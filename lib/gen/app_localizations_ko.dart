// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Korean (`ko`).
class AppLocalizationsKo extends AppLocalizations {
  AppLocalizationsKo([String locale = 'ko']) : super(locale);

  @override
  String get appTitle => '축구 훈련 일지';

  @override
  String get tabHome => '홈';

  @override
  String get tabLogs => '훈련기록';

  @override
  String get tabCalendar => '캘린더';

  @override
  String get tabStats => '통계';

  @override
  String get tabDiary => '다이어리';

  @override
  String get tabNews => '오늘의 소식';

  @override
  String get tabGame => '미니게임';

  @override
  String get drawerMainScreens => '주요 화면';

  @override
  String get drawerQuickAdd => '빠른 추가';

  @override
  String get drawerToolsContent => '도구와 콘텐츠';

  @override
  String get drawerTrainingPlan => '훈련 계획';

  @override
  String get drawerMatch => '시합';

  @override
  String get drawerAddTrainingSketch => '훈련 스케치';

  @override
  String get drawerNotifications => '알림';

  @override
  String get drawerQuiz => '퀴즈';

  @override
  String get addEntry => '기록 추가';

  @override
  String get editEntry => '기록 수정';

  @override
  String get save => '저장';

  @override
  String get update => '수정 완료';

  @override
  String get add => '추가';

  @override
  String get edit => '수정';

  @override
  String get newItem => '새 항목';

  @override
  String get trainingDate => '훈련 날짜';

  @override
  String get trainingDuration => '훈련 시간';

  @override
  String minutes(Object value) {
    return '$value분';
  }

  @override
  String times(Object value) {
    return '$value회';
  }

  @override
  String get notSet => '미입력';

  @override
  String get trainingType => '훈련 종류';

  @override
  String get status => '훈련 상태';

  @override
  String get statusGreat => '아주 좋아요';

  @override
  String get statusGood => '좋아요';

  @override
  String get statusNormal => '보통';

  @override
  String get statusTough => '힘들어요';

  @override
  String get statusRecovery => '회복 중';

  @override
  String get typeTechnical => '기술';

  @override
  String get typePhysical => '피지컬';

  @override
  String get typeTactical => '전술';

  @override
  String get typeMatch => '경기';

  @override
  String get typeRecovery => '회복';

  @override
  String get intensity => '강도';

  @override
  String get condition => '컨디션';

  @override
  String get location => '장소';

  @override
  String get program => '훈련 프로그램';

  @override
  String get drills => '세션 드릴';

  @override
  String get injury => '부상 여부';

  @override
  String get injuryPart => '부상 부위';

  @override
  String get painLevel => '통증 강도(1-10)';

  @override
  String get rehab => '재활 여부';

  @override
  String get goal => '오늘 목표';

  @override
  String get feedback => '피드백/코멘트';

  @override
  String get notes => '메모';

  @override
  String get growth => '성장 기록';

  @override
  String get height => '키(cm)';

  @override
  String get weight => '몸무게(kg)';

  @override
  String get calendar => '캘린더';

  @override
  String get calendarFormatMonth => '1개월';

  @override
  String get calendarFormatTwoWeeks => '2주';

  @override
  String get calendarFormatWeek => '1주';

  @override
  String get noEntries => '아직 기록이 없습니다.';

  @override
  String get noEntriesForDay => '선택한 날짜에 기록이 없습니다.';

  @override
  String get noResults => '검색 결과가 없습니다.';

  @override
  String get searchHint => '훈련 기록 검색';

  @override
  String get filterTitle => '기록 필터';

  @override
  String get filterAll => '전체';

  @override
  String get filterInjuryOnly => '부상 기록만';

  @override
  String get filterReset => '초기화';

  @override
  String get filterApply => '적용';

  @override
  String get deleteEntry => '기록 삭제';

  @override
  String get deleteConfirm => '선택한 기록을 삭제할까요?';

  @override
  String get cancel => '취소';

  @override
  String get delete => '삭제';

  @override
  String get statsRecent7 => '최근 7일';

  @override
  String get statsRecent30 => '최근 30일';

  @override
  String get statsTotalSessions => '훈련 횟수';

  @override
  String get statsTotalMinutes => '총 훈련 시간';

  @override
  String get statsAvgIntensity => '평균 강도';

  @override
  String get statsAvgCondition => '평균 컨디션';

  @override
  String get statsInjuryCount => '부상 기록';

  @override
  String get statsAvgPain => '평균 통증';

  @override
  String get statsRehabCount => '재활 기록';

  @override
  String get statsSummary => '전체 요약';

  @override
  String get statsTypeRatio => '훈련 프로그램 비율';

  @override
  String get statsWeeklyMinutes => '최근 7일 훈련 시간(분)';

  @override
  String get growthHistory => '성장 히스토리';

  @override
  String level(Object value) {
    return '레벨 $value';
  }

  @override
  String levelUpRemaining(Object value) {
    return '레벨업까지 $value회!';
  }

  @override
  String get missionComplete => '미션 완료! 이번 주 목표 달성!';

  @override
  String get missionKeepGoing => '잘하고 있어요! 이번 주 3회 목표까지 조금만 더!';

  @override
  String get onboard1 => '오늘 훈련을 기록해요';

  @override
  String get onboard2 => '성장 히스토리를 확인해요';

  @override
  String get onboard3 => '목표 달성과 레벨업!';

  @override
  String get next => '다음';

  @override
  String get start => '시작하기';

  @override
  String get heroMessage => '오늘도 멋진 플레이! 기록을 남기면 실력이 쑥쑥 올라가요.';

  @override
  String get logsHeadline1 => '훈련';

  @override
  String get logsHeadline2 => '기록';

  @override
  String get entryHeadline1 => '훈련 노트';

  @override
  String get entryHeadline2 => '';

  @override
  String get statsHeadline1 => '성장';

  @override
  String get statsHeadline2 => '통계';

  @override
  String get durationNotSet => '시간 미입력';

  @override
  String get defaultLocation1 => '학교 운동장';

  @override
  String get defaultLocation2 => '동네 운동장';

  @override
  String get defaultLocation3 => '실내 체육관';

  @override
  String get defaultProgram1 => '기본기';

  @override
  String get defaultProgram2 => '피지컬';

  @override
  String get defaultProgram3 => '전술';

  @override
  String get defaultProgram4 => '회복';

  @override
  String get defaultDrill1 => '5:2 론도';

  @override
  String get defaultDrill2 => '1:1 대인 수비';

  @override
  String get defaultDrill3 => '슈팅 반복';

  @override
  String get defaultDrill4 => '스프린트';

  @override
  String get defaultInjury1 => '햄스트링';

  @override
  String get defaultInjury2 => '무릎';

  @override
  String get defaultInjury3 => '발목';

  @override
  String get defaultInjury4 => '허벅지';

  @override
  String get defaultInjury5 => '종아리';

  @override
  String get languageEnglish => '영어';

  @override
  String get languageKorean => '한국어';

  @override
  String get settings => '설정';

  @override
  String get account => '계정';

  @override
  String get signInWithGoogle => 'Google로 로그인';

  @override
  String get signInFailed => '로그인에 실패했어요. 다시 시도해 주세요.';

  @override
  String get signedIn => '로그인됨';

  @override
  String get signOut => '로그아웃';

  @override
  String get webLoginNotAvailable => '웹에서는 Google 로그인을 사용할 수 없어요.';

  @override
  String get backupToDrive => 'Google Drive 백업';

  @override
  String get restoreFromDrive => 'Google Drive 복원';

  @override
  String get backupConfirm => 'Google Drive에 새 백업을 만들까요?';

  @override
  String get restoreConfirm => 'Google Drive의 최신 백업으로 복원할까요? 현재 데이터가 교체됩니다.';

  @override
  String get backupSuccess => '백업이 완료되었습니다.';

  @override
  String get backupFailed => '백업에 실패했어요. 다시 시도해 주세요.';

  @override
  String get restoreSuccess => '복원이 완료되었습니다.';

  @override
  String get restoreFailed => '복원에 실패했어요. 다시 시도해 주세요.';

  @override
  String get backupInProgress => '백업 중...';

  @override
  String get restoreInProgress => '복원 중...';

  @override
  String get backupDailyEnabled => '매일 자동 백업';

  @override
  String get backupDailyDesc => '앱을 열 때 하루에 한 번 백업합니다';

  @override
  String get backupAutoOnSave => '저장 시 자동 백업';

  @override
  String get backupAutoOnSaveDesc => '기록을 추가/수정할 때마다 백업합니다';

  @override
  String get lastBackup => '마지막 백업';

  @override
  String get timeJustNow => '방금 전';

  @override
  String timeMinutesAgo(int count) {
    return '$count분 전';
  }

  @override
  String timeHoursAgo(int count) {
    return '$count시간 전';
  }

  @override
  String get timeYesterday => '어제';

  @override
  String get restoreLocalBackup => '로컬 안전 백업 복원';

  @override
  String get restoreLocalConfirm => '복원 직전에 저장된 안전 백업으로 되돌릴까요? 현재 데이터가 교체됩니다.';

  @override
  String get restoreLocalSuccess => '로컬 복원이 완료되었습니다.';

