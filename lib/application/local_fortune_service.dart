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

class FortuneDatabaseSection {
  final String title;
  final List<String> values;

  const FortuneDatabaseSection({
    required this.title,
    required this.values,
  });
}

class LocalFortuneService {
  static const MyeongliDatabase _myeongli = MyeongliDatabase.instance;
  static final BigInt totalFortunePoolCount = _calculateTotalFortunePoolCount();

  static List<FortuneDatabaseSection> databaseSections(
    AppLocalizations l10n,
  ) {
    return <FortuneDatabaseSection>[
      FortuneDatabaseSection(
        title: l10n.fortuneDatabaseSectionBirthCodes,
        values: <String>[
          ..._localizedValues(l10n.fortuneSajuHeavenlyStems),
          ..._localizedValues(l10n.fortuneSajuEarthlyBranches),
        ],
      ),
      FortuneDatabaseSection(
        title: l10n.fortuneDatabaseSectionHiddenStems,
        values: _localizedValues(l10n.fortuneMyeongliHiddenStemLabels),
      ),
      FortuneDatabaseSection(
        title: l10n.fortuneDatabaseSectionTenGods,
        values: _localizedValues(l10n.fortuneMyeongliTenGodLabels),
      ),
      FortuneDatabaseSection(
        title: l10n.fortuneDatabaseSectionTwelveStages,
        values: _localizedValues(l10n.fortuneMyeongliTwelveStageLabels),
      ),
      FortuneDatabaseSection(
        title: l10n.fortuneDatabaseSectionBranchRelations,
        values: _localizedValues(l10n.fortuneMyeongliBranchRelationLabels),
      ),
      FortuneDatabaseSection(
        title: l10n.fortuneDatabaseSectionSymbolicStars,
        values: _localizedValues(l10n.fortuneMyeongliSymbolicStarLabels),
      ),
      FortuneDatabaseSection(
        title: l10n.fortuneDatabaseSectionElementColors,
        values: _localizedValues(l10n.fortuneMyeongliElementColorLabels),
      ),
      FortuneDatabaseSection(
        title: l10n.fortuneDatabaseSectionDayMoods,
        values: _combinedLocalizedValues(
          l10n.fortuneSajuElementFlows,
          l10n.fortuneSajuElementFlowExtras,
        ),
      ),
      FortuneDatabaseSection(
        title: l10n.fortuneDatabaseSectionDailyEvents,
        values: _combinedLocalizedValues(
          l10n.fortuneSajuFortuneThemes,
          l10n.fortuneSajuFortuneThemeExtras,
        ),
      ),
      FortuneDatabaseSection(
        title: l10n.fortuneDatabaseSectionDailyOutcomes,
        values: _dailyOutcomeSentences(l10n),
      ),
      FortuneDatabaseSection(
        title: l10n.fortuneDatabaseSectionActionCues,
        values: _combinedLocalizedValues(
          l10n.fortuneSajuTrainingTones,
          l10n.fortuneSajuTrainingToneExtras,
        ),
      ),
      FortuneDatabaseSection(
        title: l10n.fortuneDatabaseSectionNameRhythms,
        values: _combinedLocalizedValues(
          l10n.fortuneSajuNameElements,
          l10n.fortuneSajuNameElementExtras,
        ),
      ),
      FortuneDatabaseSection(
        title: l10n.fortuneDatabaseSectionAdvice,
        values: _combinedLocalizedValues(
          l10n.fortuneSajuPlayAdvice,
          l10n.fortuneSajuPlayAdviceExtras,
        ),
      ),
      FortuneDatabaseSection(
        title: l10n.fortuneDatabaseSectionColorTones,
        values: _combinedLocalizedValues(
          l10n.fortuneLuckyColorTones,
          l10n.fortuneLuckyColorToneExtras,
        ),
      ),
      FortuneDatabaseSection(
        title: l10n.fortuneDatabaseSectionColorBases,
        values: _combinedLocalizedValues(
          l10n.fortuneLuckyColorBases,
          l10n.fortuneLuckyColorBaseExtras,
        ),
      ),
      FortuneDatabaseSection(
        title: l10n.fortuneDatabaseSectionTimePeriods,
        values: _combinedLocalizedValues(
          l10n.fortuneLuckyTimePeriods,
          l10n.fortuneLuckyTimePeriodExtras,
        ),
      ),
      FortuneDatabaseSection(
        title: l10n.fortuneDatabaseSectionTimeWindows,
        values: _combinedLocalizedValues(
          l10n.fortuneLuckyTimeWindows,
          l10n.fortuneLuckyTimeWindowExtras,
        ),
      ),
      FortuneDatabaseSection(
        title: l10n.fortuneDatabaseSectionSceneModifiers,
        values: _combinedLocalizedValues(
          l10n.fortuneLuckyZoneModifiers,
          l10n.fortuneLuckyZoneModifierExtras,
        ),
      ),
      FortuneDatabaseSection(
        title: l10n.fortuneDatabaseSectionSceneBases,
        values: _combinedLocalizedValues(
          l10n.fortuneLuckyZoneBases,
          l10n.fortuneLuckyZoneBaseExtras,
        ),
      ),
      FortuneDatabaseSection(
        title: l10n.fortuneDatabaseSectionCueOpenings,
        values: _combinedLocalizedValues(
          l10n.fortuneLuckyCueOpenings,
          l10n.fortuneLuckyCueOpeningExtras,
        ),
      ),
      FortuneDatabaseSection(
        title: l10n.fortuneDatabaseSectionCueActions,
        values: _combinedLocalizedValues(
          l10n.fortuneLuckyCueActions,
          l10n.fortuneLuckyCueActionExtras,
        ),
      ),
    ];
  }

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
    final dailySignature = birthReading.chart == null
        ? null
        : _myeongli.dailySignature(
            birthChart: birthReading.chart!,
            date: entry.date,
          );
    final dailyPillar =
        dailySignature?.dailyPillar ?? _myeongli.dayPillar(entry.date);
    final luckyElement = dailyPillar.stem.element;
    final luckyColor = _luckyColor(
      seed: baseSeed + 73,
      element: luckyElement,
      l10n: l10n,
    );
    final luckyNumber = _luckyNumber(seed: baseSeed, element: luckyElement);
    final recommendedProgram = _recommendedProgram(entry: entry, l10n: l10n);
    final recommendationText = _recommendationText(
      entry: entry,
      recommendedProgram: recommendedProgram,
      l10n: l10n,
    );
    final name = _playerName(profile, l10n);
    final dailyFortune = _dailyFortuneSentence(
      signature: dailySignature,
      seed: baseSeed +
          birthReading.elementSeed +
          dailyPillar.stem.index * 37 +
          dailyPillar.branch.index * 43,
      l10n: l10n,
    );
    final nameRhythm = _nameRhythm(
      seed: baseSeed + birthReading.elementSeed,
      l10n: l10n,
    );
    final actionCue = _actionCue(
      seed: baseSeed + (dailySignature?.seed ?? dailyPillar.index),
      l10n: l10n,
    );

