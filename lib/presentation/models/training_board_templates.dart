import 'package:flutter/material.dart';
import 'package:football_note/gen/app_localizations.dart';

import 'training_method_layout.dart';

class TrainingBoardTemplateOption {
  final String id;
  final IconData icon;
  final String label;
  final String description;
  final TrainingMethodLayout Function(String title) buildLayout;

  const TrainingBoardTemplateOption({
    required this.id,
    required this.icon,
    required this.label,
    required this.description,
    required this.buildLayout,
  });
}

Future<TrainingBoardTemplateOption?> showTrainingBoardTemplatePicker(
  BuildContext context,
) {
  final l10n = AppLocalizations.of(context)!;
  final templates = buildTrainingBoardTemplateOptions(l10n);
  return showModalBottomSheet<TrainingBoardTemplateOption>(
    context: context,
    showDragHandle: true,
    builder: (context) => SafeArea(
      child: ListView(
        shrinkWrap: true,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
            child: Text(
              l10n.trainingSketchTemplatePickerTitle,
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ),
          ...templates.map(
            (template) => ListTile(
              leading: Icon(template.icon),
              title: Text(template.label),
              subtitle: Text(template.description),
              onTap: () => Navigator.of(context).pop(template),
            ),
          ),
        ],
      ),
    ),
  );
}

