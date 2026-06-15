import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:football_note/application/player_level_service.dart';
import 'package:football_note/gen/app_localizations.dart';
import 'package:football_note/presentation/theme/app_theme.dart';
import 'package:football_note/presentation/widgets/level_up_dialog.dart';

void main() {
  testWidgets('level up later action remains visible on gradient dialog', (
    tester,
  ) async {
    final before = PlayerLevelState.fromXp(
      PlayerLevelService.levelThresholds[11] - 1,
    );
    final after = PlayerLevelState.fromXp(
      PlayerLevelService.levelThresholds[11],
    );

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        locale: const Locale('ko', 'KR'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Builder(
          builder: (context) => Scaffold(
            body: Center(
              child: FilledButton(
                onPressed: () {
                  showLevelUpCelebrationDialog(
                    context,
                    award: PlayerLevelAward(
                      gainedXp: 13,
                      before: before,
                      after: after,
                      reasons: const <String>['log'],
                    ),
                    isKo: true,
                    onClaimReward: null,
                  );
                },
                child: const Text('open'),
              ),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('open'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    final laterButton = tester.widget<OutlinedButton>(
      find.widgetWithText(OutlinedButton, '나중에 볼래'),
    );
    final backgroundColor = laterButton.style?.backgroundColor?.resolve(
      <WidgetState>{},
    );
    final foregroundColor = laterButton.style?.foregroundColor?.resolve(
      <WidgetState>{},
    );
    final celebrationImage = tester.widget<Image>(find.byType(Image));
    final imageProvider = celebrationImage.image as AssetImage;

    expect(backgroundColor, isNotNull);
    expect(backgroundColor, isNot(Colors.white));
    expect(foregroundColor, Colors.white);
    expect(
      imageProvider.assetName,
      'assets/images/record_reward_gem_character.png',
    );
  });

  testWidgets('training record reward screen uses receiving gem character', (
    tester,
  ) async {
    final before = PlayerLevelState.fromXp(20);
    final after = PlayerLevelState.fromXp(33);

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        locale: const Locale('ko', 'KR'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Builder(
          builder: (context) => Scaffold(
            body: Center(
              child: FilledButton(
                onPressed: () {
                  showTrainingXpRewardDialog(
                    context,
                    award: PlayerLevelAward(
                      gainedXp: 13,
                      before: before,
                      after: after,
                      reasons: const <String>['log'],
                    ),
                  );
                },
                child: const Text('open'),
              ),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('open'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    final imageAssets = tester
        .widgetList<Image>(find.byType(Image))
        .map((image) => (image.image as AssetImage).assetName);

    expect(
      imageAssets,
      contains('assets/images/record_reward_gem_character.png'),
    );
    expect(
      imageAssets,
      isNot(contains('assets/images/celebration_gem_flame_fairytale.png')),
    );

    final painterTypes = tester
        .widgetList<CustomPaint>(find.byType(CustomPaint))
        .map((paint) => paint.painter?.runtimeType.toString());

    expect(painterTypes, contains('_FallingGemPainter'));
    expect(painterTypes, contains('_GemCascadePainter'));
  });

  testWidgets('training record saved screen opens when no xp is earned', (
    tester,
  ) async {
    final state = PlayerLevelState.fromXp(65);

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        locale: const Locale('ko', 'KR'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Builder(
          builder: (context) => Scaffold(
            body: Center(
              child: FilledButton(
                onPressed: () {
                  showTrainingRecordSavedDialog(
                    context,
                    award: PlayerLevelAward(
                      gainedXp: 0,
                      before: state,
                      after: state,
                      reasons: const <String>['daily_xp_cap'],
                    ),
                  );
                },
                child: const Text('open'),
              ),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('open'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('훈련 기록 완료'), findsOneWidget);
    expect(find.text('기록 완료'), findsOneWidget);
    expect(find.text('저장 완료'), findsOneWidget);
    expect(find.text('+0 XP'), findsNothing);
  });

  testWidgets('training streak screen uses passion flame character', (
    tester,
  ) async {
    final state = PlayerLevelState.fromXp(80);

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        locale: const Locale('ko', 'KR'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Builder(
          builder: (context) => Scaffold(
            body: Center(
              child: FilledButton(
                onPressed: () {
                  showTrainingStreakCheerDialog(
                    context,
                    award: PlayerLevelAward(
                      gainedXp: 12,
                      before: state,
                      after: state,
                      reasons: const <String>['streak_3'],
                    ),
                  );
                },
                child: const Text('open'),
              ),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('open'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    final imageAssets = tester
        .widgetList<Image>(find.byType(Image))
        .map((image) => (image.image as AssetImage).assetName);

    expect(imageAssets, contains('assets/images/passion_flame_character.png'));
    expect(
      imageAssets,
      isNot(contains('assets/images/celebration_gem_flame_fairytale.png')),
    );

    final painterTypes = tester
        .widgetList<CustomPaint>(find.byType(CustomPaint))
        .map((paint) => paint.painter?.runtimeType.toString());
    final flameBodyTransform = tester.widget<Transform>(
      find.byKey(const ValueKey('burning-flame-body-transform')),
    );

    expect(painterTypes, contains('_FlameEmberPainter'));
    expect(flameBodyTransform.transform.entry(0, 1), 0);
    expect(flameBodyTransform.transform.entry(1, 0), 0);
  });
}
