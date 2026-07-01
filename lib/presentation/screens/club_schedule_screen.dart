import 'package:flutter/material.dart';
import 'package:football_note/gen/app_localizations.dart';
import 'package:intl/intl.dart';

import '../../application/club_schedule_service.dart';
import '../../domain/repositories/option_repository.dart';
import '../theme/app_theme.dart';
import '../widgets/app_background.dart';
import '../widgets/app_bar_action_button.dart';
import '../widgets/app_feedback.dart';
import '../widgets/uniform_jersey_swatch.dart';

class ClubScheduleScreen extends StatefulWidget {
  final OptionRepository optionRepository;
  final String? sportId;

  const ClubScheduleScreen({
    super.key,
    required this.optionRepository,
    this.sportId,
  });

  @override
  State<ClubScheduleScreen> createState() => _ClubScheduleScreenState();
}

class _ClubScheduleScreenState extends State<ClubScheduleScreen> {
  late final ClubScheduleService _service;
  late ClubScheduleProfile _profile;
  late List<ClubTrainingSchedule> _schedules;
  final TextEditingController _clubNameController = TextEditingController();
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
  }

  @override
  void dispose() {
    _clubNameController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final l10n = AppLocalizations.of(context)!;
    setState(() => _saving = true);
    try {
      final profile = _profile.copyWith(
        clubName: _clubNameController.text.trim(),
        weekdaySchedules: _schedules,
      );
      await _service.saveProfile(profile);
      if (!mounted) return;
      setState(() {
        _profile = _service.loadProfile();
        _schedules = List<ClubTrainingSchedule>.from(
          _profile.weekdaySchedules,
        );
      });
      AppFeedback.showSuccess(context, text: l10n.clubScheduleSavedFeedback);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _setSchedule(ClubTrainingSchedule schedule) {
    setState(() {
      _schedules = ClubScheduleService.normalizeSchedules(
        _schedules.map(
          (item) => item.weekday == schedule.weekday ? schedule : item,
        ),
      );
    });
  }

  Future<void> _pickScheduleTime({
    required ClubTrainingSchedule schedule,
    required bool start,
  }) async {
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
    return Scaffold(
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
            onPressed: _saving ? null : _save,
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
              _ClubNamePanel(controller: _clubNameController),
              const SizedBox(height: AppSpacing.md),
              _WeekdaySchedulePanel(
                schedules: _schedules,
                weekdayLabel: _weekdayLabel,
                timeRangeLabel: _timeRangeLabel,
                onScheduleChanged: _setSchedule,
                onPickTime: _pickScheduleTime,
              ),
            ],
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

  const _ClubNamePanel({required this.controller});

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
  final ValueChanged<ClubTrainingSchedule> onScheduleChanged;
  final Future<void> Function({
    required ClubTrainingSchedule schedule,
    required bool start,
  }) onPickTime;

  const _WeekdaySchedulePanel({
    required this.schedules,
    required this.weekdayLabel,
    required this.timeRangeLabel,
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
  final ValueChanged<ClubTrainingSchedule> onScheduleChanged;
  final Future<void> Function({
    required ClubTrainingSchedule schedule,
    required bool start,
  }) onPickTime;

  const _WeekdayScheduleRow({
    required this.schedule,
    required this.weekdayLabel,
    required this.timeRangeLabel,
    required this.onScheduleChanged,
    required this.onPickTime,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
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
                onChanged: (enabled) => onScheduleChanged(
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
                        onPressed: schedule.enabled
                            ? () => onPickTime(schedule: schedule, start: true)
                            : null,
                        icon: const Icon(Icons.play_arrow_outlined),
                        label: Text(l10n.clubScheduleStartTimeLabel),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.xs),
                    Expanded(
                      child: OutlinedButton.icon(
                        key: ValueKey<String>(
                          'club-schedule-end-${schedule.weekday}',
                        ),
                        onPressed: schedule.enabled
                            ? () => onPickTime(schedule: schedule, start: false)
                            : null,
                        icon: const Icon(Icons.stop_outlined),
                        label: Text(l10n.clubScheduleEndTimeLabel),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    ConstrainedBox(
                      constraints: const BoxConstraints(minWidth: 92),
                      child: Text(
                        schedule.enabled
                            ? timeRangeLabel
                            : l10n.clubScheduleDayOffLabel,
                        textAlign: TextAlign.end,
                        style: theme.textTheme.labelLarge?.copyWith(
                          color: schedule.enabled
                              ? scheme.primary
                              : scheme.onSurfaceVariant,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  ],
                ),
                if (schedule.enabled) ...[
                  const SizedBox(height: AppSpacing.sm),
                  _UniformColorSelector(
                    label: l10n.clubScheduleDayUniformLabel,
                    selectedColorValue: schedule.uniformColorValue,
                    keyPrefix: 'day-${schedule.weekday}',
                    onChanged: (value) => onScheduleChanged(
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
  final ValueChanged<int> onChanged;

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
            onPressed: () async {
              final picked = await showModalBottomSheet<int>(
                context: context,
                showDragHandle: true,
                useSafeArea: true,
                builder: (context) => _UniformColorPickerSheet(
                  initialColorValue: selectedColorValue,
                ),
              );
              if (picked != null) onChanged(picked);
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

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.md,
        AppSpacing.xs,
        AppSpacing.md,
        AppSpacing.lg,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
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
          _UniformColorSlider(
            key: const ValueKey<String>('club-uniform-color-hue-slider'),
            label: l10n.clubScheduleColorHueLabel,
            valueLabel: _color.hue.round().toString(),
            value: _color.hue,
            min: 0,
            max: 360,
            divisions: 360,
            activeColor: HSVColor.fromAHSV(1, _color.hue, 1, 1).toColor(),
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
                onPressed: () => Navigator.of(context).pop(
                  selectedColor.toARGB32(),
                ),
                child: Text(materialL10n.okButtonLabel),
              ),
            ],
          ),
        ],
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
