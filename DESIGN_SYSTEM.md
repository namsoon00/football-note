# SoccerNote Design System (v1)

이 문서는 현재 앱의 UI 기준(토스 느낌의 미니멀 금융형 패턴)을 기록합니다.
다음 작업에서 기능 변경 없이 시각 일관성을 유지하기 위한 기준입니다.

## 1) Tone & Principles
- 톤: 밝고 가벼운 미니멀 UI
- 원칙: 큰 타이포 + 넓은 여백 + 단순한 카드 + 명확한 CTA
- 금지: 브랜드/자산 복제, 과한 색상 혼합, 장식성 과다

## 2) Code Source Of Truth
앱 전역 디자인 기준은 아래 파일을 우선합니다.

- Theme & tokens: `lib/presentation/theme/app_theme.dart`
- Surface card: `lib/presentation/widgets/watch_cart/watch_cart_card.dart`
- Shared tab header: `lib/presentation/widgets/shared_tab_header.dart`
- Feedback: `lib/presentation/widgets/app_feedback.dart`

화면별로 새 카드/버튼/배너 스타일을 직접 만들기 전에 위 공통 기준을 먼저 재사용합니다.

## 3) Color Tokens
- Primary: `#2B6FF3`
- Background: `#F6F8FC`
- Surface(Card): `#FFFFFF`
- Text Primary: `#111827`
- Text Secondary: `#6B7280`
- Border/Outline: `#E4EAF3`

적용 위치: `lib/presentation/theme/app_theme.dart`

## 4) Typography
- Hero/Headline: 26~30, weight 800
- Tab/Screen Title: 24, weight 800
- Section Title: 18~22, weight 700~800
- Body: 14~16, weight 500
- Caption: 12~13, weight 500

## 5) Spacing & Radius
- 기본 화면 패딩: 가로 16~24
- 섹션 간격: 8 / 12 / 16 / 24 단위
- Card radius: 20
- Button/Input radius: 16
- Compact controls: 12
- 최소 터치 영역: 48

## 6) Components
- Primary CTA: 높이 54, 풀폭, 둥근 모서리 16
- Card: 밝은 Surface + 얕은 보더 + 약한 그림자
- Option buttons: 56 높이, 16 radius, active state는 primary tint
- NavigationBar: `onlyShowSelected` 라벨, 아이콘 5탭까지 명확히 보이게 유지

## 7) Status Icon System (Single Source)
상태 아이콘/색은 한 파일에서 관리:
- 파일: `lib/presentation/widgets/status_style.dart`
- API:
  - `trainingStatusVisual(status)`
  - `trainingStatusColor(status)`

사용 대상:
- 일지 리스트: `logs_screen.dart`
- 캘린더 리스트: `calendar_screen.dart`
- 기록 입력 상태칩: `entry_form_screen.dart`

새 상태 추가 시 반드시 `status_style.dart`만 수정하고, 화면별 하드코딩 금지.

## 8) Screen Rules
- 기능/플로우는 유지하고 스타일만 조정
- CTA는 화면당 하나를 가장 강하게
- 텍스트 대비(명도) 우선
- 리스트/카드 터치 피드백 유지(InkWell/Haptic)
- 사용자에게 보이는 문구는 `lib/l10n/*.arb`에 추가하고 generated localization으로 접근

## 9) Implementation Checklist
- [ ] `app_theme.dart` 토큰 준수
- [ ] `app_theme.dart`의 `AppSpacing`/`AppRadius`/`AppSurfaces` 재사용
- [ ] 카드 라운드/보더/여백 일치
- [ ] 상태 아이콘은 공통 시스템 사용
- [ ] 새 UI 문구는 모든 ARB 파일에 추가
- [ ] 하단 탭(통계 포함) 가시성 확인
- [ ] 다크/라이트 대비 확인
