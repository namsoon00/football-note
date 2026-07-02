import 'dart:async';

import 'package:flutter/material.dart';
import 'package:football_note/gen/app_localizations.dart';
import 'package:intl/intl.dart';

import '../../application/club_schedule_service.dart';
import '../../application/club_training_reminder_service.dart';
import '../../application/family_access_service.dart';
import '../../application/settings_service.dart';
import '../../domain/repositories/option_repository.dart';
import '../theme/app_theme.dart';
import '../widgets/app_background.dart';
import '../widgets/app_bar_action_button.dart';
import '../widgets/app_feedback.dart';
import '../widgets/uniform_jersey_swatch.dart';

class ClubScheduleScreen extends StatefulWidget {
  final OptionRepository optionRepository;
  final String? sportId;
  final bool readOnly;

  const ClubScheduleScreen({
    super.key,
    required this.optionRepository,
    this.sportId,
    this.readOnly = false,
  });

  @override
  State<ClubScheduleScreen> createState() => _ClubScheduleScreenState();
}

class _ClubScheduleScreenState extends State<ClubScheduleScreen> {
  late final ClubScheduleService _service;
  late ClubScheduleProfile _profile;
  late List<ClubTrainingSchedule> _schedules;
  final TextEditingController _clubNameController = TextEditingController();
  Timer? _autoSaveTimer;
  Future<void>? _activeSave;
  bool _queueSaveAfterCurrent = false;
  bool _syncingClubName = false;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _service = ClubScheduleService(
      widget.optionRepository,
      sportId: widget.sportId,
    );
    _profile = _service.loadProfile();
    _clubNameController.text = _profile.clubName;
    _schedules = List<ClubTrainingSchedule>.from(_profile.weekdaySchedules);
    _clubNameController.addListener(_handleClubNameChanged);
  }

  @override
  void dispose() {
    _autoSaveTimer?.cancel();
    _clubNameController.removeListener(_handleClubNameChanged);
    _clubNameController.dispose();
    super.dispose();
  }

  bool get _isReadOnlySupportMode =>
      widget.readOnly ||
      FamilyAccessService(
        widget.optionRepository,
      ).loadState().isReadOnlySupportMode;

  bool get _hasUnsavedDraft =>
      !_isReadOnlySupportMode &&
      !_sameEditableProfile(_draftProfile(), _profile);

  bool get _hasPendingSave =>
      _saving || (_autoSaveTimer?.isActive ?? false) || _hasUnsavedDraft;

  void _handleClubNameChanged() {
    if (_syncingClubName) return;
    if (_isReadOnlySupportMode) {
      if (_clubNameController.text != _profile.clubName) {
        _syncingClubName = true;
        _clubNameController.text = _profile.clubName;
        _syncingClubName = false;
      }
      return;
    }
    setState(() {});
    _scheduleAutoSave();
  }

  void _scheduleAutoSave() {
    _autoSaveTimer?.cancel();
    if (_isReadOnlySupportMode) return;
    if (!_hasUnsavedDraft) {
      if (mounted) setState(() {});
      return;
    }
    if (_saving) {
      _queueSaveAfterCurrent = true;
      return;
    }
    setState(() {});
    _autoSaveTimer = Timer(const Duration(milliseconds: 700), () {
      _save(showFeedback: false);
    });
  }

  Future<void> _save({
    bool showFeedback = true,
    bool force = false,
  }) {
    _autoSaveTimer?.cancel();
    if (_isReadOnlySupportMode) {
      if (showFeedback && mounted) {
        _showReadOnlyMessage();
      }
      return Future<void>.value();
    }
    _queueSaveAfterCurrent = true;
    if (_activeSave != null) {
      return _activeSave!;
    }

    final save = _drainSaveQueue(
      showFeedbackForFirstSave: showFeedback,
      forceFirstSave: force,
    );
    _activeSave = save.whenComplete(() {
      _activeSave = null;
    });
    return _activeSave!;
  }

  Future<void> _drainSaveQueue({
    required bool showFeedbackForFirstSave,
    required bool forceFirstSave,
  }) async {
    var showFeedback = showFeedbackForFirstSave;
    var force = forceFirstSave;
    while (mounted) {
      _queueSaveAfterCurrent = false;
      if (!force && !_hasUnsavedDraft) break;
      try {
        await _performSingleSave(showFeedback: showFeedback);
      } catch (_) {
        if (!mounted) return;
        final l10n = AppLocalizations.of(context)!;
        AppFeedback.showMessage(
          context,
          text: l10n.clubScheduleSaveFailedFeedback,
        );
        break;
      }
      showFeedback = false;
      force = false;
      if (!_queueSaveAfterCurrent && !_hasUnsavedDraft) break;
    }
    if (mounted) setState(() {});
  }

  Future<void> _performSingleSave({required bool showFeedback}) async {
    final l10n = showFeedback ? AppLocalizations.of(context)! : null;
    final profileToSave = _draftProfile();
    setState(() => _saving = true);
    try {
      await _service.saveProfile(profileToSave);
      await _syncClubTrainingReminders();
      if (!mounted) return;
      final saved = _service.loadProfile();
      final currentDraft = _draftProfile();
      final shouldPreserveDraft =
          !_sameEditableProfile(currentDraft, profileToSave);
      setState(() {
        _profile = saved;
        if (!shouldPreserveDraft) {
          _schedules = List<ClubTrainingSchedule>.from(
            saved.weekdaySchedules,
          );
          if (_clubNameController.text != saved.clubName) {
            _syncingClubName = true;
            _clubNameController.text = saved.clubName;
            _syncingClubName = false;
          }
        }
      });
      if (showFeedback && !shouldPreserveDraft && mounted) {
        AppFeedback.showSuccess(
          context,
          text: l10n!.clubScheduleSavedFeedback,
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _syncClubTrainingReminders() async {
    try {
      final settings = SettingsService(widget.optionRepository)..load();
      await ClubTrainingReminderService(
        widget.optionRepository,
        settings,
        sportId: widget.sportId,
      ).syncSettingsDrivenReminders();
    } catch (_) {
      // Reminder sync can recover on app startup or the next schedule save.
    }
  }

  void _setSchedule(ClubTrainingSchedule schedule) {
    if (_isReadOnlySupportMode) {
      _showReadOnlyMessage();
      return;
    }
    setState(() {
      _schedules = ClubScheduleService.normalizeSchedules(
        _schedules.map(
          (item) => item.weekday == schedule.weekday ? schedule : item,
        ),
      );
    });
    _scheduleAutoSave();
  }

  Future<void> _pickScheduleTime({
    required ClubTrainingSchedule schedule,
    required bool start,
  }) async {
    if (_isReadOnlySupportMode) {
      _showReadOnlyMessage();
      return;
    }
    final initialMinutes = start ? schedule.startMinutes : schedule.endMinutes;
    final picked = await showTimePicker(
      context: context,
      initialTime: _timeOfDayForMinutes(initialMinutes),
    );
    if (picked == null) return;
    final minutes = picked.hour * 60 + picked.minute;
    _setSchedule(
      start
          ? schedule.copyWith(startMinutes: minutes)
          : schedule.copyWith(endMinutes: minutes),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final readOnly = _isReadOnlySupportMode;
    final canPop = !_hasPendingSave;
    return PopScope(
      canPop: canPop,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop || canPop) return;
        await _handlePendingExit();
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(l10n.clubScheduleTitle),
          actions: [
            AppBarActionButton.label(
              key: const ValueKey<String>('club-schedule-save-button'),
              icon: _saving
                  ? const SizedBox.square(
                      dimension: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.save_outlined),
              label: l10n.clubScheduleSaveButton,
              tooltip: l10n.clubScheduleSaveButton,
              onPressed: readOnly || _saving
                  ? null
                  : () => _save(showFeedback: true, force: true),
              maxLabelWidth: 120,
            ),
          ],
        ),
        body: AppBackground(
          child: SafeArea(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.md,
                AppSpacing.md,
                AppSpacing.md,
                AppSpacing.xl,
              ),
              children: [
                _ClubScheduleSummaryPanel(
                  profile: _draftProfile(),
                  weekdayLabel: _weekdayLabel,
                  timeRangeLabel: _timeRangeLabel,
                ),
                const SizedBox(height: AppSpacing.md),
                _ClubNamePanel(
                  controller: _clubNameController,
                  readOnly: readOnly,
                ),
                const SizedBox(height: AppSpacing.md),
                _WeekdaySchedulePanel(
                  schedules: _schedules,
                  weekdayLabel: _weekdayLabel,
                  timeRangeLabel: _timeRangeLabel,
                  readOnly: readOnly,
                  onScheduleChanged: _setSchedule,
                  onPickTime: _pickScheduleTime,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  ClubScheduleProfile _draftProfile() {
    return _profile.copyWith(
      clubName: _clubNameController.text.trim(),
      weekdaySchedules: _schedules,
    );
  }

  Future<void> _handlePendingExit() async {
    if (_isReadOnlySupportMode) return;
    final navigator = Navigator.of(context);
    final action = await _confirmPendingExit();
    if (!mounted || action == null) return;
    switch (action) {
      case _ClubSchedulePendingExitAction.keepEditing:
        return;
      case _ClubSchedulePendingExitAction.leaveWithoutSaving:
        _autoSaveTimer?.cancel();
        navigator.pop();
      case _ClubSchedulePendingExitAction.saveAndLeave:
        await _save(showFeedback: false, force: true);
        if (!mounted || _hasPendingSave) return;
        navigator.pop();
    }
  }

  Future<_ClubSchedulePendingExitAction?> _confirmPendingExit() {
    final l10n = AppLocalizations.of(context)!;
    return showDialog<_ClubSchedulePendingExitAction>(
      context: context,
      builder: (context) => AlertDialog(
        key: const ValueKey<String>('club-schedule-unsaved-dialog'),
        title: Text(l10n.clubScheduleUnsavedDialogTitle),
        content: Text(l10n.clubScheduleUnsavedDialogBody),
        actions: [
          TextButton(
            key: const ValueKey<String>('club-schedule-unsaved-keep-editing'),
            onPressed: () => Navigator.of(context).pop(
              _ClubSchedulePendingExitAction.keepEditing,
            ),
            child: Text(l10n.clubScheduleUnsavedKeepEditing),
          ),
          TextButton(
            key: const ValueKey<String>('club-schedule-unsaved-leave'),
            onPressed: () => Navigator.of(context).pop(
              _ClubSchedulePendingExitAction.leaveWithoutSaving,
            ),
            child: Text(l10n.clubScheduleUnsavedLeaveWithoutSaving),
          ),
          FilledButton(
            key: const ValueKey<String>('club-schedule-unsaved-save-leave'),
            onPressed: () => Navigator.of(context).pop(
              _ClubSchedulePendingExitAction.saveAndLeave,
            ),
            child: Text(l10n.clubScheduleUnsavedSaveAndLeave),
          ),
        ],
      ),
    );
  }

  void _showReadOnlyMessage() {
    if (!mounted) return;
    AppFeedback.showMessage(
      context,
      text: AppLocalizations.of(context)!.parentReadOnlyCoreDataMessage,
    );
  }

  bool _sameEditableProfile(
    ClubScheduleProfile a,
    ClubScheduleProfile b,
  ) {
    if (a.clubName.trim() != b.clubName.trim()) return false;
    if (a.weekdaySchedules.length != b.weekdaySchedules.length) return false;
    for (var index = 0; index < a.weekdaySchedules.length; index += 1) {
      if (!_sameSchedule(
        a.weekdaySchedules[index],
        b.weekdaySchedules[index],
      )) {
        return false;
      }
    }
    return a.homeUniformColorValue == b.homeUniformColorValue &&
        a.awayUniformColorValue == b.awayUniformColorValue &&
        a.keeperUniformColorValue == b.keeperUniformColorValue;
  }

  bool _sameSchedule(ClubTrainingSchedule a, ClubTrainingSchedule b) {
    return a.weekday == b.weekday &&
        a.enabled == b.enabled &&
        a.startMinutes == b.startMinutes &&
        a.endMinutes == b.endMinutes &&
        a.uniformColorValue == b.uniformColorValue;
  }

  String _weekdayLabel(int weekday) {
    return DateFormat.EEEE(
      AppLocalizations.of(context)!.localeName,
    ).format(_dateForWeekday(weekday));
  }

  String _timeRangeLabel(ClubTrainingSchedule schedule) {
    return '${_timeLabel(schedule.startMinutes)}-${_timeLabel(schedule.endMinutes)}';
  }

  String _timeLabel(int minutes) {
    return MaterialLocalizations.of(context).formatTimeOfDay(
      _timeOfDayForMinutes(minutes),
      alwaysUse24HourFormat: MediaQuery.alwaysUse24HourFormatOf(context),
    );
  }

  static DateTime _dateForWeekday(int weekday) {
    return DateTime(2026, 6, 29).add(Duration(days: weekday - 1));
  }

  static TimeOfDay _timeOfDayForMinutes(int minutes) {
    final normalized = ClubScheduleService.normalizeMinutes(
      minutes,
      fallback: ClubTrainingSchedule.defaultStartMinutes,
    );
    return TimeOfDay(hour: normalized ~/ 60, minute: normalized % 60);
  }
}

enum _ClubSchedulePendingExitAction {
  keepEditing,
  leaveWithoutSaving,
  saveAndLeave,
}

class _ClubScheduleSummaryPanel extends StatelessWidget {
  final ClubScheduleProfile profile;
  final String Function(int weekday) weekdayLabel;
  final String Function(ClubTrainingSchedule schedule) timeRangeLabel;

  const _ClubScheduleSummaryPanel({
    required this.profile,
    required this.weekdayLabel,
    required this.timeRangeLabel,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final today = DateTime.now();
    final todaySchedule = profile.scheduleForDate(today);
    final nextTraining = profile.nextTraining(today);
    final hasTodayTraining = todaySchedule?.enabled == true;
    final previewSchedule =
        hasTodayTraining ? todaySchedule : nextTraining?.schedule;
    final clubName = profile.clubName.trim();
    return Container(
      decoration: AppSurfaces.heroDecoration(
        theme.colorScheme,
        theme.brightness,
        accent: const Color(0xFF16A34A),
      ),
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.event_available_outlined,
            color: Colors.white.withValues(alpha: 0.92),
            size: 28,
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            clubName.isEmpty ? l10n.clubScheduleTitle : clubName,
            style: theme.textTheme.headlineSmall?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            hasTodayTraining
                ? l10n.clubScheduleTodayTraining(
                    timeRangeLabel(todaySchedule!),
                  )
                : l10n.clubScheduleTodayNoTraining,
            style: theme.textTheme.titleMedium?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: AppSpacing.xxs),
          Text(
            nextTraining == null
                ? l10n.clubScheduleNoUpcomingTraining
                : l10n.clubScheduleNextTraining(
                    weekdayLabel(nextTraining.schedule.weekday),
                    timeRangeLabel(nextTraining.schedule),
                  ),
            style: theme.textTheme.bodyMedium?.copyWith(
              color: Colors.white.withValues(alpha: 0.84),
              height: 1.35,
            ),
          ),
          if (previewSchedule != null) ...[
            const SizedBox(height: AppSpacing.md),
            _UniformPreviewRow(colorValue: previewSchedule.uniformColorValue),
          ],
        ],
      ),
    );
  }
}

class _ClubNamePanel extends StatelessWidget {
  final TextEditingController controller;
  final bool readOnly;

  const _ClubNamePanel({
    required this.controller,
    required this.readOnly,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    return Container(
      decoration: AppSurfaces.cardDecoration(
        theme.colorScheme,
        theme.brightness,
      ),
      padding: const EdgeInsets.all(AppSpacing.md),
      child: TextField(
        key: const ValueKey<String>('club-schedule-name-field'),
        controller: controller,
        readOnly: readOnly,
        textInputAction: TextInputAction.done,
        decoration: InputDecoration(
          labelText: l10n.clubScheduleClubNameLabel,
          hintText: l10n.clubScheduleClubNameHint,
          prefixIcon: const Icon(Icons.shield_outlined),
        ),
      ),
    );
  }
}

class _WeekdaySchedulePanel extends StatelessWidget {
  final List<ClubTrainingSchedule> schedules;
  final String Function(int weekday) weekdayLabel;
  final String Function(ClubTrainingSchedule schedule) timeRangeLabel;
  final bool readOnly;
  final ValueChanged<ClubTrainingSchedule> onScheduleChanged;
  final Future<void> Function({
    required ClubTrainingSchedule schedule,
    required bool start,
  }) onPickTime;

  const _WeekdaySchedulePanel({
    required this.schedules,
    required this.weekdayLabel,
    required this.timeRangeLabel,
    required this.readOnly,
    required this.onScheduleChanged,
    required this.onPickTime,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    return Container(
      key: const ValueKey<String>('club-schedule-weekday-panel'),
      decoration: AppSurfaces.cardDecoration(
        theme.colorScheme,
        theme.brightness,
      ),
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _PanelTitle(
            icon: Icons.calendar_month_outlined,
            title: l10n.clubScheduleWeekdayTitle,
            helper: l10n.clubScheduleWeekdayHelper,
          ),
          const SizedBox(height: AppSpacing.sm),
          for (final schedule in schedules) ...[
            _WeekdayScheduleRow(
              schedule: schedule,
              weekdayLabel: weekdayLabel(schedule.weekday),
              timeRangeLabel: timeRangeLabel(schedule),
              readOnly: readOnly,
              onScheduleChanged: onScheduleChanged,
              onPickTime: onPickTime,
            ),
            if (schedule.weekday != DateTime.sunday)
              const Divider(height: AppSpacing.md),
          ],
        ],
      ),
    );
  }
}

class _WeekdayScheduleRow extends StatelessWidget {
  final ClubTrainingSchedule schedule;
  final String weekdayLabel;
  final String timeRangeLabel;
  final bool readOnly;
  final ValueChanged<ClubTrainingSchedule> onScheduleChanged;
  final Future<void> Function({
    required ClubTrainingSchedule schedule,
    required bool start,
  }) onPickTime;

  const _WeekdayScheduleRow({
    required this.schedule,
    required this.weekdayLabel,
    required this.timeRangeLabel,
    required this.readOnly,
    required this.onScheduleChanged,
    required this.onPickTime,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final timeButtonStyle = OutlinedButton.styleFrom(
      alignment: Alignment.center,
      minimumSize: const Size(0, AppSizes.minTouchTarget),
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
    );
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  weekdayLabel,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              Switch(
                key: ValueKey<String>(
                  'club-schedule-day-switch-${schedule.weekday}',
                ),
                value: schedule.enabled,
                onChanged: readOnly
                    ? null
                    : (enabled) => onScheduleChanged(
                          schedule.copyWith(enabled: enabled),
                        ),
              ),
            ],
          ),
          AnimatedOpacity(
            duration: const Duration(milliseconds: 160),
            opacity: schedule.enabled ? 1 : 0.46,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        key: ValueKey<String>(
                          'club-schedule-start-${schedule.weekday}',
                        ),
                        style: timeButtonStyle,
                        onPressed: schedule.enabled && !readOnly
                            ? () => onPickTime(schedule: schedule, start: true)
                            : null,
                        icon: const Icon(Icons.play_arrow_outlined, size: 18),
                        label: Text(
                          l10n.clubScheduleStartTimeLabel,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.xs),
                    Expanded(
                      child: OutlinedButton.icon(
                        key: ValueKey<String>(
                          'club-schedule-end-${schedule.weekday}',
                        ),
                        style: timeButtonStyle,
                        onPressed: schedule.enabled && !readOnly
                            ? () => onPickTime(schedule: schedule, start: false)
                            : null,
                        icon: const Icon(Icons.stop_outlined, size: 18),
                        label: Text(
                          l10n.clubScheduleEndTimeLabel,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.xs),
                Align(
                  alignment: Alignment.centerRight,
                  child: Text(
                    schedule.enabled
                        ? timeRangeLabel
                        : l10n.clubScheduleDayOffLabel,
                    key: ValueKey<String>(
                      'club-schedule-time-summary-${schedule.weekday}',
                    ),
                    textAlign: TextAlign.end,
                    style: theme.textTheme.labelLarge?.copyWith(
                      color: schedule.enabled
                          ? scheme.primary
                          : scheme.onSurfaceVariant,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                if (schedule.enabled) ...[
                  const SizedBox(height: AppSpacing.sm),
                  _UniformColorSelector(
                    label: l10n.clubScheduleDayUniformLabel,
                    selectedColorValue: schedule.uniformColorValue,
                    keyPrefix: 'day-${schedule.weekday}',
                    onChanged: readOnly
                        ? null
                        : (value) => onScheduleChanged(
                              schedule.copyWith(uniformColorValue: value),
                            ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _UniformColorSelector extends StatelessWidget {
  final String label;
  final int selectedColorValue;
  final String keyPrefix;
  final ValueChanged<int>? onChanged;

  const _UniformColorSelector({
    required this.label,
    required this.selectedColorValue,
    required this.keyPrefix,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final l10n = AppLocalizations.of(context)!;
    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
        Tooltip(
          message: l10n.clubScheduleColorSelectTooltip,
          child: OutlinedButton(
            key: ValueKey<String>('club-uniform-$keyPrefix-picker'),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.sm,
                vertical: AppSpacing.xs,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onPressed: onChanged == null
                ? null
                : () async {
                    final barrierColor = Theme.of(context)
                        .colorScheme
                        .scrim
                        .withValues(alpha: 0.38);
                    final picked = await showModalBottomSheet<int>(
                      context: context,
                      backgroundColor: Colors.transparent,
                      barrierColor: barrierColor,
                      isScrollControlled: true,
                      useSafeArea: true,
                      builder: (context) => _UniformColorPickerSheet(
                        initialColorValue: selectedColorValue,
                      ),
                    );
                    if (picked != null) onChanged!(picked);
                  },
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                UniformJerseySwatch(
                  color: Color(selectedColorValue),
                  size: 30,
                  borderColor: scheme.outline.withValues(alpha: 0.68),
                  borderWidth: 1.2,
                  semanticLabel: label,
                ),
                const SizedBox(width: AppSpacing.xs),
                Text(l10n.clubScheduleColorSelectTooltip),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _UniformColorPickerSheet extends StatefulWidget {
  final int initialColorValue;

  const _UniformColorPickerSheet({required this.initialColorValue});

  @override
  State<_UniformColorPickerSheet> createState() =>
      _UniformColorPickerSheetState();
}

class _UniformColorPickerSheetState extends State<_UniformColorPickerSheet> {
  static const List<_UniformColorPreset> _presets = <_UniformColorPreset>[
    _UniformColorPreset(id: 'white', colorValue: 0xFFFFFFFF),
    _UniformColorPreset(id: 'black', colorValue: 0xFF111827),
    _UniformColorPreset(id: 'red', colorValue: 0xFFDC2626),
    _UniformColorPreset(id: 'orange', colorValue: 0xFFF97316),
    _UniformColorPreset(id: 'yellow', colorValue: 0xFFFACC15),
    _UniformColorPreset(id: 'green', colorValue: 0xFF16A34A),
    _UniformColorPreset(id: 'blue', colorValue: 0xFF2563EB),
    _UniformColorPreset(id: 'purple', colorValue: 0xFF7C3AED),
  ];

  late HSVColor _color;

  @override
  void initState() {
    super.initState();
    _color = HSVColor.fromColor(Color(widget.initialColorValue));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final materialL10n = MaterialLocalizations.of(context);
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final selectedColor = _color.toColor().withValues(alpha: 1);
    final screenSize = MediaQuery.sizeOf(context);
    final maxSheetHeight = screenSize.height * 0.88;

    return SizedBox(
      width: screenSize.width,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxHeight: maxSheetHeight),
        child: Material(
          key: const ValueKey<String>('club-uniform-color-sheet'),
          color: scheme.surface,
          elevation: theme.brightness == Brightness.dark ? 0 : 10,
          shadowColor: Colors.black.withValues(alpha: 0.18),
          borderRadius: const BorderRadius.vertical(
            top: Radius.circular(AppRadius.card),
          ),
          clipBehavior: Clip.antiAlias,
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.md,
                AppSpacing.sm,
                AppSpacing.md,
                AppSpacing.lg,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Center(
                    child: Container(
                      width: 36,
                      height: 4,
                      decoration: BoxDecoration(
                        color: scheme.onSurfaceVariant.withValues(alpha: 0.34),
                        borderRadius: AppRadius.full,
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Row(
                    children: [
                      UniformJerseySwatch(
                        color: selectedColor,
                        size: 52,
                        borderColor: scheme.outline.withValues(alpha: 0.64),
                        borderWidth: 1.4,
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: Text(
                          l10n.clubScheduleColorSelectTooltip,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Text(
                    l10n.clubScheduleColorPresetsLabel,
                    style: theme.textTheme.labelLarge?.copyWith(
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Wrap(
                    spacing: AppSpacing.xs,
                    runSpacing: AppSpacing.xs,
                    children: [
                      for (final preset in _presets)
                        _UniformColorPresetButton(
                          key: ValueKey<String>(
                            'club-uniform-color-preset-${preset.id}',
                          ),
                          colorValue: preset.colorValue,
                          selected:
                              selectedColor.toARGB32() == preset.colorValue,
                          label: l10n.clubScheduleColorSelectTooltip,
                          onTap: () {
                            setState(() {
                              _color = HSVColor.fromColor(
                                Color(preset.colorValue),
                              );
                            });
                          },
                        ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.md),
                  _UniformColorSlider(
                    key: const ValueKey<String>(
                      'club-uniform-color-hue-slider',
                    ),
                    label: l10n.clubScheduleColorHueLabel,
                    valueLabel: _color.hue.round().toString(),
                    value: _color.hue,
                    min: 0,
                    max: 360,
                    divisions: 360,
                    activeColor: HSVColor.fromAHSV(
                      1,
                      _color.hue,
                      1,
                      1,
                    ).toColor(),
                    onChanged: (value) {
                      setState(() {
                        _color = _color.withHue(value);
                      });
                    },
                  ),
                  _UniformColorSlider(
                    key: const ValueKey<String>(
                      'club-uniform-color-saturation-slider',
                    ),
                    label: l10n.clubScheduleColorSaturationLabel,
                    valueLabel: '${(_color.saturation * 100).round()}%',
                    value: _color.saturation,
                    min: 0,
                    max: 1,
                    divisions: 100,
                    activeColor: selectedColor,
                    onChanged: (value) {
                      setState(() {
                        _color = _color.withSaturation(value);
                      });
                    },
                  ),
                  _UniformColorSlider(
                    key: const ValueKey<String>(
                      'club-uniform-color-brightness-slider',
                    ),
                    label: l10n.clubScheduleColorBrightnessLabel,
                    valueLabel: '${(_color.value * 100).round()}%',
                    value: _color.value,
                    min: 0,
                    max: 1,
                    divisions: 100,
                    activeColor: selectedColor,
                    onChanged: (value) {
                      setState(() {
                        _color = _color.withValue(value);
                      });
                    },
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(),
                        child: Text(materialL10n.cancelButtonLabel),
                      ),
                      const SizedBox(width: AppSpacing.xs),
                      FilledButton(
                        style: FilledButton.styleFrom(
                          minimumSize: const Size(72, 44),
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.md,
                          ),
                        ),
                        onPressed: () => Navigator.of(context).pop(
                          selectedColor.toARGB32(),
                        ),
                        child: Text(materialL10n.okButtonLabel),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _UniformColorPreset {
  final String id;
  final int colorValue;

  const _UniformColorPreset({
    required this.id,
    required this.colorValue,
  });
}

class _UniformColorPresetButton extends StatelessWidget {
  final int colorValue;
  final bool selected;
  final String label;
  final VoidCallback onTap;

  const _UniformColorPresetButton({
    super.key,
    required this.colorValue,
    required this.selected,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Tooltip(
      message: label,
      child: Semantics(
        button: true,
        selected: selected,
        label: label,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 140),
            width: 42,
            height: 42,
            padding: const EdgeInsets.all(5),
            decoration: BoxDecoration(
              color: selected
                  ? scheme.primary.withValues(alpha: 0.10)
                  : scheme.surfaceContainerHighest.withValues(alpha: 0.42),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: selected
                    ? scheme.primary
                    : scheme.outline.withValues(alpha: 0.36),
                width: selected ? 2 : 1,
              ),
            ),
            child: UniformJerseySwatch(
              color: Color(colorValue),
              size: 30,
              borderColor: selected
                  ? scheme.primary
                  : scheme.outline.withValues(alpha: 0.68),
              borderWidth: selected ? 1.4 : 1.1,
              selected: selected,
            ),
          ),
        ),
      ),
    );
  }
}

class _UniformColorSlider extends StatelessWidget {
  final String label;
  final String valueLabel;
  final double value;
  final double min;
  final double max;
  final int divisions;
  final Color activeColor;
  final ValueChanged<double> onChanged;

  const _UniformColorSlider({
    super.key,
    required this.label,
    required this.valueLabel,
    required this.value,
    required this.min,
    required this.max,
    required this.divisions,
    required this.activeColor,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: theme.textTheme.labelLarge?.copyWith(
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
            Text(
              valueLabel,
              style: theme.textTheme.labelMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
        Slider(
          value: value,
          min: min,
          max: max,
          divisions: divisions,
          label: valueLabel,
          activeColor: activeColor,
          onChanged: onChanged,
          semanticFormatterCallback: (value) {
            final normalized =
                max == 1 ? '${(value * 100).round()}%' : value.round();
            return '$label $normalized';
          },
        ),
      ],
    );
  }
}

class _UniformPreviewRow extends StatelessWidget {
  final int colorValue;

  const _UniformPreviewRow({required this.colorValue});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Row(
      children: [
        _UniformPreviewChip(
          label: l10n.clubScheduleDayUniformLabel,
          colorValue: colorValue,
        ),
      ],
    );
  }
}

class _UniformPreviewChip extends StatelessWidget {
  final String label;
  final int colorValue;

  const _UniformPreviewChip({
    required this.label,
    required this.colorValue,
  });

  @override
  Widget build(BuildContext context) {
    return Flexible(
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.xs,
          vertical: AppSpacing.xxs,
        ),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.14),
          borderRadius: AppRadius.small,
          border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            UniformJerseySwatch(
              color: Color(colorValue),
              size: 18,
              borderColor: Colors.white,
              borderWidth: 1.2,
            ),
            const SizedBox(width: AppSpacing.xxs),
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w900,
                    ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PanelTitle extends StatelessWidget {
  final IconData icon;
  final String title;
  final String helper;

  const _PanelTitle({
    required this.icon,
    required this.title,
    required this.helper,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: theme.colorScheme.primary),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: AppSpacing.xxs),
              Text(
                helper,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                  height: 1.35,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
