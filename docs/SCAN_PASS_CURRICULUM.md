# Scan Pass: real-match decision lesson and retained 2v2 flow

## Current default

`ScanPassGameScreen` now opens the public Scan Pass quick action directly into a
real-match lesson: Lamine Yamal's assist to Nico Williams for Spain's opening
goal against England in the UEFA EURO 2024 final, Berlin, 14 July 2024, 47'.
There is no pre-game mode selector, timer, XP award, leaderboard or generic
attacker/defender setup. The old 2v2 flow remains available internally for tests
and compatibility, but it is no longer the public default.

The first episode is a three-beat authored decision sequence centered on Spain
19 Yamal:

1. Move to receive Dani Carvajal's pass.
2. Select the first touch from the resulting received state.
3. Choose the next pass or carry from that exact first-touch state.

Each beat is a single on-pitch tap on a visible target. The resulting player and
ball movement is sampled continuously, and the final review compares the
learner's complete branch with a separate 2D reconstruction of the historical
Carvajal -> Yamal -> Williams line. Matching the original play is not the only
useful outcome: alternatives can retain possession, produce a saved chance or
turn the ball over depending on the branch.

The lesson uses team-qualified player ids because Spain and England share shirt
numbers. The 47' roster follows the official UEFA lineup with Spain 18 Martin
Zubimendi on for Rodri after halftime, and no Oyarzabal or Merino on the field
yet. The rendered kits are code-drawn match-specific approximations: Spain red
shirts, yellow trim/numbers, blue shorts and red socks; England white outfield
kit with navy/red trim; Pickford in yellow. No downloaded photos, crests or
broadcast assets are bundled.

Source and limitation details are shown in the lesson's collapsible source
surface. The reconstruction is based on official lineup data, UEFA technical
analysis and official video/source pages, but available public footage does not
provide exact whole-pitch tracking. Positions, timings and alternative outcomes
are therefore an authored analytical simulation rather than measured tracking,
coach endorsement or a claim of real-life skill transfer. The official footage
links are external fallbacks, with a web-only user-started embed for the verified
official England highlights segment when the platform supports it.

The on-pitch visualization is a ground-plane teaching model using the declared
105 m x 68 m field scale. Playback, pause and step-through all read the same
segment frame for ball position, player positions, arrows and displayed
distances. Completed traces are subdued while the active action is drawn with a
heavier route: solid contact routes for first touch/carry, dashed ball
trajectories for passes, a shot route and separate off-ball/pressure runs for
Spain and England. Pass distance labels are approximate reconstruction values
derived from the sampled ground path, for example `#2 -> #19 · ground path
approx 12 m · height unknown` or `#19 -> #17 · ground path approx 17 m · ground
ball`; they are not measured broadcast distances. A
ground-path waypoint, when present, is only a 2D lateral waypoint and never an
elevation value. The Yamal-to-Williams pass is marked as a ground ball; the
Carvajal-to-Yamal release and shots use an unknown/height-not-confirmed category
because the public stills do not support exact elevation. The body-facing arrow
is schematic and separate from the ball/player route arrow. The official sources
support Ruiz feeding Carvajal, Carvajal's first-time outside-foot release,
Yamal's direction change/carry, Morata and Olmo occupying centre-backs, and
Williams' far-side finish, but no named or verified body feint is marked.

The receiving decision teaches reading Shaw's outside pressure and the inside
receiving lane. The first-touch decision isolates a short contact with the ball
from the later carry: its exact endpoint stays on the pitch while separated
callouts show the movement direction. The final decision contrasts the diagonal
carry and switch to Williams with a central possession option or a direct carry
and shot. Feedback names the actual receiver, shooter or interceptor in the
selected branch; retaining possession is not described as a wrong answer.

The active action's full intended route remains visible when paused at its
start, with completed travel emphasized as it plays. Action numbers on the
route and playback controls agree. Instructions and controls occupy reserved
layout space above the pitch, so neither can cover a player or the goal.
The compact height profile is categorical: a ground baseline and ball for
known/modelled ground height, and a dashed unknown marker without an invented
arc when elevation is unconfirmed. It is not a measured vertical trajectory.
Interception details distinguish the intended receiver from the defender who
actually gains the ball. Completed reference playback has its own replay entry;
returning to review preserves the learner's original outcome.

Small screens crop the tactical camera to the attack without stretching field
angles. Portrait orientation stays consistent through review, and reference
playback uses the full field area before showing feedback. Shirt numbers remain
visible above the ball at the player's feet. Pass rings and linked callouts are
both selectable; decorative paths never intercept input. All 27 decision
combinations use continuous clocks and bounded player movement, and the
historical assist is checked against the moving defenders for an open lane.

