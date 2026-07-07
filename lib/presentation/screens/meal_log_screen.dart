import 'dart:async';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../application/family_access_service.dart';
import '../../application/meal_calorie_estimator.dart';
import '../../application/meal_coaching_service.dart';
import '../../application/meal_log_service.dart';
import '../../application/player_level_service.dart';
import '../../application/settings_service.dart';
import '../../application/training_plan_reminder_service.dart';
import '../../domain/entities/meal_entry.dart';
import '../../domain/repositories/option_repository.dart';
import '../widgets/app_bar_action_button.dart';
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
  final TextEditingController _breakfastMenuController =
      TextEditingController();
  final TextEditingController _lunchMenuController = TextEditingController();
  final TextEditingController _dinnerMenuController = TextEditingController();
  String _breakfastDishId = '';
  String _lunchDishId = '';
  String _dinnerDishId = '';
  String _breakfastDishPortion = 'regular';
  String _lunchDishPortion = 'regular';
  String _dinnerDishPortion = 'regular';
  MealEntry? _persistedEntry;
  Timer? _autoSaveTimer;
  bool _saveInProgress = false;
  bool _disposed = false;

  bool get _isParentMode =>
      FamilyAccessService(widget.optionRepository).loadState().isParentMode;

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
    final currentEntry = MealEntry(
      date: _date,
      breakfastRiceBowls: _breakfastRiceBowls,
      lunchRiceBowls: _lunchRiceBowls,
      dinnerRiceBowls: _dinnerRiceBowls,
      breakfastMenu: _breakfastMenuController.text,
      lunchMenu: _lunchMenuController.text,
      dinnerMenu: _dinnerMenuController.text,
      breakfastDishId: _breakfastDishId,
      lunchDishId: _lunchDishId,
      dinnerDishId: _dinnerDishId,
      breakfastDishPortion: _breakfastDishPortion,
      lunchDishPortion: _lunchDishPortion,
      dinnerDishPortion: _dinnerDishPortion,
    );
    final status = MealStatus.fromMealEntry(currentEntry);
    final calorieEstimate = MealCalorieEstimator.estimate(currentEntry);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.mealLogScreenTitle),
        actions: [
          if (_persistedEntry != null && !_isParentMode)
            AppBarActionButton.icon(
              tooltip: l10n.mealDeleteAction,
              onPressed: _delete,
              icon: Icons.delete_outline,
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
                menuController: _breakfastMenuController,
                selectedDishId: _breakfastDishId,
                selectedDishPortion: _breakfastDishPortion,
                l10n: l10n,
                enabled: !_isParentMode,
                onChanged: (value) {
                  setState(() => _breakfastRiceBowls = value);
                  _scheduleAutoSave();
                },
                onMenuChanged: (_) {
                  setState(() {});
                  _scheduleAutoSave();
                },
                onDishChanged: (value) {
                  setState(() {
                    _breakfastDishId = value;
                    if (value.isEmpty) _breakfastDishPortion = 'regular';
                  });
                  _scheduleAutoSave();
                },
                onDishPortionChanged: (value) {
                  setState(() => _breakfastDishPortion = value);
                  _scheduleAutoSave();
                },
              ),
              const SizedBox(height: 10),
              _MealSelectorCard(
                mealKey: 'lunch',
                label: l10n.mealLunch,
                value: _lunchRiceBowls,
                menuController: _lunchMenuController,
                selectedDishId: _lunchDishId,
                selectedDishPortion: _lunchDishPortion,
                l10n: l10n,
                enabled: !_isParentMode,
                onChanged: (value) {
                  setState(() => _lunchRiceBowls = value);
                  _scheduleAutoSave();
                },
                onMenuChanged: (_) {
                  setState(() {});
                  _scheduleAutoSave();
                },
                onDishChanged: (value) {
                  setState(() {
                    _lunchDishId = value;
                    if (value.isEmpty) _lunchDishPortion = 'regular';
                  });
                  _scheduleAutoSave();
                },
                onDishPortionChanged: (value) {
                  setState(() => _lunchDishPortion = value);
                  _scheduleAutoSave();
                },
              ),
              const SizedBox(height: 10),
              _MealSelectorCard(
                mealKey: 'dinner',
                label: l10n.mealDinner,
                value: _dinnerRiceBowls,
                menuController: _dinnerMenuController,
                selectedDishId: _dinnerDishId,
                selectedDishPortion: _dinnerDishPortion,
                l10n: l10n,
                enabled: !_isParentMode,
                onChanged: (value) {
                  setState(() => _dinnerRiceBowls = value);
                  _scheduleAutoSave();
                },
                onMenuChanged: (_) {
                  setState(() {});
                  _scheduleAutoSave();
                },
                onDishChanged: (value) {
                  setState(() {
                    _dinnerDishId = value;
                    if (value.isEmpty) _dinnerDishPortion = 'regular';
                  });
                  _scheduleAutoSave();
                },
                onDishPortionChanged: (value) {
                  setState(() => _dinnerDishPortion = value);
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
                          _InfoPill(
                            label: calorieEstimate.hasEstimate
                                ? l10n.mealCalorieEstimateValue(
                                    calorieEstimate.totalKcal,
                                  )
                                : l10n.mealCalorieEstimateEmpty,
                          ),
                          if (calorieEstimate.hasNutrition)
                            _InfoPill(
                              label: l10n.mealNutritionEstimateValue(
                                calorieEstimate.totalCarbs.round(),
                                calorieEstimate.totalProtein.round(),
                                calorieEstimate.totalFat.round(),
                              ),
                            ),
                          _InfoPill(label: _xpLabel(l10n, status)),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Text(
                        _calorieCoach(l10n, calorieEstimate),
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                          height: 1.35,
                        ),
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
    if (!_isParentMode) {
      await _save();
    }
    if (!mounted) return;
    setState(() {
      _loadEntryForDate(DateTime(picked.year, picked.month, picked.day));
    });
  }

  void _scheduleAutoSave() {
    if (_isParentMode) return;
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
      breakfastMenu: _breakfastMenuController.text.trim(),
      lunchMenu: _lunchMenuController.text.trim(),
      dinnerMenu: _dinnerMenuController.text.trim(),
      breakfastDishId: _breakfastDishId,
      lunchDishId: _lunchDishId,
      dinnerDishId: _dinnerDishId,
      breakfastDishPortion: _breakfastDishPortion,
      lunchDishPortion: _lunchDishPortion,
      dinnerDishPortion: _dinnerDishPortion,
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
    final deletedEntry = _persistedEntry;
    if (deletedEntry != null) {
      await PlayerLevelService(
        widget.optionRepository,
      ).revokeMealLogAward(deletedEntry);
    }
    await widget.mealLogService.deleteDay(_date);
    if (!mounted) return;
    AppFeedback.showSuccess(context, text: l10n.mealDeletedFeedback);
    Navigator.of(context).pop(true);
  }

  @override
  void dispose() {
    _disposed = true;
    _autoSaveTimer?.cancel();
    _breakfastMenuController.dispose();
    _lunchMenuController.dispose();
    _dinnerMenuController.dispose();
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
    _breakfastMenuController.text = entry?.breakfastMenu ?? '';
    _lunchMenuController.text = entry?.lunchMenu ?? '';
    _dinnerMenuController.text = entry?.dinnerMenu ?? '';
    _breakfastDishId = entry?.breakfastDishId ?? '';
    _lunchDishId = entry?.lunchDishId ?? '';
    _dinnerDishId = entry?.dinnerDishId ?? '';
    _breakfastDishPortion = _normalizedPortion(entry?.breakfastDishPortion);
    _lunchDishPortion = _normalizedPortion(entry?.lunchDishPortion);
    _dinnerDishPortion = _normalizedPortion(entry?.dinnerDishPortion);
    _persistedEntry = entry;
  }

  String _normalizedPortion(String? portion) {
    return MealCalorieEstimator.portionIds.contains(portion)
        ? portion!
        : 'regular';
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

  String _calorieCoach(
    AppLocalizations l10n,
    MealCalorieEstimate estimate,
  ) {
    if (!estimate.hasEstimate) return l10n.mealCalorieCoachEmpty;
    if (estimate.totalKcal < 1200) return l10n.mealCalorieCoachLow;
    if (estimate.totalKcal > 3000) return l10n.mealCalorieCoachHigh;
    return l10n.mealCalorieCoachSteady;
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
  final TextEditingController menuController;
  final String selectedDishId;
  final String selectedDishPortion;
  final AppLocalizations l10n;
  final bool enabled;
  final ValueChanged<double> onChanged;
  final ValueChanged<String> onMenuChanged;
  final ValueChanged<String> onDishChanged;
  final ValueChanged<String> onDishPortionChanged;

  const _MealSelectorCard({
    required this.mealKey,
    required this.label,
    required this.value,
    required this.menuController,
    required this.selectedDishId,
    required this.selectedDishPortion,
    required this.l10n,
    required this.enabled,
    required this.onChanged,
    required this.onMenuChanged,
    required this.onDishChanged,
    required this.onDishPortionChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final accent = theme.colorScheme.primary;
    final normalizedDishId = _normalizedDishId(selectedDishId);
    final normalizedPortion = _normalizedPortion(selectedDishPortion);
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
                    enabled: enabled && _nextValue(value) != value,
                    onTap: () => onChanged(_nextValue(value)),
                  ),
                  const SizedBox(height: 8),
                  _MealAdjustButton(
                    key: ValueKey('meal-$mealKey-decrement'),
                    tooltip: l10n.mealDecreaseAction,
                    icon: Icons.remove_rounded,
                    enabled: enabled && _previousValue(value) != value,
                    onTap: () => onChanged(_previousValue(value)),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            key: ValueKey('meal-$mealKey-dish'),
            initialValue: normalizedDishId,
            isExpanded: true,
            decoration: InputDecoration(
              filled: true,
              fillColor: theme.colorScheme.surfaceContainerHighest.withValues(
                alpha: 0.62,
              ),
              prefixIcon: const Icon(Icons.dinner_dining_outlined),
              labelText: l10n.mealMainDishLabel,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            items: [
              DropdownMenuItem<String>(
                value: '',
                child: Text(l10n.mealMainDishNone),
              ),
              for (final option in MealCalorieEstimator.mainDishOptions)
                DropdownMenuItem<String>(
                  value: option.id,
                  child: Text(_dishLabel(option.id)),
                ),
            ],
            onChanged: enabled ? (value) => onDishChanged(value ?? '') : null,
          ),
          if (normalizedDishId.isNotEmpty) ...[
            const SizedBox(height: 10),
            SegmentedButton<String>(
              key: ValueKey('meal-$mealKey-dish-portion'),
              segments: [
                ButtonSegment<String>(
                  value: 'small',
                  label: Text(l10n.mealDishPortionSmall),
                ),
                ButtonSegment<String>(
                  value: 'regular',
                  label: Text(l10n.mealDishPortionRegular),
                ),
                ButtonSegment<String>(
                  value: 'large',
                  label: Text(l10n.mealDishPortionLarge),
                ),
              ],
              selected: {normalizedPortion},
              onSelectionChanged: enabled
                  ? (values) => onDishPortionChanged(values.first)
                  : null,
            ),
            const SizedBox(height: 8),
            Text(
              _dishNutritionLabel(normalizedDishId, normalizedPortion),
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
          const SizedBox(height: 12),
          TextField(
            key: ValueKey('meal-$mealKey-menu'),
            controller: menuController,
            enabled: enabled,
            minLines: 1,
            maxLines: 3,
            maxLength: 120,
            textInputAction: TextInputAction.done,
            decoration: InputDecoration(
              counterText: '',
              filled: true,
              fillColor: theme.colorScheme.surfaceContainerHighest.withValues(
                alpha: 0.62,
              ),
              prefixIcon: const Icon(Icons.restaurant_menu_outlined),
              labelText: l10n.mealMenuInputLabel,
              hintText: l10n.mealMenuInputHint(label),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            onChanged: onMenuChanged,
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

  String _normalizedDishId(String value) {
    return MealCalorieEstimator.dishById(value) == null ? '' : value;
  }

  String _normalizedPortion(String value) {
    return MealCalorieEstimator.portionIds.contains(value) ? value : 'regular';
  }

  String _dishNutritionLabel(String dishId, String portionId) {
    final dish = MealCalorieEstimator.dishById(dishId);
    if (dish == null) return '';
    final nutrition = dish.nutrition.scaled(
      MealCalorieEstimator.portionFactor(portionId),
    );
    return l10n.mealDishNutritionPreview(
      nutrition.kcal,
      nutrition.protein.round(),
    );
  }

  String _dishLabel(String dishId) {
    return switch (dishId) {
      'chickenBreast' => l10n.mealDishChickenBreast,
      'eggs' => l10n.mealDishEggs,
      'tofu' => l10n.mealDishTofu,
      'grilledFish' => l10n.mealDishGrilledFish,
      'salmon' => l10n.mealDishSalmon,
      'bulgogi' => l10n.mealDishBulgogi,
      'kimchiStew' => l10n.mealDishKimchiStew,
      'doenjangStew' => l10n.mealDishDoenjangStew,
      'friedChicken' => l10n.mealDishFriedChicken,
      'chickenSalad' => l10n.mealDishChickenSalad,
      'ramen' => l10n.mealDishRamen,
      'sandwich' => l10n.mealDishSandwich,
      _ => dishId,
    };
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