  @override
  String get restoreLocalFailed => '로컬 복원에 실패했어요. 다시 시도해 주세요.';

  @override
  String get localBackup => '로컬 안전 백업';

  @override
  String get loginRequired => 'Google 로그인이 필요해요.';

  @override
  String get signOutDone => '로그아웃되었습니다.';

  @override
  String get voiceNotAvailable => '이 기기에서는 음성 입력을 사용할 수 없어요.';

  @override
  String get liftingRecord => '리프팅 기록';

  @override
  String get liftingByPart => '리프팅(부위별 횟수)';

  @override
  String get liftingPartInfront => '인프론트';

  @override
  String get liftingPartInside => '인사이드';

  @override
  String get liftingPartOutside => '아웃사이드';

  @override
  String get liftingPartMuple => '무릎';

  @override
  String get liftingPartHead => '머리';

  @override
  String get liftingPartChest => '가슴';

  @override
  String get liftingByBodyPartTitle => '리프팅 부위 통계';

  @override
  String get liftingNoRecords => '리프팅 기록이 없습니다.';

  @override
  String get legacyLabel => '기존';

  @override
  String get oldLabel => '구버전';

  @override
  String get confirm => '확인';

  @override
  String get language => '언어';

  @override
  String get theme => '테마';

  @override
  String get themeSystem => '시스템';

  @override
  String get themeLight => '라이트';

  @override
  String get themeDark => '다크';

  @override
  String get defaults => '기본값';

  @override
  String get defaultDuration => '기본 훈련 시간';

  @override
  String get defaultIntensity => '기본 강도';

  @override
  String get defaultCondition => '기본 컨디션';

  @override
  String get defaultLocation => '기본 장소';

  @override
  String get defaultProgram => '기본 프로그램';

  @override
  String get notifications => '알림';

  @override
  String get reminderEnabled => '일일 알림 사용';

  @override
  String get reminderTime => '알림 시간';

  @override
  String get photo => '사진';

  @override
  String get addPhoto => '사진 추가';

  @override
  String get removePhoto => '삭제';

  @override
  String get noImage => '사진이 아직 없어요';

  @override
  String get imageLoadFailed => '이미지를 불러오지 못했어요';

  @override
  String get more => '더보기';

  @override
  String get camera => '카메라';

  @override
  String get gallery => '갤러리';

  @override
  String get crop => '자르기';

  @override
  String get photoHint => '저장 왼쪽의 카메라 아이콘을 눌러 사진을 추가해요.';

  @override
  String get reorderPhotos => '사진 순서 변경';

  @override
  String photoIndex(Object value) {
    return '$value번째 사진';
  }

  @override
  String photoLimitReached(Object value) {
    return '사진은 최대 $value장까지 추가할 수 있어요.';
  }

  @override
  String get gameGuideTitle => '게임 가이드';

  @override
  String get gameGuideQuickTitle => '현재 게임 흐름';

  @override
  String get gameGuideQuickLine1 =>
      '한 판은 20초이며 시작 생명은 3개입니다. 실패해도 생명이 남으면 바로 재도전합니다.';

  @override
  String get gameGuideQuickLine2 =>
      '패스 버튼을 눌러 방향/세기를 조절해 안전 패스, 킬 패스, 위험 패스를 선택합니다.';

  @override
  String get gameGuideQuickLine3 =>
      '연속 성공으로 콤보를 쌓고, 콤보 8 이상이면 5초 피버 타임이 열려 보너스 점수가 2배가 됩니다.';

  @override
  String get gameGuideQuickLine4 =>
      '판 중에 랜덤 이벤트(좁은 라인, 넓은 라인, 순풍)와 미션이 바뀌므로 상황에 맞춰 선택하세요.';

  @override
  String get gameGuideRiskTitle => '선택 전략';

  @override
  String get gameGuideRiskLine1 => '안전 패스: 성공률이 높아 흐름 유지와 미션 안정 클리어에 좋습니다.';

  @override
  String get gameGuideRiskLine2 => '킬 패스: 중간 난이도지만 보너스가 좋아 점수 상승이 빠릅니다.';

  @override
  String get gameGuideRiskLine3 => '위험 패스: 난이도는 높지만 성공 시 보상이 가장 큽니다.';

  @override
  String get gameGuideRiskLine4 =>
      '공간이 넓은 쪽으로 보내면 추가 보너스를 받으니 수비 간격을 먼저 보고 패스하세요.';

  @override
  String get gameGuideFailureTitle => '실패 후 대응';

  @override
  String get gameGuideFailureLine1 =>
      '차단/충돌/빗나감이 나와도 생명이 남아 있으면 바로 이어서 플레이할 수 있습니다.';

  @override
  String get gameGuideFailureLine2 =>
      '빠름/느림 피드백을 보고 다음 시도에서 버튼 누르는 길이를 즉시 조정하세요.';

  @override
  String get gameGuideFailureLine3 =>
      '3초 무패스가 뜨면 템포가 끊긴 상태이므로 짧은 패스로 리듬부터 다시 만드세요.';

  @override
  String get gameGuideFailureLine4 =>
      '생명이 0이 되면 종료되므로, 후반에는 안전 패스 중심으로 운영하는 것이 유리합니다.';

  @override
  String get gameGuideRankingTitle => '점수 계산';

  @override
  String get gameGuideRankingLine1 =>
      '랭킹 점수 = (성공 패스x10) + (레벨x15) + (골x60) + 보너스 점수';

  @override
  String get gameGuideRankingLine2 =>
      '보너스 점수: 패스 타입 보상, 공간 선택 보상, 리듬 보상, 미션 보상';

  @override
  String get gameGuideRankingLine3 =>
      '피버 타임에는 보너스 점수가 2배이므로 짧은 시간에 점수를 크게 올릴 수 있습니다.';

  @override
  String get gameGuideRankingLine4 =>
      '최고 점수 루트: 안전 패스로 리듬 구축 -> 킬/위험 패스로 확장 -> 미션/골 마무리';

  @override
  String get gameGuideCharPacTitle => '팩맨 공격수';

  @override
  String get gameGuideCharPacSubtitle => '패스 시작/연결 담당';

  @override
  String get gameGuideCharPacTag => '공격';

  @override
  String get gameGuideCharBlueTitle => '블루 고스트 - BLOCK';

  @override
  String get gameGuideCharBlueSubtitle => '패스 라인 차단';

  @override
  String get gameGuideCharBlueTag => '차단';

  @override
  String get gameGuideCharOrangeTitle => '오렌지 고스트 - PRESS';

  @override
  String get gameGuideCharOrangeSubtitle => '공 근처 압박';

  @override
  String get gameGuideCharOrangeTag => '압박';

  @override
  String get gameGuideCharRedTitle => '레드 고스트 - MARK';

  @override
  String get gameGuideCharRedSubtitle => '패서 마킹';

  @override
  String get gameGuideCharRedTag => '마크';

  @override
  String get gameGuideCharPinkTitle => '핑크 고스트 - READ';

  @override
  String get gameGuideCharPinkSubtitle => '리시버 예측 차단';

  @override
  String get gameGuideCharPinkTag => '예측';

  @override
  String get hideKeyboard => '키보드 내리기';

  @override
  String get diaryTitlePlaceholder => '제목을 입력해 주세요';

  @override
  String get diaryCustomEmotionLabel => '감정 직접 만들기';

  @override
  String get diaryCustomEmotionHint => '원하는 감정을 직접 스티커로 추가해 보세요';

  @override
  String get diaryCustomEmotionAdd => '감정 추가';

  @override
  String diaryExpandNewsStickers(int count) {
    return '소식 스티커 전체 보기 ($count)';
  }

  @override
  String get diaryCollapseNewsStickers => '소식 스티커 접기';

  @override
  String get homeWeatherTitle => '날씨 코치';

  @override
  String get homeWeatherSubtitle => '현재 날씨를 보고 오늘 훈련 강도를 조절해 보세요.';

  @override
  String get homeWeatherLoad => '현재 위치 날씨 불러오기';

  @override
  String get homeWeatherLoading => '현재 위치 날씨를 불러오는 중...';

  @override
  String get homeWeatherUnavailable => '위치 권한을 허용하면 이곳에 날씨와 훈련 제안이 표시됩니다.';

  @override
  String get homeWeatherPermissionNeeded => '현재 위치 날씨를 불러오려면 위치 권한이 필요합니다.';

  @override
  String get homeWeatherLoadFailed => '현재 위치 날씨를 불러오지 못했어요.';

  @override
  String get homeWeatherLocationUnknown => '현재 위치';

  @override
  String get homeWeatherCountryKorea => '한국';

  @override
  String get homeWeatherDetailsTitle => '상세 날씨';

  @override
  String get homeWeatherDetailsSubtitle => '현재 위치 기준 날씨와 대기질을 확인하세요.';

  @override
  String get homeWeatherTomorrowTitle => '내일 상세 날씨';

  @override
  String get homeWeatherWeeklyTitle => '주간 날씨';

  @override
  String get homeWeatherCacheHint => '최근 가져온 데이터를 10분 동안 다시 사용합니다.';

  @override
  String get homeWeatherDailyHighLow => '최고/최저';

  @override
  String get homeWeatherTomorrowFallback => '내일 예보가 아직 없어요.';

