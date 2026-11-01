import 'dart:convert';
import 'dart:math' as math;

import 'real_match_replay.dart';

enum SpatialLearningTheme {
  lateralSwitch,
  forwardConnection,
  pressureSupport,
  carryThenConnect,
  wideToInside,
  combination,
  turnover,
  recovery,
}

enum SpatialEvidenceRole { departure, arrival }

enum SpatialLearningObjective {
  receivingLane,
  pressureOutlet,
  thirdPlayer,
  switchingSpace,
}

enum SpatialEducationMeasurement {
  laneAngleDegrees,
  defenderClearanceMeters,
  forwardAdvanceMeters,
}

class SpatialLearningActor {
  final int playerId;
  final String playerName;

  const SpatialLearningActor({
    required this.playerId,
    required this.playerName,
  });
}

class SpatialEducationLesson {
  static const expectedProofVersion = 'spatial-education-evidence-v2';
  static const quantizationMeters = .005;

  final SpatialLearningObjective objective;
  final SpatialEducationMeasurement measurement;
  final String proofVersion;
  final List<String> referenceUrls;
  final String questionKey;
  final String actionKey;
  final String resultKey;
  final SpatialLearningActor focusActor;
  final List<SpatialLearningActor> supportActors;
  final List<SpatialLearningActor> opponentActors;
  final SpatialLearningActor? nextActor;
  final double movementStart;
  final double trigger;
  final double outcome;
  final double slowStart;
  final double slowEnd;
  final double? nextConnection;
  final int movementStartFrame;
  final int triggerFrame;
  final int outcomeFrame;
  final int? nextConnectionFrame;
  final double beforeValue;
  final double afterValue;
  final double improvement;
  final double movementMeters;
  final double? pressureMeters;
  final double? lateralMeters;
  final double? forwardMeters;
  final double? receiverContributionDegrees;
  final double? defenderProjectionBefore;
  final double? defenderProjectionAfter;
  final double? movementAlignment;
  final double? baselinePassLineGapMeters;
  final double? afterPassLineGapMeters;
  final double? receiverLineGapContributionMeters;

  const SpatialEducationLesson({
    required this.objective,
    required this.measurement,
    required this.proofVersion,
    required this.referenceUrls,
    required this.questionKey,
    required this.actionKey,
    required this.resultKey,
    required this.focusActor,
    required this.supportActors,
    required this.opponentActors,
    required this.nextActor,
    required this.movementStart,
    required this.trigger,
    required this.outcome,
    required this.slowStart,
    required this.slowEnd,
    required this.nextConnection,
    required this.movementStartFrame,
    required this.triggerFrame,
    required this.outcomeFrame,
    required this.nextConnectionFrame,
    required this.beforeValue,
    required this.afterValue,
    required this.improvement,
    required this.movementMeters,
    required this.pressureMeters,
    required this.lateralMeters,
    required this.forwardMeters,
    required this.receiverContributionDegrees,
    required this.defenderProjectionBefore,
    required this.defenderProjectionAfter,
    required this.movementAlignment,
    required this.baselinePassLineGapMeters,
    required this.afterPassLineGapMeters,
    required this.receiverLineGapContributionMeters,
  });

  Set<int> get actorIds => <int>{
        focusActor.playerId,
        ...supportActors.map((actor) => actor.playerId),
        ...opponentActors.map((actor) => actor.playerId),
        if (nextActor != null) nextActor!.playerId,
      };

  Set<String> get actorNames => <String>{
        focusActor.playerName,
        ...supportActors.map((actor) => actor.playerName),
        ...opponentActors.map((actor) => actor.playerName),
        if (nextActor != null) nextActor!.playerName,
      };
}

class SpatialSourcePin {
  final String key;
  final String provider;
  final String license;
  final String commit;
  final String sourceUrl;
  final Set<int> matchIds;

  const SpatialSourcePin({
    required this.key,
    required this.provider,
    required this.license,
    required this.commit,
    required this.sourceUrl,
    required this.matchIds,
  });
}

class SpatialLibraryDiscovery {
  const SpatialLibraryDiscovery._();

  static String normalize(String value) {
    final buffer = StringBuffer();
    for (final rune in value.trim().toLowerCase().runes) {
      final character = String.fromCharCode(rune);
      final folded = _spatialSearchCharacterFolds[character] ?? character;
      if (!RegExp(r"[\s\-_.·/\\'’]").hasMatch(folded)) {
        buffer.write(folded);
      }
    }
    return buffer.toString();
  }

  static bool matchesScene(
    SpatialLibraryScene scene,
    String query, {
    Iterable<String> themeTerms = const <String>[],
  }) {
    final tokens = query
        .trim()
        .split(RegExp(r'\s+'))
        .map(normalize)
        .where((token) => token.isNotEmpty)
        .toList(growable: false);
    if (tokens.isEmpty) return true;

    final values = <String>{
      scene.home,
      scene.away,
      ..._aliasesFor(scene.home, _spatialTeamSearchAliases),
      ..._aliasesFor(scene.away, _spatialTeamSearchAliases),
      scene.focusPlayerName,
      ...scene.evidenceAnchors.map((anchor) => anchor.playerName),
      scene.season,
      if (scene.education != null) scene.education!.objective.name,
      if (scene.education != null) ...scene.education!.actorNames,
      for (final player in scene.participantNames)
        ..._aliasesFor(player, _spatialPlayerSearchAliases),
      scene.theme.name,
      ...themeTerms,
    }.map(normalize).where((value) => value.isNotEmpty).toSet();
    return tokens.every(
      (token) => values.any((value) => value.contains(token)),
    );
  }

  static Iterable<String> _aliasesFor(
    String value,
    Map<String, List<String>> aliases,
  ) =>
      aliases[value] ?? const <String>[];
}

class SpatialEvidenceAnchor {
  final double time;
  final SpatialEvidenceRole role;
  final int playerId;
  final String playerName;

  const SpatialEvidenceAnchor({
    required this.time,
    required this.role,
    required this.playerId,
    required this.playerName,
  });
}

class SpatialEvidenceMetrics {
  final double forwardMeters;
  final double lateralMeters;
  final double startWidthMeters;
  final double insideGainMeters;
  final double? pressureMeters;
  final double carryMeters;
  final double sequenceSeconds;

  const SpatialEvidenceMetrics({
    required this.forwardMeters,
    required this.lateralMeters,
    required this.startWidthMeters,
    required this.insideGainMeters,
    required this.pressureMeters,
    required this.carryMeters,
    required this.sequenceSeconds,
  });
}

class SpatialObservedDefenderGap {
  final int actorId;
  final String actorName;
  final RealMatchReplayPoint actor;
  final int defenderId;
  final String defenderName;
  final RealMatchReplayPoint defender;
  final double meters;

  const SpatialObservedDefenderGap({
    required this.actorId,
    required this.actorName,
    required this.actor,
    required this.defenderId,
    required this.defenderName,
    required this.defender,
    required this.meters,
  });
}

class SpatialLibraryScene {
  final String id;
  final String asset;
  final String assetSha256;
  final SpatialLearningTheme theme;
  final int matchId;
  final String date;
  final String home;
  final String away;
  final int period;
  final int startFrame;
  final int endFrame;
  final double startClock;
  final double duration;
  final int focusPlayerId;
  final String focusPlayerName;
  final List<SpatialEvidenceAnchor> evidenceAnchors;
  final List<int> highlightPlayerIds;
  final bool attackingHome;
  final int attackDirection;
  final double evidenceStart;
  final double evidenceEnd;
  final double coreStart;
  final double coreEnd;
  final List<int> corePlayerIds;
  final List<int> supportPlayerIds;
  final List<int> opponentContextPlayerIds;
  final SpatialEvidenceMetrics metrics;
  final String sourceCommit;
  final String sourceUrl;
  final String season;
  final SpatialEducationLesson? education;

