enum MyeongliElement { wood, fire, earth, metal, water }

enum MyeongliPolarity { yang, yin }

enum MyeongliTenGod {
  friend,
  robWealth,
  eatingGod,
  hurtingOfficer,
  indirectWealth,
  directWealth,
  sevenKillings,
  directOfficer,
  indirectResource,
  directResource,
}

enum MyeongliTwelveStage {
  longevity,
  bath,
  crownBelt,
  official,
  prosperity,
  decline,
  sickness,
  death,
  tomb,
  extinction,
  embryo,
  nurturing,
}

enum MyeongliBranchRelationType {
  sixCombination,
  clash,
  punishment,
  harm,
  breakRelation,
  threeHarmony,
  directionalHarmony,
}

class MyeongliStem {
  final int index;
  final String id;
  final MyeongliElement element;
  final MyeongliPolarity polarity;

  const MyeongliStem({
    required this.index,
    required this.id,
    required this.element,
    required this.polarity,
  });
}

class MyeongliBranch {
  final int index;
  final String id;
  final MyeongliElement element;
  final MyeongliPolarity polarity;
  final List<int> hiddenStemIndexes;
  final int hourStart;
  final int hourEnd;

  const MyeongliBranch({
    required this.index,
    required this.id,
    required this.element,
    required this.polarity,
    required this.hiddenStemIndexes,
    required this.hourStart,
    required this.hourEnd,
  });
}

class MyeongliBranchRelation {
  final MyeongliBranchRelationType type;
  final List<int> branchIndexes;
  final MyeongliElement? element;

  const MyeongliBranchRelation({
    required this.type,
    required this.branchIndexes,
    this.element,
  });
}

class MyeongliPillar {
  final int index;
  final MyeongliStem stem;
  final MyeongliBranch branch;

  const MyeongliPillar({
    required this.index,
    required this.stem,
    required this.branch,
  });
}

class MyeongliDailySignature {
  final MyeongliPillar dailyPillar;
  final MyeongliTenGod tenGod;
  final MyeongliTwelveStage twelveStage;
  final MyeongliBranchRelation? branchRelation;

  const MyeongliDailySignature({
    required this.dailyPillar,
    required this.tenGod,
    required this.twelveStage,
    this.branchRelation,
  });

  int get seed {
    return dailyPillar.index * 19 +
        tenGod.index * 23 +
        twelveStage.index * 29 +
        (branchRelation?.type.index ?? 0) * 31;
  }
}

class MyeongliChart {
  final MyeongliPillar year;
  final MyeongliPillar month;
  final MyeongliPillar day;
  final MyeongliPillar? hour;

  const MyeongliChart({
    required this.year,
    required this.month,
    required this.day,
    this.hour,
  });

  int get seed {
    return year.index * 7 +
        month.index * 11 +
        day.index * 13 +
        (hour?.index ?? 0) * 17;
  }

  int get elementSeed {
    final pillars = <MyeongliPillar>[
      year,
      month,
      day,
      if (hour != null) hour!,
    ];
    return pillars.fold<int>(
      0,
      (sum, pillar) =>
          sum + pillar.stem.element.index + pillar.branch.element.index,
    );
  }
}

/// Local reference data for Myeongli-based fortune copy.
///
/// Month boundaries use fixed-day solar-term approximations, not a full
/// almanac-grade calendar.
class MyeongliDatabase {
  static const MyeongliDatabase instance = MyeongliDatabase._();

  const MyeongliDatabase._();

  List<MyeongliStem> get stems => _stems;
  List<MyeongliBranch> get branches => _branches;
  List<MyeongliBranchRelation> get branchRelations => _branchRelations;

  List<MyeongliPillar> get pillars => List<MyeongliPillar>.generate(
        60,
        (index) => MyeongliPillar(
          index: index,
          stem: _stems[index % _stems.length],
          branch: _branches[index % _branches.length],
        ),
        growable: false,
      );

  MyeongliStem stemAt(int index) {
    return _stems[_positiveMod(index, _stems.length)];
  }

  MyeongliBranch branchAt(int index) {
    return _branches[_positiveMod(index, _branches.length)];
  }

