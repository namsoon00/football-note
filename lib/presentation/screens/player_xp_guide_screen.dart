import 'package:flutter/material.dart';

import '../../application/player_level_service.dart';
import '../../domain/repositories/option_repository.dart';
import '../widgets/app_background.dart';

class PlayerXpGuideScreen extends StatelessWidget {
  final OptionRepository optionRepository;

  const PlayerXpGuideScreen({super.key, required this.optionRepository});

  @override
  Widget build(BuildContext context) {
    final isKo = Localizations.localeOf(context).languageCode == 'ko';
    final levelState = PlayerLevelService(optionRepository).loadState();
    final sections = <_XpGuideSection>[
      _XpGuideSection(
        title: isKo ? '기록으로 오르는 경험치' : 'XP from logging',
        subtitle: isKo
            ? '훈련을 남길수록 기본 성장치가 안정적으로 쌓입니다.'
            : 'Core growth comes from saving consistent training logs.',
        items: [
          _XpGuideItem(
            icon: Icons.edit_note_outlined,
            title: isKo ? '훈련 기록 저장' : 'Training log saved',
            xpLabel: '+20 XP',
          ),
          _XpGuideItem(
            icon: Icons.wb_sunny_outlined,
            title: isKo ? '하루 첫 훈련 기록' : 'First log of the day',
            xpLabel: '+10 XP',
          ),
          _XpGuideItem(
            icon: Icons.event_available_outlined,
            title: isKo ? '계획한 날 훈련 완료' : 'Complete a planned day',
            xpLabel: '+25 XP',
          ),
          _XpGuideItem(
            icon: Icons.sports_soccer_outlined,
            title: isKo ? '리프팅 기록 추가' : 'Lifting recorded',
            xpLabel: '+10 XP',
          ),
          _XpGuideItem(
            icon: Icons.fitness_center_outlined,
            title: isKo ? '줄넘기 기록 추가' : 'Jump rope recorded',
            xpLabel: '+10 XP',
          ),
          _XpGuideItem(
            icon: Icons.remove_circle_outline,
            title: isKo
                ? '리프팅/줄넘기 없이 저장하면 감점'
                : 'Missing lifting or jump rope costs XP',
            xpLabel: isKo ? '-10 XP씩' : '-10 XP each',
          ),
          _XpGuideItem(
            icon: Icons.rice_bowl_outlined,
            title: isKo ? '식사 기록 저장' : 'Meal log saved',
            xpLabel: isKo ? '+5 XP / +15 XP' : '+5 XP / +15 XP',
          ),
        ],
      ),
      _XpGuideSection(
        title: isKo ? '가벼운 루틴 보너스' : 'Light routine bonuses',
        subtitle: isKo
            ? '짧은 행동도 꾸준히 쌓이면 레벨 차이가 납니다.'
            : 'Small routine actions still move the level over time.',
        items: [
          _XpGuideItem(
            icon: Icons.quiz_outlined,
            title: isKo ? '퀴즈 완료' : 'Quiz completion',
            xpLabel: '+15 XP',
          ),
          _XpGuideItem(
            icon: Icons.auto_stories_outlined,
            title: isKo ? '오늘 다이어리 작성' : 'Today diary created',
            xpLabel: '+5 XP',
          ),
          _XpGuideItem(
            icon: Icons.event_note_outlined,
            title: isKo ? '훈련 계획 생성' : 'Training plan created',
            xpLabel: '+10 XP',
          ),
          _XpGuideItem(
            icon: Icons.repeat_outlined,
            title: isKo ? '묶음 계획 생성 보너스' : 'Plan series bonus',
            xpLabel:
                isKo ? '+5 XP씩 추가 (최대 +20 XP)' : '+5 XP each (up to +20 XP)',
          ),
        ],
      ),
      _XpGuideSection(
        title: isKo ? '훈련판 활용 보너스' : 'Training board bonuses',
        subtitle: isKo
            ? '다음 세션을 설계할수록 추가 경험치를 받을 수 있어요.'
            : 'Designing the next session also earns extra XP.',
        items: [
          _XpGuideItem(
            icon: Icons.developer_board_outlined,
            title: isKo ? '새 훈련 스케치 생성' : 'Training sketch created',
            xpLabel: '+12 XP',
          ),
          _XpGuideItem(
            icon: Icons.save_outlined,
            title: isKo ? '훈련 스케치 저장' : 'Training sketch saved',
            xpLabel: '+8 XP',
          ),
        ],
      ),
      _XpGuideSection(
        title: isKo ? '연속성과 주간 보너스' : 'Streak and weekly bonuses',
        subtitle: isKo
            ? '반복이 붙기 시작하면 큰 보너스가 들어옵니다.'
            : 'Larger bonuses unlock once repetition becomes consistent.',
        items: [
          _XpGuideItem(
            icon: Icons.local_fire_department_outlined,
            title: isKo ? '3일 연속 기록 / 7일 연속 기록' : '3-day / 7-day streak',
            xpLabel: isKo ? '+25 XP / +60 XP' : '+25 XP / +60 XP',
          ),
          _XpGuideItem(
            icon: Icons.bar_chart_outlined,
            title: isKo ? '주간 3회 기록 / 5회 기록' : '3 logs / 5 logs in a week',
            xpLabel: isKo ? '+40 XP / +70 XP' : '+40 XP / +70 XP',
          ),
        ],
      ),
    ];

    return Scaffold(
      appBar: AppBar(title: Text(isKo ? '경험치 오르는 방법' : 'How XP goes up')),
      body: AppBackground(
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
            children: [
              _XpGuideHeroCard(isKo: isKo, levelState: levelState),
              const SizedBox(height: 12),
              for (final section in sections) ...[
                _XpGuideSectionCard(section: section),
                const SizedBox(height: 12),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _XpGuideHeroCard extends StatelessWidget {
  final bool isKo;
  final PlayerLevelState levelState;

  const _XpGuideHeroCard({required this.isKo, required this.levelState});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            theme.colorScheme.primaryContainer,
            theme.colorScheme.secondaryContainer,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            isKo
                ? '지금은 Lv.${levelState.level}'
                : 'You are Lv.${levelState.level}',
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            isKo
                ? '어떤 행동이 경험치를 주는지 한 화면에서 이해할 수 있게 정리했습니다. 다음 레벨까지 ${levelState.xpToNextLevel} XP 남았어요.'
                : 'This page groups every XP source clearly. ${levelState.xpToNextLevel} XP remains until the next level.',
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _XpGuideSectionCard extends StatelessWidget {
  final _XpGuideSection section;

  const _XpGuideSectionCard({required this.section});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(22),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            section.title,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 4),
          Text(section.subtitle, style: theme.textTheme.bodySmall),
          const SizedBox(height: 12),
          for (final item in section.items) ...[
            _XpGuideRow(item: item),
            if (item != section.items.last) const SizedBox(height: 10),
          ],
        ],
      ),
    );
  }
}

class _XpGuideRow extends StatelessWidget {
  final _XpGuideItem item;

  const _XpGuideRow({required this.item});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: theme.colorScheme.primary.withValues(alpha: 0.10),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(item.icon, color: theme.colorScheme.primary, size: 20),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            item.title,
            style: theme.textTheme.bodyLarge?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        const SizedBox(width: 10),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: theme.colorScheme.primary.withValues(alpha: 0.10),
            borderRadius: BorderRadius.circular(999),
          ),
          child: Text(
            item.xpLabel,
            style: theme.textTheme.labelLarge?.copyWith(
              color: theme.colorScheme.primary,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
      ],
    );
  }
}

class _XpGuideSection {
  final String title;
  final String subtitle;
  final List<_XpGuideItem> items;

  const _XpGuideSection({
    required this.title,
    required this.subtitle,
    required this.items,
  });
}

class _XpGuideItem {
  final IconData icon;
  final String title;
  final String xpLabel;

  const _XpGuideItem({
    required this.icon,
    required this.title,
    required this.xpLabel,
  });
}