  const SpatialLibraryScene({
    required this.id,
    required this.asset,
    required this.assetSha256,
    required this.theme,
    required this.matchId,
    required this.date,
    required this.home,
    required this.away,
    required this.period,
    required this.startFrame,
    required this.endFrame,
    required this.startClock,
    required this.duration,
    required this.focusPlayerId,
    required this.focusPlayerName,
    required this.evidenceAnchors,
    required this.highlightPlayerIds,
    required this.attackingHome,
    required this.attackDirection,
    required this.evidenceStart,
    required this.evidenceEnd,
    required this.coreStart,
    required this.coreEnd,
    required this.corePlayerIds,
    required this.supportPlayerIds,
    required this.opponentContextPlayerIds,
    required this.metrics,
    required this.sourceCommit,
    required this.sourceUrl,
    this.season = '',
    this.education,
  });

  String get attackingTeam => attackingHome ? home : away;

  Set<String> get participantNames => <String>{
        focusPlayerName,
        ...evidenceAnchors.map((anchor) => anchor.playerName),
        if (education != null) ...education!.actorNames,
      };

  double get teachingStart => education?.slowStart ?? evidenceStart;
  double get teachingEnd => education?.slowEnd ?? evidenceEnd;
  double get teachingCoreStart => education?.movementStart ?? coreStart;
  double get teachingCoreEnd => education?.outcome ?? coreEnd;
  Set<int> get teachingActorIds =>
      education?.actorIds ??
      <int>{
        ...corePlayerIds,
        ...supportPlayerIds,
        ...opponentContextPlayerIds,
      };

  bool involvesPlayer(String playerName) =>
      participantNames.contains(playerName);

  bool matchesSearch(String query) =>
      SpatialLibraryDiscovery.matchesScene(this, query);

  SpatialObservedDefenderGap? observedNearbyDefender(
    RealMatchReplayData data,
    double time,
  ) {
    if (theme != SpatialLearningTheme.pressureSupport) return null;
    final actorId = evidenceAnchors.first.playerId;
    final actorIndex = data.playerIndex(actorId);
    final actorMetadata = data.players[actorIndex];
    final sample = data.sample(time);
    final actor = sample.players[actorIndex];
    if (actor == null || _distance(actor, sample.ball) > 3.5) return null;

    SpatialObservedDefenderGap? nearest;
    for (var index = 0; index < data.players.length; index++) {
      final opponent = data.players[index];
      final point = sample.players[index];
      if (opponent.home == actorMetadata.home || point == null) continue;
      final meters = _distance(actor, point);
      if (nearest == null || meters < nearest.meters) {
        nearest = SpatialObservedDefenderGap(
          actorId: actorId,
          actorName: actorMetadata.name!,
          actor: actor,
          defenderId: opponent.id,
          defenderName: opponent.name!,
          defender: point,
          meters: meters,
        );
      }
    }
    return nearest != null && nearest.meters <= 8 ? nearest : null;
  }

  void validateReplay(RealMatchReplayData data) {
    if (data.scene.id != id ||
        data.match.id != matchId ||
        data.match.home != home ||
        data.match.away != away ||
        data.match.date != date ||
        data.sourceCommit != sourceCommit ||
        data.sourceUrl != sourceUrl ||
        data.scene.focusPlayerId != focusPlayerId ||
        data.scene.attackDirection != attackDirection ||
        (data.startClock - startClock).abs() > 1 / data.fps ||
        (data.duration - duration).abs() > 1 / data.fps ||
        data.annotationSource != RealMatchReplayAnnotationSource.derived ||
        data.coverage != RealMatchReplayCoverage.broadcastVisible ||
        data.ballHeightAvailable ||
        highlightPlayerIds
            .any((id) => !data.players.any((player) => player.id == id))) {
      throw const FormatException(
        'Spatial replay scene does not match its catalog evidence.',
      );
    }
    if (data.hasDisplayReconstruction ||
        data.missingPlayerCoordinate == null ||
        data.sourcePossessionOwners.length != data.frames.length) {
      throw const FormatException(
        'Spatial replay must preserve source visibility without reconstruction.',
      );
    }
    final guardFrames = (data.fps * .5).round();
    for (final anchor in evidenceAnchors) {
      final index = data.playerIndex(anchor.playerId);
      final frame = (anchor.time * data.fps).round();
      final guardStart = frame - guardFrames;
      final guardEnd = frame + guardFrames;
      if (guardStart < 0 ||
          guardEnd >= data.frames.length ||
          data.sourcePossessionOwners[frame] != anchor.playerId ||
          !List<int>.generate(
            guardEnd - guardStart + 1,
            (offset) => guardStart + offset,
          ).every((value) => data.isVisibleAtFrame(value, index))) {
        throw const FormatException('Spatial evidence anchor is not observed.');
      }
      final sample = data.sample(anchor.time);
      final player = sample.players[index];
      if (player == null ||
          _distance(player, sample.ball) > 3.5 + 1 / data.fps) {
        throw const FormatException(
          'Spatial evidence owner is too far from the recorded ball.',
        );
      }
    }
    final coreStartFrame = (coreStart * data.fps).round();
    final coreEndFrame = (coreEnd * data.fps).round();
    for (final id in <int>{
      ...corePlayerIds,
      ...supportPlayerIds,
      ...opponentContextPlayerIds,
    }) {
      final index = data.playerIndex(id);
      for (var frame = coreStartFrame; frame <= coreEndFrame; frame++) {
        if (!data.isVisibleAtFrame(frame, index)) {
          throw const FormatException(
            'Spatial core or context actor has a visibility gap.',
          );
        }
      }
    }
    var checkedOwnedFrames = 0;
    var cursor = 0;
    while (cursor < data.sourcePossessionOwners.length) {
      final owner = data.sourcePossessionOwners[cursor];
      var end = cursor;
      while (end + 1 < data.sourcePossessionOwners.length &&
          data.sourcePossessionOwners[end + 1] == owner) {
        end++;
      }
      if (owner != null && end - cursor + 1 >= 3) {
        int ownerIndex;
        try {
          ownerIndex = data.playerIndex(owner);
        } on ArgumentError {
          throw const FormatException(
            'Spatial owned-ball actor is outside the active roster.',
          );
        }
        for (var frame = cursor; frame <= end; frame++) {
          checkedOwnedFrames++;
          if (!data.isVisibleAtFrame(frame, ownerIndex)) {
            throw const FormatException(
              'Spatial owned-ball actor has a visibility gap.',
            );
          }
        }
      }
      cursor = end + 1;
    }
    if (checkedOwnedFrames == 0) {
      throw const FormatException(
          'Spatial replay has no visible ownership run.');
    }
    education?.validateReplay(this, data);
  }
}

