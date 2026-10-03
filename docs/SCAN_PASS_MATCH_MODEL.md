# Scan Pass Match Decision Model

The Scan Pass feature is a local 4v3 decision-learning scene centered on #6 receiving from #4 with #8 and #9 as support options. Scenarios are authored variants, not random dots: rear pressure from either side, retreating pressure, marked support, closing forward lanes, and return-pass opportunities.

The default user experience is self-paced. Reading time, help dialogs, and option preview time do not advance the model, expire a round, or change the outcome. The only visible motion is an explicit scan/receive/action/replay transition, and the only learning choice that deliberately advances model time before a pass is the explicit hold action. A selected option is only a preview until the learner presses the execute action.

Before scanning, the learning view masks nearby rear pressure while retaining distant players as tactical context. The marked area is an instructional cue, not a simulation of human visual range. Preview paths show only the requested touch, pass, or movement; interception points and future return passes appear after execution. On small screens, selecting an action brings the field into view with persistent change-choice and execute controls.

The model uses normalized pitch coordinates and simple deterministic motion. It evaluates first touch state, defender movement, pass-lane sampling, pressure near the ball, recipient space, return-and-move angles, hold timing where selected, and the match objective. These values are game heuristics only; they are not real meters, calibrated seconds of football skill, xG, or pass-success percentages.

Score details remain available only as a collapsed secondary evaluation for comparing choices within the same scene. They are not part of the primary intro, HUD, or causal review. The legacy/versioned challenge history is preserved for previously stored results, but the new self-paced learning flow does not write new score history, timeouts, or incomparable untimed session summaries.
