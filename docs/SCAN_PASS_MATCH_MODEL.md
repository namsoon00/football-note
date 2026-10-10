# Scan Pass Judgment Episode Model

Scan Pass now opens on a judgment-first episode trainer. The default surface shows a short moving football situation before number 6 receives, then pauses for a one-tap tactical decision. The learner chooses a contextual action on the pitch or through the equivalent large controls below the field; the action executes immediately. There is no mode picker, coordinate dragging, kick-power control, precision timing challenge, or separate confirmation button in the default flow.

The trainer keeps the mature football presentation used by the retained match screens: a wide pitch, human uniform silhouettes, a soccer ball, body-facing chevrons, rightward attacking direction, moving defenders, visible possession ring, and actual ball/player motion. The default experience is not a quiz card and does not show a green recommended route before the choice.

## Episode Flow

1. **Watch before receiving.** Number 4 plays into number 6 while teammates and defenders move. The observation is long enough to read pressure, passing lanes and support. The learner can replay the same observation before choosing.
2. **Choose one action.** At the receiving moment the model offers two to four neutral intentions, such as touch left, touch right, touch forward, shield, or one-touch return. A single tap immediately commits and animates the consequence.
3. **Continue only when the football state calls for it.** If the first touch keeps the ball alive, the next decision can be pass forward, pass wide, return pass, carry, or protect. If a pass creates a meaningful off-ball problem, the learner then chooses a support position for number 6. Episodes end after one to three decisions.
4. **Review cause and alternative.** Feedback shows the actual chosen sequence, highlights the relevant pressure/lane/support cue, and gives one localized causal sentence. Moment chips select the first touch, next action or support movement. “Compare another choice” replays an alternative from that moment’s identical decision state. Review-only cue highlights explain the outcome without identifying a preferred choice in advance. Replaying the lead-in after a first touch includes the completed actions and returns to the unchanged current decision. “Retry situation” restarts the same scene; “Continue” advances the ten-scene set.

Poor but legal choices still execute. They may keep possession under pressure, lose a passing lane, expose back-space, or be intercepted/offside where the authored situation makes that consequence relevant. The trainer never silently normalizes every branch to success and never auto-selects a best route.

## Catalog

`JudgmentEngine.catalog()` contains 24 base scenes: eight families with three authored configurations each. Mirroring and small seeded shifts may vary screen placement, but the three configurations per family are different causal situations, not jittered duplicates.

| Family | Three configuration themes |
| --- | --- |
| Rear pressure | close rear presser, dropping presser, curved rear press |
| Side pressure | pressure from upper side, pressure from lower side, side trap recovering inside |
| Open front / second defender | open carry lane, second defender stepping, lane screened while front appears open |
| Passing-lane defender | defender commits to the ball, defender screens forward lane, defender jumps the return lane |
| Receiver support / pressure | third-player support near the receiver, isolated receiver, wide underlap support |
| Numerical advantage | central overload, wide 2v1, spare player behind pressure |
| Post-pass support angle | inside return angle, flat covered angle, blind-side/wide support angle |
| Transition / back-space | secure reset under counter-pressure, back-space behind the ball, high-line/offside forward option |

A ten-scene session mixes families and configurations. If a missed condition loses possession or exposes a key cue, the final two slots can revisit that family in another valid configuration. The first eight slots retain all eight families, and retrying a scene replaces its record instead of adding an extra completed scene.

## Causal Rules

The model is deterministic. Player positions, velocities, simultaneous ball/defender movement, nearest defensive pressure, offside line and predicted next outlets determine the qualitative outcome. There is no preferred-action answer key: changing a family label without changing the geometry cannot change the assessment. Body orientation is drawn to explain motion; technical execution is automatic. Transitions use the same `AttackState` and `AttackTransition` infrastructure as the continuous attack view. The ball travels along the actual selected branch; defenders do not teleport between decisions.

First-touch actions move number 6, shield briefly, or return the ball. Next-action decisions evaluate pass interception/offside, forward carry pressure, and whether protecting possession leaves another action available. Support decisions move number 6 off the ball while the teammate holds possession, check pressure throughout that movement, and execute an actual return pass. The ball can be lost while support arrives or intercepted on the return. Different first touches can therefore leave different viable support routes later in the same episode.

Outcomes are qualitative: space gained, possession retained, next options preserved, or possession lost. The UI does not award XP, score speed, infer gaze, claim measured scanning skill, or promise real-world transfer.

## Controls and Accessibility

The pitch remains responsive across desktop, phone, small phone, and landscape layouts. In compact layouts the action dock wraps into stable two-column controls, while pitch targets remain distinct 48px semantic buttons. Targets use separated callouts with neutral guide lines, avoiding overlap with each other and player silhouettes on small screens. The pitch itself is rendered as an image; raw coordinate gesture handlers are not used for the default judgment choices, avoiding synthesized center-tap semantics.

Keyboard and screen-reader users receive the same decision set through the dock buttons. Replay, retry, compare alternative, continue, free attack and help are all reachable without scrolling excessively in the tested desktop and phone layouts.

## Retained Legacy Surfaces

The previous continuous attack remains available from the Scan Pass app bar as **Free attack**. That mode still uses `AttackEngine`, keeps one possession moving across the same pitch, and retains the goal, keeper, offside, undo, and full replay behavior from the earlier version.

`TouchChainTrainingScreen` remains available for regression coverage and optional legacy use. It still models the longer first-touch chain in which the learner controls the same number 6 through first touch, next action, and off-ball return movement with explicit commit controls. It is no longer the default Scan Pass entry.

The earlier `SpaceTrainingScreen` and its engine remain for regression coverage but are no longer the default entry. Its receive-position/timing exercise is not part of the new judgment episode trainer.

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
