# Game Fun Workshop for Issue #98

Last updated: 2026-03-19

## Goal
- Revisit the current mini game from screen composition through logic, flow, fun hooks, and the understanding of speed and space.
- Synthesize four perspectives into one document that can guide future implementation.

## Current Read
- The game already has a solid short-loop structure: 20-second runs, lives, combo, fever, rankings, and quiz gating.
- The weakest area is not basic functionality but dramatic variation inside a run and clearer football meaning behind good choices.
- The opportunity is to make the game feel more like "reading pressure and creating space" instead of only "passing quickly."

## Four Roles

### 1. Game Director
- A short round still needs a visible arc:
  - opening read phase
  - rhythm-building middle
  - late chance explosion
- Keep the existing pass UI, but surface one-line prompts such as:
  - open lane
  - weak-side switch
  - pressure arriving
- Before a shot or high-value action, use stronger presentation:
  - lane highlight
  - short zoom
  - faster audio cue

### 2. Systems Designer
- Safe, killer, and risky passes should have clearer strategic identity, not only score value differences.
- Repeating the same option too often should lose efficiency so players are pushed to read context.
- Defender behavior should rotate between patterns:
  - lane closing
  - receiver tracking
  - counter-press
- Reward football-correct combinations:
  - create space first
  - switch side
  - third-man pass
  - finish quickly

### 3. Flow Designer
- Entry should stay light:
  - show one recommended mission
  - start immediately
- Failure should teach:
  - too late
  - lane blocked
  - receiver covered
- End-of-run UX should prioritize the next retry reason over rankings:
  - what worked
  - what failed
  - one next experiment

### 4. Football Learning Coach
- Speed and space learning must be legible:
  - color the open side
  - mark overloaded or isolated zones
  - name good decisions with football language
- Higher difficulty should increase reading demands more than raw input speed:
  - pre-scan
  - first-touch direction
  - overload reading
  - weak-side access
- Feed game outcomes into the rest of the product:
  - blocked situations into quiz review
  - repeated mistakes into training-note prompts

## Synthesized Direction
1. Build a clearer round arc.
   - First 10 seconds: rhythm and spacing.
   - Last 10 seconds: aggressive chance creation and finishing.
2. Reward the full football sequence.
   - Safe pass to stretch.
   - Killer pass to break.
   - Final action to finish.
3. Turn failure into immediate coaching.
   - Label the reason.
   - Suggest one adjustment.
   - Encourage instant retry.
4. Make spatial understanding visible.
   - Open side
   - closed lane
   - pressure source
   - successful switch

## Suggested Implementation Order
1. Add contextual prompts and failure labels in the current game loop.
2. Add rotating defender behavior states and pass-efficiency decay.
3. Improve presentation for chance moments and end-of-run coaching summary.
4. Connect repeated failure patterns to quiz or note follow-up.

## Product Intent
- The mini game should stay a retention feature, but it becomes stronger when it reinforces football learning rather than acting like a detached arcade mode.
- The best version is a repeatable "read space, act fast, learn one thing" loop.
