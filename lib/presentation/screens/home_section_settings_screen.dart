import 'dart:async';

import 'package:flutter/material.dart';
import 'package:football_note/gen/app_localizations.dart';

import '../../domain/repositories/option_repository.dart';
import '../models/home_hub_section_settings.dart';
import '../theme/app_theme.dart';
import '../widgets/app_background.dart';
import '../widgets/app_bar_action_button.dart';

class HomeSectionSettingsScreen extends StatefulWidget {
  final OptionRepository optionRepository;
  final HomeHubSectionSettings initialSettings;

  const HomeSectionSettingsScreen({
    super.key,
    required this.optionRepository,
    required this.initialSettings,
  });

  @override
  State<HomeSectionSettingsScreen> createState() =>
      _HomeSectionSettingsScreenState();
}

class _HomeSectionSettingsScreenState extends State<HomeSectionSettingsScreen> {
  late HomeHubSectionSettings _settings;

  @override
  void initState() {
    super.initState();
    _settings = widget.initialSettings;
  }

  void _update(
    HomeHubSectionSettings settings, {
    bool showSavedMessage = false,
  }) {
    setState(() => _settings = settings);
    unawaited(
      _saveSettings(
        settings,
        showSavedMessage: showSavedMessage,
      ),
    );
  }

  Future<void> _saveSettings(
    HomeHubSectionSettings settings, {
    required bool showSavedMessage,
  }) async {
    await widget.optionRepository.setValue(
      HomeHubSectionSettings.storageKey,
      settings.encode(),
    );
    if (!mounted || !showSavedMessage) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context)!.homeLayoutSavedMessage),
        ),
      );
  }

  void _reset() {
    _update(HomeHubSectionSettings.defaults());
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    return Scaffold(
      body: AppBackground(
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.md,
                  AppSpacing.sm,
                  AppSpacing.md,
                  AppSpacing.xs,
                ),
                child: Row(
                  children: [
                    AppBarActionButton.icon(
                      key: const ValueKey<String>(
                        'home-section-settings-back-button',
                      ),
                      icon: Icons.arrow_back,
                      tooltip: MaterialLocalizations.of(
                        context,
                      ).backButtonTooltip,
                      onPressed: () => Navigator.of(context).pop(),
                      margin: EdgeInsets.zero,
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: Text(
                        l10n.homeLayoutSettingsTitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                    AppBarActionButton.label(
                      key: const ValueKey<String>('home-section-reset-button'),
                      icon: const Icon(Icons.restart_alt),
                      label: l10n.homeLayoutSettingsReset,
                      tooltip: l10n.homeLayoutSettingsReset,
                      onPressed: _reset,
                      margin: EdgeInsets.zero,
                    ),
                  ],
                ),
              ),
              Expanded(
                child: ReorderableListView.builder(
                  key: const ValueKey<String>('home-section-settings-list'),
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.md,
                    AppSpacing.sm,
                    AppSpacing.md,
                    AppSpacing.xl,
                  ),
                  buildDefaultDragHandles: false,
                  itemCount: _settings.sections.length,
                  onReorder: (oldIndex, newIndex) {
                    _update(
                      _settings.move(oldIndex, newIndex),
                      showSavedMessage: true,
                    );
                  },
                  itemBuilder: (context, index) {
                    final setting = _settings.sections[index];
                    return _HomeSectionSettingTile(
                      key: ValueKey<String>(
                        'home-section-setting-${setting.section.storageId}',
                      ),
                      index: index,
                      setting: setting,
                      onVisibleChanged: (visible) {
                        _update(
                          _settings.setVisible(setting.section, visible),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _HomeSectionSettingTile extends StatelessWidget {
  final int index;
  final HomeHubSectionSetting setting;
  final ValueChanged<bool> onVisibleChanged;

  const _HomeSectionSettingTile({
    super.key,
    required this.index,
    required this.setting,
    required this.onVisibleChanged,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return ReorderableDelayedDragStartListener(
      key: ValueKey<String>(
        'home-section-drag-area-${setting.section.storageId}',
      ),
      index: index,
      child: Container(
        margin: const EdgeInsets.only(bottom: AppSpacing.sm),
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.sm,
          AppSpacing.sm,
          AppSpacing.xs,
          AppSpacing.sm,
        ),
        decoration: AppSurfaces.cardDecoration(scheme, theme.brightness),
        child: Row(
          children: [
            Tooltip(
              message: l10n.homeLayoutReorderTooltip,
              child: Container(
                width: 40,
                height: 40,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: scheme.primary.withValues(alpha: 0.10),
                  borderRadius: AppRadius.full,
                ),
                child: Icon(
                  Icons.drag_handle_rounded,
                  color: scheme.primary,
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Container(
              width: 40,
              height: 40,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: scheme.secondaryContainer.withValues(alpha: 0.52),
                borderRadius: AppRadius.small,
              ),
              child: Icon(
                setting.section.icon,
                color: scheme.onSecondaryContainer,
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Text(
                setting.section.label(l10n),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            Switch(
              key: ValueKey<String>(
                'home-section-visible-${setting.section.storageId}',
              ),
              value: setting.visible,
              onChanged: onVisibleChanged,
            ),
          ],
        ),
      ),
    );
  }
}

extension HomeHubSectionPresentation on HomeHubSectionId {
  IconData get icon => switch (this) {
        HomeHubSectionId.level => Icons.stars_outlined,
        HomeHubSectionId.challenge => Icons.flag_outlined,
        HomeHubSectionId.streak => Icons.local_fire_department_outlined,
        HomeHubSectionId.meal => Icons.rice_bowl_outlined,
        HomeHubSectionId.todayPlan => Icons.event_note_outlined,
        HomeHubSectionId.dailyFlow => Icons.check_circle_outline,
        HomeHubSectionId.quickActions => Icons.bolt_outlined,
        HomeHubSectionId.continueSection => Icons.playlist_play_outlined,
      };

  String label(AppLocalizations l10n) => switch (this) {
        HomeHubSectionId.level => l10n.homeSectionLevel,
        HomeHubSectionId.challenge => l10n.homeSectionChallenge,
        HomeHubSectionId.streak => l10n.homeSectionStreak,
        HomeHubSectionId.meal => l10n.homeSectionMeal,
        HomeHubSectionId.todayPlan => l10n.homeSectionTodayPlan,
        HomeHubSectionId.dailyFlow => l10n.homeSectionDailyFlow,
        HomeHubSectionId.quickActions => l10n.homeSectionQuickActions,
        HomeHubSectionId.continueSection => l10n.homeSectionContinue,
      };
}
