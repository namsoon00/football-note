import 'dart:async';

import 'package:flutter/material.dart';
import 'package:football_note/gen/app_localizations.dart';
import 'package:intl/intl.dart';

import '../../application/backup_service.dart';
import '../../application/benchmark_service.dart';
import '../../application/drive_backup_service.dart';
import '../../application/family_access_service.dart';
import '../../application/locale_service.dart';
import '../../application/localized_option_defaults.dart';
import '../../application/settings_service.dart';
import '../../domain/repositories/option_repository.dart';
import '../widgets/watch_cart/constants.dart';
import '../widgets/watch_cart/watch_cart_card.dart';
import 'family_space_screen.dart';
import 'visual_language_preview_screen.dart';

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

class _SettingsScreenState extends State<SettingsScreen> {
  bool _backupBusy = false;
  bool _restoreBusy = false;
  bool _signInBusy = false;
  bool _benchmarkSyncBusy = false;
  bool _signedIn = false;
  bool _autoDaily = true;
  bool _autoOnSave = true;
  String _connectedDriveLabel = '';
  String _savedPlayerDriveLabel = '';
  String _savedPlayerDriveEmail = '';
  String _sharedChildDriveLabel = '';
  String _sharedChildDriveEmail = '';

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
    _refreshSignInState();
  }

  Future<void> _refreshSignInState() async {
    if (widget.driveBackupService == null) return;
    final signedIn = await widget.driveBackupService!.isSignedIn();
    final connection =
        await widget.driveBackupService!.getDriveConnectionInfo();
    final familyState =
        FamilyAccessService(widget.optionRepository).loadState();
    if (familyState.isChildMode &&
        connection != null &&
        !connection.isEmpty &&
        widget.driveBackupService!.getSavedPlayerDriveEmail().trim().isEmpty) {
      await widget.driveBackupService!.rememberPlayerDriveConnection();
    }
    if (!mounted) return;
    setState(() {
      _signedIn = signedIn;
      _connectedDriveLabel = connection?.label.trim() ?? '';
      _savedPlayerDriveLabel =
          widget.driveBackupService!.getSavedPlayerDriveLabel();
      _savedPlayerDriveEmail =
          widget.driveBackupService!.getSavedPlayerDriveEmail();
      _sharedChildDriveLabel =
          widget.driveBackupService!.getSharedChildDriveLabel();
      _sharedChildDriveEmail =
          widget.driveBackupService!.getSharedChildDriveEmail();
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isKo = Localizations.localeOf(context).languageCode == 'ko';
    final current = widget.localeService.locale?.languageCode ?? 'en';
    final familyState =
        FamilyAccessService(widget.optionRepository).loadState();
    final showPlayerBackupSection =
        widget.driveBackupService != null && !familyState.isParentMode;
    final savedPlayerDriveLabel = _savedPlayerDriveLabel.trim().isNotEmpty
        ? _savedPlayerDriveLabel.trim()
        : _savedPlayerDriveEmail.trim();
    final expectedChildDriveLabel = _sharedChildDriveLabel.trim().isNotEmpty
        ? _sharedChildDriveLabel.trim()
        : _sharedChildDriveEmail.trim();
    final playerDriveMatchesSaved = savedPlayerDriveLabel.isEmpty ||
        _connectedDriveLabel.trim().isEmpty ||
        _connectedDriveLabel.toLowerCase().contains(
              _savedPlayerDriveEmail.trim().toLowerCase(),
            );
    final driveMatchesExpected = expectedChildDriveLabel.isEmpty ||
        _connectedDriveLabel.trim().isEmpty ||
        _connectedDriveLabel.toLowerCase().contains(
              _sharedChildDriveEmail.trim().toLowerCase(),
            );

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
        padding: const EdgeInsets.all(16),
        children: [
          if (showPlayerBackupSection) ...[
            _buildSectionCard(
              title: l10n.account,
              icon: Icons.manage_accounts_outlined,
              initiallyExpanded: true,
              children: [
                _BackupHealthCard(
                  isKo: isKo,
                  signedIn: _signedIn,
                  autoDaily: _autoDaily,
                  autoOnSave: _autoOnSave,
                  lastBackupAt: widget.driveBackupService!.getLastBackup(),
                  localRestoreAt:
                      widget.driveBackupService!.getLocalPreRestoreTime(),
                  formatBackupTime: _formatBackupTime,
                ),
                const SizedBox(height: 8),
                _buildDriveAuthButton(
                  l10n: l10n,
                  label: _signedIn ? l10n.signOut : l10n.signInWithGoogle,
                ),
                const SizedBox(height: 8),
                _buildDriveAccountTile(
                  icon: Icons.cloud_done_outlined,
                  title: l10n.driveConnectedAccount,
                  subtitle: _connectedDriveLabel.trim().isEmpty
                      ? l10n.driveConnectedAccountEmpty
                      : _connectedDriveLabel.trim(),
                ),
                if (savedPlayerDriveLabel.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  _buildDriveAccountTile(
                    icon: Icons.sports_soccer_outlined,
                    title: l10n.driveSavedPlayerAccount,
                    subtitle: savedPlayerDriveLabel,
                  ),
                  if (!_signedIn || !playerDriveMatchesSaved) ...[
                    const SizedBox(height: 4),
                    Text(
                      l10n.driveReconnectSavedPlayerHint,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    const SizedBox(height: 8),
                    OutlinedButton.icon(
                      onPressed: _signInBusy
                          ? null
                          : () => _connectSavedPlayerDrive(l10n),
                      icon: const Icon(Icons.link_outlined),
                      label: Text(l10n.driveReconnectSavedPlayer),
                      style: _outlinedActionStyle(),
                    ),
                  ],
                ],
                const SizedBox(height: 8),
                ElevatedButton.icon(
                  onPressed: _backupBusy ? null : () => _backupToDrive(l10n),
                  icon: const Icon(Icons.cloud_upload_outlined),
                  label: Text(
                    _backupBusy ? l10n.backupInProgress : l10n.backupToDrive,
                  ),
                  style: _elevatedActionStyle(),
                ),
                const SizedBox(height: 8),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(l10n.backupDailyEnabled),
                  subtitle: Text(l10n.backupDailyDesc),
                  value: _autoDaily,
                  onChanged: (value) async {
                    setState(() => _autoDaily = value);
                    await widget.driveBackupService!.setAutoDailyEnabled(value);
                  },
                ),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(l10n.backupAutoOnSave),
                  subtitle: Text(l10n.backupAutoOnSaveDesc),
                  value: _autoOnSave,
                  onChanged: (value) async {
                    setState(() => _autoOnSave = value);
                    await widget.driveBackupService!.setAutoOnSaveEnabled(
                      value,
                    );
                  },
                ),
                if (widget.driveBackupService!.getLastBackup() != null) ...[
                  const Divider(height: 12),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.history, size: 20),
                    title: Text(l10n.lastBackup),
                    subtitle: Text(
                      _formatBackupTime(
                        widget.driveBackupService!.getLastBackup()!,
                      ),
                    ),
                  ),
                ],
                if (widget.driveBackupService!.getLocalPreRestoreTime() != null)
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.restore, size: 20),
                    title: Text(l10n.localBackup),
                    subtitle: Text(
                      _formatBackupTime(
                        widget.driveBackupService!.getLocalPreRestoreTime()!,
                      ),
                    ),
                  ),
                const SizedBox(height: 8),
                OutlinedButton.icon(
                  onPressed:
                      _restoreBusy ? null : () => _restoreFromDrive(l10n),
                  icon: const Icon(Icons.cloud_download_outlined),
                  label: Text(
                    _restoreBusy
                        ? l10n.restoreInProgress
                        : l10n.restoreFromDrive,
                  ),
                  style: _outlinedActionStyle(),
                ),
                const SizedBox(height: 8),
                OutlinedButton.icon(
                  onPressed: _restoreBusy ||
                          !widget.driveBackupService!.hasLocalPreRestoreBackup()
                      ? null
                      : () => _restoreLocalBackup(l10n),
                  icon: const Icon(Icons.undo),
                  label: Text(l10n.restoreLocalBackup),
                  style: _outlinedActionStyle(),
                ),
              ],
            ),
            const SizedBox(height: 12),
          ],
          _buildSectionCard(
            title: l10n.familySharing,
            icon: Icons.family_restroom_outlined,
            initiallyExpanded: true,
            children: [
              Text(
                l10n.familySharedBackupDescription,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 8),
              Text(
                familyState.isParentMode
                    ? l10n.familyParentAutoSyncDescription
                    : l10n.familyBackupIncludesMedia,
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: 12),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(l10n.familyParentModeEnabled),
                subtitle: Text(l10n.familyParentModeDescription),
                value: familyState.isParentMode,
                onChanged: (enabled) {
                  _updateFamilyRole(
                    enabled ? FamilyRole.parent : FamilyRole.child,
                  );
                },
              ),
              const SizedBox(height: 10),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.badge_outlined, size: 20),
                title: Text(l10n.familyChildName),
                subtitle: Text(
                  familyState.childName.trim().isEmpty
                      ? l10n.familyChildNameEmpty
                      : familyState.childName.trim(),
                ),
              ),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.person_outline, size: 20),
                title: Text(l10n.familyParentName),
                subtitle: Text(
                  familyState.parentName.trim().isEmpty
                      ? l10n.familyParentNameEmpty
                      : familyState.parentName.trim(),
                ),
              ),
              const SizedBox(height: 8),
              OutlinedButton.icon(
                onPressed: () => _editFamilyMembers(familyState),
                icon: const Icon(Icons.edit_outlined),
                label: Text(l10n.familyEditNames),
                style: _outlinedActionStyle(),
              ),
              if (widget.driveBackupService != null &&
                  familyState.isParentMode) ...[
                const SizedBox(height: 8),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Theme.of(
                      context,
                    ).colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.familyChildDriveConnectionTitle,
                        style: Theme.of(
                          context,
                        ).textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w800,
                            ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        l10n.familyChildDriveConnectionDescription,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                      const SizedBox(height: 12),
                      _buildDriveAuthButton(
                        l10n: l10n,
                        label: _signedIn
                            ? l10n.familyDisconnectChildDrive
                            : l10n.familyConnectChildDrive,
                      ),
                      const SizedBox(height: 8),
                      _buildDriveAccountTile(
                        icon: Icons.child_care_outlined,
                        title: l10n.driveSharedChildAccount,
                        subtitle: expectedChildDriveLabel.isEmpty
                            ? l10n.driveSharedChildAccountEmpty
                            : expectedChildDriveLabel,
                      ),
                      _buildDriveAccountTile(
                        icon: Icons.cloud_done_outlined,
                        title: l10n.driveConnectedAccount,
                        subtitle: _connectedDriveLabel.trim().isEmpty
                            ? l10n.driveConnectedAccountEmpty
                            : _connectedDriveLabel.trim(),
                      ),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: driveMatchesExpected
                              ? Theme.of(
                                  context,
                                ).colorScheme.surfaceContainerHigh
                              : Theme.of(context)
                                  .colorScheme
                                  .errorContainer
                                  .withValues(alpha: 0.45),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Text(
                          driveMatchesExpected
                              ? l10n.familyParentUsesChildDriveHint
                              : l10n.familyParentUsesChildDriveWarning,
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                _buildParentFamilySyncCard(l10n),
              ],
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceContainerHigh,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.familyPolicyTitle,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                    ),
                    const SizedBox(height: 8),
                    Text(l10n.familyPolicyChildOwnsData),
                    const SizedBox(height: 4),
                    Text(l10n.familyPolicyParentWritesOnly),
                    const SizedBox(height: 4),
                    Text(l10n.familyPolicyParentSeedRequired),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              ElevatedButton.icon(
                onPressed: () => _openFamilySpace(),
                icon: const Icon(Icons.forum_outlined),
                label: Text(l10n.familyOpenSpace),
                style: _elevatedActionStyle(),
              ),
            ],
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
              const SizedBox(height: 10),
              OutlinedButton.icon(
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const VisualLanguagePreviewScreen(),
                    ),
                  );
                },
                icon: const Icon(Icons.palette_outlined),
                label: Text(
                  isKo ? '그림 언어 시안 보기' : 'Preview Visual Language',
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
    final defaultDurationText =
        _defaultDuration <= 0 ? l10n.notSet : l10n.minutes(_defaultDuration);
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
                        final normalized =
                            sanitize == null ? added : sanitize(added);
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

  Future<void> _updateFamilyRole(FamilyRole role) async {
    final familyService = FamilyAccessService(widget.optionRepository);
    final currentState = familyService.loadState();
    if (widget.driveBackupService != null &&
        currentState.currentRole == FamilyRole.child &&
        role == FamilyRole.parent &&
        _signedIn) {
      await widget.driveBackupService!.rememberPlayerDriveConnection();
    }
    await familyService.setCurrentRole(role);
    await _refreshSignInState();
    if (!mounted) return;
    setState(() {});
    final l10n = AppLocalizations.of(context)!;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          role == FamilyRole.parent
              ? l10n.familyRoleParentActivated
              : l10n.familyRoleChildActivated,
        ),
      ),
    );
  }

  Future<void> _editFamilyMembers(FamilyAccessState state) async {
    final l10n = AppLocalizations.of(context)!;
    final childController = TextEditingController(text: state.childName);
    final parentController = TextEditingController(text: state.parentName);
    final saved = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.familyEditNames),
        content: SizedBox(
          width: 360,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: childController,
                autofocus: true,
                decoration: InputDecoration(
                  labelText: l10n.familyChildName,
                  hintText: l10n.familyChildNameEmpty,
                  border: const OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: parentController,
                decoration: InputDecoration(
                  labelText: l10n.familyParentName,
                  hintText: l10n.familyParentNameEmpty,
                  border: const OutlineInputBorder(),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(l10n.save),
          ),
        ],
      ),
    );
    if (saved != true) {
      childController.dispose();
      parentController.dispose();
      return;
    }
    final familyService = FamilyAccessService(widget.optionRepository);
    await familyService.saveMembers(
      childName: childController.text,
      parentName: parentController.text,
    );
    childController.dispose();
    parentController.dispose();
    if (!mounted) return;
    setState(() {});
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(l10n.familyNamesSaved)));
  }

  Future<void> _openFamilySpace() async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => FamilySpaceScreen(
          optionRepository: widget.optionRepository,
          driveBackupService: widget.driveBackupService,
        ),
      ),
    );
    if (!mounted) return;
    setState(() {});
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

  ButtonStyle _elevatedActionStyle() {
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
      elevation: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.pressed)) return 1;
        if (states.contains(WidgetState.hovered)) return 7;
        return 5;
      }),
      overlayColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.pressed)) {
          return Colors.black.withAlpha(20);
        }
        return null;
      }),
      shadowColor: WidgetStateProperty.all(Colors.black.withAlpha(70)),
      splashFactory: InkRipple.splashFactory,
    );
  }

  Widget _buildDriveAuthButton({
    required AppLocalizations l10n,
    required String label,
  }) {
    return ElevatedButton.icon(
      onPressed: _signInBusy ? null : () => _toggleDriveSignIn(l10n),
      icon: Icon(_signedIn ? Icons.logout : Icons.login),
      label: Text(label),
      style: _elevatedActionStyle(),
    );
  }

  Widget _buildDriveAccountTile({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(icon, size: 20),
      title: Text(title),
      subtitle: Text(subtitle),
    );
  }

  Widget _buildParentFamilySyncCard(AppLocalizations l10n) {
    final lastBackupAt = widget.driveBackupService?.getLastBackup();
    final hasLocalRestore =
        widget.driveBackupService?.hasLocalPreRestoreBackup() ?? false;
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
          Text(
            l10n.familySharedSyncTitle,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
          ),
          const SizedBox(height: 6),
          Text(
            l10n.familySharedSyncDescription,
            style: Theme.of(context).textTheme.bodySmall,
          ),
          if (lastBackupAt != null) ...[
            const SizedBox(height: 8),
            _buildDriveAccountTile(
              icon: Icons.history,
              title: l10n.familySharedLastSync,
              subtitle: _formatBackupTime(lastBackupAt),
            ),
          ],
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: _restoreBusy
                ? null
                : () => _restoreFromDrive(
                      l10n,
                      title: l10n.familySharedRestore,
                      message: l10n.familySharedRestoreConfirm,
                      successMessage: l10n.familySharedRestoreSuccess,
                      failedMessage: l10n.familySharedRestoreFailed,
                    ),
            icon: const Icon(Icons.cloud_download_outlined),
            label: Text(
              _restoreBusy ? l10n.restoreInProgress : l10n.familySharedRestore,
            ),
            style: _outlinedActionStyle(),
          ),
          if (hasLocalRestore) ...[
            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: _restoreBusy
                  ? null
                  : () => _restoreLocalBackup(
                        l10n,
                        title: l10n.familySharedRestoreLocal,
                        message: l10n.familySharedRestoreLocalConfirm,
                        successMessage: l10n.familySharedRestoreLocalSuccess,
                        failedMessage: l10n.familySharedRestoreLocalFailed,
                      ),
              icon: const Icon(Icons.undo),
              label: Text(l10n.familySharedRestoreLocal),
              style: _outlinedActionStyle(),
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

  Future<void> _backupToDrive(AppLocalizations l10n) async {
    if (widget.driveBackupService == null) return;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.backupToDrive),
        content: Text(l10n.backupConfirm),
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
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l10n.backupSuccess)));
    } catch (e, st) {
      debugPrint('Drive backup failed: $e');
      debugPrintStack(stackTrace: st);
      if (!mounted) return;
      final message = e.toString().contains('sign-in') ||
              e.toString().contains('Sign in') ||
              e.toString().contains('cancelled')
          ? l10n.loginRequired
          : _driveFailureMessage(l10n, e, fallback: l10n.backupFailed);
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
        await widget.driveBackupService!.signOut();
      } else {
        await widget.driveBackupService!.signIn();
        final familyState =
            FamilyAccessService(widget.optionRepository).loadState();
        if (familyState.isChildMode) {
          await widget.driveBackupService!.rememberPlayerDriveConnection();
        }
      }
      await _refreshSignInState();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(wasSignedIn ? l10n.signOutDone : l10n.signInWithGoogle),
        ),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l10n.loginRequired)));
    } finally {
      if (mounted) {
        setState(() => _signInBusy = false);
      }
    }
  }

  Future<void> _connectSavedPlayerDrive(AppLocalizations l10n) async {
    if (widget.driveBackupService == null) return;
    setState(() => _signInBusy = true);
    try {
      await widget.driveBackupService!.signInForSavedPlayer();
      await _refreshSignInState();
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l10n.driveReconnectSavedPlayer)));
    } catch (e) {
      if (!mounted) return;
      final message = e.toString().contains(
                DriveBackupService.playerDriveMismatchErrorCode,
              )
          ? l10n.driveReconnectSavedPlayerMismatch
          : l10n.loginRequired;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(message)));
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
  }) async {
    if (widget.driveBackupService == null) return;
    final confirm = await _confirmRestoreAction(
      l10n: l10n,
      title: title ?? l10n.restoreFromDrive,
      message: message ?? l10n.restoreConfirm,
    );
    if (confirm != true) return;
    setState(() => _restoreBusy = true);
    try {
      await widget.driveBackupService!.restoreLatest();
      widget.localeService.load();
      widget.settingsService.load();
      await _refreshSignInState();
      if (!mounted) return;
      setState(() {});
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(
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

  Future<void> _restoreLocalBackup(
    AppLocalizations l10n, {
    String? title,
    String? message,
    String? successMessage,
    String? failedMessage,
  }) async {
    if (widget.driveBackupService == null) return;
    final confirm = await _confirmRestoreAction(
      l10n: l10n,
      title: title ?? l10n.restoreLocalBackup,
      message: message ?? l10n.restoreLocalConfirm,
    );
    if (confirm != true) return;
    setState(() => _restoreBusy = true);
    try {
      await widget.driveBackupService!.restoreLocalPreBackup();
      widget.localeService.load();
      widget.settingsService.load();
      if (!mounted) return;
      setState(() {});
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(
        SnackBar(content: Text(successMessage ?? l10n.restoreLocalSuccess)),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(
        SnackBar(content: Text(failedMessage ?? l10n.restoreLocalFailed)),
      );
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

  String _driveFailureMessage(
    AppLocalizations l10n,
    Object error, {
    required String fallback,
  }) {
    final raw = error.toString();
    if (raw.contains('parent_drive_mismatch')) {
      return l10n.familyParentUsesChildDriveWarning;
    }
    if (raw.contains(DriveBackupService.playerDriveMismatchErrorCode)) {
      return l10n.driveReconnectSavedPlayerMismatch;
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
    final isKo = Localizations.localeOf(context).languageCode == 'ko';
    final secondConfirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(isKo ? '복원 재확인' : 'Restore confirmation'),
        content: Text(
          isKo
              ? '정말 복원할까요? 현재 데이터는 백업 데이터로 교체됩니다.'
              : 'Do you really want to restore? Current data will be replaced.',
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
  final bool isKo;
  final bool signedIn;
  final bool autoDaily;
  final bool autoOnSave;
  final DateTime? lastBackupAt;
  final DateTime? localRestoreAt;
  final String Function(DateTime value) formatBackupTime;

  const _BackupHealthCard({
    required this.isKo,
    required this.signedIn,
    required this.autoDaily,
    required this.autoOnSave,
    required this.lastBackupAt,
    required this.localRestoreAt,
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
              Icon(Icons.verified_user_outlined, color: healthColor, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  widget.isKo ? '백업 상태' : 'Backup health',
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
          Text(
            _summary(),
            style: theme.textTheme.bodyMedium,
          ),
          const SizedBox(height: 8),
          TextButton.icon(
            onPressed: () => setState(() => _expanded = !_expanded),
            icon: Icon(
              _expanded ? Icons.expand_less : Icons.expand_more,
              color: healthColor,
            ),
            label: Text(
              widget.isKo
                  ? (_expanded ? '자세한 상태 숨기기' : '자세한 상태 보기')
                  : (_expanded ? 'Hide details' : 'Show details'),
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
                  label: widget.isKo
                      ? (widget.signedIn ? '구글 연결됨' : '구글 미연결')
                      : (widget.signedIn
                          ? 'Google connected'
                          : 'Google disconnected'),
                ),
                _InfoPill(
                  label: widget.isKo
                      ? (widget.autoDaily ? '일일 자동 백업 켜짐' : '일일 자동 백업 꺼짐')
                      : (widget.autoDaily
                          ? 'Daily auto-backup on'
                          : 'Daily auto-backup off'),
                ),
                _InfoPill(
                  label: widget.isKo
                      ? (widget.autoOnSave ? '저장 시 자동 백업 켜짐' : '저장 시 자동 백업 꺼짐')
                      : (widget.autoOnSave
                          ? 'Auto-backup on save on'
                          : 'Auto-backup on save off'),
                ),
              ],
            ),
            if (widget.lastBackupAt != null) ...[
              const SizedBox(height: 10),
              Text(
                widget.isKo
                    ? '마지막 클라우드 백업: ${widget.formatBackupTime(widget.lastBackupAt!)}'
                    : 'Last cloud backup: ${widget.formatBackupTime(widget.lastBackupAt!)}',
                style: theme.textTheme.bodySmall,
              ),
            ],
            if (widget.localRestoreAt != null) ...[
              const SizedBox(height: 4),
              Text(
                widget.isKo
                    ? '복원 전 로컬 보관본: ${widget.formatBackupTime(widget.localRestoreAt!)}'
                    : 'Pre-restore local snapshot: ${widget.formatBackupTime(widget.localRestoreAt!)}',
                style: theme.textTheme.bodySmall,
              ),
            ],
          ],
        ],
      ),
    );
  }

  String _healthLabel() {
    if (!widget.signedIn) {
      return widget.isKo ? '로그인 필요' : 'Sign-in required';
    }
    if (widget.lastBackupAt == null) {
      return widget.isKo ? '백업 없음' : 'No backup';
    }
    final age = DateTime.now().difference(widget.lastBackupAt!);
    if (age <= const Duration(hours: 24)) {
      return widget.isKo ? '정상' : 'Healthy';
    }
    if (age <= const Duration(days: 3)) {
      return widget.isKo ? '확인 필요' : 'Review';
    }
    return widget.isKo ? '위험' : 'At risk';
  }

  Color _healthColor(ThemeData theme) {
    if (!widget.signedIn || widget.lastBackupAt == null) {
      return theme.colorScheme.error;
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
    if (!widget.signedIn) {
      return widget.isKo
          ? '계정 연결 전에는 자동 백업이 동작하지 않습니다.'
          : 'Automatic backups cannot run until an account is connected.';
    }
    if (widget.lastBackupAt == null) {
      return widget.isKo
          ? '첫 백업을 아직 만들지 않았습니다. 지금 한 번 백업해 두는 편이 안전합니다.'
          : 'No backup has been created yet. Running one now is the safer path.';
    }
    final age = DateTime.now().difference(widget.lastBackupAt!);
    if (age <= const Duration(hours: 24)) {
      return widget.isKo
          ? '최근 24시간 안에 백업이 완료되어 현재 데이터 보호 상태가 좋습니다.'
          : 'A backup completed within the last 24 hours, so protection is in good shape.';
    }
    return widget.isKo
        ? '마지막 백업이 오래되었습니다. 수동 백업 또는 자동 백업 설정을 다시 확인하세요.'
        : 'The last backup is getting old. Run a manual backup or verify the automation settings.';
  }
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
