// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Taeo\'s Note';

  @override
  String get tabHome => 'Home';

  @override
  String get tabLogs => 'Logs';

  @override
  String get tabCalendar => 'Calendar';

  @override
  String get tabStats => 'Stats';

  @override
  String get tabDiary => 'Diary';

  @override
  String get tabNews => 'News';

  @override
  String tabGuideTitle(Object tabName) {
    return '$tabName guide';
  }

  @override
  String get welcomeGuideTitle => 'Log today, and move stronger tomorrow.';

  @override
  String get welcomeGuideIntro =>
      'Any sport works. One short note can make the next practice easier. Start now; you can do this.';

  @override
  String get welcomeGuidePrimaryAction => 'Start logging';

  @override
  String get welcomeGuideSectionFlow => 'What to do';

  @override
  String get welcomeGuideNextTabHint =>
      'Swipe through three cards. Then log one thing right away.';

  @override
  String get welcomeGuidePreviewLabel => 'Action to choose now';

  @override
  String get welcomeGuideCoachMarkLabel => 'Tap this';

  @override
  String get welcomeSlideGemTitle => 'Small logs become real confidence.';

  @override
  String get welcomeSlideGemBody =>
      'Praise what went well, and turn the hard part into the next challenge. Each note helps you improve.';

  @override
  String get welcomeSlideFlameTitle => 'Do not stop on a hard day.';

  @override
  String get welcomeSlideFlameBody =>
      'One small action is enough. Log it, restart, and take one more step tomorrow.';

  @override
  String get startupSportTitle => 'Choose your sport first';

  @override
  String get startupSportSubtitle =>
      'Records, goals, stats, and news start around the sport you choose. You can change it later in Settings.';

  @override
  String get startupSportAction => 'Start with this sport';

  @override
  String get startupLoadingTitle => 'Getting the app ready';

  @override
  String get startupLoadingBody =>
      'Loading your records and settings. Please wait a moment.';

  @override
  String get startupErrorTitle => 'The app could not start';

  @override
  String get startupErrorBody =>
      'Something went wrong while loading the initial data. If retry keeps stopping here, fully close the app and open it again.';

  @override
  String get startupErrorDetailsLabel => 'Error details';

  @override
  String get startupErrorStepLabel => 'Step';

  @override
  String get startupErrorMessageLabel => 'Message';

  @override
  String get startupRetryAction => 'Retry';

  @override
  String get startupSportFootballDescription =>
      'Start with football training, matches, sketches, and news.';

  @override
  String get startupSportBaseballDescription =>
      'Track throwing, batting, fielding, and conditioning for baseball.';

  @override
  String get startupSportBasketballDescription =>
      'Log shooting, dribbling, game flow, and conditioning for basketball.';

  @override
  String get startupSportTennisDescription =>
      'Track strokes, serves, rallies, and support training for tennis.';

  @override
  String tabGuideCoachMarkStep(int current, int total) {
    return 'Step $current of $total';
  }

  @override
  String get tabGuideCoachMarkSkip => 'Skip';

  @override
  String get tabGuideCoachMarkBack => 'Back';

  @override
  String get tabGuideCoachMarkNext => 'Next';

  @override
  String get tabGuideCoachMarkDone => 'Done';

  @override
  String get tabGuideCoachMarkTry => 'Try this';

  @override
  String get parentWelcomeGuideTitle => 'Parent Mode Guide';

  @override
  String get parentWelcomeGuideIntro =>
      'Parent mode is for reviewing player records and leaving feedback on existing training logs.';

  @override
  String get parentWelcomeGuideStepLogs =>
      'Open the Logs tab first to review records saved by the player.';

  @override
  String get parentWelcomeGuideStepFeedback =>
      'Leave praise and next-time notes as feedback inside an existing record.';

  @override
  String get parentWelcomeGuideStepSync =>
      'Connect the Google Drive account that holds the player backup to keep shared data in sync.';

  @override
  String get guideActionToday => 'Today';

  @override
  String get guideActionMeal => 'Meals';

  @override
  String get guideActionCardList => 'Cards/List';

  @override
  String get guideActionSelectDate => 'Select date';

  @override
  String get guideActionPlus => '+';

  @override
  String get guideActionPeriod => 'Period';

  @override
  String get guideActionBenchmark => 'Average';

  @override
  String get guideActionWeakPoint => 'Focus';

  @override
  String get guideActionOpenToday => 'Today diary';

  @override
  String get guideActionRecordSticker => 'Stickers';

  @override
  String get guideActionSaveDiary => 'Save diary';

  @override
  String get welcomeHomeOverview =>
      'Start on Home when you want the app to decide the next useful action.';

  @override
  String get welcomeHomeStepToday =>
      'Check today\'s plan, quick actions, and the next unfinished routine first.';

  @override
  String get welcomeHomeStepMeal =>
      'Add meals from the meal button before the day ends so recovery records stay complete.';

  @override
  String get welcomeHomeStepStats =>
      'Open weekly stats from Home after logging to see whether the week is balanced.';

  @override
  String get welcomeLogsOverview =>
      'Use Logs when you are creating or reviewing the actual training note.';

  @override
  String get welcomeLogsStepAdd =>
      'Tap Add Entry, fill the session basics, then save the first note.';

  @override
  String get welcomeLogsStepBoard =>
      'Open Board inside the note when the drill shape or movement path matters.';

  @override
  String get welcomeLogsStepReview =>
      'Switch cards/list and filters to find recent records without reading every note.';

  @override
  String get welcomeCalendarOverview =>
      'Use Calendar when the date matters: plans, matches, meals, and notes stay together.';

  @override
  String get welcomeCalendarStepDate =>
      'Select a date first so every create action starts on the right day.';

  @override
  String get welcomeCalendarStepPlus =>
      'Use + to add a plan, match, training note, or meal on the selected date.';

  @override
  String get welcomeCalendarStepMeal =>
      'Add a meal record from the same date when recovery is part of the day.';

  @override
  String get welcomeStatsOverview =>
      'Use Stats after several records exist and you want the next training target.';

  @override
  String get welcomeStatsStepPeriod =>
      'Change the period to compare this week, last week, or a custom range.';

  @override
  String get welcomeStatsStepAverage =>
      'Switch between training and match tabs to review each record flow.';

  @override
  String get welcomeStatsStepFocus =>
      'Turn the weakest signal into the next plan or note goal.';

  @override
  String get welcomeChallengeOverview =>
      'Challenge mode turns daily rounds into pressure you cannot quietly ignore.';

  @override
  String get welcomeChallengeActionStart => 'Start challenge';

  @override
  String get welcomeChallengeStepStart =>
      'Choose a duration to create rounds you can follow from today.';

  @override
  String get welcomeChallengeActionMission => 'Enter mission';

  @override
  String get welcomeChallengeStepMission =>
      'Tap training, jump rope, lifting, or meal missions to open the matching record screen.';

  @override
  String get welcomeChallengeActionReward => 'XP reward';

  @override
  String get welcomeChallengeStepReward =>
      'Finished rounds stack XP. Miss them, and the gap is visible.';

  @override
  String get welcomeDiaryOverview =>
      'Use Diary to turn the day into one readable story with training, meals, and stickers.';

  @override
  String get welcomeDiaryStepToday =>
      'Open today\'s diary from Home or the Diary tab after recording.';

  @override
  String get welcomeDiaryStepSticker =>
      'Open a new diary and write today\'s title and story.';

  @override
  String get welcomeDiaryStepSave =>
      'Save the diary once the title, story, or sticker selection is ready.';

  @override
  String get logsQuickGuideTitle => 'Quick start guide';

  @override
  String get logsQuickGuideIntro =>
      'Create your first record in this order, then return here to review it.';

  @override
  String get newsFifaHubButton => 'FIFA';

  @override
  String get newsWorldCupButton => 'World Cup';

  @override
  String get newsKLeagueStandingsButton => 'League';

  @override
  String get newsMoreActionsTooltip => 'League view';

  @override
  String get newsMoreActionsTitle => 'More';

  @override
  String get newsRankingMoreButton => 'League view';

  @override
  String get newsLeagueStandingsAction => 'League';

  @override
  String get newsLeagueStandingsTitle => 'League View';

  @override
  String get newsKLeagueStandingsTitle => 'K League 1';

  @override
  String get newsPremierLeagueStandingsTitle => 'Premier League';

  @override
  String get newsChampionsLeagueStandingsTitle => 'Champions League';

  @override
  String get newsLaLigaStandingsTitle => 'LaLiga';

  @override
  String get newsBundesligaStandingsTitle => 'Bundesliga';

  @override
  String get newsMajorLeagueSoccerStandingsTitle => 'MLS';

  @override
  String get newsSaudiProLeagueStandingsTitle => 'Saudi Pro League';

  @override
  String newsLeagueStandingsUpdated(Object date) {
    return 'Updated $date';
  }

  @override
  String get newsLeagueStandingsOpenSource => 'Open source table';

  @override
  String get newsLeagueStandingsEmpty =>
      'No standings are available right now.';

  @override
  String get newsLeagueStandingsError => 'Could not load standings.';

  @override
  String get newsLeagueStandingsRetry => 'Retry';

  @override
  String get newsLeagueFixturesTitle => 'Fixture calendar';

  @override
  String get newsLeagueFixturesCalendarTitle => 'Fixture calendar';

  @override
  String get newsLeagueFixturesOpenCalendar => 'View as calendar';

  @override
  String get newsLeagueFixturesCalendarEmptyDay =>
      'No fixtures are placed on this date.';

  @override
  String get newsLeagueFixturesSubtitle =>
      'Open the calendar to review upcoming fixtures and recent results.';

  @override
  String get newsLeagueFixturesEmpty =>
      'No fixtures were found after checking a wider schedule window.';

  @override
  String get newsLeagueFixturesShowAll => 'Show all fixtures';

  @override
  String get newsLeagueFixturesCollapse => 'Collapse fixtures';

  @override
  String get newsLeagueFixturesSelectedTeamsOnly => 'Selected teams only';

  @override
  String get newsLeagueFixturesSelectedTeamsEmpty =>
      'No selected-team fixtures are available in this league schedule.';

  @override
  String newsLeagueFixturesEmptyReason(String league) {
    return '$league has no fixtures to show because the source fixture feed is empty or the current season schedule has not been published yet.';
  }

  @override
  String get newsLeagueFixtureScheduled => 'Fixture';

  @override
  String get newsLeagueFixtureLive => 'Live';

  @override
  String get newsLeagueFixtureFullTime => 'FT';

  @override
  String newsLeagueTeamDetailTitle(String team) {
    return '$team info';
  }

  @override
  String get newsLeagueTeamDetailRosterTitle => 'Roster';

  @override
  String get newsLeagueTeamDetailTacticsTitle => 'Tactics';

  @override
  String get newsLeagueTeamDetailFixturesTitle => 'Team fixtures';

  @override
  String get newsLeagueTeamDetailNoFixtures =>
      'No matches for this team were found in the loaded fixtures.';

  @override
  String get newsLeagueTeamDetailTacticsSummary =>
      'Use the current table plus goal data to read the team trend. Official tactics and roster details will appear here when the feed provides them.';

  @override
  String get newsLeagueTeamDetailSourceNote =>
      'Only information available from the official league feed is shown.';

  @override
  String get newsLeagueFavoriteTeamTitle => 'Favorite teams';

  @override
  String get newsLeagueFavoriteTeamManage => 'Select favorite teams';

  @override
  String get newsLeagueFavoriteTeamSubtitle =>
      'Choose favorite teams to receive alerts for their loaded fixtures.';

  @override
  String get newsLeagueFavoriteTeamSelect => 'Select teams';

  @override
  String get newsLeagueFavoriteTeamClear => 'Clear';

  @override
  String get newsLeagueFavoriteTeamNone => 'No team selected';

  @override
  String get newsLeagueFavoriteTeamSheetTitle => 'Select favorite teams';

  @override
  String get newsLeagueFavoriteTeamSaveAction => 'Save';

  @override
  String get newsLeagueFavoriteTeamLoadError => 'Could not load the team list.';

  @override
  String get newsLeagueFavoriteTeamEmpty => 'No teams are available.';

  @override
  String newsLeagueFavoriteTeamSelectedCount(int count) {
    return '$count team(s) selected';
  }

  @override
  String get newsLeagueFavoriteTeamSaved => 'Favorite teams saved.';

  @override
  String get newsLeagueFavoriteTeamNoUpcoming =>
      'No match alerts are scheduled.';

  @override
  String newsLeagueFavoriteTeamReminderCount(int count) {
    return '$count match alerts scheduled';
  }

  @override
  String newsLeagueFavoriteTeamNotificationBody(
      Object team, Object opponent, Object kickoff) {
    return '$team fixture alert: vs $opponent at $kickoff';
  }

  @override
  String get newsLeagueFixtureNotificationChannelName =>
      'League Fixture Alerts';

  @override
  String get newsLeagueFixtureNotificationChannelDescription =>
      'Fixture alerts for preferred league teams';

  @override
  String get notificationAppTitle => 'Taeo\'s Note';

  @override
  String get worldCupFixtureNotificationChannelName => 'World Cup Match Alerts';

  @override
  String get worldCupFixtureNotificationChannelDescription =>
      'Fixture alerts for selected World Cup countries';

  @override
  String worldCupFixtureNotificationBody(
      Object team, Object opponent, Object kickoff) {
    return '$team World Cup match: vs $opponent at $kickoff';
  }

  @override
  String get newsLeagueStandingsTeamColumn => 'Team';

  @override
  String get newsLeagueStandingsPlayedColumn => 'P';

  @override
  String get newsLeagueStandingsWinsColumn => 'W';

  @override
  String get newsLeagueStandingsDrawsColumn => 'D';

  @override
  String get newsLeagueStandingsLossesColumn => 'L';

  @override
  String get newsLeagueStandingsGoalDifferenceColumn => 'GD';

  @override
  String get newsLeagueStandingsPointsColumn => 'Pts';

  @override
  String get newsSearchAction => 'Search news';

  @override
  String get newsChannelsAction => 'Channels';

  @override
  String get newsShowAllNewsAction => 'Show all news';

  @override
  String get newsShowScrappedOnlyAction => 'Show scrapped only';

  @override
  String get newsViewedHistoryAction => 'Viewed news';

  @override
  String get newsViewedHistoryTitle => 'Viewed news';

  @override
  String get newsViewedHistoryEmpty => 'No viewed news yet.';

  @override
  String get newsTitleTranslateEnabledTooltip => 'Title translation on';

  @override
  String get newsTitleTranslateDisabledTooltip => 'Title translation off';

  @override
  String get newsTranslateAction => 'Translate';

  @override
  String get newsLoadFailedMessage =>
      'Failed to load news. Pull down to refresh.';

  @override
  String get newsNoChannelArticles => 'No news for selected channels.';

  @override
  String get newsNoScrappedArticles => 'No scrapped news yet.';

  @override
  String get newsNoResultsFound => 'No results found.';

  @override
  String get newsScrapTooltip => 'Scrap';

  @override
  String get newsRemoveScrapTooltip => 'Remove scrap';

  @override
  String get newsScrappedSnack => 'News scrapped.';

  @override
  String get newsScrapRemovedSnack => 'Scrap removed.';

  @override
  String get newsTranslationGuideSnack =>
      'Use the top-right menu on the article screen to translate the page.';

  @override
  String get newsSelectChannelsTitle => 'Select news channels';

  @override
  String get newsSelectAll => 'Select all';

  @override
  String get newsClearAll => 'Clear all';

  @override
  String get newsDomesticFeedsLabel => 'Korean feeds';

  @override
  String get newsInternationalFeedsLabel => 'International feeds';

  @override
  String get newsRegionAllLabel => 'All';

  @override
  String get newsRegionDomesticLabel => 'Korea';

  @override
  String get newsRegionInternationalLabel => 'World';

  @override
  String get newsNationalSnapshotTitle => 'National Team Snapshot';

  @override
  String get newsNationalSnapshotSubtitle =>
      'Korea Republic men\'s team summary from official pages';

  @override
  String get newsFifaRankingTitle => 'FIFA Ranking';

  @override
  String get newsRankingCurrentLabel => 'Current rank';

  @override
  String get newsRankingUpdatedLabel => 'Updated';

  @override
  String get newsRecentAMatchTitle => 'Recent A-matches';

  @override
  String get newsRecentAMatchEmpty => 'Recent A-match results were not found.';

  @override
  String get newsOpenOfficialSource => 'Open official page';

  @override
  String get newsOfficialSourceFifa => 'FIFA official';

  @override
  String get newsOfficialSourceKfa => 'KFA official';

  @override
  String get newsMatchResultWin => 'Win';

  @override
  String get newsMatchResultDraw => 'Draw';

  @override
  String get newsMatchResultLoss => 'Loss';

  @override
  String matchKickoffKoreaOnly(String time) {
    return 'Korea time $time';
  }

  @override
  String matchKickoffLocalAndKorea(String localTime, String koreaTime) {
    return '$localTime · Korea time $koreaTime';
  }

  @override
  String get worldCupTitle => 'World Cup View';

  @override
  String get worldCupInfoAction => 'Guide';

  @override
  String get worldCupShareTooltip => 'Share World Cup page';

  @override
  String worldCupShareMessage(String url) {
    return 'Follow the 2026 World Cup schedule, standings, and tournament bracket on Taeo Note.\n$url';
  }

  @override
  String get worldCupShareOpenedSnack => 'World Cup share is ready.';

  @override
  String get worldCupShareFailedSnack => 'Could not open World Cup sharing.';

  @override
  String get worldCupPdfAction => 'PDF';

  @override
  String get worldCupImageAction => 'Image';

  @override
  String get worldCupSourceShortAction => 'FIFA';

  @override
  String get worldCupHeroTitle => 'FIFA World Cup 2026';

  @override
  String get worldCupHeroSubtitle => 'Canada, Mexico, United States · 48 teams';

  @override
  String worldCupCountdownDays(int days) {
    return '$days days left';
  }

  @override
  String get worldCupCountdownToday => 'Opening day';

  @override
  String get worldCupCountdownStarted => 'Tournament underway';

  @override
  String get worldCupCountdownComplete => 'Tournament complete';

  @override
  String get worldCupScheduleTab => 'Schedule';

  @override
  String get worldCupStandingsTab => 'Groups';

  @override
  String get worldCupRankingsTab => 'Stats';

  @override
  String get worldCupTournamentTab => 'Tournament';

  @override
  String get worldCupOverviewTitle => 'Tournament overview';

  @override
  String get worldCupOverviewIntro =>
      'This World Cup is bigger than before: 48 countries, 12 groups, and 104 matches across Canada, Mexico, and the United States.';

  @override
  String get worldCupHostsLabel => 'Hosts';

  @override
  String get worldCupHostsValue => 'Canada · Mexico · United States';

  @override
  String get worldCupDatesLabel => 'Dates';

  @override
  String worldCupDateRange(String start, String end) {
    return '$start - $end';
  }

  @override
  String get worldCupFormatLabel => 'Format';

  @override
  String get worldCupFormatValue => '48 teams · 12 groups';

  @override
  String get worldCupMatchesLabel => 'Matches';

  @override
  String get worldCupMatchesValue => '104 fixtures across 16 host cities';

  @override
  String worldCupMatchesCountValue(int count) {
    return '$count fixtures across 16 host cities';
  }

  @override
  String get worldCupGuideFormatTitle => 'How this World Cup works';

  @override
  String get worldCupGuideFormatBullets =>
      '48 countries are split into 12 groups of 4.\nEach country plays 3 group matches.\nThe top 2 teams in every group move on, plus the 8 best third-place teams.\nAfter that, the Round of 32 begins and one loss means elimination.';

  @override
  String get worldCupGuideMatchRulesTitle => 'Match rules';

  @override
  String get worldCupGuideMatchRulesBullets =>
      'A normal match has two 45-minute halves.\nGroup matches can finish as a draw, so both teams may earn 1 point.\nIn knockout matches, a draw after 90 minutes goes to extra time, then penalties if still tied.\nA win is 3 points, a draw is 1 point, and a loss is 0 points in the group stage.';

  @override
  String get worldCupGuideTiebreakTitle => 'How ties are broken';

  @override
  String get worldCupGuideTiebreakBullets =>
      'Teams are ranked by points first.\nIf teams in the same group are tied, FIFA checks head-to-head points, head-to-head goal difference, and head-to-head goals.\nIf they are still tied, FIFA checks overall goal difference, overall goals, team conduct score, and then the latest FIFA ranking.\nThe 8 best third-place teams are compared by points, goal difference, goals scored, team conduct score, and FIFA ranking.';

  @override
  String get worldCupGuideRefereeTitle => 'Referees and helpers';

  @override
  String get worldCupGuideRefereeBullets =>
      'FIFA selected 52 referees, 88 assistant referees, and 30 video match officials for the tournament.\nOn the field, a referee leads the match with two assistant referees, a fourth official, and reserve help when appointed.\nAssistant referees help with offside, throw-ins, goal kicks, corner kicks, substitutions, and penalty-kick details.\nThe referee always makes the final decision.';

  @override
  String get worldCupGuideVarTitle => 'VAR and technology';

  @override
  String get worldCupGuideVarBullets =>
      'VAR means Video Assistant Referee.\nVAR checks big match-changing moments such as goal/no goal, penalty/no penalty, direct red card, and mistaken identity.\nThe referee can watch the screen for an on-field review, but the referee still makes the final call.\nGoal-line technology, advanced semi-automated offside support, and connected-ball technology help officials make faster factual decisions.';

  @override
  String get worldCupTeamSettingsTitle => 'My World Cup teams';

  @override
  String get worldCupSupportCountryLabel => 'Cheering country';

  @override
  String get worldCupInterestCountriesLabel => 'Interest countries';

  @override
  String get worldCupInterestCountriesEmpty =>
      'No interest countries selected yet.';

  @override
  String get worldCupEditInterestCountriesAction => 'Edit countries';

  @override
  String get worldCupClearInterestCountriesAction => 'Clear';

  @override
  String get worldCupSelectedCountriesOnly => 'Show selected countries only';

  @override
  String get worldCupHighlightedMatchesTitle => 'Selected-country fixtures';

  @override
  String get worldCupNoHighlightedMatches =>
      'Choose a cheering country or interest countries to highlight their fixtures.';

  @override
  String get worldCupCalendarTitle => 'Full fixture calendar';

  @override
  String worldCupDayMatchesTitle(String date, int count) {
    return '$date · $count fixtures';
  }

  @override
  String get worldCupNoMatchesOnDay => 'No fixtures on this day.';

  @override
  String worldCupMatchNumber(int number) {
    return 'M$number';
  }

  @override
  String get worldCupVersusShort => 'v';

  @override
  String get worldCupMatchScheduled => 'Scheduled';

  @override
  String get worldCupMatchLive => 'Live';

  @override
  String get worldCupMatchAwaitingUpdate => 'Awaiting result update';

  @override
  String get worldCupMatchAwaitingUpdateReason =>
      'The estimated final whistle has passed, but FIFA official results have not been reflected yet. Refresh or check the official page.';

  @override
  String get worldCupMatchResultFinal => 'Result';

  @override
  String worldCupFifaRankingCompactLabel(int rank) {
    return 'FIFA #$rank';
  }

  @override
  String get worldCupMatchDetailTitle => 'Match details';

  @override
  String get worldCupMatchComparisonTitle => 'Team comparison';

  @override
  String get worldCupMatchRecordsTitle => 'Match records';

  @override
  String get worldCupMatchRecordUnavailable =>
      'Live match records will appear as official data becomes available.';

  @override
  String get worldCupMatchDetailLoading => 'Loading FIFA match data...';

  @override
  String get worldCupMatchScorersTitle => 'Scorers';

  @override
  String get worldCupMatchLineupsTitle => 'Lineups';

  @override
  String get worldCupStartingPlayersLabel => 'Starting XI';

  @override
  String get worldCupBenchPlayersLabel => 'Bench';

  @override
  String get worldCupCaptainAbbreviation => '(C)';

  @override
  String get worldCupOfficialSourceNote =>
      'Scores, player lists, and match records are refreshed from FIFA data when this page opens.';

  @override
  String get worldCupMatchPossessionLabel => 'Possession';

  @override
  String worldCupMatchPossessionValue(int home, int away) {
    return '$home% · $away%';
  }

  @override
  String get worldCupMatchAttendanceLabel => 'Attendance';

  @override
  String get worldCupMatchTacticsLabel => 'Tactics';

  @override
  String worldCupPlayerProfileTitle(String player) {
    return '$player profile';
  }

  @override
  String worldCupClubInfoOpenTooltip(String club) {
    return 'Open $club info';
  }

  @override
  String worldCupClubHomepageOpenTooltip(String club) {
    return 'Open $club official website';
  }

  @override
  String worldCupClubInfoTitle(String club) {
    return '$club info';
  }

  @override
  String get worldCupPlayerProfilePlayerLabel => 'Player';

  @override
  String get worldCupPlayerProfileTeamLabel => 'National team';

  @override
  String get worldCupPlayerProfilePositionLabel => 'Position';

  @override
  String get worldCupPlayerProfileClubLabel => 'Club';

  @override
  String get worldCupPlayerClubPending => 'Club update pending';

  @override
  String get worldCupScorePending => '- : -';

  @override
  String worldCupScoreLine(int homeScore, int awayScore) {
    return '$homeScore : $awayScore';
  }

  @override
  String worldCupScorePenaltyLine(int homePenaltyScore, int awayPenaltyScore) {
    return 'PSO $homePenaltyScore : $awayPenaltyScore';
  }

  @override
  String get worldCupResultPendingTeam => 'Kickoff pending';

  @override
  String get worldCupResultWin => 'W';

  @override
  String get worldCupResultDraw => 'D';

  @override
  String get worldCupResultLoss => 'L';

  @override
  String get worldCupResultWinSummary => 'Win';

  @override
  String get worldCupResultDrawSummary => 'Draw';

  @override
  String get worldCupResultLossSummary => 'Loss';

  @override
  String worldCupGroupStageLabel(String group) {
    return 'Group $group';
  }

  @override
  String get worldCupRoundOf32Label => 'Round of 32';

  @override
  String get worldCupRoundOf16Label => 'Round of 16';

  @override
  String get worldCupQuarterFinalLabel => 'Quarter-final';

  @override
  String get worldCupSemiFinalLabel => 'Semi-final';

  @override
  String get worldCupThirdPlaceLabel => 'Third place';

  @override
  String get worldCupFinalLabel => 'Final';

  @override
  String get worldCupCountryAlgeria => 'Algeria';

  @override
  String get worldCupCountryArgentina => 'Argentina';

  @override
  String get worldCupCountryAustralia => 'Australia';

  @override
  String get worldCupCountryAustria => 'Austria';

  @override
  String get worldCupCountryBelgium => 'Belgium';

  @override
  String get worldCupCountryBosniaAndHerzegovina => 'Bosnia and Herzegovina';

  @override
  String get worldCupCountryBrazil => 'Brazil';

  @override
  String get worldCupCountryCanada => 'Canada';

  @override
  String get worldCupCountryCapeVerde => 'Cape Verde';

  @override
  String get worldCupCountryColombia => 'Colombia';

  @override
  String get worldCupCountryCongoDr => 'Congo DR';

  @override
  String get worldCupCountryCroatia => 'Croatia';

  @override
  String get worldCupCountryCuracao => 'Curacao';

  @override
  String get worldCupCountryCzechia => 'Czechia';

  @override
  String get worldCupCountryEcuador => 'Ecuador';

  @override
  String get worldCupCountryEgypt => 'Egypt';

  @override
  String get worldCupCountryEngland => 'England';

  @override
  String get worldCupCountryFrance => 'France';

  @override
  String get worldCupCountryGermany => 'Germany';

  @override
  String get worldCupCountryGhana => 'Ghana';

  @override
  String get worldCupCountryHaiti => 'Haiti';

  @override
  String get worldCupCountryIran => 'Iran';

  @override
  String get worldCupCountryIraq => 'Iraq';

  @override
  String get worldCupCountryIvoryCoast => 'Ivory Coast';

  @override
  String get worldCupCountryJapan => 'Japan';

  @override
  String get worldCupCountryJordan => 'Jordan';

  @override
  String get worldCupCountryKoreaRepublic => 'Korea Republic';

  @override
  String get worldCupCountryMexico => 'Mexico';

  @override
  String get worldCupCountryMorocco => 'Morocco';

  @override
  String get worldCupCountryNetherlands => 'Netherlands';

  @override
  String get worldCupCountryNewZealand => 'New Zealand';

  @override
  String get worldCupCountryNorway => 'Norway';

  @override
  String get worldCupCountryPanama => 'Panama';

  @override
  String get worldCupCountryParaguay => 'Paraguay';

  @override
  String get worldCupCountryPortugal => 'Portugal';

  @override
  String get worldCupCountryQatar => 'Qatar';

  @override
  String get worldCupCountrySaudiArabia => 'Saudi Arabia';

  @override
  String get worldCupCountryScotland => 'Scotland';

  @override
  String get worldCupCountrySenegal => 'Senegal';

  @override
  String get worldCupCountrySouthAfrica => 'South Africa';

  @override
  String get worldCupCountrySpain => 'Spain';

  @override
  String get worldCupCountrySweden => 'Sweden';

  @override
  String get worldCupCountrySwitzerland => 'Switzerland';

  @override
  String get worldCupCountryTunisia => 'Tunisia';

  @override
  String get worldCupCountryTurkiye => 'Turkiye';

  @override
  String get worldCupCountryUsa => 'USA';

  @override
  String get worldCupCountryUruguay => 'Uruguay';

  @override
  String get worldCupCountryUzbekistan => 'Uzbekistan';

  @override
  String get worldCupVenueAttDallas => 'AT&T Stadium, Dallas';

  @override
  String get worldCupVenueBcPlaceVancouver => 'BC Place, Vancouver';

  @override
  String get worldCupVenueBmoFieldToronto => 'BMO Field, Toronto';

  @override
  String get worldCupVenueEstadioAkronGuadalajara =>
      'Estadio Akron, Guadalajara';

  @override
  String get worldCupVenueEstadioAztecaMexicoCity =>
      'Estadio Azteca, Mexico City';

  @override
  String get worldCupVenueEstadioBbvaMonterrey => 'Estadio BBVA, Monterrey';

  @override
  String get worldCupVenueGehaArrowheadKansasCity =>
      'GEHA Field at Arrowhead Stadium, Kansas City';

  @override
  String get worldCupVenueGilletteBoston => 'Gillette Stadium, Boston';

  @override
  String get worldCupVenueHardRockMiami => 'Hard Rock Stadium, Miami';

  @override
  String get worldCupVenueLevisSanFranciscoBayArea =>
      'Levi\'s Stadium, San Francisco Bay Area';

  @override
  String get worldCupVenueLincolnFinancialPhiladelphia =>
      'Lincoln Financial Field, Philadelphia';

  @override
  String get worldCupVenueLumenSeattle => 'Lumen Field, Seattle';

  @override
  String get worldCupVenueMercedesBenzAtlanta =>
      'Mercedes-Benz Stadium, Atlanta';

  @override
  String get worldCupVenueMetLifeNewYorkNewJersey =>
      'MetLife Stadium, New York/New Jersey';

  @override
  String get worldCupVenueNrgHouston => 'NRG Stadium, Houston';

  @override
  String get worldCupVenueSofiLosAngeles => 'SoFi Stadium, Los Angeles';

  @override
  String worldCupKickoffLocal(String time) {
    return '$time local time';
  }

  @override
  String get worldCupSupportBadge => 'Cheering';

  @override
  String get worldCupInterestBadge => 'Interest';

  @override
  String get worldCupKoreaTitle => 'Korea Republic watch';

  @override
  String get worldCupKoreaBody =>
      'Korea Republic starts in Group A and opens against Czechia in Guadalajara.';

  @override
  String get worldCupKoreaGroupLabel => 'Group';

  @override
  String get worldCupKoreaGroup => 'Group A';

  @override
  String get worldCupKoreaOpenerLabel => 'Opener';

  @override
  String get worldCupKoreaOpener =>
      'Korea Republic v Czechia · Estadio Guadalajara';

  @override
  String get worldCupMilestonesTitle => 'Road to the final';

  @override
  String get worldCupMilestoneOpeningLabel => 'Opening match';

  @override
  String get worldCupOpeningMatch =>
      'Mexico v South Africa · 11 Jun 2026 · Mexico City Stadium';

  @override
  String get worldCupMilestoneGroupLabel => 'Group stage';

  @override
  String get worldCupGroupStage =>
      'Group matches start on 11 Jun and build the 32-team knockout bracket.';

  @override
  String get worldCupMilestoneKnockoutLabel => 'Knockout rounds';

  @override
  String get worldCupKnockouts =>
      'The round of 32 starts after the group stage.';

  @override
  String get worldCupMilestoneFinalLabel => 'Final';

  @override
  String get worldCupFinalMatch => '19 Jul 2026 · New York New Jersey Stadium';

  @override
  String get worldCupStandingsTitle => 'Group standings';

  @override
  String get worldCupStandingsPlanBody =>
      'Group rankings update from the fixture scores already in the schedule. Teams are ordered by points, goal difference, goals, wins, losses, then country name until official tie-break data is available.';

  @override
  String get worldCupStandingsRuleLabel => 'Tiebreak order';

  @override
  String get worldCupStandingsRuleValue =>
      'Points · goal difference · goals for · wins · losses · team name';

  @override
  String get worldCupStandingsTieGuide =>
      'When points are tied, goal difference breaks the tie first; if that is still level, goals for decides the order.';

  @override
  String get worldCupStandingsTableTitle => 'Group table';

  @override
  String get worldCupStandingsRankColumn => 'Rk';

  @override
  String get worldCupStandingsTeamColumn => 'Team';

  @override
  String get worldCupStandingsRecordColumn => 'W-D-L';

  @override
  String get worldCupStandingsGoalDifferenceColumn => 'GD';

  @override
  String get worldCupStandingsGoalsForColumn => 'GF';

  @override
  String get worldCupStandingsPointsColumn => 'Pts';

  @override
  String worldCupStandingsRecordValue(int wins, int draws, int losses) {
    return '$wins-$draws-$losses';
  }

  @override
  String worldCupStandingsTieReasonValue(String goalDifference, int goalsFor) {
    return 'Tie-break: GD $goalDifference · GF $goalsFor';
  }

  @override
  String get worldCupRankingsTitle => 'World Cup rankings';

  @override
  String get worldCupRankingsIntro =>
      'Player rankings are gathered from the FIFA official match details available in the app. Goals come from official scorer lists, assists are counted only for matches where FIFA provides assisting player IDs, and yellow/red cards use official card records.';

  @override
  String get worldCupRankingsSourceMatchesLabel => 'Source matches';

  @override
  String worldCupRankingsSourceMatchesValue(int count) {
    return '$count matches';
  }

  @override
  String get worldCupRankingsUpdatedLabel => 'Updated';

  @override
  String get worldCupRankingsLoading => 'Loading FIFA player records...';

  @override
  String get worldCupGoalRankingsTitle => 'Goal ranking';

  @override
  String get worldCupAssistRankingsTitle => 'Assist ranking';

  @override
  String get worldCupDisciplineRankingsTitle => 'Yellow/red card ranking';

  @override
  String get worldCupYellowCardRankingsTitle => 'Yellow card ranking';

  @override
  String get worldCupRedCardRankingsTitle => 'Red card ranking';

  @override
  String get worldCupRankingsNoOfficialMatches =>
      'There are no finished official matches to rank yet. This fills automatically when FIFA data arrives.';

  @override
  String get worldCupGoalRankingsEmpty =>
      'Official scorer details are not available yet. Goal rankings will fill in when match details update.';

  @override
  String get worldCupAssistRankingsEmpty =>
      'Assists can only be counted when FIFA provides assisting player IDs, so there are no assists to show yet.';

  @override
  String get worldCupDisciplineRankingsEmpty =>
      'FIFA official yellow/red card records are not available yet, so there is no discipline ranking to show.';

  @override
  String get worldCupYellowCardRankingsEmpty =>
      'FIFA official yellow card records are not available yet, so there are no players to show.';

  @override
  String get worldCupRedCardRankingsEmpty =>
      'FIFA official red card records are not available yet, so there are no players to show.';

  @override
  String worldCupRankingsGoalCount(int count) {
    return '$count goals';
  }

  @override
  String worldCupRankingsAssistCount(int count) {
    return '$count assists';
  }

  @override
  String worldCupRankingsDisciplineCount(int yellowCards, int redCards) {
    return 'Yellow $yellowCards · Red $redCards';
  }

  @override
  String worldCupRankingsYellowCardCount(int count) {
    return '$count cards';
  }

  @override
  String worldCupRankingsRedCardCount(int count) {
    return '$count cards';
  }

  @override
  String get worldCupYellowCardLabel => 'yellow';

  @override
  String get worldCupRedCardLabel => 'red';

  @override
  String worldCupRankingsEventWithMinute(String opponent, String minute) {
    return 'vs $opponent $minute';
  }

  @override
  String worldCupRankingsCardEventWithMinute(
      String opponent, String minute, String card) {
    return 'vs $opponent $minute $card';
  }

  @override
  String worldCupRankingsMoreEvents(int count) {
    return '+$count more';
  }

  @override
  String get worldCupGroupTeamsTitle => 'Group teams';

  @override
  String worldCupTeamRosterOpenTooltip(String team) {
    return 'Open $team roster';
  }

  @override
  String worldCupTeamRosterTitle(String team) {
    return '$team roster';
  }

  @override
  String get worldCupTeamRosterSubtitle =>
      'Build your own best XI and formation from the position groups.';

  @override
  String get worldCupTeamHistoryTitle => 'Football history and context';

  @override
  String worldCupTeamHistoryBody(String team) {
    return '$team\'s football story is shaped by its national-team tournament experience, domestic league base, overseas-player pipeline, and World Cup qualifying record. This view brings the group fixtures, points, and player clubs together so you can read how $team may build its tournament rhythm.';
  }

  @override
  String worldCupTeamHistoryTournamentContext(
      String team, String opponents, String group) {
    return 'In this group stage, $team competes in $group against $opponents.';
  }

  @override
  String get worldCupTeamMatchOverviewTitle => 'Team match info';

  @override
  String get worldCupTeamCurrentPointsLabel => 'Current points';

  @override
  String get worldCupTeamMatchHistoryTitle => 'Match results';

  @override
  String get worldCupKnockoutPathTitle => 'Opponents to the final';

  @override
  String get worldCupKnockoutPathSubtitle =>
      'Assuming this team advances through each round, these are the possible opponents on the path to the final.';

  @override
  String worldCupKnockoutPathCandidateCount(int count) {
    return '$count candidates';
  }

  @override
  String get worldCupKnockoutPathOpponentPending => 'Opponent to be confirmed';

  @override
  String get worldCupKnockoutPathEliminated => 'Eliminated here';

  @override
  String get worldCupQualificationScenariosTitle => 'Round of 32 scenarios';

  @override
  String worldCupQualificationScenariosSubtitle(
      int currentPoints, int remainingMatches) {
    return 'From $currentPoints current points, this estimates Round of 32 paths and opponent slots for the $remainingMatches remaining match results.';
  }

  @override
  String worldCupQualificationScenariosOneMatchSubtitle(int currentPoints) {
    return 'From $currentPoints current points, this shows the win/draw/loss paths for the final remaining match.';
  }

  @override
  String worldCupQualificationScenariosNoTeamMatchesSubtitle(
      int currentPoints, int remainingOtherMatches) {
    return 'This team has $currentPoints current points and no matches left. Remaining group results ($remainingOtherMatches) still drive the Round of 32 path.';
  }

  @override
  String worldCupQualificationScenariosCompleteSubtitle(int currentPoints) {
    return 'The group schedule is complete. This shows the Round of 32 path from the final $currentPoints points.';
  }

  @override
  String get worldCupQualificationScenariosGuide =>
      'Each row is one result combination for this team\'s remaining matches. Auto means finishing 1st or 2nd in the group. 3rd-place race means finishing 3rd, then needing to be among the 8 best third-place teams overall. The denominators for auto, 3rd-place race, and out count every win/draw/loss combination for the other remaining matches in the same group. Opponent countries translate the bracket slot using the current table.';

  @override
  String get worldCupQualificationScenariosNoTeamMatchesGuide =>
      'There are no result picks for this team. The denominator only counts any remaining win/draw/loss combinations elsewhere in the group; if none remain, the table is fixed.';

  @override
  String get worldCupQualificationScenariosEmpty =>
      'There is not enough group-stage data to calculate Round of 32 scenarios for this team yet.';

  @override
  String worldCupQualificationScenarioPoints(
      int remainingPoints, int finalPoints) {
    return '+$remainingPoints remaining pts · $finalPoints pts total';
  }

  @override
  String worldCupQualificationScenarioRankRange(int bestRank, int worstRank) {
    return 'Possible rank $bestRank-$worstRank';
  }

  @override
  String worldCupQualificationScenarioCases(int automaticCases,
      int thirdPlaceCases, int eliminatedCases, int totalCases) {
    return 'Auto $automaticCases/$totalCases · 3rd-place race $thirdPlaceCases/$totalCases · out $eliminatedCases/$totalCases';
  }

  @override
  String worldCupQualificationOtherMatchesTitle(int count) {
    return '$count other match result cases';
  }

  @override
  String get worldCupQualificationOtherMatchesSubtitle =>
      'Even with this team\'s result fixed, other group results can change the rank and qualification state.';

  @override
  String get worldCupQualificationWaitingOtherMatchesTitle =>
      'Waiting result scenarios';

  @override
  String get worldCupQualificationWaitingOtherMatchesSubtitle =>
      'This team\'s matches are finished, so every remaining group result combination recalculates the Round of 32 state below.';

  @override
  String get worldCupQualificationOtherPathDirectSection =>
      'Direct advance cases';

  @override
  String get worldCupQualificationOtherPathThirdSection =>
      '3rd-place race cases';

  @override
  String get worldCupQualificationOtherPathOutSection => 'Elimination cases';

  @override
  String worldCupQualificationOtherPathSectionTitle(String label, int count) {
    return '$label · $count cases';
  }

  @override
  String worldCupQualificationOtherPathOutcome(int rank, String outcome) {
    return 'Rank $rank · $outcome';
  }

  @override
  String worldCupQualificationOtherMatchPick(
      String home, String away, String result) {
    return '$home - $away: $result';
  }

  @override
  String worldCupQualificationOtherMatchWinResult(String team) {
    return '$team win';
  }

  @override
  String get worldCupQualificationOtherMatchDrawResult => 'Draw';

  @override
  String get worldCupQualificationThirdPlaceNote =>
      'A third-place finish still needs to rank among the 8 best third-place teams across the 12 groups.';

  @override
  String get worldCupQualificationNoTeamMatchesPick => 'No team matches left';

  @override
  String get worldCupQualificationCompletePick => 'Group rank fixed';

  @override
  String worldCupQualificationMatchPick(String opponent, String result) {
    return '$result vs $opponent';
  }

  @override
  String get worldCupQualificationOutcomeAuto => 'Auto berth';

  @override
  String get worldCupQualificationOutcomePossible => 'Can advance';

  @override
  String get worldCupQualificationOutcomeThird => '3rd-place race';

  @override
  String get worldCupQualificationOutcomeOut => 'Out';

  @override
  String worldCupQualificationOpponentCandidates(String opponents) {
    return 'Round of 32 opponents (current table): $opponents';
  }

  @override
  String get worldCupQualificationNoOpponent =>
      'This result path has no Round of 32 route.';

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
  String get worldCupQualificationOpponentSeparator => ' or ';

  @override
  String worldCupTeamRosterFormationLabel(String formation) {
    return '$formation formation';
  }

  @override
  String get worldCupTeamRosterBestXiTitle => 'My best XI';

  @override
  String get worldCupTeamRosterBestXiNote =>
      'This is not an official match lineup. It is a board drawn from the formation and players you choose. Tap player rows to include or remove them.';

  @override
  String get worldCupTeamRosterFormationPickerLabel => 'Formation';

  @override
  String worldCupTeamRosterBestXiCount(int count) {
    return '$count/11 selected';
  }

  @override
  String get worldCupTeamRosterBestXiComplete => 'Best XI complete';

  @override
  String worldCupTeamRosterBestXiNeedMore(int count) {
    return '$count more needed';
  }

  @override
  String get worldCupTeamRosterBestXiReset => 'Auto pick';

  @override
  String worldCupTeamRosterBestXiPositionLimit(int selected, int required) {
    return '$selected/$required';
  }

  @override
  String worldCupTeamRosterBestXiSelectTooltip(String player) {
    return 'Select $player';
  }

  @override
  String worldCupTeamRosterBestXiRemoveTooltip(String player) {
    return 'Remove $player';
  }

  @override
  String get worldCupTeamRosterFormationEstimatedNote =>
      'This is an expected formation arranged from the current squad data, not an official match lineup. Actual match tactics and starters can change.';

  @override
  String get worldCupTeamRosterFormationPlaceholderNote =>
      'Official squad data is unavailable, so this uses default position slots. Do not treat it as an actual formation.';

  @override
  String get worldCupTeamRosterSourceNote =>
      'Official 2026 squad data is not bundled for this country yet, so position slots are shown until a stable legal source is connected.';

  @override
  String get worldCupTeamRosterCandidateSourceNote =>
      'Shown from published 2026 squad and club information. Injury replacements and match-day choices can still change before kickoff.';

  @override
  String get worldCupTeamRosterGoalkeepers => 'Goalkeepers';

  @override
  String get worldCupTeamRosterDefenders => 'Defenders';

  @override
  String get worldCupTeamRosterMidfielders => 'Midfielders';

  @override
  String get worldCupTeamRosterForwards => 'Forwards';

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
  String get worldCupTournamentTitle => 'Tournament bracket';

  @override
  String get worldCupTournamentPlanBody =>
      'Confirmed ties are shown by country, with the path through the next rounds kept easy to scan.';

  @override
  String get worldCupTournamentZoomOut => 'Zoom bracket out';

  @override
  String get worldCupTournamentZoomReset => 'Reset bracket zoom';

  @override
  String get worldCupTournamentZoomIn => 'Zoom bracket in';

  @override
  String get worldCupTournamentOpenFullScreen => 'Open full screen';

  @override
  String get worldCupTournamentPdfTooltip => 'Download bracket PDF';

  @override
  String get worldCupTournamentPdfExportedSnack => 'Bracket PDF is ready.';

  @override
  String get worldCupTournamentPdfExportFailedSnack =>
      'Could not create the bracket PDF.';

  @override
  String get worldCupTournamentImageTooltip => 'Share bracket image';

  @override
  String get worldCupTournamentImageExportedSnack => 'Bracket image is ready.';

  @override
  String get worldCupTournamentImageExportFailedSnack =>
      'Could not create the bracket image.';

  @override
  String worldCupStageMatchCount(int count) {
    return '$count matches';
  }

  @override
  String worldCupBracketRoundSummary(String dateRange, int count) {
    return '$dateRange · $count matches';
  }

  @override
  String worldCupBracketFirstSeed(String group) {
    return 'Group $group winner';
  }

  @override
  String worldCupBracketSecondSeed(String group) {
    return 'Group $group runner-up';
  }

  @override
  String worldCupBracketThirdSeed(String groups) {
    return 'One 3rd-place team from $groups';
  }

  @override
  String worldCupBracketWinnerSlot(int matchNumber) {
    return 'Winner of M$matchNumber';
  }

  @override
  String worldCupBracketLoserSlot(int matchNumber) {
    return 'Loser of M$matchNumber';
  }

  @override
  String get worldCupBracketPendingTeam => 'Team to be confirmed';

  @override
  String get worldCupBracketPendingWinner => 'Winner to be confirmed';

  @override
  String get worldCupBracketPendingLoser => 'Loser to be confirmed';

  @override
  String get worldCupBracketQualifiedTeamSeparator => ' / ';

  @override
  String worldCupBracketQualifiedSlotDetail(String slot) {
    return 'Qualified from $slot';
  }

  @override
  String get worldCupBracketWinnerCandidateDetail => 'Winner candidates';

  @override
  String get worldCupBracketLoserCandidateDetail => 'Loser candidates';

  @override
  String get worldCupBracketWinnerResolvedDetail => 'Winner confirmed';

  @override
  String get worldCupBracketLoserResolvedDetail => 'Loser confirmed';

  @override
  String worldCupBracketSourceMatch(int matchNumber, String home, String away) {
    return 'M$matchNumber: $home v $away';
  }

  @override
  String get worldCupSourceAction => 'Open FIFA schedule';

  @override
  String get worldCupOfficialRefreshAction => 'Refresh FIFA data';

  @override
  String get worldCupOfficialRefreshing => 'Updating FIFA';

  @override
  String get worldCupOfficialUnavailable => 'FIFA unavailable';

  @override
  String worldCupOfficialUpdatedAt(String time) {
    return 'FIFA $time';
  }

  @override
  String get homeHubTitleShort => 'Home';

  @override
  String get homeLayoutChangeAction => 'Change home';

  @override
  String get homeLayoutSettingsTitle => 'Home screen settings';

  @override
  String get homeLayoutSettingsReset => 'Reset';

  @override
  String get homeLayoutReorderTooltip => 'Move section';

  @override
  String get homeLayoutSavedMessage => 'Home screen order saved.';

  @override
  String get homeLayoutNoVisibleSections => 'All home sections are hidden.';

  @override
  String get homeLayoutAutoOrderHint =>
      'Sections you do not pin move up as you use them more.';

  @override
  String get homeSectionPinTooltip => 'Pin this position';

  @override
  String get homeSectionUnpinTooltip => 'Unpin';

  @override
  String get homeSectionClubSchedule => 'Club schedule';

  @override
  String get homeSectionLevel => 'Level summary';

  @override
  String get homeSectionChallenge => 'Challenge';

  @override
  String get homeSectionStreak => 'Training streak';

  @override
  String get homeSectionMeal => 'Meal summary';

  @override
  String get homeSectionDailyFlow => 'Today\'s tasks';

  @override
  String get homeSectionQuickActions => 'Quick actions';

  @override
  String get homeSectionContinue => 'Continue';

  @override
  String get homeDailyCheckTitle => 'Today\'s tasks';

  @override
  String homeDailyCheckCompletedCount(int completed, int total) {
    return '$completed/$total done';
  }

  @override
  String get homeTodoTrainingLogShort => 'Log';

  @override
  String get homeTodoLiftingShort => 'Lifting';

  @override
  String get homeTodoJumpRopeShort => 'Jump';

  @override
  String get jumpRopeRecordTitle => 'Jump rope record';

  @override
  String get jumpRopeMinutesLabel => 'Jump rope time (min)';

  @override
  String get jumpRopeCountLabel => 'Jump rope count';

  @override
  String get jumpRopeMemoLabel => 'Memo';

  @override
  String get jumpRopeMemoHint => 'Write what you felt during jump rope.';

  @override
  String get homeTodoQuizShort => 'Quiz';

  @override
  String get homeTodoNewsShort => 'News';

  @override
  String get homeTodoDiaryShort => 'Diary';

  @override
  String get homeTodoBoardSketchShort => 'Sketch';

  @override
  String get homeQuickActionsTitle => 'Quick actions';

  @override
  String get homeQuickActionMatch => 'Add match';

  @override
  String get homeQuickActionPlan => 'Add plan';

  @override
  String get homeContinueTitle => 'Continue';

  @override
  String get homeContinueEmpty =>
      'Nothing to continue today. Pick a fresh challenge below.';

  @override
  String get homeContinueWrongAnswerReview => 'Continue wrong-answer review';

  @override
  String get homeContinueQuiz => 'Continue quiz';

  @override
  String get homeContinueStartQuiz => 'Start quiz';

  @override
  String homeContinueQuizProgress(int current, int total) {
    return 'In progress $current / $total';
  }

  @override
  String get homeContinueQuizStartSubtitle => 'Jump back into today\'s quiz.';

  @override
  String get homeContinueTodayTrainingLog => 'Today training log';

  @override
  String homeContinueTrainingDuration(Object date, int duration) {
    return '$date · $duration min';
  }

  @override
  String get homeContinueTrainingButton => 'Continue';

  @override
  String get homeContinueQuizButton => 'Open quiz';

  @override
  String get homeContinueRecentBoardTitle => 'Recent training board';

  @override
  String homeContinueBoardCount(int count) {
    return '$count sketches';
  }

  @override
  String homeContinueBoardSaved(Object title, Object date) {
    return '$title · saved $date';
  }

  @override
  String get homeContinueBoardButton => 'Edit now';

  @override
  String get dailyTasksXpDialogTitle => 'Today\'s tasks complete';

  @override
  String get dailyTasksXpDialogMessage =>
      'The whole routine is checked off. That consistency turned into growth gems.';

  @override
  String dailyTasksXpDialogGems(int count) {
    return '+$count gems';
  }

  @override
  String dailyTasksXpDialogProgress(int totalXp, int remainingXp) {
    return 'Total $totalXp XP · $remainingXp XP to next level';
  }

  @override
  String dailyTasksXpDialogMaxProgress(int totalXp, int remainingXp) {
    return 'Total $totalXp XP · $remainingXp XP to next mastery star';
  }

  @override
  String get dailyTasksXpDialogAction => 'Keep going';

  @override
  String get trainingXpDialogTitle => 'Training log saved';

  @override
  String get trainingXpDialogMessage => 'Training log saved.';

  @override
  String get trainingRecordSavedDialogMessage => 'Record saved.';

  @override
  String get trainingEntryConditioningEmpty => 'No jump rope/lifting record';

  @override
  String get trainingEntryLessonSummary => 'Lesson';

  @override
  String trainingEntryLessonSummaryWithDetail(String detail) {
    return 'Lesson: $detail';
  }

  @override
  String get trainingEntryInjuryPresent => 'Injury recorded';

  @override
  String trainingEntryInjurySummary(String detail) {
    return 'Injury: $detail';
  }

  @override
  String trainingEntryInjuryPainSummary(int pain) {
    return 'Pain $pain/10';
  }

  @override
  String get trainingXpDialogJumpRopeTitle => 'Jump rope saved';

  @override
  String get trainingXpDialogJumpRopeMessage => 'Jump rope log saved.';

  @override
  String get trainingXpDialogLiftingTitle => 'Lifting saved';

  @override
  String get trainingXpDialogLiftingMessage => 'Lifting log saved.';

  @override
  String get trainingXpDialogMealTitle => 'Recovery saved';

  @override
  String get trainingXpDialogMealMessage => 'Meal and recovery log saved.';

  @override
  String get diaryXpDialogTitle => 'Diary sapphire';

  @override
  String get diaryXpDialogMessage =>
      'Your reflection turned into calm sapphire XP.';

  @override
  String get trainingSketchXpDialogTitle => 'Sketch gold';

  @override
  String get trainingSketchXpDialogMessage =>
      'Your training idea sketch turned into bright gold XP.';

  @override
  String trainingXpDialogXp(int count) {
    return '+$count XP';
  }

  @override
  String get trainingXpDialogRewardLabel => 'XP earned';

  @override
  String get trainingRecordSavedDialogLabel => 'Record complete';

  @override
  String get trainingRecordSavedDialogValue => 'Saved';

  @override
  String get trainingXpDialogTotalLabel => 'Total XP';

  @override
  String trainingXpDialogTotalValue(int totalXp) {
    return '$totalXp XP';
  }

  @override
  String get trainingXpDialogLevelLabel => 'Current level';

  @override
  String trainingXpDialogLevelValue(int level, String levelName) {
    return 'Lv.$level $levelName';
  }

  @override
  String get trainingXpDialogAction => 'OK';

  @override
  String get trainingXpSourceTrainingLog => 'Training log';

  @override
  String get trainingXpSourceTrainingUpdate => 'Training update';

  @override
  String get trainingXpSourceLifting => 'Lifting';

  @override
  String get trainingXpSourceJumpRope => 'Jump rope';

  @override
  String get trainingXpSourceTrainingSketch => 'Training sketch';

  @override
  String get trainingXpSourceDiary => 'Diary';

  @override
  String get trainingSaveToastPlain => 'Training note saved.';

  @override
  String trainingSaveToastWithXp(int gainedXp, Object details) {
    return 'Training note saved. +$gainedXp XP · $details';
  }

  @override
  String trainingSaveToastLevelUp(
      int gainedXp, Object details, int level, Object levelName) {
    return 'Training note saved. +$gainedXp XP · $details · Reached Lv.$level $levelName';
  }

  @override
  String get trainingXpToastReasonLiftingMissed => 'Lifting missed';

  @override
  String get trainingXpToastReasonJumpRopeMissed => 'Jump rope missed';

  @override
  String get trainingXpToastReasonMealFullBonus =>
      'Three meals + 5+ rice bowls';

  @override
  String get trainingXpToastReasonRoutineComplete =>
      'Training routine complete';

  @override
  String get trainingXpToastReasonStreakDaily2 => '2-3 day streak bonus';

  @override
  String get trainingXpToastReasonStreakDaily4 => '4-6 day streak bonus';

  @override
  String get trainingXpToastReasonStreakDaily7 => '7+ day streak bonus';

  @override
  String get trainingXpToastReasonStreak3 => '3-day streak';

  @override
  String get trainingXpToastReasonStreak7 => '7-day streak';

  @override
  String get trainingXpToastReasonWeekly3 => '3 logs this week';

  @override
  String get trainingXpToastReasonWeekly5 => '5 logs this week';

  @override
  String get trainingXpToastReasonDailyCap => 'Daily cap applied';

  @override
  String trainingXpToastMoreReasons(int count) {
    return '$count more';
  }

  @override
  String diarySavedWithXpFeedback(int count) {
    return 'Diary saved +$count XP';
  }

  @override
  String trainingStreakCheerTitle(int count) {
    return '$count-day training streak';
  }

  @override
  String get trainingStreakCheerMessage =>
      'Day-by-day training notes are connecting into a real routine. Keep the next session simple and repeatable.';

  @override
  String get trainingStreakCheerAction => 'Keep going';

  @override
  String get levelUpDialogTitle => 'Level up!';

  @override
  String levelUpDialogLevelLabel(int level, Object levelName) {
    return 'Lv.$level $levelName';
  }

  @override
  String get levelUpDialogEncouragement =>
      'Today\'s effort became bright growth. Keep this rhythm for the next session.';

  @override
  String levelUpDialogEncouragementWithReward(Object rewardName) {
    return 'Today\'s effort became bright growth, and $rewardName is ready too.';
  }

  @override
  String levelUpDialogProgress(int xp, Object stageName) {
    return '+$xp gems earned · now in $stageName';
  }

  @override
  String get levelUpDialogRewardTitle => 'Reward';

  @override
  String get levelUpDialogLater => 'Later';

  @override
  String get levelUpDialogClaimReward => 'Claim reward';

  @override
  String get levelUpDialogConfirm => 'Great';

  @override
  String levelUpRewardClaimed(Object rewardName) {
    return 'Claimed $rewardName.';
  }

  @override
  String get xpGuideDailyTasksCompleteTitle => 'All today tasks complete';

  @override
  String get quizXpSourceLabel => 'Sports quiz';

  @override
  String get quizScreenTitle => 'Today\'s Quiz';

  @override
  String get quizLibraryAction => 'Questions';

  @override
  String get quizHistoryAction => 'History';

  @override
  String get quizBackHomeTooltip => 'Back to quiz home';

  @override
  String get quizResultMissReviewCountLabel => 'Misses to review';

  @override
  String get quizResultNoMissedQuestions =>
      'This run finished with no missed questions.';

  @override
  String get quizStudyGuideTitle => 'Study guide';

  @override
  String get quizStudyGuideQuestionLabel => 'Question';

  @override
  String get quizStudyGuideAnswerLabel => 'Answer';

  @override
  String get quizStudyGuideConceptLabel => 'Core concept';

  @override
  String get quizStudyGuideApplicationLabel => 'Apply it';

  @override
  String get quizStudyGuidePracticeLabel => 'Training check';

  @override
  String get quizStudyGuidePending =>
      'Choose an answer to open the study guide.';

  @override
  String quizXpSavedFeedback(int count) {
    return 'Quiz complete +$count XP';
  }

  @override
  String get playerXpGuideTitle => 'How XP goes up';

  @override
  String playerXpGuideHeroLevel(int level) {
    return 'You are Lv.$level';
  }

  @override
  String playerXpGuideHeroBody(int remainingXp) {
    return 'This page groups every XP source clearly. $remainingXp XP remains until the next level.';
  }

  @override
  String playerXpGuideHeroMax(int masterySpan, int remainingXp) {
    return 'After Lv.20, every $masterySpan XP earns a mastery star. $remainingXp XP remains until the next star.';
  }

  @override
  String get playerXpGuideLoggingTitle => 'XP from training logs';

  @override
  String get playerXpGuideLoggingSubtitle =>
      'Core growth comes from saving consistent training logs.';

  @override
  String get playerXpGuideTrainingLogSaved => 'Training log saved';

  @override
  String get playerXpGuideFirstDailyLog => 'First log of the day';

  @override
  String get playerXpGuidePlannedDayComplete => 'Complete a planned day';

  @override
  String get playerXpGuideLiftingRecorded => 'Lifting recorded';

  @override
  String get playerXpGuideJumpRopeRecorded => 'Jump rope recorded';

  @override
  String get playerXpGuideTrainingRoutineComplete =>
      'Complete lifting + jump rope + recovery';

  @override
  String get playerXpGuideMissingConditioning =>
      'Missing lifting or jump rope costs XP';

  @override
  String get playerXpGuideMissingConditioningXp => '-5 XP each';

  @override
  String get playerXpGuideStreakTitle => 'Streak and weekly bonuses';

  @override
  String get playerXpGuideStreakSubtitle =>
      'Larger bonuses unlock once repetition becomes consistent.';

  @override
  String get playerXpGuideStreakMilestones => '3-day / 7-day streak';

  @override
  String get playerXpGuideStreakDailyBonus => 'Daily bonus from streak logging';

  @override
  String get playerXpGuideWeeklyBonus => '3 logs / 5 logs in a week';

  @override
  String get playerXpGuideActivityTitle => 'Other activity XP';

  @override
  String get playerXpGuideActivitySubtitle =>
      'Plans, sketches, meals, diary, quiz, and daily completion also add XP when saved.';

  @override
  String get playerXpGuidePlanCreated => 'Training plan created';

  @override
  String get playerXpGuideMatchLogged => 'Match log saved';

  @override
  String get playerXpGuideTrainingSketchSaved => 'Training sketch saved';

  @override
  String get playerXpGuideTrainingSketchSavedXp => '+5 XP / +2 XP';

  @override
  String get playerXpGuideDiaryCreated => 'Diary created';

  @override
  String get playerXpGuideQuizComplete => 'Quiz completed';

  @override
  String get playerXpGuideQuizCompleteXp => '+2 to +15 XP by correct answers';

  @override
  String get playerXpGuideMealTwoPlus => 'Two or more meals logged';

  @override
  String get playerXpGuideMealFull =>
      'Three meals / three meals with 5+ rice bowls';

  @override
  String get playerXpGuideDailyTasksComplete =>
      'All daily home tasks completed';

  @override
  String get playerXpGuideDailyCap => 'Daily positive XP cap';

  @override
  String get playerLevelName1 => 'Kickoff';

  @override
  String get playerLevelName2 => 'Rookie';

  @override
  String get playerLevelName3 => 'Starter';

  @override
  String get playerLevelName4 => 'Challenger';

  @override
  String get playerLevelName5 => 'Playmaker';

  @override
  String get playerLevelName6 => 'Engine';

  @override
  String get playerLevelName7 => 'Captain';

  @override
  String get playerLevelName8 => 'Elite';

  @override
  String get playerLevelName9 => 'Match Leader';

  @override
  String get playerLevelName10 => 'High Performer';

  @override
  String get playerLevelName11 => 'Driver';

  @override
  String get playerLevelName12 => 'Field Maker';

  @override
  String get playerLevelName13 => 'Control Tower';

  @override
  String get playerLevelName14 => 'Iron Captain';

  @override
  String get playerLevelName15 => 'Game Changer';

  @override
  String get playerLevelName16 => 'Session Master';

  @override
  String get playerLevelName17 => 'Ace Core';

  @override
  String get playerLevelName18 => 'Pitch Artist';

  @override
  String get playerLevelName19 => 'Stadium Icon';

  @override
  String get playerLevelName20 => 'Football Gift Master';

  @override
  String get playerLevelStage1 => 'New Ground';

  @override
  String get playerLevelStage2 => 'Training Rookie';

  @override
  String get playerLevelStage3 => 'First Team Rise';

  @override
  String get playerLevelStage4 => 'Match Leader';

  @override
  String get playerLevelStage5 => 'Upper Tier';

  @override
  String get playerLevelStage6 => 'Core Ace';

  @override
  String get playerLevelStage7 => 'Elite Track';

  @override
  String get playerLevelBaseballNames =>
      'Play Ball|Rookie Hitter|Lineup Starter|Base Challenger|Clutch Maker|Inning Engine|Dugout Captain|Diamond Elite|Game Leader|High Performer|Slugger Driver|Field Maker|Sign Controller|Iron Captain|Game Changer|Series Master|Ace Core|Diamond Artist|Ballpark Icon|Baseball Gift Master';

  @override
  String get playerLevelBasketballNames =>
      'Tipoff|Court Rookie|Lineup Starter|Rim Challenger|Playmaker|Court Engine|Team Captain|Elite Guard|Game Leader|High Performer|Drive Leader|Court Maker|Pace Controller|Iron Captain|Clutch Changer|Session Master|Ace Core|Court Artist|Arena Icon|Basketball Gift Master';

  @override
  String get playerLevelTennisNames =>
      'First Serve|Court Rookie|Rally Starter|Baseline Challenger|Point Maker|Footwork Engine|Match Captain|Elite Rallyer|Game Leader|High Performer|Serve Driver|Court Maker|Tempo Controller|Iron Captain|Tiebreak Changer|Session Master|Ace Core|Line Artist|Center Court Icon|Tennis Gift Master';

  @override
  String get playerLevelBaseballStages =>
      'New Player|Rookie Hitter|Starter Rise|Game Leader|Upper Tier|Core Ace|Elite Diamond';

  @override
  String get playerLevelBasketballStages =>
      'New Player|Court Rookie|Starter Rise|Game Leader|Upper Tier|Core Ace|Elite Court';

  @override
  String get playerLevelTennisStages =>
      'New Player|Court Rookie|Rally Rise|Match Leader|Upper Tier|Core Ace|Elite Tour';

  @override
  String get playerLevelBaseballIllustrations =>
      'Play-ball sign|First glove|Batting tee|Speed cleats|Throwing rhythm|Power bat|Lineup board|Captain cap|Winner trophy|Celebration fireworks|Fielding glove|Catcher mitt|Sign radar|Baserun lightning|Victory medal|Home ballpark|Ace rocket|Diamond star|Ballpark gift box|Legend galaxy';

  @override
  String get playerLevelBasketballIllustrations =>
      'Tipoff ball|First basketball|Training cone|Speed shoes|Dribble rhythm|Power dumbbell|Tactics board|Captain crown|Winner trophy|Celebration fireworks|Defense shield|Rebound hands|Tactics radar|Fast-break lightning|Victory medal|Home arena|Ace rocket|Court star|Arena gift box|Legend galaxy';

  @override
  String get playerLevelTennisIllustrations =>
      'First serve|First racket|Training cone|Speed shoes|Rally rhythm|Power dumbbell|Tactics note|Captain crown|Winner trophy|Celebration fireworks|Defense shield|Match towel|Tactics radar|Footwork lightning|Victory medal|Center court|Ace rocket|Line star|Center-court gift box|Legend galaxy';

  @override
  String get playerLevelIllustration1 => 'Starter whistle';

  @override
  String get playerLevelIllustration2 => 'First football';

  @override
  String get playerLevelIllustration3 => 'Training cone';

  @override
  String get playerLevelIllustration4 => 'Speed boots';

  @override
  String get playerLevelIllustration5 => 'Jump-rope rhythm';

  @override
  String get playerLevelIllustration6 => 'Power dumbbell';

  @override
  String get playerLevelIllustration7 => 'Tactics board';

  @override
  String get playerLevelIllustration8 => 'Captain crown';

  @override
  String get playerLevelIllustration9 => 'Winner trophy';

  @override
  String get playerLevelIllustration10 => 'Celebration fireworks';

  @override
  String get playerLevelIllustration11 => 'Defense shield';

  @override
  String get playerLevelIllustration12 => 'Keeper gloves';

  @override
  String get playerLevelIllustration13 => 'Tactics radar';

  @override
  String get playerLevelIllustration14 => 'Sprint lightning';

  @override
  String get playerLevelIllustration15 => 'Victory medal';

  @override
  String get playerLevelIllustration16 => 'Home stadium';

  @override
  String get playerLevelIllustration17 => 'Ace rocket';

  @override
  String get playerLevelIllustration18 => 'Pitch star';

  @override
  String get playerLevelIllustration19 => 'Stadium gift box';

  @override
  String get playerLevelIllustration20 => 'Legend galaxy';

  @override
  String get levelGuideTitle => 'Level guide';

  @override
  String get levelGuideOpenXpGuideTooltip => 'Open XP guide';

  @override
  String get levelGuideXpHistoryTooltip => 'XP history';

  @override
  String get levelGuideCurrentProgressTitle => 'Current progress';

  @override
  String levelGuideCurrentProgressTotal(int level, int totalXp) {
    return 'Lv.$level · $totalXp XP total';
  }

  @override
  String levelGuideCurrentProgressMax(int stars, int remainingXp) {
    return '$stars mastery star(s) · $remainingXp XP left until the next star.';
  }

  @override
  String levelGuideCurrentProgressNext(int remainingXp) {
    return '$remainingXp XP left until the next level. Use the top-right actions for the XP guide and history.';
  }

  @override
  String get levelGuideSetRewardTitle => 'Set level reward';

  @override
  String get levelGuideRewardNameLabel => 'Reward name';

  @override
  String get levelGuideRewardNameHint => 'e.g. New football socks';

  @override
  String get levelGuideClearRewardAction => 'Clear';

  @override
  String get levelGuideCurrentBadge => 'Current';

  @override
  String levelGuideXpRangeLabel(int minXp, int maxXp) {
    return '$minXp XP to $maxXp XP';
  }

  @override
  String get levelGuideRewardTitle => 'Level reward';

  @override
  String get levelGuideEditReward => 'Edit';

  @override
  String get levelGuideRewardNotSet => 'Not set';

  @override
  String get levelGuideSyncing => 'Syncing...';

  @override
  String get levelGuideRewardNeedsName => 'Add reward to claim';

  @override
  String get levelGuideRewardAlreadyClaimed => 'Already claimed';

  @override
  String get levelGuideClaimReward => 'Claim reward';

  @override
  String levelGuideRewardLocked(int level) {
    return 'Claim at Lv.$level';
  }

  @override
  String get xpHistoryTitle => 'XP history';

  @override
  String get xpHistoryClearAllAction => 'Clear all';

  @override
  String get xpHistoryEmpty => 'No XP history yet.';

  @override
  String get xpHistoryMessageDeleted => 'XP message deleted.';

  @override
  String get xpHistoryDeleteDialogTitle => 'Delete XP messages';

  @override
  String get xpHistoryDeleteDialogBody => 'Delete all saved XP messages?';

  @override
  String get xpHistoryAllDeleted => 'All XP messages deleted.';

  @override
  String get xpHistoryRecentFlow => 'Recent XP flow';

  @override
  String xpHistorySummaryCount(int count) {
    return '$count history items are saved.';
  }

  @override
  String xpHistorySummaryLatest(Object title) {
    return 'Below, entries are arranged in date and time order. Latest entry: $title.';
  }

  @override
  String xpHistoryDayEventCount(int count) {
    return '$count XP events';
  }

  @override
  String get xpHistoryDeleteMessageTooltip => 'Delete message';

  @override
  String xpHistoryTotalXp(int totalXp) {
    return '$totalXp XP total';
  }

  @override
  String xpHistoryStayedAtLevel(int level) {
    return 'Stayed at Lv.$level';
  }

  @override
  String get xpHistoryTrainingLog => 'Training log';

  @override
  String xpHistoryTrainingLogWithLabel(Object label) {
    return 'Training log · $label';
  }

  @override
  String get xpHistoryMatchLog => 'Match log saved';

  @override
  String xpHistoryMatchLogWithLabel(Object label) {
    return 'Match log · $label';
  }

  @override
  String get xpHistoryMealLog => 'Meal log saved';

  @override
  String get xpHistoryQuizCompletion => 'Quiz completion';

  @override
  String get xpHistoryPlanCreated => 'Training plan created';

  @override
  String get xpHistoryBoardSaved => 'Training sketch saved';

  @override
  String xpHistoryBoardSavedWithLabel(Object label) {
    return 'Training sketch · $label';
  }

  @override
  String get xpHistoryDiaryCreated => 'Today diary created';

  @override
  String get xpHistoryDailyTasksComplete => 'Today tasks complete';

  @override
  String get xpHistoryTrainingLabelLifting => 'Lifting';

  @override
  String get xpHistoryTrainingLabelJumpRope => 'Jump rope';

  @override
  String get xpHistoryReasonLog => 'base log';

  @override
  String get xpHistoryReasonFirstDailyLog => 'first of day';

  @override
  String get xpHistoryReasonPlanCompleted => 'planned day';

  @override
  String get xpHistoryReasonLiftingRecorded => 'lifting recorded';

  @override
  String get xpHistoryReasonJumpRopeRecorded => 'jump rope recorded';

  @override
  String get xpHistoryReasonLiftingMissed => 'no lifting';

  @override
  String get xpHistoryReasonJumpRopeMissed => 'no jump rope';

  @override
  String get xpHistoryReasonLiftingAdded => 'lifting added';

  @override
  String get xpHistoryReasonJumpRopeAdded => 'jump rope added';

  @override
  String get xpHistoryReasonMealTwoPlus => '2+ meals';

  @override
  String get xpHistoryReasonMealFullDay => '3 meals complete';

  @override
  String get xpHistoryReasonMealFullDayBonus => '3 meals + 5+ rice bowls';

  @override
  String get xpHistoryReasonStreak3 => '3-day streak';

  @override
  String get xpHistoryReasonStreak7 => '7-day streak';

  @override
  String get xpHistoryReasonStreakDaily2 => 'daily streak (2-3 days)';

  @override
  String get xpHistoryReasonStreakDaily4 => 'daily streak (4-6 days)';

  @override
  String get xpHistoryReasonStreakDaily7 => 'daily streak (7+ days)';

  @override
  String get xpHistoryReasonRoutineComplete => 'daily routine complete';

  @override
  String get xpHistoryReasonWeekly3 => '3 this week';

  @override
  String get xpHistoryReasonWeekly5 => '5 this week';

  @override
  String get xpHistoryReasonQuizComplete => 'quiz complete';

  @override
  String get xpHistoryReasonPlanCreated => 'plan created';

  @override
  String xpHistoryReasonPlanGroupCreated(int count) {
    return '$count-plan series';
  }

  @override
  String get xpHistoryReasonMatchLogged => 'match logged';

  @override
  String get xpHistoryReasonMatchResultRecorded => 'result recorded';

  @override
  String get xpHistoryReasonMatchContributionRecorded =>
      'contribution recorded';

  @override
  String get xpHistoryReasonBoardCreated => 'board created';

  @override
  String get xpHistoryReasonBoardSaved => 'board saved';

  @override
  String get xpHistoryReasonDiaryCreated => 'diary created';

  @override
  String get xpHistoryReasonDailyTasksCompleted => 'today tasks complete';

  @override
  String get xpHistoryReasonDailyCap => 'daily cap';

  @override
  String get profilePlayerLevelLabel => 'Player level';

  @override
  String get profileVisualGrowthTier => 'Visual growth tier';

  @override
  String profileRewardReadySummary(int count) {
    return '$count rewards ready';
  }

  @override
  String get profileNoNextReward => 'No next reward yet';

  @override
  String profileRewardNow(Object rewardName) {
    return 'Reward now: $rewardName';
  }

  @override
  String profileNextReward(int level, Object rewardName) {
    return 'Next reward Lv.$level $rewardName';
  }

  @override
  String get profilePlayerNumberLabel => 'Player number';

  @override
  String get profilePlayerNumberHint => 'Example: 10';

  @override
  String profileSportStartDateLabel(Object sport) {
    return '$sport start date';
  }

  @override
  String profileLevelProgressMax(int stars, int remainingXp) {
    return '$stars mastery star(s) · $remainingXp XP left';
  }

  @override
  String profileLevelProgressNext(int remainingXp, int totalXp) {
    return '$remainingXp XP to next level · $totalXp XP total';
  }

  @override
  String homeLevelProgressMax(int stars, int remainingXp) {
    return '$stars star(s) · $remainingXp XP left';
  }

  @override
  String homeLevelProgressNext(int remainingXp) {
    return '$remainingXp XP left';
  }

  @override
  String get homePriorityCheckPlansMessage =>
      'Review the remaining training plans before you start.';

  @override
  String get homePriorityPlansAction => 'Plans';

  @override
  String get homePriorityPlanNextMessage => 'Add a short training plan.';

  @override
  String get homePriorityPlanNextAction => 'Add plan';

  @override
  String get homePriorityReviewWeekMessage =>
      'Review this week\'s training flow and choose the next target.';

  @override
  String get homePriorityStatsAction => 'Stats';

  @override
  String get homePrioritySketchNextMessage =>
      'Sketch the movement you want to try in your next session.';

  @override
  String get homePriorityBoardAction => 'Board';

  @override
  String get homePriorityConditionMessage =>
      'Check your recent condition trend and adjust recovery.';

  @override
  String get homePriorityRewardsMessage =>
      'Review level rewards and the next growth target.';

  @override
  String get homePriorityLevelAction => 'Level';

  @override
  String get homeMealSuggestionDoneShort =>
      'All three meals are logged. Keep the rhythm going.';

  @override
  String get homeMealSuggestionTwoShort => 'Please log one more meal.';

  @override
  String get homeMealSuggestionOneShort => 'Please log two more meals.';

  @override
  String get homeMealSuggestionNoneShort =>
      'Please start with the first meal today.';

  @override
  String get homeNextTrainingTitle => 'Next training';

  @override
  String get homeNextTrainingToday => 'Today';

  @override
  String get homeNextTrainingTomorrow => 'Tomorrow';

  @override
  String homeNextTrainingInDays(int count) {
    return 'In $count days';
  }

  @override
  String homeNextTrainingCount(int count) {
    return '$count planned';
  }

  @override
  String get profileTestsActionLabel => 'Profile tests';

  @override
  String entryStartedFromPlanSummary(String summary) {
    return 'Started from today’s plan: $summary';
  }

  @override
  String get fifaHubAppBarTitle => 'FIFA Ranking Hub';

  @override
  String get fifaHubHeroTitle => 'Worldwide FIFA ranking and A-match tracker';

  @override
  String get fifaHubHeroSubtitle =>
      'Check the full rankings, recent results, and upcoming fixtures from FIFA official data.';

  @override
  String get fifaHubMenLabel => 'Men';

  @override
  String get fifaHubWomenLabel => 'Women';

  @override
  String get fifaHubLeaderLabel => 'Current No. 1';

  @override
  String fifaHubRankedTeamsCount(int count) {
    return '$count ranked teams';
  }

  @override
  String fifaHubConfederationCount(int count) {
    return '$count confederations';
  }

  @override
  String fifaHubRecentResultsCount(int count) {
    return '$count recent results';
  }

  @override
  String fifaHubUpcomingFixturesCount(int count) {
    return '$count upcoming fixtures';
  }

  @override
  String get fifaHubNextUpdateLabel => 'Next update';

  @override
  String get fifaHubDataSourceLabel =>
      'Source: FIFA official ranking and live match feeds';

  @override
  String get fifaHubHighlightsTitle => 'Movement highlights';

  @override
  String get fifaHubBiggestClimber => 'Biggest climber';

  @override
  String get fifaHubBiggestFaller => 'Biggest faller';

  @override
  String get fifaHubGlobalRankingTitle => 'Global ranking';

  @override
  String get fifaHubGlobalRankingSubtitle =>
      'Open sections to browse national teams without an inner scroll.';

  @override
  String get fifaHubShowAll => 'Show all';

  @override
  String get fifaHubShowLess => 'Show less';

  @override
  String get fifaHubShowAllList => 'Show full list';

  @override
  String get fifaHubCollapseList => 'Collapse list';

  @override
  String get fifaHubRecentResultsTitle => 'Recent worldwide A-match results';

  @override
  String get fifaHubRecentResultsSubtitle =>
      'Senior national-team matches filtered from FIFA match feeds.';

  @override
  String get fifaHubRecentResultsEmpty =>
      'No recent worldwide A-match results found.';

  @override
  String get fifaHubUpcomingFixturesTitle =>
      'Upcoming worldwide A-match fixtures';

  @override
  String get fifaHubUpcomingFixturesSubtitle =>
      'Upcoming senior national-team fixtures from the latest FIFA schedule window.';

  @override
  String get fifaHubUpcomingFixturesEmpty =>
      'No upcoming worldwide A-match fixtures found.';

  @override
  String get fifaHubKfaUpcomingFixturesTitle => 'KFA Korea match schedule';

  @override
  String get fifaHubKfaUpcomingFixturesSubtitle =>
      'From the Korea Football Association official Next Match feed.';

  @override
  String get fifaHubKfaUpcomingFixturesEmpty =>
      'No KFA Korea match schedule found.';

  @override
  String get fifaHubKfaRecentResultsTitle => 'KFA Korea match results';

  @override
  String get fifaHubKfaRecentResultsSubtitle =>
      'From the Korea Football Association official Match Results feed.';

  @override
  String get fifaHubKfaRecentResultsEmpty =>
      'No KFA Korea match results found.';

  @override
  String get fifaHubMatchStatusResult => 'Result';

  @override
  String get fifaHubMatchStatusLive => 'Live';

  @override
  String get fifaHubMatchStatusFixture => 'Fixture';

  @override
  String get fifaHubLoadError =>
      'Failed to load FIFA data. Pull down to refresh.';

  @override
  String get fifaHubNoData =>
      'No FIFA ranking or A-match data is available right now.';

  @override
  String get fifaMatchDetailTitle => 'Match detail';

  @override
  String get fifaMatchDetailResultSummaryTitle => 'Result summary';

  @override
  String get fifaMatchDetailFixtureSummaryTitle => 'Fixture summary';

  @override
  String get fifaMatchDetailCompetitionLabel => 'Competition';

  @override
  String get fifaMatchDetailKickoffLabel => 'Kickoff';

  @override
  String get fifaMatchDetailDateLabel => 'Date';

  @override
  String get fifaMatchDetailStageLabel => 'Stage';

  @override
  String get fifaMatchDetailVenueLabel => 'Venue';

  @override
  String get fifaMatchDetailCityLabel => 'City';

  @override
  String get fifaMatchDetailMatchIdLabel => 'Match ID';

  @override
  String get fifaMatchDetailScoreUnavailable => 'Score not confirmed';

  @override
  String get fifaMatchDetailVersusLabel => 'vs';

  @override
  String get fifaMatchDetailHomeTeamLabel => 'Home';

  @override
  String get fifaMatchDetailAwayTeamLabel => 'Away';

  @override
  String get fifaMatchDetailScorersTitle => 'Scorers';

  @override
  String get fifaMatchDetailPossessionTitle => 'Ball possession';

  @override
  String get fifaMatchDetailAdvancedLoading => 'Checking detailed records...';

  @override
  String get fifaMatchDetailAdvancedUnavailable =>
      'Scorers and ball possession were not found in the source data.';

  @override
  String get fifaMatchDetailScorersUnavailable =>
      'No scorer information found.';

  @override
  String get fifaMatchDetailPossessionUnavailable =>
      'No ball possession information found.';

  @override
  String get fifaMatchDetailUnknownScorer => 'Player not provided';

  @override
  String get fifaMatchDetailFifaSourceNote =>
      'Based on the FIFA official match API.';

  @override
  String get fifaMatchDetailKfaSourceNote =>
      'Based on the KFA home feed. Scorers and ball possession may not be provided by the source.';

  @override
  String get fifaMatchDetailOpenSource => 'Open source';

  @override
  String get fifaCountryDetailRankingSummaryTitle => 'Ranking summary';

  @override
  String get fifaCountryDetailTeamProfileTitle => 'Team profile';

  @override
  String get fifaCountryDetailCurrentRankLabel => 'Current rank';

  @override
  String get fifaCountryDetailPreviousRankLabel => 'Previous rank';

  @override
  String get fifaCountryDetailPointsLabel => 'Points';

  @override
  String get fifaCountryDetailPointChangeLabel => 'Point change';

  @override
  String get fifaCountryDetailConfederationLabel => 'Confederation';

  @override
  String get fifaCountryDetailCountryCodeLabel => 'Country code';

  @override
  String get fifaCountryDetailTeamIdLabel => 'FIFA team ID';

  @override
  String get fifaCountryDetailAbbreviationLabel => 'Abbreviation';

  @override
  String get fifaCountryDetailFoundationYearLabel => 'Founded';

  @override
  String get fifaCountryDetailCityLabel => 'City';

  @override
  String get fifaCountryDetailStadiumLabel => 'Stadium';

  @override
  String get fifaCountryDetailAddressLabel => 'Address';

  @override
  String get fifaCountryDetailProfileUnavailable =>
      'No additional FIFA team profile is available right now.';

  @override
  String get fifaCountryDetailProfileSource =>
      'Profile data from FIFA official team API.';

  @override
  String get fifaCountryDetailRecentMatchesTitle =>
      'This team\'s recent A-matches';

  @override
  String get fifaCountryDetailUpcomingMatchesTitle =>
      'This team\'s upcoming A-matches';

  @override
  String get fifaCountryDetailMatchesUnavailable =>
      'No matches for this team were found in the loaded FIFA feed.';

  @override
  String get tabGame => 'Mini Game';

  @override
  String get drawerMainScreens => 'Main screens';

  @override
  String get drawerQuickAdd => 'Quick add';

  @override
  String get drawerToolsContent => 'Tools and content';

  @override
  String get drawerTrainingPlan => 'Training plan';

  @override
  String get drawerMatch => 'Match';

  @override
  String get drawerAddTrainingSketch => 'Add training sketch';

  @override
  String get drawerNotifications => 'Notifications';

  @override
  String get drawerQuiz => 'Quiz';

  @override
  String get addEntry => 'Add Entry';

  @override
  String get editEntry => 'Edit Entry';

  @override
  String get save => 'Save';

  @override
  String get update => 'Update';

  @override
  String get add => 'Add';

  @override
  String get edit => 'Edit';

  @override
  String get newItem => 'New item';

  @override
  String get trainingDate => 'Training Date';

  @override
  String get trainingDuration => 'Training Duration';

  @override
  String minutes(Object value) {
    return '$value min';
  }

  @override
  String times(Object value) {
    return '$value times';
  }

  @override
  String get notSet => 'Not set';

  @override
  String get trainingType => 'Training Type';

  @override
  String get status => 'Training Status';

  @override
  String get statusGreat => 'Great';

  @override
  String get statusGood => 'Good';

  @override
  String get statusNormal => 'Normal';

  @override
  String get statusTough => 'Tough';

  @override
  String get statusRecovery => 'Recovery';

  @override
  String get typeTechnical => 'Technical';

  @override
  String get typePhysical => 'Physical';

  @override
  String get typeTactical => 'Tactical';

  @override
  String get typeMatch => 'Match';

  @override
  String get typeRecovery => 'Recovery';

  @override
  String get intensity => 'Intensity';

  @override
  String get condition => 'Condition';

  @override
  String get location => 'Location';

  @override
  String get program => 'Program';

  @override
  String get entryProgramDurationsTitle => 'Training program';

  @override
  String get entryProgramDurationsSubtitle =>
      'Record the program and time together.';

  @override
  String entryProgramDurationTotal(Object minutes) {
    return 'Total $minutes';
  }

  @override
  String get entryProgramDurationAddAction => 'Add program';

  @override
  String get entryProgramDurationRemoveTooltip => 'Remove program time';

  @override
  String get entryProgramDurationEmpty => 'Add a training program.';

  @override
  String get entryProgramOptionAddTooltip => 'Add program option';

  @override
  String get entryDurationOptionAddTooltip => 'Add time option';

  @override
  String get entryTodayGoalsTitle => 'Today\'s goals';

  @override
  String get entryTodayGoalAddTitle => 'Add today\'s goal';

  @override
  String get entryTodayGoalAddTooltip => 'Add goal';

  @override
  String get entryTodayGoalsSelectTooltip => 'Select today\'s goals';

  @override
  String get entryTodayGoalsSelectTitle => 'Select today\'s goals';

  @override
  String get entryTodayGoalsDone => 'Done';

  @override
  String get entryTodayGoalsNone => 'No goals selected';

  @override
  String entryTodayGoalsSelectedCount(int count) {
    return '$count selected';
  }

  @override
  String get drills => 'Session Drills';

  @override
  String get injury => 'Injury';

  @override
  String get injuryPart => 'Injury Part';

  @override
  String get painLevel => 'Pain Level (1-10)';

  @override
  String get rehab => 'Rehab';

  @override
  String get entryLesson => 'Lesson';

  @override
  String get entryLessonDetail => 'Lesson detail';

  @override
  String get entryLessonDetailHint =>
      'e.g. 1:1 dribbling, shooting group lesson';

  @override
  String get goal => 'Goal';

  @override
  String get feedback => 'Feedback';

  @override
  String get notes => 'Notes';

  @override
  String get growth => 'Growth';

  @override
  String get height => 'Height (cm)';

  @override
  String get weight => 'Weight (kg)';

  @override
  String get calendar => 'Calendar';

  @override
  String get calendarFormatMonth => 'Month';

  @override
  String get calendarFormatTwoWeeks => '2 weeks';

  @override
  String get calendarFormatWeek => 'Week';

  @override
  String get noEntries => 'No entries yet.';

  @override
  String get noEntriesForDay => 'No entries for this day.';

  @override
  String get noResults => 'No entries match your search.';

  @override
  String get searchHint => 'Search training logs';

  @override
  String get filterTitle => 'Filter logs';

  @override
  String get filterAll => 'All';

  @override
  String get filterInjuryOnly => 'Injury only';

  @override
  String get filterJumpRopeOnly => 'Jump rope days only';

  @override
  String get filterFeedbackOnly => 'Feedback only';

  @override
  String get filterLessonOnly => 'Lesson only';

  @override
  String get filterEmptyResetHint => 'Reset filters to see more entries.';

  @override
  String get filterReset => 'Reset';

  @override
  String get filterApply => 'Apply';

  @override
  String get logsLayoutCard => 'Card';

  @override
  String get logsLayoutList => 'List';

  @override
  String get logsTrainingSketchListLabel => 'Training sketch list';

  @override
  String get logsTrainingSketchTitle => 'Sketches';

  @override
  String get logsEmptyFirstEntrySubtitle =>
      'Create your first training note to start the flow.';

  @override
  String get logsEntryDeletedSnack => 'Entry deleted.';

  @override
  String get logsEntryDeleteUndoAction => 'Undo';

  @override
  String get logsDeleteUndoneSnack => 'Delete undone.';

  @override
  String get deleteEntry => 'Delete Entry';

  @override
  String get deleteConfirm => 'Delete this entry?';

  @override
  String get cancel => 'Cancel';

  @override
  String get delete => 'Delete';

  @override
  String get undo => 'Undo';

  @override
  String get statsRecent7 => 'Last 7 days';

  @override
  String get statsRecent30 => 'Last 30 days';

  @override
  String get statsTotalSessions => 'Total Sessions';

  @override
  String get statsTotalMinutes => 'Total Minutes';

  @override
  String get statsAvgIntensity => 'Avg Intensity';

  @override
  String get statsAvgCondition => 'Avg Condition';

  @override
  String get statsInjuryCount => 'Injury Count';

  @override
  String get statsAvgPain => 'Avg Pain';

  @override
  String get statsRehabCount => 'Rehab Count';

  @override
  String get statsSummary => 'Summary';

  @override
  String get statsTypeRatio => 'Training Program Ratio';

  @override
  String get statsWeeklyMinutes => 'Weekly Minutes';

  @override
  String get statsLoadingMessage => 'Loading statistics...';

  @override
  String get statsLoadFailedMessage =>
      'There was a problem loading statistics.';

  @override
  String get statsFallbackMessage =>
      'Some stats failed to compute, showing fallback view.';

  @override
  String get statsTrainingTab => 'Training';

  @override
  String get statsMatchesTab => 'Matches';

  @override
  String get statsNoMatchesSelectedPeriod =>
      'No matches in the selected period.';

  @override
  String get statsRangePickerHelp => 'Select period';

  @override
  String get statsWorkoutDaysNone => 'Workout days: none';

  @override
  String statsWorkoutDaysValue(Object days) {
    return 'Workout days: $days';
  }

  @override
  String get statsGrowthChartTitle => 'Growth Chart';

  @override
  String get statsActualLabel => 'Actual';

  @override
  String get statsTargetLabel => 'Target';

  @override
  String get statsActualTimeDailyLabel => 'Actual time (daily)';

  @override
  String get statsAverageTargetTimeDailyLabel => 'Average target time (daily)';

  @override
  String get statsAllMatchRecordsTitle => 'All Match Records';

  @override
  String statsMatchMinutesPlayedValue(Object minutes) {
    return '$minutes min';
  }

  @override
  String get statsResultUnset => 'Result unset';

  @override
  String get statsOutcomeWin => 'Win';

  @override
  String get statsOutcomeDraw => 'Draw';

  @override
  String get statsOutcomeLoss => 'Loss';

  @override
  String get statsDurationZeroMinutes => '0m';

  @override
  String statsDurationMinutes(Object minutes) {
    return '$minutes min';
  }

  @override
  String statsDurationHours(Object hours) {
    return '$hours h';
  }

  @override
  String statsDurationHoursMinutes(Object hours, Object minutes) {
    return '$hours h $minutes min';
  }

  @override
  String get statsCompactDurationZero => '0h';

  @override
  String statsCompactDurationMinutes(Object minutes) {
    return '$minutes m';
  }

  @override
  String statsCompactDurationHours(Object hours) {
    return '$hours h';
  }

  @override
  String statsCompactDurationHoursMinutes(Object hours, Object minutes) {
    return '$hours h $minutes m';
  }

  @override
  String get statsComparisonCurrentLabel => 'Now';

  @override
  String get statsComparisonAverageLabel => 'Avg';

  @override
  String get growthHistory => 'Growth History';

  @override
  String level(Object value) {
    return 'Level $value';
  }

  @override
  String levelUpRemaining(Object value) {
    return '$value more to level up';
  }

  @override
  String get missionComplete => 'Mission complete! Weekly goal achieved!';

  @override
  String get missionKeepGoing =>
      'Great job! Just a bit more to hit 3 sessions this week!';

  @override
  String get onboard1 => 'Log today’s training';

  @override
  String get onboard2 => 'Track your growth history';

  @override
  String get onboard3 => 'Level up with goals';

  @override
  String get next => 'Next';

  @override
  String get start => 'Start';

  @override
  String get heroMessage => 'Great work today! Logging helps you grow faster.';

  @override
  String get logsHeadline1 => 'Training';

  @override
  String get logsHeadline2 => 'Sessions';

  @override
  String get entryHeadline1 => 'Log';

  @override
  String get entryHeadline2 => 'Your Training';

  @override
  String get statsHeadline1 => 'Progress';

  @override
  String get statsHeadline2 => 'Overview';

  @override
  String get statsMatchTrendStable => 'Recent match trend is stable.';

  @override
  String get statsMatchTrendNeedsAttention => 'Result trend needs attention.';

  @override
  String statsMatchInsightMessage(
      int count,
      Object primaryLabel,
      int primaryValue,
      Object secondaryLabel,
      int secondaryValue,
      Object direction) {
    return 'Across $count matches: $primaryLabel $primaryValue · $secondaryLabel $secondaryValue. $direction';
  }

  @override
  String statsReportTrainingTitle(Object sport) {
    return '$sport Growth Summary';
  }

  @override
  String statsReportSummarySentence(
      Object totalTime, int sessions, int streak) {
    String _temp0 = intl.Intl.pluralLogic(
      sessions,
      locale: localeName,
      other: '$sessions sessions',
      one: '1 session',
    );
    String _temp1 = intl.Intl.pluralLogic(
      streak,
      locale: localeName,
      other: '$streak-day streak',
      one: '1-day streak',
    );
    return 'This period has $totalTime across $_temp0 with a $_temp1.';
  }

  @override
  String statsReportActivityPeriodSummary(int activeDays, int periodDays) {
    return 'Logged on $activeDays/$periodDays days in the selected period';
  }

  @override
  String get statsReportInsightTitle => 'Period Report';

  @override
  String get statsReportTargetLabel => 'Target';

  @override
  String get statsReportTargetProgressLabel => 'Target achievement';

  @override
  String statsReportTargetPercentValue(int percent) {
    return '$percent%';
  }

  @override
  String get statsReportNoTargetValue => 'No baseline';

  @override
  String get statsReportSessionsLabel => 'Sessions';

  @override
  String statsReportSessionsValue(int count) {
    return '$count';
  }

  @override
  String get statsReportTotalTimeLabel => 'Total time';

  @override
  String get statsReportTrainingRhythmLabel => 'Training rhythm';

  @override
  String statsReportTrainingRhythmValue(
      int sessions, int activeDays, int periodDays) {
    return '$sessions sessions · $activeDays/$periodDays days';
  }

  @override
  String statsReportTrainingRhythmCompactValue(
      int sessions, int activeDays, int periodDays, int streak) {
    return '$sessions sessions · $activeDays/$periodDays days · $streak-day streak';
  }

  @override
  String get statsReportLessonCountLabel => 'Lessons';

  @override
  String statsReportLessonCountValue(int count) {
    return '$count';
  }

  @override
  String get statsReportActiveDaysLabel => 'Logged days';

  @override
  String statsReportActiveDaysValue(int activeDays, int periodDays) {
    return '$activeDays/$periodDays days';
  }

  @override
  String get statsReportPlanExecutionLabel => 'Plan execution';

  @override
  String get statsReportTargetPlanLabel => 'Target / Plan';

  @override
  String statsReportTargetPlanValue(Object target, Object plan) {
    return 'Target $target · Plan $plan';
  }

  @override
  String get statsReportNoPlanValue => 'No plan';

  @override
  String get statsReportFocusLabel => 'Focus';

  @override
  String get statsReportDefaultFocus => 'Fundamentals';

  @override
  String get statsReportExpandDetailsAction => 'Show details';

  @override
  String get statsReportCollapseDetailsAction => 'Collapse';

  @override
  String statsReportFocusStreakValue(Object focus, int days) {
    return '$focus · $days-day streak';
  }

  @override
  String get statsReportStreakLabel => 'Consistency';

  @override
  String statsReportStreakValue(int days) {
    return '$days-day streak';
  }

  @override
  String get statsReportMealCoverageLabel => 'Meal coverage';

  @override
  String statsReportMealCoverageValue(
      int mealDays, int periodDays, int fullMealDays) {
    return '$mealDays/$periodDays days · 3 meals $fullMealDays days';
  }

  @override
  String get statsReportConditionLabel => 'Condition';

  @override
  String statsReportConditionValue(
      Object intensity, Object mood, int injuryDays) {
    return 'Load $intensity · Mood $mood · Injury ${injuryDays}d';
  }

  @override
  String get statsReportConditioningLabel => 'Conditioning';

  @override
  String statsReportConditioningValue(int minutes, int count) {
    return '$minutes min · $count reps';
  }

  @override
  String statsReportInsightRecovery(int injuryDays, Object mood) {
    return 'There are $injuryDays injury days and average mood is $mood. Check recovery load and pain changes first in the next log.';
  }

  @override
  String statsReportInsightNeedsVolume(
      Object sport, int percent, int activeDays, int periodDays) {
    return '$sport volume is $percent% of target. You logged $activeDays/$periodDays days, so add shorter sessions more often next period.';
  }

  @override
  String statsReportInsightMealGap(int mealDays, int activeDays) {
    return 'Meals were logged on $mealDays of $activeDays training days. Log meals with training days to judge recovery better.';
  }

  @override
  String statsReportInsightNoConditioning(
      Object primaryLabel, Object secondaryLabel) {
    return '$primaryLabel/$secondaryLabel records are empty. Add sport-specific conditioning to read growth trends more accurately.';
  }

  @override
  String statsReportInsightBalanced(
      Object sport, int activeDays, int periodDays) {
    return '$sport was logged on $activeDays/$periodDays days, with conditioning and meal flow visible. Next period, compare the quality of your most frequent focus.';
  }

  @override
  String statsSecondaryConditioningNoRecords(Object label) {
    return 'No $label detail records in the selected period.';
  }

  @override
  String statsSecondaryConditioningDailyTotals(Object label) {
    return 'Daily $label totals';
  }

  @override
  String statsPrimaryConditioningStatsTitle(Object label) {
    return '$label Stats';
  }

  @override
  String statsPrimaryConditioningNoRecords(Object label) {
    return 'No $label count or time recorded in the selected period.';
  }

  @override
  String statsPrimaryConditioningTooltipCount(Object label, int count) {
    return '$label $count reps';
  }

  @override
  String statsPrimaryConditioningTooltipMinutes(Object label, int minutes) {
    return '$label $minutes min';
  }

  @override
  String statsPrimaryConditioningDailyCount(Object label) {
    return 'Daily $label count';
  }

  @override
  String statsPrimaryConditioningDailyMinutes(Object label) {
    return 'Daily $label time';
  }

  @override
  String statsPrimaryConditioningTotalCount(int count) {
    return 'Total $count reps';
  }

  @override
  String statsPrimaryConditioningTotalMinutes(int minutes) {
    return 'Total $minutes min';
  }

  @override
  String statsPrimaryConditioningBestCount(int month, int day, int count) {
    return 'Best $month/$day · $count reps';
  }

  @override
  String statsPrimaryConditioningBestMinutes(int month, int day, int minutes) {
    return 'Best $month/$day · $minutes min';
  }

  @override
  String statsMatchFormTitle(Object sport) {
    return '$sport Match Report';
  }

  @override
  String get statsMatchSummaryTitle => 'Match Summary';

  @override
  String get statsMatchResultGroupTitle => 'Result Metrics';

  @override
  String get statsMatchPersonalGroupTitle => 'Personal Contribution';

  @override
  String get statsMatchTotalMatchesLabel => 'Matches';

  @override
  String statsMatchTotalMatchesValue(int count) {
    return '$count';
  }

  @override
  String get statsMatchRecordLabel => 'Record';

  @override
  String statsMatchRecordValue(int wins, int draws, int losses) {
    return '$wins-$draws-$losses';
  }

  @override
  String get statsMatchTypeLabel => 'Match type';

  @override
  String get statsMatchGoalsLabel => 'Scoreline';

  @override
  String get statsMatchPersonalTotalLabel => 'Personal total';

  @override
  String get statsMatchPersonalDetailLabel => 'Detail contribution';

  @override
  String get statsMatchFormInsightTitle => 'Match Flow';

  @override
  String get statsMatchFormLabel => 'Recent form';

  @override
  String get statsMatchFormUnsetValue => 'No results';

  @override
  String get statsMatchUnsetValue => 'Not set';

  @override
  String get statsMatchOutcomeWinShort => 'W';

  @override
  String get statsMatchOutcomeDrawShort => 'D';

  @override
  String get statsMatchOutcomeLossShort => 'L';

  @override
  String get statsMatchWinRateLabel => 'Win rate';

  @override
  String statsMatchWinRateValue(int percent) {
    return '$percent%';
  }

  @override
  String get statsMatchCompletedMatchesLabel => 'Results recorded';

  @override
  String statsMatchCompletedMatchesValue(int completed, int total) {
    return '$completed/$total';
  }

  @override
  String get statsMatchGoalDifferenceLabel => 'Goal difference';

  @override
  String get statsMatchAverageScoreLabel => 'Avg score';

  @override
  String statsMatchAverageScoreValue(Object scored, Object conceded) {
    return '$scored:$conceded';
  }

  @override
  String get statsMatchPersonalPerMatchLabel => 'Personal per match';

  @override
  String statsMatchPersonalPerMatchValue(Object primaryLabel,
      Object primaryValue, Object secondaryLabel, Object secondaryValue) {
    return '$primaryLabel $primaryValue · $secondaryLabel $secondaryValue';
  }

  @override
  String statsMatchPerUnitLabel(int minutes) {
    return 'Per $minutes min';
  }

  @override
  String statsMatchPerUnitValue(Object primaryLabel, Object primaryValue,
      Object secondaryLabel, Object secondaryValue) {
    return '$primaryLabel $primaryValue · $secondaryLabel $secondaryValue';
  }

  @override
  String get statsMatchMinutesLabel => 'Minutes played';

  @override
  String get statsMatchNoMinutesValue => 'No minutes';

  @override
  String statsMatchFormInsightNoResults(Object sport) {
    return '$sport match results are still missing. Add scores and personal records together to calculate form.';
  }

  @override
  String statsMatchFormInsightPositive(Object sport, Object form, int winRate) {
    return 'Recent $sport form is $form, with a $winRate% win rate. Repeat the personal records that led to your strengths next match.';
  }

  @override
  String statsMatchFormInsightNeedsWork(
      Object sport, Object form, int winRate) {
    return 'Recent $sport form is $form, with a $winRate% win rate. Check where result patterns and personal records drop together.';
  }

  @override
  String get statsCompetitionDashboardTitle => 'Competition board';

  @override
  String get statsCompetitionLeagueSectionTitle => 'League competitions';

  @override
  String get statsCompetitionTournamentSectionTitle =>
      'Tournament competitions';

  @override
  String statsCompetitionProgressValue(int recorded, int total) {
    return '$recorded/$total';
  }

  @override
  String statsCompetitionMoreCount(int count) {
    return '$count more';
  }

  @override
  String get statsCompetitionOpponentUnset => 'Opponent unset';

  @override
  String get averageComparisonProfileMissingTitle =>
      'Enter age and sport experience';

  @override
  String get averageComparisonProfileMissingMessage =>
      'Average comparison is hidden because age and sport experience are missing. Add birth date and sport start date in profile.';

  @override
  String get averageComparisonOpenProfileAction => 'Open Profile';

  @override
  String get averageComparisonTitle => 'Average Comparison';

  @override
  String get averageComparisonReferenceAction => 'References';

  @override
  String get averageComparisonHiddenMessage =>
      'Average comparison is hidden because age/experience is not set.';

  @override
  String get averageComparisonHeightLabel => 'Height';

  @override
  String get averageComparisonWeightLabel => 'Weight';

  @override
  String get averageComparisonNotSet => 'Not set';

  @override
  String get averageComparisonHiddenValue => 'Hidden';

  @override
  String get averageComparisonUnavailableValue => 'N/A';

  @override
  String get averageComparisonHiddenGap => 'Hidden';

  @override
  String averageComparisonGapValue(Object gap) {
    return '$gap vs avg';
  }

  @override
  String averageComparisonConditioningPerSessionLabel(Object metric) {
    return '$metric/session';
  }

  @override
  String get averageComparisonFootballOnlyTitle =>
      'Football average comparison hidden';

  @override
  String get averageComparisonFootballOnlyMessage =>
      'This average comparison uses soccer juggling reference ranges, so it is not shown for the current sport.';

  @override
  String get durationNotSet => 'No time';

  @override
  String get defaultLocation1 => 'School field';

  @override
  String get defaultLocation2 => 'Community field';

  @override
  String get defaultLocation3 => 'Indoor gym';

  @override
  String get defaultProgram1 => 'Fundamentals';

  @override
  String get defaultProgram2 => 'Physical';

  @override
  String get defaultProgram3 => 'Tactical';

  @override
  String get defaultProgram4 => 'Recovery';

  @override
  String get sport => 'Sport';

  @override
  String get sportFootball => 'Football';

  @override
  String get sportBaseball => 'Baseball';

  @override
  String get sportBasketball => 'Basketball';

  @override
  String get sportTennis => 'Tennis';

  @override
  String get footballGoalDribbling => 'Dribbling';

  @override
  String get footballGoalPassingAccuracy => 'Passing Accuracy';

  @override
  String get footballGoalShooting => 'Shooting';

  @override
  String get footballGoalFitness => 'Fitness';

  @override
  String get footballGoalDefensivePositioning => 'Defensive Positioning';

  @override
  String get footballGoalFirstTouch => 'First Touch';

  @override
  String get baseballProgramThrowing => 'Throwing';

  @override
  String get baseballProgramBatting => 'Batting';

  @override
  String get baseballProgramFielding => 'Fielding';

  @override
  String get baseballProgramBaseRunning => 'Base Running';

  @override
  String get baseballProgramConditioning => 'Conditioning';

  @override
  String get baseballProgramRecovery => 'Recovery';

  @override
  String get baseballGoalThrowingAccuracy => 'Throwing Accuracy';

  @override
  String get baseballGoalBattingContact => 'Batting Contact';

  @override
  String get baseballGoalFieldingGlove => 'Fielding Glove';

  @override
  String get baseballGoalBaseRunning => 'Base Running';

  @override
  String get baseballGoalReactionSpeed => 'Reaction Speed';

  @override
  String get baseballGoalGameAwareness => 'Game Awareness';

  @override
  String get basketballProgramBallHandling => 'Ball Handling';

  @override
  String get basketballProgramShooting => 'Shooting';

  @override
  String get basketballProgramPassing => 'Passing';

  @override
  String get basketballProgramDefense => 'Defense';

  @override
  String get basketballProgramConditioning => 'Conditioning';

  @override
  String get basketballProgramRecovery => 'Recovery';

  @override
  String get basketballGoalBallHandling => 'Ball Handling';

  @override
  String get basketballGoalShootingForm => 'Shooting Form';

  @override
  String get basketballGoalPassingChoices => 'Passing Choices';

  @override
  String get basketballGoalDefensiveFootwork => 'Defensive Footwork';

  @override
  String get basketballGoalRebounding => 'Rebounding';

  @override
  String get basketballGoalFitness => 'Fitness';

  @override
  String get tennisProgramStroke => 'Stroke';

  @override
  String get tennisProgramServe => 'Serve';

  @override
  String get tennisProgramFootwork => 'Footwork';

  @override
  String get tennisProgramMatchPlay => 'Match Play';

  @override
  String get tennisProgramConditioning => 'Conditioning';

  @override
  String get tennisProgramRecovery => 'Recovery';

  @override
  String get tennisGoalServeConsistency => 'Serve Consistency';

  @override
  String get tennisGoalForehand => 'Forehand';

  @override
  String get tennisGoalBackhand => 'Backhand';

  @override
  String get tennisGoalFootwork => 'Footwork';

  @override
  String get tennisGoalRallyConsistency => 'Rally Consistency';

  @override
  String get tennisGoalMatchStrategy => 'Match Strategy';

  @override
  String get baseballConditioningPrimary => 'Sprint work';

  @override
  String get baseballConditioningSecondary => 'Catch play';

  @override
  String get baseballConditioningDetailTitle => 'Catch play details';

  @override
  String get baseballConditioningDetailShortThrow => 'Short throws';

  @override
  String get baseballConditioningDetailLongThrow => 'Long throws';

  @override
  String get baseballConditioningDetailGrounder => 'Grounders';

  @override
  String get baseballConditioningDetailFlyBall => 'Fly balls';

  @override
  String get baseballConditioningDetailTransfer => 'Quick transfer';

  @override
  String get baseballConditioningDetailCore => 'Core balance';

  @override
  String get basketballConditioningPrimary => 'Shuttle run';

  @override
  String get basketballConditioningSecondary => 'Ball handling';

  @override
  String get basketballConditioningDetailTitle => 'Ball handling details';

  @override
  String get basketballConditioningDetailRightHand => 'Right hand';

  @override
  String get basketballConditioningDetailLeftHand => 'Left hand';

  @override
  String get basketballConditioningDetailCrossover => 'Crossover';

  @override
  String get basketballConditioningDetailChangePace => 'Change of pace';

  @override
  String get basketballConditioningDetailShootingPocket => 'Shooting pocket';

  @override
  String get basketballConditioningDetailPressure => 'Under pressure';

  @override
  String get tennisConditioningPrimary => 'Footwork';

  @override
  String get tennisConditioningSecondary => 'Wall rally';

  @override
  String get tennisConditioningDetailTitle => 'Wall rally details';

  @override
  String get tennisConditioningDetailForehand => 'Forehand';

  @override
  String get tennisConditioningDetailBackhand => 'Backhand';

  @override
  String get tennisConditioningDetailServeToss => 'Serve toss';

  @override
  String get tennisConditioningDetailVolley => 'Volley';

  @override
  String get tennisConditioningDetailApproach => 'Approach';

  @override
  String get tennisConditioningDetailRecovery => 'Recovery step';

  @override
  String sportConditioningRecordTitle(String label) {
    return '$label Record';
  }

  @override
  String sportConditioningMinutesLabel(String label) {
    return '$label time (min)';
  }

  @override
  String sportConditioningCountLabel(String label) {
    return '$label count';
  }

  @override
  String sportConditioningMemoLabel(String label) {
    return '$label memo';
  }

  @override
  String sportConditioningMemoHint(String label) {
    return 'Write what you felt during $label.';
  }

  @override
  String sportConditioningEmpty(String primary, String secondary) {
    return 'No $primary/$secondary record';
  }

  @override
  String get defaultDrill1 => 'Rondo 5:2';

  @override
  String get defaultDrill2 => '1v1 defense';

  @override
  String get defaultDrill3 => 'Shooting reps';

  @override
  String get defaultDrill4 => 'Sprints';

  @override
  String get defaultInjury1 => 'Hamstring';

  @override
  String get defaultInjury2 => 'Knee';

  @override
  String get defaultInjury3 => 'Ankle';

  @override
  String get defaultInjury4 => 'Thigh';

  @override
  String get defaultInjury5 => 'Calf';

  @override
  String get languageEnglish => 'English';

  @override
  String get languageKorean => 'Korean';

  @override
  String get languageJapanese => 'Japanese';

  @override
  String get languageSystemDefault => 'System default';

  @override
  String get settings => 'Settings';

  @override
  String get settingsGeneralSection => 'General';

  @override
  String get settingsSoundEffectsTitle => 'Sound effects';

  @override
  String get settingsSoundEffectsSubtitle =>
      'Play sounds for buttons, rewards, and other in-app actions.';

  @override
  String get settingsTutorialReplayTitle => 'Replay tutorial';

  @override
  String get settingsTutorialReplaySubtitle =>
      'Return home and restart the coach marks from the beginning.';

  @override
  String get settingsTutorialReplayReady => 'The tutorial is ready to replay.';

  @override
  String get settingsNewsFilterTitle => 'News Filter';

  @override
  String get settingsNewsBlockedDomainsTitle => 'Blocked ad domains';

  @override
  String settingsNewsBlockedDomainsCount(int count) {
    return '$count items';
  }

  @override
  String get settingsNewsBlockedDomainsManageTitle =>
      'Manage blocked ad domains';

  @override
  String get settingsNewsBlockedDomainsExample =>
      'Example: example.com (domain only, no path)';

  @override
  String get settingsJournalOptionManagerTitle => 'Journal option manager';

  @override
  String settingsOptionItemsCount(int count) {
    return '$count items';
  }

  @override
  String get settingsDurationOptionsTitle => 'Duration options';

  @override
  String get settingsDurationOptionsManageTitle => 'Manage duration options';

  @override
  String get settingsProgramOptionsTitle => 'Program options';

  @override
  String get settingsProgramOptionsManageTitle => 'Manage program options';

  @override
  String get settingsTrainingGoalOptionsTitle => 'Training goal options';

  @override
  String get settingsTrainingGoalOptionsManageTitle =>
      'Manage training goal options';

  @override
  String get settingsInjuryPartOptionsTitle => 'Injury part options';

  @override
  String get settingsInjuryPartOptionsManageTitle =>
      'Manage injury part options';

  @override
  String get settingsOptionEditTitle => 'Edit option';

  @override
  String get settingsOptionAddTitle => 'Add option';

  @override
  String get settingsIntOptionEditTitle => 'Edit minutes';

  @override
  String get settingsIntOptionAddTitle => 'Add minutes';

  @override
  String get settingsApiUsageTitle => 'APIs used in this app';

  @override
  String get settingsApiUsageSubtitle =>
      'This app uses the following public or consent-based APIs. Quotas can change by provider, so the app caches where possible and limits background refreshes.';

  @override
  String get settingsApiTrafficLabel => 'Traffic';

  @override
  String get settingsApiLegalLabel => 'Legal use';

  @override
  String get settingsApiOpenMeteoProvider =>
      'Open-Meteo weather, air quality, geocoding, and archive APIs';

  @override
  String get settingsApiOpenMeteoTraffic =>
      'Free public service with fair-use expectations; requests are cached for weather views and refreshed only when needed.';

  @override
  String get settingsApiOpenMeteoLegal =>
      'Used under Open-Meteo public API terms with attribution/source surfaces in weather features.';

  @override
  String get settingsApiKoreaPublicProvider =>
      'Korea public data APIs for weather and air quality';

  @override
  String get settingsApiKoreaPublicTraffic =>
      'Quota depends on the issued public-data service key and agency limits.';

  @override
  String get settingsApiKoreaPublicLegal =>
      'Used with an issued service key under the Korean public data portal terms.';

  @override
  String get settingsApiKakaoProvider => 'Kakao Local search/geocoding API';

  @override
  String get settingsApiKakaoTraffic =>
      'Quota depends on the registered Kakao Developers app and REST API key.';

  @override
  String get settingsApiKakaoLegal =>
      'Used only when the app key/platform configuration permits it under Kakao Developers terms.';

  @override
  String get settingsApiFootballProvider =>
      'Football schedule, standings, and World Cup source pages/APIs';

  @override
  String get settingsApiFootballTraffic =>
      'Read-only fetches are cached and retried conservatively; availability depends on the source service.';

  @override
  String get settingsApiFootballLegal =>
      'Uses public fixture/standings data for in-app display and links/source labels where provided.';

  @override
  String get settingsApiNewsProvider => 'RSS feeds and news fetch helpers';

  @override
  String get settingsApiNewsTraffic =>
      'RSS/news responses are cached and filtered to reduce repeated traffic.';

  @override
  String get settingsApiNewsLegal =>
      'Shows article metadata and opens the original publisher page instead of republishing full articles.';

  @override
  String get settingsApiGoogleProvider => 'Google Drive and Firebase services';

  @override
  String get settingsApiGoogleTraffic =>
      'Traffic follows the connected Google Cloud project and user Drive quota.';

  @override
  String get settingsApiGoogleLegal =>
      'Drive access uses user consent and app backup scopes for the user\'s own files.';

  @override
  String get account => 'Account';

  @override
  String get signInWithGoogle => 'Sign in with Google';

  @override
  String get signInFailed => 'Sign-in failed. Please try again.';

  @override
  String get signedIn => 'Signed in';

  @override
  String get signOut => 'Sign out';

  @override
  String get webLoginNotAvailable => 'Google login is not available on web.';

  @override
  String get backupToDrive => 'Back up data';

  @override
  String get restoreFromDrive => 'Import latest data';

  @override
  String get restorePreviousBackup => 'Import previous backup';

  @override
  String get restorePreviousBackupInfo =>
      'Previous backup import is a recovery tool for undoing a recent import or checking an older state. Confirm that current data will be replaced by the previous backup before running it.';

  @override
  String get backupConfirm => 'Create a new backup on Google Drive?';

  @override
  String get restoreConfirm =>
      'Import the latest data from Google Drive with safe merge? Local-only records are kept.';

  @override
  String get restorePreviousConfirm =>
      'Import the previous Google Drive backup? Current data will be replaced.';

  @override
  String get backupSuccess => 'Backup completed.';

  @override
  String get backupFailed => 'Backup failed. Please try again.';

  @override
  String get restoreSuccess => 'Data imported.';

  @override
  String get restoreFailed => 'Failed to import data. Please try again.';

  @override
  String get restorePreviousSuccess => 'Previous backup imported.';

  @override
  String get restorePreviousFailed =>
      'Failed to import the previous backup. Please try again.';

  @override
  String get backupInProgress => 'Backing up...';

  @override
  String get restoreInProgress => 'Importing data...';

  @override
  String get backupDailyEnabled => 'Daily backup enabled';

  @override
  String get backupDailyDesc => 'Backs up once per day when the app opens';

  @override
  String get backupAutoOnSave => 'Auto backup on save';

  @override
  String get backupAutoOnSaveDesc =>
      'Backs up whenever you add or update a log';

  @override
  String get lastBackup => 'Last backup';

  @override
  String get timeJustNow => 'Just now';

  @override
  String timeMinutesAgo(int count) {
    return '$count min ago';
  }

  @override
  String timeHoursAgo(int count) {
    return '$count hr ago';
  }

  @override
  String get timeYesterday => 'Yesterday';

  @override
  String get restoreLocalBackup => 'Undo latest import';

  @override
  String get restoreLocalConfirm =>
      'Undo the changes made by the latest import on this device? This will replace current data.';

  @override
  String get restoreLocalSuccess => 'The latest import was undone.';

  @override
  String get restoreLocalFailed =>
      'Failed to undo the latest import. Please try again.';

  @override
  String get localBackup => 'Local safety backup';

  @override
  String get driveBackupLockedAccountChanged =>
      'The Google account changed. Choose how this device should use the connected account before any backup can run.';

  @override
  String get driveBackupRemoteOverwriteBlocked =>
      'Backup was stopped because this device has no player data but the Drive backup already contains data. Import the Drive backup first.';

  @override
  String get driveBackupOwnerMismatch =>
      'Backup was stopped because the Drive backup belongs to a different Google account. Reconnect the correct account first.';

  @override
  String get driveBackupDatasetMismatch =>
      'This Drive backup belongs to a different data set. Automatic merge was stopped.';

  @override
  String get driveBackupPlayerMismatch =>
      'This Drive backup belongs to a different player. Automatic merge was stopped.';

  @override
  String get driveAccountSwitchImportAction => 'Import this account\'s backup';

  @override
  String get driveAccountSwitchStartEmptyAction =>
      'Start empty with this account';

  @override
  String get driveAccountSwitchImportTitle => 'Use connected account data?';

  @override
  String get driveAccountSwitchImportBody =>
      'The connected Google account is different from the saved player backup account. Import this account\'s latest Drive backup first; current device data will be replaced after a local safety copy is kept.';

  @override
  String get driveAccountSwitchStartEmptyTitle =>
      'Start as a new player account?';

  @override
  String get driveAccountSwitchStartEmptyBody =>
      'This will clear player data on this device and connect the current Google account as the player backup account. A local safety copy is kept so you can undo the import from this device.';

  @override
  String get driveAccountSwitchImportSuccess =>
      'This account\'s backup was imported.';

  @override
  String get driveAccountSwitchStartEmptySuccess =>
      'Started with an empty player dataset for this account.';

  @override
  String get driveAccountSwitchImportFailed =>
      'Could not import this account\'s backup. Please try again.';

  @override
  String get driveAccountSwitchStartEmptyFailed =>
      'Could not start with this account. Please try again.';

  @override
  String get driveAccountSwitchNoRemoteBackup =>
      'No Drive backup was found for the connected account. Start empty with this account or reconnect the saved player account.';

  @override
  String get driveLegacyAccountImportAction =>
      'Verify this account and import data';

  @override
  String get driveLegacyAccountImportTitle => 'Verify this account backup?';

  @override
  String get driveLegacyAccountImportBody =>
      'This device has an older account connection without a Google account ID. Backups remain protected until you import the latest Drive backup for the connected account. A local safety copy is kept before current device data is replaced.';

  @override
  String get driveLegacyAccountImportSuccess =>
      'Account verified and Drive backup imported.';

  @override
  String get backupVersionUnsupported =>
      'This backup was created by a newer app version and cannot be imported here yet. Update the app and try again.';

  @override
  String get backupPayloadInvalid =>
      'The backup data format could not be verified, so the import was stopped. Try a different backup.';

  @override
  String get loginRequired => 'Please sign in to Google to use Drive backup.';

  @override
  String get signOutDone => 'Signed out.';

  @override
  String get voiceNotAvailable =>
      'Voice input is not available on this device.';

  @override
  String get voiceInputStartTooltip => 'Voice input';

  @override
  String get voiceInputStopTooltip => 'Stop voice input';

  @override
  String get voiceListeningStatus => 'Voice input active';

  @override
  String get liftingRecord => 'Lifting Record';

  @override
  String get liftingByPart => 'Lifting (reps by part)';

  @override
  String get liftingMinutesLabel => 'Lifting time (min)';

  @override
  String get liftingPartInfront => 'Infront';

  @override
  String get liftingPartInside => 'Inside';

  @override
  String get liftingPartOutside => 'Outside';

  @override
  String get liftingPartMuple => 'Knee';

  @override
  String get liftingPartHead => 'Head';

  @override
  String get liftingPartChest => 'Chest';

  @override
  String get liftingByBodyPartTitle => 'Lifting by Body Part';

  @override
  String get liftingNoRecords => 'No lifting records.';

  @override
  String get legacyLabel => 'Legacy';

  @override
  String get oldLabel => 'Old';

  @override
  String get confirm => 'Confirm';

  @override
  String get close => 'Close';

  @override
  String get language => 'Language';

  @override
  String get theme => 'Theme';

  @override
  String get themeSystem => 'System';

  @override
  String get themeLight => 'Light';

  @override
  String get themeDark => 'Dark';

  @override
  String get defaults => 'Defaults';

  @override
  String get defaultDuration => 'Default Duration';

  @override
  String get defaultIntensity => 'Default Intensity';

  @override
  String get defaultCondition => 'Default Condition';

  @override
  String get defaultLocation => 'Default Location';

  @override
  String get defaultProgram => 'Default Program';

  @override
  String get notifications => 'Notifications';

  @override
  String get notificationSettingsAction => 'Settings';

  @override
  String get notificationSettingsTitle => 'Alert settings';

  @override
  String get notificationSettingsCloseTooltip => 'Close alert settings';

  @override
  String get notificationRefreshAction => 'Refresh';

  @override
  String get notificationMuteStatusPaused => 'Alerts are currently paused.';

  @override
  String get notificationMuteControlTitle => 'Repeating alert control';

  @override
  String get notificationMuteControlSubtitle =>
      'Temporarily mute alerts or resume anytime.';

  @override
  String get notificationMute8HoursAction => 'Mute 8h';

  @override
  String get notificationResumeAction => 'Resume';

  @override
  String get notificationAllSettingsTitle => 'All notifications';

  @override
  String get notificationTrainingPlanVibrationTitle =>
      'Training plan vibration';

  @override
  String get notificationXpAlertSettingsTitle => 'XP alerts';

  @override
  String get notificationXpAlertSettingsSubtitle =>
      'Show an alert whenever XP is earned.';

  @override
  String get notificationLevelUpSettingsTitle => 'Level-up notifications';

  @override
  String notificationFamilySectionTitle(int count) {
    return '$count parent sync alert(s)';
  }

  @override
  String get notificationFamilyEmpty => 'No parent sync alerts yet.';

  @override
  String notificationFixtureSectionTitle(int count) {
    return '$count fixture alert(s)';
  }

  @override
  String get notificationFixtureEmpty => 'No fixture alerts yet.';

  @override
  String get notificationFamilySettingsTitle => 'Parent sync alerts';

  @override
  String get notificationFamilySettingsSubtitle =>
      'Notify when player logs or guardian feedback/rewards sync.';

  @override
  String get notificationLeagueFixtureSettingsTitle =>
      'Favorite team match alerts';

  @override
  String get notificationLeagueFixtureSettingsSubtitle =>
      'Notify before loaded fixtures for selected favorite teams.';

  @override
  String get notificationOverviewOnTitle => 'Phone notifications are on';

  @override
  String get notificationOverviewOffTitle => 'Phone notifications are off';

  @override
  String get notificationOverviewAllOnSubtitle =>
      'Device notifications and in-app alerts are both enabled.';

  @override
  String get notificationOverviewAppOffSubtitle =>
      'Device notifications are on, but all in-app alerts are off.';

  @override
  String get notificationOverviewPermissionOffSubtitle =>
      'Allow notifications for this app in Settings > Notifications to receive alerts.';

  @override
  String get notificationOverviewPausedLabel => 'Paused';

  @override
  String notificationOverviewCountLabel(int count) {
    return '$count alerts';
  }

  @override
  String get notificationFeedTitle => 'Alert feed';

  @override
  String notificationFeedSubtitle(int count) {
    return 'Alerts shown: $count';
  }

  @override
  String get notificationCategoryTrainingPlan => 'Training';

  @override
  String get notificationCategoryWeather => 'Weather';

  @override
  String get notificationCategoryClubTraining => 'Club training';

  @override
  String get notificationCategoryFixture => 'Matches';

  @override
  String get notificationCategoryXp => 'XP';

  @override
  String get notificationCategoryFamily => 'Family';

  @override
  String notificationCategorySectionTitle(Object category, int count) {
    return '$category ($count)';
  }

  @override
  String get notificationFeedEmptyTitle => 'No alerts to show.';

  @override
  String get notificationFeedEmptySubtitle =>
      'Training, weather, and match alerts will appear here.';

  @override
  String get notificationInactivitySettingsTitle => 'Inactivity reminders';

  @override
  String get notificationInactivityOnTitle => 'Inactivity reminder is on';

  @override
  String get notificationInactivityOffTitle => 'Inactivity reminder is off';

  @override
  String notificationInactivityOnSubtitle(int days, Object time) {
    return 'Alert at $time after $days inactive days';
  }

  @override
  String get notificationInactivityOffSubtitle =>
      'Turn it on to get nudges after quiet periods.';

  @override
  String notificationLastTrainingLog(Object time) {
    return 'Last log: $time';
  }

  @override
  String get notificationInactivityTimeTitle => 'Training reminder time';

  @override
  String notificationInactivityTimeSubtitle(int days, Object time) {
    return '$days day threshold · $time';
  }

  @override
  String get notificationInactivityThresholdLabel => 'Inactivity threshold';

  @override
  String notificationInactivityThresholdDayOption(int value) {
    return '$value day(s)';
  }

  @override
  String get notificationChangeTimeAction => 'Change';

  @override
  String get notificationXpFallbackTitle => 'XP alert';

  @override
  String notificationXpSubtitle(int gainedXp, int totalXp) {
    return '+$gainedXp XP · total $totalXp XP';
  }

  @override
  String get notificationPlanFallbackTitle => 'Training plan';

  @override
  String get notificationWeatherSettingsTitle => 'Weather alert';

  @override
  String get notificationWeatherSettingsSubtitle =>
      'Send a daily reminder to check weather and training outfit.';

  @override
  String get notificationWeatherTimeTitle => 'Weather alert time';

  @override
  String notificationWeatherTimeSubtitle(Object time) {
    return 'Every day at $time';
  }

  @override
  String get notificationClubTrainingSettingsTitle => 'Club training alerts';

  @override
  String notificationClubTrainingSettingsSubtitle(int minutes) {
    return 'Send uniform and time alerts $minutes minutes before training.';
  }

  @override
  String get notificationClubTrainingLeadTimeLabel => 'Club training lead time';

  @override
  String notificationClubTrainingLeadTimeOption(int value) {
    return '$value min before';
  }

  @override
  String get notificationNewBadge => 'NEW';

  @override
  String get weatherNotificationChannelName => 'Weather alerts';

  @override
  String get weatherNotificationChannelDescription =>
      'Daily weather and training outfit reminders';

  @override
  String get weatherNotificationDailyBody =>
      'Check today\'s weather and training outfit.';

  @override
  String get reminderEnabled => 'Enable daily reminder';

  @override
  String get reminderTime => 'Reminder time';

  @override
  String get photo => 'Photo';

  @override
  String get addPhoto => 'Add photo';

  @override
  String get removePhoto => 'Remove';

  @override
  String get noImage => 'No image yet';

  @override
  String get imageLoadFailed => 'Failed to load image';

  @override
  String get more => 'More';

  @override
  String get camera => 'Camera';

  @override
  String get gallery => 'Gallery';

  @override
  String get crop => 'Crop';

  @override
  String get photoHint => 'Tap the camera icon next to Save to add photos.';

  @override
  String get reorderPhotos => 'Reorder photos';

  @override
  String photoIndex(Object value) {
    return 'Photo $value';
  }

  @override
  String photoLimitReached(Object value) {
    return 'You can add up to $value photos.';
  }

  @override
  String get openPhotoViewer => 'View photo';

  @override
  String get closePhotoViewer => 'Close photo';

  @override
  String get previousPhoto => 'Previous photo';

  @override
  String get nextPhoto => 'Next photo';

  @override
  String photoViewerCounter(Object current, Object total) {
    return '$current / $total';
  }

  @override
  String get gameGuideTitle => 'Game Guide';

  @override
  String get gameGuideQuickTitle => 'Current Game Flow';

  @override
  String get gameGuideQuickLine1 =>
      'Each run is 20 seconds, and you start with 3 lives. If you fail, you instantly retry while lives remain.';

  @override
  String get gameGuideQuickLine2 =>
      'Use the pass button to control direction and power, then choose safe, killer, or risky passes.';

  @override
  String get gameGuideQuickLine3 =>
      'Build combo through consecutive success. At combo 8+, Fever starts for 5 seconds and doubles bonus points.';

  @override
  String get gameGuideQuickLine4 =>
      'Random events (narrow lanes, wide lanes, tail wind) and missions rotate during a run, so adapt quickly.';

  @override
  String get gameGuideRiskTitle => 'Decision Strategy';

  @override
  String get gameGuideRiskLine1 =>
      'Safe pass: highest stability, best for keeping rhythm and clearing missions safely.';

  @override
  String get gameGuideRiskLine2 =>
      'Killer pass: medium risk with strong rewards for fast score growth.';

  @override
  String get gameGuideRiskLine3 =>
      'Risky pass: hardest option but gives the largest reward when completed.';

  @override
  String get gameGuideRiskLine4 =>
      'Passing into open space grants extra bonus, so read defender spacing before release.';

  @override
  String get gameGuideFailureTitle => 'Recover From Mistakes';

  @override
  String get gameGuideFailureLine1 =>
      'Interception, collision, and miss no longer end the run immediately if you still have lives.';

  @override
  String get gameGuideFailureLine2 =>
      'Use too-fast/too-slow feedback to adjust hold timing on the very next attempt.';

  @override
  String get gameGuideFailureLine3 =>
      'If no-pass-3s appears, reset tempo first with a short safe pass.';

  @override
  String get gameGuideFailureLine4 =>
      'When lives are low, switch to safer choices to protect your run.';

  @override
  String get gameGuideRankingTitle => 'Score Formula';

  @override
  String get gameGuideRankingLine1 =>
      'Rank score = (completed passes x 10) + (level x 15) + (goals x 60) + bonus score.';

  @override
  String get gameGuideRankingLine2 =>
      'Bonus score sources: pass-type rewards, open-space rewards, rhythm rewards, mission rewards.';

  @override
  String get gameGuideRankingLine3 =>
      'During Fever, bonus score is doubled, enabling big jumps in a short window.';

  @override
  String get gameGuideRankingLine4 =>
      'High-score route: build rhythm with safe passes, expand with killer/risky passes, then finish with mission and goal rewards.';

  @override
  String get gameRankingTitle => 'Game Rankings';

  @override
  String get gameRankingEmpty => 'No ranking records yet.';

  @override
  String gameRankingEntryTitle(String rankLabel, int rankScore, int score) {
    return 'Rank $rankLabel ($rankScore pts) - Score $score';
  }

  @override
  String gameRankingEntrySubtitle(int level, int goals, String date) {
    return 'Level Lv.$level - Goals $goals - $date';
  }

  @override
  String gameRankingPosition(int rankNo) {
    return '#$rankNo';
  }

  @override
  String get gameGuideCharPacTitle => 'Pacman Attacker';

  @override
  String get gameGuideCharPacSubtitle => 'Starts and links passes';

  @override
  String get gameGuideCharPacTag => 'ATTACK';

  @override
  String get gameGuideCharBlueTitle => 'Blue Ghost - BLOCK';

  @override
  String get gameGuideCharBlueSubtitle => 'Blocks passing lanes';

  @override
  String get gameGuideCharBlueTag => 'BLOCK';

  @override
  String get gameGuideCharOrangeTitle => 'Orange Ghost - PRESS';

  @override
  String get gameGuideCharOrangeSubtitle => 'Pressure near ball';

  @override
  String get gameGuideCharOrangeTag => 'PRESS';

  @override
  String get gameGuideCharRedTitle => 'Red Ghost - MARK';

  @override
  String get gameGuideCharRedSubtitle => 'Marks the passer';

  @override
  String get gameGuideCharRedTag => 'MARK';

  @override
  String get gameGuideCharPinkTitle => 'Pink Ghost - READ';

  @override
  String get gameGuideCharPinkSubtitle => 'Anticipates receiver route';

  @override
  String get gameGuideCharPinkTag => 'READ';

  @override
  String get hideKeyboard => 'Hide keyboard';

  @override
  String get diaryComposerSavePromptTitle => 'Save changes?';

  @override
  String get diaryComposerSavePromptBody =>
      'You have unsaved changes. Save before closing?';

  @override
  String get diaryComposerDontSave => 'Don\'t save';

  @override
  String get diaryNewAction => 'New diary';

  @override
  String get diaryNextDayTooltip => 'Next day';

  @override
  String get diaryPreviousDayTooltip => 'Previous day';

  @override
  String get diaryComposeTooltip => 'Compose';

  @override
  String get diaryEmptyTitle => 'No diary pages yet';

  @override
  String get diaryEmptyBody => 'Pick a date and create your first page.';

  @override
  String get diaryCreateFirstAction => 'Create first diary';

  @override
  String get diaryDeleteDialogTitle => 'Delete diary';

  @override
  String get diaryDeleteDialogBody => 'Delete this day diary?';

  @override
  String get diaryDeletedMessage => 'Diary deleted.';

  @override
  String get diaryDeleteRestoredMessage => 'Restored deleted diary.';

  @override
  String get diaryThemeNotebookName => 'Notebook';

  @override
  String get diaryThemeNotebookDescription =>
      'A calm paper-textured default diary.';

  @override
  String get diaryThemeDuskName => 'Dusk';

  @override
  String get diaryThemeDuskDescription =>
      'Reads in the warmth of a red evening glow.';

  @override
  String get diaryThemeOceanName => 'Early Sea';

  @override
  String get diaryThemeOceanDescription =>
      'A crisp and cool page like blue ink.';

  @override
  String get diaryVoiceInputTooltip => 'Voice input';

  @override
  String get diaryVoiceInputUnavailable =>
      'Voice input is not available on this device.';

  @override
  String get diaryComposerTitle => 'Compose today\'s diary';

  @override
  String get diaryComposerDescription =>
      'Pick stickers from today records below, and write the story yourself in short.';

  @override
  String get diaryEmptyHint => 'Keep it short and clear.';

  @override
  String get diaryLastSavedPrefix => 'Last saved';

  @override
  String get diarySavedMessage => 'Diary saved.';

  @override
  String get diaryTitlePlaceholder => 'Please enter a title';

  @override
  String get diaryTitleLabel => 'Title';

  @override
  String get diaryTitleHint =>
      'Ex: Passing rhythm that lasted through the rain';

  @override
  String get diaryStoryLabel => 'Body';

  @override
  String get diaryStoryPlaceholder => 'Please enter the body text';

  @override
  String get diarySaveEmptyMessage =>
      'Nothing to save yet. Add a title, story, sticker, or photo first.';

  @override
  String get diaryClearConfirmTitle => 'Clear all?';

  @override
  String get diaryClearConfirmBody =>
      'This will clear title, story, selected stickers, and photos.';

  @override
  String get diaryClearAction => 'Clear';

  @override
  String get diaryCustomEmotionLabel => 'Create your own emotion';

  @override
  String get diaryCustomEmotionHint => 'Add a mood sticker in your own words';

  @override
  String get diaryCustomEmotionAdd => 'Add emotion';

  @override
  String diaryExpandNewsStickers(int count) {
    return 'Show all news stickers ($count)';
  }

  @override
  String get diaryCollapseNewsStickers => 'Collapse news stickers';

  @override
  String get homeWeatherTitle => 'Weather coach';

  @override
  String get homeWeatherTodayTitle => 'Today\'s weather';

  @override
  String get homeWeatherSubtitle =>
      'Check local conditions and adjust training focus.';

  @override
  String get homeWeatherLoad => 'Load local weather';

  @override
  String get homeWeatherLoading => 'Loading local weather...';

  @override
  String get homeWeatherUnavailable =>
      'Weather info is ready here once location access is allowed.';

  @override
  String get homeWeatherPermissionNeeded =>
      'Allow location access to load local weather.';

  @override
  String get homeWeatherLoadFailed => 'Failed to load local weather.';

  @override
  String get entryWeatherLoading => 'Loading weather...';

  @override
  String get entryWeatherHomeMissing => 'Load weather on Home first.';

  @override
  String get entryWeatherUseLocationTooltip => 'Use location weather';

  @override
  String get entryWeatherLocationServiceTitle => 'Location service needed';

  @override
  String get entryWeatherLocationServiceBody =>
      'Turn on location services to load current-location weather.';

  @override
  String get entryWeatherPermissionTitle => 'Location permission needed';

  @override
  String get entryWeatherPermissionBody =>
      'Location permission is off. Allow it in settings to load current-location weather.';

  @override
  String get entryWeatherPermissionRequired =>
      'Location permission is required.';

  @override
  String get entryWeatherLoadFailed => 'Failed to load weather.';

  @override
  String get entryWeatherOpenSettings => 'Open settings';

  @override
  String get homeWeatherRetryTitle => 'Retry weather';

  @override
  String get homeWeatherRetrySubtitle => 'Tap to load';

  @override
  String get homeWeatherLocationUnknown => 'Current location';

  @override
  String get homeWeatherCountryKorea => 'Korea';

  @override
  String get homeWeatherDetailsTitle => 'Weather';

  @override
  String get homeWeatherDetailsSubtitle =>
      'Check local weather and air quality for your current location.';

  @override
  String get homeWeatherTomorrowTitle => 'Tomorrow\'s weather';

  @override
  String get homeWeatherWeeklyTitle => 'Weekly weather';

  @override
  String get homeWeatherOutfitActionLabel => 'Outfit';

  @override
  String get homeWeatherTomorrowActionLabel => 'Tomorrow';

  @override
  String get homeWeatherWeeklyActionLabel => 'Week';

  @override
  String get homeWeatherTomorrowNavSubtitle =>
      'Check tomorrow\'s forecast and outfit guide separately.';

  @override
  String get homeWeatherWeeklyNavSubtitle =>
      'Review the 7-day forecast and air-quality trend separately.';

  @override
  String get homeWeatherMorningLabel => 'Morning';

  @override
  String get homeWeatherEveningLabel => 'Evening';

  @override
  String get homeWeatherCacheHint =>
      'Recently fetched weather is reused for 10 minutes.';

  @override
  String get homeWeatherDailyHighLow => 'High/Low';

  @override
  String get homeWeatherTomorrowFallback =>
      'Tomorrow\'s forecast is not available yet.';

  @override
  String get homeWeatherWeeklyFallback =>
      'Weekly forecast is not available yet.';

  @override
  String get homeWeatherTomorrowOutfitTitle => 'Tomorrow\'s outfit';

  @override
  String get homeWeatherTomorrowOutfitFallback =>
      'Tomorrow\'s outfit guide is not ready yet.';

  @override
  String get homeWeatherTemperatureRange => 'High/Low';

  @override
  String get homeWeatherFeelsLike => 'Feels like';

  @override
  String get homeWeatherHumidity => 'Humidity';

  @override
  String get homeWeatherPrecipitation => 'Precipitation';

  @override
  String get homeWeatherPrecipitationProbability => 'Rain chance';

  @override
  String get weatherPrecipitationNone => 'None';

  @override
  String get weatherPrecipitationTrace => 'A little rain';

  @override
  String get weatherPrecipitationLight => 'Light rain';

  @override
  String get weatherPrecipitationModerate => 'Steady rain';

  @override
  String get weatherPrecipitationHeavy => 'Heavy rain';

  @override
  String get weatherPrecipitationVeryHeavy => 'Very heavy rain';

  @override
  String get homeWeatherHourlyPrecipitation => 'Hourly rain timeline';

  @override
  String get homeWeatherHourlyTemperature => 'Hourly temperature';

  @override
  String get homeWeatherHourlyOverview => 'Hourly weather';

  @override
  String get homeWeatherWindSpeed => 'Wind';

  @override
  String get homeWeatherUvIndex => 'UV index';

  @override
  String get homeWeatherOutfitTitle => 'Recommended training outfit';

  @override
  String get homeWeatherOutfitBaseHot =>
      'Short-sleeve kit, light shorts, and breathable socks.';

  @override
  String get homeWeatherOutfitBaseCold =>
      'Thermal base layer, gloves, long socks, and a beanie if needed.';

  @override
  String get homeWeatherOutfitBaseMild =>
      'Standard kit with a light base layer is enough.';

  @override
  String get homeWeatherOutfitRain =>
      'Pack a thin waterproof shell and an extra pair of socks.';

  @override
  String get homeWeatherOutfitSnow =>
      'Wear warm base layers and thick socks; watch for slippery ground.';

  @override
  String get homeWeatherOutfitWind =>
      'Add a windbreaker to keep body temperature stable.';

  @override
  String get homeWeatherOutfitAirCaution =>
      'If air quality is poor, wear a mask when commuting and reduce hard outdoor work.';

  @override
  String get homeWeatherOutfitButton => 'Outfit guide';

  @override
  String get homeWeatherOutfitLayersLabel => 'Top layers';

  @override
  String get homeWeatherOutfitOuterLabel => 'Outer layer';

  @override
  String get homeWeatherOutfitBottomLabel => 'Bottom';

  @override
  String get homeWeatherOutfitAccessoriesLabel => 'Accessories';

  @override
  String get homeWeatherOutfitNotesLabel => 'Notes';

  @override
  String get homeWeatherOutfitViewAllCases => 'View all outfit cases';

  @override
  String get homeWeatherOutfitAllCasesTitle => 'All outfit cases';

  @override
  String get homeWeatherOutfitAllCasesSubtitle =>
      'Review each weather band with top layers, outer layer, bottoms, and accessory details.';

  @override
  String get homeWeatherOutfitCaseHotTitle => 'Hot summer';

  @override
  String get homeWeatherOutfitCaseHotRange => 'Feels like 30°C+';

  @override
  String get homeWeatherOutfitCaseWarmTitle => 'Warm training day';

  @override
  String get homeWeatherOutfitCaseWarmRange => 'Feels like 22-29°C';

  @override
  String get homeWeatherOutfitCaseMildTitle => 'Mild day';

  @override
  String get homeWeatherOutfitCaseMildRange => 'Feels like 15-21°C';

  @override
  String get homeWeatherOutfitCaseCoolTitle => 'Cool day';

  @override
  String get homeWeatherOutfitCaseCoolRange => 'Feels like 8-14°C';

  @override
  String get homeWeatherOutfitCaseColdTitle => 'Cold day';

  @override
  String get homeWeatherOutfitCaseColdRange => 'Feels like 2-7°C';

  @override
  String get homeWeatherOutfitCaseWetTitle => 'Rainy or snowy day';

  @override
  String get homeWeatherOutfitCaseWetRange => 'When raining or snowing';

  @override
  String get homeWeatherOutfitLayersDefault => 'Base layer + short-sleeve top';

  @override
  String get homeWeatherOutfitOuterDefault => 'Light zip-up or vest';

  @override
  String get homeWeatherOutfitBottomDefault => 'Standard shorts';

  @override
  String get homeWeatherOutfitAccessoriesDefault =>
      'Spare socks and water bottle';

  @override
  String get homeWeatherOutfitLayersHot =>
      'Sleeveless/short-sleeve + cooling base';

  @override
  String get homeWeatherOutfitOuterNone => 'No outerwear';

  @override
  String get homeWeatherOutfitBottomHot => 'Breathable shorts';

  @override
  String get homeWeatherOutfitAccessoriesHot => 'Cool towel, iced water, cap';

  @override
  String get homeWeatherOutfitNoteHotBreaks => 'Take frequent cooling breaks';

  @override
  String get homeWeatherOutfitLayersWarm => 'Short-sleeve training top';

  @override
  String get homeWeatherOutfitBottomWarm => 'Training shorts';

  @override
  String get homeWeatherOutfitAccessoriesWarm => 'Spare shirt and sweat towel';

  @override
  String get homeWeatherOutfitLayersMild => 'Base layer + short/long sleeve';

  @override
  String get homeWeatherOutfitOuterMild => 'Training zip-up or vest';

  @override
  String get homeWeatherOutfitBottomMild => 'Light track pants or shorts';

  @override
  String get homeWeatherOutfitAccessoriesMild => 'Warm-up layer';

  @override
  String get homeWeatherOutfitLayersCool =>
      'Brushed base layer + long-sleeve top';

  @override
  String get homeWeatherOutfitOuterCool => 'Windbreaker + vest';

  @override
  String get homeWeatherOutfitBottomTrackPants => 'Long training pants';

  @override
  String get homeWeatherOutfitAccessoriesCool => 'Light gloves, neck warmer';

  @override
  String get homeWeatherOutfitLayersCold =>
      'Thermal base + long-sleeve + midlayer';

  @override
  String get homeWeatherOutfitOuterCold => 'Windproof jacket or padded vest';

  @override
  String get homeWeatherOutfitAccessoriesCold =>
      'Winter gloves, neck warmer, ear cover';

  @override
  String get homeWeatherOutfitLayersVeryCold =>
      'Heat base layer + thick midlayer';

  @override
  String get homeWeatherOutfitOuterVeryCold =>
      'Light puffer/training padded jacket';

  @override
  String get homeWeatherOutfitBottomVeryCold => 'Thermal training pants';

  @override
  String get homeWeatherOutfitAccessoriesVeryCold =>
      'Insulated gloves, neck warmer, beanie';

  @override
  String get homeWeatherOutfitNoteVeryCold =>
      'Warm up indoors then do short outdoor sets';

  @override
  String get homeWeatherOutfitNoteStrongWind =>
      'Strong wind: windbreaker and neck warmer required';

  @override
  String get homeWeatherOutfitOuterWaterproof => 'Waterproof windproof jacket';

  @override
  String get homeWeatherOutfitOuterRainLight =>
      'Water-resistant jacket + light midlayer';

  @override
  String homeWeatherOutfitAccessoriesRain(Object accessories) {
    return '$accessories, waterproof or spare socks';
  }

  @override
  String get homeWeatherOutfitNoteWetGrass => 'Watch slippery wet grass';

  @override
  String homeWeatherOutfitAccessoriesSnow(Object accessories) {
    return '$accessories, hand warmers (optional)';
  }

  @override
  String get homeWeatherOutfitNoteIcy => 'Avoid icy zones';

  @override
  String get homeWeatherOutfitBottomFleece => 'Fleece-lined pants';

  @override
  String get homeWeatherOutfitCautionNormal =>
      'Normal intensity is fine in current conditions';

  @override
  String get homeWeatherAirQualityTitle => 'Air quality';

  @override
  String get homeWeatherAirQualitySubtitle =>
      'Lower numbers usually mean easier breathing outdoors.';

  @override
  String get homeWeatherAirQualityForecastMissingReason =>
      'Air-quality forecast is unavailable for this area or time.';

  @override
  String get homeWeatherAirGuideTitle => 'Outdoor activity guide';

  @override
  String get homeWeatherAirGuideUnknown =>
      'Refresh air data to see outdoor activity guidance.';

  @override
  String get homeWeatherAirGuideGood =>
      'Air quality is stable enough for normal outdoor activity and training.';

  @override
  String get homeWeatherAirGuideModerate =>
      'Most outdoor activity is fine, but lower the load if your breathing is sensitive.';

  @override
  String get homeWeatherAirGuideSensitive =>
      'If breathing gets irritated easily, reduce long outdoor sessions and hard efforts.';

  @override
  String get homeWeatherAirGuideUnhealthy =>
      'Avoid hard outdoor activity and switch to indoor training or recovery if possible.';

  @override
  String get homeWeatherAirGuideVeryUnhealthy =>
      'Minimize outdoor activity and move to indoor recovery or technical work.';

  @override
  String get homeWeatherAirGuideHazardous =>
      'Stop outdoor activity and stay indoors if possible.';

  @override
  String get homeWeatherComparedYesterday => 'Vs. yesterday';

  @override
  String get homeWeatherPm10 => 'Fine dust';

  @override
  String get homeWeatherPm25 => 'Ultrafine dust';

  @override
  String get homeWeatherAqi => 'AQI';

  @override
  String get homeWeatherAqiLabel => 'Air quality index';

  @override
  String get homeWeatherAqiDescription =>
      'AQI is a simple score that shows how clean the air feels.';

  @override
  String get homeWeatherAqiScaleGood => '0-50 good';

  @override
  String get homeWeatherAqiScaleModerate => '51-100 moderate';

  @override
  String get homeWeatherAqiScaleSensitive => '101+ caution';

  @override
  String get homeWeatherTomorrowCondition => 'Condition';

  @override
  String get homeWeatherWeeklyDateLabel => 'Date';

  @override
  String get homeWeatherWeeklyConditionLabel => 'Forecast';

  @override
  String get homeWeatherStatusGood => 'Good';

  @override
  String get homeWeatherStatusModerate => 'Moderate';

  @override
  String get homeWeatherStatusSensitive =>
      'Take care if breathing is sensitive';

  @override
  String get homeWeatherStatusUnhealthy => 'Unhealthy';

  @override
  String get homeWeatherStatusVeryUnhealthy => 'Very unhealthy';

  @override
  String get homeWeatherStatusHazardous => 'Hazardous';

  @override
  String get weatherLabelDefault => 'Weather';

  @override
  String get weatherLabelClear => 'Clear';

  @override
  String get weatherLabelCloudy => 'Cloudy';

  @override
  String get weatherLabelFog => 'Fog';

  @override
  String get weatherLabelDrizzle => 'Drizzle';

  @override
  String get weatherLabelRain => 'Rain';

  @override
  String get weatherLabelSnow => 'Snow';

  @override
  String get weatherLabelThunderstorm => 'Thunderstorm';

  @override
  String get diaryStickerTraining => 'Training';

  @override
  String get diaryStickerMatch => 'Match';

  @override
  String get diaryStickerPlan => 'Plan';

  @override
  String get diaryStickerFortune => 'Today\'s line';

  @override
  String get diaryStickerBoard => 'Board';

  @override
  String get diaryStickerNews => 'News';

  @override
  String get diaryStickerMeal => 'Rice bowl';

  @override
  String get diaryStickerConditioning => 'Jump rope/lifting';

  @override
  String get diaryStickerInjury => 'Injury';

  @override
  String get diaryStickerQuiz => 'Quiz';

  @override
  String get diaryStickerWeather => 'Weather';

  @override
  String get diaryStickerParentFeedback => 'Parent feedback';

  @override
  String get diaryInjuryNoDetails => 'No injury note was saved.';

  @override
  String get diaryInjuryRehab => 'Rehab';

  @override
  String get diaryInjuryStorySentence =>
      'Write the moment pain showed up and what needs recovery next.';

  @override
  String get diaryQuizStorySentence =>
      'Write the question or concept you want to keep from the quiz run.';

  @override
  String diaryParentFeedbackStorySentence(String message) {
    return 'Parent feedback: $message';
  }

  @override
  String diaryQuizSummaryPerfect(int score, int total) {
    return '$score/$total correct · no misses';
  }

  @override
  String diaryQuizSummaryWithMisses(int score, int total, int wrongCount) {
    return '$score/$total correct · $wrongCount misses';
  }

  @override
  String diaryQuizExpandQuestions(int count) {
    return 'Show all answers ($count)';
  }

  @override
  String get diaryQuizCollapseQuestions => 'Collapse answers';

  @override
  String get diaryQuizQuestionLabel => 'Question';

  @override
  String get diaryQuizAnswerLabel => 'Answer';

  @override
  String get diaryQuizWrongAnswerLabel => 'Wrong answer';

  @override
  String get diaryQuizWrongAnswerNone => 'No wrong answer';

  @override
  String get diaryQuizNoMissesLabel =>
      'This quiz run finished without any misses.';

  @override
  String get diaryTrainingStatusLabel => 'Training status';

  @override
  String get diaryConditioningJumpRopeLabel => 'Jump rope';

  @override
  String get diaryConditioningLiftingLabel => 'Lifting';

  @override
  String get diaryWeatherEmpty => 'No weather was logged.';

  @override
  String get diaryUnknownSource => 'Unknown source';

  @override
  String get diaryLocationUnset => 'No location';

  @override
  String get diaryLocationNotLogged => 'No location logged';

  @override
  String get diaryFundamentalsFallback => 'fundamentals';

  @override
  String diaryUpdatedAt(String date) {
    return 'Updated $date';
  }

  @override
  String get diaryMatchOpponentUnknown => 'vs unknown opponent';

  @override
  String diaryMatchOpponentLabel(String opponent) {
    return 'vs $opponent';
  }

  @override
  String diaryMatchScoreLabel(String score) {
    return 'score $score';
  }

  @override
  String diaryMatchGoalsLabel(int count) {
    return 'goals $count';
  }

  @override
  String diaryMatchAssistsLabel(int count) {
    return 'assists $count';
  }

  @override
  String diaryMatchMinutesPlayed(String minutes) {
    return '$minutes played';
  }

  @override
  String diaryMatchPersonalStats(int goals, int assists) {
    return '${goals}G ${assists}A';
  }

  @override
  String diaryTotalRiceBowls(String count) {
    return '$count bowls total';
  }

  @override
  String diaryCompletedMeals(int count) {
    return '$count meals logged';
  }

  @override
  String diaryReps(int count) {
    return '$count reps';
  }

  @override
  String diaryTotalReps(int count) {
    return '$count reps total';
  }

  @override
  String diaryLiftingReps(int count) {
    return 'Lifting $count reps';
  }

  @override
  String diaryJumpRopeReps(int count) {
    return 'Jump rope $count reps';
  }

  @override
  String diaryJumpRopeMinutes(String minutes) {
    return 'Jump rope $minutes';
  }

  @override
  String diaryJumpRopeCombined(int count, String minutes) {
    return 'Jump rope $minutes/$count reps';
  }

  @override
  String diaryConditioningSummary(
      int liftingCount, int jumpCount, String jumpMinutes) {
    return 'Lifting $liftingCount reps · Jump rope $jumpMinutes/$jumpCount reps';
  }

  @override
  String diaryStoryPromptFromSeed(String title) {
    return 'Start from $title and continue with the scene you want to keep today. You can naturally connect what you planned, what you actually did, and how it felt.';
  }

  @override
  String diaryStoryPromptDefault(String place, String focus) {
    return 'Write today in your own words. Start with what happened around $place, what stayed with you in $focus, what felt good, and what still lingers.';
  }

  @override
  String diaryPlanStorySentence(String title) {
    return 'Start from $title and write why this task deserves a place in today\'s diary.';
  }

  @override
  String diaryPlanNoteTitle(String category) {
    return '$category note';
  }

  @override
  String diaryPlanDurationLabel(String duration) {
    return '$duration plan';
  }

  @override
  String get diaryPinnedPlanTooltip => 'Pinned plan';

  @override
  String diaryTrainingTodoTitle(String label) {
    return 'Training · $label';
  }

  @override
  String diaryTrainingSummaryTitle(String label) {
    return '$label summary';
  }

  @override
  String get diaryFortunePinSummary => 'Pin today\'s line as a diary sticker.';

  @override
  String get diaryFortuneStorySentence =>
      'Write the scene you want to keep from today\'s line.';

  @override
  String get diaryFortuneNoteTitle => 'Fortune line note';

  @override
  String get diaryMatchTodoTitleNoOpponent => 'Match';

  @override
  String diaryMatchTodoTitleWithOpponent(String opponent) {
    return 'Match · vs $opponent';
  }

  @override
  String get diaryMatchStorySentence =>
      'Replay the match scene by scene and write both the sharp choices and the missed ones.';

  @override
  String get diaryMatchFlowTitle => 'Match flow';

  @override
  String get diaryMatchSectionBodyDefault =>
      'Write the flow that stayed most from the match.';

  @override
  String get diaryBoardStickerFallbackSummary =>
      'Movement and idea captured on this board';

  @override
  String diaryBoardNotePrefix(String memo) {
    return 'Board note: $memo';
  }

  @override
  String diaryBoardTodoTitle(String title) {
    return 'Board · $title';
  }

  @override
  String get diaryBoardStorySentence =>
      'Write the movement or idea you want to keep from this board.';

  @override
  String get diaryBoardFallbackSummary =>
      'Pull the tactic idea into the diary.';

  @override
  String diaryBoardNoteTitle(String title) {
    return '$title note';
  }

  @override
  String get diaryLiftingStorySentence =>
      'Write how the lifting rhythm held today\'s ball feel in place.';

  @override
  String get diaryLiftingNoteTitle => 'Lifting note';

  @override
  String get diaryLiftingSectionBody =>
      'Keep the moment the touch settled together with the counts.';

  @override
  String get diaryJumpRopeStorySentence =>
      'Write the moment jump rope woke the body up and changed the breathing rhythm.';

  @override
  String get diaryJumpRopeNoteTitle => 'Jump rope note';

  @override
  String get diaryJumpRopeSectionBody =>
      'Keep the count, time, and the point where the body started to feel lighter.';

  @override
  String get diaryWeatherStorySentence =>
      'Write how the weather affected your training flow and body.';

  @override
  String diaryNewsTodoTitle(String title) {
    return 'News · $title';
  }

  @override
  String diaryNewsStorySentence(String title) {
    return 'Write one point you want to keep from \"$title\".';
  }

  @override
  String get diaryTodayNewsTitle => 'Today news';

  @override
  String diaryNewsSectionBody(String source, String title) {
    return '$source article: $title';
  }

  @override
  String get quizWrongAnswerTimeout => 'Timed out';

  @override
  String get quizWrongAnswerRevealed => 'Revealed the answer';

  @override
  String get quizWrongAnswerSkipped => 'No answer selected';

  @override
  String get quizWrongAnswerEmpty => 'No input';

  @override
  String get quizShortAnswerHintAction => 'Show hint';

  @override
  String get quizRevealAnswerAction => 'Reveal answer';

  @override
  String get quizShortAnswerHintUnavailable => 'No hint is available yet.';

  @override
  String quizShortAnswerHintStartsWith(Object first, Object length) {
    return 'It starts with \"$first\" and has $length letters.';
  }

  @override
  String quizShortAnswerHintNumber(Object first, Object length) {
    return 'It is a $length-digit answer starting with $first.';
  }

  @override
  String get diaryTrainingSelectedGoalsLabel => 'Selected goals';

  @override
  String get diaryTrainingStrongPointLabel => 'What went well';

  @override
  String get diaryTrainingNeedsWorkLabel => 'Needs work';

  @override
  String get diaryTrainingNextGoalLabel => 'Next goal';

  @override
  String get diarySelectedRecordStickersTitle => 'Selected record stickers';

  @override
  String get diarySelectedRecordStickersHint =>
      'Drag the handle to reorder, or use remove to take a sticker out.';

  @override
  String get diaryRecordStickerSectionTitle => 'Record sticker layout';

  @override
  String get diaryRecordStickerSectionSubtitle =>
      'Pick from today\'s records and organize the reading order above.';

  @override
  String get diaryRecordStickerSourceTitle => 'Pull from today records';

  @override
  String diaryRecordStickerAvailableCount(int count) {
    return '$count items';
  }

  @override
  String diaryRecordStickerSelectedCount(int count) {
    return '$count selected';
  }

  @override
  String diaryRecordStickerSelectedOrder(int order) {
    return 'Order $order';
  }

  @override
  String get diaryRecordStickerEmptyHint =>
      'Pick stickers below and reorder them here right away.';

  @override
  String get diaryRecordStickerReorder => 'Reorder sticker';

  @override
  String get diaryRecordStickerRemove => 'Remove sticker';

  @override
  String get diaryRecordStickerPinned => 'Sticker added';

  @override
  String get diaryRecordStickerPin => 'Add sticker';

  @override
  String get diaryMealStorySentence =>
      'Look back on what you ate today and note how the meal volume connected to body condition.';

  @override
  String get diaryMealSectionTitle => 'Meal note';

  @override
  String get diaryMealSectionBody =>
      'Keep the three meals, rice amount, and body feel in one short note.';

  @override
  String get diaryNewsOpenFailed => 'Failed to open the article.';

  @override
  String get mealRoutineTitle => 'Eating is training too';

  @override
  String get mealRoutineSubtitle =>
      'Skip calorie math and just log three meals with rice bowl count.';

  @override
  String get mealBreakfast => 'Breakfast';

  @override
  String get mealLunch => 'Lunch';

  @override
  String get mealDinner => 'Dinner';

  @override
  String get mealShortLabel => 'Meals';

  @override
  String get mealDone => 'Done';

  @override
  String get mealSkipped => 'Skipped';

  @override
  String get mealRiceNone => '0 bowls';

  @override
  String mealRiceBowls(int count) {
    return '$count bowl(s)';
  }

  @override
  String get mealRiceLabel => 'Rice';

  @override
  String get mealCoachHeadlinePerfect => 'Three meals are on track.';

  @override
  String get mealCoachHeadlineAlmost => 'One more meal finishes the routine.';

  @override
  String get mealCoachHeadlineNeedsMore =>
      'The meal routine needs more structure.';

  @override
  String get mealCoachHeadlineStart => 'Treat meals as training today.';

  @override
  String get mealCoachBodySteady =>
      'Meal timing and rice volume look steady. It is a good day to hold tempo in the next session.';

  @override
  String get mealCoachBodyThreeMeals =>
      'You logged all three meals. Next step is keeping rice portions from swinging too much meal to meal.';

  @override
  String get mealCoachBodyTwoMealsSolid =>
      'Two meals are solid. Lock the missing meal to a fixed time to stabilize recovery.';

  @override
  String get mealCoachBodyTwoMealsLight =>
      'Two meals are logged, but volume is light. Start by anchoring the next meal at one bowl.';

  @override
  String get mealCoachBodyOneMeal =>
      'Only one meal is recorded. Add another meal before worrying about training quality today.';

  @override
  String get mealCoachBodyZeroMeal =>
      'Start by checking off the three meals. Missing fewer meals matters more than detailed math.';

  @override
  String get mealXpFull => '3 meals complete +8 XP';

  @override
  String get mealXpFullBonus => '3 meals complete + 5+ rice bowls +10 XP';

  @override
  String get mealXpPartial => '2+ meals +3 XP';

  @override
  String get mealXpNeutral => 'One meal or less gives no bonus';

  @override
  String get homeMealCoachTitle => 'Meal coach';

  @override
  String get homeMealCoachRecordAction => 'Meals';

  @override
  String get homeParentWelcomeMessage =>
      'Parent mode: review records and feedback only.';

  @override
  String get homeParentWelcomeAction => 'Logs';

  @override
  String get homeMealCoachOtherSuggestions => 'Show other suggestions';

  @override
  String get homeMealCoachHeadlinePerfect => 'Complete';

  @override
  String get homeMealCoachHeadlineAlmost => 'Almost there';

  @override
  String get homeMealCoachHeadlineNeedsMore => 'Needs work';

  @override
  String get homeMealCoachHeadlineStart => 'Not started';

  @override
  String get homeMealCoachNoEntry =>
      'There is no training note for today yet. Start by logging the meals you ate.';

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
      'Stabilize the one meal you skip most often first.';

  @override
  String get homeMealCoachSuggestionStart2 =>
      'When you start logging, meal count matters more than calories.';

  @override
  String get homeMealCoachSuggestionStart3 =>
      'Log the first meal today, then repeat that time tomorrow.';

  @override
  String get homeMealCoachSuggestionOne1 =>
      'Only one meal is logged. Fix the next meal to a clear time so it is not missed.';

  @override
  String get homeMealCoachSuggestionOne2 =>
      'If you ate, add the rice volume too. The next coaching step gets much easier.';

  @override
  String get homeMealCoachSuggestionOne3 =>
      'Today, adding meals matters more than finishing quiz or diary.';

  @override
  String get homeMealCoachSuggestionTwoLight1 =>
      'Two meals are logged, but the volume is light. Aim for at least one full bowl in the next meal.';

  @override
  String get homeMealCoachSuggestionTwoLight2 =>
      'Do not replace the missing meal with random snacks. Keep it as a real meal slot.';

  @override
  String get homeMealCoachSuggestionTwoLight3 =>
      'Meal count is acceptable. Now build a repeatable rice benchmark too.';

  @override
  String get homeMealCoachSuggestionTwoSolid1 =>
      'The two-meal rhythm is good. Fix the missing meal in the same time window each day.';

  @override
  String get homeMealCoachSuggestionTwoSolid2 =>
      'Since the meal rhythm was decent today, also note how your body felt after training.';

  @override
  String get homeMealCoachSuggestionTwoSolid3 =>
      'If two meals are stable, the third is mostly a scheduling problem.';

  @override
  String get homeMealCoachSuggestionThree1 =>
      'You logged all three meals. Next, reduce the portion gap across meals.';

  @override
  String get homeMealCoachSuggestionThree2 =>
      'On a full three-meal day, pair it with diary to finish the recovery routine.';

  @override
  String get homeMealCoachSuggestionThree3 =>
      'The rhythm is steady, so also track how light or heavy your movement felt.';

  @override
  String get homeMealCoachSuggestionSteady1 =>
      'Meal timing and volume were stable. You can focus on holding training tempo next.';

  @override
  String get homeMealCoachSuggestionSteady2 =>
      'Energy refill looked good today. Add a short note about how your body responded.';

  @override
  String get homeMealCoachSuggestionSteady3 =>
      'Now that meals are stable, the next suggestion is linking sleep and diary review.';

  @override
  String mealCompactSummary(String label, int count) {
    return '$label $count bowl(s)';
  }

  @override
  String mealCompactSkipped(String label) {
    return '$label skipped';
  }

  @override
  String mealRiceBowlsValue(String count) {
    return '$count bowl(s)';
  }

  @override
  String get mealLogScreenTitle => 'Meal log';

  @override
  String get mealLogDateLabel => 'Log date';

  @override
  String get mealLogDatePickerHelp => 'Select meal log date';

  @override
  String get mealDietDetailsTitle => 'Diet details';

  @override
  String get mealMenuInputLabel => 'Additional note';

  @override
  String mealMenuInputHint(String label) {
    return 'Add foods not on the list or notes for $label';
  }

  @override
  String get mealMainDishLabel => 'Main dish';

  @override
  String get mealMainDishNone => 'No main dish';

  @override
  String get mealMainDishChooseAction => 'Choose main';

  @override
  String get mealMainDishEditAction => 'Edit';

  @override
  String get mealMainDishSheetTitle => 'Search main dish';

  @override
  String get mealMainDishClearAction => 'No main dish';

  @override
  String get mealDishPortionSmall => 'Light';

  @override
  String get mealDishPortionRegular => 'Regular';

  @override
  String get mealDishPortionLarge => 'Large';

  @override
  String mealDishNutritionPreview(int kcal, int protein) {
    return 'About $kcal kcal · protein ${protein}g';
  }

  @override
  String get mealCompanionFoodsLabel => 'Foods eaten together';

  @override
  String get mealCompanionFoodsEmpty => 'No extra foods selected';

  @override
  String get mealCompanionFoodsChooseAction => 'Choose foods';

  @override
  String get mealCompanionFoodsEditAction => 'Edit';

  @override
  String get mealCompanionFoodsSheetTitle => 'Choose foods eaten together';

  @override
  String get mealFoodSearchLabel => 'Search foods';

  @override
  String get mealFoodSearchHint => 'Kimchi, milk, banana, and more';

  @override
  String get mealFoodSelectionClear => 'Clear all';

  @override
  String get mealFoodSelectionDone => 'Done';

  @override
  String mealFoodNutritionLine(int kcal, int carbs, int protein, int fat) {
    return '$kcal kcal · carbs ${carbs}g · protein ${protein}g · fat ${fat}g';
  }

  @override
  String mealFoodOptionSubtitle(String category, String nutrition) {
    return '$category · $nutrition';
  }

  @override
  String mealSelectedFoodsNutritionPreview(int kcal, int protein) {
    return 'Extra foods about $kcal kcal · protein ${protein}g';
  }

  @override
  String get mealFoodCategoryMain => 'Main';

  @override
  String get mealFoodCategoryProtein => 'Protein';

  @override
  String get mealFoodCategorySide => 'Side';

  @override
  String get mealFoodCategorySoup => 'Soup';

  @override
  String get mealFoodCategoryCarb => 'Carbs';

  @override
  String get mealFoodCategoryFruit => 'Fruit';

  @override
  String get mealFoodCategorySnack => 'Snack';

  @override
  String get mealFoodCategoryDrink => 'Drink';

  @override
  String get mealDishChickenBreast => 'Chicken breast';

  @override
  String get mealDishEggs => 'Eggs';

  @override
  String get mealDishTofu => 'Tofu';

  @override
  String get mealDishGrilledFish => 'Grilled fish';

  @override
  String get mealDishSalmon => 'Salmon';

  @override
  String get mealDishBulgogi => 'Bulgogi';

  @override
  String get mealDishKimchiStew => 'Kimchi stew';

  @override
  String get mealDishDoenjangStew => 'Doenjang stew';

  @override
  String get mealDishFriedChicken => 'Fried chicken';

  @override
  String get mealDishChickenSalad => 'Chicken salad';

  @override
  String get mealDishRamen => 'Ramen';

  @override
  String get mealDishSandwich => 'Sandwich';

  @override
  String get mealFoodBibimbap => 'Bibimbap';

  @override
  String get mealFoodFriedRice => 'Fried rice';

  @override
  String get mealFoodGimbap => 'Gimbap';

  @override
  String get mealFoodCurryRice => 'Curry rice';

  @override
  String get mealFoodPorkCutlet => 'Pork cutlet';

  @override
  String get mealFoodJajangmyeon => 'Jajangmyeon';

  @override
  String get mealFoodJjampong => 'Jjamppong';

  @override
  String get mealFoodTteokbokki => 'Tteokbokki';

  @override
  String get mealFoodPasta => 'Pasta';

  @override
  String get mealFoodHamburger => 'Hamburger';

  @override
  String get mealFoodPizza => 'Pizza';

  @override
  String get mealFoodPorkBelly => 'Pork belly';

  @override
  String get mealFoodJeyukBokkeum => 'Spicy pork stir-fry';

  @override
  String get mealFoodBeefSteak => 'Beef steak';

  @override
  String get mealFoodDakgalbi => 'Dakgalbi';

  @override
  String get mealFoodOmurice => 'Omurice';

  @override
  String get mealFoodUdon => 'Udon';

  @override
  String get mealFoodColdNoodles => 'Cold noodles';

  @override
  String get mealFoodSoybeanNoodles => 'Soybean noodles';

  @override
  String get mealFoodDumplingSoup => 'Dumpling soup';

  @override
  String get mealFoodSamgyetang => 'Samgyetang';

  @override
  String get mealFoodKimchiFriedRice => 'Kimchi fried rice';

  @override
  String get mealFoodBudaeJjigae => 'Budae jjigae';

  @override
  String get mealFoodSundubuJjigae => 'Sundubu jjigae';

  @override
  String get mealFoodGalbitang => 'Galbitang';

  @override
  String get mealFoodSeolleongtang => 'Seolleongtang';

  @override
  String get mealFoodYukgaejang => 'Yukgaejang';

  @override
  String get mealFoodGamjatang => 'Gamjatang';

  @override
  String get mealFoodKalguksu => 'Kalguksu';

  @override
  String get mealFoodSujebi => 'Sujebi';

  @override
  String get mealFoodBibimNoodles => 'Bibim noodles';

  @override
  String get mealFoodJapchae => 'Japchae';

  @override
  String get mealFoodBossam => 'Bossam';

  @override
  String get mealFoodJokbal => 'Jokbal';

  @override
  String get mealFoodGalbiJjim => 'Galbi jjim';

  @override
  String get mealFoodDakdoritang => 'Spicy braised chicken';

  @override
  String get mealFoodHaejangguk => 'Haejangguk';

  @override
  String get mealFoodGukbap => 'Gukbap';

  @override
  String get mealFoodSoondaeGuk => 'Soondae guk';

  @override
  String get mealFoodTteokguk => 'Tteokguk';

  @override
  String get mealFoodJanchiGuksu => 'Janchi guksu';

  @override
  String get mealFoodMakguksu => 'Makguksu';

  @override
  String get mealFoodKimchiPancake => 'Kimchi pancake';

  @override
  String get mealFoodSeafoodPancake => 'Seafood pancake';

  @override
  String get mealFoodBindaetteok => 'Mung bean pancake';

  @override
  String get mealFoodSundae => 'Korean blood sausage';

  @override
  String get mealFoodOdengSoup => 'Fish cake soup';

  @override
  String get mealFoodSpaghetti => 'Spaghetti';

  @override
  String get mealFoodLasagna => 'Lasagna';

  @override
  String get mealFoodRisotto => 'Risotto';

  @override
  String get mealFoodPaella => 'Paella';

  @override
  String get mealFoodTacos => 'Tacos';

  @override
  String get mealFoodBurrito => 'Burrito';

  @override
  String get mealFoodQuesadilla => 'Quesadilla';

  @override
  String get mealFoodNachos => 'Nachos';

  @override
  String get mealFoodSushi => 'Sushi';

  @override
  String get mealFoodSashimi => 'Sashimi';

  @override
  String get mealFoodTempuraDon => 'Tempura don';

  @override
  String get mealFoodGyudon => 'Gyudon';

  @override
  String get mealFoodKatsudon => 'Katsudon';

  @override
  String get mealFoodYakisoba => 'Yakisoba';

  @override
  String get mealFoodOkonomiyaki => 'Okonomiyaki';

  @override
  String get mealFoodTakoyaki => 'Takoyaki';

  @override
  String get mealFoodPho => 'Pho';

  @override
  String get mealFoodBanhMi => 'Banh mi';

  @override
  String get mealFoodPadThai => 'Pad thai';

  @override
  String get mealFoodTomYumSoup => 'Tom yum soup';

  @override
  String get mealFoodGreenCurry => 'Green curry';

  @override
  String get mealFoodMassamanCurry => 'Massaman curry';

  @override
  String get mealFoodNasiGoreng => 'Nasi goreng';

  @override
  String get mealFoodSatay => 'Satay';

  @override
  String get mealFoodLaksa => 'Laksa';

  @override
  String get mealFoodButterChicken => 'Butter chicken';

  @override
  String get mealFoodChickenTikkaMasala => 'Chicken tikka masala';

  @override
  String get mealFoodBiryani => 'Biryani';

  @override
  String get mealFoodNaan => 'Naan';

  @override
  String get mealFoodDal => 'Dal';

  @override
  String get mealFoodKebab => 'Kebab';

  @override
  String get mealFoodShawarma => 'Shawarma';

  @override
  String get mealFoodFalafel => 'Falafel';

  @override
  String get mealFoodHummus => 'Hummus';

  @override
  String get mealFoodShakshuka => 'Shakshuka';

  @override
  String get mealFoodFishAndChips => 'Fish and chips';

  @override
  String get mealFoodRoastChicken => 'Roast chicken';

  @override
  String get mealFoodMeatballs => 'Meatballs';

  @override
  String get mealFoodMacAndCheese => 'Mac and cheese';

  @override
  String get mealFoodHotDog => 'Hot dog';

  @override
  String get mealFoodBurritoBowl => 'Burrito bowl';

  @override
  String get mealFoodChowMein => 'Chow mein';

  @override
  String get mealFoodMapoTofu => 'Mapo tofu';

  @override
  String get mealFoodKungPaoChicken => 'Kung pao chicken';

  @override
  String get mealFoodDimSum => 'Dim sum';

  @override
  String get mealFoodSpringRoll => 'Spring roll';

  @override
  String get mealFoodFriedNoodles => 'Fried noodles';

  @override
  String get mealFoodCongee => 'Congee';

  @override
  String get mealFoodWontonSoup => 'Wonton soup';

  @override
  String get mealFoodPokeBowl => 'Poke bowl';

  @override
  String get mealFoodCaesarSalad => 'Caesar salad';

  @override
  String get mealFoodGreekSalad => 'Greek salad';

  @override
  String get mealFoodClamChowder => 'Clam chowder';

  @override
  String get mealFoodKimchi => 'Kimchi';

  @override
  String get mealFoodPickledRadish => 'Pickled radish';

  @override
  String get mealFoodSeasonedBeanSprouts => 'Seasoned bean sprouts';

  @override
  String get mealFoodSpinachNamul => 'Spinach namul';

  @override
  String get mealFoodSeaweedSalad => 'Seaweed salad';

  @override
  String get mealFoodLettuce => 'Lettuce';

  @override
  String get mealFoodCucumber => 'Cucumber';

  @override
  String get mealFoodTomato => 'Tomato';

  @override
  String get mealFoodAvocado => 'Avocado';

  @override
  String get mealFoodBroccoli => 'Broccoli';

  @override
  String get mealFoodSweetPotato => 'Sweet potato';

  @override
  String get mealFoodPotato => 'Potato';

  @override
  String get mealFoodCorn => 'Corn';

  @override
  String get mealFoodBoiledEgg => 'Boiled egg';

  @override
  String get mealFoodFriedEgg => 'Fried egg';

  @override
  String get mealFoodOmelet => 'Omelet';

  @override
  String get mealFoodCheese => 'Cheese';

  @override
  String get mealFoodTunaCan => 'Canned tuna';

  @override
  String get mealFoodHam => 'Ham';

  @override
  String get mealFoodSausage => 'Sausage';

  @override
  String get mealFoodBacon => 'Bacon';

  @override
  String get mealFoodMackerel => 'Mackerel';

  @override
  String get mealFoodShrimp => 'Shrimp';

  @override
  String get mealFoodSquid => 'Squid';

  @override
  String get mealFoodBeans => 'Beans';

  @override
  String get mealFoodChickpeas => 'Chickpeas';

  @override
  String get mealFoodLentils => 'Lentils';

  @override
  String get mealFoodSeaweedSoup => 'Seaweed soup';

  @override
  String get mealFoodBeefSoup => 'Beef soup';

  @override
  String get mealFoodEggSoup => 'Egg soup';

  @override
  String get mealFoodTofuSoup => 'Soft tofu soup';

  @override
  String get mealFoodVegetableSoup => 'Vegetable soup';

  @override
  String get mealFoodMisoSoup => 'Miso soup';

  @override
  String get mealFoodChickenSoup => 'Chicken soup';

  @override
  String get mealFoodDumplings => 'Dumplings';

  @override
  String get mealFoodFriedSnack => 'Fried snack';

  @override
  String get mealFoodFrenchFries => 'French fries';

  @override
  String get mealFoodRiceCake => 'Rice cake';

  @override
  String get mealFoodBreadSlice => 'Bread slice';

  @override
  String get mealFoodToast => 'Toast';

  @override
  String get mealFoodOatmeal => 'Oatmeal';

  @override
  String get mealFoodCereal => 'Cereal';

  @override
  String get mealFoodGranola => 'Granola';

  @override
  String get mealFoodMixedNuts => 'Mixed nuts';

  @override
  String get mealFoodAlmonds => 'Almonds';

  @override
  String get mealFoodIceCream => 'Ice cream';

  @override
  String get mealFoodChocolate => 'Chocolate';

  @override
  String get mealFoodCookie => 'Cookie';

  @override
  String get mealFoodCake => 'Cake';

  @override
  String get mealFoodYogurt => 'Yogurt';

  @override
  String get mealFoodGreekYogurt => 'Greek yogurt';

  @override
  String get mealFoodProteinShake => 'Protein shake';

  @override
  String get mealFoodWheyProtein => 'Whey protein';

  @override
  String get mealFoodMilk => 'Milk';

  @override
  String get mealFoodSoyMilk => 'Soy milk';

  @override
  String get mealFoodJuice => 'Juice';

  @override
  String get mealFoodSportsDrink => 'Sports drink';

  @override
  String get mealFoodCoffeeLatte => 'Cafe latte';

  @override
  String get mealFoodAmericano => 'Americano';

  @override
  String get mealFoodCola => 'Cola';

  @override
  String get mealFoodWater => 'Water';

  @override
  String get mealFoodBanana => 'Banana';

  @override
  String get mealFoodApple => 'Apple';

  @override
  String get mealFoodOrange => 'Orange';

  @override
  String get mealFoodGrapes => 'Grapes';

  @override
  String get mealFoodStrawberries => 'Strawberries';

  @override
  String get mealFoodBlueberries => 'Blueberries';

  @override
  String get mealFoodSaladGreens => 'Salad greens';

  @override
  String get mealFoodSeasonedSeaweed => 'Seasoned seaweed';

  @override
  String get mealFoodLaver => 'Laver';

  @override
  String get mealFoodGyeranJjim => 'Steamed egg';

  @override
  String get mealFoodJangjorim => 'Jangjorim';

  @override
  String get mealFoodAnchovyBokkeum => 'Stir-fried anchovies';

  @override
  String get mealFoodFishCakeBokkeum => 'Stir-fried fish cake';

  @override
  String get mealFoodKongjaban => 'Sweet black beans';

  @override
  String get mealFoodCucumberKimchi => 'Cucumber kimchi';

  @override
  String get mealFoodRadishKimchi => 'Radish kimchi';

  @override
  String get mealFoodKkakdugi => 'Kkakdugi';

  @override
  String get mealFoodPerillaLeaves => 'Pickled perilla leaves';

  @override
  String get mealFoodGarlic => 'Garlic';

  @override
  String get mealFoodSsamjang => 'Ssamjang';

  @override
  String get mealFoodGochujang => 'Gochujang';

  @override
  String get mealFoodDoenjang => 'Doenjang';

  @override
  String get mealFoodSalsa => 'Salsa';

  @override
  String get mealFoodGuacamole => 'Guacamole';

  @override
  String get mealFoodTortillaChips => 'Tortilla chips';

  @override
  String get mealFoodPitaBread => 'Pita bread';

  @override
  String get mealFoodPickles => 'Pickles';

  @override
  String get mealFoodOlives => 'Olives';

  @override
  String get mealFoodSauerkraut => 'Sauerkraut';

  @override
  String get mealFoodColeslaw => 'Coleslaw';

  @override
  String get mealFoodMashedPotatoes => 'Mashed potatoes';

  @override
  String get mealFoodBakedBeans => 'Baked beans';

  @override
  String get mealFoodGarlicBread => 'Garlic bread';

  @override
  String get mealFoodOnionSoup => 'Onion soup';

  @override
  String get mealFoodEdamame => 'Edamame';

  @override
  String get mealFoodMozzarella => 'Mozzarella';

  @override
  String get mealFoodHoney => 'Honey';

  @override
  String get mealFoodJam => 'Jam';

  @override
  String get mealFoodPeanutButter => 'Peanut butter';

  @override
  String get mealFoodCrackers => 'Crackers';

  @override
  String get mealFoodCroissant => 'Croissant';

  @override
  String get mealFoodBagel => 'Bagel';

  @override
  String get mealFoodMuffin => 'Muffin';

  @override
  String get mealFoodPancakes => 'Pancakes';

  @override
  String get mealFoodWaffles => 'Waffles';

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
  String get mealSaveAction => 'Save meal log';

  @override
  String get mealDeleteAction => 'Delete meal log';

  @override
  String get mealDeleteConfirmBody => 'Delete this day\'s meal log?';

  @override
  String get mealSavedFeedback => 'Meal log saved.';

  @override
  String mealSavedWithXpFeedback(int count) {
    return 'Meal log saved +$count XP';
  }

  @override
  String get mealDeletedFeedback => 'Meal log deleted.';

  @override
  String get mealLogXpSourceLabel => 'Meal log';

  @override
  String mealCalorieEstimateValue(int kcal) {
    return 'About $kcal kcal';
  }

  @override
  String get mealCalorieEstimateEmpty => 'Calorie estimate pending';

  @override
  String mealNutritionEstimateValue(int carbs, int protein, int fat) {
    return 'Carbs ${carbs}g · protein ${protein}g · fat ${fat}g';
  }

  @override
  String get mealCalorieCoachEmpty =>
      'Record foods to estimate rough calories from rice bowls and selected items.';

  @override
  String get mealCalorieCoachLow =>
      'Calories look low today. On a training day, add a carb such as rice, sweet potato, or banana to the next meal.';

  @override
  String get mealCalorieCoachSteady =>
      'This looks reasonable for training energy. Next, spread protein and vegetables across each meal.';

  @override
  String get mealCalorieCoachHigh =>
      'Calories look high. If fried food, noodles, or snacks overlapped, make the next meal lighter with protein and vegetables.';

  @override
  String mealAverageExpectedValue(String value) {
    return 'Expected average $value bowl(s)';
  }

  @override
  String mealAverageActualValue(String value) {
    return '$value bowl(s)';
  }

  @override
  String get mealStatsEmpty => 'No meal entries in the selected period.';

  @override
  String get mealStatsSectionTitle => 'Meal Logs';

  @override
  String get mealStatsTrendTitle => 'Meal Flow';

  @override
  String get mealStatsTodayRiceBowlTitle => 'Latest rice bowls';

  @override
  String get mealStatsLoggedDays => 'Logged days';

  @override
  String get mealStatsExpectedAverage => 'Expected avg';

  @override
  String get mealStatsActualAverage => 'Actual avg';

  @override
  String get mealStatsBestDay => 'Best day';

  @override
  String get mealStatsAverageCalories => 'Avg calories';

  @override
  String get mealStatsTotalCalories => 'Total calories';

  @override
  String get mealStatsAverageNutrition => 'Avg nutrients';

  @override
  String get mealIncreaseAction => 'Add bowl';

  @override
  String get mealDecreaseAction => 'Remove bowl';

  @override
  String get mealStatsWeightLinkedHint =>
      'Days with weight records are linked on the same chart.';

  @override
  String get homeRiceBowlTitle => 'Today\'s rice bowls';

  @override
  String get homeRiceBowlSubtitle =>
      'See full bowls, half bowls, and skipped bowls at a glance.';

  @override
  String get homeRiceBowlFull => 'Full bowl';

  @override
  String get homeRiceBowlHalf => 'Half bowl';

  @override
  String get homeRiceBowlEmpty => 'Skipped';

  @override
  String get fortuneDialogTitle => 'Today\'s line';

  @override
  String get fortuneDialogSubtitle => '';

  @override
  String get fortuneDialogOverviewTitle => 'Line view';

  @override
  String get fortuneDialogOverallFortuneLabel => 'Line';

  @override
  String get fortuneDialogLuckyInfoLabel => 'Lucky number and color';

  @override
  String fortuneDialogOverallFortuneCount(int count) {
    return '$count lines';
  }

  @override
  String fortuneDialogLuckyInfoCount(int count) {
    return '$count items';
  }

  @override
  String get fortuneDialogLuckyInfoTitle => 'Lucky number and color';

  @override
  String get fortuneDialogPoolSizeLabel => 'Combinations';

  @override
  String fortuneDialogPoolSizeCount(String count) {
    return '$count cases';
  }

  @override
  String get fortuneDialogRecommendedProgramTitle =>
      'Next training recommendation';

  @override
  String get fortuneDialogRecommendationTitle => 'Play line';

  @override
  String get fortuneDialogEncouragement =>
      'Save one quick highlight from today.';

  @override
  String get fortuneDialogAction => 'Got it';

  @override
  String get fortuneDatabaseViewAction => 'View full database';

  @override
  String get fortuneDatabaseTitle => 'Full Fortune Database';

  @override
  String get fortuneDatabaseSubtitle =>
      'Myeongli codes, everyday scenes, lucky numbers, and lucky colors used to build short fortunes.';

  @override
  String get fortuneDatabaseCloseAction => 'Close';

  @override
  String get fortuneDatabaseSectionBirthCodes => 'Myeongli codes';

  @override
  String get fortuneDatabaseSectionHiddenStems => 'Hidden stems';

  @override
  String get fortuneDatabaseSectionTenGods => 'Ten-god meanings';

  @override
  String get fortuneDatabaseSectionTwelveStages => 'Twelve life stages';

  @override
  String get fortuneDatabaseSectionBranchRelations => 'Branch relations';

  @override
  String get fortuneDatabaseSectionSymbolicStars => 'Symbolic stars';

  @override
  String get fortuneDatabaseSectionElementColors => 'Element colors';

  @override
  String get fortuneDatabaseSectionShortLines => 'Short recommendations';

  @override
  String get fortuneDatabaseSectionDayMoods => 'Line ingredients';

  @override
  String get fortuneDatabaseSectionDailyEvents => 'What may follow';

  @override
  String get fortuneDatabaseSectionDailyOutcomes => 'Short fortune lines';

  @override
  String get fortuneDatabaseSectionActionCues => 'Small things to try';

  @override
  String get fortuneDatabaseSectionNameRhythms => 'Name rhythms';

  @override
  String get fortuneDatabaseSectionAdvice => 'Daily notes';

  @override
  String get fortuneDatabaseSectionColorTones => 'Color tones';

  @override
  String get fortuneDatabaseSectionColorBases => 'Colors';

  @override
  String get fortuneDatabaseSectionTimePeriods => 'Time windows';

  @override
  String get fortuneDatabaseSectionTimeWindows => 'Time windows';

  @override
  String get fortuneDatabaseSectionSceneModifiers => 'Place cues';

  @override
  String get fortuneDatabaseSectionSceneBases => 'Places and scenes';

  @override
  String get fortuneDatabaseSectionCueOpenings => 'Routine starts';

  @override
  String get fortuneDatabaseSectionCueActions => 'Small routines';

  @override
  String get entryFortuneOpenFailed => 'Failed to open fortune.';

  @override
  String get profileBirthTimeTitle => 'Birth time';

  @override
  String get profileBirthTimeSelectDateFirst => 'Select birth date first';

  @override
  String get fortuneGeneratedUnknownPlayerName => 'Player';

  @override
  String get fortuneGeneratedBirthNotSet => 'no birth date set';

  @override
  String fortuneGeneratedBirthFrame(
      String yearPillar, String monthPillar, String dayPillar) {
    return 'birth code $yearPillar/$monthPillar/$dayPillar';
  }

  @override
  String fortuneGeneratedBirthFrameWithTime(String yearPillar,
      String monthPillar, String dayPillar, String hourPillar) {
    return 'birth code $yearPillar/$monthPillar/$dayPillar/$hourPillar';
  }

  @override
  String get fortuneShortLines =>
      'Read once more before sending.|The first pass can stay safe.|Check the bag zipper before moving.|A sip of water helps the start.|Take the first five minutes slow.|Retied boots make the first step lighter.|Fewer options keep focus longer.|After a miss, the next ball has the answer.|A short reply sent first feels lighter.|Ten seconds of film can show the point.|Scan empty space and the pass lane opens.|Use your voice once and the team moves faster.|One finish photo keeps the day clear.|One quick compliment speeds up the talk.|One line is enough for the record.|Pause three seconds when you rush.|Keep the first touch close for the next move.|Move without the ball and you get it again.|Putting it away now saves time later.|Change posture while waiting and the body loosens.|Eat slow and put the phone down for a bit.|Start with the easiest piece when stuck.|Write the messy choice in two lines.|A short overdue reply is enough.|Screenshot new info and it is easier to find.|Save the line you liked; it will help later.|Stretch after practice and tomorrow feels easier.|Say hello first and the talk opens faster.|Move one beat early when space appears.|Split the routine into ten-minute chunks.|Lower the load if it feels off.|Save the good scene and reuse it later.|Mute one alert and focus gets longer.|Set the next plan five minutes early.|Lift your head before the pass and options grow.|Choose one dribble direction and feet stay cleaner.|Empty the bag before home and tomorrow is easier.|Grab water first during the break.|Basics make mistakes shrink faster.|One check before closing saves time tomorrow.|Finding one sock already counts as a start.|A calm first touch keeps the day cleaner.|A short reply on time lands neatly.|Let the eyes work before the feet.|One receipt out of the bag clears the head.|Laugh once and the next scene arrives faster.|The simple first choice keeps the feet quiet.|Fill the bottle and the routine follows.|One record line saves tomorrow some wandering.|One easy pass can wake up the team.|Drop the shoulders and the view opens.|Clear one blank and the head follows.|A late reply still works when it is clean.|If speed tangles, check the laces first.|One small tidy-up buys the afternoon time.|One compliment warms the team chat fast.|Keep the snack light and the focus long.|The next position matters more than the missed ball.|The first note line is more useful than it looks.|A tidy bag is tomorrow morning\'s cheat code.|When the cafe door opens, a good smell follows.|The first line of a favorite song quickens your steps.|A familiar name appears by the elevator door.|Lunch clicks on the first choice.|One random photo lifts the corners of your mouth.|Your eyes light up near a new convenience-store snack.|A reply you waited for arrives first, even if short.|A good smell says hello around the corner.|A forgotten note between pages makes you smile.|A pretty sky-blue moment slows your steps a little.|A favorite sentence appears right when it fits.|One notification arrives with a small flutter.|Something new you bought feels just right in hand.|Your mirror face looks better than expected.|A small spark hides around the walking path.|The right emoji softens the chat opening.|A bus window seat untangles your thoughts.|When the umbrella folds, the air turns fresh.|Your favorite snack is the last one left.|The lights on the way home look extra pretty.';

  @override
  String fortuneGeneratedDailyLineOne(String name, String elementFlow) {
    return '$name, $elementFlow';
  }

  @override
  String fortuneGeneratedDailyLineTwo(String fortuneTheme) {
    return '$fortuneTheme';
  }

  @override
  String fortuneGeneratedLinkedDailyLine(
      String name, String elementFlow, String fortuneTheme) {
    return '$name, $elementFlow / $fortuneTheme';
  }

  @override
  String fortuneGeneratedDailyLineThree(String nameElement, String playAdvice) {
    return 'Recommendation: use $nameElement and $playAdvice.';
  }

  @override
  String get fortuneGeneratedLuckyInfoHeader => '[Lucky number and color]';

  @override
  String fortuneGeneratedLuckyInfoLine(int number, String color) {
    return 'Lucky number is $number, lucky color is $color.';
  }

  @override
  String get fortuneRecommendedRecoveryProgram => 'Recovery ball touch';

  @override
  String get fortuneRecommendedLightFirstTouchProgram => 'Light first touch';

  @override
  String get fortuneRecommendedForwardPassProgram => 'Forward pass combination';

  @override
  String get fortuneRecommendedCoreTechniqueProgram => 'Core technique routine';

  @override
  String fortuneRecommendationInjury(String program) {
    return 'Check pain first and lower the next session intensity around $program.';
  }

  @override
  String fortuneRecommendationStrongFlow(String program) {
    return 'Your practice rhythm is good. Keep the next session focused on $program.';
  }

  @override
  String fortuneRecommendationDefault(String program) {
    return 'Use $program next to settle your rhythm and raise accuracy.';
  }

  @override
  String get fortuneSajuHeavenlyStems =>
      'Gap|Eul|Byeong|Jeong|Mu|Gi|Gyeong|Sin|Im|Gye';

  @override
  String get fortuneSajuEarthlyBranches =>
      'Ja|Chuk|In|Myo|Jin|Sa|O|Mi|Sin|Yu|Sul|Hae';

  @override
  String get fortuneMyeongliHiddenStemLabels =>
      'Zi: Gui|Chou: Ji, Gui, Xin|Yin: Jia, Bing, Wu|Mao: Yi|Chen: Wu, Yi, Gui|Si: Bing, Wu, Geng|Wu: Ding, Ji|Wei: Ji, Ding, Yi|Shen: Geng, Ren, Wu|You: Xin|Xu: Wu, Xin, Ding|Hai: Ren, Jia';

  @override
  String get fortuneMyeongliTenGodLabels =>
      'Friend: self-direction and personal standards|Rob wealth: competition, sharing, quick response|Eating god: enjoyment, expression, steady output|Hurting officer: unusual expression and off-rule ideas|Indirect wealth: wide chances and unexpected offers|Direct wealth: practical order and steady care|Seven killings: pressure, decision, breakthrough|Direct officer: promises, order, trusted rhythm|Indirect resource: unusual clues and deep observation|Direct resource: support, learning, easy protection';

  @override
  String get fortuneMyeongliTwelveStageLabels =>
      'Longevity: a new force begins to grow|Bath: senses wake up and change starts|Crown belt: posture and readiness form|Official: personal strength becomes clear|Prosperity: the strongest push|Decline: easing force and arranging matters|Sickness: care matters more than overdoing|Death: endings and decisions come forward|Tomb: storing and ripening the thought|Extinction: cutting off and seeing anew|Embryo: a small possibility appears|Nurturing: preparing the next flow';

  @override
  String get fortuneMyeongliBranchRelationLabels =>
      'Zi-Wu clash: direction collides and choices sharpen|Chou-Wei clash: old matters begin to move|Yin-Shen clash: movement and judgment speed up|Mao-You clash: words and relationships need balance|Chen-Xu clash: standards and responsibility are reviewed|Si-Hai clash: feelings and speed need pacing|Zi-Chou combination: close cooperation and stability|Yin-Hai combination: learning and expansion connect|Mao-Xu combination: warm expression and empathy|Chen-You combination: order and results connect|Si-Shen combination: quick judgment and wit|Wu-Wei combination: easy relationships and closure|Yin-Si-Shen punishment: a signal to smooth urgency|Chou-Wei-Xu punishment: a signal to clear old pressure|Zi-Mao punishment: a signal to tune words and feelings|Zi-Wei harm: check small misunderstandings|Chou-Wu harm: match the heat of feeling and action|Yin-Si harm: lower the rush|Mao-Chen harm: view close ties gently|Shen-Hai harm: sort things when thoughts grow|You-Xu harm: mind wording and promises|Zi-You break: rebuild a scattered plan|Chou-Chen break: mend a small crack|Yin-Hai break: see familiar expectations anew|Mao-Wu break: change the way you express it|Si-Shen break: review a quick choice once more|Wei-Xu break: reset the finishing standard|Shen-Zi-Chen water trine: thoughts and information gather|Hai-Mao-Wei wood trine: growth and relationships wake up|Yin-Wu-Xu fire trine: expression and passion rise|Si-You-Chou metal trine: order and finish improve|Hai-Zi-Chou water frame: calm focus builds|Yin-Mao-Chen wood frame: starting and growth flow|Si-Wu-Wei fire frame: energy and expression flow|Shen-You-Xu metal frame: results and order flow';

  @override
  String get fortuneMyeongliSymbolicStarLabels =>
      'Heavenly noble: helpful support appears|Literary star: writing, learning, and speech|Peach blossom: charm and attention rise|Traveling horse: movement, change, and new news|Canopy: immersion, taste, and deep feeling|Sheep blade: strong drive and decision|White tiger: big energy and breakthrough|Goe-gang: forceful independence|Heavenly virtue: gentle protection and buffering|Monthly virtue: help and care through relationships|Heavenly doctor: recovery and care|Golden carriage: comfort, stability, and easy favor';

  @override
  String get fortuneMyeongliElementColorLabels =>
      'Wood: green, mint, turquoise, forest|Fire: red, coral, peach, rose pink|Earth: mustard, butter yellow, mocha, ivory|Metal: white, silver, gold, stone gray|Water: navy, black, steel blue, ocean blue';

  @override
  String get fortuneMyeongliElementColorValues =>
      'green/mint/turquoise/forest|red/coral/peach/rose pink|mustard/butter yellow/mocha/ivory|white/silver/gold/stone gray|navy/black/steel blue/ocean blue';

  @override
  String get fortuneMyeongliTenGodDailyLines =>
      'a day to split today’s tasks into three parts|a day to pick only the words you need in a group chat|a day to take a break and grab a small snack|a day to explain things in a different tone|a day to compare a sudden offer by its conditions|a day to tidy your bag and desk|a day to decide on a delayed reply|a day to keep appointment times and order|a day to reopen a missed notification|a day to solve a stuck task with help';

  @override
  String get fortuneMyeongliTwelveStageDailyLines =>
      'a day to start the first morning action small|a day to notice changes in faces and tone|a day to prepare your seat and supplies first|a day to handle tasks one by one at your pace|a day to start delayed work in the morning|a day to remove unnecessary plans and items|a day to put rest time first|a day to pick one task and finish it|a day to reuse an old note|a day to separate what to stop from what to continue|a day to choose one small thing to try|a day to write tomorrow’s tasks tonight';

  @override
  String get fortuneMyeongliBranchRelationDailyLines =>
      'a day to handle things with someone close|a day to reset tasks after opinions clash|a day to list tangled work in order|a day to ask right away and reduce misunderstanding|a day to match loose plans again|a day to gather everyone’s comments in one place|a day to handle tasks in a familiar place';

  @override
  String get fortuneSajuElementFlows =>
      'a day to start slowly and pick up speed before noon|a day to reply to a message from a welcome name|a day to find a lost item or needed information|a day to clear one part of your room or desk|a day to lift your mood with music or a snack|a day to choose one of two options|a day to talk first to someone close|a day to hold one task for a short time|a day to finish work faster with help|a day to rest briefly and restart|a day to write down an idea right away|a day to find a clue in a usual place|a day to clear old notifications or notes|a day to choose words after reading someone’s face|a day to leave ten minutes early for an appointment|a day to speak first with a little courage|a day to check news you waited for again|a day to finish at a comfortable pace|a day to split a stuck task into small steps|a day to move in the order you chose|a day to greet someone with a smile first|a day to check changed plans or places quickly|a day to check an answer you waited for one more time|a day to show work you prepared quietly';

  @override
  String get fortuneSajuElementFlowExtras =>
      'a day to listen until the other person finishes|a day to choose again when something unexpected happens|a day to start with the least heavy task|a day to ask once before deciding alone|a day to notice small kindness right away|a day to choose a menu or route quickly|a day to mark finished work with a check|a day to try the option you like for five minutes|a day to receive a slow reply|a day to write the answer to a task in one line|a day to get a hint from a phrase or photo|a day to put nearby items back in place|a day to discover a new object or topic of interest|a day to write busy thoughts on paper|a day to find the first clue early|a day to say it briefly and still be understood|a day to ask gently and hear an answer|a day to hear or give a small compliment|a day to rest five minutes and start the next task|a day to match appointment and travel times|a day to reduce notifications and keep focus|a day to fix a small mistake right away|a day to find missed items or information|a day to speed up afternoon tasks|a day to have quiet preparation recognized|a day to trust checked facts over first feelings|a day to move naturally after a small plan change|a day to greet first and get a response|a day to make the first task small|a day to check one more time before finishing|a day to feel waiting time shorten|a day to meet one more laugh|a day to hear a new offer before refusing it|a day to use comfortable words instead of stiff ones|a day to look closely and speak right away|a day to search or ask about what you wonder';

  @override
  String get fortuneSajuFortuneThemes =>
      'a welcome name appears in your morning notification.|you send a delayed message before lunch.|the reply you waited for arrives by afternoon.|you compare the terms of a new offer and decide.|you skip a small purchase and choose what you need.|you turn a complicated thought into one note.|a short talk with someone close makes your mind easier.|you follow a useful guide on a usual route.|you finish delayed work with twenty minutes of focus.|someone’s short comment makes today’s choice easier.|a changed schedule gives you a more comfortable time.|a forgotten promise or supply comes back to mind.|you pull out something you were looking for while tidying.|a color or item you choose changes your mood.|waiting time shrinks and you start the next task faster.|you receive or give a small compliment.|needed information comes through a chat or notification.|you handle delayed work quietly while alone.|a solution comes during a short walk or commute.|you decide on a confusing choice before evening.|you notice what someone wants without being told.|you fix a small mistake and laugh it off.|you read someone’s reaction and change your words.|you reopen a contact you delayed for a long time.|new information changes what you were choosing.|water or a short rest improves your mood quickly.|you choose to save time rather than money.|someone you meet by chance leads to the next plan.|quiet focus leaves a visible result.|something on your mind ends more easily than expected.|a night check catches what you missed.|handling someone’s request gives you useful information.|you directly check an item or news you waited for.|you meet someone who is easier to talk with than expected.|one small tidy-up makes the rest of the day easier.|you keep the first choice you made.';

  @override
  String get fortuneSajuFortuneThemeExtras =>
      'you sort the needed schedule on the first screen of the morning.|you finish a small favor and hear thanks right away.|you start a postponed tidy-up within ten minutes.|you bring up a conversation on your mind briefly.|free time opens earlier than expected.|a lightly chosen route takes you to the shop or place you wanted.|moving first reduces waiting time.|you organize the information on an open screen.|a small mistake leads you to an easier method.|a short wait helps you decide the next choice.|you hear welcome news from someone familiar.|a small task finished in the morning makes the afternoon easier.|shorter words carry your meaning more accurately.|you finish an annoying task and mark it checked.|you find an answer or item in a nearby place.|someone who asks for help later gives you useful information.|an unplanned task ends faster than expected.|a thought worth writing down comes during a short break.|you compare price or time and choose an unfamiliar option.|a welcome notification or message arrives late afternoon.|unexpected praise brightens your face.|starting with what is in reach tidies things quickly.|a light sentence leads to a short conversation.|you reopen a contact you postponed.|you reduce unclear priorities to three.|a small discovery changes what you want to buy.|supplies you quietly prepared help at the end.|focus works well at a different time than usual.|small kindness returns sooner than expected.|a worry ends with a short check.|words you waited for arrive as a short text.|one light change refreshes your schedule.|one more check helps you avoid a mistake.|a rule for a long concern becomes clear.|slowing down makes the finish neater.|a strength you prepared alone shows during conversation.|a skipped message contains an important date.|you follow a new guide in a familiar place.|smiling first helps you start a conversation easily.|a short check builds trust.|the color you choose keeps catching your eye in photos or items.|a short trip helps you sort what to do.|you find a menu or item you unexpectedly like.|something hard to say comes out naturally.|you match your move to the time people around you move.|even after a late start, you finish the final check.|a small concession gives you a more comfortable seat.|new information becomes the reason for changing today’s choice.|something you laughed off becomes a good evening story.|a tidy space helps you find what you need right away.|words from someone close become today’s standard for choosing.|something feels like a small reward at the end of the day.|an unusual check helps you avoid a mistake.|you end a meeting or call more comfortably than expected.|a sudden idea becomes useful right away.|after a short walk, your next task becomes clear.|good news begins as a short sentence or small notification.|the final choice turns out more comfortable.|an easy choice satisfies you for a long time.|speaking first with small courage changes the situation.';

  @override
  String get fortuneDailyOutcomeTimes =>
      'in the morning|around lunch|this afternoon|this evening|out of nowhere|by chance|pretty soon|all at once|in a quick moment|at the end';

  @override
  String get fortuneDailyOutcomeSubjects =>
      'a funny scene|a welcome message|good news|a small chance|the answer you need|a new offer|a free pocket of time|a sharp comment|a grateful moment|an easy choice';

  @override
  String get fortuneDailyOutcomeResults =>
      'pops up.|lifts the mood.|makes the day easier.|sticks around.|makes the next move easier.|lands bigger than expected.|changes today\'s energy.|gives you a little push.|makes you smile.|stays memorable.';

  @override
  String get fortuneSajuTrainingTones =>
      'things feel cleaner if you do not rush for no reason.|one first word can loosen the mood quickly.|start with a small tidy-up and the flow speeds up.|write down what bothers you in a short note.|a comfortable choice fits better than a fast decision today.|one light joke can melt the awkwardness.|reduce a complex task to three steps.|check important messages in the morning for an easier day.|after lunch, fewer extra plans may suit you better.|keep a pleasing color nearby and focus gets easier.|handle a small request quickly and your mind opens up.|save or write down any decent idea.|when words get long, the core is enough.|fun may come from a familiar route rather than a new one.|pause for one breath and the choice becomes clearer.|it is okay to get help with something you were solving alone.|pick one small thing to do while waiting.|do not wait too long before answering welcome news.|trust your taste more than the perfect answer.|drop the comparisons and your mood recovers fast.|look once more for something you thought was lost.|check unfamiliar information once before trusting it.|ask how someone close is doing first.|it is a good time to finish a delayed booking or check.|a short outing may refresh you more than expected.|fewer phone alerts can stretch your focus.|a small choice you can make now is better than later.|split a worry into smaller pieces instead of saying it big.|a neat finish raises the day\'s luck.|a casually chosen menu may satisfy you more than expected.|read once more before sending and misunderstandings shrink.|if the pace stalls, change your seat or background.|smiling first makes conversation much easier.|drop one unnecessary thing and your mind gets lighter.|keep ten minutes of room around appointments.|today\'s good scene can stay in words, not only photos.';

  @override
  String get fortuneSajuTrainingToneExtras =>
      'break the first task that comes to mind into smaller pieces today.|if you feel stuck, open a window or move toward the light.|keep important words short and kind words a little warmer.|a rushed choice can feel much easier after five minutes.|if your mood feels vague, finish the easiest thing first.|look at intent before tone and your mind may lighten.|start a new attempt small and the pressure drops.|today, beginning before tidying can also be fine.|if something stopped midway, add just one line.|write a good thought right away so today\'s luck stays.|if you are delaying an answer, send even a short signal.|removing one unneeded alert can bring focus back.|one clean item may reset your mood today.|when asking for something, start with the core instead of a long explanation.|in an awkward place, look for common ground first.|carry one morning standard through the day.|for a small spend, think about satisfaction first.|complex feelings get easier when you name them.|today fits a natural finish more than perfection.|do not hold good news alone for too long.|if worry gets long, move your body first.|mix a small change into a familiar method.|keep important things where you can see them.|if your words tangle, return to the first sentence.|move quickly by day and softly by evening.|a short and kind no is enough today.|tidy your surroundings while waiting and your mind will settle.|good timing shows itself first to people who prepare a little.|when comparison starts, compare only with yesterday\'s self.|if your mind rushes, count numbers and choose again.|say someone\'s strength first and conversation opens easily.|one small note today can help your next choice.|do not ignore discomfort; check it gently.|put down a long-held task once and an answer may appear.|a brief final check can make the day clean.|a short laugh may become more energy than expected.';

  @override
  String get fortuneSajuNameElements =>
      'quick-starter|kind connector|calm organizer|spark-idea|slow observer|mood-shifter|careful chooser|fast intuition|steady recovery|smile-first|chance spotter|small-happiness|heart-aware|timing matcher|action over words|one-beat waiter|open to newness|accurate picker|warm relationship|small-practice|mood lifter|flow changer|curious mind|clean finisher';

  @override
  String get fortuneSajuNameElementExtras =>
      'small-clue catcher|slow but accurate type|mood opener|quick mood recoverer|good-word giver|new-flow starter|calm center holder|quick-check keeper|hidden-strength finder|comfortable chooser|relationship temperature matcher|last-tidy finisher|small-change spotter|fast information linker|mind lightener|quiet pusher|interest keeper|standard setter|laugh-point finder|feeling truster|one-more-check type|kindness rememberer|space maker|coincidence collector|quick refresher|right-moment chooser|soft persuader|small-win builder|easy-thought organizer|bright-side viewer|patient waiter|close-people carer|new-taste finder|plain finisher|day-rhythm maker|light-choice maker';

  @override
  String get fortuneSajuPlayAdvice =>
      'a small coincidence gets more fun when you do not pass over it.|the person who tidies first may own today\'s pace.|a light choice may keep your mood up longer than expected.|a kind sentence has more power than saving every word.|the answer you waited for may arrive in a simpler shape.|leave a decent suggestion open for a moment before refusing it.|give yourself one easy choice during the day.|a small direction change fits better than a big reset today.|you may see a new side of someone familiar.|one extra look at an ordinary thing may reveal the hint.|a short pause may reduce afternoon mistakes.|a light move can loosen tangled thoughts too.|keep a vivid color nearby when your mood dips.|an unfamiliar conversation may become comfortable quickly.|reduce the rush and the result can follow enough.|a quick check makes trust visible.|one piece of information today may become useful later.|something you laughed off may become a good evening story.|sorting what to keep and let go makes the mind lighter.|it is a good day to restart something paused rather than begin new.|if you receive unexpected praise, you can simply accept it.|a short focus window can carry you farther.|ask one question first and awkwardness fades fast.|today\'s luck arrives through small repeats more than big events.|when there are many options, choose the most comfortable one.|your subtle hunch may be right, so write it down.|thank someone quickly when you get help.|finishing what can end early keeps the luck alive.|one phrase you like can change your whole expression.|read slowly when news arrives after a wait.|a neat start can lead to a neat finish today.|something you do without big expectations may return as a small result.|check misunderstandings briefly and softly.|keep your own pace and nearby flows feel easier.|a short silence may bring a better answer.|the last choice you make may become today\'s memory.';

  @override
  String get fortuneSajuPlayAdviceExtras =>
      'you do not need to doubt your first feeling too much today.|crossing one small line first can make the day wider.|finish less important things lightly and keep your energy.|send a short hello to someone welcome and the flow improves.|new information can become useful if you save it now.|today\'s luck may arrive as good timing rather than a big event.|when your mood shakes, return to your most familiar routine.|one item you tidy first can make your mind comfortable.|reduce a long worry to two choices.|even a short link with someone who understands you is good.|answering a little slowly today will not break the mood.|laughing off something small may keep your mood up longer.|look for a new scene in a familiar place.|when someone is kind, respond right away.|ask a little more softly when something is unclear.|lowering the rush can make luck feel clearer today.|keeping a favorite color nearby may make choices easier.|recognize a small success right away so the next flow attaches.|imagine an unexpected offer once before deciding.|start an awkward talk with the weather or a scene you saw today.|if there is a lot to do, finish the shortest one first.|your comfortable speed is the best speed today.|you do not need to stare at one mistake for too long.|a decent thought may need a memo before words.|when waiting appears, use it to notice your surroundings.|saying thanks first can soften relationship luck.|a small plan change may fit better than the original.|if choosing is hard, pick the side that relaxes your face.|an old item may give a small hint today.|if your heart feels heavy, shrink the task to one line.|good words are better used today than saved.|a hint may come from someone close rather than someone unfamiliar.|write down today\'s hunch; later it may look quite accurate.|even a slow start can speed up once the flow catches.|if things do not sort out, empty your thoughts before the room.|a light promise may stay longer than a heavy one.|something small you learn today may become very useful.|give yourself a small reward after finishing an unpleasant task.|use a sentence you like as today\'s expression.|small curiosity can open a good conversation.|if someone approaches first, you can leave the door a little open.|today, fewer explanations may help you connect better.|a small afternoon change may alter your evening mood.|even with a familiar choice, mix in one fun detail.|a problem that does not solve right away can wait until night.|attitude may arrive before words in one moment.|small compliments may come more easily today.|thinking in a quiet place may make the answer clearer.|something started lightly may continue longer than expected.|a small sentence can quickly loosen an uncomfortable feeling.|preparing one item first can make the day easier.|today favors a chance discovery more than a chance meeting.|a pleasant sound can change the rhythm of the day.|after a small concession, an easier option may open.|today\'s good luck may show itself late but clearly.|it is fine to look again at what you liked first.|look together for the reason someone nearby is smiling.|a short focus can reduce a long worry.|today, passing cleanly may fit better than holding on.|move with one small expectation and the day feels lighter.';

  @override
  String get fortuneLuckyColorTones =>
      'Deep|Soft|Clean|Sunset|Cool|Warm|Mist|Bright|Mono|Accent|Neon|Pastel|Metallic|Fresh|Calm|Spark|Light|Mood|Glow|Natural';

  @override
  String get fortuneLuckyColorToneExtras =>
      'Minty|Smoky|Vivid|Subtle|Clear|Cozy|Fresh green|Cool-edged|Warm-lit|Transparent|Vintage|Sharp|Calm glow|Gentle|Crisp|Glittering|Deepened|Airy|Bright clear|Plain';

  @override
  String get fortuneLuckyColorBases =>
      'Navy|Emerald|Coral|Mustard|Sky Blue|Khaki|Ivory|Cherry Red|Lime|Charcoal|Royal Blue|Mint|Peach|Violet|Silver|Gold|White|Black|Olive|Turquoise|Lavender|Butter Yellow|Rose Pink|Deep Green';

  @override
  String get fortuneLuckyColorBaseExtras =>
      'Plum|Salmon|Aqua|Burgundy|Champagne|Mocha|Stone Gray|Lilac|Apple Green|Denim Blue|Cream|Ruby|Sage|Ocean Blue|Melon|Cocoa|Steel Blue|Powder Pink|Ice Blue|Forest|Tangerine|Grape|Snow|Moss Green';

  @override
  String get fortuneLuckyTimePeriods =>
      'Early morning|Late morning|Right after lunch|Early afternoon|Late afternoon|At sunset|Early evening|Night routine window|Before school|Break time|On the move|Before sleep|Message-check time|Snack time|Right after getting home|Day wrap-up time';

  @override
  String get fortuneLuckyTimePeriodExtras =>
      'Morning prep time|First message time|Before lunch|After-lunch walk time|Afternoon focus time|When the sun leans down|Before dinner|After dinner|Room tidy time|After washing up|Quiet night|Short break time|Before an appointment|After an appointment|Moment you write a record|Last check time';

  @override
  String get fortuneLuckyTimeWindows =>
      '06:40-07:20|08:10-08:50|09:30-10:10|10:40-11:20|12:20-13:00|14:10-14:50|16:00-16:40|18:20-19:00|20:10-20:50|21:00-21:40|07:30-08:00|11:40-12:10|13:20-13:50|15:10-15:40|17:20-17:50|19:30-20:00|22:00-22:30|06:10-06:30|12:50-13:20|18:50-19:20';

  @override
  String get fortuneLuckyTimeWindowExtras =>
      '06:55-07:15|07:45-08:15|08:55-09:25|09:45-10:15|10:55-11:25|11:55-12:25|12:35-13:05|13:45-14:15|14:35-15:05|15:45-16:15|16:35-17:05|17:45-18:15|18:35-19:05|19:45-20:15|20:35-21:05|21:45-22:15|22:20-22:50|06:20-06:50|07:05-07:35|08:25-08:55|10:20-10:50|11:10-11:40|13:05-13:35|14:55-15:25|16:50-17:20|18:05-18:35|19:05-19:35|21:10-21:40';

  @override
  String get fortuneLuckyZoneModifiers =>
      'By the window|Near the door|Left seat|Right seat|Center seat|Quiet spot|Bright spot|Shaded spot|In front of the desk|Near the entrance|By the elevator|Near the bus stop|Cafe corner|End of the hallway|Near the stairs|Water spot|In front of the mirror|Beside the bag|Near the table|Beside the bed';

  @override
  String get fortuneLuckyZoneModifierExtras =>
      'Sunlit|Breezy|Less crowded|Most familiar|Newly noticeable|Tidied|Warm-lit|Where your steps pause|Leaning spot|Where sounds fade|Wide-view|Where you put things down|Mood-brightening|Easy to hear|Quietly smiling|First seen today|Lightly passing|Worth a second look|Comfortable|Softly sparkling';

  @override
  String get fortuneLuckyZoneBases =>
      'small memo space|place to put the phone down|moment of the first hello|spot for a light smile|chair for a short break|tidy desk surface|moment of opening the bag|seat with a window view|place to drink water|quiet thinking spot|moment of checking a message|place to fix your shoes|place waiting for the elevator|time with favorite music|place to wash your hands|quick snack spot|place to review the plan|place to pause for a moment|moment of coming home|spot where you turn on the light|moment you yield first|place where a new path appears|spot to find today\'s item|place that closes the day';

  @override
  String get fortuneLuckyZoneBaseExtras =>
      'spot where you open a window|place to open a notebook|place to plug in a charger|beside a favorite cup|place to check the calendar|place to set down your bag|moment of reading a text|place to tie your shoes|wall to lean on briefly|desk touched by light|spot to choose a drink|moment of checking your watch|place you look back one last time|place with a small sound|spot to check a photo|place where waiting feels shorter|moment of tidying a pocket|place to choose today\'s color|seat where you feel the breeze|place to rest your eyes|moment you think of a friend|place to erase a short memo|spot to think of the next plan|moment of a quiet smile';

  @override
  String get fortuneLuckyCueOpenings =>
      'Briefly|Before the first start|After settling the breath|Before sending a message|Before leaving the door|Right after lifting your head|Before sitting down|When the rhythm slips|After drinking water|Before calling a name|After the first mistake|When conversation pauses|Once before choosing|When your mind rushes|After hearing a good word|Before sleeping|Before checking alerts|Before climbing the stairs|When entering a new place|While wrapping up the day';

  @override
  String get fortuneLuckyCueOpeningExtras =>
      'Before seeing the first alert|Before lifting your bag|When you start looking for something|When your mind gets busy|When you hear a small compliment|When you want to delay a decision|When you see a new path|After washing your hands|During a short wait|When something smells good|When a familiar song plays|When choosing today\'s color|When words get stuck|When laughter comes out|When you see something to tidy|When the answer you waited for arrives|When you are briefly alone|Right before going outside|After coming home|Before turning off the last light';

  @override
  String get fortuneLuckyCueActions =>
      'check one more time|smile first|shake both hands lightly|say the first sentence short|find one thing to appreciate|bind the mind with a short breath|choose accuracy over speed|relax the shoulders|call the other person\'s name gently|make the second choice smaller|leave one memo|slow the steps a little|tidy up right after a mistake|read once before sending|think of someone to ask for help|pause before a firm answer|lift the mood with a short compliment|tidy lightly in the last 10 minutes|expect the next task first|pick one nearby color|lift your head and look slowly|clean up right after finishing|ask one question if it feels awkward|remember today\'s good scene|choose one quiet song|tidy the inside of your bag|drink one sip of water|reduce worries to three lines|look again at a pleasant photo|send one short reply first|change your seat slightly|leave one compliment in the evening';

  @override
  String get fortuneLuckyCueActionExtras =>
      'choose the easiest thing first|offer a decent word first|tidy one small item|remove just one task from today|keep a favorite color close|send a short reply first|match your walking speed a little|relax your fingertips|write down a word that stands out|try a delayed thing for three minutes|look out the window once|share good news with one person|laugh off a small mistake|record the first thought|choose just one place to tidy|change posture while waiting|think of someone you appreciate|save today\'s color as a photo|ask gently about what feels off|make the last choice slowly|leave five minutes of room for the next time|save a sentence you like|check new information once|finish a regrettable thing briefly|look for a moment to yield first|do not delay a good answer too long|lighten what is in your pocket|imagine one unfamiliar choice|leave one line about what you learned today|think again in a quiet place|notice a pleasant expression|choose a small reward for the end of the day';

  @override
  String get mealStatsNoTrainingOrMealEntries =>
      'No training or meal entries in the selected period.';

  @override
  String get drawerRunningCoach => 'Running Coach';

  @override
  String get runningCoachScreenTitle => 'Running Coach';

  @override
  String get runningCoachHeroTitle => 'Run, review, improve';

  @override
  String get runningCoachHeroBody =>
      'Use live cues while you run, or upload one clear side-view clip for a full form report.';

  @override
  String get runningCoachStartTitle => 'Choose how you want to train';

  @override
  String get runningCoachStartBody =>
      'Start live coaching now, or check the exact camera setup before recording a clip.';

  @override
  String get runningCoachSectionToday => 'Mission';

  @override
  String get runningCoachSectionRecords => 'Records';

  @override
  String get runningCoachSectionAnalysis => 'Analysis';

  @override
  String get runningCoachTodayPlanTitle => 'Session plan';

  @override
  String get runningCoachTodayPlanMissionTitle => 'Primary sprint block';

  @override
  String get runningCoachTodayPlanMissionBody =>
      'Start with the mission below. Three sharp attempts are enough.';

  @override
  String get runningCoachTodayPlanRecordTitle => 'Performance log';

  @override
  String get runningCoachTodayPlanRecordBody =>
      'After running, move to Records and enter only the fastest attempt.';

  @override
  String get runningCoachTodayPlanAnalysisTitle => 'Form review trigger';

  @override
  String get runningCoachTodayPlanAnalysisBody =>
      'Use Analysis when the start feels slow, heavy, or different from the best run.';

  @override
  String get runningCoachTodayPlanRecordAction => 'Go to records';

  @override
  String get runningCoachTodayPlanAnalysisAction => 'Go to analysis';

  @override
  String get runningCoachRecordsPlanTitle => 'Timing protocol';

  @override
  String get runningCoachRecordsPlanDistanceTitle => 'Choose the distance';

  @override
  String get runningCoachRecordsPlanDistanceBody =>
      'Pick 10m, 20m, or 30m to match the sprint you just ran.';

  @override
  String get runningCoachRecordsPlanSecondsTitle => 'Enter seconds';

  @override
  String get runningCoachRecordsPlanSecondsBody =>
      'Use the stopwatch time in seconds, then save it as today\'s best attempt.';

  @override
  String get runningCoachRecordsPlanCompareTitle => 'Chase the previous runner';

  @override
  String get runningCoachRecordsPlanCompareBody =>
      'The app compares the saved time with the previous best so the next target is clear.';

  @override
  String get runningCoachAnalysisPlanTitle => 'Video analysis protocol';

  @override
  String get runningCoachAnalysisPlanRecordTitle => 'Record a side view';

  @override
  String get runningCoachAnalysisPlanRecordBody =>
      'Keep the full body in frame from the side for a few running steps.';

  @override
  String get runningCoachAnalysisPlanSampleTitle => 'Check the sample first';

  @override
  String get runningCoachAnalysisPlanSampleBody =>
      'Open the sample guide if you want to see what the app compares before uploading.';

  @override
  String get runningCoachAnalysisPlanAnalyzeTitle => 'Pick and analyze';

  @override
  String get runningCoachAnalysisPlanAnalyzeBody =>
      'Choose the video, run analysis, then start with the first focus cue.';

  @override
  String get runningCoachControlPanelTitle => 'Coach checkpoint';

  @override
  String get runningCoachControlPanelLoadLabel => 'Load';

  @override
  String get runningCoachControlPanelLoadValue => '3 quality reps';

  @override
  String get runningCoachControlPanelDistanceLabel => 'Distance';

  @override
  String runningCoachControlPanelDistanceValue(int meters) {
    return '${meters}m focus';
  }

  @override
  String get runningCoachControlPanelRecordLabel => 'Log';

  @override
  String get runningCoachControlPanelRecordValue => 'Best attempt only';

  @override
  String get runningCoachControlPanelReviewLabel => 'Review';

  @override
  String get runningCoachControlPanelReviewValue => 'Side-view if needed';

  @override
  String get runningCoachGrowthTitle => 'Beat your own runner';

  @override
  String get runningCoachGrowthBody =>
      'Record simple 10m, 20m, and 30m times. The app celebrates personal bests, streaks, and steady attempts so running stays fun even before a new record.';

  @override
  String get runningCoachGrowthAttemptsLabel => 'Attempts';

  @override
  String runningCoachGrowthAttempts(int count) {
    return '$count total';
  }

  @override
  String get runningCoachGrowthStreakLabel => 'Streak';

  @override
  String runningCoachGrowthStreak(int count) {
    return '$count days';
  }

  @override
  String get runningCoachGrowthDistancesLabel => 'Distances';

  @override
  String runningCoachGrowthDistances(int count) {
    return '$count/3 logged';
  }

  @override
  String get runningCoachRecordInputTitle => 'Log a sprint time';

  @override
  String runningCoachRecordDistance(int meters) {
    return '${meters}m';
  }

  @override
  String get runningCoachRecordSecondsLabel => 'Time';

  @override
  String get runningCoachRecordSecondsHint => 'Example 4.32';

  @override
  String get runningCoachRecordSecondsSuffix => 'sec';

  @override
  String get runningCoachRecordSaveAction => 'Save time';

  @override
  String get runningCoachRecordInvalid =>
      'Enter a sprint time between 0 and 60 seconds.';

  @override
  String get runningCoachRecordSaved => 'Sprint time saved.';

  @override
  String get runningCoachRecordEmpty => 'No time yet';

  @override
  String runningCoachRecordSecondsValue(String seconds) {
    return '${seconds}s';
  }

  @override
  String get runningCoachGhostEmptyTitle => 'Create your first ghost runner';

  @override
  String get runningCoachGhostEmptyBody =>
      'Run once and save the time. Next time, the target is simply to catch your own previous run.';

  @override
  String runningCoachGhostTitle(int meters) {
    return '${meters}m ghost runner';
  }

  @override
  String runningCoachGhostFirstRecordBody(String seconds) {
    return 'Your first target is ${seconds}s. Try to trim just 0.05s next time.';
  }

  @override
  String runningCoachGhostImprovedBody(String seconds) {
    return 'Personal best by ${seconds}s. Save this feeling and try to repeat it once.';
  }

  @override
  String runningCoachGhostChaseBody(String seconds) {
    return 'You are ${seconds}s away from the best ghost. One cleaner start can close that gap.';
  }

  @override
  String get runningCoachBadgesTitle => 'Running badges';

  @override
  String get runningCoachBadgeFirstRun => 'First sprint';

  @override
  String get runningCoachBadgeRecordBreaker => 'Record breaker';

  @override
  String get runningCoachBadgeThreeDaySpark => '3-day spark';

  @override
  String get runningCoachBadgeAllRounder => '10/20/30m runner';

  @override
  String get runningCoachAnalyzeBody =>
      'Choose a side-view clip. The app scans within a fixed frame budget, focuses on the clearest runner section, then re-reads contact windows densely.';

  @override
  String get runningCoachCaptureFlowTitle => 'Analyze a running video';

  @override
  String get runningCoachCandidatePreviewTitle => 'Preview candidate videos';

  @override
  String get runningCoachCapturedPreviewTitle => 'Review this recording';

  @override
  String get runningCoachPreviewBody =>
      'Play and scrub the video before confirming it. Quality checks below are warnings and do not block analysis.';

  @override
  String get runningCoachPreviewUnavailable =>
      'Preview is unavailable. You can choose another video or let the analysis decoder try this file.';

  @override
  String get runningCoachPreviewPoseAnalyzing => 'Checking joints';

  @override
  String get runningCoachPreviewPoseUnavailable => 'Joint overlay unavailable';

  @override
  String get runningCoachPreviewPoseRetryAction => 'Retry';

  @override
  String get runningCoachPreviewSelectAction => 'Choose this video';

  @override
  String get runningCoachPreviewAnalyzeAction => 'Analyze this video';

  @override
  String get runningCoachPreviewLongVideoWarning =>
      'This is longer than 60 seconds. The app will scan within its frame budget and focus on the clearest runner segment.';

  @override
  String get runningCoachPreviewLargeVideoWarning =>
      'This file is over 120 MB. Analysis will use a bounded frame budget and may take longer.';

  @override
  String get runningCoachPreviewLargeWebVideoWarning =>
      'This browser file is over 64 MB. Files above 96 MB are rejected before analysis to protect browser memory.';

  @override
  String get runningCoachPreviewResolutionWarning =>
      'The resolution is low, so some measurements may be estimates.';

  @override
  String get runningCoachPreviewUnknownInfo => 'unknown';

  @override
  String runningCoachPreviewMegabytes(String value) {
    return '$value MB';
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
  String get runningCoachCoordinatePreviewLabel => 'Coordinate preview';

  @override
  String get runningCoachSlowLoopTitle => 'View this moment in the video';

  @override
  String get runningCoachSlowLoopBody =>
      'Plays only the short interval around this measurement at 0.5× speed and repeats it.';

  @override
  String get runningCoachSlowLoopUnavailable =>
      'The original video was not saved, so this moment cannot be played.';

  @override
  String get runningCoachSlowLoopCaptureOnly =>
      'Only the saved real capture is available because the original video was not retained.';

  @override
  String runningCoachSlowLoopTiming(String start, String end) {
    return '0.5× loop · ${start}s–${end}s';
  }

  @override
  String get runningCoachConfirmedScoreLabel => 'Confirmed score';

  @override
  String get runningCoachEstimatedScoreLabel => 'Expected score';

  @override
  String get runningCoachEstimatedScoreSummary =>
      'An expected score based on the coordinates available in this video';

  @override
  String runningCoachMeasurementCountTitle(int count, int total) {
    return 'Measurement results $count/$total';
  }

  @override
  String get runningCoachMeasurementStatusEstimated => 'Estimated measurement';

  @override
  String get runningCoachMeasurementStatusCoordinatesUnavailable =>
      'No coordinates';

  @override
  String runningCoachMeasurementExpectedRange(String lower, String upper) {
    return 'Expected range $lower–$upper';
  }

  @override
  String runningCoachEvidenceFrameMetadata(
      String side, String time, String value, int confidence) {
    return '$side · $time · $value · confidence $confidence%';
  }

  @override
  String runningCoachEvidenceViewAtTime(String time) {
    return 'View at $time in video';
  }

  @override
  String get runningCoachCaptureFlowBody =>
      'Record or choose a side-view clip, preview it, then confirm analysis. Longer clips are handled within a fixed frame budget.';

  @override
  String get runningCoachCaptureAction => 'Record now';

  @override
  String get runningCoachCaptureAndAnalyzeAction => 'Record and analyze now';

  @override
  String get runningCoachCaptureAgainAction => 'Record again';

  @override
  String get runningCoachCaptureTitle => 'Record a run';

  @override
  String get runningCoachCaptureGuide =>
      'Keep your full body and both feet inside the guide from a side view.';

  @override
  String get runningCoachCaptureStart => 'Start recording';

  @override
  String get runningCoachCaptureStop => 'Finish recording';

  @override
  String runningCoachCaptureRecording(int elapsed, int maximum) {
    return 'Recording $elapsed/${maximum}s';
  }

  @override
  String runningCoachCaptureMinimumDuration(int seconds) {
    return 'Record for at least $seconds seconds.';
  }

  @override
  String get runningCoachCaptureSwitchCamera => 'Switch camera';

  @override
  String get runningCoachCaptureUnsupportedPlatform =>
      'In-app recording is not available on this device.';

  @override
  String get runningCoachCapturePermissionDenied =>
      'Camera permission is required. Allow it in Settings and try again.';

  @override
  String get runningCoachCaptureUnavailable => 'No camera is available.';

  @override
  String get runningCoachCaptureFailed =>
      'Could not start recording. Check the camera and try again.';

  @override
  String get runningCoachCaptureRetry => 'Open camera again';

  @override
  String get runningCoachCaptureFramingTitle => 'Smart framing';

  @override
  String runningCoachCaptureFramingReadyCount(int count, int total) {
    return '$count/$total ready';
  }

  @override
  String get runningCoachCaptureFramingFallbackBody =>
      'Live pose checks are unavailable here, so only device and preview checks are shown.';

  @override
  String get runningCoachCaptureFramingLiveBody =>
      'Live pose checks update before recording. Warnings do not block recording.';

  @override
  String get runningCoachCaptureFramingStartingBody =>
      'Starting the live framing check...';

  @override
  String get runningCoachCaptureFramingLiveSearching =>
      'Looking for a full-body pose';

  @override
  String get runningCoachCaptureFramingLiveReady => 'Live pose detected';

  @override
  String get runningCoachCaptureFramingNotMeasured => 'Not measured';

  @override
  String get runningCoachCaptureFramingPhoneGood => 'Phone upright';

  @override
  String get runningCoachCaptureFramingPhoneWarning => 'Rotate upright';

  @override
  String get runningCoachCaptureFramingPreviewGood => 'Preview fills screen';

  @override
  String get runningCoachCaptureFramingFullBodyGood => 'Body inside guide';

  @override
  String get runningCoachCaptureFramingFullBodyWarning => 'Center full body';

  @override
  String get runningCoachCaptureFramingFullBodyUnknown => 'Body not measured';

  @override
  String get runningCoachCaptureFramingScaleGood => 'Good runner size';

  @override
  String get runningCoachCaptureFramingScaleTooSmall => 'Runner too small';

  @override
  String get runningCoachCaptureFramingScaleTooLarge => 'Runner too close';

  @override
  String get runningCoachCaptureFramingScaleUnknown => 'Size not measured';

  @override
  String get runningCoachCaptureFramingLandmarksGood =>
      'Head and shoes visible';

  @override
  String get runningCoachCaptureFramingLandmarksWarning =>
      'Show head, joints, shoes';

  @override
  String get runningCoachCaptureFramingLandmarksUnknown =>
      'Joints not measured';

  @override
  String get runningCoachCaptureFramingSideGood => 'Side view';

  @override
  String get runningCoachCaptureFramingSideWarning => 'Move square to side';

  @override
  String get runningCoachCaptureFramingSideUnknown => 'Side view not measured';

  @override
  String get runningCoachCaptureFramingVideoQualityGood => 'Clear and steady';

  @override
  String get runningCoachCaptureFramingVideoQualityWarning =>
      'Hold camera steady';

  @override
  String get runningCoachCaptureFramingVideoQualityLowConfidence =>
      'Improve light; avoid blur or blocking';

  @override
  String get runningCoachCaptureFramingVideoQualityUnknown =>
      'Clarity not measured';

  @override
  String get runningCoachCaptureFramingCheckWarning => 'Check framing';

  @override
  String get runningCoachModeLive => 'Live';

  @override
  String get runningCoachModeVideo => 'Video analysis';

  @override
  String get runningCoachModeLiveTitle => 'Check your form while running';

  @override
  String get runningCoachModeVideoTitle => 'Analyze form from a video';

  @override
  String get runningCoachModeLiveBody =>
      'Run a few steps in a full-body side view for immediate guidance.';

  @override
  String get runningCoachModeVideoBody =>
      'Choose a side-view video to scan within a fixed frame budget and create a form report.';

  @override
  String get runningCoachModeLiveAction => 'Start live coaching';

  @override
  String get runningCoachTipsTitle => 'How to record';

  @override
  String get runningCoachTipWholeBody =>
      'Keep the full body in frame from head to foot strike, with shoulders, hips, knees, ankles, elbows, and wrists visible.';

  @override
  String get runningCoachTipSideView =>
      'Record from a true side view while the runner moves across the frame, not toward or away from the camera.';

  @override
  String get runningCoachTipSteadyCamera =>
      'Use a steady camera and bright, even light. For the fastest reliable result, include at least 3 clean strides in a steady 5–15 second section.';

  @override
  String get runningCoachUploadGuideTitle => 'Video upload guide';

  @override
  String get runningCoachUploadGuideBody =>
      'Open the example playback only to learn the overlay. Your uploaded result is judged from your own video frames.';

  @override
  String get runningCoachUploadGuideStepSide =>
      'Set the phone square to the running lane at hip height, then film the runner moving left-to-right or right-to-left.';

  @override
  String get runningCoachUploadGuideStepDistance =>
      'Leave space in front and behind the runner so the head, hips, knees, ankles, feet, elbows, and wrists stay visible on every step.';

  @override
  String get runningCoachUploadGuideStepDuration =>
      'A focused 5–15 second section is fastest. Longer clips are sampled within a fixed budget, so remove walking setup, repeated turns, and stopped frames when possible.';

  @override
  String get runningCoachUploadGuideStepLight =>
      'Record in bright, even light with a plain background; avoid shadows, cropped feet, and people crossing behind the runner.';

  @override
  String get runningCoachSampleTitle => 'Sample video guide';

  @override
  String get runningCoachSampleBody =>
      'Play the analysis-ready side-view example first, then match its framing when you record your own run.';

  @override
  String get runningCoachSampleGuideAction => 'Open sample video guide';

  @override
  String get runningCoachCaptureGuideAction => 'Open recording guide';

  @override
  String get runningCoachCaptureGuideTitle => 'Recording guide';

  @override
  String get runningCoachCaptureGuideBody =>
      'This screen helps you set up the recording. Form scores and coaching are calculated only from the video you upload.';

  @override
  String get runningCoachCaptureGuideChecklistTitle => 'Before you upload';

  @override
  String get runningCoachCaptureGuideChecklistCamera =>
      'Fix the camera and place it square to the running line.';

  @override
  String get runningCoachCaptureGuideChecklistFraming =>
      'Keep the head through both shoes in view, with the full body filling 50–75% of the frame height.';

  @override
  String get runningCoachCaptureGuideChecklistClip =>
      'For the fastest reliable result, use a bright 5–15 second clip with 3–6 clean strides. Longer clips use bounded sampling.';

  @override
  String get runningCoachCaptureGuideAnalysisTitle =>
      'Analysis uses only your video';

  @override
  String get runningCoachCaptureGuideAnalysisBody =>
      'This guide checks recording setup. Form scores and corrections are calculated from your uploaded frames and their confidence.';

  @override
  String get runningCoachSampleAnalysisLoadingTitle =>
      'Adding the measured overlay';

  @override
  String get runningCoachSampleAnalysisLoadingBody =>
      'The video is ready to play. The app is analyzing its joints and contact frames in the background.';

  @override
  String get runningCoachSampleAnalysisFailedTitle =>
      'Sample analysis unavailable';

  @override
  String get runningCoachSampleAnalysisRetryAction => 'Retry sample analysis';

  @override
  String get runningCoachSampleTechnicalDetailsTitle =>
      'How the analysis works';

  @override
  String get runningCoachSampleVideoPlay => 'Play sample video';

  @override
  String get runningCoachSampleVideoPause => 'Pause sample video';

  @override
  String get runningCoachSampleVideoUnavailable =>
      'The sample video could not be loaded. You can still use the recording guide below.';

  @override
  String get runningCoachSampleVideoRetryAction => 'Retry video';

  @override
  String runningCoachSampleScoreValue(int score) {
    return 'Score $score';
  }

  @override
  String runningCoachSampleFrameLabel(int current, int total) {
    return 'Frame $current/$total';
  }

  @override
  String get runningCoachSampleFrameGuideTitle => 'What the overlay shows';

  @override
  String get runningCoachSampleFrameGuideBody =>
      'Read the overlays with the example runner: posture, landing, arm timing, and frame coverage appear on top of the clip.';

  @override
  String get runningCoachSampleCueLean =>
      'Hip-to-shoulder lean compared with the vertical hip line';

  @override
  String get runningCoachSampleCueFrame =>
      'Head, hips, knees, and feet stay visible';

  @override
  String get runningCoachSampleCueFoot =>
      'Foot lands under the hip with toes forward';

  @override
  String get runningCoachSampleCueArms =>
      'Elbows stay bent and swing opposite the legs';

  @override
  String get runningCoachSampleReferenceTab => 'Example A';

  @override
  String get runningCoachSampleMistakeTab => 'Example B';

  @override
  String get runningCoachSampleReferenceTitle =>
      'Portrait full-body side-view example';

  @override
  String get runningCoachSampleMistakeTitle => 'Example B readouts';

  @override
  String get runningCoachSampleReferenceBody =>
      'The runner stays visible from head to both shoes and occupies about 60% of the frame height, leaving enough detail for joint tracking.';

  @override
  String get runningCoachSampleMistakeBody =>
      'This separate clip shows another runner and setting. Review the readouts without treating it as a matched comparison.';

  @override
  String get runningCoachSampleReferencePosture =>
      'Trunk lean: the coach reads the shoulder-to-hip line and reports the current posture value.';

  @override
  String get runningCoachSampleReferenceFoot =>
      'Contact point: the coach compares the landing foot with the hip line before judging braking risk.';

  @override
  String get runningCoachSampleReferenceKnee =>
      'Stance knee: the coach reports the loaded knee angle from the detected hip, knee, and ankle.';

  @override
  String get runningCoachSampleReferenceArms =>
      'Arm angle: the coach reads shoulder, elbow, and wrist positions on each sampled frame.';

  @override
  String get runningCoachSampleReferenceFrame =>
      'Frame quality: usable frames depend on visible body points, not on a preset sample label.';

  @override
  String get runningCoachSampleMistakePosture =>
      'Trunk lean: the coach reports the same posture metric and status for this clip.';

  @override
  String get runningCoachSampleMistakeFoot =>
      'Contact point: the coach uses the detected landing distance before assigning the status.';

  @override
  String get runningCoachSampleMistakeKnee =>
      'Stance knee: the coach reads the actual contact-window knee angle from the pose frames.';

  @override
  String get runningCoachSampleMistakeArms =>
      'Arm angle: the coach uses the detected elbow angle instead of a fixed sample value.';

  @override
  String get runningCoachSampleMistakeBounce =>
      'Bounce: the coach reports the measured vertical motion from the analyzed frames.';

  @override
  String get runningCoachSampleAnalysisMethodTitle =>
      'How the coach analyzes it';

  @override
  String get runningCoachSampleAnalysisMethodBody =>
      'The coach samples stable side-view frames, checks visible body points, estimates contact windows, and scores each metric with confidence.';

  @override
  String get runningCoachSampleMethodPose =>
      'Visible body points: shoulders, hips, knees, ankles, elbows, wrists, and head must stay visible.';

  @override
  String get runningCoachSampleMethodAngles =>
      'Angles: trunk lean, stance knee, and elbow carriage are measured frame by frame.';

  @override
  String get runningCoachSampleMethodContact =>
      'Contact: the closest landing frames estimate foot strike distance from the hip line.';

  @override
  String get runningCoachSampleMethodConfidence =>
      'Confidence: low coverage or too few stable frames makes the coach warn you to recheck.';

  @override
  String get runningCoachSampleRecordingGuideTitle => 'Recording setup guide';

  @override
  String get runningCoachCaptureTreadmillTab => 'Treadmill';

  @override
  String get runningCoachCaptureOutdoorTab => 'Outdoor pass';

  @override
  String get runningCoachCaptureTreadmillTitle => 'Best setup for a treadmill';

  @override
  String get runningCoachCaptureTreadmillBody =>
      'A fixed landscape side view is the most repeatable setup. Portrait is acceptable only when the full body and treadmill remain visible.';

  @override
  String get runningCoachCaptureTreadmillStepCamera =>
      'Place the phone exactly perpendicular to the belt, with the lens at hip height. Do not film from the front or rear.';

  @override
  String get runningCoachCaptureTreadmillStepDistance =>
      'Start about 3 m away, then adjust until the runner is 50-75% of the frame height.';

  @override
  String get runningCoachCaptureTreadmillStepFrame =>
      'Keep the head, both hands, both knees, and both shoes inside the frame for every step. Leave a little space above the head and below the belt.';

  @override
  String get runningCoachCaptureTreadmillStepClip =>
      'Record 5-10 seconds at a steady speed. Use 1080p/60 fps when available; 30 fps is the minimum.';

  @override
  String get runningCoachCaptureOutdoorTitle => 'Fixed side-pass setup';

  @override
  String get runningCoachCaptureOutdoorBody =>
      'A runner may pass farther from the phone, but distance is acceptable only while the whole body remains large and sharp enough to track.';

  @override
  String get runningCoachCaptureOutdoorStepCamera =>
      'Fix the phone at hip height, perpendicular to the running line. Do not pan, zoom, or follow the runner.';

  @override
  String get runningCoachCaptureOutdoorStepDistance =>
      'Set the running line so the runner occupies 40-70% of frame height while crossing the center.';

  @override
  String get runningCoachCaptureOutdoorStepFrame =>
      'Leave entry and exit space, but trim the clip to 3-6 clean strides with every joint visible.';

  @override
  String get runningCoachCaptureOutdoorStepClip =>
      'Use bright, even light and a plain background. Avoid motion blur, shadows, cropped feet, and people crossing behind.';

  @override
  String get runningCoachCaptureOutdoorDistanceWarning =>
      'Far-away footage is not recommended when the runner is below 40% of frame height. Move the running line closer or use optical zoom before recording.';

  @override
  String get runningCoachCaptureMoreDetails => 'More recording details';

  @override
  String get runningCoachSampleProcessTitle =>
      'Analysis process on the real clip';

  @override
  String get runningCoachSampleProcessBody =>
      'The overlay shows the same order the coach follows: sample a stable frame, lock visible body points, connect body lines, measure angles, then check contact evidence.';

  @override
  String get runningCoachSamplePhaseFrame => 'Sample frame';

  @override
  String get runningCoachSamplePhaseJoints => 'Find body points';

  @override
  String get runningCoachSamplePhaseMuscles => 'Mark body load';

  @override
  String get runningCoachSamplePhaseSkeleton => 'Connect body lines';

  @override
  String get runningCoachSamplePhaseAngles => 'Measure angles';

  @override
  String get runningCoachSamplePhaseContactScore => 'Check contact evidence';

  @override
  String get runningCoachSamplePhaseDenseContact => 'Validate contact frame';

  @override
  String runningCoachSampleContactFrameLabel(Object time) {
    return 'Contact $time';
  }

  @override
  String runningCoachContactTimestampSeconds(String seconds) {
    return '${seconds}s';
  }

  @override
  String get runningCoachSampleDecisionTitle => 'Decision evidence';

  @override
  String get runningCoachSampleMetricPosture => 'Trunk lean';

  @override
  String get runningCoachSampleMetricArms => 'Arms';

  @override
  String get runningCoachSampleMetricLanding => 'Landing';

  @override
  String get runningCoachSampleMetricFrames => 'Frame coverage';

  @override
  String get runningCoachSampleMetricBounce => 'Bounce';

  @override
  String get runningCoachSampleStatusPass => 'Pass';

  @override
  String get runningCoachSampleStatusReview => 'Review';

  @override
  String get runningCoachSamplePoseOverlayUnavailable => 'No pose frames';

  @override
  String runningCoachSampleReadoutValue(
      Object metric, Object value, Object status) {
    return '$metric: $value · $status';
  }

  @override
  String get runningCoachSampleOverlayPosture => 'Trunk lean value';

  @override
  String get runningCoachSampleOverlayArms => 'Arm value';

  @override
  String get runningCoachSampleOverlayFoot => 'Landing value';

  @override
  String get runningCoachSampleOverlayBounce => 'Bounce value';

  @override
  String get runningCoachSampleOverlayFrames => 'Pose frames';

  @override
  String get runningCoachSampleMistakeOverlayPosture => 'Trunk lean value';

  @override
  String get runningCoachSampleMistakeOverlayArms => 'Arm value';

  @override
  String get runningCoachSampleMistakeOverlayFoot => 'Landing value';

  @override
  String get runningCoachSampleMistakeOverlayBounce => 'Bounce value';

  @override
  String get runningCoachSampleMetricDetailScreenTitle => 'Evidence detail';

  @override
  String get runningCoachSampleMetricDetailHeroBody =>
      'Use this view to inspect the exact body position the sample overlay reads before it assigns this evidence item.';

  @override
  String get runningCoachSampleMetricDetailSampleLabel => 'Sample';

  @override
  String get runningCoachSampleMetricDetailValueLabel => 'Measured value';

  @override
  String get runningCoachSampleMetricDetailStatusLabel => 'Readout';

  @override
  String get runningCoachSampleMetricDetailKeyPositionTitle => 'Key position';

  @override
  String get runningCoachSampleMetricDetailReferenceTitle => 'Example A motion';

  @override
  String get runningCoachSampleMetricDetailReviewTitle => 'Example B motion';

  @override
  String get runningCoachSampleMetricDetailHowReadTitle =>
      'How the overlay reads it';

  @override
  String get runningCoachSampleMetricDetailGoodRangeTitle => 'Good range';

  @override
  String get runningCoachSamplePostureDetailGoodRange =>
      'Use the coaching guide range for trunk lean, then compare it with this clip\'s measured value.';

  @override
  String get runningCoachSamplePostureDetailKeyPosition =>
      'Mid-stance: the app draws a vertical line up from the hip center, then compares it with the hip-to-shoulder center line.';

  @override
  String get runningCoachSamplePostureDetailReference =>
      'Example A shows the shoulders slightly ahead of the hips without folding at the waist.';

  @override
  String get runningCoachSamplePostureDetailReview =>
      'A clip is marked for review when its measured lean falls outside the coaching range for this run.';

  @override
  String get runningCoachSamplePostureDetailHowRead =>
      'The app averages left/right shoulders and hips, builds one trunk axis, and measures how many degrees that axis moves away from vertical.';

  @override
  String get runningCoachSampleArmsDetailGoodRange =>
      'Elbow angle 80-105°, hands moving front-to-back near the ribs, with the opposite arm and leg paired.';

  @override
  String get runningCoachSampleArmsDetailKeyPosition =>
      'Arm-drive frame: each elbow angle is read while the opposite knee is driving forward.';

  @override
  String get runningCoachSampleArmsDetailReference =>
      'Example A shows compact elbows swinging front-to-back close to the ribs.';

  @override
  String get runningCoachSampleArmsDetailReview =>
      'The review clip opens the elbow angle, which can slow cadence and rotate the torso.';

  @override
  String get runningCoachSampleArmsDetailHowRead =>
      'The app connects shoulder, elbow, and wrist positions and flags the frame when the elbow opens too far.';

  @override
  String get runningCoachSampleLandingDetailGoodRange =>
      'Use the coaching guide range for foot contact near the hip line, then compare it with this clip\'s measured value.';

  @override
  String get runningCoachSampleLandingDetailKeyPosition =>
      'First-contact frame: the foot, ankle, and hip line show whether the step lands under the body.';

  @override
  String get runningCoachSampleLandingDetailReference =>
      'Example A lands close to the hip line, so contact supports forward movement.';

  @override
  String get runningCoachSampleLandingDetailReview =>
      'The review clip lands too far ahead of the hip, which reads as braking.';

  @override
  String get runningCoachSampleLandingDetailHowRead =>
      'The app measures the horizontal gap from the hip line to the contact ankle and toe during the landing window.';

  @override
  String get runningCoachSampleBounceDetailGoodRange =>
      'Use the coaching guide range for upper-body vertical change, then compare it with this clip\'s measured value.';

  @override
  String get runningCoachSampleBounceDetailKeyPosition =>
      'Stride window: the upper-body landmark path is compared across multiple frames.';

  @override
  String get runningCoachSampleBounceDetailReference =>
      'Example A keeps vertical motion compact, so energy stays directed forward.';

  @override
  String get runningCoachSampleBounceDetailReview =>
      'The review clip rises and drops more, making contact timing less stable.';

  @override
  String get runningCoachSampleBounceDetailHowRead =>
      'The app uses the central 80% of upper-body height samples to reduce one-frame spikes. It is a coaching estimate, not a jump-height measurement.';

  @override
  String get runningCoachDenseContactEvidenceTitle => 'Dense contact evidence';

  @override
  String get runningCoachDenseContactEvidenceBody =>
      'The full clip is scanned first. Foot-strike and stance-knee values come only from high-density re-read frames around validated contact.';

  @override
  String get runningCoachDenseContactKinematicEstimateLabel =>
      'Foot-path fallback';

  @override
  String get runningCoachDenseContactKinematicEstimateBody =>
      'If the ground line is unstable, the contact window is backed up by the visible landing leg\'s hip, knee, ankle, and vertical foot path. This is used for scores and coaching only after three repeated steps.';

  @override
  String get runningCoachDenseContactCoarseSamplesLabel => 'Full scan';

  @override
  String get runningCoachDenseContactDenseSamplesLabel => 'Contact detail';

  @override
  String get runningCoachDenseContactWindowsLabel => 'Windows';

  @override
  String get runningCoachDenseContactCandidateFramesLabel =>
      'Contact candidates';

  @override
  String get runningCoachDenseContactFramesLabel => 'Contact frames';

  @override
  String runningCoachDenseContactVerificationProgress(
      int verified, int required) {
    return '$verified/$required verified';
  }

  @override
  String get runningCoachDenseContactConfidenceLabel => 'Evidence';

  @override
  String get runningCoachDenseContactTimesLabel => 'Timestamps';

  @override
  String get runningCoachDenseContactUnavailable => 'No validated contact';

  @override
  String get runningCoachEvidenceTitle => 'Evidence from your video';

  @override
  String get runningCoachEvidenceBody =>
      'This frame is from the analyzed clip and supports the selected coaching focus.';

  @override
  String get runningCoachEvidenceDetailsTitle => 'Evidence details';

  @override
  String get runningCoachEvidenceInsufficientTitle => 'Retake this clip';

  @override
  String get runningCoachEvidenceInsufficientBody =>
      'There were not enough stable frames for this focus, so the app is not showing a precise score.';

  @override
  String runningCoachEvidenceMetricUnavailableTitle(Object metric) {
    return 'We cannot yet confirm the $metric measurement';
  }

  @override
  String runningCoachEvidenceMetricUnavailableBody(Object metric) {
    return 'There is not enough evidence for $metric, so its score and coaching are withheld. You can still review measurements from other metrics.';
  }

  @override
  String get runningCoachMeasurementStatusVerified => 'Verified';

  @override
  String get runningCoachMeasurementStatusObserved => 'Video observation';

  @override
  String get runningCoachMeasurementStatusUnavailable => 'Unavailable';

  @override
  String get runningCoachMeasurementCoverageTitle =>
      'What this video could measure';

  @override
  String get runningCoachMeasurementCoverageBody =>
      'Metrics are verified independently. Missing contact evidence does not invalidate measurements such as arm carriage or trunk position.';

  @override
  String get runningCoachScoreWithheldLabel => 'Score withheld';

  @override
  String get runningCoachScoreWithheldSummary =>
      'The video does not support a verified score.';

  @override
  String get runningCoachScoreWithheldValue => '—';

  @override
  String runningCoachScoreWithheldContactReason(Object reason) {
    return 'Contact evidence is not defensible: $reason';
  }

  @override
  String get runningCoachScoreWithheldGenericReason =>
      'One or more required measurements are limited, so the score is withheld instead of estimated.';

  @override
  String get runningCoachMeasuredMetricsTitle => 'Measured metrics';

  @override
  String get runningCoachMeasuredMetricsBody =>
      'Only values supported by this video are listed as verified. Limited observations are shown without a score or drill.';

  @override
  String get runningCoachReferenceRangeNotice =>
      'Reference ranges are general coaching references, not individualized medical or injury-risk limits.';

  @override
  String get runningCoachMetricVerticalBounceLabel => 'Vertical bounce (%)';

  @override
  String runningCoachMeasuredMetricSpmValue(Object value) {
    return '$value spm';
  }

  @override
  String runningCoachMeasuredMetricMsValue(Object value) {
    return '$value ms';
  }

  @override
  String get runningCoachMeasuredMetricWithinReference =>
      'Within general reference';

  @override
  String get runningCoachMeasuredMetricNearReferenceEdge =>
      'Near reference edge';

  @override
  String get runningCoachMeasuredMetricOutsideReference =>
      'Outside general reference';

  @override
  String get runningCoachMeasuredMetricInconsistent =>
      'Inconsistent across samples';

  @override
  String get runningCoachMeasuredMetricLimited => 'Limited evidence';

  @override
  String get runningCoachMeasuredMetricUnavailable =>
      'Unavailable from this video';

  @override
  String runningCoachMeasuredMetricSampleCount(int count) {
    return '$count samples';
  }

  @override
  String get runningCoachMeasuredMetricNoSamples => 'No defensible sample';

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
  String get runningCoachQualityReasonLabelLowCoverage => 'low coverage';

  @override
  String get runningCoachQualityReasonLabelLimitedSamples => 'limited samples';

  @override
  String get runningCoachQualityReasonLabelContactPhaseProxy => 'contact proxy';

  @override
  String get runningCoachQualityReasonLabelKinematicContact =>
      'kinematic contact';

  @override
  String get runningCoachQualityReasonLabelLowConfidence => 'low confidence';

  @override
  String get runningCoachQualityReasonLabelMissingContact => 'missing contact';

  @override
  String get runningCoachQualityReasonLabelMissingPoseFrames =>
      'missing pose frames';

  @override
  String get runningCoachQualityReasonLabelMissingMeasuredFrames =>
      'missing measured frames';

  @override
  String get runningCoachPerspectiveTooSmallLabel => 'Too far/small';

  @override
  String get runningCoachPerspectiveNotSideOnLabel => 'Not side-on enough';

  @override
  String get runningCoachPerspectiveBodyCutOffLabel => 'Body cut off';

  @override
  String get runningCoachPerspectiveScaleDriftLabel => 'Distance changed';

  @override
  String get runningCoachPerspectiveTooSmallReason =>
      'The runner is too small in the frame, so position-based coaching is limited.';

  @override
  String get runningCoachPerspectiveNotSideOnReason =>
      'The view is diagonal or front-facing enough that lower-body contact coaching is limited.';

  @override
  String get runningCoachPerspectiveBodyCutOffReason =>
      'The body is cut off in too many frames, so affected measurements are limited.';

  @override
  String get runningCoachPerspectiveScaleDriftReason =>
      'The runner changes size across the clip, so distance-sensitive measurements are limited.';

  @override
  String get runningCoachPerspectiveTooSmallRetake =>
      'Retake closer from the side with the full body visible.';

  @override
  String get runningCoachPerspectiveNotSideOnRetake =>
      'Retake from a true side view with the runner moving across the frame.';

  @override
  String get runningCoachPerspectiveBodyCutOffRetake =>
      'Keep head, hips, knees, and feet inside the frame for the full clip.';

  @override
  String get runningCoachPerspectiveScaleDriftRetake =>
      'Keep camera distance steady so the runner stays the same size.';

  @override
  String get runningCoachPerspectiveGenericRetake =>
      'Retake from a steady side view with the full runner visible.';

  @override
  String get runningCoachEvidenceVideoUnavailable =>
      'The saved video file is unavailable. The pose overlay still shows the analyzed frame.';

  @override
  String get runningCoachEvidencePoseFrameOnly =>
      'Showing the analyzed pose frame. The video file was not saved with this view.';

  @override
  String runningCoachEvidenceTimestamp(Object time) {
    return 'Evidence frame $time';
  }

  @override
  String runningCoachEvidenceFrameSummary(Object frame, Object value) {
    return '$frame: $value';
  }

  @override
  String get runningCoachEvidencePreviousFrame => 'Previous evidence frame';

  @override
  String get runningCoachEvidenceNextFrame => 'Next evidence frame';

  @override
  String get runningCoachEvidenceImageViewerTitle => 'Evidence image';

  @override
  String runningCoachEvidenceImageViewerMetadata(
      String kind, String role, String side, String time) {
    return '$kind · $role · $side · $time';
  }

  @override
  String get runningCoachEvidenceFocusView => 'Zoom to runner';

  @override
  String get runningCoachEvidenceOriginalView => 'Show full frame';

  @override
  String get runningCoachEvidenceOverlayOn => 'Show overlay';

  @override
  String get runningCoachEvidenceOverlayOff => 'Hide overlay';

  @override
  String get runningCoachEvidencePlay => 'Play evidence video';

  @override
  String get runningCoachEvidencePause => 'Pause evidence video';

  @override
  String runningCoachEvidenceFrameCount(int current, int total) {
    return 'Evidence $current/$total';
  }

  @override
  String get runningCoachEvidenceWhatSeenLabel => 'What I saw';

  @override
  String get runningCoachEvidenceOverlayBody =>
      'Colored guides show only the movement used for this coaching call. Your original video is unchanged.';

  @override
  String get runningCoachEvidenceCurrentOverlayTitle =>
      'Measurement in this frame';

  @override
  String get runningCoachEvidenceCurrentOverlayBody =>
      'The red guide marks only the body area used for this coaching call.';

  @override
  String get runningCoachEvidenceTransitionTitle => 'From current to next';

  @override
  String get runningCoachEvidenceTransitionBody =>
      'The blue target is the direction to use on your next step, not a pose drawn over the video.';

  @override
  String get runningCoachGoalMotionTitle => 'Your frame and target movement';

  @override
  String get runningCoachGoalMotionBody =>
      'Compare the same landing phase, then follow one target.';

  @override
  String get runningCoachGoalMotionActualLabel => 'My frame';

  @override
  String get runningCoachGoalMotionTargetLabel => 'Target runner';

  @override
  String get runningCoachGoalMotionFootnote =>
      'This line only shows the landing direction.';

  @override
  String get runningCoachGoalMotionPlay => 'Play goal movement';

  @override
  String get runningCoachGoalMotionPause => 'Pause goal movement';

  @override
  String get runningCoachTwoDComparisonTitle => 'Runner motion comparison';

  @override
  String get runningCoachTwoDCurrentLabel => 'My measured pose';

  @override
  String get runningCoachTwoDTargetLabel => 'Next landing';

  @override
  String get runningCoachTwoDVideoOverlayTitle =>
      'Overlay on your uploaded video';

  @override
  String get runningCoachCoordinateRigUnavailable =>
      'This frame does not contain enough joint coordinates to build the motion comparison.';

  @override
  String get runningCoachPoseComparisonTitle => 'Measured pose comparison';

  @override
  String get runningCoachPoseComparisonCurrentLabel => 'Current measured pose';

  @override
  String get runningCoachPoseComparisonTargetLabel => 'Reference target';

  @override
  String get runningCoachPoseComparisonUnavailable =>
      'This frame does not contain enough measured joint coordinates for a side-by-side pose comparison.';

  @override
  String get runningCoachHistoryEvidenceUnavailableTitle =>
      'No saved joint evidence';

  @override
  String get runningCoachHistoryEvidenceUnavailableBody =>
      'This older record has no saved pose frames. Its score and coaching goal are still available.';

  @override
  String get runningCoachEvidenceCurrentLabel => 'Current';

  @override
  String get runningCoachEvidenceNextLabel => 'Next';

  @override
  String runningCoachEvidenceWhatSeenBody(Object metric, Object time) {
    return '$metric at $time in your clip.';
  }

  @override
  String get runningCoachEvidenceWhyMattersLabel => 'Why it matters';

  @override
  String get runningCoachEvidenceTryLabel => 'Try this';

  @override
  String get runningCoachEvidenceRetakeLabel => 'Retake setup';

  @override
  String get runningCoachEvidenceRetakeBody =>
      'Record from the side with the whole body and both feet visible. Keep the phone still for a few clean steps.';

  @override
  String get runningCoachEvidenceQualityLimitedBadge => 'Evidence limited';

  @override
  String get runningCoachEvidenceQualityStableBadge => 'Body tracking stable';

  @override
  String get runningCoachEvidenceQualityCheckBadge => 'Tracking needs review';

  @override
  String get runningCoachEvidenceReasonLowConfidence =>
      'The body points moved or blurred too much for a confident read.';

  @override
  String get runningCoachEvidenceReasonLimitedFrames =>
      'There were too few stable frames for this metric.';

  @override
  String get runningCoachEvidenceReasonMissingPoseFrames =>
      'No analyzed pose frames were saved for this clip.';

  @override
  String get runningCoachEvidenceReasonMissingContact =>
      'The contact frame was not stable enough to support this lower-body metric.';

  @override
  String get runningCoachEvidenceReasonMissingMeasuredFrames =>
      'The saved pose frames do not include a defensible measurement moment for this metric.';

  @override
  String get runningCoachObservedValueBadge => 'Video observation';

  @override
  String get runningCoachObservedValueLabel => 'Video observation';

  @override
  String get runningCoachObservedValueBody =>
      'This is a coordinate observed in the video. It was not used for a score, good/needs-work judgment, or drill because the evidence is not sufficient.';

  @override
  String get runningCoachMeasurementUnavailableValue =>
      'No verified measurement';

  @override
  String get runningCoachContactRejectionMissingFootLandmark =>
      'Foot and ankle landmarks were not tracked reliably in the contact-candidate window. Keep both feet in frame throughout the clip.';

  @override
  String get runningCoachContactRejectionMissingContactJointChain =>
      'The candidate landing leg did not show its hip, knee, and ankle together on one side. Record a side view with the full leg visible.';

  @override
  String get runningCoachContactRejectionOutsideGround =>
      'The foot was not repeatedly confirmed near the ground line. Keep the camera fixed and include both the shoes and floor line.';

  @override
  String get runningCoachContactRejectionLowConfidence =>
      'Joint confidence was low in the contact-candidate window. Record in even light without camera shake.';

  @override
  String get runningCoachContactRejectionUnstableMotion =>
      'The foot\'s vertical movement did not form a stable contact moment. Use a sharp side-view clip with 3–6 strides.';

  @override
  String get runningCoachContactRejectionNotDescending =>
      'The foot did not descend into the ground band before contact, so the frame was treated as recovery or flight. Record a steady side view with the floor line visible.';

  @override
  String get runningCoachContactRejectionInsufficientMotionWindow =>
      'There were not enough continuous frames before and after contact to confirm foot movement. Record 5–10 seconds at a steady pace.';

  @override
  String get runningCoachContactRejectionInsufficientContactPersistence =>
      'The foot appeared near the ground, but a continuous contact state was not confirmed. Record 3–6 strides with both feet and the ground line visible.';

  @override
  String get runningCoachEvidenceContactLabel => 'Contact evidence';

  @override
  String get runningCoachEvidencePostureLabel => 'Posture frame';

  @override
  String get runningCoachEvidenceBounceLabel => 'Bounce frame';

  @override
  String get runningCoachEvidenceLandingLabel => 'Landing frame';

  @override
  String get runningCoachEvidenceKneeLabel => 'Knee frame';

  @override
  String get runningCoachEvidenceArmLabel => 'Arm frame';

  @override
  String get runningCoachEvidenceSamplesLabel => 'Samples';

  @override
  String get runningCoachEvidenceReliabilityLabel => 'Reliability';

  @override
  String get runningCoachEvidenceAggregateValueLabel => 'Representative value';

  @override
  String get runningCoachEvidenceGuideRangeLabel => 'Coaching guide';

  @override
  String get runningCoachEvidenceScoreCenterLabel => 'Scoring center';

  @override
  String get runningCoachEvidenceFrameRangeLabel => 'Evidence-frame value';

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
    return 'Average · $samples frames';
  }

  @override
  String get runningCoachMetricScoreBasis =>
      'The score shows how close the representative value is to the scoring center.';

  @override
  String get runningCoachEvidenceWhyThisResultLabel => 'Why this result';

  @override
  String get runningCoachEvidenceVideoMissingTitle => 'Video not available';

  @override
  String get runningCoachEvidenceVideoMissingBody =>
      'The saved video is missing, so this metric is shown as a text evidence summary instead.';

  @override
  String get runningCoachEvidenceMetricRhythm => 'Rhythm';

  @override
  String get runningCoachEvidenceMetricPosture => 'Posture';

  @override
  String get runningCoachEvidenceMetricLanding => 'Landing';

  @override
  String get runningCoachEvidenceMetricLandingObserved => 'Confirmed contact';

  @override
  String get runningCoachEvidenceMetricLandingCandidate => 'Contact candidate';

  @override
  String get runningCoachEvidenceMetricKnee => 'Knee';

  @override
  String get runningCoachEvidenceMetricBounce => 'Bounce';

  @override
  String get runningCoachEvidenceMetricArms => 'Arms';

  @override
  String runningCoachEvidenceRhythmValue(Object cadence, Object stepTime) {
    return '$cadence spm · $stepTime ms';
  }

  @override
  String get runningCoachEvidenceWhyRhythm =>
      'Verified contact timestamps set the cadence and step-time readout.';

  @override
  String get runningCoachEvidenceWhyPosture =>
      'The selected frame is closest to the measured forward-lean value across stable posture frames.';

  @override
  String get runningCoachEvidenceWhyLanding =>
      'Validated contact frames provide the foot-to-hip landing distance used for this metric.';

  @override
  String get runningCoachEvidenceWhyKnee =>
      'Validated stance-phase frames provide the knee angle used for this metric.';

  @override
  String get runningCoachEvidenceWhyBounce =>
      'The high and low hip trajectory frames show the vertical motion behind this metric.';

  @override
  String get runningCoachEvidenceWhyArms =>
      'The arm evidence comes from frames where elbow angle was actually measured.';

  @override
  String get runningCoachEvidenceRoleRhythmContact =>
      'Verified contact timestamp';

  @override
  String get runningCoachEvidenceRolePosture => 'Representative posture frame';

  @override
  String get runningCoachEvidenceRoleLowering => 'Lowering before contact';

  @override
  String get runningCoachEvidenceRoleInitialContact => 'Initial contact frame';

  @override
  String get runningCoachEvidenceRoleKneeFlexion =>
      'Maximum support knee flexion';

  @override
  String get runningCoachEvidenceRoleRecoveryKneeFlexion =>
      'Recovery knee fold';

  @override
  String get runningCoachEvidenceRolePushOff => 'Push-off frame';

  @override
  String get runningCoachEvidenceRoleTrajectoryHigh =>
      'High point of the hip path';

  @override
  String get runningCoachEvidenceRoleTrajectoryLow =>
      'Low point of the hip path';

  @override
  String get runningCoachEvidenceRoleArmClosed => 'Closed elbow phase';

  @override
  String get runningCoachEvidenceRoleArmOpen => 'Open elbow phase';

  @override
  String get runningCoachMyVideoEvidenceTitle => 'My video evidence';

  @override
  String runningCoachEvidenceSummaryTimestamp(Object time, int samples) {
    return '$time · $samples samples';
  }

  @override
  String get runningCoachOpenMyVideoEvidenceAction =>
      'View in my video evidence';

  @override
  String get runningCoachPoseEvidenceBlockerFullBody =>
      'Step back until your head and both feet stay on screen.';

  @override
  String get runningCoachPoseEvidenceBlockerSideView =>
      'Turn to a steady side view and keep it there.';

  @override
  String get runningCoachPoseEvidenceBlockerCoreJoints =>
      'Hold the camera steady so the coach can find your joints.';

  @override
  String get runningCoachPoseEvidenceBlockerGaitPhase =>
      'Keep running in the same view for a few more steps.';

  @override
  String get runningCoachFieldValidationTitle => 'Field validation';

  @override
  String get runningCoachFieldValidationPrivacyNote =>
      'Uses saved counters and pose-joint evidence only. Camera frames are not stored.';

  @override
  String get runningCoachFieldValidationStatusInsufficient => 'Insufficient';

  @override
  String get runningCoachFieldValidationStatusNeedsReview => 'Needs review';

  @override
  String get runningCoachFieldValidationStatusReady => 'Ready for calibration';

  @override
  String get runningCoachFieldValidationBodyInsufficient =>
      'Not enough stable field evidence for threshold tuning. Repeat capture after the checks below.';

  @override
  String get runningCoachFieldValidationBodyNeedsReview =>
      'Useful field evidence was captured, but review the measurable checks before tuning thresholds.';

  @override
  String get runningCoachFieldValidationBodyReady =>
      'This run is ready to compare during threshold calibration. Repeat the same profile before changing thresholds.';

  @override
  String runningCoachFieldValidationProfileValue(Object profile) {
    return 'Profile: $profile';
  }

  @override
  String runningCoachFieldValidationQualityValue(int score) {
    return 'Field quality $score%';
  }

  @override
  String get runningCoachFieldValidationNextChecksTitle =>
      'Next capture checks';

  @override
  String get runningCoachFieldValidationAllChecksPassed =>
      'All measurable field checks passed.';

  @override
  String get runningCoachFieldValidationCheckCaptureReadiness =>
      'Capture readiness';

  @override
  String get runningCoachFieldValidationCheckPhaseCoverage => 'Phase coverage';

  @override
  String get runningCoachFieldValidationCheckTrackedFrames => 'Tracked frames';

  @override
  String get runningCoachFieldValidationCheckUsableSamples =>
      'Usable pose samples';

  @override
  String get runningCoachFieldValidationCheckTimingConfidence =>
      'Timing confidence';

  @override
  String get runningCoachFieldValidationCheckSideViewConfidence =>
      'Side-view confidence';

  @override
  String get runningCoachFieldValidationCheckTrackingConfidence =>
      'Tracking confidence';

  @override
  String get runningCoachFieldValidationCheckBodyVisibility => 'Body loss';

  @override
  String get runningCoachFieldValidationCheckStepEvidence => 'Step evidence';

  @override
  String get runningCoachFieldValidationCheckLandingEvidence =>
      'Landing evidence';

  @override
  String runningCoachFieldValidationCountValue(int observed, int required) {
    return '$observed / target $required';
  }

  @override
  String runningCoachFieldValidationPercentValue(int current, int target) {
    return '$current% / target $target%';
  }

  @override
  String runningCoachFieldValidationPercentMaxValue(int current, int target) {
    return '$current% / max $target%';
  }

  @override
  String get runningCoachCalibrationReadinessTitle =>
      'Calibration repeatability';

  @override
  String get runningCoachCalibrationReadinessStatusCurrentNotReady =>
      'Current capture not ready';

  @override
  String get runningCoachCalibrationReadinessStatusNeedsMore =>
      'Need more same-profile sessions';

  @override
  String get runningCoachCalibrationReadinessStatusVariationReview =>
      'Review variation';

  @override
  String get runningCoachCalibrationReadinessStatusReady =>
      'Ready for threshold calibration';

  @override
  String get runningCoachCalibrationReadinessBodyCurrentNotReady =>
      'This run is not field-validation-ready yet. Fix the field checks before using it for repeatability.';

  @override
  String get runningCoachCalibrationReadinessBodyNeedsMore =>
      'Save at least 3 field-validation-ready sessions with this same profile before threshold calibration.';

  @override
  String get runningCoachCalibrationReadinessBodyVariationReview =>
      'Same-profile captures vary too much for paid-quality threshold calibration. Review the checks before tuning.';

  @override
  String get runningCoachCalibrationReadinessBodyReady =>
      'This profile has enough repeatable field evidence for threshold calibration.';

  @override
  String get runningCoachCalibrationReadinessPrivacyNote =>
      'Uses saved live sprint report counters and joint-evidence summaries only. No camera frames, uploads, or raw video are used; profiles and thresholds are not changed.';

  @override
  String runningCoachCalibrationReadinessScoreValue(int score) {
    return 'Repeatability $score%';
  }

  @override
  String runningCoachCalibrationReadinessReadySessionsValue(
      int ready, int required) {
    return 'Ready $ready/$required';
  }

  @override
  String runningCoachCalibrationReadinessSameProfileSessionsValue(int count) {
    return 'Same profile $count';
  }

  @override
  String get runningCoachCalibrationReadinessChecksTitle => 'Compact checks';

  @override
  String get runningCoachCalibrationReadinessCheckCurrentFieldValidation =>
      'Current field validation';

  @override
  String get runningCoachCalibrationReadinessCheckSameProfileReadySessions =>
      'Same-profile ready sessions';

  @override
  String get runningCoachCalibrationReadinessCheckAverageFieldQuality =>
      'Average field quality';

  @override
  String get runningCoachCalibrationReadinessCheckTimingVariation =>
      'Timing confidence spread';

  @override
  String get runningCoachCalibrationReadinessCheckSideViewVariation =>
      'Side-view confidence spread';

  @override
  String get runningCoachCalibrationReadinessCheckTrackingVariation =>
      'Tracking confidence spread';

  @override
  String get runningCoachCalibrationReadinessCheckTrackedFrameVariation =>
      'Tracked-frame rate spread';

  @override
  String get runningCoachCalibrationReadinessCheckEligiblePoseVariation =>
      'Eligible-pose rate spread';

  @override
  String get runningCoachCalibrationReadinessCheckLandingContactVariation =>
      'Landing/contact rate spread';

  @override
  String runningCoachCalibrationReadinessCheckCountValue(
      int observed, int required) {
    return '$observed / required $required';
  }

  @override
  String runningCoachCalibrationReadinessCheckPercentValue(
      int current, int target) {
    return '$current% / target $target%';
  }

  @override
  String runningCoachCalibrationReadinessCheckPercentMaxValue(
      int current, int target) {
    return '$current% / max $target%';
  }

  @override
  String get runningCoachFieldMatrixTitle => 'Field coverage matrix';

  @override
  String get runningCoachFieldMatrixStatusNotReady => 'Not ready';

  @override
  String get runningCoachFieldMatrixStatusBuilding => 'Building coverage';

  @override
  String get runningCoachFieldMatrixStatusRecommendationReady =>
      'Ready for recommendation coverage';

  @override
  String get runningCoachFieldMatrixStatusComplete =>
      'Matrix coverage complete';

  @override
  String get runningCoachFieldMatrixBodyNotReady =>
      'Saved field-ready sessions do not yet cover the required rear-phone baseline.';

  @override
  String get runningCoachFieldMatrixBodyBuilding =>
      'Keep adding field-ready runs in the missing setup bands before using this for a stronger recommendation.';

  @override
  String get runningCoachFieldMatrixBodyRecommendationReady =>
      'The baseline and a meaningful geometry variation are covered. Remaining matrix gaps are still listed.';

  @override
  String get runningCoachFieldMatrixBodyComplete =>
      'All required setup bands are represented by field-ready saved sessions.';

  @override
  String get runningCoachFieldMatrixPrivacyNote =>
      'Uses only saved setup summaries. Unknown legacy context does not count, and no camera frames, model names, uploads, or video are stored.';

  @override
  String runningCoachFieldMatrixCoverageValue(int covered, int required) {
    return '$covered/$required scenarios';
  }

  @override
  String runningCoachFieldMatrixScoreValue(int score) {
    return 'Coverage $score%';
  }

  @override
  String runningCoachFieldMatrixEligibleSessionsValue(int count) {
    return '$count field-ready';
  }

  @override
  String runningCoachFieldMatrixUnknownContextValue(int count) {
    return '$count unknown context';
  }

  @override
  String get runningCoachFieldMatrixMissingTitle => 'Missing scenarios';

  @override
  String get runningCoachFieldMatrixMissingNone =>
      'No required setup bands are missing.';

  @override
  String get runningCoachFieldMatrixScenarioRearPhoneNormalClear =>
      'Rear phone · normal distance · clear side';

  @override
  String get runningCoachFieldMatrixScenarioRearPhoneCloseClear =>
      'Rear phone · close distance · clear side';

  @override
  String get runningCoachFieldMatrixScenarioRearPhoneFarClear =>
      'Rear phone · far distance · clear side';

  @override
  String get runningCoachFieldMatrixScenarioRearPhoneNormalPartial =>
      'Rear phone · normal distance · partial side';

  @override
  String get runningCoachCalibrationCandidateTitle =>
      'Calibration recommendation';

  @override
  String get runningCoachCalibrationCandidateStatusNotReady => 'Not ready';

  @override
  String get runningCoachCalibrationCandidateStatusKeepCurrent =>
      'Keep current profile';

  @override
  String get runningCoachCalibrationCandidateStatusRecommendation =>
      'Safe recommendation only';

  @override
  String get runningCoachCalibrationCandidateBodyNotReady =>
      'Repeatability or field coverage is not ready enough to recommend a stricter capture profile.';

  @override
  String get runningCoachCalibrationCandidateBodyKeepCurrent =>
      'The current profile remains the safer choice based on saved summaries.';

  @override
  String get runningCoachCalibrationCandidateBodyRecommendation =>
      'A stricter profile passed the saved-session checks. Treat this as a recommendation only.';

  @override
  String get runningCoachCalibrationCandidatePrivacyNote =>
      'No profile, threshold, user setting, upload, raw video, or camera frame is changed automatically.';

  @override
  String runningCoachCalibrationCandidateScoreValue(int score) {
    return 'Recommendation $score%';
  }

  @override
  String runningCoachCalibrationCandidateEligibleValue(int count) {
    return '$count eligible sessions';
  }

  @override
  String runningCoachCalibrationCandidateCoverageValue(
      int passed, int eligible) {
    return '$passed/$eligible pass candidate';
  }

  @override
  String runningCoachCalibrationCandidateMarginValue(int percent) {
    return 'Evidence margin $percent%';
  }

  @override
  String runningCoachCalibrationCandidateComparisonValue(
      Object current, Object candidate) {
    return '$current → recommend $candidate';
  }

  @override
  String runningCoachCalibrationCandidateComparisonKeep(Object profile) {
    return 'Current: $profile';
  }

  @override
  String get runningCoachCalibrationCandidateBlockersTitle => 'Blockers';

  @override
  String get runningCoachCalibrationCandidateNoBlockers =>
      'No blockers in the saved summaries.';

  @override
  String get runningCoachCalibrationCandidateBlockerRepeatability =>
      'Repeatability not ready';

  @override
  String get runningCoachCalibrationCandidateBlockerFieldMatrix =>
      'Field matrix incomplete';

  @override
  String get runningCoachCalibrationCandidateBlockerNoStricter =>
      'Already strictest profile';

  @override
  String get runningCoachCalibrationCandidateBlockerEvidence =>
      'Candidate evidence failed';

  @override
  String get runningCoachCalibrationCandidateBlockerMargin =>
      'Evidence margin too small';

  @override
  String get runningCoachCalibrationCandidateBlockerCoverage =>
      'Coverage regression';

  @override
  String get runningCoachCalibrationCandidateBlockerHoldout =>
      'Latest holdout failed';

  @override
  String get runningCoachSelectedVideoLabel => 'Selected video';

  @override
  String get runningCoachNoVideoSelected => 'No video selected yet.';

  @override
  String get runningCoachPickVideoAction => 'Pick video';

  @override
  String get runningCoachChangeVideoAction => 'Change';

  @override
  String get runningCoachAnalyzeAction => 'Analyze run';

  @override
  String get runningCoachAnalysisInProgress => 'Analyzing...';

  @override
  String get runningCoachPickVideoFailed => 'Could not open the video picker.';

  @override
  String get runningCoachUnsupportedPlatform =>
      'Running video analysis is not available on this device.';

  @override
  String get runningCoachNativeAnalyzerUnavailable =>
      'This app build does not include the running video analyzer yet. Reinstall the latest mobile app build and try again.';

  @override
  String get runningCoachWebAnalyzerUnavailable =>
      'The browser video analyzer could not start. Refresh the page and try again.';

  @override
  String get runningCoachWebVideoDecodeFailed =>
      'This browser could not read the selected video. Try an MP4 or MOV file.';

  @override
  String get runningCoachVideoFileMissing =>
      'The selected video file could not be found.';

  @override
  String get runningCoachVideoTooShort =>
      'The video is too short. Record at least a few running steps.';

  @override
  String get runningCoachVideoTooLong =>
      'The video exceeds the safe on-device decoding budget. Trim it to the section where the runner is visible.';

  @override
  String get runningCoachVideoTooLarge =>
      'The file exceeds the safe in-memory analysis limit. Export a smaller file while keeping the runner visible.';

  @override
  String get runningCoachWebVideoTooLarge =>
      'This browser file is over the 96 MB analysis limit. Export a smaller clip before trying again.';

  @override
  String get runningCoachVideoTooBlurry =>
      'This video is too blurry for a precise result. Keep the phone still and record a clearer side view with your whole body and both feet visible.';

  @override
  String get runningCoachNoPoseDetected =>
      'Clothing is not used for this check, but the runner\'s joints could not be tracked well enough. Try a clearer side-view clip with elbows, knees, and feet visible.';

  @override
  String get runningCoachInsufficientContactEvidence =>
      'The clip did not include enough verified foot-contact frames. Try a clearer side view with both feet visible through landing.';

  @override
  String get runningCoachAnalysisFailedGeneric =>
      'Running analysis failed. Try another clip with a clearer side view.';

  @override
  String get runningCoachAnalysisTimedOut =>
      'Analysis took too long. Try a shorter, clearer side-view clip.';

  @override
  String get runningCoachLowerBodyEvidenceLimited =>
      'Foot-strike and knee readings are reference only. Contact evidence was limited, so they are not used for this score or next goal.';

  @override
  String get runningCoachResultsTitle => 'Coaching results';

  @override
  String get runningCoachAnalysisQualityTitle => 'Analysis quality';

  @override
  String get runningCoachAnalysisQualityStrong =>
      'Enough evidence was captured';

  @override
  String runningCoachAnalysisQualityStrongBody(int count) {
    return 'This goal uses $count reliable measurements and verified landing evidence.';
  }

  @override
  String get runningCoachAnalysisQualityStrongSummary =>
      'This video has enough reliable evidence to set your next goal.';

  @override
  String get runningCoachAnalysisQualityLimited =>
      'Use some readings as reference';

  @override
  String runningCoachAnalysisQualityLimitedBody(int count) {
    return '$count measurements are reliable. Foot and knee feedback is used only when its evidence is sufficient.';
  }

  @override
  String get runningCoachAnalysisQualityLimitedSummary =>
      'Some form checks are best used as reference only.';

  @override
  String get runningCoachAnalysisQualityRetake => 'A retake is recommended';

  @override
  String get runningCoachAnalysisQualityRetakeBody =>
      'The clip does not contain enough joint or landing evidence to set a reliable goal.';

  @override
  String get runningCoachAnalysisQualityDetailsTitle =>
      'View measurement details';

  @override
  String get runningCoachAnalysisQualityPosePairingLimited =>
      'Contact timing was verified, but there are not enough paired full-body pose frames for per-step foot, knee, trunk, and arm ranges.';

  @override
  String get runningCoachVerifiedContactsLabel => 'Verified landings';

  @override
  String get runningCoachResultOneChangeTitle => 'Change one thing first';

  @override
  String get runningCoachNextGoalTitle => 'Next goal';

  @override
  String get runningCoachNextGoalRepeat =>
      'For your next three runs, focus only on this.';

  @override
  String get runningCoachResultNextRunCueLabel => 'On your next run';

  @override
  String get runningCoachResultOneChangeBody =>
      'Use this one cue for a few steps, then record again to see the change.';

  @override
  String get runningCoachResultKeepOneThingBody =>
      'Keep this strength through the next few steps, then record again to make sure it stays consistent.';

  @override
  String get runningCoachResultDetailsTitle => 'Detailed review';

  @override
  String get runningCoachReportDetailsBody =>
      'See all five checks at a glance. Open the matching video evidence only when you want to inspect a frame.';

  @override
  String get runningCoachAnalysisHistoryTitle => 'Coaching analysis history';

  @override
  String get runningCoachAnalysisHistoryBody =>
      'Review each uploaded video and live sprint session with its key coaching focus and correction guide.';

  @override
  String runningCoachAnalysisHistoryAction(int count) {
    return 'All $count';
  }

  @override
  String get runningCoachAnalysisHistoryEmpty =>
      'No saved coaching analyses yet.';

  @override
  String get runningCoachHistoryClearAllAction => 'Clear all';

  @override
  String get runningCoachHistoryClearAllTitle => 'Clear all coaching analyses?';

  @override
  String get runningCoachHistoryClearAllBody =>
      'This removes every saved analysis, locally saved evidence frame, and any video you chose to save on this device.';

  @override
  String get runningCoachHistoryDeleteTitle => 'Delete this analysis?';

  @override
  String get runningCoachHistoryDeleteBody =>
      'This removes the analysis, its locally saved evidence frames, and its saved video if one exists.';

  @override
  String get runningCoachSaveVideoTitle => 'Save this video with the analysis';

  @override
  String get runningCoachSaveVideoBody =>
      'Off by default. Turn this on only if you want a local copy kept until you delete the analysis.';

  @override
  String get runningCoachVideoSaveFailedTitle => 'Video was not saved';

  @override
  String get runningCoachVideoSaveFailedBody =>
      'The analysis is saved, but this device could not keep a local video copy. You can still review this result now.';

  @override
  String get runningCoachAnalysisHistorySaveFailedTitle =>
      'Analysis is complete, but it was not saved to history';

  @override
  String get runningCoachAnalysisHistorySaveFailedBody =>
      'You can review this result now, but it may not remain in your analysis history after you close this screen. Delete an older analysis and try again.';

  @override
  String get runningCoachAnalysisHistoryDetailTitle => 'Analysis review';

  @override
  String get runningCoachAnalysisHistoryPrimaryFocus => 'Key coaching focus';

  @override
  String runningCoachHistoryMetricCount(int count) {
    return '$count metrics';
  }

  @override
  String get runningCoachHistoryFullReportTitle => 'Full form report';

  @override
  String runningCoachHistoryFullReportBody(int count) {
    return 'This saved report includes all $count measured coaching metrics. Open each item for the same cue and drill shown after analysis.';
  }

  @override
  String get runningCoachAnalysisResultScreenTitle => 'Running analysis result';

  @override
  String get runningCoachHistoryVideoSaved => 'Video saved';

  @override
  String get runningCoachArchivedVideoTitle => 'Analyzed video';

  @override
  String get runningCoachArchivedVideoBody =>
      'This video is saved with the analysis history so you can review the same form again.';

  @override
  String get runningCoachArchivedVideoPlay => 'Play';

  @override
  String get runningCoachArchivedVideoPause => 'Pause';

  @override
  String get runningCoachArchivedVideoUnavailable =>
      'The saved video cannot be opened. The file may have been removed from this device.';

  @override
  String get runningCoachEvidenceFramesTitle => 'Saved evidence frames';

  @override
  String get runningCoachEvidenceFramesBody =>
      'These still frames and pose markers stay only on this device. Deleting the analysis removes them. The full video is saved only when you turned on video saving.';

  @override
  String runningCoachEvidenceArchiveSavedTitle(int count) {
    return '$count evidence image(s) saved';
  }

  @override
  String get runningCoachEvidenceArchiveSavedBody =>
      'These still frames are separate from the optional source video and stay only on this device.';

  @override
  String runningCoachEvidenceArchivePartialTitle(int saved, int requested) {
    return '$saved/$requested evidence images saved';
  }

  @override
  String runningCoachEvidenceArchivePartialBody(Object reason) {
    return 'Some still frames could not be saved: $reason';
  }

  @override
  String get runningCoachEvidenceArchiveFailedTitle =>
      'Evidence images were not saved';

  @override
  String runningCoachEvidenceArchiveFailedBody(Object reason) {
    return 'The analysis is saved, but the still evidence images could not be kept: $reason';
  }

  @override
  String get runningCoachEvidenceArchiveNotRequestedTitle =>
      'No evidence image requested';

  @override
  String get runningCoachEvidenceArchiveNotRequestedBody =>
      'This analysis did not produce a reliable still frame to archive. The measured pose data remains in the result.';

  @override
  String get runningCoachEvidenceArchiveReasonSourceUnavailable =>
      'the source video was unavailable after analysis.';

  @override
  String get runningCoachEvidenceArchiveReasonExtractionEmpty =>
      'no JPEG frame could be extracted at the selected evidence timestamps.';

  @override
  String get runningCoachEvidenceArchiveReasonStorageUnavailable =>
      'local image storage was unavailable.';

  @override
  String get runningCoachEvidenceArchiveReasonFileWrite =>
      'the device could not write the JPEG file.';

  @override
  String get runningCoachEvidenceArchiveReasonWebLimit =>
      'the browser storage limit would be exceeded.';

  @override
  String get runningCoachEvidenceArchiveReasonPlatformUnavailable =>
      'this app build could not run the evidence-frame extractor.';

  @override
  String get runningCoachEvidenceArchiveReasonUnknown =>
      'the device reported an unknown image-save error.';

  @override
  String get runningCoachEvidenceImageReadFailed => 'Image unavailable';

  @override
  String get runningCoachEvidenceImageReadFailedReason =>
      'The saved file may have been removed from this device.';

  @override
  String get runningCoachAnalysisGuideTitle => 'Correction point in pictures';

  @override
  String get runningCoachAnalysisGuideBody =>
      'Use the picture to see what to change first.';

  @override
  String get runningCoachGoodFormGuideTitle => 'Good running form at a glance';

  @override
  String get runningCoachGoodFormGuideBody =>
      'Not one perfect still pose—these are five movements to repeat while running.';

  @override
  String get runningCoachGoodFormPrinciplePosture =>
      'Keep the shoulder-to-hip line gently forward without folding at the waist.';

  @override
  String get runningCoachGoodFormPrincipleBounce =>
      'Keep the rhythm moving forward instead of bouncing upward.';

  @override
  String get runningCoachGoodFormPrincipleFootStrike =>
      'Let the foot meet the ground close beneath your hips.';

  @override
  String get runningCoachGoodFormPrincipleKnee =>
      'Allow the knee to absorb the landing without collapsing.';

  @override
  String get runningCoachGoodFormPrincipleArms =>
      'Let relaxed elbows swing forward and back with the rhythm.';

  @override
  String get runningCoachGoodFormAction => 'Good form';

  @override
  String get runningCoachGoodFormScreenTitle => 'Good running form';

  @override
  String get runningCoachGoodFormIntroTitle =>
      'For new and experienced runners';

  @override
  String get runningCoachGoodFormIntroBody =>
      'Start with ‘Start here.’ Once it feels natural, use ‘Look closer’ to check symmetry, timing, and movement across several strides.';

  @override
  String get runningCoachGoodFormCycleTitle => 'Continuous form loop';

  @override
  String get runningCoachGoodFormCycleBody =>
      'One reference runner loops through landing, support, push-off, recovery, and the next landing with shared scale and ground alignment.';

  @override
  String get runningCoachGoodFormPhaseLandingTitle => 'Landing';

  @override
  String get runningCoachGoodFormPhaseLandingCue =>
      'Place the foot lightly near the hips instead of reaching it forward.';

  @override
  String get runningCoachGoodFormPhaseLandingFocus =>
      'Landing foot near the shared ground line';

  @override
  String get runningCoachGoodFormPhaseSupportTitle => 'Support';

  @override
  String get runningCoachGoodFormPhaseSupportCue =>
      'Let the knee and ankle absorb load as the body moves smoothly over the foot.';

  @override
  String get runningCoachGoodFormPhaseSupportFocus =>
      'Supporting knee over the loading leg';

  @override
  String get runningCoachGoodFormPhasePushOffTitle => 'Push-off';

  @override
  String get runningCoachGoodFormPhasePushOffCue =>
      'Press down, then let the foot travel behind as the body moves forward.';

  @override
  String get runningCoachGoodFormPhasePushOffFocus =>
      'Push-off toe and foot against the ground line';

  @override
  String get runningCoachGoodFormPhaseRecoveryTitle => 'Recovery';

  @override
  String get runningCoachGoodFormPhaseRecoveryCue =>
      'Recover the heel naturally and bring the knee through for the next landing.';

  @override
  String get runningCoachGoodFormPhaseRecoveryFocus =>
      'Recovery knee and heel moving through together';

  @override
  String runningCoachGoodFormCycleObservationLabel(String phase) {
    return 'Observe: $phase';
  }

  @override
  String runningCoachGoodFormCycleFocusLegend(String focus) {
    return 'Blue mark: $focus';
  }

  @override
  String get runningCoachGoodFormSlowMotionAction => 'Slow view';

  @override
  String get runningCoachGoodFormStepAction => 'Next phase';

  @override
  String get runningCoachGoodFormRestartStepsAction => 'Restart four steps';

  @override
  String get runningCoachGoodFormPlayAction => 'Play';

  @override
  String get runningCoachGoodFormPauseAction => 'Pause';

  @override
  String get runningCoachGoodFormStepFrameAction => 'Next frame';

  @override
  String get runningCoachGoodFormSpeedNormal => 'Normal';

  @override
  String get runningCoachGoodFormSpeedSlow => 'Slow';

  @override
  String get runningCoachGoodFormTechniqueTitle =>
      'Illustrated technique guide';

  @override
  String get runningCoachGoodFormTechniqueBody =>
      'Red shows a common mistake; blue shows the recommended movement. Focus on the marked relationship and direction, not the model\'s body shape.';

  @override
  String get runningCoachGoodFormCommonLabel => 'Common mistake';

  @override
  String get runningCoachGoodFormRecommendedLabel => 'Recommended';

  @override
  String get runningCoachGoodFormBeginnerLabel => 'Start here';

  @override
  String get runningCoachGoodFormExperiencedLabel => 'Look closer';

  @override
  String get runningCoachGoodFormExperiencedPosture =>
      'Across several frames, check that the shoulder-to-hip line stays slightly forward instead of the waist folding as pace changes.';

  @override
  String get runningCoachGoodFormExperiencedBounce =>
      'Do not judge one peak frame. Compare hip-height change and contact rhythm across several strides for a repeatable pattern.';

  @override
  String get runningCoachGoodFormExperiencedFootStrike =>
      'At contact, compare foot-to-hip distance, shin direction, and whether the same pattern repeats differently on the left and right.';

  @override
  String get runningCoachGoodFormExperiencedKnee =>
      'After contact, check that the knee neither locks nor collapses abruptly, then bends and extends smoothly through support.';

  @override
  String get runningCoachGoodFormExperiencedArms =>
      'Check shoulder tension, elbow bend, hands crossing the midline, and differences between left and right arm swing.';

  @override
  String runningCoachGoodFormIllustrationSemantics(String metric) {
    return 'Illustrated comparison for $metric: common mistake and recommended movement';
  }

  @override
  String get runningCoachGoodFormGuideFootnoteTitle => 'What this guide is for';

  @override
  String get runningCoachGoodFormGuideFootnoteBody =>
      'This guide does not prescribe one perfect shape. Form varies with body, pace, and setting; in an analysis result, prioritize the evidence from your own video.';

  @override
  String get runningCoachAnalysisGuideRangeLabel => 'Good range';

  @override
  String get runningCoachAnalysisGuideFindingLabel => 'Why it was flagged';

  @override
  String get runningCoachAnalysisGuideCueLabel => 'Action cue';

  @override
  String get runningCoachAnalysisGuideDrillLabel => 'Recommended drill';

  @override
  String get runningCoachTargetGuideTitle => 'Target movement example';

  @override
  String get runningCoachTargetGuideBody =>
      'This is a form example. Copy the blue marker, not the model\'s exact body shape.';

  @override
  String get runningCoachMeasuredPoseTitle => 'Move this way from your pose';

  @override
  String get runningCoachMeasuredPoseBody =>
      'Red marks the current point; blue marks the next target. Follow one arrow at a time.';

  @override
  String get runningCoachIllustrationTitle => 'Next movement reference';

  @override
  String get runningCoachIllustrationBody =>
      'Red marks the current issue. Blue shows the one movement to try next.';

  @override
  String get runningCoachIllustrationGoodBody =>
      'This video\'s value is inside the coaching reference for this item. It does not mean your entire form is universally good.';

  @override
  String get runningCoachIllustrationFootnote =>
      'This is a generic runner reference matched to your measurement, not a reconstruction of your body.';

  @override
  String get runningCoachMeasuredPoseActualLabel => 'Current point';

  @override
  String get runningCoachMeasuredPoseTargetLabel => 'Next target';

  @override
  String get runningCoachMeasuredPoseTargetRangeLabel => 'Coaching reference';

  @override
  String get runningCoachMeasuredPoseCueLabel => 'Try this movement';

  @override
  String get runningCoachMeasuredPoseFootnote =>
      'The blue marker is a location or range to move a joint toward on your next step. It does not replace your measured pose.';

  @override
  String get runningCoachMeasuredPoseImproveLegend =>
      'Red: current measurement · Blue: next target';

  @override
  String get runningCoachMeasuredPoseGoodLegend =>
      'Green: this video\'s value is inside the coaching reference for this item';

  @override
  String get runningCoachMeasuredPoseGoodBody =>
      'Your current value is inside the coaching reference for this item. It does not mean your entire form is universally good.';

  @override
  String get runningCoachMeasuredPoseGoodCue =>
      'Keep this movement, and check the other items too.';

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
  String get runningCoachGuideRangePosture =>
      'Goal: slight trunk lean, without bending at the waist';

  @override
  String get runningCoachGuideRangeBounce =>
      'Goal: quick steps with little up-down motion';

  @override
  String get runningCoachGuideRangeFootStrike =>
      'Goal: foot lands close under the hips';

  @override
  String get runningCoachGuideRangeKnee =>
      'Goal: landing knee stays soft, not locked';

  @override
  String get runningCoachGuideRangeArm =>
      'Goal: elbows stay bent and hands move front to back';

  @override
  String get runningCoachMetricScoreLabel => 'Metric score';

  @override
  String runningCoachConfidenceLabel(int percent) {
    return 'Confidence $percent%';
  }

  @override
  String get runningCoachSessionSourceUploadVideo => 'Video analysis';

  @override
  String get runningCoachQualityReasonLowCoverage =>
      'The runner was not clear for enough of the clip. Check this again with a clearer video.';

  @override
  String get runningCoachQualityReasonLimitedSamples =>
      'Only a few clear frames were read. Record once more from the same side.';

  @override
  String get runningCoachQualityReasonContactPhaseProxy =>
      'Foot landing was hard to confirm. Check the landing and knee again.';

  @override
  String get runningCoachQualityReasonKinematicContactEstimate =>
      'The contact window was confirmed from the foot trajectory and visible joint chain instead of the ground line. It was used for coaching only after three repeated steps.';

  @override
  String get runningCoachQualityReasonLowConfidence =>
      'The camera did not see the joints clearly. Hold the camera steady.';

  @override
  String get runningCoachQualityReasonGeneric =>
      'The video was not clear enough. Record again from the same side.';

  @override
  String get runningCoachOverallHeadlineStrong => 'Strong running shape';

  @override
  String get runningCoachOverallHeadlineSolid =>
      'Solid base with one clear fix';

  @override
  String get runningCoachOverallHeadlineNeedsWork =>
      'Build a cleaner running pattern';

  @override
  String runningCoachOverallSummary(int score) {
    return 'Overall running score $score/100';
  }

  @override
  String get runningCoachOverallScoreLabel => 'Overall score';

  @override
  String get runningCoachDurationLabel => 'Clip';

  @override
  String get runningCoachFramesAnalyzedLabel => 'Frames';

  @override
  String get runningCoachCoverageLabel => 'Coverage';

  @override
  String get runningCoachMetricScoresTitle => 'Metric scores';

  @override
  String get runningCoachFocusTitle => 'Focus first';

  @override
  String get runningCoachMaintainTitle => 'Keep these';

  @override
  String runningCoachMetricScore(int score) {
    return 'Score $score';
  }

  @override
  String runningCoachPriorityLabel(int priority) {
    return 'Priority $priority';
  }

  @override
  String get runningCoachMetricValueLabel => 'Measured value';

  @override
  String get runningCoachBodyRegionUpper => 'Upper body';

  @override
  String get runningCoachBodyRegionLower => 'Lower body';

  @override
  String get runningCoachBodyRegionWhole => 'Whole-body rhythm';

  @override
  String get runningCoachStatusGood => 'Good';

  @override
  String get runningCoachStatusWatch => 'Watch';

  @override
  String get runningCoachStatusNeedsWork => 'Needs work';

  @override
  String runningCoachLeanValue(Object value) {
    return '$value° trunk lean';
  }

  @override
  String runningCoachBounceValue(Object value) {
    return '$value% up-down motion';
  }

  @override
  String runningCoachFootStrikeValue(Object value) {
    return '${value}x foot reach';
  }

  @override
  String runningCoachKneeValue(Object value) {
    return '$value° landing knee';
  }

  @override
  String runningCoachArmValue(Object value) {
    return '$value° arm bend';
  }

  @override
  String runningCoachStrideValue(Object value) {
    return '${value}x stride reach';
  }

  @override
  String get runningCoachInsightPostureTitle => 'Posture';

  @override
  String get runningCoachPostureGoodSummary =>
      'Your trunk line leans forward a little and stays tall.';

  @override
  String get runningCoachPostureGoodCue =>
      'Keep your chest tall and the shoulder-to-hip line slightly forward.';

  @override
  String get runningCoachPostureGoodDrill => 'Drill: Do two 15 m wall marches.';

  @override
  String get runningCoachInRangeWatchSummary =>
      'This value is inside the broad guide range, but not close enough to the target center to call it good.';

  @override
  String get runningCoachInRangeWatchCue =>
      'Keep the rhythm relaxed and compare two or three similar clips before making a large form change.';

  @override
  String get runningCoachInRangeWatchDrill =>
      'Drill: Run two relaxed 20 m repeats, then remeasure.';

  @override
  String get runningCoachPostureUprightSummary =>
      'Your trunk line is too upright. It can slow the next step.';

  @override
  String get runningCoachPostureUprightCue =>
      'Bring the shoulder-to-hip line slightly forward while keeping your chest tall.';

  @override
  String get runningCoachPostureUprightDrill =>
      'Drill: Do two 15 m falling starts.';

  @override
  String get runningCoachPostureLeanSummary =>
      'Your trunk line is leaning too far forward. Your steps may feel rushed.';

  @override
  String get runningCoachPostureLeanCue =>
      'Stand a little taller. Keep the hips under your chest.';

  @override
  String get runningCoachPostureLeanDrill =>
      'Drill: Do two 20 m tall runs with quick light steps.';

  @override
  String get runningCoachInsightBounceTitle => 'Bounce';

  @override
  String get runningCoachBounceGoodSummary =>
      'You stay low and move forward well.';

  @override
  String get runningCoachBounceGoodCue =>
      'Keep pushing the ground back. Do not jump upward.';

  @override
  String get runningCoachBounceGoodDrill =>
      'Drill: Do two 20 m ankle-bounce runs.';

  @override
  String get runningCoachBounceHighSummary =>
      'You are moving up and down too much.';

  @override
  String get runningCoachBounceHighCue =>
      'Keep steps quick. Push the ground back, not down.';

  @override
  String get runningCoachBounceHighDrill =>
      'Drill: Do three 20 m quick-contact runs.';

  @override
  String get runningCoachInsightFootStrikeTitle => 'Foot strike';

  @override
  String get runningCoachFootStrikeGoodSummary =>
      'Your foot lands close under your hips.';

  @override
  String get runningCoachFootStrikeGoodCue =>
      'Keep putting the foot down under you.';

  @override
  String get runningCoachFootStrikeGoodDrill =>
      'Drill: Do two 20 m quick-step runs.';

  @override
  String get runningCoachFootStrikeOverSummary =>
      'Your foot lands too far in front.';

  @override
  String get runningCoachFootStrikeOverCue =>
      'Put the foot down closer under the hips.';

  @override
  String get runningCoachFootStrikeOverDrill =>
      'Drill: Do two 20 m A-marches, then two 20 m quick-step runs.';

  @override
  String get runningCoachInsightKneeTitle => 'Knee flexion';

  @override
  String get runningCoachKneeGoodSummary =>
      'Your landing knee bends enough to stay light.';

  @override
  String get runningCoachKneeGoodCue =>
      'Keep the knee soft when the foot lands.';

  @override
  String get runningCoachKneeGoodDrill =>
      'Drill: Do two 20 m pogo runs, then two 20 m quick-contact runs.';

  @override
  String get runningCoachKneeStraightSummary =>
      'Your landing knee is too straight. The step may feel heavy.';

  @override
  String get runningCoachKneeStraightCue =>
      'Bend the knee a little as the foot lands.';

  @override
  String get runningCoachKneeStraightDrill =>
      'Drill: Do two 20 m quick-contact runs with soft knees.';

  @override
  String get runningCoachKneeCollapseSummary =>
      'Your knee bends too much after landing.';

  @override
  String get runningCoachKneeCollapseCue =>
      'Keep the knee soft, but do not sink down.';

  @override
  String get runningCoachKneeCollapseDrill =>
      'Drill: Do two 15 m single-leg pogo hops each side.';

  @override
  String get runningCoachInsightArmTitle => 'Arm carriage';

  @override
  String get runningCoachArmGoodSummary =>
      'Your arms stay bent and help your rhythm.';

  @override
  String get runningCoachArmGoodCue => 'Keep hands moving front to back.';

  @override
  String get runningCoachArmGoodDrill =>
      'Drill: Do two 20 second wall arm switches.';

  @override
  String get runningCoachArmOpenSummary =>
      'Your arms open too much. The rhythm can get loose.';

  @override
  String get runningCoachArmOpenCue =>
      'Keep elbows more bent. Drive the hands back.';

  @override
  String get runningCoachArmOpenDrill =>
      'Drill: Do two 20 second wall arm switches with bent elbows.';

  @override
  String get runningCoachArmTightSummary =>
      'Your arms are too tight. The swing may feel short.';

  @override
  String get runningCoachArmTightCue =>
      'Relax the shoulders. Let the hands swing back.';

  @override
  String get runningCoachArmTightDrill =>
      'Drill: Do two 20 m arm-swing marches with relaxed shoulders.';

  @override
  String get runningCoachInsightStrideTitle => 'Stride reach';

  @override
  String get runningCoachStrideGoodSummary =>
      'Your front foot stays close to a useful landing window under the body.';

  @override
  String get runningCoachStrideGoodCue =>
      'Keep the same timing and let the stride open from force, not from reaching.';

  @override
  String get runningCoachStrideGoodDrill =>
      'Drill: 2 x 20m wicket-style quick step runs to keep the same rhythm.';

  @override
  String get runningCoachStrideShortSummary =>
      'Your stride reach looks short, so you may be holding back and not opening the run enough.';

  @override
  String get runningCoachStrideShortCue =>
      'Drive the knee forward and let the step open naturally behind a faster arm rhythm.';

  @override
  String get runningCoachStrideShortDrill =>
      'Drill: 2 x 20m A-march into A-skip to build front-side mechanics.';

  @override
  String get runningCoachStrideOverSummary =>
      'The front foot is reaching too far ahead of the body, which can create braking.';

  @override
  String get runningCoachStrideOverCue =>
      'Land closer under the hips and let speed come from push-off, not reaching.';

  @override
  String get runningCoachStrideOverDrill =>
      'Drill: 2 x 20m A-march and 2 x 20m wicket-style runs with short contacts.';

  @override
  String get homeWeatherNeedsLocationTitle => 'Need location';

  @override
  String get homeWeatherNeedsLocationSubtitle => 'Turn location on';

  @override
  String get homeStreakBadgeActive => 'Momentum';

  @override
  String get homeStreakBadgeResume => 'Restart';

  @override
  String homeStreakActiveTodayTitle(int count) {
    return '$count straight days';
  }

  @override
  String homeStreakActiveYesterdayTitle(int count) {
    return '$count days through yesterday';
  }

  @override
  String homeStreakPausedTitle(int count) {
    return '$count-day streak paused';
  }

  @override
  String get homeStreakActiveTodayBody =>
      'Today\'s session is already in. One more short log tomorrow keeps the rhythm building.';

  @override
  String get homeStreakActiveYesterdayBody =>
      'Add one more session today and the recent rhythm carries straight forward.';

  @override
  String homeStreakPausedBody(int gap) {
    return 'You have been away for $gap days. Restart with a short session and the rhythm comes back quickly.';
  }

  @override
  String homeStreakLastLogged(Object date) {
    return 'Last log $date';
  }

  @override
  String homeStreakDaysValue(int count) {
    return '$count days';
  }

  @override
  String get homeStreakActionContinue => 'Log today';

  @override
  String get homeStreakActionReview => 'Week';

  @override
  String get educationScreenTitle => 'The World Cup Story Dad Tells Taeo';

  @override
  String get educationStoryIntroBody =>
      'Taeo, tonight I do not want you to flip through the World Cup like a workbook. I want you to read it like one long story. It lasts much longer when you remember not only the names of the champions, but also the smell, the noise, and the expressions each tournament left behind. I want you to grow into the kind of player who looks at the faces and the air of an era as carefully as the scoreline.\n\nThat is why this screen no longer chops the story into little pages. You can read it in one long stretch now. Instead of turning chapters with your thumb, just keep moving slowly through the years. I want Uruguay 1930 and the still-unopened page of North America 2026 to feel connected in one line.';

  @override
  String get educationStoryOriginsTitle =>
      '1930-1938, the first World Cup arrived by ship';

  @override
  String get educationStoryOriginsBody =>
      'Taeo, the first World Cup began in an age when ships mattered more than planes. European teams spent weeks crossing the sea to reach Uruguay, and the hosts hurried the Estadio Centenario to completion inside the heat of a centenary celebration. By modern standards the whole thing looks inconvenient, but that very slowness is why the first tournament still feels so sharp. The World Cup was teaching us from the start that big occasions often arrive carrying a little discomfort.\n\nAnd when the story moves into Italy 1934 and France 1938, I do not want you to look only at the result sheet. Look at Mussolini\'s shadow, the long travel, the resentment around participation, and the refereeing arguments too. The World Cup was never only football. Travel technology, politics, and the emotions between nations were already sticking to the grass.\n\nSo when you remember 1930, 1934, and 1938, do not keep only three numbers. Keep the smell of salt, the tone of speeches, and the sound of uneasy applause with them. History stops feeling like an exam answer when you remember it as a real scene.';

  @override
  String get educationStoryReturnTitle =>
      '1950-1970, when silence and a smile stayed in the same tournament';

  @override
  String get educationStoryReturnBody =>
      'After the years emptied out by war, the World Cup returned in Brazil in 1950, and people probably expected celebration first. But Taeo, whenever I talk about that tournament, I start with the silence of the Maracana. Uruguay beating Brazil showed that one result can change the volume of an entire country.\n\nThen the story runs quickly through the Miracle of Bern in 1954, seventeen-year-old Pele in 1958, Garrincha in 1962, England in 1966, and the golden Brazil of 1970. By then the World Cup had become more than a tournament. It had turned into a machine for making collective memory. Someone falls, someone appears, and someone becomes so complete that he starts to look like legend.\n\nWhen you read this stretch, I want you to keep five words beside it: restart, shock, birth, revenge, and completion. Those words fold a long era into your hand without shrinking any of its feeling.';

  @override
  String get educationStoryMiddleTitle =>
      '1974-2006, beauty and argument have to be remembered together';

  @override
  String get educationStoryMiddleBody =>
      'By 1974 the texture of the air changes again. The trophy changes, the Netherlands shake the coordinates of the pitch with total football, and West Germany turn that beautiful chaos into a result. Taeo, every time I read this era I am reminded that football is one of the few places where idealism and reality collide in full public view. Grace is easy to love, but trophies usually lean toward something heavier.\n\nBut this period never fits inside tactics alone. Argentina 1978 carries the chill of military rule. Battiston\'s fall in 1982 stays in the mind far too long. Maradona in 1986 feels almost like weather. Then Roger Milla\'s dance in 1990, Korea\'s semi-final run in 2002, and Zidane\'s headbutt in 2006 show how the World Cup can spill out of the television and change the atmosphere inside a home.\n\nAnd 2002 is not somebody else\'s timeline for us. It includes the shouting in the streets, the late-night surge, and the air that refused to settle after the whistle. So when you read this era, do not remember only who scored. Remember what kind of night it was.';

  @override
  String get educationStoryRecentTitle =>
      '2010-2022, the more numbers arrived, the sharper the scenes became';

  @override
  String get educationStoryRecentBody =>
      'Open South Africa 2010 and you hear the vuvuzelas first. Open Brazil 2014 and the 7-1 scoreboard appears before anything else. In Russia 2018 there is the silence in front of the VAR monitor, and in Qatar 2022 Messi and Mbappe hold both a passing of generations and a collision of generations inside one final. Taeo, it sounds as if more data and more technology should blur the story, but the World Cup somehow moved in the opposite direction. The more numbers arrived, the more strongly the scenes stayed inside the body.\n\nKlose\'s sixteenth goal, Morocco reaching the semi-finals, and Suarez\'s handball on the line can all be listed in a record book. But what people hold onto for years is still the human expression of the moment. That is what I most want to tell you. Tables organize. Scenes make you understand.\n\nSo when you watch the recent World Cups, do not stop at the scoreline and the data. Ask why people were shocked, why they kept talking, and why the image lingered. That is how your football map grows wider.';

  @override
  String get educationStoryPeopleTitle =>
      'You need the people, the politics, and the technology too';

  @override
  String get educationStoryPeopleBody =>
      'Taeo, the World Cup can never be explained by a champions table alone. You need the faces that pulled whole eras forward: Jules Rimet, Pozzo, Pele, Beckenbauer, Maradona, Ronaldo, Messi. You also need moments such as the cancelled tournaments of 1942 and 1946, when war was strong enough to stop even football\'s grandest calendar. Only then do you see how quickly the World Cup began to resemble the wider world.\n\nThe dog Pickles recovering the Jules Rimet Trophy in 1966, the Schumacher-Battiston collision in 1982, Lampard\'s disallowed goal in 2010, goal-line technology in 2014, VAR in 2018, and semi-automated offside in 2022 all belong on the same line. Football always wants to become fairer, while also revealing that perfect fairness never fully arrives.\n\nSo keep writing two questions beside every tournament. Who won. And what changed. Once you start holding those two lines together, history becomes less stiff and more accurate at the same time.';

  @override
  String get educationStoryFutureTitle =>
      'Beyond 2026, how to read a page that has not opened yet';

  @override
  String get educationStoryFutureBody =>
      'Now look toward North America 2026. A field of 48 teams, 104 matches, and three host nations already gives it a different face from older tournaments. Taeo, when I see those numbers, I think before anything else about travel distance, recovery time, bench strength, and the ability to decode unfamiliar opponents quickly. The longer a tournament becomes, the more it depends on a whole structure of endurance rather than one star.\n\nSo reading the future is not the same as guessing one winner like a fortune teller. It is practice in seeing which team can survive the minutes when set-pieces begin to tilt a match, which side can keep its rhythm over a long road, and which squad can hold real competitive level from players eighteen through twenty-three. The longer you read World Cup history, the sooner those conditions begin to stand out.\n\nI want you to read 2026 the same way you read the past. Do not write down only the team name. Write down the pressing, the transitions, the set-pieces, and the defensive line stability beside it. Then you will understand that good prediction grows out of good memory.';

  @override
  String get educationStoryClosingBody =>
      'In the end, Taeo, watching the World Cup well is not about memorizing one final score. It is about following the long thread from the first voyage in 1930 to the next question waiting in 2026. Every time you read that story, I hope you learn to see people more clearly than numbers, the air more clearly than the result, and an era more clearly than a single match.';

  @override
  String get educationHeroEyebrow => 'YOUTH SESSION KIT';

  @override
  String get educationHeroTitle =>
      'Youth football content you can coach right away';

  @override
  String get educationHeroBody =>
      'Keep the explanations short, the repetitions high, and finish with one question. These three sessions are built for that flow.';

  @override
  String get educationHeroStatLessons => '3 ready lessons';

  @override
  String get educationHeroStatMinutes => '45-minute flow';

  @override
  String get educationHeroStatPrinciples => 'Coach cues included';

  @override
  String get educationHeroStatHistory => 'Quiz history included';

  @override
  String get educationSectionLessonsTitle => 'Ready Lessons';

  @override
  String get educationSectionHistoryTitle => 'Quiz History Study';

  @override
  String get educationSectionHistoryBody =>
      'These cards group together the years, competition names, and iconic moments that appear often in the quiz. Review one card, then jump straight into a round while the timeline is still fresh.';

  @override
  String get educationSectionPrinciplesTitle => 'Coaching Principles';

  @override
  String get educationHistoryWorldCupEyebrow => 'WORLD CUP ROOTS';

  @override
  String get educationHistoryWorldCupTitle => 'World Cup Foundations';

  @override
  String get educationHistoryWorldCupSummary =>
      'Use one card to lock in the first tournament, trophy change, and headline records that frame many World Cup history questions.';

  @override
  String get educationHistoryWorldCupFocus => 'Year + host';

  @override
  String get educationHistoryWorldCupFact1 =>
      'The first FIFA World Cup was held in Uruguay in 1930.';

  @override
  String get educationHistoryWorldCupFact2 =>
      'The Jules Rimet Trophy was used through 1970, and the current FIFA World Cup Trophy has been used since 1974.';

  @override
  String get educationHistoryWorldCupFact3 =>
      'Brazil is the most common answer for the most men’s World Cup titles, and Miroslav Klose is the landmark all-time scorer.';

  @override
  String get educationHistoryCompetitionEyebrow => 'COMPETITION TIMELINE';

  @override
  String get educationHistoryCompetitionTitle =>
      'Competition Names And Launches';

  @override
  String get educationHistoryCompetitionSummary =>
      'League and European competition questions get easier when you pair launch years with inaugural champions or rebrand seasons.';

  @override
  String get educationHistoryCompetitionFocus => 'Launch + first champion';

  @override
  String get educationHistoryCompetitionFact1 =>
      'The Premier League launched in 1992, and Manchester United won the inaugural 1992-93 title.';

  @override
  String get educationHistoryCompetitionFact2 =>
      'The European Cup began operating as the UEFA Champions League from the 1992-93 season.';

  @override
  String get educationHistoryCompetitionFact3 =>
      'Arsenal’s 2003-04 Invincibles season is one of the most common Premier League history anchors.';

  @override
  String get educationHistoryMomentsEyebrow => 'ICONIC MOMENTS';

  @override
  String get educationHistoryMomentsTitle =>
      'Iconic Moments And Women’s Football';

  @override
  String get educationHistoryMomentsSummary =>
      'Pair famous scenes with both the year and the opponent, and keep women’s football on its own timeline for faster recall.';

  @override
  String get educationHistoryMomentsFocus => 'Moment + opponent';

  @override
  String get educationHistoryMomentsFact1 =>
      'Maradona’s “Hand of God” happened against England at the 1986 World Cup.';

  @override
  String get educationHistoryMomentsFact2 =>
      'Zidane’s headbutt is an iconic scene from the 2006 FIFA World Cup final.';

  @override
  String get educationHistoryMomentsFact3 =>
      'The first FIFA Women’s World Cup was held in China in 1991.';

  @override
  String get educationModuleBallEyebrow => 'BALL MASTERY';

  @override
  String get educationModuleBallTitle => 'Increase Touch Count';

  @override
  String get educationModuleBallSummary =>
      'A session that keeps both-foot inside and outside touches plus turns connected so younger players get comfortable with the ball.';

  @override
  String get educationModuleBallAge => 'U8-U10';

  @override
  String get educationModuleBallDuration => '12 min';

  @override
  String get educationModuleBallCue1 =>
      'Let the eyes come up sometimes while the feet stay light and active.';

  @override
  String get educationModuleBallCue2 =>
      'Before asking for speed, check that the ball stays close to the body.';

  @override
  String get educationModuleBallCue3 =>
      'After mistakes, encourage the next touch instead of stopping the drill.';

  @override
  String get educationModulePassEyebrow => 'FIRST TOUCH & PASS';

  @override
  String get educationModulePassTitle => 'First Touch Into Pass';

  @override
  String get educationModulePassSummary =>
      'Receive, turn, and release. This session links touch direction with passing accuracy in one flow.';

  @override
  String get educationModulePassAge => 'U10-U12';

  @override
  String get educationModulePassDuration => '15 min';

  @override
  String get educationModulePassCue1 =>
      'Ask players to scan over the shoulder once before receiving.';

  @override
  String get educationModulePassCue2 =>
      'Coach the first touch into the space where the next pass should go.';

  @override
  String get educationModulePassCue3 =>
      'Set the body shape and contact surface before asking for stronger pace.';

  @override
  String get educationModuleDecisionEyebrow => '1V1 DECISION';

  @override
  String get educationModuleDecisionTitle => '1v1 Breakthrough And Choice';

  @override
  String get educationModuleDecisionSummary =>
      'A decision session built around changing speed, freezing the defender, then finishing with either a shot or a pass.';

  @override
  String get educationModuleDecisionAge => 'U11-U13';

  @override
  String get educationModuleDecisionDuration => '18 min';

  @override
  String get educationModuleDecisionCue1 =>
      'Make the first step big, then keep the direction change short and sharp.';

  @override
  String get educationModuleDecisionCue2 =>
      'Praise the timing and preparation first, not only the final result.';

  @override
  String get educationModuleDecisionCue3 =>
      'After a success, revisit why it worked in one short sentence.';

  @override
  String get educationPrincipleOneTitle => 'One cue at a time';

  @override
  String get educationPrincipleOneBody =>
      'Keep instructions short and actionable. Single-word cues such as \"open\", \"scan\", and \"connect\" work well.';

  @override
  String get educationPrincipleTwoTitle => 'Find praise right after mistakes';

  @override
  String get educationPrincipleTwoBody =>
      'If you praise the preparation instead of only the outcome, players keep trying instead of freezing.';

  @override
  String get educationPrincipleThreeTitle =>
      'Use the last two minutes for questions';

  @override
  String get educationPrincipleThreeBody =>
      'Ask what felt easy today and what they want to change next time. That reflection helps the lesson stick.';

  @override
  String get educationBookSectionStory => 'Taeo\'s Scene';

  @override
  String get educationBookSectionTimeline => 'Core Timeline';

  @override
  String get educationBookSectionFacts => 'Memory Data';

  @override
  String get educationBookSectionNote => 'Taeo\'s Note';

  @override
  String get educationBookSwipeHint =>
      'Pages turn only with a side swipe. Read each chapter by slowly scrolling downward.';

  @override
  String get educationBookPreviousButton => 'Previous';

  @override
  String get educationBookNextButton => 'Next';

  @override
  String educationBookProgressLabel(int current, int total) {
    return '$current/$total chapters';
  }

  @override
  String get educationBookCoverLabel => 'Prologue';

  @override
  String get educationBookCoverTitle =>
      'Taking the World Cup Down From a Shelf at Night';

  @override
  String get educationBookCoverSubtitle =>
      'How Taeo opens the first page of a history book';

  @override
  String get educationBookCoverStory =>
      'On some nights after training, paper feels heavier than the ball. Taeo runs a cooling hand along a shelf of old World Cup programmes. The pages smell faintly of dust, and inside them lie the port of Montevideo, the steps of the Maracana, the sunlight over the Azteca, and the polished night above Lusail. It feels as if someone folded whole seasons into paper and left them here for later.\n\nThis book does not try to explain all of football. It follows only one river: the World Cup. It begins in Uruguay in 1930, passes through Qatar in 2022, and pauses at the far edge of 2026 in North America, still waiting to be written. Taeo likes that restraint. Sometimes looking at one thing for a long time is more exact than trying to hold everything at once.\n\nSo he writes down 1930, 1950, 1958, 1970, 1986, 1998, 2002, 2010, 2018, 2022, and 2026 on a blank page. Years look like numbers, but if you stare at them long enough, they begin to feel like rooms with different temperatures. One room holds Pele\'s smile. One holds the silence of the Maracana. Another keeps the moment Messi finally lets himself exhale. Tonight Taeo decides to touch each doorknob in turn.';

  @override
  String get educationBookCoverTimeline =>
      'FIFA was founded in 1904, building the administrative frame that later made the World Cup possible.\nThe first men\'s FIFA World Cup was held in Uruguay in 1930.\nThe 1942 and 1946 editions were cancelled because of World War II.\nFrom 1974 onward, the current FIFA World Cup Trophy replaced the Jules Rimet Trophy.\nFrance 1998 expanded the finals to a 32-team format.\nRussia 2018 was the first men\'s World Cup with full VAR implementation.\nCanada, Mexico, and the United States are due to stage a 48-team, 104-match tournament in 2026.';

  @override
  String get educationBookCoverFacts =>
      'Taeo\'s bookmark 1: through Qatar 2022, the men\'s World Cup has been completed 22 times.\nTaeo\'s bookmark 2: Brazil with 5 titles, Germany with 4, Italy with 4, and Argentina with 3 are the main title anchors.\nTaeo\'s bookmark 3: Miroslav Klose\'s 16 goals remain the all-time men\'s World Cup scoring record.\nTaeo\'s bookmark 4: World Cup history sticks best when year, host, champion, iconic scene, and leading figure are grouped together.';

  @override
  String get educationBookCoverNote =>
      'Taeo writes that this book is not just a list of winners. It is a chronicle of what kind of face the world showed every four years. That is why he chooses to remember the latest completed tournament in 2022 and the next door opening in 2026 side by side.';

  @override
  String get educationBookOriginsLabel => 'Chapter 1';

  @override
  String get educationBookOriginsTitle => 'The First Summer Arrived By Ship';

  @override
  String get educationBookOriginsSubtitle =>
      'Uruguay 1930, Italy 1934, and France 1938';

  @override
  String get educationBookOriginsStory =>
      'The first chapter begins in an age when ships mattered more than planes. European teams spent weeks crossing the sea to reach Uruguay, and the hosts finished the Estadio Centenario in a rush thick with the heat of a centenary celebration. By modern standards everything was slow and inconvenient, yet that slowness makes the tournament seem sharper. Big events often arrive carrying a little discomfort with them. The World Cup knew that from the start.\n\nAs Uruguay become the first champions in 1930 and Italy follow with titles in 1934 and 1938, Taeo finds himself reading the air around the results before the scorelines themselves. Mussolini\'s shadow stretches over one tournament. War has not yet begun, but it is already walking quietly through the corridors of Europe. The World Cup starts resembling the world much earlier than he expected. Travel, politics, boycotts, and refereeing arguments all enter the same cover.\n\nReading this period, Taeo learns that the World Cup was never innocent in its earliest form. The sea delayed the teams, but it also made the tournament look like legend. Things that take a long time to arrive are rarely forgotten. So he decides to remember 1930, 1934, and 1938 not only as numbers, but as the smell of salt, the tone of speeches, and the sound of uneasy applause.';

  @override
  String get educationBookOriginsTimeline =>
      'Uruguay 1930 featured only 13 teams, but the hosts became the first champions and set the tone of the tournament.\nThe 1930 final ended as a South American duel, with Uruguay beating Argentina 4-2.\nItaly 1934 was the first World Cup to apply a fully developed qualification path before the finals.\nUruguay skipped the 1934 tournament in protest after many European teams had stayed away from 1930.\nUnder coach Vittorio Pozzo, Italy won back-to-back titles in 1934 and 1938.\nAt France 1938, the Dutch East Indies became the first Asian team to appear in the men\'s World Cup finals.';

  @override
  String get educationBookOriginsFacts =>
      'Jules Rimet was the central administrator who pushed the tournament into existence and later gave his name to the original trophy.\nVittorio Pozzo is still the only coach to win back-to-back men\'s World Cups.\nThe long travel distance between Europe and South America shaped participation more heavily than modern fans often expect.\nTaeo files away 1930, 1934, and 1938 as the first tournament, the first full qualifying era, and the first back-to-back title run.';

  @override
  String get educationBookOriginsNote =>
      'Taeo keeps 1930, 1934, and 1938 as one cluster. The first tournament, the first qualification era, and the first repeat champions all arrived together. From the very beginning, the World Cup was already more than football.';

  @override
  String get educationBookWorldCupLabel => 'Chapter 2';

  @override
  String get educationBookWorldCupTitle =>
      'How Silence and Celebration Stay in the Same Stadium';

  @override
  String get educationBookWorldCupSubtitle => 'From Brazil 1950 to Mexico 1970';

  @override
  String get educationBookWorldCupStory =>
      'When the World Cup returned in Brazil in 1950 after two empty summers lost to war, people probably expected celebration first. But the first scene Taeo meets is silence. Uruguay\'s win over Brazil in the decisive match at the Maracana shows him that one result can alter the volume of an entire country. From that point on, the World Cup looks less like a sports event than a machine for making collective memory.\n\nThe pages that follow turn into legend with surprising speed. The Miracle of Bern in 1954. Seventeen-year-old Pele arriving in 1958. Brazil carried by Garrincha in 1962. England\'s one and only title in 1966. The golden Brazil of 1970 in Mexico. The more Taeo reads, the clearer it becomes that history books borrow faces and movement in order to stay alive. Someone falls. Someone appears. Someone becomes so complete that he starts to look invented.\n\nSo Taeo folds 1950 through 1970 into five words: restart, shock, birth, revenge, completion. On paper that feels small enough to fit in one hand. But the feelings inside those words do not shrink with them. The silence of the Maracana and the smile of Pele remain, each in a different direction, for a very long time.';

  @override
  String get educationBookWorldCupTimeline =>
      'Brazil 1950 used a final group instead of a one-match final, and Uruguay\'s win over Brazil became the Maracana shock.\nWest Germany beat mighty Hungary in 1954 to create the Miracle of Bern.\nAt Sweden 1958, 17-year-old Pele rose as the game\'s brightest new star.\nBrazil retained the trophy in Chile 1962 with Garrincha carrying the side through key matches.\nEngland won their only men\'s World Cup in 1966, with Geoff Hurst scoring a famous hat-trick in the final.\nBrazil\'s third title in Mexico 1970 gave them permanent ownership of the Jules Rimet Trophy.\nCarlos Alberto\'s goal in the 1970 final is still replayed as the symbol of collective team football.';

  @override
  String get educationBookWorldCupFacts =>
      'Hungary arrived at the 1954 final as the team many saw as the strongest in the world.\nJairzinho scored in every match Brazil played during their 1970 title run.\nGordon Banks\' save from Pele\'s header is still labeled by many as the save of the century.\nTaeo groups together the Maracana shock of 1950, the emergence of Pele in 1958, and Brazil\'s masterpiece in 1970.';

  @override
  String get educationBookWorldCupNote =>
      'Taeo writes that the World Cup from 1950 to 1970 was both a return ceremony after war and the biggest stage in the world for introducing a new genius.';

  @override
  String get educationBookClubLabel => 'Chapter 3';

  @override
  String get educationBookClubTitle =>
      'An Era Where Beauty and Discomfort Grow Together';

  @override
  String get educationBookClubSubtitle =>
      'From West Germany 1974 to Italy 1990';

  @override
  String get educationBookClubStory =>
      'By 1974, the air inside the book changes. The trophy changes too. The Netherlands shake the coordinates of the pitch with total football, and West Germany finally arranges that beautiful chaos into a result. Whenever Taeo reads this chapter, he thinks football is one of the few places where idealism and reality collide in full public view. Grace is easy to love, but the trophy usually leans toward something heavier.\n\nYet this era cannot be explained by tactics alone. Argentina 1978 carries the chill of military rule. In 1982, Battiston\'s fall tears open the time of the match itself. Maradona in 1986 appears less like a player than a weather system. The Hand of God and the goal past five men happen in the same summer, and the contradiction only makes the face of the World Cup clearer.\n\nBy the time Taeo reaches 1990, he understands that an era does not always end in a tidy sentence. Roger Milla\'s dancing, Beckenbauer\'s title as a coach, and Maradona\'s tears remain at different temperatures. History lasts longer when it is slightly mixed rather than perfectly arranged. So he binds this stretch together only loosely, with four words: beauty, discomfort, talent, and argument.';

  @override
  String get educationBookClubTimeline =>
      'West Germany 1974 was the first tournament to award the current FIFA World Cup Trophy.\nCruyff\'s turn and the Netherlands\' total football left images that outlived even the final result.\nArgentina won their first title in 1978, but the tournament remains tied to the political climate of the junta.\nSpain 1982 was the first men\'s World Cup with 24 teams.\nFrance against West Germany in the 1982 semifinal was the first World Cup match decided by a penalty shootout and is also remembered for the Schumacher-Battiston collision.\nMaradona\'s 1986 performance against England gave football both the Hand of God and the Goal of the Century.\nCameroon reached the quarter-finals in 1990, becoming the first African team to go that far in the men\'s World Cup.';

  @override
  String get educationBookClubFacts =>
      'Franz Beckenbauer stands as a defining symbol because he won the World Cup as a player in 1974 and as a coach in 1990.\nPaolo Rossi returned from suspension in time to become the face of Italy\'s 1982 title.\nItaly 1990 is often cited as a tournament whose defensive trend helped push later rule discussions.\nTaeo groups 1974, 1978, 1982, 1986, and 1990 as World Cup years that left both beauty and discomfort behind.';

  @override
  String get educationBookClubNote =>
      'Taeo writes that this period proves the World Cup does not leave behind only clean, beautiful stories. That is also why it lasts. History has to remember what made people uncomfortable as well as what made them cheer.';

  @override
  String get educationBookTacticsLabel => 'Chapter 4';

  @override
  String get educationBookTacticsTitle =>
      'When the World Cup Walked From Television Into the Living Room';

  @override
  String get educationBookTacticsSubtitle =>
      'USA 1994, France 1998, Korea and Japan 2002, Germany 2006';

  @override
  String get educationBookTacticsStory =>
      'By USA 1994, Taeo sees the tournament acquiring a completely different size. Giant stadiums, the brightness of the advertising boards, the heat spreading through television screens, and Baggio\'s kick rising into the sky all settle into the same memory. The World Cup no longer feels like a distant celebration in another country. It feels like a huge piece of furniture suddenly placed in the middle of the living room. No one passes it without noticing.\n\nAs he moves through Zidane\'s France in 1998, Korea\'s semi-final run and Ronaldo\'s redemption in 2002, and Zidane\'s headbutt in the 2006 final, Taeo starts to feel that these tournaments are unusually friendly to replay. Strong scenes are easy to repeat, and repeated scenes become shared memory for a generation. For him, 2002 is not someone else\'s history at all. It comes with the shouting in nearby streets, the empty cans under the television, and the night air that took a long time to settle after the final whistle.\n\nSeen that way, the World Cup is always slightly wider than the scoreline. Some tournaments are remembered less for who scored than for what kind of night they became. When Taeo thinks of 1994, 1998, 2002, and 2006, he remembers faces, noise, and camera angles before he remembers the numbers. Maybe that is how modern history books are written now.';

  @override
  String get educationBookTacticsTimeline =>
      'The 1994 final was the first men\'s World Cup final decided by a penalty shootout.\nRoberto Baggio\'s miss in 1994 became one of the best-known images in World Cup history.\nFrance 1998 marked the beginning of the 32-team finals format.\nLaurent Blanc scored the first golden goal in World Cup history at France 1998.\nKorea and Japan 2002 became the first co-hosts of a men\'s World Cup, and South Korea reached the semi-finals.\nRonaldo scored eight times in 2002 and turned the pain of the 1998 final into a story of redemption.\nGermany 2006 ended with Zidane\'s red card in the final and Italy taking the title.';

  @override
  String get educationBookTacticsFacts =>
      'Names such as Hiddink, Scolari, and Lippi are attached to the memory of this era as strongly as the players are.\nCroatia\'s Davor Suker won the Golden Boot in 1998 while his team surged to third place.\nSenegal\'s run to the quarter-finals and Turkey\'s run to the semi-finals in 2002 showed again that the World Cup is never moved only by the giants.\nTaeo writes that 1994, 1998, 2002, and 2006 have to be remembered through their final scenes to stay alive.';

  @override
  String get educationBookTacticsNote =>
      'Taeo lingers especially long over the 2002 chapter. For Korean fans, World Cup history is not a distant timeline. It is a memory line that touches home directly. That is why he decides to remember not only the result sheet, but the atmosphere and the sound around it too.';

  @override
  String get educationBookLegendsLabel => 'Chapter 5';

  @override
  String get educationBookLegendsTitle =>
      'The More Numbers There Were, the Sharper the Scenes Became';

  @override
  String get educationBookLegendsSubtitle =>
      'From South Africa 2010 to Qatar 2022';

  @override
  String get educationBookLegendsStory =>
      'When Taeo opens South Africa 2010, he hears the vuvuzelas first. Some tournaments are remembered through the ears before the eyes. Spain\'s title, Suarez\'s handball on the line, Ghana\'s exit, and the strange fame of Paul the Octopus show him that different kinds of seriousness can live inside the same month. The World Cup remains a history book, but it is also a storage room for rumor, jokes, and collective obsession.\n\nBy the time he reaches Brazil\'s 7-1 collapse in 2014, the full arrival of VAR in 2018, and the final in Qatar in 2022, Taeo starts to feel that more numbers do not blur the story. They sharpen the scenes instead. Klose\'s sixteenth goal, Mbappe\'s acceleration, the final missing piece in Messi\'s career, and Morocco\'s run to the semi-finals all push history from different angles. Data helps explain things, but what remains in the body is never data alone.\n\nWhenever Taeo reads the recent World Cups, he returns to the same conclusion. People remember scenes longer than tables. The 7-1 scoreboard. The silence in front of the VAR monitor. The brief moment when Messi lowers his head after extra time. Records are filed away on shelves. Scenes stick to the inside of the body.';

  @override
  String get educationBookLegendsTimeline =>
      'South Africa 2010 was the first men\'s World Cup held on the African continent.\nSpain won their first World Cup in 2010 thanks to Iniesta\'s extra-time goal in the final.\nSuarez\'s handball against Ghana in 2010 became one of the hottest argument scenes in World Cup memory.\nGermany beat Brazil 7-1 in the 2014 semi-final and then went on to win the title.\nKlose\'s goal against Brazil in 2014 set the men\'s World Cup all-time scoring record at 16.\nRussia 2018 was the first men\'s World Cup with full VAR use throughout the tournament.\nAt Qatar 2022, Morocco reached the semi-finals and Argentina won with Messi at the center.';

  @override
  String get educationBookLegendsFacts =>
      'Paul the Octopus became a prediction icon in 2010 by repeatedly getting match outcomes right.\nKylian Mbappe\'s 2018 title and 2022 final hat-trick built the strongest young World Cup narrative since Pele.\nLionel Messi used 2022 to fill the final empty space in his World Cup career.\nTaeo remembers 2010, 2014, 2018, and 2022 through five feelings: sound, collapse, technology, youth, and completion.';

  @override
  String get educationBookLegendsNote =>
      'Taeo writes that even in the most data-heavy World Cups, people still remember scenes first. The vuvuzelas, the 7-1 scoreboard, the VAR check, and Messi\'s smile stay longer than any spreadsheet.';

  @override
  String get educationBookAsiaLabel => 'Chapter 6';

  @override
  String get educationBookAsiaTitle =>
      'The Moment Faces Come to Mind Before Years';

  @override
  String get educationBookAsiaSubtitle =>
      'From Jules Rimet to Pele, Maradona, Beckenbauer, and Messi';

  @override
  String get educationBookAsiaStory =>
      'At some point Taeo begins to remember the World Cup through faces before he remembers it through years. Jules Rimet, who helped make the tournament possible. Pozzo, who shaped back-to-back titles. Pele, who stood at the top three times. Beckenbauer, who passed through both the door of player and the door of coach. Maradona, who turned one summer into myth. Read one by one, these names give history a surprisingly personal expression. Even a massive tournament can end up summarized by the breathing of a few people.\n\nNone of the figures in this chapter are complete. Garrincha carries an injured team. Ronaldo turns the memory of one lost final inside out four years later. Zidane leaves behind both genius and fracture. Messi finishes his own sentence only at the end. So Taeo feels that the World Cup is not really a place that creates heroes from nothing. It is a place that enlarges the outline of people who were already shaking.\n\nHe always writes a year and a scene next to the name. Pele means 1958 and 1970. Maradona means 1986. Ronaldo means 2002. Messi means 2022. Names alone feel like exam notes. Add the scene, and suddenly they become stories. Perhaps history books survive only in that form.';

  @override
  String get educationBookAsiaTimeline =>
      'Jules Rimet gave the competition both its early political drive and the name of its first trophy.\nVittorio Pozzo coached Italy to back-to-back titles in 1934 and 1938.\nPele won the men\'s World Cup in 1958, 1962, and 1970, a record no other male player has matched.\nFranz Beckenbauer won the trophy as a player in 1974 and as a coach in 1990.\nMaradona\'s 1986 campaign is still large enough to explain a huge part of World Cup mythology by itself.\nRonaldo\'s eight goals in 2002 turned the pain of 1998 into one of football\'s cleanest redemption arcs.\nMessi and Mbappe used the 2022 final to show both a passing of generations and a collision of generations at once.';

  @override
  String get educationBookAsiaFacts =>
      'Just Fontaine\'s 13 goals remain the all-time record for one single World Cup tournament.\nMiroslav Klose\'s 16 goals remain the all-time men\'s World Cup scoring record across multiple editions.\nMario Zagallo, Franz Beckenbauer, and Didier Deschamps are among the iconic figures who won the World Cup both as players and as coaches.\nTaeo records each figure in one line by pairing name, country, defining tournament, and defining scene.';

  @override
  String get educationBookAsiaNote =>
      'Taeo decides that the fastest way to remember the World Cup is to remember it through people. Years alone feel like a test. Faces and scenes turn it into a story.';

  @override
  String get educationBookWomenLabel => 'Chapter 7';

  @override
  String get educationBookWomenTitle =>
      'How to Read the Air Outside the Stadium Too';

  @override
  String get educationBookWomenSubtitle =>
      'War, politics, theft, and the technology of judgement';

  @override
  String get educationBookWomenStory =>
      'At some point Taeo decides that a history book listing only champions is slightly rude. The World Cup has never happened only inside the stadium. Some tournaments disappeared completely because of war. Some were played beneath dictatorship. Some are remembered as much for events beyond the pitch as for the football itself. The air of the wider world always seeps onto the grass.\n\nThe theft of the Jules Rimet Trophy in 1966 and its recovery by a dog called Pickles is so strange it almost refuses to feel true. Battiston falling in 1982, Lampard\'s disallowed goal in 2010, goal-line technology in 2014, VAR in 2018, and semi-automated offside in 2022 show how long football has wrestled with human imperfection in judgement. The sport always wants to become fairer, while knowing it can never become perfectly fair.\n\nSo Taeo writes two questions next to every tournament. Who won. And what changed. Put those sentences together, and the outline of an event becomes much clearer. History does not end at the scoreboard. It has to be read together with the air behind it.';

  @override
  String get educationBookWomenTimeline =>
      'The cancellations of 1942 and 1946 showed that world war could halt even football\'s grandest calendar.\nBefore England 1966 began, the Jules Rimet Trophy was stolen and then found by a dog named Pickles.\nArgentina 1978 remains tied to the political pressure of the ruling military regime.\nThe Schumacher-Battiston collision in the 1982 semi-final expanded the argument about sportsmanship and refereeing.\nFrank Lampard\'s disallowed goal against Germany in 2010 made the case for technical review even louder.\nGoal-line technology was used at Brazil 2014.\nVAR arrived in 2018 and semi-automated offside followed in 2022, changing the look of elite refereeing again.';

  @override
  String get educationBookWomenFacts =>
      'Pickles became the most famous dog in football history after helping recover the World Cup trophy.\nTechnology does not erase World Cup controversy. It changes the kind of controversy people argue about.\nPolitics and social conditions reshape host memory, crowd emotion, and the way a tournament is remembered.\nTaeo always writes the social setting next to the scoreline when he studies historic events.';

  @override
  String get educationBookWomenNote =>
      'Taeo writes that the World Cup is not only the biggest football tournament. It is also a place where the era\'s politics, technology, and fairness arguments all gather at once. That is why he refuses to treat the off-field story as a footnote.';

  @override
  String get educationBookModernLabel => 'Chapter 8';

  @override
  String get educationBookModernTitle =>
      'Things Worth Writing Down While Waiting for the Next Tournament';

  @override
  String get educationBookModernSubtitle =>
      'Taeo\'s notes toward North America 2026';

  @override
  String get educationBookModernStory =>
      'Now the book walks slowly toward a tournament that has not yet been played. North America 2026 already wears a different expression: 48 teams, 104 matches, three host nations. When Taeo looks at those numbers, he thinks first not of favorites but of travel distance, recovery time, and the breathing of the bench. The longer a tournament becomes, the more it seems to depend on a whole way of enduring rather than on one star.\n\nThat is why this chapter feels closer to observation than prophecy. Which teams can decode unfamiliar opponents quickly. Which teams can survive the minutes when set pieces begin to tilt a match. Which teams can keep their rhythm over a long road. Taeo believes that the conditions of a strong side are usually born from dull detail rather than glamorous sentences. History, strangely enough, agrees with him more often than not.\n\nIt feels risky to speak too loudly about a tournament that has not yet arrived. The future usually comes in a drier form than expected, and predictions often miss. Even so, Taeo leaves a few pages blank. He thinks the last virtue of a history book is always the space it keeps for the next sentence.';

  @override
  String get educationBookModernTimeline =>
      'The 2026 World Cup will be the first men\'s edition jointly hosted by Canada, Mexico, and the United States.\nFrom 2026 onward, the men\'s World Cup finals expand to 48 teams.\nA 48-team format means 104 matches, giving scheduling and rotation even more strategic weight.\nLong travel routes and climate variation are likely to matter more than in many previous editions.\nSet-pieces, bench scoring, and the speed of analytical preparation should rise in value in a longer event.\nTaeo decides to treat 2026 as a search for the conditions of strength rather than only a hunt for the winner.';

  @override
  String get educationBookModernFacts =>
      'The longer a tournament becomes, the more the real competitive level of players 18 through 23 matters along with the starting eleven.\nA 48-team field also increases the chance of surprise runs from Asia, Africa, and Concacaf.\nTraditional giants still carry the greatest baseline, but the number of possible twists may grow with the format.\nWhen Taeo writes a prediction, he adds pressing, transitions, set-pieces, and defensive stability beside the team name.';

  @override
  String get educationBookModernNote =>
      'Taeo writes that prediction is not a game of lucky guesses. It is practice in reading the conditions of a strong team. That is why he writes more about why a side looks powerful than about the name itself.';

  @override
  String get educationBookFinaleLabel => 'Epilogue';

  @override
  String get educationBookFinaleTitle =>
      'The Final Page Always Closes a Little More Slowly';

  @override
  String get educationBookFinaleSubtitle =>
      'An epilogue tying 1930 and 2026 into one line';

  @override
  String get educationBookFinaleStory =>
      'By the last page, Taeo starts to think the World Cup is really a very thick magazine published once every four years. The era keeps changing, but the title on the cover stays the same, and inside it the air, faces, and arguments of that moment are compressed together. The players who sailed to Uruguay and the players running under cameras and sensors today end up resting on the same spine. That feels slightly strange, and also exactly right.\n\nSome years remain because of names such as Pele, Maradona, and Messi. Some remain because of scores like the Maracana shock or 7-1. Some remain because of war, dictatorship, or the technology of judgement. So Taeo decides that reading the World Cup is not really about memorizing football. It is closer to running a hand along the grain of time. Once you realize that an era is folded behind a single match, even the score begins to weigh more.\n\nBefore he closes the book, he reads 1930, 1950, 1958, 1970, 1986, 1998, 2002, 2010, 2018, 2022, and 2026 one more time. Now they no longer sound like cold dates. They sound like room names under different lights. Some rooms are already behind him. One is still about to open. That, Taeo thinks, is why history books matter. They let you walk slowly through the space in between.';

  @override
  String get educationBookFinaleTimeline =>
      'Taeo learned from the early World Cups how quickly the tournament moved into the center of world history.\nTaeo learned from the post-war era that one match can become a nation\'s memory.\nTaeo learned from recent tournaments that even in a data-heavy age, people still remember scenes and faces first.\nTaeo learned from the 2026 preview that reading the future begins by seeing the patterns of the past.';

  @override
  String get educationBookFinaleFacts =>
      'Review anchor 1: tie together the year, host, champion, iconic scene, and leading figure in one line.\nReview anchor 2: 1930, 1950, 1970, 1986, 1998, 2002, 2018, and 2022 are non-negotiable review years.\nReview anchor 3: connect records to signature numbers such as Pele\'s 3 titles, Brazil\'s 5 titles, and Klose\'s 16 goals.\nReview anchor 4: predictions get stronger when tactics, fitness, and squad depth are written beside the team name.';

  @override
  String get educationBookFinaleNote =>
      'As he closes the book, Taeo writes the first line of his next journal like this. To really watch the World Cup well is not to memorize only one final score, but to follow the whole long story from the first kick in 1930 to the next question waiting in 2026.';

  @override
  String get familySharing => 'Parent mode/player sharing';

  @override
  String get familySharedBackupDescription =>
      'Use Drive backups without a server. Player mode owns the source snapshot, while parent mode syncs feedback and reward names through a separate contribution file.';

  @override
  String get familyBackupIncludesMedia =>
      'Back up profile photos and training photos too when those files can be collected locally.';

  @override
  String get familyParentAutoSyncDescription =>
      'In parent or coach mode, only training feedback and reward names sync automatically. Back up and restore player records from player mode.';

  @override
  String get familyChildDriveConnectionTitle => 'Connect shared backup Drive';

  @override
  String get familyChildDriveConnectionDescription =>
      'In parent mode, connect the Google Drive account that holds the player\'s source data. Parent changes sync through a separate contribution file.';

  @override
  String get familyConnectChildDrive => 'Connect shared Drive';

  @override
  String get familyDisconnectChildDrive => 'Disconnect shared Drive';

  @override
  String get familyRoleChild => 'Player';

  @override
  String get familyRolePlayer => 'Player';

  @override
  String get familyRoleParent => 'Parent';

  @override
  String get familyRoleCoach => 'Coach';

  @override
  String get familyRoleSelectionTitle => 'Usage mode selection';

  @override
  String get familyRoleSelectionDescription =>
      'Choose whether this device is used by the player directly, by a parent, or by a coach managing multiple players.';

  @override
  String get settingsUsageModeTitle => 'Usage mode';

  @override
  String get settingsRoleAndSyncTitle => 'Usage & sync';

  @override
  String get healthConnectSectionTitle => 'Samsung Health auto import';

  @override
  String get healthConnectSectionSubtitle =>
      'Import jump rope workouts shared by Samsung Health through Health Connect into jump rope training logs.';

  @override
  String get healthConnectAutoSyncTitle => 'Auto-import jump rope';

  @override
  String get healthConnectAutoSyncSubtitle =>
      'After permission is granted, the app checks recent jump rope workouts on launch and resume, then imports them without duplicates.';

  @override
  String get healthConnectStatusUnavailable =>
      'Health Connect is unavailable on this device.';

  @override
  String get healthConnectStatusUpdateRequired =>
      'Health Connect needs to be updated.';

  @override
  String get healthConnectStatusPermissionNeeded =>
      'Allow Health Connect exercise permission first.';

  @override
  String get healthConnectStatusReady =>
      'Permission is allowed. You can sync when needed.';

  @override
  String get healthConnectStatusAutoOn => 'Auto import is on.';

  @override
  String get healthConnectSyncNow => 'Sync now';

  @override
  String get healthConnectGrantAndSync => 'Allow and sync';

  @override
  String healthConnectLastSync(Object time) {
    return 'Last sync: $time';
  }

  @override
  String healthConnectSyncImported(int count) {
    return 'Imported $count jump rope record(s).';
  }

  @override
  String get healthConnectImportNotificationChannelName =>
      'Samsung Health auto import';

  @override
  String get healthConnectImportNotificationChannelDescription =>
      'Alerts when Health Connect jump rope workouts are imported';

  @override
  String get healthConnectImportNotificationTitle =>
      'Jump rope record imported';

  @override
  String healthConnectImportNotificationBody(int count) {
    return '$count jump rope record(s) were imported into Taeo\'s Note.';
  }

  @override
  String get healthConnectSyncNoNewRecords =>
      'No new jump rope records to import.';

  @override
  String get healthConnectSyncFailed => 'Health Connect sync failed.';

  @override
  String get healthConnectDisabled => 'Jump rope auto import is off.';

  @override
  String get settingsInfoTooltip => 'Show description';

  @override
  String get settingsSupportModeLabel => 'Parent';

  @override
  String get settingsCoachRosterTitle => 'Coach roster';

  @override
  String get settingsCoachRosterDescription =>
      'Select the active player before writing feedback, reward names, or Drive backups.';

  @override
  String get settingsCoachRosterEmpty => 'No players are registered yet.';

  @override
  String get settingsCoachRosterAddPlayer => 'Add player';

  @override
  String get settingsCoachRosterEditPlayer => 'Edit player';

  @override
  String get settingsCoachRosterDeletePlayer => 'Delete player';

  @override
  String get settingsCoachRosterDeleteTitle => 'Delete player';

  @override
  String settingsCoachRosterDeleteMessage(Object player) {
    return 'Delete $player from the coach roster?';
  }

  @override
  String settingsCoachRosterDeleted(Object player) {
    return '$player was deleted.';
  }

  @override
  String settingsCoachRosterRenamed(Object player) {
    return '$player was updated.';
  }

  @override
  String get settingsCoachRosterLastPlayerRequired =>
      'Keep at least one player in coach mode.';

  @override
  String settingsCoachRosterDriveAccount(Object email) {
    return 'Drive: $email';
  }

  @override
  String get settingsCoachRosterNoDriveAccount =>
      'No Drive account saved for this player yet.';

  @override
  String get settingsCoachRosterPlayerNameLabel => 'Player name';

  @override
  String get settingsCoachRosterPlayerNameHint => 'Example: Minjun';

  @override
  String settingsCoachRosterAdded(Object player) {
    return '$player was added.';
  }

  @override
  String settingsCoachRosterActivated(Object player) {
    return '$player is now active.';
  }

  @override
  String get settingsSupportRoleTitle => 'Parent mode details';

  @override
  String get settingsDriveConnectionTitle => 'Google Drive connection';

  @override
  String get settingsDriveConnectionPlayerSummary =>
      'Check which Google Drive account stores and imports this device\'s records.';

  @override
  String get settingsDriveConnectionSupportSummary =>
      'Check the currently connected Google Drive account.';

  @override
  String get settingsDataSyncTitle => 'Data sync';

  @override
  String get settingsDataSyncPlayerSummary =>
      'Check freshness between current data and Drive backup, then run Drive actions.';

  @override
  String get settingsDataSyncSupportSummary =>
      'Import the latest backup and write shared changes to the separate contribution file.';

  @override
  String get settingsSyncSourceStatusTitle => 'Backup data';

  @override
  String get settingsSyncStatusTitle => 'Data sync status';

  @override
  String get settingsSyncShowDetails => 'Show details';

  @override
  String get settingsSyncHideDetails => 'Hide details';

  @override
  String get settingsSyncGoogleConnected => 'Google connected';

  @override
  String get settingsSyncGoogleDisconnected => 'Google disconnected';

  @override
  String get settingsSyncDailyOn => 'Daily backup on';

  @override
  String get settingsSyncDailyOff => 'Daily backup off';

  @override
  String get settingsSyncOnSaveOn => 'Backup on save on';

  @override
  String get settingsSyncOnSaveOff => 'Backup on save off';

  @override
  String settingsSyncBackedUpDataTime(Object time) {
    return 'Backed-up data: $time';
  }

  @override
  String settingsSyncCurrentDataSnapshot(Object time) {
    return 'Current data snapshot: $time';
  }

  @override
  String get settingsSyncStatusChecking => 'Checking';

  @override
  String get settingsSyncBackupDataReady => 'Backup source found.';

  @override
  String get settingsSyncStatusSignInNeeded => 'Connect';

  @override
  String get settingsSyncStatusNoBackup => 'No backup';

  @override
  String get settingsSyncStatusCurrent => 'Recent backup';

  @override
  String get settingsSyncStatusReview => 'Check backup';

  @override
  String get settingsSyncStatusStale => 'Backup stale';

  @override
  String get settingsSyncSummaryChecking => 'Checking the Drive backup status.';

  @override
  String get settingsSyncSummarySignInNeeded =>
      'Connect an account to compare this device with Drive backup and run import or backup actions.';

  @override
  String get settingsSyncSummaryNoBackup =>
      'No Drive backup file exists yet. Use Back up data to store the current data first.';

  @override
  String settingsSyncSummaryCurrent(Object time) {
    return 'The Drive backup was created around $time. Check this time before replacing or overwriting data.';
  }

  @override
  String settingsSyncSummaryStale(Object time) {
    return 'The Drive backup is from $time. Changes made after that may not be backed up yet.';
  }

  @override
  String settingsDriveActionFilePath(Object path) {
    return 'File path: $path';
  }

  @override
  String settingsDriveActionBackupTime(Object time) {
    return 'Backup saved at: $time';
  }

  @override
  String get settingsDriveActionBackupTimeUnknown =>
      'Backup saved time: not available on this device yet.';

  @override
  String get settingsDriveConnectAction => 'Connect Google Drive';

  @override
  String get settingsDriveDisconnectAction => 'Disconnect Google Drive';

  @override
  String get settingsRestoreLatestActionTitle => 'Import latest data';

  @override
  String get settingsBackupDataActionTitle => 'Back up data';

  @override
  String get settingsBackupContributionActionTitle => 'Back up contribution';

  @override
  String get backupRestoreDetailsAction => 'Review backup details';

  @override
  String get backupRestoreDetailsTitle => 'Backup and restore details';

  @override
  String get backupDetailsConnectedAccount => 'Connected account';

  @override
  String get backupDetailsTarget => 'Target';

  @override
  String get backupDetailsPlayerSourceTarget => 'Player source snapshot';

  @override
  String get backupDetailsParentContributionTarget =>
      'Parent contribution file';

  @override
  String get backupDetailsLocalData => 'Local data';

  @override
  String backupDetailsLocalCounts(int trainingCount, int optionCount) {
    return '$trainingCount training, $optionCount app records';
  }

  @override
  String get backupDetailsRemoteCreated => 'Remote backup';

  @override
  String get backupDetailsIntegrity => 'Integrity';

  @override
  String get backupDetailsIntegrityVerified => 'Hash verified';

  @override
  String get backupDetailsIntegrityLegacy => 'Legacy backup';

  @override
  String get backupDetailsDiff => 'Restore preview';

  @override
  String backupDetailsDiffCounts(int addCount, int updateCount,
      int conflictCount, int deleteCount, int skipCount) {
    return '$addCount add, $updateCount update, $conflictCount conflict, $deleteCount delete candidate, $skipCount skip';
  }

  @override
  String get backupDetailsPreviewUnavailable =>
      'Backup preview is unavailable right now.';

  @override
  String get backupPreviewChanged =>
      'The remote backup changed after the preview. Review the latest details before restoring.';

  @override
  String get backupDetailsParentCoreZero =>
      'Parent and coach uploads write zero player core records; only feedback and reward names are included.';

  @override
  String get restoreModeAddMissingOnly => 'Add missing only';

  @override
  String get restoreModeSafeMerge => 'Safe merge';

  @override
  String get settingsRoleAccountSummary =>
      'Choose this device usage mode first.';

  @override
  String get settingsRoleAccountTitle => 'Usage mode and account';

  @override
  String get settingsRoleAccountDescription =>
      'Choose how this device will be used first. The account connection below changes to match that mode.';

  @override
  String get settingsRoleAccountUnavailable =>
      'Google Drive account connection is unavailable in this build.';

  @override
  String get settingsRolePlayerDescription =>
      'Record training, meals, sketches, XP, and backups in player mode.';

  @override
  String get settingsRoleParentDescription =>
      'Read player records and manage feedback or reward names without editing core records.';

  @override
  String get settingsRoleCoachDescription =>
      'Review player records and sketches in parent mode, with shared feedback focused on training.';

  @override
  String get settingsRoleActionTitle => 'Mode-based actions';

  @override
  String get settingsPlayerActionSummary =>
      'In player mode, use backup first to protect new records, and use the import actions below only when you need to restore older data.';

  @override
  String get settingsSupportActionSummary =>
      'Parent mode does not create new source backups here. It imports player data and writes feedback or reward names to a separate contribution file.';

  @override
  String get settingsPlayerAccountTitle => 'Record backup Drive account';

  @override
  String get settingsPlayerAccountDescription =>
      'Connect the Google Drive account used to back up and import this device\'s training records.';

  @override
  String get settingsPlayerBackupActionBody =>
      'Save the current device records as the latest Google Drive backup. Use this first when protecting new entries.';

  @override
  String get settingsPlayerRestoreDriveActionTitle => 'Import latest data';

  @override
  String get settingsPlayerRestoreDriveActionBody =>
      'Safely merge the latest backup from Google Drive while keeping local-only records.';

  @override
  String get settingsPlayerRestoreLocalActionTitle => 'Undo latest import';

  @override
  String get settingsPlayerRestoreLocalActionBody =>
      'Revert this device to the state it had before the latest import changed it.';

  @override
  String get settingsSupportRestoreDriveActionTitle =>
      'Import latest player data';

  @override
  String get settingsSupportRestoreDriveActionBody =>
      'Pull the latest Google Drive backup that was saved in player mode onto this device.';

  @override
  String get settingsSupportRestoreLocalActionTitle => 'Undo latest import';

  @override
  String get settingsSupportRestoreLocalActionBody =>
      'Revert the latest imported player-data changes on this device to the previous state.';

  @override
  String get settingsSupportBackupConfirm =>
      'Back up parent-mode feedback and level reward names to the separate contribution file?';

  @override
  String get settingsSupportBackupSuccess =>
      'Shared changes were backed up to the contribution file.';

  @override
  String get settingsSupportBackupFailed =>
      'Could not back up shared changes. Check the Drive connection and family/player match.';

  @override
  String get settingsRestoreRollbackTitle => 'Import rollback';

  @override
  String get settingsRestoreRollbackBody =>
      'This is advanced recovery for undoing the last import on this device, not a regular backup action.';

  @override
  String familyRoleActivated(Object role) {
    return '$role mode activated.';
  }

  @override
  String get familyParentModeEnabled => 'Enable parent mode';

  @override
  String get familyParentModeDescription =>
      'Turn this on for parent mode. Turn it off to return to player mode.';

  @override
  String get familyChildName => 'Player name';

  @override
  String get familyParentName => 'Parent name';

  @override
  String get familyChildNameEmpty => 'Set the player name';

  @override
  String get familyParentNameEmpty => 'Set the parent name';

  @override
  String get familyEditNames => 'Edit family names';

  @override
  String get familyPolicyTitle => 'Parent mode/player sharing policy';

  @override
  String get familyPolicyChildOwnsData =>
      'Player mode backs up training, profile, diary, meals, and plans as the source of truth.';

  @override
  String get familyPolicyParentWritesOnly =>
      'Parent mode can save training feedback and level reward names only.';

  @override
  String get familyPolicyParentSeedRequired =>
      'Connect the parent device after at least one player backup already exists.';

  @override
  String get familyRoleChildActivated => 'Player mode activated.';

  @override
  String get familyRoleParentActivated => 'Parent mode activated.';

  @override
  String get familyNamesSaved => 'Family names saved.';

  @override
  String get driveConnectedAccount => 'Connected Drive account';

  @override
  String get driveConnectedAccountEmpty =>
      'No Google Drive account is connected yet.';

  @override
  String get driveSavedPlayerAccount => 'Player-mode backup Drive';

  @override
  String get driveReconnectSavedPlayer => 'Reconnect player-mode Drive';

  @override
  String get driveReconnectSavedPlayerHint =>
      'After leaving parent mode, reconnect the saved player-mode Drive account here.';

  @override
  String get driveReconnectSavedPlayerMismatch =>
      'Please reconnect with the saved player-mode Drive account.';

  @override
  String get driveSavedParentAccount => 'Saved parent-mode Drive';

  @override
  String get driveReconnectSavedParent => 'Reconnect saved parent-mode Drive';

  @override
  String get driveReconnectSavedParentHint =>
      'Reconnect the Drive account that was used most recently in parent mode.';

  @override
  String get driveReconnectSavedParentMismatch =>
      'Please reconnect with the saved parent-mode Drive account.';

  @override
  String get driveSharedChildAccount => 'Source backup Drive';

  @override
  String get driveSharedChildAccountEmpty =>
      'No source backup is known yet. Create at least one backup first.';

  @override
  String get driveSharedChildAccountRemoteBackup =>
      'A remote backup was found. Connect the same Google Drive account.';

  @override
  String get familyChildDriveConnectionSummary =>
      'Use the Google Drive account that holds the source backup.';

  @override
  String get familyParentUsesChildDriveSummary =>
      'Use the source backup Drive account here.';

  @override
  String get familyParentUsesChildDriveHint =>
      'In parent mode, sign in with the Google Drive account that holds the player\'s source data to sync training feedback and reward names into a separate contribution file.';

  @override
  String get familyParentUsesChildDriveWarning =>
      'Parent mode should connect to the Google Drive account that holds the player\'s source data so feedback and reward names sync safely into the contribution file.';

  @override
  String get familySharedSyncTitle => 'Data sync status';

  @override
  String get familySharedSyncDescription =>
      'Parent feedback and level reward names are written automatically into a separate contribution file.';

  @override
  String get familySyncAlertTitle => 'Parent sync';

  @override
  String familySyncParentTrainingAdded(int count) {
    return '$count new player training log(s) synced.';
  }

  @override
  String familySyncParentRewardClaimed(int count) {
    return '$count player reward claim(s) synced.';
  }

  @override
  String familySyncParentTrainingAndRewardClaimed(
      int trainingCount, int rewardCount) {
    return '$trainingCount new player training log(s) and $rewardCount reward claim(s) synced.';
  }

  @override
  String familySyncChildFeedbackAdded(int count) {
    return '$count parent feedback update(s) synced.';
  }

  @override
  String get familySyncChildRewardUpdated => 'Level reward names synced.';

  @override
  String familySyncChildFeedbackAndReward(int count) {
    return '$count parent feedback update(s) and reward names synced.';
  }

  @override
  String get familySharedLastSync => 'Last parent/player sync';

  @override
  String get familySharedLastPush => 'Last push';

  @override
  String get familySharedLastRefresh => 'Last import check';

  @override
  String get familySharedAutoRefreshDescription =>
      'When parent mode opens or the app resumes, the latest state is checked automatically. Auto checks pause when local changes are still waiting to be pushed to Drive.';

  @override
  String get familySharedPendingLocalChanges =>
      'Automatic import is paused because local changes still need to be pushed to Drive.';

  @override
  String get familySharedRestore => 'Import player data';

  @override
  String get familySharedRestoreConfirm =>
      'Import the latest player data from Google Drive with safe merge? Local-only records on this device are kept.';

  @override
  String get familySharedRestoreSuccess => 'Player data imported.';

  @override
  String get familySharedRestoreFailed =>
      'Failed to import player data. Please try again.';

  @override
  String get familySharedRestoreLocal => 'Import previous player data';

  @override
  String get familySharedRestoreLocalConfirm =>
      'Undo the latest imported player-data changes on this device? This replaces the player records and shared data shown on this device.';

  @override
  String get familySharedRestoreLocalSuccess => 'The latest import was undone.';

  @override
  String get familySharedRestoreLocalFailed =>
      'Failed to undo the latest import. Please try again.';

  @override
  String get restoreReconfirmTitle => 'Restore confirmation';

  @override
  String get restoreReconfirmBody =>
      'Do you really want to continue? Safe merge keeps local-only records; advanced rollback replaces current data.';

  @override
  String get familyParentFamilyMismatch =>
      'The connected Drive backup does not match this parent/player sharing data.';

  @override
  String get moreInfoAction => 'More info';

  @override
  String get parentReadOnlyProfileSummary => 'Profile is view only here.';

  @override
  String get parentReadOnlyProfileDescription =>
      'Parent mode keeps the profile read-only. Leave training feedback from the training log and set reward names from the level guide.';

  @override
  String get parentReadOnlySettingsOptions =>
      'Parent mode cannot edit the sport, default values, or news filters. Change them in player mode.';

  @override
  String get benchmarkReferencesTitle => 'Average benchmarks';

  @override
  String get benchmarkRefreshAction => 'Refresh average';

  @override
  String get benchmarkRefreshInProgress => 'Refreshing';

  @override
  String benchmarkLastSynced(Object date) {
    return 'Last sync: $date';
  }

  @override
  String get benchmarkRefreshSuccess => 'Average benchmark data updated.';

  @override
  String get benchmarkRefreshFailed =>
      'Failed to update average benchmark data. Check network.';

  @override
  String get benchmarkReferenceNote =>
      'Height and weight use CDC growth-chart medians. Activity time uses WHO youth guidance. Sport-specific conditioning ranges are app training references, not medical standards.';

  @override
  String get benchmarkAgeTableTitle => 'Averages by age';

  @override
  String get benchmarkAgeTableNote =>
      'If the player\'s age is set, that row is highlighted. Weekly targets are adjusted by the entered sport experience.';

  @override
  String get benchmarkAgeColumnAge => 'Age';

  @override
  String get benchmarkAgeColumnHeight => 'Avg height';

  @override
  String get benchmarkAgeColumnWeight => 'Avg weight';

  @override
  String get benchmarkAgeColumnLifting => 'Lifting/session';

  @override
  String benchmarkAgeColumnConditioning(Object metric) {
    return '$metric/session';
  }

  @override
  String get benchmarkAgeColumnWeeklyTarget => 'Weekly target';

  @override
  String benchmarkAgeValue(int age) {
    return 'Age $age';
  }

  @override
  String get benchmarkAgeCurrentBadge => 'Current';

  @override
  String benchmarkAgeLiftingValue(int count) {
    return '$count reps';
  }

  @override
  String benchmarkAgeWeeklyTargetValue(int minutes, int sessions) {
    return '$minutes min · $sessions sessions';
  }

  @override
  String get parentReadOnlyEntryTitle =>
      'Parent mode cannot edit training notes.';

  @override
  String get parentReadOnlyEntryBody =>
      'Core records like training, meals, and diary stay in player mode. Parent mode leaves the original record untouched and stores only feedback and reward naming separately.';

  @override
  String get parentReadOnlyLogsSummary =>
      'View training logs and leave feedback only.';

  @override
  String get parentReadOnlyLogsBanner =>
      'Parent mode does not delete training logs. Open a record to leave feedback instead.';

  @override
  String get parentReadOnlyLogsMessage =>
      'Parent mode cannot delete training logs.';

  @override
  String get parentReadOnlyMealLogSummary => 'Meal log is view only here.';

  @override
  String get parentReadOnlyMealLog =>
      'Parent mode cannot edit meal logs. Update meals in player mode.';

  @override
  String get parentReadOnlyQuiz =>
      'Parent mode does not run the quiz. Quiz history and XP stay in player mode.';

  @override
  String get parentReadOnlyDrawerMessage =>
      'Parent mode keeps core records read-only. Use shared data and reward naming instead.';

  @override
  String get parentReadOnlyCoreDataMessage =>
      'Parent mode cannot edit player core data. Switch to player mode to change it.';

  @override
  String get parentReadOnlyCalendarSummary => 'Calendar is view only here.';

  @override
  String get parentReadOnlyCalendarBanner =>
      'Parent mode keeps the calendar read-only. Update plans, matches, and meals in player mode.';

  @override
  String get parentReadOnlyCalendarMessage =>
      'Parent mode cannot edit the calendar.';

  @override
  String get parentReadOnlyChallengeSummary =>
      'Parent mode can create challenges.';

  @override
  String get parentReadOnlyChallengeMessage =>
      'In Parent mode, you can create challenges and set finish gifts. Mission records are still entered in player mode.';

  @override
  String get parentReadOnlyDiaryMessage => 'Parent mode cannot edit the diary.';

  @override
  String get parentReadOnlyDiaryBadge => 'Parent mode read-only';

  @override
  String get parentReadOnlySketchMessage =>
      'Parent mode cannot edit training sketches.';

  @override
  String get parentReadOnlyFortuneEmpty =>
      'No saved mood card is available yet.';

  @override
  String get parentFeedbackSectionTitle => 'Parent feedback';

  @override
  String get parentFeedbackHelper =>
      'Keep the original training record untouched and store only the parent feedback for this session separately.';

  @override
  String get parentFeedbackReadOnlyHint =>
      'Feedback left on this training log by a parent.';

  @override
  String get parentFeedbackInputLabel => 'Parent feedback';

  @override
  String get parentFeedbackInputHint =>
      'Write what a parent wants to praise or what to watch next time.';

  @override
  String get parentFeedbackSave => 'Save feedback';

  @override
  String get parentFeedbackClear => 'Clear';

  @override
  String get parentFeedbackWriteAction => 'Write feedback';

  @override
  String get parentFeedbackEditAction => 'Edit feedback';

  @override
  String get parentFeedbackViewAction => 'View feedback';

  @override
  String get parentFeedbackDiscardTitle => 'Unsaved feedback';

  @override
  String get parentFeedbackDiscardBody =>
      'You have unsaved feedback. Leave without saving?';

  @override
  String get parentFeedbackDiscardAction => 'Leave';

  @override
  String get parentFeedbackSaved => 'Feedback saved.';

  @override
  String get parentFeedbackSaveFailed => 'Could not save feedback. Try again.';

  @override
  String get parentFeedbackCleared => 'Feedback cleared.';

  @override
  String get parentFeedbackEmpty => 'There is no feedback yet.';

  @override
  String get parentFeedbackReactionOnly => 'The player left a reaction.';

  @override
  String get parentFeedbackReactionLabel => 'Reaction';

  @override
  String get parentFeedbackReactionNone => 'None';

  @override
  String get parentFeedbackReactionThanks => 'Thanks';

  @override
  String get parentFeedbackReactionProud => 'Proud';

  @override
  String get parentFeedbackReactionReview => 'Review';

  @override
  String get parentFeedbackReactionTry => 'Try next';

  @override
  String get parentFeedbackOpenExistingEntryTitle =>
      'Open an existing training log to leave feedback.';

  @override
  String get parentFeedbackOpenExistingEntryBody =>
      'Parent mode does not create new training logs. Parent feedback can only be saved on an existing training log after the player records it first.';

  @override
  String get parentSharedSyncInProgress =>
      'Syncing to the contribution file...';

  @override
  String get parentSharedSyncDone => 'Synced to the contribution file.';

  @override
  String get parentSharedSyncPending =>
      'It will sync into the contribution file after Drive is connected.';

  @override
  String get levelGuideParentModeLabel => 'Parent mode';

  @override
  String get levelGuideChildModeLabel => 'Player mode';

  @override
  String get levelGuideParentModeDescription =>
      'Parent mode can save reward names only, and saved reward names sync through the parent contribution file. Reward received marks stay in player mode.';

  @override
  String get levelGuideChildModeDescription =>
      'Player mode can mark received level rewards. Reward naming stays in parent mode.';

  @override
  String get levelGuideModeInfoTooltip => 'Show mode description';

  @override
  String get levelGuideClaimChildOnly => 'Claim in player mode';

  @override
  String get levelGuideRewardFallbackName => 'Reward';

  @override
  String levelGuideRewardClaimed(Object rewardName) {
    return 'Claimed $rewardName.';
  }

  @override
  String get levelGuideRewardSaved => 'Reward saved.';

  @override
  String get levelGuideRewardCleared => 'Reward cleared.';

  @override
  String levelGuideMaxLevelRangeLabel(Object minXp) {
    return '$minXp XP+ · max level';
  }

  @override
  String levelGuideMaxLevelMasteryHint(Object masterySpan) {
    return 'There is no next level. Keep earning a mastery star every $masterySpan XP.';
  }

  @override
  String get trainingPlanAddTitle => 'Add Training Plan';

  @override
  String get trainingPlanEditTitle => 'Edit Training Plan';

  @override
  String get trainingPlanViewTitle => 'View Training Plan';

  @override
  String get matchAddTitle => 'Add Match';

  @override
  String get matchEditTitle => 'Edit Match';

  @override
  String get matchViewTitle => 'View Match';

  @override
  String get matchKindFriendly => 'Friendly';

  @override
  String get matchKindLeague => 'League';

  @override
  String get matchKindTournament => 'Tournament';

  @override
  String get matchFriendlyResultLabel => 'Friendly result';

  @override
  String get matchResultLabel => 'Match result';

  @override
  String get matchResultUnset => 'Unset';

  @override
  String get matchResultWin => 'Win';

  @override
  String get matchResultDraw => 'Draw';

  @override
  String get matchResultLoss => 'Loss';

  @override
  String get matchLeagueSectionTitle => 'League details';

  @override
  String get matchTournamentSectionTitle => 'Tournament details';

  @override
  String get matchCompetitionNameLabel => 'Competition name';

  @override
  String get matchLeagueNameHint => 'e.g. Weekend League';

  @override
  String get matchTournamentNameHint => 'e.g. Cup tournament';

  @override
  String get matchCompetitionSelectLabel => 'Saved competitions';

  @override
  String get matchCompetitionStatusLabel => 'Competition status';

  @override
  String get matchCompetitionStatusActive => 'Active';

  @override
  String get matchCompetitionStatusFinished => 'Finished';

  @override
  String matchCompetitionOptionActive(Object name) {
    return '$name · active';
  }

  @override
  String matchCompetitionOptionFinished(Object name) {
    return '$name · finished';
  }

  @override
  String get matchCompetitionQuickLoadTitle => 'Load saved competition';

  @override
  String get matchCompetitionQuickLoadHelper =>
      'Fill the match record with the league or tournament name, teams, status, and venue.';

  @override
  String get matchCompetitionManagedOnlyTitle =>
      'Select a competition created in Competition Management.';

  @override
  String get matchCompetitionManagedOnlyBody =>
      'Match registration no longer creates leagues or tournaments. Create one in Competition Management first, then load it here to record the match.';

  @override
  String get matchCompetitionSelectionRequired =>
      'Select a competition created in Competition Management first.';

  @override
  String get matchCompetitionSelectedTitle => 'Selected competition';

  @override
  String get matchCompetitionFinishedNotice =>
      'This competition is finished. Select it when organizing past match records.';

  @override
  String get matchCompetitionManageButton => 'Teams / results';

  @override
  String get matchCompetitionOpenButton => 'Competition management';

  @override
  String get matchCompetitionOpenHelper => 'Run leagues and tournaments';

  @override
  String get matchCompetitionProTitle => 'Competition Operations Center';

  @override
  String get matchCompetitionProSubtitle =>
      'Manage participating teams, operations details, standings, and brackets with coaches and players.';

  @override
  String get matchCompetitionOperationsSummaryTitle => 'Operations summary';

  @override
  String get matchCompetitionListTitle => 'Competition status';

  @override
  String matchCompetitionListCount(int count) {
    return '$count competitions';
  }

  @override
  String get matchCompetitionNewButton => 'New';

  @override
  String matchCompetitionFilterAll(int count) {
    return 'All $count';
  }

  @override
  String matchCompetitionFilterActive(int count) {
    return 'Active $count';
  }

  @override
  String matchCompetitionFilterFinished(int count) {
    return 'Finished $count';
  }

  @override
  String get matchCompetitionFilterEmptyTitle =>
      'No competitions match this status.';

  @override
  String get matchCompetitionFilterEmptyBody =>
      'Reset the filter to see all competitions.';

  @override
  String matchCompetitionCardSummary(int teams, int matches) {
    return '$teams teams · $matches matches';
  }

  @override
  String get matchCompetitionDeleteDialogTitle => 'Delete competition';

  @override
  String matchCompetitionDeleteDialogBody(String name) {
    return 'Delete \"$name\"? Saved match records will not be deleted.';
  }

  @override
  String get matchCompetitionDeleteButton => 'Delete';

  @override
  String get matchCompetitionDeletedFeedback => 'Competition deleted.';

  @override
  String get matchCompetitionCreateLeagueButton => 'Create league';

  @override
  String get matchCompetitionCreateTournamentButton => 'Create tournament';

  @override
  String get matchCompetitionSeasonLabel => 'Season';

  @override
  String get matchCompetitionSeasonHint => 'e.g. Summer 2026';

  @override
  String get matchCompetitionVenueLabel => 'Venue';

  @override
  String get matchCompetitionVenueHint => 'e.g. Main pitch';

  @override
  String get matchCompetitionOrganizerLabel => 'Lead';

  @override
  String get matchCompetitionOrganizerHint => 'e.g. Coach Kim';

  @override
  String get matchCompetitionNoteLabel => 'Operations note';

  @override
  String get matchCompetitionNoteHint =>
      'e.g. Groups into knockout, rotation required';

  @override
  String get matchCompetitionSaveCompetition => 'Save competition';

  @override
  String get matchCompetitionEditButton => 'Edit';

  @override
  String get matchCompetitionEditorBasicsTitle => 'Competition basics';

  @override
  String get matchCompetitionEditorOperationsTitle => 'Operations details';

  @override
  String get matchCompetitionNoCompetitionsProBody =>
      'Create a league or tournament first to manage teams, operations details, standings, and brackets professionally.';

  @override
  String get matchCompetitionOperationsDetailEmpty => 'No operations details';

  @override
  String get matchCompetitionNextActionLabel => 'Next operation';

  @override
  String get matchCompetitionNextRegisterTeams => 'Register teams';

  @override
  String get matchCompetitionNextRecordFirstMatch => 'Record first match';

  @override
  String get matchCompetitionNextRecordNextMatch => 'Record next match';

  @override
  String get matchCompetitionNextCloseCompetition => 'Review closing';

  @override
  String get matchCompetitionNextReviewArchive => 'Review archive';

  @override
  String matchCompetitionProgressPercent(int percent) {
    return 'Progress $percent%';
  }

  @override
  String get matchCompetitionManagerNewTitle => 'Competition manager';

  @override
  String matchCompetitionManagerTitle(String name) {
    return '$name manager';
  }

  @override
  String get matchCompetitionTeamsTab => 'Teams';

  @override
  String get matchCompetitionResultsTab => 'Results';

  @override
  String get matchCompetitionBackButton => 'Back';

  @override
  String get matchCompetitionTeamPreviewTitle => 'Team preview';

  @override
  String get matchCompetitionTeamNameLabel => 'Team name';

  @override
  String get matchCompetitionAddTeamButton => 'Add';

  @override
  String get matchCompetitionTeamNameRequired => 'Enter a team name.';

  @override
  String get matchCompetitionTeamAlreadyAdded =>
      'That team is already registered.';

  @override
  String get matchCompetitionTeamsListTitle => 'Registered teams';

  @override
  String get matchCompetitionEditParticipantsAction => 'Edit participants';

  @override
  String get matchCompetitionLeagueSetupTitle => 'League teams';

  @override
  String get matchCompetitionLeagueSetupBody =>
      'Add teams to calculate standings, records, goal difference, and points automatically from match results.';

  @override
  String get matchCompetitionTournamentSetupTitle => 'Tournament seeding';

  @override
  String get matchCompetitionTournamentSetupBody =>
      'Drag teams into seed order. Matchups and byes are assigned automatically from the highest seeds.';

  @override
  String get matchCompetitionTournamentPreviewTitle => 'Seeded bracket preview';

  @override
  String matchCompetitionTournamentSeedPair(
      int slot, String teamA, String teamB) {
    return 'Match $slot · $teamA vs $teamB';
  }

  @override
  String get matchCompetitionOwnTeamBadge => 'Our team';

  @override
  String matchCompetitionRemoveTeamTooltip(String team) {
    return 'Remove $team';
  }

  @override
  String get matchCompetitionTeamsInputLabel => 'Participating teams';

  @override
  String get matchCompetitionTeamsInputHint =>
      'Enter one team per line or separate with commas';

  @override
  String matchCompetitionTeamCount(int count) {
    return '$count team(s) registered';
  }

  @override
  String get matchCompetitionSaveTeams => 'Save teams';

  @override
  String get matchCompetitionSavedFeedback => 'Competition details saved.';

  @override
  String get matchCompetitionNameRequired => 'Enter a competition name.';

  @override
  String get matchCompetitionMinimumTeamsRequired =>
      'Add at least two participating teams to save the competition.';

  @override
  String get matchLeagueStandingsTitle => 'League standings';

  @override
  String get matchTournamentBracketTitle => 'Tournament bracket';

  @override
  String get matchTournamentImageAction => 'Image';

  @override
  String get matchTournamentImageTooltip => 'Export bracket image';

  @override
  String get matchTournamentImageExportedFeedback =>
      'The bracket image is ready.';

  @override
  String get matchTournamentImageExportFailedFeedback =>
      'Could not create the bracket image.';

  @override
  String get matchTournamentOpenFullScreen => 'Open bracket full screen';

  @override
  String get matchTournamentZoomOut => 'Zoom bracket out';

  @override
  String get matchTournamentZoomReset => 'Reset bracket zoom';

  @override
  String get matchTournamentZoomIn => 'Zoom bracket in';

  @override
  String matchTournamentRoundOf(int number) {
    return 'Round of $number';
  }

  @override
  String matchTournamentWinnerSource(int number) {
    return 'Winner M$number';
  }

  @override
  String get matchTournamentChampionSlot => 'Champion';

  @override
  String get matchCompetitionNoTeams => 'No teams are registered.';

  @override
  String get matchCompetitionNoMatches => 'No matches are recorded yet.';

  @override
  String get matchCompetitionFixtureRecordContext =>
      'Loaded from competition schedule';

  @override
  String matchCompetitionFixtureRound(int round) {
    return 'Round $round';
  }

  @override
  String get matchCompetitionFixturesTitle => 'Schedule';

  @override
  String get matchCompetitionFixturesEmpty =>
      'No fixtures have been generated yet.';

  @override
  String get matchCompetitionFixtureVersus => 'vs';

  @override
  String get matchCompetitionFixtureTbd => 'TBD';

  @override
  String get matchCompetitionMyTeamFallback => 'Our team';

  @override
  String get matchTournamentByeLabel => 'Bye';

  @override
  String matchTournamentPairLabel(int number) {
    return 'Match $number';
  }

  @override
  String matchTournamentPairText(String teamA, String teamB) {
    return '$teamA vs $teamB';
  }

  @override
  String get matchTournamentRecordedProgressTitle => 'Recorded progress';

  @override
  String matchTournamentRecordedProgress(
      String stage, String opponent, String outcome) {
    return '$stage · vs $opponent · $outcome';
  }

  @override
  String get matchCompetitionSummaryTeams => 'Teams';

  @override
  String get matchCompetitionSummaryMatches => 'Recorded matches';

  @override
  String get matchCompetitionSummaryLeader => 'Leader';

  @override
  String get matchCompetitionSummaryRecorded => 'Recorded';

  @override
  String get matchCompetitionSummaryProgress => 'Progress';

  @override
  String get matchCompetitionNoLeader => 'None yet';

  @override
  String get matchTournamentSummarySlots => 'Bracket slots';

  @override
  String matchTournamentSlotProgress(int recorded, int total) {
    return '$recorded/$total';
  }

  @override
  String get matchTournamentPairPending => 'Pending';

  @override
  String get matchTournamentPairByeStatus => 'Bye';

  @override
  String get matchTournamentVersusLabel => 'vs';

  @override
  String matchLeaguePlayedSummary(int played) {
    return '$played played';
  }

  @override
  String matchLeagueRecordSummary(int wins, int draws, int losses) {
    return '${wins}W ${draws}D ${losses}L';
  }

  @override
  String matchLeagueGoalDifferenceSummary(int difference) {
    return 'GD $difference';
  }

  @override
  String matchLeaguePointsSummary(int points) {
    return '$points pts';
  }

  @override
  String get matchLeagueRoundLabel => 'Round or matchday';

  @override
  String get matchLeagueRoundHint => 'e.g. Round 3';

  @override
  String get matchTournamentStageLabel => 'Tournament stage';

  @override
  String get matchTournamentStagePreliminary => 'Preliminary';

  @override
  String get matchTournamentStageRound16 => 'Round of 16';

  @override
  String get matchTournamentStageQuarterfinal => 'Quarterfinal';

  @override
  String get matchTournamentStageSemifinal => 'Semifinal';

  @override
  String get matchTournamentStageFinal => 'Final';

  @override
  String get matchTournamentOutcomeLabel => 'Progress result';

  @override
  String get matchTournamentOutcomeOngoing => 'In progress';

  @override
  String get matchTournamentOutcomeAdvanced => 'Advanced';

  @override
  String get matchTournamentOutcomeEliminated => 'Eliminated';

  @override
  String get matchTournamentOutcomeChampion => 'Champion';

  @override
  String get matchTournamentShootoutTitle => 'Penalty shootout';

  @override
  String get matchTournamentShootoutHelper =>
      'When a tournament match is level, use the shootout score to decide who advances.';

  @override
  String get matchTournamentShootoutRequired =>
      'A drawn tournament match needs a penalty shootout score to decide the winner.';

  @override
  String get matchTournamentShootoutTie =>
      'Penalty shootout scores cannot be level.';

  @override
  String matchTournamentShootoutSummary(int homeScore, int awayScore) {
    return 'Penalty shootout $homeScore : $awayScore';
  }

  @override
  String get matchOpponentTeamLabel => 'Opponent team';

  @override
  String get matchOpponentTeamHint => 'e.g. Suwon U15';

  @override
  String get matchOpponentRequired => 'Select or enter an opponent team.';

  @override
  String get matchScoreRequired => 'Enter both teams\' scores.';

  @override
  String requiredFieldLabel(Object label) {
    return '$label (required)';
  }

  @override
  String get matchLocationHint => 'e.g. Main stadium';

  @override
  String get matchBoardTitle => 'Match board';

  @override
  String get matchBoardHelper =>
      'Set the opponent, score, result, and personal stats directly on the board.';

  @override
  String get matchBoardEventsTitle => 'Quick events';

  @override
  String get matchYellowCardsLabel => 'Yellow cards';

  @override
  String get matchRedCardsLabel => 'Red cards';

  @override
  String get matchDisciplineSummaryLabel => 'Cards';

  @override
  String matchDisciplineSummary(int yellowCards, int redCards) {
    return 'Yellow $yellowCards · Red $redCards';
  }

  @override
  String get matchDetailsSectionTitle => 'Details';

  @override
  String get matchDetailsSectionHelper =>
      'Keep venue and notes after the live match flow.';

  @override
  String get matchFlowBasicSectionTitle => 'Basics';

  @override
  String get matchFlowCompetitionSectionTitle => 'Competition setup';

  @override
  String get matchFlowCompetitionSectionHelper =>
      'Select a saved competition first to fill teams and status together.';

  @override
  String get matchFlowOpponentSectionTitle => 'Opponent';

  @override
  String get matchFlowOpponentSectionHelper =>
      'Choose this match\'s opponent from the registered teams.';

  @override
  String get matchFlowResultSectionTitle => 'Result';

  @override
  String get matchFlowResultSectionHelper =>
      'Pick W/D/L first, then adjust the score and competition result.';

  @override
  String get matchFlowPersonalSectionTitle => 'Personal record';

  @override
  String get matchFlowPersonalSectionHelper =>
      'Add values you want to review later, such as goals, assists, and minutes.';

  @override
  String get matchLeagueTeamsLabel => 'League teams';

  @override
  String get matchLeagueTeamsHint =>
      'Enter one team per line or separate with commas';

  @override
  String get matchTournamentTeamsLabel => 'Tournament teams';

  @override
  String get matchTournamentTeamsHint =>
      'Enter participating teams one per line or separate them with commas';

  @override
  String get matchLeaguePointsMode => 'Points';

  @override
  String get matchTournamentWinsMode => 'Tournament wins';

  @override
  String get matchLeaguePointsLabel => 'League points';

  @override
  String get matchTournamentWinsLabel => 'Tournament wins';

  @override
  String matchLeaguePointsValue(int points) {
    return '$points pts';
  }

  @override
  String matchTournamentWinsValue(int count) {
    return '$count wins';
  }

  @override
  String get matchOurScoreLabel => 'Our score';

  @override
  String get matchOpponentScoreLabel => 'Opponent score';

  @override
  String get matchGoalsLabel => 'Goals';

  @override
  String get matchAssistsLabel => 'Assists';

  @override
  String matchCountIncreaseTooltip(String label) {
    return 'Increase $label';
  }

  @override
  String matchCountDecreaseTooltip(String label) {
    return 'Decrease $label';
  }

  @override
  String get matchMinutesPlayedLabel => 'Minutes played';

  @override
  String get matchMinutesPlayedHint => 'e.g. 70';

  @override
  String get matchNoteOptionalLabel => 'Note (optional)';

  @override
  String get matchShotsOnTargetLabel => 'Shots on target';

  @override
  String get matchBallsWonLabel => 'Balls won';

  @override
  String get matchHubTopActionTooltip => 'Team management';

  @override
  String get matchHubTitle => 'Team management';

  @override
  String get matchHubSubtitle =>
      'Manage player operations and match operations as one team flow.';

  @override
  String get matchHubOverviewTitle => 'Operations snapshot';

  @override
  String get matchHubRecentFormLabel => 'Recent form';

  @override
  String get matchHubRecordButton => 'Record match';

  @override
  String get teamMatchHubUpcomingTab => 'Upcoming';

  @override
  String get teamMatchHubResultsTab => 'Results';

  @override
  String get teamMatchHubUpcomingTitle => 'Matches to record';

  @override
  String get teamMatchHubUpcomingEmptyTitle =>
      'No competition matches are ready to record.';

  @override
  String get teamMatchHubUpcomingEmptyBody =>
      'Create a competition to record our matches from its schedule or bracket.';

  @override
  String get teamMatchHubDateUnset => 'Date not set';

  @override
  String get teamMatchHubRecordFixtureAction => 'Record result';

  @override
  String get matchEntryManagedInHubTitle =>
      'Match records are managed in Team Management.';

  @override
  String get matchEntryManagedInHubBody =>
      'Training notes no longer show match details. View and edit matches from the top Team Management area.';

  @override
  String get matchHubRecordHelper => 'Enter today\'s result quickly';

  @override
  String get matchRecordsOpenButton => 'Match records';

  @override
  String get matchRecordsOpenHelper => 'Review past match results';

  @override
  String get matchRecordsTitle => 'Match records';

  @override
  String get matchRecordsSubtitle =>
      'Review friendly, league, and tournament results by date.';

  @override
  String get matchRecordsSummaryTitle => 'Record summary';

  @override
  String get matchRecordsListTitle => 'All match records';

  @override
  String get matchRecordsCompetitionAllFilter => 'All competitions';

  @override
  String get matchRecordsSearchHint =>
      'Search opponent, competition, round, venue, or notes';

  @override
  String get matchRecordsSearchClearTooltip => 'Clear search';

  @override
  String get matchRecordsOutcomeAllFilter => 'All results';

  @override
  String get matchRecordsOutcomeUnsetFilter => 'Result not recorded';

  @override
  String get matchRecordsDateAllFilter => 'All dates';

  @override
  String get matchRecordsDateLast30DaysFilter => 'Last 30 days';

  @override
  String get matchRecordsDateThisYearFilter => 'This year';

  @override
  String get matchRecordsFilterEmptyTitle => 'No matches fit these filters.';

  @override
  String get matchRecordsFilterEmptyBody =>
      'Reset the search and filters, then try again.';

  @override
  String get matchHubCalendarButton => 'Open calendar';

  @override
  String get matchHubCalendarHelper => 'Review matches and plans by date';

  @override
  String get matchHubStatsButton => 'Match stats';

  @override
  String get matchHubStatsHelper => 'Analyze record and personal output';

  @override
  String get matchHubCompetitionHelper =>
      'Manage teams and competition results';

  @override
  String get matchHubCompetitionsTitle => 'Competition board';

  @override
  String get matchHubNoCompetitionsTitle => 'No competitions registered.';

  @override
  String get matchHubNoCompetitionsSubtitle =>
      'When you record league or tournament matches, teams, standings, and brackets collect here.';

  @override
  String get matchHubRecentMatchesTitle => 'Recent matches';

  @override
  String get matchHubEmptyTitle => 'No match records yet.';

  @override
  String get matchHubEmptySubtitle =>
      'Start with a friendly match to calculate win rate and recent form.';

  @override
  String get matchHubOpeningFeedback => 'Opening Team Management.';

  @override
  String matchHubRecordedOnlyProgress(int count) {
    return '$count match(es) recorded';
  }

  @override
  String matchHubKindBreakdown(int friendly, int league, int tournament) {
    return 'Friendly $friendly · League $league · Tournament $tournament';
  }

  @override
  String get matchHubCompetitionStateLabel => 'Competition status';

  @override
  String matchHubCompetitionStateValue(int active, int finished) {
    return 'Active $active · Finished $finished';
  }

  @override
  String get matchHubTeamManagementHeaderSubtitle =>
      'Connect player management, match records, and competition flow in one place.';

  @override
  String get matchHubTeamManagementTitle => 'Team snapshot';

  @override
  String get matchHubTeamManagementHelper =>
      'Manage roster, schedule, and lineup';

  @override
  String get matchHubTeamStateLabel => 'Our team';

  @override
  String matchHubTeamStateValue(int count) {
    return '$count team(s)';
  }

  @override
  String get matchHubNoPrimaryTeamValue => 'Not set';

  @override
  String get matchHubNoTeamsTitle => 'No team set yet.';

  @override
  String get matchHubNoTeamsSubtitle =>
      'Prepare your team in the team management screen where player registration starts immediately.';

  @override
  String get matchHubCommandCenterTitle => 'Operations work';

  @override
  String get matchHubCommandCenterHelper =>
      'Choose player management or match management from one screen.';

  @override
  String get matchHubPlayerCommandHelper =>
      'Manage player registration, the tactics book, and match-prep boards.';

  @override
  String get matchHubTeamCommandHelper =>
      'Switch between player management and match management in one team structure.';

  @override
  String get matchHubTeamCommandPrimary => 'Open team management';

  @override
  String get matchHubMatchCommandTitle => 'Match management';

  @override
  String get matchHubMatchCommandHelper =>
      'Quickly run match recording, record review, and stats.';

  @override
  String matchHubMoreTeamsCount(int count) {
    return '$count more team(s)';
  }

  @override
  String matchHubTeamFormationValue(Object formation) {
    return '$formation formation';
  }

  @override
  String get clubScheduleTitle => 'Club Schedule';

  @override
  String get clubScheduleSubtitle =>
      'Check weekly training times, uniform colors, and sock colors quickly.';

  @override
  String get clubScheduleHomeTitle => 'Club schedule';

  @override
  String get clubScheduleHomeTodayRest => 'No training today';

  @override
  String get clubScheduleHomeSetupHint =>
      'Add training times, uniform colors, and sock colors.';

  @override
  String clubScheduleHomeNextTraining(Object weekday, Object time) {
    return 'Next training $weekday $time';
  }

  @override
  String clubScheduleTodayTraining(Object time) {
    return 'Today $time';
  }

  @override
  String get clubScheduleTodayNoTraining => 'No training is set for today.';

  @override
  String clubScheduleNextTraining(Object weekday, Object time) {
    return 'Next training: $weekday $time';
  }

  @override
  String get clubScheduleNoUpcomingTraining => 'No upcoming training.';

  @override
  String get clubScheduleClubNameLabel => 'Club name';

  @override
  String get clubScheduleClubNameHint => 'e.g. Seongnam U15';

  @override
  String get clubMorningWorkoutAlertTitle => 'Morning workout alarm';

  @override
  String get clubMorningWorkoutAlertHelper =>
      'Keep your morning workout time alongside your club schedule.';

  @override
  String get clubMorningWorkoutAlertSwitchTitle =>
      'Turn on morning workout alarm';

  @override
  String clubMorningWorkoutAlertSwitchSubtitle(Object weekdays, Object time) {
    return '$weekdays · alert at $time';
  }

  @override
  String get clubMorningWorkoutAlertTimeTitle => 'Alert time';

  @override
  String clubMorningWorkoutAlertTimeSubtitle(Object time) {
    return 'Current time $time';
  }

  @override
  String get clubMorningWorkoutAlertChangeTimeAction => 'Change time';

  @override
  String get clubMorningWorkoutAlertWeekdayTitle => 'Alert weekdays';

  @override
  String get clubMorningWorkoutAlertEveryDay => 'Every day';

  @override
  String get clubScheduleWeekdayTitle => 'Weekly training times';

  @override
  String get clubScheduleWeekdayHelper =>
      'Turn on training days, then set start time, end time, uniform color, and sock color.';

  @override
  String get clubScheduleStartTimeLabel => 'Start';

  @override
  String get clubScheduleEndTimeLabel => 'End';

  @override
  String get clubScheduleDayOffLabel => 'Off';

  @override
  String get clubScheduleDayUniformLabel => 'Uniform';

  @override
  String get clubScheduleDaySockLabel => 'Socks';

  @override
  String get clubScheduleUniformTitle => 'Uniform colors';

  @override
  String get clubScheduleUniformHelper =>
      'Save the home, away, and goalkeeper colors you need at training.';

  @override
  String get clubScheduleHomeKitLabel => 'Home';

  @override
  String get clubScheduleAwayKitLabel => 'Away';

  @override
  String get clubScheduleKeeperKitLabel => 'GK';

  @override
  String get clubScheduleColorSelectTooltip => 'Select color';

  @override
  String get clubScheduleColorPresetsLabel => 'Common colors';

  @override
  String get clubScheduleColorHueLabel => 'Hue';

  @override
  String get clubScheduleColorSaturationLabel => 'Saturation';

  @override
  String get clubScheduleColorBrightnessLabel => 'Brightness';

  @override
  String get clubScheduleSaveButton => 'Save club schedule';

  @override
  String get clubScheduleSavedFeedback => 'Club schedule saved.';

  @override
  String get clubScheduleSaveFailedFeedback =>
      'Could not save the club schedule. Please try again.';

  @override
  String get clubScheduleUnsavedDialogTitle => 'Unsaved changes';

  @override
  String get clubScheduleUnsavedDialogBody =>
      'Some club schedule changes have not been saved yet. Save before leaving?';

  @override
  String get clubScheduleUnsavedKeepEditing => 'Keep editing';

  @override
  String get clubScheduleUnsavedLeaveWithoutSaving => 'Leave without saving';

  @override
  String get clubScheduleUnsavedSaveAndLeave => 'Save and leave';

  @override
  String get clubTrainingNotificationChannelName => 'Club training alerts';

  @override
  String get clubTrainingNotificationChannelDescription =>
      'Reminders before club training starts';

  @override
  String clubTrainingNotificationTitle(Object clubName) {
    return '$clubName training prep';
  }

  @override
  String clubTrainingNotificationBody(int minutesBefore, Object timeRange) {
    return 'Training in $minutesBefore min · $timeRange';
  }

  @override
  String get clubMorningWorkoutNotificationTitle => 'Morning workout alarm';

  @override
  String clubMorningWorkoutNotificationBody(Object time) {
    return '$time is your morning workout time.';
  }

  @override
  String get teamManagementTitle => 'Team Management';

  @override
  String get teamManagementSubtitle =>
      'Organize the roster, tactics book, schedule, and competitions by task.';

  @override
  String get teamManagementOpenButton => 'Team management';

  @override
  String get teamManagementPlayerSectionTab => 'Player management';

  @override
  String get teamManagementMatchSectionTab => 'Match management';

  @override
  String get teamManagementDefaultTeamName => 'Our team';

  @override
  String get teamManagementWorkspaceTitle => 'Choose a workspace';

  @override
  String get teamManagementWorkspaceHelper =>
      'Choose a task button to open the roster, tactics book, or schedule screen.';

  @override
  String get teamManagementWorkspaceBackButton => 'Back to tasks';

  @override
  String get teamManagementWorkspaceRosterTab => 'Roster';

  @override
  String get teamManagementWorkspaceBoardTab => 'Tactics board';

  @override
  String get teamManagementBoardHeaderButton => 'Board';

  @override
  String get teamManagementCompetitionHeaderButton => 'Cups';

  @override
  String get teamManagementTacticBookTitle => 'Tactic list';

  @override
  String teamManagementTacticBookPageCount(int count) {
    return '$count tactic(s)';
  }

  @override
  String teamManagementTacticBoardDefaultTitle(int index) {
    return 'Tactic $index';
  }

  @override
  String teamManagementTacticBoardCopyTitle(Object title) {
    return '$title copy';
  }

  @override
  String get teamManagementTacticBoardAddButton => 'New tactic';

  @override
  String get teamManagementTacticBoardDuplicateButton => 'Duplicate';

  @override
  String get teamManagementTacticBoardRenameButton => 'Rename';

  @override
  String get teamManagementTacticBoardEditButton => 'Tactic details';

  @override
  String get teamManagementTacticBoardDeleteButton => 'Delete';

  @override
  String get teamManagementTacticBoardRenameDialogTitle => 'Rename tactic';

  @override
  String get teamManagementTacticBoardEditDialogTitle => 'Edit tactic details';

  @override
  String get teamManagementTacticBoardNameLabel => 'Tactic name';

  @override
  String get teamManagementTacticBoardDescriptionLabel => 'Tactic description';

  @override
  String get teamManagementTacticBoardDescriptionHint =>
      'e.g. Occupy the half space, then switch right';

  @override
  String get teamManagementTacticBoardRenameSaveButton => 'Save';

  @override
  String get teamManagementTacticBoardDeleteDialogTitle => 'Delete tactic';

  @override
  String teamManagementTacticBoardDeleteDialogBody(Object title) {
    return 'Delete \"$title\"?';
  }

  @override
  String get teamManagementTacticBoardDeletedFeedback => 'Tactic deleted.';

  @override
  String get teamManagementTacticBoardUndoFeedback => 'Tactic change undone.';

  @override
  String teamManagementTacticBoardPageMeta(int players, int markers) {
    return '$players players · $markers markers';
  }

  @override
  String get teamManagementWorkspaceProfileTab => 'Team profile';

  @override
  String get teamManagementWorkspaceOperationsTab => 'Schedule';

  @override
  String get teamManagementWorkspaceProfileValue => 'Name & tactics';

  @override
  String get teamManagementSavedTeamsTitle => 'Team selector';

  @override
  String get teamManagementSavedTeamsHelper =>
      'Select a saved team to continue operating its roster, tactical principles, and board placement.';

  @override
  String get teamManagementNoTeamsTitle => 'Preparing your first team.';

  @override
  String get teamManagementNoTeamsBody =>
      'Enter a team name and roster, and it will auto-save into a team card here.';

  @override
  String get teamManagementOperationsTitle => 'Operations Summary';

  @override
  String get teamManagementOperationsHelper =>
      'Review next training, roster status, lineup readiness, and competitions at a glance.';

  @override
  String get teamManagementOperationsNextTrainingLabel => 'Next training';

  @override
  String get teamManagementOperationsNextTrainingUnset => 'No training set';

  @override
  String get teamManagementOperationsRosterLabel => 'Roster status';

  @override
  String teamManagementOperationsRosterValue(int total, int managed) {
    return '$total total · $managed managed';
  }

  @override
  String get teamManagementOperationsLineupLabel => 'Lineup';

  @override
  String get teamManagementOperationsCompetitionsLabel => 'Competitions';

  @override
  String teamManagementOperationsCompetitionsValue(int active, int total) {
    return '$active active · $total total';
  }

  @override
  String get teamManagementOperationsScheduleTitle =>
      'Schedule and competitions';

  @override
  String get teamManagementOperationsScheduleHelper =>
      'Organize training days, uniforms, and competitions in the schedule section.';

  @override
  String get teamManagementOperationsOpenScheduleButton => 'Edit schedule';

  @override
  String get teamManagementOperationsNoTraining =>
      'No training schedule has been set.';

  @override
  String get teamManagementOperationsUniformLabel => 'Uniforms';

  @override
  String get teamManagementOperationsCompetitionTitle => 'Competitions';

  @override
  String get teamManagementOperationsNoCompetitions =>
      'Create leagues or tournaments in competition management to show their status here.';

  @override
  String get teamManagementNewTeamButton => 'New team';

  @override
  String get teamManagementBasicsTitle => 'Team profile';

  @override
  String get teamManagementBasicsHelper =>
      'Manage the team name used across the roster.';

  @override
  String get teamManagementTeamNameLabel => 'Team name';

  @override
  String get teamManagementTeamNameHint => 'e.g. Our U15';

  @override
  String get teamManagementStrategyLabel => 'Tactical notes';

  @override
  String get teamManagementStrategyHint =>
      'e.g. Pressing trigger, wide switch rule, defensive block standard';

  @override
  String get teamManagementFormationTitle => 'Pro tactics board';

  @override
  String get teamManagementFormationHelper =>
      'Place players freely and organize movement lines, press lines, and space zones on a wider board.';

  @override
  String get teamManagementFormationLabel => 'Formation';

  @override
  String teamManagementFormationSpotLabel(Object spot) {
    return '$spot';
  }

  @override
  String get teamManagementSelectPositionPrompt =>
      'Select a position on the pitch.';

  @override
  String teamManagementSelectedPosition(Object position) {
    return 'Assign $position';
  }

  @override
  String get teamManagementAssignedPlayerLabel => 'Assigned player';

  @override
  String get teamManagementUnassignedPlayer => 'Unassigned';

  @override
  String get teamManagementPlayersTitle => 'Roster';

  @override
  String get teamManagementPlayerSearchTooltip => 'Search players';

  @override
  String get teamManagementPlayerSearchCloseTooltip => 'Close search';

  @override
  String get teamManagementPlayerSearchHint =>
      'Search by name, number, or grade';

  @override
  String get teamManagementPlayerFilterTooltip => 'Filter player status';

  @override
  String get teamManagementPlayerFilterEmptyTitle =>
      'No players match these filters.';

  @override
  String get teamManagementPlayerFilterEmptyBody =>
      'Clear the search or status filter and try again.';

  @override
  String get teamManagementRosterSummaryAll => 'All';

  @override
  String get teamManagementRosterSummaryReady => 'Ready';

  @override
  String get teamManagementRosterSummaryWatch => 'Watch';

  @override
  String get teamManagementRosterSummaryRest => 'Rest';

  @override
  String get teamManagementPlayersHelper =>
      'Manage number, position, preferred foot, condition, and notes as roster cards.';

  @override
  String get teamManagementPlayerSectionBoardHelper =>
      'Build lineups, movement lines, pressing lines, and space zones directly on the board.';

  @override
  String get teamManagementMatchSectionTitle => 'Match management';

  @override
  String get teamManagementMatchSectionHelper =>
      'Run match recording, record review, stats, and club schedule from one place. Use the title action for competition management.';

  @override
  String get teamManagementRosterBoardTitle => 'Squad board';

  @override
  String get teamManagementRosterBoardHelper =>
      'Review player status and board placement by position.';

  @override
  String teamManagementRoleGroupCount(Object role, int count) {
    return '$role · $count player(s)';
  }

  @override
  String get teamManagementPlayerNameLabel => 'Player name';

  @override
  String get teamManagementPlayerNameHint => 'e.g. Minjun Kim';

  @override
  String get teamManagementPlayerNumberLabel => 'No.';

  @override
  String get teamManagementPlayerNumberHint => '10';

  @override
  String get teamManagementPlayerRegistrationTitle => 'Register player';

  @override
  String get teamManagementPlayerEditTitle => 'Edit player';

  @override
  String get teamManagementRegisterPlayerButton => 'Register player';

  @override
  String get teamManagementPlayerImageTitle => 'Player image';

  @override
  String get teamManagementPlayerImageEmptyTitle => 'Player photo';

  @override
  String get teamManagementPlayerImageSelectButton => 'Choose photo';

  @override
  String get teamManagementPlayerImageReplaceButton => 'Change photo';

  @override
  String get teamManagementPlayerImageRemoveButton => 'Remove photo';

  @override
  String get teamManagementPlayerImagePickFailed =>
      'Could not load the image. Please try another photo.';

  @override
  String get teamManagementPlayerBasicInfoTitle => 'Basic info';

  @override
  String get teamManagementPlayerGradeLabel => 'Grade';

  @override
  String get teamManagementPlayerGradeHint => 'e.g. Grade 5';

  @override
  String get teamManagementPlayerGradeUnset => 'No grade';

  @override
  String teamManagementPlayerElementaryGradeOption(int grade) {
    return 'Elementary grade $grade';
  }

  @override
  String teamManagementPlayerMiddleGradeOption(int grade) {
    return 'Middle school grade $grade';
  }

  @override
  String teamManagementPlayerHighGradeOption(int grade) {
    return 'High school grade $grade';
  }

  @override
  String get teamManagementPlayerBodySizeTitle => 'Body size';

  @override
  String get teamManagementPlayerBodySizeUnset => 'Not set';

  @override
  String get teamManagementPlayerHeightLabel => 'Height';

  @override
  String get teamManagementPlayerHeightUnit => 'cm';

  @override
  String get teamManagementPlayerWeightLabel => 'Weight';

  @override
  String get teamManagementPlayerWeightUnit => 'kg';

  @override
  String get teamManagementPlayerStatusTitle => 'Status info';

  @override
  String get teamManagementPlayerNumberEmpty => 'No number';

  @override
  String teamManagementPlayerNumberPreview(Object number) {
    return 'No. $number';
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
  String get teamManagementPlayerRoleLabel => 'Default position';

  @override
  String get teamManagementPlayerPositionLabel => 'Detailed position';

  @override
  String get teamManagementPositionGoalkeeper => 'GK · Goalkeeper';

  @override
  String get teamManagementPositionLeftBack => 'LB · Left back';

  @override
  String get teamManagementPositionCenterBack => 'CB · Center back';

  @override
  String get teamManagementPositionRightBack => 'RB · Right back';

  @override
  String get teamManagementPositionDefensiveMidfielder =>
      'DM · Defensive midfielder';

  @override
  String get teamManagementPositionLeftMidfielder => 'LM · Left midfielder';

  @override
  String get teamManagementPositionCentralMidfielder =>
      'CM · Central midfielder';

  @override
  String get teamManagementPositionRightMidfielder => 'RM · Right midfielder';

  @override
  String get teamManagementPositionAttackingMidfielder =>
      'AM · Attacking midfielder';

  @override
  String get teamManagementPositionLeftWinger => 'LW · Left winger';

  @override
  String get teamManagementPositionStriker => 'ST · Striker';

  @override
  String get teamManagementPositionRightWinger => 'RW · Right winger';

  @override
  String get teamManagementPlayerFootLabel => 'Preferred foot';

  @override
  String get teamManagementPlayerFootRight => 'Right';

  @override
  String get teamManagementPlayerFootLeft => 'Left';

  @override
  String get teamManagementPlayerFootBoth => 'Both';

  @override
  String get teamManagementPlayerConditionLabel => 'Condition';

  @override
  String get teamManagementPlayerConditionReady => 'Ready';

  @override
  String get teamManagementPlayerConditionWatch => 'Manage';

  @override
  String get teamManagementPlayerConditionRest => 'Rest advised';

  @override
  String get teamManagementPlayerNoteLabel => 'Player note';

  @override
  String get teamManagementPlayerNoteHint =>
      'e.g. Strong left foot, quick pressing transition, monitor knee load';

  @override
  String get teamManagementAddPlayerButton => 'Register player';

  @override
  String get teamManagementUpdatePlayerButton => 'Save changes';

  @override
  String get teamManagementCancelPlayerEditButton => 'Cancel edit';

  @override
  String get teamManagementEditPlayerButton => 'Edit';

  @override
  String get teamManagementNoPlayersTitle => 'No players registered.';

  @override
  String get teamManagementNoPlayersBody =>
      'Add players to drag them directly onto the pitch board.';

  @override
  String teamManagementPlayerMeta(Object role, int count) {
    return '$role · $count board placement(s)';
  }

  @override
  String teamManagementPlayerDetailMeta(
      Object role, Object foot, Object condition, int count) {
    return '$role · $foot · $condition · $count placed';
  }

  @override
  String teamManagementRosterPlacementCount(int count) {
    return 'Board $count';
  }

  @override
  String get teamManagementRosterNoPlacement => 'Not on board';

  @override
  String teamManagementRosterReadyCount(int count) {
    return 'Ready $count';
  }

  @override
  String teamManagementRosterManagedCount(int count) {
    return 'Managed $count';
  }

  @override
  String get teamManagementPlayerTrayTitle => 'Players to drag';

  @override
  String get teamManagementPlayerTrayEmpty =>
      'Register players first, then drag them from here directly onto the pitch.';

  @override
  String get teamManagementBoardMovePlayersMode => 'Place players';

  @override
  String get teamManagementBoardDrawMode => 'Board marker';

  @override
  String get teamManagementBoardMovementMode => 'Movement';

  @override
  String get teamManagementBoardPressMode => 'Press line';

  @override
  String get teamManagementBoardZoneMode => 'Space zone';

  @override
  String get teamManagementBoardClearLinesButton => 'Clear lines';

  @override
  String get teamManagementBoardClearMarkersButton => 'Clear markers';

  @override
  String get teamManagementBoardDeleteSelectedMarkerButton => 'Delete selected';

  @override
  String get teamManagementBoardLandscapeButton => 'Landscape';

  @override
  String get teamManagementBoardPortraitButton => 'Portrait';

  @override
  String get teamManagementBoardPlacementLabel => 'Board placement';

  @override
  String get teamManagementBoardMarkerLabel => 'Tactical markers';

  @override
  String teamManagementBoardPlacementValue(int placed, int total) {
    return '$placed/$total placed';
  }

  @override
  String teamManagementTacticLinesCount(int count) {
    return '$count marker(s)';
  }

  @override
  String get teamManagementFormationDropHint =>
      'In player placement mode, drag players already on the board to adjust their exact position. Use landscape mode when you need more drawing space.';

  @override
  String get teamManagementRemovePlayerButton => 'Remove';

  @override
  String get teamManagementDeleteTeamButton => 'Delete team';

  @override
  String get teamManagementSaveTeamButton => 'Save team';

  @override
  String get teamManagementSaveHint =>
      'Your team roster, tactics, and board placement auto-save as you edit and appear in the Team Management snapshot.';

  @override
  String get teamManagementAutoSaveReady => 'Auto-save';

  @override
  String get teamManagementAutoSavePending => 'Pending';

  @override
  String get teamManagementAutoSaveSaving => 'Saving';

  @override
  String get teamManagementAutoSaveSaved => 'Saved';

  @override
  String get teamManagementAutoSaveNeedsName => 'Name needed';

  @override
  String get teamManagementNameRequired => 'Enter a team name.';

  @override
  String get teamManagementPlayerRequired => 'Enter a player name.';

  @override
  String get teamManagementSavedFeedback => 'Team details saved.';

  @override
  String get teamManagementDeletedFeedback => 'Team deleted.';

  @override
  String get teamManagementRoleGoalkeeper => 'Goalkeeper';

  @override
  String get teamManagementRoleDefender => 'Defender';

  @override
  String get teamManagementRoleMidfielder => 'Midfielder';

  @override
  String get teamManagementRoleForward => 'Forward';

  @override
  String teamManagementLineupFilled(int filled, int total) {
    return '$filled/$total assigned';
  }

  @override
  String teamManagementPlayerCount(int count) {
    return '$count player(s)';
  }

  @override
  String get baseballMatchHitsLabel => 'Hits';

  @override
  String get baseballMatchRbisLabel => 'RBIs';

  @override
  String get baseballMatchRunsLabel => 'Runs';

  @override
  String get baseballMatchDefensivePlaysLabel => 'Defensive plays';

  @override
  String get basketballMatchPointsLabel => 'Points';

  @override
  String get basketballMatchAssistsLabel => 'Assists';

  @override
  String get basketballMatchReboundsLabel => 'Rebounds';

  @override
  String get basketballMatchStealsLabel => 'Steals';

  @override
  String get tennisMatchGamesWonLabel => 'Games won';

  @override
  String get tennisMatchAcesLabel => 'Aces';

  @override
  String get tennisMatchFirstServesInLabel => 'First serves in';

  @override
  String get tennisMatchBreakPointsWonLabel => 'Break points won';

  @override
  String get calendarMatchXpSourceLabel => 'Match record';

  @override
  String get matchSavedFeedback => 'Match record saved.';

  @override
  String get matchUpdatedFeedback => 'Match record updated.';

  @override
  String matchSavedWithXpFeedback(int count) {
    return 'Match saved +$count XP';
  }

  @override
  String get trainingSketchControlsPanel => 'Tools and selection';

  @override
  String get trainingSketchTacticalOverlay => 'Show tactical zones';

  @override
  String get trainingSketchPlayTooltip => 'Play';

  @override
  String get trainingSketchPdfExportTooltip => 'Download sketch PDF';

  @override
  String get trainingSketchPdfExportedSnack => 'Sketch PDF is ready.';

  @override
  String get trainingSketchPdfExportFailedSnack =>
      'Could not create the sketch PDF.';

  @override
  String get trainingSketchVideoExportTooltip => 'Create motion video';

  @override
  String get trainingSketchVideoExportedSnack =>
      'Sketch motion video is ready.';

  @override
  String get trainingSketchVideoExportFailedSnack =>
      'Could not create the sketch motion video.';

  @override
  String get trainingSketchVideoExportUnavailableSnack =>
      'Motion video export is not supported on this device.';

  @override
  String get trainingSketchLandscapeModeTooltip => 'Landscape mode';

  @override
  String get trainingSketchPortraitModeTooltip => 'Portrait mode';

  @override
  String get trainingSketchPlaybackSpeedTooltip => 'Playback speed';

  @override
  String get trainingSketchAddSketchTooltip => 'Add sketch';

  @override
  String get trainingSketchCopySketchTooltip => 'Copy from another sketch';

  @override
  String get trainingSketchDeleteSketchTooltip => 'Delete sketch';

  @override
  String get trainingSketchImportSketchTooltip => 'Import previous sketch';

  @override
  String get trainingSketchRenameSketchTooltip => 'Rename sketch';

  @override
  String get trainingSketchBoardNameLabel => 'Board name';

  @override
  String get trainingSketchBoardNameHint => 'e.g. Pass warm-up';

  @override
  String get trainingSketchMemoLabel => 'Training sketch note';

  @override
  String get trainingSketchMemoHint =>
      'e.g. Two-touch dribble between cones then pass';

  @override
  String get trainingSketchVoiceInputTooltip => 'Voice input';

  @override
  String get trainingSketchConeButton => 'Cone';

  @override
  String get trainingSketchLowHurdleButton => 'Low hurdle';

  @override
  String get trainingSketchPlayerButton => 'Player';

  @override
  String get trainingSketchBallButton => 'Ball';

  @override
  String get trainingSketchLadderButton => 'Ladder';

  @override
  String get trainingSketchTargetButton => 'Target';

  @override
  String get trainingSketchBaseButton => 'Base';

  @override
  String get trainingSketchBasketButton => 'Hoop';

  @override
  String get trainingSketchPenButton => 'Pen';

  @override
  String get trainingSketchAddElementMenuButton => 'Add item';

  @override
  String get trainingSketchClearInkButton => 'Clear ink';

  @override
  String get trainingSketchResetButton => 'Clear';

  @override
  String get trainingSketchPenModeHint =>
      'Pen mode: drag on the board to draw.';

  @override
  String get trainingSketchPenColorLabel => 'Pen color';

  @override
  String get trainingSketchQuickStart =>
      'Quick start: Select a player, tap an action, then tap the target player or space.';

  @override
  String get trainingSketchNextActionButton => 'Add next action';

  @override
  String trainingSketchPlayerFlowTitle(int index) {
    return 'Player $index flow';
  }

  @override
  String get trainingSketchPlayerFlowWithBall => 'Has ball';

  @override
  String get trainingSketchPlayerFlowWithoutBall => 'No ball';

  @override
  String trainingSketchPlayerFlowNextStageChip(int stage) {
    return 'Next stage $stage';
  }

  @override
  String get trainingSketchPlayerFlowHint =>
      'Choose the player\'s next action and the stage and ball movement will connect automatically.';

  @override
  String get trainingSketchPlayerFlowPassSection => 'Connect to teammate';

  @override
  String get trainingSketchPlayerFlowBallSection => 'Ball actions';

  @override
  String get trainingSketchPlayerFlowMoveSection => 'Movement';

  @override
  String get trainingSketchGlobalStagesTitle => 'Overall stages';

  @override
  String get trainingSketchGlobalStagesHint =>
      'Build the board as one sequence, and add several actions to the same stage when they should happen together.';

  @override
  String get trainingSketchActionTimelineTitle => 'All actions';

  @override
  String get trainingSketchActionTimelineEmpty =>
      'No actions yet. Select a player to add the next action.';

  @override
  String get trainingSketchReorderStageTooltip => 'Reorder stage';

  @override
  String get trainingSketchReorderActionTooltip => 'Reorder action';

  @override
  String get trainingSketchRunWithPreviousTooltip => 'Run with previous action';

  @override
  String get trainingSketchRunAfterPreviousTooltip =>
      'Run after previous action';

  @override
  String get trainingSketchDeleteActionTooltip => 'Delete action';

  @override
  String get trainingSketchGlobalStagesEmpty =>
      'No stages yet. The first action starts as stage 1.';

  @override
  String trainingSketchGlobalStageChip(int stage, int count) {
    return 'Stage $stage · $count actions';
  }

  @override
  String get trainingSketchStageActionSelectedLabel => 'Selected';

  @override
  String get trainingSketchInsertActionAfterTooltip =>
      'Insert action after this';

  @override
  String get trainingSketchStageActionUnknownItem => 'Item';

  @override
  String trainingSketchStageActionPlayerMove(Object actor) {
    return '$actor moves';
  }

  @override
  String trainingSketchStageActionPlayerStay(Object actor) {
    return '$actor stays in place';
  }

  @override
  String trainingSketchStageActionBallMove(Object actor) {
    return '$actor moves the ball';
  }

  @override
  String trainingSketchStageActionBallPickup(Object actor) {
    return '$actor gains the ball';
  }

  @override
  String trainingSketchStageActionBallToTarget(Object actor, Object target) {
    return '$actor moves the ball to $target';
  }

  @override
  String trainingSketchStageActionUnownedBallMove(Object ball) {
    return '$ball moves';
  }

  @override
  String trainingSketchAddSameStageButton(int stage) {
    return 'Add together in stage $stage';
  }

  @override
  String trainingSketchAddNextStageButton(int stage) {
    return 'Create new stage $stage';
  }

  @override
  String trainingSketchRegisteredNextGlobalStageHint(int stage) {
    return 'Editing overall stage $stage.';
  }

  @override
  String trainingSketchBallPossessionRequiredSnack(Object player) {
    return '$player does not have the ball. Have them receive a pass first or select the ball they own.';
  }

  @override
  String get trainingSketchBallOwnershipTitle => 'Ball ownership';

  @override
  String trainingSketchBallOwnedBy(Object ball, Object player) {
    return '$ball: owned by $player';
  }

  @override
  String trainingSketchBallMovingToTarget(
      Object ball, Object actor, Object target) {
    return '$ball: moving from $actor to $target';
  }

  @override
  String trainingSketchBallUnowned(Object ball) {
    return '$ball: no owner';
  }

  @override
  String get trainingSketchFlowReviewTitle => 'Flow review';

  @override
  String get trainingSketchFlowReviewOk =>
      'Ball ownership and action links look natural.';

  @override
  String trainingSketchFlowWarningBallWithoutActor(Object ball) {
    return '$ball moves without a player.';
  }

  @override
  String trainingSketchFlowWarningWrongOwner(
      Object ball, Object owner, Object actor) {
    return '$ball is owned by $owner, but $actor uses it.';
  }

  @override
  String trainingSketchFlowWarningUnownedBallUsed(Object ball, Object actor) {
    return '$ball has no owner, but $actor uses it.';
  }

  @override
  String trainingSketchFlowWarningMultipleActors(Object ball, int stage) {
    return 'Multiple players use $ball in stage $stage.';
  }

  @override
  String trainingSketchFlowWarningInvalidTarget(Object ball, Object target) {
    return '$ball targets a non-player ($target).';
  }

  @override
  String get trainingSketchSelectedItemTitle => 'Selected item';

  @override
  String get trainingSketchAssignColorLabel => 'Assign color';

  @override
  String get trainingSketchPlayerStagesTitle => 'Player stages';

  @override
  String get trainingSketchPlayerStagesEmpty =>
      'No stages are registered for this player yet.';

  @override
  String trainingSketchPlayerStageChip(int stage, int count) {
    return 'Stage $stage · $count actions';
  }

  @override
  String trainingSketchRegisterNextPlayerStageButton(int stage) {
    return 'Register stage $stage';
  }

  @override
  String trainingSketchRegisteredNextPlayerStageHint(int stage) {
    return 'The next action will be created as stage $stage.';
  }

  @override
  String get trainingSketchDrawRouteFirst => 'Draw or select a route first.';

  @override
  String get trainingSketchAddPlayerFirst => 'Add a player icon first.';

  @override
  String get trainingSketchAddBallFirst => 'Add a ball icon first.';

  @override
  String get trainingSketchRoutesButton => 'Actions';

  @override
  String get trainingSketchLinkRoutesInOrderButton => 'Chain all in order';

  @override
  String get trainingSketchLinkRoutesInOrderSnack =>
      'Routes now start one by one in the order they were drawn.';

  @override
  String get trainingSketchLinkRoutesNeedTwoSnack =>
      'Add at least two routes to chain them.';

  @override
  String get trainingSketchCreatedSnack => 'Training sketch created.';

  @override
  String get trainingSketchSavedSnack => 'Training sketch saved.';

  @override
  String get trainingSketchPreviousCopiedSnack => 'Previous sketch copied.';

  @override
  String get trainingSketchDuplicatedSnack => 'Sketch duplicated.';

  @override
  String get trainingSketchCopiedFromAnotherSnack =>
      'Sketch copied from another one.';

  @override
  String get trainingBoardListTitle => 'Training sketch list';

  @override
  String get trainingBoardTitleDialogTitle => 'Training sketch title';

  @override
  String get trainingBoardTitleHint => 'e.g. Pass warm-up';

  @override
  String get trainingBoardRenamedSnack => 'Board renamed.';

  @override
  String get trainingBoardRenameUndoneSnack => 'Rename undone.';

  @override
  String get trainingBoardNoCopySourceSnack => 'No training sketch to copy.';

  @override
  String trainingBoardDefaultCopyTitle(Object title) {
    return '$title Copy';
  }

  @override
  String get trainingBoardDeleteTitle => 'Delete training sketch';

  @override
  String trainingBoardDeleteConfirm(Object title) {
    return 'Delete \"$title\"?';
  }

  @override
  String get trainingBoardDeletedSnack => 'Board deleted.';

  @override
  String get trainingBoardDeleteUndoneSnack => 'Delete undone.';

  @override
  String get trainingBoardDefaultTitle => 'Training Board';

  @override
  String get trainingBoardSearchCloseTooltip => 'Close search';

  @override
  String get trainingBoardSearchTooltip => 'Search boards';

  @override
  String get trainingBoardSortTooltip => 'Sort';

  @override
  String get trainingBoardSortRecentlyUpdated => 'Recently updated';

  @override
  String get trainingBoardSortTrainingDate => 'Training date';

  @override
  String get trainingBoardSortName => 'Name A-Z';

  @override
  String get trainingBoardAddTooltip => 'Add training sketch';

  @override
  String get trainingBoardCreateNewAction => 'Create new sketch';

  @override
  String get trainingBoardCopyPreviousAction => 'Copy previous sketch';

  @override
  String get trainingBoardDoneAction => 'Done';

  @override
  String get trainingBoardEmptyTitle => 'No boards yet.';

  @override
  String get trainingBoardEmptySubtitle =>
      'Create one directly from a training note.';

  @override
  String get trainingBoardBackToNotes => 'Back to notes';

  @override
  String get trainingBoardSearchHint => 'Search board';

  @override
  String get trainingBoardNoSearchResults => 'No search results.';

  @override
  String trainingBoardListItemSubtitle(Object count, Object date) {
    return '$count items · Training date $date';
  }

  @override
  String get trainingBoardRenameAction => 'Rename';

  @override
  String get trainingBoardDuplicateAction => 'Duplicate';

  @override
  String get trainingSketchAutoStagesButton => 'Auto stages';

  @override
  String get trainingSketchAutoStagesSnack =>
      'Routes were split into stages starting from stage 1.';

  @override
  String get trainingSketchAutoStagesNeedTwoSnack =>
      'Add at least two routes to split stages.';

  @override
  String get trainingSketchRouteStageTitle => 'Movement stage';

  @override
  String trainingSketchRouteStageChip(Object stage) {
    return 'Stage $stage';
  }

  @override
  String get trainingSketchSelectRouteForStageHint =>
      'Select a player or ball to change its route stage.';

  @override
  String get trainingSketchPreviousStageButton => 'Previous stage';

  @override
  String get trainingSketchNextStageButton => 'Next stage';

  @override
  String get trainingSketchRouteAfterBallButton => 'After ball';

  @override
  String get trainingSketchFinishRouteButton => 'Finish route';

  @override
  String get trainingSketchUndoLastRoutePointButton => 'Undo last point';

  @override
  String get trainingSketchClearAllRoutesButton => 'Clear all action lines';

  @override
  String get trainingSketchPlayerRoutesTitle => 'Player actions';

  @override
  String get trainingSketchBallRoutesTitle => 'Ball actions';

  @override
  String get trainingSketchRoutesEmpty => 'No action lines yet for this type.';

  @override
  String get trainingSketchExtendRouteButton => 'Extend from end';

  @override
  String get trainingSketchReverseRouteButton => 'Reverse direction';

  @override
  String get trainingSketchRedrawRouteButton => 'Redraw selected';

  @override
  String get trainingSketchDeleteRouteButton => 'Delete selected';

  @override
  String get trainingSketchEditStageActionTooltip => 'Edit stage action';

  @override
  String get trainingSketchAddSameStageActionTooltip =>
      'Add player action to this stage';

  @override
  String get trainingSketchAddNextStageActionTooltip =>
      'Add player action to the next stage';

  @override
  String get trainingSketchDeleteStageActionTooltip => 'Delete stage action';

  @override
  String trainingSketchPlayerRouteChip(int index) {
    return 'Player $index';
  }

  @override
  String trainingSketchBallRouteChip(int index) {
    return 'Ball $index';
  }

  @override
  String get trainingSketchRouteReplaceHint =>
      'Tap the destination, then finish the route to replace the selected route.';

  @override
  String get trainingSketchSelectedPlayerRouteHint =>
      'Tap a destination, then finish the route. You can still drag to draw.';

  @override
  String get trainingSketchSelectedBallRouteHint =>
      'Tap a pass destination, then finish the route. You can still drag to draw.';

  @override
  String get trainingSketchPlayerRouteHint =>
      'Select a player or tap the board to start, then tap a destination and finish.';

  @override
  String get trainingSketchBallRouteHint =>
      'Select a ball or tap the board to start, then tap a pass destination and finish.';

  @override
  String get trainingSketchLinkPlayerHint =>
      'Tap an action, then tap a destination or target player. Actions that need a ball create one beside the player automatically.';

  @override
  String get trainingSketchLinkBallHint =>
      'Use this only when you want to move the ball by itself. Player actions create the needed ball movement together.';

  @override
  String trainingSketchActionTargetHint(Object action) {
    return 'Tap the target or space for $action.';
  }

  @override
  String trainingSketchPassTargetHint(Object action) {
    return 'Tap the player to receive $action.';
  }

  @override
  String get trainingSketchActionTargetCancelButton => 'Cancel';

  @override
  String get trainingSketchActionCreatedSnack => 'Action added.';

  @override
  String get trainingSketchSelectedItemActionsTitle => 'Quick actions';

  @override
  String get trainingSketchPlayerActionsTitle => 'Player actions';

  @override
  String get trainingSketchBallActionsTitle => 'Ball actions';

  @override
  String get trainingSketchCreateMoveRouteButton => 'Create move';

  @override
  String get trainingSketchCreatePassRouteButton => 'Create pass';

  @override
  String get trainingSketchQuickMoveButton => 'Move';

  @override
  String get trainingSketchQuickMoveToBallButton => 'Move to ball';

  @override
  String get trainingSketchQuickStayButton => 'Stay';

  @override
  String get trainingSketchMoveThenPassButton => 'Move then pass';

  @override
  String get trainingSketchMoveThenPassReceiverPrompt =>
      'Move point set. Select the player to receive the pass.';

  @override
  String get trainingSketchQuickPassButton => 'Pass';

  @override
  String get trainingSketchQuickPassAndMoveButton => 'Pass then move';

  @override
  String get trainingSketchQuickDribbleButton => 'Dribble';

  @override
  String get trainingSketchQuickReceiveMoveButton => 'Receive and move';

  @override
  String get trainingSketchQuickReturnMoveButton => 'Return';

  @override
  String get trainingSketchQuickOverlapButton => 'Overlap';

  @override
  String get trainingSketchQuickShotButton => 'Shoot';

  @override
  String get trainingSketchQuickCrossButton => 'Cross';

  @override
  String get trainingSketchQuickDriveButton => 'Drive';

  @override
  String get trainingSketchQuickCutButton => 'Cut';

  @override
  String get trainingSketchQuickScreenButton => 'Screen';

  @override
  String get trainingSketchQuickConeTurnButton => 'Circle cone';

  @override
  String get trainingSketchQuickConeJumpButton => 'Jump cone';

  @override
  String get trainingSketchQuickHurdleJumpButton => 'Jump hurdle';

  @override
  String get trainingSketchQuickRunBaseButton => 'Base run';

  @override
  String get trainingSketchQuickFieldingButton => 'Fielding move';

  @override
  String get trainingSketchQuickThrowButton => 'Throw';

  @override
  String get trainingSketchQuickServeButton => 'Serve';

  @override
  String get trainingSketchQuickRallyButton => 'Rally';

  @override
  String get trainingSketchQuickRecoverButton => 'Recover';

  @override
  String trainingSketchPassToPlayerButton(int index) {
    return 'Pass to player $index';
  }

  @override
  String get trainingSketchPassToNewPlayerButton => 'Pass to new player';

  @override
  String trainingSketchPassToSpotButton(Object target, int index) {
    return 'Pass to $target $index';
  }

  @override
  String trainingSketchConeTurnTargetButton(int index) {
    return 'Circle cone $index';
  }

  @override
  String trainingSketchConeJumpTargetButton(int index) {
    return 'Jump cone $index';
  }

  @override
  String trainingSketchHurdleJumpTargetButton(int index) {
    return 'Jump hurdle $index';
  }

  @override
  String trainingSketchThrowToPlayerButton(int index) {
    return 'Throw to player $index';
  }

  @override
  String get trainingSketchThrowToNewPlayerButton => 'Throw to new player';

  @override
  String trainingSketchThrowToSpotButton(Object target, int index) {
    return 'Throw to $target $index';
  }

  @override
  String trainingSketchRallyToPlayerButton(int index) {
    return 'Rally to player $index';
  }

  @override
  String get trainingSketchRallyToNewPlayerButton => 'Rally to new player';

  @override
  String trainingSketchRallyToSpotButton(Object target, int index) {
    return 'Rally to $target $index';
  }

  @override
  String get trainingSketchPlayerRouteLimitReached =>
      'All player action lines are already assigned. Select a player to replace or redraw its action.';

  @override
  String get trainingSketchBallRouteLimitReached =>
      'All ball action lines are already assigned. Select a ball to replace or redraw its action.';

  @override
  String get trainingSketchTemplatePickerTitle => 'Choose template';

  @override
  String get trainingSketchTemplateBlankLabel => 'Blank sketch';

  @override
  String get trainingSketchTemplateBlankDescription =>
      'Start from an empty board';

  @override
  String get trainingSketchTemplatePassWarmupLabel => 'Pass and move triangle';

  @override
  String get trainingSketchTemplatePassWarmupDescription =>
      'Pass, support, and rotate';

  @override
  String get trainingSketchTemplatePassWarmupMethod =>
      'Open the body before receiving and move after every pass';

  @override
  String get trainingSketchTemplateBuildUpLabel => 'Build-out escape';

  @override
  String get trainingSketchTemplateBuildUpDescription =>
      'Goalkeeper, center backs, and the 6';

  @override
  String get trainingSketchTemplateBuildUpMethod =>
      'Draw pressure, find the 6, then release to the far fullback';

  @override
  String get trainingSketchTemplatePressingLabel => '5-second counterpress';

  @override
  String get trainingSketchTemplatePressingDescription =>
      'Immediate pressure and cover after loss';

  @override
  String get trainingSketchTemplatePressingMethod =>
      'Nearest player presses while support players block passing lanes';

  @override
  String get trainingSketchTemplateSetPieceLabel => 'Near-far corner';

  @override
  String get trainingSketchTemplateSetPieceDescription =>
      'Screen, near touch, far-post run';

  @override
  String get trainingSketchTemplateSetPieceMethod =>
      'Use the blocker, flick near-post, then attack the far post';

  @override
  String get trainingSketchTemplateRondoLabel => '5v2 rondo switch';

  @override
  String get trainingSketchTemplateRondoDescription =>
      'Split pass and support rotation with a joker';

  @override
  String get trainingSketchTemplateRondoMethod =>
      'Break the pressure line, then rotate the support positions';

  @override
  String get trainingSketchTemplateFinishingLabel => 'Cutback finishing';

  @override
  String get trainingSketchTemplateFinishingDescription =>
      'Wide drive, cutback, box arrivals';

  @override
  String get trainingSketchTemplateFinishingMethod =>
      'Attack near post, cutback zone, and far post at the same time';

  @override
  String get trainingSketchTemplateWingCombinationLabel =>
      'Overlap and underlap';

  @override
  String get trainingSketchTemplateWingCombinationDescription =>
      'Wide overload with fullback, winger, and 8';

  @override
  String get trainingSketchTemplateWingCombinationMethod =>
      'Pin inside with the winger, then overlap or underlap for a cutback';

  @override
  String get trainingSketchTemplateTransitionAttackLabel =>
      '6-second counterattack';

  @override
  String get trainingSketchTemplateTransitionAttackDescription =>
      'First pass, depth run, and wide carry';

  @override
  String get trainingSketchTemplateTransitionAttackMethod =>
      'Use the first forward pass before the defense can reset';

  @override
  String get trainingSketchTemplateSwitchPlayLabel => 'Switch of play';

  @override
  String get trainingSketchTemplateSwitchPlayDescription =>
      'Draw pressure, then switch to the far winger';

  @override
  String get trainingSketchTemplateSwitchPlayMethod =>
      'Attract pressure on one side, then use the 6 and center back to switch';

  @override
  String get trainingSketchTemplateDefensiveShiftLabel =>
      'Defensive line shift';

  @override
  String get trainingSketchTemplateDefensiveShiftDescription =>
      'Line slide and cover as the ball moves';

  @override
  String get trainingSketchTemplateDefensiveShiftMethod =>
      'When the ball switches sides, the back four and 6 move together';

  @override
  String get trainingSketchTemplateBaseballThrowingLabel => 'Throwing relay';

  @override
  String get trainingSketchTemplateBaseballThrowingDescription =>
      'Basic catch-and-throw connection';

  @override
  String get trainingSketchTemplateBaseballThrowingMethod =>
      'Receive cleanly and throw quickly to the target';

  @override
  String get trainingSketchTemplateBaseballBattingLabel => 'Hit and run';

  @override
  String get trainingSketchTemplateBaseballBattingDescription =>
      'Batting direction and first-base run';

  @override
  String get trainingSketchTemplateBaseballBattingMethod =>
      'Check contact direction, then sprint through first base';

  @override
  String get trainingSketchTemplateBaseballFieldingLabel => 'Fielding play';

  @override
  String get trainingSketchTemplateBaseballFieldingDescription =>
      'Batted-ball reaction and relay throw';

  @override
  String get trainingSketchTemplateBaseballFieldingMethod =>
      'React, field the ball, and throw accurately to the relay spot';

  @override
  String get trainingSketchTemplateBasketballShootingLabel => 'Shooting spots';

  @override
  String get trainingSketchTemplateBasketballShootingDescription =>
      'Drive path and shot locations';

  @override
  String get trainingSketchTemplateBasketballShootingMethod =>
      'Catch, set the feet, and shoot from the assigned spot';

  @override
  String get trainingSketchTemplateBasketballPassingLabel => 'Pass and cut';

  @override
  String get trainingSketchTemplateBasketballPassingDescription =>
      'Cut timing and pass connection';

  @override
  String get trainingSketchTemplateBasketballPassingMethod =>
      'Time the pass with the cutter\'s movement';

  @override
  String get trainingSketchTemplateBasketballDefenseLabel => 'Defensive slides';

  @override
  String get trainingSketchTemplateBasketballDefenseDescription =>
      'Lateral slide and pressure positions';

  @override
  String get trainingSketchTemplateBasketballDefenseMethod =>
      'Stay in front and repeat controlled lateral slides';

  @override
  String get trainingSketchTemplateTennisServeLabel => 'Serve targets';

  @override
  String get trainingSketchTemplateTennisServeDescription =>
      'Serve direction and recovery position';

  @override
  String get trainingSketchTemplateTennisServeMethod =>
      'Serve to the target, then recover to the middle';

  @override
  String get trainingSketchTemplateTennisRallyLabel => 'Cross-court rally';

  @override
  String get trainingSketchTemplateTennisRallyDescription =>
      'Cross-court rally and recovery';

  @override
  String get trainingSketchTemplateTennisRallyMethod =>
      'Send cross-court and recover to center for the next ball';

  @override
  String get trainingSketchTemplateTennisFootworkLabel => 'Footwork pattern';

  @override
  String get trainingSketchTemplateTennisFootworkDescription =>
      'Split step and side-to-side movement';

  @override
  String get trainingSketchTemplateTennisFootworkMethod =>
      'Split step, move side to side, and recover balance';

  @override
  String get trainingSketchTemplateBallMasteryLabel => 'Ball mastery slalom';

  @override
  String get trainingSketchTemplateBallMasteryDescription =>
      'Slalom dribble, change of direction, and finish';

  @override
  String get trainingSketchTemplateBallMasteryMethod =>
      'Keep the ball in front, change pace at each cone, then finish on target';

  @override
  String get trainingSketchTemplateFirstTouchFinishLabel =>
      'First touch and finish';

  @override
  String get trainingSketchTemplateFirstTouchFinishDescription =>
      'Receive, turn away from pressure, and shoot';

  @override
  String get trainingSketchTemplateFirstTouchFinishMethod =>
      'Receive on the half turn, take the first touch into space, then finish early';

  @override
  String get trainingSketchTemplateOneVOneLabel => '1v1 break and finish';

  @override
  String get trainingSketchTemplateOneVOneDescription =>
      'Attack a defender with a change of speed';

  @override
  String get trainingSketchTemplateOneVOneMethod =>
      'Commit the defender, accelerate past the shoulder, and finish with the next touch';

  @override
  String get trainingSketchTemplateTwoVOneLabel => '2v1 overlap finish';

  @override
  String get trainingSketchTemplateTwoVOneDescription =>
      'Pass, overlap, receive again, and finish';

  @override
  String get trainingSketchTemplateTwoVOneMethod =>
      'Move as the pass travels, draw the defender, and use the return pass into the finish';

  @override
  String get trainingSketchTemplateThirdManLabel => 'Third-player run';

  @override
  String get trainingSketchTemplateThirdManDescription =>
      'Pass, layoff, and a runner beyond the line';

  @override
  String get trainingSketchTemplateThirdManMethod =>
      'Use the link player for one touch and release the third runner into space';

  @override
  String get trainingSketchTemplateCoordinationFinishLabel =>
      'Coordination circuit finish';

  @override
  String get trainingSketchTemplateCoordinationFinishDescription =>
      'Ladder, hurdle, turn, and a ball finish';

  @override
  String get trainingSketchTemplateCoordinationFinishMethod =>
      'Keep posture through the ladder and hurdle, turn tightly, then finish with control';

  @override
  String get trainingSketchTemplateBaseballDoublePlayLabel =>
      'Double-play feed';

  @override
  String get trainingSketchTemplateBaseballDoublePlayDescription =>
      'Field, feed second, pivot, and throw first';

  @override
  String get trainingSketchTemplateBaseballDoublePlayMethod =>
      'Secure the ground ball, make a clean feed, then turn quickly for the throw to first';

  @override
  String get trainingSketchTemplateBaseballBaseRunningLabel =>
      'Extra-base running';

  @override
  String get trainingSketchTemplateBaseballBaseRunningDescription =>
      'Read the hit and run a full base path';

  @override
  String get trainingSketchTemplateBaseballBaseRunningMethod =>
      'Leave hard, round each base under control, and read the relay before advancing';

  @override
  String get trainingSketchTemplateBasketballTransitionLabel =>
      'Three-lane transition';

  @override
  String get trainingSketchTemplateBasketballTransitionDescription =>
      'Advance with two passes and finish at the rim';

  @override
  String get trainingSketchTemplateBasketballTransitionMethod =>
      'Fill the lanes, pass ahead before pressure arrives, and finish at pace';

  @override
  String get trainingSketchTemplateBasketballPickRollLabel =>
      'Pick and roll kick-out';

  @override
  String get trainingSketchTemplateBasketballPickRollDescription =>
      'Screen, drive, kick out, and shoot';

  @override
  String get trainingSketchTemplateBasketballPickRollMethod =>
      'Set the screen with balance, attack the gap, then find the open shooter';

  @override
  String get trainingSketchTemplateTennisReturnRecoverLabel =>
      'Return and recover';

  @override
  String get trainingSketchTemplateTennisReturnRecoverDescription =>
      'Return cross-court and recover for the next ball';

  @override
  String get trainingSketchTemplateTennisReturnRecoverMethod =>
      'Move to the return, send the ball cross-court, then recover through the middle';

  @override
  String get trainingSketchTemplateTennisApproachVolleyLabel =>
      'Approach and volley';

  @override
  String get trainingSketchTemplateTennisApproachVolleyDescription =>
      'Approach through the court and finish at the net';

  @override
  String get trainingSketchTemplateTennisApproachVolleyMethod =>
      'Drive the approach into space, close with balanced steps, and play the volley forward';

  @override
  String get trainingSketchTemplateGalleryAction => 'View templates';

  @override
  String get trainingSketchTemplateGalleryTitle => 'Training template gallery';

  @override
  String get trainingSketchTemplateGallerySubtitle =>
      'Preview movement lines and notes before creating a sketch.';

  @override
  String get challengeTitle => 'Challenge';

  @override
  String get challengeRewardAction => 'Rewards';

  @override
  String get challengeHistoryAction => 'History';

  @override
  String get challengeListTitle => 'Active challenges';

  @override
  String challengeListBody(int count) {
    return '$count challenges are ready or in progress. Prepared challenges and today\'s rounds are grouped here.';
  }

  @override
  String get challengeCreateTitle => 'Create challenge';

  @override
  String get challengeCreateAction => 'Create challenge';

  @override
  String get challengeDetailTitle => 'Challenge detail';

  @override
  String get challengeDetailAction => 'Details';

  @override
  String get challengeEditTitle => 'Edit challenge';

  @override
  String get challengeEditAction => 'Edit';

  @override
  String get challengeEditBody =>
      'Adjust the duration, round frequency, and mission setup before the challenge starts.';

  @override
  String get challengeUpdateAction => 'Save changes';

  @override
  String get challengeUpdateSnack => 'Challenge updated.';

  @override
  String get challengeEditUnavailableSnack =>
      'Challenges with started records cannot be edited.';

  @override
  String get challengeDeletePendingAction => 'Delete';

  @override
  String get challengeDeletePendingTitle => 'Delete challenge';

  @override
  String get challengeDeletePendingBody =>
      'This challenge has not started yet. Delete this challenge?';

  @override
  String get challengeDeletePendingConfirm => 'Delete';

  @override
  String get challengeDeletePendingSnack => 'Challenge deleted.';

  @override
  String get challengeDeletePendingUnavailableSnack =>
      'Challenges with started records cannot be deleted.';

  @override
  String get challengeStartHeroTitle => 'Rinzy\'s Challenge Mode';

  @override
  String get challengeStartHeroBody =>
      'Choose a duration and mission amounts, then prepare the challenge. When ready, the player can start from today.';

  @override
  String get challengeLatestComplete => 'Latest challenge complete';

  @override
  String get challengeSelectTitle => 'Choose a challenge';

  @override
  String challengeActiveCardTitle(Object title) {
    return '$title in progress';
  }

  @override
  String get challengeCreateAnotherTitle => 'Add another challenge';

  @override
  String get challengeDurationSelectTitle => '1. Choose duration';

  @override
  String get challengeCadenceSelectTitle => 'Round frequency';

  @override
  String get challengeCadenceDaily => 'Every day';

  @override
  String get challengeCadenceEveryTwoDays => 'Every 2 days';

  @override
  String get challengeCadenceWeekly => 'Once a week';

  @override
  String challengeCadenceEveryNDays(int days) {
    return 'Every $days days';
  }

  @override
  String get challengeTemplateStarterTitle => '3-day Challenge';

  @override
  String get challengeTemplateStarterDescription =>
      'Learn the challenge rhythm with a short focused run.';

  @override
  String get challengeTemplateWeeklyTitle => '7-day Challenge';

  @override
  String get challengeTemplateWeeklyDescription =>
      'Keep a daily routine for one full week.';

  @override
  String get challengeTemplateFocusTitle => '14-day Challenge';

  @override
  String get challengeTemplateFocusDescription =>
      'Build consistency across two steady weeks.';

  @override
  String get challengeDifficultySprout => 'Sprout';

  @override
  String get challengeDifficultyBoost => 'Grow-Up';

  @override
  String get challengeDifficultyStar => 'Star';

  @override
  String get challengeTrainingLevelTitle => '2. Choose level';

  @override
  String get challengeTrainingLevelRookieTitle => 'Rookie level';

  @override
  String get challengeTrainingLevelRookieDescription =>
      'A lighter target for younger players or players just starting soccer.';

  @override
  String get challengeTrainingLevelGrowthTitle => 'Grow-Up level';

  @override
  String get challengeTrainingLevelGrowthDescription =>
      'A steady target for players with basic rhythm and regular practice.';

  @override
  String get challengeTrainingLevelAceTitle => 'Ace level';

  @override
  String get challengeTrainingLevelAceDescription =>
      'A challenging target for older players with more soccer experience.';

  @override
  String get challengeRecommendedLevelBadge => 'Recommended';

  @override
  String get challengeSkillSelectTitle => '2. Choose missions';

  @override
  String get challengeSkillSelectSubtitle =>
      'Choose training programs, auxiliary drills, and meal missions for this challenge, then adjust each daily target.';

  @override
  String get challengeMissionOtherSectionTitle => 'Extra missions';

  @override
  String get challengeMissionTargetsTitle => 'Mission targets';

  @override
  String get challengeMissionTargetsSubtitle =>
      'Choose the daily amount for each selected mission.';

  @override
  String get challengeTrainingProgramLinkTitle => 'Edit training programs';

  @override
  String get challengeTrainingProgramLinkBody =>
      'Open Settings defaults to edit the training program options.';

  @override
  String get challengeTrainingProgramLinkAction => 'Open';

  @override
  String get challengeTrainingProgramMissionLabel => 'Training programs';

  @override
  String get challengeMissionSummaryTitle => 'Selected missions';

  @override
  String challengeMissionProgramSummary(Object label, Object programs) {
    return '$label: $programs';
  }

  @override
  String challengeRiceBowlsOption(Object bowls) {
    return '$bowls bowls';
  }

  @override
  String get challengeSkillDribble => 'Dribble';

  @override
  String get challengeSkillSpeedRun => 'Speed run';

  @override
  String get challengeSkillJumpRope => 'Jump rope';

  @override
  String get challengeSkillLifting => 'Lifting';

  @override
  String get challengeSkillPassing => 'Passing';

  @override
  String get challengeSkillShooting => 'Shooting';

  @override
  String get challengeSkillFirstTouch => 'First touch';

  @override
  String get challengeSkillDefense => 'Defense';

  @override
  String challengeLevelTrainingTargetLabel(int minutes) {
    return 'Total training $minutes min';
  }

  @override
  String challengeLevelJumpRopeTargetLabel(int minutes) {
    return 'Jump rope $minutes min';
  }

  @override
  String challengeLevelLiftingTargetLabel(int minutes) {
    return 'Lifting $minutes min';
  }

  @override
  String challengeDaysLabel(int days) {
    return '$days days';
  }

  @override
  String challengeRewardXp(int xp) {
    return '+$xp XP';
  }

  @override
  String challengeRoundXpLabel(int xp) {
    return 'Round +$xp XP';
  }

  @override
  String challengeStreakBonusLabel(int xp) {
    return 'Streak bonus +$xp XP';
  }

  @override
  String challengeActiveLevelPill(Object level) {
    return 'Level: $level';
  }

  @override
  String get challengeInfoStatusLabel => 'Status';

  @override
  String get challengeInfoLevelLabel => 'Level';

  @override
  String get challengeInfoRoundXpLabel => 'Round reward';

  @override
  String get challengeInfoPotentialXpLabel => 'Challenge reward';

  @override
  String get challengeInfoPeriodLabel => 'Period';

  @override
  String get challengeInfoRoundProgressLabel => 'Round progress';

  @override
  String challengePotentialXpPill(int xp) {
    return 'Potential XP +$xp';
  }

  @override
  String challengeCompletionBonusLabel(int xp) {
    return 'Finish bonus +$xp XP';
  }

  @override
  String challengeTotalXpLabel(int xp) {
    return 'Up to +$xp XP';
  }

  @override
  String get challengeRewardPitchTitle => 'A big finish bonus is waiting';

  @override
  String get challengeRewardGiftSectionTitle => 'Gift reward';

  @override
  String get challengeRewardGiftSectionSubtitle =>
      'Write the gift to give when the challenge is finished.';

  @override
  String get challengeRewardGiftInputLabel => 'Finish gift';

  @override
  String get challengeRewardGiftInputHint => 'Example: new football';

  @override
  String challengeRewardGiftPill(Object gift) {
    return 'Gift: $gift';
  }

  @override
  String get challengeRewardGiftPromisedLabel => 'Finish gift';

  @override
  String challengeRewardGiftPromisedBody(Object gift) {
    return 'Finish the challenge to earn this gift: $gift.';
  }

  @override
  String get challengeGiftReceiveTitle => 'Rinzy brought your gift!';

  @override
  String challengeGiftReceiveBody(Object gift) {
    return 'It is time to receive $gift. Rinzy is celebrating the promise you finished.';
  }

  @override
  String get challengeGiftReceiveAction => 'Gift received';

  @override
  String get challengeRewardGuideTitle => 'Challenge rewards';

  @override
  String get challengeRewardGuideBody =>
      'Round rewards grow when rounds are completed consecutively. A finished challenge also adds the finish bonus.';

  @override
  String get challengeRewardGuideNoActive =>
      'No active challenge is running. Start a challenge to see earned and remaining XP.';

  @override
  String get challengeRewardGuideActiveTitle => 'Current challenge';

  @override
  String get challengeRewardGuideTemplatesTitle => 'Reward plans by challenge';

  @override
  String challengeRewardGuideTemplateTitle(Object title) {
    return '$title reward plan';
  }

  @override
  String get challengeRewardGuideHistoryTitle => 'Reward plan';

  @override
  String get challengeRewardGuideBaseRoundLabel => 'Base round';

  @override
  String get challengeRewardGuideStreakBonusLabel => 'Max streak bonus';

  @override
  String get challengeRewardGuideRoundTotalLabel => 'Rounds total';

  @override
  String get challengeRewardGuideFinishBonusLabel => 'Finish bonus';

  @override
  String get challengeRewardGuidePotentialLabel => 'Maximum XP';

  @override
  String get challengeRewardGuideEarnedLabel => 'Earned so far';

  @override
  String get challengeRewardGuideRemainingLabel => 'Remaining';

  @override
  String get challengeRewardGuideRoundsTitle => 'Round rewards';

  @override
  String challengeRewardGuideRoundReward(int round, int xp) {
    return 'Round $round: +$xp XP';
  }

  @override
  String challengeRewardGuideRoundRewardWithBonus(
      int round, int xp, int bonus) {
    return 'Round $round: +$xp XP (streak +$bonus)';
  }

  @override
  String get challengeStartReadyTitle => '3. Save setup';

  @override
  String get challengePrepareAction => 'Prepare challenge';

  @override
  String get challengeStartAction => 'Start challenge';

  @override
  String challengeRoundCount(int completed, int total) {
    return '$completed/$total rounds complete';
  }

  @override
  String challengeMissionCount(int completed, int total) {
    return '$completed/$total missions complete';
  }

  @override
  String challengeProgressPercent(int percent) {
    return '$percent% complete';
  }

  @override
  String challengeTodayRoundTitle(int round) {
    return 'Today · Round $round';
  }

  @override
  String challengeUpcomingRoundTitle(int round) {
    return 'Next · Round $round';
  }

  @override
  String get challengeRoundsTitle => 'Rounds';

  @override
  String challengeRoundTitle(int round) {
    return 'Round $round';
  }

  @override
  String get challengeTrainingLabel => 'Training';

  @override
  String get challengeJumpRopeLabel => 'Jump rope';

  @override
  String get challengeLiftingLabel => 'Lifting';

  @override
  String get challengeMealLabel => 'Meals';

  @override
  String challengeTrainingGoalValue(int current, int target) {
    return '$current/$target min';
  }

  @override
  String challengeMealGoalValue(Object current, Object target) {
    return '$current/$target bowls';
  }

  @override
  String get challengeCompletedBadge => 'Complete';

  @override
  String get challengeReadyBadge => 'Not started';

  @override
  String get challengePendingBadge => 'In progress';

  @override
  String get challengeReadyPeriodLabel =>
      'The schedule starts from the day you begin.';

  @override
  String challengeReadyCardTitle(Object title) {
    return '$title is ready';
  }

  @override
  String get challengeReadyPlayerBody =>
      'Start when you are ready. The round schedule and mission tracking open from the start day.';

  @override
  String get challengeReadyParentBody =>
      'The player can start this from player mode when ready. Before it starts, you can still edit or delete it.';

  @override
  String get challengeReadyStartAction => 'Start now';

  @override
  String challengeCompletedSummary(Object title) {
    return '$title complete';
  }

  @override
  String get challengeRoundDateToday => 'Today';

  @override
  String challengePrepareSnack(Object title) {
    return '$title prepared.';
  }

  @override
  String challengeStartSnack(Object title) {
    return '$title started.';
  }

  @override
  String challengeAwardSnack(int xp) {
    return 'Challenge round complete +$xp XP';
  }

  @override
  String get challengeCompletedSnack => 'Challenge complete.';

  @override
  String challengeFailedSnack(int round) {
    return 'Round $round was missed, so the challenge ended as failed.';
  }

  @override
  String challengeFailureTitle(int round) {
    return 'Round $round stopped here';
  }

  @override
  String get challengeFailureSimpleTitle => 'Rinzy is sad today';

  @override
  String get challengeFailureBody =>
      'Rinzy is sad, but tomorrow\'s round can start stronger.';

  @override
  String get challengeFailureAction => 'Check the round';

  @override
  String get challengeCelebrationTitle => 'Mission complete!';

  @override
  String challengeCelebrationBody(int rounds, int xp) {
    return 'Round $rounds complete. Rinzy is cheering. You earned +$xp XP.';
  }

  @override
  String get challengeCelebrationBodyNoXp =>
      'Round missions complete. Review the record.';

  @override
  String get challengeCelebrationCompleteTitle => 'Challenge complete!';

  @override
  String challengeCelebrationCompleteBody(int xp) {
    return 'You finished every round. That consistency is becoming real skill. You earned +$xp XP.';
  }

  @override
  String get challengeCelebrationCompleteBodyNoXp =>
      'All missions are recorded. Carry this finish into the next challenge.';

  @override
  String get challengeCelebrationMissionsTitle => 'Completed missions';

  @override
  String get challengeCelebrationAction => 'Nice!';

  @override
  String get challengeCelebrationNextChallengeAction => 'Create next challenge';

  @override
  String get challengeFinishedPraiseTitle => 'You finished it all';

  @override
  String challengeFinishedPraiseBody(Object title, int rounds) {
    return 'You completed all $rounds rounds of $title. Keep the rhythm going with the next challenge.';
  }

  @override
  String challengeFinishedCompletedRoundsLabel(int rounds) {
    return '$rounds rounds completed';
  }

  @override
  String get challengeFinishedNextPrompt => 'Choose the next challenge below';

  @override
  String get challengeHistoryTitle => 'Challenge history';

  @override
  String get challengeHistorySummaryTitle => 'Challenge summary';

  @override
  String get challengeHistoryListTitle => 'Challenge records';

  @override
  String get challengeHistorySummaryTotalLabel => 'Total';

  @override
  String get challengeHistorySummarySuccessLabel => 'Success';

  @override
  String get challengeHistorySummaryLatestLabel => 'Latest';

  @override
  String get challengeHistoryEmpty => 'No challenge history yet.';

  @override
  String challengeHistoryStarted(Object date) {
    return 'Started $date';
  }

  @override
  String challengeHistoryFailedRound(Object date, int round) {
    return 'Started $date · failed at round $round';
  }

  @override
  String get challengeHistoryResultCompleted => 'Success';

  @override
  String get challengeHistoryResultFailed => 'Failed';

  @override
  String get challengeHistoryResultAbandoned => 'Ended';

  @override
  String get challengeHistoryResultInProgress => 'In progress';

  @override
  String challengeHistoryRoundSuccessCount(int success, int total) {
    return 'Success $success/$total';
  }

  @override
  String challengeHistoryRoundFailureCount(int failure, int total) {
    return 'Fail $failure/$total';
  }

  @override
  String get challengeHistoryDetailTitle => 'Challenge detail';

  @override
  String get challengeHistoryDetailCompletedBody =>
      'All rounds were completed. Review the reward plan and round dates.';

  @override
  String challengeHistoryDetailFailedBody(int round) {
    return 'This challenge stopped at round $round. Review the round sequence and reward plan.';
  }

  @override
  String get challengeHistoryDetailAbandonedBody =>
      'This challenge was ended before completion. Review the original round plan.';

  @override
  String challengeHistoryDetailPeriodValue(Object start, Object end) {
    return '$start - $end';
  }

  @override
  String get challengeHistoryDetailMissionsLabel => 'Missions';

  @override
  String get challengeHistoryDetailEarnedXpLabel => 'Earned XP';

  @override
  String get challengeHistoryDetailNoMissions => 'Extra missions only';

  @override
  String get challengeHistoryDetailRoundsTitle => 'Round detail';

  @override
  String challengeHistoryDetailRoundDate(int round, Object date) {
    return 'Round $round · $date';
  }

  @override
  String get challengeHistoryDetailRoundCompleted => 'Completed';

  @override
  String get challengeHistoryDetailRoundFailed => 'Failed here';

  @override
  String get challengeHistoryDetailRoundEnded => 'Not counted';

  @override
  String get challengeAbandonAction => 'End';

  @override
  String get challengeAbandonTitle => 'End challenge';

  @override
  String get challengeAbandonBody =>
      'End the current challenge and choose another?';

  @override
  String get challengeAbandonConfirm => 'End';

  @override
  String get homeChallengeEmptyBody => 'Start a challenge with Rinzy.';

  @override
  String homeChallengeActiveBody(int completed, int total, int round) {
    return '$completed/$total complete · Round $round today';
  }

  @override
  String xpHistoryChallengeRound(Object label) {
    return 'Challenge round · $label';
  }

  @override
  String get xpHistoryReasonChallengeRoundCompleted =>
      'challenge round complete';

  @override
  String get xpHistoryReasonChallengeRoundStreakBonus =>
      'challenge streak bonus';

  @override
  String get xpHistoryReasonChallengeCompletionBonus =>
      'challenge finish bonus';

  @override
  String get matchCompetitionScheduleTab => 'Schedule & results';

  @override
  String get matchCompetitionStandingsTab => 'Standings';

  @override
  String get matchCompetitionBracketTab => 'Bracket';

  @override
  String get matchCompetitionTeamsViewTab => 'Teams';

  @override
  String get matchCompetitionFixtureManageAction => 'Manage match';

  @override
  String get matchCompetitionFixtureEditorTitle => 'Manage match';

  @override
  String get matchCompetitionFixtureScheduleSection => 'Match schedule';

  @override
  String get matchCompetitionFixtureResultSection => 'Match result';

  @override
  String get matchCompetitionFixtureResultEnabled => 'Enter result';

  @override
  String get matchCompetitionFixtureResultUnavailable =>
      'Enter a result after both participating teams are confirmed.';

  @override
  String get matchCompetitionFixtureStatusScheduled => 'Scheduled';

  @override
  String get matchCompetitionFixtureStatusPostponed => 'Postponed';

  @override
  String get matchCompetitionFixtureStatusCancelled => 'Cancelled';

  @override
  String get matchCompetitionFixtureStatusCompleted => 'Completed';

  @override
  String get matchCompetitionFixtureDateAction => 'Select date';

  @override
  String get matchCompetitionFixtureTimeAction => 'Select time';

  @override
  String get matchCompetitionFixtureClearSchedule => 'Clear schedule';

  @override
  String get matchCompetitionFixtureVenueDefault => 'Competition default venue';

  @override
  String get matchCompetitionFixtureVenueUnset => 'Venue undecided';

  @override
  String get matchCompetitionFixturePenaltyTitle => 'Penalty shootout';

  @override
  String get matchCompetitionFixturePenaltyRequired =>
      'Enter a penalty shootout result for a drawn tournament match.';

  @override
  String get matchCompetitionFixtureSave => 'Save match';

  @override
  String get matchCompetitionFixtureSavedFeedback =>
      'Saved the match schedule and result.';

  @override
  String get matchCompetitionFixtureOpenTeamRecord => 'Open our team record';

  @override
  String get matchCompetitionFixtureUnscheduled => 'Schedule pending';

  @override
  String get matchCompetitionFixtureSchedulePlanAction => 'Plan schedule';

  @override
  String get matchCompetitionFixtureSchedulePlanTitle =>
      'Plan competition schedule';

  @override
  String get matchCompetitionFixtureScheduleStartLabel => 'First match';

  @override
  String get matchCompetitionFixtureScheduleIntervalLabel => 'Round interval';

  @override
  String matchCompetitionFixtureScheduleIntervalDays(int days) {
    return '$days days';
  }

  @override
  String get matchCompetitionFixtureScheduleApply => 'Apply schedule';

  @override
  String matchCompetitionFixtureScheduleCount(int scheduled, int total) {
    return '$scheduled/$total scheduled';
  }

  @override
  String get matchCompetitionFixtureDecreaseScore => 'Decrease score';

  @override
  String get matchCompetitionFixtureIncreaseScore => 'Increase score';

  @override
  String get matchCompetitionAutoSavedFeedback =>
      'Competition changes were saved automatically.';

  @override
  String get matchCompetitionStandingsRankColumn => 'Rank';

  @override
  String get matchCompetitionStandingsTeamColumn => 'Team';

  @override
  String get matchCompetitionStandingsPlayedColumn => 'P';

  @override
  String get matchCompetitionStandingsRecordColumn => 'W-D-L';

  @override
  String get matchCompetitionStandingsGoalDifferenceColumn => 'GD';

  @override
  String get matchCompetitionStandingsPointsColumn => 'Pts';

  @override
  String get matchCompetitionParticipantOrderColumn => 'No.';

  @override
  String get matchCompetitionParticipantTeamColumn => 'Team';

  @override
  String get matchCompetitionLeagueTieBreakerLabel => 'Tiebreak rule';

  @override
  String get matchCompetitionTieBreakerGoalDifference =>
      'Points, goal difference, goals scored';

  @override
  String get matchCompetitionTieBreakerWins => 'Points, wins, goal difference';

  @override
  String get matchCompetitionTieBreakerGoalsFor =>
      'Points, goals scored, goal difference';

  @override
  String get matchCompetitionRebuildDialogTitle =>
      'Rebuild fixtures and bracket?';

  @override
  String matchCompetitionRebuildDialogBody(int fixtures, int results) {
    return 'This rebuilds $fixtures fixtures for the new setup. $results recorded results may be cleared.';
  }

  @override
  String get matchCompetitionRebuildConfirm => 'Rebuild';

  @override
  String get matchCompetitionRebuildFeedback =>
      'Fixtures and bracket were rebuilt.';

  @override
  String get matchCompetitionRebuildUndoneFeedback =>
      'Restored the previous fixtures and bracket.';

  @override
  String get matchCompetitionScheduleCalendarAction => 'Competition calendar';

  @override
  String get matchCompetitionScheduleCalendarTitle => 'Competition calendar';

  @override
  String get matchCompetitionScheduleCalendarEmptyDay =>
      'No matches are scheduled for this day.';

  @override
  String get matchCompetitionScheduleUnscheduledLane => 'Unscheduled matches';

  @override
  String matchCompetitionScheduleUnscheduledCount(int count) {
    return '$count unscheduled matches';
  }

  @override
  String matchCompetitionScheduleIssuesCount(int count) {
    return '$count items need attention';
  }

  @override
  String get matchCompetitionScheduleIssueVenueOverlap => 'Venue conflict';

  @override
  String get matchCompetitionScheduleIssueTeamOverlap =>
      'Team plays twice on the same day';

  @override
  String get matchCompetitionScheduleIssueShortRest =>
      'Insufficient rest between matches';

  @override
  String get matchCompetitionQuickResultAction => 'Quick result entry';

  @override
  String get matchCompetitionQuickResultSave => 'Save result';

  @override
  String get matchCompetitionQuickResultCancel => 'Close result entry';

  @override
  String get matchCompetitionProgressRemaining => 'Remaining matches';

  @override
  String get matchCompetitionProgressNextMatches => 'Next matches';

  @override
  String get matchCompetitionProgressChampion => 'Champion';

  @override
  String get matchCompetitionProgressLeader => 'Current leader';

  @override
  String get matchCompetitionProgressAdvanced => 'Advancement confirmed';

  @override
  String get runningCoachCaptureContextTitle => 'Comparison conditions';

  @override
  String get runningCoachCaptureContextBody =>
      'Choose this run\'s effort and surface to compare only like-for-like recordings. Analysis still works without a comparison.';

  @override
  String get runningCoachCaptureContextEffortLabel => 'Effort';

  @override
  String get runningCoachCaptureContextSurfaceLabel => 'Surface';

  @override
  String get runningCoachCaptureEffortEasy => 'Easy';

  @override
  String get runningCoachCaptureEffortSteady => 'Steady';

  @override
  String get runningCoachCaptureEffortFast => 'Fast';

  @override
  String get runningCoachCaptureSurfaceTreadmill => 'Treadmill';

  @override
  String get runningCoachCaptureSurfaceTrackOrRoad => 'Track / road';

  @override
  String get runningCoachGaitTitle => 'Step-by-step measurements';

  @override
  String get runningCoachGaitBody =>
      'Only validated contact frames are used to calculate each step, side, and movement phase again.';

  @override
  String get runningCoachRhythmTitle => 'Running figures from this video';

  @override
  String get runningCoachRhythmBody =>
      'Cadence and time between steps are calculated from verified contact timestamps. This is not an exact ground-contact-time measurement.';

  @override
  String get runningCoachRhythmContactsLabel => 'Verified contacts';

  @override
  String get runningCoachRhythmBilateralUnavailable =>
      'Left/right rhythm comparison needs more contacts with a confidently identified foot.';

  @override
  String get runningCoachRhythmEvidenceLimited =>
      'There are too few verified contacts, so these rhythm values are reference-only.';

  @override
  String get runningCoachGaitDetailsTitle =>
      'Step form values and measurement criteria';

  @override
  String get runningCoachGaitDetailsCollapsedBody =>
      'Foot placement, knee, trunk, arm ranges, and side differences appear when full-body pose coordinates pair with a contact frame.';

  @override
  String get runningCoachGaitUnavailableTitle =>
      'Step measurements are not ready';

  @override
  String get runningCoachGaitUnavailableBody =>
      'There are not enough paired contact and pose frames. Retake with your full body and both feet visible.';

  @override
  String get runningCoachGaitReliableStepsLabel => 'Reliable steps';

  @override
  String get runningCoachGaitCadenceLabel => 'Cadence (spm)';

  @override
  String get runningCoachGaitStepTimeLabel => 'Step time (ms)';

  @override
  String get runningCoachGaitFootReachLabel => 'Foot placement (body scale)';

  @override
  String get runningCoachGaitKneeAtContactLabel => 'Knee at contact (°)';

  @override
  String get runningCoachGaitMinimumKneeLabel =>
      'Minimum knee after contact (°)';

  @override
  String get runningCoachGaitForwardLeanLabel => 'Forward lean at contact (°)';

  @override
  String get runningCoachGaitElbowLabel => 'Elbow at contact (°)';

  @override
  String get runningCoachGaitLeftRightTimingLabel =>
      'Left / right step-time difference (%)';

  @override
  String get runningCoachGaitLeftRightFootLabel =>
      'Left / right foot-placement difference';

  @override
  String get runningCoachGaitLeftRightKneeLabel =>
      'Left / right knee-at-contact difference (°)';

  @override
  String runningCoachGaitRangeValue(
      String median, String minimum, String maximum) {
    return '$median · range $minimum–$maximum';
  }

  @override
  String get runningCoachGaitStepsTitle => 'Validated steps';

  @override
  String runningCoachGaitStepNumber(int number) {
    return 'Step $number';
  }

  @override
  String get runningCoachGaitStepLeft => 'Left';

  @override
  String get runningCoachGaitStepRight => 'Right';

  @override
  String get runningCoachGaitInitialContactLabel => 'Initial contact';

  @override
  String get runningCoachGaitMaximumKneeFlexionLabel => 'Maximum knee flexion';

  @override
  String get runningCoachGaitPhaseUnavailable => 'Not measured in this phase';

  @override
  String get runningCoachGaitEvidenceLimited =>
      'Fewer than three stable steps were read, so these values are reference-only.';

  @override
  String get runningCoachGaitLimitationsTitle =>
      'What this video cannot measure';

  @override
  String get runningCoachGaitLimitationsBody =>
      'A single side-view video does not measure foot rolling or pronation, ground-reaction force, exact ground-contact time, or injury risk.';

  @override
  String get runningCoachJudgmentWithheldTitle => 'Judgment withheld';

  @override
  String get runningCoachJudgmentWithheldBody =>
      'There is not enough evidence to label this movement as good or needing work, so no drill is prescribed. Retake the video instead.';

  @override
  String get runningCoachTrendTitle => 'Same-condition trend';

  @override
  String runningCoachTrendBody(Object effort, Object surface, int count) {
    return 'Compared condition: $effort on $surface. Uses $count recent verified sessions with the same score version.';
  }

  @override
  String get runningCoachTrendInsufficientBaselineTitle =>
      'Insufficient verified baseline';

  @override
  String get runningCoachTrendInsufficientBaselineBody =>
      'At least two verified same-condition sessions with the same score version are required before showing deltas.';

  @override
  String runningCoachTrendMetricValue(Object current, Object delta) {
    return '$current · Δ $delta';
  }

  @override
  String get runningCoachComparisonTitle => 'Same-condition comparison';

  @override
  String runningCoachComparisonBody(String effort, String surface) {
    return 'This recording is stored as $effort on $surface. Only compare it with a previous recording under the same conditions.';
  }

  @override
  String get runningCoachComparisonNoBaselineTitle =>
      'No same-condition baseline yet';

  @override
  String get runningCoachComparisonNoBaselineBody =>
      'Record another run with the same effort and surface before comparing changes.';

  @override
  String get runningCoachComparisonPreviousLabel => 'Previous';

  @override
  String get runningCoachComparisonCurrentLabel => 'Current';

  @override
  String get runningCoachComparisonChangeLabel => 'Previous → current';

  @override
  String runningCoachComparisonChangeValue(String previous, String current) {
    return '$previous → $current';
  }

  @override
  String get runningCoachComparisonSameConditionRetake =>
      'Retake in the same conditions';

  @override
  String get runningCoachDefaultRunner => 'Me';

  @override
  String runningCoachRunnerTarget(String name) {
    return 'Analysis target: $name';
  }

  @override
  String get runningCoachManageRunners => 'Manage runners';

  @override
  String get runningCoachSelectRunnerTitle => 'Who are you analyzing?';

  @override
  String get runningCoachAddRunner => 'Add runner';

  @override
  String get runningCoachRenameRunner => 'Rename';

  @override
  String get runningCoachArchiveRunner => 'Archive';

  @override
  String get runningCoachRunnerNameLabel => 'Runner name';

  @override
  String get runningCoachManageRunner => 'Manage runner';

  @override
  String get runningCoachAnalysisSteps =>
      'Find runner → Analyze movement → Build result';

  @override
  String get runningCoachCaptureWarningAnalysisLimited =>
      'You can still record, but unclear framing may limit or estimate the analysis.';

  @override
  String get runningCoachPreviewCheckFullBody => 'Full body';

  @override
  String get runningCoachPreviewCheckSide => 'Side view';

  @override
  String get runningCoachPreviewCheckClarity => 'Clear distance';

  @override
  String get runningCoachTodayOneThingTitle => 'Change just this today';

  @override
  String get runningCoachStatusEstimatedShort => 'Estimated';

  @override
  String get runningCoachViewEvidenceSlowly => 'View evidence slowly';

  @override
  String get runningCoachTenSecondDrill => '10-second drill';

  @override
  String get runningCoachFiveMovementsTitle => 'Six checks';

  @override
  String get runningCoachStatusImproveShort => 'Improve';

  @override
  String get runningCoachStatusUnavailableShort => 'Not measured';

  @override
  String get runningCoachFullAnalysisAction => 'View full analysis';

  @override
  String get runningCoachGoodBandLabel => 'Good band';

  @override
  String get runningCoachNextCueLabel => 'Next cue';

  @override
  String get runningCoachRawMeasurementDetails => 'View measurement details';

  @override
  String get runningCoachConfidenceShortLabel => 'Confidence';

  @override
  String get runningCoachMeasurementMethodLabel => 'Method';

  @override
  String get runningCoachGaitRhythmTitle => 'Rhythm and timing';

  @override
  String get runningCoachReportDetailsTitle => 'Movement details';

  @override
  String get runningCoachGaitFineTitle => 'Detailed gait';

  @override
  String get runningCoachTodayLabel => 'Today';

  @override
  String get runningCoachAnalysisQualityBadgeStrong => 'Stable analysis';

  @override
  String get runningCoachAnalysisQualityBadgeLimited => 'Limited analysis';

  @override
  String runningCoachPreviousScoreDelta(int delta) {
    return 'Previous $delta';
  }

  @override
  String runningCoachHistoryConfirmedScore(int score) {
    return 'Confirmed $score';
  }

  @override
  String runningCoachHistoryEstimatedScore(int score) {
    return 'Estimated $score';
  }

  @override
  String get runningCoachHistoryScoreUnavailable => 'Score withheld';

  @override
  String get runningCoachMultiplePersonLabel => 'More than one person';

  @override
  String get runningCoachTargetIdentityUnstableLabel =>
      'Runner tracking changed';

  @override
  String get runningCoachMultiplePersonReason =>
      'More than one person may be in the clip, so the app withheld the score to avoid scoring the wrong runner.';

  @override
  String get runningCoachTargetIdentityUnstableReason =>
      'Runner tracking changed abruptly, so the app withheld the score to avoid mixing people.';

  @override
  String get runningCoachSingleRunnerRetake =>
      'Record one runner at a time and keep everyone else outside the frame.';

  @override
  String runningCoachHistoryTrendSummary(int best, int delta) {
    return 'Best confirmed score $best · latest change $delta';
  }
}
