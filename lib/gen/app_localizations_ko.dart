// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Korean (`ko`).
class AppLocalizationsKo extends AppLocalizations {
  AppLocalizationsKo([String locale = 'ko']) : super(locale);

  @override
  String get appTitle => '태오의노트';

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
  String get startupLoadingTitle => '앱을 준비하고 있어요';

  @override
  String get startupLoadingBody => '기록과 설정을 불러오는 중입니다. 잠시만 기다려 주세요.';

  @override
  String get startupErrorTitle => '앱을 시작하지 못했어요';

  @override
  String get startupErrorBody =>
      '초기 데이터를 불러오는 중 문제가 생겼습니다. 다시 시도해도 계속 멈추면 앱을 완전히 종료한 뒤 다시 열어 주세요.';

  @override
  String get startupErrorDetailsLabel => '오류 정보';

  @override
  String get startupErrorStepLabel => '단계';

  @override
  String get startupErrorMessageLabel => '메시지';

  @override
  String get startupRetryAction => '다시 시도';

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
  String get welcomeCalendarStepPlus =>
      '+ 버튼으로 선택한 날짜에 계획, 시합, 훈련 노트, 식사를 추가해요.';

  @override
  String get welcomeCalendarStepMeal => '같은 날짜의 식사 기록도 함께 남겨 회복 흐름을 맞춰요.';

  @override
  String get welcomeStatsOverview => '통계는 기록이 쌓인 뒤 다음 훈련 목표를 정하는 화면입니다.';

  @override
  String get welcomeStatsStepPeriod => '기간을 바꿔 이번 주, 지난주, 원하는 범위를 비교해요.';

  @override
  String get welcomeStatsStepAverage => '훈련과 시합 탭을 바꿔 보며 기록 흐름을 나누어 확인해요.';

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
  String get welcomeDiaryStepSticker => '새 다이어리를 열어 오늘의 제목과 이야기를 남겨요.';

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
  String get notificationAppTitle => '태오의노트';

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
  String get newsLoadFailedMessage => '뉴스를 불러오지 못했습니다. 아래로 당겨 새로고침 해주세요.';

  @override
  String get newsNoChannelArticles => '선택한 채널의 뉴스가 없습니다.';

  @override
  String get newsNoScrappedArticles => '스크랩한 소식이 없습니다.';

  @override
  String get newsNoResultsFound => '검색 결과가 없습니다.';

  @override
  String get newsScrapTooltip => '스크랩';

  @override
  String get newsRemoveScrapTooltip => '스크랩 해제';

  @override
  String get newsScrappedSnack => '소식을 스크랩했어요.';

  @override
  String get newsScrapRemovedSnack => '스크랩을 해제했어요.';

  @override
  String get newsTranslationGuideSnack => '기사 화면 우측 상단 메뉴에서 번역 기능을 사용할 수 있어요.';

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
  String get worldCupShareTooltip => '월드컵 페이지 공유';

  @override
  String worldCupShareMessage(String url) {
    return '태오의노트 월드컵 페이지에서 2026 월드컵 일정, 순위, 토너먼트 대진표를 같이 봐요.\n$url';
  }

  @override
  String get worldCupShareOpenedSnack => '월드컵 공유를 준비했어요.';

  @override
  String get worldCupShareFailedSnack => '월드컵 공유를 열지 못했어요.';

  @override
  String get worldCupPdfAction => 'PDF';

  @override
  String get worldCupImageAction => '이미지';

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
  String get worldCupStandingsTab => '조별리그';

