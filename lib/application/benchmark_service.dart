import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../domain/repositories/option_repository.dart';

class TargetBenchmark {
  final int weeklyMinutesTarget;
  final int weeklySessionsTarget;

  const TargetBenchmark({
    required this.weeklyMinutesTarget,
    required this.weeklySessionsTarget,
  });
}

class BenchmarkSource {
  final String title;
  final String url;

  const BenchmarkSource({
    required this.title,
    required this.url,
  });
}

class PhysicalBenchmark {
  final double heightCmAvg;
  final double weightKgAvg;
  final int liftsPerSessionAvg;

  const PhysicalBenchmark({
    required this.heightCmAvg,
    required this.weightKgAvg,
    required this.liftsPerSessionAvg,
  });
}

class BenchmarkService {
  static const _physicalByAgeCacheKey = 'benchmark_physical_by_age_v2';
  static const _liftingByAgeCacheKey = 'benchmark_lifting_by_age_v2';
  static const _syncedAtCacheKey = 'benchmark_synced_at_v2';

  static const _heightCsvUrl =
      'https://www.cdc.gov/growthcharts/data/zscore/statage.csv';
  static const _weightCsvUrl =
      'https://www.cdc.gov/growthcharts/data/zscore/wtage.csv';
  static const _liftingGuideUrl =
      'https://www.progressivesoccertraining.com/soccer-juggling-by-age/';

  final OptionRepository _options;
  final http.Client _client;

  static bool _refreshing = false;

  BenchmarkService(
    this._options, {
    http.Client? client,
  }) : _client = client ?? http.Client();

  PhysicalBenchmark physicalBenchmarkForAge(int? ageYears) {
    final age = (ageYears ?? 13).clamp(6, 18);
    final physicalTable = _readPhysicalByAge() ?? _defaultPhysicalByAge();
    final liftingTable = _readLiftingByAge() ?? _defaultLiftingByAge();
    final physical = physicalTable[age] ?? physicalTable[13]!;
    return PhysicalBenchmark(
      heightCmAvg: physical.heightCmAvg,
      weightKgAvg: physical.weightKgAvg,
      liftsPerSessionAvg: liftingTable[age] ?? liftingTable[13]!,
    );
  }

  DateTime? lastSyncedAt() {
    final raw = _options.getValue<String>(_syncedAtCacheKey);
    if (raw == null || raw.isEmpty) return null;
    return DateTime.tryParse(raw);
  }

  Future<void> refreshFromExternalIfNeeded({
    Duration staleAfter = const Duration(days: 14),
    bool force = false,
  }) async {
    if (_refreshing) return;

    final syncedAt = lastSyncedAt();
    final now = DateTime.now().toUtc();
    if (!force &&
        syncedAt != null &&
        now.difference(syncedAt.toUtc()) < staleAfter) {
      return;
    }

    _refreshing = true;
    try {
      final physical = await _fetchPhysicalFromCdc();
      if (physical != null && physical.isNotEmpty) {
        await _options.setValue(
          _physicalByAgeCacheKey,
          jsonEncode(
            physical.map(
              (age, value) => MapEntry(age.toString(), {
                'h': value.heightCmAvg,
                'w': value.weightKgAvg,
              }),
            ),
          ),
        );
      }

      final lifting = await _fetchLiftingByAge();
      if (lifting != null && lifting.isNotEmpty) {
        await _options.setValue(
          _liftingByAgeCacheKey,
          jsonEncode(lifting.map((age, value) => MapEntry('$age', value))),
        );
      }

      await _options.setValue(_syncedAtCacheKey, now.toIso8601String());
    } catch (_) {
      // Keep fallback/cache values when remote fetch fails.
    } finally {
      _refreshing = false;
    }
  }

