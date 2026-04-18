import 'dart:convert';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:googleapis/drive/v3.dart' as drive;
import 'package:hive/hive.dart';
import 'package:http/http.dart' as http;

import 'backup_asset_store.dart';
import 'backup_asset_store_types.dart';
import 'drive_connection_info.dart';
import '../domain/entities/training_entry.dart';
import '../domain/repositories/backup_repository.dart';
import '../infrastructure/hive_option_repository.dart';
import 'family_access_service.dart';

class DriveBackupService implements BackupRepository {
  DriveBackupService(
    this._trainingBox,
    this._optionBox, {
    GoogleSignIn? googleSignIn,
    FirebaseAuth? firebaseAuth,
    BackupAssetFileStore? backupAssetFileStore,
    Future<DriveConnectionInfo?> Function()? driveConnectionLoader,
    String? webClientId,
  })  : _googleSignIn = googleSignIn ??
            (kIsWeb
                ? null
                : GoogleSignIn(
                    clientId:
                        webClientId != null && webClientId.trim().isNotEmpty
                            ? webClientId.trim()
                            : null,
                    scopes: const ['email', _driveScope],
                  )),
        _firebaseAuth = firebaseAuth ?? _safeFirebaseAuth(),
        _backupAssetFileStore =
            backupAssetFileStore ?? createBackupAssetFileStore(),
        _driveConnectionLoader = driveConnectionLoader;

  final Box<TrainingEntry> _trainingBox;
  final Box _optionBox;
  final GoogleSignIn? _googleSignIn;
  final FirebaseAuth? _firebaseAuth;
  final BackupAssetFileStore _backupAssetFileStore;
  final Future<DriveConnectionInfo?> Function()? _driveConnectionLoader;
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
  static const connectedDriveEmailLocalKey = 'drive_connected_email_local_v1';
  static const connectedDriveLabelLocalKey = 'drive_connected_label_local_v1';
  static const connectedDriveSubjectLocalKey =
      'drive_connected_subject_local_v1';
  static const recordDriveEmailLocalKey = 'drive_player_email_local_v1';
  static const recordDriveLabelLocalKey = 'drive_player_label_local_v1';
  static const recordDriveSubjectLocalKey = 'drive_player_subject_local_v1';
  static const playerDriveEmailLocalKey = 'drive_player_email_local_v1';
  static const playerDriveLabelLocalKey = 'drive_player_label_local_v1';
  static const playerDriveSubjectLocalKey = 'drive_player_subject_local_v1';
  static const parentDriveEmailLocalKey = 'drive_parent_email_local_v1';
  static const parentDriveLabelLocalKey = 'drive_parent_label_local_v1';
  static const parentDriveSubjectLocalKey = 'drive_parent_subject_local_v1';
  static const sharedChildDriveEmailKey = 'drive_child_email_v1';
  static const sharedChildDriveLabelKey = 'drive_child_label_v1';
  static const _folderName = 'Football Note';
  static const _fileName = 'football_note_backup.json';
  static const _driveScope = 'https://www.googleapis.com/auth/drive.file';
  static const parentDriveMismatchErrorCode = 'parent_drive_mismatch';
  static const parentFamilyMismatchErrorCode = 'parent_family_mismatch';
  static const recordDriveMismatchErrorCode = 'record_drive_mismatch';
  static const playerDriveMismatchErrorCode = recordDriveMismatchErrorCode;
  static const parentModeDriveMismatchErrorCode = 'parent_mode_drive_mismatch';
  static const Set<String> _excludedOptionKeys = {
    _lastBackupKey,
    _localPreRestoreKey,
    _localPreRestoreAtKey,
    FamilyAccessService.messagesKey,
    connectedDriveEmailLocalKey,
    connectedDriveLabelLocalKey,
    connectedDriveSubjectLocalKey,
    recordDriveEmailLocalKey,
    recordDriveLabelLocalKey,
    recordDriveSubjectLocalKey,
    parentDriveEmailLocalKey,
    parentDriveLabelLocalKey,
    parentDriveSubjectLocalKey,
    ...FamilyAccessService.localOnlyOptionKeys,
  };
  static const _backupVersion = 5;
  static const _typedValueKey = '__type';
  static const _typedDataKey = 'data';
  static const _optionRecordsKey = 'optionRecords';
  static const _familyMetadataKey = 'family';
  static const _assetRecordsKey = 'assetRecords';
  static const _assetRefPrefix = 'backup_asset://';
  static const _profilePhotoOptionKey = 'profile_photo_url';

