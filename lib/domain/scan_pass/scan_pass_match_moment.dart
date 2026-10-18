import 'dart:math' as math;

import 'scan_pass_game.dart' show ScanPassPoint;

enum MatchMomentTeam { spain, england }

enum MatchMomentPlayerName {
  unaiSimon,
  daniCarvajal,
  robinLeNormand,
  alvaroMorata,
  fabianRuiz,
  daniOlmo,
  aymericLaporte,
  nicoWilliams,
  martinZubimendi,
  lamineYamal,
  marcCucurella,
  jordanPickford,
  kyleWalker,
  lukeShaw,
  declanRice,
  johnStones,
  marcGuehi,
  bukayoSaka,
  harryKane,
  judeBellingham,
  philFoden,
  kobbieMainoo,
  authoredRole,
}

enum MatchMomentBeat { receive, firstTouch, nextAction }

enum MatchMomentChoiceId {
  receiveInside,
  receiveWide,
  receiveCheck,
  touchInside,
  touchLine,
  touchSet,
  passWilliams,
  passMorata,
  carryInside,
}

enum MatchMomentActionKind {
  leadIn,
  receivePass,
  firstTouch,
  pass,
  carry,
  shot
}

enum MatchMomentBallHeight { ground, low, lofted, unknown }

enum MatchMomentOutcome { goal, saved, turnover, retained }

enum MatchMomentReviewCue {
  receiveInside,
  receiveWide,
  receiveCheck,
  touchInside,
  touchLine,
  touchSet,
  williamsGoal,
  williamsSaved,
  williamsIntercepted,
  morataRetained,
  carrySaved,
  carryTurnover,
}

class MatchMomentPlayerDefinition {
  final String id;
  final MatchMomentTeam team;
  final int number;
  final MatchMomentPlayerName name;
  final bool goalkeeper;
  final bool essential;
  final bool subdued;

  const MatchMomentPlayerDefinition({
    required this.id,
    required this.team,
    required this.number,
    required this.name,
    this.goalkeeper = false,
    this.essential = false,
    this.subdued = false,
  });
}

class MatchMomentActorState {
  final ScanPassPoint position;
  final double facingRadians;

  const MatchMomentActorState({
    required this.position,
    this.facingRadians = 0,
  });

  MatchMomentActorState lerp(MatchMomentActorState other, double t) =>
      MatchMomentActorState(
        position: position.lerp(other.position, t),
        facingRadians: facingRadians +
            _angleDelta(other.facingRadians, facingRadians) *
                t.clamp(0.0, 1.0).toDouble(),
      );
}

class MatchMomentFrame {
  final Map<String, MatchMomentActorState> actors;
  final ScanPassPoint ball;
  final String? carrierId;
  final double elapsed;
  final MatchMomentOutcome? outcome;

  const MatchMomentFrame({
    required this.actors,
    required this.ball,
    required this.carrierId,
    this.elapsed = 0,
    this.outcome,
  });

  MatchMomentActorState actor(String id) => actors[id]!;

  MatchMomentFrame copyWith({
    Map<String, MatchMomentActorState>? actors,
    ScanPassPoint? ball,
    String? carrierId,
    bool clearCarrier = false,
    double? elapsed,
    MatchMomentOutcome? outcome,
  }) =>
      MatchMomentFrame(
        actors: Map.unmodifiable(actors ?? this.actors),
        ball: ball ?? this.ball,
        carrierId: clearCarrier ? null : carrierId ?? this.carrierId,
        elapsed: elapsed ?? this.elapsed,
        outcome: outcome ?? this.outcome,
      );
}

class MatchMomentChoice {
  final MatchMomentChoiceId id;
  final MatchMomentBeat beat;
  final String actorId;
  final String? receiverId;
  final ScanPassPoint target;
  final bool playerRing;

  const MatchMomentChoice({
    required this.id,
    required this.beat,
    required this.actorId,
    required this.target,
    this.receiverId,
    this.playerRing = false,
  });
}

class MatchMomentSegment {
  final MatchMomentFrame before;
  final MatchMomentFrame after;
  final MatchMomentActionKind kind;
  final String actorId;
  final String? receiverId;
  final MatchMomentChoiceId? choiceId;
  final double duration;
  final List<ScanPassPoint> ballGroundWaypoints;
  final MatchMomentBallHeight ballHeight;
  final MatchMomentReviewCue cue;

  const MatchMomentSegment({
    required this.before,
    required this.after,
    required this.kind,
    required this.actorId,
    required this.duration,
    required this.cue,
    this.receiverId,
    this.choiceId,
    this.ballGroundWaypoints = const <ScanPassPoint>[],
    this.ballHeight = MatchMomentBallHeight.ground,
  });

  List<ScanPassPoint> get ballGroundPath => List.unmodifiable(
        <ScanPassPoint>[
          before.ball,
          ...ballGroundWaypoints,
          after.ball,
        ],
      );

  double get groundDistanceMetres =>
      MatchMomentEpisode.groundPathMetres(ballGroundPath);

  ScanPassPoint ballPointAt(double progress) {
    final t = progress.clamp(0.0, 1.0).toDouble();
    final path = ballGroundPath;
    final total = MatchMomentEpisode.groundPathMetres(path);
    if (total < .001) return after.ball;
    var remaining = total * t;
    for (var index = 1; index < path.length; index += 1) {
      final start = path[index - 1];
      final end = path[index];
      final length = MatchMomentEpisode.groundMetres(start, end);
      if (length < .001) continue;
      if (remaining <= length) {
        return start.lerp(end, remaining / length);
      }
      remaining -= length;
    }
    return path.last;
  }

  List<ScanPassPoint> sampleBallPath({
    int count = 17,
    double progress = 1,
  }) {
    final resolvedCount = math.max(2, count);
    final end = progress.clamp(0.0, 1.0).toDouble();
    return List.unmodifiable([
      for (var index = 0; index < resolvedCount; index += 1)
        ballPointAt(end * index / (resolvedCount - 1)),
    ]);
  }

