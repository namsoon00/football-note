import 'package:flutter/material.dart';

class WelcomeScreen extends StatefulWidget {
  final VoidCallback onStart;

  const WelcomeScreen({super.key, required this.onStart});

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    final isKo = Localizations.localeOf(context).languageCode == 'ko';
    final sections = _buildSections(isKo);
    final selected = sections[_selectedIndex];

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                isKo ? '환영합니다! 앱 화면 안내' : 'Welcome! App Walkthrough',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                isKo
                    ? '아래 탭 버튼을 누르면 설명 화면이 전환됩니다. 각 탭이 무엇을 하는지 먼저 확인해보세요.'
                    : 'Tap a tab button below to switch the guide panel and preview each screen.',
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(height: 1.45),
              ),
              const SizedBox(height: 14),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: List.generate(sections.length, (i) {
                    final section = sections[i];
                    return Padding(
                      padding: EdgeInsets.only(
                        right: i == sections.length - 1 ? 0 : 8,
                      ),
                      child: ChoiceChip(
                        selected: i == _selectedIndex,
                        avatar: Icon(section.icon, size: 16),
                        label: Text(section.title),
                        onSelected: (_) => setState(() => _selectedIndex = i),
                      ),
                    );
                  }),
                ),
              ),
              const SizedBox(height: 12),
              Expanded(
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 240),
                  switchInCurve: Curves.easeOutCubic,
                  switchOutCurve: Curves.easeInCubic,
                  child: _WelcomeSectionCard(
                    key: ValueKey(selected.id),
                    section: selected,
                    isKo: isKo,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: widget.onStart,
                  icon: const Icon(Icons.arrow_forward_rounded),
                  style: FilledButton.styleFrom(
                    minimumSize: const Size.fromHeight(52),
                  ),
                  label: Text(isKo ? '앱 시작하기' : 'Start App'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _WelcomeSectionCard extends StatelessWidget {
  final _WelcomeSection section;
  final bool isKo;

  const _WelcomeSectionCard({
    super.key,
    required this.section,
    required this.isKo,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest.withValues(alpha: 0.82),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: scheme.outline.withValues(alpha: 0.35)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(section.icon, color: scheme.primary),
              const SizedBox(width: 8),
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
          const SizedBox(height: 10),
          Text(
            section.overview,
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(height: 1.45),
          ),
          const SizedBox(height: 12),
          Text(
            isKo ? '화면에서 할 수 있는 것' : 'What you can do on this screen',
            style: Theme.of(
              context,
            ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 6),
          ...section.details.map(
            (line) => Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Padding(
                    padding: EdgeInsets.only(top: 3),
                    child: Icon(Icons.check_circle, size: 14),
                  ),
                  const SizedBox(width: 6),
                  Expanded(child: Text(line)),
                ],
              ),
            ),
          ),
          const Spacer(),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              color: scheme.primary.withValues(alpha: 0.10),
            ),
            child: Text(
              isKo
                  ? '탭 버튼을 누르면 안내 카드가 즉시 바뀝니다.'
                  : 'Tap another tab button to switch this guide card instantly.',
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }
}

class _WelcomeSection {
  final String id;
  final IconData icon;
  final String title;
  final String overview;
  final List<String> details;

  const _WelcomeSection({
    required this.id,
    required this.icon,
    required this.title,
    required this.overview,
    required this.details,
  });
}

List<_WelcomeSection> _buildSections(bool isKo) {
  if (isKo) {
    return const <_WelcomeSection>[
      _WelcomeSection(
        id: 'logs',
        icon: Icons.list_alt_outlined,
        title: '훈련기록',
        overview: '훈련 노트를 빠르게 기록하고, 카드/리스트 뷰로 과거 기록을 확인하는 화면입니다.',
        details: [
          '훈련 강도, 컨디션, 메모, 훈련 스케치 정보까지 한 번에 입력/수정할 수 있습니다.',
          '카드형/리스트형 전환으로 원하는 방식으로 기록을 탐색할 수 있습니다.',
          '정렬은 최신 작성/등록 우선으로 관리되어 최근 기록을 먼저 확인할 수 있습니다.',
        ],
      ),
      _WelcomeSection(
        id: 'calendar',
        icon: Icons.calendar_month_outlined,
        title: '캘린더',
        overview: '날짜 중심으로 훈련 기록과 계획을 한눈에 확인하고 일정 흐름을 관리하는 화면입니다.',
        details: [
          '날짜를 선택하면 해당일의 훈련 기록과 계획이 함께 표시됩니다.',
          '오늘 이동, 계획 추가, 알림 연동을 통해 실전 루틴을 만들 수 있습니다.',
          '월 단위 흐름을 보면서 훈련 공백/집중 구간을 쉽게 파악할 수 있습니다.',
        ],
      ),
      _WelcomeSection(
        id: 'stats',
        icon: Icons.bar_chart_outlined,
        title: '성장 통계',
        overview: '선택한 기간의 성장 추이를 그래프와 지표로 확인해 훈련 방향을 조정하는 화면입니다.',
        details: [
          '성장 그래프, 평균 비교, 리프팅/줄넘기 통계 등 핵심 지표를 볼 수 있습니다.',
          '기간 변경으로 최근 1주일/사용자 지정 기간을 비교할 수 있습니다.',
          '오른 지표와 약한 지표를 분리해 다음 훈련 목표 설정에 활용할 수 있습니다.',
        ],
      ),
      _WelcomeSection(
        id: 'news',
        icon: Icons.newspaper_outlined,
        title: '오늘의 소식',
        overview: '선택한 채널의 축구 뉴스를 모아보고, 필요한 정보만 빠르게 확인하는 화면입니다.',
        details: [
          '채널 선택으로 관심 있는 소식만 필터링해서 볼 수 있습니다.',
          '한국어 환경에서는 제목 번역 토글로 읽기 편의성을 높일 수 있습니다.',
          '당겨서 새로고침으로 최신 뉴스를 즉시 반영할 수 있습니다.',
        ],
      ),
      _WelcomeSection(
        id: 'game',
        icon: Icons.sports_esports_outlined,
        title: '게임/퀴즈',
        overview: '패스 게임과 실전 퀴즈를 통해 훈련 판단력을 재미있게 반복 학습하는 화면입니다.',
        details: [
          '게임 가이드/랭킹/퀴즈 버튼으로 학습과 플레이를 빠르게 전환할 수 있습니다.',
          '퀴즈는 유형별 문제풀과 오답 다시풀기로 학습 강화를 지원합니다.',
          '게임 결과는 골/선방/실패를 확인한 뒤 다음 단계로 넘어가도록 구성되어 있습니다.',
        ],
      ),
    ];
  }

  return const <_WelcomeSection>[
    _WelcomeSection(
      id: 'logs',
      icon: Icons.list_alt_outlined,
      title: 'Logs',
      overview:
          'Create and review training notes with card/list views and recent-first browsing.',
      details: [
        'Record intensity, condition, memo, and training-board details in one flow.',
        'Switch between card and list layouts based on your preference.',
        'Recent entries stay at the top so you can review the latest work first.',
      ],
    ),
    _WelcomeSection(
      id: 'calendar',
      icon: Icons.calendar_month_outlined,
      title: 'Calendar',
      overview:
          'Manage your schedule by date with training logs and plans shown together.',
      details: [
        'Tap a date to review that day’s logs and plans at once.',
        'Use today-jump and plan add actions to maintain your routine.',
        'Track monthly flow to spot gaps and high-focus periods quickly.',
      ],
    ),
    _WelcomeSection(
      id: 'stats',
      icon: Icons.bar_chart_outlined,
      title: 'Growth Stats',
      overview:
          'Analyze growth trends with charts and key metrics over your selected period.',
      details: [
        'Review growth chart, averages, lifting and jump-rope statistics.',
        'Compare last 7 days vs custom ranges to evaluate progress.',
        'Use strong/weak signals to set your next training focus.',
      ],
    ),
    _WelcomeSection(
      id: 'news',
      icon: Icons.newspaper_outlined,
      title: 'News',
      overview:
          'Read football headlines from selected channels and focus on relevant updates.',
      details: [
        'Pick channels so only useful sources appear in your feed.',
        'Use title translation toggle in Korean locale for readability.',
        'Pull to refresh to fetch the latest updates instantly.',
      ],
    ),
    _WelcomeSection(
      id: 'game',
      icon: Icons.sports_esports_outlined,
      title: 'Game / Quiz',
      overview:
          'Train decision making with pass game and categorized skill quizzes.',
      details: [
        'Use Guide/Quiz/Ranking actions to move between learning and play quickly.',
        'Quiz supports per-type pools and wrong-answer retry for reinforcement.',
        'Shot results are shown clearly before the match flow continues.',
      ],
    ),
  ];
}
