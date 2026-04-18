import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:football_note/gen/app_localizations.dart';
import 'package:intl/intl.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:table_calendar/table_calendar.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../application/backup_service.dart';
import '../../application/family_access_service.dart';
import '../../application/locale_service.dart';
import '../../application/meal_log_service.dart';
import '../../application/news_badge_service.dart';
import '../../application/player_level_service.dart';
import '../../application/settings_service.dart';
import '../../application/training_board_service.dart';
import '../../application/training_plan_reminder_service.dart';
import '../../application/training_service.dart';
import '../../domain/entities/training_board.dart';
import '../../domain/entities/meal_entry.dart';
import '../../domain/entities/training_entry.dart';
import '../../domain/repositories/option_repository.dart';
import '../models/training_board_link_codec.dart';
import '../models/training_program_emoji.dart';
import '../models/training_status_emoji.dart';
import '../models/training_method_layout.dart';
import '../widgets/app_background.dart';
import '../widgets/app_drawer.dart';
import '../widgets/app_feedback.dart';
import '../widgets/rice_bowl_summary.dart';
import '../widgets/fortune_card.dart';
import '../widgets/shared_tab_header.dart';
import '../widgets/status_style.dart';
import '../widgets/training_board_sketch.dart';
import 'news_screen.dart';
import 'profile_screen.dart';
import 'settings_screen.dart';
import 'skill_quiz_screen.dart';
import 'notification_center_screen.dart';

class CoachLessonScreen extends StatefulWidget {
  static const String todayViewedDiaryDayKey = 'coach_diary_completed_day_v2';

  final OptionRepository optionRepository;
  final TrainingService? trainingService;
  final MealLogService? mealLogService;
  final LocaleService? localeService;
  final SettingsService? settingsService;
  final BackupService? driveBackupService;
  final bool embeddedInHomeTab;
  final int openTodayDiaryRequestKey;

  const CoachLessonScreen({
    super.key,
    required this.optionRepository,
    this.trainingService,
    this.mealLogService,
    this.localeService,
    this.settingsService,
    this.driveBackupService,
    this.embeddedInHomeTab = false,
    this.openTodayDiaryRequestKey = 0,
  });

  static String todayViewedDayToken(DateTime date) =>
      '${date.year.toString().padLeft(4, '0')}-'
      '${date.month.toString().padLeft(2, '0')}-'
      '${date.day.toString().padLeft(2, '0')}';

  @override
  State<CoachLessonScreen> createState() => _CoachLessonScreenState();
}

class _CoachLessonScreenState extends State<CoachLessonScreen> {
  static const String _plansStorageKey = 'training_plans_v1';
  static const String _diaryThemeKey = 'diary_theme_v1';
  static const String _customDiaryEntriesKey = 'custom_diary_entries_v3';

  final PageController _pageController = PageController();
  final Set<String> _expandedQuizStickerIds = <String>{};
  int _selectedDayIndex = 0;
  late String _selectedThemeId;
  String? _lastCompletedDiaryToken;
  late Map<String, _CustomDiaryEntryData> _customDiaryEntries;
  int _lastHandledOpenTodayDiaryRequestKey = 0;

  bool get _isKo => Localizations.localeOf(context).languageCode == 'ko';
  AppLocalizations get _l10n => AppLocalizations.of(context)!;
  ThemeData get _theme => Theme.of(context);
  bool get _isDark => _theme.brightness == Brightness.dark;
  _DiaryThemePalette get _palette =>
      _DiaryThemePalette.fromId(_selectedThemeId);
  Color get _paperSurface => _isDark ? _palette.paperDark : _palette.paper;
  Color get _paperEdge =>
      _isDark ? _palette.paperBorderDark : _palette.paperBorder;
  Color get _headlineInk =>
      _isDark ? _palette.headlineInkDark : _palette.headlineInk;
  Color get _bodyInk => _isDark ? _palette.bodyInkDark : _palette.bodyInk;
  Color get _accentInk => _isDark ? _palette.accentInkDark : _palette.accentInk;
  Color get _notebookLine =>
      _isDark ? _palette.notebookLineDark : _palette.notebookLine;
  Color get _notebookMargin =>
      _isDark ? _palette.notebookMarginDark : _palette.notebookMargin;
  Color get _notebookHole =>
      _isDark ? _palette.holeColorDark : _palette.holeColor;
  Color get _tileSurface =>
      _isDark ? _palette.tileDark : Colors.white.withValues(alpha: 0.58);

