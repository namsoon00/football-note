import 'package:flutter_test/flutter_test.dart';
import 'package:football_note/application/myeongli_database.dart';

void main() {
  group('MyeongliDatabase', () {
    const db = MyeongliDatabase.instance;

    test('stores core heavenly stem and earthly branch data', () {
      expect(db.stems, hasLength(10));
      expect(db.branches, hasLength(12));
      expect(db.pillars, hasLength(60));

      expect(db.stemAt(0).id, 'gap');
      expect(db.stemAt(0).element, MyeongliElement.wood);
      expect(db.stemAt(0).polarity, MyeongliPolarity.yang);
      expect(db.stemAt(9).id, 'gye');
      expect(db.stemAt(9).element, MyeongliElement.water);
      expect(db.stemAt(9).polarity, MyeongliPolarity.yin);

      expect(db.branchAt(0).id, 'ja');
      expect(db.branchAt(0).element, MyeongliElement.water);
      expect(db.branchAt(0).hiddenStemIndexes, const <int>[9]);
      expect(db.branchAt(4).id, 'jin');
      expect(db.branchAt(4).hiddenStemIndexes, const <int>[4, 1, 9]);
    });

    test('looks up the sixty pillar cycle by stem and branch', () {
      final gapJa = db.pillarForIndex(0);
      expect(gapJa.index, 0);
      expect(gapJa.stem.id, 'gap');
      expect(gapJa.branch.id, 'ja');

      final imJin = db.pillarForStemBranch(stemIndex: 8, branchIndex: 4);
      expect(imJin.index, 28);
      expect(imJin.stem.id, 'im');
      expect(imJin.branch.id, 'jin');

      final gapIn = db.pillarForStemBranch(stemIndex: 0, branchIndex: 2);
      expect(gapIn.index, 50);
      expect(gapIn.stem.id, 'gap');
      expect(gapIn.branch.id, 'in');
    });

    test('builds birth chart pillars from birth date and time', () {
      final chart = db.chartForBirth(DateTime(2012, 3, 10, 7, 30));

      expect(chart.year.stem.id, 'im');
      expect(chart.year.branch.id, 'jin');
      expect(chart.month.branch.id, 'myo');
      expect(chart.day.index, db.dayPillar(DateTime(2012, 3, 10)).index);
      expect(chart.hour, isNotNull);
      expect(chart.hour!.branch.id, 'jin');
    });

    test('uses solar month boundaries for month branch approximation', () {
      expect(db.monthBranchIndex(DateTime(2026, 3, 5)), 2);
      expect(db.monthBranchIndex(DateTime(2026, 3, 6)), 3);
      expect(db.monthBranchIndex(DateTime(2026, 12, 7)), 0);
      expect(db.monthBranchIndex(DateTime(2026, 1, 20)), 1);
    });

    test('derives ten-god relationships from the day stem', () {
      final dayStem = db.stemAt(0);

      expect(
        db.tenGodFor(dayStem: dayStem, targetStem: db.stemAt(0)),
        MyeongliTenGod.friend,
      );
      expect(
        db.tenGodFor(dayStem: dayStem, targetStem: db.stemAt(1)),
        MyeongliTenGod.robWealth,
      );
      expect(
        db.tenGodFor(dayStem: dayStem, targetStem: db.stemAt(2)),
        MyeongliTenGod.eatingGod,
      );
      expect(
        db.tenGodFor(dayStem: dayStem, targetStem: db.stemAt(3)),
        MyeongliTenGod.hurtingOfficer,
      );
      expect(
        db.tenGodFor(dayStem: dayStem, targetStem: db.stemAt(4)),
        MyeongliTenGod.indirectWealth,
      );
      expect(
        db.tenGodFor(dayStem: dayStem, targetStem: db.stemAt(5)),
        MyeongliTenGod.directWealth,
      );
      expect(
        db.tenGodFor(dayStem: dayStem, targetStem: db.stemAt(6)),
        MyeongliTenGod.sevenKillings,
      );
      expect(
        db.tenGodFor(dayStem: dayStem, targetStem: db.stemAt(7)),
        MyeongliTenGod.directOfficer,
      );
      expect(
        db.tenGodFor(dayStem: dayStem, targetStem: db.stemAt(8)),
        MyeongliTenGod.indirectResource,
      );
      expect(
        db.tenGodFor(dayStem: dayStem, targetStem: db.stemAt(9)),
        MyeongliTenGod.directResource,
      );
    });
  });
}