extension SpatialEducationReplayValidation on SpatialEducationLesson {
  void validateReplay(SpatialLibraryScene scene, RealMatchReplayData data) {
    const metricTolerance = .0011;
    if (proofVersion != SpatialEducationLesson.expectedProofVersion ||
        referenceUrls.isEmpty ||
        referenceUrls.any((url) => !url.startsWith('https://')) ||
        questionKey !=
            'spatialEducation${_objectiveSuffix(objective)}Question' ||
        actionKey != 'spatialEducation${_objectiveSuffix(objective)}Action' ||
        resultKey != 'spatialEducation${_objectiveSuffix(objective)}Result' ||
        supportActors.isEmpty ||
        opponentActors.isEmpty ||
        movementStart < 0 ||
        movementStart >= trigger ||
        trigger >= outcome ||
        slowStart > movementStart ||
        slowEnd < outcome ||
        slowEnd > data.duration ||
        movementStartFrame !=
            scene.startFrame + (movementStart * data.fps).round() ||
        triggerFrame != scene.startFrame + (trigger * data.fps).round() ||
        outcomeFrame != scene.startFrame + (outcome * data.fps).round() ||
        (nextConnection == null) != (nextConnectionFrame == null) ||
        (nextConnection != null &&
            (nextConnection! <= outcome ||
                nextConnection! > data.duration ||
                nextConnectionFrame !=
                    scene.startFrame + (nextConnection! * data.fps).round())) ||
        (afterValue - beforeValue - improvement).abs() > metricTolerance) {
      throw const FormatException('Invalid spatial education lesson metadata.');
    }

    for (final actor in <SpatialLearningActor>{
      focusActor,
      ...supportActors,
      ...opponentActors,
      if (nextActor != null) nextActor!,
    }) {
      final player = data.player(actor.playerId);
      if (player.name != actor.playerName) {
        throw const FormatException(
          'Spatial education actor identity does not match the replay.',
        );
      }
    }
    final focusPlayer = data.player(focusActor.playerId);
    final supportIds = supportActors.map((actor) => actor.playerId).toSet();
    final opponentIds = opponentActors.map((actor) => actor.playerId).toSet();
    if (supportIds.contains(focusActor.playerId) ||
        opponentIds.contains(focusActor.playerId) ||
        supportIds.intersection(opponentIds).isNotEmpty ||
        supportActors.any(
          (actor) => data.player(actor.playerId).home != focusPlayer.home,
        ) ||
        opponentActors.any(
          (actor) => data.player(actor.playerId).home == focusPlayer.home,
        ) ||
        (nextActor != null &&
            data.player(nextActor!.playerId).home != focusPlayer.home)) {
      throw const FormatException(
        'Spatial education actor roles do not match source teams.',
      );
    }
    final firstFrame = (movementStart * data.fps).round();
    final lastFrame = (outcome * data.fps).round();
    for (final actor in <SpatialLearningActor>{
      focusActor,
      ...supportActors,
      ...opponentActors,
    }) {
      final index = data.playerIndex(actor.playerId);
      for (var frame = firstFrame; frame <= lastFrame; frame++) {
        if (!data.isVisibleAtFrame(frame, index)) {
          throw const FormatException(
            'Spatial education evidence contains an unobserved actor.',
          );
        }
      }
    }
    final finalFrame = ((nextConnection ?? outcome) * data.fps).round();
    for (var frame = firstFrame; frame <= finalFrame; frame++) {
      if (!data.isBallVisibleAtFrame(frame)) {
        throw const FormatException(
          'Spatial education evidence contains a hidden ball.',
        );
      }
    }
    if (nextActor != null && nextConnection != null) {
      final index = data.playerIndex(nextActor!.playerId);
      for (var frame = firstFrame; frame <= finalFrame; frame++) {
        if (!data.isVisibleAtFrame(frame, index)) {
          throw const FormatException(
            'Spatial education next actor has a visibility gap.',
          );
        }
      }
    }

    RealMatchReplayPoint point(SpatialLearningActor actor, double time) {
      final value = data.sample(time).players[data.playerIndex(actor.playerId)];
      if (value == null) {
        throw const FormatException('Spatial education actor is hidden.');
      }
      return value;
    }

    void expectMetric(double actual, double stored) {
      if ((actual - stored).abs() > metricTolerance) {
        throw const FormatException(
          'Spatial education measurement does not match the replay.',
        );
      }
    }

    final focusStart = point(focusActor, movementStart);
    final focusTrigger = point(focusActor, trigger);
    final focusOutcome = point(focusActor, outcome);
    switch (objective) {
      case SpatialLearningObjective.receivingLane:
        if (measurement != SpatialEducationMeasurement.laneAngleDegrees ||
            supportActors.length != 1 ||
            opponentActors.length != 1 ||
            nextActor != null) {
          throw const FormatException('Invalid receiving-lane evidence roles.');
        }
        final passer = supportActors.single;
        final defender = opponentActors.single;
        final before = _angleDegrees(
          point(passer, movementStart),
          focusStart,
          point(defender, movementStart),
        );
        final after = _angleDegrees(
          point(passer, trigger),
          focusTrigger,
          point(defender, trigger),
        );
        expectMetric(before, beforeValue);
        expectMetric(after, afterValue);
        expectMetric(_distance(focusStart, focusTrigger), movementMeters);
        final projectionBefore = _segmentProjection(
          point(passer, movementStart),
          focusStart,
          point(defender, movementStart),
        );
        final projectionAfter = _segmentProjection(
          point(passer, trigger),
          focusTrigger,
          point(defender, trigger),
        );
        final frozenReceiverAngle = _angleDegrees(
          point(passer, trigger),
          focusStart,
          point(defender, trigger),
        );
        final contribution = after - frozenReceiverAngle;
        final baselineLineGap = _lineGap(
          point(passer, movementStart),
          focusStart,
          point(defender, movementStart),
        );
        final afterLineGap = _lineGap(
          point(passer, trigger),
          focusTrigger,
          point(defender, trigger),
        );
        final frozenReceiverLineGap = _lineGap(
          point(passer, trigger),
          focusStart,
          point(defender, trigger),
        );
        final lineGapContribution = afterLineGap - frozenReceiverLineGap;
        if (receiverContributionDegrees == null ||
            defenderProjectionBefore == null ||
            defenderProjectionAfter == null ||
            baselinePassLineGapMeters == null ||
            afterPassLineGapMeters == null ||
            receiverLineGapContributionMeters == null) {
          throw const FormatException(
            'Receiving-lane causal measurements are missing.',
          );
        }
        expectMetric(contribution, receiverContributionDegrees!);
        expectMetric(projectionBefore, defenderProjectionBefore!);
        expectMetric(projectionAfter, defenderProjectionAfter!);
        expectMetric(baselineLineGap, baselinePassLineGapMeters!);
        expectMetric(afterLineGap, afterPassLineGapMeters!);
        expectMetric(
          lineGapContribution,
          receiverLineGapContributionMeters!,
        );
        if (projectionBefore < -.001 ||
            projectionBefore > 1.001 ||
            projectionAfter < -.001 ||
            projectionAfter > 1.001 ||
            baselineLineGap > 3.001 ||
            before > 25.001 ||
            afterLineGap - baselineLineGap + .01 < .5 ||
            lineGapContribution + .01 < .25 ||
            movementMeters + .01 < .75 ||
            improvement + .001 < 3 ||
            contribution + .001 < 1) {
          throw const FormatException('Receiving-lane threshold is not met.');
        }
        _expectOrderedOwnership(data, <(double, int)>[
          (trigger, passer.playerId),
          (outcome, focusActor.playerId),
        ]);
        _expectOwnerNearBall(data, trigger, passer.playerId);
        _expectOwnerNearBall(data, outcome, focusActor.playerId);
        break;
      case SpatialLearningObjective.pressureOutlet:
        if (measurement !=
                SpatialEducationMeasurement.defenderClearanceMeters ||
            supportActors.length < 2 ||
            opponentActors.length < 2 ||
            nextActor == null ||
            nextConnection == null ||
            pressureMeters == null) {
          throw const FormatException(
              'Invalid pressure-outlet evidence roles.');
        }
        final passer = supportActors.first;
        final pressureDefender = opponentActors.first;
        final comparisonDefender = opponentActors.last;
        expectMetric(
          _distance(point(passer, trigger), point(pressureDefender, trigger)),
          pressureMeters!,
        );
        expectMetric(
          _distance(focusStart, point(comparisonDefender, movementStart)),
          beforeValue,
        );
        expectMetric(
          _distance(focusOutcome, point(comparisonDefender, outcome)),
          afterValue,
        );
        expectMetric(_distance(focusStart, focusOutcome), movementMeters);
        if (pressureMeters! - .01 > 4 || improvement + .01 < 1) {
          throw const FormatException('Pressure-outlet threshold is not met.');
        }
        _expectOrderedOwnership(data, <(double, int)>[
          (trigger, passer.playerId),
          (outcome, focusActor.playerId),
          (nextConnection!, nextActor!.playerId),
        ]);
        _expectOwnerNearBall(data, trigger, passer.playerId);
        _expectOwnerNearBall(data, outcome, focusActor.playerId);
        _expectOwnerNearBall(data, nextConnection!, nextActor!.playerId);
        break;
      case SpatialLearningObjective.thirdPlayer:
        if (supportActors.length != 2 ||
            <int>{
                  supportActors[0].playerId,
                  supportActors[1].playerId,
                  focusActor.playerId,
                }.length !=
                3) {
          throw const FormatException('Third-player actors must be distinct.');
        }
        expectMetric(_distance(focusStart, focusTrigger), movementMeters);
        final totalMovement = _distance(focusStart, focusOutcome);
        final preX = focusTrigger.x - focusStart.x;
        final preY = focusTrigger.y - focusStart.y;
        final totalX = focusOutcome.x - focusStart.x;
        final totalY = focusOutcome.y - focusStart.y;
        final alignment = movementMeters <= 1e-9 || totalMovement <= 1e-9
            ? -1.0
            : (preX * totalX + preY * totalY) /
                (movementMeters * totalMovement);
        if (movementMeters + .01 < .6 ||
            totalMovement + .01 < 1 ||
            alignment + .001 < .5) {
          throw const FormatException(
              'Third-player movement is late or absent.');
        }
        if (movementAlignment == null) {
          throw const FormatException(
            'Third-player movement alignment is missing.',
          );
        }
        expectMetric(alignment, movementAlignment!);
        if (measurement == SpatialEducationMeasurement.forwardAdvanceMeters) {
          final forward =
              (focusOutcome.x - focusStart.x) * scene.attackDirection;
          expectMetric(0, beforeValue);
          expectMetric(forward, afterValue);
          if (improvement + .01 < 1.5) {
            throw const FormatException(
                'Third-player advance is insufficient.');
          }
        } else if (measurement ==
            SpatialEducationMeasurement.defenderClearanceMeters) {
          final defender = opponentActors.single;
          expectMetric(
            _distance(focusStart, point(defender, movementStart)),
            beforeValue,
          );
          expectMetric(
            _distance(focusOutcome, point(defender, outcome)),
            afterValue,
          );
          if (improvement + .01 < 1) {
            throw const FormatException(
              'Third-player clearance improvement is insufficient.',
            );
          }
        } else {
          throw const FormatException('Invalid third-player measurement.');
        }
        final firstConnection = scene.evidenceAnchors.first.time;
        _expectOrderedOwnership(data, <(double, int)>[
          (firstConnection, supportActors[0].playerId),
          (trigger, supportActors[1].playerId),
          (outcome, focusActor.playerId),
        ]);
        _expectOwnerNearBall(
          data,
          firstConnection,
          supportActors[0].playerId,
        );
        _expectOwnerNearBall(data, trigger, supportActors[1].playerId);
        _expectOwnerNearBall(data, outcome, focusActor.playerId);
        break;
      case SpatialLearningObjective.switchingSpace:
        if (measurement !=
                SpatialEducationMeasurement.defenderClearanceMeters ||
            supportActors.length != 1 ||
            opponentActors.length != 1 ||
            lateralMeters == null) {
          throw const FormatException(
              'Invalid switching-space evidence roles.');
        }
        final passer = supportActors.single;
        final defender = opponentActors.single;
        expectMetric(
          _distance(focusStart, point(defender, movementStart)),
          beforeValue,
        );
        expectMetric(
          _distance(focusOutcome, point(defender, outcome)),
          afterValue,
        );
        expectMetric(_distance(focusStart, focusOutcome), movementMeters);
        final lateral = (point(passer, trigger).y - focusOutcome.y).abs();
        expectMetric(lateral, lateralMeters!);
        if (lateralMeters! + .01 < 22 || improvement + .01 < 1) {
          throw const FormatException('Switching-space threshold is not met.');
        }
        _expectOrderedOwnership(data, <(double, int)>[
          (trigger, passer.playerId),
          (outcome, focusActor.playerId),
        ]);
        _expectOwnerNearBall(data, trigger, passer.playerId);
        _expectOwnerNearBall(data, outcome, focusActor.playerId);
        break;
    }
  }
}