  MyeongliPillar pillarForIndex(int index) {
    final normalized = _positiveMod(index, 60);
    return MyeongliPillar(
      index: normalized,
      stem: stemAt(normalized),
      branch: branchAt(normalized),
    );
  }

  MyeongliPillar pillarForStemBranch({
    required int stemIndex,
    required int branchIndex,
  }) {
    final stem = stemAt(stemIndex);
    final branch = branchAt(branchIndex);
    return MyeongliPillar(
      index: _positiveMod(stem.index * 6 - branch.index * 5, 60),
      stem: stem,
      branch: branch,
    );
  }

  MyeongliChart chartForBirth(DateTime birthDate) {
    final year = yearPillar(birthDate);
    final month = monthPillar(birthDate, yearStemIndex: year.stem.index);
    final day = dayPillar(birthDate);
    final hour = hasBirthTime(birthDate)
        ? hourPillar(birthDate, dayStemIndex: day.stem.index)
        : null;
    return MyeongliChart(year: year, month: month, day: day, hour: hour);
  }

  MyeongliDailySignature dailySignature({
    required MyeongliChart birthChart,
    required DateTime date,
  }) {
    final dailyPillar = dayPillar(date);
    return MyeongliDailySignature(
      dailyPillar: dailyPillar,
      tenGod: tenGodFor(
        dayStem: birthChart.day.stem,
        targetStem: dailyPillar.stem,
      ),
      twelveStage: twelveStageFor(
        dayStem: birthChart.day.stem,
        targetBranch: dailyPillar.branch,
      ),
      branchRelation: firstBranchRelationFor(
        birthChart: birthChart,
        targetBranch: dailyPillar.branch,
      ),
    );
  }

  MyeongliPillar yearPillar(DateTime date) {
    final pillarYear = date.month == 1 || (date.month == 2 && date.day < 4)
        ? date.year - 1
        : date.year;
    return pillarForIndex(pillarYear - 4);
  }

  MyeongliPillar monthPillar(
    DateTime date, {
    required int yearStemIndex,
  }) {
    final branchIndex = monthBranchIndex(date);
    final firstMonthStem = switch (_positiveMod(yearStemIndex, 10)) {
      0 || 5 => 2,
      1 || 6 => 4,
      2 || 7 => 6,
      3 || 8 => 8,
      _ => 0,
    };
    final stemIndex = _positiveMod(firstMonthStem + branchIndex - 2, 10);
    return pillarForStemBranch(
      stemIndex: stemIndex,
      branchIndex: branchIndex,
    );
  }

  int monthBranchIndex(DateTime date) {
    var branchIndex = 1;
    for (final rule in _solarMonthStartRules) {
      if (_isOnOrAfter(date, month: rule.month, day: rule.day)) {
        branchIndex = rule.branchIndex;
      }
    }
    return branchIndex;
  }

  MyeongliPillar dayPillar(DateTime date) {
    final day = DateTime(date.year, date.month, date.day);
    final days = day.difference(DateTime(1984, 2, 2)).inDays;
    return pillarForIndex(days);
  }

  MyeongliPillar hourPillar(
    DateTime date, {
    required int dayStemIndex,
  }) {
    final branchIndex = ((date.hour + 1) ~/ 2) % 12;
    final firstHourStem = switch (_positiveMod(dayStemIndex, 10)) {
      0 || 5 => 0,
      1 || 6 => 2,
      2 || 7 => 4,
      3 || 8 => 6,
      _ => 8,
    };
    final stemIndex = _positiveMod(firstHourStem + branchIndex, 10);
    return pillarForStemBranch(
      stemIndex: stemIndex,
      branchIndex: branchIndex,
    );
  }

  bool hasBirthTime(DateTime date) {
    return date.hour != 0 ||
        date.minute != 0 ||
        date.second != 0 ||
        date.millisecond != 0 ||
        date.microsecond != 0;
  }

  MyeongliElement generatedElement(MyeongliElement element) {
    return switch (element) {
      MyeongliElement.wood => MyeongliElement.fire,
      MyeongliElement.fire => MyeongliElement.earth,
      MyeongliElement.earth => MyeongliElement.metal,
      MyeongliElement.metal => MyeongliElement.water,
      MyeongliElement.water => MyeongliElement.wood,
    };
  }