  @override
  String get homeWeatherTemperatureRange => '최고/최저';

  @override
  String get homeWeatherFeelsLike => '체감 온도';

  @override
  String get homeWeatherHumidity => '습도';

  @override
  String get homeWeatherPrecipitation => '강수량';

  @override
  String get homeWeatherWindSpeed => '풍속';

  @override
  String get homeWeatherUvIndex => '자외선';

  @override
  String get homeWeatherOutfitTitle => '오늘의 축구 복장';

  @override
  String get homeWeatherOutfitBaseHot => '반팔 유니폼과 가벼운 쇼츠, 통풍 잘 되는 양말을 준비하세요.';

  @override
  String get homeWeatherOutfitBaseCold => '기모 이너, 장갑, 롱양말, 필요하면 비니까지 착용하세요.';

  @override
  String get homeWeatherOutfitBaseMild => '기본 유니폼에 가벼운 이너 한 벌이면 충분합니다.';

  @override
  String get homeWeatherOutfitRain => '얇은 방수 바람막이와 여벌 양말을 챙기세요.';

  @override
  String get homeWeatherOutfitSnow => '보온 이너와 두꺼운 양말, 미끄럼 주의가 필요합니다.';

  @override
  String get homeWeatherOutfitWind => '바람막이를 덧입고 체온이 떨어지지 않게 하세요.';

  @override
  String get homeWeatherOutfitAirCaution =>
      '대기질이 나쁘면 이동 시 마스크를 착용하고 야외 고강도는 줄이세요.';

  @override
  String get homeWeatherOutfitButton => '추천 복장';

  @override
  String get homeWeatherAirQualityTitle => '대기질';

  @override
  String get homeWeatherAirQualitySubtitle => '숫자가 낮을수록 숨쉬기 편한 공기예요.';

  @override
  String get homeWeatherPm10 => '미세먼지 PM10';

  @override
  String get homeWeatherPm25 => '초미세먼지 PM2.5';

  @override
  String get homeWeatherAqi => 'AQI';

  @override
  String get homeWeatherAqiLabel => '공기질 지수';

  @override
  String get homeWeatherAqiDescription => 'AQI는 공기 상태를 숫자로 보여주는 값이에요.';

  @override
  String get homeWeatherAqiScaleGood => '0-50 좋음';

  @override
  String get homeWeatherAqiScaleModerate => '51-100 보통';

  @override
  String get homeWeatherAqiScaleSensitive => '101 이상 주의';

  @override
  String get homeWeatherTomorrowCondition => '날씨 상태';

  @override
  String get homeWeatherWeeklyDateLabel => '날짜';

  @override
  String get homeWeatherWeeklyConditionLabel => '예보';

  @override
  String get homeWeatherStatusGood => '좋음';

  @override
  String get homeWeatherStatusModerate => '보통';

  @override
  String get homeWeatherStatusSensitive => '민감군 주의';

  @override
  String get homeWeatherStatusUnhealthy => '나쁨';

  @override
  String get homeWeatherStatusVeryUnhealthy => '매우 나쁨';

  @override
  String get homeWeatherStatusHazardous => '위험';

  @override
  String get homeWeatherSuggestionTitle => '추천 훈련 포인트';

  @override
  String get homeWeatherSuggestionButton => '추천 훈련 포인트';

  @override
  String get homeWeatherSuggestionClear =>
      '야외에서 퍼스트 터치, 패스 리듬, 짧은 스프린트 세트를 소화하기 좋은 날씨예요.';

  @override
  String get homeWeatherSuggestionCloudy =>
      '컨디션이 안정적이라 전술 패턴 연습과 템포 유지 훈련을 길게 가져가기 좋습니다.';

  @override
  String get homeWeatherSuggestionRain =>
      '실내 볼 터치, 벽 패스, 밸런스와 코어 중심 훈련으로 전환하는 편이 좋습니다.';

  @override
  String get homeWeatherSuggestionSnow => '실내 코디네이션, 가동성, 가벼운 기술 반복 위주로 가져가세요.';

  @override
  String get homeWeatherSuggestionStorm =>
      '안전을 우선하고 회복, 영상 복기, 짧은 실내 활성화 운동으로 조정하세요.';

  @override
  String get homeWeatherSuggestionHot =>
      '훈련량을 줄이고 회복 시간을 늘리면서 수분 보충과 기술 완성도에 집중하세요.';

  @override
  String get homeWeatherSuggestionCold =>
      '워밍업 시간을 더 확보한 뒤 터치 감각부터 올리면서 강도를 천천히 끌어올리세요.';

  @override
  String get homeWeatherSuggestionAirCaution =>
      '대기질이 좋지 않으니 야외 고강도는 줄이고 가능하면 실내 기술 훈련이나 회복 세션으로 전환하세요.';

  @override
  String get homeWeatherSuggestionAirWatch =>
      '실외 훈련이 필요하면 고강도 구간을 짧게 가져가고 호흡 상태를 자주 확인하세요.';

  @override
  String get weatherLabelDefault => '날씨';

  @override
  String get weatherLabelClear => '맑음';

  @override
  String get weatherLabelCloudy => '구름';

  @override
  String get weatherLabelFog => '안개';

  @override
  String get weatherLabelDrizzle => '이슬비';

  @override
  String get weatherLabelRain => '비';

  @override
  String get weatherLabelSnow => '눈';

  @override
  String get weatherLabelThunderstorm => '천둥번개';

  @override
  String get diaryStickerTraining => '훈련';

  @override
  String get diaryStickerMatch => '시합';

  @override
  String get diaryStickerPlan => '계획';

  @override
  String get diaryStickerFortune => '운세';

  @override
  String get diaryStickerBoard => '훈련보드';

  @override
  String get diaryStickerNews => '소식';

  @override
  String get diaryStickerMeal => '공기밥';

  @override
  String get diaryStickerConditioning => '줄넘기/리프팅';

  @override
  String get diaryStickerInjury => '부상';

  @override
  String get diaryStickerQuiz => '퀴즈';

  @override
  String get diaryStickerWeather => '날씨';

  @override
  String get diaryInjuryNoDetails => '남긴 부상 메모가 없어요.';

  @override
  String get diaryInjuryRehab => '재활';

  @override
  String get diaryInjuryStorySentence => '통증이 있었던 장면과 회복이 필요한 부분을 짧게 남겨 보세요.';

  @override
  String get diaryQuizStorySentence => '퀴즈를 풀며 기억에 남은 문제나 다시 보고 싶은 개념을 적어 보세요.';

  @override
  String diaryQuizSummaryPerfect(int score, int total) {
    return '$score/$total 정답 · 오답 없음';
  }

  @override
  String diaryQuizSummaryWithMisses(int score, int total, int wrongCount) {
    return '$score/$total 정답 · 오답 $wrongCount개';
  }

  @override
  String diaryQuizExpandQuestions(int count) {
    return '정답 전체 보기 ($count)';
  }

  @override
  String get diaryQuizCollapseQuestions => '정답 접기';

  @override
  String get diaryQuizQuestionLabel => '질문';

  @override
  String get diaryQuizAnswerLabel => '정답';

  @override
  String get diaryQuizWrongAnswerLabel => '오답';

  @override
  String get diaryQuizWrongAnswerNone => '오답 없음';

  @override
  String get diaryQuizNoMissesLabel => '이번 퀴즈는 오답 없이 마쳤어요.';

  @override
  String get diaryTrainingStatusLabel => '훈련 상태';

  @override
  String get diaryConditioningJumpRopeLabel => '줄넘기';

  @override
  String get diaryConditioningLiftingLabel => '리프팅';

  @override
  String get diaryWeatherEmpty => '날씨 기록이 없습니다.';

  @override
  String get quizWrongAnswerTimeout => '시간 초과';

  @override
  String get quizWrongAnswerRevealed => '정답 보기';

  @override
  String get quizWrongAnswerSkipped => '답을 고르지 않음';

  @override
  String get quizWrongAnswerEmpty => '입력 없음';

  @override
  String get diaryTrainingSelectedGoalsLabel => '선택한 목표';

  @override
  String get diaryTrainingStrongPointLabel => '잘한 점';

  @override
  String get diaryTrainingNeedsWorkLabel => '아쉬운 점';

  @override
  String get diaryTrainingNextGoalLabel => '다음 목표';

  @override
  String get diarySelectedRecordStickersTitle => '선택한 기록 스티커';

  @override
  String get diarySelectedRecordStickersHint => '드래그해서 순서를 바꿀 수 있어요.';

  @override
  String get diaryRecordStickerSectionTitle => '기록 스티커 구성';

  @override
  String get diaryRecordStickerSectionSubtitle =>
      '오늘 기록에서 바로 고르고, 위쪽 선택 순서에서 흐름을 정리하세요.';

  @override
  String get diaryRecordStickerSourceTitle => '오늘 기록에서 가져오기';

  @override
  String diaryRecordStickerAvailableCount(int count) {
    return '$count개 항목';
  }

  @override
  String diaryRecordStickerSelectedCount(int count) {
    return '$count개 선택';
  }

  @override
  String diaryRecordStickerSelectedOrder(int order) {
    return '$order번 순서';
  }

