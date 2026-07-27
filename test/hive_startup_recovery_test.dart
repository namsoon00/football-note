import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:football_note/infrastructure/hive_startup_recovery.dart';
import 'package:football_note/infrastructure/hive_startup_recovery_io.dart';
import 'package:hive/hive.dart';

void main() {
  late Directory tempDir;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('hive_startup_recovery_');
    Hive.init(tempDir.path);
  });

  tearDown(() async {
    await Hive.close();
    if (await tempDir.exists()) {
      await tempDir.delete(recursive: true);
    }
  });

  test('opens an existing valid box without moving files aside', () async {
    final firstOpen = await Hive.openBox<String>('options');
    await firstOpen.put('locale', 'ko');
    await firstOpen.close();

    final recovered = await openRecoverableHiveBox<String>(
      'options',
      path: tempDir.path,
    );

    expect(recovered.get('locale'), 'ko');
    final movedFiles = tempDir
        .listSync()
        .where((entity) => entity.path.contains('.startup_recovery_'))
        .toList();
    expect(movedFiles, isEmpty);
  });

  test('moves an unopenable box aside and opens an empty replacement',
      () async {
    final corruptDirectory = Directory(
      '${tempDir.path}${Platform.pathSeparator}training_entries.hive',
    );
    await corruptDirectory.create();

    final recovered = await openRecoverableHiveBox<dynamic>(
      'training_entries',
      path: tempDir.path,
    );

    expect(recovered.isOpen, isTrue);
    expect(recovered.isEmpty, isTrue);
    final movedFiles = tempDir
        .listSync()
        .where((entity) => entity.path.contains('.startup_recovery_'))
        .toList();
    expect(movedFiles, hasLength(1));
    expect(movedFiles.single.path, endsWith('.hive'));
    expect(FileSystemEntity.typeSync(movedFiles.single.path),
        FileSystemEntityType.directory);
  });

  test('does not overwrite an existing quarantined Hive box', () async {
    final source = File(
      '${tempDir.path}${Platform.pathSeparator}options.hive',
    );
    await source.writeAsString('first');
    await moveHiveBoxFilesAside(
      'options',
      path: tempDir.path,
      recoveryId: 'fixed',
    );

    await source.writeAsString('second');
    await moveHiveBoxFilesAside(
      'options',
      path: tempDir.path,
      recoveryId: 'fixed',
    );

    final first = File(
      '${tempDir.path}${Platform.pathSeparator}'
      'options.startup_recovery_fixed.hive',
    );
    final second = File(
      '${tempDir.path}${Platform.pathSeparator}'
      'options.startup_recovery_fixed_1.hive',
    );
    expect(await first.readAsString(), 'first');
    expect(await second.readAsString(), 'second');
  });
}
