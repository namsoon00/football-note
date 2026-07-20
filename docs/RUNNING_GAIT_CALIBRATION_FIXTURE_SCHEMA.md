# Running Gait Calibration Fixture Schema

The offline gait calibration evaluator reads two JSON files: one ground-truth
fixture and one prediction input. Ground truth uses the flat fixture schema
below. Predictions can use either the same flat schema or real
`[RunningLiveSession]` debug-log output from `running_live_coach_screen`.

```json
{
  "schemaVersion": 1,
  "events": [
    {
      "timestampMs": 120,
      "side": "left",
      "type": "touchdown"
    },
    {
      "timestampMs": 240,
      "side": "left",
      "type": "toeOff"
    }
  ]
}
```

Fields:

- `schemaVersion`: optional integer metadata for fixture producers.
- `events`: required array sorted by nondecreasing `timestampMs`.
- `timestampMs`: required non-negative integer event timestamp in
  milliseconds from the start of the analyzed clip.
- `side`: required foot side, either `left` or `right`.
- `type`: required gait event type, either `touchdown` or `toeOff`.

Validation rules:

- The root value must be an object containing an `events` array.
- Events must be sorted by nondecreasing `timestampMs`.
- Duplicate events with the same `timestampMs`, `side`, and `type` are rejected.
- Unknown sides, event types, missing fields, negative timestamps, and
  non-integer timestamps are rejected before evaluation.

## Real RunningLive Log Predictions

Debug builds of `running_live_coach_screen` emit cumulative session snapshots:

```text
I/flutter: [RunningLiveSession] {"sessionId":"running-...","events":{"timeline":[...]}}
```

Pass the captured log file directly as `--predictions`. The evaluator:

- extracts only lines containing `[RunningLiveSession]`;
- selects one `sessionId`;
- merges the cumulative `events.timeline` arrays for that session;
- sorts merged events by `timestampMs`;
- deduplicates repeated cumulative events with identical `timestampMs`, `side`,
  `type`, and diagnostic payload;
- rejects repeated event keys when diagnostic payloads conflict, so conflicting
  data is not silently hidden.

If a log contains multiple sessions, provide the one to evaluate:

```sh
dart bin/running_gait_calibration_evaluator.dart \
  --ground-truth path/to/ground_truth.json \
  --predictions path/to/running_live_debug.log \
  --prediction-session-id running-1784592000000000 \
  --tolerance-ms 80 \
  --pretty
```

RunningLive session logs use a session-relative value for
`events.timeline[].timestampMs`, compatible with fixtures whose clip starts at
the beginning of the camera session. They also include `timestamp`,
`absoluteTimestampMs`, and `confidence` for diagnostics; omit those extra fields
when creating a minimal flat prediction fixture.

## Live Temporal Readiness

The live coach targets a 50 ms (20 Hz) gait-analysis cadence. Native MediaPipe
inference remains serialized, so a slower device is never treated as if it had
processed frames it skipped. Contact transitions are confirmed with debounce,
but the logged event keeps the first observed transition timestamp rather than
adding debounce latency to the label being evaluated.

For a calibration candidate, retain the matching `end` session log and inspect
`metrics.analyzedFrameIntervalMs.p95`, `metrics.averageConfidence.timing`, and
`metrics.averageConfidence.sideView`. Gaps above 90 ms reduce timing confidence;
if the resulting timing confidence is too low, cadence and contact-duration
metrics remain unavailable. This is a capture-readiness signal, not expert
validation of touchdown or toe-off timing.

Use the same side-view recording for human labels and the app log. Do not pair
labels from a separately exported or trimmed clip unless its zero timestamp is
explicitly aligned to `events.timeline[].timestampMs`.

Run the evaluator:

```sh
dart bin/running_gait_calibration_evaluator.dart \
  --ground-truth path/to/ground_truth.json \
  --predictions path/to/predictions.json \
  --tolerance-ms 80 \
  --pretty
```

Within each `(side, type)` group, matching preserves event order and maximizes
the number of one-to-one matches within the tolerance. Among solutions with
the same match count, it minimizes total absolute timing error. Remaining ties
use a fixed earlier-ground-truth traversal order, so matching is deterministic.

## Quality Gate Thresholds

The report always includes `qualityGate.passed` and
`qualityGate.violations`. With no thresholds configured, the gate passes and
the violation list is empty. Configure any combination of thresholds:

```sh
dart bin/running_gait_calibration_evaluator.dart \
  --ground-truth path/to/ground_truth.json \
  --predictions path/to/running_live_debug.log \
  --prediction-session-id running-1784592000000000 \
  --tolerance-ms 80 \
  --min-ground-truth-events 20 \
  --min-overall-precision 0.95 \
  --min-overall-recall 0.95 \
  --min-overall-f1 0.95 \
  --max-timing-mae-ms 25 \
  --max-timing-p95-ms 60 \
  --min-touchdown-precision 0.95 \
  --min-touchdown-recall 0.95 \
  --min-toe-off-precision 0.95 \
  --min-toe-off-recall 0.95 \
  --pretty
```

Threshold semantics:

- Numeric thresholds must be finite; `NaN` and positive or negative infinity
  are rejected as CLI usage errors.
- Minimum thresholds are inclusive: the actual value must be `>=` the threshold.
- Maximum timing thresholds are inclusive: the actual value must be `<=` the
  threshold.
- Timing MAE and P95 are computed from matched events only. If no events match
  and a timing threshold is configured, that threshold fails as unavailable.
- The evaluator checks every configured threshold and reports every violation.
- A quality-gate failure prints the JSON report and exits with status `2`.
- CLI usage errors still exit `64`, malformed input still exits `65`, and file
  read failures still exit `66`.

## Sample Video Warning

The bundled running-coach sample videos are pipeline smoke tests only. They are
not expert-labeled ground truth and must not be cited as expert validation for
gait timing, touchdown, or toe-off accuracy.