  @override
  Future<void> backup() async {
    try {
      final driveApi = await _driveApi(requireInteractive: kIsWeb);
      await _refreshConnectedDriveAccountCache();
      await _syncSharedChildDriveMetadataIfNeeded();
      await _backupWithApi(driveApi);
    } catch (e, st) {
      if (!_isAuthError(e)) rethrow;
      debugPrint(
        'Drive sign-in/scope missing. Reauthenticating and retrying backup.',
      );
      debugPrintStack(stackTrace: st);
      await _reauthenticateForDriveScope();
      final retriedApi = await _driveApi(requireInteractive: false);
      await _refreshConnectedDriveAccountCache();
      await _syncSharedChildDriveMetadataIfNeeded();
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
        await _refreshConnectedDriveAccountCache();
        await _syncSharedChildDriveMetadataIfNeeded();
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
      await _refreshConnectedDriveAccountCache();
      await _syncSharedChildDriveMetadataIfNeeded();
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
    if (_familyService.loadState().currentRole == FamilyRole.parent) {
      return;
    }
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

  Future<DriveConnectionInfo?> getDriveConnectionInfo() async {
    await _refreshConnectedDriveAccountCache();
    final cached = _loadCachedDriveConnectionInfo();
    return cached?.isEmpty ?? true ? null : cached;
  }

  String getSharedChildDriveEmail() {
    return (_optionBox.get(sharedChildDriveEmailKey) as String?)?.trim() ?? '';
  }

  String getSharedChildDriveLabel() {
    return (_optionBox.get(sharedChildDriveLabelKey) as String?)?.trim() ?? '';
  }

  String getSavedRecordDriveEmail() {
    return (_optionBox.get(recordDriveEmailLocalKey) as String?)?.trim() ?? '';
  }

  String getSavedRecordDriveLabel() {
    return (_optionBox.get(recordDriveLabelLocalKey) as String?)?.trim() ?? '';
  }

  String getSavedPlayerDriveEmail() {
    return getSavedRecordDriveEmail();
  }

  String getSavedPlayerDriveLabel() {
    return getSavedRecordDriveLabel();
  }

  String getSavedParentDriveEmail() {
    return (_optionBox.get(parentDriveEmailLocalKey) as String?)?.trim() ?? '';
  }

  String getSavedParentDriveLabel() {
    return (_optionBox.get(parentDriveLabelLocalKey) as String?)?.trim() ?? '';
  }

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
    final data = _buildBackup(
      updatedByRole: _familyService.loadState().currentRole,
      familyLayerOnly: false,
    );
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
      await _refreshConnectedDriveAccountCache();
      return;
    }
    await _ensureSignedIn(requireInteractive: true);
    await _refreshConnectedDriveAccountCache();
  }

  Future<bool> isSignedIn() async {
    if (kIsWeb) {
      final signedIn = _firebaseAuth?.currentUser != null;
      if (signedIn) {
        await _refreshConnectedDriveAccountCache();
      }
      return signedIn;
    }
    final google = _googleSignIn;
    if (google == null) return false;
    var account = google.currentUser;
    account ??= await google.signInSilently();
    if (account != null) {
      await _refreshConnectedDriveAccountCache();
    }
    return account != null;
  }

