/// Shared timing contract for live running gait analysis.
///
/// Fifty milliseconds gives contact-event processing a 20 Hz target while the
/// serialized native detector still applies backpressure on slower devices.
const runningLiveGaitTargetFrameInterval = Duration(milliseconds: 50);

/// Gaps beyond this reduce gait timing confidence instead of being treated as
/// equivalent to the live target cadence.
const runningLiveGaitMaximumFrameGap = Duration(milliseconds: 90);
