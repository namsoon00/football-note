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
    String id = '',
    int color = playerBlue,
    double size = 32,
  }) =>
      TrainingMethodItem(
        id: id,
        type: 'player',
        x: x,
        y: y,
        size: size,
        rotationDeg: 0,
        colorValue: color,
      );

  TrainingMethodItem ball(
    double x,
    double y, {
    String id = '',
    double size = 30,
  }) =>
      TrainingMethodItem(
        id: id,
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
    String id = '',
    int color = coneOrange,
    double size = 30,
  }) =>
      TrainingMethodItem(
        id: id,
        type: 'cone',
        x: x,
        y: y,
        size: size,
        rotationDeg: 0,
        colorValue: color,
      );

  TrainingMethodItem prop(
    String type,
    double x,
    double y, {
    String id = '',
    int color = coneOrange,
    double size = 30,
  }) =>
      TrainingMethodItem(
        id: id,
        type: type,
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
    List<TrainingMethodPoint> points, {
    String? linkedItemId,
    String? actorItemId,
    String? targetItemId,
    List<int> segmentDurationsMs = const <int>[],
    int stageIndex = 1,
  }) =>
      TrainingMethodRoute(
        id: id,
        kind: kind,
        linkedItemId: linkedItemId,
        actorItemId: actorItemId,
        targetItemId: targetItemId,
        points: points,
        segmentDurationsMs: segmentDurationsMs,
        stageIndex: stageIndex,
        colorValue:
            kind == TrainingMethodRouteKind.ball ? 0xFFFFCA28 : 0xFF80D8FF,
      );

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
          cone(0.18, 0.60, id: 'pass_warmup_gate_1'),
          cone(0.46, 0.38, id: 'pass_warmup_gate_2'),
          cone(0.74, 0.58, id: 'pass_warmup_gate_3'),
          cone(0.46, 0.74, id: 'pass_warmup_gate_4'),
          player(0.18, 0.60, id: 'pass_warmup_player_1'),
          player(0.46, 0.38, id: 'pass_warmup_player_2'),
          player(0.74, 0.58, id: 'pass_warmup_player_3'),
          player(
            0.46,
            0.74,
            id: 'pass_warmup_player_4',
            color: playerGreen,
          ),
          ball(0.18, 0.60, id: 'pass_warmup_ball'),
        ],
        routes: <TrainingMethodRoute>[
          route(
            'pass_warmup_ball_cycle',
            TrainingMethodRouteKind.ball,
            <TrainingMethodPoint>[
              point(0.18, 0.60),
              point(0.46, 0.38),
              point(0.74, 0.58),
              point(0.46, 0.74),
            ],
            linkedItemId: 'pass_warmup_ball',
            segmentDurationsMs: const <int>[520, 560, 600],
          ),
          route(
            'pass_warmup_player_1_rotate',
            TrainingMethodRouteKind.player,
            <TrainingMethodPoint>[
              point(0.18, 0.60),
              point(0.30, 0.56),
              point(0.46, 0.38),
            ],
            linkedItemId: 'pass_warmup_player_1',
            stageIndex: 2,
          ),
          route(
            'pass_warmup_player_2_check',
            TrainingMethodRouteKind.player,
            <TrainingMethodPoint>[
              point(0.46, 0.38),
              point(0.54, 0.48),
              point(0.74, 0.58),
            ],
            linkedItemId: 'pass_warmup_player_2',
            stageIndex: 2,
          ),
          route(
            'pass_warmup_player_4_support',
            TrainingMethodRouteKind.player,
            <TrainingMethodPoint>[
              point(0.46, 0.74),
              point(0.58, 0.70),
              point(0.68, 0.62),
            ],
            linkedItemId: 'pass_warmup_player_4',
            stageIndex: 3,
          ),
        ],
      );

  TrainingMethodLayout buildUp(String title) => onePage(
        title: title,
        methodText: l10n.trainingSketchTemplateBuildUpMethod,
        items: <TrainingMethodItem>[
          cone(0.14, 0.64, id: 'build_up_left_lane'),
          cone(0.86, 0.64, id: 'build_up_right_lane'),
          player(
            0.42,
            0.52,
            id: 'build_up_pressure_1',
            color: playerRed,
          ),
          player(
            0.58,
            0.52,
            id: 'build_up_pressure_2',
            color: playerRed,
          ),
          player(0.50, 0.86, id: 'build_up_keeper', color: playerGreen),
          player(0.28, 0.76, id: 'build_up_left_cb'),
          player(0.72, 0.76, id: 'build_up_right_cb'),
          player(0.50, 0.62, id: 'build_up_pivot'),
          player(0.16, 0.58, id: 'build_up_left_back'),
          player(0.84, 0.58, id: 'build_up_right_back'),
          ball(0.50, 0.86, id: 'build_up_ball'),
        ],
        routes: <TrainingMethodRoute>[
          route(
            'build_up_ball_escape',
            TrainingMethodRouteKind.ball,
            <TrainingMethodPoint>[
              point(0.50, 0.86),
              point(0.28, 0.76),
              point(0.50, 0.62),
              point(0.84, 0.58),
            ],
            linkedItemId: 'build_up_ball',
            segmentDurationsMs: const <int>[560, 620, 720],
          ),
          route(
            'build_up_left_cb_open',
            TrainingMethodRouteKind.player,
            <TrainingMethodPoint>[
              point(0.28, 0.76),
              point(0.22, 0.72),
              point(0.20, 0.66),
            ],
            linkedItemId: 'build_up_left_cb',
            stageIndex: 1,
          ),
          route(
            'build_up_pivot_drop',
            TrainingMethodRouteKind.player,
            <TrainingMethodPoint>[
              point(0.50, 0.62),
              point(0.46, 0.68),
              point(0.42, 0.58),
            ],
            linkedItemId: 'build_up_pivot',
            stageIndex: 2,
          ),
          route(
            'build_up_right_back_release',
            TrainingMethodRouteKind.player,
            <TrainingMethodPoint>[
              point(0.84, 0.58),
              point(0.88, 0.50),
              point(0.88, 0.42),
            ],
            linkedItemId: 'build_up_right_back',
            stageIndex: 3,
          ),
        ],
      );

  TrainingMethodLayout pressing(String title) => onePage(
        title: title,
        methodText: l10n.trainingSketchTemplatePressingMethod,
        items: <TrainingMethodItem>[
          cone(0.32, 0.34, id: 'pressing_trap_left'),
          cone(0.70, 0.34, id: 'pressing_trap_right'),
          player(0.34, 0.60, id: 'pressing_nearest'),
          player(0.50, 0.66, id: 'pressing_cover'),
          player(0.66, 0.60, id: 'pressing_far'),
          player(0.50, 0.78, id: 'pressing_rest_defense'),
          player(
            0.52,
            0.42,
            id: 'pressing_receiver',
            color: playerRed,
          ),
          ball(0.52, 0.42, id: 'pressing_ball'),
        ],
        routes: <TrainingMethodRoute>[
          route(
            'pressing_ball_escape',
            TrainingMethodRouteKind.ball,
            <TrainingMethodPoint>[
              point(0.52, 0.42),
              point(0.42, 0.34),
              point(0.28, 0.30),
            ],
            linkedItemId: 'pressing_ball',
          ),
          route(
            'pressing_nearest_jump',
            TrainingMethodRouteKind.player,
            <TrainingMethodPoint>[
              point(0.34, 0.60),
              point(0.40, 0.50),
              point(0.50, 0.42),
            ],
            linkedItemId: 'pressing_nearest',
          ),
          route(
            'pressing_cover_shadow',
            TrainingMethodRouteKind.player,
            <TrainingMethodPoint>[
              point(0.50, 0.66),
              point(0.46, 0.56),
              point(0.42, 0.46),
            ],
            linkedItemId: 'pressing_cover',
          ),
          route(
            'pressing_far_lock',
            TrainingMethodRouteKind.player,
            <TrainingMethodPoint>[
              point(0.66, 0.60),
              point(0.62, 0.50),
              point(0.58, 0.44),
            ],
            linkedItemId: 'pressing_far',
          ),
          route(
            'pressing_rest_defense_squeeze',
            TrainingMethodRouteKind.player,
            <TrainingMethodPoint>[
              point(0.50, 0.78),
              point(0.50, 0.70),
              point(0.48, 0.62),
            ],
            linkedItemId: 'pressing_rest_defense',
            stageIndex: 2,
          ),
        ],
      );

  TrainingMethodLayout setPiece(String title) => onePage(
        title: title,
        methodText: l10n.trainingSketchTemplateSetPieceMethod,
        items: <TrainingMethodItem>[
          cone(0.08, 0.10, id: 'set_piece_corner'),
          cone(0.52, 0.30, id: 'set_piece_near_zone'),
          cone(0.70, 0.42, id: 'set_piece_far_zone'),
          player(
            0.34,
            0.26,
            id: 'set_piece_defender_1',
            color: playerRed,
          ),
          player(
            0.48,
            0.30,
            id: 'set_piece_defender_2',
            color: playerRed,
          ),
          player(
            0.64,
            0.38,
            id: 'set_piece_defender_3',
            color: playerRed,
          ),
          player(0.08, 0.10, id: 'set_piece_taker', color: playerGreen),
          player(0.26, 0.22, id: 'set_piece_blocker'),
          player(0.36, 0.36, id: 'set_piece_near_runner'),
          player(0.46, 0.24, id: 'set_piece_screen_runner'),
          player(0.58, 0.46, id: 'set_piece_far_runner'),
          ball(0.08, 0.10, id: 'set_piece_ball'),
        ],
        routes: <TrainingMethodRoute>[
          route(
            'set_piece_ball_near_flick',
            TrainingMethodRouteKind.ball,
            <TrainingMethodPoint>[
              point(0.08, 0.10),
              point(0.30, 0.16),
              point(0.52, 0.30),
              point(0.70, 0.42),
            ],
            linkedItemId: 'set_piece_ball',
            segmentDurationsMs: const <int>[460, 560, 520],
          ),
          route(
            'set_piece_blocker_screen',
            TrainingMethodRouteKind.player,
            <TrainingMethodPoint>[
              point(0.26, 0.22),
              point(0.34, 0.26),
              point(0.44, 0.28),
            ],
            linkedItemId: 'set_piece_blocker',
          ),
          route(
            'set_piece_near_post_attack',
            TrainingMethodRouteKind.player,
            <TrainingMethodPoint>[
              point(0.36, 0.36),
              point(0.44, 0.32),
              point(0.52, 0.30),
            ],
            linkedItemId: 'set_piece_near_runner',
          ),
          route(
            'set_piece_far_post_attack',
            TrainingMethodRouteKind.player,
            <TrainingMethodPoint>[
              point(0.58, 0.46),
              point(0.64, 0.44),
              point(0.70, 0.42),
            ],
            linkedItemId: 'set_piece_far_runner',
            stageIndex: 2,
          ),
        ],
      );

  TrainingMethodLayout rondo(String title) => onePage(
        title: title,
        methodText: l10n.trainingSketchTemplateRondoMethod,
        items: <TrainingMethodItem>[
          cone(0.18, 0.24, id: 'rondo_box_1', color: conePurple),
          cone(0.82, 0.24, id: 'rondo_box_2', color: conePurple),
          cone(0.18, 0.76, id: 'rondo_box_3', color: conePurple),
          cone(0.82, 0.76, id: 'rondo_box_4', color: conePurple),
          player(0.22, 0.30, id: 'rondo_support_1'),
          player(0.78, 0.30, id: 'rondo_support_2'),
          player(0.22, 0.70, id: 'rondo_support_3'),
          player(0.78, 0.70, id: 'rondo_support_4'),
          player(0.50, 0.50, id: 'rondo_joker', color: playerGreen),
          player(0.44, 0.48, id: 'rondo_defender_1', color: playerRed),
          player(0.56, 0.52, id: 'rondo_defender_2', color: playerRed),
          ball(0.22, 0.30, id: 'rondo_ball'),
        ],
        routes: <TrainingMethodRoute>[
          route(
            'rondo_ball_split',
            TrainingMethodRouteKind.ball,
            <TrainingMethodPoint>[
              point(0.22, 0.30),
              point(0.78, 0.30),
              point(0.50, 0.50),
              point(0.22, 0.70),
              point(0.78, 0.70),
            ],
            linkedItemId: 'rondo_ball',
            segmentDurationsMs: const <int>[420, 520, 420, 560],
          ),
          route(
            'rondo_support_1_rotate',
            TrainingMethodRouteKind.player,
            <TrainingMethodPoint>[
              point(0.22, 0.30),
              point(0.20, 0.48),
              point(0.22, 0.70),
            ],
            linkedItemId: 'rondo_support_1',
            stageIndex: 2,
          ),
          route(
            'rondo_joker_open',
            TrainingMethodRouteKind.player,
            <TrainingMethodPoint>[
              point(0.50, 0.50),
              point(0.52, 0.44),
              point(0.58, 0.42),
            ],
            linkedItemId: 'rondo_joker',
            stageIndex: 2,
          ),
          route(
            'rondo_defender_press',
            TrainingMethodRouteKind.player,
            <TrainingMethodPoint>[
              point(0.44, 0.48),
              point(0.50, 0.44),
              point(0.56, 0.42),
            ],
            linkedItemId: 'rondo_defender_1',
          ),
        ],
      );

  TrainingMethodLayout finishing(String title) => onePage(
        title: title,
        methodText: l10n.trainingSketchTemplateFinishingMethod,
        items: <TrainingMethodItem>[
          cone(0.20, 0.76, id: 'finishing_start'),
          cone(0.78, 0.26, id: 'finishing_near_post'),
          cone(0.78, 0.52, id: 'finishing_cutback_spot'),
          player(
            0.62,
            0.34,
            id: 'finishing_defender_1',
            color: playerRed,
          ),
          player(
            0.74,
            0.44,
            id: 'finishing_defender_2',
            color: playerRed,
          ),
          player(0.20, 0.76, id: 'finishing_midfielder'),
          player(0.38, 0.62, id: 'finishing_wide_player'),
          player(0.56, 0.40, id: 'finishing_striker'),
          player(0.54, 0.58, id: 'finishing_ten', color: playerGreen),
          player(0.34, 0.38, id: 'finishing_far_winger'),
          ball(0.20, 0.76, id: 'finishing_ball'),
        ],
        routes: <TrainingMethodRoute>[
          route(
            'finishing_ball_cutback',
            TrainingMethodRouteKind.ball,
            <TrainingMethodPoint>[
              point(0.20, 0.76),
              point(0.38, 0.62),
              point(0.78, 0.52),
              point(0.56, 0.40),
              point(0.82, 0.30),
            ],
            linkedItemId: 'finishing_ball',
            segmentDurationsMs: const <int>[460, 700, 520, 520],
          ),
          route(
            'finishing_wide_drive',
            TrainingMethodRouteKind.player,
            <TrainingMethodPoint>[
              point(0.38, 0.62),
              point(0.58, 0.58),
              point(0.78, 0.52),
            ],
            linkedItemId: 'finishing_wide_player',
          ),
          route(
            'finishing_striker_near',
            TrainingMethodRouteKind.player,
            <TrainingMethodPoint>[
              point(0.56, 0.40),
              point(0.66, 0.34),
              point(0.78, 0.26),
            ],
            linkedItemId: 'finishing_striker',
            stageIndex: 2,
          ),
          route(
            'finishing_ten_cutback',
            TrainingMethodRouteKind.player,
            <TrainingMethodPoint>[
              point(0.54, 0.58),
              point(0.60, 0.54),
              point(0.70, 0.50),
            ],
            linkedItemId: 'finishing_ten',
            stageIndex: 2,
          ),
          route(
            'finishing_far_winger_arrive',
            TrainingMethodRouteKind.player,
            <TrainingMethodPoint>[
              point(0.34, 0.38),
              point(0.48, 0.34),
              point(0.66, 0.30),
            ],
            linkedItemId: 'finishing_far_winger',
            stageIndex: 3,
          ),
        ],
      );

  TrainingMethodLayout wingCombination(String title) => onePage(
        title: title,
        methodText: l10n.trainingSketchTemplateWingCombinationMethod,
        items: <TrainingMethodItem>[
          cone(0.22, 0.66, id: 'wing_start_gate'),
          cone(0.84, 0.50, id: 'wing_cutback_gate'),
          player(0.48, 0.54, id: 'wing_defender_1', color: playerRed),
          player(0.70, 0.50, id: 'wing_defender_2', color: playerRed),
          player(0.22, 0.66, id: 'wing_fullback'),
          player(0.36, 0.52, id: 'wing_winger'),
          player(0.42, 0.74, id: 'wing_underlap', color: playerGreen),
          player(0.62, 0.38, id: 'wing_nine'),
          player(0.58, 0.62, id: 'wing_arrival'),
          ball(0.22, 0.66, id: 'wing_ball'),
        ],
        routes: <TrainingMethodRoute>[
          route(
            'wing_ball_combination',
            TrainingMethodRouteKind.ball,
            <TrainingMethodPoint>[
              point(0.22, 0.66),
              point(0.36, 0.52),
              point(0.42, 0.74),
              point(0.84, 0.50),
              point(0.62, 0.38),
            ],
            linkedItemId: 'wing_ball',
            segmentDurationsMs: const <int>[420, 500, 680, 520],
          ),
          route(
            'wing_fullback_overlap',
            TrainingMethodRouteKind.player,
            <TrainingMethodPoint>[
              point(0.22, 0.66),
              point(0.36, 0.72),
              point(0.56, 0.70),
            ],
            linkedItemId: 'wing_fullback',
            stageIndex: 2,
          ),
          route(
            'wing_underlap_break',
            TrainingMethodRouteKind.player,
            <TrainingMethodPoint>[
              point(0.42, 0.74),
              point(0.58, 0.62),
              point(0.84, 0.50),
            ],
            linkedItemId: 'wing_underlap',
            stageIndex: 2,
          ),
          route(
            'wing_nine_near_run',
            TrainingMethodRouteKind.player,
            <TrainingMethodPoint>[
              point(0.62, 0.38),
              point(0.72, 0.40),
              point(0.80, 0.44),
            ],
            linkedItemId: 'wing_nine',
            stageIndex: 3,
          ),
          route(
            'wing_arrival_cutback',
            TrainingMethodRouteKind.player,
            <TrainingMethodPoint>[
              point(0.58, 0.62),
              point(0.66, 0.56),
              point(0.74, 0.52),
            ],
            linkedItemId: 'wing_arrival',
            stageIndex: 3,
          ),
        ],
      );

  TrainingMethodLayout transitionAttack(String title) => onePage(
        title: title,
        methodText: l10n.trainingSketchTemplateTransitionAttackMethod,
        items: <TrainingMethodItem>[
          cone(0.34, 0.58, id: 'transition_regain_zone'),
          cone(0.84, 0.28, id: 'transition_finish_zone'),
          player(
            0.30,
            0.46,
            id: 'transition_opponent_1',
            color: playerRed,
          ),
          player(
            0.52,
            0.28,
            id: 'transition_opponent_2',
            color: playerRed,
          ),
          player(
            0.70,
            0.58,
            id: 'transition_opponent_3',
            color: playerRed,
          ),
          player(0.34, 0.58, id: 'transition_winner'),
          player(0.48, 0.46, id: 'transition_ten', color: playerGreen),
          player(0.66, 0.34, id: 'transition_runner'),
          player(0.76, 0.58, id: 'transition_wide_runner'),
          ball(0.34, 0.58, id: 'transition_ball'),
        ],
        routes: <TrainingMethodRoute>[
          route(
            'transition_ball_forward',
            TrainingMethodRouteKind.ball,
            <TrainingMethodPoint>[
              point(0.34, 0.58),
              point(0.48, 0.46),
              point(0.76, 0.58),
              point(0.84, 0.28),
            ],
            linkedItemId: 'transition_ball',
            segmentDurationsMs: const <int>[420, 620, 680],
          ),
          route(
            'transition_winner_support',
            TrainingMethodRouteKind.player,
            <TrainingMethodPoint>[
              point(0.34, 0.58),
              point(0.42, 0.52),
              point(0.52, 0.50),
            ],
            linkedItemId: 'transition_winner',
            stageIndex: 2,
          ),
          route(
            'transition_runner_depth',
            TrainingMethodRouteKind.player,
            <TrainingMethodPoint>[
              point(0.66, 0.34),
              point(0.74, 0.30),
              point(0.84, 0.28),
            ],
            linkedItemId: 'transition_runner',
            stageIndex: 2,
          ),
          route(
            'transition_wide_carry',
            TrainingMethodRouteKind.player,
            <TrainingMethodPoint>[
              point(0.76, 0.58),
              point(0.82, 0.48),
              point(0.84, 0.36),
            ],
            linkedItemId: 'transition_wide_runner',
            stageIndex: 3,
          ),
        ],
      );

  TrainingMethodLayout switchPlay(String title) => onePage(
        title: title,
        methodText: l10n.trainingSketchTemplateSwitchPlayMethod,
        items: <TrainingMethodItem>[
          cone(0.18, 0.62, id: 'switch_left_channel'),
          cone(0.82, 0.36, id: 'switch_right_channel'),
          player(0.38, 0.42, id: 'switch_defender_1', color: playerRed),
          player(0.58, 0.46, id: 'switch_defender_2', color: playerRed),
          player(0.18, 0.62, id: 'switch_left_back'),
          player(0.34, 0.52, id: 'switch_six', color: playerGreen),
          player(0.52, 0.62, id: 'switch_center_back'),
          player(0.82, 0.36, id: 'switch_right_winger'),
          player(0.70, 0.54, id: 'switch_right_back'),
          ball(0.18, 0.62, id: 'switch_ball'),
        ],
        routes: <TrainingMethodRoute>[
          route(
            'switch_ball_diagonal',
            TrainingMethodRouteKind.ball,
            <TrainingMethodPoint>[
              point(0.18, 0.62),
              point(0.34, 0.52),
              point(0.52, 0.62),
              point(0.82, 0.36),
            ],
            linkedItemId: 'switch_ball',
            segmentDurationsMs: const <int>[440, 520, 780],
          ),
          route(
            'switch_six_offer',
            TrainingMethodRouteKind.player,
            <TrainingMethodPoint>[
              point(0.34, 0.52),
              point(0.40, 0.50),
              point(0.46, 0.54),
            ],
            linkedItemId: 'switch_six',
          ),
          route(
            'switch_right_winger_receive',
            TrainingMethodRouteKind.player,
            <TrainingMethodPoint>[
              point(0.82, 0.36),
              point(0.86, 0.40),
              point(0.88, 0.48),
            ],
            linkedItemId: 'switch_right_winger',
            stageIndex: 2,
          ),
          route(
            'switch_right_back_underlap',
            TrainingMethodRouteKind.player,
            <TrainingMethodPoint>[
              point(0.70, 0.54),
              point(0.76, 0.48),
              point(0.82, 0.44),
            ],
            linkedItemId: 'switch_right_back',
            stageIndex: 3,
          ),
        ],
      );

  TrainingMethodLayout defensiveShift(String title) => onePage(
        title: title,
        methodText: l10n.trainingSketchTemplateDefensiveShiftMethod,
        items: <TrainingMethodItem>[
          cone(0.22, 0.42, id: 'defensive_shift_left_ball_zone'),
          cone(0.78, 0.42, id: 'defensive_shift_right_ball_zone'),
          player(0.22, 0.42,
              id: 'defensive_shift_opponent_1', color: playerRed),
          player(0.78, 0.42,
              id: 'defensive_shift_opponent_2', color: playerRed),
          player(0.26, 0.64, id: 'defensive_shift_left_back'),
          player(0.42, 0.62, id: 'defensive_shift_left_center'),
          player(0.58, 0.62, id: 'defensive_shift_right_center'),
          player(0.74, 0.64, id: 'defensive_shift_right_back'),
          player(0.50, 0.50, id: 'defensive_shift_six', color: playerGreen),
          ball(0.22, 0.42, id: 'defensive_shift_ball'),
        ],
        routes: <TrainingMethodRoute>[
          route(
            'defensive_shift_ball_switch',
            TrainingMethodRouteKind.ball,
            <TrainingMethodPoint>[
              point(0.22, 0.42),
              point(0.50, 0.34),
              point(0.78, 0.42),
            ],
            linkedItemId: 'defensive_shift_ball',
            segmentDurationsMs: const <int>[680, 680],
          ),
          route(
            'defensive_shift_left_back_step',
            TrainingMethodRouteKind.player,
            <TrainingMethodPoint>[
              point(0.26, 0.64),
              point(0.22, 0.58),
              point(0.30, 0.58),
            ],
            linkedItemId: 'defensive_shift_left_back',
          ),
          route(
            'defensive_shift_left_center_cover',
            TrainingMethodRouteKind.player,
            <TrainingMethodPoint>[
              point(0.42, 0.62),
              point(0.36, 0.58),
              point(0.46, 0.56),
            ],
            linkedItemId: 'defensive_shift_left_center',
          ),
          route(
            'defensive_shift_right_center_slide',
            TrainingMethodRouteKind.player,
            <TrainingMethodPoint>[
              point(0.58, 0.62),
              point(0.54, 0.58),
              point(0.64, 0.56),
            ],
            linkedItemId: 'defensive_shift_right_center',
            stageIndex: 2,
          ),
          route(
            'defensive_shift_right_back_press',
            TrainingMethodRouteKind.player,
            <TrainingMethodPoint>[
              point(0.74, 0.64),
              point(0.78, 0.56),
              point(0.82, 0.48),
            ],
            linkedItemId: 'defensive_shift_right_back',
            stageIndex: 2,
          ),
          route(
            'defensive_shift_six_screen',
            TrainingMethodRouteKind.player,
            <TrainingMethodPoint>[
              point(0.50, 0.50),
              point(0.44, 0.48),
              point(0.56, 0.48),
            ],
            linkedItemId: 'defensive_shift_six',
            stageIndex: 2,
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

  TrainingMethodLayout ballMastery(String title) => onePage(
        title: title,
        methodText: l10n.trainingSketchTemplateBallMasteryMethod,
        items: <TrainingMethodItem>[
          player(0.16, 0.74, id: 'mastery_player_1'),
          player(0.16, 0.24, id: 'mastery_player_2', color: playerGreen),
          player(0.82, 0.74, id: 'mastery_player_3', color: playerRed),
          ball(0.22, 0.70, id: 'mastery_ball'),
          cone(0.34, 0.64, id: 'mastery_cone_1'),
          cone(0.48, 0.52, id: 'mastery_cone_2'),
          cone(0.62, 0.42, id: 'mastery_cone_3'),
          prop('target', 0.90, 0.22, id: 'mastery_goal', size: 38),
        ],
        routes: <TrainingMethodRoute>[
          route(
            'mastery_dribble_player',
            TrainingMethodRouteKind.player,
            <TrainingMethodPoint>[
              point(0.16, 0.74),
              point(0.34, 0.66),
              point(0.50, 0.50),
              point(0.72, 0.34),
            ],
            linkedItemId: 'mastery_player_1',
            actorItemId: 'mastery_player_1',
            stageIndex: 1,
          ),
          route(
            'mastery_dribble_ball',
            TrainingMethodRouteKind.ball,
            <TrainingMethodPoint>[
              point(0.22, 0.70),
              point(0.40, 0.62),
              point(0.56, 0.46),
              point(0.78, 0.30),
            ],
            linkedItemId: 'mastery_ball',
            actorItemId: 'mastery_player_1',
            targetItemId: 'mastery_player_1',
            segmentDurationsMs: const <int>[420, 460, 500],
            stageIndex: 1,
          ),
          route(
            'mastery_finish_ball',
            TrainingMethodRouteKind.ball,
            <TrainingMethodPoint>[point(0.78, 0.30), point(0.90, 0.22)],
            linkedItemId: 'mastery_ball',
            actorItemId: 'mastery_player_1',
            targetItemId: 'mastery_goal',
            segmentDurationsMs: const <int>[520],
            stageIndex: 2,
          ),
        ],
      );

  TrainingMethodLayout firstTouchFinish(String title) => onePage(
        title: title,
        methodText: l10n.trainingSketchTemplateFirstTouchFinishMethod,
        items: <TrainingMethodItem>[
          player(0.14, 0.72, id: 'first_touch_server'),
          player(0.46, 0.52, id: 'first_touch_receiver', color: playerGreen),
          player(0.78, 0.28, id: 'first_touch_keeper', color: playerRed),
          ball(0.21, 0.69, id: 'first_touch_ball'),
          cone(0.58, 0.42, id: 'first_touch_cone'),
          prop('target', 0.91, 0.18, id: 'first_touch_goal', size: 38),
        ],
        routes: <TrainingMethodRoute>[
          route(
            'first_touch_server_move',
            TrainingMethodRouteKind.player,
            <TrainingMethodPoint>[point(0.14, 0.72), point(0.30, 0.58)],
            linkedItemId: 'first_touch_server',
            actorItemId: 'first_touch_server',
            stageIndex: 1,
          ),
          route(
            'first_touch_pass',
            TrainingMethodRouteKind.ball,
            <TrainingMethodPoint>[point(0.21, 0.69), point(0.46, 0.52)],
            linkedItemId: 'first_touch_ball',
            actorItemId: 'first_touch_server',
            targetItemId: 'first_touch_receiver',
            segmentDurationsMs: const <int>[560],
            stageIndex: 1,
          ),
          route(
            'first_touch_receiver_turn',
            TrainingMethodRouteKind.player,
            <TrainingMethodPoint>[
              point(0.46, 0.52),
              point(0.62, 0.42),
              point(0.76, 0.30),
            ],
            linkedItemId: 'first_touch_receiver',
            actorItemId: 'first_touch_receiver',
            stageIndex: 2,
          ),
          route(
            'first_touch_carry',
            TrainingMethodRouteKind.ball,
            <TrainingMethodPoint>[
              point(0.46, 0.52),
              point(0.68, 0.38),
              point(0.81, 0.27),
            ],
            linkedItemId: 'first_touch_ball',
            actorItemId: 'first_touch_receiver',
            targetItemId: 'first_touch_receiver',
            segmentDurationsMs: const <int>[460, 440],
            stageIndex: 2,
          ),
          route(
            'first_touch_finish',
            TrainingMethodRouteKind.ball,
            <TrainingMethodPoint>[point(0.81, 0.27), point(0.91, 0.18)],
            linkedItemId: 'first_touch_ball',
            actorItemId: 'first_touch_receiver',
            targetItemId: 'first_touch_goal',
            segmentDurationsMs: const <int>[480],
            stageIndex: 3,
          ),
        ],
      );

  TrainingMethodLayout oneVOne(String title) => onePage(
        title: title,
        methodText: l10n.trainingSketchTemplateOneVOneMethod,
        items: <TrainingMethodItem>[
          player(0.16, 0.72, id: 'one_v_one_attacker'),
          player(0.54, 0.48, id: 'one_v_one_defender', color: playerRed),
          player(0.80, 0.24, id: 'one_v_one_keeper', color: playerGreen),
          ball(0.23, 0.69, id: 'one_v_one_ball'),
          cone(0.36, 0.62, id: 'one_v_one_gate_1'),
          cone(0.36, 0.42, id: 'one_v_one_gate_2'),
          prop('target', 0.92, 0.18, id: 'one_v_one_goal', size: 38),
        ],
        routes: <TrainingMethodRoute>[
          route(
            'one_v_one_attacker_drive',
            TrainingMethodRouteKind.player,
            <TrainingMethodPoint>[
              point(0.16, 0.72),
              point(0.40, 0.62),
              point(0.66, 0.36),
              point(0.80, 0.26),
            ],
            linkedItemId: 'one_v_one_attacker',
            actorItemId: 'one_v_one_attacker',
            stageIndex: 1,
          ),
          route(
            'one_v_one_dribble',
            TrainingMethodRouteKind.ball,
            <TrainingMethodPoint>[
              point(0.23, 0.69),
              point(0.46, 0.58),
              point(0.72, 0.32),
              point(0.85, 0.24),
            ],
            linkedItemId: 'one_v_one_ball',
            actorItemId: 'one_v_one_attacker',
            targetItemId: 'one_v_one_attacker',
            segmentDurationsMs: const <int>[420, 500, 380],
            stageIndex: 1,
          ),
          route(
            'one_v_one_defend',
            TrainingMethodRouteKind.player,
            <TrainingMethodPoint>[point(0.54, 0.48), point(0.62, 0.42)],
            linkedItemId: 'one_v_one_defender',
            actorItemId: 'one_v_one_defender',
            stageIndex: 1,
          ),
          route(
            'one_v_one_finish',
            TrainingMethodRouteKind.ball,
            <TrainingMethodPoint>[point(0.85, 0.24), point(0.92, 0.18)],
            linkedItemId: 'one_v_one_ball',
            actorItemId: 'one_v_one_attacker',
            targetItemId: 'one_v_one_goal',
            segmentDurationsMs: const <int>[440],
            stageIndex: 2,
          ),
        ],
      );

  TrainingMethodLayout twoVOne(String title) => onePage(
        title: title,
        methodText: l10n.trainingSketchTemplateTwoVOneMethod,
        items: <TrainingMethodItem>[
          player(0.16, 0.70, id: 'two_v_one_ball_carrier'),
          player(0.46, 0.38, id: 'two_v_one_support', color: playerGreen),
          player(0.64, 0.52, id: 'two_v_one_defender', color: playerRed),
          ball(0.23, 0.68, id: 'two_v_one_ball'),
          cone(0.76, 0.30, id: 'two_v_one_finish_gate'),
          prop('target', 0.91, 0.20, id: 'two_v_one_goal', size: 38),
        ],
        routes: <TrainingMethodRoute>[
          route(
            'two_v_one_overlap',
            TrainingMethodRouteKind.player,
            <TrainingMethodPoint>[point(0.16, 0.70), point(0.42, 0.62)],
            linkedItemId: 'two_v_one_ball_carrier',
            actorItemId: 'two_v_one_ball_carrier',
            stageIndex: 1,
          ),
          route(
            'two_v_one_first_pass',
            TrainingMethodRouteKind.ball,
            <TrainingMethodPoint>[point(0.23, 0.68), point(0.46, 0.38)],
            linkedItemId: 'two_v_one_ball',
            actorItemId: 'two_v_one_ball_carrier',
            targetItemId: 'two_v_one_support',
            segmentDurationsMs: const <int>[520],
            stageIndex: 1,
          ),
          route(
            'two_v_one_return_run',
            TrainingMethodRouteKind.player,
            <TrainingMethodPoint>[point(0.42, 0.62), point(0.74, 0.34)],
            linkedItemId: 'two_v_one_ball_carrier',
            actorItemId: 'two_v_one_ball_carrier',
            stageIndex: 2,
          ),
          route(
            'two_v_one_return_pass',
            TrainingMethodRouteKind.ball,
            <TrainingMethodPoint>[point(0.46, 0.38), point(0.74, 0.34)],
            linkedItemId: 'two_v_one_ball',
            actorItemId: 'two_v_one_support',
            targetItemId: 'two_v_one_ball_carrier',
            segmentDurationsMs: const <int>[520],
            stageIndex: 2,
          ),
          route(
            'two_v_one_finish',
            TrainingMethodRouteKind.ball,
            <TrainingMethodPoint>[point(0.74, 0.34), point(0.91, 0.20)],
            linkedItemId: 'two_v_one_ball',
            actorItemId: 'two_v_one_ball_carrier',
            targetItemId: 'two_v_one_goal',
            segmentDurationsMs: const <int>[520],
            stageIndex: 3,
          ),
        ],
      );

  TrainingMethodLayout thirdMan(String title) => onePage(
        title: title,
        methodText: l10n.trainingSketchTemplateThirdManMethod,
        items: <TrainingMethodItem>[
          player(0.16, 0.68, id: 'third_man_passer'),
          player(0.46, 0.50, id: 'third_man_link', color: playerGreen),
          player(0.72, 0.30, id: 'third_man_runner'),
          ball(0.23, 0.65, id: 'third_man_ball'),
          cone(0.60, 0.58, id: 'third_man_cone'),
          prop('target', 0.91, 0.18, id: 'third_man_goal', size: 38),
        ],
        routes: <TrainingMethodRoute>[
          route(
            'third_man_passer_support',
            TrainingMethodRouteKind.player,
            <TrainingMethodPoint>[point(0.16, 0.68), point(0.34, 0.56)],
            linkedItemId: 'third_man_passer',
            actorItemId: 'third_man_passer',
            stageIndex: 1,
          ),
          route(
            'third_man_first_pass',
            TrainingMethodRouteKind.ball,
            <TrainingMethodPoint>[point(0.23, 0.65), point(0.46, 0.50)],
            linkedItemId: 'third_man_ball',
            actorItemId: 'third_man_passer',
            targetItemId: 'third_man_link',
            segmentDurationsMs: const <int>[500],
            stageIndex: 1,
          ),
          route(
            'third_man_runner_move',
            TrainingMethodRouteKind.player,
            <TrainingMethodPoint>[point(0.72, 0.30), point(0.80, 0.24)],
            linkedItemId: 'third_man_runner',
            actorItemId: 'third_man_runner',
            stageIndex: 2,
          ),
          route(
            'third_man_layoff',
            TrainingMethodRouteKind.ball,
            <TrainingMethodPoint>[point(0.46, 0.50), point(0.80, 0.24)],
            linkedItemId: 'third_man_ball',
            actorItemId: 'third_man_link',
            targetItemId: 'third_man_runner',
            segmentDurationsMs: const <int>[620],
            stageIndex: 2,
          ),
          route(
            'third_man_finish',
            TrainingMethodRouteKind.ball,
            <TrainingMethodPoint>[point(0.80, 0.24), point(0.91, 0.18)],
            linkedItemId: 'third_man_ball',
            actorItemId: 'third_man_runner',
            targetItemId: 'third_man_goal',
            segmentDurationsMs: const <int>[440],
            stageIndex: 3,
          ),
        ],
      );

  TrainingMethodLayout coordinationFinish(String title) => onePage(
        title: title,
        methodText: l10n.trainingSketchTemplateCoordinationFinishMethod,
        items: <TrainingMethodItem>[
          player(0.14, 0.74, id: 'coordination_runner'),
          player(0.16, 0.28, id: 'coordination_partner', color: playerGreen),
          player(0.82, 0.24, id: 'coordination_keeper', color: playerRed),
          ball(0.21, 0.70, id: 'coordination_ball'),
          prop('ladder', 0.34, 0.62, id: 'coordination_ladder', size: 42),
          prop('hurdle', 0.54, 0.48, id: 'coordination_hurdle', size: 34),
          cone(0.68, 0.36, id: 'coordination_cone'),
          prop('target', 0.91, 0.18, id: 'coordination_goal', size: 38),
        ],
        routes: <TrainingMethodRoute>[
          route(
            'coordination_run',
            TrainingMethodRouteKind.player,
            <TrainingMethodPoint>[
              point(0.14, 0.74),
              point(0.34, 0.62),
              point(0.54, 0.48),
              point(0.74, 0.30),
            ],
            linkedItemId: 'coordination_runner',
            actorItemId: 'coordination_runner',
            stageIndex: 1,
          ),
          route(
            'coordination_carry',
            TrainingMethodRouteKind.ball,
            <TrainingMethodPoint>[
              point(0.21, 0.70),
              point(0.41, 0.58),
              point(0.61, 0.44),
              point(0.80, 0.27),
            ],
            linkedItemId: 'coordination_ball',
            actorItemId: 'coordination_runner',
            targetItemId: 'coordination_runner',
            segmentDurationsMs: const <int>[420, 440, 500],
            stageIndex: 1,
          ),
          route(
            'coordination_finish',
            TrainingMethodRouteKind.ball,
            <TrainingMethodPoint>[point(0.80, 0.27), point(0.91, 0.18)],
            linkedItemId: 'coordination_ball',
            actorItemId: 'coordination_runner',
            targetItemId: 'coordination_goal',
            segmentDurationsMs: const <int>[480],
            stageIndex: 2,
          ),
        ],
      );

  TrainingMethodLayout baseballDoublePlay(String title) => onePage(
        title: title,
        methodText: l10n.trainingSketchTemplateBaseballDoublePlayMethod,
        items: <TrainingMethodItem>[
          player(0.42, 0.66, id: 'double_play_shortstop'),
          player(0.62, 0.48, id: 'double_play_second', color: playerGreen),
          player(0.84, 0.30, id: 'double_play_first'),
          player(0.18, 0.78, id: 'double_play_runner', color: playerRed),
          ball(0.42, 0.66, id: 'double_play_ball'),
          prop('base', 0.62, 0.48, id: 'double_play_second_base'),
          prop('base', 0.84, 0.30, id: 'double_play_first_base'),
        ],
        routes: <TrainingMethodRoute>[
          route(
            'double_play_field',
            TrainingMethodRouteKind.player,
            <TrainingMethodPoint>[point(0.42, 0.66), point(0.48, 0.58)],
            linkedItemId: 'double_play_shortstop',
            actorItemId: 'double_play_shortstop',
            stageIndex: 1,
          ),
          route(
            'double_play_feed',
            TrainingMethodRouteKind.ball,
            <TrainingMethodPoint>[point(0.42, 0.66), point(0.62, 0.48)],
            linkedItemId: 'double_play_ball',
            actorItemId: 'double_play_shortstop',
            targetItemId: 'double_play_second',
            segmentDurationsMs: const <int>[460],
            stageIndex: 1,
          ),
          route(
            'double_play_pivot',
            TrainingMethodRouteKind.player,
            <TrainingMethodPoint>[point(0.62, 0.48), point(0.68, 0.40)],
            linkedItemId: 'double_play_second',
            actorItemId: 'double_play_second',
            stageIndex: 2,
          ),
          route(
            'double_play_throw',
            TrainingMethodRouteKind.ball,
            <TrainingMethodPoint>[point(0.62, 0.48), point(0.84, 0.30)],
            linkedItemId: 'double_play_ball',
            actorItemId: 'double_play_second',
            targetItemId: 'double_play_first',
            segmentDurationsMs: const <int>[440],
            stageIndex: 2,
          ),
        ],
      );

  TrainingMethodLayout baseballBaseRunning(String title) => onePage(
        title: title,
        methodText: l10n.trainingSketchTemplateBaseballBaseRunningMethod,
        items: <TrainingMethodItem>[
          player(0.18, 0.76, id: 'base_running_batter'),
          player(0.52, 0.40, id: 'base_running_pitcher', color: playerRed),
          player(0.78, 0.26, id: 'base_running_fielder'),
          ball(0.24, 0.72, id: 'base_running_ball'),
          prop('base', 0.46, 0.60, id: 'base_running_first'),
          prop('base', 0.70, 0.42, id: 'base_running_second'),
          prop('base', 0.56, 0.22, id: 'base_running_third'),
        ],
        routes: <TrainingMethodRoute>[
          route(
            'base_running_hit',
            TrainingMethodRouteKind.ball,
            <TrainingMethodPoint>[point(0.24, 0.72), point(0.76, 0.28)],
            linkedItemId: 'base_running_ball',
            actorItemId: 'base_running_batter',
            targetItemId: 'base_running_fielder',
            segmentDurationsMs: const <int>[620],
            stageIndex: 1,
          ),
          route(
            'base_running_sprint',
            TrainingMethodRouteKind.player,
            <TrainingMethodPoint>[
              point(0.18, 0.76),
              point(0.46, 0.60),
              point(0.70, 0.42),
              point(0.56, 0.22),
            ],
            linkedItemId: 'base_running_batter',
            actorItemId: 'base_running_batter',
            stageIndex: 1,
          ),
          route(
            'base_running_relay',
            TrainingMethodRouteKind.ball,
            <TrainingMethodPoint>[point(0.76, 0.28), point(0.52, 0.40)],
            linkedItemId: 'base_running_ball',
            actorItemId: 'base_running_fielder',
            targetItemId: 'base_running_pitcher',
            segmentDurationsMs: const <int>[460],
            stageIndex: 2,
          ),
        ],
      );

  TrainingMethodLayout basketballTransition(String title) => onePage(
        title: title,
        methodText: l10n.trainingSketchTemplateBasketballTransitionMethod,
        items: <TrainingMethodItem>[
          player(0.16, 0.76, id: 'basket_transition_guard'),
          player(0.48, 0.58,
              id: 'basket_transition_middle', color: playerGreen),
          player(0.80, 0.28, id: 'basket_transition_wing'),
          player(0.56, 0.34,
              id: 'basket_transition_defender', color: playerRed),
          ball(0.22, 0.72, id: 'basket_transition_ball'),
          prop('basket', 0.92, 0.16, id: 'basket_transition_basket', size: 40),
        ],
        routes: <TrainingMethodRoute>[
          route(
            'basket_transition_guard_run',
            TrainingMethodRouteKind.player,
            <TrainingMethodPoint>[point(0.16, 0.76), point(0.40, 0.62)],
            linkedItemId: 'basket_transition_guard',
            actorItemId: 'basket_transition_guard',
            stageIndex: 1,
          ),
          route(
            'basket_transition_first_pass',
            TrainingMethodRouteKind.ball,
            <TrainingMethodPoint>[point(0.22, 0.72), point(0.48, 0.58)],
            linkedItemId: 'basket_transition_ball',
            actorItemId: 'basket_transition_guard',
            targetItemId: 'basket_transition_middle',
            segmentDurationsMs: const <int>[440],
            stageIndex: 1,
          ),
          route(
            'basket_transition_second_pass',
            TrainingMethodRouteKind.ball,
            <TrainingMethodPoint>[point(0.48, 0.58), point(0.80, 0.28)],
            linkedItemId: 'basket_transition_ball',
            actorItemId: 'basket_transition_middle',
            targetItemId: 'basket_transition_wing',
            segmentDurationsMs: const <int>[500],
            stageIndex: 2,
          ),
          route(
            'basket_transition_finish',
            TrainingMethodRouteKind.ball,
            <TrainingMethodPoint>[point(0.80, 0.28), point(0.92, 0.16)],
            linkedItemId: 'basket_transition_ball',
            actorItemId: 'basket_transition_wing',
            targetItemId: 'basket_transition_basket',
            segmentDurationsMs: const <int>[420],
            stageIndex: 3,
          ),
        ],
      );

  TrainingMethodLayout basketballPickRoll(String title) => onePage(
        title: title,
        methodText: l10n.trainingSketchTemplateBasketballPickRollMethod,
        items: <TrainingMethodItem>[
          player(0.22, 0.76, id: 'pick_roll_handler'),
          player(0.50, 0.56, id: 'pick_roll_screener', color: playerGreen),
          player(0.78, 0.34, id: 'pick_roll_shooter'),
          player(0.36, 0.62, id: 'pick_roll_defender', color: playerRed),
          ball(0.28, 0.72, id: 'pick_roll_ball'),
          prop('basket', 0.92, 0.16, id: 'pick_roll_basket', size: 40),
        ],
        routes: <TrainingMethodRoute>[
          route(
            'pick_roll_screen',
            TrainingMethodRouteKind.player,
            <TrainingMethodPoint>[point(0.50, 0.56), point(0.46, 0.48)],
            linkedItemId: 'pick_roll_screener',
            actorItemId: 'pick_roll_screener',
            stageIndex: 1,
          ),
          route(
            'pick_roll_drive',
            TrainingMethodRouteKind.player,
            <TrainingMethodPoint>[point(0.22, 0.76), point(0.54, 0.48)],
            linkedItemId: 'pick_roll_handler',
            actorItemId: 'pick_roll_handler',
            stageIndex: 1,
          ),
          route(
            'pick_roll_carry',
            TrainingMethodRouteKind.ball,
            <TrainingMethodPoint>[point(0.28, 0.72), point(0.60, 0.44)],
            linkedItemId: 'pick_roll_ball',
            actorItemId: 'pick_roll_handler',
            targetItemId: 'pick_roll_handler',
            segmentDurationsMs: const <int>[540],
            stageIndex: 1,
          ),
          route(
            'pick_roll_kickout',
            TrainingMethodRouteKind.ball,
            <TrainingMethodPoint>[point(0.60, 0.44), point(0.78, 0.34)],
            linkedItemId: 'pick_roll_ball',
            actorItemId: 'pick_roll_handler',
            targetItemId: 'pick_roll_shooter',
            segmentDurationsMs: const <int>[420],
            stageIndex: 2,
          ),
          route(
            'pick_roll_shot',
            TrainingMethodRouteKind.ball,
            <TrainingMethodPoint>[point(0.78, 0.34), point(0.92, 0.16)],
            linkedItemId: 'pick_roll_ball',
            actorItemId: 'pick_roll_shooter',
            targetItemId: 'pick_roll_basket',
            segmentDurationsMs: const <int>[380],
            stageIndex: 3,
          ),
        ],
      );

  TrainingMethodLayout tennisReturnRecover(String title) => onePage(
        title: title,
        methodText: l10n.trainingSketchTemplateTennisReturnRecoverMethod,
        items: <TrainingMethodItem>[
          player(0.34, 0.78, id: 'tennis_return_player'),
          player(0.66, 0.22, id: 'tennis_return_server', color: playerRed),
          player(0.50, 0.50, id: 'tennis_return_coach', color: playerGreen),
          ball(0.38, 0.72, id: 'tennis_return_ball'),
          prop('target', 0.20, 0.44, id: 'tennis_return_target', size: 34),
        ],
        routes: <TrainingMethodRoute>[
          route(
            'tennis_return_move',
            TrainingMethodRouteKind.player,
            <TrainingMethodPoint>[
              point(0.34, 0.78),
              point(0.24, 0.60),
              point(0.50, 0.68),
            ],
            linkedItemId: 'tennis_return_player',
            actorItemId: 'tennis_return_player',
            stageIndex: 1,
          ),
          route(
            'tennis_return_cross',
            TrainingMethodRouteKind.ball,
            <TrainingMethodPoint>[point(0.38, 0.72), point(0.20, 0.44)],
            linkedItemId: 'tennis_return_ball',
            actorItemId: 'tennis_return_player',
            targetItemId: 'tennis_return_target',
            segmentDurationsMs: const <int>[440],
            stageIndex: 1,
          ),
          route(
            'tennis_return_reply',
            TrainingMethodRouteKind.ball,
            <TrainingMethodPoint>[point(0.20, 0.44), point(0.50, 0.68)],
            linkedItemId: 'tennis_return_ball',
            actorItemId: 'tennis_return_server',
            targetItemId: 'tennis_return_player',
            segmentDurationsMs: const <int>[520],
            stageIndex: 2,
          ),
        ],
      );

  TrainingMethodLayout tennisApproachVolley(String title) => onePage(
        title: title,
        methodText: l10n.trainingSketchTemplateTennisApproachVolleyMethod,
        items: <TrainingMethodItem>[
          player(0.22, 0.80, id: 'tennis_approach_player'),
          player(0.78, 0.20, id: 'tennis_approach_opponent', color: playerRed),
          player(0.50, 0.50, id: 'tennis_approach_coach', color: playerGreen),
          ball(0.28, 0.74, id: 'tennis_approach_ball'),
          cone(0.46, 0.56, id: 'tennis_approach_cone'),
          prop('target', 0.72, 0.38, id: 'tennis_approach_target', size: 34),
        ],
        routes: <TrainingMethodRoute>[
          route(
            'tennis_approach_run',
            TrainingMethodRouteKind.player,
            <TrainingMethodPoint>[
              point(0.22, 0.80),
              point(0.46, 0.56),
              point(0.62, 0.44),
            ],
            linkedItemId: 'tennis_approach_player',
            actorItemId: 'tennis_approach_player',
            stageIndex: 1,
          ),
          route(
            'tennis_approach_shot',
            TrainingMethodRouteKind.ball,
            <TrainingMethodPoint>[point(0.28, 0.74), point(0.72, 0.38)],
            linkedItemId: 'tennis_approach_ball',
            actorItemId: 'tennis_approach_player',
            targetItemId: 'tennis_approach_target',
            segmentDurationsMs: const <int>[580],
            stageIndex: 1,
          ),
          route(
            'tennis_approach_volley',
            TrainingMethodRouteKind.ball,
            <TrainingMethodPoint>[point(0.72, 0.38), point(0.78, 0.20)],
            linkedItemId: 'tennis_approach_ball',
            actorItemId: 'tennis_approach_player',
            targetItemId: 'tennis_approach_opponent',
            segmentDurationsMs: const <int>[360],
            stageIndex: 2,
          ),
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
        TrainingBoardTemplateOption(
          id: 'baseball_double_play',
          icon: Icons.sync_alt_outlined,
          label: l10n.trainingSketchTemplateBaseballDoublePlayLabel,
          description: l10n.trainingSketchTemplateBaseballDoublePlayDescription,
          buildLayout: baseballDoublePlay,
        ),
        TrainingBoardTemplateOption(
          id: 'baseball_base_running',
          icon: Icons.directions_run_outlined,
          label: l10n.trainingSketchTemplateBaseballBaseRunningLabel,
          description:
              l10n.trainingSketchTemplateBaseballBaseRunningDescription,
          buildLayout: baseballBaseRunning,
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
        TrainingBoardTemplateOption(
          id: 'basketball_transition',
          icon: Icons.fast_forward_outlined,
          label: l10n.trainingSketchTemplateBasketballTransitionLabel,
          description:
              l10n.trainingSketchTemplateBasketballTransitionDescription,
          buildLayout: basketballTransition,
        ),
        TrainingBoardTemplateOption(
          id: 'basketball_pick_roll',
          icon: Icons.account_tree_outlined,
          label: l10n.trainingSketchTemplateBasketballPickRollLabel,
          description: l10n.trainingSketchTemplateBasketballPickRollDescription,
          buildLayout: basketballPickRoll,
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
        TrainingBoardTemplateOption(
          id: 'tennis_return_recover',
          icon: Icons.reply_all_outlined,
          label: l10n.trainingSketchTemplateTennisReturnRecoverLabel,
          description:
              l10n.trainingSketchTemplateTennisReturnRecoverDescription,
          buildLayout: tennisReturnRecover,
        ),
        TrainingBoardTemplateOption(
          id: 'tennis_approach_volley',
          icon: Icons.north_east_outlined,
          label: l10n.trainingSketchTemplateTennisApproachVolleyLabel,
          description:
              l10n.trainingSketchTemplateTennisApproachVolleyDescription,
          buildLayout: tennisApproachVolley,
        ),
      ];
  }

  return <TrainingBoardTemplateOption>[
    blankTemplate,
    TrainingBoardTemplateOption(
      id: 'ball_mastery',
      icon: Icons.sports_soccer_outlined,
      label: l10n.trainingSketchTemplateBallMasteryLabel,
      description: l10n.trainingSketchTemplateBallMasteryDescription,
      buildLayout: ballMastery,
    ),
    TrainingBoardTemplateOption(
      id: 'pass_warmup',
      icon: Icons.sports_soccer_outlined,
      label: l10n.trainingSketchTemplatePassWarmupLabel,
      description: l10n.trainingSketchTemplatePassWarmupDescription,
      buildLayout: passWarmup,
    ),
    TrainingBoardTemplateOption(
      id: 'first_touch_finish',
      icon: Icons.touch_app_outlined,
      label: l10n.trainingSketchTemplateFirstTouchFinishLabel,
      description: l10n.trainingSketchTemplateFirstTouchFinishDescription,
      buildLayout: firstTouchFinish,
    ),
    TrainingBoardTemplateOption(
      id: 'one_v_one',
      icon: Icons.person_search_outlined,
      label: l10n.trainingSketchTemplateOneVOneLabel,
      description: l10n.trainingSketchTemplateOneVOneDescription,
      buildLayout: oneVOne,
    ),
    TrainingBoardTemplateOption(
      id: 'two_v_one',
      icon: Icons.group_outlined,
      label: l10n.trainingSketchTemplateTwoVOneLabel,
      description: l10n.trainingSketchTemplateTwoVOneDescription,
      buildLayout: twoVOne,
    ),
    TrainingBoardTemplateOption(
      id: 'third_man',
      icon: Icons.call_split_outlined,
      label: l10n.trainingSketchTemplateThirdManLabel,
      description: l10n.trainingSketchTemplateThirdManDescription,
      buildLayout: thirdMan,
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
      id: 'coordination_finish',
      icon: Icons.route_outlined,
      label: l10n.trainingSketchTemplateCoordinationFinishLabel,
      description: l10n.trainingSketchTemplateCoordinationFinishDescription,
      buildLayout: coordinationFinish,
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
    TrainingBoardTemplateOption(
      id: 'switch_play',
      icon: Icons.swap_horiz_rounded,
      label: l10n.trainingSketchTemplateSwitchPlayLabel,
      description: l10n.trainingSketchTemplateSwitchPlayDescription,
      buildLayout: switchPlay,
    ),
    TrainingBoardTemplateOption(
      id: 'defensive_shift',
      icon: Icons.shield_outlined,
      label: l10n.trainingSketchTemplateDefensiveShiftLabel,
      description: l10n.trainingSketchTemplateDefensiveShiftDescription,
      buildLayout: defensiveShift,
    ),
  ];
}
