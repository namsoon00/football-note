import 'package:flutter/material.dart';

class GameRankingEntry {
  final DateTime playedAt;
  final int score;
  final int level;
  final int goals;
  final int rankScore;
  final String rankLabel;
  final String difficulty;

  const GameRankingEntry({
    required this.playedAt,
    required this.score,
    required this.level,
    required this.goals,
    required this.rankScore,
    required this.rankLabel,
    required this.difficulty,
  });

  Map<String, dynamic> toMap() {
    return {
      'playedAt': playedAt.toIso8601String(),
      'score': score,
      'level': level,
      'goals': goals,
      'rankScore': rankScore,
      'rankLabel': rankLabel,
      'difficulty': difficulty,
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
      difficulty: map['difficulty']?.toString() ?? 'medium',
    );
  }
}

class GameRankingScreen extends StatelessWidget {
  final List<GameRankingEntry> entries;

  const GameRankingScreen({
    super.key,
    required this.entries,
  });

  @override
  Widget build(BuildContext context) {
    final isKo = Localizations.localeOf(context).languageCode == 'ko';
    final sorted = [...entries]..sort((a, b) {
        final score = b.rankScore.compareTo(a.rankScore);
        if (score != 0) return score;
        return b.playedAt.compareTo(a.playedAt);
      });

    return Scaffold(
      appBar: AppBar(
        title: Text(isKo ? '게임 랭킹' : 'Game Rankings'),
      ),
      body: sorted.isEmpty
          ? Center(
              child: Text(
                isKo ? '아직 랭킹 기록이 없습니다.' : 'No ranking records yet.',
              ),
            )
          : ListView.separated(
              padding: const EdgeInsets.all(12),
              itemCount: sorted.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                final entry = sorted[index];
                final rankNo = index + 1;
                final dateText =
                    '${entry.playedAt.year}.${entry.playedAt.month.toString().padLeft(2, '0')}.${entry.playedAt.day.toString().padLeft(2, '0')}';
                final diffText = _difficultyText(entry.difficulty, isKo);
                return Card(
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    leading: CircleAvatar(
                      child: Text('$rankNo'),
                    ),
                    title: Text(
                      isKo
                          ? '${entry.rankLabel}등급 · 점수 ${entry.score}'
                          : 'Rank ${entry.rankLabel} · Score ${entry.score}',
                      style: const TextStyle(fontWeight: FontWeight.w800),
                    ),
                    subtitle: Text(
                      isKo
                          ? '레벨 Lv.${entry.level} · 골 ${entry.goals} · 난이도 $diffText · $dateText'
                          : 'Level Lv.${entry.level} · Goals ${entry.goals} · Difficulty $diffText · $dateText',
                    ),
                    trailing: Text(
                      '${entry.rankScore}',
                      style: TextStyle(
                        fontWeight: FontWeight.w900,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                  ),
                );
              },
            ),
    );
  }

  String _difficultyText(String raw, bool isKo) {
    switch (raw) {
      case 'easy':
        return isKo ? '초급' : 'Easy';
      case 'hard':
        return isKo ? '고급' : 'Hard';
      case 'medium':
      default:
        return isKo ? '중급' : 'Medium';
    }
  }
}
