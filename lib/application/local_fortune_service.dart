import 'package:football_note/gen/app_localizations.dart';
import 'package:intl/intl.dart';

import '../domain/entities/player_profile.dart';
import '../domain/entities/training_entry.dart';
import 'myeongli_database.dart';

class LocalFortuneResult {
  final String fortuneText;
  final String recommendationText;
  final String recommendedProgram;

  const LocalFortuneResult({
    required this.fortuneText,
    required this.recommendationText,
    required this.recommendedProgram,
  });
}

class LocalFortuneService {
  static const MyeongliDatabase _myeongli = MyeongliDatabase.instance;
  static final BigInt totalFortunePoolCount = _calculateTotalFortunePoolCount();

  static String formatFortunePoolCount(String localeName) {
    final groupSeparator = _resolveGroupSeparator(localeName);
    final digits = totalFortunePoolCount.toString();
    final buffer = StringBuffer();
    for (var index = 0; index < digits.length; index++) {
      if (index > 0 && (digits.length - index) % 3 == 0) {
        buffer.write(groupSeparator);
      }
      buffer.write(digits[index]);
    }
    return buffer.toString();
  }

  LocalFortuneResult generateResult({
    required TrainingEntry entry,
    required PlayerProfile profile,
    required List<TrainingEntry> history,
    required AppLocalizations l10n,
  }) {
    final baseSeed = _seed(entry, profile, history);
    final birthReading = _birthReading(profile, l10n);
    final dailyPillar = _myeongli.dayPillar(entry.date);
    final luckyTime = _luckyTime(seed: baseSeed + 71, l10n: l10n);
    final luckyColor = _luckyColor(seed: baseSeed + 73, l10n: l10n);
    final luckyZone = _luckyZone(seed: baseSeed + 79, l10n: l10n);
    final luckyCue = _luckyCue(seed: baseSeed + 83, l10n: l10n);
    final luckyNumber = (baseSeed.abs() % 9) + 1;
    final recommendedProgram = _recommendedProgram(entry: entry, l10n: l10n);
    final recommendationText = _recommendationText(
      entry: entry,
      recommendedProgram: recommendedProgram,
      l10n: l10n,
    );
    final name = _playerName(profile, l10n);
    final fortuneTheme = _pickLocalized(
      l10n.fortuneSajuFortuneThemes,
      baseSeed + birthReading.seed + 89,
    );
    final trainingTone = _pickLocalized(
      l10n.fortuneSajuTrainingTones,
      baseSeed + dailyPillar.stem.index * 31,
    );
    final playAdvice = _pickLocalized(
      l10n.fortuneSajuPlayAdvice,
      baseSeed + birthReading.seed + dailyPillar.branch.index * 43,
    );
    final elementFlow = _pickLocalized(
      l10n.fortuneSajuElementFlows,
      birthReading.elementSeed + dailyPillar.stem.index,
    );
    final nameElement = _pickLocalized(
      l10n.fortuneSajuNameElements,
      _nameSeed(profile) + birthReading.seed,
    );

    final fortuneText = <String>[
      l10n.fortuneGeneratedDailyLineOne(name, elementFlow),
      l10n.fortuneGeneratedDailyLineTwo(fortuneTheme, trainingTone),
      l10n.fortuneGeneratedDailyLineThree(nameElement, playAdvice),
      l10n.fortuneGeneratedLuckyInfoLine(
        luckyNumber,
        luckyColor,
        luckyTime,
        luckyZone,
        luckyCue,
      ),
    ].join('\n');

    return LocalFortuneResult(
      fortuneText: fortuneText,
      recommendationText: recommendationText,
      recommendedProgram: recommendedProgram,
    );
  }

  String generate({
    required TrainingEntry entry,
    required PlayerProfile profile,
    required List<TrainingEntry> history,
    required AppLocalizations l10n,
  }) {
    return generateResult(
      entry: entry,
      profile: profile,
      history: history,
      l10n: l10n,
    ).fortuneText;
  }

  int _seed(
    TrainingEntry entry,
    PlayerProfile profile,
    List<TrainingEntry> history,
  ) {
    final date = DateTime(entry.date.year, entry.date.month, entry.date.day);
    final p = _nameSeed(profile);
    final b = _birthSeed(profile.birthDate);
    final h = history.length * 17;
    final l = entry.liftingByPart.values.fold<int>(0, (a, b) => a + b);
    return date.year * 37 +
        date.month * 101 +
        date.day * 271 +
        entry.intensity * 17 +
        entry.mood * 13 +
        entry.durationMinutes * 3 +
        l * 5 +
        p * 3 +
        b +
        h;
  }

