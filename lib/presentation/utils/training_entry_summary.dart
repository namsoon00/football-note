import 'package:football_note/gen/app_localizations.dart';

import '../../domain/entities/training_entry.dart';

String trainingEntryPrimaryLabel(TrainingEntry entry, AppLocalizations l10n) {
  final label = entry.type.trim();
  if (label.isNotEmpty) return label;
  final programs = entry.effectiveTrainingProgramMinutes.keys
      .map((program) => program.trim())
      .where((program) => program.isNotEmpty)
      .join(', ');
  if (programs.isNotEmpty) return programs;
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

int _liftingPartTotal(TrainingEntry entry) {
  return entry.liftingByPart.values.fold<int>(0, (sum, value) => sum + value);
}

bool _hasJumpRopeRecord(TrainingEntry entry) {
  return entry.jumpRopeEnabled ||
      entry.jumpRopeCount > 0 ||
      entry.jumpRopeMinutes > 0 ||
      entry.jumpRopeNote.trim().isNotEmpty;
}
