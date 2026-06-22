// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Korean (`ko`).
class AppLocalizationsKo extends AppLocalizations {
  AppLocalizationsKo([String locale = 'ko']) : super(locale);

  @override
  String get appTitle => '태오의 노트';

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
  String get tabNews => '소식';

  @override
  String tabGuideTitle(Object tabName) {
    return '$tabName 가이드';
  }

  @override
  String get welcomeGuideTitle => '오늘 기록하면, 내일 더 강해져요';

  @override
  String get welcomeGuideIntro =>
      '종목은 상관없어요. 한 줄만 남겨도 다음 훈련이 쉬워져요. 지금 시작해도 충분히 잘할 수 있어요.';

  @override
  String get welcomeGuidePrimaryAction => '기록 시작하기';

  @override
  String get welcomeGuideSectionFlow => '해야 할 일';

  @override
  String get welcomeGuideNextTabHint => '세 장만 넘기면 돼요. 그 다음은 바로 하나 기록해 봐요.';

  @override
  String get welcomeGuidePreviewLabel => '지금 고를 액션';

  @override
  String get welcomeGuideCoachMarkLabel => '바로 누를 곳';

  @override
  String get welcomeSlideGemTitle => '작은 기록이 큰 자신감이 돼요';

  @override
  String get welcomeSlideGemBody =>
      '잘한 점은 크게 칭찬하고, 아쉬운 점은 다음 도전으로 바꿔요. 하나씩 쌓이면 더 잘할 수 있어요.';

  @override
  String get welcomeSlideFlameTitle => '힘든 날에도 멈추지 마세요';

  @override
  String get welcomeSlideFlameBody =>
      '오늘 하나만 해도 괜찮아요. 기록하고 다시 시작하면 내일 한 걸음 더 갈 수 있어요.';

  @override
  String get startupSportTitle => '먼저 사용할 종목을 골라요';

  @override
  String get startupSportSubtitle =>
      '선택한 종목에 맞춰 기록, 목표, 통계, 뉴스가 시작됩니다. 나중에 설정에서 바꿀 수 있어요.';

  @override
  String get startupSportAction => '이 종목으로 시작하기';

  @override
  String get startupSportFootballDescription =>
      '훈련, 시합, 스케치, 뉴스까지 축구 중심으로 시작해요.';

  @override
  String get startupSportBaseballDescription =>
      '투구, 타격, 수비, 컨디션 기록을 야구 기준으로 맞춰요.';

  @override
  String get startupSportBasketballDescription =>
      '슛, 드리블, 경기 흐름과 컨디션을 농구 기준으로 기록해요.';

  @override
  String get startupSportTennisDescription =>
      '스트로크, 서브, 랠리와 보강 운동을 테니스 기준으로 기록해요.';

  @override
  String tabGuideCoachMarkStep(int current, int total) {
    return '$total단계 중 $current단계';
  }

  @override
  String get tabGuideCoachMarkSkip => '건너뛰기';

  @override
  String get tabGuideCoachMarkBack => '이전';

  @override
  String get tabGuideCoachMarkNext => '다음';

  @override
  String get tabGuideCoachMarkDone => '완료';

  @override
  String get tabGuideCoachMarkTry => '바로 해보기';

  @override
  String get parentWelcomeGuideTitle => '보호자 모드 안내';

  @override
  String get parentWelcomeGuideIntro =>
      '보호자 모드에서는 선수 기록을 확인하고, 기존 훈련기록에 피드백만 남길 수 있어요.';

  @override
  String get parentWelcomeGuideStepLogs => '훈련기록 탭에서 선수가 저장한 기록을 먼저 열어보세요.';

  @override
  String get parentWelcomeGuideStepFeedback =>
      '기존 기록 안에서 칭찬과 다음에 볼 점을 피드백으로 남겨요.';

  @override
  String get parentWelcomeGuideStepSync =>
      '선수 백업이 있는 Google Drive 계정으로 연결해 같은 데이터를 안전하게 동기화하세요.';

  @override
  String get guideActionToday => '오늘';

  @override
  String get guideActionMeal => '식사';

  @override
  String get guideActionCardList => '카드/리스트';

  @override
  String get guideActionSelectDate => '날짜 선택';

  @override
  String get guideActionPlus => '+';

  @override
  String get guideActionPeriod => '기간';

  @override
  String get guideActionBenchmark => '평균';

  @override
  String get guideActionWeakPoint => '목표';

  @override
  String get guideActionOpenToday => '오늘 다이어리';

  @override
  String get guideActionRecordSticker => '스티커';

  @override
  String get guideActionSaveDiary => '다이어리 저장';

  @override
  String get welcomeHomeOverview => '홈은 지금 가장 먼저 할 일을 고르는 시작 화면입니다.';

  @override
  String get welcomeHomeStepToday => '오늘 계획, 빠른 실행, 아직 남은 루틴을 먼저 확인해요.';

  @override
  String get welcomeHomeStepMeal => '하루가 끝나기 전에 식사 버튼으로 회복 기록을 채워요.';

  @override
  String get welcomeHomeStepStats => '기록 후 주간 통계를 열어 이번 주 흐름이 균형 잡혔는지 봐요.';

  @override
  String get welcomeLogsOverview => '훈련기록은 실제 훈련 노트를 만들고 다시 찾는 화면입니다.';

  @override
  String get welcomeLogsStepAdd => '기록 추가를 눌러 기본 정보부터 입력하고 첫 노트를 저장해요.';

  @override
  String get welcomeLogsStepBoard => '훈련 모양이나 움직임 경로가 중요하면 노트 안에서 보드를 열어요.';

  @override
  String get welcomeLogsStepReview => '카드/리스트와 필터를 바꿔 최근 기록을 빠르게 찾아요.';

  @override
  String get welcomeCalendarOverview => '캘린더는 날짜별 계획, 시합, 식사, 노트를 함께 보는 화면입니다.';

  @override
  String get welcomeCalendarStepDate => '먼저 날짜를 선택해 새 기록이 올바른 날에 붙게 해요.';

  @override
  String get welcomeCalendarStepPlus => '+ 버튼으로 선택한 날짜에 계획, 시합, 훈련 노트를 추가해요.';

  @override
  String get welcomeCalendarStepMeal => '같은 날짜의 식사 기록도 함께 남겨 회복 흐름을 맞춰요.';

  @override
  String get welcomeStatsOverview => '통계는 기록이 쌓인 뒤 다음 훈련 목표를 정하는 화면입니다.';

  @override
  String get welcomeStatsStepPeriod => '기간을 바꿔 이번 주, 지난주, 원하는 범위를 비교해요.';

  @override
  String get welcomeStatsStepAverage => '평균 비교를 열어 앞선 지표와 뒤처진 지표를 구분해요.';

  @override
  String get welcomeStatsStepFocus => '가장 약한 신호를 다음 계획이나 노트 목표로 바꿔요.';

  @override
  String get welcomeChallengeOverview =>
      '챌린지는 매일 라운드를 빼먹지 못하게 압박하고, 완료를 경험치로 남기는 화면입니다.';

  @override
  String get welcomeChallengeActionStart => '챌린지 시작';

  @override
  String get welcomeChallengeStepStart => '기간을 고르면 오늘부터 이어갈 라운드가 만들어져요.';

  @override
  String get welcomeChallengeActionMission => '미션 입력';

  @override
  String get welcomeChallengeStepMission =>
      '훈련, 줄넘기, 리프팅, 식사 미션을 눌러 바로 기록 화면으로 들어가요.';

  @override
  String get welcomeChallengeActionReward => 'XP 보상';

  @override
  String get welcomeChallengeStepReward =>
      '라운드를 끝낼수록 경험치가 쌓이고, 빠뜨리면 빈칸이 그대로 남아요.';

  @override
  String get welcomeDiaryOverview => '다이어리는 훈련, 식사, 스티커를 하루 이야기로 묶는 화면입니다.';

  @override
  String get welcomeDiaryStepToday => '홈이나 다이어리 탭에서 오늘 다이어리를 열어요.';

  @override
  String get welcomeDiaryStepSticker => '오늘 기록 스티커를 불러와 읽는 순서를 정리해요.';

  @override
  String get welcomeDiaryStepSave => '제목, 이야기, 스티커 중 하나라도 준비되면 다이어리를 저장해요.';

  @override
  String get logsQuickGuideTitle => '빠른 시작 가이드';

  @override
  String get logsQuickGuideIntro => '첫 기록은 이 순서로 만들고, 저장 후 이 화면에서 다시 확인하세요.';

  @override
  String get newsFifaHubButton => '피파';

  @override
  String get newsWorldCupButton => '월드컵';

  @override
  String get newsKLeagueStandingsButton => '리그';

  @override
  String get newsMoreActionsTooltip => '리그보기';

  @override
  String get newsMoreActionsTitle => '더보기';

  @override
  String get newsRankingMoreButton => '리그보기';

  @override
  String get newsLeagueStandingsAction => '리그';

  @override
  String get newsLeagueStandingsTitle => '리그 보기';

  @override
  String get newsKLeagueStandingsTitle => 'K리그1';

  @override
  String get newsPremierLeagueStandingsTitle => '프리미어리그';

  @override
  String get newsChampionsLeagueStandingsTitle => '챔피언스리그';

  @override
  String get newsLaLigaStandingsTitle => '라리가';

  @override
  String get newsBundesligaStandingsTitle => '분데스리가';

  @override
  String get newsMajorLeagueSoccerStandingsTitle => 'MLS';

  @override
  String get newsSaudiProLeagueStandingsTitle => 'Saudi Pro League';

  @override
  String newsLeagueStandingsUpdated(Object date) {
    return '업데이트 $date';
  }

  @override
  String get newsLeagueStandingsOpenSource => '원문 순위 열기';

  @override
  String get newsLeagueStandingsEmpty => '표시할 순위가 없어요.';

  @override
  String get newsLeagueStandingsError => '순위를 불러오지 못했어요.';

  @override
  String get newsLeagueStandingsRetry => '다시 시도';

  @override
  String get newsLeagueFixturesTitle => '일정 캘린더';

  @override
  String get newsLeagueFixturesCalendarTitle => '경기 일정 캘린더';

  @override
  String get newsLeagueFixturesOpenCalendar => '캘린더로 보기';

  @override
  String get newsLeagueFixturesCalendarEmptyDay => '이 날짜에 배치된 경기가 없어요.';

  @override
  String get newsLeagueFixturesSubtitle => '캘린더에서 예정 경기와 최근 결과를 확인하세요.';

  @override
  String get newsLeagueFixturesEmpty => '더 넓은 일정 구간을 확인했지만 표시할 경기를 찾지 못했어요.';

  @override
  String get newsLeagueFixturesShowAll => '일정 전체 보기';

  @override
  String get newsLeagueFixturesCollapse => '일정 접기';

  @override
  String get newsLeagueFixturesSelectedTeamsOnly => '선택한 팀 경기만';

  @override
  String get newsLeagueFixturesSelectedTeamsEmpty => '이 리그 일정에 선택한 팀 경기가 없어요.';

  @override
  String newsLeagueFixturesEmptyReason(String league) {
    return '$league 일정 원본 피드가 비어 있거나 현재 시즌 일정이 아직 공개되지 않아 표시할 경기가 없어요.';
  }

  @override
  String get newsLeagueFixtureScheduled => '예정';

  @override
  String get newsLeagueFixtureLive => '진행 중';

  @override
  String get newsLeagueFixtureFullTime => '종료';

  @override
  String newsLeagueTeamDetailTitle(String team) {
    return '$team 정보';
  }

  @override
  String get newsLeagueTeamDetailRosterTitle => '선수 명단';

  @override
  String get newsLeagueTeamDetailTacticsTitle => '전술';

  @override
  String get newsLeagueTeamDetailFixturesTitle => '팀 일정';

  @override
  String get newsLeagueTeamDetailNoFixtures => '불러온 일정 안에서 이 팀의 경기를 찾지 못했어요.';

  @override
  String get newsLeagueTeamDetailTacticsSummary =>
      '현재 순위와 득실 데이터를 바탕으로 팀 흐름을 확인하세요. 공식 전술/선수 명단이 제공되면 이 화면에 함께 표시됩니다.';

  @override
  String get newsLeagueTeamDetailSourceNote => '공식 리그 피드에서 확인 가능한 정보만 표시합니다.';

  @override
  String get newsLeagueFavoriteTeamTitle => '좋아하는 팀';

  @override
  String get newsLeagueFavoriteTeamManage => '좋아하는 팀 선택';

  @override
  String get newsLeagueFavoriteTeamSubtitle =>
      '좋아하는 팀을 선택하면 불러온 일정 중 해당 팀 경기 알림을 받을 수 있어요.';

  @override
  String get newsLeagueFavoriteTeamSelect => '팀 선택';

  @override
  String get newsLeagueFavoriteTeamClear => '해제';

  @override
  String get newsLeagueFavoriteTeamNone => '선택된 팀 없음';

  @override
  String get newsLeagueFavoriteTeamSheetTitle => '좋아하는 팀 선택';

  @override
  String get newsLeagueFavoriteTeamSaveAction => '저장';

  @override
  String get newsLeagueFavoriteTeamLoadError => '팀 목록을 불러오지 못했어요.';

  @override
  String get newsLeagueFavoriteTeamEmpty => '선택할 팀이 없어요.';

  @override
  String newsLeagueFavoriteTeamSelectedCount(int count) {
    return '$count개 팀 선택됨';
  }

  @override
  String get newsLeagueFavoriteTeamSaved => '좋아하는 팀을 저장했어요.';

  @override
  String get newsLeagueFavoriteTeamNoUpcoming => '예약된 경기 알림이 없어요.';

  @override
  String newsLeagueFavoriteTeamReminderCount(int count) {
    return '$count개 경기 알림 예약됨';
  }

  @override
  String newsLeagueFavoriteTeamNotificationBody(
      Object team, Object opponent, Object kickoff) {
    return '$team 경기 알림: $opponent전 $kickoff';
  }

  @override
  String get newsLeagueFixtureNotificationChannelName => '리그 경기 알림';

  @override
  String get newsLeagueFixtureNotificationChannelDescription =>
      '선호 팀의 리그 일정 알림';

  @override
  String get notificationAppTitle => '태오의 노트';

  @override
  String get worldCupFixtureNotificationChannelName => '월드컵 경기 알림';

  @override
  String get worldCupFixtureNotificationChannelDescription =>
      '관심 국가의 월드컵 일정 알림';

  @override
  String worldCupFixtureNotificationBody(
      Object team, Object opponent, Object kickoff) {
    return '$team 월드컵 경기: $opponent전 $kickoff';
  }

  @override
  String get newsLeagueStandingsTeamColumn => '팀';

  @override
  String get newsLeagueStandingsPlayedColumn => '경기';

  @override
  String get newsLeagueStandingsWinsColumn => '승';

  @override
  String get newsLeagueStandingsDrawsColumn => '무';

  @override
  String get newsLeagueStandingsLossesColumn => '패';

  @override
  String get newsLeagueStandingsGoalDifferenceColumn => '득실';

  @override
  String get newsLeagueStandingsPointsColumn => '승점';

  @override
  String get newsSearchAction => '기사 검색';

  @override
  String get newsChannelsAction => '채널 선택';

  @override
  String get newsShowAllNewsAction => '전체 소식 보기';

  @override
  String get newsShowScrappedOnlyAction => '스크랩한 소식만 보기';

  @override
  String get newsViewedHistoryAction => '본 소식';

  @override
  String get newsViewedHistoryTitle => '본 소식';

  @override
  String get newsViewedHistoryEmpty => '아직 본 소식이 없어요.';

  @override
  String get newsTitleTranslateEnabledTooltip => '제목 번역 켜짐';

  @override
  String get newsTitleTranslateDisabledTooltip => '제목 번역 꺼짐';

  @override
  String get newsTranslateAction => '번역';

  @override
  String get newsSelectChannelsTitle => '뉴스 채널 선택';

  @override
  String get newsSelectAll => '전체 선택';

  @override
  String get newsClearAll => '전체 해제';

  @override
  String get newsDomesticFeedsLabel => '국내 피드';

  @override
  String get newsInternationalFeedsLabel => '해외 피드';

  @override
  String get newsRegionAllLabel => '전체';

  @override
  String get newsRegionDomesticLabel => '국내';

  @override
  String get newsRegionInternationalLabel => '해외';

  @override
  String get newsNationalSnapshotTitle => '국가대표 스냅샷';

  @override
  String get newsNationalSnapshotSubtitle => '공식 페이지 기준 대한민국 남자 대표팀 요약';

  @override
  String get newsFifaRankingTitle => 'FIFA 랭킹';

  @override
  String get newsRankingCurrentLabel => '현재 순위';

  @override
  String get newsRankingUpdatedLabel => '업데이트';

  @override
  String get newsRecentAMatchTitle => '최근 A매치';

  @override
  String get newsRecentAMatchEmpty => '최근 A매치 기록을 찾지 못했어요.';

  @override
  String get newsOpenOfficialSource => '공식 페이지 열기';

  @override
  String get newsOfficialSourceFifa => 'FIFA 공식';

  @override
  String get newsOfficialSourceKfa => 'KFA 공식';

  @override
  String get newsMatchResultWin => '승';

  @override
  String get newsMatchResultDraw => '무';

  @override
  String get newsMatchResultLoss => '패';

  @override
  String matchKickoffKoreaOnly(String time) {
    return '한국 시간 $time';
  }

  @override
  String matchKickoffLocalAndKorea(String localTime, String koreaTime) {
    return '$localTime · 한국 시간 $koreaTime';
  }

  @override
  String get worldCupTitle => '월드컵 보기';

  @override
  String get worldCupInfoAction => '설명';

  @override
  String get worldCupSourceShortAction => 'FIFA';

  @override
  String get worldCupHeroTitle => 'FIFA 월드컵 2026';

  @override
  String get worldCupHeroSubtitle => '캐나다, 멕시코, 미국 · 48개 팀';

  @override
  String worldCupCountdownDays(int days) {
    return '$days일 남음';
  }

  @override
  String get worldCupCountdownToday => '개막일';

  @override
  String get worldCupCountdownStarted => '대회 진행 중';

  @override
  String get worldCupCountdownComplete => '대회 종료';

  @override
  String get worldCupScheduleTab => '일정';

  @override
  String get worldCupStandingsTab => '순위';

  @override
  String get worldCupTournamentTab => '토너먼트';

  @override
  String get worldCupOverviewTitle => '대회 개요';

  @override
  String get worldCupOverviewIntro =>
      '이번 월드컵은 이전보다 더 커졌어요. 캐나다, 멕시코, 미국에서 48개 나라가 12개 조로 나뉘어 104경기를 치릅니다.';

  @override
  String get worldCupHostsLabel => '개최국';

  @override
  String get worldCupHostsValue => '캐나다 · 멕시코 · 미국';

  @override
  String get worldCupDatesLabel => '기간';

  @override
  String worldCupDateRange(String start, String end) {
    return '$start - $end';
  }

  @override
  String get worldCupFormatLabel => '방식';

  @override
  String get worldCupFormatValue => '48개 팀 · 12개 조';

  @override
  String get worldCupMatchesLabel => '경기';

  @override
  String get worldCupMatchesValue => '16개 개최 도시에서 104경기';

  @override
  String worldCupMatchesCountValue(int count) {
    return '16개 개최 도시에서 $count경기';
  }

  @override
  String get worldCupGuideFormatTitle => '이번 월드컵 진행 방식';

  @override
  String get worldCupGuideFormatBullets =>
      '48개 나라가 4팀씩 12개 조로 나뉘어요.\n각 나라는 조별리그에서 3경기를 해요.\n각 조 1위와 2위는 바로 올라가고, 3위 팀 중 성적이 좋은 8팀도 올라가요.\n그다음 32강부터는 한 번 지면 탈락하는 토너먼트예요.';

  @override
  String get worldCupGuideMatchRulesTitle => '경기 기본 규칙';

  @override
  String get worldCupGuideMatchRulesBullets =>
      '한 경기는 전반 45분, 후반 45분으로 진행돼요.\n조별리그는 비겨도 끝날 수 있고, 두 팀이 승점 1점씩 가져가요.\n토너먼트에서 90분 동안 비기면 연장전을 하고, 그래도 같으면 승부차기로 승자를 정해요.\n조별리그 승점은 승리 3점, 무승부 1점, 패배 0점이에요.';

  @override
  String get worldCupGuideTiebreakTitle => '순위가 같을 때';

  @override
  String get worldCupGuideTiebreakBullets =>
      '가장 먼저 승점을 봐요.\n같은 조 안에서 승점이 같으면 맞대결 승점, 맞대결 득실차, 맞대결 득점을 차례로 봐요.\n그래도 같으면 전체 득실차, 전체 득점, 팀 페어플레이 점수, 최신 FIFA 랭킹을 봐요.\n3위 팀끼리는 승점, 득실차, 득점, 팀 페어플레이 점수, FIFA 랭킹 순서로 좋은 8팀을 정해요.';

  @override
  String get worldCupGuideRefereeTitle => '심판과 도와주는 사람들';

  @override
  String get worldCupGuideRefereeBullets =>
      'FIFA는 이번 대회에 주심 52명, 부심 88명, 비디오 심판 30명을 뽑았어요.\n경기장 안에서는 주심 1명이 경기를 이끌고, 부심 2명과 대기심, 필요한 예비 심판이 도와요.\n부심은 오프사이드, 스로인, 골킥, 코너킥, 교체, 페널티킥 상황을 도와 확인해요.\n마지막 결정은 항상 주심이 내려요.';

  @override
  String get worldCupGuideVarTitle => 'VAR과 경기 기술';

  @override
  String get worldCupGuideVarBullets =>
      'VAR은 비디오로 중요한 장면을 다시 확인하는 심판이에요.\n골인지 아닌지, 페널티킥인지 아닌지, 바로 퇴장인지, 카드를 받은 선수가 맞는지 같은 큰 장면을 확인해요.\n주심은 필요하면 화면을 직접 보고 온필드 리뷰를 하지만, 최종 결정은 주심이 해요.\n골라인 판독, 더 발전한 반자동 오프사이드 도움, 연결된 공 기술도 빠르고 정확한 판정을 도와요.';

  @override
  String get worldCupTeamSettingsTitle => '내 월드컵 국가';

  @override
  String get worldCupSupportCountryLabel => '응원하는 나라';

  @override
  String get worldCupInterestCountriesLabel => '관심 국가';

  @override
  String get worldCupInterestCountriesEmpty => '아직 관심 국가를 선택하지 않았어요.';

  @override
  String get worldCupEditInterestCountriesAction => '국가 편집';

  @override
  String get worldCupClearInterestCountriesAction => '비우기';

  @override
  String get worldCupSelectedCountriesOnly => '선택한 국가 경기만 보기';

  @override
  String get worldCupHighlightedMatchesTitle => '선택 국가 경기';

  @override
  String get worldCupNoHighlightedMatches =>
      '응원하는 나라나 관심 국가를 고르면 해당 경기 일정이 강조돼요.';

  @override
  String get worldCupCalendarTitle => '전체 경기 캘린더';

  @override
  String worldCupDayMatchesTitle(String date, int count) {
    return '$date · $count경기';
  }

  @override
  String get worldCupNoMatchesOnDay => '이 날에는 경기가 없어요.';

  @override
  String worldCupMatchNumber(int number) {
    return 'M$number';
  }

  @override
  String get worldCupVersusShort => '대';

  @override
  String get worldCupMatchScheduled => '예정';

  @override
  String get worldCupMatchLive => '진행 중';

  @override
  String get worldCupMatchAwaitingUpdate => '결과 갱신 대기';

  @override
  String get worldCupMatchAwaitingUpdateReason =>
      '경기 종료 예상 시간이 지났지만 FIFA 공식 결과가 아직 반영되지 않았어요. 새로고침하거나 공식 페이지를 확인해 주세요.';

  @override
  String get worldCupMatchResultFinal => '결과';

  @override
  String worldCupFifaRankingCompactLabel(int rank) {
    return 'FIFA $rank위';
  }

  @override
  String get worldCupMatchDetailTitle => '경기 상세';

  @override
  String get worldCupMatchComparisonTitle => '전력 비교';

  @override
  String get worldCupMatchRecordsTitle => '경기 기록';

  @override
  String get worldCupMatchRecordUnavailable =>
      '실시간 경기 기록은 공식 데이터가 들어오는 대로 표시됩니다.';

  @override
  String get worldCupMatchDetailLoading => 'FIFA 경기 데이터를 불러오는 중...';

  @override
  String get worldCupMatchScorersTitle => '득점 선수';

  @override
  String get worldCupMatchLineupsTitle => '출전 명단';

  @override
  String get worldCupStartingPlayersLabel => '선발';

  @override
  String get worldCupBenchPlayersLabel => '교체 명단';

  @override
  String get worldCupCaptainAbbreviation => '(주장)';

  @override
  String get worldCupOfficialSourceNote =>
      '점수, 선수 명단, 경기 기록은 이 페이지를 열 때 FIFA 데이터로 갱신됩니다.';

  @override
  String get worldCupMatchPossessionLabel => '점유율';

  @override
  String worldCupMatchPossessionValue(int home, int away) {
    return '$home% · $away%';
  }

  @override
  String get worldCupMatchAttendanceLabel => '관중';

  @override
  String get worldCupMatchTacticsLabel => '전술';

  @override
  String worldCupPlayerProfileTitle(String player) {
    return '$player 프로필';
  }

  @override
  String worldCupClubInfoOpenTooltip(String club) {
    return '$club 정보 보기';
  }

  @override
  String worldCupClubHomepageOpenTooltip(String club) {
    return '$club 공식 홈페이지 열기';
  }

  @override
  String worldCupClubInfoTitle(String club) {
    return '$club 정보';
  }

  @override
  String get worldCupPlayerProfilePlayerLabel => '선수';

  @override
  String get worldCupPlayerProfileTeamLabel => '대표팀';

  @override
  String get worldCupPlayerProfilePositionLabel => '포지션';

  @override
  String get worldCupPlayerProfileClubLabel => '소속팀';

  @override
  String get worldCupPlayerClubPending => '소속팀 업데이트 대기';

  @override
  String get worldCupScorePending => '- : -';

  @override
  String worldCupScoreLine(int homeScore, int awayScore) {
    return '$homeScore : $awayScore';
  }

  @override
  String get worldCupResultPendingTeam => '경기 전';

  @override
  String get worldCupResultWin => '승';

  @override
  String get worldCupResultDraw => '무';

  @override
  String get worldCupResultLoss => '패';

  @override
  String get worldCupResultWinSummary => '이겼어요';

  @override
  String get worldCupResultDrawSummary => '비겼어요';

  @override
  String get worldCupResultLossSummary => '졌어요';

  @override
  String worldCupGroupStageLabel(String group) {
    return '$group조';
  }

  @override
  String get worldCupRoundOf32Label => '32강';

  @override
  String get worldCupRoundOf16Label => '16강';

  @override
  String get worldCupQuarterFinalLabel => '8강';

  @override
  String get worldCupSemiFinalLabel => '준결승';

  @override
  String get worldCupThirdPlaceLabel => '3위 결정전';

  @override
  String get worldCupFinalLabel => '결승';

  @override
  String get worldCupCountryAlgeria => '알제리';

  @override
  String get worldCupCountryArgentina => '아르헨티나';

  @override
  String get worldCupCountryAustralia => '호주';

  @override
  String get worldCupCountryAustria => '오스트리아';

  @override
  String get worldCupCountryBelgium => '벨기에';

  @override
  String get worldCupCountryBosniaAndHerzegovina => '보스니아 헤르체고비나';

  @override
  String get worldCupCountryBrazil => '브라질';

  @override
  String get worldCupCountryCanada => '캐나다';

  @override
  String get worldCupCountryCapeVerde => '카보베르데';

  @override
  String get worldCupCountryColombia => '콜롬비아';

  @override
  String get worldCupCountryCongoDr => '콩고민주공화국';

  @override
  String get worldCupCountryCroatia => '크로아티아';

  @override
  String get worldCupCountryCuracao => '퀴라소';

  @override
  String get worldCupCountryCzechia => '체코';

  @override
  String get worldCupCountryEcuador => '에콰도르';

  @override
  String get worldCupCountryEgypt => '이집트';

  @override
  String get worldCupCountryEngland => '잉글랜드';

  @override
  String get worldCupCountryFrance => '프랑스';

  @override
  String get worldCupCountryGermany => '독일';

  @override
  String get worldCupCountryGhana => '가나';

  @override
  String get worldCupCountryHaiti => '아이티';

  @override
  String get worldCupCountryIran => '이란';

  @override
  String get worldCupCountryIraq => '이라크';

  @override
  String get worldCupCountryIvoryCoast => '코트디부아르';

  @override
  String get worldCupCountryJapan => '일본';

  @override
  String get worldCupCountryJordan => '요르단';

  @override
  String get worldCupCountryKoreaRepublic => '대한민국';

  @override
  String get worldCupCountryMexico => '멕시코';

  @override
  String get worldCupCountryMorocco => '모로코';

  @override
  String get worldCupCountryNetherlands => '네덜란드';

  @override
  String get worldCupCountryNewZealand => '뉴질랜드';

  @override
  String get worldCupCountryNorway => '노르웨이';

  @override
  String get worldCupCountryPanama => '파나마';

  @override
  String get worldCupCountryParaguay => '파라과이';

  @override
  String get worldCupCountryPortugal => '포르투갈';

  @override
  String get worldCupCountryQatar => '카타르';

  @override
  String get worldCupCountrySaudiArabia => '사우디아라비아';

  @override
  String get worldCupCountryScotland => '스코틀랜드';

  @override
  String get worldCupCountrySenegal => '세네갈';

  @override
  String get worldCupCountrySouthAfrica => '남아프리카공화국';

  @override
  String get worldCupCountrySpain => '스페인';

  @override
  String get worldCupCountrySweden => '스웨덴';

  @override
  String get worldCupCountrySwitzerland => '스위스';

  @override
  String get worldCupCountryTunisia => '튀니지';

  @override
  String get worldCupCountryTurkiye => '튀르키예';

  @override
  String get worldCupCountryUsa => '미국';

  @override
  String get worldCupCountryUruguay => '우루과이';

  @override
  String get worldCupCountryUzbekistan => '우즈베키스탄';

  @override
  String get worldCupVenueAttDallas => 'AT&T 스타디움, 댈러스';

  @override
  String get worldCupVenueBcPlaceVancouver => 'BC 플레이스, 밴쿠버';

  @override
  String get worldCupVenueBmoFieldToronto => 'BMO 필드, 토론토';

