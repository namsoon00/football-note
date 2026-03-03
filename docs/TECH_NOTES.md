# 태오의 노트 테크 노트

최종 갱신: 2026-03-03

## 1) 아키텍처 개요
- 기본 원칙: DDD 분리
- `domain`: 엔티티/리포지토리 인터페이스
- `application`: 유스케이스 서비스(훈련, 백업, 벤치마크, 프로필 등)
- `infrastructure`: Hive, RSS, 외부 API 연동
- `presentation`: 화면/위젯/상태 렌더링

## 2) 디렉토리 요약
- `lib/domain/entities`: `TrainingEntry`, `PlayerProfile`, `GameRankingEntry` 등
- `lib/domain/repositories`: 저장소 인터페이스
- `lib/application`: `TrainingService`, `DriveBackupService`, `BenchmarkService` 등
- `lib/infrastructure`: Hive 구현체, RSS/뉴스 구현체
- `lib/presentation/screens`: 탭별 주요 화면
- `lib/presentation/widgets`: 공통 UI, 상태 아이콘, 앱 배경 등

## 3) 데이터 저장/동기화
- 로컬 저장: Hive
- 주요 박스:
- `training_entries`
- `options`
- 백업:
- `TrainingService`의 add/update/delete 후 비동기 백업 트리거
- Google Drive API + 앱 옵션/엔트리 전체 동기화

## 4) 주요 서비스 책임
- `TrainingService`
- 일지 CRUD
- 최신 기록 조회(입력 기본값 보정에 사용)
- 백그라운드 백업 트리거
- `DriveBackupService`
- 로그인 상태 확인
- Drive 파일 생성/업데이트/복원
- `BenchmarkService`
- 외부 평균 데이터 refresh
- 연령 기반 평균치 제공
- `PlayerProfileService`
- 나이/구력 계산
- 통계 비교 가능 여부 판단

## 5) 화면별 구현 포인트
- `logs_screen.dart`
- 기록 목록/필터/삭제/상세 진입
- `entry_form_screen.dart`
- 자동저장
- 최근 기록 기반 시간/장소 기본값 적용
- `calendar_screen.dart`
- 월간 캘린더 + 날짜별 계획/일지 타임라인
- 날짜 선택 콜백으로 기록 추가 초기 날짜 연동
- 일지 스와이프 삭제(confirmDismiss)
- `stats_screen.dart`
- 기간 선택(DateRange)
- 기간 기준 코칭/그래프/비교
- 평균 비교 버튼 및 기간 버튼 스타일 정렬
- `news_screen.dart`
- 다중 채널/필터/번역 토글
- 인앱 브라우저 기사 열기
- `space_speed_game_screen.dart`
- 2 공격수/다수 수비수 게임 루프
- 조이스틱/패스 패드 입력 처리
- 패스 가이드 오버레이(카메라 이동 보정 포함)
- 레벨/랭킹 기록

## 6) 최근 반영된 UX/기능 결정
- 캘린더 일지 항목:
- 제목 줄: 훈련유형 + 시간 + 장소
- 중복 프로그램 줄 제거
- 설정 일반 섹션:
- 언어 셀렉트 타이틀 잘림 방지(최소 높이/패딩)
- 게임:
- 패스 직후 패서 즉시 전진 가속
- 공격수 간 충돌 튕김 제거(크로스)
- 게임 시간 20초
- 패스 가이드 선/원은 화면 이동 시 함께 이동
- 통계:
- 기본 기간 최근 7일
- 성장 그래프 일 단위 + 운동 일자 표시

## 7) 빌드/검증 규칙
- 정적 분석: `flutter analyze`
- 통합 검증: `./scripts/verify.sh`
- 포함 단계:
- `flutter pub get`
- `flutter gen-l10n`
- format check
- analyze
- test
- iOS simulator run check

## 8) 자동화/Git 운용
- 이슈 기반 자동 작업: `docs/ISSUE_WORKFLOW.md`, `docs/LOCAL_CODEX_AUTOMATION.md`
- 브랜치/PR 기반 처리 후 main 반영
- 커밋 메시지 규칙: 이슈 번호 포함 (`(#번호)`)

## 9) 알려진 운영 메모
- Web Google Sign-In은 clientId/메타 설정 누락 시 실패 가능
- iOS 릴리즈 빌드는 CocoaPods 상태 영향 큼
- 장시간 `flutter run` 세션이 다수 열리면 실행 경고가 발생할 수 있음

