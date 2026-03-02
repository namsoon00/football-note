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
