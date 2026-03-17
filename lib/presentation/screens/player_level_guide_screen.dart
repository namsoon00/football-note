import 'package:flutter/material.dart';

import '../../application/player_level_service.dart';
import '../../domain/repositories/option_repository.dart';
import '../widgets/app_background.dart';
import '../widgets/app_feedback.dart';
import '../widgets/player_level_visuals.dart';

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

  @override
  void initState() {
    super.initState();
    _levelService = PlayerLevelService(widget.optionRepository);
  }

  @override
  Widget build(BuildContext context) {
    final isKo = Localizations.localeOf(context).languageCode == 'ko';
    final thresholds = PlayerLevelService.levelThresholds;
    final rewardByLevel = {
      for (final item in _levelService.loadRewardStatuses())
        item.reward.level: item,
    };

    return Scaffold(
      appBar: AppBar(title: Text(isKo ? '레벨 가이드' : 'Level guide')),
      body: AppBackground(
        child: SafeArea(
          child: ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
            itemCount: thresholds.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final level = index + 1;
              final spec = PlayerLevelVisualSpec.fromLevel(level);
              final minXp = thresholds[index];
              final maxXp = index + 1 < thresholds.length
                  ? thresholds[index + 1] - 1
                  : null;
              return _LevelGuideCard(
                level: level,
                minXp: minXp,
                maxXp: maxXp,
                isCurrent: level == widget.currentLevel,
                rewardStatus: rewardByLevel[level],
                isKo: isKo,
                spec: spec,
                onClaimReward: () => _claimReward(level, isKo),
                onEditRewardName: rewardByLevel[level] == null
                    ? null
                    : () =>
                        _editRewardName(context, rewardByLevel[level]!, isKo),
              );
            },
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
        : (isKo ? claim.reward.nameKo : claim.reward.nameEn);
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
    final controller = TextEditingController(text: status.customRewardName);
    final saved = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(isKo ? '레벨 선물 입력' : 'Set level reward'),
        content: TextField(
          controller: controller,
          autofocus: true,
          maxLength: 30,
          decoration: InputDecoration(
            labelText: isKo ? '선물 이름' : 'Reward name',
            hintText: isKo ? '예) 새 축구 양말' : 'e.g. New football socks',
            border: const OutlineInputBorder(),
          ),
          textInputAction: TextInputAction.done,
          onSubmitted: (value) => Navigator.of(dialogContext).pop(value.trim()),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: Text(isKo ? '취소' : 'Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(''),
            child: Text(isKo ? '삭제' : 'Clear'),
          ),
          FilledButton(
            onPressed: () =>
                Navigator.of(dialogContext).pop(controller.text.trim()),
            child: Text(isKo ? '저장' : 'Save'),
          ),
        ],
      ),
    );
    controller.dispose();
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
    final rewardLabel = customRewardName.isNotEmpty
        ? customRewardName
        : (reward == null ? '' : (isKo ? reward.nameKo : reward.nameEn));
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
                              ? '선물: $rewardLabel'
                              : 'Reward: $rewardLabel',
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
                        : (isKo ? reward.descriptionKo : reward.descriptionEn),
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: Colors.white.withValues(alpha: 0.9),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 10),
                  if (rewardStatus!.isClaimed)
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
