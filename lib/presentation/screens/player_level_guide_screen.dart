import 'package:flutter/material.dart';
import 'package:football_note/gen/app_localizations.dart';

import '../../application/backup_service.dart';
import '../../application/family_access_service.dart';
import '../../application/player_level_service.dart';
import '../../domain/repositories/option_repository.dart';
import '../widgets/app_background.dart';
import '../widgets/app_feedback.dart';
import '../widgets/player_level_visuals.dart';
import 'player_xp_guide_screen.dart';
import 'player_xp_history_screen.dart';

class PlayerLevelGuideScreen extends StatefulWidget {
  final int currentLevel;
  final OptionRepository optionRepository;
  final BackupService? driveBackupService;

  const PlayerLevelGuideScreen({
    super.key,
    required this.currentLevel,
    required this.optionRepository,
    this.driveBackupService,
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
    final l10n = AppLocalizations.of(context)!;
    final thresholds = PlayerLevelService.levelThresholds;
    final currentState = _levelService.loadState();
    final familyState = FamilyAccessService(
      widget.optionRepository,
    ).loadState();
    final rewardByLevel = {
      for (final item in _levelService.loadRewardStatuses())
        item.reward.level: item,
    };

    return Scaffold(
      appBar: AppBar(
        title: Text(isKo ? '레벨 가이드' : 'Level guide'),
        actions: [
          IconButton(
            tooltip: isKo ? '경험치 가이드 열기' : 'Open XP guide',
            onPressed: () => _openXpGuide(context),
            icon: const Icon(Icons.menu_book_outlined),
          ),
          IconButton(
            tooltip: isKo ? '경험치 히스토리' : 'XP history',
            onPressed: () => _openXpHistory(context, isKo),
            icon: const Icon(Icons.schedule_outlined),
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
                roleLabel: familyState.isParentMode
                    ? l10n.levelGuideParentModeLabel
                    : l10n.levelGuideChildModeLabel,
                roleMessage: familyState.isParentMode
                    ? l10n.levelGuideParentModeDescription
                    : l10n.levelGuideChildModeDescription,
              ),
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
                  canClaimReward: familyState.isChildMode,
                  claimDisabledLabel: l10n.levelGuideClaimChildOnly,
                  onClaimReward: () => _claimReward(levelIndex + 1),
                  onEditRewardName:
                      rewardByLevel[levelIndex + 1] == null ||
                          !familyState.isParentMode
                      ? null
                      : () => _editRewardName(
                          context,
                          rewardByLevel[levelIndex + 1]!,
                        ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _claimReward(int level) async {
    final claim = await _levelService.claimRewardForLevel(level);
    if (!mounted || claim == null) return;
    await _syncSharedBackupIfPossible();
    if (!mounted) return;
    setState(() {});
    final l10n = AppLocalizations.of(context)!;
    final rewardName = claim.customRewardName.trim().isNotEmpty
        ? claim.customRewardName
        : l10n.levelGuideRewardFallbackName;
    AppFeedback.showSuccess(
      context,
      text: l10n.levelGuideRewardClaimed(rewardName),
    );
  }

  Future<void> _editRewardName(
    BuildContext context,
    PlayerLevelRewardStatus status,
  ) async {
    final saved = await showDialog<String>(
      context: context,
      builder: (dialogContext) => _RewardNameDialog(
        initialValue: status.customRewardName,
        isKo: Localizations.localeOf(context).languageCode == 'ko',
      ),
    );
    if (saved == null) return;
    await _levelService.setCustomRewardName(status.reward.level, saved);
    final didSync = await _syncSharedBackupIfPossible();
    if (!context.mounted) return;
    setState(() {});
    final l10n = AppLocalizations.of(context)!;
    final baseMessage = saved.trim().isEmpty
        ? l10n.levelGuideRewardCleared
        : l10n.levelGuideRewardSaved;
    final syncMessage =
        FamilyAccessService(widget.optionRepository).loadState().isParentMode
        ? (didSync ? l10n.parentSharedSyncDone : l10n.parentSharedSyncPending)
        : '';
    AppFeedback.showSuccess(
      context,
      text: syncMessage.isEmpty ? baseMessage : '$baseMessage $syncMessage',
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

  Future<void> _openXpGuide(BuildContext context) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) =>
            PlayerXpGuideScreen(optionRepository: widget.optionRepository),
      ),
    );
  }

  Future<bool> _syncSharedBackupIfPossible() async {
    final backup = widget.driveBackupService;
    if (backup == null) return false;
    final familyState = FamilyAccessService(
      widget.optionRepository,
    ).loadState();
    try {
      if (familyState.isParentMode) {
        await backup.markParentSharedDataDirty();
      }
      return await backup.backupIfSignedIn();
    } catch (_) {
      // Reward changes still remain local if the shared backup is unavailable.
      return false;
    }
  }
}

class _LevelGuideSummaryCard extends StatelessWidget {
  final bool isKo;
  final int currentLevel;
  final int totalXp;
  final int xpToNextLevel;
  final String roleLabel;
  final String roleMessage;

  const _LevelGuideSummaryCard({
    required this.isKo,
    required this.currentLevel,
    required this.totalXp,
    required this.xpToNextLevel,
    required this.roleLabel,
    required this.roleMessage,
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
            isKo
                ? '다음 레벨까지 $xpToNextLevel XP 남았습니다. 우측 상단에서 경험치 가이드와 히스토리를 바로 열 수 있어요.'
                : '$xpToNextLevel XP left until the next level. Use the top-right actions for the XP guide and history.',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              color: scheme.surface,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  roleLabel,
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: scheme.primary,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 4),
                Text(roleMessage, style: Theme.of(context).textTheme.bodySmall),
              ],
            ),
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
  final bool canClaimReward;
  final String claimDisabledLabel;
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
    required this.canClaimReward,
    required this.claimDisabledLabel,
    required this.onClaimReward,
    required this.onEditRewardName,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final reward = rewardStatus?.reward;
    final customRewardName = rewardStatus?.customRewardName.trim() ?? '';
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
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.16),
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.20),
                      ),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 42,
                          height: 42,
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.18),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: const Icon(
                            Icons.card_giftcard_outlined,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      isKo ? '레벨 선물' : 'Level reward',
                                      style: theme.textTheme.labelLarge
                                          ?.copyWith(
                                            color: Colors.white,
                                            fontWeight: FontWeight.w900,
                                          ),
                                    ),
                                  ),
                                  if (onEditRewardName != null)
                                    TextButton(
                                      onPressed: onEditRewardName,
                                      style: TextButton.styleFrom(
                                        foregroundColor: Colors.white,
                                        minimumSize: const Size(1, 32),
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8,
                                        ),
                                        tapTargetSize:
                                            MaterialTapTargetSize.shrinkWrap,
                                      ),
                                      child: Text(isKo ? '입력' : 'Edit'),
                                    ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text(
                                customRewardName.isEmpty
                                    ? (isKo ? '미정' : 'Not set')
                                    : customRewardName,
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  if (customRewardName.isEmpty)
                    _WhitePill(
                      label: isKo ? '선물 입력 후 수령 가능' : 'Add reward to claim',
                    )
                  else if (rewardStatus!.isClaimed)
                    _WhitePill(label: isKo ? '이미 받음' : 'Already claimed')
                  else if (rewardStatus!.isAvailable && canClaimReward)
                    FilledButton.tonal(
                      onPressed: onClaimReward,
                      style: FilledButton.styleFrom(
                        backgroundColor: Colors.white.withValues(alpha: 0.92),
                        foregroundColor: spec.colors.first,
                      ),
                      child: Text(isKo ? '선물 받기' : 'Claim reward'),
                    )
                  else if (rewardStatus!.isAvailable)
                    _WhitePill(label: claimDisabledLabel)
                  else
                    _WhitePill(
                      label: isKo
                          ? 'Lv.$level 달성 시 수령 가능'
                          : 'Claim at Lv.$level',
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
