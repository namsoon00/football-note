import 'dart:convert';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:googleapis/drive/v3.dart' as drive;
import 'package:hive/hive.dart';
import 'package:http/http.dart' as http;

import '../domain/entities/training_entry.dart';
import '../domain/repositories/backup_repository.dart';

class DriveBackupService implements BackupRepository {
  DriveBackupService(
    this._trainingBox,
    this._optionBox, {
    GoogleSignIn? googleSignIn,
    FirebaseAuth? firebaseAuth,
    String? webClientId,
  }) : _googleSignIn =
           googleSignIn ??
           (kIsWeb
               ? null
               : GoogleSignIn(
                   clientId:
                       webClientId != null && webClientId.trim().isNotEmpty
                       ? webClientId.trim()
                       : null,
                   scopes: const ['email', _driveScope],
                 )),
       _firebaseAuth = firebaseAuth ?? _safeFirebaseAuth();

  final Box<TrainingEntry> _trainingBox;
  final Box _optionBox;
  final GoogleSignIn? _googleSignIn;
  final FirebaseAuth? _firebaseAuth;
  String? _webAccessToken;

  static FirebaseAuth? _safeFirebaseAuth() {
    if (kIsWeb) {
      try {
        if (Firebase.apps.isEmpty) {
          return null;
        }
      } catch (_) {
        return null;
      }
    }
    try {
      return FirebaseAuth.instance;
    } catch (_) {
      return null;
    }
  }

  static const _autoDailyKey = 'drive_auto_daily';
  static const _autoOnSaveKey = 'drive_auto_on_save';
  static const _lastBackupKey = 'drive_last_backup';
  static const _localPreRestoreKey = 'local_pre_restore_backup';
  static const _localPreRestoreAtKey = 'local_pre_restore_backup_at';
  static const _folderName = 'Football Note';
  static const _fileName = 'football_note_backup.json';
  static const _driveScope = 'https://www.googleapis.com/auth/drive.file';
  static const Set<String> _excludedOptionKeys = {
    _localPreRestoreKey,
    _localPreRestoreAtKey,
  };

  @override
  Future<void> backup() async {
    try {
      final driveApi = await _driveApi(requireInteractive: kIsWeb);
      await _backupWithApi(driveApi);
    } catch (e, st) {
      if (!_isAuthError(e)) rethrow;
      debugPrint(
        'Drive sign-in/scope missing. Reauthenticating and retrying backup.',
      );
      debugPrintStack(stackTrace: st);
      await _reauthenticateForDriveScope();
      final retriedApi = await _driveApi(requireInteractive: false);
      await _backupWithApi(retriedApi);
    }
  }

  @override
  Future<bool> backupIfSignedIn({bool requireAutoOnSave = false}) async {
    if (requireAutoOnSave && !isAutoOnSaveEnabled()) {
      return false;
    }
    if (kIsWeb) {
      if (_firebaseAuth?.currentUser == null || _webAccessToken == null) {
        return false;
      }
      try {
        final driveApi = await _driveApi(requireInteractive: false);
        await _backupWithApi(driveApi);
        return true;
      } catch (e, st) {
        if (_isAuthError(e)) {
          _webAccessToken = null;
          return false;
        }
        debugPrint('Drive auto backup skipped due to error: $e');
        debugPrintStack(stackTrace: st);
        return false;
      }
    }
    try {
      final google = _googleSignIn;
      if (google == null) {
        return false;
      }
      final account = await google.signInSilently();
      if (account == null) {
        return false;
      }
      final authHeaders = await account.authHeaders;
      final driveApi = drive.DriveApi(_GoogleAuthClient(authHeaders));
      await _backupWithApi(driveApi);
      return true;
    } catch (e, st) {
      if (_isInsufficientScopeError(e)) {
        return false;
      }
      debugPrint('Drive auto backup skipped due to error: $e');
      debugPrintStack(stackTrace: st);
      return false;
    }
  }

  @override
  Future<void> autoBackupDaily() async {
    if (!isAutoDailyEnabled()) {
      return;
    }
    final last = _getLastBackup();
    final now = DateTime.now();
    if (last != null && _isSameDay(last, now)) {
      return;
    }
    try {
      final didBackup = await backupIfSignedIn();
      if (didBackup) {
        await _setLastBackup(now);
      }
    } catch (_) {
      // Ignore auto-backup failures on app start.
    }
  }

  @override
  bool isAutoDailyEnabled() {
    return _optionBox.get(_autoDailyKey, defaultValue: true) as bool;
  }

