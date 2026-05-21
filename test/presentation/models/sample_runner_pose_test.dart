import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:football_note/presentation/models/sample_runner_pose.dart';

void main() {
  test('keeps runner limb segment lengths fixed during the sample cycle', () {
    const size = Size(360, 157.5);
    final poses = <SampleRunnerPose>[
      for (final progress in <double>[0, 0.125, 0.25, 0.375, 0.5, 0.75])
        buildSampleRunnerPose(progress: progress, size: size),
    ];
    final reference = poses.first;

    for (final pose in poses.skip(1)) {
      expect(
        pose.frontLeg.thighLength,
        closeTo(reference.frontLeg.thighLength, 0.0001),
      );
      expect(
        pose.frontLeg.shinLength,
        closeTo(reference.frontLeg.shinLength, 0.0001),
      );
      expect(
        pose.rearLeg.thighLength,
        closeTo(reference.rearLeg.thighLength, 0.0001),
      );
      expect(
        pose.rearLeg.shinLength,
        closeTo(reference.rearLeg.shinLength, 0.0001),
      );
      expect(
        pose.frontArm.upperArmLength,
        closeTo(reference.frontArm.upperArmLength, 0.0001),
      );
      expect(
        pose.frontArm.forearmLength,
        closeTo(reference.frontArm.forearmLength, 0.0001),
      );
      expect(
        pose.rearArm.upperArmLength,
        closeTo(reference.rearArm.upperArmLength, 0.0001),
      );
      expect(
        pose.rearArm.forearmLength,
        closeTo(reference.rearArm.forearmLength, 0.0001),
      );
    }
  });

  test('scales runner body proportions from frame height instead of width', () {
    final wide = buildSampleRunnerPose(
      progress: 0.25,
      size: const Size(360, 157.5),
    );
    final ultraWide = buildSampleRunnerPose(
      progress: 0.25,
      size: const Size(720, 157.5),
    );

    expect(
      ultraWide.frontLeg.thighLength,
      closeTo(wide.frontLeg.thighLength, 0.0001),
    );
    expect(
      ultraWide.frontArm.upperArmLength,
      closeTo(wide.frontArm.upperArmLength, 0.0001),
    );
    expect(ultraWide.head.dy, closeTo(wide.head.dy, 0.0001));
  });

  test('keeps the sample runner centered with a forward-driving lean', () {
    const size = Size(360, 157.5);
    final poses = <SampleRunnerPose>[
      for (final progress in <double>[0, 0.125, 0.25, 0.375, 0.5, 0.75])
        buildSampleRunnerPose(progress: progress, size: size),
    ];

    for (final pose in poses) {
      expect(
        pose.hip.dx,
        inInclusiveRange(size.width * 0.50, size.width * 0.58),
      );
      expect(pose.chest.dx, greaterThan(pose.hip.dx));
      expect(pose.head.dx, greaterThan(pose.chest.dx));
    }
  });

  test('adds a larger high-knee stride for a more dynamic sample cycle', () {
    const size = Size(360, 157.5);
    final drivePose = buildSampleRunnerPose(progress: 0.25, size: size);
    final groundedPose = buildSampleRunnerPose(progress: 0.75, size: size);

    expect(
      groundedPose.frontLeg.knee.dy - drivePose.frontLeg.knee.dy,
      greaterThan(size.height * 0.07),
    );
    expect(
      drivePose.frontLeg.ankle.dx - drivePose.rearLeg.ankle.dx,
      greaterThan(size.height * 0.34),
    );
  });
}