  Map<int, PhysicalBenchmark>? _readPhysicalByAge() {
    final raw = _options.getValue<String>(_physicalByAgeCacheKey);
    if (raw == null || raw.isEmpty) return null;
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map<String, dynamic>) return null;
      final result = <int, PhysicalBenchmark>{};
      decoded.forEach((key, value) {
        final age = int.tryParse(key);
        if (age == null) return;
        if (value is! Map) return;
        final h = (value['h'] as num?)?.toDouble();
        final w = (value['w'] as num?)?.toDouble();
        if (h == null || w == null) return;
        result[age] = PhysicalBenchmark(
          heightCmAvg: h,
          weightKgAvg: w,
          liftsPerSessionAvg: 0,
        );
      });
      return result.isEmpty ? null : result;
    } catch (_) {
      return null;
    }
  }

  Map<int, int>? _readLiftingByAge() {
    final raw = _options.getValue<String>(_liftingByAgeCacheKey);
    if (raw == null || raw.isEmpty) return null;
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map<String, dynamic>) return null;
      final result = <int, int>{};
      decoded.forEach((key, value) {
        final age = int.tryParse(key);
        final lifts = (value is num) ? value.toInt() : int.tryParse('$value');
        if (age == null || lifts == null) return;
        result[age] = lifts;
      });
      return result.isEmpty ? null : result;
    } catch (_) {
      return null;
    }
  }

  Future<Map<int, PhysicalBenchmark>?> _fetchPhysicalFromCdc() async {
    final heightCsv = await _fetchTextWithWebFallback(_heightCsvUrl);
    final weightCsv = await _fetchTextWithWebFallback(_weightCsvUrl);
    if (heightCsv == null || weightCsv == null) return null;

    final heightRows = _parseLmsRows(heightCsv);
    final weightRows = _parseLmsRows(weightCsv);
    if (heightRows.isEmpty || weightRows.isEmpty) return null;

    final bySexHeight = _groupRowsBySex(heightRows);
    final bySexWeight = _groupRowsBySex(weightRows);
    if (!bySexHeight.containsKey(1) ||
        !bySexHeight.containsKey(2) ||
        !bySexWeight.containsKey(1) ||
        !bySexWeight.containsKey(2)) {
      return null;
    }

    final output = <int, PhysicalBenchmark>{};
    for (var age = 6; age <= 18; age++) {
      final ageMonths = age * 12 + 6;
      final boyH = _nearestMedian(bySexHeight[1]!, ageMonths);
      final girlH = _nearestMedian(bySexHeight[2]!, ageMonths);
      final boyW = _nearestMedian(bySexWeight[1]!, ageMonths);
      final girlW = _nearestMedian(bySexWeight[2]!, ageMonths);
      if (boyH == null || girlH == null || boyW == null || girlW == null) {
        continue;
      }
      output[age] = PhysicalBenchmark(
        heightCmAvg: (boyH + girlH) / 2,
        weightKgAvg: (boyW + girlW) / 2,
        liftsPerSessionAvg: 0,
      );
    }
    return output.isEmpty ? null : output;
  }

  Future<Map<int, int>?> _fetchLiftingByAge() async {
    final html = await _fetchTextWithWebFallback(_liftingGuideUrl);
    if (html == null || html.isEmpty) return null;
    final lower = html.toLowerCase();

    final a = _extractRangeMidpoint(
        lower, RegExp(r'6\s*-\s*8[^0-9]{0,40}(\d+)\s*-\s*(\d+)'));
    final b = _extractRangeMidpoint(
        lower, RegExp(r'9\s*-\s*12[^0-9]{0,40}(\d+)\s*-\s*(\d+)'));
    final c = _extractRangeMidpoint(
        lower, RegExp(r'13\s*-\s*16[^0-9]{0,40}(\d+)\s*-\s*(\d+)'));
    final d = _extractSingleValue(lower, RegExp(r'17\+[^0-9]{0,40}(\d+)'));

    if (a == null || b == null || c == null || d == null) return null;

    final result = <int, int>{};
    for (var age = 6; age <= 8; age++) {
      result[age] = a;
    }
    for (var age = 9; age <= 12; age++) {
      result[age] = b;
    }
    for (var age = 13; age <= 16; age++) {
      result[age] = c;
    }
    for (var age = 17; age <= 18; age++) {
      result[age] = d;
    }
    return result;
  }

  int? _extractRangeMidpoint(String text, RegExp exp) {
    final m = exp.firstMatch(text);
    if (m == null) return null;
    final min = int.tryParse(m.group(1) ?? '');
    final max = int.tryParse(m.group(2) ?? '');
    if (min == null || max == null) return null;
    return ((min + max) / 2).round();
  }

  int? _extractSingleValue(String text, RegExp exp) {
    final m = exp.firstMatch(text);
    if (m == null) return null;
    return int.tryParse(m.group(1) ?? '');
  }

  Future<String?> _fetchTextWithWebFallback(String url) async {
    final requests = _requestsForPlatform(url);
    for (final req in requests) {
      try {
        final response = await _client
            .get(Uri.parse(req.url))
            .timeout(const Duration(seconds: 12));
        if (response.statusCode != 200) continue;
        if (req.type == _RemoteResponseType.raw) {
          if (response.body.trim().isNotEmpty) return response.body;
          continue;
        }
        final decoded = jsonDecode(response.body);
        if (decoded is! Map<String, dynamic>) continue;
        final contents = decoded['contents'];
        if (contents is String && contents.trim().isNotEmpty) {
          return contents;
        }
      } catch (_) {
        // Try next fallback endpoint.
      }
    }
    return null;
  }

  List<_RemoteRequest> _requestsForPlatform(String url) {
    if (!kIsWeb) {
      return [
        _RemoteRequest(url: url, type: _RemoteResponseType.raw),
      ];
    }
    final encoded = Uri.encodeComponent(url);
    return [
      _RemoteRequest(
        url: 'https://api.allorigins.win/raw?url=$encoded',
        type: _RemoteResponseType.raw,
      ),
      _RemoteRequest(
        url: 'https://api.allorigins.win/get?url=$encoded',
        type: _RemoteResponseType.allOriginsGet,
      ),
    ];
  }

  List<_LmsRow> _parseLmsRows(String csv) {
    final lines = const LineSplitter()
        .convert(csv)
        .where((line) => line.trim().isNotEmpty)
        .toList();
    if (lines.length < 2) return const [];

    final headers = lines.first
        .split(',')
        .map((s) => s.trim().toLowerCase())
        .toList(growable: false);
    final sexIdx = headers.indexWhere((h) => h == 'sex');
    final ageIdx = headers.indexWhere((h) => h == 'agemos');
    final mIdx = headers.indexWhere((h) => h == 'm');
    if (sexIdx < 0 || ageIdx < 0 || mIdx < 0) return const [];

    final rows = <_LmsRow>[];
    for (final line in lines.skip(1)) {
      final cols = line.split(',');
      if (cols.length <= mIdx ||
          cols.length <= ageIdx ||
          cols.length <= sexIdx) {
        continue;
      }
      final sex = int.tryParse(cols[sexIdx].trim());
      final ageMonths = double.tryParse(cols[ageIdx].trim());
      final median = double.tryParse(cols[mIdx].trim());
      if (sex == null || ageMonths == null || median == null) continue;
      rows.add(_LmsRow(sex: sex, ageMonths: ageMonths, median: median));
    }
    return rows;
  }

  Map<int, List<_LmsRow>> _groupRowsBySex(List<_LmsRow> rows) {
    final map = <int, List<_LmsRow>>{};
    for (final row in rows) {
      map.putIfAbsent(row.sex, () => <_LmsRow>[]).add(row);
    }
    return map;
  }

  double? _nearestMedian(List<_LmsRow> rows, int targetMonths) {
    if (rows.isEmpty) return null;
    _LmsRow best = rows.first;
    var bestGap = (best.ageMonths - targetMonths).abs();
    for (final row in rows.skip(1)) {
      final gap = (row.ageMonths - targetMonths).abs();
      if (gap < bestGap) {
        best = row;
        bestGap = gap;
      }
    }
    return best.median;
  }
}