  @override
  Future<void> setAutoDailyEnabled(bool value) async {
    await _optionBox.put(_autoDailyKey, value);
  }

  @override
  bool isAutoOnSaveEnabled() {
    return _optionBox.get(_autoOnSaveKey, defaultValue: true) as bool;
  }

  @override
  Future<void> setAutoOnSaveEnabled(bool value) async {
    await _optionBox.put(_autoOnSaveKey, value);
  }

  @override
  DateTime? getLastBackup() => _getLastBackup();

  @override
  Future<void> restoreLatest() async {
    await _saveLocalPreRestore();
    try {
      final driveApi = await _driveApi(requireInteractive: kIsWeb);
      await _restoreLatestWithApi(driveApi);
    } catch (e, st) {
      if (!_isAuthError(e)) rethrow;
      debugPrint(
        'Drive sign-in/scope missing. Reauthenticating and retrying restore.',
      );
      debugPrintStack(stackTrace: st);
      await _reauthenticateForDriveScope();
      final retriedApi = await _driveApi(requireInteractive: false);
      await _restoreLatestWithApi(retriedApi);
    }
  }

  Future<void> _saveLocalPreRestore() async {
    final data = _buildBackup();
    final json = jsonEncode(data);
    await _optionBox.put(_localPreRestoreKey, json);
    await _optionBox.put(
      _localPreRestoreAtKey,
      DateTime.now().toIso8601String(),
    );
  }

  Future<drive.DriveApi> _driveApi({required bool requireInteractive}) async {
    if (kIsWeb) {
      final accessToken = await _ensureWebAccessToken(
        requireInteractive: requireInteractive,
      );
      final client = _GoogleAuthClient({
        'Authorization': 'Bearer $accessToken',
      });
      return drive.DriveApi(client);
    }
    final account = await _ensureSignedIn(
      requireInteractive: requireInteractive,
    );
    final authHeaders = await account.authHeaders;
    final client = _GoogleAuthClient(authHeaders);
    return drive.DriveApi(client);
  }

  Future<void> signIn() async {
    if (kIsWeb) {
      await _ensureWebAccessToken(requireInteractive: true);
      return;
    }
    await _ensureSignedIn(requireInteractive: true);
  }

  Future<bool> isSignedIn() async {
    if (kIsWeb) {
      return _firebaseAuth?.currentUser != null;
    }
    final google = _googleSignIn;
    if (google == null) return false;
    var account = google.currentUser;
    account ??= await google.signInSilently();
    return account != null;
  }

  Future<void> signOut() async {
    _webAccessToken = null;
    if (kIsWeb) {
      await _firebaseAuth?.signOut();
      return;
    }
    final google = _googleSignIn;
    if (google == null) return;
    try {
      await google.disconnect();
    } catch (_) {
      // Ignore disconnect failures.
    }
    await google.signOut();
  }

  Future<void> _reauthenticateForDriveScope() async {
    if (kIsWeb) {
      await _firebaseAuth?.signOut();
      _webAccessToken = null;
      await _ensureWebAccessToken(requireInteractive: true);
      return;
    }
    final google = _googleSignIn;
    if (google == null) {
      throw StateError('Google sign-in required.');
    }
    try {
      await google.disconnect();
    } catch (_) {
      // Ignore and continue with sign-out/sign-in flow.
    }
    await google.signOut();
    final account = await google.signIn();
    if (account == null) {
      throw StateError('Google sign-in cancelled.');
    }
    await _ensureDriveScopeGranted();
  }

  Future<String> _ensureWebAccessToken({
    required bool requireInteractive,
  }) async {
    if (!kIsWeb) {
      throw StateError('Web access token requested on non-web platform.');
    }
    final auth = _firebaseAuth;
    if (auth == null) {
      throw StateError('Firebase web auth unavailable.');
    }
    final cached = _webAccessToken;
    if (cached != null && cached.isNotEmpty) {
      return cached;
    }
    if (!requireInteractive) {
      throw StateError('Google sign-in required.');
    }
    final provider = GoogleAuthProvider()
      ..addScope('email')
      ..addScope(_driveScope)
      ..setCustomParameters(const {'prompt': 'consent'});
    final credential = await auth.signInWithPopup(provider);
    final oauth = credential.credential;
    final token = oauth is OAuthCredential ? oauth.accessToken : null;
    if (token == null || token.isEmpty) {
      throw StateError('Drive access token is missing.');
    }
    _webAccessToken = token;
    return token;
  }