  @override
  String get worldCupVenueEstadioAkronGuadalajara => '에스타디오 아크론, 과달라하라';

  @override
  String get worldCupVenueEstadioAztecaMexicoCity => '에스타디오 아스테카, 멕시코시티';

  @override
  String get worldCupVenueEstadioBbvaMonterrey => '에스타디오 BBVA, 몬테레이';

  @override
  String get worldCupVenueGehaArrowheadKansasCity => '애로헤드 스타디움 GEHA 필드, 캔자스시티';

  @override
  String get worldCupVenueGilletteBoston => '질레트 스타디움, 보스턴';

  @override
  String get worldCupVenueHardRockMiami => '하드록 스타디움, 마이애미';

  @override
  String get worldCupVenueLevisSanFranciscoBayArea =>
      '리바이스 스타디움, 샌프란시스코 베이 에어리어';

  @override
  String get worldCupVenueLincolnFinancialPhiladelphia => '링컨 파이낸셜 필드, 필라델피아';

  @override
  String get worldCupVenueLumenSeattle => '루멘 필드, 시애틀';

  @override
  String get worldCupVenueMercedesBenzAtlanta => '메르세데스-벤츠 스타디움, 애틀랜타';

  @override
  String get worldCupVenueMetLifeNewYorkNewJersey => '메트라이프 스타디움, 뉴욕/뉴저지';

  @override
  String get worldCupVenueNrgHouston => 'NRG 스타디움, 휴스턴';

  @override
  String get worldCupVenueSofiLosAngeles => '소파이 스타디움, 로스앤젤레스';

  @override
  String worldCupKickoffLocal(String time) {
    return '$time 현지 시간';
  }

  @override
  String get worldCupSupportBadge => '응원';

  @override
  String get worldCupInterestBadge => '관심';

  @override
  String get worldCupKoreaTitle => '대한민국 보기';

  @override
  String get worldCupKoreaBody => '대한민국은 A조에서 체코와 과달라하라 첫 경기를 치릅니다.';

  @override
  String get worldCupKoreaGroupLabel => '조';

  @override
  String get worldCupKoreaGroup => 'A조';

  @override
  String get worldCupKoreaOpenerLabel => '첫 경기';

  @override
  String get worldCupKoreaOpener => '대한민국 대 체코 · 에스타디오 과달라하라';

  @override
  String get worldCupMilestonesTitle => '결승까지의 흐름';

  @override
  String get worldCupMilestoneOpeningLabel => '개막전';

  @override
  String get worldCupOpeningMatch =>
      '멕시코 대 남아프리카공화국 · 2026년 6월 11일 · 멕시코시티 스타디움';

  @override
  String get worldCupMilestoneGroupLabel => '조별리그';

  @override
  String get worldCupGroupStage => '6월 11일부터 조별리그가 시작되고 32강 대진으로 이어집니다.';

  @override
  String get worldCupMilestoneKnockoutLabel => '토너먼트';

  @override
  String get worldCupKnockouts => '조별리그 이후 32강이 시작됩니다.';

  @override
  String get worldCupMilestoneFinalLabel => '결승';

  @override
  String get worldCupFinalMatch => '2026년 7월 19일 · 뉴욕 뉴저지 스타디움';

  @override
  String get worldCupStandingsTitle => '조별 순위';

  @override
  String get worldCupStandingsPlanBody =>
      '일정에 들어온 경기 결과를 바탕으로 조별 순위를 바로 정리해요. 공식 세부 순위 기준이 확정되기 전까지는 승점, 득실차, 득점, 승리, 패배, 국가명 순서로 정렬합니다.';

  @override
  String get worldCupStandingsRuleLabel => '순위 기준';

  @override
  String get worldCupStandingsRuleValue => '승점 · 득실차 · 득점 · 승리 · 패배 · 국가명';

  @override
  String get worldCupStandingsTieGuide =>
      '승점이 같으면 득실차를 먼저 보고, 그래도 같으면 득점이 높은 팀이 위에 표시돼요.';

  @override
  String get worldCupStandingsTableTitle => '조별 순위표';

  @override
  String get worldCupStandingsRankColumn => '순위';

  @override
  String get worldCupStandingsTeamColumn => '국가';

  @override
  String get worldCupStandingsRecordColumn => '승-무-패';

  @override
  String get worldCupStandingsGoalDifferenceColumn => '득실';

  @override
  String get worldCupStandingsGoalsForColumn => '득점';

  @override
  String get worldCupStandingsPointsColumn => '승점';

  @override
  String worldCupStandingsRecordValue(int wins, int draws, int losses) {
    return '$wins-$draws-$losses';
  }

  @override
  String worldCupStandingsTieReasonValue(String goalDifference, int goalsFor) {
    return '동률 비교: 득실차 $goalDifference · 득점 $goalsFor';
  }

  @override
  String get worldCupGroupTeamsTitle => '조별 팀 구성';

  @override
  String worldCupTeamRosterOpenTooltip(String team) {
    return '$team 선수 명단 열기';
  }

  @override
  String worldCupTeamRosterTitle(String team) {
    return '$team 선수 명단';
  }

  @override
  String get worldCupTeamRosterSubtitle => '포지션별 명단과 포메이션 배치로 팀 구성을 빠르게 확인해요.';

  @override
  String get worldCupTeamHistoryTitle => '축구 역사와 설명';

  @override
  String worldCupTeamHistoryBody(String team) {
    return '$team의 축구사는 대표팀의 국제 대회 경험, 자국 리그와 해외파 선수 흐름, 월드컵 예선에서 쌓인 경쟁력이 함께 만든 이야기입니다. 이 화면에서는 현재 조별 일정, 승점, 선수 소속팀을 묶어 $team이 이번 대회에서 어떤 흐름을 만들 수 있는지 확인할 수 있어요.';
  }

  @override
  String worldCupTeamHistoryTournamentContext(
      String team, String opponents, String group) {
    return '이번 조별리그에서 $team은 $group에서 $opponents와 만납니다.';
  }

  @override
  String get worldCupTeamMatchOverviewTitle => '국가 경기 정보';

  @override
  String get worldCupTeamCurrentPointsLabel => '현재 승점';

  @override
  String get worldCupTeamMatchHistoryTitle => '상대별 결과';

  @override
  String get worldCupQualificationScenariosTitle => '32강 경우의 수';

  @override
  String worldCupQualificationScenariosSubtitle(
      int currentPoints, int remainingMatches) {
    return '현재 승점 $currentPoints점에서 남은 $remainingMatches경기 결과 조합별 32강 진출 가능성과 상대 후보를 계산해요.';
  }

  @override
  String get worldCupQualificationScenariosGuide =>
      '각 행은 이 팀의 남은 경기 결과 조합이에요. 직행은 조 1~2위, 3위 비교는 조 3위 뒤 전체 3위 팀 중 상위 8팀에 들어야 한다는 뜻입니다. 직행/3위 비교/탈락의 분모는 같은 조의 다른 남은 경기 승·무·패를 모두 섞어 본 경우 수예요. 상대 국가는 현재 순위로 브래킷 슬롯을 나라명으로 풀어쓴 후보입니다.';

  @override
  String get worldCupQualificationScenariosEmpty =>
      '이 국가의 32강 경우의 수를 계산할 조별리그 정보가 아직 없어요.';

  @override
  String worldCupQualificationScenarioPoints(
      int remainingPoints, int finalPoints) {
    return '남은 승점 +$remainingPoints · 최종 $finalPoints점';
  }

  @override
  String worldCupQualificationScenarioRankRange(int bestRank, int worstRank) {
    return '$bestRank~$worstRank위 가능';
  }

  @override
  String worldCupQualificationScenarioCases(int automaticCases,
      int thirdPlaceCases, int eliminatedCases, int totalCases) {
    return '직행 $automaticCases/$totalCases · 3위 비교 $thirdPlaceCases/$totalCases · 탈락 $eliminatedCases/$totalCases';
  }

  @override
  String get worldCupQualificationThirdPlaceNote =>
      '조 3위는 12개 조 3위 중 상위 8팀에 들어야 32강에 올라갑니다.';

  @override
  String worldCupQualificationMatchPick(String opponent, String result) {
    return '$opponent전 $result';
  }

  @override
  String get worldCupQualificationOutcomeAuto => '직행 확정';

  @override
  String get worldCupQualificationOutcomePossible => '진출 가능';

  @override
  String get worldCupQualificationOutcomeThird => '3위 비교';

  @override
  String get worldCupQualificationOutcomeOut => '탈락';

  @override
  String worldCupQualificationOpponentCandidates(String opponents) {
    return '32강 상대 후보(현재 순위): $opponents';
  }

  @override
  String get worldCupQualificationNoOpponent => '이 조합에서는 32강 진출 경로가 없어요.';

  @override
  String worldCupQualificationOpponentCandidate(String opponent) {
    return '$opponent';
  }

  @override
  String worldCupQualificationOpponentCandidateWithCountries(
      String opponent, String countries) {
    return '$opponent → $countries';
  }

  @override
  String get worldCupQualificationOpponentTeamSeparator => ', ';

  @override
  String get worldCupQualificationOpponentSeparator => ' 또는 ';

  @override
  String worldCupTeamRosterFormationLabel(String formation) {
    return '$formation 포메이션';
  }

  @override
  String get worldCupTeamRosterFormationEstimatedNote =>
      '공식 경기 라인업이 아니라 현재 선수단 데이터를 기준으로 배치한 예상 포메이션이에요. 실제 경기 전술과 선발은 달라질 수 있어요.';

  @override
  String get worldCupTeamRosterFormationPlaceholderNote =>
      '공식 선수단 데이터가 없어서 기본 포지션 슬롯으로 배치했어요. 실제 포메이션으로 보지 마세요.';

  @override
  String get worldCupTeamRosterSourceNote =>
      '이 국가는 아직 앱에 공식 2026 선수단 데이터가 포함되지 않아 안정적이고 합법적인 출처가 연결될 때까지 포지션 슬롯으로 표시됩니다.';

  @override
  String get worldCupTeamRosterCandidateSourceNote =>
      '공개된 2026 선수단 정보와 예상 포메이션 데이터를 바탕으로 보여줘요. 부상 교체와 경기 당일 선택은 킥오프 전까지 바뀔 수 있어요.';

  @override
  String get worldCupTeamRosterGoalkeepers => '골키퍼';

  @override
  String get worldCupTeamRosterDefenders => '수비수';

  @override
  String get worldCupTeamRosterMidfielders => '미드필더';

  @override
  String get worldCupTeamRosterForwards => '공격수';

  @override
  String get worldCupTeamRosterPositionGoalkeeper => 'GK';

  @override
  String get worldCupTeamRosterPositionDefender => 'DF';

  @override
  String get worldCupTeamRosterPositionMidfielder => 'MF';

  @override
  String get worldCupTeamRosterPositionForward => 'FW';

  @override
  String worldCupTeamRosterPlayerSlot(String position, int number) {
    return '$position $number';
  }

  @override
  String get worldCupTournamentTitle => '토너먼트 대진표';

  @override
  String get worldCupTournamentPlanBody =>
      '현재는 공식 일정의 조 순위와 이전 경기 승자 슬롯 기준으로 보여줘요. 조별리그 결과가 확정되면 각 슬롯을 실제 국가명으로 따라갈 수 있어요.';

  @override
  String worldCupStageMatchCount(int count) {
    return '$count경기';
  }

  @override
  String worldCupBracketRoundSummary(String dateRange, int count) {
    return '$dateRange · $count경기';
  }

  @override
  String worldCupBracketFirstSeed(String group) {
    return '$group조 1위';
  }

  @override
  String worldCupBracketSecondSeed(String group) {
    return '$group조 2위';
  }

  @override
  String worldCupBracketThirdSeed(String groups) {
    return '$groups조 3위 중 1팀';
  }

  @override
  String worldCupBracketWinnerSlot(int matchNumber) {
    return 'M$matchNumber 승자';
  }

  @override
  String worldCupBracketLoserSlot(int matchNumber) {
    return 'M$matchNumber 패자';
  }

  @override
  String worldCupBracketSourceMatch(int matchNumber, String home, String away) {
    return 'M$matchNumber: $home 대 $away';
  }

  @override
  String get worldCupSourceAction => 'FIFA 일정 열기';

  @override
  String get worldCupOfficialRefreshAction => 'FIFA 데이터 새로고침';

  @override
  String get worldCupOfficialRefreshing => 'FIFA 갱신 중';

  @override
  String get worldCupOfficialUnavailable => 'FIFA 연결 불가';

  @override
  String worldCupOfficialUpdatedAt(String time) {
    return 'FIFA $time';
  }

  @override
  String get homeTodayPlanCardTitle => '오늘의 훈련 계획';

  @override
  String homeTodayPlanCardSummary(int count) {
    return '오늘 계획 $count개';
  }

  @override
  String get homeTodayPlanOpenAction => '계획 보기';

  @override
  String get homeTodayPlanSelectForLogTitle => '훈련기록으로 만들 계획을 선택하세요';

  @override
  String get homeHubTitleShort => '홈';

  @override
  String get homeDailyCheckTitle => '오늘 할일';

  @override
  String homeDailyCheckCompletedCount(int completed, int total) {
    return '$completed/$total 완료';
  }

  @override
  String get homeTodoTrainingLogShort => '기록';

  @override
  String get homeTodoLiftingShort => '리프팅';

  @override
  String get homeTodoJumpRopeShort => '줄넘기';

  @override
  String get jumpRopeRecordTitle => '줄넘기 기록';

  @override
  String get jumpRopeMinutesLabel => '줄넘기 시간(분)';

  @override
  String get jumpRopeCountLabel => '줄넘기 횟수';

  @override
  String get jumpRopeMemoLabel => '메모';

  @override
  String get jumpRopeMemoHint => '줄넘기를 하면서 느낀 점을 적어보세요.';

  @override
  String get homeTodoQuizShort => '퀴즈';

  @override
  String get homeTodoNewsShort => '소식';

  @override
  String get homeTodoDiaryShort => '다이어리';

  @override
  String get homeTodoBoardSketchShort => '스케치';

  @override
  String get homeQuickActionsTitle => '빠른 실행';

  @override
  String get homeQuickActionMatch => '시합 기록';

  @override
  String get homeQuickActionPlan => '훈련 계획';

  @override
  String get homeContinueTitle => '이어하기';

  @override
  String get homeContinueEmpty => '오늘은 이어서 할 액션이 없어요. 아래에서 새 도전을 골라보세요.';

  @override
  String get homeContinueWrongAnswerReview => '오답 복습 이어하기';

  @override
  String get homeContinueQuiz => '퀴즈 이어하기';

  @override
  String get homeContinueStartQuiz => '새 퀴즈 시작';

  @override
  String homeContinueQuizProgress(int current, int total) {
    return '$current / $total 진행 중';
  }

  @override
  String get homeContinueQuizStartSubtitle => '오늘 퀴즈를 다시 시작해요.';

  @override
  String get homeContinueTodayTrainingLog => '오늘 훈련 기록';

  @override
  String homeContinueTrainingDuration(Object date, int duration) {
    return '$date · $duration분';
  }

  @override
  String get homeContinueTrainingButton => '이어서 쓰기';

  @override
  String get homeContinueTodayPlanTitle => '오늘 훈련 계획';

  @override
  String homeContinueTodayPlanSubtitle(int count) {
    return '오늘 계획 $count개가 있어요.';
  }

  @override
  String get homeContinuePlanButton => '계획 보기';

  @override
  String get homeContinueQuizButton => '퀴즈 열기';

  @override
  String get homeContinueRecentBoardTitle => '최근 훈련보드';

  @override
  String homeContinueBoardCount(int count) {
    return '스케치 $count개';
  }

  @override
  String homeContinueBoardSaved(Object title, Object date) {
    return '$title · 최근 저장 $date';
  }

  @override
  String get homeContinueBoardButton => '바로 수정';

  @override
  String get dailyTasksXpDialogTitle => '오늘 할일 완주';

  @override
  String get dailyTasksXpDialogMessage => '하루 루틴을 모두 맞췄어요. 꾸준함이 성장 보석으로 쌓였습니다.';

  @override
  String dailyTasksXpDialogGems(int count) {
    return '+$count 보석';
  }

  @override
  String dailyTasksXpDialogProgress(int totalXp, int remainingXp) {
    return '누적 $totalXp XP · 다음 레벨까지 $remainingXp XP';
  }

  @override
  String dailyTasksXpDialogMaxProgress(int totalXp, int remainingXp) {
    return '누적 $totalXp XP · 다음 마스터리 별까지 $remainingXp XP';
  }

  @override
  String get dailyTasksXpDialogAction => '계속하기';

  @override
  String get trainingXpDialogTitle => '훈련 기록 완료';

  @override
  String get trainingXpDialogMessage => '훈련 기록이 저장됐어요.';

  @override
  String get trainingRecordSavedDialogMessage => '기록이 저장됐어요.';

  @override
  String get trainingEntryConditioningEmpty => '줄넘기/리프팅 기록 없음';

  @override
  String get trainingEntryLessonSummary => '레슨';

  @override
  String get trainingEntryInjuryPresent => '부상 있음';

  @override
  String trainingEntryInjurySummary(String detail) {
    return '부상: $detail';
  }

  @override
  String trainingEntryInjuryPainSummary(int pain) {
    return '통증 $pain/10';
  }

  @override
  String get trainingXpDialogJumpRopeTitle => '줄넘기 기록 완료';

  @override
  String get trainingXpDialogJumpRopeMessage => '줄넘기 기록이 저장됐어요.';

  @override
  String get trainingXpDialogLiftingTitle => '리프팅 기록 완료';

  @override
  String get trainingXpDialogLiftingMessage => '리프팅 기록이 저장됐어요.';

  @override
  String get trainingXpDialogMealTitle => '회복 기록 완료';

  @override
  String get trainingXpDialogMealMessage => '식사와 회복 기록이 저장됐어요.';

  @override
  String get diaryXpDialogTitle => '다이어리 사파이어';

  @override
  String get diaryXpDialogMessage => '오늘을 돌아본 다이어리가 차분한 사파이어 경험치로 쌓였어요.';

  @override
  String get trainingSketchXpDialogTitle => '스케치 골드';

  @override
  String get trainingSketchXpDialogMessage =>
      '훈련 아이디어를 그린 스케치가 빛나는 골드 경험치로 쌓였어요.';

  @override
  String trainingXpDialogXp(int count) {
    return '+$count XP';
  }

  @override
  String get trainingXpDialogRewardLabel => '오늘 얻은 경험치';

  @override
  String get trainingRecordSavedDialogLabel => '기록 완료';

  @override
  String get trainingRecordSavedDialogValue => '저장 완료';

  @override
  String get trainingXpDialogTotalLabel => '누적 경험치';

  @override
  String trainingXpDialogTotalValue(int totalXp) {
    return '$totalXp XP';
  }

  @override
  String get trainingXpDialogLevelLabel => '현재 레벨';

  @override
  String trainingXpDialogLevelValue(int level, String levelName) {
    return 'Lv.$level $levelName';
  }

  @override
  String get trainingXpDialogAction => '확인';

  @override
  String get trainingXpSourceTrainingLog => '훈련 기록';

  @override
  String get trainingXpSourceTrainingUpdate => '훈련 기록 수정';

  @override
  String get trainingXpSourceLifting => '리프팅';

  @override
  String get trainingXpSourceJumpRope => '줄넘기';

  @override
  String get trainingXpSourceTrainingSketch => '훈련 스케치';

  @override
  String get trainingXpSourceDiary => '다이어리';

  @override
  String get trainingSaveToastPlain => '훈련노트를 저장했어요.';

  @override
  String trainingSaveToastWithXp(int gainedXp, Object details) {
    return '훈련노트를 저장했어요. +$gainedXp XP · $details';
  }

  @override
  String trainingSaveToastLevelUp(
      int gainedXp, Object details, int level, Object levelName) {
    return '훈련노트를 저장했어요. +$gainedXp XP · $details · Lv.$level $levelName 달성';
  }

  @override
  String get trainingXpToastReasonLiftingMissed => '리프팅 누락';

  @override
  String get trainingXpToastReasonJumpRopeMissed => '줄넘기 누락';

  @override
  String get trainingXpToastReasonMealFullBonus => '세 끼+밥 5개 이상';

  @override
  String get trainingXpToastReasonRoutineComplete => '훈련 루틴 완성';

  @override
  String get trainingXpToastReasonStreakDaily2 => '2~3일 연속 보너스';

  @override
  String get trainingXpToastReasonStreakDaily4 => '4~6일 연속 보너스';

  @override
  String get trainingXpToastReasonStreakDaily7 => '7일 이상 연속 보너스';

  @override
  String get trainingXpToastReasonStreak3 => '3일 연속 기록';

  @override
  String get trainingXpToastReasonStreak7 => '7일 연속 기록';

  @override
  String get trainingXpToastReasonWeekly3 => '주 3회 기록';

  @override
  String get trainingXpToastReasonWeekly5 => '주 5회 기록';

  @override
  String get trainingXpToastReasonDailyCap => '하루 상한 적용';

  @override
  String trainingXpToastMoreReasons(int count) {
    return '외 $count개';
  }

  @override
  String diarySavedWithXpFeedback(int count) {
    return '다이어리 저장 +$count XP';
  }

  @override
  String trainingStreakCheerTitle(int count) {
    return '$count일 연속 훈련';
  }

  @override
  String get trainingStreakCheerMessage =>
      '하루 단위 훈련 노트가 진짜 루틴으로 이어지고 있어요. 다음 훈련도 단순하게 반복해 보세요.';

  @override
  String get trainingStreakCheerAction => '계속하기';

  @override
  String get levelUpDialogTitle => '레벨 업!';

  @override
  String levelUpDialogLevelLabel(int level, Object levelName) {
    return 'Lv.$level $levelName';
  }

  @override
  String get levelUpDialogEncouragement =>
      '오늘의 노력이 반짝 성장으로 쌓였어요. 다음 훈련도 이 리듬으로 가면 됩니다.';

  @override
  String levelUpDialogEncouragementWithReward(Object rewardName) {
    return '오늘의 노력이 반짝 성장으로 쌓였고, $rewardName 선물도 준비됐어요.';
  }

  @override
  String levelUpDialogProgress(int xp, Object stageName) {
    return '+$xp 보석 획득 · 이제 $stageName 단계예요';
  }

  @override
  String get levelUpDialogRewardTitle => '선물 받기';

  @override
  String get levelUpDialogLater => '나중에 볼래';

  @override
  String get levelUpDialogClaimReward => '선물 받기';

  @override
  String get levelUpDialogConfirm => '좋아요';

  @override
  String levelUpRewardClaimed(Object rewardName) {
    return '$rewardName 선물을 받았어요.';
  }

  @override
  String get xpGuideDailyTasksCompleteTitle => '오늘 할일 모두 완료';

  @override
  String get quizXpSourceLabel => '스포츠 퀴즈';

  @override
  String get quizScreenTitle => '오늘의 퀴즈';

  @override
  String get quizLibraryAction => '문제';

  @override
  String get quizHistoryAction => '기록';

  @override
  String get quizBackHomeTooltip => '퀴즈 홈으로';

  @override
  String get quizResultMissReviewCountLabel => '복기할 오답';

  @override
  String get quizResultNoMissedQuestions => '이번 세트는 놓친 문제가 없습니다.';

  @override
  String get quizStudyGuideTitle => '학습 참고서';

  @override
  String get quizStudyGuideQuestionLabel => '문제';

  @override
  String get quizStudyGuideAnswerLabel => '정답';

  @override
  String get quizStudyGuideConceptLabel => '핵심 개념';

  @override
  String get quizStudyGuideApplicationLabel => '적용 포인트';

  @override
  String get quizStudyGuidePracticeLabel => '훈련 체크';

  @override
  String get quizStudyGuidePending => '정답을 고르면 학습 참고서가 열립니다.';

  @override
  String quizXpSavedFeedback(int count) {
    return '퀴즈 완료 +$count XP';
  }

  @override
  String get playerXpGuideTitle => '경험치가 오르는 방법';

  @override
  String playerXpGuideHeroLevel(int level) {
    return '지금 Lv.$level';
  }

  @override
  String playerXpGuideHeroBody(int remainingXp) {
    return '모든 경험치 획득 경로를 한눈에 정리했어요. 다음 레벨까지 $remainingXp XP 남았습니다.';
  }

  @override
  String playerXpGuideHeroMax(int masterySpan, int remainingXp) {
    return 'Lv.20 이후에는 $masterySpan XP마다 마스터리 별을 얻어요. 다음 별까지 $remainingXp XP 남았습니다.';
  }

  @override
  String get playerXpGuideLoggingTitle => '훈련 기록 경험치';

  @override
  String get playerXpGuideLoggingSubtitle =>
      '꾸준히 훈련 기록을 저장하면 가장 기본 성장 경험치가 쌓입니다.';

  @override
  String get playerXpGuideTrainingLogSaved => '훈련 기록 저장';

  @override
  String get playerXpGuideFirstDailyLog => '하루 첫 훈련 기록';

  @override
  String get playerXpGuidePlannedDayComplete => '계획한 날 훈련 완료';

  @override
  String get playerXpGuideLiftingRecorded => '리프팅 기록 추가';

  @override
  String get playerXpGuideJumpRopeRecorded => '줄넘기 기록 추가';

  @override
  String get playerXpGuideTrainingRoutineComplete => '리프팅+줄넘기+회복 루틴 완성';

  @override
  String get playerXpGuideMissingConditioning => '리프팅/줄넘기 없이 저장하면 감점';

  @override
  String get playerXpGuideMissingConditioningXp => '각 -5 XP';

  @override
  String get playerXpGuideStreakTitle => '연속 기록과 주간 보너스';

  @override
  String get playerXpGuideStreakSubtitle => '반복이 루틴이 될수록 더 큰 보너스가 열립니다.';

  @override
  String get playerXpGuideStreakMilestones => '3일 연속 기록 / 7일 연속 기록';

  @override
  String get playerXpGuideStreakDailyBonus => '연속 기록 일일 보너스';

  @override
  String get playerXpGuideWeeklyBonus => '주 3회 기록 / 주 5회 기록';

  @override
  String get playerXpGuideActivityTitle => '다른 활동 경험치';

  @override
  String get playerXpGuideActivitySubtitle =>
      '계획, 스케치, 식사, 다이어리, 퀴즈, 오늘 할일 완료도 저장하면 경험치가 쌓입니다.';

  @override
  String get playerXpGuidePlanCreated => '훈련 계획 생성';

  @override
  String get playerXpGuideMatchLogged => '시합 기록 저장';

  @override
  String get playerXpGuideTrainingSketchSaved => '훈련 스케치 저장';

  @override
  String get playerXpGuideTrainingSketchSavedXp => '+5 XP / +2 XP';

  @override
  String get playerXpGuideDiaryCreated => '다이어리 작성';

  @override
  String get playerXpGuideQuizComplete => '퀴즈 완료';

  @override
  String get playerXpGuideQuizCompleteXp => '정답 수에 따라 +2~+15 XP';

  @override
  String get playerXpGuideMealTwoPlus => '식사 두 끼 이상 기록';

  @override
  String get playerXpGuideMealFull => '세 끼 기록 / 세 끼 모두 공기밥 5개 이상';

  @override
  String get playerXpGuideDailyTasksComplete => '홈 오늘 할일 모두 완료';

  @override
  String get playerXpGuideDailyCap => '하루 긍정 경험치 상한';

  @override
  String get playerLevelName1 => '킥오프';

  @override
  String get playerLevelName2 => '루키';

  @override
  String get playerLevelName3 => '스타터';

  @override
  String get playerLevelName4 => '챌린저';

  @override
  String get playerLevelName5 => '플레이메이커';

  @override
  String get playerLevelName6 => '엔진';

  @override
  String get playerLevelName7 => '캡틴';

  @override
  String get playerLevelName8 => '엘리트';

  @override
  String get playerLevelName9 => '매치 리더';

  @override
  String get playerLevelName10 => '하이 퍼포머';

  @override
  String get playerLevelName11 => '드라이버';

  @override
  String get playerLevelName12 => '필드 메이커';

  @override
  String get playerLevelName13 => '컨트롤 타워';

  @override
  String get playerLevelName14 => '아이언 캡틴';

  @override
  String get playerLevelName15 => '게임 체인저';

  @override
  String get playerLevelName16 => '세션 마스터';

  @override
  String get playerLevelName17 => '에이스 코어';

  @override
  String get playerLevelName18 => '피치 아티스트';

  @override
  String get playerLevelName19 => '스타디움 아이콘';

  @override
  String get playerLevelName20 => '풋볼 선물왕';

  @override
  String get playerLevelStage1 => '입문 선수';

  @override
  String get playerLevelStage2 => '훈련 루키';

  @override
  String get playerLevelStage3 => '주전 성장기';

  @override
  String get playerLevelStage4 => '경기 리더';

  @override
  String get playerLevelStage5 => '상위 경쟁자';

  @override
  String get playerLevelStage6 => '핵심 에이스';

  @override
  String get playerLevelStage7 => '엘리트 트랙';

  @override
  String get playerLevelBaseballNames =>
      '플레이볼|루키 타자|라인업 스타터|베이스 챌린저|클러치 메이커|이닝 엔진|덕아웃 캡틴|다이아몬드 엘리트|게임 리더|하이 퍼포머|슬러거 드라이버|필드 메이커|사인 컨트롤러|아이언 캡틴|게임 체인저|시리즈 마스터|에이스 코어|다이아몬드 아티스트|볼파크 아이콘|야구 선물왕';

  @override
  String get playerLevelBasketballNames =>
      '팁오프|코트 루키|라인업 스타터|림 챌린저|플레이메이커|코트 엔진|팀 캡틴|엘리트 가드|게임 리더|하이 퍼포머|드라이브 리더|코트 메이커|페이스 컨트롤러|아이언 캡틴|클러치 체인저|세션 마스터|에이스 코어|코트 아티스트|아레나 아이콘|농구 선물왕';

  @override
  String get playerLevelTennisNames =>
      '퍼스트 서브|코트 루키|랠리 스타터|베이스라인 챌린저|포인트 메이커|풋워크 엔진|매치 캡틴|엘리트 랠러|게임 리더|하이 퍼포머|서브 드라이버|코트 메이커|템포 컨트롤러|아이언 캡틴|타이브레이크 체인저|세션 마스터|에이스 코어|라인 아티스트|센터코트 아이콘|테니스 선물왕';

  @override
  String get playerLevelBaseballStages =>
      '입문 선수|루키 타자|선발 성장기|게임 리더|상위 경쟁자|핵심 에이스|엘리트 다이아몬드';

