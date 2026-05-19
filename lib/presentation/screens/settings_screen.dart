import 'dart:async';

import 'package:flutter/material.dart';
import 'package:football_note/gen/app_localizations.dart';
import 'package:intl/intl.dart';

import '../../application/backup_service.dart';
import '../../application/benchmark_service.dart';
import '../../application/drive_connection_info.dart';
import '../../application/drive_backup_service.dart';
import '../../application/family_access_service.dart';
import '../../application/locale_service.dart';
import '../../application/localized_option_defaults.dart';
import '../../application/settings_service.dart';
import '../../domain/repositories/option_repository.dart';
import '../widgets/watch_cart/constants.dart';
import '../widgets/watch_cart/watch_cart_card.dart';

class SettingsScreen extends StatefulWidget {
  final LocaleService localeService;
  final SettingsService settingsService;
  final OptionRepository optionRepository;
  final BackupService? driveBackupService;

  const SettingsScreen({
    super.key,
    required this.localeService,
    required this.settingsService,
    required this.optionRepository,
    this.driveBackupService,
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
  bool _benchmarkSyncBusy = false;
  bool _signedIn = false;
  bool _autoDaily = true;
  bool _autoOnSave = true;
  String _connectedDriveLabel = '';
  String _connectedDriveEmail = '';
  String _sharedChildDriveLabel = '';
  String _sharedChildDriveEmail = '';
  bool _hasRemotePlayerBackup = false;
  bool _driveStatusLoading = true;
  StreamSubscription<void>? _driveAccountStateSubscription;

  late List<int> _durationOptions;
  late List<int> _ratingOptions;
  late List<String> _locationOptions;
  late List<String> _programOptions;
  late List<String> _dailyGoalOptions;
  late List<String> _injuryPartOptions;

  late int _defaultDuration;
  late int _defaultIntensity;
  late int _defaultCondition;
  late String _defaultLocation;
  late String _defaultProgram;
  late List<String> _newsBlockedDomains;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _driveAccountStateSubscription = widget.driveBackupService
        ?.driveAccountStateChanges()
        .listen((_) => unawaited(_refreshDriveUi()));
    unawaited(_refreshDriveUi(refreshParentSharedData: true));
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      unawaited(_refreshDriveUi(refreshParentSharedData: true));
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
  }) async {
    if (widget.driveBackupService != null && mounted) {
      setState(() => _driveStatusLoading = true);
    }
    try {
      if (refreshParentSharedData) {
        try {
          await _refreshParentSharedDataIfNeeded();
        } catch (e, st) {
          debugPrint('Drive family shared data refresh failed: $e');
          debugPrintStack(stackTrace: st);
        }
      }
      await _refreshSignInState(allowCachedConnection: allowCachedConnection);
    } catch (e, st) {
      debugPrint('Drive UI refresh failed: $e');
      debugPrintStack(stackTrace: st);
    } finally {
      if (widget.driveBackupService != null && mounted) {
        setState(() => _driveStatusLoading = false);
      }
    }
  }

