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
  String get homeWeatherOutfitLayersLabel => '레이어';

  @override
  String get homeWeatherOutfitOuterLabel => '아우터';

  @override
  String get homeWeatherOutfitBottomLabel => '하의';

  @override
  String get homeWeatherOutfitAccessoriesLabel => '준비물';

  @override
  String get homeWeatherOutfitNotesLabel => '주의 포인트';

  @override
  String get homeWeatherOutfitViewAllCases => '모든 복장 케이스 보기';

  @override
  String get homeWeatherOutfitAllCasesTitle => '전체 복장 케이스';

  @override
  String get homeWeatherOutfitAllCasesSubtitle =>
      '날씨대별 추천 복장을 레이어, 하의, 준비물까지 자세히 확인하세요.';

  @override
  String get homeWeatherOutfitCaseHotTitle => '한여름 더위';

  @override
  String get homeWeatherOutfitCaseHotRange => '체감 30°C 이상';

  @override
  String get homeWeatherOutfitCaseWarmTitle => '따뜻한 훈련 날';

  @override
  String get homeWeatherOutfitCaseWarmRange => '체감 22~29°C';

  @override
  String get homeWeatherOutfitCaseMildTitle => '선선한 날';

  @override
  String get homeWeatherOutfitCaseMildRange => '체감 15~21°C';

  @override
  String get homeWeatherOutfitCaseCoolTitle => '쌀쌀한 날';

  @override
  String get homeWeatherOutfitCaseCoolRange => '체감 8~14°C';

  @override
  String get homeWeatherOutfitCaseColdTitle => '추운 날';

  @override
  String get homeWeatherOutfitCaseColdRange => '체감 2~7°C';

  @override
  String get homeWeatherOutfitCaseWetTitle => '비·눈 오는 날';

  @override
  String get homeWeatherOutfitCaseWetRange => '강수 또는 적설 시';

  @override
  String get homeWeatherAirQualityTitle => '대기질';

  @override
  String get homeWeatherAirQualitySubtitle => '숫자가 낮을수록 숨쉬기 편한 공기예요.';

  @override
  String get homeWeatherAirGuideTitle => '야외 활동 가이드';

  @override
  String get homeWeatherAirGuideUnknown =>
      '대기질 데이터를 다시 불러오면 야외 활동 가이드를 보여드릴게요.';

  @override
  String get homeWeatherAirGuideGood => '일반 야외 활동과 훈련을 진행하기 무난한 공기 상태예요.';

  @override
  String get homeWeatherAirGuideModerate =>
      '대부분의 야외 활동은 가능하지만, 호흡이 예민하면 강도를 조금 낮추세요.';

  @override
  String get homeWeatherAirGuideSensitive =>
      '민감군은 장시간 야외 활동이나 고강도 훈련을 줄이는 편이 좋아요.';

  @override
  String get homeWeatherAirGuideUnhealthy =>
      '야외 고강도 활동은 피하고, 가능하면 실내 훈련이나 회복 위주로 전환하세요.';

  @override
  String get homeWeatherAirGuideVeryUnhealthy =>
      '야외 활동은 최소화하고 실내 회복 또는 기술 훈련으로 바꾸는 편이 안전해요.';

  @override
  String get homeWeatherAirGuideHazardous =>
      '야외 활동을 중단하고 실내에서 쉬는 편이 더 안전한 공기 상태예요.';

  @override
  String get homeWeatherComparedYesterday => '어제 같은 시간 대비';

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

  @override
  String get headerEducationTooltip => '월드컵 역사책';

  @override
  String get homeWeatherNeedsLocationTitle => '위치 연결 필요';

  @override
  String get homeWeatherNeedsLocationSubtitle => '위치 켜고 확인';

  @override
  String get homeStreakBadgeActive => '연속 중';

  @override
  String get homeStreakBadgeResume => '다시 시작';

  @override
  String homeStreakActiveTodayTitle(int count) {
    return '$count일 연속 흐름을 이어가고 있어요';
  }

  @override
  String homeStreakActiveYesterdayTitle(int count) {
    return '어제까지 $count일 연속으로 기록했어요';
  }

  @override
  String homeStreakPausedTitle(int count) {
    return '$count일 연속 흐름이 잠시 멈췄어요';
  }

  @override
  String get homeStreakActiveTodayBody =>
      '오늘 기록까지 완료했어요. 내일도 짧게라도 남기면 연속 흐름이 더 단단해집니다.';

  @override
  String get homeStreakActiveYesterdayBody =>
      '오늘 한 번 더 남기면 최근의 좋은 리듬을 그대로 이어갈 수 있어요.';

  @override
  String homeStreakPausedBody(int gap) {
    return '$gap일 쉬었어요. 짧은 훈련부터 다시 적으면 리듬을 빠르게 되찾을 수 있어요.';
  }

  @override
  String homeStreakLastLogged(Object date) {
    return '마지막 기록 $date';
  }

  @override
  String homeStreakDaysValue(int count) {
    return '$count일';
  }

  @override
  String get homeStreakActionContinue => '오늘 기록';

  @override
  String get homeStreakActionReview => '주간 흐름';

  @override
  String get educationScreenTitle => '아빠가 태오에게 들려주는 월드컵 이야기';

  @override
  String get educationStoryIntroBody =>
      '태오야, 오늘은 월드컵을 문제집처럼 넘기지 말고 긴 이야기처럼 읽어 보자. 우승국 이름만 줄줄 외우는 것보다, 그 대회가 어떤 냄새와 소리와 표정을 남겼는지 같이 기억하는 편이 훨씬 오래 간다. 아빠는 네가 축구 역사를 볼 때 스코어 옆에 사람들의 얼굴과 시대의 공기까지 함께 보는 선수가 되었으면 좋겠어.\n\n그래서 이 화면도 책장을 열었다 닫았다 하는 식보다 한 번에 길게 읽을 수 있게 바꿔 두었다. 손가락으로 장을 넘기는 대신, 네가 직접 긴 시간을 천천히 걸어 내려가듯 읽으면 된다. 1930년 우루과이에서 시작한 이야기와 2026년 북중미를 바라보는 마음이 한 줄로 이어지는 느낌을 받았으면 한다.';

  @override
  String get educationStoryOriginsTitle => '1930-1938, 배를 타고 도착한 첫 번째 월드컵';

  @override
  String get educationStoryOriginsBody =>
      '태오야, 첫 월드컵은 비행기보다 배가 더 중요하던 시대에 시작됐어. 유럽 팀들은 몇 주씩 바다를 건너 우루과이로 향했고, 개최국은 독립 100주년의 열기 속에서 센테나리오 경기장을 급하게 완성했지. 지금 기준으로 보면 불편한 점투성이였겠지만, 바로 그 느림 때문에 첫 대회는 더 또렷하게 남아. 큰 대회는 원래 약간의 불편함과 함께 시작된다는 걸 월드컵이 처음부터 보여 준 셈이야.\n\n그리고 1934년과 1938년 이탈리아로 넘어가면, 아빠는 네가 결과표만 보지 않았으면 해. 무솔리니의 그림자, 길었던 항해, 참가를 둘러싼 반발, 판정 논쟁까지 같이 봐야 해. 월드컵은 시작부터 축구만의 세계가 아니었어. 이동 기술과 정치 분위기, 나라들 사이의 감정이 모두 잔디 위에 조금씩 묻어 있었지.\n\n그래서 1930, 1934, 1938을 외울 때는 숫자 셋만 외우지 말자. 바닷물 냄새, 연설문, 어딘가 불안한 박수 소리까지 같이 떠올리자. 그런 식으로 기억하면 역사는 시험 답안이 아니라 진짜 장면이 돼.';

  @override
  String get educationStoryReturnTitle => '1950-1970, 침묵과 미소가 같은 대회에 남는 법';

  @override
  String get educationStoryReturnBody =>
      '전쟁 때문에 비어 있던 시간을 지나 1950년 브라질 월드컵이 돌아왔을 때, 사람들은 아마 축제를 먼저 떠올렸을 거야. 그런데 태오야, 그 해를 말할 때 아빠는 늘 마라카낭의 침묵부터 이야기하게 된다. 우루과이가 브라질을 꺾은 그 충격은 한 경기 결과가 한 나라의 목소리 높이까지 바꿔 놓을 수 있다는 걸 보여 줬거든.\n\n그 뒤로는 1954 베른의 기적, 1958년 열일곱 살 펠레, 1962년 가린샤, 1966년 잉글랜드, 1970년 황금 브라질이 아주 빠르게 이어져. 월드컵은 이 시기를 지나면서 단순한 대회가 아니라 사람들의 집단 기억을 만드는 무대가 됐어. 누군가는 무너지고, 누군가는 태어나고, 누군가는 너무 완벽해서 오히려 전설처럼 보이지.\n\n아빠는 네가 이 구간을 읽을 때 재개, 충격, 탄생, 복수, 완성이라는 다섯 단어를 같이 떠올렸으면 해. 그러면 1950년부터 1970년까지의 긴 시간이 손바닥 안에 접히면서도 감정은 하나도 줄어들지 않거든.';

  @override
  String get educationStoryMiddleTitle => '1974-2006, 아름다움도 논쟁도 같이 기억해야 해';

  @override
  String get educationStoryMiddleBody =>
      '1974년에 들어오면 공기의 결이 또 달라져. 트로피가 바뀌고, 네덜란드는 토탈 풋볼로 경기장의 좌표를 흔들고, 서독은 그 아름다운 혼란을 결국 결과로 정리하지. 태오야, 아빠는 이 시기를 볼 때마다 축구가 이상과 현실이 가장 공개적으로 부딪히는 장소라는 생각을 해. 예쁜 장면은 쉽게 사랑받지만, 우승은 늘 조금 더 무거운 곳으로 기울더라.\n\n그런데 이 시대는 전술 이야기만으로 끝나지 않아. 1978년 아르헨티나에는 군사정권의 냉기가 배어 있고, 1982년에는 바티스통의 쓰러짐이 너무 오래 남아. 1986년의 마라도나는 거의 하나의 기후처럼 느껴지고, 1990년 로저 밀라의 춤과 2002년 한국의 4강, 2006년 지단의 박치기까지 오면 월드컵은 텔레비전 안에만 있지 않고 집 안 공기까지 흔드는 일이 돼.\n\n특히 2002년은 우리한테 남의 연표가 아니야. 길거리 함성, 늦은 밤의 들뜸, 경기가 끝나도 쉽게 가라앉지 않던 공기까지 다 같이 기억해야 해. 그러니까 태오야, 이 시기를 읽을 때는 누가 넣었는지만 보지 말고 어떤 밤이었는지도 꼭 같이 떠올리자.';

  @override
  String get educationStoryRecentTitle => '2010-2022, 숫자가 많아질수록 장면은 더 선명해졌어';

  @override
  String get educationStoryRecentBody =>
      '2010 남아공을 펼치면 먼저 부부젤라 소리가 들리고, 2014 브라질을 펼치면 7대1 전광판이 먼저 떠오른다. 2018 러시아에서는 VAR 모니터 앞의 정적이 있었고, 2022 카타르에서는 메시와 음바페가 한 경기 안에서 세대의 충돌과 계승을 같이 보여 줬지. 태오야, 데이터와 기술이 늘어나면 이야기가 흐려질 것 같지만, 이상하게도 월드컵은 그 반대로 갔어. 숫자가 많아질수록 장면은 더 강하게 몸에 남았거든.\n\n클로제의 16번째 골, 모로코의 4강, 수아레스의 골라인 핸드볼 같은 장면은 기록표 안에서도 설명되지만, 사람들이 오래 붙잡는 건 결국 순간의 표정이야. 아빠가 네게 꼭 말해 주고 싶은 것도 그거야. 표는 정리해 주지만, 장면은 이해하게 해 준다.\n\n그래서 최근 월드컵을 볼 때는 스코어와 데이터만 보고 끝내지 말자. 그 장면 앞에서 사람들이 왜 놀랐는지, 왜 오래 이야기했는지까지 같이 생각해야 진짜 네 축구 지도가 넓어진다.';

  @override
  String get educationStoryPeopleTitle => '사람, 정치, 기술까지 붙여야 역사가 완성돼';

  @override
  String get educationStoryPeopleBody =>
      '태오야, 월드컵은 우승국 표 하나로는 절대 다 설명되지 않아. 쥘 리메, 포초, 펠레, 베켄바워, 마라도나, 호나우두, 메시처럼 시대를 끌고 간 얼굴들을 같이 봐야 하고, 1942년과 1946년 대회 취소처럼 전쟁이 축구 달력까지 멈춰 세운 순간도 기억해야 해. 그래야 월드컵이 세상과 얼마나 빨리 닮아 갔는지 알 수 있어.\n\n1966년 쥘 리메 트로피를 찾아낸 개 피클스 이야기, 1982년 슈마허와 바티스통 충돌, 2010년 램파드의 오심 골, 2014년 골라인 기술, 2018년 VAR, 2022년 반자동 오프사이드도 같은 줄에 놓여야 해. 축구는 늘 더 공정해지려 하지만, 한편으로는 완벽한 공정함에 도달할 수 없다는 사실도 같이 보여 주거든.\n\n그러니까 어떤 대회를 볼 때는 두 가지 질문을 항상 같이 적자. 누가 이겼는가. 그리고 무엇이 바뀌었는가. 이 두 줄을 같이 적기 시작하면, 역사책은 훨씬 덜 딱딱하고 훨씬 더 정확해진다.';

  @override
  String get educationStoryFutureTitle => '2026 이후, 아직 안 열린 페이지를 읽는 방법';

  @override
  String get educationStoryFutureBody =>
      '이제 2026 북중미 월드컵을 바라보자. 48개국, 104경기, 세 나라 공동 개최라는 조건만으로도 이미 예전 대회와는 얼굴이 달라. 태오야, 아빠는 이런 숫자를 볼 때 우승 후보보다 먼저 이동 거리, 회복 시간, 벤치 전력, 낯선 상대를 빨리 읽는 능력을 떠올리게 된다. 대회가 길어질수록 스타 한 명보다 버티는 구조 전체가 더 중요해지기 때문이야.\n\n그래서 미래를 읽는다는 건 점쟁이처럼 우승 팀 하나를 맞히는 일이 아니야. 어떤 팀이 세트피스로 흔들리는 시간을 버틸 수 있는지, 어떤 팀이 긴 여정에서도 자기 리듬을 잃지 않는지, 어떤 팀이 18명에서 23명까지 실전 전력을 유지하는지를 보는 연습이지. 월드컵 역사를 오래 읽을수록 그런 조건들이 더 먼저 보이게 돼.\n\n아빠는 네가 2026을 볼 때도 과거와 같은 방식으로 읽었으면 좋겠어. 팀 이름만 적지 말고 압박, 전환, 세트피스, 수비 라인 안정성까지 같이 적어 두자. 그러면 미래 예측도 결국 과거를 제대로 읽는 힘에서 나온다는 걸 알게 될 거야.';

  @override
  String get educationStoryClosingBody =>
      '결국 태오야, 월드컵을 잘 본다는 건 결승 스코어 하나만 외우는 일이 아니야. 1930년의 첫 항해부터 2026년의 다음 질문까지 이어지는 긴 이야기를 천천히 따라가는 일이야. 아빠는 네가 그 이야기를 읽을 때마다 숫자보다 사람을, 결과보다 공기를, 한 경기보다 한 시대를 더 넓게 보게 되길 바란다.';

  @override
  String get educationHeroEyebrow => 'YOUTH SESSION KIT';

  @override
  String get educationHeroTitle => '바로 지도할 수 있는 유소년 축구 컨텐츠';

  @override
  String get educationHeroBody =>
      '설명은 짧게, 반복은 많이, 마무리는 질문으로 가져가는 3가지 세션을 담았어요.';

  @override
  String get educationHeroStatLessons => '3개 세션';

  @override
  String get educationHeroStatMinutes => '45분 흐름';

  @override
  String get educationHeroStatPrinciples => '코칭 원칙 포함';

  @override
  String get educationHeroStatHistory => '퀴즈 역사 포함';

  @override
  String get educationSectionLessonsTitle => '바로 쓰는 레슨';

  @override
  String get educationSectionHistoryTitle => '퀴즈 대비 역사';

  @override
  String get educationSectionHistoryBody =>
      '퀴즈에 자주 나오는 연도, 대회 이름, 상징 장면을 묶어서 정리했어요. 카드 한 장씩 보고 바로 퀴즈로 넘어가면 흐름을 잡기 좋습니다.';

  @override
  String get educationSectionPrinciplesTitle => '지도 포인트';

  @override
  String get educationHistoryWorldCupEyebrow => 'WORLD CUP ROOTS';

  @override
  String get educationHistoryWorldCupTitle => '월드컵 시작점';

  @override
  String get educationHistoryWorldCupSummary =>
      '첫 대회, 트로피 변화, 대표 기록을 한 번에 묶어서 월드컵 역사 문제의 뼈대를 잡는 카드입니다.';

  @override
  String get educationHistoryWorldCupFocus => '연도 + 개최국';

  @override
  String get educationHistoryWorldCupFact1 => '1930년 첫 FIFA 월드컵은 우루과이에서 열렸습니다.';

  @override
  String get educationHistoryWorldCupFact2 =>
      '쥘 리메 트로피는 1970년까지, 현재 FIFA 월드컵 트로피는 1974년부터 쓰입니다.';

  @override
  String get educationHistoryWorldCupFact3 =>
      '브라질은 남자 월드컵 최다 우승국으로, 미로슬라프 클로제는 통산 최다 득점자로 자주 나옵니다.';

  @override
  String get educationHistoryCompetitionEyebrow => 'COMPETITION TIMELINE';

  @override
  String get educationHistoryCompetitionTitle => '대회 이름과 출범';

  @override
  String get educationHistoryCompetitionSummary =>
      '리그와 유럽 대회는 출범 연도와 초대 우승팀을 함께 외우면 퀴즈 풀이 속도가 빨라집니다.';

  @override
  String get educationHistoryCompetitionFocus => '출범 + 첫 우승';

  @override
  String get educationHistoryCompetitionFact1 =>
      '프리미어리그는 1992년에 출범했고 1992-93 초대 우승팀은 맨체스터 유나이티드입니다.';

  @override
  String get educationHistoryCompetitionFact2 =>
      '유러피언컵은 1992-93 시즌부터 UEFA 챔피언스리그라는 이름으로 운영됐습니다.';

  @override
  String get educationHistoryCompetitionFact3 =>
      '아스널의 2003-04 인빈서블스 시즌은 프리미어리그 역사 문제의 대표 포인트입니다.';

  @override
  String get educationHistoryMomentsEyebrow => 'ICONIC MOMENTS';

  @override
  String get educationHistoryMomentsTitle => '역사 장면과 여자 축구';

  @override
  String get educationHistoryMomentsSummary =>
      '유명 장면은 연도와 상대를 같이 묶고, 여자 축구는 별도 타임라인으로 정리해 두면 기억이 오래갑니다.';

  @override
  String get educationHistoryMomentsFocus => '장면 + 상대';

  @override
  String get educationHistoryMomentsFact1 =>
      '마라도나의 \'신의 손\'은 1986년 월드컵 잉글랜드전에서 나왔습니다.';

  @override
  String get educationHistoryMomentsFact2 =>
      '지단의 헤더 사건은 2006 FIFA 월드컵 결승전의 상징 장면입니다.';

  @override
  String get educationHistoryMomentsFact3 => '첫 FIFA 여자 월드컵은 1991년 중국에서 열렸습니다.';

  @override
  String get educationModuleBallEyebrow => 'BALL MASTERY';

  @override
  String get educationModuleBallTitle => '터치 수 늘리기';

  @override
  String get educationModuleBallSummary =>
      '양발 인사이드와 아웃사이드, 방향 전환을 끊기지 않게 이어서 공과 친해지는 세션입니다.';

  @override
  String get educationModuleBallAge => 'U8-U10';

  @override
  String get educationModuleBallDuration => '12분';

  @override
  String get educationModuleBallCue1 => '시선은 가끔 앞을 보고, 발은 잔걸음으로 가볍게 움직입니다.';

  @override
  String get educationModuleBallCue2 => '빠른 속도보다 공이 몸 가까이에 머무는지 먼저 확인합니다.';

  @override
  String get educationModuleBallCue3 => '실수 뒤 멈추기보다 바로 다음 터치로 이어가게 격려합니다.';

  @override
  String get educationModulePassEyebrow => 'FIRST TOUCH & PASS';

  @override
  String get educationModulePassTitle => '첫 터치 후 패스';

  @override
  String get educationModulePassSummary =>
      '받고, 돌리고, 내주는 흐름으로 첫 터치 방향과 패스 정확도를 함께 익히는 세션입니다.';

  @override
  String get educationModulePassAge => 'U10-U12';

  @override
  String get educationModulePassDuration => '15분';

  @override
  String get educationModulePassCue1 => '받기 전에 어깨 너머를 한 번 보고 시작하게 합니다.';

  @override
  String get educationModulePassCue2 => '첫 터치는 다음 패스가 나갈 공간으로 두게 지도합니다.';

  @override
  String get educationModulePassCue3 => '패스 강도보다 정확한 발면과 몸 방향을 먼저 잡아줍니다.';

  @override
  String get educationModuleDecisionEyebrow => '1V1 DECISION';

  @override
  String get educationModuleDecisionTitle => '1대1 돌파와 선택';

  @override
  String get educationModuleDecisionSummary =>
      '속도 변화와 멈춤 동작으로 수비를 흔든 뒤 슈팅이나 패스로 끝내는 판단 세션입니다.';

  @override
  String get educationModuleDecisionAge => 'U11-U13';

  @override
  String get educationModuleDecisionDuration => '18분';

  @override
  String get educationModuleDecisionCue1 =>
      '첫 한 걸음은 크게, 방향 전환은 짧고 빠르게 가져가게 합니다.';

  @override
  String get educationModuleDecisionCue2 => '결과보다 타이밍을 보는 눈과 준비 동작을 먼저 칭찬합니다.';

  @override
  String get educationModuleDecisionCue3 => '성공 장면 뒤에는 왜 좋았는지 한 문장으로 되짚어 줍니다.';

  @override
  String get educationPrincipleOneTitle => '한 번에 한 가지';

  @override
  String get educationPrincipleOneBody =>
      '지시어는 짧고 바로 행동으로 옮길 수 있게 주세요. \"열어\", \"보고\", \"붙여\"처럼 한 단어가 좋습니다.';

  @override
  String get educationPrincipleTwoTitle => '실수 직후 칭찬 포인트 찾기';

  @override
  String get educationPrincipleTwoBody =>
      '결과가 아닌 준비 동작을 칭찬하면 아이가 도전을 멈추지 않고 다시 시도합니다.';

  @override
  String get educationPrincipleThreeTitle => '마지막 2분은 질문';

  @override
  String get educationPrincipleThreeBody =>
      '무엇이 쉬웠는지, 다음엔 무엇을 바꾸고 싶은지 묻게 하면 배운 내용이 더 오래 남습니다.';

  @override
  String get educationBookSectionStory => '태오의 장면';

  @override
  String get educationBookSectionTimeline => '핵심 연표';

  @override
  String get educationBookSectionFacts => '기억할 데이터';

  @override
  String get educationBookSectionNote => '태오의 메모';

  @override
  String get educationBookSwipeHint =>
      '페이지는 좌우 스와이프로만 넘길 수 있어요. 각 장 안에서는 아래로 천천히 읽어 주세요.';

  @override
  String get educationBookPreviousButton => '이전 장';

  @override
  String get educationBookNextButton => '다음 장';

  @override
  String educationBookProgressLabel(int current, int total) {
    return '$current/$total장';
  }

  @override
  String get educationBookCoverLabel => '프롤로그';

  @override
  String get educationBookCoverTitle => '밤의 서가에서 월드컵을 꺼내는 일';

  @override
  String get educationBookCoverSubtitle => '태오가 역사책의 첫 장을 여는 방식';

  @override
  String get educationBookCoverStory =>
      '훈련이 끝난 밤에는 이상하게도 공보다 종이가 더 무겁게 느껴질 때가 있다. 태오는 땀이 식어 가는 손으로 오래된 월드컵 프로그램북이 꽂힌 서가를 천천히 훑어본다. 종이에서는 먼지 냄새와 비슷한 것이 나고, 그 안쪽에는 몬테비데오의 항구, 마라카낭의 계단, 아즈테카의 햇빛, 루사일의 매끈한 밤공기가 차례대로 접혀 있다. 누군가가 오래전에 접어 둔 계절이 이제야 다시 펼쳐지는 것처럼 보인다.\n\n이 책은 축구 전체를 설명하려 들지 않는다. 월드컵이라는 한 줄기 강물만 따라간다. 1930년 우루과이에서 시작해 2022년 카타르까지 흘러온 물길을 더듬고, 그 끝에서 2026 북중미라는 아직 쓰이지 않은 장을 멀리 바라본다. 태오는 그런 구성이 마음에 든다. 모든 것을 다 아는 것보다 하나를 오래 바라보는 편이 가끔은 더 정확하다고 믿기 때문이다.\n\n그래서 태오는 빈 페이지 위에 1930, 1950, 1958, 1970, 1986, 1998, 2002, 2010, 2018, 2022, 2026을 천천히 적는다. 연도는 숫자처럼 보이지만, 오래 들여다보면 각기 다른 온도를 가진 방 이름처럼 느껴진다. 어떤 방에는 펠레의 웃음이 있고, 어떤 방에는 마라카낭의 침묵이 있고, 또 어떤 방에는 메시가 드디어 숨을 고르는 순간이 있다. 태오는 오늘 밤 그 방들의 문손잡이를 하나씩 만져 보기로 한다.';

  @override
  String get educationBookCoverTimeline =>
      '1904년 FIFA가 창설되며 월드컵을 준비할 국제 행정의 뼈대가 생겼습니다.\n1930년 우루과이에서 첫 남자 FIFA 월드컵이 열렸습니다.\n1942년과 1946년 대회는 제2차 세계대전 때문에 열리지 못했습니다.\n1974년부터는 쥘 리메 트로피 대신 현재의 FIFA 월드컵 트로피가 쓰였습니다.\n1998년 프랑스 월드컵부터 본선이 32개국 체제로 확대됐습니다.\n2018년 러시아 월드컵은 남자 월드컵에서 VAR이 본격 적용된 첫 대회였습니다.\n2026년 캐나다, 멕시코, 미국 대회는 48개국 104경기로 열릴 예정입니다.';

  @override
  String get educationBookCoverFacts =>
      '태오의 책갈피 1: 2022 카타르까지 남자 월드컵은 모두 22번 치러졌습니다.\n태오의 책갈피 2: 브라질 5회, 독일 4회, 이탈리아 4회, 아르헨티나 3회가 대표적인 우승 기준점입니다.\n태오의 책갈피 3: 미로슬라프 클로제의 16골은 남자 월드컵 개인 통산 최다 득점 기록입니다.\n태오의 책갈피 4: 월드컵은 연도, 개최국, 우승국, 명장면, 주인공을 한 묶음으로 읽어야 오래 남습니다.';

  @override
  String get educationBookCoverNote =>
      '태오는 이 책이 우승국 리스트가 아니라, 세계가 4년마다 어떤 얼굴을 보여 줬는지 읽는 연대기라고 적어 둡니다. 그래서 가장 최근 완료 대회인 2022와 다음 장의 문 앞에 선 2026을 서로 붙여 기억하기로 합니다.';

  @override
  String get educationBookOriginsLabel => '1장';

  @override
  String get educationBookOriginsTitle => '배를 타고 도착한 첫 번째 여름';

  @override
  String get educationBookOriginsSubtitle => '1930 우루과이, 1934 이탈리아, 1938 프랑스';

  @override
  String get educationBookOriginsStory =>
      '첫 번째 장은 비행기보다 배가 더 중요한 시대에서 시작된다. 유럽 팀들은 몇 주씩 바다를 건너 우루과이로 향했고, 개최국은 독립 100주년의 열기 속에서 센테나리오 경기장을 거의 숨 돌릴 틈도 없이 완성했다. 지금 기준으로 보면 모든 것이 느리고 불편했을 텐데, 이상하게도 그 느림 때문에 대회는 더 선명해 보인다. 큰일은 언제나 약간의 불편함을 데리고 온다는 사실을, 월드컵은 첫 장부터 알고 있었던 셈이다.\n\n1930년 우루과이가 초대 챔피언이 되고, 1934년과 1938년 이탈리아가 연달아 우승하는 동안 태오는 경기 결과보다 주변의 공기를 먼저 읽게 된다. 무솔리니의 그림자가 경기장 위로 길게 드리워져 있었고, 전쟁은 아직 시작되지 않았지만 이미 대륙 전체의 복도를 천천히 걸어 다니고 있었다. 월드컵은 생각보다 빨리 세상과 닮아 갔다. 승부, 이동, 정치, 보이콧, 판정 논쟁이 한꺼번에 같은 표지 안으로 들어왔다.\n\n태오는 이 시기를 읽으며 월드컵이 처음부터 순진한 대회는 아니었다는 것을 배운다. 바다는 팀들을 늦게 도착하게 했지만, 동시에 대회를 전설처럼 보이게 했다. 오래 걸려서 도착한 것들은 좀처럼 잊히지 않는다. 그래서 태오는 1930, 1934, 1938을 세 개의 숫자가 아니라, 물비린내와 연설문과 불안한 박수 소리로 기억해 두기로 한다.';

  @override
  String get educationBookOriginsTimeline =>
      '1930년 우루과이 대회는 13개국만 참가했지만 개최국이 초대 우승을 차지하며 강한 인상을 남겼습니다.\n1930년 결승전은 우루과이가 아르헨티나를 4대2로 꺾는 남미 맞대결로 끝났습니다.\n1934년 이탈리아 대회는 본선 전에 예선이 본격 적용된 첫 월드컵이었습니다.\n1934년 우루과이는 1930년 유럽 팀들의 불참에 반발해 대회에 나오지 않았습니다.\n1934년과 1938년 이탈리아는 비토리오 포초 감독 아래 월드컵 2연패를 달성했습니다.\n1938년 프랑스 대회에는 네덜란드령 동인도가 출전해 아시아 최초의 남자 월드컵 본선 참가 기록을 남겼습니다.';

  @override
  String get educationBookOriginsFacts =>
      '쥘 리메는 월드컵 창설을 밀어붙인 핵심 행정가로 이름이 트로피에 남았습니다.\n비토리오 포초는 지금도 남자 월드컵 2연패를 기록한 유일한 감독입니다.\n초창기 월드컵은 유럽과 남미의 긴 항해 거리 때문에 참가국 구성이 크게 흔들렸습니다.\n태오는 1930, 1934, 1938을 첫 대회, 첫 예선 시대, 첫 2연패라는 세 단어로 묶어 둡니다.';

  @override
  String get educationBookOriginsNote =>
      '태오는 1930, 1934, 1938을 붙여 기억합니다. 첫 대회, 첫 예선 시대, 첫 2연패. 월드컵은 시작부터 이미 축구만의 이야기가 아니라 세계정치와 이동 기술이 함께 만든 무대였습니다.';

  @override
  String get educationBookWorldCupLabel => '2장';

  @override
  String get educationBookWorldCupTitle => '침묵과 환호가 같은 구장에 남는 방식';

  @override
  String get educationBookWorldCupSubtitle => '1950 브라질부터 1970 멕시코까지';

  @override
  String get educationBookWorldCupStory =>
      '전쟁 때문에 비어 있던 두 번의 여름 뒤에 1950년 브라질 월드컵이 돌아왔을 때, 사람들은 아마 축제가 먼저 시작될 거라고 믿었을 것이다. 하지만 태오가 가장 먼저 만나는 장면은 환호가 아니라 침묵이다. 우루과이가 브라질을 꺾은 마라카낭의 충격은 한 경기의 결과가 한 나라의 목소리 높이까지 바꿔 버릴 수 있다는 걸 보여 준다. 월드컵은 그때부터 단순한 스포츠 행사라기보다 집단 기억을 만드는 기계처럼 보인다.\n\n그 뒤로 이어지는 몇 장은 놀랄 만큼 빠르게 전설이 된다. 1954년 베른의 기적, 1958년 열일곱 살 펠레의 등장, 1962년 가린샤의 어깨 위에 올라탄 브라질, 1966년 잉글랜드의 한 번뿐인 우승, 1970년 멕시코에서 완성된 황금 브라질. 태오는 이 흐름을 읽을수록 역사책이 결국 사람의 표정과 걸음걸이를 빌려 기억된다는 걸 알게 된다. 누군가는 무너지고, 누군가는 태어나고, 누군가는 너무 완벽해서 오히려 이야기처럼 보인다.\n\n그래서 태오는 1950부터 1970까지를 다섯 개의 단어로 접어 둔다. 재개, 충격, 탄생, 복수, 완성. 그렇게 적어 놓고 보면 긴 시대도 손바닥만 한 메모처럼 다뤄진다. 하지만 메모가 작다고 해서 그 안의 감정까지 작아지는 것은 아니다. 마라카낭의 침묵과 펠레의 미소는 서로 다른 방향으로 오래 남는다.';

  @override
  String get educationBookWorldCupTimeline =>
      '1950년 브라질 대회는 결승전 대신 최종 리그로 우승팀을 가렸고, 우루과이가 브라질을 꺾으며 마라카낭의 충격을 남겼습니다.\n1954년 서독은 무패 행진의 헝가리를 꺾고 베른의 기적을 만들었습니다.\n1958년 스웨덴 대회에서 17세 펠레는 세계 최고의 신성으로 떠올랐습니다.\n1962년 칠레 대회에서 브라질은 가린샤의 활약으로 2연패를 달성했습니다.\n1966년 잉글랜드는 제프 허스트의 해트트릭과 함께 자국 첫 우승을 기록했습니다.\n1970년 멕시코 대회에서 브라질은 세 번째 우승으로 쥘 리메 트로피를 영구 보유하게 됐습니다.\n1970년 결승전의 카를로스 아우베르투 골은 팀 골의 상징처럼 계속 회자됩니다.';

  @override
  String get educationBookWorldCupFacts =>
      '1954년 헝가리는 결승 전까지 30경기 넘게 무패에 가까운 흐름을 달리던 최강팀이었습니다.\n1970년 자이르지뉴는 브라질이 치른 모든 경기에서 골을 넣은 유일한 우승 팀 공격수라는 상징성을 가집니다.\n고든 뱅크스의 펠레 헤더 선방은 세기의 선방으로 불립니다.\n태오는 1950의 마라카낭, 1958의 펠레, 1970의 브라질을 한 줄로 묶어 기억합니다.';

  @override
  String get educationBookWorldCupNote =>
      '태오는 1950년부터 1970년까지의 월드컵을 읽고 이렇게 적어 둡니다. 월드컵은 전쟁 뒤의 복귀 행사이면서 동시에 새로운 천재를 세상에 소개하는 가장 큰 무대였다.';

  @override
  String get educationBookClubLabel => '3장';

  @override
  String get educationBookClubTitle => '아름다움과 불편함이 함께 자라는 시절';

  @override
  String get educationBookClubSubtitle => '1974 서독부터 1990 이탈리아까지';

  @override
  String get educationBookClubStory =>
      '1974년에 들어서면 책 속의 공기는 조금 달라진다. 트로피가 바뀌고, 네덜란드는 토탈 풋볼로 경기장의 좌표를 마음대로 흔들어 놓고, 서독은 그 아름다운 혼란을 끝내 결과로 정리해 버린다. 태오는 이 장을 읽을 때마다 축구가 이상과 현실이 가장 공개적으로 부딪히는 장소라는 생각을 한다. 멋진 움직임은 쉽게 사랑받지만, 우승은 대체로 좀 더 무거운 쪽으로 기운다.\n\n하지만 이 시대는 전술만으로 정리되지 않는다. 1978년 아르헨티나에는 군사정권의 냉기가 배어 있고, 1982년에는 바티스통이 쓰러지는 장면이 너무 오래 남아서 경기의 시간 자체를 찢어 놓는다. 1986년의 마라도나는 더 이상 선수라기보다 하나의 기압골처럼 등장한다. 신의 손과 다섯 명을 제친 골이 같은 여름에 있었고, 그 모순은 오히려 월드컵의 얼굴을 더 분명하게 만든다.\n\n1990년까지 읽고 나면 태오는 한 시대가 꼭 정돈된 문장으로 끝나지 않는다는 걸 이해한다. 로저 밀라의 춤, 베켄바워의 감독 우승, 마라도나의 울음이 서로 다른 온도로 남아 있기 때문이다. 역사라는 것은 깨끗하게 분류되는 것보다 조금 섞여 있을 때 더 오래 기억된다. 태오는 그래서 이 시기를 아름다움, 불편함, 재능, 논쟁이라는 네 개의 단어로만 간신히 묶어 둔다.';

  @override
  String get educationBookClubTimeline =>
      '1974년 서독 대회는 현재의 FIFA 월드컵 트로피가 처음 사용된 대회였습니다.\n1974년 크루이프 턴과 네덜란드의 토탈 풋볼은 결과보다 더 오래 남는 장면을 만들었습니다.\n1978년 아르헨티나는 첫 우승을 차지했지만 대회 배경에는 군사정권의 선전 논란이 따라붙었습니다.\n1982년 스페인 대회는 참가국이 24개국으로 늘어난 첫 남자 월드컵이었습니다.\n1982년 프랑스와 서독의 준결승은 월드컵 첫 승부차기 경기이자 슈마허-바티스통 충돌로도 기억됩니다.\n1986년 마라도나는 잉글랜드전에서 신의 손과 세기의 골을 같은 경기에서 남겼습니다.\n1990년 카메룬은 로저 밀라의 활약으로 아프리카 팀 최초의 8강 진출을 이뤘습니다.';

  @override
  String get educationBookClubFacts =>
      '프란츠 베켄바워는 1974년 선수, 1990년 감독으로 월드컵을 든 상징적 인물입니다.\n1982년 파올로 로시는 대회 전 징계를 끝내고 돌아와 이탈리아 우승의 얼굴이 됐습니다.\n1990년 월드컵은 수비적 경기 양상이 강해 규칙 변화 논의를 자극한 대회로 자주 언급됩니다.\n태오는 1974, 1978, 1982, 1986, 1990을 아름다움과 불편함이 동시에 남은 월드컵 연도로 묶습니다.';

  @override
  String get educationBookClubNote =>
      '태오는 이 시기를 읽고 월드컵이 언제나 예쁜 이야기만 남기지는 않는다고 적습니다. 하지만 그래서 더 오래 기억됩니다. 누가 이겼는지뿐 아니라 무엇이 사람들을 불편하게 했는지도 역사책의 일부이기 때문입니다.';

  @override
  String get educationBookTacticsLabel => '4장';

  @override
  String get educationBookTacticsTitle => '텔레비전 속 월드컵이 거실로 걸어 들어오던 밤';

  @override
  String get educationBookTacticsSubtitle =>
      '1994 미국, 1998 프랑스, 2002 한일, 2006 독일';

  @override
  String get educationBookTacticsStory =>
      '1994년 미국 월드컵에 이르면 태오는 대회가 완전히 다른 크기를 갖게 되는 순간을 본다. 거대한 경기장, 광고판의 밝기, 텔레비전 화면을 타고 번지는 열기, 그리고 결국 하늘로 떠버린 바조의 슛. 월드컵은 더 이상 먼 나라의 축제가 아니라 거실 한가운데에 갑자기 놓인 거대한 가구처럼 느껴진다. 누구든 그 앞을 지나치기 어렵다.\n\n1998년 프랑스의 지단, 2002년 한일 월드컵의 한국 4강과 호나우두의 복수, 2006년 독일 대회의 지단 박치기까지 읽다 보면 태오는 이 시기 월드컵이 유난히 화면 친화적이었다고 느낀다. 강한 장면은 언제나 재생되기 쉽고, 재생되는 장면은 세대의 공용 기억이 된다. 특히 2002년은 태오에게 남의 역사가 아니다. 집 근처 골목의 함성, 텔레비전 밑에 쌓인 빈 캔, 경기가 끝난 뒤에도 좀처럼 내려앉지 않던 밤공기까지 함께 따라온다.\n\n그렇게 생각하면 월드컵은 경기 결과표보다 조금 더 넓은 것이다. 누가 넣었는가보다 어떤 밤이었는가가 더 오래 남는 대회가 있다. 태오는 1994, 1998, 2002, 2006을 떠올릴 때 스코어보다 먼저 표정과 소음, 그리고 마지막 장면의 카메라 각도를 기억한다. 아마도 현대의 역사책은 원래 그렇게 쓰이는지도 모른다.';

  @override
  String get educationBookTacticsTimeline =>
      '1994년 미국 월드컵 결승은 남자 월드컵 역사상 처음으로 승부차기에서 우승팀이 결정됐습니다.\n1994년 로베르토 바조의 실축은 월드컵 결승의 가장 유명한 장면 중 하나가 됐습니다.\n1998년 프랑스 월드컵은 본선 32개국 체제의 시작이었습니다.\n1998년 로랑 블랑은 파라과이전에서 월드컵 첫 골든골을 기록했습니다.\n2002년 한국과 일본은 월드컵을 공동 개최한 첫 두 나라가 됐고, 한국은 4강에 올랐습니다.\n2002년 브라질의 호나우두는 8골로 득점왕이 되며 1998년 결승의 상처를 씻었습니다.\n2006년 독일 월드컵 결승은 지단의 박치기 퇴장과 이탈리아의 우승으로 끝났습니다.';

  @override
  String get educationBookTacticsFacts =>
      '히딩크, 스콜라리, 리피 같은 감독 이름도 이 시기 월드컵 기억에 강하게 붙어 있습니다.\n1998년 크로아티아의 다보르 수케르는 3위 돌풍과 함께 득점왕에 올랐습니다.\n2002년 세네갈의 8강, 터키의 4강은 강호만이 월드컵을 움직이는 게 아니라는 사실을 보여 줬습니다.\n태오는 1994, 1998, 2002, 2006을 결승전 장면과 함께 외워야 가장 오래 남는다고 적어 둡니다.';

  @override
  String get educationBookTacticsNote =>
      '태오는 특히 2002년 장에서 오래 머뭅니다. 한국 축구팬에게 월드컵 역사는 남의 연표가 아니라 직접 연결된 기억이라는 걸 알기 때문입니다. 그래서 태오는 2002년을 읽을 때마다 결과표 옆에 분위기와 목소리까지 같이 떠올리기로 합니다.';

  @override
  String get educationBookLegendsLabel => '5장';

  @override
  String get educationBookLegendsTitle => '숫자가 많아질수록 장면은 더 선명해졌다';

  @override
  String get educationBookLegendsSubtitle => '2010 남아공부터 2022 카타르까지';

  @override
  String get educationBookLegendsStory =>
      '2010년 남아공 페이지를 펼치면 태오는 먼저 부부젤라 소리를 듣는다. 어떤 대회는 눈보다 귀로 먼저 기억된다. 스페인의 우승, 수아레스의 골라인 핸드볼, 가나의 탈락, 문어 파울의 기묘한 인기는 서로 다른 종류의 진지함이 한 대회 안에서 동시에 살 수 있다는 것을 보여 준다. 월드컵은 여전히 역사책이지만, 동시에 밈과 소문과 농담의 저장소이기도 하다.\n\n2014년 브라질의 7대1, 2018년 러시아에서 본격화된 VAR, 2022년 카타르의 결승전까지 넘어오면 태오는 숫자가 점점 많아질수록 오히려 장면은 더 또렷해진다고 느낀다. 클로제의 16번째 골, 음바페의 질주, 메시의 마지막 빈칸, 모로코의 4강은 각기 다른 방향에서 역사의 선을 밀어 올린다. 데이터는 설명을 돕지만, 결국 마음속에 남는 것은 한 번도 숫자만이 아니었다.\n\n태오는 최근 월드컵들을 읽을 때면 늘 같은 결론으로 돌아온다. 사람들은 표보다 장면을 오래 기억한다. 7대1 전광판, VAR 모니터 앞의 정적, 연장전이 끝난 뒤 메시가 잠깐 고개를 숙이는 순간 같은 것들 말이다. 기록은 선반에 꽂히지만, 장면은 몸속 어딘가에 눌어붙는다.';

  @override
  String get educationBookLegendsTimeline =>
      '2010년 남아공 대회는 아프리카 대륙에서 열린 첫 남자 월드컵이었습니다.\n2010년 스페인은 이니에스타의 결승골로 첫 월드컵 우승을 차지했습니다.\n2010년 수아레스의 골라인 핸드볼과 가나의 탈락은 월드컵에서 가장 뜨거운 논쟁 장면 중 하나입니다.\n2014년 독일은 브라질을 7대1로 꺾고 결승에 올라 결국 우승했습니다.\n2014년 클로제는 브라질전에서 통산 16호 골을 넣어 월드컵 최다 득점 기록을 세웠습니다.\n2018년 러시아 월드컵은 남자 월드컵에 VAR이 처음 본격 적용된 대회였습니다.\n2022년 카타르 월드컵에서 모로코는 아프리카 팀 최초로 4강에 올랐고, 아르헨티나는 메시와 함께 우승했습니다.';

  @override
  String get educationBookLegendsFacts =>
      '2010년 문어 파울은 경기 결과를 맞히는 예측 아이콘으로 전 세계 화제가 됐습니다.\n킬리안 음바페는 2018년 우승과 2022년 결승 해트트릭으로 펠레 이후 가장 강한 월드컵 청춘 서사를 만들었습니다.\n리오넬 메시는 2022년 우승으로 월드컵 커리어의 마지막 빈칸을 채웠습니다.\n태오는 2010, 2014, 2018, 2022를 기술과 밈, 대참사, 신성, 완성이라는 다섯 감정으로 기억합니다.';

  @override
  String get educationBookLegendsNote =>
      '태오는 최근 월드컵을 읽으며 숫자와 데이터가 늘어도 결국 사람들은 장면을 기억한다는 점을 적어 둡니다. 부부젤라 소리, 7대1 전광판, VAR 체크, 메시의 미소처럼요.';

  @override
  String get educationBookAsiaLabel => '6장';

  @override
  String get educationBookAsiaTitle => '연도보다 얼굴이 먼저 떠오르는 순간';

  @override
  String get educationBookAsiaSubtitle => '쥘 리메부터 펠레, 마라도나, 베켄바워, 메시까지';

  @override
  String get educationBookAsiaStory =>
      '어느 지점부터 태오는 월드컵을 연표보다 사람 얼굴로 먼저 기억하게 된다. 대회를 가능하게 만든 쥘 리메, 두 번 연속 우승을 만든 포초, 세 번 정상에 선 펠레, 선수와 감독의 문을 모두 통과한 베켄바워, 한 번의 여름을 신화로 바꾼 마라도나. 이름을 하나씩 읽다 보면 역사는 뜻밖에도 아주 개인적인 표정을 띤다. 거대한 대회도 결국 몇 사람의 숨소리로 요약되곤 한다.\n\n이 장에 등장하는 인물들은 모두 완전하지 않다. 가린샤는 상처 입은 팀을 대신 짊어지고, 호나우두는 무너졌던 결승의 기억을 네 해 뒤에 뒤집고, 지단은 천재성과 파열음을 함께 남기고, 메시는 마지막에야 자기 문장을 끝낸다. 그래서 태오는 월드컵이 영웅을 만드는 장소라기보다, 이미 흔들리고 있던 사람의 윤곽을 더 크게 확대해 주는 장소에 가깝다고 느낀다.\n\n태오는 이름 옆에 반드시 연도와 장면을 붙여 적어 둔다. 펠레는 1958과 1970, 마라도나는 1986, 호나우두는 2002, 메시는 2022처럼 말이다. 이름만 쓰면 시험공부 같지만, 장면까지 붙이면 갑자기 이야기가 된다. 역사책이란 아마 그런 식으로만 끝내 살아남는 것인지도 모른다.';

  @override
  String get educationBookAsiaTimeline =>
      '쥘 리메는 월드컵 창설을 추진한 행정가로 대회 존재 이유 자체에 이름을 남겼습니다.\n비토리오 포초는 1934년과 1938년 이탈리아를 이끈 월드컵 2연패 감독입니다.\n펠레는 1958년, 1962년, 1970년 세 번 우승한 유일한 남자 선수입니다.\n프란츠 베켄바워는 1974년 선수, 1990년 감독으로 월드컵 우승을 모두 경험했습니다.\n마라도나는 1986년 멕시코 월드컵 한 대회만으로도 축구 역사 전체를 설명할 수 있는 인물로 남았습니다.\n호나우두는 2002년 8골과 우승으로 1998년 결승의 아픔을 가장 극적으로 뒤집었습니다.\n메시와 음바페는 2022년 결승전 하나로 세대 교체와 세대 공존을 동시에 보여 줬습니다.';

  @override
  String get educationBookAsiaFacts =>
      '쥐스트 퐁텐의 13골은 한 번의 월드컵에서 나온 개인 최다 득점 기록입니다.\n미로슬라프 클로제의 16골은 여러 대회에 걸친 통산 최다 득점 기록입니다.\n마리오 자갈루, 베켄바워, 디디에 데샹은 선수와 감독으로 모두 월드컵 우승을 맛본 상징적 이름들입니다.\n태오는 인물을 외울 때 이름, 국적, 대표 대회, 대표 장면을 한 줄로 정리합니다.';

  @override
  String get educationBookAsiaNote =>
      '태오는 결국 월드컵을 가장 빨리 기억하는 방법은 사람으로 기억하는 것이라고 적습니다. 연도만 외우면 시험처럼 남지만, 얼굴과 장면을 붙이면 이야기가 됩니다.';

  @override
  String get educationBookWomenLabel => '7장';

  @override
  String get educationBookWomenTitle => '경기장 바깥의 공기까지 읽는 법';

  @override
  String get educationBookWomenSubtitle => '전쟁, 정치, 도난, 그리고 판정 기술';

  @override
  String get educationBookWomenStory =>
      '태오는 어느 순간 우승국만 적혀 있는 역사책이 조금 불친절하다고 느낀다. 월드컵은 늘 경기장 안에서만 벌어진 것이 아니기 때문이다. 어떤 대회는 전쟁 때문에 아예 열리지 못했고, 어떤 대회는 독재의 그림자 아래에서 치러졌으며, 어떤 대회는 경기보다도 경기 밖 사건이 더 오래 회자된다. 세상의 공기는 언제나 잔디 위로 조금씩 스며든다.\n\n1966년 쥘 리메 트로피 도난 사건과 피클스라는 개의 발견담은 너무 기묘해서 오히려 진짜 역사처럼 느껴지지 않는다. 1982년 바티스통의 쓰러짐, 2010년 램파드의 오심 골, 2014년 골라인 기술, 2018년 VAR, 2022년 반자동 오프사이드는 경기 규칙이 얼마나 인간적인 불완전함을 붙들고 씨름해 왔는지를 보여 준다. 축구는 언제나 공정해지고 싶어 하지만, 동시에 완벽하게 공정해질 수 없다는 사실도 스스로 안다.\n\n그래서 태오는 월드컵을 읽을 때 두 가지 질문을 같이 적는다. 누가 이겼는가. 그리고 무엇이 바뀌었는가. 이 두 문장을 붙여 놓으면 비로소 한 대회의 윤곽이 선명해진다. 역사는 점수판만으로는 끝나지 않고, 늘 그 뒤쪽의 공기까지 함께 읽어야 완성된다.';

  @override
  String get educationBookWomenTimeline =>
      '1942년과 1946년 월드컵 취소는 세계대전이 축구 달력까지 멈추게 한 사건이었습니다.\n1966년 잉글랜드 대회 개막 전 쥘 리메 트로피 도난 사건이 벌어졌고, 강아지 피클스가 트로피를 찾아냈습니다.\n1978년 아르헨티나 월드컵은 군사정권 아래에서 열린 정치적 긴장 속 대회로 기억됩니다.\n1982년 프랑스-서독 준결승의 슈마허-바티스통 충돌은 스포츠맨십 논쟁을 크게 남겼습니다.\n2010년 램파드의 골이 인정되지 않자 기술 판독 필요성이 더 커졌습니다.\n2014년 브라질 월드컵에서 골라인 기술이 실제로 사용됐습니다.\n2018년 VAR, 2022년 반자동 오프사이드가 도입되며 판정 풍경이 크게 바뀌었습니다.';

  @override
  String get educationBookWomenFacts =>
      '피클스는 월드컵 트로피를 찾아낸 개로 축구 역사에서 가장 유명한 반려견이 됐습니다.\n기술이 들어와도 월드컵 논쟁은 사라지지 않고, 오히려 다른 종류의 토론으로 바뀝니다.\n정치와 사회 분위기는 개최국의 기억, 관중의 감정, 대회 서사까지 크게 흔듭니다.\n태오는 역사적 사건을 읽을 때 경기 결과와 함께 사회적 배경을 반드시 옆에 적어 둡니다.';

  @override
  String get educationBookWomenNote =>
      '태오는 월드컵이 단지 가장 큰 축구 대회가 아니라, 그 시대의 기술과 정치, 공정성 논쟁이 한꺼번에 모이는 장소라고 적어 둡니다. 그래서 경기장 밖 사건도 결코 부록으로 읽지 않기로 합니다.';

  @override
  String get educationBookModernLabel => '8장';

  @override
  String get educationBookModernTitle => '다음 대회를 기다리는 동안 적어 두는 것들';

  @override
  String get educationBookModernSubtitle => '2026 북중미를 향한 태오의 메모';

  @override
  String get educationBookModernStory =>
      '이제 책은 아직 열리지 않은 대회를 향해 천천히 걸어간다. 2026 북중미 월드컵은 48개국, 104경기, 세 나라 공동 개최라는 조건만으로도 이미 이전 페이지들과 다른 표정을 하고 있다. 태오는 이런 숫자들을 볼 때 이상하게도 우승 후보보다 먼저 이동 거리와 회복 시간, 벤치의 숨결 같은 것을 떠올린다. 대회가 길어질수록 스타 한 명보다 견디는 방식 전체가 더 중요해질 것 같기 때문이다.\n\n그래서 이 장은 예언이라기보다 관찰에 가깝다. 어떤 팀이 낯선 상대를 빨리 해독할 수 있는지, 어떤 팀이 세트피스로 무너지는 시간을 버틸 수 있는지, 어떤 팀이 긴 여정 속에서 자기 리듬을 잃지 않는지. 태오는 강팀의 조건이란 대체로 화려한 문장보다 지루한 디테일에서 생긴다고 믿는다. 그 믿음은 의외로 여러 대회의 역사와도 잘 맞아떨어진다.\n\n아직 오지 않은 대회에 대해 너무 크게 말하는 것은 조금 조심스럽다. 미래는 늘 생각보다 건조하게 오고, 예측은 종종 어긋난다. 그래도 태오는 빈 페이지를 남겨 두기로 한다. 역사책의 마지막 미덕은 언제나 다음 문장을 받아 적을 자리를 남겨 두는 일이라고 생각하기 때문이다.';

  @override
  String get educationBookModernTimeline =>
      '2026년 월드컵은 캐나다, 멕시코, 미국이 공동 개최하는 첫 남자 월드컵입니다.\n2026년부터 남자 월드컵 본선은 48개국 체제로 확대됩니다.\n48개국 체제에서는 총 104경기가 열려 일정 관리와 로테이션 가치가 더 커집니다.\n이동 거리와 기후 차이는 기존보다 더 큰 체력 변수로 작용할 가능성이 큽니다.\n세트피스, 벤치 득점, 분석 스태프의 준비 속도는 장기 대회일수록 더 중요해집니다.\n태오는 2026년을 보며 결과 예측보다 강팀의 조건을 먼저 찾기로 합니다.';

  @override
  String get educationBookModernFacts =>
      '대회가 길어질수록 주전 11명보다 18명에서 23명 수준의 실전 전력이 더 중요해집니다.\n48개국 체제는 아시아, 아프리카, 북중미 팀들의 깜짝 진출 가능성도 함께 키웁니다.\n전통 강호의 기본 체급은 여전히 크지만, 조별리그와 토너먼트의 변수는 더 많아질 수 있습니다.\n태오는 예측을 쓸 때 팀 이름만 적지 않고 압박, 전환, 세트피스, 수비 라인 안정성을 같이 적어 둡니다.';

  @override
  String get educationBookModernNote =>
      '태오는 예측은 맞히기 놀이가 아니라 강팀의 조건을 읽는 연습이라고 적습니다. 그래서 2026년 전망 페이지에는 우승 후보 이름보다 왜 그 팀이 강해 보이는지를 더 길게 적어 둡니다.';

  @override
  String get educationBookFinaleLabel => '에필로그';

  @override
  String get educationBookFinaleTitle => '마지막 페이지는 늘 조금 천천히 닫힌다';

  @override
  String get educationBookFinaleSubtitle => '1930에서 2026까지를 한 줄로 묶는 에필로그';

  @override
  String get educationBookFinaleStory =>
      '마지막 장에 이르면 태오는 월드컵이 결국 4년에 한 번씩 발행되는 아주 두꺼운 잡지 같다는 생각을 한다. 시대는 계속 바뀌는데 표지 제목은 변하지 않고, 그 안에는 늘 그해의 공기와 얼굴과 논쟁이 압축되어 들어간다. 배를 타고 우루과이로 가던 선수들과, 수많은 카메라와 센서 속에서 뛰는 현대 선수들이 결국 같은 책등 아래에 꽂여 있다는 사실이 조금 이상하고 또 정확하다.\n\n어떤 해는 펠레와 마라도나, 메시 같은 이름으로 남고, 어떤 해는 마라카낭의 충격이나 7대1 같은 스코어로 남고, 어떤 해는 전쟁과 독재와 판독 기술 이야기로 남는다. 태오는 그래서 월드컵을 읽는 일은 축구를 외우는 일이 아니라 시간의 결을 만져 보는 일에 가깝다고 생각한다. 한 경기 뒤에 한 시대가 접혀 있다는 사실을 알게 되면, 점수도 전보다 훨씬 무겁게 보인다.\n\n책을 덮기 전에 태오는 다시 한 번 1930, 1950, 1958, 1970, 1986, 1998, 2002, 2010, 2018, 2022, 2026을 차례대로 읽는다. 이제 그 숫자들은 차가운 연도가 아니라, 서로 다른 조명 아래 놓인 방 이름처럼 들린다. 어떤 방은 이미 지나갔고, 어떤 방은 곧 열릴 것이다. 역사책이 좋은 이유는 바로 그 사이를 천천히 걸어갈 수 있게 해 준다는 데 있다.';

  @override
  String get educationBookFinaleTimeline =>
      '태오는 초창기 월드컵에서 대회가 어떻게 세상 속으로 들어왔는지 배웠습니다.\n태오는 전후 월드컵에서 한 경기의 충격이 한 나라의 기억이 될 수 있음을 봤습니다.\n태오는 최근 월드컵에서 기술과 데이터가 늘어나도 결국 사람들은 장면과 인물을 기억한다는 걸 확인했습니다.\n태오는 2026년 전망을 통해 미래 예측도 결국 과거 패턴 읽기에서 시작된다는 점을 이해했습니다.';

  @override
  String get educationBookFinaleFacts =>
      '복습 기준 1: 연도, 개최국, 우승국, 명장면, 주인공을 한 줄로 묶습니다.\n복습 기준 2: 1930, 1950, 1970, 1986, 1998, 2002, 2018, 2022는 반드시 다시 떠올릴 기준 연도입니다.\n복습 기준 3: 기록은 펠레 3회 우승, 브라질 5회 우승, 클로제 16골처럼 대표 숫자로 연결합니다.\n복습 기준 4: 예측은 팀 이름만이 아니라 전술, 체력, 스쿼드 깊이까지 함께 적어야 더 정확해집니다.';

  @override
  String get educationBookFinaleNote =>
      '태오는 책장을 닫으며 다음 훈련 일지 첫 줄에 이렇게 적습니다. 월드컵을 잘 본다는 것은 결승 스코어 하나만 외우는 것이 아니라, 1930년의 첫 출발부터 2026년의 다음 질문까지 그 긴 이야기를 끝까지 따라가는 일이다.';

  @override
  String get familySharing => '가족 공유';

  @override
  String get familySharedBackupDescription =>
      '서버 없이 Google Drive 백업 파일 하나를 함께 사용합니다. 기록 모드에서는 핵심 기록을 직접 관리하고, 부모 모드는 가족 공유 레이어만 동기화합니다.';

  @override
  String get familyBackupIncludesMedia =>
      '프로필 사진과 훈련 사진처럼 기기 파일로 저장된 항목도 가능한 범위에서 함께 백업합니다.';

  @override
  String get familyParentAutoSyncDescription =>
      '부모 모드에서는 피드백과 레벨 선물 이름만 자동 동기화합니다. 선수 기록 백업과 복원은 기록 모드에서 진행해 주세요.';

  @override
  String get familyChildDriveConnectionTitle => '선수 Google Drive 연결';

  @override
  String get familyChildDriveConnectionDescription =>
      '부모 모드에서는 선수가 쓰는 Google Drive 계정으로 연결해야 같은 가족 백업 파일을 함께 사용할 수 있어요.';

  @override
  String get familyConnectChildDrive => '선수 Drive 연결';

  @override
  String get familyDisconnectChildDrive => '선수 Drive 연결 해제';

  @override
  String get familyRoleChild => '선수';

  @override
  String get familyRoleParent => '부모';

  @override
  String get familyParentModeEnabled => '부모 모드 활성화';

  @override
  String get familyParentModeDescription => '켜면 부모 모드로 전환되고, 끄면 기록 모드로 돌아갑니다.';

  @override
  String get familyChildName => '선수 이름';

  @override
  String get familyParentName => '부모 이름';

  @override
  String get familyChildNameEmpty => '선수 이름을 입력해 주세요';

  @override
  String get familyParentNameEmpty => '부모 이름을 입력해 주세요';

  @override
  String get familyEditNames => '가족 이름 수정';

  @override
  String get familyPolicyTitle => '공유 백업 정책';

  @override
  String get familyPolicyChildOwnsData =>
      '기록 모드에서는 훈련, 프로필, 다이어리, 식사, 계획을 원본으로 백업합니다.';

  @override
  String get familyPolicyParentWritesOnly =>
      '부모 모드는 피드백과 레벨 선물 이름만 저장할 수 있습니다.';

  @override
  String get familyPolicyParentSeedRequired =>
      '부모 기기는 선수 백업이 한 번 이상 만들어진 뒤 연결해야 합니다.';

  @override
  String get familyRoleChildActivated => '기록 모드로 전환했어요.';

  @override
  String get familyRoleParentActivated => '부모 모드로 전환했어요.';

  @override
  String get familyNamesSaved => '가족 이름을 저장했어요.';

  @override
  String get driveConnectedAccount => '현재 연결된 Drive 계정';

  @override
  String get driveConnectedAccountEmpty => '아직 Google Drive 계정이 연결되지 않았어요.';

  @override
  String get driveSavedPlayerAccount => '저장된 기록 모드 Drive';

  @override
  String get driveReconnectSavedPlayer => '저장된 기록 Drive 연결';

  @override
  String get driveReconnectSavedPlayerHint =>
      '부모 모드에서 돌아온 뒤에는 저장된 기록 모드 Drive 계정으로 다시 연결할 수 있어요.';

  @override
  String get driveReconnectSavedPlayerMismatch =>
      '저장된 기록 모드 Drive 계정으로 다시 연결해 주세요.';

  @override
  String get driveSavedParentAccount => '저장된 부모 모드 Drive';

  @override
  String get driveReconnectSavedParent => '저장된 부모 Drive 연결';

  @override
  String get driveReconnectSavedParentHint =>
      '부모 모드에서 마지막으로 사용한 Drive 계정으로 다시 연결할 수 있어요.';

  @override
  String get driveReconnectSavedParentMismatch =>
      '저장된 부모 모드 Drive 계정으로 다시 연결해 주세요.';

  @override
  String get driveSharedChildAccount => '공유 대상 선수 Drive';

  @override
  String get driveSharedChildAccountEmpty =>
      '아직 선수 Drive 정보가 없어요. 기록 모드에서 먼저 한 번 백업해 주세요.';

  @override
  String get familyParentUsesChildDriveHint =>
      '부모 모드에서는 선수 Google Drive 계정으로 로그인하면 같은 백업 파일에 피드백과 선물 이름을 동기화할 수 있어요.';

  @override
  String get familyParentUsesChildDriveWarning =>
      '부모 모드에서는 선수 Google Drive 계정으로 연결해야 같은 가족 백업에 안전하게 동기화할 수 있어요.';

  @override
  String get familySharedSyncTitle => '가족 공유 동기화';

  @override
  String get familySharedSyncDescription =>
      '부모 모드에서 저장하는 피드백과 선물 이름은 자동으로 같은 가족 백업 파일에 반영됩니다.';

  @override
  String get familySharedLastSync => '최근 가족 공유 동기화';

  @override
  String get familySharedLastPush => '최근 가족 공유 반영';

  @override
  String get familySharedLastRefresh => '최근 가족 공유 새로고침';

  @override
  String get familySharedAutoRefreshDescription =>
      '부모 모드로 들어오거나 앱으로 돌아오면 최신 가족 공유 상태를 자동으로 확인합니다. 아직 원격에 반영하지 못한 로컬 변경이 있으면 자동 새로고침은 건너뜁니다.';

  @override
  String get familySharedPendingLocalChanges =>
      '아직 원격에 반영하지 못한 부모 모드 로컬 변경이 있어 자동 새로고침을 잠시 보류하고 있어요.';

  @override
  String get familySharedRestore => '가족 공유 복원';

  @override
  String get familySharedRestoreConfirm =>
      'Google Drive의 최신 선수 백업 상태로 복원할까요? 현재 부모 기기에서 보이는 선수 기록과 가족 공유 데이터가 교체됩니다.';

  @override
  String get familySharedRestoreSuccess => '선수 백업 복원이 완료되었습니다.';

  @override
  String get familySharedRestoreFailed => '선수 백업 복원에 실패했어요. 다시 시도해 주세요.';

  @override
  String get familySharedRestoreLocal => '가족 공유 되돌리기';

  @override
  String get familySharedRestoreLocalConfirm =>
      '복원 직전에 저장된 이전 상태로 되돌릴까요? 현재 부모 기기에서 보이는 선수 기록과 가족 공유 데이터가 교체됩니다.';

  @override
  String get familySharedRestoreLocalSuccess => '이전 상태로 되돌리기가 완료되었습니다.';

  @override
  String get familySharedRestoreLocalFailed =>
      '이전 상태로 되돌리기에 실패했어요. 다시 시도해 주세요.';

  @override
  String get familyParentFamilyMismatch =>
      '현재 연결한 Drive 백업이 이 가족 데이터와 일치하지 않아요.';

  @override
  String get parentReadOnlyProfileDescription =>
      '부모 모드에서는 프로필이 읽기 전용입니다. 피드백은 가족 공유에서, 레벨 선물 입력은 레벨 가이드에서 진행해 주세요.';

  @override
  String get parentReadOnlyEntryTitle => '부모 모드에서는 훈련 노트를 수정할 수 없어요.';

  @override
  String get parentReadOnlyEntryBody =>
      '훈련, 식사, 다이어리 같은 핵심 기록은 기록 모드에서 작성해 주세요. 부모 모드는 가족 공유와 선물 입력만 저장합니다.';

  @override
  String get parentReadOnlyMealLog =>
      '부모 모드에서는 식사 기록을 수정할 수 없어요. 식사 입력은 기록 모드에서 진행해 주세요.';

  @override
  String get parentReadOnlyQuiz =>
      '부모 모드에서는 퀴즈를 진행하지 않아요. 퀴즈 기록과 경험치는 기록 모드에서만 쌓입니다.';

  @override
  String get parentReadOnlyDrawerMessage =>
      '부모 모드에서는 핵심 기록을 수정할 수 없어요. 가족 공유와 선물 입력을 이용해 주세요.';

  @override
  String get parentReadOnlyCalendarBanner =>
      '부모 모드에서는 캘린더를 읽기 전용으로 보여줍니다. 계획, 시합, 식사 수정은 기록 모드에서 진행해 주세요.';

  @override
  String get parentReadOnlyCalendarMessage => '부모 모드에서는 캘린더를 수정할 수 없어요.';

  @override
  String get parentReadOnlyDiaryMessage => '부모 모드에서는 다이어리를 수정할 수 없어요.';

  @override
  String get parentReadOnlyDiaryBadge => '부모 모드 읽기 전용';

  @override
  String get parentReadOnlySketchMessage => '부모 모드에서는 훈련 스케치를 수정할 수 없어요.';

  @override
  String get levelGuideParentModeLabel => '부모 모드';

  @override
  String get levelGuideChildModeLabel => '기록 모드';

  @override
  String get levelGuideParentModeDescription =>
      '부모 모드에서는 레벨 선물 이름만 저장할 수 있고, 선물 수령은 기록 모드에서 진행합니다.';

  @override
  String get levelGuideChildModeDescription =>
      '기록 모드에서는 레벨 선물을 수령할 수 있고, 선물 이름 입력은 부모 모드에서 관리합니다.';

  @override
  String get levelGuideClaimChildOnly => '기록 모드에서 수령';
}