  @override
  String get worldCupRankingsTab => '기록 순위';

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
  String worldCupScorePenaltyLine(int homePenaltyScore, int awayPenaltyScore) {
    return '승부차기 $homePenaltyScore : $awayPenaltyScore';
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
  String get worldCupRankingsTitle => '월드컵 순위';

  @override
  String get worldCupRankingsIntro =>
      'FIFA 공식 매치 상세에서 확인되는 선수 기록을 모아 보여줘요. 득점은 공식 득점자 목록으로, 어시스트는 FIFA가 도움 선수 ID를 제공한 경기만 집계하고, 옐로카드와 레드카드는 공식 카드 기록으로 집계합니다.';

  @override
  String get worldCupRankingsSourceMatchesLabel => '집계 경기';

  @override
  String worldCupRankingsSourceMatchesValue(int count) {
    return '$count경기';
  }

  @override
  String get worldCupRankingsUpdatedLabel => '업데이트';

  @override
  String get worldCupRankingsLoading => 'FIFA 선수 기록을 불러오고 있어요...';

  @override
  String get worldCupGoalRankingsTitle => '득점 순위';

  @override
  String get worldCupAssistRankingsTitle => '어시스트 순위';

  @override
  String get worldCupDisciplineRankingsTitle => '경고/퇴장 순위';

  @override
  String get worldCupYellowCardRankingsTitle => '옐로카드 순위';

  @override
  String get worldCupRedCardRankingsTitle => '레드카드 순위';

  @override
  String get worldCupRankingsNoOfficialMatches =>
      '아직 집계할 공식 종료 경기가 없습니다. FIFA 데이터가 들어오면 자동으로 채워져요.';

  @override
  String get worldCupGoalRankingsEmpty =>
      '공식 득점자 상세가 아직 없습니다. 경기 상세가 업데이트되면 득점 순위가 채워져요.';

  @override
  String get worldCupAssistRankingsEmpty =>
      'FIFA가 도움 선수 ID를 제공한 경기만 집계할 수 있어 현재 표시할 어시스트가 없습니다.';

  @override
  String get worldCupDisciplineRankingsEmpty =>
      'FIFA 공식 경고/퇴장 기록이 아직 없어 표시할 징계 순위가 없습니다.';

  @override
  String get worldCupYellowCardRankingsEmpty =>
      'FIFA 공식 옐로카드 기록이 아직 없어 표시할 선수가 없습니다.';

  @override
  String get worldCupRedCardRankingsEmpty =>
      'FIFA 공식 레드카드 기록이 아직 없어 표시할 선수가 없습니다.';

  @override
  String worldCupRankingsGoalCount(int count) {
    return '$count골';
  }

  @override
  String worldCupRankingsAssistCount(int count) {
    return '$count도움';
  }

  @override
  String worldCupRankingsDisciplineCount(int yellowCards, int redCards) {
    return '경고 $yellowCards · 퇴장 $redCards';
  }

  @override
  String worldCupRankingsYellowCardCount(int count) {
    return '$count장';
  }

  @override
  String worldCupRankingsRedCardCount(int count) {
    return '$count장';
  }

  @override
  String get worldCupYellowCardLabel => '경고';

  @override
  String get worldCupRedCardLabel => '퇴장';

  @override
  String worldCupRankingsEventWithMinute(String opponent, String minute) {
    return '$opponent전 $minute';
  }

  @override
  String worldCupRankingsCardEventWithMinute(
      String opponent, String minute, String card) {
    return '$opponent전 $minute $card';
  }

  @override
  String worldCupRankingsMoreEvents(int count) {
    return '외 $count개';
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
  String get worldCupTeamRosterSubtitle => '포지션별 명단에서 직접 베스트 11과 포메이션을 구성해요.';

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
  String get worldCupKnockoutPathTitle => '결승까지의 상대';

  @override
  String get worldCupKnockoutPathSubtitle =>
      '이 팀이 각 라운드를 통과한다고 가정하고 결승까지 만날 수 있는 상대 후보를 보여줘요.';

  @override
  String worldCupKnockoutPathCandidateCount(int count) {
    return '$count팀 후보';
  }

  @override
  String get worldCupKnockoutPathOpponentPending => '상대 확정 전';

  @override
  String get worldCupKnockoutPathEliminated => '이 라운드에서 탈락';

  @override
  String get worldCupQualificationScenariosTitle => '32강 경우의 수';

  @override
  String worldCupQualificationScenariosSubtitle(
      int currentPoints, int remainingMatches) {
    return '현재 승점 $currentPoints점에서 남은 $remainingMatches경기 결과 조합별 32강 진출 가능성과 상대 후보를 계산해요.';
  }

  @override
  String worldCupQualificationScenariosOneMatchSubtitle(int currentPoints) {
    return '현재 승점 $currentPoints점에서 마지막 1경기의 승·무·패별 32강 진출 가능성과 상대 후보를 계산해요.';
  }

  @override
  String worldCupQualificationScenariosNoTeamMatchesSubtitle(
      int currentPoints, int remainingOtherMatches) {
    return '현재 승점 $currentPoints점이고 이 팀의 남은 경기는 없어요. 같은 조 남은 $remainingOtherMatches경기 결과에 따른 32강 경로를 계산해요.';
  }

  @override
  String worldCupQualificationScenariosCompleteSubtitle(int currentPoints) {
    return '조별리그 경기가 모두 끝났습니다. 최종 승점 $currentPoints점 기준의 32강 경로를 보여줘요.';
  }

  @override
  String get worldCupQualificationScenariosGuide =>
      '각 행은 이 팀의 남은 경기 결과 조합이에요. 직행은 조 1~2위, 3위 비교는 조 3위 뒤 전체 3위 팀 중 상위 8팀에 들어야 한다는 뜻입니다. 직행/3위 비교/탈락의 분모는 같은 조의 다른 남은 경기 승·무·패를 모두 섞어 본 경우 수예요. 상대 국가는 현재 순위로 브래킷 슬롯을 나라명으로 풀어쓴 후보입니다.';

  @override
  String get worldCupQualificationScenariosNoTeamMatchesGuide =>
      '이 팀의 경기 결과 선택지는 없고, 분모는 같은 조의 남은 다른 경기 승·무·패 조합입니다. 다른 경기 결과가 없어도 현재 확정 순위를 기준으로 상대 후보를 보여줘요.';

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
  String worldCupQualificationOtherMatchesTitle(int count) {
    return '다른 경기 결과 $count가지';
  }

  @override
  String get worldCupQualificationOtherMatchesSubtitle =>
      '이 팀 결과가 같아도 같은 조의 다른 경기 승·무·패에 따라 순위와 진출 상태가 달라질 수 있어요.';

  @override
  String get worldCupQualificationWaitingOtherMatchesTitle =>
      '기다리는 경기 결과별 경우의 수';

  @override
  String get worldCupQualificationWaitingOtherMatchesSubtitle =>
      '이 팀 경기는 끝났고, 아래 다른 경기 결과 조합마다 32강 상태를 다시 계산해요.';

  @override
  String get worldCupQualificationOtherPathDirectSection => '직행하는 경우';

  @override
  String get worldCupQualificationOtherPathThirdSection => '3위 비교로 남는 경우';

  @override
  String get worldCupQualificationOtherPathOutSection => '탈락하는 경우';

  @override
  String worldCupQualificationOtherPathSectionTitle(String label, int count) {
    return '$label $count가지';
  }

  @override
  String worldCupQualificationOtherPathOutcome(int rank, String outcome) {
    return '$rank위 · $outcome';
  }

  @override
  String worldCupQualificationOtherMatchPick(
      String home, String away, String result) {
    return '$home - $away: $result';
  }

  @override
  String worldCupQualificationOtherMatchWinResult(String team) {
    return '$team 승';
  }

  @override
  String get worldCupQualificationOtherMatchDrawResult => '무승부';

  @override
  String get worldCupQualificationThirdPlaceNote =>
      '조 3위는 12개 조 3위 중 상위 8팀에 들어야 32강에 올라갑니다.';

  @override
  String get worldCupQualificationNoTeamMatchesPick => '이 팀 남은 경기 없음';

  @override
  String get worldCupQualificationCompletePick => '조별 순위 확정';

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
  String get worldCupTeamRosterBestXiTitle => '나의 베스트 11';

  @override
  String get worldCupTeamRosterBestXiNote =>
      '공식 경기 라인업이 아니라 사용자가 선택한 포메이션과 선수로 그린 보드예요. 선수 행을 눌러 포함하거나 제외할 수 있어요.';

  @override
  String get worldCupTeamRosterFormationPickerLabel => '포메이션';

  @override
  String worldCupTeamRosterBestXiCount(int count) {
    return '$count/11명 선택';
  }

  @override
  String get worldCupTeamRosterBestXiComplete => '베스트 11 완성';

  @override
  String worldCupTeamRosterBestXiNeedMore(int count) {
    return '$count명 더 선택';
  }

  @override
  String get worldCupTeamRosterBestXiReset => '자동 추천';

  @override
  String worldCupTeamRosterBestXiPositionLimit(int selected, int required) {
    return '$selected/$required';
  }

  @override
  String worldCupTeamRosterBestXiSelectTooltip(String player) {
    return '$player 선택';
  }

  @override
  String worldCupTeamRosterBestXiRemoveTooltip(String player) {
    return '$player 제외';
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
      '공개된 2026 선수단 정보와 소속팀 정보를 바탕으로 보여줘요. 부상 교체와 경기 당일 선택은 킥오프 전까지 바뀔 수 있어요.';

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
      '확정된 대진은 국가명으로 보여주고, 다음 라운드 흐름을 한눈에 따라갈 수 있게 정리해요.';

  @override
  String get worldCupTournamentZoomOut => '브래킷 축소';

  @override
  String get worldCupTournamentZoomReset => '브래킷 크기 초기화';

  @override
  String get worldCupTournamentZoomIn => '브래킷 확대';

  @override
  String get worldCupTournamentOpenFullScreen => '전체 화면에서 보기';

  @override
  String get worldCupTournamentPdfTooltip => '대진표 PDF 다운로드';

  @override
  String get worldCupTournamentPdfExportedSnack => '대진표 PDF를 준비했어요.';

  @override
  String get worldCupTournamentPdfExportFailedSnack => '대진표 PDF를 만들지 못했어요.';

  @override
  String get worldCupTournamentImageTooltip => '대진표 이미지 공유';

  @override
  String get worldCupTournamentImageExportedSnack => '대진표 이미지를 준비했어요.';

  @override
  String get worldCupTournamentImageExportFailedSnack => '대진표 이미지를 만들지 못했어요.';

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
  String get worldCupBracketPendingTeam => '진출팀 확정 전';

  @override
  String get worldCupBracketPendingWinner => '승자 확정 전';

  @override
  String get worldCupBracketPendingLoser => '패자 확정 전';

  @override
  String get worldCupBracketQualifiedTeamSeparator => ' / ';

  @override
  String worldCupBracketQualifiedSlotDetail(String slot) {
    return '$slot 기준 진출';
  }

  @override
  String get worldCupBracketWinnerCandidateDetail => '승자 후보';

  @override
  String get worldCupBracketLoserCandidateDetail => '패자 후보';

  @override
  String get worldCupBracketWinnerResolvedDetail => '승자 확정';

  @override
  String get worldCupBracketLoserResolvedDetail => '패자 확정';

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
  String get homeHubTitleShort => '홈';

  @override
  String get homeLayoutChangeAction => '홈화면 변경';

  @override
  String get homeLayoutSettingsTitle => '홈 화면 설정';

  @override
  String get homeLayoutSettingsReset => '초기화';

  @override
  String get homeLayoutReorderTooltip => '섹션 이동';

  @override
  String get homeLayoutSavedMessage => '홈 화면 순서를 저장했어요.';

  @override
  String get homeLayoutNoVisibleSections => '표시 중인 홈 섹션이 없어요.';

  @override
  String get homeLayoutAutoOrderHint => '고정하지 않은 섹션은 자주 사용할수록 위로 올라가요.';

  @override
  String get homeSectionPinTooltip => '이 위치에 고정';

  @override
  String get homeSectionUnpinTooltip => '고정 해제';

  @override
  String get homeSectionClubSchedule => '클럽 일정';

  @override
  String get homeSectionLevel => '레벨 요약';

  @override
  String get homeSectionChallenge => '챌린지';

  @override
  String get homeSectionStreak => '훈련 연속 기록';

  @override
  String get homeSectionMeal => '식사 요약';

  @override
  String get homeSectionDailyFlow => '오늘 할일';

  @override
  String get homeSectionQuickActions => '빠른 실행';

  @override
  String get homeSectionContinue => '이어하기';

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
  String trainingEntryLessonSummaryWithDetail(String detail) {
    return '레슨: $detail';
  }

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
  String get profilePlayerNumberLabel => '선수 번호';

  @override
  String get profilePlayerNumberHint => '예) 10';

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
  String get entryLessonDetail => '어떤 레슨인가요?';

  @override
  String get entryLessonDetailHint => '예: 드리블 개인레슨, 슈팅 그룹레슨';

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
  String get filterLessonOnly => '레슨 기록만';

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
  String get statsLoadingMessage => '통계 데이터를 불러오는 중...';

  @override
  String get statsLoadFailedMessage => '통계를 불러오는 중 문제가 발생했어요.';

  @override
  String get statsFallbackMessage => '일부 통계 계산에 실패해 기본 화면으로 표시합니다.';

  @override
  String get statsTrainingTab => '훈련';

  @override
  String get statsMatchesTab => '시합';

  @override
  String get statsNoMatchesSelectedPeriod => '선택한 기간에 시합 기록이 없습니다.';

  @override
  String get statsRangePickerHelp => '통계 기간 선택';

  @override
  String get statsWorkoutDaysNone => '운동한 날: 없음';

  @override
  String statsWorkoutDaysValue(Object days) {
    return '운동한 날: $days';
  }

  @override
  String get statsGrowthChartTitle => '성장 그래프';

  @override
  String get statsActualLabel => '실제';

  @override
  String get statsTargetLabel => '목표';

  @override
  String get statsActualTimeDailyLabel => '실제 훈련 시간(일)';

  @override
  String get statsAverageTargetTimeDailyLabel => '평균 목표 시간(일)';

  @override
  String get statsAllMatchRecordsTitle => '전체 시합 기록';

  @override
  String statsMatchMinutesPlayedValue(Object minutes) {
    return '$minutes분 출전';
  }

  @override
  String get statsResultUnset => '결과 미입력';

  @override
  String get statsOutcomeWin => '승';

  @override
  String get statsOutcomeDraw => '무';

  @override
  String get statsOutcomeLoss => '패';

  @override
  String get statsDurationZeroMinutes => '0분';

  @override
  String statsDurationMinutes(Object minutes) {
    return '$minutes분';
  }

  @override
  String statsDurationHours(Object hours) {
    return '$hours시간';
  }

  @override
  String statsDurationHoursMinutes(Object hours, Object minutes) {
    return '$hours시간 $minutes분';
  }

  @override
  String get statsCompactDurationZero => '0분';

  @override
  String statsCompactDurationMinutes(Object minutes) {
    return '$minutes분';
  }

  @override
  String statsCompactDurationHours(Object hours) {
    return '$hours시간';
  }

  @override
  String statsCompactDurationHoursMinutes(Object hours, Object minutes) {
    return '$hours시간 $minutes분';
  }

  @override
  String get statsComparisonCurrentLabel => '현재';

  @override
  String get statsComparisonAverageLabel => '평균';

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
  String statsReportSummarySentence(
      Object totalTime, int sessions, int streak) {
    return '선택 기간에 총 $totalTime, 훈련 $sessions회, $streak일 연속 기록을 남겼어요.';
  }

  @override
  String statsReportActivityPeriodSummary(int activeDays, int periodDays) {
    return '선택 기간 $periodDays일 중 $activeDays일 활동 기록';
  }

  @override
  String get statsReportInsightTitle => '기간 리포트';

  @override
  String get statsReportTargetLabel => '목표 달성';

  @override
  String get statsReportTargetProgressLabel => '목표 달성률';

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
  String statsReportTrainingRhythmCompactValue(
      int sessions, int activeDays, int periodDays, int streak) {
    return '$sessions회 · $activeDays/$periodDays일 · $streak일 연속';
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
  String get statsReportExpandDetailsAction => '자세히 보기';

  @override
  String get statsReportCollapseDetailsAction => '접기';

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
  String get statsReportConditioningLabel => '보조운동';

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
  String get statsMatchSummaryTitle => '시합 요약';

  @override
  String get statsMatchResultGroupTitle => '결과 지표';

  @override
  String get statsMatchPersonalGroupTitle => '개인 기여';

  @override
  String get statsMatchTotalMatchesLabel => '총 시합';

  @override
  String statsMatchTotalMatchesValue(int count) {
    return '$count경기';
  }

  @override
  String get statsMatchRecordLabel => '전적';

  @override
  String statsMatchRecordValue(int wins, int draws, int losses) {
    return '$wins승 $draws무 $losses패';
  }

  @override
  String get statsMatchTypeLabel => '경기 유형';

  @override
  String get statsMatchGoalsLabel => '득실점';

  @override
  String get statsMatchPersonalTotalLabel => '개인 기록 합계';

  @override
  String get statsMatchPersonalDetailLabel => '세부 기여';

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
  String get statsMatchCompletedMatchesLabel => '결과 입력';

  @override
  String statsMatchCompletedMatchesValue(int completed, int total) {
    return '$completed/$total경기';
  }

  @override
  String get statsMatchGoalDifferenceLabel => '득실차';

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
  String get statsCompetitionDashboardTitle => '대회 결과 보드';

  @override
  String get statsCompetitionLeagueSectionTitle => '리그 대회';

  @override
  String get statsCompetitionTournamentSectionTitle => '토너먼트 대회';

  @override
  String statsCompetitionProgressValue(int recorded, int total) {
    return '$recorded/$total';
  }

  @override
  String statsCompetitionMoreCount(int count) {
    return '외 $count개';
  }

  @override
  String get statsCompetitionOpponentUnset => '상대 미입력';

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
  String get languageSystemDefault => '시스템 기본값';

  @override
  String get settings => '설정';

  @override
  String get settingsGeneralSection => '일반 설정';

  @override
  String get settingsSoundEffectsTitle => '효과음';

  @override
  String get settingsSoundEffectsSubtitle => '버튼과 보상 등 앱 안의 효과음을 재생합니다.';

  @override
  String get settingsTutorialReplayTitle => '튜토리얼 다시 보기';

  @override
  String get settingsTutorialReplaySubtitle => '홈으로 돌아가 코칭마크를 처음부터 다시 시작해요.';

  @override
  String get settingsTutorialReplayReady => '튜토리얼을 다시 시작할 준비가 됐어요.';

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
  String get settingsJournalOptionManagerTitle => '일지 항목 관리';

  @override
  String settingsOptionItemsCount(int count) {
    return '$count개 항목';
  }

  @override
  String get settingsDurationOptionsTitle => '훈련 시간 옵션';

  @override
  String get settingsDurationOptionsManageTitle => '훈련 시간 옵션 관리';

  @override
  String get settingsProgramOptionsTitle => '프로그램 옵션';

  @override
  String get settingsProgramOptionsManageTitle => '프로그램 옵션 관리';

  @override
  String get settingsTrainingGoalOptionsTitle => '훈련 목표 옵션';

  @override
  String get settingsTrainingGoalOptionsManageTitle => '훈련 목표 옵션 관리';

  @override
  String get settingsInjuryPartOptionsTitle => '부상 부위 옵션';

  @override
  String get settingsInjuryPartOptionsManageTitle => '부상 부위 옵션 관리';

  @override
  String get settingsOptionEditTitle => '항목 수정';

  @override
  String get settingsOptionAddTitle => '새 항목 추가';

  @override
  String get settingsIntOptionEditTitle => '시간 수정(분)';

  @override
  String get settingsIntOptionAddTitle => '새 시간 추가(분)';

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
  String get restoreConfirm =>
      'Google Drive의 최신 데이터를 안전 병합으로 가져올까요? 이 기기에만 있는 기록은 유지됩니다.';

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
  String get driveBackupRemoteOverwriteBlocked =>
      '이 기기에 선수 데이터가 없지만 Drive 백업에는 데이터가 있어 백업을 중단했어요. 먼저 Drive 백업을 가져와 주세요.';

  @override
  String get driveBackupOwnerMismatch =>
      'Drive 백업이 다른 Google 계정의 데이터로 확인되어 백업을 중단했어요. 올바른 계정으로 다시 연결해 주세요.';

  @override
  String get driveBackupDatasetMismatch =>
      '이 Drive 백업은 다른 데이터 세트에 속해 있어 자동 병합을 중단했어요.';

  @override
  String get driveBackupPlayerMismatch =>
      '이 Drive 백업은 다른 선수의 데이터로 확인되어 자동 병합을 중단했어요.';

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
  String get driveLegacyAccountImportAction => '이 계정 확인 및 백업 가져오기';

  @override
  String get driveLegacyAccountImportTitle => '기존 계정 연결을 확인할까요?';

  @override
  String get driveLegacyAccountImportBody =>
      '이 기기에는 Google 계정 ID가 없는 이전 연결 정보가 있어요. 현재 연결된 계정의 최신 Drive 백업을 가져오면 계정을 확인합니다. 가져오기 전 현재 기기 데이터는 로컬 안전 백업으로 남고, 확인 전까지 백업은 보호됩니다.';

  @override
  String get driveLegacyAccountImportSuccess => '계정을 확인하고 Drive 백업을 가져왔어요.';

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
  String get voiceInputStartTooltip => '음성 입력';

  @override
  String get voiceInputStopTooltip => '음성 입력 중지';

  @override
  String get voiceListeningStatus => '음성 입력 중';

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
  String get close => '닫기';

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
  String get notificationCategoryClubTraining => '클럽 훈련';

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
  String get notificationClubTrainingSettingsTitle => '클럽 훈련 알림';

  @override
  String notificationClubTrainingSettingsSubtitle(int minutes) {
    return '훈련 $minutes분 전에 유니폼과 시간을 알려줍니다.';
  }

  @override
  String get notificationClubTrainingLeadTimeLabel => '클럽 훈련 사전 알림';

  @override
  String notificationClubTrainingLeadTimeOption(int value) {
    return '$value분 전';
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
  String get openPhotoViewer => '사진 크게 보기';

  @override
  String get closePhotoViewer => '사진 닫기';

  @override
  String get previousPhoto => '이전 사진';

  @override
  String get nextPhoto => '다음 사진';

  @override
  String photoViewerCounter(Object current, Object total) {
    return '$current / $total';
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
  String get gameRankingTitle => '게임 랭킹';

  @override
  String get gameRankingEmpty => '아직 랭킹 기록이 없어요.';

  @override
  String gameRankingEntryTitle(String rankLabel, int rankScore, int score) {
    return '$rankLabel등급 ($rankScore점) - 게임 점수 $score';
  }

  @override
  String gameRankingEntrySubtitle(int level, int goals, String date) {
    return '레벨 Lv.$level - 골 $goals - $date';
  }

  @override
  String gameRankingPosition(int rankNo) {
    return '$rankNo위';
  }

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
  String get homeWeatherDetailsTitle => '날씨';

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
  String get weatherPrecipitationNone => '안 와요';

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
  String get homeWeatherHourlyOverview => '시간별 날씨';

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
  String get homeWeatherOutfitLayersDefault => '기능성 이너 + 반팔 훈련복';

  @override
  String get homeWeatherOutfitOuterDefault => '얇은 집업 또는 조끼';

  @override
  String get homeWeatherOutfitBottomDefault => '기본 반바지';

  @override
  String get homeWeatherOutfitAccessoriesDefault => '여벌 양말, 물통';

  @override
  String get homeWeatherOutfitLayersHot => '민소매/반팔 + 쿨 이너';

  @override
  String get homeWeatherOutfitOuterNone => '겉옷 없음';

  @override
  String get homeWeatherOutfitBottomHot => '통풍 반바지';

  @override
  String get homeWeatherOutfitAccessoriesHot => '쿨타월, 얼음물, 챙 모자';

  @override
  String get homeWeatherOutfitNoteHotBreaks => '과열 방지 위해 휴식 간격을 짧게';

  @override
  String get homeWeatherOutfitLayersWarm => '반팔 훈련복';

  @override
  String get homeWeatherOutfitBottomWarm => '반바지';

  @override
  String get homeWeatherOutfitAccessoriesWarm => '여벌 티셔츠, 땀수건';

  @override
  String get homeWeatherOutfitLayersMild => '기능성 이너 + 반팔/긴팔';

  @override
  String get homeWeatherOutfitOuterMild => '트레이닝 집업 또는 조끼';

  @override
  String get homeWeatherOutfitBottomMild => '얇은 긴바지 또는 반바지';

  @override
  String get homeWeatherOutfitAccessoriesMild => '워밍업용 겉옷';

  @override
  String get homeWeatherOutfitLayersCool => '기모 이너 + 긴팔 훈련복';

  @override
  String get homeWeatherOutfitOuterCool => '바람막이 + 조끼';

  @override
  String get homeWeatherOutfitBottomTrackPants => '긴 트레이닝 팬츠';

  @override
  String get homeWeatherOutfitAccessoriesCool => '얇은 장갑, 넥워머';

  @override
  String get homeWeatherOutfitLayersCold => '기모 이너 + 긴팔 + 덧입는 상의';

  @override
  String get homeWeatherOutfitOuterCold => '방풍 자켓 또는 경량 패딩 조끼';

  @override
  String get homeWeatherOutfitAccessoriesCold => '방한 장갑, 넥워머, 귀마개';

  @override
  String get homeWeatherOutfitLayersVeryCold => '발열 이너 + 두꺼운 긴팔 상의';

  @override
  String get homeWeatherOutfitOuterVeryCold => '경량 패딩/훈련용 패딩';

  @override
  String get homeWeatherOutfitBottomVeryCold => '방한 팬츠';

  @override
  String get homeWeatherOutfitAccessoriesVeryCold => '방한 장갑, 넥워머, 비니';

  @override
  String get homeWeatherOutfitNoteVeryCold => '실내 워밍업 후 짧은 세트로 진행';

  @override
  String get homeWeatherOutfitNoteStrongWind => '강풍: 바람막이/넥워머 필수';

  @override
  String get homeWeatherOutfitOuterWaterproof => '방수 방풍 자켓';

  @override
  String get homeWeatherOutfitOuterRainLight => '생활방수 자켓 + 얇은 긴팔 상의';

  @override
  String homeWeatherOutfitAccessoriesRain(Object accessories) {
    return '$accessories, 방수 양말 또는 여벌 양말';
  }

  @override
  String get homeWeatherOutfitNoteWetGrass => '젖은 잔디 미끄럼 주의';

  @override
  String homeWeatherOutfitAccessoriesSnow(Object accessories) {
    return '$accessories, 손난로(선택)';
  }

  @override
  String get homeWeatherOutfitNoteIcy => '빙판 구간 피해서 훈련';

  @override
  String get homeWeatherOutfitBottomFleece => '기모 긴바지';

  @override
  String get homeWeatherOutfitCautionNormal => '현재 조건에서 일반 강도 훈련 가능';

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
  String get diaryStickerFortune => '오늘의 한 줄';

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
  String get diaryFortunePinSummary => '오늘 기록에 남은 무드를 다이어리 스티커로 붙여둘 수 있어요.';

  @override
  String get diaryFortuneStorySentence => '오늘 한 줄에서 기억할 장면을 짧게 남긴다.';

  @override
  String get diaryFortuneNoteTitle => '한 줄 운세 메모';

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
  String get mealDietDetailsTitle => '식단 입력';

  @override
  String get mealMenuInputLabel => '추가 메모';

  @override
  String mealMenuInputHint(String label) {
    return '$label에 목록에 없는 음식이나 느낌을 메모하세요';
  }

  @override
  String get mealMainDishLabel => '메인요리';

  @override
  String get mealMainDishNone => '선택 안 함';

  @override
  String get mealMainDishChooseAction => '메인요리 선택';

  @override
  String get mealMainDishEditAction => '수정';

  @override
  String get mealMainDishSheetTitle => '메인요리 검색';

  @override
  String get mealMainDishClearAction => '선택 안 함';

  @override
  String get mealDishPortionSmall => '적게';

  @override
  String get mealDishPortionRegular => '보통';

  @override
  String get mealDishPortionLarge => '많이';

  @override
  String mealDishNutritionPreview(int kcal, int protein) {
    return '약 $kcal kcal · 단백질 ${protein}g';
  }

  @override
  String get mealCompanionFoodsLabel => '같이 먹은 음식';

  @override
  String get mealCompanionFoodsEmpty => '선택한 음식이 없어요';

  @override
  String get mealCompanionFoodsChooseAction => '음식 선택';

  @override
  String get mealCompanionFoodsEditAction => '수정';

  @override
  String get mealCompanionFoodsSheetTitle => '같이 먹은 음식 선택';

  @override
  String get mealFoodSearchLabel => '음식 검색';

  @override
  String get mealFoodSearchHint => '김치, 우유, 바나나 등';

  @override
  String get mealFoodSelectionClear => '전체 해제';

  @override
  String get mealFoodSelectionDone => '완료';

  @override
  String mealFoodNutritionLine(int kcal, int carbs, int protein, int fat) {
    return '$kcal kcal · 탄 ${carbs}g · 단 ${protein}g · 지 ${fat}g';
  }

  @override
  String mealFoodOptionSubtitle(String category, String nutrition) {
    return '$category · $nutrition';
  }

  @override
  String mealSelectedFoodsNutritionPreview(int kcal, int protein) {
    return '추가 음식 약 $kcal kcal · 단백질 ${protein}g';
  }

  @override
  String get mealFoodCategoryMain => '메인';

  @override
  String get mealFoodCategoryProtein => '단백질';

  @override
  String get mealFoodCategorySide => '반찬';

  @override
  String get mealFoodCategorySoup => '국·찌개';

  @override
  String get mealFoodCategoryCarb => '탄수화물';

  @override
  String get mealFoodCategoryFruit => '과일';

  @override
  String get mealFoodCategorySnack => '간식';

  @override
  String get mealFoodCategoryDrink => '음료';

  @override
  String get mealDishChickenBreast => '닭가슴살';

  @override
  String get mealDishEggs => '계란';

  @override
  String get mealDishTofu => '두부';

  @override
  String get mealDishGrilledFish => '생선구이';

  @override
  String get mealDishSalmon => '연어';

  @override
  String get mealDishBulgogi => '불고기';

  @override
  String get mealDishKimchiStew => '김치찌개';

  @override
  String get mealDishDoenjangStew => '된장찌개';

  @override
  String get mealDishFriedChicken => '치킨';

  @override
  String get mealDishChickenSalad => '닭가슴살 샐러드';

  @override
  String get mealDishRamen => '라면';

  @override
  String get mealDishSandwich => '샌드위치';

  @override
  String get mealFoodBibimbap => '비빔밥';

  @override
  String get mealFoodFriedRice => '볶음밥';

  @override
  String get mealFoodGimbap => '김밥';

  @override
  String get mealFoodCurryRice => '카레라이스';

  @override
  String get mealFoodPorkCutlet => '돈가스';

  @override
  String get mealFoodJajangmyeon => '짜장면';

  @override
  String get mealFoodJjampong => '짬뽕';

  @override
  String get mealFoodTteokbokki => '떡볶이';

  @override
  String get mealFoodPasta => '파스타';

  @override
  String get mealFoodHamburger => '햄버거';

  @override
  String get mealFoodPizza => '피자';

  @override
  String get mealFoodPorkBelly => '삼겹살';

  @override
  String get mealFoodJeyukBokkeum => '제육볶음';

  @override
  String get mealFoodBeefSteak => '스테이크';

  @override
  String get mealFoodDakgalbi => '닭갈비';

  @override
  String get mealFoodOmurice => '오므라이스';

  @override
  String get mealFoodUdon => '우동';

  @override
  String get mealFoodColdNoodles => '냉면';

  @override
  String get mealFoodSoybeanNoodles => '콩국수';

  @override
  String get mealFoodDumplingSoup => '만둣국';

  @override
  String get mealFoodSamgyetang => '삼계탕';

  @override
  String get mealFoodKimchiFriedRice => '김치볶음밥';

  @override
  String get mealFoodBudaeJjigae => '부대찌개';

  @override
  String get mealFoodSundubuJjigae => '순두부찌개';

  @override
  String get mealFoodGalbitang => '갈비탕';

  @override
  String get mealFoodSeolleongtang => '설렁탕';

  @override
  String get mealFoodYukgaejang => '육개장';

  @override
  String get mealFoodGamjatang => '감자탕';

  @override
  String get mealFoodKalguksu => '칼국수';

  @override
  String get mealFoodSujebi => '수제비';

  @override
  String get mealFoodBibimNoodles => '비빔국수';

  @override
  String get mealFoodJapchae => '잡채';

  @override
  String get mealFoodBossam => '보쌈';

  @override
  String get mealFoodJokbal => '족발';

  @override
  String get mealFoodGalbiJjim => '갈비찜';

  @override
  String get mealFoodDakdoritang => '닭볶음탕';

  @override
  String get mealFoodHaejangguk => '해장국';

  @override
  String get mealFoodGukbap => '국밥';

  @override
  String get mealFoodSoondaeGuk => '순대국';

  @override
  String get mealFoodTteokguk => '떡국';

  @override
  String get mealFoodJanchiGuksu => '잔치국수';

  @override
  String get mealFoodMakguksu => '막국수';

  @override
  String get mealFoodKimchiPancake => '김치전';

  @override
  String get mealFoodSeafoodPancake => '해물파전';

  @override
  String get mealFoodBindaetteok => '빈대떡';

  @override
  String get mealFoodSundae => '순대';

  @override
  String get mealFoodOdengSoup => '어묵탕';

  @override
  String get mealFoodSpaghetti => '스파게티';

  @override
  String get mealFoodLasagna => '라자냐';

  @override
  String get mealFoodRisotto => '리소토';

  @override
  String get mealFoodPaella => '파에야';

  @override
  String get mealFoodTacos => '타코';

  @override
  String get mealFoodBurrito => '부리토';

  @override
  String get mealFoodQuesadilla => '퀘사디아';

  @override
  String get mealFoodNachos => '나초';

  @override
  String get mealFoodSushi => '초밥';

  @override
  String get mealFoodSashimi => '사시미';

  @override
  String get mealFoodTempuraDon => '텐동';

  @override
  String get mealFoodGyudon => '규동';

  @override
  String get mealFoodKatsudon => '가츠동';

  @override
  String get mealFoodYakisoba => '야키소바';

  @override
  String get mealFoodOkonomiyaki => '오코노미야키';

  @override
  String get mealFoodTakoyaki => '타코야키';

  @override
  String get mealFoodPho => '쌀국수';

  @override
  String get mealFoodBanhMi => '반미';

  @override
  String get mealFoodPadThai => '팟타이';

  @override
  String get mealFoodTomYumSoup => '똠얌꿍';

  @override
  String get mealFoodGreenCurry => '그린커리';

  @override
  String get mealFoodMassamanCurry => '마사만커리';

  @override
  String get mealFoodNasiGoreng => '나시고렝';

  @override
  String get mealFoodSatay => '사테';

  @override
  String get mealFoodLaksa => '락사';

  @override
  String get mealFoodButterChicken => '버터치킨';

  @override
  String get mealFoodChickenTikkaMasala => '치킨 티카 마살라';

  @override
  String get mealFoodBiryani => '비리야니';

  @override
  String get mealFoodNaan => '난';

  @override
  String get mealFoodDal => '달 커리';

  @override
  String get mealFoodKebab => '케밥';

  @override
  String get mealFoodShawarma => '샤와르마';

  @override
  String get mealFoodFalafel => '팔라펠';

  @override
  String get mealFoodHummus => '후무스';

  @override
  String get mealFoodShakshuka => '샥슈카';

  @override
  String get mealFoodFishAndChips => '피시앤칩스';

  @override
  String get mealFoodRoastChicken => '로스트치킨';

  @override
  String get mealFoodMeatballs => '미트볼';

  @override
  String get mealFoodMacAndCheese => '맥앤치즈';

  @override
  String get mealFoodHotDog => '핫도그';

  @override
  String get mealFoodBurritoBowl => '부리토볼';

  @override
  String get mealFoodChowMein => '차우멘';

  @override
  String get mealFoodMapoTofu => '마파두부';

  @override
  String get mealFoodKungPaoChicken => '쿵파오 치킨';

  @override
  String get mealFoodDimSum => '딤섬';

  @override
  String get mealFoodSpringRoll => '스프링롤';

  @override
  String get mealFoodFriedNoodles => '볶음면';

  @override
  String get mealFoodCongee => '죽';

  @override
  String get mealFoodWontonSoup => '완탕국';

  @override
  String get mealFoodPokeBowl => '포케볼';

  @override
  String get mealFoodCaesarSalad => '시저샐러드';

  @override
  String get mealFoodGreekSalad => '그릭샐러드';

  @override
  String get mealFoodClamChowder => '클램차우더';

  @override
  String get mealFoodKimchi => '김치';

  @override
  String get mealFoodPickledRadish => '단무지';

  @override
  String get mealFoodSeasonedBeanSprouts => '콩나물무침';

  @override
  String get mealFoodSpinachNamul => '시금치나물';

  @override
  String get mealFoodSeaweedSalad => '미역무침';

  @override
  String get mealFoodLettuce => '상추';

  @override
  String get mealFoodCucumber => '오이';

  @override
  String get mealFoodTomato => '토마토';

  @override
  String get mealFoodAvocado => '아보카도';

  @override
  String get mealFoodBroccoli => '브로콜리';

  @override
  String get mealFoodSweetPotato => '고구마';

  @override
  String get mealFoodPotato => '감자';

  @override
  String get mealFoodCorn => '옥수수';

  @override
  String get mealFoodBoiledEgg => '삶은 계란';

  @override
  String get mealFoodFriedEgg => '계란후라이';

  @override
  String get mealFoodOmelet => '오믈렛';

  @override
  String get mealFoodCheese => '치즈';

  @override
  String get mealFoodTunaCan => '참치캔';

  @override
  String get mealFoodHam => '햄';

  @override
  String get mealFoodSausage => '소시지';

  @override
  String get mealFoodBacon => '베이컨';

  @override
  String get mealFoodMackerel => '고등어';

  @override
  String get mealFoodShrimp => '새우';

  @override
  String get mealFoodSquid => '오징어';

  @override
  String get mealFoodBeans => '콩';

  @override
  String get mealFoodChickpeas => '병아리콩';

  @override
  String get mealFoodLentils => '렌틸콩';

  @override
  String get mealFoodSeaweedSoup => '미역국';

  @override
  String get mealFoodBeefSoup => '소고기국';

  @override
  String get mealFoodEggSoup => '계란국';

  @override
  String get mealFoodTofuSoup => '순두부국';

  @override
  String get mealFoodVegetableSoup => '채소수프';

  @override
  String get mealFoodMisoSoup => '미소국';

  @override
  String get mealFoodChickenSoup => '닭고기수프';

  @override
  String get mealFoodDumplings => '만두';

  @override
  String get mealFoodFriedSnack => '튀김';

  @override
  String get mealFoodFrenchFries => '감자튀김';

  @override
  String get mealFoodRiceCake => '떡';

  @override
  String get mealFoodBreadSlice => '식빵';

  @override
  String get mealFoodToast => '토스트';

  @override
  String get mealFoodOatmeal => '오트밀';

  @override
  String get mealFoodCereal => '시리얼';

  @override
  String get mealFoodGranola => '그래놀라';

  @override
  String get mealFoodMixedNuts => '믹스넛';

  @override
  String get mealFoodAlmonds => '아몬드';

  @override
  String get mealFoodIceCream => '아이스크림';

  @override
  String get mealFoodChocolate => '초콜릿';

  @override
  String get mealFoodCookie => '쿠키';

  @override
  String get mealFoodCake => '케이크';

  @override
  String get mealFoodYogurt => '요거트';

  @override
  String get mealFoodGreekYogurt => '그릭요거트';

  @override
  String get mealFoodProteinShake => '프로틴 쉐이크';

  @override
  String get mealFoodWheyProtein => '웨이 프로틴';

  @override
  String get mealFoodMilk => '우유';

  @override
  String get mealFoodSoyMilk => '두유';

  @override
  String get mealFoodJuice => '주스';

  @override
  String get mealFoodSportsDrink => '스포츠음료';

  @override
  String get mealFoodCoffeeLatte => '카페라떼';

  @override
  String get mealFoodAmericano => '아메리카노';

  @override
  String get mealFoodCola => '콜라';

  @override
  String get mealFoodWater => '물';

  @override
  String get mealFoodBanana => '바나나';

  @override
  String get mealFoodApple => '사과';

  @override
  String get mealFoodOrange => '오렌지';

  @override
  String get mealFoodGrapes => '포도';

  @override
  String get mealFoodStrawberries => '딸기';

  @override
  String get mealFoodBlueberries => '블루베리';

  @override
  String get mealFoodSaladGreens => '샐러드 채소';

  @override
  String get mealFoodSeasonedSeaweed => '조미김';

  @override
  String get mealFoodLaver => '김';

  @override
  String get mealFoodGyeranJjim => '계란찜';

  @override
  String get mealFoodJangjorim => '장조림';

  @override
  String get mealFoodAnchovyBokkeum => '멸치볶음';

  @override
  String get mealFoodFishCakeBokkeum => '어묵볶음';

  @override
  String get mealFoodKongjaban => '콩자반';

  @override
  String get mealFoodCucumberKimchi => '오이소박이';

  @override
  String get mealFoodRadishKimchi => '무김치';

  @override
  String get mealFoodKkakdugi => '깍두기';

  @override
  String get mealFoodPerillaLeaves => '깻잎장아찌';

  @override
  String get mealFoodGarlic => '마늘';

  @override
  String get mealFoodSsamjang => '쌈장';

  @override
  String get mealFoodGochujang => '고추장';

  @override
  String get mealFoodDoenjang => '된장';

  @override
  String get mealFoodSalsa => '살사';

  @override
  String get mealFoodGuacamole => '과카몰리';

  @override
  String get mealFoodTortillaChips => '토르티야 칩';

  @override
  String get mealFoodPitaBread => '피타빵';

  @override
  String get mealFoodPickles => '피클';

  @override
  String get mealFoodOlives => '올리브';

  @override
  String get mealFoodSauerkraut => '사우어크라우트';

  @override
  String get mealFoodColeslaw => '코울슬로';

  @override
  String get mealFoodMashedPotatoes => '매시드 포테이토';

  @override
  String get mealFoodBakedBeans => '베이크드빈';

  @override
  String get mealFoodGarlicBread => '갈릭브레드';

  @override
  String get mealFoodOnionSoup => '양파수프';

  @override
  String get mealFoodEdamame => '에다마메';

  @override
  String get mealFoodMozzarella => '모차렐라';

  @override
  String get mealFoodHoney => '꿀';

  @override
  String get mealFoodJam => '잼';

  @override
  String get mealFoodPeanutButter => '땅콩버터';

  @override
  String get mealFoodCrackers => '크래커';

  @override
  String get mealFoodCroissant => '크루아상';

  @override
  String get mealFoodBagel => '베이글';

  @override
  String get mealFoodMuffin => '머핀';

  @override
  String get mealFoodPancakes => '팬케이크';

  @override
  String get mealFoodWaffles => '와플';

  @override
  String mealSummaryRiceOnly(String label, String rice) {
    return '$label $rice';
  }

  @override
  String mealSummaryMenuOnly(String label, String menu) {
    return '$label $menu';
  }

  @override
  String mealSummaryMenuPair(String first, String second) {
    return '$first, $second';
  }

  @override
  String mealSummaryRiceWithMenu(String label, String rice, String menu) {
    return '$label $rice · $menu';
  }

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
  String mealCalorieEstimateValue(int kcal) {
    return '약 $kcal kcal';
  }

  @override
  String get mealCalorieEstimateEmpty => '칼로리 계산 대기';

  @override
  String mealNutritionEstimateValue(int carbs, int protein, int fat) {
    return '탄 ${carbs}g · 단 ${protein}g · 지 ${fat}g';
  }

  @override
  String get mealCalorieCoachEmpty =>
      '음식을 기록하면 밥공기 수와 선택한 음식으로 대략적인 칼로리를 계산해요.';

  @override
  String get mealCalorieCoachLow =>
      '오늘 열량이 낮게 잡혀요. 훈련일이면 다음 끼니에 밥, 고구마, 바나나 같은 탄수화물을 보충해보세요.';

  @override
  String get mealCalorieCoachSteady =>
      '훈련 에너지로 무난한 기록이에요. 다음은 단백질과 채소를 끼니마다 나눠 넣어보세요.';

  @override
  String get mealCalorieCoachHigh =>
      '열량이 높게 잡혀요. 튀김, 면, 간식이 겹쳤다면 다음 끼니는 단백질과 채소 중심으로 가볍게 맞춰보세요.';

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
  String get mealStatsAverageCalories => '평균 칼로리';

  @override
  String get mealStatsTotalCalories => '총 칼로리';

  @override
  String get mealStatsAverageNutrition => '평균 영양소';

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
  String get fortuneDialogTitle => '오늘의 한 줄';

  @override
  String get fortuneDialogSubtitle => '';

  @override
  String get fortuneDialogOverviewTitle => '한 줄 보기';

  @override
  String get fortuneDialogOverallFortuneLabel => '한 줄';

  @override
  String get fortuneDialogLuckyInfoLabel => '행운의 숫자와 색';

  @override
  String fortuneDialogOverallFortuneCount(int count) {
    return '$count줄';
  }

  @override
  String fortuneDialogLuckyInfoCount(int count) {
    return '$count개';
  }

  @override
  String get fortuneDialogLuckyInfoTitle => '행운의 숫자와 색';

  @override
  String get fortuneDialogPoolSizeLabel => '조합 수';

  @override
  String fortuneDialogPoolSizeCount(String count) {
    return '$count개';
  }

  @override
  String get fortuneDialogRecommendedProgramTitle => '다음 훈련 추천';

  @override
  String get fortuneDialogRecommendationTitle => '플레이 한줄';

  @override
  String get fortuneDialogEncouragement => '오늘 하이라이트 하나만 짧게 남겨봐요.';

  @override
  String get fortuneDialogAction => '좋아요';

  @override
  String get fortuneDatabaseViewAction => '전체 데이터 보기';

  @override
  String get fortuneDatabaseTitle => '전체 운세 데이터베이스';

  @override
  String get fortuneDatabaseSubtitle =>
      '명리 코드와 생활 장면, 행운의 숫자와 색으로 짧은 운세를 만드는 데이터예요.';

  @override
  String get fortuneDatabaseCloseAction => '닫기';

  @override
  String get fortuneDatabaseSectionBirthCodes => '명리 코드';

  @override
  String get fortuneDatabaseSectionHiddenStems => '지장간';

  @override
  String get fortuneDatabaseSectionTenGods => '십성 해석';

  @override
  String get fortuneDatabaseSectionTwelveStages => '십이운성';

  @override
  String get fortuneDatabaseSectionBranchRelations => '지지 합충형해파';

  @override
  String get fortuneDatabaseSectionSymbolicStars => '신살 키워드';

  @override
  String get fortuneDatabaseSectionElementColors => '오행 컬러';

  @override
  String get fortuneDatabaseSectionShortLines => '짧은 추천안';

  @override
  String get fortuneDatabaseSectionDayMoods => '한 줄 재료';

  @override
  String get fortuneDatabaseSectionDailyEvents => '이어질 수 있는 일';

  @override
  String get fortuneDatabaseSectionDailyOutcomes => '짧은 운세 문장';

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
  String get fortuneDatabaseSectionTimePeriods => '시간대';

  @override
  String get fortuneDatabaseSectionTimeWindows => '시간대';

  @override
  String get fortuneDatabaseSectionSceneModifiers => '장소 단서';

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
  String get fortuneGeneratedUnknownPlayerName => '플레이어';

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
  String get fortuneShortLines =>
      '보내기 전 한 번 더 읽으면 실수 하나 줄어요.|첫 패스는 안전하게 가도 충분해요.|가방 지퍼 확인하면 작은 사고가 줄어요.|물 한 모금이 시작 속도를 살려요.|첫 5분은 천천히 들어가면 몸이 빨리 풀려요.|신발끈 다시 묶으면 첫 움직임이 가벼워요.|선택지를 줄이면 집중이 더 오래 가요.|실수 뒤에는 다음 볼이 바로 답이에요.|답장은 짧아도 먼저 보내면 편해져요.|연습 영상은 10초만 봐도 포인트가 보여요.|빈 공간을 먼저 보면 패스 길이 열려요.|목소리 한 번 크게 내면 팀 텐션이 올라요.|마무리 사진 한 장이 오늘 기록을 살려요.|칭찬 하나 먼저 던지면 대화가 빨라져요.|기록은 한 줄만 남겨도 충분해요.|급할수록 3초 멈추면 선택이 또렷해요.|첫 터치는 발밑에 붙이면 다음 동작이 쉬워요.|공 없을 때 움직이면 한 번 더 받아요.|바로 치운 물건이 나중에 시간을 벌어요.|기다릴 땐 자세만 바꿔도 몸이 덜 굳어요.|밥은 천천히, 폰은 잠깐 내려도 돼요.|막힐 땐 쉬운 것부터 잡으면 금방 풀려요.|헷갈리면 종이에 두 줄로 쓰면 정리돼요.|미뤄둔 답장은 짧게 보내도 충분해요.|새 정보는 캡처해 두면 다시 찾기 쉬워요.|마음에 든 문장은 저장해 두면 쓸 데가 생겨요.|연습 끝나고 스트레칭하면 내일 몸이 편해요.|첫 인사를 먼저 건네면 대화가 빨리 열려요.|공간이 보이면 한 박자 빠른 움직임이 먹혀요.|루틴은 10분씩 끊으면 지루함이 줄어요.|불편하면 강도를 낮춰야 내일도 뛰어요.|좋은 장면은 메모장에 남기면 다시 써먹어요.|알림 하나 끄면 집중 시간이 바로 늘어요.|다음 약속은 5분 일찍 잡으면 마음이 덜 바빠요.|패스 전 고개 한 번 들면 선택지가 늘어요.|드리블은 첫 방향만 정해도 발이 덜 꼬여요.|집 가기 전 가방을 비우면 내일이 편해요.|쉬는 시간엔 물부터 챙기면 몸이 빨리 돌아와요.|기본기를 챙긴 날은 실수가 빨리 줄어요.|끝내기 전 체크 하나가 내일 시간을 아껴요.|양말 한 짝만 찾아도 출발은 이긴 거예요.|첫 터치가 얌전하면 하루도 덜 삐끗해요.|대답은 짧아도 늦지 않게 보내면 깔끔해요.|공간을 먼저 보면 발보다 눈이 먼저 일해요.|가방 속 영수증 하나 빼면 머리도 가벼워요.|잠깐 웃고 넘기면 다음 장면이 빨리 와요.|첫 선택은 심플할수록 발이 덜 바빠요.|물병을 채우면 루틴도 같이 채워져요.|기록 한 줄이면 내일 내가 덜 헤매요.|쉬운 패스 하나가 팀 전체를 깨워요.|어깨 힘을 빼면 시야가 한 칸 넓어져요.|빈칸 하나 지우면 머릿속도 정리돼요.|늦은 답장도 담백하면 충분히 괜찮아요.|속도가 꼬이면 신발끈부터 다시 봐요.|작은 정리 하나가 오후 시간을 벌어요.|칭찬 한마디는 팀 채팅도 빠르게 데워요.|간식은 가볍게, 집중은 오래 가져가요.|놓친 볼보다 다음 위치가 더 중요해요.|메모장 첫 줄이 생각보다 쓸모 있어요.|정리된 가방은 내일 아침 치트키예요.|카페 문이 열릴 때 좋은 냄새가 따라와요.|좋아하는 노래 첫 소절에 걸음이 살짝 빨라져요.|엘리베이터 앞에서 반가운 이름을 마주쳐요.|점심 메뉴가 한 번에 마음에 들어와요.|우연히 본 사진 한 장이 입꼬리를 올려요.|편의점 신상 앞에서 괜히 눈이 반짝해요.|기다리던 답장이 짧게라도 먼저 와요.|길모퉁이에서 좋은 냄새가 먼저 인사해요.|책갈피 사이에서 잊은 메모가 웃게 해요.|하늘색이 예쁜 순간에 걸음이 살짝 느려져요.|좋아하는 문장이 갑자기 딱 맞게 떠올라요.|괜히 두근거리는 알림이 하나 와요.|새로 산 물건이 오늘 손에 착 붙어요.|거울 앞에서 표정이 평소보다 괜찮아요.|산책길 모퉁이에 작은 설렘이 숨어요.|마음에 든 이모지가 대화를 부드럽게 열어요.|버스 창가 자리에서 생각이 기분 좋게 풀려요.|우산을 접는 순간 공기가 산뜻하게 바뀌어요.|좋아하는 간식이 마지막 하나 남아 있어요.|집에 오는 길 불빛이 유난히 예뻐요.';

  @override
  String fortuneGeneratedDailyLineOne(String name, String elementFlow) {
    return '$name님, $elementFlow';
  }

  @override
  String fortuneGeneratedDailyLineTwo(String fortuneTheme) {
    return '$fortuneTheme';
  }

  @override
  String fortuneGeneratedLinkedDailyLine(
      String name, String elementFlow, String fortuneTheme) {
    return '$name님, $elementFlow / $fortuneTheme';
  }

  @override
  String fortuneGeneratedDailyLineThree(String nameElement, String playAdvice) {
    return '추천: $nameElement처럼 $playAdvice.';
  }

  @override
  String get fortuneGeneratedLuckyInfoHeader => '[행운의 숫자와 색]';

  @override
  String fortuneGeneratedLuckyInfoLine(int number, String color) {
    return '행운의 숫자는 $number, 색은 $color예요.';
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
  String get fortuneMyeongliHiddenStemLabels =>
      '자: 계|축: 기·계·신|인: 갑·병·무|묘: 을|진: 무·을·계|사: 병·무·경|오: 정·기|미: 기·정·을|신: 경·임·무|유: 신|술: 무·신·정|해: 임·갑';

  @override
  String get fortuneMyeongliTenGodLabels =>
      '비견: 나와 비슷한 힘, 기준과 자존감|겁재: 경쟁과 공유, 빠른 반응|식신: 즐거움과 표현, 안정적인 결과|상관: 색다른 표현, 규칙 밖 아이디어|편재: 넓은 기회, 뜻밖의 제안|정재: 실속과 정리, 꾸준한 관리|칠살: 긴장감과 결단, 돌파력|정관: 약속과 질서, 신뢰 흐름|편인: 낯선 힌트, 깊은 관찰|정인: 도움과 배움, 편안한 보호';

  @override
  String get fortuneMyeongliTwelveStageLabels =>
      '장생: 새 기운이 자라는 시작|목욕: 감각이 살아나는 변화|관대: 태도를 갖추는 준비|건록: 내 힘이 선명해지는 자리|제왕: 가장 강한 추진력|쇠: 힘을 덜고 정리하는 흐름|병: 무리보다 관리가 필요한 흐름|사: 끝맺음과 판단의 흐름|묘: 잠시 보관하고 숙성하는 흐름|절: 끊고 새로 보는 전환|태: 작은 가능성이 생기는 흐름|양: 다음 흐름을 키우는 준비';

  @override
  String get fortuneMyeongliBranchRelationLabels =>
      '자오충: 방향이 부딪혀 선택이 선명해짐|축미충: 묵은 일이 움직이는 변화|인신충: 이동과 판단이 빨라지는 흐름|묘유충: 말과 관계의 균형 조정|진술충: 기준과 책임을 다시 보는 흐름|사해충: 감정과 속도를 조절하는 흐름|자축합: 가까운 협력과 안정|인해합: 배움과 확장의 연결|묘술합: 따뜻한 표현과 공감|진유합: 정리와 결과의 연결|사신합: 빠른 판단과 재치|오미합: 편안한 관계와 마무리|인사신형: 급한 마음을 다듬는 신호|축미술형: 오래된 부담을 정리하는 신호|자묘형: 말과 감정의 선을 맞추는 신호|자미해: 작은 오해를 확인하는 흐름|축오해: 마음과 행동의 온도를 맞추는 흐름|인사해: 서두름을 낮추는 흐름|묘진해: 가까운 관계를 부드럽게 보는 흐름|신해해: 생각이 많아질 때 정리하는 흐름|유술해: 말끝과 약속을 살피는 흐름|자유파: 흐트러진 계획을 다시 잡는 흐름|축진파: 작은 균열을 메우는 흐름|인해파: 익숙한 기대를 새로 보는 흐름|묘오파: 표현 방식을 바꾸는 흐름|사신파: 재빠른 선택을 한 번 더 보는 흐름|미술파: 마무리 기준을 다시 잡는 흐름|신자진 삼합 수: 생각과 정보가 모이는 흐름|해묘미 삼합 목: 성장과 관계가 살아나는 흐름|인오술 삼합 화: 표현과 열정이 커지는 흐름|사유축 삼합 금: 정리와 완성도가 높아지는 흐름|해자축 방합 수: 차분한 집중이 쌓이는 흐름|인묘진 방합 목: 시작과 성장의 흐름|사오미 방합 화: 활기와 표현의 흐름|신유술 방합 금: 결과와 정리의 흐름';

  @override
  String get fortuneMyeongliSymbolicStarLabels =>
      '천을귀인: 도움을 만나는 귀인 운|문창귀인: 글과 배움, 말솜씨의 운|도화: 매력과 주목이 살아나는 운|역마: 이동과 변화, 새 소식의 운|화개: 몰입과 취향, 깊은 감성의 운|양인: 강한 추진력과 결단의 운|백호: 큰 에너지와 돌파의 운|괴강: 밀어붙이는 힘과 독립성|천덕귀인: 부드러운 보호와 완충|월덕귀인: 관계 속 도움과 배려|천의성: 회복과 돌봄의 운|금여: 안정감과 편안한 호감';

  @override
  String get fortuneMyeongliElementColorLabels =>
      '목: 그린, 민트, 터쿼이즈, 포레스트|화: 레드, 코랄, 피치, 로즈 핑크|토: 머스타드, 버터 옐로, 모카, 아이보리|금: 화이트, 실버, 골드, 스톤 그레이|수: 네이비, 블랙, 스틸 블루, 오션 블루';

  @override
  String get fortuneMyeongliElementColorValues =>
      '그린/민트/터쿼이즈/포레스트|레드/코랄/피치/로즈 핑크|머스타드/버터 옐로/모카/아이보리|화이트/실버/골드/스톤 그레이|네이비/블랙/스틸 블루/오션 블루';

  @override
  String get fortuneMyeongliTenGodDailyLines =>
      '오늘 할 일을 세 가지로 나누는 날이에요.|단체 메시지에서 답할 말만 고르는 날이에요.|쉬는 시간과 간식을 챙기는 날이에요.|평소와 다른 말투로 설명하는 날이에요.|갑자기 온 제안을 조건별로 비교하는 날이에요.|가방과 책상 위 물건을 정리하는 날이에요.|미룬 대답을 바로 정하는 날이에요.|약속 시간과 순서를 지키는 날이에요.|놓친 알림을 다시 여는 날이에요.|혼자 붙잡던 일을 도움받아 푸는 날이에요.';

  @override
  String get fortuneMyeongliTwelveStageDailyLines =>
      '아침 첫 행동을 작게 시작하는 날이에요.|표정과 말투 변화를 빨리 알아차리는 날이에요.|앉을 자리와 준비물을 먼저 챙기는 날이에요.|내 속도로 하나씩 처리하는 날이에요.|오전에 밀린 일을 시작하는 날이에요.|불필요한 약속과 물건을 덜어내는 날이에요.|쉬는 시간을 먼저 넣는 날이에요.|끝낼 일을 하나 골라 마무리하는 날이에요.|전에 적어둔 메모를 다시 쓰는 날이에요.|그만둘 일과 계속할 일을 나누는 날이에요.|새로 해볼 일을 작게 정하는 날이에요.|내일 할 일을 밤에 미리 적는 날이에요.';

  @override
  String get fortuneMyeongliBranchRelationDailyLines =>
      '가까운 사람과 같이 처리하는 날이에요.|의견이 부딪힌 뒤 할 일을 다시 정하는 날이에요.|꼬인 일을 순서대로 적는 날이에요.|오해를 바로 물어보고 줄이는 날이에요.|흐트러진 약속을 다시 맞추는 날이에요.|여러 사람이 한 말을 한곳에 모으는 날이에요.|익숙한 장소에서 할 일을 처리하는 날이에요.';

  @override
  String get fortuneSajuElementFlows =>
      '천천히 시작하고 오전 안에 속도를 내는 날이에요.|반가운 이름의 메시지에 답하는 날이에요.|잃어버린 물건이나 필요한 정보를 찾는 날이에요.|방이나 책상 한 칸을 치우는 날이에요.|좋아하는 음악이나 간식으로 기분을 올리는 날이에요.|두 가지 선택지 중 하나를 고르는 날이에요.|가까운 사람에게 먼저 말을 거는 날이에요.|짧은 시간에 한 가지 일만 붙잡는 날이에요.|도움을 받아 일을 빨리 끝내는 날이에요.|잠깐 쉬고 다시 시작하는 날이에요.|떠오른 생각을 바로 메모하는 날이에요.|평소 지나친 곳에서 필요한 단서를 찾는 날이에요.|쌓인 알림이나 메모를 지우는 날이에요.|상대 표정을 보고 말을 고르는 날이에요.|약속 시간보다 10분 먼저 움직이는 날이에요.|짧은 용기를 내서 먼저 말하는 날이에요.|기다리던 소식을 다시 확인하는 날이에요.|편한 속도로 끝까지 해내는 날이에요.|막힌 일을 작은 단계로 나누는 날이에요.|내가 정한 순서대로 움직이는 날이에요.|먼저 웃으며 인사하는 날이에요.|바뀐 일정이나 장소를 빨리 확인하는 날이에요.|기다리던 답을 한 번 더 확인하는 날이에요.|조용히 준비한 일을 꺼내는 날이에요.';

  @override
  String get fortuneSajuElementFlowExtras =>
      '상대 말을 끝까지 듣는 날이에요.|예상과 다른 일이 생겨도 다시 고르는 날이에요.|부담 없는 일부터 먼저 시작하는 날이에요.|혼자 결정하기보다 한 번 물어보는 날이에요.|작은 친절을 바로 알아차리는 날이에요.|메뉴나 이동 경로를 빨리 고르는 날이에요.|끝낸 일에 체크 표시를 하는 날이에요.|마음에 드는 쪽을 5분만 해보는 날이에요.|느리게 오던 답장을 받는 날이에요.|해야 할 일의 답을 한 줄로 적는 날이에요.|우연히 본 문구나 사진에서 힌트를 얻는 날이에요.|주변 물건을 제자리에 놓는 날이에요.|새로 관심 가는 물건이나 주제를 발견하는 날이에요.|복잡한 생각을 종이에 적는 날이에요.|문제의 첫 단서를 일찍 찾는 날이에요.|짧게 말하고 뜻을 전하는 날이에요.|부드럽게 부탁하고 대답을 듣는 날이에요.|작은 칭찬을 듣거나 전하는 날이에요.|5분 정도 쉬고 다음 일을 시작하는 날이에요.|약속 시간과 이동 시간을 맞추는 날이에요.|알림을 줄이고 집중을 오래 붙잡는 날이에요.|작은 실수를 바로 고치는 날이에요.|못 봤던 물건이나 정보를 찾는 날이에요.|오후부터 해야 할 일에 속도를 내는 날이에요.|조용히 준비한 내용을 인정받는 날이에요.|첫 느낌보다 확인한 내용을 믿는 날이에요.|계획을 조금 바꿔도 자연스럽게 움직이는 날이에요.|먼저 인사하고 반응을 얻는 날이에요.|시작할 일을 작게 정하는 날이에요.|마무리 전에 한 번 더 확인하는 날이에요.|기다리는 시간을 짧게 느끼는 날이에요.|한 번 더 웃을 일을 만나는 날이에요.|새 제안을 바로 거절하지 않고 듣는 날이에요.|딱딱한 말보다 편한 말로 전하는 날이에요.|정확히 보고 바로 말하는 날이에요.|궁금한 것을 검색하거나 물어보는 날이에요.';

  @override
  String get fortuneSajuFortuneThemes =>
      '아침 알림에 반가운 이름이 떠요.|점심 전에 미뤄둔 메시지를 보내요.|기다리던 답장이 오후 안에 와요.|새로 온 제안도 조건을 비교해서 바로 정해요.|작은 지출을 줄이고 꼭 필요한 물건을 골라요.|복잡했던 생각을 메모 한 줄로 정리해요.|가까운 사람과 짧게 이야기하고 마음이 편해져요.|늘 지나가던 길에서 필요한 안내를 따라가요.|오후에 미뤄둔 일을 20분 집중해서 끝내요.|누군가의 짧은 말이 오늘 선택을 쉽게 해줘요.|바뀐 일정 덕분에 더 편한 시간이 생겨요.|잊고 있던 약속이나 준비물이 떠올라요.|정리하다가 찾던 물건을 꺼내요.|오늘 고른 색이나 물건으로 기분을 바꿔요.|기다리는 시간이 줄고 다음 일을 빨리 시작해요.|작은 칭찬을 받거나 먼저 건네요.|필요한 정보가 대화나 알림으로 들어와요.|혼자 있는 시간에 밀린 일을 조용히 처리해요.|짧은 산책이나 이동 중에 해결 방법이 떠올라요.|헷갈리던 선택을 저녁 전에 정해요.|말하지 않아도 상대가 원하는 것을 알아차려요.|작은 실수를 바로 고치고 웃고 넘어가요.|상대 반응을 빨리 보고 말을 바꿔요.|오래 미룬 연락을 오늘 다시 꺼내요.|새로 알게 된 정보로 고르던 것을 바꿔요.|물 한잔이나 짧은 휴식으로 기분이 빨리 나아져요.|돈보다 시간을 아끼는 선택을 해요.|우연히 만난 사람이 다음 약속으로 이어져요.|조용히 집중한 일이 기록으로 남아요.|마음에 걸리던 일이 생각보다 쉽게 끝나요.|밤에 다시 확인해 놓친 부분을 잡아요.|누군가의 부탁을 처리하며 좋은 정보를 얻어요.|기다리던 물건이나 소식을 직접 확인해요.|생각보다 말이 잘 통하는 사람을 만나요.|작은 정리 하나로 남은 일정이 편해져요.|처음 고른 선택을 그대로 이어가요.';

  @override
  String get fortuneSajuFortuneThemeExtras =>
      '아침 첫 화면에서 필요한 일정을 바로 정리해요.|작은 부탁을 끝내고 바로 고맙다는 말을 들어요.|미뤄둔 정리를 10분 안에 시작해요.|마음에 걸린 대화를 짧게 다시 꺼내요.|예상보다 일찍 빈 시간이 생겨요.|가볍게 고른 길에서 찾던 가게나 장소를 만나요.|먼저 움직여 기다리는 시간을 줄여요.|열어둔 화면에서 찾던 정보를 바로 정리해요.|작은 실수 뒤에 더 쉬운 방법을 찾아요.|잠깐 기다리는 동안 다음 선택을 정해요.|익숙한 사람에게서 반가운 소식을 들어요.|오전에 끝낸 작은 일이 오후를 편하게 만들어요.|짧게 말했는데 뜻이 더 정확히 전해져요.|귀찮던 일을 끝내고 체크 표시를 해요.|가까운 장소에서 찾던 답이나 물건을 발견해요.|도움을 요청한 사람이 나중에 좋은 정보를 줘요.|계획 밖의 일이 생각보다 빨리 끝나요.|잠깐 쉬는 동안 적어둘 만한 생각이 떠올라요.|낯선 선택지도 가격이나 시간을 비교해서 골라요.|오후 늦게 반가운 알림이나 연락이 와요.|기대하지 않은 칭찬을 듣고 표정이 밝아져요.|손에 잡히는 일부터 시작해 주변을 빨리 정리해요.|가볍게 보낸 말이 짧은 대화로 이어져요.|미뤄둔 연락처를 다시 열어요.|흐릿했던 우선순위를 세 가지로 줄여요.|사소한 발견으로 사고 싶은 물건을 다시 골라요.|조용히 챙긴 준비물이 마지막에 도움이 돼요.|평소와 다른 시간에 집중이 잘 돼요.|작은 친절이 생각보다 빨리 돌아와요.|걱정하던 일이 짧은 확인으로 끝나요.|기다리던 말을 짧은 문자로 받아요.|가벼운 변화 하나로 하루 일정이 새로워져요.|한 번 더 확인해서 실수를 줄여요.|오래 고민한 일에 정할 기준이 생겨요.|속도를 낮추고 마무리를 깔끔하게 해요.|혼자 준비한 장점이 대화 중에 드러나요.|지나친 메시지에서 중요한 날짜를 찾아요.|익숙한 장소에서 새로 붙은 안내를 따라가요.|먼저 웃으며 인사해 대화를 쉽게 시작해요.|짧은 확인으로 신뢰를 얻어요.|오늘 고른 색이 물건 선택에 자주 들어가요.|짧은 이동 중에 해야 할 일을 정리해요.|뜻밖에 마음에 드는 메뉴나 물건을 찾아요.|말하기 애매했던 일을 자연스럽게 꺼내요.|주변 사람이 움직이는 시간을 보고 맞춰 가요.|조금 늦게 시작해도 마지막 확인을 끝내요.|작게 양보한 덕분에 더 편한 자리가 생겨요.|새 정보가 오늘 선택을 바꾸는 이유가 돼요.|웃고 넘긴 일이 저녁에 좋은 이야기거리가 돼요.|정리된 공간에서 필요한 물건을 바로 찾아요.|가까운 사람의 말이 오늘 선택의 기준이 돼요.|하루 끝에 작은 보상처럼 느껴지는 일이 생겨요.|평소 안 하던 확인으로 실수를 피해요.|생각보다 편하게 만남이나 통화를 끝내요.|갑자기 떠오른 아이디어를 바로 써먹어요.|마음이 복잡하면 짧은 산책 뒤에 할 일을 하나 정해요.|좋은 소식이 짧은 말이나 작은 알림으로 시작돼요.|마지막에 고른 선택이 실제로 더 편해요.|편하게 고른 것이 오래 만족을 줘요.|작은 용기를 내 먼저 말하면 상황이 바뀌어요.';

  @override
  String get fortuneDailyOutcomeTimes =>
      '아침에|점심쯤|오후에|저녁에|뜻밖에|우연히|금방|한번에|짧은 순간|마지막에';

  @override
  String get fortuneDailyOutcomeSubjects =>
      '웃긴 장면이|반가운 메시지가|좋은 소식이|작은 찬스가|필요한 답이|새 제안이|여유 시간이|센스 있는 말이|고마운 순간이|쉬운 선택지가';

  @override
  String get fortuneDailyOutcomeResults =>
      '툭 나와요.|기분을 올려요.|하루를 편하게 해요.|오래 남아요.|다음 행동을 쉽게 해요.|생각보다 크게 와요.|오늘 텐션을 바꿔요.|작은 힘을 줘요.|웃게 만들어요.|기억에 남아요.';

  @override
  String get fortuneSajuTrainingTones =>
      '괜히 서두르지만 않으면 더 산뜻해져요.|먼저 한마디 건네면 분위기가 쉽게 풀려요.|작게 정리하고 시작하면 흐름이 빨라져요.|마음에 걸리는 건 짧게 메모해두면 좋아요.|오늘은 빠른 결정보다 기분이 편한 선택이 잘 맞아요.|가벼운 농담 하나가 어색함을 녹여줘요.|복잡한 일은 순서를 세 개로 줄여보세요.|오전에 중요한 메시지를 확인해두면 편해요.|점심 이후에는 무리한 약속을 줄이는 쪽이 좋아요.|기분 좋은 색을 가까이 두면 집중이 쉬워져요.|작은 부탁은 바로 처리하면 마음이 넓어져요.|괜찮은 생각은 캡처하거나 적어두세요.|말이 길어질 때는 핵심만 남기면 충분해요.|오늘은 새로운 길보다 익숙한 길에서 재미가 나와요.|잠깐 멈춰서 숨을 고르면 선택이 또렷해져요.|혼자 해결하려던 일에 도움을 받아도 좋아요.|기다리는 동안 할 수 있는 작은 일을 잡아보세요.|반가운 연락에는 너무 오래 뜸 들이지 마세요.|정답보다 취향을 믿는 편이 잘 맞아요.|지나친 비교만 줄이면 기분이 금방 살아나요.|아까운 물건은 한 번 더 찾아볼 만해요.|낯선 정보는 바로 믿기보다 한 번 확인해보세요.|가까운 사람의 컨디션을 먼저 물어보면 좋아요.|미뤄둔 예약이나 확인을 끝내기 좋은 타이밍이에요.|짧은 외출이 생각보다 큰 환기가 돼요.|휴대폰 알림을 조금 줄이면 집중이 길어져요.|나중보다 지금 할 수 있는 작은 선택이 좋아요.|걱정은 크게 말하지 말고 작게 나눠보세요.|오늘은 깔끔한 마무리가 운을 끌어올려요.|가볍게 고른 메뉴가 의외로 만족스러울 수 있어요.|한 번 더 읽고 보내면 오해가 줄어들어요.|속도가 안 나면 자리나 배경을 바꿔보세요.|먼저 웃으면 대화가 훨씬 쉬워져요.|필요 없는 짐을 하나 덜어내면 마음도 가벼워져요.|약속 시간 앞뒤 10분을 넉넉히 잡아보세요.|오늘 좋은 장면은 사진보다 말로 남겨도 좋아요.';

  @override
  String get fortuneSajuTrainingToneExtras =>
      '오늘은 처음 떠오른 할 일을 작게 쪼개면 좋아요.|답답하면 창문을 열거나 빛이 있는 쪽으로 움직여보세요.|중요한 말은 짧게, 좋은 말은 조금 더 따뜻하게 해보세요.|급한 선택은 5분만 늦춰도 훨씬 편해져요.|기분이 애매하면 가장 쉬운 것부터 끝내보세요.|누군가의 말투보다 의도를 먼저 보면 마음이 가벼워져요.|새로운 시도는 작게 시작하면 부담이 줄어요.|오늘은 정리보다 시작이 먼저일 때도 괜찮아요.|중간에 멈춘 일이 있다면 한 줄만 이어보세요.|좋은 생각은 바로 적어야 오늘의 운이 남아요.|대답을 미루고 있다면 짧게라도 신호를 보내보세요.|필요 없는 알림 하나만 줄여도 집중이 살아나요.|오늘은 깨끗한 물건 하나가 기분 전환이 돼요.|부탁할 일은 설명을 길게 하기보다 핵심부터 말해보세요.|어색한 자리에서는 먼저 공통점을 찾아보세요.|아침에 정한 한 가지 기준을 끝까지 가져가보세요.|작은 지출은 만족도를 먼저 생각하면 좋아요.|복잡한 감정은 이름을 붙이면 다루기 쉬워져요.|오늘은 완벽보다 자연스러운 마무리가 잘 맞아요.|기분 좋은 소식은 혼자 오래 담아두지 마세요.|고민이 길어지면 몸을 먼저 움직여보세요.|익숙한 방법에 작은 변화를 섞어보면 좋아요.|중요한 물건은 눈에 보이는 곳에 두세요.|말이 꼬이면 처음 문장으로 돌아가면 돼요.|낮에는 빠르게, 저녁에는 부드럽게 움직이면 좋아요.|오늘은 거절도 짧고 다정하게 하면 충분해요.|기다리는 동안 주변을 정리하면 마음이 차분해져요.|좋은 타이밍은 작게 준비한 사람에게 먼저 보여요.|비교가 시작되면 어제의 나와만 비교해보세요.|마음이 급하면 숫자를 세고 다시 고르면 좋아요.|누군가의 장점을 먼저 말하면 대화가 쉽게 풀려요.|오늘은 작은 기록 하나가 다음 선택을 도와줘요.|불편한 느낌은 무시하지 말고 부드럽게 확인해보세요.|오래 붙잡은 일은 한 번 내려놓으면 답이 보일 수 있어요.|마지막 확인을 짧게 하면 하루가 깔끔해져요.|잠깐의 웃음이 생각보다 큰 에너지가 돼요.';

  @override
  String get fortuneSajuNameElements =>
      '빠른 시작형|다정한 연결형|차분한 정리형|반짝이는 아이디어형|느긋한 관찰형|분위기 전환형|섬세한 선택형|직감이 빠른 형|꾸준한 회복형|먼저 웃는 형|기회를 잘 보는 형|소소한 행복형|마음을 살피는 형|타이밍을 맞추는 형|말보다 행동형|한 박자 기다리는 형|새로움에 열린 형|정확하게 고르는 형|관계가 따뜻한 형|작게 실천하는 형|기분을 끌어올리는 형|흐름을 바꾸는 형|호기심이 강한 형|마무리가 좋은 형';

  @override
  String get fortuneSajuNameElementExtras =>
      '작은 단서를 잘 잡는 형|느리지만 정확한 형|먼저 분위기를 푸는 형|기분을 빨리 회복하는 형|좋은 말을 잘 건네는 형|새로운 흐름을 여는 형|차분히 중심 잡는 형|짧은 확인에 강한 형|숨은 장점을 찾는 형|편안한 선택을 잘하는 형|관계의 온도를 맞추는 형|마지막 정리에 강한 형|작은 변화에 밝은 형|정보를 빨리 연결하는 형|마음을 가볍게 만드는 형|조용히 밀어붙이는 형|흥미를 잘 살리는 형|기준을 세우는 형|웃음 포인트를 찾는 형|느낌을 믿는 형|한 번 더 확인하는 형|친절을 기억하는 형|여유를 만드는 형|우연을 잘 줍는 형|기분 전환이 빠른 형|정확한 순간을 고르는 형|부드럽게 설득하는 형|작은 성취를 쌓는 형|생각을 쉽게 정리하는 형|상황을 밝게 보는 형|기다림을 견디는 형|가까운 사람을 챙기는 형|새로운 취향을 찾는 형|담백하게 끝내는 형|하루 리듬을 만드는 형|선택을 가볍게 하는 형';

  @override
  String get fortuneSajuPlayAdvice =>
      '작은 우연도 그냥 넘기지 않으면 하루가 더 재미있어져요.|먼저 정리한 사람이 오늘의 속도를 가져갈 수 있어요.|가볍게 고른 선택이 의외로 오래 기분을 살려줘요.|말을 아끼는 순간보다 다정하게 말하는 순간이 더 힘이 있어요.|기다리던 답은 생각보다 단순한 모습으로 올 수 있어요.|괜찮은 제안은 바로 거절하지 말고 조금만 열어두세요.|하루 중 한 번은 스스로에게 쉬운 선택을 주세요.|오늘은 큰 변화보다 작은 방향 전환이 잘 맞아요.|익숙한 사람에게서 새로운 면을 볼 수 있어요.|대충 지나가던 일을 한 번만 살피면 힌트가 보여요.|잠깐의 여유가 오후의 실수를 줄여줄 수 있어요.|가볍게 움직이면 머릿속 엉킨 생각도 같이 풀려요.|기분이 가라앉으면 색이 선명한 물건을 가까이 둬보세요.|낯선 대화가 생각보다 빨리 편해질 수 있어요.|급한 마음만 줄이면 결과는 충분히 따라와요.|짧은 확인을 해두면 신뢰가 눈에 보이게 쌓여요.|오늘 만나는 정보 중 하나는 나중에 꽤 유용해져요.|웃고 넘긴 일이 저녁에는 좋은 이야기거리가 돼요.|정리할 것과 버릴 것을 나누면 마음이 확실히 가벼워져요.|새로 시작하기보다 멈춘 일을 다시 켜기 좋은 날이에요.|예상 밖의 칭찬을 받으면 그냥 받아들여도 좋아요.|짧은 집중 시간이 길게 끌고 가는 힘이 돼요.|어색한 순간은 먼저 질문하면 금방 풀려요.|오늘의 행운은 크게 오기보다 작은 반복으로 와요.|선택지가 많으면 가장 편안한 것을 고르세요.|미묘한 감이 맞을 수 있으니 기록해두면 좋아요.|누군가의 도움을 받으면 감사 인사를 바로 남겨보세요.|일찍 끝낼 수 있는 일은 미루지 않는 쪽이 운을 살려요.|마음에 드는 문장 하나가 하루 표정까지 바꿀 수 있어요.|기다림 끝에 온 소식은 조금 천천히 읽어도 괜찮아요.|오늘은 단정한 시작이 단정한 마무리로 이어져요.|큰 기대 없이 한 일이 작은 성과로 돌아올 수 있어요.|오해가 생기면 짧고 부드럽게 확인하는 편이 좋아요.|나만의 속도를 지키면 주변 흐름도 편해져요.|잠깐의 침묵이 더 좋은 대답을 데려올 수 있어요.|마지막에 고른 선택이 오늘의 기억으로 남을 수 있어요.';

  @override
  String get fortuneSajuPlayAdviceExtras =>
      '오늘은 첫 느낌을 너무 의심하지 않아도 좋아요.|작은 선을 먼저 넘으면 하루가 조금 더 넓어져요.|덜 중요한 일은 가볍게 끝내고 마음을 남겨두세요.|반가운 사람에게 짧게 안부를 건네면 흐름이 좋아져요.|새로운 정보는 바로 쓰지 않아도 저장해두면 쓸모가 생겨요.|오늘의 행운은 큰 사건보다 좋은 타이밍으로 올 수 있어요.|기분이 흔들리면 가장 익숙한 루틴으로 돌아오세요.|먼저 정리한 물건 하나가 마음을 편하게 만들어요.|고민은 길게 붙잡기보다 선택지를 두 개로 줄여보세요.|말이 잘 통하는 사람과 짧게라도 연결되면 좋아요.|오늘은 조금 천천히 답해도 분위기가 무너지지 않아요.|작게 웃어넘긴 일이 생각보다 오래 기분을 살려요.|익숙한 장소에서 새로운 장면을 찾아보세요.|누군가의 친절을 받으면 바로 반응해주는 게 좋아요.|확실하지 않은 일은 조금 더 부드럽게 물어보세요.|오늘은 급한 마음을 낮추면 운이 더 또렷해져요.|좋아하는 색을 가까이 두면 선택이 쉬워질 수 있어요.|작은 성공은 바로 인정해야 다음 흐름이 붙어요.|예상 밖의 제안은 한 번 상상해본 뒤 결정해도 늦지 않아요.|어색한 대화는 날씨나 오늘 본 장면부터 시작해보세요.|할 일이 많으면 가장 짧은 것 하나부터 끝내세요.|오늘은 내 편한 속도가 가장 좋은 속도예요.|실수 하나를 너무 오래 들여다보지 않아도 돼요.|괜찮은 생각은 말보다 메모가 먼저일 수 있어요.|기다림이 생기면 주변을 살피는 시간이 될 수 있어요.|먼저 고맙다고 말하면 관계 운이 부드러워져요.|작게 바꾼 계획이 오히려 더 잘 맞을 수 있어요.|선택이 어려우면 표정이 편해지는 쪽을 고르세요.|오늘은 오래된 물건이 작은 힌트를 줄 수 있어요.|마음이 무거우면 해야 할 일을 한 줄로 줄여보세요.|좋은 말은 아껴두기보다 오늘 쓰는 편이 좋아요.|낯선 사람보다 가까운 사람에게서 힌트가 올 수 있어요.|오늘의 감은 기록해두면 나중에 꽤 정확해 보여요.|천천히 시작해도 한 번 흐름이 붙으면 빨라질 수 있어요.|정리가 안 되면 공간보다 생각부터 비워보세요.|무리한 약속보다 가벼운 약속이 더 오래 남아요.|오늘은 작게 배운 것이 크게 써먹히는 날이에요.|싫은 일을 끝낸 뒤에는 작은 보상을 주세요.|마음에 든 문장은 오늘의 표정처럼 써도 좋아요.|사소한 호기심이 좋은 대화를 열 수 있어요.|누군가 먼저 다가오면 조금 더 열어둬도 괜찮아요.|오늘은 불필요한 설명을 줄이면 더 잘 통할 수 있어요.|오후의 작은 변화가 저녁 기분을 바꿀 수 있어요.|익숙한 선택을 해도 재미를 하나 섞어보세요.|바로 해결되지 않는 일은 밤까지 기다려도 좋아요.|말보다 태도가 먼저 전해지는 순간이 있을 수 있어요.|오늘은 소소한 칭찬을 받기 쉬운 흐름이에요.|조용한 곳에서 생각하면 답이 더 선명해질 수 있어요.|가볍게 시작한 일이 뜻밖에 오래 이어질 수 있어요.|불편한 마음은 작게 말하면 금방 풀릴 수 있어요.|먼저 챙긴 준비물이 하루를 편하게 만들어요.|오늘은 우연한 만남보다 우연한 발견이 강해요.|기분 좋은 소리는 하루의 리듬을 바꿀 수 있어요.|작게 양보한 뒤에 더 편한 선택지가 열릴 수 있어요.|오늘의 좋은 운은 늦게라도 표시가 날 수 있어요.|처음 마음에 든 것을 다시 봐도 괜찮아요.|주변 사람이 웃는 이유를 같이 찾아보세요.|잠깐의 집중이 긴 고민을 줄여줄 수 있어요.|오늘은 끝까지 붙드는 것보다 깔끔하게 넘기는 쪽이 좋아요.|작은 기대 하나만 품고 움직이면 하루가 가벼워져요.';

  @override
  String get fortuneLuckyColorTones =>
      '딥|소프트|클린|선셋|쿨|웜|미스트|브라이트|모노|포인트|네온|파스텔|메탈릭|프레시|차분한|스파클|라이트|무드|글로우|내추럴';

  @override
  String get fortuneLuckyColorToneExtras =>
      '민트빛|스모키|비비드|은은한|깨끗한|포근한|싱그러운|차가운|따뜻한|투명한|빈티지|선명한|차분히 빛나는|부드러운|산뜻한|반짝이는|깊은|가벼운|맑은|담백한';

  @override
  String get fortuneLuckyColorBases =>
      '네이비|에메랄드|코랄|머스타드|스카이블루|카키|아이보리|체리 레드|라임|차콜|로열 블루|민트|피치|바이올렛|실버|골드|화이트|블랙|올리브|터쿼이즈|라벤더|버터 옐로|로즈 핑크|딥 그린';

  @override
  String get fortuneLuckyColorBaseExtras =>
      '플럼|샐먼|아쿠아|버건디|샴페인|모카|스톤 그레이|라일락|애플 그린|데님 블루|크림|루비|세이지|오션 블루|멜론|코코아|스틸 블루|파우더 핑크|아이스 블루|포레스트|탠저린|그레이프|스노우|모스 그린';

  @override
  String get fortuneLuckyTimePeriods =>
      '이른 오전|오전 후반|점심 직후|초반 오후|늦은 오후|해질 무렵|저녁 초반|밤 루틴 시간|등교 전|쉬는 시간|이동 중|잠들기 전|메시지 확인 시간|간식 시간|집에 돌아온 직후|하루 정리 시간';

  @override
  String get fortuneLuckyTimePeriodExtras =>
      '아침 준비 시간|첫 메시지 시간|점심 전|점심 뒤 산책 시간|오후 집중 시간|해가 기울 때|저녁 식사 전|저녁 식사 뒤|방 정리 시간|씻고 난 뒤|조용한 밤|잠깐 쉬는 시간|약속 전|약속 뒤|기록을 남기는 순간|마지막 확인 시간';

  @override
  String get fortuneLuckyTimeWindows =>
      '06:40~07:20|08:10~08:50|09:30~10:10|10:40~11:20|12:20~13:00|14:10~14:50|16:00~16:40|18:20~19:00|20:10~20:50|21:00~21:40|07:30~08:00|11:40~12:10|13:20~13:50|15:10~15:40|17:20~17:50|19:30~20:00|22:00~22:30|06:10~06:30|12:50~13:20|18:50~19:20';

  @override
  String get fortuneLuckyTimeWindowExtras =>
      '06:55~07:15|07:45~08:15|08:55~09:25|09:45~10:15|10:55~11:25|11:55~12:25|12:35~13:05|13:45~14:15|14:35~15:05|15:45~16:15|16:35~17:05|17:45~18:15|18:35~19:05|19:45~20:15|20:35~21:05|21:45~22:15|22:20~22:50|06:20~06:50|07:05~07:35|08:25~08:55|10:20~10:50|11:10~11:40|13:05~13:35|14:55~15:25|16:50~17:20|18:05~18:35|19:05~19:35|21:10~21:40';

  @override
  String get fortuneLuckyZoneModifiers =>
      '창가 쪽|문 가까이|왼쪽 자리|오른쪽 자리|중앙 자리|조용한 곳|밝은 곳|그늘진 곳|책상 앞|현관 근처|엘리베이터 앞|버스 정류장 근처|카페 모서리|복도 끝|계단 가까이|물 마시는 곳|거울 앞|가방 옆|식탁 근처|침대 옆';

  @override
  String get fortuneLuckyZoneModifierExtras =>
      '햇빛 드는|바람이 통하는|사람이 적은|가장 익숙한|새로 눈에 띈|정리된|따뜻한 불빛의|발걸음이 멈추는|잠깐 기대는|소리가 잦아드는|시야가 넓은|물건을 내려놓는|기분이 밝아지는|말이 잘 들리는|조용히 웃는|오늘 처음 보는|가볍게 지나치는|한 번 더 돌아보는|마음이 편한|작게 반짝이는';

  @override
  String get fortuneLuckyZoneBases =>
      '작은 메모 공간|휴대폰을 내려두는 자리|첫 인사를 건네는 순간|가볍게 웃는 자리|잠깐 쉬는 의자|정리된 책상 위|가방을 여는 순간|창밖이 보이는 자리|물을 마시는 자리|조용히 생각하는 곳|메시지를 확인하는 순간|신발을 고쳐 신는 곳|엘리베이터 기다리는 곳|좋아하는 음악을 듣는 시간|손을 씻는 곳|간단히 간식 먹는 자리|계획을 다시 보는 곳|잠깐 멈춰 서는 곳|집에 들어오는 순간|불을 켜는 자리|먼저 양보하는 순간|낯선 길이 보이는 곳|오늘 물건을 찾는 자리|하루를 닫는 자리';

  @override
  String get fortuneLuckyZoneBaseExtras =>
      '창문을 여는 자리|노트를 펼치는 곳|충전기를 꽂는 자리|좋아하는 컵 옆|달력을 보는 곳|가방을 내려놓는 곳|문자를 읽는 순간|신발끈을 묶는 곳|잠깐 기대는 벽|조명이 닿는 책상|음료를 고르는 자리|손목시계를 보는 순간|마지막으로 돌아보는 곳|작은 소리가 들리는 곳|사진을 확인하는 자리|기다림이 짧아지는 곳|주머니를 정리하는 순간|오늘의 색을 고르는 곳|바람을 느끼는 자리|시선을 잠깐 쉬는 곳|친구를 떠올리는 순간|짧은 메모를 지우는 곳|다음 약속을 떠올리는 자리|조용히 미소 짓는 순간';

  @override
  String get fortuneLuckyCueOpenings =>
      '짧게|첫 시작 전에|호흡 고른 뒤|메시지를 보내기 전에|문을 나서기 전에|고개를 든 직후|자리에 앉기 전에|리듬이 흔들리면|물 마신 다음|이름을 부르기 전에|첫 실수 뒤에|대화가 끊기면|선택 전 한 번|마음이 급해지면|좋은 말을 들은 뒤|잠들기 전에|알림을 확인하기 전에|계단을 오르기 전에|새로운 장소에 들어가면|하루를 정리하며';

  @override
  String get fortuneLuckyCueOpeningExtras =>
      '첫 알림을 보기 전에|가방을 들기 전에|물건을 찾기 시작하면|마음이 복잡해지면|작은 칭찬을 들으면|결정을 미루고 싶을 때|새로운 길을 볼 때|손을 씻은 뒤|짧은 대기 시간에|좋은 냄새가 날 때|익숙한 노래가 들리면|오늘 색을 고를 때|말문이 막히면|웃음이 나올 때|정리할 물건이 보이면|기다리던 답이 오면|잠깐 혼자 있을 때|밖으로 나가기 직전|집에 돌아와서|마지막 불을 끄기 전에';

  @override
  String get fortuneLuckyCueActions =>
      '한 번 더 확인하기|먼저 웃어보기|두 손을 가볍게 털기|첫 문장을 짧게 말하기|고마운 점 하나 찾기|짧은 호흡으로 마음 묶기|빠름보다 정확함을 고르기|어깨 힘을 빼기|상대 이름을 부드럽게 부르기|두 번째 선택을 작게 바꾸기|메모 하나 남기기|걸음을 조금 늦추기|실수 뒤 바로 정리하기|보내기 전 한 번 읽기|도움을 청할 사람 떠올리기|확답 전에 잠깐 멈추기|짧은 칭찬으로 분위기 올리기|마지막 10분은 가볍게 정리하기|다음 일을 먼저 예상하기|주변 색을 하나 고르기|고개를 들고 천천히 보기|끝낸 뒤 바로 치우기|어색하면 질문 하나 던지기|오늘 좋았던 장면 기억하기|조용한 음악 하나 고르기|가방 속을 한 번 정리하기|물 한 모금 마시기|걱정을 세 줄로 줄이기|기분 좋은 사진을 다시 보기|짧은 답장 먼저 보내기|앉는 자리를 살짝 바꾸기|저녁에 한 가지 칭찬 남기기';

  @override
  String get fortuneLuckyCueActionExtras =>
      '가장 쉬운 것부터 고르기|괜찮은 말을 먼저 건네기|작은 물건 하나 정리하기|선택지 하나만 줄이기|좋아하는 색을 가까이 두기|답장을 짧게 먼저 보내기|걷는 속도를 조금 맞추기|손끝 힘을 빼기|눈에 띈 단어를 적어두기|괜히 미룬 일을 3분만 해보기|창밖을 한 번 보기|좋은 소식을 한 사람과 나누기|작은 실수를 웃고 넘기기|처음 든 생각을 기록하기|정리할 곳 하나만 고르기|기다리는 동안 자세를 바꾸기|고마운 사람을 떠올리기|오늘의 색을 사진으로 남기기|불편한 점을 부드럽게 묻기|마지막 선택은 천천히 하기|다음 시간을 5분 여유 있게 잡기|마음에 드는 문장을 저장하기|새로운 정보를 한 번 확인하기|아쉬운 일은 짧게 마무리하기|먼저 양보할 순간을 찾기|좋은 대답은 너무 늦추지 않기|주머니 속을 가볍게 비우기|낯선 선택을 한 번 상상하기|오늘 배운 것을 한 줄로 남기기|조용한 곳에서 다시 생각하기|기분 좋은 표정을 의식하기|하루 끝에 작은 보상 정하기';

  @override
  String get mealStatsNoTrainingOrMealEntries => '선택한 기간에 훈련 기록과 식사 기록이 없습니다.';

  @override
  String get drawerRunningCoach => '달리기 코치';

  @override
  String get runningCoachScreenTitle => '달리기 코치';

  @override
  String get runningCoachHeroTitle => '달리고, 확인하고, 좋아지기';

  @override
  String get runningCoachHeroBody =>
      '달리는 동안 실시간 코칭을 받거나, 선명한 측면 영상 하나로 전체 자세 리포트를 확인하세요.';

  @override
  String get runningCoachStartTitle => '원하는 코칭 방식을 고르세요';

  @override
  String get runningCoachStartBody =>
      '바로 실시간 코칭을 시작하거나, 영상을 찍기 전에 정확한 카메라 구도를 확인할 수 있어요.';

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
      '측면 영상 하나를 고르세요. 정해진 프레임 예산으로 전체를 훑고 러너가 선명한 구간과 접지 주변을 다시 분석해요.';

  @override
  String get runningCoachCaptureFlowTitle => '달리기 영상 분석';

  @override
  String get runningCoachCandidatePreviewTitle => '후보 영상을 미리 봐요';

  @override
  String get runningCoachCapturedPreviewTitle => '촬영한 영상을 확인해요';

  @override
  String get runningCoachPreviewBody =>
      '확정하기 전에 영상을 재생하고 탐색해 보세요. 아래 품질 점검은 경고일 뿐 분석을 막지 않아요.';

  @override
  String get runningCoachPreviewUnavailable =>
      '미리보기를 열 수 없어요. 다른 영상을 고르거나 분석 디코더로 이 파일을 시도할 수 있어요.';

  @override
  String get runningCoachPreviewPoseAnalyzing => '관절 확인 중';

  @override
  String get runningCoachPreviewPoseUnavailable => '관절 오버레이 확인 불가';

  @override
  String get runningCoachPreviewPoseRetryAction => '다시 시도';

  @override
  String get runningCoachPreviewSelectAction => '이 영상 선택';

  @override
  String get runningCoachPreviewAnalyzeAction => '이 영상 분석';

  @override
  String get runningCoachPreviewLongVideoWarning =>
      '60초보다 긴 영상이에요. 프레임 예산 안에서 전체를 훑고 러너가 가장 잘 보이는 구간을 집중 분석해요.';

  @override
  String get runningCoachPreviewLargeVideoWarning =>
      '120MB보다 큰 파일이에요. 제한된 프레임 예산으로 분석하며 시간이 더 걸릴 수 있어요.';

  @override
  String get runningCoachPreviewLargeWebVideoWarning =>
      '브라우저 파일이 64MB보다 커요. 브라우저 메모리를 보호하기 위해 96MB를 넘으면 분석 전에 거절해요.';

  @override
  String get runningCoachPreviewResolutionWarning =>
      '해상도가 낮아 일부 항목은 추정값으로 표시될 수 있어요.';

  @override
  String get runningCoachPreviewUnknownInfo => '정보 없음';

  @override
  String runningCoachPreviewMegabytes(String value) {
    return '${value}MB';
  }

  @override
  String runningCoachPreviewVideoInfo(
      String duration, String size, String resolution) {
    return '$duration · $size · $resolution';
  }

  @override
  String runningCoachPreviewTimeline(String current, String total) {
    return '$current / $total';
  }

  @override
  String get runningCoachCoordinatePreviewLabel => '좌표 미리보기';

  @override
  String get runningCoachSlowLoopTitle => '영상에서 이 순간 보기';

  @override
  String get runningCoachSlowLoopBody => '이 측정 전후의 짧은 구간만 0.5배속으로 반복 재생해요.';

  @override
  String get runningCoachSlowLoopUnavailable =>
      '원본 영상을 저장하지 않아 이 순간을 재생할 수 없어요.';

  @override
  String get runningCoachSlowLoopCaptureOnly =>
      '원본 영상을 보관하지 않아 저장된 실제 캡처만 볼 수 있어요.';

  @override
  String runningCoachSlowLoopTiming(String start, String end) {
    return '0.5배속 반복 · $start초–$end초';
  }

  @override
  String get runningCoachConfirmedScoreLabel => '확정 점수';

  @override
  String get runningCoachEstimatedScoreLabel => '예상 점수';

  @override
  String get runningCoachEstimatedScoreSummary => '이 영상에서 읽은 좌표로 계산한 예상 점수예요';

  @override
  String runningCoachMeasurementCountTitle(int count, int total) {
    return '측정 결과 $count/$total';
  }

  @override
  String get runningCoachMeasurementStatusEstimated => '추정 측정';

  @override
  String get runningCoachMeasurementStatusCoordinatesUnavailable => '좌표 없음';

  @override
  String runningCoachMeasurementExpectedRange(String lower, String upper) {
    return '예상 범위 $lower–$upper';
  }

  @override
  String runningCoachEvidenceFrameMetadata(
      String side, String time, String value, int confidence) {
    return '$side · $time · $value · 신뢰도 $confidence%';
  }

  @override
  String runningCoachEvidenceViewAtTime(String time) {
    return '영상에서 $time 보기';
  }

  @override
  String get runningCoachCaptureFlowBody =>
      '측면 영상을 촬영하거나 고른 뒤 미리 보고 분석을 확정하세요. 긴 영상도 정해진 프레임 예산으로 처리해요.';

  @override
  String get runningCoachCaptureAction => '바로 촬영';

  @override
  String get runningCoachCaptureAndAnalyzeAction => '바로 촬영하고 분석하기';

  @override
  String get runningCoachCaptureAgainAction => '다시 촬영';

  @override
  String get runningCoachCaptureTitle => '달리기 촬영';

  @override
  String get runningCoachCaptureGuide => '측면에서 전신과 양발이 안내선 안에 보이게 촬영하세요.';

  @override
  String get runningCoachCaptureStart => '촬영 시작';

  @override
  String get runningCoachCaptureStop => '촬영 끝내기';

  @override
  String runningCoachCaptureRecording(int elapsed, int maximum) {
    return '촬영 중 $elapsed/$maximum초';
  }

  @override
  String runningCoachCaptureMinimumDuration(int seconds) {
    return '최소 $seconds초를 촬영해 주세요.';
  }

  @override
  String get runningCoachCaptureSwitchCamera => '카메라 전환';

  @override
  String get runningCoachCaptureUnsupportedPlatform =>
      '이 기기에서는 앱 내 촬영을 사용할 수 없어요.';

  @override
  String get runningCoachCapturePermissionDenied =>
      '카메라 권한이 필요해요. 설정에서 권한을 허용한 뒤 다시 시도해 주세요.';

  @override
  String get runningCoachCaptureUnavailable => '사용할 수 있는 카메라를 찾지 못했어요.';

  @override
  String get runningCoachCaptureFailed =>
      '촬영을 시작하지 못했어요. 카메라 상태를 확인한 뒤 다시 시도해 주세요.';

  @override
  String get runningCoachCaptureRetry => '카메라 다시 열기';

  @override
  String get runningCoachCaptureFramingTitle => '스마트 구도 확인';

  @override
  String runningCoachCaptureFramingReadyCount(int count, int total) {
    return '$count/$total 준비됨';
  }

  @override
  String get runningCoachCaptureFramingFallbackBody =>
      '실시간 자세 확인을 사용할 수 없어 기기와 미리보기 상태만 표시해요.';

  @override
  String get runningCoachCaptureFramingLiveBody =>
      '촬영 전 실시간 자세 상태가 갱신돼요. 경고가 있어도 촬영은 막지 않아요.';

  @override
  String get runningCoachCaptureFramingStartingBody =>
      '실시간 구도 확인을 시작하는 중이에요...';

  @override
  String get runningCoachCaptureFramingLiveSearching => '전신 자세를 찾는 중';

  @override
  String get runningCoachCaptureFramingLiveReady => '실시간 자세 감지됨';

  @override
  String get runningCoachCaptureFramingNotMeasured => '측정 안 됨';

  @override
  String get runningCoachCaptureFramingPhoneGood => '휴대폰 세로 고정';

  @override
  String get runningCoachCaptureFramingPhoneWarning => '세로로 세워 주세요';

  @override
  String get runningCoachCaptureFramingPreviewGood => '미리보기 화면 채움';

  @override
  String get runningCoachCaptureFramingFullBodyGood => '전신이 안내선 안';

  @override
  String get runningCoachCaptureFramingFullBodyWarning => '전신을 중앙으로';

  @override
  String get runningCoachCaptureFramingFullBodyUnknown => '전신 미측정';

  @override
  String get runningCoachCaptureFramingScaleGood => '러너 크기 적절';

  @override
  String get runningCoachCaptureFramingScaleTooSmall => '러너가 너무 작음';

  @override
  String get runningCoachCaptureFramingScaleTooLarge => '러너가 너무 가까움';

  @override
  String get runningCoachCaptureFramingScaleUnknown => '크기 미측정';

  @override
  String get runningCoachCaptureFramingLandmarksGood => '머리와 신발 보임';

  @override
  String get runningCoachCaptureFramingLandmarksWarning => '머리·관절·신발 보이게';

  @override
  String get runningCoachCaptureFramingLandmarksUnknown => '관절 미측정';

  @override
  String get runningCoachCaptureFramingSideGood => '측면 구도';

  @override
  String get runningCoachCaptureFramingSideWarning => '정확한 측면으로 이동';

  @override
  String get runningCoachCaptureFramingSideUnknown => '측면 여부 미측정';

  @override
  String get runningCoachCaptureFramingVideoQualityGood => '선명하고 안정적';

  @override
  String get runningCoachCaptureFramingVideoQualityWarning => '카메라를 흔들림 없이 고정';

  @override
  String get runningCoachCaptureFramingVideoQualityLowConfidence =>
      '빛을 밝게 하고 흐림·가림을 피하세요';

  @override
  String get runningCoachCaptureFramingVideoQualityUnknown => '선명도 미측정';

  @override
  String get runningCoachCaptureFramingCheckWarning => '구도 확인 필요';

  @override
  String get runningCoachModeLive => '실시간';

  @override
  String get runningCoachModeVideo => '영상 분석';

  @override
  String get runningCoachModeLiveTitle => '달리는 동안 자세 확인';

  @override
  String get runningCoachModeVideoTitle => '영상으로 자세 분석';

  @override
  String get runningCoachModeLiveBody => '전신이 보이는 측면 구도에서 몇 걸음 달리면 바로 안내해요.';

  @override
  String get runningCoachModeVideoBody =>
      '측면 영상을 선택하면 정해진 프레임 예산으로 훑어 자세 리포트를 만들어요.';

  @override
  String get runningCoachModeLiveAction => '실시간 코칭 시작';

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
      '카메라는 흔들리지 않게 두고 밝고 고른 빛에서 촬영해 주세요. 가장 빠르고 안정적인 결과에는 3보 이상이 담긴 5~15초 구간이 좋아요.';

  @override
  String get runningCoachUploadGuideTitle => '동영상 업로드 가이드';

  @override
  String get runningCoachUploadGuideBody =>
      '예시 재생은 오버레이를 익히는 용도로만 보세요. 업로드 결과는 내 영상 프레임으로 판단합니다.';

  @override
  String get runningCoachUploadGuideStepSide =>
      '휴대폰을 달리는 라인과 직각으로, 엉덩이 높이에 맞춰 두고 러너가 좌우로 지나가게 촬영해 주세요.';

  @override
  String get runningCoachUploadGuideStepDistance =>
      '러너 앞뒤에 여유 공간을 두어 머리, 엉덩이, 무릎, 발목, 발, 팔꿈치, 손목이 모든 스텝에서 보이게 해 주세요.';

  @override
  String get runningCoachUploadGuideStepDuration =>
      '5~15초의 집중된 구간이 가장 빨라요. 긴 영상은 정해진 예산으로 표본을 뽑으므로 준비 걸음, 잦은 회전, 멈춘 장면은 가능한 한 빼 주세요.';

  @override
  String get runningCoachUploadGuideStepLight =>
      '밝고 고른 빛과 단순한 배경에서 촬영하고, 그림자, 잘린 발, 뒤로 지나가는 사람을 피해주세요.';

  @override
  String get runningCoachSampleTitle => '샘플 영상 가이드';

  @override
  String get runningCoachSampleBody =>
      '분석에 적합한 측면 예시를 먼저 재생하고, 같은 구도로 내 달리기 영상을 촬영하세요.';

  @override
  String get runningCoachSampleGuideAction => '샘플 영상 가이드 보기';

  @override
  String get runningCoachCaptureGuideAction => '촬영 가이드 보기';

  @override
  String get runningCoachCaptureGuideTitle => '촬영 가이드';

  @override
  String get runningCoachCaptureGuideBody =>
      '이 화면은 촬영 구도 안내예요. 자세 점수와 코칭은 내가 업로드한 영상에서만 계산해요.';

  @override
  String get runningCoachCaptureGuideChecklistTitle => '업로드 전 확인';

  @override
  String get runningCoachCaptureGuideChecklistCamera =>
      '카메라를 고정하고 달리는 선과 정확히 직각으로 두세요.';

  @override
  String get runningCoachCaptureGuideChecklistFraming =>
      '머리부터 양쪽 신발까지 계속 보이도록, 전신이 화면 높이의 50~75%를 차지하게 맞추세요.';

  @override
  String get runningCoachCaptureGuideChecklistClip =>
      '가장 빠르고 안정적인 결과에는 밝고 단순한 배경의 5~15초 영상이 좋아요. 긴 영상은 제한된 표본으로 분석해요.';

  @override
  String get runningCoachCaptureGuideAnalysisTitle => '분석 결과는 내 영상에서만';

  @override
  String get runningCoachCaptureGuideAnalysisBody =>
      '이 가이드는 촬영 품질을 보여 줍니다. 자세 점수와 교정은 업로드한 프레임과 신뢰도 기준으로 계산해요.';

  @override
  String get runningCoachSampleAnalysisLoadingTitle => '측정 오버레이를 추가하는 중';

  @override
  String get runningCoachSampleAnalysisLoadingBody =>
      '영상은 바로 재생할 수 있어요. 관절과 접지 프레임은 백그라운드에서 분석하고 있어요.';

  @override
  String get runningCoachSampleAnalysisFailedTitle => '샘플 분석을 사용할 수 없어요';

  @override
  String get runningCoachSampleAnalysisRetryAction => '샘플 분석 다시 시도';

  @override
  String get runningCoachSampleTechnicalDetailsTitle => '분석 원리 자세히 보기';

  @override
  String get runningCoachSampleVideoPlay => '샘플 영상 재생';

  @override
  String get runningCoachSampleVideoPause => '샘플 영상 일시정지';

  @override
  String get runningCoachSampleVideoUnavailable =>
      '샘플 영상을 불러오지 못했어요. 아래 촬영 가이드는 계속 확인할 수 있어요.';

  @override
  String get runningCoachSampleVideoRetryAction => '영상 다시 불러오기';

  @override
  String runningCoachSampleScoreValue(int score) {
    return '점수 $score';
  }

  @override
  String runningCoachSampleFrameLabel(int current, int total) {
    return '프레임 $current/$total';
  }

  @override
  String get runningCoachSampleFrameGuideTitle => '오버레이가 보여 주는 것';

  @override
  String get runningCoachSampleFrameGuideBody =>
      '예시 러너 위에 자세, 착지, 팔 타이밍, 프레임 판독이 직접 표시됩니다.';

  @override
  String get runningCoachSampleCueLean => '엉덩이-어깨 중심선이 엉덩이 수직선보다 앞으로 기울어진 정도';

  @override
  String get runningCoachSampleCueFrame => '머리, 엉덩이, 무릎, 발이 계속 보임';

  @override
  String get runningCoachSampleCueFoot => '발끝이 앞으로 향하고 엉덩이 아래 착지';

  @override
  String get runningCoachSampleCueArms => '팔꿈치를 접고 다리와 반대로 스윙';

  @override
  String get runningCoachSampleReferenceTab => '예시 A';

  @override
  String get runningCoachSampleMistakeTab => '예시 B';

  @override
  String get runningCoachSampleReferenceTitle => '세로 전신 측면 예시';

  @override
  String get runningCoachSampleMistakeTitle => '예시 B 판독';

  @override
  String get runningCoachSampleReferenceBody =>
      '머리부터 양쪽 신발까지 보이고, 러너가 화면 높이의 약 60%를 차지해 관절을 추적하기에 충분한 구도예요.';

  @override
  String get runningCoachSampleMistakeBody =>
      '이 클립은 다른 러너와 환경에서 촬영된 별도 예시입니다. 짝지어진 비교로 보지 말고 판독 표시만 확인하세요.';

  @override
  String get runningCoachSampleReferencePosture =>
      '몸통 기울기: 코치는 어깨-엉덩이 선을 읽고 현재 자세 값을 표시해요.';

  @override
  String get runningCoachSampleReferenceFoot =>
      '접지 지점: 코치는 착지 발과 엉덩이 선을 비교한 뒤 제동 위험을 판단해요.';

  @override
  String get runningCoachSampleReferenceKnee =>
      '접지 무릎: 코치는 감지된 엉덩이, 무릎, 발목으로 부하를 받는 무릎 각도를 표시해요.';

  @override
  String get runningCoachSampleReferenceArms =>
      '팔 각도: 코치는 샘플 프레임마다 어깨, 팔꿈치, 손목 위치를 읽어요.';

  @override
  String get runningCoachSampleReferenceFrame =>
      '프레임 품질: 사용 가능 프레임은 미리 정한 샘플 라벨이 아니라 보이는 신체 지점에 따라 달라져요.';

  @override
  String get runningCoachSampleMistakePosture =>
      '몸통 기울기: 코치는 이 클립에도 같은 자세 지표와 상태를 표시해요.';

  @override
  String get runningCoachSampleMistakeFoot =>
      '접지 지점: 코치는 감지된 착지 거리를 사용한 뒤 상태를 매겨요.';

  @override
  String get runningCoachSampleMistakeKnee =>
      '접지 무릎: 코치는 poseFrames에서 실제 접지 구간 무릎 각도를 읽어요.';

  @override
  String get runningCoachSampleMistakeArms =>
      '팔 각도: 코치는 고정 샘플값 대신 감지된 팔꿈치 각도를 사용해요.';

  @override
  String get runningCoachSampleMistakeBounce =>
      '바운스: 코치는 분석된 프레임에서 측정한 수직 움직임을 표시해요.';

  @override
  String get runningCoachSampleAnalysisMethodTitle => '코치가 분석하는 방식';

  @override
  String get runningCoachSampleAnalysisMethodBody =>
      '코치는 안정적인 측면 프레임을 샘플링하고, 보이는 신체 지점을 확인하고, 접지 구간을 추정한 뒤 각 지표를 신뢰도와 함께 점수화해요.';

  @override
  String get runningCoachSampleMethodPose =>
      '보이는 신체 지점: 어깨, 엉덩이, 무릎, 발목, 팔꿈치, 손목, 머리가 계속 보여야 해요.';

  @override
  String get runningCoachSampleMethodAngles =>
      '각도: 몸통 기울기, 접지 무릎, 팔꿈치 각도를 프레임마다 측정해요.';

  @override
  String get runningCoachSampleMethodContact =>
      '접지: 착지에 가까운 프레임으로 엉덩이 선 대비 발 착지 거리를 추정해요.';

  @override
  String get runningCoachSampleMethodConfidence =>
      '신뢰도: 추적 범위가 낮거나 안정 프레임이 적으면 다시 확인하라고 알려줘요.';

  @override
  String get runningCoachSampleRecordingGuideTitle => '촬영 설정 가이드';

  @override
  String get runningCoachCaptureTreadmillTab => '러닝머신';

  @override
  String get runningCoachCaptureOutdoorTab => '야외 통과';

  @override
  String get runningCoachCaptureTreadmillTitle => '러닝머신 권장 촬영법';

  @override
  String get runningCoachCaptureTreadmillBody =>
      '고정된 가로 화면의 정확한 측면 구도가 가장 안정적이에요. 세로 촬영은 전신과 러닝머신이 모두 보일 때만 사용하세요.';

  @override
  String get runningCoachCaptureTreadmillStepCamera =>
      '휴대폰을 벨트와 정확히 직각으로 두고 렌즈를 엉덩이 높이에 맞추세요. 앞이나 뒤에서 비스듬히 찍지 마세요.';

  @override
  String get runningCoachCaptureTreadmillStepDistance =>
      '약 3m 거리에서 시작한 뒤, 러너 키가 화면 높이의 50~75%가 되도록 거리를 조절하세요.';

  @override
  String get runningCoachCaptureTreadmillStepFrame =>
      '매 순간 머리, 양손, 양쪽 무릎, 양쪽 신발이 화면 안에 있어야 해요. 머리 위와 벨트 아래에 약간의 여백을 두세요.';

  @override
  String get runningCoachCaptureTreadmillStepClip =>
      '일정한 속도로 5~10초 촬영하세요. 가능하면 1080p 60fps, 최소 30fps를 사용하세요.';

  @override
  String get runningCoachCaptureOutdoorTitle => '고정 카메라 측면 통과 촬영';

  @override
  String get runningCoachCaptureOutdoorBody =>
      '멀리서 달려도 되지만, 전신이 관절을 추적할 만큼 크고 선명하게 보이는 거리까지만 가능해요.';

  @override
  String get runningCoachCaptureOutdoorStepCamera =>
      '휴대폰을 엉덩이 높이에 고정하고 달리는 선과 직각으로 두세요. 러너를 따라 회전하거나 확대하지 마세요.';

  @override
  String get runningCoachCaptureOutdoorStepDistance =>
      '러너가 화면 중앙을 지날 때 키가 화면 높이의 40~70%가 되도록 달리는 선을 정하세요.';

  @override
  String get runningCoachCaptureOutdoorStepFrame =>
      '들어오고 나갈 공간은 남기되, 모든 관절이 보이는 깨끗한 3~6보만 남도록 영상을 잘라 주세요.';

  @override
  String get runningCoachCaptureOutdoorStepClip =>
      '밝고 고른 빛과 단순한 배경을 사용하세요. 잔상, 그림자, 잘린 발, 뒤로 지나가는 사람을 피하세요.';

  @override
  String get runningCoachCaptureOutdoorDistanceWarning =>
      '러너 키가 화면 높이의 40%보다 작으면 멀리서 촬영하지 않는 것이 좋아요. 달리는 선을 가까이 옮기거나 촬영 전에 광학 줌을 맞추세요.';

  @override
  String get runningCoachCaptureMoreDetails => '촬영 세부 설정 보기';

  @override
  String get runningCoachSampleProcessTitle => '실제 영상 분석 흐름';

  @override
  String get runningCoachSampleProcessBody =>
      '오버레이는 코치가 보는 순서대로 보여줘요. 안정 프레임을 고르고, 보이는 신체 지점을 고정하고, 몸 선을 잇고, 각도를 잰 뒤 착지 근거를 확인해요.';

  @override
  String get runningCoachSamplePhaseFrame => '프레임 샘플';

  @override
  String get runningCoachSamplePhaseJoints => '신체 지점 찾기';

  @override
  String get runningCoachSamplePhaseMuscles => '몸 부하 표시';

  @override
  String get runningCoachSamplePhaseSkeleton => '몸 선 연결';

  @override
  String get runningCoachSamplePhaseAngles => '각도 측정';

  @override
  String get runningCoachSamplePhaseContactScore => '착지 근거 확인';

  @override
  String get runningCoachSamplePhaseDenseContact => '접지 프레임 검증';

  @override
  String runningCoachSampleContactFrameLabel(Object time) {
    return '접지 $time';
  }

  @override
  String runningCoachContactTimestampSeconds(String seconds) {
    return '$seconds초';
  }

  @override
  String get runningCoachSampleDecisionTitle => '판정 근거';

  @override
  String get runningCoachSampleMetricPosture => '몸통 기울기';

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
  String get runningCoachSamplePoseOverlayUnavailable => '관절 프레임 없음';

  @override
  String runningCoachSampleReadoutValue(
      Object metric, Object value, Object status) {
    return '$metric: $value · $status';
  }

  @override
  String get runningCoachSampleOverlayPosture => '몸통 기울기 값';

  @override
  String get runningCoachSampleOverlayArms => '팔 값';

  @override
  String get runningCoachSampleOverlayFoot => '착지 값';

  @override
  String get runningCoachSampleOverlayBounce => '바운스 값';

  @override
  String get runningCoachSampleOverlayFrames => '관절 프레임';

  @override
  String get runningCoachSampleMistakeOverlayPosture => '몸통 기울기 값';

  @override
  String get runningCoachSampleMistakeOverlayArms => '팔 값';

  @override
  String get runningCoachSampleMistakeOverlayFoot => '착지 값';

  @override
  String get runningCoachSampleMistakeOverlayBounce => '바운스 값';

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
  String get runningCoachSampleMetricDetailStatusLabel => '판독';

  @override
  String get runningCoachSampleMetricDetailKeyPositionTitle => '핵심 위치';

  @override
  String get runningCoachSampleMetricDetailReferenceTitle => '예시 A 동작';

  @override
  String get runningCoachSampleMetricDetailReviewTitle => '예시 B 동작';

  @override
  String get runningCoachSampleMetricDetailHowReadTitle => '오버레이가 읽는 방식';

  @override
  String get runningCoachSampleMetricDetailGoodRangeTitle => '좋은 범위';

  @override
  String get runningCoachSamplePostureDetailGoodRange =>
      '몸통 기울기는 코칭 가이드 범위와 이 클립의 실제 측정값을 함께 비교해요.';

  @override
  String get runningCoachSamplePostureDetailKeyPosition =>
      '중간 접지 위치: 앱은 엉덩이 중심에서 위로 수직선을 세우고, 엉덩이-어깨 중심선과 비교해요.';

  @override
  String get runningCoachSamplePostureDetailReference =>
      '예시 A는 허리를 접지 않고 어깨가 엉덩이보다 살짝 앞에 있는 모습을 보여 줘요.';

  @override
  String get runningCoachSamplePostureDetailReview =>
      '측정된 몸통 기울기가 이 러닝의 코칭 범위를 벗어나면 확인 상태로 표시돼요.';

  @override
  String get runningCoachSamplePostureDetailHowRead =>
      '앱은 좌우 어깨와 엉덩이를 평균 내 몸통 축을 만들고, 그 축이 수직선에서 몇 도 벗어났는지 측정해요.';

  @override
  String get runningCoachSampleArmsDetailGoodRange =>
      '팔꿈치 80-105도, 손은 갈비뼈 가까이 앞뒤로 움직이고 반대쪽 팔과 다리가 짝을 이뤄야 해요.';

  @override
  String get runningCoachSampleArmsDetailKeyPosition =>
      '팔 드라이브 위치: 반대쪽 무릎이 앞으로 나오는 순간 팔꿈치 각도를 읽어요.';

  @override
  String get runningCoachSampleArmsDetailReference =>
      '예시 A는 팔꿈치를 작게 접고 갈비뼈 옆에서 앞뒤로 흔드는 모습을 보여 줘요.';

  @override
  String get runningCoachSampleArmsDetailReview =>
      '확인 샘플은 팔꿈치가 많이 열려 보폭 리듬이 느려지고 몸통 회전이 커질 수 있어요.';

  @override
  String get runningCoachSampleArmsDetailHowRead =>
      '앱은 어깨, 팔꿈치, 손목 위치를 연결하고 팔꿈치가 지나치게 열리는 프레임을 표시해요.';

  @override
  String get runningCoachSampleLandingDetailGoodRange =>
      '착지는 엉덩이 선 가까이 닿는 코칭 가이드 범위와 이 클립의 실제 측정값을 함께 비교해요.';

  @override
  String get runningCoachSampleLandingDetailKeyPosition =>
      '첫 접지 위치: 발, 발목, 엉덩이 선으로 발이 몸 아래에 떨어지는지 봐요.';

  @override
  String get runningCoachSampleLandingDetailReference =>
      '예시 A는 발이 엉덩이 선 가까이에 닿아 접지가 앞으로 이어지는 모습을 보여 줘요.';

  @override
  String get runningCoachSampleLandingDetailReview =>
      '확인 샘플은 발이 엉덩이보다 너무 앞에 떨어져 브레이크처럼 읽혀요.';

  @override
  String get runningCoachSampleLandingDetailHowRead =>
      '앱은 착지 구간에서 엉덩이 선과 접지 발목, 발끝 사이의 가로 거리를 측정해요.';

  @override
  String get runningCoachSampleBounceDetailGoodRange =>
      '바운스는 상체 높이 변화에 대한 코칭 가이드 범위와 이 클립의 실제 측정값을 함께 비교해요.';

  @override
  String get runningCoachSampleBounceDetailKeyPosition =>
      '보폭 구간: 여러 프레임에서 상체 기준점의 이동 경로를 비교해요.';

  @override
  String get runningCoachSampleBounceDetailReference =>
      '예시 A는 위아래 움직임이 작아 에너지가 앞으로 유지되는 모습을 보여 줘요.';

  @override
  String get runningCoachSampleBounceDetailReview =>
      '확인 샘플은 몸이 더 크게 뜨고 내려와 접지 타이밍이 불안정해져요.';

  @override
  String get runningCoachSampleBounceDetailHowRead =>
      '앱은 한 프레임의 튐을 줄이기 위해 상체 높이 표본의 가운데 80% 범위를 사용해요. 점프 높이가 아니라 코칭용 추정값이에요.';

  @override
  String get runningCoachDenseContactEvidenceTitle => '정밀 접지 근거';

  @override
  String get runningCoachDenseContactEvidenceBody =>
      '영상 전체를 먼저 스캔하고, 발 착지와 접지 무릎 값은 검증된 접지 주변에서 다시 읽은 고밀도 프레임만 사용해요.';

  @override
  String get runningCoachDenseContactKinematicEstimateLabel => '발 궤적으로 보완';

  @override
  String get runningCoachDenseContactKinematicEstimateBody =>
      '바닥선이 흔들리면 보이는 착지 다리의 엉덩이·무릎·발목과 발의 위아래 궤적으로 접지 구간을 보완해요. 이 방식은 반복된 3보 이상에서만 점수와 코칭에 사용해요.';

  @override
  String get runningCoachDenseContactCoarseSamplesLabel => '전체 스캔';

  @override
  String get runningCoachDenseContactDenseSamplesLabel => '접지 정밀';

  @override
  String get runningCoachDenseContactWindowsLabel => '구간';

  @override
  String get runningCoachDenseContactCandidateFramesLabel => '접지 후보 프레임';

  @override
  String get runningCoachDenseContactFramesLabel => '접지 프레임';

  @override
  String runningCoachDenseContactVerificationProgress(
      int verified, int required) {
    return '$verified/$required회 검증';
  }

  @override
  String get runningCoachDenseContactConfidenceLabel => '근거';

  @override
  String get runningCoachDenseContactTimesLabel => '시각';

  @override
  String get runningCoachDenseContactUnavailable => '검증된 접지 없음';

  @override
  String get runningCoachEvidenceTitle => '내 영상의 근거';

  @override
  String get runningCoachEvidenceBody =>
      '이 프레임은 분석한 클립에서 가져왔고 선택한 코칭 포인트를 뒷받침합니다.';

  @override
  String get runningCoachEvidenceDetailsTitle => '근거와 측정 방식';

  @override
  String get runningCoachEvidenceInsufficientTitle => '이 클립을 다시 촬영해 주세요';

  @override
  String get runningCoachEvidenceInsufficientBody =>
      '이 포인트를 판단할 안정 프레임이 부족해 정확한 점수를 보여 주지 않습니다.';

  @override
  String runningCoachEvidenceMetricUnavailableTitle(Object metric) {
    return '$metric 측정은 아직 확정할 수 없어요';
  }

  @override
  String runningCoachEvidenceMetricUnavailableBody(Object metric) {
    return '$metric의 근거가 부족해 점수와 코칭은 보류했어요. 다른 항목의 측정은 그대로 확인할 수 있어요.';
  }

  @override
  String get runningCoachMeasurementStatusVerified => '확정 측정';

  @override
  String get runningCoachMeasurementStatusObserved => '영상 관찰값';

  @override
  String get runningCoachMeasurementStatusUnavailable => '측정 불가';

  @override
  String get runningCoachMeasurementCoverageTitle => '이번 영상의 항목별 상태';

  @override
  String get runningCoachMeasurementCoverageBody =>
      '항목별로 독립 검증합니다. 접지 근거가 부족해도 팔·상체 등의 측정이 함께 무효가 되지는 않습니다.';

  @override
  String get runningCoachScoreWithheldLabel => '점수 보류';

  @override
  String get runningCoachScoreWithheldSummary => '이 영상으로는 검증된 점수를 낼 수 없어요.';

  @override
  String get runningCoachScoreWithheldValue => '—';

  @override
  String runningCoachScoreWithheldContactReason(Object reason) {
    return '착지 근거가 충분하지 않아요: $reason';
  }

  @override
  String get runningCoachScoreWithheldGenericReason =>
      '필수 측정 중 일부가 제한되어 추정 점수 대신 점수를 보류했어요.';

  @override
  String get runningCoachMeasuredMetricsTitle => '측정 지표';

  @override
  String get runningCoachMeasuredMetricsBody =>
      '영상이 뒷받침하는 값만 확정 측정으로 표시해요. 제한된 관찰값은 점수나 드릴 없이 보여 줍니다.';

  @override
  String get runningCoachReferenceRangeNotice =>
      '기준 범위는 일반 코칭 참고값이며 개인별 의학적 한계나 부상 위험 한계가 아니에요.';

  @override
  String get runningCoachMetricVerticalBounceLabel => '상하 흔들림 (%)';

  @override
  String runningCoachMeasuredMetricSpmValue(Object value) {
    return '$value spm';
  }

  @override
  String runningCoachMeasuredMetricMsValue(Object value) {
    return '$value ms';
  }

  @override
  String get runningCoachMeasuredMetricWithinReference => '일반 기준 안';

  @override
  String get runningCoachMeasuredMetricNearReferenceEdge => '기준 경계 근처';

  @override
  String get runningCoachMeasuredMetricOutsideReference => '일반 기준 밖';

  @override
  String get runningCoachMeasuredMetricInconsistent => '샘플 간 변동 큼';

  @override
  String get runningCoachMeasuredMetricLimited => '근거 제한';

  @override
  String get runningCoachMeasuredMetricUnavailable => '이 영상에서는 사용 불가';

  @override
  String runningCoachMeasuredMetricSampleCount(int count) {
    return '$count개 샘플';
  }

  @override
  String get runningCoachMeasuredMetricNoSamples => '방어 가능한 샘플 없음';

  @override
  String runningCoachMeasuredMetricEvidenceDetail(
      Object quality, Object samples) {
    return '$quality · $samples';
  }

  @override
  String runningCoachMeasuredMetricEvidenceReasonDetail(
      Object quality, Object samples, Object reason) {
    return '$quality · $samples · $reason';
  }

  @override
  String get runningCoachQualityReasonLabelLowCoverage => '낮은 커버리지';

  @override
  String get runningCoachQualityReasonLabelLimitedSamples => '샘플 부족';

  @override
  String get runningCoachQualityReasonLabelContactPhaseProxy => '착지 대체값';

  @override
  String get runningCoachQualityReasonLabelKinematicContact => '움직임 기반 착지';

  @override
  String get runningCoachQualityReasonLabelLowConfidence => '낮은 신뢰도';

  @override
  String get runningCoachQualityReasonLabelMissingContact => '착지 근거 없음';

  @override
  String get runningCoachQualityReasonLabelMissingPoseFrames => '자세 프레임 없음';

  @override
  String get runningCoachQualityReasonLabelMissingMeasuredFrames => '측정 프레임 없음';

  @override
  String get runningCoachPerspectiveTooSmallLabel => '너무 멀거나 작음';

  @override
  String get runningCoachPerspectiveNotSideOnLabel => '측면 부족';

  @override
  String get runningCoachPerspectiveBodyCutOffLabel => '몸이 잘림';

  @override
  String get runningCoachPerspectiveScaleDriftLabel => '거리 변화';

  @override
  String get runningCoachPerspectiveTooSmallReason =>
      '러너가 화면에서 너무 작아 위치 기반 코칭이 제한돼요.';

  @override
  String get runningCoachPerspectiveNotSideOnReason =>
      '대각선 또는 정면에 가까워 하체 착지 코칭이 제한돼요.';

  @override
  String get runningCoachPerspectiveBodyCutOffReason =>
      '많은 프레임에서 몸이 잘려 해당 측정이 제한돼요.';

  @override
  String get runningCoachPerspectiveScaleDriftReason =>
      '클립 중 러너 크기가 크게 변해 거리 민감 측정이 제한돼요.';

  @override
  String get runningCoachPerspectiveTooSmallRetake =>
      '전신이 보이도록 더 가까운 측면에서 다시 촬영해 주세요.';

  @override
  String get runningCoachPerspectiveNotSideOnRetake =>
      '러너가 화면을 가로질러 움직이는 정확한 측면에서 다시 촬영해 주세요.';

  @override
  String get runningCoachPerspectiveBodyCutOffRetake =>
      '머리, 골반, 무릎, 발이 전체 클립에서 프레임 안에 있게 해 주세요.';

  @override
  String get runningCoachPerspectiveScaleDriftRetake =>
      '러너 크기가 일정하게 보이도록 카메라 거리를 유지해 주세요.';

  @override
  String get runningCoachPerspectiveGenericRetake =>
      '전신이 보이는 안정적인 측면 영상으로 다시 촬영해 주세요.';

  @override
  String get runningCoachEvidenceVideoUnavailable =>
      '저장된 영상 파일을 사용할 수 없어요. 분석된 프레임의 자세 오버레이는 보여 줍니다.';

  @override
  String get runningCoachEvidencePoseFrameOnly =>
      '분석된 자세 프레임을 보여 줍니다. 이 화면에는 영상 파일이 저장되지 않았어요.';

  @override
  String runningCoachEvidenceTimestamp(Object time) {
    return '근거 프레임 $time';
  }

  @override
  String runningCoachEvidenceFrameSummary(Object frame, Object value) {
    return '$frame: $value';
  }

  @override
  String get runningCoachEvidencePreviousFrame => '이전 근거 프레임';

  @override
  String get runningCoachEvidenceNextFrame => '다음 근거 프레임';

  @override
  String get runningCoachEvidenceImageViewerTitle => '근거 이미지';

  @override
  String runningCoachEvidenceImageViewerMetadata(
      String kind, String role, String side, String time) {
    return '$kind · $role · $side · $time';
  }

  @override
  String get runningCoachEvidenceFocusView => '러너 확대 보기';

  @override
  String get runningCoachEvidenceOriginalView => '전체 프레임 보기';

  @override
  String get runningCoachEvidenceOverlayOn => '오버레이 보기';

  @override
  String get runningCoachEvidenceOverlayOff => '오버레이 숨기기';

  @override
  String get runningCoachEvidencePlay => '근거 영상 재생';

  @override
  String get runningCoachEvidencePause => '근거 영상 일시정지';

  @override
  String runningCoachEvidenceFrameCount(int current, int total) {
    return '근거 $current/$total';
  }

  @override
  String get runningCoachEvidenceWhatSeenLabel => '본 내용';

  @override
  String get runningCoachEvidenceOverlayBody =>
      '색 가이드는 이번 코칭 판단에 사용한 움직임만 보여 줍니다. 원본 영상은 바뀌지 않습니다.';

  @override
  String get runningCoachEvidenceCurrentOverlayTitle => '이 프레임에서 본 측정 지점';

  @override
  String get runningCoachEvidenceCurrentOverlayBody =>
      '빨간 선과 표시점은 이번 코칭 판단에 쓴 부위만 보여 줍니다.';

  @override
  String get runningCoachEvidenceTransitionTitle => '현재에서 다음으로';

  @override
  String get runningCoachEvidenceTransitionBody =>
      '파란 목표는 영상 위가 아니라 다음 동작에서 맞출 방향이에요.';

  @override
  String get runningCoachGoalMotionTitle => '내 프레임과 목표 동작';

  @override
  String get runningCoachGoalMotionBody => '같은 착지 단계에서 비교하고 한 가지 목표만 따라 해 보세요.';

  @override
  String get runningCoachGoalMotionActualLabel => '내 프레임';

  @override
  String get runningCoachGoalMotionTargetLabel => '목표 러너';

  @override
  String get runningCoachGoalMotionFootnote => '이 표시는 착지 이동 방향만 보여 줍니다.';

  @override
  String get runningCoachGoalMotionPlay => '목표 움직임 재생';

  @override
  String get runningCoachGoalMotionPause => '목표 움직임 일시정지';

  @override
  String get runningCoachTwoDComparisonTitle => '러너 동작 비교';

  @override
  String get runningCoachTwoDCurrentLabel => '내 측정 자세';

  @override
  String get runningCoachTwoDTargetLabel => '다음 착지';

  @override
  String get runningCoachTwoDVideoOverlayTitle => '업로드한 영상 위 측정';

  @override
  String get runningCoachCoordinateRigUnavailable =>
      '이 프레임의 관절 좌표가 부족해 동작 비교를 만들 수 없어요.';

  @override
  String get runningCoachPoseComparisonTitle => '측정 자세 비교';

  @override
  String get runningCoachPoseComparisonCurrentLabel => '현재 측정 자세';

  @override
  String get runningCoachPoseComparisonTargetLabel => '기준 목표';

  @override
  String get runningCoachPoseComparisonUnavailable =>
      '이 프레임에는 나란히 비교할 측정 관절 좌표가 충분하지 않아요.';

  @override
  String get runningCoachHistoryEvidenceUnavailableTitle => '저장된 관절 근거 없음';

  @override
  String get runningCoachHistoryEvidenceUnavailableBody =>
      '이전 버전에서 저장한 기록이라 자세 프레임은 없어요. 점수와 코칭 목표는 그대로 볼 수 있어요.';

  @override
  String get runningCoachEvidenceCurrentLabel => '현재';

  @override
  String get runningCoachEvidenceNextLabel => '다음';

  @override
  String runningCoachEvidenceWhatSeenBody(Object metric, Object time) {
    return '내 클립 $time의 $metric입니다.';
  }

  @override
  String get runningCoachEvidenceWhyMattersLabel => '왜 중요한가';

  @override
  String get runningCoachEvidenceTryLabel => '해볼 동작';

  @override
  String get runningCoachEvidenceRetakeLabel => '다시 찍는 법';

  @override
  String get runningCoachEvidenceRetakeBody =>
      '측면에서 전신과 양발이 보이게 찍어 주세요. 몇 걸음 동안 휴대폰을 흔들지 마세요.';

  @override
  String get runningCoachEvidenceQualityLimitedBadge => '근거 부족';

  @override
  String get runningCoachEvidenceQualityStableBadge => '관절 추적 안정적';

  @override
  String get runningCoachEvidenceQualityCheckBadge => '관절 추적 확인 필요';

  @override
  String get runningCoachEvidenceReasonLowConfidence =>
      '몸 지점이 흔들리거나 흐려져 확실히 읽기 어려웠어요.';

  @override
  String get runningCoachEvidenceReasonLimitedFrames =>
      '이 지표를 판단할 안정 프레임이 너무 적었어요.';

  @override
  String get runningCoachEvidenceReasonMissingPoseFrames =>
      '이 클립에 저장된 분석 자세 프레임이 없어요.';

  @override
  String get runningCoachEvidenceReasonMissingContact =>
      '이 하체 지표를 뒷받침할 접지 프레임이 충분히 안정적이지 않았어요.';

  @override
  String get runningCoachEvidenceReasonMissingMeasuredFrames =>
      '저장된 자세 프레임 안에 이 지표를 방어적으로 읽을 수 있는 순간이 없어요.';

  @override
  String get runningCoachObservedValueBadge => '영상 관찰값';

  @override
  String get runningCoachObservedValueLabel => '영상 관찰값';

  @override
  String get runningCoachObservedValueBody =>
      '이 값은 영상에서 관찰된 좌표예요. 근거가 충분하지 않아 점수·좋음/개선 판단·드릴에는 쓰지 않았어요.';

  @override
  String get runningCoachMeasurementUnavailableValue => '확정 측정값 없음';

  @override
  String get runningCoachContactRejectionMissingFootLandmark =>
      '접지 후보 구간에서 발·발목 관절이 충분히 추적되지 않았어요. 양발이 화면 안에 계속 보이게 촬영해 주세요.';

  @override
  String get runningCoachContactRejectionMissingContactJointChain =>
      '착지 후보 다리의 엉덩이·무릎·발목이 한쪽에서 함께 보이지 않았어요. 한쪽 옆모습과 다리 전체가 보이게 촬영해 주세요.';

  @override
  String get runningCoachContactRejectionOutsideGround =>
      '발 위치가 접지면 가까이에서 반복적으로 확인되지 않았어요. 카메라를 고정하고 신발과 바닥선이 함께 보이게 촬영해 주세요.';

  @override
  String get runningCoachContactRejectionLowConfidence =>
      '접지 후보 구간의 관절 신뢰도가 낮아요. 밝은 곳에서 흔들림 없이 촬영해 주세요.';

  @override
  String get runningCoachContactRejectionUnstableMotion =>
      '발의 위아래 움직임이 접지 순간으로 안정적으로 이어지지 않았어요. 3~6보가 선명하게 담긴 측면 영상을 사용해 주세요.';

  @override
  String get runningCoachContactRejectionNotDescending =>
      '발이 접지 전에 바닥 가까운 구간으로 내려오지 않아 회수 또는 공중 프레임으로 처리했어요. 바닥선이 보이는 안정적인 측면 영상을 촬영해 주세요.';

  @override
  String get runningCoachContactRejectionInsufficientMotionWindow =>
      '접지 전후의 연속 프레임이 부족해 발의 움직임을 확인하지 못했어요. 일정한 속도로 5~10초를 촬영해 주세요.';

  @override
  String get runningCoachContactRejectionInsufficientContactPersistence =>
      '발이 바닥 가까이에 보였지만 연속된 접지 상태는 확인하지 못했어요. 양발과 바닥선이 보이게 3~6보를 촬영해 주세요.';

  @override
  String get runningCoachEvidenceContactLabel => '접지 근거';

  @override
  String get runningCoachEvidencePostureLabel => '자세 프레임';

  @override
  String get runningCoachEvidenceBounceLabel => '바운스 프레임';

  @override
  String get runningCoachEvidenceLandingLabel => '착지 프레임';

  @override
  String get runningCoachEvidenceKneeLabel => '무릎 프레임';

  @override
  String get runningCoachEvidenceArmLabel => '팔 프레임';

  @override
  String get runningCoachEvidenceSamplesLabel => '샘플';

  @override
  String get runningCoachEvidenceReliabilityLabel => '신뢰도';

  @override
  String get runningCoachEvidenceAggregateValueLabel => '대표값';

  @override
  String get runningCoachEvidenceGuideRangeLabel => '코칭 가이드';

  @override
  String get runningCoachEvidenceScoreCenterLabel => '판정 중심';

  @override
  String get runningCoachEvidenceFrameRangeLabel => '근거 프레임값';

  @override
  String runningCoachEvidenceFrameRangeValue(Object minimum, Object maximum) {
    return '$minimum–$maximum';
  }

  @override
  String runningCoachEvidenceDegreesValue(Object value) {
    return '$value°';
  }

  @override
  String runningCoachEvidencePercentValue(Object value) {
    return '$value%';
  }

  @override
  String runningCoachEvidenceRatioValue(Object value) {
    return '$value×';
  }

  @override
  String runningCoachEvidenceAverageLabel(int samples) {
    return '평균 · $samples 프레임';
  }

  @override
  String get runningCoachMetricScoreBasis => '점수는 대표값이 판정 중심에 얼마나 가까운지 나타냅니다.';

  @override
  String get runningCoachEvidenceWhyThisResultLabel => '이 결과의 이유';

  @override
  String get runningCoachEvidenceVideoMissingTitle => '영상을 사용할 수 없음';

  @override
  String get runningCoachEvidenceVideoMissingBody =>
      '저장된 영상이 없어 이 지표는 텍스트 근거 요약으로 보여 줍니다.';

  @override
  String get runningCoachEvidenceMetricRhythm => '리듬';

  @override
  String get runningCoachEvidenceMetricPosture => '자세';

  @override
  String get runningCoachEvidenceMetricLanding => '착지';

  @override
  String get runningCoachEvidenceMetricLandingObserved => '확인된 접지';

  @override
  String get runningCoachEvidenceMetricLandingCandidate => '접지 후보';

  @override
  String get runningCoachEvidenceMetricKnee => '무릎';

  @override
  String get runningCoachEvidenceMetricBounce => '바운스';

  @override
  String get runningCoachEvidenceMetricArms => '팔';

  @override
  String runningCoachEvidenceRhythmValue(Object cadence, Object stepTime) {
    return '$cadence spm · $stepTime ms';
  }

  @override
  String get runningCoachEvidenceWhyRhythm => '검증된 접지 시각으로 케이던스와 스텝 시간을 계산했어요.';

  @override
  String get runningCoachEvidenceWhyPosture =>
      '안정적인 자세 프레임 중 측정된 전방 기울기 값에 가장 가까운 프레임을 골랐어요.';

  @override
  String get runningCoachEvidenceWhyLanding =>
      '검증된 접지 프레임에서 발과 엉덩이 사이 착지 거리를 읽었어요.';

  @override
  String get runningCoachEvidenceWhyKnee => '검증된 지지 구간 프레임에서 이 무릎 각도를 읽었어요.';

  @override
  String get runningCoachEvidenceWhyBounce => '엉덩이 궤적의 높은 지점과 낮은 지점이 바운스 근거예요.';

  @override
  String get runningCoachEvidenceWhyArms => '팔 근거는 팔꿈치 각도를 실제로 읽은 프레임에서 가져왔어요.';

  @override
  String get runningCoachEvidenceRoleRhythmContact => '검증된 접지 시각';

  @override
  String get runningCoachEvidenceRolePosture => '대표 자세 프레임';

  @override
  String get runningCoachEvidenceRoleLowering => '접지 전 하강 구간';

  @override
  String get runningCoachEvidenceRoleInitialContact => '초기 접지 프레임';

  @override
  String get runningCoachEvidenceRoleKneeFlexion => '지지 중 무릎이 가장 굽혀진 구간';

  @override
  String get runningCoachEvidenceRoleRecoveryKneeFlexion => '회수 중 무릎 접힘';

  @override
  String get runningCoachEvidenceRolePushOff => '밀어내기 프레임';

  @override
  String get runningCoachEvidenceRoleTrajectoryHigh => '엉덩이 궤적의 높은 지점';

  @override
  String get runningCoachEvidenceRoleTrajectoryLow => '엉덩이 궤적의 낮은 지점';

  @override
  String get runningCoachEvidenceRoleArmClosed => '팔꿈치가 닫힌 구간';

  @override
  String get runningCoachEvidenceRoleArmOpen => '팔꿈치가 열린 구간';

  @override
  String get runningCoachMyVideoEvidenceTitle => '내 영상 근거';

  @override
  String runningCoachEvidenceSummaryTimestamp(Object time, int samples) {
    return '$time · 샘플 $samples개';
  }

  @override
  String get runningCoachOpenMyVideoEvidenceAction => '내 영상 근거에서 보기';

  @override
  String get runningCoachPoseEvidenceBlockerFullBody =>
      '머리와 양발이 화면 안에 남을 때까지 뒤로 가세요.';

  @override
  String get runningCoachPoseEvidenceBlockerSideView => '안정적인 측면 자세를 유지해 주세요.';

  @override
  String get runningCoachPoseEvidenceBlockerCoreJoints =>
      '코치가 관절을 찾을 수 있게 카메라를 흔들지 마세요.';

  @override
  String get runningCoachPoseEvidenceBlockerGaitPhase =>
      '같은 측면 구도에서 몇 걸음 더 달려 보세요.';

  @override
  String get runningCoachFieldValidationTitle => '현장 검증';

  @override
  String get runningCoachFieldValidationPrivacyNote =>
      '저장된 카운터와 관절 근거만 사용합니다. 카메라 프레임은 저장하지 않습니다.';

  @override
  String get runningCoachFieldValidationStatusInsufficient => '근거 부족';

  @override
  String get runningCoachFieldValidationStatusNeedsReview => '리뷰 필요';

  @override
  String get runningCoachFieldValidationStatusReady => '보정 준비됨';

  @override
  String get runningCoachFieldValidationBodyInsufficient =>
      '임계값 튜닝에 쓸 안정적인 현장 근거가 부족해요. 아래 항목을 고친 뒤 다시 캡처해 주세요.';

  @override
  String get runningCoachFieldValidationBodyNeedsReview =>
      '현장 근거는 확보됐지만, 임계값을 조정하기 전에 측정 항목을 확인해 주세요.';

  @override
  String get runningCoachFieldValidationBodyReady =>
      '이 기록은 임계값 보정 비교에 사용할 수 있어요. 기준을 바꾸기 전에 같은 프로필로 한 번 더 반복해 주세요.';

  @override
  String runningCoachFieldValidationProfileValue(Object profile) {
    return '프로필: $profile';
  }

  @override
  String runningCoachFieldValidationQualityValue(int score) {
    return '현장 품질 $score%';
  }

  @override
  String get runningCoachFieldValidationNextChecksTitle => '다음 캡처 확인';

  @override
  String get runningCoachFieldValidationAllChecksPassed =>
      '측정 가능한 현장 확인을 모두 통과했어요.';

  @override
  String get runningCoachFieldValidationCheckCaptureReadiness => '캡처 준비도';

  @override
  String get runningCoachFieldValidationCheckPhaseCoverage => '구간 확보';

  @override
  String get runningCoachFieldValidationCheckTrackedFrames => '추적 프레임';

  @override
  String get runningCoachFieldValidationCheckUsableSamples => '사용 가능한 자세 샘플';

  @override
  String get runningCoachFieldValidationCheckTimingConfidence => '타이밍 신뢰도';

  @override
  String get runningCoachFieldValidationCheckSideViewConfidence => '측면 신뢰도';

  @override
  String get runningCoachFieldValidationCheckTrackingConfidence => '트래킹 신뢰도';

  @override
  String get runningCoachFieldValidationCheckBodyVisibility => '전신 이탈';

  @override
  String get runningCoachFieldValidationCheckStepEvidence => '스텝 근거';

  @override
  String get runningCoachFieldValidationCheckLandingEvidence => '착지 근거';

  @override
  String runningCoachFieldValidationCountValue(int observed, int required) {
    return '$observed / 목표 $required';
  }

  @override
  String runningCoachFieldValidationPercentValue(int current, int target) {
    return '$current% / 목표 $target%';
  }

  @override
  String runningCoachFieldValidationPercentMaxValue(int current, int target) {
    return '$current% / 최대 $target%';
  }

  @override
  String get runningCoachCalibrationReadinessTitle => '보정 반복 준비도';

  @override
  String get runningCoachCalibrationReadinessStatusCurrentNotReady =>
      '현재 캡처 준비 안 됨';

  @override
  String get runningCoachCalibrationReadinessStatusNeedsMore =>
      '같은 프로필 세션 더 필요';

  @override
  String get runningCoachCalibrationReadinessStatusVariationReview =>
      '변동 리뷰 필요';

  @override
  String get runningCoachCalibrationReadinessStatusReady => '임계값 보정 준비됨';

  @override
  String get runningCoachCalibrationReadinessBodyCurrentNotReady =>
      '이 기록은 아직 현장 검증 준비가 되지 않았어요. 반복성에 쓰기 전에 현장 확인을 먼저 고쳐 주세요.';

  @override
  String get runningCoachCalibrationReadinessBodyNeedsMore =>
      '임계값 보정 전에 같은 프로필로 현장 검증 준비가 된 세션을 최소 3개 저장해 주세요.';

  @override
  String get runningCoachCalibrationReadinessBodyVariationReview =>
      '같은 프로필의 캡처 변동이 유료 품질 임계값 보정에 쓰기에는 커요. 조정 전에 확인 항목을 검토해 주세요.';

  @override
  String get runningCoachCalibrationReadinessBodyReady =>
      '이 프로필은 임계값 보정에 쓸 반복 가능한 현장 근거가 충분해요.';

  @override
  String get runningCoachCalibrationReadinessPrivacyNote =>
      '저장된 실시간 스프린트 리포트 카운터와 관절 근거 요약만 사용합니다. 카메라 프레임, 업로드, 원본 영상은 사용하지 않으며 프로필과 임계값은 변경하지 않습니다.';

  @override
  String runningCoachCalibrationReadinessScoreValue(int score) {
    return '반복성 $score%';
  }

  @override
  String runningCoachCalibrationReadinessReadySessionsValue(
      int ready, int required) {
    return '준비 $ready/$required';
  }

  @override
  String runningCoachCalibrationReadinessSameProfileSessionsValue(int count) {
    return '같은 프로필 $count';
  }

  @override
  String get runningCoachCalibrationReadinessChecksTitle => '간단 확인';

  @override
  String get runningCoachCalibrationReadinessCheckCurrentFieldValidation =>
      '현재 현장 검증';

  @override
  String get runningCoachCalibrationReadinessCheckSameProfileReadySessions =>
      '같은 프로필 준비 세션';

  @override
  String get runningCoachCalibrationReadinessCheckAverageFieldQuality =>
      '평균 현장 품질';

  @override
  String get runningCoachCalibrationReadinessCheckTimingVariation =>
      '타이밍 신뢰도 변동';

  @override
  String get runningCoachCalibrationReadinessCheckSideViewVariation =>
      '측면 신뢰도 변동';

  @override
  String get runningCoachCalibrationReadinessCheckTrackingVariation =>
      '트래킹 신뢰도 변동';

  @override
  String get runningCoachCalibrationReadinessCheckTrackedFrameVariation =>
      '추적 프레임 비율 변동';

  @override
  String get runningCoachCalibrationReadinessCheckEligiblePoseVariation =>
      '적격 자세 비율 변동';

  @override
  String get runningCoachCalibrationReadinessCheckLandingContactVariation =>
      '착지/접촉 비율 변동';

  @override
  String runningCoachCalibrationReadinessCheckCountValue(
      int observed, int required) {
    return '$observed / 필요 $required';
  }

  @override
  String runningCoachCalibrationReadinessCheckPercentValue(
      int current, int target) {
    return '$current% / 목표 $target%';
  }

  @override
  String runningCoachCalibrationReadinessCheckPercentMaxValue(
      int current, int target) {
    return '$current% / 최대 $target%';
  }

  @override
  String get runningCoachFieldMatrixTitle => '현장 커버리지 매트릭스';

  @override
  String get runningCoachFieldMatrixStatusNotReady => '준비 안 됨';

  @override
  String get runningCoachFieldMatrixStatusBuilding => '커버리지 구축 중';

  @override
  String get runningCoachFieldMatrixStatusRecommendationReady => '추천 커버리지 준비됨';

  @override
  String get runningCoachFieldMatrixStatusComplete => '매트릭스 커버리지 완료';

  @override
  String get runningCoachFieldMatrixBodyNotReady =>
      '저장된 현장 준비 세션이 아직 필수 후면 폰 기준 조건을 채우지 못했어요.';

  @override
  String get runningCoachFieldMatrixBodyBuilding =>
      '더 강한 추천에 쓰기 전에 빠진 설정 밴드에서 현장 준비 세션을 더 저장해 주세요.';

  @override
  String get runningCoachFieldMatrixBodyRecommendationReady =>
      '기준 조건과 의미 있는 구도 변화가 확보됐어요. 남은 매트릭스 공백은 계속 표시됩니다.';

  @override
  String get runningCoachFieldMatrixBodyComplete =>
      '필수 설정 밴드가 모두 현장 준비 세션으로 확보됐어요.';

  @override
  String get runningCoachFieldMatrixPrivacyNote =>
      '저장된 설정 요약만 사용합니다. 알 수 없는 과거 컨텍스트는 포함하지 않으며 카메라 프레임, 모델명, 업로드, 영상은 저장하지 않습니다.';

  @override
  String runningCoachFieldMatrixCoverageValue(int covered, int required) {
    return '$covered/$required 시나리오';
  }

  @override
  String runningCoachFieldMatrixScoreValue(int score) {
    return '커버리지 $score%';
  }

  @override
  String runningCoachFieldMatrixEligibleSessionsValue(int count) {
    return '현장 준비 $count개';
  }

  @override
  String runningCoachFieldMatrixUnknownContextValue(int count) {
    return '알 수 없음 $count개';
  }

  @override
  String get runningCoachFieldMatrixMissingTitle => '빠진 시나리오';

  @override
  String get runningCoachFieldMatrixMissingNone => '필수 설정 밴드가 모두 확보됐어요.';

  @override
  String get runningCoachFieldMatrixScenarioRearPhoneNormalClear =>
      '후면 폰 · 보통 거리 · 선명한 측면';

  @override
  String get runningCoachFieldMatrixScenarioRearPhoneCloseClear =>
      '후면 폰 · 가까운 거리 · 선명한 측면';

  @override
  String get runningCoachFieldMatrixScenarioRearPhoneFarClear =>
      '후면 폰 · 먼 거리 · 선명한 측면';

  @override
  String get runningCoachFieldMatrixScenarioRearPhoneNormalPartial =>
      '후면 폰 · 보통 거리 · 부분 측면';

  @override
  String get runningCoachCalibrationCandidateTitle => '보정 추천';

  @override
  String get runningCoachCalibrationCandidateStatusNotReady => '준비 안 됨';

  @override
  String get runningCoachCalibrationCandidateStatusKeepCurrent => '현재 프로필 유지';

  @override
  String get runningCoachCalibrationCandidateStatusRecommendation =>
      '안전 추천만 표시';

  @override
  String get runningCoachCalibrationCandidateBodyNotReady =>
      '반복성 또는 현장 커버리지가 더 엄격한 캡처 프로필을 추천할 만큼 준비되지 않았어요.';

  @override
  String get runningCoachCalibrationCandidateBodyKeepCurrent =>
      '저장된 요약 기준으로는 현재 프로필이 더 안전한 선택이에요.';

  @override
  String get runningCoachCalibrationCandidateBodyRecommendation =>
      '더 엄격한 프로필이 저장 세션 확인을 통과했어요. 추천으로만 다뤄 주세요.';

  @override
  String get runningCoachCalibrationCandidatePrivacyNote =>
      '프로필, 임계값, 사용자 설정, 업로드, 원본 영상, 카메라 프레임은 자동으로 바꾸지 않습니다.';

  @override
  String runningCoachCalibrationCandidateScoreValue(int score) {
    return '추천 $score%';
  }

  @override
  String runningCoachCalibrationCandidateEligibleValue(int count) {
    return '대상 세션 $count개';
  }

  @override
  String runningCoachCalibrationCandidateCoverageValue(
      int passed, int eligible) {
    return '$passed/$eligible 후보 통과';
  }

  @override
  String runningCoachCalibrationCandidateMarginValue(int percent) {
    return '근거 여유 $percent%';
  }

  @override
  String runningCoachCalibrationCandidateComparisonValue(
      Object current, Object candidate) {
    return '$current → $candidate 추천';
  }

  @override
  String runningCoachCalibrationCandidateComparisonKeep(Object profile) {
    return '현재: $profile';
  }

  @override
  String get runningCoachCalibrationCandidateBlockersTitle => '막힌 항목';

  @override
  String get runningCoachCalibrationCandidateNoBlockers =>
      '저장된 요약에서 막힌 항목이 없어요.';

  @override
  String get runningCoachCalibrationCandidateBlockerRepeatability =>
      '반복성 준비 안 됨';

  @override
  String get runningCoachCalibrationCandidateBlockerFieldMatrix =>
      '현장 매트릭스 미완료';

  @override
  String get runningCoachCalibrationCandidateBlockerNoStricter =>
      '이미 가장 엄격한 프로필';

  @override
  String get runningCoachCalibrationCandidateBlockerEvidence => '후보 근거 실패';

  @override
  String get runningCoachCalibrationCandidateBlockerMargin => '근거 여유 부족';

  @override
  String get runningCoachCalibrationCandidateBlockerCoverage => '커버리지 후퇴';

  @override
  String get runningCoachCalibrationCandidateBlockerHoldout => '최신 홀드아웃 실패';

  @override
  String get runningCoachSelectedVideoLabel => '선택한 영상';

  @override
  String get runningCoachNoVideoSelected => '아직 선택한 영상이 없어요.';

  @override
  String get runningCoachPickVideoAction => '영상 선택';

  @override
  String get runningCoachChangeVideoAction => '바꾸기';

  @override
  String get runningCoachAnalyzeAction => '달리기 분석';

  @override
  String get runningCoachAnalysisInProgress => '분석 중...';

  @override
  String get runningCoachPickVideoFailed => '영상 선택기를 열지 못했어요.';

  @override
  String get runningCoachUnsupportedPlatform => '이 기기에서는 달리기 영상 분석을 지원하지 않아요.';

  @override
  String get runningCoachNativeAnalyzerUnavailable =>
      '이 앱 빌드에는 달리기 영상 분석기가 포함되지 않았어요. 최신 모바일 앱으로 다시 설치한 뒤 시도해 주세요.';

  @override
  String get runningCoachWebAnalyzerUnavailable =>
      '브라우저 영상 분석기를 시작하지 못했어요. 페이지를 새로고침한 뒤 다시 시도해 주세요.';

  @override
  String get runningCoachWebVideoDecodeFailed =>
      '이 브라우저에서 선택한 영상을 읽지 못했어요. MP4 또는 MOV 파일로 다시 시도해 주세요.';

  @override
  String get runningCoachVideoFileMissing => '선택한 영상 파일을 찾지 못했어요.';

  @override
  String get runningCoachVideoTooShort => '영상이 너무 짧아요. 몇 걸음 이상 달리는 장면을 찍어 주세요.';

  @override
  String get runningCoachVideoTooLong =>
      '안전한 기기 내 디코딩 범위를 넘는 영상이에요. 러너가 보이는 구간으로 잘라 주세요.';

  @override
  String get runningCoachVideoTooLarge =>
      '안전한 메모리 분석 한도를 넘는 파일이에요. 러너가 보이도록 유지하면서 더 작은 파일로 내보내 주세요.';

  @override
  String get runningCoachWebVideoTooLarge =>
      '브라우저 분석 한도인 96MB를 넘는 파일이에요. 더 작은 영상으로 내보낸 뒤 다시 시도해 주세요.';

  @override
  String get runningCoachVideoTooBlurry =>
      '영상이 흔들리거나 흐려서 정확히 분석할 수 없어요. 휴대폰을 고정하고 전신과 양발이 보이는 선명한 측면 영상으로 다시 찍어 주세요.';

  @override
  String get runningCoachNoPoseDetected =>
      '옷차림은 판단 기준이 아니지만, 관절을 충분히 추적하지 못했어요. 팔꿈치, 무릎, 발이 잘 보이는 선명한 측면 영상을 다시 찍어 주세요.';

  @override
  String get runningCoachInsufficientContactEvidence =>
      '검증된 발 접지 프레임이 부족해요. 착지 순간까지 양발이 보이는 더 선명한 측면 영상으로 다시 시도해 주세요.';

  @override
  String get runningCoachAnalysisFailedGeneric =>
      '달리기 분석에 실패했어요. 측면이 더 잘 보이는 영상으로 다시 시도해 주세요.';

  @override
  String get runningCoachAnalysisTimedOut =>
      '분석 시간이 너무 오래 걸렸어요. 더 짧고 선명한 측면 영상으로 다시 시도해 주세요.';

  @override
  String get runningCoachLowerBodyEvidenceLimited =>
      '착지와 무릎 평가는 참고용이에요. 접지 근거가 부족해 이번 점수와 다음 목표에는 반영하지 않았어요.';

  @override
  String get runningCoachResultsTitle => '코칭 결과';

  @override
  String get runningCoachAnalysisQualityTitle => '분석 품질';

  @override
  String get runningCoachAnalysisQualityStrong => '측정 근거가 충분해요';

  @override
  String runningCoachAnalysisQualityStrongBody(int count) {
    return '신뢰할 수 있는 $count개 지표와 착지 근거로 이번 목표를 정했어요.';
  }

  @override
  String get runningCoachAnalysisQualityStrongSummary =>
      '이번 목표를 정할 만큼 근거가 충분해요.';

  @override
  String get runningCoachAnalysisQualityLimited => '일부 지표만 참고하세요';

  @override
  String runningCoachAnalysisQualityLimitedBody(int count) {
    return '신뢰할 수 있는 지표는 $count개예요. 발과 무릎 평가는 근거가 충분할 때만 반영해요.';
  }

  @override
  String get runningCoachAnalysisQualityLimitedSummary =>
      '일부 자세 항목은 참고로만 봐 주세요.';

  @override
  String get runningCoachAnalysisQualityRetake => '재촬영을 권장해요';

  @override
  String get runningCoachAnalysisQualityRetakeBody =>
      '관절 또는 착지 근거가 부족해 이번 영상으로는 신뢰할 만한 목표를 정하기 어려워요.';

  @override
  String get runningCoachAnalysisQualityDetailsTitle => '측정값 자세히 보기';

  @override
  String get runningCoachAnalysisQualityPosePairingLimited =>
      '접지 시점은 확인했지만 전신 좌표 짝이 부족해 발·무릎·상체·팔의 걸음별 범위는 별도 확인이 필요해요.';

  @override
  String get runningCoachVerifiedContactsLabel => '검증된 착지';

  @override
  String get runningCoachResultOneChangeTitle => '먼저 한 가지만 바꿔 보세요';

  @override
  String get runningCoachNextGoalTitle => '다음 목표';

  @override
  String get runningCoachNextGoalRepeat => '다음 3번은 이것만 의식해 보세요.';

  @override
  String get runningCoachResultNextRunCueLabel => '다음 달리기에서 할 동작';

  @override
  String get runningCoachResultOneChangeBody =>
      '몇 걸음 동안 이 한 가지에만 집중한 뒤 다시 촬영해 변화를 확인해 보세요.';

  @override
  String get runningCoachResultKeepOneThingBody =>
      '다음 몇 걸음에서도 이 장점을 유지한 뒤 다시 촬영해 계속 잘 되는지 확인해 보세요.';

  @override
  String get runningCoachResultDetailsTitle => '세부 분석';

  @override
  String get runningCoachReportDetailsBody =>
      '다섯 항목을 한눈에 확인하세요. 프레임을 자세히 보고 싶을 때만 내 영상 근거를 여세요.';

  @override
  String get runningCoachAnalysisHistoryTitle => '코칭 분석 기록';

  @override
  String get runningCoachAnalysisHistoryBody =>
      '업로드 영상과 실시간 스프린트 세션의 핵심 코칭 포인트와 교정 가이드를 다시 볼 수 있어요.';

  @override
  String runningCoachAnalysisHistoryAction(int count) {
    return '전체 $count개';
  }

  @override
  String get runningCoachAnalysisHistoryEmpty => '아직 저장된 코칭 분석 기록이 없어요.';

  @override
  String get runningCoachHistoryClearAllAction => '전체 삭제';

  @override
  String get runningCoachHistoryClearAllTitle => '코칭 분석 기록을 모두 삭제할까요?';

  @override
  String get runningCoachHistoryClearAllBody =>
      '저장된 모든 분석, 이 기기에 저장된 근거 프레임, 저장하기로 선택한 영상이 함께 삭제돼요.';

  @override
  String get runningCoachHistoryDeleteTitle => '이 분석 기록을 삭제할까요?';

  @override
  String get runningCoachHistoryDeleteBody =>
      '분석 기록, 이 기기에 저장된 근거 프레임, 저장된 영상이 있다면 그 영상도 삭제돼요.';

  @override
  String get runningCoachSaveVideoTitle => '분석과 함께 이 영상 저장';

  @override
  String get runningCoachSaveVideoBody =>
      '기본값은 꺼짐이에요. 분석 기록을 삭제할 때까지 이 기기에 영상을 남기고 싶을 때만 켜세요.';

  @override
  String get runningCoachVideoSaveFailedTitle => '영상이 저장되지 않았어요';

  @override
  String get runningCoachVideoSaveFailedBody =>
      '분석 기록은 저장됐지만, 이 기기에 영상 사본을 남기지 못했어요. 지금 결과는 계속 확인할 수 있어요.';

  @override
  String get runningCoachAnalysisHistorySaveFailedTitle =>
      '분석은 완료됐지만 기록에 저장하지 못했어요';

  @override
  String get runningCoachAnalysisHistorySaveFailedBody =>
      '이번 결과는 지금 확인할 수 있지만, 이 화면을 닫으면 분석 기록에 남지 않을 수 있어요. 오래된 분석 기록을 지운 뒤 다시 시도해 주세요.';

  @override
  String get runningCoachAnalysisHistoryDetailTitle => '분석 리포트';

  @override
  String get runningCoachAnalysisHistoryPrimaryFocus => '핵심 코칭 포인트';

  @override
  String runningCoachHistoryMetricCount(int count) {
    return '지표 $count개';
  }

  @override
  String get runningCoachHistoryFullReportTitle => '전체 자세 리포트';

  @override
  String runningCoachHistoryFullReportBody(int count) {
    return '저장된 $count개 측정 지표를 모두 보여줘요. 각 항목을 열면 분석 직후와 같은 설명, 다음 동작, 추천 드릴을 확인할 수 있어요.';
  }

  @override
  String get runningCoachAnalysisResultScreenTitle => '달리기 분석 결과';

  @override
  String get runningCoachHistoryVideoSaved => '영상 저장됨';

  @override
  String get runningCoachArchivedVideoTitle => '분석 영상';

  @override
  String get runningCoachArchivedVideoBody =>
      '이 영상은 분석 히스토리와 함께 저장되어 같은 자세를 다시 확인할 수 있어요.';

  @override
  String get runningCoachArchivedVideoPlay => '재생';

  @override
  String get runningCoachArchivedVideoPause => '일시정지';

  @override
  String get runningCoachArchivedVideoUnavailable =>
      '저장된 영상을 열 수 없어요. 영상 파일이 기기에서 삭제되었을 수 있어요.';

  @override
  String get runningCoachEvidenceFramesTitle => '저장된 근거 프레임';

  @override
  String get runningCoachEvidenceFramesBody =>
      '이 정지 화면과 자세 표시는 이 기기에만 저장돼요. 분석 기록을 삭제하면 함께 삭제됩니다. 전체 영상은 영상 저장을 켰을 때만 저장돼요.';

  @override
  String runningCoachEvidenceArchiveSavedTitle(int count) {
    return '근거 이미지 $count장 저장됨';
  }

  @override
  String get runningCoachEvidenceArchiveSavedBody =>
      '이 정지 이미지는 선택 저장하는 원본 영상과 별개이며 이 기기에만 남아요.';

  @override
  String runningCoachEvidenceArchivePartialTitle(int saved, int requested) {
    return '근거 이미지 $saved/$requested장 저장됨';
  }

  @override
  String runningCoachEvidenceArchivePartialBody(Object reason) {
    return '일부 정지 이미지를 저장하지 못했어요: $reason';
  }

  @override
  String get runningCoachEvidenceArchiveFailedTitle => '근거 이미지를 저장하지 못했어요';

  @override
  String runningCoachEvidenceArchiveFailedBody(Object reason) {
    return '분석 기록은 저장됐지만 정지 근거 이미지는 보관하지 못했어요: $reason';
  }

  @override
  String get runningCoachEvidenceArchiveNotRequestedTitle => '요청된 근거 이미지가 없어요';

  @override
  String get runningCoachEvidenceArchiveNotRequestedBody =>
      '이 분석에서는 보관할 만큼 신뢰할 수 있는 정지 프레임이 나오지 않았어요. 측정된 자세 데이터는 결과에 남아 있어요.';

  @override
  String get runningCoachEvidenceArchiveReasonSourceUnavailable =>
      '분석 뒤 원본 영상을 사용할 수 없었어요.';

  @override
  String get runningCoachEvidenceArchiveReasonExtractionEmpty =>
      '선택된 근거 시점에서 JPEG 프레임을 추출하지 못했어요.';

  @override
  String get runningCoachEvidenceArchiveReasonStorageUnavailable =>
      '로컬 이미지 저장소를 사용할 수 없었어요.';

  @override
  String get runningCoachEvidenceArchiveReasonFileWrite =>
      '기기가 JPEG 파일을 쓰지 못했어요.';

  @override
  String get runningCoachEvidenceArchiveReasonWebLimit =>
      '브라우저 저장 용량 제한을 넘을 수 있어 저장하지 않았어요.';

  @override
  String get runningCoachEvidenceArchiveReasonPlatformUnavailable =>
      '이 앱 빌드에서 근거 프레임 추출기를 실행할 수 없었어요.';

  @override
  String get runningCoachEvidenceArchiveReasonTimeout =>
      '근거 이미지 저장 시간이 너무 오래 걸려 결과 화면을 먼저 열었어요.';

  @override
  String get runningCoachEvidenceArchiveReasonUnknown =>
      '기기에서 알 수 없는 이미지 저장 오류를 보고했어요.';

  @override
  String get runningCoachEvidenceImageReadFailed => '이미지를 열 수 없어요';

  @override
  String get runningCoachEvidenceImageReadFailedReason =>
      '저장된 파일이 이 기기에서 삭제되었을 수 있어요.';

  @override
  String get runningCoachAnalysisGuideTitle => '그림으로 보는 교정 포인트';

  @override
  String get runningCoachAnalysisGuideBody => '그림을 보고 먼저 바꿀 부분을 확인하세요.';

  @override
  String get runningCoachGoodFormGuideTitle => '좋은 달리기 자세 한눈에';

  @override
  String get runningCoachGoodFormGuideBody =>
      '완벽한 한 장의 자세가 아니라, 달리는 동안 반복할 다섯 가지 움직임이에요.';

  @override
  String get runningCoachGoodFormPrinciplePosture =>
      '허리를 접지 않고 어깨-엉덩이 선을 가볍게 앞으로 둬요.';

  @override
  String get runningCoachGoodFormPrincipleBounce =>
      '위아래로 튀기보다 앞으로 가는 리듬을 유지해요.';

  @override
  String get runningCoachGoodFormPrincipleFootStrike =>
      '발은 엉덩이 가까이에서 지면에 닿게 해요.';

  @override
  String get runningCoachGoodFormPrincipleKnee =>
      '무릎은 주저앉지 않으면서 착지 충격을 부드럽게 받아요.';

  @override
  String get runningCoachGoodFormPrincipleArms =>
      '힘을 뺀 팔꿈치가 리듬에 맞춰 앞뒤로 움직이게 해요.';

  @override
  String get runningCoachGoodFormAction => '좋은 자세';

  @override
  String get runningCoachGoodFormScreenTitle => '좋은 러닝 자세';

  @override
  String get runningCoachGoodFormIntroTitle => '초보자부터 경력자까지';

  @override
  String get runningCoachGoodFormIntroBody =>
      '처음에는 ‘먼저 이것만’을 따라 하고, 익숙해지면 ‘더 정확히 보기’로 좌우·타이밍·연속 동작을 확인하세요.';

  @override
  String get runningCoachGoodFormCycleTitle => '연속 동작 루프';

  @override
  String get runningCoachGoodFormCycleBody =>
      '한 명의 기준 러너가 착지, 지지, 밀어내기, 회복, 다음 착지까지 같은 스케일과 지면선으로 이어집니다.';

  @override
  String get runningCoachGoodFormPhaseLandingTitle => '착지';

  @override
  String get runningCoachGoodFormPhaseLandingCue =>
      '발을 앞으로 뻗기보다 엉덩이 가까이에 가볍게 내려놓아요.';

  @override
  String get runningCoachGoodFormPhaseLandingFocus => '착지 발과 공통 지면선';

  @override
  String get runningCoachGoodFormPhaseSupportTitle => '지지';

  @override
  String get runningCoachGoodFormPhaseSupportCue =>
      '무릎과 발목이 충격을 받으며 몸이 발 위를 부드럽게 지나가요.';

  @override
  String get runningCoachGoodFormPhaseSupportFocus => '지지하는 무릎과 하중을 받는 다리';

  @override
  String get runningCoachGoodFormPhasePushOffTitle => '밀어내기';

  @override
  String get runningCoachGoodFormPhasePushOffCue =>
      '땅을 아래로 누른 뒤 발이 뒤로 빠지며 몸이 앞으로 이동해요.';

  @override
  String get runningCoachGoodFormPhasePushOffFocus => '밀어내는 발끝과 발, 지면선';

  @override
  String get runningCoachGoodFormPhaseRecoveryTitle => '회수';

  @override
  String get runningCoachGoodFormPhaseRecoveryCue =>
      '뒤꿈치를 자연스럽게 회수하고 무릎이 다음 착지를 준비해요.';

  @override
  String get runningCoachGoodFormPhaseRecoveryFocus => '회수되는 무릎과 뒤꿈치';

  @override
  String runningCoachGoodFormCycleObservationLabel(String phase) {
    return '관찰: $phase';
  }

  @override
  String runningCoachGoodFormCycleFocusLegend(String focus) {
    return '파란 표시: $focus';
  }

  @override
  String get runningCoachGoodFormSlowMotionAction => '천천히 보기';

  @override
  String get runningCoachGoodFormStepAction => '다음 단계';

  @override
  String get runningCoachGoodFormRestartStepsAction => '4단계 다시 시작';

  @override
  String get runningCoachGoodFormPlayAction => '재생';

  @override
  String get runningCoachGoodFormPauseAction => '일시정지';

  @override
  String get runningCoachGoodFormStepFrameAction => '다음 프레임';

  @override
  String get runningCoachGoodFormSpeedNormal => '보통';

  @override
  String get runningCoachGoodFormSpeedSlow => '느리게';

  @override
  String get runningCoachGoodFormTechniqueTitle => '항목별 일러스트 가이드';

  @override
  String get runningCoachGoodFormTechniqueBody =>
      '빨강은 흔한 실수, 파랑은 권장 움직임입니다. 몸 모양보다 표시된 관계와 방향을 확인하세요.';

  @override
  String get runningCoachGoodFormCommonLabel => '흔한 실수';

  @override
  String get runningCoachGoodFormRecommendedLabel => '권장 움직임';

  @override
  String get runningCoachGoodFormBeginnerLabel => '먼저 이것만';

  @override
  String get runningCoachGoodFormExperiencedLabel => '더 정확히 보기';

  @override
  String get runningCoachGoodFormExperiencedPosture =>
      '속도가 바뀌어도 허리만 접히지 않고 어깨-엉덩이 선이 살짝 앞으로 유지되는지 여러 프레임에서 확인해요.';

  @override
  String get runningCoachGoodFormExperiencedBounce =>
      '한 스텝의 최고점만 보지 말고 여러 보폭에서 골반 높이 변화와 접지 리듬이 일정한지 확인해요.';

  @override
  String get runningCoachGoodFormExperiencedFootStrike =>
      '착지 순간 발과 엉덩이의 앞뒤 거리, 정강이 방향, 좌우 발의 반복 차이를 함께 확인해요.';

  @override
  String get runningCoachGoodFormExperiencedKnee =>
      '착지 직후 무릎이 잠기거나 급격히 주저앉지 않고, 지지 구간에서 부드럽게 굽혀졌다 펴지는지 확인해요.';

  @override
  String get runningCoachGoodFormExperiencedArms =>
      '어깨 힘, 팔꿈치 굽힘, 손이 몸 중앙을 가로지르는지와 좌우 스윙 차이를 함께 확인해요.';

  @override
  String runningCoachGoodFormIllustrationSemantics(String metric) {
    return '$metric의 흔한 실수와 권장 움직임을 비교하는 일러스트';
  }

  @override
  String get runningCoachGoodFormGuideFootnoteTitle => '이 가이드의 역할';

  @override
  String get runningCoachGoodFormGuideFootnoteBody =>
      '정답 자세 하나를 강요하는 화면이 아닙니다. 체형·속도·환경에 따라 모습은 달라질 수 있으며, 분석 결과에서는 내 영상 근거를 우선하세요.';

  @override
  String get runningCoachAnalysisGuideRangeLabel => '좋은 범위';

  @override
  String get runningCoachAnalysisGuideFindingLabel => '판정 근거';

  @override
  String get runningCoachAnalysisGuideCueLabel => '실행 cue';

  @override
  String get runningCoachAnalysisGuideDrillLabel => '추천 드릴';

  @override
  String get runningCoachTargetGuideTitle => '목표 움직임 예시';

  @override
  String get runningCoachTargetGuideBody =>
      '목표 자세 예시입니다. 내 몸 모양이 아니라 파란 표시의 움직임만 따라 해 보세요.';

  @override
  String get runningCoachMeasuredPoseTitle => '내 자세에서 이렇게 옮기기';

  @override
  String get runningCoachMeasuredPoseBody =>
      '빨간 표시는 현재 위치, 파란 표시는 다음에 맞출 곳이에요. 화살표 하나만 따라 움직여 보세요.';

  @override
  String get runningCoachIllustrationTitle => '다음 동작 참고';

  @override
  String get runningCoachIllustrationBody =>
      '빨강은 현재 이슈, 파랑은 다음에 따라 해 볼 한 가지 움직임이에요.';

  @override
  String get runningCoachIllustrationGoodBody =>
      '위 영상의 수치는 이 항목의 코칭 기준 안에 있어요. 전체 자세가 모두 좋다는 뜻은 아니에요.';

  @override
  String get runningCoachIllustrationFootnote =>
      '그림은 내 체형을 재구성한 것이 아니라, 측정 결과에 맞춘 일반 러너 예시입니다.';

  @override
  String get runningCoachMeasuredPoseActualLabel => '현재 위치';

  @override
  String get runningCoachMeasuredPoseTargetLabel => '다음 목표';

  @override
  String get runningCoachMeasuredPoseTargetRangeLabel => '코칭 기준';

  @override
  String get runningCoachMeasuredPoseCueLabel => '이렇게 움직여 보세요';

  @override
  String get runningCoachMeasuredPoseFootnote =>
      '파란 표시는 내 몸을 바꿔 만든 자세가 아니라, 다음 동작에서 관절을 옮길 위치 또는 범위예요.';

  @override
  String get runningCoachMeasuredPoseImproveLegend => '빨강: 현재 측정값 · 파랑: 다음 목표';

  @override
  String get runningCoachMeasuredPoseGoodLegend =>
      '초록: 이번 영상의 수치가 이 항목의 코칭 기준 안에 있어요';

  @override
  String get runningCoachMeasuredPoseGoodBody =>
      '현재 수치는 이 항목의 코칭 기준 안에 있어요. 전체 자세가 모두 좋다는 뜻은 아니에요.';

  @override
  String get runningCoachMeasuredPoseGoodCue => '이 움직임은 유지하되, 다른 항목도 함께 확인하세요.';

  @override
  String runningCoachMeasuredPoseRangeDegrees(String minimum, String maximum) {
    return '$minimum–$maximum°';
  }

  @override
  String runningCoachMeasuredPoseRangePercentMaximum(String maximum) {
    return '≤ $maximum%';
  }

  @override
  String runningCoachMeasuredPoseRangeRatioMaximum(String maximum) {
    return '≤ $maximum×';
  }

  @override
  String get runningCoachGuideRangePosture => '목표: 허리를 접지 않고 몸통을 살짝 앞으로 기울이기';

  @override
  String get runningCoachGuideRangeBounce => '목표: 위아래 움직임은 작게, 발은 빠르게';

  @override
  String get runningCoachGuideRangeFootStrike => '목표: 발이 엉덩이 아래 가까이에 닿기';

  @override
  String get runningCoachGuideRangeKnee => '목표: 착지 무릎은 잠그지 말고 부드럽게';

  @override
  String get runningCoachGuideRangeArm => '목표: 팔꿈치는 굽히고 손은 앞뒤로 움직이기';

  @override
  String get runningCoachMetricScoreLabel => '항목 점수';

  @override
  String runningCoachConfidenceLabel(int percent) {
    return '신뢰도 $percent%';
  }

  @override
  String get runningCoachSessionSourceUploadVideo => '영상 분석';

  @override
  String get runningCoachQualityReasonLowCoverage =>
      '영상에서 러너가 충분히 선명하지 않았어요. 더 선명한 영상으로 다시 확인하세요.';

  @override
  String get runningCoachQualityReasonLimitedSamples =>
      '뚜렷하게 읽은 장면이 적었어요. 같은 측면에서 한 번 더 촬영하세요.';

  @override
  String get runningCoachQualityReasonContactPhaseProxy =>
      '발이 닿는 순간을 확인하기 어려웠어요. 착지와 무릎을 다시 확인하세요.';

  @override
  String get runningCoachQualityReasonKinematicContactEstimate =>
      '바닥선 대신 발 궤적과 보이는 관절 사슬로 접지 구간을 확인했어요. 반복된 3보 이상에서만 코칭에 사용했어요.';

  @override
  String get runningCoachQualityReasonLowConfidence =>
      '카메라가 관절을 선명하게 보지 못했어요. 카메라를 흔들지 마세요.';

  @override
  String get runningCoachQualityReasonGeneric =>
      '영상이 충분히 선명하지 않았어요. 같은 측면에서 다시 촬영하세요.';

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
    return '몸통 기울기 $value°';
  }

  @override
  String runningCoachBounceValue(Object value) {
    return '상하 움직임 $value%';
  }

  @override
  String runningCoachFootStrikeValue(Object value) {
    return '발 뻗음 $value배';
  }

  @override
  String runningCoachKneeValue(Object value) {
    return '착지 무릎 $value°';
  }

  @override
  String runningCoachArmValue(Object value) {
    return '팔 굽힘 $value°';
  }

  @override
  String runningCoachStrideValue(Object value) {
    return '보폭 도달 $value배';
  }

  @override
  String get runningCoachInsightPostureTitle => '상체 자세';

  @override
  String get runningCoachPostureGoodSummary => '몸통 선이 살짝 앞으로 기울고 자세가 곧게 유지돼요.';

  @override
  String get runningCoachPostureGoodCue => '가슴은 세우고 어깨-엉덩이 선을 살짝 앞으로 두세요.';

  @override
  String get runningCoachPostureGoodDrill => '드릴: 벽 마치 15m를 2번 하세요.';

  @override
  String get runningCoachInRangeWatchSummary =>
      '넓은 가이드 범위 안이지만, ‘좋음’이라고 할 만큼 목표 중심에 가깝지는 않아요.';

  @override
  String get runningCoachInRangeWatchCue =>
      '큰 자세 변화는 바로 시도하지 말고, 편한 리듬으로 2~3개의 비슷한 영상을 먼저 비교해 보세요.';

  @override
  String get runningCoachInRangeWatchDrill => '드릴: 편하게 20m를 2번 달린 뒤 다시 측정하세요.';

  @override
  String get runningCoachPostureUprightSummary =>
      '몸통 선이 너무 서 있어요. 다음 걸음이 느려질 수 있어요.';

  @override
  String get runningCoachPostureUprightCue => '가슴은 세우고 어깨-엉덩이 선을 살짝 앞으로 가져가세요.';

  @override
  String get runningCoachPostureUprightDrill => '드릴: 폴링 스타트 15m를 2번 하세요.';

  @override
  String get runningCoachPostureLeanSummary =>
      '몸통 선이 너무 앞으로 기울었어요. 걸음이 급해질 수 있어요.';

  @override
  String get runningCoachPostureLeanCue => '조금 더 크게 서세요. 엉덩이가 가슴 아래에 오게 하세요.';

  @override
  String get runningCoachPostureLeanDrill => '드릴: 가볍고 빠른 톨 런 20m를 2번 하세요.';

  @override
  String get runningCoachInsightBounceTitle => '바운스';

  @override
  String get runningCoachBounceGoodSummary => '낮게 앞으로 잘 움직이고 있어요.';

  @override
  String get runningCoachBounceGoodCue => '땅을 뒤로 밀어 주세요. 위로 뛰지 마세요.';

  @override
  String get runningCoachBounceGoodDrill => '드릴: 발목 탄성을 살린 20m 달리기를 2번 하세요.';

  @override
  String get runningCoachBounceHighSummary => '위아래 움직임이 너무 커요.';

  @override
  String get runningCoachBounceHighCue => '발은 빠르게. 땅을 아래가 아니라 뒤로 밀어 주세요.';

  @override
  String get runningCoachBounceHighDrill => '드릴: 짧게 딛는 20m 달리기를 3번 하세요.';

  @override
  String get runningCoachInsightFootStrikeTitle => '발 착지';

  @override
  String get runningCoachFootStrikeGoodSummary => '발이 엉덩이 아래 가까이에 닿고 있어요.';

  @override
  String get runningCoachFootStrikeGoodCue => '발을 몸 아래에 내려놓는 느낌을 유지하세요.';

  @override
  String get runningCoachFootStrikeGoodDrill => '드릴: 퀵 스텝 런 20m를 2번 하세요.';

  @override
  String get runningCoachFootStrikeOverSummary => '발이 너무 앞에 닿고 있어요.';

  @override
  String get runningCoachFootStrikeOverCue => '발을 엉덩이 아래에 더 가깝게 내려놓으세요.';

  @override
  String get runningCoachFootStrikeOverDrill =>
      '드릴: A-마치 20m를 2번 한 뒤 퀵 스텝 런 20m를 2번 하세요.';

  @override
  String get runningCoachInsightKneeTitle => '무릎 굴곡';

  @override
  String get runningCoachKneeGoodSummary => '착지 무릎이 가볍게 버틸 만큼 잘 굽혀져요.';

  @override
  String get runningCoachKneeGoodCue => '발이 닿을 때 무릎을 부드럽게 유지하세요.';

  @override
  String get runningCoachKneeGoodDrill =>
      '드릴: 포고 런 20m를 2번, 짧게 딛는 20m 달리기를 2번 하세요.';

  @override
  String get runningCoachKneeStraightSummary =>
      '착지 무릎이 너무 곧아요. 발걸음이 무거워질 수 있어요.';

  @override
  String get runningCoachKneeStraightCue => '발이 닿을 때 무릎을 조금 굽히세요.';

  @override
  String get runningCoachKneeStraightDrill =>
      '드릴: 부드러운 무릎으로 짧게 딛는 20m 달리기를 2번 하세요.';

  @override
  String get runningCoachKneeCollapseSummary => '착지 뒤에 무릎이 너무 많이 접혀요.';

  @override
  String get runningCoachKneeCollapseCue => '무릎은 부드럽게, 하지만 너무 주저앉지 않게 유지하세요.';

  @override
  String get runningCoachKneeCollapseDrill => '드릴: 한 발 포고 홉 15m를 양쪽 각각 2번 하세요.';

  @override
  String get runningCoachInsightArmTitle => '팔 각도';

  @override
  String get runningCoachArmGoodSummary => '팔이 잘 굽혀져 리듬을 도와줘요.';

  @override
  String get runningCoachArmGoodCue => '손을 앞뒤로 움직이세요.';

  @override
  String get runningCoachArmGoodDrill => '드릴: 벽 팔 스위치를 20초씩 2번 하세요.';

  @override
  String get runningCoachArmOpenSummary => '팔이 너무 많이 펴져요. 리듬이 느슨해질 수 있어요.';

  @override
  String get runningCoachArmOpenCue => '팔꿈치를 더 굽히고 손을 뒤로 밀어 주세요.';

  @override
  String get runningCoachArmOpenDrill => '드릴: 팔꿈치를 굽힌 채 벽 팔 스위치를 20초씩 2번 하세요.';

  @override
  String get runningCoachArmTightSummary => '팔이 너무 조여 있어요. 스윙이 짧아질 수 있어요.';

  @override
  String get runningCoachArmTightCue => '어깨 힘을 빼고 손이 뒤로 흔들리게 하세요.';

  @override
  String get runningCoachArmTightDrill => '드릴: 어깨 힘을 빼고 암 스윙 마치 20m를 2번 하세요.';

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
      '서버 없이 Google Drive 백업을 사용합니다. 선수 모드는 원본 스냅샷을 소유하고, 보호자 모드는 피드백과 선물 이름을 별도 기여 파일로 동기화합니다.';

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
      '보호자 모드에서는 선수 데이터 원본이 있는 Google Drive 계정으로 연결합니다. 보호자 변경사항은 별도 기여 파일로 동기화됩니다.';

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
  String get healthConnectSectionTitle => '삼성 헬스 자동 등록';

  @override
  String get healthConnectSectionSubtitle =>
      'Samsung Health가 Health Connect에 공유한 줄넘기 운동을 훈련 기록의 줄넘기 항목으로 가져옵니다.';

  @override
  String get healthConnectAutoSyncTitle => '줄넘기 자동 등록';

  @override
  String get healthConnectAutoSyncSubtitle =>
      '권한을 허용하면 앱 시작과 복귀 시 최근 줄넘기 운동을 확인해 중복 없이 등록합니다.';

  @override
  String get healthConnectStatusUnavailable =>
      '이 기기에서는 Health Connect를 사용할 수 없어요.';

  @override
  String get healthConnectStatusUpdateRequired => 'Health Connect 업데이트가 필요해요.';

  @override
  String get healthConnectStatusPermissionNeeded =>
      'Health Connect 운동 권한을 허용해야 해요.';

  @override
  String get healthConnectStatusReady => '권한이 허용됐어요. 필요할 때 동기화할 수 있습니다.';

  @override
  String get healthConnectStatusAutoOn => '자동 등록이 켜져 있어요.';

  @override
  String get healthConnectSyncNow => '지금 동기화';

  @override
  String get healthConnectGrantAndSync => '권한 허용 및 동기화';

  @override
  String healthConnectLastSync(Object time) {
    return '마지막 동기화: $time';
  }

  @override
  String healthConnectSyncImported(int count) {
    return '줄넘기 기록 $count개를 등록했어요.';
  }

  @override
  String get healthConnectImportNotificationChannelName => '삼성 헬스 자동 등록';

  @override
  String get healthConnectImportNotificationChannelDescription =>
      'Health Connect 줄넘기 기록 자동 등록 알림';

  @override
  String get healthConnectImportNotificationTitle => '줄넘기 기록 등록 완료';

  @override
  String healthConnectImportNotificationBody(int count) {
    return '줄넘기 기록 $count개가 태오의노트에 등록됐어요.';
  }

  @override
  String get healthConnectSyncNoNewRecords => '새로 등록할 줄넘기 기록이 없어요.';

  @override
  String get healthConnectSyncFailed => 'Health Connect 동기화에 실패했어요.';

  @override
  String get healthConnectDisabled => '줄넘기 자동 등록을 껐어요.';

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
      '최신 백업을 가져오고 공유 변경은 별도 기여 파일에 저장합니다.';

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
  String get settingsDriveRevokeAccessAction => 'Google 접근 권한 철회';

  @override
  String get settingsDriveRevokeAccessTitle => 'Google 접근 권한 철회';

  @override
  String get settingsDriveRevokeAccessBody =>
      '현재 Google 계정에서 이 앱의 Google Drive 권한을 제거합니다. 일반 로그아웃은 Google Drive 연결 해제를 사용하세요.';

  @override
  String get settingsDriveRevokeAccessDone => 'Google 접근 권한을 철회했어요.';

  @override
  String get settingsDriveRevokeAccessFailed =>
      'Google 접근 권한 철회에 실패했어요. 다시 연결한 뒤 시도해 주세요.';

  @override
  String get settingsRestoreLatestActionTitle => '최근 데이터 가져오기';

  @override
  String get settingsBackupDataActionTitle => '데이터 백업하기';

  @override
  String get settingsBackupContributionActionTitle => '기여 파일 백업';

  @override
  String get backupRestoreDetailsAction => '백업 상세 확인';

  @override
  String get backupRestoreDetailsTitle => '백업 및 가져오기 상세';

  @override
  String get backupDetailsConnectedAccount => '연결 계정';

  @override
  String get backupDetailsTarget => '대상';

  @override
  String get backupDetailsPlayerSourceTarget => '선수 원본 스냅샷';

  @override
  String get backupDetailsParentContributionTarget => '보호자 기여 파일';

  @override
  String get backupDetailsLocalData => '로컬 데이터';

  @override
  String backupDetailsLocalCounts(int trainingCount, int optionCount) {
    return '훈련 $trainingCount개, 앱 기록 $optionCount개';
  }

  @override
  String get backupDetailsRemoteCreated => '원격 백업';

  @override
  String get backupDetailsIntegrity => '무결성';

  @override
  String get backupDetailsIntegrityVerified => '해시 확인됨';

  @override
  String get backupDetailsIntegrityLegacy => '이전 형식 백업';

  @override
  String get backupDetailsDiff => '가져오기 미리보기';

  @override
  String backupDetailsDiffCounts(int addCount, int updateCount,
      int conflictCount, int deleteCount, int skipCount) {
    return '추가 $addCount개, 업데이트 $updateCount개, 충돌 $conflictCount개, 삭제 후보 $deleteCount개, 건너뜀 $skipCount개';
  }

  @override
  String get backupDetailsPreviewUnavailable => '지금은 백업 미리보기를 불러올 수 없어요.';

  @override
  String get backupPreviewChanged =>
      '미리보기 이후 원격 백업이 변경됐어요. 최신 상세 내용을 다시 확인한 뒤 가져오세요.';

  @override
  String get backupDetailsParentCoreZero =>
      '보호자/코치 업로드는 선수 핵심 기록을 0개만 씁니다. 피드백과 선물 이름만 포함됩니다.';

  @override
  String get restoreModeAddMissingOnly => '없는 항목만 추가';

  @override
  String get restoreModeSafeMerge => '안전 병합';

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
      '보호자 모드에서는 새 원본 백업을 만들지 않습니다. 선수 데이터를 가져오고 피드백/선물 이름은 별도 기여 파일에 저장합니다.';

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
      'Google Drive의 최신 백업을 안전 병합으로 가져오며, 이 기기에만 있는 기록은 유지합니다.';

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
      '보호자 모드에서 저장한 피드백과 레벨 선물 이름을 별도 기여 파일에 백업할까요?';

  @override
  String get settingsSupportBackupSuccess => '공유 변경사항을 기여 파일에 백업했어요.';

  @override
  String get settingsSupportBackupFailed =>
      '공유 변경사항 백업에 실패했어요. Drive 연결과 가족/선수 일치 여부를 확인해 주세요.';

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
  String get familyLinkConnectTitle => '가족 연결';

  @override
  String get familyLinkConnectedTitle => '가족 연결됨';

  @override
  String get familyLinkConnectedStatus => '가족 연결이 활성화되어 있어요.';

  @override
  String familyLinkConnectedAccount(Object parent) {
    return '$parent와 연결됨';
  }

  @override
  String get familyLinkConnectedAccountHidden => '연결된 가족 구성원';

  @override
  String familyLinkConnectedSubtitle(Object parent) {
    return '$parent와 연결되어 있어요. 선수 데이터는 자녀 소유로 유지되고, 보호자 쓰기는 별도 기여 파일만 사용합니다.';
  }

  @override
  String get familyLinkConnectedSubtitleHidden =>
      '선수 데이터는 자녀 소유로 유지되고, 보호자 쓰기는 별도 기여 파일만 사용합니다.';

  @override
  String get familyLinkParentConnectBody =>
      '보호자 Google 계정으로 로그인하고 QR을 보여 준 뒤 자녀 승인을 기다리세요.';

  @override
  String get familyLinkChildConnectBody =>
      '자녀 Google 계정으로 로그인하고 보호자 QR을 스캔한 뒤 연결을 승인하세요.';

  @override
  String get familyLinkParentStartAction => '연결 QR 표시';

  @override
  String get familyLinkChildScanAction => '연결 QR 스캔';

  @override
  String get familyLinkParentQrTitle => '가족 연결';

  @override
  String familyLinkParentQrExpires(Object time) {
    return '이 QR은 $time에 만료됩니다.';
  }

  @override
  String get familyLinkWaitingBody => '자녀 기기에서 승인하고 파일을 공유하기를 기다리는 중입니다.';

  @override
  String get familyLinkWaitingChecking => '공유 파일을 확인하는 중입니다.';

  @override
  String get familyLinkCheckNowAction => '지금 확인';

  @override
  String get familyLinkOpenSharedFileAction => '공유 파일 열기';

  @override
  String get familyLinkOpeningSharedFile => '선택한 파일을 여는 중입니다.';

  @override
  String get familyLinkChildScanTitle => '연결 QR 스캔';

  @override
  String get familyLinkChildScanBody => '카메라를 보호자 연결 QR에 맞추세요.';

  @override
  String get familyLinkChildConfirmTitle => '가족 연결 승인';

  @override
  String familyLinkChildConfirmBody(Object parent) {
    return '$parent와 가족 연결을 승인할까요? 보호자는 선수 백업을 읽고 피드백과 선물 이름만 쓸 수 있어요.';
  }

  @override
  String get familyLinkApproveAction => '연결 승인';

  @override
  String get familyLinkUnlinkAction => '가족 연결 해제';

  @override
  String get familyLinkUnlinkTitle => '가족 연결 해제';

  @override
  String get familyLinkUnlinkBody =>
      '자녀 쪽 연결 해제는 보호자의 Drive 권한을 제거합니다. 보호자 쪽 연결 해제는 이 기기의 로컬 가족 연결을 제거하고, 가능하면 다음 새로고침 때 자녀 기기에 접근 해제를 요청합니다.';

  @override
  String get familyLinkConnectedSnack => '가족 연결이 완료됐어요.';

  @override
  String get familyLinkApprovedSnack => '가족 연결을 승인했어요.';

  @override
  String get familyLinkUnlinkedSnack => '가족 연결을 제거했어요.';

  @override
  String get familyLinkCreateFailed => '연결 QR을 만들 수 없어요.';

  @override
  String get familyLinkCompleteFailed => '아직 연결을 완료할 수 없어요.';

  @override
  String get familyLinkCompletionFileFailed => '선택한 파일로 연결을 완료할 수 없어요.';

  @override
  String get familyLinkApproveFailed => '가족 연결 승인에 실패했어요.';

  @override
  String get familyLinkUnlinkFailed => '가족 연결 해제에 실패했어요.';

  @override
  String get familyLinkInvalidQr => '유효하지 않은 연결 QR입니다.';

  @override
  String get familyLinkExpiredMessage =>
      '이 연결 QR은 만료됐어요. 보호자 기기에서 새 QR을 시작하세요.';

  @override
  String get familyLinkWrongAccount => '계속하려면 예상된 Google 계정으로 다시 연결하세요.';

  @override
  String get familyLinkPermissionRevoked =>
      'Drive 권한이 철회됐거나 연결 파일을 사용할 수 없어요. 가족 연결을 다시 설정하세요.';

  @override
  String get familyLinkInviteUsed => '이 연결 QR은 이미 사용됐어요. 새 연결 QR을 시작하세요.';

  @override
  String get familyChildDriveConnectionSummary =>
      '원본 백업이 있는 Google Drive 계정으로 연결해요.';

  @override
  String get familyParentUsesChildDriveSummary =>
      '가족 연결 후에는 보호자의 Google Drive 계정을 사용하세요.';

  @override
  String get familyParentUsesChildDriveHint =>
      '보호자 모드에서는 보호자의 Google 계정으로 로그인하세요. 가족 연결은 선수 데이터 읽기와 별도 기여 파일 쓰기 권한만 제공합니다.';

  @override
  String get familyParentUsesChildDriveWarning =>
      '이 기기가 예상된 가족 연결과 맞지 않습니다. 보호자 Google 계정으로 다시 연결하거나 새로 연결하세요.';

  @override
  String get familySharedSyncTitle => '데이터 동기화 상태';

  @override
  String get familySharedSyncDescription =>
      '보호자 피드백과 레벨 선물 이름은 별도 기여 파일로 자동 반영됩니다.';

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
      'Google Drive의 최신 선수 데이터를 안전 병합으로 가져올까요? 이 기기에만 있는 기록은 유지됩니다.';

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
  String get restoreReconfirmBody =>
      '계속할까요? 안전 병합은 이 기기에만 있는 기록을 유지하고, 고급 되돌리기는 현재 데이터를 교체합니다.';

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
  String get parentReadOnlyCoreDataMessage =>
      '보호자 모드에서는 선수의 핵심 데이터를 수정할 수 없어요. 선수 모드에서 변경해 주세요.';

  @override
  String get parentReadOnlyCalendarSummary => '캘린더는 읽기 전용이에요.';

  @override
  String get parentReadOnlyCalendarBanner =>
      '보호자 모드에서는 캘린더를 읽기 전용으로 보여줍니다. 계획, 시합, 식사 수정은 선수 모드에서 진행해 주세요.';

  @override
  String get parentReadOnlyCalendarMessage => '보호자 모드에서는 캘린더를 수정할 수 없어요.';

  @override
  String get parentReadOnlyChallengeSummary => '보호자가 챌린지를 만들 수 있어요.';

  @override
  String get parentReadOnlyChallengeMessage =>
      '보호자 모드에서는 챌린지를 만들고 완주 선물을 정할 수 있어요. 미션 기록은 선수 모드에서 입력합니다.';

  @override
  String get parentReadOnlyDiaryMessage => '보호자 모드에서는 다이어리를 수정할 수 없어요.';

  @override
  String get parentReadOnlyDiaryBadge => '보호자 모드 읽기 전용';

  @override
  String get parentReadOnlySketchMessage => '보호자 모드에서는 훈련 스케치를 수정할 수 없어요.';

  @override
  String get parentReadOnlyFortuneEmpty => '저장된 무드 카드가 아직 없어요.';

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
  String get parentSharedSyncInProgress => '기여 파일로 동기화 중이에요...';

  @override
  String get parentSharedSyncDone => '기여 파일에 동기화했어요.';

  @override
  String get parentSharedSyncPending => 'Drive 연결 후 기여 파일로 자동 동기화됩니다.';

  @override
  String get levelGuideParentModeLabel => '보호자 모드';

  @override
  String get levelGuideChildModeLabel => '선수 모드';

  @override
  String get levelGuideParentModeDescription =>
      '보호자 모드에서는 레벨 선물 이름만 저장할 수 있고, 저장한 선물 이름은 보호자 기여 파일로 동기화됩니다. 선물 수령 표시는 선수 모드에서 진행합니다.';

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
  String get matchCompetitionQuickLoadTitle => '저장된 대회 불러오기';

  @override
  String get matchCompetitionQuickLoadHelper =>
      '리그/토너먼트 이름, 참가 팀, 상태와 장소를 시합 기록에 채웁니다.';

  @override
  String get matchCompetitionManagedOnlyTitle => '대회관리에서 만든 대회를 선택하세요.';

  @override
  String get matchCompetitionManagedOnlyBody =>
      '시합등록에서는 리그나 토너먼트를 새로 만들지 않습니다. 대회관리에서 먼저 만든 뒤 여기서 불러와 기록하세요.';

  @override
  String get matchCompetitionSelectionRequired => '대회관리에서 만든 대회를 먼저 선택하세요.';

  @override
  String get matchCompetitionSelectedTitle => '선택한 대회';

  @override
  String get matchCompetitionFinishedNotice =>
      '종료된 대회입니다. 이전 경기 기록을 정리할 때 선택하세요.';

  @override
  String get matchCompetitionManageButton => '팀 등록/결과 보기';

  @override
  String get matchCompetitionOpenButton => '대회 관리';

  @override
  String get matchCompetitionOpenHelper => '리그와 토너먼트 운영';

  @override
  String get matchCompetitionProTitle => '대회 운영 센터';

  @override
  String get matchCompetitionProSubtitle =>
      '감독, 코치, 선수가 참가 팀, 운영 정보, 순위와 대진을 함께 관리하세요.';

  @override
  String get matchCompetitionOperationsSummaryTitle => '운영 요약';

  @override
  String get matchCompetitionListTitle => '대회 현황';

  @override
  String matchCompetitionListCount(int count) {
    return '$count개 대회';
  }

  @override
  String get matchCompetitionNewButton => '새 대회';

  @override
  String matchCompetitionFilterAll(int count) {
    return '전체 $count';
  }

  @override
  String matchCompetitionFilterActive(int count) {
    return '진행 $count';
  }

  @override
  String matchCompetitionFilterFinished(int count) {
    return '종료 $count';
  }

  @override
  String get matchCompetitionFilterEmptyTitle => '해당 상태의 대회가 없어요.';

  @override
  String get matchCompetitionFilterEmptyBody => '필터를 초기화하면 전체 대회를 볼 수 있습니다.';

  @override
  String matchCompetitionCardSummary(int teams, int matches) {
    return '$teams팀 · $matches경기';
  }

  @override
  String get matchCompetitionDeleteDialogTitle => '대회 삭제';

  @override
  String matchCompetitionDeleteDialogBody(String name) {
    return '\"$name\" 대회를 삭제할까요? 등록된 시합 기록은 삭제되지 않습니다.';
  }

  @override
  String get matchCompetitionDeleteButton => '삭제';

  @override
  String get matchCompetitionDeletedFeedback => '대회를 삭제했어요.';

  @override
  String get matchCompetitionCreateLeagueButton => '리그 만들기';

  @override
  String get matchCompetitionCreateTournamentButton => '토너먼트 만들기';

  @override
  String get matchCompetitionSeasonLabel => '시즌';

  @override
  String get matchCompetitionSeasonHint => '예) 2026 여름';

  @override
  String get matchCompetitionVenueLabel => '장소';

  @override
  String get matchCompetitionVenueHint => '예) 메인 구장';

  @override
  String get matchCompetitionOrganizerLabel => '담당';

  @override
  String get matchCompetitionOrganizerHint => '예) 감독 김코치';

  @override
  String get matchCompetitionNoteLabel => '운영 메모';

  @override
  String get matchCompetitionNoteHint => '예) 조별 후 토너먼트, 로테이션 필수';

  @override
  String get matchCompetitionSaveCompetition => '대회 저장';

  @override
  String get matchCompetitionEditButton => '수정';

  @override
  String get matchCompetitionEditorBasicsTitle => '대회 기본';

  @override
  String get matchCompetitionEditorOperationsTitle => '운영 정보';

  @override
  String get matchCompetitionNoCompetitionsProBody =>
      '리그나 토너먼트를 먼저 만들면 참가 팀, 운영 정보, 순위와 대진을 전문적으로 관리할 수 있어요.';

  @override
  String get matchCompetitionOperationsDetailEmpty => '운영 정보 미입력';

  @override
  String get matchCompetitionNextActionLabel => '다음 운영';

  @override
  String get matchCompetitionNextRegisterTeams => '참가 팀 등록';

  @override
  String get matchCompetitionNextRecordFirstMatch => '첫 경기 기록';

  @override
  String get matchCompetitionNextRecordNextMatch => '다음 경기 기록';

  @override
  String get matchCompetitionNextCloseCompetition => '대회 종료 검토';

  @override
  String get matchCompetitionNextReviewArchive => '결과 아카이브';

  @override
  String matchCompetitionProgressPercent(int percent) {
    return '진행률 $percent%';
  }

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
  String get matchCompetitionEditParticipantsAction => '참가팀 편집';

  @override
  String get matchCompetitionLeagueSetupTitle => '리그 참가 팀';

  @override
  String get matchCompetitionLeagueSetupBody =>
      '팀을 등록하면 시합 기록을 기준으로 순위, 승무패, 득실과 승점이 자동 계산됩니다.';

  @override
  String get matchCompetitionTournamentSetupTitle => '토너먼트 시드';

  @override
  String get matchCompetitionTournamentSetupBody =>
      '팀을 드래그해 시드 순위를 정하세요. 상위 시드를 기준으로 대진과 부전승이 자동 배정됩니다.';

  @override
  String get matchCompetitionTournamentPreviewTitle => '시드 대진 미리보기';

  @override
  String matchCompetitionTournamentSeedPair(
      int slot, String teamA, String teamB) {
    return '$slot경기 · $teamA vs $teamB';
  }

  @override
  String get matchCompetitionOwnTeamBadge => '우리 팀';

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
  String get matchCompetitionSavedFeedback => '대회 정보를 저장했어요.';

  @override
  String get matchCompetitionNameRequired => '대회 이름을 입력하세요.';

  @override
  String get matchCompetitionMinimumTeamsRequired =>
      '대회를 저장하려면 참가 팀을 2팀 이상 등록하세요.';

  @override
  String get matchLeagueStandingsTitle => '리그 순위';

  @override
  String get matchTournamentBracketTitle => '토너먼트 대진표';

  @override
  String get matchTournamentImageAction => '이미지';

  @override
  String get matchTournamentImageTooltip => '대진표 이미지로 내보내기';

  @override
  String get matchTournamentImageExportedFeedback => '대진표 이미지를 준비했어요.';

  @override
  String get matchTournamentImageExportFailedFeedback => '대진표 이미지를 만들지 못했어요.';

  @override
  String get matchTournamentOpenFullScreen => '대진표 전체 화면으로 보기';

  @override
  String get matchTournamentZoomOut => '대진표 축소';

  @override
  String get matchTournamentZoomReset => '대진표 크기 초기화';

  @override
  String get matchTournamentZoomIn => '대진표 확대';

  @override
  String matchTournamentRoundOf(int number) {
    return '$number강';
  }

  @override
  String matchTournamentWinnerSource(int number) {
    return 'M$number 승자';
  }

  @override
  String get matchTournamentChampionSlot => '우승';

  @override
  String get matchCompetitionNoTeams => '등록된 팀이 없어요.';

  @override
  String get matchCompetitionNoMatches => '아직 기록된 경기가 없어요.';

  @override
  String get matchCompetitionFixtureRecordContext => '대회 일정에서 불러옴';

  @override
  String matchCompetitionFixtureRound(int round) {
    return '$round라운드';
  }

  @override
  String get matchCompetitionFixturesTitle => '경기 일정';

  @override
  String get matchCompetitionFixturesEmpty => '생성된 경기 일정이 없어요.';

  @override
  String get matchCompetitionFixtureVersus => 'vs';

  @override
  String get matchCompetitionFixtureTbd => '대기';

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
  String get matchCompetitionSummaryTeams => '참가 팀';

  @override
  String get matchCompetitionSummaryMatches => '기록 경기';

  @override
  String get matchCompetitionSummaryLeader => '선두';

  @override
  String get matchCompetitionSummaryRecorded => '기록';

  @override
  String get matchCompetitionSummaryProgress => '진행률';

  @override
  String get matchCompetitionNoLeader => '아직 없음';

  @override
  String get matchTournamentSummarySlots => '대진';

  @override
  String matchTournamentSlotProgress(int recorded, int total) {
    return '$recorded/$total';
  }

  @override
  String get matchTournamentPairPending => '경기 전';

  @override
  String get matchTournamentPairByeStatus => '부전승';

  @override
  String get matchTournamentVersusLabel => 'vs';

  @override
  String matchLeaguePlayedSummary(int played) {
    return '$played경기';
  }

  @override
  String matchLeagueRecordSummary(int wins, int draws, int losses) {
    return '$wins승 $draws무 $losses패';
  }

  @override
  String matchLeagueGoalDifferenceSummary(int difference) {
    return '득실 $difference';
  }

  @override
  String matchLeaguePointsSummary(int points) {
    return '승점 $points';
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
  String get matchTournamentShootoutTitle => '승부차기';

  @override
  String get matchTournamentShootoutHelper =>
      '토너먼트가 무승부면 승부차기 점수로 진출 팀을 확정하세요.';

  @override
  String get matchTournamentShootoutRequired => '토너먼트 무승부는 승부차기 점수로 승자를 정하세요.';

  @override
  String get matchTournamentShootoutTie => '승부차기 점수는 같을 수 없어요.';

  @override
  String matchTournamentShootoutSummary(int homeScore, int awayScore) {
    return '승부차기 $homeScore : $awayScore';
  }

  @override
  String get matchOpponentTeamLabel => '상대 팀';

  @override
  String get matchOpponentTeamHint => '예) 수원 U15';

  @override
  String get matchOpponentRequired => '상대 팀을 선택하거나 입력하세요.';

  @override
  String get matchScoreRequired => '양 팀의 스코어를 모두 입력하세요.';

  @override
  String requiredFieldLabel(Object label) {
    return '$label (필수)';
  }

  @override
  String get matchLocationHint => '예) 메인 구장';

  @override
  String get matchBoardTitle => '시합 보드';

  @override
  String get matchBoardHelper => '상대, 스코어, 승무패, 개인 기록을 경기판에서 바로 조정하세요.';

  @override
  String get matchBoardEventsTitle => '빠른 기록';

  @override
  String get matchYellowCardsLabel => '옐로 카드';

  @override
  String get matchRedCardsLabel => '레드 카드';

  @override
  String get matchDisciplineSummaryLabel => '카드';

  @override
  String matchDisciplineSummary(int yellowCards, int redCards) {
    return '옐로 $yellowCards · 레드 $redCards';
  }

  @override
  String get matchDetailsSectionTitle => '상세 정보';

  @override
  String get matchDetailsSectionHelper => '장소와 메모처럼 경기 후 정리할 내용을 남기세요.';

  @override
  String get matchFlowBasicSectionTitle => '기본 정보';

  @override
  String get matchFlowCompetitionSectionTitle => '대회 설정';

  @override
  String get matchFlowCompetitionSectionHelper =>
      '저장된 대회를 먼저 고르면 참가 팀과 상태가 함께 채워집니다.';

  @override
  String get matchFlowOpponentSectionTitle => '상대팀 선택';

  @override
  String get matchFlowOpponentSectionHelper => '등록된 참가 팀 중 이번 경기 상대를 선택하세요.';

  @override
  String get matchFlowResultSectionTitle => '결과 입력';

  @override
  String get matchFlowResultSectionHelper => '승/무/패를 먼저 고른 뒤 점수와 대회 결과를 조정하세요.';

  @override
  String get matchFlowPersonalSectionTitle => '개인 기록';

  @override
  String get matchFlowPersonalSectionHelper =>
      '득점, 도움, 출전 시간처럼 나중에 통계로 볼 값을 남기세요.';

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
  String get matchHubTopActionTooltip => '팀 관리';

  @override
  String get matchHubTitle => '팀 관리';

  @override
  String get matchHubSubtitle => '선수관리와 시합관리를 팀 단위로 이어서 관리하세요.';

  @override
  String get matchHubOverviewTitle => '운영 현황';

  @override
  String get matchHubRecentFormLabel => '최근 폼';

  @override
  String get matchHubRecordButton => '시합 기록';

  @override
  String get teamMatchHubUpcomingTab => '예정 경기';

  @override
  String get teamMatchHubResultsTab => '경기 결과';

  @override
  String get teamMatchHubUpcomingTitle => '기록할 경기';

  @override
  String get teamMatchHubUpcomingEmptyTitle => '기록할 대회 경기가 없어요.';

  @override
  String get teamMatchHubUpcomingEmptyBody =>
      '대회를 만들면 일정과 대진에서 우리 팀 경기를 바로 기록할 수 있어요.';

  @override
  String get teamMatchHubDateUnset => '일정 미정';

  @override
  String get teamMatchHubRecordFixtureAction => '결과 기록';

  @override
  String get matchEntryManagedInHubTitle => '시합 기록은 팀 관리에서 관리합니다.';

  @override
  String get matchEntryManagedInHubBody =>
      '훈련 노트에서는 시합 정보를 보여주지 않습니다. 시합 확인과 수정은 상단 팀 관리에서 진행해 주세요.';

  @override
  String get matchHubRecordHelper => '오늘 경기 결과를 바로 입력';

  @override
  String get matchRecordsOpenButton => '시합 기록 보기';

  @override
  String get matchRecordsOpenHelper => '지난 경기 결과를 따로 확인';

  @override
  String get matchRecordsTitle => '시합 기록';

  @override
  String get matchRecordsSubtitle => '친선, 리그, 토너먼트 결과를 날짜순으로 확인하세요.';

  @override
  String get matchRecordsSummaryTitle => '기록 요약';

  @override
  String get matchRecordsListTitle => '전체 시합 기록';

  @override
  String get matchRecordsCompetitionAllFilter => '대회 전체';

  @override
  String get matchRecordsSearchHint => '상대, 대회, 라운드, 장소, 메모 검색';

  @override
  String get matchRecordsSearchClearTooltip => '검색어 지우기';

  @override
  String get matchRecordsOutcomeAllFilter => '결과 전체';

  @override
  String get matchRecordsOutcomeUnsetFilter => '결과 미입력';

  @override
  String get matchRecordsDateAllFilter => '기간 전체';

  @override
  String get matchRecordsDateLast30DaysFilter => '최근 30일';

  @override
  String get matchRecordsDateThisYearFilter => '올해';

  @override
  String get matchRecordsFilterEmptyTitle => '조건에 맞는 시합이 없어요.';

  @override
  String get matchRecordsFilterEmptyBody => '검색어와 필터를 초기화해 보세요.';

  @override
  String get matchHubCalendarButton => '일정 보기';

  @override
  String get matchHubCalendarHelper => '날짜별 시합과 계획 확인';

  @override
  String get matchHubStatsButton => '시합 통계';

  @override
  String get matchHubStatsHelper => '전적과 개인 기록 분석';

  @override
  String get matchHubCompetitionHelper => '팀 등록과 대회 결과 관리';

  @override
  String get matchHubCompetitionsTitle => '대회 보드';

  @override
  String get matchHubNoCompetitionsTitle => '등록된 대회가 없어요.';

  @override
  String get matchHubNoCompetitionsSubtitle =>
      '리그나 토너먼트로 시합을 기록하면 팀, 순위, 대진표가 이곳에 모입니다.';

  @override
  String get matchHubRecentMatchesTitle => '최근 시합';

  @override
  String get matchHubEmptyTitle => '아직 시합 기록이 없어요.';

  @override
  String get matchHubEmptySubtitle => '친선 경기부터 빠르게 남기면 승률과 최근 폼을 계산할 수 있어요.';

  @override
  String get matchHubOpeningFeedback => '팀 관리로 이동합니다.';

  @override
  String matchHubRecordedOnlyProgress(int count) {
    return '$count경기 기록됨';
  }

  @override
  String matchHubKindBreakdown(int friendly, int league, int tournament) {
    return '친선 $friendly · 리그 $league · 토너먼트 $tournament';
  }

  @override
  String get matchHubCompetitionStateLabel => '대회 상태';

  @override
  String matchHubCompetitionStateValue(int active, int finished) {
    return '진행 $active · 종료 $finished';
  }

  @override
  String get matchHubTeamManagementHeaderSubtitle =>
      '선수관리, 시합 기록, 대회 흐름을 한곳에서 이어서 관리하세요.';

  @override
  String get matchHubTeamManagementTitle => '팀 현황';

  @override
  String get matchHubTeamManagementHelper => '선수단, 일정, 라인업 관리';

  @override
  String get matchHubTeamStateLabel => '우리 팀';

  @override
  String matchHubTeamStateValue(int count) {
    return '$count팀';
  }

  @override
  String get matchHubNoPrimaryTeamValue => '미등록';

  @override
  String get matchHubNoTeamsTitle => '아직 우리 팀이 없어요.';

  @override
  String get matchHubNoTeamsSubtitle =>
      '선수 등록부터 시작할 수 있는 팀 관리 화면에서 우리 팀을 준비하세요.';

  @override
  String get matchHubCommandCenterTitle => '운영 작업';

  @override
  String get matchHubCommandCenterHelper => '선수관리와 시합관리를 한 화면에서 선택해 이어서 작업하세요.';

  @override
  String get matchHubPlayerCommandHelper => '선수 등록, 전술 책, 시합 준비 보드를 관리하세요.';

  @override
  String get matchHubTeamCommandHelper => '선수관리와 시합관리를 한 화면 구조 안에서 전환합니다.';

  @override
  String get matchHubTeamCommandPrimary => '팀 관리 열기';

  @override
  String get matchHubMatchCommandTitle => '시합 관리';

  @override
  String get matchHubMatchCommandHelper => '시합 기록, 기록 확인, 통계 분석을 빠르게 실행하세요.';

  @override
  String matchHubMoreTeamsCount(int count) {
    return '외 $count팀 더 있음';
  }

  @override
  String matchHubTeamFormationValue(Object formation) {
    return '$formation 포메이션';
  }

  @override
  String get clubScheduleTitle => '클럽 일정';

  @override
  String get clubScheduleSubtitle => '요일별 훈련시간과 유니폼, 양말 컬러를 빠르게 확인하세요.';

  @override
  String get clubScheduleHomeTitle => '클럽 일정';

  @override
  String get clubScheduleHomeTodayRest => '오늘 훈련 없음';

  @override
  String get clubScheduleHomeSetupHint => '훈련 시간과 유니폼, 양말 컬러를 등록하세요.';

  @override
  String clubScheduleHomeNextTraining(Object weekday, Object time) {
    return '다음 훈련 $weekday $time';
  }

  @override
  String clubScheduleTodayTraining(Object time) {
    return '오늘 $time';
  }

  @override
  String get clubScheduleTodayNoTraining => '오늘 등록된 훈련이 없어요.';

  @override
  String clubScheduleNextTraining(Object weekday, Object time) {
    return '다음 훈련: $weekday $time';
  }

  @override
  String get clubScheduleNoUpcomingTraining => '예정된 훈련이 없어요.';

  @override
  String get clubScheduleClubNameLabel => '클럽 이름';

  @override
  String get clubScheduleClubNameHint => '예) 성남 U15';

  @override
  String get clubMorningWorkoutAlertTitle => '아침 운동 알림';

  @override
  String get clubMorningWorkoutAlertHelper => '클럽 일정과 함께 아침 운동 시간을 챙겨요.';

  @override
  String get clubMorningWorkoutAlertSwitchTitle => '아침 운동 알림 켜기';

  @override
  String clubMorningWorkoutAlertSwitchSubtitle(Object weekdays, Object time) {
    return '$weekdays · $time에 알림';
  }

  @override
  String get clubMorningWorkoutAlertTimeTitle => '알림 시간';

  @override
  String clubMorningWorkoutAlertTimeSubtitle(Object time) {
    return '현재 $time';
  }

  @override
  String get clubMorningWorkoutAlertChangeTimeAction => '시간 변경';

  @override
  String get clubMorningWorkoutAlertWeekdayTitle => '알림 요일';

  @override
  String get clubMorningWorkoutAlertEveryDay => '매일';

  @override
  String get clubScheduleWeekdayTitle => '요일별 훈련시간';

  @override
  String get clubScheduleWeekdayHelper =>
      '훈련이 있는 요일만 켜고 시작/종료 시간, 유니폼과 양말 컬러를 맞추세요.';

  @override
  String get clubScheduleStartTimeLabel => '시작';

  @override
  String get clubScheduleEndTimeLabel => '종료';

  @override
  String get clubScheduleDayOffLabel => '쉼';

  @override
  String get clubScheduleDayUniformLabel => '유니폼';

  @override
  String get clubScheduleDaySockLabel => '양말';

  @override
  String get clubScheduleUniformTitle => '유니폼 컬러';

  @override
  String get clubScheduleUniformHelper => '훈련장에서 바로 확인할 홈, 어웨이, 골키퍼 컬러를 정해두세요.';

  @override
  String get clubScheduleHomeKitLabel => '홈';

  @override
  String get clubScheduleAwayKitLabel => '어웨이';

  @override
  String get clubScheduleKeeperKitLabel => 'GK';

  @override
  String get clubScheduleColorSelectTooltip => '컬러 선택';

  @override
  String get clubScheduleColorPresetsLabel => '대표 색상';

  @override
  String get clubScheduleColorHueLabel => '색상';

  @override
  String get clubScheduleColorSaturationLabel => '채도';

  @override
  String get clubScheduleColorBrightnessLabel => '밝기';

  @override
  String get clubScheduleSaveButton => '클럽 일정 저장';

  @override
  String get clubScheduleSavedFeedback => '클럽 일정을 저장했어요.';

  @override
  String get clubScheduleSaveFailedFeedback => '클럽 일정 저장에 실패했어요. 다시 시도해 주세요.';

  @override
  String get clubScheduleUnsavedDialogTitle => '저장되지 않은 변경사항';

  @override
  String get clubScheduleUnsavedDialogBody =>
      '아직 저장되지 않은 클럽 일정 변경이 있어요. 저장하고 나갈까요?';

  @override
  String get clubScheduleUnsavedKeepEditing => '계속 편집';

  @override
  String get clubScheduleUnsavedLeaveWithoutSaving => '저장 안 하고 나가기';

  @override
  String get clubScheduleUnsavedSaveAndLeave => '저장 후 나가기';

  @override
  String get clubTrainingNotificationChannelName => '클럽 훈련 알림';

  @override
  String get clubTrainingNotificationChannelDescription => '클럽 훈련 시작 전 리마인드 알림';

  @override
  String clubTrainingNotificationTitle(Object clubName) {
    return '$clubName 훈련 준비';
  }

  @override
  String clubTrainingNotificationBody(int minutesBefore, Object timeRange) {
    return '$minutesBefore분 뒤 훈련 · $timeRange';
  }

  @override
  String get clubMorningWorkoutNotificationTitle => '아침 운동 알림';

  @override
  String clubMorningWorkoutNotificationBody(Object time) {
    return '$time 아침 운동 시간이에요.';
  }

  @override
  String get teamManagementTitle => '팀 관리';

  @override
  String get teamManagementSubtitle => '선수단, 전술 책, 일정과 대회를 작업별로 정리하세요.';

  @override
  String get teamManagementOpenButton => '팀 관리';

  @override
  String get teamManagementPlayerSectionTab => '선수관리';

  @override
  String get teamManagementMatchSectionTab => '시합관리';

  @override
  String get teamManagementDefaultTeamName => '우리 팀';

  @override
  String get teamManagementWorkspaceTitle => '작업 선택';

  @override
  String get teamManagementWorkspaceHelper =>
      '필요한 작업 버튼을 눌러 선수단, 전술 책, 일정 화면으로 이동하세요.';

  @override
  String get teamManagementWorkspaceBackButton => '작업 선택으로';

  @override
  String get teamManagementWorkspaceRosterTab => '선수단';

  @override
  String get teamManagementWorkspaceBoardTab => '전술 보드';

  @override
  String get teamManagementBoardHeaderButton => '보드';

  @override
  String get teamManagementCompetitionHeaderButton => '대회';

  @override
  String get teamManagementTacticBookTitle => '전술 리스트';

  @override
  String teamManagementTacticBookPageCount(int count) {
    return '$count개 전술';
  }

  @override
  String teamManagementTacticBoardDefaultTitle(int index) {
    return '전술 $index';
  }

  @override
  String teamManagementTacticBoardCopyTitle(Object title) {
    return '$title 복사본';
  }

  @override
  String get teamManagementTacticBoardAddButton => '새 전술';

  @override
  String get teamManagementTacticBoardDuplicateButton => '복제';

  @override
  String get teamManagementTacticBoardRenameButton => '이름 변경';

  @override
  String get teamManagementTacticBoardEditButton => '전술 정보';

  @override
  String get teamManagementTacticBoardDeleteButton => '삭제';

  @override
  String get teamManagementTacticBoardRenameDialogTitle => '전술 이름 변경';

  @override
  String get teamManagementTacticBoardEditDialogTitle => '전술 정보 편집';

  @override
  String get teamManagementTacticBoardNameLabel => '전술 이름';

  @override
  String get teamManagementTacticBoardDescriptionLabel => '전술 설명';

  @override
  String get teamManagementTacticBoardDescriptionHint =>
      '예) 하프스페이스 점유 후 오른쪽 전환';

  @override
  String get teamManagementTacticBoardRenameSaveButton => '저장';

  @override
  String get teamManagementTacticBoardDeleteDialogTitle => '전술 삭제';

  @override
  String teamManagementTacticBoardDeleteDialogBody(Object title) {
    return '\"$title\" 전술을 삭제할까요?';
  }

  @override
  String get teamManagementTacticBoardDeletedFeedback => '전술을 삭제했어요.';

  @override
  String get teamManagementTacticBoardUndoFeedback => '전술 변경을 되돌렸어요.';

  @override
  String teamManagementTacticBoardPageMeta(int players, int markers) {
    return '$players명 · 마커 $markers개';
  }

  @override
  String get teamManagementWorkspaceProfileTab => '팀 프로필';

  @override
  String get teamManagementWorkspaceOperationsTab => '일정·대회';

  @override
  String get teamManagementWorkspaceProfileValue => '이름·전술';

  @override
  String get teamManagementSavedTeamsTitle => '팀 선택';

  @override
  String get teamManagementSavedTeamsHelper =>
      '저장된 팀을 선택하면 선수단, 전술 원칙, 보드 배치를 바로 이어서 운영할 수 있어요.';

  @override
  String get teamManagementNoTeamsTitle => '첫 팀을 준비 중입니다.';

  @override
  String get teamManagementNoTeamsBody =>
      '팀 이름과 선수 명단을 입력하면 자동 저장되어 이곳에 팀 카드가 생깁니다.';

  @override
  String get teamManagementOperationsTitle => '운영 요약';

  @override
  String get teamManagementOperationsHelper =>
      '다음 훈련, 선수단 상태, 라인업 완성도와 참가 대회를 한눈에 확인하세요.';

  @override
  String get teamManagementOperationsNextTrainingLabel => '다음 훈련';

  @override
  String get teamManagementOperationsNextTrainingUnset => '훈련 일정 없음';

  @override
  String get teamManagementOperationsRosterLabel => '선수단 상태';

  @override
  String teamManagementOperationsRosterValue(int total, int managed) {
    return '전체 $total명 · 관리 $managed명';
  }

  @override
  String get teamManagementOperationsLineupLabel => '라인업';

  @override
  String get teamManagementOperationsCompetitionsLabel => '대회';

  @override
  String teamManagementOperationsCompetitionsValue(int active, int total) {
    return '진행 $active · 전체 $total';
  }

  @override
  String get teamManagementOperationsScheduleTitle => '일정과 대회';

  @override
  String get teamManagementOperationsScheduleHelper =>
      '훈련 요일, 유니폼, 참가 대회를 일정 섹션에서 정리하세요.';

  @override
  String get teamManagementOperationsOpenScheduleButton => '일정 편집';

  @override
  String get teamManagementOperationsNoTraining => '등록된 훈련 일정이 없어요.';

  @override
  String get teamManagementOperationsUniformLabel => '유니폼';

  @override
  String get teamManagementOperationsCompetitionTitle => '참가 대회';

  @override
  String get teamManagementOperationsNoCompetitions =>
      '대회 관리에서 리그나 토너먼트를 만들면 이곳에 진행 상태가 표시됩니다.';

  @override
  String get teamManagementNewTeamButton => '새 팀';

  @override
  String get teamManagementBasicsTitle => '팀 프로필';

  @override
  String get teamManagementBasicsHelper => '선수단에서 사용할 팀 이름을 관리하세요.';

  @override
  String get teamManagementTeamNameLabel => '팀 이름';

  @override
  String get teamManagementTeamNameHint => '예) 우리 팀 U15';

  @override
  String get teamManagementStrategyLabel => '전술 설명';

  @override
  String get teamManagementStrategyHint => '예) 전방 압박 시작 위치, 측면 전환 약속, 수비 블록 기준';

  @override
  String get teamManagementFormationTitle => '프로 전술 보드';

  @override
  String get teamManagementFormationHelper =>
      '선수를 자유 배치하고 이동선, 압박선, 공간 영역을 넓은 보드에서 정리하세요.';

  @override
  String get teamManagementFormationLabel => '포메이션';

  @override
  String teamManagementFormationSpotLabel(Object spot) {
    return '$spot';
  }

  @override
  String get teamManagementSelectPositionPrompt => '그라운드에서 포지션을 선택하세요.';

  @override
  String teamManagementSelectedPosition(Object position) {
    return '$position 배정';
  }

  @override
  String get teamManagementAssignedPlayerLabel => '배정할 선수';

  @override
  String get teamManagementUnassignedPlayer => '미배정';

  @override
  String get teamManagementPlayersTitle => '선수단';

  @override
  String get teamManagementPlayerSearchTooltip => '선수 검색';

  @override
  String get teamManagementPlayerSearchCloseTooltip => '검색 닫기';

  @override
  String get teamManagementPlayerSearchHint => '선수 이름, 등번호 또는 학년 검색';

  @override
  String get teamManagementPlayerFilterTooltip => '선수 상태 필터';

  @override
  String get teamManagementPlayerFilterEmptyTitle => '조건에 맞는 선수가 없어요.';

  @override
  String get teamManagementPlayerFilterEmptyBody => '검색어나 상태 필터를 초기화해 보세요.';

  @override
  String get teamManagementRosterSummaryAll => '전체';

  @override
  String get teamManagementRosterSummaryReady => '출전';

  @override
  String get teamManagementRosterSummaryWatch => '관리';

  @override
  String get teamManagementRosterSummaryRest => '휴식';

  @override
  String get teamManagementPlayersHelper =>
      '등번호, 포지션, 주발, 컨디션과 관리 메모를 선수단 카드로 관리하세요.';

  @override
  String get teamManagementPlayerSectionBoardHelper =>
      '라인업과 움직임, 압박선, 공간 영역을 보드에서 직접 구성하세요.';

  @override
  String get teamManagementMatchSectionTitle => '시합관리';

  @override
  String get teamManagementMatchSectionHelper =>
      '시합 기록, 기록 확인, 통계, 클럽 일정을 한곳에서 실행하세요. 대회 관리는 타이틀 우측 버튼에서 열 수 있습니다.';

  @override
  String get teamManagementRosterBoardTitle => '스쿼드 보드';

  @override
  String get teamManagementRosterBoardHelper =>
      '포지션별로 선수 상태와 보드 배치를 빠르게 확인하세요.';

  @override
  String teamManagementRoleGroupCount(Object role, int count) {
    return '$role · $count명';
  }

  @override
  String get teamManagementPlayerNameLabel => '선수 이름';

  @override
  String get teamManagementPlayerNameHint => '예) 김민준';

  @override
  String get teamManagementPlayerNumberLabel => '번호';

  @override
  String get teamManagementPlayerNumberHint => '10';

  @override
  String get teamManagementPlayerRegistrationTitle => '선수 등록';

  @override
  String get teamManagementPlayerEditTitle => '선수 정보 수정';

  @override
  String get teamManagementRegisterPlayerButton => '선수 등록';

  @override
  String get teamManagementPlayerImageTitle => '선수 이미지';

  @override
  String get teamManagementPlayerImageEmptyTitle => '선수 사진';

  @override
  String get teamManagementPlayerImageSelectButton => '사진 선택';

  @override
  String get teamManagementPlayerImageReplaceButton => '사진 변경';

  @override
  String get teamManagementPlayerImageRemoveButton => '사진 제거';

  @override
  String get teamManagementPlayerImagePickFailed =>
      '이미지를 불러오지 못했어요. 다른 사진으로 다시 시도해 주세요.';

  @override
  String get teamManagementPlayerBasicInfoTitle => '기본 정보';

  @override
  String get teamManagementPlayerGradeLabel => '학년';

  @override
  String get teamManagementPlayerGradeHint => '예) 초등 5학년';

  @override
  String get teamManagementPlayerGradeUnset => '학년 미선택';

  @override
  String teamManagementPlayerElementaryGradeOption(int grade) {
    return '초등 $grade학년';
  }

  @override
  String teamManagementPlayerMiddleGradeOption(int grade) {
    return '중등 $grade학년';
  }

  @override
  String teamManagementPlayerHighGradeOption(int grade) {
    return '고등 $grade학년';
  }

  @override
  String get teamManagementPlayerBodySizeTitle => '신체 사이즈';

  @override
  String get teamManagementPlayerBodySizeUnset => '미선택';

  @override
  String get teamManagementPlayerHeightLabel => '키';

  @override
  String get teamManagementPlayerHeightUnit => 'cm';

  @override
  String get teamManagementPlayerWeightLabel => '몸무게';

  @override
  String get teamManagementPlayerWeightUnit => 'kg';

  @override
  String get teamManagementPlayerStatusTitle => '상태 정보';

  @override
  String get teamManagementPlayerNumberEmpty => '번호 없음';

  @override
  String teamManagementPlayerNumberPreview(Object number) {
    return '번호 $number';
  }

  @override
  String teamManagementPlayerGradeMeta(Object grade) {
    return '$grade';
  }

  @override
  String teamManagementPlayerHeightMeta(Object height) {
    return '${height}cm';
  }

  @override
  String teamManagementPlayerWeightMeta(Object weight) {
    return '${weight}kg';
  }

  @override
  String get teamManagementPlayerRoleLabel => '기본 포지션';

  @override
  String get teamManagementPlayerPositionLabel => '세부 포지션';

  @override
  String get teamManagementPositionGoalkeeper => 'GK · 골키퍼';

  @override
  String get teamManagementPositionLeftBack => 'LB · 왼쪽 풀백';

  @override
  String get teamManagementPositionCenterBack => 'CB · 센터백';

  @override
  String get teamManagementPositionRightBack => 'RB · 오른쪽 풀백';

  @override
  String get teamManagementPositionDefensiveMidfielder => 'DM · 수비형 미드필더';

  @override
  String get teamManagementPositionLeftMidfielder => 'LM · 왼쪽 미드필더';

  @override
  String get teamManagementPositionCentralMidfielder => 'CM · 중앙 미드필더';

  @override
  String get teamManagementPositionRightMidfielder => 'RM · 오른쪽 미드필더';

  @override
  String get teamManagementPositionAttackingMidfielder => 'AM · 공격형 미드필더';

  @override
  String get teamManagementPositionLeftWinger => 'LW · 왼쪽 윙';

  @override
  String get teamManagementPositionStriker => 'ST · 스트라이커';

  @override
  String get teamManagementPositionRightWinger => 'RW · 오른쪽 윙';

  @override
  String get teamManagementPlayerFootLabel => '주발';

  @override
  String get teamManagementPlayerFootRight => '오른발';

  @override
  String get teamManagementPlayerFootLeft => '왼발';

  @override
  String get teamManagementPlayerFootBoth => '양발';

  @override
  String get teamManagementPlayerConditionLabel => '컨디션';

  @override
  String get teamManagementPlayerConditionReady => '출전 가능';

  @override
  String get teamManagementPlayerConditionWatch => '관리 필요';

  @override
  String get teamManagementPlayerConditionRest => '휴식 권장';

  @override
  String get teamManagementPlayerNoteLabel => '선수 메모';

  @override
  String get teamManagementPlayerNoteHint => '예) 왼발 킥 좋음, 압박 전환 빠름, 무릎 관리 필요';

  @override
  String get teamManagementAddPlayerButton => '선수 등록';

  @override
  String get teamManagementUpdatePlayerButton => '수정 저장';

  @override
  String get teamManagementCancelPlayerEditButton => '수정 취소';

  @override
  String get teamManagementEditPlayerButton => '수정';

  @override
  String get teamManagementNoPlayersTitle => '등록된 선수가 없어요.';

  @override
  String get teamManagementNoPlayersBody =>
      '선수를 추가하면 그라운드 보드에 바로 끌어 올릴 수 있습니다.';

  @override
  String teamManagementPlayerMeta(Object role, int count) {
    return '$role · $count개 보드 배치';
  }

  @override
  String teamManagementPlayerDetailMeta(
      Object role, Object foot, Object condition, int count) {
    return '$role · $foot · $condition · $count개 배치';
  }

  @override
  String teamManagementRosterPlacementCount(int count) {
    return '보드 $count';
  }

  @override
  String get teamManagementRosterNoPlacement => '보드 미배치';

  @override
  String teamManagementRosterReadyCount(int count) {
    return '출전 가능 $count';
  }

  @override
  String teamManagementRosterManagedCount(int count) {
    return '관리 $count';
  }

  @override
  String get teamManagementPlayerTrayTitle => '드래그할 선수';

  @override
  String get teamManagementPlayerTrayEmpty =>
      '먼저 선수를 등록하면 여기에서 그라운드로 바로 끌어 놓을 수 있어요.';

  @override
  String get teamManagementBoardMovePlayersMode => '선수 배치';

  @override
  String get teamManagementBoardDrawMode => '보드 마카';

  @override
  String get teamManagementBoardMovementMode => '이동선';

  @override
  String get teamManagementBoardPressMode => '압박선';

  @override
  String get teamManagementBoardZoneMode => '공간 영역';

  @override
  String get teamManagementBoardClearLinesButton => '선 지우기';

  @override
  String get teamManagementBoardClearMarkersButton => '마커 지우기';

  @override
  String get teamManagementBoardDeleteSelectedMarkerButton => '선택 삭제';

  @override
  String get teamManagementBoardLandscapeButton => '가로모드';

  @override
  String get teamManagementBoardPortraitButton => '세로모드';

  @override
  String get teamManagementBoardPlacementLabel => '보드 배치';

  @override
  String get teamManagementBoardMarkerLabel => '전술 마커';

  @override
  String teamManagementBoardPlacementValue(int placed, int total) {
    return '$placed/$total 배치';
  }

  @override
  String teamManagementTacticLinesCount(int count) {
    return '마커 $count개';
  }

  @override
  String get teamManagementFormationDropHint =>
      '선수 배치 모드에서는 보드 위 선수를 직접 끌어 위치를 조정하세요. 더 넓게 그릴 때는 가로모드를 사용하세요.';

  @override
  String get teamManagementRemovePlayerButton => '삭제';

  @override
  String get teamManagementDeleteTeamButton => '팀 삭제';

  @override
  String get teamManagementSaveTeamButton => '팀 저장';

  @override
  String get teamManagementSaveHint =>
      '우리 팀의 선수단, 전술, 보드 배치는 변경 즉시 자동 저장되고 팀 관리의 팀 현황에 반영됩니다.';

  @override
  String get teamManagementAutoSaveReady => '자동 저장';

  @override
  String get teamManagementAutoSavePending => '저장 대기';

  @override
  String get teamManagementAutoSaveSaving => '저장 중';

  @override
  String get teamManagementAutoSaveSaved => '저장됨';

  @override
  String get teamManagementAutoSaveNeedsName => '팀 이름 필요';

  @override
  String get teamManagementNameRequired => '팀 이름을 입력하세요.';

  @override
  String get teamManagementPlayerRequired => '선수 이름을 입력하세요.';

  @override
  String get teamManagementSavedFeedback => '팀 정보를 저장했어요.';

  @override
  String get teamManagementDeletedFeedback => '팀을 삭제했어요.';

  @override
  String get teamManagementRoleGoalkeeper => '골키퍼';

  @override
  String get teamManagementRoleDefender => '수비수';

  @override
  String get teamManagementRoleMidfielder => '미드필더';

  @override
  String get teamManagementRoleForward => '공격수';

  @override
  String teamManagementLineupFilled(int filled, int total) {
    return '$filled/$total 배정';
  }

  @override
  String teamManagementPlayerCount(int count) {
    return '$count명';
  }

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
  String get matchSavedFeedback => '시합 기록을 저장했어요.';

  @override
  String get matchUpdatedFeedback => '시합 기록을 수정했어요.';

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
  String get trainingSketchPdfExportTooltip => '스케치 PDF 다운로드';

  @override
  String get trainingSketchPdfExportedSnack => '스케치 PDF를 준비했어요.';

  @override
  String get trainingSketchPdfExportFailedSnack => '스케치 PDF를 만들지 못했어요.';

  @override
  String get trainingSketchVideoExportTooltip => '움직이는 영상 만들기';

  @override
  String get trainingSketchVideoExportedSnack => '스케치 움직임 영상을 준비했어요.';

  @override
  String get trainingSketchVideoExportFailedSnack => '스케치 움직임 영상을 만들지 못했어요.';

  @override
  String get trainingSketchVideoExportUnavailableSnack =>
      '이 기기에서는 움직임 영상 내보내기를 지원하지 않아요.';

  @override
  String get trainingSketchLandscapeModeTooltip => '가로 모드';

  @override
  String get trainingSketchPortraitModeTooltip => '세로 모드';

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
  String get trainingSketchBoardNameLabel => '보드명';

  @override
  String get trainingSketchBoardNameHint => '예) 패스 워밍업';

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
  String get trainingSketchAddElementMenuButton => '요소 추가';

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
  String get trainingSketchNextActionButton => '다음 동작 추가';

  @override
  String trainingSketchPlayerFlowTitle(int index) {
    return '사람 $index 흐름';
  }

  @override
  String get trainingSketchPlayerFlowWithBall => '공 보유';

  @override
  String get trainingSketchPlayerFlowWithoutBall => '공 없음';

  @override
  String trainingSketchPlayerFlowNextStageChip(int stage) {
    return '다음 $stage단계';
  }

  @override
  String get trainingSketchPlayerFlowHint =>
      '선수의 다음 동작을 고르면 단계와 공 이동이 자동으로 이어집니다.';

  @override
  String get trainingSketchPlayerFlowPassSection => '동료에게 바로 연결';

  @override
  String get trainingSketchPlayerFlowBallSection => '공을 쓰는 동작';

  @override
  String get trainingSketchPlayerFlowMoveSection => '움직임';

  @override
  String get trainingSketchGlobalStagesTitle => '전체 단계';

  @override
  String get trainingSketchGlobalStagesHint =>
      '보드 전체 순서로 이어서 만들고, 필요하면 같은 단계에 여러 액션을 함께 넣을 수 있어요.';

  @override
  String get trainingSketchActionTimelineTitle => '전체 액션';

  @override
  String get trainingSketchActionTimelineEmpty =>
      '아직 액션이 없어요. 선수를 선택해 다음 동작을 추가하세요.';

  @override
  String get trainingSketchReorderStageTooltip => '단계 순서 변경';

  @override
  String get trainingSketchReorderActionTooltip => '액션 순서 변경';

  @override
  String get trainingSketchRunWithPreviousTooltip => '앞 액션과 동시에 실행';

  @override
  String get trainingSketchRunAfterPreviousTooltip => '앞 액션 다음에 실행';

  @override
  String get trainingSketchDeleteActionTooltip => '액션 삭제';

  @override
  String get trainingSketchGlobalStagesEmpty =>
      '아직 등록된 단계가 없어요. 첫 액션은 1단계로 시작합니다.';

  @override
  String trainingSketchGlobalStageChip(int stage, int count) {
    return '$stage단계 · 액션 $count개';
  }

  @override
  String get trainingSketchStageActionSelectedLabel => '선택됨';

  @override
  String get trainingSketchInsertActionAfterTooltip => '이 액션 뒤에 새 액션 삽입';

  @override
  String get trainingSketchStageActionUnknownItem => '요소';

  @override
  String trainingSketchStageActionPlayerMove(Object actor) {
    return '$actor 이동';
  }

  @override
  String trainingSketchStageActionPlayerStay(Object actor) {
    return '$actor 제자리';
  }

  @override
  String trainingSketchStageActionBallMove(Object actor) {
    return '$actor 공 이동';
  }

  @override
  String trainingSketchStageActionBallPickup(Object actor) {
    return '$actor 공 확보';
  }

  @override
  String trainingSketchStageActionBallToTarget(Object actor, Object target) {
    return '$actor에서 $target로 공 이동';
  }

  @override
  String trainingSketchStageActionUnownedBallMove(Object ball) {
    return '$ball 이동';
  }

  @override
  String trainingSketchAddSameStageButton(int stage) {
    return '$stage단계에 동시에 추가';
  }

  @override
  String trainingSketchAddNextStageButton(int stage) {
    return '새 $stage단계 만들기';
  }

  @override
  String trainingSketchRegisteredNextGlobalStageHint(int stage) {
    return '현재 전체 $stage단계 편집 중입니다.';
  }

  @override
  String trainingSketchBallPossessionRequiredSnack(Object player) {
    return '$player는 지금 공을 가지고 있지 않아요. 먼저 패스를 받거나 소유 중인 공을 선택해 주세요.';
  }

  @override
  String get trainingSketchBallOwnershipTitle => '공 소유 관계';

  @override
  String trainingSketchBallOwnedBy(Object ball, Object player) {
    return '$ball: $player 보유';
  }

  @override
  String trainingSketchBallMovingToTarget(
      Object ball, Object actor, Object target) {
    return '$ball: $actor에서 $target로 이동 중';
  }

  @override
  String trainingSketchBallUnowned(Object ball) {
    return '$ball: 소유자 없음';
  }

  @override
  String get trainingSketchFlowReviewTitle => '흐름 점검';

  @override
  String get trainingSketchFlowReviewOk => '공 소유와 액션 연결이 자연스럽습니다.';

  @override
  String trainingSketchFlowWarningBallWithoutActor(Object ball) {
    return '$ball가 사람 없이 움직입니다.';
  }

  @override
  String trainingSketchFlowWarningWrongOwner(
      Object ball, Object owner, Object actor) {
    return '$ball는 $owner 보유인데 $actor가 사용합니다.';
  }

  @override
  String trainingSketchFlowWarningUnownedBallUsed(Object ball, Object actor) {
    return '$ball는 소유자 없음 상태인데 $actor가 사용합니다.';
  }

  @override
  String trainingSketchFlowWarningMultipleActors(Object ball, int stage) {
    return '$stage단계에서 $ball를 여러 사람이 동시에 사용합니다.';
  }

  @override
  String trainingSketchFlowWarningInvalidTarget(Object ball, Object target) {
    return '$ball의 도착 대상이 사람($target)이 아닙니다.';
  }

  @override
  String get trainingSketchSelectedItemTitle => '선택 요소';

  @override
  String get trainingSketchAssignColorLabel => '색상 지정';

  @override
  String get trainingSketchPlayerStagesTitle => '선수 단계';

  @override
  String get trainingSketchPlayerStagesEmpty => '아직 이 선수에게 등록된 단계가 없어요.';

  @override
  String trainingSketchPlayerStageChip(int stage, int count) {
    return '$stage단계 · 동작 $count개';
  }

  @override
  String trainingSketchRegisterNextPlayerStageButton(int stage) {
    return '$stage단계 등록';
  }

  @override
  String trainingSketchRegisteredNextPlayerStageHint(int stage) {
    return '다음 액션은 $stage단계로 만들어져요.';
  }

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
  String get trainingBoardListTitle => '훈련 스케치 리스트';

  @override
  String get trainingBoardTitleDialogTitle => '훈련 스케치 제목';

  @override
  String get trainingBoardTitleHint => '예) 패스 워밍업';

  @override
  String get trainingBoardRenamedSnack => '보드 이름을 변경했어요.';

  @override
  String get trainingBoardRenameUndoneSnack => '이름 변경을 되돌렸어요.';

  @override
  String get trainingBoardNoCopySourceSnack => '복사할 훈련 스케치가 없어요.';

  @override
  String trainingBoardDefaultCopyTitle(Object title) {
    return '$title 복사본';
  }

  @override
  String get trainingBoardDeleteTitle => '훈련 스케치 삭제';

  @override
  String trainingBoardDeleteConfirm(Object title) {
    return '\"$title\"를 정말 삭제할까요?';
  }

  @override
  String get trainingBoardDeletedSnack => '보드를 삭제했어요.';

  @override
  String get trainingBoardDeleteUndoneSnack => '삭제를 되돌렸어요.';

  @override
  String get trainingBoardDefaultTitle => '훈련 보드';

  @override
  String get trainingBoardSearchCloseTooltip => '검색 닫기';

  @override
  String get trainingBoardSearchTooltip => '보드 검색';

  @override
  String get trainingBoardSortTooltip => '정렬';

  @override
  String get trainingBoardSortRecentlyUpdated => '최근 수정순';

  @override
  String get trainingBoardSortTrainingDate => '훈련일 최신순';

  @override
  String get trainingBoardSortName => '이름순';

  @override
  String get trainingBoardAddTooltip => '훈련 스케치 추가';

  @override
  String get trainingBoardCreateNewAction => '새 스케치 만들기';

  @override
  String get trainingBoardCopyPreviousAction => '이전 스케치 복사';

  @override
  String get trainingBoardDoneAction => '완료';

  @override
  String get trainingBoardEmptyTitle => '훈련보드가 아직 없습니다.';

  @override
  String get trainingBoardEmptySubtitle => '훈련노트에서 보드 버튼을 눌러 바로 생성해보세요.';

  @override
  String get trainingBoardBackToNotes => '훈련노트로 돌아가기';

  @override
  String get trainingBoardSearchHint => '보드명 검색';

  @override
  String get trainingBoardNoSearchResults => '검색 결과가 없습니다.';

  @override
  String trainingBoardListItemSubtitle(Object count, Object date) {
    return '요소 $count개 · 훈련일 $date';
  }

  @override
  String get trainingBoardRenameAction => '이름 변경';

  @override
  String get trainingBoardDuplicateAction => '복제';

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
  String get trainingSketchExtendRouteButton => '끝에 이어 그리기';

  @override
  String get trainingSketchReverseRouteButton => '방향 뒤집기';

  @override
  String get trainingSketchRedrawRouteButton => '선택 이동선 다시 그리기';

  @override
  String get trainingSketchDeleteRouteButton => '선택 이동선 삭제';

  @override
  String get trainingSketchEditStageActionTooltip => '단계 액션 수정';

  @override
  String get trainingSketchAddSameStageActionTooltip => '이 단계에 선수 액션 추가';

  @override
  String get trainingSketchAddNextStageActionTooltip => '다음 단계에 선수 액션 추가';

  @override
  String get trainingSketchDeleteStageActionTooltip => '단계 액션 삭제';

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
  String trainingSketchPassTargetHint(Object action) {
    return '$action 받을 선수를 누르세요.';
  }

  @override
  String get trainingSketchActionTargetCancelButton => '취소';

  @override
  String get trainingSketchActionCreatedSnack => '동작을 추가했어요.';

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
  String get trainingSketchQuickMoveToBallButton => '공으로 이동';

  @override
  String get trainingSketchQuickStayButton => '제자리';

  @override
  String get trainingSketchMoveThenPassButton => '이동 후 패스';

  @override
  String get trainingSketchMoveThenPassReceiverPrompt =>
      '이동 지점을 정했어요. 패스할 선수를 선택하세요.';

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
  String get trainingSketchQuickConeTurnButton => '콘 돌기';

  @override
  String get trainingSketchQuickConeJumpButton => '콘 넘기';

  @override
  String get trainingSketchQuickHurdleJumpButton => '뜀틀 넘기';

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
  String get trainingSketchPassToNewPlayerButton => '새 사람에게 패스';

  @override
  String trainingSketchPassToSpotButton(Object target, int index) {
    return '$target $index에 패스';
  }

  @override
  String trainingSketchConeTurnTargetButton(int index) {
    return '콘 $index 돌기';
  }

  @override
  String trainingSketchConeJumpTargetButton(int index) {
    return '콘 $index 넘기';
  }

  @override
  String trainingSketchHurdleJumpTargetButton(int index) {
    return '뜀틀 $index 넘기';
  }

  @override
  String trainingSketchThrowToPlayerButton(int index) {
    return '사람 $index에게 송구';
  }

  @override
  String get trainingSketchThrowToNewPlayerButton => '새 사람에게 송구';

  @override
  String trainingSketchThrowToSpotButton(Object target, int index) {
    return '$target $index에 송구';
  }

  @override
  String trainingSketchRallyToPlayerButton(int index) {
    return '사람 $index에게 랠리';
  }

  @override
  String get trainingSketchRallyToNewPlayerButton => '새 사람에게 랠리';

  @override
  String trainingSketchRallyToSpotButton(Object target, int index) {
    return '$target $index로 랠리';
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
  String get trainingSketchTemplatePassWarmupLabel => '3인 패스 앤 무브';

  @override
  String get trainingSketchTemplatePassWarmupDescription => '패스, 지원, 자리 교대 흐름';

  @override
  String get trainingSketchTemplatePassWarmupMethod =>
      '받기 전 몸 열기, 패스 후 다음 위치로 이동';

  @override
  String get trainingSketchTemplateBuildUpLabel => '후방 빌드업 탈압박';

  @override
  String get trainingSketchTemplateBuildUpDescription => '골키퍼-센터백-6번 연결';

  @override
  String get trainingSketchTemplateBuildUpMethod =>
      '압박을 끌어낸 뒤 6번을 거쳐 반대 풀백으로 전개';

  @override
  String get trainingSketchTemplatePressingLabel => '5초 역압박';

  @override
  String get trainingSketchTemplatePressingDescription => '볼 잃은 뒤 즉시 압박과 커버';

  @override
  String get trainingSketchTemplatePressingMethod =>
      '가장 가까운 선수는 압박, 주변 선수는 패스길 차단';

  @override
  String get trainingSketchTemplateSetPieceLabel => '코너킥 니어-파';

  @override
  String get trainingSketchTemplateSetPieceDescription => '스크린, 니어 터치, 파포스트 침투';

  @override
  String get trainingSketchTemplateSetPieceMethod =>
      '블로커가 길을 만들고 니어 플릭 뒤 파포스트 마무리';

  @override
  String get trainingSketchTemplateRondoLabel => '5대2 론도 전환';

  @override
  String get trainingSketchTemplateRondoDescription => '조커를 활용한 분할 패스와 회전';

  @override
  String get trainingSketchTemplateRondoMethod => '압박 사이를 찢는 패스 후 지원 위치를 회전';

  @override
  String get trainingSketchTemplateFinishingLabel => '컷백 마무리';

  @override
  String get trainingSketchTemplateFinishingDescription => '측면 드라이브, 컷백, 박스 침투';

  @override
  String get trainingSketchTemplateFinishingMethod =>
      '측면 돌파 후 니어, 컷백, 파포스트를 동시에 공격';

  @override
  String get trainingSketchTemplateWingCombinationLabel => '측면 오버랩/언더랩';

  @override
  String get trainingSketchTemplateWingCombinationDescription =>
      '풀백, 윙어, 8번의 측면 과부하';

  @override
  String get trainingSketchTemplateWingCombinationMethod =>
      '윙어가 안쪽을 묶고 오버랩 또는 언더랩으로 컷백';

  @override
  String get trainingSketchTemplateTransitionAttackLabel => '탈취 후 6초 역습';

  @override
  String get trainingSketchTemplateTransitionAttackDescription =>
      '첫 패스, 깊이 침투, 측면 운반';

  @override
  String get trainingSketchTemplateTransitionAttackMethod =>
      '탈취 직후 첫 전진 패스로 수비가 정렬되기 전에 마무리';

  @override
  String get trainingSketchTemplateSwitchPlayLabel => '반대 전환';

  @override
  String get trainingSketchTemplateSwitchPlayDescription => '밀집 유도 후 반대 윙으로 전환';

  @override
  String get trainingSketchTemplateSwitchPlayMethod =>
      '한쪽으로 압박을 모은 뒤 6번과 센터백을 거쳐 반대로 전개';

  @override
  String get trainingSketchTemplateDefensiveShiftLabel => '수비 라인 이동';

  @override
  String get trainingSketchTemplateDefensiveShiftDescription =>
      '볼 이동에 맞춘 라인 슬라이드와 커버';

  @override
  String get trainingSketchTemplateDefensiveShiftMethod =>
      '공이 반대로 이동할 때 4백과 6번이 간격을 유지하며 이동';

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
  String get trainingSketchTemplateBallMasteryLabel => '볼 마스터리 슬라럼';

  @override
  String get trainingSketchTemplateBallMasteryDescription =>
      '콘 사이 드리블, 방향 전환, 마무리';

  @override
  String get trainingSketchTemplateBallMasteryMethod =>
      '공을 몸 앞에 두고 콘마다 속도를 바꾼 뒤 목표로 마무리';

  @override
  String get trainingSketchTemplateFirstTouchFinishLabel => '퍼스트 터치 후 마무리';

  @override
  String get trainingSketchTemplateFirstTouchFinishDescription =>
      '패스 수신, 압박 회피 턴, 슈팅';

  @override
  String get trainingSketchTemplateFirstTouchFinishMethod =>
      '하프턴으로 받고 첫 터치를 공간으로 가져간 뒤 빠르게 마무리';

  @override
  String get trainingSketchTemplateOneVOneLabel => '1대1 돌파 마무리';

  @override
  String get trainingSketchTemplateOneVOneDescription => '속도 변화로 수비수를 제치기';

  @override
  String get trainingSketchTemplateOneVOneMethod =>
      '수비수를 끌어낸 뒤 어깨 쪽으로 가속해 다음 터치에 마무리';

  @override
  String get trainingSketchTemplateTwoVOneLabel => '2대1 오버랩 마무리';

  @override
  String get trainingSketchTemplateTwoVOneDescription => '패스, 오버랩, 재수신, 마무리';

  @override
  String get trainingSketchTemplateTwoVOneMethod =>
      '패스가 가는 동안 움직여 수비수를 끌고, 리턴 패스로 마무리 공간에 진입';

  @override
  String get trainingSketchTemplateThirdManLabel => '3번째 선수 침투';

  @override
  String get trainingSketchTemplateThirdManDescription => '패스, 원터치 연결, 라인 뒤 침투';

  @override
  String get trainingSketchTemplateThirdManMethod =>
      '연결 선수가 원터치로 공을 떨구고 세 번째 선수를 공간으로 보냄';

  @override
  String get trainingSketchTemplateCoordinationFinishLabel => '코디네이션 서킷 마무리';

  @override
  String get trainingSketchTemplateCoordinationFinishDescription =>
      '사다리, 뜀틀, 턴, 볼 마무리';

  @override
  String get trainingSketchTemplateCoordinationFinishMethod =>
      '사다리와 뜀틀에서 자세를 유지하고, 타이트하게 돈 뒤 컨트롤하며 마무리';

  @override
  String get trainingSketchTemplateBaseballDoublePlayLabel => '병살 연결';

  @override
  String get trainingSketchTemplateBaseballDoublePlayDescription =>
      '포구, 2루 송구, 피벗, 1루 송구';

  @override
  String get trainingSketchTemplateBaseballDoublePlayMethod =>
      '땅볼을 안정적으로 잡고 정확히 연결한 뒤 빠르게 피벗하여 1루로 송구';

  @override
  String get trainingSketchTemplateBaseballBaseRunningLabel => '장타 주루';

  @override
  String get trainingSketchTemplateBaseballBaseRunningDescription =>
      '타구 판단 후 전체 베이스 주루';

  @override
  String get trainingSketchTemplateBaseballBaseRunningMethod =>
      '강하게 출발해 베이스를 안정적으로 돌고 중계 플레이를 보며 다음 베이스 판단';

  @override
  String get trainingSketchTemplateBasketballTransitionLabel => '3레인 트랜지션';

  @override
  String get trainingSketchTemplateBasketballTransitionDescription =>
      '두 번의 전진 패스 후 림 마무리';

  @override
  String get trainingSketchTemplateBasketballTransitionMethod =>
      '각 레인을 채우고 압박 전에 전진 패스해 속도감 있게 마무리';

  @override
  String get trainingSketchTemplateBasketballPickRollLabel => '픽앤롤 킥아웃';

  @override
  String get trainingSketchTemplateBasketballPickRollDescription =>
      '스크린, 드라이브, 킥아웃, 슈팅';

  @override
  String get trainingSketchTemplateBasketballPickRollMethod =>
      '균형 있게 스크린을 세우고 틈을 공격한 뒤 열린 슈터를 찾기';

  @override
  String get trainingSketchTemplateTennisReturnRecoverLabel => '리턴 후 리커버리';

  @override
  String get trainingSketchTemplateTennisReturnRecoverDescription =>
      '크로스 리턴 후 다음 공을 위한 복귀';

  @override
  String get trainingSketchTemplateTennisReturnRecoverMethod =>
      '리턴 위치로 이동해 크로스로 보내고 중앙을 거쳐 다음 공에 대비';

  @override
  String get trainingSketchTemplateTennisApproachVolleyLabel => '어프로치 앤 발리';

  @override
  String get trainingSketchTemplateTennisApproachVolleyDescription =>
      '코트 안으로 접근해 네트에서 마무리';

  @override
  String get trainingSketchTemplateTennisApproachVolleyMethod =>
      '공간으로 어프로치를 보내고 균형 있게 접근한 뒤 발리를 앞으로 처리';

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
  String get challengeListTitle => '활성 챌린지';

  @override
  String challengeListBody(int count) {
    return '$count개의 챌린지가 준비 또는 진행 중이에요. 시작 전 챌린지와 오늘 라운드를 함께 모았어요.';
  }

  @override
  String get challengeCreateTitle => '챌린지 만들기';

  @override
  String get challengeCreateAction => '챌린지 만들기';

  @override
  String get challengeDetailTitle => '챌린지 상세';

  @override
  String get challengeDetailAction => '상세';

  @override
  String get challengeEditTitle => '챌린지 수정';

  @override
  String get challengeEditAction => '수정';

  @override
  String get challengeEditBody => '시작 전 챌린지의 기간, 진행 간격, 미션 구성을 조정할 수 있어요.';

  @override
  String get challengeUpdateAction => '수정 저장';

  @override
  String get challengeUpdateSnack => '챌린지를 수정했어요.';

  @override
  String get challengeEditUnavailableSnack => '이미 기록이 시작된 챌린지는 수정할 수 없어요.';

  @override
  String get challengeDeletePendingAction => '삭제';

  @override
  String get challengeDeletePendingTitle => '챌린지 삭제';

  @override
  String get challengeDeletePendingBody => '아직 시작하지 않은 챌린지예요. 이 챌린지를 삭제할까요?';

  @override
  String get challengeDeletePendingConfirm => '삭제';

  @override
  String get challengeDeletePendingSnack => '챌린지를 삭제했어요.';

  @override
  String get challengeDeletePendingUnavailableSnack =>
      '이미 기록이 시작된 챌린지는 삭제할 수 없어요.';

  @override
  String get challengeStartHeroTitle => '린지의 챌린지 모드';

  @override
  String get challengeStartHeroBody =>
      '기간과 미션별 훈련량을 고른 뒤 챌린지를 준비해요. 준비가 끝나면 선수 모드에서 오늘부터 시작할 수 있어요.';

  @override
  String get challengeLatestComplete => '최근 챌린지 완료';

  @override
  String get challengeSelectTitle => '챌린지 선택';

  @override
  String challengeActiveCardTitle(Object title) {
    return '$title 진행 중';
  }

  @override
  String get challengeCreateAnotherTitle => '새 챌린지 추가';

  @override
  String get challengeDurationSelectTitle => '1. 기간 선택';

  @override
  String get challengeCadenceSelectTitle => '진행 간격';

  @override
  String get challengeCadenceDaily => '매일';

  @override
  String get challengeCadenceEveryTwoDays => '이틀에 한 번';

  @override
  String get challengeCadenceWeekly => '일주일에 한 번';

  @override
  String challengeCadenceEveryNDays(int days) {
    return '$days일에 한 번';
  }

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
  String get challengeRewardGiftSectionTitle => '선물 보상';

  @override
  String get challengeRewardGiftSectionSubtitle =>
      '챌린지를 끝까지 완주했을 때 줄 선물을 적어두세요.';

  @override
  String get challengeRewardGiftInputLabel => '완주 선물';

  @override
  String get challengeRewardGiftInputHint => '예: 새 축구공';

  @override
  String challengeRewardGiftPill(Object gift) {
    return '선물: $gift';
  }

  @override
  String get challengeRewardGiftPromisedLabel => '완주 선물';

  @override
  String challengeRewardGiftPromisedBody(Object gift) {
    return '완주하면 $gift 선물이 기다려요.';
  }

  @override
  String get challengeGiftReceiveTitle => '린지가 선물을 가져왔어요!';

  @override
  String challengeGiftReceiveBody(Object gift) {
    return '$gift 선물을 받을 시간이에요. 끝까지 해낸 약속을 린지가 축하하고 있어요.';
  }

  @override
  String get challengeGiftReceiveAction => '선물 받았어요';

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
  String get challengeStartReadyTitle => '3. 준비 저장';

  @override
  String get challengePrepareAction => '챌린지 준비';

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
  String get challengeReadyBadge => '시작 전';

  @override
  String get challengePendingBadge => '진행 중';

  @override
  String get challengeReadyPeriodLabel => '시작하면 오늘부터 일정이 잡혀요.';

  @override
  String challengeReadyCardTitle(Object title) {
    return '$title 준비 완료';
  }

  @override
  String get challengeReadyPlayerBody =>
      '준비가 됐으면 지금 시작하세요. 시작한 날부터 라운드 일정과 미션 기록이 열립니다.';

  @override
  String get challengeReadyParentBody =>
      '선수가 준비되면 선수 모드에서 시작할 수 있어요. 시작 전에는 수정하거나 삭제할 수 있습니다.';

  @override
  String get challengeReadyStartAction => '지금 시작';

  @override
  String challengeCompletedSummary(Object title) {
    return '$title 완료';
  }

  @override
  String get challengeRoundDateToday => '오늘';

  @override
  String challengePrepareSnack(Object title) {
    return '$title를 준비했어요.';
  }

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

  @override
  String get matchCompetitionScheduleTab => '일정·결과';

  @override
  String get matchCompetitionStandingsTab => '순위';

  @override
  String get matchCompetitionBracketTab => '대진표';

  @override
  String get matchCompetitionTeamsViewTab => '참가 팀';

  @override
  String get matchCompetitionFixtureManageAction => '경기 관리';

  @override
  String get matchCompetitionFixtureEditorTitle => '경기 관리';

  @override
  String get matchCompetitionFixtureScheduleSection => '경기 일정';

  @override
  String get matchCompetitionFixtureResultSection => '경기 결과';

  @override
  String get matchCompetitionFixtureResultEnabled => '결과 입력';

  @override
  String get matchCompetitionFixtureResultUnavailable =>
      '참가 팀이 확정되면 결과를 입력할 수 있어요.';

  @override
  String get matchCompetitionFixtureStatusScheduled => '예정';

  @override
  String get matchCompetitionFixtureStatusPostponed => '연기';

  @override
  String get matchCompetitionFixtureStatusCancelled => '취소';

  @override
  String get matchCompetitionFixtureStatusCompleted => '완료';

  @override
  String get matchCompetitionFixtureDateAction => '날짜 선택';

  @override
  String get matchCompetitionFixtureTimeAction => '시간 선택';

  @override
  String get matchCompetitionFixtureClearSchedule => '일정 지우기';

  @override
  String get matchCompetitionFixtureVenueDefault => '대회 기본 장소';

  @override
  String get matchCompetitionFixtureVenueUnset => '장소 미정';

  @override
  String get matchCompetitionFixturePenaltyTitle => '승부차기';

  @override
  String get matchCompetitionFixturePenaltyRequired =>
      '토너먼트 동점 경기는 승부차기 결과를 입력하세요.';

  @override
  String get matchCompetitionFixtureSave => '경기 저장';

  @override
  String get matchCompetitionFixtureSavedFeedback => '경기 일정과 결과를 저장했어요.';

  @override
  String get matchCompetitionFixtureOpenTeamRecord => '우리 팀 기록 열기';

  @override
  String get matchCompetitionFixtureUnscheduled => '일정 미정';

  @override
  String get matchCompetitionFixtureSchedulePlanAction => '일정 편성';

  @override
  String get matchCompetitionFixtureSchedulePlanTitle => '대회 일정 편성';

  @override
  String get matchCompetitionFixtureScheduleStartLabel => '첫 경기';

  @override
  String get matchCompetitionFixtureScheduleIntervalLabel => '라운드 간격';

  @override
  String matchCompetitionFixtureScheduleIntervalDays(int days) {
    return '$days일';
  }

  @override
  String get matchCompetitionFixtureScheduleApply => '일정 적용';

  @override
  String matchCompetitionFixtureScheduleCount(int scheduled, int total) {
    return '$scheduled/$total 일정';
  }

  @override
  String get matchCompetitionFixtureDecreaseScore => '점수 감소';

  @override
  String get matchCompetitionFixtureIncreaseScore => '점수 증가';

  @override
  String get matchCompetitionAutoSavedFeedback => '대회 정보를 자동 저장했어요.';

  @override
  String get matchCompetitionStandingsRankColumn => '순위';

  @override
  String get matchCompetitionStandingsTeamColumn => '팀';

  @override
  String get matchCompetitionStandingsPlayedColumn => '경기';

  @override
  String get matchCompetitionStandingsRecordColumn => '승·무·패';

  @override
  String get matchCompetitionStandingsGoalDifferenceColumn => '득실';

  @override
  String get matchCompetitionStandingsPointsColumn => '승점';

  @override
  String get matchCompetitionParticipantOrderColumn => '순번';

  @override
  String get matchCompetitionParticipantTeamColumn => '참가 팀';

  @override
  String get matchCompetitionLeagueTieBreakerLabel => '동률 순위 기준';

  @override
  String get matchCompetitionTieBreakerGoalDifference => '승점, 득실차, 다득점';

  @override
  String get matchCompetitionTieBreakerWins => '승점, 승리 수, 득실차';

  @override
  String get matchCompetitionTieBreakerGoalsFor => '승점, 다득점, 득실차';

  @override
  String get matchCompetitionRebuildDialogTitle => '일정과 대진을 다시 편성할까요?';

  @override
  String matchCompetitionRebuildDialogBody(int fixtures, int results) {
    return '변경된 구성에 맞춰 경기 $fixtures개를 다시 편성합니다. 기록된 결과 $results개가 초기화될 수 있어요.';
  }

  @override
  String get matchCompetitionRebuildConfirm => '다시 편성';

  @override
  String get matchCompetitionRebuildFeedback => '일정과 대진을 다시 편성했어요.';

  @override
  String get matchCompetitionRebuildUndoneFeedback => '이전 일정과 대진으로 되돌렸어요.';

  @override
  String get matchCompetitionScheduleCalendarAction => '대회 캘린더';

  @override
  String get matchCompetitionScheduleCalendarTitle => '대회 캘린더';

  @override
  String get matchCompetitionScheduleCalendarEmptyDay => '이 날짜에는 경기가 없어요.';

  @override
  String get matchCompetitionScheduleUnscheduledLane => '일정 미정 경기';

  @override
  String matchCompetitionScheduleUnscheduledCount(int count) {
    return '일정 미정 $count경기';
  }

  @override
  String matchCompetitionScheduleIssuesCount(int count) {
    return '확인이 필요한 항목 $count건';
  }

  @override
  String get matchCompetitionScheduleIssueVenueOverlap => '같은 장소의 경기 일정이 겹쳐요';

  @override
  String get matchCompetitionScheduleIssueTeamOverlap => '같은 날에 같은 팀 경기가 겹쳐요';

  @override
  String get matchCompetitionScheduleIssueShortRest => '경기 사이 휴식일이 부족해요';

  @override
  String get matchCompetitionQuickResultAction => '빠른 결과 입력';

  @override
  String get matchCompetitionQuickResultSave => '결과 저장';

  @override
  String get matchCompetitionQuickResultCancel => '결과 입력 닫기';

  @override
  String get matchCompetitionProgressRemaining => '남은 경기';

  @override
  String get matchCompetitionProgressNextMatches => '다음 경기';

  @override
  String get matchCompetitionProgressChampion => '우승 확정';

  @override
  String get matchCompetitionProgressLeader => '현재 1위';

  @override
  String get matchCompetitionProgressAdvanced => '진출 확정';

  @override
  String get runningCoachCaptureContextTitle => '비교 기준 설정';

  @override
  String get runningCoachCaptureContextBody =>
      '같은 조건의 이전 영상과만 비교하려면 이번 러닝 강도와 환경을 선택하세요. 선택하지 않아도 분석은 할 수 있어요.';

  @override
  String get runningCoachCaptureContextEffortLabel => '러닝 강도';

  @override
  String get runningCoachCaptureContextSurfaceLabel => '환경';

  @override
  String get runningCoachCaptureEffortEasy => '가벼움';

  @override
  String get runningCoachCaptureEffortSteady => '보통';

  @override
  String get runningCoachCaptureEffortFast => '빠름';

  @override
  String get runningCoachCaptureSurfaceTreadmill => '러닝머신';

  @override
  String get runningCoachCaptureSurfaceTrackOrRoad => '트랙 · 도로';

  @override
  String get runningCoachGaitTitle => '걸음별 측정';

  @override
  String get runningCoachGaitBody => '검증된 접지 프레임에서만 걸음·좌우·동작 단계를 나누어 다시 계산했어요.';

  @override
  String get runningCoachRhythmTitle => '이번 영상의 리듬 수치';

  @override
  String get runningCoachRhythmBody =>
      '검증된 접지 시점으로 케이던스와 걸음 간 시간을 계산했어요. 정확한 접지 시간은 아니에요.';

  @override
  String get runningCoachRhythmContactsLabel => '검증된 접지';

  @override
  String get runningCoachRhythmBilateralUnavailable =>
      '좌우 리듬 비교에는 왼발과 오른발이 구분된 접지 장면이 더 필요해요.';

  @override
  String get runningCoachRhythmEvidenceLimited => '검증된 접지가 적어 리듬 수치는 참고용이에요.';

  @override
  String get runningCoachGaitDetailsTitle => '걸음별 자세 수치와 측정 기준';

  @override
  String get runningCoachGaitDetailsCollapsedBody =>
      '발 위치·무릎·상체·팔의 범위와 좌우 차이는 전신 좌표가 접지 장면과 짝지어지면 보여 드려요.';

  @override
  String get runningCoachGaitUnavailableTitle => '걸음별 수치를 아직 확정할 수 없어요';

  @override
  String get runningCoachGaitUnavailableBody =>
      '검증된 접지 프레임과 자세 프레임의 짝이 부족해요. 전신과 양발이 보이게 다시 촬영해 주세요.';

  @override
  String get runningCoachGaitReliableStepsLabel => '신뢰 가능한 걸음';

  @override
  String get runningCoachGaitCadenceLabel => '케이던스 (spm)';

  @override
  String get runningCoachGaitStepTimeLabel => '걸음 시간 (ms)';

  @override
  String get runningCoachGaitFootReachLabel => '착지 발 위치 (몸통 대비)';

  @override
  String get runningCoachGaitKneeAtContactLabel => '접지 무릎 각도 (°)';

  @override
  String get runningCoachGaitMinimumKneeLabel => '접지 후 최저 무릎 각도 (°)';

  @override
  String get runningCoachGaitForwardLeanLabel => '접지 상체 기울기 (°)';

  @override
  String get runningCoachGaitElbowLabel => '접지 팔꿈치 각도 (°)';

  @override
  String get runningCoachGaitLeftRightTimingLabel => '좌우 걸음 시간 차이 (%)';

  @override
  String get runningCoachGaitLeftRightFootLabel => '좌우 착지 발 위치 차이';

  @override
  String get runningCoachGaitLeftRightKneeLabel => '좌우 접지 무릎 차이 (°)';

  @override
  String runningCoachGaitRangeValue(
      String median, String minimum, String maximum) {
    return '$median · 범위 $minimum–$maximum';
  }

  @override
  String get runningCoachGaitStepsTitle => '검증된 걸음';

  @override
  String runningCoachGaitStepNumber(int number) {
    return '$number번째 걸음';
  }

  @override
  String get runningCoachGaitStepLeft => '왼발';

  @override
  String get runningCoachGaitStepRight => '오른발';

  @override
  String get runningCoachGaitInitialContactLabel => '첫 접지';

  @override
  String get runningCoachGaitMaximumKneeFlexionLabel => '최대 무릎 굽힘';

  @override
  String get runningCoachGaitPhaseUnavailable => '이 단계는 측정되지 않음';

  @override
  String get runningCoachGaitEvidenceLimited =>
      '안정적으로 읽힌 걸음이 3개 미만이라 이 수치는 참고용입니다.';

  @override
  String get runningCoachGaitLimitationsTitle => '이 영상으로 측정할 수 없는 것';

  @override
  String get runningCoachGaitLimitationsBody =>
      '단일 측면 영상만으로는 발 롤링·회내, 지면 반력, 정확한 접지 시간, 부상 위험을 측정하거나 판정하지 않습니다.';

  @override
  String get runningCoachJudgmentWithheldTitle => '판정 보류';

  @override
  String get runningCoachJudgmentWithheldBody =>
      '근거가 부족해 좋음/개선 필요와 훈련 처방을 표시하지 않았어요. 영상을 다시 촬영해 주세요.';

  @override
  String get runningCoachTrendTitle => '같은 조건 추세';

  @override
  String runningCoachTrendBody(Object effort, Object surface, int count) {
    return '비교 조건: $surface에서 $effort. 같은 점수 버전의 최근 검증 세션 $count개를 사용합니다.';
  }

  @override
  String get runningCoachTrendInsufficientBaselineTitle => '검증 기준선 부족';

  @override
  String get runningCoachTrendInsufficientBaselineBody =>
      '변화를 보여 주려면 같은 점수 버전의 검증된 같은 조건 세션이 최소 2개 필요해요.';

  @override
  String runningCoachTrendMetricValue(Object current, Object delta) {
    return '$current · Δ $delta';
  }

  @override
  String get runningCoachComparisonTitle => '같은 조건 비교';

  @override
  String runningCoachComparisonBody(String effort, String surface) {
    return '이번 기록은 $effort · $surface 조건으로 저장됩니다. 같은 조건의 이전 영상과만 비교하세요.';
  }

  @override
  String get runningCoachComparisonNoBaselineTitle => '같은 조건의 이전 기록이 아직 없어요';

  @override
  String get runningCoachComparisonNoBaselineBody =>
      '같은 러닝 강도와 환경으로 한 번 더 촬영하면 변화를 비교할 수 있어요.';

  @override
  String get runningCoachComparisonPreviousLabel => '이전';

  @override
  String get runningCoachComparisonCurrentLabel => '현재';

  @override
  String get runningCoachComparisonChangeLabel => '이전 → 현재';

  @override
  String runningCoachComparisonChangeValue(String previous, String current) {
    return '$previous → $current';
  }

  @override
  String get runningCoachComparisonSameConditionRetake => '같은 조건으로 다시 촬영';

  @override
  String get runningCoachDefaultRunner => '나';

  @override
  String runningCoachRunnerTarget(String name) {
    return '분석 대상: $name';
  }

  @override
  String get runningCoachManageRunners => '러너 관리';

  @override
  String get runningCoachSelectRunnerTitle => '누구를 분석할까요?';

  @override
  String get runningCoachAddRunner => '러너 추가';

  @override
  String get runningCoachRenameRunner => '이름 변경';

  @override
  String get runningCoachArchiveRunner => '보관';

  @override
  String get runningCoachRunnerNameLabel => '러너 이름';

  @override
  String get runningCoachManageRunner => '러너 관리';

  @override
  String get runningCoachAnalysisSteps => '러너 찾기 → 움직임 분석 → 결과 만들기';

  @override
  String get runningCoachAnalysisStageJointLanding => '관절·착지 분석';

  @override
  String get runningCoachAnalysisStageSavingResult => '결과 및 근거 저장';

  @override
  String runningCoachAnalysisElapsed(Object elapsed) {
    return '경과 $elapsed';
  }

  @override
  String get runningCoachCaptureWarningAnalysisLimited =>
      '그대로 촬영할 수 있지만 구도가 흐리면 분석이 추정되거나 제한될 수 있어요.';

  @override
  String get runningCoachPreviewCheckFullBody => '전신';

  @override
  String get runningCoachPreviewCheckSide => '측면';

  @override
  String get runningCoachPreviewCheckClarity => '선명한 거리';

  @override
  String get runningCoachTodayOneThingTitle => '오늘은 이것만 바꿔보세요';

  @override
  String get runningCoachStatusEstimatedShort => '추정';

  @override
  String get runningCoachViewEvidenceSlowly => '근거 느리게 보기';

  @override
  String get runningCoachTenSecondDrill => '10초 연습';

  @override
  String get runningCoachFiveMovementsTitle => '6가지 체크';

  @override
  String get runningCoachStatusImproveShort => '개선';

  @override
  String get runningCoachStatusUnavailableShort => '측정 안 됨';

  @override
  String get runningCoachFullAnalysisAction => '전체 분석 보기';

  @override
  String get runningCoachGoodBandLabel => '좋은 범위';

  @override
  String get runningCoachNextCueLabel => '다음 큐';

  @override
  String get runningCoachRawMeasurementDetails => '측정값 자세히 보기';

  @override
  String get runningCoachConfidenceShortLabel => '신뢰도';

  @override
  String get runningCoachMeasurementMethodLabel => '측정 방식';

  @override
  String get runningCoachGaitRhythmTitle => '리듬과 타이밍';

  @override
  String get runningCoachReportDetailsTitle => '움직임 상세';

  @override
  String get runningCoachGaitFineTitle => '세부 보행';

  @override
  String get runningCoachTodayLabel => '오늘';

  @override
  String get runningCoachAnalysisQualityBadgeStrong => '안정적 분석';

  @override
  String get runningCoachAnalysisQualityBadgeLimited => '제한적 분석';

  @override
  String runningCoachPreviousScoreDelta(int delta) {
    return '이전 대비 $delta';
  }

  @override
  String runningCoachHistoryConfirmedScore(int score) {
    return '확정 $score';
  }

  @override
  String runningCoachHistoryEstimatedScore(int score) {
    return '추정 $score';
  }

  @override
  String get runningCoachHistoryScoreUnavailable => '점수 보류';

  @override
  String get runningCoachMultiplePersonLabel => '여러 사람 감지';

  @override
  String get runningCoachTargetIdentityUnstableLabel => '러너 추적 변경';

  @override
  String get runningCoachMultiplePersonReason =>
      '영상에 여러 사람이 있을 수 있어 다른 사람을 채점하지 않도록 점수를 보류했어요.';

  @override
  String get runningCoachTargetIdentityUnstableReason =>
      '러너 추적이 갑자기 바뀌어 서로 다른 사람의 기록이 섞이지 않도록 점수를 보류했어요.';

  @override
  String get runningCoachSingleRunnerRetake =>
      '한 번에 한 명만 촬영하고 다른 사람은 화면 밖에 있도록 해주세요.';

  @override
  String runningCoachHistoryTrendSummary(int best, int delta) {
    return '확정 최고 $best점 · 최근 변화 $delta점';
  }
}