void _expectOwnerNearBall(
  RealMatchReplayData data,
  double time,
  int playerId,
) {
  final frame = (time * data.fps).round();
  if (frame < 0 ||
      frame >= data.sourcePossessionOwners.length ||
      data.sourcePossessionOwners[frame] != playerId ||
      !data.isBallVisibleAtFrame(frame)) {
    throw const FormatException(
      'Spatial education source ownership does not match the lesson.',
    );
  }
  final player = data.sample(time).players[data.playerIndex(playerId)];
  if (player == null || _distance(player, data.sample(time).ball) > 3.5) {
    throw const FormatException(
      'Spatial education owner is not observed with the visible ball.',
    );
  }
}

void _expectOrderedOwnership(
  RealMatchReplayData data,
  List<(double, int)> anchors,
) {
  for (var index = 0; index + 1 < anchors.length; index++) {
    final first = anchors[index];
    final second = anchors[index + 1];
    final start = (first.$1 * data.fps).round();
    final end = (second.$1 * data.fps).round();
    if (start >= end ||
        data.sourcePossessionOwners[start] != first.$2 ||
        data.sourcePossessionOwners[end] != second.$2) {
      throw const FormatException(
        'Spatial education source ownership order is invalid.',
      );
    }
    var advanced = false;
    for (var frame = start; frame <= end; frame++) {
      final owner = data.sourcePossessionOwners[frame];
      if (owner == null) continue;
      if (owner == second.$2) {
        advanced = true;
      } else if (owner != first.$2 || advanced) {
        throw const FormatException(
          'Spatial education connection has intervening possession.',
        );
      }
    }
  }
}

double _angleDegrees(
  RealMatchReplayPoint origin,
  RealMatchReplayPoint first,
  RealMatchReplayPoint second,
) {
  final ax = first.x - origin.x;
  final ay = first.y - origin.y;
  final bx = second.x - origin.x;
  final by = second.y - origin.y;
  final denominator =
      math.sqrt(ax * ax + ay * ay) * math.sqrt(bx * bx + by * by);
  if (denominator <= 1e-9) return 0;
  final cosine = ((ax * bx + ay * by) / denominator).clamp(-1.0, 1.0);
  return math.acos(cosine) * 180 / math.pi;
}

double _segmentProjection(
  RealMatchReplayPoint start,
  RealMatchReplayPoint end,
  RealMatchReplayPoint point,
) {
  final dx = end.x - start.x;
  final dy = end.y - start.y;
  final denominator = dx * dx + dy * dy;
  if (denominator <= 1e-9) return double.infinity;
  return ((point.x - start.x) * dx + (point.y - start.y) * dy) / denominator;
}