  @override
  void initState() {
    super.initState();
    _selectedThemeId =
        widget.optionRepository.getValue<String>(_diaryThemeKey) ??
            _DiaryThemePalette.notebook.id;
    _customDiaryEntries = _loadCustomDiaryEntries();
    NewsBadgeService.refresh(widget.optionRepository);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isParentMode = _isParentReadOnlyMode;
    final stream = widget.trainingService?.watchEntries() ??
        Stream<List<TrainingEntry>>.value(const <TrainingEntry>[]);
    final mealStream = widget.mealLogService?.watchEntries() ??
        Stream<List<MealEntry>>.value(const <MealEntry>[]);
    final showBack = !widget.embeddedInHomeTab;
    final canOpenDrawer = !showBack &&
        widget.trainingService != null &&
        widget.localeService != null &&
        widget.settingsService != null;
    final profilePhotoSource =
        widget.optionRepository.getValue<String>('profile_photo_url') ?? '';
    final reminderUnreadCount = widget.settingsService == null
        ? 0
        : TrainingPlanReminderService(
            widget.optionRepository,
            widget.settingsService!,
          ).unreadReminderCountSync();

    return Scaffold(
      drawer: canOpenDrawer
          ? AppDrawer(
              trainingService: widget.trainingService!,
              optionRepository: widget.optionRepository,
              localeService: widget.localeService!,
              settingsService: widget.settingsService!,
              driveBackupService: widget.driveBackupService,
              currentIndex: 4,
            )
          : null,
      body: _DiaryNotebookBackground(
        baseBackground: const AppBackground(child: SizedBox.expand()),
        paperColor: _paperSurface,
        lineColor: _notebookLine,
        marginColor: _notebookMargin,
        holeColor: _notebookHole,
        child: SafeArea(
          child: StreamBuilder<List<TrainingEntry>>(
            stream: stream,
            builder: (context, snapshot) {
              return StreamBuilder<List<MealEntry>>(
                stream: mealStream,
                builder: (context, mealSnapshot) {
                  final entries = [
                    ...(snapshot.data ?? const <TrainingEntry>[]),
                  ]..sort(TrainingEntry.compareByRecentCreated);
                  final entriesByDay = _groupEntriesByDay(entries);
                  final mealEntries = widget.mealLogService?.mergedEntries(
                        directEntries: mealSnapshot.data ?? const <MealEntry>[],
                        legacyEntries: entries,
                      ) ??
                      const <MealEntry>[];
                  final mealEntriesByDay = _groupMealEntriesByDay(mealEntries);
                  final plans = _loadPlans();
                  final plansByDay = _groupPlansByDay(plans);
                  final boardMap = TrainingBoardService(
                    widget.optionRepository,
                  ).boardMap();
                  final days = _buildDays(
                    entriesByDay: entriesByDay,
                    mealEntriesByDay: mealEntriesByDay,
                    plansByDay: plansByDay,
                    boardMap: boardMap,
                  );
                  _consumeTodayDiaryOpenRequest(
                    days: days,
                    entriesByDay: entriesByDay,
                    mealEntriesByDay: mealEntriesByDay,
                    plansByDay: plansByDay,
                    boardMap: boardMap,
                  );
                  if (days.isEmpty) {
                    return ListView(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                      children: [
                        _buildEmptyCard(
                          onCreateDiary: isParentMode
                              ? _showParentReadOnlyMessage
                              : () => _openNewDiaryComposer(
                                    entriesByDay: entriesByDay,
                                    mealEntriesByDay: mealEntriesByDay,
                                    plansByDay: plansByDay,
                                    boardMap: boardMap,
                                  ),
                        ),
                      ],
                    );
                  }

                  final selectedIndex = _selectedDayIndex.clamp(
                    0,
                    days.length - 1,
                  );
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
                      ValueListenableBuilder<int>(
                        valueListenable: NewsBadgeService.listenable(
                          widget.optionRepository,
                        ),
                        builder: (context, newsCount, _) => Builder(
                          builder: (headerContext) => SharedTabHeader(
                            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                            onLeadingTap: showBack
                                ? () => Navigator.of(context).maybePop()
                                : canOpenDrawer
                                    ? () =>
                                        Scaffold.of(headerContext).openDrawer()
                                    : null,
                            leadingIcon:
                                showBack ? Icons.arrow_back : Icons.menu,
                            leadingTooltip: _isKo
                                ? (showBack ? '뒤로가기' : '메뉴')
                                : (showBack ? 'Back' : 'Menu'),
                            onNewsTap: widget.trainingService != null &&
                                    widget.localeService != null &&
                                    widget.settingsService != null
                                ? _openNews
                                : null,
                            newsBadgeCount: newsCount,
                            onQuizTap: widget.trainingService != null &&
                                    widget.localeService != null &&
                                    widget.settingsService != null
                                ? _openQuiz
                                : null,
                            onProfileTap: _openProfile,
                            onNotificationTap: widget.settingsService != null
                                ? _openNotifications
                                : null,
                            notificationBadgeCount: reminderUnreadCount,
                            onSettingsTap: widget.localeService != null &&
                                    widget.settingsService != null
                                ? _openSettings
                                : _openProfile,
                            profilePhotoSource: profilePhotoSource,
                            title: _isKo ? '다이어리' : 'Diary',
                            titleTrailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                if (isParentMode)
                                  Padding(
                                    padding: const EdgeInsets.only(right: 8),
                                    child: Text(
                                      _l10n.parentReadOnlyDiaryBadge,
                                      style: Theme.of(context)
                                          .textTheme
                                          .labelLarge
                                          ?.copyWith(
                                            color: _accentInk,
                                            fontWeight: FontWeight.w800,
                                          ),
                                    ),
                                  ),
                                OutlinedButton.icon(
                                  onPressed: _showThemePicker,
                                  icon: const Icon(
                                    Icons.palette_outlined,
                                    size: 18,
                                  ),
                                  label: Text(_isKo ? '테마' : 'Theme'),
                                ),
                                const SizedBox(width: 8),
                                OutlinedButton.icon(
                                  onPressed: isParentMode
                                      ? _showParentReadOnlyMessage
                                      : () => _openNewDiaryComposer(
                                            entriesByDay: entriesByDay,
                                            mealEntriesByDay: mealEntriesByDay,
                                            plansByDay: plansByDay,
                                            boardMap: boardMap,
                                          ),
                                  icon: const Icon(
                                    Icons.add_circle_outline,
                                    size: 18,
                                  ),
                                  label: Text(_isKo ? '새 다이어리' : 'New diary'),
                                ),
                              ],
                            ),
                          ),
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
        padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
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
                    vertical: 4,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Flexible(
                        child: Text(
                          selectedLabel,
                          textAlign: TextAlign.center,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style:
                              Theme.of(context).textTheme.titleSmall?.copyWith(
                                    color: _headlineInk,
                                    fontWeight: FontWeight.w900,
                                  ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Icon(
                        Icons.calendar_month_outlined,
                        size: 16,
                        color: _accentInk,
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
    if (mounted) {
      await NewsBadgeService.refresh(widget.optionRepository);
    }
  }

  Future<void> _openQuiz() async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) =>
            SkillQuizScreen(optionRepository: widget.optionRepository),
      ),
    );
  }

  Future<void> _openNotifications() async {
    final settingsService = widget.settingsService;
    if (settingsService == null) return;
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => NotificationCenterScreen(
          optionRepository: widget.optionRepository,
          settingsService: settingsService,
        ),
      ),
    );
    if (mounted) setState(() {});
  }

  Future<void> _markDiaryCompletedIfNeeded(DateTime date) async {
    final token = CoachLessonScreen.todayViewedDayToken(date);
    if (_lastCompletedDiaryToken == token) return;
    _lastCompletedDiaryToken = token;
    await widget.optionRepository.setValue(
      CoachLessonScreen.todayViewedDiaryDayKey,
      token,
    );
    await _awardDiaryCreateXp(date);
  }

  Future<void> _awardDiaryCreateXp(DateTime date) async {
    final award = await PlayerLevelService(
      widget.optionRepository,
    ).awardForDiaryCreated(createdAt: date);
    final settingsService = widget.settingsService ??
        (SettingsService(widget.optionRepository)..load());
    await TrainingPlanReminderService(
      widget.optionRepository,
      settingsService,
    ).showXpGainAlert(
      gainedXp: award.gainedXp,
      totalXp: award.after.totalXp,
      isKo: _isKo,
      sourceLabel: _isKo ? '다이어리' : 'Diary',
    );
    if (!mounted || award.gainedXp <= 0) return;
    AppFeedback.showSuccess(
      context,
      text: _isKo
          ? '오늘 다이어리 작성 +${award.gainedXp} XP'
          : 'Today diary created +${award.gainedXp} XP',
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
    final customDiary = _customDiaryForDay(day.date);
    final diaryTitle = customDiary.title.trim().isNotEmpty
        ? customDiary.title.trim()
        : _l10n.diaryTitlePlaceholder;
    // Weather shown via sticker; omit older subtitle summary.
    return _DiaryScrollPage(
      onReachedEnd: () {},
      onPullDownToDismiss: widget.embeddedInHomeTab
          ? null
          : () => Navigator.of(context).maybePop(),
      childBuilder: (controller) => SingleChildScrollView(
        controller: controller,
        padding: const EdgeInsets.fromLTRB(40, 20, 16, 28),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildDiarySection(
              title: diaryTitle,
              // Weather appears via sticker; keep subtitle empty.
              subtitle: null,
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (customDiary.hasContent) ...[
                    _buildDiaryActionIconButton(
                      key: ValueKey(
                        'diary-delete-${_dayStorageToken(day.date)}',
                      ),
                      onPressed: () => _confirmDeleteDiary(day.date),
                      tooltip: _isKo ? '삭제' : 'Delete',
                      foregroundColor: Theme.of(context).colorScheme.error,
                      icon: const Icon(Icons.delete_outline, size: 20),
                    ),
                    const SizedBox(width: 4),
                  ],
                  _buildDiaryActionIconButton(
                    key: ValueKey('diary-edit-${_dayStorageToken(day.date)}'),
                    onPressed: () => _openDiaryComposer(day, customDiary),
                    tooltip: _isKo ? '작성' : 'Compose',
                    icon: Icon(
                      customDiary.hasContent
                          ? Icons.edit_note_outlined
                          : Icons.add_circle_outline,
                      size: 20,
                    ),
                  ),
                ],
              ),
              child: _buildCustomDiaryCard(day, customDiary),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDiaryActionIconButton({
    required Key key,
    required VoidCallback onPressed,
    required String tooltip,
    required Widget icon,
    Color? foregroundColor,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    final resolvedColor = foregroundColor ?? colorScheme.onSurfaceVariant;
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: resolvedColor.withValues(alpha: 0.28)),
      ),
      child: IconButton(
        key: key,
        onPressed: onPressed,
        tooltip: tooltip,
        color: resolvedColor,
        icon: icon,
      ),
    );
  }

  Widget _buildCustomDiaryCard(
    _DiaryDayData day,
    _CustomDiaryEntryData customDiary,
  ) {
    final todoSeeds = _todoSeedsForDay(day);
    final recordStickers = customDiary.recordStickers
        .map((sticker) => _resolveRecordSticker(sticker, day))
        .whereType<_DiaryRecordStickerViewData>()
        .toList(growable: false);
    return _buildPaperCard(
      title: null,
      subtitle: customDiary.updatedAt == null
          ? (_isKo ? '핵심만 간단히 기록해보세요.' : 'Keep it short and clear.')
          : (_isKo
              ? '마지막 저장 ${DateFormat('M.d HH:mm', 'ko').format(customDiary.updatedAt!)}'
              : 'Last saved ${DateFormat('MMM d HH:mm', 'en').format(customDiary.updatedAt!)}'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            customDiary.story.trim().isNotEmpty
                ? customDiary.story.trim()
                : (_isKo ? '본문을 입력해 주세요' : 'Please enter the body text'),
            key: ValueKey('diary-story-${_dayStorageToken(day.date)}'),
            style: _theme.textTheme.bodyLarge?.copyWith(
              color: customDiary.story.trim().isNotEmpty
                  ? _headlineInk
                  : _bodyInk.withValues(alpha: 0.78),
              height: 1.72,
            ),
          ),
          const SizedBox(height: 14),
          if (recordStickers.isNotEmpty) ...[
            ...recordStickers.map(_buildRecordStickerCard),
            const SizedBox(height: 6),
          ],
          const SizedBox(height: 14),
          if (!customDiary.hasContent && todoSeeds.isNotEmpty) ...[
            ...todoSeeds.take(3).map(
                  (seed) => Container(
                    width: double.infinity,
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
                    decoration: BoxDecoration(
                      color: _tileSurface,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: _paperEdge),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(seed.icon, size: 18, color: _accentInk),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                seed.title,
                                style: _theme.textTheme.labelLarge?.copyWith(
                                  color: _headlineInk,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          seed.summary,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: _theme.textTheme.bodyMedium?.copyWith(
                            color: _bodyInk,
                            height: 1.35,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
          ],
          if (!customDiary.hasContent && todoSeeds.isNotEmpty)
            const SizedBox(height: 4),
        ],
      ),
    );
  }

  Widget _buildRecordStickerCard(_DiaryRecordStickerViewData sticker) {
    final hasBoardPreview = sticker.boardPage != null;
    final isNewsSticker = sticker.kind == _DiaryRecordStickerKind.news;
    final isMealSticker = sticker.kind == _DiaryRecordStickerKind.meal;
    final isFortuneSticker = sticker.kind == _DiaryRecordStickerKind.fortune;
    final isTrainingSticker = sticker.kind == _DiaryRecordStickerKind.training;
    final isQuizSticker = sticker.kind == _DiaryRecordStickerKind.quiz;
    if (isFortuneSticker && sticker.fortune != null) {
      final fortune = sticker.fortune!;
      return Container(
        key: ValueKey('diary-record-sticker-${sticker.id}'),
        width: double.infinity,
        margin: const EdgeInsets.only(bottom: 10),
        decoration: BoxDecoration(
          color: _recordStickerCardSurface(sticker.tint),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: sticker.tint.withValues(alpha: _isDark ? 0.42 : 0.28),
          ),
        ),
        child: FortuneCard(
          sections: FortuneSections(
            bodyLines: fortune.bodyLines,
            luckyInfoLines: fortune.luckyInfoLines,
          ),
          title: sticker.title,
          subtitle: '',
          luckyInfoTitle: _l10n.fortuneDialogLuckyInfoTitle,
          overviewTitle: _l10n.fortuneDialogOverviewTitle,
          overallFortuneLabel: _l10n.fortuneDialogOverallFortuneLabel,
          overallFortuneCount: _l10n.fortuneDialogOverallFortuneCount(
            fortune.bodyLines.length,
          ),
          luckyInfoLabel: _l10n.fortuneDialogLuckyInfoLabel,
          luckyInfoCount: _l10n.fortuneDialogLuckyInfoCount(
            fortune.luckyInfoLines.length,
          ),
          isKo: _isKo,
          compact: true,
          showOverview: false,
        ),
      );
    }
    final content = Padding(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 28,
                height: 28,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: sticker.tint.withValues(alpha: _isDark ? 0.2 : 0.12),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Icon(sticker.icon, size: 16, color: sticker.tint),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  sticker.title,
                  maxLines: isNewsSticker ? 2 : null,
                  overflow: isNewsSticker ? TextOverflow.ellipsis : null,
                  style: _theme.textTheme.labelLarge?.copyWith(
                    color: _headlineInk,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          if (!isMealSticker &&
              !isQuizSticker &&
              sticker.summary.trim().isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(
              sticker.summary,
              maxLines: isNewsSticker
                  ? 3
                  : (isFortuneSticker ||
                          (isTrainingSticker && sticker.focusItems.isEmpty)
                      ? null
                      : 3),
              overflow: isFortuneSticker ||
                      (isTrainingSticker && sticker.focusItems.isEmpty)
                  ? null
                  : TextOverflow.ellipsis,
              style: _theme.textTheme.bodyMedium?.copyWith(
                color: _bodyInk,
                height: 1.5,
              ),
            ),
          ],
          if (isQuizSticker) ...[
            const SizedBox(height: 10),
            _buildQuizStickerBody(sticker),
          ],
          if (sticker.focusItems.isNotEmpty) ...[
            const SizedBox(height: 10),
            Column(
              children: [
                for (var i = 0; i < sticker.focusItems.length; i++)
                  Padding(
                    padding: EdgeInsets.only(
                      bottom: i == sticker.focusItems.length - 1 ? 0 : 10,
                    ),
                    child: _buildTrainingFocusItem(
                      sticker.focusItems[i],
                      tint: sticker.tint,
                    ),
                  ),
              ],
            ),
          ],
          if (isMealSticker && sticker.mealEntry != null)
            Padding(
              padding: const EdgeInsets.only(top: 10),
              child: RiceBowlInlineSummary(
                entry: sticker.mealEntry,
                accentColor: sticker.tint,
              ),
            ),
          if (hasBoardPreview) ...[
            const SizedBox(height: 10),
            SizedBox(
              height: 150,
              width: double.infinity,
              child: TrainingBoardSketch(
                page: sticker.boardPage!,
                borderRadius: 14,
                showItemCountBadge: false,
              ),
            ),
          ],
        ],
      ),
    );
    return Container(
      key: ValueKey('diary-record-sticker-${sticker.id}'),
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: _recordStickerCardSurface(sticker.tint),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: sticker.tint.withValues(alpha: _isDark ? 0.42 : 0.28),
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: isNewsSticker ? () => _openNewsSticker(sticker) : null,
          child: content,
        ),
      ),
    );
  }

  Widget _buildTrainingFocusItem(
    _DiaryStickerFocusItem item, {
    required Color tint,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
      decoration: BoxDecoration(
        color: tint.withValues(alpha: _isDark ? 0.14 : 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: tint.withValues(alpha: _isDark ? 0.24 : 0.16),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            item.title,
            style: _theme.textTheme.labelLarge?.copyWith(
              color: _headlineInk,
              fontWeight: FontWeight.w800,
              height: 1.3,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            item.body,
            style: _theme.textTheme.bodyMedium?.copyWith(
              color: _bodyInk,
              height: 1.45,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuizStickerBody(_DiaryRecordStickerViewData sticker) {
    final quiz = sticker.quizSummary;
    if (quiz == null) {
      return Text(
        sticker.summary,
        style: _theme.textTheme.bodyMedium?.copyWith(
          color: _bodyInk,
          height: 1.5,
        ),
      );
    }

    final isExpanded = _expandedQuizStickerIds.contains(sticker.id);
    final visibleQuestions =
        isExpanded ? quiz.questions : quiz.questions.take(2).toList();
    final canToggle = quiz.questions.length > 2;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          sticker.summary,
          style: _theme.textTheme.bodyMedium?.copyWith(
            color: _bodyInk,
            height: 1.45,
          ),
        ),
        if (visibleQuestions.isNotEmpty) ...[
          const SizedBox(height: 12),
          ...visibleQuestions.asMap().entries.map(
                (entry) => Padding(
                  padding: EdgeInsets.only(
                    bottom:
                        entry.key == visibleQuestions.length - 1 && !canToggle
                            ? 0
                            : 10,
                  ),
                  child: _buildQuizStickerQuestionCard(sticker, entry.value),
                ),
              ),
        ],
        if (canToggle)
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              onPressed: () {
                setState(() {
                  if (isExpanded) {
                    _expandedQuizStickerIds.remove(sticker.id);
                  } else {
                    _expandedQuizStickerIds.add(sticker.id);
                  }
                });
              },
              icon: Icon(
                isExpanded
                    ? Icons.expand_less_rounded
                    : Icons.expand_more_rounded,
                size: 18,
              ),
              label: Text(
                isExpanded
                    ? _l10n.diaryQuizCollapseQuestions
                    : _l10n.diaryQuizExpandQuestions(quiz.questions.length),
              ),
              style: TextButton.styleFrom(
                foregroundColor: sticker.tint,
                padding: const EdgeInsets.symmetric(horizontal: 0, vertical: 4),
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                visualDensity: VisualDensity.compact,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildQuizStickerQuestionCard(
    _DiaryRecordStickerViewData sticker,
    _DiaryQuizQuestion question,
  ) {
    const correctTint = Color(0xFF1D8A5A);
    final isMissed = question.hasWrongAnswer;
    final questionTint = isMissed
        ? const Color(0xFFC74B4B)
        : sticker.tint.withValues(alpha: _isDark ? 0.72 : 0.88);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
      decoration: BoxDecoration(
        color: sticker.tint.withValues(alpha: _isDark ? 0.16 : 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: sticker.tint.withValues(alpha: _isDark ? 0.34 : 0.22),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(10, 10, 10, 10),
            decoration: BoxDecoration(
              color: questionTint.withValues(alpha: _isDark ? 0.18 : 0.10),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _l10n.diaryQuizQuestionLabel,
                  style: _theme.textTheme.labelMedium?.copyWith(
                    color: questionTint,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.2,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  question.prompt(_isKo),
                  style: _theme.textTheme.bodyMedium?.copyWith(
                    color: _headlineInk,
                    fontWeight: FontWeight.w700,
                    height: 1.45,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          _buildQuizStickerAnswerRow(
            label: _l10n.diaryQuizAnswerLabel,
            value: question.answer(_isKo),
            tint: correctTint,
          ),
        ],
      ),
    );
  }

  Widget _buildQuizStickerAnswerRow({
    required String label,
    required String value,
    required Color tint,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(10, 10, 10, 10),
      decoration: BoxDecoration(
        color: tint.withValues(alpha: _isDark ? 0.18 : 0.10),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: _theme.textTheme.labelSmall?.copyWith(
              color: tint,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: _theme.textTheme.bodyMedium?.copyWith(
              color: _headlineInk,
              fontWeight: FontWeight.w700,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _openNewsSticker(_DiaryRecordStickerViewData sticker) async {
    final link = sticker.link?.trim() ?? '';
    final uri = Uri.tryParse(link);
    if (uri == null || !uri.hasScheme) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(_l10n.diaryNewsOpenFailed)));
      return;
    }
    final opened = await launchUrl(
      uri,
      mode: LaunchMode.inAppBrowserView,
      browserConfiguration: const BrowserConfiguration(showTitle: true),
    );
    if (!opened && mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(_l10n.diaryNewsOpenFailed)));
    }
  }

  Widget _buildDiarySection({
    required String title,
    String? subtitle,
    Widget? trailing,
    required Widget child,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              child: Text(
                title,
                style: _theme.textTheme.titleMedium?.copyWith(
                  color: _headlineInk,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
            if (trailing != null) trailing,
          ],
        ),
        const SizedBox(height: 8),
        if (subtitle != null && subtitle.trim().isNotEmpty) ...[
          Row(
            children: [
              Icon(
                Icons.wb_cloudy_outlined,
                size: 16,
                color: _accentInk.withValues(alpha: 0.84),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  subtitle,
                  style: _theme.textTheme.bodySmall?.copyWith(
                    color: _bodyInk,
                    fontWeight: FontWeight.w700,
                    height: 1.4,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
        ],
        Divider(color: _paperEdge, height: 1),
        const SizedBox(height: 12),
        child,
      ],
    );
  }

  // ignore: unused_element
  _DiaryStickerChipData? _resolveDiarySticker(String id) {
    final preset = _DiaryStickerPalette.fromId(id);
    if (preset != null) {
      return _DiaryStickerChipData(
        id: preset.id,
        label: _isKo ? preset.labelKo : preset.labelEn,
        icon: preset.icon,
        tint: preset.tint,
      );
    }
    final customLabel = _DiaryStickerPalette.customLabelFromId(id);
    if (customLabel == null) return null;
    return _DiaryStickerChipData(
      id: id,
      label: customLabel,
      icon: Icons.add_reaction_outlined,
      tint: const Color(0xFF7B5CC7),
      isCustom: true,
    );
  }

  String _trainingSummaryShort(TrainingEntry entry) {
    final detail = _trainingSummary(entry);
    final firstLine = detail.split('\n').first;
    final parts = firstLine
        .split(' · ')
        .map((part) => part.trim())
        .where((part) => part.isNotEmpty)
        .toList(growable: false);
    if (parts.length <= 4) return firstLine;
    return parts.take(4).join(' · ');
  }

  String _trainingStickerSummary(TrainingEntry entry) {
    final lines = <String>[
      _trainingSummaryShort(entry),
      if (!TrainingBoardLinkCodec.isBoardLinkPayload(entry.drills) &&
          entry.drills.trim().isNotEmpty)
        entry.drills.trim(),
    ];
    return lines.join('\n');
  }

  Color _recordStickerCardSurface(Color tint) {
    return _isDark
        ? Color.alphaBlend(tint.withValues(alpha: 0.12), _tileSurface)
        : tint.withValues(alpha: 0.12);
  }

  Color _composerIdleSurface() {
    return _isDark
        ? Colors.white.withValues(alpha: 0.06)
        : Colors.white.withValues(alpha: 0.68);
  }

  BorderSide _composerIdleBorder() {
    return BorderSide(
      color: _isDark
          ? Colors.white.withValues(alpha: 0.12)
          : _paperEdge.withValues(alpha: 0.92),
    );
  }

  Widget _buildEmptyCard({required VoidCallback onCreateDiary}) {
    return _buildPaperCard(
      title: _isKo ? '아직 만든 다이어리가 없습니다.' : 'No diary pages yet',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _isKo
                ? '날짜를 골라 첫 페이지를 만들면 다이어리가 시작됩니다.'
                : 'Pick a date and create your first page.',
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: _bodyInk, height: 1.5),
          ),
          const SizedBox(height: 14),
          FilledButton.icon(
            key: const ValueKey('diary-create-first-button'),
            onPressed: onCreateDiary,
            icon: const Icon(Icons.add_circle_outline),
            label: Text(_isKo ? '첫 다이어리 만들기' : 'Create first diary'),
          ),
        ],
      ),
    );
  }

  Widget _buildPaperCard({
    required String? title,
    String? subtitle,
    Widget? trailing,
    required Widget child,
  }) {
    final hasHeader = (title?.trim().isNotEmpty ?? false) ||
        (subtitle?.trim().isNotEmpty ?? false) ||
        trailing != null;
    return Container(
      decoration: _paperDecoration(),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (hasHeader) ...[
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (title != null && title.trim().isNotEmpty)
                          Text(
                            title,
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium
                                ?.copyWith(
                                  color: _headlineInk,
                                  fontWeight: FontWeight.w900,
                                ),
                          ),
                        if (subtitle != null && subtitle.trim().isNotEmpty) ...[
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
            ],
            child,
          ],
        ),
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

  Map<DateTime, List<TrainingEntry>> _groupEntriesByDay(
    List<TrainingEntry> entries,
  ) {
    final grouped = <DateTime, List<TrainingEntry>>{};
    for (final entry in entries) {
      final day = _normalizeDay(entry.date);
      grouped.putIfAbsent(day, () => <TrainingEntry>[]).add(entry);
    }
    return grouped;
  }

  Map<DateTime, List<_DiaryPlan>> _groupPlansByDay(List<_DiaryPlan> plans) {
    final grouped = <DateTime, List<_DiaryPlan>>{};
    for (final plan in plans) {
      final day = _normalizeDay(plan.scheduledAt);
      grouped.putIfAbsent(day, () => <_DiaryPlan>[]).add(plan);
    }
    return grouped;
  }

  Map<DateTime, MealEntry> _groupMealEntriesByDay(List<MealEntry> entries) {
    final grouped = <DateTime, MealEntry>{};
    for (final entry in entries) {
      final day = _normalizeDay(entry.date);
      final previous = grouped[day];
      if (previous == null || entry.createdAt.isAfter(previous.createdAt)) {
        grouped[day] = entry;
      }
    }
    return grouped;
  }

  List<_DiaryDayData> _buildDays({
    required Map<DateTime, List<TrainingEntry>> entriesByDay,
    required Map<DateTime, MealEntry> mealEntriesByDay,
    required Map<DateTime, List<_DiaryPlan>> plansByDay,
    required Map<String, TrainingBoard> boardMap,
  }) {
    final diaryDates = _customDiaryEntries.keys
        .map(DateTime.tryParse)
        .whereType<DateTime>()
        .map(_normalizeDay)
        .toSet();
    final days = diaryDates
        .map(
          (day) => _buildDiaryDayData(
            day: day,
            entriesByDay: entriesByDay,
            mealEntriesByDay: mealEntriesByDay,
            plansByDay: plansByDay,
            boardMap: boardMap,
          ),
        )
        .toList(growable: false)
      ..sort((a, b) => b.date.compareTo(a.date));
    return days;
  }

  _DiaryDayData _buildDiaryDayData({
    required DateTime day,
    required Map<DateTime, List<TrainingEntry>> entriesByDay,
    required Map<DateTime, MealEntry> mealEntriesByDay,
    required Map<DateTime, List<_DiaryPlan>> plansByDay,
    required Map<String, TrainingBoard> boardMap,
  }) {
    final dayEntries = entriesByDay[day] ?? const <TrainingEntry>[];
    final linkedBoards = <String, TrainingBoard>{};
    for (final entry in dayEntries) {
      for (final id in TrainingBoardLinkCodec.decodeBoardIds(entry.drills)) {
        final board = boardMap[id];
        if (board != null) linkedBoards[id] = board;
      }
    }
    return _DiaryDayData(
      date: day,
      entries: [...dayEntries]..sort((a, b) => a.date.compareTo(b.date)),
      mealEntry: mealEntriesByDay[day],
      plans: [...(plansByDay[day] ?? const <_DiaryPlan>[])]
        ..sort((a, b) => a.scheduledAt.compareTo(b.scheduledAt)),
      boards: linkedBoards.values.toList(growable: false)
        ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt)),
    );
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

  Map<String, _CustomDiaryEntryData> _loadCustomDiaryEntries() {
    final raw = widget.optionRepository.getValue<String>(
      _customDiaryEntriesKey,
    );
    if (raw == null || raw.trim().isEmpty) {
      return <String, _CustomDiaryEntryData>{};
    }
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map) {
        return <String, _CustomDiaryEntryData>{};
      }
      return decoded.map((key, value) {
        if (value is Map<String, dynamic>) {
          return MapEntry(key.toString(), _CustomDiaryEntryData.fromMap(value));
        }
        if (value is Map) {
          return MapEntry(
            key.toString(),
            _CustomDiaryEntryData.fromMap(value.cast<String, dynamic>()),
          );
        }
        return MapEntry(key.toString(), const _CustomDiaryEntryData.empty());
      });
    } catch (_) {
      return <String, _CustomDiaryEntryData>{};
    }
  }

  Future<void> _persistCustomDiaryEntries() {
    final payload = <String, Map<String, dynamic>>{};
    for (final entry in _customDiaryEntries.entries) {
      if (!entry.value.hasContent) continue;
      payload[entry.key] = entry.value.toMap();
    }
    return widget.optionRepository.setValue(
      _customDiaryEntriesKey,
      jsonEncode(payload),
    );
  }

  String _dayStorageToken(DateTime date) {
    return DateFormat('yyyy-MM-dd').format(_normalizeDay(date));
  }

  _CustomDiaryEntryData _customDiaryForDay(DateTime date) {
    return _customDiaryEntries[_dayStorageToken(date)] ??
        const _CustomDiaryEntryData.empty();
  }

  Future<void> _saveCustomDiary(
    DateTime date,
    _CustomDiaryEntryData data, {
    bool showFeedback = true,
  }) async {
    if (_isParentReadOnlyMode) {
      _showParentReadOnlyMessage();
      return;
    }
    final token = _dayStorageToken(date);
    if (data.hasContent) {
      _customDiaryEntries[token] = data.copyWith(updatedAt: DateTime.now());
    } else {
      _customDiaryEntries.remove(token);
    }
    await _persistCustomDiaryEntries();
    if (!mounted) return;
    setState(() {});
    if (showFeedback) {
      AppFeedback.showSuccess(
        context,
        text: _isKo ? '다이어리를 저장했어요.' : 'Diary saved.',
      );
    }
  }

  Future<void> _confirmDeleteDiary(DateTime date) async {
    if (_isParentReadOnlyMode) {
      _showParentReadOnlyMessage();
      return;
    }
    final token = _dayStorageToken(date);
    final removedDiary = _customDiaryEntries[token];
    if (removedDiary == null) return;
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(_isKo ? '다이어리 삭제' : 'Delete diary'),
        content: Text(_isKo ? '이 날짜의 다이어리를 삭제할까요?' : 'Delete this day diary?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(_isKo ? '취소' : 'Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(_isKo ? '삭제' : 'Delete'),
          ),
        ],
      ),
    );
    if (shouldDelete != true) return;
    _customDiaryEntries.remove(token);
    final dayToken = CoachLessonScreen.todayViewedDayToken(date);
    if (_lastCompletedDiaryToken == dayToken) {
      _lastCompletedDiaryToken = null;
    }
    final completedToken = widget.optionRepository.getValue<String>(
      CoachLessonScreen.todayViewedDiaryDayKey,
    );
    if (completedToken == dayToken) {
      await widget.optionRepository.setValue(
        CoachLessonScreen.todayViewedDiaryDayKey,
        '',
      );
    }
    await _persistCustomDiaryEntries();
    if (!mounted) return;
    setState(() {});
    final messenger = ScaffoldMessenger.of(context);
    messenger
      ..clearSnackBars()
      ..showSnackBar(
        SnackBar(
          content: Text(_isKo ? '다이어리를 삭제했어요.' : 'Diary deleted.'),
          duration: const Duration(seconds: 5),
          action: SnackBarAction(
            label: _isKo ? '되돌리기' : 'Undo',
            onPressed: () {
              unawaited(_undoDeleteDiary(date, removedDiary));
            },
          ),
        ),
      );
  }

  Future<void> _undoDeleteDiary(
    DateTime date,
    _CustomDiaryEntryData restoredDiary,
  ) async {
    final token = _dayStorageToken(date);
    _customDiaryEntries[token] = restoredDiary;
    final dayToken = CoachLessonScreen.todayViewedDayToken(date);
    _lastCompletedDiaryToken = dayToken;
    await widget.optionRepository.setValue(
      CoachLessonScreen.todayViewedDiaryDayKey,
      dayToken,
    );
    await _persistCustomDiaryEntries();
    if (!mounted) return;
    setState(() {});
    AppFeedback.showSuccess(
      context,
      text: _isKo ? '삭제를 되돌렸어요.' : 'Restored deleted diary.',
    );
  }

  Future<void> _openNewDiaryComposer({
    required Map<DateTime, List<TrainingEntry>> entriesByDay,
    required Map<DateTime, MealEntry> mealEntriesByDay,
    required Map<DateTime, List<_DiaryPlan>> plansByDay,
    required Map<String, TrainingBoard> boardMap,
  }) async {
    if (_isParentReadOnlyMode) {
      _showParentReadOnlyMessage();
      return;
    }
    final today = _normalizeDay(DateTime.now());
    final initialDate = _customDiaryEntries.keys
            .map(DateTime.tryParse)
            .whereType<DateTime>()
            .map(_normalizeDay)
            .contains(today)
        ? today.add(const Duration(days: 1))
        : today;
    final firstDay = DateTime(2020, 1, 1);
    final lastDay = DateTime(2100, 12, 31);
    final markerMap = <DateTime, Set<_DiaryMarkerType>>{};
    for (final token in _customDiaryEntries.keys) {
      final parsed = DateTime.tryParse(token);
      if (parsed == null) continue;
      markerMap
          .putIfAbsent(_normalizeDay(parsed), () => <_DiaryMarkerType>{})
          .add(_DiaryMarkerType.diary);
    }

    DateTime focusedDay = initialDate;
    DateTime? picked;
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
                child: TableCalendar<_DiaryMarkerType>(
                  locale: _isKo ? 'ko_KR' : 'en_US',
                  firstDay: firstDay,
                  lastDay: lastDay,
                  focusedDay: focusedDay,
                  calendarFormat: CalendarFormat.month,
                  rowHeight: 42,
                  daysOfWeekHeight: 18,
                  availableGestures: AvailableGestures.horizontalSwipe,
                  startingDayOfWeek: StartingDayOfWeek.sunday,
                  headerStyle: const HeaderStyle(
                    formatButtonVisible: false,
                    titleCentered: true,
                    headerPadding: EdgeInsets.symmetric(vertical: 6),
                    leftChevronPadding: EdgeInsets.zero,
                    rightChevronPadding: EdgeInsets.zero,
                  ),
                  selectedDayPredicate: (day) =>
                      picked != null && isSameDay(day, picked),
                  onDaySelected: (selected, focused) {
                    picked = _normalizeDay(selected);
                    Navigator.of(sheetContext).pop();
                  },
                  onPageChanged: (focused) {
                    setSheetState(() => focusedDay = focused);
                  },
                  eventLoader: (day) {
                    return markerMap[_normalizeDay(day)]?.toList(
                          growable: false,
                        ) ??
                        const <_DiaryMarkerType>[];
                  },
                  calendarBuilders: CalendarBuilders<_DiaryMarkerType>(
                    markerBuilder: (context, day, markers) {
                      if (markers.isEmpty) return const SizedBox.shrink();
                      final markerList = markers
                          .whereType<_DiaryMarkerType>()
                          .toList(growable: false);
                      if (markerList.isEmpty) return const SizedBox.shrink();
                      return Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: markerList
                            .take(4)
                            .map(
                              (marker) => Container(
                                key: ValueKey(
                                  'diary-calendar-marker-${_dayStorageToken(day)}-${marker.name}',
                                ),
                                width: 6,
                                height: 6,
                                margin: const EdgeInsets.symmetric(
                                  horizontal: 1.5,
                                ),
                                decoration: BoxDecoration(
                                  color: marker.color,
                                  shape: BoxShape.circle,
                                ),
                              ),
                            )
                            .toList(growable: false),
                      );
                    },
                  ),
                ),
              ),
            );
          },
        );
      },
    );
    if (picked == null) return;
    final normalized = _normalizeDay(picked!);
    final day = _buildDiaryDayData(
      day: normalized,
      entriesByDay: entriesByDay,
      mealEntriesByDay: mealEntriesByDay,
      plansByDay: plansByDay,
      boardMap: boardMap,
    );
    await _openDiaryComposer(day, _customDiaryForDay(normalized));
    if (!mounted) return;
    final orderedDays = _buildDays(
      entriesByDay: entriesByDay,
      mealEntriesByDay: mealEntriesByDay,
      plansByDay: plansByDay,
      boardMap: boardMap,
    );
    final index = orderedDays.indexWhere((entry) => entry.date == normalized);
    if (index >= 0) {
      setState(() => _selectedDayIndex = index);
      if (_pageController.hasClients) {
        await _movePage(index);
      }
    }
  }