  MatchMomentFrame frame(double progress) {
    final t = progress.clamp(0.0, 1.0).toDouble();
    final nextActors = <String, MatchMomentActorState>{};
    for (final entry in before.actors.entries) {
      final next = after.actors[entry.key] ?? entry.value;
      nextActors[entry.key] = entry.value.lerp(next, t);
    }
    final carrier = t <= 0
        ? before.carrierId
        : switch (kind) {
            MatchMomentActionKind.receivePass ||
            MatchMomentActionKind.pass ||
            MatchMomentActionKind.shot =>
              t >= 1 ? after.carrierId : null,
            _ => t >= 1 ? after.carrierId : before.carrierId,
          };
    return MatchMomentFrame(
      actors: Map.unmodifiable(nextActors),
      ball: _ballPoint(t),
      carrierId: carrier,
      elapsed: before.elapsed + duration * t,
      outcome: t >= 1 ? after.outcome : before.outcome,
    );
  }

  List<MatchMomentFrame> samples({int count = 9}) => List.unmodifiable([
        for (var index = 0; index < count; index += 1)
          frame(count <= 1 ? 1 : index / (count - 1)),
      ]);

  ScanPassPoint _ballPoint(double t) => ballPointAt(t);
}

class MatchMomentBranch {
  final MatchMomentFrame before;
  final MatchMomentFrame after;
  final List<MatchMomentSegment> segments;
  final MatchMomentReviewCue cue;

  const MatchMomentBranch({
    required this.before,
    required this.after,
    required this.segments,
    required this.cue,
  });
}

class MatchMomentAttempt {
  final List<MatchMomentChoiceId> choices;
  final List<MatchMomentSegment> segments;
  final Map<MatchMomentBeat, MatchMomentFrame> decisionFrames;
  final MatchMomentOutcome outcome;
  final List<MatchMomentReviewCue> reviewCues;
  final bool reference;

  const MatchMomentAttempt({
    required this.choices,
    required this.segments,
    required this.decisionFrames,
    required this.outcome,
    required this.reviewCues,
    this.reference = false,
  });

  MatchMomentFrame get finalFrame => segments.last.after;

  bool get followsHistoricalLine =>
      choices.length == 3 &&
      choices[0] == MatchMomentChoiceId.receiveInside &&
      choices[1] == MatchMomentChoiceId.touchInside &&
      choices[2] == MatchMomentChoiceId.passWilliams;

  MatchMomentFrame frameBefore(MatchMomentBeat beat) => decisionFrames[beat]!;
}

class MatchMomentEpisode {
  static const double fieldLengthMetres = 105;
  static const double fieldWidthMetres = 68;
  static const String id = 'yamal-euro-2024-final-assist';
  static const String spain2 = 'esp-2-carvajal';
  static const String spain3 = 'esp-3-le-normand';
  static const String spain7 = 'esp-7-morata';
  static const String spain8 = 'esp-8-ruiz';
  static const String spain10 = 'esp-10-olmo';
  static const String spain14 = 'esp-14-laporte';
  static const String spain17 = 'esp-17-williams';
  static const String spain18 = 'esp-18-zubimendi';
  static const String spain19 = 'esp-19-yamal';
  static const String spain23 = 'esp-23-unai-simon';
  static const String spain24 = 'esp-24-cucurella';
  static const String england1 = 'eng-1-pickford';
  static const String england2 = 'eng-2-walker';
  static const String england3 = 'eng-3-shaw';
  static const String england4 = 'eng-4-rice';
  static const String england5 = 'eng-5-stones';
  static const String england6 = 'eng-6-guehi';
  static const String england7 = 'eng-7-saka';
  static const String england9 = 'eng-9-kane';
  static const String england10 = 'eng-10-bellingham';
  static const String england11 = 'eng-11-foden';
  static const String england26 = 'eng-26-mainoo';

  static const officialLineupUrl =
      'https://www.uefa.com/newsfiles/EURO/2024/2036211_LU.pdf';
  static const technicalReportUrl =
      'https://editorial.uefa.com/resources/028f-1b6f7f14a391-e1beafb781cc-1000/euro2024_mini-tech-report_v7.pdf';
  static const officialGoalPageUrl =
      'https://www.uefa.com/uefaeuro/history/video/028f-1b5e7b0b2ccd-cd78a924f1bd-1000--spain-vs-england-player-of-the-match-nico-williams/';
  static const officialYoutubeCompilationUrl =
      'https://www.youtube.com/watch?v=_UVK0h72UB0';
  static const officialEnglandHighlightsUrl =
      'https://www.youtube.com/watch?v=lBOS43RWfY0&t=110s';
  static const officialEnglandHighlightEmbedUrl =
      'https://www.youtube-nocookie.com/embed/lBOS43RWfY0?start=110&end=128&playsinline=1&rel=0';
  static const officialEnglandMatchCentreUrl =
      'https://www.englandfootball.com/england/mens-senior-team/fixtures-results/2023-24/EURO-2024/spain-england-uefa-euro-2024-final-sunday-14-july';
  static const matchRecordUrl =
      'https://www.uefa.com/uefaeuro/history/news/028f-1b5e5c2b7b67-d5faab9be20b-1000--spain-2-1-england-late-oyarzabal-winner-earns-la-roja-reco/';

  const MatchMomentEpisode();

  bool get referenceHasVerifiedBodyFeint => false;

