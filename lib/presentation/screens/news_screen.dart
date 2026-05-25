import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:football_note/gen/app_localizations.dart';

import '../../application/news_read_state.dart';
import '../../application/news_badge_service.dart';
import '../../application/news_service.dart';
import '../../application/family_access_service.dart';
import '../../application/player_profile_service.dart';
import '../../application/locale_service.dart';
import '../../application/settings_service.dart';
import '../../application/training_service.dart';
import '../../application/backup_service.dart';
import '../../domain/entities/news_article.dart';
import '../../domain/entities/news_channel.dart';
import '../../domain/repositories/option_repository.dart';
import '../../infrastructure/rss_news_repository.dart';
import '../widgets/app_page_route.dart';
import '../widgets/app_background.dart';
import '../widgets/watch_cart/watch_cart_card.dart';
import 'fifa_ranking_screen.dart';
import 'league_standings_screen.dart';

class NewsScreen extends StatefulWidget {
  static const String openedItemsKey = 'news_opened_items_v1';

  final TrainingService trainingService;
  final LocaleService localeService;
  final OptionRepository optionRepository;
  final SettingsService settingsService;
  final BackupService? driveBackupService;
  final bool isActive;
  final NewsService? newsService;

  const NewsScreen({
    super.key,
    required this.trainingService,
    required this.localeService,
    required this.optionRepository,
    required this.settingsService,
    this.driveBackupService,
    this.isActive = false,
    this.newsService,
  });

  @override
  State<NewsScreen> createState() => _NewsScreenState();
}

enum _NewsRegionFilter { all, domestic, international }

class _NewsScreenState extends State<NewsScreen> with WidgetsBindingObserver {
  static const String _titleTranslateEnabledKey =
      'news_title_translate_enabled';
  static const String _scrappedLinksKey = 'news_scrapped_links';
  static const String _scrappedItemsKey = 'news_scrapped_items_v1';
  static const String _sourceOpenCountsKey = 'news_source_open_counts_v1';
  static const Duration _autoRefreshInterval = Duration(hours: 3);
  static const int _defaultPrimaryChannelLoadCount = 3;
  static const int _domesticPrimaryChannelLoadCount = 2;
  static const ValueKey<String> _channelsActionKey = ValueKey<String>(
    'news_quick_action_channels',
  );
  static const ValueKey<String> _scrapToggleActionKey = ValueKey<String>(
    'news_quick_action_scrap_toggle',
  );
  static const ValueKey<String> _translateToggleActionKey = ValueKey<String>(
    'news_quick_action_translate_toggle',
  );
  static const ValueKey<String> _fifaHubActionKey = ValueKey<String>(
    'news_quick_action_fifa_hub',
  );
  static const ValueKey<String> _kLeagueStandingsActionKey = ValueKey<String>(
    'news_quick_action_kleague_standings',
  );
  static const ValueKey<String> _leagueStandingsActionKey = ValueKey<String>(
    'news_quick_action_league_standings',
  );
  static const ValueKey<String> _searchActionKey = ValueKey<String>(
    'news_quick_action_search',
  );
  static const ValueKey<String> _viewedHistoryActionKey = ValueKey<String>(
    'news_quick_action_viewed_history',
  );
  static final Uri _kLeagueStandingsUri = Uri.parse(
    'https://www.kleague.com/record/team.do',
  );
  static DateTime? _cachedLoadedAt;
  static Set<String>? _cachedChannelIds;
  static final List<NewsArticle> _cachedArticles = <NewsArticle>[];
  late final NewsService _newsService;
  late final PlayerProfileService _profileService;
  late final List<NewsChannel> _channels;
  final TextEditingController _searchController = TextEditingController();
  late Set<String> _selectedChannelIds;
  late Set<String> _readArticleKeys;
  final Set<String> _sessionOpenedArticleKeys = <String>{};
  late Set<String> _scrappedLinks;
  late Map<String, _ScrappedNewsItem> _scrappedItemsByLink;
  late Map<String, int> _sourceOpenCounts;
  late String _positionHint;
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
  _NewsRegionFilter _regionFilter = _NewsRegionFilter.all;
  bool _guideShownOnce = false;
  bool _isBackgroundLoading = false;
  int _loadToken = 0;
  DateTime? _lastLoadedAt;

  bool get _isParentMode =>
      FamilyAccessService(widget.optionRepository).loadState().isParentMode;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _newsService =
        widget.newsService ??
        NewsService(RssNewsRepository(widget.optionRepository));
    _profileService = PlayerProfileService(widget.optionRepository);
    _channels = _newsService.channels();
    _positionHint = _profileService
        .load()
        .positionTestResult
        .trim()
        .toLowerCase();
    _selectedChannelIds = _channels.map((channel) => channel.id).toSet();
    _readArticleKeys = NewsReadState.loadReadKeys(widget.optionRepository);
    _scrappedLinks = widget.optionRepository
        .getOptions(_scrappedLinksKey, const [])
        .map((value) => value.trim())
        .where((value) => value.isNotEmpty)
        .toSet();
    _scrappedItemsByLink = _loadScrappedItems();
    if (_scrappedItemsByLink.isNotEmpty) {
      _scrappedLinks = {..._scrappedLinks, ..._scrappedItemsByLink.keys};
    }
    _sourceOpenCounts = _loadSourceOpenCounts();
    unawaited(NewsBadgeService.markFeedOpened(widget.optionRepository));
    _applyCacheIfValid();
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
      body: AppBackground(
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildNewsHeader(l10n),
                    const SizedBox(height: 8),
                    _buildQuickActions(
                      l10n: l10n,
                      isKo:
                          Localizations.localeOf(context).languageCode == 'ko',
                    ),
                    const SizedBox(height: 8),
                    _buildRegionFilter(l10n),
                  ],
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
                      hintText: l10n.newsSearchAction,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
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

