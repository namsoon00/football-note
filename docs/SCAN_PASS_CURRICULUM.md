# Scan Pass: small-sided decision curriculum

The default game now uses `scan_pass_curriculum.dart`. Earlier possession/goal
engines remain available for compatibility; they do not define these lessons.
The exercise is a 40 × 28 m training area, progressing from two attackers to
three and four. The learner is always number 6. There are two cone gates and no
goalkeeper, shooting decision, score or reaction-time reward.

## What a case defines

Each `PracticeCase` includes a typed `PracticeLearningDefinition`: its goal,
observable cues, typical mistakes and measurable rubric. A useful football
choice and demonstrating the current case's objective are separate facts:
`PracticeDecision.useful` and `goalDemonstrated`. A successful cone crossing does
not retroactively mark earlier choices correct. Retaining possession can be a
valid exercise ending.

The thresholds (1.5 m pressure gap, 1 m unobstructed passing lane, moving receiver
speed of at least 1.6 m/s) are explicit, inspectable teaching approximations.
They are not universal coaching rules or validated ability scores.

| Cases | Players | Observe | Paired condition | Teaching criterion |
| --- | --- | --- | --- | --- |
| `firstTouch-0/1` | 2v1 | Pressure approach and the next connection | The same defender approaches from above/below; other attackers are identical | A controlled first touch leaves usable time/space or a connected next action; a different touch can also be useful |
| `drawDefender-0/1` | 2v1 | Whether the defender steps to the ball or tracks the runner | Only defender 2's movement changes | Recognize a committed defender, use an available carrying lane or pass beyond the defender while keeping the receiver connected; do not demand an extra carry when the pass is already available |
| `throughPass-0/1` | 2v2 | Runner direction/speed and the intervening defender | Only runner 8's velocity changes: forward run/check toward the ball | Lead an actual run; a checking receiver can require a pass to feet, a short carry or waiting before a later through ball |
| `supportAngle-0/1` | 3v2 | The ball holder's pressure and the return/support lane | Only defender 2's lateral movement changes | Choose a new supporting angle, or maintain one that is already useful; the teammate decides independently whether that support should be used |
| `thirdPlayer-0/1` | 3v2 | Covered direct lane and an intermediate teammate | Only defender 2's lateral movement changes | Recognize when a three-player chain is useful; the paired condition may reopen a direct pass, which remains valid |
| `switchPlay-0/1` | 4v3 | Ball-side defensive concentration and far-side cover | Only defender 5's movement changes | Move possession across at least 10 m of width into a receiver with greater pressure relief; reevaluate if the far-side defender is already moving there |

Each pair changes one player's trajectory, not a hidden answer id. Recommendations
and physical policies never inspect case ids or variant labels. Tests rename
those labels while preserving the world and verify identical choices/results.
The first pair mirrors one pressure trajectory; the other pairs share starting
positions and change one velocity. These are authored small-sided constraints,
not arbitrary 11v11 match formations.

## Decision and action loop

1. Watch the incoming pass and surrounding motion for 0.65 s.
2. Time freezes to choose a first-touch direction on the pitch.
3. With the ball, choose a short carry, a pass to feet, a through pass into future
   space or a 0.5 s wait. The runner and defenders move during every action.
4. Once a teammate receives, choose number 6's movement destination or hold.
   Movement starts immediately; after 0.45 s the teammate chooses a continuation
   while number 6 continues the chosen run. A teammate does not wait for a long
   user run to finish, and does not automatically return every pass.
5. A useful return restores the learner's on-ball decision. Otherwise the learner
   continues making support decisions. The exercise ends at a controlled gate
   crossing, an actual interception, offside or eight learner decisions with
   possession retained.

Custom carries are capped at 5.8 m and support destinations at 8 m per decision.
The stored action target is the effective capped target. A short teammate action
can end a decision checkpoint before the learner reaches a chosen destination;
feedback reports the distance actually travelled. No new off-ball run for number
6 is invented after releasing the ball; existing velocity can brake. Receiving
a pass can involve meeting that pass, but does not grant an automatic attacking
run. Teammates use pressure, pass lanes, available connections and progression,
with a useful return requiring a safe next connection and either pressure relief
or forward advantage.

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
A pass flying between the cones is never gate success. The replay stops at the
exact crossing/contact frame. A later interception cannot rewrite an earlier
decision's evidence.

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
values compare a consistent player pair: number 6 and the selected teammate
(or the strongest initial teammate connection for a carry/touch); support
compares the original teammate ball holder and number 6 after the chosen run.
They never compare an old chosen target with an unrelated new "best" lane.
Distance is the sum of the actual sampled travel, including concurrent support
movement, rather than the distance to a destination that was not reached.

`beforeDecision` restores the exact paused world, phase and history to try a
second choice. `rankedChoices` uses the case rubric and actually simulated
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
conditional teammate returns and reproducible same-world comparisons.