  List<MatchMomentPlayerDefinition> get roster => const [
        MatchMomentPlayerDefinition(
          id: spain23,
          team: MatchMomentTeam.spain,
          number: 23,
          name: MatchMomentPlayerName.unaiSimon,
          goalkeeper: true,
          subdued: true,
        ),
        MatchMomentPlayerDefinition(
          id: spain2,
          team: MatchMomentTeam.spain,
          number: 2,
          name: MatchMomentPlayerName.daniCarvajal,
          essential: true,
        ),
        MatchMomentPlayerDefinition(
          id: spain3,
          team: MatchMomentTeam.spain,
          number: 3,
          name: MatchMomentPlayerName.robinLeNormand,
          subdued: true,
        ),
        MatchMomentPlayerDefinition(
          id: spain7,
          team: MatchMomentTeam.spain,
          number: 7,
          name: MatchMomentPlayerName.alvaroMorata,
          essential: true,
        ),
        MatchMomentPlayerDefinition(
          id: spain8,
          team: MatchMomentTeam.spain,
          number: 8,
          name: MatchMomentPlayerName.fabianRuiz,
        ),
        MatchMomentPlayerDefinition(
          id: spain10,
          team: MatchMomentTeam.spain,
          number: 10,
          name: MatchMomentPlayerName.daniOlmo,
          essential: true,
        ),
        MatchMomentPlayerDefinition(
          id: spain14,
          team: MatchMomentTeam.spain,
          number: 14,
          name: MatchMomentPlayerName.aymericLaporte,
          subdued: true,
        ),
        MatchMomentPlayerDefinition(
          id: spain17,
          team: MatchMomentTeam.spain,
          number: 17,
          name: MatchMomentPlayerName.nicoWilliams,
          essential: true,
        ),
        MatchMomentPlayerDefinition(
          id: spain18,
          team: MatchMomentTeam.spain,
          number: 18,
          name: MatchMomentPlayerName.martinZubimendi,
        ),
        MatchMomentPlayerDefinition(
          id: spain19,
          team: MatchMomentTeam.spain,
          number: 19,
          name: MatchMomentPlayerName.lamineYamal,
          essential: true,
        ),
        MatchMomentPlayerDefinition(
          id: spain24,
          team: MatchMomentTeam.spain,
          number: 24,
          name: MatchMomentPlayerName.marcCucurella,
        ),
        MatchMomentPlayerDefinition(
          id: england1,
          team: MatchMomentTeam.england,
          number: 1,
          name: MatchMomentPlayerName.jordanPickford,
          goalkeeper: true,
          essential: true,
        ),
        MatchMomentPlayerDefinition(
          id: england2,
          team: MatchMomentTeam.england,
          number: 2,
          name: MatchMomentPlayerName.kyleWalker,
          essential: true,
        ),
        MatchMomentPlayerDefinition(
          id: england3,
          team: MatchMomentTeam.england,
          number: 3,
          name: MatchMomentPlayerName.lukeShaw,
          essential: true,
        ),
        MatchMomentPlayerDefinition(
          id: england4,
          team: MatchMomentTeam.england,
          number: 4,
          name: MatchMomentPlayerName.declanRice,
        ),
        MatchMomentPlayerDefinition(
          id: england5,
          team: MatchMomentTeam.england,
          number: 5,
          name: MatchMomentPlayerName.johnStones,
          essential: true,
        ),
        MatchMomentPlayerDefinition(
          id: england6,
          team: MatchMomentTeam.england,
          number: 6,
          name: MatchMomentPlayerName.marcGuehi,
          essential: true,
        ),
        MatchMomentPlayerDefinition(
          id: england7,
          team: MatchMomentTeam.england,
          number: 7,
          name: MatchMomentPlayerName.bukayoSaka,
          subdued: true,
        ),
        MatchMomentPlayerDefinition(
          id: england9,
          team: MatchMomentTeam.england,
          number: 9,
          name: MatchMomentPlayerName.harryKane,
          subdued: true,
        ),
        MatchMomentPlayerDefinition(
          id: england10,
          team: MatchMomentTeam.england,
          number: 10,
          name: MatchMomentPlayerName.judeBellingham,
        ),
        MatchMomentPlayerDefinition(
          id: england11,
          team: MatchMomentTeam.england,
          number: 11,
          name: MatchMomentPlayerName.philFoden,
          subdued: true,
        ),
        MatchMomentPlayerDefinition(
          id: england26,
          team: MatchMomentTeam.england,
          number: 26,
          name: MatchMomentPlayerName.kobbieMainoo,
        ),
      ];

  MatchMomentFrame get initialFrame => MatchMomentFrame(
        actors: Map.unmodifiable(_states({
          spain23: _sourcePoint(.02, .50),
          spain14: _sourcePoint(.12, .63),
          spain3: _sourcePoint(.14, .42),
          spain2: _sourcePoint(.22, .30),
          spain8: _sourcePoint(.18, .52),
          spain18: _sourcePoint(.29, .59),
          spain24: _sourcePoint(.48, .79),
          spain19: _sourcePoint(.33, .31),
          spain10: _sourcePoint(.56, .45),
          spain7: _sourcePoint(.65, .52),
          spain17: _sourcePoint(.56, .73),
          england1: _sourcePoint(.93, .50),
          england2: _sourcePoint(.76, .70),
          england3: _sourcePoint(.43, .29),
          england4: _sourcePoint(.53, .50),
          england5: _sourcePoint(.70, .47),
          england6: _sourcePoint(.66, .60),
          england7: _sourcePoint(.35, .22),
          england9: _sourcePoint(.50, .57),
          england10: _sourcePoint(.39, .55),
          england11: _sourcePoint(.42, .42),
          england26: _sourcePoint(.48, .63),
        })),
        ball: _sourcePoint(.18, .52),
        carrierId: spain8,
      );

  MatchMomentSegment get leadIn {
    final before = initialFrame;
    final after = _frame(
      before,
      elapsed: 1.05,
      updates: {
        spain2: _sourcePoint(.26, .31),
        spain8: _sourcePoint(.19, .52),
        spain18: _sourcePoint(.31, .60),
        spain19: _sourcePoint(.35, .31),
        spain10: _sourcePoint(.58, .44),
        spain7: _sourcePoint(.66, .50),
        spain17: _sourcePoint(.57, .74),
        england3: _sourcePoint(.45, .30),
        england10: _sourcePoint(.41, .55),
        england4: _sourcePoint(.54, .50),
        england5: _sourcePoint(.70, .48),
        england6: _sourcePoint(.66, .60),
        england2: _sourcePoint(.76, .70),
      },
      ball: _sourcePoint(.26, .31),
      carrierId: spain2,
    );
    return MatchMomentSegment(
      before: before,
      after: after,
      kind: MatchMomentActionKind.pass,
      actorId: spain8,
      receiverId: spain2,
      duration: 1.05,
      ballHeight: MatchMomentBallHeight.unknown,
      cue: MatchMomentReviewCue.receiveInside,
    );
  }

