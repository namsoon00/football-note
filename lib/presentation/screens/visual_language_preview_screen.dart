import 'package:flutter/material.dart';

class VisualLanguagePreviewScreen extends StatelessWidget {
  const VisualLanguagePreviewScreen({super.key});

  bool _isKo(BuildContext context) =>
      Localizations.localeOf(context).languageCode == 'ko';

  @override
  Widget build(BuildContext context) {
    final isKo = _isKo(context);
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: const Color(0xFFEEE7DC),
      appBar: AppBar(
        title: Text(isKo ? '그림 언어 시안' : 'Visual Language Preview'),
        backgroundColor: const Color(0xFFEEE7DC),
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        children: [
          _IntroCard(isKo: isKo),
          const SizedBox(height: 16),
          _SectionTitle(
            title: isKo ? '홈 카드' : 'Home Cards',
            subtitle: isKo
                ? '오늘 해야 할 일을 그림으로 먼저 이해하게 합니다.'
                : 'The day should read through illustrations first.',
          ),
          const SizedBox(height: 12),
          _HomeHeroCard(isKo: isKo),
          const SizedBox(height: 12),
          _QuickActionGrid(isKo: isKo),
          const SizedBox(height: 20),
          _SectionTitle(
            title: isKo ? '성장 카드' : 'Growth Card',
            subtitle: isKo
                ? '숫자보다 성장 장면이 먼저 보이도록 설계합니다.'
                : 'Progress should feel visual before it feels numeric.',
          ),
          const SizedBox(height: 12),
          _LevelShowcaseCard(isKo: isKo),
          const SizedBox(height: 20),
          _SectionTitle(
            title: isKo ? '다이어리 스티커' : 'Diary Stickers',
            subtitle: isKo
                ? '감정과 상태를 작은 장면 스티커로 읽게 합니다.'
                : 'Mood and status should read as tiny scenes.',
          ),
          const SizedBox(height: 12),
          _DiaryStickerPreview(isKo: isKo),
          const SizedBox(height: 20),
          _SectionTitle(
            title: isKo ? '퀴즈 상황 카드' : 'Quiz Scenario Card',
            subtitle: isKo
                ? '읽는 문제보다 보는 문제를 늘리기 위한 방향입니다.'
                : 'A direction for more visual, match-sense questions.',
          ),
          const SizedBox(height: 12),
          _QuizScenarioPreview(isKo: isKo, accent: scheme.primary),
          const SizedBox(height: 20),
          _SectionTitle(
            title: isKo ? '캘린더 아이콘 체계' : 'Calendar Icon System',
            subtitle: isKo
                ? '훈련, 경기, 회복을 점 대신 의미 있는 배지로 구분합니다.'
                : 'Training, match, and recovery read as badges, not dots.',
          ),
          const SizedBox(height: 12),
          _CalendarBadgePreview(isKo: isKo),
        ],
      ),
    );
  }
}

class _IntroCard extends StatelessWidget {
  final bool isKo;

  const _IntroCard({required this.isKo});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF203246), Color(0xFF41556D)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(22),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            isKo
                ? '단순하지만 유치하지 않은 스포츠 그래픽'
                : 'Simple, but not childish sports graphics',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            isKo
                ? '부드러운 캐릭터보다 축구 브랜드처럼 보이는 단단한 플랫 그래픽 방향으로 다시 잡은 시안입니다.'
                : 'A tougher, more premium football-brand direction instead of soft childlike graphics.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  height: 1.55,
                  color: const Color(0xFFD9E2EB),
                ),
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;
  final String subtitle;

  const _SectionTitle({required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w900,
                color: const Color(0xFF1B2938),
              ),
        ),
        const SizedBox(height: 4),
        Text(
          subtitle,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: const Color(0xFF5F5A54),
                height: 1.45,
              ),
        ),
      ],
    );
  }
}

class _HomeHeroCard extends StatelessWidget {
  final bool isKo;

