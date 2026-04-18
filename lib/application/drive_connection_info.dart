class DriveConnectionInfo {
  final String email;
  final String displayName;
  final String subjectId;

  const DriveConnectionInfo({
    required this.email,
    required this.displayName,
    required this.subjectId,
  });

  bool get isEmpty =>
      email.trim().isEmpty &&
      displayName.trim().isEmpty &&
      subjectId.trim().isEmpty;

  String get label {
    if (displayName.trim().isNotEmpty && email.trim().isNotEmpty) {
      return '${displayName.trim()} · ${email.trim()}';
    }
    if (email.trim().isNotEmpty) {
      return email.trim();
    }
    return displayName.trim();
  }
}
