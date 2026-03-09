class TrainingBoard {
  final String id;
  final String title;
  final String layoutJson;
  final DateTime createdAt;
  final DateTime updatedAt;

  const TrainingBoard({
    required this.id,
    required this.title,
    required this.layoutJson,
    required this.createdAt,
    required this.updatedAt,
  });

  TrainingBoard copyWith({
    String? id,
    String? title,
    String? layoutJson,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return TrainingBoard(
      id: id ?? this.id,
      title: title ?? this.title,
      layoutJson: layoutJson ?? this.layoutJson,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'layoutJson': layoutJson,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  static TrainingBoard? fromMap(Map<String, dynamic> map) {
    final id = map['id']?.toString().trim() ?? '';
    if (id.isEmpty) return null;
    final title = map['title']?.toString().trim();
    final layoutJson = map['layoutJson']?.toString() ?? '';
    final now = DateTime.now();
    final createdAt = DateTime.tryParse(map['createdAt']?.toString() ?? '');
    final updatedAt = DateTime.tryParse(map['updatedAt']?.toString() ?? '');
    return TrainingBoard(
      id: id,
      title: (title == null || title.isEmpty) ? 'Training Board' : title,
      layoutJson: layoutJson,
      createdAt: createdAt ?? now,
      updatedAt: updatedAt ?? createdAt ?? now,
    );
  }
}
