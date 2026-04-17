import 'package:flutter/material.dart';
import 'package:football_note/gen/app_localizations.dart';

import '../widgets/app_background.dart';
import '../widgets/watch_cart/watch_cart_card.dart';

class FootballEducationScreen extends StatelessWidget {
  const FootballEducationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final modules = <_EducationModule>[
      _EducationModule(
        eyebrow: l10n.educationModuleBallEyebrow,
        title: l10n.educationModuleBallTitle,
        summary: l10n.educationModuleBallSummary,
        ageBand: l10n.educationModuleBallAge,
        duration: l10n.educationModuleBallDuration,
        cues: <String>[
          l10n.educationModuleBallCue1,
          l10n.educationModuleBallCue2,
          l10n.educationModuleBallCue3,
        ],
        icon: Icons.sports_soccer_rounded,
        gradientColors: const <Color>[Color(0xFFFFD39B), Color(0xFFF78C6A)],
      ),
      _EducationModule(
        eyebrow: l10n.educationModulePassEyebrow,
        title: l10n.educationModulePassTitle,
        summary: l10n.educationModulePassSummary,
        ageBand: l10n.educationModulePassAge,
        duration: l10n.educationModulePassDuration,
        cues: <String>[
          l10n.educationModulePassCue1,
          l10n.educationModulePassCue2,
          l10n.educationModulePassCue3,
        ],
        icon: Icons.sync_alt_rounded,
        gradientColors: const <Color>[Color(0xFFB7E3CC), Color(0xFF5DAE8B)],
      ),
      _EducationModule(
        eyebrow: l10n.educationModuleDecisionEyebrow,
        title: l10n.educationModuleDecisionTitle,
        summary: l10n.educationModuleDecisionSummary,
        ageBand: l10n.educationModuleDecisionAge,
        duration: l10n.educationModuleDecisionDuration,
        cues: <String>[
          l10n.educationModuleDecisionCue1,
          l10n.educationModuleDecisionCue2,
          l10n.educationModuleDecisionCue3,
        ],
        icon: Icons.bolt_rounded,
        gradientColors: const <Color>[Color(0xFFC8D7FF), Color(0xFF6B8DFF)],
      ),
    ];
    final principles = <_CoachingPrinciple>[
      _CoachingPrinciple(
        title: l10n.educationPrincipleOneTitle,
        body: l10n.educationPrincipleOneBody,
        icon: Icons.filter_1_rounded,
      ),
      _CoachingPrinciple(
        title: l10n.educationPrincipleTwoTitle,
        body: l10n.educationPrincipleTwoBody,
        icon: Icons.favorite_outline_rounded,
      ),
      _CoachingPrinciple(
        title: l10n.educationPrincipleThreeTitle,
        body: l10n.educationPrincipleThreeBody,
        icon: Icons.forum_outlined,
      ),
    ];