  Future<GoogleSignInAccount> _ensureSignedIn({
    required bool requireInteractive,
  }) async {
    final google = _googleSignIn;
    if (google == null) {
      throw StateError('Google sign-in required.');
    }
    var account = google.currentUser;
    account ??= await google.signInSilently();
    if (account == null && requireInteractive) {
      account = await google.signIn();
    }
    if (account == null) {
      throw StateError('Google sign-in required.');
    }
    if (requireInteractive) {
      await _ensureDriveScopeGranted();
    }
    return account;
  }

  Future<void> _ensureDriveScopeGranted() async {
    final google = _googleSignIn;
    if (google == null) return;
    try {
      final granted = await google.requestScopes(const [_driveScope]);
      if (!granted) {
        throw StateError('Drive permission denied.');
      }
    } on UnimplementedError {
      // Some platforms do not support explicit scope requests.
      // Continue with the scopes configured at sign-in.
    }
  }

  Future<String> _findOrCreateFolder(drive.DriveApi api) async {
    final result = await api.files.list(
      q:
          "mimeType='application/vnd.google-apps.folder' and "
          "name='$_folderName' and trashed=false",
      spaces: 'drive',
      $fields: 'files(id,name)',
    );
    final existing = result.files?.firstOrNull;
    if (existing?.id != null) {
      return existing!.id!;
    }
    final folder = await api.files.create(
      drive.File(
        name: _folderName,
        mimeType: 'application/vnd.google-apps.folder',
      ),
    );
    return folder.id!;
  }

  Future<drive.File?> _findBackupFile(
    drive.DriveApi api,
    String folderId,
  ) async {
    final result = await api.files.list(
      q: "'$folderId' in parents and name='$_fileName' and trashed=false",
      spaces: 'drive',
      orderBy: 'modifiedTime desc',
      $fields: 'files(id,name,modifiedTime)',
    );
    return result.files?.firstOrNull;
  }

  Future<void> _cleanupDuplicateBackups(
    drive.DriveApi api,
    String folderId,
    String keepId,
  ) async {
    final result = await api.files.list(
      q: "'$folderId' in parents and name='$_fileName' and trashed=false",
      spaces: 'drive',
      orderBy: 'modifiedTime desc',
      $fields: 'files(id,name,modifiedTime)',
    );
    final files = result.files ?? const <drive.File>[];
    for (final file in files) {
      if (file.id != null && file.id != keepId) {
        await api.files.delete(file.id!);
      }
    }
  }

  Future<void> _backupWithApi(drive.DriveApi driveApi) async {
    final folderId = await _findOrCreateFolder(driveApi);
    final data = _buildBackup();
    final bytes = utf8.encode(jsonEncode(data));
    final media = drive.Media(Stream.value(bytes), bytes.length);

    final existing = await _findBackupFile(driveApi, folderId);
    if (existing != null) {
      await driveApi.files.update(
        drive.File(name: _fileName),
        existing.id!,
        uploadMedia: media,
      );
      await _cleanupDuplicateBackups(driveApi, folderId, existing.id!);
      await _setLastBackup(DateTime.now());
      return;
    }

    final created = await driveApi.files.create(
      drive.File(name: _fileName, parents: [folderId]),
      uploadMedia: media,
    );

    await _setLastBackup(DateTime.now());
    if (created.id != null) {
      await _cleanupDuplicateBackups(driveApi, folderId, created.id!);
    }
  }

  Future<void> _restoreLatestWithApi(drive.DriveApi driveApi) async {
    final folderId = await _findOrCreateFolder(driveApi);
    final file = await _findBackupFile(driveApi, folderId);
    if (file == null) {
      throw StateError('No backup file found.');
    }

    final media =
        await driveApi.files.get(
              file.id!,
              downloadOptions: drive.DownloadOptions.fullMedia,
            )
            as drive.Media;

    final content = await utf8.decoder.bind(media.stream).join();
    final data = jsonDecode(content) as Map<String, dynamic>;
    await _restoreFromMap(data);
  }

  Map<String, dynamic> _buildBackup() {
    final entries = _trainingBox.values.map(_entryToMap).toList();
    final options = <String, dynamic>{};
    for (final key in _optionBox.keys) {
      if (key is String && !_excludedOptionKeys.contains(key)) {
        final jsonSafe = _toJsonSafe(_optionBox.get(key));
        if (jsonSafe != _unsupportedValue) {
          options[key] = jsonSafe;
        }
      }
    }
    return {
      'version': 1,
      'createdAt': DateTime.now().toIso8601String(),
      'entries': entries,
      'options': options,
    };
  }