  @override
  String get playerLevelBasketballStages =>
      '입문 선수|코트 루키|주전 성장기|게임 리더|상위 경쟁자|핵심 에이스|엘리트 코트';

  @override
  String get playerLevelTennisStages =>
      '입문 선수|코트 루키|랠리 성장기|매치 리더|상위 경쟁자|핵심 에이스|엘리트 투어';

  @override
  String get playerLevelBaseballIllustrations =>
      '플레이볼 사인|첫 글러브|타격 티|스피드 스파이크|송구 리듬|파워 배트|작전 라인업|캡틴 모자|우승 트로피|축하 불꽃|수비 글러브|포수 미트|사인 레이더|주루 번개|승리 메달|홈구장|에이스 로켓|다이아몬드 스타|볼파크 선물상자|레전드 은하';

  @override
  String get playerLevelBasketballIllustrations =>
      '팁오프 볼|첫 농구공|훈련 콘|스피드 슈즈|드리블 리듬|파워 덤벨|작전 보드|캡틴 왕관|우승 트로피|축하 불꽃|수비 방패|리바운드 손|전술 레이더|속공 번개|승리 메달|홈 아레나|에이스 로켓|코트 스타|아레나 선물상자|레전드 은하';

  @override
  String get playerLevelTennisIllustrations =>
      '첫 서브|첫 라켓|훈련 콘|스피드 슈즈|랠리 리듬|파워 덤벨|작전 노트|캡틴 왕관|우승 트로피|축하 불꽃|수비 방패|매치 타월|전술 레이더|풋워크 번개|승리 메달|센터 코트|에이스 로켓|라인 스타|센터코트 선물상자|레전드 은하';

  @override
  String get playerLevelIllustration1 => '시작 호루라기';

  @override
  String get playerLevelIllustration2 => '첫 축구공';

  @override
  String get playerLevelIllustration3 => '훈련 콘';

  @override
  String get playerLevelIllustration4 => '스피드 축구화';

  @override
  String get playerLevelIllustration5 => '줄넘기 리듬';

  @override
  String get playerLevelIllustration6 => '힘쎈 아령';

  @override
  String get playerLevelIllustration7 => '작전 보드';

  @override
  String get playerLevelIllustration8 => '주장 왕관';

  @override
  String get playerLevelIllustration9 => '우승 트로피';

  @override
  String get playerLevelIllustration10 => '축하 불꽃';

  @override
  String get playerLevelIllustration11 => '수비 방패';

  @override
  String get playerLevelIllustration12 => '골키퍼 장갑';

  @override
  String get playerLevelIllustration13 => '전술 레이더';

  @override
  String get playerLevelIllustration14 => '질주 번개';

  @override
  String get playerLevelIllustration15 => '승리 메달';

  @override
  String get playerLevelIllustration16 => '홈 경기장';

  @override
  String get playerLevelIllustration17 => '에이스 로켓';

  @override
  String get playerLevelIllustration18 => '피치 스타';

  @override
  String get playerLevelIllustration19 => '스타디움 선물상자';

  @override
  String get playerLevelIllustration20 => '레전드 은하';

  @override
  String get levelGuideTitle => '레벨 가이드';

  @override
  String get levelGuideOpenXpGuideTooltip => '경험치 가이드 열기';

  @override
  String get levelGuideXpHistoryTooltip => '경험치 히스토리';

  @override
  String get levelGuideCurrentProgressTitle => '현재 진행 상태';

  @override
  String levelGuideCurrentProgressTotal(int level, int totalXp) {
    return 'Lv.$level · 총 $totalXp XP';
  }

  @override
  String levelGuideCurrentProgressMax(int stars, int remainingXp) {
    return '마스터리 별 $stars개 · 다음 별까지 $remainingXp XP 남았습니다.';
  }

  @override
  String levelGuideCurrentProgressNext(int remainingXp) {
    return '다음 레벨까지 $remainingXp XP 남았습니다. 우측 상단에서 경험치 가이드와 히스토리를 바로 열 수 있어요.';
  }

  @override
  String get levelGuideSetRewardTitle => '레벨 선물 입력';

  @override
  String get levelGuideRewardNameLabel => '선물 이름';

  @override
  String get levelGuideRewardNameHint => '예) 새 축구 양말';

  @override
  String get levelGuideClearRewardAction => '삭제';

  @override
  String get levelGuideCurrentBadge => '지금 여기';

  @override
  String levelGuideXpRangeLabel(int minXp, int maxXp) {
    return '$minXp XP ~ $maxXp XP';
  }

  @override
  String get levelGuideRewardTitle => '레벨 선물';

  @override
  String get levelGuideEditReward => '입력';

  @override
  String get levelGuideRewardNotSet => '미정';

  @override
  String get levelGuideSyncing => '동기화 중...';

  @override
  String get levelGuideRewardNeedsName => '선물 입력 후 수령 가능';

  @override
  String get levelGuideRewardAlreadyClaimed => '이미 받음';

  @override
  String get levelGuideClaimReward => '선물 받기';

  @override
  String levelGuideRewardLocked(int level) {
    return 'Lv.$level 달성 시 수령 가능';
  }

  @override
  String get xpHistoryTitle => '경험치 히스토리';

  @override
  String get xpHistoryClearAllAction => '전체 삭제';

  @override
  String get xpHistoryEmpty => '아직 쌓인 경험치 기록이 없습니다.';

  @override
  String get xpHistoryMessageDeleted => '경험치 메세지를 삭제했어요.';

  @override
  String get xpHistoryDeleteDialogTitle => '경험치 메세지 삭제';

  @override
  String get xpHistoryDeleteDialogBody => '쌓인 경험치 메세지를 모두 삭제할까요?';

  @override
  String get xpHistoryAllDeleted => '경험치 메세지를 모두 삭제했어요.';

  @override
  String get xpHistoryRecentFlow => '최근 경험치 흐름';

  @override
  String xpHistorySummaryCount(int count) {
    return '총 $count개의 기록이 저장되어 있습니다.';
  }

  @override
  String xpHistorySummaryLatest(Object title) {
    return '아래에서 날짜와 시간 순서대로 바로 내려가며 확인할 수 있어요. 최근 기록은 $title 입니다.';
  }

  @override
  String xpHistoryDayEventCount(int count) {
    return '$count개의 경험치 변동';
  }

  @override
  String get xpHistoryDeleteMessageTooltip => '메세지 삭제';

  @override
  String xpHistoryTotalXp(int totalXp) {
    return '누적 $totalXp XP';
  }

  @override
  String xpHistoryStayedAtLevel(int level) {
    return 'Lv.$level 유지';
  }

  @override
  String get xpHistoryTrainingLog => '훈련 기록 저장';

  @override
  String xpHistoryTrainingLogWithLabel(Object label) {
    return '훈련 기록 · $label';
  }

  @override
  String get xpHistoryMatchLog => '시합 기록 저장';

  @override
  String xpHistoryMatchLogWithLabel(Object label) {
    return '시합 기록 · $label';
  }

  @override
  String get xpHistoryMealLog => '식사 기록 저장';

  @override
  String get xpHistoryQuizCompletion => '퀴즈 완료';

  @override
  String get xpHistoryPlanCreated => '훈련 계획 생성';

  @override
  String get xpHistoryBoardSaved => '훈련 스케치 저장';

  @override
  String xpHistoryBoardSavedWithLabel(Object label) {
    return '훈련 스케치 · $label';
  }

  @override
  String get xpHistoryDiaryCreated => '오늘 다이어리 작성';

  @override
  String get xpHistoryDailyTasksComplete => '오늘 할일 완주';

  @override
  String get xpHistoryTrainingLabelLifting => '리프팅';

  @override
  String get xpHistoryTrainingLabelJumpRope => '줄넘기';

  @override
  String get xpHistoryReasonLog => '기본 기록';

  @override
  String get xpHistoryReasonFirstDailyLog => '하루 첫 기록';

  @override
  String get xpHistoryReasonPlanCompleted => '계획 수행';

  @override
  String get xpHistoryReasonLiftingRecorded => '리프팅 기록';

  @override
  String get xpHistoryReasonJumpRopeRecorded => '줄넘기 기록';

  @override
  String get xpHistoryReasonLiftingMissed => '리프팅 미기록';

  @override
  String get xpHistoryReasonJumpRopeMissed => '줄넘기 미기록';

  @override
  String get xpHistoryReasonLiftingAdded => '리프팅 추가 기록';

  @override
  String get xpHistoryReasonJumpRopeAdded => '줄넘기 추가 기록';

  @override
  String get xpHistoryReasonMealTwoPlus => '두 끼 이상';

  @override
  String get xpHistoryReasonMealFullDay => '세 끼 완료';

  @override
  String get xpHistoryReasonMealFullDayBonus => '세 끼+밥 5개 이상';

  @override
  String get xpHistoryReasonStreak3 => '3일 연속';

  @override
  String get xpHistoryReasonStreak7 => '7일 연속';

  @override
  String get xpHistoryReasonStreakDaily2 => '연속 기록 데일리(2~3일)';

  @override
  String get xpHistoryReasonStreakDaily4 => '연속 기록 데일리(4~6일)';

  @override
  String get xpHistoryReasonStreakDaily7 => '연속 기록 데일리(7일+)';

  @override
  String get xpHistoryReasonRoutineComplete => '하루 루틴 완주';

  @override
  String get xpHistoryReasonWeekly3 => '주간 3회';

  @override
  String get xpHistoryReasonWeekly5 => '주간 5회';

  @override
  String get xpHistoryReasonQuizComplete => '퀴즈 완료';

  @override
  String get xpHistoryReasonPlanCreated => '계획 생성';

  @override
  String xpHistoryReasonPlanGroupCreated(int count) {
    return '묶음 계획 $count개';
  }

  @override
  String get xpHistoryReasonMatchLogged => '시합 기록';

  @override
  String get xpHistoryReasonMatchResultRecorded => '시합 결과 기록';

  @override
  String get xpHistoryReasonMatchContributionRecorded => '시합 기여 기록';

  @override
  String get xpHistoryReasonBoardCreated => '보드 생성';

  @override
  String get xpHistoryReasonBoardSaved => '보드 저장';

  @override
  String get xpHistoryReasonDiaryCreated => '다이어리 작성';

  @override
  String get xpHistoryReasonDailyTasksCompleted => '오늘 할일 완주';

  @override
  String get xpHistoryReasonDailyCap => '하루 상한';

  @override
  String get profilePlayerLevelLabel => '선수 레벨';

  @override
  String get profileVisualGrowthTier => '비주얼 성장 단계';

  @override
  String profileRewardReadySummary(int count) {
    return '지금 받을 선물 $count개';
  }

  @override
  String get profileNoNextReward => '다음 선물이 아직 없어요';

  @override
  String profileRewardNow(Object rewardName) {
    return '지금 선물: $rewardName';
  }

  @override
  String profileNextReward(int level, Object rewardName) {
    return '다음 선물 Lv.$level $rewardName';
  }

  @override
  String profileSportStartDateLabel(Object sport) {
    return '$sport 시작일';
  }

  @override
  String profileLevelProgressMax(int stars, int remainingXp) {
    return '마스터리 별 $stars개 · 다음 $remainingXp XP';
  }

  @override
  String profileLevelProgressNext(int remainingXp, int totalXp) {
    return '다음 $remainingXp XP · 총 $totalXp XP';
  }

  @override
  String homeLevelProgressMax(int stars, int remainingXp) {
    return '별 $stars개 · 다음 별 ${remainingXp}XP';
  }

  @override
  String homeLevelProgressNext(int remainingXp) {
    return '다음까지 ${remainingXp}XP';
  }

  @override
  String get homePriorityCheckPlansMessage => '남은 훈련 계획을 먼저 확인해 주세요.';

  @override
  String get homePriorityPlansAction => '계획';

  @override
  String get homePriorityPlanNextMessage => '짧은 훈련 계획을 추가해 보세요.';

  @override
  String get homePriorityPlanNextAction => '계획 추가';

  @override
  String get homePriorityReviewWeekMessage => '이번 주 훈련 흐름을 확인하고 다음 목표를 정해 보세요.';

  @override
  String get homePriorityStatsAction => '통계';

  @override
  String get homePrioritySketchNextMessage => '다음 훈련에서 해볼 움직임을 보드에 스케치해 보세요.';

  @override
  String get homePriorityBoardAction => '보드';

  @override
  String get homePriorityConditionMessage => '최근 컨디션 흐름을 확인하고 회복 계획을 조정해 보세요.';

  @override
  String get homePriorityRewardsMessage => '레벨 보상과 다음 성장 목표를 확인해 보세요.';

  @override
  String get homePriorityLevelAction => '레벨';

  @override
  String get homeMealSuggestionDoneShort => '세 끼를 모두 기록하셨습니다. 좋은 리듬을 이어가세요.';

  @override
  String get homeMealSuggestionTwoShort => '한 끼만 더 기록해 주세요.';

  @override
  String get homeMealSuggestionOneShort => '두 끼를 더 기록해 주세요.';

  @override
  String get homeMealSuggestionNoneShort => '오늘 첫 끼부터 기록해 주세요.';

  @override
  String get homeNextTrainingTitle => '다음 훈련';

  @override
  String get homeNextTrainingToday => '오늘';

  @override
  String get homeNextTrainingTomorrow => '내일';

  @override
  String homeNextTrainingInDays(int count) {
    return '$count일 뒤';
  }

  @override
  String homeNextTrainingCount(int count) {
    return '$count개 예정';
  }

  @override
  String get profileTestsActionLabel => '성향 테스트';

  @override
  String entryStartedFromPlanSummary(String summary) {
    return '오늘 계획 반영: $summary';
  }

  @override
  String get fifaHubAppBarTitle => 'FIFA 랭킹';

  @override
  String get fifaHubHeroTitle => '전 세계 FIFA 랭킹과 A매치 허브';

  @override
  String get fifaHubHeroSubtitle =>
      'FIFA 공식 데이터를 바탕으로 전체 랭킹과 최근 결과, 예정 경기를 한 번에 확인하세요.';

  @override
  String get fifaHubMenLabel => '남자';

  @override
  String get fifaHubWomenLabel => '여자';

  @override
  String get fifaHubLeaderLabel => '현재 1위';

  @override
  String fifaHubRankedTeamsCount(int count) {
    return '랭킹 $count개 팀';
  }

  @override
  String fifaHubConfederationCount(int count) {
    return '$count개 대륙 연맹';
  }

  @override
  String fifaHubRecentResultsCount(int count) {
    return '최근 결과 $count경기';
  }

  @override
  String fifaHubUpcomingFixturesCount(int count) {
    return '예정 경기 $count경기';
  }

  @override
  String get fifaHubNextUpdateLabel => '다음 업데이트';

  @override
  String get fifaHubDataSourceLabel => '데이터 출처: FIFA 공식 랭킹 및 실시간 경기 피드';

  @override
  String get fifaHubHighlightsTitle => '순위 변동 하이라이트';

  @override
  String get fifaHubBiggestClimber => '최대 상승';

  @override
  String get fifaHubBiggestFaller => '최대 하락';

  @override
  String get fifaHubGlobalRankingTitle => '전체 랭킹';

  @override
  String get fifaHubGlobalRankingSubtitle => '섹션을 펼쳐 전체 국가대표 순위를 확인하세요.';

  @override
  String get fifaHubShowAll => '전체 보기';

  @override
  String get fifaHubShowLess => '접기';

  @override
  String get fifaHubShowAllList => '전체 목록 보기';

  @override
  String get fifaHubCollapseList => '목록 접기';

  @override
  String get fifaHubRecentResultsTitle => '전 세계 A매치 최근 결과';

  @override
  String get fifaHubRecentResultsSubtitle =>
      'FIFA 경기 피드에서 시니어 국가대표 경기만 골라 보여줍니다.';

  @override
  String get fifaHubRecentResultsEmpty => '최근 전 세계 A매치 결과를 찾지 못했어요.';

  @override
  String get fifaHubUpcomingFixturesTitle => '전 세계 A매치 예정 경기';

  @override
  String get fifaHubUpcomingFixturesSubtitle =>
      '최신 FIFA 일정 구간 기준의 시니어 국가대표 예정 경기입니다.';

  @override
  String get fifaHubUpcomingFixturesEmpty => '예정된 전 세계 A매치 일정을 찾지 못했어요.';

  @override
  String get fifaHubKfaUpcomingFixturesTitle => 'KFA 대한민국 경기 일정';

  @override
  String get fifaHubKfaUpcomingFixturesSubtitle =>
      '대한축구협회 공식 Next Match 기준입니다.';

  @override
  String get fifaHubKfaUpcomingFixturesEmpty => 'KFA 공식 경기 일정을 찾지 못했어요.';

  @override
  String get fifaHubKfaRecentResultsTitle => 'KFA 대한민국 경기 결과';

  @override
  String get fifaHubKfaRecentResultsSubtitle =>
      '대한축구협회 공식 Match Results 기준입니다.';

  @override
  String get fifaHubKfaRecentResultsEmpty => 'KFA 공식 경기 결과를 찾지 못했어요.';

  @override
  String get fifaHubMatchStatusResult => '결과';

  @override
  String get fifaHubMatchStatusLive => '진행 중';

  @override
  String get fifaHubMatchStatusFixture => '예정';

  @override
  String get fifaHubLoadError => 'FIFA 데이터를 불러오지 못했어요. 아래로 당겨 새로고침해 주세요.';

  @override
  String get fifaHubNoData => '현재 표시할 FIFA 랭킹 또는 A매치 데이터가 없어요.';

  @override
  String get fifaMatchDetailTitle => '경기 상세';

  @override
  String get fifaMatchDetailResultSummaryTitle => '결과 요약';

  @override
  String get fifaMatchDetailFixtureSummaryTitle => '일정 요약';

  @override
  String get fifaMatchDetailCompetitionLabel => '대회';

  @override
  String get fifaMatchDetailKickoffLabel => '킥오프';

  @override
  String get fifaMatchDetailDateLabel => '일시';

  @override
  String get fifaMatchDetailStageLabel => '라운드';

  @override
  String get fifaMatchDetailVenueLabel => '경기장';

  @override
  String get fifaMatchDetailCityLabel => '도시';

  @override
  String get fifaMatchDetailMatchIdLabel => '경기 ID';

  @override
  String get fifaMatchDetailScoreUnavailable => '스코어 미확정';

  @override
  String get fifaMatchDetailVersusLabel => 'vs';

  @override
  String get fifaMatchDetailHomeTeamLabel => '홈';

  @override
  String get fifaMatchDetailAwayTeamLabel => '원정';

  @override
  String get fifaMatchDetailScorersTitle => '득점자';

  @override
  String get fifaMatchDetailPossessionTitle => '볼 점유율';

  @override
  String get fifaMatchDetailAdvancedLoading => '세부 기록 확인 중...';

  @override
  String get fifaMatchDetailAdvancedUnavailable =>
      '득점자와 볼 점유율 세부 기록을 원본에서 찾지 못했어요.';

  @override
  String get fifaMatchDetailScorersUnavailable => '득점자 정보를 찾지 못했어요.';

  @override
  String get fifaMatchDetailPossessionUnavailable => '볼 점유율 정보를 찾지 못했어요.';

  @override
  String get fifaMatchDetailUnknownScorer => '선수 정보 미제공';

  @override
  String get fifaMatchDetailFifaSourceNote => 'FIFA 공식 경기 API 기준입니다.';

  @override
  String get fifaMatchDetailKfaSourceNote =>
      'KFA 홈 피드 기준입니다. 득점자와 볼 점유율은 원본에서 제공되지 않을 수 있어요.';

  @override
  String get fifaMatchDetailOpenSource => '원본 열기';

  @override
  String get fifaCountryDetailRankingSummaryTitle => '랭킹 요약';

  @override
  String get fifaCountryDetailTeamProfileTitle => '팀 프로필';

  @override
  String get fifaCountryDetailCurrentRankLabel => '현재 순위';

  @override
  String get fifaCountryDetailPreviousRankLabel => '이전 순위';

  @override
  String get fifaCountryDetailPointsLabel => '포인트';

  @override
  String get fifaCountryDetailPointChangeLabel => '포인트 변동';

  @override
  String get fifaCountryDetailConfederationLabel => '대륙 연맹';

  @override
  String get fifaCountryDetailCountryCodeLabel => '국가 코드';

  @override
  String get fifaCountryDetailTeamIdLabel => 'FIFA 팀 ID';

  @override
  String get fifaCountryDetailAbbreviationLabel => '약어';

  @override
  String get fifaCountryDetailFoundationYearLabel => '창립연도';

  @override
  String get fifaCountryDetailCityLabel => '도시';

  @override
  String get fifaCountryDetailStadiumLabel => '경기장';

  @override
  String get fifaCountryDetailAddressLabel => '주소';

  @override
  String get fifaCountryDetailProfileUnavailable =>
      '현재 추가 FIFA 팀 프로필을 찾지 못했어요.';

  @override
  String get fifaCountryDetailProfileSource => 'FIFA 공식 팀 API 기준 프로필입니다.';

  @override
  String get fifaCountryDetailRecentMatchesTitle => '이 팀의 최근 A매치';

  @override
  String get fifaCountryDetailUpcomingMatchesTitle => '이 팀의 예정 A매치';

  @override
  String get fifaCountryDetailMatchesUnavailable =>
      '불러온 FIFA 피드에서 이 팀의 경기를 찾지 못했어요.';

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
  String get entryProgramDurationsTitle => '훈련 프로그램';

  @override
  String get entryProgramDurationsSubtitle => '프로그램과 시간을 함께 기록하세요.';

  @override
  String entryProgramDurationTotal(Object minutes) {
    return '합계 $minutes';
  }

  @override
  String get entryProgramDurationAddAction => '프로그램 추가';

  @override
  String get entryProgramDurationRemoveTooltip => '프로그램 시간 삭제';

  @override
  String get entryProgramDurationEmpty => '훈련 프로그램을 추가해요.';

  @override
  String get entryProgramOptionAddTooltip => '프로그램 옵션 추가';

  @override
  String get entryDurationOptionAddTooltip => '시간 옵션 추가';

  @override
  String get entryTodayGoalsTitle => '오늘의 목표';

  @override
  String get entryTodayGoalAddTitle => '오늘의 목표 추가';

  @override
  String get entryTodayGoalAddTooltip => '목표 추가';

  @override
  String get entryTodayGoalsSelectTooltip => '오늘의 목표 선택';

  @override
  String get entryTodayGoalsSelectTitle => '오늘의 목표 선택';

  @override
  String get entryTodayGoalsDone => '완료';

  @override
  String get entryTodayGoalsNone => '선택된 목표 없음';

  @override
  String entryTodayGoalsSelectedCount(int count) {
    return '$count개 선택됨';
  }

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
  String get entryLesson => '레슨 여부';

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
  String get filterJumpRopeOnly => '줄넘기 한 날만';

  @override
  String get filterFeedbackOnly => '피드백 있는 기록만';

  @override
  String get filterEmptyResetHint => '필터를 초기화하면 더 많은 기록을 볼 수 있어요.';

  @override
  String get filterReset => '초기화';

  @override
  String get filterApply => '적용';

  @override
  String get logsLayoutCard => '카드';

  @override
  String get logsLayoutList => '리스트';

  @override
  String get logsTrainingSketchListLabel => '훈련 스케치 리스트';

  @override
  String get logsTrainingSketchTitle => '훈련 스케치';

  @override
  String get logsEmptyFirstEntrySubtitle => '첫 훈련기록을 남기고 흐름을 시작해보세요.';

  @override
  String get logsEntryDeletedSnack => '기록을 삭제했어요.';

  @override
  String get logsEntryDeleteUndoAction => '되돌리기';

  @override
  String get logsDeleteUndoneSnack => '삭제를 되돌렸어요.';

  @override
  String get deleteEntry => '기록 삭제';

  @override
  String get deleteConfirm => '선택한 기록을 삭제할까요?';

  @override
  String get cancel => '취소';

  @override
  String get delete => '삭제';

  @override
  String get undo => '되돌리기';

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
  String get statsMatchTrendStable => '최근 흐름이 무너지지 않았습니다.';

  @override
  String get statsMatchTrendNeedsAttention => '결과 흐름 관리가 필요합니다.';

  @override
  String statsMatchInsightMessage(
      int count,
      Object primaryLabel,
      int primaryValue,
      Object secondaryLabel,
      int secondaryValue,
      Object direction) {
    return '$count경기 동안 개인 기록은 $primaryLabel $primaryValue · $secondaryLabel $secondaryValue입니다. $direction';
  }

  @override
  String statsReportTrainingTitle(Object sport) {
    return '$sport 성장 요약';
  }

  @override
  String get statsReportInsightTitle => '기간 리포트';

  @override
  String get statsReportTargetLabel => '목표 달성';

  @override
  String statsReportTargetPercentValue(int percent) {
    return '$percent%';
  }

  @override
  String get statsReportNoTargetValue => '기준 없음';

  @override
  String get statsReportSessionsLabel => '훈련 횟수';

  @override
  String statsReportSessionsValue(int count) {
    return '$count회';
  }

  @override
  String get statsReportTotalTimeLabel => '총 훈련 시간';

  @override
  String get statsReportTrainingRhythmLabel => '기록 리듬';

  @override
  String statsReportTrainingRhythmValue(
      int sessions, int activeDays, int periodDays) {
    return '$sessions회 · $activeDays/$periodDays일';
  }

  @override
  String get statsReportLessonCountLabel => '레슨 횟수';

  @override
  String statsReportLessonCountValue(int count) {
    return '$count회';
  }

  @override
  String get statsReportActiveDaysLabel => '기록일';

  @override
  String statsReportActiveDaysValue(int activeDays, int periodDays) {
    return '$activeDays/$periodDays일';
  }

  @override
  String get statsReportPlanExecutionLabel => '계획 실행률';

  @override
  String get statsReportTargetPlanLabel => '목표/계획';

  @override
  String statsReportTargetPlanValue(Object target, Object plan) {
    return '목표 $target · 계획 $plan';
  }

  @override
  String get statsReportNoPlanValue => '계획 없음';

  @override
  String get statsReportFocusLabel => '집중 분야';

  @override
  String get statsReportDefaultFocus => '기본기';

  @override
  String statsReportFocusStreakValue(Object focus, int days) {
    return '$focus · $days일 연속';
  }

  @override
  String get statsReportStreakLabel => '꾸준함';

  @override
  String statsReportStreakValue(int days) {
    return '$days일 연속 기록';
  }

  @override
  String get statsReportMealCoverageLabel => '식사 기록률';

  @override
  String statsReportMealCoverageValue(
      int mealDays, int periodDays, int fullMealDays) {
    return '$mealDays/$periodDays일 · 3끼 $fullMealDays일';
  }

  @override
  String get statsReportConditionLabel => '컨디션';

  @override
  String statsReportConditionValue(
      Object intensity, Object mood, int injuryDays) {
    return '강도 $intensity · 기분 $mood · 부상 $injuryDays일';
  }

  @override
  String statsReportConditioningValue(int minutes, int count) {
    return '$minutes분 · $count회';
  }

  @override
  String statsReportInsightRecovery(int injuryDays, Object mood) {
    return '부상 기록 $injuryDays일, 평균 기분 $mood입니다. 다음 기록에서는 회복 강도와 통증 변화를 먼저 확인하세요.';
  }

  @override
  String statsReportInsightNeedsVolume(
      Object sport, int percent, int activeDays, int periodDays) {
    return '$sport 훈련량은 목표의 $percent%입니다. $activeDays/$periodDays일 기록이라 다음 기간에는 짧은 세션을 더 자주 배치하세요.';
  }

  @override
  String statsReportInsightMealGap(int mealDays, int activeDays) {
    return '훈련 기록일 $activeDays일 중 식사 기록은 $mealDays일입니다. 회복 판단을 위해 훈련일 식사를 함께 남기는 흐름이 필요합니다.';
  }

  @override
  String statsReportInsightNoConditioning(
      Object primaryLabel, Object secondaryLabel) {
    return '$primaryLabel/$secondaryLabel 기록이 비어 있습니다. 종목 보조운동을 함께 남기면 성장 추세를 더 정확히 볼 수 있습니다.';
  }

  @override
  String statsReportInsightBalanced(
      Object sport, int activeDays, int periodDays) {
    return '$sport 기록이 $activeDays/$periodDays일 이어졌고 보조운동/식사 흐름도 확인됩니다. 다음 기간에는 가장 많이 한 집중 분야의 품질을 비교하세요.';
  }

  @override
  String statsSecondaryConditioningNoRecords(Object label) {
    return '선택한 기간에 $label 세부 기록이 없습니다.';
  }

  @override
  String statsSecondaryConditioningDailyTotals(Object label) {
    return '일자별 $label 총 횟수';
  }

  @override
  String statsPrimaryConditioningStatsTitle(Object label) {
    return '$label 통계';
  }

  @override
  String statsPrimaryConditioningNoRecords(Object label) {
    return '선택한 기간에 기록된 $label 횟수나 시간이 없습니다.';
  }

  @override
  String statsPrimaryConditioningTooltipCount(Object label, int count) {
    return '$label $count회';
  }

  @override
  String statsPrimaryConditioningTooltipMinutes(Object label, int minutes) {
    return '$label $minutes분';
  }

  @override
  String statsPrimaryConditioningDailyCount(Object label) {
    return '일자별 $label 횟수';
  }

  @override
  String statsPrimaryConditioningDailyMinutes(Object label) {
    return '일자별 $label 시간';
  }

  @override
  String statsPrimaryConditioningTotalCount(int count) {
    return '총합 $count회';
  }

  @override
  String statsPrimaryConditioningTotalMinutes(int minutes) {
    return '총 $minutes분';
  }

  @override
  String statsPrimaryConditioningBestCount(int month, int day, int count) {
    return '최고 $month/$day · $count회';
  }

  @override
  String statsPrimaryConditioningBestMinutes(int month, int day, int minutes) {
    return '최고 $month/$day · $minutes분';
  }

  @override
  String statsMatchFormTitle(Object sport) {
    return '$sport 경기 리포트';
  }

  @override
  String get statsMatchFormInsightTitle => '경기 흐름';

  @override
  String get statsMatchFormLabel => '최근 폼';

  @override
  String get statsMatchFormUnsetValue => '결과 미입력';

  @override
  String get statsMatchUnsetValue => '미입력';

  @override
  String get statsMatchOutcomeWinShort => '승';

  @override
  String get statsMatchOutcomeDrawShort => '무';

  @override
  String get statsMatchOutcomeLossShort => '패';