  @override
  String get diaryRecordStickerEmptyHint =>
      '아래 기록에서 스티커를 고르면 이곳에서 순서를 바로 바꿀 수 있어요.';

  @override
  String get diaryRecordStickerReorder => '순서 변경';

  @override
  String get diaryRecordStickerRemove => '스티커 제거';

  @override
  String get diaryRecordStickerPinned => '스티커 추가됨';

  @override
  String get diaryRecordStickerPin => '기록 스티커로 붙이기';

  @override
  String get diaryMealStorySentence =>
      '오늘 먹은 흐름을 돌아보며 식사량이 몸 상태와 어떻게 이어졌는지 적어 본다.';

  @override
  String get diaryMealSectionTitle => '오늘 식사 메모';

  @override
  String get diaryMealSectionBody => '세 끼와 밥 양, 몸 느낌의 연결을 간단히 남긴다.';

  @override
  String get diaryNewsOpenFailed => '기사를 열지 못했어요.';

  @override
  String get mealRoutineTitle => '먹는 것도 훈련이다';

  @override
  String get mealRoutineSubtitle => '복잡한 칼로리 대신 세 끼와 밥 양을 간단히 기록하세요.';

  @override
  String get mealBreakfast => '아침';

  @override
  String get mealLunch => '점심';

  @override
  String get mealDinner => '저녁';

  @override
  String get mealShortLabel => '식사';

  @override
  String get mealDone => '먹음';

  @override
  String get mealSkipped => '미기록';

  @override
  String get mealRiceNone => '0공기';

  @override
  String mealRiceBowls(int count) {
    return '$count공기';
  }

  @override
  String get mealRiceLabel => '밥 양';

  @override
  String get mealCoachHeadlinePerfect => '세 끼 루틴이 좋습니다.';

  @override
  String get mealCoachHeadlineAlmost => '한 끼만 더 챙기면 됩니다.';

  @override
  String get mealCoachHeadlineNeedsMore => '식사 루틴을 더 채워야 합니다.';

  @override
  String get mealCoachHeadlineStart => '오늘은 식사부터 훈련으로 묶어보세요.';

  @override
  String get mealCoachBodySteady =>
      '세 끼와 밥 양이 안정적입니다. 다음 훈련에서는 템포 유지에 집중해도 좋습니다.';

  @override
  String get mealCoachBodyThreeMeals =>
      '세 끼를 챙겼습니다. 다음 단계는 끼니마다 밥 양을 너무 들쭉날쭉하지 않게 맞추는 것입니다.';

  @override
  String get mealCoachBodyTwoMealsSolid =>
      '두 끼는 잘 챙겼습니다. 빠진 한 끼를 고정 시간에 붙이면 회복 흐름이 더 좋아집니다.';

  @override
  String get mealCoachBodyTwoMealsLight =>
      '두 끼를 먹었지만 양이 얇습니다. 다음 식사 한 끼는 한 그릇 기준부터 세워보세요.';

  @override
  String get mealCoachBodyOneMeal =>
      '한 끼만 기록됐습니다. 오늘은 훈련 강도보다 끼니 수를 늘리는 것이 먼저입니다.';

  @override
  String get mealCoachBodyZeroMeal =>
      '세 끼 체크부터 다시 시작하세요. 계산보다 끼니를 놓치지 않는 루틴이 우선입니다.';

  @override
  String get mealXpFull => '세 끼 완료 +15 XP';

  @override
  String get mealXpFullBonus => '세 끼 완료 + 공기밥 5공기 이상 +20 XP';

  @override
  String get mealXpPartial => '두 끼 이상 +5 XP';

  @override
  String get mealXpNeutral => '한 끼 이하 기록은 보너스 없음';

  @override
  String get homeMealCoachTitle => '식사 코치';

  @override
  String get homeMealCoachRecordAction => '오늘 식사 기록';

  @override
  String get homeMealCoachOtherSuggestions => '다른 제안 보기';

  @override
  String get homeMealCoachHeadlinePerfect => '완료';

  @override
  String get homeMealCoachHeadlineAlmost => '거의 완료';

  @override
  String get homeMealCoachHeadlineNeedsMore => '보완 필요';

  @override
  String get homeMealCoachHeadlineStart => '시작 전';

  @override
  String get homeMealCoachNoEntry => '오늘 훈련노트가 아직 없습니다. 오늘 먹은 끼니부터 먼저 남겨보세요.';

  @override
  String homeMealCoachSummary(
      String breakfastLabel,
      String breakfastValue,
      String lunchLabel,
      String lunchValue,
      String dinnerLabel,
      String dinnerValue) {
    return '$breakfastLabel $breakfastValue · $lunchLabel $lunchValue · $dinnerLabel $dinnerValue';
  }

  @override
  String get homeMealCoachSuggestionStart1 =>
      '아침, 점심, 저녁 중 가장 자주 빠지는 끼니 하나만 먼저 고정하세요.';

  @override
  String get homeMealCoachSuggestionStart2 => '기록을 시작할 때는 칼로리보다 세 끼 체크가 우선입니다.';

  @override
  String get homeMealCoachSuggestionStart3 =>
      '오늘 첫 식사를 남기고 내일 같은 시간에 다시 이어가 보세요.';

  @override
  String get homeMealCoachSuggestionOne1 =>
      '한 끼만 기록됐습니다. 다음 끼니는 시간을 정해서 놓치지 않게 하세요.';

  @override
  String get homeMealCoachSuggestionOne2 =>
      '먹었다면 밥 양도 같이 적어 두세요. 다음 코칭이 훨씬 쉬워집니다.';

  @override
  String get homeMealCoachSuggestionOne3 =>
      '오늘은 퀴즈나 다이어리보다 끼니 수를 늘리는 것이 우선입니다.';

  @override
  String get homeMealCoachSuggestionTwoLight1 =>
      '두 끼를 먹었지만 양이 적습니다. 다음 한 끼는 최소 한 그릇을 목표로 잡아보세요.';

  @override
  String get homeMealCoachSuggestionTwoLight2 =>
      '빠진 한 끼를 간식으로 대체하지 말고 식사 시간으로 고정해 보세요.';

  @override
  String get homeMealCoachSuggestionTwoLight3 =>
      '식사 수는 괜찮습니다. 이제 밥 양 기준을 함께 만들 차례입니다.';

  @override
  String get homeMealCoachSuggestionTwoSolid1 =>
      '두 끼 흐름은 좋습니다. 빠진 한 끼를 같은 시간대에 붙이면 회복이 더 안정됩니다.';

  @override
  String get homeMealCoachSuggestionTwoSolid2 =>
      '오늘은 식사 리듬을 지킨 만큼 훈련 메모에 몸 상태도 같이 남겨보세요.';

  @override
  String get homeMealCoachSuggestionTwoSolid3 =>
      '두 끼가 안정적이면 세 끼 완성은 시간 고정 문제에 가깝습니다.';

  @override
  String get homeMealCoachSuggestionThree1 =>
      '세 끼를 챙겼습니다. 다음은 끼니별 밥 양 편차를 줄여보세요.';

  @override
  String get homeMealCoachSuggestionThree2 =>
      '세 끼를 지킨 날은 다이어리까지 묶어 회복 루틴 완성도를 높여보세요.';

  @override
  String get homeMealCoachSuggestionThree3 =>
      '기록이 안정적이니 다음 훈련에서는 움직임 가벼움도 같이 체크해 보세요.';

  @override
  String get homeMealCoachSuggestionSteady1 =>
      '세 끼와 밥 양이 안정적입니다. 다음 훈련 템포 유지에 집중해도 됩니다.';

  @override
  String get homeMealCoachSuggestionSteady2 =>
      '오늘은 에너지 채우기가 좋았습니다. 훈련 후 느낌을 메모로 남겨보세요.';

  @override
  String get homeMealCoachSuggestionSteady3 =>
      '식사 루틴이 잡혔으니 다른 제안은 회복 수면과 다이어리 연결입니다.';

  @override
  String mealCompactSummary(String label, int count) {
    return '$label $count공기';
  }

  @override
  String mealCompactSkipped(String label) {
    return '$label 미기록';
  }

  @override
  String mealRiceBowlsValue(String count) {
    return '$count공기';
  }

  @override
  String get mealLogScreenTitle => '식사 기록';

  @override
  String get mealLogDateLabel => '기록 날짜';

  @override
  String get mealLogDatePickerHelp => '식사 기록 날짜 선택';

  @override
  String get mealSaveAction => '식사 기록 저장';

  @override
  String get mealDeleteAction => '식사 기록 삭제';

  @override
  String get mealDeleteConfirmBody => '이 날짜의 식사 기록을 삭제할까요?';

  @override
  String get mealSavedFeedback => '식사 기록을 저장했어요.';

  @override
  String get mealDeletedFeedback => '식사 기록을 삭제했어요.';

  @override
  String get mealLogXpSourceLabel => '식사 기록';

  @override
  String mealAverageExpectedValue(String value) {
    return '평균 기대치 $value공기';
  }

  @override
  String mealAverageActualValue(String value) {
    return '$value공기';
  }

  @override
  String get mealStatsEmpty => '선택한 기간에 식사 기록이 없습니다.';

  @override
  String get mealStatsSectionTitle => '식사 기록';

