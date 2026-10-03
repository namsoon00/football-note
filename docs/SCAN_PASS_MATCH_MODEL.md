# Scan Pass Match Decision Model

Scan Pass is now a single continuous attack with four attackers, three outfield defenders and a goalkeeper. The opening action starts with #4 on the ball and plays into #6, then the learner keeps possession moving on the same pitch until the attack ends with a goal attempt, turnover, save, block, wide shot, or offside.

The presentation does not reset positions after each successful choice. It stores each `AttackTransition`, shows the resulting `AttackState`, and offers the next decision from that live state. Preview paths use only the engine's intended target; the UI does not call outcome logic until the learner presses execute.

The experience is self-paced. Reading time, the scan overlay, help sheets, backgrounding, and preview selection do not advance the model. The only state-changing actions are the opening start pass and explicit executed actions. Replay uses the stored transitions without writing history or mutating the original sequence.

The main learning surface is the pitch. Players are drawn as uniforms, the ball is rendered as a soccer ball, the right-side goal and keeper stay visible, and compact controls sit around the field. Text is limited to short state cues, action labels, terminal outcome banners, and optional help or sequence review sheets.

Offside is a visual warning until the learner executes a targeted pass. The UI draws the engine's offside line and shaded beyond-line area, and marks the targeted receiver when `checkOffside()` marks an offside position. Position alone does not whistle: if a defender intercepts before the receiver becomes involved, the result is a turnover instead. On an executed offside pass, the display freezes at `offside.atKick` and marks the kick point, receiver, and second-last opponent. The rule explanation follows IFAB Law 11: offside is judged at the moment the ball is played, with the ball, halfway line, and second-last opponent including the goalkeeper all relevant.

The current flow does not award XP, score, session summaries, or challenge history. Legacy scoring model files remain available for existing regression tests and stored historical data, but the primary Scan Pass screen is a visual continuous-attack trainer rather than a scored round review.

The pitch keeps the same bounds through selection, execution, and review so player movement does not get confused with layout changes. Desktop uses the full board width; portrait phones use a taller field. On smaller goal mouths the three 44px-or-larger shooting controls sit below the field with no overlapping touch targets. Both teams use the same human uniform silhouette; transparent pass targets leave the jerseys visible.

The domain is an instructional approximation, not a full match or a validated predictor of player decisions. Coordinates represent player positions, not body-part tracking. Player motion, pressure, interception radii, goalkeeper reactions and shot spread are deterministic; the goal is enlarged for legibility. Offside covers direct open-play passes using the release moment, ball, halfway line and second-last opponent (including the keeper). Throw-ins, corners, fouls, restarts and interference-with-an-opponent cases are not simulated. The rule reference is [IFAB Law 11](https://www.theifab.com/laws/latest/offside/).
