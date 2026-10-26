# Scan Pass directly authored first-touch sample

## What ships

The Scan Pass actual-match viewer overflow menu contains **Directly authored
sample** (`직접 제작 샘플`, `直接作成サンプル`). It opens one fictional 8.2-second
educational reconstruction. Three blue attackers and two red defenders remain
visible in a fixed context view while a synchronized close-up shows the central
receiver, the approaching defender, both feet, body facing and ball.

This sample is manually designed motion. It is not captured tracking, an AI
measurement, coach-certified footage, or a reconstruction of any named player.
It is not part of `RealMatchReplayData`, the 25-scene catalog, or any replay
source manifest. All existing files under `assets/scan_pass_replay/` remain the
actual-match observation assets.

## Editable data schema

The asset is
`assets/scan_pass_authored/first-touch-open-side.json`; its pure Dart parser and
sampler are in `lib/domain/scan_pass/authored_touch_sample.dart`.

The top-level schema contains:

- `schemaVersion`, `id`, `kind`, `duration`, `sharedUntil`, `playbackRate` and
  fixed metric `contextBounds`;
- an explicit `source` declaration for manual authorship, fictional players,
  and the absence of tracking, AI measurement and coach certification;
- five stable player identities with team, number and teaching role;
- `sharedMotion` and `sharedEvents` for the identical lead-in through 3.20 s;
- `continuations.openSide` and `continuations.pressureSide`, each with player
  pose tracks, ball track, events, phase markers and asserted plant windows.

Every player pose keyframe stores time, ground/root position, body-facing angle,
and separate left/right-foot positions in the same metre coordinate system as
the ball. Ball keyframes store XYZ and accumulated rotation. Player poses use
deterministic cubic easing, shortest-angle body interpolation and exact holds
when a planted foot repeats. The ball rolls linearly between contacts, so it
does not repeatedly stop at plotting points. Sampling clamps at
0.0 and 8.2 seconds and never randomizes or mutates the common setup.

## Timeline and contacts

Attack is oriented toward increasing X. The open continuation sends the ball
toward negative Y; the defender approaches from positive Y. Copy identifies the
approaching defender instead of assigning a body-relative side while the
receiver turns. The initial passer,
central receiver, moving forward support, presser and covering defender all stay
inside `[-22, 21] × [-13, 13]` metres.

| Time | Authored event | Contact / result |
| ---: | --- | --- |
| 0.65 s | Initial pass | Passer right foot meets the ball; left support foot is fixed from 0.45–0.85 s. |
| 3.20 s | Shared first-contact state | Receiver left foot meets the arriving ball; right support foot is fixed from 2.95–3.45 s across both continuations. |
| 3.20–5.55 s | Open-side continuation | The left-foot touch sends the ball toward negative Y; the receiver turns and makes a short controlled carry. |
| 4.20 and 5.00 s | Controlled carry touches | Explicit right-foot contacts redirect the rolling ball; a separate wind-up precedes the forward pass. |
| 5.55 s | Forward pass | Receiver right foot meets the ball while the left support foot remains fixed from 5.00–5.80 s. |
| 7.70 s | Forward reception | The moving support player's left foot meets the ground pass. |
| 3.20–4.10 s | Pressure-side continuation | The same arrival is directed toward positive Y and the approaching defender. |
| 4.10 s | Steal | Presser left foot meets the ball while the right support foot is fixed from 3.80–4.10 s; possession changes from receiver to presser. |
| 4.50–8.20 s | Defender carry | Presser right foot takes the first carry contact and moves the ball more than seven metres away. |
| 5.50 and 6.80 s | Defender carry touches | Further explicit right-foot contacts keep the carry connected to the same visible ball. |

The two continuations illustrate only these declared fictional conditions. The
sample does not claim that one foot or touch direction is universally correct,
that the first touch alone determines a real match outcome, or that a coach has
reviewed the motion.

## Rendering and controls

`ScanPassAuthoredTouchSampleScreen` owns one animation clock. The context and
close-up painters receive the same sampled frame on every tick. Context uses the
asset bounds and keeps all five identities visible. The close-up follows the
receiver in a 6.4-metre-high crop, retaining the first-touch roll in frame. After
a steal it smoothly follows the defender in possession. Root, feet, ball, limbs and body
height share the same world-to-screen scale. Shoe centers therefore still meet
the ball at declared contacts. A planted-foot ring appears only during asserted
plant windows. After the long forward pass leaves the crop, the close-up stays
honestly on the receiver's follow-through while the context view carries the
ball to its receiver.

The illustrative body rig uses fixed 0.52-metre upper/lower leg segments,
balances the pelvis over the stance feet and lowers it for extended stances.
It preserves the authored shoe/contact coordinates while solving bent knees.
Torso depth keeps jerseys visible at cardinal facing angles. The turf viewport
clips drawing; off-camera players are culled as whole bodies. Cues respect text
scaling and the facing marker leaves shirt numbers unobscured.

The primary button plays, pauses or replays the entire sequence at a fixed
0.7× rate. The one comparison button switches continuation and resets to the
same time-zero state. Backgrounding pauses playback; route disposal cancels it;
the animation stops at the exact authored end. Closing returns to the paused
actual-match replay without changing its source time.

## Limitations

The poses are sparse teaching keyframes, not biomechanics, optical motion
capture or physics simulation. Interpolation is deterministic and bounded but
does not model muscle forces, collisions, ball deformation, turf friction or
uncertainty. The 2.5D human renderer derives torso, head and arms from each
authored root/facing pose; those derived body shapes make orientation readable
but are not additional measurements. Feet, root, ball, contacts, plant windows,
events, possession changes and phase times come directly from the asset.
