import 'dart:io';
import 'dart:math' as math;
import 'dart:ui';
import 'package:flutter_test/flutter_test.dart';
import 'package:football_note/domain/scan_pass/real_match_replay.dart';
import 'package:football_note/domain/scan_pass/real_match_replay_detail.dart';
import 'package:football_note/presentation/scan_pass/replay_pitch_geometry.dart';

void main() {
  test(
      'detail protects actual head, limbs and ball, not only the ground anchor',
      () {
    final catalog = RealMatchReplayCatalog.fromJsonString(
        File('assets/scan_pass_replay/catalog.json').readAsStringSync());
    final failures = <Map<String, Object?>>[];
    var checked = 0;
    for (final scene in catalog.scenes) {
      final data = RealMatchReplayData.fromJsonString(
          File(scene.asset).readAsStringSync());
      for (final step in data.scene.steps) {
        final detail = RealMatchReplayActionDetail.forStep(data, step);
        if (detail == null) continue;
        for (final size in [
          const Size(280, 280),
          const Size(336, 400),
          const Size(430, 210),
          const Size(600, 300),
          const Size(1000, 500)
        ]) {
          final geometry = ReplayPitchGeometry.forSize(size,
              camera: detail.camera,
              attackDirection: data.scene.attackDirection,
              view: ReplayPitchView.actionDetail,
              pitchLength: data.pitchLength,
              pitchWidth: data.pitchWidth,
              fitPlayerBodies: true,
              bodyScaleMinimum: 38,
              bodyScaleMaximum: 54,
              bodyScaleFactor: 1.9,
              rotatePitch: size.width < size.height,
              headerInset: 14 * 1.4 + 28,
              bottomInset: 12 * 1.4 + 28);
          final bodyScale =
              math.max(38.0, math.min(54.0, geometry.scale * 1.9));
          final safe = Rect.fromLTRB(
              0, 14 * 1.4 + 28, size.width, size.height - (12 * 1.4 + 16) - 3);
          for (var n = 0; n <= 20; n++) {
            final time = detail.sourceTimeAt(n / 20),
                point = data.renderSample(time).players[detail.actorIndex]!;
            final pose = data.poseAt(time, detail.actorIndex) ??
                data.motion.simplifiedPoseAt(time, detail.actorIndex);
            final joints = {
              for (var j = 0; j < data.joints.length; j++)
                data.joints[j]: pose.joints[j]
            };
            final baseZ = math.max(
                -.05, math.min(joints['lHeel']!.z, joints['rHeel']!.z));
            for (final entry in joints.entries) {
              final joint = entry.value, local = bodyScale / geometry.scale;
              var p = geometry
                  .project(point.x + joint.x * local, point.y + joint.y * local)
                  .translate(0, -(joint.z - baseZ) * bodyScale * .85);
              final radius = entry.key == 'nose'
                  ? math.max(2.0, bodyScale * .095) + bodyScale * .03
                  : bodyScale * .075;
              if (!safe.inflate(.1).contains(p - Offset(radius, radius)) ||
                  !safe.inflate(.1).contains(p + Offset(radius, radius))) {
                failures.add({
                  'scene': scene.id,
                  'kind': step.kind.name,
                  'time': time,
                  'size': size.toString(),
                  'joint': entry.key,
                  'point': p.toString(),
                  'radius': radius
                });
                break;
              }
            }
            final ball = data.sample(time).ball,
                b = geometry.project(ball.x, ball.y, ball.z);
            if (!safe.inflate(.1).contains(b - const Offset(8, 8)) ||
                !safe.inflate(.1).contains(b + const Offset(8, 8))) {
              failures.add({
                'scene': scene.id,
                'kind': step.kind.name,
                'time': time,
                'size': size.toString(),
                'joint': 'ball',
                'point': b.toString()
              });
            }
            checked++;
          }
        }
      }
    }

    expect(checked, greaterThan(9000));
    expect(failures, isEmpty,
        reason:
            'Source limbs and ball must clear the caption and path legend.');
  });
}
