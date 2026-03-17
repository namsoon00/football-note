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

  bool get _isKo => Localizations.localeOf(context).languageCode == 'ko';
  ThemeData get _theme => Theme.of(context);
  ColorScheme get _scheme => _theme.colorScheme;
  bool get _isDark => _theme.brightness == Brightness.dark;
  AppLocalizations get _l10n => AppLocalizations.of(context)!;
  _DiaryThemePalette get _palette => _DiaryThemePalette.fromId(_selectedThemeId);
  Color get _paperSurface => _isDark
      ? Color.lerp(_palette.paper, _scheme.surface, 0.45)!
      : _palette.paper;
  Color get _paperEdge => _isDark
      ? Color.lerp(_palette.paperBorder, _scheme.outline, 0.55)!
      : _palette.paperBorder;
  Color get _headlineInk => _isDark
      ? Color.lerp(_palette.headlineInk, _scheme.onSurface, 0.6)!
      : _palette.headlineInk;
  Color get _bodyInk => _isDark
      ? Color.lerp(_palette.bodyInk, _scheme.onSurfaceVariant, 0.55)!
      : _palette.bodyInk;
  Color get _accentInk => _isDark
      ? Color.lerp(_palette.accentInk, _scheme.primary, 0.5)!
      : _palette.accentInk;
  Color get _accentWash => _accentInk.withValues(alpha: _isDark ? 0.16 : 0.1);
  Color get _tileSurface => _isDark
      ? _scheme.surfaceContainerHighest.withValues(alpha: 0.52)
      : Colors.white.withValues(alpha: 0.58);
  Color get _notebookLine => _isDark
      ? Color.lerp(_palette.notebookLine, _scheme.outlineVariant, 0.5)!
      : _palette.notebookLine;
  Color get _notebookMargin => _isDark
      ? Color.lerp(_palette.notebookMargin, _scheme.error, 0.4)!
      : _palette.notebookMargin;
  Color get _holeColor => _isDark
      ? Color.lerp(_palette.holeColor, _scheme.surface, 0.5)!
      : _palette.holeColor;

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
                    onNewsTap:
                        widget.trainingService != null &&
                            widget.localeService != null &&
                            widget.settingsService != null
                        ? _openNews
                        : null,
                    onGameTap:
                        widget.trainingService != null &&
                            widget.localeService != null &&
                            widget.settingsService != null
                        ? _openGame
                        : null,
                    onProfileTap: _openProfile,
                    onSettingsTap:
                        widget.localeService != null &&
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
        builder: (_) => ProfileScreen(optionRepository: widget.optionRepository),
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
              _buildTrainingCard(day.trainingEntries),
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
    return Container(
      decoration: _paperDecoration(),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(18, 18, 18, 18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _formatDiaryDate(day.date),
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: _headlineInk,
                    fontWeight: FontWeight.w900,
                  ),
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
    final fortunes = day.savedFortunes;
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
    final sourceLabel = fortune.program.trim().isEmpty
        ? _formatTime(fortune.entryDate)
        : '${_formatTime(fortune.entryDate)} · ${fortune.program.trim()}';
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
      child: Column(
        children: entries
            .map(
              (entry) => _buildTimelineTile(
                title: '${_formatTime(entry.date)} · ${entry.type}',
                detail: _trainingSummary(entry),
              ),
            )
            .toList(growable: false),
      ),
    );
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
          ? '${_formatDiaryDate(day.date)}의 기억은 ${_topPlaces(day.entries)}에서 천천히 몸을 풀던 장면으로 시작된다. 오늘의 중심에는 ${_topFocus(day.trainingEntries)}이(가) 놓여 있었고, 기록을 따라가다 보면 마음이 머문 곳도 자연스럽게 드러난다.'
          : 'The memory of ${_formatDiaryDate(day.date)} begins where the body first settled into motion at ${_topPlaces(day.entries)}. ${_topFocus(day.trainingEntries)} stayed at the center of the day, and the notes quietly reveal where the mind lingered too.',
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
            ? '하루를 붙들어 주던 계획은 $planLines 순서였다. 미리 적어 둔 문장들 덕분에 오늘은 허둥대기보다 천천히 방향을 확인하며 걸어갈 수 있었다.'
            : 'The day was held together by a plan in this order: $planLines. Those lines written in advance kept the day from scattering and gave it a direction to return to.',
      );
    }

    if (day.trainingEntries.isNotEmpty) {
      final totalMinutes = day.trainingEntries.fold<int>(
        0,
        (sum, entry) => sum + entry.durationMinutes,
      );
      paragraphs.add(
        _isKo
            ? '훈련은 ${day.trainingEntries.length}번, 모두 $totalMinutes분이었다. ${day.trainingEntries.map(_trainingDiarySentence).join(' ')}'
            : 'Training appeared ${day.trainingEntries.length} times for a total of $totalMinutes minutes. ${day.trainingEntries.map(_trainingDiarySentence).join(' ')}',
      );
    }

    if (day.matchEntries.isNotEmpty) {
      paragraphs.add(
        _isKo
            ? '경기 장면으로 넘어가면 ${day.matchEntries.map(_matchDiarySentence).join(' ')}'
            : 'When the day moves into match scenes, ${day.matchEntries.map(_matchDiarySentence).join(' ')}',
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
          ? '결국 오늘의 다이어리는 잘한 장면만 남기지 않는다. 흔들린 순간과 버티어 낸 순간을 함께 묶어 두면서, 내일의 목표가 왜 필요한지도 조용히 설명해 준다.'
          : 'In the end, this diary does not keep only the clean moments. It holds the shaky ones beside the steady ones, and quietly explains why tomorrow still needs a goal.',
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
    final details = <String>[
      if (entry.program.trim().isNotEmpty) entry.program.trim(),
      if (!TrainingBoardLinkCodec.isBoardLinkPayload(entry.drills) &&
          entry.drills.trim().isNotEmpty)
        entry.drills.trim(),
      if (entry.goodPoints.trim().isNotEmpty) entry.goodPoints.trim(),
      if (entry.improvements.trim().isNotEmpty) entry.improvements.trim(),
      if (entry.nextGoal.trim().isNotEmpty) entry.nextGoal.trim(),
      if (entry.notes.trim().isNotEmpty) entry.notes.trim(),
    ];
    final detailText = details.isEmpty
        ? (_isKo ? '세부 메모 없음' : 'No detailed note')
        : details.join(' · ');
    return _isKo
        ? '${entry.type} ${entry.durationMinutes}분, ${entry.location.trim().isEmpty ? '장소 기록 없음' : entry.location.trim()}, $detailText'
        : '${entry.type} for ${entry.durationMinutes} min at ${entry.location.trim().isEmpty ? 'no location logged' : entry.location.trim()}, $detailText';
  }

  String _trainingDiarySentence(TrainingEntry entry) {
    final noteParts = <String>[
      if (entry.goodPoints.trim().isNotEmpty)
        _isKo
            ? '잘된 장면은 ${entry.goodPoints.trim()}'
            : 'the part that held up was ${entry.goodPoints.trim()}',
      if (entry.improvements.trim().isNotEmpty)
        _isKo
            ? '아직 손봐야 할 부분은 ${entry.improvements.trim()}'
            : 'what still asks for attention is ${entry.improvements.trim()}',
      if (entry.nextGoal.trim().isNotEmpty)
        _isKo
            ? '다음으로 데려가고 싶은 목표는 ${entry.nextGoal.trim()}'
            : 'the next goal worth carrying forward is ${entry.nextGoal.trim()}',
      if (entry.notes.trim().isNotEmpty)
        _isKo
            ? '메모에는 ${entry.notes.trim()}'
            : 'the note admitted ${entry.notes.trim()}',
    ];
    final suffix = noteParts.isEmpty ? '' : ' ${noteParts.join('. ')}.';
    return _isKo
        ? '${_formatTime(entry.date)}에는 ${entry.location.trim().isEmpty ? '장소 기록 없이' : entry.location.trim()}에서 ${entry.type} ${entry.durationMinutes}분을 보냈다. 몸이 기억한 리듬은 그렇게 한 줄씩 쌓였다.$suffix'
        : 'At ${_formatTime(entry.date)}, ${entry.type} stayed with the body for ${entry.durationMinutes} minutes ${entry.location.trim().isEmpty ? 'without a logged place' : 'at ${entry.location.trim()}'}.$suffix';
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
  final Color headlineInk;
  final Color bodyInk;
  final Color accentInk;
  final Color notebookLine;
  final Color notebookMargin;
  final Color holeColor;

  const _DiaryThemePalette({
    required this.id,
    required this.nameKo,
    required this.nameEn,
    required this.descriptionKo,
    required this.descriptionEn,
    required this.paper,
    required this.paperBorder,
    required this.headlineInk,
    required this.bodyInk,
    required this.accentInk,
    required this.notebookLine,
    required this.notebookMargin,
    required this.holeColor,
  });

  static const notebook = _DiaryThemePalette(
    id: 'notebook',
    nameKo: '노트북',
    nameEn: 'Notebook',
    descriptionKo: '차분한 종이 질감의 기본 다이어리입니다.',
    descriptionEn: 'A calm paper-textured default diary.',
    paper: Color(0xFFF7F1E7),
    paperBorder: Color(0xFFD8CBB5),
    headlineInk: Color(0xFF123B2D),
    bodyInk: Color(0xFF6E5A49),
    accentInk: Color(0xFF0F5A43),
    notebookLine: Color(0xFFC8DBF5),
    notebookMargin: Color(0xFFE6A6A6),
    holeColor: Color(0xFFE6DDCF),
  );

  static const dusk = _DiaryThemePalette(
    id: 'dusk',
    nameKo: '노을',
    nameEn: 'Dusk',
    descriptionKo: '붉은 저녁빛처럼 따뜻한 분위기로 읽습니다.',
    descriptionEn: 'Reads in the warmth of a red evening glow.',
    paper: Color(0xFFF9EEE8),
    paperBorder: Color(0xFFE2C8BE),
    headlineInk: Color(0xFF5A2E27),
    bodyInk: Color(0xFF7A544C),
    accentInk: Color(0xFFB05A4A),
    notebookLine: Color(0xFFF1D3C9),
    notebookMargin: Color(0xFFD88A8A),
    holeColor: Color(0xFFECDDCE),
  );

  static const ocean = _DiaryThemePalette(
    id: 'ocean',
    nameKo: '새벽 바다',
    nameEn: 'Early Sea',
    descriptionKo: '푸른 잉크처럼 또렷하고 서늘한 페이지입니다.',
    descriptionEn: 'A crisp and cool page like blue ink.',
    paper: Color(0xFFEFF5F7),
    paperBorder: Color(0xFFC9D9DE),
    headlineInk: Color(0xFF173D4A),
    bodyInk: Color(0xFF41606A),
    accentInk: Color(0xFF246C86),
    notebookLine: Color(0xFFC7DCE6),
    notebookMargin: Color(0xFF98B7C4),
    holeColor: Color(0xFFDCE7EA),
  );

  static const values = <_DiaryThemePalette>[notebook, dusk, ocean];

  static _DiaryThemePalette fromId(String id) {
    return values.firstWhere(
      (value) => value.id == id,
      orElse: () => notebook,
    );
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

  List<_DiaryFortune> get savedFortunes => trainingEntries
      .where((entry) => entry.fortuneComment.trim().isNotEmpty)
      .map(_DiaryFortune.fromEntry)
      .toList(growable: false);
}

class _DiaryFortune {
  final DateTime entryDate;
  final String program;
  final List<String> bodyLines;
  final List<String> luckyInfoLines;
  final String recommendation;

  const _DiaryFortune({
    required this.entryDate,
    required this.program,
    required this.bodyLines,
    required this.luckyInfoLines,
    required this.recommendation,
  });

  factory _DiaryFortune.fromEntry(TrainingEntry entry) {
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
    return _DiaryFortune(
      entryDate: entry.date,
      program: entry.program,
      bodyLines: bodyLines,
      luckyInfoLines: luckyInfoLines,
      recommendation: entry.fortuneRecommendation,
    );
  }

  static bool _isLuckyInfoLine(String line) {
    return line.startsWith('행운 ') || line.startsWith('Lucky ');
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
