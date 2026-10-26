# Scan Pass: actual-match observation and retained lessons

## Scope and validation status

`ScanPassGameScreen` now opens `ScanPassRealMatchReplayScreen`. The public
experience is a library of 25 continuous observational scenes: the existing 20
A-League scenes plus five historical Premier League/LaLiga scenes. The five new
scenes appear first and feature De Bruyne, Salah, Messi, Kroos, and Vinícius in
source-continuous 8.6–12.0 second intervals. The library covers transition,
build-up, pressure, switches, penetration, combinations, wide attacks, and
turnovers. Every scene starts paused. One action plays continuously to the next
meaningful recorded teaching moment and pauses there; that same action pauses or
resumes mid-interval and becomes replay at the true clip end. There is no
scrubber, speed choice, chapter row, manual camera control, compulsory choice,
quiz, rating, score, countdown, synthetic defender AI, player control, or video
link in this release.

The original A-League source is SkillCorner Open Data at pinned revision
`4340d274572876239c154c90bc507a9b3250a656`: Brisbane Roar v Perth Glory on
2024-12-21, match 1925299, and Sydney FC v Adelaide United on 2025-02-01,
match 1996435. The original Brisbane transition retains 25 fps positions and
12.5 fps pose snapshots. The 19 additional scenes use 10 fps tracked positions
without invented pose samples. The historical source is pinned separately at
`1ed50b775f93075c2a6d00d0d795f13b7b89709e`: Manchester City v Liverpool on
2020-07-02, match 4039, and Real Madrid v FC Barcelona on 2020-03-01, match
3442. Its recorded layer remains broadcast-visible tracking rather than
measured full-22 tracking. A separate, explicitly marked display layer keeps
the 22 players active at each scene's match clock continuously visible, using
same-player interpolation and nearby same-period anchors for missing positions.
The recorded layer retains every gap, and reconstructed positions never
become evidence for a coaching claim. Scene stages and outcomes are factual
navigation and context,
not claims about intent, an exact foot, an optimal choice, an automatic return,
or coach approval.

Some source positions and the available displayed body poses are estimates.
The overflow disclosure identifies tracking-only and broadcast-visible scenes,
whose main-pitch body motion is procedural rather than measured pose. Its gait
phase is integrated across the displayed trajectory, facing changes gradually,
and player rendering interpolates without overshoot. Historical display
estimates keep the same opaque body and number and add a small hollow ground
ring, explained by one short in-pitch legend. The ball always follows its linear
recorded XY; height is
used only when every selected source frame supplies Z. It is never snapped to
feet and no kick or missing height is fabricated. Source team colors, player
names, and numbers are retained. Historical rosters contain exactly 11 active
identified players per side; ambiguous anonymous observations do not create
extra players. Uniform design, skin, shorts, and procedural limbs are not a
photographic reconstruction. This is an
observation library, not evidence of cognitive training, coach certification,
or learning transfer.

The historical source has no provider dynamic-event annotations. Its receive,
carry, pass, pressure and connection labels are conservative editorial
derivations from possession transfers, proximity and continuous trajectories.
The source sheet discloses that distinction and the lack of measured pose. Each
new scene stops at the selected recorded interval end instead of asserting an
unseen completion, shot or goal.

The public camera remains on one stable overview for the entire clip, covering
the full pitch, all displayed player trajectories, the recorded ball and safe
body/caption margins. The source-only automatic close camera remains a domain
API with regression coverage. Body safety is reserved in screen pixels, so the
pitch can fill the available space without wasting large world-space margins.
Wide layouts use the available width; portrait layouts
rotate the normalized attack upward, and both attack directions preserve equal
world scale. The pitch contains one short cue and relevant trail or arrow, with
layout avoidance for the ball and important bodies. There is no permanent
mini-map, pose card, result panel, or fullscreen mode. Scene selection and
source disclosure live in the single overflow menu, and scene changes start
paused.

Short landscape screens place the title, overflow and the same single playback
action beside the pitch, preserving its full height instead of shrinking all
22 players between a top title and bottom controls.

`ScanPassPressureLessonScreen` and the authored 12-situation model remain as
direct legacy APIs for regression coverage, but they are no longer the public
Home → Scan Pass default. The remainder of this document records that retained
model and must not be read as a description of the default entry.

## Retained pressure-lesson model