  @visibleForTesting
  Map<String, dynamic> buildBackupForTesting() => _buildBackup();

  @visibleForTesting
  Future<void> restoreFromMapForTesting(Map<String, dynamic> data) =>
      _restoreFromMap(data);

  Future<void> _restoreFromMap(Map<String, dynamic> data) async {
    final entries = (data['entries'] as List?) ?? const [];
    final options = (data['options'] as Map?) ?? const {};
    final localPreRestoreRaw = _optionBox.get(_localPreRestoreKey);
    final localPreRestoreAtRaw = _optionBox.get(_localPreRestoreAtKey);

    await _trainingBox.clear();
    for (final raw in entries) {
      if (raw is Map) {
        await _trainingBox.add(_entryFromMap(raw.cast<String, dynamic>()));
      }
    }

    await _optionBox.clear();
    for (final entry in options.entries) {
      if (entry.key is String && !_excludedOptionKeys.contains(entry.key)) {
        await _optionBox.put(entry.key, entry.value);
      }
    }
    if (localPreRestoreRaw is String) {
      await _optionBox.put(_localPreRestoreKey, localPreRestoreRaw);
    }
    if (localPreRestoreAtRaw is String) {
      await _optionBox.put(_localPreRestoreAtKey, localPreRestoreAtRaw);
    }
  }

  bool hasLocalPreRestoreBackup() {
    return _optionBox.get(_localPreRestoreKey) != null;
  }

  DateTime? getLocalPreRestoreTime() {
    final value = _optionBox.get(_localPreRestoreAtKey);
    if (value is String) {
      return DateTime.tryParse(value);
    }
    return null;
  }

  Future<void> restoreLocalPreBackup() async {
    final raw = _optionBox.get(_localPreRestoreKey);
    if (raw is! String) {
      throw StateError('No local backup available.');
    }
    final data = jsonDecode(raw) as Map<String, dynamic>;
    await _restoreFromMap(data);
  }

  DateTime? _getLastBackup() {
    final value = _optionBox.get(_lastBackupKey);
    if (value is String) {
      return DateTime.tryParse(value);
    }
    return null;
  }

