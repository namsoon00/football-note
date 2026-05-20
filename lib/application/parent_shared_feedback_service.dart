import '../domain/entities/training_entry.dart';
import '../domain/repositories/option_repository.dart';
import 'family_access_service.dart';

class ParentTrainingFeedback {
  final String entryId;
  final String message;
  final String reaction;
  final DateTime? updatedAt;

  const ParentTrainingFeedback({
    required this.entryId,
    required this.message,
    this.reaction = '',
    this.updatedAt,
  });

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'message': message,
      if (reaction.trim().isNotEmpty) 'reaction': reaction.trim(),
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
    final reaction = raw['reaction']?.toString().trim() ?? '';
    if (message.isEmpty && reaction.isEmpty) {
      return null;
    }
    return ParentTrainingFeedback(
      entryId: entryId,
      message: message,
      reaction: reaction,
      updatedAt: DateTime.tryParse(raw['updatedAt']?.toString() ?? ''),
    );
  }
}

class ParentSharedFeedbackService {
  final OptionRepository _optionRepository;

  ParentSharedFeedbackService(this._optionRepository);

  static String entryIdFor(TrainingEntry entry) {
    return 'training_${entry.createdAt.toUtc().microsecondsSinceEpoch}';
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
    String reaction = '',
  ]) async {
    final next = _loadRawMap();
    final entryId = entryIdFor(entry);
    final trimmed = message.trim();
    final trimmedReaction = reaction.trim();
    if (trimmed.isEmpty && trimmedReaction.isEmpty) {
      next.remove(entryId);
      await _optionRepository.setValue(
        FamilyAccessService.parentTrainingFeedbackKey,
        next,
      );
      return null;
    }
    final feedback = ParentTrainingFeedback(
      entryId: entryId,
      message: trimmed,
      reaction: trimmedReaction,
      updatedAt: DateTime.now(),
    );
    next[entryId] = feedback.toMap();
    await _optionRepository.setValue(
      FamilyAccessService.parentTrainingFeedbackKey,
      next,
    );
    return feedback;
  }

  Map<String, dynamic> _loadRawMap() {
    final raw = _optionRepository.getValue<Map>(
      FamilyAccessService.parentTrainingFeedbackKey,
    );
    if (raw is! Map) {
      return <String, dynamic>{};
    }
    return raw.map((key, value) => MapEntry(key.toString(), value));
  }
}