  MatchMomentFrame get decisionStart => leadIn.after;

  MatchMomentAttempt get historicalAttempt => buildAttempt(const [
        MatchMomentChoiceId.receiveInside,
        MatchMomentChoiceId.touchInside,
        MatchMomentChoiceId.passWilliams,
      ], reference: true);

  List<MatchMomentChoice> choicesFor(
    MatchMomentBeat beat,
    MatchMomentFrame frame,
  ) {
    return switch (beat) {
      MatchMomentBeat.receive => [
          MatchMomentChoice(
            id: MatchMomentChoiceId.receiveInside,
            beat: MatchMomentBeat.receive,
            actorId: spain19,
            target: _sourcePoint(.43, .36),
          ),
          MatchMomentChoice(
            id: MatchMomentChoiceId.receiveWide,
            beat: MatchMomentBeat.receive,
            actorId: spain19,
            target: _sourcePoint(.40, .25),
          ),
          MatchMomentChoice(
            id: MatchMomentChoiceId.receiveCheck,
            beat: MatchMomentBeat.receive,
            actorId: spain19,
            target: _sourcePoint(.35, .42),
          ),
        ],
      MatchMomentBeat.firstTouch => [
          MatchMomentChoice(
            id: MatchMomentChoiceId.touchInside,
            beat: MatchMomentBeat.firstTouch,
            actorId: spain19,
            target: _touchTarget(frame, const ScanPassPoint(.018, .012)),
          ),
          MatchMomentChoice(
            id: MatchMomentChoiceId.touchLine,
            beat: MatchMomentBeat.firstTouch,
            actorId: spain19,
            target: _touchTarget(frame, const ScanPassPoint(.018, -.012)),
          ),
          MatchMomentChoice(
            id: MatchMomentChoiceId.touchSet,
            beat: MatchMomentBeat.firstTouch,
            actorId: spain19,
            target: _retreatTouchTarget(frame),
          ),
        ],
      MatchMomentBeat.nextAction => [
          MatchMomentChoice(
            id: MatchMomentChoiceId.passWilliams,
            beat: MatchMomentBeat.nextAction,
            actorId: spain19,
            receiverId: spain17,
            target: frame.actor(spain17).position,
            playerRing: true,
          ),
          MatchMomentChoice(
            id: MatchMomentChoiceId.passMorata,
            beat: MatchMomentBeat.nextAction,
            actorId: spain19,
            receiverId: spain7,
            target: frame.actor(spain7).position,
            playerRing: true,
          ),
          MatchMomentChoice(
            id: MatchMomentChoiceId.carryInside,
            beat: MatchMomentBeat.nextAction,
            actorId: spain19,
            target: _touchTarget(frame, const ScanPassPoint(.12, .03)),
          ),
        ],
    };
  }

  MatchMomentAttempt buildAttempt(
    List<MatchMomentChoiceId> choices, {
    bool reference = false,
  }) {
    if (choices.length != 3) {
      throw ArgumentError('A complete match attempt requires three choices.');
    }
    var state = decisionStart;
    final decisionFrames = <MatchMomentBeat, MatchMomentFrame>{
      MatchMomentBeat.receive: state,
    };
    final segments = <MatchMomentSegment>[];
    final cues = <MatchMomentReviewCue>[];

    final receive = applyChoice(
      state,
      const <MatchMomentChoiceId>[],
      choices[0],
    );
    segments.addAll(receive.segments);
    cues.add(receive.cue);
    state = receive.after;
    decisionFrames[MatchMomentBeat.firstTouch] = state;

    final touch = applyChoice(
      state,
      choices.take(1).toList(growable: false),
      choices[1],
    );
    segments.addAll(touch.segments);
    cues.add(touch.cue);
    state = touch.after;
    decisionFrames[MatchMomentBeat.nextAction] = state;

    final next = applyChoice(
      state,
      choices.take(2).toList(growable: false),
      choices[2],
    );
    segments.addAll(next.segments);
    cues.add(next.cue);
    state = next.after;
    return MatchMomentAttempt(
      choices: List.unmodifiable(choices),
      segments: List.unmodifiable(segments),
      decisionFrames: Map.unmodifiable(decisionFrames),
      outcome: state.outcome!,
      reviewCues: List.unmodifiable(cues),
      reference: reference,
    );
  }

