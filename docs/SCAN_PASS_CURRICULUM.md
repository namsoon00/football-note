# Scan Pass: small-sided decision curriculum

The default game now uses `scan_pass_curriculum.dart`. Earlier possession/goal
engines remain available for compatibility; they do not define these lessons.
The exercise is a 40 × 28 m training area, progressing from two attackers to
three and four. The learner controls every attacker. There are two cone gates and no
goalkeeper, shooting decision, score or reaction-time reward.

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