This is a reduced seven-player model with four attackers, three defenders and
no goalkeeper. The coordinates are authored teaching geometry on a 105 m x 68 m
field; they are not tracking data or reconstructions of real matches. The
sources below establish coaching principles, not endorsement of the app or
validation of its cases. No coach has reviewed the cases and no learning or
transfer study has been performed.

Legacy draw-and-release, third-player and historical-reference APIs may remain
for regression coverage. They are not part of the retained 12-case catalog and
their sources are not presented as sources for these cases.

## Legacy authored lesson catalog (direct entry only)

The retained catalog order is the four guided/contrast pairs, followed by one held-out
case from each family. Guided and contrast partners have stable starts and
differ in exactly the declared cue. There is no random positional jitter in a
paired start.

| Family | Situation and phase | Role relationship and task | Guided/contrast cue | Held-out transfer |
| --- | --- | --- | --- | --- |
| Receiving under pressure | Middle-third reception | Receiver #19 reads the nearest presser and cover before the first contact, then the actual carrier makes the next decision | Presser approaches from the opposite side; all other authored start values are unchanged. The guided example touches inside, preserves the already usable forward lane, and connects with #10; the paired case touches outside and safely returns to #2 from its closed-forward picture | Different channel and support triangle with the same pressure-side principle; its closed forward route also uses the safe #2 outlet |
| Usable off-ball support | Build-up after #10 receives | Off-ball #19 selects one free-space target while #10 holds the ball, then the actual carrier chooses the next action | Cover #4 changes position; the mover, carrier, presser, tracker and motion intents are unchanged | Different build-up region and relationship to the cover shadow |
| Runner and through-pass window | Attacking progression | Runner #17 chooses a run target, then the actual carrier decides whether and when to release | Runner #17 starts closer to the visible defensive line; the line defenders and other actors are unchanged | Different channel, deeper line and delivery angle |
| Recycle or switch | Attacking-third route closure | The carrier judges the forward lane and far-side outlet, then the actual resulting carrier acts | Cover #4 changes the far-side/forward closure; the other actors and intents are unchanged | Mirrored field region with a new outlet geometry |

The paired cue changes an observable conditional judgment, not merely a title.
The receiving pair reverses the useful touch corridor; the support cover cue
changes whether the same forward support target offers an angle; the runner
pair changes an attacking run into an onside recovery and safe outlet; and the
recycle pair changes a closed forward picture into a usable runner pass. Other
choices can still be defensible when their measured conditions support them.

Each `PressureLessonScenario` carries typed `PressureLessonMetadata`:

- `principle` and one or more `sources`;
- `region`, `phase`, and `roleRelationship`;
- `learningObjective` and observable pre-action facts;
- `contrastFeature`; and
- a family-specific `PressureConditionalRubric`.

The app displays the current situation, region/phase, goal, holder, deciding
player, and a neutral observation throughout decisions, execution, retry, and
replay. It does not reveal a preferred action before selection.

## Sources and adaptation map

The source sheet was checked on 2026-10-19. The exact primary references are:

1. John Peacock, “Passing and receiving,” FIFA Training Centre, 26 March 2024:
   <https://www.fifatrainingcentre.com/en/practice/elite-sessions/in-possession/john-peacock-passing-and-receiving.php>
2. Rehanne Skinner, “Using the goalkeeper for successful build-up,” FIFA
   Training Centre, 22 February 2022:
   <https://www.fifatrainingcentre.com/en/practice/elite-sessions/in-possession/building_from_the_back_skinner.php>
3. “5v5 plus 3 small-sided game: Breaking the press and playing in behind,”
   FIFA Talent Coach Programme, 31 December 2024:
   <https://www.fifatrainingcentre.com/en/practice/talent-coach-programme/build-and-progress/5v5-plus-3-small-sided-game-breaking-the-press-and-play-in-behind.php>
4. “The role of player numbers and space,” FIFA Training Centre, 9 June 2026:
   <https://www.fifatrainingcentre.com/en/practice/training-perspectives/designing-games-for-development/the-role-of-player-numbers-and-space.php>

The in-app source sheet lists only the sources mapped to the current case and
uses the injectable `sourceLauncher`. It also displays the adaptation and
validation limits.