  Future<void> signOut() async {
    _webAccessToken = null;
    if (kIsWeb) {
      await _firebaseAuth?.signOut();
      await _clearConnectedDriveAccountCache();
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
    await _clearConnectedDriveAccountCache();
  }

  Future<void> rememberRecordDriveConnection() {
    return _rememberDriveConnection(
      emailKey: recordDriveEmailLocalKey,
      labelKey: recordDriveLabelLocalKey,
      subjectKey: recordDriveSubjectLocalKey,
    );
  }

  Future<void> rememberPlayerDriveConnection() =>
      rememberRecordDriveConnection();

  Future<void> rememberParentDriveConnection() {
    return _rememberDriveConnection(
      emailKey: parentDriveEmailLocalKey,
      labelKey: parentDriveLabelLocalKey,
      subjectKey: parentDriveSubjectLocalKey,
    );
  }

  Future<void> rememberCurrentRoleDriveConnection() async {
    final role = _familyService.loadState().currentRole;
    if (role == FamilyRole.parent) {
      await rememberParentDriveConnection();
      return;
    }
    await rememberRecordDriveConnection();
  }

  Future<void> signInForSavedRecord() {
    return _signInForSavedDrive(
      expectedEmail: _normalizedEmail(getSavedRecordDriveEmail()),
      rememberConnection: rememberRecordDriveConnection,
      mismatchErrorCode: recordDriveMismatchErrorCode,
    );
  }

  Future<void> signInForSavedPlayer() => signInForSavedRecord();

  Future<void> signInForSavedParent() {
    return _signInForSavedDrive(
      expectedEmail: _normalizedEmail(getSavedParentDriveEmail()),
      rememberConnection: rememberParentDriveConnection,
      mismatchErrorCode: parentModeDriveMismatchErrorCode,
    );
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

  Future<void> _refreshConnectedDriveAccountCache() async {
    final info = await _loadDriveConnectionInfo();
    if (info == null || info.isEmpty) return;
    await _optionBox.put(connectedDriveEmailLocalKey, info.email.trim());
    await _optionBox.put(
      connectedDriveLabelLocalKey,
      info.displayName.trim(),
    );
    await _optionBox.put(connectedDriveSubjectLocalKey, info.subjectId.trim());
  }

  Future<void> _clearConnectedDriveAccountCache() async {
    await _optionBox.delete(connectedDriveEmailLocalKey);
    await _optionBox.delete(connectedDriveLabelLocalKey);
    await _optionBox.delete(connectedDriveSubjectLocalKey);
  }

  DriveConnectionInfo? _loadCachedDriveConnectionInfo() {
    final email =
        (_optionBox.get(connectedDriveEmailLocalKey) as String?)?.trim() ?? '';
    final displayName =
        (_optionBox.get(connectedDriveLabelLocalKey) as String?)?.trim() ?? '';
    final subjectId =
        (_optionBox.get(connectedDriveSubjectLocalKey) as String?)?.trim() ??
            '';
    if (email.isEmpty && displayName.isEmpty && subjectId.isEmpty) {
      return null;
    }
    return DriveConnectionInfo(
      email: email,
      displayName: displayName,
      subjectId: subjectId,
    );
  }

  Future<DriveConnectionInfo?> _loadDriveConnectionInfo() async {
    if (_driveConnectionLoader != null) {
      return _driveConnectionLoader();
    }
    if (kIsWeb) {
      final user = _firebaseAuth?.currentUser;
      if (user == null) return null;
      return DriveConnectionInfo(
        email: user.email?.trim() ?? '',
        displayName: user.displayName?.trim() ?? '',
        subjectId: user.uid,
      );
    }
    final google = _googleSignIn;
    if (google == null) return null;
    var account = google.currentUser;
    account ??= await google.signInSilently();
    if (account == null) return null;
    return DriveConnectionInfo(
      email: account.email.trim(),
      displayName: account.displayName?.trim() ?? '',
      subjectId: account.id,
    );
  }

  Future<void> _syncSharedChildDriveMetadataIfNeeded() async {
    final state = _familyService.loadState();
    if (state.currentRole != FamilyRole.child) {
      return;
    }
    final info = _loadCachedDriveConnectionInfo();
    if (info == null || info.email.trim().isEmpty) {
      return;
    }
    await _optionBox.put(sharedChildDriveEmailKey, info.email.trim());
    if (info.label.trim().isNotEmpty) {
      await _optionBox.put(sharedChildDriveLabelKey, info.label.trim());
    }
  }

  Future<String> _findOrCreateFolder(drive.DriveApi api) async {
    final result = await api.files.list(
      q: "mimeType='application/vnd.google-apps.folder' and "
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
    final existing = await _findBackupFile(driveApi, folderId);
    final familyState = _familyService.loadState();
    final remote =
        existing != null && familyState.currentRole == FamilyRole.parent
            ? await _downloadBackupMap(driveApi, existing.id!)
            : null;
    _validateParentRemoteBinding(remote);
    final data = _buildUploadPayload(
      currentRole: familyState.currentRole,
      remote: remote,
    );
    final bytes = utf8.encode(jsonEncode(data));
    final media = drive.Media(Stream.value(bytes), bytes.length);
    if (existing != null) {
      await driveApi.files.update(
        drive.File(name: _fileName),
        existing.id!,
        uploadMedia: media,
      );
      await _cleanupDuplicateBackups(driveApi, folderId, existing.id!);
      await _familyService.recordSharedBackupSync(
          role: familyState.currentRole);
      await _setLastBackup(DateTime.now());
      return;
    }

    final created = await driveApi.files.create(
      drive.File(name: _fileName, parents: [folderId]),
      uploadMedia: media,
    );

    await _familyService.recordSharedBackupSync(role: familyState.currentRole);
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

    final media = await driveApi.files.get(
      file.id!,
      downloadOptions: drive.DownloadOptions.fullMedia,
    ) as drive.Media;

    final content = await utf8.decoder.bind(media.stream).join();
    final data = jsonDecode(content) as Map<String, dynamic>;
    _validateRestoreBinding(data);
    await _restoreFromMap(data);
  }

  Map<String, dynamic> _buildBackup({
    required FamilyRole updatedByRole,
    required bool familyLayerOnly,
  }) {
    final assetRecords = <String, dynamic>{};
    final assetIdBySourcePath = <String, String>{};
    final entries = _trainingBox.values
        .map(
          (entry) => _entryToMap(
            entry,
            assetRecords: assetRecords,
            assetIdBySourcePath: assetIdBySourcePath,
          ),
        )
        .toList();
    final options = <String, dynamic>{};
    final optionRecords = <Map<String, dynamic>>[];
    for (final key in _optionBox.keys) {
      if (key is String && _excludedOptionKeys.contains(key)) {
        continue;
      }
      final encodedKey = _toBackupValue(key);
      final encodedValue = key is String
          ? _encodeOptionValueForBackup(
              key: key,
              value: _optionBox.get(key),
              assetRecords: assetRecords,
              assetIdBySourcePath: assetIdBySourcePath,
            )
          : _toBackupValue(_optionBox.get(key));
      if (encodedKey == _unsupportedValue ||
          encodedValue == _unsupportedValue) {
        continue;
      }
      optionRecords.add(<String, dynamic>{
        'key': encodedKey,
        'value': encodedValue,
      });
      if (key is String) {
        options[key] = encodedValue;
      }
    }
    final familyState = _familyService.loadState();
    return {
      'version': _backupVersion,
      'createdAt': DateTime.now().toIso8601String(),
      'entries': entries,
      'options': options,
      _optionRecordsKey: optionRecords,
      _assetRecordsKey: assetRecords,
      _familyMetadataKey: FamilyAccessService.backupMetadataFromState(
        familyState,
        updatedByRole: updatedByRole,
        familyLayerOnly: familyLayerOnly,
      ),
    };
  }

  @visibleForTesting
  Map<String, dynamic> buildBackupForTesting({
    FamilyRole updatedByRole = FamilyRole.child,
    bool familyLayerOnly = false,
  }) =>
      _buildBackup(
        updatedByRole: updatedByRole,
        familyLayerOnly: familyLayerOnly,
      );

  @visibleForTesting
  Future<void> restoreFromMapForTesting(Map<String, dynamic> data) =>
      _restoreFromMap(data);

  @visibleForTesting
  Map<String, dynamic> mergeParentBackupForTesting({
    required Map<String, dynamic> remote,
  }) {
    return _buildUploadPayload(
      currentRole: FamilyRole.parent,
      remote: remote,
    );
  }

  Future<void> _restoreFromMap(Map<String, dynamic> data) async {
    final version = (data['version'] as num?)?.toInt() ?? 1;
    final entries = (data['entries'] as List?) ?? const [];
    final optionRecords = (data[_optionRecordsKey] as List?) ?? const [];
    final options = (data['options'] as Map?) ?? const {};
    final assetRecords = _extractAssetRecords(data);
    final lastBackupRaw = _optionBox.get(_lastBackupKey);
    final localPreRestoreRaw = _optionBox.get(_localPreRestoreKey);
    final localPreRestoreAtRaw = _optionBox.get(_localPreRestoreAtKey);
    final preservedLocalOnly = <String, dynamic>{
      for (final key in FamilyAccessService.localOnlyOptionKeys)
        key: _optionBox.get(key),
      connectedDriveEmailLocalKey: _optionBox.get(connectedDriveEmailLocalKey),
      connectedDriveLabelLocalKey: _optionBox.get(connectedDriveLabelLocalKey),
      connectedDriveSubjectLocalKey: _optionBox.get(
        connectedDriveSubjectLocalKey,
      ),
      recordDriveEmailLocalKey: _optionBox.get(recordDriveEmailLocalKey),
      recordDriveLabelLocalKey: _optionBox.get(recordDriveLabelLocalKey),
      recordDriveSubjectLocalKey: _optionBox.get(recordDriveSubjectLocalKey),
      parentDriveEmailLocalKey: _optionBox.get(parentDriveEmailLocalKey),
      parentDriveLabelLocalKey: _optionBox.get(parentDriveLabelLocalKey),
      parentDriveSubjectLocalKey: _optionBox.get(parentDriveSubjectLocalKey),
    };

    await _trainingBox.clear();
    for (final raw in entries) {
      if (raw is Map) {
        final entry = await _restoreEntryAssets(
          _entryFromMap(raw.cast<String, dynamic>()),
          assetRecords,
        );
        await _trainingBox.add(entry);
      }
    }

    await _optionBox.clear();
    if (optionRecords.isNotEmpty) {
      for (final raw in optionRecords) {
        if (raw is! Map) continue;
        final key = _fromBackupValue(raw['key'], version: version);
        if (key is String && _excludedOptionKeys.contains(key)) {
          continue;
        }
        if (key == null) continue;
        await _optionBox.put(
          key,
          _fromBackupValue(raw['value'], version: version),
        );
      }
    } else {
      for (final entry in options.entries) {
        if (entry.key is String && !_excludedOptionKeys.contains(entry.key)) {
          await _optionBox.put(
            entry.key,
            _fromBackupValue(entry.value, version: version),
          );
        }
      }
    }
    await _restoreOptionAssets(assetRecords);
    if (localPreRestoreRaw is String) {
      await _optionBox.put(_localPreRestoreKey, localPreRestoreRaw);
    }
    if (localPreRestoreAtRaw is String) {
      await _optionBox.put(_localPreRestoreAtKey, localPreRestoreAtRaw);
    }
    if (lastBackupRaw is String) {
      await _optionBox.put(_lastBackupKey, lastBackupRaw);
    }
    for (final entry in preservedLocalOnly.entries) {
      if (entry.value != null) {
        await _optionBox.put(entry.key, entry.value);
      }
    }
  }

  dynamic _encodeOptionValueForBackup({
    required String key,
    required dynamic value,
    required Map<String, dynamic> assetRecords,
    required Map<String, String> assetIdBySourcePath,
  }) {
    if (key == _profilePhotoOptionKey && value is String) {
      return _toBackupValue(
        _replacePathWithAssetReferenceIfNeeded(
          assetId: 'option:$_profilePhotoOptionKey',
          sourcePath: value,
          assetRecords: assetRecords,
          assetIdBySourcePath: assetIdBySourcePath,
          preferredFileName: 'profile_photo${_fileExtension(value)}',
        ),
      );
    }
    return _toBackupValue(value);
  }

  String _replacePathWithAssetReferenceIfNeeded({
    required String assetId,
    required String sourcePath,
    required Map<String, dynamic> assetRecords,
    required Map<String, String> assetIdBySourcePath,
    String? preferredFileName,
  }) {
    final trimmed = sourcePath.trim();
    if (trimmed.isEmpty || trimmed.startsWith('data:')) {
      return sourcePath;
    }
    final existingAssetId = assetIdBySourcePath[trimmed];
    if (existingAssetId != null) {
      return '$_assetRefPrefix$existingAssetId';
    }
    final record = _backupAssetFileStore.readFileSync(
      assetId: assetId,
      sourcePath: trimmed,
      preferredFileName: preferredFileName,
    );
    if (record == null) {
      return sourcePath;
    }
    assetIdBySourcePath[trimmed] = record.assetId;
    assetRecords[record.assetId] = record.toMap();
    return '$_assetRefPrefix${record.assetId}';
  }

  Map<String, BackupAssetRecord> _extractAssetRecords(
      Map<String, dynamic> data) {
    final raw = data[_assetRecordsKey];
    if (raw is! Map) {
      return const <String, BackupAssetRecord>{};
    }
    final records = <String, BackupAssetRecord>{};
    raw.forEach((key, value) {
      final record = BackupAssetRecord.tryParse(key.toString(), value);
      if (record != null) {
        records[record.assetId] = record;
      }
    });
    return records;
  }

  Future<void> _restoreOptionAssets(
    Map<String, BackupAssetRecord> assetRecords,
  ) async {
    final raw = _optionBox.get(_profilePhotoOptionKey);
    if (raw is! String || !_isAssetReference(raw)) {
      return;
    }
    final restored = await _restoreAssetReference(raw, assetRecords);
    if (restored == null) {
      return;
    }
    await _optionBox.put(_profilePhotoOptionKey, restored);
  }

  Future<TrainingEntry> _restoreEntryAssets(
    TrainingEntry entry,
    Map<String, BackupAssetRecord> assetRecords,
  ) async {
    final restoredPaths = <String>[];
    for (final path in entry.imagePaths) {
      restoredPaths
          .add(await _restoreAssetReference(path, assetRecords) ?? path);
    }
    final restoredPrimary =
        await _restoreAssetReference(entry.imagePath, assetRecords) ??
            (restoredPaths.isNotEmpty ? restoredPaths.first : entry.imagePath);
    return TrainingEntry(
      date: entry.date,
      durationMinutes: entry.durationMinutes,
      intensity: entry.intensity,
      type: entry.type,
      mood: entry.mood,
      injury: entry.injury,
      notes: entry.notes,
      location: entry.location,
      program: entry.program,
      drills: entry.drills,
      club: entry.club,
      injuryPart: entry.injuryPart,
      painLevel: entry.painLevel,
      rehab: entry.rehab,
      goal: entry.goal,
      feedback: entry.feedback,
      heightCm: entry.heightCm,
      weightKg: entry.weightKg,
      imagePath: restoredPrimary,
      imagePaths: restoredPaths,
      status: entry.status,
      liftingByPart: entry.liftingByPart,
      coachComment: entry.coachComment,
      fortuneComment: entry.fortuneComment,
      fortuneRecommendation: entry.fortuneRecommendation,
      fortuneRecommendedProgram: entry.fortuneRecommendedProgram,
      goalFocuses: entry.goalFocuses,
      goodPoints: entry.goodPoints,
      improvements: entry.improvements,
      nextGoal: entry.nextGoal,
      createdAt: entry.createdAt,
      jumpRopeCount: entry.jumpRopeCount,
      jumpRopeMinutes: entry.jumpRopeMinutes,
      jumpRopeEnabled: entry.jumpRopeEnabled,
      jumpRopeNote: entry.jumpRopeNote,
      opponentTeam: entry.opponentTeam,
      scoredGoals: entry.scoredGoals,
      concededGoals: entry.concededGoals,
      playerGoals: entry.playerGoals,
      playerAssists: entry.playerAssists,
      minutesPlayed: entry.minutesPlayed,
      matchLocation: entry.matchLocation,
      breakfastDone: entry.breakfastDone,
      breakfastRiceBowls: entry.breakfastRiceBowls,
      lunchDone: entry.lunchDone,
      lunchRiceBowls: entry.lunchRiceBowls,
      dinnerDone: entry.dinnerDone,
      dinnerRiceBowls: entry.dinnerRiceBowls,
    );
  }

  Future<String?> _restoreAssetReference(
    String raw,
    Map<String, BackupAssetRecord> assetRecords,
  ) async {
    if (!_isAssetReference(raw)) {
      return null;
    }
    final assetId = raw.substring(_assetRefPrefix.length);
    final record = assetRecords[assetId];
    if (record == null) {
      return null;
    }
    return _backupAssetFileStore.restoreFile(record);
  }

  bool _isAssetReference(String raw) {
    return raw.trim().startsWith(_assetRefPrefix);
  }

  String _fileExtension(String path) {
    final trimmed = path.trim();
    final dotIndex = trimmed.lastIndexOf('.');
    if (dotIndex < 0 || dotIndex == trimmed.length - 1) {
      return '.bin';
    }
    final extension = trimmed.substring(dotIndex);
    if (!RegExp(r'^\.[A-Za-z0-9]+$').hasMatch(extension)) {
      return '.bin';
    }
    return extension;
  }

  void _validateParentRemoteBinding(Map<String, dynamic>? remote) {
    final state = _familyService.loadState();
    if (state.currentRole != FamilyRole.parent || remote == null) {
      return;
    }
    final localFamilyId = state.familyId.trim();
    final remoteFamilyId = _extractFamilyId(remote);
    if (localFamilyId.isNotEmpty &&
        remoteFamilyId.isNotEmpty &&
        localFamilyId != remoteFamilyId) {
      throw StateError(parentFamilyMismatchErrorCode);
    }
    final connectedEmail = _normalizedEmail(
      _optionBox.get(connectedDriveEmailLocalKey) as String?,
    );
    final expectedChildDriveEmail = _normalizedEmail(
      _extractSharedChildDriveEmail(remote).isNotEmpty
          ? _extractSharedChildDriveEmail(remote)
          : _optionBox.get(sharedChildDriveEmailKey) as String?,
    );
    if (expectedChildDriveEmail.isNotEmpty &&
        connectedEmail.isNotEmpty &&
        expectedChildDriveEmail != connectedEmail) {
      throw StateError(parentDriveMismatchErrorCode);
    }
  }

  void _validateRestoreBinding(Map<String, dynamic> remote) {
    final state = _familyService.loadState();
    final localFamilyId = state.familyId.trim();
    final remoteFamilyId = _extractFamilyId(remote);
    if (state.currentRole == FamilyRole.parent &&
        localFamilyId.isNotEmpty &&
        remoteFamilyId.isNotEmpty &&
        localFamilyId != remoteFamilyId) {
      throw StateError(parentFamilyMismatchErrorCode);
    }
  }

  String _extractFamilyId(Map<String, dynamic> backup) {
    final familyRaw = backup[_familyMetadataKey];
    if (familyRaw is Map) {
      final value = familyRaw['familyId']?.toString().trim() ?? '';
      if (value.isNotEmpty) {
        return value;
      }
    }
    final options = _copyStringOptions(backup);
    return options[FamilyAccessService.familyIdKey]?.toString().trim() ?? '';
  }

  String _extractSharedChildDriveEmail(Map<String, dynamic> backup) {
    final options = _copyStringOptions(backup);
    return options[sharedChildDriveEmailKey]?.toString().trim() ?? '';
  }

  String _normalizedEmail(String? raw) {
    return raw?.trim().toLowerCase() ?? '';
  }

  Future<void> _rememberDriveConnection({
    required String emailKey,
    required String labelKey,
    required String subjectKey,
  }) async {
    final info = await getDriveConnectionInfo();
    if (info == null || info.isEmpty) {
      return;
    }
    await _optionBox.put(emailKey, info.email.trim());
    await _optionBox.put(labelKey, info.label.trim());
    await _optionBox.put(subjectKey, info.subjectId.trim());
  }

  Future<void> _signInForSavedDrive({
    required String expectedEmail,
    required Future<void> Function() rememberConnection,
    required String mismatchErrorCode,
  }) async {
    final current = await getDriveConnectionInfo();
    if (expectedEmail.isNotEmpty &&
        _normalizedEmail(current?.email) == expectedEmail) {
      await rememberConnection();
      return;
    }
    if (current != null && !current.isEmpty) {
      await signOut();
    }
    await signIn();
    final refreshed = await getDriveConnectionInfo();
    if (expectedEmail.isNotEmpty &&
        _normalizedEmail(refreshed?.email) != expectedEmail) {
      await signOut();
      throw StateError(mismatchErrorCode);
    }
    await rememberConnection();
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

  dynamic _toBackupValue(dynamic value) {
    if (value == null || value is String || value is bool || value is num) {
      return value;
    }
    if (value is DateTime) {
      return {
        _typedValueKey: 'datetime',
        _typedDataKey: value.toIso8601String(),
      };
    }
    if (value is Uint8List) {
      return {_typedValueKey: 'bytes', _typedDataKey: base64Encode(value)};
    }
    if (value is Set) {
      final result = <dynamic>[];
      for (final item in value) {
        final converted = _toBackupValue(item);
        if (converted == _unsupportedValue) {
          return _unsupportedValue;
        }
        result.add(converted);
      }
      return {_typedValueKey: 'set', _typedDataKey: result};
    }
    if (value is List) {
      final result = <dynamic>[];
      for (final item in value) {
        final converted = _toBackupValue(item);
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
        final converted = _toBackupValue(entry.value);
        if (converted == _unsupportedValue) {
          return _unsupportedValue;
        }
        result[key] = converted;
      }
      return result;
    }
    return _unsupportedValue;
  }

  dynamic _fromBackupValue(dynamic value, {required int version}) {
    if (value is Map) {
      if (version >= 2 &&
          value[_typedValueKey] is String &&
          value.containsKey(_typedDataKey)) {
        final type = value[_typedValueKey] as String;
        final data = value[_typedDataKey];
        switch (type) {
          case 'datetime':
            if (data is String) {
              return DateTime.tryParse(data) ?? data;
            }
            return data;
          case 'bytes':
            if (data is String) {
              try {
                return base64Decode(data);
              } catch (_) {
                return data;
              }
            }
            return data;
          case 'set':
            if (data is List) {
              return data
                  .map((item) => _fromBackupValue(item, version: version))
                  .toSet();
            }
            return <dynamic>{};
          default:
            return data;
        }
      }
      final mapped = <String, dynamic>{};
      for (final entry in value.entries) {
        final key = entry.key;
        if (key is! String) continue;
        mapped[key] = _fromBackupValue(entry.value, version: version);
      }
      return mapped;
    }
    if (value is List) {
      return value
          .map((item) => _fromBackupValue(item, version: version))
          .toList(growable: true);
    }
    return value;
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

  FamilyAccessService get _familyService {
    return FamilyAccessService(HiveOptionRepository(_optionBox));
  }

  Future<Map<String, dynamic>> _downloadBackupMap(
    drive.DriveApi driveApi,
    String fileId,
  ) async {
    final media = await driveApi.files.get(
      fileId,
      downloadOptions: drive.DownloadOptions.fullMedia,
    ) as drive.Media;
    final content = await utf8.decoder.bind(media.stream).join();
    final data = jsonDecode(content);
    if (data is Map<String, dynamic>) {
      return data;
    }
    if (data is Map) {
      return data.cast<String, dynamic>();
    }
    throw StateError('Invalid backup payload.');
  }

  Map<String, dynamic> _buildUploadPayload({
    required FamilyRole currentRole,
    required Map<String, dynamic>? remote,
  }) {
    if (currentRole == FamilyRole.parent) {
      _validateParentRemoteBinding(remote);
    }
    final local = _buildBackup(
      updatedByRole: currentRole,
      familyLayerOnly: false,
    );
    if (currentRole != FamilyRole.parent) {
      return local;
    }
    if (remote == null) {
      throw StateError(
        'Parent mode needs an existing player backup before syncing family data.',
      );
    }
    return _mergeParentFamilyBackup(remote: remote, local: local);
  }

  Map<String, dynamic> _mergeParentFamilyBackup({
    required Map<String, dynamic> remote,
    required Map<String, dynamic> local,
  }) {
    final remoteVersion = (remote['version'] as num?)?.toInt() ?? 1;
    final localVersion = (local['version'] as num?)?.toInt() ?? _backupVersion;
    final mergedOptions = _copyStringOptions(remote);
    final localOptions = _copyStringOptions(local);
    for (final key in FamilyAccessService.sharedBackupOptionKeys) {
      if (localOptions.containsKey(key)) {
        mergedOptions[key] = localOptions[key];
      } else {
        mergedOptions.remove(key);
      }
    }
    final familyState = _familyService.loadState();
    return <String, dynamic>{
      ...remote,
      'version': _backupVersion,
      'createdAt': DateTime.now().toIso8601String(),
      'entries':
          (remote['entries'] as List?)?.toList(growable: true) ?? const [],
      'options': mergedOptions,
      _optionRecordsKey: _mergeOptionRecords(
        remote: remote,
        remoteVersion: remoteVersion,
        local: local,
        localVersion: localVersion,
      ),
      _familyMetadataKey: FamilyAccessService.backupMetadataFromState(
        familyState,
        updatedByRole: FamilyRole.parent,
        familyLayerOnly: true,
      ),
    };
  }

  Map<String, dynamic> _copyStringOptions(Map<String, dynamic> backup) {
    final raw = backup['options'];
    if (raw is! Map) return <String, dynamic>{};
    return raw.map(
      (key, value) => MapEntry(key.toString(), value),
    );
  }

  List<Map<String, dynamic>> _mergeOptionRecords({
    required Map<String, dynamic> remote,
    required int remoteVersion,
    required Map<String, dynamic> local,
    required int localVersion,
  }) {
    final keptRemote = _extractOptionRecords(remote).where((record) {
      final key = _fromBackupValue(record['key'], version: remoteVersion);
      return key is! String ||
          !FamilyAccessService.isSharedBackupOptionKey(key);
    });
    final localShared = _extractOptionRecords(local).where((record) {
      final key = _fromBackupValue(record['key'], version: localVersion);
      return key is String && FamilyAccessService.isSharedBackupOptionKey(key);
    });
    return <Map<String, dynamic>>[
      ...keptRemote,
      ...localShared,
    ];
  }

  List<Map<String, dynamic>> _extractOptionRecords(
      Map<String, dynamic> backup) {
    final raw = backup[_optionRecordsKey];
    if (raw is List) {
      return raw
          .whereType<Map>()
          .map((item) => item.cast<String, dynamic>())
          .toList(growable: true);
    }
    final options = backup['options'];
    if (options is! Map) {
      return <Map<String, dynamic>>[];
    }
    return options.entries
        .map(
          (entry) => <String, dynamic>{
            'key': _toBackupValue(entry.key.toString()),
            'value': entry.value,
          },
        )
        .toList(growable: true);
  }

  Map<String, dynamic> _entryToMap(
    TrainingEntry entry, {
    required Map<String, dynamic> assetRecords,
    required Map<String, String> assetIdBySourcePath,
  }) {
    final assetBaseId = 'training:${entry.createdAt.microsecondsSinceEpoch}';
    final encodedImagePaths = <String>[
      for (var i = 0; i < entry.imagePaths.length; i++)
        _replacePathWithAssetReferenceIfNeeded(
          assetId: '$assetBaseId:$i',
          sourcePath: entry.imagePaths[i],
          assetRecords: assetRecords,
          assetIdBySourcePath: assetIdBySourcePath,
        ),
    ];
    final encodedPrimaryImage = entry.imagePath.trim().isNotEmpty
        ? _replacePathWithAssetReferenceIfNeeded(
            assetId: '$assetBaseId:primary',
            sourcePath: entry.imagePath,
            assetRecords: assetRecords,
            assetIdBySourcePath: assetIdBySourcePath,
          )
        : (encodedImagePaths.isNotEmpty ? encodedImagePaths.first : '');
    return {
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
      'imagePath': encodedPrimaryImage,
      'imagePaths': encodedImagePaths,
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
      'jumpRopeEnabled': entry.jumpRopeEnabled,
      'jumpRopeNote': entry.jumpRopeNote,
      'opponentTeam': entry.opponentTeam,
      'scoredGoals': entry.scoredGoals,
      'concededGoals': entry.concededGoals,
      'playerGoals': entry.playerGoals,
      'playerAssists': entry.playerAssists,
      'minutesPlayed': entry.minutesPlayed,
      'matchLocation': entry.matchLocation,
      'breakfastDone': entry.breakfastDone,
      'breakfastRiceBowls': entry.breakfastRiceBowls,
      'lunchDone': entry.lunchDone,
      'lunchRiceBowls': entry.lunchRiceBowls,
      'dinnerDone': entry.dinnerDone,
      'dinnerRiceBowls': entry.dinnerRiceBowls,
    };
  }

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
      liftingByPart: (map['liftingByPart'] as Map?)?.map(
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
      jumpRopeEnabled: map['jumpRopeEnabled'] as bool? ?? false,
      jumpRopeNote: map['jumpRopeNote'] as String? ?? '',
      opponentTeam:
          map['opponentTeam'] as String? ?? (map['club'] as String? ?? ''),
      scoredGoals: (map['scoredGoals'] as num?)?.toInt(),
      concededGoals: (map['concededGoals'] as num?)?.toInt(),
      playerGoals: (map['playerGoals'] as num?)?.toInt(),
      playerAssists: (map['playerAssists'] as num?)?.toInt(),
      minutesPlayed: (map['minutesPlayed'] as num?)?.toInt(),
      matchLocation: map['matchLocation'] as String? ?? '',
      breakfastDone: map['breakfastDone'] as bool? ?? false,
      breakfastRiceBowls: (map['breakfastRiceBowls'] as num?)?.toInt() ?? 0,
      lunchDone: map['lunchDone'] as bool? ?? false,
      lunchRiceBowls: (map['lunchRiceBowls'] as num?)?.toInt() ?? 0,
      dinnerDone: map['dinnerDone'] as bool? ?? false,
      dinnerRiceBowls: (map['dinnerRiceBowls'] as num?)?.toInt() ?? 0,
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
