const String runningCoachDefaultRunnerId = 'running-coach-default-runner';

class RunningCoachRunnerProfile {
  final String id;
  final String displayName;
  final String? imageReference;
  final DateTime createdAt;
  final bool archived;

  const RunningCoachRunnerProfile({
    required this.id,
    required this.displayName,
    required this.createdAt,
    this.imageReference,
    this.archived = false,
  });

  bool get isDefault => id == runningCoachDefaultRunnerId;

  String get initials {
    final value = displayName.trim();
    return value.isEmpty ? '' : String.fromCharCode(value.runes.first);
  }

  RunningCoachRunnerProfile copyWith({
    String? displayName,
    String? imageReference,
    bool clearImageReference = false,
    bool? archived,
  }) {
    return RunningCoachRunnerProfile(
      id: id,
      displayName: displayName ?? this.displayName,
      imageReference:
          clearImageReference ? null : imageReference ?? this.imageReference,
      createdAt: createdAt,
      archived: isDefault ? false : archived ?? this.archived,
    );
  }

  Map<String, Object?> toMap() => <String, Object?>{
        'id': id,
        'displayName': displayName,
        if (imageReference != null) 'imageReference': imageReference,
        'createdAt': createdAt.toIso8601String(),
        'archived': archived,
      };

  factory RunningCoachRunnerProfile.fromMap(Map<String, dynamic> map) {
    final id = map['id']?.toString().trim() ?? '';
    final displayName = map['displayName']?.toString().trim() ?? '';
    return RunningCoachRunnerProfile(
      id: id,
      displayName: displayName,
      imageReference: _optionalProfileString(map['imageReference']),
      createdAt: DateTime.tryParse(map['createdAt']?.toString() ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0),
      archived:
          id == runningCoachDefaultRunnerId ? false : map['archived'] == true,
    );
  }
}

String? _optionalProfileString(Object? value) {
  final text = value?.toString().trim();
  return text == null || text.isEmpty ? null : text;
}
