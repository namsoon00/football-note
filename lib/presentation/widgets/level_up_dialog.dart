import 'package:flutter/material.dart';

import '../../application/player_level_service.dart';

Future<void> showLevelUpCelebrationDialog(
  BuildContext context, {
  required PlayerLevelAward award,
  required bool isKo,
  required VoidCallback? onClaimReward,
  String customRewardName = '',
}) async {
  if (!award.didLevelUp) return;
  final reward = PlayerLevelService.rewardForLevel(award.after.level);
  final rewardName = customRewardName.trim();
  final hasCustomRewardName = rewardName.isNotEmpty;
  final hasReward = reward != null && hasCustomRewardName;
  final theme = Theme.of(context);
  final isDark = theme.brightness == Brightness.dark;
  final gradientColors = isDark
      ? const <Color>[
          Color(0xFF3A2D16),
          Color(0xFF4A2B2B),
          Color(0xFF2D334A),
        ]
      : const <Color>[
          Color(0xFFFFF1B8),
          Color(0xFFFFD36E),
          Color(0xFFFF9F68),
        ];
  final primaryTextColor = isDark ? const Color(0xFFFFF1D6) : const Color(0xFF5C2E00);
  final secondaryTextColor =
      isDark ? const Color(0xFFFFDCA8) : const Color(0xFF6F3C00);
  final infoBackground =
      isDark ? const Color(0xFF1D1F2A) : Colors.white.withValues(alpha: 0.74);
  final rewardBackground =
      isDark ? const Color(0x33242A3D) : const Color(0xFF5C2E00).withValues(alpha: 0.10);
  final rewardBorder =
      isDark ? const Color(0x66A88BFF) : const Color(0xFF5C2E00).withValues(alpha: 0.18);
  final actionButtonColor = isDark ? const Color(0xFF6B6CFF) : const Color(0xFF5C2E00);
  await showGeneralDialog<void>(
    context: context,
    barrierDismissible: true,
    barrierLabel: 'level-up',
    barrierColor: Colors.black45,
    transitionDuration: const Duration(milliseconds: 280),
    pageBuilder: (_, __, ___) => const SizedBox.shrink(),
    transitionBuilder: (context, animation, _, __) {
      final curved = CurvedAnimation(
        parent: animation,
        curve: Curves.easeOutCubic,
        reverseCurve: Curves.easeInCubic,
      );
      return FadeTransition(
        opacity: curved,
        child: ScaleTransition(
          scale: Tween<double>(begin: 0.92, end: 1).animate(curved),
          child: Dialog(
            backgroundColor: Colors.transparent,
            insetPadding: const EdgeInsets.symmetric(horizontal: 20),
            child: Container(
              padding: const EdgeInsets.all(22),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: gradientColors,
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(28),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x33000000),
                    blurRadius: 28,
                    offset: Offset(0, 14),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const _CelebrationBurst(),
                  const SizedBox(height: 14),
                  Text(
                    isKo ? '레벨 업!' : 'Level up!',
                    style: theme.textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.w900,
                      color: primaryTextColor,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    isKo
                        ? 'Lv.${award.after.level} ${PlayerLevelService.levelName(award.after.level, true)}'
                        : 'Lv.${award.after.level} ${PlayerLevelService.levelName(award.after.level, false)}',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w900,
                      color: primaryTextColor,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    isKo
                        ? hasCustomRewardName
                              ? '와! 오늘의 노력이 반짝 점수로 쌓여서 "$rewardName" 선물도 준비됐어요.'
                              : '와! 오늘의 노력이 반짝 점수로 쌓였어요.'
                        : 'Your effort turned into shining XP today.',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodyLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: secondaryTextColor,
                    ),
                  ),
                  const SizedBox(height: 14),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: infoBackground,
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: Text(
                      isKo
                          ? '+${award.gainedXp} XP를 받았고, 이제 ${PlayerLevelService.stageName(award.after.level, true)} 단계예요.'
                          : 'You earned +${award.gainedXp} XP and moved into ${PlayerLevelService.stageName(award.after.level, false)}.',
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: primaryTextColor,
                      ),
                    ),
                  ),
                  if (hasReward) ...[
                    const SizedBox(height: 14),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: rewardBackground,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: rewardBorder),
                      ),
                      child: Column(
                        children: [
                          Text(
                            isKo ? '선물 받기' : 'Reward',
                            style: theme.textTheme.labelLarge?.copyWith(
                              fontWeight: FontWeight.w800,
                              color: primaryTextColor,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            hasCustomRewardName
                                ? rewardName
                                : (isKo ? reward.nameKo : reward.nameEn),
                            textAlign: TextAlign.center,
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w900,
                              color: primaryTextColor,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            isKo ? reward.descriptionKo : reward.descriptionEn,
                            textAlign: TextAlign.center,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: secondaryTextColor,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  const SizedBox(height: 18),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.of(context).pop(),
                          child: Text(isKo ? '나중에 볼래' : 'Later'),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: FilledButton(
                          onPressed: () {
                            Navigator.of(context).pop();
                            onClaimReward?.call();
                          },
                          style: FilledButton.styleFrom(
                            backgroundColor: actionButtonColor,
                            foregroundColor: Colors.white,
                          ),
                          child: Text(
                            hasReward
                                ? (isKo ? '선물 받기' : 'Claim reward')
                                : (isKo ? '좋아요' : 'Awesome'),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    },
  );
}

class _CelebrationBurst extends StatelessWidget {
  const _CelebrationBurst();

  @override
  Widget build(BuildContext context) {
    return const SizedBox(
      width: 132,
      height: 88,
      child: Stack(
        alignment: Alignment.center,
        children: [
          _BurstDot(left: 10, top: 30, color: Color(0xFFFF7A59)),
          _BurstDot(left: 28, top: 10, color: Color(0xFFFFC145)),
          _BurstDot(right: 26, top: 12, color: Color(0xFF57CC99)),
          _BurstDot(right: 8, top: 34, color: Color(0xFF3FA7D6)),
          _BurstDot(left: 34, bottom: 2, color: Color(0xFFFF8FA3)),
          _BurstDot(right: 34, bottom: 6, color: Color(0xFF7B61FF)),
          Icon(Icons.celebration_rounded, size: 54, color: Color(0xFF5C2E00)),
        ],
      ),
    );
  }
}

class _BurstDot extends StatelessWidget {
  final double? left;
  final double? right;
  final double? top;
  final double? bottom;
  final Color color;

  const _BurstDot({
    this.left,
    this.right,
    this.top,
    this.bottom,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: left,
      right: right,
      top: top,
      bottom: bottom,
      child: Container(
        width: 14,
        height: 14,
        decoration: BoxDecoration(color: color, shape: BoxShape.circle),
      ),
    );
  }
}