  MatchMomentBranch applyChoice(
    MatchMomentFrame before,
    List<MatchMomentChoiceId> priorChoices,
    MatchMomentChoiceId choice,
  ) {
    final branch = switch (choice) {
      MatchMomentChoiceId.receiveInside => _receiveBranch(
          before,
          choice,
          yamalTarget: _sourcePoint(.43, .36),
          shawTarget: _sourcePoint(.48, .34),
          riceTarget: _sourcePoint(.55, .49),
          williamsTarget: _sourcePoint(.58, .74),
          cue: MatchMomentReviewCue.receiveInside,
        ),
      MatchMomentChoiceId.receiveWide => _receiveBranch(
          before,
          choice,
          yamalTarget: _sourcePoint(.40, .25),
          shawTarget: _sourcePoint(.43, .25),
          riceTarget: _sourcePoint(.54, .47),
          williamsTarget: _sourcePoint(.57, .73),
          cue: MatchMomentReviewCue.receiveWide,
        ),
      MatchMomentChoiceId.receiveCheck => _receiveBranch(
          before,
          choice,
          yamalTarget: _sourcePoint(.35, .42),
          shawTarget: _sourcePoint(.40, .38),
          riceTarget: _sourcePoint(.49, .48),
          williamsTarget: _sourcePoint(.57, .73),
          cue: MatchMomentReviewCue.receiveCheck,
        ),
      MatchMomentChoiceId.touchInside => _touchBranch(
          before,
          choice,
          target: _touchTarget(before, const ScanPassPoint(.018, .012)),
          shawTarget: _shift(before, england3, const ScanPassPoint(.018, .016)),
          riceTarget:
              _shift(before, england4, const ScanPassPoint(.018, -.004)),
          stonesTarget:
              _shift(before, england5, const ScanPassPoint(.005, -.010)),
          williamsTarget:
              _shift(before, spain17, const ScanPassPoint(.018, .00)),
          cue: MatchMomentReviewCue.touchInside,
        ),
      MatchMomentChoiceId.touchLine => _touchBranch(
          before,
          choice,
          target: _touchTarget(before, const ScanPassPoint(.018, -.012)),
          shawTarget:
              _shift(before, england3, const ScanPassPoint(.024, -.014)),
          riceTarget:
              _shift(before, england4, const ScanPassPoint(.018, -.010)),
          stonesTarget:
              _shift(before, england5, const ScanPassPoint(.005, -.004)),
          williamsTarget:
              _shift(before, spain17, const ScanPassPoint(.014, -.006)),
          cue: MatchMomentReviewCue.touchLine,
        ),
      MatchMomentChoiceId.touchSet => _touchBranch(
          before,
          choice,
          target: _retreatTouchTarget(before),
          shawTarget: _shift(before, england3, const ScanPassPoint(.014, .018)),
          riceTarget:
              _shift(before, england4, const ScanPassPoint(-.006, .010)),
          stonesTarget:
              _shift(before, england5, const ScanPassPoint(-.01, .00)),
          williamsTarget:
              _shift(before, spain17, const ScanPassPoint(.010, .00)),
          cue: MatchMomentReviewCue.touchSet,
        ),
      MatchMomentChoiceId.passWilliams =>
        _passWilliamsBranch(before, priorChoices),
      MatchMomentChoiceId.passMorata => _passMorataBranch(before),
      MatchMomentChoiceId.carryInside => _carryBranch(before, priorChoices),
    };
    return _timeBranch(branch);
  }

  // Authored alternatives share the same metre scale and plausible movement
  // bounds. Retiming also keeps replay clocks continuous at every segment join.
  MatchMomentBranch _timeBranch(MatchMomentBranch branch) {
    var cursor = branch.before;
    final segments = <MatchMomentSegment>[];
    for (final segment in branch.segments) {
      var duration = segment.duration;
      for (final entry in cursor.actors.entries) {
        duration = math.max(
            duration,
            _metres(entry.value.position,
                    segment.after.actor(entry.key).position) /
                8.5);
      }
      final ballDistance = groundPathMetres(
        <ScanPassPoint>[
          cursor.ball,
          ...segment.ballGroundWaypoints,
          segment.after.ball,
        ],
      );
      duration = math.max(duration, ballDistance / 28);
      final after = segment.after.copyWith(elapsed: cursor.elapsed + duration);
      segments.add(MatchMomentSegment(
        before: cursor,
        after: after,
        kind: segment.kind,
        actorId: segment.actorId,
        receiverId: segment.receiverId,
        choiceId: segment.choiceId,
        duration: duration,
        ballGroundWaypoints: segment.ballGroundWaypoints,
        ballHeight: segment.ballHeight,
        cue: segment.cue,
      ));
      cursor = after;
    }
    return MatchMomentBranch(
      before: branch.before,
      after: cursor,
      cue: branch.cue,
      segments: List.unmodifiable(segments),
    );
  }

  static double groundMetres(ScanPassPoint a, ScanPassPoint b) {
    final dx = (b.x - a.x) * fieldLengthMetres;
    final dy = (b.y - a.y) * fieldWidthMetres;
    return math.sqrt(dx * dx + dy * dy);
  }

  static double groundPathMetres(List<ScanPassPoint> path) {
    var total = 0.0;
    for (var index = 1; index < path.length; index += 1) {
      total += groundMetres(path[index - 1], path[index]);
    }
    return total;
  }

  static double _metres(ScanPassPoint a, ScanPassPoint b) => groundMetres(a, b);

  static ScanPassPoint _sourcePoint(double x, double y) =>
      ScanPassPoint(_sourceX(x), y);

  static double _sourceX(double x) {
    if (x < .22) return x * (.36 + .22 * .64) / .22;
    return x >= .99 ? x : .36 + x * .64;
  }

  MatchMomentBranch _receiveBranch(
    MatchMomentFrame before,
    MatchMomentChoiceId choice, {
    required ScanPassPoint yamalTarget,
    required ScanPassPoint shawTarget,
    required ScanPassPoint riceTarget,
    required ScanPassPoint williamsTarget,
    required MatchMomentReviewCue cue,
  }) {
    final after = _frame(
      before,
      elapsed: before.elapsed + .90,
      updates: {
        spain19: yamalTarget,
        spain17: williamsTarget,
        spain10: _sourcePoint(.60, .43),
        spain7: _sourcePoint(.67, .50),
        england3: shawTarget,
        england4: riceTarget,
        england10: _sourcePoint(.43, .55),
        england5: _sourcePoint(.71, .47),
        england6: _sourcePoint(.66, .59),
        england2: _sourcePoint(.75, .70),
      },
      ball: yamalTarget,
      carrierId: spain19,
    );
    return MatchMomentBranch(
      before: before,
      after: after,
      cue: cue,
      segments: [
        MatchMomentSegment(
          before: before,
          after: after,
          kind: MatchMomentActionKind.receivePass,
          actorId: spain2,
          receiverId: spain19,
          choiceId: choice,
          duration: .90,
          ballHeight: MatchMomentBallHeight.unknown,
          cue: cue,
        ),
      ],
    );
  }

