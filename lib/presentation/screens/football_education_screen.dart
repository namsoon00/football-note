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
  late final PageController _pageController;
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(viewportFraction: 0.9);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final chapters = _buildChapters(l10n);
    final currentChapter = chapters[_currentIndex];

    return Scaffold(
      body: AppBackground(
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                child: Column(
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
                            style: theme.textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.surface.withValues(
                              alpha: 0.9,
                            ),
                            borderRadius: BorderRadius.circular(999),
                            border: Border.all(
                              color: theme.colorScheme.outline.withValues(
                                alpha: 0.2,
                              ),
                            ),
                          ),
                          child: Text(
                            l10n.educationBookProgressLabel(
                              _currentIndex + 1,
                              chapters.length,
                            ),
                            style: theme.textTheme.labelLarge?.copyWith(
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    _BookProgressCard(
                      title: currentChapter.title,
                      chapterLabel: currentChapter.chapterLabel,
                      progressLabel: l10n.educationBookProgressLabel(
                        _currentIndex + 1,
                        chapters.length,
                      ),
                      swipeHint: l10n.educationBookSwipeHint,
                      pageCount: chapters.length,
                      currentIndex: _currentIndex,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              Expanded(
                child: PageView.builder(
                  key: const ValueKey<String>('education-book-page-view'),
                  controller: _pageController,
                  itemCount: chapters.length,
                  onPageChanged: (index) {
                    if (_currentIndex == index) {
                      return;
                    }
                    setState(() {
                      _currentIndex = index;
                    });
                  },
                  itemBuilder: (context, index) {
                    return AnimatedBuilder(
                      animation: _pageController,
                      child: _BookPageCard(
                        pageIndex: index,
                        chapter: chapters[index],
                        pageLabel: l10n.educationBookProgressLabel(
                          index + 1,
                          chapters.length,
                        ),
                      ),
                      builder: (context, child) {
                        final currentPage =
                            _pageController.hasClients &&
                                _pageController.page != null
                            ? _pageController.page!
                            : _currentIndex.toDouble();
                        final distance = (index - currentPage)
                            .clamp(-1.0, 1.0)
                            .toDouble();
                        final scale = (1 - (distance.abs() * 0.08)).clamp(
                          0.92,
                          1.0,
                        );
                        final opacity = (1 - (distance.abs() * 0.26)).clamp(
                          0.72,
                          1.0,
                        );

                        return Opacity(
                          opacity: opacity,
                          child: Transform.translate(
                            offset: Offset(distance * 22, 0),
                            child: Transform(
                              alignment: distance >= 0
                                  ? Alignment.centerLeft
                                  : Alignment.centerRight,
                              transform: Matrix4.identity()
                                ..setEntry(3, 2, 0.001)
                                ..rotateY(distance * 0.09),
                              child: Transform.scale(
                                scale: scale,
                                child: child,
                              ),
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  List<_BookChapter> _buildChapters(AppLocalizations l10n) {
    return <_BookChapter>[
      _BookChapter(
        chapterLabel: l10n.educationBookCoverLabel,
        title: l10n.educationBookCoverTitle,
        subtitle: l10n.educationBookCoverSubtitle,
        storyParagraphs: _splitParagraphs(l10n.educationBookCoverStory),
        accentColors: const <Color>[Color(0xFFD9874D), Color(0xFF6A422D)],
      ),
      _BookChapter(
        chapterLabel: l10n.educationBookOriginsLabel,
        title: l10n.educationBookOriginsTitle,
        subtitle: l10n.educationBookOriginsSubtitle,
        storyParagraphs: _splitParagraphs(l10n.educationBookOriginsStory),
        accentColors: const <Color>[Color(0xFFE4AF63), Color(0xFF5C4731)],
      ),
      _BookChapter(
        chapterLabel: l10n.educationBookWorldCupLabel,
        title: l10n.educationBookWorldCupTitle,
        subtitle: l10n.educationBookWorldCupSubtitle,
        storyParagraphs: _splitParagraphs(l10n.educationBookWorldCupStory),
        accentColors: const <Color>[Color(0xFFE17C52), Color(0xFF633537)],
      ),
      _BookChapter(
        chapterLabel: l10n.educationBookClubLabel,
        title: l10n.educationBookClubTitle,
        subtitle: l10n.educationBookClubSubtitle,
        storyParagraphs: _splitParagraphs(l10n.educationBookClubStory),
        accentColors: const <Color>[Color(0xFF5E9D89), Color(0xFF234D45)],
      ),
      _BookChapter(
        chapterLabel: l10n.educationBookTacticsLabel,
        title: l10n.educationBookTacticsTitle,
        subtitle: l10n.educationBookTacticsSubtitle,
        storyParagraphs: _splitParagraphs(l10n.educationBookTacticsStory),
        accentColors: const <Color>[Color(0xFF678DD8), Color(0xFF2D416B)],
      ),
      _BookChapter(
        chapterLabel: l10n.educationBookLegendsLabel,
        title: l10n.educationBookLegendsTitle,
        subtitle: l10n.educationBookLegendsSubtitle,
        storyParagraphs: _splitParagraphs(l10n.educationBookLegendsStory),
        accentColors: const <Color>[Color(0xFFC26AA7), Color(0xFF5A3153)],
      ),
      _BookChapter(
        chapterLabel: l10n.educationBookAsiaLabel,
        title: l10n.educationBookAsiaTitle,
        subtitle: l10n.educationBookAsiaSubtitle,
        storyParagraphs: _splitParagraphs(l10n.educationBookAsiaStory),
        accentColors: const <Color>[Color(0xFF4D9EB7), Color(0xFF204A57)],
      ),
      _BookChapter(
        chapterLabel: l10n.educationBookWomenLabel,
        title: l10n.educationBookWomenTitle,
        subtitle: l10n.educationBookWomenSubtitle,
        storyParagraphs: _splitParagraphs(l10n.educationBookWomenStory),
        accentColors: const <Color>[Color(0xFFD97070), Color(0xFF63363A)],
      ),
      _BookChapter(
        chapterLabel: l10n.educationBookModernLabel,
        title: l10n.educationBookModernTitle,
        subtitle: l10n.educationBookModernSubtitle,
        storyParagraphs: _splitParagraphs(l10n.educationBookModernStory),
        accentColors: const <Color>[Color(0xFF8A6BE0), Color(0xFF413563)],
      ),
      _BookChapter(
        chapterLabel: l10n.educationBookFinaleLabel,
        title: l10n.educationBookFinaleTitle,
        subtitle: l10n.educationBookFinaleSubtitle,
        storyParagraphs: _splitParagraphs(l10n.educationBookFinaleStory),
        accentColors: const <Color>[Color(0xFFB07A45), Color(0xFF4F3A2A)],
      ),
    ];
  }

  List<String> _splitParagraphs(String value) {
    return value
        .split('\n\n')
        .map((entry) => entry.trim())
        .where((entry) => entry.isNotEmpty)
        .toList(growable: false);
  }
}

class _BookProgressCard extends StatelessWidget {
  final String title;
  final String chapterLabel;
  final String progressLabel;
  final String swipeHint;
  final int pageCount;
  final int currentIndex;

  const _BookProgressCard({
    required this.title,
    required this.chapterLabel,
    required this.progressLabel,
    required this.swipeHint,
    required this.pageCount,
    required this.currentIndex,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: theme.colorScheme.outline.withValues(alpha: 0.16),
        ),
        boxShadow: theme.brightness == Brightness.dark
            ? null
            : const <BoxShadow>[
                BoxShadow(
                  color: Color(0x120E1726),
                  blurRadius: 16,
                  offset: Offset(0, 8),
                ),
              ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  chapterLabel,
                  style: theme.textTheme.labelLarge?.copyWith(
                    fontWeight: FontWeight.w900,
                    color: theme.colorScheme.primary,
                  ),
                ),
              ),
              Text(
                progressLabel,
                style: theme.textTheme.labelLarge?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            title,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: List<Widget>.generate(pageCount, (index) {
              final isActive = currentIndex == index;
              return AnimatedContainer(
                duration: const Duration(milliseconds: 220),
                margin: EdgeInsets.only(right: index == pageCount - 1 ? 0 : 6),
                width: isActive ? 22 : 8,
                height: 8,
                decoration: BoxDecoration(
                  color: isActive
                      ? theme.colorScheme.primary
                      : theme.colorScheme.outline.withValues(alpha: 0.25),
                  borderRadius: BorderRadius.circular(999),
                ),
              );
            }),
          ),
          const SizedBox(height: 10),
          Text(
            swipeHint,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w600,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}

class _BookPageCard extends StatelessWidget {
  final int pageIndex;
  final _BookChapter chapter;
  final String pageLabel;

  const _BookPageCard({
    required this.pageIndex,
    required this.chapter,
    required this.pageLabel,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final accent = chapter.accentColors.last;

    return Padding(
      padding: const EdgeInsets.fromLTRB(6, 4, 6, 8),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(32),
          boxShadow: theme.brightness == Brightness.dark
              ? null
              : const <BoxShadow>[
                  BoxShadow(
                    color: Color(0x24161F2F),
                    blurRadius: 26,
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
                      : const Color(0xFFFAF4E6),
                  theme.brightness == Brightness.dark
                      ? theme.colorScheme.surfaceContainerHighest
                      : const Color(0xFFF4E7D1),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              border: Border.all(color: accent.withValues(alpha: 0.34)),
            ),
            child: Stack(
              fit: StackFit.expand,
              children: [
                Positioned(
                  left: 24,
                  top: 0,
                  bottom: 0,
                  child: Container(
                    width: 4,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: <Color>[
                          accent.withValues(alpha: 0.2),
                          accent.withValues(alpha: 0.45),
                          accent.withValues(alpha: 0.2),
                        ],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                ),
                Positioned(
                  right: -30,
                  top: -24,
                  child: Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      color: accent.withValues(alpha: 0.08),
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
                Positioned(
                  right: 24,
                  top: 22,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 7,
                    ),
                    decoration: BoxDecoration(
                      color: accent.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          pageLabel,
                          style: theme.textTheme.labelLarge?.copyWith(
                            color: accent,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                SingleChildScrollView(
                  key: ValueKey<String>('education-page-scroll-$pageIndex'),
                  padding: const EdgeInsets.fromLTRB(32, 28, 28, 40),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        chapter.chapterLabel,
                        style: theme.textTheme.labelLarge?.copyWith(
                          color: accent,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: 10),
                      ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 300),
                        child: Text(
                          chapter.title,
                          style: theme.textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.w900,
                            height: 1.12,
                            color: theme.colorScheme.onSurface,
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        chapter.subtitle,
                        style: theme.textTheme.titleSmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                          fontWeight: FontWeight.w700,
                          height: 1.35,
                        ),
                      ),
                      const SizedBox(height: 22),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.fromLTRB(18, 18, 18, 22),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.surface.withValues(
                            alpha: theme.brightness == Brightness.dark
                                ? 0.26
                                : 0.5,
                          ),
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(
                            color: accent.withValues(alpha: 0.16),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: chapter.storyParagraphs
                              .map(
                                (paragraph) => Padding(
                                  padding: const EdgeInsets.only(bottom: 16),
                                  child: Text(
                                    paragraph,
                                    style: theme.textTheme.bodyLarge?.copyWith(
                                      height: 1.8,
                                      fontWeight: FontWeight.w600,
                                      color: theme.colorScheme.onSurface,
                                    ),
                                  ),
                                ),
                              )
                              .toList(growable: false),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _BookChapter {
  final String chapterLabel;
  final String title;
  final String subtitle;
  final List<String> storyParagraphs;
  final List<Color> accentColors;

  const _BookChapter({
    required this.chapterLabel,
    required this.title,
    required this.subtitle,
    required this.storyParagraphs,
    required this.accentColors,
  });
}