List<TrainingBoardTemplateOption> buildTrainingBoardTemplateOptions(
  AppLocalizations l10n,
) {
  const playerBlue = 0xFF1E88E5;
  const playerRed = 0xFFE53935;
  const playerGreen = 0xFF43A047;
  const coneOrange = 0xFFFFA000;
  const conePurple = 0xFF8E24AA;

  TrainingMethodItem player(
    double x,
    double y, {
    int color = playerBlue,
    double size = 32,
  }) => TrainingMethodItem(
    type: 'player',
    x: x,
    y: y,
    size: size,
    rotationDeg: 0,
    colorValue: color,
  );

  TrainingMethodItem ball(double x, double y, {double size = 30}) =>
      TrainingMethodItem(
        type: 'ball',
        x: x,
        y: y,
        size: size,
        rotationDeg: 0,
        colorValue: 0xFFFFFFFF,
      );

  TrainingMethodItem cone(
    double x,
    double y, {
    int color = coneOrange,
    double size = 30,
  }) => TrainingMethodItem(
    type: 'cone',
    x: x,
    y: y,
    size: size,
    rotationDeg: 0,
    colorValue: color,
  );

  TrainingMethodLayout onePage({
    required String title,
    required String methodText,
    required List<TrainingMethodItem> items,
  }) => TrainingMethodLayout(
    pages: <TrainingMethodPage>[
      TrainingMethodPage(name: title, methodText: methodText, items: items),
    ],
  );

  TrainingMethodLayout blank(String title) => TrainingMethodLayout(
    pages: <TrainingMethodPage>[
      TrainingMethodPage(name: title, items: const <TrainingMethodItem>[]),
    ],
  );

  TrainingMethodLayout passWarmup(String title) => onePage(
    title: title,
    methodText: l10n.trainingSketchTemplatePassWarmupMethod,
    items: <TrainingMethodItem>[
      player(0.2, 0.5),
      player(0.5, 0.25),
      player(0.8, 0.5),
      cone(0.5, 0.75),
      ball(0.2, 0.5),
    ],
  );

  TrainingMethodLayout buildUp(String title) => onePage(
    title: title,
    methodText: l10n.trainingSketchTemplateBuildUpMethod,
    items: <TrainingMethodItem>[
      player(0.2, 0.8),
      player(0.5, 0.82),
      player(0.8, 0.8),
      player(0.38, 0.58),
      player(0.62, 0.58),
      ball(0.5, 0.82),
    ],
  );

  TrainingMethodLayout pressing(String title) => onePage(
    title: title,
    methodText: l10n.trainingSketchTemplatePressingMethod,
    items: <TrainingMethodItem>[
      player(0.3, 0.35, color: playerRed),
      player(0.5, 0.42, color: playerRed),
      player(0.7, 0.35, color: playerRed),
      ball(0.5, 0.18),
    ],
  );

  TrainingMethodLayout setPiece(String title) => onePage(
    title: title,
    methodText: l10n.trainingSketchTemplateSetPieceMethod,
    items: <TrainingMethodItem>[
      ball(0.06, 0.08),
      player(0.2, 0.2),
      player(0.3, 0.28),
      player(0.38, 0.36),
      player(0.45, 0.24, color: playerRed),
      player(0.56, 0.32, color: playerRed),
      player(0.66, 0.4, color: playerRed),
    ],
  );

  TrainingMethodLayout rondo(String title) => onePage(
    title: title,
    methodText: l10n.trainingSketchTemplateRondoMethod,
    items: <TrainingMethodItem>[
      player(0.24, 0.28),
      player(0.76, 0.28),
      player(0.24, 0.72),
      player(0.76, 0.72),
      player(0.5, 0.5, color: playerRed),
      ball(0.24, 0.28),
      cone(0.18, 0.2, color: conePurple),
      cone(0.82, 0.2, color: conePurple),
      cone(0.18, 0.8, color: conePurple),
      cone(0.82, 0.8, color: conePurple),
    ],
  );

  TrainingMethodLayout finishing(String title) => onePage(
    title: title,
    methodText: l10n.trainingSketchTemplateFinishingMethod,
    items: <TrainingMethodItem>[
      ball(0.16, 0.76),
      player(0.16, 0.76),
      player(0.34, 0.6),
      player(0.54, 0.42),
      player(0.72, 0.32),
      player(0.82, 0.22, color: playerRed),
      player(0.82, 0.46, color: playerRed),
      cone(0.3, 0.78),
      cone(0.48, 0.64),
      cone(0.66, 0.5),
    ],
  );

  TrainingMethodLayout wingCombination(String title) => onePage(
    title: title,
    methodText: l10n.trainingSketchTemplateWingCombinationMethod,
    items: <TrainingMethodItem>[
      ball(0.18, 0.68),
      player(0.18, 0.68),
      player(0.3, 0.52),
      player(0.42, 0.78, color: playerGreen),
      player(0.62, 0.48),
      player(0.74, 0.34),
      player(0.5, 0.42, color: playerRed),
      player(0.7, 0.6, color: playerRed),
      cone(0.26, 0.84),
      cone(0.56, 0.74),
    ],
  );

  TrainingMethodLayout transitionAttack(String title) => onePage(
    title: title,
    methodText: l10n.trainingSketchTemplateTransitionAttackMethod,
    items: <TrainingMethodItem>[
      ball(0.34, 0.54),
      player(0.34, 0.54),
      player(0.5, 0.42),
      player(0.68, 0.3),
      player(0.24, 0.3, color: playerRed),
      player(0.52, 0.2, color: playerRed),
      player(0.74, 0.58, color: playerRed),
      cone(0.12, 0.64),
      cone(0.3, 0.18),
      cone(0.84, 0.16),
    ],
  );

  return <TrainingBoardTemplateOption>[
    TrainingBoardTemplateOption(
      id: 'blank',
      icon: Icons.dashboard_outlined,
      label: l10n.trainingSketchTemplateBlankLabel,
      description: l10n.trainingSketchTemplateBlankDescription,
      buildLayout: blank,
    ),
    TrainingBoardTemplateOption(
      id: 'pass_warmup',
      icon: Icons.sports_soccer_outlined,
      label: l10n.trainingSketchTemplatePassWarmupLabel,
      description: l10n.trainingSketchTemplatePassWarmupDescription,
      buildLayout: passWarmup,
    ),
    TrainingBoardTemplateOption(
      id: 'build_up',
      icon: Icons.account_tree_outlined,
      label: l10n.trainingSketchTemplateBuildUpLabel,
      description: l10n.trainingSketchTemplateBuildUpDescription,
      buildLayout: buildUp,
    ),
    TrainingBoardTemplateOption(
      id: 'pressing',
      icon: Icons.bolt_outlined,
      label: l10n.trainingSketchTemplatePressingLabel,
      description: l10n.trainingSketchTemplatePressingDescription,
      buildLayout: pressing,
    ),
    TrainingBoardTemplateOption(
      id: 'set_piece',
      icon: Icons.flag_outlined,
      label: l10n.trainingSketchTemplateSetPieceLabel,
      description: l10n.trainingSketchTemplateSetPieceDescription,
      buildLayout: setPiece,
    ),
    TrainingBoardTemplateOption(
      id: 'rondo',
      icon: Icons.loop_rounded,
      label: l10n.trainingSketchTemplateRondoLabel,
      description: l10n.trainingSketchTemplateRondoDescription,
      buildLayout: rondo,
    ),
    TrainingBoardTemplateOption(
      id: 'finishing',
      icon: Icons.gps_fixed,
      label: l10n.trainingSketchTemplateFinishingLabel,
      description: l10n.trainingSketchTemplateFinishingDescription,
      buildLayout: finishing,
    ),
    TrainingBoardTemplateOption(
      id: 'wing_combination',
      icon: Icons.timeline_rounded,
      label: l10n.trainingSketchTemplateWingCombinationLabel,
      description: l10n.trainingSketchTemplateWingCombinationDescription,
      buildLayout: wingCombination,
    ),
    TrainingBoardTemplateOption(
      id: 'transition_attack',
      icon: Icons.north_east_rounded,
      label: l10n.trainingSketchTemplateTransitionAttackLabel,
      description: l10n.trainingSketchTemplateTransitionAttackDescription,
      buildLayout: transitionAttack,
    ),
  ];
}
