import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

import '../../application/backup_service.dart';
import '../../application/locale_service.dart';
import '../../application/settings_service.dart';
import '../../application/training_board_service.dart';
import '../../application/training_service.dart';
import '../../domain/entities/training_board.dart';
import '../../domain/entities/training_entry.dart';
import '../../domain/repositories/option_repository.dart';
import '../../gen/app_localizations.dart';
import '../models/training_board_link_codec.dart';
import '../models/training_method_layout.dart';
import '../widgets/app_background.dart';
import '../widgets/shared_tab_header.dart';
import 'news_screen.dart';
import 'profile_screen.dart';
import 'settings_screen.dart';
import 'space_speed_game_screen.dart';

class CoachLessonScreen extends StatefulWidget {
  final OptionRepository optionRepository;
  final TrainingService? trainingService;
  final LocaleService? localeService;
  final SettingsService? settingsService;
  final BackupService? driveBackupService;
  final bool embeddedInHomeTab;

  const CoachLessonScreen({
    super.key,
    required this.optionRepository,
    this.trainingService,
    this.localeService,
    this.settingsService,
    this.driveBackupService,
    this.embeddedInHomeTab = false,
  });

  @override
  State<CoachLessonScreen> createState() => _CoachLessonScreenState();
}

class _CoachLessonScreenState extends State<CoachLessonScreen> {
  static const String _plansStorageKey = 'training_plans_v1';
  static const String _diaryThemeKey = 'diary_theme_v1';

  final PageController _pageController = PageController();
  int _selectedDayIndex = 0;
  late String _selectedThemeId;
  final Set<String> _expandedTrainingGroups = <String>{};

  bool get _isKo => Localizations.localeOf(context).languageCode == 'ko';
  ThemeData get _theme => Theme.of(context);
  bool get _isDark => _theme.brightness == Brightness.dark;
  AppLocalizations get _l10n => AppLocalizations.of(context)!;
  _DiaryThemePalette get _palette =>
      _DiaryThemePalette.fromId(_selectedThemeId);
  Color get _paperSurface => _isDark ? _palette.paperDark : _palette.paper;
  Color get _paperEdge =>
      _isDark ? _palette.paperBorderDark : _palette.paperBorder;
  Color get _headlineInk =>
      _isDark ? _palette.headlineInkDark : _palette.headlineInk;
  Color get _bodyInk => _isDark ? _palette.bodyInkDark : _palette.bodyInk;
  Color get _accentInk => _isDark ? _palette.accentInkDark : _palette.accentInk;
  Color get _accentWash => _accentInk.withValues(alpha: _isDark ? 0.16 : 0.1);
  Color get _tileSurface =>
      _isDark ? _palette.tileDark : Colors.white.withValues(alpha: 0.58);
  Color get _notebookLine =>
      _isDark ? _palette.notebookLineDark : _palette.notebookLine;
  Color get _notebookMargin =>
      _isDark ? _palette.notebookMarginDark : _palette.notebookMargin;
  Color get _holeColor => _isDark ? _palette.holeColorDark : _palette.holeColor;

