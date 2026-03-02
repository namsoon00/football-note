class PlayerProfile {
  final String name;
  final String photoUrl;
  final DateTime? birthDate;
  final DateTime? soccerStartDate;
  final double? heightCm;
  final double? weightKg;

  const PlayerProfile({
    this.name = '',
    this.photoUrl = '',
    this.birthDate,
    this.soccerStartDate,
    this.heightCm,
    this.weightKg,
  });

  bool get isEmpty =>
      name.trim().isEmpty &&
      photoUrl.trim().isEmpty &&
      birthDate == null &&
      soccerStartDate == null &&
      heightCm == null &&
      weightKg == null;

  PlayerProfile copyWith({
    String? name,
    String? photoUrl,
    DateTime? birthDate,
    DateTime? soccerStartDate,
    double? heightCm,
    double? weightKg,
    bool clearBirthDate = false,
    bool clearSoccerStartDate = false,
    bool clearHeightCm = false,
    bool clearWeightKg = false,
  }) {
    return PlayerProfile(
      name: name ?? this.name,
      photoUrl: photoUrl ?? this.photoUrl,
      birthDate: clearBirthDate ? null : (birthDate ?? this.birthDate),
      soccerStartDate: clearSoccerStartDate
          ? null
          : (soccerStartDate ?? this.soccerStartDate),
      heightCm: clearHeightCm ? null : (heightCm ?? this.heightCm),
      weightKg: clearWeightKg ? null : (weightKg ?? this.weightKg),
    );
  }
}