  @override
  String get mealStatsTrendTitle => '식사 흐름';

  @override
  String get mealStatsTodayRiceBowlTitle => '최근 기록 공기밥';

  @override
  String get mealStatsLoggedDays => '기록 일수';

  @override
  String get mealStatsExpectedAverage => '평균 기대치';

  @override
  String get mealStatsActualAverage => '평균 실제';

  @override
  String get mealStatsBestDay => '최고 섭취';

  @override
  String get mealIncreaseAction => '공기 추가';

  @override
  String get mealDecreaseAction => '공기 줄이기';

  @override
  String get mealStatsWeightLinkedHint => '몸무게를 남긴 날에는 식사량과 함께 그래프에 연결됩니다.';

  @override
  String get homeRiceBowlTitle => '오늘 먹은 공기밥';

  @override
  String get homeRiceBowlSubtitle => '가득 찬 공기밥, 반공기, 안 먹은 공기밥을 한눈에 봐요.';

  @override
  String get homeRiceBowlFull => '한 공기';

  @override
  String get homeRiceBowlHalf => '반 공기';

  @override
  String get homeRiceBowlEmpty => '안 먹음';

  @override
  String get fortuneDialogTitle => '오늘의 운세';

  @override
  String get fortuneDialogSubtitle => '오늘의 행운 정보를 확인해 보세요.';

  @override
  String get fortuneDialogOverviewTitle => '운세 보기';

  @override
  String get fortuneDialogOverallFortuneLabel => '전체 운세';

  @override
  String get fortuneDialogLuckyInfoLabel => '행운 정보';

  @override
  String fortuneDialogOverallFortuneCount(int count) {
    return '$count줄';
  }

  @override
  String fortuneDialogLuckyInfoCount(int count) {
    return '$count개';
  }

  @override
  String get fortuneDialogLuckyInfoTitle => '행운 정보';

  @override
  String get fortuneDialogPoolSizeLabel => '전체 운세 pool';

  @override
  String fortuneDialogPoolSizeCount(String count) {
    return '$count개';
  }

  @override
  String get fortuneDialogRecommendedProgramTitle => '추천 훈련';

  @override
  String get fortuneDialogRecommendationTitle => '운세 코멘트';

  @override
  String get fortuneDialogEncouragement => '오늘도 멋진 플레이를 응원할게요.';

  @override
  String get fortuneDialogAction => '좋아요';

  @override
  String get mealStatsNoTrainingOrMealEntries => '선택한 기간에 훈련 기록과 식사 기록이 없습니다.';

  @override
  String get drawerRunningCoach => '달리기 코치';

  @override
  String get runningCoachScreenTitle => '달리기 코치';

  @override
  String get runningCoachHeroTitle => '측면 달리기 자세 코칭';

  @override
  String get runningCoachHeroBody =>
      '짧은 측면 달리기 영상을 올리면 상체 자세, 바운스, 발 착지, 무릎 굴곡, 팔 각도까지 더 엄격하게 코칭해 줍니다.';

  @override
  String get runningCoachTipsTitle => '촬영 팁';

  @override
  String get runningCoachTipWholeBody =>
      '머리부터 발목까지 전신이 들어오고, 팔꿈치와 발도 계속 보이게 촬영해 주세요.';

  @override
  String get runningCoachTipSideView => '러너가 화면을 가로지르도록 측면에서 촬영해 주세요.';

  @override
  String get runningCoachTipSteadyCamera =>
      '카메라는 흔들리지 않게 두고 5~15초 정도의 짧은 달리기 장면을 사용해 주세요.';

  @override
  String get runningCoachLiveCardTitle => '실시간 코치';

  @override
  String get runningCoachLiveCardBody =>
      '카메라를 켜 두면 화면부터 먼저 바로잡아 주고, 측면 자세가 안정되면 상체, 바운스, 발 착지, 무릎 굴곡, 팔 각도를 바로 코칭해 줘요.';

  @override
  String get runningCoachLiveAction => '실시간 코치 시작';

  @override
  String get runningCoachLiveGuideAction => '촬영 가이드';

  @override
  String get runningCoachLiveScreenTitle => '실시간 달리기 코치';

  @override
  String get runningCoachLiveGuideScreenTitle => '실시간 촬영 가이드';

  @override
  String get runningCoachLiveGuideHeroTitle => '러너가 가운데, 점수는 옆으로';

  @override
  String get runningCoachLiveGuideHeroBody =>
      '러너는 가운데 프레임 안에 두고, 앱의 점수와 코칭 정보는 좌우 가장자리로 빠지도록 설계했어요. 아래 기준으로 맞추면 인식이 더 안정돼요.';

  @override
  String get runningCoachLiveGuideTipSideTitle => '측면이 잘 보여야 해요';

  @override
  String get runningCoachLiveGuideTipSideBody =>
      '러너가 정면이나 사선보다 측면으로 보이게 서서 화면을 가로지르도록 달려 주세요.';

  @override
  String get runningCoachLiveGuideTipBodyTitle => '머리부터 발끝까지 넣어 주세요';

  @override
  String get runningCoachLiveGuideTipBodyBody =>
      '머리, 팔꿈치, 엉덩이, 발목이 모두 프레임 안에 남아야 자세 선과 점수가 안정적으로 나와요.';

  @override
  String get runningCoachLiveGuideTipHudTitle => '러너 주변에 여백을 남겨 주세요';

  @override
  String get runningCoachLiveGuideTipHudBody =>
      '점수와 메트릭은 화면 바깥쪽에 붙어 나와요. 러너는 가운데 가이드 프레임 안쪽에 두면 가려지지 않아요.';

  @override
  String get runningCoachLiveGuideTipCameraTitle => '카메라는 고정하고 몸 크기는 적당히';

  @override
  String get runningCoachLiveGuideTipCameraBody =>
      '카메라는 흔들리지 않게 두고, 러너가 너무 작지 않게 전신 기준으로 세로 높이의 절반 이상 차지하도록 맞춰 주세요.';

  @override
  String get runningCoachLivePreparingTitle => '카메라 준비 중';

  @override
  String get runningCoachLivePreparingBody => '후면 카메라를 열고 실시간 자세 추적을 준비하고 있어요.';

  @override
  String get runningCoachLiveCameraIssueTitle => '카메라 확인이 필요해요';

  @override
  String get runningCoachLiveCameraDenied => '실시간 코칭을 쓰려면 카메라 권한이 필요해요.';

  @override
  String get runningCoachLiveCameraFailed =>
      '실시간 코치용 카메라를 열지 못했어요. 다시 시도해 주세요.';

  @override
  String get runningCoachLiveRetryAction => '다시 시도';

  @override
  String get runningCoachLiveVoiceOn => '음성 코칭 켜짐';

  @override
  String get runningCoachLiveVoiceOff => '음성 코칭 꺼짐';

  @override
  String get runningCoachLiveSwitchCamera => '카메라 전환';

  @override
  String get runningCoachLiveStatusFraming => '화면부터 맞춰 주세요';

  @override
  String get runningCoachLiveStatusCollecting => '움직임을 모으는 중';

  @override
  String get runningCoachLiveStatusCoaching => '실시간 코칭 중';

  @override
  String get runningCoachLiveCueNoRunner => '러너가 잘 보이지 않아요. 화면 안으로 들어와 주세요.';

  @override
  String get runningCoachLiveCueStepBack =>
      '한 걸음 뒤로 가서 머리부터 발끝까지 전신이 다 나오게 맞춰 주세요.';

  @override
  String get runningCoachLiveCueMoveCloser =>
      '몸이 너무 작게 보여요. 카메라 쪽으로 조금만 더 가까이 와 주세요.';

  @override
  String get runningCoachLiveCueCenterRunner => '러너를 화면 가운데에 더 가깝게 맞춰 주세요.';

  @override
  String get runningCoachLiveCueTurnSideways => '정면보다 측면이 잘 보이게 몸 방향을 돌려 주세요.';

  @override
  String get runningCoachLiveCueKeepRunning =>
      '좋아요. 같은 리듬으로 몇 걸음 더 달리면 코칭이 바로 나와요.';

  @override
  String get runningCoachLiveCueLookingGood => '좋아요. 지금 리듬과 자세를 그대로 유지해 보세요.';

  @override
  String runningCoachLiveTrackedFrames(int count) {
    return '추적 프레임 $count';
  }

  @override
  String get runningCoachLiveScorePending => '점수 계산 중';

  @override
  String runningCoachLiveOverallScore(int score) {
    return '실시간 점수 $score/100';
  }

  @override
  String get runningCoachSprintLiveCardTitle => '스프린트 실시간 MVP';

  @override
  String get runningCoachSprintLiveCardBody =>
      '측면 카메라를 바로 연결해 전경사, 무릎 드라이브, 스텝 리듬, 팔 균형을 보고 세션 FPS, 스킵, 가시성 로그까지 함께 확인해요.';

  @override
  String get runningCoachSprintLiveAction => '스프린트 MVP 시작';

  @override
  String get runningCoachSprintLiveScreenTitle => '스프린트 실시간 코칭';

  @override
  String get runningCoachSprintLiveStatusLowConfidence => '먼저 전신 프레이밍을 맞춰 주세요';

