import 'dart:async';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../application/family_access_service.dart';
import '../../application/meal_coaching_service.dart';
import '../../application/meal_log_service.dart';
import '../../application/player_level_service.dart';
import '../../application/settings_service.dart';
import '../../application/training_plan_reminder_service.dart';
import '../../domain/entities/meal_entry.dart';
import '../../domain/repositories/option_repository.dart';
import '../widgets/app_background.dart';
import '../widgets/app_feedback.dart';
import '../widgets/rice_bowl_summary.dart';
import 'package:football_note/gen/app_localizations.dart';

class MealLogScreen extends StatefulWidget {
  final MealLogService mealLogService;
  final OptionRepository optionRepository;
  final SettingsService settingsService;
  final DateTime initialDate;
  final MealEntry? initialEntry;

  const MealLogScreen({
    super.key,
    required this.mealLogService,
    required this.optionRepository,
    required this.settingsService,
    required this.initialDate,
    this.initialEntry,
  });

  @override
  State<MealLogScreen> createState() => _MealLogScreenState();
}

class _MealLogScreenState extends State<MealLogScreen> {
  DateTime _date = DateTime.now();
  double _breakfastRiceBowls = 0;
  double _lunchRiceBowls = 0;
  double _dinnerRiceBowls = 0;
  MealEntry? _persistedEntry;
  Timer? _autoSaveTimer;
  bool _saveInProgress = false;
  bool _disposed = false;

