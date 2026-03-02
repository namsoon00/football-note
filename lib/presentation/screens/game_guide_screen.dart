import 'package:flutter/material.dart';

class GameGuideScreen extends StatelessWidget {
  const GameGuideScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isKo = Localizations.localeOf(context).languageCode == 'ko';

    return Scaffold(
      appBar: AppBar(
        title: Text(isKo ? '게임 가이드' : 'Game Guide'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _GuideSection(
            title: isKo ? '게임 방법' : 'How To Play',
            icon: Icons.sports_esports_outlined,
            lines: isKo
                ? const [
                    '1) 60초 동안 패스를 성공시켜 점수와 레벨을 올립니다.',
                    '2) 패스는 길게 눌렀다가 놓으면 발사됩니다.',
                    '3) 수비수에게 공이 닿으면 즉시 종료됩니다.',
                    '4) 60초 종료 후 최종 슈팅 라운드가 시작됩니다.',
                    '5) 슈팅 성공 시 보너스 점수와 함께 최종 랭킹이 표시됩니다.',
                  ]
                : const [
                    '1) Build score and level with successful passes for 60 seconds.',
                    '2) Hold and release to pass.',
                    '3) Match ends immediately if the ball is intercepted.',
                    '4) Final shot round starts after 60 seconds.',
                    '5) A successful shot gives bonus score and final rank.',
                  ],
          ),
          const SizedBox(height: 12),
          _GuideSection(
            title: isKo ? '레벨 설명' : 'Level System',
            icon: Icons.stacked_line_chart_outlined,
            lines: isKo
                ? const [
                    '초급: 수비수 3~6명, 블루/오렌지 고스트만 등장합니다.',
                    '중급: 수비수 5~9명, 블루/오렌지/레드 고스트가 등장합니다.',
                    '고급: 수비수 7~12명, 4종 고스트가 모두 등장합니다.',
                    '패스 성공으로 레벨이 오르면 수비수 수와 압박 강도가 증가합니다.',
                  ]
                : const [
                    'Easy: 3-6 defenders, Blue/Orange ghosts only.',
                    'Medium: 5-9 defenders, Blue/Orange/Red ghosts.',
                    'Hard: 7-12 defenders, all 4 ghost types.',
                    'As level rises from successful passes, pressure and defender count increase.',
                  ],
          ),
          const SizedBox(height: 12),
          _GuideSection(
            title: isKo ? '랭킹 설명' : 'Ranking System',
            icon: Icons.emoji_events_outlined,
            lines: isKo
                ? const [
                    '랭킹 점수 = (패스 점수×10) + (레벨×15) + (골×60)',
                    'S: 320점 이상',
                    'A: 240점 이상',
                    'B: 170점 이상',
                    'C: 110점 이상',
                    'D: 110점 미만',
                    '골 보너스 비중이 커서, 60초 후 슈팅 성공이 최종 랭킹에 큰 영향을 줍니다.',
                  ]
                : const [
                    'Rank score = (pass score x 10) + (level x 15) + (goals x 60)',
                    'S: 320+',
                    'A: 240+',
                    'B: 170+',
                    'C: 110+',
                    'D: below 110',
                    'Goal bonus has high weight, so final-shot success strongly affects final rank.',
                  ],
          ),
          const SizedBox(height: 12),
          _GuideSection(
            title: isKo ? '캐릭터 소개' : 'Character Intro',
            icon: Icons.groups_2_outlined,
            lines: isKo
                ? const [
                    '팩맨(노랑): 우리팀 공격수. 패스를 주고받으며 전진합니다.',
                    '블루 고스트(BLOCK): 패스 라인을 차단하는 수비수.',
                    '오렌지 고스트(PRESS): 공 주변을 빠르게 압박하는 수비수.',
                    '레드 고스트(MARK): 패서를 따라붙는 마킹 수비수.',
                    '핑크 고스트(READ): 리시버 이동을 예측해 커팅하는 수비수.',
                  ]
                : const [
                    'Pacman (Yellow): your attackers advancing by passing.',
                    'Blue Ghost (BLOCK): blocks passing lanes.',
                    'Orange Ghost (PRESS): fast pressure around the ball.',
                    'Red Ghost (MARK): tracks and marks the passer.',
                    'Pink Ghost (READ): anticipates receiver movement and cuts.',
                  ],
          ),
          const SizedBox(height: 12),
          _CharacterGuideCard(
            title: isKo ? '팩맨 공격수' : 'Pacman Attacker',
            subtitle: isKo ? '패스 시작/연결 담당' : 'Starts and links passes',
            color: const Color(0xFFFFC107),
            tag: isKo ? '공격' : 'ATTACK',
            painter: const _GuidePacmanPainter(color: Color(0xFFFFD54F)),
          ),
          const SizedBox(height: 10),
          _CharacterGuideCard(
            title: isKo ? '블루 고스트 - BLOCK' : 'Blue Ghost - BLOCK',
            subtitle: isKo ? '패스 라인 차단' : 'Blocks passing lanes',
            color: const Color(0xFF42A5F5),
            tag: isKo ? '차단' : 'BLOCK',
            painter: const _GuideGhostPainter(color: Color(0xFF42A5F5)),
          ),
          const SizedBox(height: 10),
          _CharacterGuideCard(
            title: isKo ? '오렌지 고스트 - PRESS' : 'Orange Ghost - PRESS',
            subtitle: isKo ? '공 근처 압박' : 'Pressure near ball',
            color: const Color(0xFFFFA726),
            tag: isKo ? '압박' : 'PRESS',
            painter: const _GuideGhostPainter(color: Color(0xFFFFA726)),
          ),
          const SizedBox(height: 10),
          _CharacterGuideCard(
            title: isKo ? '레드 고스트 - MARK' : 'Red Ghost - MARK',
            subtitle: isKo ? '패서 마킹' : 'Marks the passer',
            color: const Color(0xFFEF5350),
            tag: isKo ? '마크' : 'MARK',
            painter: const _GuideGhostPainter(color: Color(0xFFEF5350)),
          ),
          const SizedBox(height: 10),
          _CharacterGuideCard(
            title: isKo ? '핑크 고스트 - READ' : 'Pink Ghost - READ',
            subtitle: isKo ? '리시버 예측 차단' : 'Anticipates receiver route',
            color: const Color(0xFFEC70C0),
            tag: isKo ? '예측' : 'READ',
            painter: const _GuideGhostPainter(color: Color(0xFFEC70C0)),
          ),
        ],
      ),
    );
  }
}

