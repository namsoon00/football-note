# Scan Pass First-Touch Chain Model

Scan Pass opens on a 3v2 sequence in which the learner controls **the same number 6 throughout**. The core is a preplanned first touch, a deliberate next action, and movement without the ball to receive again. A completed pass is an intermediate event; it does not end the exercise or transfer control to the recipient. Two actual return receptions and their chosen touches complete a sequence. The previous goal and offside game remains available through the football button, **Free attack**.

## Continuous choices

1. **Plan the first touch before receiving.** Drag from number 6, tap the ground, or use the arrow keys to choose a direction and distance within three model metres. Confirm to request the incoming pass. The selected touch is executed at reception, including its exact direction and length. There is no automatic touch or receive-position/timing question.
2. **Read the changed situation and choose the next action.** Tap a teammate to prepare a pass to 4 or 8. Drag into space for a carry of up to four metres, or select Protect and choose a short turn of up to 1.5 metres. A separate button commits the choice. Carrying or shielding leads back to this decision with the same live geometry. Facing affects the time needed to turn before releasing a pass, while defenders continue moving.
3. **Offer a return.** After a successful pass, the teammate holds the ball and the learner personally chooses where number 6 runs, within seven metres. Defenders react to both players. A usable return needs separation and an open passing lane. The next reception is prepared at the reached position, without resetting or teleporting any player. The learner chooses the next first touch before the teammate sends the return.

The ball travels continuously. Defenders have finite reactive speeds, and committed touches, turns, carries, passes and runs have collision or pressure consequences. The model uses small deterministic substeps on a 30m by 20m pitch. These are instructional approximations rather than measurements of professional players. Nearby viable destinations are tested, so success does not depend on a single correct pixel. Seeded layouts vary the pressure direction and supporting geometry.

## Reading and interaction

The pitch keeps a stable 3:2 aspect ratio across desktop, phone and landscape layouts. Both teams use human uniform silhouettes, the ball has soccer-ball panels, and number 6 has a persistent learner label and blue halo. The possession ring follows the ball holder. A small triangle shows body direction and motion arrows show current velocity. A neutral gold arrow previews the learner's choice without exposing a safe/unsafe answer.

Decision stages pause the simulation. Committed movement plays at half speed with pause and single-step controls. Help, Free attack and backgrounding pause the sequence; resumption is explicit. There is no countdown, speed bonus or numeric skill score. Touch, mouse dragging and keyboard input share the same spatial model. The canvas excludes synthesized web semantic tap coordinates, and provides focus/arrow-key control plus accessible teammate buttons.

## Causal review

The review preserves actual trajectory frames and moment snapshots. It compares the learner's pressure and immediate passing lanes before and after each first touch, then lets the player inspect the next action and off-ball destination. Movement trails, moment controls and full-sequence replay explain what changed. A same-layout retry invites a different first touch; a new layout changes the situation. Review overlays appear only after the attempt.

No XP, gaze inference or persistent progression is recorded. Test results establish software behavior, not improvement in real match judgment. Transfer to play would require separate unfamiliar-scene and field evaluation.

Coverage includes manual preplanned touches, alternate touches under identical geometry, facing and release delay, pass/carry/protect choices, continued control after passing, return-lane consequences of the learner's own run, continuous return flights, two successive reconnections, nearby viable choices, seeded variation, lifecycle pauses, pointer and keyboard input, responsive controls and review playback. Real web checks include accessibility-enabled spatial input.

The earlier `SpaceTrainingScreen` and its engine remain for regression coverage but are no longer the default entry. Its receive-position/timing exercise is not part of the new chain.

## Earlier scenario lesson implementation

The earlier decision-learning widget is retained for regression coverage; it is no longer the default route. Its opening lesson starts with #4 passing into learner #6 while teammates and defenders move, then asks the learner to choose the next action after reading the cue before reception. The available decisions are forward pass to #8, wide pass to #7, return pass to #4, and forward carry.

The trainer uses three lesson families: rear pressure, passing lane, and receiver support. Each guided set contains six paired situations: the original cue and the changed cue for each family. The changed scene keeps unrelated actors in the same opening positions so the learner can compare cause and consequence rather than memorize one route.