Primary sources currently documented in-app:

- [UEFA official lineup PDF](https://www.uefa.com/newsfiles/EURO/2024/2036211_LU.pdf)
  for Spain v England, match 2036211.
- [UEFA EURO 2024 technical report](https://editorial.uefa.com/resources/028f-1b6f7f14a391-e1beafb781cc-1000/euro2024_mini-tech-report_v7.pdf)
  pp. 6-7 for the tactical relationship:
  Ruiz/Bellingham, Shaw pressing, Carvajal's outside-of-foot pass, Yamal's
  diagonal carry, Morata/Olmo runs and Williams finishing.
- [UEFA Nico Williams final video](https://www.uefa.com/uefaeuro/history/video/028f-1b5e7b0b2ccd-cd78a924f1bd-1000--spain-vs-england-player-of-the-match-nico-williams/).
- [Official England highlights](https://www.youtube.com/watch?v=lBOS43RWfY0&t=110s),
  also embedded by the [FA match centre](https://www.englandfootball.com/england/mens-senior-team/fixtures-results/2023-24/EURO-2024/spain-england-uefa-euro-2024-final-sunday-14-july).
  The 110-128 second segment was checked in official public preview frames.
  Embed availability was checked in metadata; live browser playback was not
  verified on the development host.

## Retained internal 2v2 flow

`FlowEngine` reuses deterministic motion/collision sampling from `PracticeEngine`
through the additive `PracticeSettings.freeFlow` and
`PracticeSettings.automaticSupport` flags. Both default to false for existing
curriculum callers. The retained 2v2 flow enables them explicitly when reached
by direct internal callers. Flow case focus is typed data, not inferred from
labels or case ids.

## The twelve 2v2 situations

Every focus has two authored conditions. Each pair keeps the same attackers and
changes one defender's starting position/approach; the other defender remains
present and reactive. All incoming observation passes are checked against both
opponents, and every case has a physically safe free first-touch direction.
Neither a third attacker nor a four-player switch rubric is required.

| Case ids | Read before acting | Difference between conditions | Demonstrated learning |
| --- | --- | --- | --- |
| `flow-firstTouch-0/1` | Approach side and pressure gap | Defender 2 approaches from ahead/outside or behind/outside | Touch within the visible range into usable space with pressure relief or an available next connection |
| `flow-drawDefender-0/1` | First defender's commitment and second defender's cover | Defender 2 steps toward the carrier or starts nearer the diagonal connection | Actually draw a defender and improve a connection, or use an already-open pass beyond that first defender |
| `flow-supportAngle-0/1` | Space available to the passer after release | Defender 3 starts higher or lower beside the receiver | Select and time a useful later pass into space created by automatic support; AI movement alone is not credited as the player's spatial choice |
| `flow-throughPass-0/1` | A visible automatic runner and the covering defender | Defender 3 covers deeper/wider or nearer the runner's inside shoulder | Complete a useful led pass to the visible running endpoint while the receiver actually travels at least 1 m |
| `flow-beatCover-0/1` | Both the pressing and covering defender | Defender 3 narrows the carrying channel or covers the other attacker's side | A touch/carry retains pressure clearance and opens a passing lane or creates measurable pressure relief |
| `flow-changeLane-0/1` | The congested side and available lateral space | Defender 2 starts toward the touchline or the inside lane | Move the ball laterally at least 1.5 m while measurably improving clearance or pressure; this is a two-player lane change, not a three-player switch |

The useful/risky judgment and focus evidence remain separate. Reaching a cone
gate cannot retroactively make earlier decisions correct, and the focus can be
demonstrated without completing a gate. These criteria are teaching
approximations, not a validated football intelligence score.

## One field, direct decisions

1. A brief incoming pass establishes the situation; it is the only scripted
   attacking opening. Time pauses at the receiver unless a first touch has
   already been explicitly prepared.
2. The player taps any point for the **first touch**. The field shows the actual
   **2.3 m physical range** and the exact bounded destination. An outside tap is
   projected onto that visible range. Successful reception requires a new first
   touch every time, not just at the opening.
3. A tap on open space carries the ball to that bounded field point. There is no
   hidden 5.8 m carry cap or 8 m run cap in flow mode. Execution reaches the
   requested point unless an actual steal or controlled gate crossing ends play.
4. A visible, accessible **Pass** ring follows the teammate. Tapping it commits
   the pass immediately. The old carrier's support run is selected
   automatically from the current player/defender geometry and starts on the
   first simulated sample of the pass.
5. Control transfers when the receiver physically collects the ball. A prepared
   first touch follows immediately; otherwise time pauses for the next choice.
   Ordinary receptions use the receiver's current run, velocity and the ball's
   flight time, then settle the ball to the receiver's feet over sampled frames
   while preserving a realistic receiving stride. The old carrier becomes the
   automatic supporter, and any support run that is not complete remains visible
   and continues during subsequent touches, carries, passes or an explicit 0.5 s
   advance. The new carrier must choose a first touch from this exact paused
   world before pass controls return.
6. A **through pass** is available only to the other attacker's visible running
   endpoint. It never invents a hidden distant target. An ordinary pass resolves
   against the receiver's current movement, acceleration and ball flight rather
   than a fixed lead distance; it can still be stolen and does not count as a
   through pass.
   The opening pass and later passes accept an explicit first-touch selection
   before arrival. Touch/carry execution also accepts one next action, with
   progress copy distinct from a fresh decision prompt. Without a queued choice
   the world pauses for the player's decision. The localized instruction area
   and its trailing control keep a stable size, so the pitch does not shift as
   instructions wrap or a cancel button appears; instructions and feedback are
   reused between animation frames.
7. A controlled cone crossing, actual defensive steal or 16 decisions ends the
   sequence. Offside is disabled for this deliberately constrained 2v2 exercise.

The decision snapshot contains the automatic support settings and the visible
support plan used at that moment. `beforeDecision` restores that exact world,
pending plans, settings and history; repeating the same pass, touch, carry or
hold gesture yields identical sampled motion. Feedback uses positions **at
actual reception**, not the distant target of a support run that is still in
progress, and does not credit the player's spatial skill for a run chosen solely
by the support AI.

All movement and contact share sampled trajectories (at most 25 ms apart).
Facing direction is interpolated through the shortest turn between samples, so
the drawn body direction should not snap to the next stored frame. A steal
transfers possession to the actual defender and includes a continuous 0.4 s
collection movement. Both ball and attacking carrier must cross the cone opening
under control; a ball flying through on its own does not complete it. Only
persistent support plans and physical braking remain between choices; there is
no timer, countdown or unbounded real-time tick while the player reads.

Domain tests cover all 12 openings, safe first-touch exits, exact target/range
agreement, full clicked carry destinations, automatic off-ball displacement
before the first pass, simultaneous passing/support, reception pauses,
persistent runs, through-pass endpoints, moving-receiver collection with
non-zero receiving speed, shortest-angle facing interpolation, deterministic
retries, defender-sensitive support targets, both defenders reacting, actual
theft and controlled cone crossings.
Each focus also has a reproducible example using only the public gestures: free
touch, carrier movement, hold, pass, and explicit through pass when a visible
automatic endpoint exists; none depends on direct off-ball selection.
The existing limitations and design sources below still apply: this is a 2D
teaching model, not a professional match simulator or evidence of transfer to a
real match.

## Retained legacy curriculum

The remainder documents `scan_pass_curriculum.dart` for compatibility and
regression coverage. Its old count/mode selection, 2→3→4 progression and
per-command distance caps do **not** describe the public default above. Earlier
possession/goal engines also remain internal compatibility surfaces.
The legacy exercise uses a 40 × 28 m training area, two cone gates, and
player-controlled attackers.

## What a case defines

Each `PracticeCase` includes a typed `PracticeLearningDefinition`: its goal,
observable cues, typical mistakes and measurable rubric. A useful football
choice and demonstrating the current case's objective are separate facts:
`PracticeDecision.useful` and `goalDemonstrated`. A successful cone crossing does
not retroactively mark earlier choices correct. Retaining possession can be a
valid exercise ending.

The thresholds (1.5 m pressure gap, 1 m unobstructed passing lane, moving receiver
speed of at least 1.6 m/s or an explicit forward run plan) are inspectable teaching approximations.
They are not universal coaching rules or validated ability scores.

| Cases | Players | Observe | Paired condition | Teaching criterion |
| --- | --- | --- | --- | --- |
| `firstTouch-0/1` | 2v1 | Pressure approach and the next connection | The same defender approaches from above/below; other attackers are identical | A controlled first touch leaves usable time/space or a connected next action; a different touch can also be useful |
| `drawDefender-0/1` | 2v1 | Whether the defender steps to the ball or tracks the runner | Only defender 2's movement changes | Recognize a committed defender, use an available carrying lane or pass beyond the defender while keeping the receiver connected; do not demand an extra carry when the pass is already available |
| `throughPass-0/1` | 2v2 | Runner direction/speed and the intervening defender | Only runner 8's velocity changes: forward run/check toward the ball | Lead an actual run; a checking receiver can require a pass to feet, a short carry or waiting before a later through ball |
| `supportAngle-0/1` | 3v2 | The ball holder's pressure and the return/support lane | Only defender 2's lateral movement changes | Select the supporting attacker and open an available passing angle; separately decide whether and when to use that connection |
| `thirdPlayer-0/1` | 3v2 | Covered direct lane and an intermediate teammate | Only defender 2's lateral movement changes | Recognize when a three-player chain is useful; the paired condition may reopen a direct pass, which remains valid |
| `switchPlay-0/1` | 4v3 | Ball-side defensive concentration and far-side cover | Only defender 5's movement changes | Move possession across at least 10 m of width into a receiver with greater pressure relief; reevaluate if the far-side defender is already moving there |

Each pair changes one player's trajectory, not a hidden answer id. Recommendations
and physical policies never inspect case ids or variant labels. Tests rename
those labels while preserving the world and verify identical choices/results.
The first pair mirrors one pressure trajectory; the other pairs share starting
positions and change one velocity. These are authored small-sided constraints,
not arbitrary 11v11 match formations.

## Decision and action loop

1. Select **2, 3 or 4 attackers** and free connection or pass and move before
   opening a case. The catalog filters actual teams. Retry, paired conditions
   and next case preserve the selection. Defenders remain reactive opposition.
2. Watch the incoming pass and surrounding motion for 0.65 s. This is the only
   scripted attacking sequence in the public exercise.
3. Time freezes. Numbered first-touch controls connect to a solid path and a
   football at the **actual destination**. Metres mean current ball to destination,
   not screen-button spacing. A touch reaches its target unless stolen first.
4. Choose a carry, pass to feet, through pass or 0.5 s advance. After receiving,
   that attacker becomes the controlled ball holder and waits for the next user
   choice. Nobody independently chooses a second pass, carry or supporting run.
5. Use the on-pitch movement control to select **any attacker**, then a destination.
   During destination placement, other selectors and pass buttons are hidden.
   The ball holder executes a carry; an off-ball player gets a queued run without
   time advancing. Plans show persistent arrows, endpoints and remaining metres.
   They execute during the next ball action, 0.5 s advance or their own on-pitch
   run action. Plans can be changed or cancelled without spending a decision.
6. Finish at a controlled gate crossing, physical steal, offside or **16 user
   decisions** retaining possession. Gate completion and learning remain separate.

Carries are capped at 5.8 m and off-ball destinations at 8 m per command. Stored
targets and drawn endpoints use the same bounded coordinate. A short ball action
may end before a runner reaches the target; that plan persists. A direct run action
continues to the target unless play ends. Uncommanded attackers only brake existing
velocity. Selecting a receiving pass authorizes meeting its target, replaces that
receiver's old run plan, and stops that plan on reception.

**Free connection** permits every teammate as a receiver. **Pass and move** is a
training constraint: after a completed pass, the next pass must return to its
previous passer. The return never starts automatically and still respects steals
and offside. Carrying, waiting and support runs remain available. The learning
goal in this mode is a useful return after the passer relocates at least 1 m,
replacing
the base case's third-player/switch goal. It is not an always-correct match rule.

A through ball is distinct from a pass to feet. Its target leads the receiver;
a checking receiver must actually reverse direction and reach the ball. The
ball is never awarded to a distant player just because they were the selected
recipient. Runner aims and standard through-pass targets remain before the
cones, so crossing the line still requires possession and control.

## Shared physical evidence

Every committed action integrates players and ball at intervals of at most
25 ms. The same `AttackTransition.motionSamples` drive visible replay and event
tests. Passes travel at 17 m/s; players accelerate up to 6.2 m/s², with role/action
speed caps. Collision detection sweeps relative ball/defender movement and stops
at the first contact, rather than checking an unrelated destination or rolling
success odds. Opening observations also provide actual sampled moving frames;
tests verify the incoming pass is clear of every defender.

A gate is a line between two cone positions. Both the ball and its carrier must
cross forwards in the opening with the ball within 0.65 m of the same carrier.
A pass flying between the cones is never gate success. Gate replay stops at the
exact crossing. At defensive contact, possession transfers to that defender
(`AttackState.carrierIsDefender`) and a further 0.4 s of sampled collection makes
the steal visible. The ball approaches continuously and is no longer attributed
to the dispossessed attacker. Review opens on the final frame and names the
defender. A later interception cannot rewrite an earlier decision's evidence.

Offside is deliberately disabled in 2v1, 2v2 and 3v2 introductory exercises and
is explicitly enabled in the 4v3 stage. The kick-time snapshot uses the actual
second-last defender, ball and halfway line; no goalkeeper is invented. Running
past the line after a legal release is allowed. Being beyond it at release stops
the play at the release frame.

## Feedback and comparison

A decision records a typed observed cue, chosen action, reason, useful/risky
judgment, case-goal evidence, pressure gaps, lane clearances, passing connections,
actual travelled distance and relevant player number. There are distinct reasons
for a running receiver met in stride, a runner not ready, a reception under
pressure, a closed pass lane, a hidden/open support lane, an observed three-player
chain, actual far-side relief, controlled gate passage and kick-time offside.
A claimed defender commitment requires actual movement toward the ball and a
new connection or measurable lane improvement, not merely a successful attack.

Pressure values mean distance from the current ball carrier/ball to the nearest
defender. They may describe different carriers before and after a pass. Lane
values compare a consistent player pair: the acting ball holder and selected
teammate (or the strongest initial connection for a carry/touch); support compares
the original ball holder with the attacker whose run was commanded.
They never compare an old chosen target with an unrelated new "best" lane.
Distance is the sum of the actual sampled travel, including concurrent support
movement, rather than the distance to a destination that was not reached.

`beforeDecision` restores the exact paused world, phase, history, settings, queued
runs and required return receiver to try a second choice. `rankedChoices` uses the
case rubric and actually simulated
outcomes; the highest-ranked choice is a model recommendation, not a unique
correct answer. `coachRun` produces a complete example from the same initial
world. A bounded search is used when a short-horizon route would subsequently
lose the ball. It uses the same movements, offside and interception rules.

Feedback is localized by the UI; the domain stores no presentation copy. The
screen should show the relevant moment, actor and short explanation, reserving
numbers and a complete path comparison for review.

## Scope and design sources

This is a deterministic perception-and-decision exercise, not a professional
match simulator. It does not model body contact, fouls, first-person visual
occlusion, detailed ball spin or empirically measured transfer to a real pitch.
Repeated successful decisions are evidence within the exercise, not proof of
increased football intelligence. Stage selection is available immediately; there
is no claimed mastery/adaptive curriculum or persistent ability score.

Design references: [FIFA: movement to attack space in behind](https://www.fifatrainingcentre.com/en/practice/talent-coach-programme/sessions/movement-to-attack-the-space-in-behind.php)
for reading carrier/runner/defender interaction and passing timing, and
[The FA: mastering the ball through the gates](https://www.thefa.com/bootroom/resources/coaching/mastering-the-ball-through-the-gates)
for using open gates as a dribbling constraint.

The focused domain tests cover paired conditions, counts, observed moving frames,
first-touch alternatives, through timing, complete examples, controlled crossings,
visible interception/speed continuity, kick-time offside, learner movement ownership,
manual team ownership, queued/cancelled runs, constrained return targets, actual
defensive possession and reproducible comparisons including pending plans. The
older assisted policy is retained only behind explicit internal settings for
regression tests; it is not a public control option.

## Default screen interaction

`ScanPassGameScreen` opens `ScanPassFlowScreen` immediately in the first 2v2
situation. Its on-field goal and current instruction stay in a fixed order.
A free-space tap chooses the first touch (within the visible physical circle)
or the carrier's complete dribble destination. The **Pass** ring around the
teammate commits a pass in one tap; automatic support handles the passer's run.
A marked automatic receiver endpoint offers a through pass when the movement
supports it.
Tapping the carrier keeps possession for a short interval; defenders still react.

One next command can be queued during a committed action, replaced or cancelled.
Commands execute against the resulting session only after the visible action
finishes; a terminal result clears the queue. Picking cases, help, app background
and explicit pause suspend playback. There is no reaction-time score.

Review groups copy into **Result / Why / Try next** with two fixed footer actions:
**Retry this decision** and **Next situation** (or **Continue play** during a
mid-attack review). Retry restores the selected original snapshot; combined passes
return to the same automatic intent without reopening a manual support-placement
step. Replay, the prior attempt, before versus after frames, decision selection,
restart and case selection live in More.
Prior-attempt replay uses that attempt's own feedback and returns to the new record.

Pass controls retain priority at the receiving player's position. On compact
screens, overlapping hold/through controls move to separate hit areas and have
connector lines to the controlled player or actual run endpoint. A relocated
hold uses an hourglass so it remains discoverable. Portrait and landscape
pointer regressions verify that a nearby receiver's pass and hold commands stay
independently tappable.