  @override
  String get statsMatchWinRateLabel => '승률';

  @override
  String statsMatchWinRateValue(int percent) {
    return '$percent%';
  }

  @override
  String get statsMatchAverageScoreLabel => '평균 득실';

  @override
  String statsMatchAverageScoreValue(Object scored, Object conceded) {
    return '$scored:$conceded';
  }

  @override
  String get statsMatchPersonalPerMatchLabel => '경기당 개인 기록';

  @override
  String statsMatchPersonalPerMatchValue(Object primaryLabel,
      Object primaryValue, Object secondaryLabel, Object secondaryValue) {
    return '$primaryLabel $primaryValue · $secondaryLabel $secondaryValue';
  }

  @override
  String statsMatchPerUnitLabel(int minutes) {
    return '$minutes분 기준';
  }

  @override
  String statsMatchPerUnitValue(Object primaryLabel, Object primaryValue,
      Object secondaryLabel, Object secondaryValue) {
    return '$primaryLabel $primaryValue · $secondaryLabel $secondaryValue';
  }

  @override
  String get statsMatchMinutesLabel => '출전 시간';

  @override
  String get statsMatchNoMinutesValue => '시간 미입력';

  @override
  String statsMatchFormInsightNoResults(Object sport) {
    return '$sport 경기 결과가 아직 부족합니다. 점수와 개인 기록을 함께 남기면 흐름을 계산할 수 있습니다.';
  }

  @override
  String statsMatchFormInsightPositive(Object sport, Object form, int winRate) {
    return '최근 $sport 폼은 $form, 승률 $winRate%입니다. 강점으로 이어진 개인 기록을 다음 경기에서도 반복하세요.';
  }

  @override
  String statsMatchFormInsightNeedsWork(
      Object sport, Object form, int winRate) {
    return '최근 $sport 폼은 $form, 승률 $winRate%입니다. 실점/실패 패턴과 개인 기록이 함께 떨어지는 구간을 먼저 점검하세요.';
  }

  @override
  String get averageComparisonProfileMissingTitle => '나이/경력 정보를 입력해 주세요';

  @override
  String get averageComparisonProfileMissingMessage =>
      '현재는 판단 기준(나이/종목 경력)이 없어 평균 비교 통계를 보여드릴 수 없어요. 프로필에서 생년월일과 종목 시작일을 입력해 주세요.';

  @override
  String get averageComparisonOpenProfileAction => '프로필 입력하기';

  @override
  String get averageComparisonTitle => '평균 비교';

  @override
  String get averageComparisonReferenceAction => '기준 출처';

  @override
  String get averageComparisonHiddenMessage => '나이/경력 미입력으로 평균 비교는 숨김 상태입니다.';

  @override
  String get averageComparisonHeightLabel => '키';

  @override
  String get averageComparisonWeightLabel => '몸무게';

  @override
  String get averageComparisonNotSet => '미입력';

  @override
  String get averageComparisonHiddenValue => '숨김';

  @override
  String get averageComparisonUnavailableValue => '비교 불가';

  @override
  String get averageComparisonHiddenGap => '비교 숨김';

  @override
  String averageComparisonGapValue(Object gap) {
    return '$gap 평균대비';
  }

  @override
  String averageComparisonConditioningPerSessionLabel(Object metric) {
    return '$metric/세션';
  }

  @override
  String get averageComparisonFootballOnlyTitle => '축구 평균 비교는 숨겼어요';

  @override
  String get averageComparisonFootballOnlyMessage =>
      '이 평균 비교는 축구 저글링 기준을 사용하므로 현재 종목에서는 표시하지 않습니다.';

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
  String get sport => '종목';

  @override
  String get sportFootball => '축구';

  @override
  String get sportBaseball => '야구';

  @override
  String get sportBasketball => '농구';

  @override
  String get sportTennis => '테니스';

  @override
  String get footballGoalDribbling => '드리블';

  @override
  String get footballGoalPassingAccuracy => '패스 정확도';

  @override
  String get footballGoalShooting => '슈팅';

  @override
  String get footballGoalFitness => '체력';

  @override
  String get footballGoalDefensivePositioning => '수비 위치 선정';

  @override
  String get footballGoalFirstTouch => '퍼스트 터치';

  @override
  String get baseballProgramThrowing => '송구';

  @override
  String get baseballProgramBatting => '타격';

  @override
  String get baseballProgramFielding => '수비';

  @override
  String get baseballProgramBaseRunning => '주루';

  @override
  String get baseballProgramConditioning => '컨디셔닝';

  @override
  String get baseballProgramRecovery => '회복';

  @override
  String get baseballGoalThrowingAccuracy => '송구 정확도';

  @override
  String get baseballGoalBattingContact => '타격 컨택';

  @override
  String get baseballGoalFieldingGlove => '수비 글러브';

  @override
  String get baseballGoalBaseRunning => '주루 판단';

  @override
  String get baseballGoalReactionSpeed => '반응 속도';

  @override
  String get baseballGoalGameAwareness => '경기 이해';

  @override
  String get basketballProgramBallHandling => '볼 핸들링';

  @override
  String get basketballProgramShooting => '슈팅';

  @override
  String get basketballProgramPassing => '패스';

  @override
  String get basketballProgramDefense => '수비';

  @override
  String get basketballProgramConditioning => '컨디셔닝';

  @override
  String get basketballProgramRecovery => '회복';

  @override
  String get basketballGoalBallHandling => '볼 핸들링';

  @override
  String get basketballGoalShootingForm => '슈팅 폼';

  @override
  String get basketballGoalPassingChoices => '패스 선택';

  @override
  String get basketballGoalDefensiveFootwork => '수비 스텝';

  @override
  String get basketballGoalRebounding => '리바운드';

  @override
  String get basketballGoalFitness => '체력';

  @override
  String get tennisProgramStroke => '스트로크';

  @override
  String get tennisProgramServe => '서브';

  @override
  String get tennisProgramFootwork => '풋워크';

  @override
  String get tennisProgramMatchPlay => '매치 플레이';

  @override
  String get tennisProgramConditioning => '컨디셔닝';

  @override
  String get tennisProgramRecovery => '회복';

  @override
  String get tennisGoalServeConsistency => '서브 안정성';

  @override
  String get tennisGoalForehand => '포핸드';

  @override
  String get tennisGoalBackhand => '백핸드';

  @override
  String get tennisGoalFootwork => '풋워크';

  @override
  String get tennisGoalRallyConsistency => '랠리 지속';

  @override
  String get tennisGoalMatchStrategy => '경기 전략';

  @override
  String get baseballConditioningPrimary => '스프린트';

  @override
  String get baseballConditioningSecondary => '캐치볼';

  @override
  String get baseballConditioningDetailTitle => '캐치볼 세부 기록';

  @override
  String get baseballConditioningDetailShortThrow => '짧은 송구';

  @override
  String get baseballConditioningDetailLongThrow => '긴 송구';

  @override
  String get baseballConditioningDetailGrounder => '땅볼 처리';

  @override
  String get baseballConditioningDetailFlyBall => '플라이 처리';

  @override
  String get baseballConditioningDetailTransfer => '빠른 송구 전환';

  @override
  String get baseballConditioningDetailCore => '코어 밸런스';

  @override
  String get basketballConditioningPrimary => '셔틀런';

  @override
  String get basketballConditioningSecondary => '볼 핸들링';

  @override
  String get basketballConditioningDetailTitle => '볼 핸들링 세부 기록';

  @override
  String get basketballConditioningDetailRightHand => '오른손';

  @override
  String get basketballConditioningDetailLeftHand => '왼손';

  @override
  String get basketballConditioningDetailCrossover => '크로스오버';

  @override
  String get basketballConditioningDetailChangePace => '속도 변화';

  @override
  String get basketballConditioningDetailShootingPocket => '슈팅 포켓';

  @override
  String get basketballConditioningDetailPressure => '압박 상황';

  @override
  String get tennisConditioningPrimary => '풋워크';

  @override
  String get tennisConditioningSecondary => '벽치기';

  @override
  String get tennisConditioningDetailTitle => '벽치기 세부 기록';

  @override
  String get tennisConditioningDetailForehand => '포핸드';

  @override
  String get tennisConditioningDetailBackhand => '백핸드';

  @override
  String get tennisConditioningDetailServeToss => '서브 토스';

  @override
  String get tennisConditioningDetailVolley => '발리';

  @override
  String get tennisConditioningDetailApproach => '어프로치';

  @override
  String get tennisConditioningDetailRecovery => '리커버리 스텝';

  @override
  String sportConditioningRecordTitle(String label) {
    return '$label 기록';
  }

  @override
  String sportConditioningMinutesLabel(String label) {
    return '$label 시간(분)';
  }

  @override
  String sportConditioningCountLabel(String label) {
    return '$label 횟수';
  }

  @override
  String sportConditioningMemoLabel(String label) {
    return '$label 메모';
  }

  @override
  String sportConditioningMemoHint(String label) {
    return '$label을 하면서 느낀 점을 적어보세요.';
  }

  @override
  String sportConditioningEmpty(String primary, String secondary) {
    return '$primary/$secondary 기록 없음';
  }

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
  String get languageJapanese => '일본어';

  @override
  String get settings => '설정';

  @override
  String get settingsGeneralSection => '일반 설정';

  @override
  String get settingsNewsFilterTitle => '뉴스 필터';

  @override
  String get settingsNewsBlockedDomainsTitle => '광고 도메인 차단 목록';

  @override
  String settingsNewsBlockedDomainsCount(int count) {
    return '$count개 항목';
  }

  @override
  String get settingsNewsBlockedDomainsManageTitle => '광고 도메인 차단 목록 관리';

  @override
  String get settingsNewsBlockedDomainsExample =>
      '예시: example.com (프로토콜/경로 없이 도메인만 입력)';

  @override
  String get settingsApiUsageTitle => '앱에서 사용하는 API';

  @override
  String get settingsApiUsageSubtitle =>
      '이 앱은 아래의 공개 API 또는 사용자 동의 기반 API를 사용합니다. 제공처별 할당량은 바뀔 수 있어 가능한 곳은 캐시하고 백그라운드 새로고침을 제한합니다.';

  @override
  String get settingsApiTrafficLabel => '트래픽';

  @override
  String get settingsApiLegalLabel => '합법적 사용';

  @override
  String get settingsApiOpenMeteoProvider =>
      'Open-Meteo 날씨, 대기질, 지오코딩, 과거 날씨 API';

  @override
  String get settingsApiOpenMeteoTraffic =>
      '공개 무료 서비스이며 공정 사용이 전제됩니다. 날씨 화면 요청은 캐시하고 필요할 때만 갱신합니다.';

  @override
  String get settingsApiOpenMeteoLegal =>
      'Open-Meteo 공개 API 약관에 따라 사용하며 날씨 기능에서 출처를 노출합니다.';

  @override
  String get settingsApiKoreaPublicProvider => '국내 공공데이터 날씨 및 대기질 API';

  @override
  String get settingsApiKoreaPublicTraffic =>
      '공공데이터포털에서 발급된 서비스 키와 기관별 제한량을 따릅니다.';

  @override
  String get settingsApiKoreaPublicLegal =>
      '발급된 서비스 키와 공공데이터포털 이용 조건에 맞춰 사용합니다.';

  @override
  String get settingsApiKakaoProvider => 'Kakao Local 검색/지오코딩 API';

  @override
  String get settingsApiKakaoTraffic =>
      '등록된 Kakao Developers 앱과 REST API 키의 할당량을 따릅니다.';

  @override
  String get settingsApiKakaoLegal =>
      '앱 키와 플랫폼 설정이 허용하는 범위에서 Kakao Developers 약관에 따라 사용합니다.';

  @override
  String get settingsApiFootballProvider => '축구 일정, 순위, 월드컵 출처 페이지/API';

  @override
  String get settingsApiFootballTraffic =>
      '읽기 전용 요청은 캐시하고 보수적으로 재시도합니다. 이용 가능 여부는 출처 서비스 상태를 따릅니다.';

  @override
  String get settingsApiFootballLegal =>
      '공개 경기 일정/순위 데이터를 앱 표시용으로 사용하고 제공되는 경우 링크와 출처를 함께 표시합니다.';

  @override
  String get settingsApiNewsProvider => 'RSS 피드 및 뉴스 가져오기 보조 API';

  @override
  String get settingsApiNewsTraffic => 'RSS/뉴스 응답은 반복 트래픽을 줄이기 위해 캐시하고 필터링합니다.';

  @override
  String get settingsApiNewsLegal =>
      '기사 전문을 재게시하지 않고 기사 메타데이터와 원문 발행사 링크를 보여줍니다.';

  @override
  String get settingsApiGoogleProvider => 'Google Drive 및 Firebase 서비스';

  @override
  String get settingsApiGoogleTraffic =>
      '연결된 Google Cloud 프로젝트와 사용자 Drive 할당량을 따릅니다.';

  @override
  String get settingsApiGoogleLegal =>
      '사용자 동의를 받고 사용자 자신의 백업 파일에 필요한 앱 백업 범위로 접근합니다.';

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
  String get backupToDrive => '데이터 백업하기';

  @override
  String get restoreFromDrive => '최근 데이터 가져오기';

  @override
  String get restorePreviousBackup => '이전 백업 가져오기';

  @override
  String get restorePreviousBackupInfo =>
      '이전 백업은 최근 가져오기를 되돌리거나 예전 상태를 확인할 때만 사용하는 복구 기능입니다. 실행하기 전에 현재 데이터가 이전 백업으로 교체되는 점을 확인해 주세요.';

  @override
  String get backupConfirm => 'Google Drive에 새 백업을 만들까요?';

  @override
  String get restoreConfirm => 'Google Drive의 최신 데이터를 가져올까요? 현재 데이터가 교체됩니다.';

  @override
  String get restorePreviousConfirm =>
      'Google Drive의 이전 백업을 가져올까요? 현재 데이터가 교체됩니다.';

  @override
  String get backupSuccess => '백업이 완료되었습니다.';

  @override
  String get backupFailed => '백업에 실패했어요. 다시 시도해 주세요.';

  @override
  String get restoreSuccess => '데이터를 가져왔어요.';

  @override
  String get restoreFailed => '데이터 가져오기에 실패했어요. 다시 시도해 주세요.';

  @override
  String get restorePreviousSuccess => '이전 백업을 가져왔어요.';

  @override
  String get restorePreviousFailed => '이전 백업 가져오기에 실패했어요. 다시 시도해 주세요.';

  @override
  String get backupInProgress => '백업 중...';

  @override
  String get restoreInProgress => '데이터 가져오는 중...';

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
  String get restoreLocalBackup => '최근 가져오기 취소';

  @override
  String get restoreLocalConfirm =>
      '이 기기에서 마지막 가져오기로 바뀐 내용을 직전 상태로 되돌릴까요? 현재 데이터가 교체됩니다.';

  @override
  String get restoreLocalSuccess => '최근 가져오기를 취소했어요.';

  @override
  String get restoreLocalFailed => '최근 가져오기 취소에 실패했어요. 다시 시도해 주세요.';

  @override
  String get localBackup => '로컬 안전 백업';

  @override
  String get driveBackupLockedAccountChanged =>
      'Google 계정이 바뀌었어요. 이 계정으로 백업하기 전에 이 기기에서 어떤 데이터로 시작할지 선택해야 해요.';

  @override
  String get driveAccountSwitchImportAction => '이 계정 백업 가져오기';

  @override
  String get driveAccountSwitchStartEmptyAction => '이 계정으로 새로 시작';

  @override
  String get driveAccountSwitchImportTitle => '연결된 계정의 데이터를 사용할까요?';

  @override
  String get driveAccountSwitchImportBody =>
      '현재 연결된 Google 계정이 저장된 선수 백업 계정과 달라요. 먼저 이 계정의 최신 Drive 백업을 가져옵니다. 로컬 안전 백업을 남긴 뒤 현재 기기 데이터가 교체됩니다.';

  @override
  String get driveAccountSwitchStartEmptyTitle => '새 선수 계정으로 시작할까요?';

  @override
  String get driveAccountSwitchStartEmptyBody =>
      '이 기기의 선수 데이터를 비우고 현재 Google 계정을 선수 백업 계정으로 연결합니다. 이 기기에서 되돌릴 수 있도록 로컬 안전 백업은 남겨둡니다.';

  @override
  String get driveAccountSwitchImportSuccess => '이 계정의 백업을 가져왔어요.';

  @override
  String get driveAccountSwitchStartEmptySuccess => '이 계정의 빈 선수 데이터로 시작했어요.';

  @override
  String get driveAccountSwitchImportFailed =>
      '이 계정의 백업 가져오기에 실패했어요. 다시 시도해 주세요.';

  @override
  String get driveAccountSwitchStartEmptyFailed =>
      '이 계정으로 새로 시작하지 못했어요. 다시 시도해 주세요.';

  @override
  String get driveAccountSwitchNoRemoteBackup =>
      '연결된 계정에서 Drive 백업을 찾지 못했어요. 이 계정으로 새로 시작하거나 저장된 선수 계정으로 다시 연결해 주세요.';

  @override
  String get backupVersionUnsupported =>
      '이 백업은 더 새로운 앱에서 만들어져 현재 버전으로는 가져올 수 없어요. 앱을 업데이트한 뒤 다시 시도해 주세요.';

  @override
  String get backupPayloadInvalid =>
      '백업 데이터 형식을 확인할 수 없어 가져오기를 중단했어요. 다른 백업으로 다시 시도해 주세요.';

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
  String get liftingMinutesLabel => '리프팅 시간(분)';

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
  String get notificationSettingsAction => '설정';

  @override
  String get notificationSettingsTitle => '알림 설정';

  @override
  String get notificationSettingsCloseTooltip => '알림 설정 닫기';

  @override
  String get notificationRefreshAction => '새로고침';

  @override
  String get notificationMuteStatusPaused => '현재 알림이 일시중지되어 있어요.';

  @override
  String get notificationMuteControlTitle => '반복 알림 제어';

  @override
  String get notificationMuteControlSubtitle => '알림을 잠시 멈추거나 다시 켤 수 있어요.';

  @override
  String get notificationMute8HoursAction => '8시간 끄기';

  @override
  String get notificationResumeAction => '다시 켜기';

  @override
  String get notificationAllSettingsTitle => '전체 알림';

  @override
  String get notificationTrainingPlanVibrationTitle => '훈련 계획 진동 알림';

  @override
  String get notificationXpAlertSettingsTitle => '경험치 알림';

  @override
  String get notificationXpAlertSettingsSubtitle => '경험치를 얻으면 바로 알림을 보냅니다.';

  @override
  String get notificationLevelUpSettingsTitle => '레벨 업 알림';

  @override
  String notificationFamilySectionTitle(int count) {
    return '보호자 동기화 알림 $count개';
  }

  @override
  String get notificationFamilyEmpty => '아직 보호자 동기화 알림이 없어요.';

  @override
  String notificationFixtureSectionTitle(int count) {
    return '경기 일정 알림 $count개';
  }

  @override
  String get notificationFixtureEmpty => '아직 경기 일정 알림이 없어요.';

  @override
  String get notificationFamilySettingsTitle => '보호자 동기화 알림';

  @override
  String get notificationFamilySettingsSubtitle =>
      '선수 기록 또는 보호자 피드백/선물이 동기화되면 알림을 보냅니다.';

  @override
  String get notificationLeagueFixtureSettingsTitle => '좋아하는 팀 경기 알림';

  @override
  String get notificationLeagueFixtureSettingsSubtitle =>
      '선택한 좋아하는 팀의 불러온 경기 일정 전에 알림을 보냅니다.';

  @override
  String get notificationOverviewOnTitle => '폰 알림 활성화';

  @override
  String get notificationOverviewOffTitle => '폰 알림 비활성화';

  @override
  String get notificationOverviewAllOnSubtitle => '기기 알림과 앱 알림이 모두 켜져 있습니다.';

  @override
  String get notificationOverviewAppOffSubtitle =>
      '기기 알림은 켜져 있지만 앱 내 전체 알림은 꺼져 있습니다.';

  @override
  String get notificationOverviewPermissionOffSubtitle =>
      '설정 > 알림에서 이 앱의 알림을 허용해야 실제 알림이 도착합니다.';

  @override
  String get notificationOverviewPausedLabel => '일시중지';

  @override
  String notificationOverviewCountLabel(int count) {
    return '$count개';
  }

  @override
  String get notificationFeedTitle => '알림 피드';

  @override
  String notificationFeedSubtitle(int count) {
    return '$count개 알림을 시간순으로 정리했어요.';
  }

  @override
  String get notificationCategoryTrainingPlan => '훈련';

  @override
  String get notificationCategoryWeather => '날씨';

  @override
  String get notificationCategoryFixture => '경기';

  @override
  String get notificationCategoryXp => '경험치';

  @override
  String get notificationCategoryFamily => '보호자';

  @override
  String notificationCategorySectionTitle(Object category, int count) {
    return '$category $count개';
  }

  @override
  String get notificationFeedEmptyTitle => '표시할 알림이 없어요.';

  @override
  String get notificationFeedEmptySubtitle =>
      '훈련, 날씨, 경기 알림이 생기면 여기에 모아 보여드려요.';

  @override
  String get notificationInactivitySettingsTitle => '기록 공백 리마인드';

  @override
  String get notificationInactivityOnTitle => '기록 공백 리마인드 사용 중';

  @override
  String get notificationInactivityOffTitle => '기록 공백 리마인드 꺼짐';

  @override
  String notificationInactivityOnSubtitle(int days, Object time) {
    return '$days일 동안 기록이 없으면 $time에 알림';
  }

  @override
  String get notificationInactivityOffSubtitle => '켜면 훈련 기록 공백을 알려줍니다.';

  @override
  String notificationLastTrainingLog(Object time) {
    return '마지막 기록: $time';
  }

  @override
  String get notificationInactivityTimeTitle => '기록 리마인드 시간';

  @override
  String notificationInactivityTimeSubtitle(int days, Object time) {
    return '$days일 기준 · $time';
  }

  @override
  String get notificationInactivityThresholdLabel => '기록 공백 기준';

  @override
  String notificationInactivityThresholdDayOption(int value) {
    return '$value일';
  }

  @override
  String get notificationChangeTimeAction => '시간 변경';

  @override
  String get notificationXpFallbackTitle => '경험치 알림';

  @override
  String notificationXpSubtitle(int gainedXp, int totalXp) {
    return '+$gainedXp XP · 누적 $totalXp XP';
  }

  @override
  String get notificationPlanFallbackTitle => '훈련 계획';

  @override
  String get notificationWeatherSettingsTitle => '날씨 알림';

  @override
  String get notificationWeatherSettingsSubtitle =>
      '매일 날씨와 운동 복장을 확인할 수 있게 알려줍니다.';

  @override
  String get notificationWeatherTimeTitle => '날씨 알림 시간';

  @override
  String notificationWeatherTimeSubtitle(Object time) {
    return '매일 $time에 알림';
  }

  @override
  String get notificationNewBadge => 'NEW';

  @override
  String get weatherNotificationChannelName => '날씨 알림';

  @override
  String get weatherNotificationChannelDescription => '매일 날씨와 운동 복장 확인 알림';

  @override
  String get weatherNotificationDailyBody => '오늘 날씨와 운동 복장을 확인해요.';

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
  String get diaryComposerSavePromptTitle => '저장할까요?';

  @override
  String get diaryComposerSavePromptBody => '저장하지 않은 내용이 있어요. 저장 후 닫을까요?';

  @override
  String get diaryComposerDontSave => '저장 안 함';

  @override
  String get diaryNewAction => '새 다이어리';

  @override
  String get diaryNextDayTooltip => '다음 날짜';

  @override
  String get diaryPreviousDayTooltip => '이전 날짜';

  @override
  String get diaryComposeTooltip => '작성';

  @override
  String get diaryEmptyTitle => '아직 만든 다이어리가 없습니다.';

  @override
  String get diaryEmptyBody => '날짜를 골라 첫 페이지를 만들면 다이어리가 시작됩니다.';

  @override
  String get diaryCreateFirstAction => '첫 다이어리 만들기';

  @override
  String get diaryDeleteDialogTitle => '다이어리 삭제';

  @override
  String get diaryDeleteDialogBody => '이 날짜의 다이어리를 삭제할까요?';

  @override
  String get diaryDeletedMessage => '다이어리를 삭제했어요.';

  @override
  String get diaryDeleteRestoredMessage => '삭제를 되돌렸어요.';

  @override
  String get diaryThemeNotebookName => '노트북';

  @override
  String get diaryThemeNotebookDescription => '차분한 종이 질감의 기본 다이어리입니다.';

  @override
  String get diaryThemeDuskName => '노을';

  @override
  String get diaryThemeDuskDescription => '붉은 저녁빛처럼 따뜻한 분위기로 읽습니다.';

  @override
  String get diaryThemeOceanName => '새벽 바다';

  @override
  String get diaryThemeOceanDescription => '푸른 잉크처럼 또렷하고 서늘한 페이지입니다.';

  @override
  String get diaryVoiceInputTooltip => '음성 입력';

  @override
  String get diaryVoiceInputUnavailable => '이 기기에서는 음성 입력을 사용할 수 없어요.';

  @override
  String get diaryComposerTitle => '오늘의 일기 구성하기';

  @override
  String get diaryComposerDescription =>
      '아래 기록에서 스티커로 붙일 항목을 고르고, 본문은 직접 간단히 작성하세요.';

  @override
  String get diaryEmptyHint => '핵심만 간단히 기록해보세요.';

  @override
  String get diaryLastSavedPrefix => '마지막 저장';

  @override
  String get diarySavedMessage => '다이어리를 저장했어요.';

  @override
  String get diaryTitlePlaceholder => '제목을 입력해 주세요';

  @override
  String get diaryTitleLabel => '제목';

  @override
  String get diaryTitleHint => '예: 비 온 날 끝까지 이어진 패스 감각';

  @override
  String get diaryStoryLabel => '본문';

  @override
  String get diaryStoryPlaceholder => '본문을 입력해 주세요';

  @override
  String get diarySaveEmptyMessage =>
      '저장할 내용이 없어요. 제목, 본문, 스티커, 사진 중 하나 이상을 추가해 주세요.';

  @override
  String get diaryClearConfirmTitle => '정말 비울까요?';

  @override
  String get diaryClearConfirmBody => '작성한 제목, 본문, 선택한 스티커, 사진을 모두 비웁니다.';

  @override
  String get diaryClearAction => '비우기';

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
  String get homeWeatherTodayTitle => '오늘 날씨';

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
  String get entryWeatherLoading => '날씨 불러오는 중...';

  @override
  String get entryWeatherHomeMissing => '홈에서 날씨를 먼저 불러오세요.';

  @override
  String get entryWeatherUseLocationTooltip => '현재 위치 날씨';

  @override
  String get entryWeatherLocationServiceTitle => '위치 서비스 필요';

  @override
  String get entryWeatherLocationServiceBody => '현재 위치 날씨를 불러오려면 위치 서비스를 켜주세요.';

  @override
  String get entryWeatherPermissionTitle => '위치 권한 필요';

  @override
  String get entryWeatherPermissionBody => '위치 권한이 꺼져 있어요. 설정에서 권한을 허용해주세요.';

  @override
  String get entryWeatherPermissionRequired => '위치 권한이 필요합니다.';

  @override
  String get entryWeatherLoadFailed => '날씨를 불러오지 못했어요.';

  @override
  String get entryWeatherOpenSettings => '설정 열기';

  @override
  String get homeWeatherRetryTitle => '날씨 다시 시도';

  @override
  String get homeWeatherRetrySubtitle => '눌러서 불러오기';

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
  String get homeWeatherOutfitActionLabel => '복장';

  @override
  String get homeWeatherTomorrowActionLabel => '내일';

  @override
  String get homeWeatherWeeklyActionLabel => '주간';

  @override
  String get homeWeatherTomorrowNavSubtitle => '내일 예보와 추천 복장을 따로 확인하세요.';

  @override
  String get homeWeatherWeeklyNavSubtitle => '7일 예보와 대기질 흐름을 따로 확인하세요.';

  @override
  String get homeWeatherMorningLabel => '아침';

  @override
  String get homeWeatherEveningLabel => '저녁';

  @override
  String get homeWeatherCacheHint => '최근 가져온 데이터를 10분 동안 다시 사용합니다.';

  @override
  String get homeWeatherDailyHighLow => '최고/최저';

  @override
  String get homeWeatherTomorrowFallback => '내일 예보가 아직 없어요.';

  @override
  String get homeWeatherWeeklyFallback => '주간 예보가 아직 없어요.';

  @override
  String get homeWeatherTomorrowOutfitTitle => '내일 추천 복장';

  @override
  String get homeWeatherTomorrowOutfitFallback => '내일 복장 추천을 준비 중이에요.';

  @override
  String get homeWeatherTemperatureRange => '최고/최저';

  @override
  String get homeWeatherFeelsLike => '체감 온도';

  @override
  String get homeWeatherHumidity => '습도';

  @override
  String get homeWeatherPrecipitation => '강수량';

  @override
  String get homeWeatherPrecipitationProbability => '강수확률';

  @override
  String get weatherPrecipitationNone => '비가 안 와요';

  @override
  String get weatherPrecipitationTrace => '조금 와요';

  @override
  String get weatherPrecipitationLight => '가볍게 와요';

  @override
  String get weatherPrecipitationModerate => '꽤 와요';

  @override
  String get weatherPrecipitationHeavy => '많이 와요';

  @override
  String get weatherPrecipitationVeryHeavy => '아주 많이 와요';

  @override
  String get homeWeatherHourlyPrecipitation => '시간별 비 타임라인';

  @override
  String get homeWeatherHourlyTemperature => '시간대별 기온';

  @override
  String get homeWeatherWindSpeed => '풍속';

  @override
  String get homeWeatherUvIndex => '자외선';

  @override
  String get homeWeatherOutfitTitle => '오늘의 운동 복장';

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
  String get homeWeatherOutfitLayersLabel => '상의 조합';

  @override
  String get homeWeatherOutfitOuterLabel => '겉옷';

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
      '날씨대별 추천 복장을 상의 조합, 겉옷, 하의, 준비물까지 자세히 확인하세요.';

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
  String get homeWeatherAirQualityForecastMissingReason =>
      '대기질 예보가 제공되지 않는 지역/시간대입니다.';

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
      '숨쉬기가 예민하면 오래 밖에 있거나 힘든 훈련은 줄여 주세요.';

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
  String get homeWeatherComparedYesterday => '어제 대비';

  @override
  String get homeWeatherPm10 => '미세먼지';

