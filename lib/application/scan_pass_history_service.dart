import '../domain/repositories/option_repository.dart';
import '../domain/scan_pass/scan_pass_game.dart';
import 'sport_scoped_storage.dart';

class ScanPassHistoryService {
  static const String legacySummaryKey = 'scan_pass_summary_v1';
  static const String summaryKey = 'scan_pass_match_summary_v2';

  final OptionRepository optionRepository;
  final String? sportId;

  const ScanPassHistoryService(this.optionRepository, {this.sportId});

  String get storageKey => sportScopedOptionKey(
        optionRepository,
        summaryKey,
        sportId: sportId,
      );

  ScanPassPersonalSummary load() {
    return ScanPassPersonalSummary.fromJson(
      optionRepository.getValue<String>(storageKey),
    );
  }

  Future<ScanPassPersonalSummary> recordSession(
    ScanPassSessionSummary session, {
    DateTime? now,
  }) async {
    final next =
        load().recordSession(session, updatedAt: now ?? DateTime.now());
    await optionRepository.setValue(storageKey, next.toJson());
    return next;
  }
}
