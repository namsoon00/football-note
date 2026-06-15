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

    expect(backgroundColor, isNotNull);
    expect(backgroundColor, isNot(Colors.white));
    expect(foregroundColor, Colors.white);
  });
}