  @override
  String get homeWeatherPm25 => '초미세먼지';

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
  String get homeWeatherStatusSensitive => '숨쉬기 예민하면 주의';

  @override
  String get homeWeatherStatusUnhealthy => '나쁨';

  @override
  String get homeWeatherStatusVeryUnhealthy => '매우 나쁨';

  @override
  String get homeWeatherStatusHazardous => '위험';

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
  String get diaryStickerFortune => '오늘의 운세';

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
  String get diaryStickerParentFeedback => '보호자 피드백';

  @override
  String get diaryInjuryNoDetails => '남긴 부상 메모가 없어요.';

  @override
  String get diaryInjuryRehab => '재활';

  @override
  String get diaryInjuryStorySentence => '통증이 있었던 장면과 회복이 필요한 부분을 짧게 남겨 보세요.';

  @override
  String get diaryQuizStorySentence => '퀴즈를 풀며 기억에 남은 문제나 다시 보고 싶은 개념을 적어 보세요.';

  @override
  String diaryParentFeedbackStorySentence(String message) {
    return '보호자 피드백: $message';
  }

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
  String get diaryUnknownSource => '출처 없음';

  @override
  String get diaryLocationUnset => '장소 미기록';

  @override
  String get diaryLocationNotLogged => '장소 기록 없음';

  @override
  String get diaryFundamentalsFallback => '기본기';

  @override
  String diaryUpdatedAt(String date) {
    return '업데이트 $date';
  }

  @override
  String get diaryMatchOpponentUnknown => '상대 팀 미기록';

  @override
  String diaryMatchOpponentLabel(String opponent) {
    return '$opponent전';
  }

  @override
  String diaryMatchScoreLabel(String score) {
    return '스코어 $score';
  }

  @override
  String diaryMatchGoalsLabel(int count) {
    return '개인 득점 $count';
  }

  @override
  String diaryMatchAssistsLabel(int count) {
    return '도움 $count';
  }

  @override
  String diaryMatchMinutesPlayed(String minutes) {
    return '출전 $minutes';
  }

  @override
  String diaryMatchPersonalStats(int goals, int assists) {
    return '$goals골 $assists도움';
  }

  @override
  String diaryTotalRiceBowls(String count) {
    return '총 $count공기';
  }

  @override
  String diaryCompletedMeals(int count) {
    return '$count끼 기록';
  }

  @override
  String diaryReps(int count) {
    return '$count회';
  }

  @override
  String diaryTotalReps(int count) {
    return '총 $count회';
  }

  @override
  String diaryLiftingReps(int count) {
    return '리프팅 $count회';
  }

  @override
  String diaryJumpRopeReps(int count) {
    return '줄넘기 $count회';
  }

  @override
  String diaryJumpRopeMinutes(String minutes) {
    return '줄넘기 $minutes';
  }

  @override
  String diaryJumpRopeCombined(int count, String minutes) {
    return '줄넘기 $minutes/$count회';
  }

  @override
  String diaryConditioningSummary(
      int liftingCount, int jumpCount, String jumpMinutes) {
    return '리프팅 $liftingCount회 · 줄넘기 $jumpMinutes/$jumpCount회';
  }

  @override
  String diaryStoryPromptFromSeed(String title) {
    return '$title부터 시작해서 오늘 남기고 싶은 장면을 이어 적어 보세요. 해야 했던 일과 실제로 한 일, 기분 변화를 자연스럽게 붙여 써도 좋아요.';
  }

  @override
  String diaryStoryPromptDefault(String place, String focus) {
    return '오늘 $place에서 있었던 일을 내 말로 적어 보세요. $focus 쪽에서 어떤 장면이 가장 오래 남았는지, 무엇이 즐거웠고 무엇이 아쉬웠는지 자유롭게 써도 좋아요.';
  }

  @override
  String diaryPlanStorySentence(String title) {
    return '$title 할 일을 먼저 떠올리며, 왜 이걸 오늘 다이어리에 넣고 싶은지 적어 본다.';
  }

  @override
  String diaryPlanNoteTitle(String category) {
    return '$category 메모';
  }

  @override
  String diaryPlanDurationLabel(String duration) {
    return '$duration 계획';
  }

  @override
  String get diaryPinnedPlanTooltip => '계획 고정';

  @override
  String diaryTrainingTodoTitle(String label) {
    return '훈련 · $label';
  }

  @override
  String diaryTrainingSummaryTitle(String label) {
    return '$label 훈련 요약';
  }

  @override
  String get diaryFortunePinSummary => '오늘 기록에 남은 운세를 다이어리 스티커로 붙여둘 수 있어요.';

  @override
  String get diaryFortuneStorySentence => '오늘 운세에서 기억하고 싶은 장면이나 응원 한 줄을 적어 본다.';

  @override
  String get diaryFortuneNoteTitle => '오늘 운세 메모';

  @override
  String get diaryMatchTodoTitleNoOpponent => '시합';

  @override
  String diaryMatchTodoTitleWithOpponent(String opponent) {
    return '시합 · $opponent전';
  }

  @override
  String get diaryMatchStorySentence =>
      '시합 흐름을 한 장면씩 떠올리며 좋았던 선택과 아쉬운 선택을 함께 적어 본다.';

  @override
  String get diaryMatchFlowTitle => '시합 흐름';

  @override
  String get diaryMatchSectionBodyDefault => '시합에서 가장 크게 남은 흐름을 적는다.';

  @override
  String get diaryBoardStickerFallbackSummary => '이 보드에서 기록한 움직임과 아이디어';

  @override
  String diaryBoardNotePrefix(String memo) {
    return '보드 메모: $memo';
  }

  @override
  String diaryBoardTodoTitle(String title) {
    return '훈련보드 · $title';
  }

  @override
  String get diaryBoardStorySentence => '이 보드에서 남기고 싶은 움직임과 아이디어를 적는다.';

  @override
  String get diaryBoardFallbackSummary => '전술 아이디어를 일기로 옮길 수 있어요.';

  @override
  String diaryBoardNoteTitle(String title) {
    return '$title 메모';
  }

  @override
  String get diaryLiftingStorySentence => '리프팅 반복이 오늘 감각을 어떻게 붙잡아 줬는지 적어 본다.';

  @override
  String get diaryLiftingNoteTitle => '리프팅 메모';

  @override
  String get diaryLiftingSectionBody => '반복 수와 함께 발 감각이 안정된 순간을 남긴다.';

  @override
  String get diaryJumpRopeStorySentence => '줄넘기로 몸이 깨어난 순간과 호흡 변화를 적어 본다.';

  @override
  String get diaryJumpRopeNoteTitle => '줄넘기 메모';

  @override
  String get diaryJumpRopeSectionBody => '횟수와 시간, 몸이 가벼워진 타이밍을 함께 남긴다.';

  @override
  String get diaryWeatherStorySentence =>
      '그날 날씨가 훈련 흐름과 몸 상태에 어떤 영향을 줬는지 적어 보세요.';

  @override
  String diaryNewsTodoTitle(String title) {
    return '소식 · $title';
  }

  @override
  String diaryNewsStorySentence(String title) {
    return '$title 기사를 읽고 기억하고 싶은 포인트를 한 줄로 남긴다.';
  }

  @override
  String get diaryTodayNewsTitle => '오늘 본 소식';

  @override
  String diaryNewsSectionBody(String source, String title) {
    return '$source 기사: $title';
  }

  @override
  String get quizWrongAnswerTimeout => '시간 초과';

  @override
  String get quizWrongAnswerRevealed => '정답 보기';

  @override
  String get quizWrongAnswerSkipped => '답을 고르지 않음';

  @override
  String get quizWrongAnswerEmpty => '입력 없음';

  @override
  String get quizShortAnswerHintAction => '힌트 보기';

  @override
  String get quizRevealAnswerAction => '정답 보기';

  @override
  String get quizShortAnswerHintUnavailable => '아직 준비된 힌트가 없어요.';

  @override
  String quizShortAnswerHintStartsWith(Object first, Object length) {
    return '첫 글자는 \"$first\"이고 총 $length글자예요.';
  }

  @override
  String quizShortAnswerHintNumber(Object first, Object length) {
    return '숫자 정답이며 첫 숫자는 $first, 총 $length자리예요.';
  }

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
  String get diarySelectedRecordStickersHint =>
      '손잡이를 드래그해서 순서를 바꾸고, 삭제 버튼으로 스티커를 뺄 수 있어요.';

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
  String get diaryRecordStickerPin => '스티커 추가';

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
  String get mealXpFull => '세 끼 완료 +8 XP';

  @override
  String get mealXpFullBonus => '세 끼 완료 + 공기밥 5공기 이상 +10 XP';

  @override
  String get mealXpPartial => '두 끼 이상 +3 XP';

  @override
  String get mealXpNeutral => '한 끼 이하 기록은 보너스 없음';

  @override
  String get homeMealCoachTitle => '식사 코치';

  @override
  String get homeMealCoachRecordAction => '식사';

  @override
  String get homeParentWelcomeMessage => '보호자 모드입니다. 기록 확인과 피드백만 관리해요.';

  @override
  String get homeParentWelcomeAction => '기록 보기';

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
  String mealSavedWithXpFeedback(int count) {
    return '식사 기록 저장 +$count XP';
  }

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
  String get fortuneDialogSubtitle => '생일과 이름으로 고른 오늘의 가벼운 운세예요.';

  @override
  String get fortuneDialogOverviewTitle => '운세 보기';

  @override
  String get fortuneDialogOverallFortuneLabel => '오늘 운세';

  @override
  String get fortuneDialogLuckyInfoLabel => '재미 포인트';

  @override
  String fortuneDialogOverallFortuneCount(int count) {
    return '$count줄';
  }

  @override
  String fortuneDialogLuckyInfoCount(int count) {
    return '$count개';
  }

  @override
  String get fortuneDialogLuckyInfoTitle => '재미 포인트';

  @override
  String get fortuneDialogPoolSizeLabel => '운세 조합';

  @override
  String fortuneDialogPoolSizeCount(String count) {
    return '$count개';
  }

  @override
  String get fortuneDialogRecommendedProgramTitle => '추천 훈련';

  @override
  String get fortuneDialogRecommendationTitle => '플레이 코멘트';

  @override
  String get fortuneDialogEncouragement => '오늘도 재미있는 작은 장면을 챙겨봐요.';

  @override
  String get fortuneDialogAction => '좋아요';

  @override
  String get fortuneDatabaseViewAction => '전체 데이터 보기';

  @override
  String get fortuneDatabaseTitle => '전체 운세 데이터 베이스';

  @override
  String get fortuneDatabaseSubtitle =>
      '오늘 운세를 만들 때 쓰는 문장 조각과 재미 포인트를 모두 모아봤어요.';

  @override
  String get fortuneDatabaseCloseAction => '닫기';

  @override
  String get fortuneDatabaseSectionBirthCodes => '명리 코드';

  @override
  String get fortuneDatabaseSectionDayMoods => '하루 분위기';

  @override
  String get fortuneDatabaseSectionDailyEvents => '오늘 일어날 수 있는 일';

  @override
  String get fortuneDatabaseSectionActionCues => '가볍게 해볼 일';

  @override
  String get fortuneDatabaseSectionNameRhythms => '이름 리듬';

  @override
  String get fortuneDatabaseSectionAdvice => '오늘의 한마디';

  @override
  String get fortuneDatabaseSectionColorTones => '컬러 톤';

  @override
  String get fortuneDatabaseSectionColorBases => '컬러';

  @override
  String get fortuneDatabaseSectionTimePeriods => '시간 분위기';

  @override
  String get fortuneDatabaseSectionTimeWindows => '시간대';

  @override
  String get fortuneDatabaseSectionSceneModifiers => '장소 분위기';

  @override
  String get fortuneDatabaseSectionSceneBases => '장소와 장면';

  @override
  String get fortuneDatabaseSectionCueOpenings => '루틴 시작점';

  @override
  String get fortuneDatabaseSectionCueActions => '작은 루틴';

  @override
  String get entryFortuneOpenFailed => '운세 화면을 여는 중 문제가 생겼어요.';

  @override
  String get profileBirthTimeTitle => '출생 시간';

  @override
  String get profileBirthTimeSelectDateFirst => '생년월일 선택 후 입력';

  @override
  String get fortuneGeneratedUnknownPlayerName => '선수';

  @override
  String get fortuneGeneratedBirthNotSet => '생일 정보 없음';

  @override
  String fortuneGeneratedBirthFrame(
      String yearPillar, String monthPillar, String dayPillar) {
    return '생일 코드 $yearPillar/$monthPillar/$dayPillar';
  }

  @override
  String fortuneGeneratedBirthFrameWithTime(String yearPillar,
      String monthPillar, String dayPillar, String hourPillar) {
    return '생일 코드 $yearPillar/$monthPillar/$dayPillar/$hourPillar';
  }

  @override
  String fortuneGeneratedDailyLineOne(String name, String elementFlow) {
    return '$name, 오늘은 $elementFlow 분위기가 먼저 찾아와요.';
  }

  @override
  String fortuneGeneratedDailyLineTwo(
      String fortuneTheme, String trainingTone) {
    return '$fortuneTheme $trainingTone';
  }

  @override
  String fortuneGeneratedDailyLineThree(String nameElement, String playAdvice) {
    return '$nameElement 흐름이라 $playAdvice';
  }

  @override
  String get fortuneGeneratedLuckyInfoHeader => '[재미 포인트]';

  @override
  String fortuneGeneratedLuckyInfoLine(int number, String color) {
    return '재미 포인트: 숫자 $number, 컬러 $color.';
  }

  @override
  String get fortuneRecommendedRecoveryProgram => '회복 볼터치';

  @override
  String get fortuneRecommendedLightFirstTouchProgram => '가벼운 퍼스트 터치';

  @override
  String get fortuneRecommendedForwardPassProgram => '전진 패스 연계';

  @override
  String get fortuneRecommendedCoreTechniqueProgram => '기본기 루틴';

  @override
  String fortuneRecommendationInjury(String program) {
    return '통증 체크를 우선하고, 다음 훈련은 $program 중심으로 강도를 낮춰보세요.';
  }

  @override
  String fortuneRecommendationStrongFlow(String program) {
    return '오늘 리듬이 좋아요. 다음 훈련은 $program로 속도와 선택 연결을 이어가세요.';
  }

  @override
  String fortuneRecommendationDefault(String program) {
    return '다음 훈련은 $program로 리듬을 정리하며 정확도를 끌어올려보세요.';
  }

  @override
  String get fortuneSajuHeavenlyStems => '갑|을|병|정|무|기|경|신|임|계';

  @override
  String get fortuneSajuEarthlyBranches => '자|축|인|묘|진|사|오|미|신|유|술|해';

  @override
  String get fortuneSajuElementFlows =>
      '느긋한 시작|반가운 연락|작은 행운|정리되는 마음|가벼운 설렘|선명한 선택|따뜻한 만남|기분 좋은 집중|예상 밖의 도움|차분한 회복|새로운 아이디어|숨은 기회|말끔한 정리|빠른 눈치|부드러운 타이밍|작은 용기|좋은 소식의 기미|편안한 속도|흐름이 풀리는 느낌|나에게 맞는 리듬|먼저 웃는 분위기|작은 변화의 바람|기다리던 답|은근한 자신감';

  @override
  String get fortuneSajuFortuneThemes =>
      '아침에 뜻밖의 웃음이 생길 수 있어요.|미뤄둔 일이 생각보다 쉽게 풀릴 수 있어요.|기다리던 답장이 조금 늦게라도 올 수 있어요.|낯선 제안이 의외로 마음에 들 수 있어요.|작은 지출 대신 기분 좋은 발견이 있을 수 있어요.|복잡했던 생각이 한 문장으로 정리될 수 있어요.|가까운 사람과 짧은 대화가 길게 남을 수 있어요.|평소 지나치던 곳에서 좋은 힌트를 볼 수 있어요.|오후에 집중력이 갑자기 살아날 수 있어요.|누군가의 한마디가 자신감을 건드릴 수 있어요.|계획이 살짝 바뀌어도 더 괜찮은 길이 열릴 수 있어요.|잊고 있던 약속이나 물건이 떠오를 수 있어요.|정리하다가 반가운 기억을 찾을 수 있어요.|괜히 끌리는 색이나 물건이 하루 분위기를 바꿀 수 있어요.|기다림이 짧아지고 선택이 빨라질 수 있어요.|작은 칭찬을 받거나 먼저 건네기 좋은 날이에요.|새로운 정보가 딱 필요한 순간에 들어올 수 있어요.|혼자만의 시간이 예상보다 달콤할 수 있어요.|가벼운 산책이나 이동 중에 생각이 풀릴 수 있어요.|헷갈리던 마음이 저녁쯤 선명해질 수 있어요.|말하지 않아도 통하는 순간이 생길 수 있어요.|작은 실수가 오히려 웃긴 이야기로 바뀔 수 있어요.|평소보다 눈치가 빨라져 타이밍을 잡기 쉬워요.|오래 미룬 메시지를 보내기 좋은 흐름이에요.|새로 알게 된 사실이 취향을 살짝 바꿀 수 있어요.|기분 전환이 예상보다 빠르게 먹힐 수 있어요.|돈보다 시간이 아깝게 느껴지는 순간이 올 수 있어요.|괜찮은 우연이 다음 약속으로 이어질 수 있어요.|조용한 집중으로 결과가 또렷해질 수 있어요.|마음에 걸리던 일이 대수롭지 않게 지나갈 수 있어요.|낮보다 밤에 감이 좋아질 수 있어요.|누군가의 부탁 속에 작은 기회가 숨어 있을 수 있어요.|기다리던 물건이나 소식이 가까워질 수 있어요.|생각보다 말이 잘 통하는 사람을 만날 수 있어요.|사소한 정리가 하루 전체를 가볍게 만들 수 있어요.|처음 고른 선택이 의외로 오래 맞아떨어질 수 있어요.';

  @override
  String get fortuneSajuTrainingTones =>
      '괜히 서두르지만 않으면 더 산뜻해져요.|먼저 한마디 건네면 분위기가 쉽게 풀려요.|작게 정리하고 시작하면 흐름이 빨라져요.|마음에 걸리는 건 짧게 메모해두면 좋아요.|오늘은 빠른 결정보다 기분이 편한 선택이 잘 맞아요.|가벼운 농담 하나가 어색함을 녹여줘요.|복잡한 일은 순서를 세 개로 줄여보세요.|오전에 중요한 메시지를 확인해두면 편해요.|점심 이후에는 무리한 약속을 줄이는 쪽이 좋아요.|기분 좋은 색을 가까이 두면 집중이 쉬워져요.|작은 부탁은 바로 처리하면 마음이 넓어져요.|괜찮은 생각은 캡처하거나 적어두세요.|말이 길어질 때는 핵심만 남기면 충분해요.|오늘은 새로운 길보다 익숙한 길에서 재미가 나와요.|잠깐 멈춰서 숨을 고르면 선택이 또렷해져요.|혼자 해결하려던 일에 도움을 받아도 좋아요.|기다리는 동안 할 수 있는 작은 일을 잡아보세요.|반가운 연락에는 너무 오래 뜸 들이지 마세요.|정답보다 취향을 믿는 편이 잘 맞아요.|지나친 비교만 줄이면 기분이 금방 살아나요.|아까운 물건은 한 번 더 찾아볼 만해요.|낯선 정보는 바로 믿기보다 한 번 확인해보세요.|가까운 사람의 컨디션을 먼저 물어보면 좋아요.|미뤄둔 예약이나 확인을 끝내기 좋은 타이밍이에요.|짧은 외출이 생각보다 큰 환기가 돼요.|휴대폰 알림을 조금 줄이면 집중이 길어져요.|나중보다 지금 할 수 있는 작은 선택이 좋아요.|걱정은 크게 말하지 말고 작게 나눠보세요.|오늘은 깔끔한 마무리가 운을 끌어올려요.|가볍게 고른 메뉴가 의외로 만족스러울 수 있어요.|한 번 더 읽고 보내면 오해가 줄어들어요.|속도가 안 나면 자리나 배경을 바꿔보세요.|먼저 웃으면 대화가 훨씬 쉬워져요.|필요 없는 짐을 하나 덜어내면 마음도 가벼워져요.|약속 시간 앞뒤 10분을 넉넉히 잡아보세요.|오늘 좋은 장면은 사진보다 말로 남겨도 좋아요.';

  @override
  String get fortuneSajuNameElements =>
      '빠른 시작형|다정한 연결형|차분한 정리형|반짝이는 아이디어형|느긋한 관찰형|분위기 전환형|섬세한 선택형|직감이 빠른 형|꾸준한 회복형|먼저 웃는 형|기회를 잘 보는 형|소소한 행복형|마음을 살피는 형|타이밍을 맞추는 형|말보다 행동형|한 박자 기다리는 형|새로움에 열린 형|정확하게 고르는 형|관계가 따뜻한 형|작게 실천하는 형|기분을 끌어올리는 형|흐름을 바꾸는 형|호기심이 강한 형|마무리가 좋은 형';

  @override
  String get fortuneSajuPlayAdvice =>
      '작은 우연도 그냥 넘기지 않으면 하루가 더 재미있어져요.|먼저 정리한 사람이 오늘의 속도를 가져갈 수 있어요.|가볍게 고른 선택이 의외로 오래 기분을 살려줘요.|말을 아끼는 순간보다 다정하게 말하는 순간이 더 힘이 있어요.|기다리던 답은 생각보다 단순한 모습으로 올 수 있어요.|괜찮은 제안은 바로 거절하지 말고 조금만 열어두세요.|하루 중 한 번은 스스로에게 쉬운 선택을 주세요.|오늘은 큰 변화보다 작은 방향 전환이 잘 맞아요.|익숙한 사람에게서 새로운 면을 볼 수 있어요.|대충 지나가던 일을 한 번만 살피면 힌트가 보여요.|잠깐의 여유가 오후의 실수를 줄여줄 수 있어요.|가볍게 움직이면 머릿속 엉킨 생각도 같이 풀려요.|기분이 가라앉으면 색이 선명한 물건을 가까이 둬보세요.|낯선 대화가 생각보다 빨리 편해질 수 있어요.|급한 마음만 줄이면 결과는 충분히 따라와요.|작은 약속을 지키면 신뢰가 눈에 보이게 쌓여요.|오늘 만나는 정보 중 하나는 나중에 꽤 유용해져요.|웃고 넘긴 일이 저녁에는 좋은 이야기거리가 돼요.|정리할 것과 버릴 것을 나누면 마음이 확실히 가벼워져요.|새로 시작하기보다 멈춘 일을 다시 켜기 좋은 날이에요.|예상 밖의 칭찬을 받으면 그냥 받아들여도 좋아요.|짧은 집중 시간이 길게 끌고 가는 힘이 돼요.|어색한 순간은 먼저 질문하면 금방 풀려요.|오늘의 행운은 크게 오기보다 작은 반복으로 와요.|선택지가 많으면 가장 편안한 것을 고르세요.|미묘한 감이 맞을 수 있으니 기록해두면 좋아요.|누군가의 도움을 받으면 감사 인사를 바로 남겨보세요.|일찍 끝낼 수 있는 일은 미루지 않는 쪽이 운을 살려요.|마음에 드는 문장 하나가 하루 표정까지 바꿀 수 있어요.|기다림 끝에 온 소식은 조금 천천히 읽어도 괜찮아요.|오늘은 단정한 시작이 단정한 마무리로 이어져요.|큰 기대 없이 한 일이 작은 성과로 돌아올 수 있어요.|오해가 생기면 짧고 부드럽게 확인하는 편이 좋아요.|나만의 속도를 지키면 주변 흐름도 편해져요.|잠깐의 침묵이 더 좋은 대답을 데려올 수 있어요.|마지막에 고른 선택이 오늘의 기억으로 남을 수 있어요.';

  @override
  String get fortuneLuckyColorTones =>
      '딥|소프트|클린|선셋|쿨|웜|미스트|브라이트|모노|포인트|네온|파스텔|메탈릭|프레시|차분한|스파클|라이트|무드|글로우|내추럴';

  @override
  String get fortuneLuckyColorBases =>
      '네이비|에메랄드|코랄|머스타드|스카이블루|카키|아이보리|체리 레드|라임|차콜|로열 블루|민트|피치|바이올렛|실버|골드|화이트|블랙|올리브|터쿼이즈|라벤더|버터 옐로|로즈 핑크|딥 그린';

  @override
  String get fortuneLuckyTimePeriods =>
      '이른 오전|오전 후반|점심 직후|초반 오후|늦은 오후|해질 무렵|저녁 초반|밤 루틴 시간|등교 전|쉬는 시간|이동 중|잠들기 전|메시지 확인 시간|간식 시간|집에 돌아온 직후|하루 정리 시간';

  @override
  String get fortuneLuckyTimeWindows =>
      '06:40~07:20|08:10~08:50|09:30~10:10|10:40~11:20|12:20~13:00|14:10~14:50|16:00~16:40|18:20~19:00|20:10~20:50|21:00~21:40|07:30~08:00|11:40~12:10|13:20~13:50|15:10~15:40|17:20~17:50|19:30~20:00|22:00~22:30|06:10~06:30|12:50~13:20|18:50~19:20';

  @override
  String get fortuneLuckyZoneModifiers =>
      '창가 쪽|문 가까이|왼쪽 자리|오른쪽 자리|중앙 자리|조용한 곳|밝은 곳|그늘진 곳|책상 앞|현관 근처|엘리베이터 앞|버스 정류장 근처|카페 모서리|복도 끝|계단 가까이|물 마시는 곳|거울 앞|가방 옆|식탁 근처|침대 옆';

  @override
  String get fortuneLuckyZoneBases =>
      '작은 메모 공간|휴대폰을 내려두는 자리|첫 인사를 건네는 순간|가볍게 웃는 자리|잠깐 쉬는 의자|정리된 책상 위|가방을 여는 순간|창밖이 보이는 자리|물을 마시는 자리|조용히 생각하는 곳|메시지를 확인하는 순간|신발을 고쳐 신는 곳|엘리베이터 기다리는 곳|좋아하는 음악을 듣는 시간|손을 씻는 곳|간단히 간식 먹는 자리|계획을 다시 보는 곳|잠깐 멈춰 서는 곳|집에 들어오는 순간|불을 켜는 자리|먼저 양보하는 순간|낯선 길이 보이는 곳|오늘 물건을 찾는 자리|하루를 닫는 자리';

  @override
  String get fortuneLuckyCueOpenings =>
      '짧게|첫 시작 전에|호흡 고른 뒤|메시지를 보내기 전에|문을 나서기 전에|고개를 든 직후|자리에 앉기 전에|리듬이 흔들리면|물 마신 다음|이름을 부르기 전에|첫 실수 뒤에|대화가 끊기면|선택 전 한 번|마음이 급해지면|좋은 말을 들은 뒤|잠들기 전에|알림을 확인하기 전에|계단을 오르기 전에|새로운 장소에 들어가면|하루를 정리하며';

  @override
  String get fortuneLuckyCueActions =>
      '한 번 더 확인하기|먼저 웃어보기|두 손을 가볍게 털기|첫 문장을 짧게 말하기|고마운 점 하나 찾기|짧은 호흡으로 마음 묶기|빠름보다 정확함을 고르기|어깨 힘을 빼기|상대 이름을 부드럽게 부르기|두 번째 선택을 작게 바꾸기|메모 하나 남기기|걸음을 조금 늦추기|실수 뒤 바로 정리하기|보내기 전 한 번 읽기|도움을 청할 사람 떠올리기|확답 전에 잠깐 멈추기|짧은 칭찬으로 분위기 올리기|마지막 10분은 가볍게 정리하기|다음 일을 먼저 예상하기|주변 색을 하나 고르기|고개를 들고 천천히 보기|끝낸 뒤 바로 치우기|어색하면 질문 하나 던지기|오늘 좋았던 장면 기억하기|조용한 음악 하나 고르기|가방 속을 한 번 정리하기|물 한 모금 마시기|걱정을 세 줄로 줄이기|기분 좋은 사진을 다시 보기|작은 약속을 먼저 지키기|앉는 자리를 살짝 바꾸기|저녁에 한 가지 칭찬 남기기';

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
      '달리기를 다음 경기의 무기로 느끼게 해요. 짧은 축구형 스프린트 미션을 뛰고 기록을 남긴 뒤, 자세 코칭으로 다음 0.1초를 찾습니다.';

  @override
  String get runningCoachSectionToday => '미션';

  @override
  String get runningCoachSectionRecords => '기록';

  @override
  String get runningCoachSectionAnalysis => '분석';

  @override
  String get runningCoachTodayPlanTitle => '오늘 세션 플랜';

  @override
  String get runningCoachTodayPlanMissionTitle => '메인 스프린트 블록';

  @override
  String get runningCoachTodayPlanMissionBody =>
      '아래 미션부터 시작해요. 날카롭게 3번만 뛰어도 충분합니다.';

  @override
  String get runningCoachTodayPlanRecordTitle => '퍼포먼스 기록';

  @override
  String get runningCoachTodayPlanRecordBody =>
      '뛴 뒤에는 기록 화면으로 가서 가장 빠른 시도만 입력해요.';

  @override
  String get runningCoachTodayPlanAnalysisTitle => '자세 리뷰 트리거';

  @override
  String get runningCoachTodayPlanAnalysisBody =>
      '출발이 느리거나 몸이 무겁게 느껴질 때 분석 화면에서 자세를 확인해요.';

  @override
  String get runningCoachTodayPlanRecordAction => '기록으로 이동';

  @override
  String get runningCoachTodayPlanAnalysisAction => '분석으로 이동';

  @override
  String get runningCoachRecordsPlanTitle => '타이밍 기록 프로토콜';

  @override
  String get runningCoachRecordsPlanDistanceTitle => '거리 선택';

  @override
  String get runningCoachRecordsPlanDistanceBody =>
      '방금 뛴 스프린트에 맞춰 10m, 20m, 30m 중 하나를 고릅니다.';

  @override
  String get runningCoachRecordsPlanSecondsTitle => '초 입력';

  @override
  String get runningCoachRecordsPlanSecondsBody =>
      '스톱워치에 나온 시간을 초 단위로 넣고 오늘의 최고 시도로 저장해요.';

  @override
  String get runningCoachRecordsPlanCompareTitle => '이전의 나를 따라잡기';

  @override
  String get runningCoachRecordsPlanCompareBody =>
      '저장된 기록은 이전 최고 기록과 비교되어 다음 목표가 바로 보입니다.';

  @override
  String get runningCoachAnalysisPlanTitle => '영상 분석 프로토콜';

