import 'package:flutter/material.dart';
import 'package:football_note/gen/app_localizations.dart';

import '../widgets/app_background.dart';

class FootballEducationScreen extends StatelessWidget {
  const FootballEducationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      body: AppBackground(
        child: SafeArea(
          child: ListView(
            key: const ValueKey<String>('education-story-scroll'),
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
            children: [
              Align(
                alignment: Alignment.centerLeft,
                child: IconButton.filledTonal(
                  onPressed: () => Navigator.of(context).maybePop(),
                  icon: const Icon(Icons.arrow_back_rounded),
                ),
              ),
              const SizedBox(height: 12),
              _StoryPaper(
                title: l10n.educationScreenTitle,
                introParagraphs: _splitParagraphs(l10n.educationStoryIntroBody),
                sections: _buildSections(l10n),
                closingParagraphs: _splitParagraphs(
                  l10n.educationStoryClosingBody,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  List<_StorySection> _buildSections(AppLocalizations l10n) {
    return <_StorySection>[
      _StorySection(
        title: l10n.educationStoryOriginsTitle,
        paragraphs: _splitParagraphs(l10n.educationStoryOriginsBody),
      ),
      _StorySection(
        title: l10n.educationStoryReturnTitle,
        paragraphs: _splitParagraphs(l10n.educationStoryReturnBody),
      ),
      _StorySection(
        title: l10n.educationStoryMiddleTitle,
        paragraphs: _splitParagraphs(l10n.educationStoryMiddleBody),
      ),
      _StorySection(
        title: l10n.educationStoryRecentTitle,
        paragraphs: _splitParagraphs(l10n.educationStoryRecentBody),
      ),
      _StorySection(
        title: l10n.educationStoryPeopleTitle,
        paragraphs: _splitParagraphs(l10n.educationStoryPeopleBody),
      ),
      _StorySection(
        title: l10n.educationStoryFutureTitle,
        paragraphs: _splitParagraphs(l10n.educationStoryFutureBody),
      ),
    ];
  }

  static List<String> _splitParagraphs(String value) {
    return value
        .split('\n\n')
        .map((entry) => entry.trim())
        .where((entry) => entry.isNotEmpty)
        .toList(growable: false);
  }
}

class _StoryPaper extends StatelessWidget {
  final String title;
  final List<String> introParagraphs;
  final List<_StorySection> sections;
  final List<String> closingParagraphs;

  const _StoryPaper({
    required this.title,
    required this.introParagraphs,
    required this.sections,
    required this.closingParagraphs,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    const accent = Color(0xFF8E5A36);

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(32),
        boxShadow: theme.brightness == Brightness.dark
            ? null
            : const <BoxShadow>[
                BoxShadow(
                  color: Color(0x24161F2F),
                  blurRadius: 24,
                  offset: Offset(0, 16),
                ),
              ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(32),
        child: DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: <Color>[
                theme.brightness == Brightness.dark
                    ? theme.colorScheme.surface
                    : const Color(0xFFFBF3E3),
                theme.brightness == Brightness.dark
                    ? theme.colorScheme.surfaceContainerHighest
                    : const Color(0xFFF4E2C5),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            border: Border.all(color: accent.withValues(alpha: 0.3)),
          ),
          child: Stack(
            children: [
              Positioned(
                left: 24,
                top: 0,
                bottom: 0,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(999),
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: <Color>[
                        accent.withValues(alpha: 0.08),
                        accent.withValues(alpha: 0.42),
                        accent.withValues(alpha: 0.08),
                      ],
                    ),
                  ),
                  child: const SizedBox(width: 4),
                ),
              ),
              Positioned(
                right: -20,
                top: -18,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: accent.withValues(alpha: 0.08),
                    shape: BoxShape.circle,
                  ),
                  child: const SizedBox(width: 124, height: 124),
                ),
              ),
              Positioned(
                right: 28,
                top: 28,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: accent.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    child: Text(
                      '1930-2026',
                      style: theme.textTheme.labelLarge?.copyWith(
                        fontWeight: FontWeight.w900,
                        color: accent,
                        letterSpacing: 0.4,
                      ),
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(36, 28, 28, 32),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 300),
                      child: Text(
                        title,
                        style: theme.textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.w900,
                          height: 1.12,
                          color: theme.colorScheme.onSurface,
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    _StoryParagraphBlock(
                      paragraphs: introParagraphs,
                      lead: true,
                    ),
                    for (var index = 0; index < sections.length; index++) ...[
                      const SizedBox(height: 28),
                      _SectionDivider(
                        isLast:
                            index == sections.length - 1 &&
                            closingParagraphs.isEmpty,
                      ),
                      const SizedBox(height: 18),
                      Text(
                        sections[index].title,
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w900,
                          height: 1.2,
                          color: theme.colorScheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: 12),
                      _StoryParagraphBlock(
                        paragraphs: sections[index].paragraphs,
                      ),
                    ],
                    if (closingParagraphs.isNotEmpty) ...[
                      const SizedBox(height: 28),
                      const _SectionDivider(isLast: true),
                      const SizedBox(height: 18),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.fromLTRB(18, 18, 18, 20),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.surface.withValues(
                            alpha: theme.brightness == Brightness.dark
                                ? 0.24
                                : 0.52,
                          ),
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(
                            color: accent.withValues(alpha: 0.16),
                          ),
                        ),
                        child: _StoryParagraphBlock(
                          paragraphs: closingParagraphs,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StoryParagraphBlock extends StatelessWidget {
  final List<String> paragraphs;
  final bool lead;

  const _StoryParagraphBlock({required this.paragraphs, this.lead = false});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: paragraphs
          .map(
            (paragraph) => Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Text(
                paragraph,
                style:
                    (lead
                            ? theme.textTheme.bodyLarge
                            : theme.textTheme.bodyMedium)
                        ?.copyWith(
                          height: lead ? 1.9 : 1.85,
                          fontWeight: lead ? FontWeight.w700 : FontWeight.w600,
                          color: theme.colorScheme.onSurface,
                        ),
              ),
            ),
          )
          .toList(growable: false),
    );
  }
}

class _SectionDivider extends StatelessWidget {
  final bool isLast;

  const _SectionDivider({required this.isLast});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = theme.colorScheme.outline.withValues(alpha: 0.22);

    return Row(
      children: [
        Expanded(child: Container(height: 1, color: color)),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10),
          child: Icon(
            isLast ? Icons.auto_stories_rounded : Icons.circle,
            size: isLast ? 18 : 8,
            color: theme.colorScheme.primary.withValues(alpha: 0.72),
          ),
        ),
        Expanded(child: Container(height: 1, color: color)),
      ],
    );
  }
}

class _StorySection {
  final String title;
  final List<String> paragraphs;

  const _StorySection({required this.title, required this.paragraphs});
}
