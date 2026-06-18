import 'package:flutter/material.dart';
import 'package:football_note/gen/app_localizations.dart';
import 'package:google_fonts/google_fonts.dart';

class WelcomeScreen extends StatefulWidget {
  final VoidCallback onStart;

  const WelcomeScreen({super.key, required this.onStart});

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen> {
  final PageController _pageController = PageController();
  int _selectedIndex = 0;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final slides = _buildSlides(l10n);
    final isLast = _selectedIndex == slides.length - 1;
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: scheme.surface,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: PageView.builder(
                key: const ValueKey('welcome-page-view'),
                controller: _pageController,
                itemCount: slides.length,
                onPageChanged: (index) =>
                    setState(() => _selectedIndex = index),
                itemBuilder: (context, index) {
                  return _WelcomeSlideView(slide: slides[index]);
                },
              ),
            ),
            _WelcomePagerBar(
              l10n: l10n,
              slideCount: slides.length,
              selectedIndex: _selectedIndex,
              isLast: isLast,
              onNext: () {
                if (isLast) {
                  widget.onStart();
                  return;
                }
                _pageController.nextPage(
                  duration: const Duration(milliseconds: 260),
                  curve: Curves.easeOutCubic,
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _WelcomeSlideView extends StatelessWidget {
  final _WelcomeSlide slide;

  const _WelcomeSlideView({required this.slide});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxHeight < 650;
        final topPadding = compact ? 18.0 : 30.0;
        const bottomPadding = 24.0;
        final contentMinHeight =
            (constraints.maxHeight - topPadding - bottomPadding)
                .clamp(0.0, double.infinity)
                .toDouble();
        return SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(24, topPadding, 24, bottomPadding),
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: contentMinHeight),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 560),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    _MascotStage(slide: slide, compact: compact),
                    SizedBox(height: compact ? 24 : 32),
                    Text(
                      slide.title,
                      textAlign: TextAlign.center,
                      style: GoogleFonts.gowunDodum(
                        textStyle: theme.textTheme.headlineMedium?.copyWith(
                          color: scheme.onSurface,
                          fontWeight: FontWeight.w700,
                          height: 1.16,
                          letterSpacing: 0,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      slide.body,
                      textAlign: TextAlign.center,
                      style: GoogleFonts.gowunDodum(
                        textStyle: theme.textTheme.titleMedium?.copyWith(
                          color: scheme.onSurfaceVariant,
                          fontWeight: FontWeight.w600,
                          height: 1.42,
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
      },
    );
  }
}

class _MascotStage extends StatelessWidget {
  final _WelcomeSlide slide;
  final bool compact;

  const _MascotStage({required this.slide, required this.compact});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final size = compact ? 188.0 : 226.0;
    return Center(
      child: Container(
        width: size,
        height: size,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: slide.accent.withValues(alpha: 0.10),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: slide.accent.withValues(alpha: 0.28)),
          boxShadow: [
            BoxShadow(
              color: slide.accent.withValues(alpha: 0.16),
              blurRadius: 28,
              offset: const Offset(0, 16),
            ),
          ],
        ),
        child: Image.asset(
          slide.assetPath,
          width: size * slide.assetScale,
          height: size * slide.assetScale,
          fit: BoxFit.contain,
          errorBuilder: (_, __, ___) {
            return Icon(
              slide.fallbackIcon,
              size: size * 0.42,
              color: scheme.primary,
            );
          },
        ),
      ),
    );
  }
}

class _WelcomePagerBar extends StatelessWidget {
  final AppLocalizations l10n;
  final int slideCount;
  final int selectedIndex;
  final bool isLast;
  final VoidCallback onNext;

  const _WelcomePagerBar({
    required this.l10n,
    required this.slideCount,
    required this.selectedIndex,
    required this.isLast,
    required this.onNext,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: scheme.surface,
        border: Border(top: BorderSide(color: scheme.outlineVariant)),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(22, 12, 22, 16),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    for (var index = 0; index < slideCount; index += 1) ...[
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 180),
                        width: index == selectedIndex ? 24 : 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: index == selectedIndex
                              ? scheme.primary
                              : scheme.outlineVariant,
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      if (index != slideCount - 1) const SizedBox(width: 6),
                    ],
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  l10n.welcomeGuideNextTabHint,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: scheme.onSurfaceVariant,
                        fontWeight: FontWeight.w700,
                      ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    key: ValueKey(
                      isLast ? 'welcome-start-button' : 'welcome-next-button',
                    ),
                    onPressed: onNext,
                    icon: Icon(
                      isLast
                          ? Icons.arrow_forward_rounded
                          : Icons.swipe_rounded,
                    ),
                    style: FilledButton.styleFrom(
                      minimumSize: const Size.fromHeight(52),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    label: Text(
                      isLast
                          ? l10n.welcomeGuidePrimaryAction
                          : l10n.tabGuideCoachMarkNext,
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
}

class _WelcomeSlide {
  final String title;
  final String body;
  final String assetPath;
  final double assetScale;
  final IconData fallbackIcon;
  final Color accent;

  const _WelcomeSlide({
    required this.title,
    required this.body,
    required this.assetPath,
    required this.assetScale,
    required this.fallbackIcon,
    required this.accent,
  });
}

List<_WelcomeSlide> _buildSlides(AppLocalizations l10n) {
  return <_WelcomeSlide>[
    _WelcomeSlide(
      title: l10n.welcomeGuideTitle,
      body: l10n.welcomeGuideIntro,
      assetPath: 'assets/images/challenge_rinzy_cheer.png',
      assetScale: 0.88,
      fallbackIcon: Icons.sports_rounded,
      accent: const Color(0xFF2563EB),
    ),
    _WelcomeSlide(
      title: l10n.welcomeSlideGemTitle,
      body: l10n.welcomeSlideGemBody,
      assetPath: 'assets/images/record_reward_gem_character.png',
      assetScale: 0.82,
      fallbackIcon: Icons.diamond_rounded,
      accent: const Color(0xFF0891B2),
    ),
    _WelcomeSlide(
      title: l10n.welcomeSlideFlameTitle,
      body: l10n.welcomeSlideFlameBody,
      assetPath: 'assets/images/passion_flame_character.png',
      assetScale: 0.84,
      fallbackIcon: Icons.local_fire_department_rounded,
      accent: const Color(0xFFEA580C),
    ),
  ];
}