  MatchMomentBranch _touchBranch(
    MatchMomentFrame before,
    MatchMomentChoiceId choice, {
    required ScanPassPoint target,
    required ScanPassPoint shawTarget,
    required ScanPassPoint riceTarget,
    required ScanPassPoint stonesTarget,
    required ScanPassPoint williamsTarget,
    required MatchMomentReviewCue cue,
  }) {
    final after = _frame(
      before,
      elapsed: before.elapsed + .52,
      updates: {
        spain19: target,
        spain17: williamsTarget,
        spain10: _shift(before, spain10, const ScanPassPoint(.04, -.02)),
        spain7: _shift(before, spain7, const ScanPassPoint(.03, .00)),
        england3: shawTarget,
        england4: riceTarget,
        england5: stonesTarget,
        england6: _shift(before, england6, const ScanPassPoint(.02, .02)),
        england2: _shift(before, england2, const ScanPassPoint(.00, -.03)),
        england1: _shift(before, england1, const ScanPassPoint(.00, .00)),
      },
      ball: target,
      carrierId: spain19,
    );
    return MatchMomentBranch(
      before: before,
      after: after,
      cue: cue,
      segments: [
        MatchMomentSegment(
          before: before,
          after: after,
          kind: MatchMomentActionKind.firstTouch,
          actorId: spain19,
          choiceId: choice,
          duration: .52,
          cue: cue,
        ),
      ],
    );
  }

  MatchMomentBranch _passWilliamsBranch(
    MatchMomentFrame before,
    List<MatchMomentChoiceId> priorChoices,
  ) {
    final historical = priorChoices.length >= 2 &&
        priorChoices[0] == MatchMomentChoiceId.receiveInside &&
        priorChoices[1] == MatchMomentChoiceId.touchInside;
    final stalled = priorChoices.contains(MatchMomentChoiceId.touchSet) ||
        priorChoices.contains(MatchMomentChoiceId.receiveCheck);
    if (stalled) {
      return _williamsIntercepted(before);
    }
    if (!historical) {
      return _williamsSaved(before);
    }
    return _williamsGoal(before);
  }

  MatchMomentBranch _williamsGoal(MatchMomentFrame before) {
    final carryPoint = _sourcePoint(.66, .44);
    final carryAfter = _frame(
      before,
      elapsed: before.elapsed + 3.05,
      updates: {
        spain19: carryPoint,
        spain17: _sourcePoint(.74, .68),
        spain7: _sourcePoint(.81, .53),
        spain10: _sourcePoint(.78, .40),
        england3: _sourcePoint(.60, .39),
        england4: _sourcePoint(.63, .50),
        england5: _sourcePoint(.80, .42),
        england6: _sourcePoint(.81, .51),
        england2: _sourcePoint(.79, .63),
        england1: _sourcePoint(.91, .51),
      },
      ball: carryPoint,
      carrierId: spain19,
    );
    final receive = _sourcePoint(.82, .66);
    final passAfter = _frame(
      carryAfter,
      elapsed: carryAfter.elapsed + 1.45,
      updates: {
        spain17: receive,
        spain7: _sourcePoint(.84, .52),
        spain10: _sourcePoint(.81, .40),
        england2: _sourcePoint(.84, .63),
        england5: _sourcePoint(.84, .43),
        england6: _sourcePoint(.84, .52),
        england1: _sourcePoint(.92, .51),
      },
      ball: receive,
      carrierId: spain17,
    );
    const finish = ScanPassPoint(1.025, .47);
    final shotAfter = _frame(
      passAfter,
      elapsed: passAfter.elapsed + .72,
      updates: {
        spain17: _sourcePoint(.83, .66),
        england1: _sourcePoint(.93, .48),
        england2: _sourcePoint(.85, .64),
        england5: _sourcePoint(.85, .44),
      },
      ball: finish,
      carrierId: null,
      clearCarrier: true,
      outcome: MatchMomentOutcome.goal,
    );
    return MatchMomentBranch(
      before: before,
      after: shotAfter,
      cue: MatchMomentReviewCue.williamsGoal,
      segments: [
        MatchMomentSegment(
          before: before,
          after: carryAfter,
          kind: MatchMomentActionKind.carry,
          actorId: spain19,
          choiceId: MatchMomentChoiceId.passWilliams,
          duration: 3.05,
          cue: MatchMomentReviewCue.williamsGoal,
        ),
        MatchMomentSegment(
          before: carryAfter,
          after: passAfter,
          kind: MatchMomentActionKind.pass,
          actorId: spain19,
          receiverId: spain17,
          duration: 1.45,
          cue: MatchMomentReviewCue.williamsGoal,
        ),
        MatchMomentSegment(
          before: passAfter,
          after: shotAfter,
          kind: MatchMomentActionKind.shot,
          actorId: spain17,
          duration: .72,
          ballHeight: MatchMomentBallHeight.unknown,
          cue: MatchMomentReviewCue.williamsGoal,
        ),
      ],
    );
  }

