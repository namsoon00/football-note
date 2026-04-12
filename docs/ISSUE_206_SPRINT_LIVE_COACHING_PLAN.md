# Issue #206: 스프린트 실시간 코칭 MVP 설계

## 목표 정리

- 최종 목표: 스프린트 + 민첩성 실시간 코칭
- 1차 MVP: 측면 촬영 기반 스프린트 실시간 코칭
- 실시간 판정 구조: `pose extraction -> feature calculation -> state estimation -> rule engine`
- 실시간 경로에서는 LLM 미사용
- LLM은 세션 종료 후 리포트 / 설명 확장 포인트로만 열어 둠

## MVP에서 우선 다룰 코칭 포인트

- 몸통 기울기 (`trunk angle`)
- 무릎 드라이브 높이 (`knee drive height`)
- 스텝 리듬 (`step interval / cadence`)
- 팔 스윙 좌우 균형 (`arm swing symmetry`)

## 포즈 추출 선택: ML Kit Pose Detection

### 선택 이유

- 현재 앱이 이미 `camera` + `google_mlkit_pose_detection` 조합을 사용 중이라 초기 통합 비용이 가장 낮다.
- Flutter에서 온디바이스 실시간 추론 연결이 안정적이고, 프레임 단위 랜드마크를 지속적으로 받을 수 있다.
- 1차 MVP의 핵심은 최고 정확도보다 "프레임 드랍이 적고 결과가 흔들리지 않는 것"인데, 기존 코드와 팀 맥락을 감안하면 ML Kit이 더 빠르게 운영 가능한 선택이다.
- 추후 민첩성 코칭으로 확장할 때도 공통 포즈 입력 계층 위에 feature / rule pack을 추가하는 구조로 확장 가능하다.

### MediaPipe 대비 트레이드오프

- ML Kit 장점
  - 현재 코드베이스와 가장 잘 맞는다.
  - Flutter 연동 난이도가 낮다.
  - 온디바이스 실시간 MVP를 빨리 올릴 수 있다.
- ML Kit 단점
  - 모델과 후처리 제어 범위가 MediaPipe보다 좁다.
  - 향후 복잡한 민첩성 이벤트 추적이나 커스텀 튜닝에서는 제약이 생길 수 있다.
- MediaPipe 장점
  - 파이프라인 제어 폭이 넓고, 장기적으로 커스텀 분석 확장성이 좋다.
- MediaPipe 단점
  - Flutter 통합 복잡도와 유지보수 비용이 더 크다.
  - 이번 MVP 기준으로는 도입 비용 대비 이점이 크지 않다.

### 결론

- `Phase 1~3`은 ML Kit 기준으로 구현한다.
- 민첩성 2단계에서 추적 품질이나 이벤트 정밀도가 병목이 되면 MediaPipe 전환 여부를 재검토한다.

## 전체 아키텍처

```text
presentation
  RunningLiveCoachScreen
    -> camera preview
    -> skeleton overlay
    -> text feedback / metric rail

application
  SprintLiveCoachingService
    -> app-facing facade
    -> coordinates realtime pipeline lifecycle

domain
  SprintPoseFrame
  SprintFeatureSnapshot
  SprintStateEstimate
  SprintRealtimeCoachingState
  SprintFeedbackMessage

realtime_analysis
  SprintLandmarkSmoother
  SprintPoseNormalizer
  SprintFeatureCalculator
  SprintStateEstimator
  SprintFeedbackRuleEngine
  SprintRealtimeCoachingPipeline

data
  MlKitSprintPoseDetector (Phase 2 implementation target)
    -> camera frame to pose landmarks adapter
```

## 제안 폴더 구조

이번 단계에서는 전체 구조를 한 번에 다 옮기지 않고, 기존 기능은 유지한 채 아래 구조로 스캐폴드를 추가한다.

```text
lib/
  application/
    sprint_live_coaching_service.dart
  domain/
    entities/
      sprint_pose_frame.dart
      sprint_realtime_coaching_state.dart
  realtime_analysis/
    sprint_coaching/
      sprint_pipeline_config.dart
      sprint_landmark_smoother.dart
      sprint_pose_normalizer.dart
      sprint_feature_calculator.dart
      sprint_state_estimator.dart
      sprint_feedback_rule_engine.dart
      sprint_realtime_coaching_pipeline.dart
  presentation/
    screens/
      running_live_coach_screen.dart      // 기존 화면 재사용, 단계별로 연결
  data/
    // Phase 2에서 ML Kit adapter 추가
```

## 필요한 패키지 / 플러그인

현재 MVP 계획 기준으로 신규 런타임 의존성 없이 아래 패키지로 충분하다.

- `camera`
  - 카메라 프리뷰 / 이미지 스트림 입력
- `google_mlkit_pose_detection`
  - 온디바이스 포즈 랜드마크 추출
- `flutter_tts`
  - 후속 단계에서 음성 코칭 유지 가능

선택 사항:

- 별도 상태관리 패키지는 이번 단계에서 추가하지 않는다.
- 현재 프로젝트 패턴에 맞춰 `screen-local state + application service`로 먼저 구현하고, 상태가 커지면 이후 `ChangeNotifier` 또는 `Riverpod`로 이동을 검토한다.

## 실시간 분석 파이프라인 설계

### 단계

1. `camera frame input`
2. `pose landmarks extraction`
3. `confidence filtering`
4. `landmark smoothing`
5. `body-scale normalization`
6. `feature extraction`
7. `event/state estimation`
8. `rule-based feedback generation`
9. `UI overlay / text feedback output`

