import '../domain/entities/training_entry.dart';
import '../domain/repositories/option_repository.dart';
import 'coach_roster_service.dart';
import 'family_access_service.dart';

class ParentTrainingFeedback {
  final String entryId;
  final String message;
  final List<String> reactions;
  final DateTime? updatedAt;

  ParentTrainingFeedback({
    required this.entryId,
    required this.message,
    String reaction = '',
    List<String> reactions = const <String>[],
    this.updatedAt,
  }) : reactions = _normalizeReactions(
          reactions.isEmpty ? _splitReactionIds(reaction) : reactions,
        );

  String get reaction => reactions.join(',');

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'message': message,
      if (reactions.isNotEmpty) ...{
        'reaction': reactions.first,
        'reactions': reactions,
      },
      if (updatedAt != null) 'updatedAt': updatedAt!.toIso8601String(),
    };
  }

  static ParentTrainingFeedback? tryParse(String entryId, dynamic raw) {
    if (raw is String) {
      final trimmed = raw.trim();
      if (trimmed.isEmpty) return null;
      return ParentTrainingFeedback(entryId: entryId, message: trimmed);
    }
    if (raw is! Map) {
      return null;
    }
    final message = raw['message']?.toString().trim() ?? '';
    final reactions = _normalizeReactions([
      if (raw['reactions'] is List)
        ...(raw['reactions'] as List).map((item) => item.toString()),
      ..._splitReactionIds(raw['reaction']?.toString() ?? ''),
    ]);
    if (message.isEmpty && reactions.isEmpty) {
      return null;
    }
    return ParentTrainingFeedback(
      entryId: entryId,
      message: message,
      reactions: reactions,
      updatedAt: DateTime.tryParse(raw['updatedAt']?.toString() ?? ''),
    );
  }

  static List<String> _splitReactionIds(String raw) {
    return raw
        .split(',')
        .map((item) => item.trim())
        .where((item) => item.isNotEmpty)
        .toList(growable: false);
  }

  static List<String> _normalizeReactions(Iterable<String> raw) {
    final seen = <String>{};
    final normalized = <String>[];
    for (final item in raw) {
      final trimmed = item.trim();
      if (trimmed.isEmpty || !seen.add(trimmed)) continue;
      normalized.add(trimmed);
    }
    return List<String>.unmodifiable(normalized);
  }
}

class ParentSharedFeedbackService {
  final OptionRepository _optionRepository;
  final String _playerId;

  ParentSharedFeedbackService(this._optionRepository, {String? playerId})
      : _playerId = CoachRosterService.resolveScopedPlayerIdForOptions(
          _optionRepository,
          explicitPlayerId: playerId,
        );

  static String entryIdFor(TrainingEntry entry) {
    return entry.effectiveRecordId;
  }

  Map<String, ParentTrainingFeedback> loadAll() {
    final raw = _loadRawMap();
    final feedbackByEntryId = <String, ParentTrainingFeedback>{};
    raw.forEach((key, value) {
      final parsed = ParentTrainingFeedback.tryParse(key, value);
      if (parsed != null) {
        feedbackByEntryId[parsed.entryId] = parsed;
      }
    });
    return feedbackByEntryId;
  }

  ParentTrainingFeedback? feedbackForEntry(TrainingEntry entry) {
    return loadAll()[entryIdFor(entry)];
  }

  String messageForEntry(TrainingEntry entry) {
    return feedbackForEntry(entry)?.message ?? '';
  }

  Future<ParentTrainingFeedback?> saveFeedbackForEntry(
    TrainingEntry entry,
    String message, [
    Object reactions = const <String>[],
  ]) async {
    final next = _loadRawMap();
    final entryId = entryIdFor(entry);
    final trimmed = message.trim();
    final normalizedReactions = _normalizeReactionArgument(reactions);
    if (trimmed.isEmpty && normalizedReactions.isEmpty) {
      next.remove(entryId);
      await _optionRepository.setValue(_storageKey, next);
      return null;
    }
    final feedback = ParentTrainingFeedback(
      entryId: entryId,
      message: trimmed,
      reactions: normalizedReactions,
      updatedAt: DateTime.now(),
    );
    next[entryId] = feedback.toMap();
    await _optionRepository.setValue(_storageKey, next);
    return feedback;
  }

  String get _storageKey => _playerId.isEmpty
      ? FamilyAccessService.parentTrainingFeedbackKey
      : CoachRosterService.scopedOptionKey(
          FamilyAccessService.parentTrainingFeedbackKey,
          _playerId,
        );

  Map<String, dynamic> _loadRawMap() {
    final raw = _optionRepository.getValue<Map>(_storageKey);
    if (raw is! Map) {
      return <String, dynamic>{};
    }
    return raw.map((key, value) => MapEntry(key.toString(), value));
  }

  List<String> _normalizeReactionArgument(Object raw) {
    if (raw is String) {
      return ParentTrainingFeedback._normalizeReactions(
        ParentTrainingFeedback._splitReactionIds(raw),
      );
    }
    if (raw is Iterable) {
      return ParentTrainingFeedback._normalizeReactions(
        raw.map((item) => item.toString()),
      );
    }
    return const <String>[];
  }
}