  MyeongliElement controlledElement(MyeongliElement element) {
    return switch (element) {
      MyeongliElement.wood => MyeongliElement.earth,
      MyeongliElement.fire => MyeongliElement.metal,
      MyeongliElement.earth => MyeongliElement.water,
      MyeongliElement.metal => MyeongliElement.wood,
      MyeongliElement.water => MyeongliElement.fire,
    };
  }

  MyeongliTenGod tenGodFor({
    required MyeongliStem dayStem,
    required MyeongliStem targetStem,
  }) {
    final samePolarity = dayStem.polarity == targetStem.polarity;
    if (dayStem.element == targetStem.element) {
      return samePolarity ? MyeongliTenGod.friend : MyeongliTenGod.robWealth;
    }
    if (generatedElement(dayStem.element) == targetStem.element) {
      return samePolarity
          ? MyeongliTenGod.eatingGod
          : MyeongliTenGod.hurtingOfficer;
    }
    if (controlledElement(dayStem.element) == targetStem.element) {
      return samePolarity
          ? MyeongliTenGod.indirectWealth
          : MyeongliTenGod.directWealth;
    }
    if (controlledElement(targetStem.element) == dayStem.element) {
      return samePolarity
          ? MyeongliTenGod.sevenKillings
          : MyeongliTenGod.directOfficer;
    }
    return samePolarity
        ? MyeongliTenGod.indirectResource
        : MyeongliTenGod.directResource;
  }

  MyeongliTwelveStage twelveStageFor({
    required MyeongliStem dayStem,
    required MyeongliBranch targetBranch,
  }) {
    final rule = _twelveStageRules[stemAt(dayStem.index).index];
    final distance = rule.forward
        ? _positiveMod(targetBranch.index - rule.startBranchIndex, 12)
        : _positiveMod(rule.startBranchIndex - targetBranch.index, 12);
    return MyeongliTwelveStage.values[distance];
  }

  MyeongliBranchRelation? firstBranchRelationFor({
    required MyeongliChart birthChart,
    required MyeongliBranch targetBranch,
  }) {
    final sourceBranches = <MyeongliBranch>[
      birthChart.year.branch,
      birthChart.month.branch,
      birthChart.day.branch,
      if (birthChart.hour != null) birthChart.hour!.branch,
    ];
    final matches = branchRelationsFor(
      sourceBranches: sourceBranches,
      targetBranch: targetBranch,
    );
    return matches.isEmpty ? null : matches.first;
  }

  List<MyeongliBranchRelation> branchRelationsFor({
    required List<MyeongliBranch> sourceBranches,
    required MyeongliBranch targetBranch,
  }) {
    return _branchRelations.where((relation) {
      if (!relation.branchIndexes.contains(targetBranch.index)) {
        return false;
      }
      return sourceBranches.any((branch) {
        return branch.index != targetBranch.index &&
            relation.branchIndexes.contains(branch.index);
      });
    }).toList(growable: false);
  }

  bool _isOnOrAfter(DateTime date, {required int month, required int day}) {
    return date.month > month || (date.month == month && date.day >= day);
  }

  static int _positiveMod(int value, int modulo) {
    final result = value % modulo;
    return result < 0 ? result + modulo : result;
  }
}

class _TwelveStageRule {
  final int startBranchIndex;
  final bool forward;

  const _TwelveStageRule({
    required this.startBranchIndex,
    required this.forward,
  });
}

class _SolarMonthStartRule {
  final int month;
  final int day;
  final int branchIndex;

  const _SolarMonthStartRule({
    required this.month,
    required this.day,
    required this.branchIndex,
  });
}