double _lineGap(
  RealMatchReplayPoint start,
  RealMatchReplayPoint end,
  RealMatchReplayPoint point,
) {
  final dx = end.x - start.x;
  final dy = end.y - start.y;
  final denominator = math.sqrt(dx * dx + dy * dy);
  if (denominator <= 1e-9) return double.infinity;
  return (dx * (point.y - start.y) - dy * (point.x - start.x)).abs() /
      denominator;
}

String _objectiveSuffix(SpatialLearningObjective objective) =>
    switch (objective) {
      SpatialLearningObjective.receivingLane => 'ReceivingLane',
      SpatialLearningObjective.pressureOutlet => 'PressureOutlet',
      SpatialLearningObjective.thirdPlayer => 'ThirdPlayer',
      SpatialLearningObjective.switchingSpace => 'SwitchingSpace',
    };

class SpatialLibraryCatalog {
  static const expectedSourceCommit =
      '1ed50b775f93075c2a6d00d0d795f13b7b89709e';
  static const expectedRecentSourceCommit =
      '4340d274572876239c154c90bc507a9b3250a656';
  static const expectedEducationProofVersion = 'spatial-education-catalog-v2';

  final int version;
  final String provider;
  final String license;
  final String sourceCommit;
  final String sourceUrl;
  final int matchCount;
  final List<SpatialLibraryScene> scenes;
  final String? proofVersion;
  final List<SpatialSourcePin> sourcePins;

  const SpatialLibraryCatalog({
    required this.version,
    required this.provider,
    required this.license,
    required this.sourceCommit,
    required this.sourceUrl,
    required this.matchCount,
    required this.scenes,
    this.proofVersion,
    this.sourcePins = const <SpatialSourcePin>[],
  });

  factory SpatialLibraryCatalog.fromJsonString(String source) {
    final decoded = jsonDecode(source);
    if (decoded is! Map<String, dynamic>) {
      throw const FormatException('Spatial catalog must be a JSON object.');
    }
    return SpatialLibraryCatalog.fromJson(decoded);
  }

  factory SpatialLibraryCatalog.fromJson(Map<String, dynamic> json) {
    final version = _integer(json, 'version');
    final values = _list(json, 'scenes');
    final scenes = values.map((value) {
      final item = _mapValue(value, 'spatial scene');
      final metrics = _map(item, 'metrics');
      final evidenceAnchors = _list(item, 'evidenceAnchors').map((value) {
        final anchor = _mapValue(value, 'evidence anchor');
        return SpatialEvidenceAnchor(
          time: _number(anchor, 'time'),
          role: _enumValue(
            SpatialEvidenceRole.values,
            _string(anchor, 'role'),
            'spatial evidence role',
          ),
          playerId: _integer(anchor, 'playerId'),
          playerName: _string(anchor, 'playerName'),
        );
      }).toList(growable: false);
      final highlightPlayerIds = _list(item, 'highlightPlayerIds')
          .map((value) => _integerValue(value, 'highlight player id'))
          .toList(growable: false);
      final education = item['learning'] == null
          ? null
          : _educationLesson(_map(item, 'learning'));
      return SpatialLibraryScene(
        id: _string(item, 'id'),
        asset: _string(item, 'asset'),
        assetSha256: _string(item, 'assetSha256'),
        theme: _enumValue(
          SpatialLearningTheme.values,
          _string(item, 'theme'),
          'spatial theme',
        ),
        matchId: _integer(item, 'matchId'),
        date: _string(item, 'date'),
        home: _string(item, 'home'),
        away: _string(item, 'away'),
        period: _integer(item, 'period'),
        startFrame: _integer(item, 'startFrame'),
        endFrame: _integer(item, 'endFrame'),
        startClock: _number(item, 'startClock'),
        duration: _number(item, 'duration'),
        focusPlayerId: _integer(item, 'focusPlayerId'),
        focusPlayerName: _string(item, 'focusPlayerName'),
        evidenceAnchors: evidenceAnchors,
        highlightPlayerIds: highlightPlayerIds,
        attackingHome: _string(item, 'attackingTeam') == 'home',
        attackDirection: _integer(item, 'attackDirection'),
        evidenceStart: _number(item, 'evidenceStart'),
        evidenceEnd: _number(item, 'evidenceEnd'),
        coreStart: _number(item, 'coreStart'),
        coreEnd: _number(item, 'coreEnd'),
        corePlayerIds: _integerList(item, 'corePlayerIds'),
        supportPlayerIds: _integerList(item, 'supportPlayerIds'),
        opponentContextPlayerIds: _integerList(
          item,
          'opponentContextPlayerIds',
        ),
        metrics: SpatialEvidenceMetrics(
          forwardMeters: _number(metrics, 'forwardMeters'),
          lateralMeters: _number(metrics, 'lateralMeters'),
          startWidthMeters: _number(metrics, 'startWidthMeters'),
          insideGainMeters: _number(metrics, 'insideGainMeters'),
          pressureMeters: metrics['pressureMeters'] == null
              ? null
              : _number(metrics, 'pressureMeters'),
          carryMeters: _number(metrics, 'carryMeters'),
          sequenceSeconds: _number(metrics, 'sequenceSeconds'),
        ),
        sourceCommit: _string(item, 'sourceCommit'),
        sourceUrl: _string(item, 'sourceUrl'),
        season: item['season'] == null ? '' : _string(item, 'season'),
        education: education,
      );
    }).toList(growable: false);
    final sourcePins = json['sourcePins'] == null
        ? const <SpatialSourcePin>[]
        : _list(json, 'sourcePins').map((value) {
            final pin = _mapValue(value, 'spatial source pin');
            return SpatialSourcePin(
              key: _string(pin, 'key'),
              provider: _string(pin, 'provider'),
              license: _string(pin, 'license'),
              commit: _string(pin, 'commit'),
              sourceUrl: _string(pin, 'sourceUrl'),
              matchIds: _integerList(pin, 'matchIds').toSet(),
            );
          }).toList(growable: false);
    final catalog = SpatialLibraryCatalog(
      version: version,
      provider: _string(json, 'provider'),
      license: _string(json, 'license'),
      sourceCommit: _string(json, 'sourceCommit'),
      sourceUrl: _string(json, 'sourceUrl'),
      matchCount: _integer(json, 'matchCount'),
      scenes: scenes,
      proofVersion:
          json['proofVersion'] == null ? null : _string(json, 'proofVersion'),
      sourcePins: sourcePins,
    );
    catalog._validate();
    return catalog;
  }

  Set<int> get matchIds => scenes.map((scene) => scene.matchId).toSet();
  Set<String> get focalPlayers =>
      scenes.map((scene) => scene.focusPlayerName).toSet();
  Set<SpatialLearningTheme> get themes =>
      scenes.map((scene) => scene.theme).toSet();
  Set<String> get attackingTeams =>
      scenes.map((scene) => scene.attackingTeam).toSet();
  Set<String> participants({String? attackingTeam}) => scenes
      .where(
        (scene) =>
            attackingTeam == null || scene.attackingTeam == attackingTeam,
      )
      .expand((scene) => scene.participantNames)
      .toSet();

  List<SpatialLibraryScene> filtered({
    SpatialLearningTheme? theme,
    String query = '',
    String? attackingTeam,
    String? player,
  }) =>
      scenes
          .where((scene) => theme == null || scene.theme == theme)
          .where(
            (scene) =>
                attackingTeam == null || scene.attackingTeam == attackingTeam,
          )
          .where((scene) => player == null || scene.involvesPlayer(player))
          .where((scene) => scene.matchesSearch(query))
          .toList(growable: false);