  @override
  String get runningCoachSprintLiveStatusCollecting => '스프린트 리듬을 안정화하는 중';

  @override
  String get runningCoachSprintLiveStatusReady => '실시간 피드백 준비됨';

  @override
  String get runningCoachSprintLiveStatusCoaching => '실시간 스프린트 피드백 중';

  @override
  String get runningCoachSprintLiveCueCollecting =>
      '몇 걸음만 더 유지하면 리듬과 무릎 드라이브를 더 안정적으로 읽을 수 있어요.';

  @override
  String get runningCoachSprintLiveCueReady =>
      '좋아요. 지금 형태를 유지한 채 5~10초만 더 질주해 주세요.';

  @override
  String get runningCoachSprintGuideSideCapture => '측면 구도를 유지해 주세요';

  @override
  String get runningCoachSprintGuideFullBodyFraming =>
      '머리부터 발끝까지 프레임 안에 맞춰 주세요';

  @override
  String runningCoachSprintTrackingConfidenceValue(int percent) {
    return '트래킹 $percent%';
  }

  @override
  String runningCoachSprintTrackedFrames(int count) {
    return '추적 $count프레임';
  }

  @override
  String runningCoachSprintDetectedSteps(int count) {
    return '스텝 이벤트 $count';
  }

  @override
  String get runningCoachSprintSessionLogTitle => '세션 디버그';

  @override
  String get runningCoachSprintSessionCameraFpsLabel => '카메라 입력 FPS';

  @override
  String get runningCoachSprintSessionAnalyzedFpsLabel => '분석 FPS';

  @override
  String get runningCoachSprintSessionAverageProcessingLabel => '평균 처리시간';

  @override
  String runningCoachSprintSessionAverageProcessingValue(Object ms) {
    return '${ms}ms';
  }

  @override
  String get runningCoachSprintSessionSkippedFramesLabel => '드랍/스킵 프레임';

  @override
  String runningCoachSprintSessionSkippedFramesValue(int count) {
    return '$count프레임';
  }

  @override
  String get runningCoachSprintSessionBodyNotVisibleLabel => '전신 누락 비율';

  @override
  String runningCoachSprintSessionBodyNotVisibleValue(int percent) {
    return '$percent%';
  }

  @override
  String get runningCoachSprintSessionBodyVisibilityLabel => '전신 가시성';

  @override
  String runningCoachSprintSessionBodyVisibilityValue(
      Object status, int visible, int total, int percent) {
    return '$status · 핵심 $visible/$total · $percent%';
  }

  @override
  String get runningCoachSprintSessionActiveFeedbackLabel => '활성 피드백';

  @override
  String runningCoachSprintSessionActiveFeedbackValue(Object key, Object text) {
    return '$key · $text';
  }

  @override
  String get runningCoachSprintSessionFeedbackEmpty => '대기 중';

  @override
  String get runningCoachSprintSessionFeedbackChangesLabel => '피드백 변경 빈도';

  @override
  String runningCoachSprintSessionFeedbackChangesValue(
      int count, Object perMinute, int suppressed) {
    return '$count회 / $perMinute분당 · 쿨다운 보류 $suppressed';
  }

  @override
  String get runningCoachSprintSessionReadinessLabel => '준비 상태';

  @override
  String runningCoachSprintSessionReadinessValue(
      int visible, int missing, int stable, Object travel) {
    return '보임 $visible · 누락 $missing · 안정 $stable · 이동 $travel';
  }

  @override
  String get runningCoachSprintSessionStepDetectorLabel => '스텝 판정';

  @override
  String runningCoachSprintSessionStepDetectorValue(
      int switches, int accepted, int lowVelocity, int minInterval) {
    return '교차 $switches · 채택 $accepted · 저속 $lowVelocity · 간격 $minInterval';
  }

  @override
  String get runningCoachSprintSessionConfidenceLabel => '랜드마크 신뢰도';

  @override
  String runningCoachSprintSessionConfidenceValue(
      int high, int medium, int low) {
    return '0.8+ $high% · 0.6-0.8 $medium% · <0.6 $low%';
  }

  @override
  String get runningCoachSprintMetricPending => '--';

  @override
  String get runningCoachSprintMetricTrunkLabel => '전경사';

  @override
  String runningCoachSprintMetricTrunkValue(Object value) {
    return '$value°';
  }

  @override
  String get runningCoachSprintMetricKneeDriveLabel => '무릎 드라이브';

  @override
  String runningCoachSprintMetricKneeDriveValue(Object value) {
    return '스케일 $value%';
  }

  @override
  String get runningCoachSprintMetricCadenceLabel => '케이던스';

  @override
  String runningCoachSprintMetricCadenceValue(Object value) {
    return '$value spm';
  }

  @override
  String get runningCoachSprintMetricRhythmLabel => '리듬 변동';

  @override
  String runningCoachSprintMetricRhythmValue(Object value) {
    return '${value}ms';
  }

  @override
  String get runningCoachSprintMetricArmBalanceLabel => '팔 균형';

  @override
  String runningCoachSprintMetricArmBalanceValue(Object value) {
    return '차이 $value%';
  }

  @override
  String get runningCoachSprintBodyVisibilityFull => '전신 확보';

  @override
  String get runningCoachSprintBodyVisibilityPartial => '일부 누락';

  @override
  String get runningCoachSprintBodyVisibilityNotVisible => '전신 미확보';

  @override
  String get runningCoachSprintCueBodyVisible =>
      '몸 전체가 프레임 안에 보이도록 한 걸음만 더 조정해 주세요.';

  @override
  String get runningCoachSprintCueLeanForward =>
      '허리로 꺾지 말고 발목부터 상체를 조금 더 앞으로 유지해 주세요.';

  @override
  String get runningCoachSprintCueDriveKnee =>
      '지면에서 밀어낸 뒤 무릎을 조금 더 강하게 앞으로 끌어올려 보세요.';

  @override
  String get runningCoachSprintCueKeepRhythm =>
      '좌우 리듬이 흔들리고 있어요. 접지 간격을 조금 더 일정하게 맞춰 보세요.';

  @override
  String get runningCoachSprintCueBalanceArms =>
      '팔 스윙 좌우 차이가 커요. 뒤로 당기는 길이를 비슷하게 맞춰 보세요.';

  @override
  String get runningCoachSprintCueKeepPushing =>
      '좋아요. 지금 리듬과 전경사를 유지한 채 그대로 밀고 나가세요.';

  @override
  String get runningCoachSelectedVideoLabel => '선택한 영상';

  @override
  String get runningCoachNoVideoSelected => '아직 선택한 영상이 없어요.';

  @override
  String get runningCoachPickVideoAction => '영상 선택';

  @override
  String get runningCoachAnalyzeAction => '달리기 분석';

  @override
  String get runningCoachAnalysisInProgress => '분석 중...';

  @override
  String get runningCoachPickVideoFailed => '영상 선택기를 열지 못했어요.';

  @override
  String get runningCoachUnsupportedPlatform =>
      '달리기 영상 분석은 안드로이드와 iPhone/iPad 앱에서만 지원해요.';

  @override
  String get runningCoachNativeAnalyzerUnavailable =>
      '이 앱 빌드에는 달리기 영상 분석기가 포함되지 않았어요. 최신 모바일 앱으로 다시 설치한 뒤 시도해 주세요.';

  @override
  String get runningCoachVideoFileMissing => '선택한 영상 파일을 찾지 못했어요.';

  @override
  String get runningCoachVideoTooShort => '영상이 너무 짧아요. 몇 걸음 이상 달리는 장면을 찍어 주세요.';

  @override
  String get runningCoachNoPoseDetected =>
      '러너 자세를 충분히 추적하지 못했어요. 팔꿈치, 무릎, 발이 잘 보이는 더 선명한 측면 영상을 사용해 주세요.';

  @override
  String get runningCoachAnalysisFailedGeneric =>
      '달리기 분석에 실패했어요. 측면이 더 잘 보이는 영상으로 다시 시도해 주세요.';

  @override
  String get runningCoachResultsTitle => '코칭 결과';

  @override
  String get runningCoachOverallHeadlineStrong => '달리기 형태가 좋아요';

  @override
  String get runningCoachOverallHeadlineSolid => '기본은 좋고 한 가지 포인트만 다듬으면 돼요';

  @override
  String get runningCoachOverallHeadlineNeedsWork =>
      '달리기 패턴을 더 깔끔하게 만들 필요가 있어요';

  @override
  String runningCoachOverallSummary(int score) {
    return '전체 달리기 점수 $score/100';
  }

  @override
  String get runningCoachDurationLabel => '영상 길이';

  @override
  String get runningCoachFramesAnalyzedLabel => '분석 프레임';

  @override
  String get runningCoachCoverageLabel => '추적 비율';

  @override
  String get runningCoachMetricValueLabel => '측정값';

  @override
  String get runningCoachStatusGood => '좋음';

  @override
  String get runningCoachStatusWatch => '주의';

  @override
  String get runningCoachStatusNeedsWork => '보완 필요';

  @override
  String runningCoachLeanValue(Object value) {
    return '전경사 $value°';
  }

  @override
  String runningCoachBounceValue(Object value) {
    return '수직 바운스 $value%';
  }

  @override
  String runningCoachFootStrikeValue(Object value) {
    return '엉덩이 앞 $value배';
  }

