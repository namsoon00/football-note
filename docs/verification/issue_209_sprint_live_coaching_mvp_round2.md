## ✅ 실행 결과 요약
- 기준 일시: 2026-04-13
- 이번 라운드 범위: 스프린트 MVP 파이프라인을 실제 카메라 루프에 연결하고, 온디바이스 세션 계측 로그 및 localization/UI 연결을 추가
- 코드 레벨 검증 결과: `flutter test test/realtime_analysis/sprint_coaching/sprint_feature_calculator_test.dart test/realtime_analysis/sprint_coaching/sprint_realtime_coaching_pipeline_test.dart` 통과, touched files 대상 `flutter analyze ...` 통과
- 구현 상태: `SprintLiveCoachingScreen` 추가, `RunningCoachScreen`에서 진입 가능, `SprintLiveSessionMetricsCollector`가 세션 로그를 주기적으로 `[SprintLiveSession] {...}` JSON 형태로 출력

## 📱 실기기 / OS / 기종
- 실제 iPhone 실기기 실행: 미완료
- 현재 확인된 환경: macOS desktop / Chrome만 `flutter devices`에 연결됨
- 차단 상태: `flutter devices`에서 `순태의 iPhone` 무선 탐색 오류(`code -27`)가 발생했고 유선 연결/Developer Mode 활성 상태의 실기기 세션은 확보되지 않음

## ⚙️ FPS / 처리시간 / 프레임 드랍
- 실제 측정값: 미기록
- 이번 라운드에서 추가된 런타임 로그 필드
  - `cameraInputFps`
  - `analyzedFps`
  - `averageProcessingTimeMs`
  - `skippedFrames.total / busy / throttled / invalidInput / analysisError`
  - `bodyNotVisibleRatio`
  - `feedbackChanges.count / perMinute`
  - `landmarkConfidenceDistribution`
  - `trackingConfidence`
  - `activeFeedbackKey / activeFeedbackText`
- 로그 출력 위치: `SprintLiveCoachingScreen._emitSessionLog()`에서 5초 주기 및 dispose 시점

```text
[SprintLiveSession] {
  "cameraInputFps": "...",
  "analyzedFps": "...",
  "averageProcessingTimeMs": "...",
  "skippedFrames": {
    "total": ...,
    "busy": ...,
    "throttled": ...,
    "invalidInput": ...,
    "analysisError": ...
  },
  "bodyNotVisibleRatio": "...",
  "feedbackChanges": {
    "count": ...,
    "perMinute": "..."
  },
  "landmarkConfidenceDistribution": {
    "0.0-0.2": ...,
    "0.2-0.4": ...,
    "0.4-0.6": ...,
    "0.6-0.8": ...,
    "0.8-1.0": ...
  }
}
```

## 🔥 발열 및 배터리 체감
- 실제 iPhone 실기기 검증 미실행으로 미기록
- 이번 단계에서는 발열/배터리 리포트를 남길 수 있도록 세션 로그와 discussion 포맷만 선반영

## 💬 실제 출력된 피드백 문장
- 몸 전체가 프레임 안에 보이도록 한 걸음만 더 조정해 주세요.
- 허리로 꺾지 말고 발목부터 상체를 조금 더 앞으로 유지해 주세요.
- 지면에서 밀어낸 뒤 무릎을 조금 더 강하게 앞으로 끌어올려 보세요.
- 좌우 리듬이 흔들리고 있어요. 접지 간격을 조금 더 일정하게 맞춰 보세요.
- 팔 스윙 좌우 차이가 커요. 뒤로 당기는 길이를 비슷하게 맞춰 보세요.
- 좋아요. 지금 리듬과 전경사를 유지한 채 그대로 밀고 나가세요.

## 👍 잘 동작한 조건
- 코드 경로 기준으로는 `camera -> ML Kit pose -> SprintPoseFrame -> SprintRealtimeCoachingPipeline -> localizationKey 기반 UI/TTS` 연결이 완료됨
- step event 검출은 기존 단순 sign change에서 아래 조건을 함께 보도록 보강
  - minimum step interval
  - hysteresis
  - ankle delta velocity
- synthetic test 기준 false positive 억제 사례
  - 발목 delta가 `±0.04` 수준으로 흔들리는 jitter는 step event로 집계되지 않음
  - 교차 자체는 있지만 400ms 간격의 느린 low-velocity crossover는 velocity threshold 조건에서 억제됨

## ⚠️ 실패한 조건 / 미검증 조건
- iPhone 실기기 기준 측면 촬영
- 약간 비스듬한 촬영
- 밝은 환경 / 일반 실내 조명
- 일부 랜드마크 가림 상황
- 짧은 10초 질주와 제자리 동작 비교
- 발열/배터리 체감

## 🧠 원인 분석
- 현재 환경에서는 실제 iPhone이 연결되지 않아 온디바이스 로그 수집 자체가 시작되지 못함
- `flutter devices`가 무선 탐색 오류(`code -27`)를 반환해 discussion에 요구된 실기기/OS/기종/FPS/발열 데이터는 확보되지 않음
- step detector는 false positive를 줄이기 위해 보수적으로 바뀌었고, 그 결과 실제 아주 느린 제자리 동작이나 비스듬한 촬영에서는 false negative가 늘어날 가능성이 남아 있음

## ➡️ 다음 수정 제안
- iPhone 실기기를 유선으로 연결하고 Developer Mode를 확인한 뒤, 아래 조건별로 discussion 208에 같은 포맷으로 누적
  - 측면 촬영 / 약간 비스듬한 촬영
  - 밝은 환경 / 일반 실내 조명
  - 일부 랜드마크 가림
  - 10초 질주 / 제자리 동작 비교
- 실기기 로그를 본 뒤 아래 튜닝 포인트를 우선 조정
  - `_minimumAnalysisInterval`
  - `minimumStepEventInterval`
  - `stepDetectionHysteresis`
  - `minimumStepDetectionVelocity`
- `skippedFrames.busy` 비율이 높으면 detector sampling 또는 해상도 fallback을 추가 검토
