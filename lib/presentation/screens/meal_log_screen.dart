import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../application/meal_coaching_service.dart';
import '../../application/meal_log_service.dart';
import '../../application/player_level_service.dart';
import '../../application/settings_service.dart';
import '../../application/training_plan_reminder_service.dart';
import '../../domain/entities/meal_entry.dart';
import '../../domain/repositories/option_repository.dart';
import '../widgets/app_background.dart';
import '../widgets/app_feedback.dart';
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

  @override
  void initState() {
    super.initState();
    final initialDate = DateTime(
      widget.initialDate.year,
      widget.initialDate.month,
      widget.initialDate.day,
    );
    final initialEntry = widget.initialEntry;
    _date = initialEntry == null
        ? initialDate
        : DateTime(
            initialEntry.date.year,
            initialEntry.date.month,
            initialEntry.date.day,
          );
    _breakfastRiceBowls = initialEntry?.breakfastRiceBowls ?? 0;
    _lunchRiceBowls = initialEntry?.lunchRiceBowls ?? 0;
    _dinnerRiceBowls = initialEntry?.dinnerRiceBowls ?? 0;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
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
          if (widget.initialEntry != null)
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
                label: l10n.mealBreakfast,
                value: _breakfastRiceBowls,
                l10n: l10n,
                onChanged: (value) {
                  setState(() => _breakfastRiceBowls = value);
                },
              ),
              const SizedBox(height: 10),
              _MealSelectorCard(
                label: l10n.mealLunch,
                value: _lunchRiceBowls,
                l10n: l10n,
                onChanged: (value) {
                  setState(() => _lunchRiceBowls = value);
                },
              ),
              const SizedBox(height: 10),
              _MealSelectorCard(
                label: l10n.mealDinner,
                value: _dinnerRiceBowls,
                l10n: l10n,
                onChanged: (value) {
                  setState(() => _dinnerRiceBowls = value);
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
                          _InfoPill(
                            label: _xpLabel(l10n, status.completedMeals),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),
              FilledButton.icon(
                onPressed: _save,
                icon: const Icon(Icons.save_outlined),
                label: Text(l10n.mealSaveAction),
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
    setState(() {
      _date = DateTime(picked.year, picked.month, picked.day);
    });
  }

  Future<void> _save() async {
    final l10n = AppLocalizations.of(context)!;
    final isKo = Localizations.localeOf(context).languageCode == 'ko';
    final previousEntry = widget.initialEntry;
    final entry = MealEntry(
      date: _date,
      breakfastRiceBowls: _breakfastRiceBowls,
      lunchRiceBowls: _lunchRiceBowls,
      dinnerRiceBowls: _dinnerRiceBowls,
      createdAt: previousEntry?.createdAt ?? DateTime.now(),
    );
    await widget.mealLogService.save(entry);
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
    if (!mounted) return;
    AppFeedback.showSuccess(context, text: l10n.mealSavedFeedback);
    Navigator.of(context).pop(entry);
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

  String _xpLabel(AppLocalizations l10n, int completedMeals) {
    if (completedMeals >= 3) return l10n.mealXpFull;
    if (completedMeals >= 2) return l10n.mealXpPartial;
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
  final String label;
  final double value;
  final AppLocalizations l10n;
  final ValueChanged<double> onChanged;

  const _MealSelectorCard({
    required this.label,
    required this.value,
    required this.l10n,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    label,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                Text(
                  _labelForValue(value),
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: theme.colorScheme.primary,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: MealCoachingService.riceBowlOptions.map((option) {
                return ChoiceChip(
                  selected: option == value,
                  label: Text(_labelForValue(option)),
                  onSelected: (_) => onChanged(option),
                );
              }).toList(growable: false),
            ),
          ],
        ),
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