  @override
  String runningCoachKneeValue(Object value) {
    return '지지 무릎 각도 $value°';
  }

  @override
  String runningCoachArmValue(Object value) {
    return '팔꿈치 각도 $value°';
  }

  @override
  String runningCoachStrideValue(Object value) {
    return '보폭 도달 $value배';
  }

  @override
  String get runningCoachInsightPostureTitle => '상체 자세';

  @override
  String get runningCoachPostureGoodSummary =>
      '상체 각도가 가벼운 전경사를 유지해서 깔끔한 스프린트 자세에 가까워요.';

  @override
  String get runningCoachPostureGoodCue =>
      '가슴은 세우고 몸 전체가 한 줄로 앞으로 기울어진 느낌을 유지해 보세요.';

  @override
  String get runningCoachPostureGoodDrill =>
      '드릴: 벽 기대기 마치 15m x 2세트로 같은 몸선 유지하기.';

  @override
  String get runningCoachPostureUprightSummary =>
      '상체가 너무 곧게 서 있어서 한 걸음마다 앞으로 나가는 힘이 줄 수 있어요.';

  @override
  String get runningCoachPostureUprightCue =>
      '\"코가 발끝 위에 온다\"는 느낌으로 허리가 아니라 발목에서 가볍게 기울여 보세요.';

  @override
  String get runningCoachPostureUprightDrill =>
      '드릴: 폴링 스타트 15m x 2세트 후 벽 기대기 마치 15m x 2세트.';

  @override
  String get runningCoachPostureLeanSummary =>
      '상체 기울기가 너무 커서 보폭이 무너지거나 회복 동작이 늦어질 수 있어요.';

  @override
  String get runningCoachPostureLeanCue =>
      '엉덩이를 세우고 갈비뼈가 골반 위에 쌓이는 느낌으로 달려 보세요.';

  @override
  String get runningCoachPostureLeanDrill => '드릴: 가볍고 빠른 발로 톨 포스처 런 20m x 2세트.';

  @override
  String get runningCoachInsightBounceTitle => '바운스';

  @override
  String get runningCoachBounceGoodSummary =>
      '상하 움직임이 잘 제어돼서 에너지가 앞으로 잘 전달되는 편이에요.';

  @override
  String get runningCoachBounceGoodCue => '위로 튀기보다 뒤로 밀어낸다는 느낌을 계속 가져가세요.';

  @override
  String get runningCoachBounceGoodDrill => '드릴: 다음 스프린트 전에 앵클 드리블 20m x 2세트.';

  @override
  String get runningCoachBounceHighSummary =>
      '상하 바운스가 조금 커서 에너지가 위로 새고 있을 수 있어요.';

  @override
  String get runningCoachBounceHighCue =>
      '짧고 빠른 지면 접촉으로 뒤로 밀어내고, 위로 튀는 느낌은 줄여 보세요.';

  @override
  String get runningCoachBounceHighDrill =>
      '드릴: 앵클 드리블 20m x 3세트와 스트레이트 레그 런으로 짧은 접촉 만들기.';

  @override
  String get runningCoachInsightFootStrikeTitle => '발 착지';

  @override
  String get runningCoachFootStrikeGoodSummary =>
      '앞발이 엉덩이 아래에 비교적 가깝게 착지해서 리듬을 끊지 않고 앞으로 이어 갈 수 있어요.';

  @override
  String get runningCoachFootStrikeGoodCue =>
      '앞으로 뻗기보다 엉덩이 아래에 가깝게 착지하고 뒤로 밀어내는 느낌을 유지하세요.';

  @override
  String get runningCoachFootStrikeGoodDrill =>
      '드릴: 짧고 빠른 접촉을 만드는 위켓 스타일 런 20m x 2세트.';

  @override
  String get runningCoachFootStrikeOverSummary =>
      '앞발이 엉덩이보다 너무 멀리 앞에 닿아 접지 때 브레이크가 걸릴 수 있어요.';

  @override
  String get runningCoachFootStrikeOverCue =>
      '착지 지점을 엉덩이 아래로 더 당기고, 앞으로 뻗기보다 뒤로 미는 느낌을 가져가세요.';

  @override
  String get runningCoachFootStrikeOverDrill =>
      '드릴: A-마치 20m x 2세트 후 짧은 접촉 위켓 스타일 런 20m x 2세트.';

  @override
  String get runningCoachInsightKneeTitle => '무릎 굴곡';

  @override
  String get runningCoachKneeGoodSummary =>
      '지지 무릎이 너무 잠기지 않으면서도 무너지지 않게 잘 버텨 주고 있어요.';

  @override
  String get runningCoachKneeGoodCue =>
      '착지할 때 무릎은 부드럽게 받고, 바로 튀어나가는 반응성을 유지하세요.';

  @override
  String get runningCoachKneeGoodDrill =>
      '드릴: 포고 런 20m x 2세트 후 드리블 런 20m x 2세트.';

  @override
  String get runningCoachKneeStraightSummary =>
      '지지 무릎이 너무 펴진 채 닿아서 착지가 딱딱하고 무거워질 수 있어요.';

  @override
  String get runningCoachKneeStraightCue =>
      '무릎을 완전히 잠그지 말고, 엉덩이 아래에서 부드럽게 받아 주세요.';

  @override
  String get runningCoachKneeStraightDrill =>
      '드릴: 살짝 굽힌 무릎으로 짧게 접지하는 드리블 런 20m x 2세트.';

  @override
  String get runningCoachKneeCollapseSummary =>
      '지지 무릎이 접지 뒤에 너무 많이 접혀서 다리 스프링이 무너지고 있어요.';

  @override
  String get runningCoachKneeCollapseCue =>
      '지지 다리를 너무 주저앉히지 말고, 엉덩이와 발 위에서 탄성 있게 버텨 보세요.';

  @override
  String get runningCoachKneeCollapseDrill =>
      '드릴: 한 발 포고 홉 각 15m x 2세트 후 드리블 런 20m x 2세트.';

  @override
  String get runningCoachInsightArmTitle => '팔 각도';

  @override
  String get runningCoachArmGoodSummary =>
      '팔꿈치가 적당히 접힌 범위 안에서 움직여서 리듬을 잘 도와주고 있어요.';

  @override
  String get runningCoachArmGoodCue => '팔꿈치를 적당히 굽힌 채 손이 앞뒤로 자연스럽게 오가게 유지하세요.';

  @override
  String get runningCoachArmGoodDrill =>
      '드릴: 벽 팔 스위치 20초 x 2세트 후 암 드라이브 마치 20m x 2세트.';

  @override
  String get runningCoachArmOpenSummary =>
      '팔꿈치가 너무 많이 펴져서 팔 스윙 리듬이 새고 있을 수 있어요.';

  @override
  String get runningCoachArmOpenCue =>
      '팔꿈치를 더 접고, 손이 길게 뻗기보다 엉덩이 뒤로 지나가게 밀어 보세요.';

  @override
  String get runningCoachArmOpenDrill =>
      '드릴: 팔꿈치 80~100도를 유지한 벽 팔 스위치 20초 x 2세트.';

  @override
  String get runningCoachArmTightSummary =>
      '팔꿈치가 너무 접혀 있어서 팔 스윙이 짧아지고 보폭 리듬이 답답해질 수 있어요.';

  @override
  String get runningCoachArmTightCue =>
      '어깨 힘을 풀고, 팔꿈치가 조금 더 열리면서 뒤로 밀리는 동작을 만들어 보세요.';

  @override
  String get runningCoachArmTightDrill =>
      '드릴: 어깨 힘을 빼고 부드럽게 뒤로 미는 암 스윙 마치 20m x 2세트.';

  @override
  String get runningCoachInsightStrideTitle => '보폭 도달';

  @override
  String get runningCoachStrideGoodSummary =>
      '앞발 착지가 몸 아래 근처의 좋은 구간 안에 들어오는 편이에요.';

  @override
  String get runningCoachStrideGoodCue =>
      '앞으로 뻗으려 하지 말고, 밀어낸 힘으로 자연스럽게 보폭이 열리게 유지하세요.';

  @override
  String get runningCoachStrideGoodDrill =>
      '드릴: 빠른 리듬을 유지하는 위켓 스타일 런 20m x 2세트.';

  @override
  String get runningCoachStrideShortSummary =>
      '보폭 도달이 짧아서 동작을 너무 묶고 달릴 가능성이 있어 보여요.';

  @override
  String get runningCoachStrideShortCue =>
      '팔 리듬을 조금 더 빠르게 쓰고, 무릎을 앞쪽으로 보내면서 보폭이 자연스럽게 열리게 해 보세요.';

  @override
  String get runningCoachStrideShortDrill =>
      '드릴: A-마치 후 A-스킵 20m x 2세트로 앞쪽 메커닉 만들기.';

  @override
  String get runningCoachStrideOverSummary =>
      '앞발이 몸보다 너무 멀리 나가 브레이크가 걸릴 수 있어요.';

  @override
  String get runningCoachStrideOverCue =>
      '엉덩이 아래에 가깝게 착지하고, 뻗기보다 지면을 밀어서 속도를 만드세요.';