class _GuideSection extends StatelessWidget {
  final String title;
  final IconData icon;
  final List<String> lines;

  const _GuideSection({
    required this.title,
    required this.icon,
    required this.lines,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 18),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            for (final line in lines) ...[
              Text(
                line,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 6),
            ],
          ],
        ),
      ),
    );
  }
}

class _CharacterGuideCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final String tag;
  final Color color;
  final CustomPainter painter;

  const _CharacterGuideCard({
    required this.title,
    required this.subtitle,
    required this.tag,
    required this.color,
    required this.painter,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Container(
              width: 58,
              height: 58,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: color.withValues(alpha: 0.45)),
              ),
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: CustomPaint(painter: painter),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    subtitle,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.16),
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                tag,
                style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.w900,
                  fontSize: 11,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _GuidePacmanPainter extends CustomPainter {
  final Color color;

  const _GuidePacmanPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final radius = size.shortestSide * 0.48;
    final center = Offset(size.width / 2, size.height / 2);
    const mouth = 0.85;
    final fill = Paint()..color = color;
    final border = Paint()
      ..color = const Color(0xEEFFFFFF)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.3;

    final path = Path()
      ..moveTo(center.dx, center.dy)
      ..arcTo(
        Rect.fromCircle(center: center, radius: radius),
        mouth / 2,
        (3.14159265359 * 2) - mouth,
        false,
      )
      ..close();
    canvas.drawPath(path, fill);
    canvas.drawPath(path, border);

    final eye = Paint()..color = const Color(0xFF1F2937);
    canvas.drawCircle(
      Offset(center.dx + (radius * 0.15), center.dy - (radius * 0.34)),
      radius * 0.10,
      eye,
    );
  }

  @override
  bool shouldRepaint(covariant _GuidePacmanPainter oldDelegate) {
    return oldDelegate.color != color;
  }
}

class _GuideGhostPainter extends CustomPainter {
  final Color color;

  const _GuideGhostPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final path = Path()
      ..moveTo(w * 0.20, h * 0.92)
      ..quadraticBezierTo(w * 0.25, h * 0.80, w * 0.30, h * 0.92)
      ..quadraticBezierTo(w * 0.38, h * 0.80, w * 0.46, h * 0.92)
      ..quadraticBezierTo(w * 0.54, h * 0.80, w * 0.62, h * 0.92)
      ..quadraticBezierTo(w * 0.70, h * 0.80, w * 0.78, h * 0.92)
      ..lineTo(w * 0.80, h * 0.38)
      ..arcToPoint(
        Offset(w * 0.20, h * 0.38),
        radius: Radius.elliptical(w * 0.30, h * 0.30),
        clockwise: false,
      )
      ..close();

    final fill = Paint()..color = color;
    final border = Paint()
      ..color = const Color(0xEEFFFFFF)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;
    canvas.drawPath(path, fill);
    canvas.drawPath(path, border);

    final eyeWhite = Paint()..color = Colors.white.withValues(alpha: 0.93);
    final pupil = Paint()..color = const Color(0xFF111827);
    canvas.drawOval(
      Rect.fromCenter(
          center: Offset(w * 0.40, h * 0.50),
          width: w * 0.15,
          height: h * 0.21),
      eyeWhite,
    );
    canvas.drawOval(
      Rect.fromCenter(
          center: Offset(w * 0.60, h * 0.50),
          width: w * 0.15,
          height: h * 0.21),
      eyeWhite,
    );
    canvas.drawCircle(Offset(w * 0.43, h * 0.52), w * 0.035, pupil);
    canvas.drawCircle(Offset(w * 0.63, h * 0.52), w * 0.035, pupil);
  }

  @override
  bool shouldRepaint(covariant _GuideGhostPainter oldDelegate) {
    return oldDelegate.color != color;
  }
}
