import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:football_note/gen/app_localizations.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:table_calendar/table_calendar.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../application/backup_service.dart';
import '../../application/family_access_service.dart';
import '../../application/locale_service.dart';
import '../../application/meal_log_service.dart';
import '../../application/news_badge_service.dart';
import '../../application/parent_shared_feedback_service.dart';
import '../../application/player_level_service.dart';
import '../../application/player_profile_service.dart';
import '../../application/settings_service.dart';
import '../../application/sport_capabilities.dart';
import '../../application/sport_scoped_storage.dart';
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
import '../theme/app_theme.dart';
import '../widgets/app_background.dart';
import '../widgets/app_drawer.dart';
import '../widgets/app_feedback.dart';
import '../widgets/app_page_route.dart';
import '../widgets/rice_bowl_summary.dart';
import '../widgets/fortune_card.dart';
import '../widgets/shared_tab_header.dart';
import '../widgets/status_style.dart';
import '../widgets/training_board_sketch.dart';
import 'calendar_screen.dart';
import 'entry_form_screen.dart';
import 'meal_log_screen.dart';
import 'news_screen.dart';
import 'training_method_board_screen.dart';
import 'profile_screen.dart';
import 'settings_screen.dart';
import 'skill_quiz_screen.dart';
import 'notification_center_screen.dart';
import 'weather_detail_screen.dart';

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
  final int dataRevision;

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
    this.dataRevision = 0,
  });

  static String todayViewedDayToken(DateTime date) =>
      '${date.year.toString().padLeft(4, '0')}-'
      '${date.month.toString().padLeft(2, '0')}-'
      '${date.day.toString().padLeft(2, '0')}';

  @override
  State<CoachLessonScreen> createState() => _CoachLessonScreenState();
}

class _CoachLessonScreenState extends State<CoachLessonScreen> {
  static const String _diaryThemeKey = 'diary_theme_v1';
  static const int _diaryTrainingEntryLimit = 500;
  static const String _customDiaryEntriesKey = 'custom_diary_entries_v3';
  static const int _customDiaryPhotoLimit = 6;

  final PageController _pageController = PageController();
  final Set<String> _expandedQuizStickerIds = <String>{};
  int _selectedDayIndex = 0;
  late String _selectedThemeId;
  String? _lastCompletedDiaryToken;
  late Map<String, _CustomDiaryEntryData> _customDiaryEntries;
  int _lastHandledOpenTodayDiaryRequestKey = 0;

  String get _languageCode => Localizations.localeOf(context).languageCode;
  bool get _isKo => _languageCode == 'ko';
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
  String get _plansStorageKey =>
      TrainingPlanReminderService.plansStorageKeyFor(widget.optionRepository);
  String get _diaryThemeStorageKey =>
      sportScopedOptionKey(widget.optionRepository, _diaryThemeKey);
  String get _customDiaryEntriesStorageKey =>
      sportScopedOptionKey(widget.optionRepository, _customDiaryEntriesKey);
  String get _todayViewedDiaryDayStorageKey => sportScopedOptionKey(
        widget.optionRepository,
        CoachLessonScreen.todayViewedDiaryDayKey,
      );
  String get _openedNewsItemsStorageKey =>
      sportScopedOptionKey(widget.optionRepository, NewsScreen.openedItemsKey);

  @override
  void initState() {
    super.initState();
    _selectedThemeId =
        widget.optionRepository.getValue<String>(_diaryThemeStorageKey) ??
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
  void didUpdateWidget(covariant CoachLessonScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.dataRevision == oldWidget.dataRevision) {
      return;
    }
    _selectedThemeId =
        widget.optionRepository.getValue<String>(_diaryThemeStorageKey) ??
            _DiaryThemePalette.notebook.id;
    _customDiaryEntries = _loadCustomDiaryEntries();
  }

