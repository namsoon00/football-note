import 'dart:convert';

class TrainingBoardLinkCodec {
  static const int version = 2;

  static List<String> decodeBoardIds(String raw) {
    final text = raw.trim();
    if (text.isEmpty) return const <String>[];
    try {
      final decoded = jsonDecode(text);
      if (decoded is! Map<String, dynamic>) return const <String>[];
      final rawIds = decoded['boardIds'];
      if (rawIds is! List) return const <String>[];
      return rawIds
          .map((e) => e.toString().trim())
          .where((e) => e.isNotEmpty)
          .toSet()
          .toList(growable: false);
    } catch (_) {
      return const <String>[];
    }
  }

  static bool isBoardLinkPayload(String raw) {
    final text = raw.trim();
    if (text.isEmpty) return false;
    try {
      final decoded = jsonDecode(text);
      if (decoded is! Map<String, dynamic>) return false;
      return decoded['boardIds'] is List;
    } catch (_) {
      return false;
    }
  }

  static String encodeBoardIds(List<String> boardIds) {
    final normalized = boardIds
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toSet()
        .toList(growable: false);
    return jsonEncode({'version': version, 'boardIds': normalized});
  }
}