  @override
  void initState() {
    super.initState();
    _selectedThemeId =
        widget.optionRepository.getValue<String>(_diaryThemeKey) ??
            _DiaryThemePalette.notebook.id;
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final stream = widget.trainingService?.watchEntries() ??
        Stream<List<TrainingEntry>>.value(const <TrainingEntry>[]);
    final showBack = !widget.embeddedInHomeTab;
    final profilePhotoSource =
        widget.optionRepository.getValue<String>('profile_photo_url') ?? '';

    return Scaffold(
      body: AppBackground(
        child: SafeArea(
          child: StreamBuilder<List<TrainingEntry>>(
            stream: stream,
            builder: (context, snapshot) {
              final entries = [...(snapshot.data ?? const <TrainingEntry>[])]
                ..sort(TrainingEntry.compareByRecentCreated);
              final boardMap = TrainingBoardService(
                widget.optionRepository,
              ).boardMap();
              final days = _buildDays(entries, _loadPlans(), boardMap);
              if (days.isEmpty) {
                return ListView(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                  children: [_buildEmptyCard()],
                );
              }

              final selectedIndex = _selectedDayIndex.clamp(0, days.length - 1);
              if (selectedIndex != _selectedDayIndex) {
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (!mounted) return;
                  setState(() => _selectedDayIndex = selectedIndex);
                  if (_pageController.hasClients) {
                    _pageController.jumpToPage(selectedIndex);
                  }
                });
              }
              final selectedDay = days[selectedIndex];

              return Column(
                children: [
                  SharedTabHeader(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                    onLeadingTap: showBack
                        ? () => Navigator.of(context).maybePop()
                        : null,
                    leadingIcon: showBack ? Icons.arrow_back : Icons.menu,
                    leadingTooltip: _isKo
                        ? (showBack ? '뒤로가기' : '메뉴')
                        : (showBack ? 'Back' : 'Menu'),
                    onNewsTap: widget.trainingService != null &&
                            widget.localeService != null &&
                            widget.settingsService != null
                        ? _openNews
                        : null,
                    onGameTap: widget.trainingService != null &&
                            widget.localeService != null &&
                            widget.settingsService != null
                        ? _openGame
                        : null,
                    onProfileTap: _openProfile,
                    onSettingsTap: widget.localeService != null &&
                            widget.settingsService != null
                        ? _openSettings
                        : _openProfile,
                    profilePhotoSource: profilePhotoSource,
                    title: _isKo ? '다이어리' : 'Diary',
                    titleTrailing: OutlinedButton.icon(
                      onPressed: _showThemePicker,
                      icon: const Icon(Icons.palette_outlined, size: 18),
                      label: Text(_isKo ? '테마' : 'Theme'),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                    child: _buildPagerCard(
                      days: days,
                      dayCount: days.length,
                      selectedIndex: selectedIndex,
                      selectedLabel: _formatDiaryDate(selectedDay.date),
                    ),
                  ),
                  Expanded(
                    child: PageView.builder(
                      key: const ValueKey('diary-page-view'),
                      controller: _pageController,
                      itemCount: days.length,
                      onPageChanged: (index) {
                        if (_selectedDayIndex == index) return;
                        setState(() => _selectedDayIndex = index);
                      },
                      itemBuilder: (context, index) {
                        return _buildDiaryPage(days[index]);
                      },
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildPagerCard({
    required List<_DiaryDayData> days,
    required int dayCount,
    required int selectedIndex,
    required String selectedLabel,
  }) {
    final canGoPrev = selectedIndex < dayCount - 1;
    final canGoNext = selectedIndex > 0;
    return Container(
      decoration: _paperDecoration(),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
        child: Row(
          children: [
            IconButton(
              tooltip: _isKo ? '이전 날짜' : 'Previous day',
              onPressed: canGoPrev ? () => _movePage(selectedIndex + 1) : null,
              icon: const Icon(Icons.chevron_left),
            ),
            Expanded(
              child: InkWell(
                borderRadius: BorderRadius.circular(18),
                onTap: () => _pickDiaryDate(days, selectedIndex),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 6,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Flexible(
                            child: Text(
                              selectedLabel,
                              textAlign: TextAlign.center,
                              style: Theme.of(context)
                                  .textTheme
                                  .titleSmall
                                  ?.copyWith(
                                    color: _headlineInk,
                                    fontWeight: FontWeight.w900,
                                  ),
                            ),
                          ),
                          const SizedBox(width: 6),
                          Icon(
                            Icons.calendar_month_outlined,
                            size: 18,
                            color: _accentInk,
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _isKo
                            ? '${selectedIndex + 1} / $dayCount 페이지 · 탭해서 날짜 선택'
                            : 'Page ${selectedIndex + 1} / $dayCount · tap to pick a date',
                        style: Theme.of(
                          context,
                        ).textTheme.bodySmall?.copyWith(color: _bodyInk),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            IconButton(
              tooltip: _isKo ? '다음 날짜' : 'Next day',
              onPressed: canGoNext ? () => _movePage(selectedIndex - 1) : null,
              icon: const Icon(Icons.chevron_right),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showThemePicker() async {
    final selected = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      builder: (context) {
        return SafeArea(
          child: ListView(
            shrinkWrap: true,
            children: [
              for (final theme in _DiaryThemePalette.values)
                ListTile(
                  leading: Icon(
                    theme.id == _selectedThemeId
                        ? Icons.radio_button_checked
                        : Icons.radio_button_off,
                  ),
                  title: Text(_isKo ? theme.nameKo : theme.nameEn),
                  subtitle: Text(
                    _isKo ? theme.descriptionKo : theme.descriptionEn,
                  ),
                  onTap: () => Navigator.of(context).pop(theme.id),
                ),
            ],
          ),
        );
      },
    );
    if (selected == null || selected == _selectedThemeId) return;
    await widget.optionRepository.setValue(_diaryThemeKey, selected);
    if (!mounted) return;
    setState(() => _selectedThemeId = selected);
  }

  Future<void> _openProfile() async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) =>
            ProfileScreen(optionRepository: widget.optionRepository),
      ),
    );
  }

  Future<void> _openSettings() async {
    final localeService = widget.localeService;
    final settingsService = widget.settingsService;
    if (localeService == null || settingsService == null) {
      return _openProfile();
    }
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => SettingsScreen(
          localeService: localeService,
          settingsService: settingsService,
          optionRepository: widget.optionRepository,
          driveBackupService: widget.driveBackupService,
        ),
      ),
    );
  }

  Future<void> _openNews() async {
    final trainingService = widget.trainingService;
    final localeService = widget.localeService;
    final settingsService = widget.settingsService;
    if (trainingService == null ||
        localeService == null ||
        settingsService == null) {
      return;
    }
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => NewsScreen(
          trainingService: trainingService,
          localeService: localeService,
          optionRepository: widget.optionRepository,
          settingsService: settingsService,
          driveBackupService: widget.driveBackupService,
          isActive: true,
        ),
      ),
    );
  }

  Future<void> _openGame() async {
    final trainingService = widget.trainingService;
    final localeService = widget.localeService;
    final settingsService = widget.settingsService;
    if (trainingService == null ||
        localeService == null ||
        settingsService == null) {
      return;
    }
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => SpaceSpeedGameScreen(
          trainingService: trainingService,
          localeService: localeService,
          optionRepository: widget.optionRepository,
          settingsService: settingsService,
          driveBackupService: widget.driveBackupService,
        ),
      ),
    );
  }

  Future<void> _movePage(int index) async {
    await _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 260),
      curve: Curves.easeOutCubic,
    );
  }

  Widget _buildDiaryPage(_DiaryDayData day) {
    final diary = _buildDiary(day);
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
      child: _buildNotebookSheet(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildDayHeadlineCard(day),
            const SizedBox(height: 12),
            _buildTrainingOverviewCard(day),
            const SizedBox(height: 12),
            _buildNightReviewCard(day, diary),
            const SizedBox(height: 12),
            _buildFortuneCard(day),
            if (day.plans.isNotEmpty) ...[
              const SizedBox(height: 12),
              _buildPlanCard(day.plans),
            ],
            if (day.matchEntries.isNotEmpty) ...[
              const SizedBox(height: 12),
              _buildMatchCard(day.matchEntries),
            ],
            if (day.trainingEntries.isNotEmpty) ...[
              const SizedBox(height: 12),
              _buildTrainingSection(day),
            ],
            if (_hasRecoveryRecord(day)) ...[
              const SizedBox(height: 12),
              _buildRecoveryCard(day),
            ],
            if (day.boards.isNotEmpty) ...[
              const SizedBox(height: 12),
              _buildBoardCard(day),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildDayHeadlineCard(_DiaryDayData day) {
    final totalMinutes = day.entries.fold<int>(
      0,
      (sum, entry) => sum + entry.durationMinutes,
    );
    final trainingCount = day.trainingEntries.length;
    final matchCount = day.matchEntries.length;
    final weatherSummary = _dayWeatherSummary(day);
    final weatherIcon = _weatherIconForSummary(weatherSummary);
    return Container(
      decoration: _paperDecoration(),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(18, 18, 18, 18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    _formatDiaryDate(day.date),
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          color: _headlineInk,
                          fontWeight: FontWeight.w900,
                        ),
                  ),
                ),
                if (weatherIcon != null)
                  Icon(weatherIcon, size: 20, color: _accentInk),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              _isKo
                  ? '저장된 계획, 경기, 훈련, 회복 기록을 한 편의 일기처럼 이어서 읽을 수 있도록 정리했습니다.'
                  : 'Saved plans, matches, training, and recovery notes are gathered here as one diary entry.',
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: _bodyInk, height: 1.45),
            ),
            const SizedBox(height: 14),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _buildStatChip(
                  _isKo ? '훈련 $trainingCount개' : '$trainingCount trainings',
                ),
                _buildStatChip(
                  _isKo ? '시합 $matchCount개' : '$matchCount matches',
                ),
                _buildStatChip(
                  _isKo
                      ? '계획 ${day.plans.length}개'
                      : '${day.plans.length} plans',
                ),
                _buildStatChip(
                  _isKo ? '합계 $totalMinutes분' : '$totalMinutes min total',
                ),
                if (day.boards.isNotEmpty)
                  _buildStatChip(
                    _isKo
                        ? '보드 ${day.boards.length}개'
                        : '${day.boards.length} boards',
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatChip(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: _accentWash,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelLarge?.copyWith(
              color: _accentInk,
              fontWeight: FontWeight.w800,
            ),
      ),
    );
  }

  Widget _buildFortuneCard(_DiaryDayData day) {
    final fortunes = day.fortunes(_isKo);
    if (fortunes.isEmpty) {
      return _buildPaperCard(
        title: _isKo ? '오늘의 운세 노트' : 'Today fortune note',
        subtitle: _isKo
            ? '같은 날 훈련노트에 저장된 운세가 아직 없어요.'
            : 'No saved fortunes from training notes on this day yet.',
        child: Text(
          _isKo
              ? '훈련노트에서 오늘의 운세를 저장하면 이 다이어리 페이지에 함께 보여줍니다.'
              : 'Saved fortunes from training notes will appear here on the same diary day.',
          style: _theme.textTheme.bodyMedium?.copyWith(
            height: 1.55,
            color: _headlineInk,
          ),
        ),
      );
    }
    return _buildPaperCard(
      title: _isKo ? '오늘의 운세 노트' : 'Today fortune note',
      subtitle: _isKo
          ? '같은 날 훈련노트에 저장된 운세를 모아서 보여줘요.'
          : 'Saved fortunes from training notes on the same day are shown here.',
      child: SizedBox(
        height: fortunes.length > 1 ? 300 : 260,
        child: Column(
          children: [
            Expanded(
              child: PageView.builder(
                itemCount: fortunes.length,
                itemBuilder: (context, index) {
                  final fortune = fortunes[index];
                  return Padding(
                    padding: const EdgeInsets.only(right: 4),
                    child: _buildFortunePage(
                      fortune: fortune,
                      page: index + 1,
                      totalPages: fortunes.length,
                    ),
                  );
                },
              ),
            ),
            if (fortunes.length > 1) ...[
              const SizedBox(height: 12),
              Text(
                _isKo
                    ? '좌우로 넘겨서 다른 운세 보기'
                    : 'Swipe left or right for more fortunes',
                style: _theme.textTheme.bodySmall?.copyWith(color: _bodyInk),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildFortunePage({
    required _DiaryFortune fortune,
    required int page,
    required int totalPages,
  }) {
    final sourceLabel = _isKo ? '훈련 운세' : 'Training fortune';
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
      decoration: BoxDecoration(
        color: _tileSurface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _paperEdge),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  sourceLabel,
                  style: _theme.textTheme.labelLarge?.copyWith(
                    color: _accentInk,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              if (totalPages > 1)
                Text(
                  '$page / $totalPages',
                  style: _theme.textTheme.labelMedium?.copyWith(
                    color: _bodyInk,
                    fontWeight: FontWeight.w700,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 10),
          Expanded(
            child: ListView(
              physics: const BouncingScrollPhysics(),
              padding: EdgeInsets.zero,
              children: [
                ...fortune.bodyLines.map(
                  (line) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Text(
                      line,
                      style: _theme.textTheme.bodyMedium?.copyWith(
                        height: 1.55,
                        color: _headlineInk,
                      ),
                    ),
                  ),
                ),
                if (fortune.luckyInfoLines.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    _isKo ? '행운 정보' : 'Lucky info',
                    style: _theme.textTheme.bodyMedium?.copyWith(
                      color: _headlineInk,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 6),
                  ...fortune.luckyInfoLines.map(
                    (line) => Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: Text(
                        line,
                        style: _theme.textTheme.bodyMedium?.copyWith(
                          height: 1.5,
                          color: _headlineInk,
                        ),
                      ),
                    ),
                  ),
                ],
                if (fortune.recommendation.trim().isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      _isKo
                          ? '다음 한 걸음: ${fortune.recommendation.trim()}'
                          : 'Next step: ${fortune.recommendation.trim()}',
                      style: _theme.textTheme.bodyMedium?.copyWith(
                        height: 1.55,
                        color: _headlineInk,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNightReviewCard(_DiaryDayData day, String diary) {
    return _buildPaperCard(
      title: _isKo ? '자기 전 다이어리' : 'Night review diary',
      subtitle: _isKo
          ? '기록에 있는 사실만 연결해서 오늘을 다시 읽습니다.'
          : 'This recap only uses details already recorded in your logs.',
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            tooltip: _isKo ? '복사' : 'Copy',
            onPressed: () => _copyDiary(diary),
            icon: const Icon(Icons.content_copy_outlined),
          ),
        ],
      ),
      child: SelectableText(
        diary,
        style: Theme.of(
          context,
        ).textTheme.bodyLarge?.copyWith(height: 1.7, color: _headlineInk),
      ),
    );
  }

  Widget _buildTrainingOverviewCard(_DiaryDayData day) {
    final trainings = day.trainingEntries;
    final totalMinutes = trainings.fold<int>(
      0,
      (sum, entry) => sum + entry.durationMinutes,
    );
    final topFocus = _topFocus(trainings);
    final topPlace = _topPlaces(trainings);
    final modeLabel = trainings.length >= 6
        ? (_isKo ? '압축 타임라인 모드' : 'Compact timeline mode')
        : (_isKo ? '카드 모드' : 'Card mode');
    return _buildPaperCard(
      title: _isKo ? '오늘 훈련 요약' : 'Today training summary',
      subtitle: _isKo
          ? '핵심만 먼저 보여주고, 아래에서 상세를 펼쳐볼 수 있어요.'
          : 'See key points first, then open details below.',
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          _buildStatChip(
            _isKo ? '훈련 ${trainings.length}개' : '${trainings.length} logs',
          ),
          _buildStatChip(_isKo ? '합계 $totalMinutes분' : '$totalMinutes min'),
          _buildStatChip(_isKo ? '중심 $topFocus' : 'Focus $topFocus'),
          _buildStatChip(_isKo ? '장소 $topPlace' : 'Place $topPlace'),
          _buildStatChip(modeLabel),
        ],
      ),
    );
  }

  Widget _buildPlanCard(List<_DiaryPlan> plans) {
    return _buildPaperCard(
      title: _isKo ? '훈련 계획' : 'Training plans',
      child: Column(
        children: plans
            .map(
              (plan) => _buildTimelineTile(
                title: '${_formatTime(plan.scheduledAt)} · ${plan.category}',
                detail: _isKo
                    ? '${plan.durationMinutes}분${plan.note.trim().isEmpty ? '' : ' · ${plan.note.trim()}'}'
                    : '${plan.durationMinutes} min${plan.note.trim().isEmpty ? '' : ' · ${plan.note.trim()}'}',
              ),
            )
            .toList(growable: false),
      ),
    );
  }

  Widget _buildMatchCard(List<TrainingEntry> entries) {
    return _buildPaperCard(
      title: _isKo ? '시합 기록' : 'Match records',
      child: Column(
        children: entries
            .map(
              (entry) => _buildTimelineTile(
                title:
                    '${_formatTime(entry.date)} · ${entry.opponentTeam.isEmpty ? entry.type : entry.opponentTeam}',
                detail: _matchSummary(entry),
              ),
            )
            .toList(growable: false),
      ),
    );
  }

  Widget _buildTrainingCard(List<TrainingEntry> entries) {
    return _buildPaperCard(
      title: _isKo ? '훈련 기록' : 'Training records',
      child: SizedBox(
        height: entries.length > 1 ? 260 : 220,
        child: Column(
          children: [
            Expanded(
              child: PageView.builder(
                itemCount: entries.length,
                itemBuilder: (context, index) {
                  final entry = entries[index];
                  return Padding(
                    padding: const EdgeInsets.only(right: 4),
                    child: _buildTrainingRecordPage(
                      entry: entry,
                      page: index + 1,
                      totalPages: entries.length,
                    ),
                  );
                },
              ),
            ),
            if (entries.length > 1) ...[
              const SizedBox(height: 12),
              Text(
                _isKo
                    ? '좌우로 넘겨서 다른 훈련 기록 보기'
                    : 'Swipe left or right for more training records',
                style: _theme.textTheme.bodySmall?.copyWith(color: _bodyInk),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildTrainingSection(_DiaryDayData day) {
    final entries = day.trainingEntries;
    if (entries.length >= 6) {
      return _buildTrainingTimelineCard(day);
    }
    return _buildTrainingCard(entries);
  }

  Widget _buildTrainingTimelineCard(_DiaryDayData day) {
    final grouped = _groupTrainingEntriesByType(day.trainingEntries);
    return _buildPaperCard(
      title: _isKo ? '훈련 기록 타임라인' : 'Training timeline',
      subtitle: _isKo
          ? '훈련이 많아 유형별로 묶어 보여줍니다. 탭해서 펼치세요.'
          : 'Many logs are grouped by type. Tap to expand.',
      child: Column(
        children: grouped.entries.map((group) {
          final groupKey = _trainingGroupKey(day.date, group.key);
          final expanded = _expandedTrainingGroups.contains(groupKey);
          final items = group.value;
          final totalMinutes = items.fold<int>(
            0,
            (sum, entry) => sum + entry.durationMinutes,
          );
          final preview = _trainingSummaryShort(items.first);
          return Container(
            width: double.infinity,
            margin: const EdgeInsets.only(bottom: 10),
            decoration: BoxDecoration(
              color: _tileSurface,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: _paperEdge),
            ),
            child: InkWell(
              borderRadius: BorderRadius.circular(14),
              onTap: () {
                setState(() {
                  if (expanded) {
                    _expandedTrainingGroups.remove(groupKey);
                  } else {
                    _expandedTrainingGroups.add(groupKey);
                  }
                });
              },
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            '${group.key} · ${items.length}${_isKo ? '회' : 'x'} · $totalMinutes${_isKo ? '분' : ' min'}',
                            style: _theme.textTheme.labelLarge?.copyWith(
                              color: _headlineInk,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                        Icon(
                          expanded ? Icons.expand_less : Icons.expand_more,
                          color: _accentInk,
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      preview,
                      maxLines: expanded ? null : 2,
                      overflow: expanded
                          ? TextOverflow.visible
                          : TextOverflow.ellipsis,
                      style: _theme.textTheme.bodySmall?.copyWith(
                        color: _bodyInk,
                        height: 1.4,
                      ),
                    ),
                    if (expanded) ...[
                      const SizedBox(height: 8),
                      ...items.map(
                        (entry) => Padding(
                          padding: const EdgeInsets.only(bottom: 6),
                          child: _buildSummaryLine(
                            '${_formatTime(entry.date)} · ${_trainingSummaryShort(entry)}',
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          );
        }).toList(growable: false),
      ),
    );
  }

  Widget _buildTrainingRecordPage({
    required TrainingEntry entry,
    required int page,
    required int totalPages,
  }) {
    final title = entry.type.trim().isEmpty
        ? (_isKo ? '훈련' : 'Training')
        : entry.type.trim();
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
      decoration: BoxDecoration(
        color: _tileSurface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _paperEdge),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: _theme.textTheme.labelLarge?.copyWith(
                    color: _headlineInk,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              if (totalPages > 1)
                Text(
                  '$page / $totalPages',
                  style: _theme.textTheme.labelMedium?.copyWith(
                    color: _bodyInk,
                    fontWeight: FontWeight.w700,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              physics: const BouncingScrollPhysics(),
              children: [
                Text(
                  _trainingSummary(entry),
                  maxLines: 5,
                  overflow: TextOverflow.ellipsis,
                  style: _theme.textTheme.bodyMedium?.copyWith(
                    color: _bodyInk,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Map<String, List<TrainingEntry>> _groupTrainingEntriesByType(
    List<TrainingEntry> entries,
  ) {
    final grouped = <String, List<TrainingEntry>>{};
    for (final entry in entries) {
      final type = entry.type.trim().isEmpty
          ? (_isKo ? '기본 훈련' : 'General training')
          : entry.type.trim();
      grouped.putIfAbsent(type, () => <TrainingEntry>[]).add(entry);
    }
    return grouped;
  }

  String _trainingGroupKey(DateTime date, String type) {
    final dayKey = DateFormat('yyyy-MM-dd').format(date);
    return '$dayKey::$type';
  }

  String _trainingSummaryShort(TrainingEntry entry) {
    final detail = _trainingSummary(entry);
    final firstLine = detail.split('\n').first;
    final parts = firstLine
        .split(' · ')
        .map((part) => part.trim())
        .where((part) => part.isNotEmpty)
        .toList(growable: false);
    if (parts.length <= 2) return firstLine;
    return parts.take(2).join(' · ');
  }

  Widget _buildRecoveryCard(_DiaryDayData day) {
    final lifting = _buildLiftingSummary(day.entries);
    final jumpRope = _buildJumpRopeSummary(day.entries);
    final injuryNotes = day.entries
        .where((entry) => entry.injury)
        .map(_injurySummary)
        .toList(growable: false);
    return _buildPaperCard(
      title: _isKo ? '부상 · 리프팅 · 줄넘기' : 'Injury, lifting, jump rope',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (injuryNotes.isNotEmpty)
            _buildSummaryLine(
              _isKo
                  ? '부상: ${injuryNotes.join(' / ')}'
                  : 'Injury: ${injuryNotes.join(' / ')}',
            ),
          if (lifting.isNotEmpty)
            _buildSummaryLine(_isKo ? '리프팅: $lifting' : 'Lifting: $lifting'),
          if (jumpRope.isNotEmpty)
            _buildSummaryLine(
              _isKo ? '줄넘기: $jumpRope' : 'Jump rope: $jumpRope',
            ),
        ],
      ),
    );
  }

  Widget _buildBoardCard(_DiaryDayData day) {
    return _buildPaperCard(
      title: _isKo ? '다이어리에 담긴 훈련보드' : 'Training boards in this diary',
      subtitle: _isKo
          ? '실제 보드 화면과 보드 메모, 연결된 기록 메모를 함께 남깁니다.'
          : 'Keeps the board preview, board memo, and linked log notes together.',
      child: Column(
        children: day.boards
            .map((board) => _buildBoardDiaryTile(day: day, board: board))
            .toList(growable: false),
      ),
    );
  }

  Widget _buildEmptyCard() {
    return _buildPaperCard(
      title: _isKo ? '아직 기록이 없습니다.' : 'No records yet',
      child: Text(
        _isKo
            ? '훈련이나 시합, 계획을 남기면 날짜별 다이어리 페이지가 자동으로 만들어집니다.'
            : 'Once you add a training note, match, or plan, this screen will build a diary page for that date.',
        style: Theme.of(
          context,
        ).textTheme.bodyMedium?.copyWith(color: _bodyInk, height: 1.5),
      ),
    );
  }

  Widget _buildPaperCard({
    required String title,
    String? subtitle,
    Widget? trailing,
    required Widget child,
  }) {
    return Container(
      decoration: _paperDecoration(),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style:
                            Theme.of(context).textTheme.titleMedium?.copyWith(
                                  color: _headlineInk,
                                  fontWeight: FontWeight.w900,
                                ),
                      ),
                      if (subtitle != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          subtitle,
                          style: Theme.of(context)
                              .textTheme
                              .bodySmall
                              ?.copyWith(color: _bodyInk, height: 1.45),
                        ),
                      ],
                    ],
                  ),
                ),
                if (trailing != null) trailing,
              ],
            ),
            const SizedBox(height: 14),
            child,
          ],
        ),
      ),
    );
  }

  Widget _buildTimelineTile({required String title, required String detail}) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
      decoration: BoxDecoration(
        color: _tileSurface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _paperEdge),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  color: _headlineInk,
                  fontWeight: FontWeight.w800,
                ),
          ),
          const SizedBox(height: 4),
          Text(
            detail,
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: _bodyInk, height: 1.45),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryLine(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        text,
        style: Theme.of(
          context,
        ).textTheme.bodyMedium?.copyWith(color: _headlineInk, height: 1.5),
      ),
    );
  }

  BoxDecoration _paperDecoration() {
    return BoxDecoration(
      color: _paperSurface,
      borderRadius: BorderRadius.circular(26),
      border: Border.all(color: _paperEdge),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withValues(alpha: _isDark ? 0.26 : 0.07),
          blurRadius: _isDark ? 26 : 18,
          offset: const Offset(0, 10),
        ),
      ],
    );
  }

  List<_DiaryDayData> _buildDays(
    List<TrainingEntry> entries,
    List<_DiaryPlan> plans,
    Map<String, TrainingBoard> boardMap,
  ) {
    final dayKeys = <DateTime>{};
    final entriesByDay = <DateTime, List<TrainingEntry>>{};
    final plansByDay = <DateTime, List<_DiaryPlan>>{};

    for (final entry in entries) {
      final day = _normalizeDay(entry.date);
      dayKeys.add(day);
      entriesByDay.putIfAbsent(day, () => <TrainingEntry>[]).add(entry);
    }
    for (final plan in plans) {
      final day = _normalizeDay(plan.scheduledAt);
      dayKeys.add(day);
      plansByDay.putIfAbsent(day, () => <_DiaryPlan>[]).add(plan);
    }

    final days = dayKeys.map((day) {
      final dayEntries = entriesByDay[day] ?? const <TrainingEntry>[];
      final linkedBoards = <String, TrainingBoard>{};
      for (final entry in dayEntries) {
        for (final id in TrainingBoardLinkCodec.decodeBoardIds(
          entry.drills,
        )) {
          final board = boardMap[id];
          if (board != null) linkedBoards[id] = board;
        }
      }
      return _DiaryDayData(
        date: day,
        entries: [...dayEntries]..sort((a, b) => a.date.compareTo(b.date)),
        plans: [...(plansByDay[day] ?? const <_DiaryPlan>[])]
          ..sort((a, b) => a.scheduledAt.compareTo(b.scheduledAt)),
        boards: linkedBoards.values.toList(growable: false)
          ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt)),
      );
    }).toList(growable: false)
      ..sort((a, b) => b.date.compareTo(a.date));
    return days;
  }

  List<_DiaryPlan> _loadPlans() {
    final raw = widget.optionRepository.getValue<String>(_plansStorageKey);
    if (raw == null || raw.trim().isEmpty) return const <_DiaryPlan>[];
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) return const <_DiaryPlan>[];
      return decoded
          .whereType<Map>()
          .map((map) => _DiaryPlan.fromMap(map.cast<String, dynamic>()))
          .toList(growable: false);
    } catch (_) {
      return const <_DiaryPlan>[];
    }
  }

  String _buildDiary(_DiaryDayData day) {
    final paragraphs = <String>[
      _isKo
          ? '${_formatDiaryDate(day.date)} 기록을 코치 시선으로 다시 읽는다. 주된 장소는 ${_topPlaces(day.entries)}였고, 오늘 훈련의 중심은 ${_topFocus(day.trainingEntries)}에 모였다.'
          : 'This is the coach-style review for ${_formatDiaryDate(day.date)}. The main place was ${_topPlaces(day.entries)}, and the day centered on ${_topFocus(day.trainingEntries)}.',
    ];

    if (day.plans.isNotEmpty) {
      final planLines = day.plans
          .map(
            (plan) => _isKo
                ? '${_formatTime(plan.scheduledAt)} ${plan.category} ${plan.durationMinutes}분${plan.note.trim().isEmpty ? '' : ' (${plan.note.trim()})'}'
                : '${_formatTime(plan.scheduledAt)} ${plan.category} ${plan.durationMinutes} min${plan.note.trim().isEmpty ? '' : ' (${plan.note.trim()})'}',
          )
          .join(', ');
      paragraphs.add(
        _isKo
            ? '코치 메모에는 오늘 계획이 $planLines 순서로 남아 있다. 계획선이 분명해서 훈련 흐름도 크게 흔들리지 않았다.'
            : 'The coach note keeps today\'s plan in this order: $planLines. Because the plan line was clear, the training flow stayed steady.',
      );
    }

    if (day.trainingEntries.isNotEmpty) {
      final totalMinutes = day.trainingEntries.fold<int>(
        0,
        (sum, entry) => sum + entry.durationMinutes,
      );
      paragraphs.add(
        _isKo
            ? '오늘 훈련은 ${day.trainingEntries.length}회, 총 $totalMinutes분이다. ${day.trainingEntries.map(_trainingDiarySentence).join(' ')}'
            : 'There were ${day.trainingEntries.length} training blocks today for a total of $totalMinutes minutes. ${day.trainingEntries.map(_trainingDiarySentence).join(' ')}',
      );
    }

    if (day.matchEntries.isNotEmpty) {
      paragraphs.add(
        _isKo
            ? '시합 장면에서는 ${day.matchEntries.map(_matchDiarySentence).join(' ')}'
            : 'In the match phase, ${day.matchEntries.map(_matchDiarySentence).join(' ')}',
      );
    }

    final recoveryParagraph = _buildRecoveryDiaryParagraph(day);
    if (recoveryParagraph.isNotEmpty) {
      paragraphs.add(recoveryParagraph);
    }

    final boardParagraph = _buildBoardDiaryParagraph(day);
    if (boardParagraph.isNotEmpty) {
      paragraphs.add(boardParagraph);
    }

    paragraphs.add(
      _isKo
          ? '코치 정리로 남기면 오늘 기록은 결과보다 흐름을 보여 준다. 잘된 장면과 흔들린 장면을 같이 남겨야 다음 목표도 더 정확해진다.'
          : 'As a coach recap, today\'s record shows the flow more than the result. Keeping the steady and shaky moments together makes the next goal clearer.',
    );
    return paragraphs.join('\n\n');
  }

  String _topFocus(List<TrainingEntry> entries) {
    if (entries.isEmpty) return _isKo ? '기본기' : 'fundamentals';
    final counts = <String, int>{};
    for (final entry in entries) {
      for (final raw in <String>[
        entry.program,
        entry.type,
        ...entry.goalFocuses,
      ]) {
        final text = raw.trim();
        if (text.isEmpty) continue;
        counts[text] = (counts[text] ?? 0) + 1;
      }
    }
    if (counts.isEmpty) return _isKo ? '기본기' : 'fundamentals';
    final sorted = counts.entries.toList()
      ..sort((a, b) {
        final countCompare = b.value.compareTo(a.value);
        if (countCompare != 0) return countCompare;
        return a.key.compareTo(b.key);
      });
    return sorted.first.key;
  }

  String _topPlaces(List<TrainingEntry> entries) {
    final counts = <String, int>{};
    for (final entry in entries) {
      final value = entry.effectiveMatchLocation.trim();
      if (value.isEmpty) continue;
      counts[value] = (counts[value] ?? 0) + 1;
    }
    if (counts.isEmpty) {
      return _isKo ? '장소 기록 없음' : 'No location logged';
    }
    final sorted = counts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return sorted.take(2).map((entry) => entry.key).join(', ');
  }

  bool _hasRecoveryRecord(_DiaryDayData day) {
    return day.entries.any(
      (entry) =>
          entry.injury ||
          entry.liftingByPart.values.any((count) => count > 0) ||
          entry.jumpRopeCount > 0 ||
          entry.jumpRopeMinutes > 0 ||
          entry.jumpRopeNote.trim().isNotEmpty,
    );
  }

  String _trainingSummary(TrainingEntry entry) {
    final cleanNotes = _stripWeatherFromNotes(entry.notes);
    final locationText = entry.location.trim().isEmpty
        ? (_isKo ? '장소 기록 없음' : 'no location logged')
        : entry.location.trim();
    final meta = <String>[
      '${entry.durationMinutes}${_isKo ? '분' : ' min'}',
      _isKo ? '장소 $locationText' : 'Place $locationText',
      _isKo ? '강도 ${entry.intensity}' : 'Intensity ${entry.intensity}',
      _isKo ? '컨디션 ${entry.mood}' : 'Condition ${entry.mood}',
    ];
    final details = <String>[
      if (_trainingProgramLabel(entry).isNotEmpty) _trainingProgramLabel(entry),
      if (!TrainingBoardLinkCodec.isBoardLinkPayload(entry.drills) &&
          entry.drills.trim().isNotEmpty)
        entry.drills.trim(),
      if (cleanNotes.isNotEmpty) cleanNotes,
    ];
    final firstLine = details.isEmpty
        ? meta.join(' · ')
        : '${meta.join(' · ')} · ${details.join(' · ')}';
    final focusLines = _trainingFocusLines(entry);
    return focusLines.isEmpty
        ? firstLine
        : '$firstLine\n${focusLines.join('\n')}';
  }

  String _trainingDiarySentence(TrainingEntry entry) {
    final cleanNotes = _stripWeatherFromNotes(entry.notes);
    final locationText = entry.location.trim().isEmpty
        ? '장소 기록 없이'
        : '${entry.location.trim()}에서';
    final noteParts = <String>[
      _isKo
          ? '강도 ${entry.intensity}, 컨디션 ${entry.mood}로 ${entry.type} ${entry.durationMinutes}분을 진행했다'
          : '${entry.type} ran for ${entry.durationMinutes} minutes with intensity ${entry.intensity} and condition ${entry.mood}',
      if (_trainingProgramLabel(entry).isNotEmpty)
        _isKo
            ? '훈련 프로그램은 ${_trainingProgramLabel(entry)}로 정리했다'
            : 'the training program was ${_trainingProgramLabel(entry)}',
      if (entry.goodPoints.trim().isNotEmpty)
        _isKo
            ? '잘된 장면은 ${entry.goodPoints.trim()}'
            : 'the part that held up was ${entry.goodPoints.trim()}',
      if (entry.improvements.trim().isNotEmpty)
        _isKo
            ? '아직 손봐야 할 부분은 ${entry.improvements.trim()}'
            : 'what still asks for attention is ${entry.improvements.trim()}',
      if (cleanNotes.isNotEmpty)
        _isKo ? '메모에는 $cleanNotes' : 'the note admitted $cleanNotes',
    ];
    final goalText = _trainingGoalText(entry);
    if (goalText.isNotEmpty) {
      noteParts.add(
        _isKo ? '다음 훈련 목표는 $goalText' : 'the next training goal is $goalText',
      );
    }
    final suffix = noteParts.isEmpty ? '' : ' ${noteParts.join('. ')}.';
    return _isKo
        ? '코치는 $locationText 오늘 훈련을 확인한다.$suffix'
        : '${entry.type} stayed with the body for ${entry.durationMinutes} minutes ${entry.location.trim().isEmpty ? 'without a logged place' : 'at ${entry.location.trim()}'}.$suffix';
  }

  String _trainingProgramLabel(TrainingEntry entry) {
    final program = entry.program.trim();
    if (program.isEmpty) return '';
    if (program == entry.type.trim()) return '';
    return program;
  }

  String _trainingGoalText(TrainingEntry entry) {
    if (entry.nextGoal.trim().isNotEmpty) return entry.nextGoal.trim();
    if (entry.goalFocuses.isNotEmpty) return entry.goalFocuses.join(', ');
    if (entry.goal.trim().isNotEmpty) return entry.goal.trim();
    return '';
  }

  List<String> _trainingFocusLines(TrainingEntry entry) {
    final lines = <String>[];
    final goalText = _trainingGoalText(entry);
    if (goalText.isNotEmpty) {
      lines.add(_isKo ? '훈련 목표: $goalText' : 'Training goal: $goalText');
    }
    if (entry.goodPoints.trim().isNotEmpty) {
      lines.add(
        _isKo
            ? '잘한 점: ${entry.goodPoints.trim()}'
            : 'Strong point: ${entry.goodPoints.trim()}',
      );
    }
    if (entry.improvements.trim().isNotEmpty) {
      lines.add(
        _isKo
            ? '아쉬운 점: ${entry.improvements.trim()}'
            : 'Needs work: ${entry.improvements.trim()}',
      );
    }
    return lines;
  }

  String _extractWeatherFromNotes(String notes) {
    for (final line in notes.split('\n')) {
      final trimmed = line.trim();
      if (trimmed.startsWith('[Weather] ')) {
        return trimmed.substring('[Weather] '.length).trim();
      }
      if (trimmed.startsWith('[날씨] ')) {
        return trimmed.substring('[날씨] '.length).trim();
      }
    }
    return '';
  }

  String _stripWeatherFromNotes(String notes) {
    return notes
        .split('\n')
        .map((line) => line.trimRight())
        .where((line) => !line.trim().startsWith('[Weather]'))
        .where((line) => !line.trim().startsWith('[날씨]'))
        .join('\n')
        .trim();
  }

  String _dayWeatherSummary(_DiaryDayData day) {
    for (final entry in day.trainingEntries) {
      final weather = _extractWeatherFromNotes(entry.notes);
      if (weather.isNotEmpty) return weather;
    }
    return '';
  }

  IconData? _weatherIconForSummary(String summary) {
    final text = summary.toLowerCase();
    if (text.isEmpty) return null;
    if (text.contains('번개') || text.contains('thunder')) {
      return Icons.thunderstorm_outlined;
    }
    if (text.contains('눈') || text.contains('snow')) {
      return Icons.ac_unit;
    }
    if (text.contains('비') ||
        text.contains('rain') ||
        text.contains('drizzle')) {
      return Icons.umbrella_outlined;
    }
    if (text.contains('맑') || text.contains('clear') || text.contains('sun')) {
      return Icons.wb_sunny_outlined;
    }
    if (text.contains('구름') ||
        text.contains('cloud') ||
        text.contains('안개') ||
        text.contains('fog')) {
      return Icons.cloud_outlined;
    }
    return Icons.wb_cloudy_outlined;
  }

  String _matchSummary(TrainingEntry entry) {
    final parts = <String>[
      if (_isKo)
        '${entry.opponentTeam.isEmpty ? '상대 팀 미기록' : entry.opponentTeam}전'
      else
        'vs ${entry.opponentTeam.isEmpty ? 'unknown opponent' : entry.opponentTeam}',
      if (entry.scoredGoals != null || entry.concededGoals != null)
        _isKo
            ? '스코어 ${entry.scoredGoals ?? 0}:${entry.concededGoals ?? 0}'
            : 'score ${entry.scoredGoals ?? 0}:${entry.concededGoals ?? 0}',
      if (entry.playerGoals != null)
        _isKo ? '개인 득점 ${entry.playerGoals}' : 'goals ${entry.playerGoals}',
      if (entry.playerAssists != null)
        _isKo ? '도움 ${entry.playerAssists}' : 'assists ${entry.playerAssists}',
      if (entry.minutesPlayed != null)
        _isKo
            ? '출전 ${entry.minutesPlayed}분'
            : '${entry.minutesPlayed} min played',
      if (entry.effectiveMatchLocation.trim().isNotEmpty)
        entry.effectiveMatchLocation.trim(),
      if (entry.notes.trim().isNotEmpty) entry.notes.trim(),
    ];
    return parts.join(' · ');
  }

  String _matchDiarySentence(TrainingEntry entry) {
    final result = (entry.scoredGoals != null || entry.concededGoals != null)
        ? '${entry.scoredGoals ?? 0}:${entry.concededGoals ?? 0}'
        : null;
    final extras = <String>[
      if (entry.playerGoals != null)
        _isKo ? '개인 득점 ${entry.playerGoals}' : '${entry.playerGoals} goal(s)',
      if (entry.playerAssists != null)
        _isKo
            ? '도움 ${entry.playerAssists}'
            : '${entry.playerAssists} assist(s)',
      if (entry.notes.trim().isNotEmpty) entry.notes.trim(),
    ];
    return _isKo
        ? '${entry.opponentTeam.isEmpty ? '이름이 남지 않은 경기' : '${entry.opponentTeam}전'}${result == null ? '' : '은 $result'}으로 기록됐다.${extras.isEmpty ? ' 점수만큼 마음의 결도 남아 있었을 것이다.' : ' 그리고 ${extras.join(', ')}까지 빠짐없이 적어 두었다.'}'
        : '${entry.opponentTeam.isEmpty ? 'a match with no opponent logged' : 'the match against ${entry.opponentTeam}'}${result == null ? '' : ' finished $result'}.${extras.isEmpty ? ' The score remains, even if the finer emotions were left unsaid.' : ' The notes also kept ${extras.join(', ')} close.'}';
  }

  String _injurySummary(TrainingEntry entry) {
    final parts = <String>[
      if (entry.injuryPart.trim().isNotEmpty)
        entry.injuryPart.trim()
      else if (_isKo)
        '부위 미기록'
      else
        'part not logged',
      if (entry.painLevel != null)
        _isKo ? '통증 ${entry.painLevel}/10' : 'pain ${entry.painLevel}/10',
      if (entry.rehab) _isKo ? '재활 포함' : 'rehab included',
    ];
    return parts.join(' · ');
  }

  String _buildLiftingSummary(List<TrainingEntry> entries) {
    final totals = <String, int>{};
    for (final entry in entries) {
      entry.liftingByPart.forEach((part, count) {
        if (count <= 0) return;
        totals[part] = (totals[part] ?? 0) + count;
      });
    }
    if (totals.isEmpty) return '';
    final sorted = totals.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return sorted
        .map((entry) => '${_liftingPartLabel(entry.key)} ${entry.value}회')
        .join(', ');
  }

  String _buildJumpRopeSummary(List<TrainingEntry> entries) {
    final totalCount = entries.fold<int>(
      0,
      (sum, entry) => sum + entry.jumpRopeCount,
    );
    final totalMinutes = entries.fold<int>(
      0,
      (sum, entry) => sum + entry.jumpRopeMinutes,
    );
    final notes = entries
        .map((entry) => entry.jumpRopeNote.trim())
        .where((text) => text.isNotEmpty)
        .toSet()
        .toList(growable: false);
    if (totalCount == 0 && totalMinutes == 0 && notes.isEmpty) return '';
    final parts = <String>[
      if (totalCount > 0) _isKo ? '$totalCount회' : '$totalCount reps',
      if (totalMinutes > 0) _isKo ? '$totalMinutes분' : '$totalMinutes min',
      if (notes.isNotEmpty) notes.join(' / '),
    ];
    return parts.join(' · ');
  }

  String _buildRecoveryDiaryParagraph(_DiaryDayData day) {
    final injuries = day.entries
        .where((entry) => entry.injury)
        .map(_injurySummary)
        .toList(growable: false);
    final lifting = _buildLiftingSummary(day.entries);
    final jumpRope = _buildJumpRopeSummary(day.entries);
    if (injuries.isEmpty && lifting.isEmpty && jumpRope.isEmpty) return '';
    final parts = <String>[
      if (injuries.isNotEmpty)
        _isKo
            ? '부상 기록은 ${injuries.join(' / ')}'
            : 'injury notes were ${injuries.join(' / ')}',
      if (lifting.isNotEmpty) _isKo ? '리프팅은 $lifting' : 'lifting was $lifting',
      if (jumpRope.isNotEmpty)
        _isKo ? '줄넘기는 $jumpRope' : 'jump rope was $jumpRope',
    ];
    return _isKo
        ? '몸을 돌보는 기록까지 펼쳐 보면 ${parts.join(', ')}. 눈에 띄지 않는 반복이었지만 이런 장면들이 결국 하루의 밀도를 만든다.'
        : 'When the quieter recovery work is unfolded, ${parts.join(', ')}. They are easy to overlook, but this is often where the day gathers its real density.';
  }

  String _liftingPartLabel(String key) {
    switch (key) {
      case 'infront':
        return _l10n.liftingPartInfront;
      case 'inside':
        return _l10n.liftingPartInside;
      case 'outside':
        return _l10n.liftingPartOutside;
      case 'muple':
        return _l10n.liftingPartMuple;
      case 'head':
        return _l10n.liftingPartHead;
      case 'chest':
        return _l10n.liftingPartChest;
      case 'left_foot':
        return '${_l10n.liftingPartInfront} (${_l10n.legacyLabel})';
      case 'right_foot':
        return '${_l10n.liftingPartInside} (${_l10n.legacyLabel})';
      case 'left_thigh':
        return '${_l10n.liftingPartOutside} (${_l10n.legacyLabel})';
      case 'right_thigh':
        return '${_l10n.liftingPartMuple} (${_l10n.legacyLabel})';
      case 'back':
        return '${_l10n.liftingPartInside} (${_l10n.oldLabel})';
      case 'legs':
        return '${_l10n.liftingPartOutside} (${_l10n.oldLabel})';
      case 'shoulders':
        return '${_l10n.liftingPartMuple} (${_l10n.oldLabel})';
      case 'arms':
        return '${_l10n.liftingPartHead} (${_l10n.legacyLabel})';
      case 'core':
        return '${_l10n.liftingPartChest} (${_l10n.legacyLabel})';
      default:
        return key;
    }
  }

  String _buildBoardDiaryParagraph(_DiaryDayData day) {
    if (day.boards.isEmpty) return '';
    final boardNotes = day.boards.map((board) {
      final layout = TrainingMethodLayout.decode(board.layoutJson);
      final memo =
          layout.pages.isNotEmpty ? layout.pages.first.methodText.trim() : '';
      if (_isKo) {
        return memo.isEmpty ? board.title : '${board.title} 메모는 "$memo"';
      }
      return memo.isEmpty ? board.title : '${board.title} memo was "$memo"';
    }).join(' / ');
    return _isKo
        ? '훈련보드에는 $boardNotes 같은 그림과 메모가 남아 있다. 말로 다 적지 못한 움직임은 이런 도식 안에서 다시 또렷해진다.'
        : 'The training boards kept sketches and notes such as $boardNotes. The movements that were difficult to explain in plain sentences become clear again inside those diagrams.';
  }

  Widget _buildBoardDiaryTile({
    required _DiaryDayData day,
    required TrainingBoard board,
  }) {
    final layout = TrainingMethodLayout.decode(board.layoutJson);
    final page = layout.pages.isNotEmpty ? layout.pages.first : null;
    final boardMemo = page?.methodText.trim() ?? '';
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
      decoration: BoxDecoration(
        color: _tileSurface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _paperEdge),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  board.title,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        color: _headlineInk,
                        fontWeight: FontWeight.w800,
                      ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                _isKo
                    ? DateFormat('M.d HH:mm', 'ko').format(board.updatedAt)
                    : DateFormat('MMM d HH:mm', 'en').format(board.updatedAt),
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: _bodyInk),
              ),
            ],
          ),
          const SizedBox(height: 10),
          _DiaryBoardPreview(layout: layout),
          if (boardMemo.isNotEmpty) ...[
            const SizedBox(height: 10),
            _buildSummaryLine(
              _isKo ? '보드 메모: $boardMemo' : 'Board note: $boardMemo',
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _copyDiary(String diary) async {
    await Clipboard.setData(ClipboardData(text: diary));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(_isKo ? '일기를 복사했어요.' : 'Diary copied.')),
    );
  }

  DateTime _normalizeDay(DateTime value) {
    return DateTime(value.year, value.month, value.day);
  }

  Future<void> _pickDiaryDate(
    List<_DiaryDayData> days,
    int selectedIndex,
  ) async {
    final selectedDay = days[selectedIndex].date;
    final availableDays = days.map((day) => day.date).toSet();
    final picked = await showDatePicker(
      context: context,
      initialDate: selectedDay,
      firstDate: days.last.date,
      lastDate: days.first.date,
      selectableDayPredicate: (day) =>
          availableDays.contains(_normalizeDay(day)),
      locale: Locale(_isKo ? 'ko' : 'en'),
    );
    if (picked == null) return;
    final normalized = _normalizeDay(picked);
    final targetIndex = days.indexWhere((day) => day.date == normalized);
    if (targetIndex == -1) return;
    setState(() => _selectedDayIndex = targetIndex);
    await _movePage(targetIndex);
  }

  String _formatDiaryDate(DateTime date) {
    return _isKo
        ? DateFormat('M월 d일 EEEE', 'ko').format(date)
        : DateFormat('EEE, MMM d', 'en').format(date);
  }

  String _formatTime(DateTime date) {
    return _isKo
        ? DateFormat('a h:mm', 'ko').format(date)
        : DateFormat('h:mm a', 'en').format(date);
  }

  Widget _buildNotebookSheet({required Widget child}) {
    return Container(
      decoration: _paperDecoration(),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(26),
        child: Stack(
          children: [
            Positioned.fill(
              child: CustomPaint(
                painter: _NotebookSheetPainter(
                  lineColor: _notebookLine,
                  marginColor: _notebookMargin,
                  holeColor: _holeColor,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(32, 18, 18, 18),
              child: child,
            ),
          ],
        ),
      ),
    );
  }
}

class _NotebookSheetPainter extends CustomPainter {
  final Color lineColor;
  final Color marginColor;
  final Color holeColor;

  const _NotebookSheetPainter({
    required this.lineColor,
    required this.marginColor,
    required this.holeColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final linePaint = Paint()
      ..color = lineColor
      ..strokeWidth = 1;
    final marginPaint = Paint()
      ..color = marginColor
      ..strokeWidth = 1.4;
    final holePaint = Paint()..color = holeColor;
    final holeBorder = Paint()
      ..color = lineColor.withValues(alpha: 0.7)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;

    canvas.drawLine(const Offset(22, 0), Offset(22, size.height), marginPaint);

    for (double y = 24; y < size.height; y += 28) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), linePaint);
    }

    for (double y = 28; y < size.height - 8; y += 72) {
      canvas.drawCircle(Offset(12, y), 5, holePaint);
      canvas.drawCircle(Offset(12, y), 5, holeBorder);
    }
  }

  @override
  bool shouldRepaint(covariant _NotebookSheetPainter oldDelegate) {
    return oldDelegate.lineColor != lineColor ||
        oldDelegate.marginColor != marginColor ||
        oldDelegate.holeColor != holeColor;
  }
}

class _DiaryBoardPreview extends StatelessWidget {
  final TrainingMethodLayout layout;

  const _DiaryBoardPreview({required this.layout});

  @override
  Widget build(BuildContext context) {
    final previewPage = layout.pages.isNotEmpty
        ? layout.pages.first
        : TrainingMethodLayout.empty().pages.first;
    final itemCount = layout.pages.fold<int>(
      0,
      (sum, page) => sum + page.items.length,
    );
    return Container(
      height: 148,
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        gradient: const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF2E7D32), Color(0xFF1B5E20)],
        ),
        border: Border.all(color: Colors.white.withValues(alpha: 0.24)),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final width = constraints.maxWidth;
          final height = constraints.maxHeight;
          return Stack(
            children: [
              CustomPaint(
                size: Size(width, height),
                painter: _DiaryBoardPreviewPainter(page: previewPage),
              ),
              ...previewPage.items.take(14).map((item) {
                final icon = switch (item.type) {
                  'cone' => Icons.change_history,
                  'player' => Icons.person,
                  'ball' => Icons.sports_soccer,
                  'ladder' => Icons.view_week,
                  _ => Icons.circle,
                };
                return Positioned(
                  left: (item.x * width).clamp(6.0, width - 20.0),
                  top: (item.y * height).clamp(4.0, height - 20.0),
                  child: Transform.rotate(
                    angle: item.rotationDeg * 3.1415926535897932 / 180,
                    child: Icon(
                      icon,
                      size: (item.size * 0.42).clamp(10.0, 20.0),
                      color: Color(item.colorValue).withValues(alpha: 0.96),
                    ),
                  ),
                );
              }),
              Positioned(
                right: 8,
                top: 8,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    '$itemCount',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _DiaryBoardPreviewPainter extends CustomPainter {
  final TrainingMethodPage page;

  const _DiaryBoardPreviewPainter({required this.page});

  @override
  void paint(Canvas canvas, Size size) {
    final line = Paint()
      ..color = Colors.white.withValues(alpha: 0.55)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4;
    final pathPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.72)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.8
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final centerX = size.width / 2;
    final centerY = size.height / 2;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(2, 2, size.width - 4, size.height - 4),
        const Radius.circular(14),
      ),
      line,
    );
    canvas.drawLine(Offset(centerX, 2), Offset(centerX, size.height - 2), line);
    canvas.drawCircle(Offset(centerX, centerY), 16, line);

    for (final stroke in page.strokes) {
      if (stroke.points.length < 2) continue;
      final strokePaint = Paint()
        ..color = Color(stroke.colorValue).withValues(alpha: 0.92)
        ..style = PaintingStyle.stroke
        ..strokeWidth = stroke.width.clamp(1.0, 4.0)
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round;
      final path = Path()
        ..moveTo(
          stroke.points.first.x * size.width,
          stroke.points.first.y * size.height,
        );
      for (final point in stroke.points.skip(1)) {
        path.lineTo(point.x * size.width, point.y * size.height);
      }
      canvas.drawPath(path, strokePaint);
    }

    if (page.playerPath.length >= 2) {
      final playerPath = Path()
        ..moveTo(
          page.playerPath.first.x * size.width,
          page.playerPath.first.y * size.height,
        );
      for (final point in page.playerPath.skip(1)) {
        playerPath.lineTo(point.x * size.width, point.y * size.height);
      }
      canvas.drawPath(playerPath, pathPaint);
    }

    if (page.ballPath.length >= 2) {
      final ballPaint = Paint()
        ..color = const Color(0xFFFFF59D)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.6
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round;
      final ballPath = Path()
        ..moveTo(
          page.ballPath.first.x * size.width,
          page.ballPath.first.y * size.height,
        );
      for (final point in page.ballPath.skip(1)) {
        ballPath.lineTo(point.x * size.width, point.y * size.height);
      }
      canvas.drawPath(ballPath, ballPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _DiaryBoardPreviewPainter oldDelegate) {
    return oldDelegate.page != page;
  }
}

class _DiaryThemePalette {
  final String id;
  final String nameKo;
  final String nameEn;
  final String descriptionKo;
  final String descriptionEn;
  final Color paper;
  final Color paperBorder;
  final Color paperDark;
  final Color paperBorderDark;
  final Color headlineInk;
  final Color bodyInk;
  final Color accentInk;
  final Color headlineInkDark;
  final Color bodyInkDark;
  final Color accentInkDark;
  final Color notebookLine;
  final Color notebookMargin;
  final Color holeColor;
  final Color notebookLineDark;
  final Color notebookMarginDark;
  final Color holeColorDark;
  final Color tileDark;

  const _DiaryThemePalette({
    required this.id,
    required this.nameKo,
    required this.nameEn,
    required this.descriptionKo,
    required this.descriptionEn,
    required this.paper,
    required this.paperBorder,
    required this.paperDark,
    required this.paperBorderDark,
    required this.headlineInk,
    required this.bodyInk,
    required this.accentInk,
    required this.headlineInkDark,
    required this.bodyInkDark,
    required this.accentInkDark,
    required this.notebookLine,
    required this.notebookMargin,
    required this.holeColor,
    required this.notebookLineDark,
    required this.notebookMarginDark,
    required this.holeColorDark,
    required this.tileDark,
  });

  static const notebook = _DiaryThemePalette(
    id: 'notebook',
    nameKo: '노트북',
    nameEn: 'Notebook',
    descriptionKo: '차분한 종이 질감의 기본 다이어리입니다.',
    descriptionEn: 'A calm paper-textured default diary.',
    paper: Color(0xFFF7F1E7),
    paperBorder: Color(0xFFD8CBB5),
    paperDark: Color(0xFF1F242A),
    paperBorderDark: Color(0xFF48525C),
    headlineInk: Color(0xFF123B2D),
    bodyInk: Color(0xFF6E5A49),
    accentInk: Color(0xFF0F5A43),
    headlineInkDark: Color(0xFFE8F1EA),
    bodyInkDark: Color(0xFFC0C9C5),
    accentInkDark: Color(0xFF82D4B5),
    notebookLine: Color(0xFFC8DBF5),
    notebookMargin: Color(0xFFE6A6A6),
    holeColor: Color(0xFFE6DDCF),
    notebookLineDark: Color(0xFF324252),
    notebookMarginDark: Color(0xFF855A63),
    holeColorDark: Color(0xFF171C20),
    tileDark: Color(0xFF283038),
  );

  static const dusk = _DiaryThemePalette(
    id: 'dusk',
    nameKo: '노을',
    nameEn: 'Dusk',
    descriptionKo: '붉은 저녁빛처럼 따뜻한 분위기로 읽습니다.',
    descriptionEn: 'Reads in the warmth of a red evening glow.',
    paper: Color(0xFFF9EEE8),
    paperBorder: Color(0xFFE2C8BE),
    paperDark: Color(0xFF2B2325),
    paperBorderDark: Color(0xFF625055),
    headlineInk: Color(0xFF5A2E27),
    bodyInk: Color(0xFF7A544C),
    accentInk: Color(0xFFB05A4A),
    headlineInkDark: Color(0xFFF7E6E0),
    bodyInkDark: Color(0xFFD5B9B0),
    accentInkDark: Color(0xFFFFA38C),
    notebookLine: Color(0xFFF1D3C9),
    notebookMargin: Color(0xFFD88A8A),
    holeColor: Color(0xFFECDDCE),
    notebookLineDark: Color(0xFF574146),
    notebookMarginDark: Color(0xFF8F6266),
    holeColorDark: Color(0xFF21181A),
    tileDark: Color(0xFF362B2F),
  );

  static const ocean = _DiaryThemePalette(
    id: 'ocean',
    nameKo: '새벽 바다',
    nameEn: 'Early Sea',
    descriptionKo: '푸른 잉크처럼 또렷하고 서늘한 페이지입니다.',
    descriptionEn: 'A crisp and cool page like blue ink.',
    paper: Color(0xFFEFF5F7),
    paperBorder: Color(0xFFC9D9DE),
    paperDark: Color(0xFF1C2830),
    paperBorderDark: Color(0xFF445B66),
    headlineInk: Color(0xFF173D4A),
    bodyInk: Color(0xFF41606A),
    accentInk: Color(0xFF246C86),
    headlineInkDark: Color(0xFFE5F1F6),
    bodyInkDark: Color(0xFFBCD1D8),
    accentInkDark: Color(0xFF76C9E6),
    notebookLine: Color(0xFFC7DCE6),
    notebookMargin: Color(0xFF98B7C4),
    holeColor: Color(0xFFDCE7EA),
    notebookLineDark: Color(0xFF31434C),
    notebookMarginDark: Color(0xFF4E6672),
    holeColorDark: Color(0xFF131A1F),
    tileDark: Color(0xFF24333C),
  );

  static const values = <_DiaryThemePalette>[notebook, dusk, ocean];

  static _DiaryThemePalette fromId(String id) {
    return values.firstWhere((value) => value.id == id, orElse: () => notebook);
  }
}

class _DiaryDayData {
  final DateTime date;
  final List<TrainingEntry> entries;
  final List<_DiaryPlan> plans;
  final List<TrainingBoard> boards;

  const _DiaryDayData({
    required this.date,
    required this.entries,
    required this.plans,
    required this.boards,
  });

  List<TrainingEntry> get trainingEntries =>
      entries.where((entry) => !entry.isMatch).toList(growable: false);

  List<TrainingEntry> get matchEntries =>
      entries.where((entry) => entry.isMatch).toList(growable: false);

  List<_DiaryFortune> fortunes(bool isKo) => trainingEntries
      .map((entry) => _DiaryFortune.fromEntry(entry, isKo))
      .toList(growable: false);
}

class _DiaryFortune {
  final DateTime entryDate;
  final List<String> bodyLines;
  final List<String> luckyInfoLines;
  final String recommendation;

  const _DiaryFortune({
    required this.entryDate,
    required this.bodyLines,
    required this.luckyInfoLines,
    required this.recommendation,
  });

  factory _DiaryFortune.fromEntry(TrainingEntry entry, bool isKo) {
    final allLines = entry.fortuneComment
        .split('\n')
        .map((line) => line.trim())
        .where((line) => line.isNotEmpty)
        .toList(growable: false);
    final luckyInfoLines =
        allLines.where(_isLuckyInfoLine).toList(growable: false);
    final bodyLines = allLines
        .where((line) => !_isLuckyInfoLine(line))
        .toList(growable: false);
    final generated = _GeneratedDiaryFortuneText.fromEntry(entry, isKo);
    return _DiaryFortune(
      entryDate: entry.date,
      bodyLines: [...bodyLines, ...generated.bodyLines],
      luckyInfoLines: [...luckyInfoLines, ...generated.luckyInfoLines],
      recommendation: entry.fortuneRecommendation.trim().isNotEmpty
          ? entry.fortuneRecommendation
          : generated.recommendation,
    );
  }

  static bool _isLuckyInfoLine(String line) {
    return line.startsWith('행운 ') || line.startsWith('Lucky ');
  }
}

class _GeneratedDiaryFortuneText {
  final List<String> bodyLines;
  final List<String> luckyInfoLines;
  final String recommendation;

  const _GeneratedDiaryFortuneText({
    required this.bodyLines,
    required this.luckyInfoLines,
    required this.recommendation,
  });

  factory _GeneratedDiaryFortuneText.fromEntry(TrainingEntry entry, bool isKo) {
    final seed = Object.hash(
      entry.date.year,
      entry.date.month,
      entry.date.day,
      entry.date.hour,
      entry.durationMinutes,
      entry.intensity,
      entry.mood,
      entry.jumpRopeCount,
      entry.jumpRopeMinutes,
      entry.liftingByPart.values.fold<int>(0, (sum, value) => sum + value),
      entry.type,
      entry.program,
    );
    final durationBand = _durationBand(entry.durationMinutes, isKo);
    final intensityBand = _effortBand(entry.intensity, isKo);
    final conditionBand = _conditionBand(entry.mood, isKo);
    final liftingTotal = entry.liftingByPart.values.fold<int>(
      0,
      (sum, value) => sum + value,
    );
    final jumpMetric = entry.jumpRopeCount > 0
        ? (isKo ? '${entry.jumpRopeCount}회' : '${entry.jumpRopeCount} reps')
        : (entry.jumpRopeMinutes > 0
            ? (isKo
                ? '${entry.jumpRopeMinutes}분'
                : '${entry.jumpRopeMinutes} min')
            : (isKo ? '기록 준비' : 'prep'));
    final focus = entry.type.trim().isNotEmpty
        ? entry.type.trim()
        : (isKo ? '훈련' : 'training');
    final liftingState = liftingTotal > 0
        ? (isKo ? '리프팅 $liftingTotal회' : 'lifting $liftingTotal reps')
        : (isKo ? '리프팅 리듬 점검' : 'lifting rhythm check');
    final jumpState = (entry.jumpRopeCount > 0 || entry.jumpRopeMinutes > 0)
        ? (isKo ? '줄넘기 $jumpMetric' : 'jump rope $jumpMetric')
        : (isKo ? '줄넘기 감각 깨우기' : 'jump rope activation');
    final combinedTone = _pick(_combinedToneTemplates(isKo), seed);
    final tempo = _pick(_tempoTemplates(durationBand, isKo), seed ~/ 3);
    final condition = _pick(
      _conditionTemplates(conditionBand, isKo),
      seed ~/ 5,
    );
    final effort = _pick(_effortTemplates(intensityBand, isKo), seed ~/ 7);
    final recovery = _pick(
      _recoveryTemplates(
        isKo: isKo,
        hasLifting: liftingTotal > 0,
        hasJumpRope: entry.jumpRopeCount > 0 || entry.jumpRopeMinutes > 0,
      ),
      seed ~/ 11,
    );
    final lucky = _pick(
      _luckyTemplates(focus, liftingState, jumpState, isKo),
      seed ~/ 13,
    );
    final recommendation = _pick(
      _recommendationTemplates(
        isKo: isKo,
        focus: focus,
        durationMinutes: entry.durationMinutes,
        intensity: entry.intensity,
        mood: entry.mood,
        liftingState: liftingState,
        jumpState: jumpState,
      ),
      seed ~/ 17,
    );
    return _GeneratedDiaryFortuneText(
      bodyLines: <String>[
        combinedTone
            .replaceAll('{focus}', focus)
            .replaceAll('{duration}', '${entry.durationMinutes}분')
            .replaceAll('{condition}', conditionBand)
            .replaceAll('{intensity}', intensityBand),
        tempo
            .replaceAll('{focus}', focus)
            .replaceAll('{duration}', '${entry.durationMinutes}분'),
        condition.replaceAll('{condition}', conditionBand),
        effort.replaceAll('{intensity}', intensityBand),
        recovery
            .replaceAll('{lifting}', liftingState)
            .replaceAll('{jump}', jumpState),
      ],
      luckyInfoLines: <String>[lucky],
      recommendation: recommendation,
    );
  }

  static String _durationBand(int minutes, bool isKo) {
    if (minutes >= 90) return isKo ? '긴 호흡' : 'long push';
    if (minutes >= 60) return isKo ? '안정된 흐름' : 'steady flow';
    if (minutes >= 35) return isKo ? '집중 세션' : 'focused session';
    return isKo ? '짧고 선명한 리듬' : 'sharp rhythm';
  }

  static String _effortBand(int intensity, bool isKo) {
    if (intensity >= 5) return isKo ? '강한 압박' : 'heavy pressure';
    if (intensity >= 4) return isKo ? '높은 강도' : 'high intensity';
    if (intensity >= 3) return isKo ? '균형 잡힌 강도' : 'balanced intensity';
    if (intensity >= 2) return isKo ? '가볍게 조율한 강도' : 'light tuning';
    return isKo ? '회복 중심 강도' : 'recovery pace';
  }

  static String _conditionBand(int mood, bool isKo) {
    if (mood >= 5) return isKo ? '컨디션 최상' : 'top condition';
    if (mood >= 4) return isKo ? '컨디션 좋음' : 'good condition';
    if (mood >= 3) return isKo ? '컨디션 보통' : 'steady condition';
    if (mood >= 2) return isKo ? '컨디션 주의' : 'watch condition';
    return isKo ? '컨디션 회복 필요' : 'recovery-needed condition';
  }

  static String _pick(List<String> values, int seed) {
    return values[seed.abs() % values.length];
  }

  static List<String> _combinedToneTemplates(bool isKo) => isKo
      ? <String>[
          '{focus}에 들어간 오늘의 흐름은 {duration} 동안 {condition}과 {intensity}가 맞물리며 시작됐어요.',
          '{duration}의 훈련에서 {focus} 감각은 {condition} 위에 {intensity}를 얹는 방식으로 살아났어요.',
          '오늘 {focus} 기록은 {condition} 상태에서 {intensity}를 견디며 쌓인 {duration}의 장면이에요.',
          '{condition}을 바탕으로 {focus}를 붙들고, {intensity}로 밀어붙인 {duration}의 하루였어요.',
          '{focus} 노트에는 {duration} 동안 {condition}과 {intensity}가 어떻게 섞였는지가 또렷하게 남았어요.',
          '{duration} 동안 이어진 {focus} 세션은 {condition}과 {intensity}의 균형을 시험한 페이지였어요.',
          '{focus}을(를) 중심에 둔 오늘은 {condition} 속에서도 {intensity}를 유지하며 리듬을 만들었어요.',
          '{condition}의 시작점을 {intensity}로 끌어올린 덕분에 {focus} 연습이 {duration} 동안 끊기지 않았어요.',
          '{focus} 장면은 {duration}이라는 시간 안에서 {condition}과 {intensity}를 동시에 다루는 연습이었어요.',
          '오늘의 {focus}는 {condition}을 읽으면서도 {intensity}를 놓치지 않은 {duration}의 메모예요.',
          '{duration} 훈련 내내 {focus}은(는) {condition}을 다독이며 {intensity}를 채워 넣는 방향으로 흘렀어요.',
          '{focus}을(를) 다시 붙잡은 오늘은 {condition} 위에서 {intensity}를 버텨 낸 {duration}의 기록이에요.',
        ]
      : <String>[
          'Today\'s {focus} session opened with {condition} and {intensity} moving together for {duration}.',
          'Across {duration}, {focus} came alive by balancing {condition} with {intensity}.',
          'This {focus} log held {duration} of work built through {condition} and {intensity}.',
          'The day kept {focus} in front while leaning on {condition} and pushing through {intensity}.',
          'The {focus} note clearly shows how {condition} and {intensity} mixed over {duration}.',
          'This {duration} session tested the balance between {condition}, {intensity}, and {focus}.',
          'With {focus} at the center, the session kept its rhythm through {condition} and {intensity}.',
          'Raising the day from {condition} into {intensity} helped {focus} stay connected for {duration}.',
          '{focus} became a practice in handling {condition} and {intensity} at the same time across {duration}.',
          'Today\'s {focus} note kept reading {condition} without letting go of {intensity} over {duration}.',
          'For {duration}, {focus} moved by steadying {condition} and filling in {intensity}.',
          'Returning to {focus} turned the day into {duration} of holding {condition} under {intensity}.',
        ];

  static List<String> _tempoTemplates(String durationBand, bool isKo) => isKo
      ? <String>[
          '$durationBand 페이스라서 {focus}의 반복이 조급하지 않게 쌓였어요.',
          '$durationBand 덕분에 {focus} 타이밍을 한 번 더 확인할 여유가 생겼어요.',
          '$durationBand 흐름이 이어져서 {focus}에서 흔들린 장면도 금방 다시 정리됐어요.',
          '$durationBand 세션이라 {focus}의 결을 끝까지 잃지 않고 가져갔어요.',
          '$durationBand 무게감이 있어서 {focus} 디테일을 더 오래 붙들 수 있었어요.',
          '$durationBand 리듬이 잡히면서 {focus} 장면이 하루의 중심으로 남았어요.',
        ]
      : <String>[
          'That $durationBand pace let the repetitions in {focus} build without rushing.',
          'The $durationBand session left enough room to check the timing of {focus} one more time.',
          'Because the $durationBand flow held, shaky moments in {focus} settled quickly again.',
          'The $durationBand session helped keep the texture of {focus} to the end.',
          'That $durationBand weight made it easier to stay with the details of {focus}.',
          'Once the $durationBand rhythm settled, {focus} stayed at the center of the day.',
        ];

  static List<String> _conditionTemplates(String conditionBand, bool isKo) =>
      isKo
          ? <String>[
              '$conditionBand 신호가 보여서 몸의 반응을 읽으며 움직이기 좋았어요.',
              '$conditionBand 단계여서 판단과 터치의 간격을 차분히 맞출 수 있었어요.',
              '$conditionBand 기준으로 보아도 오늘은 감각을 잃지 않고 이어 간 편이에요.',
              '$conditionBand 상태라서 작은 흔들림도 빨리 알아차릴 수 있었어요.',
              '$conditionBand 흐름을 유지한 덕분에 기록 전체가 무너지지 않았어요.',
              '$conditionBand 날에는 무리보다 정리가 중요했는데, 오늘 메모가 그 균형을 보여줘요.',
            ]
          : <String>[
              'With $conditionBand signals, it was easier to read the body and move with it.',
              'At $conditionBand, the spacing between decisions and touches stayed calm.',
              'Even by a $conditionBand standard, the day held onto its feel without falling apart.',
              'Being in $conditionBand made it easier to notice small slips early.',
              'Keeping a $conditionBand flow helped the full log stay intact.',
              'On a $conditionBand day, clean organization mattered more than forcing it, and the note shows that balance.',
            ];

  static List<String> _effortTemplates(String intensityBand, bool isKo) => isKo
      ? <String>[
          '$intensityBand 구간을 지나면서도 발끝 감각은 끝까지 남아 있었어요.',
          '$intensityBand 템포가 걸려도 기록은 흐트러지지 않고 이어졌어요.',
          '$intensityBand 장면이 있었기에 오늘의 훈련이 더 또렷하게 남아요.',
          '$intensityBand 선택이 들어간 덕분에 세션의 밀도가 확실히 올라갔어요.',
          '$intensityBand 부담 속에서도 오늘은 중심을 다시 찾아오는 속도가 좋았어요.',
          '$intensityBand 하루였지만 메모는 급해지지 않고 차분하게 남았어요.',
        ]
      : <String>[
          'Even through that $intensityBand stretch, the touch at the feet stayed alive.',
          'The log stayed organized even when the pace moved into $intensityBand.',
          'That $intensityBand segment is part of what makes the session stand out.',
          'Choosing $intensityBand clearly raised the density of the session.',
          'Even under $intensityBand stress, the day returned to center quickly.',
          'It was a $intensityBand day, but the note never turned frantic.',
        ];

  static List<String> _recoveryTemplates({
    required bool isKo,
    required bool hasLifting,
    required bool hasJumpRope,
  }) {
    if (hasLifting && hasJumpRope) {
      return isKo
          ? <String>[
              '{lifting}와 {jump}가 함께 붙어서 몸의 준비도가 더 고르게 올라갔어요.',
              '{lifting}, {jump}까지 챙긴 덕분에 오늘 기록은 기본기와 체력이 같이 움직였어요.',
              '{jump} 뒤에 {lifting}까지 이어진 흐름이 하루의 완성도를 높였어요.',
              '{lifting}과 {jump}를 모두 남겨 둔 날은 훈련의 뒷받침이 더 단단해 보여요.',
              '{jump}와 {lifting}가 받쳐 줘서 메인 훈련의 리듬이 쉽게 끊기지 않았어요.',
            ]
          : <String>[
              '{lifting} and {jump} together raised the body into the session more evenly.',
              'Because both {lifting} and {jump} were checked, the day balanced fundamentals with conditioning.',
              'The flow from {jump} into {lifting} gave the day a more complete shape.',
              'Logging both {lifting} and {jump} makes the support work behind the session feel stronger.',
              '{jump} and {lifting} helped keep the main training rhythm from breaking apart.',
            ];
    }
    if (hasLifting) {
      return isKo
          ? <String>[
              '{lifting}을 챙긴 덕분에 볼 감각이 더 오래 유지될 바탕이 생겼어요.',
              '{lifting} 기록이 들어가 있어 오늘은 발 감각을 세밀하게 다듬은 날로 읽혀요.',
              '{lifting}이 메인 세션 뒤를 받쳐 줘서 기록의 밀도가 더 좋아졌어요.',
              '{lifting}이 남아 있어 반복의 성실함이 숫자로도 보이는 하루예요.',
              '{lifting} 덕분에 오늘 메모가 기술 훈련에서 끝나지 않고 기초 체력까지 닿았어요.',
            ]
          : <String>[
              '{lifting} gave the ball feel a stronger base to last longer.',
              'Because {lifting} was logged, the day reads like one that refined foot feel in detail.',
              '{lifting} supported the main session and improved the density of the whole record.',
              'With {lifting} left in the log, the honesty of repetition is visible in numbers too.',
              '{lifting} kept the day from ending at technique alone and extended it into base conditioning.',
            ];
    }
    if (hasJumpRope) {
      return isKo
          ? <String>[
              '{jump}가 먼저 리듬을 만들어 줘서 오늘의 첫 터치가 더 가벼웠을 거예요.',
              '{jump} 기록이 있어 몸의 박자를 미리 올려 둔 하루로 읽혀요.',
              '{jump}를 함께 남긴 덕분에 훈련 전환이 더 부드러웠을 가능성이 커요.',
              '{jump}가 있어서 발놀림 준비가 오늘 기록 안에 자연스럽게 이어져요.',
              '{jump} 하나만으로도 몸의 시동을 어떻게 걸었는지 충분히 보였어요.',
            ]
          : <String>[
              '{jump} likely set the rhythm early and made the first touch lighter.',
              'With {jump} logged, the day reads like one that raised the body rhythm in advance.',
              'Keeping {jump} in the record probably made the shift into training smoother.',
              '{jump} naturally extends the story of how the feet were prepared.',
              '{jump} alone already shows a lot about how the body was started for the day.',
            ];
    }
    return isKo
        ? <String>[
            '{lifting}과 {jump}를 다음 기록에 더하면 오늘의 리듬이 더 선명해질 거예요.',
            '오늘은 메인 훈련이 중심이었고, 다음엔 {lifting}이나 {jump}를 곁들여도 좋아 보여요.',
            '{lifting} 또는 {jump}를 보태면 오늘 쌓은 감각이 더 오래 남을 수 있어요.',
            '이번 기록은 메인 세션 위주였으니 다음에는 {jump}나 {lifting}도 함께 남겨 보세요.',
            '다음 페이지에서는 {lifting}, {jump} 같은 준비 루틴까지 연결하면 더 탄탄해질 거예요.',
          ]
        : <String>[
            'Adding {lifting} and {jump} next time could make the day\'s rhythm feel even clearer.',
            'The main session led today, and next time {lifting} or {jump} could support it well.',
            'Adding either {lifting} or {jump} may help today\'s feel stay longer.',
            'This record focused on the main session, so next time try logging {jump} or {lifting} too.',
            'The next page may feel sturdier if it also connects warm-up work like {lifting} and {jump}.',
          ];
  }

  static List<String> _luckyTemplates(
    String focus,
    String liftingState,
    String jumpState,
    bool isKo,
  ) =>
      isKo
          ? <String>[
              '행운 루틴: $focus 전에 $jumpState로 발 리듬을 먼저 깨워 보세요.',
              '행운 포인트: $liftingState처럼 반복 횟수가 보이는 루틴이 오늘 감각을 오래 붙잡아 줘요.',
              '행운 타이밍: $focus 시작 전 5분은 호흡을 고르고 박자를 맞추는 시간이 좋아요.',
              '행운 키워드: 첫 터치, 시선 정리, 그리고 $jumpState.',
              '행운 메모: $focus 장면은 짧은 준비 루틴과 함께할 때 더 선명해져요.',
              '행운 연결: $liftingState 뒤에 메인 훈련을 이어가면 감각이 더 또렷해질 수 있어요.',
            ]
          : <String>[
              'Lucky routine: wake the feet up with $jumpState before $focus.',
              'Lucky point: routines with visible counts like $liftingState help the feel last longer today.',
              'Lucky timing: the five minutes before $focus are good for settling breath and rhythm.',
              'Lucky keywords: first touch, scanning, and $jumpState.',
              'Lucky note: $focus becomes clearer when it starts with a short prep routine.',
              'Lucky link: the feel may sharpen if the main session follows $liftingState.',
            ];

  static List<String> _recommendationTemplates({
    required bool isKo,
    required String focus,
    required int durationMinutes,
    required int intensity,
    required int mood,
    required String liftingState,
    required String jumpState,
  }) {
    final durationText = durationMinutes >= 60
        ? (isKo ? '후반 10분' : 'the final 10 minutes')
        : (isKo ? '마지막 5분' : 'the last 5 minutes');
    final intensityText = intensity >= 4
        ? (isKo ? '강하게 밀어붙인 구간' : 'after the hard push')
        : (isKo ? '리듬을 고른 구간' : 'after the rhythm section');
    final conditionText = mood >= 4
        ? (isKo ? '좋은 컨디션을 유지한 흐름' : 'the good-condition flow')
        : (isKo ? '컨디션을 끌어올리는 과정' : 'the build back into condition');
    return isKo
        ? <String>[
            '$durationText에는 $focus 한 가지만 남겨서 반복해 보세요.',
            '$intensityText 뒤에 $jumpState를 짧게 붙이면 리듬 정리에 도움이 돼요.',
            '$conditionText을 다시 만들기 위해 $liftingState를 다음 기록에도 이어가 보세요.',
            '$focus 전에 시야 확인 한 번, 터치 방향 한 번을 같은 루틴으로 고정해 보세요.',
            '오늘 메모를 기준으로 내일은 $focus 첫 성공 장면을 더 빨리 만드는 데 집중해 보세요.',
            '$focus 훈련 뒤에 짧은 정리 메모를 남기면 좋은 감각을 더 오래 복기할 수 있어요.',
            '$jumpState 또는 $liftingState 중 하나만 꾸준히 이어도 하루 컨디션 변화가 더 잘 보여요.',
            '$focus 장면에서 가장 좋았던 한 번을 기준 동작으로 삼아 다시 반복해 보세요.',
          ]
        : <String>[
            'Use $durationText to repeat only one clear version of $focus.',
            '$intensityText, adding a short block of $jumpState could help reset the rhythm.',
            'To rebuild $conditionText, try carrying $liftingState into the next log as well.',
            'Before $focus, keep one scan cue and one touch-direction cue fixed as the same routine.',
            'Based on today\'s note, focus tomorrow on reaching the first successful $focus moment earlier.',
            'A short closing note after $focus can help replay the good feel for longer.',
            'Even staying consistent with either $jumpState or $liftingState will reveal condition changes more clearly.',
            'Use the best single $focus rep from today as the reference movement for the next round.',
          ];
  }
}

class _DiaryPlan {
  final String id;
  final DateTime scheduledAt;
  final String category;
  final int durationMinutes;
  final String note;

  const _DiaryPlan({
    required this.id,
    required this.scheduledAt,
    required this.category,
    required this.durationMinutes,
    required this.note,
  });

  factory _DiaryPlan.fromMap(Map<String, dynamic> map) {
    return _DiaryPlan(
      id: map['id']?.toString() ??
          DateTime.now().microsecondsSinceEpoch.toString(),
      scheduledAt: DateTime.tryParse(map['scheduledAt']?.toString() ?? '') ??
          DateTime.now(),
      category: map['category']?.toString() ?? '',
      durationMinutes: (map['durationMinutes'] as num?)?.toInt() ?? 60,
      note: map['note']?.toString() ?? '',
    );
  }
}
