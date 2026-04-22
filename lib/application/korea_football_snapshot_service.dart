import 'dart:async';

import 'package:http/http.dart' as http;

import '../domain/entities/korea_football_snapshot.dart';

class KoreaFootballSnapshotService {
  static final Uri fifaRankingUri = Uri.parse(
    'https://inside.fifa.com/fifa-world-ranking/KOR',
  );
  static final Uri kfaNationalTeamUri = Uri.parse(
    'https://www.kfa.or.kr/national/?act=nt_man',
  );

  final http.Client _client;

  KoreaFootballSnapshotService({http.Client? client})
      : _client = client ?? http.Client();

  Future<KoreaFootballSnapshot> fetchLatest() async {
    final results = await Future.wait<dynamic>([
      _fetchFifaRanking(),
      _fetchRecentMatches(),
    ]);
    return KoreaFootballSnapshot(
      fifaRanking: results[0] as KoreaFifaRankingSnapshot?,
      recentMatches: results[1] as List<KoreaAMatchSnapshot>,
      fetchedAt: DateTime.now(),
    );
  }

  Future<KoreaFifaRankingSnapshot?> _fetchFifaRanking() async {
    try {
      final response =
          await _client.get(fifaRankingUri).timeout(const Duration(seconds: 8));
      if (response.statusCode != 200) {
        return null;
      }
      return parseFifaRankingHtml(response.body);
    } catch (_) {
      return null;
    }
  }

  Future<List<KoreaAMatchSnapshot>> _fetchRecentMatches() async {
    try {
      final response = await _client
          .get(kfaNationalTeamUri)
          .timeout(const Duration(seconds: 8));
      if (response.statusCode != 200) {
        return const <KoreaAMatchSnapshot>[];
      }
      return parseRecentMatchesHtml(response.body);
    } catch (_) {
      return const <KoreaAMatchSnapshot>[];
    }
  }

  static KoreaFifaRankingSnapshot? parseFifaRankingHtml(String html) {
    final teamName = _firstGroup(
          html,
          RegExp(r'<div class="header_header__[^"]*">([^<]+)</div>'),
        ) ??
        'Korea Republic';
    final rankText = _firstGroup(
          html,
          RegExp(
            r'<div class="highlights_resultItemValue__[^"]*">\s*<span[^>]*>(\d+)(?:st|nd|rd|th)?</span>\s*</div>\s*<div class="highlights_resultItemLabel__[^"]*">\s*<span>Current rank</span>',
            dotAll: true,
          ),
        ) ??
        _firstGroup(
          html,
          RegExp(
            r'<span>Current rank</span>\s*</div>\s*<div[^>]*>\s*<span[^>]*>(\d+)(?:st|nd|rd|th)?</span>',
            dotAll: true,
          ),
        ) ??
        _firstGroup(
          html,
          RegExp(r'"label":"Current rank","value":"(\d+)(?:st|nd|rd|th)"'),
        );
    final currentRank = int.tryParse(rankText ?? '');
    if (currentRank == null) {
      return null;
    }
    final updatedText = _firstGroup(
      html,
      RegExp(
        r'Last official update:</span>\s*<span[^>]*>([^<]+)</span>',
        dotAll: true,
      ),
    );
    return KoreaFifaRankingSnapshot(
      teamName: _cleanText(teamName),
      currentRank: currentRank,
      updatedAt: _parseFifaDate(updatedText),
      officialUrl: fifaRankingUri.toString(),
    );
  }

  static List<KoreaAMatchSnapshot> parseRecentMatchesHtml(
    String html, {
    int maxItems = 2,
  }) {
    final matches = <KoreaAMatchSnapshot>[];
    final pattern = RegExp(
      r'<div class="result_info">\s*<p class="result_title">\s*<span class="title">([^<]+)</span>\s*<span style="display:block">([^<]+)</span>\s*</p>\s*<ul[^>]*>\s*<li class="korea">\s*남자 국가대표팀\s*<span>(\d+)\s*</span>\s*</li>\s*<li class="away"[^>]*>\s*([^<]+?)\s*<span[^>]*>(\d+)\s*</span>\s*</li>\s*</ul>\s*<em[^>]*>([^<]+)</em>',
      dotAll: true,
    );
    for (final match in pattern.allMatches(html)) {
      final competition = _cleanText(match.group(1));
      final venue = _cleanText(match.group(2));
      final koreaScore = int.tryParse(match.group(3) ?? '');
      final opponent = _cleanText(match.group(4));
      final opponentScore = int.tryParse(match.group(5) ?? '');
      final playedAtText = _cleanText(match.group(6));
      final competitionYear = _extractCompetitionYear(competition);
      if (koreaScore == null || opponentScore == null || opponent.isEmpty) {
        continue;
      }
      matches.add(
        KoreaAMatchSnapshot(
          competition: competition,
          venue: venue,
          opponent: opponent,
          koreaScore: koreaScore,
          opponentScore: opponentScore,
          playedAt: _parseKfaDate(
            playedAtText,
            fallbackYear: competitionYear ?? DateTime.now().year,
          ),
          officialUrl: kfaNationalTeamUri.toString(),
        ),
      );
      if (matches.length >= maxItems) {
        break;
      }
    }
    return matches;
  }

  static String? _firstGroup(String input, RegExp pattern) {
    final match = pattern.firstMatch(input);
    if (match == null || match.groupCount < 1) {
      return null;
    }
    return match.group(1);
  }

  static String _cleanText(String? raw) {
    return (raw ?? '')
        .replaceAll('&nbsp;', ' ')
        .replaceAll('&#x27;', "'")
        .replaceAll('&amp;', '&')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }

  static DateTime? _parseFifaDate(String? raw) {
    final cleaned = _cleanText(raw);
    if (cleaned.isEmpty) {
      return null;
    }
    final match = RegExp(r'(\d{2}) ([A-Za-z]+) (\d{4})').firstMatch(cleaned);
    if (match == null) {
      return null;
    }
    final month = _monthIndex(match.group(2));
    if (month == null) {
      return null;
    }
    return DateTime.utc(
      int.parse(match.group(3)!),
      month,
      int.parse(match.group(1)!),
    );
  }

  static DateTime? _parseKfaDate(String raw, {required int fallbackYear}) {
    final match = RegExp(
      r'(\d{2})\.\s*(\d{2})\s*[^\d]+\s*(\d{2}):(\d{2})',
    ).firstMatch(raw);
    if (match == null) {
      return null;
    }
    return DateTime(
      fallbackYear,
      int.parse(match.group(1)!),
      int.parse(match.group(2)!),
      int.parse(match.group(3)!),
      int.parse(match.group(4)!),
    );
  }

  static int? _extractCompetitionYear(String competition) {
    final match = RegExp(r'\b(20\d{2})\b').firstMatch(competition);
    return match == null ? null : int.tryParse(match.group(1)!);
  }

  static int? _monthIndex(String? raw) {
    return switch ((raw ?? '').trim().toLowerCase()) {
      'january' => 1,
      'february' => 2,
      'march' => 3,
      'april' => 4,
      'may' => 5,
      'june' => 6,
      'july' => 7,
      'august' => 8,
      'september' => 9,
      'october' => 10,
      'november' => 11,
      'december' => 12,
      _ => null,
    };
  }
}