  Future<void> _setLastBackup(DateTime value) async {
    await _optionBox.put(_lastBackupKey, value.toIso8601String());
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  static const _unsupportedValue = Object();

  dynamic _toJsonSafe(dynamic value) {
    if (value == null || value is String || value is bool || value is num) {
      return value;
    }
    if (value is DateTime) {
      return value.toIso8601String();
    }
    if (value is List) {
      final result = <dynamic>[];
      for (final item in value) {
        final converted = _toJsonSafe(item);
        if (converted == _unsupportedValue) {
          return _unsupportedValue;
        }
        result.add(converted);
      }
      return result;
    }
    if (value is Map) {
      final result = <String, dynamic>{};
      for (final entry in value.entries) {
        final key = entry.key;
        if (key is! String) {
          return _unsupportedValue;
        }
        final converted = _toJsonSafe(entry.value);
        if (converted == _unsupportedValue) {
          return _unsupportedValue;
        }
        result[key] = converted;
      }
      return result;
    }
    return _unsupportedValue;
  }

  bool _isInsufficientScopeError(Object error) {
    final msg = error.toString().toLowerCase();
    return msg.contains('insufficient authentication scopes') ||
        msg.contains('insufficientpermissions') ||
        msg.contains('insufficient permissions');
  }

  bool _isSignInRequiredError(Object error) {
    final msg = error.toString().toLowerCase();
    return msg.contains('sign-in required') ||
        msg.contains('sign in required') ||
        msg.contains('firebase web auth unavailable');
  }

  bool _isAuthError(Object error) {
    final msg = error.toString().toLowerCase();
    return _isInsufficientScopeError(error) ||
        _isSignInRequiredError(error) ||
        msg.contains('invalid credentials') ||
        msg.contains('unauthenticated') ||
        msg.contains('request is missing required authentication credential');
  }

  Map<String, dynamic> _entryToMap(TrainingEntry entry) => {
    'date': entry.date.toIso8601String(),
    'createdAt': entry.createdAt.toIso8601String(),
    'durationMinutes': entry.durationMinutes,
    'intensity': entry.intensity,
    'type': entry.type,
    'mood': entry.mood,
    'injury': entry.injury,
    'notes': entry.notes,
    'location': entry.location,
    'program': entry.program,
    'drills': entry.drills,
    'club': entry.club,
    'injuryPart': entry.injuryPart,
    'painLevel': entry.painLevel,
    'rehab': entry.rehab,
    'goal': entry.goal,
    'feedback': entry.feedback,
    'heightCm': entry.heightCm,
    'weightKg': entry.weightKg,
    'imagePath': entry.imagePath,
    'imagePaths': entry.imagePaths,
    'status': entry.status,
    'liftingByPart': entry.liftingByPart,
    'coachComment': entry.coachComment,
    'fortuneComment': entry.fortuneComment,
    'fortuneRecommendation': entry.fortuneRecommendation,
    'fortuneRecommendedProgram': entry.fortuneRecommendedProgram,
    'goalFocuses': entry.goalFocuses,
    'goodPoints': entry.goodPoints,
    'improvements': entry.improvements,
    'nextGoal': entry.nextGoal,
    'jumpRopeCount': entry.jumpRopeCount,
    'jumpRopeMinutes': entry.jumpRopeMinutes,
  };

  TrainingEntry _entryFromMap(Map<String, dynamic> map) {
    DateTime parseDate() {
      final value = map['date'];
      if (value is String) {
        return DateTime.tryParse(value) ?? DateTime.now();
      }
      return DateTime.now();
    }

    DateTime parseCreatedAt(DateTime fallback) {
      final value = map['createdAt'];
      if (value is String) {
        return DateTime.tryParse(value) ?? fallback;
      }
      return fallback;
    }

    final date = parseDate();

    return TrainingEntry(
      date: date,
      durationMinutes: (map['durationMinutes'] as num?)?.toInt() ?? 0,
      intensity: (map['intensity'] as num?)?.toInt() ?? 3,
      type: map['type'] as String? ?? '',
      mood: (map['mood'] as num?)?.toInt() ?? 3,
      injury: map['injury'] as bool? ?? false,
      notes: map['notes'] as String? ?? '',
      location: map['location'] as String? ?? '',
      program: map['program'] as String? ?? '',
      drills: map['drills'] as String? ?? '',
      club: map['club'] as String? ?? '',
      injuryPart: map['injuryPart'] as String? ?? '',
      painLevel: (map['painLevel'] as num?)?.toInt(),
      rehab: map['rehab'] as bool? ?? false,
      goal: map['goal'] as String? ?? '',
      feedback: map['feedback'] as String? ?? '',
      heightCm: (map['heightCm'] as num?)?.toDouble(),
      weightKg: (map['weightKg'] as num?)?.toDouble(),
      imagePath: map['imagePath'] as String? ?? '',
      imagePaths:
          (map['imagePaths'] as List?)?.cast<String>() ?? const <String>[],
      status: map['status'] as String? ?? 'normal',
      liftingByPart:
          (map['liftingByPart'] as Map?)?.map(
            (key, value) =>
                MapEntry(key.toString(), (value is num) ? value.toInt() : 0),
          ) ??
          const {},
      coachComment: map['coachComment'] as String? ?? '',
      fortuneComment: map['fortuneComment'] as String? ?? '',
      fortuneRecommendation: map['fortuneRecommendation'] as String? ?? '',
      fortuneRecommendedProgram:
          map['fortuneRecommendedProgram'] as String? ?? '',
      goalFocuses:
          (map['goalFocuses'] as List?)?.map((e) => e.toString()).toList() ??
          const <String>[],
      goodPoints:
          (map['goodPoints'] as String?) ?? (map['feedback'] as String? ?? ''),
      improvements:
          (map['improvements'] as String?) ?? (map['notes'] as String? ?? ''),
      nextGoal: (map['nextGoal'] as String?) ?? (map['goal'] as String? ?? ''),
      createdAt: parseCreatedAt(date),
      jumpRopeCount: (map['jumpRopeCount'] as num?)?.toInt() ?? 0,
      jumpRopeMinutes: (map['jumpRopeMinutes'] as num?)?.toInt() ?? 0,
    );
  }
}

class _GoogleAuthClient extends http.BaseClient {
  _GoogleAuthClient(this._headers);

  final Map<String, String> _headers;
  final http.Client _client = http.Client();

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) {
    return _client.send(request..headers.addAll(_headers));
  }

  @override
  void close() {
    _client.close();
    super.close();
  }
}

extension on List<drive.File>? {
  drive.File? get firstOrNull {
    final files = this;
    if (files == null || files.isEmpty) return null;
    return files.first;
  }
}