  void _validate() {
    if (version == 2) {
      _validateEducation();
      return;
    }
    final ids = <String>{};
    if (version != 1 ||
        provider != 'SkillCorner Open Data' ||
        license != 'MIT' ||
        sourceCommit != expectedSourceCommit ||
        matchCount != 9 ||
        scenes.isEmpty ||
        !sourceUrl
            .startsWith('https://github.com/SkillCorner/opendata/tree/')) {
      throw const FormatException('Invalid spatial catalog metadata.');
    }
    for (final scene in scenes) {
      if (!ids.add(scene.id) ||
          !scene.asset.startsWith('assets/scan_pass_spatial/scenes/') ||
          scene.assetSha256.length != 64 ||
          scene.matchId <= 0 ||
          scene.date.isEmpty ||
          scene.home.isEmpty ||
          scene.away.isEmpty ||
          (scene.period != 1 && scene.period != 2) ||
          scene.startFrame < 0 ||
          scene.endFrame <= scene.startFrame ||
          scene.startClock < 0 ||
          scene.duration < 20 ||
          scene.duration > 40 ||
          scene.focusPlayerName.isEmpty ||
          scene.evidenceAnchors.length < 2 ||
          scene.evidenceAnchors.length > 3 ||
          scene.highlightPlayerIds.length < 4 ||
          scene.highlightPlayerIds.length > 6 ||
          scene.highlightPlayerIds.toSet().length !=
              scene.highlightPlayerIds.length ||
          !scene.highlightPlayerIds.contains(scene.focusPlayerId) ||
          scene.corePlayerIds.length < 2 ||
          scene.supportPlayerIds.isEmpty ||
          scene.opponentContextPlayerIds.isEmpty ||
          <int>{
            ...scene.corePlayerIds,
            ...scene.supportPlayerIds,
            ...scene.opponentContextPlayerIds,
          }.any((id) => !scene.highlightPlayerIds.contains(id)) ||
          scene.evidenceAnchors.any(
            (anchor) =>
                anchor.playerName.isEmpty ||
                !scene.highlightPlayerIds.contains(anchor.playerId),
          ) ||
          scene.attackDirection.abs() != 1 ||
          scene.evidenceStart < 4 ||
          scene.evidenceEnd <= scene.evidenceStart ||
          scene.duration - scene.evidenceEnd < 4 ||
          (scene.coreStart - (scene.evidenceStart - .5)).abs() > .001 ||
          (scene.coreEnd - (scene.evidenceEnd + .5)).abs() > .001 ||
          scene.sourceCommit != sourceCommit ||
          !scene.sourceUrl.startsWith('$sourceUrl/data/matches/')) {
        throw const FormatException('Invalid spatial catalog scene.');
      }
      for (var index = 0; index < scene.evidenceAnchors.length; index++) {
        final anchor = scene.evidenceAnchors[index];
        if (anchor.time <= 0 ||
            anchor.time >= scene.duration ||
            (index > 0 &&
                anchor.time <= scene.evidenceAnchors[index - 1].time)) {
          throw const FormatException('Invalid ordered spatial evidence.');
        }
      }
      if ((scene.evidenceAnchors.first.time - scene.evidenceStart).abs() >
              0.001 ||
          (scene.evidenceAnchors.last.time - scene.evidenceEnd).abs() > 0.001) {
        throw const FormatException('Spatial evidence bounds do not match.');
      }
    }
  }

  void _validateEducation() {
    const historicalRoot =
        'https://github.com/SkillCorner/opendata/tree/$expectedSourceCommit';
    const recentRoot =
        'https://github.com/SkillCorner/opendata/tree/$expectedRecentSourceCommit';
    final ids = <String>{};
    if (provider != 'SkillCorner Open Data' ||
        license != 'MIT' ||
        proofVersion != expectedEducationProofVersion ||
        sourceCommit != 'mixed-pinned-sources-v1' ||
        sourceUrl != 'https://github.com/SkillCorner/opendata' ||
        sourcePins.length != 2 ||
        scenes.isEmpty ||
        matchCount != matchIds.length) {
      throw const FormatException('Invalid spatial education metadata.');
    }
    final pinByCommit = <String, SpatialSourcePin>{
      for (final pin in sourcePins) pin.commit: pin,
    };
    final historical = pinByCommit[expectedSourceCommit];
    final recent = pinByCommit[expectedRecentSourceCommit];
    if (historical == null ||
        recent == null ||
        historical.key != 'historical-2019-20' ||
        recent.key != 'recent-2024-25' ||
        historical.provider != provider ||
        recent.provider != provider ||
        historical.license != license ||
        recent.license != license ||
        historical.sourceUrl != historicalRoot ||
        recent.sourceUrl != recentRoot ||
        recent.matchIds.difference(const <int>{1925299, 1996435}).isNotEmpty ||
        recent.matchIds.isEmpty ||
        sourcePins.expand((pin) => pin.matchIds).toSet().length != matchCount) {
      throw const FormatException('Invalid spatial education source pins.');
    }
    for (final scene in scenes) {
      final lesson = scene.education;
      final pin = pinByCommit[scene.sourceCommit];
      if (!ids.add(scene.id) ||
          lesson == null ||
          pin == null ||
          !pin.matchIds.contains(scene.matchId) ||
          scene.sourceUrl != '${pin.sourceUrl}/data/matches/${scene.matchId}' ||
          scene.assetSha256.length != 64 ||
          scene.season !=
              (scene.sourceCommit == expectedRecentSourceCommit
                  ? '2024/25'
                  : '2019/20') ||
          (scene.sourceCommit == expectedRecentSourceCommit
              ? !scene.asset.startsWith(
                  'assets/scan_pass_spatial/education_scenes/',
                )
              : !scene.asset.startsWith('assets/scan_pass_spatial/scenes/')) ||
          scene.duration < 20 ||
          scene.duration > 40 ||
          scene.duration - lesson.outcome < 4 ||
          lesson.movementStart < 4 ||
          scene.attackDirection.abs() != 1 ||
          !lesson.actorIds.every(scene.highlightPlayerIds.contains) ||
          lesson.focusActor.playerName.isEmpty ||
          scene.evidenceAnchors.any(
            (anchor) =>
                anchor.time <= 0 ||
                anchor.time >= scene.duration ||
                anchor.playerName.isEmpty,
          )) {
        throw const FormatException('Invalid spatial education scene.');
      }
    }
    if (scenes.map((scene) => scene.education!.objective).toSet().length !=
        SpatialLearningObjective.values.length) {
      throw const FormatException(
        'Spatial education catalog must cover every learning objective.',
      );
    }
  }
}