### 각 클래스 책임

- `SprintLiveCoachingService`
  - 화면에서 들어오는 프레임/포즈 입력을 파이프라인에 전달
  - reset / lifecycle 관리
- `SprintRealtimeCoachingPipeline`
  - 전체 순서를 orchestration
  - window buffer / cooldown / active feedback 관리
- `SprintLandmarkSmoother`
  - EMA 기반 랜드마크 흔들림 완화
- `SprintPoseNormalizer`
  - hip center 기준 좌표 정렬
  - body scale로 나누어 기기 거리 차이 영향을 줄임
- `SprintFeatureCalculator`
  - trunk angle / knee drive / step interval / cadence / arm symmetry 계산
- `SprintStateEstimator`
  - running detected
  - acceleration phase detected
  - low confidence
  - body fully visible
  - feedback cooldown active
- `SprintFeedbackRuleEngine`
  - 단일 우선순위 피드백 선택
  - cooldown 중 피드백 흔들림 방지

## Feature Calculator 설계

### trunk angle

- shoulder center 와 hip center를 이용해 수직 대비 기울기를 계산
- MVP에서는 측면 촬영을 전제로 절대 기울기부터 사용
- 너무 upright 하면 "상체를 조금 더 앞으로 유지하세요"

### knee drive height

- hip 대비 가장 높이 올라온 무릎 위치를 body scale로 정규화
- 일정 윈도우에서 상위 구간 평균을 사용해서 순간 노이즈를 줄임

### step interval / cadence

- 좌우 발목의 상대 x 위치가 뒤바뀌는 시점을 step event 후보로 사용
- event 간 간격 평균과 표준편차로 cadence 와 rhythm stability를 계산

### arm swing symmetry

- 좌우 손목의 수평 excursion 평균을 비교
- 차이가 크면 asymmetry ratio 증가

## Rule Engine 설계

우선순위는 한 번에 하나의 피드백만 노출하는 방향으로 고정한다.

1. low confidence / body not visible
2. trunk angle correction
3. knee drive correction
4. step rhythm correction
5. arm swing balance correction
6. positive reinforcement (`keep pushing`)

정책:

- 프레임 하나로 바로 판정하지 않는다.
- 최근 윈도우 평균과 변동성을 함께 본다.
- cooldown 동안에는 새 피드백으로 바로 바꾸지 않는다.
- 단, `body not visible` 류 안내는 분석보다 우선하며 cooldown을 무시한다.

## MVP 화면 설계

기존 [lib/presentation/screens/running_live_coach_screen.dart](/Users/namsoon00/Devel/actions-runner/_work/football-note/football-note/lib/presentation/screens/running_live_coach_screen.dart)을 재사용하고, 점진적으로 아래 UI를 맞춘다.

- 전체화면 카메라 프리뷰
- skeleton overlay
- 중앙 안전 프레임
- 상단 1줄 피드백 배너
- 우측 metric rail
  - trunk
  - knee drive
  - cadence
  - arm balance
- 하단 상태 dock
  - tracking confidence
  - detected frames
  - voice coaching state

## 단계별 구현 TODO

### Phase 1

- ML Kit 포즈 입력 adapter 분리
- `SprintPoseFrame` 모델 연결
- debug skeleton overlay 를 새 pipeline 입력으로 붙이기
- 기존 live coach screen 에 mock / debug switch 없이도 동작 가능한 입력 경로 확보

### Phase 2

- smoothing / normalization 연결
- `SprintFeatureCalculator` 실제 값 검증
- trunk / knee / rhythm 우선 구현

### Phase 3

- `SprintFeedbackRuleEngine` 연결
- feedback priority / cooldown 정책 반영
- 기존 live cue UI 에 스프린트 전용 피드백 매핑

### Phase 4

- 프레임 샘플링 주기 최적화
- 저사양 fallback
- low confidence / partial body / permission / detector error 처리 강화
- 실기기 튜닝

## 민첩성 코칭 확장 포인트

- 공통 계층 유지
  - camera
  - pose extraction
  - confidence filtering
  - smoothing
  - normalization
- 모드별로 교체
  - feature calculator
  - state estimator
  - rule engine
  - UI copy / metric labeling

확장 예시:

- `SprintFeatureCalculator` -> `AgilityFeatureCalculator`
- `SprintFeedbackRuleEngine` -> `AgilityFeedbackRuleEngine`
- 공통 pipeline 은 유지하고 mode pack 만 주입

## 세션 후 LLM 리포트 확장 포인트

실시간 경로와 분리해서 아래 순서로 붙인다.

1. 세션 중 저장
   - feature summary
   - feedback timeline
   - confidence summary
2. 세션 종료 후
   - 구조화된 session summary 생성
3. 선택적으로 LLM 호출
   - 사람 친화적 설명
   - 훈련 포인트 요약
   - 다음 세션 체크리스트

중요 원칙:

- LLM 입력은 `raw video` 가 아니라 `요약 feature / state / event` 여야 한다.
- 실시간 코칭 성능과 안정성은 LLM 경로에 의존하지 않는다.

## 이번 커밋 범위

- 설계 문서 추가
- 스프린트 실시간 코칭 파이프라인 스캐폴드 추가
- 기존 라이브 코칭 기능은 유지
- 다음 단계에서 ML Kit adapter 와 UI 연결을 순차적으로 진행