| Family | Source principle adapted into this model | What is not claimed |
| --- | --- | --- |
| Receiving under pressure | Observe pressure and available connections before receiving; keep or trade options according to the approach and cover | The app cannot observe head scanning, body orientation, shielding technique, or real pass technique |
| Usable off-ball support | Offer an angle/width appropriate to the press and defender positions | This is not a reproduction of Skinner’s goalkeeper practice; the model has no goalkeeper |
| Runner and through-pass window | Read delivery ability, runner motion, space behind pressure and the line together; judge offside at release | The case is not the FIFA exercise or a real match scene |
| Recycle or switch | Recycle to reopen a usable route when forward play is closed; do not make recycling universally superior | The source does not certify an authored app choice as optimal |
| All four | A reduced game should preserve the relevant relationships, vary one meaningful cue, and expose conditional decisions | Repetition in this app is not evidence of real-match learning transfer |

## Connected decisions and physical continuity

A case contains two important judgments. The deciding actor is resolved from the
actual current world. A pass does not force an off-ball decision or return pass.
Actor positions, velocities, ball state, possession, active run plan, contact
and elapsed time carry into the next judgment without a reset or teleport.

An off-ball choice is one free-space pitch tap within a bounded reach. During
that interval the current carrier uses the same neutral short-hold policy and
defenders continue to react. The next judgment belongs to the actual carrier.
Support credit compares the chosen movement with the same snapshot advanced for
the same duration while the mover stays stationary. Credit requires an actually
improved usable relation. An opened or materially improved passing lane is
reported as an angle effect; changed defender spacing is reported separately
and is never renamed as an opened lane. The retained support examples
all create a measured usable lane and the next carrier uses that relationship.
If a mover does not receive in another live choice, review names the teammate
option that changed and does not invent decoy value.

Passes and touches use the shared physical resolver. Possession changes only
through sampled player/ball contact. An intended receiver id guides the flight
but cannot create control. Interception, loose ball, retained possession, and
offside remain separate outcomes.

## Offside model

The through-pass line is computed from the exact world. Observation,
movement-only choices and other non-pass views label the current potential
line. A recorded or active pass freezes the visible line to that pass's exact
release snapshot. Its x-coordinate is the more goal-side of the ball and the
second most goal-side visible defender. The same release value drives feedback
and the offside check. A player in their own half remains onside. A player beyond
both references is penalized only if that intended player becomes involved by
receiving the pass; crossing the line after an onside release is legal, and a
defender touching the ball first remains an interception.

With only three visible defenders and no goalkeeper, the line is an explicit
small-sided simplification rather than a complete 11v11 law model.

## Pre-action coaching judgment versus outcome

Every `PressureEpisodeDecision` stores a `PressureCoachingAnalysis` linked to
the exact immutable `before` world. `PressurePreActionFacts` are recomputed from
geometry and motion, including:

- nearest pressure distance, direction and approach;
- simulated connection clearance and forward-lane availability;
- projected support-target lane clearance from the current snapshot;
- runner movement, release-time line and onside window; and
- forward closure and availability of a recycle/far-side outlet.

The scenario metadata chooses which principle and rubric to apply. It does not
provide a success-answer key, and the physical solver never consults lesson id,
variant, option key, action label, or the coaching assessment.

After off-ball movement, `PressureSupportResult` separately stores executed
movement and lane changes against the same-duration stationary counterfactual.
Those measured consequences are not written into `PressurePreActionFacts` or
presented as facts known before choosing. First-touch judgment requires movement
into a clearer two-dimensional corridor. A later carry uses available
corridor/contact space instead; it need not increase its distance from every
defender ahead.

For an active runner plan, review describes only the completed movement interval
and asks the learner to recheck the lead pass at release. A static foot-position
lane projection is not labelled as a completed failure of the continuing run;
the subsequent carrier choice uses its own release snapshot and actual trajectory.

The idea assessment is one of fit, defensible trade-off, conflict, or
insufficient evidence. Several actions can be defensible. Examples:

- A safe pass can fit pressure or be a defensible trade-off that preserves the
  ball while declining an available forward route.
- A forward action into observed cover can conflict with the cue even if a
  sampled rollout happens to retain possession.
- A well-matched idea can be intercepted or go loose; the review still reports
  the idea separately from actual contact.
- Support movement can create an option without claiming that an ensuing pass
  occurred.

The review order is concise and fixed: what mattered before the action, why the
selected choice did or did not fit, then the actual physical outcome. The pitch
adds only relevant route, pressure, lane, run, contact, or offside-line evidence.
It makes no claims about scanning or body shape that the model cannot observe.

Same-start alternatives use the selected decision’s exact `before` snapshot and
the same defender/teammate policy. `relevantAlternative` chooses a different,
instructionally meaningful condition—not a universal best answer. Retry restores
the chosen snapshot by identity, preserves its timeline prefix, and discards only
the suffix. Returning from an alternative or example restores the original first
attempt unchanged.

