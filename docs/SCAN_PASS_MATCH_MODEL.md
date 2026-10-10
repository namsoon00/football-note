# Scan Pass: continuous situation catalog

Scan Pass opens directly on a catalog of 12 continuous attacking situations: central reception, half-space, touchline, layoff, third-player connection and attacking transition, each with a pressing and covering defensive setup. The six families have different spatial layouts; each defensive pair preserves the initial attacking shape. Titles and miniature pitch previews use the same scene configuration as play. A scenario starts directly with observation and an independent decision. Coach demonstration is optional within that scenario. Retry, next situation and catalog navigation remain available without a separate practice menu.

The learner remains number 6 through first touch, a teammate pass, off-ball movement and the return connection. Each intention executes immediately. The same possession continues through automatic teammate decisions to a shot, safe reset or loss. A shooting chance includes the actual goal, save or block. The model does not force every scenario into a goal. Legal but inferior choices are animated rather than silently corrected. Review compares the full learner and coach possessions from the same initial state without overwriting the learner's choice record.

## Spatial and movement model

- All movement distances use a 105 m by 68 m coordinate model, independent of viewport size. A displayed metre value is rounded to one decimal. The responsive tactical drawing can stretch its aspect ratio; screen pixels are not used as a distance measurement.
- First touches travel about 2.8–3.2 m. Support options are derived from number 6's current position, rather than shared absolute coordinates. The chosen support path's start, direction and arrival match the engine target. Uninterrupted planned support motion travels exactly the displayed straight-line distance; an interception can end it early.
- Normal playback uses one model second per wall-clock second. Incoming pass duration is computed from ball travel. Slow replay and manual pause are available; these change playback only, not decisions or outcomes. Reduced motion jumps to stable states.
- Ground passes travel at a nominal 19 m/s, shots at 25 m/s. Outfield role motion is capped at 7 m/s, with acceleration/deceleration limited to 5.5 m/s². The goalkeeper has a lower movement cap. These are transparent design parameters, not measurements of a particular professional team.
- The engine integrates movement in steps no larger than 25 ms. `AttackTransition.motionSamples` is the source both for collision detection and the rendered `frame()` path. Collision checks use the relative ball/defender segment between samples, so the visible trajectories and interception instant agree.
- A designated defender presses the ball/receiving lane after a brief reaction interval. Other defenders cover at staggered depths, divide receiver threats and recover goal-side as the ball progresses. On role changes velocity decays through acceleration limits instead of snapping to a new speed cap.
- Attackers form support angles, come toward a pass, move diagonally beyond the defensive line, and offer a reset behind the ball. The passer moves again after release. A teammate in possession moves away from pressure while the learner supports. The goalkeeper follows the ball angle and reacts to a shot. No player is teleported to a fresh formation between decisions.
- Offside uses the release-time ball, halfway line and second-last defender, including the goalkeeper. A receiver may run beyond the line after a legal release. An earlier interception ends the attack before an offside involvement is invented.

## Coaching and review

The coach explores complete continuations using exactly the same transition functions as the learner. It prefers an actual chance, retained possession and usable next connections. Scene names cannot change outcomes: identical geometry with different situation/variant labels produces the same recommendation. Several routes may be useful; this is not a unique-answer quiz.

Feedback names the actual receiver or interceptor. The moment timeline only includes events that occurred, and inspecting an early moment hides later trails. Full-route comparison also includes the coach's later actions; it is not represented as proof that the first touch alone caused the final result. There are no speed points, XP awards or persistent skill scores.

Coordinated movement follows principles described in FIFA Training Centre material: the closest defender pressures while others cover and block passing lanes, and timed third-player movement creates the next receiving option. Sources: [Defending as a unit](https://www.fifatrainingcentre.com/en/practice/elite-sessions/out-of-possession/defending-as-a-unit.php), [Third-player combinations](https://www.fifatrainingcentre.com/en/game/game-analysis/in-possession/third-player-combinations.php), [Passing the press](https://www.fifatrainingcentre.com/en/game/game-analysis/transition-to-attacking/passing-the-press.php).

These coaching sources inform the model; they do not validate its training effect. This remains a deterministic small-group, 2D instructional simulation, not professional player tracking, full 11v11 tactics or a measured assessment of gaze or real-match improvement. Body orientation is schematic, technical execution is automatic, and body-part contact, fouls, restarts and goalkeeper handling details are not simulated.

## Presentation and accessibility

The pitch retains human uniform silhouettes, a soccer ball, body-facing chevrons, a visible learner label, goalkeeper, goal and attacking direction. Planned player runs use directional arrows with arrival markers and metre labels; ball-pass paths are visually distinguished. Choice numbering matches field and dock controls. The optional demonstration never blocks independent entry.

Stable framing and separate desktop/phone/landscape layouts keep important actors and controls visible. Semantic dock controls offer the same choices without dragging or precision tapping. Playback pauses for help, app backgrounding and navigation; a user's manual pause remains paused on return. En, ko and ja text comes from the localization files.

## Retained legacy implementation

Free attack is a secondary catalog entry using the earlier `AttackEngine`; its model is separate from the new possession engine. The previous 48 short judgment episodes, decision lessons, touch-chain and space-training classes remain for regression coverage and compatibility. They are not promoted as a separate practice layer in the default catalog. The new 12 continuous situations do not claim to turn those 48 disconnected episodes into full possessions.

## Verification

Domain checks cover distinct catalog geometry, changed defensive recommendations, complete possession continuity, distance/arrival agreement, deterministic comparison, kick-time offside, real interception positions, role speed/acceleration bounds and rendered samples. Presentation checks cover direct catalog entry, scenario selection, optional coaching, next situation, route overlays, playback speed/pause and constrained screen sizes. Actual Flutter raster and input checks supplement widget layout tests.
