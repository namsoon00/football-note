import 'package:flutter/material.dart';
import 'package:football_note/gen/app_localizations.dart';
import 'package:football_note/presentation/theme/app_theme.dart';
import 'package:football_note/presentation/widgets/app_background.dart';

class GameRankingEntry {
  final DateTime playedAt;
  final int score;
  final int level;
  final int goals;
  final int rankScore;
  final String rankLabel;
  final String? difficulty;

  const GameRankingEntry({
    required this.playedAt,
    required this.score,
    required this.level,
    required this.goals,
    required this.rankScore,
    required this.rankLabel,
    this.difficulty,
  });

  Map<String, dynamic> toMap() {
    return {
      'playedAt': playedAt.toIso8601String(),
      'score': score,
      'level': level,
      'goals': goals,
      'rankScore': rankScore,
      'rankLabel': rankLabel,
      if (difficulty != null) 'difficulty': difficulty,
    };
  }

  static GameRankingEntry? fromMap(Map<String, dynamic> map) {
    final rawDate = map['playedAt']?.toString();
    final date = rawDate == null ? null : DateTime.tryParse(rawDate);
    if (date == null) return null;
    return GameRankingEntry(
      playedAt: date,
      score: (map['score'] as num?)?.toInt() ?? 0,
      level: (map['level'] as num?)?.toInt() ?? 0,
      goals: (map['goals'] as num?)?.toInt() ?? 0,
      rankScore: (map['rankScore'] as num?)?.toInt() ?? 0,
      rankLabel: map['rankLabel']?.toString() ?? 'D',
      difficulty: map['difficulty']?.toString(),
    );
  }
}

class GameRankingScreen extends StatelessWidget {
  final List<GameRankingEntry> entries;

  const GameRankingScreen({super.key, required this.entries});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;
    final scheme = theme.colorScheme;
    final sorted = [...entries]..sort((a, b) {
        final score = b.rankScore.compareTo(a.rankScore);
        if (score != 0) return score;
        return b.playedAt.compareTo(a.playedAt);
      });
    final top10 = sorted.take(10).toList(growable: false);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.gameRankingTitle)),
      body: AppBackground(
        child: top10.isEmpty
            ? Center(
                child: Padding(
                  padding: AppSpacing.screen,
                  child: Text(
                    l10n.gameRankingEmpty,
                    textAlign: TextAlign.center,
                    style: textTheme.bodyMedium?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                ),
              )
            : ListView.separated(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.md,
                  AppSpacing.md,
                  AppSpacing.md,
                  AppSpacing.xl,
                ),
                itemCount: top10.length,
                separatorBuilder: (_, __) => const SizedBox(
                  height: AppSpacing.sm,
                ),
                itemBuilder: (context, index) {
                  final entry = top10[index];
                  final rankNo = index + 1;
                  final dateText =
                      '${entry.playedAt.year}.${entry.playedAt.month.toString().padLeft(2, '0')}.${entry.playedAt.day.toString().padLeft(2, '0')}';
                  return Card(
                    margin: EdgeInsets.zero,
                    child: ListTile(
                      minLeadingWidth: AppSizes.minTouchTarget,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.md,
                        vertical: AppSpacing.xs,
                      ),
                      leading: _rankLeading(context, rankNo),
                      title: Text(
                        l10n.gameRankingEntryTitle(
                          entry.rankLabel,
                          entry.rankScore,
                          entry.score,
                        ),
                        style: textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      subtitle: Padding(
                        padding: const EdgeInsets.only(top: AppSpacing.xxs),
                        child: Text(
                          l10n.gameRankingEntrySubtitle(
                            entry.level,
                            entry.goals,
                            dateText,
                          ),
                          style: textTheme.bodySmall?.copyWith(
                            color: scheme.onSurfaceVariant,
                          ),
                        ),
                      ),
                      trailing: Text(
                        l10n.gameRankingPosition(rankNo),
                        style: textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w900,
                          color: scheme.primary,
                        ),
                      ),
                    ),
                  );
                },
              ),
      ),
    );
  }

  Widget _rankLeading(BuildContext context, int rankNo) {
    final scheme = Theme.of(context).colorScheme;
    if (rankNo == 1) {
      return CircleAvatar(
        backgroundColor: scheme.tertiaryContainer,
        foregroundColor: scheme.onTertiaryContainer,
        child: const Icon(Icons.emoji_events),
      );
    }
    if (rankNo == 2) {
      return CircleAvatar(
        backgroundColor: scheme.secondaryContainer,
        foregroundColor: scheme.onSecondaryContainer,
        child: const Icon(Icons.military_tech),
      );
    }
    if (rankNo == 3) {
      return CircleAvatar(
        backgroundColor: scheme.primaryContainer,
        foregroundColor: scheme.onPrimaryContainer,
        child: const Icon(Icons.military_tech),
      );
    }
    return CircleAvatar(
      backgroundColor: scheme.surfaceContainerHighest,
      foregroundColor: scheme.onSurfaceVariant,
      child: Text(
        '$rankNo',
        style: Theme.of(context).textTheme.labelLarge?.copyWith(
              fontWeight: FontWeight.w900,
              color: scheme.onSurfaceVariant,
            ),
      ),
    );
  }
}
