import 'package:flutter/material.dart';

import '../../domain/entities/sport_definition.dart';
import '../../gen/app_localizations.dart';

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

    return Scaffold(
      backgroundColor: scheme.surface,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final wide = constraints.maxWidth >= 560;
                  return SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
                    child: Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 680),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Icon(
                              Icons.sports_rounded,
                              size: 44,
                              color: scheme.primary,
                            ),
                            const SizedBox(height: 18),
                            Text(
                              l10n.startupSportTitle,
                              textAlign: TextAlign.center,
                              style: theme.textTheme.headlineMedium?.copyWith(
                                color: scheme.onSurface,
                                fontWeight: FontWeight.w800,
                                height: 1.18,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              l10n.startupSportSubtitle,
                              textAlign: TextAlign.center,
                              style: theme.textTheme.titleMedium?.copyWith(
                                color: scheme.onSurfaceVariant,
                                fontWeight: FontWeight.w600,
                                height: 1.42,
                              ),
                            ),
                            const SizedBox(height: 28),
                            GridView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: choices.length,
                              gridDelegate:
                                  SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: wide ? 2 : 1,
                                crossAxisSpacing: 12,
                                mainAxisSpacing: 12,
                                childAspectRatio: wide ? 2.1 : 3.1,
                              ),
                              itemBuilder: (context, index) {
                                final choice = choices[index];
                                return _SportChoiceCard(
                                  choice: choice,
                                  selected: selectedSportId == choice.id,
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
                color: scheme.surface,
                border: Border(top: BorderSide(color: scheme.outlineVariant)),
              ),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 14, 24, 18),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 680),
                    child: SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        key: const ValueKey('startup-sport-start-button'),
                        onPressed: selectedSportId == null
                            ? null
                            : () => widget.onSelected(selectedSportId),
                        icon: const Icon(Icons.arrow_forward_rounded),
                        style: FilledButton.styleFrom(
                          minimumSize: const Size.fromHeight(54),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        label: Text(l10n.startupSportAction),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SportChoiceCard extends StatelessWidget {
  final _SportChoice choice;
  final bool selected;
  final VoidCallback onTap;

  const _SportChoiceCard({
    required this.choice,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final borderColor = selected ? choice.color : scheme.outlineVariant;
    return Semantics(
      button: true,
      selected: selected,
      label: choice.title,
      child: Material(
        color: selected
            ? choice.color.withValues(alpha: 0.12)
            : scheme.surfaceContainerLow,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: BorderSide(color: borderColor, width: selected ? 1.8 : 1),
        ),
        child: InkWell(
          key: ValueKey('startup-sport-choice-${choice.id}'),
          borderRadius: BorderRadius.circular(8),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: choice.color.withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(choice.icon, color: choice.color, size: 27),
                ),
                const SizedBox(width: 14),
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
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 4),
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
                const SizedBox(width: 10),
                Icon(
                  selected
                      ? Icons.check_circle_rounded
                      : Icons.radio_button_unchecked_rounded,
                  color: selected ? choice.color : scheme.outline,
                ),
              ],
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
