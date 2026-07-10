import 'dart:async';

import 'package:flutter/material.dart';
import 'package:football_note/gen/app_localizations.dart';
import 'package:intl/intl.dart';

import '../../application/backup_service.dart';
import '../../application/coach_roster_service.dart';
import '../../application/drive_connection_info.dart';
import '../../application/drive_backup_service.dart';
import '../../application/family_access_service.dart';
import '../../application/health_connect_jump_rope_sync_service.dart';
import '../../application/locale_service.dart';
import '../../application/localized_option_defaults.dart';
import '../../application/news_badge_service.dart';
import '../../application/settings_service.dart';
import '../../application/sport_defaults.dart';
import '../../application/sport_service.dart';
import '../../domain/entities/sport_definition.dart';
import '../../domain/repositories/option_repository.dart';
import '../widgets/sport_scope.dart';
import '../widgets/watch_cart/constants.dart';
import '../widgets/watch_cart/watch_cart_card.dart';

enum _DriveQuickActionTone { neutral, connect, disconnect, restore, backup }

enum SettingsInitialTarget { trainingPrograms }

class _ApiDisclosure {
  final String provider;
  final String traffic;
  final String legal;

  const _ApiDisclosure({
    required this.provider,
    required this.traffic,
    required this.legal,
  });
}

class _ApiDisclosureTile extends StatelessWidget {
  final _ApiDisclosure disclosure;
  final String trafficLabel;
  final String legalLabel;

  const _ApiDisclosureTile({
    required this.disclosure,
    required this.trafficLabel,
    required this.legalLabel,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            disclosure.provider,
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 6),
          _ApiDisclosureLine(
            label: trafficLabel,
            value: disclosure.traffic,
            icon: Icons.speed_rounded,
          ),
          const SizedBox(height: 4),
          _ApiDisclosureLine(
            label: legalLabel,
            value: disclosure.legal,
            icon: Icons.verified_user_outlined,
          ),
        ],
      ),
    );
  }
}

class _ApiDisclosureLine extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;

  const _ApiDisclosureLine({
    required this.label,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: theme.colorScheme.primary),
        const SizedBox(width: 8),
        Expanded(
          child: Text.rich(
            TextSpan(
              children: [
                TextSpan(
                  text: '$label: ',
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
                TextSpan(text: value),
              ],
            ),
            style: theme.textTheme.bodySmall,
          ),
        ),
      ],
    );
  }
}

class SettingsScreen extends StatefulWidget {
  final LocaleService localeService;
  final SettingsService settingsService;
  final OptionRepository optionRepository;
  final BackupService? driveBackupService;
  final HealthConnectJumpRopeSyncService? healthConnectJumpRopeSyncService;
  final SettingsInitialTarget? initialTarget;

