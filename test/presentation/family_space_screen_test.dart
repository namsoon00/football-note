import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:football_note/application/family_access_service.dart';
import 'package:football_note/domain/repositories/option_repository.dart';
import 'package:football_note/gen/app_localizations.dart';
import 'package:football_note/presentation/screens/family_space_screen.dart';

void main() {
  testWidgets('sending a family message stores and shows it', (tester) async {
    final repository = _MemoryOptionRepository()
      ..seed(FamilyAccessService.currentRoleLocalKey, 'parent')
      ..seed(FamilyAccessService.parentNameKey, 'Dad')
      ..seed(FamilyAccessService.childNameKey, 'Minjun');

    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('ko', 'KR'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: FamilySpaceScreen(optionRepository: repository),
      ),
    );
    await tester.pumpAndSettle();

    await tester.enterText(
      find.widgetWithText(TextField, '가족 메세지'),
      '오늘 회복이 좋아 보였어.',
    );
    await tester.tap(find.text('보내기'));
    await tester.pumpAndSettle();

    expect(find.text('오늘 회복이 좋아 보였어.'), findsOneWidget);
    expect(find.text('Dad'), findsOneWidget);
    expect(find.text('피드백'), findsWidgets);
  });
}

class _MemoryOptionRepository implements OptionRepository {
  final Map<String, dynamic> _values = <String, dynamic>{};

  void seed(String key, dynamic value) {
    _values[key] = value;
  }

  @override
  List<String> getOptions(String key, List<String> defaults) {
    final value = _values[key];
    if (value is List<String>) return value;
    return defaults;
  }

  @override
  List<int> getIntOptions(String key, List<int> defaults) {
    final value = _values[key];
    if (value is List<int>) return value;
    return defaults;
  }

  @override
  T? getValue<T>(String key) => _values[key] as T?;

  @override
  Future<void> saveOptions(String key, List<dynamic> options) async {
    _values[key] = options;
  }

  @override
  Future<void> setValue(String key, dynamic value) async {
    _values[key] = value;
  }
}
