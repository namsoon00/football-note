import 'package:flutter/material.dart';
import 'package:football_note/gen/app_localizations.dart';

class GameGuideScreen extends StatelessWidget {
  const GameGuideScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isKo = Localizations.localeOf(context).languageCode == 'ko';
    final workshopSections = _buildWorkshopSections(isKo);
    final synthesisLines = isKo
        ? const [
            '1순위: 한 판 안에서 상황이 바뀌는 드라마를 만들기 위해 전반 10초는 리듬 축적, 후반 10초는 찬스 폭발 구간으로 구분합니다.',
            '2순위: 안전 패스로 공간을 만들고 킬 패스로 전진한 뒤 마무리하는 3단계를 점수/연출/미션으로 동시에 보상합니다.',
            '3순위: 게임 종료 후에는 실패 이유, 잘한 선택, 다음 도전 미션을 짧게 보여 줘 속도와 공간 학습이 남도록 합니다.',
          ]
        : const [
            'Priority 1: Split each run into a rhythm-building first 10 seconds and a chance-explosion last 10 seconds so the round has a clear dramatic arc.',
            'Priority 2: Reward the three-step loop of creating space with safe passes, advancing with killer passes, and finishing the move through score, missions, and presentation together.',
            'Priority 3: After the run, show the failure reason, strongest choice, and next challenge so speed-and-space learning remains visible.',
          ];

    return Scaffold(
      appBar: AppBar(title: Text(l10n.gameGuideTitle)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _GuideSection(
            title: l10n.gameGuideQuickTitle,
            icon: Icons.flash_on_outlined,
            lines: [
              l10n.gameGuideQuickLine1,
              l10n.gameGuideQuickLine2,
              l10n.gameGuideQuickLine3,
              l10n.gameGuideQuickLine4,
            ],
          ),
          const SizedBox(height: 12),
          _GuideSection(
            title: l10n.gameGuideRiskTitle,
            icon: Icons.balance_outlined,
            lines: [
              l10n.gameGuideRiskLine1,
              l10n.gameGuideRiskLine2,
              l10n.gameGuideRiskLine3,
              l10n.gameGuideRiskLine4,
            ],
          ),
          const SizedBox(height: 12),
          _GuideSection(
            title: l10n.gameGuideFailureTitle,
            icon: Icons.rule_folder_outlined,
            lines: [
              l10n.gameGuideFailureLine1,
              l10n.gameGuideFailureLine2,
              l10n.gameGuideFailureLine3,
              l10n.gameGuideFailureLine4,
            ],
          ),
          const SizedBox(height: 12),
          _GuideSection(
            title: l10n.gameGuideRankingTitle,
            icon: Icons.emoji_events_outlined,
            lines: [
              l10n.gameGuideRankingLine1,
              l10n.gameGuideRankingLine2,
              l10n.gameGuideRankingLine3,
              l10n.gameGuideRankingLine4,
            ],
          ),
          const SizedBox(height: 12),
          _WorkshopHeroCard(
            title: isKo ? '게임 재미 워크숍' : 'Game Fun Workshop',
            subtitle: isKo
                ? '화면 구성, 게임 로직, 게임 흐름, 재미 요소, 속도와 공간 학습을 4개 역할로 다시 점검한 제안입니다.'
                : 'A four-role review of screen layout, game logic, flow, fun hooks, and speed-and-space learning.',
          ),
          const SizedBox(height: 12),
          for (final section in workshopSections) ...[
            _RoleWorkshopCard(section: section),
            const SizedBox(height: 12),
          ],
          _GuideSection(
            title: isKo ? '종합 제안' : 'Synthesized Proposal',
            icon: Icons.merge_type_outlined,
            lines: synthesisLines,
          ),
          const SizedBox(height: 12),
          _CharacterGuideCard(
            title: l10n.gameGuideCharPacTitle,
            subtitle: l10n.gameGuideCharPacSubtitle,
            color: const Color(0xFFFFC107),
            tag: l10n.gameGuideCharPacTag,
            painter: const _GuidePacmanPainter(color: Color(0xFFFFD54F)),
          ),
          const SizedBox(height: 10),
          _CharacterGuideCard(
            title: l10n.gameGuideCharBlueTitle,
            subtitle: l10n.gameGuideCharBlueSubtitle,
            color: const Color(0xFF42A5F5),
            tag: l10n.gameGuideCharBlueTag,
            painter: const _GuideGhostPainter(color: Color(0xFF42A5F5)),
          ),
          const SizedBox(height: 10),
          _CharacterGuideCard(
            title: l10n.gameGuideCharOrangeTitle,
            subtitle: l10n.gameGuideCharOrangeSubtitle,
            color: const Color(0xFFFFA726),
            tag: l10n.gameGuideCharOrangeTag,
            painter: const _GuideGhostPainter(color: Color(0xFFFFA726)),
          ),
          const SizedBox(height: 10),
          _CharacterGuideCard(
            title: l10n.gameGuideCharRedTitle,
            subtitle: l10n.gameGuideCharRedSubtitle,
            color: const Color(0xFFEF5350),
            tag: l10n.gameGuideCharRedTag,
            painter: const _GuideGhostPainter(color: Color(0xFFEF5350)),
          ),
          const SizedBox(height: 10),
          _CharacterGuideCard(
            title: l10n.gameGuideCharPinkTitle,
            subtitle: l10n.gameGuideCharPinkSubtitle,
            color: const Color(0xFFEC70C0),
            tag: l10n.gameGuideCharPinkTag,
            painter: const _GuideGhostPainter(color: Color(0xFFEC70C0)),
          ),
        ],
      ),
    );
  }
}