  bool get _isParentReadOnlyMode {
    return FamilyAccessService(widget.optionRepository)
        .loadState()
        .isParentMode;
  }

  void _showParentReadOnlyMessage() {
    AppFeedback.showMessage(
      context,
      text: _l10n.parentReadOnlyDiaryMessage,
    );
  }

  void _consumeTodayDiaryOpenRequest({
    required List<_DiaryDayData> days,
    required Map<DateTime, List<TrainingEntry>> entriesByDay,
    required Map<DateTime, MealEntry> mealEntriesByDay,
    required Map<DateTime, List<_DiaryPlan>> plansByDay,
    required Map<String, TrainingBoard> boardMap,
  }) {
    final requestKey = widget.openTodayDiaryRequestKey;
    if (requestKey == 0 || requestKey == _lastHandledOpenTodayDiaryRequestKey) {
      return;
    }
    _lastHandledOpenTodayDiaryRequestKey = requestKey;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _openTodayDiaryFromHome(
        days: days,
        entriesByDay: entriesByDay,
        mealEntriesByDay: mealEntriesByDay,
        plansByDay: plansByDay,
        boardMap: boardMap,
      );
    });
  }

  Future<void> _openTodayDiaryFromHome({
    required List<_DiaryDayData> days,
    required Map<DateTime, List<TrainingEntry>> entriesByDay,
    required Map<DateTime, MealEntry> mealEntriesByDay,
    required Map<DateTime, List<_DiaryPlan>> plansByDay,
    required Map<String, TrainingBoard> boardMap,
  }) async {
    final today = _normalizeDay(DateTime.now());
    final todayToken = _dayStorageToken(today);
    if (_customDiaryEntries.containsKey(todayToken)) {
      final index = days.indexWhere((entry) => entry.date == today);
      if (index >= 0) {
        setState(() => _selectedDayIndex = index);
        await _movePage(index);
      }
      final viewedToken = CoachLessonScreen.todayViewedDayToken(today);
      _lastCompletedDiaryToken = viewedToken;
      await widget.optionRepository.setValue(
        CoachLessonScreen.todayViewedDiaryDayKey,
        viewedToken,
      );
      return;
    }

    final todayDay = _buildDiaryDayData(
      day: today,
      entriesByDay: entriesByDay,
      mealEntriesByDay: mealEntriesByDay,
      plansByDay: plansByDay,
      boardMap: boardMap,
    );
    await _openDiaryComposer(todayDay, _customDiaryForDay(today));
    if (!mounted) return;
    final orderedDays = _buildDays(
      entriesByDay: entriesByDay,
      mealEntriesByDay: mealEntriesByDay,
      plansByDay: plansByDay,
      boardMap: boardMap,
    );
    final index = orderedDays.indexWhere((entry) => entry.date == today);
    if (index >= 0) {
      setState(() => _selectedDayIndex = index);
      await _movePage(index);
    }
  }

  _DiaryRecordStickerViewData? _resolveRecordSticker(
    _DiaryRecordStickerData sticker,
    _DiaryDayData day,
  ) {
    switch (sticker.kind) {
      case _DiaryRecordStickerKind.training:
        final entry = day.trainingEntries.cast<TrainingEntry?>().firstWhere(
              (item) =>
                  '${item?.createdAt.millisecondsSinceEpoch}' == sticker.refId,
              orElse: () => null,
            );
        if (entry == null) return null;
        final primaryLabel =
            entry.program.trim().isNotEmpty ? entry.program.trim() : entry.type;
        final programEmoji = trainingProgramEmojiFor(primaryLabel);
        final statusEmoji = trainingStatusEmojiFor(entry.status);
        // Remove soccer-ball emoji before training type; keep other program emojis.
        final showProgramEmoji = programEmoji != '⚽';
        final displayLabel = '${statusEmoji.isNotEmpty ? '$statusEmoji ' : ''}'
            '${showProgramEmoji ? '$programEmoji ' : ''}'
            '$primaryLabel';
        return _DiaryRecordStickerViewData(
          id: sticker.storageId,
          kind: _DiaryRecordStickerKind.training,
          title: displayLabel,
          summary: _trainingStickerSummary(entry),
          metaLabels: [
            if (entry.location.trim().isNotEmpty) entry.location.trim(),
            _isKo
                ? '${entry.durationMinutes}분'
                : '${entry.durationMinutes} min',
            '${_l10n.diaryTrainingStatusLabel} ${_trainingStatusLabel(entry.status)}',
            _isKo ? '컨디션 ${entry.mood}' : 'Condition ${entry.mood}',
            _isKo ? '강도 ${entry.intensity}' : 'Intensity ${entry.intensity}',
          ],
          // Match the icon used when recording training status
          icon: trainingStatusVisual(entry.status).icon,
          tint: const Color(0xFF2F8F6A),
          focusItems: _trainingFocusItems(entry),
        );
      case _DiaryRecordStickerKind.match:
        final entry = day.matchEntries.cast<TrainingEntry?>().firstWhere(
              (item) =>
                  '${item?.createdAt.millisecondsSinceEpoch}' == sticker.refId,
              orElse: () => null,
            );
        if (entry == null) return null;
        return _DiaryRecordStickerViewData(
          id: sticker.storageId,
          kind: _DiaryRecordStickerKind.match,
          title: entry.opponentTeam.trim().isEmpty
              ? _l10n.diaryStickerMatch
              : _isKo
                  ? '${entry.opponentTeam.trim()}전'
                  : 'vs ${entry.opponentTeam.trim()}',
          summary: _matchSummary(entry),
          metaLabels: [
            if ((entry.minutesPlayed ?? 0) > 0)
              _isKo
                  ? '${entry.minutesPlayed}분 출전'
                  : '${entry.minutesPlayed} min',
            if (entry.scoredGoals != null && entry.concededGoals != null)
              '${entry.scoredGoals}-${entry.concededGoals}',
            if ((entry.playerGoals ?? 0) > 0 || (entry.playerAssists ?? 0) > 0)
              _isKo
                  ? '${entry.playerGoals ?? 0}골 ${entry.playerAssists ?? 0}도움'
                  : '${entry.playerGoals ?? 0}G ${entry.playerAssists ?? 0}A',
          ],
          icon: Icons.sports_soccer_outlined,
          tint: const Color(0xFF2E6ECF),
        );
      case _DiaryRecordStickerKind.plan:
        final plan = day.plans.cast<_DiaryPlan?>().firstWhere(
              (item) => item?.id == sticker.refId,
              orElse: () => null,
            );
        if (plan == null) return null;
        return _DiaryRecordStickerViewData(
          id: sticker.storageId,
          kind: _DiaryRecordStickerKind.plan,
          title: plan.category,
          summary: _isKo
              ? '${_formatTime(plan.scheduledAt)} · ${plan.durationMinutes}분${plan.note.trim().isEmpty ? '' : ' · ${plan.note.trim()}'}'
              : '${_formatTime(plan.scheduledAt)} · ${plan.durationMinutes} min${plan.note.trim().isEmpty ? '' : ' · ${plan.note.trim()}'}',
          metaLabels: [
            _formatTime(plan.scheduledAt),
            _isKo ? '${plan.durationMinutes}분' : '${plan.durationMinutes} min',
          ],
          icon: Icons.event_note_outlined,
          tint: const Color(0xFF97754A),
        );
      case _DiaryRecordStickerKind.fortune:
        final entry = day.trainingEntries.cast<TrainingEntry?>().firstWhere(
              (item) =>
                  '${item?.createdAt.millisecondsSinceEpoch}' == sticker.refId,
              orElse: () => null,
            );
        if (entry == null) return null;
        final fortune = _DiaryFortune.fromEntry(entry);
        return _DiaryRecordStickerViewData(
          id: sticker.storageId,
          kind: _DiaryRecordStickerKind.fortune,
          title: _formatDiaryDate(entry.date),
          summary: fortune.composeText(),
          metaLabels: [
            _formatDiaryDate(entry.date),
            _isKo ? '강도 ${entry.intensity}' : 'Intensity ${entry.intensity}',
          ],
          icon: Icons.auto_awesome_outlined,
          tint: const Color(0xFF9B51E0),
          fortune: fortune,
        );
      case _DiaryRecordStickerKind.board:
        final board = day.boards.cast<TrainingBoard?>().firstWhere(
              (item) => item?.id == sticker.refId,
              orElse: () => null,
            );
        if (board == null) return null;
        final layout = TrainingMethodLayout.decode(board.layoutJson);
        final boardMemo =
            layout.pages.isNotEmpty ? layout.pages.first.methodText.trim() : '';
        return _DiaryRecordStickerViewData(
          id: sticker.storageId,
          kind: _DiaryRecordStickerKind.board,
          title: board.title,
          summary: boardMemo.isNotEmpty
              ? boardMemo
              : (_isKo
                  ? '이 보드에서 기록한 움직임과 아이디어'
                  : 'Movement and idea captured on this board'),
          metaLabels: [
            if (layout.pages.isNotEmpty &&
                layout.pages.first.name.trim().isNotEmpty)
              layout.pages.first.name.trim(),
            _isKo
                ? '업데이트 ${DateFormat('M.d HH:mm', 'ko').format(board.updatedAt)}'
                : 'Updated ${DateFormat('MMM d HH:mm', 'en').format(board.updatedAt)}',
          ],
          icon: Icons.dashboard_customize_outlined,
          tint: const Color(0xFF4A7CCF),
          boardPage: layout.pages.isNotEmpty ? layout.pages.first : null,
        );
      case _DiaryRecordStickerKind.news:
        final openedNews = _openedNewsForDay(day.date);
        final item = openedNews.cast<_DiaryOpenedNewsItem?>().firstWhere(
              (entry) => entry?.id == sticker.refId,
              orElse: () => null,
            );
        if (item == null) return null;
        final displayTitle = item.displayTitle(_isKo);
        return _DiaryRecordStickerViewData(
          id: sticker.storageId,
          kind: _DiaryRecordStickerKind.news,
          title: displayTitle,
          summary: _isKo
              ? '${item.source.isEmpty ? '출처 없음' : item.source} · ${_formatTime(item.openedAt)}'
              : '${item.source.isEmpty ? 'Unknown source' : item.source} · ${_formatTime(item.openedAt)}',
          metaLabels: [
            item.source.isEmpty
                ? (_isKo ? '출처 없음' : 'Unknown source')
                : item.source,
            _formatTime(item.openedAt),
          ],
          icon: Icons.article_outlined,
          tint: const Color(0xFF7A4ED8),
          link: item.link,
        );
      case _DiaryRecordStickerKind.weather:
        final weather = _weatherSummaryForDay(day).trim();
        if (weather.isEmpty || sticker.refId != _dayStorageToken(day.date)) {
          return null;
        }
        return _DiaryRecordStickerViewData(
          id: sticker.storageId,
          kind: _DiaryRecordStickerKind.weather,
          title: _l10n.diaryStickerWeather,
          summary: weather,
          metaLabels: [_formatDiaryDate(day.date)],
          icon: Icons.wb_cloudy_outlined,
          tint: const Color(0xFF4E86C8),
        );
      case _DiaryRecordStickerKind.meal:
        final mealEntry = day.mealEntry;
        if (mealEntry == null || sticker.refId != _dayStorageToken(day.date)) {
          return null;
        }
        return _DiaryRecordStickerViewData(
          id: sticker.storageId,
          kind: _DiaryRecordStickerKind.meal,
          title: _l10n.diaryStickerMeal,
          summary: _mealSummary(mealEntry),
          metaLabels: [
            _isKo
                ? '총 ${mealEntry.totalRiceBowls.toStringAsFixed(mealEntry.totalRiceBowls.truncateToDouble() == mealEntry.totalRiceBowls ? 0 : 1)}공기'
                : '${mealEntry.totalRiceBowls.toStringAsFixed(mealEntry.totalRiceBowls.truncateToDouble() == mealEntry.totalRiceBowls ? 0 : 1)} bowls',
            _isKo
                ? '${mealEntry.completedMeals}끼 기록'
                : '${mealEntry.completedMeals} meals',
          ],
          icon: Icons.rice_bowl_outlined,
          tint: const Color(0xFFB45309),
          mealEntry: mealEntry,
        );
      case _DiaryRecordStickerKind.conditioning:
        final dayToken = _dayStorageToken(day.date);
        if (sticker.refId != dayToken) return null;
        return _DiaryRecordStickerViewData(
          id: sticker.storageId,
          kind: _DiaryRecordStickerKind.conditioning,
          title: _l10n.diaryStickerConditioning,
          summary: _conditioningJumpRopeSummary(day),
          metaLabels: [
            if (_totalJumpRopeMinutes(day) > 0)
              _isKo
                  ? '${_totalJumpRopeMinutes(day)}분'
                  : '${_totalJumpRopeMinutes(day)} min',
            if (_totalJumpRopeCount(day) > 0)
              _isKo
                  ? '${_totalJumpRopeCount(day)}회'
                  : '${_totalJumpRopeCount(day)} reps',
          ],
          icon: Icons.sports_gymnastics_outlined,
          tint: const Color(0xFF2F8F6A),
          focusItems: _conditioningFocusItems(day),
        );
      case _DiaryRecordStickerKind.injury:
        final dayToken = _dayStorageToken(day.date);
        if (sticker.refId != dayToken) return null;
        return _DiaryRecordStickerViewData(
          id: sticker.storageId,
          kind: _DiaryRecordStickerKind.injury,
          title: _l10n.diaryStickerInjury,
          summary: _injurySummary(day),
          icon: Icons.healing_outlined,
          tint: const Color(0xFFC45D3C),
        );
      case _DiaryRecordStickerKind.quiz:
        final quiz = _quizHistoryForDay(day.date);
        if (quiz == null || quiz.id != sticker.refId) return null;
        return _DiaryRecordStickerViewData(
          id: sticker.storageId,
          kind: _DiaryRecordStickerKind.quiz,
          title: _l10n.diaryStickerQuiz,
          summary: quiz.summary(_l10n),
          metaLabels: [_formatTime(quiz.finishedAt)],
          icon: Icons.quiz_outlined,
          tint: const Color(0xFF5A6FD6),
          quizSummary: quiz,
        );
    }
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
    return day.entries.any((entry) => entry.injury);
  }

  bool _hasConditioningRecord(_DiaryDayData day) {
    return day.entries.any(
      (entry) =>
          entry.liftingByPart.values.any((count) => count > 0) ||
          entry.jumpRopeCount > 0 ||
          entry.jumpRopeMinutes > 0 ||
          entry.jumpRopeNote.trim().isNotEmpty,
    );
  }

  String _trainingSummary(TrainingEntry entry) {
    final cleanNotes = _stripWeatherFromNotes(entry.notes);
    final meta = _trainingMetaParts(entry, includeStatus: false);
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

  List<String> _trainingMetaParts(
    TrainingEntry entry, {
    bool includeStatus = true,
  }) {
    final location = entry.location.trim();
    return <String>[
      location.isEmpty ? (_isKo ? '장소 미기록' : 'No location') : location,
      '${entry.durationMinutes}${_isKo ? '분' : ' min'}',
      if (includeStatus)
        '${_l10n.diaryTrainingStatusLabel} ${_trainingStatusLabel(entry.status)}',
      _isKo ? '컨디션 ${entry.mood}' : 'Condition ${entry.mood}',
      _isKo ? '강도 ${entry.intensity}' : 'Intensity ${entry.intensity}',
    ];
  }

  String _trainingStatusLabel(String status) {
    switch (status) {
      case 'great':
        return _l10n.statusGreat;
      case 'good':
        return _l10n.statusGood;
      case 'tough':
        return _l10n.statusTough;
      case 'recovery':
        return _l10n.statusRecovery;
      case 'normal':
      default:
        return _l10n.statusNormal;
    }
  }

  String _trainingProgramLabel(TrainingEntry entry) {
    final program = entry.program.trim();
    if (program.isEmpty) return '';
    if (program == entry.type.trim()) return '';
    return program;
  }

  List<_DiaryStickerFocusItem> _trainingFocusItems(TrainingEntry entry) {
    final items = <_DiaryStickerFocusItem>[];
    final selectedGoals = entry.goalFocuses
        .map((goal) => goal.trim())
        .where((goal) => goal.isNotEmpty)
        .toList(growable: false);
    final legacyGoal = entry.goal.trim();
    if (selectedGoals.isNotEmpty || legacyGoal.isNotEmpty) {
      items.add(
        _DiaryStickerFocusItem(
          title: _l10n.diaryTrainingSelectedGoalsLabel,
          body:
              selectedGoals.isNotEmpty ? selectedGoals.join(', ') : legacyGoal,
          icon: Icons.track_changes_outlined,
        ),
      );
    }
    if (entry.goodPoints.trim().isNotEmpty) {
      items.add(
        _DiaryStickerFocusItem(
          title: _l10n.diaryTrainingStrongPointLabel,
          body: entry.goodPoints.trim(),
          icon: Icons.thumb_up_alt_outlined,
        ),
      );
    }
    if (entry.improvements.trim().isNotEmpty) {
      items.add(
        _DiaryStickerFocusItem(
          title: _l10n.diaryTrainingNeedsWorkLabel,
          body: entry.improvements.trim(),
          icon: Icons.construction_outlined,
        ),
      );
    }
    if (entry.nextGoal.trim().isNotEmpty) {
      items.add(
        _DiaryStickerFocusItem(
          title: _l10n.diaryTrainingNextGoalLabel,
          body: entry.nextGoal.trim(),
          icon: Icons.flag_outlined,
        ),
      );
    }
    return items;
  }

  List<String> _trainingFocusLines(TrainingEntry entry) {
    final lines = <String>[];
    final selectedGoals = entry.goalFocuses
        .map((goal) => goal.trim())
        .where((goal) => goal.isNotEmpty)
        .toList(growable: false);
    final legacyGoal = entry.goal.trim();
    if (selectedGoals.isNotEmpty || legacyGoal.isNotEmpty) {
      final goalText =
          selectedGoals.isNotEmpty ? selectedGoals.join(', ') : legacyGoal;
      lines.add('${_l10n.diaryTrainingSelectedGoalsLabel}: $goalText');
    }
    return lines;
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

  String _extractWeatherFromNotes(String notes) {
    for (final rawLine in notes.split('\n')) {
      final line = rawLine.trim();
      if (line.startsWith('[Weather]')) {
        return line.replaceFirst('[Weather]', '').trim();
      }
      if (line.startsWith('[날씨]')) {
        return line.replaceFirst('[날씨]', '').trim();
      }
    }
    return '';
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

  String _defaultStoryPrompt(_DiaryDayData day) {
    final seeds = _todoSeedsForDay(day);
    final primarySeed = seeds.isEmpty ? null : seeds.first;
    if (primarySeed != null) {
      return _isKo
          ? '${primarySeed.title}부터 시작해서 오늘 남기고 싶은 장면을 이어 적어 보세요. 해야 했던 일과 실제로 한 일, 기분 변화를 자연스럽게 붙여 써도 좋아요.'
          : 'Start from ${primarySeed.title} and continue with the scene you want to keep today. You can naturally connect what you planned, what you actually did, and how it felt.';
    }
    final focus = _topFocus(day.trainingEntries);
    final place = _topPlaces(day.entries);
    return _isKo
        ? '오늘 $place에서 있었던 일을 내 말로 적어 보세요. $focus 쪽에서 어떤 장면이 가장 오래 남았는지, 무엇이 즐거웠고 무엇이 아쉬웠는지 자유롭게 써도 좋아요.'
        : 'Write today in your own words. Start with what happened around $place, what stayed with you in $focus, what felt good, and what still lingers.';
  }

  List<_DiaryTodoSeed> _todoSeedsForDay(_DiaryDayData day) {
    final seeds = <_DiaryTodoSeed>[
      ...day.plans.map(_planTodoSeed),
      ...day.trainingEntries.map(_trainingTodoSeed),
      ...day.trainingEntries
          .where((entry) => entry.fortuneComment.trim().isNotEmpty)
          .map(_fortuneTodoSeed),
      ...day.matchEntries.map(_matchTodoSeed),
      if (day.mealEntry != null) _mealTodoSeed(day.mealEntry!),
      ...day.boards.map(_boardTodoSeed),
      ..._newsTodoSeedsForDay(day.date),
      if (_weatherTodoSeed(day) case final weatherSeed?) weatherSeed,
      if (_quizHistoryForDay(day.date) case final quiz?) _quizTodoSeed(quiz),
    ];
    if (_hasConditioningRecord(day)) {
      seeds.add(_conditioningTodoSeed(day));
    }
    if (_hasRecoveryRecord(day)) {
      seeds.add(_injuryTodoSeed(day));
    }
    return seeds;
  }

  _DiaryTodoSeed _planTodoSeed(_DiaryPlan plan) {
    final title = '${_formatTime(plan.scheduledAt)} · ${plan.category}';
    final note = plan.note.trim();
    return _DiaryTodoSeed(
      id: 'plan-${plan.id}',
      title: title,
      summary: _isKo
          ? '${plan.durationMinutes}분${note.isEmpty ? '' : ' · $note'}'
          : '${plan.durationMinutes} min${note.isEmpty ? '' : ' · $note'}',
      storySentence: _isKo
          ? '$title 할 일을 먼저 떠올리며, 왜 이걸 오늘 다이어리에 넣고 싶은지 적어 본다.'
          : 'Start from $title and write why this task deserves a place in today diary.',
      sectionTitle: _isKo ? '${plan.category} 메모' : '${plan.category} note',
      sectionBody: _isKo
          ? '${plan.durationMinutes}분 계획${note.isEmpty ? '' : ' - $note'}'
          : '${plan.durationMinutes} min plan${note.isEmpty ? '' : ' - $note'}',
      icon: Icons.event_note_outlined,
      trailingIcon: Icons.push_pin_outlined,
      trailingIconColor: const Color(0xFF2E6ECF),
      trailingIconTooltip: _isKo ? '계획 고정' : 'Pinned plan',
      recordKind: _DiaryRecordStickerKind.plan,
      recordRefId: plan.id,
    );
  }

  _DiaryTodoSeed _trainingTodoSeed(TrainingEntry entry) {
    final label =
        entry.program.trim().isNotEmpty ? entry.program.trim() : entry.type;
    final programEmoji = trainingProgramEmojiFor(label);
    final showProgramEmoji = programEmoji != '⚽';
    final statusEmoji = trainingStatusEmojiFor(entry.status);
    final displayLabel = '${statusEmoji.isNotEmpty ? '$statusEmoji ' : ''}'
        '${showProgramEmoji ? '$programEmoji ' : ''}'
        '$label';
    final summaryText = _trainingSummary(entry);
    final statusVisual = trainingStatusVisual(entry.status);
    return _DiaryTodoSeed(
      id: 'training-${entry.createdAt.millisecondsSinceEpoch}',
      title: _isKo ? '훈련 · $displayLabel' : 'Training · $displayLabel',
      summary: summaryText,
      storySentence: summaryText,
      sectionTitle: _isKo ? '$displayLabel 훈련 요약' : '$displayLabel summary',
      sectionBody: summaryText,
      icon: statusVisual.icon,
      recordKind: _DiaryRecordStickerKind.training,
      recordRefId: '${entry.createdAt.millisecondsSinceEpoch}',
    );
  }

  _DiaryTodoSeed _fortuneTodoSeed(TrainingEntry entry) {
    final fortune = _DiaryFortune.fromEntry(entry);
    final summary = fortune.summaryText.trim();
    final body = summary.isNotEmpty
        ? summary
        : (_isKo
            ? '오늘 기록에 남은 운세 흐름을 다이어리 스티커로 붙여둘 수 있어요.'
            : 'Pin today fortune flow as a diary sticker.');
    return _DiaryTodoSeed(
      id: 'fortune-${entry.createdAt.millisecondsSinceEpoch}',
      title: _l10n.diaryStickerFortune,
      summary: body,
      storySentence: _isKo
          ? '오늘 운세에서 기억하고 싶은 흐름이나 응원 한 줄을 적어 본다.'
          : 'Write the one flow or encouragement you want to keep from today fortune.',
      sectionTitle: _isKo ? '오늘 운세 메모' : 'Today fortune note',
      sectionBody: body,
      icon: Icons.auto_awesome_outlined,
      recordKind: _DiaryRecordStickerKind.fortune,
      recordRefId: '${entry.createdAt.millisecondsSinceEpoch}',
    );
  }

  _DiaryTodoSeed _mealTodoSeed(MealEntry entry) {
    return _DiaryTodoSeed(
      id: 'meal-${_dayStorageToken(entry.date)}',
      title: _l10n.diaryStickerMeal,
      summary: _mealSummary(entry),
      storySentence: _l10n.diaryMealStorySentence,
      sectionTitle: _l10n.diaryMealSectionTitle,
      sectionBody: _l10n.diaryMealSectionBody,
      icon: Icons.rice_bowl_outlined,
      recordKind: _DiaryRecordStickerKind.meal,
      recordRefId: _dayStorageToken(entry.date),
    );
  }

  _DiaryTodoSeed _matchTodoSeed(TrainingEntry entry) {
    final opponent = entry.opponentTeam.trim();
    return _DiaryTodoSeed(
      id: 'match-${entry.createdAt.millisecondsSinceEpoch}',
      title: _isKo
          ? '시합${opponent.isEmpty ? '' : ' · $opponent전'}'
          : 'Match${opponent.isEmpty ? '' : ' · vs $opponent'}',
      summary: _isKo
          ? '${entry.durationMinutes}분 · ${entry.location.trim().isEmpty ? '장소 기록 없음' : entry.location.trim()}'
          : '${entry.durationMinutes} min · ${entry.location.trim().isEmpty ? 'No location' : entry.location.trim()}',
      storySentence: _isKo
          ? '시합 흐름을 한 장면씩 떠올리며 좋았던 선택과 아쉬운 선택을 함께 적어 본다.'
          : 'Replay the match scene by scene and write both the sharp choices and the missed ones.',
      sectionTitle: _isKo ? '시합 흐름' : 'Match flow',
      sectionBody: entry.notes.trim().isNotEmpty
          ? entry.notes.trim()
          : (_isKo
              ? '시합에서 가장 크게 남은 흐름을 적는다.'
              : 'Write the flow that stayed most from the match.'),
      icon: Icons.sports_soccer_outlined,
      recordKind: _DiaryRecordStickerKind.match,
      recordRefId: '${entry.createdAt.millisecondsSinceEpoch}',
    );
  }

  _DiaryTodoSeed _boardTodoSeed(TrainingBoard board) {
    final layout = TrainingMethodLayout.decode(board.layoutJson);
    final boardMemo =
        layout.pages.isNotEmpty ? layout.pages.first.methodText.trim() : '';
    final body = boardMemo.isNotEmpty
        ? (_isKo ? '보드 메모: $boardMemo' : 'Board note: $boardMemo')
        : (_isKo
            ? '이 보드에서 남기고 싶은 움직임과 아이디어를 적는다.'
            : 'Write the movement or idea you want to keep from this board.');
    return _DiaryTodoSeed(
      id: 'board-${board.id}',
      title: _isKo ? '훈련보드 · ${board.title}' : 'Board · ${board.title}',
      summary: boardMemo.isNotEmpty
          ? boardMemo
          : (_isKo
              ? '전술 아이디어를 일기로 옮길 수 있어요.'
              : 'Pull the tactic idea into the diary.'),
      storySentence: body,
      sectionTitle: _isKo ? '${board.title} 메모' : '${board.title} note',
      sectionBody: body,
      icon: Icons.dashboard_customize_outlined,
      recordKind: _DiaryRecordStickerKind.board,
      recordRefId: board.id,
    );
  }

  _DiaryTodoSeed _conditioningTodoSeed(_DiaryDayData day) {
    final dayToken = _dayStorageToken(day.date);
    return _DiaryTodoSeed(
      id: 'conditioning-$dayToken',
      title: _isKo ? '줄넘기와 리프팅' : 'Jump rope and lifting',
      summary: _conditioningSummary(day),
      storySentence: _isKo
          ? '줄넘기와 리프팅을 하면서 몸이 어떻게 풀렸는지부터 적어 본다.'
          : 'Start with how the body opened up during jump rope and lifting.',
      sectionTitle: _isKo ? '몸 풀린 순간' : 'Body wake-up',
      sectionBody: _isKo
          ? '반복 수와 함께 몸이 가벼워진 순간을 남긴다.'
          : 'Keep the moment the body felt lighter together with the counts.',
      icon: Icons.sports_gymnastics_outlined,
      recordKind: _DiaryRecordStickerKind.conditioning,
      recordRefId: dayToken,
    );
  }

  _DiaryTodoSeed? _weatherTodoSeed(_DiaryDayData day) {
    final weather = _weatherSummaryForDay(day).trim();
    if (weather.isEmpty) return null;
    final dayToken = _dayStorageToken(day.date);
    return _DiaryTodoSeed(
      id: 'weather-$dayToken',
      title: _l10n.diaryStickerWeather,
      summary: weather,
      storySentence: _isKo
          ? '그날 날씨가 훈련 흐름과 몸 상태에 어떤 영향을 줬는지 적어 보세요.'
          : 'Write how the weather affected your training flow and body.',
      sectionTitle: _l10n.diaryStickerWeather,
      sectionBody: weather,
      icon: Icons.wb_cloudy_outlined,
      recordKind: _DiaryRecordStickerKind.weather,
      recordRefId: dayToken,
    );
  }

  _DiaryTodoSeed _injuryTodoSeed(_DiaryDayData day) {
    final dayToken = _dayStorageToken(day.date);
    return _DiaryTodoSeed(
      id: 'injury-$dayToken',
      title: _l10n.diaryStickerInjury,
      summary: _injurySummary(day),
      storySentence: _l10n.diaryInjuryStorySentence,
      sectionTitle: _l10n.diaryStickerInjury,
      sectionBody: _injurySummary(day),
      icon: Icons.healing_outlined,
      recordKind: _DiaryRecordStickerKind.injury,
      recordRefId: dayToken,
    );
  }

  _DiaryTodoSeed _quizTodoSeed(_DiaryQuizSummary quiz) {
    return _DiaryTodoSeed(
      id: 'quiz-${quiz.id}',
      title: _l10n.diaryStickerQuiz,
      summary: quiz.summary(_l10n),
      storySentence: _l10n.diaryQuizStorySentence,
      sectionTitle: _l10n.diaryStickerQuiz,
      sectionBody: quiz.summary(_l10n),
      icon: Icons.quiz_outlined,
      recordKind: _DiaryRecordStickerKind.quiz,
      recordRefId: quiz.id,
    );
  }

  String _mealSummary(MealEntry entry) {
    final values = <String>[
      _mealLine(_l10n.mealBreakfast, entry.breakfastRiceBowls),
      _mealLine(_l10n.mealLunch, entry.lunchRiceBowls),
      _mealLine(_l10n.mealDinner, entry.dinnerRiceBowls),
    ];
    return values.join(' · ');
  }

  String _mealLine(String label, double bowls) {
    if (bowls <= 0) return _l10n.mealCompactSkipped(label);
    final count = bowls == bowls.truncateToDouble()
        ? bowls.toStringAsFixed(0)
        : bowls.toStringAsFixed(1);
    return '$label ${_l10n.mealRiceBowlsValue(count)}';
  }

  List<_DiaryTodoSeed> _newsTodoSeedsForDay(DateTime day) {
    const maxNewsSeeds = 6;
    final openedItems = _openedNewsForDay(
      day,
    ).take(maxNewsSeeds).toList(growable: false);
    return openedItems
        .map(
          (item) => _DiaryTodoSeed(
            id: 'news-${item.id}',
            title: _isKo
                ? '소식 · ${item.displayTitle(true)}'
                : 'News · ${item.displayTitle(false)}',
            summary: _isKo
                ? '${item.source.isEmpty ? '출처 없음' : item.source} · ${_formatTime(item.openedAt)}'
                : '${item.source.isEmpty ? 'Unknown source' : item.source} · ${_formatTime(item.openedAt)}',
            storySentence: _isKo
                ? '${item.displayTitle(true)} 기사를 읽고 기억하고 싶은 포인트를 한 줄로 남긴다.'
                : 'Write one point you want to keep from "${item.displayTitle(false)}".',
            sectionTitle: _isKo ? '오늘 본 소식' : 'Today news',
            sectionBody: _isKo
                ? '${item.source.isEmpty ? '출처 없음' : item.source} 기사: ${item.displayTitle(true)}'
                : '${item.source.isEmpty ? 'Unknown source' : item.source} article: ${item.displayTitle(false)}',
            icon: Icons.article_outlined,
            recordKind: _DiaryRecordStickerKind.news,
            recordRefId: item.id,
          ),
        )
        .toList(growable: false);
  }

  List<_DiaryOpenedNewsItem> _openedNewsForDay(DateTime day) {
    final target = _normalizeDay(day);
    final raw = widget.optionRepository.getValue<String>(
      NewsScreen.openedItemsKey,
    );
    if (raw == null || raw.trim().isEmpty) {
      return const <_DiaryOpenedNewsItem>[];
    }
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) return const <_DiaryOpenedNewsItem>[];
      final items = decoded
          .whereType<Map>()
          .map(
            (map) => _DiaryOpenedNewsItem.fromMap(map.cast<String, dynamic>()),
          )
          .where(
            (item) =>
                _normalizeDay(item.openedAt).year == target.year &&
                _normalizeDay(item.openedAt).month == target.month &&
                _normalizeDay(item.openedAt).day == target.day,
          )
          .toList(growable: false);
      final sorted = [...items]
        ..sort((a, b) => b.openedAt.compareTo(a.openedAt));
      return sorted;
    } catch (_) {
      return const <_DiaryOpenedNewsItem>[];
    }
  }

  String _conditioningSummary(_DiaryDayData day) {
    final totalLifting = _totalLiftingCount(day);
    final totalJumpCount = _totalJumpRopeCount(day);
    final totalJumpMinutes = _totalJumpRopeMinutes(day);
    final notes = day.entries
        .map((entry) => entry.jumpRopeNote.trim())
        .where((text) => text.isNotEmpty)
        .toList(growable: false);
    final noteText = notes.isEmpty ? '' : notes.first;
    if (_isKo) {
      return '리프팅 $totalLifting회 · 줄넘기 $totalJumpCount회/$totalJumpMinutes분${noteText.isEmpty ? '' : ' · $noteText'}';
    }
    return 'Lifting $totalLifting reps · Jump rope $totalJumpCount reps/$totalJumpMinutes min${noteText.isEmpty ? '' : ' · $noteText'}';
  }

  String _conditioningJumpRopeSummary(_DiaryDayData day) {
    final totalJumpCount = _totalJumpRopeCount(day);
    final totalJumpMinutes = _totalJumpRopeMinutes(day);
    if (totalJumpCount <= 0 && totalJumpMinutes <= 0) {
      return '';
    }
    if (_isKo) {
      if (totalJumpCount > 0 && totalJumpMinutes > 0) {
        return '줄넘기 $totalJumpCount회/$totalJumpMinutes분';
      }
      if (totalJumpCount > 0) {
        return '줄넘기 $totalJumpCount회';
      }
      return '줄넘기 $totalJumpMinutes분';
    }
    if (totalJumpCount > 0 && totalJumpMinutes > 0) {
      return 'Jump rope $totalJumpCount reps/$totalJumpMinutes min';
    }
    if (totalJumpCount > 0) {
      return 'Jump rope $totalJumpCount reps';
    }
    return 'Jump rope $totalJumpMinutes min';
  }

  List<_DiaryStickerFocusItem> _conditioningFocusItems(_DiaryDayData day) {
    final items = <_DiaryStickerFocusItem>[];
    for (final entry in _liftingBreakdown(day)) {
      items.add(
        _DiaryStickerFocusItem(
          title: '${_l10n.diaryConditioningLiftingLabel} · ${entry.$1}',
          body: _isKo ? '${entry.$2}회' : '${entry.$2} reps',
          icon: Icons.sports_soccer_outlined,
        ),
      );
    }
    return items;
  }

  List<(String, int)> _liftingBreakdown(_DiaryDayData day) {
    const orderedKeys = <String>[
      'infront',
      'inside',
      'outside',
      'muple',
      'head',
      'chest',
    ];
    final totals = <String, int>{};
    for (final entry in day.entries) {
      entry.liftingByPart.forEach((key, value) {
        if (value <= 0) return;
        totals[key] = (totals[key] ?? 0) + value;
      });
    }
    return orderedKeys
        .where((key) => (totals[key] ?? 0) > 0)
        .map((key) => (_liftingPartLabel(key), totals[key] ?? 0))
        .toList(growable: false);
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
      default:
        return _l10n.liftingPartChest;
    }
  }

  String _weatherSummaryForDay(_DiaryDayData day) {
    return day.trainingEntries
        .map((entry) => _extractWeatherFromNotes(entry.notes))
        .firstWhere((weather) => weather.trim().isNotEmpty, orElse: () => '')
        .trim();
  }

  String _injurySummary(_DiaryDayData day) {
    final injuredEntries =
        day.entries.where((entry) => entry.injury).toList(growable: false);
    final injuryParts = injuredEntries
        .map((entry) => entry.injuryPart.trim())
        .where((part) => part.isNotEmpty)
        .toSet()
        .toList(growable: false);
    final notes = injuredEntries
        .map((entry) => _stripWeatherFromNotes(entry.notes))
        .where((note) => note.isNotEmpty)
        .toList(growable: false);
    final maxPainLevel = injuredEntries.fold<int>(
      0,
      (currentMax, entry) => math.max(currentMax, entry.painLevel ?? 0),
    );
    final parts = <String>[
      ...injuryParts,
      if (maxPainLevel > 0) 'P$maxPainLevel',
      if (injuredEntries.any((entry) => entry.rehab)) _l10n.diaryInjuryRehab,
      if (notes.isNotEmpty) notes.first,
    ];
    if (parts.isEmpty) {
      return _l10n.diaryInjuryNoDetails;
    }
    return parts.join(' · ');
  }

  _DiaryQuizSummary? _quizHistoryForDay(DateTime day) {
    final raw = widget.optionRepository.getValue<String>(
      SkillQuizScreen.historyKey,
    );
    if (raw == null || raw.trim().isEmpty) return null;
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) return null;
      final target = _normalizeDay(day);
      final matched = decoded
          .whereType<Map>()
          .map((item) {
            final map = item.cast<String, dynamic>();
            final id = map['id']?.toString() ?? '';
            final finishedAt = DateTime.tryParse(
              map['finishedAt']?.toString() ?? '',
            );
            final totalQuestions =
                (map['totalQuestions'] as num?)?.toInt() ?? 0;
            final score = (map['score'] as num?)?.toInt() ?? 0;
            final wrongQuestions =
                (map['wrongQuestions'] as List?)?.whereType<Object?>().length ??
                    0;
            return _DiaryQuizSummary(
              id: id,
              finishedAt: finishedAt ?? DateTime.fromMillisecondsSinceEpoch(0),
              totalQuestions: totalQuestions,
              score: score,
              wrongQuestions: wrongQuestions,
              questions: ((map['questions'] as List?) ??
                      (map['wrongQuestions'] as List?) ??
                      const <dynamic>[])
                  .whereType<Map>()
                  .map(
                    (item) => _DiaryQuizQuestion.fromMap(
                      item.cast<String, dynamic>(),
                    ),
                  )
                  .whereType<_DiaryQuizQuestion>()
                  .toList(growable: false),
            );
          })
          .where((item) => item.id.isNotEmpty)
          .where((item) => _normalizeDay(item.finishedAt) == target)
          .toList(growable: false)
        ..sort((a, b) => b.finishedAt.compareTo(a.finishedAt));
      return matched.isEmpty ? null : matched.first;
    } catch (_) {
      return null;
    }
  }

  int _totalLiftingCount(_DiaryDayData day) {
    return day.entries.fold<int>(
      0,
      (sum, entry) =>
          sum +
          entry.liftingByPart.values.fold<int>(0, (acc, value) => acc + value),
    );
  }

  int _totalJumpRopeCount(_DiaryDayData day) {
    return day.entries.fold<int>(0, (sum, entry) => sum + entry.jumpRopeCount);
  }

  int _totalJumpRopeMinutes(_DiaryDayData day) {
    return day.entries.fold<int>(
      0,
      (sum, entry) => sum + entry.jumpRopeMinutes,
    );
  }

  Future<void> _openDiaryComposer(
    _DiaryDayData day,
    _CustomDiaryEntryData initialData,
  ) async {
    final previousRecordStickerKinds = initialData.recordStickers.isEmpty
        ? _latestRecordStickerKinds(excludingToken: _dayStorageToken(day.date))
        : initialData.recordStickers.map((sticker) => sticker.kind).toList();
    final todoSeeds = _sortedTodoSeedsForComposer(
      _todoSeedsForDay(day),
      previousRecordStickerKinds,
    );
    String? recordStorageIdFromSeed(_DiaryTodoSeed seed) {
      if (seed.recordKind == null || seed.recordRefId == null) return null;
      return '${seed.recordKind!.name}:${seed.recordRefId!}';
    }

    final titleController = TextEditingController(text: initialData.title);
    final storyController = TextEditingController(text: initialData.story);
    final speech = stt.SpeechToText();
    var speechInitialized = false;
    var speechAvailable = false;
    var listeningSession = 0;
    var isListening = false;
    TextEditingController? listeningController;
    var sessionRecognizedWords = '';
    var sessionCommitted = false;
    var composerActive = true;
    const initialSelectedStickerIds = <String>{};
    final selectableRecordStorageIds =
        todoSeeds.map(recordStorageIdFromSeed).whereType<String>().toSet();
    final seedByRecordStorageId = <String, _DiaryTodoSeed>{
      for (final seed in todoSeeds)
        if (recordStorageIdFromSeed(seed) != null)
          recordStorageIdFromSeed(seed)!: seed,
    };
    final initialSelectedRecordStickerOrder = initialData.recordStickers
        .map((sticker) => sticker.storageId)
        .where(selectableRecordStorageIds.contains)
        .toList(growable: false);
    final selectedRecordStickerOrder = <String>[
      ...initialSelectedRecordStickerOrder,
    ];
    var isClosingFlowRunning = false;
    Timer? autoSaveTimer;
    var autoSaveInFlight = false;
    var autoSaveQueued = false;
    var persistedDraftSignature = '';
    _CustomDiaryEntryData buildDraftData() {
      return _CustomDiaryEntryData(
        title: titleController.text.trim(),
        story: storyController.text.trim(),
        sections: const <_CustomDiarySectionData>[],
        moodId: _DiaryMoodPreset.calmId,
        recordStickers: selectedRecordStickerOrder
            .map((storageId) => seedByRecordStorageId[storageId])
            .whereType<_DiaryTodoSeed>()
            .map(
              (seed) => _DiaryRecordStickerData(
                kind: seed.recordKind!,
                refId: seed.recordRefId!,
              ),
            )
            .toList(growable: false),
        stickers: const <String>[],
        updatedAt: initialData.updatedAt,
      );
    }

    String buildDraftSignature(_CustomDiaryEntryData data) {
      return jsonEncode(<String, dynamic>{
        'title': data.title.trim(),
        'story': data.story.trim(),
        'recordStickers': data.recordStickers
            .map((sticker) => sticker.storageId)
            .toList(growable: false),
        'stickers': [...data.stickers]..sort(),
      });
    }

    Future<void> persistDraftSilently() async {
      if (!composerActive) return;
      if (autoSaveInFlight) {
        autoSaveQueued = true;
        return;
      }
      autoSaveInFlight = true;
      try {
        do {
          autoSaveQueued = false;
          final draft = buildDraftData();
          final nextSignature = buildDraftSignature(draft);
          if (nextSignature == persistedDraftSignature) {
            continue;
          }
          await _saveCustomDiary(day.date, draft, showFeedback: false);
          persistedDraftSignature = nextSignature;
        } while (autoSaveQueued && composerActive);
      } finally {
        autoSaveInFlight = false;
      }
    }

    void scheduleAutoSave() {
      autoSaveTimer?.cancel();
      autoSaveTimer = Timer(
        const Duration(milliseconds: 450),
        () => unawaited(persistDraftSilently()),
      );
    }

    titleController.addListener(scheduleAutoSave);
    storyController.addListener(scheduleAutoSave);
    persistedDraftSignature = buildDraftSignature(buildDraftData());

    List<String> normalizeIds(List<String> values) {
      final ids = [...values]..sort();
      return ids;
    }

    bool hasUnsavedChanges() {
      final draft = buildDraftData();
      return buildDraftSignature(draft) != persistedDraftSignature ||
          normalizeIds(draft.stickers).join('|') !=
              normalizeIds(initialSelectedStickerIds.toList()).join('|');
    }

    Future<void> requestCloseWithSavePrompt(BuildContext modalContext) async {
      if (isClosingFlowRunning) return;
      isClosingFlowRunning = true;
      final navigator = Navigator.of(modalContext);
      if (!hasUnsavedChanges()) {
        if (navigator.canPop()) {
          navigator.pop();
        }
        isClosingFlowRunning = false;
        return;
      }
      final shouldSave = await showDialog<bool>(
        context: modalContext,
        builder: (dialogContext) => AlertDialog(
          title: Text(_isKo ? '저장할까요?' : 'Save changes?'),
          content: Text(
            _isKo
                ? '저장하지 않은 내용이 있어요. 저장 후 닫을까요?'
                : 'You have unsaved changes. Save before closing?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(null),
              child: Text(_isKo ? '취소' : 'Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: Text(_isKo ? '저장 안 함' : "Don't save"),
            ),
            FilledButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: Text(_isKo ? '저장' : 'Save'),
            ),
          ],
        ),
      );
      if (shouldSave == null) {
        isClosingFlowRunning = false;
        return;
      }
      if (shouldSave) {
        // Ensure any ongoing IME composition (notably on Android/Korean input)
        // is committed before reading controller texts.
        FocusManager.instance.primaryFocus?.unfocus();
        await Future.delayed(const Duration(milliseconds: 16));
        if (navigator.canPop()) {
          navigator.pop(buildDraftData());
        }
      } else {
        if (navigator.canPop()) {
          navigator.pop();
        }
      }
      isClosingFlowRunning = false;
    }

    final result = await showModalBottomSheet<_CustomDiaryEntryData>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      useSafeArea: true,
      builder: (context) {
        final bottomInset = MediaQuery.of(context).viewInsets.bottom;
        return StatefulBuilder(
          builder: (context, setModalState) {
            Future<bool> ensureSpeechInitialized() async {
              if (speechInitialized) return speechAvailable;
              speechInitialized = true;
              speechAvailable = await speech.initialize(
                onStatus: (status) {
                  if (!composerActive || !mounted) return;
                  if (!isListening) return;
                  if (status == 'done' || status == 'notListening') {
                    if (listeningController != null &&
                        !sessionCommitted &&
                        sessionRecognizedWords.trim().isNotEmpty) {
                      final recognized = sessionRecognizedWords.trim();
                      final currentText = listeningController!.text;
                      final isKoreanLocale = _isKo;
                      final needsSpacing = !isKoreanLocale &&
                          currentText.isNotEmpty &&
                          !RegExp(r'\s$').hasMatch(currentText);
                      final separator = needsSpacing ? ' ' : '';
                      final nextText =
                          '$currentText$separator${recognized.trim()}';
                      try {
                        listeningController!.value =
                            listeningController!.value.copyWith(
                          text: nextText,
                          selection: TextSelection.collapsed(
                            offset: nextText.length,
                          ),
                          composing: TextRange.empty,
                        );
                      } on FlutterError {
                        // Ignore late callback after field teardown.
                      }
                      sessionCommitted = true;
                    }
                    if (!composerActive) return;
                    setModalState(() {
                      isListening = false;
                      listeningController = null;
                      sessionRecognizedWords = '';
                      sessionCommitted = false;
                    });
                  }
                },
                onError: (_) {
                  if (!composerActive || !mounted) return;
                  setModalState(() {
                    isListening = false;
                    listeningController = null;
                    sessionRecognizedWords = '';
                    sessionCommitted = false;
                  });
                },
              );
              return speechAvailable;
            }

            Future<void> toggleListening(
              TextEditingController controller,
            ) async {
              if (!composerActive || !mounted) return;
              if (isListening) {
                listeningSession++;
                final wasListeningForSameController =
                    listeningController == controller;
                final controllerToCommit = listeningController;
                final recognizedToCommit = sessionRecognizedWords;
                final shouldCommit = !sessionCommitted;
                if (composerActive) {
                  setModalState(() {
                    isListening = false;
                    listeningController = null;
                    sessionRecognizedWords = '';
                    sessionCommitted = false;
                  });
                }
                await speech.cancel();
                if (!composerActive || !mounted) return;
                if (wasListeningForSameController) {
                  if (shouldCommit &&
                      controllerToCommit != null &&
                      recognizedToCommit.trim().isNotEmpty) {
                    final normalized = recognizedToCommit.trim();
                    final currentText = controllerToCommit.text;
                    final needsSpacing = !_isKo &&
                        currentText.isNotEmpty &&
                        !RegExp(r'\s$').hasMatch(currentText);
                    final separator = needsSpacing ? ' ' : '';
                    final nextText = '$currentText$separator$normalized';
                    try {
                      controllerToCommit.value =
                          controllerToCommit.value.copyWith(
                        text: nextText,
                        selection: TextSelection.collapsed(
                          offset: nextText.length,
                        ),
                        composing: TextRange.empty,
                      );
                    } on FlutterError {
                      return;
                    }
                    sessionCommitted = true;
                  }
                  return;
                }
              }

              final available = await ensureSpeechInitialized();
              if (!available) {
                if (!mounted || !context.mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      _isKo
                          ? '이 기기에서는 음성 입력을 사용할 수 없어요.'
                          : 'Voice input is not available on this device.',
                    ),
                  ),
                );
                return;
              }
              final nextSession = ++listeningSession;
              setModalState(() {
                isListening = true;
                listeningController = controller;
                sessionRecognizedWords = '';
                sessionCommitted = false;
              });
              if (!composerActive || !mounted) return;
              final localeId = _isKo ? 'ko_KR' : null;
              await speech.listen(
                localeId: localeId,
                onResult: (result) {
                  if (!composerActive || !mounted) return;
                  if (nextSession != listeningSession) return;
                  final recognized = result.recognizedWords.trim();
                  if (recognized.isEmpty) return;
                  sessionRecognizedWords = recognized;
                },
              );
            }

            Widget buildVoiceField({
              required Key key,
              required TextEditingController controller,
              required String labelText,
              required String hintText,
              TextInputAction? textInputAction,
              int minLines = 1,
              int? maxLines = 1,
              bool alignLabelWithHint = false,
            }) {
              final isListeningForField =
                  isListening && listeningController == controller;
              return TextField(
                key: key,
                controller: controller,
                textInputAction: textInputAction ?? TextInputAction.done,
                onSubmitted: (_) => FocusScope.of(context).unfocus(),
                minLines: minLines,
                maxLines: maxLines,
                decoration: InputDecoration(
                  labelText: labelText,
                  hintText: hintText,
                  alignLabelWithHint: alignLabelWithHint,
                  suffixIcon: IconButton(
                    tooltip: _isKo ? '음성 입력' : 'Voice input',
                    onPressed: () => toggleListening(controller),
                    icon: Icon(
                      isListeningForField ? Icons.mic : Icons.mic_none,
                    ),
                  ),
                ),
              );
            }

            return PopScope(
              canPop: false,
              onPopInvokedWithResult: (didPop, __) {
                if (didPop) return;
                requestCloseWithSavePrompt(context);
              },
              child: Padding(
                padding: EdgeInsets.fromLTRB(16, 0, 16, bottomInset + 16),
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        _isKo ? '오늘의 일기 구성하기' : 'Compose today diary',
                        style: _theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _isKo
                            ? '아래 기록에서 스티커로 붙일 항목을 고르고, 본문은 직접 간단히 작성하세요.'
                            : 'Pick stickers from today records below, and write the story yourself in short.',
                        style: _theme.textTheme.bodyMedium?.copyWith(
                          color: _bodyInk,
                          height: 1.5,
                        ),
                      ),
                      const SizedBox(height: 16),
                      buildVoiceField(
                        key: const ValueKey('diary-title-field'),
                        controller: titleController,
                        textInputAction: TextInputAction.next,
                        labelText: titleController.text.trim().isEmpty
                            ? _l10n.diaryTitlePlaceholder
                            : (_isKo ? '제목' : 'Title'),
                        hintText: titleController.text.trim().isEmpty
                            ? (_isKo
                                ? '예: 비 온 날 끝까지 이어진 패스 감각'
                                : 'Ex: Passing rhythm that lasted through the rain')
                            : '',
                      ),
                      const SizedBox(height: 12),
                      buildVoiceField(
                        key: const ValueKey('diary-story-field'),
                        controller: storyController,
                        minLines: 7,
                        maxLines: 12,
                        labelText: storyController.text.trim().isEmpty
                            ? (_isKo
                                ? '본문을 입력해 주세요'
                                : 'Please enter the body text')
                            : (_isKo ? '본문 시작' : 'Opening body'),
                        hintText: storyController.text.trim().isEmpty
                            ? _defaultStoryPrompt(day)
                            : '',
                        alignLabelWithHint: true,
                      ),
                      if (todoSeeds.isNotEmpty) ...[
                        const SizedBox(height: 18),
                        Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: _tileSurface,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: _paperEdge),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Text(
                                    _l10n.diarySelectedRecordStickersTitle,
                                    style:
                                        _theme.textTheme.labelLarge?.copyWith(
                                      color: _headlineInk,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                  const Spacer(),
                                  Text(
                                    _l10n.diaryRecordStickerSelectedCount(
                                      selectedRecordStickerOrder.length,
                                    ),
                                    style:
                                        _theme.textTheme.labelSmall?.copyWith(
                                      color: _bodyInk,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 10),
                              Text(
                                _l10n.diarySelectedRecordStickersHint,
                                style: _theme.textTheme.bodySmall?.copyWith(
                                  color: _bodyInk,
                                  height: 1.4,
                                ),
                              ),
                              const SizedBox(height: 10),
                              if (selectedRecordStickerOrder.isEmpty)
                                Container(
                                  width: double.infinity,
                                  margin: const EdgeInsets.only(bottom: 10),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 14,
                                  ),
                                  decoration: BoxDecoration(
                                    color: _composerIdleSurface(),
                                    borderRadius: BorderRadius.circular(14),
                                    border: Border.all(
                                      color: _composerIdleBorder().color,
                                    ),
                                  ),
                                  child: Text(
                                    _l10n.diaryRecordStickerEmptyHint,
                                    style: _theme.textTheme.bodySmall?.copyWith(
                                      color: _bodyInk,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                              if (selectedRecordStickerOrder.isNotEmpty)
                                ReorderableListView.builder(
                                  shrinkWrap: true,
                                  buildDefaultDragHandles: false,
                                  physics: const NeverScrollableScrollPhysics(),
                                  itemCount: selectedRecordStickerOrder.length,
                                  onReorder: (oldIndex, newIndex) {
                                    setModalState(() {
                                      if (newIndex > oldIndex) {
                                        newIndex -= 1;
                                      }
                                      final moved = selectedRecordStickerOrder
                                          .removeAt(oldIndex);
                                      selectedRecordStickerOrder.insert(
                                        newIndex,
                                        moved,
                                      );
                                    });
                                    scheduleAutoSave();
                                  },
                                  itemBuilder: (context, index) {
                                    final storageId =
                                        selectedRecordStickerOrder[index];
                                    final seed =
                                        seedByRecordStorageId[storageId];
                                    if (seed == null) {
                                      return const SizedBox.shrink();
                                    }
                                    return Container(
                                      key: ValueKey(
                                        'diary-selected-record-sticker-${seed.id}',
                                      ),
                                      margin: EdgeInsets.only(
                                        bottom: index ==
                                                selectedRecordStickerOrder
                                                        .length -
                                                    1
                                            ? 10
                                            : 8,
                                      ),
                                      padding: const EdgeInsets.fromLTRB(
                                        12,
                                        10,
                                        8,
                                        10,
                                      ),
                                      decoration: BoxDecoration(
                                        color: _recordStickerCardSurface(
                                          _accentInk,
                                        ),
                                        borderRadius: BorderRadius.circular(16),
                                        border: Border.all(
                                          color: _accentInk.withValues(
                                            alpha: _isDark ? 0.34 : 0.2,
                                          ),
                                        ),
                                      ),
                                      child: Row(
                                        children: [
                                          Container(
                                            width: 28,
                                            height: 28,
                                            alignment: Alignment.center,
                                            decoration: BoxDecoration(
                                              color: _accentInk.withValues(
                                                alpha: 0.14,
                                              ),
                                              borderRadius:
                                                  BorderRadius.circular(999),
                                            ),
                                            child: Icon(
                                              seed.icon,
                                              size: 16,
                                              color: _accentInk,
                                            ),
                                          ),
                                          const SizedBox(width: 10),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  seed.title,
                                                  maxLines: seed.recordKind ==
                                                          _DiaryRecordStickerKind
                                                              .news
                                                      ? 2
                                                      : 1,
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                  style: _theme
                                                      .textTheme.labelLarge
                                                      ?.copyWith(
                                                    color: _headlineInk,
                                                    fontWeight: FontWeight.w800,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                          Padding(
                                            padding: const EdgeInsets.only(
                                              right: 4,
                                            ),
                                            child: Text(
                                              '${index + 1}',
                                              style: _theme.textTheme.labelSmall
                                                  ?.copyWith(
                                                color: _accentInk,
                                                fontWeight: FontWeight.w900,
                                              ),
                                            ),
                                          ),
                                          IconButton(
                                            key: ValueKey(
                                              'diary-record-sticker-remove-${seed.id}',
                                            ),
                                            tooltip:
                                                _l10n.diaryRecordStickerRemove,
                                            onPressed: () {
                                              setModalState(() {
                                                selectedRecordStickerOrder
                                                    .remove(storageId);
                                              });
                                              scheduleAutoSave();
                                            },
                                            icon: const Icon(
                                              Icons.close_rounded,
                                            ),
                                          ),
                                          ReorderableDragStartListener(
                                            key: ValueKey(
                                              'diary-record-sticker-drag-${seed.id}',
                                            ),
                                            index: index,
                                            child: Padding(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                horizontal: 8,
                                              ),
                                              child: Icon(
                                                Icons.drag_handle_rounded,
                                                color: _bodyInk,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    );
                                  },
                                ),
                              Text(
                                _l10n.diaryRecordStickerSourceTitle,
                                style: _theme.textTheme.labelLarge?.copyWith(
                                  color: _headlineInk,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              const SizedBox(height: 10),
                              ...todoSeeds.map(
                                (seed) => Builder(
                                  builder: (context) {
                                    final recordStorageId =
                                        recordStorageIdFromSeed(seed);
                                    final isSelected =
                                        recordStorageId != null &&
                                            selectedRecordStickerOrder.contains(
                                              recordStorageId,
                                            );
                                    final orderIndex = recordStorageId == null
                                        ? -1
                                        : selectedRecordStickerOrder.indexOf(
                                            recordStorageId,
                                          );
                                    return Container(
                                      key: ValueKey(
                                        'diary-todo-seed-${seed.id}',
                                      ),
                                      margin: const EdgeInsets.only(bottom: 10),
                                      padding: const EdgeInsets.fromLTRB(
                                        12,
                                        12,
                                        12,
                                        12,
                                      ),
                                      decoration: BoxDecoration(
                                        color: isSelected
                                            ? _accentInk.withValues(alpha: 0.08)
                                            : _composerIdleSurface(),
                                        borderRadius: BorderRadius.circular(16),
                                        border: Border.all(
                                          color: isSelected
                                              ? _accentInk.withValues(
                                                  alpha: 0.28,
                                                )
                                              : _composerIdleBorder().color,
                                        ),
                                      ),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Container(
                                                width: 36,
                                                height: 36,
                                                decoration: BoxDecoration(
                                                  color: _accentInk.withValues(
                                                    alpha: 0.12,
                                                  ),
                                                  borderRadius:
                                                      BorderRadius.circular(12),
                                                ),
                                                child: Icon(
                                                  seed.icon,
                                                  size: 18,
                                                  color: _accentInk,
                                                ),
                                              ),
                                              const SizedBox(width: 10),
                                              Expanded(
                                                child: Row(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,
                                                  children: [
                                                    Expanded(
                                                      child: Column(
                                                        crossAxisAlignment:
                                                            CrossAxisAlignment
                                                                .start,
                                                        children: [
                                                          Text(
                                                            seed.title,
                                                            maxLines: seed
                                                                        .recordKind ==
                                                                    _DiaryRecordStickerKind
                                                                        .news
                                                                ? 2
                                                                : null,
                                                            overflow: seed
                                                                        .recordKind ==
                                                                    _DiaryRecordStickerKind
                                                                        .news
                                                                ? TextOverflow
                                                                    .ellipsis
                                                                : null,
                                                            style: _theme
                                                                .textTheme
                                                                .labelLarge
                                                                ?.copyWith(
                                                              color:
                                                                  _headlineInk,
                                                              fontWeight:
                                                                  FontWeight
                                                                      .w800,
                                                            ),
                                                          ),
                                                          const SizedBox(
                                                            height: 6,
                                                          ),
                                                          Text(
                                                            seed.summary,
                                                            maxLines: seed
                                                                        .recordKind ==
                                                                    _DiaryRecordStickerKind
                                                                        .news
                                                                ? 2
                                                                : null,
                                                            overflow: seed
                                                                        .recordKind ==
                                                                    _DiaryRecordStickerKind
                                                                        .news
                                                                ? TextOverflow
                                                                    .ellipsis
                                                                : null,
                                                            style: _theme
                                                                .textTheme
                                                                .bodySmall
                                                                ?.copyWith(
                                                              color: _bodyInk,
                                                              height: 1.45,
                                                            ),
                                                          ),
                                                        ],
                                                      ),
                                                    ),
                                                    if (seed.trailingIcon !=
                                                        null) ...[
                                                      const SizedBox(width: 8),
                                                      Tooltip(
                                                        message:
                                                            seed.trailingIconTooltip ??
                                                                '',
                                                        child: Container(
                                                          width: 28,
                                                          height: 28,
                                                          decoration:
                                                              BoxDecoration(
                                                            color: (seed.trailingIconColor ??
                                                                    _accentInk)
                                                                .withValues(
                                                              alpha: 0.14,
                                                            ),
                                                            borderRadius:
                                                                BorderRadius
                                                                    .circular(
                                                              999,
                                                            ),
                                                          ),
                                                          child: Icon(
                                                            seed.trailingIcon,
                                                            size: 16,
                                                            color:
                                                                seed.trailingIconColor ??
                                                                    _accentInk,
                                                          ),
                                                        ),
                                                      ),
                                                    ],
                                                  ],
                                                ),
                                              ),
                                            ],
                                          ),
                                          if (recordStorageId != null) ...[
                                            const SizedBox(height: 10),
                                            Row(
                                              children: [
                                                FilterChip(
                                                  key: ValueKey(
                                                    'diary-record-sticker-${seed.id}',
                                                  ),
                                                  label: Text(
                                                    isSelected
                                                        ? _l10n
                                                            .diaryRecordStickerPinned
                                                        : _l10n
                                                            .diaryRecordStickerPin,
                                                  ),
                                                  avatar: Icon(
                                                    isSelected
                                                        ? Icons
                                                            .check_circle_outline
                                                        : Icons
                                                            .push_pin_outlined,
                                                    size: 18,
                                                    color: _accentInk,
                                                  ),
                                                  selected: isSelected,
                                                  backgroundColor:
                                                      _composerIdleSurface(),
                                                  selectedColor: _accentInk
                                                      .withValues(alpha: 0.12),
                                                  side: isSelected
                                                      ? BorderSide(
                                                          color: _accentInk
                                                              .withValues(
                                                            alpha: 0.4,
                                                          ),
                                                        )
                                                      : _composerIdleBorder(),
                                                  onSelected: (selected) {
                                                    setModalState(() {
                                                      if (selected) {
                                                        if (!selectedRecordStickerOrder
                                                            .contains(
                                                          recordStorageId,
                                                        )) {
                                                          selectedRecordStickerOrder
                                                              .add(
                                                            recordStorageId,
                                                          );
                                                        }
                                                      } else {
                                                        selectedRecordStickerOrder
                                                            .remove(
                                                          recordStorageId,
                                                        );
                                                      }
                                                    });
                                                    scheduleAutoSave();
                                                  },
                                                ),
                                                const SizedBox(width: 8),
                                                Visibility(
                                                  visible: isSelected &&
                                                      orderIndex >= 0,
                                                  maintainSize: true,
                                                  maintainState: true,
                                                  maintainAnimation: true,
                                                  child: Text(
                                                    _l10n
                                                        .diaryRecordStickerSelectedOrder(
                                                      orderIndex + 1,
                                                    ),
                                                    style: _theme
                                                        .textTheme.labelSmall
                                                        ?.copyWith(
                                                      color: _accentInk,
                                                      fontWeight:
                                                          FontWeight.w900,
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ],
                                        ],
                                      ),
                                    );
                                  },
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                      const SizedBox(height: 20),
                      LayoutBuilder(
                        builder: (context, constraints) {
                          final saveButtonWidth = math.min(
                            180.0,
                            constraints.maxWidth * 0.45,
                          );
                          return Row(
                            children: [
                              TextButton(
                                onPressed: () async {
                                  final shouldClear = await showDialog<bool>(
                                    context: context,
                                    builder: (dialogContext) => AlertDialog(
                                      title: Text(
                                        _isKo ? '정말 비울까요?' : 'Clear all?',
                                      ),
                                      content: Text(
                                        _isKo
                                            ? '작성한 제목, 본문, 선택한 스티커를 모두 비웁니다.'
                                            : 'This will clear title, story, and selected stickers.',
                                      ),
                                      actions: [
                                        TextButton(
                                          onPressed: () => Navigator.of(
                                            dialogContext,
                                          ).pop(false),
                                          child: Text(_isKo ? '취소' : 'Cancel'),
                                        ),
                                        FilledButton(
                                          onPressed: () => Navigator.of(
                                            dialogContext,
                                          ).pop(true),
                                          child: Text(
                                            _isKo ? '비우기' : 'Clear',
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                  if (shouldClear != true) return;
                                  setModalState(() {
                                    titleController.clear();
                                    storyController.clear();
                                    selectedRecordStickerOrder.clear();
                                  });
                                  scheduleAutoSave();
                                },
                                child: Text(_isKo ? '비우기' : 'Clear'),
                              ),
                              const Spacer(),
                              SizedBox(
                                width: saveButtonWidth,
                                child: FilledButton(
                                  key: const ValueKey('diary-save-button'),
                                  onPressed: () async {
                                    // Commit any unsubmitted composing text from
                                    // the active TextField before saving.
                                    // Without this, some Android IMEs may drop
                                    // the last syllable or treat the entry as
                                    // empty.
                                    final navigator = Navigator.of(context);
                                    FocusManager.instance.primaryFocus
                                        ?.unfocus();
                                    await Future.delayed(
                                      const Duration(milliseconds: 16),
                                    );
                                    if (navigator.canPop()) {
                                      navigator.pop(buildDraftData());
                                    }
                                  },
                                  child: Text(_isKo ? '저장' : 'Save'),
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );

    composerActive = false;
    autoSaveTimer?.cancel();
    if (isListening) {
      await speech.cancel();
    }
    titleController.removeListener(scheduleAutoSave);
    storyController.removeListener(scheduleAutoSave);
    listeningController = null;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      titleController.dispose();
      storyController.dispose();
    });

    if (result == null) return;
    await _saveCustomDiary(day.date, result);
    if (result.hasContent) {
      await _markDiaryCompletedIfNeeded(day.date);
    }
  }

  DateTime _normalizeDay(DateTime value) {
    return DateTime(value.year, value.month, value.day);
  }

  Future<void> _pickDiaryDate(
    List<_DiaryDayData> days,
    int selectedIndex,
  ) async {
    final selectedDay = days[selectedIndex].date;
    final dayMap = <DateTime, _DiaryDayData>{
      for (final day in days) _normalizeDay(day.date): day,
    };
    DateTime focusedDay = selectedDay;
    DateTime? picked;
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
                child: TableCalendar<_DiaryMarkerType>(
                  locale: _isKo ? 'ko_KR' : 'en_US',
                  firstDay: days.last.date,
                  lastDay: days.first.date,
                  focusedDay: focusedDay,
                  calendarFormat: CalendarFormat.month,
                  rowHeight: 42,
                  daysOfWeekHeight: 18,
                  availableGestures: AvailableGestures.horizontalSwipe,
                  startingDayOfWeek: StartingDayOfWeek.sunday,
                  headerStyle: const HeaderStyle(
                    formatButtonVisible: false,
                    titleCentered: true,
                    headerPadding: EdgeInsets.symmetric(vertical: 6),
                    leftChevronPadding: EdgeInsets.zero,
                    rightChevronPadding: EdgeInsets.zero,
                  ),
                  selectedDayPredicate: (day) =>
                      isSameDay(day, selectedDay) ||
                      (picked != null && isSameDay(day, picked)),
                  enabledDayPredicate: (day) =>
                      dayMap.containsKey(_normalizeDay(day)),
                  onDaySelected: (selected, focused) {
                    final normalized = _normalizeDay(selected);
                    if (!dayMap.containsKey(normalized)) return;
                    picked = normalized;
                    Navigator.of(sheetContext).pop();
                  },
                  onPageChanged: (focused) {
                    setSheetState(() => focusedDay = focused);
                  },
                  eventLoader: (day) {
                    final diaryDay = dayMap[_normalizeDay(day)];
                    if (diaryDay == null) return const <_DiaryMarkerType>[];
                    final markers = <_DiaryMarkerType>[];
                    final customDiary = _customDiaryForDay(diaryDay.date);
                    if (customDiary.hasContent) {
                      markers.add(_DiaryMarkerType.diary);
                    }
                    if (diaryDay.trainingEntries.isNotEmpty) {
                      markers.add(_DiaryMarkerType.training);
                    }
                    if (diaryDay.matchEntries.isNotEmpty) {
                      markers.add(_DiaryMarkerType.match);
                    }
                    if (diaryDay.plans.isNotEmpty) {
                      markers.add(_DiaryMarkerType.plan);
                    }
                    if (diaryDay.mealEntry != null) {
                      markers.add(_DiaryMarkerType.meal);
                    }
                    return markers;
                  },
                  calendarBuilders: CalendarBuilders<_DiaryMarkerType>(
                    markerBuilder: (context, day, markers) {
                      if (markers.isEmpty) return const SizedBox.shrink();
                      final markerList = markers
                          .whereType<_DiaryMarkerType>()
                          .toList(growable: false);
                      if (markerList.isEmpty) return const SizedBox.shrink();
                      return Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: markerList
                            .take(4)
                            .map(
                              (marker) => Container(
                                key: ValueKey(
                                  'diary-calendar-marker-${_dayStorageToken(day)}-${marker.name}',
                                ),
                                width: 6,
                                height: 6,
                                margin: const EdgeInsets.symmetric(
                                  horizontal: 1.5,
                                ),
                                decoration: BoxDecoration(
                                  color: marker.color,
                                  shape: BoxShape.circle,
                                ),
                              ),
                            )
                            .toList(growable: false),
                      );
                    },
                  ),
                ),
              ),
            );
          },
        );
      },
    );
    if (picked == null) return;
    final normalized = _normalizeDay(picked!);
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

  List<_DiaryRecordStickerKind> _latestRecordStickerKinds({
    required String excludingToken,
  }) {
    final entries = _customDiaryEntries.entries.toList(growable: false)
      ..sort((a, b) {
        final updatedCompare =
            (b.value.updatedAt ?? DateTime.fromMillisecondsSinceEpoch(0))
                .compareTo(
          a.value.updatedAt ?? DateTime.fromMillisecondsSinceEpoch(0),
        );
        if (updatedCompare != 0) return updatedCompare;
        return b.key.compareTo(a.key);
      });
    for (final entry in entries) {
      if (entry.key == excludingToken) continue;
      if (entry.value.recordStickers.isEmpty) continue;
      final orderedKinds = <_DiaryRecordStickerKind>[];
      for (final sticker in entry.value.recordStickers) {
        if (orderedKinds.contains(sticker.kind)) continue;
        orderedKinds.add(sticker.kind);
      }
      if (orderedKinds.isNotEmpty) {
        return orderedKinds;
      }
    }
    return const <_DiaryRecordStickerKind>[];
  }

  List<_DiaryTodoSeed> _sortedTodoSeedsForComposer(
    List<_DiaryTodoSeed> seeds,
    List<_DiaryRecordStickerKind> previousKinds,
  ) {
    if (previousKinds.isEmpty) return seeds;
    final orderMap = <_DiaryRecordStickerKind, int>{
      for (var index = 0; index < previousKinds.length; index++)
        previousKinds[index]: index,
    };
    final indexedSeeds = seeds.indexed.toList(growable: false)
      ..sort((a, b) {
        final aOrder = a.$2.recordKind == null
            ? 1 << 20
            : (orderMap[a.$2.recordKind!] ?? 1 << 20);
        final bOrder = b.$2.recordKind == null
            ? 1 << 20
            : (orderMap[b.$2.recordKind!] ?? 1 << 20);
        final orderCompare = aOrder.compareTo(bOrder);
        if (orderCompare != 0) return orderCompare;
        return a.$1.compareTo(b.$1);
      });
    return indexedSeeds.map((entry) => entry.$2).toList(growable: false);
  }
}

class _DiaryNotebookBackground extends StatelessWidget {
  final Widget baseBackground;
  final Color paperColor;
  final Color lineColor;
  final Color marginColor;
  final Color holeColor;
  final Widget child;

  const _DiaryNotebookBackground({
    required this.baseBackground,
    required this.paperColor,
    required this.lineColor,
    required this.marginColor,
    required this.holeColor,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        baseBackground,
        CustomPaint(
          painter: _DiaryNotebookBackgroundPainter(
            paperColor: paperColor,
            lineColor: lineColor,
            marginColor: marginColor,
            holeColor: holeColor,
          ),
        ),
        child,
      ],
    );
  }
}

class _DiaryNotebookBackgroundPainter extends CustomPainter {
  final Color paperColor;
  final Color lineColor;
  final Color marginColor;
  final Color holeColor;

  const _DiaryNotebookBackgroundPainter({
    required this.paperColor,
    required this.lineColor,
    required this.marginColor,
    required this.holeColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paperRect = Rect.fromLTWH(0, 0, size.width, size.height);
    final paperPaint = Paint()..color = paperColor.withValues(alpha: 0.88);
    canvas.drawRect(paperRect, paperPaint);

    final linePaint = Paint()
      ..color = lineColor.withValues(alpha: 0.52)
      ..strokeWidth = 1;
    const lineGap = 34.0;
    for (double y = 18; y < size.height; y += lineGap) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), linePaint);
    }

    final marginX = size.width * 0.085;
    final marginPaint = Paint()
      ..color = marginColor.withValues(alpha: 0.74)
      ..strokeWidth = 1.4;
    canvas.drawLine(
      Offset(marginX, 0),
      Offset(marginX, size.height),
      marginPaint,
    );

    final holeFill = Paint()..color = holeColor.withValues(alpha: 0.95);
    final holeStroke = Paint()
      ..color = Colors.black.withValues(alpha: 0.16)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.8;
    const holeRadius = 9.0;
    const holeTop = 72.0;
    const holeGap = 96.0;
    for (double y = holeTop; y < size.height; y += holeGap) {
      final center = Offset(marginX * 0.45, y);
      canvas.drawCircle(center, holeRadius, holeFill);
      canvas.drawCircle(center, holeRadius, holeStroke);
    }
  }

  @override
  bool shouldRepaint(covariant _DiaryNotebookBackgroundPainter oldDelegate) {
    return oldDelegate.paperColor != paperColor ||
        oldDelegate.lineColor != lineColor ||
        oldDelegate.marginColor != marginColor ||
        oldDelegate.holeColor != holeColor;
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

class _DiaryScrollPage extends StatefulWidget {
  final Widget Function(ScrollController controller) childBuilder;
  final VoidCallback onReachedEnd;
  final VoidCallback? onPullDownToDismiss;

  const _DiaryScrollPage({
    required this.childBuilder,
    required this.onReachedEnd,
    this.onPullDownToDismiss,
  });

  @override
  State<_DiaryScrollPage> createState() => _DiaryScrollPageState();
}

class _DiaryScrollPageState extends State<_DiaryScrollPage> {
  final ScrollController _controller = ScrollController();
  bool _didReachEnd = false;
  double _pullDownDistance = 0;
  bool _dismissTriggered = false;

  @override
  void initState() {
    super.initState();
    _controller.addListener(_handleScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) => _checkIfAtEnd());
  }

  @override
  void didUpdateWidget(covariant _DiaryScrollPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    _didReachEnd = false;
    WidgetsBinding.instance.addPostFrameCallback((_) => _checkIfAtEnd());
  }

  @override
  void dispose() {
    _controller
      ..removeListener(_handleScroll)
      ..dispose();
    super.dispose();
  }

  void _handleScroll() {
    _checkIfAtEnd();
  }

  void _checkIfAtEnd() {
    if (!mounted || _didReachEnd) return;
    if (!_controller.hasClients) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _checkIfAtEnd());
      return;
    }
    if (_controller.position.extentAfter > 24) return;
    _didReachEnd = true;
    widget.onReachedEnd();
  }

  @override
  Widget build(BuildContext context) {
    return NotificationListener<ScrollNotification>(
      onNotification: (notification) {
        final onPullDownToDismiss = widget.onPullDownToDismiss;
        if (onPullDownToDismiss == null) return false;
        if (_dismissTriggered) return false;

        final atTop = !_controller.hasClients ||
            _controller.position.pixels <=
                _controller.position.minScrollExtent + 0.5;

        if (notification is ScrollStartNotification) {
          _dismissTriggered = false;
          _pullDownDistance = 0;
        } else if (notification is ScrollUpdateNotification) {
          final dy = notification.dragDetails?.delta.dy ?? 0;
          if (atTop && dy > 0) {
            _pullDownDistance += dy;
          } else if (dy < 0) {
            _pullDownDistance = 0;
          }
        } else if (notification is OverscrollNotification) {
          if (atTop) {
            _pullDownDistance += notification.overscroll.abs();
          }
        } else if (notification is ScrollEndNotification) {
          if (_pullDownDistance >= 86) {
            _dismissTriggered = true;
            onPullDownToDismiss();
          }
          _pullDownDistance = 0;
        }
        return false;
      },
      child: widget.childBuilder(_controller),
    );
  }
}

enum _DiaryMarkerType { diary, training, match, plan, meal }

extension on _DiaryMarkerType {
  Color get color {
    switch (this) {
      case _DiaryMarkerType.diary:
        return const Color(0xFFE46B8A);
      case _DiaryMarkerType.training:
        return const Color(0xFF2F8F6A);
      case _DiaryMarkerType.match:
        return const Color(0xFF2E6ECF);
      case _DiaryMarkerType.plan:
        return const Color(0xFF97754A);
      case _DiaryMarkerType.meal:
        return const Color(0xFFB45309);
    }
  }
}

class _DiaryDayData {
  final DateTime date;
  final List<TrainingEntry> entries;
  final MealEntry? mealEntry;
  final List<_DiaryPlan> plans;
  final List<TrainingBoard> boards;

  const _DiaryDayData({
    required this.date,
    required this.entries,
    required this.mealEntry,
    required this.plans,
    required this.boards,
  });

  List<TrainingEntry> get trainingEntries =>
      entries.where((entry) => !entry.isMatch).toList(growable: false);

  List<TrainingEntry> get matchEntries =>
      entries.where((entry) => entry.isMatch).toList(growable: false);
}

class _CustomDiaryEntryData {
  final String title;
  final String story;
  final List<_CustomDiarySectionData> sections;
  final String moodId;
  final List<_DiaryRecordStickerData> recordStickers;
  final List<String> stickers;
  final DateTime? updatedAt;

  const _CustomDiaryEntryData({
    required this.title,
    required this.story,
    required this.sections,
    required this.moodId,
    required this.recordStickers,
    required this.stickers,
    required this.updatedAt,
  });

  const _CustomDiaryEntryData.empty()
      : title = '',
        story = '',
        sections = const <_CustomDiarySectionData>[],
        moodId = _DiaryMoodPreset.calmId,
        recordStickers = const <_DiaryRecordStickerData>[],
        stickers = const <String>[],
        updatedAt = null;

  bool get hasContent =>
      title.trim().isNotEmpty ||
      story.trim().isNotEmpty ||
      sections.any((section) => section.hasContent) ||
      recordStickers.isNotEmpty ||
      stickers.isNotEmpty;

  _DiaryMoodPreset get mood => _DiaryMoodPreset.fromId(moodId);

  _CustomDiaryEntryData copyWith({
    String? title,
    String? story,
    List<_CustomDiarySectionData>? sections,
    String? moodId,
    List<_DiaryRecordStickerData>? recordStickers,
    List<String>? stickers,
    DateTime? updatedAt,
  }) {
    return _CustomDiaryEntryData(
      title: title ?? this.title,
      story: story ?? this.story,
      sections: sections ?? this.sections,
      moodId: moodId ?? this.moodId,
      recordStickers: recordStickers ?? this.recordStickers,
      stickers: stickers ?? this.stickers,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toMap() => <String, dynamic>{
        'title': title,
        'story': story,
        'sections': sections.map((section) => section.toMap()).toList(),
        'moodId': moodId,
        'recordStickers': recordStickers
            .map((sticker) => sticker.toMap())
            .toList(growable: false),
        'stickers': stickers,
        if (updatedAt != null) 'updatedAt': updatedAt!.toIso8601String(),
      };

  factory _CustomDiaryEntryData.fromMap(Map<String, dynamic> map) {
    final migratedSections = <_CustomDiarySectionData>[
      ...((map['sections'] as List?) ?? const <dynamic>[])
          .whereType<Map>()
          .map(
            (section) => _CustomDiarySectionData.fromMap(
              section.cast<String, dynamic>(),
            ),
          )
          .where((section) => section.hasContent),
    ];
    if (migratedSections.isEmpty) {
      final legacyHighlight = (map['highlight'] as String?) ?? '';
      final legacyGratitude = (map['gratitude'] as String?) ?? '';
      if (legacyHighlight.trim().isNotEmpty) {
        migratedSections.add(
          _CustomDiarySectionData(
            title: '오늘의 하이라이트',
            body: legacyHighlight.trim(),
          ),
        );
      }
      if (legacyGratitude.trim().isNotEmpty) {
        migratedSections.add(
          _CustomDiarySectionData(
            title: '고마운 순간',
            body: legacyGratitude.trim(),
          ),
        );
      }
    }
    return _CustomDiaryEntryData(
      title: (map['title'] as String?) ?? '',
      story: (map['story'] as String?) ?? '',
      sections: migratedSections,
      moodId: (map['moodId'] as String?) ?? _DiaryMoodPreset.calmId,
      recordStickers: ((map['recordStickers'] as List?) ?? const <dynamic>[])
          .whereType<Map>()
          .map(
            (sticker) => _DiaryRecordStickerData.fromMap(
              sticker.cast<String, dynamic>(),
            ),
          )
          .toList(growable: false),
      stickers: (map['stickers'] as List?)
              ?.map((value) => value.toString())
              .where((value) => value.trim().isNotEmpty)
              .toList(growable: false) ??
          const <String>[],
      updatedAt: DateTime.tryParse((map['updatedAt'] as String?) ?? ''),
    );
  }
}

class _CustomDiarySectionData {
  final String title;
  final String body;

  const _CustomDiarySectionData({required this.title, required this.body});

  bool get hasContent => title.trim().isNotEmpty || body.trim().isNotEmpty;

  Map<String, dynamic> toMap() => <String, dynamic>{
        'title': title,
        'body': body,
      };

  factory _CustomDiarySectionData.fromMap(Map<String, dynamic> map) {
    return _CustomDiarySectionData(
      title: (map['title'] as String?) ?? '',
      body: (map['body'] as String?) ?? '',
    );
  }
}

class _DiaryTodoSeed {
  final String id;
  final String title;
  final String summary;
  final String storySentence;
  final String sectionTitle;
  final String sectionBody;
  final IconData icon;
  final IconData? trailingIcon;
  final Color? trailingIconColor;
  final String? trailingIconTooltip;
  final _DiaryRecordStickerKind? recordKind;
  final String? recordRefId;

  const _DiaryTodoSeed({
    required this.id,
    required this.title,
    required this.summary,
    required this.storySentence,
    required this.sectionTitle,
    required this.sectionBody,
    required this.icon,
    this.trailingIcon,
    this.trailingIconColor,
    this.trailingIconTooltip,
    this.recordKind,
    this.recordRefId,
  });
}

class _DiaryOpenedNewsItem {
  final String id;
  final String title;
  final String titleKo;
  final String source;
  final String link;
  final DateTime openedAt;

  const _DiaryOpenedNewsItem({
    required this.id,
    required this.title,
    required this.titleKo,
    required this.source,
    required this.link,
    required this.openedAt,
  });

  String displayTitle(bool isKo) {
    if (isKo && titleKo.trim().isNotEmpty) return titleKo.trim();
    return title.trim();
  }

  factory _DiaryOpenedNewsItem.fromMap(Map<String, dynamic> map) {
    final link = (map['link'] as String?)?.trim() ?? '';
    final id = (map['id'] as String?)?.trim().isNotEmpty == true
        ? (map['id'] as String).trim()
        : Uri.encodeComponent(link);
    return _DiaryOpenedNewsItem(
      id: id,
      title: (map['title'] as String?)?.trim().isNotEmpty == true
          ? (map['title'] as String).trim()
          : (link.isNotEmpty ? link : 'News'),
      titleKo: (map['titleKo'] as String?)?.trim() ?? '',
      source: (map['source'] as String?)?.trim() ?? '',
      link: link,
      openedAt: DateTime.tryParse((map['openedAt'] as String?) ?? '') ??
          DateTime.now(),
    );
  }
}

enum _DiaryRecordStickerKind {
  training,
  match,
  plan,
  fortune,
  board,
  news,
  weather,
  meal,
  conditioning,
  injury,
  quiz,
}

class _DiaryRecordStickerData {
  final _DiaryRecordStickerKind kind;
  final String refId;

  const _DiaryRecordStickerData({required this.kind, required this.refId});

  String get storageId => '${kind.name}:$refId';

  Map<String, dynamic> toMap() => <String, dynamic>{
        'kind': kind.name,
        'refId': refId,
      };

  factory _DiaryRecordStickerData.fromMap(Map<String, dynamic> map) {
    final kindName = (map['kind'] as String?) ?? '';
    final kind = _DiaryRecordStickerKind.values.firstWhere(
      (value) => value.name == kindName,
      orElse: () => _DiaryRecordStickerKind.training,
    );
    return _DiaryRecordStickerData(
      kind: kind,
      refId: (map['refId'] as String?) ?? '',
    );
  }
}

class _DiaryRecordStickerViewData {
  final String id;
  final _DiaryRecordStickerKind kind;
  final String title;
  final String summary;
  final List<String> metaLabels;
  final IconData icon;
  final Color tint;
  final TrainingMethodPage? boardPage;
  final String? link;
  final MealEntry? mealEntry;
  final _DiaryFortune? fortune;
  final List<_DiaryStickerFocusItem> focusItems;
  final _DiaryQuizSummary? quizSummary;

  const _DiaryRecordStickerViewData({
    required this.id,
    required this.kind,
    required this.title,
    required this.summary,
    this.metaLabels = const <String>[],
    required this.icon,
    required this.tint,
    this.boardPage,
    this.link,
    this.mealEntry,
    this.fortune,
    this.focusItems = const <_DiaryStickerFocusItem>[],
    this.quizSummary,
  });
}

class _DiaryStickerFocusItem {
  final String title;
  final String body;
  final IconData icon;

  const _DiaryStickerFocusItem({
    required this.title,
    required this.body,
    required this.icon,
  });
}

class _DiaryQuizSummary {
  final String id;
  final DateTime finishedAt;
  final int totalQuestions;
  final int score;
  final int wrongQuestions;
  final List<_DiaryQuizQuestion> questions;

  const _DiaryQuizSummary({
    required this.id,
    required this.finishedAt,
    required this.totalQuestions,
    required this.score,
    required this.wrongQuestions,
    required this.questions,
  });

  String summary(AppLocalizations l10n) {
    if (wrongQuestions <= 0) {
      return l10n.diaryQuizSummaryPerfect(score, totalQuestions);
    }
    return l10n.diaryQuizSummaryWithMisses(
      score,
      totalQuestions,
      wrongQuestions,
    );
  }
}

class _DiaryQuizQuestion {
  final String promptKo;
  final String promptEn;
  final String answerKo;
  final String answerEn;
  final String wrongAnswerKo;
  final String wrongAnswerEn;

  const _DiaryQuizQuestion({
    required this.promptKo,
    required this.promptEn,
    required this.answerKo,
    required this.answerEn,
    required this.wrongAnswerKo,
    required this.wrongAnswerEn,
  });

  String prompt(bool isKo) => isKo ? promptKo : promptEn;
  String answer(bool isKo) => isKo ? answerKo : answerEn;
  String wrongAnswer(bool isKo) => isKo ? wrongAnswerKo : wrongAnswerEn;
  bool get hasWrongAnswer =>
      wrongAnswerKo.trim().isNotEmpty || wrongAnswerEn.trim().isNotEmpty;

  static _DiaryQuizQuestion? fromMap(Map<String, dynamic> map) {
    final promptKo = map['promptKo']?.toString().trim() ?? '';
    final promptEn = map['promptEn']?.toString().trim() ?? '';
    final answerKo = map['answerKo']?.toString().trim() ?? '';
    final answerEn = map['answerEn']?.toString().trim() ?? '';
    if ((promptKo.isEmpty && promptEn.isEmpty) ||
        (answerKo.isEmpty && answerEn.isEmpty)) {
      return null;
    }
    return _DiaryQuizQuestion(
      promptKo: promptKo,
      promptEn: promptEn,
      answerKo: answerKo,
      answerEn: answerEn,
      wrongAnswerKo: map['wrongAnswerKo']?.toString().trim() ?? '',
      wrongAnswerEn: map['wrongAnswerEn']?.toString().trim() ?? '',
    );
  }
}

class _DiaryMoodPreset {
  static const String calmId = 'calm';

  final String id;
  final String labelKo;
  final String labelEn;
  final IconData icon;
  final Color tint;

  const _DiaryMoodPreset({
    required this.id,
    required this.labelKo,
    required this.labelEn,
    required this.icon,
    required this.tint,
  });

  static const calm = _DiaryMoodPreset(
    id: calmId,
    labelKo: '차분함',
    labelEn: 'Calm',
    icon: Icons.spa_outlined,
    tint: Color(0xFF3F7C63),
  );

  static const proud = _DiaryMoodPreset(
    id: 'proud',
    labelKo: '뿌듯함',
    labelEn: 'Proud',
    icon: Icons.workspace_premium_outlined,
    tint: Color(0xFFCB8B1C),
  );

  static const playful = _DiaryMoodPreset(
    id: 'playful',
    labelKo: '들뜸',
    labelEn: 'Playful',
    icon: Icons.celebration_outlined,
    tint: Color(0xFFD45F78),
  );

  static const focused = _DiaryMoodPreset(
    id: 'focused',
    labelKo: '집중',
    labelEn: 'Focused',
    icon: Icons.track_changes_outlined,
    tint: Color(0xFF2E6ECF),
  );

  static const reflective = _DiaryMoodPreset(
    id: 'reflective',
    labelKo: '회고',
    labelEn: 'Reflective',
    icon: Icons.nights_stay_outlined,
    tint: Color(0xFF6A4FA3),
  );

  static const values = <_DiaryMoodPreset>[
    calm,
    proud,
    playful,
    focused,
    reflective,
  ];

  static _DiaryMoodPreset fromId(String id) {
    return values.firstWhere((value) => value.id == id, orElse: () => calm);
  }
}

class _DiaryStickerPalette {
  static const String customIdPrefix = 'custom:';

  final String id;
  final String labelKo;
  final String labelEn;
  final IconData icon;
  final Color tint;

  const _DiaryStickerPalette({
    required this.id,
    required this.labelKo,
    required this.labelEn,
    required this.icon,
    required this.tint,
  });

  static const star = _DiaryStickerPalette(
    id: 'star',
    labelKo: '반짝',
    labelEn: 'Spark',
    icon: Icons.auto_awesome_outlined,
    tint: Color(0xFFF6B81A),
  );

  static const heart = _DiaryStickerPalette(
    id: 'heart',
    labelKo: '설렘',
    labelEn: 'Heart',
    icon: Icons.favorite_border,
    tint: Color(0xFFE46B8A),
  );

  static const boot = _DiaryStickerPalette(
    id: 'boot',
    labelKo: '풋워크',
    labelEn: 'Footwork',
    icon: Icons.sports_soccer_outlined,
    tint: Color(0xFF2F8F6A),
  );

  static const rain = _DiaryStickerPalette(
    id: 'rain',
    labelKo: '날씨',
    labelEn: 'Weather',
    icon: Icons.umbrella_outlined,
    tint: Color(0xFF4F8FCB),
  );

  static const note = _DiaryStickerPalette(
    id: 'note',
    labelKo: '메모',
    labelEn: 'Memo',
    icon: Icons.sticky_note_2_outlined,
    tint: Color(0xFF97754A),
  );

  static const trophy = _DiaryStickerPalette(
    id: 'trophy',
    labelKo: '성취',
    labelEn: 'Win',
    icon: Icons.emoji_events_outlined,
    tint: Color(0xFFC78A1C),
  );

  static const fire = _DiaryStickerPalette(
    id: 'fire',
    labelKo: '열정',
    labelEn: 'Fire',
    icon: Icons.local_fire_department_outlined,
    tint: Color(0xFFE66C3B),
  );

  static const smile = _DiaryStickerPalette(
    id: 'smile',
    labelKo: '신남',
    labelEn: 'Smile',
    icon: Icons.sentiment_very_satisfied_outlined,
    tint: Color(0xFFF2A81D),
  );

  static const cool = _DiaryStickerPalette(
    id: 'cool',
    labelKo: '자신감',
    labelEn: 'Cool',
    icon: Icons.mood_outlined,
    tint: Color(0xFF3E8FD1),
  );

  static const rocket = _DiaryStickerPalette(
    id: 'rocket',
    labelKo: '상승',
    labelEn: 'Boost',
    icon: Icons.rocket_launch_outlined,
    tint: Color(0xFF8C62D8),
  );

  static const shield = _DiaryStickerPalette(
    id: 'shield',
    labelKo: '든든',
    labelEn: 'Shield',
    icon: Icons.shield_outlined,
    tint: Color(0xFF2E8C74),
  );

  static const clap = _DiaryStickerPalette(
    id: 'clap',
    labelKo: '칭찬',
    labelEn: 'Clap',
    icon: Icons.celebration_outlined,
    tint: Color(0xFFDA5E86),
  );

  static const tired = _DiaryStickerPalette(
    id: 'tired',
    labelKo: '지침',
    labelEn: 'Tired',
    icon: Icons.bedtime_outlined,
    tint: Color(0xFF5F6C8F),
  );

  static const nervous = _DiaryStickerPalette(
    id: 'nervous',
    labelKo: '긴장',
    labelEn: 'Nervous',
    icon: Icons.psychology_alt_outlined,
    tint: Color(0xFF7C6DB2),
  );

  static const sad = _DiaryStickerPalette(
    id: 'sad',
    labelKo: '아쉬움',
    labelEn: 'Low',
    icon: Icons.sentiment_dissatisfied_outlined,
    tint: Color(0xFF5B86A7),
  );

  static const upset = _DiaryStickerPalette(
    id: 'upset',
    labelKo: '답답함',
    labelEn: 'Upset',
    icon: Icons.mood_bad_outlined,
    tint: Color(0xFFB06452),
  );

  static const values = <_DiaryStickerPalette>[
    star,
    heart,
    boot,
    rain,
    note,
    trophy,
    fire,
    smile,
    cool,
    rocket,
    shield,
    clap,
    tired,
    nervous,
    sad,
    upset,
  ];

  static _DiaryStickerPalette? fromId(String id) {
    for (final value in values) {
      if (value.id == id) return value;
    }
    return null;
  }

  static String? customLabelFromId(String id) {
    if (!id.startsWith(customIdPrefix)) return null;
    final encoded = id.substring(customIdPrefix.length);
    final label = Uri.decodeComponent(encoded).trim();
    if (label.isEmpty) return null;
    return label;
  }
}

class _DiaryStickerChipData {
  final String id;
  final String label;
  final IconData icon;
  final Color tint;
  final bool isCustom;

  const _DiaryStickerChipData({
    required this.id,
    required this.label,
    required this.icon,
    required this.tint,
    this.isCustom = false,
  });
}

class _DiaryFortune {
  final DateTime entryDate;
  final List<String> bodyLines;
  final List<String> luckyInfoLines;

  const _DiaryFortune({
    required this.entryDate,
    required this.bodyLines,
    required this.luckyInfoLines,
  });

  String get summaryText {
    final lines = <String>[...bodyLines, ...luckyInfoLines];
    if (lines.isEmpty) return '';
    if (lines.length == 1) return lines.first;
    return '${lines.first} · ${lines[1]}';
  }

  String composeText() {
    final lines = <String>[...bodyLines, ...luckyInfoLines];
    return lines.join('\n');
  }

  factory _DiaryFortune.fromEntry(TrainingEntry entry) {
    final sections = FortuneSections.fromComment(entry.fortuneComment);
    return _DiaryFortune(
      entryDate: entry.date,
      bodyLines: sections.bodyLines,
      luckyInfoLines: sections.luckyInfoLines,
    );
  }
}

// ignore: unused_element
class _GeneratedDiaryFortuneText {
  final List<String> bodyLines;
  final List<String> luckyInfoLines;
  final String recommendation;

  const _GeneratedDiaryFortuneText({
    required this.bodyLines,
    required this.luckyInfoLines,
    required this.recommendation,
  });

  // ignore: unused_element
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
