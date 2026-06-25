import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

class AppSkeletonBlock extends StatefulWidget {
  final double height;
  final double? width;
  final BorderRadius? borderRadius;

  const AppSkeletonBlock({
    super.key,
    required this.height,
    this.width,
    this.borderRadius,
  });

  @override
  State<AppSkeletonBlock> createState() => _AppSkeletonBlockState();
}

class _AppSkeletonBlockState extends State<AppSkeletonBlock>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final brightness = theme.brightness;
    final base = AppSurfaces.subtleColor(scheme, brightness);
    final highlight = Color.lerp(
          base,
          scheme.primary,
          brightness == Brightness.dark ? 0.16 : 0.08,
        ) ??
        base;

    return ExcludeSemantics(
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) {
          final value = Curves.easeInOut.transform(_controller.value);
          return SizedBox(
            width: widget.width ?? double.infinity,
            height: widget.height,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: Color.lerp(base, highlight, value),
                borderRadius: widget.borderRadius ?? AppRadius.small,
              ),
            ),
          );
        },
      ),
    );
  }
}

class AppSkeletonTextLines extends StatelessWidget {
  final int count;
  final List<double> widthFactors;
  final double height;
  final double spacing;

  const AppSkeletonTextLines({
    super.key,
    this.count = 3,
    this.widthFactors = const [0.86, 0.62, 0.74],
    this.height = 12,
    this.spacing = AppSpacing.sm,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (var index = 0; index < count; index += 1) ...[
          FractionallySizedBox(
            widthFactor: widthFactors[index % widthFactors.length],
            alignment: AlignmentDirectional.centerStart,
            child: AppSkeletonBlock(height: height),
          ),
          if (index != count - 1) SizedBox(height: spacing),
        ],
      ],
    );
  }
}

class AppSkeletonCard extends StatelessWidget {
  final bool showLeading;
  final int lineCount;
  final EdgeInsetsGeometry padding;
  final double leadingSize;
  final List<double> lineWidthFactors;

  const AppSkeletonCard({
    super.key,
    this.showLeading = true,
    this.lineCount = 3,
    this.padding = AppSpacing.card,
    this.leadingSize = 48,
    this.lineWidthFactors = const [0.78, 0.48, 0.68],
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final brightness = theme.brightness;
    return DecoratedBox(
      decoration: AppSurfaces.cardDecoration(scheme, brightness),
      child: Padding(
        padding: padding,
        child: Row(
          children: [
            if (showLeading) ...[
              AppSkeletonBlock(
                width: leadingSize,
                height: leadingSize,
                borderRadius: AppRadius.control,
              ),
              const SizedBox(width: AppSpacing.md),
            ],
            Expanded(
              child: AppSkeletonTextLines(
                count: lineCount,
                widthFactors: lineWidthFactors,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class AppSkeletonHeroCard extends StatelessWidget {
  const AppSkeletonHeroCard({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final brightness = theme.brightness;
    return DecoratedBox(
      decoration: AppSurfaces.subtleDecoration(scheme, brightness),
      child: const Padding(
        padding: AppSpacing.card,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AppSkeletonBlock(height: 24, width: 180),
            SizedBox(height: AppSpacing.md),
            AppSkeletonTextLines(
              count: 3,
              widthFactors: [0.92, 0.64, 0.76],
            ),
            SizedBox(height: AppSpacing.lg),
            Row(
              children: [
                Expanded(child: AppSkeletonBlock(height: 44)),
                SizedBox(width: AppSpacing.sm),
                Expanded(child: AppSkeletonBlock(height: 44)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class AppSkeletonList extends StatelessWidget {
  final int itemCount;
  final bool includeHero;
  final bool showLeading;
  final EdgeInsetsGeometry padding;
  final ScrollPhysics physics;

  const AppSkeletonList({
    super.key,
    this.itemCount = 5,
    this.includeHero = false,
    this.showLeading = true,
    this.padding = AppSpacing.screen,
    this.physics = const AlwaysScrollableScrollPhysics(),
  });

  @override
  Widget build(BuildContext context) {
    final totalCount = itemCount + (includeHero ? 1 : 0);
    return ListView.separated(
      physics: physics,
      padding: padding,
      itemCount: totalCount,
      separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.sm),
      itemBuilder: (context, index) {
        if (includeHero && index == 0) {
          return const AppSkeletonHeroCard();
        }
        return AppSkeletonCard(
          showLeading: showLeading,
          lineCount: index.isEven ? 3 : 2,
        );
      },
    );
  }
}