const List<MyeongliStem> _stems = <MyeongliStem>[
  MyeongliStem(
    index: 0,
    id: 'gap',
    element: MyeongliElement.wood,
    polarity: MyeongliPolarity.yang,
  ),
  MyeongliStem(
    index: 1,
    id: 'eul',
    element: MyeongliElement.wood,
    polarity: MyeongliPolarity.yin,
  ),
  MyeongliStem(
    index: 2,
    id: 'byeong',
    element: MyeongliElement.fire,
    polarity: MyeongliPolarity.yang,
  ),
  MyeongliStem(
    index: 3,
    id: 'jeong',
    element: MyeongliElement.fire,
    polarity: MyeongliPolarity.yin,
  ),
  MyeongliStem(
    index: 4,
    id: 'mu',
    element: MyeongliElement.earth,
    polarity: MyeongliPolarity.yang,
  ),
  MyeongliStem(
    index: 5,
    id: 'gi',
    element: MyeongliElement.earth,
    polarity: MyeongliPolarity.yin,
  ),
  MyeongliStem(
    index: 6,
    id: 'gyeong',
    element: MyeongliElement.metal,
    polarity: MyeongliPolarity.yang,
  ),
  MyeongliStem(
    index: 7,
    id: 'sin',
    element: MyeongliElement.metal,
    polarity: MyeongliPolarity.yin,
  ),
  MyeongliStem(
    index: 8,
    id: 'im',
    element: MyeongliElement.water,
    polarity: MyeongliPolarity.yang,
  ),
  MyeongliStem(
    index: 9,
    id: 'gye',
    element: MyeongliElement.water,
    polarity: MyeongliPolarity.yin,
  ),
];

const List<MyeongliBranch> _branches = <MyeongliBranch>[
  MyeongliBranch(
    index: 0,
    id: 'ja',
    element: MyeongliElement.water,
    polarity: MyeongliPolarity.yang,
    hiddenStemIndexes: <int>[9],
    hourStart: 23,
    hourEnd: 1,
  ),
  MyeongliBranch(
    index: 1,
    id: 'chuk',
    element: MyeongliElement.earth,
    polarity: MyeongliPolarity.yin,
    hiddenStemIndexes: <int>[5, 9, 7],
    hourStart: 1,
    hourEnd: 3,
  ),
  MyeongliBranch(
    index: 2,
    id: 'in',
    element: MyeongliElement.wood,
    polarity: MyeongliPolarity.yang,
    hiddenStemIndexes: <int>[0, 2, 4],
    hourStart: 3,
    hourEnd: 5,
  ),
  MyeongliBranch(
    index: 3,
    id: 'myo',
    element: MyeongliElement.wood,
    polarity: MyeongliPolarity.yin,
    hiddenStemIndexes: <int>[1],
    hourStart: 5,
    hourEnd: 7,
  ),
  MyeongliBranch(
    index: 4,
    id: 'jin',
    element: MyeongliElement.earth,
    polarity: MyeongliPolarity.yang,
    hiddenStemIndexes: <int>[4, 1, 9],
    hourStart: 7,
    hourEnd: 9,
  ),
  MyeongliBranch(
    index: 5,
    id: 'sa',
    element: MyeongliElement.fire,
    polarity: MyeongliPolarity.yin,
    hiddenStemIndexes: <int>[2, 4, 6],
    hourStart: 9,
    hourEnd: 11,
  ),
  MyeongliBranch(
    index: 6,
    id: 'o',
    element: MyeongliElement.fire,
    polarity: MyeongliPolarity.yang,
    hiddenStemIndexes: <int>[3, 5],
    hourStart: 11,
    hourEnd: 13,
  ),
  MyeongliBranch(
    index: 7,
    id: 'mi',
    element: MyeongliElement.earth,
    polarity: MyeongliPolarity.yin,
    hiddenStemIndexes: <int>[5, 3, 1],
    hourStart: 13,
    hourEnd: 15,
  ),
  MyeongliBranch(
    index: 8,
    id: 'sin',
    element: MyeongliElement.metal,
    polarity: MyeongliPolarity.yang,
    hiddenStemIndexes: <int>[6, 8, 4],
    hourStart: 15,
    hourEnd: 17,
  ),
  MyeongliBranch(
    index: 9,
    id: 'yu',
    element: MyeongliElement.metal,
    polarity: MyeongliPolarity.yin,
    hiddenStemIndexes: <int>[7],
    hourStart: 17,
    hourEnd: 19,
  ),
  MyeongliBranch(
    index: 10,
    id: 'sul',
    element: MyeongliElement.earth,
    polarity: MyeongliPolarity.yang,
    hiddenStemIndexes: <int>[4, 7, 3],
    hourStart: 19,
    hourEnd: 21,
  ),
  MyeongliBranch(
    index: 11,
    id: 'hae',
    element: MyeongliElement.water,
    polarity: MyeongliPolarity.yin,
    hiddenStemIndexes: <int>[8, 0],
    hourStart: 21,
    hourEnd: 23,
  ),
];

