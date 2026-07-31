# Running Coach Portrait Sample Video Fixture

This asset is an internal regression fixture only:

```text
assets/videos/running_coach_portrait_side_view_sample.mp4
```

It is a 720x1280 H.264 MP4, rendered from the clothed beach side-view source
at `assets/videos/running_coach_reference_sample.mp4`. It is not packaged for
the user-facing recording guide and must not be presented as a recommended
running environment, a form reference, or a source of coaching scores.

## Render

```bash
.tmp/running_release_video_venv/bin/python \
  scripts/generate_running_coach_portrait_sample.py
```

The script finds the median detected hip center once, reserves a little room in
front of the runner, then uses that fixed 9:16 crop so real lateral travel and
the lead shoe remain visible. It keeps the complete height, scales to
720x1280, applies a small unsharp mask, then uses macOS `avconvert` to write
an H.264 MP4. It requires the MediaPipe/OpenCV environment created by:

```bash
./scripts/test_running_release_video_fixtures.sh --keep-venv
```

## Acceptance Gate

The rendered asset was checked with the bundled Full Pose Landmarker in VIDEO
mode. At the generated 22.815fps, 25/25 sampled frames contained a full body,
lower body, and ankle/foot evidence. Median full-body confidence was `0.699`,
median ankle/foot confidence was `0.760`, and median native sharpness was
`0.01915`, above the mobile gate of `0.018`. The contact-window harness also
found 3 validated contacts with a `0.462` hip-motion ratio.

Re-run `./scripts/test_mediapipe_sample_videos.sh` after regenerating the
asset. This verifies pose, contact-window, motion, and dense-frame evidence;
it does not replace physical-device capture validation. Do not restore this
asset to the user-facing app until commercial-use rights, model consent, and
physical-device validation are all documented.