  const _HomeHeroCard({required this.isKo});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFFF8F4EE),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFD8CEC2)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x10000000),
            blurRadius: 14,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          const _GroundScene(
            size: 124,
            base: Color(0xFF74B06A),
            accent: Color(0xFFF28C45),
            icon: Icons.sports_soccer,
            badgeIcon: Icons.check_rounded,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isKo ? '오늘의 홈' : 'Today',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w900,
                        color: const Color(0xFF172533),
                      ),
                ),
                const SizedBox(height: 8),
                Text(
                  isKo
                      ? '4월 1일, 패스 훈련과 다이어리가 남아 있어요'
                      : 'Apr 1, pass training and diary are waiting',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: const Color(0xFF23384C),
                        height: 1.35,
                      ),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _StateChip(
                      color: const Color(0xFFE6F4E1),
                      text: isKo ? '훈련 완료' : 'Training done',
                    ),
                    _StateChip(
                      color: const Color(0xFFFFF1DE),
                      text: isKo ? '퀴즈 1개' : '1 quiz',
                    ),
                    _StateChip(
                      color: const Color(0xFFE8F2FB),
                      text: isKo ? '다이어리 작성' : 'Write diary',
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _QuickActionGrid extends StatelessWidget {
  final bool isKo;

  const _QuickActionGrid({required this.isKo});

  @override
  Widget build(BuildContext context) {
    final items = [
      (
        icon: Icons.edit_note_rounded,
        color: const Color(0xFFE8F4E3),
        label: isKo ? '훈련 기록' : 'Log',
      ),
      (
        icon: Icons.calendar_month_rounded,
        color: const Color(0xFFFFF0DD),
        label: isKo ? '훈련 계획' : 'Plan',
      ),
      (
        icon: Icons.quiz_rounded,
        color: const Color(0xFFE6EDF8),
        label: isKo ? '퀴즈' : 'Quiz',
      ),
      (
        icon: Icons.menu_book_rounded,
        color: const Color(0xFFF6EADA),
        label: isKo ? '다이어리' : 'Diary',
      ),
    ];

    return GridView.builder(
      itemCount: items.length,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
        childAspectRatio: 1.12,
      ),
      itemBuilder: (context, index) {
        final item = items[index];
        return Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: const Color(0xFFF8F4EE),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFFD8CEC2)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: const Color(0xFF152433),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Stack(
                    children: [
                      Positioned(
                        left: 12,
                        top: 12,
                        child: Container(
                          width: 34,
                          height: 4,
                          decoration: BoxDecoration(
                            color: item.color,
                            borderRadius: BorderRadius.circular(999),
                          ),
                        ),
                      ),
                      Center(
                        child: Icon(
                          item.icon,
                          size: 34,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Text(
                item.label,
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: const Color(0xFF172533),
                    ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _LevelShowcaseCard extends StatelessWidget {
  final bool isKo;

  const _LevelShowcaseCard({required this.isKo});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFF24364B),
        borderRadius: BorderRadius.circular(28),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 4,
            child: AspectRatio(
              aspectRatio: 0.9,
              child: Container(
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF3B5677), Color(0xFF1F2D3E)],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Positioned(
                      bottom: 22,
                      child: Container(
                        width: 84,
                        height: 18,
                        decoration: BoxDecoration(
                          color: const Color(0xFF6FAF5F),
                          borderRadius: BorderRadius.circular(18),
                        ),
                      ),
                    ),
                    Positioned(
                      bottom: 40,
                      child: Container(
                        width: 62,
                        height: 100,
                        decoration: BoxDecoration(
                          color: const Color(0xFFF28C45),
                          borderRadius: BorderRadius.circular(26),
                        ),
                      ),
                    ),
                    Positioned(
                      top: 28,
                      child: Container(
                        width: 44,
                        height: 44,
                        decoration: const BoxDecoration(
                          color: Color(0xFFF6E7A8),
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                    const Positioned(
                      left: 22,
                      top: 34,
                      child: Icon(Icons.sports,
                          color: Color(0xFFF5F5F5), size: 22),
                    ),
                    const Positioned(
                      right: 20,
                      top: 32,
                      child: Icon(Icons.auto_awesome,
                          color: Color(0xFFF6E7A8), size: 22),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            flex: 5,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Lv.5 Playmaker',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                      ),
                ),
                const SizedBox(height: 8),
                Text(
                  isKo
                      ? '선수 카드가 자라나는 느낌으로 레벨을 보여줍니다.'
                      : 'Leveling should feel like a growing player card.',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: const Color(0xFFD6E0EA),
                        height: 1.5,
                      ),
                ),
                const SizedBox(height: 14),
                ClipRRect(
                  borderRadius: BorderRadius.circular(99),
                  child: const LinearProgressIndicator(
                    value: 0.72,
                    minHeight: 10,
                    backgroundColor: Colors.white24,
                    valueColor:
                        AlwaysStoppedAnimation<Color>(Color(0xFFF5C15D)),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  isKo ? '다음 레벨까지 40 XP' : '40 XP to next level',
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        color: const Color(0xFFF9E8B7),
                        fontWeight: FontWeight.w800,
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

class _DiaryStickerPreview extends StatelessWidget {
  final bool isKo;

  const _DiaryStickerPreview({required this.isKo});

  @override
  Widget build(BuildContext context) {
    final items = [
      (
        icon: Icons.local_fire_department_rounded,
        color: const Color(0xFFFFE7D6),
        label: isKo ? '불타오름' : 'On fire',
      ),
      (
        icon: Icons.psychology_alt_rounded,
        color: const Color(0xFFE7F0FF),
        label: isKo ? '집중' : 'Focused',
      ),
      (
        icon: Icons.water_drop_rounded,
        color: const Color(0xFFE3F5FF),
        label: isKo ? '회복 필요' : 'Recover',
      ),
      (
        icon: Icons.mood_rounded,
        color: const Color(0xFFFFF0D9),
        label: isKo ? '뿌듯' : 'Proud',
      ),
    ];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF8F4EE),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFD8CEC2)),
      ),
      child: Wrap(
        spacing: 10,
        runSpacing: 10,
        children: items.map((item) {
          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFD9CEC2)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 26,
                  height: 26,
                  decoration: BoxDecoration(
                    color: item.color,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    item.icon,
                    size: 15,
                    color: const Color(0xFF172533),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  item.label,
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: const Color(0xFF2A3746),
                      ),
                ),
              ],
            ),
          );
        }).toList(growable: false),
      ),
    );
  }
}

class _QuizScenarioPreview extends StatelessWidget {
  final bool isKo;
  final Color accent;

  const _QuizScenarioPreview({required this.isKo, required this.accent});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF8F4EE),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFD8CEC2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            isKo ? '문제 3/5' : 'Question 3/5',
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: const Color(0xFF6E665D),
                ),
          ),
          const SizedBox(height: 12),
          Container(
            height: 180,
            decoration: BoxDecoration(
              color: const Color(0xFF152433),
              borderRadius: BorderRadius.circular(18),
            ),
            child: Stack(
              children: [
                Positioned.fill(
                  child: CustomPaint(painter: _MiniPitchPainter()),
                ),
                const Positioned(
                    left: 64,
                    top: 74,
                    child: _PlayerDot(color: Color(0xFF24364B))),
                const Positioned(
                    left: 130,
                    top: 58,
                    child: _PlayerDot(color: Color(0xFF24364B))),
                const Positioned(
                    left: 236,
                    top: 78,
                    child: _PlayerDot(color: Color(0xFF24364B))),
                const Positioned(
                    left: 182,
                    top: 38,
                    child: _PlayerDot(color: Color(0xFFF28C45))),
                const Positioned(
                    left: 212,
                    top: 118,
                    child: _PlayerDot(color: Color(0xFFF28C45))),
                const Positioned(left: 148, top: 110, child: _BallDot()),
                const Positioned(
                  left: 140,
                  top: 92,
                  child: Icon(
                    Icons.arrow_upward_rounded,
                    color: Color(0xFFE0B85B),
                    size: 34,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Text(
            isKo
                ? '압박을 받는 이 장면에서 가장 좋은 다음 선택은?'
                : 'What is the best next choice under this pressure?',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w900,
                  color: const Color(0xFF24364B),
                ),
          ),
        ],
      ),
    );
  }
}

