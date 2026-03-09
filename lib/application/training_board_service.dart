import 'dart:convert';

import '../domain/entities/training_board.dart';
import '../domain/repositories/option_repository.dart';

class TrainingBoardService {
  static const String storageKey = 'training_boards_v1';

  final OptionRepository _optionRepository;

  const TrainingBoardService(this._optionRepository);

  List<TrainingBoard> allBoards() {
    final raw = _optionRepository.getValue<String>(storageKey);
    if (raw == null || raw.trim().isEmpty) return const <TrainingBoard>[];
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) return const <TrainingBoard>[];
      final boards =
          decoded
              .whereType<Map>()
              .map((e) => TrainingBoard.fromMap(e.cast<String, dynamic>()))
              .whereType<TrainingBoard>()
              .toList(growable: false)
            ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
      return boards;
    } catch (_) {
      return const <TrainingBoard>[];
    }
  }

  Map<String, TrainingBoard> boardMap() {
    final map = <String, TrainingBoard>{};
    for (final board in allBoards()) {
      map[board.id] = board;
    }
    return map;
  }

  TrainingBoard? findById(String id) {
    final target = id.trim();
    if (target.isEmpty) return null;
    for (final board in allBoards()) {
      if (board.id == target) return board;
    }
    return null;
  }

  Future<TrainingBoard> createBoard({
    required String title,
    required String layoutJson,
  }) async {
    final now = DateTime.now();
    final board = TrainingBoard(
      id: _createId(now),
      title: title.trim().isEmpty ? 'Training Board' : title.trim(),
      layoutJson: layoutJson,
      createdAt: now,
      updatedAt: now,
    );
    final next = [...allBoards(), board];
    await _saveAll(next);
    return board;
  }

  Future<void> saveBoard(TrainingBoard board) async {
    final current = allBoards();
    final next = <TrainingBoard>[];
    var replaced = false;
    for (final item in current) {
      if (item.id == board.id) {
        next.add(board.copyWith(updatedAt: DateTime.now()));
        replaced = true;
      } else {
        next.add(item);
      }
    }
    if (!replaced) {
      next.add(board.copyWith(updatedAt: DateTime.now()));
    }
    await _saveAll(next);
  }

  Future<void> deleteBoard(String id) async {
    final target = id.trim();
    if (target.isEmpty) return;
    final next = allBoards().where((board) => board.id != target).toList();
    await _saveAll(next);
  }

  Future<void> _saveAll(List<TrainingBoard> boards) {
    final normalized = [...boards]
      ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    final encoded = jsonEncode(
      normalized.map((e) => e.toMap()).toList(growable: false),
    );
    return _optionRepository.setValue(storageKey, encoded);
  }

  String _createId(DateTime now) {
    return 'tb_${now.microsecondsSinceEpoch}_${now.millisecond}';
  }
}