  @override
  void initState() {
    super.initState();
    final initialDate = DateTime(
      widget.initialDate.year,
      widget.initialDate.month,
      widget.initialDate.day,
    );
    _loadEntryForDate(initialDate, initialEntry: widget.initialEntry);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final isParentMode =
        FamilyAccessService(widget.optionRepository).loadState().isParentMode;
    if (isParentMode) {
      return Scaffold(
        appBar: AppBar(title: Text(l10n.mealLogScreenTitle)),
        body: AppBackground(
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    l10n.parentReadOnlyMealLog,
                    style: theme.textTheme.bodyLarge,
                  ),
                ),
              ),
            ),
          ),
        ),
      );
    }
    final status = MealStatus.fromMealEntry(
      MealEntry(
        date: _date,
        breakfastRiceBowls: _breakfastRiceBowls,
        lunchRiceBowls: _lunchRiceBowls,
        dinnerRiceBowls: _dinnerRiceBowls,
      ),
    );

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.mealLogScreenTitle),
        actions: [
          if (_persistedEntry != null)
            IconButton(
              tooltip: l10n.mealDeleteAction,
              onPressed: _delete,
              icon: const Icon(Icons.delete_outline),
            ),
        ],
      ),
      body: AppBackground(
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
            children: [
              Card(
                child: ListTile(
                  leading: const Icon(Icons.calendar_today_outlined),
                  title: Text(l10n.mealLogDateLabel),
                  subtitle: Text(
                    DateFormat.yMMMMd(
                      Localizations.localeOf(context).toString(),
                    ).add_E().format(_date),
                  ),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: _pickDate,
                ),
              ),
              const SizedBox(height: 12),
              _MealSelectorCard(
                mealKey: 'breakfast',
                label: l10n.mealBreakfast,
                value: _breakfastRiceBowls,
                l10n: l10n,
                onChanged: (value) {
                  setState(() => _breakfastRiceBowls = value);
                  _scheduleAutoSave();
                },
              ),
              const SizedBox(height: 10),
              _MealSelectorCard(
                mealKey: 'lunch',
                label: l10n.mealLunch,
                value: _lunchRiceBowls,
                l10n: l10n,
                onChanged: (value) {
                  setState(() => _lunchRiceBowls = value);
                  _scheduleAutoSave();
                },
              ),
              const SizedBox(height: 10),
              _MealSelectorCard(
                mealKey: 'dinner',
                label: l10n.mealDinner,
                value: _dinnerRiceBowls,
                l10n: l10n,
                onChanged: (value) {
                  setState(() => _dinnerRiceBowls = value);
                  _scheduleAutoSave();
                },
              ),
              const SizedBox(height: 12),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _headline(l10n, status),
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _body(l10n, status),
                        style: theme.textTheme.bodyMedium,
                      ),
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          _InfoPill(
                            label: l10n.mealAverageExpectedValue(
                              _formatBowls(MealLogService.expectedBowlsPerDay),
                            ),
                          ),
                          _InfoPill(
                            label: l10n.mealAverageActualValue(
                              _formatBowls(status.totalRiceBowls),
                            ),
                          ),
                          _InfoPill(label: _xpLabel(l10n, status)),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _pickDate() async {
    final l10n = AppLocalizations.of(context)!;
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2022, 1, 1),
      lastDate: DateTime(2032, 12, 31),
      helpText: l10n.mealLogDatePickerHelp,
    );
    if (picked == null || !mounted) return;
    _autoSaveTimer?.cancel();
    await _save();
    if (!mounted) return;
    setState(() {
      _loadEntryForDate(DateTime(picked.year, picked.month, picked.day));
    });
  }

  void _scheduleAutoSave() {
    if (_saveInProgress || _disposed) return;
    _autoSaveTimer?.cancel();
    _autoSaveTimer = Timer(const Duration(milliseconds: 250), () {
      if (!mounted || _disposed) return;
      unawaited(_save());
    });
  }

  Future<void> _save() async {
    if (_saveInProgress || _disposed) return;
    _saveInProgress = true;
    final l10n = AppLocalizations.of(context)!;
    final isKo = Localizations.localeOf(context).languageCode == 'ko';
    final previousEntry = _persistedEntry;
    final entry = MealEntry(
      date: _date,
      breakfastRiceBowls: _breakfastRiceBowls,
      lunchRiceBowls: _lunchRiceBowls,
      dinnerRiceBowls: _dinnerRiceBowls,
      createdAt: previousEntry?.createdAt ?? DateTime.now(),
    );
    try {
      await widget.mealLogService.save(entry);
      _persistedEntry = entry.hasRecords ? entry : null;
      final levelService = PlayerLevelService(widget.optionRepository);
      final award = await levelService.awardForMealLog(
        previousEntry: previousEntry,
        updatedEntry: entry,
      );
      final reminderService = TrainingPlanReminderService(
        widget.optionRepository,
        widget.settingsService,
      );
      if (award.gainedXp > 0) {
        await reminderService.showXpGainAlert(
          gainedXp: award.gainedXp,
          totalXp: award.after.totalXp,
          isKo: isKo,
          sourceLabel: l10n.mealLogXpSourceLabel,
        );
        if (award.didLevelUp) {
          await reminderService.showLevelUpAlert(
            level: award.after.level,
            isKo: isKo,
          );
        }
      }
    } finally {
      _saveInProgress = false;
    }
  }

  Future<void> _delete() async {
    final l10n = AppLocalizations.of(context)!;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.mealDeleteAction),
        content: Text(l10n.mealDeleteConfirmBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(MaterialLocalizations.of(context).cancelButtonLabel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(l10n.mealDeleteAction),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    await widget.mealLogService.deleteDay(_date);
    if (!mounted) return;
    AppFeedback.showSuccess(context, text: l10n.mealDeletedFeedback);
    Navigator.of(context).pop(true);
  }

  @override
  void dispose() {
    _disposed = true;
    _autoSaveTimer?.cancel();
    super.dispose();
  }

  void _loadEntryForDate(DateTime date, {MealEntry? initialEntry}) {
    final normalizedDate = DateTime(date.year, date.month, date.day);
    final entry =
        initialEntry ?? widget.mealLogService.entryForDay(normalizedDate);
    _date = entry == null
        ? normalizedDate
        : DateTime(entry.date.year, entry.date.month, entry.date.day);
    _breakfastRiceBowls = entry?.breakfastRiceBowls ?? 0;
    _lunchRiceBowls = entry?.lunchRiceBowls ?? 0;
    _dinnerRiceBowls = entry?.dinnerRiceBowls ?? 0;
    _persistedEntry = entry;
  }

  String _headline(AppLocalizations l10n, MealStatus status) {
    return switch (status.completedMeals) {
      3 => l10n.mealCoachHeadlinePerfect,
      2 => l10n.mealCoachHeadlineAlmost,
      1 => l10n.mealCoachHeadlineNeedsMore,
      _ => l10n.mealCoachHeadlineStart,
    };
  }

  String _body(AppLocalizations l10n, MealStatus status) {
    if (status.completedMeals >= 3 && status.totalRiceBowls >= 5) {
      return l10n.mealCoachBodySteady;
    }
    if (status.completedMeals >= 3) {
      return l10n.mealCoachBodyThreeMeals;
    }
    if (status.completedMeals == 2 && status.totalRiceBowls >= 3) {
      return l10n.mealCoachBodyTwoMealsSolid;
    }
    if (status.completedMeals == 2) {
      return l10n.mealCoachBodyTwoMealsLight;
    }
    if (status.completedMeals == 1) {
      return l10n.mealCoachBodyOneMeal;
    }
    return l10n.mealCoachBodyZeroMeal;
  }

  String _xpLabel(AppLocalizations l10n, MealStatus status) {
    if (status.completedMeals >= 3 && status.totalRiceBowls >= 5) {
      return l10n.mealXpFullBonus;
    }
    if (status.completedMeals >= 3) return l10n.mealXpFull;
    if (status.completedMeals >= 2) return l10n.mealXpPartial;
    return l10n.mealXpNeutral;
  }

  String _formatBowls(double bowls) {
    final whole = bowls.truncateToDouble();
    if ((bowls - whole).abs() < 0.001) {
      return bowls.toStringAsFixed(0);
    }
    return bowls.toStringAsFixed(1);
  }
}

