## ✅ 1. 실행 결과 요약
- 실제 디바이스 실행 여부: 미실행
- 실행 환경 (iOS / Android / 에뮬레이터): macOS 로컬에서 `flutter test`, `flutter gen-l10n`, `flutter analyze`로 코드 레벨 검증만 수행
- 실행 시 문제 여부: `flutter test test/realtime_analysis/sprint_coaching` 3건과 `./scripts/verify.sh`는 통과. 다만 `SprintLiveCoachingService` / `SprintRealtimeCoachingPipeline`는 아직 `RunningLiveCoachScreen`의 실제 카메라 루프에 연결되지 않아 실기기 실시간 동작은 검증되지 않음

```text
검증 대상
- lib/application/sprint_live_coaching_service.dart
- lib/realtime_analysis/sprint_coaching/*
- test/realtime_analysis/sprint_coaching/*
```

---

## 🧠 2. 포즈 추출 상태
- 사용 라이브러리 (MediaPipe / ML Kit 등): 현재 앱의 실시간 카메라 입력 경로는 `google_mlkit_pose_detection` 기반이며, 스프린트 MVP는 그 입력을 받을 도메인 모델(`SprintPoseFrame`)과 분석 파이프라인만 구현된 상태
- landmark 추출 성공 여부: 실제 카메라-스프린트 경로는 아직 미연결, 이번 검증에서는 synthetic landmark 프레임을 주입해 파이프라인 동작만 확인
- confidence 값 사용 여부: 사용 중. `SprintPipelineConfig.minimumLandmarkConfidence = 0.45` 미만 랜드마크는 입력 단계에서 제거
- 프레임별 안정성: `SprintLandmarkSmoother`의 EMA(`smoothingFactor = 0.34`)와 최근 윈도우 기반 평균으로 단일 프레임 흔들림을 줄이는 구조는 들어가 있음. 다만 실카메라 입력에서의 jitter는 아직 미실측

---

## ⚡ 3. 성능
- 평균 FPS: 미측정
- 프레임 드랍 여부: 미측정
- 발열 상태: 미측정
- 저사양 기기 예상 성능: 스프린트 MVP 전용 카메라 루프가 아직 UI에 연결되지 않아 실기기 추정의 신뢰도가 낮음. 참고로 기존 `RunningLiveCoachScreen`은 `350ms` 간격 처리라 실분석 루프가 약 `2.9Hz` 수준인데, 이 수치는 스프린트 MVP 성능 수치로 간주하면 안 됨

```dart
// lib/realtime_analysis/sprint_coaching/sprint_realtime_coaching_pipeline.dart
final features = _featureCalculator.calculate(normalizedFrames);
final stateEstimate = _stateEstimator.estimate(
  rawFrames: rawFrames,
  normalizedFrames: normalizedFrames,
  features: features,
  config: config,
  now: now,
  lastFeedbackAt: _lastFeedbackAt,
);
final nextFeedback = _resolveFeedback(
  now: now,
  features: features,
  stateEstimate: stateEstimate,
);
```

---

## 📊 4. Feature 계산 결과
아래 항목 각각에 대해:
- 계산 방식
- 실제 값 예시
- 문제 여부

- trunk angle
  계산 방식: 어깨 중심의 `dx/dy`를 이용해 수직 대비 기울기 각도를 계산
  실제 값 예시: synthetic 검증 시 평균 `11.31°`
  문제 여부: 계산 자체는 정상. 다만 실제 측면 카메라 입력에서의 절대값 보정은 아직 미검증

- knee drive height
  계산 방식: 좌우 무릎 중 더 높게 올라온 값을 body scale 기준으로 정규화하고, 최근 윈도우 상위 1/3 평균을 사용
  실제 값 예시: synthetic 검증 시 `0.41`
  문제 여부: 계산 정상. 한쪽 무릎만 사용해도 값이 나오므로 실제 가림 상황에서는 과대평가될 수 있음

- step rhythm
  계산 방식: 좌우 발목 `x` 순서가 뒤바뀌는 시점을 step event로 보고, event 간 간격 평균/표준편차 계산
  실제 값 예시: synthetic 검증 시 평균 step interval `250ms`, cadence `240spm`, std `0ms`
  문제 여부: 계산 정상. 하지만 단순 sign change 기반이라 측면 각도가 틀어지면 false event 가능성 있음

- arm swing symmetry
  계산 방식: 좌우 손목의 수평 excursion 평균 차이를 큰 쪽 excursion으로 나눈 비율
  실제 값 예시: synthetic 검증 시 `0.043`
  문제 여부: 계산 정상. 손목 landmark 흔들림에 민감할 수 있어 실기기 jitter 튜닝 필요

---

## 🧩 5. 룰 엔진 동작
- 현재 적용된 룰 목록
  - body not visible
  - lean forward more
  - drive knee higher
  - keep rhythm steady
  - balance arm swing
  - keep pushing
