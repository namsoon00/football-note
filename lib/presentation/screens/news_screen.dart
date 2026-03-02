import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:football_note/gen/app_localizations.dart';
import 'package:url_launcher/url_launcher.dart';

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
import '../widgets/app_drawer.dart';
import '../widgets/watch_cart/main_app_bar.dart';
import '../widgets/watch_cart/watch_cart_card.dart';
import 'profile_screen.dart';
import 'settings_screen.dart';

class NewsScreen extends StatefulWidget {
  final TrainingService trainingService;
  final LocaleService localeService;
  final OptionRepository optionRepository;
  final SettingsService settingsService;
  final BackupService? driveBackupService;

  const NewsScreen({
    super.key,
    required this.trainingService,
    required this.localeService,
    required this.optionRepository,
    required this.settingsService,
    this.driveBackupService,
  });

  @override
  State<NewsScreen> createState() => _NewsScreenState();
}

class _NewsScreenState extends State<NewsScreen> {
  late final NewsService _newsService;
  late final List<NewsChannel> _channels;
  late Set<String> _selectedChannelIds;
  final List<NewsArticle> _articles = <NewsArticle>[];
  final Set<String> _seenLinks = <String>{};
  final Set<String> _seenTitles = <String>{};
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
  int _loadToken = 0;

  @override
  void initState() {
    super.initState();
    _newsService = NewsService(RssNewsRepository(widget.optionRepository));
    _channels = _newsService.channels();
    _selectedChannelIds = _channels.map((channel) => channel.id).toSet();
    _loadProgressive();
  }

  @override
  Widget build(BuildContext context) {
    final isKo = Localizations.localeOf(context).languageCode == 'ko';
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      drawer: AppDrawer(
        trainingService: widget.trainingService,
        optionRepository: widget.optionRepository,
        localeService: widget.localeService,
        settingsService: widget.settingsService,
        driveBackupService: widget.driveBackupService,
        currentIndex: 3,
      ),
      body: AppBackground(
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                child: Builder(
                  builder: (context) => WatchCartAppBar(
                    onMenuTap: () => Scaffold.of(context).openDrawer(),
                    profilePhotoSource: widget.optionRepository
                            .getValue<String>('profile_photo_url') ??
                        '',
                    onProfileTap: () => _openProfile(context),
                    onSettingsTap: () => _openSettings(context),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 10),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    l10n.tabNews,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                child: WatchCartCard(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  child: Row(
                    children: [
                      const Icon(Icons.rss_feed, size: 18),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _channelSummary(isKo),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      TextButton(
                        onPressed: _openChannelPicker,
                        child: Text(isKo ? '채널 선택' : 'Channels'),
                      ),
                    ],
                  ),
                ),
              ),
              Expanded(
                child: RefreshIndicator(
                  onRefresh: _loadProgressive,
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
    return Stack(
      children: [
        ListView.separated(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
          itemCount: _articles.length,
          separatorBuilder: (_, __) => const SizedBox(height: 8),
          itemBuilder: (context, index) {
            final article = _articles[index];
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
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
                  child: Row(
                    children: [
                      _NewsThumb(imageUrl: article.imageUrl),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              article.title,
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
                      const SizedBox(width: 6),
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
                        children: _channels.map((channel) {
                          return CheckboxListTile(
                            dense: true,
                            value: temp.contains(channel.id),
                            title: Text(channel.name),
                            controlAffinity: ListTileControlAffinity.leading,
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
                        }).toList(growable: false),
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
    _loadProgressive();
  }

  Future<void> _loadProgressive() async {
    final channelIds = _selectedChannelIds.toList(growable: false);
    final token = ++_loadToken;
    setState(() {
      _isLoading = true;
      _hadError = false;
      _articles.clear();
      _seenLinks.clear();
      _seenTitles.clear();
    });
    if (channelIds.isEmpty) {
      if (!mounted || token != _loadToken) return;
      setState(() => _isLoading = false);
      return;
    }

    final tasks = channelIds.map((id) async {
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
    }).toList(growable: false);

    await Future.wait(tasks);
    if (!mounted || token != _loadToken) return;
    setState(() => _isLoading = false);
  }

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
    final custom =
        widget.optionRepository.getOptions('news_blocked_domains', const []);
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
    final target = isKo ? _koreanTranslateUri(uri) : uri;
    await launchUrl(target, mode: LaunchMode.inAppBrowserView);
  }

  Uri _koreanTranslateUri(Uri original) {
    return Uri.https(
      'translate.google.com',
      '/translate',
      {
        'hl': 'ko',
        'sl': 'auto',
        'tl': 'ko',
        'u': original.toString(),
      },
    );
  }

  void _openSettings(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => SettingsScreen(
          localeService: widget.localeService,
          settingsService: widget.settingsService,
          optionRepository: widget.optionRepository,
          driveBackupService: widget.driveBackupService,
        ),
      ),
    );
  }

  Future<void> _openProfile(BuildContext context) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ProfileScreen(
          optionRepository: widget.optionRepository,
        ),
      ),
    );
    if (mounted) {
      _loadProgressive();
    }
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
