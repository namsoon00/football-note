class PlayerProfile {
  final String name;
  final String photoUrl;
  final DateTime? birthDate;
  final DateTime? soccerStartDate;
  final double? heightCm;
  final double? weightKg;
  final String gender;
  final String mbtiResult;
  final String positionTestResult;

  const PlayerProfile({
    this.name = '',
    this.photoUrl = '',
    this.birthDate,
    this.soccerStartDate,
    this.heightCm,
    this.weightKg,
    this.gender = '',
    this.mbtiResult = '',
    this.positionTestResult = '',
  });

  bool get isEmpty =>
      name.trim().isEmpty &&
      photoUrl.trim().isEmpty &&
      birthDate == null &&
      soccerStartDate == null &&
      heightCm == null &&
      weightKg == null &&
      gender.trim().isEmpty &&
      mbtiResult.trim().isEmpty &&
      positionTestResult.trim().isEmpty;

  PlayerProfile copyWith({
    String? name,
    String? photoUrl,
    DateTime? birthDate,
    DateTime? soccerStartDate,
    double? heightCm,
    double? weightKg,
    String? gender,
    String? mbtiResult,
    String? positionTestResult,
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
      gender: gender ?? this.gender,
      mbtiResult: mbtiResult ?? this.mbtiResult,
      positionTestResult: positionTestResult ?? this.positionTestResult,
    );
  }
}
