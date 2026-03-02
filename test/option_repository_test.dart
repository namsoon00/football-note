import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:football_note/infrastructure/hive_option_repository.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory tempDir;
  late Box box;
  late HiveOptionRepository repo;

  setUpAll(() async {
    tempDir = await Directory.systemTemp.createTemp('football_note_options');
    Hive.init(tempDir.path);
    box = await Hive.openBox('options');
    repo = HiveOptionRepository(box);
  });

  tearDownAll(() async {
    await box.close();
    await Hive.close();
    await tempDir.delete(recursive: true);
  });

  test('getOptions returns defaults and persists', () async {
    final defaults = ['A', 'B'];
    final values = repo.getOptions('locations', defaults);
    expect(values, defaults);

    await repo.saveOptions('locations', ['C']);
    final updated = repo.getOptions('locations', defaults);
    expect(updated, ['C']);
  });

  test('getIntOptions returns defaults and persists', () async {
    final defaults = [0, 30, 60];
    final values = repo.getIntOptions('durations', defaults);
    expect(values, defaults);

    await repo.saveOptions('durations', [15, 45]);
    final updated = repo.getIntOptions('durations', defaults);
    expect(updated, [15, 45]);
  });
}