Preview selection is intentionally neutral. Tapping a player or carry space draws an intended dotted route and enables execute, but it does not call assessment logic or reveal safe/unsafe verdicts. A choice and explicit execution can be prepared during the incoming pass. The UI calls `DecisionEngine.assess()` at reception or the later committed simulation time. It plays the returned action, first touch and possible follow-up, then freezes the receiving moment for a causal review. The qualitative outcome, one reason, pressure ring and next-outlet arrows describe that same receiving state. A completed pass can still leave a receiver isolated; a pressured receiver can be a useful wall player when a short, reachable outlet exists.

Reading modes:

- Read together: self-paced reception freeze with simple cue arrows.
- Read alone: self-paced scenes without cue arrows. Independent practice sets shuffle the six scene variants, so the round number does not reveal a fixed answer sequence.
- Moving pressure: after reception, the scenario evolves in active foreground simulation ticks via `decisionState(elapsed)`. Help, backgrounding and opening Free attack pause it; mode changes cancel the previous scene. The short practice window pauses after 2.8 simulation seconds if nothing is executed. This is an ungraded opportunity to watch again, not proof that every pass has become impossible. A selected but unexecuted action is distinguished from no selection. There is no automatic pass, countdown score or speed bonus.

Review comparisons animate from the original scenario and exactly the original decision delay. Viewing another choice does not replace or mutate the stored learner assessment or add a new learning record. A branch label remains visible throughout playback and review. The paths drawn during animation never run ahead of the current ball; the receiving freeze shows the learner action and reachable next outlets, rather than future completed passes.

The decision model samples moving defenders against the ball path. It checks pressure both at arrival and shortly afterwards, allows more time to turn for a receiver facing backwards, and restricts pressured one-touch outlets by distance, body direction, interception and the next receiver's space. Several choices may be useful. A carry can draw or evade a lane defender, while a return pass may keep possession. These are transparent teaching assumptions, not measured elite-player thresholds or validated probabilities.

Regression examples cover all mirrored/translated variants: carrying into rear pressure loses the ball while carrying with the same defender dropping away creates progression; the same forward pass is intercepted when the lane is covered and connects when the defender steps away; the same completed pass into a marked #8 creates a connection through nearby #10 but leaves #8 isolated when #10 moves out of immediate supporting range. Swapping scene labels without changing geometry does not change the assessment.

The previous continuous attack remains available from the Scan Pass app bar as Free attack. That mode still uses `AttackEngine`, keeps one possession moving across the same pitch, and retains the goal, keeper, offside, undo, and full replay behavior from the earlier version.

The current Scan Pass flows do not award XP, numeric skill scores or persistent challenge history. A local end-of-set review summarizes reasons from the learner's actual choices and is discarded with the screen. The screen is an instructional simulator, not a validated measurement of gaze, scanning habit, match skill, or improvement.

The main learning surface remains the pitch. Players use the same human uniform silhouette; #6 is the learner and the possession ring follows the actual ball carrier. A small chevron beside each outfield player shows body orientation. Defenders use warm colors, teammates use blue, the ball is rendered as a soccer ball, and the right-side goal and keeper stay visible. Observation, committed actions and comparison replays each supply the painter with the active transition, so the ball travels along its actual flight path instead of attaching to the passer during flight. A raster regression checks the white ball and black panels at the interpolated position for incoming and outgoing passes. The pitch keeps stable bounds through observation, choice, execution, and review so movement is not confused with layout changes.

The domain is an instructional approximation, not a full match model. Coordinates represent player positions, not body-part tracking. Player motion, pressure, passing lanes, receiver follow-up and goalkeeper behavior are deterministic teaching approximations. The retained free-attack offside explanation follows IFAB Law 11: offside is judged at the moment the ball is played, with the ball, halfway line, and second-last opponent including the goalkeeper all relevant. Throw-ins, corners, fouls, restarts and interference-with-an-opponent cases are not simulated. Rule reference: [IFAB Law 11](https://www.theifab.com/laws/latest/offside/).