const List<_TwelveStageRule> _twelveStageRules = <_TwelveStageRule>[
  _TwelveStageRule(startBranchIndex: 11, forward: true),
  _TwelveStageRule(startBranchIndex: 6, forward: false),
  _TwelveStageRule(startBranchIndex: 2, forward: true),
  _TwelveStageRule(startBranchIndex: 9, forward: false),
  _TwelveStageRule(startBranchIndex: 2, forward: true),
  _TwelveStageRule(startBranchIndex: 9, forward: false),
  _TwelveStageRule(startBranchIndex: 5, forward: true),
  _TwelveStageRule(startBranchIndex: 0, forward: false),
  _TwelveStageRule(startBranchIndex: 8, forward: true),
  _TwelveStageRule(startBranchIndex: 3, forward: false),
];

const List<MyeongliBranchRelation> _branchRelations = <MyeongliBranchRelation>[
  MyeongliBranchRelation(
    type: MyeongliBranchRelationType.clash,
    branchIndexes: <int>[0, 6],
  ),
  MyeongliBranchRelation(
    type: MyeongliBranchRelationType.clash,
    branchIndexes: <int>[1, 7],
  ),
  MyeongliBranchRelation(
    type: MyeongliBranchRelationType.clash,
    branchIndexes: <int>[2, 8],
  ),
  MyeongliBranchRelation(
    type: MyeongliBranchRelationType.clash,
    branchIndexes: <int>[3, 9],
  ),
  MyeongliBranchRelation(
    type: MyeongliBranchRelationType.clash,
    branchIndexes: <int>[4, 10],
  ),
  MyeongliBranchRelation(
    type: MyeongliBranchRelationType.clash,
    branchIndexes: <int>[5, 11],
  ),
  MyeongliBranchRelation(
    type: MyeongliBranchRelationType.sixCombination,
    branchIndexes: <int>[0, 1],
    element: MyeongliElement.earth,
  ),
  MyeongliBranchRelation(
    type: MyeongliBranchRelationType.sixCombination,
    branchIndexes: <int>[2, 11],
    element: MyeongliElement.wood,
  ),
  MyeongliBranchRelation(
    type: MyeongliBranchRelationType.sixCombination,
    branchIndexes: <int>[3, 10],
    element: MyeongliElement.fire,
  ),
  MyeongliBranchRelation(
    type: MyeongliBranchRelationType.sixCombination,
    branchIndexes: <int>[4, 9],
    element: MyeongliElement.metal,
  ),
  MyeongliBranchRelation(
    type: MyeongliBranchRelationType.sixCombination,
    branchIndexes: <int>[5, 8],
    element: MyeongliElement.water,
  ),
  MyeongliBranchRelation(
    type: MyeongliBranchRelationType.sixCombination,
    branchIndexes: <int>[6, 7],
    element: MyeongliElement.earth,
  ),
  MyeongliBranchRelation(
    type: MyeongliBranchRelationType.punishment,
    branchIndexes: <int>[2, 5, 8],
  ),
  MyeongliBranchRelation(
    type: MyeongliBranchRelationType.punishment,
    branchIndexes: <int>[1, 7, 10],
  ),
  MyeongliBranchRelation(
    type: MyeongliBranchRelationType.punishment,
    branchIndexes: <int>[0, 3],
  ),
  MyeongliBranchRelation(
    type: MyeongliBranchRelationType.harm,
    branchIndexes: <int>[0, 7],
  ),
  MyeongliBranchRelation(
    type: MyeongliBranchRelationType.harm,
    branchIndexes: <int>[1, 6],
  ),
  MyeongliBranchRelation(
    type: MyeongliBranchRelationType.harm,
    branchIndexes: <int>[2, 5],
  ),
  MyeongliBranchRelation(
    type: MyeongliBranchRelationType.harm,
    branchIndexes: <int>[3, 4],
  ),
  MyeongliBranchRelation(
    type: MyeongliBranchRelationType.harm,
    branchIndexes: <int>[8, 11],
  ),
  MyeongliBranchRelation(
    type: MyeongliBranchRelationType.harm,
    branchIndexes: <int>[9, 10],
  ),
  MyeongliBranchRelation(
    type: MyeongliBranchRelationType.breakRelation,
    branchIndexes: <int>[0, 9],
  ),
  MyeongliBranchRelation(
    type: MyeongliBranchRelationType.breakRelation,
    branchIndexes: <int>[1, 4],
  ),
  MyeongliBranchRelation(
    type: MyeongliBranchRelationType.breakRelation,
    branchIndexes: <int>[2, 11],
  ),
  MyeongliBranchRelation(
    type: MyeongliBranchRelationType.breakRelation,
    branchIndexes: <int>[3, 6],
  ),
  MyeongliBranchRelation(
    type: MyeongliBranchRelationType.breakRelation,
    branchIndexes: <int>[5, 8],
  ),
  MyeongliBranchRelation(
    type: MyeongliBranchRelationType.breakRelation,
    branchIndexes: <int>[7, 10],
  ),
  MyeongliBranchRelation(
    type: MyeongliBranchRelationType.threeHarmony,
    branchIndexes: <int>[8, 0, 4],
    element: MyeongliElement.water,
  ),
  MyeongliBranchRelation(
    type: MyeongliBranchRelationType.threeHarmony,
    branchIndexes: <int>[11, 3, 7],
    element: MyeongliElement.wood,
  ),
  MyeongliBranchRelation(
    type: MyeongliBranchRelationType.threeHarmony,
    branchIndexes: <int>[2, 6, 10],
    element: MyeongliElement.fire,
  ),
  MyeongliBranchRelation(
    type: MyeongliBranchRelationType.threeHarmony,
    branchIndexes: <int>[5, 9, 1],
    element: MyeongliElement.metal,
  ),
  MyeongliBranchRelation(
    type: MyeongliBranchRelationType.directionalHarmony,
    branchIndexes: <int>[11, 0, 1],
    element: MyeongliElement.water,
  ),
  MyeongliBranchRelation(
    type: MyeongliBranchRelationType.directionalHarmony,
    branchIndexes: <int>[2, 3, 4],
    element: MyeongliElement.wood,
  ),
  MyeongliBranchRelation(
    type: MyeongliBranchRelationType.directionalHarmony,
    branchIndexes: <int>[5, 6, 7],
    element: MyeongliElement.fire,
  ),
  MyeongliBranchRelation(
    type: MyeongliBranchRelationType.directionalHarmony,
    branchIndexes: <int>[8, 9, 10],
    element: MyeongliElement.metal,
  ),
];

const List<_SolarMonthStartRule> _solarMonthStartRules = <_SolarMonthStartRule>[
  _SolarMonthStartRule(month: 2, day: 4, branchIndex: 2),
  _SolarMonthStartRule(month: 3, day: 6, branchIndex: 3),
  _SolarMonthStartRule(month: 4, day: 5, branchIndex: 4),
  _SolarMonthStartRule(month: 5, day: 6, branchIndex: 5),
  _SolarMonthStartRule(month: 6, day: 6, branchIndex: 6),
  _SolarMonthStartRule(month: 7, day: 7, branchIndex: 7),
  _SolarMonthStartRule(month: 8, day: 8, branchIndex: 8),
  _SolarMonthStartRule(month: 9, day: 8, branchIndex: 9),
  _SolarMonthStartRule(month: 10, day: 8, branchIndex: 10),
  _SolarMonthStartRule(month: 11, day: 7, branchIndex: 11),
  _SolarMonthStartRule(month: 12, day: 7, branchIndex: 0),
];