  @override
  Widget build(BuildContext context) {
    final isParentMode = _isParentReadOnlyMode;
    final stream = widget.trainingService?.watchRecentEntries(
          limit: _diaryTrainingEntryLimit,
        ) ??
        Stream<List<TrainingEntry>>.value(const <TrainingEntry>[]);
    final mealStream = widget.mealLogService?.watchEntries() ??
        Stream<List<MealEntry>>.value(const <MealEntry>[]);
    final showBack = !widget.embeddedInHomeTab;
    final canOpenDrawer = !showBack &&
        widget.trainingService != null &&
        widget.localeService != null &&
        widget.settingsService != null;
    final profilePhotoSource =
        PlayerProfileService(widget.optionRepository).load().photoUrl;
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
                  final sportId =
                      currentSportIdForOptions(widget.optionRepository);
                  final entries = [
                    ...(snapshot.data ?? const <TrainingEntry>[]),
                  ];
                  final sportEntries = filterEntriesForSport(entries, sportId)
                    ..sort(TrainingEntry.compareByRecentCreated);
                  final sportEntriesByDay = _groupEntriesByDay(sportEntries);
                  final mealEntries = widget.mealLogService?.mergedEntries(
                        directEntries: mealSnapshot.data ?? const <MealEntry>[],
                        legacyEntries: sportEntries,
                      ) ??
                      const <MealEntry>[];
                  final mealEntriesByDay = _groupMealEntriesByDay(mealEntries);
                  final plans = _loadPlans();
                  final plansByDay = _groupPlansByDay(plans);
                  final boardMap = TrainingBoardService(
                    widget.optionRepository,
                  ).boardMap();
                  final days = _buildDays(
                    entriesByDay: sportEntriesByDay,
                    mealEntriesByDay: mealEntriesByDay,
                    plansByDay: plansByDay,
                    boardMap: boardMap,
                  );
                  _consumeTodayDiaryOpenRequest(
                    days: days,
                    entriesByDay: sportEntriesByDay,
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
                              ? null
                              : () => _openNewDiaryComposer(
                                    entriesByDay: sportEntriesByDay,
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
                            leadingTooltip: showBack
                                ? MaterialLocalizations.of(
                                    context,
                                  ).backButtonTooltip
                                : MaterialLocalizations.of(
                                    context,
                                  ).openAppDrawerTooltip,
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
                            title: _l10n.tabDiary,
                            titleTrailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                OutlinedButton.icon(
                                  onPressed: _showThemePicker,
                                  icon: const Icon(
                                    Icons.palette_outlined,
                                    size: 18,
                                  ),
                                  label: Text(_l10n.theme),
                                ),
                                const SizedBox(width: 8),
                                OutlinedButton.icon(
                                  onPressed: isParentMode
                                      ? null
                                      : () => _openNewDiaryComposer(
                                            entriesByDay: sportEntriesByDay,
                                            mealEntriesByDay: mealEntriesByDay,
                                            plansByDay: plansByDay,
                                            boardMap: boardMap,
                                          ),
                                  icon: const Icon(
                                    Icons.add_circle_outline,
                                    size: 18,
                                  ),
                                  label: Text(_l10n.diaryNewAction),
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
    final canGoNewer = selectedIndex > 0;
    final canGoOlder = selectedIndex < dayCount - 1;
    return Container(
      decoration: _paperDecoration(),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
        child: Row(
          children: [
            IconButton(
              tooltip: _l10n.diaryNextDayTooltip,
              onPressed: canGoNewer ? () => _movePage(selectedIndex - 1) : null,
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
              tooltip: _l10n.diaryPreviousDayTooltip,
              onPressed: canGoOlder ? () => _movePage(selectedIndex + 1) : null,
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
                  title: Text(_diaryThemeName(theme)),
                  subtitle: Text(_diaryThemeDescription(theme)),
                  onTap: () => Navigator.of(context).pop(theme.id),
                ),
            ],
          ),
        );
      },
    );
    if (selected == null || selected == _selectedThemeId) return;
    await widget.optionRepository.setValue(_diaryThemeStorageKey, selected);
    if (!mounted) return;
    setState(() => _selectedThemeId = selected);
  }

  String _diaryThemeName(_DiaryThemePalette theme) {
    return switch (theme.id) {
      'dusk' => _l10n.diaryThemeDuskName,
      'ocean' => _l10n.diaryThemeOceanName,
      _ => _l10n.diaryThemeNotebookName,
    };
  }

  String _diaryThemeDescription(_DiaryThemePalette theme) {
    return switch (theme.id) {
      'dusk' => _l10n.diaryThemeDuskDescription,
      'ocean' => _l10n.diaryThemeOceanDescription,
      _ => _l10n.diaryThemeNotebookDescription,
    };
  }

  Future<void> _openProfile() async {
    await Navigator.of(context).push(
      AppPageRoute(
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
      AppPageRoute(
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
      AppPageRoute(
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
      AppPageRoute(
        builder: (_) =>
            SkillQuizScreen(optionRepository: widget.optionRepository),
      ),
    );
  }

  Future<void> _openNotifications() async {
    final settingsService = widget.settingsService;
    if (settingsService == null) return;
    await Navigator.of(context).push(
      AppPageRoute(
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
      _todayViewedDiaryDayStorageKey,
      token,
    );
    await _awardDiaryCreateXp(date);
  }

  Future<void> _awardDiaryCreateXp(DateTime date) async {
    final award = await PlayerLevelService(
      widget.optionRepository,
    ).awardForDiaryCreated(createdAt: date);
    if (!mounted) return;
    final l10n = AppLocalizations.of(context)!;
    final settingsService = widget.settingsService ??
        (SettingsService(widget.optionRepository)..load());
    await TrainingPlanReminderService(
      widget.optionRepository,
      settingsService,
    ).showXpGainAlert(
      gainedXp: award.gainedXp,
      totalXp: award.after.totalXp,
      isKo: _isKo,
      sourceLabel: l10n.trainingXpSourceDiary,
    );
    if (award.didLevelUp) {
      await TrainingPlanReminderService(
        widget.optionRepository,
        settingsService,
      ).showLevelUpAlert(level: award.after.level, isKo: _isKo);
    }
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
                      onPressed: _isParentReadOnlyMode
                          ? null
                          : () => _confirmDeleteDiary(day.date),
                      tooltip: _l10n.delete,
                      foregroundColor: Theme.of(context).colorScheme.error,
                      icon: const Icon(Icons.delete_outline, size: 20),
                    ),
                    const SizedBox(width: 4),
                  ],
                  _buildDiaryActionIconButton(
                    key: ValueKey('diary-edit-${_dayStorageToken(day.date)}'),
                    onPressed: _isParentReadOnlyMode
                        ? null
                        : () => _openDiaryComposer(day, customDiary),
                    tooltip: _l10n.diaryComposeTooltip,
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
    required VoidCallback? onPressed,
    required String tooltip,
    required Widget icon,
    Color? foregroundColor,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    final resolvedColor = onPressed == null
        ? colorScheme.onSurfaceVariant.withValues(alpha: 0.42)
        : foregroundColor ?? colorScheme.onSurfaceVariant;
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: resolvedColor.withValues(
            alpha: onPressed == null ? 0.2 : 0.28,
          ),
        ),
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
          ? _l10n.diaryEmptyHint
          : '${_l10n.diaryLastSavedPrefix} ${_formatShortDateTime(customDiary.updatedAt!)}',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (customDiary.photoDataUrls.isNotEmpty) ...[
            _buildDiaryPhotoGallery(customDiary.photoDataUrls),
            const SizedBox(height: 14),
          ],
          Text(
            customDiary.story.trim().isNotEmpty
                ? customDiary.story.trim()
                : _l10n.diaryStoryPlaceholder,
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
            ...recordStickers.map(
              (sticker) => _buildRecordStickerCard(day, sticker),
            ),
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
                      borderRadius: AppRadius.control,
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

  Widget _buildDiaryPhotoComposer({
    required List<String> photoDataUrls,
    required VoidCallback onAddPhoto,
    required ValueChanged<int> onRemovePhoto,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _tileSurface,
        borderRadius: AppRadius.surface,
        border: Border.all(color: _paperEdge),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  _l10n.photo,
                  style: _theme.textTheme.labelLarge?.copyWith(
                    color: _headlineInk,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              OutlinedButton.icon(
                onPressed: photoDataUrls.length >= _customDiaryPhotoLimit
                    ? null
                    : onAddPhoto,
                icon: const Icon(Icons.add_photo_alternate_outlined, size: 18),
                label: Text(_l10n.addPhoto),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (photoDataUrls.isEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
              decoration: BoxDecoration(
                color: _composerIdleSurface(),
                borderRadius: AppRadius.control,
                border: Border.all(color: _composerIdleBorder().color),
              ),
              child: Text(
                _l10n.noImage,
                style: _theme.textTheme.bodySmall?.copyWith(
                  color: _bodyInk,
                  fontWeight: FontWeight.w700,
                ),
              ),
            )
          else
            LayoutBuilder(
              builder: (context, constraints) {
                final tileSize = math.max(
                  74.0,
                  (constraints.maxWidth - 16) / 3,
                );
                return Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (var index = 0; index < photoDataUrls.length; index++)
                      SizedBox(
                        width: tileSize,
                        height: tileSize,
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            ClipRRect(
                              borderRadius: AppRadius.control,
                              child: _buildDiaryPhotoImage(
                                photoDataUrls[index],
                                label: _l10n.photoIndex(index + 1),
                              ),
                            ),
                            PositionedDirectional(
                              top: 4,
                              end: 4,
                              child: IconButton.filled(
                                onPressed: () => onRemovePhoto(index),
                                tooltip: _l10n.removePhoto,
                                style: IconButton.styleFrom(
                                  fixedSize: const Size.square(32),
                                  minimumSize: const Size.square(32),
                                  padding: EdgeInsets.zero,
                                  tapTargetSize:
                                      MaterialTapTargetSize.shrinkWrap,
                                ),
                                icon: const Icon(Icons.close_rounded, size: 16),
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                );
              },
            ),
        ],
      ),
    );
  }

  Widget _buildDiaryPhotoGallery(List<String> photoDataUrls) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        Widget photoTile(
          int index, {
          double radius = 16,
          BoxFit fit = BoxFit.cover,
        }) {
          return ClipRRect(
            borderRadius: BorderRadius.circular(radius),
            child: _buildDiaryPhotoImage(
              photoDataUrls[index],
              label: _l10n.photoIndex(index + 1),
              fit: fit,
            ),
          );
        }

        if (photoDataUrls.length == 1) {
          return AspectRatio(
            aspectRatio: 4 / 3,
            child: photoTile(0, radius: 18, fit: BoxFit.contain),
          );
        }

        if (photoDataUrls.length == 2) {
          return Row(
            children: [
              for (var index = 0; index < 2; index++) ...[
                Expanded(
                  child: AspectRatio(
                    aspectRatio: 1,
                    child: photoTile(index, radius: 16),
                  ),
                ),
                if (index == 0) const SizedBox(width: 8),
              ],
            ],
          );
        }

        if (photoDataUrls.length == 3) {
          return SizedBox(
            height: (width * 0.68).clamp(220.0, 360.0).toDouble(),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(flex: 3, child: photoTile(0, radius: 18)),
                const SizedBox(width: 8),
                Expanded(
                  flex: 2,
                  child: Column(
                    children: [
                      Expanded(child: photoTile(1, radius: 16)),
                      const SizedBox(height: 8),
                      Expanded(child: photoTile(2, radius: 16)),
                    ],
                  ),
                ),
              ],
            ),
          );
        }

        final tileSize = math.max(72.0, (width - 16) / 3);
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AspectRatio(aspectRatio: 16 / 9, child: photoTile(0, radius: 18)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (var index = 1; index < photoDataUrls.length; index++)
                  SizedBox(
                    width: tileSize,
                    height: tileSize,
                    child: photoTile(index, radius: 14),
                  ),
              ],
            ),
          ],
        );
      },
    );
  }

  Widget _buildDiaryPhotoImage(
    String dataUrl, {
    required String label,
    BoxFit fit = BoxFit.contain,
  }) {
    final bytes = _decodeDiaryPhotoDataUrl(dataUrl);
    if (bytes == null || bytes.isEmpty) {
      return _buildDiaryPhotoFallback();
    }
    return Semantics(
      image: true,
      label: label,
      child: Container(
        color: _composerIdleSurface(),
        alignment: Alignment.center,
        child: Image.memory(
          bytes,
          fit: fit,
          width: double.infinity,
          height: double.infinity,
          errorBuilder: (_, __, ___) => _buildDiaryPhotoFallback(),
        ),
      ),
    );
  }

  Widget _buildDiaryPhotoFallback() {
    return Container(
      alignment: Alignment.center,
      color: _composerIdleSurface(),
      padding: const EdgeInsets.all(12),
      child: Text(
        _l10n.imageLoadFailed,
        textAlign: TextAlign.center,
        style: _theme.textTheme.bodySmall?.copyWith(
          color: _bodyInk,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  Widget _buildRecordStickerCard(
    _DiaryDayData day,
    _DiaryRecordStickerViewData sticker,
  ) {
    final hasBoardPreview = sticker.boardPage != null;
    final isNewsSticker = sticker.kind == _DiaryRecordStickerKind.news;
    final isMealSticker = sticker.kind == _DiaryRecordStickerKind.meal;
    final isFortuneSticker = sticker.kind == _DiaryRecordStickerKind.fortune;
    final isTrainingSticker = sticker.kind == _DiaryRecordStickerKind.training;
    final isQuizSticker = sticker.kind == _DiaryRecordStickerKind.quiz;
    final onTap = _recordStickerTapHandler(day, sticker);
    if (isFortuneSticker && sticker.fortune != null) {
      final fortune = sticker.fortune!;
      return Container(
        key: ValueKey('diary-record-sticker-${sticker.id}'),
        width: double.infinity,
        margin: const EdgeInsets.only(bottom: 10),
        decoration: BoxDecoration(
          color: _recordStickerCardSurface(sticker.tint),
          borderRadius: AppRadius.control,
          border: Border.all(
            color: sticker.tint.withValues(alpha: _isDark ? 0.42 : 0.28),
          ),
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: AppRadius.control,
            onTap: onTap,
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
          ),
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
        borderRadius: AppRadius.control,
        border: Border.all(
          color: sticker.tint.withValues(alpha: _isDark ? 0.42 : 0.28),
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: AppRadius.control,
          onTap: onTap,
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

  Future<void> _openWeatherSticker(_DiaryRecordStickerViewData sticker) async {
    await Navigator.of(context).push(
      AppPageRoute(
        builder: (_) =>
            WeatherDetailScreen(initialSummary: sticker.summary.trim()),
      ),
    );
  }

  VoidCallback? _recordStickerTapHandler(
    _DiaryDayData day,
    _DiaryRecordStickerViewData sticker,
  ) {
    if (sticker.kind == _DiaryRecordStickerKind.news) {
      return () => unawaited(_openNewsSticker(sticker));
    }
    switch (sticker.kind) {
      case _DiaryRecordStickerKind.training:
      case _DiaryRecordStickerKind.parentFeedback:
      case _DiaryRecordStickerKind.match:
      case _DiaryRecordStickerKind.plan:
      case _DiaryRecordStickerKind.fortune:
      case _DiaryRecordStickerKind.board:
      case _DiaryRecordStickerKind.meal:
      case _DiaryRecordStickerKind.conditioning:
      case _DiaryRecordStickerKind.jumpRope:
      case _DiaryRecordStickerKind.lifting:
      case _DiaryRecordStickerKind.injury:
        return () => unawaited(_openEditableRecordSticker(day, sticker));
      case _DiaryRecordStickerKind.news:
        return () => unawaited(_openNewsSticker(sticker));
      case _DiaryRecordStickerKind.weather:
        return () => unawaited(_openWeatherSticker(sticker));
      case _DiaryRecordStickerKind.quiz:
        return () => unawaited(_openQuiz());
    }
  }

  Future<void> _openEditableRecordSticker(
    _DiaryDayData day,
    _DiaryRecordStickerViewData sticker,
  ) async {
    switch (sticker.kind) {
      case _DiaryRecordStickerKind.training:
      case _DiaryRecordStickerKind.parentFeedback:
      case _DiaryRecordStickerKind.fortune:
        final entry = _findTrainingEntryForSticker(day, sticker);
        if (entry != null) {
          await _openTrainingEntryEditor(entry: entry);
          return;
        }
        await _openCalendarEditor(day.date);
        return;
      case _DiaryRecordStickerKind.board:
        final board = _findBoardForSticker(day, sticker);
        if (board == null) return;
        await _openBoardEditor(board);
        return;
      case _DiaryRecordStickerKind.meal:
        final mealEntry = sticker.mealEntry ?? day.mealEntry;
        if (mealEntry == null) return;
        await _openMealEditor(mealEntry.date, entry: mealEntry);
        return;
      case _DiaryRecordStickerKind.match:
      case _DiaryRecordStickerKind.plan:
      case _DiaryRecordStickerKind.conditioning:
      case _DiaryRecordStickerKind.injury:
        await _openCalendarEditor(day.date);
        return;
      case _DiaryRecordStickerKind.jumpRope:
        await _openTrainingEntryEditor(
          entry: _latestTrainingEntryForFocus(
            day,
            EntryFormInitialFocusTarget.jumpRope,
          ),
          initialDate: day.date,
          initialFocusTarget: EntryFormInitialFocusTarget.jumpRope,
        );
        return;
      case _DiaryRecordStickerKind.lifting:
        await _openTrainingEntryEditor(
          entry: _latestTrainingEntryForFocus(
            day,
            EntryFormInitialFocusTarget.lifting,
          ),
          initialDate: day.date,
          initialFocusTarget: EntryFormInitialFocusTarget.lifting,
        );
        return;
      case _DiaryRecordStickerKind.news:
      case _DiaryRecordStickerKind.weather:
      case _DiaryRecordStickerKind.quiz:
        return;
    }
  }

  TrainingEntry? _findTrainingEntryForSticker(
    _DiaryDayData day,
    _DiaryRecordStickerViewData sticker,
  ) {
    final refId = _recordStickerRefId(sticker);
    if (refId == null) return null;
    for (final entry in day.trainingEntries) {
      if ('${entry.createdAt.millisecondsSinceEpoch}' == refId) {
        return entry;
      }
    }
    return null;
  }

  TrainingBoard? _findBoardForSticker(
    _DiaryDayData day,
    _DiaryRecordStickerViewData sticker,
  ) {
    final refId = _recordStickerRefId(sticker);
    if (refId == null) return null;
    for (final board in day.boards) {
      if (board.id == refId) {
        return board;
      }
    }
    return null;
  }

  String? _recordStickerRefId(_DiaryRecordStickerViewData sticker) {
    final separatorIndex = sticker.id.indexOf(':');
    if (separatorIndex <= 0 || separatorIndex >= sticker.id.length - 1) {
      return null;
    }
    return sticker.id.substring(separatorIndex + 1);
  }

  Future<void> _openTrainingEntryEditor({
    TrainingEntry? entry,
    DateTime? initialDate,
    EntryFormInitialFocusTarget? initialFocusTarget,
  }) async {
    final trainingService = widget.trainingService;
    final localeService = widget.localeService;
    final settingsService = widget.settingsService;
    if (trainingService == null ||
        localeService == null ||
        settingsService == null) {
      return;
    }
    await Navigator.of(context).push(
      AppPageRoute(
        builder: (_) => EntryFormScreen(
          trainingService: trainingService,
          optionRepository: widget.optionRepository,
          localeService: localeService,
          settingsService: settingsService,
          driveBackupService: widget.driveBackupService,
          entry: entry,
          initialDate: initialDate,
          initialFocusTarget: initialFocusTarget,
        ),
      ),
    );
  }

  TrainingEntry? _latestTrainingEntryForFocus(
    _DiaryDayData day,
    EntryFormInitialFocusTarget target,
  ) {
    for (final entry in day.trainingEntries.reversed) {
      if (_entryMatchesFocusTarget(entry, target)) {
        return entry;
      }
    }
    if (day.trainingEntries.isEmpty) {
      return null;
    }
    return day.trainingEntries.last;
  }

  bool _entryMatchesFocusTarget(
    TrainingEntry entry,
    EntryFormInitialFocusTarget target,
  ) {
    return switch (target) {
      EntryFormInitialFocusTarget.lifting => entry.liftingByPart.values.any(
          (count) => count > 0,
        ),
      EntryFormInitialFocusTarget.jumpRope => entry.jumpRopeCount > 0 ||
          entry.jumpRopeMinutes > 0 ||
          entry.jumpRopeNote.trim().isNotEmpty,
    };
  }

  Future<void> _openMealEditor(DateTime initialDate, {MealEntry? entry}) async {
    final mealLogService = widget.mealLogService;
    final settingsService = widget.settingsService;
    if (mealLogService == null || settingsService == null) return;
    await Navigator.of(context).push(
      AppPageRoute(
        builder: (_) => MealLogScreen(
          mealLogService: mealLogService,
          optionRepository: widget.optionRepository,
          settingsService: settingsService,
          initialDate: _normalizeDay(initialDate),
          initialEntry: entry ?? mealLogService.entryForDay(initialDate),
        ),
      ),
    );
  }

  Future<void> _openBoardEditor(TrainingBoard board) async {
    await Navigator.of(context).push(
      AppPageRoute(
        builder: (_) => TrainingMethodBoardScreen(
          boardTitle: board.title,
          initialLayoutJson: board.layoutJson,
          optionRepository: widget.optionRepository,
          initialSelectedBoardIds: [board.id],
          initialBoardId: board.id,
          readOnly: _isParentReadOnlyMode,
        ),
      ),
    );
  }

  Future<void> _openCalendarEditor(DateTime initialDate) async {
    final trainingService = widget.trainingService;
    final mealLogService = widget.mealLogService;
    final localeService = widget.localeService;
    final settingsService = widget.settingsService;
    if (trainingService == null ||
        mealLogService == null ||
        localeService == null ||
        settingsService == null) {
      return;
    }
    var selectedDay = _normalizeDay(initialDate);
    await Navigator.of(context).push(
      AppPageRoute(
        builder: (_) => CalendarScreen(
          trainingService: trainingService,
          mealLogService: mealLogService,
          localeService: localeService,
          optionRepository: widget.optionRepository,
          settingsService: settingsService,
          driveBackupService: widget.driveBackupService,
          initialSelectedDay: selectedDay,
          onEdit: (entry) {
            unawaited(_openTrainingEntryEditor(entry: entry));
          },
          onCreate: () {
            unawaited(_openTrainingEntryEditor(initialDate: selectedDay));
          },
          onCreateMeal: () {
            unawaited(_openMealEditor(selectedDay));
          },
          onSelectedDayChanged: (day) {
            selectedDay = _normalizeDay(day);
          },
        ),
      ),
    );
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

  Color _recordStickerTint(_DiaryRecordStickerKind kind) {
    return switch (kind) {
      _DiaryRecordStickerKind.training => const Color(0xFF2F8F6A),
      _DiaryRecordStickerKind.parentFeedback => const Color(0xFF4F6DB8),
      _DiaryRecordStickerKind.match => const Color(0xFF2E6ECF),
      _DiaryRecordStickerKind.plan => const Color(0xFF97754A),
      _DiaryRecordStickerKind.fortune => const Color(0xFF9B51E0),
      _DiaryRecordStickerKind.board => const Color(0xFF2B8C7E),
      _DiaryRecordStickerKind.news => const Color(0xFF5A6FD6),
      _DiaryRecordStickerKind.weather => const Color(0xFF4E86C8),
      _DiaryRecordStickerKind.meal => const Color(0xFFB45309),
      _DiaryRecordStickerKind.conditioning => const Color(0xFF6A9E3F),
      _DiaryRecordStickerKind.jumpRope => const Color(0xFFE66C3B),
      _DiaryRecordStickerKind.lifting => const Color(0xFF1D6FA3),
      _DiaryRecordStickerKind.injury => const Color(0xFFC45D3C),
      _DiaryRecordStickerKind.quiz => const Color(0xFFC058D3),
    };
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

  Widget _buildEmptyCard({required VoidCallback? onCreateDiary}) {
    return _buildPaperCard(
      title: _l10n.diaryEmptyTitle,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _l10n.diaryEmptyBody,
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: _bodyInk, height: 1.5),
          ),
          const SizedBox(height: 14),
          FilledButton.icon(
            key: const ValueKey('diary-create-first-button'),
            onPressed: onCreateDiary,
            icon: const Icon(Icons.add_circle_outline),
            label: Text(_l10n.diaryCreateFirstAction),
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
      borderRadius: AppRadius.surface,
      border: Border.all(color: _paperEdge),
      boxShadow: AppShadows.surface(_theme.brightness),
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
      _customDiaryEntriesStorageKey,
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
      _customDiaryEntriesStorageKey,
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
      AppFeedback.showSuccess(context, text: _l10n.diarySavedMessage);
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
        title: Text(_l10n.diaryDeleteDialogTitle),
        content: Text(_l10n.diaryDeleteDialogBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(_l10n.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(_l10n.delete),
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
      _todayViewedDiaryDayStorageKey,
    );
    if (completedToken == dayToken) {
      await widget.optionRepository.setValue(
        _todayViewedDiaryDayStorageKey,
        '',
      );
    }
    await PlayerLevelService(widget.optionRepository).revokeDiaryCreated(date);
    await _persistCustomDiaryEntries();
    if (!mounted) return;
    setState(() {});
    final messenger = ScaffoldMessenger.of(context);
    messenger
      ..clearSnackBars()
      ..showSnackBar(
        SnackBar(
          content: Text(_l10n.diaryDeletedMessage),
          duration: const Duration(seconds: 5),
          action: SnackBarAction(
            label: _l10n.undo,
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
      _todayViewedDiaryDayStorageKey,
      dayToken,
    );
    await PlayerLevelService(
      widget.optionRepository,
    ).awardForDiaryCreated(createdAt: date);
    await _persistCustomDiaryEntries();
    if (!mounted) return;
    setState(() {});
    AppFeedback.showSuccess(context, text: _l10n.diaryDeleteRestoredMessage);
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
    for (final entry in _customDiaryEntries.entries) {
      final day = DateTime.tryParse(entry.key);
      if (day == null || !entry.value.hasContent) continue;
      markerMap
          .putIfAbsent(_normalizeDay(day), () => <_DiaryMarkerType>{})
          .add(_DiaryMarkerType.diary);
    }

    final picked = await _showDiaryCalendarSheet(
      firstDay: firstDay,
      lastDay: lastDay,
      initialDate: initialDate,
      selectedDay: initialDate,
      eventLoader: (day) {
        return markerMap[_normalizeDay(day)]?.toList(growable: false) ??
            const <_DiaryMarkerType>[];
      },
    );
    if (picked == null) return;
    final normalized = _normalizeDay(picked);
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
    return FamilyAccessService(
      widget.optionRepository,
    ).loadState().isParentMode;
  }

  void _showParentReadOnlyMessage() {
    AppFeedback.showMessage(context, text: _l10n.parentReadOnlyDiaryMessage);
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
        _todayViewedDiaryDayStorageKey,
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
        final primaryLabel = _trainingPrimaryLabel(entry);
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
            if (_trainingProgramDurationSummary(entry).isNotEmpty)
              _trainingProgramDurationSummary(entry)
            else
              _durationText(entry.durationMinutes),
            '${_l10n.diaryTrainingStatusLabel} ${_trainingStatusLabel(entry.status)}',
          ],
          // Match the icon used when recording training status
          icon: trainingStatusVisual(entry.status).icon,
          tint: _recordStickerTint(_DiaryRecordStickerKind.training),
          focusItems: _trainingFocusItems(entry),
        );
      case _DiaryRecordStickerKind.parentFeedback:
        final entry = day.trainingEntries.cast<TrainingEntry?>().firstWhere(
              (item) =>
                  '${item?.createdAt.millisecondsSinceEpoch}' == sticker.refId,
              orElse: () => null,
            );
        if (entry == null) return null;
        final feedback = ParentSharedFeedbackService(
          widget.optionRepository,
        ).feedbackForEntry(entry);
        final message = feedback?.message.trim() ?? '';
        final reaction = feedback?.reaction.trim() ?? '';
        if (message.isEmpty && reaction.isEmpty) return null;
        final summary =
            message.isEmpty ? _l10n.parentFeedbackReactionOnly : message;
        final updatedAt = feedback?.updatedAt;
        final label = _trainingPrimaryLabel(entry);
        return _DiaryRecordStickerViewData(
          id: sticker.storageId,
          kind: _DiaryRecordStickerKind.parentFeedback,
          title: _l10n.diaryStickerParentFeedback,
          summary: summary,
          metaLabels: [
            label,
            if (updatedAt != null) _formatShortDateTime(updatedAt),
          ],
          icon: Icons.rate_review_outlined,
          tint: _recordStickerTint(_DiaryRecordStickerKind.parentFeedback),
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
              : _l10n.diaryMatchOpponentLabel(entry.opponentTeam.trim()),
          summary: _matchSummary(entry),
          metaLabels: [
            if ((entry.minutesPlayed ?? 0) > 0)
              _durationText(entry.minutesPlayed!),
            if (entry.scoredGoals != null && entry.concededGoals != null)
              '${entry.scoredGoals}-${entry.concededGoals}',
            if ((entry.playerGoals ?? 0) > 0 || (entry.playerAssists ?? 0) > 0)
              _l10n.diaryMatchPersonalStats(
                entry.playerGoals ?? 0,
                entry.playerAssists ?? 0,
              ),
          ],
          icon: Icons.sports_soccer_outlined,
          tint: _recordStickerTint(_DiaryRecordStickerKind.match),
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
          summary: _planDetailText(plan, includeTime: true),
          metaLabels: [
            _formatTime(plan.scheduledAt),
            _durationText(plan.durationMinutes),
          ],
          icon: Icons.event_note_outlined,
          tint: _recordStickerTint(_DiaryRecordStickerKind.plan),
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
            '${_l10n.diaryTrainingStatusLabel} ${_trainingStatusLabel(entry.status)}',
          ],
          icon: Icons.auto_awesome_outlined,
          tint: _recordStickerTint(_DiaryRecordStickerKind.fortune),
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
              : _l10n.diaryBoardStickerFallbackSummary,
          metaLabels: [
            if (layout.pages.isNotEmpty &&
                layout.pages.first.name.trim().isNotEmpty)
              layout.pages.first.name.trim(),
            _l10n.diaryUpdatedAt(_formatShortDateTime(board.updatedAt)),
          ],
          icon: Icons.dashboard_customize_outlined,
          tint: _recordStickerTint(_DiaryRecordStickerKind.board),
          boardPage: layout.pages.isNotEmpty ? layout.pages.first : null,
        );
      case _DiaryRecordStickerKind.news:
        final openedNews = _openedNewsForDay(day.date);
        final item = openedNews.cast<_DiaryOpenedNewsItem?>().firstWhere(
              (entry) => entry?.id == sticker.refId,
              orElse: () => null,
            );
        if (item == null) return null;
        final displayTitle = _newsDisplayTitle(item);
        return _DiaryRecordStickerViewData(
          id: sticker.storageId,
          kind: _DiaryRecordStickerKind.news,
          title: displayTitle,
          summary:
              '${_sourceText(item.source)} · ${_formatTime(item.openedAt)}',
          metaLabels: [_sourceText(item.source), _formatTime(item.openedAt)],
          icon: Icons.article_outlined,
          tint: _recordStickerTint(_DiaryRecordStickerKind.news),
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
          tint: _recordStickerTint(_DiaryRecordStickerKind.weather),
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
            _l10n.diaryTotalRiceBowls(
              _compactDecimal(mealEntry.totalRiceBowls),
            ),
            _l10n.diaryCompletedMeals(mealEntry.completedMeals),
          ],
          icon: Icons.rice_bowl_outlined,
          tint: _recordStickerTint(_DiaryRecordStickerKind.meal),
          mealEntry: mealEntry,
        );
      case _DiaryRecordStickerKind.conditioning:
        final dayToken = _dayStorageToken(day.date);
        if (sticker.refId != dayToken) return null;
        return _DiaryRecordStickerViewData(
          id: sticker.storageId,
          kind: _DiaryRecordStickerKind.conditioning,
          title: _l10n.diaryStickerConditioning,
          summary: _conditioningSummary(day),
          metaLabels: [
            if (_totalLiftingCount(day) > 0)
              _l10n.diaryLiftingReps(_totalLiftingCount(day)),
            if (_totalJumpRopeMinutes(day) > 0)
              _durationText(_totalJumpRopeMinutes(day)),
            if (_totalJumpRopeCount(day) > 0)
              _l10n.diaryReps(_totalJumpRopeCount(day)),
          ],
          icon: Icons.sports_gymnastics_outlined,
          tint: _recordStickerTint(_DiaryRecordStickerKind.conditioning),
          focusItems: _liftingFocusItems(day),
        );
      case _DiaryRecordStickerKind.jumpRope:
        final dayToken = _dayStorageToken(day.date);
        if (sticker.refId != dayToken || !_hasJumpRopeRecord(day)) return null;
        return _DiaryRecordStickerViewData(
          id: sticker.storageId,
          kind: _DiaryRecordStickerKind.jumpRope,
          title: _l10n.diaryConditioningJumpRopeLabel,
          summary: _jumpRopeSummary(day),
          metaLabels: [
            if (_totalJumpRopeMinutes(day) > 0)
              _durationText(_totalJumpRopeMinutes(day)),
            if (_totalJumpRopeCount(day) > 0)
              _l10n.diaryReps(_totalJumpRopeCount(day)),
          ],
          icon: Icons.sports_gymnastics_outlined,
          tint: _recordStickerTint(_DiaryRecordStickerKind.jumpRope),
        );
      case _DiaryRecordStickerKind.lifting:
        final dayToken = _dayStorageToken(day.date);
        if (sticker.refId != dayToken || !_hasLiftingRecord(day)) return null;
        return _DiaryRecordStickerViewData(
          id: sticker.storageId,
          kind: _DiaryRecordStickerKind.lifting,
          title: _l10n.diaryConditioningLiftingLabel,
          summary: _liftingSummary(day),
          metaLabels: [_l10n.diaryTotalReps(_totalLiftingCount(day))],
          icon: Icons.sports_soccer_outlined,
          tint: _recordStickerTint(_DiaryRecordStickerKind.lifting),
          focusItems: _liftingFocusItems(day),
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
          tint: _recordStickerTint(_DiaryRecordStickerKind.injury),
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
          tint: _recordStickerTint(_DiaryRecordStickerKind.quiz),
          quizSummary: quiz,
        );
    }
  }

  String _durationText(int minutes) => _l10n.minutes(minutes);

  String _sourceText(String source) {
    final trimmed = source.trim();
    return trimmed.isEmpty ? _l10n.diaryUnknownSource : trimmed;
  }

  String _newsDisplayTitle(_DiaryOpenedNewsItem item) {
    return item.displayTitle(_languageCode == 'ko');
  }

  String _compactDecimal(double value) {
    final digits = value.truncateToDouble() == value ? 0 : 1;
    return value.toStringAsFixed(digits);
  }

  String _planDetailText(_DiaryPlan plan, {required bool includeTime}) {
    final note = plan.note.trim();
    return <String>[
      if (includeTime) _formatTime(plan.scheduledAt),
      _durationText(plan.durationMinutes),
      if (note.isNotEmpty) note,
    ].join(' · ');
  }

  String _planSectionBody(_DiaryPlan plan, {required String note}) {
    return <String>[
      _l10n.diaryPlanDurationLabel(_durationText(plan.durationMinutes)),
      if (note.isNotEmpty) note,
    ].join(' - ');
  }

  String _topFocus(List<TrainingEntry> entries) {
    if (entries.isEmpty) return _l10n.diaryFundamentalsFallback;
    final counts = <String, int>{};
    for (final entry in entries) {
      for (final raw in <String>[
        entry.program,
        ...entry.effectiveTrainingProgramMinutes.keys,
        entry.type,
        ...entry.goalFocuses,
      ]) {
        final text = raw.trim();
        if (text.isEmpty) continue;
        counts[text] = (counts[text] ?? 0) + 1;
      }
    }
    if (counts.isEmpty) return _l10n.diaryFundamentalsFallback;
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
      return _l10n.diaryLocationNotLogged;
    }
    final sorted = counts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return sorted.take(2).map((entry) => entry.key).join(', ');
  }

  bool _hasRecoveryRecord(_DiaryDayData day) {
    return day.entries.any((entry) => entry.injury);
  }

  bool _hasLiftingRecord(_DiaryDayData day) {
    return day.entries.any(
      (entry) => entry.liftingByPart.values.any((count) => count > 0),
    );
  }

  bool _hasJumpRopeRecord(_DiaryDayData day) {
    return day.entries.any(
      (entry) =>
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
    final programDuration = _trainingProgramDurationSummary(entry);
    return <String>[
      location.isEmpty ? _l10n.diaryLocationUnset : location,
      programDuration.isEmpty
          ? _durationText(entry.durationMinutes)
          : programDuration,
      if (includeStatus)
        '${_l10n.diaryTrainingStatusLabel} ${_trainingStatusLabel(entry.status)}',
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
    final programs = entry.effectiveTrainingProgramMinutes.keys
        .map((program) => program.trim())
        .where((program) => program.isNotEmpty && program != entry.type.trim())
        .toList(growable: false);
    if (programs.isNotEmpty) return programs.join(', ');
    final program = entry.program.trim();
    if (program.isEmpty || program == entry.type.trim()) return '';
    return program;
  }

  String _trainingPrimaryLabel(TrainingEntry entry) {
    final label = _trainingProgramLabel(entry);
    if (label.isNotEmpty) return label;
    final type = entry.type.trim();
    return type.isEmpty ? _l10n.diaryStickerTraining : type;
  }

  String _trainingProgramDurationSummary(TrainingEntry entry) {
    final programs = entry.effectiveTrainingProgramMinutes;
    if (programs.isEmpty) return '';
    return programs.entries
        .map((program) => '${program.key} ${_durationText(program.value)}')
        .join(' · ');
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
      entry.opponentTeam.isEmpty
          ? _l10n.diaryMatchOpponentUnknown
          : _l10n.diaryMatchOpponentLabel(entry.opponentTeam),
      if (entry.scoredGoals != null || entry.concededGoals != null)
        _l10n.diaryMatchScoreLabel(
          '${entry.scoredGoals ?? 0}:${entry.concededGoals ?? 0}',
        ),
      if (entry.playerGoals != null)
        _l10n.diaryMatchGoalsLabel(entry.playerGoals!),
      if (entry.playerAssists != null)
        _l10n.diaryMatchAssistsLabel(entry.playerAssists!),
      if (entry.minutesPlayed != null)
        _l10n.diaryMatchMinutesPlayed(_durationText(entry.minutesPlayed!)),
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
      return _l10n.diaryStoryPromptFromSeed(primarySeed.title);
    }
    final focus = _topFocus(day.trainingEntries);
    final place = _topPlaces(day.entries);
    return _l10n.diaryStoryPromptDefault(place, focus);
  }

  List<_DiaryTodoSeed> _todoSeedsForDay(_DiaryDayData day) {
    final seeds = <_DiaryTodoSeed>[
      ...day.plans.map(_planTodoSeed),
      ...day.trainingEntries.map(_trainingTodoSeed),
      ...day.trainingEntries
          .map(_parentFeedbackTodoSeed)
          .whereType<_DiaryTodoSeed>(),
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
    if (_hasLiftingRecord(day)) seeds.add(_liftingTodoSeed(day));
    if (_hasJumpRopeRecord(day)) seeds.add(_jumpRopeTodoSeed(day));
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
      summary: _planDetailText(plan, includeTime: false),
      storySentence: _l10n.diaryPlanStorySentence(title),
      sectionTitle: _l10n.diaryPlanNoteTitle(plan.category),
      sectionBody: _planSectionBody(plan, note: note),
      icon: Icons.event_note_outlined,
      trailingIcon: Icons.push_pin_outlined,
      trailingIconColor: const Color(0xFF2E6ECF),
      trailingIconTooltip: _l10n.diaryPinnedPlanTooltip,
      recordKind: _DiaryRecordStickerKind.plan,
      recordRefId: plan.id,
    );
  }

  _DiaryTodoSeed _trainingTodoSeed(TrainingEntry entry) {
    final label = _trainingPrimaryLabel(entry);
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
      title: _l10n.diaryTrainingTodoTitle(displayLabel),
      summary: summaryText,
      storySentence: summaryText,
      sectionTitle: _l10n.diaryTrainingSummaryTitle(displayLabel),
      sectionBody: summaryText,
      icon: statusVisual.icon,
      recordKind: _DiaryRecordStickerKind.training,
      recordRefId: '${entry.createdAt.millisecondsSinceEpoch}',
    );
  }

  _DiaryTodoSeed? _parentFeedbackTodoSeed(TrainingEntry entry) {
    final feedback = ParentSharedFeedbackService(
      widget.optionRepository,
    ).feedbackForEntry(entry);
    final message = feedback?.message.trim() ?? '';
    final reaction = feedback?.reaction.trim() ?? '';
    if (message.isEmpty && reaction.isEmpty) return null;
    final summary =
        message.isEmpty ? _l10n.parentFeedbackReactionOnly : message;
    final label = _trainingPrimaryLabel(entry);
    return _DiaryTodoSeed(
      id: 'parent-feedback-${entry.createdAt.millisecondsSinceEpoch}',
      title: _l10n.diaryStickerParentFeedback,
      summary: summary,
      storySentence: _l10n.diaryParentFeedbackStorySentence(summary),
      sectionTitle: _isKo
          ? '${_l10n.diaryStickerParentFeedback} · $label'
          : '${_l10n.diaryStickerParentFeedback} · $label',
      sectionBody: summary,
      icon: Icons.rate_review_outlined,
      recordKind: _DiaryRecordStickerKind.parentFeedback,
      recordRefId: '${entry.createdAt.millisecondsSinceEpoch}',
    );
  }

  _DiaryTodoSeed _fortuneTodoSeed(TrainingEntry entry) {
    final fortune = _DiaryFortune.fromEntry(entry);
    final summary = fortune.summaryText.trim();
    final body = summary.isNotEmpty ? summary : _l10n.diaryFortunePinSummary;
    return _DiaryTodoSeed(
      id: 'fortune-${entry.createdAt.millisecondsSinceEpoch}',
      title: _l10n.diaryStickerFortune,
      summary: body,
      storySentence: _l10n.diaryFortuneStorySentence,
      sectionTitle: _l10n.diaryFortuneNoteTitle,
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
      title: opponent.isEmpty
          ? _l10n.diaryMatchTodoTitleNoOpponent
          : _l10n.diaryMatchTodoTitleWithOpponent(opponent),
      summary:
          '${_durationText(entry.durationMinutes)} · ${entry.location.trim().isEmpty ? _l10n.diaryLocationNotLogged : entry.location.trim()}',
      storySentence: _l10n.diaryMatchStorySentence,
      sectionTitle: _l10n.diaryMatchFlowTitle,
      sectionBody: entry.notes.trim().isNotEmpty
          ? entry.notes.trim()
          : _l10n.diaryMatchSectionBodyDefault,
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
        ? _l10n.diaryBoardNotePrefix(boardMemo)
        : _l10n.diaryBoardStorySentence;
    return _DiaryTodoSeed(
      id: 'board-${board.id}',
      title: _l10n.diaryBoardTodoTitle(board.title),
      summary:
          boardMemo.isNotEmpty ? boardMemo : _l10n.diaryBoardFallbackSummary,
      storySentence: body,
      sectionTitle: _l10n.diaryBoardNoteTitle(board.title),
      sectionBody: body,
      icon: Icons.dashboard_customize_outlined,
      recordKind: _DiaryRecordStickerKind.board,
      recordRefId: board.id,
    );
  }

  _DiaryTodoSeed _liftingTodoSeed(_DiaryDayData day) {
    final dayToken = _dayStorageToken(day.date);
    return _DiaryTodoSeed(
      id: 'lifting-$dayToken',
      title: _l10n.diaryConditioningLiftingLabel,
      summary: _liftingSummary(day),
      storySentence: _l10n.diaryLiftingStorySentence,
      sectionTitle: _l10n.diaryLiftingNoteTitle,
      sectionBody: _l10n.diaryLiftingSectionBody,
      icon: Icons.sports_soccer_outlined,
      recordKind: _DiaryRecordStickerKind.lifting,
      recordRefId: dayToken,
    );
  }

  _DiaryTodoSeed _jumpRopeTodoSeed(_DiaryDayData day) {
    final dayToken = _dayStorageToken(day.date);
    return _DiaryTodoSeed(
      id: 'jump-rope-$dayToken',
      title: _l10n.diaryConditioningJumpRopeLabel,
      summary: _jumpRopeSummary(day),
      storySentence: _l10n.diaryJumpRopeStorySentence,
      sectionTitle: _l10n.diaryJumpRopeNoteTitle,
      sectionBody: _l10n.diaryJumpRopeSectionBody,
      icon: Icons.sports_gymnastics_outlined,
      recordKind: _DiaryRecordStickerKind.jumpRope,
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
      storySentence: _l10n.diaryWeatherStorySentence,
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
    return openedItems.map((item) {
      final title = _newsDisplayTitle(item);
      final source = _sourceText(item.source);
      return _DiaryTodoSeed(
        id: 'news-${item.id}',
        title: _l10n.diaryNewsTodoTitle(title),
        summary: '$source · ${_formatTime(item.openedAt)}',
        storySentence: _l10n.diaryNewsStorySentence(title),
        sectionTitle: _l10n.diaryTodayNewsTitle,
        sectionBody: _l10n.diaryNewsSectionBody(source, title),
        icon: Icons.article_outlined,
        recordKind: _DiaryRecordStickerKind.news,
        recordRefId: item.id,
      );
    }).toList(growable: false);
  }

  List<_DiaryOpenedNewsItem> _openedNewsForDay(DateTime day) {
    final target = _normalizeDay(day);
    final raw = widget.optionRepository.getValue<String>(
      _openedNewsItemsStorageKey,
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
    final summary = _l10n.diaryConditioningSummary(
      totalLifting,
      totalJumpCount,
      _durationText(totalJumpMinutes),
    );
    return noteText.isEmpty ? summary : '$summary · $noteText';
  }

  String _conditioningJumpRopeSummary(_DiaryDayData day) {
    final totalJumpCount = _totalJumpRopeCount(day);
    final totalJumpMinutes = _totalJumpRopeMinutes(day);
    if (totalJumpCount <= 0 && totalJumpMinutes <= 0) {
      return '';
    }
    if (totalJumpCount > 0 && totalJumpMinutes > 0) {
      return _l10n.diaryJumpRopeCombined(
        totalJumpCount,
        _durationText(totalJumpMinutes),
      );
    }
    if (totalJumpCount > 0) {
      return _l10n.diaryJumpRopeReps(totalJumpCount);
    }
    return _l10n.diaryJumpRopeMinutes(_durationText(totalJumpMinutes));
  }

  String _jumpRopeSummary(_DiaryDayData day) {
    final base = _conditioningJumpRopeSummary(day);
    final note = _jumpRopeNote(day);
    if (note.isEmpty || base.isEmpty) {
      return base;
    }
    return '$base · $note';
  }

  String _liftingSummary(_DiaryDayData day) {
    final totalLifting = _totalLiftingCount(day);
    return _l10n.diaryLiftingReps(totalLifting);
  }

  String _jumpRopeNote(_DiaryDayData day) {
    return day.entries
        .map((entry) => entry.jumpRopeNote.trim())
        .firstWhere((note) => note.isNotEmpty, orElse: () => '');
  }

  List<_DiaryStickerFocusItem> _liftingFocusItems(_DiaryDayData day) {
    final items = <_DiaryStickerFocusItem>[];
    for (final entry in _liftingBreakdown(day)) {
      items.add(
        _DiaryStickerFocusItem(
          title: '${_l10n.diaryConditioningLiftingLabel} · ${entry.$1}',
          body: _l10n.diaryReps(entry.$2),
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
      SkillQuizScreen.storageKey(
        widget.optionRepository,
        SkillQuizScreen.historyKey,
      ),
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
    if (_isParentReadOnlyMode) {
      _showParentReadOnlyMessage();
      return;
    }
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
    final selectedRecordStickerOrder = initialData.hasContent
        ? <String>[...initialSelectedRecordStickerOrder]
        : todoSeeds
            .map(recordStorageIdFromSeed)
            .whereType<String>()
            .toList(growable: true);
    final photoDataUrls = <String>[...initialData.photoDataUrls];
    final imagePicker = ImagePicker();
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
        photoDataUrls: List<String>.unmodifiable(photoDataUrls),
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
        'photoDataUrls': data.photoDataUrls,
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

    Future<void> addDiaryPhoto(
      BuildContext modalContext,
      StateSetter setModalState,
    ) async {
      if (photoDataUrls.length >= _customDiaryPhotoLimit) {
        AppFeedback.showMessage(
          modalContext,
          text: _l10n.photoLimitReached(_customDiaryPhotoLimit),
        );
        return;
      }
      try {
        final remainingSlots = _customDiaryPhotoLimit - photoDataUrls.length;
        final picked = await imagePicker.pickMultiImage(
          maxWidth: 1600,
          imageQuality: 78,
        );
        if (picked.isEmpty) return;
        final selected = picked.take(remainingSlots).toList(growable: false);
        final dataUrls = <String>[];
        for (final photo in selected) {
          dataUrls.add(await _diaryPhotoDataUrlFromXFile(photo));
        }
        if (!composerActive || !mounted || !modalContext.mounted) return;
        setModalState(() => photoDataUrls.addAll(dataUrls));
        if (picked.length > remainingSlots) {
          AppFeedback.showMessage(
            modalContext,
            text: _l10n.photoLimitReached(_customDiaryPhotoLimit),
          );
        }
        scheduleAutoSave();
      } catch (_) {
        if (!composerActive || !mounted || !modalContext.mounted) return;
        AppFeedback.showMessage(modalContext, text: _l10n.imageLoadFailed);
      }
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
          title: Text(_l10n.diaryComposerSavePromptTitle),
          content: Text(_l10n.diaryComposerSavePromptBody),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(null),
              child: Text(_l10n.cancel),
            ),
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: Text(_l10n.diaryComposerDontSave),
            ),
            FilledButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: Text(_l10n.save),
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
            final availableRecordStickerSeeds = todoSeeds.where((seed) {
              final recordStorageId = recordStorageIdFromSeed(seed);
              return recordStorageId == null ||
                  !selectedRecordStickerOrder.contains(recordStorageId);
            }).toList(growable: false);

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
                  SnackBar(content: Text(_l10n.diaryVoiceInputUnavailable)),
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
              final isMultiline =
                  maxLines == null || maxLines > 1 || minLines > 1;
              final resolvedTextInputAction = textInputAction ??
                  (isMultiline
                      ? TextInputAction.newline
                      : TextInputAction.done);
              return TextField(
                key: key,
                controller: controller,
                keyboardType: isMultiline ? TextInputType.multiline : null,
                textInputAction: resolvedTextInputAction,
                onSubmitted: resolvedTextInputAction == TextInputAction.newline
                    ? null
                    : (_) => FocusScope.of(context).unfocus(),
                minLines: minLines,
                maxLines: maxLines,
                decoration: InputDecoration(
                  labelText: labelText,
                  hintText: hintText,
                  alignLabelWithHint: alignLabelWithHint,
                  suffixIcon: IconButton(
                    tooltip: _l10n.diaryVoiceInputTooltip,
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
                        _l10n.diaryComposerTitle,
                        style: _theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _l10n.diaryComposerDescription,
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
                            : _l10n.diaryTitleLabel,
                        hintText: titleController.text.trim().isEmpty
                            ? _l10n.diaryTitleHint
                            : '',
                      ),
                      const SizedBox(height: 12),
                      buildVoiceField(
                        key: const ValueKey('diary-story-field'),
                        controller: storyController,
                        minLines: 7,
                        maxLines: 12,
                        labelText: _l10n.diaryStoryLabel,
                        hintText: storyController.text.trim().isEmpty
                            ? _defaultStoryPrompt(day)
                            : '',
                        alignLabelWithHint: true,
                      ),
                      const SizedBox(height: 14),
                      _buildDiaryPhotoComposer(
                        photoDataUrls: photoDataUrls,
                        onAddPhoto: () => addDiaryPhoto(context, setModalState),
                        onRemovePhoto: (index) {
                          if (index < 0 || index >= photoDataUrls.length) {
                            return;
                          }
                          setModalState(() => photoDataUrls.removeAt(index));
                          scheduleAutoSave();
                        },
                      ),
                      if (todoSeeds.isNotEmpty) ...[
                        const SizedBox(height: 18),
                        Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: _tileSurface,
                            borderRadius: AppRadius.surface,
                            border: Border.all(color: _paperEdge),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      _l10n.diarySelectedRecordStickersTitle,
                                      style:
                                          _theme.textTheme.labelLarge?.copyWith(
                                        color: _headlineInk,
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                  ),
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
                                        borderRadius: AppRadius.control,
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
                                          if (selectedRecordStickerOrder
                                                  .length >
                                              1)
                                            ReorderableDragStartListener(
                                              key: ValueKey(
                                                'diary-record-sticker-drag-${seed.id}',
                                              ),
                                              index: index,
                                              child: Tooltip(
                                                message: _l10n
                                                    .diaryRecordStickerReorder,
                                                child: Semantics(
                                                  button: true,
                                                  label: _l10n
                                                      .diaryRecordStickerReorder,
                                                  child: Container(
                                                    width: 40,
                                                    height: 40,
                                                    alignment: Alignment.center,
                                                    decoration: BoxDecoration(
                                                      color:
                                                          _accentInk.withValues(
                                                        alpha: 0.10,
                                                      ),
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                        999,
                                                      ),
                                                    ),
                                                    child: Icon(
                                                      Icons.drag_handle_rounded,
                                                      color: _accentInk,
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            ),
                                        ],
                                      ),
                                    );
                                  },
                                ),
                              if (availableRecordStickerSeeds.isNotEmpty) ...[
                                Text(
                                  _l10n.diaryRecordStickerSourceTitle,
                                  style: _theme.textTheme.labelLarge?.copyWith(
                                    color: _headlineInk,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                                const SizedBox(height: 10),
                                ...availableRecordStickerSeeds.map(
                                  (seed) => Builder(
                                    builder: (context) {
                                      final recordStorageId =
                                          recordStorageIdFromSeed(seed);
                                      final isSelected = recordStorageId !=
                                              null &&
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
                                        margin: const EdgeInsets.only(
                                          bottom: 10,
                                        ),
                                        padding: const EdgeInsets.fromLTRB(
                                          12,
                                          12,
                                          12,
                                          12,
                                        ),
                                        decoration: BoxDecoration(
                                          color: isSelected
                                              ? _accentInk.withValues(
                                                  alpha: 0.08,
                                                )
                                              : _composerIdleSurface(),
                                          borderRadius: BorderRadius.circular(
                                            16,
                                          ),
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
                                                    color:
                                                        _accentInk.withValues(
                                                      alpha: 0.12,
                                                    ),
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                      12,
                                                    ),
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
                                                        CrossAxisAlignment
                                                            .start,
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
                                                        const SizedBox(
                                                          width: 8,
                                                        ),
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
                                                              color: seed
                                                                      .trailingIconColor ??
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
                                                    selectedColor:
                                                        _accentInk.withValues(
                                                      alpha: 0.12,
                                                    ),
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
                                      title: Text(_l10n.diaryClearConfirmTitle),
                                      content: Text(
                                        _l10n.diaryClearConfirmBody,
                                      ),
                                      actions: [
                                        TextButton(
                                          onPressed: () => Navigator.of(
                                            dialogContext,
                                          ).pop(false),
                                          child: Text(_l10n.cancel),
                                        ),
                                        FilledButton(
                                          onPressed: () => Navigator.of(
                                            dialogContext,
                                          ).pop(true),
                                          child: Text(_l10n.diaryClearAction),
                                        ),
                                      ],
                                    ),
                                  );
                                  if (shouldClear != true) return;
                                  setModalState(() {
                                    titleController.clear();
                                    storyController.clear();
                                    selectedRecordStickerOrder.clear();
                                    photoDataUrls.clear();
                                  });
                                  scheduleAutoSave();
                                },
                                child: Text(_l10n.diaryClearAction),
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
                                    if (!context.mounted) return;
                                    final draft = buildDraftData();
                                    if (!initialData.hasContent &&
                                        !draft.hasContent) {
                                      AppFeedback.showMessage(
                                        context,
                                        text: _l10n.diarySaveEmptyMessage,
                                      );
                                      return;
                                    }
                                    if (navigator.canPop()) {
                                      navigator.pop(draft);
                                    }
                                  },
                                  child: Text(_l10n.save),
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

  Future<String> _diaryPhotoDataUrlFromXFile(XFile file) async {
    final bytes = await file.readAsBytes();
    if (bytes.isEmpty) {
      throw StateError('empty_diary_photo');
    }
    final mimeType = _diaryPhotoMimeType(file);
    return 'data:$mimeType;base64,${base64Encode(bytes)}';
  }

  String _diaryPhotoMimeType(XFile file) {
    final explicit = file.mimeType?.trim();
    if (explicit != null && explicit.startsWith('image/')) {
      return explicit;
    }
    final lowerName = file.name.toLowerCase();
    if (lowerName.endsWith('.png')) return 'image/png';
    if (lowerName.endsWith('.webp')) return 'image/webp';
    if (lowerName.endsWith('.heic')) return 'image/heic';
    return 'image/jpeg';
  }

  Uint8List? _decodeDiaryPhotoDataUrl(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) return null;
    final commaIndex = trimmed.indexOf(',');
    final encoded =
        commaIndex == -1 ? trimmed : trimmed.substring(commaIndex + 1);
    try {
      return base64Decode(encoded);
    } on FormatException {
      return null;
    }
  }

  DateTime _normalizeDay(DateTime value) {
    return DateTime(value.year, value.month, value.day);
  }

  Future<DateTime?> _showDiaryCalendarSheet({
    required DateTime firstDay,
    required DateTime lastDay,
    required DateTime initialDate,
    required List<_DiaryMarkerType> Function(DateTime day) eventLoader,
    DateTime? selectedDay,
    bool Function(DateTime day)? enabledDayPredicate,
  }) {
    DateTime focusedDay = initialDate;
    return showModalBottomSheet<DateTime>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            final theme = Theme.of(context);
            const calendarDayNumberFontSize = 17.0;
            final dayTextStyle = TextStyle(
              fontSize: calendarDayNumberFontSize,
              fontWeight: FontWeight.w700,
              color: theme.colorScheme.onSurface,
            );
            return SafeArea(
              child: Center(
                heightFactor: 1,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(
                    maxWidth: 420,
                    maxHeight: 430,
                  ),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(14, 0, 14, 16),
                    child: TableCalendar<_DiaryMarkerType>(
                      locale: switch (_languageCode) {
                        'ko' => 'ko_KR',
                        'ja' => 'ja_JP',
                        _ => 'en_US',
                      },
                      firstDay: firstDay,
                      lastDay: lastDay,
                      focusedDay: focusedDay,
                      calendarFormat: CalendarFormat.month,
                      sixWeekMonthsEnforced: false,
                      shouldFillViewport: false,
                      rowHeight: 40,
                      daysOfWeekHeight: 20,
                      availableGestures: AvailableGestures.horizontalSwipe,
                      startingDayOfWeek: StartingDayOfWeek.sunday,
                      headerStyle: const HeaderStyle(
                        formatButtonVisible: false,
                        titleCentered: true,
                        titleTextStyle: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                        ),
                        headerPadding: EdgeInsets.fromLTRB(0, 0, 0, 6),
                        leftChevronPadding: EdgeInsets.zero,
                        rightChevronPadding: EdgeInsets.zero,
                      ),
                      daysOfWeekStyle: DaysOfWeekStyle(
                        weekdayStyle: theme.textTheme.labelMedium?.copyWith(
                              fontWeight: FontWeight.w700,
                            ) ??
                            const TextStyle(fontWeight: FontWeight.w700),
                        weekendStyle: theme.textTheme.labelMedium?.copyWith(
                              fontWeight: FontWeight.w700,
                            ) ??
                            const TextStyle(fontWeight: FontWeight.w700),
                      ),
                      calendarStyle: CalendarStyle(
                        outsideDaysVisible: false,
                        defaultTextStyle: dayTextStyle,
                        weekendTextStyle: dayTextStyle,
                        disabledTextStyle: dayTextStyle.copyWith(
                          color: theme.colorScheme.onSurface.withValues(
                            alpha: 0.28,
                          ),
                        ),
                        todayTextStyle: dayTextStyle.copyWith(
                          color: theme.colorScheme.onPrimary,
                          fontWeight: FontWeight.w900,
                        ),
                        selectedTextStyle: dayTextStyle.copyWith(
                          color: theme.colorScheme.onPrimary,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      selectedDayPredicate: (day) =>
                          selectedDay != null && isSameDay(day, selectedDay),
                      enabledDayPredicate: enabledDayPredicate,
                      onDaySelected: (selected, focused) {
                        final normalized = _normalizeDay(selected);
                        if (enabledDayPredicate != null &&
                            !enabledDayPredicate(normalized)) {
                          return;
                        }
                        Navigator.of(sheetContext).pop(normalized);
                      },
                      onPageChanged: (focused) {
                        setSheetState(() => focusedDay = focused);
                      },
                      eventLoader: eventLoader,
                      calendarBuilders: CalendarBuilders<_DiaryMarkerType>(
                        markerBuilder: (context, day, markers) {
                          if (markers.isEmpty) return const SizedBox.shrink();
                          final markerList = markers
                              .whereType<_DiaryMarkerType>()
                              .toList(growable: false);
                          if (markerList.isEmpty) {
                            return const SizedBox.shrink();
                          }
                          return PositionedDirectional(
                            start: 0,
                            end: 0,
                            bottom: 4,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: markerList
                                  .take(4)
                                  .map(
                                    (marker) => Container(
                                      key: ValueKey(
                                        'diary-calendar-marker-${_dayStorageToken(day)}-${marker.name}',
                                      ),
                                      width: 5,
                                      height: 5,
                                      margin: const EdgeInsets.symmetric(
                                        horizontal: 1.2,
                                      ),
                                      decoration: BoxDecoration(
                                        color: marker.color,
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                  )
                                  .toList(growable: false),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _pickDiaryDate(
    List<_DiaryDayData> days,
    int selectedIndex,
  ) async {
    final selectedDay = days[selectedIndex].date;
    final dayMap = <DateTime, _DiaryDayData>{
      for (final day in days) _normalizeDay(day.date): day,
    };
    final picked = await _showDiaryCalendarSheet(
      firstDay: days.last.date,
      lastDay: days.first.date,
      initialDate: selectedDay,
      selectedDay: selectedDay,
      enabledDayPredicate: (day) => dayMap.containsKey(_normalizeDay(day)),
      eventLoader: (day) {
        final diaryDay = dayMap[_normalizeDay(day)];
        if (diaryDay == null) {
          return const <_DiaryMarkerType>[];
        }
        final customDiary = _customDiaryForDay(diaryDay.date);
        return customDiary.hasContent
            ? const <_DiaryMarkerType>[_DiaryMarkerType.diary]
            : const <_DiaryMarkerType>[];
      },
    );
    if (picked == null) return;
    final normalized = _normalizeDay(picked);
    final targetIndex = days.indexWhere((day) => day.date == normalized);
    if (targetIndex == -1) return;
    setState(() => _selectedDayIndex = targetIndex);
    await _movePage(targetIndex);
  }

  String _formatDiaryDate(DateTime date) {
    final pattern = switch (_languageCode) {
      'ko' => 'M월 d일 EEEE',
      'ja' => 'M月d日 EEEE',
      _ => 'EEE, MMM d',
    };
    return DateFormat(pattern, _l10n.localeName).format(date);
  }

  String _formatTime(DateTime date) {
    final pattern = switch (_languageCode) {
      'ko' => 'a h:mm',
      'ja' => 'H:mm',
      _ => 'h:mm a',
    };
    return DateFormat(pattern, _l10n.localeName).format(date);
  }

  String _formatShortDateTime(DateTime date) {
    final pattern = switch (_languageCode) {
      'ko' || 'ja' => 'M.d HH:mm',
      _ => 'MMM d HH:mm',
    };
    return DateFormat(pattern, _l10n.localeName).format(date);
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
  final List<String> photoDataUrls;
  final DateTime? updatedAt;

  const _CustomDiaryEntryData({
    required this.title,
    required this.story,
    required this.sections,
    required this.moodId,
    required this.recordStickers,
    required this.stickers,
    required this.photoDataUrls,
    required this.updatedAt,
  });

  const _CustomDiaryEntryData.empty()
      : title = '',
        story = '',
        sections = const <_CustomDiarySectionData>[],
        moodId = _DiaryMoodPreset.calmId,
        recordStickers = const <_DiaryRecordStickerData>[],
        stickers = const <String>[],
        photoDataUrls = const <String>[],
        updatedAt = null;

  bool get hasContent =>
      title.trim().isNotEmpty ||
      story.trim().isNotEmpty ||
      sections.any((section) => section.hasContent) ||
      recordStickers.isNotEmpty ||
      stickers.isNotEmpty ||
      photoDataUrls.isNotEmpty;

  _DiaryMoodPreset get mood => _DiaryMoodPreset.fromId(moodId);

  _CustomDiaryEntryData copyWith({
    String? title,
    String? story,
    List<_CustomDiarySectionData>? sections,
    String? moodId,
    List<_DiaryRecordStickerData>? recordStickers,
    List<String>? stickers,
    List<String>? photoDataUrls,
    DateTime? updatedAt,
  }) {
    return _CustomDiaryEntryData(
      title: title ?? this.title,
      story: story ?? this.story,
      sections: sections ?? this.sections,
      moodId: moodId ?? this.moodId,
      recordStickers: recordStickers ?? this.recordStickers,
      stickers: stickers ?? this.stickers,
      photoDataUrls: photoDataUrls ?? this.photoDataUrls,
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
        'photoDataUrls': photoDataUrls,
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
      photoDataUrls: (map['photoDataUrls'] as List?)
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
  jumpRope,
  lifting,
  injury,
  quiz,
  parentFeedback,
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

class _DiaryPlan {
  final String id;
  final DateTime scheduledAt;
  final String category;
  final int durationMinutes;
  final String location;
  final String note;

  const _DiaryPlan({
    required this.id,
    required this.scheduledAt,
    required this.category,
    required this.durationMinutes,
    required this.location,
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
      location: map['location']?.toString() ?? '',
      note: map['note']?.toString() ?? '',
    );
  }
}