class _MealSelectorCard extends StatelessWidget {
  final String mealKey;
  final String label;
  final double value;
  final AppLocalizations l10n;
  final ValueChanged<double> onChanged;

  const _MealSelectorCard({
    required this.mealKey,
    required this.label,
    required this.value,
    required this.l10n,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final accent = theme.colorScheme.primary;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: accent.withValues(alpha: 0.16)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(11),
                ),
                child: Icon(Icons.rice_bowl_outlined, color: accent, size: 20),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  label,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              Text(
                _labelForValue(value),
                style: theme.textTheme.titleSmall?.copyWith(
                  color: accent,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _MealBowlPreview(value: value, accent: accent),
              ),
              const SizedBox(width: 12),
              Column(
                children: [
                  _MealAdjustButton(
                    key: ValueKey('meal-$mealKey-increment'),
                    tooltip: l10n.mealIncreaseAction,
                    icon: Icons.add_rounded,
                    enabled: _nextValue(value) != value,
                    onTap: () => onChanged(_nextValue(value)),
                  ),
                  const SizedBox(height: 8),
                  _MealAdjustButton(
                    key: ValueKey('meal-$mealKey-decrement'),
                    tooltip: l10n.mealDecreaseAction,
                    icon: Icons.remove_rounded,
                    enabled: _previousValue(value) != value,
                    onTap: () => onChanged(_previousValue(value)),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _labelForValue(double value) {
    if (value == 0) return l10n.mealRiceNone;
    final countText = value == value.truncateToDouble()
        ? value.toStringAsFixed(0)
        : value.toStringAsFixed(1);
    return l10n.mealRiceBowlsValue(countText);
  }

  double _nextValue(double current) {
    final currentIndex = MealCoachingService.riceBowlOptions.indexOf(current);
    if (currentIndex < 0 ||
        currentIndex >= MealCoachingService.riceBowlOptions.length - 1) {
      return current;
    }
    return MealCoachingService.riceBowlOptions[currentIndex + 1];
  }

  double _previousValue(double current) {
    final currentIndex = MealCoachingService.riceBowlOptions.indexOf(current);
    if (currentIndex <= 0) return current;
    return MealCoachingService.riceBowlOptions[currentIndex - 1];
  }
}

class _MealBowlPreview extends StatelessWidget {
  final double value;
  final Color accent;

  const _MealBowlPreview({required this.value, required this.accent});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: accent.withValues(alpha: 0.14)),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [RiceBowlStackVisual(value: value, accentColor: accent)],
          ),
          const SizedBox(height: 10),
          Text(
            value <= 0
                ? AppLocalizations.of(context)!.homeRiceBowlEmpty
                : value == value.truncateToDouble()
                    ? value.toStringAsFixed(0)
                    : value.toStringAsFixed(1),
            style: theme.textTheme.labelLarge?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _MealAdjustButton extends StatelessWidget {
  final String tooltip;
  final IconData icon;
  final bool enabled;
  final VoidCallback onTap;

  const _MealAdjustButton({
    super.key,
    required this.tooltip,
    required this.icon,
    required this.enabled,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final accent = theme.colorScheme.primary;
    return Tooltip(
      message: tooltip,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: enabled ? onTap : null,
          borderRadius: BorderRadius.circular(14),
          child: Ink(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: enabled
                  ? accent.withValues(alpha: 0.12)
                  : theme.colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: enabled
                    ? accent.withValues(alpha: 0.24)
                    : theme.colorScheme.outline.withValues(alpha: 0.14),
              ),
            ),
            child: Icon(
              icon,
              color: enabled
                  ? accent
                  : theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
            ),
          ),
        ),
      ),
    );
  }
}

class _InfoPill extends StatelessWidget {
  final String label;

  const _InfoPill({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: Theme.of(
          context,
        ).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w700),
      ),
    );
  }
}
