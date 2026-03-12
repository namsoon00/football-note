import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:football_note/application/player_profile_service.dart';
import 'package:football_note/domain/entities/player_profile.dart';
import 'package:football_note/infrastructure/hive_option_repository.dart';
import 'package:hive/hive.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory tempDir;
  late Box optionBox;
  late PlayerProfileService service;

  setUpAll(() async {
    tempDir = await Directory.systemTemp.createTemp('football_note_profile');
    Hive.init(tempDir.path);
    optionBox = await Hive.openBox('options');
    service = PlayerProfileService(HiveOptionRepository(optionBox));
  });

  tearDownAll(() async {
    await optionBox.close();
    await Hive.close();
    await tempDir.delete(recursive: true);
  });

  test('save/load persists profile test results', () async {
    const profile = PlayerProfile(
      name: 'Kim',
      gender: 'male',
      mbtiResult: 'ENTJ',
      positionTestResult: 'MF · Midfielder',
    );

    await service.save(profile);

    final loaded = service.load();

    expect(loaded.name, 'Kim');
    expect(loaded.gender, 'male');
    expect(loaded.mbtiResult, 'ENTJ');
    expect(loaded.positionTestResult, 'MF · Midfielder');
  });
}