List<_WorkshopSectionData> _buildWorkshopSections(bool isKo) {
  if (isKo) {
    return const [
      _WorkshopSectionData(
        title: '역할 1. 게임 디렉터',
        subtitle: '한 판이 짧아도 장면 전환과 긴장 곡선이 보여야 합니다.',
        icon: Icons.movie_filter_outlined,
        lines: [
          '시작 3초는 수비 간격을 읽는 준비 구간, 중반은 템포 축적, 후반은 골 찬스 구간으로 나눠 화면 메시지를 바꿉니다.',
          '지금의 패스 선택 UI는 유지하되, “지금 열린 공간”, “위험한 수비”를 한 문장으로 보여 주면 판단의 재미가 선명해집니다.',
          '골 직전에는 카메라 줌, 라인 하이라이트, 짧은 효과음 템포 변화로 클라이맥스를 만들어야 합니다.',
        ],
      ),
      _WorkshopSectionData(
        title: '역할 2. 시스템 디자이너',
        subtitle: '리스크를 읽고 선택을 바꾸는 순간이 점수보다 더 재미있어야 합니다.',
        icon: Icons.tune_outlined,
        lines: [
          '안전/킬/위험 패스의 기대값 차이를 더 분명히 하고, 연속 같은 선택만 하면 효율이 떨어지는 흐름 감쇠를 넣습니다.',
          '수비 AI는 단순 속도 상승보다 “라인 닫기”, “리시버 추적”, “역압박” 패턴을 번갈아 보여 줘야 공간 창출 학습이 됩니다.',
          '공간을 만든 뒤 반대 전환이나 third-man pass가 나오면 추가 배수를 주면 축구적인 정답이 보상됩니다.',
        ],
      ),
      _WorkshopSectionData(
        title: '역할 3. 플레이 플로우 디자이너',
        subtitle: '도전 시작, 실패, 재도전까지 끊김 없이 이어져야 습관이 됩니다.',
        icon: Icons.route_outlined,
        lines: [
          '게임 전에는 “오늘의 추천 미션”을 한 줄만 보여 주고 바로 시작하게 해서 진입 장벽을 낮춥니다.',
          '실패 후에는 생명 차감만 보여 주지 말고 “왜 늦었는지/왜 막혔는지”를 즉시 라벨링해 다음 시도를 유도합니다.',
          '한 판 종료 후에는 랭킹보다 먼저 “다음 판에서 해볼 것 1개”를 제시하면 반복 플레이 이유가 분명해집니다.',
        ],
      ),
      _WorkshopSectionData(
        title: '역할 4. 축구 학습 코치',
        subtitle: '속도와 공간을 이해했다는 감각이 남아야 미니게임이 학습 도구가 됩니다.',
        icon: Icons.sports_soccer_outlined,
        lines: [
          '공간이 열린 방향을 색으로 구분하고, 좋은 선택 뒤에는 “압박 반대편 사용”, “간격 벌리기 성공” 같은 축구 언어를 붙입니다.',
          '레벨이 오를수록 더 빠른 손 조작보다 프리스캔, 첫 터치 방향, 수적 우위 활용 같은 판단 문제를 늘려야 합니다.',
          '훈련 노트나 퀴즈와 연결해 “오늘 게임에서 자주 막힌 상황”을 복습 주제로 보내면 학습 루프가 완성됩니다.',
        ],
      ),
    ];
  }

  return const [
    _WorkshopSectionData(
      title: 'Role 1. Game Director',
      subtitle:
          'Even a short round needs visible scene changes and a tension curve.',
      icon: Icons.movie_filter_outlined,
      lines: [
        'Split the round into a 3-second read phase, a mid-round rhythm phase, and a late chance phase with different on-screen prompts.',
        'Keep the current pass-choice UI, but surface one-line cues such as “open lane” or “danger pressure” so decisions feel sharper.',
        'Before a shot, use a short zoom, lane highlight, and audio tempo change to create a real climax.',
      ],
    ),
    _WorkshopSectionData(
      title: 'Role 2. Systems Designer',
      subtitle:
          'Reading risk and changing the choice should feel more fun than raw scoring.',
      icon: Icons.tune_outlined,
      lines: [
        'Differentiate the expected value of safe, killer, and risky passes more clearly, and add efficiency decay when the same choice repeats too often.',
        'Rotate defender behaviors such as lane closing, receiver tracking, and counter-pressing instead of only increasing speed.',
        'Add a multiplier for switch play or third-man combinations after creating space so football-correct decisions get rewarded.',
      ],
    ),
    _WorkshopSectionData(
      title: 'Role 3. Flow Designer',
      subtitle:
          'Starting, failing, and retrying must connect without friction to build habit.',
      icon: Icons.route_outlined,
      lines: [
        'Show only one recommended mission before the run and let players start immediately.',
        'After failure, label why it happened instead of only subtracting a life so the next attempt has a concrete adjustment.',
        'At round end, show one “next thing to try” before rankings so repeat motivation is clear.',
      ],
    ),
    _WorkshopSectionData(
      title: 'Role 4. Football Learning Coach',
      subtitle:
          'The mini game should leave the player with a sense of understanding speed and space.',
      icon: Icons.sports_soccer_outlined,
      lines: [
        'Color-code the open side and attach football language like “used weak-side space” or “stretched the line” after good decisions.',
        'As levels rise, emphasize scanning, first-touch direction, and overload reading instead of only faster finger inputs.',
        'Link blocked situations back into notes or quiz review so the game feeds the learning loop.',
      ],
    ),
  ];
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
              Text(line, style: Theme.of(context).textTheme.bodyMedium),
              const SizedBox(height: 6),
            ],
          ],
        ),
      ),
    );
  }
}

