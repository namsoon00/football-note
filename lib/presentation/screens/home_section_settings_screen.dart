import 'dart:async';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:football_note/gen/app_localizations.dart';

import '../../domain/repositories/option_repository.dart';
import '../models/home_hub_section_settings.dart';
import '../theme/app_theme.dart';
import '../widgets/app_background.dart';
import '../widgets/app_bar_action_button.dart';

const _homeSectionReorderDelay = Duration(milliseconds: 180);
const _homeSectionPressFeedbackDuration = Duration(milliseconds: 90);

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
                  proxyDecorator: _reorderProxyDecorator,
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

  Widget _reorderProxyDecorator(
    Widget child,
    int index,
    Animation<double> animation,
  ) {
    final scheme = Theme.of(context).colorScheme;
    return AnimatedBuilder(
      animation: animation,
      child: child,
      builder: (context, child) {
        final lift = Curves.easeOutCubic.transform(animation.value);
        return Transform.scale(
          scale: 1 + (0.025 * lift),
          child: Material(
            color: Colors.transparent,
            elevation: 10 + (10 * lift),
            shadowColor: scheme.primary.withValues(alpha: 0.34),
            borderRadius: AppRadius.surface,
            child: child,
          ),
        );
      },
    );
  }
}

class _HomeSectionSettingTile extends StatefulWidget {
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
  State<_HomeSectionSettingTile> createState() =>
      _HomeSectionSettingTileState();
}

class _HomeSectionSettingTileState extends State<_HomeSectionSettingTile> {
  bool _pressed = false;

  void _setPressed(bool value) {
    if (_pressed == value) return;
    setState(() => _pressed = value);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final setting = widget.setting;
    return _FastReorderableDelayedDragStartListener(
      key: ValueKey<String>(
        'home-section-drag-area-${setting.section.storageId}',
      ),
      index: widget.index,
      child: Listener(
        onPointerDown: (_) => _setPressed(true),
        onPointerCancel: (_) => _setPressed(false),
        onPointerUp: (_) => _setPressed(false),
        child: MouseRegion(
          cursor: SystemMouseCursors.grab,
          child: AnimatedScale(
            duration: _homeSectionPressFeedbackDuration,
            curve: Curves.easeOutCubic,
            scale: _pressed ? 1.012 : 1,
            child: AnimatedContainer(
              key: ValueKey<String>(
                'home-section-setting-surface-${setting.section.storageId}',
              ),
              duration: _homeSectionPressFeedbackDuration,
              curve: Curves.easeOutCubic,
              margin: const EdgeInsets.only(bottom: AppSpacing.sm),
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.sm,
                AppSpacing.sm,
                AppSpacing.xs,
                AppSpacing.sm,
              ),
              decoration: _tileDecoration(
                scheme,
                theme.brightness,
                pressed: _pressed,
              ),
              child: Row(
                children: [
                  AnimatedContainer(
                    key: ValueKey<String>(
                      'home-section-drag-handle-${setting.section.storageId}',
                    ),
                    duration: _homeSectionPressFeedbackDuration,
                    curve: Curves.easeOutCubic,
                    width: 40,
                    height: 40,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: _pressed
                          ? scheme.primary
                          : scheme.primary.withValues(alpha: 0.10),
                      borderRadius: AppRadius.full,
                      boxShadow: _pressed
                          ? <BoxShadow>[
                              BoxShadow(
                                color: scheme.primary.withValues(alpha: 0.30),
                                blurRadius: 14,
                                offset: const Offset(0, 5),
                              ),
                            ]
                          : null,
                    ),
                    child: Icon(
                      Icons.drag_handle_rounded,
                      color: _pressed ? scheme.onPrimary : scheme.primary,
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
                    onChanged: widget.onVisibleChanged,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  BoxDecoration _tileDecoration(
    ColorScheme scheme,
    Brightness brightness, {
    required bool pressed,
  }) {
    final base = AppSurfaces.cardDecoration(scheme, brightness);
    if (!pressed) return base;
    final baseColor = base.color ?? AppSurfaces.cardColor(scheme, brightness);
    return base.copyWith(
      color: Color.alphaBlend(
        scheme.primary.withValues(
          alpha: brightness == Brightness.dark ? 0.22 : 0.10,
        ),
        baseColor,
      ),
      border: Border.all(
        color: scheme.primary.withValues(alpha: 0.76),
        width: 2,
      ),
      boxShadow: <BoxShadow>[
        BoxShadow(
          color: scheme.primary.withValues(
            alpha: brightness == Brightness.dark ? 0.34 : 0.22,
          ),
          blurRadius: 24,
          offset: const Offset(0, 10),
        ),
        ...?base.boxShadow,
      ],
    );
  }
}

class _FastReorderableDelayedDragStartListener
    extends ReorderableDelayedDragStartListener {
  const _FastReorderableDelayedDragStartListener({
    super.key,
    required super.child,
    required super.index,
  });

  @override
  MultiDragGestureRecognizer createRecognizer() {
    return DelayedMultiDragGestureRecognizer(
      delay: _homeSectionReorderDelay,
      debugOwner: this,
    );
  }
}

extension HomeHubSectionPresentation on HomeHubSectionId {
  IconData get icon => switch (this) {
        HomeHubSectionId.level => Icons.stars_outlined,
        HomeHubSectionId.challenge => Icons.flag_outlined,
        HomeHubSectionId.streak => Icons.local_fire_department_outlined,
        HomeHubSectionId.meal => Icons.rice_bowl_outlined,
        HomeHubSectionId.dailyFlow => Icons.check_circle_outline,
        HomeHubSectionId.quickActions => Icons.bolt_outlined,
        HomeHubSectionId.continueSection => Icons.playlist_play_outlined,
      };

  String label(AppLocalizations l10n) => switch (this) {
        HomeHubSectionId.level => l10n.homeSectionLevel,
        HomeHubSectionId.challenge => l10n.homeSectionChallenge,
        HomeHubSectionId.streak => l10n.homeSectionStreak,
        HomeHubSectionId.meal => l10n.homeSectionMeal,
        HomeHubSectionId.dailyFlow => l10n.homeSectionDailyFlow,
        HomeHubSectionId.quickActions => l10n.homeSectionQuickActions,
        HomeHubSectionId.continueSection => l10n.homeSectionContinue,
      };
}