  @override
  String get runningCoachStrideOverDrill =>
      '드릴: A-마치 20m x 2세트와 짧은 접촉 위켓 스타일 런 20m x 2세트.';

  @override
  String get runningCoachSprintDebugToggle => '스프린트 디버그 오버레이 토글';

  @override
  String get runningCoachSprintDebugPanelTitle => '디버그 오버레이';

  @override
  String get runningCoachSprintCueWhyLabel => '원인';

  @override
  String get runningCoachSprintCueTryLabel => '시도';

  @override
  String get runningCoachSprintTrackingStateBodyTooSmall => '카메라에 더 가깝게';

  @override
  String get runningCoachSprintTrackingStateBodyOutOfFrame => '전신을 프레임 안에';

  @override
  String get runningCoachSprintTrackingStateLowConfidence => '트래킹 신뢰도 올리기';

  @override
  String get runningCoachSprintTrackingStateSideViewUnstable => '측면 구도 안정화';

  @override
  String get runningCoachSprintTrackingStateReady => '분석 준비 완료';

  @override
  String get runningCoachSprintTrackingHintBodyTooSmall =>
      '러너가 프레임에서 너무 작습니다. 먼저 더 가깝게 맞춰 주세요.';

  @override
  String get runningCoachSprintTrackingHintBodyOutOfFrame =>
      '일부 관절이 프레임 밖으로 나가서 포즈 라인이 안정적으로 붙지 않습니다.';

  @override
  String get runningCoachSprintTrackingHintLowConfidence =>
      '현재 포즈 신뢰도가 낮습니다. 카메라를 조금 더 안정적으로 유지해 주세요.';

  @override
  String get runningCoachSprintTrackingHintSideViewUnstable =>
      '측면 움직임이 아직 불안정합니다. 더 선명한 측면 동선으로 다시 잡아 주세요.';

  @override
  String get runningCoachSprintTrackingDiagnosisBodyTooSmall =>
      '현재 전신 박스가 너무 작아서 실기기에서 전경사, 무릎, 리듬 값을 안정적으로 읽기 어렵습니다.';

  @override
  String get runningCoachSprintTrackingDiagnosisBodyOutOfFrame =>
      '핵심 관절이 화면 가장자리에서 잘려 overlay와 feature 값이 함께 흔들릴 수 있습니다.';

  @override
  String get runningCoachSprintTrackingDiagnosisLowConfidence =>
      '보이는 관절 수나 평균 landmark confidence가 현재 코칭 품질 기준 아래입니다.';

  @override
  String get runningCoachSprintTrackingDiagnosisSideViewUnstable =>
      '움직임 경로가 충분히 측면으로 유지되지 않아 측면 분석을 아직 열지 않고 있습니다.';

  @override
  String get runningCoachSprintTrackingActionBodyTooSmall =>
      '전신 높이가 화면의 절반 정도 이상이 되도록 카메라를 더 가깝게 맞춰 주세요.';

  @override
  String get runningCoachSprintTrackingActionBodyOutOfFrame =>
      '머리, 팔꿈치, 엉덩이, 발목이 모두 가이드 안에 들어온 뒤 다시 질주해 주세요.';

  @override
  String get runningCoachSprintTrackingActionLowConfidence =>
      '카메라 흔들림을 줄이고 조명을 밝게 한 뒤 몇 프레임 동안 중앙을 유지해 주세요.';

  @override
  String get runningCoachSprintTrackingActionSideViewUnstable =>
      '카메라 쪽으로 다가오지 말고 화면을 가로지르는 측면 질주로 맞춰 주세요.';

  @override
  String runningCoachSprintTrackingSummary(
      Object state, int heightPercent, int areaPercent) {
    return '$state · 높이 $heightPercent% · 면적 $areaPercent%';
  }

  @override
  String runningCoachSprintSpeechSummary(Object state, Object reason) {
    return '음성 $state · $reason';
  }

  @override
  String get runningCoachSprintSpeechStateIdle => '대기';

  @override
  String get runningCoachSprintSpeechStateQueued => '큐 등록';

  @override
  String get runningCoachSprintSpeechStateStarted => '재생 시작';

  @override
  String get runningCoachSprintSpeechStateCompleted => '재생 완료';

  @override
  String get runningCoachSprintSpeechStateSkipped => '스킵';

  @override
  String get runningCoachSprintSpeechStateCancelled => '취소';

  @override
  String get runningCoachSprintSpeechStateError => '오류';

  @override
  String get runningCoachSprintSpeechSkipNone => '스킵 없음';

  @override
  String get runningCoachSprintSpeechSkipDisabled => '음성 피드백이 꺼져 있습니다';

  @override
  String get runningCoachSprintSpeechSkipNoFeedbackSelected => '선택된 피드백이 없습니다';

  @override
  String get runningCoachSprintSpeechSkipEmptyCue => '읽을 cue 문구가 비어 있습니다';

  @override
  String get runningCoachSprintSpeechSkipInfoFeedback => '경고성 cue만 음성으로 읽습니다';

  @override
  String get runningCoachSprintSpeechSkipTrackingNotReady =>
      '트래킹이 아직 준비되지 않았습니다';

  @override
  String get runningCoachSprintSpeechSkipLowConfidence =>
      '음성으로 읽기에는 피드백 신뢰도가 낮습니다';

  @override
  String get runningCoachSprintSpeechSkipTrackingNotStable =>
      '트래킹 안정 프레임이 아직 부족합니다';

  @override
  String get runningCoachSprintSpeechSkipCooldownActive => '음성 쿨다운이 아직 남아 있습니다';

  @override
  String get runningCoachSprintDiagnosisLeanForward =>
      '상체가 너무 빨리 세워져서 첫 가속 구간의 전방 추진이 끊기고 있습니다.';

  @override
  String get runningCoachSprintDiagnosisDriveKnee =>
      '무릎 드라이브가 엉덩이 대비 낮아서 앞쪽 스텝 연결이 약해지고 있습니다.';

  @override
  String get runningCoachSprintDiagnosisKeepRhythm =>
      '스텝 간격 변동이 커서 좌우 스프린트 리듬이 흔들리고 있습니다.';

  @override
  String get runningCoachSprintDiagnosisBalanceArms =>
      '한쪽 팔의 뒤로 미는 기여가 작아서 상체 리듬 지원이 비대칭으로 보입니다.';

  @override
  String get runningCoachSprintDiagnosisKeepPushing =>
      '핵심 스프린트 feature가 현재 MVP 범위 안에 있어 지금 형태를 유지하는 cue를 주고 있습니다.';

  @override
  String get runningCoachSprintActionLeanForward =>
      '첫 세 걸음 동안 가슴을 더 낮게 두고 발목부터 기울어지는 느낌을 유지해 보세요.';

  @override
  String get runningCoachSprintActionDriveKnee =>
      '무릎만 억지로 들기보다 지면을 더 강하게 밀어내고 그 결과로 무릎이 지나오게 해 보세요.';

  @override
  String get runningCoachSprintActionKeepRhythm =>
      '보폭을 억지로 늘리지 말고 다음 몇 걸음의 접지 간격을 더 고르게 맞춰 보세요.';

  @override
  String get runningCoachSprintActionBalanceArms =>
      '양쪽 팔의 뒤로 미는 길이를 비슷하게 맞추고 어깨 흔들림을 줄여 보세요.';

  @override
  String get runningCoachSprintActionKeepPushing =>
      '지금 형태를 몇 걸음 더 유지해서 앱이 안정성을 다시 확인하게 해 주세요.';

  @override
  String get runningCoachSprintSessionTrackingStateLabel => '트래킹 상태';

  @override
  String get runningCoachSprintSessionPersonSizeLabel => '사람 크기';

  @override
  String runningCoachSprintSessionPersonSizeValue(
      int heightPercent, int areaPercent) {
    return '높이 $heightPercent% · 면적 $areaPercent%';
  }

  @override
  String get runningCoachSprintSessionVisibleJointCountLabel => '보이는 관절 수';

  @override
  String runningCoachSprintSessionVisibleJointCountValue(
      int count, Object confidence) {
    return '$count개 · 평균 $confidence';
  }

  @override
  String get runningCoachSprintSessionSpeechStateLabel => '음성 상태';

  @override
  String runningCoachSprintSessionSpeechStateValue(
      Object state, Object reason, int cooldownMs) {
    return '$state · $reason · 쿨다운 ${cooldownMs}ms';
  }

  @override
  String get runningCoachSprintSessionFeatureConfidenceLabel => 'feature 신뢰도';

  @override
  String runningCoachSprintSessionFeatureConfidenceValue(
      Object trunk, Object knee, Object rhythm) {
    return '$trunk / $knee / $rhythm';
  }

  @override
  String runningCoachSprintSessionFeatureDebugValue(
      Object feature, Object value, int confidence) {
    return '$feature $value ($confidence%)';
  }

  @override
  String runningCoachSprintSessionFeatureUnavailableValue(
      Object feature, Object reason) {
    return '$feature 사용 불가: $reason';
  }

  @override
  String get runningCoachSprintFeatureUnavailableJointWindow =>
      '안정적인 관절 프레임이 부족함';

  @override
  String get runningCoachSprintFeatureUnavailableStepEvents =>
      '안정적인 스텝 이벤트가 부족함';
}
