import '../domain/entities/player_profile.dart';
import '../domain/repositories/option_repository.dart';

class PlayerProfileService {
  static const _nameKey = 'profile_name';
  static const _photoUrlKey = 'profile_photo_url';
  static const _birthDateKey = 'profile_birth_date';
  static const _soccerStartDateKey = 'profile_soccer_start_date';
  static const _heightCmKey = 'profile_height_cm';
  static const _weightKgKey = 'profile_weight_kg';
  static const _genderKey = 'profile_gender';
  static const _mbtiResultKey = 'profile_mbti_result';
  static const _positionTestResultKey = 'profile_position_test_result';

  final OptionRepository _options;

  PlayerProfileService(this._options);

  PlayerProfile load() {
    final birthRaw = _options.getValue<String>(_birthDateKey);
    final startRaw = _options.getValue<String>(_soccerStartDateKey);
    return PlayerProfile(
      name: _options.getValue<String>(_nameKey) ?? '',
      photoUrl: _options.getValue<String>(_photoUrlKey) ?? '',
      birthDate: _tryParseIsoDate(birthRaw),
      soccerStartDate: _tryParseIsoDate(startRaw),
      heightCm: _tryParseDouble(_options.getValue(_heightCmKey)),
      weightKg: _tryParseDouble(_options.getValue(_weightKgKey)),
      gender: _options.getValue<String>(_genderKey) ?? '',
      mbtiResult: _options.getValue<String>(_mbtiResultKey) ?? '',
      positionTestResult:
          _options.getValue<String>(_positionTestResultKey) ?? '',
    );
  }

  Future<void> save(PlayerProfile profile) async {
    await _options.setValue(_nameKey, profile.name.trim());
    await _options.setValue(_photoUrlKey, profile.photoUrl.trim());
    await _options.setValue(
      _birthDateKey,
      profile.birthDate?.toIso8601String() ?? '',
    );
    await _options.setValue(
      _soccerStartDateKey,
      profile.soccerStartDate?.toIso8601String() ?? '',
    );
    await _options.setValue(_heightCmKey, profile.heightCm?.toString() ?? '');
    await _options.setValue(_weightKgKey, profile.weightKg?.toString() ?? '');
    await _options.setValue(_genderKey, profile.gender.trim());
    await _options.setValue(_mbtiResultKey, profile.mbtiResult.trim());
    await _options.setValue(
      _positionTestResultKey,
      profile.positionTestResult.trim(),
    );
  }

  int? ageInYears(PlayerProfile profile, DateTime now) {
    return _elapsedYears(profile.birthDate, now);
  }

  int? soccerYears(PlayerProfile profile, DateTime now) {
    return _elapsedYears(profile.soccerStartDate, now);
  }

  int? soccerMonthsRemainder(PlayerProfile profile, DateTime now) {
    final start = profile.soccerStartDate;
    if (start == null || start.isAfter(now)) return null;
    final totalMonths =
        (now.year - start.year) * 12 + (now.month - start.month);
    return totalMonths % 12;
  }

  DateTime? _tryParseIsoDate(String? raw) {
    if (raw == null || raw.isEmpty) return null;
    return DateTime.tryParse(raw);
  }

  double? _tryParseDouble(dynamic raw) {
    if (raw == null) return null;
    if (raw is num) return raw.toDouble();
    final text = raw.toString().trim();
    if (text.isEmpty) return null;
    return double.tryParse(text);
  }

  int? _elapsedYears(DateTime? start, DateTime now) {
    if (start == null || start.isAfter(now)) return null;
    var years = now.year - start.year;
    final beforeAnniversary =
        now.month < start.month ||
        (now.month == start.month && now.day < start.day);
    if (beforeAnniversary) years -= 1;
    return years < 0 ? null : years;
  }
}
