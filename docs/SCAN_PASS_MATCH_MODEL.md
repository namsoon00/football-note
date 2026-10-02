# Scan Pass Match Decision Model

The Scan Pass feature is a local 4v3 decision game centered on #6 receiving from #4 with #8 and #9 as support options. Scenarios are authored variants, not random dots: rear pressure from either side, retreating pressure, marked support, closing forward lanes, and return-pass opportunities.

The model uses normalized pitch coordinates and simple deterministic motion. It evaluates first touch state, elapsed decision time, defender movement, pass-lane sampling, pressure near the ball, recipient space, return-and-move angles, and the match objective. These values are game heuristics only; they are not real meters, calibrated seconds of football skill, xG, or pass-success percentages.

Scores are versioned separately from the previous route-picker history. Each completed challenge round records a score out of 100 from four rounded components: control 30, pressure escape 22, continuation 24, and context fit 24. Practice is never saved. A timeout records 0 for that round and moves to review.