SpatialEducationLesson _educationLesson(Map<String, dynamic> json) {
  SpatialLearningActor actor(Object? value, String label) {
    final item = _mapValue(value, label);
    return SpatialLearningActor(
      playerId: _integer(item, 'playerId'),
      playerName: _string(item, 'playerName'),
    );
  }

  List<SpatialLearningActor> actors(String key) => _list(json, key)
      .map((value) => actor(value, key))
      .toList(growable: false);
  final metrics = _map(json, 'measurements');
  final sourceFrames = _map(json, 'sourceFrames');
  return SpatialEducationLesson(
    objective: _enumValue(
      SpatialLearningObjective.values,
      _string(json, 'objective'),
      'spatial learning objective',
    ),
    measurement: _enumValue(
      SpatialEducationMeasurement.values,
      _string(metrics, 'kind'),
      'spatial education measurement',
    ),
    proofVersion: _string(json, 'proofVersion'),
    referenceUrls: _list(json, 'referenceUrls')
        .map((value) => _stringValue(value, 'reference URL'))
        .toList(growable: false),
    questionKey: _string(json, 'questionKey'),
    actionKey: _string(json, 'actionKey'),
    resultKey: _string(json, 'resultKey'),
    focusActor: actor(json['focusActor'], 'focus actor'),
    supportActors: actors('supportActors'),
    opponentActors: actors('opponentActors'),
    nextActor: json['nextActor'] == null
        ? null
        : actor(json['nextActor'], 'next actor'),
    movementStart: _number(json, 'movementStart'),
    trigger: _number(json, 'trigger'),
    outcome: _number(json, 'outcome'),
    slowStart: _number(json, 'slowStart'),
    slowEnd: _number(json, 'slowEnd'),
    nextConnection:
        json['nextConnection'] == null ? null : _number(json, 'nextConnection'),
    movementStartFrame: _integer(sourceFrames, 'movementStart'),
    triggerFrame: _integer(sourceFrames, 'trigger'),
    outcomeFrame: _integer(sourceFrames, 'outcome'),
    nextConnectionFrame: sourceFrames['nextConnection'] == null
        ? null
        : _integer(sourceFrames, 'nextConnection'),
    beforeValue: _number(metrics, 'before'),
    afterValue: _number(metrics, 'after'),
    improvement: _number(metrics, 'improvement'),
    movementMeters: _number(metrics, 'movementMeters'),
    pressureMeters: metrics['pressureMeters'] == null
        ? null
        : _number(metrics, 'pressureMeters'),
    lateralMeters: metrics['lateralMeters'] == null
        ? null
        : _number(metrics, 'lateralMeters'),
    forwardMeters: metrics['forwardMeters'] == null
        ? null
        : _number(metrics, 'forwardMeters'),
    receiverContributionDegrees: metrics['receiverContributionDegrees'] == null
        ? null
        : _number(metrics, 'receiverContributionDegrees'),
    defenderProjectionBefore: metrics['defenderProjectionBefore'] == null
        ? null
        : _number(metrics, 'defenderProjectionBefore'),
    defenderProjectionAfter: metrics['defenderProjectionAfter'] == null
        ? null
        : _number(metrics, 'defenderProjectionAfter'),
    movementAlignment: metrics['movementAlignment'] == null
        ? null
        : _number(metrics, 'movementAlignment'),
    baselinePassLineGapMeters: metrics['baselinePassLineGapMeters'] == null
        ? null
        : _number(metrics, 'baselinePassLineGapMeters'),
    afterPassLineGapMeters: metrics['afterPassLineGapMeters'] == null
        ? null
        : _number(metrics, 'afterPassLineGapMeters'),
    receiverLineGapContributionMeters:
        metrics['receiverLineGapContributionMeters'] == null
            ? null
            : _number(metrics, 'receiverLineGapContributionMeters'),
  );
}

const _spatialSearchCharacterFolds = <String, String>{
  'à': 'a',
  'á': 'a',
  'â': 'a',
  'ã': 'a',
  'ä': 'a',
  'å': 'a',
  'ā': 'a',
  'ă': 'a',
  'ą': 'a',
  'æ': 'ae',
  'ç': 'c',
  'ć': 'c',
  'č': 'c',
  'ď': 'd',
  'đ': 'd',
  'è': 'e',
  'é': 'e',
  'ê': 'e',
  'ë': 'e',
  'ē': 'e',
  'ė': 'e',
  'ę': 'e',
  'ě': 'e',
  'ğ': 'g',
  'ì': 'i',
  'í': 'i',
  'î': 'i',
  'ï': 'i',
  'ī': 'i',
  'ı': 'i',
  'ľ': 'l',
  'ł': 'l',
  'ñ': 'n',
  'ń': 'n',
  'ň': 'n',
  'ò': 'o',
  'ó': 'o',
  'ô': 'o',
  'õ': 'o',
  'ö': 'o',
  'ø': 'o',
  'ō': 'o',
  'œ': 'oe',
  'ř': 'r',
  'ś': 's',
  'š': 's',
  'ş': 's',
  'ß': 'ss',
  'ť': 't',
  'ù': 'u',
  'ú': 'u',
  'û': 'u',
  'ü': 'u',
  'ū': 'u',
  'ý': 'y',
  'ÿ': 'y',
  'ž': 'z',
  'ź': 'z',
  'ż': 'z',
};

const _spatialTeamSearchAliases = <String, List<String>>{
  'Manchester City': <String>[
    'Man City',
    'Man City FC',
    'MCFC',
    '맨시티',
    '맨체스터 시티',
    'マンチェスターシティ',
  ],
  'Liverpool': <String>['Liverpool FC', 'LFC', '리버풀', 'リヴァプール'],
  'Dortmund': <String>[
    'Borussia Dortmund',
    'BVB',
    '도르트문트',
    'ドルトムント',
  ],
  'Bayern Munchen': <String>[
    'Bayern München',
    'Bayern Munich',
    'FC Bayern',
    'Bayern',
    '바이에른',
    '바이에른 뮌헨',
    'バイエルン',
  ],
  'Juventus': <String>['Juve', '유벤투스', 'ユヴェントス'],
  'Inter': <String>[
    'Inter Milan',
    'Internazionale',
    '인테르',
    '인터 밀란',
    'インテル',
  ],
  'Real Madrid': <String>[
    'Real',
    'RMA',
    '레알',
    '레알 마드리드',
    'レアル',
    'レアルマドリード',
  ],
  'FC Barcelona': <String>[
    'Barcelona',
    'Barca',
    'Barça',
    'FCB',
    '바르셀로나',
    '바르사',
    'バルセロナ',
  ],
  'Paris': <String>[
    'Paris Saint-Germain',
    'Paris Saint Germain',
    'PSG',
    '파리',
    '파리 생제르맹',
    'パリ',
    'パリサンジェルマン',
  ],
  'Marseille': <String>[
    'Olympique Marseille',
    'Olympique de Marseille',
    'OM',
    '마르세유',
    'マルセイユ',
  ],
};

