## ✅ 실행 결과 요약
- 기준 일시: 2026-04-13
- 이번 라운드 범위: 실기기 검증 라운드를 바로 진행할 수 있도록 스프린트 실시간 MVP의 readiness / step detector / feedback stability 진단값을 보강하고, false positive 억제 테스트를 추가
- 코드 레벨 검증 목표
  - `step detector false positive / false negative` 원인 로그 확보
  - `feedback 변경 빈도`뿐 아니라 `cooldown`으로 눌린 전환 횟수까지 기록
  - `제자리 / 저속 동작`이 running으로 오인되지 않도록 보수적 running gate 추가

## 🔎 이번 라운드에 추가한 진단값
- 세션 로그 `[SprintLiveSession] {...}`에 아래 블록 추가
  - `readiness.bodyFullyVisible / visibleLandmarks / missingCoreLandmarks / stableFrames / hipTravelRatio / runningDetected`
  - `stepDetector.leadSwitches / acceptedEvents / rejectedLowVelocity / rejectedMinInterval`
  - `feedbackChanges.suppressedByCooldown`
- 화면 우하단 세션 카드에 아래 줄 추가
  - `준비 상태`
  - `스텝 판정`
  - `피드백 변경 빈도`의 `쿨다운 보류` 수치

## 🎯 보수적 튜닝 반영
- running 판정은 아래 둘 중 하나를 만족할 때만 true
  - `hipTravelRatio >= minimumRunningTravelRatio`
  - `detectedStepEvents >= minimumStepEventsForRunning` 이면서
    `cadence >= minimumRunningCadenceStepsPerMinute` 이고
    `hipTravelRatio >= minimumStepDrivenTravelRatio`
- 의도
  - 짧은 제자리 리듬이나 저속 제자리 동작이 `step event`만으로 sprint running으로 승격되는 false positive를 줄임
  - 실제 질주에서는 travel ratio 또는 cadence + 소폭 travel을 함께 보고 통과

## 📱 실기기 검증 체크리스트
- 우선순위 1: iPhone 유선 연결 확인
  - Finder / Xcode에서 기기 인식 확인
  - iPhone `Developer Mode` 활성 여부 확인
  - `flutter devices`에서 무선 오류 대신 유선 기기 식별 확인
- 우선순위 2: 최소 1회 측면 촬영 로그 확보
  - 후면 카메라
  - 측면 촬영
  - 5~10초 질주
  - `[SprintLiveSession]` JSON 1세트 이상 저장
- 우선순위 3: 실패 케이스 중심 로그 비교
  - 비스듬 촬영
  - 일부 가림
  - 제자리 / 저속 동작

## 📋 로그 확인 포인트
- 성능
  - `cameraInputFps`
  - `analyzedFps`
  - `averageProcessingTimeMs`
  - `skippedFrames.busy / throttled / invalidInput / analysisError`
- 가시성
  - `bodyNotVisibleRatio`
  - `readiness.visibleLandmarks`
  - `readiness.missingCoreLandmarks`
  - `readiness.stableFrames`
- UX 안정성
  - `feedbackChanges.count / perMinute`
  - `feedbackChanges.suppressedByCooldown`
- step detector
  - `stepDetector.leadSwitches`
  - `stepDetector.acceptedEvents`
  - `stepDetector.rejectedLowVelocity`
  - `stepDetector.rejectedMinInterval`

## 🧪 추가된 코드 테스트
- `SprintFeatureCalculator`
  - low velocity rejection count 검증
  - minimum interval rejection count 검증
- `SprintRealtimeCoachingPipeline`
  - landmark 일부 누락 시 visibility diagnostics 검증
  - `feedback cooldown` 중 suppressed switch 검증
  - 제자리 / 저속 동작이 running으로 승격되지 않는지 검증
- `SprintLiveSessionMetricsCollector`
  - 세션 로그 payload에 readiness / step detector / suppressed feedback 필드가 들어가는지 검증

## ➡️ 실기기 로그 확보 후 우선 튜닝할 값
- `_minimumAnalysisInterval`
- `minimumRunningTravelRatio`
- `minimumStepEventsForRunning`
- `minimumRunningCadenceStepsPerMinute`
- `minimumStepDrivenTravelRatio`
- `minimumStepEventInterval`
- `stepDetectionHysteresis`
- `minimumStepDetectionVelocity`