  Future<void> _refreshParentSharedDataIfNeeded() async {
    if (widget.driveBackupService == null) return;
    final result = await widget.driveBackupService!
        .refreshFamilySharedDataIfNeeded();
    if (result.refreshed) {
      widget.localeService.load();
      widget.settingsService.load();
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

  Future<void> _refreshSignInState({bool allowCachedConnection = false}) async {
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
    var hasRemotePlayerBackup = false;
    try {
      sharedChildConnection = await widget.driveBackupService!
          .getSharedChildDriveConnectionInfo(
            allowRemoteLookup: familyState.isParentMode,
          );
      if (familyState.isParentMode &&
          (sharedChildConnection == null || sharedChildConnection.isEmpty)) {
        hasRemotePlayerBackup = await widget.driveBackupService!
            .hasRemotePlayerBackup();
      }
    } catch (e, st) {
      debugPrint('Shared child Drive lookup failed: $e');
      debugPrintStack(stackTrace: st);
    }
    if (familyState.isChildMode &&
        connection != null &&
        !connection.isEmpty &&
        widget.driveBackupService!.getSavedRecordDriveEmail().trim().isEmpty) {
      try {
        await widget.driveBackupService!.rememberRecordDriveConnection();
      } catch (e, st) {
        debugPrint('Drive player connection cache refresh failed: $e');
        debugPrintStack(stackTrace: st);
      }
    }
    final cachedConnectedDriveLabel = _cachedConnectedDriveLabel();
    final cachedConnectedDriveEmail = _cachedConnectedDriveEmail();
    if (!mounted) return;
    setState(() {
      _signedIn =
          signedIn ||
          (connection != null && !connection.isEmpty) ||
          (allowCachedConnection && cachedConnectedDriveLabel.isNotEmpty);
      _connectedDriveLabel = connection?.label.trim().isNotEmpty == true
          ? connection!.label.trim()
          : cachedConnectedDriveLabel;
      _connectedDriveEmail = connection?.email.trim().isNotEmpty == true
          ? connection!.email.trim()
          : cachedConnectedDriveEmail;
      _sharedChildDriveLabel = sharedChildConnection?.label.trim() ?? '';
      _sharedChildDriveEmail = sharedChildConnection?.email.trim() ?? '';
      _hasRemotePlayerBackup = hasRemotePlayerBackup;
    });
  }

  String _cachedConnectedDriveLabel() {
    final cachedLabel =
        widget.optionRepository
            .getValue<String>(DriveBackupService.connectedDriveLabelLocalKey)
            ?.trim() ??
        '';
    final cachedEmail =
        widget.optionRepository
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

  String _cachedConnectedDriveEmail() {
    return widget.optionRepository
            .getValue<String>(DriveBackupService.connectedDriveEmailLocalKey)
            ?.trim() ??
        '';
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
    final savedEmail =
        widget.driveBackupService?.getSavedRecordDriveEmail().trim() ?? '';
    final connectedEmail = _connectedDriveEmail.trim();
    if (savedEmail.isEmpty || connectedEmail.isEmpty) return false;
    return savedEmail.toLowerCase() != connectedEmail.toLowerCase();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isKo = Localizations.localeOf(context).languageCode == 'ko';
    final current = widget.localeService.locale?.languageCode ?? 'en';
    final familyState = FamilyAccessService(
      widget.optionRepository,
    ).loadState();
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
    final driveMatchesExpected =
        expectedChildDriveLabel.isEmpty ||
        _connectedDriveLabel.trim().isEmpty ||
        _driveLabelMatchesEmail(_connectedDriveLabel, _sharedChildDriveEmail);

    if (widget.driveBackupService != null) {
      _autoDaily = widget.driveBackupService!.isAutoDailyEnabled();
      _autoOnSave = widget.driveBackupService!.isAutoOnSaveEnabled();
    }

    _durationOptions = widget.optionRepository.getIntOptions(
      'durations',
      const [0, 30, 45, 60, 75, 90, 120],
    );
    _ratingOptions = const [1, 2, 3, 4, 5];
    _locationOptions = widget.optionRepository.getOptions('locations', [
      l10n.defaultLocation1,
      l10n.defaultLocation2,
      l10n.defaultLocation3,
    ]);
    final localizedLocationDefaults = [
      l10n.defaultLocation1,
      l10n.defaultLocation2,
      l10n.defaultLocation3,
    ];
    final normalizedLocations = LocalizedOptionDefaults.normalizeOptions(
      key: 'locations',
      stored: _locationOptions,
      localizedDefaults: localizedLocationDefaults,
    );
    if (!_sameStringList(_locationOptions, normalizedLocations)) {
      _locationOptions = normalizedLocations;
      widget.optionRepository.saveOptions('locations', normalizedLocations);
    }
    _programOptions = widget.optionRepository.getOptions('programs', [
      l10n.defaultProgram1,
      l10n.defaultProgram2,
      l10n.defaultProgram3,
      l10n.defaultProgram4,
    ]);
    final localizedProgramDefaults = [
      l10n.defaultProgram1,
      l10n.defaultProgram2,
      l10n.defaultProgram3,
      l10n.defaultProgram4,
    ];
    final normalizedPrograms = LocalizedOptionDefaults.normalizeOptions(
      key: 'programs',
      stored: _programOptions,
      localizedDefaults: localizedProgramDefaults,
    );
    if (!_sameStringList(_programOptions, normalizedPrograms)) {
      _programOptions = normalizedPrograms;
      widget.optionRepository.saveOptions('programs', normalizedPrograms);
    }
    _injuryPartOptions = widget.optionRepository.getOptions('injury_parts', [
      l10n.defaultInjury1,
      l10n.defaultInjury2,
      l10n.defaultInjury3,
      l10n.defaultInjury4,
      l10n.defaultInjury5,
    ]);
    _dailyGoalOptions = widget.optionRepository.getOptions(
      'daily_goals',
      _defaultDailyGoals(isKo),
    );
    final localizedDailyGoalDefaults = _defaultDailyGoals(isKo);
    final normalizedDailyGoals = LocalizedOptionDefaults.normalizeOptions(
      key: 'daily_goals',
      stored: _dailyGoalOptions,
      localizedDefaults: localizedDailyGoalDefaults,
    );
    if (!_sameStringList(_dailyGoalOptions, normalizedDailyGoals)) {
      _dailyGoalOptions = normalizedDailyGoals;
      widget.optionRepository.saveOptions('daily_goals', normalizedDailyGoals);
    }
    _defaultDuration =
        widget.optionRepository.getValue<int>('default_duration') ??
        _durationOptions.first;
    _defaultIntensity =
        widget.optionRepository.getValue<int>('default_intensity') ?? 3;
    _defaultCondition =
        widget.optionRepository.getValue<int>('default_condition') ?? 3;
    final storedDefaultLocation = widget.optionRepository.getValue<String>(
      'default_location',
    );
    _defaultLocation = LocalizedOptionDefaults.normalizeDefaultValue(
      key: 'default_location',
      storedValue: storedDefaultLocation,
      localizedDefaults: localizedLocationDefaults,
      options: _locationOptions,
    );
    if (storedDefaultLocation != _defaultLocation) {
      unawaited(
        widget.optionRepository.setValue('default_location', _defaultLocation),
      );
    }

    final storedDefaultProgram = widget.optionRepository.getValue<String>(
      'default_program',
    );
    _defaultProgram = LocalizedOptionDefaults.normalizeDefaultValue(
      key: 'default_program',
      storedValue: storedDefaultProgram,
      localizedDefaults: localizedProgramDefaults,
      options: _programOptions,
    );
    if (storedDefaultProgram != _defaultProgram) {
      unawaited(
        widget.optionRepository.setValue('default_program', _defaultProgram),
      );
    }
    _newsBlockedDomains = widget.optionRepository.getOptions(
      'news_blocked_domains',
      const [],
    );

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
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
          _buildSectionCard(
            title: isKo ? '일반 설정' : 'General',
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
                          label: l10n.language,
                          value: current,
                          options: const ['en', 'ko'],
                          optionLabel: (value) => value == 'ko'
                              ? l10n.languageKorean
                              : l10n.languageEnglish,
                          onChanged: (value) {
                            if (value == 'ko') {
                              widget.localeService.setLocale(
                                const Locale('ko', 'KR'),
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
              const SizedBox(height: 10),
              OutlinedButton.icon(
                onPressed: _benchmarkSyncBusy
                    ? null
                    : () => _refreshBenchmarkData(isKo),
                icon: _benchmarkSyncBusy
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.sync),
                label: Text(
                  _benchmarkSyncBusy
                      ? (isKo ? '평균 데이터 동기화 중...' : 'Syncing average data...')
                      : (isKo ? '평균 데이터 지금 새로고침' : 'Refresh Average Data Now'),
                ),
                style: _outlinedActionStyle(),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildSectionCard(
            title: l10n.defaults,
            icon: Icons.tune_outlined,
            children: [
              const SizedBox(height: 6),
              _buildDefaultsAndOptionManager(l10n, isKo),
              const SizedBox(height: 8),
            ],
          ),
          const SizedBox(height: 12),
          _buildSectionCard(
            title: isKo ? '뉴스 필터' : 'News Filter',
            icon: Icons.filter_alt_outlined,
            children: [
              _buildOptionManagerTile(
                title: isKo ? '광고 도메인 차단 목록' : 'Blocked ad domains',
                subtitle:
                    '${_newsBlockedDomains.length}${isKo ? '개 항목' : ' items'}',
                onTap: () => _manageStringOptions(
                  key: 'news_blocked_domains',
                  title: isKo ? '광고 도메인 차단 목록 관리' : 'Manage blocked ad domains',
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
                  isKo
                      ? '예시: example.com (프로토콜/경로 없이 도메인만 입력)'
                      : 'Example: example.com (domain only, no path)',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ),
            ],
          ),
        ],
      ),
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
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              title,
                              style: Theme.of(context).textTheme.titleSmall
                                  ?.copyWith(fontWeight: FontWeight.w800),
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
              selected: familyState.isSupportMode,
              onSelected: (_) {
                if (familyState.isSupportMode) return;
                unawaited(_updateFamilyRole(FamilyRole.parent));
              },
            ),
          ],
        ),
      ],
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
    final children = <Widget>[
      _buildCurrentDriveAccountTile(l10n),
      _buildDriveQuickActions(l10n: l10n, familyState: familyState),
    ];
    if (_backupLockedByChangedPlayerDrive(familyState)) {
      children.add(_buildDriveBackupLockedWarning(l10n));
    }
    if (!_signedIn) {
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
    final hasKnownBackupData =
        _hasRemotePlayerBackup ||
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
        lastBackupAt:
            driveBackupService.getLastFamilySyncPush() ??
            driveBackupService.getLastFamilyRefresh() ??
            driveBackupService.getLastBackup(),
        localRestoreAt: driveBackupService.getLocalPreRestoreTime(),
        backupKnown: hasKnownBackupData,
        formatBackupTime: _formatBackupTime,
      ),
      _buildParentFamilySyncCard(l10n),
    ]);
    return children;
  }