  MatchMomentBranch _williamsSaved(MatchMomentFrame before) {
    final carryPoint = _sourcePoint(.56, .38);
    final carryAfter = _frame(
      before,
      elapsed: before.elapsed + 1.55,
      updates: {
        spain19: carryPoint,
        spain17: _sourcePoint(.69, .69),
        spain7: _sourcePoint(.70, .50),
        spain10: _sourcePoint(.66, .42),
        england3: _sourcePoint(.55, .34),
        england4: _sourcePoint(.60, .47),
        england5: _sourcePoint(.74, .48),
        england6: _sourcePoint(.70, .58),
        england2: _sourcePoint(.78, .67),
        england1: _sourcePoint(.91, .52),
      },
      ball: carryPoint,
      carrierId: spain19,
    );
    final receive = _sourcePoint(.80, .64);
    final passAfter = _frame(
      carryAfter,
      elapsed: carryAfter.elapsed + 1.35,
      updates: {
        spain17: receive,
        spain7: _sourcePoint(.72, .50),
        spain10: _sourcePoint(.68, .42),
        england2: _sourcePoint(.82, .64),
        england5: _sourcePoint(.76, .48),
        england6: _sourcePoint(.72, .58),
        england1: _sourcePoint(.92, .52),
      },
      ball: receive,
      carrierId: spain17,
    );
    final save = _sourcePoint(.95, .50);
    final shotAfter = _frame(
      passAfter,
      elapsed: passAfter.elapsed + .70,
      updates: {
        england1: _sourcePoint(.94, .50),
        england2: _sourcePoint(.84, .63),
        england5: _sourcePoint(.78, .48),
      },
      ball: save,
      carrierId: england1,
      outcome: MatchMomentOutcome.saved,
    );
    return MatchMomentBranch(
      before: before,
      after: shotAfter,
      cue: MatchMomentReviewCue.williamsSaved,
      segments: [
        MatchMomentSegment(
          before: before,
          after: carryAfter,
          kind: MatchMomentActionKind.carry,
          actorId: spain19,
          choiceId: MatchMomentChoiceId.passWilliams,
          duration: 1.55,
          cue: MatchMomentReviewCue.williamsSaved,
        ),
        MatchMomentSegment(
          before: carryAfter,
          after: passAfter,
          kind: MatchMomentActionKind.pass,
          actorId: spain19,
          receiverId: spain17,
          duration: 1.35,
          cue: MatchMomentReviewCue.williamsSaved,
        ),
        MatchMomentSegment(
          before: passAfter,
          after: shotAfter,
          kind: MatchMomentActionKind.shot,
          actorId: spain17,
          duration: .70,
          ballHeight: MatchMomentBallHeight.unknown,
          cue: MatchMomentReviewCue.williamsSaved,
        ),
      ],
    );
  }

  MatchMomentBranch _williamsIntercepted(MatchMomentFrame before) {
    final carryPoint = _sourcePoint(.49, .43);
    final carryAfter = _frame(
      before,
      elapsed: before.elapsed + 1.10,
      updates: {
        spain19: carryPoint,
        spain17: _shift(before, spain17, const ScanPassPoint(.04, .00)),
        england3: _shift(before, england3, const ScanPassPoint(.04, .03)),
        england4: _shift(before, england4, const ScanPassPoint(.04, .00)),
        england5: _shift(before, england5, const ScanPassPoint(.01, .00)),
      },
      ball: carryPoint,
      carrierId: spain19,
    );
    final intended = _shift(carryAfter, spain17, const ScanPassPoint(.02, .00));
    final direction = intended - carryAfter.ball;
    final defenderOffset =
        carryAfter.actor(england4).position - carryAfter.ball;
    final squaredLength =
        math.pow(direction.x * 105, 2) + math.pow(direction.y * 68, 2);
    final projection = ((defenderOffset.x * direction.x * 105 * 105 +
                defenderOffset.y * direction.y * 68 * 68) /
            squaredLength)
        .clamp(.25, .80)
        .toDouble();
    // The defender meets the intended pass line; the ball never bends toward
    // an interceptor simply because this authored alternative loses possession.
    final cut = carryAfter.ball.lerp(intended, projection);
    final after = _frame(
      carryAfter,
      elapsed: carryAfter.elapsed + .90,
      updates: {
        england4: cut,
        spain17: _shift(carryAfter, spain17, const ScanPassPoint(.02, .00)),
        england3: _shift(carryAfter, england3, const ScanPassPoint(.02, .02)),
        england5: _shift(carryAfter, england5, const ScanPassPoint(.01, .00)),
      },
      ball: cut,
      carrierId: england4,
      outcome: MatchMomentOutcome.turnover,
    );
    return MatchMomentBranch(
      before: before,
      after: after,
      cue: MatchMomentReviewCue.williamsIntercepted,
      segments: [
        MatchMomentSegment(
          before: before,
          after: carryAfter,
          kind: MatchMomentActionKind.carry,
          actorId: spain19,
          choiceId: MatchMomentChoiceId.passWilliams,
          duration: 1.10,
          cue: MatchMomentReviewCue.williamsIntercepted,
        ),
        MatchMomentSegment(
          before: carryAfter,
          after: after,
          kind: MatchMomentActionKind.pass,
          actorId: spain19,
          receiverId: spain17,
          duration: .90,
          cue: MatchMomentReviewCue.williamsIntercepted,
        ),
      ],
    );
  }

  MatchMomentBranch _passMorataBranch(MatchMomentFrame before) {
    final receive = _sourcePoint(.69, .50);
    final passAfter = _frame(
      before,
      elapsed: before.elapsed + .65,
      updates: {
        spain7: receive,
        spain10: _sourcePoint(.66, .42),
        spain17: _sourcePoint(.70, .74),
        england5: _sourcePoint(.72, .49),
        england6: _sourcePoint(.70, .58),
        england4: _sourcePoint(.61, .50),
      },
      ball: receive,
      carrierId: spain7,
    );
    final reset = _sourcePoint(.61, .42);
    final resetAfter = _frame(
      passAfter,
      elapsed: passAfter.elapsed + .60,
      updates: {
        spain10: reset,
        spain7: _sourcePoint(.70, .50),
        england5: _sourcePoint(.73, .49),
        england6: _sourcePoint(.70, .58),
        england4: _sourcePoint(.63, .49),
      },
      ball: reset,
      carrierId: spain10,
      outcome: MatchMomentOutcome.retained,
    );
    return MatchMomentBranch(
      before: before,
      after: resetAfter,
      cue: MatchMomentReviewCue.morataRetained,
      segments: [
        MatchMomentSegment(
          before: before,
          after: passAfter,
          kind: MatchMomentActionKind.pass,
          actorId: spain19,
          receiverId: spain7,
          choiceId: MatchMomentChoiceId.passMorata,
          duration: .65,
          cue: MatchMomentReviewCue.morataRetained,
        ),
        MatchMomentSegment(
          before: passAfter,
          after: resetAfter,
          kind: MatchMomentActionKind.pass,
          actorId: spain7,
          receiverId: spain10,
          duration: .60,
          cue: MatchMomentReviewCue.morataRetained,
        ),
      ],
    );
  }

