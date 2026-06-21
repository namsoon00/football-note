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
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final choices = _buildSportChoices(l10n);
    final selectedSportId = _selectedSportId;
    final selectedChoice =
        choices.where((choice) => choice.id == selectedSportId).firstOrNull;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: AppBackground(
        child: SafeArea(
          child: Column(
            children: [
              Expanded(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final listLayout = constraints.maxWidth < 360;
                    final crossAxisCount =
                        listLayout ? 1 : (constraints.maxWidth >= 760 ? 4 : 2);
                    final aspectRatio =
                        listLayout ? 3.05 : (crossAxisCount == 4 ? 0.78 : 0.84);
                    return SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(
                        AppSpacing.lg,
                        AppSpacing.xl,
                        AppSpacing.lg,
                        AppSpacing.xl,
                      ),
                      child: Center(
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 840),
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
              DecoratedBox(
                decoration: BoxDecoration(
                  color: AppSurfaces.cardColor(scheme, theme.brightness),
                  border: Border(
                    top: BorderSide(
                      color: AppSurfaces.borderColor(scheme, theme.brightness),
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
                      constraints: const BoxConstraints(maxWidth: 840),
                      child: _SportStartAction(
                        selectedChoice: selectedChoice,
                        label: l10n.startupSportAction,
                        onPressed: selectedSportId == null
                            ? null
                            : () => widget.onSelected(selectedSportId),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
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
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 56,
          height: 56,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: scheme.primary.withValues(alpha: 0.10),
            borderRadius: AppRadius.control,
            border: Border.all(
              color: scheme.primary.withValues(alpha: 0.18),
            ),
          ),
          child: Icon(
            Icons.sports_rounded,
            size: 30,
            color: scheme.primary,
          ),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: theme.textTheme.headlineMedium?.copyWith(
                  color: scheme.onSurface,
                  fontWeight: FontWeight.w900,
                  height: 1.16,
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                subtitle,
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: scheme.onSurfaceVariant,
                  height: 1.46,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _SportChoiceCard extends StatelessWidget {
  final _SportChoice choice;
  final bool selected;
  final bool listLayout;
  final VoidCallback onTap;

  const _SportChoiceCard({
    required this.choice,
    required this.selected,
    required this.listLayout,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final brightness = theme.brightness;
    final borderColor = selected
        ? choice.color
            .withValues(alpha: brightness == Brightness.dark ? 0.82 : 0.68)
        : AppSurfaces.borderColor(scheme, brightness);
    return Semantics(
      button: true,
      selected: selected,
      label: choice.title,
      child: AnimatedScale(
        scale: selected ? 1.012 : 1,
        duration: const Duration(milliseconds: 160),
        curve: Curves.easeOutCubic,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOutCubic,
          decoration: BoxDecoration(
            gradient: selected
                ? LinearGradient(
                    begin: AlignmentDirectional.topStart,
                    end: AlignmentDirectional.bottomEnd,
                    colors: [
                      choice.color.withValues(
                        alpha: brightness == Brightness.dark ? 0.24 : 0.14,
                      ),
                      AppSurfaces.cardColor(scheme, brightness),
                    ],
                  )
                : null,
            color: selected ? null : AppSurfaces.cardColor(scheme, brightness),
            borderRadius: AppRadius.surface,
            border: Border.all(color: borderColor, width: selected ? 1.6 : 1),
            boxShadow: AppShadows.surface(brightness),
          ),
          child: Material(
            color: Colors.transparent,
            borderRadius: AppRadius.surface,
            child: InkWell(
              key: ValueKey('startup-sport-choice-${choice.id}'),
              borderRadius: AppRadius.surface,
              onTap: onTap,
              child: Padding(
                padding: EdgeInsets.all(listLayout ? AppSpacing.md : 18),
                child: listLayout
                    ? _buildListContent(context)
                    : _buildTileContent(context),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTileContent(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _SportIconMark(choice: choice, selected: selected),
            const Spacer(),
            _SportSelectionMark(
              selected: selected,
              color: choice.color,
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
          maxLines: 3,
          overflow: TextOverflow.ellipsis,
          style: theme.textTheme.bodySmall?.copyWith(
            color: scheme.onSurfaceVariant,
            height: 1.32,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildListContent(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
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
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: scheme.onSurfaceVariant,
                  height: 1.28,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        _SportSelectionMark(selected: selected, color: choice.color),
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
    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeOutCubic,
      width: 52,
      height: 52,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: choice.color.withValues(alpha: selected ? 0.18 : 0.12),
        borderRadius: AppRadius.control,
      ),
      child: Icon(choice.icon, color: choice.color, size: 29),
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
    final scheme = Theme.of(context).colorScheme;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeOutCubic,
      width: 28,
      height: 28,
      decoration: BoxDecoration(
        color: selected ? color : Colors.transparent,
        borderRadius: AppRadius.full,
        border: Border.all(
          color: selected ? color : scheme.outline,
          width: 1.4,
        ),
      ),
      child: selected
          ? const Icon(Icons.check_rounded, size: 18, color: Colors.white)
          : null,
    );
  }
}

class _SportStartAction extends StatelessWidget {
  final _SportChoice? selectedChoice;
  final String label;
  final VoidCallback? onPressed;

  const _SportStartAction({
    required this.selectedChoice,
    required this.label,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final choice = selectedChoice;
    return SizedBox(
      width: double.infinity,
      child: FilledButton.icon(
        key: const ValueKey('startup-sport-start-button'),
        onPressed: onPressed,
        icon: Icon(choice == null ? Icons.arrow_forward_rounded : choice.icon),
        style: FilledButton.styleFrom(
          minimumSize: const Size.fromHeight(AppSizes.primaryButtonHeight),
          shape: RoundedRectangleBorder(borderRadius: AppRadius.control),
        ),
        label: Text(label, maxLines: 1, overflow: TextOverflow.ellipsis),
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
      color: const Color(0xFF2563EB),
    ),
    _SportChoice(
      id: SportCatalog.baseballId,
      title: l10n.sportBaseball,
      description: l10n.startupSportBaseballDescription,
      icon: Icons.sports_baseball,
      color: const Color(0xFFB45309),
    ),
    _SportChoice(
      id: SportCatalog.basketballId,
      title: l10n.sportBasketball,
      description: l10n.startupSportBasketballDescription,
      icon: Icons.sports_basketball_rounded,
      color: const Color(0xFFDC2626),
    ),
    _SportChoice(
      id: SportCatalog.tennisId,
      title: l10n.sportTennis,
      description: l10n.startupSportTennisDescription,
      icon: Icons.sports_tennis_rounded,
      color: const Color(0xFF15803D),
    ),
  ];
}