  @override
  String get runningCoachAnalysisPlanRecordTitle => '측면 영상 찍기';

  @override
  String get runningCoachAnalysisPlanRecordBody =>
      '몸 전체가 보이도록 옆에서 몇 걸음 달리는 영상을 찍어요.';

  @override
  String get runningCoachAnalysisPlanSampleTitle => '샘플 먼저 보기';

  @override
  String get runningCoachAnalysisPlanSampleBody =>
      '업로드 전에 앱이 무엇을 비교하는지 샘플 가이드로 확인할 수 있어요.';

  @override
  String get runningCoachAnalysisPlanAnalyzeTitle => '영상 선택 후 분석';

  @override
  String get runningCoachAnalysisPlanAnalyzeBody =>
      '영상을 고르고 분석한 뒤, 가장 먼저 고칠 포인트부터 따라가요.';

  @override
  String get runningCoachControlPanelTitle => '코치 체크포인트';

  @override
  String get runningCoachControlPanelLoadLabel => '훈련량';

  @override
  String get runningCoachControlPanelLoadValue => '고품질 3회';

  @override
  String get runningCoachControlPanelDistanceLabel => '거리';

  @override
  String runningCoachControlPanelDistanceValue(int meters) {
    return '${meters}m 집중';
  }

  @override
  String get runningCoachControlPanelRecordLabel => '기록';

  @override
  String get runningCoachControlPanelRecordValue => '최고 시도만';

  @override
  String get runningCoachControlPanelReviewLabel => '리뷰';

  @override
  String get runningCoachControlPanelReviewValue => '필요 시 측면 분석';

  @override
  String get runningCoachMissionCardTitle => '오늘의 스피드 미션';

  @override
  String runningCoachMissionDistance(int meters) {
    return '${meters}m 미션';
  }

  @override
  String get runningCoachMissionStartSprint => '스프린트 코치 시작';

  @override
  String get runningCoachMissionStartLive => '자세 실시간 확인';

  @override
  String get runningCoachMissionBreakawayTitle => '수비 라인 깨기';

  @override
  String get runningCoachMissionBreakawayBody =>
      '수비 뒤 공간으로 침투한다고 생각하고 20m를 뛰어요. 길게 하지 말고 날카로운 3번이면 충분해요.';

  @override
  String get runningCoachMissionBreakawayFocus => '첫 3보';

  @override
  String get runningCoachMissionBreakawayReward => '어제 출발 넘기';

  @override
  String get runningCoachMissionPressureTitle => '압박 벗어나기';

  @override
  String get runningCoachMissionPressureBody =>
      '압박에서 돌아나와 10m만 폭발해요. 오래 뛰는 것보다 첫 밀어내기를 빠르게 만드는 게 목표예요.';

  @override
  String get runningCoachMissionPressureFocus => '낮은 전경사';

  @override
  String get runningCoachMissionPressureReward => '더 빠른 탈압박';

  @override
  String get runningCoachMissionLooseBallTitle => '루즈볼 먼저 잡기';

  @override
  String get runningCoachMissionLooseBallBody =>
      '경기처럼 30m 루즈볼을 쫓아가요. 가장 좋은 기록을 남기고 다음엔 아주 조금만 줄여 봅니다.';

  @override
  String get runningCoachMissionLooseBallFocus => '후반 속도 유지';

  @override
  String get runningCoachMissionLooseBallReward => '새 추격 목표';

  @override
  String get runningCoachMissionFirstStepsTitle => '첫 세 걸음 잡기';

  @override
  String get runningCoachMissionFirstStepsBody =>
      '처음 10m만 전력으로 뛰고 멈춰요. 출발이 빠르고 가볍고 반복 가능하게 느껴지는 게 목표예요.';

  @override
  String get runningCoachMissionFirstStepsFocus => '폭발적인 출발';

  @override
  String get runningCoachMissionFirstStepsReward => '출발 배지 진도';

  @override
  String get runningCoachGrowthTitle => '내 기록 깨기';

  @override
  String get runningCoachGrowthBody =>
      '10m, 20m, 30m 기록을 간단히 남겨요. 최고 기록뿐 아니라 연속 도전과 꾸준한 시도도 축하해서 새 기록 전에도 달리기가 재밌게 느껴지게 합니다.';

  @override
  String get runningCoachGrowthAttemptsLabel => '시도';

  @override
  String runningCoachGrowthAttempts(int count) {
    return '총 $count회';
  }

  @override
  String get runningCoachGrowthStreakLabel => '연속';

  @override
  String runningCoachGrowthStreak(int count) {
    return '$count일';
  }

  @override
  String get runningCoachGrowthDistancesLabel => '거리';

  @override
  String runningCoachGrowthDistances(int count) {
    return '$count/3 기록';
  }

  @override
  String get runningCoachRecordInputTitle => '스프린트 기록 남기기';

  @override
  String runningCoachRecordDistance(int meters) {
    return '${meters}m';
  }

  @override
  String get runningCoachRecordSecondsLabel => '기록';

  @override
  String get runningCoachRecordSecondsHint => '예: 4.32';

  @override
  String get runningCoachRecordSecondsSuffix => '초';

  @override
  String get runningCoachRecordSaveAction => '기록 저장';

  @override
  String get runningCoachRecordInvalid => '0초보다 크고 60초 이하인 스프린트 기록을 입력해 주세요.';

  @override
  String get runningCoachRecordSaved => '스프린트 기록을 저장했어요.';

  @override
  String get runningCoachRecordEmpty => '아직 기록 없음';

  @override
  String runningCoachRecordSecondsValue(String seconds) {
    return '$seconds초';
  }

  @override
  String get runningCoachGhostEmptyTitle => '첫 고스트 러너 만들기';

  @override
  String get runningCoachGhostEmptyBody =>
      '한 번 뛰고 기록을 저장해 주세요. 다음 목표는 이전의 나를 따라잡는 것부터 시작해요.';

  @override
  String runningCoachGhostTitle(int meters) {
    return '${meters}m 고스트 러너';
  }

  @override
  String runningCoachGhostFirstRecordBody(String seconds) {
    return '첫 목표는 $seconds초예요. 다음에는 0.05초만 줄여 봐요.';
  }

  @override
  String runningCoachGhostImprovedBody(String seconds) {
    return '개인 최고 기록을 $seconds초 줄였어요. 이 느낌을 기억하고 한 번 더 반복해 봐요.';
  }

  @override
  String runningCoachGhostChaseBody(String seconds) {
    return '최고 고스트와 $seconds초 차이예요. 출발 하나만 더 깔끔해져도 좁힐 수 있어요.';
  }

  @override
  String get runningCoachBadgesTitle => '러닝 배지';

  @override
  String get runningCoachBadgeFirstRun => '첫 질주';

  @override
  String get runningCoachBadgeRecordBreaker => '기록 단축';

  @override
  String get runningCoachBadgeThreeDaySpark => '3일 불씨';

  @override
  String get runningCoachBadgeAllRounder => '10/20/30m 러너';

  @override
  String get runningCoachAnalyzeBody =>
      '측면 영상을 고르면 점수, 관절 각도, 접지 기준, 가장 먼저 고칠 움직임을 같이 정리해 줍니다.';

  @override
  String get runningCoachTipsTitle => '촬영 팁';

  @override
  String get runningCoachTipWholeBody =>
      '머리부터 접지하는 발까지 전신이 들어오고, 어깨, 엉덩이, 무릎, 발목, 팔꿈치, 손목이 계속 보이게 촬영해 주세요.';

  @override
  String get runningCoachTipSideView =>
      '러너가 카메라 쪽으로 오거나 멀어지지 않고 화면을 가로지르도록 정확한 측면에서 촬영해 주세요.';

  @override
  String get runningCoachTipSteadyCamera =>
      '카메라는 흔들리지 않게 두고 밝고 고른 빛에서 3보 이상 깨끗한 5~15초 장면을 사용해 주세요.';

  @override
  String get runningCoachUploadGuideTitle => '동영상 업로드 가이드';

  @override
  String get runningCoachUploadGuideBody =>
      '샘플 가이드에서 좋은 자세와 잘못된 자세 루프를 비교하고, 코치가 읽는 관절, 각도, 접지 지점을 정확히 확인해요.';

  @override
  String get runningCoachUploadGuideStepSide =>
      '휴대폰을 달리는 라인과 직각으로, 엉덩이 높이에 맞춰 두고 러너가 좌우로 지나가게 촬영해 주세요.';

  @override
  String get runningCoachUploadGuideStepDistance =>
      '러너 앞뒤에 여유 공간을 두어 머리, 엉덩이, 무릎, 발목, 발, 팔꿈치, 손목이 모든 스텝에서 보이게 해 주세요.';

  @override
  String get runningCoachUploadGuideStepDuration =>
      '깨끗한 보폭이 3~6번 들어간 5~15초 영상을 쓰고, 준비 걸음, 회전, 멈춘 프레임은 잘라 주세요.';

  @override
  String get runningCoachUploadGuideStepLight =>
      '밝고 고른 빛과 단순한 배경에서 촬영하고, 그림자, 잘린 발, 뒤로 지나가는 사람을 피해주세요.';

  @override
  String get runningCoachSampleTitle => '샘플 영상 가이드';

  @override
  String get runningCoachSampleBody =>
      '기준 루프와 잘못된 자세 루프를 바꿔 보며 코치가 상체, 착지, 무릎 부하, 팔 각도, 바운스, 프레임 품질을 어떻게 읽는지 확인해요.';

  @override
  String get runningCoachSampleGuideAction => '샘플 영상 가이드 보기';

  @override
  String runningCoachSampleFrameLabel(int current, int total) {
    return '프레임 $current/$total';
  }

  @override
  String get runningCoachSampleFrameGuideTitle => '영상에서 같이 볼 기준';

  @override
  String get runningCoachSampleFrameGuideBody =>
      '텍스트만 나열하지 않고 샘플 러너 위에 자세, 착지, 팔 타이밍, 프레임 판독을 같이 표시해 비교하기 쉽게 했어요.';

  @override
  String get runningCoachSampleCueLean => '발목부터 어깨까지, 허리 꺾임 없는 전경사';

  @override
  String get runningCoachSampleCueFrame => '머리, 엉덩이, 무릎, 발이 계속 보임';

  @override
  String get runningCoachSampleCueFoot => '발끝이 앞으로 향하고 엉덩이 아래 착지';

  @override
  String get runningCoachSampleCueArms => '팔꿈치를 접고 다리와 반대로 스윙';

  @override
  String get runningCoachSampleReferenceTab => '기준 샘플';

  @override
  String get runningCoachSampleMistakeTab => '잘못된 샘플';

  @override
  String get runningCoachSampleReferenceTitle => '기준 자세 판독';

  @override
  String get runningCoachSampleMistakeTitle => '잘못된 자세 판독';

  @override
  String get runningCoachSampleReferenceBody =>
      '목표 루프예요. 러너가 몸 전체를 살짝 기울이고, 엉덩이 가까이 착지하며, 무릎을 부드럽게 받고, 팔은 간결하게 유지해요.';

  @override
  String get runningCoachSampleMistakeBody =>
      '확인이 필요한 패턴이에요. 상체가 서고, 발이 엉덩이보다 앞에 떨어지고, 접지 무릎이 뻣뻣하며, 팔 스윙이 높고, 위아래 바운스가 커져요.';

  @override
  String get runningCoachSampleReferencePosture =>
      '상체 선: 발목-엉덩이-어깨 전경사 10도, 허리 접힘 없음.';

  @override
  String get runningCoachSampleReferenceFoot =>
      '접지 지점: 착지 거리 0.08, 엉덩이 아래에 가깝게 착지.';

  @override
  String get runningCoachSampleReferenceKnee =>
      '접지 무릎: 155도, 잠그지 않고 부드럽게 부하를 받음.';

  @override
  String get runningCoachSampleReferenceArms =>
      '팔 각도: 팔꿈치가 90도 근처에서 다리와 반대로 스윙.';

  @override
  String get runningCoachSampleReferenceFrame =>
      '프레임 품질: 주요 관절이 보이는 24/24 사용 가능 프레임.';

  @override
  String get runningCoachSampleMistakePosture =>
      '상체 선: 전경사 4도라 앞으로 밀지 못하고 몸이 선 상태.';

  @override
  String get runningCoachSampleMistakeFoot =>
      '접지 지점: 엉덩이보다 0.20 앞에 떨어져 제동이 커짐.';

  @override
  String get runningCoachSampleMistakeKnee =>
      '접지 무릎: 172도, 충격을 받고 밀기에는 너무 곧게 펴짐.';

  @override
  String get runningCoachSampleMistakeArms =>
      '팔 각도: 팔꿈치가 118도 근처까지 올라와 스윙이 높고 좁아짐.';

  @override
  String get runningCoachSampleMistakeBounce => '바운스: 수직 움직임 10%, 힘이 위로 새어 나감.';

  @override
  String get runningCoachSampleAnalysisMethodTitle => '코치가 분석하는 방식';

  @override
  String get runningCoachSampleAnalysisMethodBody =>
      '코치는 안정적인 측면 프레임을 샘플링하고, 자세 랜드마크를 추적하고, 접지 구간을 추정한 뒤 각 지표를 신뢰도와 함께 점수화해요.';

  @override
  String get runningCoachSampleMethodPose =>
      '자세 랜드마크: 어깨, 엉덩이, 무릎, 발목, 팔꿈치, 손목, 머리가 계속 보여야 해요.';

  @override
  String get runningCoachSampleMethodAngles =>
      '각도: 전경사, 접지 무릎, 팔꿈치 각도를 프레임마다 측정해요.';

  @override
  String get runningCoachSampleMethodContact =>
      '접지: 착지에 가까운 프레임으로 엉덩이 선 대비 발 착지 거리를 추정해요.';

  @override
  String get runningCoachSampleMethodConfidence =>
      '신뢰도: 추적 범위가 낮거나 안정 프레임이 적으면 다시 확인하라고 알려줘요.';

  @override
  String get runningCoachSampleRecordingGuideTitle => '샘플처럼 촬영하기';

  @override
  String get runningCoachSampleProcessTitle => '실제 영상 분석 흐름';

  @override
  String get runningCoachSampleProcessBody =>
      '오버레이는 코치가 실제로 보는 순서대로 보여줘요. 안정 프레임을 고르고, 보이는 관절을 고정하고, 자세선을 잇고, 각도를 잰 뒤 착지와 신뢰도를 비교해요.';

  @override
  String get runningCoachSamplePhaseFrame => '프레임 샘플';

  @override
  String get runningCoachSamplePhaseJoints => '관절 추적';

  @override
  String get runningCoachSamplePhaseMuscles => '근육 부하 맵';

  @override
  String get runningCoachSamplePhaseSkeleton => '자세선 연결';

  @override
  String get runningCoachSamplePhaseAngles => '각도 측정';

  @override
  String get runningCoachSamplePhaseContactScore => '착지 신뢰도 점수';

  @override
  String get runningCoachSampleDecisionTitle => '판정 근거';

  @override
  String get runningCoachSampleMetricPosture => '상체';

  @override
  String get runningCoachSampleMetricArms => '팔';

  @override
  String get runningCoachSampleMetricLanding => '착지';

  @override
  String get runningCoachSampleMetricFrames => '프레임';

  @override
  String get runningCoachSampleMetricBounce => '바운스';

  @override
  String get runningCoachSampleStatusPass => '통과';

  @override
  String get runningCoachSampleStatusReview => '확인';

  @override
  String get runningCoachSampleOverlayPosture => '전경사 10도';

  @override
  String get runningCoachSampleOverlayArms => '팔 90도';

  @override
  String get runningCoachSampleOverlayFoot => '착지 0.08';

  @override
  String get runningCoachSampleOverlayBounce => '바운스 6%';

  @override
  String get runningCoachSampleOverlayFrames => '24/24프레임';

  @override
  String get runningCoachSampleMistakeOverlayPosture => '상체 4도';

  @override
  String get runningCoachSampleMistakeOverlayArms => '팔 118도';

  @override
  String get runningCoachSampleMistakeOverlayFoot => '앞착지 0.20';

  @override
  String get runningCoachSampleMistakeOverlayBounce => '바운스 10%';

  @override
  String get runningCoachSampleMetricDetailScreenTitle => '근거 상세';

  @override
  String get runningCoachSampleMetricDetailHeroBody =>
      '이 화면은 선택한 판정 항목을 매기기 전에 샘플 오버레이가 실제로 읽는 신체 위치를 확대해서 보여줘요.';

  @override
  String get runningCoachSampleMetricDetailSampleLabel => '샘플';

  @override
  String get runningCoachSampleMetricDetailValueLabel => '측정값';

  @override
  String get runningCoachSampleMetricDetailStatusLabel => '판정';

  @override
  String get runningCoachSampleMetricDetailKeyPositionTitle => '핵심 위치';

  @override
  String get runningCoachSampleMetricDetailReferenceTitle => '좋은 동작';

  @override
  String get runningCoachSampleMetricDetailReviewTitle => '확인 동작';

  @override
  String get runningCoachSampleMetricDetailHowReadTitle => '오버레이가 읽는 방식';

  @override
  String get runningCoachSamplePostureDetailKeyPosition =>
      '중간 접지 위치: 어깨 중심, 엉덩이 선, 지지 발목을 연결해 상체 기울기를 봐요.';

  @override
  String get runningCoachSamplePostureDetailReference =>
      '좋은 샘플은 엉덩이부터 가볍게 앞으로 기울고, 머리가 가슴 위에 안정적으로 실려 있어요.';

  @override
  String get runningCoachSamplePostureDetailReview =>
      '확인 샘플은 상체가 너무 서 있어 밀어내는 선이 짧고 가속이 늦어 보일 수 있어요.';

  @override
  String get runningCoachSamplePostureDetailHowRead =>
      '앱은 엉덩이와 어깨 중심을 연결하고, 엉덩이의 수직선과 비교해 프레임마다 전경사 각도를 확인해요.';

  @override
  String get runningCoachSampleArmsDetailKeyPosition =>
      '팔 드라이브 위치: 반대쪽 무릎이 앞으로 나오는 순간 팔꿈치 각도를 읽어요.';

  @override
  String get runningCoachSampleArmsDetailReference =>
      '좋은 샘플은 팔꿈치를 90도에 가깝게 유지하고 갈비뼈 옆에서 앞뒤로 흔들어요.';

  @override
  String get runningCoachSampleArmsDetailReview =>
      '확인 샘플은 팔꿈치가 많이 열려 보폭 리듬이 느려지고 몸통 회전이 커질 수 있어요.';

  @override
  String get runningCoachSampleArmsDetailHowRead =>
      '앱은 어깨, 팔꿈치, 손목 랜드마크를 연결하고 팔꿈치가 지나치게 열리는 프레임을 표시해요.';

  @override
  String get runningCoachSampleLandingDetailKeyPosition =>
      '첫 접지 위치: 발, 발목, 엉덩이 선으로 발이 몸 아래에 떨어지는지 봐요.';

  @override
  String get runningCoachSampleLandingDetailReference =>
      '좋은 샘플은 발이 엉덩이 선 가까이에 닿아 접지가 앞으로 밀어주는 힘으로 이어져요.';

  @override
  String get runningCoachSampleLandingDetailReview =>
      '확인 샘플은 발이 엉덩이보다 너무 앞에 떨어져 브레이크처럼 읽혀요.';

  @override
  String get runningCoachSampleLandingDetailHowRead =>
      '앱은 착지 구간에서 엉덩이 선과 접지 발목, 발끝 사이의 가로 거리를 측정해요.';

  @override
  String get runningCoachSampleBounceDetailKeyPosition =>
      '공중-접지 전환 구간: 이웃 프레임의 머리와 엉덩이 높이 변화를 비교해요.';

  @override
  String get runningCoachSampleBounceDetailReference =>
      '좋은 샘플은 위아래 움직임이 작아 에너지가 앞으로 유지돼요.';

  @override
  String get runningCoachSampleBounceDetailReview =>
      '확인 샘플은 몸이 더 크게 뜨고 내려와 접지 타이밍이 불안정해져요.';

  @override
  String get runningCoachSampleBounceDetailHowRead =>
      '앱은 보폭 전체에서 머리와 엉덩이 높이 범위를 추적하고 수직 변화 비율을 점수화해요.';

  @override
  String get runningCoachLiveCardTitle => '실시간 코치';

  @override
  String get runningCoachLiveCardBody =>
      '러너 윤곽과 자세 선을 실시간으로 보고, 필요하면 바로 스프린트 전용 피드백으로 넘어가 전경사, 무릎 드라이브, 스텝 리듬, 팔 균형까지 확인할 수 있어요.';

  @override
  String get runningCoachLiveAction => '실시간 코치 시작';

  @override
  String get runningCoachLiveGuideAction => '촬영 가이드';

  @override
  String get runningCoachLiveScreenTitle => '실시간 달리기 코치';

  @override
  String get runningCoachLiveGuideScreenTitle => '실시간 촬영 가이드';

  @override
  String get runningCoachLiveGuideHeroTitle => '러너 윤곽을 잡고 하단 코칭을 같이 봐요';

  @override
  String get runningCoachLiveGuideHeroBody =>
      '실시간 코치는 러너 윤곽과 자세 선을 화면에 바로 마킹하고, 하단 패널에서 설명과 결과를 함께 보여줘요. 아래 기준을 맞추면 추적과 코칭이 더 안정돼요.';

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
  String get runningCoachLiveGuideTipHudTitle => '상단 안내와 하단 결과를 같이 보세요';

  @override
  String get runningCoachLiveGuideTipHudBody =>
      '노란 네모 대신 상단 상태 문구와 러너 윤곽 마킹이 먼저 보이고, 하단 패널에서는 이유와 수정 포인트, 부위별 결과를 같이 확인할 수 있어요.';

  @override
  String get runningCoachLiveGuideTipCameraTitle => '카메라는 고정하고 몸 크기는 적당히';

  @override
  String get runningCoachLiveGuideTipCameraBody =>
      '카메라는 흔들리지 않게 두고, 러너가 화면 높이의 절반 이상 차지하도록 맞춰 주세요. 화면을 꽉 채울수록 자세 선과 음성 코칭이 더 안정돼요.';

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
  String get runningCoachLiveGuidanceTitle => '현재 안내';

  @override
  String get runningCoachSprintLiveCardTitle => '스프린트 실시간 코칭';

  @override
  String get runningCoachSprintLiveCardBody =>
      '측면 카메라로 전경사, 무릎 드라이브, 스텝 리듬, 팔 균형을 읽고 질주 중 바로 고칠 포인트를 알려줘요.';

  @override
  String get runningCoachSprintLiveAction => '스프린트 코칭 시작';

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
  String get runningCoachSprintSessionLogTitle => '세션 요약';

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
  String get runningCoachOverallScoreLabel => '종합 점수';

  @override
  String get runningCoachDurationLabel => '영상 길이';

  @override
  String get runningCoachFramesAnalyzedLabel => '분석 프레임';

  @override
  String get runningCoachCoverageLabel => '추적 비율';

  @override
  String get runningCoachMetricScoresTitle => '지표별 점수';

  @override
  String get runningCoachFocusTitle => '지금 가장 먼저 볼 포인트';

  @override
  String get runningCoachMaintainTitle => '유지할 포인트';

  @override
  String runningCoachMetricScore(int score) {
    return '점수 $score';
  }

  @override
  String runningCoachPriorityLabel(int priority) {
    return '우선 $priority';
  }

  @override
  String get runningCoachMetricValueLabel => '측정값';

  @override
  String get runningCoachBodyRegionUpper => '상체';

  @override
  String get runningCoachBodyRegionLower => '하체';

  @override
  String get runningCoachBodyRegionWhole => '전신 리듬';

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
      '핵심 관절이 화면 가장자리에서 잘려 자세선과 지표가 함께 흔들릴 수 있습니다.';

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
      '핵심 스프린트 지표가 안정 범위 안에 있어 지금 형태를 유지하는 안내를 주고 있습니다.';

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
  String get runningCoachSprintSessionFeatureConfidenceLabel => '지표 신뢰도';

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
  String get homeWeatherNeedsLocationTitle => '위치 연결 필요';

  @override
  String get homeWeatherNeedsLocationSubtitle => '위치 켜고 확인';

  @override
  String get homeStreakBadgeActive => '연속 중';

  @override
  String get homeStreakBadgeResume => '다시 시작';

  @override
  String homeStreakActiveTodayTitle(int count) {
    return '오늘까지 $count일 연속';
  }

  @override
  String homeStreakActiveYesterdayTitle(int count) {
    return '어제까지 $count일 연속';
  }