  MatchMomentBranch _carryBranch(
    MatchMomentFrame before,
    List<MatchMomentChoiceId> priorChoices,
  ) {
    final strongCarry = priorChoices.length >= 2 &&
        priorChoices[0] == MatchMomentChoiceId.receiveInside &&
        priorChoices[1] == MatchMomentChoiceId.touchInside;
    final target = _touchTarget(before, const ScanPassPoint(.12, .03));
    final carryAfter = _frame(
      before,
      elapsed: before.elapsed + 1.45,
      updates: {
        spain19: target,
        england3: _shift(before, england3, const ScanPassPoint(.07, .04)),
        england4: _shift(before, england4, const ScanPassPoint(.05, .00)),
        england5: _shift(before, england5, const ScanPassPoint(.01, -.01)),
      },
      ball: target,
      carrierId: spain19,
    );
    if (strongCarry) {
      final save = _sourcePoint(.91, .49);
      final shotAfter = _frame(
        carryAfter,
        elapsed: carryAfter.elapsed + .65,
        updates: {
          england1: _sourcePoint(.90, .49),
          england5: _sourcePoint(.76, .47),
          england6: _sourcePoint(.72, .57),
        },
        ball: save,
        carrierId: england1,
        outcome: MatchMomentOutcome.saved,
      );
      return MatchMomentBranch(
        before: before,
        after: shotAfter,
        cue: MatchMomentReviewCue.carrySaved,
        segments: [
          MatchMomentSegment(
            before: before,
            after: carryAfter,
            kind: MatchMomentActionKind.carry,
            actorId: spain19,
            choiceId: MatchMomentChoiceId.carryInside,
            duration: 1.45,
            cue: MatchMomentReviewCue.carrySaved,
          ),
          MatchMomentSegment(
            before: carryAfter,
            after: shotAfter,
            kind: MatchMomentActionKind.shot,
            actorId: spain19,
            duration: .65,
            ballHeight: MatchMomentBallHeight.unknown,
            cue: MatchMomentReviewCue.carrySaved,
          ),
        ],
      );
    }
    final steal = target;
    final stealAfter = _frame(
      carryAfter,
      elapsed: carryAfter.elapsed + .38,
      updates: {
        england3: steal,
        spain19: target + const ScanPassPoint(.018, -.012),
      },
      ball: steal,
      carrierId: england3,
      outcome: MatchMomentOutcome.turnover,
    );
    return MatchMomentBranch(
      before: before,
      after: stealAfter,
      cue: MatchMomentReviewCue.carryTurnover,
      segments: [
        MatchMomentSegment(
          before: before,
          after: carryAfter,
          kind: MatchMomentActionKind.carry,
          actorId: spain19,
          choiceId: MatchMomentChoiceId.carryInside,
          duration: 1.45,
          cue: MatchMomentReviewCue.carryTurnover,
        ),
        MatchMomentSegment(
          before: carryAfter,
          after: stealAfter,
          kind: MatchMomentActionKind.carry,
          actorId: spain19,
          duration: .38,
          cue: MatchMomentReviewCue.carryTurnover,
        ),
      ],
    );
  }

  MatchMomentFrame _frame(
    MatchMomentFrame before, {
    required double elapsed,
    required Map<String, ScanPassPoint> updates,
    required ScanPassPoint ball,
    required String? carrierId,
    bool clearCarrier = false,
    MatchMomentOutcome? outcome,
  }) {
    final actors = Map<String, MatchMomentActorState>.of(before.actors);
    for (final entry in updates.entries) {
      actors[entry.key] = MatchMomentActorState(
        position: entry.value,
        facingRadians: _facing(
            before.actors[entry.key]?.position ?? entry.value, entry.value),
      );
    }
    return before.copyWith(
      actors: actors,
      ball: ball,
      carrierId: carrierId,
      clearCarrier: clearCarrier,
      elapsed: elapsed,
      outcome: outcome,
    );
  }

  static Map<String, MatchMomentActorState> _states(
    Map<String, ScanPassPoint> positions,
  ) =>
      {
        for (final entry in positions.entries)
          entry.key: MatchMomentActorState(
            position: entry.value,
            facingRadians: entry.key.startsWith('eng-') ? 3.14159 : 0,
          ),
      };

  static ScanPassPoint _touchTarget(
    MatchMomentFrame frame,
    ScanPassPoint offset,
  ) =>
      (frame.ball + offset)
          .clampToField(minX: .04, maxX: .98, minY: .08, maxY: .92);

  static ScanPassPoint _retreatTouchTarget(MatchMomentFrame frame) {
    final support = frame.actor(spain2).position;
    final distance = _metres(frame.ball, support);
    if (distance < .001) return frame.ball;
    final fraction = math.min(1.0, 1.5 / distance);
    return _touchTarget(
        frame,
        ScanPassPoint(
          (support.x - frame.ball.x) * fraction,
          (support.y - frame.ball.y) * fraction,
        ));
  }

  static ScanPassPoint _shift(
    MatchMomentFrame frame,
    String id,
    ScanPassPoint offset,
  ) =>
      (frame.actor(id).position + offset)
          .clampToField(minX: .02, maxX: .98, minY: .08, maxY: .92);
}

double _facing(ScanPassPoint from, ScanPassPoint to) {
  final delta = to - from;
  if (delta.distance < .001) return 0;
  return math.atan2(delta.y, delta.x);
}

double _angleDelta(double target, double current) {
  var delta = (target - current) % 6.283185307179586;
  if (delta > 3.141592653589793) delta -= 6.283185307179586;
  if (delta < -3.141592653589793) delta += 6.283185307179586;
  return delta;
}