class _WorkshopHeroCard extends StatelessWidget {
  final String title;
  final String subtitle;

  const _WorkshopHeroCard({required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            colorScheme.primary.withValues(alpha: 0.18),
            colorScheme.secondary.withValues(alpha: 0.10),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: colorScheme.primary.withValues(alpha: 0.18)),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: colorScheme.primary.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(Icons.forum_outlined, color: colorScheme.primary),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 4),
                Text(subtitle),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _RoleWorkshopCard extends StatelessWidget {
  final _WorkshopSectionData section;

  const _RoleWorkshopCard({required this.section});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: colorScheme.primary.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    section.icon,
                    size: 18,
                    color: colorScheme.primary,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    section.title,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              section.subtitle,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(
                  context,
                ).colorScheme.onSurface.withValues(alpha: 0.75),
              ),
            ),
            const SizedBox(height: 10),
            for (final line in section.lines) ...[
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Padding(
                    padding: EdgeInsets.only(top: 6),
                    child: Icon(Icons.circle, size: 6),
                  ),
                  const SizedBox(width: 8),
                  Expanded(child: Text(line)),
                ],
              ),
              const SizedBox(height: 8),
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
                  Text(subtitle, style: Theme.of(context).textTheme.bodySmall),
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
        height: h * 0.21,
      ),
      eyeWhite,
    );
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(w * 0.60, h * 0.50),
        width: w * 0.15,
        height: h * 0.21,
      ),
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

class _WorkshopSectionData {
  final String title;
  final String subtitle;
  final IconData icon;
  final List<String> lines;

  const _WorkshopSectionData({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.lines,
  });
}
