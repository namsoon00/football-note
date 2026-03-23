import 'package:flutter/material.dart';
import '../../application/locale_service.dart';
import '../../application/settings_service.dart';
import '../../application/training_service.dart';
import '../../application/backup_service.dart';
import '../../domain/repositories/option_repository.dart';
import '../screens/entry_form_screen.dart';
import '../screens/home_screen.dart';
import '../screens/settings_screen.dart';
import '../screens/calendar_screen.dart';
import '../screens/training_method_board_screen.dart';
import '../screens/news_screen.dart';
import '../screens/notification_center_screen.dart';
import '../screens/skill_quiz_screen.dart';
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
    final isKo = Localizations.localeOf(context).languageCode == 'ko';
    return Drawer(
      child: SafeArea(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
              child: Text(
                l10n.appTitle,
                style: Theme.of(context).textTheme.titleLarge,
              ),
            ),
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
              child: Text(
                isKo ? '주요 화면' : 'Main screens',
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
              ),
            ),
            _NavTile(
              icon: Icons.home,
              label: l10n.tabHome,
              selected: currentIndex == 0,
              onTap: () => _navigateTo(context, 0),
            ),
            _NavTile(
              icon: Icons.list_alt,
              label: l10n.tabLogs,
              selected: currentIndex == 1,
              onTap: () => _navigateTo(context, 1),
            ),
            _NavTile(
              icon: Icons.calendar_month,
              label: l10n.tabCalendar,
              selected: currentIndex == 2,
              onTap: () => _navigateTo(context, 2),
            ),
            _NavTile(
              icon: Icons.bar_chart,
              label: l10n.tabStats,
              selected: currentIndex == 3,
              onTap: () => _navigateTo(context, 3),
            ),
            const SizedBox(height: 4),
            _DrawerSection(
              title: isKo ? '빠른 추가' : 'Quick add',
              icon: Icons.add_circle_outline,
              initiallyExpanded: true,
              children: [
                _DrawerActionTile(
                  icon: Icons.note_add_outlined,
                  label: l10n.addEntry,
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
                _DrawerActionTile(
                  icon: Icons.event_note_outlined,
                  label: isKo ? '훈련 계획' : 'Training plan',
                  onTap: () => _navigateTo(
                    context,
                    2,
                    calendarQuickCreateAction: CalendarQuickCreateAction.plan,
                  ),
                ),
                _DrawerActionTile(
                  icon: Icons.sports_soccer_outlined,
                  label: isKo ? '시합' : 'Match',
                  onTap: () => _navigateTo(
                    context,
                    2,
                    calendarQuickCreateAction: CalendarQuickCreateAction.match,
                  ),
                ),
                _DrawerActionTile(
                  icon: Icons.developer_board_outlined,
                  label: isKo ? '훈련 스케치' : 'Add training sketch',
                  onTap: () {
                    Navigator.of(context).pop();
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => TrainingMethodBoardScreen(
                          boardTitle: '',
                          initialLayoutJson: '',
                          optionRepository: optionRepository,
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
            _DrawerSection(
              title: isKo ? '도구와 콘텐츠' : 'Tools and content',
              icon: Icons.dashboard_customize_outlined,
              children: [
                _DrawerActionTile(
                  icon: Icons.newspaper_outlined,
                  label: l10n.tabNews,
                  onTap: () {
                    Navigator.of(context).pop();
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => NewsScreen(
                          trainingService: trainingService,
                          localeService: localeService,
                          optionRepository: optionRepository,
                          settingsService: settingsService,
                          driveBackupService: driveBackupService,
                          isActive: true,
                        ),
                      ),
                    );
                  },
                ),
                _DrawerActionTile(
                  icon: Icons.notifications_outlined,
                  label: isKo ? '알림' : 'Notifications',
                  onTap: () {
                    Navigator.of(context).pop();
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => NotificationCenterScreen(
                          optionRepository: optionRepository,
                          settingsService: settingsService,
                        ),
                      ),
                    );
                  },
                ),
                _DrawerActionTile(
                  icon: Icons.quiz_outlined,
                  label: isKo ? '퀴즈' : 'Quiz',
                  onTap: () {
                    Navigator.of(context).pop();
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => SkillQuizScreen(
                          optionRepository: optionRepository,
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
            _DrawerSection(
              title: isKo ? '설정' : 'Settings',
              icon: Icons.settings_outlined,
              children: [
                _DrawerActionTile(
                  icon: Icons.settings,
                  label: l10n.settings,
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
          ],
        ),
      ),
    );
  }

  void _navigateTo(
    BuildContext context,
    int index, {
    CalendarQuickCreateAction? calendarQuickCreateAction,
  }) {
    Navigator.of(context).pop();
    if (index == currentIndex && calendarQuickCreateAction == null) {
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
          calendarQuickCreateAction: calendarQuickCreateAction,
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

class _DrawerSection extends StatelessWidget {
  final String title;
  final IconData icon;
  final List<Widget> children;
  final bool initiallyExpanded;

  const _DrawerSection({
    required this.title,
    required this.icon,
    required this.children,
    this.initiallyExpanded = false,
  });

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
      child: ExpansionTile(
        leading: Icon(icon),
        title: Text(
          title,
          style: Theme.of(
            context,
          ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
        ),
        tilePadding: const EdgeInsets.symmetric(horizontal: 16),
        childrenPadding: const EdgeInsets.only(bottom: 4),
        initiallyExpanded: initiallyExpanded,
        children: children,
      ),
    );
  }
}

class _DrawerActionTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _DrawerActionTile({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      dense: true,
      leading: Icon(icon),
      minLeadingWidth: 24,
      contentPadding: const EdgeInsets.fromLTRB(28, 0, 16, 0),
      title: Text(label),
      onTap: onTap,
    );
  }
}