  const SettingsScreen({
    super.key,
    required this.localeService,
    required this.settingsService,
    required this.optionRepository,
    this.driveBackupService,
    this.healthConnectJumpRopeSyncService,
    this.initialTarget,
  });

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen>
    with WidgetsBindingObserver {
  final ScrollController _scrollController = ScrollController();
  bool _backupBusy = false;
  bool _restoreBusy = false;
  bool _signInBusy = false;
  bool _signedIn = false;
  bool _autoDaily = true;
  bool _autoOnSave = true;
  String _connectedDriveLabel = '';
  String _sharedChildDriveLabel = '';
  String _sharedChildDriveEmail = '';
  bool _hasRemotePlayerBackup = false;
  bool _driveStatusLoading = true;
  bool _openedInitialTarget = false;
  bool _healthConnectBusy = false;
  bool _healthConnectStatusLoading = false;
  HealthConnectStatus _healthConnectStatus =
      const HealthConnectStatus.unavailable();
  StreamSubscription<void>? _driveAccountStateSubscription;

  late List<int> _durationOptions;
  late List<String> _programOptions;
  late List<String> _dailyGoalOptions;
  late List<String> _injuryPartOptions;

  late int _defaultDuration;
  late String _defaultProgram;
  late List<String> _newsBlockedDomains;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _driveAccountStateSubscription =
        widget.driveBackupService?.driveAccountStateChanges().listen(
              (_) => unawaited(
                _refreshDriveUi(allowRemoteStatusLookup: true),
              ),
            );
    unawaited(
      _refreshDriveUi(
        refreshParentSharedData: true,
        allowRemoteStatusLookup: true,
      ),
    );
    unawaited(_refreshHealthConnectUi());
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      unawaited(_refreshDriveUi(refreshParentSharedData: true));
      unawaited(_refreshHealthConnectUi());
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    unawaited(_driveAccountStateSubscription?.cancel());
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _refreshDriveUi({
    bool allowCachedConnection = false,
    bool refreshParentSharedData = false,
    bool allowRemoteStatusLookup = false,
    bool showLoading = true,
  }) async {
    if (showLoading && widget.driveBackupService != null && mounted) {
      setState(() => _driveStatusLoading = true);
    }
    try {
      await _refreshSignInState(
        allowCachedConnection: allowCachedConnection,
        allowRemoteSharedLookup: allowRemoteStatusLookup,
        checkRemotePlayerBackup: allowRemoteStatusLookup,
      );
      if (refreshParentSharedData) {
        unawaited(_refreshParentSharedDataInBackground());
      }
    } catch (e, st) {
      debugPrint('Drive UI refresh failed: $e');
      debugPrintStack(stackTrace: st);
    } finally {
      if (showLoading && widget.driveBackupService != null && mounted) {
        setState(() => _driveStatusLoading = false);
      }
    }
  }

  Future<void> _refreshParentSharedDataInBackground() async {
    try {
      await _refreshParentSharedDataIfNeeded();
    } catch (e, st) {
      debugPrint('Drive family shared data refresh failed: $e');
      debugPrintStack(stackTrace: st);
    }
    if (!mounted) return;
    await _refreshDriveUi(
      allowCachedConnection: true,
      allowRemoteStatusLookup: true,
      showLoading: false,
    );
  }

  Future<void> _refreshParentSharedDataIfNeeded() async {
    final backup = widget.driveBackupService;
    if (backup == null) return;
    final pushedPending = backup.hasPendingParentSharedChanges()
        ? await backup.backupIfSignedIn()
        : false;
    final result = await backup.refreshFamilySharedDataIfNeeded();
    if (pushedPending || result.refreshed) {
      widget.localeService.load();
      widget.settingsService.load();
      if (!mounted) return;
      SportScope.read(context)?.reloadFromStorage();
    }
  }

  void _scrollToTopAfterLayout() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) return;
      final currentOffset = _scrollController.offset;
      if (currentOffset <= 0) {
        _scrollController.jumpTo(0);
        return;
      }
      unawaited(
        _scrollController.animateTo(
          0,
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOutCubic,
        ),
      );
    });
  }

  void _scheduleInitialTarget(bool readOnly) {
    if (_openedInitialTarget || widget.initialTarget == null) return;
    _openedInitialTarget = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || readOnly) return;
      if (widget.initialTarget == SettingsInitialTarget.trainingPrograms) {
        unawaited(_manageProgramOptions());
      }
    });
  }

  Future<void> _refreshSignInState({
    bool allowCachedConnection = false,
    bool allowRemoteSharedLookup = false,
    bool checkRemotePlayerBackup = false,
  }) async {
    if (widget.driveBackupService == null) return;
    var signedIn = false;
    DriveConnectionInfo? connection;
    try {
      signedIn = await widget.driveBackupService!.isSignedIn();
    } catch (e, st) {
      debugPrint('Drive sign-in check failed: $e');
      debugPrintStack(stackTrace: st);
    }
    try {
      connection = await widget.driveBackupService!.getDriveConnectionInfo();
    } catch (e, st) {
      debugPrint('Drive connection info refresh failed: $e');
      debugPrintStack(stackTrace: st);
    }
    final familyState = FamilyAccessService(
      widget.optionRepository,
    ).loadState();
    DriveConnectionInfo? sharedChildConnection;
    var hasRemotePlayerBackup = _hasRemotePlayerBackup;
    try {
      sharedChildConnection =
          await widget.driveBackupService!.getSharedChildDriveConnectionInfo(
        allowRemoteLookup: allowRemoteSharedLookup && familyState.isParentMode,
      );
      if (checkRemotePlayerBackup &&
          familyState.isParentMode &&
          (sharedChildConnection == null || sharedChildConnection.isEmpty)) {
        hasRemotePlayerBackup =
            await widget.driveBackupService!.hasRemotePlayerBackup();
      }
      if (checkRemotePlayerBackup &&
          familyState.isChildMode &&
          signedIn &&
          connection != null &&
          !connection.isEmpty &&
          _savedPlayerDriveLabel().isEmpty) {
        hasRemotePlayerBackup =
            await widget.driveBackupService!.hasRemotePlayerBackup();
      }
    } catch (e, st) {
      debugPrint('Shared child Drive lookup failed: $e');
      debugPrintStack(stackTrace: st);
    }
    final cachedConnectedDriveLabel = _cachedConnectedDriveLabel();
    if (!mounted) return;
    setState(() {
      _signedIn = signedIn ||
          (connection != null && !connection.isEmpty) ||
          (allowCachedConnection && cachedConnectedDriveLabel.isNotEmpty);
      _connectedDriveLabel = connection?.label.trim().isNotEmpty == true
          ? connection!.label.trim()
          : cachedConnectedDriveLabel;
      _sharedChildDriveLabel = sharedChildConnection?.label.trim() ?? '';
      _sharedChildDriveEmail = sharedChildConnection?.email.trim() ?? '';
      _hasRemotePlayerBackup = hasRemotePlayerBackup;
    });
  }

  String _cachedConnectedDriveLabel() {
    final cachedLabel = widget.optionRepository
            .getValue<String>(DriveBackupService.connectedDriveLabelLocalKey)
            ?.trim() ??
        '';
    final cachedEmail = widget.optionRepository
            .getValue<String>(DriveBackupService.connectedDriveEmailLocalKey)
            ?.trim() ??
        '';
    if (cachedLabel.isEmpty) {
      return cachedEmail;
    }
    if (cachedEmail.isEmpty ||
        cachedLabel.toLowerCase().contains(cachedEmail.toLowerCase())) {
      return cachedLabel;
    }
    return '$cachedLabel · $cachedEmail';
  }

  String _savedPlayerDriveLabel() {
    final backup = widget.driveBackupService;
    if (backup == null) return '';
    final label = backup.getSavedPlayerDriveLabel().trim();
    final email = backup.getSavedPlayerDriveEmail().trim();
    if (label.isEmpty) {
      return email;
    }
    if (email.isEmpty || label.toLowerCase().contains(email.toLowerCase())) {
      return label;
    }
    return '$label · $email';
  }

  bool _driveLabelMatchesEmail(String label, String email) {
    final normalizedEmail = email.trim().toLowerCase();
    if (normalizedEmail.isEmpty || label.trim().isEmpty) {
      return false;
    }
    return label.toLowerCase().contains(normalizedEmail);
  }

  bool _backupLockedByChangedPlayerDrive(FamilyAccessState familyState) {
    if (!familyState.isChildMode || !_signedIn) return false;
    return widget.driveBackupService?.hasChangedPlayerDriveConnection() ??
        false;
  }

  bool _playerDriveNeedsResolution(FamilyAccessState familyState) {
    if (!familyState.isChildMode || !_signedIn) return false;
    return _backupLockedByChangedPlayerDrive(familyState) ||
        _savedPlayerDriveLabel().isEmpty;
  }

  bool _playerBackupBlockedBeforeImport(FamilyAccessState familyState) {
    return _playerDriveNeedsResolution(familyState);
  }

  bool _shouldShowLatestRestoreAction(FamilyAccessState familyState) {
    if (!_signedIn) return false;
    if (familyState.isSupportMode) return true;
    return !_playerBackupBlockedBeforeImport(familyState);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final current = widget.localeService.locale?.languageCode ?? 'system';
    final familyState = FamilyAccessService(
      widget.optionRepository,
    ).loadState();
    final parentSettingsReadOnly = familyState.isSupportMode;
    final expectedChildDriveLabel = _sharedChildDriveLabel.trim().isNotEmpty
        ? _sharedChildDriveLabel.trim()
        : _sharedChildDriveEmail.trim();
    final sharedChildDriveSubtitle = _driveStatusLoading
        ? l10n.settingsSyncStatusChecking
        : expectedChildDriveLabel.isNotEmpty
            ? l10n.settingsSyncBackupDataReady
            : _hasRemotePlayerBackup
                ? l10n.driveSharedChildAccountRemoteBackup
                : l10n.driveSharedChildAccountEmpty;
    final driveMatchesExpected = expectedChildDriveLabel.isEmpty ||
        _connectedDriveLabel.trim().isEmpty ||
        _driveLabelMatchesEmail(_connectedDriveLabel, _sharedChildDriveEmail);

    if (widget.driveBackupService != null) {
      _autoDaily = widget.driveBackupService!.isAutoDailyEnabled();
      _autoOnSave = widget.driveBackupService!.isAutoOnSaveEnabled();
    }

    final sportId = SportScope.maybeOf(context)?.currentSportId ??
        SportService(widget.optionRepository).currentSportId();
    final durationOptionsKey = SportCatalog.optionKey(
      'durations',
      sportId: sportId,
    );
    final defaultDurationKey = SportCatalog.optionKey(
      'default_duration',
      sportId: sportId,
    );
    final injuryPartsKey = SportCatalog.optionKey(
      'injury_parts',
      sportId: sportId,
    );
    final programOptionsKey = SportCatalog.optionKey(
      'programs',
      sportId: sportId,
    );
    final dailyGoalsKey = SportCatalog.optionKey(
      'daily_goals',
      sportId: sportId,
    );
    final defaultProgramKey = SportCatalog.optionKey(
      'default_program',
      sportId: sportId,
    );
    final localizedProgramDefaults = SportDefaults.programOptions(
      l10n: l10n,
      sportId: sportId,
    );
    _durationOptions = widget.optionRepository.getIntOptions(
      durationOptionsKey,
      const [0, 30, 45, 60, 75, 90, 120],
    );
    _programOptions = widget.optionRepository.getOptions(
      programOptionsKey,
      localizedProgramDefaults,
    );
    final normalizedPrograms = LocalizedOptionDefaults.normalizeOptions(
      key: programOptionsKey,
      stored: _programOptions,
      localizedDefaults: localizedProgramDefaults,
    );
    if (!_sameStringList(_programOptions, normalizedPrograms)) {
      _programOptions = normalizedPrograms;
      widget.optionRepository
          .saveOptions(programOptionsKey, normalizedPrograms);
    }
    _injuryPartOptions = widget.optionRepository.getOptions(injuryPartsKey, [
      l10n.defaultInjury1,
      l10n.defaultInjury2,
      l10n.defaultInjury3,
      l10n.defaultInjury4,
      l10n.defaultInjury5,
    ]);
    _dailyGoalOptions = widget.optionRepository.getOptions(
      dailyGoalsKey,
      _defaultDailyGoals(l10n, sportId: sportId),
    );
    final localizedDailyGoalDefaults = _defaultDailyGoals(
      l10n,
      sportId: sportId,
    );
    final normalizedDailyGoals = LocalizedOptionDefaults.normalizeOptions(
      key: dailyGoalsKey,
      stored: _dailyGoalOptions,
      localizedDefaults: localizedDailyGoalDefaults,
    );
    if (!_sameStringList(_dailyGoalOptions, normalizedDailyGoals)) {
      _dailyGoalOptions = normalizedDailyGoals;
      widget.optionRepository.saveOptions(dailyGoalsKey, normalizedDailyGoals);
    }
    _defaultDuration = widget.optionRepository.getValue<int>(
          defaultDurationKey,
        ) ??
        _durationOptions.first;

    final storedDefaultProgram =
        widget.optionRepository.getValue<String>(defaultProgramKey);
    _defaultProgram = LocalizedOptionDefaults.normalizeDefaultValue(
      key: defaultProgramKey,
      storedValue: storedDefaultProgram,
      localizedDefaults: localizedProgramDefaults,
      options: _programOptions,
    );
    if (storedDefaultProgram != _defaultProgram) {
      unawaited(
        widget.optionRepository.setValue(defaultProgramKey, _defaultProgram),
      );
    }
    _newsBlockedDomains = widget.optionRepository.getOptions(
      'news_blocked_domains',
      const [],
    );
    _scheduleInitialTarget(parentSettingsReadOnly);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        centerTitle: false,
        title: Text(l10n.settings),
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        elevation: 0,
      ),
      body: ListView(
        controller: _scrollController,
        padding: const EdgeInsets.all(16),
        children: [
          _buildRoleAndSyncSection(
            l10n: l10n,
            familyState: familyState,
            sharedChildDriveSubtitle: sharedChildDriveSubtitle,
            driveMatchesExpected: driveMatchesExpected,
          ),
          const SizedBox(height: 12),
          if (widget.healthConnectJumpRopeSyncService != null) ...[
            _buildHealthConnectSection(
              l10n,
              readOnly: parentSettingsReadOnly,
            ),
            const SizedBox(height: 12),
          ],
          _buildSectionCard(
            title: l10n.settingsGeneralSection,
            icon: Icons.tune,
            children: [
              LayoutBuilder(
                builder: (context, constraints) {
                  final twoColumns = constraints.maxWidth >= 520;
                  const spacing = 10.0;
                  final itemWidth = twoColumns
                      ? (constraints.maxWidth - spacing) / 2
                      : constraints.maxWidth;
                  return Wrap(
                    spacing: spacing,
                    runSpacing: 2,
                    children: [
                      SizedBox(
                        width: itemWidth,
                        child: _buildSelectRow<String>(
                          label: l10n.sport,
                          value: sportId,
                          options: SportCatalog.all
                              .map((sport) => sport.id)
                              .toList(growable: false),
                          optionLabel: (value) => SportDefaults.label(
                            l10n: l10n,
                            sportId: value,
                          ),
                          onChanged: parentSettingsReadOnly
                              ? null
                              : (value) =>
                                  unawaited(_changeCurrentSport(value)),
                          height: 56,
                        ),
                      ),
                      SizedBox(
                        width: itemWidth,
                        child: _buildSelectRow<String>(
                          label: l10n.language,
                          value: current,
                          options: const ['system', 'en', 'ko', 'ja'],
                          optionLabel: (value) => switch (value) {
                            'system' => l10n.languageSystemDefault,
                            'ko' => l10n.languageKorean,
                            'ja' => l10n.languageJapanese,
                            _ => l10n.languageEnglish,
                          },
                          onChanged: (value) {
                            if (value == 'system') {
                              widget.localeService.setLocale(null);
                            } else if (value == 'ko') {
                              widget.localeService.setLocale(
                                const Locale('ko', 'KR'),
                              );
                            } else if (value == 'ja') {
                              widget.localeService.setLocale(
                                const Locale('ja'),
                              );
                            } else {
                              widget.localeService.setLocale(
                                const Locale('en'),
                              );
                            }
                          },
                          height: 56,
                        ),
                      ),
                      SizedBox(
                        width: itemWidth,
                        child: _buildSelectRow<ThemeMode>(
                          label: l10n.theme,
                          value: widget.settingsService.themeMode,
                          options: const [
                            ThemeMode.system,
                            ThemeMode.light,
                            ThemeMode.dark,
                          ],
                          optionLabel: (value) {
                            switch (value) {
                              case ThemeMode.light:
                                return l10n.themeLight;
                              case ThemeMode.dark:
                                return l10n.themeDark;
                              case ThemeMode.system:
                                return l10n.themeSystem;
                            }
                          },
                          onChanged: (value) =>
                              widget.settingsService.setThemeMode(value),
                        ),
                      ),
                    ],
                  );
                },
              ),
              if (parentSettingsReadOnly)
                Padding(
                  padding: const EdgeInsets.fromLTRB(4, 2, 4, 4),
                  child: Text(
                    l10n.parentReadOnlySettingsOptions,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          _buildSectionCard(
            title: l10n.defaults,
            icon: Icons.tune_outlined,
            initiallyExpanded:
                widget.initialTarget == SettingsInitialTarget.trainingPrograms,
            children: [
              const SizedBox(height: 6),
              _buildDefaultsAndOptionManager(
                l10n,
                readOnly: parentSettingsReadOnly,
              ),
              const SizedBox(height: 8),
            ],
          ),
          const SizedBox(height: 12),
          _buildSectionCard(
            title: l10n.settingsNewsFilterTitle,
            icon: Icons.filter_alt_outlined,
            children: [
              _buildOptionManagerTile(
                title: l10n.settingsNewsBlockedDomainsTitle,
                subtitle: l10n.settingsNewsBlockedDomainsCount(
                  _newsBlockedDomains.length,
                ),
                onTap: parentSettingsReadOnly
                    ? null
                    : () => _manageStringOptions(
                          key: 'news_blocked_domains',
                          title: l10n.settingsNewsBlockedDomainsManageTitle,
                          options: _newsBlockedDomains,
                          minKeep: 0,
                          sanitize: _normalizeDomain,
                          onSaved: (updated) async {
                            setState(() => _newsBlockedDomains = updated);
                          },
                        ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: Text(
                  parentSettingsReadOnly
                      ? l10n.parentReadOnlySettingsOptions
                      : l10n.settingsNewsBlockedDomainsExample,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildApiUsageSection(l10n),
        ],
      ),
    );
  }

  Widget _buildHealthConnectSection(
    AppLocalizations l10n, {
    required bool readOnly,
  }) {
    final service = widget.healthConnectJumpRopeSyncService;
    if (service == null) return const SizedBox.shrink();
    final statusText = _healthConnectStatusText(l10n);
    final autoEnabled = service.autoSyncEnabled;
    final canUse = _healthConnectStatus.isAvailable;
    final canRunAction = !_healthConnectBusy && !readOnly && canUse;
    final lastSyncAt = service.lastSyncAt;
    return _buildSectionCard(
      title: l10n.healthConnectSectionTitle,
      icon: Icons.health_and_safety_outlined,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(4, 0, 4, 8),
          child: Text(
            l10n.healthConnectSectionSubtitle,
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          secondary: Icon(
            autoEnabled ? Icons.sync_rounded : Icons.sync_disabled_rounded,
          ),
          title: Text(l10n.healthConnectAutoSyncTitle),
          subtitle: Text(
            readOnly ? l10n.parentReadOnlySettingsOptions : statusText,
          ),
          value: autoEnabled,
          onChanged: canUse && !_healthConnectBusy && !readOnly
              ? (value) => unawaited(_setHealthConnectAutoSync(value, l10n))
              : null,
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Text(
            l10n.healthConnectAutoSyncSubtitle,
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            OutlinedButton.icon(
              onPressed: canRunAction
                  ? () => unawaited(_syncHealthConnectJumpRope(l10n))
                  : null,
              icon: _healthConnectBusy
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.sync),
              label: Text(
                _healthConnectStatus.permissionsGranted
                    ? l10n.healthConnectSyncNow
                    : l10n.healthConnectGrantAndSync,
              ),
            ),
          ],
        ),
        if (lastSyncAt != null) ...[
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Text(
              l10n.healthConnectLastSync(_formatBackupTime(lastSyncAt)),
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
        ],
      ],
    );
  }

  String _healthConnectStatusText(AppLocalizations l10n) {
    if (_healthConnectStatusLoading) return l10n.settingsSyncStatusChecking;
    switch (_healthConnectStatus.availability) {
      case HealthConnectAvailabilityState.unavailable:
        return l10n.healthConnectStatusUnavailable;
      case HealthConnectAvailabilityState.updateRequired:
        return l10n.healthConnectStatusUpdateRequired;
      case HealthConnectAvailabilityState.available:
        if (!_healthConnectStatus.permissionsGranted) {
          return l10n.healthConnectStatusPermissionNeeded;
        }
        return widget.healthConnectJumpRopeSyncService?.autoSyncEnabled == true
            ? l10n.healthConnectStatusAutoOn
            : l10n.healthConnectStatusReady;
    }
  }

  Future<void> _refreshHealthConnectUi() async {
    final service = widget.healthConnectJumpRopeSyncService;
    if (service == null) return;
    if (mounted) {
      setState(() => _healthConnectStatusLoading = true);
    }
    final status = await service.status();
    if (!mounted) return;
    setState(() {
      _healthConnectStatus = status;
      _healthConnectStatusLoading = false;
    });
  }

  Future<void> _setHealthConnectAutoSync(
    bool enabled,
    AppLocalizations l10n,
  ) async {
    final service = widget.healthConnectJumpRopeSyncService;
    if (service == null || _healthConnectBusy) return;
    setState(() => _healthConnectBusy = true);
    try {
      if (!enabled) {
        await service.setAutoSyncEnabled(false);
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.healthConnectDisabled)),
        );
        setState(() {});
        return;
      }
      final result = _healthConnectStatus.permissionsGranted
          ? await (() async {
              await service.setAutoSyncEnabled(true);
              return service.syncRecent();
            })()
          : await service.requestPermissionsAndSync();
      if (!mounted) return;
      _showHealthConnectSyncSnack(l10n, result);
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.healthConnectSyncFailed)),
      );
    } finally {
      if (mounted) {
        setState(() => _healthConnectBusy = false);
        unawaited(_refreshHealthConnectUi());
      }
    }
  }

  Future<void> _syncHealthConnectJumpRope(AppLocalizations l10n) async {
    final service = widget.healthConnectJumpRopeSyncService;
    if (service == null || _healthConnectBusy) return;
    setState(() => _healthConnectBusy = true);
    try {
      final result = _healthConnectStatus.permissionsGranted
          ? await service.syncRecent()
          : await service.requestPermissionsAndSync();
      if (!mounted) return;
      _showHealthConnectSyncSnack(l10n, result);
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.healthConnectSyncFailed)),
      );
    } finally {
      if (mounted) {
        setState(() => _healthConnectBusy = false);
        unawaited(_refreshHealthConnectUi());
      }
    }
  }

  void _showHealthConnectSyncSnack(
    AppLocalizations l10n,
    HealthConnectJumpRopeSyncResult result,
  ) {
    final message = !result.status.isAvailable
        ? l10n.healthConnectStatusUnavailable
        : !result.status.permissionsGranted
            ? l10n.healthConnectStatusPermissionNeeded
            : result.importedCount > 0
                ? l10n.healthConnectSyncImported(result.importedCount)
                : l10n.healthConnectSyncNoNewRecords;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  Widget _buildApiUsageSection(AppLocalizations l10n) {
    final disclosures = <_ApiDisclosure>[
      _ApiDisclosure(
        provider: l10n.settingsApiOpenMeteoProvider,
        traffic: l10n.settingsApiOpenMeteoTraffic,
        legal: l10n.settingsApiOpenMeteoLegal,
      ),
      _ApiDisclosure(
        provider: l10n.settingsApiKoreaPublicProvider,
        traffic: l10n.settingsApiKoreaPublicTraffic,
        legal: l10n.settingsApiKoreaPublicLegal,
      ),
      _ApiDisclosure(
        provider: l10n.settingsApiKakaoProvider,
        traffic: l10n.settingsApiKakaoTraffic,
        legal: l10n.settingsApiKakaoLegal,
      ),
      _ApiDisclosure(
        provider: l10n.settingsApiFootballProvider,
        traffic: l10n.settingsApiFootballTraffic,
        legal: l10n.settingsApiFootballLegal,
      ),
      _ApiDisclosure(
        provider: l10n.settingsApiNewsProvider,
        traffic: l10n.settingsApiNewsTraffic,
        legal: l10n.settingsApiNewsLegal,
      ),
      _ApiDisclosure(
        provider: l10n.settingsApiGoogleProvider,
        traffic: l10n.settingsApiGoogleTraffic,
        legal: l10n.settingsApiGoogleLegal,
      ),
    ];
    return _buildSectionCard(
      title: l10n.settingsApiUsageTitle,
      icon: Icons.policy_outlined,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(4, 0, 4, 8),
          child: Text(
            l10n.settingsApiUsageSubtitle,
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ),
        for (var index = 0; index < disclosures.length; index += 1) ...[
          _ApiDisclosureTile(
            disclosure: disclosures[index],
            trafficLabel: l10n.settingsApiTrafficLabel,
            legalLabel: l10n.settingsApiLegalLabel,
          ),
          if (index != disclosures.length - 1) const Divider(height: 18),
        ],
      ],
    );
  }

  Widget _buildSectionCard({
    required String title,
    required IconData icon,
    required List<Widget> children,
    bool initiallyExpanded = false,
  }) {
    return WatchCartCard(
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          tilePadding: EdgeInsets.zero,
          childrenPadding: const EdgeInsets.only(bottom: 6),
          initiallyExpanded: initiallyExpanded,
          leading: Icon(icon),
          title: Text(title, style: Theme.of(context).textTheme.titleSmall),
          children: children,
        ),
      ),
    );
  }

  Widget _buildPrimarySettingsCard({
    required String title,
    required IconData icon,
    String? summary,
    String? detailsMessage,
    String? detailsTooltip,
    List<Widget> headerActions = const <Widget>[],
    required List<Widget> children,
    bool compact = false,
  }) {
    final scheme = Theme.of(context).colorScheme;
    final contentPadding = compact ? 14.0 : 16.0;
    final headerIconSize = compact ? 36.0 : 40.0;
    final headerIconRadius = compact ? 12.0 : 14.0;
    final headerIconGlyphSize = compact ? 18.0 : 20.0;
    final childGap = compact ? 10.0 : 12.0;
    final sectionGap = compact ? 14.0 : 16.0;
    return WatchCartCard(
      child: Padding(
        padding: EdgeInsets.all(contentPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: headerIconSize,
                  height: headerIconSize,
                  decoration: BoxDecoration(
                    color: scheme.primary.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(headerIconRadius),
                  ),
                  alignment: Alignment.center,
                  child: Icon(
                    icon,
                    size: headerIconGlyphSize,
                    color: scheme.primary,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ConstrainedBox(
                        constraints: BoxConstraints(minHeight: headerIconSize),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Expanded(
                              child: Text(
                                title,
                                style: Theme.of(context)
                                    .textTheme
                                    .titleSmall
                                    ?.copyWith(fontWeight: FontWeight.w800),
                              ),
                            ),
                            if (detailsMessage?.trim().isNotEmpty == true)
                              IconButton(
                                onPressed: () => _showSettingsInfoDialog(
                                  title: title,
                                  message: detailsMessage!,
                                ),
                                icon: const Icon(Icons.info_outline, size: 18),
                                tooltip: detailsTooltip,
                                visualDensity: VisualDensity.compact,
                              ),
                            ...headerActions,
                          ],
                        ),
                      ),
                      if (summary?.trim().isNotEmpty == true) ...[
                        const SizedBox(height: 4),
                        Text(
                          summary!,
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
            if (children.isNotEmpty) ...[
              SizedBox(height: sectionGap),
              for (var i = 0; i < children.length; i++) ...[
                children[i],
                if (i != children.length - 1) SizedBox(height: childGap),
              ],
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildRoleAndSyncSection({
    required AppLocalizations l10n,
    required FamilyAccessState familyState,
    required String sharedChildDriveSubtitle,
    required bool driveMatchesExpected,
  }) {
    return _buildSectionCard(
      title: l10n.settingsRoleAndSyncTitle,
      icon: Icons.manage_accounts_outlined,
      initiallyExpanded: true,
      children: [
        _buildUsageModeSection(
          l10n: l10n,
          familyState: familyState,
          compact: true,
        ),
        if (familyState.currentRole == FamilyRole.coach) ...[
          const SizedBox(height: 8),
          _buildCoachRosterSection(l10n, compact: true),
        ],
        if (widget.driveBackupService != null) ...[
          const SizedBox(height: 8),
          _buildDataSyncSection(
            l10n: l10n,
            familyState: familyState,
            sharedChildDriveSubtitle: sharedChildDriveSubtitle,
            driveMatchesExpected: driveMatchesExpected,
            compact: true,
          ),
        ] else ...[
          const SizedBox(height: 8),
          _buildDriveUnavailableSection(l10n, compact: true),
        ],
      ],
    );
  }

  Widget _buildUsageModeSection({
    required AppLocalizations l10n,
    required FamilyAccessState familyState,
    bool compact = false,
  }) {
    return _buildPrimarySettingsCard(
      title: l10n.settingsUsageModeTitle,
      icon: Icons.manage_accounts_outlined,
      detailsMessage: l10n.familyRoleSelectionDescription,
      detailsTooltip: l10n.settingsInfoTooltip,
      compact: compact,
      children: [
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            ChoiceChip(
              avatar: Icon(_familyRoleIcon(FamilyRole.child), size: 18),
              label: Text(l10n.familyRolePlayer),
              selected: familyState.isChildMode,
              onSelected: (_) {
                if (familyState.isChildMode) return;
                unawaited(_updateFamilyRole(FamilyRole.child));
              },
            ),
            ChoiceChip(
              avatar: Icon(_familyRoleIcon(FamilyRole.parent), size: 18),
              label: Text(l10n.settingsSupportModeLabel),
              selected: familyState.currentRole == FamilyRole.parent,
              onSelected: (_) {
                if (familyState.currentRole == FamilyRole.parent) return;
                unawaited(_updateFamilyRole(FamilyRole.parent));
              },
            ),
            ChoiceChip(
              avatar: Icon(_familyRoleIcon(FamilyRole.coach), size: 18),
              label: Text(l10n.familyRoleCoach),
              selected: familyState.currentRole == FamilyRole.coach,
              onSelected: (_) {
                if (familyState.currentRole == FamilyRole.coach) return;
                unawaited(_updateFamilyRole(FamilyRole.coach));
              },
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildCoachRosterSection(
    AppLocalizations l10n, {
    bool compact = false,
  }) {
    final rosterState = CoachRosterService(widget.optionRepository).loadState();
    final players = rosterState.players;
    return _buildPrimarySettingsCard(
      title: l10n.settingsCoachRosterTitle,
      icon: Icons.groups_2_outlined,
      detailsMessage: l10n.settingsCoachRosterDescription,
      detailsTooltip: l10n.settingsInfoTooltip,
      compact: compact,
      children: [
        if (players.isEmpty)
          Text(
            l10n.settingsCoachRosterEmpty,
            style: Theme.of(context).textTheme.bodyMedium,
          )
        else
          Column(
            children: [
              for (final player in players) ...[
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(
                    player.id == rosterState.activePlayerId
                        ? Icons.check_circle_rounded
                        : Icons.person_outline,
                  ),
                  title: Text(player.displayName),
                  subtitle: Text(
                    player.driveEmail.trim().isEmpty
                        ? l10n.settingsCoachRosterNoDriveAccount
                        : l10n.settingsCoachRosterDriveAccount(
                            player.driveEmail.trim(),
                          ),
                  ),
                  selected: player.id == rosterState.activePlayerId,
                  onTap: () {
                    if (player.id == rosterState.activePlayerId) return;
                    unawaited(_setActiveCoachRosterPlayer(player, l10n));
                  },
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        onPressed: () => _editCoachRosterPlayer(player, l10n),
                        icon: const Icon(Icons.edit_outlined),
                        tooltip: l10n.settingsCoachRosterEditPlayer,
                      ),
                      IconButton(
                        onPressed: players.length <= 1
                            ? null
                            : () => _deleteCoachRosterPlayer(player, l10n),
                        icon: const Icon(Icons.delete_outline),
                        tooltip: l10n.settingsCoachRosterDeletePlayer,
                      ),
                    ],
                  ),
                ),
                if (player != players.last) const Divider(height: 1),
              ],
            ],
          ),
        Align(
          alignment: Alignment.centerLeft,
          child: OutlinedButton.icon(
            onPressed: () => _addCoachRosterPlayer(l10n),
            icon: const Icon(Icons.person_add_alt_1_outlined),
            label: Text(l10n.settingsCoachRosterAddPlayer),
          ),
        ),
      ],
    );
  }

  Future<void> _addCoachRosterPlayer(AppLocalizations l10n) async {
    final trimmedName = await _showCoachRosterPlayerNameDialog(
      l10n,
      title: l10n.settingsCoachRosterAddPlayer,
      initialName: '',
    );
    if (trimmedName == null || trimmedName.isEmpty) return;
    final player = await CoachRosterService(
      widget.optionRepository,
    ).addPlayer(displayName: trimmedName);
    if (!mounted) return;
    setState(() {});
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
          content: Text(l10n.settingsCoachRosterAdded(player.displayName))),
    );
    unawaited(
      _refreshDriveUi(
        allowCachedConnection: true,
        allowRemoteStatusLookup: true,
        showLoading: false,
      ),
    );
  }

  Future<void> _editCoachRosterPlayer(
    CoachPlayerProfile player,
    AppLocalizations l10n,
  ) async {
    final trimmedName = await _showCoachRosterPlayerNameDialog(
      l10n,
      title: l10n.settingsCoachRosterEditPlayer,
      initialName: player.displayName,
    );
    if (trimmedName == null || trimmedName.isEmpty) return;
    final renamed = await CoachRosterService(widget.optionRepository)
        .renamePlayer(playerId: player.id, displayName: trimmedName);
    if (!mounted || renamed == null) return;
    setState(() {});
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(l10n.settingsCoachRosterRenamed(renamed.displayName)),
      ),
    );
  }

  Future<void> _deleteCoachRosterPlayer(
    CoachPlayerProfile player,
    AppLocalizations l10n,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.settingsCoachRosterDeleteTitle),
        content:
            Text(l10n.settingsCoachRosterDeleteMessage(player.displayName)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(l10n.confirm),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    final removed = await CoachRosterService(
      widget.optionRepository,
    ).removePlayer(player.id);
    if (!mounted) return;
    if (!removed) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.settingsCoachRosterLastPlayerRequired)),
      );
      return;
    }
    setState(() {});
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
          content: Text(l10n.settingsCoachRosterDeleted(player.displayName))),
    );
    unawaited(
      _refreshDriveUi(
        allowCachedConnection: true,
        allowRemoteStatusLookup: true,
        showLoading: false,
      ),
    );
  }

  Future<String?> _showCoachRosterPlayerNameDialog(
    AppLocalizations l10n, {
    required String title,
    required String initialName,
  }) async {
    final controller = TextEditingController();
    controller.text = initialName;
    controller.selection = TextSelection.collapsed(
      offset: controller.text.length,
    );
    final playerName = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(title),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: InputDecoration(
            labelText: l10n.settingsCoachRosterPlayerNameLabel,
            hintText: l10n.settingsCoachRosterPlayerNameHint,
          ),
          textInputAction: TextInputAction.done,
          onSubmitted: (value) {
            Navigator.of(dialogContext).pop(value.trim());
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            onPressed: () =>
                Navigator.of(dialogContext).pop(controller.text.trim()),
            child: Text(l10n.confirm),
          ),
        ],
      ),
    );
    controller.dispose();
    return playerName?.trim();
  }

  Future<void> _setActiveCoachRosterPlayer(
    CoachPlayerProfile player,
    AppLocalizations l10n,
  ) async {
    await CoachRosterService(widget.optionRepository).setActivePlayer(
      player.id,
    );
    if (!mounted) return;
    setState(() {});
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(l10n.settingsCoachRosterActivated(player.displayName)),
      ),
    );
    unawaited(
      _refreshDriveUi(
        allowCachedConnection: true,
        allowRemoteStatusLookup: true,
        showLoading: false,
      ),
    );
  }

  Widget _buildDriveUnavailableSection(
    AppLocalizations l10n, {
    bool compact = false,
  }) {
    return _buildPrimarySettingsCard(
      title: l10n.settingsDriveConnectionTitle,
      summary: l10n.settingsRoleAccountUnavailable,
      icon: Icons.cloud_off_outlined,
      compact: compact,
      children: const [],
    );
  }

  Widget _buildDataSyncSection({
    required AppLocalizations l10n,
    required FamilyAccessState familyState,
    required String sharedChildDriveSubtitle,
    required bool driveMatchesExpected,
    bool compact = false,
  }) {
    return _buildPrimarySettingsCard(
      title: l10n.settingsDataSyncTitle,
      icon: Icons.sync_alt_rounded,
      detailsMessage: familyState.isChildMode
          ? l10n.settingsDataSyncPlayerSummary
          : l10n.settingsDataSyncSupportSummary,
      detailsTooltip: l10n.settingsInfoTooltip,
      headerActions: [
        if (_signedIn)
          IconButton(
            onPressed: (_backupBusy ||
                    _restoreBusy ||
                    _playerBackupBlockedBeforeImport(familyState))
                ? null
                : () => _showPreviousBackupRestoreInfo(l10n),
            icon: const Icon(Icons.history_rounded, size: 18),
            tooltip: l10n.restorePreviousBackup,
            visualDensity: VisualDensity.compact,
          ),
      ],
      compact: compact,
      children: familyState.isChildMode
          ? _buildPlayerSyncChildren(l10n, familyState)
          : _buildSupportSyncChildren(
              l10n,
              familyState,
              sharedChildDriveSubtitle: sharedChildDriveSubtitle,
              driveMatchesExpected: driveMatchesExpected,
            ),
    );
  }

  List<Widget> _buildPlayerSyncChildren(
    AppLocalizations l10n,
    FamilyAccessState familyState,
  ) {
    final driveBackupService = widget.driveBackupService!;
    final backupBlockedBeforeImport =
        _playerBackupBlockedBeforeImport(familyState);
    final children = <Widget>[
      _buildCurrentDriveAccountTile(l10n),
    ];
    if (backupBlockedBeforeImport) {
      children.add(_buildDriveBackupLockedWarning(l10n));
    }
    children.add(_buildDriveQuickActions(l10n: l10n, familyState: familyState));
    if (!_signedIn || backupBlockedBeforeImport) {
      return children;
    }
    children.addAll([
      _BackupHealthCard(
        l10n: l10n,
        loading: _driveStatusLoading,
        signedIn: _signedIn,
        autoDaily: _autoDaily,
        autoOnSave: _autoOnSave,
        lastBackupAt: driveBackupService.getLastBackup(),
        localRestoreAt: driveBackupService.getLocalPreRestoreTime(),
        formatBackupTime: _formatBackupTime,
      ),
      SwitchListTile(
        contentPadding: EdgeInsets.zero,
        title: Text(l10n.backupDailyEnabled),
        value: _autoDaily,
        onChanged: (value) async {
          setState(() => _autoDaily = value);
          await driveBackupService.setAutoDailyEnabled(value);
        },
      ),
      SwitchListTile(
        contentPadding: EdgeInsets.zero,
        title: Text(l10n.backupAutoOnSave),
        value: _autoOnSave,
        onChanged: (value) async {
          setState(() => _autoOnSave = value);
          await driveBackupService.setAutoOnSaveEnabled(value);
        },
      ),
    ]);
    return children;
  }

  List<Widget> _buildSupportSyncChildren(
    AppLocalizations l10n,
    FamilyAccessState familyState, {
    required String sharedChildDriveSubtitle,
    required bool driveMatchesExpected,
  }) {
    final driveBackupService = widget.driveBackupService!;
    final hasKnownBackupData = _hasRemotePlayerBackup ||
        _sharedChildDriveLabel.trim().isNotEmpty ||
        _sharedChildDriveEmail.trim().isNotEmpty;
    final children = <Widget>[
      _buildCurrentDriveAccountTile(l10n),
      _buildDriveQuickActions(l10n: l10n, familyState: familyState),
    ];
    if (!_signedIn) {
      return children;
    }
    children.addAll([
      _buildSupportSyncSourceStatus(l10n, sharedChildDriveSubtitle),
      if (!_driveStatusLoading && !driveMatchesExpected)
        _buildDriveMismatchWarning(l10n),
      _BackupHealthCard(
        l10n: l10n,
        loading: _driveStatusLoading,
        signedIn: _signedIn,
        autoDaily: _autoDaily,
        autoOnSave: _autoOnSave,
        lastBackupAt: driveBackupService.getLastFamilySyncPush() ??
            driveBackupService.getLastFamilyRefresh() ??
            driveBackupService.getLastBackup(),
        localRestoreAt: driveBackupService.getLocalPreRestoreTime(),
        backupKnown: hasKnownBackupData,
        formatBackupTime: _formatBackupTime,
      ),
      _buildParentFamilySyncDetails(l10n),
    ]);
    return children;
  }

  Widget _buildDriveQuickActions({
    required AppLocalizations l10n,
    required FamilyAccessState familyState,
  }) {
    if (_driveStatusLoading) {
      return const SizedBox.shrink();
    }
    final isSupportMode = familyState.isSupportMode;
    final backupBlockedBeforeImport =
        _playerBackupBlockedBeforeImport(familyState);
    final actions = <Widget>[
      _buildDriveQuickActionButton(
        icon: _signedIn ? Icons.link_off_outlined : Icons.link_outlined,
        label: _signedIn
            ? l10n.settingsDriveDisconnectAction
            : l10n.settingsDriveConnectAction,
        tone: _signedIn
            ? _DriveQuickActionTone.disconnect
            : _DriveQuickActionTone.connect,
        onPressed: _signInBusy ? null : () => _toggleDriveSignIn(l10n),
      ),
    ];
    if (_shouldShowLatestRestoreAction(familyState)) {
      actions.add(
        _buildDriveQuickActionButton(
          icon: Icons.cloud_download_outlined,
          label: l10n.settingsRestoreLatestActionTitle,
          tone: _DriveQuickActionTone.restore,
          onPressed: (_backupBusy || _restoreBusy)
              ? null
              : () => _restoreFromDrive(
                    l10n,
                    title: l10n.settingsRestoreLatestActionTitle,
                    filePath: DriveBackupService.backupDisplayPath,
                    backupCreatedAt: widget.driveBackupService!.getLastBackup(),
                    message:
                        isSupportMode ? l10n.familySharedRestoreConfirm : null,
                    successMessage:
                        isSupportMode ? l10n.familySharedRestoreSuccess : null,
                    failedMessage:
                        isSupportMode ? l10n.familySharedRestoreFailed : null,
                  ),
        ),
      );
    }
    if (backupBlockedBeforeImport) {
      actions.add(
        _buildDriveQuickActionButton(
          icon: Icons.cloud_download_outlined,
          label: l10n.driveAccountSwitchImportAction,
          tone: _DriveQuickActionTone.restore,
          onPressed: (_backupBusy || _restoreBusy)
              ? null
              : () => _resolveChangedPlayerDrive(
                    l10n,
                    startWithEmptyData: false,
                  ),
        ),
      );
      actions.add(
        _buildDriveQuickActionButton(
          icon: Icons.person_add_alt_1_outlined,
          label: l10n.driveAccountSwitchStartEmptyAction,
          tone: _DriveQuickActionTone.neutral,
          onPressed: (_backupBusy || _restoreBusy)
              ? null
              : () => _resolveChangedPlayerDrive(
                    l10n,
                    startWithEmptyData: true,
                  ),
        ),
      );
    }
    if (_signedIn && !isSupportMode && !backupBlockedBeforeImport) {
      actions.add(
        _buildDriveQuickActionButton(
          icon: Icons.cloud_upload_outlined,
          label: l10n.settingsBackupDataActionTitle,
          tone: _DriveQuickActionTone.backup,
          onPressed: (_backupBusy || _restoreBusy || backupBlockedBeforeImport)
              ? null
              : () => _backupToDrive(
                    l10n,
                    title: l10n.settingsBackupDataActionTitle,
                    filePath: DriveBackupService.backupDisplayPath,
                  ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (var i = 0; i < actions.length; i++) ...[
          actions[i],
          if (i != actions.length - 1) const SizedBox(height: 8),
        ],
      ],
    );
  }

  Widget _buildCurrentDriveAccountTile(AppLocalizations l10n) {
    return _buildDriveAccountTile(
      icon: Icons.cloud_done_outlined,
      title: l10n.driveConnectedAccount,
      subtitle: _driveStatusLoading
          ? l10n.settingsSyncStatusChecking
          : _connectedDriveLabel.trim().isEmpty
              ? l10n.driveConnectedAccountEmpty
              : _connectedDriveLabel.trim(),
      loading: _driveStatusLoading,
    );
  }

  Widget _buildSupportSyncSourceStatus(
    AppLocalizations l10n,
    String sharedChildDriveSubtitle,
  ) {
    return _buildDriveAccountTile(
      icon: Icons.sync_alt_rounded,
      title: l10n.settingsSyncSourceStatusTitle,
      subtitle: sharedChildDriveSubtitle,
      loading: _driveStatusLoading,
    );
  }

  Widget _buildDriveMismatchWarning(AppLocalizations l10n) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(
          context,
        ).colorScheme.errorContainer.withValues(alpha: 0.45),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Text(
        l10n.familyParentUsesChildDriveWarning,
        style: Theme.of(context).textTheme.bodySmall,
      ),
    );
  }

  Widget _buildDriveBackupLockedWarning(AppLocalizations l10n) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(
          context,
        ).colorScheme.errorContainer.withValues(alpha: 0.45),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Text(
        l10n.driveBackupLockedAccountChanged,
        style: Theme.of(context).textTheme.bodySmall,
      ),
    );
  }

  Widget _buildDriveQuickActionButton({
    required IconData icon,
    required String label,
    required VoidCallback? onPressed,
    _DriveQuickActionTone tone = _DriveQuickActionTone.neutral,
  }) {
    return OutlinedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 18),
      label: Text(
        label,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
        textAlign: TextAlign.center,
      ),
      style: _quickActionButtonStyle(tone: tone),
    );
  }

  bool _sameStringList(List<String> a, List<String> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }

  Widget _buildSelectRow<T>({
    required String label,
    required T value,
    required List<T> options,
    required String Function(T value) optionLabel,
    required ValueChanged<T>? onChanged,
    double height = 60,
    double topSpacing = 6,
    double bottomSpacing = 8,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final onSurface = Theme.of(context).colorScheme.onSurface;
    final fillColor =
        isDark ? const Color(0xFF242D3D) : const Color(0xFFF7F8FC);
    final borderColor = isDark
        ? const Color(0xFF4A556D)
        : const Color.fromRGBO(210, 220, 245, 1);
    return Padding(
      padding: EdgeInsets.only(top: topSpacing, bottom: bottomSpacing),
      child: ConstrainedBox(
        constraints: BoxConstraints(minHeight: height),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final availableWidth = constraints.maxWidth.isFinite
                ? constraints.maxWidth
                : MediaQuery.of(context).size.width - 32;
            return DropdownMenu<T>(
              width: availableWidth.clamp(160.0, 720.0),
              enabled: onChanged != null,
              initialSelection: value,
              label: Text(label),
              textStyle: TextStyle(fontSize: 14, color: onSurface),
              inputDecorationTheme: InputDecorationTheme(
                filled: true,
                fillColor: fillColor,
                floatingLabelBehavior: FloatingLabelBehavior.always,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 12,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(color: borderColor, width: 1.2),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(color: borderColor, width: 1.2),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(
                    color: Theme.of(context).colorScheme.primary,
                    width: 1.4,
                  ),
                ),
              ),
              dropdownMenuEntries: options
                  .map(
                    (option) => DropdownMenuEntry(
                      value: option,
                      label: optionLabel(option),
                    ),
                  )
                  .toList(),
              onSelected: onChanged == null
                  ? null
                  : (value) {
                      if (value != null) onChanged(value);
                    },
            );
          },
        ),
      ),
    );
  }

  Widget _buildDefaultsAndOptionManager(
    AppLocalizations l10n, {
    bool readOnly = false,
  }) {
    final sportId = SportService(widget.optionRepository).currentSportId();
    final durationOptionsKey =
        SportCatalog.optionKey('durations', sportId: sportId);
    final defaultDurationKey =
        SportCatalog.optionKey('default_duration', sportId: sportId);
    final injuryPartsKey =
        SportCatalog.optionKey('injury_parts', sportId: sportId);
    final defaultDurationText =
        _defaultDuration <= 0 ? l10n.notSet : l10n.minutes(_defaultDuration);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (readOnly) ...[
          Text(
            l10n.parentReadOnlySettingsOptions,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w700,
                ),
          ),
          const SizedBox(height: 10),
        ],
        Text(
          l10n.defaults,
          style: Theme.of(
            context,
          ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 8),
        _buildDefaultTile(
          l10n: l10n,
          label: l10n.defaultDuration,
          valueText: defaultDurationText,
          onEdit: readOnly ? null : () => _pickDefaultDuration(l10n),
        ),
        _buildDefaultTile(
          l10n: l10n,
          label: l10n.defaultProgram,
          valueText: _defaultProgram,
          onEdit: readOnly
              ? null
              : () => _pickDefaultString(
                    key: SportCatalog.optionKey(
                      'default_program',
                      sportId: SportService(
                        widget.optionRepository,
                      ).currentSportId(),
                    ),
                    current: _defaultProgram,
                    options: _programOptions,
                    title: l10n.defaultProgram,
                    onChanged: (value) =>
                        setState(() => _defaultProgram = value),
                  ),
        ),
        const SizedBox(height: 12),
        const Divider(height: 1),
        const SizedBox(height: 12),
        Text(
          l10n.settingsJournalOptionManagerTitle,
          style: Theme.of(
            context,
          ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 8),
        _buildOptionManagerTile(
          title: l10n.settingsDurationOptionsTitle,
          subtitle: l10n.settingsOptionItemsCount(
            _durationOptions.where((e) => e > 0).length,
          ),
          onTap: readOnly
              ? null
              : () => _manageIntOptions(
                    key: durationOptionsKey,
                    title: l10n.settingsDurationOptionsManageTitle,
                    options: _durationOptions,
                    minKeep: 1,
                    formatLabel: (value) =>
                        value <= 0 ? l10n.notSet : l10n.minutes(value),
                    onSaved: (updated) async {
                      setState(() => _durationOptions = updated);
                      if (!_durationOptions.contains(_defaultDuration)) {
                        final fallback = _durationOptions.first;
                        await widget.optionRepository.setValue(
                          defaultDurationKey,
                          fallback,
                        );
                        if (!mounted) return;
                        setState(() => _defaultDuration = fallback);
                      }
                    },
                  ),
        ),
        _buildOptionManagerTile(
          title: l10n.settingsProgramOptionsTitle,
          subtitle: l10n.settingsOptionItemsCount(_programOptions.length),
          onTap: readOnly ? null : () => _manageProgramOptions(),
        ),
        _buildOptionManagerTile(
          title: l10n.settingsTrainingGoalOptionsTitle,
          subtitle: l10n.settingsOptionItemsCount(_dailyGoalOptions.length),
          onTap: readOnly
              ? null
              : () => _manageStringOptions(
                    key: SportCatalog.optionKey(
                      'daily_goals',
                      sportId: SportService(
                        widget.optionRepository,
                      ).currentSportId(),
                    ),
                    title: l10n.settingsTrainingGoalOptionsManageTitle,
                    options: _dailyGoalOptions,
                    minKeep: 1,
                    onSaved: (updated) async {
                      setState(() => _dailyGoalOptions = updated);
                    },
                  ),
        ),
        _buildOptionManagerTile(
          title: l10n.settingsInjuryPartOptionsTitle,
          subtitle: l10n.settingsOptionItemsCount(_injuryPartOptions.length),
          onTap: readOnly
              ? null
              : () => _manageStringOptions(
                    key: injuryPartsKey,
                    title: l10n.settingsInjuryPartOptionsManageTitle,
                    options: _injuryPartOptions,
                    minKeep: 1,
                    onSaved: (updated) async {
                      setState(() => _injuryPartOptions = updated);
                    },
                  ),
        ),
      ],
    );
  }

  Widget _buildDefaultTile({
    required AppLocalizations l10n,
    required String label,
    required String valueText,
    required Future<void> Function()? onEdit,
  }) {
    return ListTile(
      dense: true,
      contentPadding: EdgeInsets.zero,
      title: Text(label),
      subtitle: Text(valueText),
      trailing: IconButton(
        icon: const Icon(Icons.edit_outlined),
        tooltip: l10n.edit,
        onPressed: onEdit,
      ),
    );
  }

  Widget _buildOptionManagerTile({
    required String title,
    required String subtitle,
    required Future<void> Function()? onTap,
  }) {
    final enabled = onTap != null;
    final scheme = Theme.of(context).colorScheme;
    return ListTile(
      enabled: enabled,
      dense: true,
      contentPadding: EdgeInsets.zero,
      title: Text(title),
      subtitle: Text(subtitle),
      trailing: Icon(
        Icons.chevron_right,
        color: enabled
            ? scheme.onSurfaceVariant
            : scheme.onSurface.withValues(alpha: 0.32),
      ),
      onTap: onTap,
    );
  }

  Future<void> _manageProgramOptions() async {
    final l10n = AppLocalizations.of(context)!;
    final sportId = SportService(widget.optionRepository).currentSportId();
    await _manageStringOptions(
      key: SportCatalog.optionKey('programs', sportId: sportId),
      title: l10n.settingsProgramOptionsManageTitle,
      options: _programOptions,
      minKeep: 1,
      onSaved: (updated) async {
        setState(() => _programOptions = updated);
        if (!_programOptions.contains(_defaultProgram)) {
          final fallback = _programOptions.first;
          await widget.optionRepository.setValue(
            SportCatalog.optionKey('default_program', sportId: sportId),
            fallback,
          );
          if (!mounted) return;
          setState(() => _defaultProgram = fallback);
        }
      },
    );
  }

  Future<void> _pickDefaultDuration(AppLocalizations l10n) async {
    final sportId = SportService(widget.optionRepository).currentSportId();
    await _pickDefaultInt(
      key: SportCatalog.optionKey('default_duration', sportId: sportId),
      current: _defaultDuration,
      options: _durationOptions,
      title: l10n.defaultDuration,
      labelBuilder: (value) => value <= 0 ? l10n.notSet : l10n.minutes(value),
      onChanged: (value) => setState(() => _defaultDuration = value),
    );
  }

  Future<void> _pickDefaultInt({
    required String key,
    required int current,
    required List<int> options,
    required String title,
    required String Function(int value) labelBuilder,
    required ValueChanged<int> onChanged,
  }) async {
    final selected = await showModalBottomSheet<int>(
      context: context,
      showDragHandle: true,
      builder: (context) {
        return SafeArea(
          child: ListView(
            shrinkWrap: true,
            children: options
                .map(
                  (option) => ListTile(
                    title: Text(labelBuilder(option)),
                    trailing: option == current
                        ? const Icon(Icons.check_circle)
                        : const Icon(Icons.circle_outlined),
                    onTap: () => Navigator.of(context).pop(option),
                  ),
                )
                .toList(growable: false),
          ),
        );
      },
    );
    if (selected == null) return;
    await widget.optionRepository.setValue(key, selected);
    onChanged(selected);
  }

  Future<void> _pickDefaultString({
    required String key,
    required String current,
    required List<String> options,
    required String title,
    required ValueChanged<String> onChanged,
  }) async {
    final selected = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      builder: (context) {
        return SafeArea(
          child: ListView(
            shrinkWrap: true,
            children: options
                .map(
                  (option) => ListTile(
                    title: Text(option),
                    trailing: option == current
                        ? const Icon(Icons.check_circle)
                        : const Icon(Icons.circle_outlined),
                    onTap: () => Navigator.of(context).pop(option),
                  ),
                )
                .toList(growable: false),
          ),
        );
      },
    );
    if (selected == null) return;
    await widget.optionRepository.setValue(key, selected);
    onChanged(selected);
  }

  Future<void> _manageStringOptions({
    required String key,
    required String title,
    required List<String> options,
    required int minKeep,
    required Future<void> Function(List<String> updated) onSaved,
    String Function(String value)? sanitize,
  }) async {
    var working = [...options];
    final l10n = AppLocalizations.of(context)!;
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return SafeArea(
              child: Padding(
                padding: EdgeInsets.fromLTRB(
                  16,
                  8,
                  16,
                  12 + MediaQuery.of(context).viewInsets.bottom,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(title, style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: working
                          .map(
                            (option) => InputChip(
                              label: Text(option),
                              onPressed: () async {
                                final edited = await _showTextInputDialog(
                                  title: l10n.settingsOptionEditTitle,
                                  initial: option,
                                );
                                if (edited == null || edited.isEmpty) return;
                                final normalized = sanitize == null
                                    ? edited
                                    : sanitize(edited);
                                if (normalized.isEmpty) return;
                                setSheetState(() {
                                  final index = working.indexOf(option);
                                  if (index >= 0) working[index] = normalized;
                                });
                              },
                              onDeleted: working.length <= minKeep
                                  ? null
                                  : () {
                                      setSheetState(() {
                                        working.remove(option);
                                      });
                                    },
                              deleteIcon: const Icon(Icons.delete_outline),
                            ),
                          )
                          .toList(growable: false),
                    ),
                    const SizedBox(height: 10),
                    OutlinedButton.icon(
                      onPressed: () async {
                        final added = await _showTextInputDialog(
                          title: l10n.settingsOptionAddTitle,
                        );
                        if (added == null || added.isEmpty) return;
                        final normalized =
                            sanitize == null ? added : sanitize(added);
                        if (normalized.isEmpty ||
                            working.contains(normalized)) {
                          return;
                        }
                        setSheetState(() => working.add(normalized));
                      },
                      icon: const Icon(Icons.add),
                      label: Text(l10n.add),
                    ),
                    const SizedBox(height: 10),
                    FilledButton(
                      onPressed: () async {
                        if (working.length < minKeep) return;
                        await widget.optionRepository.saveOptions(key, working);
                        await onSaved(working);
                        if (!context.mounted) return;
                        Navigator.of(context).pop();
                      },
                      child: Text(l10n.save),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _manageIntOptions({
    required String key,
    required String title,
    required List<int> options,
    required int minKeep,
    required String Function(int value) formatLabel,
    required Future<void> Function(List<int> updated) onSaved,
  }) async {
    var working = [...options];
    final l10n = AppLocalizations.of(context)!;
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return SafeArea(
              child: Padding(
                padding: EdgeInsets.fromLTRB(
                  16,
                  8,
                  16,
                  12 + MediaQuery.of(context).viewInsets.bottom,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(title, style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: working
                          .map(
                            (option) => InputChip(
                              label: Text(formatLabel(option)),
                              onPressed: () async {
                                final edited = await _showTextInputDialog(
                                  title: l10n.settingsIntOptionEditTitle,
                                  initial: option.toString(),
                                  number: true,
                                );
                                final parsed = int.tryParse(edited ?? '');
                                if (parsed == null || parsed < 0) return;
                                setSheetState(() {
                                  final index = working.indexOf(option);
                                  if (index >= 0) working[index] = parsed;
                                });
                              },
                              onDeleted: working.length <= minKeep
                                  ? null
                                  : () {
                                      setSheetState(() {
                                        working.remove(option);
                                      });
                                    },
                              deleteIcon: const Icon(Icons.delete_outline),
                            ),
                          )
                          .toList(growable: false),
                    ),
                    const SizedBox(height: 10),
                    OutlinedButton.icon(
                      onPressed: () async {
                        final added = await _showTextInputDialog(
                          title: l10n.settingsIntOptionAddTitle,
                          number: true,
                        );
                        final parsed = int.tryParse(added ?? '');
                        if (parsed == null ||
                            parsed < 0 ||
                            working.contains(parsed)) {
                          return;
                        }
                        setSheetState(() => working.add(parsed));
                      },
                      icon: const Icon(Icons.add),
                      label: Text(l10n.add),
                    ),
                    const SizedBox(height: 10),
                    FilledButton(
                      onPressed: () async {
                        if (working.length < minKeep) return;
                        final updated = [...working]..sort();
                        await widget.optionRepository.saveOptions(key, updated);
                        await onSaved(updated);
                        if (!context.mounted) return;
                        Navigator.of(context).pop();
                      },
                      child: Text(l10n.save),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Future<String?> _showTextInputDialog({
    required String title,
    String initial = '',
    bool number = false,
  }) async {
    final controller = TextEditingController(text: initial);
    final l10n = AppLocalizations.of(context)!;
    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: TextField(
          controller: controller,
          autofocus: true,
          keyboardType: number ? TextInputType.number : TextInputType.text,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(l10n.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(controller.text.trim()),
            child: Text(l10n.confirm),
          ),
        ],
      ),
    );
    return result?.trim();
  }

  Future<void> _showSettingsInfoDialog({
    required String title,
    required String message,
  }) async {
    final l10n = AppLocalizations.of(context)!;
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: Text(l10n.confirm),
          ),
        ],
      ),
    );
  }

  Future<void> _updateFamilyRole(FamilyRole role) async {
    final targetRole = role;
    final familyService = FamilyAccessService(widget.optionRepository);
    final currentState = familyService.loadState();
    final roleHandledByBackup =
        await widget.driveBackupService?.setCurrentFamilyRole(targetRole) ??
            false;
    if (!roleHandledByBackup) {
      await familyService.setCurrentRole(targetRole);
    }
    if (targetRole == FamilyRole.coach) {
      await CoachRosterService(widget.optionRepository).ensureActivePlayer();
    }
    if (!mounted) return;
    _scrollToTopAfterLayout();
    setState(() {});
    final l10n = AppLocalizations.of(context)!;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          l10n.familyRoleActivated(_familyRoleLabel(l10n, targetRole)),
        ),
      ),
    );
    unawaited(
      _completeFamilyRoleSwitchSideEffects(
        previousState: currentState,
        targetRole: targetRole,
      ),
    );
  }

  Future<void> _completeFamilyRoleSwitchSideEffects({
    required FamilyAccessState previousState,
    required FamilyRole targetRole,
  }) async {
    try {
      if (widget.driveBackupService != null && _signedIn) {
        if (previousState.isChildMode &&
            FamilyAccessService.isSupportRole(targetRole)) {
          await widget.driveBackupService!.rememberRecordDriveConnection();
        } else if (previousState.isSupportMode &&
            targetRole == FamilyRole.child) {
          await widget.driveBackupService!.rememberParentDriveConnection();
          await widget.driveBackupService!.signOut();
        }
      }
      if (widget.driveBackupService != null &&
          FamilyAccessService.isSupportRole(targetRole)) {
        await _refreshParentSharedDataIfNeeded();
      }
      if (!mounted) return;
      await _refreshDriveUi(
        allowCachedConnection: true,
        allowRemoteStatusLookup: FamilyAccessService.isSupportRole(targetRole),
        showLoading: false,
      );
    } catch (e, st) {
      debugPrint('Family role side effects failed: $e');
      debugPrintStack(stackTrace: st);
    }
  }

  String _familyRoleLabel(AppLocalizations l10n, FamilyRole role) {
    return switch (role) {
      FamilyRole.child => l10n.familyRolePlayer,
      FamilyRole.parent => l10n.settingsSupportModeLabel,
      FamilyRole.coach => l10n.familyRoleCoach,
    };
  }

  IconData _familyRoleIcon(FamilyRole role) {
    return switch (role) {
      FamilyRole.child => Icons.sports_soccer_outlined,
      FamilyRole.parent => Icons.family_restroom_outlined,
      FamilyRole.coach => Icons.co_present_outlined,
    };
  }

  String _normalizeDomain(String input) {
    final raw = input.trim().toLowerCase();
    if (raw.isEmpty) return '';
    final withScheme = raw.contains('://') ? raw : 'https://$raw';
    final parsed = Uri.tryParse(withScheme);
    final host = parsed?.host.toLowerCase().trim() ?? raw;
    if (host.isEmpty) return '';
    return host;
  }

  Future<void> _changeCurrentSport(String sportId) async {
    final familyState = FamilyAccessService(
      widget.optionRepository,
    ).loadState();
    if (familyState.isSupportMode) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            AppLocalizations.of(context)!.parentReadOnlySettingsOptions,
          ),
        ),
      );
      return;
    }
    final normalizedSportId = SportCatalog.normalizeSportId(sportId);
    final controller = SportScope.read(context);
    final changed = controller == null
        ? await _setSportWithoutController(normalizedSportId)
        : await controller.setCurrentSportId(normalizedSportId);
    if (!changed) return;
    NewsBadgeService.clearUnreadCount();
    unawaited(NewsBadgeService.refresh(widget.optionRepository, force: true));
    if (!mounted) return;
    setState(() {});
    final navigator = Navigator.maybeOf(context);
    if (navigator != null && navigator.canPop()) {
      navigator.popUntil((route) => route.isFirst);
    }
  }

  Future<bool> _setSportWithoutController(String sportId) async {
    final service = SportService(widget.optionRepository);
    final normalizedSportId = SportCatalog.normalizeSportId(sportId);
    if (service.currentSportId() == normalizedSportId) {
      return false;
    }
    await service.setCurrentSportId(normalizedSportId);
    return true;
  }

  List<String> _defaultDailyGoals(AppLocalizations l10n, {String? sportId}) {
    return SportDefaults.dailyGoals(
      l10n: l10n,
      sportId:
          sportId ?? SportService(widget.optionRepository).currentSportId(),
    );
  }

  Widget _buildDriveAccountTile({
    required IconData icon,
    required String title,
    required String subtitle,
    bool loading = false,
  }) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: loading
          ? const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : Icon(icon, size: 20),
      title: Text(title),
      subtitle: Text(subtitle),
    );
  }

  Widget _buildParentFamilySyncDetails(AppLocalizations l10n) {
    final lastPushAt = widget.driveBackupService?.getLastFamilySyncPush();
    final lastPullAt = widget.driveBackupService?.getLastFamilyRefresh();
    final hasPendingChanges =
        widget.driveBackupService?.hasPendingParentSharedChanges() ?? false;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (hasPendingChanges) ...[
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.errorContainer,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Text(
              l10n.familySharedPendingLocalChanges,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
        ],
        if (lastPushAt != null) ...[
          if (hasPendingChanges) const SizedBox(height: 8),
          _buildDriveAccountTile(
            icon: Icons.history,
            title: l10n.familySharedLastPush,
            subtitle: _formatBackupTime(lastPushAt),
          ),
        ],
        if (lastPullAt != null) ...[
          if (hasPendingChanges || lastPushAt != null)
            const SizedBox(height: 8),
          _buildDriveAccountTile(
            icon: Icons.refresh_outlined,
            title: l10n.familySharedLastRefresh,
            subtitle: _formatBackupTime(lastPullAt),
          ),
        ],
      ],
    );
  }

  ButtonStyle _quickActionButtonStyle({
    _DriveQuickActionTone tone = _DriveQuickActionTone.neutral,
  }) {
    final scheme = Theme.of(context).colorScheme;
    final color = switch (tone) {
      _DriveQuickActionTone.disconnect => scheme.error,
      _DriveQuickActionTone.connect => Colors.green.shade700,
      _DriveQuickActionTone.restore => scheme.primary,
      _DriveQuickActionTone.backup => scheme.tertiary,
      _DriveQuickActionTone.neutral => WatchCartConstants.primaryColor,
    };
    return ButtonStyle(
      minimumSize: WidgetStateProperty.all(const Size(0, 54)),
      padding: WidgetStateProperty.all(
        const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      ),
      textStyle: WidgetStateProperty.all(
        const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
      ),
      shape: WidgetStateProperty.all(
        RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
      foregroundColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.disabled)) {
          return scheme.onSurface.withValues(alpha: 0.38);
        }
        return color;
      }),
      side: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.disabled)) {
          return BorderSide(
            color: scheme.onSurface.withValues(alpha: 0.12),
            width: 1.2,
          );
        }
        if (states.contains(WidgetState.pressed)) {
          return BorderSide(color: color, width: 1.8);
        }
        return BorderSide(color: color.withValues(alpha: 0.58), width: 1.2);
      }),
      backgroundColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.disabled)) {
          return scheme.surfaceContainerLowest;
        }
        if (states.contains(WidgetState.pressed)) {
          return color.withValues(alpha: 0.10);
        }
        return null;
      }),
      overlayColor: WidgetStateProperty.all(color.withValues(alpha: 0.08)),
      splashFactory: InkRipple.splashFactory,
    );
  }

  Future<void> _backupToDrive(
    AppLocalizations l10n, {
    String? title,
    String? message,
    String? successMessage,
    String? failedMessage,
    String? filePath,
  }) async {
    if (widget.driveBackupService == null) return;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title ?? l10n.backupToDrive),
        content: Text(
          _driveActionDialogMessage(
            l10n: l10n,
            message: message ?? l10n.backupConfirm,
            filePath: filePath,
            includeBackupTime: false,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(l10n.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(l10n.confirm),
          ),
        ],
      ),
    );
    if (confirm != true) return;
    if (!mounted) return;
    setState(() => _backupBusy = true);
    unawaited(
      _runBackupToDrive(
        l10n,
        successMessage: successMessage,
        failedMessage: failedMessage,
      ),
    );
  }

  Future<void> _runBackupToDrive(
    AppLocalizations l10n, {
    String? successMessage,
    String? failedMessage,
  }) async {
    try {
      await widget.driveBackupService!.backup();
      await _refreshSignInState();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(successMessage ?? l10n.backupSuccess)),
      );
    } catch (e, st) {
      debugPrint('Drive backup failed: $e');
      debugPrintStack(stackTrace: st);
      if (!mounted) return;
      final message = e.toString().contains('sign-in') ||
              e.toString().contains('Sign in') ||
              e.toString().contains('cancelled')
          ? l10n.loginRequired
          : _driveFailureMessage(
              l10n,
              e,
              fallback: failedMessage ?? l10n.backupFailed,
            );
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(message)));
    } finally {
      if (mounted) {
        setState(() => _backupBusy = false);
      }
    }
  }

  Future<void> _toggleDriveSignIn(AppLocalizations l10n) async {
    if (widget.driveBackupService == null) return;
    final wasSignedIn = _signedIn;
    setState(() => _signInBusy = true);
    try {
      if (wasSignedIn) {
        await widget.driveBackupService!.rememberCurrentRoleDriveConnection();
        await widget.driveBackupService!.signOut();
      } else {
        await widget.driveBackupService!.signIn();
        await _rememberSignedInDriveConnectionIfSafe();
      }
      await _refreshDriveUi(
        allowCachedConnection: !wasSignedIn,
        refreshParentSharedData: !wasSignedIn,
        allowRemoteStatusLookup: true,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(wasSignedIn ? l10n.signOutDone : l10n.signInWithGoogle),
        ),
      );
    } catch (e, st) {
      debugPrint('Drive sign-in toggle failed: $e');
      debugPrintStack(stackTrace: st);
      await _refreshDriveUi(
        allowCachedConnection: true,
        refreshParentSharedData: !wasSignedIn,
        allowRemoteStatusLookup: true,
      );
      if (!mounted) return;
      if (_signedIn || _connectedDriveLabel.trim().isNotEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              wasSignedIn ? l10n.signOutDone : l10n.signInWithGoogle,
            ),
          ),
        );
      } else {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(l10n.loginRequired)));
      }
    } finally {
      if (mounted) {
        setState(() => _signInBusy = false);
      }
    }
  }

  Future<void> _rememberSignedInDriveConnectionIfSafe() async {
    final backup = widget.driveBackupService;
    if (backup == null) return;
    if (backup.hasChangedPlayerDriveConnection()) {
      return;
    }
    final familyState = FamilyAccessService(
      widget.optionRepository,
    ).loadState();
    if (familyState.isChildMode && _savedPlayerDriveLabel().isEmpty) {
      return;
    }
    await backup.rememberCurrentRoleDriveConnection();
  }

  Future<void> _restoreFromDrive(
    AppLocalizations l10n, {
    String? title,
    String? message,
    String? successMessage,
    String? failedMessage,
    Future<void> Function()? restoreAction,
    String? filePath,
    DateTime? backupCreatedAt,
  }) async {
    if (widget.driveBackupService == null) return;
    final confirm = await _confirmRestoreAction(
      l10n: l10n,
      title: title ?? l10n.restoreFromDrive,
      message: _driveActionDialogMessage(
        l10n: l10n,
        message: message ?? l10n.restoreConfirm,
        filePath: filePath,
        backupCreatedAt: backupCreatedAt,
        includeBackupTime: true,
      ),
    );
    if (confirm != true) return;
    if (!mounted) return;
    setState(() => _restoreBusy = true);
    final action = restoreAction ?? widget.driveBackupService!.restoreLatest;
    unawaited(
      _runRestoreFromDrive(
        l10n,
        restoreAction: action,
        successMessage: successMessage,
        failedMessage: failedMessage,
      ),
    );
  }

  Future<void> _runRestoreFromDrive(
    AppLocalizations l10n, {
    required Future<void> Function() restoreAction,
    String? successMessage,
    String? failedMessage,
  }) async {
    try {
      await restoreAction();
      widget.localeService.load();
      widget.settingsService.load();
      await _refreshDriveUi(
        allowCachedConnection: true,
        allowRemoteStatusLookup: true,
        showLoading: false,
      );
      if (!mounted) return;
      setState(() {});
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(successMessage ?? l10n.restoreSuccess)),
      );
    } catch (e, st) {
      debugPrint('Drive restore failed: $e');
      debugPrintStack(stackTrace: st);
      if (!mounted) return;
      final message = e.toString().contains('sign-in') ||
              e.toString().contains('Sign in') ||
              e.toString().contains('cancelled')
          ? l10n.loginRequired
          : _driveFailureMessage(
              l10n,
              e,
              fallback: failedMessage ?? l10n.restoreFailed,
            );
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(message)));
    } finally {
      if (mounted) {
        setState(() => _restoreBusy = false);
      }
    }
  }

  Future<void> _resolveChangedPlayerDrive(
    AppLocalizations l10n, {
    required bool startWithEmptyData,
  }) async {
    final backup = widget.driveBackupService;
    if (backup == null) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          startWithEmptyData
              ? l10n.driveAccountSwitchStartEmptyTitle
              : l10n.driveAccountSwitchImportTitle,
        ),
        content: Text(
          startWithEmptyData
              ? l10n.driveAccountSwitchStartEmptyBody
              : l10n.driveAccountSwitchImportBody,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(l10n.cancel),
          ),
          FilledButton.icon(
            onPressed: () => Navigator.of(context).pop(true),
            icon: Icon(
              startWithEmptyData
                  ? Icons.person_add_alt_1_outlined
                  : Icons.cloud_download_outlined,
            ),
            label: Text(
              startWithEmptyData
                  ? l10n.driveAccountSwitchStartEmptyAction
                  : l10n.driveAccountSwitchImportAction,
            ),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    setState(() => _restoreBusy = true);
    try {
      if (startWithEmptyData) {
        await backup.startChangedPlayerDriveWithEmptyData();
      } else {
        await backup.importChangedPlayerDriveBackup();
      }
      widget.localeService.load();
      widget.settingsService.load();
      if (!mounted) return;
      SportScope.read(context)?.reloadFromStorage();
      await _refreshDriveUi(
        allowCachedConnection: true,
        allowRemoteStatusLookup: true,
        showLoading: false,
      );
      if (!mounted) return;
      setState(() {});
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            startWithEmptyData
                ? l10n.driveAccountSwitchStartEmptySuccess
                : l10n.driveAccountSwitchImportSuccess,
          ),
        ),
      );
    } catch (e, st) {
      debugPrint('Drive changed player account resolution failed: $e');
      debugPrintStack(stackTrace: st);
      if (!mounted) return;
      final message = _driveFailureMessage(
        l10n,
        e,
        fallback: startWithEmptyData
            ? l10n.driveAccountSwitchStartEmptyFailed
            : l10n.driveAccountSwitchImportFailed,
      );
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(message)));
    } finally {
      if (mounted) {
        setState(() => _restoreBusy = false);
      }
    }
  }

  Future<void> _showPreviousBackupRestoreInfo(AppLocalizations l10n) async {
    final familyState =
        FamilyAccessService(widget.optionRepository).loadState();
    if (_playerBackupBlockedBeforeImport(familyState)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.driveBackupLockedAccountChanged)),
      );
      return;
    }
    final runRestore = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.restorePreviousBackup),
        content: Text(l10n.restorePreviousBackupInfo),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(l10n.cancel),
          ),
          FilledButton.icon(
            onPressed: () => Navigator.of(context).pop(true),
            icon: const Icon(Icons.settings_backup_restore_outlined),
            label: Text(l10n.restorePreviousBackup),
          ),
        ],
      ),
    );
    if (runRestore != true || !mounted) return;
    await _restoreFromDrive(
      l10n,
      title: l10n.restorePreviousBackup,
      filePath: DriveBackupService.previousBackupDisplayPath,
      backupCreatedAt: widget.driveBackupService!.getPreviousBackupCreatedAt(),
      message: l10n.restorePreviousConfirm,
      successMessage: l10n.restorePreviousSuccess,
      failedMessage: l10n.restorePreviousFailed,
      restoreAction: widget.driveBackupService!.restorePreviousBackup,
    );
  }

  String _formatBackupTime(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);
    final l10n = AppLocalizations.of(context)!;

    if (diff.inMinutes < 1) {
      return l10n.timeJustNow;
    }
    if (diff.inMinutes < 60) {
      return l10n.timeMinutesAgo(diff.inMinutes);
    }
    if (diff.inHours < 24) {
      return l10n.timeHoursAgo(diff.inHours);
    }
    if (_isYesterday(date, now)) {
      return l10n.timeYesterday;
    }
    final locale = Localizations.localeOf(context).toString();
    return DateFormat.yMMMd(locale).format(date);
  }

  String _formatBackupTimestamp(DateTime date) {
    final locale = Localizations.localeOf(context).toString();
    return DateFormat.yMMMd(locale).add_Hm().format(date.toLocal());
  }

  String _driveActionDialogMessage({
    required AppLocalizations l10n,
    required String message,
    String? filePath,
    DateTime? backupCreatedAt,
    bool includeBackupTime = false,
  }) {
    final lines = <String>[message];
    final path = filePath?.trim();
    if (path != null && path.isNotEmpty) {
      lines.add(l10n.settingsDriveActionFilePath(path));
    }
    if (backupCreatedAt != null) {
      lines.add(
        l10n.settingsDriveActionBackupTime(
          _formatBackupTimestamp(backupCreatedAt),
        ),
      );
    } else if (includeBackupTime) {
      lines.add(l10n.settingsDriveActionBackupTimeUnknown);
    }
    return lines.join('\n\n');
  }

  String _driveFailureMessage(
    AppLocalizations l10n,
    Object error, {
    required String fallback,
  }) {
    final raw = error.toString();
    if (raw.contains(DriveBackupService.unsupportedBackupVersionErrorCode)) {
      return l10n.backupVersionUnsupported;
    }
    if (raw.contains(DriveBackupService.invalidBackupPayloadErrorCode)) {
      return l10n.backupPayloadInvalid;
    }
    if (raw
        .contains(DriveBackupService.changedPlayerDriveConnectionErrorCode)) {
      return l10n.driveBackupLockedAccountChanged;
    }
    if (raw.contains(
      DriveBackupService.changedPlayerRemoteBackupMissingErrorCode,
    )) {
      return l10n.driveAccountSwitchNoRemoteBackup;
    }
    if (raw.contains('parent_drive_mismatch')) {
      return l10n.familyParentUsesChildDriveWarning;
    }
    if (raw.contains(DriveBackupService.playerDriveMismatchErrorCode)) {
      return l10n.driveReconnectSavedPlayerMismatch;
    }
    if (raw.contains(DriveBackupService.parentModeDriveMismatchErrorCode)) {
      return l10n.driveReconnectSavedParentMismatch;
    }
    if (raw.contains('parent_family_mismatch')) {
      return l10n.familyParentFamilyMismatch;
    }
    return fallback;
  }

  bool _isYesterday(DateTime date, DateTime now) {
    final yesterday = DateTime(
      now.year,
      now.month,
      now.day,
    ).subtract(const Duration(days: 1));
    return date.year == yesterday.year &&
        date.month == yesterday.month &&
        date.day == yesterday.day;
  }

  Future<bool> _confirmRestoreAction({
    required AppLocalizations l10n,
    required String title,
    required String message,
  }) async {
    final firstConfirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(l10n.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(l10n.confirm),
          ),
        ],
      ),
    );
    if (firstConfirm != true) return false;
    if (!mounted) return false;
    final secondConfirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.restoreReconfirmTitle),
        content: Text(l10n.restoreReconfirmBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(l10n.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(l10n.confirm),
          ),
        ],
      ),
    );
    return secondConfirm == true;
  }
}

