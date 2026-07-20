# Running Gait Calibration Fixture Schema

The offline gait calibration evaluator reads two JSON files: one ground-truth
fixture and one prediction fixture. Both files use the same schema.

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

Run the evaluator:

```sh
dart run bin/running_gait_calibration_evaluator.dart \
  --ground-truth path/to/ground_truth.json \
  --predictions path/to/predictions.json \
  --tolerance-ms 80 \
  --pretty
```

Matching is deterministic and one-to-one within each `(side, type)` group.
For each ground-truth event, the nearest unused prediction inside the tolerance
window is selected, with earlier predictions winning equal-error ties.