## Reference examples

Retained legacy cases use a small family-specific conditional policy rather than the old
retention/progress/separation weighted selector. It reasons over live geometry:

- reception: guided chooses the inside clear corridor and then physically
  connects forward with #10 through a lane that was already usable; the paired
  cue reverses the touch outside and uses its valid live connection, while the
  transfer keeps a closed-forward case that safely recycles to #2;
- support: all variants move #19 into an actually improved receiver lane
  relative to staying still, after which #10's ordinary pass reaches #19;
- runner timing: guided and transfer produce an onside moving reception, while
  the paired closed window adjusts the run and uses the safe #10 outlet;
- recycle/switch: guided and transfer recycle from closed forward pictures and
  connect the new outlet, while the paired open picture uses the runner.

Every selected step is run through ordinary physics. All 12 retained authored
fixtures have a replayable goal-aligned example across the tested seeds. Once
its local two-decision goal is demonstrated, the example ends at that actual
world instead of adding a generic long reset that erases the evidence. If a
custom/live state cannot demonstrate its principle—or its terminal world is
lost, loose, or offside—the example is unavailable. A non-demonstrating learner
attempt that still needs a bounded continuation tries a usable forward/local
support, then a viable carry, and only then a deep recycle. Examples are labelled
source-principle adaptations, never coach-certified optimal play or historical
trajectories.

## UX and localization

All 25 scene titles, spatial coaching cues, default replay controls, and
retained lesson text are localized in
`lib/l10n/app_en.arb`, `app_ko.arb`, and
`app_ja.arb` and accessed through generated localization classes. Generic role
numbers identify the authored actors. A generic live-roster adapter paints those
actual ids and numbers in distinct attack/defence kits, while actual-match
rendering uses each scene's roster and recorded kit colors. The new titles name
their focal player, while match teams, date/clock and source revision remain
discoverable in the header, library and overflow details. Names and colors do
not imply licensed badges or a photographic match reconstruction.

The default viewer is covered at 320/360 px portrait widths and 844x390 short
landscape at 1.4 text scale in English, Korean, and Japanese, including light
and dark themes. The title, pitch, cue, one bounded playback action, back
navigation, and overflow remain available without a player-covering permanent
panel.

## Automated evidence and remaining limits

Focused tests cover:

- all 25 actual-match catalog entries, eight categories, both source revisions,
  both attacking directions, different kits and variable durations;
- deterministic historical import, raw/derived hashes, exact frame and roster
  proof, centimetre quantization, coverage decisions and preservation of the
  original 20 payloads;
- sparse recorded visibility, missing focal/step actor rejection, raw gaps
  remaining absent, dense marked 22-player display trajectories with continuous
  gait, and explicit XY-only ball height behavior;
- recorded-pose versus tracking-only behavior, deterministic distance-phased
  gait, stationary/running behavior, bounded interpolation, and gradual turns;
- one-control stop timing through the true duration, manual and lifecycle
  pause/resume, replay, scene selection behind overflow, paused scene changes,
  stale async load rejection, and retry;
- automatic context/close camera continuity and ball/relevant-actor visibility
  across all scenes, both attack directions, portrait normalization, and
  constrained light/dark layouts;
- stable public overview framing with every displayed body and recorded ball
  inside the safe viewport, including intermediate samples and large text;
- four retained families, 12-case ordering, metadata and source mapping;
- one-cue paired starts and held-out geometry;
- a physically retained first-touch-to-forward-#10 chain, including actual
  receipt and evidence that the touch preserved rather than opened its lane;
- cue-dependent coaching judgments and a retained risky action that is not
  automatically praised;
- idea assessment independent of contact outcome;
- useful support movement versus a stationary counterfactual;
- release-time offside and the visible line from the same world;
- all 12 retained reference examples through actual goal-aligned trajectories,
  plus explicit unavailability for an invalid custom state;
- local-objective terminal validation without a value-erasing automatic reset;
- separate first-touch and safe-carry corridor reasoning;
- generic-id jersey and number pixels in the actual pitch renderer;
- state continuity, actor-aware replay, exact retry, immutable first attempts,
  source disclosure/launching, and localized pitch interaction.

These are consistency checks for the authored model. They do not establish that
the situations are fully representative of 11v11 football, that the conditional
rubrics are complete, that a specific choice is universally correct, or that
using the lesson improves player performance. External coach review, player
usability work, and measured learning transfer remain outstanding.
