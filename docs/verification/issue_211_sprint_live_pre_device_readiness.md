## 이번 라운드 구현 범위
- 스프린트 synthetic 시나리오를 정상 스프린트, 느린 조깅, 제자리 러닝, landmark 일부 누락, trunk angle 부족, knee drive 부족, rhythm 불규칙, arm swing 비대칭, step detector false positive/false negative 케이스까지 확장했습니다.
- `SprintLiveCoachingScreen`에 실기기 디버깅용 오버레이를 정리해 trunk angle, knee drive, cadence, step interval std, arm asymmetry, tracking confidence, body visibility 상태, active feedback key/text를 바로 확인할 수 있게 했습니다.
- `[SprintLiveSession]` 로그 포맷을 `start / periodic / end / feedback_changed / step_detected / body_not_visible_entered / body_not_visible_exited / analysis_skipped` 이벤트로 고정하고, 공통 상태/특징/피드백/계측 블록을 일관되게 남기도록 정리했습니다.

## 추가된 테스트 시나리오
- 정상 스프린트: `keepPushing` 유지와 trunk angle, knee drive, cadence, rhythm, arm asymmetry 안정 범위를 고정
- 느린 조깅: cadence가 sprint threshold 아래일 때 sprint feedback으로 승격되지 않는지 고정
- 제자리 러닝: hip travel 부족으로 runningDetected가 false로 유지되는지 고정
- landmark 일부 누락: partial visibility 진단과 `bodyNotVisible` feedback 고정
- trunk angle 부족: `leanForwardMore` feedback 고정
- knee drive 부족: `driveKneeHigher` feedback 고정
- rhythm 불규칙: `keepRhythmSteady` feedback과 std 초과 범위 고정
- arm swing 비대칭: `balanceArmSwing` feedback과 asymmetry 초과 범위 고정
- step detector false positive: hysteresis 아래 jitter가 step event로 집계되지 않는지 고정
- step detector false negative: low velocity / minimum interval rejection count가 남는지 고정

## 디버그 오버레이/로그 필드 요약
- 화면 디버그 오버레이
  - trunk angle
  - knee drive
  - cadence
  - step interval std
  - arm asymmetry
  - tracking confidence
  - body visibility 상태
  - active feedback key / text
- 세션 로그 공통 블록
  - `state`: body visibility status, visible landmarks, visible core landmarks, body visibility ratio, tracking confidence, stable frames, hip travel ratio, runningDetected, accelerationPhaseDetected, feedbackCooldownActive
  - `features`: trunk angle, knee drive height, cadence, step interval, step interval std, arm asymmetry
  - `stepDetector`: lead switches, accepted events, rejected low velocity, rejected minimum interval
  - `feedback`: active key, localized text, cooldown suppression
  - `metrics`: camera FPS, analyzed FPS, average processing time, skipped frame breakdown, body-not-visible ratio, feedback change frequency
- 세션 이벤트 로그
  - `start`
  - `periodic`
  - `end`
  - `feedback_changed`
  - `step_detected`
  - `body_not_visible_entered`
  - `body_not_visible_exited`
  - `analysis_skipped`

## Config 정리 내용
- `SprintPipelineConfig` 기준으로 아래 threshold/timing을 일원화했습니다.
  - `minimumAnalysisInterval`
  - `minimumTrunkAngleDegrees`
  - `minimumKneeDriveHeight`
  - `maximumStepIntervalStdMs`
  - `maximumArmAsymmetryRatio`
  - `minimumStepEventInterval`
  - `stepDetectionHysteresis`
  - `minimumStepDetectionVelocity`
  - `minimumLandmarkConfidence`
  - `minimumTrackingConfidence`
  - `minimumVisibleLandmarks`
  - `minimumBodyVisibilityRatio`
  - `minimumWindowFrames`
- preset 추가
  - `SprintPipelineConfig.conservative()`
  - `SprintPipelineConfig()` / balanced default
  - `SprintPipelineConfig.responsive()`

## 남아 있는 리스크
- 실제 iPhone/Android 실기기에서는 ML Kit landmark confidence 분포와 frame skip 패턴이 synthetic 입력과 다를 수 있습니다.
- 느린 조깅과 비스듬 촬영 경계에서는 cadence gate와 visibility gate가 false negative로 작동할 가능성이 남아 있습니다.
- `analysis_skipped` 이벤트는 reason별 rate-limit을 걸었지만, 기기 성능이 낮으면 로그량이 여전히 빠르게 늘 수 있습니다.
- TTS 과다 재생은 동일 feedback 반복을 줄였지만, 장시간 세션에서 최적의 repeat interval은 실기기 확인이 필요합니다.

## 실기기 연결 직후 바로 확인할 항목
- 측면 촬영에서 `body visibility`, `tracking confidence`, `active feedback`이 안정적으로 유지되는지 확인
- 비스듬 촬영에서 `body_not_visible_entered/exited`와 `feedback_changed` 빈도를 확인
- 밝은 환경과 실내 조명에서 landmark confidence 분포가 크게 달라지는지 확인
- 일부 가림에서 `body visibility status`가 partial로 떨어지고 복구 로그가 남는지 확인
- 10초 질주에서 cadence, step interval std, feedback change frequency가 과도하게 흔들리지 않는지 확인
- 제자리 동작과 느린 조깅에서 sprint feedback이 불필요하게 활성화되지 않는지 확인

## 실기기 테스트 체크리스트
- [ ] 측면 촬영
- [ ] 비스듬 촬영
- [ ] 밝은 환경
- [ ] 실내 조명
- [ ] 일부 가림
- [ ] 10초 질주
- [ ] 제자리 동작
- [ ] 느린 조깅