  String _pick(List<String> values, int seed) {
    if (values.isEmpty) return '';
    return values[seed.abs() % values.length];
  }

  String _recommendedProgram({
    required TrainingEntry entry,
    required AppLocalizations l10n,
  }) {
    final liftingTotal = entry.liftingByPart.values.fold<int>(
      0,
      (sum, count) => sum + count,
    );
    if (entry.injury || (entry.painLevel ?? 0) >= 4) {
      return l10n.fortuneRecommendedRecoveryProgram;
    }
    if (liftingTotal >= 80) {
      return l10n.fortuneRecommendedLightFirstTouchProgram;
    }
    if (entry.mood >= 4 && entry.intensity >= 4) {
      return l10n.fortuneRecommendedForwardPassProgram;
    }
    return l10n.fortuneRecommendedCoreTechniqueProgram;
  }

  String _recommendationText({
    required TrainingEntry entry,
    required String recommendedProgram,
    required AppLocalizations l10n,
  }) {
    if (entry.injury || (entry.painLevel ?? 0) >= 4) {
      return l10n.fortuneRecommendationInjury(recommendedProgram);
    }
    if (entry.mood >= 4 && entry.intensity >= 4) {
      return l10n.fortuneRecommendationStrongFlow(recommendedProgram);
    }
    return l10n.fortuneRecommendationDefault(recommendedProgram);
  }

  String _luckyColor({required int seed, required AppLocalizations l10n}) {
    return _composeSegments(
      seed: seed,
      first: _localizedValues(l10n.fortuneLuckyColorTones),
      second: _localizedValues(l10n.fortuneLuckyColorBases),
    );
  }

  String _luckyTime({required int seed, required AppLocalizations l10n}) {
    return _composeSegments(
      seed: seed,
      first: _localizedValues(l10n.fortuneLuckyTimePeriods),
      second: _localizedValues(l10n.fortuneLuckyTimeWindows),
    );
  }

  String _luckyZone({required int seed, required AppLocalizations l10n}) {
    return _composeSegments(
      seed: seed,
      first: _localizedValues(l10n.fortuneLuckyZoneModifiers),
      second: _localizedValues(l10n.fortuneLuckyZoneBases),
    );
  }

  String _luckyCue({required int seed, required AppLocalizations l10n}) {
    return _composeSegments(
      seed: seed,
      first: _localizedValues(l10n.fortuneLuckyCueOpenings),
      second: _localizedValues(l10n.fortuneLuckyCueActions),
    );
  }

  String _composeSegments({
    required int seed,
    required List<String> first,
    required List<String> second,
    List<String>? third,
    String separator = ' ',
  }) {
    final parts = <String>[
      _pick(first, seed + 1),
      _pick(second, seed + 17),
      if (third != null) _pick(third, seed + 31),
    ].where((value) => value.trim().isNotEmpty).toList(growable: false);
    return parts.join(separator).replaceAll(RegExp(r'\s+'), ' ').trim();
  }

  _BirthReading _birthReading(
    PlayerProfile profile,
    AppLocalizations l10n,
  ) {
    final birthDate = profile.birthDate;
    if (birthDate == null) {
      final seed = _nameSeed(profile);
      return _BirthReading(
        frame: l10n.fortuneGeneratedBirthNotSet,
        seed: seed,
        elementSeed: seed,
      );
    }

    final chart = _myeongli.chartForBirth(birthDate);
    final frame = chart.hour == null
        ? l10n.fortuneGeneratedBirthFrame(
            _pillarLabel(chart.year, l10n),
            _pillarLabel(chart.month, l10n),
            _pillarLabel(chart.day, l10n),
          )
        : l10n.fortuneGeneratedBirthFrameWithTime(
            _pillarLabel(chart.year, l10n),
            _pillarLabel(chart.month, l10n),
            _pillarLabel(chart.day, l10n),
            _pillarLabel(chart.hour!, l10n),
          );
    return _BirthReading(
      frame: frame,
      seed: chart.seed,
      elementSeed: chart.elementSeed,
    );
  }

