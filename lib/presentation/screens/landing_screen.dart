import 'package:flutter/material.dart';
import 'package:football_note/gen/app_localizations.dart';
import '../../application/locale_service.dart';
import '../../application/meal_log_service.dart';
import '../../application/settings_service.dart';
import '../../application/training_service.dart';
import '../../application/backup_service.dart';
import '../../domain/repositories/option_repository.dart';
import 'home_screen.dart';
import '../widgets/watch_cart/primary_button.dart';

class LandingScreen extends StatelessWidget {
  final TrainingService trainingService;
  final OptionRepository optionRepository;
  final LocaleService localeService;
  final SettingsService settingsService;
  final BackupService? driveBackupService;
  final VoidCallback? onStart;

  const LandingScreen({
    super.key,
    required this.trainingService,
    required this.optionRepository,
    required this.localeService,
    required this.settingsService,
    this.driveBackupService,
    this.onStart,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final textTheme = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 14),
              Text(
                '내아들 태오에게 바치는 앱',
                style: textTheme.bodyMedium?.copyWith(
                  color: scheme.primary,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 14),
              Text(
                l10n.onboard1,
                style: textTheme.headlineLarge,
              ),
              const SizedBox(height: 8),
              Text(
                l10n.onboard3,
                style: textTheme.titleLarge,
              ),
              const SizedBox(height: 16),
              Text(
                l10n.heroMessage,
                style: textTheme.bodyMedium?.copyWith(
                  color: const Color(0xFF6B7280),
                  height: 1.45,
                ),
              ),
              const SizedBox(height: 28),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: scheme.surface,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: scheme.outline),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x10111F3C),
                      blurRadius: 16,
                      offset: Offset(0, 6),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    _FeatureRow(
                      icon: Icons.edit_note_rounded,
                      title: l10n.addEntry,
                      subtitle: l10n.onboard2,
                    ),
                    const SizedBox(height: 14),
                    _FeatureRow(
                      icon: Icons.calendar_month_rounded,
                      title: l10n.tabCalendar,
                      subtitle: l10n.logsHeadline2,
                    ),
                    const SizedBox(height: 14),
                    _FeatureRow(
                      icon: Icons.bar_chart_rounded,
                      title: l10n.tabStats,
                      subtitle: l10n.tabStats,
                    ),
                  ],
                ),
              ),
              const Spacer(),
              WatchCartPrimaryButton(
                text: l10n.start,
                onPressed: () {
                  if (onStart != null) {
                    onStart!.call();
                    return;
                  }
                  Navigator.of(context).pushReplacement(
                    MaterialPageRoute(
                      builder: (_) => HomeScreen(
                        trainingService: trainingService,
                        mealLogService: MealLogService(optionRepository),
                        optionRepository: optionRepository,
                        localeService: localeService,
                        settingsService: settingsService,
                        driveBackupService: driveBackupService,
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }
}

class _FeatureRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const _FeatureRow({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    return Row(
      children: [
        Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: scheme.primary.withAlpha(22),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: scheme.primary, size: 20),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: textTheme.titleMedium),
              const SizedBox(height: 2),
              Text(
                subtitle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: textTheme.bodySmall,
              ),
            ],
          ),
        ),
      ],
    );
  }
}
