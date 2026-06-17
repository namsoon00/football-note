import 'package:flutter/material.dart';
import 'package:football_note/gen/app_localizations.dart';

import '../../domain/entities/sport_definition.dart';
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
  BuildContext context, {
  Future<void> Function()? onOpenGallery,
  String? sportId,
}) {
  final l10n = AppLocalizations.of(context)!;
  final templates = buildTrainingBoardTemplateOptions(l10n, sportId: sportId);
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
          if (onOpenGallery != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
              child: Align(
                alignment: Alignment.centerRight,
                child: TextButton.icon(
                  onPressed: () => onOpenGallery(),
                  icon: const Icon(Icons.grid_view_rounded),
                  label: Text(l10n.trainingSketchTemplateGalleryAction),
                ),
              ),
            ),
        ],
      ),
    ),
  );
}

List<TrainingBoardTemplateOption> buildTrainingBoardTemplateOptions(
  AppLocalizations l10n, {
  String? sportId,
}) {
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
  }) =>
      TrainingMethodItem(
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
  }) =>
      TrainingMethodItem(
        type: 'cone',
        x: x,
        y: y,
        size: size,
        rotationDeg: 0,
        colorValue: color,
      );

  TrainingMethodPoint point(double x, double y) =>
      TrainingMethodPoint(x: x, y: y);

  TrainingMethodRoute route(
    String id,
    TrainingMethodRouteKind kind,
    List<TrainingMethodPoint> points,
  ) =>
      TrainingMethodRoute(id: id, kind: kind, points: points);

  TrainingMethodLayout onePage({
    required String title,
    required String methodText,
    required List<TrainingMethodItem> items,
    List<TrainingMethodRoute> routes = const <TrainingMethodRoute>[],
  }) =>
      TrainingMethodLayout(
        pages: <TrainingMethodPage>[
          TrainingMethodPage(
            name: title,
            methodText: methodText,
            items: items,
            routes: routes,
          ),
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
        routes: <TrainingMethodRoute>[
          route(
            'pass_warmup_player',
            TrainingMethodRouteKind.player,
            <TrainingMethodPoint>[
              point(0.5, 0.75),
              point(0.42, 0.62),
              point(0.35, 0.48),
            ],
          ),
          route(
            'pass_warmup_player_support_top',
            TrainingMethodRouteKind.player,
            <TrainingMethodPoint>[
              point(0.5, 0.25),
              point(0.62, 0.34),
              point(0.72, 0.44),
            ],
          ),
          route(
            'pass_warmup_player_support_right',
            TrainingMethodRouteKind.player,
            <TrainingMethodPoint>[
              point(0.8, 0.5),
              point(0.7, 0.62),
              point(0.56, 0.72),
            ],
          ),
          route(
            'pass_warmup_ball',
            TrainingMethodRouteKind.ball,
            <TrainingMethodPoint>[
              point(0.2, 0.5),
              point(0.5, 0.25),
              point(0.8, 0.5),
            ],
          ),
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
        routes: <TrainingMethodRoute>[
          route(
            'build_up_left_player',
            TrainingMethodRouteKind.player,
            <TrainingMethodPoint>[
              point(0.2, 0.8),
              point(0.24, 0.7),
              point(0.3, 0.6),
            ],
          ),
          route(
            'build_up_right_player',
            TrainingMethodRouteKind.player,
            <TrainingMethodPoint>[
              point(0.8, 0.8),
              point(0.74, 0.7),
              point(0.68, 0.6),
            ],
          ),
          route(
            'build_up_player',
            TrainingMethodRouteKind.player,
            <TrainingMethodPoint>[
              point(0.38, 0.58),
              point(0.44, 0.5),
              point(0.5, 0.42),
            ],
          ),
          route(
            'build_up_mid_support',
            TrainingMethodRouteKind.player,
            <TrainingMethodPoint>[
              point(0.62, 0.58),
              point(0.58, 0.48),
              point(0.52, 0.38),
            ],
          ),
          route(
            'build_up_ball',
            TrainingMethodRouteKind.ball,
            <TrainingMethodPoint>[
              point(0.5, 0.82),
              point(0.38, 0.58),
              point(0.5, 0.42),
              point(0.62, 0.58),
            ],
          ),
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
        routes: <TrainingMethodRoute>[
          route(
            'pressing_left_player',
            TrainingMethodRouteKind.player,
            <TrainingMethodPoint>[
              point(0.3, 0.35),
              point(0.36, 0.28),
              point(0.44, 0.22),
            ],
          ),
          route(
            'pressing_player',
            TrainingMethodRouteKind.player,
            <TrainingMethodPoint>[
              point(0.5, 0.42),
              point(0.5, 0.3),
              point(0.48, 0.2),
            ],
          ),
          route(
            'pressing_right_player',
            TrainingMethodRouteKind.player,
            <TrainingMethodPoint>[
              point(0.7, 0.35),
              point(0.64, 0.28),
              point(0.56, 0.22),
            ],
          ),
          route(
            'pressing_ball',
            TrainingMethodRouteKind.ball,
            <TrainingMethodPoint>[
              point(0.5, 0.18),
              point(0.42, 0.24),
              point(0.32, 0.34),
            ],
          ),
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
        routes: <TrainingMethodRoute>[
          route(
            'set_piece_near_post_run',
            TrainingMethodRouteKind.player,
            <TrainingMethodPoint>[
              point(0.2, 0.2),
              point(0.3, 0.24),
              point(0.38, 0.3),
            ],
          ),
          route(
            'set_piece_player',
            TrainingMethodRouteKind.player,
            <TrainingMethodPoint>[
              point(0.3, 0.28),
              point(0.4, 0.34),
              point(0.5, 0.42),
            ],
          ),
          route(
            'set_piece_far_post_run',
            TrainingMethodRouteKind.player,
            <TrainingMethodPoint>[
              point(0.38, 0.36),
              point(0.5, 0.4),
              point(0.64, 0.44),
            ],
          ),
          route(
            'set_piece_ball',
            TrainingMethodRouteKind.ball,
            <TrainingMethodPoint>[
              point(0.06, 0.08),
              point(0.28, 0.16),
              point(0.48, 0.3),
              point(0.66, 0.4),
            ],
          ),
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
        routes: <TrainingMethodRoute>[
          route(
            'rondo_left_support',
            TrainingMethodRouteKind.player,
            <TrainingMethodPoint>[
              point(0.24, 0.28),
              point(0.22, 0.5),
              point(0.24, 0.72),
            ],
          ),
          route(
            'rondo_player',
            TrainingMethodRouteKind.player,
            <TrainingMethodPoint>[
              point(0.5, 0.5),
              point(0.56, 0.44),
              point(0.62, 0.38),
            ],
          ),
          route(
            'rondo_right_support',
            TrainingMethodRouteKind.player,
            <TrainingMethodPoint>[
              point(0.76, 0.28),
              point(0.78, 0.5),
              point(0.76, 0.72),
            ],
          ),
          route(
              'rondo_ball', TrainingMethodRouteKind.ball, <TrainingMethodPoint>[
            point(0.24, 0.28),
            point(0.5, 0.24),
            point(0.76, 0.28),
            point(0.76, 0.72),
            point(0.24, 0.72),
            point(0.76, 0.28),
          ]),
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
        routes: <TrainingMethodRoute>[
          route(
            'finishing_overlap',
            TrainingMethodRouteKind.player,
            <TrainingMethodPoint>[
              point(0.34, 0.6),
              point(0.48, 0.52),
              point(0.62, 0.48),
            ],
          ),
          route(
            'finishing_player',
            TrainingMethodRouteKind.player,
            <TrainingMethodPoint>[
              point(0.16, 0.76),
              point(0.38, 0.56),
              point(0.64, 0.36),
              point(0.82, 0.22),
            ],
          ),
          route(
            'finishing_box_run',
            TrainingMethodRouteKind.player,
            <TrainingMethodPoint>[
              point(0.72, 0.32),
              point(0.8, 0.34),
              point(0.84, 0.46),
            ],
          ),
          route(
            'finishing_ball',
            TrainingMethodRouteKind.ball,
            <TrainingMethodPoint>[
              point(0.16, 0.76),
              point(0.4, 0.54),
              point(0.68, 0.34),
              point(0.84, 0.24),
            ],
          ),
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
        routes: <TrainingMethodRoute>[
          route(
            'wing_combination_overlap',
            TrainingMethodRouteKind.player,
            <TrainingMethodPoint>[
              point(0.42, 0.78),
              point(0.52, 0.68),
              point(0.62, 0.48),
            ],
          ),
          route(
            'wing_combination_player',
            TrainingMethodRouteKind.player,
            <TrainingMethodPoint>[
              point(0.42, 0.78),
              point(0.52, 0.62),
              point(0.62, 0.48),
            ],
          ),
          route(
            'wing_combination_box_run',
            TrainingMethodRouteKind.player,
            <TrainingMethodPoint>[
              point(0.74, 0.34),
              point(0.78, 0.42),
              point(0.68, 0.56),
            ],
          ),
          route(
            'wing_combination_ball',
            TrainingMethodRouteKind.ball,
            <TrainingMethodPoint>[
              point(0.18, 0.68),
              point(0.3, 0.52),
              point(0.62, 0.48),
              point(0.74, 0.34),
              point(0.66, 0.54),
              point(0.74, 0.34),
            ],
          ),
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
        routes: <TrainingMethodRoute>[
          route(
            'transition_attack_support_left',
            TrainingMethodRouteKind.player,
            <TrainingMethodPoint>[
              point(0.34, 0.54),
              point(0.28, 0.44),
              point(0.24, 0.3),
            ],
          ),
          route(
            'transition_attack_player',
            TrainingMethodRouteKind.player,
            <TrainingMethodPoint>[
              point(0.5, 0.42),
              point(0.6, 0.34),
              point(0.68, 0.3),
            ],
          ),
          route(
            'transition_attack_support_right',
            TrainingMethodRouteKind.player,
            <TrainingMethodPoint>[
              point(0.68, 0.3),
              point(0.74, 0.38),
              point(0.78, 0.48),
            ],
          ),
          route(
            'transition_attack_ball',
            TrainingMethodRouteKind.ball,
            <TrainingMethodPoint>[
              point(0.34, 0.54),
              point(0.5, 0.42),
              point(0.62, 0.32),
              point(0.68, 0.3),
            ],
          ),
        ],
      );

  TrainingMethodLayout baseballThrowing(String title) => onePage(
        title: title,
        methodText: l10n.trainingSketchTemplateBaseballThrowingMethod,
        items: <TrainingMethodItem>[
          player(0.18, 0.5),
          player(0.5, 0.5),
          player(0.82, 0.5),
          cone(0.34, 0.34),
          cone(0.66, 0.66),
          ball(0.18, 0.5),
        ],
        routes: <TrainingMethodRoute>[
          route('baseball_throw_ball', TrainingMethodRouteKind.ball, [
            point(0.18, 0.5),
            point(0.5, 0.5),
            point(0.82, 0.5),
          ]),
          route('baseball_throw_follow', TrainingMethodRouteKind.player, [
            point(0.18, 0.5),
            point(0.34, 0.44),
            point(0.5, 0.5),
          ]),
        ],
      );

  TrainingMethodLayout baseballBatting(String title) => onePage(
        title: title,
        methodText: l10n.trainingSketchTemplateBaseballBattingMethod,
        items: <TrainingMethodItem>[
          player(0.18, 0.7),
          player(0.5, 0.72),
          player(0.74, 0.32, color: playerRed),
          player(0.84, 0.54, color: playerRed),
          ball(0.18, 0.7),
          cone(0.36, 0.58),
          cone(0.58, 0.46),
        ],
        routes: <TrainingMethodRoute>[
          route('baseball_batting_ball', TrainingMethodRouteKind.ball, [
            point(0.18, 0.7),
            point(0.42, 0.58),
            point(0.74, 0.32),
          ]),
          route('baseball_batting_run', TrainingMethodRouteKind.player, [
            point(0.5, 0.72),
            point(0.62, 0.58),
            point(0.84, 0.54),
          ]),
        ],
      );

  TrainingMethodLayout baseballFielding(String title) => onePage(
        title: title,
        methodText: l10n.trainingSketchTemplateBaseballFieldingMethod,
        items: <TrainingMethodItem>[
          player(0.24, 0.72),
          player(0.5, 0.42),
          player(0.78, 0.7),
          ball(0.5, 0.42),
          cone(0.18, 0.82),
          cone(0.82, 0.82),
        ],
        routes: <TrainingMethodRoute>[
          route('baseball_fielding_react', TrainingMethodRouteKind.player, [
            point(0.5, 0.42),
            point(0.38, 0.58),
            point(0.24, 0.72),
          ]),
          route('baseball_fielding_throw', TrainingMethodRouteKind.ball, [
            point(0.24, 0.72),
            point(0.5, 0.42),
            point(0.78, 0.7),
          ]),
        ],
      );

  TrainingMethodLayout basketballShooting(String title) => onePage(
        title: title,
        methodText: l10n.trainingSketchTemplateBasketballShootingMethod,
        items: <TrainingMethodItem>[
          player(0.22, 0.72),
          player(0.5, 0.58),
          player(0.78, 0.72),
          player(0.5, 0.22, color: playerRed),
          ball(0.22, 0.72),
          cone(0.34, 0.48),
          cone(0.66, 0.48),
        ],
        routes: <TrainingMethodRoute>[
          route('basketball_shooting_drive', TrainingMethodRouteKind.player, [
            point(0.22, 0.72),
            point(0.36, 0.54),
            point(0.5, 0.34),
          ]),
          route('basketball_shooting_ball', TrainingMethodRouteKind.ball, [
            point(0.22, 0.72),
            point(0.5, 0.58),
            point(0.5, 0.22),
          ]),
        ],
      );

  TrainingMethodLayout basketballPassing(String title) => onePage(
        title: title,
        methodText: l10n.trainingSketchTemplateBasketballPassingMethod,
        items: <TrainingMethodItem>[
          player(0.2, 0.62),
          player(0.5, 0.4),
          player(0.8, 0.62),
          player(0.5, 0.76, color: playerGreen),
          ball(0.2, 0.62),
          cone(0.36, 0.52),
          cone(0.64, 0.52),
        ],
        routes: <TrainingMethodRoute>[
          route('basketball_passing_cut', TrainingMethodRouteKind.player, [
            point(0.5, 0.76),
            point(0.5, 0.58),
            point(0.5, 0.4),
          ]),
          route('basketball_passing_ball', TrainingMethodRouteKind.ball, [
            point(0.2, 0.62),
            point(0.5, 0.4),
            point(0.8, 0.62),
          ]),
        ],
      );

  TrainingMethodLayout basketballDefense(String title) => onePage(
        title: title,
        methodText: l10n.trainingSketchTemplateBasketballDefenseMethod,
        items: <TrainingMethodItem>[
          player(0.3, 0.72),
          player(0.5, 0.48, color: playerRed),
          player(0.7, 0.72),
          ball(0.5, 0.48),
          cone(0.24, 0.36),
          cone(0.76, 0.36),
        ],
        routes: <TrainingMethodRoute>[
          route(
              'basketball_defense_slide_left', TrainingMethodRouteKind.player, [
            point(0.3, 0.72),
            point(0.24, 0.54),
            point(0.24, 0.36),
          ]),
          route('basketball_defense_slide_right',
              TrainingMethodRouteKind.player, [
            point(0.7, 0.72),
            point(0.76, 0.54),
            point(0.76, 0.36),
          ]),
        ],
      );

  TrainingMethodLayout tennisServe(String title) => onePage(
        title: title,
        methodText: l10n.trainingSketchTemplateTennisServeMethod,
        items: <TrainingMethodItem>[
          player(0.5, 0.82),
          player(0.5, 0.18, color: playerRed),
          ball(0.5, 0.82),
          cone(0.28, 0.42),
          cone(0.72, 0.42),
        ],
        routes: <TrainingMethodRoute>[
          route('tennis_serve_ball', TrainingMethodRouteKind.ball, [
            point(0.5, 0.82),
            point(0.42, 0.56),
            point(0.28, 0.42),
          ]),
          route('tennis_serve_recover', TrainingMethodRouteKind.player, [
            point(0.5, 0.82),
            point(0.5, 0.68),
            point(0.5, 0.54),
          ]),
        ],
      );

  TrainingMethodLayout tennisRally(String title) => onePage(
        title: title,
        methodText: l10n.trainingSketchTemplateTennisRallyMethod,
        items: <TrainingMethodItem>[
          player(0.28, 0.76),
          player(0.72, 0.24, color: playerRed),
          ball(0.28, 0.76),
          cone(0.24, 0.5),
          cone(0.76, 0.5),
        ],
        routes: <TrainingMethodRoute>[
          route('tennis_rally_ball', TrainingMethodRouteKind.ball, [
            point(0.28, 0.76),
            point(0.76, 0.5),
            point(0.72, 0.24),
            point(0.24, 0.5),
          ]),
          route('tennis_rally_recover', TrainingMethodRouteKind.player, [
            point(0.28, 0.76),
            point(0.42, 0.66),
            point(0.5, 0.58),
          ]),
        ],
      );

  TrainingMethodLayout tennisFootwork(String title) => onePage(
        title: title,
        methodText: l10n.trainingSketchTemplateTennisFootworkMethod,
        items: <TrainingMethodItem>[
          player(0.5, 0.76),
          ball(0.5, 0.76),
          cone(0.28, 0.58),
          cone(0.72, 0.58),
          cone(0.36, 0.34),
          cone(0.64, 0.34),
        ],
        routes: <TrainingMethodRoute>[
          route('tennis_footwork_split', TrainingMethodRouteKind.player, [
            point(0.5, 0.76),
            point(0.28, 0.58),
            point(0.5, 0.48),
            point(0.72, 0.58),
            point(0.5, 0.34),
          ]),
        ],
      );

  final blankTemplate = TrainingBoardTemplateOption(
    id: 'blank',
    icon: Icons.dashboard_outlined,
    label: l10n.trainingSketchTemplateBlankLabel,
    description: l10n.trainingSketchTemplateBlankDescription,
    buildLayout: blank,
  );

  switch (SportCatalog.normalizeSportId(sportId)) {
    case SportCatalog.baseballId:
      return <TrainingBoardTemplateOption>[
        blankTemplate,
        TrainingBoardTemplateOption(
          id: 'baseball_throwing',
          icon: Icons.sports_baseball,
          label: l10n.trainingSketchTemplateBaseballThrowingLabel,
          description: l10n.trainingSketchTemplateBaseballThrowingDescription,
          buildLayout: baseballThrowing,
        ),
        TrainingBoardTemplateOption(
          id: 'baseball_batting',
          icon: Icons.sports_baseball,
          label: l10n.trainingSketchTemplateBaseballBattingLabel,
          description: l10n.trainingSketchTemplateBaseballBattingDescription,
          buildLayout: baseballBatting,
        ),
        TrainingBoardTemplateOption(
          id: 'baseball_fielding',
          icon: Icons.my_location_outlined,
          label: l10n.trainingSketchTemplateBaseballFieldingLabel,
          description: l10n.trainingSketchTemplateBaseballFieldingDescription,
          buildLayout: baseballFielding,
        ),
      ];
    case SportCatalog.basketballId:
      return <TrainingBoardTemplateOption>[
        blankTemplate,
        TrainingBoardTemplateOption(
          id: 'basketball_shooting',
          icon: Icons.sports_basketball,
          label: l10n.trainingSketchTemplateBasketballShootingLabel,
          description: l10n.trainingSketchTemplateBasketballShootingDescription,
          buildLayout: basketballShooting,
        ),
        TrainingBoardTemplateOption(
          id: 'basketball_passing',
          icon: Icons.sync_alt_outlined,
          label: l10n.trainingSketchTemplateBasketballPassingLabel,
          description: l10n.trainingSketchTemplateBasketballPassingDescription,
          buildLayout: basketballPassing,
        ),
        TrainingBoardTemplateOption(
          id: 'basketball_defense',
          icon: Icons.shield_outlined,
          label: l10n.trainingSketchTemplateBasketballDefenseLabel,
          description: l10n.trainingSketchTemplateBasketballDefenseDescription,
          buildLayout: basketballDefense,
        ),
      ];
    case SportCatalog.tennisId:
      return <TrainingBoardTemplateOption>[
        blankTemplate,
        TrainingBoardTemplateOption(
          id: 'tennis_serve',
          icon: Icons.sports_tennis,
          label: l10n.trainingSketchTemplateTennisServeLabel,
          description: l10n.trainingSketchTemplateTennisServeDescription,
          buildLayout: tennisServe,
        ),
        TrainingBoardTemplateOption(
          id: 'tennis_rally',
          icon: Icons.compare_arrows_outlined,
          label: l10n.trainingSketchTemplateTennisRallyLabel,
          description: l10n.trainingSketchTemplateTennisRallyDescription,
          buildLayout: tennisRally,
        ),
        TrainingBoardTemplateOption(
          id: 'tennis_footwork',
          icon: Icons.directions_run_outlined,
          label: l10n.trainingSketchTemplateTennisFootworkLabel,
          description: l10n.trainingSketchTemplateTennisFootworkDescription,
          buildLayout: tennisFootwork,
        ),
      ];
  }

  return <TrainingBoardTemplateOption>[
    blankTemplate,
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
