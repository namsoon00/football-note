import 'package:flutter/material.dart';

import '../../application/player_level_service.dart';
import '../../domain/repositories/option_repository.dart';
import '../widgets/app_background.dart';
import '../widgets/app_feedback.dart';
import '../widgets/player_level_visuals.dart';
import 'player_xp_history_screen.dart';

class PlayerLevelGuideScreen extends StatefulWidget {
  final int currentLevel;
  final OptionRepository optionRepository;

  const PlayerLevelGuideScreen({
    super.key,
    required this.currentLevel,
    required this.optionRepository,
  });

  @override
  State<PlayerLevelGuideScreen> createState() => _PlayerLevelGuideScreenState();
}

class _PlayerLevelGuideScreenState extends State<PlayerLevelGuideScreen> {
  late final PlayerLevelService _levelService;
  bool _showXpGuide = false;

  @override
  void initState() {
    super.initState();
    _levelService = PlayerLevelService(widget.optionRepository);
  }

  @override
  Widget build(BuildContext context) {
    final isKo = Localizations.localeOf(context).languageCode == 'ko';
    final thresholds = PlayerLevelService.levelThresholds;
    final currentState = _levelService.loadState();
    final rewardByLevel = {
      for (final item in _levelService.loadRewardStatuses())
        item.reward.level: item,
    };

    return Scaffold(
      appBar: AppBar(
        title: Text(isKo ? '레벨 가이드' : 'Level guide'),
        actions: [
          IconButton(
            tooltip: _showXpGuide
                ? (isKo ? '경험치 방법 숨기기' : 'Hide XP guide')
                : (isKo ? '경험치 오르는 방법' : 'How XP goes up'),
            onPressed: () => setState(() => _showXpGuide = !_showXpGuide),
            icon: Icon(
              _showXpGuide
                  ? Icons.visibility_off_outlined
                  : Icons.trending_up_outlined,
            ),
          ),
          IconButton(
            tooltip: isKo ? '경험치 히스토리' : 'XP history',
            onPressed: () => _openXpHistory(context, isKo),
            icon: const Icon(Icons.timeline_outlined),
          ),
        ],
      ),
      body: AppBackground(
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
            children: [
              _LevelGuideSummaryCard(
                isKo: isKo,
                currentLevel: currentState.level,
                totalXp: currentState.totalXp,
                xpToNextLevel: currentState.xpToNextLevel,
                showXpGuide: _showXpGuide,
              ),
              if (_showXpGuide) ...[
                const SizedBox(height: 12),
                _XpGuideCard(isKo: isKo),
              ],
              for (
                var levelIndex = 0;
                levelIndex < thresholds.length;
                levelIndex++
              ) ...[
                const SizedBox(height: 12),
                _LevelGuideCard(
                  level: levelIndex + 1,
                  minXp: thresholds[levelIndex],
                  maxXp: levelIndex + 1 < thresholds.length
                      ? thresholds[levelIndex + 1] - 1
                      : null,
                  isCurrent: levelIndex + 1 == widget.currentLevel,
                  rewardStatus: rewardByLevel[levelIndex + 1],
                  isKo: isKo,
                  spec: PlayerLevelVisualSpec.fromLevel(levelIndex + 1),
                  onClaimReward: () => _claimReward(levelIndex + 1, isKo),
                  onEditRewardName: rewardByLevel[levelIndex + 1] == null
                      ? null
                      : () => _editRewardName(
                          context,
                          rewardByLevel[levelIndex + 1]!,
                          isKo,
                        ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _claimReward(int level, bool isKo) async {
    final claim = await _levelService.claimRewardForLevel(level);
    if (!mounted || claim == null) return;
    setState(() {});
    final rewardName = claim.customRewardName.trim().isNotEmpty
        ? claim.customRewardName
        : (isKo ? '선물' : 'Reward');
    AppFeedback.showSuccess(
      context,
      text: isKo ? '$rewardName 선물을 받았어요.' : 'Claimed $rewardName.',
    );
  }

  Future<void> _editRewardName(
    BuildContext context,
    PlayerLevelRewardStatus status,
    bool isKo,
  ) async {
    final saved = await showDialog<String>(
      context: context,
      builder: (dialogContext) =>
          _RewardNameDialog(initialValue: status.customRewardName, isKo: isKo),
    );
    if (saved == null) return;
    await _levelService.setCustomRewardName(status.reward.level, saved);
    if (!context.mounted) return;
    setState(() {});
    AppFeedback.showSuccess(
      context,
      text: saved.trim().isEmpty
          ? (isKo ? '레벨 선물을 지웠어요.' : 'Reward cleared.')
          : (isKo ? '레벨 선물을 저장했어요.' : 'Reward saved.'),
    );
  }

  Future<void> _openXpHistory(BuildContext context, bool isKo) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) =>
            PlayerXpHistoryScreen(optionRepository: widget.optionRepository),
      ),
    );
  }
}

class _LevelGuideSummaryCard extends StatelessWidget {
  final bool isKo;
  final int currentLevel;
  final int totalXp;
  final int xpToNextLevel;
  final bool showXpGuide;

  const _LevelGuideSummaryCard({
    required this.isKo,
    required this.currentLevel,
    required this.totalXp,
    required this.xpToNextLevel,
    required this.showXpGuide,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            isKo ? '현재 진행 상태' : 'Current progress',
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
              color: scheme.primary,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            isKo
                ? 'Lv.$currentLevel · 총 $totalXp XP'
                : 'Lv.$currentLevel · $totalXp XP total',
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 4),
          Text(
            showXpGuide
                ? (isKo
                      ? '경험치 오르는 방법을 펼쳐둔 상태예요.'
                      : 'The XP guide is open right now.')
                : (isKo
                      ? '다음 레벨까지 $xpToNextLevel XP 남았습니다.'
                      : '$xpToNextLevel XP left until the next level.'),
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }
}

class _RewardNameDialog extends StatefulWidget {
  final String initialValue;
  final bool isKo;

  const _RewardNameDialog({required this.initialValue, required this.isKo});

  @override
  State<_RewardNameDialog> createState() => _RewardNameDialogState();
}

class _RewardNameDialogState extends State<_RewardNameDialog> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialValue);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isKo = widget.isKo;
    return AlertDialog(
      title: Text(isKo ? '레벨 선물 입력' : 'Set level reward'),
      content: SizedBox(
        width: 360,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _controller,
              autofocus: true,
              maxLength: 30,
              decoration: InputDecoration(
                labelText: isKo ? '선물 이름' : 'Reward name',
                hintText: isKo ? '예) 새 축구 양말' : 'e.g. New football socks',
                border: const OutlineInputBorder(),
              ),
              textInputAction: TextInputAction.done,
              onSubmitted: (value) => Navigator.of(context).pop(value.trim()),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: Text(isKo ? '취소' : 'Cancel'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextButton(
                    onPressed: () => Navigator.of(context).pop(''),
                    child: Text(isKo ? '삭제' : 'Clear'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: FilledButton(
                    onPressed: () =>
                        Navigator.of(context).pop(_controller.text.trim()),
                    child: Text(isKo ? '저장' : 'Save'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _LevelGuideCard extends StatelessWidget {
  final int level;
  final int minXp;
  final int? maxXp;
  final bool isCurrent;
  final PlayerLevelRewardStatus? rewardStatus;
  final bool isKo;
  final PlayerLevelVisualSpec spec;
  final VoidCallback onClaimReward;
  final VoidCallback? onEditRewardName;

  const _LevelGuideCard({
    required this.level,
    required this.minXp,
    required this.maxXp,
    required this.isCurrent,
    required this.rewardStatus,
    required this.isKo,
    required this.spec,
    required this.onClaimReward,
    required this.onEditRewardName,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final reward = rewardStatus?.reward;
    final customRewardName = rewardStatus?.customRewardName.trim() ?? '';
    final nextRewardLabel = rewardStatus == null || customRewardName.isEmpty
        ? (isKo ? '없음' : 'Empty')
        : customRewardName;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: spec.colors,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: Colors.white.withValues(alpha: isCurrent ? 0.42 : 0.18),
          width: isCurrent ? 1.4 : 1,
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x14000000),
            blurRadius: 16,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Text(
                      'Lv.$level ${PlayerLevelService.levelName(level, isKo)}',
                      style: theme.textTheme.titleLarge?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    if (isCurrent)
                      _WhitePill(label: isKo ? '지금 여기' : 'Current'),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  PlayerLevelService.stageName(level, isKo),
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: Colors.white.withValues(alpha: 0.92),
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  PlayerLevelService.illustrationLabel(level, isKo),
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  maxXp == null
                      ? (isKo ? '$minXp XP 이상' : '$minXp XP+')
                      : (isKo
                            ? '$minXp XP ~ $maxXp XP'
                            : '$minXp XP to $maxXp XP'),
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: Colors.white.withValues(alpha: 0.88),
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (reward != null) ...[
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _WhitePill(
                          label: isKo
                              ? '선물: $nextRewardLabel'
                              : 'Reward: $nextRewardLabel',
                        ),
                      ),
                      const SizedBox(width: 8),
                      TextButton(
                        onPressed: onEditRewardName,
                        style: TextButton.styleFrom(
                          foregroundColor: Colors.white,
                        ),
                        child: Text(isKo ? '입력' : 'Edit'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    customRewardName.isNotEmpty
                        ? (isKo
                              ? '직접 입력한 레벨 선물이에요.'
                              : 'Your custom reward for this level.')
                        : (isKo
                              ? '입력하지 않으면 빈값으로 두고 나중에 채울 수 있어요.'
                              : 'Leave it empty for now and fill it later.'),
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: Colors.white.withValues(alpha: 0.9),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 10),
                  if (customRewardName.isEmpty)
                    Text(
                      isKo ? '선물을 입력하면 받을 수 있어요.' : 'Add a reward to claim it.',
                      style: theme.textTheme.labelLarge?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                      ),
                    )
                  else if (rewardStatus!.isClaimed)
                    Text(
                      isKo ? '이미 받았어요' : 'Already claimed',
                      style: theme.textTheme.labelLarge?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                      ),
                    )
                  else if (rewardStatus!.isAvailable)
                    FilledButton.tonal(
                      onPressed: onClaimReward,
                      style: FilledButton.styleFrom(
                        backgroundColor: Colors.white.withValues(alpha: 0.92),
                        foregroundColor: spec.colors.first,
                      ),
                      child: Text(isKo ? '선물 받기' : 'Claim reward'),
                    )
                  else
                    Text(
                      isKo
                          ? 'Lv.$level 이 되면 받을 수 있어요.'
                          : 'Available at Lv.$level.',
                      style: theme.textTheme.labelLarge?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 12),
          SizedBox(
            width: 108,
            height: 108,
            child: PlayerLevelIllustration(level: level),
          ),
        ],
      ),
    );
  }
}

class _XpGuideCard extends StatelessWidget {
  final bool isKo;

  const _XpGuideCard({required this.isKo});

  @override
  Widget build(BuildContext context) {
    final items = <String>[
      isKo ? '훈련 기록 저장: +20 XP' : 'Training log saved: +20 XP',
      isKo ? '하루 첫 훈련 기록: +10 XP' : 'First log of the day: +10 XP',
      isKo ? '계획한 날 훈련 완료: +25 XP' : 'Train on a planned day: +25 XP',
      isKo ? '퀴즈 완료: +15 XP' : 'Quiz completion: +15 XP',
      isKo ? '훈련 계획 생성: +10 XP' : 'Training plan created: +10 XP',
      isKo ? '훈련 스케치 저장: +8 XP' : 'Training sketch saved: +8 XP',
      isKo ? '새 훈련 스케치 생성: +12 XP' : 'Training sketch created: +12 XP',
      isKo ? '오늘 다이어리 확인: +5 XP' : 'Today diary reviewed: +5 XP',
      isKo
          ? '3일 연속 기록: +25 XP / 7일 연속 기록: +60 XP'
          : '3-day streak: +25 XP / 7-day streak: +60 XP',
      isKo
          ? '주간 3회 기록: +40 XP / 5회 기록: +70 XP'
          : '3 logs in a week: +40 XP / 5 logs: +70 XP',
    ];
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            isKo ? '경험치 오르는 방법' : 'How XP goes up',
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 8),
          ...items.map(
            (item) => Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Text(item, style: Theme.of(context).textTheme.bodyMedium),
            ),
          ),
        ],
      ),
    );
  }
}

class _WhitePill extends StatelessWidget {
  final String label;

  const _WhitePill({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelMedium?.copyWith(
          color: Colors.white,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}