  @override
  String homeStreakPausedTitle(int count) {
    return '$count일 연속 잠시 멈춤';
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
  String get homeStreakActionReview => '주간';

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
  String get familySharing => '보호자 모드/선수 공유';

  @override
  String get familySharedBackupDescription =>
      '서버 없이 Google Drive 백업 파일 하나를 함께 사용합니다. 선수 모드에서는 핵심 기록을 직접 관리하고, 보호자 모드에서는 피드백과 선물 이름만 동기화합니다.';

  @override
  String get familyBackupIncludesMedia =>
      '프로필 사진과 훈련 사진처럼 기기 파일로 저장된 항목도 가능한 범위에서 함께 백업합니다.';

  @override
  String get familyParentAutoSyncDescription =>
      '보호자 또는 코치 모드에서는 훈련 피드백과 레벨 선물 이름만 자동 동기화합니다. 선수 기록 백업과 복원은 선수 모드에서 진행해 주세요.';

  @override
  String get familyChildDriveConnectionTitle => '공유 백업 Drive 연결';

  @override
  String get familyChildDriveConnectionDescription =>
      '보호자 모드에서는 선수 데이터 원본이 있는 Google Drive 계정으로 연결해야 같은 백업 파일을 함께 사용할 수 있어요.';

  @override
  String get familyConnectChildDrive => '공유 Drive 연결';

  @override
  String get familyDisconnectChildDrive => '공유 Drive 연결 해제';

  @override
  String get familyRoleChild => '선수';

  @override
  String get familyRolePlayer => '선수';

  @override
  String get familyRoleParent => '보호자';

  @override
  String get familyRoleCoach => '코치';

  @override
  String get familyRoleSelectionTitle => '사용 방식 선택';

  @override
  String get familyRoleSelectionDescription =>
      '이 기기가 직접 기록하는 선수용인지, 보호자용인지, 여러 선수를 관리하는 코치용인지 먼저 고르세요.';

  @override
  String get settingsUsageModeTitle => '사용 방식';

  @override
  String get settingsRoleAndSyncTitle => '사용 방식 및 동기화';

  @override
  String get settingsInfoTooltip => '설명 보기';

  @override
  String get settingsSupportModeLabel => '보호자';

  @override
  String get settingsCoachRosterTitle => '코치 선수 목록';

  @override
  String get settingsCoachRosterDescription =>
      '피드백, 선물 이름, Drive 백업을 쓰기 전에 현재 관리할 선수를 선택하세요.';

  @override
  String get settingsCoachRosterEmpty => '아직 등록된 선수가 없어요.';

  @override
  String get settingsCoachRosterAddPlayer => '선수 추가';

  @override
  String get settingsCoachRosterEditPlayer => '선수 수정';

  @override
  String get settingsCoachRosterDeletePlayer => '선수 삭제';

  @override
  String get settingsCoachRosterDeleteTitle => '선수 삭제';

  @override
  String settingsCoachRosterDeleteMessage(Object player) {
    return '$player 선수를 코치 목록에서 삭제할까요?';
  }

  @override
  String settingsCoachRosterDeleted(Object player) {
    return '$player 선수를 삭제했어요.';
  }

  @override
  String settingsCoachRosterRenamed(Object player) {
    return '$player 선수 정보를 수정했어요.';
  }

  @override
  String get settingsCoachRosterLastPlayerRequired =>
      '코치 모드에서는 최소 한 명의 선수가 필요해요.';

  @override
  String settingsCoachRosterDriveAccount(Object email) {
    return 'Drive: $email';
  }

  @override
  String get settingsCoachRosterNoDriveAccount => '아직 이 선수에 저장된 Drive 계정이 없어요.';

  @override
  String get settingsCoachRosterPlayerNameLabel => '선수 이름';

  @override
  String get settingsCoachRosterPlayerNameHint => '예: 민준';

  @override
  String settingsCoachRosterAdded(Object player) {
    return '$player 선수를 추가했어요.';
  }

  @override
  String settingsCoachRosterActivated(Object player) {
    return '$player 선수가 현재 관리 대상으로 설정됐어요.';
  }

  @override
  String get settingsSupportRoleTitle => '보호자 모드 안내';

  @override
  String get settingsDriveConnectionTitle => 'Google Drive 연결';

  @override
  String get settingsDriveConnectionPlayerSummary =>
      '이 기기 기록을 저장하거나 가져올 Google Drive 계정을 확인하세요.';

  @override
  String get settingsDriveConnectionSupportSummary =>
      '현재 연결된 Google Drive 계정을 확인하세요.';

  @override
  String get settingsDataSyncTitle => '데이터 동기화';

  @override
  String get settingsDataSyncPlayerSummary =>
      '현재 데이터와 백업 데이터의 최신성을 확인하고 Drive 작업을 실행합니다.';

  @override
  String get settingsDataSyncSupportSummary =>
      '최신 백업을 가져오고 공유 변경은 보호자 또는 현재 선수 파일에 반영합니다.';

  @override
  String get settingsSyncSourceStatusTitle => '백업 데이터';

  @override
  String get settingsSyncStatusTitle => '데이터 동기화 상태';

  @override
  String get settingsSyncShowDetails => '상세 보기';

  @override
  String get settingsSyncHideDetails => '상세 숨기기';

  @override
  String get settingsSyncGoogleConnected => 'Google 연결됨';

  @override
  String get settingsSyncGoogleDisconnected => 'Google 미연결';

  @override
  String get settingsSyncDailyOn => '일일 자동 백업 켜짐';

  @override
  String get settingsSyncDailyOff => '일일 자동 백업 꺼짐';

  @override
  String get settingsSyncOnSaveOn => '저장 시 자동 백업 켜짐';

  @override
  String get settingsSyncOnSaveOff => '저장 시 자동 백업 꺼짐';

  @override
  String settingsSyncBackedUpDataTime(Object time) {
    return '백업된 데이터: $time';
  }

  @override
  String settingsSyncCurrentDataSnapshot(Object time) {
    return '현재 데이터 보관본: $time';
  }

  @override
  String get settingsSyncStatusChecking => '확인 중';

  @override
  String get settingsSyncBackupDataReady => '가져올 백업 원본을 확인했어요.';

  @override
  String get settingsSyncStatusSignInNeeded => '연결 필요';

  @override
  String get settingsSyncStatusNoBackup => '백업 없음';

  @override
  String get settingsSyncStatusCurrent => '최근 백업';

  @override
  String get settingsSyncStatusReview => '백업 확인';

  @override
  String get settingsSyncStatusStale => '백업 오래됨';

  @override
  String get settingsSyncSummaryChecking => 'Drive 백업 상태를 확인하는 중입니다.';

  @override
  String get settingsSyncSummarySignInNeeded =>
      '계정을 연결하면 현재 기기 데이터와 Drive 백업을 비교하고 가져오기/백업을 실행할 수 있어요.';

  @override
  String get settingsSyncSummaryNoBackup =>
      'Drive에 아직 백업 파일이 없어요. 데이터 백업하기로 현재 데이터를 먼저 저장해 주세요.';

  @override
  String settingsSyncSummaryCurrent(Object time) {
    return 'Drive 백업이 $time 기준으로 만들어졌어요. 최근 변경을 잃지 않으려면 백업 시간을 확인하세요.';
  }

  @override
  String settingsSyncSummaryStale(Object time) {
    return 'Drive 백업 기준이 $time입니다. 그 뒤에 바꾼 내용은 아직 백업되지 않았을 수 있어요.';
  }

  @override
  String settingsDriveActionFilePath(Object path) {
    return '파일 경로: $path';
  }

  @override
  String settingsDriveActionBackupTime(Object time) {
    return '백업 저장 시각: $time';
  }

  @override
  String get settingsDriveActionBackupTimeUnknown =>
      '백업 저장 시각: 이 기기에서는 아직 확인할 수 없어요.';

  @override
  String get settingsDriveConnectAction => 'Google Drive 연결';

  @override
  String get settingsDriveDisconnectAction => 'Google Drive 연결 해제';

  @override
  String get settingsRestoreLatestActionTitle => '최근 데이터 가져오기';

  @override
  String get settingsBackupDataActionTitle => '데이터 백업하기';

  @override
  String get settingsRoleAccountSummary => '먼저 이 기기 사용 방식을 고르세요.';

  @override
  String get settingsRoleAccountTitle => '사용 방식과 계정';

  @override
  String get settingsRoleAccountDescription =>
      '먼저 이 기기의 사용 방식을 선택하세요. 아래 계정 연결은 선택한 방식에 맞게 바뀝니다.';

  @override
  String get settingsRoleAccountUnavailable =>
      '이 빌드에서는 Google Drive 계정 연결을 사용할 수 없어요.';

  @override
  String get settingsRolePlayerDescription =>
      '선수 모드로 훈련, 식사, 스케치, 경험치, 백업을 직접 기록합니다.';

  @override
  String get settingsRoleParentDescription =>
      '핵심 기록은 읽기 중심으로 보고, 피드백과 선물 이름만 관리합니다.';

  @override
  String get settingsRoleCoachDescription =>
      '보호자 모드로 선수 기록과 스케치를 확인하고 훈련 피드백을 남깁니다.';

  @override
  String get settingsRoleActionTitle => '사용 방식에 맞는 작업';

  @override
  String get settingsPlayerActionSummary =>
      '선수 모드에서는 새 기록을 지킬 때 백업을 먼저 쓰고, 기존 기록을 되돌릴 때는 아래 가져오기 작업을 사용하세요.';

  @override
  String get settingsSupportActionSummary =>
      '보호자 모드에서는 새 원본 백업을 만들지 않고, 선수 모드에서 만든 데이터를 가져오거나 이전 가져오기 전 상태로 되돌립니다.';

  @override
  String get settingsPlayerAccountTitle => '기록 백업 Drive 계정';

  @override
  String get settingsPlayerAccountDescription =>
      '이 기기에서 훈련 기록을 백업하고 가져올 Google Drive를 연결합니다.';

  @override
  String get settingsPlayerBackupActionBody =>
      '현재 기기 기록을 Google Drive 최신본으로 저장합니다. 새 기록을 보호할 때 먼저 사용하세요.';

  @override
  String get settingsPlayerRestoreDriveActionTitle => '최근 데이터 가져오기';

  @override
  String get settingsPlayerRestoreDriveActionBody =>
      'Google Drive에 있는 최신 백업을 가져와 현재 기기 데이터를 교체합니다.';

  @override
  String get settingsPlayerRestoreLocalActionTitle => '최근 가져오기 취소';

  @override
  String get settingsPlayerRestoreLocalActionBody =>
      '이 기기에서 마지막 가져오기로 바뀐 내용을 직전 상태로 되돌립니다.';

  @override
  String get settingsSupportRestoreDriveActionTitle => '최근 선수 데이터 가져오기';

  @override
  String get settingsSupportRestoreDriveActionBody =>
      '선수 모드에서 저장한 최신 Google Drive 백업을 현재 기기로 가져옵니다.';

  @override
  String get settingsSupportRestoreLocalActionTitle => '최근 가져오기 취소';

  @override
  String get settingsSupportRestoreLocalActionBody =>
      '이 기기에서 마지막으로 가져온 선수 데이터 변경을 직전 상태로 되돌립니다.';

  @override
  String get settingsSupportBackupConfirm =>
      '보호자 모드에서 저장한 피드백과 레벨 선물 이름을 선수 데이터 원본 Drive에 반영할까요?';

  @override
  String get settingsSupportBackupSuccess => '공유 변경사항을 선수 데이터 원본 Drive에 반영했어요.';

  @override
  String get settingsSupportBackupFailed =>
      '공유 변경사항 반영에 실패했어요. 선수 모드 백업이 있는 Drive 계정인지 확인해 주세요.';

  @override
  String get settingsRestoreRollbackTitle => '가져오기 되돌리기';

  @override
  String get settingsRestoreRollbackBody =>
      '평소 백업 대신 쓰는 기능이 아니라, 마지막 가져오기로 바뀐 내용을 취소할 때만 사용하는 고급 복구입니다.';

  @override
  String familyRoleActivated(Object role) {
    return '$role 모드로 전환했어요.';
  }

  @override
  String get familyParentModeEnabled => '보호자 모드 활성화';

  @override
  String get familyParentModeDescription => '켜면 보호자 모드로 전환되고, 끄면 선수 모드로 돌아갑니다.';

  @override
  String get familyChildName => '선수 이름';

  @override
  String get familyParentName => '보호자 이름';

  @override
  String get familyChildNameEmpty => '선수 이름을 입력해 주세요';

  @override
  String get familyParentNameEmpty => '보호자 이름을 입력해 주세요';

  @override
  String get familyEditNames => '가족 이름 수정';

  @override
  String get familyPolicyTitle => '보호자 모드/선수 공유 정책';

  @override
  String get familyPolicyChildOwnsData =>
      '선수 모드에서는 훈련, 프로필, 다이어리, 식사, 계획을 원본으로 백업합니다.';

  @override
  String get familyPolicyParentWritesOnly =>
      '보호자 모드는 훈련 피드백과 레벨 선물 이름만 저장할 수 있습니다.';

  @override
  String get familyPolicyParentSeedRequired =>
      '보호자 기기는 선수 백업이 한 번 이상 만들어진 뒤 연결해야 합니다.';

  @override
  String get familyRoleChildActivated => '선수 모드로 전환했어요.';

  @override
  String get familyRoleParentActivated => '보호자 모드로 전환했어요.';

  @override
  String get familyNamesSaved => '가족 이름을 저장했어요.';

  @override
  String get driveConnectedAccount => '현재 연결된 Drive 계정';

  @override
  String get driveConnectedAccountEmpty => '아직 Google Drive 계정이 연결되지 않았어요.';

  @override
  String get driveSavedPlayerAccount => '선수 모드 백업 Drive';

  @override
  String get driveReconnectSavedPlayer => '선수 모드 Drive 다시 연결';

  @override
  String get driveReconnectSavedPlayerHint =>
      '보호자 모드에서 돌아온 뒤에는 저장된 선수 모드 Drive 계정으로 다시 연결할 수 있어요.';

  @override
  String get driveReconnectSavedPlayerMismatch =>
      '저장된 선수 모드 Drive 계정으로 다시 연결해 주세요.';

  @override
  String get driveSavedParentAccount => '저장된 보호자 모드 Drive';

  @override
  String get driveReconnectSavedParent => '저장된 보호자 모드 Drive 연결';

  @override
  String get driveReconnectSavedParentHint =>
      '보호자 모드에서 마지막으로 사용한 Drive 계정으로 다시 연결할 수 있어요.';

  @override
  String get driveReconnectSavedParentMismatch =>
      '저장된 보호자 모드 Drive 계정으로 다시 연결해 주세요.';

  @override
  String get driveSharedChildAccount => '백업 원본 Drive';

  @override
  String get driveSharedChildAccountEmpty =>
      '아직 백업 원본 정보가 없어요. 먼저 한 번 백업해 주세요.';

  @override
  String get driveSharedChildAccountRemoteBackup =>
      '원격 백업은 확인됐어요. 같은 Google Drive 계정으로 연결해 주세요.';

  @override
  String get familyChildDriveConnectionSummary =>
      '원본 백업이 있는 Google Drive 계정으로 연결해요.';

  @override
  String get familyParentUsesChildDriveSummary => '여기서는 원본 백업 Drive 계정을 사용해요.';

  @override
  String get familyParentUsesChildDriveHint =>
      '보호자 모드에서는 선수 데이터 원본이 있는 Google Drive 계정으로 로그인하면 훈련 피드백과 선물 이름을 같은 백업 파일에 동기화할 수 있어요.';

  @override
  String get familyParentUsesChildDriveWarning =>
      '보호자 모드에서는 선수 데이터 원본이 있는 Google Drive 계정으로 연결해야 같은 백업 파일에 훈련 피드백과 선물 이름을 안전하게 동기화할 수 있어요.';

  @override
  String get familySharedSyncTitle => '데이터 동기화 상태';

  @override
  String get familySharedSyncDescription =>
      '보호자 피드백과 레벨 선물 이름은 같은 선수 백업 파일로 자동 반영됩니다.';

  @override
  String get familySyncAlertTitle => '보호자 동기화';

  @override
  String familySyncParentTrainingAdded(int count) {
    return '선수 훈련기록 $count개가 새로 동기화됐어요.';
  }

  @override
  String familySyncParentRewardClaimed(int count) {
    return '선수가 받은 선물 $count개가 동기화됐어요.';
  }

  @override
  String familySyncParentTrainingAndRewardClaimed(
      int trainingCount, int rewardCount) {
    return '선수 훈련기록 $trainingCount개와 선물 수령 $rewardCount개가 동기화됐어요.';
  }

  @override
  String familySyncChildFeedbackAdded(int count) {
    return '보호자 피드백 $count개가 동기화됐어요.';
  }

  @override
  String get familySyncChildRewardUpdated => '레벨 선물 이름이 동기화됐어요.';

  @override
  String familySyncChildFeedbackAndReward(int count) {
    return '보호자 피드백 $count개와 레벨 선물 이름이 동기화됐어요.';
  }

  @override
  String get familySharedLastSync => '최근 보호자/선수 공유 동기화';

  @override
  String get familySharedLastPush => '최근 반영';

  @override
  String get familySharedLastRefresh => '최근 가져오기 확인';

  @override
  String get familySharedAutoRefreshDescription =>
      '보호자 모드로 들어오거나 앱으로 돌아오면 최신 상태를 자동으로 확인합니다. 아직 Drive에 반영하지 못한 로컬 변경이 있으면 자동 확인은 건너뜁니다.';

  @override
  String get familySharedPendingLocalChanges =>
      '아직 Drive에 반영하지 못한 로컬 변경이 있어 자동 가져오기를 잠시 보류하고 있어요.';

  @override
  String get familySharedRestore => '선수 데이터 가져오기';

  @override
  String get familySharedRestoreConfirm =>
      'Google Drive의 최신 선수 데이터를 가져올까요? 현재 기기에서 보이는 선수 기록과 공유 데이터가 교체됩니다.';

  @override
  String get familySharedRestoreSuccess => '선수 데이터를 가져왔어요.';

  @override
  String get familySharedRestoreFailed => '선수 데이터 가져오기에 실패했어요. 다시 시도해 주세요.';

  @override
  String get familySharedRestoreLocal => '이전 선수 데이터 가져오기';

  @override
  String get familySharedRestoreLocalConfirm =>
      '이 기기에서 마지막으로 가져온 선수 데이터 변경을 직전 상태로 되돌릴까요? 현재 기기에서 보이는 선수 기록과 공유 데이터가 교체됩니다.';

  @override
  String get familySharedRestoreLocalSuccess => '최근 가져오기를 취소했어요.';

  @override
  String get familySharedRestoreLocalFailed => '최근 가져오기 취소에 실패했어요. 다시 시도해 주세요.';

  @override
  String get restoreReconfirmTitle => '복원 재확인';

  @override
  String get restoreReconfirmBody => '정말 복원할까요? 현재 데이터는 백업 데이터로 교체됩니다.';

  @override
  String get familyParentFamilyMismatch =>
      '현재 연결한 Drive 백업이 이 보호자/선수 공유 데이터와 일치하지 않아요.';

  @override
  String get moreInfoAction => '자세히 보기';

  @override
  String get parentReadOnlyProfileSummary => '프로필은 읽기 전용이에요.';

  @override
  String get parentReadOnlyProfileDescription =>
      '보호자 모드에서는 프로필이 읽기 전용입니다. 훈련 피드백은 훈련기록에서, 레벨 선물 입력은 레벨 가이드에서 진행해 주세요.';

  @override
  String get parentReadOnlySettingsOptions =>
      '보호자 모드에서는 종목, 기본값, 뉴스 필터를 수정할 수 없어요. 선수 모드에서 변경해 주세요.';

  @override
  String get benchmarkReferencesTitle => '평균 기준';

  @override
  String get benchmarkRefreshAction => '평균 새로고침';

  @override
  String get benchmarkRefreshInProgress => '새로고침 중';

  @override
  String benchmarkLastSynced(Object date) {
    return '최근 동기화: $date';
  }

  @override
  String get benchmarkRefreshSuccess => '평균 기준 데이터를 업데이트했어요.';

  @override
  String get benchmarkRefreshFailed => '평균 기준 데이터 업데이트에 실패했어요. 네트워크를 확인해 주세요.';

  @override
  String get benchmarkReferenceNote =>
      '키와 체중은 CDC 성장 차트 중앙값, 활동 시간은 WHO 청소년 신체활동 권고를 기준으로 합니다. 종목별 보조 지표 범위는 앱의 훈련 참고값이며 의학 기준은 아닙니다.';

  @override
  String get benchmarkAgeTableTitle => '나이별 평균';

  @override
  String get benchmarkAgeTableNote =>
      '현재 나이가 있으면 해당 행을 강조합니다. 주간 목표 시간은 입력한 종목 경력 기준으로 조정됩니다.';

  @override
  String get benchmarkAgeColumnAge => '나이';

  @override
  String get benchmarkAgeColumnHeight => '키 평균';

  @override
  String get benchmarkAgeColumnWeight => '체중 평균';

  @override
  String get benchmarkAgeColumnLifting => '리프팅/세션';

  @override
  String benchmarkAgeColumnConditioning(Object metric) {
    return '$metric/세션';
  }

  @override
  String get benchmarkAgeColumnWeeklyTarget => '주간 목표';

  @override
  String benchmarkAgeValue(int age) {
    return '$age세';
  }

  @override
  String get benchmarkAgeCurrentBadge => '현재';

  @override
  String benchmarkAgeLiftingValue(int count) {
    return '$count회';
  }

  @override
  String benchmarkAgeWeeklyTargetValue(int minutes, int sessions) {
    return '$minutes분 · $sessions회';
  }

  @override
  String get parentReadOnlyEntryTitle => '보호자 모드에서는 훈련 노트를 수정할 수 없어요.';

  @override
  String get parentReadOnlyEntryBody =>
      '훈련, 식사, 다이어리 같은 핵심 기록은 선수 모드에서 작성해 주세요. 보호자 모드에서는 기록 원본은 건드리지 않고 피드백과 선물 입력만 따로 저장합니다.';

  @override
  String get parentReadOnlyLogsSummary => '훈련기록은 열람하고 피드백만 남겨요.';

  @override
  String get parentReadOnlyLogsBanner =>
      '보호자 모드에서는 훈련기록을 삭제하지 않아요. 기록을 열어 피드백을 남겨보세요.';

  @override
  String get parentReadOnlyLogsMessage => '보호자 모드에서는 훈련기록을 삭제할 수 없어요.';

  @override
  String get parentReadOnlyMealLogSummary => '식사 기록은 읽기 전용이에요.';

  @override
  String get parentReadOnlyMealLog =>
      '보호자 모드에서는 식사 기록을 수정할 수 없어요. 식사 입력은 선수 모드에서 진행해 주세요.';

  @override
  String get parentReadOnlyQuiz =>
      '보호자 모드에서는 퀴즈를 진행하지 않아요. 퀴즈 기록과 경험치는 선수 모드에서만 쌓입니다.';

  @override
  String get parentReadOnlyDrawerMessage =>
      '보호자 모드에서는 핵심 기록을 수정할 수 없어요. 공유 데이터와 선물 입력을 이용해 주세요.';

  @override
  String get parentReadOnlyCalendarSummary => '캘린더는 읽기 전용이에요.';

  @override
  String get parentReadOnlyCalendarBanner =>
      '보호자 모드에서는 캘린더를 읽기 전용으로 보여줍니다. 계획, 시합, 식사 수정은 선수 모드에서 진행해 주세요.';

  @override
  String get parentReadOnlyCalendarMessage => '보호자 모드에서는 캘린더를 수정할 수 없어요.';

  @override
  String get parentReadOnlyChallengeSummary => '챌린지는 읽기 전용이에요.';

  @override
  String get parentReadOnlyChallengeMessage =>
      '보호자 모드에서는 챌린지를 시작하거나 미션을 수정할 수 없어요. 선수 모드에서 진행한 챌린지 상태만 확인할 수 있습니다.';

  @override
  String get parentReadOnlyDiaryMessage => '보호자 모드에서는 다이어리를 수정할 수 없어요.';

  @override
  String get parentReadOnlyDiaryBadge => '보호자 모드 읽기 전용';

  @override
  String get parentReadOnlySketchMessage => '보호자 모드에서는 훈련 스케치를 수정할 수 없어요.';

  @override
  String get parentReadOnlyFortuneEmpty => '저장된 운세가 아직 없어요.';

  @override
  String get parentFeedbackSectionTitle => '보호자 피드백';

  @override
  String get parentFeedbackHelper =>
      '훈련 기록 원본은 수정하지 않고, 이 훈련에 대한 보호자 피드백만 따로 저장합니다.';

  @override
  String get parentFeedbackReadOnlyHint => '보호자가 이 훈련기록에 남긴 피드백입니다.';

  @override
  String get parentFeedbackInputLabel => '보호자 피드백 입력';

  @override
  String get parentFeedbackInputHint => '오늘 훈련에서 칭찬하고 싶은 점이나 다음에 챙길 점을 남겨보세요.';

  @override
  String get parentFeedbackSave => '피드백 저장';

  @override
  String get parentFeedbackClear => '지우기';

  @override
  String get parentFeedbackWriteAction => '피드백 입력';

  @override
  String get parentFeedbackEditAction => '피드백 수정';

  @override
  String get parentFeedbackViewAction => '피드백 보기';

  @override
  String get parentFeedbackDiscardTitle => '저장하지 않은 피드백';

  @override
  String get parentFeedbackDiscardBody => '저장하지 않은 피드백이 있어요. 정말 나가시겠어요?';

  @override
  String get parentFeedbackDiscardAction => '나가기';

  @override
  String get parentFeedbackSaved => '피드백을 저장했어요.';

  @override
  String get parentFeedbackSaveFailed => '피드백 저장에 실패했어요. 다시 시도해 주세요.';

  @override
  String get parentFeedbackCleared => '피드백을 지웠어요.';

  @override
  String get parentFeedbackEmpty => '아직 피드백이 없어요.';

  @override
  String get parentFeedbackReactionOnly => '선수가 리액션을 남겼어요.';

  @override
  String get parentFeedbackReactionLabel => '리액션';

  @override
  String get parentFeedbackReactionNone => '없음';

  @override
  String get parentFeedbackReactionThanks => '고마워요';

  @override
  String get parentFeedbackReactionProud => '뿌듯해요';

  @override
  String get parentFeedbackReactionReview => '다시 볼게요';

  @override
  String get parentFeedbackReactionTry => '다음에 해볼게요';

  @override
  String get parentFeedbackOpenExistingEntryTitle => '기존 훈련기록을 열어 피드백을 남겨주세요.';

  @override
  String get parentFeedbackOpenExistingEntryBody =>
      '보호자 모드에서는 새 훈련기록을 만들지 않고, 이미 저장된 훈련기록에만 보호자 피드백을 저장할 수 있어요. 선수 모드에서 먼저 기록을 남긴 뒤 해당 기록을 열어 주세요.';

  @override
  String get parentSharedSyncInProgress => '선수 Drive로 동기화 중이에요...';

  @override
  String get parentSharedSyncDone => '선수 Drive에도 동기화했어요.';

  @override
  String get parentSharedSyncPending => 'Drive 연결 후 같은 선수 백업 파일로 자동 동기화됩니다.';

  @override
  String get levelGuideParentModeLabel => '보호자 모드';

  @override
  String get levelGuideChildModeLabel => '선수 모드';

  @override
  String get levelGuideParentModeDescription =>
      '보호자 모드에서는 레벨 선물 이름만 저장할 수 있고, 저장한 선물 이름은 선수 Drive 공유에도 반영됩니다. 선물 수령 표시는 선수 모드에서 진행합니다.';

  @override
  String get levelGuideChildModeDescription =>
      '선수 모드에서는 받은 레벨 선물을 직접 표시할 수 있고, 선물 이름 입력은 보호자 모드에서 관리합니다.';

  @override
  String get levelGuideModeInfoTooltip => '모드 설명 보기';

  @override
  String get levelGuideClaimChildOnly => '선수 모드에서 수령';

  @override
  String get levelGuideRewardFallbackName => '선물';

  @override
  String levelGuideRewardClaimed(Object rewardName) {
    return '$rewardName 선물을 받았어요.';
  }

  @override
  String get levelGuideRewardSaved => '레벨 선물을 저장했어요.';

  @override
  String get levelGuideRewardCleared => '레벨 선물을 지웠어요.';

  @override
  String levelGuideMaxLevelRangeLabel(Object minXp) {
    return '$minXp XP 이상 · 최고 레벨';
  }

  @override
  String levelGuideMaxLevelMasteryHint(Object masterySpan) {
    return '다음 레벨은 없고, $masterySpan XP마다 마스터리 별을 계속 모읍니다.';
  }

  @override
  String get trainingPlanAddTitle => '훈련 계획 추가';

  @override
  String get trainingPlanEditTitle => '훈련 계획 수정';

  @override
  String get trainingPlanViewTitle => '훈련 계획 보기';

  @override
  String get matchAddTitle => '시합 등록';

  @override
  String get matchEditTitle => '시합 수정';

  @override
  String get matchViewTitle => '시합 보기';

  @override
  String get matchKindFriendly => '친선 경기';

  @override
  String get matchKindLeague => '리그 경기';

  @override
  String get matchKindTournament => '토너먼트';

  @override
  String get matchFriendlyResultLabel => '친선 경기 결과';

  @override
  String get matchResultLabel => '경기 결과';

  @override
  String get matchResultUnset => '미입력';

  @override
  String get matchResultWin => '승';

  @override
  String get matchResultDraw => '무';

  @override
  String get matchResultLoss => '패';

  @override
  String get matchLeagueSectionTitle => '리그 정보';

  @override
  String get matchTournamentSectionTitle => '토너먼트 정보';

  @override
  String get matchCompetitionNameLabel => '대회 이름';

  @override
  String get matchLeagueNameHint => '예) 주말 리그';

  @override
  String get matchTournamentNameHint => '예) 컵 대회';

  @override
  String get matchCompetitionSelectLabel => '저장된 대회';

  @override
  String get matchCompetitionStatusLabel => '대회 상태';

  @override
  String get matchCompetitionStatusActive => '진행 중';

  @override
  String get matchCompetitionStatusFinished => '종료';

  @override
  String matchCompetitionOptionActive(Object name) {
    return '$name · 진행 중';
  }

  @override
  String matchCompetitionOptionFinished(Object name) {
    return '$name · 종료';
  }

  @override
  String get matchCompetitionFinishedNotice =>
      '종료된 대회입니다. 이전 경기 기록을 정리할 때 선택하세요.';

  @override
  String get matchCompetitionManageButton => '팀 등록/결과 보기';

  @override
  String get matchCompetitionManagerNewTitle => '대회 관리';

  @override
  String matchCompetitionManagerTitle(String name) {
    return '$name 관리';
  }

  @override
  String get matchCompetitionTeamsTab => '팀 등록';

  @override
  String get matchCompetitionResultsTab => '결과 보기';

  @override
  String get matchCompetitionBackButton => '뒤로';

  @override
  String get matchCompetitionTeamPreviewTitle => '팀 미리보기';

  @override
  String get matchCompetitionTeamNameLabel => '팀 이름';

  @override
  String get matchCompetitionAddTeamButton => '추가';

  @override
  String get matchCompetitionTeamNameRequired => '팀 이름을 입력하세요.';

  @override
  String get matchCompetitionTeamAlreadyAdded => '이미 등록된 팀이에요.';

  @override
  String get matchCompetitionTeamsListTitle => '등록 팀';

  @override
  String matchCompetitionRemoveTeamTooltip(String team) {
    return '$team 삭제';
  }

  @override
  String get matchCompetitionTeamsInputLabel => '참가 팀';

  @override
  String get matchCompetitionTeamsInputHint => '한 줄에 한 팀씩 입력하거나 쉼표로 구분하세요';

  @override
  String matchCompetitionTeamCount(int count) {
    return '$count개 팀 등록됨';
  }

  @override
  String get matchCompetitionSaveTeams => '팀 저장';

  @override
  String get matchCompetitionNameRequired => '대회 이름을 입력하세요.';

  @override
  String get matchLeagueStandingsTitle => '리그 순위';

  @override
  String get matchTournamentBracketTitle => '토너먼트 대진표';

  @override
  String get matchCompetitionNoTeams => '등록된 팀이 없어요.';

  @override
  String get matchCompetitionNoMatches => '아직 기록된 경기가 없어요.';

  @override
  String get matchCompetitionMyTeamFallback => '우리 팀';

  @override
  String get matchTournamentByeLabel => '부전승';

  @override
  String matchTournamentPairLabel(int number) {
    return '$number경기';
  }

  @override
  String matchTournamentPairText(String teamA, String teamB) {
    return '$teamA vs $teamB';
  }

  @override
  String get matchTournamentRecordedProgressTitle => '기록된 진행';

  @override
  String matchTournamentRecordedProgress(
      String stage, String opponent, String outcome) {
    return '$stage · $opponent전 · $outcome';
  }

  @override
  String get matchLeagueRoundLabel => '라운드/주차';

  @override
  String get matchLeagueRoundHint => '예) 3라운드';

  @override
  String get matchTournamentStageLabel => '토너먼트 단계';

  @override
  String get matchTournamentStagePreliminary => '예선';

  @override
  String get matchTournamentStageRound16 => '16강';

  @override
  String get matchTournamentStageQuarterfinal => '8강';

  @override
  String get matchTournamentStageSemifinal => '4강';

  @override
  String get matchTournamentStageFinal => '결승';

  @override
  String get matchTournamentOutcomeLabel => '진행 결과';

  @override
  String get matchTournamentOutcomeOngoing => '진행 중';

  @override
  String get matchTournamentOutcomeAdvanced => '다음 라운드 진출';

  @override
  String get matchTournamentOutcomeEliminated => '탈락';

  @override
  String get matchTournamentOutcomeChampion => '우승';

  @override
  String get matchOpponentTeamLabel => '상대 팀';

  @override
  String get matchOpponentTeamHint => '예) 수원 U15';

  @override
  String get matchLeagueTeamsLabel => '리그 팀';

  @override
  String get matchLeagueTeamsHint => '한 줄에 한 팀씩 입력하거나 쉼표로 구분하세요';

  @override
  String get matchTournamentTeamsLabel => '토너먼트 팀';

  @override
  String get matchTournamentTeamsHint => '참가 팀을 한 줄에 한 팀씩 입력하거나 쉼표로 구분하세요';

  @override
  String get matchLeaguePointsMode => '승점';

  @override
  String get matchTournamentWinsMode => '토너먼트 승리';

  @override
  String get matchLeaguePointsLabel => '승점';

  @override
  String get matchTournamentWinsLabel => '토너먼트 승리';

  @override
  String matchLeaguePointsValue(int points) {
    return '승점 $points';
  }

  @override
  String matchTournamentWinsValue(int count) {
    return '$count승';
  }

  @override
  String get matchOurScoreLabel => '우리 점수';

  @override
  String get matchOpponentScoreLabel => '상대 점수';

  @override
  String get matchGoalsLabel => '골';

  @override
  String get matchAssistsLabel => '어시스트';

  @override
  String matchCountIncreaseTooltip(String label) {
    return '$label 늘리기';
  }

  @override
  String matchCountDecreaseTooltip(String label) {
    return '$label 줄이기';
  }

  @override
  String get matchMinutesPlayedLabel => '출전 시간(분)';

  @override
  String get matchMinutesPlayedHint => '예) 70';

  @override
  String get matchNoteOptionalLabel => '메모(선택)';

  @override
  String get matchShotsOnTargetLabel => '유효 슈팅';

  @override
  String get matchBallsWonLabel => '공을 뺏은 횟수';

  @override
  String get baseballMatchHitsLabel => '안타';

  @override
  String get baseballMatchRbisLabel => '타점';

  @override
  String get baseballMatchRunsLabel => '득점';

  @override
  String get baseballMatchDefensivePlaysLabel => '수비 처리';

  @override
  String get basketballMatchPointsLabel => '득점';

  @override
  String get basketballMatchAssistsLabel => '어시스트';

  @override
  String get basketballMatchReboundsLabel => '리바운드';

  @override
  String get basketballMatchStealsLabel => '스틸';

  @override
  String get tennisMatchGamesWonLabel => '따낸 게임';

  @override
  String get tennisMatchAcesLabel => '에이스';

  @override
  String get tennisMatchFirstServesInLabel => '첫 서브 성공';

  @override
  String get tennisMatchBreakPointsWonLabel => '브레이크 성공';

  @override
  String get calendarMatchXpSourceLabel => '시합 기록';

  @override
  String matchSavedWithXpFeedback(int count) {
    return '시합 저장 +$count XP';
  }

  @override
  String get trainingSketchControlsPanel => '도구와 선택';

  @override
  String get trainingSketchTacticalOverlay => '전술 구역 표시';

  @override
  String get trainingSketchPlayTooltip => '플레이';

  @override
  String get trainingSketchPlaybackSpeedTooltip => '재생 속도';

  @override
  String get trainingSketchAddSketchTooltip => '스케치 추가';

  @override
  String get trainingSketchCopySketchTooltip => '다른 스케치 복사 추가';

  @override
  String get trainingSketchDeleteSketchTooltip => '스케치 삭제';

  @override
  String get trainingSketchImportSketchTooltip => '이전 스케치 가져오기';

  @override
  String get trainingSketchRenameSketchTooltip => '스케치명 수정';

  @override
  String get trainingSketchMemoLabel => '훈련 스케치 메모';

  @override
  String get trainingSketchMemoHint => '예) 콘 사이 2터치 드리블 후 패스';

  @override
  String get trainingSketchVoiceInputTooltip => '음성 입력';

  @override
  String get trainingSketchConeButton => '콘';

  @override
  String get trainingSketchLowHurdleButton => '낮은 뜀틀';

  @override
  String get trainingSketchPlayerButton => '사람';

  @override
  String get trainingSketchBallButton => '공';

  @override
  String get trainingSketchLadderButton => '사다리';

  @override
  String get trainingSketchTargetButton => '목표';

  @override
  String get trainingSketchBaseButton => '베이스';

  @override
  String get trainingSketchBasketButton => '골대';

  @override
  String get trainingSketchPenButton => '펜';

  @override
  String get trainingSketchClearInkButton => '펜 지우기';

  @override
  String get trainingSketchResetButton => '초기화';

  @override
  String get trainingSketchPenModeHint => '펜 모드: 보드 영역을 드래그해 그릴 수 있습니다.';

  @override
  String get trainingSketchPenColorLabel => '펜 색상';

  @override
  String get trainingSketchQuickStart =>
      '빠른 시작: 선수를 선택하고 액션을 누른 뒤, 대상 사람이나 공간을 찍으세요.';

  @override
  String get trainingSketchSelectedItemTitle => '선택 요소';

  @override
  String get trainingSketchAssignColorLabel => '색상 지정';

  @override
  String get trainingSketchDrawRouteFirst => '먼저 이동선을 그리거나 선택해 주세요.';

  @override
  String get trainingSketchAddPlayerFirst => '먼저 사람 아이콘을 추가해 주세요.';

  @override
  String get trainingSketchAddBallFirst => '먼저 공 아이콘을 추가해 주세요.';

  @override
  String get trainingSketchRoutesButton => '동작';

  @override
  String get trainingSketchLinkRoutesInOrderButton => '전체 차례대로 연결';

  @override
  String get trainingSketchLinkRoutesInOrderSnack =>
      '이동선을 그린 순서대로 하나씩 시작하게 연결했어요.';

  @override
  String get trainingSketchLinkRoutesNeedTwoSnack => '연결하려면 이동선이 2개 이상 필요해요.';

  @override
  String get trainingSketchCreatedSnack => '훈련 스케치를 만들었어요.';

  @override
  String get trainingSketchSavedSnack => '훈련 스케치를 저장했습니다.';

  @override
  String get trainingSketchPreviousCopiedSnack => '이전 스케치를 복사했어요.';

  @override
  String get trainingSketchDuplicatedSnack => '스케치를 복제했어요.';

  @override
  String get trainingSketchCopiedFromAnotherSnack => '다른 스케치를 복사해 추가했습니다.';

  @override
  String get trainingSketchAutoStagesButton => '단계 자동 나누기';

  @override
  String get trainingSketchAutoStagesSnack => '이동선을 1단계부터 자동으로 나눴어요.';

  @override
  String get trainingSketchAutoStagesNeedTwoSnack =>
      '단계를 나누려면 이동선이 2개 이상 필요해요.';

  @override
  String get trainingSketchRouteStageTitle => '동작 단계';

  @override
  String trainingSketchRouteStageChip(Object stage) {
    return '$stage단계';
  }

  @override
  String get trainingSketchSelectRouteForStageHint =>
      '사람이나 공을 선택하면 이동선 단계를 바꿀 수 있어요.';

  @override
  String get trainingSketchPreviousStageButton => '이전 단계';

  @override
  String get trainingSketchNextStageButton => '다음 단계';

  @override
  String get trainingSketchRouteAfterBallButton => '공 뒤에 시작';

  @override
  String get trainingSketchFinishRouteButton => '이동선 완료';

  @override
  String get trainingSketchUndoLastRoutePointButton => '마지막 점 취소';

  @override
  String get trainingSketchClearAllRoutesButton => '동작선 전체 지우기';

  @override
  String get trainingSketchPlayerRoutesTitle => '사람 동작';

  @override
  String get trainingSketchBallRoutesTitle => '공 동작';

  @override
  String get trainingSketchRoutesEmpty => '아직 이 종류의 동작선이 없어요.';

  @override
  String get trainingSketchRedrawRouteButton => '선택 이동선 다시 그리기';

  @override
  String get trainingSketchDeleteRouteButton => '선택 이동선 삭제';

  @override
  String trainingSketchPlayerRouteChip(int index) {
    return '사람 $index';
  }

  @override
  String trainingSketchBallRouteChip(int index) {
    return '공 $index';
  }

  @override
  String get trainingSketchRouteReplaceHint =>
      '도착 지점을 누르고 이동선 완료를 누르면 선택한 이동선이 바뀝니다.';

  @override
  String get trainingSketchSelectedPlayerRouteHint =>
      '도착 지점을 누른 뒤 이동선 완료를 누르세요. 드래그로도 그릴 수 있어요.';

  @override
  String get trainingSketchSelectedBallRouteHint =>
      '패스 도착 지점을 누른 뒤 이동선 완료를 누르세요. 드래그로도 그릴 수 있어요.';

  @override
  String get trainingSketchPlayerRouteHint =>
      '사람을 선택하거나 보드를 눌러 시작한 뒤, 도착 지점을 누르고 완료하세요.';

  @override
  String get trainingSketchBallRouteHint =>
      '공을 선택하거나 보드를 눌러 시작한 뒤, 패스 도착 지점을 누르고 완료하세요.';

  @override
  String get trainingSketchLinkPlayerHint =>
      '액션을 누른 뒤 도착 지점이나 대상 사람을 찍으세요. 공이 필요한 액션은 선수 옆에 공을 자동으로 만들어요.';

  @override
  String get trainingSketchLinkBallHint =>
      '공만 따로 움직이고 싶을 때 사용하세요. 선수 액션을 쓰면 필요한 공 움직임이 함께 만들어져요.';

  @override
  String trainingSketchActionTargetHint(Object action) {
    return '$action 대상이나 공간을 누르세요.';
  }

  @override
  String get trainingSketchActionTargetCancelButton => '취소';

  @override
  String get trainingSketchSelectedItemActionsTitle => '빠른 동작';

  @override
  String get trainingSketchPlayerActionsTitle => '선수 액션';

  @override
  String get trainingSketchBallActionsTitle => '공 액션';

  @override
  String get trainingSketchCreateMoveRouteButton => '이동 만들기';

  @override
  String get trainingSketchCreatePassRouteButton => '패스 만들기';

  @override
  String get trainingSketchQuickMoveButton => '이동';

  @override
  String get trainingSketchQuickPassButton => '패스';

  @override
  String get trainingSketchQuickPassAndMoveButton => '패스 후 이동';

  @override
  String get trainingSketchQuickDribbleButton => '드리블';

  @override
  String get trainingSketchQuickReceiveMoveButton => '공 받고 이동';

  @override
  String get trainingSketchQuickReturnMoveButton => '돌아오기';

  @override
  String get trainingSketchQuickOverlapButton => '오버랩';

  @override
  String get trainingSketchQuickShotButton => '슈팅';

  @override
  String get trainingSketchQuickCrossButton => '크로스';

  @override
  String get trainingSketchQuickDriveButton => '드라이브';

  @override
  String get trainingSketchQuickCutButton => '컷인';

  @override
  String get trainingSketchQuickScreenButton => '스크린';

  @override
  String get trainingSketchQuickRunBaseButton => '베이스 러닝';

  @override
  String get trainingSketchQuickFieldingButton => '수비 이동';

  @override
  String get trainingSketchQuickThrowButton => '송구';

  @override
  String get trainingSketchQuickServeButton => '서브';

  @override
  String get trainingSketchQuickRallyButton => '랠리';

  @override
  String get trainingSketchQuickRecoverButton => '리커버리';

  @override
  String trainingSketchPassToPlayerButton(int index) {
    return '사람 $index에게 패스';
  }

  @override
  String trainingSketchThrowToPlayerButton(int index) {
    return '사람 $index에게 송구';
  }

  @override
  String trainingSketchRallyToPlayerButton(int index) {
    return '사람 $index에게 랠리';
  }

  @override
  String get trainingSketchPlayerRouteLimitReached =>
      '모든 사람 동작선이 이미 있어요. 사람을 선택해서 동작선을 바꾸거나 다시 그려 주세요.';

  @override
  String get trainingSketchBallRouteLimitReached =>
      '모든 공 동작선이 이미 있어요. 공을 선택해서 동작선을 바꾸거나 다시 그려 주세요.';

  @override
  String get trainingSketchTemplatePickerTitle => '템플릿 선택';

  @override
  String get trainingSketchTemplateBlankLabel => '빈 스케치';

  @override
  String get trainingSketchTemplateBlankDescription => '아무 요소 없이 바로 시작';

  @override
  String get trainingSketchTemplatePassWarmupLabel => '패스 워밍업';

  @override
  String get trainingSketchTemplatePassWarmupDescription => '기본 3인 패스 구조';

  @override
  String get trainingSketchTemplatePassWarmupMethod => '2터치 패스 + 움직임 교대';

  @override
  String get trainingSketchTemplateBuildUpLabel => '빌드업 패턴';

  @override
  String get trainingSketchTemplateBuildUpDescription => '후방 전개 기본 구조';

  @override
  String get trainingSketchTemplateBuildUpMethod => '후방 빌드업 3-2 전개';

  @override
  String get trainingSketchTemplatePressingLabel => '압박 전환';

  @override
  String get trainingSketchTemplatePressingDescription => '전방 압박 시작 위치';

  @override
  String get trainingSketchTemplatePressingMethod => '전방 압박 트리거 확인';

  @override
  String get trainingSketchTemplateSetPieceLabel => '세트피스';

  @override
  String get trainingSketchTemplateSetPieceDescription => '코너킥 기본 배치';

  @override
  String get trainingSketchTemplateSetPieceMethod => '코너킥 공격 패턴';

  @override
  String get trainingSketchTemplateRondoLabel => '론도';

  @override
  String get trainingSketchTemplateRondoDescription => '4대1 볼 돌리기 구조';

  @override
  String get trainingSketchTemplateRondoMethod => '4대1 론도, 2터치 제한';

  @override
  String get trainingSketchTemplateFinishingLabel => '마무리 슈팅';

  @override
  String get trainingSketchTemplateFinishingDescription => '크로스 후 박스 침투 마무리';

  @override
  String get trainingSketchTemplateFinishingMethod => '측면 전개 후 박스 침투 슈팅';

  @override
  String get trainingSketchTemplateWingCombinationLabel => '측면 연계';

  @override
  String get trainingSketchTemplateWingCombinationDescription =>
      '윙어와 풀백 오버래핑 패턴';

  @override
  String get trainingSketchTemplateWingCombinationMethod => '윙어-풀백 오버래핑 후 컷백';

  @override
  String get trainingSketchTemplateTransitionAttackLabel => '전환 공격';

  @override
  String get trainingSketchTemplateTransitionAttackDescription =>
      '볼 탈취 직후 빠른 전개';

  @override
  String get trainingSketchTemplateTransitionAttackMethod => '볼 탈취 후 6초 안에 전진';

  @override
  String get trainingSketchTemplateBaseballThrowingLabel => '송구 릴레이';

  @override
  String get trainingSketchTemplateBaseballThrowingDescription =>
      '캐치볼과 송구 연결 기본 배치';

  @override
  String get trainingSketchTemplateBaseballThrowingMethod =>
      '포구 후 목표 지점으로 빠르게 송구';

  @override
  String get trainingSketchTemplateBaseballBattingLabel => '타격 후 주루';

  @override
  String get trainingSketchTemplateBaseballBattingDescription =>
      '타격 방향과 1루 진입 흐름';

  @override
  String get trainingSketchTemplateBaseballBattingMethod =>
      '컨택 후 타구 방향 확인, 1루까지 전력 주루';

  @override
  String get trainingSketchTemplateBaseballFieldingLabel => '수비 처리';

  @override
  String get trainingSketchTemplateBaseballFieldingDescription =>
      '타구 반응과 중계 송구 구조';

  @override
  String get trainingSketchTemplateBaseballFieldingMethod =>
      '첫 반응 후 포구, 중계 지점으로 정확히 송구';

  @override
  String get trainingSketchTemplateBasketballShootingLabel => '슛 스팟';

  @override
  String get trainingSketchTemplateBasketballShootingDescription =>
      '드라이브와 슈팅 위치 기본 배치';

  @override
  String get trainingSketchTemplateBasketballShootingMethod =>
      '패스 수신 후 스텝 정리, 지정 스팟에서 슛';

  @override
  String get trainingSketchTemplateBasketballPassingLabel => '패스 컷';

  @override
  String get trainingSketchTemplateBasketballPassingDescription =>
      '컷인과 패스 타이밍 연결';

  @override
  String get trainingSketchTemplateBasketballPassingMethod =>
      '컷인 움직임에 맞춰 패스 타이밍을 맞추기';

  @override
  String get trainingSketchTemplateBasketballDefenseLabel => '수비 슬라이드';

  @override
  String get trainingSketchTemplateBasketballDefenseDescription =>
      '좌우 슬라이드와 압박 위치';

  @override
  String get trainingSketchTemplateBasketballDefenseMethod =>
      '상대 앞을 유지하며 좌우 슬라이드 반복';

  @override
  String get trainingSketchTemplateTennisServeLabel => '서브 코스';

  @override
  String get trainingSketchTemplateTennisServeDescription => '서브 방향과 리커버리 위치';

  @override
  String get trainingSketchTemplateTennisServeMethod => '목표 코스로 서브 후 중앙으로 리커버리';

  @override
  String get trainingSketchTemplateTennisRallyLabel => '크로스 랠리';

  @override
  String get trainingSketchTemplateTennisRallyDescription => '크로스 방향 랠리와 복귀';

  @override
  String get trainingSketchTemplateTennisRallyMethod =>
      '크로스로 보내고 다음 공을 위해 중앙으로 복귀';

  @override
  String get trainingSketchTemplateTennisFootworkLabel => '풋워크 패턴';

  @override
  String get trainingSketchTemplateTennisFootworkDescription => '스플릿 스텝과 좌우 이동';

  @override
  String get trainingSketchTemplateTennisFootworkMethod =>
      '스플릿 스텝 후 좌우 이동, 중심으로 회복';

  @override
  String get trainingSketchTemplateGalleryAction => '템플릿 보기';

  @override
  String get trainingSketchTemplateGalleryTitle => '훈련 템플릿 갤러리';

  @override
  String get trainingSketchTemplateGallerySubtitle =>
      '스케치를 만들기 전에 이동선과 메모 구성을 미리 확인하세요.';

  @override
  String get challengeTitle => '챌린지';

  @override
  String get challengeRewardAction => '보상';

  @override
  String get challengeHistoryAction => '히스토리';

  @override
  String get challengeStartHeroTitle => '린지의 챌린지 모드';

  @override
  String get challengeStartHeroBody =>
      '기간과 미션별 훈련량을 고른 뒤 시작 버튼을 누르면 도전이 시작됩니다. 하루라도 놓치면 실패예요.';

  @override
  String get challengeLatestComplete => '최근 챌린지 완료';

  @override
  String get challengeSelectTitle => '챌린지 선택';

  @override
  String get challengeDurationSelectTitle => '1. 기간 선택';

  @override
  String get challengeTemplateStarterTitle => '3일 챌린지';

  @override
  String get challengeTemplateStarterDescription => '짧게 집중해서 챌린지 감각을 익힙니다.';

  @override
  String get challengeTemplateWeeklyTitle => '7일 챌린지';

  @override
  String get challengeTemplateWeeklyDescription => '일주일 동안 매일 루틴을 이어갑니다.';

  @override
  String get challengeTemplateFocusTitle => '14일 챌린지';

  @override
  String get challengeTemplateFocusDescription => '2주 동안 꾸준함을 길게 쌓습니다.';

  @override
  String get challengeDifficultySprout => '새싹';

  @override
  String get challengeDifficultyBoost => '쑥쑥';

  @override
  String get challengeDifficultyStar => '스타';

  @override
  String get challengeTrainingLevelTitle => '2. 단계 선택';

  @override
  String get challengeTrainingLevelRookieTitle => '루키 레벨';

  @override
  String get challengeTrainingLevelRookieDescription =>
      '저학년이거나 축구를 막 시작한 선수에게 맞춘 가벼운 목표입니다.';

  @override
  String get challengeTrainingLevelGrowthTitle => '쑥쑥 레벨';

  @override
  String get challengeTrainingLevelGrowthDescription =>
      '기본기가 잡히고 꾸준히 훈련하는 선수에게 맞춘 표준 목표입니다.';

  @override
  String get challengeTrainingLevelAceTitle => '에이스 레벨';

  @override
  String get challengeTrainingLevelAceDescription =>
      '나이와 축구 구력이 쌓인 선수에게 맞춘 도전적인 목표입니다.';

  @override
  String get challengeRecommendedLevelBadge => '추천';

  @override
  String get challengeSkillSelectTitle => '2. 미션 선택';

  @override
  String get challengeSkillSelectSubtitle =>
      '챌린지에 넣을 훈련 프로그램, 보조 훈련, 식사 미션을 고르고 목표 훈련량을 조정하세요.';

  @override
  String get challengeMissionOtherSectionTitle => '추가 미션';

  @override
  String get challengeMissionTargetsTitle => '미션별 목표량';

  @override
  String get challengeMissionTargetsSubtitle => '선택한 미션마다 매일 채울 기준을 고르세요.';

  @override
  String get challengeTrainingProgramLinkTitle => '훈련 프로그램 편집';

  @override
  String get challengeTrainingProgramLinkBody =>
      '설정 화면의 기본값에서 훈련 프로그램 옵션을 바로 편집해요.';

  @override
  String get challengeTrainingProgramLinkAction => '열기';

  @override
  String get challengeTrainingProgramMissionLabel => '훈련 프로그램';

  @override
  String get challengeMissionSummaryTitle => '선택한 미션';

  @override
  String challengeMissionProgramSummary(Object label, Object programs) {
    return '$label: $programs';
  }

  @override
  String challengeRiceBowlsOption(Object bowls) {
    return '$bowls그릇';
  }

  @override
  String get challengeSkillDribble => '드리블';

  @override
  String get challengeSkillSpeedRun => '스피드 달리기';

  @override
  String get challengeSkillJumpRope => '줄넘기';

  @override
  String get challengeSkillLifting => '리프팅';

  @override
  String get challengeSkillPassing => '패스';

  @override
  String get challengeSkillShooting => '슈팅';

  @override
  String get challengeSkillFirstTouch => '퍼스트 터치';

  @override
  String get challengeSkillDefense => '수비';

  @override
  String challengeLevelTrainingTargetLabel(int minutes) {
    return '총 훈련 $minutes분';
  }

  @override
  String challengeLevelJumpRopeTargetLabel(int minutes) {
    return '줄넘기 $minutes분';
  }

  @override
  String challengeLevelLiftingTargetLabel(int minutes) {
    return '리프팅 $minutes분';
  }

  @override
  String challengeDaysLabel(int days) {
    return '$days일';
  }

  @override
  String challengeRewardXp(int xp) {
    return '+$xp XP';
  }

  @override
  String challengeRoundXpLabel(int xp) {
    return '라운드 +$xp XP';
  }

  @override
  String challengeStreakBonusLabel(int xp) {
    return '연속 보너스 +$xp XP';
  }

  @override
  String challengeActiveLevelPill(Object level) {
    return '레벨: $level';
  }

  @override
  String get challengeInfoStatusLabel => '상태';

  @override
  String get challengeInfoLevelLabel => '단계';

  @override
  String get challengeInfoRoundXpLabel => '라운드 보상';

  @override
  String get challengeInfoPotentialXpLabel => '챌린지 보상';

  @override
  String get challengeInfoPeriodLabel => '기간';

  @override
  String get challengeInfoRoundProgressLabel => '라운드 진행';

  @override
  String challengePotentialXpPill(int xp) {
    return '쌓을 수 있는 XP +$xp';
  }

  @override
  String challengeCompletionBonusLabel(int xp) {
    return '완주 보너스 +$xp XP';
  }

  @override
  String challengeTotalXpLabel(int xp) {
    return '최대 +$xp XP';
  }

  @override
  String get challengeRewardPitchTitle => '완주하면 큰 보너스가 기다려요';

  @override
  String get challengeRewardGuideTitle => '챌린지 보상';

  @override
  String get challengeRewardGuideBody =>
      '라운드를 연속으로 완료할수록 라운드 보상이 커져요. 챌린지를 끝까지 완주하면 완주 보너스도 더해집니다.';

  @override
  String get challengeRewardGuideNoActive =>
      '진행 중인 챌린지가 없어요. 챌린지를 시작하면 획득한 XP와 남은 XP를 볼 수 있어요.';

  @override
  String get challengeRewardGuideActiveTitle => '현재 챌린지';

  @override
  String get challengeRewardGuideTemplatesTitle => '챌린지별 보상 계획';

  @override
  String challengeRewardGuideTemplateTitle(Object title) {
    return '$title 보상 계획';
  }

  @override
  String get challengeRewardGuideHistoryTitle => '보상 계획';

  @override
  String get challengeRewardGuideBaseRoundLabel => '기본 라운드';

  @override
  String get challengeRewardGuideStreakBonusLabel => '최대 연속 보너스';

  @override
  String get challengeRewardGuideRoundTotalLabel => '라운드 합계';

  @override
  String get challengeRewardGuideFinishBonusLabel => '완주 보너스';

  @override
  String get challengeRewardGuidePotentialLabel => '최대 XP';

  @override
  String get challengeRewardGuideEarnedLabel => '현재 획득';

  @override
  String get challengeRewardGuideRemainingLabel => '남은 XP';

  @override
  String get challengeRewardGuideRoundsTitle => '라운드 보상';

  @override
  String challengeRewardGuideRoundReward(int round, int xp) {
    return '라운드 $round: +$xp XP';
  }

  @override
  String challengeRewardGuideRoundRewardWithBonus(
      int round, int xp, int bonus) {
    return '라운드 $round: +$xp XP (연속 +$bonus)';
  }

  @override
  String get challengeStartReadyTitle => '3. 시작 준비';

  @override
  String get challengeStartAction => '챌린지 시작';

  @override
  String challengeRoundCount(int completed, int total) {
    return '$completed/$total 라운드 완료';
  }

  @override
  String challengeMissionCount(int completed, int total) {
    return '$completed/$total 미션 완료';
  }

  @override
  String challengeProgressPercent(int percent) {
    return '$percent% 완료';
  }

  @override
  String challengeTodayRoundTitle(int round) {
    return '오늘 · $round라운드';
  }

  @override
  String challengeUpcomingRoundTitle(int round) {
    return '다음 · $round라운드';
  }

  @override
  String get challengeRoundsTitle => '라운드';

  @override
  String challengeRoundTitle(int round) {
    return '$round라운드';
  }

  @override
  String get challengeTrainingLabel => '훈련';

  @override
  String get challengeJumpRopeLabel => '줄넘기';

  @override
  String get challengeLiftingLabel => '리프팅';

  @override
  String get challengeMealLabel => '식사';

  @override
  String challengeTrainingGoalValue(int current, int target) {
    return '$current/$target분';
  }

  @override
  String challengeMealGoalValue(Object current, Object target) {
    return '$current/$target그릇';
  }

  @override
  String get challengeCompletedBadge => '완료';

  @override
  String get challengePendingBadge => '진행 중';

  @override
  String challengeCompletedSummary(Object title) {
    return '$title 완료';
  }

  @override
  String get challengeRoundDateToday => '오늘';

  @override
  String challengeStartSnack(Object title) {
    return '$title를 시작했어요.';
  }

  @override
  String challengeAwardSnack(int xp) {
    return '챌린지 라운드 완료 +$xp XP';
  }

  @override
  String get challengeCompletedSnack => '챌린지를 완료했어요.';

  @override
  String challengeFailedSnack(int round) {
    return '$round라운드를 놓쳐 챌린지가 실패로 끝났어요.';
  }

  @override
  String challengeFailureTitle(int round) {
    return '$round라운드에서 멈췄어요';
  }

  @override
  String get challengeFailureSimpleTitle => '오늘은 린지가 속상해요';

  @override
  String get challengeFailureBody => '린지가 아쉬워해요. 그래도 다음 도전은 더 힘차게 시작할 수 있어요.';

  @override
  String get challengeFailureAction => '라운드 확인';

  @override
  String get challengeCelebrationTitle => '미션 완료!';

  @override
  String challengeCelebrationBody(int rounds, int xp) {
    return '$rounds라운드 완료! 린지가 박수를 보내요. +$xp XP를 받았어요.';
  }

  @override
  String get challengeCelebrationBodyNoXp => '라운드 미션을 완료했어요. 기록을 확인하세요.';

  @override
  String get challengeCelebrationCompleteTitle => '챌린지 완주!';

  @override
  String challengeCelebrationCompleteBody(int xp) {
    return '모든 라운드를 끝까지 해냈어요. 꾸준함이 진짜 실력이 되고 있어요. +$xp XP를 받았어요.';
  }

  @override
  String get challengeCelebrationCompleteBodyNoXp =>
      '모든 미션 기록이 끝났어요. 끝까지 해낸 흐름을 다음 챌린지로 이어가 보세요.';

  @override
  String get challengeCelebrationMissionsTitle => '수행한 미션';

  @override
  String get challengeCelebrationAction => '좋아!';

  @override
  String get challengeCelebrationNextChallengeAction => '다음 챌린지 만들기';

  @override
  String get challengeFinishedPraiseTitle => '끝까지 해낸 챌린지예요';

  @override
  String challengeFinishedPraiseBody(Object title, int rounds) {
    return '$title에서 $rounds라운드를 모두 완주했어요. 이 꾸준함을 다음 챌린지로 이어가 볼까요?';
  }

  @override
  String challengeFinishedCompletedRoundsLabel(int rounds) {
    return '$rounds라운드 완주';
  }

  @override
  String get challengeFinishedNextPrompt => '아래에서 다음 챌린지를 선택해요';

  @override
  String get challengeHistoryTitle => '챌린지 히스토리';

  @override
  String get challengeHistorySummaryTitle => '챌린지 요약';

  @override
  String get challengeHistoryListTitle => '챌린지 기록';

  @override
  String get challengeHistorySummaryTotalLabel => '전체';

  @override
  String get challengeHistorySummarySuccessLabel => '성공';

  @override
  String get challengeHistorySummaryLatestLabel => '최근';

  @override
  String get challengeHistoryEmpty => '아직 챌린지 기록이 없어요.';

  @override
  String challengeHistoryStarted(Object date) {
    return '$date 시작';
  }

  @override
  String challengeHistoryFailedRound(Object date, int round) {
    return '$date 시작 · $round라운드 실패';
  }

  @override
  String get challengeHistoryResultCompleted => '성공';

  @override
  String get challengeHistoryResultFailed => '실패';

  @override
  String get challengeHistoryResultAbandoned => '종료';

  @override
  String get challengeHistoryResultInProgress => '진행 중';

  @override
  String challengeHistoryRoundSuccessCount(int success, int total) {
    return '성공 $success/$total';
  }

  @override
  String challengeHistoryRoundFailureCount(int failure, int total) {
    return '실패 $failure/$total';
  }

  @override
  String get challengeHistoryDetailTitle => '챌린지 상세';

  @override
  String get challengeHistoryDetailCompletedBody =>
      '모든 라운드를 완료했어요. 보상 계획과 라운드 날짜를 확인해요.';

  @override
  String challengeHistoryDetailFailedBody(int round) {
    return '이 챌린지는 $round라운드에서 멈췄어요. 라운드 흐름과 보상 계획을 확인해요.';
  }

  @override
  String get challengeHistoryDetailAbandonedBody =>
      '완료 전에 종료된 챌린지예요. 원래 라운드 계획을 확인해요.';

  @override
  String challengeHistoryDetailPeriodValue(Object start, Object end) {
    return '$start - $end';
  }

  @override
  String get challengeHistoryDetailMissionsLabel => '미션';

  @override
  String get challengeHistoryDetailEarnedXpLabel => '획득 XP';

  @override
  String get challengeHistoryDetailNoMissions => '추가 미션만';

  @override
  String get challengeHistoryDetailRoundsTitle => '라운드 상세';

  @override
  String challengeHistoryDetailRoundDate(int round, Object date) {
    return '라운드 $round · $date';
  }

  @override
  String get challengeHistoryDetailRoundCompleted => '완료';

  @override
  String get challengeHistoryDetailRoundFailed => '여기서 실패';

  @override
  String get challengeHistoryDetailRoundEnded => '미집계';

  @override
  String get challengeAbandonAction => '종료';

  @override
  String get challengeAbandonTitle => '챌린지 종료';

  @override
  String get challengeAbandonBody => '현재 챌린지를 종료하고 다른 챌린지를 선택할까요?';

  @override
  String get challengeAbandonConfirm => '종료';

  @override
  String get homeChallengeEmptyBody => '린지와 함께 챌린지를 시작하세요.';

  @override
  String homeChallengeActiveBody(int completed, int total, int round) {
    return '$completed/$total 완료 · 오늘 $round라운드';
  }

  @override
  String xpHistoryChallengeRound(Object label) {
    return '챌린지 라운드 · $label';
  }

  @override
  String get xpHistoryReasonChallengeRoundCompleted => '챌린지 라운드 완료';

  @override
  String get xpHistoryReasonChallengeRoundStreakBonus => '챌린지 연속 보너스';

  @override
  String get xpHistoryReasonChallengeCompletionBonus => '챌린지 완주 보너스';
}
