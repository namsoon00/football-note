import 'package:football_note/gen/app_localizations.dart';

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
  AppLocalizations l10n,
) {
  final lifting = _liftingPartTotal(entry);
  final parts = <String>[];
  if (lifting > 0) {
    parts.add('${l10n.challengeLiftingLabel} ${l10n.diaryReps(lifting)}');
  } else if (entry.liftingMinutes > 0) {
    parts.add(
      '${l10n.challengeLiftingLabel} ${l10n.minutes(entry.liftingMinutes)}',
    );
  }

  if (_hasJumpRopeRecord(entry)) {
    if (entry.jumpRopeCount > 0) {
      parts.add(
        '${l10n.challengeJumpRopeLabel} ${l10n.diaryReps(entry.jumpRopeCount)}',
      );
    } else if (entry.jumpRopeMinutes > 0) {
      parts.add(
        '${l10n.challengeJumpRopeLabel} ${l10n.minutes(entry.jumpRopeMinutes)}',
      );
    } else {
      parts.add(l10n.challengeJumpRopeLabel);
    }
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
  final location = entry.location.trim();
  final weather = trainingEntryWeatherLabel(entry);
  return [location, weather].where((part) => part.isNotEmpty).join(' · ');
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
