import 'dart:async';
import 'dart:math';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../theme/app_motion.dart';

class AppSplashScreen extends StatefulWidget {
  final VoidCallback onCompleted;

  const AppSplashScreen({super.key, required this.onCompleted});

  @override
  State<AppSplashScreen> createState() => _AppSplashScreenState();
}

class _AppSplashScreenState extends State<AppSplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  Timer? _completionTimer;
  bool _completed = false;

  static const _duration = Duration(milliseconds: 3600);

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: _duration)
      ..addStatusListener((status) {
        if (status == AnimationStatus.completed) {
          _complete();
        }
      });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_controller.isAnimating || _controller.isCompleted) {
      return;
    }
    if (AppMotion.reduceMotion(context)) {
      _completionTimer = Timer(const Duration(milliseconds: 700), _complete);
      return;
    }
    _controller.forward();
  }

  @override
  void dispose() {
    _completionTimer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _complete() {
    if (_completed || !mounted) {
      return;
    }
    _completed = true;
    widget.onCompleted();
  }

  @override
  Widget build(BuildContext context) {
    final reduceMotion = AppMotion.reduceMotion(context);
    final isKo = Localizations.localeOf(context).languageCode == 'ko';
    final theme = Theme.of(context);

    return Scaffold(
      body: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF07131F),
              Color(0xFF0F2840),
              Color(0xFF104A55),
              Color(0xFF081A28),
            ],
          ),
        ),
        child: SafeArea(
          child: AnimatedBuilder(
            animation: _controller,
            builder: (context, _) {
              final t = reduceMotion ? 1.0 : _controller.value;
              final backgroundGlow = Curves.easeOut.transform(
                const Interval(0.0, 0.42).transform(t),
              );
              final headerOpacity = Curves.easeOut.transform(
                const Interval(0.08, 0.3).transform(t),
              );
              final boardReveal = Curves.easeOutCubic.transform(
                const Interval(0.12, 0.5).transform(t),
              );
              final connectionPulse = Curves.easeInOut.transform(
                const Interval(0.32, 0.84).transform(t),
              );
              final emblemBloom = Curves.easeOutCubic.transform(
                const Interval(0.58, 0.94).transform(t),
              );
              final footerOpacity = Curves.easeOut.transform(
                const Interval(0.52, 0.84).transform(t),
              );
              final roles = _buildRoleDescriptors(isKo);

              return LayoutBuilder(
                builder: (context, constraints) {
                  final size = constraints.biggest;
                  final center = Offset(size.width / 2, size.height * 0.54);
                  final boardRadius = min(size.width * 0.29, 142.0);

                  return Stack(
                    fit: StackFit.expand,
                    children: [
                      Positioned(
                        top: -56,
                        left: -44,
                        child: _EnergyGlow(
                          size: 240,
                          color: const Color(
                            0xFF67E8F9,
                          ).withValues(alpha: 0.18 + (backgroundGlow * 0.3)),
                        ),
                      ),
                      Positioned(
                        right: -62,
                        top: size.height * 0.18,
                        child: _EnergyGlow(
                          size: 210,
                          color: const Color(
                            0xFFFDE68A,
                          ).withValues(alpha: 0.1 + (backgroundGlow * 0.2)),
                        ),
                      ),
                      Positioned(
                        left: -12,
                        bottom: -48,
                        child: _EnergyGlow(
                          size: 280,
                          color: const Color(
                            0xFF38BDF8,
                          ).withValues(alpha: 0.08 + (backgroundGlow * 0.18)),
                        ),
                      ),
                      Positioned.fill(
                        child: CustomPaint(
                          painter: _AtmospherePainter(
                            progress: t,
                            boardCenter: center,
                            boardRadius: boardRadius,
                            connectionPulse: connectionPulse,
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(24, 26, 24, 28),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Opacity(
                              opacity: headerOpacity,
                              child: Transform.translate(
                                offset: Offset(
                                  0,
                                  lerpDouble(18, 0, headerOpacity)!,
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 12,
                                        vertical: 7,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Colors.white.withValues(
                                          alpha: 0.1,
                                        ),
                                        borderRadius: BorderRadius.circular(
                                          999,
                                        ),
                                        border: Border.all(
                                          color: Colors.white.withValues(
                                            alpha: 0.14,
                                          ),
                                        ),
                                      ),
                                      child: Text(
                                        isKo
                                            ? '4명의 역할이 첫 전술을 정렬하는 중'
                                            : 'Four roles align the first play',
                                        style: theme.textTheme.labelLarge
                                            ?.copyWith(
                                              color: Colors.white.withValues(
                                                alpha: 0.9,
                                              ),
                                              fontWeight: FontWeight.w700,
                                              letterSpacing: 0.2,
                                            ),
                                      ),
                                    ),
                                    const SizedBox(height: 16),
                                    Text(
                                      isKo
                                          ? '시작부터 완성도 있게.'
                                          : 'Start with crafted motion.',
                                      style: theme.textTheme.headlineMedium
                                          ?.copyWith(
                                            color: Colors.white,
                                            fontWeight: FontWeight.w900,
                                            height: 1.1,
                                          ),
                                    ),
                                    const SizedBox(height: 10),
                                    Text(
                                      isKo
                                          ? '전략, 리듬, 디테일, 애니메이션이 한 장면으로 모이며 오늘의 훈련을 엽니다.'
                                          : 'Strategy, rhythm, detail, and animation converge to open today\'s training.',
                                      style: theme.textTheme.bodyMedium
                                          ?.copyWith(
                                            color: Colors.white.withValues(
                                              alpha: 0.78,
                                            ),
                                            height: 1.5,
                                          ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const Spacer(),
                            SizedBox(
                              height: min(430, size.height * 0.54),
                              child: Stack(
                                clipBehavior: Clip.none,
                                children: [
                                  Positioned.fill(
                                    child: _DiscussionBoard(
                                      center: center.translate(
                                        0,
                                        -size.height * 0.18,
                                      ),
                                      radius: boardRadius,
                                      progress: boardReveal,
                                      pulse: connectionPulse,
                                    ),
                                  ),
                                  ...List.generate(roles.length, (index) {
                                    final role = roles[index];
                                    final cardProgress = Curves.easeOutBack
                                        .transform(
                                          Interval(
                                            role.intervalStart,
                                            role.intervalEnd,
                                          ).transform(t),
                                        );
                                    final anchor = center.translate(
                                      0,
                                      -size.height * 0.18,
                                    );
                                    final target =
                                        anchor +
                                        Offset(
                                          cos(role.angle) *
                                              (boardRadius + role.distance),
                                          sin(role.angle) *
                                              (boardRadius + role.distance),
                                        );
                                    final start =
                                        anchor +
                                        Offset(
                                          cos(role.angle) *
                                              (boardRadius +
                                                  role.distance +
                                                  88),
                                          sin(role.angle) *
                                              (boardRadius +
                                                  role.distance +
                                                  88),
                                        );
                                    final cardOffset = Offset.lerp(
                                      start,
                                      target,
                                      cardProgress,
                                    )!;
                                    final cardScale = lerpDouble(
                                      0.72,
                                      1.0,
                                      cardProgress,
                                    )!;
                                    final linkOpacity = lerpDouble(
                                      0.0,
                                      0.92,
                                      Curves.easeOut.transform(
                                        Interval(
                                          role.intervalStart + 0.06,
                                          min(role.intervalEnd + 0.12, 1.0),
                                        ).transform(t),
                                      ),
                                    )!;

                                    return Positioned(
                                      left: cardOffset.dx - 80,
                                      top: cardOffset.dy - 38,
                                      child: Opacity(
                                        opacity: cardProgress,
                                        child: Transform.scale(
                                          scale: cardScale,
                                          child: _RoleCard(
                                            role: role,
                                            linkOpacity: linkOpacity,
                                            pulse: connectionPulse,
                                          ),
                                        ),
                                      ),
                                    );
                                  }),
                                  Positioned(
                                    left: center.dx - boardRadius - 64,
                                    top:
                                        center.dy -
                                        size.height * 0.18 -
                                        boardRadius -
                                        64,
                                    child: IgnorePointer(
                                      child: SizedBox(
                                        width: (boardRadius + 64) * 2,
                                        height: (boardRadius + 64) * 2,
                                        child: CustomPaint(
                                          painter: _ConnectionPainter(
                                            roles: roles,
                                            boardRadius: boardRadius,
                                            pulse: connectionPulse,
                                            reveal: boardReveal,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                  Positioned(
                                    left: center.dx - 74,
                                    top: center.dy - size.height * 0.18 - 74,
                                    child: _CenterEmblem(
                                      bloom: emblemBloom,
                                      pulse: connectionPulse,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const Spacer(),
                            Opacity(
                              opacity: footerOpacity,
                              child: Transform.translate(
                                offset: Offset(
                                  0,
                                  lerpDouble(22, 0, footerOpacity)!,
                                ),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        isKo
                                            ? '전술 보드 위에서 흐름을 맞춘 뒤 홈으로 진입합니다.'
                                            : 'The team syncs on the tactic board before entering home.',
                                        style: theme.textTheme.bodySmall
                                            ?.copyWith(
                                              color: Colors.white.withValues(
                                                alpha: 0.75,
                                              ),
                                              height: 1.55,
                                            ),
                                      ),
                                    ),
                                    const SizedBox(width: 16),
                                    SizedBox(
                                      width: 64,
                                      child: LinearProgressIndicator(
                                        value: reduceMotion
                                            ? null
                                            : max(t, 0.08),
                                        minHeight: 4,
                                        borderRadius: BorderRadius.circular(
                                          999,
                                        ),
                                        backgroundColor: Colors.white
                                            .withValues(alpha: 0.12),
                                        valueColor:
                                            const AlwaysStoppedAnimation(
                                              Color(0xFFFDE68A),
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
                    ],
                  );
                },
              );
            },
          ),
        ),
      ),
    );
  }

  List<_RoleDescriptor> _buildRoleDescriptors(bool isKo) {
    return [
      _RoleDescriptor(
        angle: -2.42,
        distance: 44,
        intervalStart: 0.14,
        intervalEnd: 0.34,
        color: const Color(0xFF7DD3FC),
        accent: const Color(0xFF38BDF8),
        icon: Icons.route_rounded,
        title: isKo ? '전략가' : 'Strategist',
        subtitle: isKo ? '전개 흐름 설계' : 'Builds the flow',
      ),
      _RoleDescriptor(
        angle: -0.88,
        distance: 50,
        intervalStart: 0.22,
        intervalEnd: 0.42,
        color: const Color(0xFFFDE68A),
        accent: const Color(0xFFF59E0B),
        icon: Icons.auto_awesome_motion_rounded,
        title: isKo ? '애니메이션' : 'Motion Lead',
        subtitle: isKo ? '타이밍과 탄성 조율' : 'Tunes timing',
      ),
      _RoleDescriptor(
        angle: 0.76,
        distance: 50,
        intervalStart: 0.3,
        intervalEnd: 0.5,
        color: const Color(0xFF86EFAC),
        accent: const Color(0xFF10B981),
        icon: Icons.palette_outlined,
        title: isKo ? '비주얼' : 'Visual',
        subtitle: isKo ? '명암과 디테일 정리' : 'Shapes details',
      ),
      _RoleDescriptor(
        angle: 2.34,
        distance: 44,
        intervalStart: 0.38,
        intervalEnd: 0.58,
        color: const Color(0xFFF9A8D4),
        accent: const Color(0xFFEC4899),
        icon: Icons.sports_soccer_rounded,
        title: isKo ? '플레이 코치' : 'Play Coach',
        subtitle: isKo ? '앱 첫인상 검수' : 'Checks impact',
      ),
    ];
  }
}

class _DiscussionBoard extends StatelessWidget {
  final Offset center;
  final double radius;
  final double progress;
  final double pulse;

  const _DiscussionBoard({
    required this.center,
    required this.radius,
    required this.progress,
    required this.pulse,
  });

  @override
  Widget build(BuildContext context) {
    final boardSize = radius * 2.2;

    return Stack(
      clipBehavior: Clip.none,
      children: [
        Positioned(
          left: center.dx - (boardSize / 2),
          top: center.dy - (boardSize / 2),
          child: Transform.scale(
            scale: lerpDouble(0.82, 1.0, progress)!,
            child: Opacity(
              opacity: progress,
              child: Container(
                width: boardSize,
                height: boardSize,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      Colors.white.withValues(alpha: 0.12),
                      Colors.white.withValues(alpha: 0.01),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
        Positioned(
          left: center.dx - radius,
          top: center.dy - radius,
          child: Transform.scale(
            scale: lerpDouble(0.76, 1.0, progress)!,
            child: Transform.rotate(
              angle: pulse * 0.18,
              child: Opacity(
                opacity: progress,
                child: Container(
                  width: radius * 2,
                  height: radius * 2,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withValues(alpha: 0.05),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.12),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF38BDF8).withValues(alpha: 0.12),
                        blurRadius: 36,
                      ),
                    ],
                  ),
                  child: CustomPaint(
                    painter: _BoardPainter(progress: progress, pulse: pulse),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _CenterEmblem extends StatelessWidget {
  final double bloom;
  final double pulse;

  const _CenterEmblem({required this.bloom, required this.pulse});

  @override
  Widget build(BuildContext context) {
    final ringScale = lerpDouble(0.72, 1.22, bloom)!;
    final badgeScale = lerpDouble(0.44, 1.0, bloom)!;

    return SizedBox(
      width: 148,
      height: 148,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Transform.scale(
            scale: ringScale,
            child: Container(
              width: 132,
              height: 132,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    const Color(0xFFFDE68A).withValues(alpha: 0.22 * bloom),
                    const Color(0xFF38BDF8).withValues(alpha: 0.08 * bloom),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
          Container(
            width: 112,
            height: 112,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.16 + (pulse * 0.08)),
              ),
            ),
          ),
          Transform.scale(
            scale: badgeScale,
            child: Container(
              width: 86,
              height: 86,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFFFEF3C7), Color(0xFF67E8F9)],
                ),
                boxShadow: [
                  BoxShadow(
                    color: const Color(
                      0xFF67E8F9,
                    ).withValues(alpha: 0.28 * bloom),
                    blurRadius: 28,
                    spreadRadius: 2,
                  ),
                ],
              ),
              padding: const EdgeInsets.all(20),
              child: SvgPicture.asset('assets/images/icon_ball.svg'),
            ),
          ),
        ],
      ),
    );
  }
}

class _RoleCard extends StatelessWidget {
  final _RoleDescriptor role;
  final double linkOpacity;
  final double pulse;

  const _RoleCard({
    required this.role,
    required this.linkOpacity,
    required this.pulse,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      width: 160,
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white.withValues(alpha: 0.18),
            Colors.white.withValues(alpha: 0.08),
          ],
        ),
        border: Border.all(
          color: role.color.withValues(alpha: 0.32 + (pulse * 0.1)),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.12),
            blurRadius: 20,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: role.color.withValues(alpha: 0.18),
                ),
                child: Icon(role.icon, color: role.color, size: 18),
              ),
              const Spacer(),
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: role.accent.withValues(alpha: linkOpacity),
                  boxShadow: [
                    BoxShadow(
                      color: role.accent.withValues(alpha: linkOpacity * 0.7),
                      blurRadius: 12,
                      spreadRadius: 1,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            role.title,
            style: theme.textTheme.titleMedium?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            role.subtitle,
            style: theme.textTheme.bodySmall?.copyWith(
              color: Colors.white.withValues(alpha: 0.72),
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _RoleDescriptor {
  final double angle;
  final double distance;
  final double intervalStart;
  final double intervalEnd;
  final Color color;
  final Color accent;
  final IconData icon;
  final String title;
  final String subtitle;

  const _RoleDescriptor({
    required this.angle,
    required this.distance,
    required this.intervalStart,
    required this.intervalEnd,
    required this.color,
    required this.accent,
    required this.icon,
    required this.title,
    required this.subtitle,
  });
}

class _BoardPainter extends CustomPainter {
  final double progress;
  final double pulse;

  const _BoardPainter({required this.progress, required this.pulse});

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = size.width / 2;
    final basePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4
      ..color = Colors.white.withValues(alpha: 0.13 * progress);

    canvas.drawCircle(center, radius * 0.78, basePaint);
    canvas.drawCircle(center, radius * 0.46, basePaint);

    final crossPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.1 * progress)
      ..strokeWidth = 1;

    canvas.drawLine(
      Offset(center.dx - radius * 0.8, center.dy),
      Offset(center.dx + radius * 0.8, center.dy),
      crossPaint,
    );
    canvas.drawLine(
      Offset(center.dx, center.dy - radius * 0.8),
      Offset(center.dx, center.dy + radius * 0.8),
      crossPaint,
    );

    final path = Path()
      ..moveTo(center.dx - radius * 0.55, center.dy + radius * 0.28)
      ..quadraticBezierTo(
        center.dx - radius * 0.2,
        center.dy - radius * 0.26,
        center.dx + radius * 0.24,
        center.dy - radius * 0.08,
      )
      ..quadraticBezierTo(
        center.dx + radius * 0.46,
        center.dy + radius * 0.02,
        center.dx + radius * 0.62,
        center.dy - radius * 0.32,
      );

    final tacticPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round
      ..shader = const LinearGradient(
        colors: [Color(0xFF67E8F9), Color(0xFFFDE68A)],
      ).createShader(Offset.zero & size);
    final metric = path.computeMetrics().first;
    final visiblePath = metric.extractPath(
      0,
      metric.length * (0.34 + (pulse * 0.66)),
    );
    canvas.drawPath(visiblePath, tacticPaint);

    final dotPaint = Paint()
      ..style = PaintingStyle.fill
      ..color = const Color(0xFFFDE68A).withValues(alpha: 0.92);
    canvas.drawCircle(
      Offset(center.dx - radius * 0.55, center.dy + radius * 0.28),
      4,
      dotPaint,
    );
    canvas.drawCircle(
      Offset(center.dx + radius * 0.62, center.dy - radius * 0.32),
      4,
      dotPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _BoardPainter oldDelegate) {
    return oldDelegate.progress != progress || oldDelegate.pulse != pulse;
  }
}

class _ConnectionPainter extends CustomPainter {
  final List<_RoleDescriptor> roles;
  final double boardRadius;
  final double pulse;
  final double reveal;

  const _ConnectionPainter({
    required this.roles,
    required this.boardRadius,
    required this.pulse,
    required this.reveal,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final ringPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.1
      ..color = Colors.white.withValues(alpha: 0.08 + (pulse * 0.06));

    canvas.drawCircle(center, boardRadius + 28, ringPaint);

    for (final role in roles) {
      final target =
          center +
          Offset(
            cos(role.angle) * (boardRadius + role.distance - 4),
            sin(role.angle) * (boardRadius + role.distance - 4),
          );
      final path = Path()
        ..moveTo(center.dx, center.dy)
        ..quadraticBezierTo(
          center.dx + cos(role.angle) * (boardRadius * 0.6),
          center.dy + sin(role.angle) * (boardRadius * 0.6),
          target.dx,
          target.dy,
        );
      final paint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5
        ..strokeCap = StrokeCap.round
        ..shader = LinearGradient(
          colors: [
            role.accent.withValues(alpha: 0.0),
            role.accent.withValues(alpha: 0.6 * reveal),
            Colors.white.withValues(alpha: 0.8 * reveal),
          ],
        ).createShader(Offset.zero & size);
      final metric = path.computeMetrics().first;
      final visible = metric.extractPath(
        0,
        metric.length * (0.22 + (pulse * 0.78)),
      );
      canvas.drawPath(visible, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _ConnectionPainter oldDelegate) {
    return oldDelegate.pulse != pulse ||
        oldDelegate.reveal != reveal ||
        oldDelegate.boardRadius != boardRadius ||
        oldDelegate.roles != roles;
  }
}

class _AtmospherePainter extends CustomPainter {
  final double progress;
  final Offset boardCenter;
  final double boardRadius;
  final double connectionPulse;

  const _AtmospherePainter({
    required this.progress,
    required this.boardCenter,
    required this.boardRadius,
    required this.connectionPulse,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final gridPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1
      ..color = Colors.white.withValues(alpha: 0.04 + (progress * 0.02));
    const cell = 34.0;
    for (double x = 0; x <= size.width; x += cell) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), gridPaint);
    }
    for (double y = 0; y <= size.height; y += cell) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    final sweepRect = Rect.fromCircle(
      center: boardCenter,
      radius: boardRadius * (1.5 + (connectionPulse * 0.2)),
    );
    final sweepPaint = Paint()
      ..shader = SweepGradient(
        startAngle: -pi / 2,
        endAngle: pi * 1.5,
        transform: GradientRotation(progress * pi * 0.9),
        colors: [
          Colors.transparent,
          const Color(0xFF67E8F9).withValues(alpha: 0.0),
          const Color(0xFF67E8F9).withValues(alpha: 0.16),
          Colors.transparent,
        ],
        stops: const [0.0, 0.54, 0.72, 1.0],
      ).createShader(sweepRect)
      ..blendMode = BlendMode.plus;
    canvas.drawCircle(
      boardCenter,
      boardRadius * (1.35 + (connectionPulse * 0.08)),
      sweepPaint,
    );

    final particlePaint = Paint()..style = PaintingStyle.fill;
    for (var i = 0; i < 12; i++) {
      final orbital = progress * 2.4 + (i * 0.55);
      final radius = boardRadius * (1.2 + ((i % 3) * 0.17));
      final point =
          boardCenter +
          Offset(cos(orbital) * radius, sin(orbital * 1.14) * radius * 0.72);
      particlePaint.color = const Color(
        0xFFFDE68A,
      ).withValues(alpha: 0.08 + ((i % 4) * 0.03));
      canvas.drawCircle(point, 1.8 + ((i % 3) * 0.7), particlePaint);
    }
  }

  @override
  bool shouldRepaint(covariant _AtmospherePainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.boardCenter != boardCenter ||
        oldDelegate.boardRadius != boardRadius ||
        oldDelegate.connectionPulse != connectionPulse;
  }
}

class _EnergyGlow extends StatelessWidget {
  final double size;
  final Color color;

  const _EnergyGlow({required this.size, required this.color});

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(colors: [color, color.withValues(alpha: 0)]),
        ),
      ),
    );
  }
}
