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
  String get tabNews => '오늘의 소식';

  @override
  String get tabGame => '미니게임';

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
    return '평균 실제 $value공기';
  }

  @override
  String get mealStatsEmpty => '선택한 기간에 식사 기록이 없습니다.';

  @override
  String get mealStatsSectionTitle => '식사 기록';

  @override
  String get mealStatsTrendTitle => '식사 그래프';

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
  String get fortuneDialogSubtitle => '오늘 흐름을 짧게 읽어보세요.';

  @override
  String get mealStatsNoTrainingOrMealEntries => '선택한 기간에 훈련 기록과 식사 기록이 없습니다.';
}