    return Scaffold(
      body: AppBackground(
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
            children: [
              Row(
                children: [
                  IconButton.filledTonal(
                    onPressed: () => Navigator.of(context).maybePop(),
                    icon: const Icon(Icons.arrow_back_rounded),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      l10n.educationScreenTitle,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _EducationHeroCard(l10n: l10n),
              const SizedBox(height: 18),
              Text(
                l10n.educationSectionLessonsTitle,
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 10),
              ...modules.map(
                (module) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: _EducationModuleCard(module: module),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                l10n.educationSectionPrinciplesTitle,
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 10),
              ...principles.map(
                (principle) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: _CoachingPrincipleCard(principle: principle),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EducationHeroCard extends StatelessWidget {
  final AppLocalizations l10n;

  const _EducationHeroCard({required this.l10n});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: <Color>[Color(0xFFFFD9A4), Color(0xFFF88D62)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(28),
        boxShadow: const <BoxShadow>[
          BoxShadow(
            color: Color(0x1F372000),
            blurRadius: 24,
            offset: Offset(0, 12),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            right: -14,
            top: -10,
            child: Container(
              width: 110,
              height: 110,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.14),
                shape: BoxShape.circle,
              ),
            ),
          ),
          Positioned(
            right: 22,
            bottom: 8,
            child: Icon(
              Icons.sports_soccer_rounded,
              size: 76,
              color: Colors.white.withValues(alpha: 0.18),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  l10n.educationHeroEyebrow,
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: const Color(0xFF5C2A00),
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.4,
                  ),
                ),
              ),
              const SizedBox(height: 14),
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 300),
                child: Text(
                  l10n.educationHeroTitle,
                  style: theme.textTheme.headlineSmall?.copyWith(
                    color: const Color(0xFF301100),
                    fontWeight: FontWeight.w900,
                    height: 1.12,
                  ),
                ),
              ),
              const SizedBox(height: 10),
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 300),
                child: Text(
                  l10n.educationHeroBody,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: const Color(0xFF5B2A0A),
                    height: 1.45,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _HeroStatChip(
                    icon: Icons.library_books_outlined,
                    label: l10n.educationHeroStatLessons,
                  ),
                  _HeroStatChip(
                    icon: Icons.schedule_rounded,
                    label: l10n.educationHeroStatMinutes,
                  ),
                  _HeroStatChip(
                    icon: Icons.record_voice_over_outlined,
                    label: l10n.educationHeroStatPrinciples,
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _HeroStatChip extends StatelessWidget {
  final IconData icon;
  final String label;

  const _HeroStatChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: const Color(0xFF5B2A0A)),
          const SizedBox(width: 6),
          Text(
            label,
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
              color: const Color(0xFF5B2A0A),
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _EducationModuleCard extends StatelessWidget {
  final _EducationModule module;

  const _EducationModuleCard({required this.module});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(1.2),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: module.gradientColors,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
      ),
      child: WatchCartCard(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: module.gradientColors,
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(module.icon, color: Colors.white, size: 24),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        module.eyebrow,
                        style: theme.textTheme.labelLarge?.copyWith(
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0.4,
                          color: theme.colorScheme.primary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        module.title,
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w900,
                          height: 1.12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              module.summary,
              style: theme.textTheme.bodyMedium?.copyWith(
                height: 1.45,
                color: theme.colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _ModuleMetaChip(
                  icon: Icons.group_outlined,
                  label: module.ageBand,
                ),
                _ModuleMetaChip(
                  icon: Icons.schedule_outlined,
                  label: module.duration,
                ),
              ],
            ),
            const SizedBox(height: 14),
            ...module.cues.map(
              (cue) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 20,
                      height: 20,
                      margin: const EdgeInsets.only(top: 1),
                      decoration: BoxDecoration(
                        color: module.gradientColors.last.withValues(
                          alpha: 0.14,
                        ),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Icon(
                        Icons.north_east_rounded,
                        size: 13,
                        color: module.gradientColors.last,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        cue,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          height: 1.4,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ModuleMetaChip extends StatelessWidget {
  final IconData icon;
  final String label;

  const _ModuleMetaChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: Theme.of(
          context,
        ).colorScheme.secondaryContainer.withValues(alpha: 0.75),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 15,
            color: Theme.of(context).colorScheme.onSecondaryContainer,
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
              fontWeight: FontWeight.w800,
              color: Theme.of(context).colorScheme.onSecondaryContainer,
            ),
          ),
        ],
      ),
    );
  }
}

class _CoachingPrincipleCard extends StatelessWidget {
  final _CoachingPrinciple principle;

  const _CoachingPrincipleCard({required this.principle});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return WatchCartCard(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: theme.colorScheme.primaryContainer,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(
              principle.icon,
              color: theme.colorScheme.onPrimaryContainer,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  principle.title,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  principle.body,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.w600,
                    height: 1.45,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _EducationModule {
  final String eyebrow;
  final String title;
  final String summary;
  final String ageBand;
  final String duration;
  final List<String> cues;
  final IconData icon;
  final List<Color> gradientColors;

  const _EducationModule({
    required this.eyebrow,
    required this.title,
    required this.summary,
    required this.ageBand,
    required this.duration,
    required this.cues,
    required this.icon,
    required this.gradientColors,
  });
}

class _CoachingPrinciple {
  final String title;
  final String body;
  final IconData icon;

  const _CoachingPrinciple({
    required this.title,
    required this.body,
    required this.icon,
  });
}
