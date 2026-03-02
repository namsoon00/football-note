import 'package:flutter/material.dart';
import '../../application/locale_service.dart';
import '../../application/settings_service.dart';
import '../../application/training_service.dart';
import '../../application/backup_service.dart';
import '../../domain/repositories/option_repository.dart';
import '../screens/entry_form_screen.dart';
import '../screens/home_screen.dart';
import '../screens/settings_screen.dart';
import 'package:football_note/gen/app_localizations.dart';

class AppDrawer extends StatelessWidget {
  final TrainingService trainingService;
  final OptionRepository optionRepository;
  final LocaleService localeService;
  final SettingsService settingsService;
  final BackupService? driveBackupService;
  final int currentIndex;

  const AppDrawer({
    super.key,
    required this.trainingService,
    required this.optionRepository,
    required this.localeService,
    required this.settingsService,
    this.driveBackupService,
    required this.currentIndex,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Drawer(
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                l10n.appTitle,
                style: Theme.of(context).textTheme.titleLarge,
              ),
            ),
            const Divider(height: 1),
            _NavTile(
              icon: Icons.list_alt,
              label: l10n.tabLogs,
              selected: currentIndex == 0,
              onTap: () => _navigateTo(context, 0),
            ),
            _NavTile(
              icon: Icons.calendar_month,
              label: l10n.tabCalendar,
              selected: currentIndex == 1,
              onTap: () => _navigateTo(context, 1),
            ),
            _NavTile(
              icon: Icons.bar_chart,
              label: l10n.tabStats,
              selected: currentIndex == 2,
              onTap: () => _navigateTo(context, 2),
            ),
            _NavTile(
              icon: Icons.newspaper,
              label: l10n.tabNews,
              selected: currentIndex == 3,
              onTap: () => _navigateTo(context, 3),
            ),
            _NavTile(
              icon: Icons.sports_esports,
              label: l10n.tabGame,
              selected: currentIndex == 4,
              onTap: () => _navigateTo(context, 4),
            ),
            const Divider(height: 1),
            ListTile(
              leading: const Icon(Icons.add_circle_outline),
              title: Text(l10n.addEntry),
              onTap: () {
                Navigator.of(context).pop();
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => EntryFormScreen(
                      trainingService: trainingService,
                      optionRepository: optionRepository,
                      localeService: localeService,
                      settingsService: settingsService,
                      driveBackupService: driveBackupService,
                    ),
                  ),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.settings),
              title: Text(l10n.settings),
              onTap: () {
                Navigator.of(context).pop();
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => SettingsScreen(
                      localeService: localeService,
                      settingsService: settingsService,
                      optionRepository: optionRepository,
                      driveBackupService: driveBackupService,
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  void _navigateTo(BuildContext context, int index) {
    Navigator.of(context).pop();
    if (index == currentIndex) {
      return;
    }
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => HomeScreen(
          trainingService: trainingService,
          optionRepository: optionRepository,
          localeService: localeService,
          settingsService: settingsService,
          driveBackupService: driveBackupService,
          initialIndex: index,
        ),
      ),
    );
  }
}

class _NavTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _NavTile({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon),
      title: Text(label),
      selected: selected,
      onTap: onTap,
    );
  }
}