  String _pillarLabel(MyeongliPillar pillar, AppLocalizations l10n) {
    final stems = _localizedValues(l10n.fortuneSajuHeavenlyStems);
    final branches = _localizedValues(l10n.fortuneSajuEarthlyBranches);
    return '${_valueAt(stems, pillar.stem.index)}'
        '${_valueAt(branches, pillar.branch.index)}';
  }

  static String _playerName(PlayerProfile profile, AppLocalizations l10n) {
    final name = profile.name.trim();
    return name.isEmpty ? l10n.fortuneGeneratedUnknownPlayerName : name;
  }

  static int _nameSeed(PlayerProfile profile) {
    return profile.name.trim().runes.fold<int>(0, (a, b) => a + b);
  }

  static int _birthSeed(DateTime? birthDate) {
    if (birthDate == null) return 0;
    return birthDate.year * 11 +
        birthDate.month * 47 +
        birthDate.day * 83 +
        birthDate.hour * 131 +
        birthDate.minute * 151;
  }

  static List<String> _localizedValues(String packed) {
    return packed
        .split('|')
        .map((value) => value.trim())
        .where((value) => value.isNotEmpty)
        .toList(growable: false);
  }

  static String _pickLocalized(String packed, int seed) {
    return _valueAt(_localizedValues(packed), seed);
  }

  static String _valueAt(List<String> values, int index) {
    if (values.isEmpty) return '';
    return values[_positiveMod(index, values.length)];
  }

  static int _positiveMod(int value, int modulo) {
    final result = value % modulo;
    return result < 0 ? result + modulo : result;
  }

  static BigInt _calculateTotalFortunePoolCount() {
    BigInt count(int value) => BigInt.from(value);
    BigInt countSegments(
      int first,
      int second, [
      int? third,
    ]) {
      var total = count(first) * count(second);
      if (third != null) {
        total *= count(third);
      }
      return total;
    }

    final luckyColorCount = countSegments(
      _fortuneLuckyColorToneCount,
      _fortuneLuckyColorBaseCount,
    );
    final luckyTimeCount = countSegments(
      _fortuneLuckyTimePeriodCount,
      _fortuneLuckyTimeWindowCount,
    );
    final luckyZoneCount = countSegments(
      _fortuneLuckyZoneModifierCount,
      _fortuneLuckyZoneBaseCount,
    );
    final luckyCueCount = countSegments(
      _fortuneLuckyCueOpeningCount,
      _fortuneLuckyCueActionCount,
    );
    final sajuReadingCount = countSegments(
      _fortuneSajuElementFlowCount,
      _fortuneSajuThemeCount,
      _fortuneSajuTrainingToneCount,
    );
    final sajuAdviceCount = countSegments(
      _fortuneSajuNameElementCount,
      _fortuneSajuPlayAdviceCount,
    );
    final pillarCount = BigInt.from(_myeongli.pillars.length);
    const luckyNumberCount = 9;

    return pillarCount *
        luckyColorCount *
        luckyTimeCount *
        luckyZoneCount *
        luckyCueCount *
        sajuReadingCount *
        sajuAdviceCount *
        BigInt.from(luckyNumberCount);
  }

  static String _resolveGroupSeparator(String localeName) {
    try {
      return NumberFormat.decimalPattern(localeName).symbols.GROUP_SEP;
    } catch (_) {
      final fallbackLocale = localeName.split(RegExp('[-_]')).first;
      try {
        return NumberFormat.decimalPattern(fallbackLocale).symbols.GROUP_SEP;
      } catch (_) {
        return ',';
      }
    }
  }
}

class _BirthReading {
  final String frame;
  final int seed;
  final int elementSeed;

  const _BirthReading({
    required this.frame,
    required this.seed,
    required this.elementSeed,
  });
}

const int _fortuneLuckyColorToneCount = 16;
const int _fortuneLuckyColorBaseCount = 20;
const int _fortuneLuckyTimePeriodCount = 12;
const int _fortuneLuckyTimeWindowCount = 16;
const int _fortuneLuckyZoneModifierCount = 16;
const int _fortuneLuckyZoneBaseCount = 20;
const int _fortuneLuckyCueOpeningCount = 16;
const int _fortuneLuckyCueActionCount = 24;
const int _fortuneSajuElementFlowCount = 16;
const int _fortuneSajuThemeCount = 24;
const int _fortuneSajuTrainingToneCount = 24;
const int _fortuneSajuNameElementCount = 16;
const int _fortuneSajuPlayAdviceCount = 24;