    final fortuneText = <String>[
      l10n.fortuneGeneratedDailyLineOne(name, dailyFortune),
      l10n.fortuneGeneratedDailyLineThree(nameRhythm, actionCue),
      l10n.fortuneGeneratedLuckyInfoLine(luckyNumber, luckyColor),
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
    final date = entry.date;
    final createdAtSeed = entry.createdAt.millisecondsSinceEpoch.remainder(
      1000003,
    );
    final recordTextSeed = _textSeed(entry.type) * 7 +
        _textSeed(entry.program) * 11 +
        _textSeed(entry.location) * 13 +
        _textSeed(entry.notes) * 17;
    final p = _nameSeed(profile);
    final b = _birthSeed(profile.birthDate);
    final h = history.length * 17;
    final l = entry.liftingByPart.values.fold<int>(0, (a, b) => a + b);
    return date.year * 37 +
        date.month * 101 +
        date.day * 271 +
        date.hour * 389 +
        date.minute * 397 +
        entry.intensity * 17 +
        entry.mood * 13 +
        entry.durationMinutes * 3 +
        createdAtSeed * 19 +
        recordTextSeed +
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

  String _luckyColor({
    required int seed,
    required MyeongliElement element,
    required AppLocalizations l10n,
  }) {
    final elementColorSets = _localizedValues(
      l10n.fortuneMyeongliElementColorValues,
    );
    final elementColors = _splitElementColorSet(
      _valueAt(elementColorSets, element.index),
    );
    if (elementColors.isNotEmpty) {
      return _composeSegments(
        seed: seed,
        first: _combinedLocalizedValues(
          l10n.fortuneLuckyColorTones,
          l10n.fortuneLuckyColorToneExtras,
        ),
        second: elementColors,
      );
    }
    return _composeSegments(
      seed: seed,
      first: _combinedLocalizedValues(
        l10n.fortuneLuckyColorTones,
        l10n.fortuneLuckyColorToneExtras,
      ),
      second: _combinedLocalizedValues(
        l10n.fortuneLuckyColorBases,
        l10n.fortuneLuckyColorBaseExtras,
      ),
    );
  }

  int _luckyNumber({
    required int seed,
    required MyeongliElement element,
  }) {
    const elementNumbers = <List<int>>[
      <int>[3, 8],
      <int>[2, 7],
      <int>[5],
      <int>[4, 9],
      <int>[1, 6],
    ];
    final numbers = elementNumbers[element.index];
    return numbers[seed.abs() % numbers.length];
  }

  String _dailyFortuneSentence({
    required MyeongliDailySignature? signature,
    required int seed,
    required AppLocalizations l10n,
  }) {
    final candidates = _dailyOutcomeSentences(l10n);
    return _valueAt(candidates, seed + (signature?.seed ?? 0));
  }

  String _nameRhythm({
    required int seed,
    required AppLocalizations l10n,
  }) {
    return _valueAt(
      _combinedLocalizedValues(
        l10n.fortuneSajuNameElements,
        l10n.fortuneSajuNameElementExtras,
      ),
      seed,
    );
  }

  String _actionCue({
    required int seed,
    required AppLocalizations l10n,
  }) {
    return _valueAt(
      _combinedLocalizedValues(
        l10n.fortuneLuckyCueActions,
        l10n.fortuneLuckyCueActionExtras,
      ),
      seed,
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
      chart: chart,
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
    return _textSeed(profile.name);
  }

  static int _textSeed(String text) {
    return text.trim().runes.fold<int>(0, (a, b) => a + b);
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

  static List<String> _splitElementColorSet(String packed) {
    return packed
        .split('/')
        .map((value) => value.trim())
        .where((value) => value.isNotEmpty)
        .toList(growable: false);
  }

  static List<String> _combinedLocalizedValues(String base, String extra) {
    return <String>[
      ..._localizedValues(base),
      ..._localizedValues(extra),
    ];
  }

  static List<String> _dailyOutcomeSentences(AppLocalizations l10n) {
    final times = _localizedValues(l10n.fortuneDailyOutcomeTimes);
    final subjects = _localizedValues(l10n.fortuneDailyOutcomeSubjects);
    final results = _localizedValues(l10n.fortuneDailyOutcomeResults);

    return <String>[
      for (final time in times)
        for (final subject in subjects)
          for (final result in results)
            _joinSegments(<String>[time, subject, result]),
    ];
  }

  static String _joinSegments(List<String> values) {
    return values
        .where((value) => value.trim().isNotEmpty)
        .join(' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
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
    final dailyOutcomeCount = countSegments(
      _fortuneDailyOutcomeTimeCount,
      _fortuneDailyOutcomeSubjectCount,
      _fortuneDailyOutcomeResultCount,
    );
    final myeongliSignatureCount = countSegments(
      _fortuneMyeongliTenGodCount,
      _fortuneMyeongliTwelveStageCount,
      _fortuneMyeongliBranchRelationTypeCount,
    );
    final pillarCount = BigInt.from(_myeongli.pillars.length);
    const luckyNumberCount = 9;

    return pillarCount *
        myeongliSignatureCount *
        luckyColorCount *
        luckyTimeCount *
        luckyZoneCount *
        luckyCueCount *
        sajuReadingCount *
        sajuAdviceCount *
        dailyOutcomeCount *
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
  final MyeongliChart? chart;

  const _BirthReading({
    required this.frame,
    required this.seed,
    required this.elementSeed,
    this.chart,
  });
}

const int _fortuneMyeongliTenGodCount = 10;
const int _fortuneMyeongliTwelveStageCount = 12;
const int _fortuneMyeongliBranchRelationTypeCount = 7;
const int _fortuneLuckyColorToneCount = 40;
const int _fortuneLuckyColorBaseCount = 48;
const int _fortuneLuckyTimePeriodCount = 32;
const int _fortuneLuckyTimeWindowCount = 48;
const int _fortuneLuckyZoneModifierCount = 40;
const int _fortuneLuckyZoneBaseCount = 48;
const int _fortuneLuckyCueOpeningCount = 40;
const int _fortuneLuckyCueActionCount = 64;
const int _fortuneSajuElementFlowCount = 60;
const int _fortuneSajuThemeCount = 96;
const int _fortuneSajuTrainingToneCount = 72;
const int _fortuneSajuNameElementCount = 60;
const int _fortuneSajuPlayAdviceCount = 96;
const int _fortuneDailyOutcomeTimeCount = 10;
const int _fortuneDailyOutcomeSubjectCount = 10;
const int _fortuneDailyOutcomeResultCount = 10;