  Widget _buildNewsHeader(AppLocalizations l10n) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final actionsMaxWidth =
            (constraints.maxWidth * (constraints.maxWidth < 520 ? 0.54 : 0.58))
                .clamp(176.0, 380.0)
                .toDouble();
        return Row(
          children: [
            IconButton(
              onPressed: () => Navigator.of(context).maybePop(),
              icon: const Icon(Icons.arrow_back),
              tooltip: MaterialLocalizations.of(context).backButtonTooltip,
            ),
            const SizedBox(width: 4),
            Expanded(
              child: Text(
                l10n.tabNews,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900),
              ),
            ),
            const SizedBox(width: 8),
            ConstrainedBox(
              constraints: BoxConstraints(maxWidth: actionsMaxWidth),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildHeaderLeagueAction(
                      buttonKey: _leagueStandingsActionKey,
                      label: l10n.newsLeagueStandingsAction,
                      icon: Icons.sports_soccer_outlined,
                      onPressed: _openLeagueStandings,
                    ),
                    const SizedBox(width: 6),
                    _buildHeaderLeagueAction(
                      buttonKey: _kLeagueStandingsActionKey,
                      label: l10n.newsKLeagueStandingsButton,
                      icon: Icons.flag_outlined,
                      onPressed: _openKLeagueStandings,
                    ),
                    const SizedBox(width: 6),
                    _buildHeaderLeagueAction(
                      buttonKey: _fifaHubActionKey,
                      label: l10n.newsFifaHubButton,
                      icon: Icons.public,
                      onPressed: _openFifaRankingHub,
                    ),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildHeaderLeagueAction({
    required Key buttonKey,
    required String label,
    required IconData icon,
    required VoidCallback onPressed,
  }) {
    return OutlinedButton.icon(
      key: buttonKey,
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(
        minimumSize: const Size(0, 40),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        visualDensity: VisualDensity.compact,
      ),
      icon: Icon(icon, size: 17),
      label: Text(label, maxLines: 1, overflow: TextOverflow.ellipsis),
    );
  }

  Widget _buildRegionFilter(AppLocalizations l10n) {
    return SizedBox(
      width: double.infinity,
      child: SegmentedButton<_NewsRegionFilter>(
        segments: [
          ButtonSegment<_NewsRegionFilter>(
            value: _NewsRegionFilter.all,
            icon: const Icon(Icons.public, size: 18),
            label: Text(l10n.newsRegionAllLabel),
          ),
          ButtonSegment<_NewsRegionFilter>(
            value: _NewsRegionFilter.domestic,
            icon: const Icon(Icons.flag_outlined, size: 18),
            label: Text(l10n.newsRegionDomesticLabel),
          ),
          ButtonSegment<_NewsRegionFilter>(
            value: _NewsRegionFilter.international,
            icon: const Icon(Icons.language_outlined, size: 18),
            label: Text(l10n.newsRegionInternationalLabel),
          ),
        ],
        selected: {_regionFilter},
        showSelectedIcon: false,
        onSelectionChanged: _changeRegionFilter,
      ),
    );
  }

  Widget _buildQuickActions({
    required AppLocalizations l10n,
    required bool isKo,
  }) {
    return Align(
      alignment: Alignment.centerRight,
      child: Wrap(
        alignment: WrapAlignment.end,
        spacing: 8,
        runSpacing: 8,
        children: [
          OutlinedButton.icon(
            key: _channelsActionKey,
            onPressed: _openChannelPicker,
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            ),
            icon: const Icon(Icons.rss_feed, size: 18),
            label: Text(l10n.newsChannelsAction),
          ),
          _buildQuickToggleAction(
            buttonKey: _scrapToggleActionKey,
            label: _showScrappedOnly
                ? l10n.newsShowAllNewsAction
                : l10n.newsShowScrappedOnlyAction,
            icon: _showScrappedOnly ? Icons.bookmark : Icons.bookmark_border,
            selected: _showScrappedOnly,
            showLabel: false,
            tooltip: _showScrappedOnly
                ? l10n.newsShowAllNewsAction
                : l10n.newsShowScrappedOnlyAction,
            onPressed: () {
              setState(() {
                _showScrappedOnly = !_showScrappedOnly;
              });
            },
          ),
          if (isKo)
            Tooltip(
              message: _titleTranslateEnabled
                  ? l10n.newsTitleTranslateEnabledTooltip
                  : l10n.newsTitleTranslateDisabledTooltip,
              child: _buildQuickToggleAction(
                buttonKey: _translateToggleActionKey,
                label: l10n.newsTranslateAction,
                icon: Icons.translate_rounded,
                selected: _titleTranslateEnabled,
                showLabel: false,
                onPressed: _toggleTitleTranslate,
              ),
            ),
          _buildQuickToggleAction(
            buttonKey: _searchActionKey,
            label: l10n.newsSearchAction,
            icon: _showSearch ? Icons.close : Icons.search,
            selected: _showSearch,
            showLabel: false,
            tooltip: l10n.newsSearchAction,
            onPressed: _toggleSearch,
          ),
          _buildQuickToggleAction(
            buttonKey: _viewedHistoryActionKey,
            label: l10n.newsViewedHistoryAction,
            icon: Icons.history,
            selected: false,
            showLabel: false,
            tooltip: l10n.newsViewedHistoryAction,
            onPressed: _openViewedNewsHistory,
          ),
        ],
      ),
    );
  }

  Widget _buildQuickToggleAction({
    Key? buttonKey,
    required String label,
    required IconData icon,
    required bool selected,
    required VoidCallback onPressed,
    bool showLabel = true,
    String? tooltip,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    final style = OutlinedButton.styleFrom(
      padding: showLabel
          ? const EdgeInsets.symmetric(horizontal: 14, vertical: 12)
          : const EdgeInsets.all(12),
      minimumSize: showLabel ? null : const Size(46, 46),
      backgroundColor: selected
          ? colorScheme.primaryContainer
          : colorScheme.surfaceContainerLow,
      foregroundColor: selected
          ? colorScheme.onPrimaryContainer
          : colorScheme.onSurface,
      side: BorderSide(
        color: selected ? colorScheme.primary : colorScheme.outlineVariant,
      ),
    );
    final child = showLabel
        ? OutlinedButton.icon(
            key: buttonKey,
            onPressed: onPressed,
            style: style,
            icon: Icon(icon, size: 18),
            label: Text(label),
          )
        : OutlinedButton(
            key: buttonKey,
            onPressed: onPressed,
            style: style,
            child: Icon(icon, size: 18),
          );
    final button = Semantics(
      button: true,
      selected: selected,
      label: label,
      child: child,
    );
    if (tooltip == null || tooltip.trim().isEmpty) {
      return button;
    }
    return Tooltip(message: tooltip, child: button);
  }

  Widget _buildNewsBody(bool isKo) {
    final visibleArticles = _filteredArticles();
    final showScrappedOnly = _showScrappedOnly;
    if (_isLoading && _articles.isEmpty) {
      return ListView(
        children: const [
          SizedBox(height: 120),
          Center(child: CircularProgressIndicator()),
        ],
      );
    }
    final items = <Widget>[];
    if (_articles.isEmpty && _hadError) {
      items.add(
        _buildMessageCard(
          isKo
              ? '뉴스를 불러오지 못했습니다. 아래로 당겨 새로고침 해주세요.'
              : 'Failed to load news. Pull down to refresh.',
        ),
      );
    } else if (_articles.isEmpty) {
      items.add(
        _buildMessageCard(
          isKo ? '선택한 채널의 뉴스가 없습니다.' : 'No news for selected channels.',
        ),
      );
    } else if (visibleArticles.isEmpty) {
      items.add(
        _buildMessageCard(
          showScrappedOnly
              ? (isKo ? '스크랩한 소식이 없습니다.' : 'No scrapped news yet.')
              : (isKo ? '검색 결과가 없습니다.' : 'No results found.'),
        ),
      );
    } else {
      items.addAll(
        visibleArticles.map((article) => _buildArticleCard(article)),
      );
    }
    return Stack(
      children: [
        ListView.separated(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
          itemCount: items.length,
          separatorBuilder: (_, __) => const SizedBox(height: 8),
          itemBuilder: (context, index) => items[index],
        ),
        if (_isLoading || _isBackgroundLoading)
          const Align(
            alignment: Alignment.topCenter,
            child: LinearProgressIndicator(minHeight: 2),
          ),
      ],
    );
  }

  Widget _buildMessageCard(String message) {
    return Padding(
      padding: const EdgeInsets.only(top: 64),
      child: Center(child: Text(message, textAlign: TextAlign.center)),
    );
  }

  Widget _buildArticleCard(NewsArticle article) {
    final isKo = Localizations.localeOf(context).languageCode == 'ko';
    final isParentMode = _isParentMode;
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
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
          child: Row(
            children: [
              _NewsThumb(article: article),
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
              if (!isParentMode)
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
  }

  List<NewsArticle> _filteredArticles() {
    final query = _searchController.text.trim().toLowerCase();
    final showScrappedOnly = _showScrappedOnly;
    final scrappedBase = showScrappedOnly
        ? _scrappedItemsByLink.values.toList(growable: false)
        : <_ScrappedNewsItem>[];
    if (showScrappedOnly) {
      scrappedBase.sort((a, b) => b.scrappedAt.compareTo(a.scrappedAt));
    }
    final base = showScrappedOnly
        ? scrappedBase.map((item) => item.article).toList(growable: false)
        : _articles
              .where(
                (article) =>
                    !_isReadArticle(article) ||
                    _sessionOpenedArticleKeys.contains(
                      NewsReadState.articleKey(article),
                    ),
              )
              .toList(growable: false);
    final regionBase = base.where(_matchesRegionFilter).toList(growable: true);
    final filtered = query.isEmpty
        ? regionBase
        : regionBase
              .where((article) {
                final title = article.title.toLowerCase();
                final sourceText = article.source.toLowerCase();
                final translated =
                    _translatedTitlesByLink[article.link.trim()]
                        ?.toLowerCase() ??
                    '';
                return title.contains(query) ||
                    sourceText.contains(query) ||
                    translated.contains(query);
              })
              .toList(growable: true);
    if (_regionFilter == _NewsRegionFilter.domestic) {
      filtered.sort((a, b) {
        final readCompare = _compareReadPriority(a, b);
        if (readCompare != 0) {
          return readCompare;
        }
        final thumbCompare = (_hasUsableThumbnail(b) ? 1 : 0).compareTo(
          _hasUsableThumbnail(a) ? 1 : 0,
        );
        if (thumbCompare != 0) {
          return thumbCompare;
        }
        return _scoreArticle(b).compareTo(_scoreArticle(a));
      });
    }
    return filtered;
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
    if (_isParentMode) return;
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

  void _changeRegionFilter(Set<_NewsRegionFilter> selection) {
    if (selection.isEmpty) return;
    final next = selection.first;
    if (next == _regionFilter) return;
    setState(() {
      _regionFilter = next;
    });
    unawaited(_loadProgressive());
  }

  Future<void> _openChannelPicker() async {
    final l10n = AppLocalizations.of(context)!;
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
                      l10n.newsSelectChannelsTitle,
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
                          child: Text(l10n.newsSelectAll),
                        ),
                        TextButton(
                          onPressed: () {
                            setSheetState(temp.clear);
                          },
                          child: Text(l10n.newsClearAll),
                        ),
                      ],
                    ),
                    SizedBox(
                      height: 320,
                      child: ListView(
                        children: _buildChannelPickerItems(
                          l10n: l10n,
                          temp: temp,
                          setSheetState: setSheetState,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    FilledButton(
                      onPressed: () => Navigator.of(context).pop(temp),
                      child: Text(l10n.filterApply),
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

  List<Widget> _buildChannelPickerItems({
    required AppLocalizations l10n,
    required Set<String> temp,
    required StateSetter setSheetState,
  }) {
    final domesticChannels = _channels
        .where(_isDomesticNewsChannel)
        .toList(growable: false);
    final internationalChannels = _channels
        .where((channel) => !_isDomesticNewsChannel(channel))
        .toList(growable: false);
    return [
      if (domesticChannels.isNotEmpty) ...[
        _buildChannelGroupHeader(l10n.newsDomesticFeedsLabel),
        ...domesticChannels.map(
          (channel) => _buildChannelTile(
            channel: channel,
            temp: temp,
            setSheetState: setSheetState,
          ),
        ),
      ],
      if (internationalChannels.isNotEmpty) ...[
        _buildChannelGroupHeader(l10n.newsInternationalFeedsLabel),
        ...internationalChannels.map(
          (channel) => _buildChannelTile(
            channel: channel,
            temp: temp,
            setSheetState: setSheetState,
          ),
        ),
      ],
    ];
  }

  Widget _buildChannelGroupHeader(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 6),
      child: Text(
        title,
        style: Theme.of(
          context,
        ).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w800),
      ),
    );
  }

  Widget _buildChannelTile({
    required NewsChannel channel,
    required Set<String> temp,
    required StateSetter setSheetState,
  }) {
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
  }

  bool _isDomesticNewsChannel(NewsChannel channel) =>
      channel.isDomestic || channel.id.endsWith('_ko');

  Future<void> _loadProgressive({bool force = false}) async {
    if (!force && !_shouldRefreshByPolicy()) {
      return;
    }
    _readArticleKeys = NewsReadState.loadReadKeys(widget.optionRepository);
    final channelIds = _prioritizedSelectedChannelIds();
    final token = ++_loadToken;
    setState(() {
      _isLoading = true;
      _isBackgroundLoading = false;
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
    final foregroundCount = _foregroundChannelLoadCount();
    final primaryIds = channelIds.take(foregroundCount).toList(growable: false);
    final secondaryIds = channelIds
        .skip(foregroundCount)
        .toList(growable: false);

    final primarySucceeded = await _loadChannels(
      token: token,
      channelIds: primaryIds,
      forceRefresh: force,
    );
    if (!mounted || token != _loadToken) return;
    await _markLoadedArticlesSeenForBadge();
    if (!mounted || token != _loadToken) return;

    if (secondaryIds.isEmpty) {
      setState(() {
        _isLoading = false;
        _hadError = !primarySucceeded && _articles.isEmpty;
      });
      _updateNewsCache();
      return;
    }

    setState(() {
      _isLoading = false;
      _isBackgroundLoading = true;
      _hadError = !primarySucceeded && _articles.isEmpty;
    });
    unawaited(
      _loadChannels(
        token: token,
        channelIds: secondaryIds,
        forceRefresh: force,
      ).then((secondarySucceeded) async {
        if (!mounted || token != _loadToken) return;
        await _markLoadedArticlesSeenForBadge();
        if (!mounted || token != _loadToken) return;
        setState(() {
          _isBackgroundLoading = false;
          _hadError =
              _articles.isEmpty && !(primarySucceeded || secondarySucceeded);
        });
        _updateNewsCache();
      }),
    );
  }

  bool _shouldRefreshByPolicy() {
    if (_articles.isEmpty) {
      final cachedChannels = _cachedChannelIds;
      if (cachedChannels == null ||
          !_hasSameChannels(_effectiveSelectedChannelIds(), cachedChannels)) {
        return true;
      }
    }
    final last = _lastLoadedAt ?? _cachedLoadedAt;
    if (last == null) return true;
    return DateTime.now().difference(last) >= _autoRefreshInterval;
  }

  void _applyCacheIfValid() {
    final cachedAt = _cachedLoadedAt;
    final cachedChannels = _cachedChannelIds;
    if (cachedAt == null || cachedChannels == null) return;
    if (DateTime.now().difference(cachedAt) >= _autoRefreshInterval) return;
    if (!_hasSameChannels(_effectiveSelectedChannelIds(), cachedChannels)) {
      return;
    }
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
    unawaited(_markLoadedArticlesSeenForBadge());
  }

  Future<void> _markLoadedArticlesSeenForBadge() async {
    final newlySeenArticles = <NewsArticle>[];
    final seenKeys = widget.optionRepository
        .getOptions(NewsBadgeService.seenArticleKeysKey, const <String>[])
        .map((value) => value.trim())
        .where((value) => value.isNotEmpty)
        .toSet();
    for (final article in _articles) {
      final key = NewsReadState.articleKey(article);
      if (key.isEmpty || seenKeys.contains(key)) continue;
      newlySeenArticles.add(article);
    }
    if (newlySeenArticles.isEmpty) {
      NewsBadgeService.clearUnreadCount();
      return;
    }
    await NewsBadgeService.markSeen(widget.optionRepository, newlySeenArticles);
    NewsBadgeService.clearUnreadCount();
  }

  Future<bool> _loadChannels({
    required int token,
    required List<String> channelIds,
    required bool forceRefresh,
  }) async {
    if (channelIds.isEmpty) return false;
    final loadedChunks = <List<NewsArticle>>[];
    final tasks = channelIds
        .map((id) async {
          try {
            final chunk = await _newsService.latest(
              id,
              forceRefresh: forceRefresh,
            );
            if (chunk.isNotEmpty) {
              loadedChunks.add(chunk);
            }
          } catch (_) {
            // Keep loading remaining channels even if one feed fails.
          }
        })
        .toList(growable: false);
    await Future.wait(tasks);
    if (!mounted || token != _loadToken || loadedChunks.isEmpty) {
      return false;
    }
    setState(() {
      for (final chunk in loadedChunks) {
        _mergeChunk(chunk);
      }
    });
    return true;
  }

  void _updateNewsCache() {
    _lastLoadedAt = DateTime.now();
    _cachedLoadedAt = _lastLoadedAt;
    _cachedChannelIds = _effectiveSelectedChannelIds();
    _cachedArticles
      ..clear()
      ..addAll(_articles);
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
    _resortArticles();
  }

  void _resortArticles() {
    _articles.sort((a, b) {
      final readCompare = _compareReadPriority(a, b);
      if (readCompare != 0) {
        return readCompare;
      }
      return _scoreArticle(b).compareTo(_scoreArticle(a));
    });
  }

  int _compareReadPriority(NewsArticle a, NewsArticle b) {
    final aRead = _isReadArticle(a) ? 1 : 0;
    final bRead = _isReadArticle(b) ? 1 : 0;
    return aRead.compareTo(bRead);
  }

  bool _isReadArticle(NewsArticle article) {
    final key = NewsReadState.articleKey(article);
    return key.isNotEmpty && _readArticleKeys.contains(key);
  }

  double _scoreArticle(NewsArticle article) {
    var score = 0.0;
    final now = DateTime.now();
    final publishedAt = article.publishedAt?.toLocal();
    if (publishedAt != null) {
      final ageHours = now.difference(publishedAt).inHours;
      score += (96 - ageHours).clamp(0, 96) * 0.35;
    }
    final sourceKey = _normalizeSourceKey(article.source);
    score += ((_sourceOpenCounts[sourceKey] ?? 0).clamp(0, 8)) * 7.0;
    score += (_scrappedSourceCount(sourceKey).clamp(0, 4)) * 4.0;
    score += _scoreArticleForPosition(article);
    if (_matchesPriorityLeague(article)) {
      score += 4.0;
    }
    return score;
  }

  double _scoreArticleForPosition(NewsArticle article) {
    if (_positionHint.isEmpty) return 0;
    final haystack = '${article.title} ${article.source}'.trim().toLowerCase();
    final keywords = _positionKeywords(_positionHint);
    var score = 0.0;
    for (final keyword in keywords) {
      if (haystack.contains(keyword)) {
        score += 6.0;
      }
    }
    return score;
  }

  bool _matchesPriorityLeague(NewsArticle article) {
    final lower = article.title.toLowerCase();
    return lower.contains('premier league') ||
        lower.contains('champions league') ||
        lower.contains('ucl');
  }

  List<String> _positionKeywords(String position) {
    if (position.contains('keeper') ||
        position.contains('goalkeeper') ||
        position.contains('골키퍼')) {
      return const [
        'goalkeeper',
        'keeper',
        'save',
        'shot-stopper',
        'distribution',
      ];
    }
    if (position.contains('defender') ||
        position.contains('center back') ||
        position.contains('centre back') ||
        position.contains('fullback') ||
        position.contains('풀백') ||
        position.contains('수비')) {
      return const [
        'defender',
        'centre-back',
        'center-back',
        'full-back',
        'fullback',
        'press',
        'build-up',
      ];
    }
    if (position.contains('midfielder') ||
        position.contains('midfield') ||
        position.contains('미드필더')) {
      return const [
        'midfielder',
        'midfield',
        'playmaker',
        'passing',
        'tempo',
        'press',
      ];
    }
    if (position.contains('wing') ||
        position.contains('winger') ||
        position.contains('윙')) {
      return const ['winger', 'wing', 'cross', 'dribble', '1v1', 'wide'];
    }
    if (position.contains('forward') ||
        position.contains('striker') ||
        position.contains('attacker') ||
        position.contains('공격')) {
      return const [
        'striker',
        'forward',
        'finishing',
        'shooting',
        'goal',
        'pressing',
      ];
    }
    return const ['football', 'match', 'training'];
  }

  List<String> _prioritizedSelectedChannelIds() {
    final selected = _effectiveSelectedChannels().toList(growable: false)
      ..sort(
        (a, b) => _channelPriorityScore(b).compareTo(_channelPriorityScore(a)),
      );
    return selected.map((channel) => channel.id).toList(growable: false);
  }

  int _foregroundChannelLoadCount() {
    return _regionFilter == _NewsRegionFilter.domestic
        ? _domesticPrimaryChannelLoadCount
        : _defaultPrimaryChannelLoadCount;
  }

  List<NewsChannel> _channelsForRegion(_NewsRegionFilter filter) {
    switch (filter) {
      case _NewsRegionFilter.all:
        return _channels;
      case _NewsRegionFilter.domestic:
        return _channels.where(_isDomesticNewsChannel).toList(growable: false);
      case _NewsRegionFilter.international:
        return _channels
            .where((channel) => !_isDomesticNewsChannel(channel))
            .toList(growable: false);
    }
  }

  List<NewsChannel> _effectiveSelectedChannels() {
    return _channelsForRegion(_regionFilter)
        .where((channel) => _selectedChannelIds.contains(channel.id))
        .toList(growable: false);
  }

  Set<String> _effectiveSelectedChannelIds() =>
      _effectiveSelectedChannels().map((channel) => channel.id).toSet();

  bool _matchesRegionFilter(NewsArticle article) {
    switch (_regionFilter) {
      case _NewsRegionFilter.all:
        return true;
      case _NewsRegionFilter.domestic:
        return _isDomesticNewsArticle(article);
      case _NewsRegionFilter.international:
        return !_isDomesticNewsArticle(article);
    }
  }

  bool _isDomesticNewsArticle(NewsArticle article) {
    final channelId = article.channelId.trim();
    if (channelId.isNotEmpty) {
      final channel = _channelForId(channelId);
      return channel == null
          ? channelId.endsWith('_ko')
          : _isDomesticNewsChannel(channel);
    }
    final haystack = '${article.title} ${article.source} ${article.link}';
    return RegExp(r'[가-힣]').hasMatch(haystack);
  }

  NewsChannel? _channelForId(String id) {
    for (final channel in _channels) {
      if (channel.id == id) return channel;
    }
    return null;
  }

  double _channelPriorityScore(NewsChannel channel) {
    final lowerName = channel.name.toLowerCase();
    final sourceKey = _normalizeSourceKey(channel.name.split('·').first);
    var score = ((_sourceOpenCounts[sourceKey] ?? 0).clamp(0, 8)) * 8.0;
    if (_regionFilter == _NewsRegionFilter.domestic &&
        _isDedicatedDomesticChannel(channel)) {
      score += 18.0;
    }
    if (!lowerName.contains('premier league') &&
        !lowerName.contains('champions league')) {
      score += 3.0;
    }
    for (final keyword in _positionKeywords(_positionHint)) {
      if (lowerName.contains(keyword)) {
        score += 2.0;
      }
    }
    return score;
  }

  bool _isDedicatedDomesticChannel(NewsChannel channel) {
    if (!_isDomesticNewsChannel(channel)) return false;
    final lowerName = channel.name.toLowerCase();
    return lowerName.contains('국내축구') ||
        lowerName.contains('한국축구') ||
        channel.id.contains('domestic_soccer');
  }

  Map<String, int> _loadSourceOpenCounts() {
    final raw = widget.optionRepository.getValue<String>(_sourceOpenCountsKey);
    if (raw == null || raw.trim().isEmpty) return <String, int>{};
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map) return <String, int>{};
      return decoded.map<String, int>((key, value) {
        final count = value is num
            ? value.toInt()
            : int.tryParse('$value') ?? 0;
        return MapEntry(key.toString(), count);
      });
    } catch (_) {
      return <String, int>{};
    }
  }

  String _normalizeSourceKey(String raw) {
    return raw.trim().toLowerCase().replaceAll(RegExp(r'\s+'), ' ');
  }

  int _scrappedSourceCount(String sourceKey) {
    if (sourceKey.isEmpty) return 0;
    return _scrappedItemsByLink.values.where((item) {
      return _normalizeSourceKey(item.article.source) == sourceKey;
    }).length;
  }

  Future<void> _recordSourceOpen(NewsArticle article) async {
    final key = _normalizeSourceKey(article.source);
    if (key.isEmpty) return;
    final next = Map<String, int>.from(_sourceOpenCounts);
    next[key] = (next[key] ?? 0) + 1;
    _sourceOpenCounts = next;
    await widget.optionRepository.setValue(
      _sourceOpenCountsKey,
      jsonEncode(next),
    );
  }

  bool _isRenderableArticle(NewsArticle article) {
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

  Future<void> _openFifaRankingHub() async {
    await Navigator.of(
      context,
    ).push<void>(AppPageRoute(builder: (_) => const FifaRankingScreen()));
  }

  Future<void> _openLeagueStandings() async {
    await Navigator.of(context).push<void>(
      AppPageRoute(
        builder: (_) => LeagueStandingsScreen(
          optionRepository: widget.optionRepository,
          settingsService: widget.settingsService,
        ),
      ),
    );
  }

  Future<void> _openKLeagueStandings() async {
    await launchUrl(
      _kLeagueStandingsUri,
      mode: LaunchMode.inAppBrowserView,
      browserConfiguration: const BrowserConfiguration(showTitle: true),
    );
  }

  Future<void> _openViewedNewsHistory() async {
    final l10n = AppLocalizations.of(context)!;
    final isKo = Localizations.localeOf(context).languageCode == 'ko';
    final openedItems = _loadOpenedNewsItems();
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (sheetContext) {
        return SafeArea(
          child: FractionallySizedBox(
            heightFactor: 0.72,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
                  child: Text(
                    l10n.newsViewedHistoryTitle,
                    style: Theme.of(sheetContext).textTheme.titleLarge
                        ?.copyWith(fontWeight: FontWeight.w900),
                  ),
                ),
                if (openedItems.isEmpty)
                  Expanded(
                    child: Center(
                      child: Text(
                        l10n.newsViewedHistoryEmpty,
                        textAlign: TextAlign.center,
                      ),
                    ),
                  )
                else
                  Expanded(
                    child: ListView.separated(
                      padding: const EdgeInsets.fromLTRB(8, 0, 8, 16),
                      itemCount: openedItems.length,
                      separatorBuilder: (_, __) => const Divider(height: 1),
                      itemBuilder: (context, index) {
                        final item = openedItems[index];
                        return ListTile(
                          leading: const Icon(Icons.article_outlined),
                          title: Text(
                            item.displayTitle(isKo),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          subtitle: Text(item.subtitle),
                          trailing: const Icon(Icons.open_in_new),
                          onTap: () {
                            Navigator.of(sheetContext).pop();
                            unawaited(_openViewedNewsItem(item));
                          },
                        );
                      },
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  List<_OpenedNewsItem> _loadOpenedNewsItems() {
    final raw = widget.optionRepository.getValue<String>(
      NewsScreen.openedItemsKey,
    );
    if (raw == null || raw.trim().isEmpty) return const <_OpenedNewsItem>[];
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) return const <_OpenedNewsItem>[];
      return decoded
          .whereType<Map>()
          .map((item) => _OpenedNewsItem.fromMap(item.cast<String, dynamic>()))
          .where((item) => item.link.trim().isNotEmpty)
          .toList(growable: false);
    } catch (_) {
      return const <_OpenedNewsItem>[];
    }
  }

  Future<void> _openViewedNewsItem(_OpenedNewsItem item) async {
    final uri = Uri.tryParse(item.link);
    if (uri == null || !uri.hasScheme) return;
    await launchUrl(
      uri,
      mode: LaunchMode.inAppBrowserView,
      browserConfiguration: const BrowserConfiguration(showTitle: true),
    );
  }

  bool _hasUsableThumbnail(NewsArticle article) {
    final url = article.imageUrl.trim();
    return url.startsWith('http://') || url.startsWith('https://');
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
    unawaited(
      Future.wait<void>([
        _recordSourceOpen(article),
        _recordOpenedArticle(article),
      ]).catchError((_) => const <void>[]),
    );
    await launchUrl(
      uri,
      mode: LaunchMode.inAppBrowserView,
      browserConfiguration: const BrowserConfiguration(showTitle: true),
    );
  }

  Future<void> _recordOpenedArticle(NewsArticle article) async {
    final isKo = Localizations.localeOf(context).languageCode == 'ko';
    await NewsReadState.markRead(widget.optionRepository, [article]);
    NewsBadgeService.clearUnreadCount();
    final readKey = NewsReadState.articleKey(article);
    if (readKey.isNotEmpty && mounted) {
      setState(() {
        _readArticleKeys = {..._readArticleKeys, readKey};
        _sessionOpenedArticleKeys.add(readKey);
      });
    }
    final link = article.link.trim();
    if (link.isEmpty) return;
    final openedAt = DateTime.now();
    final rawTitle = article.title.trim();
    var titleKo = _translatedTitlesByLink[link]?.trim() ?? '';
    if (isKo &&
        rawTitle.isNotEmpty &&
        titleKo.isEmpty &&
        !RegExp(r'[가-힣]').hasMatch(rawTitle)) {
      unawaited(_cacheOpenedArticleTitleTranslation(link, rawTitle));
    }
    final items = <Map<String, dynamic>>[];
    final raw = widget.optionRepository.getValue<String>(
      NewsScreen.openedItemsKey,
    );
    if (raw != null && raw.trim().isNotEmpty) {
      try {
        final decoded = jsonDecode(raw);
        if (decoded is List) {
          for (final item in decoded) {
            if (item is Map<String, dynamic>) {
              items.add(item);
            } else if (item is Map) {
              items.add(item.cast<String, dynamic>());
            }
          }
        }
      } catch (_) {
        // Ignore malformed payload.
      }
    }
    final id = _openedNewsId(link, openedAt);
    final next = items.toList(growable: true);
    next.insert(0, <String, dynamic>{
      'id': id,
      'title': rawTitle,
      'titleKo': titleKo,
      'link': link,
      'source': article.source.trim(),
      'openedAt': openedAt.toIso8601String(),
    });
    if (next.length > 300) {
      next.removeRange(300, next.length);
    }
    await widget.optionRepository.setValue(
      NewsScreen.openedItemsKey,
      jsonEncode(next),
    );
  }

  Future<void> _cacheOpenedArticleTitleTranslation(
    String link,
    String rawTitle,
  ) async {
    final titleKo = (await _translateToKorean(rawTitle)).trim();
    if (titleKo.isEmpty || titleKo == rawTitle) return;
    final raw = widget.optionRepository.getValue<String>(
      NewsScreen.openedItemsKey,
    );
    if (raw == null || raw.trim().isEmpty) return;
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) return;
      final updated = decoded
          .map((item) {
            final map = item is Map<String, dynamic>
                ? Map<String, dynamic>.from(item)
                : item is Map
                ? Map<String, dynamic>.from(item.cast<String, dynamic>())
                : null;
            if (map == null) return item;
            if (map['link']?.toString().trim() == link &&
                (map['titleKo']?.toString().trim().isEmpty ?? true)) {
              map['titleKo'] = titleKo;
            }
            return map;
          })
          .toList(growable: false);
      await widget.optionRepository.setValue(
        NewsScreen.openedItemsKey,
        jsonEncode(updated),
      );
    } catch (_) {
      // Translation history can be filled on a later open.
    }
  }

  String _openedNewsId(String link, DateTime openedAt) =>
      '${Uri.encodeComponent(link)}::${openedAt.microsecondsSinceEpoch}';

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

class _OpenedNewsItem {
  final String title;
  final String titleKo;
  final String link;
  final String source;
  final DateTime? openedAt;

  const _OpenedNewsItem({
    required this.title,
    required this.titleKo,
    required this.link,
    required this.source,
    required this.openedAt,
  });

  factory _OpenedNewsItem.fromMap(Map<String, dynamic> map) {
    return _OpenedNewsItem(
      title: map['title']?.toString().trim() ?? '',
      titleKo: map['titleKo']?.toString().trim() ?? '',
      link: map['link']?.toString().trim() ?? '',
      source: map['source']?.toString().trim() ?? '',
      openedAt: DateTime.tryParse(map['openedAt']?.toString() ?? ''),
    );
  }

  String displayTitle(bool isKo) {
    if (isKo && titleKo.trim().isNotEmpty) return titleKo.trim();
    if (title.trim().isNotEmpty) return title.trim();
    return link.trim();
  }

  String get subtitle {
    final date = openedAt;
    if (date == null) return source;
    final dateText = DateFormat('yyyy.MM.dd HH:mm').format(date.toLocal());
    if (source.trim().isEmpty) return dateText;
    return '$source · $dateText';
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
        'summary': article.summary,
        'publishedAt': article.publishedAt?.toIso8601String(),
        'imageUrl': article.imageUrl,
        'channelId': article.channelId,
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
      summary: articleMap['summary']?.toString() ?? '',
      publishedAt: DateTime.tryParse(publishedAtText),
      imageUrl: articleMap['imageUrl']?.toString() ?? '',
      channelId: articleMap['channelId']?.toString() ?? '',
    );
    return _ScrappedNewsItem(
      link: link,
      article: article,
      scrappedAt: DateTime.tryParse(rawScrappedAt) ?? DateTime.now(),
    );
  }
}

class _NewsThumb extends StatefulWidget {
  final NewsArticle article;

  const _NewsThumb({required this.article});

  @override
  State<_NewsThumb> createState() => _NewsThumbState();
}

class _NewsThumbState extends State<_NewsThumb> {
  static final Map<String, String> _resolvedImageByLink = <String, String>{};
  static final RegExp _ogImagePattern = RegExp(
    '<meta[^>]+property=["\\\']og:image["\\\'][^>]*content=["\\\']([^"\\\']+)["\\\']',
    caseSensitive: false,
  );
  static final RegExp _twitterImagePattern = RegExp(
    '<meta[^>]+name=["\\\']twitter:image["\\\'][^>]*content=["\\\']([^"\\\']+)["\\\']',
    caseSensitive: false,
  );

  String _resolvedImageUrl = '';
  bool _didRequestFallback = false;

  @override
  void initState() {
    super.initState();
    _syncResolvedImageUrl();
    _loadFallbackImage();
  }

  @override
  void didUpdateWidget(covariant _NewsThumb oldWidget) {
    super.didUpdateWidget(oldWidget);
    final oldLink = oldWidget.article.link.trim();
    final newLink = widget.article.link.trim();
    final oldImageUrl = oldWidget.article.imageUrl.trim();
    final newImageUrl = widget.article.imageUrl.trim();
    if (oldLink == newLink && oldImageUrl == newImageUrl) {
      return;
    }
    _didRequestFallback = false;
    _syncResolvedImageUrl();
    _loadFallbackImage();
  }

  void _syncResolvedImageUrl() {
    final directUrl = widget.article.imageUrl.trim();
    if (_isHttpUrl(directUrl)) {
      _resolvedImageUrl = directUrl;
      return;
    }
    final cached = _resolvedImageByLink[widget.article.link.trim()] ?? '';
    _resolvedImageUrl = _isHttpUrl(cached) ? cached : '';
  }

  Future<void> _loadFallbackImage() async {
    if (_didRequestFallback ||
        _resolvedImageUrl.isNotEmpty ||
        !_isSportsKhanArticle(widget.article.link)) {
      return;
    }
    _didRequestFallback = true;
    final resolved = await _fetchArticleMetaImage(widget.article.link);
    if (!mounted || !_isHttpUrl(resolved)) {
      return;
    }
    final link = widget.article.link.trim();
    _resolvedImageByLink[link] = resolved;
    setState(() {
      _resolvedImageUrl = resolved;
    });
  }

  Future<String> _fetchArticleMetaImage(String link) async {
    final normalizedLink = link.trim();
    if (normalizedLink.isEmpty) return '';
    final requestUrl = kIsWeb
        ? 'https://api.allorigins.win/raw?url=${Uri.encodeComponent(normalizedLink)}'
        : normalizedLink;
    try {
      final response = await http
          .get(Uri.parse(requestUrl))
          .timeout(const Duration(seconds: 10));
      if (response.statusCode != 200) return '';
      final body = response.body;
      for (final pattern in <RegExp>[_ogImagePattern, _twitterImagePattern]) {
        final match = pattern.firstMatch(body);
        final candidate = match?.group(1)?.trim() ?? '';
        if (_isHttpUrl(candidate)) {
          return candidate;
        }
      }
    } catch (_) {
      return '';
    }
    return '';
  }

  bool _isSportsKhanArticle(String link) {
    final uri = Uri.tryParse(link.trim());
    if (uri == null || uri.host.isEmpty) return false;
    return uri.host.toLowerCase() == 'sports.khan.co.kr';
  }

  bool _isHttpUrl(String url) {
    return url.startsWith('http://') || url.startsWith('https://');
  }

  @override
  Widget build(BuildContext context) {
    final url = _resolvedImageUrl.trim();
    final canShow = _isHttpUrl(url);
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