class _CalendarBadgePreview extends StatelessWidget {
  final bool isKo;

  const _CalendarBadgePreview({required this.isKo});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF8F4EE),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFD8CEC2)),
      ),
      child: Column(
        children: [
          Row(
            children: List.generate(7, (index) {
              final labels = isKo
                  ? const ['월', '화', '수', '목', '금', '토', '일']
                  : const ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
              return Expanded(
                child: Center(
                  child: Text(
                    labels[index],
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(
                          color: const Color(0xFF7A736B),
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                ),
              );
            }),
          ),
          const SizedBox(height: 12),
          Row(
            children: List.generate(7, (index) {
              final day = 1 + index;
              return Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 2),
                  child: Container(
                    height: 70,
                    decoration: BoxDecoration(
                      color: day == 3
                          ? const Color(0xFFF0E6D9)
                          : const Color(0xFFF3EDE5),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text('$day'),
                        const SizedBox(height: 8),
                        if (day == 1)
                          const _MiniBadge(
                              color: Color(0xFF6FAF5F),
                              icon: Icons.sports_soccer_rounded),
                        if (day == 2)
                          const _MiniBadge(
                              color: Color(0xFFF28C45),
                              icon: Icons.emoji_events_rounded),
                        if (day == 3)
                          const _MiniBadge(
                              color: Color(0xFF7CC6E8),
                              icon: Icons.water_drop_rounded),
                      ],
                    ),
                  ),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }
}

class _StateChip extends StatelessWidget {
  final Color color;
  final String text;

  const _StateChip({required this.color, required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        text,
        style: Theme.of(context).textTheme.labelLarge?.copyWith(
              fontWeight: FontWeight.w800,
              color: const Color(0xFF324251),
            ),
      ),
    );
  }
}

class _GroundScene extends StatelessWidget {
  final double size;
  final Color base;
  final Color accent;
  final IconData icon;
  final IconData badgeIcon;

  const _GroundScene({
    required this.size,
    required this.base,
    required this.accent,
    required this.icon,
    required this.badgeIcon,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        children: [
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF2A3F54), Color(0xFF152433)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomCenter,
                ),
                borderRadius: BorderRadius.circular(20),
              ),
            ),
          ),
          Positioned(
            left: 14,
            right: 14,
            bottom: 14,
            child: Container(
              height: 58,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: base.withValues(alpha: 0.72),
                  width: 1.4,
                ),
              ),
            ),
          ),
          Positioned(
            left: 43,
            right: 43,
            bottom: 14,
            child: Container(
              height: 58,
              decoration: BoxDecoration(
                border: Border(
                  left: BorderSide(
                    color: base.withValues(alpha: 0.72),
                    width: 1.2,
                  ),
                  right: BorderSide(
                    color: base.withValues(alpha: 0.72),
                    width: 1.2,
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            left: 46,
            bottom: 34,
            child: Icon(icon, size: 42, color: Colors.white),
          ),
          Positioned(
            left: 22,
            bottom: 26,
            child: Container(
              width: 12,
              height: 22,
              decoration: BoxDecoration(
                color: accent,
                borderRadius: BorderRadius.circular(3),
              ),
            ),
          ),
          Positioned(
            right: 18,
            top: 18,
            child: Container(
              width: 34,
              height: 34,
              decoration: const BoxDecoration(
                color: Color(0xFFE0B85B),
                borderRadius: BorderRadius.all(Radius.circular(10)),
              ),
              child: Icon(badgeIcon, color: const Color(0xFF152433), size: 20),
            ),
          ),
        ],
      ),
    );
  }
}

class _PlayerDot extends StatelessWidget {
  final Color color;

  const _PlayerDot({required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 24,
      height: 24,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 2),
      ),
    );
  }
}

class _BallDot extends StatelessWidget {
  const _BallDot();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 16,
      height: 16,
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        border: Border.all(color: const Color(0xFF24364B), width: 2),
      ),
    );
  }
}

class _MiniBadge extends StatelessWidget {
  final Color color;
  final IconData icon;

  const _MiniBadge({required this.color, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 22,
      height: 22,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
      child: Icon(icon, size: 14, color: Colors.white),
    );
  }
}

class _MiniPitchPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final linePaint = Paint()
      ..color = const Color(0x55E5D7C4)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.8;
    final midX = size.width / 2;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Offset.zero & size,
        const Radius.circular(22),
      ),
      linePaint,
    );
    canvas.drawLine(Offset(midX, 0), Offset(midX, size.height), linePaint);
    canvas.drawCircle(Offset(midX, size.height / 2), 22, linePaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
