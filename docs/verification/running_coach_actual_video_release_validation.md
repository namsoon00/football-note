# Running Coach Actual Video Release Validation

## Scope

`./scripts/test_running_release_video_fixtures.sh` creates reproducible test
videos from the two real human-runner clips already bundled with the app:

- `assets/videos/running_coach_reference_sample.mp4`
- `assets/videos/running_coach_mistake_sample.mp4`

The script does **not** claim that it has newly recorded a runner or performed
a physical-device camera test. It builds transformed fixtures from existing
real-video frames and writes all generated MP4 files and reports under
`.tmp/running-release-video-validation/`.

## Fixture Matrix

| Fixture | Source | Input condition | Required decision |
| --- | --- | --- | --- |
| `portrait_reference_full_body` | beach side-view sample | 9:16, full body | Allow pose scoring only with sufficient full-body evidence. |
| `portrait_track_full_body` | track side-view sample | 9:16, full body | Allow pose scoring only with sufficient full-body evidence. |
| `portrait_lower_body_cropped` | beach side-view sample | 9:16, lower third removed | Reject precise scoring because lower-body evidence is missing. |
| `portrait_ankle_occluded` | beach side-view sample | 9:16, lower-leg/ankle foreground occlusion | Reject precise scoring when ankles/feet are not confidently visible. |
| `portrait_strong_motion_blur` | beach side-view sample | 9:16, strong horizontal blur | Reject precise scoring when image sharpness is below the mobile analyzer's fixed sharpness gate. |

The source SHA-256 digest is placed in `fixture_manifest.json` and verified by
the analyzer so that a report can be traced to the bundled sample used. The
generated MP4 SHA-256 digest is also recorded so stale or edited derived
fixtures can be spotted in the release report.

## Command

```bash
./scripts/test_running_release_video_fixtures.sh
```

The runner creates an isolated MediaPipe/OpenCV environment using the same
versions as `scripts/test_mediapipe_sample_videos.sh`, then invokes the iOS
bundled `ios/Runner/pose_landmarker_lite.task` in MediaPipe Tasks `VIDEO` mode.
The report is written to:

```text
.tmp/running-release-video-validation/release_validation_report.json
```

Logs are written to:

```text
.tmp/running-release-video-validation/logs/pip_install.log
.tmp/running-release-video-validation/logs/release_validation.log
```

`--output-dir` is intentionally restricted to a path under `.tmp/`. Generated
MP4 files, JSON reports, and logs are release-validation artifacts and should
not be committed.

Exit codes:

- `0`: every fixture produced its expected allow/reject decision.
- `2`: a fixture was allowed or rejected contrary to the expected decision.
- non-zero otherwise: setup, video, model, or report failure.

`./scripts/verify.sh` runs only the fast contract check for these scripts. It
does not run the MP4 analysis, because it downloads a Python MediaPipe runtime
and is intentionally a separate release-validation command.

## What a Passing Report Means

A passing report means the bundled `.task` model can be executed in MediaPipe
Tasks `VIDEO` mode against actual human-runner pixels in the supplied portrait
transformations. It also means the test quality gate found enough full-body and
motion evidence in the reference portrait fixtures, while blocking precise
scoring for intentionally incomplete, ankle-obscured, or blurred inputs.

The blur check mirrors the uploaded-video analyzers on both mobile platforms:
it samples the central 80% by 36% runner band at `96x64` without smoothing,
converts it to luma, and uses the median Laplacian variance across coarse
frames. The calibrated minimum is `0.018`. This is a conservative safeguard
for the tested input format, not a universal camera-quality certification.

It does **not** label either sample as a technically correct or incorrect
sprint, and it is not a biomechanics accuracy study.

## Release Decision

The automated verdict is deliberately `CONDITIONAL_NOT_DEVICE_APPROVED`, even
when every fixture passes. It is evidence for video-input regression safety,
not a launch approval.

Release approval still requires recorded evidence from at least one physical
iPhone and one physical Android phone for:

1. Rear-camera portrait capture, side-view 5-10 second running clip.
2. Video upload and post-analysis, including an upright overlay and full-body
   framing decision.
3. Live coaching with a fully visible runner, partial lower-body occlusion,
   and a runner entering/leaving the frame.
4. Indoor and outdoor lighting, with analyzed FPS, processing time, dropped
   frames, thermal behavior, and user-visible coaching stability captured.

Until those measurements are collected from the native camera/plugin path,
the running coach should not be described as ready for paid release.

## Latest Executed Result

Executed on 2026-07-22 with the bundled model and the generated fixtures.

| Fixture | Pose evidence | Quality-gate result |
| --- | --- | --- |
| `portrait_reference_full_body` | 30/30 full-body frames, median confidence 0.839 | Allowed as expected; median native sharpness `0.02384`. |
| `portrait_track_full_body` | 29/29 full-body frames, median confidence 0.812 | Allowed as expected; median native sharpness `0.07163`. |
| `portrait_lower_body_cropped` | 0 full-body and 0 lower-body frames | Rejected as expected. |
| `portrait_ankle_occluded` | 0 full-body and 0 lower-body frames | Rejected as expected. |
| `portrait_strong_motion_blur` | 30/30 full-body frames, median confidence 0.853 | Rejected as expected; median native sharpness `0.01497` is below `0.018`. |

The blurred fixture still produces confident pose landmarks, so pose confidence
alone is not a sufficient blur safeguard. The fixed native-aligned sharpness
gate blocks this fixture before precise running metrics are returned.

**Current automated verdict: CONDITIONAL_NOT_DEVICE_APPROVED.** The generated
fixture suite now passes, but that does not replace the physical-device
validation listed above. The running coach should not be described as ready for
paid release until the iPhone and Android camera, upload, overlay, thermal, and
latency checks are recorded.
