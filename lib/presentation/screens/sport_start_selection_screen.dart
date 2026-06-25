import 'package:flutter/material.dart';

import '../../domain/entities/sport_definition.dart';
import '../../gen/app_localizations.dart';
import '../theme/app_theme.dart';
import '../widgets/app_background.dart';

class SportStartSelectionScreen extends StatefulWidget {
  final ValueChanged<String> onSelected;

  const SportStartSelectionScreen({super.key, required this.onSelected});

  @override
  State<SportStartSelectionScreen> createState() =>
      _SportStartSelectionScreenState();
}

class _SportStartSelectionScreenState extends State<SportStartSelectionScreen> {
  String? _selectedSportId;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final choices = _buildSportChoices(l10n);
    final selectedSportId = _selectedSportId;
    final selectedChoice =
        choices.where((choice) => choice.id == selectedSportId).firstOrNull;

    return Scaffold(
      body: AppBackground(
        child: SafeArea(
          child: Column(
            children: [
              Expanded(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final listLayout = constraints.maxWidth < 560;
                    final crossAxisCount =
                        listLayout ? 1 : (constraints.maxWidth >= 920 ? 4 : 2);
                    final aspectRatio =
                        listLayout ? 4.2 : (crossAxisCount == 4 ? 1.02 : 1.82);
                    return SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(
                        AppSpacing.lg,
                        AppSpacing.xxl,
                        AppSpacing.lg,
                        AppSpacing.xl,
                      ),
                      child: Center(
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 960),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              _SportSelectionHeader(
                                title: l10n.startupSportTitle,
                                subtitle: l10n.startupSportSubtitle,
                              ),
                              const SizedBox(height: AppSpacing.xl),
                              GridView.builder(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                itemCount: choices.length,
                                gridDelegate:
                                    SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: crossAxisCount,
                                  crossAxisSpacing: AppSpacing.sm,
                                  mainAxisSpacing: AppSpacing.sm,
                                  childAspectRatio: aspectRatio,
                                ),
                                itemBuilder: (context, index) {
                                  final choice = choices[index];
                                  return _SportChoiceCard(
                                    index: index,
                                    choice: choice,
                                    selected: selectedSportId == choice.id,
                                    listLayout: listLayout,
                                    onTap: () => setState(
                                      () => _selectedSportId = choice.id,
                                    ),
                                  );
                                },
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
              _SportStartDock(
                selectedChoice: selectedChoice,
                label: l10n.startupSportAction,
                onPressed: selectedSportId == null
                    ? null
                    : () => widget.onSelected(selectedSportId),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SportSelectionPalette {
  static Color card(ColorScheme scheme, Brightness brightness) {
    return AppSurfaces.cardColor(scheme, brightness);
  }

  static Color raised(ColorScheme scheme, Brightness brightness) {
    return AppSurfaces.subtleColor(scheme, brightness);
  }

  static Color border(ColorScheme scheme, Brightness brightness) {
    return AppSurfaces.borderColor(scheme, brightness);
  }

  static Color muted(ColorScheme scheme) {
    return scheme.onSurfaceVariant;
  }

  static Color idleFill(ColorScheme scheme, Brightness brightness) {
    return brightness == Brightness.dark
        ? Colors.white.withValues(alpha: 0.04)
        : scheme.surfaceContainerHighest.withValues(alpha: 0.72);
  }
}

class _SportSelectionHeader extends StatelessWidget {
  final String title;
  final String subtitle;

  const _SportSelectionHeader({
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 52,
          height: 3,
          decoration: BoxDecoration(
            color: scheme.primary,
            borderRadius: AppRadius.full,
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        Text(
          title,
          style: theme.textTheme.headlineMedium?.copyWith(
            color: scheme.onSurface,
            fontWeight: FontWeight.w900,
            height: 1.12,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 640),
          child: Text(
            subtitle,
            style: theme.textTheme.bodyLarge?.copyWith(
              color: _SportSelectionPalette.muted(scheme),
              height: 1.48,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}

class _SportChoiceCard extends StatelessWidget {
  final int index;
  final _SportChoice choice;
  final bool selected;
  final bool listLayout;
  final VoidCallback onTap;

  const _SportChoiceCard({
    required this.index,
    required this.choice,
    required this.selected,
    required this.listLayout,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final brightness = scheme.brightness;
    final borderColor = selected
        ? choice.color.withValues(alpha: 0.78)
        : _SportSelectionPalette.border(scheme, brightness);
    final background = selected
        ? Color.lerp(
            _SportSelectionPalette.raised(scheme, brightness),
            choice.color,
            brightness == Brightness.dark ? 0.12 : 0.08,
          )!
        : _SportSelectionPalette.card(scheme, brightness);
    return Semantics(
      button: true,
      selected: selected,
      label: choice.title,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOutCubic,
        decoration: BoxDecoration(
          color: background,
          borderRadius: AppRadius.small,
          border: Border.all(color: borderColor, width: selected ? 1.4 : 1),
        ),
        child: Material(
          color: Colors.transparent,
          borderRadius: AppRadius.small,
          child: InkWell(
            key: ValueKey('startup-sport-choice-${choice.id}'),
            borderRadius: AppRadius.small,
            onTap: onTap,
            child: Stack(
              children: [
                PositionedDirectional(
                  start: 0,
                  top: 0,
                  bottom: 0,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    width: selected ? 4 : 2,
                    decoration: BoxDecoration(
                      color: choice.color.withValues(
                        alpha: selected ? 0.95 : 0.42,
                      ),
                      borderRadius: const BorderRadiusDirectional.only(
                        topStart: Radius.circular(AppRadius.xs),
                        bottomStart: Radius.circular(AppRadius.xs),
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: EdgeInsets.all(listLayout ? AppSpacing.md : 18),
                  child: listLayout
                      ? _buildListContent(context, scheme)
                      : _buildTileContent(context, scheme),
                ),
                PositionedDirectional(
                  top: AppSpacing.sm,
                  end: AppSpacing.sm,
                  child: Text(
                    (index + 1).toString().padLeft(2, '0'),
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: scheme.onSurface.withValues(alpha: 0.36),
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0,
                        ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTileContent(BuildContext context, ColorScheme scheme) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _SportIconMark(choice: choice, selected: selected),
            const Spacer(),
            Padding(
              padding: const EdgeInsetsDirectional.only(top: AppSpacing.xl),
              child: _SportSelectionMark(
                selected: selected,
                color: choice.color,
              ),
            ),
          ],
        ),
        const Spacer(),
        Text(
          choice.title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: theme.textTheme.titleLarge?.copyWith(
            color: scheme.onSurface,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          choice.description,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: theme.textTheme.bodySmall?.copyWith(
            color: _SportSelectionPalette.muted(scheme),
            height: 1.35,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildListContent(BuildContext context, ColorScheme scheme) {
    final theme = Theme.of(context);
    return Row(
      children: [
        _SportIconMark(choice: choice, selected: selected),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                choice.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.titleMedium?.copyWith(
                  color: scheme.onSurface,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: AppSpacing.xxs),
              Text(
                choice.description,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: _SportSelectionPalette.muted(scheme),
                  height: 1.28,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Padding(
          padding: const EdgeInsetsDirectional.only(end: AppSpacing.lg),
          child: _SportSelectionMark(selected: selected, color: choice.color),
        ),
      ],
    );
  }
}

class _SportIconMark extends StatelessWidget {
  final _SportChoice choice;
  final bool selected;

  const _SportIconMark({
    required this.choice,
    required this.selected,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final brightness = scheme.brightness;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeOutCubic,
      width: 42,
      height: 42,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: selected
            ? choice.color.withValues(alpha: 0.20)
            : _SportSelectionPalette.idleFill(scheme, brightness),
        borderRadius: AppRadius.small,
        border: Border.all(
          color: selected
              ? choice.color.withValues(alpha: 0.54)
              : _SportSelectionPalette.border(scheme, brightness),
        ),
      ),
      child: Icon(choice.icon, color: choice.color, size: 23),
    );
  }
}

class _SportSelectionMark extends StatelessWidget {
  final bool selected;
  final Color color;

  const _SportSelectionMark({
    required this.selected,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final brightness = scheme.brightness;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeOutCubic,
      width: 24,
      height: 24,
      decoration: BoxDecoration(
        color: selected
            ? color
            : _SportSelectionPalette.idleFill(scheme, brightness),
        borderRadius: BorderRadius.circular(AppRadius.xs),
        border: Border.all(
          color: selected
              ? color
              : _SportSelectionPalette.border(scheme, brightness),
          width: 1.2,
        ),
      ),
      child: selected
          ? const Icon(Icons.check_rounded, size: 16, color: Colors.white)
          : null,
    );
  }
}

class _SportStartDock extends StatelessWidget {
  final _SportChoice? selectedChoice;
  final String label;
  final VoidCallback? onPressed;

  const _SportStartDock({
    required this.selectedChoice,
    required this.label,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final choice = selectedChoice;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final brightness = scheme.brightness;
    final background = choice?.color ?? theme.colorScheme.primary;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: _SportSelectionPalette.card(scheme, brightness),
        border: Border(
          top: BorderSide(
            color: _SportSelectionPalette.border(scheme, brightness),
          ),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg,
          AppSpacing.sm,
          AppSpacing.lg,
          AppSpacing.md,
        ),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 960),
            child: SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                key: const ValueKey('startup-sport-start-button'),
                onPressed: onPressed,
                icon: Icon(
                  choice == null ? Icons.arrow_forward_rounded : choice.icon,
                ),
                style: FilledButton.styleFrom(
                  backgroundColor: background,
                  disabledBackgroundColor:
                      scheme.onSurface.withValues(alpha: 0.08),
                  disabledForegroundColor:
                      scheme.onSurface.withValues(alpha: 0.38),
                  foregroundColor: Colors.white,
                  minimumSize:
                      const Size.fromHeight(AppSizes.primaryButtonHeight),
                  shape: RoundedRectangleBorder(borderRadius: AppRadius.small),
                ),
                label:
                    Text(label, maxLines: 1, overflow: TextOverflow.ellipsis),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _SportChoice {
  final String id;
  final String title;
  final String description;
  final IconData icon;
  final Color color;

  const _SportChoice({
    required this.id,
    required this.title,
    required this.description,
    required this.icon,
    required this.color,
  });
}

List<_SportChoice> _buildSportChoices(AppLocalizations l10n) {
  return <_SportChoice>[
    _SportChoice(
      id: SportCatalog.footballId,
      title: l10n.sportFootball,
      description: l10n.startupSportFootballDescription,
      icon: Icons.sports_soccer_rounded,
      color: const Color(0xFF4F8BFF),
    ),
    _SportChoice(
      id: SportCatalog.baseballId,
      title: l10n.sportBaseball,
      description: l10n.startupSportBaseballDescription,
      icon: Icons.sports_baseball,
      color: const Color(0xFFE5A449),
    ),
    _SportChoice(
      id: SportCatalog.basketballId,
      title: l10n.sportBasketball,
      description: l10n.startupSportBasketballDescription,
      icon: Icons.sports_basketball_rounded,
      color: const Color(0xFFFF6B5F),
    ),
    _SportChoice(
      id: SportCatalog.tennisId,
      title: l10n.sportTennis,
      description: l10n.startupSportTennisDescription,
      icon: Icons.sports_tennis_rounded,
      color: const Color(0xFF5BBF7A),
    ),
  ];
}