class _LmsRow {
  final int sex;
  final double ageMonths;
  final double median;

  const _LmsRow({
    required this.sex,
    required this.ageMonths,
    required this.median,
  });
}

enum _RemoteResponseType { raw, allOriginsGet }

class _RemoteRequest {
  final String url;
  final _RemoteResponseType type;

  const _RemoteRequest({
    required this.url,
    required this.type,
  });
}

TargetBenchmark benchmarkTarget(int? ageYears, int? soccerYears) {
  final age = ageYears ?? 13;
  // WHO: Children and adolescents (5-17y) should do at least 60 min/day.
  // Source: https://www.who.int/news-room/fact-sheets/detail/physical-activity
  var minutes = age <= 17 ? 420 : 225;
  var sessions = age <= 17 ? 5 : 3;

  final years = soccerYears ?? 1;
  if (years < 1) {
    minutes = (minutes * 0.75).round();
    sessions = sessions > 2 ? sessions - 1 : sessions;
  } else if (years < 3) {
    minutes = (minutes * 0.9).round();
  } else if (years >= 8) {
    minutes = (minutes * 1.05).round();
  }

  return TargetBenchmark(
    weeklyMinutesTarget: minutes,
    weeklySessionsTarget: sessions,
  );
}

PhysicalBenchmark physicalBenchmark(int? ageYears) {
  final age = (ageYears ?? 13).clamp(6, 18);
  final body = _defaultPhysicalByAge()[age] ?? _defaultPhysicalByAge()[13]!;
  final lifts = _defaultLiftingByAge()[age] ?? _defaultLiftingByAge()[13]!;
  return PhysicalBenchmark(
    heightCmAvg: body.heightCmAvg,
    weightKgAvg: body.weightKgAvg,
    liftsPerSessionAvg: lifts,
  );
}

