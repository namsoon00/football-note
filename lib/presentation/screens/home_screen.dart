import 'package:flutter/material.dart';
import '../../application/training_service.dart';
import '../../domain/repositories/option_repository.dart';
import '../../application/locale_service.dart';
import '../../application/settings_service.dart';
import '../../application/backup_service.dart';
import 'package:football_note/gen/app_localizations.dart';
import 'calendar_screen.dart';
import 'logs_screen.dart';
import 'stats_screen.dart';
import 'news_screen.dart';
import 'space_speed_game_screen.dart';
import 'entry_form_screen.dart';

class HomeScreen extends StatefulWidget {
  final TrainingService trainingService;
  final OptionRepository optionRepository;
  final LocaleService localeService;
  final SettingsService settingsService;
  final BackupService? driveBackupService;
  final int initialIndex;

  const HomeScreen({
    super.key,
    required this.trainingService,
    required this.optionRepository,
    required this.localeService,
    required this.settingsService,
    this.driveBackupService,
    this.initialIndex = 0,
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late int _index;

  @override
  void initState() {
    super.initState();
    _index = widget.initialIndex;
  }

  @override
  Widget build(BuildContext context) {
    final navBackground = Theme.of(context).colorScheme.surface;
    final pages = [
      LogsScreen(
        trainingService: widget.trainingService,
        localeService: widget.localeService,
        optionRepository: widget.optionRepository,
        settingsService: widget.settingsService,
        driveBackupService: widget.driveBackupService,
        onEdit: _openEdit,
        onCreate: _openCreate,
      ),
      CalendarScreen(
        trainingService: widget.trainingService,
        localeService: widget.localeService,
        optionRepository: widget.optionRepository,
        settingsService: widget.settingsService,
        driveBackupService: widget.driveBackupService,
        onEdit: _openEdit,
        onCreate: _openCreate,
      ),
      StatsScreen(
        trainingService: widget.trainingService,
        localeService: widget.localeService,
        onCreate: _openCreate,
        optionRepository: widget.optionRepository,
        settingsService: widget.settingsService,
        driveBackupService: widget.driveBackupService,
      ),
      NewsScreen(
        trainingService: widget.trainingService,
        localeService: widget.localeService,
        optionRepository: widget.optionRepository,
        settingsService: widget.settingsService,
        driveBackupService: widget.driveBackupService,
      ),
      SpaceSpeedGameScreen(
        trainingService: widget.trainingService,
        localeService: widget.localeService,
        optionRepository: widget.optionRepository,
        settingsService: widget.settingsService,
        driveBackupService: widget.driveBackupService,
      ),
    ];

    return Scaffold(
      body: pages[_index],
      bottomNavigationBar: NavigationBar(
        backgroundColor: navBackground,
        indicatorColor: Theme.of(context).colorScheme.primary.withAlpha(38),
        labelBehavior: NavigationDestinationLabelBehavior.onlyShowSelected,
        selectedIndex: _index,
        onDestinationSelected: (value) => setState(() => _index = value),
        destinations: [
          NavigationDestination(
            icon: const Icon(Icons.list_alt_outlined),
            selectedIcon: const Icon(Icons.list_alt),
            label: AppLocalizations.of(context)!.tabLogs,
          ),
          NavigationDestination(
            icon: const Icon(Icons.calendar_month_outlined),
            selectedIcon: const Icon(Icons.calendar_month),
            label: AppLocalizations.of(context)!.tabCalendar,
          ),
          NavigationDestination(
            icon: const Icon(Icons.bar_chart_outlined),
            selectedIcon: const Icon(Icons.bar_chart),
            label: AppLocalizations.of(context)!.tabStats,
          ),
          NavigationDestination(
            icon: const Icon(Icons.newspaper_outlined),
            selectedIcon: const Icon(Icons.newspaper),
            label: AppLocalizations.of(context)!.tabNews,
          ),
          NavigationDestination(
            icon: const Icon(Icons.sports_esports_outlined),
            selectedIcon: const Icon(Icons.sports_esports),
            label: AppLocalizations.of(context)!.tabGame,
          ),
        ],
      ),
      floatingActionButton: _index >= 2
          ? null
          : FloatingActionButton.extended(
              onPressed: _openCreate,
              icon: const Icon(Icons.add),
              label: Text(AppLocalizations.of(context)!.addEntry),
            ),
    );
  }

  Future<void> _openCreate() async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => EntryFormScreen(
          trainingService: widget.trainingService,
          optionRepository: widget.optionRepository,
          localeService: widget.localeService,
          settingsService: widget.settingsService,
          driveBackupService: widget.driveBackupService,
        ),
      ),
    );
  }

  Future<void> _openEdit(entry) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => EntryFormScreen(
          trainingService: widget.trainingService,
          optionRepository: widget.optionRepository,
          entry: entry,
          localeService: widget.localeService,
          settingsService: widget.settingsService,
          driveBackupService: widget.driveBackupService,
        ),
      ),
    );
  }
}
