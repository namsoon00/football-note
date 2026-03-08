import 'package:flutter/material.dart';

class WelcomeScreen extends StatelessWidget {
  final VoidCallback onStart;

  const WelcomeScreen({super.key, required this.onStart});

  @override
  Widget build(BuildContext context) {
    final isKo = Localizations.localeOf(context).languageCode == 'ko';
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                isKo
                    ? 'Football Note에 오신 것을 환영합니다'
                    : 'Welcome to Football Note',
                style: textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                isKo
                    ? '훈련 기록부터 성장 통계, 스킬 퀴즈와 게임까지 한 앱에서 관리합니다.'
                    : 'Track training, growth stats, skill quiz, and game in one app.',
                style: textTheme.bodyMedium?.copyWith(height: 1.45),
              ),
              const SizedBox(height: 18),
              _FeatureTile(
                icon: Icons.list_alt_outlined,
                title: isKo ? '훈련기록' : 'Logs',
                description: isKo
                    ? '훈련 노트를 카드/리스트로 빠르게 기록하고 수정합니다.'
                    : 'Create and edit training notes quickly in card/list views.',
              ),
              _FeatureTile(
                icon: Icons.calendar_month_outlined,
                title: isKo ? '캘린더' : 'Calendar',
                description: isKo
                    ? '날짜별 기록과 훈련 계획을 확인하고 관리합니다.'
                    : 'Review daily logs and manage training plans by date.',
              ),
              _FeatureTile(
                icon: Icons.bar_chart_outlined,
                title: isKo ? '성장 통계' : 'Growth Stats',
                description: isKo
                    ? '기간별 성장 그래프와 세부 지표를 확인합니다.'
                    : 'Check growth charts and detailed metrics by period.',
              ),
              _FeatureTile(
                icon: Icons.newspaper_outlined,
                title: isKo ? '오늘의 소식' : 'News',
                description: isKo
                    ? '축구 뉴스를 모아보고 필요한 채널만 선택합니다.'
                    : 'Read football news and choose only the channels you want.',
              ),
              _FeatureTile(
                icon: Icons.sports_esports_outlined,
                title: isKo ? '게임/퀴즈' : 'Game/Quiz',
                description: isKo
                    ? '스킬 퀴즈와 패스 게임으로 재미있게 훈련합니다.'
                    : 'Train with a skill quiz and pass game interactively.',
              ),
              const Spacer(),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: onStart,
                  style: FilledButton.styleFrom(
                    minimumSize: const Size.fromHeight(52),
                    backgroundColor: scheme.primary,
                  ),
                  child: Text(isKo ? '시작하기' : 'Get Started'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FeatureTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;

  const _FeatureTile({
    required this.icon,
    required this.title,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: scheme.surfaceContainerHighest.withValues(alpha: 0.82),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: scheme.outline.withValues(alpha: 0.35)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 20, color: scheme.primary),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                  const SizedBox(height: 2),
                  Text(description,
                      style: Theme.of(context).textTheme.bodySmall),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
