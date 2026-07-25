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
import '../meal_food_labels.dart';
import '../utils/app_sound_effects.dart';
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
  List<String> _breakfastFoodIds = const <String>[];
  List<String> _lunchFoodIds = const <String>[];
  List<String> _dinnerFoodIds = const <String>[];
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
      breakfastFoodIds: _foodIdsForMeal(_breakfastFoodIds, _breakfastDishId),
      lunchFoodIds: _foodIdsForMeal(_lunchFoodIds, _lunchDishId),
      dinnerFoodIds: _foodIdsForMeal(_dinnerFoodIds, _dinnerDishId),
    );
    final status = MealStatus.fromMealEntry(currentEntry);
    final calorieEstimate = MealCalorieEstimator.estimate(currentEntry);
    final dividerColor = theme.colorScheme.outline.withValues(alpha: 0.18);

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
              _buildDateSection(context: context, l10n: l10n, theme: theme),
              const SizedBox(height: 10),
              Divider(
                key: const ValueKey('meal-log-date-divider'),
                height: 1,
                color: dividerColor,
              ),
              const SizedBox(height: 12),
              _buildCoachSection(
                l10n: l10n,
                theme: theme,
                status: status,
                calorieEstimate: calorieEstimate,
                hasDietDetails: currentEntry.hasMealPlan,
              ),
              const SizedBox(height: 16),
              Divider(
                key: const ValueKey('meal-section-divider-coach-breakfast'),
                height: 1,
                color: dividerColor,
              ),
              const SizedBox(height: 18),
              _MealSelectorSection(
                mealKey: 'breakfast',
                label: l10n.mealBreakfast,
                value: _breakfastRiceBowls,
                menuController: _breakfastMenuController,
                selectedDishId: _breakfastDishId,
                selectedDishPortion: _breakfastDishPortion,
                selectedFoodIds: _breakfastFoodIds,
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
                    _breakfastFoodIds = _foodIdsForMeal(
                      _breakfastFoodIds,
                      value,
                    );
                  });
                  _scheduleAutoSave();
                },
                onDishPortionChanged: (value) {
                  setState(() => _breakfastDishPortion = value);
                  _scheduleAutoSave();
                },
                onFoodIdsChanged: (value) {
                  setState(() => _breakfastFoodIds = value);
                  _scheduleAutoSave();
                },
              ),
              const SizedBox(height: 18),
              Divider(
                key: const ValueKey('meal-section-divider-breakfast-lunch'),
                height: 1,
                color: dividerColor,
              ),
              const SizedBox(height: 18),
              _MealSelectorSection(
                mealKey: 'lunch',
                label: l10n.mealLunch,
                value: _lunchRiceBowls,
                menuController: _lunchMenuController,
                selectedDishId: _lunchDishId,
                selectedDishPortion: _lunchDishPortion,
                selectedFoodIds: _lunchFoodIds,
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
                    _lunchFoodIds = _foodIdsForMeal(_lunchFoodIds, value);
                  });
                  _scheduleAutoSave();
                },
                onDishPortionChanged: (value) {
                  setState(() => _lunchDishPortion = value);
                  _scheduleAutoSave();
                },
                onFoodIdsChanged: (value) {
                  setState(() => _lunchFoodIds = value);
                  _scheduleAutoSave();
                },
              ),
              const SizedBox(height: 18),
              Divider(
                key: const ValueKey('meal-section-divider-lunch-dinner'),
                height: 1,
                color: dividerColor,
              ),
              const SizedBox(height: 18),
              _MealSelectorSection(
                mealKey: 'dinner',
                label: l10n.mealDinner,
                value: _dinnerRiceBowls,
                menuController: _dinnerMenuController,
                selectedDishId: _dinnerDishId,
                selectedDishPortion: _dinnerDishPortion,
                selectedFoodIds: _dinnerFoodIds,
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
                    _dinnerFoodIds = _foodIdsForMeal(_dinnerFoodIds, value);
                  });
                  _scheduleAutoSave();
                },
                onDishPortionChanged: (value) {
                  setState(() => _dinnerDishPortion = value);
                  _scheduleAutoSave();
                },
                onFoodIdsChanged: (value) {
                  setState(() => _dinnerFoodIds = value);
                  _scheduleAutoSave();
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDateSection({
    required BuildContext context,
    required AppLocalizations l10n,
    required ThemeData theme,
  }) {
    final dateText = DateFormat.yMMMMd(
      Localizations.localeOf(context).toString(),
    ).add_E().format(_date);
    return Semantics(
      button: true,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          key: const ValueKey('meal-log-date-section'),
          onTap: _pickDate,
          borderRadius: BorderRadius.circular(8),
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 56),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Icon(
                    Icons.calendar_today_outlined,
                    color: theme.colorScheme.primary,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l10n.mealLogDateLabel,
                          style: theme.textTheme.labelLarge?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          dateText,
                          style: theme.textTheme.bodyLarge?.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Icon(
                    Icons.chevron_right_rounded,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCoachSection({
    required AppLocalizations l10n,
    required ThemeData theme,
    required MealStatus status,
    required MealCalorieEstimate calorieEstimate,
    required bool hasDietDetails,
  }) {
    return Padding(
      key: const ValueKey('meal-coach-summary-section'),
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Theme(
        data: theme.copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          key: ValueKey('meal-coach-details-$hasDietDetails'),
          initiallyExpanded: hasDietDetails,
          maintainState: true,
          tilePadding: EdgeInsets.zero,
          childrenPadding: const EdgeInsets.only(top: 2),
          title: Text(
            _headline(l10n, status),
            key: const ValueKey('meal-coach-headline'),
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _body(l10n, status),
                  key: const ValueKey('meal-coach-body'),
                  style: theme.textTheme.bodyMedium,
                ),
                const SizedBox(height: 10),
                _MealCoachInfoList(
                  items: [
                    _MealCoachInfoItem(
                      key: const ValueKey('meal-coach-expected-row'),
                      icon: Icons.flag_outlined,
                      label: l10n.mealAverageExpectedValue(
                        _formatBowls(MealLogService.expectedBowlsPerDay),
                      ),
                    ),
                    _MealCoachInfoItem(
                      key: const ValueKey('meal-coach-actual-row'),
                      icon: Icons.rice_bowl_outlined,
                      label: l10n.mealAverageActualValue(
                        _formatBowls(status.totalRiceBowls),
                      ),
                    ),
                    _MealCoachInfoItem(
                      key: const ValueKey('meal-coach-calorie-row'),
                      icon: Icons.local_fire_department_outlined,
                      label: calorieEstimate.hasEstimate
                          ? l10n.mealCalorieEstimateValue(
                              calorieEstimate.totalKcal,
                            )
                          : l10n.mealCalorieEstimateEmpty,
                    ),
                    if (calorieEstimate.hasNutrition)
                      _MealCoachInfoItem(
                        key: const ValueKey('meal-coach-nutrition-row'),
                        icon: Icons.monitor_heart_outlined,
                        label: l10n.mealNutritionEstimateValue(
                          calorieEstimate.totalCarbs.round(),
                          calorieEstimate.totalProtein.round(),
                          calorieEstimate.totalFat.round(),
                        ),
                      ),
                    _MealCoachInfoItem(
                      key: const ValueKey('meal-coach-xp-row'),
                      icon: Icons.bolt_outlined,
                      label: _xpLabel(l10n, status),
                    ),
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
          ],
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
    final previousCompletedMeals = previousEntry == null
        ? 0
        : MealStatus.fromMealEntry(previousEntry).completedMeals;
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
      breakfastFoodIds: _foodIdsForMeal(_breakfastFoodIds, _breakfastDishId),
      lunchFoodIds: _foodIdsForMeal(_lunchFoodIds, _lunchDishId),
      dinnerFoodIds: _foodIdsForMeal(_dinnerFoodIds, _dinnerDishId),
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
      final updatedStatus = MealStatus.fromMealEntry(entry);
      if (previousCompletedMeals < 3 && updatedStatus.completedMeals >= 3) {
        AppSoundEffects.playMissionComplete();
      }
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
    _breakfastFoodIds = _foodIdsForMeal(
      _normalizedFoodIds(entry?.breakfastFoodIds),
      _breakfastDishId,
    );
    _lunchFoodIds = _foodIdsForMeal(
      _normalizedFoodIds(entry?.lunchFoodIds),
      _lunchDishId,
    );
    _dinnerFoodIds = _foodIdsForMeal(
      _normalizedFoodIds(entry?.dinnerFoodIds),
      _dinnerDishId,
    );
    _persistedEntry = entry;
  }

  String _normalizedPortion(String? portion) {
    return MealCalorieEstimator.portionIds.contains(portion)
        ? portion!
        : 'regular';
  }

  List<String> _normalizedFoodIds(List<String>? foodIds) {
    if (foodIds == null || foodIds.isEmpty) return const <String>[];
    final seen = <String>{};
    final normalized = <String>[];
    for (final id in foodIds) {
      if (MealCalorieEstimator.foodById(id) == null || !seen.add(id)) {
        continue;
      }
      normalized.add(id);
    }
    return List<String>.unmodifiable(normalized);
  }

  List<String> _foodIdsForMeal(List<String> foodIds, String dishId) {
    final normalizedDishId = dishId.trim();
    if (normalizedDishId.isEmpty) return foodIds;
    return foodIds
        .where((id) => id != normalizedDishId)
        .toList(growable: false);
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

class _MealSelectorSection extends StatelessWidget {
  final String mealKey;
  final String label;
  final double value;
  final TextEditingController menuController;
  final String selectedDishId;
  final String selectedDishPortion;
  final List<String> selectedFoodIds;
  final AppLocalizations l10n;
  final bool enabled;
  final ValueChanged<double> onChanged;
  final ValueChanged<String> onMenuChanged;
  final ValueChanged<String> onDishChanged;
  final ValueChanged<String> onDishPortionChanged;
  final ValueChanged<List<String>> onFoodIdsChanged;

  const _MealSelectorSection({
    required this.mealKey,
    required this.label,
    required this.value,
    required this.menuController,
    required this.selectedDishId,
    required this.selectedDishPortion,
    required this.selectedFoodIds,
    required this.l10n,
    required this.enabled,
    required this.onChanged,
    required this.onMenuChanged,
    required this.onDishChanged,
    required this.onDishPortionChanged,
    required this.onFoodIdsChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final accent = theme.colorScheme.primary;
    final normalizedDishId = _normalizedDishId(selectedDishId);
    final normalizedPortion = _normalizedPortion(selectedDishPortion);
    final normalizedFoodIds = _normalizedFoodIds(
      selectedFoodIds.where((id) => id != normalizedDishId),
    );
    final hasDietDetails = normalizedDishId.isNotEmpty ||
        normalizedFoodIds.isNotEmpty ||
        menuController.text.trim().isNotEmpty;
    return Padding(
      key: ValueKey('meal-$mealKey-section'),
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.rice_bowl_outlined, color: accent, size: 22),
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
          Theme(
            data: theme.copyWith(dividerColor: Colors.transparent),
            child: ExpansionTile(
              key: PageStorageKey<String>('meal-$mealKey-diet-expansion'),
              initiallyExpanded: hasDietDetails,
              maintainState: true,
              tilePadding: EdgeInsets.zero,
              childrenPadding: const EdgeInsets.only(top: 6),
              leading: const Icon(Icons.restaurant_menu_outlined),
              title: Text(
                l10n.mealDietDetailsTitle,
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w900,
                ),
              ),
              subtitle: Text(
                hasDietDetails
                    ? l10n.mealDietDetailsFilled
                    : l10n.mealDietDetailsHint,
              ),
              children: [
                _MainDishSelector(
                  mealKey: mealKey,
                  l10n: l10n,
                  selectedDishId: normalizedDishId,
                  enabled: enabled,
                  onDishChanged: onDishChanged,
                ),
                if (normalizedDishId.isNotEmpty) const SizedBox(height: 8),
                if (normalizedDishId.isNotEmpty) ...[
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
                _CompanionFoodSelector(
                  mealKey: mealKey,
                  l10n: l10n,
                  selectedDishId: normalizedDishId,
                  selectedFoodIds: normalizedFoodIds,
                  enabled: enabled,
                  onChanged: onFoodIdsChanged,
                ),
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
                    fillColor: theme.colorScheme.surfaceContainerHighest
                        .withValues(alpha: 0.62),
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

  List<String> _normalizedFoodIds(Iterable<String> value) {
    final seen = <String>{};
    final ids = <String>[];
    for (final id in value) {
      if (MealCalorieEstimator.foodById(id) == null || !seen.add(id)) {
        continue;
      }
      ids.add(id);
    }
    return List<String>.unmodifiable(ids);
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
}

class _MainDishSelector extends StatelessWidget {
  final String mealKey;
  final AppLocalizations l10n;
  final String selectedDishId;
  final bool enabled;
  final ValueChanged<String> onDishChanged;

  const _MainDishSelector({
    required this.mealKey,
    required this.l10n,
    required this.selectedDishId,
    required this.enabled,
    required this.onDishChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final selectedDish = MealCalorieEstimator.dishById(selectedDishId);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                l10n.mealMainDishLabel,
                style: theme.textTheme.labelLarge?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            OutlinedButton.icon(
              key: ValueKey('meal-$mealKey-dish'),
              onPressed: enabled ? () => _openMainDishSheet(context) : null,
              icon: const Icon(Icons.search_rounded),
              label: Text(
                selectedDish == null
                    ? l10n.mealMainDishChooseAction
                    : l10n.mealMainDishEditAction,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        if (selectedDish == null)
          Text(
            l10n.mealMainDishNone,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          )
        else
          InputChip(
            key: ValueKey('meal-$mealKey-dish-chip'),
            avatar: const Icon(Icons.dinner_dining_outlined, size: 18),
            label: Text(mealFoodLabel(l10n, selectedDish.id)),
            onDeleted: enabled ? () => onDishChanged('') : null,
          ),
      ],
    );
  }

  Future<void> _openMainDishSheet(BuildContext context) async {
    final next = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (context) {
        return _MainDishSheet(selectedDishId: selectedDishId);
      },
    );
    if (next == null) return;
    onDishChanged(next);
  }
}

class _MainDishSheet extends StatefulWidget {
  final String selectedDishId;

  const _MainDishSheet({required this.selectedDishId});

  @override
  State<_MainDishSheet> createState() => _MainDishSheetState();
}

class _MainDishSheetState extends State<_MainDishSheet> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final options = _filteredOptions(l10n);
    return FractionallySizedBox(
      heightFactor: 0.88,
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.outlineVariant,
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
              ),
              const SizedBox(height: 14),
              Text(
                l10n.mealMainDishSheetTitle,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                key: const ValueKey('meal-main-dish-search'),
                decoration: InputDecoration(
                  prefixIcon: const Icon(Icons.search_rounded),
                  labelText: l10n.mealFoodSearchLabel,
                  hintText: l10n.mealFoodSearchHint,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                onChanged: (value) => setState(() => _query = value),
              ),
              const SizedBox(height: 10),
              Expanded(
                child: ListView.separated(
                  itemCount: options.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final option = options[index];
                    final selected = option.id == widget.selectedDishId;
                    return ListTile(
                      key: ValueKey('meal-main-dish-option-${option.id}'),
                      leading: Icon(
                        selected
                            ? Icons.radio_button_checked
                            : Icons.radio_button_unchecked,
                        color: selected ? theme.colorScheme.primary : null,
                      ),
                      title: Text(mealFoodLabel(l10n, option.id)),
                      subtitle: Text(
                        l10n.mealFoodOptionSubtitle(
                          mealFoodCategoryLabel(l10n, option.category),
                          l10n.mealFoodNutritionLine(
                            option.kcal,
                            option.carbs.round(),
                            option.protein.round(),
                            option.fat.round(),
                          ),
                        ),
                      ),
                      onTap: () => Navigator.of(context).pop(option.id),
                    );
                  },
                ),
              ),
              const SizedBox(height: 10),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  key: const ValueKey('meal-main-dish-clear'),
                  onPressed: () => Navigator.of(context).pop(''),
                  child: Text(l10n.mealMainDishClearAction),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  List<MealFoodOption> _filteredOptions(AppLocalizations l10n) {
    final query = _query.trim().toLowerCase();
    return MealCalorieEstimator.mainDishOptions.where((option) {
      if (query.isEmpty) return true;
      final label = mealFoodLabel(l10n, option.id).toLowerCase();
      return label.contains(query) || option.id.toLowerCase().contains(query);
    }).toList(growable: false);
  }
}

class _CompanionFoodSelector extends StatelessWidget {
  final String mealKey;
  final AppLocalizations l10n;
  final String selectedDishId;
  final List<String> selectedFoodIds;
  final bool enabled;
  final ValueChanged<List<String>> onChanged;

  const _CompanionFoodSelector({
    required this.mealKey,
    required this.l10n,
    required this.selectedDishId,
    required this.selectedFoodIds,
    required this.enabled,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final selectedIds = selectedFoodIds
        .where((id) => MealCalorieEstimator.foodById(id) != null)
        .toList(growable: false);
    final nutrition = MealCalorieEstimator.nutritionForFoodIds(selectedIds);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                l10n.mealCompanionFoodsLabel,
                style: theme.textTheme.labelLarge?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            OutlinedButton.icon(
              key: ValueKey('meal-$mealKey-foods'),
              onPressed: enabled ? () => _openFoodSheet(context) : null,
              icon: const Icon(Icons.playlist_add_check_rounded),
              label: Text(
                selectedIds.isEmpty
                    ? l10n.mealCompanionFoodsChooseAction
                    : l10n.mealCompanionFoodsEditAction,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        if (selectedIds.isEmpty)
          Text(
            l10n.mealCompanionFoodsEmpty,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          )
        else ...[
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final id in selectedIds)
                InputChip(
                  key: ValueKey('meal-$mealKey-food-chip-$id'),
                  label: Text(mealFoodLabel(l10n, id)),
                  onDeleted: enabled
                      ? () => onChanged(
                            selectedIds
                                .where((selectedId) => selectedId != id)
                                .toList(growable: false),
                          )
                      : null,
                ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            l10n.mealSelectedFoodsNutritionPreview(
              nutrition.kcal,
              nutrition.protein.round(),
            ),
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ],
    );
  }

  Future<void> _openFoodSheet(BuildContext context) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (context) {
        return _CompanionFoodSheet(
          selectedDishId: selectedDishId,
          selectedFoodIds: selectedFoodIds,
          onChanged: onChanged,
        );
      },
    );
  }
}

class _CompanionFoodSheet extends StatefulWidget {
  final String selectedDishId;
  final List<String> selectedFoodIds;
  final ValueChanged<List<String>> onChanged;

  const _CompanionFoodSheet({
    required this.selectedDishId,
    required this.selectedFoodIds,
    required this.onChanged,
  });

  @override
  State<_CompanionFoodSheet> createState() => _CompanionFoodSheetState();
}

class _CompanionFoodSheetState extends State<_CompanionFoodSheet> {
  late final Set<String> _selectedFoodIds = widget.selectedFoodIds
      .where((id) => MealCalorieEstimator.foodById(id) != null)
      .toSet();
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final options = _filteredOptions(l10n);
    return FractionallySizedBox(
      heightFactor: 0.88,
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.outlineVariant,
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
              ),
              const SizedBox(height: 14),
              Text(
                l10n.mealCompanionFoodsSheetTitle,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                key: const ValueKey('meal-food-search'),
                decoration: InputDecoration(
                  prefixIcon: const Icon(Icons.search_rounded),
                  labelText: l10n.mealFoodSearchLabel,
                  hintText: l10n.mealFoodSearchHint,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                onChanged: (value) => setState(() => _query = value),
              ),
              const SizedBox(height: 10),
              Expanded(
                child: ListView.separated(
                  itemCount: options.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final option = options[index];
                    final selected = _selectedFoodIds.contains(option.id);
                    return CheckboxListTile(
                      key: ValueKey('meal-food-option-${option.id}'),
                      value: selected,
                      title: Text(mealFoodLabel(l10n, option.id)),
                      subtitle: Text(
                        l10n.mealFoodOptionSubtitle(
                          mealFoodCategoryLabel(l10n, option.category),
                          l10n.mealFoodNutritionLine(
                            option.kcal,
                            option.carbs.round(),
                            option.protein.round(),
                            option.fat.round(),
                          ),
                        ),
                      ),
                      controlAffinity: ListTileControlAffinity.leading,
                      onChanged: (_) => _toggle(option.id),
                    );
                  },
                ),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  TextButton(
                    onPressed:
                        _selectedFoodIds.isEmpty ? null : _clearSelection,
                    child: Text(l10n.mealFoodSelectionClear),
                  ),
                  const Spacer(),
                  FilledButton(
                    key: const ValueKey('meal-food-sheet-done'),
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                    child: Text(l10n.mealFoodSelectionDone),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  List<MealFoodOption> _filteredOptions(AppLocalizations l10n) {
    final query = _query.trim().toLowerCase();
    return MealCalorieEstimator.companionFoodOptions.where((option) {
      if (option.id == widget.selectedDishId) return false;
      if (query.isEmpty) return true;
      final label = mealFoodLabel(l10n, option.id).toLowerCase();
      return label.contains(query) || option.id.toLowerCase().contains(query);
    }).toList(growable: false);
  }

  void _toggle(String id) {
    setState(() {
      if (!_selectedFoodIds.add(id)) {
        _selectedFoodIds.remove(id);
      }
    });
    widget.onChanged(_orderedSelection());
  }

  void _clearSelection() {
    setState(_selectedFoodIds.clear);
    widget.onChanged(const <String>[]);
  }

  List<String> _orderedSelection() {
    return MealCalorieEstimator.companionFoodOptions
        .where(
          (option) =>
              option.id != widget.selectedDishId &&
              _selectedFoodIds.contains(option.id),
        )
        .map((option) => option.id)
        .toList(growable: false);
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

class _MealCoachInfoItem {
  final Key key;
  final IconData icon;
  final String label;

  const _MealCoachInfoItem({
    required this.key,
    required this.icon,
    required this.label,
  });
}

class _MealCoachInfoList extends StatelessWidget {
  final List<_MealCoachInfoItem> items;

  const _MealCoachInfoList({required this.items});

  @override
  Widget build(BuildContext context) {
    final dividerColor =
        Theme.of(context).colorScheme.outline.withValues(alpha: 0.18);
    return Column(
      children: [
        for (var i = 0; i < items.length; i++) ...[
          _MealCoachInfoRow(
            key: items[i].key,
            icon: items[i].icon,
            label: items[i].label,
          ),
          if (i < items.length - 1)
            Divider(
              key: ValueKey('meal-coach-summary-divider-$i'),
              height: 1,
              color: dividerColor,
            ),
        ],
      ],
    );
  }
}

class _MealCoachInfoRow extends StatelessWidget {
  final IconData icon;
  final String label;

  const _MealCoachInfoRow({
    super.key,
    required this.icon,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: theme.colorScheme.primary),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              label,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w800,
                height: 1.35,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
