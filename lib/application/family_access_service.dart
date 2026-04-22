import '../domain/repositories/option_repository.dart';
import 'player_level_service.dart';

enum FamilyRole { child, parent }

class FamilyBackupPolicy {
  static const int schemaVersion = 1;

  final bool childOwnsCoreData;
  final bool parentMergesFamilyLayerOnly;
  final List<String> parentWritableScopes;

  const FamilyBackupPolicy({
    required this.childOwnsCoreData,
    required this.parentMergesFamilyLayerOnly,
    required this.parentWritableScopes,
  });

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'schemaVersion': schemaVersion,
      'childOwnsCoreData': childOwnsCoreData,
      'parentMergesFamilyLayerOnly': parentMergesFamilyLayerOnly,
      'parentWritableScopes': parentWritableScopes,
    };
  }
}

class FamilyAccessState {
  final FamilyRole currentRole;
  final String familyId;
  final String childName;
  final String parentName;
  final FamilyBackupPolicy backupPolicy;
  final DateTime? lastSharedSyncAt;
  final FamilyRole? lastSharedSyncRole;

  const FamilyAccessState({
    required this.currentRole,
    required this.familyId,
    required this.childName,
    required this.parentName,
    required this.backupPolicy,
    required this.lastSharedSyncAt,
    required this.lastSharedSyncRole,
  });

  bool get isParentMode => currentRole == FamilyRole.parent;
  bool get isChildMode => currentRole == FamilyRole.child;
  bool get isConfigured =>
      familyId.trim().isNotEmpty ||
      childName.trim().isNotEmpty ||
      parentName.trim().isNotEmpty;
}

class FamilyAccessService {
  static const String currentRoleLocalKey = 'family_current_role_local_v1';
  static const String familyIdKey = 'family_shared_id_v1';
  static const String childNameKey = 'family_child_name_v1';
  static const String parentNameKey = 'family_parent_name_v1';
  static const String parentTrainingFeedbackKey =
      'family_parent_training_feedback_v1';
  static const String messagesKey = 'family_messages_v1';
  static const String lastSharedSyncAtKey = 'family_shared_sync_at_v1';
  static const String lastSharedSyncRoleKey = 'family_shared_sync_role_v1';

  static const Set<String> localOnlyOptionKeys = <String>{currentRoleLocalKey};
  static const Set<String> sharedBackupOptionKeys = <String>{
    familyIdKey,
    childNameKey,
    parentNameKey,
    parentTrainingFeedbackKey,
    lastSharedSyncAtKey,
    lastSharedSyncRoleKey,
    PlayerLevelService.customRewardNamesKey,
  };

  static const FamilyBackupPolicy policy = FamilyBackupPolicy(
    childOwnsCoreData: true,
    parentMergesFamilyLayerOnly: true,
    parentWritableScopes: <String>['feedback', 'rewards'],
  );

  final OptionRepository _options;

  FamilyAccessService(this._options);

  FamilyAccessState loadState() {
    final childName =
        _options.getValue<String>(childNameKey)?.trim() ??
        _options.getValue<String>('profile_name')?.trim() ??
        '';
    final parentName = _options.getValue<String>(parentNameKey)?.trim() ?? '';
    final syncRoleRaw = _options.getValue<String>(lastSharedSyncRoleKey);
    return FamilyAccessState(
      currentRole: roleFromStorage(
        _options.getValue<String>(currentRoleLocalKey),
      ),
      familyId: _options.getValue<String>(familyIdKey)?.trim() ?? '',
      childName: childName,
      parentName: parentName,
      backupPolicy: policy,
      lastSharedSyncAt: DateTime.tryParse(
        _options.getValue<String>(lastSharedSyncAtKey) ?? '',
      ),
      lastSharedSyncRole: syncRoleRaw == null || syncRoleRaw.trim().isEmpty
          ? null
          : roleFromStorage(syncRoleRaw),
    );
  }

  Future<void> setCurrentRole(FamilyRole role) async {
    await _options.setValue(currentRoleLocalKey, role.name);
  }

  Future<void> saveMembers({
    required String childName,
    required String parentName,
  }) async {
    final trimmedChild = childName.trim();
    final trimmedParent = parentName.trim();
    await _options.setValue(childNameKey, trimmedChild);
    await _options.setValue(parentNameKey, trimmedParent);
    if (trimmedChild.isNotEmpty || trimmedParent.isNotEmpty) {
      await _ensureFamilyId();
    }
  }

  Future<void> recordSharedBackupSync({
    required FamilyRole role,
    DateTime? syncedAt,
  }) async {
    await _options.setValue(
      lastSharedSyncAtKey,
      (syncedAt ?? DateTime.now()).toIso8601String(),
    );
    await _options.setValue(lastSharedSyncRoleKey, role.name);
  }

  String displayNameForRole(FamilyRole role, {FamilyAccessState? state}) {
    final resolvedState = state ?? loadState();
    return switch (role) {
      FamilyRole.child =>
        resolvedState.childName.trim().isEmpty
            ? 'Player'
            : resolvedState.childName.trim(),
      FamilyRole.parent =>
        resolvedState.parentName.trim().isEmpty
            ? 'Parent'
            : resolvedState.parentName.trim(),
    };
  }

  bool canEditRewardNames(FamilyRole role) => role == FamilyRole.parent;

  bool canClaimRewards(FamilyRole role) => role == FamilyRole.child;

  bool canEditCoreTrainingData(FamilyRole role) => role == FamilyRole.child;

  static bool isLocalOnlyOptionKey(String key) {
    return localOnlyOptionKeys.contains(key);
  }

  static bool isSharedBackupOptionKey(String key) {
    return sharedBackupOptionKeys.contains(key);
  }

  static FamilyRole roleFromStorage(String? raw) {
    return raw == FamilyRole.parent.name ? FamilyRole.parent : FamilyRole.child;
  }

  static Map<String, dynamic> backupMetadataFromState(
    FamilyAccessState state, {
    required FamilyRole updatedByRole,
    required bool familyLayerOnly,
  }) {
    return <String, dynamic>{
      'familyId': state.familyId,
      'childName': state.childName,
      'parentName': state.parentName,
      'updatedByRole': updatedByRole.name,
      'familyLayerOnly': familyLayerOnly,
      'policy': state.backupPolicy.toMap(),
      'lastSharedSyncAt': state.lastSharedSyncAt?.toIso8601String(),
      'lastSharedSyncRole': state.lastSharedSyncRole?.name,
    };
  }

  Future<void> _ensureFamilyId() async {
    final existing = _options.getValue<String>(familyIdKey)?.trim() ?? '';
    if (existing.isNotEmpty) return;
    await _options.setValue(
      familyIdKey,
      'family-${DateTime.now().microsecondsSinceEpoch}',
    );
  }
}