  Widget _buildDriveQuickActions({
    required AppLocalizations l10n,
    required FamilyAccessState familyState,
  }) {
    final isSupportMode = familyState.isSupportMode;
    final backupLocked = _backupLockedByChangedPlayerDrive(familyState);
    final actions = <Widget>[
      _buildDriveQuickActionButton(
        icon: _signedIn ? Icons.link_off_outlined : Icons.link_outlined,
        label: _signedIn
            ? l10n.settingsDriveDisconnectAction
            : l10n.settingsDriveConnectAction,
        onPressed: _signInBusy ? null : () => _toggleDriveSignIn(l10n),
      ),
    ];
    if (_signedIn) {
      actions.add(
        _buildDriveQuickActionButton(
          icon: Icons.cloud_download_outlined,
          label: l10n.settingsRestoreLatestActionTitle,
          onPressed: (_backupBusy || _restoreBusy)
              ? null
              : () => _restoreFromDrive(
                  l10n,
                  title: l10n.settingsRestoreLatestActionTitle,
                  filePath: DriveBackupService.backupDisplayPath,
                  backupCreatedAt: widget.driveBackupService!.getLastBackup(),
                  message: isSupportMode
                      ? l10n.familySharedRestoreConfirm
                      : null,
                  successMessage: isSupportMode
                      ? l10n.familySharedRestoreSuccess
                      : null,
                  failedMessage: isSupportMode
                      ? l10n.familySharedRestoreFailed
                      : null,
                ),
        ),
      );
      actions.add(
        _buildDriveQuickActionButton(
          icon: Icons.settings_backup_restore_outlined,
          label: l10n.restorePreviousBackup,
          destructive: true,
          onPressed: (_backupBusy || _restoreBusy)
              ? null
              : () => _restoreFromDrive(
                  l10n,
                  title: l10n.restorePreviousBackup,
                  filePath: DriveBackupService.previousBackupDisplayPath,
                  backupCreatedAt: widget.driveBackupService!
                      .getPreviousBackupCreatedAt(),
                  message: l10n.restorePreviousConfirm,
                  successMessage: l10n.restorePreviousSuccess,
                  failedMessage: l10n.restorePreviousFailed,
                  restoreAction:
                      widget.driveBackupService!.restorePreviousBackup,
                ),
        ),
      );
    }
    if (_signedIn && !isSupportMode) {
      actions.add(
        _buildDriveQuickActionButton(
          icon: Icons.cloud_upload_outlined,
          label: l10n.settingsBackupDataActionTitle,
          onPressed: (_backupBusy || _restoreBusy || backupLocked)
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
    bool destructive = false,
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
      style: _quickActionButtonStyle(destructive: destructive),
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
    required ValueChanged<T> onChanged,
    double height = 60,
    double topSpacing = 6,
    double bottomSpacing = 8,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final onSurface = Theme.of(context).colorScheme.onSurface;
    final fillColor = isDark
        ? const Color(0xFF242D3D)
        : const Color(0xFFF7F8FC);
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
              onSelected: (value) {
                if (value != null) onChanged(value);
              },
            );
          },
        ),
      ),
    );
  }

  Widget _buildDefaultsAndOptionManager(AppLocalizations l10n, bool isKo) {
    final defaultDurationText = _defaultDuration <= 0
        ? l10n.notSet
        : l10n.minutes(_defaultDuration);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          isKo ? '기본값' : 'Default values',
          style: Theme.of(
            context,
          ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 8),
        _buildDefaultTile(
          label: l10n.defaultDuration,
          valueText: defaultDurationText,
          onEdit: () => _pickDefaultDuration(l10n),
          onDelete: () async {
            await widget.optionRepository.setValue('default_duration', null);
            if (!mounted) return;
            setState(() => _defaultDuration = _durationOptions.first);
          },
        ),
        _buildDefaultTile(
          label: l10n.defaultIntensity,
          valueText: '$_defaultIntensity / 5',
          onEdit: () => _pickDefaultRating(
            key: 'default_intensity',
            current: _defaultIntensity,
            onChanged: (value) => setState(() => _defaultIntensity = value),
            title: l10n.defaultIntensity,
          ),
          onDelete: () async {
            await widget.optionRepository.setValue('default_intensity', null);
            if (!mounted) return;
            setState(() => _defaultIntensity = 3);
          },
        ),
        _buildDefaultTile(
          label: l10n.defaultCondition,
          valueText: '$_defaultCondition / 5',
          onEdit: () => _pickDefaultRating(
            key: 'default_condition',
            current: _defaultCondition,
            onChanged: (value) => setState(() => _defaultCondition = value),
            title: l10n.defaultCondition,
          ),
          onDelete: () async {
            await widget.optionRepository.setValue('default_condition', null);
            if (!mounted) return;
            setState(() => _defaultCondition = 3);
          },
        ),
        _buildDefaultTile(
          label: l10n.defaultLocation,
          valueText: _defaultLocation,
          onEdit: () => _pickDefaultString(
            key: 'default_location',
            current: _defaultLocation,
            options: _locationOptions,
            title: l10n.defaultLocation,
            onChanged: (value) => setState(() => _defaultLocation = value),
          ),
          onDelete: () async {
            await widget.optionRepository.setValue('default_location', null);
            if (!mounted) return;
            setState(() => _defaultLocation = _locationOptions.first);
          },
        ),
        _buildDefaultTile(
          label: l10n.defaultProgram,
          valueText: _defaultProgram,
          onEdit: () => _pickDefaultString(
            key: 'default_program',
            current: _defaultProgram,
            options: _programOptions,
            title: l10n.defaultProgram,
            onChanged: (value) => setState(() => _defaultProgram = value),
          ),
          onDelete: () async {
            await widget.optionRepository.setValue('default_program', null);
            if (!mounted) return;
            setState(() => _defaultProgram = _programOptions.first);
          },
        ),
        const SizedBox(height: 12),
        const Divider(height: 1),
        const SizedBox(height: 12),
        Text(
          isKo ? '일지 항목 관리' : 'Journal option manager',
          style: Theme.of(
            context,
          ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 8),
        _buildOptionManagerTile(
          title: isKo ? '훈련 시간 옵션' : 'Duration options',
          subtitle:
              '${_durationOptions.where((e) => e > 0).length}${isKo ? '개 항목' : ' items'}',
          onTap: () => _manageIntOptions(
            key: 'durations',
            title: isKo ? '훈련 시간 옵션 관리' : 'Manage duration options',
            options: _durationOptions,
            minKeep: 1,
            formatLabel: (value) =>
                value <= 0 ? l10n.notSet : l10n.minutes(value),
            onSaved: (updated) async {
              setState(() => _durationOptions = updated);
              if (!_durationOptions.contains(_defaultDuration)) {
                final fallback = _durationOptions.first;
                await widget.optionRepository.setValue(
                  'default_duration',
                  fallback,
                );
                if (!mounted) return;
                setState(() => _defaultDuration = fallback);
              }
            },
          ),
        ),
        _buildOptionManagerTile(
          title: isKo ? '장소 옵션' : 'Location options',
          subtitle: '${_locationOptions.length}${isKo ? '개 항목' : ' items'}',
          onTap: () => _manageStringOptions(
            key: 'locations',
            title: isKo ? '장소 옵션 관리' : 'Manage location options',
            options: _locationOptions,
            minKeep: 1,
            onSaved: (updated) async {
              setState(() => _locationOptions = updated);
              if (!_locationOptions.contains(_defaultLocation)) {
                final fallback = _locationOptions.first;
                await widget.optionRepository.setValue(
                  'default_location',
                  fallback,
                );
                if (!mounted) return;
                setState(() => _defaultLocation = fallback);
              }
            },
          ),
        ),
        _buildOptionManagerTile(
          title: isKo ? '프로그램 옵션' : 'Program options',
          subtitle: '${_programOptions.length}${isKo ? '개 항목' : ' items'}',
          onTap: () => _manageStringOptions(
            key: 'programs',
            title: isKo ? '프로그램 옵션 관리' : 'Manage program options',
            options: _programOptions,
            minKeep: 1,
            onSaved: (updated) async {
              setState(() => _programOptions = updated);
              if (!_programOptions.contains(_defaultProgram)) {
                final fallback = _programOptions.first;
                await widget.optionRepository.setValue(
                  'default_program',
                  fallback,
                );
                if (!mounted) return;
                setState(() => _defaultProgram = fallback);
              }
            },
          ),
        ),
        _buildOptionManagerTile(
          title: isKo ? '훈련 목표 옵션' : 'Training goal options',
          subtitle: '${_dailyGoalOptions.length}${isKo ? '개 항목' : ' items'}',
          onTap: () => _manageStringOptions(
            key: 'daily_goals',
            title: isKo ? '훈련 목표 옵션 관리' : 'Manage training goal options',
            options: _dailyGoalOptions,
            minKeep: 1,
            onSaved: (updated) async {
              setState(() => _dailyGoalOptions = updated);
            },
          ),
        ),
        _buildOptionManagerTile(
          title: isKo ? '부상 부위 옵션' : 'Injury part options',
          subtitle: '${_injuryPartOptions.length}${isKo ? '개 항목' : ' items'}',
          onTap: () => _manageStringOptions(
            key: 'injury_parts',
            title: isKo ? '부상 부위 옵션 관리' : 'Manage injury part options',
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
    required String label,
    required String valueText,
    required Future<void> Function() onEdit,
    required Future<void> Function() onDelete,
  }) {
    final isKo = Localizations.localeOf(context).languageCode == 'ko';
    return ListTile(
      dense: true,
      contentPadding: EdgeInsets.zero,
      title: Text(label),
      subtitle: Text(valueText),
      trailing: Wrap(
        spacing: 4,
        children: [
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            tooltip: isKo ? '수정' : 'Edit',
            onPressed: onEdit,
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline),
            tooltip: isKo ? '삭제' : 'Delete',
            onPressed: onDelete,
          ),
        ],
      ),
    );
  }

  Widget _buildOptionManagerTile({
    required String title,
    required String subtitle,
    required Future<void> Function() onTap,
  }) {
    return ListTile(
      dense: true,
      contentPadding: EdgeInsets.zero,
      title: Text(title),
      subtitle: Text(subtitle),
      trailing: const Icon(Icons.chevron_right),
      onTap: onTap,
    );
  }

  Future<void> _pickDefaultDuration(AppLocalizations l10n) async {
    await _pickDefaultInt(
      key: 'default_duration',
      current: _defaultDuration,
      options: _durationOptions,
      title: l10n.defaultDuration,
      labelBuilder: (value) => value <= 0 ? l10n.notSet : l10n.minutes(value),
      onChanged: (value) => setState(() => _defaultDuration = value),
    );
  }

  Future<void> _pickDefaultRating({
    required String key,
    required int current,
    required ValueChanged<int> onChanged,
    required String title,
  }) async {
    await _pickDefaultInt(
      key: key,
      current: current,
      options: _ratingOptions,
      title: title,
      labelBuilder: (value) => '$value / 5',
      onChanged: onChanged,
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
    final isKo = Localizations.localeOf(context).languageCode == 'ko';
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
                                  title: isKo ? '항목 수정' : 'Edit option',
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
                          title: isKo ? '새 항목 추가' : 'Add option',
                        );
                        if (added == null || added.isEmpty) return;
                        final normalized = sanitize == null
                            ? added
                            : sanitize(added);
                        if (normalized.isEmpty ||
                            working.contains(normalized)) {
                          return;
                        }
                        setSheetState(() => working.add(normalized));
                      },
                      icon: const Icon(Icons.add),
                      label: Text(isKo ? '항목 추가' : 'Add item'),
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
                      child: Text(isKo ? '저장' : 'Save'),
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
    final isKo = Localizations.localeOf(context).languageCode == 'ko';
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
                                  title: isKo ? '시간 수정(분)' : 'Edit minutes',
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
                          title: isKo ? '새 시간 추가(분)' : 'Add minutes',
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
                      label: Text(isKo ? '항목 추가' : 'Add item'),
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
                      child: Text(isKo ? '저장' : 'Save'),
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
    final targetRole = FamilyAccessService.isSupportRole(role)
        ? FamilyRole.parent
        : FamilyRole.child;
    final familyService = FamilyAccessService(widget.optionRepository);
    final currentState = familyService.loadState();
    if (widget.driveBackupService != null && _signedIn) {
      if (currentState.isChildMode &&
          FamilyAccessService.isSupportRole(targetRole)) {
        await widget.driveBackupService!.rememberRecordDriveConnection();
      } else if (currentState.isSupportMode && targetRole == FamilyRole.child) {
        await widget.driveBackupService!.rememberParentDriveConnection();
        await widget.driveBackupService!.signOut();
      }
    }
    await familyService.setCurrentRole(targetRole);
    if (widget.driveBackupService != null &&
        FamilyAccessService.isSupportRole(targetRole)) {
      await _refreshParentSharedDataIfNeeded();
    }
    await _refreshSignInState();
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
  }

  String _familyRoleLabel(AppLocalizations l10n, FamilyRole role) {
    return switch (role) {
      FamilyRole.child => l10n.familyRolePlayer,
      FamilyRole.parent || FamilyRole.coach => l10n.settingsSupportModeLabel,
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

  List<String> _defaultDailyGoals(bool isKo) {
    if (isKo) {
      return const ['드리블', '패스 정확도', '슈팅', '체력', '수비 위치 선정', '퍼스트 터치'];
    }
    return const [
      'Dribbling',
      'Passing Accuracy',
      'Shooting',
      'Fitness',
      'Defensive Positioning',
      'First Touch',
    ];
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

  Widget _buildParentFamilySyncCard(AppLocalizations l10n) {
    final lastPushAt = widget.driveBackupService?.getLastFamilySyncPush();
    final lastPullAt = widget.driveBackupService?.getLastFamilyRefresh();
    final hasPendingChanges =
        widget.driveBackupService?.hasPendingParentSharedChanges() ?? false;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  l10n.familySharedSyncTitle,
                  style: Theme.of(
                    context,
                  ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800),
                ),
              ),
            ],
          ),
          if (hasPendingChanges) ...[
            const SizedBox(height: 8),
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
            const SizedBox(height: 8),
            _buildDriveAccountTile(
              icon: Icons.history,
              title: l10n.familySharedLastPush,
              subtitle: _formatBackupTime(lastPushAt),
            ),
          ],
          if (lastPullAt != null) ...[
            const SizedBox(height: 8),
            _buildDriveAccountTile(
              icon: Icons.refresh_outlined,
              title: l10n.familySharedLastRefresh,
              subtitle: _formatBackupTime(lastPullAt),
            ),
          ],
        ],
      ),
    );
  }

  ButtonStyle _outlinedActionStyle() {
    return ButtonStyle(
      minimumSize: WidgetStateProperty.all(const Size.fromHeight(56)),
      padding: WidgetStateProperty.all(
        const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      ),
      textStyle: WidgetStateProperty.all(
        const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
      ),
      shape: WidgetStateProperty.all(
        RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
      side: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.pressed)) {
          return const BorderSide(
            color: WatchCartConstants.primaryColor,
            width: 2,
          );
        }
        return BorderSide(
          color: WatchCartConstants.primaryColor.withAlpha(160),
          width: 1.4,
        );
      }),
      backgroundColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.pressed)) {
          return WatchCartConstants.primaryColor.withAlpha(22);
        }
        return null;
      }),
      overlayColor: WidgetStateProperty.all(
        WatchCartConstants.primaryColor.withAlpha(30),
      ),
      splashFactory: InkRipple.splashFactory,
    );
  }

  ButtonStyle _quickActionButtonStyle({bool destructive = false}) {
    final scheme = Theme.of(context).colorScheme;
    final color = destructive ? scheme.error : WatchCartConstants.primaryColor;
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
    setState(() => _backupBusy = true);
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
      final message =
          e.toString().contains('sign-in') ||
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
        await widget.driveBackupService!.rememberCurrentRoleDriveConnection();
      }
      await _refreshDriveUi(
        allowCachedConnection: !wasSignedIn,
        refreshParentSharedData: !wasSignedIn,
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
    setState(() => _restoreBusy = true);
    try {
      final action = restoreAction ?? widget.driveBackupService!.restoreLatest;
      await action();
      widget.localeService.load();
      widget.settingsService.load();
      await _refreshSignInState();
      if (!mounted) return;
      setState(() {});
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(successMessage ?? l10n.restoreSuccess)),
      );
    } catch (e, st) {
      debugPrint('Drive restore failed: $e');
      debugPrintStack(stackTrace: st);
      if (!mounted) return;
      final message =
          e.toString().contains('sign-in') ||
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

  Future<void> _refreshBenchmarkData(bool isKo) async {
    setState(() => _benchmarkSyncBusy = true);
    try {
      final service = BenchmarkService(widget.optionRepository);
      await service.refreshFromExternalIfNeeded(force: true);
      if (!mounted) return;
      final synced = service.lastSyncedAt();
      final suffix = synced == null
          ? ''
          : ' (${DateFormat('yyyy-MM-dd HH:mm').format(synced.toLocal())})';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            isKo
                ? '평균 데이터 업데이트 완료$suffix'
                : 'Average benchmark data updated$suffix',
          ),
        ),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            isKo
                ? '평균 데이터 업데이트에 실패했어요. 네트워크를 확인해 주세요.'
                : 'Failed to update average benchmark data. Check network.',
          ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _benchmarkSyncBusy = false);
      }
    }
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
            if (widget.lastBackupAt != null) ...[
              const SizedBox(height: 10),
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
