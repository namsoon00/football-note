import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:football_note/gen/app_localizations.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../application/news_read_state.dart';
import '../../application/news_service.dart';
import '../../application/locale_service.dart';
import '../../application/settings_service.dart';
import '../../application/training_service.dart';
import '../../application/backup_service.dart';
import '../../domain/entities/news_article.dart';
import '../../domain/entities/news_channel.dart';
import '../../domain/repositories/option_repository.dart';
import '../../infrastructure/rss_news_repository.dart';
import '../widgets/app_background.dart';
import '../widgets/tab_screen_title.dart';
import '../widgets/watch_cart/watch_cart_card.dart';

class NewsScreen extends StatefulWidget {
  final TrainingService trainingService;
  final LocaleService localeService;
  final OptionRepository optionRepository;
  final SettingsService settingsService;
  final BackupService? driveBackupService;
  final bool isActive;

  const NewsScreen({
    super.key,
    required this.trainingService,
    required this.localeService,
    required this.optionRepository,
    required this.settingsService,
    this.driveBackupService,
    this.isActive = false,
  });

  @override
  State<NewsScreen> createState() => _NewsScreenState();
}

class _NewsScreenState extends State<NewsScreen> with WidgetsBindingObserver {
  static const String _titleTranslateEnabledKey =
      'news_title_translate_enabled';
  static const String _scrappedLinksKey = 'news_scrapped_links';
  static const String _scrappedItemsKey = 'news_scrapped_items_v1';
  static const Duration _autoRefreshInterval = Duration(hours: 1);
  static DateTime? _cachedLoadedAt;
  static Set<String>? _cachedChannelIds;
  static final List<NewsArticle> _cachedArticles = <NewsArticle>[];
  late final NewsService _newsService;
  late final List<NewsChannel> _channels;
  final TextEditingController _searchController = TextEditingController();
  late Set<String> _selectedChannelIds;
  late Set<String> _scrappedLinks;
  late Map<String, _ScrappedNewsItem> _scrappedItemsByLink;
  final List<NewsArticle> _articles = <NewsArticle>[];
  final Set<String> _seenLinks = <String>{};
  final Set<String> _seenTitles = <String>{};
  final Map<String, String> _translatedTitlesByLink = <String, String>{};
  final Set<String> _translatingLinks = <String>{};
  static const Set<String> _blockedHosts = <String>{
    'ad.doubleclick.net',
    'doubleclick.net',
    'googlesyndication.com',
    'taboola.com',
    'outbrain.com',
    'adnxs.com',
    'criteo.com',
    'mgid.com',
  };
  bool _isLoading = false;
  bool _hadError = false;
  bool _titleTranslateEnabled = false;
  bool _titleTranslateInitialized = false;
  bool _showSearch = false;
  bool _showScrappedOnly = false;
  bool _guideShownOnce = false;
  int _loadToken = 0;
  DateTime? _lastLoadedAt;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _newsService = NewsService(RssNewsRepository(widget.optionRepository));
    _channels = _newsService.channels();
    _selectedChannelIds = _channels.map((channel) => channel.id).toSet();
    _scrappedLinks = widget.optionRepository
        .getOptions(_scrappedLinksKey, const [])
        .map((value) => value.trim())
        .where((value) => value.isNotEmpty)
        .toSet();
    _scrappedItemsByLink = _loadScrappedItems();
    if (_scrappedItemsByLink.isNotEmpty) {
      _scrappedLinks = {..._scrappedLinks, ..._scrappedItemsByLink.keys};
    }
    _applyCacheIfValid();
    unawaited(_markVisibleArticlesRead());
    _loadProgressive();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _searchController.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant NewsScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!oldWidget.isActive && widget.isActive && _shouldRefreshByPolicy()) {
      _loadProgressive(force: true);
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed) return;
    _loadProgressive();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_titleTranslateInitialized) return;
    final isKo = Localizations.localeOf(context).languageCode == 'ko';
    final stored = widget.optionRepository.getValue<bool>(
      _titleTranslateEnabledKey,
    );
    _titleTranslateEnabled = stored ?? isKo;
    _titleTranslateInitialized = true;
  }

  @override
  Widget build(BuildContext context) {
    final isKo = Localizations.localeOf(context).languageCode == 'ko';
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.tabNews)),
      body: AppBackground(
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 10),
                child: TabScreenTitle(
                  title: l10n.tabNews,
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        tooltip: isKo ? '기사 검색' : 'Search news',
                        onPressed: _toggleSearch,
                        icon: Icon(_showSearch ? Icons.close : Icons.search),
                      ),
                      TextButton.icon(
                        onPressed: _openChannelPicker,
                        icon: const Icon(Icons.rss_feed, size: 18),
                        label: Text(isKo ? '채널 선택' : 'Channels'),
                      ),
                    ],
                  ),
                ),
              ),
              if (_showSearch)
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
                  child: TextField(
                    controller: _searchController,
                    autofocus: true,
                    onChanged: (_) => setState(() {}),
                    decoration: InputDecoration(
                      isDense: true,
                      prefixIcon: const Icon(Icons.search),
                      suffixIcon: _searchController.text.trim().isEmpty
                          ? null
                          : IconButton(
                              onPressed: () {
                                _searchController.clear();
                                setState(() {});
                              },
                              icon: const Icon(Icons.close),
                            ),
                      hintText: isKo ? '기사 검색' : 'Search news',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                  ),
                ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                child: WatchCartCard(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.rss_feed, size: 18),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _statusSummary(isKo),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      IconButton(
                        tooltip: _showScrappedOnly
                            ? (isKo ? '전체 소식 보기' : 'Show all news')
                            : (isKo ? '스크랩한 소식만 보기' : 'Show scrapped only'),
                        onPressed: () {
                          setState(() {
                            _showScrappedOnly = !_showScrappedOnly;
                          });
                        },
                        icon: Icon(
                          _showScrappedOnly
                              ? Icons.bookmark
                              : Icons.bookmark_border,
                          color: _showScrappedOnly
                              ? Theme.of(context).colorScheme.primary
                              : null,
                        ),
                      ),
                      if (isKo)
                        IconButton(
                          tooltip: _titleTranslateEnabled
                              ? '제목 번역 켜짐'
                              : '제목 번역 꺼짐',
                          onPressed: _toggleTitleTranslate,
                          icon: Icon(
                            Icons.translate_rounded,
                            color: _titleTranslateEnabled
                                ? Theme.of(context).colorScheme.primary
                                : Theme.of(context).colorScheme.onSurface
                                      .withValues(alpha: 0.55),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              Expanded(
                child: RefreshIndicator(
                  onRefresh: () => _loadProgressive(force: true),
                  child: _buildNewsBody(isKo),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNewsBody(bool isKo) {
    final visibleArticles = _filteredArticles();
    if (_isLoading && _articles.isEmpty) {
      return ListView(
        children: const [
          SizedBox(height: 120),
          Center(child: CircularProgressIndicator()),
        ],
      );
    }
    if (_articles.isEmpty && _hadError) {
      return ListView(
        children: [
          const SizedBox(height: 120),
          Center(
            child: Text(
              isKo
                  ? '뉴스를 불러오지 못했습니다. 아래로 당겨 새로고침 해주세요.'
                  : 'Failed to load news. Pull down to refresh.',
              textAlign: TextAlign.center,
            ),
          ),
        ],
      );
    }
    if (_articles.isEmpty) {
      return ListView(
        children: [
          const SizedBox(height: 120),
          Center(
            child: Text(
              isKo ? '선택한 채널의 뉴스가 없습니다.' : 'No news for selected channels.',
            ),
          ),
        ],
      );
    }
    if (visibleArticles.isEmpty) {
      return ListView(
        children: [
          const SizedBox(height: 120),
          Center(
            child: Text(
              _showScrappedOnly
                  ? (isKo ? '스크랩한 소식이 없습니다.' : 'No scrapped news yet.')
                  : (isKo ? '검색 결과가 없습니다.' : 'No results found.'),
            ),
          ),
        ],
      );
    }
    return Stack(
      children: [
        ListView.separated(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
          itemCount: visibleArticles.length,
          separatorBuilder: (_, __) => const SizedBox(height: 8),
          itemBuilder: (context, index) {
            final article = visibleArticles[index];
            final pub = article.publishedAt;
            final dateText = pub == null
                ? article.source
                : '${article.source} · ${DateFormat('yyyy.MM.dd HH:mm').format(pub.toLocal())}';
            return WatchCartCard(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              child: InkWell(
                borderRadius: BorderRadius.circular(14),
                onTap: () => _openLink(article),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 6,
                  ),
                  child: Row(
                    children: [
                      _NewsThumb(imageUrl: article.imageUrl),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _displayTitle(article, isKo),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 6),
                            Text(
                              dateText,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        tooltip: _isScrapped(article)
                            ? (isKo ? '스크랩 해제' : 'Remove scrap')
                            : (isKo ? '스크랩' : 'Scrap'),
                        onPressed: () => _toggleScrap(article),
                        icon: Icon(
                          _isScrapped(article)
                              ? Icons.bookmark
                              : Icons.bookmark_border,
                          color: _isScrapped(article)
                              ? Theme.of(context).colorScheme.primary
                              : null,
                        ),
                      ),
                      const Icon(Icons.chevron_right),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
        if (_isLoading)
          const Align(
            alignment: Alignment.topCenter,
            child: LinearProgressIndicator(minHeight: 2),
          ),
      ],
    );
  }

  String _channelSummary(bool isKo) {
    if (_selectedChannelIds.isEmpty) {
      return isKo ? '선택된 채널 없음' : 'No channels selected';
    }
    if (_selectedChannelIds.length == _channels.length) {
      return isKo ? '모든 채널 선택됨' : 'All channels selected';
    }
    final selectedNames = _channels
        .where((channel) => _selectedChannelIds.contains(channel.id))
        .map((channel) => channel.name)
        .toList(growable: false);
    final first = selectedNames.first;
    final rest = selectedNames.length - 1;
    if (rest <= 0) {
      return first;
    }
    return isKo ? '$first 외 $rest개' : '$first +$rest';
  }

  String _statusSummary(bool isKo) {
    final channelText = _channelSummary(isKo);
    final scrapCount = _scrappedItemsByLink.length;
    if (_showScrappedOnly) {
      return isKo
          ? '스크랩 $scrapCount개 보는 중 · $channelText'
          : 'Showing $scrapCount scrapped items · $channelText';
    }
    if (scrapCount == 0) {
      return channelText;
    }
    return isKo
        ? '$channelText · 스크랩 $scrapCount개'
        : '$channelText · $scrapCount scrapped';
  }

  List<NewsArticle> _filteredArticles() {
    final query = _searchController.text.trim().toLowerCase();
    final scrappedBase = _showScrappedOnly
        ? _scrappedItemsByLink.values.toList(growable: false)
        : <_ScrappedNewsItem>[];
    if (_showScrappedOnly) {
      scrappedBase.sort((a, b) => b.scrappedAt.compareTo(a.scrappedAt));
    }
    final base = _showScrappedOnly
        ? scrappedBase.map((item) => item.article).toList(growable: false)
        : List<NewsArticle>.unmodifiable(_articles);
    if (query.isEmpty) return base;
    return base
        .where((article) {
          final title = article.title.toLowerCase();
          final sourceText = article.source.toLowerCase();
          final translated =
              _translatedTitlesByLink[article.link.trim()]?.toLowerCase() ?? '';
          return title.contains(query) ||
              sourceText.contains(query) ||
              translated.contains(query);
        })
        .toList(growable: false);
  }

  String _scrapKeyForArticle(NewsArticle article) {
    final link = article.link.trim();
    if (link.isNotEmpty) return link;
    final title = article.title.trim().toLowerCase();
    final source = article.source.trim().toLowerCase();
    final publishedAt =
        article.publishedAt?.toIso8601String() ?? article.imageUrl.trim();
    return 'fallback::$source::$title::$publishedAt';
  }

  bool _isScrapped(NewsArticle article) =>
      _scrappedLinks.contains(_scrapKeyForArticle(article));

  Future<void> _toggleScrap(NewsArticle article) async {
    final isKo = Localizations.localeOf(context).languageCode == 'ko';
    final link = _scrapKeyForArticle(article);
    final next = Set<String>.from(_scrappedLinks);
    final nextItems = Map<String, _ScrappedNewsItem>.from(_scrappedItemsByLink);
    final added = !next.remove(link);
    if (added) {
      next.add(link);
      nextItems[link] = _ScrappedNewsItem(
        link: link,
        article: article,
        scrappedAt: DateTime.now(),
      );
    } else {
      nextItems.remove(link);
    }
    setState(() {
      _scrappedLinks = next;
      _scrappedItemsByLink = nextItems;
    });
    await _persistScrappedState();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          added
              ? (isKo ? '소식을 스크랩했어요.' : 'News scrapped.')
              : (isKo ? '스크랩을 해제했어요.' : 'Scrap removed.'),
        ),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _toggleSearch() {
    setState(() {
      _showSearch = !_showSearch;
      if (!_showSearch) {
        _searchController.clear();
      }
    });
  }

  Future<void> _openChannelPicker() async {
    final isKo = Localizations.localeOf(context).languageCode == 'ko';
    final initial = Set<String>.from(_selectedChannelIds);
    final selected = await showModalBottomSheet<Set<String>>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) {
        final temp = Set<String>.from(initial);
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      isKo ? '뉴스 채널 선택' : 'Select news channels',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        TextButton(
                          onPressed: () {
                            setSheetState(() {
                              temp
                                ..clear()
                                ..addAll(_channels.map((e) => e.id));
                            });
                          },
                          child: Text(isKo ? '전체 선택' : 'Select all'),
                        ),
                        TextButton(
                          onPressed: () {
                            setSheetState(temp.clear);
                          },
                          child: Text(isKo ? '전체 해제' : 'Clear all'),
                        ),
                      ],
                    ),
                    SizedBox(
                      height: 320,
                      child: ListView(
                        children: _channels
                            .map((channel) {
                              return CheckboxListTile(
                                dense: true,
                                value: temp.contains(channel.id),
                                title: Text(channel.name),
                                controlAffinity:
                                    ListTileControlAffinity.leading,
                                onChanged: (checked) {
                                  setSheetState(() {
                                    if (checked == true) {
                                      temp.add(channel.id);
                                    } else {
                                      temp.remove(channel.id);
                                    }
                                  });
                                },
                              );
                            })
                            .toList(growable: false),
                      ),
                    ),
                    const SizedBox(height: 8),
                    FilledButton(
                      onPressed: () => Navigator.of(context).pop(temp),
                      child: Text(isKo ? '적용' : 'Apply'),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
    if (selected == null) return;
    setState(() {
      _selectedChannelIds = selected;
    });
    _loadProgressive(force: true);
  }

  Future<void> _loadProgressive({bool force = false}) async {
    if (!force && !_shouldRefreshByPolicy()) {
      return;
    }
    final channelIds = _selectedChannelIds.toList(growable: false);
    final token = ++_loadToken;
    setState(() {
      _isLoading = true;
      _hadError = false;
      if (force) {
        _articles.clear();
        _seenLinks.clear();
        _seenTitles.clear();
        _translatedTitlesByLink.clear();
        _translatingLinks.clear();
      }
    });
    if (channelIds.isEmpty) {
      if (!mounted || token != _loadToken) return;
      setState(() => _isLoading = false);
      return;
    }

    final tasks = channelIds
        .map((id) async {
          try {
            final chunk = await _newsService.latest(id);
            if (!mounted || token != _loadToken) return;
            if (chunk.isEmpty) return;
            setState(() {
              _mergeChunk(chunk);
            });
          } catch (_) {
            if (!mounted || token != _loadToken) return;
            setState(() {
              _hadError = true;
            });
          }
        })
        .toList(growable: false);

    await Future.wait(tasks);
    await _markVisibleArticlesRead();
    if (!mounted || token != _loadToken) return;
    setState(() {
      _isLoading = false;
      _lastLoadedAt = DateTime.now();
      _cachedLoadedAt = _lastLoadedAt;
      _cachedChannelIds = Set<String>.from(_selectedChannelIds);
      _cachedArticles
        ..clear()
        ..addAll(_articles);
    });
  }

  bool _shouldRefreshByPolicy() {
    final last = _lastLoadedAt ?? _cachedLoadedAt;
    if (last == null) return true;
    return DateTime.now().difference(last) >= _autoRefreshInterval;
  }

  void _applyCacheIfValid() {
    final cachedAt = _cachedLoadedAt;
    final cachedChannels = _cachedChannelIds;
    if (cachedAt == null || cachedChannels == null) return;
    if (DateTime.now().difference(cachedAt) >= _autoRefreshInterval) return;
    if (!_hasSameChannels(_selectedChannelIds, cachedChannels)) return;
    if (_cachedArticles.isEmpty) return;
    _articles
      ..clear()
      ..addAll(_cachedArticles);
    _seenLinks
      ..clear()
      ..addAll(_articles.map((a) => a.link.trim()).where((v) => v.isNotEmpty));
    _seenTitles
      ..clear()
      ..addAll(
        _articles
            .map((a) => a.title.trim().toLowerCase())
            .where((v) => v.isNotEmpty),
      );
    _lastLoadedAt = cachedAt;
  }

  Future<void> _markVisibleArticlesRead() async {
    if (_articles.isEmpty) return;
    await NewsReadState.markRead(widget.optionRepository, _articles);
  }

  bool _hasSameChannels(Set<String> a, Set<String> b) =>
      a.length == b.length && a.containsAll(b);

  void _mergeChunk(List<NewsArticle> chunk) {
    for (final article in chunk) {
      if (!_isRenderableArticle(article)) {
        continue;
      }
      final normLink = article.link.trim();
      final normTitle = article.title.trim().toLowerCase();
      if (normLink.isNotEmpty && _seenLinks.contains(normLink)) {
        continue;
      }
      if (normTitle.isNotEmpty && _seenTitles.contains(normTitle)) {
        continue;
      }
      if (normLink.isNotEmpty) {
        _seenLinks.add(normLink);
      }
      if (normTitle.isNotEmpty) {
        _seenTitles.add(normTitle);
      }
      _articles.add(article);
      final link = _scrapKeyForArticle(article);
      final scrapped = _scrappedItemsByLink[link];
      if (scrapped != null) {
        _scrappedItemsByLink[link] = scrapped.copyWith(article: article);
      }
    }

    _articles.sort((a, b) {
      final at = a.publishedAt;
      final bt = b.publishedAt;
      if (at == null && bt == null) return 0;
      if (at == null) return 1;
      if (bt == null) return -1;
      return bt.compareTo(at);
    });
  }

  bool _isRenderableArticle(NewsArticle article) {
    final image = article.imageUrl.trim();
    if (!(image.startsWith('http://') || image.startsWith('https://'))) {
      return false;
    }
    final host = Uri.tryParse(article.link.trim())?.host.toLowerCase() ?? '';
    if (host.isEmpty) return false;
    for (final blocked in _allBlockedHosts()) {
      if (host == blocked || host.endsWith('.$blocked')) {
        return false;
      }
    }
    final lowerTitle = article.title.toLowerCase();
    final lowerSource = article.source.toLowerCase();
    if (lowerTitle.contains('sponsored') ||
        lowerTitle.contains('advertorial') ||
        lowerSource.contains('sponsored') ||
        lowerSource.contains('홍보') ||
        lowerSource.contains('광고')) {
      return false;
    }
    return true;
  }

  Set<String> _allBlockedHosts() {
    final custom = widget.optionRepository.getOptions(
      'news_blocked_domains',
      const [],
    );
    final merged = <String>{..._blockedHosts};
    for (final value in custom) {
      final normalized = _normalizeDomain(value);
      if (normalized.isNotEmpty) {
        merged.add(normalized);
      }
    }
    return merged;
  }

  String _normalizeDomain(String input) {
    final raw = input.trim().toLowerCase();
    if (raw.isEmpty) return '';
    final withScheme = raw.contains('://') ? raw : 'https://$raw';
    final parsed = Uri.tryParse(withScheme);
    final host = parsed?.host.toLowerCase().trim() ?? raw;
    if (host.isEmpty) return '';
    return host;
  }

  Future<void> _openLink(NewsArticle article) async {
    final isKo = Localizations.localeOf(context).languageCode == 'ko';
    final uri = Uri.tryParse(article.link);
    if (uri == null || !uri.hasScheme) return;
    if (isKo && !_guideShownOnce) {
      _guideShownOnce = true;
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('기사 화면 우측 상단 메뉴에서 번역 기능을 사용할 수 있어요.'),
            duration: Duration(seconds: 3),
          ),
        );
      }
    }
    await launchUrl(
      uri,
      mode: LaunchMode.inAppBrowserView,
      browserConfiguration: const BrowserConfiguration(showTitle: true),
    );
  }

  String _displayTitle(NewsArticle article, bool isKo) {
    if (!isKo || !_titleTranslateEnabled) return article.title;
    final key = article.link.trim();
    if (key.isEmpty) return article.title;
    final translated = _translatedTitlesByLink[key];
    if (translated != null && translated.isNotEmpty) {
      return translated;
    }
    _queueTitleTranslation(article);
    return article.title;
  }

  void _queueTitleTranslation(NewsArticle article) {
    final key = article.link.trim();
    if (key.isEmpty || _translatingLinks.contains(key)) return;
    final originalTitle = article.title.trim();
    if (originalTitle.isEmpty || RegExp(r'[가-힣]').hasMatch(originalTitle)) {
      return;
    }
    _translatingLinks.add(key);
    _translateToKorean(originalTitle)
        .then((translated) {
          if (!mounted) return;
          final value = translated.trim();
          if (value.isNotEmpty && value != originalTitle) {
            setState(() {
              _translatedTitlesByLink[key] = value;
            });
          }
        })
        .whenComplete(() {
          _translatingLinks.remove(key);
        });
  }

  Future<void> _toggleTitleTranslate() async {
    setState(() {
      _titleTranslateEnabled = !_titleTranslateEnabled;
    });
    await widget.optionRepository.setValue(
      _titleTranslateEnabledKey,
      _titleTranslateEnabled,
    );
  }

  Future<String> _translateToKorean(String text) async {
    try {
      final uri = Uri.https(
        'translate.googleapis.com',
        '/translate_a/single',
        <String, String>{
          'client': 'gtx',
          'sl': 'auto',
          'tl': 'ko',
          'dt': 't',
          'q': text,
        },
      );
      final response = await http.get(uri).timeout(const Duration(seconds: 4));
      if (response.statusCode != 200) return text;
      final decoded = jsonDecode(response.body);
      if (decoded is! List || decoded.isEmpty || decoded.first is! List) {
        return text;
      }
      final segments = decoded.first as List;
      final buffer = StringBuffer();
      for (final segment in segments) {
        if (segment is List && segment.isNotEmpty && segment.first is String) {
          buffer.write(segment.first as String);
        }
      }
      final result = buffer.toString().trim();
      return result.isEmpty ? text : result;
    } catch (_) {
      return text;
    }
  }

  Future<void> _persistScrappedState() async {
    await widget.optionRepository.saveOptions(
      _scrappedLinksKey,
      _scrappedLinks.toList(growable: false),
    );
    final payload = _scrappedItemsByLink.values
        .map((item) => item.toMap())
        .toList(growable: false);
    await widget.optionRepository.setValue(
      _scrappedItemsKey,
      jsonEncode(payload),
    );
  }

  Map<String, _ScrappedNewsItem> _loadScrappedItems() {
    final raw = widget.optionRepository.getValue<String>(_scrappedItemsKey);
    if (raw == null || raw.isEmpty) return <String, _ScrappedNewsItem>{};
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) return <String, _ScrappedNewsItem>{};
      final items = <String, _ScrappedNewsItem>{};
      for (final entry in decoded) {
        if (entry is! Map) continue;
        final item = _ScrappedNewsItem.fromMap(entry.cast<String, dynamic>());
        final link = item.link.trim();
        if (link.isEmpty) continue;
        items[link] = item;
      }
      return items;
    } catch (_) {
      return <String, _ScrappedNewsItem>{};
    }
  }
}

class _ScrappedNewsItem {
  final String link;
  final NewsArticle article;
  final DateTime scrappedAt;

  const _ScrappedNewsItem({
    required this.link,
    required this.article,
    required this.scrappedAt,
  });

  _ScrappedNewsItem copyWith({NewsArticle? article, DateTime? scrappedAt}) {
    return _ScrappedNewsItem(
      link: link,
      article: article ?? this.article,
      scrappedAt: scrappedAt ?? this.scrappedAt,
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'link': link,
      'scrappedAt': scrappedAt.toIso8601String(),
      'article': <String, dynamic>{
        'title': article.title,
        'link': article.link,
        'source': article.source,
        'publishedAt': article.publishedAt?.toIso8601String(),
        'imageUrl': article.imageUrl,
      },
    };
  }

  factory _ScrappedNewsItem.fromMap(Map<String, dynamic> map) {
    final rawArticle = map['article'];
    final articleMap = rawArticle is Map
        ? rawArticle.cast<String, dynamic>()
        : <String, dynamic>{};
    final rawScrappedAt = map['scrappedAt']?.toString() ?? '';
    final link =
        (map['link']?.toString() ?? articleMap['link']?.toString() ?? '')
            .trim();
    final publishedAtText = articleMap['publishedAt']?.toString() ?? '';
    final article = NewsArticle(
      title: articleMap['title']?.toString() ?? '',
      link: articleMap['link']?.toString() ?? link,
      source: articleMap['source']?.toString() ?? '',
      publishedAt: DateTime.tryParse(publishedAtText),
      imageUrl: articleMap['imageUrl']?.toString() ?? '',
    );
    return _ScrappedNewsItem(
      link: link,
      article: article,
      scrappedAt: DateTime.tryParse(rawScrappedAt) ?? DateTime.now(),
    );
  }
}

class _NewsThumb extends StatelessWidget {
  final String imageUrl;

  const _NewsThumb({required this.imageUrl});

  @override
  Widget build(BuildContext context) {
    final url = imageUrl.trim();
    final canShow = url.startsWith('http://') || url.startsWith('https://');
    return ClipRRect(
      borderRadius: BorderRadius.circular(10),
      child: Container(
        width: 56,
        height: 56,
        color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.08),
        child: canShow
            ? Image.network(
                url,
                fit: BoxFit.cover,
                filterQuality: FilterQuality.low,
                cacheWidth: 160,
                cacheHeight: 160,
                errorBuilder: (_, __, ___) => const _NewsThumbFallback(),
              )
            : const _NewsThumbFallback(),
      ),
    );
  }
}

class _NewsThumbFallback extends StatelessWidget {
  const _NewsThumbFallback();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Icon(
        Icons.article_outlined,
        color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
      ),
    );
  }
}