class _BackupHealthCard extends StatefulWidget {
  final AppLocalizations l10n;
  final bool loading;
  final bool signedIn;
  final bool autoDaily;
  final bool autoOnSave;
  final DateTime? lastBackupAt;
  final DateTime? localRestoreAt;
  final bool backupKnown;
  final String Function(DateTime value) formatBackupTime;

  const _BackupHealthCard({
    required this.l10n,
    this.loading = false,
    required this.signedIn,
    required this.autoDaily,
    required this.autoOnSave,
    required this.lastBackupAt,
    required this.localRestoreAt,
    this.backupKnown = false,
    required this.formatBackupTime,
  });

  @override
  State<_BackupHealthCard> createState() => _BackupHealthCardState();
}

class _BackupHealthCardState extends State<_BackupHealthCard> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final healthLabel = _healthLabel();
    final healthColor = _healthColor(theme);
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: healthColor.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: healthColor.withValues(alpha: 0.24)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              widget.loading
                  ? SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: healthColor,
                      ),
                    )
                  : Icon(
                      Icons.verified_user_outlined,
                      color: healthColor,
                      size: 20,
                    ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  widget.l10n.settingsSyncStatusTitle,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              Text(
                healthLabel,
                style: theme.textTheme.labelLarge?.copyWith(
                  color: healthColor,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(_summary(), style: theme.textTheme.bodyMedium),
          const SizedBox(height: 8),
          TextButton.icon(
            onPressed: () => setState(() => _expanded = !_expanded),
            icon: Icon(
              _expanded ? Icons.expand_less : Icons.expand_more,
              color: healthColor,
            ),
            label: Text(
              _expanded
                  ? widget.l10n.settingsSyncHideDetails
                  : widget.l10n.settingsSyncShowDetails,
              style: theme.textTheme.labelLarge?.copyWith(
                color: healthColor,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          if (_expanded) ...[
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _InfoPill(
                  label: widget.signedIn
                      ? widget.l10n.settingsSyncGoogleConnected
                      : widget.l10n.settingsSyncGoogleDisconnected,
                ),
                _InfoPill(
                  label: widget.autoDaily
                      ? widget.l10n.settingsSyncDailyOn
                      : widget.l10n.settingsSyncDailyOff,
                ),
                _InfoPill(
                  label: widget.autoOnSave
                      ? widget.l10n.settingsSyncOnSaveOn
                      : widget.l10n.settingsSyncOnSaveOff,
                ),
              ],
            ),
            const SizedBox(height: 10),
            if (widget.lastBackupAt != null) ...[
              Text(
                widget.l10n.settingsSyncBackedUpDataTime(
                  widget.formatBackupTime(widget.lastBackupAt!),
                ),
                style: theme.textTheme.bodySmall,
              ),
            ],
            if (widget.localRestoreAt != null) ...[
              const SizedBox(height: 4),
              Text(
                widget.l10n.settingsSyncCurrentDataSnapshot(
                  widget.formatBackupTime(widget.localRestoreAt!),
                ),
                style: theme.textTheme.bodySmall,
              ),
            ],
          ],
        ],
      ),
    );
  }

  String _healthLabel() {
    if (widget.loading) {
      return widget.l10n.settingsSyncStatusChecking;
    }
    if (!widget.signedIn) {
      return widget.l10n.settingsSyncStatusSignInNeeded;
    }
    if (!_hasKnownBackup) {
      return widget.l10n.settingsSyncStatusNoBackup;
    }
    if (widget.lastBackupAt == null) {
      return widget.l10n.settingsSyncStatusReview;
    }
    final age = DateTime.now().difference(widget.lastBackupAt!);
    if (age <= const Duration(hours: 24)) {
      return widget.l10n.settingsSyncStatusCurrent;
    }
    if (age <= const Duration(days: 3)) {
      return widget.l10n.settingsSyncStatusReview;
    }
    return widget.l10n.settingsSyncStatusStale;
  }

  Color _healthColor(ThemeData theme) {
    if (widget.loading) {
      return theme.colorScheme.primary;
    }
    if (!widget.signedIn || !_hasKnownBackup) {
      return theme.colorScheme.error;
    }
    if (widget.lastBackupAt == null) {
      return Colors.orange.shade700;
    }
    final age = DateTime.now().difference(widget.lastBackupAt!);
    if (age <= const Duration(hours: 24)) {
      return Colors.green.shade700;
    }
    if (age <= const Duration(days: 3)) {
      return Colors.orange.shade700;
    }
    return theme.colorScheme.error;
  }

  String _summary() {
    if (widget.loading) {
      return widget.l10n.settingsSyncSummaryChecking;
    }
    if (!widget.signedIn) {
      return widget.l10n.settingsSyncSummarySignInNeeded;
    }
    if (!_hasKnownBackup) {
      return widget.l10n.settingsSyncSummaryNoBackup;
    }
    if (widget.lastBackupAt == null) {
      return widget.l10n.settingsSyncBackupDataReady;
    }
    final age = DateTime.now().difference(widget.lastBackupAt!);
    if (age <= const Duration(hours: 24)) {
      return widget.l10n.settingsSyncSummaryCurrent(
        widget.formatBackupTime(widget.lastBackupAt!),
      );
    }
    return widget.l10n.settingsSyncSummaryStale(
      widget.formatBackupTime(widget.lastBackupAt!),
    );
  }

  bool get _hasKnownBackup => widget.lastBackupAt != null || widget.backupKnown;
}

class _InfoPill extends StatelessWidget {
  final String label;

  const _InfoPill({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: Theme.of(
          context,
        ).textTheme.labelMedium?.copyWith(fontWeight: FontWeight.w700),
      ),
    );
  }
}
