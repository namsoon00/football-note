import '../domain/entities/player_profile.dart';
import '../domain/entities/sport_definition.dart';
import '../domain/repositories/option_repository.dart';
import 'sport_scoped_storage.dart';

class PlayerProfileService {
  static const String nameKey = 'profile_name';
  static const String photoUrlKey = 'profile_photo_url';
  static const String birthDateKey = 'profile_birth_date';
  static const String soccerStartDateKey = 'profile_soccer_start_date';
  static const String heightCmKey = 'profile_height_cm';
  static const String weightKgKey = 'profile_weight_kg';
  static const String genderKey = 'profile_gender';
  static const String mbtiResultKey = 'profile_mbti_result';
  static const String positionTestResultKey = 'profile_position_test_result';
  static const String mbtiAnswersKey = 'profile_mbti_answers';
  static const String positionTestAnswersKey = 'profile_position_test_answers';

  static const Set<String> optionKeys = <String>{
    nameKey,
    photoUrlKey,
    birthDateKey,
    soccerStartDateKey,
    heightCmKey,
    weightKgKey,
    genderKey,
    mbtiResultKey,
    positionTestResultKey,
    mbtiAnswersKey,
    positionTestAnswersKey,
  };

  static const List<String> sportScopedOptionKeyPrefixes = <String>[
    'profile_name_',
    'profile_photo_url_',
    'profile_birth_date_',
    'profile_soccer_start_date_',
    'profile_height_cm_',
    'profile_weight_kg_',
    'profile_gender_',
    'profile_mbti_result_',
    'profile_position_test_result_',
    'profile_mbti_answers_',
    'profile_position_test_answers_',
  ];

  static bool isPhotoUrlKey(String key) {
    if (key == photoUrlKey) return true;
    return SportCatalog.all
        .where((sport) => !sport.isFootball)
        .map((sport) => SportCatalog.optionKey(photoUrlKey, sportId: sport.id))
        .contains(key);
  }

  final OptionRepository _options;
  final String _sportId;

  PlayerProfileService(this._options, {String? sportId})
      : _sportId = currentSportIdForOptions(_options, sportId: sportId);

  PlayerProfile load() {
    final birthRaw = _options.getValue<String>(_key(birthDateKey));
    final startRaw = _options.getValue<String>(_key(soccerStartDateKey));
    return PlayerProfile(
      name: _options.getValue<String>(_key(nameKey)) ?? '',
      photoUrl: _options.getValue<String>(_key(photoUrlKey)) ?? '',
      birthDate: _tryParseIsoDate(birthRaw),
      soccerStartDate: _tryParseIsoDate(startRaw),
      heightCm: _tryParseDouble(_options.getValue(_key(heightCmKey))),
      weightKg: _tryParseDouble(_options.getValue(_key(weightKgKey))),
      gender: _options.getValue<String>(_key(genderKey)) ?? '',
      mbtiResult: _options.getValue<String>(_key(mbtiResultKey)) ?? '',
      positionTestResult:
          _options.getValue<String>(_key(positionTestResultKey)) ?? '',
      mbtiAnswers: _options.getIntOptions(_key(mbtiAnswersKey), const <int>[]),
      positionTestAnswers: _options.getIntOptions(
        _key(positionTestAnswersKey),
        const <int>[],
      ),
    );
  }

  Future<void> save(PlayerProfile profile) async {
    await _options.setValue(_key(nameKey), profile.name.trim());
    await _options.setValue(_key(photoUrlKey), profile.photoUrl.trim());
    await _options.setValue(
      _key(birthDateKey),
      profile.birthDate?.toIso8601String() ?? '',
    );
    await _options.setValue(
      _key(soccerStartDateKey),
      profile.soccerStartDate?.toIso8601String() ?? '',
    );
    await _options.setValue(
        _key(heightCmKey), profile.heightCm?.toString() ?? '');
    await _options.setValue(
        _key(weightKgKey), profile.weightKg?.toString() ?? '');
    await _options.setValue(_key(genderKey), profile.gender.trim());
    await _options.setValue(_key(mbtiResultKey), profile.mbtiResult.trim());
    await _options.setValue(
      _key(positionTestResultKey),
      profile.positionTestResult.trim(),
    );
    await _options.saveOptions(_key(mbtiAnswersKey), profile.mbtiAnswers);
    await _options.saveOptions(
      _key(positionTestAnswersKey),
      profile.positionTestAnswers,
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
    final beforeAnniversary = now.month < start.month ||
        (now.month == start.month && now.day < start.day);
    if (beforeAnniversary) years -= 1;
    return years < 0 ? null : years;
  }

  String _key(String baseKey) {
    return SportCatalog.optionKey(baseKey, sportId: _sportId);
  }
}