const _spatialPlayerSearchAliases = <String, List<String>>{
  'Aaron Ramsey': <String>['애런 램지'],
  'Achraf Hakimi': <String>['아슈라프 하키미'],
  'Alessandro Bastoni': <String>['알레산드로 바스토니'],
  'Alex Sandro': <String>['알렉스 산드루', '알렉스 산드로'],
  'Alisson Ramses Becker': <String>['알리송', '알리송 베케르'],
  'Ander Herrera': <String>['안데르 에레라'],
  'Antoine Griezmann': <String>['앙투안 그리즈만', '그리즈만'],
  'Arthur': <String>['아르투르'],
  'Arturo Vidal': <String>['아르투로 비달', '비달'],
  'Ashley Young': <String>['애슐리 영'],
  'Aymeric Laporte': <String>['아이메릭 라포르트', '라포르트'],
  'Benjamin Mendy': <String>['뱅자맹 멘디'],
  'Benjamin Pavard': <String>['뱅자맹 파바르'],
  'Bernardo Silva': <String>['베르나르두 실바', '베르나르도 실바'],
  'Casemiro': <String>['카세미루'],
  'Christian Eriksen': <String>['크리스티안 에릭센', '에릭센'],
  'Clément Lenglet': <String>['클레망 랑글레', '랑글레'],
  'Cristiano Ronaldo': <String>[
    '크리스티아누 호날두',
    '호날두',
    'クリスティアーノロナウド',
    'ロナウド',
  ],
  'Daniel Carvajal': <String>['다니 카르바할', '카르바할'],
  'David Alaba': <String>['다비드 알라바', '알라바'],
  'Dejan Lovren': <String>['데얀 로브렌', '로브렌'],
  'Douglas Costa': <String>['더글라스 코스타'],
  'Duje Caleta-Car': <String>['두예 찰레타차르', '칼레타카르'],
  'Ederson': <String>['에데르송'],
  'Emre Can': <String>['엠레 잔'],
  'Eric Garcia': <String>['에릭 가르시아'],
  'Fabinho': <String>['파비뉴'],
  'Federico Valverde': <String>['페데리코 발베르데', '발베르데'],
  'Frenkie de Jong': <String>['프렝키 더용', '프렝키 데용', '더용', '데용'],
  'Gareth Bale': <String>['가레스 베일', '베일'],
  'Georginio Wijnaldum': <String>['조르지니오 바이날둠', '바이날둠'],
  'Gerard Pique': <String>['제라르 피케', '피케'],
  'Gonzalo Higuain': <String>['곤살로 이과인', '이과인'],
  'Ilkay Gündogan': <String>['일카이 귄도안', '귄도안', '권도안'],
  'Isco': <String>['이스코'],
  'Ivan Rakitic': <String>['이반 라키티치', '라키티치'],
  'Javier Martinez': <String>['하비 마르티네스'],
  'Joe Gomez': <String>['조 고메즈', '고메즈'],
  'John Stones': <String>['존 스톤스', '스톤스'],
  'Jordan Amavi': <String>['조르당 아마비', '아마비'],
  'Jordan Henderson': <String>['조던 헨더슨', '헨더슨'],
  'Jordi Alba': <String>['조르디 알바', '알바'],
  'Jose Tasende': <String>['호세 타센데', '타센데'],
  'Joshua Kimmich': <String>['요주아 키미히', '키미히'],
  'Juan Cuadrado': <String>['후안 콰드라도', '콰드라도'],
  'Karim Benzema': <String>['카림 벤제마', '벤제마'],
  'Kevin de Bruyne': <String>[
    '케빈 더브라위너',
    '더브라위너',
    '데브라위너',
    'デブライネ',
  ],
  'Kingsley Coman': <String>['킹슬리 코망', '코망'],
  'Kwadwo Asamoah': <String>['콰드워 아사모아', '아사모아'],
  'Kyle Walker': <String>['카일 워커', '워커'],
  'Kylian Mbappe': <String>[
    'Kylian Mbappé',
    'Mbappé',
    '킬리안 음바페',
    '음바페',
    'エムバペ',
    'ムバッペ',
  ],
  'Lautaro Martinez': <String>['라우타로 마르티네스', '라우타로'],
  'Leandro Paredes': <String>['레안드로 파레데스', '파레데스'],
  'Leonardo Bonucci': <String>['레오나르도 보누치', '보누치'],
  'Lionel Messi': <String>['리오넬 메시', '메시', 'メッシ'],
  'Luis Suarez': <String>['루이스 수아레스', '수아레스'],
  'Luiz Fernandinho': <String>['페르난지뉴'],
  'Luka Modric': <String>['루카 모드리치', '모드리치'],
  'Manuel Akanji': <String>['마누엘 아칸지', '아칸지'],
  'Marc-Andre ter Stegen': <String>[
    'Marc-André ter Stegen',
    '마르크안드레 테어슈테겐',
    '테어 슈테겐',
    '테어슈테겐',
  ],
  'Marcelo': <String>['마르셀루'],
  'Marcelo Brozovic': <String>['마르셀로 브로조비치', '브로조비치'],
  'Marquinhos': <String>['마르키뉴스'],
  'Matias Vecino': <String>['마티아스 베시노', '베시노'],
  'Mats Hummels': <String>['마츠 후멜스', '후멜스'],
  'Matthijs de Ligt': <String>['마테이스 더리흐트', '더 리흐트', '더리흐트'],
  'Milan Skriniar': <String>['밀란 슈크리니아르', '슈크리니아르'],
  'Nelson Semedo': <String>['넬송 세메두', '세메두'],
  'Nicolo Barella': <String>['니콜로 바렐라', '바렐라'],
  'Paulo Dybala': <String>['파울로 디발라', '디발라'],
  'Raheem Sterling': <String>['라힘 스털링', '스털링'],
  'Raphael Guerreiro': <String>['하파엘 게헤이루', '게헤이루'],
  'Raphael Varane': <String>['라파엘 바란', '바란'],
  'Rodrigo Hernandez': <String>['로드리', '로드리고'],
  'Romelu Lukaku': <String>['로멜루 루카쿠', '루카쿠'],
  'Samir Handanovic': <String>['사미르 한다노비치', '한다노비치'],
  'Samuel Umtiti': <String>['사뮈엘 움티티', '움티티'],
  'Serge Gnabry': <String>['세르주 그나브리', '그나브리'],
  'Sergi Roberto': <String>['세르지 로베르토', '로베르토'],
  'Sergio Busquets': <String>['세르히오 부스케츠', '부스케츠'],
  'Sergio Ramos': <String>['세르히오 라모스', '라모스'],
  'Stefan de Vrij': <String>['스테판 더프레이', '더프레이'],
  'Thiago Alcantara': <String>['티아고 알칸타라', '알칸타라'],
  'Thiago Silva': <String>['치아구 실바', '티아고 실바'],
  'Toni Kroos': <String>['토니 크로스', '크로스', 'クロース'],
  'Trent Alexander-Arnold': <String>[
    '트렌트 알렉산더아놀드',
    '알렉산더 아놀드',
    '아놀드',
  ],
  'Virgil van Dijk': <String>['버질 반다이크', '반다이크'],
  'Wojciech Szczesny': <String>['보이치에흐 슈쳉스니', '슈쳉스니'],
};

double _distance(RealMatchReplayPoint a, RealMatchReplayPoint b) {
  final dx = a.x - b.x;
  final dy = a.y - b.y;
  return math.sqrt(dx * dx + dy * dy);
}

T _enumValue<T extends Enum>(List<T> values, String name, String label) =>
    values.firstWhere(
      (value) => value.name == name,
      orElse: () => throw FormatException('Invalid $label.'),
    );

Map<String, dynamic> _map(Map<String, dynamic> map, String key) =>
    _mapValue(map[key], key);

Map<String, dynamic> _mapValue(Object? value, String label) {
  if (value is! Map<String, dynamic>) {
    throw FormatException('$label must be a JSON object.');
  }
  return value;
}

List<dynamic> _list(Map<String, dynamic> map, String key) {
  final value = map[key];
  if (value is! List<dynamic>) {
    throw FormatException('$key must be a JSON array.');
  }
  return value;
}

List<int> _integerList(Map<String, dynamic> map, String key) => _list(map, key)
    .map((value) => _integerValue(value, key))
    .toList(growable: false);

String _string(Map<String, dynamic> map, String key) =>
    _stringValue(map[key], key);

String _stringValue(Object? value, String label) {
  if (value is! String || value.isEmpty) {
    throw FormatException('$label must be a non-empty string.');
  }
  return value;
}

int _integer(Map<String, dynamic> map, String key) =>
    _integerValue(map[key], key);

int _integerValue(Object? value, String label) {
  if (value is! int) throw FormatException('$label must be an integer.');
  return value;
}

double _number(Map<String, dynamic> map, String key) =>
    _numberValue(map[key], key);

double _numberValue(Object? value, String label) {
  if (value is! num || !value.isFinite) {
    throw FormatException('$label must be finite.');
  }
  return value.toDouble();
}