- 각 룰의 threshold
  - body not visible: 코어 랜드마크 충족 실패 또는 tracking confidence `< 0.58`
  - lean forward more: trunk angle `< 8°`
  - drive knee higher: knee drive height `< 0.24`
  - keep rhythm steady: step interval std `> 110ms`
  - balance arm swing: arm asymmetry ratio `> 0.18`
- cooldown 방식: 피드백 변경 후 `2초` 동안 다른 룰로 즉시 전환하지 않음. 단, `bodyNotVisible`은 cooldown을 무시하고 즉시 우선 적용
- 우선순위 처리 방식: `body not visible -> trunk -> knee -> rhythm -> arm -> positive reinforcement` 순서의 단일 피드백 선택

```dart
// lib/realtime_analysis/sprint_coaching/sprint_feedback_rule_engine.dart
if ((features.trunkAngleDegrees ?? double.infinity) <
    config.minimumTrunkAngleDegrees) {
  return const SprintFeedbackMessage(
    code: SprintFeedbackCode.leanForwardMore,
    priority: 90,
    localizationKey: 'runningCoachSprintCueLeanForward',
    debugLabel: '상체를 조금 더 앞으로 유지하세요',
  );
}
```

---

## 💬 6. 코칭 피드백 결과
- 실제 출력되는 피드백 문장 리스트
  - 몸 전체가 화면에 보이게 해주세요
  - 상체를 조금 더 앞으로 유지하세요
  - 무릎을 조금 더 강하게 들어보세요
  - 리듬을 일정하게 유지하세요
  - 팔 스윙 균형을 맞춰보세요
  - 좋아요. 지금 리듬을 유지하세요
- 피드백 발생 조건: `SprintFeedbackRuleEngine`의 threshold 위반 시 상위 우선순위 1개만 선택
- 문제점 (있다면): 현재 문장은 `debugLabel`로만 정의되어 있고, `localizationKey`에 해당하는 `lib/l10n/*.arb` 문자열과 실제 UI 연결은 아직 없음

---

## ⚠️ 7. 에러 및 예외 처리
- 사람 인식 실패 시 동작: `lowConfidence || !bodyFullyVisible`이면 `bodyNotVisible` 피드백으로 강등
- 신체 일부 가려짐 대응: 코어 랜드마크 누락 시 정상 분석 대신 low confidence 상태로 처리
- 카메라 위치 문제 대응: 실제 스프린트 UI 경로 미연결로 별도 대응 없음. 기존 러닝 라이브 코치 화면에는 프레이밍 가이드는 있으나 스프린트 MVP와는 아직 분리 상태

---

## 🏗 8. 코드 구조
- 전체 아키텍처 요약: `pose frame -> smoothing -> normalization -> feature calculation -> state estimation -> rule engine`
- 주요 클래스 구조
  - `SprintLiveCoachingService`: 앱 진입 facade
  - `SprintRealtimeCoachingPipeline`: 실시간 파이프라인 orchestration
  - `SprintLandmarkSmoother`: EMA smoothing
  - `SprintPoseNormalizer`: hip center/body scale 기준 정규화
  - `SprintFeatureCalculator`: trunk/knee/rhythm/arm feature 계산
  - `SprintStateEstimator`: running detection, confidence, visibility, cooldown 계산
  - `SprintFeedbackRuleEngine`: 우선순위 기반 피드백 선택
- realtime pipeline 흐름: 현재는 서비스/도메인/분석 계층만 존재하고, presentation 계층과의 실제 연결은 아직 미완료

---

## 🔧 9. 개선 필요 사항
- 가장 큰 문제는 스프린트 MVP 파이프라인이 실제 카메라 화면과 연결되지 않았다는 점
- `runningCoachSprintCue*` localization key가 ARB에 아직 없어 실제 사용자 문구 표면이 완성되지 않음
- 성능/FPS/발열/실기기 안정성 데이터가 없어 “실시간 MVP” 품질을 판단할 근거가 부족함
- step event 검출이 단순 sign change 기반이라 비정상적인 카메라 각도나 가림에 취약함

---

## 🚀 10. 다음 단계 제안
- 민첩성 코칭 확장 방향: 공통 pose extraction / smoothing / normalization 계층은 유지하고, 민첩성 전용 feature pack과 event detector를 별도 추가
- ML 모델 도입 위치: 현재 rule engine 앞단의 `feature extraction` 이후 또는 세션 종료 후 report ranking 단계가 도입 지점으로 적절
- 성능 개선 방향: 카메라 프레임 샘플링 전략, landmark downsampling, 저사양 fallback, 실제 기기별 FPS 계측 로그를 우선 추가

---

## 로그 일부
```text
$ flutter test test/realtime_analysis/sprint_coaching
✅ SprintRealtimeCoachingPipeline keeps the active cue until cooldown expires
✅ SprintRealtimeCoachingPipeline falls back to body-visible guidance when landmarks disappear
✅ SprintFeatureCalculator calculates stable sprint metrics from normalized frames
🎉 3 tests passed.

$ ./scripts/verify.sh
==> flutter pub get
==> flutter gen-l10n
==> flutter analyze
No issues found! (ran in 2.9s)
==> minimal verification complete (skipping flutter test/run)
```
