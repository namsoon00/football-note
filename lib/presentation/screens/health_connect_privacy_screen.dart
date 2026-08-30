import 'package:flutter/material.dart';
import 'package:football_note/gen/app_localizations.dart';

class HealthConnectPrivacyScreen extends StatelessWidget {
  const HealthConnectPrivacyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final sections = <({IconData icon, String title, String body})>[
      (
        icon: Icons.fitness_center_outlined,
        title: l10n.healthConnectPrivacyDataTitle,
        body: l10n.healthConnectPrivacyDataBody,
      ),
      (
        icon: Icons.verified_user_outlined,
        title: l10n.healthConnectPrivacySourceTitle,
        body: l10n.healthConnectPrivacySourceBody,
      ),
      (
        icon: Icons.smartphone_outlined,
        title: l10n.healthConnectPrivacyStorageTitle,
        body: l10n.healthConnectPrivacyStorageBody,
      ),
      (
        icon: Icons.track_changes_outlined,
        title: l10n.healthConnectPrivacyUseTitle,
        body: l10n.healthConnectPrivacyUseBody,
      ),
      (
        icon: Icons.tune_outlined,
        title: l10n.healthConnectPrivacyControlTitle,
        body: l10n.healthConnectPrivacyControlBody,
      ),
    ];
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.healthConnectPrivacyTitle),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
        children: [
          Text(
            l10n.healthConnectPrivacyIntro,
            style: Theme.of(context).textTheme.bodyLarge,
          ),
          const SizedBox(height: 20),
          for (var index = 0; index < sections.length; index += 1) ...[
            _PrivacySection(section: sections[index]),
            if (index != sections.length - 1) const Divider(height: 28),
          ],
        ],
      ),
    );
  }
}

class _PrivacySection extends StatelessWidget {
  final ({IconData icon, String title, String body}) section;

  const _PrivacySection({required this.section});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(section.icon, color: theme.colorScheme.primary),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                section.title,
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 6),
              Text(section.body, style: theme.textTheme.bodyMedium),
            ],
          ),
        ),
      ],
    );
  }
}
