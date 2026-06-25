import 'package:football_note/gen/app_localizations.dart';

import '../../application/sport_defaults.dart';
import '../../domain/entities/training_entry.dart';

String trainingEntryPrimaryLabel(TrainingEntry entry, AppLocalizations l10n) {
  final programs = entry.effectiveTrainingProgramMinutes.keys
      .map((program) => program.trim())
      .where((program) => program.isNotEmpty)
      .join(', ');
  if (programs.isNotEmpty) return programs;
  final label = entry.type.trim();
  if (label.isNotEmpty) return label;
  return entry.program.trim().isNotEmpty ? entry.program.trim() : l10n.program;
}

String trainingEntryDurationLabel(TrainingEntry entry, AppLocalizations l10n) {
  final programMinutes = entry.effectiveTrainingProgramMinutes.values.fold<int>(
    0,
    (sum, minutes) => sum + minutes,
  );
  final minutes = programMinutes > 0 ? programMinutes : entry.durationMinutes;
  return minutes > 0 ? l10n.minutes(minutes) : l10n.durationNotSet;
}

List<String> trainingEntryConditioningParts(
  TrainingEntry entry,
  AppLocalizations l10n, {
  bool includeEmptyMessage = false,
}) {
  final lifting = _liftingPartTotal(entry);
  final parts = <String>[];
  final primaryConditioningLabel = SportDefaults.primaryConditioningLabel(
    l10n: l10n,
    sportId: entry.sportId,
  );
  final secondaryConditioningLabel = SportDefaults.secondaryConditioningLabel(
    l10n: l10n,
    sportId: entry.sportId,
  );
  if (lifting > 0) {
    parts.add('$secondaryConditioningLabel ${l10n.diaryReps(lifting)}');
  } else if (entry.liftingMinutes > 0) {
    parts.add(
      '$secondaryConditioningLabel ${l10n.minutes(entry.liftingMinutes)}',
    );
  }

  if (_hasJumpRopeRecord(entry)) {
    if (entry.jumpRopeCount > 0) {
      parts.add(
        '$primaryConditioningLabel ${l10n.diaryReps(entry.jumpRopeCount)}',
      );
    } else if (entry.jumpRopeMinutes > 0) {
      parts.add(
        '$primaryConditioningLabel ${l10n.minutes(entry.jumpRopeMinutes)}',
      );
    } else {
      parts.add(primaryConditioningLabel);
    }
  }
  if (parts.isEmpty && includeEmptyMessage) {
    parts.add(
      l10n.sportConditioningEmpty(
        primaryConditioningLabel,
        secondaryConditioningLabel,
      ),
    );
  }
  return parts;
}

String trainingEntryWeatherLabel(TrainingEntry entry) {
  for (final line in entry.notes.split('\n')) {
    final trimmed = line.trim();
    final english = _metadataValue(trimmed, '[Weather]');
    if (english.isNotEmpty) return english;
    final korean = _metadataValue(trimmed, '[날씨]');
    if (korean.isNotEmpty) return korean;
  }
  return '';
}

String trainingEntryLocationWeatherLabel(TrainingEntry entry) {
  return trainingEntryWeatherLabel(entry);
}

String trainingEntryLessonLabel(TrainingEntry entry, AppLocalizations l10n) {
  if (!entry.isLesson) return '';
  final detail = entry.lessonDetail.trim();
  if (detail.isEmpty) return l10n.trainingEntryLessonSummary;
  return l10n.trainingEntryLessonSummaryWithDetail(detail);
}

String trainingEntryInjuryLabel(TrainingEntry entry, AppLocalizations l10n) {
  if (!entry.injury) return '';
  final parts = <String>[
    entry.injuryPart.trim(),
    if (entry.painLevel != null)
      l10n.trainingEntryInjuryPainSummary(entry.painLevel!),
  ].where((part) => part.isNotEmpty).toList(growable: false);
  if (parts.isEmpty) return l10n.trainingEntryInjuryPresent;
  return l10n.trainingEntryInjurySummary(parts.join(' · '));
}

String trainingEntryNotesWithoutWeather(TrainingEntry entry) {
  return entry.notes
      .split('\n')
      .map((line) => line.trim())
      .where((line) => line.isNotEmpty)
      .where((line) => !_isWeatherMetadataLine(line))
      .join(' ');
}

int _liftingPartTotal(TrainingEntry entry) {
  return entry.liftingByPart.values.fold<int>(0, (sum, value) => sum + value);
}

bool _hasJumpRopeRecord(TrainingEntry entry) {
  return entry.jumpRopeEnabled ||
      entry.jumpRopeCount > 0 ||
      entry.jumpRopeMinutes > 0 ||
      entry.jumpRopeNote.trim().isNotEmpty;
}

bool _isWeatherMetadataLine(String line) {
  return line.startsWith('[Weather]') || line.startsWith('[날씨]');
}

String _metadataValue(String line, String marker) {
  if (!line.startsWith(marker)) return '';
  return line.substring(marker.length).trim();
}