List<BenchmarkSource> benchmarkSources() {
  return const [
    BenchmarkSource(
      title: 'WHO Physical Activity Guidelines (5-17y)',
      url: 'https://www.who.int/news-room/fact-sheets/detail/physical-activity',
    ),
    BenchmarkSource(
      title: 'CDC Height-for-Age (statage.csv)',
      url: 'https://www.cdc.gov/growthcharts/data/zscore/statage.csv',
    ),
    BenchmarkSource(
      title: 'CDC Weight-for-Age (wtage.csv)',
      url: 'https://www.cdc.gov/growthcharts/data/zscore/wtage.csv',
    ),
    BenchmarkSource(
      title: 'Soccer Juggling by Age (reference ranges)',
      url: 'https://www.progressivesoccertraining.com/soccer-juggling-by-age/',
    ),
  ];
}

Map<int, PhysicalBenchmark> _defaultPhysicalByAge() {
  return const {
    6: PhysicalBenchmark(
        heightCmAvg: 117.0, weightKgAvg: 20.9, liftsPerSessionAvg: 0),
    7: PhysicalBenchmark(
        heightCmAvg: 122.5, weightKgAvg: 23.3, liftsPerSessionAvg: 0),
    8: PhysicalBenchmark(
        heightCmAvg: 128.0, weightKgAvg: 26.5, liftsPerSessionAvg: 0),
    9: PhysicalBenchmark(
        heightCmAvg: 133.8, weightKgAvg: 29.7, liftsPerSessionAvg: 0),
    10: PhysicalBenchmark(
        heightCmAvg: 139.7, weightKgAvg: 33.5, liftsPerSessionAvg: 0),
    11: PhysicalBenchmark(
        heightCmAvg: 146.1, weightKgAvg: 38.0, liftsPerSessionAvg: 0),
    12: PhysicalBenchmark(
        heightCmAvg: 153.0, weightKgAvg: 42.9, liftsPerSessionAvg: 0),
    13: PhysicalBenchmark(
        heightCmAvg: 158.3, weightKgAvg: 47.1, liftsPerSessionAvg: 0),
    14: PhysicalBenchmark(
        heightCmAvg: 161.5, weightKgAvg: 50.3, liftsPerSessionAvg: 0),
    15: PhysicalBenchmark(
        heightCmAvg: 163.1, weightKgAvg: 52.4, liftsPerSessionAvg: 0),
    16: PhysicalBenchmark(
        heightCmAvg: 163.8, weightKgAvg: 53.8, liftsPerSessionAvg: 0),
    17: PhysicalBenchmark(
        heightCmAvg: 164.2, weightKgAvg: 54.8, liftsPerSessionAvg: 0),
    18: PhysicalBenchmark(
        heightCmAvg: 164.5, weightKgAvg: 55.5, liftsPerSessionAvg: 0),
  };
}

Map<int, int> _defaultLiftingByAge() {
  return const {
    6: 10,
    7: 10,
    8: 10,
    9: 33,
    10: 33,
    11: 33,
    12: 33,
    13: 100,
    14: 100,
    15: 100,
    16: 100,
    17: 150,
    18: 150,
  };
}
