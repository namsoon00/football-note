import 'package:flutter/material.dart';
import 'package:football_note/gen/app_localizations.dart';

import '../models/training_board_templates.dart';
import '../widgets/app_background.dart';
import '../widgets/training_board_sketch.dart';
import '../widgets/watch_cart/watch_cart_card.dart';

class TrainingBoardTemplateGalleryScreen extends StatelessWidget {
  const TrainingBoardTemplateGalleryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final templates = buildTrainingBoardTemplateOptions(l10n);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.trainingSketchTemplateGalleryTitle)),
      body: AppBackground(
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
            children: [
              Text(
                l10n.trainingSketchTemplateGallerySubtitle,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 12),
              for (final template in templates) ...[
                _TemplatePreviewCard(template: template),
                const SizedBox(height: 12),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _TemplatePreviewCard extends StatelessWidget {
  final TrainingBoardTemplateOption template;

  const _TemplatePreviewCard({required this.template});

  @override
  Widget build(BuildContext context) {
    final layout = template.buildLayout(template.label);
    final page = layout.pages.first;
    return WatchCartCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(template.icon),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  template.label,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            template.description,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 180,
            child: TrainingBoardSketch(page: page, showItemCountBadge: true),
          ),
          if (page.methodText.trim().isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(
              page.methodText.trim(),
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ],
      ),
    );
  }
}
