import 'package:flutter/material.dart';
import 'package:football_note/gen/app_localizations.dart';

import '../widgets/app_background.dart';

class FootballEducationScreen extends StatefulWidget {
  const FootballEducationScreen({super.key});

  @override
  State<FootballEducationScreen> createState() =>
      _FootballEducationScreenState();
}

class _FootballEducationScreenState extends State<FootballEducationScreen> {
  final ScrollController _scrollController = ScrollController();
  final GlobalKey _historySectionKey = GlobalKey();
  final GlobalKey _lessonSectionKey = GlobalKey();
  final GlobalKey _storySectionKey = GlobalKey();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _scrollToSection(GlobalKey key) async {
    final context = key.currentContext;
    if (context == null) {
      return;
    }

    await Scrollable.ensureVisible(
      context,
      duration: const Duration(milliseconds: 320),
      curve: Curves.easeOutCubic,
      alignment: 0.08,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    final introParagraphs = _splitParagraphs(l10n.educationStoryIntroBody);
    final closingParagraphs = _splitParagraphs(l10n.educationStoryClosingBody);
    final historyCards = _buildHistoryCards(l10n);
    final lessonCards = _buildLessonCards(l10n);
    final principles = _buildPrinciples(l10n);
    final chapters = _buildBookChapters(l10n);

    return Scaffold(
      body: AppBackground(
        child: SafeArea(
          child: ListView(
            controller: _scrollController,
            key: const ValueKey<String>('education-hub-scroll'),
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
            children: [
              Align(
                alignment: Alignment.centerLeft,
                child: IconButton.filledTonal(
                  onPressed: () => Navigator.of(context).maybePop(),
                  icon: const Icon(Icons.arrow_back_rounded),
                ),
              ),
              const SizedBox(height: 16),
              _EducationHeroCard(
                eyebrow: l10n.educationHeroEyebrow,
                title: l10n.educationHeroTitle,
                body: l10n.educationHeroBody,
                introParagraphs:
                    introParagraphs.take(1).toList(growable: false),
                stats: <String>[
                  l10n.educationHeroStatLessons,
                  l10n.educationHeroStatMinutes,
                  l10n.educationHeroStatPrinciples,
                  l10n.educationHeroStatHistory,
                ],
              ),
              const SizedBox(height: 16),
              _EducationTrackCard(
                key: const ValueKey<String>('education-track-history'),
                icon: Icons.emoji_objects_rounded,
                accent: const Color(0xFF0F766E),
                title: l10n.educationSectionHistoryTitle,
                body: l10n.educationSectionHistoryBody,
                onTap: () => _scrollToSection(_historySectionKey),
              ),
              const SizedBox(height: 12),
              _EducationTrackCard(
                key: const ValueKey<String>('education-track-lessons'),
                icon: Icons.sports_soccer_rounded,
                accent: const Color(0xFF8E5A36),
                title: l10n.educationSectionLessonsTitle,
                body: l10n.educationHeroBody,
                onTap: () => _scrollToSection(_lessonSectionKey),
              ),
              const SizedBox(height: 12),
              _EducationTrackCard(
                key: const ValueKey<String>('education-track-story'),
                icon: Icons.auto_stories_rounded,
                accent: const Color(0xFF6D597A),
                title: l10n.educationScreenTitle,
                body: introParagraphs.isEmpty
                    ? l10n.educationStoryIntroBody
                    : introParagraphs.first,
                onTap: () => _scrollToSection(_storySectionKey),
              ),
              const SizedBox(height: 24),
              KeyedSubtree(
                key: _historySectionKey,
                child: _EducationSectionShell(
                  sectionKey:
                      const ValueKey<String>('education-history-section'),
                  eyebrow: l10n.educationHistoryWorldCupEyebrow,
                  title: l10n.educationSectionHistoryTitle,
                  description: l10n.educationSectionHistoryBody,
                  accent: const Color(0xFF0F766E),
                  child: Column(
                    children: [
                      for (var index = 0;
                          index < historyCards.length;
                          index++) ...[
                        _EducationHistoryCard(
                          card: historyCards[index],
                          accent: _historyAccent(index),
                        ),
                        if (index != historyCards.length - 1)
                          const SizedBox(height: 14),
                      ],
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),
              KeyedSubtree(
                key: _lessonSectionKey,
                child: _EducationSectionShell(
                  sectionKey:
                      const ValueKey<String>('education-lessons-section'),
                  eyebrow: l10n.educationHeroEyebrow,
                  title: l10n.educationSectionLessonsTitle,
                  description: l10n.educationHeroBody,
                  accent: const Color(0xFF8E5A36),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      for (var index = 0;
                          index < lessonCards.length;
                          index++) ...[
                        _EducationLessonCard(
                          lesson: lessonCards[index],
                          accent: _lessonAccent(index),
                        ),
                        if (index != lessonCards.length - 1)
                          const SizedBox(height: 14),
                      ],
                      const SizedBox(height: 22),
                      Text(
                        l10n.educationSectionPrinciplesTitle,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w900,
                          color: theme.colorScheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: 12),
                      for (var index = 0;
                          index < principles.length;
                          index++) ...[
                        _EducationPrincipleCard(
                          principle: principles[index],
                          icon: _principleIcon(index),
                          accent: _principleAccent(index),
                        ),
                        if (index != principles.length - 1)
                          const SizedBox(height: 12),
                      ],
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),
              KeyedSubtree(
                key: _storySectionKey,
                child: _EducationSectionShell(
                  sectionKey: const ValueKey<String>('education-story-section'),
                  eyebrow: l10n.educationBookCoverLabel,
                  title: l10n.educationScreenTitle,
                  description: introParagraphs.isEmpty
                      ? l10n.educationStoryIntroBody
                      : introParagraphs.first,
                  accent: const Color(0xFF6D597A),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (introParagraphs.length > 1) ...[
                        _StoryPreludeCard(paragraphs: introParagraphs),
                        const SizedBox(height: 16),
                      ],
                      for (var index = 0; index < chapters.length; index++) ...[
                        _EducationBookChapterCard(
                          key:
                              ValueKey<String>('education-book-chapter-$index'),
                          chapter: chapters[index],
                          accent: _chapterAccent(index),
                          storyLabel: l10n.educationBookSectionStory,
                          timelineLabel: l10n.educationBookSectionTimeline,
                          factsLabel: l10n.educationBookSectionFacts,
                          noteLabel: l10n.educationBookSectionNote,
                        ),
                        if (index != chapters.length - 1)
                          const SizedBox(height: 12),
                      ],
                      if (closingParagraphs.isNotEmpty) ...[
                        const SizedBox(height: 18),
                        _StoryClosingCard(paragraphs: closingParagraphs),
                      ],
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

  List<_EducationHistoryData> _buildHistoryCards(AppLocalizations l10n) {
    return <_EducationHistoryData>[
      _EducationHistoryData(
        eyebrow: l10n.educationHistoryWorldCupEyebrow,
        title: l10n.educationHistoryWorldCupTitle,
        summary: l10n.educationHistoryWorldCupSummary,
        focus: l10n.educationHistoryWorldCupFocus,
        facts: <String>[
          l10n.educationHistoryWorldCupFact1,
          l10n.educationHistoryWorldCupFact2,
          l10n.educationHistoryWorldCupFact3,
        ],
      ),
      _EducationHistoryData(
        eyebrow: l10n.educationHistoryCompetitionEyebrow,
        title: l10n.educationHistoryCompetitionTitle,
        summary: l10n.educationHistoryCompetitionSummary,
        focus: l10n.educationHistoryCompetitionFocus,
        facts: <String>[
          l10n.educationHistoryCompetitionFact1,
          l10n.educationHistoryCompetitionFact2,
          l10n.educationHistoryCompetitionFact3,
        ],
      ),
      _EducationHistoryData(
        eyebrow: l10n.educationHistoryMomentsEyebrow,
        title: l10n.educationHistoryMomentsTitle,
        summary: l10n.educationHistoryMomentsSummary,
        focus: l10n.educationHistoryMomentsFocus,
        facts: <String>[
          l10n.educationHistoryMomentsFact1,
          l10n.educationHistoryMomentsFact2,
          l10n.educationHistoryMomentsFact3,
        ],
      ),
    ];
  }

  List<_EducationLessonData> _buildLessonCards(AppLocalizations l10n) {
    return <_EducationLessonData>[
      _EducationLessonData(
        eyebrow: l10n.educationModuleBallEyebrow,
        title: l10n.educationModuleBallTitle,
        summary: l10n.educationModuleBallSummary,
        age: l10n.educationModuleBallAge,
        duration: l10n.educationModuleBallDuration,
        cues: <String>[
          l10n.educationModuleBallCue1,
          l10n.educationModuleBallCue2,
          l10n.educationModuleBallCue3,
        ],
      ),
      _EducationLessonData(
        eyebrow: l10n.educationModulePassEyebrow,
        title: l10n.educationModulePassTitle,
        summary: l10n.educationModulePassSummary,
        age: l10n.educationModulePassAge,
        duration: l10n.educationModulePassDuration,
        cues: <String>[
          l10n.educationModulePassCue1,
          l10n.educationModulePassCue2,
          l10n.educationModulePassCue3,
        ],
      ),
      _EducationLessonData(
        eyebrow: l10n.educationModuleDecisionEyebrow,
        title: l10n.educationModuleDecisionTitle,
        summary: l10n.educationModuleDecisionSummary,
        age: l10n.educationModuleDecisionAge,
        duration: l10n.educationModuleDecisionDuration,
        cues: <String>[
          l10n.educationModuleDecisionCue1,
          l10n.educationModuleDecisionCue2,
          l10n.educationModuleDecisionCue3,
        ],
      ),
    ];
  }

  List<_EducationPrincipleData> _buildPrinciples(AppLocalizations l10n) {
    return <_EducationPrincipleData>[
      _EducationPrincipleData(
        title: l10n.educationPrincipleOneTitle,
        body: l10n.educationPrincipleOneBody,
      ),
      _EducationPrincipleData(
        title: l10n.educationPrincipleTwoTitle,
        body: l10n.educationPrincipleTwoBody,
      ),
      _EducationPrincipleData(
        title: l10n.educationPrincipleThreeTitle,
        body: l10n.educationPrincipleThreeBody,
      ),
    ];
  }

  List<_EducationBookChapterData> _buildBookChapters(AppLocalizations l10n) {
    return <_EducationBookChapterData>[
      _EducationBookChapterData(
        label: l10n.educationBookCoverLabel,
        title: l10n.educationBookCoverTitle,
        subtitle: l10n.educationBookCoverSubtitle,
        storyParagraphs: _splitParagraphs(l10n.educationBookCoverStory),
        timelineLines: _splitLines(l10n.educationBookCoverTimeline),
        factLines: _splitLines(l10n.educationBookCoverFacts),
        noteParagraphs: _splitParagraphs(l10n.educationBookCoverNote),
      ),
      _EducationBookChapterData(
        label: l10n.educationBookOriginsLabel,
        title: l10n.educationBookOriginsTitle,
        subtitle: l10n.educationBookOriginsSubtitle,
        storyParagraphs: _splitParagraphs(l10n.educationBookOriginsStory),
        timelineLines: _splitLines(l10n.educationBookOriginsTimeline),
        factLines: _splitLines(l10n.educationBookOriginsFacts),
        noteParagraphs: _splitParagraphs(l10n.educationBookOriginsNote),
      ),
      _EducationBookChapterData(
        label: l10n.educationBookWorldCupLabel,
        title: l10n.educationBookWorldCupTitle,
        subtitle: l10n.educationBookWorldCupSubtitle,
        storyParagraphs: _splitParagraphs(l10n.educationBookWorldCupStory),
        timelineLines: _splitLines(l10n.educationBookWorldCupTimeline),
        factLines: _splitLines(l10n.educationBookWorldCupFacts),
        noteParagraphs: _splitParagraphs(l10n.educationBookWorldCupNote),
      ),
      _EducationBookChapterData(
        label: l10n.educationBookClubLabel,
        title: l10n.educationBookClubTitle,
        subtitle: l10n.educationBookClubSubtitle,
        storyParagraphs: _splitParagraphs(l10n.educationBookClubStory),
        timelineLines: _splitLines(l10n.educationBookClubTimeline),
        factLines: _splitLines(l10n.educationBookClubFacts),
        noteParagraphs: _splitParagraphs(l10n.educationBookClubNote),
      ),
      _EducationBookChapterData(
        label: l10n.educationBookTacticsLabel,
        title: l10n.educationBookTacticsTitle,
        subtitle: l10n.educationBookTacticsSubtitle,
        storyParagraphs: _splitParagraphs(l10n.educationBookTacticsStory),
        timelineLines: _splitLines(l10n.educationBookTacticsTimeline),
        factLines: _splitLines(l10n.educationBookTacticsFacts),
        noteParagraphs: _splitParagraphs(l10n.educationBookTacticsNote),
      ),
      _EducationBookChapterData(
        label: l10n.educationBookLegendsLabel,
        title: l10n.educationBookLegendsTitle,
        subtitle: l10n.educationBookLegendsSubtitle,
        storyParagraphs: _splitParagraphs(l10n.educationBookLegendsStory),
        timelineLines: _splitLines(l10n.educationBookLegendsTimeline),
        factLines: _splitLines(l10n.educationBookLegendsFacts),
        noteParagraphs: _splitParagraphs(l10n.educationBookLegendsNote),
      ),
      _EducationBookChapterData(
        label: l10n.educationBookAsiaLabel,
        title: l10n.educationBookAsiaTitle,
        subtitle: l10n.educationBookAsiaSubtitle,
        storyParagraphs: _splitParagraphs(l10n.educationBookAsiaStory),
        timelineLines: _splitLines(l10n.educationBookAsiaTimeline),
        factLines: _splitLines(l10n.educationBookAsiaFacts),
        noteParagraphs: _splitParagraphs(l10n.educationBookAsiaNote),
      ),
      _EducationBookChapterData(
        label: l10n.educationBookWomenLabel,
        title: l10n.educationBookWomenTitle,
        subtitle: l10n.educationBookWomenSubtitle,
        storyParagraphs: _splitParagraphs(l10n.educationBookWomenStory),
        timelineLines: _splitLines(l10n.educationBookWomenTimeline),
        factLines: _splitLines(l10n.educationBookWomenFacts),
        noteParagraphs: _splitParagraphs(l10n.educationBookWomenNote),
      ),
      _EducationBookChapterData(
        label: l10n.educationBookModernLabel,
        title: l10n.educationBookModernTitle,
        subtitle: l10n.educationBookModernSubtitle,
        storyParagraphs: _splitParagraphs(l10n.educationBookModernStory),
        timelineLines: _splitLines(l10n.educationBookModernTimeline),
        factLines: _splitLines(l10n.educationBookModernFacts),
        noteParagraphs: _splitParagraphs(l10n.educationBookModernNote),
      ),
      _EducationBookChapterData(
        label: l10n.educationBookFinaleLabel,
        title: l10n.educationBookFinaleTitle,
        subtitle: l10n.educationBookFinaleSubtitle,
        storyParagraphs: _splitParagraphs(l10n.educationBookFinaleStory),
        timelineLines: _splitLines(l10n.educationBookFinaleTimeline),
        factLines: _splitLines(l10n.educationBookFinaleFacts),
        noteParagraphs: _splitParagraphs(l10n.educationBookFinaleNote),
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

  static List<String> _splitLines(String value) {
    return value
        .split('\n')
        .map((entry) => entry.trim())
        .where((entry) => entry.isNotEmpty)
        .toList(growable: false);
  }

  static Color _historyAccent(int index) {
    const palette = <Color>[
      Color(0xFF0F766E),
      Color(0xFF1D4ED8),
      Color(0xFFB45309),
    ];
    return palette[index % palette.length];
  }

  static Color _lessonAccent(int index) {
    const palette = <Color>[
      Color(0xFF8E5A36),
      Color(0xFFAD5E3C),
      Color(0xFF6A994E),
    ];
    return palette[index % palette.length];
  }

  static Color _principleAccent(int index) {
    const palette = <Color>[
      Color(0xFF7C3AED),
      Color(0xFF0F766E),
      Color(0xFFC2410C),
    ];
    return palette[index % palette.length];
  }

  static IconData _principleIcon(int index) {
    const icons = <IconData>[
      Icons.looks_one_rounded,
      Icons.celebration_rounded,
      Icons.question_answer_rounded,
    ];
    return icons[index % icons.length];
  }

  static Color _chapterAccent(int index) {
    const palette = <Color>[
      Color(0xFF6D597A),
      Color(0xFF355070),
      Color(0xFFB56576),
      Color(0xFF0F766E),
      Color(0xFF8E5A36),
    ];
    return palette[index % palette.length];
  }
}

class _EducationHeroCard extends StatelessWidget {
  final String eyebrow;
  final String title;
  final String body;
  final List<String> introParagraphs;
  final List<String> stats;

  const _EducationHeroCard({
    required this.eyebrow,
    required this.title,
    required this.body,
    required this.introParagraphs,
    required this.stats,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final surface = theme.brightness == Brightness.dark
        ? const Color(0xFF2D241D)
        : const Color(0xFFFFF5E2);
    final highlight = theme.brightness == Brightness.dark
        ? const Color(0xFF594436)
        : const Color(0xFFF4C98B);
    final ink = theme.brightness == Brightness.dark
        ? const Color(0xFFFFF5E1)
        : const Color(0xFF26190F);

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(32),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: <Color>[surface, highlight],
        ),
        boxShadow: theme.brightness == Brightness.dark
            ? null
            : const <BoxShadow>[
                BoxShadow(
                  color: Color(0x24161F2F),
                  blurRadius: 24,
                  offset: Offset(0, 18),
                ),
              ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(32),
        child: Stack(
          children: [
            Positioned(
              right: -32,
              top: -12,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.18),
                  shape: BoxShape.circle,
                ),
                child: const SizedBox(width: 140, height: 140),
              ),
            ),
            Positioned(
              left: -20,
              bottom: -26,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.14),
                  shape: BoxShape.circle,
                ),
                child: const SizedBox(width: 126, height: 126),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    eyebrow,
                    style: theme.textTheme.labelLarge?.copyWith(
                      color: ink.withValues(alpha: 0.8),
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0.7,
                    ),
                  ),
                  const SizedBox(height: 10),
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 340),
                    child: Text(
                      title,
                      style: theme.textTheme.headlineMedium?.copyWith(
                        color: ink,
                        fontWeight: FontWeight.w900,
                        height: 1.08,
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    body,
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: ink.withValues(alpha: 0.88),
                      height: 1.55,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (introParagraphs.isNotEmpty) ...[
                    const SizedBox(height: 18),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.22),
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.26),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: introParagraphs
                            .map(
                              (paragraph) => Padding(
                                padding: const EdgeInsets.only(bottom: 10),
                                child: Text(
                                  paragraph,
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    color: ink.withValues(alpha: 0.88),
                                    height: 1.6,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            )
                            .toList(growable: false),
                      ),
                    ),
                  ],
                  const SizedBox(height: 18),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: stats
                        .map(
                          (stat) => DecoratedBox(
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(999),
                              border: Border.all(
                                color: Colors.white.withValues(alpha: 0.22),
                              ),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 8,
                              ),
                              child: Text(
                                stat,
                                style: theme.textTheme.labelLarge?.copyWith(
                                  color: ink,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                          ),
                        )
                        .toList(growable: false),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EducationTrackCard extends StatelessWidget {
  final IconData icon;
  final Color accent;
  final String title;
  final String body;
  final VoidCallback onTap;

  const _EducationTrackCard({
    super.key,
    required this.icon,
    required this.accent,
    required this.title,
    required this.body,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(26),
        onTap: onTap,
        child: Ink(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(26),
            color: theme.brightness == Brightness.dark
                ? theme.colorScheme.surface.withValues(alpha: 0.9)
                : Colors.white.withValues(alpha: 0.82),
            border: Border.all(color: accent.withValues(alpha: 0.24)),
            boxShadow: theme.brightness == Brightness.dark
                ? null
                : const <BoxShadow>[
                    BoxShadow(
                      color: Color(0x16161F2F),
                      blurRadius: 18,
                      offset: Offset(0, 10),
                    ),
                  ],
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(18, 18, 18, 18),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                DecoratedBox(
                  decoration: BoxDecoration(
                    color: accent.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Icon(icon, color: accent),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w900,
                          color: theme.colorScheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        body,
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          height: 1.45,
                          color: theme.colorScheme.onSurface.withValues(
                            alpha: 0.82,
                          ),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                Icon(
                  Icons.arrow_forward_rounded,
                  color: accent,
                  size: 22,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _EducationSectionShell extends StatelessWidget {
  final Key? sectionKey;
  final String eyebrow;
  final String title;
  final String description;
  final Color accent;
  final Widget child;

  const _EducationSectionShell({
    this.sectionKey,
    required this.eyebrow,
    required this.title,
    required this.description,
    required this.accent,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      key: sectionKey,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(30),
        color: theme.brightness == Brightness.dark
            ? theme.colorScheme.surface.withValues(alpha: 0.92)
            : Colors.white.withValues(alpha: 0.9),
        border: Border.all(color: accent.withValues(alpha: 0.22)),
        boxShadow: theme.brightness == Brightness.dark
            ? null
            : const <BoxShadow>[
                BoxShadow(
                  color: Color(0x14161F2F),
                  blurRadius: 20,
                  offset: Offset(0, 12),
                ),
              ],
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 22, 20, 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            DecoratedBox(
              decoration: BoxDecoration(
                color: accent.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(999),
              ),
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                child: Text(
                  eyebrow,
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: accent,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              title,
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w900,
                height: 1.12,
                color: theme.colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              description,
              style: theme.textTheme.bodyMedium?.copyWith(
                height: 1.55,
                color: theme.colorScheme.onSurface.withValues(alpha: 0.82),
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 18),
            child,
          ],
        ),
      ),
    );
  }
}

class _EducationHistoryCard extends StatelessWidget {
  final _EducationHistoryData card;
  final Color accent;

  const _EducationHistoryCard({required this.card, required this.accent});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: <Color>[
            accent.withValues(alpha: 0.12),
            accent.withValues(alpha: 0.04),
          ],
        ),
        border: Border.all(color: accent.withValues(alpha: 0.18)),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              card.eyebrow,
              style: theme.textTheme.labelLarge?.copyWith(
                color: accent,
                fontWeight: FontWeight.w900,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              card.title,
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w900,
                color: theme.colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              card.summary,
              style: theme.textTheme.bodyMedium?.copyWith(
                height: 1.55,
                fontWeight: FontWeight.w600,
                color: theme.colorScheme.onSurface.withValues(alpha: 0.84),
              ),
            ),
            const SizedBox(height: 12),
            DecoratedBox(
              decoration: BoxDecoration(
                color: accent.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(999),
              ),
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                child: Text(
                  card.focus,
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: accent,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 14),
            for (final fact in card.facts) ...[
              _BulletLine(text: fact, accent: accent),
              if (fact != card.facts.last) const SizedBox(height: 10),
            ],
          ],
        ),
      ),
    );
  }
}

class _EducationLessonCard extends StatelessWidget {
  final _EducationLessonData lesson;
  final Color accent;

  const _EducationLessonCard({required this.lesson, required this.accent});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        color: accent.withValues(alpha: 0.08),
        border: Border.all(color: accent.withValues(alpha: 0.2)),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              lesson.eyebrow,
              style: theme.textTheme.labelLarge?.copyWith(
                color: accent,
                fontWeight: FontWeight.w900,
                letterSpacing: 0.55,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              lesson.title,
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w900,
                color: theme.colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              lesson.summary,
              style: theme.textTheme.bodyMedium?.copyWith(
                height: 1.55,
                fontWeight: FontWeight.w600,
                color: theme.colorScheme.onSurface.withValues(alpha: 0.84),
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _TagChip(label: lesson.age, accent: accent),
                _TagChip(label: lesson.duration, accent: accent),
              ],
            ),
            const SizedBox(height: 14),
            for (final cue in lesson.cues) ...[
              _BulletLine(
                text: cue,
                accent: accent,
                icon: Icons.play_arrow_rounded,
              ),
              if (cue != lesson.cues.last) const SizedBox(height: 10),
            ],
          ],
        ),
      ),
    );
  }
}

class _EducationPrincipleCard extends StatelessWidget {
  final _EducationPrincipleData principle;
  final IconData icon;
  final Color accent;

  const _EducationPrincipleCard({
    required this.principle,
    required this.icon,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        color: accent.withValues(alpha: 0.08),
        border: Border.all(color: accent.withValues(alpha: 0.16)),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            DecoratedBox(
              decoration: BoxDecoration(
                color: accent.withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Padding(
                padding: const EdgeInsets.all(10),
                child: Icon(icon, color: accent),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    principle.title,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w900,
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    principle.body,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      height: 1.5,
                      fontWeight: FontWeight.w600,
                      color:
                          theme.colorScheme.onSurface.withValues(alpha: 0.82),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StoryPreludeCard extends StatelessWidget {
  final List<String> paragraphs;

  const _StoryPreludeCard({required this.paragraphs});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    const accent = Color(0xFF6D597A);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        color: accent.withValues(alpha: 0.08),
        border: Border.all(color: accent.withValues(alpha: 0.16)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: paragraphs
            .map(
              (paragraph) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Text(
                  paragraph,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    height: 1.65,
                    fontWeight: FontWeight.w600,
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.84),
                  ),
                ),
              ),
            )
            .toList(growable: false),
      ),
    );
  }
}

class _EducationBookChapterCard extends StatelessWidget {
  final _EducationBookChapterData chapter;
  final Color accent;
  final String storyLabel;
  final String timelineLabel;
  final String factsLabel;
  final String noteLabel;

  const _EducationBookChapterCard({
    super.key,
    required this.chapter,
    required this.accent,
    required this.storyLabel,
    required this.timelineLabel,
    required this.factsLabel,
    required this.noteLabel,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: Material(
        color: accent.withValues(alpha: 0.08),
        child: Theme(
          data: theme.copyWith(dividerColor: Colors.transparent),
          child: ExpansionTile(
            tilePadding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
            childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            iconColor: accent,
            collapsedIconColor: accent,
            collapsedShape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(24),
              side: BorderSide(color: accent.withValues(alpha: 0.16)),
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(24),
              side: BorderSide(color: accent.withValues(alpha: 0.18)),
            ),
            title: Text(
              chapter.title,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w900,
                color: theme.colorScheme.onSurface,
              ),
            ),
            subtitle: Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                '${chapter.label} · ${chapter.subtitle}',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            children: [
              _ChapterBlock(
                title: storyLabel,
                entries: chapter.storyParagraphs,
                accent: accent,
                bullet: false,
              ),
              const SizedBox(height: 14),
              _ChapterBlock(
                title: timelineLabel,
                entries: chapter.timelineLines,
                accent: accent,
              ),
              const SizedBox(height: 14),
              _ChapterBlock(
                title: factsLabel,
                entries: chapter.factLines,
                accent: accent,
              ),
              const SizedBox(height: 14),
              _ChapterBlock(
                title: noteLabel,
                entries: chapter.noteParagraphs,
                accent: accent,
                bullet: false,
                emphasize: true,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ChapterBlock extends StatelessWidget {
  final String title;
  final List<String> entries;
  final Color accent;
  final bool bullet;
  final bool emphasize;

  const _ChapterBlock({
    required this.title,
    required this.entries,
    required this.accent,
    this.bullet = true,
    this.emphasize = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: accent.withValues(alpha: emphasize ? 0.12 : 0.06),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: theme.textTheme.titleSmall?.copyWith(
              color: accent,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 10),
          for (final entry in entries) ...[
            if (bullet)
              _BulletLine(text: entry, accent: accent)
            else
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Text(
                  entry,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    height: 1.65,
                    fontWeight: emphasize ? FontWeight.w700 : FontWeight.w600,
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.84),
                  ),
                ),
              ),
            if (entry != entries.last) const SizedBox(height: 10),
          ],
        ],
      ),
    );
  }
}

class _StoryClosingCard extends StatelessWidget {
  final List<String> paragraphs;

  const _StoryClosingCard({required this.paragraphs});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    const accent = Color(0xFF6D597A);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: <Color>[
            accent.withValues(alpha: 0.12),
            accent.withValues(alpha: 0.06),
          ],
        ),
        border: Border.all(color: accent.withValues(alpha: 0.18)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: paragraphs
            .map(
              (paragraph) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Text(
                  paragraph,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    height: 1.65,
                    fontWeight: FontWeight.w700,
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.86),
                  ),
                ),
              ),
            )
            .toList(growable: false),
      ),
    );
  }
}

class _TagChip extends StatelessWidget {
  final String label;
  final Color accent;

  const _TagChip({required this.label, required this.accent});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return DecoratedBox(
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
        child: Text(
          label,
          style: theme.textTheme.labelLarge?.copyWith(
            color: accent,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );
  }
}

class _BulletLine extends StatelessWidget {
  final String text;
  final Color accent;
  final IconData? icon;

  const _BulletLine({
    required this.text,
    required this.accent,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 2),
          child: Icon(
            icon ?? Icons.circle,
            size: icon == null ? 8 : 18,
            color: accent,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            text,
            style: theme.textTheme.bodyMedium?.copyWith(
              height: 1.55,
              fontWeight: FontWeight.w600,
              color: theme.colorScheme.onSurface.withValues(alpha: 0.84),
            ),
          ),
        ),
      ],
    );
  }
}

class _EducationHistoryData {
  final String eyebrow;
  final String title;
  final String summary;
  final String focus;
  final List<String> facts;

  const _EducationHistoryData({
    required this.eyebrow,
    required this.title,
    required this.summary,
    required this.focus,
    required this.facts,
  });
}

class _EducationLessonData {
  final String eyebrow;
  final String title;
  final String summary;
  final String age;
  final String duration;
  final List<String> cues;

  const _EducationLessonData({
    required this.eyebrow,
    required this.title,
    required this.summary,
    required this.age,
    required this.duration,
    required this.cues,
  });
}

class _EducationPrincipleData {
  final String title;
  final String body;

  const _EducationPrincipleData({required this.title, required this.body});
}

class _EducationBookChapterData {
  final String label;
  final String title;
  final String subtitle;
  final List<String> storyParagraphs;
  final List<String> timelineLines;
  final List<String> factLines;
  final List<String> noteParagraphs;

  const _EducationBookChapterData({
    required this.label,
    required this.title,
    required this.subtitle,
    required this.storyParagraphs,
    required this.timelineLines,
    required this.factLines,
    required this.noteParagraphs,
  });
}
