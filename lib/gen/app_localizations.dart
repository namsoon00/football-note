import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_ja.dart';
import 'app_localizations_ko.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'gen/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
      : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('ja'),
    Locale('ko')
  ];

  /// No description provided for @appTitle.
  ///
  /// In en, this message translates to:
  /// **'Taeo\'s Note'**
  String get appTitle;

  /// No description provided for @tabHome.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get tabHome;

  /// No description provided for @tabLogs.
  ///
  /// In en, this message translates to:
  /// **'Logs'**
  String get tabLogs;

  /// No description provided for @tabCalendar.
  ///
  /// In en, this message translates to:
  /// **'Calendar'**
  String get tabCalendar;

  /// No description provided for @tabStats.
  ///
  /// In en, this message translates to:
  /// **'Stats'**
  String get tabStats;

  /// No description provided for @tabDiary.
  ///
  /// In en, this message translates to:
  /// **'Diary'**
  String get tabDiary;

  /// No description provided for @tabNews.
  ///
  /// In en, this message translates to:
  /// **'News'**
  String get tabNews;

  /// No description provided for @tabGuideTitle.
  ///
  /// In en, this message translates to:
  /// **'{tabName} guide'**
  String tabGuideTitle(Object tabName);

  /// No description provided for @welcomeGuideTitle.
  ///
  /// In en, this message translates to:
  /// **'Log today, and move stronger tomorrow.'**
  String get welcomeGuideTitle;

  /// No description provided for @welcomeGuideIntro.
  ///
  /// In en, this message translates to:
  /// **'Any sport works. One short note can make the next practice easier. Start now; you can do this.'**
  String get welcomeGuideIntro;

  /// No description provided for @welcomeGuidePrimaryAction.
  ///
  /// In en, this message translates to:
  /// **'Start logging'**
  String get welcomeGuidePrimaryAction;

  /// No description provided for @welcomeGuideSectionFlow.
  ///
  /// In en, this message translates to:
  /// **'What to do'**
  String get welcomeGuideSectionFlow;

  /// No description provided for @welcomeGuideNextTabHint.
  ///
  /// In en, this message translates to:
  /// **'Swipe through three cards. Then log one thing right away.'**
  String get welcomeGuideNextTabHint;

  /// No description provided for @welcomeGuidePreviewLabel.
  ///
  /// In en, this message translates to:
  /// **'Action to choose now'**
  String get welcomeGuidePreviewLabel;

  /// No description provided for @welcomeGuideCoachMarkLabel.
  ///
  /// In en, this message translates to:
  /// **'Tap this'**
  String get welcomeGuideCoachMarkLabel;

  /// No description provided for @welcomeSlideGemTitle.
  ///
  /// In en, this message translates to:
  /// **'Small logs become real confidence.'**
  String get welcomeSlideGemTitle;

  /// No description provided for @welcomeSlideGemBody.
  ///
  /// In en, this message translates to:
  /// **'Praise what went well, and turn the hard part into the next challenge. Each note helps you improve.'**
  String get welcomeSlideGemBody;

  /// No description provided for @welcomeSlideFlameTitle.
  ///
  /// In en, this message translates to:
  /// **'Do not stop on a hard day.'**
  String get welcomeSlideFlameTitle;

  /// No description provided for @welcomeSlideFlameBody.
  ///
  /// In en, this message translates to:
  /// **'One small action is enough. Log it, restart, and take one more step tomorrow.'**
  String get welcomeSlideFlameBody;

  /// No description provided for @startupSportTitle.
  ///
  /// In en, this message translates to:
  /// **'Choose your sport first'**
  String get startupSportTitle;

  /// No description provided for @startupSportSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Records, goals, stats, and news start around the sport you choose. You can change it later in Settings.'**
  String get startupSportSubtitle;

  /// No description provided for @startupSportAction.
  ///
  /// In en, this message translates to:
  /// **'Start with this sport'**
  String get startupSportAction;

  /// No description provided for @startupSportFootballDescription.
  ///
  /// In en, this message translates to:
  /// **'Start with football training, matches, sketches, and news.'**
  String get startupSportFootballDescription;

  /// No description provided for @startupSportBaseballDescription.
  ///
  /// In en, this message translates to:
  /// **'Track throwing, batting, fielding, and conditioning for baseball.'**
  String get startupSportBaseballDescription;

  /// No description provided for @startupSportBasketballDescription.
  ///
  /// In en, this message translates to:
  /// **'Log shooting, dribbling, game flow, and conditioning for basketball.'**
  String get startupSportBasketballDescription;

  /// No description provided for @startupSportTennisDescription.
  ///
  /// In en, this message translates to:
  /// **'Track strokes, serves, rallies, and support training for tennis.'**
  String get startupSportTennisDescription;

  /// No description provided for @tabGuideCoachMarkStep.
  ///
  /// In en, this message translates to:
  /// **'Step {current} of {total}'**
  String tabGuideCoachMarkStep(int current, int total);

  /// No description provided for @tabGuideCoachMarkSkip.
  ///
  /// In en, this message translates to:
  /// **'Skip'**
  String get tabGuideCoachMarkSkip;

  /// No description provided for @tabGuideCoachMarkBack.
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get tabGuideCoachMarkBack;

  /// No description provided for @tabGuideCoachMarkNext.
  ///
  /// In en, this message translates to:
  /// **'Next'**
  String get tabGuideCoachMarkNext;

  /// No description provided for @tabGuideCoachMarkDone.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get tabGuideCoachMarkDone;

  /// No description provided for @tabGuideCoachMarkTry.
  ///
  /// In en, this message translates to:
  /// **'Try this'**
  String get tabGuideCoachMarkTry;

  /// No description provided for @parentWelcomeGuideTitle.
  ///
  /// In en, this message translates to:
  /// **'Parent Mode Guide'**
  String get parentWelcomeGuideTitle;

  /// No description provided for @parentWelcomeGuideIntro.
  ///
  /// In en, this message translates to:
  /// **'Parent mode is for reviewing player records and leaving feedback on existing training logs.'**
  String get parentWelcomeGuideIntro;

  /// No description provided for @parentWelcomeGuideStepLogs.
  ///
  /// In en, this message translates to:
  /// **'Open the Logs tab first to review records saved by the player.'**
  String get parentWelcomeGuideStepLogs;

  /// No description provided for @parentWelcomeGuideStepFeedback.
  ///
  /// In en, this message translates to:
  /// **'Leave praise and next-time notes as feedback inside an existing record.'**
  String get parentWelcomeGuideStepFeedback;

  /// No description provided for @parentWelcomeGuideStepSync.
  ///
  /// In en, this message translates to:
  /// **'Connect the Google Drive account that holds the player backup to keep shared data in sync.'**
  String get parentWelcomeGuideStepSync;

  /// No description provided for @guideActionToday.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get guideActionToday;

  /// No description provided for @guideActionMeal.
  ///
  /// In en, this message translates to:
  /// **'Meals'**
  String get guideActionMeal;

  /// No description provided for @guideActionCardList.
  ///
  /// In en, this message translates to:
  /// **'Cards/List'**
  String get guideActionCardList;

  /// No description provided for @guideActionSelectDate.
  ///
  /// In en, this message translates to:
  /// **'Select date'**
  String get guideActionSelectDate;

  /// No description provided for @guideActionPlus.
  ///
  /// In en, this message translates to:
  /// **'+'**
  String get guideActionPlus;

  /// No description provided for @guideActionPeriod.
  ///
  /// In en, this message translates to:
  /// **'Period'**
  String get guideActionPeriod;

  /// No description provided for @guideActionBenchmark.
  ///
  /// In en, this message translates to:
  /// **'Average'**
  String get guideActionBenchmark;

  /// No description provided for @guideActionWeakPoint.
  ///
  /// In en, this message translates to:
  /// **'Focus'**
  String get guideActionWeakPoint;

  /// No description provided for @guideActionOpenToday.
  ///
  /// In en, this message translates to:
  /// **'Today diary'**
  String get guideActionOpenToday;

  /// No description provided for @guideActionRecordSticker.
  ///
  /// In en, this message translates to:
  /// **'Stickers'**
  String get guideActionRecordSticker;

  /// No description provided for @guideActionSaveDiary.
  ///
  /// In en, this message translates to:
  /// **'Save diary'**
  String get guideActionSaveDiary;

  /// No description provided for @welcomeHomeOverview.
  ///
  /// In en, this message translates to:
  /// **'Start on Home when you want the app to decide the next useful action.'**
  String get welcomeHomeOverview;

  /// No description provided for @welcomeHomeStepToday.
  ///
  /// In en, this message translates to:
  /// **'Check today\'s plan, quick actions, and the next unfinished routine first.'**
  String get welcomeHomeStepToday;

  /// No description provided for @welcomeHomeStepMeal.
  ///
  /// In en, this message translates to:
  /// **'Add meals from the meal button before the day ends so recovery records stay complete.'**
  String get welcomeHomeStepMeal;

  /// No description provided for @welcomeHomeStepStats.
  ///
  /// In en, this message translates to:
  /// **'Open weekly stats from Home after logging to see whether the week is balanced.'**
  String get welcomeHomeStepStats;

  /// No description provided for @welcomeLogsOverview.
  ///
  /// In en, this message translates to:
  /// **'Use Logs when you are creating or reviewing the actual training note.'**
  String get welcomeLogsOverview;

  /// No description provided for @welcomeLogsStepAdd.
  ///
  /// In en, this message translates to:
  /// **'Tap Add Entry, fill the session basics, then save the first note.'**
  String get welcomeLogsStepAdd;

  /// No description provided for @welcomeLogsStepBoard.
  ///
  /// In en, this message translates to:
  /// **'Open Board inside the note when the drill shape or movement path matters.'**
  String get welcomeLogsStepBoard;

  /// No description provided for @welcomeLogsStepReview.
  ///
  /// In en, this message translates to:
  /// **'Switch cards/list and filters to find recent records without reading every note.'**
  String get welcomeLogsStepReview;

  /// No description provided for @welcomeCalendarOverview.
  ///
  /// In en, this message translates to:
  /// **'Use Calendar when the date matters: plans, matches, meals, and notes stay together.'**
  String get welcomeCalendarOverview;

  /// No description provided for @welcomeCalendarStepDate.
  ///
  /// In en, this message translates to:
  /// **'Select a date first so every create action starts on the right day.'**
  String get welcomeCalendarStepDate;

  /// No description provided for @welcomeCalendarStepPlus.
  ///
  /// In en, this message translates to:
  /// **'Use + to add a plan, match, or training note from the selected date.'**
  String get welcomeCalendarStepPlus;

  /// No description provided for @welcomeCalendarStepMeal.
  ///
  /// In en, this message translates to:
  /// **'Add a meal record from the same date when recovery is part of the day.'**
  String get welcomeCalendarStepMeal;

  /// No description provided for @welcomeStatsOverview.
  ///
  /// In en, this message translates to:
  /// **'Use Stats after several records exist and you want the next training target.'**
  String get welcomeStatsOverview;

  /// No description provided for @welcomeStatsStepPeriod.
  ///
  /// In en, this message translates to:
  /// **'Change the period to compare this week, last week, or a custom range.'**
  String get welcomeStatsStepPeriod;

  /// No description provided for @welcomeStatsStepAverage.
  ///
  /// In en, this message translates to:
  /// **'Open average comparison to see which metric is ahead or behind.'**
  String get welcomeStatsStepAverage;

  /// No description provided for @welcomeStatsStepFocus.
  ///
  /// In en, this message translates to:
  /// **'Turn the weakest signal into the next plan or note goal.'**
  String get welcomeStatsStepFocus;

  /// No description provided for @welcomeChallengeOverview.
  ///
  /// In en, this message translates to:
  /// **'Challenge mode turns daily rounds into pressure you cannot quietly ignore.'**
  String get welcomeChallengeOverview;

  /// No description provided for @welcomeChallengeActionStart.
  ///
  /// In en, this message translates to:
  /// **'Start challenge'**
  String get welcomeChallengeActionStart;

  /// No description provided for @welcomeChallengeStepStart.
  ///
  /// In en, this message translates to:
  /// **'Choose a duration to create rounds you can follow from today.'**
  String get welcomeChallengeStepStart;

  /// No description provided for @welcomeChallengeActionMission.
  ///
  /// In en, this message translates to:
  /// **'Enter mission'**
  String get welcomeChallengeActionMission;

  /// No description provided for @welcomeChallengeStepMission.
  ///
  /// In en, this message translates to:
  /// **'Tap training, jump rope, lifting, or meal missions to open the matching record screen.'**
  String get welcomeChallengeStepMission;

  /// No description provided for @welcomeChallengeActionReward.
  ///
  /// In en, this message translates to:
  /// **'XP reward'**
  String get welcomeChallengeActionReward;

  /// No description provided for @welcomeChallengeStepReward.
  ///
  /// In en, this message translates to:
  /// **'Finished rounds stack XP. Miss them, and the gap is visible.'**
  String get welcomeChallengeStepReward;

  /// No description provided for @welcomeDiaryOverview.
  ///
  /// In en, this message translates to:
  /// **'Use Diary to turn the day into one readable story with training, meals, and stickers.'**
  String get welcomeDiaryOverview;

  /// No description provided for @welcomeDiaryStepToday.
  ///
  /// In en, this message translates to:
  /// **'Open today\'s diary from Home or the Diary tab after recording.'**
  String get welcomeDiaryStepToday;

  /// No description provided for @welcomeDiaryStepSticker.
  ///
  /// In en, this message translates to:
  /// **'Pull in today\'s record stickers and arrange the reading order.'**
  String get welcomeDiaryStepSticker;

  /// No description provided for @welcomeDiaryStepSave.
  ///
  /// In en, this message translates to:
  /// **'Save the diary once the title, story, or sticker selection is ready.'**
  String get welcomeDiaryStepSave;

  /// No description provided for @logsQuickGuideTitle.
  ///
  /// In en, this message translates to:
  /// **'Quick start guide'**
  String get logsQuickGuideTitle;

  /// No description provided for @logsQuickGuideIntro.
  ///
  /// In en, this message translates to:
  /// **'Create your first record in this order, then return here to review it.'**
  String get logsQuickGuideIntro;

  /// No description provided for @newsFifaHubButton.
  ///
  /// In en, this message translates to:
  /// **'FIFA'**
  String get newsFifaHubButton;

  /// No description provided for @newsWorldCupButton.
  ///
  /// In en, this message translates to:
  /// **'World Cup'**
  String get newsWorldCupButton;

  /// No description provided for @newsKLeagueStandingsButton.
  ///
  /// In en, this message translates to:
  /// **'League'**
  String get newsKLeagueStandingsButton;

  /// No description provided for @newsMoreActionsTooltip.
  ///
  /// In en, this message translates to:
  /// **'League view'**
  String get newsMoreActionsTooltip;

  /// No description provided for @newsMoreActionsTitle.
  ///
  /// In en, this message translates to:
  /// **'More'**
  String get newsMoreActionsTitle;

  /// No description provided for @newsRankingMoreButton.
  ///
  /// In en, this message translates to:
  /// **'League view'**
  String get newsRankingMoreButton;

  /// No description provided for @newsLeagueStandingsAction.
  ///
  /// In en, this message translates to:
  /// **'League'**
  String get newsLeagueStandingsAction;

  /// No description provided for @newsLeagueStandingsTitle.
  ///
  /// In en, this message translates to:
  /// **'League View'**
  String get newsLeagueStandingsTitle;

  /// No description provided for @newsKLeagueStandingsTitle.
  ///
  /// In en, this message translates to:
  /// **'K League 1'**
  String get newsKLeagueStandingsTitle;

  /// No description provided for @newsPremierLeagueStandingsTitle.
  ///
  /// In en, this message translates to:
  /// **'Premier League'**
  String get newsPremierLeagueStandingsTitle;

  /// No description provided for @newsChampionsLeagueStandingsTitle.
  ///
  /// In en, this message translates to:
  /// **'Champions League'**
  String get newsChampionsLeagueStandingsTitle;

  /// No description provided for @newsLaLigaStandingsTitle.
  ///
  /// In en, this message translates to:
  /// **'LaLiga'**
  String get newsLaLigaStandingsTitle;

  /// No description provided for @newsBundesligaStandingsTitle.
  ///
  /// In en, this message translates to:
  /// **'Bundesliga'**
  String get newsBundesligaStandingsTitle;

  /// No description provided for @newsMajorLeagueSoccerStandingsTitle.
  ///
  /// In en, this message translates to:
  /// **'MLS'**
  String get newsMajorLeagueSoccerStandingsTitle;

  /// No description provided for @newsSaudiProLeagueStandingsTitle.
  ///
  /// In en, this message translates to:
  /// **'Saudi Pro League'**
  String get newsSaudiProLeagueStandingsTitle;

  /// No description provided for @newsLeagueStandingsUpdated.
  ///
  /// In en, this message translates to:
  /// **'Updated {date}'**
  String newsLeagueStandingsUpdated(Object date);

  /// No description provided for @newsLeagueStandingsOpenSource.
  ///
  /// In en, this message translates to:
  /// **'Open source table'**
  String get newsLeagueStandingsOpenSource;

  /// No description provided for @newsLeagueStandingsEmpty.
  ///
  /// In en, this message translates to:
  /// **'No standings are available right now.'**
  String get newsLeagueStandingsEmpty;

  /// No description provided for @newsLeagueStandingsError.
  ///
  /// In en, this message translates to:
  /// **'Could not load standings.'**
  String get newsLeagueStandingsError;

  /// No description provided for @newsLeagueStandingsRetry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get newsLeagueStandingsRetry;

  /// No description provided for @newsLeagueFixturesTitle.
  ///
  /// In en, this message translates to:
  /// **'Fixture calendar'**
  String get newsLeagueFixturesTitle;

  /// No description provided for @newsLeagueFixturesCalendarTitle.
  ///
  /// In en, this message translates to:
  /// **'Fixture calendar'**
  String get newsLeagueFixturesCalendarTitle;

  /// No description provided for @newsLeagueFixturesOpenCalendar.
  ///
  /// In en, this message translates to:
  /// **'View as calendar'**
  String get newsLeagueFixturesOpenCalendar;

  /// No description provided for @newsLeagueFixturesCalendarEmptyDay.
  ///
  /// In en, this message translates to:
  /// **'No fixtures are placed on this date.'**
  String get newsLeagueFixturesCalendarEmptyDay;

  /// No description provided for @newsLeagueFixturesSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Open the calendar to review upcoming fixtures and recent results.'**
  String get newsLeagueFixturesSubtitle;

  /// No description provided for @newsLeagueFixturesEmpty.
  ///
  /// In en, this message translates to:
  /// **'No fixtures were found after checking a wider schedule window.'**
  String get newsLeagueFixturesEmpty;

  /// No description provided for @newsLeagueFixturesShowAll.
  ///
  /// In en, this message translates to:
  /// **'Show all fixtures'**
  String get newsLeagueFixturesShowAll;

  /// No description provided for @newsLeagueFixturesCollapse.
  ///
  /// In en, this message translates to:
  /// **'Collapse fixtures'**
  String get newsLeagueFixturesCollapse;

  /// No description provided for @newsLeagueFixturesSelectedTeamsOnly.
  ///
  /// In en, this message translates to:
  /// **'Selected teams only'**
  String get newsLeagueFixturesSelectedTeamsOnly;

  /// No description provided for @newsLeagueFixturesSelectedTeamsEmpty.
  ///
  /// In en, this message translates to:
  /// **'No selected-team fixtures are available in this league schedule.'**
  String get newsLeagueFixturesSelectedTeamsEmpty;

  /// No description provided for @newsLeagueFixturesEmptyReason.
  ///
  /// In en, this message translates to:
  /// **'{league} has no fixtures to show because the source fixture feed is empty or the current season schedule has not been published yet.'**
  String newsLeagueFixturesEmptyReason(String league);

  /// No description provided for @newsLeagueFixtureScheduled.
  ///
  /// In en, this message translates to:
  /// **'Fixture'**
  String get newsLeagueFixtureScheduled;

  /// No description provided for @newsLeagueFixtureLive.
  ///
  /// In en, this message translates to:
  /// **'Live'**
  String get newsLeagueFixtureLive;

  /// No description provided for @newsLeagueFixtureFullTime.
  ///
  /// In en, this message translates to:
  /// **'FT'**
  String get newsLeagueFixtureFullTime;

  /// No description provided for @newsLeagueTeamDetailTitle.
  ///
  /// In en, this message translates to:
  /// **'{team} info'**
  String newsLeagueTeamDetailTitle(String team);

  /// No description provided for @newsLeagueTeamDetailRosterTitle.
  ///
  /// In en, this message translates to:
  /// **'Roster'**
  String get newsLeagueTeamDetailRosterTitle;

  /// No description provided for @newsLeagueTeamDetailTacticsTitle.
  ///
  /// In en, this message translates to:
  /// **'Tactics'**
  String get newsLeagueTeamDetailTacticsTitle;

  /// No description provided for @newsLeagueTeamDetailFixturesTitle.
  ///
  /// In en, this message translates to:
  /// **'Team fixtures'**
  String get newsLeagueTeamDetailFixturesTitle;

  /// No description provided for @newsLeagueTeamDetailNoFixtures.
  ///
  /// In en, this message translates to:
  /// **'No matches for this team were found in the loaded fixtures.'**
  String get newsLeagueTeamDetailNoFixtures;

  /// No description provided for @newsLeagueTeamDetailTacticsSummary.
  ///
  /// In en, this message translates to:
  /// **'Use the current table plus goal data to read the team trend. Official tactics and roster details will appear here when the feed provides them.'**
  String get newsLeagueTeamDetailTacticsSummary;

  /// No description provided for @newsLeagueTeamDetailSourceNote.
  ///
  /// In en, this message translates to:
  /// **'Only information available from the official league feed is shown.'**
  String get newsLeagueTeamDetailSourceNote;

  /// No description provided for @newsLeagueFavoriteTeamTitle.
  ///
  /// In en, this message translates to:
  /// **'Favorite teams'**
  String get newsLeagueFavoriteTeamTitle;

  /// No description provided for @newsLeagueFavoriteTeamManage.
  ///
  /// In en, this message translates to:
  /// **'Select favorite teams'**
  String get newsLeagueFavoriteTeamManage;

  /// No description provided for @newsLeagueFavoriteTeamSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Choose favorite teams to receive alerts for their loaded fixtures.'**
  String get newsLeagueFavoriteTeamSubtitle;

  /// No description provided for @newsLeagueFavoriteTeamSelect.
  ///
  /// In en, this message translates to:
  /// **'Select teams'**
  String get newsLeagueFavoriteTeamSelect;

  /// No description provided for @newsLeagueFavoriteTeamClear.
  ///
  /// In en, this message translates to:
  /// **'Clear'**
  String get newsLeagueFavoriteTeamClear;

  /// No description provided for @newsLeagueFavoriteTeamNone.
  ///
  /// In en, this message translates to:
  /// **'No team selected'**
  String get newsLeagueFavoriteTeamNone;

  /// No description provided for @newsLeagueFavoriteTeamSheetTitle.
  ///
  /// In en, this message translates to:
  /// **'Select favorite teams'**
  String get newsLeagueFavoriteTeamSheetTitle;

  /// No description provided for @newsLeagueFavoriteTeamSaveAction.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get newsLeagueFavoriteTeamSaveAction;

  /// No description provided for @newsLeagueFavoriteTeamLoadError.
  ///
  /// In en, this message translates to:
  /// **'Could not load the team list.'**
  String get newsLeagueFavoriteTeamLoadError;

  /// No description provided for @newsLeagueFavoriteTeamEmpty.
  ///
  /// In en, this message translates to:
  /// **'No teams are available.'**
  String get newsLeagueFavoriteTeamEmpty;

  /// No description provided for @newsLeagueFavoriteTeamSelectedCount.
  ///
  /// In en, this message translates to:
  /// **'{count} team(s) selected'**
  String newsLeagueFavoriteTeamSelectedCount(int count);

  /// No description provided for @newsLeagueFavoriteTeamSaved.
  ///
  /// In en, this message translates to:
  /// **'Favorite teams saved.'**
  String get newsLeagueFavoriteTeamSaved;

  /// No description provided for @newsLeagueFavoriteTeamNoUpcoming.
  ///
  /// In en, this message translates to:
  /// **'No match alerts are scheduled.'**
  String get newsLeagueFavoriteTeamNoUpcoming;

  /// No description provided for @newsLeagueFavoriteTeamReminderCount.
  ///
  /// In en, this message translates to:
  /// **'{count} match alerts scheduled'**
  String newsLeagueFavoriteTeamReminderCount(int count);

  /// No description provided for @newsLeagueFavoriteTeamNotificationBody.
  ///
  /// In en, this message translates to:
  /// **'{team} fixture alert: vs {opponent} at {kickoff}'**
  String newsLeagueFavoriteTeamNotificationBody(
      Object team, Object opponent, Object kickoff);

  /// No description provided for @newsLeagueFixtureNotificationChannelName.
  ///
  /// In en, this message translates to:
  /// **'League Fixture Alerts'**
  String get newsLeagueFixtureNotificationChannelName;

  /// No description provided for @newsLeagueFixtureNotificationChannelDescription.
  ///
  /// In en, this message translates to:
  /// **'Fixture alerts for preferred league teams'**
  String get newsLeagueFixtureNotificationChannelDescription;

  /// No description provided for @notificationAppTitle.
  ///
  /// In en, this message translates to:
  /// **'Taeo\'s Note'**
  String get notificationAppTitle;

  /// No description provided for @worldCupFixtureNotificationChannelName.
  ///
  /// In en, this message translates to:
  /// **'World Cup Match Alerts'**
  String get worldCupFixtureNotificationChannelName;

  /// No description provided for @worldCupFixtureNotificationChannelDescription.
  ///
  /// In en, this message translates to:
  /// **'Fixture alerts for selected World Cup countries'**
  String get worldCupFixtureNotificationChannelDescription;

  /// No description provided for @worldCupFixtureNotificationBody.
  ///
  /// In en, this message translates to:
  /// **'{team} World Cup match: vs {opponent} at {kickoff}'**
  String worldCupFixtureNotificationBody(
      Object team, Object opponent, Object kickoff);

  /// No description provided for @newsLeagueStandingsTeamColumn.
  ///
  /// In en, this message translates to:
  /// **'Team'**
  String get newsLeagueStandingsTeamColumn;

  /// No description provided for @newsLeagueStandingsPlayedColumn.
  ///
  /// In en, this message translates to:
  /// **'P'**
  String get newsLeagueStandingsPlayedColumn;

  /// No description provided for @newsLeagueStandingsWinsColumn.
  ///
  /// In en, this message translates to:
  /// **'W'**
  String get newsLeagueStandingsWinsColumn;

  /// No description provided for @newsLeagueStandingsDrawsColumn.
  ///
  /// In en, this message translates to:
  /// **'D'**
  String get newsLeagueStandingsDrawsColumn;

  /// No description provided for @newsLeagueStandingsLossesColumn.
  ///
  /// In en, this message translates to:
  /// **'L'**
  String get newsLeagueStandingsLossesColumn;

  /// No description provided for @newsLeagueStandingsGoalDifferenceColumn.
  ///
  /// In en, this message translates to:
  /// **'GD'**
  String get newsLeagueStandingsGoalDifferenceColumn;

  /// No description provided for @newsLeagueStandingsPointsColumn.
  ///
  /// In en, this message translates to:
  /// **'Pts'**
  String get newsLeagueStandingsPointsColumn;

  /// No description provided for @newsSearchAction.
  ///
  /// In en, this message translates to:
  /// **'Search news'**
  String get newsSearchAction;

  /// No description provided for @newsChannelsAction.
  ///
  /// In en, this message translates to:
  /// **'Channels'**
  String get newsChannelsAction;

  /// No description provided for @newsShowAllNewsAction.
  ///
  /// In en, this message translates to:
  /// **'Show all news'**
  String get newsShowAllNewsAction;

  /// No description provided for @newsShowScrappedOnlyAction.
  ///
  /// In en, this message translates to:
  /// **'Show scrapped only'**
  String get newsShowScrappedOnlyAction;

  /// No description provided for @newsViewedHistoryAction.
  ///
  /// In en, this message translates to:
  /// **'Viewed news'**
  String get newsViewedHistoryAction;

  /// No description provided for @newsViewedHistoryTitle.
  ///
  /// In en, this message translates to:
  /// **'Viewed news'**
  String get newsViewedHistoryTitle;

  /// No description provided for @newsViewedHistoryEmpty.
  ///
  /// In en, this message translates to:
  /// **'No viewed news yet.'**
  String get newsViewedHistoryEmpty;

  /// No description provided for @newsTitleTranslateEnabledTooltip.
  ///
  /// In en, this message translates to:
  /// **'Title translation on'**
  String get newsTitleTranslateEnabledTooltip;

  /// No description provided for @newsTitleTranslateDisabledTooltip.
  ///
  /// In en, this message translates to:
  /// **'Title translation off'**
  String get newsTitleTranslateDisabledTooltip;

  /// No description provided for @newsTranslateAction.
  ///
  /// In en, this message translates to:
  /// **'Translate'**
  String get newsTranslateAction;

  /// No description provided for @newsLoadFailedMessage.
  ///
  /// In en, this message translates to:
  /// **'Failed to load news. Pull down to refresh.'**
  String get newsLoadFailedMessage;

  /// No description provided for @newsNoChannelArticles.
  ///
  /// In en, this message translates to:
  /// **'No news for selected channels.'**
  String get newsNoChannelArticles;

  /// No description provided for @newsNoScrappedArticles.
  ///
  /// In en, this message translates to:
  /// **'No scrapped news yet.'**
  String get newsNoScrappedArticles;

  /// No description provided for @newsNoResultsFound.
  ///
  /// In en, this message translates to:
  /// **'No results found.'**
  String get newsNoResultsFound;

  /// No description provided for @newsScrapTooltip.
  ///
  /// In en, this message translates to:
  /// **'Scrap'**
  String get newsScrapTooltip;

  /// No description provided for @newsRemoveScrapTooltip.
  ///
  /// In en, this message translates to:
  /// **'Remove scrap'**
  String get newsRemoveScrapTooltip;

  /// No description provided for @newsScrappedSnack.
  ///
  /// In en, this message translates to:
  /// **'News scrapped.'**
  String get newsScrappedSnack;

  /// No description provided for @newsScrapRemovedSnack.
  ///
  /// In en, this message translates to:
  /// **'Scrap removed.'**
  String get newsScrapRemovedSnack;

  /// No description provided for @newsTranslationGuideSnack.
  ///
  /// In en, this message translates to:
  /// **'Use the top-right menu on the article screen to translate the page.'**
  String get newsTranslationGuideSnack;

  /// No description provided for @newsSelectChannelsTitle.
  ///
  /// In en, this message translates to:
  /// **'Select news channels'**
  String get newsSelectChannelsTitle;

  /// No description provided for @newsSelectAll.
  ///
  /// In en, this message translates to:
  /// **'Select all'**
  String get newsSelectAll;

  /// No description provided for @newsClearAll.
  ///
  /// In en, this message translates to:
  /// **'Clear all'**
  String get newsClearAll;

  /// No description provided for @newsDomesticFeedsLabel.
  ///
  /// In en, this message translates to:
  /// **'Korean feeds'**
  String get newsDomesticFeedsLabel;

  /// No description provided for @newsInternationalFeedsLabel.
  ///
  /// In en, this message translates to:
  /// **'International feeds'**
  String get newsInternationalFeedsLabel;

  /// No description provided for @newsRegionAllLabel.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get newsRegionAllLabel;

  /// No description provided for @newsRegionDomesticLabel.
  ///
  /// In en, this message translates to:
  /// **'Korea'**
  String get newsRegionDomesticLabel;

  /// No description provided for @newsRegionInternationalLabel.
  ///
  /// In en, this message translates to:
  /// **'World'**
  String get newsRegionInternationalLabel;

  /// No description provided for @newsNationalSnapshotTitle.
  ///
  /// In en, this message translates to:
  /// **'National Team Snapshot'**
  String get newsNationalSnapshotTitle;

  /// No description provided for @newsNationalSnapshotSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Korea Republic men\'s team summary from official pages'**
  String get newsNationalSnapshotSubtitle;

  /// No description provided for @newsFifaRankingTitle.
  ///
  /// In en, this message translates to:
  /// **'FIFA Ranking'**
  String get newsFifaRankingTitle;

  /// No description provided for @newsRankingCurrentLabel.
  ///
  /// In en, this message translates to:
  /// **'Current rank'**
  String get newsRankingCurrentLabel;

  /// No description provided for @newsRankingUpdatedLabel.
  ///
  /// In en, this message translates to:
  /// **'Updated'**
  String get newsRankingUpdatedLabel;

  /// No description provided for @newsRecentAMatchTitle.
  ///
  /// In en, this message translates to:
  /// **'Recent A-matches'**
  String get newsRecentAMatchTitle;

  /// No description provided for @newsRecentAMatchEmpty.
  ///
  /// In en, this message translates to:
  /// **'Recent A-match results were not found.'**
  String get newsRecentAMatchEmpty;

  /// No description provided for @newsOpenOfficialSource.
  ///
  /// In en, this message translates to:
  /// **'Open official page'**
  String get newsOpenOfficialSource;

  /// No description provided for @newsOfficialSourceFifa.
  ///
  /// In en, this message translates to:
  /// **'FIFA official'**
  String get newsOfficialSourceFifa;

  /// No description provided for @newsOfficialSourceKfa.
  ///
  /// In en, this message translates to:
  /// **'KFA official'**
  String get newsOfficialSourceKfa;

  /// No description provided for @newsMatchResultWin.
  ///
  /// In en, this message translates to:
  /// **'Win'**
  String get newsMatchResultWin;

  /// No description provided for @newsMatchResultDraw.
  ///
  /// In en, this message translates to:
  /// **'Draw'**
  String get newsMatchResultDraw;

  /// No description provided for @newsMatchResultLoss.
  ///
  /// In en, this message translates to:
  /// **'Loss'**
  String get newsMatchResultLoss;

  /// No description provided for @matchKickoffKoreaOnly.
  ///
  /// In en, this message translates to:
  /// **'Korea time {time}'**
  String matchKickoffKoreaOnly(String time);

  /// No description provided for @matchKickoffLocalAndKorea.
  ///
  /// In en, this message translates to:
  /// **'{localTime} · Korea time {koreaTime}'**
  String matchKickoffLocalAndKorea(String localTime, String koreaTime);

  /// No description provided for @worldCupTitle.
  ///
  /// In en, this message translates to:
  /// **'World Cup View'**
  String get worldCupTitle;

  /// No description provided for @worldCupInfoAction.
  ///
  /// In en, this message translates to:
  /// **'Guide'**
  String get worldCupInfoAction;

  /// No description provided for @worldCupShareTooltip.
  ///
  /// In en, this message translates to:
  /// **'Share World Cup page'**
  String get worldCupShareTooltip;

  /// No description provided for @worldCupShareMessage.
  ///
  /// In en, this message translates to:
  /// **'Follow the 2026 World Cup schedule, standings, and tournament bracket on Taeo Note.\n{url}'**
  String worldCupShareMessage(String url);

  /// No description provided for @worldCupShareOpenedSnack.
  ///
  /// In en, this message translates to:
  /// **'World Cup share is ready.'**
  String get worldCupShareOpenedSnack;

  /// No description provided for @worldCupShareFailedSnack.
  ///
  /// In en, this message translates to:
  /// **'Could not open World Cup sharing.'**
  String get worldCupShareFailedSnack;

  /// No description provided for @worldCupPdfAction.
  ///
  /// In en, this message translates to:
  /// **'PDF'**
  String get worldCupPdfAction;

  /// No description provided for @worldCupImageAction.
  ///
  /// In en, this message translates to:
  /// **'Image'**
  String get worldCupImageAction;

  /// No description provided for @worldCupSourceShortAction.
  ///
  /// In en, this message translates to:
  /// **'FIFA'**
  String get worldCupSourceShortAction;

  /// No description provided for @worldCupHeroTitle.
  ///
  /// In en, this message translates to:
  /// **'FIFA World Cup 2026'**
  String get worldCupHeroTitle;

  /// No description provided for @worldCupHeroSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Canada, Mexico, United States · 48 teams'**
  String get worldCupHeroSubtitle;

  /// No description provided for @worldCupCountdownDays.
  ///
  /// In en, this message translates to:
  /// **'{days} days left'**
  String worldCupCountdownDays(int days);

  /// No description provided for @worldCupCountdownToday.
  ///
  /// In en, this message translates to:
  /// **'Opening day'**
  String get worldCupCountdownToday;

  /// No description provided for @worldCupCountdownStarted.
  ///
  /// In en, this message translates to:
  /// **'Tournament underway'**
  String get worldCupCountdownStarted;

  /// No description provided for @worldCupCountdownComplete.
  ///
  /// In en, this message translates to:
  /// **'Tournament complete'**
  String get worldCupCountdownComplete;

  /// No description provided for @worldCupScheduleTab.
  ///
  /// In en, this message translates to:
  /// **'Schedule'**
  String get worldCupScheduleTab;

  /// No description provided for @worldCupStandingsTab.
  ///
  /// In en, this message translates to:
  /// **'Standings'**
  String get worldCupStandingsTab;

  /// No description provided for @worldCupTournamentTab.
  ///
  /// In en, this message translates to:
  /// **'Tournament'**
  String get worldCupTournamentTab;

  /// No description provided for @worldCupOverviewTitle.
  ///
  /// In en, this message translates to:
  /// **'Tournament overview'**
  String get worldCupOverviewTitle;

  /// No description provided for @worldCupOverviewIntro.
  ///
  /// In en, this message translates to:
  /// **'This World Cup is bigger than before: 48 countries, 12 groups, and 104 matches across Canada, Mexico, and the United States.'**
  String get worldCupOverviewIntro;

  /// No description provided for @worldCupHostsLabel.
  ///
  /// In en, this message translates to:
  /// **'Hosts'**
  String get worldCupHostsLabel;

  /// No description provided for @worldCupHostsValue.
  ///
  /// In en, this message translates to:
  /// **'Canada · Mexico · United States'**
  String get worldCupHostsValue;

  /// No description provided for @worldCupDatesLabel.
  ///
  /// In en, this message translates to:
  /// **'Dates'**
  String get worldCupDatesLabel;

  /// No description provided for @worldCupDateRange.
  ///
  /// In en, this message translates to:
  /// **'{start} - {end}'**
  String worldCupDateRange(String start, String end);

  /// No description provided for @worldCupFormatLabel.
  ///
  /// In en, this message translates to:
  /// **'Format'**
  String get worldCupFormatLabel;

  /// No description provided for @worldCupFormatValue.
  ///
  /// In en, this message translates to:
  /// **'48 teams · 12 groups'**
  String get worldCupFormatValue;

  /// No description provided for @worldCupMatchesLabel.
  ///
  /// In en, this message translates to:
  /// **'Matches'**
  String get worldCupMatchesLabel;

  /// No description provided for @worldCupMatchesValue.
  ///
  /// In en, this message translates to:
  /// **'104 fixtures across 16 host cities'**
  String get worldCupMatchesValue;

  /// No description provided for @worldCupMatchesCountValue.
  ///
  /// In en, this message translates to:
  /// **'{count} fixtures across 16 host cities'**
  String worldCupMatchesCountValue(int count);

  /// No description provided for @worldCupGuideFormatTitle.
  ///
  /// In en, this message translates to:
  /// **'How this World Cup works'**
  String get worldCupGuideFormatTitle;

  /// No description provided for @worldCupGuideFormatBullets.
  ///
  /// In en, this message translates to:
  /// **'48 countries are split into 12 groups of 4.\nEach country plays 3 group matches.\nThe top 2 teams in every group move on, plus the 8 best third-place teams.\nAfter that, the Round of 32 begins and one loss means elimination.'**
  String get worldCupGuideFormatBullets;

  /// No description provided for @worldCupGuideMatchRulesTitle.
  ///
  /// In en, this message translates to:
  /// **'Match rules'**
  String get worldCupGuideMatchRulesTitle;

  /// No description provided for @worldCupGuideMatchRulesBullets.
  ///
  /// In en, this message translates to:
  /// **'A normal match has two 45-minute halves.\nGroup matches can finish as a draw, so both teams may earn 1 point.\nIn knockout matches, a draw after 90 minutes goes to extra time, then penalties if still tied.\nA win is 3 points, a draw is 1 point, and a loss is 0 points in the group stage.'**
  String get worldCupGuideMatchRulesBullets;

  /// No description provided for @worldCupGuideTiebreakTitle.
  ///
  /// In en, this message translates to:
  /// **'How ties are broken'**
  String get worldCupGuideTiebreakTitle;

  /// No description provided for @worldCupGuideTiebreakBullets.
  ///
  /// In en, this message translates to:
  /// **'Teams are ranked by points first.\nIf teams in the same group are tied, FIFA checks head-to-head points, head-to-head goal difference, and head-to-head goals.\nIf they are still tied, FIFA checks overall goal difference, overall goals, team conduct score, and then the latest FIFA ranking.\nThe 8 best third-place teams are compared by points, goal difference, goals scored, team conduct score, and FIFA ranking.'**
  String get worldCupGuideTiebreakBullets;

  /// No description provided for @worldCupGuideRefereeTitle.
  ///
  /// In en, this message translates to:
  /// **'Referees and helpers'**
  String get worldCupGuideRefereeTitle;

  /// No description provided for @worldCupGuideRefereeBullets.
  ///
  /// In en, this message translates to:
  /// **'FIFA selected 52 referees, 88 assistant referees, and 30 video match officials for the tournament.\nOn the field, a referee leads the match with two assistant referees, a fourth official, and reserve help when appointed.\nAssistant referees help with offside, throw-ins, goal kicks, corner kicks, substitutions, and penalty-kick details.\nThe referee always makes the final decision.'**
  String get worldCupGuideRefereeBullets;

  /// No description provided for @worldCupGuideVarTitle.
  ///
  /// In en, this message translates to:
  /// **'VAR and technology'**
  String get worldCupGuideVarTitle;

  /// No description provided for @worldCupGuideVarBullets.
  ///
  /// In en, this message translates to:
  /// **'VAR means Video Assistant Referee.\nVAR checks big match-changing moments such as goal/no goal, penalty/no penalty, direct red card, and mistaken identity.\nThe referee can watch the screen for an on-field review, but the referee still makes the final call.\nGoal-line technology, advanced semi-automated offside support, and connected-ball technology help officials make faster factual decisions.'**
  String get worldCupGuideVarBullets;

  /// No description provided for @worldCupTeamSettingsTitle.
  ///
  /// In en, this message translates to:
  /// **'My World Cup teams'**
  String get worldCupTeamSettingsTitle;

  /// No description provided for @worldCupSupportCountryLabel.
  ///
  /// In en, this message translates to:
  /// **'Cheering country'**
  String get worldCupSupportCountryLabel;

  /// No description provided for @worldCupInterestCountriesLabel.
  ///
  /// In en, this message translates to:
  /// **'Interest countries'**
  String get worldCupInterestCountriesLabel;

  /// No description provided for @worldCupInterestCountriesEmpty.
  ///
  /// In en, this message translates to:
  /// **'No interest countries selected yet.'**
  String get worldCupInterestCountriesEmpty;

  /// No description provided for @worldCupEditInterestCountriesAction.
  ///
  /// In en, this message translates to:
  /// **'Edit countries'**
  String get worldCupEditInterestCountriesAction;

  /// No description provided for @worldCupClearInterestCountriesAction.
  ///
  /// In en, this message translates to:
  /// **'Clear'**
  String get worldCupClearInterestCountriesAction;

  /// No description provided for @worldCupSelectedCountriesOnly.
  ///
  /// In en, this message translates to:
  /// **'Show selected countries only'**
  String get worldCupSelectedCountriesOnly;

  /// No description provided for @worldCupHighlightedMatchesTitle.
  ///
  /// In en, this message translates to:
  /// **'Selected-country fixtures'**
  String get worldCupHighlightedMatchesTitle;

  /// No description provided for @worldCupNoHighlightedMatches.
  ///
  /// In en, this message translates to:
  /// **'Choose a cheering country or interest countries to highlight their fixtures.'**
  String get worldCupNoHighlightedMatches;

  /// No description provided for @worldCupCalendarTitle.
  ///
  /// In en, this message translates to:
  /// **'Full fixture calendar'**
  String get worldCupCalendarTitle;

  /// No description provided for @worldCupDayMatchesTitle.
  ///
  /// In en, this message translates to:
  /// **'{date} · {count} fixtures'**
  String worldCupDayMatchesTitle(String date, int count);

  /// No description provided for @worldCupNoMatchesOnDay.
  ///
  /// In en, this message translates to:
  /// **'No fixtures on this day.'**
  String get worldCupNoMatchesOnDay;

  /// No description provided for @worldCupMatchNumber.
  ///
  /// In en, this message translates to:
  /// **'M{number}'**
  String worldCupMatchNumber(int number);

  /// No description provided for @worldCupVersusShort.
  ///
  /// In en, this message translates to:
  /// **'v'**
  String get worldCupVersusShort;

  /// No description provided for @worldCupMatchScheduled.
  ///
  /// In en, this message translates to:
  /// **'Scheduled'**
  String get worldCupMatchScheduled;

  /// No description provided for @worldCupMatchLive.
  ///
  /// In en, this message translates to:
  /// **'Live'**
  String get worldCupMatchLive;

  /// No description provided for @worldCupMatchAwaitingUpdate.
  ///
  /// In en, this message translates to:
  /// **'Awaiting result update'**
  String get worldCupMatchAwaitingUpdate;

  /// No description provided for @worldCupMatchAwaitingUpdateReason.
  ///
  /// In en, this message translates to:
  /// **'The estimated final whistle has passed, but FIFA official results have not been reflected yet. Refresh or check the official page.'**
  String get worldCupMatchAwaitingUpdateReason;

  /// No description provided for @worldCupMatchResultFinal.
  ///
  /// In en, this message translates to:
  /// **'Result'**
  String get worldCupMatchResultFinal;

  /// No description provided for @worldCupFifaRankingCompactLabel.
  ///
  /// In en, this message translates to:
  /// **'FIFA #{rank}'**
  String worldCupFifaRankingCompactLabel(int rank);

  /// No description provided for @worldCupMatchDetailTitle.
  ///
  /// In en, this message translates to:
  /// **'Match details'**
  String get worldCupMatchDetailTitle;

  /// No description provided for @worldCupMatchComparisonTitle.
  ///
  /// In en, this message translates to:
  /// **'Team comparison'**
  String get worldCupMatchComparisonTitle;

  /// No description provided for @worldCupMatchRecordsTitle.
  ///
  /// In en, this message translates to:
  /// **'Match records'**
  String get worldCupMatchRecordsTitle;

  /// No description provided for @worldCupMatchRecordUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Live match records will appear as official data becomes available.'**
  String get worldCupMatchRecordUnavailable;

  /// No description provided for @worldCupMatchDetailLoading.
  ///
  /// In en, this message translates to:
  /// **'Loading FIFA match data...'**
  String get worldCupMatchDetailLoading;

  /// No description provided for @worldCupMatchScorersTitle.
  ///
  /// In en, this message translates to:
  /// **'Scorers'**
  String get worldCupMatchScorersTitle;

  /// No description provided for @worldCupMatchLineupsTitle.
  ///
  /// In en, this message translates to:
  /// **'Lineups'**
  String get worldCupMatchLineupsTitle;

  /// No description provided for @worldCupStartingPlayersLabel.
  ///
  /// In en, this message translates to:
  /// **'Starting XI'**
  String get worldCupStartingPlayersLabel;

  /// No description provided for @worldCupBenchPlayersLabel.
  ///
  /// In en, this message translates to:
  /// **'Bench'**
  String get worldCupBenchPlayersLabel;

  /// No description provided for @worldCupCaptainAbbreviation.
  ///
  /// In en, this message translates to:
  /// **'(C)'**
  String get worldCupCaptainAbbreviation;

  /// No description provided for @worldCupOfficialSourceNote.
  ///
  /// In en, this message translates to:
  /// **'Scores, player lists, and match records are refreshed from FIFA data when this page opens.'**
  String get worldCupOfficialSourceNote;

  /// No description provided for @worldCupMatchPossessionLabel.
  ///
  /// In en, this message translates to:
  /// **'Possession'**
  String get worldCupMatchPossessionLabel;

  /// No description provided for @worldCupMatchPossessionValue.
  ///
  /// In en, this message translates to:
  /// **'{home}% · {away}%'**
  String worldCupMatchPossessionValue(int home, int away);

  /// No description provided for @worldCupMatchAttendanceLabel.
  ///
  /// In en, this message translates to:
  /// **'Attendance'**
  String get worldCupMatchAttendanceLabel;

  /// No description provided for @worldCupMatchTacticsLabel.
  ///
  /// In en, this message translates to:
  /// **'Tactics'**
  String get worldCupMatchTacticsLabel;

  /// No description provided for @worldCupPlayerProfileTitle.
  ///
  /// In en, this message translates to:
  /// **'{player} profile'**
  String worldCupPlayerProfileTitle(String player);

  /// No description provided for @worldCupClubInfoOpenTooltip.
  ///
  /// In en, this message translates to:
  /// **'Open {club} info'**
  String worldCupClubInfoOpenTooltip(String club);

  /// No description provided for @worldCupClubHomepageOpenTooltip.
  ///
  /// In en, this message translates to:
  /// **'Open {club} official website'**
  String worldCupClubHomepageOpenTooltip(String club);

  /// No description provided for @worldCupClubInfoTitle.
  ///
  /// In en, this message translates to:
  /// **'{club} info'**
  String worldCupClubInfoTitle(String club);

  /// No description provided for @worldCupPlayerProfilePlayerLabel.
  ///
  /// In en, this message translates to:
  /// **'Player'**
  String get worldCupPlayerProfilePlayerLabel;

  /// No description provided for @worldCupPlayerProfileTeamLabel.
  ///
  /// In en, this message translates to:
  /// **'National team'**
  String get worldCupPlayerProfileTeamLabel;

  /// No description provided for @worldCupPlayerProfilePositionLabel.
  ///
  /// In en, this message translates to:
  /// **'Position'**
  String get worldCupPlayerProfilePositionLabel;

  /// No description provided for @worldCupPlayerProfileClubLabel.
  ///
  /// In en, this message translates to:
  /// **'Club'**
  String get worldCupPlayerProfileClubLabel;

  /// No description provided for @worldCupPlayerClubPending.
  ///
  /// In en, this message translates to:
  /// **'Club update pending'**
  String get worldCupPlayerClubPending;

  /// No description provided for @worldCupScorePending.
  ///
  /// In en, this message translates to:
  /// **'- : -'**
  String get worldCupScorePending;

  /// No description provided for @worldCupScoreLine.
  ///
  /// In en, this message translates to:
  /// **'{homeScore} : {awayScore}'**
  String worldCupScoreLine(int homeScore, int awayScore);

  /// No description provided for @worldCupScorePenaltyLine.
  ///
  /// In en, this message translates to:
  /// **'PSO {homePenaltyScore} : {awayPenaltyScore}'**
  String worldCupScorePenaltyLine(int homePenaltyScore, int awayPenaltyScore);

  /// No description provided for @worldCupResultPendingTeam.
  ///
  /// In en, this message translates to:
  /// **'Kickoff pending'**
  String get worldCupResultPendingTeam;

  /// No description provided for @worldCupResultWin.
  ///
  /// In en, this message translates to:
  /// **'W'**
  String get worldCupResultWin;

  /// No description provided for @worldCupResultDraw.
  ///
  /// In en, this message translates to:
  /// **'D'**
  String get worldCupResultDraw;

  /// No description provided for @worldCupResultLoss.
  ///
  /// In en, this message translates to:
  /// **'L'**
  String get worldCupResultLoss;

  /// No description provided for @worldCupResultWinSummary.
  ///
  /// In en, this message translates to:
  /// **'Win'**
  String get worldCupResultWinSummary;

  /// No description provided for @worldCupResultDrawSummary.
  ///
  /// In en, this message translates to:
  /// **'Draw'**
  String get worldCupResultDrawSummary;

  /// No description provided for @worldCupResultLossSummary.
  ///
  /// In en, this message translates to:
  /// **'Loss'**
  String get worldCupResultLossSummary;

  /// No description provided for @worldCupGroupStageLabel.
  ///
  /// In en, this message translates to:
  /// **'Group {group}'**
  String worldCupGroupStageLabel(String group);

  /// No description provided for @worldCupRoundOf32Label.
  ///
  /// In en, this message translates to:
  /// **'Round of 32'**
  String get worldCupRoundOf32Label;

  /// No description provided for @worldCupRoundOf16Label.
  ///
  /// In en, this message translates to:
  /// **'Round of 16'**
  String get worldCupRoundOf16Label;

  /// No description provided for @worldCupQuarterFinalLabel.
  ///
  /// In en, this message translates to:
  /// **'Quarter-final'**
  String get worldCupQuarterFinalLabel;

  /// No description provided for @worldCupSemiFinalLabel.
  ///
  /// In en, this message translates to:
  /// **'Semi-final'**
  String get worldCupSemiFinalLabel;

  /// No description provided for @worldCupThirdPlaceLabel.
  ///
  /// In en, this message translates to:
  /// **'Third place'**
  String get worldCupThirdPlaceLabel;

  /// No description provided for @worldCupFinalLabel.
  ///
  /// In en, this message translates to:
  /// **'Final'**
  String get worldCupFinalLabel;

  /// No description provided for @worldCupCountryAlgeria.
  ///
  /// In en, this message translates to:
  /// **'Algeria'**
  String get worldCupCountryAlgeria;

  /// No description provided for @worldCupCountryArgentina.
  ///
  /// In en, this message translates to:
  /// **'Argentina'**
  String get worldCupCountryArgentina;

  /// No description provided for @worldCupCountryAustralia.
  ///
  /// In en, this message translates to:
  /// **'Australia'**
  String get worldCupCountryAustralia;

  /// No description provided for @worldCupCountryAustria.
  ///
  /// In en, this message translates to:
  /// **'Austria'**
  String get worldCupCountryAustria;

  /// No description provided for @worldCupCountryBelgium.
  ///
  /// In en, this message translates to:
  /// **'Belgium'**
  String get worldCupCountryBelgium;

  /// No description provided for @worldCupCountryBosniaAndHerzegovina.
  ///
  /// In en, this message translates to:
  /// **'Bosnia and Herzegovina'**
  String get worldCupCountryBosniaAndHerzegovina;

  /// No description provided for @worldCupCountryBrazil.
  ///
  /// In en, this message translates to:
  /// **'Brazil'**
  String get worldCupCountryBrazil;

  /// No description provided for @worldCupCountryCanada.
  ///
  /// In en, this message translates to:
  /// **'Canada'**
  String get worldCupCountryCanada;

  /// No description provided for @worldCupCountryCapeVerde.
  ///
  /// In en, this message translates to:
  /// **'Cape Verde'**
  String get worldCupCountryCapeVerde;

  /// No description provided for @worldCupCountryColombia.
  ///
  /// In en, this message translates to:
  /// **'Colombia'**
  String get worldCupCountryColombia;

  /// No description provided for @worldCupCountryCongoDr.
  ///
  /// In en, this message translates to:
  /// **'Congo DR'**
  String get worldCupCountryCongoDr;

  /// No description provided for @worldCupCountryCroatia.
  ///
  /// In en, this message translates to:
  /// **'Croatia'**
  String get worldCupCountryCroatia;

  /// No description provided for @worldCupCountryCuracao.
  ///
  /// In en, this message translates to:
  /// **'Curacao'**
  String get worldCupCountryCuracao;

  /// No description provided for @worldCupCountryCzechia.
  ///
  /// In en, this message translates to:
  /// **'Czechia'**
  String get worldCupCountryCzechia;

  /// No description provided for @worldCupCountryEcuador.
  ///
  /// In en, this message translates to:
  /// **'Ecuador'**
  String get worldCupCountryEcuador;

  /// No description provided for @worldCupCountryEgypt.
  ///
  /// In en, this message translates to:
  /// **'Egypt'**
  String get worldCupCountryEgypt;

  /// No description provided for @worldCupCountryEngland.
  ///
  /// In en, this message translates to:
  /// **'England'**
  String get worldCupCountryEngland;

  /// No description provided for @worldCupCountryFrance.
  ///
  /// In en, this message translates to:
  /// **'France'**
  String get worldCupCountryFrance;

  /// No description provided for @worldCupCountryGermany.
  ///
  /// In en, this message translates to:
  /// **'Germany'**
  String get worldCupCountryGermany;

  /// No description provided for @worldCupCountryGhana.
  ///
  /// In en, this message translates to:
  /// **'Ghana'**
  String get worldCupCountryGhana;

  /// No description provided for @worldCupCountryHaiti.
  ///
  /// In en, this message translates to:
  /// **'Haiti'**
  String get worldCupCountryHaiti;

  /// No description provided for @worldCupCountryIran.
  ///
  /// In en, this message translates to:
  /// **'Iran'**
  String get worldCupCountryIran;

  /// No description provided for @worldCupCountryIraq.
  ///
  /// In en, this message translates to:
  /// **'Iraq'**
  String get worldCupCountryIraq;

  /// No description provided for @worldCupCountryIvoryCoast.
  ///
  /// In en, this message translates to:
  /// **'Ivory Coast'**
  String get worldCupCountryIvoryCoast;

  /// No description provided for @worldCupCountryJapan.
  ///
  /// In en, this message translates to:
  /// **'Japan'**
  String get worldCupCountryJapan;

  /// No description provided for @worldCupCountryJordan.
  ///
  /// In en, this message translates to:
  /// **'Jordan'**
  String get worldCupCountryJordan;

  /// No description provided for @worldCupCountryKoreaRepublic.
  ///
  /// In en, this message translates to:
  /// **'Korea Republic'**
  String get worldCupCountryKoreaRepublic;

  /// No description provided for @worldCupCountryMexico.
  ///
  /// In en, this message translates to:
  /// **'Mexico'**
  String get worldCupCountryMexico;

  /// No description provided for @worldCupCountryMorocco.
  ///
  /// In en, this message translates to:
  /// **'Morocco'**
  String get worldCupCountryMorocco;

  /// No description provided for @worldCupCountryNetherlands.
  ///
  /// In en, this message translates to:
  /// **'Netherlands'**
  String get worldCupCountryNetherlands;

  /// No description provided for @worldCupCountryNewZealand.
  ///
  /// In en, this message translates to:
  /// **'New Zealand'**
  String get worldCupCountryNewZealand;

  /// No description provided for @worldCupCountryNorway.
  ///
  /// In en, this message translates to:
  /// **'Norway'**
  String get worldCupCountryNorway;

  /// No description provided for @worldCupCountryPanama.
  ///
  /// In en, this message translates to:
  /// **'Panama'**
  String get worldCupCountryPanama;

  /// No description provided for @worldCupCountryParaguay.
  ///
  /// In en, this message translates to:
  /// **'Paraguay'**
  String get worldCupCountryParaguay;

  /// No description provided for @worldCupCountryPortugal.
  ///
  /// In en, this message translates to:
  /// **'Portugal'**
  String get worldCupCountryPortugal;

  /// No description provided for @worldCupCountryQatar.
  ///
  /// In en, this message translates to:
  /// **'Qatar'**
  String get worldCupCountryQatar;

  /// No description provided for @worldCupCountrySaudiArabia.
  ///
  /// In en, this message translates to:
  /// **'Saudi Arabia'**
  String get worldCupCountrySaudiArabia;

  /// No description provided for @worldCupCountryScotland.
  ///
  /// In en, this message translates to:
  /// **'Scotland'**
  String get worldCupCountryScotland;

  /// No description provided for @worldCupCountrySenegal.
  ///
  /// In en, this message translates to:
  /// **'Senegal'**
  String get worldCupCountrySenegal;

  /// No description provided for @worldCupCountrySouthAfrica.
  ///
  /// In en, this message translates to:
  /// **'South Africa'**
  String get worldCupCountrySouthAfrica;

  /// No description provided for @worldCupCountrySpain.
  ///
  /// In en, this message translates to:
  /// **'Spain'**
  String get worldCupCountrySpain;

  /// No description provided for @worldCupCountrySweden.
  ///
  /// In en, this message translates to:
  /// **'Sweden'**
  String get worldCupCountrySweden;

  /// No description provided for @worldCupCountrySwitzerland.
  ///
  /// In en, this message translates to:
  /// **'Switzerland'**
  String get worldCupCountrySwitzerland;

  /// No description provided for @worldCupCountryTunisia.
  ///
  /// In en, this message translates to:
  /// **'Tunisia'**
  String get worldCupCountryTunisia;

  /// No description provided for @worldCupCountryTurkiye.
  ///
  /// In en, this message translates to:
  /// **'Turkiye'**
  String get worldCupCountryTurkiye;

  /// No description provided for @worldCupCountryUsa.
  ///
  /// In en, this message translates to:
  /// **'USA'**
  String get worldCupCountryUsa;

  /// No description provided for @worldCupCountryUruguay.
  ///
  /// In en, this message translates to:
  /// **'Uruguay'**
  String get worldCupCountryUruguay;

  /// No description provided for @worldCupCountryUzbekistan.
  ///
  /// In en, this message translates to:
  /// **'Uzbekistan'**
  String get worldCupCountryUzbekistan;

  /// No description provided for @worldCupVenueAttDallas.
  ///
  /// In en, this message translates to:
  /// **'AT&T Stadium, Dallas'**
  String get worldCupVenueAttDallas;

  /// No description provided for @worldCupVenueBcPlaceVancouver.
  ///
  /// In en, this message translates to:
  /// **'BC Place, Vancouver'**
  String get worldCupVenueBcPlaceVancouver;

  /// No description provided for @worldCupVenueBmoFieldToronto.
  ///
  /// In en, this message translates to:
  /// **'BMO Field, Toronto'**
  String get worldCupVenueBmoFieldToronto;

  /// No description provided for @worldCupVenueEstadioAkronGuadalajara.
  ///
  /// In en, this message translates to:
  /// **'Estadio Akron, Guadalajara'**
  String get worldCupVenueEstadioAkronGuadalajara;

  /// No description provided for @worldCupVenueEstadioAztecaMexicoCity.
  ///
  /// In en, this message translates to:
  /// **'Estadio Azteca, Mexico City'**
  String get worldCupVenueEstadioAztecaMexicoCity;

  /// No description provided for @worldCupVenueEstadioBbvaMonterrey.
  ///
  /// In en, this message translates to:
  /// **'Estadio BBVA, Monterrey'**
  String get worldCupVenueEstadioBbvaMonterrey;

  /// No description provided for @worldCupVenueGehaArrowheadKansasCity.
  ///
  /// In en, this message translates to:
  /// **'GEHA Field at Arrowhead Stadium, Kansas City'**
  String get worldCupVenueGehaArrowheadKansasCity;

  /// No description provided for @worldCupVenueGilletteBoston.
  ///
  /// In en, this message translates to:
  /// **'Gillette Stadium, Boston'**
  String get worldCupVenueGilletteBoston;

  /// No description provided for @worldCupVenueHardRockMiami.
  ///
  /// In en, this message translates to:
  /// **'Hard Rock Stadium, Miami'**
  String get worldCupVenueHardRockMiami;

  /// No description provided for @worldCupVenueLevisSanFranciscoBayArea.
  ///
  /// In en, this message translates to:
  /// **'Levi\'s Stadium, San Francisco Bay Area'**
  String get worldCupVenueLevisSanFranciscoBayArea;

  /// No description provided for @worldCupVenueLincolnFinancialPhiladelphia.
  ///
  /// In en, this message translates to:
  /// **'Lincoln Financial Field, Philadelphia'**
  String get worldCupVenueLincolnFinancialPhiladelphia;

  /// No description provided for @worldCupVenueLumenSeattle.
  ///
  /// In en, this message translates to:
  /// **'Lumen Field, Seattle'**
  String get worldCupVenueLumenSeattle;

  /// No description provided for @worldCupVenueMercedesBenzAtlanta.
  ///
  /// In en, this message translates to:
  /// **'Mercedes-Benz Stadium, Atlanta'**
  String get worldCupVenueMercedesBenzAtlanta;

  /// No description provided for @worldCupVenueMetLifeNewYorkNewJersey.
  ///
  /// In en, this message translates to:
  /// **'MetLife Stadium, New York/New Jersey'**
  String get worldCupVenueMetLifeNewYorkNewJersey;

  /// No description provided for @worldCupVenueNrgHouston.
  ///
  /// In en, this message translates to:
  /// **'NRG Stadium, Houston'**
  String get worldCupVenueNrgHouston;

  /// No description provided for @worldCupVenueSofiLosAngeles.
  ///
  /// In en, this message translates to:
  /// **'SoFi Stadium, Los Angeles'**
  String get worldCupVenueSofiLosAngeles;

  /// No description provided for @worldCupKickoffLocal.
  ///
  /// In en, this message translates to:
  /// **'{time} local time'**
  String worldCupKickoffLocal(String time);

  /// No description provided for @worldCupSupportBadge.
  ///
  /// In en, this message translates to:
  /// **'Cheering'**
  String get worldCupSupportBadge;

  /// No description provided for @worldCupInterestBadge.
  ///
  /// In en, this message translates to:
  /// **'Interest'**
  String get worldCupInterestBadge;

  /// No description provided for @worldCupKoreaTitle.
  ///
  /// In en, this message translates to:
  /// **'Korea Republic watch'**
  String get worldCupKoreaTitle;

  /// No description provided for @worldCupKoreaBody.
  ///
  /// In en, this message translates to:
  /// **'Korea Republic starts in Group A and opens against Czechia in Guadalajara.'**
  String get worldCupKoreaBody;

  /// No description provided for @worldCupKoreaGroupLabel.
  ///
  /// In en, this message translates to:
  /// **'Group'**
  String get worldCupKoreaGroupLabel;

  /// No description provided for @worldCupKoreaGroup.
  ///
  /// In en, this message translates to:
  /// **'Group A'**
  String get worldCupKoreaGroup;

  /// No description provided for @worldCupKoreaOpenerLabel.
  ///
  /// In en, this message translates to:
  /// **'Opener'**
  String get worldCupKoreaOpenerLabel;

  /// No description provided for @worldCupKoreaOpener.
  ///
  /// In en, this message translates to:
  /// **'Korea Republic v Czechia · Estadio Guadalajara'**
  String get worldCupKoreaOpener;

  /// No description provided for @worldCupMilestonesTitle.
  ///
  /// In en, this message translates to:
  /// **'Road to the final'**
  String get worldCupMilestonesTitle;

  /// No description provided for @worldCupMilestoneOpeningLabel.
  ///
  /// In en, this message translates to:
  /// **'Opening match'**
  String get worldCupMilestoneOpeningLabel;

  /// No description provided for @worldCupOpeningMatch.
  ///
  /// In en, this message translates to:
  /// **'Mexico v South Africa · 11 Jun 2026 · Mexico City Stadium'**
  String get worldCupOpeningMatch;

  /// No description provided for @worldCupMilestoneGroupLabel.
  ///
  /// In en, this message translates to:
  /// **'Group stage'**
  String get worldCupMilestoneGroupLabel;

  /// No description provided for @worldCupGroupStage.
  ///
  /// In en, this message translates to:
  /// **'Group matches start on 11 Jun and build the 32-team knockout bracket.'**
  String get worldCupGroupStage;

  /// No description provided for @worldCupMilestoneKnockoutLabel.
  ///
  /// In en, this message translates to:
  /// **'Knockout rounds'**
  String get worldCupMilestoneKnockoutLabel;

  /// No description provided for @worldCupKnockouts.
  ///
  /// In en, this message translates to:
  /// **'The round of 32 starts after the group stage.'**
  String get worldCupKnockouts;

  /// No description provided for @worldCupMilestoneFinalLabel.
  ///
  /// In en, this message translates to:
  /// **'Final'**
  String get worldCupMilestoneFinalLabel;

  /// No description provided for @worldCupFinalMatch.
  ///
  /// In en, this message translates to:
  /// **'19 Jul 2026 · New York New Jersey Stadium'**
  String get worldCupFinalMatch;

  /// No description provided for @worldCupStandingsTitle.
  ///
  /// In en, this message translates to:
  /// **'Group standings'**
  String get worldCupStandingsTitle;

  /// No description provided for @worldCupStandingsPlanBody.
  ///
  /// In en, this message translates to:
  /// **'Group rankings update from the fixture scores already in the schedule. Teams are ordered by points, goal difference, goals, wins, losses, then country name until official tie-break data is available.'**
  String get worldCupStandingsPlanBody;

  /// No description provided for @worldCupStandingsRuleLabel.
  ///
  /// In en, this message translates to:
  /// **'Tiebreak order'**
  String get worldCupStandingsRuleLabel;

  /// No description provided for @worldCupStandingsRuleValue.
  ///
  /// In en, this message translates to:
  /// **'Points · goal difference · goals for · wins · losses · team name'**
  String get worldCupStandingsRuleValue;

  /// No description provided for @worldCupStandingsTieGuide.
  ///
  /// In en, this message translates to:
  /// **'When points are tied, goal difference breaks the tie first; if that is still level, goals for decides the order.'**
  String get worldCupStandingsTieGuide;

  /// No description provided for @worldCupStandingsTableTitle.
  ///
  /// In en, this message translates to:
  /// **'Group table'**
  String get worldCupStandingsTableTitle;

  /// No description provided for @worldCupStandingsRankColumn.
  ///
  /// In en, this message translates to:
  /// **'Rk'**
  String get worldCupStandingsRankColumn;

  /// No description provided for @worldCupStandingsTeamColumn.
  ///
  /// In en, this message translates to:
  /// **'Team'**
  String get worldCupStandingsTeamColumn;

  /// No description provided for @worldCupStandingsRecordColumn.
  ///
  /// In en, this message translates to:
  /// **'W-D-L'**
  String get worldCupStandingsRecordColumn;

  /// No description provided for @worldCupStandingsGoalDifferenceColumn.
  ///
  /// In en, this message translates to:
  /// **'GD'**
  String get worldCupStandingsGoalDifferenceColumn;

  /// No description provided for @worldCupStandingsGoalsForColumn.
  ///
  /// In en, this message translates to:
  /// **'GF'**
  String get worldCupStandingsGoalsForColumn;

  /// No description provided for @worldCupStandingsPointsColumn.
  ///
  /// In en, this message translates to:
  /// **'Pts'**
  String get worldCupStandingsPointsColumn;

  /// No description provided for @worldCupStandingsRecordValue.
  ///
  /// In en, this message translates to:
  /// **'{wins}-{draws}-{losses}'**
  String worldCupStandingsRecordValue(int wins, int draws, int losses);

  /// No description provided for @worldCupStandingsTieReasonValue.
  ///
  /// In en, this message translates to:
  /// **'Tie-break: GD {goalDifference} · GF {goalsFor}'**
  String worldCupStandingsTieReasonValue(String goalDifference, int goalsFor);

  /// No description provided for @worldCupGroupTeamsTitle.
  ///
  /// In en, this message translates to:
  /// **'Group teams'**
  String get worldCupGroupTeamsTitle;

  /// No description provided for @worldCupTeamRosterOpenTooltip.
  ///
  /// In en, this message translates to:
  /// **'Open {team} roster'**
  String worldCupTeamRosterOpenTooltip(String team);

  /// No description provided for @worldCupTeamRosterTitle.
  ///
  /// In en, this message translates to:
  /// **'{team} roster'**
  String worldCupTeamRosterTitle(String team);

  /// No description provided for @worldCupTeamRosterSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Build your own best XI and formation from the position groups.'**
  String get worldCupTeamRosterSubtitle;

  /// No description provided for @worldCupTeamHistoryTitle.
  ///
  /// In en, this message translates to:
  /// **'Football history and context'**
  String get worldCupTeamHistoryTitle;

  /// No description provided for @worldCupTeamHistoryBody.
  ///
  /// In en, this message translates to:
  /// **'{team}\'s football story is shaped by its national-team tournament experience, domestic league base, overseas-player pipeline, and World Cup qualifying record. This view brings the group fixtures, points, and player clubs together so you can read how {team} may build its tournament rhythm.'**
  String worldCupTeamHistoryBody(String team);

  /// No description provided for @worldCupTeamHistoryTournamentContext.
  ///
  /// In en, this message translates to:
  /// **'In this group stage, {team} competes in {group} against {opponents}.'**
  String worldCupTeamHistoryTournamentContext(
      String team, String opponents, String group);

  /// No description provided for @worldCupTeamMatchOverviewTitle.
  ///
  /// In en, this message translates to:
  /// **'Team match info'**
  String get worldCupTeamMatchOverviewTitle;

  /// No description provided for @worldCupTeamCurrentPointsLabel.
  ///
  /// In en, this message translates to:
  /// **'Current points'**
  String get worldCupTeamCurrentPointsLabel;

  /// No description provided for @worldCupTeamMatchHistoryTitle.
  ///
  /// In en, this message translates to:
  /// **'Match results'**
  String get worldCupTeamMatchHistoryTitle;

  /// No description provided for @worldCupKnockoutPathTitle.
  ///
  /// In en, this message translates to:
  /// **'Opponents to the final'**
  String get worldCupKnockoutPathTitle;

  /// No description provided for @worldCupKnockoutPathSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Assuming this team advances through each round, these are the possible opponents on the path to the final.'**
  String get worldCupKnockoutPathSubtitle;

  /// No description provided for @worldCupKnockoutPathCandidateCount.
  ///
  /// In en, this message translates to:
  /// **'{count} candidates'**
  String worldCupKnockoutPathCandidateCount(int count);

  /// No description provided for @worldCupKnockoutPathOpponentPending.
  ///
  /// In en, this message translates to:
  /// **'Opponent to be confirmed'**
  String get worldCupKnockoutPathOpponentPending;

  /// No description provided for @worldCupKnockoutPathEliminated.
  ///
  /// In en, this message translates to:
  /// **'Eliminated here'**
  String get worldCupKnockoutPathEliminated;

  /// No description provided for @worldCupQualificationScenariosTitle.
  ///
  /// In en, this message translates to:
  /// **'Round of 32 scenarios'**
  String get worldCupQualificationScenariosTitle;

  /// No description provided for @worldCupQualificationScenariosSubtitle.
  ///
  /// In en, this message translates to:
  /// **'From {currentPoints} current points, this estimates Round of 32 paths and opponent slots for the {remainingMatches} remaining match results.'**
  String worldCupQualificationScenariosSubtitle(
      int currentPoints, int remainingMatches);

  /// No description provided for @worldCupQualificationScenariosOneMatchSubtitle.
  ///
  /// In en, this message translates to:
  /// **'From {currentPoints} current points, this shows the win/draw/loss paths for the final remaining match.'**
  String worldCupQualificationScenariosOneMatchSubtitle(int currentPoints);

  /// No description provided for @worldCupQualificationScenariosNoTeamMatchesSubtitle.
  ///
  /// In en, this message translates to:
  /// **'This team has {currentPoints} current points and no matches left. Remaining group results ({remainingOtherMatches}) still drive the Round of 32 path.'**
  String worldCupQualificationScenariosNoTeamMatchesSubtitle(
      int currentPoints, int remainingOtherMatches);

  /// No description provided for @worldCupQualificationScenariosCompleteSubtitle.
  ///
  /// In en, this message translates to:
  /// **'The group schedule is complete. This shows the Round of 32 path from the final {currentPoints} points.'**
  String worldCupQualificationScenariosCompleteSubtitle(int currentPoints);

  /// No description provided for @worldCupQualificationScenariosGuide.
  ///
  /// In en, this message translates to:
  /// **'Each row is one result combination for this team\'s remaining matches. Auto means finishing 1st or 2nd in the group. 3rd-place race means finishing 3rd, then needing to be among the 8 best third-place teams overall. The denominators for auto, 3rd-place race, and out count every win/draw/loss combination for the other remaining matches in the same group. Opponent countries translate the bracket slot using the current table.'**
  String get worldCupQualificationScenariosGuide;

  /// No description provided for @worldCupQualificationScenariosNoTeamMatchesGuide.
  ///
  /// In en, this message translates to:
  /// **'There are no result picks for this team. The denominator only counts any remaining win/draw/loss combinations elsewhere in the group; if none remain, the table is fixed.'**
  String get worldCupQualificationScenariosNoTeamMatchesGuide;

  /// No description provided for @worldCupQualificationScenariosEmpty.
  ///
  /// In en, this message translates to:
  /// **'There is not enough group-stage data to calculate Round of 32 scenarios for this team yet.'**
  String get worldCupQualificationScenariosEmpty;

  /// No description provided for @worldCupQualificationScenarioPoints.
  ///
  /// In en, this message translates to:
  /// **'+{remainingPoints} remaining pts · {finalPoints} pts total'**
  String worldCupQualificationScenarioPoints(
      int remainingPoints, int finalPoints);

  /// No description provided for @worldCupQualificationScenarioRankRange.
  ///
  /// In en, this message translates to:
  /// **'Possible rank {bestRank}-{worstRank}'**
  String worldCupQualificationScenarioRankRange(int bestRank, int worstRank);

  /// No description provided for @worldCupQualificationScenarioCases.
  ///
  /// In en, this message translates to:
  /// **'Auto {automaticCases}/{totalCases} · 3rd-place race {thirdPlaceCases}/{totalCases} · out {eliminatedCases}/{totalCases}'**
  String worldCupQualificationScenarioCases(int automaticCases,
      int thirdPlaceCases, int eliminatedCases, int totalCases);

  /// No description provided for @worldCupQualificationOtherMatchesTitle.
  ///
  /// In en, this message translates to:
  /// **'{count} other match result cases'**
  String worldCupQualificationOtherMatchesTitle(int count);

  /// No description provided for @worldCupQualificationOtherMatchesSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Even with this team\'s result fixed, other group results can change the rank and qualification state.'**
  String get worldCupQualificationOtherMatchesSubtitle;

  /// No description provided for @worldCupQualificationWaitingOtherMatchesTitle.
  ///
  /// In en, this message translates to:
  /// **'Waiting result scenarios'**
  String get worldCupQualificationWaitingOtherMatchesTitle;

  /// No description provided for @worldCupQualificationWaitingOtherMatchesSubtitle.
  ///
  /// In en, this message translates to:
  /// **'This team\'s matches are finished, so every remaining group result combination recalculates the Round of 32 state below.'**
  String get worldCupQualificationWaitingOtherMatchesSubtitle;

  /// No description provided for @worldCupQualificationOtherPathDirectSection.
  ///
  /// In en, this message translates to:
  /// **'Direct advance cases'**
  String get worldCupQualificationOtherPathDirectSection;

  /// No description provided for @worldCupQualificationOtherPathThirdSection.
  ///
  /// In en, this message translates to:
  /// **'3rd-place race cases'**
  String get worldCupQualificationOtherPathThirdSection;

  /// No description provided for @worldCupQualificationOtherPathOutSection.
  ///
  /// In en, this message translates to:
  /// **'Elimination cases'**
  String get worldCupQualificationOtherPathOutSection;

  /// No description provided for @worldCupQualificationOtherPathSectionTitle.
  ///
  /// In en, this message translates to:
  /// **'{label} · {count} cases'**
  String worldCupQualificationOtherPathSectionTitle(String label, int count);

  /// No description provided for @worldCupQualificationOtherPathOutcome.
  ///
  /// In en, this message translates to:
  /// **'Rank {rank} · {outcome}'**
  String worldCupQualificationOtherPathOutcome(int rank, String outcome);

  /// No description provided for @worldCupQualificationOtherMatchPick.
  ///
  /// In en, this message translates to:
  /// **'{home} - {away}: {result}'**
  String worldCupQualificationOtherMatchPick(
      String home, String away, String result);

  /// No description provided for @worldCupQualificationOtherMatchWinResult.
  ///
  /// In en, this message translates to:
  /// **'{team} win'**
  String worldCupQualificationOtherMatchWinResult(String team);

  /// No description provided for @worldCupQualificationOtherMatchDrawResult.
  ///
  /// In en, this message translates to:
  /// **'Draw'**
  String get worldCupQualificationOtherMatchDrawResult;

  /// No description provided for @worldCupQualificationThirdPlaceNote.
  ///
  /// In en, this message translates to:
  /// **'A third-place finish still needs to rank among the 8 best third-place teams across the 12 groups.'**
  String get worldCupQualificationThirdPlaceNote;

  /// No description provided for @worldCupQualificationNoTeamMatchesPick.
  ///
  /// In en, this message translates to:
  /// **'No team matches left'**
  String get worldCupQualificationNoTeamMatchesPick;

  /// No description provided for @worldCupQualificationCompletePick.
  ///
  /// In en, this message translates to:
  /// **'Group rank fixed'**
  String get worldCupQualificationCompletePick;

  /// No description provided for @worldCupQualificationMatchPick.
  ///
  /// In en, this message translates to:
  /// **'{result} vs {opponent}'**
  String worldCupQualificationMatchPick(String opponent, String result);

  /// No description provided for @worldCupQualificationOutcomeAuto.
  ///
  /// In en, this message translates to:
  /// **'Auto berth'**
  String get worldCupQualificationOutcomeAuto;

  /// No description provided for @worldCupQualificationOutcomePossible.
  ///
  /// In en, this message translates to:
  /// **'Can advance'**
  String get worldCupQualificationOutcomePossible;

  /// No description provided for @worldCupQualificationOutcomeThird.
  ///
  /// In en, this message translates to:
  /// **'3rd-place race'**
  String get worldCupQualificationOutcomeThird;

  /// No description provided for @worldCupQualificationOutcomeOut.
  ///
  /// In en, this message translates to:
  /// **'Out'**
  String get worldCupQualificationOutcomeOut;

  /// No description provided for @worldCupQualificationOpponentCandidates.
  ///
  /// In en, this message translates to:
  /// **'Round of 32 opponents (current table): {opponents}'**
  String worldCupQualificationOpponentCandidates(String opponents);

  /// No description provided for @worldCupQualificationNoOpponent.
  ///
  /// In en, this message translates to:
  /// **'This result path has no Round of 32 route.'**
  String get worldCupQualificationNoOpponent;

  /// No description provided for @worldCupQualificationOpponentCandidate.
  ///
  /// In en, this message translates to:
  /// **'{opponent}'**
  String worldCupQualificationOpponentCandidate(String opponent);

  /// No description provided for @worldCupQualificationOpponentCandidateWithCountries.
  ///
  /// In en, this message translates to:
  /// **'{opponent} → {countries}'**
  String worldCupQualificationOpponentCandidateWithCountries(
      String opponent, String countries);

  /// No description provided for @worldCupQualificationOpponentTeamSeparator.
  ///
  /// In en, this message translates to:
  /// **', '**
  String get worldCupQualificationOpponentTeamSeparator;

  /// No description provided for @worldCupQualificationOpponentSeparator.
  ///
  /// In en, this message translates to:
  /// **' or '**
  String get worldCupQualificationOpponentSeparator;

  /// No description provided for @worldCupTeamRosterFormationLabel.
  ///
  /// In en, this message translates to:
  /// **'{formation} formation'**
  String worldCupTeamRosterFormationLabel(String formation);

  /// No description provided for @worldCupTeamRosterBestXiTitle.
  ///
  /// In en, this message translates to:
  /// **'My best XI'**
  String get worldCupTeamRosterBestXiTitle;

  /// No description provided for @worldCupTeamRosterBestXiNote.
  ///
  /// In en, this message translates to:
  /// **'This is not an official match lineup. It is a board drawn from the formation and players you choose. Tap player rows to include or remove them.'**
  String get worldCupTeamRosterBestXiNote;

  /// No description provided for @worldCupTeamRosterFormationPickerLabel.
  ///
  /// In en, this message translates to:
  /// **'Formation'**
  String get worldCupTeamRosterFormationPickerLabel;

  /// No description provided for @worldCupTeamRosterBestXiCount.
  ///
  /// In en, this message translates to:
  /// **'{count}/11 selected'**
  String worldCupTeamRosterBestXiCount(int count);

  /// No description provided for @worldCupTeamRosterBestXiComplete.
  ///
  /// In en, this message translates to:
  /// **'Best XI complete'**
  String get worldCupTeamRosterBestXiComplete;

  /// No description provided for @worldCupTeamRosterBestXiNeedMore.
  ///
  /// In en, this message translates to:
  /// **'{count} more needed'**
  String worldCupTeamRosterBestXiNeedMore(int count);

  /// No description provided for @worldCupTeamRosterBestXiReset.
  ///
  /// In en, this message translates to:
  /// **'Auto pick'**
  String get worldCupTeamRosterBestXiReset;

  /// No description provided for @worldCupTeamRosterBestXiPositionLimit.
  ///
  /// In en, this message translates to:
  /// **'{selected}/{required}'**
  String worldCupTeamRosterBestXiPositionLimit(int selected, int required);

  /// No description provided for @worldCupTeamRosterBestXiSelectTooltip.
  ///
  /// In en, this message translates to:
  /// **'Select {player}'**
  String worldCupTeamRosterBestXiSelectTooltip(String player);

  /// No description provided for @worldCupTeamRosterBestXiRemoveTooltip.
  ///
  /// In en, this message translates to:
  /// **'Remove {player}'**
  String worldCupTeamRosterBestXiRemoveTooltip(String player);

  /// No description provided for @worldCupTeamRosterFormationEstimatedNote.
  ///
  /// In en, this message translates to:
  /// **'This is an expected formation arranged from the current squad data, not an official match lineup. Actual match tactics and starters can change.'**
  String get worldCupTeamRosterFormationEstimatedNote;

  /// No description provided for @worldCupTeamRosterFormationPlaceholderNote.
  ///
  /// In en, this message translates to:
  /// **'Official squad data is unavailable, so this uses default position slots. Do not treat it as an actual formation.'**
  String get worldCupTeamRosterFormationPlaceholderNote;

  /// No description provided for @worldCupTeamRosterSourceNote.
  ///
  /// In en, this message translates to:
  /// **'Official 2026 squad data is not bundled for this country yet, so position slots are shown until a stable legal source is connected.'**
  String get worldCupTeamRosterSourceNote;

  /// No description provided for @worldCupTeamRosterCandidateSourceNote.
  ///
  /// In en, this message translates to:
  /// **'Shown from published 2026 squad and club information. Injury replacements and match-day choices can still change before kickoff.'**
  String get worldCupTeamRosterCandidateSourceNote;

  /// No description provided for @worldCupTeamRosterGoalkeepers.
  ///
  /// In en, this message translates to:
  /// **'Goalkeepers'**
  String get worldCupTeamRosterGoalkeepers;

  /// No description provided for @worldCupTeamRosterDefenders.
  ///
  /// In en, this message translates to:
  /// **'Defenders'**
  String get worldCupTeamRosterDefenders;

  /// No description provided for @worldCupTeamRosterMidfielders.
  ///
  /// In en, this message translates to:
  /// **'Midfielders'**
  String get worldCupTeamRosterMidfielders;

  /// No description provided for @worldCupTeamRosterForwards.
  ///
  /// In en, this message translates to:
  /// **'Forwards'**
  String get worldCupTeamRosterForwards;

  /// No description provided for @worldCupTeamRosterPositionGoalkeeper.
  ///
  /// In en, this message translates to:
  /// **'GK'**
  String get worldCupTeamRosterPositionGoalkeeper;

  /// No description provided for @worldCupTeamRosterPositionDefender.
  ///
  /// In en, this message translates to:
  /// **'DF'**
  String get worldCupTeamRosterPositionDefender;

  /// No description provided for @worldCupTeamRosterPositionMidfielder.
  ///
  /// In en, this message translates to:
  /// **'MF'**
  String get worldCupTeamRosterPositionMidfielder;

  /// No description provided for @worldCupTeamRosterPositionForward.
  ///
  /// In en, this message translates to:
  /// **'FW'**
  String get worldCupTeamRosterPositionForward;

  /// No description provided for @worldCupTeamRosterPlayerSlot.
  ///
  /// In en, this message translates to:
  /// **'{position} {number}'**
  String worldCupTeamRosterPlayerSlot(String position, int number);

  /// No description provided for @worldCupTournamentTitle.
  ///
  /// In en, this message translates to:
  /// **'Tournament bracket'**
  String get worldCupTournamentTitle;

  /// No description provided for @worldCupTournamentPlanBody.
  ///
  /// In en, this message translates to:
  /// **'Confirmed ties are shown by country, with the path through the next rounds kept easy to scan.'**
  String get worldCupTournamentPlanBody;

  /// No description provided for @worldCupTournamentZoomOut.
  ///
  /// In en, this message translates to:
  /// **'Zoom bracket out'**
  String get worldCupTournamentZoomOut;

  /// No description provided for @worldCupTournamentZoomReset.
  ///
  /// In en, this message translates to:
  /// **'Reset bracket zoom'**
  String get worldCupTournamentZoomReset;

  /// No description provided for @worldCupTournamentZoomIn.
  ///
  /// In en, this message translates to:
  /// **'Zoom bracket in'**
  String get worldCupTournamentZoomIn;

  /// No description provided for @worldCupTournamentOpenFullScreen.
  ///
  /// In en, this message translates to:
  /// **'Open full screen'**
  String get worldCupTournamentOpenFullScreen;

  /// No description provided for @worldCupTournamentPdfTooltip.
  ///
  /// In en, this message translates to:
  /// **'Download bracket PDF'**
  String get worldCupTournamentPdfTooltip;

  /// No description provided for @worldCupTournamentPdfExportedSnack.
  ///
  /// In en, this message translates to:
  /// **'Bracket PDF is ready.'**
  String get worldCupTournamentPdfExportedSnack;

  /// No description provided for @worldCupTournamentPdfExportFailedSnack.
  ///
  /// In en, this message translates to:
  /// **'Could not create the bracket PDF.'**
  String get worldCupTournamentPdfExportFailedSnack;

  /// No description provided for @worldCupTournamentImageTooltip.
  ///
  /// In en, this message translates to:
  /// **'Share bracket image'**
  String get worldCupTournamentImageTooltip;

  /// No description provided for @worldCupTournamentImageExportedSnack.
  ///
  /// In en, this message translates to:
  /// **'Bracket image is ready.'**
  String get worldCupTournamentImageExportedSnack;

  /// No description provided for @worldCupTournamentImageExportFailedSnack.
  ///
  /// In en, this message translates to:
  /// **'Could not create the bracket image.'**
  String get worldCupTournamentImageExportFailedSnack;

  /// No description provided for @worldCupStageMatchCount.
  ///
  /// In en, this message translates to:
  /// **'{count} matches'**
  String worldCupStageMatchCount(int count);

  /// No description provided for @worldCupBracketRoundSummary.
  ///
  /// In en, this message translates to:
  /// **'{dateRange} · {count} matches'**
  String worldCupBracketRoundSummary(String dateRange, int count);

  /// No description provided for @worldCupBracketFirstSeed.
  ///
  /// In en, this message translates to:
  /// **'Group {group} winner'**
  String worldCupBracketFirstSeed(String group);

  /// No description provided for @worldCupBracketSecondSeed.
  ///
  /// In en, this message translates to:
  /// **'Group {group} runner-up'**
  String worldCupBracketSecondSeed(String group);

  /// No description provided for @worldCupBracketThirdSeed.
  ///
  /// In en, this message translates to:
  /// **'One 3rd-place team from {groups}'**
  String worldCupBracketThirdSeed(String groups);

  /// No description provided for @worldCupBracketWinnerSlot.
  ///
  /// In en, this message translates to:
  /// **'Winner of M{matchNumber}'**
  String worldCupBracketWinnerSlot(int matchNumber);

  /// No description provided for @worldCupBracketLoserSlot.
  ///
  /// In en, this message translates to:
  /// **'Loser of M{matchNumber}'**
  String worldCupBracketLoserSlot(int matchNumber);

  /// No description provided for @worldCupBracketPendingTeam.
  ///
  /// In en, this message translates to:
  /// **'Team to be confirmed'**
  String get worldCupBracketPendingTeam;

  /// No description provided for @worldCupBracketPendingWinner.
  ///
  /// In en, this message translates to:
  /// **'Winner to be confirmed'**
  String get worldCupBracketPendingWinner;

  /// No description provided for @worldCupBracketPendingLoser.
  ///
  /// In en, this message translates to:
  /// **'Loser to be confirmed'**
  String get worldCupBracketPendingLoser;

  /// No description provided for @worldCupBracketQualifiedTeamSeparator.
  ///
  /// In en, this message translates to:
  /// **' / '**
  String get worldCupBracketQualifiedTeamSeparator;

  /// No description provided for @worldCupBracketQualifiedSlotDetail.
  ///
  /// In en, this message translates to:
  /// **'Qualified from {slot}'**
  String worldCupBracketQualifiedSlotDetail(String slot);

  /// No description provided for @worldCupBracketWinnerCandidateDetail.
  ///
  /// In en, this message translates to:
  /// **'Winner candidates'**
  String get worldCupBracketWinnerCandidateDetail;

  /// No description provided for @worldCupBracketLoserCandidateDetail.
  ///
  /// In en, this message translates to:
  /// **'Loser candidates'**
  String get worldCupBracketLoserCandidateDetail;

  /// No description provided for @worldCupBracketWinnerResolvedDetail.
  ///
  /// In en, this message translates to:
  /// **'Winner confirmed'**
  String get worldCupBracketWinnerResolvedDetail;

  /// No description provided for @worldCupBracketLoserResolvedDetail.
  ///
  /// In en, this message translates to:
  /// **'Loser confirmed'**
  String get worldCupBracketLoserResolvedDetail;

  /// No description provided for @worldCupBracketSourceMatch.
  ///
  /// In en, this message translates to:
  /// **'M{matchNumber}: {home} v {away}'**
  String worldCupBracketSourceMatch(int matchNumber, String home, String away);

  /// No description provided for @worldCupSourceAction.
  ///
  /// In en, this message translates to:
  /// **'Open FIFA schedule'**
  String get worldCupSourceAction;

  /// No description provided for @worldCupOfficialRefreshAction.
  ///
  /// In en, this message translates to:
  /// **'Refresh FIFA data'**
  String get worldCupOfficialRefreshAction;

  /// No description provided for @worldCupOfficialRefreshing.
  ///
  /// In en, this message translates to:
  /// **'Updating FIFA'**
  String get worldCupOfficialRefreshing;

  /// No description provided for @worldCupOfficialUnavailable.
  ///
  /// In en, this message translates to:
  /// **'FIFA unavailable'**
  String get worldCupOfficialUnavailable;

  /// No description provided for @worldCupOfficialUpdatedAt.
  ///
  /// In en, this message translates to:
  /// **'FIFA {time}'**
  String worldCupOfficialUpdatedAt(String time);

  /// No description provided for @homeHubTitleShort.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get homeHubTitleShort;

  /// No description provided for @homeLayoutChangeAction.
  ///
  /// In en, this message translates to:
  /// **'Change home'**
  String get homeLayoutChangeAction;

  /// No description provided for @homeLayoutSettingsTitle.
  ///
  /// In en, this message translates to:
  /// **'Home screen settings'**
  String get homeLayoutSettingsTitle;

  /// No description provided for @homeLayoutSettingsReset.
  ///
  /// In en, this message translates to:
  /// **'Reset'**
  String get homeLayoutSettingsReset;

  /// No description provided for @homeLayoutReorderTooltip.
  ///
  /// In en, this message translates to:
  /// **'Move section'**
  String get homeLayoutReorderTooltip;

  /// No description provided for @homeLayoutSavedMessage.
  ///
  /// In en, this message translates to:
  /// **'Home screen order saved.'**
  String get homeLayoutSavedMessage;

  /// No description provided for @homeLayoutNoVisibleSections.
  ///
  /// In en, this message translates to:
  /// **'All home sections are hidden.'**
  String get homeLayoutNoVisibleSections;

  /// No description provided for @homeSectionClubSchedule.
  ///
  /// In en, this message translates to:
  /// **'Club schedule'**
  String get homeSectionClubSchedule;

  /// No description provided for @homeSectionLevel.
  ///
  /// In en, this message translates to:
  /// **'Level summary'**
  String get homeSectionLevel;

  /// No description provided for @homeSectionChallenge.
  ///
  /// In en, this message translates to:
  /// **'Challenge'**
  String get homeSectionChallenge;

  /// No description provided for @homeSectionStreak.
  ///
  /// In en, this message translates to:
  /// **'Training streak'**
  String get homeSectionStreak;

  /// No description provided for @homeSectionMeal.
  ///
  /// In en, this message translates to:
  /// **'Meal summary'**
  String get homeSectionMeal;

  /// No description provided for @homeSectionDailyFlow.
  ///
  /// In en, this message translates to:
  /// **'Today\'s tasks'**
  String get homeSectionDailyFlow;

  /// No description provided for @homeSectionQuickActions.
  ///
  /// In en, this message translates to:
  /// **'Quick actions'**
  String get homeSectionQuickActions;

  /// No description provided for @homeSectionContinue.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get homeSectionContinue;

  /// No description provided for @homeDailyCheckTitle.
  ///
  /// In en, this message translates to:
  /// **'Today\'s tasks'**
  String get homeDailyCheckTitle;

  /// No description provided for @homeDailyCheckCompletedCount.
  ///
  /// In en, this message translates to:
  /// **'{completed}/{total} done'**
  String homeDailyCheckCompletedCount(int completed, int total);

  /// No description provided for @homeTodoTrainingLogShort.
  ///
  /// In en, this message translates to:
  /// **'Log'**
  String get homeTodoTrainingLogShort;

  /// No description provided for @homeTodoLiftingShort.
  ///
  /// In en, this message translates to:
  /// **'Lifting'**
  String get homeTodoLiftingShort;

  /// No description provided for @homeTodoJumpRopeShort.
  ///
  /// In en, this message translates to:
  /// **'Jump'**
  String get homeTodoJumpRopeShort;

  /// No description provided for @jumpRopeRecordTitle.
  ///
  /// In en, this message translates to:
  /// **'Jump rope record'**
  String get jumpRopeRecordTitle;

  /// No description provided for @jumpRopeMinutesLabel.
  ///
  /// In en, this message translates to:
  /// **'Jump rope time (min)'**
  String get jumpRopeMinutesLabel;

  /// No description provided for @jumpRopeCountLabel.
  ///
  /// In en, this message translates to:
  /// **'Jump rope count'**
  String get jumpRopeCountLabel;

  /// No description provided for @jumpRopeMemoLabel.
  ///
  /// In en, this message translates to:
  /// **'Memo'**
  String get jumpRopeMemoLabel;

  /// No description provided for @jumpRopeMemoHint.
  ///
  /// In en, this message translates to:
  /// **'Write what you felt during jump rope.'**
  String get jumpRopeMemoHint;

  /// No description provided for @homeTodoQuizShort.
  ///
  /// In en, this message translates to:
  /// **'Quiz'**
  String get homeTodoQuizShort;

  /// No description provided for @homeTodoNewsShort.
  ///
  /// In en, this message translates to:
  /// **'News'**
  String get homeTodoNewsShort;

  /// No description provided for @homeTodoDiaryShort.
  ///
  /// In en, this message translates to:
  /// **'Diary'**
  String get homeTodoDiaryShort;

  /// No description provided for @homeTodoBoardSketchShort.
  ///
  /// In en, this message translates to:
  /// **'Sketch'**
  String get homeTodoBoardSketchShort;

  /// No description provided for @homeQuickActionsTitle.
  ///
  /// In en, this message translates to:
  /// **'Quick actions'**
  String get homeQuickActionsTitle;

  /// No description provided for @homeQuickActionMatch.
  ///
  /// In en, this message translates to:
  /// **'Add match'**
  String get homeQuickActionMatch;

  /// No description provided for @homeQuickActionPlan.
  ///
  /// In en, this message translates to:
  /// **'Add plan'**
  String get homeQuickActionPlan;

  /// No description provided for @homeContinueTitle.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get homeContinueTitle;

  /// No description provided for @homeContinueEmpty.
  ///
  /// In en, this message translates to:
  /// **'Nothing to continue today. Pick a fresh challenge below.'**
  String get homeContinueEmpty;

  /// No description provided for @homeContinueWrongAnswerReview.
  ///
  /// In en, this message translates to:
  /// **'Continue wrong-answer review'**
  String get homeContinueWrongAnswerReview;

  /// No description provided for @homeContinueQuiz.
  ///
  /// In en, this message translates to:
  /// **'Continue quiz'**
  String get homeContinueQuiz;

  /// No description provided for @homeContinueStartQuiz.
  ///
  /// In en, this message translates to:
  /// **'Start quiz'**
  String get homeContinueStartQuiz;

  /// No description provided for @homeContinueQuizProgress.
  ///
  /// In en, this message translates to:
  /// **'In progress {current} / {total}'**
  String homeContinueQuizProgress(int current, int total);

  /// No description provided for @homeContinueQuizStartSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Jump back into today\'s quiz.'**
  String get homeContinueQuizStartSubtitle;

  /// No description provided for @homeContinueTodayTrainingLog.
  ///
  /// In en, this message translates to:
  /// **'Today training log'**
  String get homeContinueTodayTrainingLog;

  /// No description provided for @homeContinueTrainingDuration.
  ///
  /// In en, this message translates to:
  /// **'{date} · {duration} min'**
  String homeContinueTrainingDuration(Object date, int duration);

  /// No description provided for @homeContinueTrainingButton.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get homeContinueTrainingButton;

  /// No description provided for @homeContinueQuizButton.
  ///
  /// In en, this message translates to:
  /// **'Open quiz'**
  String get homeContinueQuizButton;

  /// No description provided for @homeContinueRecentBoardTitle.
  ///
  /// In en, this message translates to:
  /// **'Recent training board'**
  String get homeContinueRecentBoardTitle;

  /// No description provided for @homeContinueBoardCount.
  ///
  /// In en, this message translates to:
  /// **'{count} sketches'**
  String homeContinueBoardCount(int count);

  /// No description provided for @homeContinueBoardSaved.
  ///
  /// In en, this message translates to:
  /// **'{title} · saved {date}'**
  String homeContinueBoardSaved(Object title, Object date);

  /// No description provided for @homeContinueBoardButton.
  ///
  /// In en, this message translates to:
  /// **'Edit now'**
  String get homeContinueBoardButton;

  /// No description provided for @dailyTasksXpDialogTitle.
  ///
  /// In en, this message translates to:
  /// **'Today\'s tasks complete'**
  String get dailyTasksXpDialogTitle;

  /// No description provided for @dailyTasksXpDialogMessage.
  ///
  /// In en, this message translates to:
  /// **'The whole routine is checked off. That consistency turned into growth gems.'**
  String get dailyTasksXpDialogMessage;

  /// No description provided for @dailyTasksXpDialogGems.
  ///
  /// In en, this message translates to:
  /// **'+{count} gems'**
  String dailyTasksXpDialogGems(int count);

  /// No description provided for @dailyTasksXpDialogProgress.
  ///
  /// In en, this message translates to:
  /// **'Total {totalXp} XP · {remainingXp} XP to next level'**
  String dailyTasksXpDialogProgress(int totalXp, int remainingXp);

  /// No description provided for @dailyTasksXpDialogMaxProgress.
  ///
  /// In en, this message translates to:
  /// **'Total {totalXp} XP · {remainingXp} XP to next mastery star'**
  String dailyTasksXpDialogMaxProgress(int totalXp, int remainingXp);

  /// No description provided for @dailyTasksXpDialogAction.
  ///
  /// In en, this message translates to:
  /// **'Keep going'**
  String get dailyTasksXpDialogAction;

  /// No description provided for @trainingXpDialogTitle.
  ///
  /// In en, this message translates to:
  /// **'Training log saved'**
  String get trainingXpDialogTitle;

  /// No description provided for @trainingXpDialogMessage.
  ///
  /// In en, this message translates to:
  /// **'Training log saved.'**
  String get trainingXpDialogMessage;

  /// No description provided for @trainingRecordSavedDialogMessage.
  ///
  /// In en, this message translates to:
  /// **'Record saved.'**
  String get trainingRecordSavedDialogMessage;

  /// No description provided for @trainingEntryConditioningEmpty.
  ///
  /// In en, this message translates to:
  /// **'No jump rope/lifting record'**
  String get trainingEntryConditioningEmpty;

  /// No description provided for @trainingEntryLessonSummary.
  ///
  /// In en, this message translates to:
  /// **'Lesson'**
  String get trainingEntryLessonSummary;

  /// No description provided for @trainingEntryLessonSummaryWithDetail.
  ///
  /// In en, this message translates to:
  /// **'Lesson: {detail}'**
  String trainingEntryLessonSummaryWithDetail(String detail);

  /// No description provided for @trainingEntryInjuryPresent.
  ///
  /// In en, this message translates to:
  /// **'Injury recorded'**
  String get trainingEntryInjuryPresent;

  /// No description provided for @trainingEntryInjurySummary.
  ///
  /// In en, this message translates to:
  /// **'Injury: {detail}'**
  String trainingEntryInjurySummary(String detail);

  /// No description provided for @trainingEntryInjuryPainSummary.
  ///
  /// In en, this message translates to:
  /// **'Pain {pain}/10'**
  String trainingEntryInjuryPainSummary(int pain);

  /// No description provided for @trainingXpDialogJumpRopeTitle.
  ///
  /// In en, this message translates to:
  /// **'Jump rope saved'**
  String get trainingXpDialogJumpRopeTitle;

  /// No description provided for @trainingXpDialogJumpRopeMessage.
  ///
  /// In en, this message translates to:
  /// **'Jump rope log saved.'**
  String get trainingXpDialogJumpRopeMessage;

  /// No description provided for @trainingXpDialogLiftingTitle.
  ///
  /// In en, this message translates to:
  /// **'Lifting saved'**
  String get trainingXpDialogLiftingTitle;

  /// No description provided for @trainingXpDialogLiftingMessage.
  ///
  /// In en, this message translates to:
  /// **'Lifting log saved.'**
  String get trainingXpDialogLiftingMessage;

  /// No description provided for @trainingXpDialogMealTitle.
  ///
  /// In en, this message translates to:
  /// **'Recovery saved'**
  String get trainingXpDialogMealTitle;

  /// No description provided for @trainingXpDialogMealMessage.
  ///
  /// In en, this message translates to:
  /// **'Meal and recovery log saved.'**
  String get trainingXpDialogMealMessage;

  /// No description provided for @diaryXpDialogTitle.
  ///
  /// In en, this message translates to:
  /// **'Diary sapphire'**
  String get diaryXpDialogTitle;

  /// No description provided for @diaryXpDialogMessage.
  ///
  /// In en, this message translates to:
  /// **'Your reflection turned into calm sapphire XP.'**
  String get diaryXpDialogMessage;

  /// No description provided for @trainingSketchXpDialogTitle.
  ///
  /// In en, this message translates to:
  /// **'Sketch gold'**
  String get trainingSketchXpDialogTitle;

  /// No description provided for @trainingSketchXpDialogMessage.
  ///
  /// In en, this message translates to:
  /// **'Your training idea sketch turned into bright gold XP.'**
  String get trainingSketchXpDialogMessage;

  /// No description provided for @trainingXpDialogXp.
  ///
  /// In en, this message translates to:
  /// **'+{count} XP'**
  String trainingXpDialogXp(int count);

  /// No description provided for @trainingXpDialogRewardLabel.
  ///
  /// In en, this message translates to:
  /// **'XP earned'**
  String get trainingXpDialogRewardLabel;

  /// No description provided for @trainingRecordSavedDialogLabel.
  ///
  /// In en, this message translates to:
  /// **'Record complete'**
  String get trainingRecordSavedDialogLabel;

  /// No description provided for @trainingRecordSavedDialogValue.
  ///
  /// In en, this message translates to:
  /// **'Saved'**
  String get trainingRecordSavedDialogValue;

  /// No description provided for @trainingXpDialogTotalLabel.
  ///
  /// In en, this message translates to:
  /// **'Total XP'**
  String get trainingXpDialogTotalLabel;

  /// No description provided for @trainingXpDialogTotalValue.
  ///
  /// In en, this message translates to:
  /// **'{totalXp} XP'**
  String trainingXpDialogTotalValue(int totalXp);

  /// No description provided for @trainingXpDialogLevelLabel.
  ///
  /// In en, this message translates to:
  /// **'Current level'**
  String get trainingXpDialogLevelLabel;

  /// No description provided for @trainingXpDialogLevelValue.
  ///
  /// In en, this message translates to:
  /// **'Lv.{level} {levelName}'**
  String trainingXpDialogLevelValue(int level, String levelName);

  /// No description provided for @trainingXpDialogAction.
  ///
  /// In en, this message translates to:
  /// **'OK'**
  String get trainingXpDialogAction;

  /// No description provided for @trainingXpSourceTrainingLog.
  ///
  /// In en, this message translates to:
  /// **'Training log'**
  String get trainingXpSourceTrainingLog;

  /// No description provided for @trainingXpSourceTrainingUpdate.
  ///
  /// In en, this message translates to:
  /// **'Training update'**
  String get trainingXpSourceTrainingUpdate;

  /// No description provided for @trainingXpSourceLifting.
  ///
  /// In en, this message translates to:
  /// **'Lifting'**
  String get trainingXpSourceLifting;

  /// No description provided for @trainingXpSourceJumpRope.
  ///
  /// In en, this message translates to:
  /// **'Jump rope'**
  String get trainingXpSourceJumpRope;

  /// No description provided for @trainingXpSourceTrainingSketch.
  ///
  /// In en, this message translates to:
  /// **'Training sketch'**
  String get trainingXpSourceTrainingSketch;

  /// No description provided for @trainingXpSourceDiary.
  ///
  /// In en, this message translates to:
  /// **'Diary'**
  String get trainingXpSourceDiary;

  /// No description provided for @trainingSaveToastPlain.
  ///
  /// In en, this message translates to:
  /// **'Training note saved.'**
  String get trainingSaveToastPlain;

  /// No description provided for @trainingSaveToastWithXp.
  ///
  /// In en, this message translates to:
  /// **'Training note saved. +{gainedXp} XP · {details}'**
  String trainingSaveToastWithXp(int gainedXp, Object details);

  /// No description provided for @trainingSaveToastLevelUp.
  ///
  /// In en, this message translates to:
  /// **'Training note saved. +{gainedXp} XP · {details} · Reached Lv.{level} {levelName}'**
  String trainingSaveToastLevelUp(
      int gainedXp, Object details, int level, Object levelName);

  /// No description provided for @trainingXpToastReasonLiftingMissed.
  ///
  /// In en, this message translates to:
  /// **'Lifting missed'**
  String get trainingXpToastReasonLiftingMissed;

  /// No description provided for @trainingXpToastReasonJumpRopeMissed.
  ///
  /// In en, this message translates to:
  /// **'Jump rope missed'**
  String get trainingXpToastReasonJumpRopeMissed;

  /// No description provided for @trainingXpToastReasonMealFullBonus.
  ///
  /// In en, this message translates to:
  /// **'Three meals + 5+ rice bowls'**
  String get trainingXpToastReasonMealFullBonus;

  /// No description provided for @trainingXpToastReasonRoutineComplete.
  ///
  /// In en, this message translates to:
  /// **'Training routine complete'**
  String get trainingXpToastReasonRoutineComplete;

  /// No description provided for @trainingXpToastReasonStreakDaily2.
  ///
  /// In en, this message translates to:
  /// **'2-3 day streak bonus'**
  String get trainingXpToastReasonStreakDaily2;

  /// No description provided for @trainingXpToastReasonStreakDaily4.
  ///
  /// In en, this message translates to:
  /// **'4-6 day streak bonus'**
  String get trainingXpToastReasonStreakDaily4;

  /// No description provided for @trainingXpToastReasonStreakDaily7.
  ///
  /// In en, this message translates to:
  /// **'7+ day streak bonus'**
  String get trainingXpToastReasonStreakDaily7;

  /// No description provided for @trainingXpToastReasonStreak3.
  ///
  /// In en, this message translates to:
  /// **'3-day streak'**
  String get trainingXpToastReasonStreak3;

  /// No description provided for @trainingXpToastReasonStreak7.
  ///
  /// In en, this message translates to:
  /// **'7-day streak'**
  String get trainingXpToastReasonStreak7;

  /// No description provided for @trainingXpToastReasonWeekly3.
  ///
  /// In en, this message translates to:
  /// **'3 logs this week'**
  String get trainingXpToastReasonWeekly3;

  /// No description provided for @trainingXpToastReasonWeekly5.
  ///
  /// In en, this message translates to:
  /// **'5 logs this week'**
  String get trainingXpToastReasonWeekly5;

  /// No description provided for @trainingXpToastReasonDailyCap.
  ///
  /// In en, this message translates to:
  /// **'Daily cap applied'**
  String get trainingXpToastReasonDailyCap;

  /// No description provided for @trainingXpToastMoreReasons.
  ///
  /// In en, this message translates to:
  /// **'{count} more'**
  String trainingXpToastMoreReasons(int count);

  /// No description provided for @diarySavedWithXpFeedback.
  ///
  /// In en, this message translates to:
  /// **'Diary saved +{count} XP'**
  String diarySavedWithXpFeedback(int count);

  /// No description provided for @trainingStreakCheerTitle.
  ///
  /// In en, this message translates to:
  /// **'{count}-day training streak'**
  String trainingStreakCheerTitle(int count);

  /// No description provided for @trainingStreakCheerMessage.
  ///
  /// In en, this message translates to:
  /// **'Day-by-day training notes are connecting into a real routine. Keep the next session simple and repeatable.'**
  String get trainingStreakCheerMessage;

  /// No description provided for @trainingStreakCheerAction.
  ///
  /// In en, this message translates to:
  /// **'Keep going'**
  String get trainingStreakCheerAction;

  /// No description provided for @levelUpDialogTitle.
  ///
  /// In en, this message translates to:
  /// **'Level up!'**
  String get levelUpDialogTitle;

  /// No description provided for @levelUpDialogLevelLabel.
  ///
  /// In en, this message translates to:
  /// **'Lv.{level} {levelName}'**
  String levelUpDialogLevelLabel(int level, Object levelName);

  /// No description provided for @levelUpDialogEncouragement.
  ///
  /// In en, this message translates to:
  /// **'Today\'s effort became bright growth. Keep this rhythm for the next session.'**
  String get levelUpDialogEncouragement;

  /// No description provided for @levelUpDialogEncouragementWithReward.
  ///
  /// In en, this message translates to:
  /// **'Today\'s effort became bright growth, and {rewardName} is ready too.'**
  String levelUpDialogEncouragementWithReward(Object rewardName);

  /// No description provided for @levelUpDialogProgress.
  ///
  /// In en, this message translates to:
  /// **'+{xp} gems earned · now in {stageName}'**
  String levelUpDialogProgress(int xp, Object stageName);

  /// No description provided for @levelUpDialogRewardTitle.
  ///
  /// In en, this message translates to:
  /// **'Reward'**
  String get levelUpDialogRewardTitle;

  /// No description provided for @levelUpDialogLater.
  ///
  /// In en, this message translates to:
  /// **'Later'**
  String get levelUpDialogLater;

  /// No description provided for @levelUpDialogClaimReward.
  ///
  /// In en, this message translates to:
  /// **'Claim reward'**
  String get levelUpDialogClaimReward;

  /// No description provided for @levelUpDialogConfirm.
  ///
  /// In en, this message translates to:
  /// **'Great'**
  String get levelUpDialogConfirm;

  /// No description provided for @levelUpRewardClaimed.
  ///
  /// In en, this message translates to:
  /// **'Claimed {rewardName}.'**
  String levelUpRewardClaimed(Object rewardName);

  /// No description provided for @xpGuideDailyTasksCompleteTitle.
  ///
  /// In en, this message translates to:
  /// **'All today tasks complete'**
  String get xpGuideDailyTasksCompleteTitle;

  /// No description provided for @quizXpSourceLabel.
  ///
  /// In en, this message translates to:
  /// **'Sports quiz'**
  String get quizXpSourceLabel;

  /// No description provided for @quizScreenTitle.
  ///
  /// In en, this message translates to:
  /// **'Today\'s Quiz'**
  String get quizScreenTitle;

  /// No description provided for @quizLibraryAction.
  ///
  /// In en, this message translates to:
  /// **'Questions'**
  String get quizLibraryAction;

  /// No description provided for @quizHistoryAction.
  ///
  /// In en, this message translates to:
  /// **'History'**
  String get quizHistoryAction;

  /// No description provided for @quizBackHomeTooltip.
  ///
  /// In en, this message translates to:
  /// **'Back to quiz home'**
  String get quizBackHomeTooltip;

  /// No description provided for @quizResultMissReviewCountLabel.
  ///
  /// In en, this message translates to:
  /// **'Misses to review'**
  String get quizResultMissReviewCountLabel;

  /// No description provided for @quizResultNoMissedQuestions.
  ///
  /// In en, this message translates to:
  /// **'This run finished with no missed questions.'**
  String get quizResultNoMissedQuestions;

  /// No description provided for @quizStudyGuideTitle.
  ///
  /// In en, this message translates to:
  /// **'Study guide'**
  String get quizStudyGuideTitle;

  /// No description provided for @quizStudyGuideQuestionLabel.
  ///
  /// In en, this message translates to:
  /// **'Question'**
  String get quizStudyGuideQuestionLabel;

  /// No description provided for @quizStudyGuideAnswerLabel.
  ///
  /// In en, this message translates to:
  /// **'Answer'**
  String get quizStudyGuideAnswerLabel;

  /// No description provided for @quizStudyGuideConceptLabel.
  ///
  /// In en, this message translates to:
  /// **'Core concept'**
  String get quizStudyGuideConceptLabel;

  /// No description provided for @quizStudyGuideApplicationLabel.
  ///
  /// In en, this message translates to:
  /// **'Apply it'**
  String get quizStudyGuideApplicationLabel;

  /// No description provided for @quizStudyGuidePracticeLabel.
  ///
  /// In en, this message translates to:
  /// **'Training check'**
  String get quizStudyGuidePracticeLabel;

  /// No description provided for @quizStudyGuidePending.
  ///
  /// In en, this message translates to:
  /// **'Choose an answer to open the study guide.'**
  String get quizStudyGuidePending;

  /// No description provided for @quizXpSavedFeedback.
  ///
  /// In en, this message translates to:
  /// **'Quiz complete +{count} XP'**
  String quizXpSavedFeedback(int count);

  /// No description provided for @playerXpGuideTitle.
  ///
  /// In en, this message translates to:
  /// **'How XP goes up'**
  String get playerXpGuideTitle;

  /// No description provided for @playerXpGuideHeroLevel.
  ///
  /// In en, this message translates to:
  /// **'You are Lv.{level}'**
  String playerXpGuideHeroLevel(int level);

  /// No description provided for @playerXpGuideHeroBody.
  ///
  /// In en, this message translates to:
  /// **'This page groups every XP source clearly. {remainingXp} XP remains until the next level.'**
  String playerXpGuideHeroBody(int remainingXp);

  /// No description provided for @playerXpGuideHeroMax.
  ///
  /// In en, this message translates to:
  /// **'After Lv.20, every {masterySpan} XP earns a mastery star. {remainingXp} XP remains until the next star.'**
  String playerXpGuideHeroMax(int masterySpan, int remainingXp);

  /// No description provided for @playerXpGuideLoggingTitle.
  ///
  /// In en, this message translates to:
  /// **'XP from training logs'**
  String get playerXpGuideLoggingTitle;

  /// No description provided for @playerXpGuideLoggingSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Core growth comes from saving consistent training logs.'**
  String get playerXpGuideLoggingSubtitle;

  /// No description provided for @playerXpGuideTrainingLogSaved.
  ///
  /// In en, this message translates to:
  /// **'Training log saved'**
  String get playerXpGuideTrainingLogSaved;

  /// No description provided for @playerXpGuideFirstDailyLog.
  ///
  /// In en, this message translates to:
  /// **'First log of the day'**
  String get playerXpGuideFirstDailyLog;

  /// No description provided for @playerXpGuidePlannedDayComplete.
  ///
  /// In en, this message translates to:
  /// **'Complete a planned day'**
  String get playerXpGuidePlannedDayComplete;

  /// No description provided for @playerXpGuideLiftingRecorded.
  ///
  /// In en, this message translates to:
  /// **'Lifting recorded'**
  String get playerXpGuideLiftingRecorded;

  /// No description provided for @playerXpGuideJumpRopeRecorded.
  ///
  /// In en, this message translates to:
  /// **'Jump rope recorded'**
  String get playerXpGuideJumpRopeRecorded;

  /// No description provided for @playerXpGuideTrainingRoutineComplete.
  ///
  /// In en, this message translates to:
  /// **'Complete lifting + jump rope + recovery'**
  String get playerXpGuideTrainingRoutineComplete;

  /// No description provided for @playerXpGuideMissingConditioning.
  ///
  /// In en, this message translates to:
  /// **'Missing lifting or jump rope costs XP'**
  String get playerXpGuideMissingConditioning;

  /// No description provided for @playerXpGuideMissingConditioningXp.
  ///
  /// In en, this message translates to:
  /// **'-5 XP each'**
  String get playerXpGuideMissingConditioningXp;

  /// No description provided for @playerXpGuideStreakTitle.
  ///
  /// In en, this message translates to:
  /// **'Streak and weekly bonuses'**
  String get playerXpGuideStreakTitle;

  /// No description provided for @playerXpGuideStreakSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Larger bonuses unlock once repetition becomes consistent.'**
  String get playerXpGuideStreakSubtitle;

  /// No description provided for @playerXpGuideStreakMilestones.
  ///
  /// In en, this message translates to:
  /// **'3-day / 7-day streak'**
  String get playerXpGuideStreakMilestones;

  /// No description provided for @playerXpGuideStreakDailyBonus.
  ///
  /// In en, this message translates to:
  /// **'Daily bonus from streak logging'**
  String get playerXpGuideStreakDailyBonus;

  /// No description provided for @playerXpGuideWeeklyBonus.
  ///
  /// In en, this message translates to:
  /// **'3 logs / 5 logs in a week'**
  String get playerXpGuideWeeklyBonus;

  /// No description provided for @playerXpGuideActivityTitle.
  ///
  /// In en, this message translates to:
  /// **'Other activity XP'**
  String get playerXpGuideActivityTitle;

  /// No description provided for @playerXpGuideActivitySubtitle.
  ///
  /// In en, this message translates to:
  /// **'Plans, sketches, meals, diary, quiz, and daily completion also add XP when saved.'**
  String get playerXpGuideActivitySubtitle;

  /// No description provided for @playerXpGuidePlanCreated.
  ///
  /// In en, this message translates to:
  /// **'Training plan created'**
  String get playerXpGuidePlanCreated;

  /// No description provided for @playerXpGuideMatchLogged.
  ///
  /// In en, this message translates to:
  /// **'Match log saved'**
  String get playerXpGuideMatchLogged;

  /// No description provided for @playerXpGuideTrainingSketchSaved.
  ///
  /// In en, this message translates to:
  /// **'Training sketch saved'**
  String get playerXpGuideTrainingSketchSaved;

  /// No description provided for @playerXpGuideTrainingSketchSavedXp.
  ///
  /// In en, this message translates to:
  /// **'+5 XP / +2 XP'**
  String get playerXpGuideTrainingSketchSavedXp;

  /// No description provided for @playerXpGuideDiaryCreated.
  ///
  /// In en, this message translates to:
  /// **'Diary created'**
  String get playerXpGuideDiaryCreated;

  /// No description provided for @playerXpGuideQuizComplete.
  ///
  /// In en, this message translates to:
  /// **'Quiz completed'**
  String get playerXpGuideQuizComplete;

  /// No description provided for @playerXpGuideQuizCompleteXp.
  ///
  /// In en, this message translates to:
  /// **'+2 to +15 XP by correct answers'**
  String get playerXpGuideQuizCompleteXp;

  /// No description provided for @playerXpGuideMealTwoPlus.
  ///
  /// In en, this message translates to:
  /// **'Two or more meals logged'**
  String get playerXpGuideMealTwoPlus;

  /// No description provided for @playerXpGuideMealFull.
  ///
  /// In en, this message translates to:
  /// **'Three meals / three meals with 5+ rice bowls'**
  String get playerXpGuideMealFull;

  /// No description provided for @playerXpGuideDailyTasksComplete.
  ///
  /// In en, this message translates to:
  /// **'All daily home tasks completed'**
  String get playerXpGuideDailyTasksComplete;

  /// No description provided for @playerXpGuideDailyCap.
  ///
  /// In en, this message translates to:
  /// **'Daily positive XP cap'**
  String get playerXpGuideDailyCap;

  /// No description provided for @playerLevelName1.
  ///
  /// In en, this message translates to:
  /// **'Kickoff'**
  String get playerLevelName1;

  /// No description provided for @playerLevelName2.
  ///
  /// In en, this message translates to:
  /// **'Rookie'**
  String get playerLevelName2;

  /// No description provided for @playerLevelName3.
  ///
  /// In en, this message translates to:
  /// **'Starter'**
  String get playerLevelName3;

  /// No description provided for @playerLevelName4.
  ///
  /// In en, this message translates to:
  /// **'Challenger'**
  String get playerLevelName4;

  /// No description provided for @playerLevelName5.
  ///
  /// In en, this message translates to:
  /// **'Playmaker'**
  String get playerLevelName5;

  /// No description provided for @playerLevelName6.
  ///
  /// In en, this message translates to:
  /// **'Engine'**
  String get playerLevelName6;

  /// No description provided for @playerLevelName7.
  ///
  /// In en, this message translates to:
  /// **'Captain'**
  String get playerLevelName7;

  /// No description provided for @playerLevelName8.
  ///
  /// In en, this message translates to:
  /// **'Elite'**
  String get playerLevelName8;

  /// No description provided for @playerLevelName9.
  ///
  /// In en, this message translates to:
  /// **'Match Leader'**
  String get playerLevelName9;

  /// No description provided for @playerLevelName10.
  ///
  /// In en, this message translates to:
  /// **'High Performer'**
  String get playerLevelName10;

  /// No description provided for @playerLevelName11.
  ///
  /// In en, this message translates to:
  /// **'Driver'**
  String get playerLevelName11;

  /// No description provided for @playerLevelName12.
  ///
  /// In en, this message translates to:
  /// **'Field Maker'**
  String get playerLevelName12;

  /// No description provided for @playerLevelName13.
  ///
  /// In en, this message translates to:
  /// **'Control Tower'**
  String get playerLevelName13;

  /// No description provided for @playerLevelName14.
  ///
  /// In en, this message translates to:
  /// **'Iron Captain'**
  String get playerLevelName14;

  /// No description provided for @playerLevelName15.
  ///
  /// In en, this message translates to:
  /// **'Game Changer'**
  String get playerLevelName15;

  /// No description provided for @playerLevelName16.
  ///
  /// In en, this message translates to:
  /// **'Session Master'**
  String get playerLevelName16;

  /// No description provided for @playerLevelName17.
  ///
  /// In en, this message translates to:
  /// **'Ace Core'**
  String get playerLevelName17;

  /// No description provided for @playerLevelName18.
  ///
  /// In en, this message translates to:
  /// **'Pitch Artist'**
  String get playerLevelName18;

  /// No description provided for @playerLevelName19.
  ///
  /// In en, this message translates to:
  /// **'Stadium Icon'**
  String get playerLevelName19;

  /// No description provided for @playerLevelName20.
  ///
  /// In en, this message translates to:
  /// **'Football Gift Master'**
  String get playerLevelName20;

  /// No description provided for @playerLevelStage1.
  ///
  /// In en, this message translates to:
  /// **'New Ground'**
  String get playerLevelStage1;

  /// No description provided for @playerLevelStage2.
  ///
  /// In en, this message translates to:
  /// **'Training Rookie'**
  String get playerLevelStage2;

  /// No description provided for @playerLevelStage3.
  ///
  /// In en, this message translates to:
  /// **'First Team Rise'**
  String get playerLevelStage3;

  /// No description provided for @playerLevelStage4.
  ///
  /// In en, this message translates to:
  /// **'Match Leader'**
  String get playerLevelStage4;

  /// No description provided for @playerLevelStage5.
  ///
  /// In en, this message translates to:
  /// **'Upper Tier'**
  String get playerLevelStage5;

  /// No description provided for @playerLevelStage6.
  ///
  /// In en, this message translates to:
  /// **'Core Ace'**
  String get playerLevelStage6;

  /// No description provided for @playerLevelStage7.
  ///
  /// In en, this message translates to:
  /// **'Elite Track'**
  String get playerLevelStage7;

  /// No description provided for @playerLevelBaseballNames.
  ///
  /// In en, this message translates to:
  /// **'Play Ball|Rookie Hitter|Lineup Starter|Base Challenger|Clutch Maker|Inning Engine|Dugout Captain|Diamond Elite|Game Leader|High Performer|Slugger Driver|Field Maker|Sign Controller|Iron Captain|Game Changer|Series Master|Ace Core|Diamond Artist|Ballpark Icon|Baseball Gift Master'**
  String get playerLevelBaseballNames;

  /// No description provided for @playerLevelBasketballNames.
  ///
  /// In en, this message translates to:
  /// **'Tipoff|Court Rookie|Lineup Starter|Rim Challenger|Playmaker|Court Engine|Team Captain|Elite Guard|Game Leader|High Performer|Drive Leader|Court Maker|Pace Controller|Iron Captain|Clutch Changer|Session Master|Ace Core|Court Artist|Arena Icon|Basketball Gift Master'**
  String get playerLevelBasketballNames;

  /// No description provided for @playerLevelTennisNames.
  ///
  /// In en, this message translates to:
  /// **'First Serve|Court Rookie|Rally Starter|Baseline Challenger|Point Maker|Footwork Engine|Match Captain|Elite Rallyer|Game Leader|High Performer|Serve Driver|Court Maker|Tempo Controller|Iron Captain|Tiebreak Changer|Session Master|Ace Core|Line Artist|Center Court Icon|Tennis Gift Master'**
  String get playerLevelTennisNames;

  /// No description provided for @playerLevelBaseballStages.
  ///
  /// In en, this message translates to:
  /// **'New Player|Rookie Hitter|Starter Rise|Game Leader|Upper Tier|Core Ace|Elite Diamond'**
  String get playerLevelBaseballStages;

  /// No description provided for @playerLevelBasketballStages.
  ///
  /// In en, this message translates to:
  /// **'New Player|Court Rookie|Starter Rise|Game Leader|Upper Tier|Core Ace|Elite Court'**
  String get playerLevelBasketballStages;

  /// No description provided for @playerLevelTennisStages.
  ///
  /// In en, this message translates to:
  /// **'New Player|Court Rookie|Rally Rise|Match Leader|Upper Tier|Core Ace|Elite Tour'**
  String get playerLevelTennisStages;

  /// No description provided for @playerLevelBaseballIllustrations.
  ///
  /// In en, this message translates to:
  /// **'Play-ball sign|First glove|Batting tee|Speed cleats|Throwing rhythm|Power bat|Lineup board|Captain cap|Winner trophy|Celebration fireworks|Fielding glove|Catcher mitt|Sign radar|Baserun lightning|Victory medal|Home ballpark|Ace rocket|Diamond star|Ballpark gift box|Legend galaxy'**
  String get playerLevelBaseballIllustrations;

  /// No description provided for @playerLevelBasketballIllustrations.
  ///
  /// In en, this message translates to:
  /// **'Tipoff ball|First basketball|Training cone|Speed shoes|Dribble rhythm|Power dumbbell|Tactics board|Captain crown|Winner trophy|Celebration fireworks|Defense shield|Rebound hands|Tactics radar|Fast-break lightning|Victory medal|Home arena|Ace rocket|Court star|Arena gift box|Legend galaxy'**
  String get playerLevelBasketballIllustrations;

  /// No description provided for @playerLevelTennisIllustrations.
  ///
  /// In en, this message translates to:
  /// **'First serve|First racket|Training cone|Speed shoes|Rally rhythm|Power dumbbell|Tactics note|Captain crown|Winner trophy|Celebration fireworks|Defense shield|Match towel|Tactics radar|Footwork lightning|Victory medal|Center court|Ace rocket|Line star|Center-court gift box|Legend galaxy'**
  String get playerLevelTennisIllustrations;

  /// No description provided for @playerLevelIllustration1.
  ///
  /// In en, this message translates to:
  /// **'Starter whistle'**
  String get playerLevelIllustration1;

  /// No description provided for @playerLevelIllustration2.
  ///
  /// In en, this message translates to:
  /// **'First football'**
  String get playerLevelIllustration2;

  /// No description provided for @playerLevelIllustration3.
  ///
  /// In en, this message translates to:
  /// **'Training cone'**
  String get playerLevelIllustration3;

  /// No description provided for @playerLevelIllustration4.
  ///
  /// In en, this message translates to:
  /// **'Speed boots'**
  String get playerLevelIllustration4;

  /// No description provided for @playerLevelIllustration5.
  ///
  /// In en, this message translates to:
  /// **'Jump-rope rhythm'**
  String get playerLevelIllustration5;

  /// No description provided for @playerLevelIllustration6.
  ///
  /// In en, this message translates to:
  /// **'Power dumbbell'**
  String get playerLevelIllustration6;

  /// No description provided for @playerLevelIllustration7.
  ///
  /// In en, this message translates to:
  /// **'Tactics board'**
  String get playerLevelIllustration7;

  /// No description provided for @playerLevelIllustration8.
  ///
  /// In en, this message translates to:
  /// **'Captain crown'**
  String get playerLevelIllustration8;

  /// No description provided for @playerLevelIllustration9.
  ///
  /// In en, this message translates to:
  /// **'Winner trophy'**
  String get playerLevelIllustration9;

  /// No description provided for @playerLevelIllustration10.
  ///
  /// In en, this message translates to:
  /// **'Celebration fireworks'**
  String get playerLevelIllustration10;

  /// No description provided for @playerLevelIllustration11.
  ///
  /// In en, this message translates to:
  /// **'Defense shield'**
  String get playerLevelIllustration11;

  /// No description provided for @playerLevelIllustration12.
  ///
  /// In en, this message translates to:
  /// **'Keeper gloves'**
  String get playerLevelIllustration12;

  /// No description provided for @playerLevelIllustration13.
  ///
  /// In en, this message translates to:
  /// **'Tactics radar'**
  String get playerLevelIllustration13;

  /// No description provided for @playerLevelIllustration14.
  ///
  /// In en, this message translates to:
  /// **'Sprint lightning'**
  String get playerLevelIllustration14;

  /// No description provided for @playerLevelIllustration15.
  ///
  /// In en, this message translates to:
  /// **'Victory medal'**
  String get playerLevelIllustration15;

  /// No description provided for @playerLevelIllustration16.
  ///
  /// In en, this message translates to:
  /// **'Home stadium'**
  String get playerLevelIllustration16;

  /// No description provided for @playerLevelIllustration17.
  ///
  /// In en, this message translates to:
  /// **'Ace rocket'**
  String get playerLevelIllustration17;

  /// No description provided for @playerLevelIllustration18.
  ///
  /// In en, this message translates to:
  /// **'Pitch star'**
  String get playerLevelIllustration18;

  /// No description provided for @playerLevelIllustration19.
  ///
  /// In en, this message translates to:
  /// **'Stadium gift box'**
  String get playerLevelIllustration19;

  /// No description provided for @playerLevelIllustration20.
  ///
  /// In en, this message translates to:
  /// **'Legend galaxy'**
  String get playerLevelIllustration20;

  /// No description provided for @levelGuideTitle.
  ///
  /// In en, this message translates to:
  /// **'Level guide'**
  String get levelGuideTitle;

  /// No description provided for @levelGuideOpenXpGuideTooltip.
  ///
  /// In en, this message translates to:
  /// **'Open XP guide'**
  String get levelGuideOpenXpGuideTooltip;

  /// No description provided for @levelGuideXpHistoryTooltip.
  ///
  /// In en, this message translates to:
  /// **'XP history'**
  String get levelGuideXpHistoryTooltip;

  /// No description provided for @levelGuideCurrentProgressTitle.
  ///
  /// In en, this message translates to:
  /// **'Current progress'**
  String get levelGuideCurrentProgressTitle;

  /// No description provided for @levelGuideCurrentProgressTotal.
  ///
  /// In en, this message translates to:
  /// **'Lv.{level} · {totalXp} XP total'**
  String levelGuideCurrentProgressTotal(int level, int totalXp);

  /// No description provided for @levelGuideCurrentProgressMax.
  ///
  /// In en, this message translates to:
  /// **'{stars} mastery star(s) · {remainingXp} XP left until the next star.'**
  String levelGuideCurrentProgressMax(int stars, int remainingXp);

  /// No description provided for @levelGuideCurrentProgressNext.
  ///
  /// In en, this message translates to:
  /// **'{remainingXp} XP left until the next level. Use the top-right actions for the XP guide and history.'**
  String levelGuideCurrentProgressNext(int remainingXp);

  /// No description provided for @levelGuideSetRewardTitle.
  ///
  /// In en, this message translates to:
  /// **'Set level reward'**
  String get levelGuideSetRewardTitle;

  /// No description provided for @levelGuideRewardNameLabel.
  ///
  /// In en, this message translates to:
  /// **'Reward name'**
  String get levelGuideRewardNameLabel;

  /// No description provided for @levelGuideRewardNameHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. New football socks'**
  String get levelGuideRewardNameHint;

  /// No description provided for @levelGuideClearRewardAction.
  ///
  /// In en, this message translates to:
  /// **'Clear'**
  String get levelGuideClearRewardAction;

  /// No description provided for @levelGuideCurrentBadge.
  ///
  /// In en, this message translates to:
  /// **'Current'**
  String get levelGuideCurrentBadge;

  /// No description provided for @levelGuideXpRangeLabel.
  ///
  /// In en, this message translates to:
  /// **'{minXp} XP to {maxXp} XP'**
  String levelGuideXpRangeLabel(int minXp, int maxXp);

  /// No description provided for @levelGuideRewardTitle.
  ///
  /// In en, this message translates to:
  /// **'Level reward'**
  String get levelGuideRewardTitle;

  /// No description provided for @levelGuideEditReward.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get levelGuideEditReward;

  /// No description provided for @levelGuideRewardNotSet.
  ///
  /// In en, this message translates to:
  /// **'Not set'**
  String get levelGuideRewardNotSet;

  /// No description provided for @levelGuideSyncing.
  ///
  /// In en, this message translates to:
  /// **'Syncing...'**
  String get levelGuideSyncing;

  /// No description provided for @levelGuideRewardNeedsName.
  ///
  /// In en, this message translates to:
  /// **'Add reward to claim'**
  String get levelGuideRewardNeedsName;

  /// No description provided for @levelGuideRewardAlreadyClaimed.
  ///
  /// In en, this message translates to:
  /// **'Already claimed'**
  String get levelGuideRewardAlreadyClaimed;

  /// No description provided for @levelGuideClaimReward.
  ///
  /// In en, this message translates to:
  /// **'Claim reward'**
  String get levelGuideClaimReward;

  /// No description provided for @levelGuideRewardLocked.
  ///
  /// In en, this message translates to:
  /// **'Claim at Lv.{level}'**
  String levelGuideRewardLocked(int level);

  /// No description provided for @xpHistoryTitle.
  ///
  /// In en, this message translates to:
  /// **'XP history'**
  String get xpHistoryTitle;

  /// No description provided for @xpHistoryClearAllAction.
  ///
  /// In en, this message translates to:
  /// **'Clear all'**
  String get xpHistoryClearAllAction;

  /// No description provided for @xpHistoryEmpty.
  ///
  /// In en, this message translates to:
  /// **'No XP history yet.'**
  String get xpHistoryEmpty;

  /// No description provided for @xpHistoryMessageDeleted.
  ///
  /// In en, this message translates to:
  /// **'XP message deleted.'**
  String get xpHistoryMessageDeleted;

  /// No description provided for @xpHistoryDeleteDialogTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete XP messages'**
  String get xpHistoryDeleteDialogTitle;

  /// No description provided for @xpHistoryDeleteDialogBody.
  ///
  /// In en, this message translates to:
  /// **'Delete all saved XP messages?'**
  String get xpHistoryDeleteDialogBody;

  /// No description provided for @xpHistoryAllDeleted.
  ///
  /// In en, this message translates to:
  /// **'All XP messages deleted.'**
  String get xpHistoryAllDeleted;

  /// No description provided for @xpHistoryRecentFlow.
  ///
  /// In en, this message translates to:
  /// **'Recent XP flow'**
  String get xpHistoryRecentFlow;

  /// No description provided for @xpHistorySummaryCount.
  ///
  /// In en, this message translates to:
  /// **'{count} history items are saved.'**
  String xpHistorySummaryCount(int count);

  /// No description provided for @xpHistorySummaryLatest.
  ///
  /// In en, this message translates to:
  /// **'Below, entries are arranged in date and time order. Latest entry: {title}.'**
  String xpHistorySummaryLatest(Object title);

  /// No description provided for @xpHistoryDayEventCount.
  ///
  /// In en, this message translates to:
  /// **'{count} XP events'**
  String xpHistoryDayEventCount(int count);

  /// No description provided for @xpHistoryDeleteMessageTooltip.
  ///
  /// In en, this message translates to:
  /// **'Delete message'**
  String get xpHistoryDeleteMessageTooltip;

  /// No description provided for @xpHistoryTotalXp.
  ///
  /// In en, this message translates to:
  /// **'{totalXp} XP total'**
  String xpHistoryTotalXp(int totalXp);

  /// No description provided for @xpHistoryStayedAtLevel.
  ///
  /// In en, this message translates to:
  /// **'Stayed at Lv.{level}'**
  String xpHistoryStayedAtLevel(int level);

  /// No description provided for @xpHistoryTrainingLog.
  ///
  /// In en, this message translates to:
  /// **'Training log'**
  String get xpHistoryTrainingLog;

  /// No description provided for @xpHistoryTrainingLogWithLabel.
  ///
  /// In en, this message translates to:
  /// **'Training log · {label}'**
  String xpHistoryTrainingLogWithLabel(Object label);

  /// No description provided for @xpHistoryMatchLog.
  ///
  /// In en, this message translates to:
  /// **'Match log saved'**
  String get xpHistoryMatchLog;

  /// No description provided for @xpHistoryMatchLogWithLabel.
  ///
  /// In en, this message translates to:
  /// **'Match log · {label}'**
  String xpHistoryMatchLogWithLabel(Object label);

  /// No description provided for @xpHistoryMealLog.
  ///
  /// In en, this message translates to:
  /// **'Meal log saved'**
  String get xpHistoryMealLog;

  /// No description provided for @xpHistoryQuizCompletion.
  ///
  /// In en, this message translates to:
  /// **'Quiz completion'**
  String get xpHistoryQuizCompletion;

  /// No description provided for @xpHistoryPlanCreated.
  ///
  /// In en, this message translates to:
  /// **'Training plan created'**
  String get xpHistoryPlanCreated;

  /// No description provided for @xpHistoryBoardSaved.
  ///
  /// In en, this message translates to:
  /// **'Training sketch saved'**
  String get xpHistoryBoardSaved;

  /// No description provided for @xpHistoryBoardSavedWithLabel.
  ///
  /// In en, this message translates to:
  /// **'Training sketch · {label}'**
  String xpHistoryBoardSavedWithLabel(Object label);

  /// No description provided for @xpHistoryDiaryCreated.
  ///
  /// In en, this message translates to:
  /// **'Today diary created'**
  String get xpHistoryDiaryCreated;

  /// No description provided for @xpHistoryDailyTasksComplete.
  ///
  /// In en, this message translates to:
  /// **'Today tasks complete'**
  String get xpHistoryDailyTasksComplete;

  /// No description provided for @xpHistoryTrainingLabelLifting.
  ///
  /// In en, this message translates to:
  /// **'Lifting'**
  String get xpHistoryTrainingLabelLifting;

  /// No description provided for @xpHistoryTrainingLabelJumpRope.
  ///
  /// In en, this message translates to:
  /// **'Jump rope'**
  String get xpHistoryTrainingLabelJumpRope;

  /// No description provided for @xpHistoryReasonLog.
  ///
  /// In en, this message translates to:
  /// **'base log'**
  String get xpHistoryReasonLog;

  /// No description provided for @xpHistoryReasonFirstDailyLog.
  ///
  /// In en, this message translates to:
  /// **'first of day'**
  String get xpHistoryReasonFirstDailyLog;

  /// No description provided for @xpHistoryReasonPlanCompleted.
  ///
  /// In en, this message translates to:
  /// **'planned day'**
  String get xpHistoryReasonPlanCompleted;

  /// No description provided for @xpHistoryReasonLiftingRecorded.
  ///
  /// In en, this message translates to:
  /// **'lifting recorded'**
  String get xpHistoryReasonLiftingRecorded;

  /// No description provided for @xpHistoryReasonJumpRopeRecorded.
  ///
  /// In en, this message translates to:
  /// **'jump rope recorded'**
  String get xpHistoryReasonJumpRopeRecorded;

  /// No description provided for @xpHistoryReasonLiftingMissed.
  ///
  /// In en, this message translates to:
  /// **'no lifting'**
  String get xpHistoryReasonLiftingMissed;

  /// No description provided for @xpHistoryReasonJumpRopeMissed.
  ///
  /// In en, this message translates to:
  /// **'no jump rope'**
  String get xpHistoryReasonJumpRopeMissed;

  /// No description provided for @xpHistoryReasonLiftingAdded.
  ///
  /// In en, this message translates to:
  /// **'lifting added'**
  String get xpHistoryReasonLiftingAdded;

  /// No description provided for @xpHistoryReasonJumpRopeAdded.
  ///
  /// In en, this message translates to:
  /// **'jump rope added'**
  String get xpHistoryReasonJumpRopeAdded;

  /// No description provided for @xpHistoryReasonMealTwoPlus.
  ///
  /// In en, this message translates to:
  /// **'2+ meals'**
  String get xpHistoryReasonMealTwoPlus;

  /// No description provided for @xpHistoryReasonMealFullDay.
  ///
  /// In en, this message translates to:
  /// **'3 meals complete'**
  String get xpHistoryReasonMealFullDay;

  /// No description provided for @xpHistoryReasonMealFullDayBonus.
  ///
  /// In en, this message translates to:
  /// **'3 meals + 5+ rice bowls'**
  String get xpHistoryReasonMealFullDayBonus;

  /// No description provided for @xpHistoryReasonStreak3.
  ///
  /// In en, this message translates to:
  /// **'3-day streak'**
  String get xpHistoryReasonStreak3;

  /// No description provided for @xpHistoryReasonStreak7.
  ///
  /// In en, this message translates to:
  /// **'7-day streak'**
  String get xpHistoryReasonStreak7;

  /// No description provided for @xpHistoryReasonStreakDaily2.
  ///
  /// In en, this message translates to:
  /// **'daily streak (2-3 days)'**
  String get xpHistoryReasonStreakDaily2;

  /// No description provided for @xpHistoryReasonStreakDaily4.
  ///
  /// In en, this message translates to:
  /// **'daily streak (4-6 days)'**
  String get xpHistoryReasonStreakDaily4;

  /// No description provided for @xpHistoryReasonStreakDaily7.
  ///
  /// In en, this message translates to:
  /// **'daily streak (7+ days)'**
  String get xpHistoryReasonStreakDaily7;

  /// No description provided for @xpHistoryReasonRoutineComplete.
  ///
  /// In en, this message translates to:
  /// **'daily routine complete'**
  String get xpHistoryReasonRoutineComplete;

  /// No description provided for @xpHistoryReasonWeekly3.
  ///
  /// In en, this message translates to:
  /// **'3 this week'**
  String get xpHistoryReasonWeekly3;

  /// No description provided for @xpHistoryReasonWeekly5.
  ///
  /// In en, this message translates to:
  /// **'5 this week'**
  String get xpHistoryReasonWeekly5;

  /// No description provided for @xpHistoryReasonQuizComplete.
  ///
  /// In en, this message translates to:
  /// **'quiz complete'**
  String get xpHistoryReasonQuizComplete;

  /// No description provided for @xpHistoryReasonPlanCreated.
  ///
  /// In en, this message translates to:
  /// **'plan created'**
  String get xpHistoryReasonPlanCreated;

  /// No description provided for @xpHistoryReasonPlanGroupCreated.
  ///
  /// In en, this message translates to:
  /// **'{count}-plan series'**
  String xpHistoryReasonPlanGroupCreated(int count);

  /// No description provided for @xpHistoryReasonMatchLogged.
  ///
  /// In en, this message translates to:
  /// **'match logged'**
  String get xpHistoryReasonMatchLogged;

  /// No description provided for @xpHistoryReasonMatchResultRecorded.
  ///
  /// In en, this message translates to:
  /// **'result recorded'**
  String get xpHistoryReasonMatchResultRecorded;

  /// No description provided for @xpHistoryReasonMatchContributionRecorded.
  ///
  /// In en, this message translates to:
  /// **'contribution recorded'**
  String get xpHistoryReasonMatchContributionRecorded;

  /// No description provided for @xpHistoryReasonBoardCreated.
  ///
  /// In en, this message translates to:
  /// **'board created'**
  String get xpHistoryReasonBoardCreated;

  /// No description provided for @xpHistoryReasonBoardSaved.
  ///
  /// In en, this message translates to:
  /// **'board saved'**
  String get xpHistoryReasonBoardSaved;

  /// No description provided for @xpHistoryReasonDiaryCreated.
  ///
  /// In en, this message translates to:
  /// **'diary created'**
  String get xpHistoryReasonDiaryCreated;

  /// No description provided for @xpHistoryReasonDailyTasksCompleted.
  ///
  /// In en, this message translates to:
  /// **'today tasks complete'**
  String get xpHistoryReasonDailyTasksCompleted;

  /// No description provided for @xpHistoryReasonDailyCap.
  ///
  /// In en, this message translates to:
  /// **'daily cap'**
  String get xpHistoryReasonDailyCap;

  /// No description provided for @profilePlayerLevelLabel.
  ///
  /// In en, this message translates to:
  /// **'Player level'**
  String get profilePlayerLevelLabel;

  /// No description provided for @profileVisualGrowthTier.
  ///
  /// In en, this message translates to:
  /// **'Visual growth tier'**
  String get profileVisualGrowthTier;

  /// No description provided for @profileRewardReadySummary.
  ///
  /// In en, this message translates to:
  /// **'{count} rewards ready'**
  String profileRewardReadySummary(int count);

  /// No description provided for @profileNoNextReward.
  ///
  /// In en, this message translates to:
  /// **'No next reward yet'**
  String get profileNoNextReward;

  /// No description provided for @profileRewardNow.
  ///
  /// In en, this message translates to:
  /// **'Reward now: {rewardName}'**
  String profileRewardNow(Object rewardName);

  /// No description provided for @profileNextReward.
  ///
  /// In en, this message translates to:
  /// **'Next reward Lv.{level} {rewardName}'**
  String profileNextReward(int level, Object rewardName);

  /// No description provided for @profilePlayerNumberLabel.
  ///
  /// In en, this message translates to:
  /// **'Player number'**
  String get profilePlayerNumberLabel;

  /// No description provided for @profilePlayerNumberHint.
  ///
  /// In en, this message translates to:
  /// **'Example: 10'**
  String get profilePlayerNumberHint;

  /// No description provided for @profileSportStartDateLabel.
  ///
  /// In en, this message translates to:
  /// **'{sport} start date'**
  String profileSportStartDateLabel(Object sport);

  /// No description provided for @profileLevelProgressMax.
  ///
  /// In en, this message translates to:
  /// **'{stars} mastery star(s) · {remainingXp} XP left'**
  String profileLevelProgressMax(int stars, int remainingXp);

  /// No description provided for @profileLevelProgressNext.
  ///
  /// In en, this message translates to:
  /// **'{remainingXp} XP to next level · {totalXp} XP total'**
  String profileLevelProgressNext(int remainingXp, int totalXp);

  /// No description provided for @homeLevelProgressMax.
  ///
  /// In en, this message translates to:
  /// **'{stars} star(s) · {remainingXp} XP left'**
  String homeLevelProgressMax(int stars, int remainingXp);

  /// No description provided for @homeLevelProgressNext.
  ///
  /// In en, this message translates to:
  /// **'{remainingXp} XP left'**
  String homeLevelProgressNext(int remainingXp);

  /// No description provided for @homePriorityCheckPlansMessage.
  ///
  /// In en, this message translates to:
  /// **'Review the remaining training plans before you start.'**
  String get homePriorityCheckPlansMessage;

  /// No description provided for @homePriorityPlansAction.
  ///
  /// In en, this message translates to:
  /// **'Plans'**
  String get homePriorityPlansAction;

  /// No description provided for @homePriorityPlanNextMessage.
  ///
  /// In en, this message translates to:
  /// **'Add a short training plan.'**
  String get homePriorityPlanNextMessage;

  /// No description provided for @homePriorityPlanNextAction.
  ///
  /// In en, this message translates to:
  /// **'Add plan'**
  String get homePriorityPlanNextAction;

  /// No description provided for @homePriorityReviewWeekMessage.
  ///
  /// In en, this message translates to:
  /// **'Review this week\'s training flow and choose the next target.'**
  String get homePriorityReviewWeekMessage;

  /// No description provided for @homePriorityStatsAction.
  ///
  /// In en, this message translates to:
  /// **'Stats'**
  String get homePriorityStatsAction;

  /// No description provided for @homePrioritySketchNextMessage.
  ///
  /// In en, this message translates to:
  /// **'Sketch the movement you want to try in your next session.'**
  String get homePrioritySketchNextMessage;

  /// No description provided for @homePriorityBoardAction.
  ///
  /// In en, this message translates to:
  /// **'Board'**
  String get homePriorityBoardAction;

  /// No description provided for @homePriorityConditionMessage.
  ///
  /// In en, this message translates to:
  /// **'Check your recent condition trend and adjust recovery.'**
  String get homePriorityConditionMessage;

  /// No description provided for @homePriorityRewardsMessage.
  ///
  /// In en, this message translates to:
  /// **'Review level rewards and the next growth target.'**
  String get homePriorityRewardsMessage;

  /// No description provided for @homePriorityLevelAction.
  ///
  /// In en, this message translates to:
  /// **'Level'**
  String get homePriorityLevelAction;

  /// No description provided for @homeMealSuggestionDoneShort.
  ///
  /// In en, this message translates to:
  /// **'All three meals are logged. Keep the rhythm going.'**
  String get homeMealSuggestionDoneShort;

  /// No description provided for @homeMealSuggestionTwoShort.
  ///
  /// In en, this message translates to:
  /// **'Please log one more meal.'**
  String get homeMealSuggestionTwoShort;

  /// No description provided for @homeMealSuggestionOneShort.
  ///
  /// In en, this message translates to:
  /// **'Please log two more meals.'**
  String get homeMealSuggestionOneShort;

  /// No description provided for @homeMealSuggestionNoneShort.
  ///
  /// In en, this message translates to:
  /// **'Please start with the first meal today.'**
  String get homeMealSuggestionNoneShort;

  /// No description provided for @homeNextTrainingTitle.
  ///
  /// In en, this message translates to:
  /// **'Next training'**
  String get homeNextTrainingTitle;

  /// No description provided for @homeNextTrainingToday.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get homeNextTrainingToday;

  /// No description provided for @homeNextTrainingTomorrow.
  ///
  /// In en, this message translates to:
  /// **'Tomorrow'**
  String get homeNextTrainingTomorrow;

  /// No description provided for @homeNextTrainingInDays.
  ///
  /// In en, this message translates to:
  /// **'In {count} days'**
  String homeNextTrainingInDays(int count);

  /// No description provided for @homeNextTrainingCount.
  ///
  /// In en, this message translates to:
  /// **'{count} planned'**
  String homeNextTrainingCount(int count);

  /// No description provided for @profileTestsActionLabel.
  ///
  /// In en, this message translates to:
  /// **'Profile tests'**
  String get profileTestsActionLabel;

  /// No description provided for @entryStartedFromPlanSummary.
  ///
  /// In en, this message translates to:
  /// **'Started from today’s plan: {summary}'**
  String entryStartedFromPlanSummary(String summary);

  /// No description provided for @fifaHubAppBarTitle.
  ///
  /// In en, this message translates to:
  /// **'FIFA Ranking Hub'**
  String get fifaHubAppBarTitle;

  /// No description provided for @fifaHubHeroTitle.
  ///
  /// In en, this message translates to:
  /// **'Worldwide FIFA ranking and A-match tracker'**
  String get fifaHubHeroTitle;

  /// No description provided for @fifaHubHeroSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Check the full rankings, recent results, and upcoming fixtures from FIFA official data.'**
  String get fifaHubHeroSubtitle;

  /// No description provided for @fifaHubMenLabel.
  ///
  /// In en, this message translates to:
  /// **'Men'**
  String get fifaHubMenLabel;

  /// No description provided for @fifaHubWomenLabel.
  ///
  /// In en, this message translates to:
  /// **'Women'**
  String get fifaHubWomenLabel;

  /// No description provided for @fifaHubLeaderLabel.
  ///
  /// In en, this message translates to:
  /// **'Current No. 1'**
  String get fifaHubLeaderLabel;

  /// No description provided for @fifaHubRankedTeamsCount.
  ///
  /// In en, this message translates to:
  /// **'{count} ranked teams'**
  String fifaHubRankedTeamsCount(int count);

  /// No description provided for @fifaHubConfederationCount.
  ///
  /// In en, this message translates to:
  /// **'{count} confederations'**
  String fifaHubConfederationCount(int count);

  /// No description provided for @fifaHubRecentResultsCount.
  ///
  /// In en, this message translates to:
  /// **'{count} recent results'**
  String fifaHubRecentResultsCount(int count);

  /// No description provided for @fifaHubUpcomingFixturesCount.
  ///
  /// In en, this message translates to:
  /// **'{count} upcoming fixtures'**
  String fifaHubUpcomingFixturesCount(int count);

  /// No description provided for @fifaHubNextUpdateLabel.
  ///
  /// In en, this message translates to:
  /// **'Next update'**
  String get fifaHubNextUpdateLabel;

  /// No description provided for @fifaHubDataSourceLabel.
  ///
  /// In en, this message translates to:
  /// **'Source: FIFA official ranking and live match feeds'**
  String get fifaHubDataSourceLabel;

  /// No description provided for @fifaHubHighlightsTitle.
  ///
  /// In en, this message translates to:
  /// **'Movement highlights'**
  String get fifaHubHighlightsTitle;

  /// No description provided for @fifaHubBiggestClimber.
  ///
  /// In en, this message translates to:
  /// **'Biggest climber'**
  String get fifaHubBiggestClimber;

  /// No description provided for @fifaHubBiggestFaller.
  ///
  /// In en, this message translates to:
  /// **'Biggest faller'**
  String get fifaHubBiggestFaller;

  /// No description provided for @fifaHubGlobalRankingTitle.
  ///
  /// In en, this message translates to:
  /// **'Global ranking'**
  String get fifaHubGlobalRankingTitle;

  /// No description provided for @fifaHubGlobalRankingSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Open sections to browse national teams without an inner scroll.'**
  String get fifaHubGlobalRankingSubtitle;

  /// No description provided for @fifaHubShowAll.
  ///
  /// In en, this message translates to:
  /// **'Show all'**
  String get fifaHubShowAll;

  /// No description provided for @fifaHubShowLess.
  ///
  /// In en, this message translates to:
  /// **'Show less'**
  String get fifaHubShowLess;

  /// No description provided for @fifaHubShowAllList.
  ///
  /// In en, this message translates to:
  /// **'Show full list'**
  String get fifaHubShowAllList;

  /// No description provided for @fifaHubCollapseList.
  ///
  /// In en, this message translates to:
  /// **'Collapse list'**
  String get fifaHubCollapseList;

  /// No description provided for @fifaHubRecentResultsTitle.
  ///
  /// In en, this message translates to:
  /// **'Recent worldwide A-match results'**
  String get fifaHubRecentResultsTitle;

  /// No description provided for @fifaHubRecentResultsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Senior national-team matches filtered from FIFA match feeds.'**
  String get fifaHubRecentResultsSubtitle;

  /// No description provided for @fifaHubRecentResultsEmpty.
  ///
  /// In en, this message translates to:
  /// **'No recent worldwide A-match results found.'**
  String get fifaHubRecentResultsEmpty;

  /// No description provided for @fifaHubUpcomingFixturesTitle.
  ///
  /// In en, this message translates to:
  /// **'Upcoming worldwide A-match fixtures'**
  String get fifaHubUpcomingFixturesTitle;

  /// No description provided for @fifaHubUpcomingFixturesSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Upcoming senior national-team fixtures from the latest FIFA schedule window.'**
  String get fifaHubUpcomingFixturesSubtitle;

  /// No description provided for @fifaHubUpcomingFixturesEmpty.
  ///
  /// In en, this message translates to:
  /// **'No upcoming worldwide A-match fixtures found.'**
  String get fifaHubUpcomingFixturesEmpty;

  /// No description provided for @fifaHubKfaUpcomingFixturesTitle.
  ///
  /// In en, this message translates to:
  /// **'KFA Korea match schedule'**
  String get fifaHubKfaUpcomingFixturesTitle;

  /// No description provided for @fifaHubKfaUpcomingFixturesSubtitle.
  ///
  /// In en, this message translates to:
  /// **'From the Korea Football Association official Next Match feed.'**
  String get fifaHubKfaUpcomingFixturesSubtitle;

  /// No description provided for @fifaHubKfaUpcomingFixturesEmpty.
  ///
  /// In en, this message translates to:
  /// **'No KFA Korea match schedule found.'**
  String get fifaHubKfaUpcomingFixturesEmpty;

  /// No description provided for @fifaHubKfaRecentResultsTitle.
  ///
  /// In en, this message translates to:
  /// **'KFA Korea match results'**
  String get fifaHubKfaRecentResultsTitle;

  /// No description provided for @fifaHubKfaRecentResultsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'From the Korea Football Association official Match Results feed.'**
  String get fifaHubKfaRecentResultsSubtitle;

  /// No description provided for @fifaHubKfaRecentResultsEmpty.
  ///
  /// In en, this message translates to:
  /// **'No KFA Korea match results found.'**
  String get fifaHubKfaRecentResultsEmpty;

  /// No description provided for @fifaHubMatchStatusResult.
  ///
  /// In en, this message translates to:
  /// **'Result'**
  String get fifaHubMatchStatusResult;

  /// No description provided for @fifaHubMatchStatusLive.
  ///
  /// In en, this message translates to:
  /// **'Live'**
  String get fifaHubMatchStatusLive;

  /// No description provided for @fifaHubMatchStatusFixture.
  ///
  /// In en, this message translates to:
  /// **'Fixture'**
  String get fifaHubMatchStatusFixture;

  /// No description provided for @fifaHubLoadError.
  ///
  /// In en, this message translates to:
  /// **'Failed to load FIFA data. Pull down to refresh.'**
  String get fifaHubLoadError;

  /// No description provided for @fifaHubNoData.
  ///
  /// In en, this message translates to:
  /// **'No FIFA ranking or A-match data is available right now.'**
  String get fifaHubNoData;

  /// No description provided for @fifaMatchDetailTitle.
  ///
  /// In en, this message translates to:
  /// **'Match detail'**
  String get fifaMatchDetailTitle;

  /// No description provided for @fifaMatchDetailResultSummaryTitle.
  ///
  /// In en, this message translates to:
  /// **'Result summary'**
  String get fifaMatchDetailResultSummaryTitle;

  /// No description provided for @fifaMatchDetailFixtureSummaryTitle.
  ///
  /// In en, this message translates to:
  /// **'Fixture summary'**
  String get fifaMatchDetailFixtureSummaryTitle;

  /// No description provided for @fifaMatchDetailCompetitionLabel.
  ///
  /// In en, this message translates to:
  /// **'Competition'**
  String get fifaMatchDetailCompetitionLabel;

  /// No description provided for @fifaMatchDetailKickoffLabel.
  ///
  /// In en, this message translates to:
  /// **'Kickoff'**
  String get fifaMatchDetailKickoffLabel;

  /// No description provided for @fifaMatchDetailDateLabel.
  ///
  /// In en, this message translates to:
  /// **'Date'**
  String get fifaMatchDetailDateLabel;

  /// No description provided for @fifaMatchDetailStageLabel.
  ///
  /// In en, this message translates to:
  /// **'Stage'**
  String get fifaMatchDetailStageLabel;

  /// No description provided for @fifaMatchDetailVenueLabel.
  ///
  /// In en, this message translates to:
  /// **'Venue'**
  String get fifaMatchDetailVenueLabel;

  /// No description provided for @fifaMatchDetailCityLabel.
  ///
  /// In en, this message translates to:
  /// **'City'**
  String get fifaMatchDetailCityLabel;

  /// No description provided for @fifaMatchDetailMatchIdLabel.
  ///
  /// In en, this message translates to:
  /// **'Match ID'**
  String get fifaMatchDetailMatchIdLabel;

  /// No description provided for @fifaMatchDetailScoreUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Score not confirmed'**
  String get fifaMatchDetailScoreUnavailable;

  /// No description provided for @fifaMatchDetailVersusLabel.
  ///
  /// In en, this message translates to:
  /// **'vs'**
  String get fifaMatchDetailVersusLabel;

  /// No description provided for @fifaMatchDetailHomeTeamLabel.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get fifaMatchDetailHomeTeamLabel;

  /// No description provided for @fifaMatchDetailAwayTeamLabel.
  ///
  /// In en, this message translates to:
  /// **'Away'**
  String get fifaMatchDetailAwayTeamLabel;

  /// No description provided for @fifaMatchDetailScorersTitle.
  ///
  /// In en, this message translates to:
  /// **'Scorers'**
  String get fifaMatchDetailScorersTitle;

  /// No description provided for @fifaMatchDetailPossessionTitle.
  ///
  /// In en, this message translates to:
  /// **'Ball possession'**
  String get fifaMatchDetailPossessionTitle;

  /// No description provided for @fifaMatchDetailAdvancedLoading.
  ///
  /// In en, this message translates to:
  /// **'Checking detailed records...'**
  String get fifaMatchDetailAdvancedLoading;

  /// No description provided for @fifaMatchDetailAdvancedUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Scorers and ball possession were not found in the source data.'**
  String get fifaMatchDetailAdvancedUnavailable;

  /// No description provided for @fifaMatchDetailScorersUnavailable.
  ///
  /// In en, this message translates to:
  /// **'No scorer information found.'**
  String get fifaMatchDetailScorersUnavailable;

  /// No description provided for @fifaMatchDetailPossessionUnavailable.
  ///
  /// In en, this message translates to:
  /// **'No ball possession information found.'**
  String get fifaMatchDetailPossessionUnavailable;

  /// No description provided for @fifaMatchDetailUnknownScorer.
  ///
  /// In en, this message translates to:
  /// **'Player not provided'**
  String get fifaMatchDetailUnknownScorer;

  /// No description provided for @fifaMatchDetailFifaSourceNote.
  ///
  /// In en, this message translates to:
  /// **'Based on the FIFA official match API.'**
  String get fifaMatchDetailFifaSourceNote;

  /// No description provided for @fifaMatchDetailKfaSourceNote.
  ///
  /// In en, this message translates to:
  /// **'Based on the KFA home feed. Scorers and ball possession may not be provided by the source.'**
  String get fifaMatchDetailKfaSourceNote;

  /// No description provided for @fifaMatchDetailOpenSource.
  ///
  /// In en, this message translates to:
  /// **'Open source'**
  String get fifaMatchDetailOpenSource;

  /// No description provided for @fifaCountryDetailRankingSummaryTitle.
  ///
  /// In en, this message translates to:
  /// **'Ranking summary'**
  String get fifaCountryDetailRankingSummaryTitle;

  /// No description provided for @fifaCountryDetailTeamProfileTitle.
  ///
  /// In en, this message translates to:
  /// **'Team profile'**
  String get fifaCountryDetailTeamProfileTitle;

  /// No description provided for @fifaCountryDetailCurrentRankLabel.
  ///
  /// In en, this message translates to:
  /// **'Current rank'**
  String get fifaCountryDetailCurrentRankLabel;

  /// No description provided for @fifaCountryDetailPreviousRankLabel.
  ///
  /// In en, this message translates to:
  /// **'Previous rank'**
  String get fifaCountryDetailPreviousRankLabel;

  /// No description provided for @fifaCountryDetailPointsLabel.
  ///
  /// In en, this message translates to:
  /// **'Points'**
  String get fifaCountryDetailPointsLabel;

  /// No description provided for @fifaCountryDetailPointChangeLabel.
  ///
  /// In en, this message translates to:
  /// **'Point change'**
  String get fifaCountryDetailPointChangeLabel;

  /// No description provided for @fifaCountryDetailConfederationLabel.
  ///
  /// In en, this message translates to:
  /// **'Confederation'**
  String get fifaCountryDetailConfederationLabel;

  /// No description provided for @fifaCountryDetailCountryCodeLabel.
  ///
  /// In en, this message translates to:
  /// **'Country code'**
  String get fifaCountryDetailCountryCodeLabel;

  /// No description provided for @fifaCountryDetailTeamIdLabel.
  ///
  /// In en, this message translates to:
  /// **'FIFA team ID'**
  String get fifaCountryDetailTeamIdLabel;

  /// No description provided for @fifaCountryDetailAbbreviationLabel.
  ///
  /// In en, this message translates to:
  /// **'Abbreviation'**
  String get fifaCountryDetailAbbreviationLabel;

  /// No description provided for @fifaCountryDetailFoundationYearLabel.
  ///
  /// In en, this message translates to:
  /// **'Founded'**
  String get fifaCountryDetailFoundationYearLabel;

  /// No description provided for @fifaCountryDetailCityLabel.
  ///
  /// In en, this message translates to:
  /// **'City'**
  String get fifaCountryDetailCityLabel;

  /// No description provided for @fifaCountryDetailStadiumLabel.
  ///
  /// In en, this message translates to:
  /// **'Stadium'**
  String get fifaCountryDetailStadiumLabel;

  /// No description provided for @fifaCountryDetailAddressLabel.
  ///
  /// In en, this message translates to:
  /// **'Address'**
  String get fifaCountryDetailAddressLabel;

  /// No description provided for @fifaCountryDetailProfileUnavailable.
  ///
  /// In en, this message translates to:
  /// **'No additional FIFA team profile is available right now.'**
  String get fifaCountryDetailProfileUnavailable;

  /// No description provided for @fifaCountryDetailProfileSource.
  ///
  /// In en, this message translates to:
  /// **'Profile data from FIFA official team API.'**
  String get fifaCountryDetailProfileSource;

  /// No description provided for @fifaCountryDetailRecentMatchesTitle.
  ///
  /// In en, this message translates to:
  /// **'This team\'s recent A-matches'**
  String get fifaCountryDetailRecentMatchesTitle;

  /// No description provided for @fifaCountryDetailUpcomingMatchesTitle.
  ///
  /// In en, this message translates to:
  /// **'This team\'s upcoming A-matches'**
  String get fifaCountryDetailUpcomingMatchesTitle;

  /// No description provided for @fifaCountryDetailMatchesUnavailable.
  ///
  /// In en, this message translates to:
  /// **'No matches for this team were found in the loaded FIFA feed.'**
  String get fifaCountryDetailMatchesUnavailable;

  /// No description provided for @tabGame.
  ///
  /// In en, this message translates to:
  /// **'Mini Game'**
  String get tabGame;

  /// No description provided for @drawerMainScreens.
  ///
  /// In en, this message translates to:
  /// **'Main screens'**
  String get drawerMainScreens;

  /// No description provided for @drawerQuickAdd.
  ///
  /// In en, this message translates to:
  /// **'Quick add'**
  String get drawerQuickAdd;

  /// No description provided for @drawerToolsContent.
  ///
  /// In en, this message translates to:
  /// **'Tools and content'**
  String get drawerToolsContent;

  /// No description provided for @drawerTrainingPlan.
  ///
  /// In en, this message translates to:
  /// **'Training plan'**
  String get drawerTrainingPlan;

  /// No description provided for @drawerMatch.
  ///
  /// In en, this message translates to:
  /// **'Match'**
  String get drawerMatch;

  /// No description provided for @drawerAddTrainingSketch.
  ///
  /// In en, this message translates to:
  /// **'Add training sketch'**
  String get drawerAddTrainingSketch;

  /// No description provided for @drawerNotifications.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get drawerNotifications;

  /// No description provided for @drawerQuiz.
  ///
  /// In en, this message translates to:
  /// **'Quiz'**
  String get drawerQuiz;

  /// No description provided for @addEntry.
  ///
  /// In en, this message translates to:
  /// **'Add Entry'**
  String get addEntry;

  /// No description provided for @editEntry.
  ///
  /// In en, this message translates to:
  /// **'Edit Entry'**
  String get editEntry;

  /// No description provided for @save.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// No description provided for @update.
  ///
  /// In en, this message translates to:
  /// **'Update'**
  String get update;

  /// No description provided for @add.
  ///
  /// In en, this message translates to:
  /// **'Add'**
  String get add;

  /// No description provided for @edit.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get edit;

  /// No description provided for @newItem.
  ///
  /// In en, this message translates to:
  /// **'New item'**
  String get newItem;

  /// No description provided for @trainingDate.
  ///
  /// In en, this message translates to:
  /// **'Training Date'**
  String get trainingDate;

  /// No description provided for @trainingDuration.
  ///
  /// In en, this message translates to:
  /// **'Training Duration'**
  String get trainingDuration;

  /// No description provided for @minutes.
  ///
  /// In en, this message translates to:
  /// **'{value} min'**
  String minutes(Object value);

  /// No description provided for @times.
  ///
  /// In en, this message translates to:
  /// **'{value} times'**
  String times(Object value);

  /// No description provided for @notSet.
  ///
  /// In en, this message translates to:
  /// **'Not set'**
  String get notSet;

  /// No description provided for @trainingType.
  ///
  /// In en, this message translates to:
  /// **'Training Type'**
  String get trainingType;

  /// No description provided for @status.
  ///
  /// In en, this message translates to:
  /// **'Training Status'**
  String get status;

  /// No description provided for @statusGreat.
  ///
  /// In en, this message translates to:
  /// **'Great'**
  String get statusGreat;

  /// No description provided for @statusGood.
  ///
  /// In en, this message translates to:
  /// **'Good'**
  String get statusGood;

  /// No description provided for @statusNormal.
  ///
  /// In en, this message translates to:
  /// **'Normal'**
  String get statusNormal;

  /// No description provided for @statusTough.
  ///
  /// In en, this message translates to:
  /// **'Tough'**
  String get statusTough;

  /// No description provided for @statusRecovery.
  ///
  /// In en, this message translates to:
  /// **'Recovery'**
  String get statusRecovery;

  /// No description provided for @typeTechnical.
  ///
  /// In en, this message translates to:
  /// **'Technical'**
  String get typeTechnical;

  /// No description provided for @typePhysical.
  ///
  /// In en, this message translates to:
  /// **'Physical'**
  String get typePhysical;

  /// No description provided for @typeTactical.
  ///
  /// In en, this message translates to:
  /// **'Tactical'**
  String get typeTactical;

  /// No description provided for @typeMatch.
  ///
  /// In en, this message translates to:
  /// **'Match'**
  String get typeMatch;

  /// No description provided for @typeRecovery.
  ///
  /// In en, this message translates to:
  /// **'Recovery'**
  String get typeRecovery;

  /// No description provided for @intensity.
  ///
  /// In en, this message translates to:
  /// **'Intensity'**
  String get intensity;

  /// No description provided for @condition.
  ///
  /// In en, this message translates to:
  /// **'Condition'**
  String get condition;

  /// No description provided for @location.
  ///
  /// In en, this message translates to:
  /// **'Location'**
  String get location;

  /// No description provided for @program.
  ///
  /// In en, this message translates to:
  /// **'Program'**
  String get program;

  /// No description provided for @entryProgramDurationsTitle.
  ///
  /// In en, this message translates to:
  /// **'Training program'**
  String get entryProgramDurationsTitle;

  /// No description provided for @entryProgramDurationsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Record the program and time together.'**
  String get entryProgramDurationsSubtitle;

  /// No description provided for @entryProgramDurationTotal.
  ///
  /// In en, this message translates to:
  /// **'Total {minutes}'**
  String entryProgramDurationTotal(Object minutes);

  /// No description provided for @entryProgramDurationAddAction.
  ///
  /// In en, this message translates to:
  /// **'Add program'**
  String get entryProgramDurationAddAction;

  /// No description provided for @entryProgramDurationRemoveTooltip.
  ///
  /// In en, this message translates to:
  /// **'Remove program time'**
  String get entryProgramDurationRemoveTooltip;

  /// No description provided for @entryProgramDurationEmpty.
  ///
  /// In en, this message translates to:
  /// **'Add a training program.'**
  String get entryProgramDurationEmpty;

  /// No description provided for @entryProgramOptionAddTooltip.
  ///
  /// In en, this message translates to:
  /// **'Add program option'**
  String get entryProgramOptionAddTooltip;

  /// No description provided for @entryDurationOptionAddTooltip.
  ///
  /// In en, this message translates to:
  /// **'Add time option'**
  String get entryDurationOptionAddTooltip;

  /// No description provided for @entryTodayGoalsTitle.
  ///
  /// In en, this message translates to:
  /// **'Today\'s goals'**
  String get entryTodayGoalsTitle;

  /// No description provided for @entryTodayGoalAddTitle.
  ///
  /// In en, this message translates to:
  /// **'Add today\'s goal'**
  String get entryTodayGoalAddTitle;

  /// No description provided for @entryTodayGoalAddTooltip.
  ///
  /// In en, this message translates to:
  /// **'Add goal'**
  String get entryTodayGoalAddTooltip;

  /// No description provided for @entryTodayGoalsSelectTooltip.
  ///
  /// In en, this message translates to:
  /// **'Select today\'s goals'**
  String get entryTodayGoalsSelectTooltip;

  /// No description provided for @entryTodayGoalsSelectTitle.
  ///
  /// In en, this message translates to:
  /// **'Select today\'s goals'**
  String get entryTodayGoalsSelectTitle;

  /// No description provided for @entryTodayGoalsDone.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get entryTodayGoalsDone;

  /// No description provided for @entryTodayGoalsNone.
  ///
  /// In en, this message translates to:
  /// **'No goals selected'**
  String get entryTodayGoalsNone;

  /// No description provided for @entryTodayGoalsSelectedCount.
  ///
  /// In en, this message translates to:
  /// **'{count} selected'**
  String entryTodayGoalsSelectedCount(int count);

  /// No description provided for @drills.
  ///
  /// In en, this message translates to:
  /// **'Session Drills'**
  String get drills;

  /// No description provided for @injury.
  ///
  /// In en, this message translates to:
  /// **'Injury'**
  String get injury;

  /// No description provided for @injuryPart.
  ///
  /// In en, this message translates to:
  /// **'Injury Part'**
  String get injuryPart;

  /// No description provided for @painLevel.
  ///
  /// In en, this message translates to:
  /// **'Pain Level (1-10)'**
  String get painLevel;

  /// No description provided for @rehab.
  ///
  /// In en, this message translates to:
  /// **'Rehab'**
  String get rehab;

  /// No description provided for @entryLesson.
  ///
  /// In en, this message translates to:
  /// **'Lesson'**
  String get entryLesson;

  /// No description provided for @entryLessonDetail.
  ///
  /// In en, this message translates to:
  /// **'Lesson detail'**
  String get entryLessonDetail;

  /// No description provided for @entryLessonDetailHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. 1:1 dribbling, shooting group lesson'**
  String get entryLessonDetailHint;

  /// No description provided for @goal.
  ///
  /// In en, this message translates to:
  /// **'Goal'**
  String get goal;

  /// No description provided for @feedback.
  ///
  /// In en, this message translates to:
  /// **'Feedback'**
  String get feedback;

  /// No description provided for @notes.
  ///
  /// In en, this message translates to:
  /// **'Notes'**
  String get notes;

  /// No description provided for @growth.
  ///
  /// In en, this message translates to:
  /// **'Growth'**
  String get growth;

  /// No description provided for @height.
  ///
  /// In en, this message translates to:
  /// **'Height (cm)'**
  String get height;

  /// No description provided for @weight.
  ///
  /// In en, this message translates to:
  /// **'Weight (kg)'**
  String get weight;

  /// No description provided for @calendar.
  ///
  /// In en, this message translates to:
  /// **'Calendar'**
  String get calendar;

  /// No description provided for @calendarFormatMonth.
  ///
  /// In en, this message translates to:
  /// **'Month'**
  String get calendarFormatMonth;

  /// No description provided for @calendarFormatTwoWeeks.
  ///
  /// In en, this message translates to:
  /// **'2 weeks'**
  String get calendarFormatTwoWeeks;

  /// No description provided for @calendarFormatWeek.
  ///
  /// In en, this message translates to:
  /// **'Week'**
  String get calendarFormatWeek;

  /// No description provided for @noEntries.
  ///
  /// In en, this message translates to:
  /// **'No entries yet.'**
  String get noEntries;

  /// No description provided for @noEntriesForDay.
  ///
  /// In en, this message translates to:
  /// **'No entries for this day.'**
  String get noEntriesForDay;

  /// No description provided for @noResults.
  ///
  /// In en, this message translates to:
  /// **'No entries match your search.'**
  String get noResults;

  /// No description provided for @searchHint.
  ///
  /// In en, this message translates to:
  /// **'Search training logs'**
  String get searchHint;

  /// No description provided for @filterTitle.
  ///
  /// In en, this message translates to:
  /// **'Filter logs'**
  String get filterTitle;

  /// No description provided for @filterAll.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get filterAll;

  /// No description provided for @filterInjuryOnly.
  ///
  /// In en, this message translates to:
  /// **'Injury only'**
  String get filterInjuryOnly;

  /// No description provided for @filterJumpRopeOnly.
  ///
  /// In en, this message translates to:
  /// **'Jump rope days only'**
  String get filterJumpRopeOnly;

  /// No description provided for @filterFeedbackOnly.
  ///
  /// In en, this message translates to:
  /// **'Feedback only'**
  String get filterFeedbackOnly;

  /// No description provided for @filterLessonOnly.
  ///
  /// In en, this message translates to:
  /// **'Lesson only'**
  String get filterLessonOnly;

  /// No description provided for @filterEmptyResetHint.
  ///
  /// In en, this message translates to:
  /// **'Reset filters to see more entries.'**
  String get filterEmptyResetHint;

  /// No description provided for @filterReset.
  ///
  /// In en, this message translates to:
  /// **'Reset'**
  String get filterReset;

  /// No description provided for @filterApply.
  ///
  /// In en, this message translates to:
  /// **'Apply'**
  String get filterApply;

  /// No description provided for @logsLayoutCard.
  ///
  /// In en, this message translates to:
  /// **'Card'**
  String get logsLayoutCard;

  /// No description provided for @logsLayoutList.
  ///
  /// In en, this message translates to:
  /// **'List'**
  String get logsLayoutList;

  /// No description provided for @logsTrainingSketchListLabel.
  ///
  /// In en, this message translates to:
  /// **'Training sketch list'**
  String get logsTrainingSketchListLabel;

  /// No description provided for @logsTrainingSketchTitle.
  ///
  /// In en, this message translates to:
  /// **'Sketches'**
  String get logsTrainingSketchTitle;

  /// No description provided for @logsEmptyFirstEntrySubtitle.
  ///
  /// In en, this message translates to:
  /// **'Create your first training note to start the flow.'**
  String get logsEmptyFirstEntrySubtitle;

  /// No description provided for @logsEntryDeletedSnack.
  ///
  /// In en, this message translates to:
  /// **'Entry deleted.'**
  String get logsEntryDeletedSnack;

  /// No description provided for @logsEntryDeleteUndoAction.
  ///
  /// In en, this message translates to:
  /// **'Undo'**
  String get logsEntryDeleteUndoAction;

  /// No description provided for @logsDeleteUndoneSnack.
  ///
  /// In en, this message translates to:
  /// **'Delete undone.'**
  String get logsDeleteUndoneSnack;

  /// No description provided for @deleteEntry.
  ///
  /// In en, this message translates to:
  /// **'Delete Entry'**
  String get deleteEntry;

  /// No description provided for @deleteConfirm.
  ///
  /// In en, this message translates to:
  /// **'Delete this entry?'**
  String get deleteConfirm;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @delete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get delete;

  /// No description provided for @undo.
  ///
  /// In en, this message translates to:
  /// **'Undo'**
  String get undo;

  /// No description provided for @statsRecent7.
  ///
  /// In en, this message translates to:
  /// **'Last 7 days'**
  String get statsRecent7;

  /// No description provided for @statsRecent30.
  ///
  /// In en, this message translates to:
  /// **'Last 30 days'**
  String get statsRecent30;

  /// No description provided for @statsTotalSessions.
  ///
  /// In en, this message translates to:
  /// **'Total Sessions'**
  String get statsTotalSessions;

  /// No description provided for @statsTotalMinutes.
  ///
  /// In en, this message translates to:
  /// **'Total Minutes'**
  String get statsTotalMinutes;

  /// No description provided for @statsAvgIntensity.
  ///
  /// In en, this message translates to:
  /// **'Avg Intensity'**
  String get statsAvgIntensity;

  /// No description provided for @statsAvgCondition.
  ///
  /// In en, this message translates to:
  /// **'Avg Condition'**
  String get statsAvgCondition;

  /// No description provided for @statsInjuryCount.
  ///
  /// In en, this message translates to:
  /// **'Injury Count'**
  String get statsInjuryCount;

  /// No description provided for @statsAvgPain.
  ///
  /// In en, this message translates to:
  /// **'Avg Pain'**
  String get statsAvgPain;

  /// No description provided for @statsRehabCount.
  ///
  /// In en, this message translates to:
  /// **'Rehab Count'**
  String get statsRehabCount;

  /// No description provided for @statsSummary.
  ///
  /// In en, this message translates to:
  /// **'Summary'**
  String get statsSummary;

  /// No description provided for @statsTypeRatio.
  ///
  /// In en, this message translates to:
  /// **'Training Program Ratio'**
  String get statsTypeRatio;

  /// No description provided for @statsWeeklyMinutes.
  ///
  /// In en, this message translates to:
  /// **'Weekly Minutes'**
  String get statsWeeklyMinutes;

  /// No description provided for @statsLoadingMessage.
  ///
  /// In en, this message translates to:
  /// **'Loading statistics...'**
  String get statsLoadingMessage;

  /// No description provided for @statsLoadFailedMessage.
  ///
  /// In en, this message translates to:
  /// **'There was a problem loading statistics.'**
  String get statsLoadFailedMessage;

  /// No description provided for @statsFallbackMessage.
  ///
  /// In en, this message translates to:
  /// **'Some stats failed to compute, showing fallback view.'**
  String get statsFallbackMessage;

  /// No description provided for @statsTrainingTab.
  ///
  /// In en, this message translates to:
  /// **'Training'**
  String get statsTrainingTab;

  /// No description provided for @statsMatchesTab.
  ///
  /// In en, this message translates to:
  /// **'Matches'**
  String get statsMatchesTab;

  /// No description provided for @statsNoMatchesSelectedPeriod.
  ///
  /// In en, this message translates to:
  /// **'No matches in the selected period.'**
  String get statsNoMatchesSelectedPeriod;

  /// No description provided for @statsRangePickerHelp.
  ///
  /// In en, this message translates to:
  /// **'Select period'**
  String get statsRangePickerHelp;

  /// No description provided for @statsWorkoutDaysNone.
  ///
  /// In en, this message translates to:
  /// **'Workout days: none'**
  String get statsWorkoutDaysNone;

  /// No description provided for @statsWorkoutDaysValue.
  ///
  /// In en, this message translates to:
  /// **'Workout days: {days}'**
  String statsWorkoutDaysValue(Object days);

  /// No description provided for @statsGrowthChartTitle.
  ///
  /// In en, this message translates to:
  /// **'Growth Chart'**
  String get statsGrowthChartTitle;

  /// No description provided for @statsActualLabel.
  ///
  /// In en, this message translates to:
  /// **'Actual'**
  String get statsActualLabel;

  /// No description provided for @statsTargetLabel.
  ///
  /// In en, this message translates to:
  /// **'Target'**
  String get statsTargetLabel;

  /// No description provided for @statsActualTimeDailyLabel.
  ///
  /// In en, this message translates to:
  /// **'Actual time (daily)'**
  String get statsActualTimeDailyLabel;

  /// No description provided for @statsAverageTargetTimeDailyLabel.
  ///
  /// In en, this message translates to:
  /// **'Average target time (daily)'**
  String get statsAverageTargetTimeDailyLabel;

  /// No description provided for @statsAllMatchRecordsTitle.
  ///
  /// In en, this message translates to:
  /// **'All Match Records'**
  String get statsAllMatchRecordsTitle;

  /// No description provided for @statsMatchMinutesPlayedValue.
  ///
  /// In en, this message translates to:
  /// **'{minutes} min'**
  String statsMatchMinutesPlayedValue(Object minutes);

  /// No description provided for @statsResultUnset.
  ///
  /// In en, this message translates to:
  /// **'Result unset'**
  String get statsResultUnset;

  /// No description provided for @statsOutcomeWin.
  ///
  /// In en, this message translates to:
  /// **'Win'**
  String get statsOutcomeWin;

  /// No description provided for @statsOutcomeDraw.
  ///
  /// In en, this message translates to:
  /// **'Draw'**
  String get statsOutcomeDraw;

  /// No description provided for @statsOutcomeLoss.
  ///
  /// In en, this message translates to:
  /// **'Loss'**
  String get statsOutcomeLoss;

  /// No description provided for @statsDurationZeroMinutes.
  ///
  /// In en, this message translates to:
  /// **'0m'**
  String get statsDurationZeroMinutes;

  /// No description provided for @statsDurationMinutes.
  ///
  /// In en, this message translates to:
  /// **'{minutes} min'**
  String statsDurationMinutes(Object minutes);

  /// No description provided for @statsDurationHours.
  ///
  /// In en, this message translates to:
  /// **'{hours} h'**
  String statsDurationHours(Object hours);

  /// No description provided for @statsDurationHoursMinutes.
  ///
  /// In en, this message translates to:
  /// **'{hours} h {minutes} min'**
  String statsDurationHoursMinutes(Object hours, Object minutes);

  /// No description provided for @statsCompactDurationZero.
  ///
  /// In en, this message translates to:
  /// **'0h'**
  String get statsCompactDurationZero;

  /// No description provided for @statsCompactDurationMinutes.
  ///
  /// In en, this message translates to:
  /// **'{minutes} m'**
  String statsCompactDurationMinutes(Object minutes);

  /// No description provided for @statsCompactDurationHours.
  ///
  /// In en, this message translates to:
  /// **'{hours} h'**
  String statsCompactDurationHours(Object hours);

  /// No description provided for @statsCompactDurationHoursMinutes.
  ///
  /// In en, this message translates to:
  /// **'{hours} h {minutes} m'**
  String statsCompactDurationHoursMinutes(Object hours, Object minutes);

  /// No description provided for @statsComparisonCurrentLabel.
  ///
  /// In en, this message translates to:
  /// **'Now'**
  String get statsComparisonCurrentLabel;

  /// No description provided for @statsComparisonAverageLabel.
  ///
  /// In en, this message translates to:
  /// **'Avg'**
  String get statsComparisonAverageLabel;

  /// No description provided for @growthHistory.
  ///
  /// In en, this message translates to:
  /// **'Growth History'**
  String get growthHistory;

  /// No description provided for @level.
  ///
  /// In en, this message translates to:
  /// **'Level {value}'**
  String level(Object value);

  /// No description provided for @levelUpRemaining.
  ///
  /// In en, this message translates to:
  /// **'{value} more to level up'**
  String levelUpRemaining(Object value);

  /// No description provided for @missionComplete.
  ///
  /// In en, this message translates to:
  /// **'Mission complete! Weekly goal achieved!'**
  String get missionComplete;

  /// No description provided for @missionKeepGoing.
  ///
  /// In en, this message translates to:
  /// **'Great job! Just a bit more to hit 3 sessions this week!'**
  String get missionKeepGoing;

  /// No description provided for @onboard1.
  ///
  /// In en, this message translates to:
  /// **'Log today’s training'**
  String get onboard1;

  /// No description provided for @onboard2.
  ///
  /// In en, this message translates to:
  /// **'Track your growth history'**
  String get onboard2;

  /// No description provided for @onboard3.
  ///
  /// In en, this message translates to:
  /// **'Level up with goals'**
  String get onboard3;

  /// No description provided for @next.
  ///
  /// In en, this message translates to:
  /// **'Next'**
  String get next;

  /// No description provided for @start.
  ///
  /// In en, this message translates to:
  /// **'Start'**
  String get start;

  /// No description provided for @heroMessage.
  ///
  /// In en, this message translates to:
  /// **'Great work today! Logging helps you grow faster.'**
  String get heroMessage;

  /// No description provided for @logsHeadline1.
  ///
  /// In en, this message translates to:
  /// **'Training'**
  String get logsHeadline1;

  /// No description provided for @logsHeadline2.
  ///
  /// In en, this message translates to:
  /// **'Sessions'**
  String get logsHeadline2;

  /// No description provided for @entryHeadline1.
  ///
  /// In en, this message translates to:
  /// **'Log'**
  String get entryHeadline1;

  /// No description provided for @entryHeadline2.
  ///
  /// In en, this message translates to:
  /// **'Your Training'**
  String get entryHeadline2;

  /// No description provided for @statsHeadline1.
  ///
  /// In en, this message translates to:
  /// **'Progress'**
  String get statsHeadline1;

  /// No description provided for @statsHeadline2.
  ///
  /// In en, this message translates to:
  /// **'Overview'**
  String get statsHeadline2;

  /// No description provided for @statsMatchTrendStable.
  ///
  /// In en, this message translates to:
  /// **'Recent match trend is stable.'**
  String get statsMatchTrendStable;

  /// No description provided for @statsMatchTrendNeedsAttention.
  ///
  /// In en, this message translates to:
  /// **'Result trend needs attention.'**
  String get statsMatchTrendNeedsAttention;

  /// No description provided for @statsMatchInsightMessage.
  ///
  /// In en, this message translates to:
  /// **'Across {count} matches: {primaryLabel} {primaryValue} · {secondaryLabel} {secondaryValue}. {direction}'**
  String statsMatchInsightMessage(
      int count,
      Object primaryLabel,
      int primaryValue,
      Object secondaryLabel,
      int secondaryValue,
      Object direction);

  /// No description provided for @statsReportTrainingTitle.
  ///
  /// In en, this message translates to:
  /// **'{sport} Growth Summary'**
  String statsReportTrainingTitle(Object sport);

  /// No description provided for @statsReportInsightTitle.
  ///
  /// In en, this message translates to:
  /// **'Period Report'**
  String get statsReportInsightTitle;

  /// No description provided for @statsReportTargetLabel.
  ///
  /// In en, this message translates to:
  /// **'Target'**
  String get statsReportTargetLabel;

  /// No description provided for @statsReportTargetPercentValue.
  ///
  /// In en, this message translates to:
  /// **'{percent}%'**
  String statsReportTargetPercentValue(int percent);

  /// No description provided for @statsReportNoTargetValue.
  ///
  /// In en, this message translates to:
  /// **'No baseline'**
  String get statsReportNoTargetValue;

  /// No description provided for @statsReportSessionsLabel.
  ///
  /// In en, this message translates to:
  /// **'Sessions'**
  String get statsReportSessionsLabel;

  /// No description provided for @statsReportSessionsValue.
  ///
  /// In en, this message translates to:
  /// **'{count}'**
  String statsReportSessionsValue(int count);

  /// No description provided for @statsReportTotalTimeLabel.
  ///
  /// In en, this message translates to:
  /// **'Total time'**
  String get statsReportTotalTimeLabel;

  /// No description provided for @statsReportTrainingRhythmLabel.
  ///
  /// In en, this message translates to:
  /// **'Training rhythm'**
  String get statsReportTrainingRhythmLabel;

  /// No description provided for @statsReportTrainingRhythmValue.
  ///
  /// In en, this message translates to:
  /// **'{sessions} sessions · {activeDays}/{periodDays} days'**
  String statsReportTrainingRhythmValue(
      int sessions, int activeDays, int periodDays);

  /// No description provided for @statsReportLessonCountLabel.
  ///
  /// In en, this message translates to:
  /// **'Lessons'**
  String get statsReportLessonCountLabel;

  /// No description provided for @statsReportLessonCountValue.
  ///
  /// In en, this message translates to:
  /// **'{count}'**
  String statsReportLessonCountValue(int count);

  /// No description provided for @statsReportActiveDaysLabel.
  ///
  /// In en, this message translates to:
  /// **'Logged days'**
  String get statsReportActiveDaysLabel;

  /// No description provided for @statsReportActiveDaysValue.
  ///
  /// In en, this message translates to:
  /// **'{activeDays}/{periodDays} days'**
  String statsReportActiveDaysValue(int activeDays, int periodDays);

  /// No description provided for @statsReportPlanExecutionLabel.
  ///
  /// In en, this message translates to:
  /// **'Plan execution'**
  String get statsReportPlanExecutionLabel;

  /// No description provided for @statsReportTargetPlanLabel.
  ///
  /// In en, this message translates to:
  /// **'Target / Plan'**
  String get statsReportTargetPlanLabel;

  /// No description provided for @statsReportTargetPlanValue.
  ///
  /// In en, this message translates to:
  /// **'Target {target} · Plan {plan}'**
  String statsReportTargetPlanValue(Object target, Object plan);

  /// No description provided for @statsReportNoPlanValue.
  ///
  /// In en, this message translates to:
  /// **'No plan'**
  String get statsReportNoPlanValue;

  /// No description provided for @statsReportFocusLabel.
  ///
  /// In en, this message translates to:
  /// **'Focus'**
  String get statsReportFocusLabel;

  /// No description provided for @statsReportDefaultFocus.
  ///
  /// In en, this message translates to:
  /// **'Fundamentals'**
  String get statsReportDefaultFocus;

  /// No description provided for @statsReportFocusStreakValue.
  ///
  /// In en, this message translates to:
  /// **'{focus} · {days}-day streak'**
  String statsReportFocusStreakValue(Object focus, int days);

  /// No description provided for @statsReportStreakLabel.
  ///
  /// In en, this message translates to:
  /// **'Consistency'**
  String get statsReportStreakLabel;

  /// No description provided for @statsReportStreakValue.
  ///
  /// In en, this message translates to:
  /// **'{days}-day streak'**
  String statsReportStreakValue(int days);

  /// No description provided for @statsReportMealCoverageLabel.
  ///
  /// In en, this message translates to:
  /// **'Meal coverage'**
  String get statsReportMealCoverageLabel;

  /// No description provided for @statsReportMealCoverageValue.
  ///
  /// In en, this message translates to:
  /// **'{mealDays}/{periodDays} days · 3 meals {fullMealDays} days'**
  String statsReportMealCoverageValue(
      int mealDays, int periodDays, int fullMealDays);

  /// No description provided for @statsReportConditionLabel.
  ///
  /// In en, this message translates to:
  /// **'Condition'**
  String get statsReportConditionLabel;

  /// No description provided for @statsReportConditionValue.
  ///
  /// In en, this message translates to:
  /// **'Load {intensity} · Mood {mood} · Injury {injuryDays}d'**
  String statsReportConditionValue(
      Object intensity, Object mood, int injuryDays);

  /// No description provided for @statsReportConditioningValue.
  ///
  /// In en, this message translates to:
  /// **'{minutes} min · {count} reps'**
  String statsReportConditioningValue(int minutes, int count);

  /// No description provided for @statsReportInsightRecovery.
  ///
  /// In en, this message translates to:
  /// **'There are {injuryDays} injury days and average mood is {mood}. Check recovery load and pain changes first in the next log.'**
  String statsReportInsightRecovery(int injuryDays, Object mood);

  /// No description provided for @statsReportInsightNeedsVolume.
  ///
  /// In en, this message translates to:
  /// **'{sport} volume is {percent}% of target. You logged {activeDays}/{periodDays} days, so add shorter sessions more often next period.'**
  String statsReportInsightNeedsVolume(
      Object sport, int percent, int activeDays, int periodDays);

  /// No description provided for @statsReportInsightMealGap.
  ///
  /// In en, this message translates to:
  /// **'Meals were logged on {mealDays} of {activeDays} training days. Log meals with training days to judge recovery better.'**
  String statsReportInsightMealGap(int mealDays, int activeDays);

  /// No description provided for @statsReportInsightNoConditioning.
  ///
  /// In en, this message translates to:
  /// **'{primaryLabel}/{secondaryLabel} records are empty. Add sport-specific conditioning to read growth trends more accurately.'**
  String statsReportInsightNoConditioning(
      Object primaryLabel, Object secondaryLabel);

  /// No description provided for @statsReportInsightBalanced.
  ///
  /// In en, this message translates to:
  /// **'{sport} was logged on {activeDays}/{periodDays} days, with conditioning and meal flow visible. Next period, compare the quality of your most frequent focus.'**
  String statsReportInsightBalanced(
      Object sport, int activeDays, int periodDays);

  /// No description provided for @statsSecondaryConditioningNoRecords.
  ///
  /// In en, this message translates to:
  /// **'No {label} detail records in the selected period.'**
  String statsSecondaryConditioningNoRecords(Object label);

  /// No description provided for @statsSecondaryConditioningDailyTotals.
  ///
  /// In en, this message translates to:
  /// **'Daily {label} totals'**
  String statsSecondaryConditioningDailyTotals(Object label);

  /// No description provided for @statsPrimaryConditioningStatsTitle.
  ///
  /// In en, this message translates to:
  /// **'{label} Stats'**
  String statsPrimaryConditioningStatsTitle(Object label);

  /// No description provided for @statsPrimaryConditioningNoRecords.
  ///
  /// In en, this message translates to:
  /// **'No {label} count or time recorded in the selected period.'**
  String statsPrimaryConditioningNoRecords(Object label);

  /// No description provided for @statsPrimaryConditioningTooltipCount.
  ///
  /// In en, this message translates to:
  /// **'{label} {count} reps'**
  String statsPrimaryConditioningTooltipCount(Object label, int count);

  /// No description provided for @statsPrimaryConditioningTooltipMinutes.
  ///
  /// In en, this message translates to:
  /// **'{label} {minutes} min'**
  String statsPrimaryConditioningTooltipMinutes(Object label, int minutes);

  /// No description provided for @statsPrimaryConditioningDailyCount.
  ///
  /// In en, this message translates to:
  /// **'Daily {label} count'**
  String statsPrimaryConditioningDailyCount(Object label);

  /// No description provided for @statsPrimaryConditioningDailyMinutes.
  ///
  /// In en, this message translates to:
  /// **'Daily {label} time'**
  String statsPrimaryConditioningDailyMinutes(Object label);

  /// No description provided for @statsPrimaryConditioningTotalCount.
  ///
  /// In en, this message translates to:
  /// **'Total {count} reps'**
  String statsPrimaryConditioningTotalCount(int count);

  /// No description provided for @statsPrimaryConditioningTotalMinutes.
  ///
  /// In en, this message translates to:
  /// **'Total {minutes} min'**
  String statsPrimaryConditioningTotalMinutes(int minutes);

  /// No description provided for @statsPrimaryConditioningBestCount.
  ///
  /// In en, this message translates to:
  /// **'Best {month}/{day} · {count} reps'**
  String statsPrimaryConditioningBestCount(int month, int day, int count);

  /// No description provided for @statsPrimaryConditioningBestMinutes.
  ///
  /// In en, this message translates to:
  /// **'Best {month}/{day} · {minutes} min'**
  String statsPrimaryConditioningBestMinutes(int month, int day, int minutes);

  /// No description provided for @statsMatchFormTitle.
  ///
  /// In en, this message translates to:
  /// **'{sport} Match Report'**
  String statsMatchFormTitle(Object sport);

  /// No description provided for @statsMatchSummaryTitle.
  ///
  /// In en, this message translates to:
  /// **'Match Summary'**
  String get statsMatchSummaryTitle;

  /// No description provided for @statsMatchResultGroupTitle.
  ///
  /// In en, this message translates to:
  /// **'Result Metrics'**
  String get statsMatchResultGroupTitle;

  /// No description provided for @statsMatchPersonalGroupTitle.
  ///
  /// In en, this message translates to:
  /// **'Personal Contribution'**
  String get statsMatchPersonalGroupTitle;

  /// No description provided for @statsMatchTotalMatchesLabel.
  ///
  /// In en, this message translates to:
  /// **'Matches'**
  String get statsMatchTotalMatchesLabel;

  /// No description provided for @statsMatchTotalMatchesValue.
  ///
  /// In en, this message translates to:
  /// **'{count}'**
  String statsMatchTotalMatchesValue(int count);

  /// No description provided for @statsMatchRecordLabel.
  ///
  /// In en, this message translates to:
  /// **'Record'**
  String get statsMatchRecordLabel;

  /// No description provided for @statsMatchRecordValue.
  ///
  /// In en, this message translates to:
  /// **'{wins}-{draws}-{losses}'**
  String statsMatchRecordValue(int wins, int draws, int losses);

  /// No description provided for @statsMatchTypeLabel.
  ///
  /// In en, this message translates to:
  /// **'Match type'**
  String get statsMatchTypeLabel;

  /// No description provided for @statsMatchGoalsLabel.
  ///
  /// In en, this message translates to:
  /// **'Scoreline'**
  String get statsMatchGoalsLabel;

  /// No description provided for @statsMatchPersonalTotalLabel.
  ///
  /// In en, this message translates to:
  /// **'Personal total'**
  String get statsMatchPersonalTotalLabel;

  /// No description provided for @statsMatchPersonalDetailLabel.
  ///
  /// In en, this message translates to:
  /// **'Detail contribution'**
  String get statsMatchPersonalDetailLabel;

  /// No description provided for @statsMatchFormInsightTitle.
  ///
  /// In en, this message translates to:
  /// **'Match Flow'**
  String get statsMatchFormInsightTitle;

  /// No description provided for @statsMatchFormLabel.
  ///
  /// In en, this message translates to:
  /// **'Recent form'**
  String get statsMatchFormLabel;

  /// No description provided for @statsMatchFormUnsetValue.
  ///
  /// In en, this message translates to:
  /// **'No results'**
  String get statsMatchFormUnsetValue;

  /// No description provided for @statsMatchUnsetValue.
  ///
  /// In en, this message translates to:
  /// **'Not set'**
  String get statsMatchUnsetValue;

  /// No description provided for @statsMatchOutcomeWinShort.
  ///
  /// In en, this message translates to:
  /// **'W'**
  String get statsMatchOutcomeWinShort;

  /// No description provided for @statsMatchOutcomeDrawShort.
  ///
  /// In en, this message translates to:
  /// **'D'**
  String get statsMatchOutcomeDrawShort;

  /// No description provided for @statsMatchOutcomeLossShort.
  ///
  /// In en, this message translates to:
  /// **'L'**
  String get statsMatchOutcomeLossShort;

  /// No description provided for @statsMatchWinRateLabel.
  ///
  /// In en, this message translates to:
  /// **'Win rate'**
  String get statsMatchWinRateLabel;

  /// No description provided for @statsMatchWinRateValue.
  ///
  /// In en, this message translates to:
  /// **'{percent}%'**
  String statsMatchWinRateValue(int percent);

  /// No description provided for @statsMatchAverageScoreLabel.
  ///
  /// In en, this message translates to:
  /// **'Avg score'**
  String get statsMatchAverageScoreLabel;

  /// No description provided for @statsMatchAverageScoreValue.
  ///
  /// In en, this message translates to:
  /// **'{scored}:{conceded}'**
  String statsMatchAverageScoreValue(Object scored, Object conceded);

  /// No description provided for @statsMatchPersonalPerMatchLabel.
  ///
  /// In en, this message translates to:
  /// **'Personal per match'**
  String get statsMatchPersonalPerMatchLabel;

  /// No description provided for @statsMatchPersonalPerMatchValue.
  ///
  /// In en, this message translates to:
  /// **'{primaryLabel} {primaryValue} · {secondaryLabel} {secondaryValue}'**
  String statsMatchPersonalPerMatchValue(Object primaryLabel,
      Object primaryValue, Object secondaryLabel, Object secondaryValue);

  /// No description provided for @statsMatchPerUnitLabel.
  ///
  /// In en, this message translates to:
  /// **'Per {minutes} min'**
  String statsMatchPerUnitLabel(int minutes);

  /// No description provided for @statsMatchPerUnitValue.
  ///
  /// In en, this message translates to:
  /// **'{primaryLabel} {primaryValue} · {secondaryLabel} {secondaryValue}'**
  String statsMatchPerUnitValue(Object primaryLabel, Object primaryValue,
      Object secondaryLabel, Object secondaryValue);

  /// No description provided for @statsMatchMinutesLabel.
  ///
  /// In en, this message translates to:
  /// **'Minutes played'**
  String get statsMatchMinutesLabel;

  /// No description provided for @statsMatchNoMinutesValue.
  ///
  /// In en, this message translates to:
  /// **'No minutes'**
  String get statsMatchNoMinutesValue;

  /// No description provided for @statsMatchFormInsightNoResults.
  ///
  /// In en, this message translates to:
  /// **'{sport} match results are still missing. Add scores and personal records together to calculate form.'**
  String statsMatchFormInsightNoResults(Object sport);

  /// No description provided for @statsMatchFormInsightPositive.
  ///
  /// In en, this message translates to:
  /// **'Recent {sport} form is {form}, with a {winRate}% win rate. Repeat the personal records that led to your strengths next match.'**
  String statsMatchFormInsightPositive(Object sport, Object form, int winRate);

  /// No description provided for @statsMatchFormInsightNeedsWork.
  ///
  /// In en, this message translates to:
  /// **'Recent {sport} form is {form}, with a {winRate}% win rate. Check where result patterns and personal records drop together.'**
  String statsMatchFormInsightNeedsWork(Object sport, Object form, int winRate);

  /// No description provided for @statsCompetitionDashboardTitle.
  ///
  /// In en, this message translates to:
  /// **'Competition board'**
  String get statsCompetitionDashboardTitle;

  /// No description provided for @statsCompetitionLeagueSectionTitle.
  ///
  /// In en, this message translates to:
  /// **'League competitions'**
  String get statsCompetitionLeagueSectionTitle;

  /// No description provided for @statsCompetitionTournamentSectionTitle.
  ///
  /// In en, this message translates to:
  /// **'Tournament competitions'**
  String get statsCompetitionTournamentSectionTitle;

  /// No description provided for @statsCompetitionProgressValue.
  ///
  /// In en, this message translates to:
  /// **'{recorded}/{total}'**
  String statsCompetitionProgressValue(int recorded, int total);

  /// No description provided for @statsCompetitionMoreCount.
  ///
  /// In en, this message translates to:
  /// **'{count} more'**
  String statsCompetitionMoreCount(int count);

  /// No description provided for @statsCompetitionOpponentUnset.
  ///
  /// In en, this message translates to:
  /// **'Opponent unset'**
  String get statsCompetitionOpponentUnset;

  /// No description provided for @averageComparisonProfileMissingTitle.
  ///
  /// In en, this message translates to:
  /// **'Enter age and sport experience'**
  String get averageComparisonProfileMissingTitle;

  /// No description provided for @averageComparisonProfileMissingMessage.
  ///
  /// In en, this message translates to:
  /// **'Average comparison is hidden because age and sport experience are missing. Add birth date and sport start date in profile.'**
  String get averageComparisonProfileMissingMessage;

  /// No description provided for @averageComparisonOpenProfileAction.
  ///
  /// In en, this message translates to:
  /// **'Open Profile'**
  String get averageComparisonOpenProfileAction;

  /// No description provided for @averageComparisonTitle.
  ///
  /// In en, this message translates to:
  /// **'Average Comparison'**
  String get averageComparisonTitle;

  /// No description provided for @averageComparisonReferenceAction.
  ///
  /// In en, this message translates to:
  /// **'References'**
  String get averageComparisonReferenceAction;

  /// No description provided for @averageComparisonHiddenMessage.
  ///
  /// In en, this message translates to:
  /// **'Average comparison is hidden because age/experience is not set.'**
  String get averageComparisonHiddenMessage;

  /// No description provided for @averageComparisonHeightLabel.
  ///
  /// In en, this message translates to:
  /// **'Height'**
  String get averageComparisonHeightLabel;

  /// No description provided for @averageComparisonWeightLabel.
  ///
  /// In en, this message translates to:
  /// **'Weight'**
  String get averageComparisonWeightLabel;

  /// No description provided for @averageComparisonNotSet.
  ///
  /// In en, this message translates to:
  /// **'Not set'**
  String get averageComparisonNotSet;

  /// No description provided for @averageComparisonHiddenValue.
  ///
  /// In en, this message translates to:
  /// **'Hidden'**
  String get averageComparisonHiddenValue;

  /// No description provided for @averageComparisonUnavailableValue.
  ///
  /// In en, this message translates to:
  /// **'N/A'**
  String get averageComparisonUnavailableValue;

  /// No description provided for @averageComparisonHiddenGap.
  ///
  /// In en, this message translates to:
  /// **'Hidden'**
  String get averageComparisonHiddenGap;

  /// No description provided for @averageComparisonGapValue.
  ///
  /// In en, this message translates to:
  /// **'{gap} vs avg'**
  String averageComparisonGapValue(Object gap);

  /// No description provided for @averageComparisonConditioningPerSessionLabel.
  ///
  /// In en, this message translates to:
  /// **'{metric}/session'**
  String averageComparisonConditioningPerSessionLabel(Object metric);

  /// No description provided for @averageComparisonFootballOnlyTitle.
  ///
  /// In en, this message translates to:
  /// **'Football average comparison hidden'**
  String get averageComparisonFootballOnlyTitle;

  /// No description provided for @averageComparisonFootballOnlyMessage.
  ///
  /// In en, this message translates to:
  /// **'This average comparison uses soccer juggling reference ranges, so it is not shown for the current sport.'**
  String get averageComparisonFootballOnlyMessage;

  /// No description provided for @durationNotSet.
  ///
  /// In en, this message translates to:
  /// **'No time'**
  String get durationNotSet;

  /// No description provided for @defaultLocation1.
  ///
  /// In en, this message translates to:
  /// **'School field'**
  String get defaultLocation1;

  /// No description provided for @defaultLocation2.
  ///
  /// In en, this message translates to:
  /// **'Community field'**
  String get defaultLocation2;

  /// No description provided for @defaultLocation3.
  ///
  /// In en, this message translates to:
  /// **'Indoor gym'**
  String get defaultLocation3;

  /// No description provided for @defaultProgram1.
  ///
  /// In en, this message translates to:
  /// **'Fundamentals'**
  String get defaultProgram1;

  /// No description provided for @defaultProgram2.
  ///
  /// In en, this message translates to:
  /// **'Physical'**
  String get defaultProgram2;

  /// No description provided for @defaultProgram3.
  ///
  /// In en, this message translates to:
  /// **'Tactical'**
  String get defaultProgram3;

  /// No description provided for @defaultProgram4.
  ///
  /// In en, this message translates to:
  /// **'Recovery'**
  String get defaultProgram4;

  /// No description provided for @sport.
  ///
  /// In en, this message translates to:
  /// **'Sport'**
  String get sport;

  /// No description provided for @sportFootball.
  ///
  /// In en, this message translates to:
  /// **'Football'**
  String get sportFootball;

  /// No description provided for @sportBaseball.
  ///
  /// In en, this message translates to:
  /// **'Baseball'**
  String get sportBaseball;

  /// No description provided for @sportBasketball.
  ///
  /// In en, this message translates to:
  /// **'Basketball'**
  String get sportBasketball;

  /// No description provided for @sportTennis.
  ///
  /// In en, this message translates to:
  /// **'Tennis'**
  String get sportTennis;

  /// No description provided for @footballGoalDribbling.
  ///
  /// In en, this message translates to:
  /// **'Dribbling'**
  String get footballGoalDribbling;

  /// No description provided for @footballGoalPassingAccuracy.
  ///
  /// In en, this message translates to:
  /// **'Passing Accuracy'**
  String get footballGoalPassingAccuracy;

  /// No description provided for @footballGoalShooting.
  ///
  /// In en, this message translates to:
  /// **'Shooting'**
  String get footballGoalShooting;

  /// No description provided for @footballGoalFitness.
  ///
  /// In en, this message translates to:
  /// **'Fitness'**
  String get footballGoalFitness;

  /// No description provided for @footballGoalDefensivePositioning.
  ///
  /// In en, this message translates to:
  /// **'Defensive Positioning'**
  String get footballGoalDefensivePositioning;

  /// No description provided for @footballGoalFirstTouch.
  ///
  /// In en, this message translates to:
  /// **'First Touch'**
  String get footballGoalFirstTouch;

  /// No description provided for @baseballProgramThrowing.
  ///
  /// In en, this message translates to:
  /// **'Throwing'**
  String get baseballProgramThrowing;

  /// No description provided for @baseballProgramBatting.
  ///
  /// In en, this message translates to:
  /// **'Batting'**
  String get baseballProgramBatting;

  /// No description provided for @baseballProgramFielding.
  ///
  /// In en, this message translates to:
  /// **'Fielding'**
  String get baseballProgramFielding;

  /// No description provided for @baseballProgramBaseRunning.
  ///
  /// In en, this message translates to:
  /// **'Base Running'**
  String get baseballProgramBaseRunning;

  /// No description provided for @baseballProgramConditioning.
  ///
  /// In en, this message translates to:
  /// **'Conditioning'**
  String get baseballProgramConditioning;

  /// No description provided for @baseballProgramRecovery.
  ///
  /// In en, this message translates to:
  /// **'Recovery'**
  String get baseballProgramRecovery;

  /// No description provided for @baseballGoalThrowingAccuracy.
  ///
  /// In en, this message translates to:
  /// **'Throwing Accuracy'**
  String get baseballGoalThrowingAccuracy;

  /// No description provided for @baseballGoalBattingContact.
  ///
  /// In en, this message translates to:
  /// **'Batting Contact'**
  String get baseballGoalBattingContact;

  /// No description provided for @baseballGoalFieldingGlove.
  ///
  /// In en, this message translates to:
  /// **'Fielding Glove'**
  String get baseballGoalFieldingGlove;

  /// No description provided for @baseballGoalBaseRunning.
  ///
  /// In en, this message translates to:
  /// **'Base Running'**
  String get baseballGoalBaseRunning;

  /// No description provided for @baseballGoalReactionSpeed.
  ///
  /// In en, this message translates to:
  /// **'Reaction Speed'**
  String get baseballGoalReactionSpeed;

  /// No description provided for @baseballGoalGameAwareness.
  ///
  /// In en, this message translates to:
  /// **'Game Awareness'**
  String get baseballGoalGameAwareness;

  /// No description provided for @basketballProgramBallHandling.
  ///
  /// In en, this message translates to:
  /// **'Ball Handling'**
  String get basketballProgramBallHandling;

  /// No description provided for @basketballProgramShooting.
  ///
  /// In en, this message translates to:
  /// **'Shooting'**
  String get basketballProgramShooting;

  /// No description provided for @basketballProgramPassing.
  ///
  /// In en, this message translates to:
  /// **'Passing'**
  String get basketballProgramPassing;

  /// No description provided for @basketballProgramDefense.
  ///
  /// In en, this message translates to:
  /// **'Defense'**
  String get basketballProgramDefense;

  /// No description provided for @basketballProgramConditioning.
  ///
  /// In en, this message translates to:
  /// **'Conditioning'**
  String get basketballProgramConditioning;

  /// No description provided for @basketballProgramRecovery.
  ///
  /// In en, this message translates to:
  /// **'Recovery'**
  String get basketballProgramRecovery;

  /// No description provided for @basketballGoalBallHandling.
  ///
  /// In en, this message translates to:
  /// **'Ball Handling'**
  String get basketballGoalBallHandling;

  /// No description provided for @basketballGoalShootingForm.
  ///
  /// In en, this message translates to:
  /// **'Shooting Form'**
  String get basketballGoalShootingForm;

  /// No description provided for @basketballGoalPassingChoices.
  ///
  /// In en, this message translates to:
  /// **'Passing Choices'**
  String get basketballGoalPassingChoices;

  /// No description provided for @basketballGoalDefensiveFootwork.
  ///
  /// In en, this message translates to:
  /// **'Defensive Footwork'**
  String get basketballGoalDefensiveFootwork;

  /// No description provided for @basketballGoalRebounding.
  ///
  /// In en, this message translates to:
  /// **'Rebounding'**
  String get basketballGoalRebounding;

  /// No description provided for @basketballGoalFitness.
  ///
  /// In en, this message translates to:
  /// **'Fitness'**
  String get basketballGoalFitness;

  /// No description provided for @tennisProgramStroke.
  ///
  /// In en, this message translates to:
  /// **'Stroke'**
  String get tennisProgramStroke;

  /// No description provided for @tennisProgramServe.
  ///
  /// In en, this message translates to:
  /// **'Serve'**
  String get tennisProgramServe;

  /// No description provided for @tennisProgramFootwork.
  ///
  /// In en, this message translates to:
  /// **'Footwork'**
  String get tennisProgramFootwork;

  /// No description provided for @tennisProgramMatchPlay.
  ///
  /// In en, this message translates to:
  /// **'Match Play'**
  String get tennisProgramMatchPlay;

  /// No description provided for @tennisProgramConditioning.
  ///
  /// In en, this message translates to:
  /// **'Conditioning'**
  String get tennisProgramConditioning;

  /// No description provided for @tennisProgramRecovery.
  ///
  /// In en, this message translates to:
  /// **'Recovery'**
  String get tennisProgramRecovery;

  /// No description provided for @tennisGoalServeConsistency.
  ///
  /// In en, this message translates to:
  /// **'Serve Consistency'**
  String get tennisGoalServeConsistency;

  /// No description provided for @tennisGoalForehand.
  ///
  /// In en, this message translates to:
  /// **'Forehand'**
  String get tennisGoalForehand;

  /// No description provided for @tennisGoalBackhand.
  ///
  /// In en, this message translates to:
  /// **'Backhand'**
  String get tennisGoalBackhand;

  /// No description provided for @tennisGoalFootwork.
  ///
  /// In en, this message translates to:
  /// **'Footwork'**
  String get tennisGoalFootwork;

  /// No description provided for @tennisGoalRallyConsistency.
  ///
  /// In en, this message translates to:
  /// **'Rally Consistency'**
  String get tennisGoalRallyConsistency;

  /// No description provided for @tennisGoalMatchStrategy.
  ///
  /// In en, this message translates to:
  /// **'Match Strategy'**
  String get tennisGoalMatchStrategy;

  /// No description provided for @baseballConditioningPrimary.
  ///
  /// In en, this message translates to:
  /// **'Sprint work'**
  String get baseballConditioningPrimary;

  /// No description provided for @baseballConditioningSecondary.
  ///
  /// In en, this message translates to:
  /// **'Catch play'**
  String get baseballConditioningSecondary;

  /// No description provided for @baseballConditioningDetailTitle.
  ///
  /// In en, this message translates to:
  /// **'Catch play details'**
  String get baseballConditioningDetailTitle;

  /// No description provided for @baseballConditioningDetailShortThrow.
  ///
  /// In en, this message translates to:
  /// **'Short throws'**
  String get baseballConditioningDetailShortThrow;

  /// No description provided for @baseballConditioningDetailLongThrow.
  ///
  /// In en, this message translates to:
  /// **'Long throws'**
  String get baseballConditioningDetailLongThrow;

  /// No description provided for @baseballConditioningDetailGrounder.
  ///
  /// In en, this message translates to:
  /// **'Grounders'**
  String get baseballConditioningDetailGrounder;

  /// No description provided for @baseballConditioningDetailFlyBall.
  ///
  /// In en, this message translates to:
  /// **'Fly balls'**
  String get baseballConditioningDetailFlyBall;

  /// No description provided for @baseballConditioningDetailTransfer.
  ///
  /// In en, this message translates to:
  /// **'Quick transfer'**
  String get baseballConditioningDetailTransfer;

  /// No description provided for @baseballConditioningDetailCore.
  ///
  /// In en, this message translates to:
  /// **'Core balance'**
  String get baseballConditioningDetailCore;

  /// No description provided for @basketballConditioningPrimary.
  ///
  /// In en, this message translates to:
  /// **'Shuttle run'**
  String get basketballConditioningPrimary;

  /// No description provided for @basketballConditioningSecondary.
  ///
  /// In en, this message translates to:
  /// **'Ball handling'**
  String get basketballConditioningSecondary;

  /// No description provided for @basketballConditioningDetailTitle.
  ///
  /// In en, this message translates to:
  /// **'Ball handling details'**
  String get basketballConditioningDetailTitle;

  /// No description provided for @basketballConditioningDetailRightHand.
  ///
  /// In en, this message translates to:
  /// **'Right hand'**
  String get basketballConditioningDetailRightHand;

  /// No description provided for @basketballConditioningDetailLeftHand.
  ///
  /// In en, this message translates to:
  /// **'Left hand'**
  String get basketballConditioningDetailLeftHand;

  /// No description provided for @basketballConditioningDetailCrossover.
  ///
  /// In en, this message translates to:
  /// **'Crossover'**
  String get basketballConditioningDetailCrossover;

  /// No description provided for @basketballConditioningDetailChangePace.
  ///
  /// In en, this message translates to:
  /// **'Change of pace'**
  String get basketballConditioningDetailChangePace;

  /// No description provided for @basketballConditioningDetailShootingPocket.
  ///
  /// In en, this message translates to:
  /// **'Shooting pocket'**
  String get basketballConditioningDetailShootingPocket;

  /// No description provided for @basketballConditioningDetailPressure.
  ///
  /// In en, this message translates to:
  /// **'Under pressure'**
  String get basketballConditioningDetailPressure;

  /// No description provided for @tennisConditioningPrimary.
  ///
  /// In en, this message translates to:
  /// **'Footwork'**
  String get tennisConditioningPrimary;

  /// No description provided for @tennisConditioningSecondary.
  ///
  /// In en, this message translates to:
  /// **'Wall rally'**
  String get tennisConditioningSecondary;

  /// No description provided for @tennisConditioningDetailTitle.
  ///
  /// In en, this message translates to:
  /// **'Wall rally details'**
  String get tennisConditioningDetailTitle;

  /// No description provided for @tennisConditioningDetailForehand.
  ///
  /// In en, this message translates to:
  /// **'Forehand'**
  String get tennisConditioningDetailForehand;

  /// No description provided for @tennisConditioningDetailBackhand.
  ///
  /// In en, this message translates to:
  /// **'Backhand'**
  String get tennisConditioningDetailBackhand;

  /// No description provided for @tennisConditioningDetailServeToss.
  ///
  /// In en, this message translates to:
  /// **'Serve toss'**
  String get tennisConditioningDetailServeToss;

  /// No description provided for @tennisConditioningDetailVolley.
  ///
  /// In en, this message translates to:
  /// **'Volley'**
  String get tennisConditioningDetailVolley;

  /// No description provided for @tennisConditioningDetailApproach.
  ///
  /// In en, this message translates to:
  /// **'Approach'**
  String get tennisConditioningDetailApproach;

  /// No description provided for @tennisConditioningDetailRecovery.
  ///
  /// In en, this message translates to:
  /// **'Recovery step'**
  String get tennisConditioningDetailRecovery;

  /// No description provided for @sportConditioningRecordTitle.
  ///
  /// In en, this message translates to:
  /// **'{label} Record'**
  String sportConditioningRecordTitle(String label);

  /// No description provided for @sportConditioningMinutesLabel.
  ///
  /// In en, this message translates to:
  /// **'{label} time (min)'**
  String sportConditioningMinutesLabel(String label);

  /// No description provided for @sportConditioningCountLabel.
  ///
  /// In en, this message translates to:
  /// **'{label} count'**
  String sportConditioningCountLabel(String label);

  /// No description provided for @sportConditioningMemoLabel.
  ///
  /// In en, this message translates to:
  /// **'{label} memo'**
  String sportConditioningMemoLabel(String label);

  /// No description provided for @sportConditioningMemoHint.
  ///
  /// In en, this message translates to:
  /// **'Write what you felt during {label}.'**
  String sportConditioningMemoHint(String label);

  /// No description provided for @sportConditioningEmpty.
  ///
  /// In en, this message translates to:
  /// **'No {primary}/{secondary} record'**
  String sportConditioningEmpty(String primary, String secondary);

  /// No description provided for @defaultDrill1.
  ///
  /// In en, this message translates to:
  /// **'Rondo 5:2'**
  String get defaultDrill1;

  /// No description provided for @defaultDrill2.
  ///
  /// In en, this message translates to:
  /// **'1v1 defense'**
  String get defaultDrill2;

  /// No description provided for @defaultDrill3.
  ///
  /// In en, this message translates to:
  /// **'Shooting reps'**
  String get defaultDrill3;

  /// No description provided for @defaultDrill4.
  ///
  /// In en, this message translates to:
  /// **'Sprints'**
  String get defaultDrill4;

  /// No description provided for @defaultInjury1.
  ///
  /// In en, this message translates to:
  /// **'Hamstring'**
  String get defaultInjury1;

  /// No description provided for @defaultInjury2.
  ///
  /// In en, this message translates to:
  /// **'Knee'**
  String get defaultInjury2;

  /// No description provided for @defaultInjury3.
  ///
  /// In en, this message translates to:
  /// **'Ankle'**
  String get defaultInjury3;

  /// No description provided for @defaultInjury4.
  ///
  /// In en, this message translates to:
  /// **'Thigh'**
  String get defaultInjury4;

  /// No description provided for @defaultInjury5.
  ///
  /// In en, this message translates to:
  /// **'Calf'**
  String get defaultInjury5;

  /// No description provided for @languageEnglish.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get languageEnglish;

  /// No description provided for @languageKorean.
  ///
  /// In en, this message translates to:
  /// **'Korean'**
  String get languageKorean;

  /// No description provided for @languageJapanese.
  ///
  /// In en, this message translates to:
  /// **'Japanese'**
  String get languageJapanese;

  /// No description provided for @languageSystemDefault.
  ///
  /// In en, this message translates to:
  /// **'System default'**
  String get languageSystemDefault;

  /// No description provided for @settings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settings;

  /// No description provided for @settingsGeneralSection.
  ///
  /// In en, this message translates to:
  /// **'General'**
  String get settingsGeneralSection;

  /// No description provided for @settingsNewsFilterTitle.
  ///
  /// In en, this message translates to:
  /// **'News Filter'**
  String get settingsNewsFilterTitle;

  /// No description provided for @settingsNewsBlockedDomainsTitle.
  ///
  /// In en, this message translates to:
  /// **'Blocked ad domains'**
  String get settingsNewsBlockedDomainsTitle;

  /// No description provided for @settingsNewsBlockedDomainsCount.
  ///
  /// In en, this message translates to:
  /// **'{count} items'**
  String settingsNewsBlockedDomainsCount(int count);

  /// No description provided for @settingsNewsBlockedDomainsManageTitle.
  ///
  /// In en, this message translates to:
  /// **'Manage blocked ad domains'**
  String get settingsNewsBlockedDomainsManageTitle;

  /// No description provided for @settingsNewsBlockedDomainsExample.
  ///
  /// In en, this message translates to:
  /// **'Example: example.com (domain only, no path)'**
  String get settingsNewsBlockedDomainsExample;

  /// No description provided for @settingsJournalOptionManagerTitle.
  ///
  /// In en, this message translates to:
  /// **'Journal option manager'**
  String get settingsJournalOptionManagerTitle;

  /// No description provided for @settingsOptionItemsCount.
  ///
  /// In en, this message translates to:
  /// **'{count} items'**
  String settingsOptionItemsCount(int count);

  /// No description provided for @settingsDurationOptionsTitle.
  ///
  /// In en, this message translates to:
  /// **'Duration options'**
  String get settingsDurationOptionsTitle;

  /// No description provided for @settingsDurationOptionsManageTitle.
  ///
  /// In en, this message translates to:
  /// **'Manage duration options'**
  String get settingsDurationOptionsManageTitle;

  /// No description provided for @settingsProgramOptionsTitle.
  ///
  /// In en, this message translates to:
  /// **'Program options'**
  String get settingsProgramOptionsTitle;

  /// No description provided for @settingsProgramOptionsManageTitle.
  ///
  /// In en, this message translates to:
  /// **'Manage program options'**
  String get settingsProgramOptionsManageTitle;

  /// No description provided for @settingsTrainingGoalOptionsTitle.
  ///
  /// In en, this message translates to:
  /// **'Training goal options'**
  String get settingsTrainingGoalOptionsTitle;

  /// No description provided for @settingsTrainingGoalOptionsManageTitle.
  ///
  /// In en, this message translates to:
  /// **'Manage training goal options'**
  String get settingsTrainingGoalOptionsManageTitle;

  /// No description provided for @settingsInjuryPartOptionsTitle.
  ///
  /// In en, this message translates to:
  /// **'Injury part options'**
  String get settingsInjuryPartOptionsTitle;

  /// No description provided for @settingsInjuryPartOptionsManageTitle.
  ///
  /// In en, this message translates to:
  /// **'Manage injury part options'**
  String get settingsInjuryPartOptionsManageTitle;

  /// No description provided for @settingsOptionEditTitle.
  ///
  /// In en, this message translates to:
  /// **'Edit option'**
  String get settingsOptionEditTitle;

  /// No description provided for @settingsOptionAddTitle.
  ///
  /// In en, this message translates to:
  /// **'Add option'**
  String get settingsOptionAddTitle;

  /// No description provided for @settingsIntOptionEditTitle.
  ///
  /// In en, this message translates to:
  /// **'Edit minutes'**
  String get settingsIntOptionEditTitle;

  /// No description provided for @settingsIntOptionAddTitle.
  ///
  /// In en, this message translates to:
  /// **'Add minutes'**
  String get settingsIntOptionAddTitle;

  /// No description provided for @settingsApiUsageTitle.
  ///
  /// In en, this message translates to:
  /// **'APIs used in this app'**
  String get settingsApiUsageTitle;

  /// No description provided for @settingsApiUsageSubtitle.
  ///
  /// In en, this message translates to:
  /// **'This app uses the following public or consent-based APIs. Quotas can change by provider, so the app caches where possible and limits background refreshes.'**
  String get settingsApiUsageSubtitle;

  /// No description provided for @settingsApiTrafficLabel.
  ///
  /// In en, this message translates to:
  /// **'Traffic'**
  String get settingsApiTrafficLabel;

  /// No description provided for @settingsApiLegalLabel.
  ///
  /// In en, this message translates to:
  /// **'Legal use'**
  String get settingsApiLegalLabel;

  /// No description provided for @settingsApiOpenMeteoProvider.
  ///
  /// In en, this message translates to:
  /// **'Open-Meteo weather, air quality, geocoding, and archive APIs'**
  String get settingsApiOpenMeteoProvider;

  /// No description provided for @settingsApiOpenMeteoTraffic.
  ///
  /// In en, this message translates to:
  /// **'Free public service with fair-use expectations; requests are cached for weather views and refreshed only when needed.'**
  String get settingsApiOpenMeteoTraffic;

  /// No description provided for @settingsApiOpenMeteoLegal.
  ///
  /// In en, this message translates to:
  /// **'Used under Open-Meteo public API terms with attribution/source surfaces in weather features.'**
  String get settingsApiOpenMeteoLegal;

  /// No description provided for @settingsApiKoreaPublicProvider.
  ///
  /// In en, this message translates to:
  /// **'Korea public data APIs for weather and air quality'**
  String get settingsApiKoreaPublicProvider;

  /// No description provided for @settingsApiKoreaPublicTraffic.
  ///
  /// In en, this message translates to:
  /// **'Quota depends on the issued public-data service key and agency limits.'**
  String get settingsApiKoreaPublicTraffic;

  /// No description provided for @settingsApiKoreaPublicLegal.
  ///
  /// In en, this message translates to:
  /// **'Used with an issued service key under the Korean public data portal terms.'**
  String get settingsApiKoreaPublicLegal;

  /// No description provided for @settingsApiKakaoProvider.
  ///
  /// In en, this message translates to:
  /// **'Kakao Local search/geocoding API'**
  String get settingsApiKakaoProvider;

  /// No description provided for @settingsApiKakaoTraffic.
  ///
  /// In en, this message translates to:
  /// **'Quota depends on the registered Kakao Developers app and REST API key.'**
  String get settingsApiKakaoTraffic;

  /// No description provided for @settingsApiKakaoLegal.
  ///
  /// In en, this message translates to:
  /// **'Used only when the app key/platform configuration permits it under Kakao Developers terms.'**
  String get settingsApiKakaoLegal;

  /// No description provided for @settingsApiFootballProvider.
  ///
  /// In en, this message translates to:
  /// **'Football schedule, standings, and World Cup source pages/APIs'**
  String get settingsApiFootballProvider;

  /// No description provided for @settingsApiFootballTraffic.
  ///
  /// In en, this message translates to:
  /// **'Read-only fetches are cached and retried conservatively; availability depends on the source service.'**
  String get settingsApiFootballTraffic;

  /// No description provided for @settingsApiFootballLegal.
  ///
  /// In en, this message translates to:
  /// **'Uses public fixture/standings data for in-app display and links/source labels where provided.'**
  String get settingsApiFootballLegal;

  /// No description provided for @settingsApiNewsProvider.
  ///
  /// In en, this message translates to:
  /// **'RSS feeds and news fetch helpers'**
  String get settingsApiNewsProvider;

  /// No description provided for @settingsApiNewsTraffic.
  ///
  /// In en, this message translates to:
  /// **'RSS/news responses are cached and filtered to reduce repeated traffic.'**
  String get settingsApiNewsTraffic;

  /// No description provided for @settingsApiNewsLegal.
  ///
  /// In en, this message translates to:
  /// **'Shows article metadata and opens the original publisher page instead of republishing full articles.'**
  String get settingsApiNewsLegal;

  /// No description provided for @settingsApiGoogleProvider.
  ///
  /// In en, this message translates to:
  /// **'Google Drive and Firebase services'**
  String get settingsApiGoogleProvider;

  /// No description provided for @settingsApiGoogleTraffic.
  ///
  /// In en, this message translates to:
  /// **'Traffic follows the connected Google Cloud project and user Drive quota.'**
  String get settingsApiGoogleTraffic;

  /// No description provided for @settingsApiGoogleLegal.
  ///
  /// In en, this message translates to:
  /// **'Drive access uses user consent and app backup scopes for the user\'s own files.'**
  String get settingsApiGoogleLegal;

  /// No description provided for @account.
  ///
  /// In en, this message translates to:
  /// **'Account'**
  String get account;

  /// No description provided for @signInWithGoogle.
  ///
  /// In en, this message translates to:
  /// **'Sign in with Google'**
  String get signInWithGoogle;

  /// No description provided for @signInFailed.
  ///
  /// In en, this message translates to:
  /// **'Sign-in failed. Please try again.'**
  String get signInFailed;

  /// No description provided for @signedIn.
  ///
  /// In en, this message translates to:
  /// **'Signed in'**
  String get signedIn;

  /// No description provided for @signOut.
  ///
  /// In en, this message translates to:
  /// **'Sign out'**
  String get signOut;

  /// No description provided for @webLoginNotAvailable.
  ///
  /// In en, this message translates to:
  /// **'Google login is not available on web.'**
  String get webLoginNotAvailable;

  /// No description provided for @backupToDrive.
  ///
  /// In en, this message translates to:
  /// **'Back up data'**
  String get backupToDrive;

  /// No description provided for @restoreFromDrive.
  ///
  /// In en, this message translates to:
  /// **'Import latest data'**
  String get restoreFromDrive;

  /// No description provided for @restorePreviousBackup.
  ///
  /// In en, this message translates to:
  /// **'Import previous backup'**
  String get restorePreviousBackup;

  /// No description provided for @restorePreviousBackupInfo.
  ///
  /// In en, this message translates to:
  /// **'Previous backup import is a recovery tool for undoing a recent import or checking an older state. Confirm that current data will be replaced by the previous backup before running it.'**
  String get restorePreviousBackupInfo;

  /// No description provided for @backupConfirm.
  ///
  /// In en, this message translates to:
  /// **'Create a new backup on Google Drive?'**
  String get backupConfirm;

  /// No description provided for @restoreConfirm.
  ///
  /// In en, this message translates to:
  /// **'Import the latest data from Google Drive? This will replace current data.'**
  String get restoreConfirm;

  /// No description provided for @restorePreviousConfirm.
  ///
  /// In en, this message translates to:
  /// **'Import the previous Google Drive backup? Current data will be replaced.'**
  String get restorePreviousConfirm;

  /// No description provided for @backupSuccess.
  ///
  /// In en, this message translates to:
  /// **'Backup completed.'**
  String get backupSuccess;

  /// No description provided for @backupFailed.
  ///
  /// In en, this message translates to:
  /// **'Backup failed. Please try again.'**
  String get backupFailed;

  /// No description provided for @restoreSuccess.
  ///
  /// In en, this message translates to:
  /// **'Data imported.'**
  String get restoreSuccess;

  /// No description provided for @restoreFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to import data. Please try again.'**
  String get restoreFailed;

  /// No description provided for @restorePreviousSuccess.
  ///
  /// In en, this message translates to:
  /// **'Previous backup imported.'**
  String get restorePreviousSuccess;

  /// No description provided for @restorePreviousFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to import the previous backup. Please try again.'**
  String get restorePreviousFailed;

  /// No description provided for @backupInProgress.
  ///
  /// In en, this message translates to:
  /// **'Backing up...'**
  String get backupInProgress;

  /// No description provided for @restoreInProgress.
  ///
  /// In en, this message translates to:
  /// **'Importing data...'**
  String get restoreInProgress;

  /// No description provided for @backupDailyEnabled.
  ///
  /// In en, this message translates to:
  /// **'Daily backup enabled'**
  String get backupDailyEnabled;

  /// No description provided for @backupDailyDesc.
  ///
  /// In en, this message translates to:
  /// **'Backs up once per day when the app opens'**
  String get backupDailyDesc;

  /// No description provided for @backupAutoOnSave.
  ///
  /// In en, this message translates to:
  /// **'Auto backup on save'**
  String get backupAutoOnSave;

  /// No description provided for @backupAutoOnSaveDesc.
  ///
  /// In en, this message translates to:
  /// **'Backs up whenever you add or update a log'**
  String get backupAutoOnSaveDesc;

  /// No description provided for @lastBackup.
  ///
  /// In en, this message translates to:
  /// **'Last backup'**
  String get lastBackup;

  /// No description provided for @timeJustNow.
  ///
  /// In en, this message translates to:
  /// **'Just now'**
  String get timeJustNow;

  /// No description provided for @timeMinutesAgo.
  ///
  /// In en, this message translates to:
  /// **'{count} min ago'**
  String timeMinutesAgo(int count);

  /// No description provided for @timeHoursAgo.
  ///
  /// In en, this message translates to:
  /// **'{count} hr ago'**
  String timeHoursAgo(int count);

  /// No description provided for @timeYesterday.
  ///
  /// In en, this message translates to:
  /// **'Yesterday'**
  String get timeYesterday;

  /// No description provided for @restoreLocalBackup.
  ///
  /// In en, this message translates to:
  /// **'Undo latest import'**
  String get restoreLocalBackup;

  /// No description provided for @restoreLocalConfirm.
  ///
  /// In en, this message translates to:
  /// **'Undo the changes made by the latest import on this device? This will replace current data.'**
  String get restoreLocalConfirm;

  /// No description provided for @restoreLocalSuccess.
  ///
  /// In en, this message translates to:
  /// **'The latest import was undone.'**
  String get restoreLocalSuccess;

  /// No description provided for @restoreLocalFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to undo the latest import. Please try again.'**
  String get restoreLocalFailed;

  /// No description provided for @localBackup.
  ///
  /// In en, this message translates to:
  /// **'Local safety backup'**
  String get localBackup;

  /// No description provided for @driveBackupLockedAccountChanged.
  ///
  /// In en, this message translates to:
  /// **'The Google account changed. Choose how this device should use the connected account before any backup can run.'**
  String get driveBackupLockedAccountChanged;

  /// No description provided for @driveAccountSwitchImportAction.
  ///
  /// In en, this message translates to:
  /// **'Import this account\'s backup'**
  String get driveAccountSwitchImportAction;

  /// No description provided for @driveAccountSwitchStartEmptyAction.
  ///
  /// In en, this message translates to:
  /// **'Start empty with this account'**
  String get driveAccountSwitchStartEmptyAction;

  /// No description provided for @driveAccountSwitchImportTitle.
  ///
  /// In en, this message translates to:
  /// **'Use connected account data?'**
  String get driveAccountSwitchImportTitle;

  /// No description provided for @driveAccountSwitchImportBody.
  ///
  /// In en, this message translates to:
  /// **'The connected Google account is different from the saved player backup account. Import this account\'s latest Drive backup first; current device data will be replaced after a local safety copy is kept.'**
  String get driveAccountSwitchImportBody;

  /// No description provided for @driveAccountSwitchStartEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'Start as a new player account?'**
  String get driveAccountSwitchStartEmptyTitle;

  /// No description provided for @driveAccountSwitchStartEmptyBody.
  ///
  /// In en, this message translates to:
  /// **'This will clear player data on this device and connect the current Google account as the player backup account. A local safety copy is kept so you can undo the import from this device.'**
  String get driveAccountSwitchStartEmptyBody;

  /// No description provided for @driveAccountSwitchImportSuccess.
  ///
  /// In en, this message translates to:
  /// **'This account\'s backup was imported.'**
  String get driveAccountSwitchImportSuccess;

  /// No description provided for @driveAccountSwitchStartEmptySuccess.
  ///
  /// In en, this message translates to:
  /// **'Started with an empty player dataset for this account.'**
  String get driveAccountSwitchStartEmptySuccess;

  /// No description provided for @driveAccountSwitchImportFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not import this account\'s backup. Please try again.'**
  String get driveAccountSwitchImportFailed;

  /// No description provided for @driveAccountSwitchStartEmptyFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not start with this account. Please try again.'**
  String get driveAccountSwitchStartEmptyFailed;

  /// No description provided for @driveAccountSwitchNoRemoteBackup.
  ///
  /// In en, this message translates to:
  /// **'No Drive backup was found for the connected account. Start empty with this account or reconnect the saved player account.'**
  String get driveAccountSwitchNoRemoteBackup;

  /// No description provided for @backupVersionUnsupported.
  ///
  /// In en, this message translates to:
  /// **'This backup was created by a newer app version and cannot be imported here yet. Update the app and try again.'**
  String get backupVersionUnsupported;

  /// No description provided for @backupPayloadInvalid.
  ///
  /// In en, this message translates to:
  /// **'The backup data format could not be verified, so the import was stopped. Try a different backup.'**
  String get backupPayloadInvalid;

  /// No description provided for @loginRequired.
  ///
  /// In en, this message translates to:
  /// **'Please sign in to Google to use Drive backup.'**
  String get loginRequired;

  /// No description provided for @signOutDone.
  ///
  /// In en, this message translates to:
  /// **'Signed out.'**
  String get signOutDone;

  /// No description provided for @voiceNotAvailable.
  ///
  /// In en, this message translates to:
  /// **'Voice input is not available on this device.'**
  String get voiceNotAvailable;

  /// No description provided for @voiceInputStartTooltip.
  ///
  /// In en, this message translates to:
  /// **'Voice input'**
  String get voiceInputStartTooltip;

  /// No description provided for @voiceInputStopTooltip.
  ///
  /// In en, this message translates to:
  /// **'Stop voice input'**
  String get voiceInputStopTooltip;

  /// No description provided for @voiceListeningStatus.
  ///
  /// In en, this message translates to:
  /// **'Voice input active'**
  String get voiceListeningStatus;

  /// No description provided for @liftingRecord.
  ///
  /// In en, this message translates to:
  /// **'Lifting Record'**
  String get liftingRecord;

  /// No description provided for @liftingByPart.
  ///
  /// In en, this message translates to:
  /// **'Lifting (reps by part)'**
  String get liftingByPart;

  /// No description provided for @liftingMinutesLabel.
  ///
  /// In en, this message translates to:
  /// **'Lifting time (min)'**
  String get liftingMinutesLabel;

  /// No description provided for @liftingPartInfront.
  ///
  /// In en, this message translates to:
  /// **'Infront'**
  String get liftingPartInfront;

  /// No description provided for @liftingPartInside.
  ///
  /// In en, this message translates to:
  /// **'Inside'**
  String get liftingPartInside;

  /// No description provided for @liftingPartOutside.
  ///
  /// In en, this message translates to:
  /// **'Outside'**
  String get liftingPartOutside;

  /// No description provided for @liftingPartMuple.
  ///
  /// In en, this message translates to:
  /// **'Knee'**
  String get liftingPartMuple;

  /// No description provided for @liftingPartHead.
  ///
  /// In en, this message translates to:
  /// **'Head'**
  String get liftingPartHead;

  /// No description provided for @liftingPartChest.
  ///
  /// In en, this message translates to:
  /// **'Chest'**
  String get liftingPartChest;

  /// No description provided for @liftingByBodyPartTitle.
  ///
  /// In en, this message translates to:
  /// **'Lifting by Body Part'**
  String get liftingByBodyPartTitle;

  /// No description provided for @liftingNoRecords.
  ///
  /// In en, this message translates to:
  /// **'No lifting records.'**
  String get liftingNoRecords;

  /// No description provided for @legacyLabel.
  ///
  /// In en, this message translates to:
  /// **'Legacy'**
  String get legacyLabel;

  /// No description provided for @oldLabel.
  ///
  /// In en, this message translates to:
  /// **'Old'**
  String get oldLabel;

  /// No description provided for @confirm.
  ///
  /// In en, this message translates to:
  /// **'Confirm'**
  String get confirm;

  /// No description provided for @language.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;

  /// No description provided for @theme.
  ///
  /// In en, this message translates to:
  /// **'Theme'**
  String get theme;

  /// No description provided for @themeSystem.
  ///
  /// In en, this message translates to:
  /// **'System'**
  String get themeSystem;

  /// No description provided for @themeLight.
  ///
  /// In en, this message translates to:
  /// **'Light'**
  String get themeLight;

  /// No description provided for @themeDark.
  ///
  /// In en, this message translates to:
  /// **'Dark'**
  String get themeDark;

  /// No description provided for @defaults.
  ///
  /// In en, this message translates to:
  /// **'Defaults'**
  String get defaults;

  /// No description provided for @defaultDuration.
  ///
  /// In en, this message translates to:
  /// **'Default Duration'**
  String get defaultDuration;

  /// No description provided for @defaultIntensity.
  ///
  /// In en, this message translates to:
  /// **'Default Intensity'**
  String get defaultIntensity;

  /// No description provided for @defaultCondition.
  ///
  /// In en, this message translates to:
  /// **'Default Condition'**
  String get defaultCondition;

  /// No description provided for @defaultLocation.
  ///
  /// In en, this message translates to:
  /// **'Default Location'**
  String get defaultLocation;

  /// No description provided for @defaultProgram.
  ///
  /// In en, this message translates to:
  /// **'Default Program'**
  String get defaultProgram;

  /// No description provided for @notifications.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get notifications;

  /// No description provided for @notificationSettingsAction.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get notificationSettingsAction;

  /// No description provided for @notificationSettingsTitle.
  ///
  /// In en, this message translates to:
  /// **'Alert settings'**
  String get notificationSettingsTitle;

  /// No description provided for @notificationSettingsCloseTooltip.
  ///
  /// In en, this message translates to:
  /// **'Close alert settings'**
  String get notificationSettingsCloseTooltip;

  /// No description provided for @notificationRefreshAction.
  ///
  /// In en, this message translates to:
  /// **'Refresh'**
  String get notificationRefreshAction;

  /// No description provided for @notificationMuteStatusPaused.
  ///
  /// In en, this message translates to:
  /// **'Alerts are currently paused.'**
  String get notificationMuteStatusPaused;

  /// No description provided for @notificationMuteControlTitle.
  ///
  /// In en, this message translates to:
  /// **'Repeating alert control'**
  String get notificationMuteControlTitle;

  /// No description provided for @notificationMuteControlSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Temporarily mute alerts or resume anytime.'**
  String get notificationMuteControlSubtitle;

  /// No description provided for @notificationMute8HoursAction.
  ///
  /// In en, this message translates to:
  /// **'Mute 8h'**
  String get notificationMute8HoursAction;

  /// No description provided for @notificationResumeAction.
  ///
  /// In en, this message translates to:
  /// **'Resume'**
  String get notificationResumeAction;

  /// No description provided for @notificationAllSettingsTitle.
  ///
  /// In en, this message translates to:
  /// **'All notifications'**
  String get notificationAllSettingsTitle;

  /// No description provided for @notificationTrainingPlanVibrationTitle.
  ///
  /// In en, this message translates to:
  /// **'Training plan vibration'**
  String get notificationTrainingPlanVibrationTitle;

  /// No description provided for @notificationXpAlertSettingsTitle.
  ///
  /// In en, this message translates to:
  /// **'XP alerts'**
  String get notificationXpAlertSettingsTitle;

  /// No description provided for @notificationXpAlertSettingsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Show an alert whenever XP is earned.'**
  String get notificationXpAlertSettingsSubtitle;

  /// No description provided for @notificationLevelUpSettingsTitle.
  ///
  /// In en, this message translates to:
  /// **'Level-up notifications'**
  String get notificationLevelUpSettingsTitle;

  /// No description provided for @notificationFamilySectionTitle.
  ///
  /// In en, this message translates to:
  /// **'{count} parent sync alert(s)'**
  String notificationFamilySectionTitle(int count);

  /// No description provided for @notificationFamilyEmpty.
  ///
  /// In en, this message translates to:
  /// **'No parent sync alerts yet.'**
  String get notificationFamilyEmpty;

  /// No description provided for @notificationFixtureSectionTitle.
  ///
  /// In en, this message translates to:
  /// **'{count} fixture alert(s)'**
  String notificationFixtureSectionTitle(int count);

  /// No description provided for @notificationFixtureEmpty.
  ///
  /// In en, this message translates to:
  /// **'No fixture alerts yet.'**
  String get notificationFixtureEmpty;

  /// No description provided for @notificationFamilySettingsTitle.
  ///
  /// In en, this message translates to:
  /// **'Parent sync alerts'**
  String get notificationFamilySettingsTitle;

  /// No description provided for @notificationFamilySettingsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Notify when player logs or guardian feedback/rewards sync.'**
  String get notificationFamilySettingsSubtitle;

  /// No description provided for @notificationLeagueFixtureSettingsTitle.
  ///
  /// In en, this message translates to:
  /// **'Favorite team match alerts'**
  String get notificationLeagueFixtureSettingsTitle;

  /// No description provided for @notificationLeagueFixtureSettingsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Notify before loaded fixtures for selected favorite teams.'**
  String get notificationLeagueFixtureSettingsSubtitle;

  /// No description provided for @notificationOverviewOnTitle.
  ///
  /// In en, this message translates to:
  /// **'Phone notifications are on'**
  String get notificationOverviewOnTitle;

  /// No description provided for @notificationOverviewOffTitle.
  ///
  /// In en, this message translates to:
  /// **'Phone notifications are off'**
  String get notificationOverviewOffTitle;

  /// No description provided for @notificationOverviewAllOnSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Device notifications and in-app alerts are both enabled.'**
  String get notificationOverviewAllOnSubtitle;

  /// No description provided for @notificationOverviewAppOffSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Device notifications are on, but all in-app alerts are off.'**
  String get notificationOverviewAppOffSubtitle;

  /// No description provided for @notificationOverviewPermissionOffSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Allow notifications for this app in Settings > Notifications to receive alerts.'**
  String get notificationOverviewPermissionOffSubtitle;

  /// No description provided for @notificationOverviewPausedLabel.
  ///
  /// In en, this message translates to:
  /// **'Paused'**
  String get notificationOverviewPausedLabel;

  /// No description provided for @notificationOverviewCountLabel.
  ///
  /// In en, this message translates to:
  /// **'{count} alerts'**
  String notificationOverviewCountLabel(int count);

  /// No description provided for @notificationFeedTitle.
  ///
  /// In en, this message translates to:
  /// **'Alert feed'**
  String get notificationFeedTitle;

  /// No description provided for @notificationFeedSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Alerts shown: {count}'**
  String notificationFeedSubtitle(int count);

  /// No description provided for @notificationCategoryTrainingPlan.
  ///
  /// In en, this message translates to:
  /// **'Training'**
  String get notificationCategoryTrainingPlan;

  /// No description provided for @notificationCategoryWeather.
  ///
  /// In en, this message translates to:
  /// **'Weather'**
  String get notificationCategoryWeather;

  /// No description provided for @notificationCategoryClubTraining.
  ///
  /// In en, this message translates to:
  /// **'Club training'**
  String get notificationCategoryClubTraining;

  /// No description provided for @notificationCategoryFixture.
  ///
  /// In en, this message translates to:
  /// **'Matches'**
  String get notificationCategoryFixture;

  /// No description provided for @notificationCategoryXp.
  ///
  /// In en, this message translates to:
  /// **'XP'**
  String get notificationCategoryXp;

  /// No description provided for @notificationCategoryFamily.
  ///
  /// In en, this message translates to:
  /// **'Family'**
  String get notificationCategoryFamily;

  /// No description provided for @notificationCategorySectionTitle.
  ///
  /// In en, this message translates to:
  /// **'{category} ({count})'**
  String notificationCategorySectionTitle(Object category, int count);

  /// No description provided for @notificationFeedEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'No alerts to show.'**
  String get notificationFeedEmptyTitle;

  /// No description provided for @notificationFeedEmptySubtitle.
  ///
  /// In en, this message translates to:
  /// **'Training, weather, and match alerts will appear here.'**
  String get notificationFeedEmptySubtitle;

  /// No description provided for @notificationInactivitySettingsTitle.
  ///
  /// In en, this message translates to:
  /// **'Inactivity reminders'**
  String get notificationInactivitySettingsTitle;

  /// No description provided for @notificationInactivityOnTitle.
  ///
  /// In en, this message translates to:
  /// **'Inactivity reminder is on'**
  String get notificationInactivityOnTitle;

  /// No description provided for @notificationInactivityOffTitle.
  ///
  /// In en, this message translates to:
  /// **'Inactivity reminder is off'**
  String get notificationInactivityOffTitle;

  /// No description provided for @notificationInactivityOnSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Alert at {time} after {days} inactive days'**
  String notificationInactivityOnSubtitle(int days, Object time);

  /// No description provided for @notificationInactivityOffSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Turn it on to get nudges after quiet periods.'**
  String get notificationInactivityOffSubtitle;

  /// No description provided for @notificationLastTrainingLog.
  ///
  /// In en, this message translates to:
  /// **'Last log: {time}'**
  String notificationLastTrainingLog(Object time);

  /// No description provided for @notificationInactivityTimeTitle.
  ///
  /// In en, this message translates to:
  /// **'Training reminder time'**
  String get notificationInactivityTimeTitle;

  /// No description provided for @notificationInactivityTimeSubtitle.
  ///
  /// In en, this message translates to:
  /// **'{days} day threshold · {time}'**
  String notificationInactivityTimeSubtitle(int days, Object time);

  /// No description provided for @notificationInactivityThresholdLabel.
  ///
  /// In en, this message translates to:
  /// **'Inactivity threshold'**
  String get notificationInactivityThresholdLabel;

  /// No description provided for @notificationInactivityThresholdDayOption.
  ///
  /// In en, this message translates to:
  /// **'{value} day(s)'**
  String notificationInactivityThresholdDayOption(int value);

  /// No description provided for @notificationChangeTimeAction.
  ///
  /// In en, this message translates to:
  /// **'Change'**
  String get notificationChangeTimeAction;

  /// No description provided for @notificationXpFallbackTitle.
  ///
  /// In en, this message translates to:
  /// **'XP alert'**
  String get notificationXpFallbackTitle;

  /// No description provided for @notificationXpSubtitle.
  ///
  /// In en, this message translates to:
  /// **'+{gainedXp} XP · total {totalXp} XP'**
  String notificationXpSubtitle(int gainedXp, int totalXp);

  /// No description provided for @notificationPlanFallbackTitle.
  ///
  /// In en, this message translates to:
  /// **'Training plan'**
  String get notificationPlanFallbackTitle;

  /// No description provided for @notificationWeatherSettingsTitle.
  ///
  /// In en, this message translates to:
  /// **'Weather alert'**
  String get notificationWeatherSettingsTitle;

  /// No description provided for @notificationWeatherSettingsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Send a daily reminder to check weather and training outfit.'**
  String get notificationWeatherSettingsSubtitle;

  /// No description provided for @notificationWeatherTimeTitle.
  ///
  /// In en, this message translates to:
  /// **'Weather alert time'**
  String get notificationWeatherTimeTitle;

  /// No description provided for @notificationWeatherTimeSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Every day at {time}'**
  String notificationWeatherTimeSubtitle(Object time);

  /// No description provided for @notificationClubTrainingSettingsTitle.
  ///
  /// In en, this message translates to:
  /// **'Club training alerts'**
  String get notificationClubTrainingSettingsTitle;

  /// No description provided for @notificationClubTrainingSettingsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Send uniform and time alerts {minutes} minutes before training.'**
  String notificationClubTrainingSettingsSubtitle(int minutes);

  /// No description provided for @notificationClubTrainingLeadTimeLabel.
  ///
  /// In en, this message translates to:
  /// **'Club training lead time'**
  String get notificationClubTrainingLeadTimeLabel;

  /// No description provided for @notificationClubTrainingLeadTimeOption.
  ///
  /// In en, this message translates to:
  /// **'{value} min before'**
  String notificationClubTrainingLeadTimeOption(int value);

  /// No description provided for @notificationNewBadge.
  ///
  /// In en, this message translates to:
  /// **'NEW'**
  String get notificationNewBadge;

  /// No description provided for @weatherNotificationChannelName.
  ///
  /// In en, this message translates to:
  /// **'Weather alerts'**
  String get weatherNotificationChannelName;

  /// No description provided for @weatherNotificationChannelDescription.
  ///
  /// In en, this message translates to:
  /// **'Daily weather and training outfit reminders'**
  String get weatherNotificationChannelDescription;

  /// No description provided for @weatherNotificationDailyBody.
  ///
  /// In en, this message translates to:
  /// **'Check today\'s weather and training outfit.'**
  String get weatherNotificationDailyBody;

  /// No description provided for @reminderEnabled.
  ///
  /// In en, this message translates to:
  /// **'Enable daily reminder'**
  String get reminderEnabled;

  /// No description provided for @reminderTime.
  ///
  /// In en, this message translates to:
  /// **'Reminder time'**
  String get reminderTime;

  /// No description provided for @photo.
  ///
  /// In en, this message translates to:
  /// **'Photo'**
  String get photo;

  /// No description provided for @addPhoto.
  ///
  /// In en, this message translates to:
  /// **'Add photo'**
  String get addPhoto;

  /// No description provided for @removePhoto.
  ///
  /// In en, this message translates to:
  /// **'Remove'**
  String get removePhoto;

  /// No description provided for @noImage.
  ///
  /// In en, this message translates to:
  /// **'No image yet'**
  String get noImage;

  /// No description provided for @imageLoadFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to load image'**
  String get imageLoadFailed;

  /// No description provided for @more.
  ///
  /// In en, this message translates to:
  /// **'More'**
  String get more;

  /// No description provided for @camera.
  ///
  /// In en, this message translates to:
  /// **'Camera'**
  String get camera;

  /// No description provided for @gallery.
  ///
  /// In en, this message translates to:
  /// **'Gallery'**
  String get gallery;

  /// No description provided for @crop.
  ///
  /// In en, this message translates to:
  /// **'Crop'**
  String get crop;

  /// No description provided for @photoHint.
  ///
  /// In en, this message translates to:
  /// **'Tap the camera icon next to Save to add photos.'**
  String get photoHint;

  /// No description provided for @reorderPhotos.
  ///
  /// In en, this message translates to:
  /// **'Reorder photos'**
  String get reorderPhotos;

  /// No description provided for @photoIndex.
  ///
  /// In en, this message translates to:
  /// **'Photo {value}'**
  String photoIndex(Object value);

  /// No description provided for @photoLimitReached.
  ///
  /// In en, this message translates to:
  /// **'You can add up to {value} photos.'**
  String photoLimitReached(Object value);

  /// No description provided for @openPhotoViewer.
  ///
  /// In en, this message translates to:
  /// **'View photo'**
  String get openPhotoViewer;

  /// No description provided for @closePhotoViewer.
  ///
  /// In en, this message translates to:
  /// **'Close photo'**
  String get closePhotoViewer;

  /// No description provided for @previousPhoto.
  ///
  /// In en, this message translates to:
  /// **'Previous photo'**
  String get previousPhoto;

  /// No description provided for @nextPhoto.
  ///
  /// In en, this message translates to:
  /// **'Next photo'**
  String get nextPhoto;

  /// No description provided for @photoViewerCounter.
  ///
  /// In en, this message translates to:
  /// **'{current} / {total}'**
  String photoViewerCounter(Object current, Object total);

  /// No description provided for @gameGuideTitle.
  ///
  /// In en, this message translates to:
  /// **'Game Guide'**
  String get gameGuideTitle;

  /// No description provided for @gameGuideQuickTitle.
  ///
  /// In en, this message translates to:
  /// **'Current Game Flow'**
  String get gameGuideQuickTitle;

  /// No description provided for @gameGuideQuickLine1.
  ///
  /// In en, this message translates to:
  /// **'Each run is 20 seconds, and you start with 3 lives. If you fail, you instantly retry while lives remain.'**
  String get gameGuideQuickLine1;

  /// No description provided for @gameGuideQuickLine2.
  ///
  /// In en, this message translates to:
  /// **'Use the pass button to control direction and power, then choose safe, killer, or risky passes.'**
  String get gameGuideQuickLine2;

  /// No description provided for @gameGuideQuickLine3.
  ///
  /// In en, this message translates to:
  /// **'Build combo through consecutive success. At combo 8+, Fever starts for 5 seconds and doubles bonus points.'**
  String get gameGuideQuickLine3;

  /// No description provided for @gameGuideQuickLine4.
  ///
  /// In en, this message translates to:
  /// **'Random events (narrow lanes, wide lanes, tail wind) and missions rotate during a run, so adapt quickly.'**
  String get gameGuideQuickLine4;

  /// No description provided for @gameGuideRiskTitle.
  ///
  /// In en, this message translates to:
  /// **'Decision Strategy'**
  String get gameGuideRiskTitle;

  /// No description provided for @gameGuideRiskLine1.
  ///
  /// In en, this message translates to:
  /// **'Safe pass: highest stability, best for keeping rhythm and clearing missions safely.'**
  String get gameGuideRiskLine1;

  /// No description provided for @gameGuideRiskLine2.
  ///
  /// In en, this message translates to:
  /// **'Killer pass: medium risk with strong rewards for fast score growth.'**
  String get gameGuideRiskLine2;

  /// No description provided for @gameGuideRiskLine3.
  ///
  /// In en, this message translates to:
  /// **'Risky pass: hardest option but gives the largest reward when completed.'**
  String get gameGuideRiskLine3;

  /// No description provided for @gameGuideRiskLine4.
  ///
  /// In en, this message translates to:
  /// **'Passing into open space grants extra bonus, so read defender spacing before release.'**
  String get gameGuideRiskLine4;

  /// No description provided for @gameGuideFailureTitle.
  ///
  /// In en, this message translates to:
  /// **'Recover From Mistakes'**
  String get gameGuideFailureTitle;

  /// No description provided for @gameGuideFailureLine1.
  ///
  /// In en, this message translates to:
  /// **'Interception, collision, and miss no longer end the run immediately if you still have lives.'**
  String get gameGuideFailureLine1;

  /// No description provided for @gameGuideFailureLine2.
  ///
  /// In en, this message translates to:
  /// **'Use too-fast/too-slow feedback to adjust hold timing on the very next attempt.'**
  String get gameGuideFailureLine2;

  /// No description provided for @gameGuideFailureLine3.
  ///
  /// In en, this message translates to:
  /// **'If no-pass-3s appears, reset tempo first with a short safe pass.'**
  String get gameGuideFailureLine3;

  /// No description provided for @gameGuideFailureLine4.
  ///
  /// In en, this message translates to:
  /// **'When lives are low, switch to safer choices to protect your run.'**
  String get gameGuideFailureLine4;

  /// No description provided for @gameGuideRankingTitle.
  ///
  /// In en, this message translates to:
  /// **'Score Formula'**
  String get gameGuideRankingTitle;

  /// No description provided for @gameGuideRankingLine1.
  ///
  /// In en, this message translates to:
  /// **'Rank score = (completed passes x 10) + (level x 15) + (goals x 60) + bonus score.'**
  String get gameGuideRankingLine1;

  /// No description provided for @gameGuideRankingLine2.
  ///
  /// In en, this message translates to:
  /// **'Bonus score sources: pass-type rewards, open-space rewards, rhythm rewards, mission rewards.'**
  String get gameGuideRankingLine2;

  /// No description provided for @gameGuideRankingLine3.
  ///
  /// In en, this message translates to:
  /// **'During Fever, bonus score is doubled, enabling big jumps in a short window.'**
  String get gameGuideRankingLine3;

  /// No description provided for @gameGuideRankingLine4.
  ///
  /// In en, this message translates to:
  /// **'High-score route: build rhythm with safe passes, expand with killer/risky passes, then finish with mission and goal rewards.'**
  String get gameGuideRankingLine4;

  /// No description provided for @gameRankingTitle.
  ///
  /// In en, this message translates to:
  /// **'Game Rankings'**
  String get gameRankingTitle;

  /// No description provided for @gameRankingEmpty.
  ///
  /// In en, this message translates to:
  /// **'No ranking records yet.'**
  String get gameRankingEmpty;

  /// No description provided for @gameRankingEntryTitle.
  ///
  /// In en, this message translates to:
  /// **'Rank {rankLabel} ({rankScore} pts) - Score {score}'**
  String gameRankingEntryTitle(String rankLabel, int rankScore, int score);

  /// No description provided for @gameRankingEntrySubtitle.
  ///
  /// In en, this message translates to:
  /// **'Level Lv.{level} - Goals {goals} - {date}'**
  String gameRankingEntrySubtitle(int level, int goals, String date);

  /// No description provided for @gameRankingPosition.
  ///
  /// In en, this message translates to:
  /// **'#{rankNo}'**
  String gameRankingPosition(int rankNo);

  /// No description provided for @gameGuideCharPacTitle.
  ///
  /// In en, this message translates to:
  /// **'Pacman Attacker'**
  String get gameGuideCharPacTitle;

  /// No description provided for @gameGuideCharPacSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Starts and links passes'**
  String get gameGuideCharPacSubtitle;

  /// No description provided for @gameGuideCharPacTag.
  ///
  /// In en, this message translates to:
  /// **'ATTACK'**
  String get gameGuideCharPacTag;

  /// No description provided for @gameGuideCharBlueTitle.
  ///
  /// In en, this message translates to:
  /// **'Blue Ghost - BLOCK'**
  String get gameGuideCharBlueTitle;

  /// No description provided for @gameGuideCharBlueSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Blocks passing lanes'**
  String get gameGuideCharBlueSubtitle;

  /// No description provided for @gameGuideCharBlueTag.
  ///
  /// In en, this message translates to:
  /// **'BLOCK'**
  String get gameGuideCharBlueTag;

  /// No description provided for @gameGuideCharOrangeTitle.
  ///
  /// In en, this message translates to:
  /// **'Orange Ghost - PRESS'**
  String get gameGuideCharOrangeTitle;

  /// No description provided for @gameGuideCharOrangeSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Pressure near ball'**
  String get gameGuideCharOrangeSubtitle;

  /// No description provided for @gameGuideCharOrangeTag.
  ///
  /// In en, this message translates to:
  /// **'PRESS'**
  String get gameGuideCharOrangeTag;

  /// No description provided for @gameGuideCharRedTitle.
  ///
  /// In en, this message translates to:
  /// **'Red Ghost - MARK'**
  String get gameGuideCharRedTitle;

  /// No description provided for @gameGuideCharRedSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Marks the passer'**
  String get gameGuideCharRedSubtitle;

  /// No description provided for @gameGuideCharRedTag.
  ///
  /// In en, this message translates to:
  /// **'MARK'**
  String get gameGuideCharRedTag;

  /// No description provided for @gameGuideCharPinkTitle.
  ///
  /// In en, this message translates to:
  /// **'Pink Ghost - READ'**
  String get gameGuideCharPinkTitle;

  /// No description provided for @gameGuideCharPinkSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Anticipates receiver route'**
  String get gameGuideCharPinkSubtitle;

  /// No description provided for @gameGuideCharPinkTag.
  ///
  /// In en, this message translates to:
  /// **'READ'**
  String get gameGuideCharPinkTag;

  /// No description provided for @hideKeyboard.
  ///
  /// In en, this message translates to:
  /// **'Hide keyboard'**
  String get hideKeyboard;

  /// No description provided for @diaryComposerSavePromptTitle.
  ///
  /// In en, this message translates to:
  /// **'Save changes?'**
  String get diaryComposerSavePromptTitle;

  /// No description provided for @diaryComposerSavePromptBody.
  ///
  /// In en, this message translates to:
  /// **'You have unsaved changes. Save before closing?'**
  String get diaryComposerSavePromptBody;

  /// No description provided for @diaryComposerDontSave.
  ///
  /// In en, this message translates to:
  /// **'Don\'t save'**
  String get diaryComposerDontSave;

  /// No description provided for @diaryNewAction.
  ///
  /// In en, this message translates to:
  /// **'New diary'**
  String get diaryNewAction;

  /// No description provided for @diaryNextDayTooltip.
  ///
  /// In en, this message translates to:
  /// **'Next day'**
  String get diaryNextDayTooltip;

  /// No description provided for @diaryPreviousDayTooltip.
  ///
  /// In en, this message translates to:
  /// **'Previous day'**
  String get diaryPreviousDayTooltip;

  /// No description provided for @diaryComposeTooltip.
  ///
  /// In en, this message translates to:
  /// **'Compose'**
  String get diaryComposeTooltip;

  /// No description provided for @diaryEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'No diary pages yet'**
  String get diaryEmptyTitle;

  /// No description provided for @diaryEmptyBody.
  ///
  /// In en, this message translates to:
  /// **'Pick a date and create your first page.'**
  String get diaryEmptyBody;

  /// No description provided for @diaryCreateFirstAction.
  ///
  /// In en, this message translates to:
  /// **'Create first diary'**
  String get diaryCreateFirstAction;

  /// No description provided for @diaryDeleteDialogTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete diary'**
  String get diaryDeleteDialogTitle;

  /// No description provided for @diaryDeleteDialogBody.
  ///
  /// In en, this message translates to:
  /// **'Delete this day diary?'**
  String get diaryDeleteDialogBody;

  /// No description provided for @diaryDeletedMessage.
  ///
  /// In en, this message translates to:
  /// **'Diary deleted.'**
  String get diaryDeletedMessage;

  /// No description provided for @diaryDeleteRestoredMessage.
  ///
  /// In en, this message translates to:
  /// **'Restored deleted diary.'**
  String get diaryDeleteRestoredMessage;

  /// No description provided for @diaryThemeNotebookName.
  ///
  /// In en, this message translates to:
  /// **'Notebook'**
  String get diaryThemeNotebookName;

  /// No description provided for @diaryThemeNotebookDescription.
  ///
  /// In en, this message translates to:
  /// **'A calm paper-textured default diary.'**
  String get diaryThemeNotebookDescription;

  /// No description provided for @diaryThemeDuskName.
  ///
  /// In en, this message translates to:
  /// **'Dusk'**
  String get diaryThemeDuskName;

  /// No description provided for @diaryThemeDuskDescription.
  ///
  /// In en, this message translates to:
  /// **'Reads in the warmth of a red evening glow.'**
  String get diaryThemeDuskDescription;

  /// No description provided for @diaryThemeOceanName.
  ///
  /// In en, this message translates to:
  /// **'Early Sea'**
  String get diaryThemeOceanName;

  /// No description provided for @diaryThemeOceanDescription.
  ///
  /// In en, this message translates to:
  /// **'A crisp and cool page like blue ink.'**
  String get diaryThemeOceanDescription;

  /// No description provided for @diaryVoiceInputTooltip.
  ///
  /// In en, this message translates to:
  /// **'Voice input'**
  String get diaryVoiceInputTooltip;

  /// No description provided for @diaryVoiceInputUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Voice input is not available on this device.'**
  String get diaryVoiceInputUnavailable;

  /// No description provided for @diaryComposerTitle.
  ///
  /// In en, this message translates to:
  /// **'Compose today\'s diary'**
  String get diaryComposerTitle;

  /// No description provided for @diaryComposerDescription.
  ///
  /// In en, this message translates to:
  /// **'Pick stickers from today records below, and write the story yourself in short.'**
  String get diaryComposerDescription;

  /// No description provided for @diaryEmptyHint.
  ///
  /// In en, this message translates to:
  /// **'Keep it short and clear.'**
  String get diaryEmptyHint;

  /// No description provided for @diaryLastSavedPrefix.
  ///
  /// In en, this message translates to:
  /// **'Last saved'**
  String get diaryLastSavedPrefix;

  /// No description provided for @diarySavedMessage.
  ///
  /// In en, this message translates to:
  /// **'Diary saved.'**
  String get diarySavedMessage;

  /// No description provided for @diaryTitlePlaceholder.
  ///
  /// In en, this message translates to:
  /// **'Please enter a title'**
  String get diaryTitlePlaceholder;

  /// No description provided for @diaryTitleLabel.
  ///
  /// In en, this message translates to:
  /// **'Title'**
  String get diaryTitleLabel;

  /// No description provided for @diaryTitleHint.
  ///
  /// In en, this message translates to:
  /// **'Ex: Passing rhythm that lasted through the rain'**
  String get diaryTitleHint;

  /// No description provided for @diaryStoryLabel.
  ///
  /// In en, this message translates to:
  /// **'Body'**
  String get diaryStoryLabel;

  /// No description provided for @diaryStoryPlaceholder.
  ///
  /// In en, this message translates to:
  /// **'Please enter the body text'**
  String get diaryStoryPlaceholder;

  /// No description provided for @diarySaveEmptyMessage.
  ///
  /// In en, this message translates to:
  /// **'Nothing to save yet. Add a title, story, sticker, or photo first.'**
  String get diarySaveEmptyMessage;

  /// No description provided for @diaryClearConfirmTitle.
  ///
  /// In en, this message translates to:
  /// **'Clear all?'**
  String get diaryClearConfirmTitle;

  /// No description provided for @diaryClearConfirmBody.
  ///
  /// In en, this message translates to:
  /// **'This will clear title, story, selected stickers, and photos.'**
  String get diaryClearConfirmBody;

  /// No description provided for @diaryClearAction.
  ///
  /// In en, this message translates to:
  /// **'Clear'**
  String get diaryClearAction;

  /// No description provided for @diaryCustomEmotionLabel.
  ///
  /// In en, this message translates to:
  /// **'Create your own emotion'**
  String get diaryCustomEmotionLabel;

  /// No description provided for @diaryCustomEmotionHint.
  ///
  /// In en, this message translates to:
  /// **'Add a mood sticker in your own words'**
  String get diaryCustomEmotionHint;

  /// No description provided for @diaryCustomEmotionAdd.
  ///
  /// In en, this message translates to:
  /// **'Add emotion'**
  String get diaryCustomEmotionAdd;

  /// No description provided for @diaryExpandNewsStickers.
  ///
  /// In en, this message translates to:
  /// **'Show all news stickers ({count})'**
  String diaryExpandNewsStickers(int count);

  /// No description provided for @diaryCollapseNewsStickers.
  ///
  /// In en, this message translates to:
  /// **'Collapse news stickers'**
  String get diaryCollapseNewsStickers;

  /// No description provided for @homeWeatherTitle.
  ///
  /// In en, this message translates to:
  /// **'Weather coach'**
  String get homeWeatherTitle;

  /// No description provided for @homeWeatherTodayTitle.
  ///
  /// In en, this message translates to:
  /// **'Today\'s weather'**
  String get homeWeatherTodayTitle;

  /// No description provided for @homeWeatherSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Check local conditions and adjust training focus.'**
  String get homeWeatherSubtitle;

  /// No description provided for @homeWeatherLoad.
  ///
  /// In en, this message translates to:
  /// **'Load local weather'**
  String get homeWeatherLoad;

  /// No description provided for @homeWeatherLoading.
  ///
  /// In en, this message translates to:
  /// **'Loading local weather...'**
  String get homeWeatherLoading;

  /// No description provided for @homeWeatherUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Weather info is ready here once location access is allowed.'**
  String get homeWeatherUnavailable;

  /// No description provided for @homeWeatherPermissionNeeded.
  ///
  /// In en, this message translates to:
  /// **'Allow location access to load local weather.'**
  String get homeWeatherPermissionNeeded;

  /// No description provided for @homeWeatherLoadFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to load local weather.'**
  String get homeWeatherLoadFailed;

  /// No description provided for @entryWeatherLoading.
  ///
  /// In en, this message translates to:
  /// **'Loading weather...'**
  String get entryWeatherLoading;

  /// No description provided for @entryWeatherHomeMissing.
  ///
  /// In en, this message translates to:
  /// **'Load weather on Home first.'**
  String get entryWeatherHomeMissing;

  /// No description provided for @entryWeatherUseLocationTooltip.
  ///
  /// In en, this message translates to:
  /// **'Use location weather'**
  String get entryWeatherUseLocationTooltip;

  /// No description provided for @entryWeatherLocationServiceTitle.
  ///
  /// In en, this message translates to:
  /// **'Location service needed'**
  String get entryWeatherLocationServiceTitle;

  /// No description provided for @entryWeatherLocationServiceBody.
  ///
  /// In en, this message translates to:
  /// **'Turn on location services to load current-location weather.'**
  String get entryWeatherLocationServiceBody;

  /// No description provided for @entryWeatherPermissionTitle.
  ///
  /// In en, this message translates to:
  /// **'Location permission needed'**
  String get entryWeatherPermissionTitle;

  /// No description provided for @entryWeatherPermissionBody.
  ///
  /// In en, this message translates to:
  /// **'Location permission is off. Allow it in settings to load current-location weather.'**
  String get entryWeatherPermissionBody;

  /// No description provided for @entryWeatherPermissionRequired.
  ///
  /// In en, this message translates to:
  /// **'Location permission is required.'**
  String get entryWeatherPermissionRequired;

  /// No description provided for @entryWeatherLoadFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to load weather.'**
  String get entryWeatherLoadFailed;

  /// No description provided for @entryWeatherOpenSettings.
  ///
  /// In en, this message translates to:
  /// **'Open settings'**
  String get entryWeatherOpenSettings;

  /// No description provided for @homeWeatherRetryTitle.
  ///
  /// In en, this message translates to:
  /// **'Retry weather'**
  String get homeWeatherRetryTitle;

  /// No description provided for @homeWeatherRetrySubtitle.
  ///
  /// In en, this message translates to:
  /// **'Tap to load'**
  String get homeWeatherRetrySubtitle;

  /// No description provided for @homeWeatherLocationUnknown.
  ///
  /// In en, this message translates to:
  /// **'Current location'**
  String get homeWeatherLocationUnknown;

  /// No description provided for @homeWeatherCountryKorea.
  ///
  /// In en, this message translates to:
  /// **'Korea'**
  String get homeWeatherCountryKorea;

  /// No description provided for @homeWeatherDetailsTitle.
  ///
  /// In en, this message translates to:
  /// **'Weather'**
  String get homeWeatherDetailsTitle;

  /// No description provided for @homeWeatherDetailsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Check local weather and air quality for your current location.'**
  String get homeWeatherDetailsSubtitle;

  /// No description provided for @homeWeatherTomorrowTitle.
  ///
  /// In en, this message translates to:
  /// **'Tomorrow\'s weather'**
  String get homeWeatherTomorrowTitle;

  /// No description provided for @homeWeatherWeeklyTitle.
  ///
  /// In en, this message translates to:
  /// **'Weekly weather'**
  String get homeWeatherWeeklyTitle;

  /// No description provided for @homeWeatherOutfitActionLabel.
  ///
  /// In en, this message translates to:
  /// **'Outfit'**
  String get homeWeatherOutfitActionLabel;

  /// No description provided for @homeWeatherTomorrowActionLabel.
  ///
  /// In en, this message translates to:
  /// **'Tomorrow'**
  String get homeWeatherTomorrowActionLabel;

  /// No description provided for @homeWeatherWeeklyActionLabel.
  ///
  /// In en, this message translates to:
  /// **'Week'**
  String get homeWeatherWeeklyActionLabel;

  /// No description provided for @homeWeatherTomorrowNavSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Check tomorrow\'s forecast and outfit guide separately.'**
  String get homeWeatherTomorrowNavSubtitle;

  /// No description provided for @homeWeatherWeeklyNavSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Review the 7-day forecast and air-quality trend separately.'**
  String get homeWeatherWeeklyNavSubtitle;

  /// No description provided for @homeWeatherMorningLabel.
  ///
  /// In en, this message translates to:
  /// **'Morning'**
  String get homeWeatherMorningLabel;

  /// No description provided for @homeWeatherEveningLabel.
  ///
  /// In en, this message translates to:
  /// **'Evening'**
  String get homeWeatherEveningLabel;

  /// No description provided for @homeWeatherCacheHint.
  ///
  /// In en, this message translates to:
  /// **'Recently fetched weather is reused for 10 minutes.'**
  String get homeWeatherCacheHint;

  /// No description provided for @homeWeatherDailyHighLow.
  ///
  /// In en, this message translates to:
  /// **'High/Low'**
  String get homeWeatherDailyHighLow;

  /// No description provided for @homeWeatherTomorrowFallback.
  ///
  /// In en, this message translates to:
  /// **'Tomorrow\'s forecast is not available yet.'**
  String get homeWeatherTomorrowFallback;

  /// No description provided for @homeWeatherWeeklyFallback.
  ///
  /// In en, this message translates to:
  /// **'Weekly forecast is not available yet.'**
  String get homeWeatherWeeklyFallback;

  /// No description provided for @homeWeatherTomorrowOutfitTitle.
  ///
  /// In en, this message translates to:
  /// **'Tomorrow\'s outfit'**
  String get homeWeatherTomorrowOutfitTitle;

  /// No description provided for @homeWeatherTomorrowOutfitFallback.
  ///
  /// In en, this message translates to:
  /// **'Tomorrow\'s outfit guide is not ready yet.'**
  String get homeWeatherTomorrowOutfitFallback;

  /// No description provided for @homeWeatherTemperatureRange.
  ///
  /// In en, this message translates to:
  /// **'High/Low'**
  String get homeWeatherTemperatureRange;

  /// No description provided for @homeWeatherFeelsLike.
  ///
  /// In en, this message translates to:
  /// **'Feels like'**
  String get homeWeatherFeelsLike;

  /// No description provided for @homeWeatherHumidity.
  ///
  /// In en, this message translates to:
  /// **'Humidity'**
  String get homeWeatherHumidity;

  /// No description provided for @homeWeatherPrecipitation.
  ///
  /// In en, this message translates to:
  /// **'Precipitation'**
  String get homeWeatherPrecipitation;

  /// No description provided for @homeWeatherPrecipitationProbability.
  ///
  /// In en, this message translates to:
  /// **'Rain chance'**
  String get homeWeatherPrecipitationProbability;

  /// No description provided for @weatherPrecipitationNone.
  ///
  /// In en, this message translates to:
  /// **'None'**
  String get weatherPrecipitationNone;

  /// No description provided for @weatherPrecipitationTrace.
  ///
  /// In en, this message translates to:
  /// **'A little rain'**
  String get weatherPrecipitationTrace;

  /// No description provided for @weatherPrecipitationLight.
  ///
  /// In en, this message translates to:
  /// **'Light rain'**
  String get weatherPrecipitationLight;

  /// No description provided for @weatherPrecipitationModerate.
  ///
  /// In en, this message translates to:
  /// **'Steady rain'**
  String get weatherPrecipitationModerate;

  /// No description provided for @weatherPrecipitationHeavy.
  ///
  /// In en, this message translates to:
  /// **'Heavy rain'**
  String get weatherPrecipitationHeavy;

  /// No description provided for @weatherPrecipitationVeryHeavy.
  ///
  /// In en, this message translates to:
  /// **'Very heavy rain'**
  String get weatherPrecipitationVeryHeavy;

  /// No description provided for @homeWeatherHourlyPrecipitation.
  ///
  /// In en, this message translates to:
  /// **'Hourly rain timeline'**
  String get homeWeatherHourlyPrecipitation;

  /// No description provided for @homeWeatherHourlyTemperature.
  ///
  /// In en, this message translates to:
  /// **'Hourly temperature'**
  String get homeWeatherHourlyTemperature;

  /// No description provided for @homeWeatherHourlyOverview.
  ///
  /// In en, this message translates to:
  /// **'Hourly weather'**
  String get homeWeatherHourlyOverview;

  /// No description provided for @homeWeatherWindSpeed.
  ///
  /// In en, this message translates to:
  /// **'Wind'**
  String get homeWeatherWindSpeed;

  /// No description provided for @homeWeatherUvIndex.
  ///
  /// In en, this message translates to:
  /// **'UV index'**
  String get homeWeatherUvIndex;

  /// No description provided for @homeWeatherOutfitTitle.
  ///
  /// In en, this message translates to:
  /// **'Recommended training outfit'**
  String get homeWeatherOutfitTitle;

  /// No description provided for @homeWeatherOutfitBaseHot.
  ///
  /// In en, this message translates to:
  /// **'Short-sleeve kit, light shorts, and breathable socks.'**
  String get homeWeatherOutfitBaseHot;

  /// No description provided for @homeWeatherOutfitBaseCold.
  ///
  /// In en, this message translates to:
  /// **'Thermal base layer, gloves, long socks, and a beanie if needed.'**
  String get homeWeatherOutfitBaseCold;

  /// No description provided for @homeWeatherOutfitBaseMild.
  ///
  /// In en, this message translates to:
  /// **'Standard kit with a light base layer is enough.'**
  String get homeWeatherOutfitBaseMild;

  /// No description provided for @homeWeatherOutfitRain.
  ///
  /// In en, this message translates to:
  /// **'Pack a thin waterproof shell and an extra pair of socks.'**
  String get homeWeatherOutfitRain;

  /// No description provided for @homeWeatherOutfitSnow.
  ///
  /// In en, this message translates to:
  /// **'Wear warm base layers and thick socks; watch for slippery ground.'**
  String get homeWeatherOutfitSnow;

  /// No description provided for @homeWeatherOutfitWind.
  ///
  /// In en, this message translates to:
  /// **'Add a windbreaker to keep body temperature stable.'**
  String get homeWeatherOutfitWind;

  /// No description provided for @homeWeatherOutfitAirCaution.
  ///
  /// In en, this message translates to:
  /// **'If air quality is poor, wear a mask when commuting and reduce hard outdoor work.'**
  String get homeWeatherOutfitAirCaution;

  /// No description provided for @homeWeatherOutfitButton.
  ///
  /// In en, this message translates to:
  /// **'Outfit guide'**
  String get homeWeatherOutfitButton;

  /// No description provided for @homeWeatherOutfitLayersLabel.
  ///
  /// In en, this message translates to:
  /// **'Top layers'**
  String get homeWeatherOutfitLayersLabel;

  /// No description provided for @homeWeatherOutfitOuterLabel.
  ///
  /// In en, this message translates to:
  /// **'Outer layer'**
  String get homeWeatherOutfitOuterLabel;

  /// No description provided for @homeWeatherOutfitBottomLabel.
  ///
  /// In en, this message translates to:
  /// **'Bottom'**
  String get homeWeatherOutfitBottomLabel;

  /// No description provided for @homeWeatherOutfitAccessoriesLabel.
  ///
  /// In en, this message translates to:
  /// **'Accessories'**
  String get homeWeatherOutfitAccessoriesLabel;

  /// No description provided for @homeWeatherOutfitNotesLabel.
  ///
  /// In en, this message translates to:
  /// **'Notes'**
  String get homeWeatherOutfitNotesLabel;

  /// No description provided for @homeWeatherOutfitViewAllCases.
  ///
  /// In en, this message translates to:
  /// **'View all outfit cases'**
  String get homeWeatherOutfitViewAllCases;

  /// No description provided for @homeWeatherOutfitAllCasesTitle.
  ///
  /// In en, this message translates to:
  /// **'All outfit cases'**
  String get homeWeatherOutfitAllCasesTitle;

  /// No description provided for @homeWeatherOutfitAllCasesSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Review each weather band with top layers, outer layer, bottoms, and accessory details.'**
  String get homeWeatherOutfitAllCasesSubtitle;

  /// No description provided for @homeWeatherOutfitCaseHotTitle.
  ///
  /// In en, this message translates to:
  /// **'Hot summer'**
  String get homeWeatherOutfitCaseHotTitle;

  /// No description provided for @homeWeatherOutfitCaseHotRange.
  ///
  /// In en, this message translates to:
  /// **'Feels like 30°C+'**
  String get homeWeatherOutfitCaseHotRange;

  /// No description provided for @homeWeatherOutfitCaseWarmTitle.
  ///
  /// In en, this message translates to:
  /// **'Warm training day'**
  String get homeWeatherOutfitCaseWarmTitle;

  /// No description provided for @homeWeatherOutfitCaseWarmRange.
  ///
  /// In en, this message translates to:
  /// **'Feels like 22-29°C'**
  String get homeWeatherOutfitCaseWarmRange;

  /// No description provided for @homeWeatherOutfitCaseMildTitle.
  ///
  /// In en, this message translates to:
  /// **'Mild day'**
  String get homeWeatherOutfitCaseMildTitle;

  /// No description provided for @homeWeatherOutfitCaseMildRange.
  ///
  /// In en, this message translates to:
  /// **'Feels like 15-21°C'**
  String get homeWeatherOutfitCaseMildRange;

  /// No description provided for @homeWeatherOutfitCaseCoolTitle.
  ///
  /// In en, this message translates to:
  /// **'Cool day'**
  String get homeWeatherOutfitCaseCoolTitle;

  /// No description provided for @homeWeatherOutfitCaseCoolRange.
  ///
  /// In en, this message translates to:
  /// **'Feels like 8-14°C'**
  String get homeWeatherOutfitCaseCoolRange;

  /// No description provided for @homeWeatherOutfitCaseColdTitle.
  ///
  /// In en, this message translates to:
  /// **'Cold day'**
  String get homeWeatherOutfitCaseColdTitle;

  /// No description provided for @homeWeatherOutfitCaseColdRange.
  ///
  /// In en, this message translates to:
  /// **'Feels like 2-7°C'**
  String get homeWeatherOutfitCaseColdRange;

  /// No description provided for @homeWeatherOutfitCaseWetTitle.
  ///
  /// In en, this message translates to:
  /// **'Rainy or snowy day'**
  String get homeWeatherOutfitCaseWetTitle;

  /// No description provided for @homeWeatherOutfitCaseWetRange.
  ///
  /// In en, this message translates to:
  /// **'When raining or snowing'**
  String get homeWeatherOutfitCaseWetRange;

  /// No description provided for @homeWeatherOutfitLayersDefault.
  ///
  /// In en, this message translates to:
  /// **'Base layer + short-sleeve top'**
  String get homeWeatherOutfitLayersDefault;

  /// No description provided for @homeWeatherOutfitOuterDefault.
  ///
  /// In en, this message translates to:
  /// **'Light zip-up or vest'**
  String get homeWeatherOutfitOuterDefault;

  /// No description provided for @homeWeatherOutfitBottomDefault.
  ///
  /// In en, this message translates to:
  /// **'Standard shorts'**
  String get homeWeatherOutfitBottomDefault;

  /// No description provided for @homeWeatherOutfitAccessoriesDefault.
  ///
  /// In en, this message translates to:
  /// **'Spare socks and water bottle'**
  String get homeWeatherOutfitAccessoriesDefault;

  /// No description provided for @homeWeatherOutfitLayersHot.
  ///
  /// In en, this message translates to:
  /// **'Sleeveless/short-sleeve + cooling base'**
  String get homeWeatherOutfitLayersHot;

  /// No description provided for @homeWeatherOutfitOuterNone.
  ///
  /// In en, this message translates to:
  /// **'No outerwear'**
  String get homeWeatherOutfitOuterNone;

  /// No description provided for @homeWeatherOutfitBottomHot.
  ///
  /// In en, this message translates to:
  /// **'Breathable shorts'**
  String get homeWeatherOutfitBottomHot;

  /// No description provided for @homeWeatherOutfitAccessoriesHot.
  ///
  /// In en, this message translates to:
  /// **'Cool towel, iced water, cap'**
  String get homeWeatherOutfitAccessoriesHot;

  /// No description provided for @homeWeatherOutfitNoteHotBreaks.
  ///
  /// In en, this message translates to:
  /// **'Take frequent cooling breaks'**
  String get homeWeatherOutfitNoteHotBreaks;

  /// No description provided for @homeWeatherOutfitLayersWarm.
  ///
  /// In en, this message translates to:
  /// **'Short-sleeve training top'**
  String get homeWeatherOutfitLayersWarm;

  /// No description provided for @homeWeatherOutfitBottomWarm.
  ///
  /// In en, this message translates to:
  /// **'Training shorts'**
  String get homeWeatherOutfitBottomWarm;

  /// No description provided for @homeWeatherOutfitAccessoriesWarm.
  ///
  /// In en, this message translates to:
  /// **'Spare shirt and sweat towel'**
  String get homeWeatherOutfitAccessoriesWarm;

  /// No description provided for @homeWeatherOutfitLayersMild.
  ///
  /// In en, this message translates to:
  /// **'Base layer + short/long sleeve'**
  String get homeWeatherOutfitLayersMild;

  /// No description provided for @homeWeatherOutfitOuterMild.
  ///
  /// In en, this message translates to:
  /// **'Training zip-up or vest'**
  String get homeWeatherOutfitOuterMild;

  /// No description provided for @homeWeatherOutfitBottomMild.
  ///
  /// In en, this message translates to:
  /// **'Light track pants or shorts'**
  String get homeWeatherOutfitBottomMild;

  /// No description provided for @homeWeatherOutfitAccessoriesMild.
  ///
  /// In en, this message translates to:
  /// **'Warm-up layer'**
  String get homeWeatherOutfitAccessoriesMild;

  /// No description provided for @homeWeatherOutfitLayersCool.
  ///
  /// In en, this message translates to:
  /// **'Brushed base layer + long-sleeve top'**
  String get homeWeatherOutfitLayersCool;

  /// No description provided for @homeWeatherOutfitOuterCool.
  ///
  /// In en, this message translates to:
  /// **'Windbreaker + vest'**
  String get homeWeatherOutfitOuterCool;

  /// No description provided for @homeWeatherOutfitBottomTrackPants.
  ///
  /// In en, this message translates to:
  /// **'Long training pants'**
  String get homeWeatherOutfitBottomTrackPants;

  /// No description provided for @homeWeatherOutfitAccessoriesCool.
  ///
  /// In en, this message translates to:
  /// **'Light gloves, neck warmer'**
  String get homeWeatherOutfitAccessoriesCool;

  /// No description provided for @homeWeatherOutfitLayersCold.
  ///
  /// In en, this message translates to:
  /// **'Thermal base + long-sleeve + midlayer'**
  String get homeWeatherOutfitLayersCold;

  /// No description provided for @homeWeatherOutfitOuterCold.
  ///
  /// In en, this message translates to:
  /// **'Windproof jacket or padded vest'**
  String get homeWeatherOutfitOuterCold;

  /// No description provided for @homeWeatherOutfitAccessoriesCold.
  ///
  /// In en, this message translates to:
  /// **'Winter gloves, neck warmer, ear cover'**
  String get homeWeatherOutfitAccessoriesCold;

  /// No description provided for @homeWeatherOutfitLayersVeryCold.
  ///
  /// In en, this message translates to:
  /// **'Heat base layer + thick midlayer'**
  String get homeWeatherOutfitLayersVeryCold;

  /// No description provided for @homeWeatherOutfitOuterVeryCold.
  ///
  /// In en, this message translates to:
  /// **'Light puffer/training padded jacket'**
  String get homeWeatherOutfitOuterVeryCold;

  /// No description provided for @homeWeatherOutfitBottomVeryCold.
  ///
  /// In en, this message translates to:
  /// **'Thermal training pants'**
  String get homeWeatherOutfitBottomVeryCold;

  /// No description provided for @homeWeatherOutfitAccessoriesVeryCold.
  ///
  /// In en, this message translates to:
  /// **'Insulated gloves, neck warmer, beanie'**
  String get homeWeatherOutfitAccessoriesVeryCold;

  /// No description provided for @homeWeatherOutfitNoteVeryCold.
  ///
  /// In en, this message translates to:
  /// **'Warm up indoors then do short outdoor sets'**
  String get homeWeatherOutfitNoteVeryCold;

  /// No description provided for @homeWeatherOutfitNoteStrongWind.
  ///
  /// In en, this message translates to:
  /// **'Strong wind: windbreaker and neck warmer required'**
  String get homeWeatherOutfitNoteStrongWind;

  /// No description provided for @homeWeatherOutfitOuterWaterproof.
  ///
  /// In en, this message translates to:
  /// **'Waterproof windproof jacket'**
  String get homeWeatherOutfitOuterWaterproof;

  /// No description provided for @homeWeatherOutfitOuterRainLight.
  ///
  /// In en, this message translates to:
  /// **'Water-resistant jacket + light midlayer'**
  String get homeWeatherOutfitOuterRainLight;

  /// No description provided for @homeWeatherOutfitAccessoriesRain.
  ///
  /// In en, this message translates to:
  /// **'{accessories}, waterproof or spare socks'**
  String homeWeatherOutfitAccessoriesRain(Object accessories);

  /// No description provided for @homeWeatherOutfitNoteWetGrass.
  ///
  /// In en, this message translates to:
  /// **'Watch slippery wet grass'**
  String get homeWeatherOutfitNoteWetGrass;

  /// No description provided for @homeWeatherOutfitAccessoriesSnow.
  ///
  /// In en, this message translates to:
  /// **'{accessories}, hand warmers (optional)'**
  String homeWeatherOutfitAccessoriesSnow(Object accessories);

  /// No description provided for @homeWeatherOutfitNoteIcy.
  ///
  /// In en, this message translates to:
  /// **'Avoid icy zones'**
  String get homeWeatherOutfitNoteIcy;

  /// No description provided for @homeWeatherOutfitBottomFleece.
  ///
  /// In en, this message translates to:
  /// **'Fleece-lined pants'**
  String get homeWeatherOutfitBottomFleece;

  /// No description provided for @homeWeatherOutfitCautionNormal.
  ///
  /// In en, this message translates to:
  /// **'Normal intensity is fine in current conditions'**
  String get homeWeatherOutfitCautionNormal;

  /// No description provided for @homeWeatherAirQualityTitle.
  ///
  /// In en, this message translates to:
  /// **'Air quality'**
  String get homeWeatherAirQualityTitle;

  /// No description provided for @homeWeatherAirQualitySubtitle.
  ///
  /// In en, this message translates to:
  /// **'Lower numbers usually mean easier breathing outdoors.'**
  String get homeWeatherAirQualitySubtitle;

  /// No description provided for @homeWeatherAirQualityForecastMissingReason.
  ///
  /// In en, this message translates to:
  /// **'Air-quality forecast is unavailable for this area or time.'**
  String get homeWeatherAirQualityForecastMissingReason;

  /// No description provided for @homeWeatherAirGuideTitle.
  ///
  /// In en, this message translates to:
  /// **'Outdoor activity guide'**
  String get homeWeatherAirGuideTitle;

  /// No description provided for @homeWeatherAirGuideUnknown.
  ///
  /// In en, this message translates to:
  /// **'Refresh air data to see outdoor activity guidance.'**
  String get homeWeatherAirGuideUnknown;

  /// No description provided for @homeWeatherAirGuideGood.
  ///
  /// In en, this message translates to:
  /// **'Air quality is stable enough for normal outdoor activity and training.'**
  String get homeWeatherAirGuideGood;

  /// No description provided for @homeWeatherAirGuideModerate.
  ///
  /// In en, this message translates to:
  /// **'Most outdoor activity is fine, but lower the load if your breathing is sensitive.'**
  String get homeWeatherAirGuideModerate;

  /// No description provided for @homeWeatherAirGuideSensitive.
  ///
  /// In en, this message translates to:
  /// **'If breathing gets irritated easily, reduce long outdoor sessions and hard efforts.'**
  String get homeWeatherAirGuideSensitive;

  /// No description provided for @homeWeatherAirGuideUnhealthy.
  ///
  /// In en, this message translates to:
  /// **'Avoid hard outdoor activity and switch to indoor training or recovery if possible.'**
  String get homeWeatherAirGuideUnhealthy;

  /// No description provided for @homeWeatherAirGuideVeryUnhealthy.
  ///
  /// In en, this message translates to:
  /// **'Minimize outdoor activity and move to indoor recovery or technical work.'**
  String get homeWeatherAirGuideVeryUnhealthy;

  /// No description provided for @homeWeatherAirGuideHazardous.
  ///
  /// In en, this message translates to:
  /// **'Stop outdoor activity and stay indoors if possible.'**
  String get homeWeatherAirGuideHazardous;

  /// No description provided for @homeWeatherComparedYesterday.
  ///
  /// In en, this message translates to:
  /// **'Vs. yesterday'**
  String get homeWeatherComparedYesterday;

  /// No description provided for @homeWeatherPm10.
  ///
  /// In en, this message translates to:
  /// **'Fine dust'**
  String get homeWeatherPm10;

  /// No description provided for @homeWeatherPm25.
  ///
  /// In en, this message translates to:
  /// **'Ultrafine dust'**
  String get homeWeatherPm25;

  /// No description provided for @homeWeatherAqi.
  ///
  /// In en, this message translates to:
  /// **'AQI'**
  String get homeWeatherAqi;

  /// No description provided for @homeWeatherAqiLabel.
  ///
  /// In en, this message translates to:
  /// **'Air quality index'**
  String get homeWeatherAqiLabel;

  /// No description provided for @homeWeatherAqiDescription.
  ///
  /// In en, this message translates to:
  /// **'AQI is a simple score that shows how clean the air feels.'**
  String get homeWeatherAqiDescription;

  /// No description provided for @homeWeatherAqiScaleGood.
  ///
  /// In en, this message translates to:
  /// **'0-50 good'**
  String get homeWeatherAqiScaleGood;

  /// No description provided for @homeWeatherAqiScaleModerate.
  ///
  /// In en, this message translates to:
  /// **'51-100 moderate'**
  String get homeWeatherAqiScaleModerate;

  /// No description provided for @homeWeatherAqiScaleSensitive.
  ///
  /// In en, this message translates to:
  /// **'101+ caution'**
  String get homeWeatherAqiScaleSensitive;

  /// No description provided for @homeWeatherTomorrowCondition.
  ///
  /// In en, this message translates to:
  /// **'Condition'**
  String get homeWeatherTomorrowCondition;

  /// No description provided for @homeWeatherWeeklyDateLabel.
  ///
  /// In en, this message translates to:
  /// **'Date'**
  String get homeWeatherWeeklyDateLabel;

  /// No description provided for @homeWeatherWeeklyConditionLabel.
  ///
  /// In en, this message translates to:
  /// **'Forecast'**
  String get homeWeatherWeeklyConditionLabel;

  /// No description provided for @homeWeatherStatusGood.
  ///
  /// In en, this message translates to:
  /// **'Good'**
  String get homeWeatherStatusGood;

  /// No description provided for @homeWeatherStatusModerate.
  ///
  /// In en, this message translates to:
  /// **'Moderate'**
  String get homeWeatherStatusModerate;

  /// No description provided for @homeWeatherStatusSensitive.
  ///
  /// In en, this message translates to:
  /// **'Take care if breathing is sensitive'**
  String get homeWeatherStatusSensitive;

  /// No description provided for @homeWeatherStatusUnhealthy.
  ///
  /// In en, this message translates to:
  /// **'Unhealthy'**
  String get homeWeatherStatusUnhealthy;

  /// No description provided for @homeWeatherStatusVeryUnhealthy.
  ///
  /// In en, this message translates to:
  /// **'Very unhealthy'**
  String get homeWeatherStatusVeryUnhealthy;

  /// No description provided for @homeWeatherStatusHazardous.
  ///
  /// In en, this message translates to:
  /// **'Hazardous'**
  String get homeWeatherStatusHazardous;

  /// No description provided for @weatherLabelDefault.
  ///
  /// In en, this message translates to:
  /// **'Weather'**
  String get weatherLabelDefault;

  /// No description provided for @weatherLabelClear.
  ///
  /// In en, this message translates to:
  /// **'Clear'**
  String get weatherLabelClear;

  /// No description provided for @weatherLabelCloudy.
  ///
  /// In en, this message translates to:
  /// **'Cloudy'**
  String get weatherLabelCloudy;

  /// No description provided for @weatherLabelFog.
  ///
  /// In en, this message translates to:
  /// **'Fog'**
  String get weatherLabelFog;

  /// No description provided for @weatherLabelDrizzle.
  ///
  /// In en, this message translates to:
  /// **'Drizzle'**
  String get weatherLabelDrizzle;

  /// No description provided for @weatherLabelRain.
  ///
  /// In en, this message translates to:
  /// **'Rain'**
  String get weatherLabelRain;

  /// No description provided for @weatherLabelSnow.
  ///
  /// In en, this message translates to:
  /// **'Snow'**
  String get weatherLabelSnow;

  /// No description provided for @weatherLabelThunderstorm.
  ///
  /// In en, this message translates to:
  /// **'Thunderstorm'**
  String get weatherLabelThunderstorm;

  /// No description provided for @diaryStickerTraining.
  ///
  /// In en, this message translates to:
  /// **'Training'**
  String get diaryStickerTraining;

  /// No description provided for @diaryStickerMatch.
  ///
  /// In en, this message translates to:
  /// **'Match'**
  String get diaryStickerMatch;

  /// No description provided for @diaryStickerPlan.
  ///
  /// In en, this message translates to:
  /// **'Plan'**
  String get diaryStickerPlan;

  /// No description provided for @diaryStickerFortune.
  ///
  /// In en, this message translates to:
  /// **'Today\'s line'**
  String get diaryStickerFortune;

  /// No description provided for @diaryStickerBoard.
  ///
  /// In en, this message translates to:
  /// **'Board'**
  String get diaryStickerBoard;

  /// No description provided for @diaryStickerNews.
  ///
  /// In en, this message translates to:
  /// **'News'**
  String get diaryStickerNews;

  /// No description provided for @diaryStickerMeal.
  ///
  /// In en, this message translates to:
  /// **'Rice bowl'**
  String get diaryStickerMeal;

  /// No description provided for @diaryStickerConditioning.
  ///
  /// In en, this message translates to:
  /// **'Jump rope/lifting'**
  String get diaryStickerConditioning;

  /// No description provided for @diaryStickerInjury.
  ///
  /// In en, this message translates to:
  /// **'Injury'**
  String get diaryStickerInjury;

  /// No description provided for @diaryStickerQuiz.
  ///
  /// In en, this message translates to:
  /// **'Quiz'**
  String get diaryStickerQuiz;

  /// No description provided for @diaryStickerWeather.
  ///
  /// In en, this message translates to:
  /// **'Weather'**
  String get diaryStickerWeather;

  /// No description provided for @diaryStickerParentFeedback.
  ///
  /// In en, this message translates to:
  /// **'Parent feedback'**
  String get diaryStickerParentFeedback;

  /// No description provided for @diaryInjuryNoDetails.
  ///
  /// In en, this message translates to:
  /// **'No injury note was saved.'**
  String get diaryInjuryNoDetails;

  /// No description provided for @diaryInjuryRehab.
  ///
  /// In en, this message translates to:
  /// **'Rehab'**
  String get diaryInjuryRehab;

  /// No description provided for @diaryInjuryStorySentence.
  ///
  /// In en, this message translates to:
  /// **'Write the moment pain showed up and what needs recovery next.'**
  String get diaryInjuryStorySentence;

  /// No description provided for @diaryQuizStorySentence.
  ///
  /// In en, this message translates to:
  /// **'Write the question or concept you want to keep from the quiz run.'**
  String get diaryQuizStorySentence;

  /// No description provided for @diaryParentFeedbackStorySentence.
  ///
  /// In en, this message translates to:
  /// **'Parent feedback: {message}'**
  String diaryParentFeedbackStorySentence(String message);

  /// No description provided for @diaryQuizSummaryPerfect.
  ///
  /// In en, this message translates to:
  /// **'{score}/{total} correct · no misses'**
  String diaryQuizSummaryPerfect(int score, int total);

  /// No description provided for @diaryQuizSummaryWithMisses.
  ///
  /// In en, this message translates to:
  /// **'{score}/{total} correct · {wrongCount} misses'**
  String diaryQuizSummaryWithMisses(int score, int total, int wrongCount);

  /// No description provided for @diaryQuizExpandQuestions.
  ///
  /// In en, this message translates to:
  /// **'Show all answers ({count})'**
  String diaryQuizExpandQuestions(int count);

  /// No description provided for @diaryQuizCollapseQuestions.
  ///
  /// In en, this message translates to:
  /// **'Collapse answers'**
  String get diaryQuizCollapseQuestions;

  /// No description provided for @diaryQuizQuestionLabel.
  ///
  /// In en, this message translates to:
  /// **'Question'**
  String get diaryQuizQuestionLabel;

  /// No description provided for @diaryQuizAnswerLabel.
  ///
  /// In en, this message translates to:
  /// **'Answer'**
  String get diaryQuizAnswerLabel;

  /// No description provided for @diaryQuizWrongAnswerLabel.
  ///
  /// In en, this message translates to:
  /// **'Wrong answer'**
  String get diaryQuizWrongAnswerLabel;

  /// No description provided for @diaryQuizWrongAnswerNone.
  ///
  /// In en, this message translates to:
  /// **'No wrong answer'**
  String get diaryQuizWrongAnswerNone;

  /// No description provided for @diaryQuizNoMissesLabel.
  ///
  /// In en, this message translates to:
  /// **'This quiz run finished without any misses.'**
  String get diaryQuizNoMissesLabel;

  /// No description provided for @diaryTrainingStatusLabel.
  ///
  /// In en, this message translates to:
  /// **'Training status'**
  String get diaryTrainingStatusLabel;

  /// No description provided for @diaryConditioningJumpRopeLabel.
  ///
  /// In en, this message translates to:
  /// **'Jump rope'**
  String get diaryConditioningJumpRopeLabel;

  /// No description provided for @diaryConditioningLiftingLabel.
  ///
  /// In en, this message translates to:
  /// **'Lifting'**
  String get diaryConditioningLiftingLabel;

  /// No description provided for @diaryWeatherEmpty.
  ///
  /// In en, this message translates to:
  /// **'No weather was logged.'**
  String get diaryWeatherEmpty;

  /// No description provided for @diaryUnknownSource.
  ///
  /// In en, this message translates to:
  /// **'Unknown source'**
  String get diaryUnknownSource;

  /// No description provided for @diaryLocationUnset.
  ///
  /// In en, this message translates to:
  /// **'No location'**
  String get diaryLocationUnset;

  /// No description provided for @diaryLocationNotLogged.
  ///
  /// In en, this message translates to:
  /// **'No location logged'**
  String get diaryLocationNotLogged;

  /// No description provided for @diaryFundamentalsFallback.
  ///
  /// In en, this message translates to:
  /// **'fundamentals'**
  String get diaryFundamentalsFallback;

  /// No description provided for @diaryUpdatedAt.
  ///
  /// In en, this message translates to:
  /// **'Updated {date}'**
  String diaryUpdatedAt(String date);

  /// No description provided for @diaryMatchOpponentUnknown.
  ///
  /// In en, this message translates to:
  /// **'vs unknown opponent'**
  String get diaryMatchOpponentUnknown;

  /// No description provided for @diaryMatchOpponentLabel.
  ///
  /// In en, this message translates to:
  /// **'vs {opponent}'**
  String diaryMatchOpponentLabel(String opponent);

  /// No description provided for @diaryMatchScoreLabel.
  ///
  /// In en, this message translates to:
  /// **'score {score}'**
  String diaryMatchScoreLabel(String score);

  /// No description provided for @diaryMatchGoalsLabel.
  ///
  /// In en, this message translates to:
  /// **'goals {count}'**
  String diaryMatchGoalsLabel(int count);

  /// No description provided for @diaryMatchAssistsLabel.
  ///
  /// In en, this message translates to:
  /// **'assists {count}'**
  String diaryMatchAssistsLabel(int count);

  /// No description provided for @diaryMatchMinutesPlayed.
  ///
  /// In en, this message translates to:
  /// **'{minutes} played'**
  String diaryMatchMinutesPlayed(String minutes);

  /// No description provided for @diaryMatchPersonalStats.
  ///
  /// In en, this message translates to:
  /// **'{goals}G {assists}A'**
  String diaryMatchPersonalStats(int goals, int assists);

  /// No description provided for @diaryTotalRiceBowls.
  ///
  /// In en, this message translates to:
  /// **'{count} bowls total'**
  String diaryTotalRiceBowls(String count);

  /// No description provided for @diaryCompletedMeals.
  ///
  /// In en, this message translates to:
  /// **'{count} meals logged'**
  String diaryCompletedMeals(int count);

  /// No description provided for @diaryReps.
  ///
  /// In en, this message translates to:
  /// **'{count} reps'**
  String diaryReps(int count);

  /// No description provided for @diaryTotalReps.
  ///
  /// In en, this message translates to:
  /// **'{count} reps total'**
  String diaryTotalReps(int count);

  /// No description provided for @diaryLiftingReps.
  ///
  /// In en, this message translates to:
  /// **'Lifting {count} reps'**
  String diaryLiftingReps(int count);

  /// No description provided for @diaryJumpRopeReps.
  ///
  /// In en, this message translates to:
  /// **'Jump rope {count} reps'**
  String diaryJumpRopeReps(int count);

  /// No description provided for @diaryJumpRopeMinutes.
  ///
  /// In en, this message translates to:
  /// **'Jump rope {minutes}'**
  String diaryJumpRopeMinutes(String minutes);

  /// No description provided for @diaryJumpRopeCombined.
  ///
  /// In en, this message translates to:
  /// **'Jump rope {minutes}/{count} reps'**
  String diaryJumpRopeCombined(int count, String minutes);

  /// No description provided for @diaryConditioningSummary.
  ///
  /// In en, this message translates to:
  /// **'Lifting {liftingCount} reps · Jump rope {jumpMinutes}/{jumpCount} reps'**
  String diaryConditioningSummary(
      int liftingCount, int jumpCount, String jumpMinutes);

  /// No description provided for @diaryStoryPromptFromSeed.
  ///
  /// In en, this message translates to:
  /// **'Start from {title} and continue with the scene you want to keep today. You can naturally connect what you planned, what you actually did, and how it felt.'**
  String diaryStoryPromptFromSeed(String title);

  /// No description provided for @diaryStoryPromptDefault.
  ///
  /// In en, this message translates to:
  /// **'Write today in your own words. Start with what happened around {place}, what stayed with you in {focus}, what felt good, and what still lingers.'**
  String diaryStoryPromptDefault(String place, String focus);

  /// No description provided for @diaryPlanStorySentence.
  ///
  /// In en, this message translates to:
  /// **'Start from {title} and write why this task deserves a place in today\'s diary.'**
  String diaryPlanStorySentence(String title);

  /// No description provided for @diaryPlanNoteTitle.
  ///
  /// In en, this message translates to:
  /// **'{category} note'**
  String diaryPlanNoteTitle(String category);

  /// No description provided for @diaryPlanDurationLabel.
  ///
  /// In en, this message translates to:
  /// **'{duration} plan'**
  String diaryPlanDurationLabel(String duration);

  /// No description provided for @diaryPinnedPlanTooltip.
  ///
  /// In en, this message translates to:
  /// **'Pinned plan'**
  String get diaryPinnedPlanTooltip;

  /// No description provided for @diaryTrainingTodoTitle.
  ///
  /// In en, this message translates to:
  /// **'Training · {label}'**
  String diaryTrainingTodoTitle(String label);

  /// No description provided for @diaryTrainingSummaryTitle.
  ///
  /// In en, this message translates to:
  /// **'{label} summary'**
  String diaryTrainingSummaryTitle(String label);

  /// No description provided for @diaryFortunePinSummary.
  ///
  /// In en, this message translates to:
  /// **'Pin today\'s line as a diary sticker.'**
  String get diaryFortunePinSummary;

  /// No description provided for @diaryFortuneStorySentence.
  ///
  /// In en, this message translates to:
  /// **'Write the scene you want to keep from today\'s line.'**
  String get diaryFortuneStorySentence;

  /// No description provided for @diaryFortuneNoteTitle.
  ///
  /// In en, this message translates to:
  /// **'Fortune line note'**
  String get diaryFortuneNoteTitle;

  /// No description provided for @diaryMatchTodoTitleNoOpponent.
  ///
  /// In en, this message translates to:
  /// **'Match'**
  String get diaryMatchTodoTitleNoOpponent;

  /// No description provided for @diaryMatchTodoTitleWithOpponent.
  ///
  /// In en, this message translates to:
  /// **'Match · vs {opponent}'**
  String diaryMatchTodoTitleWithOpponent(String opponent);

  /// No description provided for @diaryMatchStorySentence.
  ///
  /// In en, this message translates to:
  /// **'Replay the match scene by scene and write both the sharp choices and the missed ones.'**
  String get diaryMatchStorySentence;

  /// No description provided for @diaryMatchFlowTitle.
  ///
  /// In en, this message translates to:
  /// **'Match flow'**
  String get diaryMatchFlowTitle;

  /// No description provided for @diaryMatchSectionBodyDefault.
  ///
  /// In en, this message translates to:
  /// **'Write the flow that stayed most from the match.'**
  String get diaryMatchSectionBodyDefault;

  /// No description provided for @diaryBoardStickerFallbackSummary.
  ///
  /// In en, this message translates to:
  /// **'Movement and idea captured on this board'**
  String get diaryBoardStickerFallbackSummary;

  /// No description provided for @diaryBoardNotePrefix.
  ///
  /// In en, this message translates to:
  /// **'Board note: {memo}'**
  String diaryBoardNotePrefix(String memo);

  /// No description provided for @diaryBoardTodoTitle.
  ///
  /// In en, this message translates to:
  /// **'Board · {title}'**
  String diaryBoardTodoTitle(String title);

  /// No description provided for @diaryBoardStorySentence.
  ///
  /// In en, this message translates to:
  /// **'Write the movement or idea you want to keep from this board.'**
  String get diaryBoardStorySentence;

  /// No description provided for @diaryBoardFallbackSummary.
  ///
  /// In en, this message translates to:
  /// **'Pull the tactic idea into the diary.'**
  String get diaryBoardFallbackSummary;

  /// No description provided for @diaryBoardNoteTitle.
  ///
  /// In en, this message translates to:
  /// **'{title} note'**
  String diaryBoardNoteTitle(String title);

  /// No description provided for @diaryLiftingStorySentence.
  ///
  /// In en, this message translates to:
  /// **'Write how the lifting rhythm held today\'s ball feel in place.'**
  String get diaryLiftingStorySentence;

  /// No description provided for @diaryLiftingNoteTitle.
  ///
  /// In en, this message translates to:
  /// **'Lifting note'**
  String get diaryLiftingNoteTitle;

  /// No description provided for @diaryLiftingSectionBody.
  ///
  /// In en, this message translates to:
  /// **'Keep the moment the touch settled together with the counts.'**
  String get diaryLiftingSectionBody;

  /// No description provided for @diaryJumpRopeStorySentence.
  ///
  /// In en, this message translates to:
  /// **'Write the moment jump rope woke the body up and changed the breathing rhythm.'**
  String get diaryJumpRopeStorySentence;

  /// No description provided for @diaryJumpRopeNoteTitle.
  ///
  /// In en, this message translates to:
  /// **'Jump rope note'**
  String get diaryJumpRopeNoteTitle;

  /// No description provided for @diaryJumpRopeSectionBody.
  ///
  /// In en, this message translates to:
  /// **'Keep the count, time, and the point where the body started to feel lighter.'**
  String get diaryJumpRopeSectionBody;

  /// No description provided for @diaryWeatherStorySentence.
  ///
  /// In en, this message translates to:
  /// **'Write how the weather affected your training flow and body.'**
  String get diaryWeatherStorySentence;

  /// No description provided for @diaryNewsTodoTitle.
  ///
  /// In en, this message translates to:
  /// **'News · {title}'**
  String diaryNewsTodoTitle(String title);

  /// No description provided for @diaryNewsStorySentence.
  ///
  /// In en, this message translates to:
  /// **'Write one point you want to keep from \"{title}\".'**
  String diaryNewsStorySentence(String title);

  /// No description provided for @diaryTodayNewsTitle.
  ///
  /// In en, this message translates to:
  /// **'Today news'**
  String get diaryTodayNewsTitle;

  /// No description provided for @diaryNewsSectionBody.
  ///
  /// In en, this message translates to:
  /// **'{source} article: {title}'**
  String diaryNewsSectionBody(String source, String title);

  /// No description provided for @quizWrongAnswerTimeout.
  ///
  /// In en, this message translates to:
  /// **'Timed out'**
  String get quizWrongAnswerTimeout;

  /// No description provided for @quizWrongAnswerRevealed.
  ///
  /// In en, this message translates to:
  /// **'Revealed the answer'**
  String get quizWrongAnswerRevealed;

  /// No description provided for @quizWrongAnswerSkipped.
  ///
  /// In en, this message translates to:
  /// **'No answer selected'**
  String get quizWrongAnswerSkipped;

  /// No description provided for @quizWrongAnswerEmpty.
  ///
  /// In en, this message translates to:
  /// **'No input'**
  String get quizWrongAnswerEmpty;

  /// No description provided for @quizShortAnswerHintAction.
  ///
  /// In en, this message translates to:
  /// **'Show hint'**
  String get quizShortAnswerHintAction;

  /// No description provided for @quizRevealAnswerAction.
  ///
  /// In en, this message translates to:
  /// **'Reveal answer'**
  String get quizRevealAnswerAction;

  /// No description provided for @quizShortAnswerHintUnavailable.
  ///
  /// In en, this message translates to:
  /// **'No hint is available yet.'**
  String get quizShortAnswerHintUnavailable;

  /// No description provided for @quizShortAnswerHintStartsWith.
  ///
  /// In en, this message translates to:
  /// **'It starts with \"{first}\" and has {length} letters.'**
  String quizShortAnswerHintStartsWith(Object first, Object length);

  /// No description provided for @quizShortAnswerHintNumber.
  ///
  /// In en, this message translates to:
  /// **'It is a {length}-digit answer starting with {first}.'**
  String quizShortAnswerHintNumber(Object first, Object length);

  /// No description provided for @diaryTrainingSelectedGoalsLabel.
  ///
  /// In en, this message translates to:
  /// **'Selected goals'**
  String get diaryTrainingSelectedGoalsLabel;

  /// No description provided for @diaryTrainingStrongPointLabel.
  ///
  /// In en, this message translates to:
  /// **'What went well'**
  String get diaryTrainingStrongPointLabel;

  /// No description provided for @diaryTrainingNeedsWorkLabel.
  ///
  /// In en, this message translates to:
  /// **'Needs work'**
  String get diaryTrainingNeedsWorkLabel;

  /// No description provided for @diaryTrainingNextGoalLabel.
  ///
  /// In en, this message translates to:
  /// **'Next goal'**
  String get diaryTrainingNextGoalLabel;

  /// No description provided for @diarySelectedRecordStickersTitle.
  ///
  /// In en, this message translates to:
  /// **'Selected record stickers'**
  String get diarySelectedRecordStickersTitle;

  /// No description provided for @diarySelectedRecordStickersHint.
  ///
  /// In en, this message translates to:
  /// **'Drag the handle to reorder, or use remove to take a sticker out.'**
  String get diarySelectedRecordStickersHint;

  /// No description provided for @diaryRecordStickerSectionTitle.
  ///
  /// In en, this message translates to:
  /// **'Record sticker layout'**
  String get diaryRecordStickerSectionTitle;

  /// No description provided for @diaryRecordStickerSectionSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Pick from today\'s records and organize the reading order above.'**
  String get diaryRecordStickerSectionSubtitle;

  /// No description provided for @diaryRecordStickerSourceTitle.
  ///
  /// In en, this message translates to:
  /// **'Pull from today records'**
  String get diaryRecordStickerSourceTitle;

  /// No description provided for @diaryRecordStickerAvailableCount.
  ///
  /// In en, this message translates to:
  /// **'{count} items'**
  String diaryRecordStickerAvailableCount(int count);

  /// No description provided for @diaryRecordStickerSelectedCount.
  ///
  /// In en, this message translates to:
  /// **'{count} selected'**
  String diaryRecordStickerSelectedCount(int count);

  /// No description provided for @diaryRecordStickerSelectedOrder.
  ///
  /// In en, this message translates to:
  /// **'Order {order}'**
  String diaryRecordStickerSelectedOrder(int order);

  /// No description provided for @diaryRecordStickerEmptyHint.
  ///
  /// In en, this message translates to:
  /// **'Pick stickers below and reorder them here right away.'**
  String get diaryRecordStickerEmptyHint;

  /// No description provided for @diaryRecordStickerReorder.
  ///
  /// In en, this message translates to:
  /// **'Reorder sticker'**
  String get diaryRecordStickerReorder;

  /// No description provided for @diaryRecordStickerRemove.
  ///
  /// In en, this message translates to:
  /// **'Remove sticker'**
  String get diaryRecordStickerRemove;

  /// No description provided for @diaryRecordStickerPinned.
  ///
  /// In en, this message translates to:
  /// **'Sticker added'**
  String get diaryRecordStickerPinned;

  /// No description provided for @diaryRecordStickerPin.
  ///
  /// In en, this message translates to:
  /// **'Add sticker'**
  String get diaryRecordStickerPin;

  /// No description provided for @diaryMealStorySentence.
  ///
  /// In en, this message translates to:
  /// **'Look back on what you ate today and note how the meal volume connected to body condition.'**
  String get diaryMealStorySentence;

  /// No description provided for @diaryMealSectionTitle.
  ///
  /// In en, this message translates to:
  /// **'Meal note'**
  String get diaryMealSectionTitle;

  /// No description provided for @diaryMealSectionBody.
  ///
  /// In en, this message translates to:
  /// **'Keep the three meals, rice amount, and body feel in one short note.'**
  String get diaryMealSectionBody;

  /// No description provided for @diaryNewsOpenFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to open the article.'**
  String get diaryNewsOpenFailed;

  /// No description provided for @mealRoutineTitle.
  ///
  /// In en, this message translates to:
  /// **'Eating is training too'**
  String get mealRoutineTitle;

  /// No description provided for @mealRoutineSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Skip calorie math and just log three meals with rice bowl count.'**
  String get mealRoutineSubtitle;

  /// No description provided for @mealBreakfast.
  ///
  /// In en, this message translates to:
  /// **'Breakfast'**
  String get mealBreakfast;

  /// No description provided for @mealLunch.
  ///
  /// In en, this message translates to:
  /// **'Lunch'**
  String get mealLunch;

  /// No description provided for @mealDinner.
  ///
  /// In en, this message translates to:
  /// **'Dinner'**
  String get mealDinner;

  /// No description provided for @mealShortLabel.
  ///
  /// In en, this message translates to:
  /// **'Meals'**
  String get mealShortLabel;

  /// No description provided for @mealDone.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get mealDone;

  /// No description provided for @mealSkipped.
  ///
  /// In en, this message translates to:
  /// **'Skipped'**
  String get mealSkipped;

  /// No description provided for @mealRiceNone.
  ///
  /// In en, this message translates to:
  /// **'0 bowls'**
  String get mealRiceNone;

  /// No description provided for @mealRiceBowls.
  ///
  /// In en, this message translates to:
  /// **'{count} bowl(s)'**
  String mealRiceBowls(int count);

  /// No description provided for @mealRiceLabel.
  ///
  /// In en, this message translates to:
  /// **'Rice'**
  String get mealRiceLabel;

  /// No description provided for @mealCoachHeadlinePerfect.
  ///
  /// In en, this message translates to:
  /// **'Three meals are on track.'**
  String get mealCoachHeadlinePerfect;

  /// No description provided for @mealCoachHeadlineAlmost.
  ///
  /// In en, this message translates to:
  /// **'One more meal finishes the routine.'**
  String get mealCoachHeadlineAlmost;

  /// No description provided for @mealCoachHeadlineNeedsMore.
  ///
  /// In en, this message translates to:
  /// **'The meal routine needs more structure.'**
  String get mealCoachHeadlineNeedsMore;

  /// No description provided for @mealCoachHeadlineStart.
  ///
  /// In en, this message translates to:
  /// **'Treat meals as training today.'**
  String get mealCoachHeadlineStart;

  /// No description provided for @mealCoachBodySteady.
  ///
  /// In en, this message translates to:
  /// **'Meal timing and rice volume look steady. It is a good day to hold tempo in the next session.'**
  String get mealCoachBodySteady;

  /// No description provided for @mealCoachBodyThreeMeals.
  ///
  /// In en, this message translates to:
  /// **'You logged all three meals. Next step is keeping rice portions from swinging too much meal to meal.'**
  String get mealCoachBodyThreeMeals;

  /// No description provided for @mealCoachBodyTwoMealsSolid.
  ///
  /// In en, this message translates to:
  /// **'Two meals are solid. Lock the missing meal to a fixed time to stabilize recovery.'**
  String get mealCoachBodyTwoMealsSolid;

  /// No description provided for @mealCoachBodyTwoMealsLight.
  ///
  /// In en, this message translates to:
  /// **'Two meals are logged, but volume is light. Start by anchoring the next meal at one bowl.'**
  String get mealCoachBodyTwoMealsLight;

  /// No description provided for @mealCoachBodyOneMeal.
  ///
  /// In en, this message translates to:
  /// **'Only one meal is recorded. Add another meal before worrying about training quality today.'**
  String get mealCoachBodyOneMeal;

  /// No description provided for @mealCoachBodyZeroMeal.
  ///
  /// In en, this message translates to:
  /// **'Start by checking off the three meals. Missing fewer meals matters more than detailed math.'**
  String get mealCoachBodyZeroMeal;

  /// No description provided for @mealXpFull.
  ///
  /// In en, this message translates to:
  /// **'3 meals complete +8 XP'**
  String get mealXpFull;

  /// No description provided for @mealXpFullBonus.
  ///
  /// In en, this message translates to:
  /// **'3 meals complete + 5+ rice bowls +10 XP'**
  String get mealXpFullBonus;

  /// No description provided for @mealXpPartial.
  ///
  /// In en, this message translates to:
  /// **'2+ meals +3 XP'**
  String get mealXpPartial;

  /// No description provided for @mealXpNeutral.
  ///
  /// In en, this message translates to:
  /// **'One meal or less gives no bonus'**
  String get mealXpNeutral;

  /// No description provided for @homeMealCoachTitle.
  ///
  /// In en, this message translates to:
  /// **'Meal coach'**
  String get homeMealCoachTitle;

  /// No description provided for @homeMealCoachRecordAction.
  ///
  /// In en, this message translates to:
  /// **'Meals'**
  String get homeMealCoachRecordAction;

  /// No description provided for @homeParentWelcomeMessage.
  ///
  /// In en, this message translates to:
  /// **'Parent mode: review records and feedback only.'**
  String get homeParentWelcomeMessage;

  /// No description provided for @homeParentWelcomeAction.
  ///
  /// In en, this message translates to:
  /// **'Logs'**
  String get homeParentWelcomeAction;

  /// No description provided for @homeMealCoachOtherSuggestions.
  ///
  /// In en, this message translates to:
  /// **'Show other suggestions'**
  String get homeMealCoachOtherSuggestions;

  /// No description provided for @homeMealCoachHeadlinePerfect.
  ///
  /// In en, this message translates to:
  /// **'Complete'**
  String get homeMealCoachHeadlinePerfect;

  /// No description provided for @homeMealCoachHeadlineAlmost.
  ///
  /// In en, this message translates to:
  /// **'Almost there'**
  String get homeMealCoachHeadlineAlmost;

  /// No description provided for @homeMealCoachHeadlineNeedsMore.
  ///
  /// In en, this message translates to:
  /// **'Needs work'**
  String get homeMealCoachHeadlineNeedsMore;

  /// No description provided for @homeMealCoachHeadlineStart.
  ///
  /// In en, this message translates to:
  /// **'Not started'**
  String get homeMealCoachHeadlineStart;

  /// No description provided for @homeMealCoachNoEntry.
  ///
  /// In en, this message translates to:
  /// **'There is no training note for today yet. Start by logging the meals you ate.'**
  String get homeMealCoachNoEntry;

  /// No description provided for @homeMealCoachSummary.
  ///
  /// In en, this message translates to:
  /// **'{breakfastLabel} {breakfastValue} · {lunchLabel} {lunchValue} · {dinnerLabel} {dinnerValue}'**
  String homeMealCoachSummary(
      String breakfastLabel,
      String breakfastValue,
      String lunchLabel,
      String lunchValue,
      String dinnerLabel,
      String dinnerValue);

  /// No description provided for @homeMealCoachSuggestionStart1.
  ///
  /// In en, this message translates to:
  /// **'Stabilize the one meal you skip most often first.'**
  String get homeMealCoachSuggestionStart1;

  /// No description provided for @homeMealCoachSuggestionStart2.
  ///
  /// In en, this message translates to:
  /// **'When you start logging, meal count matters more than calories.'**
  String get homeMealCoachSuggestionStart2;

  /// No description provided for @homeMealCoachSuggestionStart3.
  ///
  /// In en, this message translates to:
  /// **'Log the first meal today, then repeat that time tomorrow.'**
  String get homeMealCoachSuggestionStart3;

  /// No description provided for @homeMealCoachSuggestionOne1.
  ///
  /// In en, this message translates to:
  /// **'Only one meal is logged. Fix the next meal to a clear time so it is not missed.'**
  String get homeMealCoachSuggestionOne1;

  /// No description provided for @homeMealCoachSuggestionOne2.
  ///
  /// In en, this message translates to:
  /// **'If you ate, add the rice volume too. The next coaching step gets much easier.'**
  String get homeMealCoachSuggestionOne2;

  /// No description provided for @homeMealCoachSuggestionOne3.
  ///
  /// In en, this message translates to:
  /// **'Today, adding meals matters more than finishing quiz or diary.'**
  String get homeMealCoachSuggestionOne3;

  /// No description provided for @homeMealCoachSuggestionTwoLight1.
  ///
  /// In en, this message translates to:
  /// **'Two meals are logged, but the volume is light. Aim for at least one full bowl in the next meal.'**
  String get homeMealCoachSuggestionTwoLight1;

  /// No description provided for @homeMealCoachSuggestionTwoLight2.
  ///
  /// In en, this message translates to:
  /// **'Do not replace the missing meal with random snacks. Keep it as a real meal slot.'**
  String get homeMealCoachSuggestionTwoLight2;

  /// No description provided for @homeMealCoachSuggestionTwoLight3.
  ///
  /// In en, this message translates to:
  /// **'Meal count is acceptable. Now build a repeatable rice benchmark too.'**
  String get homeMealCoachSuggestionTwoLight3;

  /// No description provided for @homeMealCoachSuggestionTwoSolid1.
  ///
  /// In en, this message translates to:
  /// **'The two-meal rhythm is good. Fix the missing meal in the same time window each day.'**
  String get homeMealCoachSuggestionTwoSolid1;

  /// No description provided for @homeMealCoachSuggestionTwoSolid2.
  ///
  /// In en, this message translates to:
  /// **'Since the meal rhythm was decent today, also note how your body felt after training.'**
  String get homeMealCoachSuggestionTwoSolid2;

  /// No description provided for @homeMealCoachSuggestionTwoSolid3.
  ///
  /// In en, this message translates to:
  /// **'If two meals are stable, the third is mostly a scheduling problem.'**
  String get homeMealCoachSuggestionTwoSolid3;

  /// No description provided for @homeMealCoachSuggestionThree1.
  ///
  /// In en, this message translates to:
  /// **'You logged all three meals. Next, reduce the portion gap across meals.'**
  String get homeMealCoachSuggestionThree1;

  /// No description provided for @homeMealCoachSuggestionThree2.
  ///
  /// In en, this message translates to:
  /// **'On a full three-meal day, pair it with diary to finish the recovery routine.'**
  String get homeMealCoachSuggestionThree2;

  /// No description provided for @homeMealCoachSuggestionThree3.
  ///
  /// In en, this message translates to:
  /// **'The rhythm is steady, so also track how light or heavy your movement felt.'**
  String get homeMealCoachSuggestionThree3;

  /// No description provided for @homeMealCoachSuggestionSteady1.
  ///
  /// In en, this message translates to:
  /// **'Meal timing and volume were stable. You can focus on holding training tempo next.'**
  String get homeMealCoachSuggestionSteady1;

  /// No description provided for @homeMealCoachSuggestionSteady2.
  ///
  /// In en, this message translates to:
  /// **'Energy refill looked good today. Add a short note about how your body responded.'**
  String get homeMealCoachSuggestionSteady2;

  /// No description provided for @homeMealCoachSuggestionSteady3.
  ///
  /// In en, this message translates to:
  /// **'Now that meals are stable, the next suggestion is linking sleep and diary review.'**
  String get homeMealCoachSuggestionSteady3;

  /// No description provided for @mealCompactSummary.
  ///
  /// In en, this message translates to:
  /// **'{label} {count} bowl(s)'**
  String mealCompactSummary(String label, int count);

  /// No description provided for @mealCompactSkipped.
  ///
  /// In en, this message translates to:
  /// **'{label} skipped'**
  String mealCompactSkipped(String label);

  /// No description provided for @mealRiceBowlsValue.
  ///
  /// In en, this message translates to:
  /// **'{count} bowl(s)'**
  String mealRiceBowlsValue(String count);

  /// No description provided for @mealLogScreenTitle.
  ///
  /// In en, this message translates to:
  /// **'Meal log'**
  String get mealLogScreenTitle;

  /// No description provided for @mealLogDateLabel.
  ///
  /// In en, this message translates to:
  /// **'Log date'**
  String get mealLogDateLabel;

  /// No description provided for @mealLogDatePickerHelp.
  ///
  /// In en, this message translates to:
  /// **'Select meal log date'**
  String get mealLogDatePickerHelp;

  /// No description provided for @mealMenuInputLabel.
  ///
  /// In en, this message translates to:
  /// **'Additional note'**
  String get mealMenuInputLabel;

  /// No description provided for @mealMenuInputHint.
  ///
  /// In en, this message translates to:
  /// **'Add foods not on the list or notes for {label}'**
  String mealMenuInputHint(String label);

  /// No description provided for @mealMainDishLabel.
  ///
  /// In en, this message translates to:
  /// **'Main dish'**
  String get mealMainDishLabel;

  /// No description provided for @mealMainDishNone.
  ///
  /// In en, this message translates to:
  /// **'No main dish'**
  String get mealMainDishNone;

  /// No description provided for @mealMainDishChooseAction.
  ///
  /// In en, this message translates to:
  /// **'Choose main'**
  String get mealMainDishChooseAction;

  /// No description provided for @mealMainDishEditAction.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get mealMainDishEditAction;

  /// No description provided for @mealMainDishSheetTitle.
  ///
  /// In en, this message translates to:
  /// **'Search main dish'**
  String get mealMainDishSheetTitle;

  /// No description provided for @mealMainDishClearAction.
  ///
  /// In en, this message translates to:
  /// **'No main dish'**
  String get mealMainDishClearAction;

  /// No description provided for @mealDishPortionSmall.
  ///
  /// In en, this message translates to:
  /// **'Light'**
  String get mealDishPortionSmall;

  /// No description provided for @mealDishPortionRegular.
  ///
  /// In en, this message translates to:
  /// **'Regular'**
  String get mealDishPortionRegular;

  /// No description provided for @mealDishPortionLarge.
  ///
  /// In en, this message translates to:
  /// **'Large'**
  String get mealDishPortionLarge;

  /// No description provided for @mealDishNutritionPreview.
  ///
  /// In en, this message translates to:
  /// **'About {kcal} kcal · protein {protein}g'**
  String mealDishNutritionPreview(int kcal, int protein);

  /// No description provided for @mealCompanionFoodsLabel.
  ///
  /// In en, this message translates to:
  /// **'Foods eaten together'**
  String get mealCompanionFoodsLabel;

  /// No description provided for @mealCompanionFoodsEmpty.
  ///
  /// In en, this message translates to:
  /// **'No extra foods selected'**
  String get mealCompanionFoodsEmpty;

  /// No description provided for @mealCompanionFoodsChooseAction.
  ///
  /// In en, this message translates to:
  /// **'Choose foods'**
  String get mealCompanionFoodsChooseAction;

  /// No description provided for @mealCompanionFoodsEditAction.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get mealCompanionFoodsEditAction;

  /// No description provided for @mealCompanionFoodsSheetTitle.
  ///
  /// In en, this message translates to:
  /// **'Choose foods eaten together'**
  String get mealCompanionFoodsSheetTitle;

  /// No description provided for @mealFoodSearchLabel.
  ///
  /// In en, this message translates to:
  /// **'Search foods'**
  String get mealFoodSearchLabel;

  /// No description provided for @mealFoodSearchHint.
  ///
  /// In en, this message translates to:
  /// **'Kimchi, milk, banana, and more'**
  String get mealFoodSearchHint;

  /// No description provided for @mealFoodSelectionClear.
  ///
  /// In en, this message translates to:
  /// **'Clear all'**
  String get mealFoodSelectionClear;

  /// No description provided for @mealFoodSelectionDone.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get mealFoodSelectionDone;

  /// No description provided for @mealFoodNutritionLine.
  ///
  /// In en, this message translates to:
  /// **'{kcal} kcal · carbs {carbs}g · protein {protein}g · fat {fat}g'**
  String mealFoodNutritionLine(int kcal, int carbs, int protein, int fat);

  /// No description provided for @mealFoodOptionSubtitle.
  ///
  /// In en, this message translates to:
  /// **'{category} · {nutrition}'**
  String mealFoodOptionSubtitle(String category, String nutrition);

  /// No description provided for @mealSelectedFoodsNutritionPreview.
  ///
  /// In en, this message translates to:
  /// **'Extra foods about {kcal} kcal · protein {protein}g'**
  String mealSelectedFoodsNutritionPreview(int kcal, int protein);

  /// No description provided for @mealFoodCategoryMain.
  ///
  /// In en, this message translates to:
  /// **'Main'**
  String get mealFoodCategoryMain;

  /// No description provided for @mealFoodCategoryProtein.
  ///
  /// In en, this message translates to:
  /// **'Protein'**
  String get mealFoodCategoryProtein;

  /// No description provided for @mealFoodCategorySide.
  ///
  /// In en, this message translates to:
  /// **'Side'**
  String get mealFoodCategorySide;

  /// No description provided for @mealFoodCategorySoup.
  ///
  /// In en, this message translates to:
  /// **'Soup'**
  String get mealFoodCategorySoup;

  /// No description provided for @mealFoodCategoryCarb.
  ///
  /// In en, this message translates to:
  /// **'Carbs'**
  String get mealFoodCategoryCarb;

  /// No description provided for @mealFoodCategoryFruit.
  ///
  /// In en, this message translates to:
  /// **'Fruit'**
  String get mealFoodCategoryFruit;

  /// No description provided for @mealFoodCategorySnack.
  ///
  /// In en, this message translates to:
  /// **'Snack'**
  String get mealFoodCategorySnack;

  /// No description provided for @mealFoodCategoryDrink.
  ///
  /// In en, this message translates to:
  /// **'Drink'**
  String get mealFoodCategoryDrink;

  /// No description provided for @mealDishChickenBreast.
  ///
  /// In en, this message translates to:
  /// **'Chicken breast'**
  String get mealDishChickenBreast;

  /// No description provided for @mealDishEggs.
  ///
  /// In en, this message translates to:
  /// **'Eggs'**
  String get mealDishEggs;

  /// No description provided for @mealDishTofu.
  ///
  /// In en, this message translates to:
  /// **'Tofu'**
  String get mealDishTofu;

  /// No description provided for @mealDishGrilledFish.
  ///
  /// In en, this message translates to:
  /// **'Grilled fish'**
  String get mealDishGrilledFish;

  /// No description provided for @mealDishSalmon.
  ///
  /// In en, this message translates to:
  /// **'Salmon'**
  String get mealDishSalmon;

  /// No description provided for @mealDishBulgogi.
  ///
  /// In en, this message translates to:
  /// **'Bulgogi'**
  String get mealDishBulgogi;

  /// No description provided for @mealDishKimchiStew.
  ///
  /// In en, this message translates to:
  /// **'Kimchi stew'**
  String get mealDishKimchiStew;

  /// No description provided for @mealDishDoenjangStew.
  ///
  /// In en, this message translates to:
  /// **'Doenjang stew'**
  String get mealDishDoenjangStew;

  /// No description provided for @mealDishFriedChicken.
  ///
  /// In en, this message translates to:
  /// **'Fried chicken'**
  String get mealDishFriedChicken;

  /// No description provided for @mealDishChickenSalad.
  ///
  /// In en, this message translates to:
  /// **'Chicken salad'**
  String get mealDishChickenSalad;

  /// No description provided for @mealDishRamen.
  ///
  /// In en, this message translates to:
  /// **'Ramen'**
  String get mealDishRamen;

  /// No description provided for @mealDishSandwich.
  ///
  /// In en, this message translates to:
  /// **'Sandwich'**
  String get mealDishSandwich;

  /// No description provided for @mealFoodBibimbap.
  ///
  /// In en, this message translates to:
  /// **'Bibimbap'**
  String get mealFoodBibimbap;

  /// No description provided for @mealFoodFriedRice.
  ///
  /// In en, this message translates to:
  /// **'Fried rice'**
  String get mealFoodFriedRice;

  /// No description provided for @mealFoodGimbap.
  ///
  /// In en, this message translates to:
  /// **'Gimbap'**
  String get mealFoodGimbap;

  /// No description provided for @mealFoodCurryRice.
  ///
  /// In en, this message translates to:
  /// **'Curry rice'**
  String get mealFoodCurryRice;

  /// No description provided for @mealFoodPorkCutlet.
  ///
  /// In en, this message translates to:
  /// **'Pork cutlet'**
  String get mealFoodPorkCutlet;

  /// No description provided for @mealFoodJajangmyeon.
  ///
  /// In en, this message translates to:
  /// **'Jajangmyeon'**
  String get mealFoodJajangmyeon;

  /// No description provided for @mealFoodJjampong.
  ///
  /// In en, this message translates to:
  /// **'Jjamppong'**
  String get mealFoodJjampong;

  /// No description provided for @mealFoodTteokbokki.
  ///
  /// In en, this message translates to:
  /// **'Tteokbokki'**
  String get mealFoodTteokbokki;

  /// No description provided for @mealFoodPasta.
  ///
  /// In en, this message translates to:
  /// **'Pasta'**
  String get mealFoodPasta;

  /// No description provided for @mealFoodHamburger.
  ///
  /// In en, this message translates to:
  /// **'Hamburger'**
  String get mealFoodHamburger;

  /// No description provided for @mealFoodPizza.
  ///
  /// In en, this message translates to:
  /// **'Pizza'**
  String get mealFoodPizza;

  /// No description provided for @mealFoodPorkBelly.
  ///
  /// In en, this message translates to:
  /// **'Pork belly'**
  String get mealFoodPorkBelly;

  /// No description provided for @mealFoodJeyukBokkeum.
  ///
  /// In en, this message translates to:
  /// **'Spicy pork stir-fry'**
  String get mealFoodJeyukBokkeum;

  /// No description provided for @mealFoodBeefSteak.
  ///
  /// In en, this message translates to:
  /// **'Beef steak'**
  String get mealFoodBeefSteak;

  /// No description provided for @mealFoodDakgalbi.
  ///
  /// In en, this message translates to:
  /// **'Dakgalbi'**
  String get mealFoodDakgalbi;

  /// No description provided for @mealFoodOmurice.
  ///
  /// In en, this message translates to:
  /// **'Omurice'**
  String get mealFoodOmurice;

  /// No description provided for @mealFoodUdon.
  ///
  /// In en, this message translates to:
  /// **'Udon'**
  String get mealFoodUdon;

  /// No description provided for @mealFoodColdNoodles.
  ///
  /// In en, this message translates to:
  /// **'Cold noodles'**
  String get mealFoodColdNoodles;

  /// No description provided for @mealFoodSoybeanNoodles.
  ///
  /// In en, this message translates to:
  /// **'Soybean noodles'**
  String get mealFoodSoybeanNoodles;

  /// No description provided for @mealFoodDumplingSoup.
  ///
  /// In en, this message translates to:
  /// **'Dumpling soup'**
  String get mealFoodDumplingSoup;

  /// No description provided for @mealFoodSamgyetang.
  ///
  /// In en, this message translates to:
  /// **'Samgyetang'**
  String get mealFoodSamgyetang;

  /// No description provided for @mealFoodKimchiFriedRice.
  ///
  /// In en, this message translates to:
  /// **'Kimchi fried rice'**
  String get mealFoodKimchiFriedRice;

  /// No description provided for @mealFoodBudaeJjigae.
  ///
  /// In en, this message translates to:
  /// **'Budae jjigae'**
  String get mealFoodBudaeJjigae;

  /// No description provided for @mealFoodSundubuJjigae.
  ///
  /// In en, this message translates to:
  /// **'Sundubu jjigae'**
  String get mealFoodSundubuJjigae;

  /// No description provided for @mealFoodGalbitang.
  ///
  /// In en, this message translates to:
  /// **'Galbitang'**
  String get mealFoodGalbitang;

  /// No description provided for @mealFoodSeolleongtang.
  ///
  /// In en, this message translates to:
  /// **'Seolleongtang'**
  String get mealFoodSeolleongtang;

  /// No description provided for @mealFoodYukgaejang.
  ///
  /// In en, this message translates to:
  /// **'Yukgaejang'**
  String get mealFoodYukgaejang;

  /// No description provided for @mealFoodGamjatang.
  ///
  /// In en, this message translates to:
  /// **'Gamjatang'**
  String get mealFoodGamjatang;

  /// No description provided for @mealFoodKalguksu.
  ///
  /// In en, this message translates to:
  /// **'Kalguksu'**
  String get mealFoodKalguksu;

  /// No description provided for @mealFoodSujebi.
  ///
  /// In en, this message translates to:
  /// **'Sujebi'**
  String get mealFoodSujebi;

  /// No description provided for @mealFoodBibimNoodles.
  ///
  /// In en, this message translates to:
  /// **'Bibim noodles'**
  String get mealFoodBibimNoodles;

  /// No description provided for @mealFoodJapchae.
  ///
  /// In en, this message translates to:
  /// **'Japchae'**
  String get mealFoodJapchae;

  /// No description provided for @mealFoodBossam.
  ///
  /// In en, this message translates to:
  /// **'Bossam'**
  String get mealFoodBossam;

  /// No description provided for @mealFoodJokbal.
  ///
  /// In en, this message translates to:
  /// **'Jokbal'**
  String get mealFoodJokbal;

  /// No description provided for @mealFoodGalbiJjim.
  ///
  /// In en, this message translates to:
  /// **'Galbi jjim'**
  String get mealFoodGalbiJjim;

  /// No description provided for @mealFoodDakdoritang.
  ///
  /// In en, this message translates to:
  /// **'Spicy braised chicken'**
  String get mealFoodDakdoritang;

  /// No description provided for @mealFoodHaejangguk.
  ///
  /// In en, this message translates to:
  /// **'Haejangguk'**
  String get mealFoodHaejangguk;

  /// No description provided for @mealFoodGukbap.
  ///
  /// In en, this message translates to:
  /// **'Gukbap'**
  String get mealFoodGukbap;

  /// No description provided for @mealFoodSoondaeGuk.
  ///
  /// In en, this message translates to:
  /// **'Soondae guk'**
  String get mealFoodSoondaeGuk;

  /// No description provided for @mealFoodTteokguk.
  ///
  /// In en, this message translates to:
  /// **'Tteokguk'**
  String get mealFoodTteokguk;

  /// No description provided for @mealFoodJanchiGuksu.
  ///
  /// In en, this message translates to:
  /// **'Janchi guksu'**
  String get mealFoodJanchiGuksu;

  /// No description provided for @mealFoodMakguksu.
  ///
  /// In en, this message translates to:
  /// **'Makguksu'**
  String get mealFoodMakguksu;

  /// No description provided for @mealFoodKimchiPancake.
  ///
  /// In en, this message translates to:
  /// **'Kimchi pancake'**
  String get mealFoodKimchiPancake;

  /// No description provided for @mealFoodSeafoodPancake.
  ///
  /// In en, this message translates to:
  /// **'Seafood pancake'**
  String get mealFoodSeafoodPancake;

  /// No description provided for @mealFoodBindaetteok.
  ///
  /// In en, this message translates to:
  /// **'Mung bean pancake'**
  String get mealFoodBindaetteok;

  /// No description provided for @mealFoodSundae.
  ///
  /// In en, this message translates to:
  /// **'Korean blood sausage'**
  String get mealFoodSundae;

  /// No description provided for @mealFoodOdengSoup.
  ///
  /// In en, this message translates to:
  /// **'Fish cake soup'**
  String get mealFoodOdengSoup;

  /// No description provided for @mealFoodSpaghetti.
  ///
  /// In en, this message translates to:
  /// **'Spaghetti'**
  String get mealFoodSpaghetti;

  /// No description provided for @mealFoodLasagna.
  ///
  /// In en, this message translates to:
  /// **'Lasagna'**
  String get mealFoodLasagna;

  /// No description provided for @mealFoodRisotto.
  ///
  /// In en, this message translates to:
  /// **'Risotto'**
  String get mealFoodRisotto;

  /// No description provided for @mealFoodPaella.
  ///
  /// In en, this message translates to:
  /// **'Paella'**
  String get mealFoodPaella;

  /// No description provided for @mealFoodTacos.
  ///
  /// In en, this message translates to:
  /// **'Tacos'**
  String get mealFoodTacos;

  /// No description provided for @mealFoodBurrito.
  ///
  /// In en, this message translates to:
  /// **'Burrito'**
  String get mealFoodBurrito;

  /// No description provided for @mealFoodQuesadilla.
  ///
  /// In en, this message translates to:
  /// **'Quesadilla'**
  String get mealFoodQuesadilla;

  /// No description provided for @mealFoodNachos.
  ///
  /// In en, this message translates to:
  /// **'Nachos'**
  String get mealFoodNachos;

  /// No description provided for @mealFoodSushi.
  ///
  /// In en, this message translates to:
  /// **'Sushi'**
  String get mealFoodSushi;

  /// No description provided for @mealFoodSashimi.
  ///
  /// In en, this message translates to:
  /// **'Sashimi'**
  String get mealFoodSashimi;

  /// No description provided for @mealFoodTempuraDon.
  ///
  /// In en, this message translates to:
  /// **'Tempura don'**
  String get mealFoodTempuraDon;

  /// No description provided for @mealFoodGyudon.
  ///
  /// In en, this message translates to:
  /// **'Gyudon'**
  String get mealFoodGyudon;

  /// No description provided for @mealFoodKatsudon.
  ///
  /// In en, this message translates to:
  /// **'Katsudon'**
  String get mealFoodKatsudon;

  /// No description provided for @mealFoodYakisoba.
  ///
  /// In en, this message translates to:
  /// **'Yakisoba'**
  String get mealFoodYakisoba;

  /// No description provided for @mealFoodOkonomiyaki.
  ///
  /// In en, this message translates to:
  /// **'Okonomiyaki'**
  String get mealFoodOkonomiyaki;

  /// No description provided for @mealFoodTakoyaki.
  ///
  /// In en, this message translates to:
  /// **'Takoyaki'**
  String get mealFoodTakoyaki;

  /// No description provided for @mealFoodPho.
  ///
  /// In en, this message translates to:
  /// **'Pho'**
  String get mealFoodPho;

  /// No description provided for @mealFoodBanhMi.
  ///
  /// In en, this message translates to:
  /// **'Banh mi'**
  String get mealFoodBanhMi;

  /// No description provided for @mealFoodPadThai.
  ///
  /// In en, this message translates to:
  /// **'Pad thai'**
  String get mealFoodPadThai;

  /// No description provided for @mealFoodTomYumSoup.
  ///
  /// In en, this message translates to:
  /// **'Tom yum soup'**
  String get mealFoodTomYumSoup;

  /// No description provided for @mealFoodGreenCurry.
  ///
  /// In en, this message translates to:
  /// **'Green curry'**
  String get mealFoodGreenCurry;

  /// No description provided for @mealFoodMassamanCurry.
  ///
  /// In en, this message translates to:
  /// **'Massaman curry'**
  String get mealFoodMassamanCurry;

  /// No description provided for @mealFoodNasiGoreng.
  ///
  /// In en, this message translates to:
  /// **'Nasi goreng'**
  String get mealFoodNasiGoreng;

  /// No description provided for @mealFoodSatay.
  ///
  /// In en, this message translates to:
  /// **'Satay'**
  String get mealFoodSatay;

  /// No description provided for @mealFoodLaksa.
  ///
  /// In en, this message translates to:
  /// **'Laksa'**
  String get mealFoodLaksa;

  /// No description provided for @mealFoodButterChicken.
  ///
  /// In en, this message translates to:
  /// **'Butter chicken'**
  String get mealFoodButterChicken;

  /// No description provided for @mealFoodChickenTikkaMasala.
  ///
  /// In en, this message translates to:
  /// **'Chicken tikka masala'**
  String get mealFoodChickenTikkaMasala;

  /// No description provided for @mealFoodBiryani.
  ///
  /// In en, this message translates to:
  /// **'Biryani'**
  String get mealFoodBiryani;

  /// No description provided for @mealFoodNaan.
  ///
  /// In en, this message translates to:
  /// **'Naan'**
  String get mealFoodNaan;

  /// No description provided for @mealFoodDal.
  ///
  /// In en, this message translates to:
  /// **'Dal'**
  String get mealFoodDal;

  /// No description provided for @mealFoodKebab.
  ///
  /// In en, this message translates to:
  /// **'Kebab'**
  String get mealFoodKebab;

  /// No description provided for @mealFoodShawarma.
  ///
  /// In en, this message translates to:
  /// **'Shawarma'**
  String get mealFoodShawarma;

  /// No description provided for @mealFoodFalafel.
  ///
  /// In en, this message translates to:
  /// **'Falafel'**
  String get mealFoodFalafel;

  /// No description provided for @mealFoodHummus.
  ///
  /// In en, this message translates to:
  /// **'Hummus'**
  String get mealFoodHummus;

  /// No description provided for @mealFoodShakshuka.
  ///
  /// In en, this message translates to:
  /// **'Shakshuka'**
  String get mealFoodShakshuka;

  /// No description provided for @mealFoodFishAndChips.
  ///
  /// In en, this message translates to:
  /// **'Fish and chips'**
  String get mealFoodFishAndChips;

  /// No description provided for @mealFoodRoastChicken.
  ///
  /// In en, this message translates to:
  /// **'Roast chicken'**
  String get mealFoodRoastChicken;

  /// No description provided for @mealFoodMeatballs.
  ///
  /// In en, this message translates to:
  /// **'Meatballs'**
  String get mealFoodMeatballs;

  /// No description provided for @mealFoodMacAndCheese.
  ///
  /// In en, this message translates to:
  /// **'Mac and cheese'**
  String get mealFoodMacAndCheese;

  /// No description provided for @mealFoodHotDog.
  ///
  /// In en, this message translates to:
  /// **'Hot dog'**
  String get mealFoodHotDog;

  /// No description provided for @mealFoodBurritoBowl.
  ///
  /// In en, this message translates to:
  /// **'Burrito bowl'**
  String get mealFoodBurritoBowl;

  /// No description provided for @mealFoodChowMein.
  ///
  /// In en, this message translates to:
  /// **'Chow mein'**
  String get mealFoodChowMein;

  /// No description provided for @mealFoodMapoTofu.
  ///
  /// In en, this message translates to:
  /// **'Mapo tofu'**
  String get mealFoodMapoTofu;

  /// No description provided for @mealFoodKungPaoChicken.
  ///
  /// In en, this message translates to:
  /// **'Kung pao chicken'**
  String get mealFoodKungPaoChicken;

  /// No description provided for @mealFoodDimSum.
  ///
  /// In en, this message translates to:
  /// **'Dim sum'**
  String get mealFoodDimSum;

  /// No description provided for @mealFoodSpringRoll.
  ///
  /// In en, this message translates to:
  /// **'Spring roll'**
  String get mealFoodSpringRoll;

  /// No description provided for @mealFoodFriedNoodles.
  ///
  /// In en, this message translates to:
  /// **'Fried noodles'**
  String get mealFoodFriedNoodles;

  /// No description provided for @mealFoodCongee.
  ///
  /// In en, this message translates to:
  /// **'Congee'**
  String get mealFoodCongee;

  /// No description provided for @mealFoodWontonSoup.
  ///
  /// In en, this message translates to:
  /// **'Wonton soup'**
  String get mealFoodWontonSoup;

  /// No description provided for @mealFoodPokeBowl.
  ///
  /// In en, this message translates to:
  /// **'Poke bowl'**
  String get mealFoodPokeBowl;

  /// No description provided for @mealFoodCaesarSalad.
  ///
  /// In en, this message translates to:
  /// **'Caesar salad'**
  String get mealFoodCaesarSalad;

  /// No description provided for @mealFoodGreekSalad.
  ///
  /// In en, this message translates to:
  /// **'Greek salad'**
  String get mealFoodGreekSalad;

  /// No description provided for @mealFoodClamChowder.
  ///
  /// In en, this message translates to:
  /// **'Clam chowder'**
  String get mealFoodClamChowder;

  /// No description provided for @mealFoodKimchi.
  ///
  /// In en, this message translates to:
  /// **'Kimchi'**
  String get mealFoodKimchi;

  /// No description provided for @mealFoodPickledRadish.
  ///
  /// In en, this message translates to:
  /// **'Pickled radish'**
  String get mealFoodPickledRadish;

  /// No description provided for @mealFoodSeasonedBeanSprouts.
  ///
  /// In en, this message translates to:
  /// **'Seasoned bean sprouts'**
  String get mealFoodSeasonedBeanSprouts;

  /// No description provided for @mealFoodSpinachNamul.
  ///
  /// In en, this message translates to:
  /// **'Spinach namul'**
  String get mealFoodSpinachNamul;

  /// No description provided for @mealFoodSeaweedSalad.
  ///
  /// In en, this message translates to:
  /// **'Seaweed salad'**
  String get mealFoodSeaweedSalad;

  /// No description provided for @mealFoodLettuce.
  ///
  /// In en, this message translates to:
  /// **'Lettuce'**
  String get mealFoodLettuce;

  /// No description provided for @mealFoodCucumber.
  ///
  /// In en, this message translates to:
  /// **'Cucumber'**
  String get mealFoodCucumber;

  /// No description provided for @mealFoodTomato.
  ///
  /// In en, this message translates to:
  /// **'Tomato'**
  String get mealFoodTomato;

  /// No description provided for @mealFoodAvocado.
  ///
  /// In en, this message translates to:
  /// **'Avocado'**
  String get mealFoodAvocado;

  /// No description provided for @mealFoodBroccoli.
  ///
  /// In en, this message translates to:
  /// **'Broccoli'**
  String get mealFoodBroccoli;

  /// No description provided for @mealFoodSweetPotato.
  ///
  /// In en, this message translates to:
  /// **'Sweet potato'**
  String get mealFoodSweetPotato;

  /// No description provided for @mealFoodPotato.
  ///
  /// In en, this message translates to:
  /// **'Potato'**
  String get mealFoodPotato;

  /// No description provided for @mealFoodCorn.
  ///
  /// In en, this message translates to:
  /// **'Corn'**
  String get mealFoodCorn;

  /// No description provided for @mealFoodBoiledEgg.
  ///
  /// In en, this message translates to:
  /// **'Boiled egg'**
  String get mealFoodBoiledEgg;

  /// No description provided for @mealFoodFriedEgg.
  ///
  /// In en, this message translates to:
  /// **'Fried egg'**
  String get mealFoodFriedEgg;

  /// No description provided for @mealFoodOmelet.
  ///
  /// In en, this message translates to:
  /// **'Omelet'**
  String get mealFoodOmelet;

  /// No description provided for @mealFoodCheese.
  ///
  /// In en, this message translates to:
  /// **'Cheese'**
  String get mealFoodCheese;

  /// No description provided for @mealFoodTunaCan.
  ///
  /// In en, this message translates to:
  /// **'Canned tuna'**
  String get mealFoodTunaCan;

  /// No description provided for @mealFoodHam.
  ///
  /// In en, this message translates to:
  /// **'Ham'**
  String get mealFoodHam;

  /// No description provided for @mealFoodSausage.
  ///
  /// In en, this message translates to:
  /// **'Sausage'**
  String get mealFoodSausage;

  /// No description provided for @mealFoodBacon.
  ///
  /// In en, this message translates to:
  /// **'Bacon'**
  String get mealFoodBacon;

  /// No description provided for @mealFoodMackerel.
  ///
  /// In en, this message translates to:
  /// **'Mackerel'**
  String get mealFoodMackerel;

  /// No description provided for @mealFoodShrimp.
  ///
  /// In en, this message translates to:
  /// **'Shrimp'**
  String get mealFoodShrimp;

  /// No description provided for @mealFoodSquid.
  ///
  /// In en, this message translates to:
  /// **'Squid'**
  String get mealFoodSquid;

  /// No description provided for @mealFoodBeans.
  ///
  /// In en, this message translates to:
  /// **'Beans'**
  String get mealFoodBeans;

  /// No description provided for @mealFoodChickpeas.
  ///
  /// In en, this message translates to:
  /// **'Chickpeas'**
  String get mealFoodChickpeas;

  /// No description provided for @mealFoodLentils.
  ///
  /// In en, this message translates to:
  /// **'Lentils'**
  String get mealFoodLentils;

  /// No description provided for @mealFoodSeaweedSoup.
  ///
  /// In en, this message translates to:
  /// **'Seaweed soup'**
  String get mealFoodSeaweedSoup;

  /// No description provided for @mealFoodBeefSoup.
  ///
  /// In en, this message translates to:
  /// **'Beef soup'**
  String get mealFoodBeefSoup;

  /// No description provided for @mealFoodEggSoup.
  ///
  /// In en, this message translates to:
  /// **'Egg soup'**
  String get mealFoodEggSoup;

  /// No description provided for @mealFoodTofuSoup.
  ///
  /// In en, this message translates to:
  /// **'Soft tofu soup'**
  String get mealFoodTofuSoup;

  /// No description provided for @mealFoodVegetableSoup.
  ///
  /// In en, this message translates to:
  /// **'Vegetable soup'**
  String get mealFoodVegetableSoup;

  /// No description provided for @mealFoodMisoSoup.
  ///
  /// In en, this message translates to:
  /// **'Miso soup'**
  String get mealFoodMisoSoup;

  /// No description provided for @mealFoodChickenSoup.
  ///
  /// In en, this message translates to:
  /// **'Chicken soup'**
  String get mealFoodChickenSoup;

  /// No description provided for @mealFoodDumplings.
  ///
  /// In en, this message translates to:
  /// **'Dumplings'**
  String get mealFoodDumplings;

  /// No description provided for @mealFoodFriedSnack.
  ///
  /// In en, this message translates to:
  /// **'Fried snack'**
  String get mealFoodFriedSnack;

  /// No description provided for @mealFoodFrenchFries.
  ///
  /// In en, this message translates to:
  /// **'French fries'**
  String get mealFoodFrenchFries;

  /// No description provided for @mealFoodRiceCake.
  ///
  /// In en, this message translates to:
  /// **'Rice cake'**
  String get mealFoodRiceCake;

  /// No description provided for @mealFoodBreadSlice.
  ///
  /// In en, this message translates to:
  /// **'Bread slice'**
  String get mealFoodBreadSlice;

  /// No description provided for @mealFoodToast.
  ///
  /// In en, this message translates to:
  /// **'Toast'**
  String get mealFoodToast;

  /// No description provided for @mealFoodOatmeal.
  ///
  /// In en, this message translates to:
  /// **'Oatmeal'**
  String get mealFoodOatmeal;

  /// No description provided for @mealFoodCereal.
  ///
  /// In en, this message translates to:
  /// **'Cereal'**
  String get mealFoodCereal;

  /// No description provided for @mealFoodGranola.
  ///
  /// In en, this message translates to:
  /// **'Granola'**
  String get mealFoodGranola;

  /// No description provided for @mealFoodMixedNuts.
  ///
  /// In en, this message translates to:
  /// **'Mixed nuts'**
  String get mealFoodMixedNuts;

  /// No description provided for @mealFoodAlmonds.
  ///
  /// In en, this message translates to:
  /// **'Almonds'**
  String get mealFoodAlmonds;

  /// No description provided for @mealFoodIceCream.
  ///
  /// In en, this message translates to:
  /// **'Ice cream'**
  String get mealFoodIceCream;

  /// No description provided for @mealFoodChocolate.
  ///
  /// In en, this message translates to:
  /// **'Chocolate'**
  String get mealFoodChocolate;

  /// No description provided for @mealFoodCookie.
  ///
  /// In en, this message translates to:
  /// **'Cookie'**
  String get mealFoodCookie;

  /// No description provided for @mealFoodCake.
  ///
  /// In en, this message translates to:
  /// **'Cake'**
  String get mealFoodCake;

  /// No description provided for @mealFoodYogurt.
  ///
  /// In en, this message translates to:
  /// **'Yogurt'**
  String get mealFoodYogurt;

  /// No description provided for @mealFoodGreekYogurt.
  ///
  /// In en, this message translates to:
  /// **'Greek yogurt'**
  String get mealFoodGreekYogurt;

  /// No description provided for @mealFoodProteinShake.
  ///
  /// In en, this message translates to:
  /// **'Protein shake'**
  String get mealFoodProteinShake;

  /// No description provided for @mealFoodWheyProtein.
  ///
  /// In en, this message translates to:
  /// **'Whey protein'**
  String get mealFoodWheyProtein;

  /// No description provided for @mealFoodMilk.
  ///
  /// In en, this message translates to:
  /// **'Milk'**
  String get mealFoodMilk;

  /// No description provided for @mealFoodSoyMilk.
  ///
  /// In en, this message translates to:
  /// **'Soy milk'**
  String get mealFoodSoyMilk;

  /// No description provided for @mealFoodJuice.
  ///
  /// In en, this message translates to:
  /// **'Juice'**
  String get mealFoodJuice;

  /// No description provided for @mealFoodSportsDrink.
  ///
  /// In en, this message translates to:
  /// **'Sports drink'**
  String get mealFoodSportsDrink;

  /// No description provided for @mealFoodCoffeeLatte.
  ///
  /// In en, this message translates to:
  /// **'Cafe latte'**
  String get mealFoodCoffeeLatte;

  /// No description provided for @mealFoodAmericano.
  ///
  /// In en, this message translates to:
  /// **'Americano'**
  String get mealFoodAmericano;

  /// No description provided for @mealFoodCola.
  ///
  /// In en, this message translates to:
  /// **'Cola'**
  String get mealFoodCola;

  /// No description provided for @mealFoodWater.
  ///
  /// In en, this message translates to:
  /// **'Water'**
  String get mealFoodWater;

  /// No description provided for @mealFoodBanana.
  ///
  /// In en, this message translates to:
  /// **'Banana'**
  String get mealFoodBanana;

  /// No description provided for @mealFoodApple.
  ///
  /// In en, this message translates to:
  /// **'Apple'**
  String get mealFoodApple;

  /// No description provided for @mealFoodOrange.
  ///
  /// In en, this message translates to:
  /// **'Orange'**
  String get mealFoodOrange;

  /// No description provided for @mealFoodGrapes.
  ///
  /// In en, this message translates to:
  /// **'Grapes'**
  String get mealFoodGrapes;

  /// No description provided for @mealFoodStrawberries.
  ///
  /// In en, this message translates to:
  /// **'Strawberries'**
  String get mealFoodStrawberries;

  /// No description provided for @mealFoodBlueberries.
  ///
  /// In en, this message translates to:
  /// **'Blueberries'**
  String get mealFoodBlueberries;

  /// No description provided for @mealFoodSaladGreens.
  ///
  /// In en, this message translates to:
  /// **'Salad greens'**
  String get mealFoodSaladGreens;

  /// No description provided for @mealFoodSeasonedSeaweed.
  ///
  /// In en, this message translates to:
  /// **'Seasoned seaweed'**
  String get mealFoodSeasonedSeaweed;

  /// No description provided for @mealFoodLaver.
  ///
  /// In en, this message translates to:
  /// **'Laver'**
  String get mealFoodLaver;

  /// No description provided for @mealFoodGyeranJjim.
  ///
  /// In en, this message translates to:
  /// **'Steamed egg'**
  String get mealFoodGyeranJjim;

  /// No description provided for @mealFoodJangjorim.
  ///
  /// In en, this message translates to:
  /// **'Jangjorim'**
  String get mealFoodJangjorim;

  /// No description provided for @mealFoodAnchovyBokkeum.
  ///
  /// In en, this message translates to:
  /// **'Stir-fried anchovies'**
  String get mealFoodAnchovyBokkeum;

  /// No description provided for @mealFoodFishCakeBokkeum.
  ///
  /// In en, this message translates to:
  /// **'Stir-fried fish cake'**
  String get mealFoodFishCakeBokkeum;

  /// No description provided for @mealFoodKongjaban.
  ///
  /// In en, this message translates to:
  /// **'Sweet black beans'**
  String get mealFoodKongjaban;

  /// No description provided for @mealFoodCucumberKimchi.
  ///
  /// In en, this message translates to:
  /// **'Cucumber kimchi'**
  String get mealFoodCucumberKimchi;

  /// No description provided for @mealFoodRadishKimchi.
  ///
  /// In en, this message translates to:
  /// **'Radish kimchi'**
  String get mealFoodRadishKimchi;

  /// No description provided for @mealFoodKkakdugi.
  ///
  /// In en, this message translates to:
  /// **'Kkakdugi'**
  String get mealFoodKkakdugi;

  /// No description provided for @mealFoodPerillaLeaves.
  ///
  /// In en, this message translates to:
  /// **'Pickled perilla leaves'**
  String get mealFoodPerillaLeaves;

  /// No description provided for @mealFoodGarlic.
  ///
  /// In en, this message translates to:
  /// **'Garlic'**
  String get mealFoodGarlic;

  /// No description provided for @mealFoodSsamjang.
  ///
  /// In en, this message translates to:
  /// **'Ssamjang'**
  String get mealFoodSsamjang;

  /// No description provided for @mealFoodGochujang.
  ///
  /// In en, this message translates to:
  /// **'Gochujang'**
  String get mealFoodGochujang;

  /// No description provided for @mealFoodDoenjang.
  ///
  /// In en, this message translates to:
  /// **'Doenjang'**
  String get mealFoodDoenjang;

  /// No description provided for @mealFoodSalsa.
  ///
  /// In en, this message translates to:
  /// **'Salsa'**
  String get mealFoodSalsa;

  /// No description provided for @mealFoodGuacamole.
  ///
  /// In en, this message translates to:
  /// **'Guacamole'**
  String get mealFoodGuacamole;

  /// No description provided for @mealFoodTortillaChips.
  ///
  /// In en, this message translates to:
  /// **'Tortilla chips'**
  String get mealFoodTortillaChips;

  /// No description provided for @mealFoodPitaBread.
  ///
  /// In en, this message translates to:
  /// **'Pita bread'**
  String get mealFoodPitaBread;

  /// No description provided for @mealFoodPickles.
  ///
  /// In en, this message translates to:
  /// **'Pickles'**
  String get mealFoodPickles;

  /// No description provided for @mealFoodOlives.
  ///
  /// In en, this message translates to:
  /// **'Olives'**
  String get mealFoodOlives;

  /// No description provided for @mealFoodSauerkraut.
  ///
  /// In en, this message translates to:
  /// **'Sauerkraut'**
  String get mealFoodSauerkraut;

  /// No description provided for @mealFoodColeslaw.
  ///
  /// In en, this message translates to:
  /// **'Coleslaw'**
  String get mealFoodColeslaw;

  /// No description provided for @mealFoodMashedPotatoes.
  ///
  /// In en, this message translates to:
  /// **'Mashed potatoes'**
  String get mealFoodMashedPotatoes;

  /// No description provided for @mealFoodBakedBeans.
  ///
  /// In en, this message translates to:
  /// **'Baked beans'**
  String get mealFoodBakedBeans;

  /// No description provided for @mealFoodGarlicBread.
  ///
  /// In en, this message translates to:
  /// **'Garlic bread'**
  String get mealFoodGarlicBread;

  /// No description provided for @mealFoodOnionSoup.
  ///
  /// In en, this message translates to:
  /// **'Onion soup'**
  String get mealFoodOnionSoup;

  /// No description provided for @mealFoodEdamame.
  ///
  /// In en, this message translates to:
  /// **'Edamame'**
  String get mealFoodEdamame;

  /// No description provided for @mealFoodMozzarella.
  ///
  /// In en, this message translates to:
  /// **'Mozzarella'**
  String get mealFoodMozzarella;

  /// No description provided for @mealFoodHoney.
  ///
  /// In en, this message translates to:
  /// **'Honey'**
  String get mealFoodHoney;

  /// No description provided for @mealFoodJam.
  ///
  /// In en, this message translates to:
  /// **'Jam'**
  String get mealFoodJam;

  /// No description provided for @mealFoodPeanutButter.
  ///
  /// In en, this message translates to:
  /// **'Peanut butter'**
  String get mealFoodPeanutButter;

  /// No description provided for @mealFoodCrackers.
  ///
  /// In en, this message translates to:
  /// **'Crackers'**
  String get mealFoodCrackers;

  /// No description provided for @mealFoodCroissant.
  ///
  /// In en, this message translates to:
  /// **'Croissant'**
  String get mealFoodCroissant;

  /// No description provided for @mealFoodBagel.
  ///
  /// In en, this message translates to:
  /// **'Bagel'**
  String get mealFoodBagel;

  /// No description provided for @mealFoodMuffin.
  ///
  /// In en, this message translates to:
  /// **'Muffin'**
  String get mealFoodMuffin;

  /// No description provided for @mealFoodPancakes.
  ///
  /// In en, this message translates to:
  /// **'Pancakes'**
  String get mealFoodPancakes;

  /// No description provided for @mealFoodWaffles.
  ///
  /// In en, this message translates to:
  /// **'Waffles'**
  String get mealFoodWaffles;

  /// No description provided for @mealSummaryRiceOnly.
  ///
  /// In en, this message translates to:
  /// **'{label} {rice}'**
  String mealSummaryRiceOnly(String label, String rice);

  /// No description provided for @mealSummaryMenuOnly.
  ///
  /// In en, this message translates to:
  /// **'{label} {menu}'**
  String mealSummaryMenuOnly(String label, String menu);

  /// No description provided for @mealSummaryMenuPair.
  ///
  /// In en, this message translates to:
  /// **'{first}, {second}'**
  String mealSummaryMenuPair(String first, String second);

  /// No description provided for @mealSummaryRiceWithMenu.
  ///
  /// In en, this message translates to:
  /// **'{label} {rice} · {menu}'**
  String mealSummaryRiceWithMenu(String label, String rice, String menu);

  /// No description provided for @mealSaveAction.
  ///
  /// In en, this message translates to:
  /// **'Save meal log'**
  String get mealSaveAction;

  /// No description provided for @mealDeleteAction.
  ///
  /// In en, this message translates to:
  /// **'Delete meal log'**
  String get mealDeleteAction;

  /// No description provided for @mealDeleteConfirmBody.
  ///
  /// In en, this message translates to:
  /// **'Delete this day\'s meal log?'**
  String get mealDeleteConfirmBody;

  /// No description provided for @mealSavedFeedback.
  ///
  /// In en, this message translates to:
  /// **'Meal log saved.'**
  String get mealSavedFeedback;

  /// No description provided for @mealSavedWithXpFeedback.
  ///
  /// In en, this message translates to:
  /// **'Meal log saved +{count} XP'**
  String mealSavedWithXpFeedback(int count);

  /// No description provided for @mealDeletedFeedback.
  ///
  /// In en, this message translates to:
  /// **'Meal log deleted.'**
  String get mealDeletedFeedback;

  /// No description provided for @mealLogXpSourceLabel.
  ///
  /// In en, this message translates to:
  /// **'Meal log'**
  String get mealLogXpSourceLabel;

  /// No description provided for @mealCalorieEstimateValue.
  ///
  /// In en, this message translates to:
  /// **'About {kcal} kcal'**
  String mealCalorieEstimateValue(int kcal);

  /// No description provided for @mealCalorieEstimateEmpty.
  ///
  /// In en, this message translates to:
  /// **'Calorie estimate pending'**
  String get mealCalorieEstimateEmpty;

  /// No description provided for @mealNutritionEstimateValue.
  ///
  /// In en, this message translates to:
  /// **'Carbs {carbs}g · protein {protein}g · fat {fat}g'**
  String mealNutritionEstimateValue(int carbs, int protein, int fat);

  /// No description provided for @mealCalorieCoachEmpty.
  ///
  /// In en, this message translates to:
  /// **'Record foods to estimate rough calories from rice bowls and selected items.'**
  String get mealCalorieCoachEmpty;

  /// No description provided for @mealCalorieCoachLow.
  ///
  /// In en, this message translates to:
  /// **'Calories look low today. On a training day, add a carb such as rice, sweet potato, or banana to the next meal.'**
  String get mealCalorieCoachLow;

  /// No description provided for @mealCalorieCoachSteady.
  ///
  /// In en, this message translates to:
  /// **'This looks reasonable for training energy. Next, spread protein and vegetables across each meal.'**
  String get mealCalorieCoachSteady;

  /// No description provided for @mealCalorieCoachHigh.
  ///
  /// In en, this message translates to:
  /// **'Calories look high. If fried food, noodles, or snacks overlapped, make the next meal lighter with protein and vegetables.'**
  String get mealCalorieCoachHigh;

  /// No description provided for @mealAverageExpectedValue.
  ///
  /// In en, this message translates to:
  /// **'Expected average {value} bowl(s)'**
  String mealAverageExpectedValue(String value);

  /// No description provided for @mealAverageActualValue.
  ///
  /// In en, this message translates to:
  /// **'{value} bowl(s)'**
  String mealAverageActualValue(String value);

  /// No description provided for @mealStatsEmpty.
  ///
  /// In en, this message translates to:
  /// **'No meal entries in the selected period.'**
  String get mealStatsEmpty;

  /// No description provided for @mealStatsSectionTitle.
  ///
  /// In en, this message translates to:
  /// **'Meal Logs'**
  String get mealStatsSectionTitle;

  /// No description provided for @mealStatsTrendTitle.
  ///
  /// In en, this message translates to:
  /// **'Meal Flow'**
  String get mealStatsTrendTitle;

  /// No description provided for @mealStatsTodayRiceBowlTitle.
  ///
  /// In en, this message translates to:
  /// **'Latest rice bowls'**
  String get mealStatsTodayRiceBowlTitle;

  /// No description provided for @mealStatsLoggedDays.
  ///
  /// In en, this message translates to:
  /// **'Logged days'**
  String get mealStatsLoggedDays;

  /// No description provided for @mealStatsExpectedAverage.
  ///
  /// In en, this message translates to:
  /// **'Expected avg'**
  String get mealStatsExpectedAverage;

  /// No description provided for @mealStatsActualAverage.
  ///
  /// In en, this message translates to:
  /// **'Actual avg'**
  String get mealStatsActualAverage;

  /// No description provided for @mealStatsBestDay.
  ///
  /// In en, this message translates to:
  /// **'Best day'**
  String get mealStatsBestDay;

  /// No description provided for @mealStatsAverageCalories.
  ///
  /// In en, this message translates to:
  /// **'Avg calories'**
  String get mealStatsAverageCalories;

  /// No description provided for @mealStatsTotalCalories.
  ///
  /// In en, this message translates to:
  /// **'Total calories'**
  String get mealStatsTotalCalories;

  /// No description provided for @mealStatsAverageNutrition.
  ///
  /// In en, this message translates to:
  /// **'Avg nutrients'**
  String get mealStatsAverageNutrition;

  /// No description provided for @mealIncreaseAction.
  ///
  /// In en, this message translates to:
  /// **'Add bowl'**
  String get mealIncreaseAction;

  /// No description provided for @mealDecreaseAction.
  ///
  /// In en, this message translates to:
  /// **'Remove bowl'**
  String get mealDecreaseAction;

  /// No description provided for @mealStatsWeightLinkedHint.
  ///
  /// In en, this message translates to:
  /// **'Days with weight records are linked on the same chart.'**
  String get mealStatsWeightLinkedHint;

  /// No description provided for @homeRiceBowlTitle.
  ///
  /// In en, this message translates to:
  /// **'Today\'s rice bowls'**
  String get homeRiceBowlTitle;

  /// No description provided for @homeRiceBowlSubtitle.
  ///
  /// In en, this message translates to:
  /// **'See full bowls, half bowls, and skipped bowls at a glance.'**
  String get homeRiceBowlSubtitle;

  /// No description provided for @homeRiceBowlFull.
  ///
  /// In en, this message translates to:
  /// **'Full bowl'**
  String get homeRiceBowlFull;

  /// No description provided for @homeRiceBowlHalf.
  ///
  /// In en, this message translates to:
  /// **'Half bowl'**
  String get homeRiceBowlHalf;

  /// No description provided for @homeRiceBowlEmpty.
  ///
  /// In en, this message translates to:
  /// **'Skipped'**
  String get homeRiceBowlEmpty;

  /// No description provided for @fortuneDialogTitle.
  ///
  /// In en, this message translates to:
  /// **'Today\'s line'**
  String get fortuneDialogTitle;

  /// No description provided for @fortuneDialogSubtitle.
  ///
  /// In en, this message translates to:
  /// **''**
  String get fortuneDialogSubtitle;

  /// No description provided for @fortuneDialogOverviewTitle.
  ///
  /// In en, this message translates to:
  /// **'Line view'**
  String get fortuneDialogOverviewTitle;

  /// No description provided for @fortuneDialogOverallFortuneLabel.
  ///
  /// In en, this message translates to:
  /// **'Line'**
  String get fortuneDialogOverallFortuneLabel;

  /// No description provided for @fortuneDialogLuckyInfoLabel.
  ///
  /// In en, this message translates to:
  /// **'Lucky number and color'**
  String get fortuneDialogLuckyInfoLabel;

  /// No description provided for @fortuneDialogOverallFortuneCount.
  ///
  /// In en, this message translates to:
  /// **'{count} lines'**
  String fortuneDialogOverallFortuneCount(int count);

  /// No description provided for @fortuneDialogLuckyInfoCount.
  ///
  /// In en, this message translates to:
  /// **'{count} items'**
  String fortuneDialogLuckyInfoCount(int count);

  /// No description provided for @fortuneDialogLuckyInfoTitle.
  ///
  /// In en, this message translates to:
  /// **'Lucky number and color'**
  String get fortuneDialogLuckyInfoTitle;

  /// No description provided for @fortuneDialogPoolSizeLabel.
  ///
  /// In en, this message translates to:
  /// **'Combinations'**
  String get fortuneDialogPoolSizeLabel;

  /// No description provided for @fortuneDialogPoolSizeCount.
  ///
  /// In en, this message translates to:
  /// **'{count} cases'**
  String fortuneDialogPoolSizeCount(String count);

  /// No description provided for @fortuneDialogRecommendedProgramTitle.
  ///
  /// In en, this message translates to:
  /// **'Next training recommendation'**
  String get fortuneDialogRecommendedProgramTitle;

  /// No description provided for @fortuneDialogRecommendationTitle.
  ///
  /// In en, this message translates to:
  /// **'Play line'**
  String get fortuneDialogRecommendationTitle;

  /// No description provided for @fortuneDialogEncouragement.
  ///
  /// In en, this message translates to:
  /// **'Save one quick highlight from today.'**
  String get fortuneDialogEncouragement;

  /// No description provided for @fortuneDialogAction.
  ///
  /// In en, this message translates to:
  /// **'Got it'**
  String get fortuneDialogAction;

  /// No description provided for @fortuneDatabaseViewAction.
  ///
  /// In en, this message translates to:
  /// **'View full database'**
  String get fortuneDatabaseViewAction;

  /// No description provided for @fortuneDatabaseTitle.
  ///
  /// In en, this message translates to:
  /// **'Full Fortune Database'**
  String get fortuneDatabaseTitle;

  /// No description provided for @fortuneDatabaseSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Myeongli codes, everyday scenes, lucky numbers, and lucky colors used to build short fortunes.'**
  String get fortuneDatabaseSubtitle;

  /// No description provided for @fortuneDatabaseCloseAction.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get fortuneDatabaseCloseAction;

  /// No description provided for @fortuneDatabaseSectionBirthCodes.
  ///
  /// In en, this message translates to:
  /// **'Myeongli codes'**
  String get fortuneDatabaseSectionBirthCodes;

  /// No description provided for @fortuneDatabaseSectionHiddenStems.
  ///
  /// In en, this message translates to:
  /// **'Hidden stems'**
  String get fortuneDatabaseSectionHiddenStems;

  /// No description provided for @fortuneDatabaseSectionTenGods.
  ///
  /// In en, this message translates to:
  /// **'Ten-god meanings'**
  String get fortuneDatabaseSectionTenGods;

  /// No description provided for @fortuneDatabaseSectionTwelveStages.
  ///
  /// In en, this message translates to:
  /// **'Twelve life stages'**
  String get fortuneDatabaseSectionTwelveStages;

  /// No description provided for @fortuneDatabaseSectionBranchRelations.
  ///
  /// In en, this message translates to:
  /// **'Branch relations'**
  String get fortuneDatabaseSectionBranchRelations;

  /// No description provided for @fortuneDatabaseSectionSymbolicStars.
  ///
  /// In en, this message translates to:
  /// **'Symbolic stars'**
  String get fortuneDatabaseSectionSymbolicStars;

  /// No description provided for @fortuneDatabaseSectionElementColors.
  ///
  /// In en, this message translates to:
  /// **'Element colors'**
  String get fortuneDatabaseSectionElementColors;

  /// No description provided for @fortuneDatabaseSectionShortLines.
  ///
  /// In en, this message translates to:
  /// **'Short recommendations'**
  String get fortuneDatabaseSectionShortLines;

  /// No description provided for @fortuneDatabaseSectionLuckyInfoNotes.
  ///
  /// In en, this message translates to:
  /// **'Lucky one-liners'**
  String get fortuneDatabaseSectionLuckyInfoNotes;

  /// No description provided for @fortuneDatabaseSectionDayMoods.
  ///
  /// In en, this message translates to:
  /// **'Line ingredients'**
  String get fortuneDatabaseSectionDayMoods;

  /// No description provided for @fortuneDatabaseSectionDailyEvents.
  ///
  /// In en, this message translates to:
  /// **'What may follow'**
  String get fortuneDatabaseSectionDailyEvents;

  /// No description provided for @fortuneDatabaseSectionDailyOutcomes.
  ///
  /// In en, this message translates to:
  /// **'Short fortune lines'**
  String get fortuneDatabaseSectionDailyOutcomes;

  /// No description provided for @fortuneDatabaseSectionActionCues.
  ///
  /// In en, this message translates to:
  /// **'Small things to try'**
  String get fortuneDatabaseSectionActionCues;

  /// No description provided for @fortuneDatabaseSectionNameRhythms.
  ///
  /// In en, this message translates to:
  /// **'Name rhythms'**
  String get fortuneDatabaseSectionNameRhythms;

  /// No description provided for @fortuneDatabaseSectionAdvice.
  ///
  /// In en, this message translates to:
  /// **'Daily notes'**
  String get fortuneDatabaseSectionAdvice;

  /// No description provided for @fortuneDatabaseSectionColorTones.
  ///
  /// In en, this message translates to:
  /// **'Color tones'**
  String get fortuneDatabaseSectionColorTones;

  /// No description provided for @fortuneDatabaseSectionColorBases.
  ///
  /// In en, this message translates to:
  /// **'Colors'**
  String get fortuneDatabaseSectionColorBases;

  /// No description provided for @fortuneDatabaseSectionTimePeriods.
  ///
  /// In en, this message translates to:
  /// **'Time windows'**
  String get fortuneDatabaseSectionTimePeriods;

  /// No description provided for @fortuneDatabaseSectionTimeWindows.
  ///
  /// In en, this message translates to:
  /// **'Time windows'**
  String get fortuneDatabaseSectionTimeWindows;

  /// No description provided for @fortuneDatabaseSectionSceneModifiers.
  ///
  /// In en, this message translates to:
  /// **'Place cues'**
  String get fortuneDatabaseSectionSceneModifiers;

  /// No description provided for @fortuneDatabaseSectionSceneBases.
  ///
  /// In en, this message translates to:
  /// **'Places and scenes'**
  String get fortuneDatabaseSectionSceneBases;

  /// No description provided for @fortuneDatabaseSectionCueOpenings.
  ///
  /// In en, this message translates to:
  /// **'Routine starts'**
  String get fortuneDatabaseSectionCueOpenings;

  /// No description provided for @fortuneDatabaseSectionCueActions.
  ///
  /// In en, this message translates to:
  /// **'Small routines'**
  String get fortuneDatabaseSectionCueActions;

  /// No description provided for @entryFortuneOpenFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to open fortune.'**
  String get entryFortuneOpenFailed;

  /// No description provided for @profileBirthTimeTitle.
  ///
  /// In en, this message translates to:
  /// **'Birth time'**
  String get profileBirthTimeTitle;

  /// No description provided for @profileBirthTimeSelectDateFirst.
  ///
  /// In en, this message translates to:
  /// **'Select birth date first'**
  String get profileBirthTimeSelectDateFirst;

  /// No description provided for @fortuneGeneratedUnknownPlayerName.
  ///
  /// In en, this message translates to:
  /// **'Player'**
  String get fortuneGeneratedUnknownPlayerName;

  /// No description provided for @fortuneGeneratedBirthNotSet.
  ///
  /// In en, this message translates to:
  /// **'no birth date set'**
  String get fortuneGeneratedBirthNotSet;

  /// No description provided for @fortuneGeneratedBirthFrame.
  ///
  /// In en, this message translates to:
  /// **'birth code {yearPillar}/{monthPillar}/{dayPillar}'**
  String fortuneGeneratedBirthFrame(
      String yearPillar, String monthPillar, String dayPillar);

  /// No description provided for @fortuneGeneratedBirthFrameWithTime.
  ///
  /// In en, this message translates to:
  /// **'birth code {yearPillar}/{monthPillar}/{dayPillar}/{hourPillar}'**
  String fortuneGeneratedBirthFrameWithTime(String yearPillar,
      String monthPillar, String dayPillar, String hourPillar);

  /// No description provided for @fortuneShortLines.
  ///
  /// In en, this message translates to:
  /// **'Read once more before sending.|The first pass can stay safe.|Check the bag zipper before moving.|A sip of water helps the start.|Take the first five minutes slow.|Retied boots make the first step lighter.|Fewer options keep focus longer.|After a miss, the next ball has the answer.|A short reply sent first feels lighter.|Ten seconds of film can show the point.|Scan empty space and the pass lane opens.|Use your voice once and the team moves faster.|One finish photo keeps the day clear.|One quick compliment speeds up the talk.|One line is enough for the record.|Pause three seconds when you rush.|Keep the first touch close for the next move.|Move without the ball and you get it again.|Putting it away now saves time later.|Change posture while waiting and the body loosens.|Eat slow and put the phone down for a bit.|Start with the easiest piece when stuck.|Write the messy choice in two lines.|A short overdue reply is enough.|Screenshot new info and it is easier to find.|Save the line you liked; it will help later.|Stretch after practice and tomorrow feels easier.|Say hello first and the talk opens faster.|Move one beat early when space appears.|Split the routine into ten-minute chunks.|Lower the load if it feels off.|Save the good scene and reuse it later.|Mute one alert and focus gets longer.|Set the next plan five minutes early.|Lift your head before the pass and options grow.|Choose one dribble direction and feet stay cleaner.|Empty the bag before home and tomorrow is easier.|Grab water first during the break.|Basics make mistakes shrink faster.|One check before closing saves time tomorrow.'**
  String get fortuneShortLines;

  /// No description provided for @fortuneGeneratedDailyLineOne.
  ///
  /// In en, this message translates to:
  /// **'{name}, {elementFlow}'**
  String fortuneGeneratedDailyLineOne(String name, String elementFlow);

  /// No description provided for @fortuneGeneratedDailyLineTwo.
  ///
  /// In en, this message translates to:
  /// **'{fortuneTheme}'**
  String fortuneGeneratedDailyLineTwo(String fortuneTheme);

  /// No description provided for @fortuneGeneratedLinkedDailyLine.
  ///
  /// In en, this message translates to:
  /// **'{name}, {elementFlow} / {fortuneTheme}'**
  String fortuneGeneratedLinkedDailyLine(
      String name, String elementFlow, String fortuneTheme);

  /// No description provided for @fortuneGeneratedDailyLineThree.
  ///
  /// In en, this message translates to:
  /// **'Recommendation: use {nameElement} and {playAdvice}.'**
  String fortuneGeneratedDailyLineThree(String nameElement, String playAdvice);

  /// No description provided for @fortuneGeneratedLuckyInfoHeader.
  ///
  /// In en, this message translates to:
  /// **'[Lucky number and color]'**
  String get fortuneGeneratedLuckyInfoHeader;

  /// No description provided for @fortuneGeneratedLuckyInfoLine.
  ///
  /// In en, this message translates to:
  /// **'Lucky number is {number}, lucky color is {color}. {note}'**
  String fortuneGeneratedLuckyInfoLine(int number, String color, String note);

  /// No description provided for @fortuneLuckyInfoNotes.
  ///
  /// In en, this message translates to:
  /// **'Keep the number like a small jersey number.|When you spot this color, use it as your routine signal.|Finding this color in your bag can feel oddly steady.|Treat the color as the uniform accent and the number as your cheer code.|Smile when you see it, then move to the next play.|Today\'s luck only needs one pocket in your bag.|Remember the number quickly and let the color stay visible.|This combo is lighter than a charm and more useful than a sticker.|It is a lucky item you can mention without feeling awkward.|One color can make today\'s scene a little clearer.|Carry the number like a beat and the color like an accent.|Finding it in your bag counts as a tiny win.|Remember it as lightly as choosing a uniform.|Let it remind you to take one sip of water.|Leave the number like one check mark for the day.|This color is enough as today\'s small highlight.|Even luck checks the dress code sometimes.|Keep the number short and the color clear.|Use this combo as a small booster.|If it catches your eye, count it as being on your side.|Keep the color in sight and the number in mind.|This combo is today\'s tiny cheering section.|When you see the color, drop your shoulders once.|Carry the number like a jersey and the color like sideline support.'**
  String get fortuneLuckyInfoNotes;

  /// No description provided for @fortuneRecommendedRecoveryProgram.
  ///
  /// In en, this message translates to:
  /// **'Recovery ball touch'**
  String get fortuneRecommendedRecoveryProgram;

  /// No description provided for @fortuneRecommendedLightFirstTouchProgram.
  ///
  /// In en, this message translates to:
  /// **'Light first touch'**
  String get fortuneRecommendedLightFirstTouchProgram;

  /// No description provided for @fortuneRecommendedForwardPassProgram.
  ///
  /// In en, this message translates to:
  /// **'Forward pass combination'**
  String get fortuneRecommendedForwardPassProgram;

  /// No description provided for @fortuneRecommendedCoreTechniqueProgram.
  ///
  /// In en, this message translates to:
  /// **'Core technique routine'**
  String get fortuneRecommendedCoreTechniqueProgram;

  /// No description provided for @fortuneRecommendationInjury.
  ///
  /// In en, this message translates to:
  /// **'Check pain first and lower the next session intensity around {program}.'**
  String fortuneRecommendationInjury(String program);

  /// No description provided for @fortuneRecommendationStrongFlow.
  ///
  /// In en, this message translates to:
  /// **'Your practice rhythm is good. Keep the next session focused on {program}.'**
  String fortuneRecommendationStrongFlow(String program);

  /// No description provided for @fortuneRecommendationDefault.
  ///
  /// In en, this message translates to:
  /// **'Use {program} next to settle your rhythm and raise accuracy.'**
  String fortuneRecommendationDefault(String program);

  /// No description provided for @fortuneSajuHeavenlyStems.
  ///
  /// In en, this message translates to:
  /// **'Gap|Eul|Byeong|Jeong|Mu|Gi|Gyeong|Sin|Im|Gye'**
  String get fortuneSajuHeavenlyStems;

  /// No description provided for @fortuneSajuEarthlyBranches.
  ///
  /// In en, this message translates to:
  /// **'Ja|Chuk|In|Myo|Jin|Sa|O|Mi|Sin|Yu|Sul|Hae'**
  String get fortuneSajuEarthlyBranches;

  /// No description provided for @fortuneMyeongliHiddenStemLabels.
  ///
  /// In en, this message translates to:
  /// **'Zi: Gui|Chou: Ji, Gui, Xin|Yin: Jia, Bing, Wu|Mao: Yi|Chen: Wu, Yi, Gui|Si: Bing, Wu, Geng|Wu: Ding, Ji|Wei: Ji, Ding, Yi|Shen: Geng, Ren, Wu|You: Xin|Xu: Wu, Xin, Ding|Hai: Ren, Jia'**
  String get fortuneMyeongliHiddenStemLabels;

  /// No description provided for @fortuneMyeongliTenGodLabels.
  ///
  /// In en, this message translates to:
  /// **'Friend: self-direction and personal standards|Rob wealth: competition, sharing, quick response|Eating god: enjoyment, expression, steady output|Hurting officer: unusual expression and off-rule ideas|Indirect wealth: wide chances and unexpected offers|Direct wealth: practical order and steady care|Seven killings: pressure, decision, breakthrough|Direct officer: promises, order, trusted rhythm|Indirect resource: unusual clues and deep observation|Direct resource: support, learning, easy protection'**
  String get fortuneMyeongliTenGodLabels;

  /// No description provided for @fortuneMyeongliTwelveStageLabels.
  ///
  /// In en, this message translates to:
  /// **'Longevity: a new force begins to grow|Bath: senses wake up and change starts|Crown belt: posture and readiness form|Official: personal strength becomes clear|Prosperity: the strongest push|Decline: easing force and arranging matters|Sickness: care matters more than overdoing|Death: endings and decisions come forward|Tomb: storing and ripening the thought|Extinction: cutting off and seeing anew|Embryo: a small possibility appears|Nurturing: preparing the next flow'**
  String get fortuneMyeongliTwelveStageLabels;

  /// No description provided for @fortuneMyeongliBranchRelationLabels.
  ///
  /// In en, this message translates to:
  /// **'Zi-Wu clash: direction collides and choices sharpen|Chou-Wei clash: old matters begin to move|Yin-Shen clash: movement and judgment speed up|Mao-You clash: words and relationships need balance|Chen-Xu clash: standards and responsibility are reviewed|Si-Hai clash: feelings and speed need pacing|Zi-Chou combination: close cooperation and stability|Yin-Hai combination: learning and expansion connect|Mao-Xu combination: warm expression and empathy|Chen-You combination: order and results connect|Si-Shen combination: quick judgment and wit|Wu-Wei combination: easy relationships and closure|Yin-Si-Shen punishment: a signal to smooth urgency|Chou-Wei-Xu punishment: a signal to clear old pressure|Zi-Mao punishment: a signal to tune words and feelings|Zi-Wei harm: check small misunderstandings|Chou-Wu harm: match the heat of feeling and action|Yin-Si harm: lower the rush|Mao-Chen harm: view close ties gently|Shen-Hai harm: sort things when thoughts grow|You-Xu harm: mind wording and promises|Zi-You break: rebuild a scattered plan|Chou-Chen break: mend a small crack|Yin-Hai break: see familiar expectations anew|Mao-Wu break: change the way you express it|Si-Shen break: review a quick choice once more|Wei-Xu break: reset the finishing standard|Shen-Zi-Chen water trine: thoughts and information gather|Hai-Mao-Wei wood trine: growth and relationships wake up|Yin-Wu-Xu fire trine: expression and passion rise|Si-You-Chou metal trine: order and finish improve|Hai-Zi-Chou water frame: calm focus builds|Yin-Mao-Chen wood frame: starting and growth flow|Si-Wu-Wei fire frame: energy and expression flow|Shen-You-Xu metal frame: results and order flow'**
  String get fortuneMyeongliBranchRelationLabels;

  /// No description provided for @fortuneMyeongliSymbolicStarLabels.
  ///
  /// In en, this message translates to:
  /// **'Heavenly noble: helpful support appears|Literary star: writing, learning, and speech|Peach blossom: charm and attention rise|Traveling horse: movement, change, and new news|Canopy: immersion, taste, and deep feeling|Sheep blade: strong drive and decision|White tiger: big energy and breakthrough|Goe-gang: forceful independence|Heavenly virtue: gentle protection and buffering|Monthly virtue: help and care through relationships|Heavenly doctor: recovery and care|Golden carriage: comfort, stability, and easy favor'**
  String get fortuneMyeongliSymbolicStarLabels;

  /// No description provided for @fortuneMyeongliElementColorLabels.
  ///
  /// In en, this message translates to:
  /// **'Wood: green, mint, turquoise, forest|Fire: red, coral, peach, rose pink|Earth: mustard, butter yellow, mocha, ivory|Metal: white, silver, gold, stone gray|Water: navy, black, steel blue, ocean blue'**
  String get fortuneMyeongliElementColorLabels;

  /// No description provided for @fortuneMyeongliElementColorValues.
  ///
  /// In en, this message translates to:
  /// **'green/mint/turquoise/forest|red/coral/peach/rose pink|mustard/butter yellow/mocha/ivory|white/silver/gold/stone gray|navy/black/steel blue/ocean blue'**
  String get fortuneMyeongliElementColorValues;

  /// No description provided for @fortuneMyeongliTenGodDailyLines.
  ///
  /// In en, this message translates to:
  /// **'a day to split today’s tasks into three parts|a day to pick only the words you need in a group chat|a day to take a break and grab a small snack|a day to explain things in a different tone|a day to compare a sudden offer by its conditions|a day to tidy your bag and desk|a day to decide on a delayed reply|a day to keep appointment times and order|a day to reopen a missed notification|a day to solve a stuck task with help'**
  String get fortuneMyeongliTenGodDailyLines;

  /// No description provided for @fortuneMyeongliTwelveStageDailyLines.
  ///
  /// In en, this message translates to:
  /// **'a day to start the first morning action small|a day to notice changes in faces and tone|a day to prepare your seat and supplies first|a day to handle tasks one by one at your pace|a day to start delayed work in the morning|a day to remove unnecessary plans and items|a day to put rest time first|a day to pick one task and finish it|a day to reuse an old note|a day to separate what to stop from what to continue|a day to choose one small thing to try|a day to write tomorrow’s tasks tonight'**
  String get fortuneMyeongliTwelveStageDailyLines;

  /// No description provided for @fortuneMyeongliBranchRelationDailyLines.
  ///
  /// In en, this message translates to:
  /// **'a day to handle things with someone close|a day to reset tasks after opinions clash|a day to list tangled work in order|a day to ask right away and reduce misunderstanding|a day to match loose plans again|a day to gather everyone’s comments in one place|a day to handle tasks in a familiar place'**
  String get fortuneMyeongliBranchRelationDailyLines;

  /// No description provided for @fortuneSajuElementFlows.
  ///
  /// In en, this message translates to:
  /// **'a day to start slowly and pick up speed before noon|a day to reply to a message from a welcome name|a day to find a lost item or needed information|a day to clear one part of your room or desk|a day to lift your mood with music or a snack|a day to choose one of two options|a day to talk first to someone close|a day to hold one task for a short time|a day to finish work faster with help|a day to rest briefly and restart|a day to write down an idea right away|a day to find a clue in a usual place|a day to clear old notifications or notes|a day to choose words after reading someone’s face|a day to leave ten minutes early for an appointment|a day to speak first with a little courage|a day to check news you waited for again|a day to finish at a comfortable pace|a day to split a stuck task into small steps|a day to move in the order you chose|a day to greet someone with a smile first|a day to check changed plans or places quickly|a day to check an answer you waited for one more time|a day to show work you prepared quietly'**
  String get fortuneSajuElementFlows;

  /// No description provided for @fortuneSajuElementFlowExtras.
  ///
  /// In en, this message translates to:
  /// **'a day to listen until the other person finishes|a day to choose again when something unexpected happens|a day to start with the least heavy task|a day to ask once before deciding alone|a day to notice small kindness right away|a day to choose a menu or route quickly|a day to mark finished work with a check|a day to try the option you like for five minutes|a day to receive a slow reply|a day to write the answer to a task in one line|a day to get a hint from a phrase or photo|a day to put nearby items back in place|a day to discover a new object or topic of interest|a day to write busy thoughts on paper|a day to find the first clue early|a day to say it briefly and still be understood|a day to ask gently and hear an answer|a day to hear or give a small compliment|a day to rest five minutes and start the next task|a day to match appointment and travel times|a day to reduce notifications and keep focus|a day to fix a small mistake right away|a day to find missed items or information|a day to speed up afternoon tasks|a day to have quiet preparation recognized|a day to trust checked facts over first feelings|a day to move naturally after a small plan change|a day to greet first and get a response|a day to make the first task small|a day to check one more time before finishing|a day to feel waiting time shorten|a day to meet one more laugh|a day to hear a new offer before refusing it|a day to use comfortable words instead of stiff ones|a day to look closely and speak right away|a day to search or ask about what you wonder'**
  String get fortuneSajuElementFlowExtras;

  /// No description provided for @fortuneSajuFortuneThemes.
  ///
  /// In en, this message translates to:
  /// **'a welcome name appears in your morning notification.|you send a delayed message before lunch.|the reply you waited for arrives by afternoon.|you compare the terms of a new offer and decide.|you skip a small purchase and choose what you need.|you turn a complicated thought into one note.|a short talk with someone close makes your mind easier.|you follow a useful guide on a usual route.|you finish delayed work with twenty minutes of focus.|someone’s short comment makes today’s choice easier.|a changed schedule gives you a more comfortable time.|a forgotten promise or supply comes back to mind.|you pull out something you were looking for while tidying.|a color or item you choose changes your mood.|waiting time shrinks and you start the next task faster.|you receive or give a small compliment.|needed information comes through a chat or notification.|you handle delayed work quietly while alone.|a solution comes during a short walk or commute.|you decide on a confusing choice before evening.|you notice what someone wants without being told.|you fix a small mistake and laugh it off.|you read someone’s reaction and change your words.|you reopen a contact you delayed for a long time.|new information changes what you were choosing.|water or a short rest improves your mood quickly.|you choose to save time rather than money.|someone you meet by chance leads to the next plan.|quiet focus leaves a visible result.|something on your mind ends more easily than expected.|a night check catches what you missed.|handling someone’s request gives you useful information.|you directly check an item or news you waited for.|you meet someone who is easier to talk with than expected.|one small tidy-up makes the rest of the day easier.|you keep the first choice you made.'**
  String get fortuneSajuFortuneThemes;

  /// No description provided for @fortuneSajuFortuneThemeExtras.
  ///
  /// In en, this message translates to:
  /// **'you sort the needed schedule on the first screen of the morning.|you finish a small favor and hear thanks right away.|you start a postponed tidy-up within ten minutes.|you bring up a conversation on your mind briefly.|free time opens earlier than expected.|a lightly chosen route takes you to the shop or place you wanted.|moving first reduces waiting time.|you organize the information on an open screen.|a small mistake leads you to an easier method.|a short wait helps you decide the next choice.|you hear welcome news from someone familiar.|a small task finished in the morning makes the afternoon easier.|shorter words carry your meaning more accurately.|you finish an annoying task and mark it checked.|you find an answer or item in a nearby place.|someone who asks for help later gives you useful information.|an unplanned task ends faster than expected.|a thought worth writing down comes during a short break.|you compare price or time and choose an unfamiliar option.|a welcome notification or message arrives late afternoon.|unexpected praise brightens your face.|starting with what is in reach tidies things quickly.|a light sentence leads to a short conversation.|you reopen a contact you postponed.|you reduce unclear priorities to three.|a small discovery changes what you want to buy.|supplies you quietly prepared help at the end.|focus works well at a different time than usual.|small kindness returns sooner than expected.|a worry ends with a short check.|words you waited for arrive as a short text.|one light change refreshes your schedule.|one more check helps you avoid a mistake.|a rule for a long concern becomes clear.|slowing down makes the finish neater.|a strength you prepared alone shows during conversation.|a skipped message contains an important date.|you follow a new guide in a familiar place.|smiling first helps you start a conversation easily.|a short check builds trust.|the color you choose keeps catching your eye in photos or items.|a short trip helps you sort what to do.|you find a menu or item you unexpectedly like.|something hard to say comes out naturally.|you match your move to the time people around you move.|even after a late start, you finish the final check.|a small concession gives you a more comfortable seat.|new information becomes the reason for changing today’s choice.|something you laughed off becomes a good evening story.|a tidy space helps you find what you need right away.|words from someone close become today’s standard for choosing.|something feels like a small reward at the end of the day.|an unusual check helps you avoid a mistake.|you end a meeting or call more comfortably than expected.|a sudden idea becomes useful right away.|after a short walk, your next task becomes clear.|good news begins as a short sentence or small notification.|the final choice turns out more comfortable.|an easy choice satisfies you for a long time.|speaking first with small courage changes the situation.'**
  String get fortuneSajuFortuneThemeExtras;

  /// No description provided for @fortuneDailyOutcomeTimes.
  ///
  /// In en, this message translates to:
  /// **'in the morning|around lunch|this afternoon|this evening|out of nowhere|by chance|pretty soon|all at once|in a quick moment|at the end'**
  String get fortuneDailyOutcomeTimes;

  /// No description provided for @fortuneDailyOutcomeSubjects.
  ///
  /// In en, this message translates to:
  /// **'a funny scene|a welcome message|good news|a small chance|the answer you need|a new offer|a free pocket of time|a sharp comment|a grateful moment|an easy choice'**
  String get fortuneDailyOutcomeSubjects;

  /// No description provided for @fortuneDailyOutcomeResults.
  ///
  /// In en, this message translates to:
  /// **'pops up.|lifts the mood.|makes the day easier.|sticks around.|makes the next move easier.|lands bigger than expected.|changes today\'s energy.|gives you a little push.|makes you smile.|stays memorable.'**
  String get fortuneDailyOutcomeResults;

  /// No description provided for @fortuneSajuTrainingTones.
  ///
  /// In en, this message translates to:
  /// **'things feel cleaner if you do not rush for no reason.|one first word can loosen the mood quickly.|start with a small tidy-up and the flow speeds up.|write down what bothers you in a short note.|a comfortable choice fits better than a fast decision today.|one light joke can melt the awkwardness.|reduce a complex task to three steps.|check important messages in the morning for an easier day.|after lunch, fewer extra plans may suit you better.|keep a pleasing color nearby and focus gets easier.|handle a small request quickly and your mind opens up.|save or write down any decent idea.|when words get long, the core is enough.|fun may come from a familiar route rather than a new one.|pause for one breath and the choice becomes clearer.|it is okay to get help with something you were solving alone.|pick one small thing to do while waiting.|do not wait too long before answering welcome news.|trust your taste more than the perfect answer.|drop the comparisons and your mood recovers fast.|look once more for something you thought was lost.|check unfamiliar information once before trusting it.|ask how someone close is doing first.|it is a good time to finish a delayed booking or check.|a short outing may refresh you more than expected.|fewer phone alerts can stretch your focus.|a small choice you can make now is better than later.|split a worry into smaller pieces instead of saying it big.|a neat finish raises the day\'s luck.|a casually chosen menu may satisfy you more than expected.|read once more before sending and misunderstandings shrink.|if the pace stalls, change your seat or background.|smiling first makes conversation much easier.|drop one unnecessary thing and your mind gets lighter.|keep ten minutes of room around appointments.|today\'s good scene can stay in words, not only photos.'**
  String get fortuneSajuTrainingTones;

  /// No description provided for @fortuneSajuTrainingToneExtras.
  ///
  /// In en, this message translates to:
  /// **'break the first task that comes to mind into smaller pieces today.|if you feel stuck, open a window or move toward the light.|keep important words short and kind words a little warmer.|a rushed choice can feel much easier after five minutes.|if your mood feels vague, finish the easiest thing first.|look at intent before tone and your mind may lighten.|start a new attempt small and the pressure drops.|today, beginning before tidying can also be fine.|if something stopped midway, add just one line.|write a good thought right away so today\'s luck stays.|if you are delaying an answer, send even a short signal.|removing one unneeded alert can bring focus back.|one clean item may reset your mood today.|when asking for something, start with the core instead of a long explanation.|in an awkward place, look for common ground first.|carry one morning standard through the day.|for a small spend, think about satisfaction first.|complex feelings get easier when you name them.|today fits a natural finish more than perfection.|do not hold good news alone for too long.|if worry gets long, move your body first.|mix a small change into a familiar method.|keep important things where you can see them.|if your words tangle, return to the first sentence.|move quickly by day and softly by evening.|a short and kind no is enough today.|tidy your surroundings while waiting and your mind will settle.|good timing shows itself first to people who prepare a little.|when comparison starts, compare only with yesterday\'s self.|if your mind rushes, count numbers and choose again.|say someone\'s strength first and conversation opens easily.|one small note today can help your next choice.|do not ignore discomfort; check it gently.|put down a long-held task once and an answer may appear.|a brief final check can make the day clean.|a short laugh may become more energy than expected.'**
  String get fortuneSajuTrainingToneExtras;

  /// No description provided for @fortuneSajuNameElements.
  ///
  /// In en, this message translates to:
  /// **'quick-starter|kind connector|calm organizer|spark-idea|slow observer|mood-shifter|careful chooser|fast intuition|steady recovery|smile-first|chance spotter|small-happiness|heart-aware|timing matcher|action over words|one-beat waiter|open to newness|accurate picker|warm relationship|small-practice|mood lifter|flow changer|curious mind|clean finisher'**
  String get fortuneSajuNameElements;

  /// No description provided for @fortuneSajuNameElementExtras.
  ///
  /// In en, this message translates to:
  /// **'small-clue catcher|slow but accurate type|mood opener|quick mood recoverer|good-word giver|new-flow starter|calm center holder|quick-check keeper|hidden-strength finder|comfortable chooser|relationship temperature matcher|last-tidy finisher|small-change spotter|fast information linker|mind lightener|quiet pusher|interest keeper|standard setter|laugh-point finder|feeling truster|one-more-check type|kindness rememberer|space maker|coincidence collector|quick refresher|right-moment chooser|soft persuader|small-win builder|easy-thought organizer|bright-side viewer|patient waiter|close-people carer|new-taste finder|plain finisher|day-rhythm maker|light-choice maker'**
  String get fortuneSajuNameElementExtras;

  /// No description provided for @fortuneSajuPlayAdvice.
  ///
  /// In en, this message translates to:
  /// **'a small coincidence gets more fun when you do not pass over it.|the person who tidies first may own today\'s pace.|a light choice may keep your mood up longer than expected.|a kind sentence has more power than saving every word.|the answer you waited for may arrive in a simpler shape.|leave a decent suggestion open for a moment before refusing it.|give yourself one easy choice during the day.|a small direction change fits better than a big reset today.|you may see a new side of someone familiar.|one extra look at an ordinary thing may reveal the hint.|a short pause may reduce afternoon mistakes.|a light move can loosen tangled thoughts too.|keep a vivid color nearby when your mood dips.|an unfamiliar conversation may become comfortable quickly.|reduce the rush and the result can follow enough.|a quick check makes trust visible.|one piece of information today may become useful later.|something you laughed off may become a good evening story.|sorting what to keep and let go makes the mind lighter.|it is a good day to restart something paused rather than begin new.|if you receive unexpected praise, you can simply accept it.|a short focus window can carry you farther.|ask one question first and awkwardness fades fast.|today\'s luck arrives through small repeats more than big events.|when there are many options, choose the most comfortable one.|your subtle hunch may be right, so write it down.|thank someone quickly when you get help.|finishing what can end early keeps the luck alive.|one phrase you like can change your whole expression.|read slowly when news arrives after a wait.|a neat start can lead to a neat finish today.|something you do without big expectations may return as a small result.|check misunderstandings briefly and softly.|keep your own pace and nearby flows feel easier.|a short silence may bring a better answer.|the last choice you make may become today\'s memory.'**
  String get fortuneSajuPlayAdvice;

  /// No description provided for @fortuneSajuPlayAdviceExtras.
  ///
  /// In en, this message translates to:
  /// **'you do not need to doubt your first feeling too much today.|crossing one small line first can make the day wider.|finish less important things lightly and keep your energy.|send a short hello to someone welcome and the flow improves.|new information can become useful if you save it now.|today\'s luck may arrive as good timing rather than a big event.|when your mood shakes, return to your most familiar routine.|one item you tidy first can make your mind comfortable.|reduce a long worry to two choices.|even a short link with someone who understands you is good.|answering a little slowly today will not break the mood.|laughing off something small may keep your mood up longer.|look for a new scene in a familiar place.|when someone is kind, respond right away.|ask a little more softly when something is unclear.|lowering the rush can make luck feel clearer today.|keeping a favorite color nearby may make choices easier.|recognize a small success right away so the next flow attaches.|imagine an unexpected offer once before deciding.|start an awkward talk with the weather or a scene you saw today.|if there is a lot to do, finish the shortest one first.|your comfortable speed is the best speed today.|you do not need to stare at one mistake for too long.|a decent thought may need a memo before words.|when waiting appears, use it to notice your surroundings.|saying thanks first can soften relationship luck.|a small plan change may fit better than the original.|if choosing is hard, pick the side that relaxes your face.|an old item may give a small hint today.|if your heart feels heavy, shrink the task to one line.|good words are better used today than saved.|a hint may come from someone close rather than someone unfamiliar.|write down today\'s hunch; later it may look quite accurate.|even a slow start can speed up once the flow catches.|if things do not sort out, empty your thoughts before the room.|a light promise may stay longer than a heavy one.|something small you learn today may become very useful.|give yourself a small reward after finishing an unpleasant task.|use a sentence you like as today\'s expression.|small curiosity can open a good conversation.|if someone approaches first, you can leave the door a little open.|today, fewer explanations may help you connect better.|a small afternoon change may alter your evening mood.|even with a familiar choice, mix in one fun detail.|a problem that does not solve right away can wait until night.|attitude may arrive before words in one moment.|small compliments may come more easily today.|thinking in a quiet place may make the answer clearer.|something started lightly may continue longer than expected.|a small sentence can quickly loosen an uncomfortable feeling.|preparing one item first can make the day easier.|today favors a chance discovery more than a chance meeting.|a pleasant sound can change the rhythm of the day.|after a small concession, an easier option may open.|today\'s good luck may show itself late but clearly.|it is fine to look again at what you liked first.|look together for the reason someone nearby is smiling.|a short focus can reduce a long worry.|today, passing cleanly may fit better than holding on.|move with one small expectation and the day feels lighter.'**
  String get fortuneSajuPlayAdviceExtras;

  /// No description provided for @fortuneLuckyColorTones.
  ///
  /// In en, this message translates to:
  /// **'Deep|Soft|Clean|Sunset|Cool|Warm|Mist|Bright|Mono|Accent|Neon|Pastel|Metallic|Fresh|Calm|Spark|Light|Mood|Glow|Natural'**
  String get fortuneLuckyColorTones;

  /// No description provided for @fortuneLuckyColorToneExtras.
  ///
  /// In en, this message translates to:
  /// **'Minty|Smoky|Vivid|Subtle|Clear|Cozy|Fresh green|Cool-edged|Warm-lit|Transparent|Vintage|Sharp|Calm glow|Gentle|Crisp|Glittering|Deepened|Airy|Bright clear|Plain'**
  String get fortuneLuckyColorToneExtras;

  /// No description provided for @fortuneLuckyColorBases.
  ///
  /// In en, this message translates to:
  /// **'Navy|Emerald|Coral|Mustard|Sky Blue|Khaki|Ivory|Cherry Red|Lime|Charcoal|Royal Blue|Mint|Peach|Violet|Silver|Gold|White|Black|Olive|Turquoise|Lavender|Butter Yellow|Rose Pink|Deep Green'**
  String get fortuneLuckyColorBases;

  /// No description provided for @fortuneLuckyColorBaseExtras.
  ///
  /// In en, this message translates to:
  /// **'Plum|Salmon|Aqua|Burgundy|Champagne|Mocha|Stone Gray|Lilac|Apple Green|Denim Blue|Cream|Ruby|Sage|Ocean Blue|Melon|Cocoa|Steel Blue|Powder Pink|Ice Blue|Forest|Tangerine|Grape|Snow|Moss Green'**
  String get fortuneLuckyColorBaseExtras;

  /// No description provided for @fortuneLuckyTimePeriods.
  ///
  /// In en, this message translates to:
  /// **'Early morning|Late morning|Right after lunch|Early afternoon|Late afternoon|At sunset|Early evening|Night routine window|Before school|Break time|On the move|Before sleep|Message-check time|Snack time|Right after getting home|Day wrap-up time'**
  String get fortuneLuckyTimePeriods;

  /// No description provided for @fortuneLuckyTimePeriodExtras.
  ///
  /// In en, this message translates to:
  /// **'Morning prep time|First message time|Before lunch|After-lunch walk time|Afternoon focus time|When the sun leans down|Before dinner|After dinner|Room tidy time|After washing up|Quiet night|Short break time|Before an appointment|After an appointment|Moment you write a record|Last check time'**
  String get fortuneLuckyTimePeriodExtras;

  /// No description provided for @fortuneLuckyTimeWindows.
  ///
  /// In en, this message translates to:
  /// **'06:40-07:20|08:10-08:50|09:30-10:10|10:40-11:20|12:20-13:00|14:10-14:50|16:00-16:40|18:20-19:00|20:10-20:50|21:00-21:40|07:30-08:00|11:40-12:10|13:20-13:50|15:10-15:40|17:20-17:50|19:30-20:00|22:00-22:30|06:10-06:30|12:50-13:20|18:50-19:20'**
  String get fortuneLuckyTimeWindows;

  /// No description provided for @fortuneLuckyTimeWindowExtras.
  ///
  /// In en, this message translates to:
  /// **'06:55-07:15|07:45-08:15|08:55-09:25|09:45-10:15|10:55-11:25|11:55-12:25|12:35-13:05|13:45-14:15|14:35-15:05|15:45-16:15|16:35-17:05|17:45-18:15|18:35-19:05|19:45-20:15|20:35-21:05|21:45-22:15|22:20-22:50|06:20-06:50|07:05-07:35|08:25-08:55|10:20-10:50|11:10-11:40|13:05-13:35|14:55-15:25|16:50-17:20|18:05-18:35|19:05-19:35|21:10-21:40'**
  String get fortuneLuckyTimeWindowExtras;

  /// No description provided for @fortuneLuckyZoneModifiers.
  ///
  /// In en, this message translates to:
  /// **'By the window|Near the door|Left seat|Right seat|Center seat|Quiet spot|Bright spot|Shaded spot|In front of the desk|Near the entrance|By the elevator|Near the bus stop|Cafe corner|End of the hallway|Near the stairs|Water spot|In front of the mirror|Beside the bag|Near the table|Beside the bed'**
  String get fortuneLuckyZoneModifiers;

  /// No description provided for @fortuneLuckyZoneModifierExtras.
  ///
  /// In en, this message translates to:
  /// **'Sunlit|Breezy|Less crowded|Most familiar|Newly noticeable|Tidied|Warm-lit|Where your steps pause|Leaning spot|Where sounds fade|Wide-view|Where you put things down|Mood-brightening|Easy to hear|Quietly smiling|First seen today|Lightly passing|Worth a second look|Comfortable|Softly sparkling'**
  String get fortuneLuckyZoneModifierExtras;

  /// No description provided for @fortuneLuckyZoneBases.
  ///
  /// In en, this message translates to:
  /// **'small memo space|place to put the phone down|moment of the first hello|spot for a light smile|chair for a short break|tidy desk surface|moment of opening the bag|seat with a window view|place to drink water|quiet thinking spot|moment of checking a message|place to fix your shoes|place waiting for the elevator|time with favorite music|place to wash your hands|quick snack spot|place to review the plan|place to pause for a moment|moment of coming home|spot where you turn on the light|moment you yield first|place where a new path appears|spot to find today\'s item|place that closes the day'**
  String get fortuneLuckyZoneBases;

  /// No description provided for @fortuneLuckyZoneBaseExtras.
  ///
  /// In en, this message translates to:
  /// **'spot where you open a window|place to open a notebook|place to plug in a charger|beside a favorite cup|place to check the calendar|place to set down your bag|moment of reading a text|place to tie your shoes|wall to lean on briefly|desk touched by light|spot to choose a drink|moment of checking your watch|place you look back one last time|place with a small sound|spot to check a photo|place where waiting feels shorter|moment of tidying a pocket|place to choose today\'s color|seat where you feel the breeze|place to rest your eyes|moment you think of a friend|place to erase a short memo|spot to think of the next plan|moment of a quiet smile'**
  String get fortuneLuckyZoneBaseExtras;

  /// No description provided for @fortuneLuckyCueOpenings.
  ///
  /// In en, this message translates to:
  /// **'Briefly|Before the first start|After settling the breath|Before sending a message|Before leaving the door|Right after lifting your head|Before sitting down|When the rhythm slips|After drinking water|Before calling a name|After the first mistake|When conversation pauses|Once before choosing|When your mind rushes|After hearing a good word|Before sleeping|Before checking alerts|Before climbing the stairs|When entering a new place|While wrapping up the day'**
  String get fortuneLuckyCueOpenings;

  /// No description provided for @fortuneLuckyCueOpeningExtras.
  ///
  /// In en, this message translates to:
  /// **'Before seeing the first alert|Before lifting your bag|When you start looking for something|When your mind gets busy|When you hear a small compliment|When you want to delay a decision|When you see a new path|After washing your hands|During a short wait|When something smells good|When a familiar song plays|When choosing today\'s color|When words get stuck|When laughter comes out|When you see something to tidy|When the answer you waited for arrives|When you are briefly alone|Right before going outside|After coming home|Before turning off the last light'**
  String get fortuneLuckyCueOpeningExtras;

  /// No description provided for @fortuneLuckyCueActions.
  ///
  /// In en, this message translates to:
  /// **'check one more time|smile first|shake both hands lightly|say the first sentence short|find one thing to appreciate|bind the mind with a short breath|choose accuracy over speed|relax the shoulders|call the other person\'s name gently|make the second choice smaller|leave one memo|slow the steps a little|tidy up right after a mistake|read once before sending|think of someone to ask for help|pause before a firm answer|lift the mood with a short compliment|tidy lightly in the last 10 minutes|expect the next task first|pick one nearby color|lift your head and look slowly|clean up right after finishing|ask one question if it feels awkward|remember today\'s good scene|choose one quiet song|tidy the inside of your bag|drink one sip of water|reduce worries to three lines|look again at a pleasant photo|send one short reply first|change your seat slightly|leave one compliment in the evening'**
  String get fortuneLuckyCueActions;

  /// No description provided for @fortuneLuckyCueActionExtras.
  ///
  /// In en, this message translates to:
  /// **'choose the easiest thing first|offer a decent word first|tidy one small item|remove just one task from today|keep a favorite color close|send a short reply first|match your walking speed a little|relax your fingertips|write down a word that stands out|try a delayed thing for three minutes|look out the window once|share good news with one person|laugh off a small mistake|record the first thought|choose just one place to tidy|change posture while waiting|think of someone you appreciate|save today\'s color as a photo|ask gently about what feels off|make the last choice slowly|leave five minutes of room for the next time|save a sentence you like|check new information once|finish a regrettable thing briefly|look for a moment to yield first|do not delay a good answer too long|lighten what is in your pocket|imagine one unfamiliar choice|leave one line about what you learned today|think again in a quiet place|notice a pleasant expression|choose a small reward for the end of the day'**
  String get fortuneLuckyCueActionExtras;

  /// No description provided for @mealStatsNoTrainingOrMealEntries.
  ///
  /// In en, this message translates to:
  /// **'No training or meal entries in the selected period.'**
  String get mealStatsNoTrainingOrMealEntries;

  /// No description provided for @drawerRunningCoach.
  ///
  /// In en, this message translates to:
  /// **'Running Coach'**
  String get drawerRunningCoach;

  /// No description provided for @runningCoachScreenTitle.
  ///
  /// In en, this message translates to:
  /// **'Running Coach'**
  String get runningCoachScreenTitle;

  /// No description provided for @runningCoachHeroTitle.
  ///
  /// In en, this message translates to:
  /// **'Side-view running form coach'**
  String get runningCoachHeroTitle;

  /// No description provided for @runningCoachHeroBody.
  ///
  /// In en, this message translates to:
  /// **'Make running feel like a weapon for the next match: take a tiny football sprint mission, log a time, then use form coaching to find the next tenth of a second.'**
  String get runningCoachHeroBody;

  /// No description provided for @runningCoachSectionToday.
  ///
  /// In en, this message translates to:
  /// **'Mission'**
  String get runningCoachSectionToday;

  /// No description provided for @runningCoachSectionRecords.
  ///
  /// In en, this message translates to:
  /// **'Records'**
  String get runningCoachSectionRecords;

  /// No description provided for @runningCoachSectionAnalysis.
  ///
  /// In en, this message translates to:
  /// **'Analysis'**
  String get runningCoachSectionAnalysis;

  /// No description provided for @runningCoachTodayPlanTitle.
  ///
  /// In en, this message translates to:
  /// **'Session plan'**
  String get runningCoachTodayPlanTitle;

  /// No description provided for @runningCoachTodayPlanMissionTitle.
  ///
  /// In en, this message translates to:
  /// **'Primary sprint block'**
  String get runningCoachTodayPlanMissionTitle;

  /// No description provided for @runningCoachTodayPlanMissionBody.
  ///
  /// In en, this message translates to:
  /// **'Start with the mission below. Three sharp attempts are enough.'**
  String get runningCoachTodayPlanMissionBody;

  /// No description provided for @runningCoachTodayPlanRecordTitle.
  ///
  /// In en, this message translates to:
  /// **'Performance log'**
  String get runningCoachTodayPlanRecordTitle;

  /// No description provided for @runningCoachTodayPlanRecordBody.
  ///
  /// In en, this message translates to:
  /// **'After running, move to Records and enter only the fastest attempt.'**
  String get runningCoachTodayPlanRecordBody;

  /// No description provided for @runningCoachTodayPlanAnalysisTitle.
  ///
  /// In en, this message translates to:
  /// **'Form review trigger'**
  String get runningCoachTodayPlanAnalysisTitle;

  /// No description provided for @runningCoachTodayPlanAnalysisBody.
  ///
  /// In en, this message translates to:
  /// **'Use Analysis when the start feels slow, heavy, or different from the best run.'**
  String get runningCoachTodayPlanAnalysisBody;

  /// No description provided for @runningCoachTodayPlanRecordAction.
  ///
  /// In en, this message translates to:
  /// **'Go to records'**
  String get runningCoachTodayPlanRecordAction;

  /// No description provided for @runningCoachTodayPlanAnalysisAction.
  ///
  /// In en, this message translates to:
  /// **'Go to analysis'**
  String get runningCoachTodayPlanAnalysisAction;

  /// No description provided for @runningCoachRecordsPlanTitle.
  ///
  /// In en, this message translates to:
  /// **'Timing protocol'**
  String get runningCoachRecordsPlanTitle;

  /// No description provided for @runningCoachRecordsPlanDistanceTitle.
  ///
  /// In en, this message translates to:
  /// **'Choose the distance'**
  String get runningCoachRecordsPlanDistanceTitle;

  /// No description provided for @runningCoachRecordsPlanDistanceBody.
  ///
  /// In en, this message translates to:
  /// **'Pick 10m, 20m, or 30m to match the sprint you just ran.'**
  String get runningCoachRecordsPlanDistanceBody;

  /// No description provided for @runningCoachRecordsPlanSecondsTitle.
  ///
  /// In en, this message translates to:
  /// **'Enter seconds'**
  String get runningCoachRecordsPlanSecondsTitle;

  /// No description provided for @runningCoachRecordsPlanSecondsBody.
  ///
  /// In en, this message translates to:
  /// **'Use the stopwatch time in seconds, then save it as today\'s best attempt.'**
  String get runningCoachRecordsPlanSecondsBody;

  /// No description provided for @runningCoachRecordsPlanCompareTitle.
  ///
  /// In en, this message translates to:
  /// **'Chase the previous runner'**
  String get runningCoachRecordsPlanCompareTitle;

  /// No description provided for @runningCoachRecordsPlanCompareBody.
  ///
  /// In en, this message translates to:
  /// **'The app compares the saved time with the previous best so the next target is clear.'**
  String get runningCoachRecordsPlanCompareBody;

  /// No description provided for @runningCoachAnalysisPlanTitle.
  ///
  /// In en, this message translates to:
  /// **'Video analysis protocol'**
  String get runningCoachAnalysisPlanTitle;

  /// No description provided for @runningCoachAnalysisPlanRecordTitle.
  ///
  /// In en, this message translates to:
  /// **'Record a side view'**
  String get runningCoachAnalysisPlanRecordTitle;

  /// No description provided for @runningCoachAnalysisPlanRecordBody.
  ///
  /// In en, this message translates to:
  /// **'Keep the full body in frame from the side for a few running steps.'**
  String get runningCoachAnalysisPlanRecordBody;

  /// No description provided for @runningCoachAnalysisPlanSampleTitle.
  ///
  /// In en, this message translates to:
  /// **'Check the sample first'**
  String get runningCoachAnalysisPlanSampleTitle;

  /// No description provided for @runningCoachAnalysisPlanSampleBody.
  ///
  /// In en, this message translates to:
  /// **'Open the sample guide if you want to see what the app compares before uploading.'**
  String get runningCoachAnalysisPlanSampleBody;

  /// No description provided for @runningCoachAnalysisPlanAnalyzeTitle.
  ///
  /// In en, this message translates to:
  /// **'Pick and analyze'**
  String get runningCoachAnalysisPlanAnalyzeTitle;

  /// No description provided for @runningCoachAnalysisPlanAnalyzeBody.
  ///
  /// In en, this message translates to:
  /// **'Choose the video, run analysis, then start with the first focus cue.'**
  String get runningCoachAnalysisPlanAnalyzeBody;

  /// No description provided for @runningCoachControlPanelTitle.
  ///
  /// In en, this message translates to:
  /// **'Coach checkpoint'**
  String get runningCoachControlPanelTitle;

  /// No description provided for @runningCoachControlPanelLoadLabel.
  ///
  /// In en, this message translates to:
  /// **'Load'**
  String get runningCoachControlPanelLoadLabel;

  /// No description provided for @runningCoachControlPanelLoadValue.
  ///
  /// In en, this message translates to:
  /// **'3 quality reps'**
  String get runningCoachControlPanelLoadValue;

  /// No description provided for @runningCoachControlPanelDistanceLabel.
  ///
  /// In en, this message translates to:
  /// **'Distance'**
  String get runningCoachControlPanelDistanceLabel;

  /// No description provided for @runningCoachControlPanelDistanceValue.
  ///
  /// In en, this message translates to:
  /// **'{meters}m focus'**
  String runningCoachControlPanelDistanceValue(int meters);

  /// No description provided for @runningCoachControlPanelRecordLabel.
  ///
  /// In en, this message translates to:
  /// **'Log'**
  String get runningCoachControlPanelRecordLabel;

  /// No description provided for @runningCoachControlPanelRecordValue.
  ///
  /// In en, this message translates to:
  /// **'Best attempt only'**
  String get runningCoachControlPanelRecordValue;

  /// No description provided for @runningCoachControlPanelReviewLabel.
  ///
  /// In en, this message translates to:
  /// **'Review'**
  String get runningCoachControlPanelReviewLabel;

  /// No description provided for @runningCoachControlPanelReviewValue.
  ///
  /// In en, this message translates to:
  /// **'Side-view if needed'**
  String get runningCoachControlPanelReviewValue;

  /// No description provided for @runningCoachMissionCardTitle.
  ///
  /// In en, this message translates to:
  /// **'Today\'s speed mission'**
  String get runningCoachMissionCardTitle;

  /// No description provided for @runningCoachMissionDistance.
  ///
  /// In en, this message translates to:
  /// **'{meters}m mission'**
  String runningCoachMissionDistance(int meters);

  /// No description provided for @runningCoachMissionStartSprint.
  ///
  /// In en, this message translates to:
  /// **'Start sprint coach'**
  String get runningCoachMissionStartSprint;

  /// No description provided for @runningCoachMissionStartLive.
  ///
  /// In en, this message translates to:
  /// **'Check form live'**
  String get runningCoachMissionStartLive;

  /// No description provided for @runningCoachMissionBreakawayTitle.
  ///
  /// In en, this message translates to:
  /// **'Break the defensive line'**
  String get runningCoachMissionBreakawayTitle;

  /// No description provided for @runningCoachMissionBreakawayBody.
  ///
  /// In en, this message translates to:
  /// **'Run 20m as if you are attacking the space behind the back line. Keep it to three sharp attempts.'**
  String get runningCoachMissionBreakawayBody;

  /// No description provided for @runningCoachMissionBreakawayFocus.
  ///
  /// In en, this message translates to:
  /// **'First 3 steps'**
  String get runningCoachMissionBreakawayFocus;

  /// No description provided for @runningCoachMissionBreakawayReward.
  ///
  /// In en, this message translates to:
  /// **'Beat yesterday\'s start'**
  String get runningCoachMissionBreakawayReward;

  /// No description provided for @runningCoachMissionPressureTitle.
  ///
  /// In en, this message translates to:
  /// **'Escape pressure'**
  String get runningCoachMissionPressureTitle;

  /// No description provided for @runningCoachMissionPressureBody.
  ///
  /// In en, this message translates to:
  /// **'Turn out of pressure and burst for 10m. The goal is a fast first push, not a long workout.'**
  String get runningCoachMissionPressureBody;

  /// No description provided for @runningCoachMissionPressureFocus.
  ///
  /// In en, this message translates to:
  /// **'Low body lean'**
  String get runningCoachMissionPressureFocus;

  /// No description provided for @runningCoachMissionPressureReward.
  ///
  /// In en, this message translates to:
  /// **'Sharper getaway'**
  String get runningCoachMissionPressureReward;

  /// No description provided for @runningCoachMissionLooseBallTitle.
  ///
  /// In en, this message translates to:
  /// **'Win the loose ball'**
  String get runningCoachMissionLooseBallTitle;

  /// No description provided for @runningCoachMissionLooseBallBody.
  ///
  /// In en, this message translates to:
  /// **'Chase a 30m loose ball with match energy. Log the best attempt and try to trim one small piece off it next time.'**
  String get runningCoachMissionLooseBallBody;

  /// No description provided for @runningCoachMissionLooseBallFocus.
  ///
  /// In en, this message translates to:
  /// **'Hold speed late'**
  String get runningCoachMissionLooseBallFocus;

  /// No description provided for @runningCoachMissionLooseBallReward.
  ///
  /// In en, this message translates to:
  /// **'New chase target'**
  String get runningCoachMissionLooseBallReward;

  /// No description provided for @runningCoachMissionFirstStepsTitle.
  ///
  /// In en, this message translates to:
  /// **'Own the first three steps'**
  String get runningCoachMissionFirstStepsTitle;

  /// No description provided for @runningCoachMissionFirstStepsBody.
  ///
  /// In en, this message translates to:
  /// **'Sprint only the first 10m and stop. Make the start feel quick, light, and repeatable.'**
  String get runningCoachMissionFirstStepsBody;

  /// No description provided for @runningCoachMissionFirstStepsFocus.
  ///
  /// In en, this message translates to:
  /// **'Explosive start'**
  String get runningCoachMissionFirstStepsFocus;

  /// No description provided for @runningCoachMissionFirstStepsReward.
  ///
  /// In en, this message translates to:
  /// **'Start badge progress'**
  String get runningCoachMissionFirstStepsReward;

  /// No description provided for @runningCoachGrowthTitle.
  ///
  /// In en, this message translates to:
  /// **'Beat your own runner'**
  String get runningCoachGrowthTitle;

  /// No description provided for @runningCoachGrowthBody.
  ///
  /// In en, this message translates to:
  /// **'Record simple 10m, 20m, and 30m times. The app celebrates personal bests, streaks, and steady attempts so running stays fun even before a new record.'**
  String get runningCoachGrowthBody;

  /// No description provided for @runningCoachGrowthAttemptsLabel.
  ///
  /// In en, this message translates to:
  /// **'Attempts'**
  String get runningCoachGrowthAttemptsLabel;

  /// No description provided for @runningCoachGrowthAttempts.
  ///
  /// In en, this message translates to:
  /// **'{count} total'**
  String runningCoachGrowthAttempts(int count);

  /// No description provided for @runningCoachGrowthStreakLabel.
  ///
  /// In en, this message translates to:
  /// **'Streak'**
  String get runningCoachGrowthStreakLabel;

  /// No description provided for @runningCoachGrowthStreak.
  ///
  /// In en, this message translates to:
  /// **'{count} days'**
  String runningCoachGrowthStreak(int count);

  /// No description provided for @runningCoachGrowthDistancesLabel.
  ///
  /// In en, this message translates to:
  /// **'Distances'**
  String get runningCoachGrowthDistancesLabel;

  /// No description provided for @runningCoachGrowthDistances.
  ///
  /// In en, this message translates to:
  /// **'{count}/3 logged'**
  String runningCoachGrowthDistances(int count);

  /// No description provided for @runningCoachRecordInputTitle.
  ///
  /// In en, this message translates to:
  /// **'Log a sprint time'**
  String get runningCoachRecordInputTitle;

  /// No description provided for @runningCoachRecordDistance.
  ///
  /// In en, this message translates to:
  /// **'{meters}m'**
  String runningCoachRecordDistance(int meters);

  /// No description provided for @runningCoachRecordSecondsLabel.
  ///
  /// In en, this message translates to:
  /// **'Time'**
  String get runningCoachRecordSecondsLabel;

  /// No description provided for @runningCoachRecordSecondsHint.
  ///
  /// In en, this message translates to:
  /// **'Example 4.32'**
  String get runningCoachRecordSecondsHint;

  /// No description provided for @runningCoachRecordSecondsSuffix.
  ///
  /// In en, this message translates to:
  /// **'sec'**
  String get runningCoachRecordSecondsSuffix;

  /// No description provided for @runningCoachRecordSaveAction.
  ///
  /// In en, this message translates to:
  /// **'Save time'**
  String get runningCoachRecordSaveAction;

  /// No description provided for @runningCoachRecordInvalid.
  ///
  /// In en, this message translates to:
  /// **'Enter a sprint time between 0 and 60 seconds.'**
  String get runningCoachRecordInvalid;

  /// No description provided for @runningCoachRecordSaved.
  ///
  /// In en, this message translates to:
  /// **'Sprint time saved.'**
  String get runningCoachRecordSaved;

  /// No description provided for @runningCoachRecordEmpty.
  ///
  /// In en, this message translates to:
  /// **'No time yet'**
  String get runningCoachRecordEmpty;

  /// No description provided for @runningCoachRecordSecondsValue.
  ///
  /// In en, this message translates to:
  /// **'{seconds}s'**
  String runningCoachRecordSecondsValue(String seconds);

  /// No description provided for @runningCoachGhostEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'Create your first ghost runner'**
  String get runningCoachGhostEmptyTitle;

  /// No description provided for @runningCoachGhostEmptyBody.
  ///
  /// In en, this message translates to:
  /// **'Run once and save the time. Next time, the target is simply to catch your own previous run.'**
  String get runningCoachGhostEmptyBody;

  /// No description provided for @runningCoachGhostTitle.
  ///
  /// In en, this message translates to:
  /// **'{meters}m ghost runner'**
  String runningCoachGhostTitle(int meters);

  /// No description provided for @runningCoachGhostFirstRecordBody.
  ///
  /// In en, this message translates to:
  /// **'Your first target is {seconds}s. Try to trim just 0.05s next time.'**
  String runningCoachGhostFirstRecordBody(String seconds);

  /// No description provided for @runningCoachGhostImprovedBody.
  ///
  /// In en, this message translates to:
  /// **'Personal best by {seconds}s. Save this feeling and try to repeat it once.'**
  String runningCoachGhostImprovedBody(String seconds);

  /// No description provided for @runningCoachGhostChaseBody.
  ///
  /// In en, this message translates to:
  /// **'You are {seconds}s away from the best ghost. One cleaner start can close that gap.'**
  String runningCoachGhostChaseBody(String seconds);

  /// No description provided for @runningCoachBadgesTitle.
  ///
  /// In en, this message translates to:
  /// **'Running badges'**
  String get runningCoachBadgesTitle;

  /// No description provided for @runningCoachBadgeFirstRun.
  ///
  /// In en, this message translates to:
  /// **'First sprint'**
  String get runningCoachBadgeFirstRun;

  /// No description provided for @runningCoachBadgeRecordBreaker.
  ///
  /// In en, this message translates to:
  /// **'Record breaker'**
  String get runningCoachBadgeRecordBreaker;

  /// No description provided for @runningCoachBadgeThreeDaySpark.
  ///
  /// In en, this message translates to:
  /// **'3-day spark'**
  String get runningCoachBadgeThreeDaySpark;

  /// No description provided for @runningCoachBadgeAllRounder.
  ///
  /// In en, this message translates to:
  /// **'10/20/30m runner'**
  String get runningCoachBadgeAllRounder;

  /// No description provided for @runningCoachAnalyzeBody.
  ///
  /// In en, this message translates to:
  /// **'Choose a side-view clip to see the score, measured joint angles, contact cues, and the first movement issue to fix.'**
  String get runningCoachAnalyzeBody;

  /// No description provided for @runningCoachTipsTitle.
  ///
  /// In en, this message translates to:
  /// **'How to record'**
  String get runningCoachTipsTitle;

  /// No description provided for @runningCoachTipWholeBody.
  ///
  /// In en, this message translates to:
  /// **'Keep the full body in frame from head to foot strike, with shoulders, hips, knees, ankles, elbows, and wrists visible.'**
  String get runningCoachTipWholeBody;

  /// No description provided for @runningCoachTipSideView.
  ///
  /// In en, this message translates to:
  /// **'Record from a true side view while the runner moves across the frame, not toward or away from the camera.'**
  String get runningCoachTipSideView;

  /// No description provided for @runningCoachTipSteadyCamera.
  ///
  /// In en, this message translates to:
  /// **'Use a steady camera, bright even light, and capture 5-15 seconds with at least 3 clean strides.'**
  String get runningCoachTipSteadyCamera;

  /// No description provided for @runningCoachUploadGuideTitle.
  ///
  /// In en, this message translates to:
  /// **'Video upload guide'**
  String get runningCoachUploadGuideTitle;

  /// No description provided for @runningCoachUploadGuideBody.
  ///
  /// In en, this message translates to:
  /// **'Open the sample guide to compare a good loop with a wrong-form loop and see exactly which joints, angles, and contact points the coach reads.'**
  String get runningCoachUploadGuideBody;

  /// No description provided for @runningCoachUploadGuideStepSide.
  ///
  /// In en, this message translates to:
  /// **'Set the phone square to the running lane at hip height, then film the runner moving left-to-right or right-to-left.'**
  String get runningCoachUploadGuideStepSide;

  /// No description provided for @runningCoachUploadGuideStepDistance.
  ///
  /// In en, this message translates to:
  /// **'Leave space in front and behind the runner so the head, hips, knees, ankles, feet, elbows, and wrists stay visible on every step.'**
  String get runningCoachUploadGuideStepDistance;

  /// No description provided for @runningCoachUploadGuideStepDuration.
  ///
  /// In en, this message translates to:
  /// **'Use a 5-15 second clip with 3-6 clean strides, then trim away walking setup, turns, and stopped frames.'**
  String get runningCoachUploadGuideStepDuration;

  /// No description provided for @runningCoachUploadGuideStepLight.
  ///
  /// In en, this message translates to:
  /// **'Record in bright, even light with a plain background; avoid shadows, cropped feet, and people crossing behind the runner.'**
  String get runningCoachUploadGuideStepLight;

  /// No description provided for @runningCoachSampleTitle.
  ///
  /// In en, this message translates to:
  /// **'Sample video guide'**
  String get runningCoachSampleTitle;

  /// No description provided for @runningCoachSampleBody.
  ///
  /// In en, this message translates to:
  /// **'Switch between the reference and wrong-form loops to see how the same coach reads posture, landing, knee load, arm angle, bounce, and frame quality.'**
  String get runningCoachSampleBody;

  /// No description provided for @runningCoachSampleGuideAction.
  ///
  /// In en, this message translates to:
  /// **'Open sample video guide'**
  String get runningCoachSampleGuideAction;

  /// No description provided for @runningCoachSampleFrameLabel.
  ///
  /// In en, this message translates to:
  /// **'Frame {current}/{total}'**
  String runningCoachSampleFrameLabel(int current, int total);

  /// No description provided for @runningCoachSampleFrameGuideTitle.
  ///
  /// In en, this message translates to:
  /// **'What to compare in the video'**
  String get runningCoachSampleFrameGuideTitle;

  /// No description provided for @runningCoachSampleFrameGuideBody.
  ///
  /// In en, this message translates to:
  /// **'Read the overlays with the runner: posture, landing, arm timing, and frame coverage are shown on top of the sample instead of only as a text list.'**
  String get runningCoachSampleFrameGuideBody;

  /// No description provided for @runningCoachSampleCueLean.
  ///
  /// In en, this message translates to:
  /// **'Hip-to-shoulder lean compared with the vertical hip line'**
  String get runningCoachSampleCueLean;

  /// No description provided for @runningCoachSampleCueFrame.
  ///
  /// In en, this message translates to:
  /// **'Head, hips, knees, and feet stay visible'**
  String get runningCoachSampleCueFrame;

  /// No description provided for @runningCoachSampleCueFoot.
  ///
  /// In en, this message translates to:
  /// **'Foot lands under the hip with toes forward'**
  String get runningCoachSampleCueFoot;

  /// No description provided for @runningCoachSampleCueArms.
  ///
  /// In en, this message translates to:
  /// **'Elbows stay bent and swing opposite the legs'**
  String get runningCoachSampleCueArms;

  /// No description provided for @runningCoachSampleReferenceTab.
  ///
  /// In en, this message translates to:
  /// **'Reference sample'**
  String get runningCoachSampleReferenceTab;

  /// No description provided for @runningCoachSampleMistakeTab.
  ///
  /// In en, this message translates to:
  /// **'Wrong form sample'**
  String get runningCoachSampleMistakeTab;

  /// No description provided for @runningCoachSampleReferenceTitle.
  ///
  /// In en, this message translates to:
  /// **'Reference readouts'**
  String get runningCoachSampleReferenceTitle;

  /// No description provided for @runningCoachSampleMistakeTitle.
  ///
  /// In en, this message translates to:
  /// **'Wrong-form readouts'**
  String get runningCoachSampleMistakeTitle;

  /// No description provided for @runningCoachSampleReferenceBody.
  ///
  /// In en, this message translates to:
  /// **'This is the target loop: the runner keeps a slight whole-body lean, lands close to the hip, loads the knee softly, and keeps the arms compact.'**
  String get runningCoachSampleReferenceBody;

  /// No description provided for @runningCoachSampleMistakeBody.
  ///
  /// In en, this message translates to:
  /// **'This loop shows the review pattern: upright torso, foot landing ahead of the hip, a stiff contact knee, a high arm swing, and extra vertical bounce.'**
  String get runningCoachSampleMistakeBody;

  /// No description provided for @runningCoachSampleReferencePosture.
  ///
  /// In en, this message translates to:
  /// **'Forward lean: shoulder center is 10° ahead of the vertical hip line without waist folding.'**
  String get runningCoachSampleReferencePosture;

  /// No description provided for @runningCoachSampleReferenceFoot.
  ///
  /// In en, this message translates to:
  /// **'Contact point: landing distance is 0.08, close enough to stay under the hip.'**
  String get runningCoachSampleReferenceFoot;

  /// No description provided for @runningCoachSampleReferenceKnee.
  ///
  /// In en, this message translates to:
  /// **'Stance knee: 155° at contact, softly loaded instead of locked.'**
  String get runningCoachSampleReferenceKnee;

  /// No description provided for @runningCoachSampleReferenceArms.
  ///
  /// In en, this message translates to:
  /// **'Arm angle: elbows stay near 90° and swing opposite the legs.'**
  String get runningCoachSampleReferenceArms;

  /// No description provided for @runningCoachSampleReferenceFrame.
  ///
  /// In en, this message translates to:
  /// **'Frame quality: 24/24 usable frames with all main joints visible.'**
  String get runningCoachSampleReferenceFrame;

  /// No description provided for @runningCoachSampleMistakePosture.
  ///
  /// In en, this message translates to:
  /// **'Forward lean: shoulder center is only 4° from the vertical hip line, so the runner sits tall.'**
  String get runningCoachSampleMistakePosture;

  /// No description provided for @runningCoachSampleMistakeFoot.
  ///
  /// In en, this message translates to:
  /// **'Contact point: landing is 0.20 ahead of the hip, increasing braking.'**
  String get runningCoachSampleMistakeFoot;

  /// No description provided for @runningCoachSampleMistakeKnee.
  ///
  /// In en, this message translates to:
  /// **'Stance knee: 172° at contact, too straight to absorb and push.'**
  String get runningCoachSampleMistakeKnee;

  /// No description provided for @runningCoachSampleMistakeArms.
  ///
  /// In en, this message translates to:
  /// **'Arm angle: elbows rise near 118°, making the swing high and tight.'**
  String get runningCoachSampleMistakeArms;

  /// No description provided for @runningCoachSampleMistakeBounce.
  ///
  /// In en, this message translates to:
  /// **'Bounce: vertical motion rises to 10%, wasting force upward.'**
  String get runningCoachSampleMistakeBounce;

  /// No description provided for @runningCoachSampleAnalysisMethodTitle.
  ///
  /// In en, this message translates to:
  /// **'How the coach analyzes it'**
  String get runningCoachSampleAnalysisMethodTitle;

  /// No description provided for @runningCoachSampleAnalysisMethodBody.
  ///
  /// In en, this message translates to:
  /// **'The coach samples stable side-view frames, tracks pose landmarks, estimates contact windows, and scores each metric with confidence.'**
  String get runningCoachSampleAnalysisMethodBody;

  /// No description provided for @runningCoachSampleMethodPose.
  ///
  /// In en, this message translates to:
  /// **'Pose landmarks: shoulders, hips, knees, ankles, elbows, wrists, and head must stay visible.'**
  String get runningCoachSampleMethodPose;

  /// No description provided for @runningCoachSampleMethodAngles.
  ///
  /// In en, this message translates to:
  /// **'Angles: forward lean, stance knee, and elbow carriage are measured frame by frame.'**
  String get runningCoachSampleMethodAngles;

  /// No description provided for @runningCoachSampleMethodContact.
  ///
  /// In en, this message translates to:
  /// **'Contact: the closest landing frames estimate foot strike distance from the hip line.'**
  String get runningCoachSampleMethodContact;

  /// No description provided for @runningCoachSampleMethodConfidence.
  ///
  /// In en, this message translates to:
  /// **'Confidence: low coverage or too few stable frames makes the coach warn you to recheck.'**
  String get runningCoachSampleMethodConfidence;

  /// No description provided for @runningCoachSampleRecordingGuideTitle.
  ///
  /// In en, this message translates to:
  /// **'Record like the sample'**
  String get runningCoachSampleRecordingGuideTitle;

  /// No description provided for @runningCoachSampleProcessTitle.
  ///
  /// In en, this message translates to:
  /// **'Analysis process on the real clip'**
  String get runningCoachSampleProcessTitle;

  /// No description provided for @runningCoachSampleProcessBody.
  ///
  /// In en, this message translates to:
  /// **'The overlay now shows the same order the coach follows: sample a stable frame, lock visible joints, connect the pose, measure angles, then compare contact and confidence.'**
  String get runningCoachSampleProcessBody;

  /// No description provided for @runningCoachSamplePhaseFrame.
  ///
  /// In en, this message translates to:
  /// **'Sample frame'**
  String get runningCoachSamplePhaseFrame;

  /// No description provided for @runningCoachSamplePhaseJoints.
  ///
  /// In en, this message translates to:
  /// **'Track joints'**
  String get runningCoachSamplePhaseJoints;

  /// No description provided for @runningCoachSamplePhaseMuscles.
  ///
  /// In en, this message translates to:
  /// **'Map muscle load'**
  String get runningCoachSamplePhaseMuscles;

  /// No description provided for @runningCoachSamplePhaseSkeleton.
  ///
  /// In en, this message translates to:
  /// **'Connect pose lines'**
  String get runningCoachSamplePhaseSkeleton;

  /// No description provided for @runningCoachSamplePhaseAngles.
  ///
  /// In en, this message translates to:
  /// **'Measure angles'**
  String get runningCoachSamplePhaseAngles;

  /// No description provided for @runningCoachSamplePhaseContactScore.
  ///
  /// In en, this message translates to:
  /// **'Score contact confidence'**
  String get runningCoachSamplePhaseContactScore;

  /// No description provided for @runningCoachSampleDecisionTitle.
  ///
  /// In en, this message translates to:
  /// **'Decision evidence'**
  String get runningCoachSampleDecisionTitle;

  /// No description provided for @runningCoachSampleMetricPosture.
  ///
  /// In en, this message translates to:
  /// **'Forward lean'**
  String get runningCoachSampleMetricPosture;

  /// No description provided for @runningCoachSampleMetricArms.
  ///
  /// In en, this message translates to:
  /// **'Arms'**
  String get runningCoachSampleMetricArms;

  /// No description provided for @runningCoachSampleMetricLanding.
  ///
  /// In en, this message translates to:
  /// **'Landing'**
  String get runningCoachSampleMetricLanding;

  /// No description provided for @runningCoachSampleMetricFrames.
  ///
  /// In en, this message translates to:
  /// **'Frame coverage'**
  String get runningCoachSampleMetricFrames;

  /// No description provided for @runningCoachSampleMetricBounce.
  ///
  /// In en, this message translates to:
  /// **'Bounce'**
  String get runningCoachSampleMetricBounce;

  /// No description provided for @runningCoachSampleStatusPass.
  ///
  /// In en, this message translates to:
  /// **'Pass'**
  String get runningCoachSampleStatusPass;

  /// No description provided for @runningCoachSampleStatusReview.
  ///
  /// In en, this message translates to:
  /// **'Review'**
  String get runningCoachSampleStatusReview;

  /// No description provided for @runningCoachSampleOverlayPosture.
  ///
  /// In en, this message translates to:
  /// **'Lean 10°'**
  String get runningCoachSampleOverlayPosture;

  /// No description provided for @runningCoachSampleOverlayArms.
  ///
  /// In en, this message translates to:
  /// **'Arms 90°'**
  String get runningCoachSampleOverlayArms;

  /// No description provided for @runningCoachSampleOverlayFoot.
  ///
  /// In en, this message translates to:
  /// **'Landing 0.08'**
  String get runningCoachSampleOverlayFoot;

  /// No description provided for @runningCoachSampleOverlayBounce.
  ///
  /// In en, this message translates to:
  /// **'Bounce 6%'**
  String get runningCoachSampleOverlayBounce;

  /// No description provided for @runningCoachSampleOverlayFrames.
  ///
  /// In en, this message translates to:
  /// **'24/24 frames'**
  String get runningCoachSampleOverlayFrames;

  /// No description provided for @runningCoachSampleMistakeOverlayPosture.
  ///
  /// In en, this message translates to:
  /// **'Upright 4°'**
  String get runningCoachSampleMistakeOverlayPosture;

  /// No description provided for @runningCoachSampleMistakeOverlayArms.
  ///
  /// In en, this message translates to:
  /// **'Arms 118°'**
  String get runningCoachSampleMistakeOverlayArms;

  /// No description provided for @runningCoachSampleMistakeOverlayFoot.
  ///
  /// In en, this message translates to:
  /// **'Ahead 0.20'**
  String get runningCoachSampleMistakeOverlayFoot;

  /// No description provided for @runningCoachSampleMistakeOverlayBounce.
  ///
  /// In en, this message translates to:
  /// **'Bounce 10%'**
  String get runningCoachSampleMistakeOverlayBounce;

  /// No description provided for @runningCoachSampleMetricDetailScreenTitle.
  ///
  /// In en, this message translates to:
  /// **'Evidence detail'**
  String get runningCoachSampleMetricDetailScreenTitle;

  /// No description provided for @runningCoachSampleMetricDetailHeroBody.
  ///
  /// In en, this message translates to:
  /// **'Use this view to inspect the exact body position the sample overlay reads before it assigns this evidence item.'**
  String get runningCoachSampleMetricDetailHeroBody;

  /// No description provided for @runningCoachSampleMetricDetailSampleLabel.
  ///
  /// In en, this message translates to:
  /// **'Sample'**
  String get runningCoachSampleMetricDetailSampleLabel;

  /// No description provided for @runningCoachSampleMetricDetailValueLabel.
  ///
  /// In en, this message translates to:
  /// **'Measured value'**
  String get runningCoachSampleMetricDetailValueLabel;

  /// No description provided for @runningCoachSampleMetricDetailStatusLabel.
  ///
  /// In en, this message translates to:
  /// **'Judgment'**
  String get runningCoachSampleMetricDetailStatusLabel;

  /// No description provided for @runningCoachSampleMetricDetailKeyPositionTitle.
  ///
  /// In en, this message translates to:
  /// **'Key position'**
  String get runningCoachSampleMetricDetailKeyPositionTitle;

  /// No description provided for @runningCoachSampleMetricDetailReferenceTitle.
  ///
  /// In en, this message translates to:
  /// **'Reference motion'**
  String get runningCoachSampleMetricDetailReferenceTitle;

  /// No description provided for @runningCoachSampleMetricDetailReviewTitle.
  ///
  /// In en, this message translates to:
  /// **'Review trigger'**
  String get runningCoachSampleMetricDetailReviewTitle;

  /// No description provided for @runningCoachSampleMetricDetailHowReadTitle.
  ///
  /// In en, this message translates to:
  /// **'How the overlay reads it'**
  String get runningCoachSampleMetricDetailHowReadTitle;

  /// No description provided for @runningCoachSampleMetricDetailGoodRangeTitle.
  ///
  /// In en, this message translates to:
  /// **'Good range'**
  String get runningCoachSampleMetricDetailGoodRangeTitle;

  /// No description provided for @runningCoachSamplePostureDetailGoodRange.
  ///
  /// In en, this message translates to:
  /// **'8-24° forward lean from the hip-to-shoulder center line. The sample value is 10°.'**
  String get runningCoachSamplePostureDetailGoodRange;

  /// No description provided for @runningCoachSamplePostureDetailKeyPosition.
  ///
  /// In en, this message translates to:
  /// **'Mid-stance: the app draws a vertical line up from the hip center, then compares it with the hip-to-shoulder center line.'**
  String get runningCoachSamplePostureDetailKeyPosition;

  /// No description provided for @runningCoachSamplePostureDetailReference.
  ///
  /// In en, this message translates to:
  /// **'The reference clip keeps the shoulders slightly ahead of the hips without folding at the waist.'**
  String get runningCoachSamplePostureDetailReference;

  /// No description provided for @runningCoachSamplePostureDetailReview.
  ///
  /// In en, this message translates to:
  /// **'The review clip is only 4°, below the sprint range, so the runner looks tall instead of driving forward.'**
  String get runningCoachSamplePostureDetailReview;

  /// No description provided for @runningCoachSamplePostureDetailHowRead.
  ///
  /// In en, this message translates to:
  /// **'The app averages left/right shoulders and hips, builds one trunk axis, and measures how many degrees that axis moves away from vertical.'**
  String get runningCoachSamplePostureDetailHowRead;

  /// No description provided for @runningCoachSampleArmsDetailGoodRange.
  ///
  /// In en, this message translates to:
  /// **'Elbow angle 80-105°, hands moving front-to-back near the ribs, with the opposite arm and leg paired.'**
  String get runningCoachSampleArmsDetailGoodRange;

  /// No description provided for @runningCoachSampleArmsDetailKeyPosition.
  ///
  /// In en, this message translates to:
  /// **'Arm-drive frame: each elbow angle is read while the opposite knee is driving forward.'**
  String get runningCoachSampleArmsDetailKeyPosition;

  /// No description provided for @runningCoachSampleArmsDetailReference.
  ///
  /// In en, this message translates to:
  /// **'The reference clip keeps the elbows near 90 degrees and swings front-to-back close to the ribs.'**
  String get runningCoachSampleArmsDetailReference;

  /// No description provided for @runningCoachSampleArmsDetailReview.
  ///
  /// In en, this message translates to:
  /// **'The review clip opens the elbow angle, which can slow cadence and rotate the torso.'**
  String get runningCoachSampleArmsDetailReview;

  /// No description provided for @runningCoachSampleArmsDetailHowRead.
  ///
  /// In en, this message translates to:
  /// **'The app connects shoulder, elbow, and wrist landmarks and flags the frame when the elbow opens too far.'**
  String get runningCoachSampleArmsDetailHowRead;

  /// No description provided for @runningCoachSampleLandingDetailGoodRange.
  ///
  /// In en, this message translates to:
  /// **'Foot contact within 0.00-0.10 body-length of the hip line. The sample value is 0.08.'**
  String get runningCoachSampleLandingDetailGoodRange;

  /// No description provided for @runningCoachSampleLandingDetailKeyPosition.
  ///
  /// In en, this message translates to:
  /// **'First-contact frame: the foot, ankle, and hip line show whether the step lands under the body.'**
  String get runningCoachSampleLandingDetailKeyPosition;

  /// No description provided for @runningCoachSampleLandingDetailReference.
  ///
  /// In en, this message translates to:
  /// **'The reference clip lands close to the hip line, so contact supports forward movement.'**
  String get runningCoachSampleLandingDetailReference;

  /// No description provided for @runningCoachSampleLandingDetailReview.
  ///
  /// In en, this message translates to:
  /// **'The review clip lands too far ahead of the hip, which reads as braking.'**
  String get runningCoachSampleLandingDetailReview;

  /// No description provided for @runningCoachSampleLandingDetailHowRead.
  ///
  /// In en, this message translates to:
  /// **'The app measures the horizontal gap from the hip line to the contact ankle and toe during the landing window.'**
  String get runningCoachSampleLandingDetailHowRead;

  /// No description provided for @runningCoachSampleBounceDetailGoodRange.
  ///
  /// In en, this message translates to:
  /// **'Vertical head/hip change under 7% through the stride. The sample value is 6%.'**
  String get runningCoachSampleBounceDetailGoodRange;

  /// No description provided for @runningCoachSampleBounceDetailKeyPosition.
  ///
  /// In en, this message translates to:
  /// **'Flight-to-contact window: head and hip height are compared across neighboring frames.'**
  String get runningCoachSampleBounceDetailKeyPosition;

  /// No description provided for @runningCoachSampleBounceDetailReference.
  ///
  /// In en, this message translates to:
  /// **'The reference clip keeps vertical motion compact, so energy stays directed forward.'**
  String get runningCoachSampleBounceDetailReference;

  /// No description provided for @runningCoachSampleBounceDetailReview.
  ///
  /// In en, this message translates to:
  /// **'The review clip rises and drops more, making contact timing less stable.'**
  String get runningCoachSampleBounceDetailReview;

  /// No description provided for @runningCoachSampleBounceDetailHowRead.
  ///
  /// In en, this message translates to:
  /// **'The app tracks the head and hip height band through the stride and scores the vertical change ratio.'**
  String get runningCoachSampleBounceDetailHowRead;

  /// No description provided for @runningCoachLiveCardTitle.
  ///
  /// In en, this message translates to:
  /// **'Live coach'**
  String get runningCoachLiveCardTitle;

  /// No description provided for @runningCoachLiveCardBody.
  ///
  /// In en, this message translates to:
  /// **'Track the runner outline and pose line live, then switch straight into sprint-specific feedback for trunk lean, knee drive, step rhythm, and arm balance.'**
  String get runningCoachLiveCardBody;

  /// No description provided for @runningCoachLiveAction.
  ///
  /// In en, this message translates to:
  /// **'Start live coach'**
  String get runningCoachLiveAction;

  /// No description provided for @runningCoachLiveGuideAction.
  ///
  /// In en, this message translates to:
  /// **'Shooting guide'**
  String get runningCoachLiveGuideAction;

  /// No description provided for @runningCoachLiveScreenTitle.
  ///
  /// In en, this message translates to:
  /// **'Live running coach'**
  String get runningCoachLiveScreenTitle;

  /// No description provided for @runningCoachLiveGuideScreenTitle.
  ///
  /// In en, this message translates to:
  /// **'Live shooting guide'**
  String get runningCoachLiveGuideScreenTitle;

  /// No description provided for @runningCoachLiveGuideHeroTitle.
  ///
  /// In en, this message translates to:
  /// **'Track the runner outline and read the lower coaching panel together'**
  String get runningCoachLiveGuideHeroTitle;

  /// No description provided for @runningCoachLiveGuideHeroBody.
  ///
  /// In en, this message translates to:
  /// **'The live coach now marks the runner outline and pose line directly on screen, while the lower panel keeps the explanation and results together. Use the setup below to keep tracking and feedback stable.'**
  String get runningCoachLiveGuideHeroBody;

  /// No description provided for @runningCoachLiveGuideTipSideTitle.
  ///
  /// In en, this message translates to:
  /// **'Show a side view'**
  String get runningCoachLiveGuideTipSideTitle;

  /// No description provided for @runningCoachLiveGuideTipSideBody.
  ///
  /// In en, this message translates to:
  /// **'The runner should move across the frame from the side, not straight toward the camera or on a heavy diagonal.'**
  String get runningCoachLiveGuideTipSideBody;

  /// No description provided for @runningCoachLiveGuideTipBodyTitle.
  ///
  /// In en, this message translates to:
  /// **'Keep the full body in frame'**
  String get runningCoachLiveGuideTipBodyTitle;

  /// No description provided for @runningCoachLiveGuideTipBodyBody.
  ///
  /// In en, this message translates to:
  /// **'The head, elbows, hips, and ankles all need to stay visible so the pose line and score can stay stable.'**
  String get runningCoachLiveGuideTipBodyBody;

  /// No description provided for @runningCoachLiveGuideTipHudTitle.
  ///
  /// In en, this message translates to:
  /// **'Read the top cue and lower results together'**
  String get runningCoachLiveGuideTipHudTitle;

  /// No description provided for @runningCoachLiveGuideTipHudBody.
  ///
  /// In en, this message translates to:
  /// **'Instead of a yellow box, the screen leads with the top status cue and runner outline marking, while the lower panel keeps the why, the fix, and the body-part results together.'**
  String get runningCoachLiveGuideTipHudBody;

  /// No description provided for @runningCoachLiveGuideTipCameraTitle.
  ///
  /// In en, this message translates to:
  /// **'Keep the camera fixed and the body large enough'**
  String get runningCoachLiveGuideTipCameraTitle;

  /// No description provided for @runningCoachLiveGuideTipCameraBody.
  ///
  /// In en, this message translates to:
  /// **'Hold the camera steady and frame the runner so the full body fills at least about half of the screen height. The fuller the frame, the steadier the pose line and voice coaching become.'**
  String get runningCoachLiveGuideTipCameraBody;

  /// No description provided for @runningCoachLivePreparingTitle.
  ///
  /// In en, this message translates to:
  /// **'Preparing camera'**
  String get runningCoachLivePreparingTitle;

  /// No description provided for @runningCoachLivePreparingBody.
  ///
  /// In en, this message translates to:
  /// **'Opening the rear camera and getting live pose tracking ready.'**
  String get runningCoachLivePreparingBody;

  /// No description provided for @runningCoachLiveCameraIssueTitle.
  ///
  /// In en, this message translates to:
  /// **'Camera check needed'**
  String get runningCoachLiveCameraIssueTitle;

  /// No description provided for @runningCoachLiveCameraDenied.
  ///
  /// In en, this message translates to:
  /// **'Camera access is required for live running coaching.'**
  String get runningCoachLiveCameraDenied;

  /// No description provided for @runningCoachLiveCameraFailed.
  ///
  /// In en, this message translates to:
  /// **'The live coach camera could not be opened. Try again.'**
  String get runningCoachLiveCameraFailed;

  /// No description provided for @runningCoachLiveRetryAction.
  ///
  /// In en, this message translates to:
  /// **'Try again'**
  String get runningCoachLiveRetryAction;

  /// No description provided for @runningCoachLiveVoiceOn.
  ///
  /// In en, this message translates to:
  /// **'Voice coaching on'**
  String get runningCoachLiveVoiceOn;

  /// No description provided for @runningCoachLiveVoiceOff.
  ///
  /// In en, this message translates to:
  /// **'Voice coaching off'**
  String get runningCoachLiveVoiceOff;

  /// No description provided for @runningCoachLiveSwitchCamera.
  ///
  /// In en, this message translates to:
  /// **'Switch camera'**
  String get runningCoachLiveSwitchCamera;

  /// No description provided for @runningCoachLiveStatusFraming.
  ///
  /// In en, this message translates to:
  /// **'Fix the framing first'**
  String get runningCoachLiveStatusFraming;

  /// No description provided for @runningCoachLiveStatusCollecting.
  ///
  /// In en, this message translates to:
  /// **'Collecting movement'**
  String get runningCoachLiveStatusCollecting;

  /// No description provided for @runningCoachLiveStatusCoaching.
  ///
  /// In en, this message translates to:
  /// **'Live coaching active'**
  String get runningCoachLiveStatusCoaching;

  /// No description provided for @runningCoachLiveCueNoRunner.
  ///
  /// In en, this message translates to:
  /// **'The runner is not clear enough yet. Step into the frame.'**
  String get runningCoachLiveCueNoRunner;

  /// No description provided for @runningCoachLiveCueStepBack.
  ///
  /// In en, this message translates to:
  /// **'Step back and fit the whole body in frame from head to toe.'**
  String get runningCoachLiveCueStepBack;

  /// No description provided for @runningCoachLiveCueMoveCloser.
  ///
  /// In en, this message translates to:
  /// **'The runner looks too small. Move a bit closer to the camera.'**
  String get runningCoachLiveCueMoveCloser;

  /// No description provided for @runningCoachLiveCueCenterRunner.
  ///
  /// In en, this message translates to:
  /// **'Center the runner more clearly in the frame.'**
  String get runningCoachLiveCueCenterRunner;

  /// No description provided for @runningCoachLiveCueTurnSideways.
  ///
  /// In en, this message translates to:
  /// **'Turn more to the side so the running shape is easier to read.'**
  String get runningCoachLiveCueTurnSideways;

  /// No description provided for @runningCoachLiveCueKeepRunning.
  ///
  /// In en, this message translates to:
  /// **'Good. Keep the same rhythm for a few more steps and coaching will appear.'**
  String get runningCoachLiveCueKeepRunning;

  /// No description provided for @runningCoachLiveCueLookingGood.
  ///
  /// In en, this message translates to:
  /// **'Good. Keep this rhythm and hold the same shape.'**
  String get runningCoachLiveCueLookingGood;

  /// No description provided for @runningCoachLiveTrackedFrames.
  ///
  /// In en, this message translates to:
  /// **'Tracked frames {count}'**
  String runningCoachLiveTrackedFrames(int count);

  /// No description provided for @runningCoachLiveScorePending.
  ///
  /// In en, this message translates to:
  /// **'Scoring...'**
  String get runningCoachLiveScorePending;

  /// No description provided for @runningCoachLiveOverallScore.
  ///
  /// In en, this message translates to:
  /// **'Live score {score}/100'**
  String runningCoachLiveOverallScore(int score);

  /// No description provided for @runningCoachLiveGuidanceTitle.
  ///
  /// In en, this message translates to:
  /// **'Current guidance'**
  String get runningCoachLiveGuidanceTitle;

  /// No description provided for @runningCoachSprintLiveCardTitle.
  ///
  /// In en, this message translates to:
  /// **'Live sprint coaching'**
  String get runningCoachSprintLiveCardTitle;

  /// No description provided for @runningCoachSprintLiveCardBody.
  ///
  /// In en, this message translates to:
  /// **'Use the side-view camera to check full-body capture first, then show trunk, knee, and rhythm cues only when joint confidence is stable.'**
  String get runningCoachSprintLiveCardBody;

  /// No description provided for @runningCoachSprintLiveAction.
  ///
  /// In en, this message translates to:
  /// **'Start sprint coaching'**
  String get runningCoachSprintLiveAction;

  /// No description provided for @runningCoachSprintLiveScreenTitle.
  ///
  /// In en, this message translates to:
  /// **'Live sprint coaching'**
  String get runningCoachSprintLiveScreenTitle;

  /// No description provided for @runningCoachSprintLiveStatusLowConfidence.
  ///
  /// In en, this message translates to:
  /// **'Fix full-body framing first'**
  String get runningCoachSprintLiveStatusLowConfidence;

  /// No description provided for @runningCoachSprintLiveStatusCollecting.
  ///
  /// In en, this message translates to:
  /// **'Stabilizing sprint rhythm'**
  String get runningCoachSprintLiveStatusCollecting;

  /// No description provided for @runningCoachSprintLiveStatusReady.
  ///
  /// In en, this message translates to:
  /// **'Live feedback ready'**
  String get runningCoachSprintLiveStatusReady;

  /// No description provided for @runningCoachSprintLiveStatusCoaching.
  ///
  /// In en, this message translates to:
  /// **'Live sprint feedback active'**
  String get runningCoachSprintLiveStatusCoaching;

  /// No description provided for @runningCoachSprintLiveCueCollecting.
  ///
  /// In en, this message translates to:
  /// **'Hold a few more steps so rhythm and knee-drive readings can settle.'**
  String get runningCoachSprintLiveCueCollecting;

  /// No description provided for @runningCoachSprintLiveCueReady.
  ///
  /// In en, this message translates to:
  /// **'Good. Keep this shape and sprint for another 5-10 seconds.'**
  String get runningCoachSprintLiveCueReady;

  /// No description provided for @runningCoachSprintGuideSideCapture.
  ///
  /// In en, this message translates to:
  /// **'Keep a clear side view'**
  String get runningCoachSprintGuideSideCapture;

  /// No description provided for @runningCoachSprintGuideFullBodyFraming.
  ///
  /// In en, this message translates to:
  /// **'Keep the full body inside the frame'**
  String get runningCoachSprintGuideFullBodyFraming;

  /// No description provided for @runningCoachSprintTrackingConfidenceValue.
  ///
  /// In en, this message translates to:
  /// **'Tracking {percent}%'**
  String runningCoachSprintTrackingConfidenceValue(int percent);

  /// No description provided for @runningCoachSprintTrackedFrames.
  ///
  /// In en, this message translates to:
  /// **'Tracked {count} frames'**
  String runningCoachSprintTrackedFrames(int count);

  /// No description provided for @runningCoachSprintDetectedSteps.
  ///
  /// In en, this message translates to:
  /// **'Step events {count}'**
  String runningCoachSprintDetectedSteps(int count);

  /// No description provided for @runningCoachSprintQualityTitle.
  ///
  /// In en, this message translates to:
  /// **'Capture confidence'**
  String get runningCoachSprintQualityTitle;

  /// No description provided for @runningCoachSprintQualityScore.
  ///
  /// In en, this message translates to:
  /// **'{score}%'**
  String runningCoachSprintQualityScore(int score);

  /// No description provided for @runningCoachSprintQualityReviewReady.
  ///
  /// In en, this message translates to:
  /// **'Saved review ready'**
  String get runningCoachSprintQualityReviewReady;

  /// No description provided for @runningCoachSprintQualityLiveReady.
  ///
  /// In en, this message translates to:
  /// **'Stable cue ready'**
  String get runningCoachSprintQualityLiveReady;

  /// No description provided for @runningCoachSprintQualitySetupNeeded.
  ///
  /// In en, this message translates to:
  /// **'Adjust capture setup'**
  String get runningCoachSprintQualitySetupNeeded;

  /// No description provided for @runningCoachSprintQualityGateFullBody.
  ///
  /// In en, this message translates to:
  /// **'Full-body joints'**
  String get runningCoachSprintQualityGateFullBody;

  /// No description provided for @runningCoachSprintQualityGateSize.
  ///
  /// In en, this message translates to:
  /// **'Runner size'**
  String get runningCoachSprintQualityGateSize;

  /// No description provided for @runningCoachSprintQualityGateSideView.
  ///
  /// In en, this message translates to:
  /// **'Side view'**
  String get runningCoachSprintQualityGateSideView;

  /// No description provided for @runningCoachSprintQualityGateConfidence.
  ///
  /// In en, this message translates to:
  /// **'Joint confidence'**
  String get runningCoachSprintQualityGateConfidence;

  /// No description provided for @runningCoachSprintQualityGateStableFrames.
  ///
  /// In en, this message translates to:
  /// **'Stable frames'**
  String get runningCoachSprintQualityGateStableFrames;

  /// No description provided for @runningCoachSprintQualityPercentValue.
  ///
  /// In en, this message translates to:
  /// **'{percent}%'**
  String runningCoachSprintQualityPercentValue(int percent);

  /// No description provided for @runningCoachSprintQualityCoreJointValue.
  ///
  /// In en, this message translates to:
  /// **'{visible}/{total}'**
  String runningCoachSprintQualityCoreJointValue(int visible, int total);

  /// No description provided for @runningCoachSprintQualitySizeValue.
  ///
  /// In en, this message translates to:
  /// **'H {heightPercent}% · A {areaPercent}%'**
  String runningCoachSprintQualitySizeValue(int heightPercent, int areaPercent);

  /// No description provided for @runningCoachSprintQualityFrameValue.
  ///
  /// In en, this message translates to:
  /// **'{count} frames'**
  String runningCoachSprintQualityFrameValue(int count);

  /// No description provided for @runningCoachSprintQualityLiveCueHint.
  ///
  /// In en, this message translates to:
  /// **'Posture cues appear only during stable capture windows.'**
  String get runningCoachSprintQualityLiveCueHint;

  /// No description provided for @runningCoachSprintQualityCaptureOnlyHint.
  ///
  /// In en, this message translates to:
  /// **'Checking capture quality now; posture scoring stays paused.'**
  String get runningCoachSprintQualityCaptureOnlyHint;

  /// No description provided for @runningCoachSprintQualityReviewReadyHint.
  ///
  /// In en, this message translates to:
  /// **'Saved-video analysis can inspect this segment in more detail.'**
  String get runningCoachSprintQualityReviewReadyHint;

  /// No description provided for @runningCoachSprintQualityReviewPendingHint.
  ///
  /// In en, this message translates to:
  /// **'Posture scoring turns on only after full body, side view, and stable frames lock.'**
  String get runningCoachSprintQualityReviewPendingHint;

  /// No description provided for @runningCoachSprintSessionLogTitle.
  ///
  /// In en, this message translates to:
  /// **'Session summary'**
  String get runningCoachSprintSessionLogTitle;

  /// No description provided for @runningCoachSprintSessionCameraFpsLabel.
  ///
  /// In en, this message translates to:
  /// **'Camera input FPS'**
  String get runningCoachSprintSessionCameraFpsLabel;

  /// No description provided for @runningCoachSprintSessionAnalyzedFpsLabel.
  ///
  /// In en, this message translates to:
  /// **'Analyzed FPS'**
  String get runningCoachSprintSessionAnalyzedFpsLabel;

  /// No description provided for @runningCoachSprintSessionAverageProcessingLabel.
  ///
  /// In en, this message translates to:
  /// **'Avg processing'**
  String get runningCoachSprintSessionAverageProcessingLabel;

  /// No description provided for @runningCoachSprintSessionAverageProcessingValue.
  ///
  /// In en, this message translates to:
  /// **'{ms}ms'**
  String runningCoachSprintSessionAverageProcessingValue(Object ms);

  /// No description provided for @runningCoachSprintSessionSkippedFramesLabel.
  ///
  /// In en, this message translates to:
  /// **'Dropped / skipped'**
  String get runningCoachSprintSessionSkippedFramesLabel;

  /// No description provided for @runningCoachSprintSessionSkippedFramesValue.
  ///
  /// In en, this message translates to:
  /// **'{count} frames'**
  String runningCoachSprintSessionSkippedFramesValue(int count);

  /// No description provided for @runningCoachSprintSessionBodyNotVisibleLabel.
  ///
  /// In en, this message translates to:
  /// **'Body loss ratio'**
  String get runningCoachSprintSessionBodyNotVisibleLabel;

  /// No description provided for @runningCoachSprintSessionBodyNotVisibleValue.
  ///
  /// In en, this message translates to:
  /// **'{percent}%'**
  String runningCoachSprintSessionBodyNotVisibleValue(int percent);

  /// No description provided for @runningCoachSprintSessionBodyVisibilityLabel.
  ///
  /// In en, this message translates to:
  /// **'Body visibility'**
  String get runningCoachSprintSessionBodyVisibilityLabel;

  /// No description provided for @runningCoachSprintSessionBodyVisibilityValue.
  ///
  /// In en, this message translates to:
  /// **'{status} · core {visible}/{total} · {percent}%'**
  String runningCoachSprintSessionBodyVisibilityValue(
      Object status, int visible, int total, int percent);

  /// No description provided for @runningCoachSprintSessionActiveFeedbackLabel.
  ///
  /// In en, this message translates to:
  /// **'Active feedback'**
  String get runningCoachSprintSessionActiveFeedbackLabel;

  /// No description provided for @runningCoachSprintSessionActiveFeedbackValue.
  ///
  /// In en, this message translates to:
  /// **'{key} · {text}'**
  String runningCoachSprintSessionActiveFeedbackValue(Object key, Object text);

  /// No description provided for @runningCoachSprintSessionFeedbackEmpty.
  ///
  /// In en, this message translates to:
  /// **'Waiting'**
  String get runningCoachSprintSessionFeedbackEmpty;

  /// No description provided for @runningCoachSprintSessionFeedbackChangesLabel.
  ///
  /// In en, this message translates to:
  /// **'Feedback changes'**
  String get runningCoachSprintSessionFeedbackChangesLabel;

  /// No description provided for @runningCoachSprintSessionFeedbackChangesValue.
  ///
  /// In en, this message translates to:
  /// **'{count} changes / {perMinute} per min · cooldown holds {suppressed}'**
  String runningCoachSprintSessionFeedbackChangesValue(
      int count, Object perMinute, int suppressed);

  /// No description provided for @runningCoachSprintSessionReadinessLabel.
  ///
  /// In en, this message translates to:
  /// **'Readiness'**
  String get runningCoachSprintSessionReadinessLabel;

  /// No description provided for @runningCoachSprintSessionReadinessValue.
  ///
  /// In en, this message translates to:
  /// **'visible {visible} · miss {missing} · stable {stable} · travel {travel}'**
  String runningCoachSprintSessionReadinessValue(
      int visible, int missing, int stable, Object travel);

  /// No description provided for @runningCoachSprintSessionStepDetectorLabel.
  ///
  /// In en, this message translates to:
  /// **'Step detector'**
  String get runningCoachSprintSessionStepDetectorLabel;

  /// No description provided for @runningCoachSprintSessionStepDetectorValue.
  ///
  /// In en, this message translates to:
  /// **'switch {switches} · ok {accepted} · lowV {lowVelocity} · gap {minInterval}'**
  String runningCoachSprintSessionStepDetectorValue(
      int switches, int accepted, int lowVelocity, int minInterval);

  /// No description provided for @runningCoachSprintSessionConfidenceLabel.
  ///
  /// In en, this message translates to:
  /// **'Landmark confidence'**
  String get runningCoachSprintSessionConfidenceLabel;

  /// No description provided for @runningCoachSprintSessionConfidenceValue.
  ///
  /// In en, this message translates to:
  /// **'0.8+ {high}% · 0.6-0.8 {medium}% · <0.6 {low}%'**
  String runningCoachSprintSessionConfidenceValue(
      int high, int medium, int low);

  /// No description provided for @runningCoachSprintMetricPending.
  ///
  /// In en, this message translates to:
  /// **'--'**
  String get runningCoachSprintMetricPending;

  /// No description provided for @runningCoachSprintMetricTrunkLabel.
  ///
  /// In en, this message translates to:
  /// **'Trunk lean'**
  String get runningCoachSprintMetricTrunkLabel;

  /// No description provided for @runningCoachSprintMetricTrunkValue.
  ///
  /// In en, this message translates to:
  /// **'{value}°'**
  String runningCoachSprintMetricTrunkValue(Object value);

  /// No description provided for @runningCoachSprintMetricKneeDriveLabel.
  ///
  /// In en, this message translates to:
  /// **'Knee drive'**
  String get runningCoachSprintMetricKneeDriveLabel;

  /// No description provided for @runningCoachSprintMetricKneeDriveValue.
  ///
  /// In en, this message translates to:
  /// **'Scale {value}%'**
  String runningCoachSprintMetricKneeDriveValue(Object value);

  /// No description provided for @runningCoachSprintMetricCadenceLabel.
  ///
  /// In en, this message translates to:
  /// **'Cadence'**
  String get runningCoachSprintMetricCadenceLabel;

  /// No description provided for @runningCoachSprintMetricCadenceValue.
  ///
  /// In en, this message translates to:
  /// **'{value} spm'**
  String runningCoachSprintMetricCadenceValue(Object value);

  /// No description provided for @runningCoachSprintMetricRhythmLabel.
  ///
  /// In en, this message translates to:
  /// **'Rhythm drift'**
  String get runningCoachSprintMetricRhythmLabel;

  /// No description provided for @runningCoachSprintMetricRhythmValue.
  ///
  /// In en, this message translates to:
  /// **'{value}ms'**
  String runningCoachSprintMetricRhythmValue(Object value);

  /// No description provided for @runningCoachSprintMetricArmBalanceLabel.
  ///
  /// In en, this message translates to:
  /// **'Arm balance'**
  String get runningCoachSprintMetricArmBalanceLabel;

  /// No description provided for @runningCoachSprintMetricArmBalanceValue.
  ///
  /// In en, this message translates to:
  /// **'Gap {value}%'**
  String runningCoachSprintMetricArmBalanceValue(Object value);

  /// No description provided for @runningCoachSprintMetricTargetRangeDegrees.
  ///
  /// In en, this message translates to:
  /// **'Target {minimum}-{maximum}°'**
  String runningCoachSprintMetricTargetRangeDegrees(int minimum, int maximum);

  /// No description provided for @runningCoachSprintMetricTargetMinimumPercent.
  ///
  /// In en, this message translates to:
  /// **'Target {percent}%+'**
  String runningCoachSprintMetricTargetMinimumPercent(int percent);

  /// No description provided for @runningCoachSprintMetricTargetMaximumMs.
  ///
  /// In en, this message translates to:
  /// **'Target <{milliseconds}ms'**
  String runningCoachSprintMetricTargetMaximumMs(int milliseconds);

  /// No description provided for @runningCoachSprintMetricTargetMaximumPercent.
  ///
  /// In en, this message translates to:
  /// **'Target <{percent}%'**
  String runningCoachSprintMetricTargetMaximumPercent(int percent);

  /// No description provided for @runningCoachSprintMetricTargetLiveReference.
  ///
  /// In en, this message translates to:
  /// **'Live reference'**
  String get runningCoachSprintMetricTargetLiveReference;

  /// No description provided for @runningCoachSprintBodyVisibilityFull.
  ///
  /// In en, this message translates to:
  /// **'Full body locked'**
  String get runningCoachSprintBodyVisibilityFull;

  /// No description provided for @runningCoachSprintBodyVisibilityPartial.
  ///
  /// In en, this message translates to:
  /// **'Partial landmarks'**
  String get runningCoachSprintBodyVisibilityPartial;

  /// No description provided for @runningCoachSprintBodyVisibilityNotVisible.
  ///
  /// In en, this message translates to:
  /// **'Body lost'**
  String get runningCoachSprintBodyVisibilityNotVisible;

  /// No description provided for @runningCoachSprintCueBodyVisible.
  ///
  /// In en, this message translates to:
  /// **'Adjust one more step so the full body stays inside the frame.'**
  String get runningCoachSprintCueBodyVisible;

  /// No description provided for @runningCoachSprintCueLeanForward.
  ///
  /// In en, this message translates to:
  /// **'Bring the shoulder center slightly ahead of the hip line without folding at the waist.'**
  String get runningCoachSprintCueLeanForward;

  /// No description provided for @runningCoachSprintCueDriveKnee.
  ///
  /// In en, this message translates to:
  /// **'After the push-off, drive the knee forward a little more aggressively.'**
  String get runningCoachSprintCueDriveKnee;

  /// No description provided for @runningCoachSprintCueKeepRhythm.
  ///
  /// In en, this message translates to:
  /// **'The left-right rhythm is drifting. Try to keep the ground contacts more even.'**
  String get runningCoachSprintCueKeepRhythm;

  /// No description provided for @runningCoachSprintCueBalanceArms.
  ///
  /// In en, this message translates to:
  /// **'The arm swing is unbalanced. Match the backward drive on both sides more closely.'**
  String get runningCoachSprintCueBalanceArms;

  /// No description provided for @runningCoachSprintCueKeepPushing.
  ///
  /// In en, this message translates to:
  /// **'Good. Keep pushing with the same rhythm and forward lean.'**
  String get runningCoachSprintCueKeepPushing;

  /// No description provided for @runningCoachSelectedVideoLabel.
  ///
  /// In en, this message translates to:
  /// **'Selected video'**
  String get runningCoachSelectedVideoLabel;

  /// No description provided for @runningCoachNoVideoSelected.
  ///
  /// In en, this message translates to:
  /// **'No video selected yet.'**
  String get runningCoachNoVideoSelected;

  /// No description provided for @runningCoachPickVideoAction.
  ///
  /// In en, this message translates to:
  /// **'Pick video'**
  String get runningCoachPickVideoAction;

  /// No description provided for @runningCoachAnalyzeAction.
  ///
  /// In en, this message translates to:
  /// **'Analyze run'**
  String get runningCoachAnalyzeAction;

  /// No description provided for @runningCoachAnalysisInProgress.
  ///
  /// In en, this message translates to:
  /// **'Analyzing...'**
  String get runningCoachAnalysisInProgress;

  /// No description provided for @runningCoachPickVideoFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not open the video picker.'**
  String get runningCoachPickVideoFailed;

  /// No description provided for @runningCoachUnsupportedPlatform.
  ///
  /// In en, this message translates to:
  /// **'Running video analysis is available only on Android and iPhone/iPad app builds.'**
  String get runningCoachUnsupportedPlatform;

  /// No description provided for @runningCoachNativeAnalyzerUnavailable.
  ///
  /// In en, this message translates to:
  /// **'This app build does not include the running video analyzer yet. Reinstall the latest mobile app build and try again.'**
  String get runningCoachNativeAnalyzerUnavailable;

  /// No description provided for @runningCoachVideoFileMissing.
  ///
  /// In en, this message translates to:
  /// **'The selected video file could not be found.'**
  String get runningCoachVideoFileMissing;

  /// No description provided for @runningCoachVideoTooShort.
  ///
  /// In en, this message translates to:
  /// **'The video is too short. Record at least a few running steps.'**
  String get runningCoachVideoTooShort;

  /// No description provided for @runningCoachNoPoseDetected.
  ///
  /// In en, this message translates to:
  /// **'The runner could not be tracked well enough. Try a clearer side-view clip with elbows, knees, and feet visible.'**
  String get runningCoachNoPoseDetected;

  /// No description provided for @runningCoachAnalysisFailedGeneric.
  ///
  /// In en, this message translates to:
  /// **'Running analysis failed. Try another clip with a clearer side view.'**
  String get runningCoachAnalysisFailedGeneric;

  /// No description provided for @runningCoachResultsTitle.
  ///
  /// In en, this message translates to:
  /// **'Coaching results'**
  String get runningCoachResultsTitle;

  /// No description provided for @runningCoachAnalysisHistoryTitle.
  ///
  /// In en, this message translates to:
  /// **'Video analysis history'**
  String get runningCoachAnalysisHistoryTitle;

  /// No description provided for @runningCoachAnalysisHistoryBody.
  ///
  /// In en, this message translates to:
  /// **'Review each analyzed video with its key decision and correction guide.'**
  String get runningCoachAnalysisHistoryBody;

  /// No description provided for @runningCoachAnalysisHistoryAction.
  ///
  /// In en, this message translates to:
  /// **'All {count}'**
  String runningCoachAnalysisHistoryAction(int count);

  /// No description provided for @runningCoachAnalysisHistoryEmpty.
  ///
  /// In en, this message translates to:
  /// **'No saved video analyses yet.'**
  String get runningCoachAnalysisHistoryEmpty;

  /// No description provided for @runningCoachAnalysisHistoryDetailTitle.
  ///
  /// In en, this message translates to:
  /// **'Analysis guide'**
  String get runningCoachAnalysisHistoryDetailTitle;

  /// No description provided for @runningCoachAnalysisHistoryPrimaryFocus.
  ///
  /// In en, this message translates to:
  /// **'Key decision for this clip'**
  String get runningCoachAnalysisHistoryPrimaryFocus;

  /// No description provided for @runningCoachAnalysisResultScreenTitle.
  ///
  /// In en, this message translates to:
  /// **'Running analysis result'**
  String get runningCoachAnalysisResultScreenTitle;

  /// No description provided for @runningCoachHistoryVideoSaved.
  ///
  /// In en, this message translates to:
  /// **'Video saved'**
  String get runningCoachHistoryVideoSaved;

  /// No description provided for @runningCoachArchivedVideoTitle.
  ///
  /// In en, this message translates to:
  /// **'Analyzed video'**
  String get runningCoachArchivedVideoTitle;

  /// No description provided for @runningCoachArchivedVideoBody.
  ///
  /// In en, this message translates to:
  /// **'This video is saved with the analysis history so you can review the same form again.'**
  String get runningCoachArchivedVideoBody;

  /// No description provided for @runningCoachArchivedVideoPlay.
  ///
  /// In en, this message translates to:
  /// **'Play'**
  String get runningCoachArchivedVideoPlay;

  /// No description provided for @runningCoachArchivedVideoPause.
  ///
  /// In en, this message translates to:
  /// **'Pause'**
  String get runningCoachArchivedVideoPause;

  /// No description provided for @runningCoachArchivedVideoUnavailable.
  ///
  /// In en, this message translates to:
  /// **'The saved video cannot be opened. The file may have been removed from this device.'**
  String get runningCoachArchivedVideoUnavailable;

  /// No description provided for @runningCoachAnalysisGuideTitle.
  ///
  /// In en, this message translates to:
  /// **'Correction point in pictures'**
  String get runningCoachAnalysisGuideTitle;

  /// No description provided for @runningCoachAnalysisGuideBody.
  ///
  /// In en, this message translates to:
  /// **'Compare the measured value with the good range using body lines, joint angles, and landing zones.'**
  String get runningCoachAnalysisGuideBody;

  /// No description provided for @runningCoachAnalysisGuideRangeLabel.
  ///
  /// In en, this message translates to:
  /// **'Good range'**
  String get runningCoachAnalysisGuideRangeLabel;

  /// No description provided for @runningCoachAnalysisGuideFindingLabel.
  ///
  /// In en, this message translates to:
  /// **'Why it was flagged'**
  String get runningCoachAnalysisGuideFindingLabel;

  /// No description provided for @runningCoachAnalysisGuideCueLabel.
  ///
  /// In en, this message translates to:
  /// **'Action cue'**
  String get runningCoachAnalysisGuideCueLabel;

  /// No description provided for @runningCoachAnalysisGuideDrillLabel.
  ///
  /// In en, this message translates to:
  /// **'Recommended drill'**
  String get runningCoachAnalysisGuideDrillLabel;

  /// No description provided for @runningCoachGuideRangePosture.
  ///
  /// In en, this message translates to:
  /// **'Target: 8-15° whole-body forward lean from the ankles'**
  String get runningCoachGuideRangePosture;

  /// No description provided for @runningCoachGuideRangeBounce.
  ///
  /// In en, this message translates to:
  /// **'Target: low, quick vertical motion around 5-9% of body height'**
  String get runningCoachGuideRangeBounce;

  /// No description provided for @runningCoachGuideRangeFootStrike.
  ///
  /// In en, this message translates to:
  /// **'Target: lead foot lands under the hips within 0.00-0.18x ahead'**
  String get runningCoachGuideRangeFootStrike;

  /// No description provided for @runningCoachGuideRangeKnee.
  ///
  /// In en, this message translates to:
  /// **'Target: support knee accepts contact softly around 145-165°'**
  String get runningCoachGuideRangeKnee;

  /// No description provided for @runningCoachGuideRangeArm.
  ///
  /// In en, this message translates to:
  /// **'Target: elbows move compactly front to back around 70-110°'**
  String get runningCoachGuideRangeArm;

  /// No description provided for @runningCoachMetricScoreLabel.
  ///
  /// In en, this message translates to:
  /// **'Metric score'**
  String get runningCoachMetricScoreLabel;

  /// No description provided for @runningCoachConfidenceLabel.
  ///
  /// In en, this message translates to:
  /// **'Confidence {percent}%'**
  String runningCoachConfidenceLabel(int percent);

  /// No description provided for @runningCoachSessionSourceUploadVideo.
  ///
  /// In en, this message translates to:
  /// **'Video analysis'**
  String get runningCoachSessionSourceUploadVideo;

  /// No description provided for @runningCoachSessionSourceLiveRun.
  ///
  /// In en, this message translates to:
  /// **'Live coach'**
  String get runningCoachSessionSourceLiveRun;

  /// No description provided for @runningCoachSessionSourceSprintLive.
  ///
  /// In en, this message translates to:
  /// **'Sprint coaching'**
  String get runningCoachSessionSourceSprintLive;

  /// No description provided for @runningCoachQualityReasonLowCoverage.
  ///
  /// In en, this message translates to:
  /// **'Tracking coverage is low, so treat this metric conservatively.'**
  String get runningCoachQualityReasonLowCoverage;

  /// No description provided for @runningCoachQualityReasonLimitedSamples.
  ///
  /// In en, this message translates to:
  /// **'Only a small set of stable frames was read; confirm once more from the same angle.'**
  String get runningCoachQualityReasonLimitedSamples;

  /// No description provided for @runningCoachQualityReasonContactPhaseProxy.
  ///
  /// In en, this message translates to:
  /// **'The contact phase used only a small proxy window; confirm foot strike and knee metrics again.'**
  String get runningCoachQualityReasonContactPhaseProxy;

  /// No description provided for @runningCoachQualityReasonGeneric.
  ///
  /// In en, this message translates to:
  /// **'Capture quality is low; confirm again from the same angle.'**
  String get runningCoachQualityReasonGeneric;

  /// No description provided for @runningCoachOverallHeadlineStrong.
  ///
  /// In en, this message translates to:
  /// **'Strong running shape'**
  String get runningCoachOverallHeadlineStrong;

  /// No description provided for @runningCoachOverallHeadlineSolid.
  ///
  /// In en, this message translates to:
  /// **'Solid base with one clear fix'**
  String get runningCoachOverallHeadlineSolid;

  /// No description provided for @runningCoachOverallHeadlineNeedsWork.
  ///
  /// In en, this message translates to:
  /// **'Build a cleaner running pattern'**
  String get runningCoachOverallHeadlineNeedsWork;

  /// No description provided for @runningCoachOverallSummary.
  ///
  /// In en, this message translates to:
  /// **'Overall running score {score}/100'**
  String runningCoachOverallSummary(int score);

  /// No description provided for @runningCoachOverallScoreLabel.
  ///
  /// In en, this message translates to:
  /// **'Overall score'**
  String get runningCoachOverallScoreLabel;

  /// No description provided for @runningCoachDurationLabel.
  ///
  /// In en, this message translates to:
  /// **'Clip'**
  String get runningCoachDurationLabel;

  /// No description provided for @runningCoachFramesAnalyzedLabel.
  ///
  /// In en, this message translates to:
  /// **'Frames'**
  String get runningCoachFramesAnalyzedLabel;

  /// No description provided for @runningCoachCoverageLabel.
  ///
  /// In en, this message translates to:
  /// **'Coverage'**
  String get runningCoachCoverageLabel;

  /// No description provided for @runningCoachMetricScoresTitle.
  ///
  /// In en, this message translates to:
  /// **'Metric scores'**
  String get runningCoachMetricScoresTitle;

  /// No description provided for @runningCoachFocusTitle.
  ///
  /// In en, this message translates to:
  /// **'Focus first'**
  String get runningCoachFocusTitle;

  /// No description provided for @runningCoachMaintainTitle.
  ///
  /// In en, this message translates to:
  /// **'Keep these'**
  String get runningCoachMaintainTitle;

  /// No description provided for @runningCoachMetricScore.
  ///
  /// In en, this message translates to:
  /// **'Score {score}'**
  String runningCoachMetricScore(int score);

  /// No description provided for @runningCoachPriorityLabel.
  ///
  /// In en, this message translates to:
  /// **'Priority {priority}'**
  String runningCoachPriorityLabel(int priority);

  /// No description provided for @runningCoachMetricValueLabel.
  ///
  /// In en, this message translates to:
  /// **'Measured value'**
  String get runningCoachMetricValueLabel;

  /// No description provided for @runningCoachBodyRegionUpper.
  ///
  /// In en, this message translates to:
  /// **'Upper body'**
  String get runningCoachBodyRegionUpper;

  /// No description provided for @runningCoachBodyRegionLower.
  ///
  /// In en, this message translates to:
  /// **'Lower body'**
  String get runningCoachBodyRegionLower;

  /// No description provided for @runningCoachBodyRegionWhole.
  ///
  /// In en, this message translates to:
  /// **'Whole-body rhythm'**
  String get runningCoachBodyRegionWhole;

  /// No description provided for @runningCoachStatusGood.
  ///
  /// In en, this message translates to:
  /// **'Good'**
  String get runningCoachStatusGood;

  /// No description provided for @runningCoachStatusWatch.
  ///
  /// In en, this message translates to:
  /// **'Watch'**
  String get runningCoachStatusWatch;

  /// No description provided for @runningCoachStatusNeedsWork.
  ///
  /// In en, this message translates to:
  /// **'Needs work'**
  String get runningCoachStatusNeedsWork;

  /// No description provided for @runningCoachLeanValue.
  ///
  /// In en, this message translates to:
  /// **'{value}° forward lean'**
  String runningCoachLeanValue(Object value);

  /// No description provided for @runningCoachBounceValue.
  ///
  /// In en, this message translates to:
  /// **'{value}% vertical bounce'**
  String runningCoachBounceValue(Object value);

  /// No description provided for @runningCoachFootStrikeValue.
  ///
  /// In en, this message translates to:
  /// **'{value}x ahead of hips'**
  String runningCoachFootStrikeValue(Object value);

  /// No description provided for @runningCoachKneeValue.
  ///
  /// In en, this message translates to:
  /// **'{value}° support knee angle'**
  String runningCoachKneeValue(Object value);

  /// No description provided for @runningCoachArmValue.
  ///
  /// In en, this message translates to:
  /// **'{value}° elbow angle'**
  String runningCoachArmValue(Object value);

  /// No description provided for @runningCoachStrideValue.
  ///
  /// In en, this message translates to:
  /// **'{value}x stride reach'**
  String runningCoachStrideValue(Object value);

  /// No description provided for @runningCoachInsightPostureTitle.
  ///
  /// In en, this message translates to:
  /// **'Posture'**
  String get runningCoachInsightPostureTitle;

  /// No description provided for @runningCoachPostureGoodSummary.
  ///
  /// In en, this message translates to:
  /// **'Your body angle is close to a clean sprint posture with a slight forward lean.'**
  String get runningCoachPostureGoodSummary;

  /// No description provided for @runningCoachPostureGoodCue.
  ///
  /// In en, this message translates to:
  /// **'Keep the chest tall and let the whole body fall forward together.'**
  String get runningCoachPostureGoodCue;

  /// No description provided for @runningCoachPostureGoodDrill.
  ///
  /// In en, this message translates to:
  /// **'Drill: 2 x 15m wall-lean marches to lock in the same body line.'**
  String get runningCoachPostureGoodDrill;

  /// No description provided for @runningCoachPostureUprightSummary.
  ///
  /// In en, this message translates to:
  /// **'Your torso stays too upright, so you may be losing forward intent on each step.'**
  String get runningCoachPostureUprightSummary;

  /// No description provided for @runningCoachPostureUprightCue.
  ///
  /// In en, this message translates to:
  /// **'Think \"nose over toes\" and let the lean come from the ankles, not the waist.'**
  String get runningCoachPostureUprightCue;

  /// No description provided for @runningCoachPostureUprightDrill.
  ///
  /// In en, this message translates to:
  /// **'Drill: 2 x 15m falling starts, then 2 x 15m wall-lean marches.'**
  String get runningCoachPostureUprightDrill;

  /// No description provided for @runningCoachPostureLeanSummary.
  ///
  /// In en, this message translates to:
  /// **'Your torso is leaning too much, which can make the stride collapse and slow recovery.'**
  String get runningCoachPostureLeanSummary;

  /// No description provided for @runningCoachPostureLeanCue.
  ///
  /// In en, this message translates to:
  /// **'Run tall through the hips and keep the ribs stacked over the pelvis.'**
  String get runningCoachPostureLeanCue;

  /// No description provided for @runningCoachPostureLeanDrill.
  ///
  /// In en, this message translates to:
  /// **'Drill: 2 x 20m tall posture runs with light quick steps.'**
  String get runningCoachPostureLeanDrill;

  /// No description provided for @runningCoachInsightBounceTitle.
  ///
  /// In en, this message translates to:
  /// **'Bounce'**
  String get runningCoachInsightBounceTitle;

  /// No description provided for @runningCoachBounceGoodSummary.
  ///
  /// In en, this message translates to:
  /// **'Your vertical movement looks controlled, which helps keep energy moving forward.'**
  String get runningCoachBounceGoodSummary;

  /// No description provided for @runningCoachBounceGoodCue.
  ///
  /// In en, this message translates to:
  /// **'Keep pushing backward into the ground instead of bouncing upward.'**
  String get runningCoachBounceGoodCue;

  /// No description provided for @runningCoachBounceGoodDrill.
  ///
  /// In en, this message translates to:
  /// **'Drill: 2 x 20m ankle dribbles before your next sprint set.'**
  String get runningCoachBounceGoodDrill;

  /// No description provided for @runningCoachBounceHighSummary.
  ///
  /// In en, this message translates to:
  /// **'There is extra up-and-down bounce in the clip, which can waste energy.'**
  String get runningCoachBounceHighSummary;

  /// No description provided for @runningCoachBounceHighCue.
  ///
  /// In en, this message translates to:
  /// **'Think quick contacts and push the ground behind you, not straight down.'**
  String get runningCoachBounceHighCue;

  /// No description provided for @runningCoachBounceHighDrill.
  ///
  /// In en, this message translates to:
  /// **'Drill: 3 x 20m ankle dribbles and straight-leg runs with short contacts.'**
  String get runningCoachBounceHighDrill;

  /// No description provided for @runningCoachInsightFootStrikeTitle.
  ///
  /// In en, this message translates to:
  /// **'Foot strike'**
  String get runningCoachInsightFootStrikeTitle;

  /// No description provided for @runningCoachFootStrikeGoodSummary.
  ///
  /// In en, this message translates to:
  /// **'The lead foot is landing close enough to the hips that the step can keep rolling forward.'**
  String get runningCoachFootStrikeGoodSummary;

  /// No description provided for @runningCoachFootStrikeGoodCue.
  ///
  /// In en, this message translates to:
  /// **'Keep landing under the hips and let speed come from push-off, not reaching.'**
  String get runningCoachFootStrikeGoodCue;

  /// No description provided for @runningCoachFootStrikeGoodDrill.
  ///
  /// In en, this message translates to:
  /// **'Drill: 2 x 20m wicket-style runs with short, quick contacts.'**
  String get runningCoachFootStrikeGoodDrill;

  /// No description provided for @runningCoachFootStrikeOverSummary.
  ///
  /// In en, this message translates to:
  /// **'The lead foot is reaching too far in front of the hips, which can create braking at contact.'**
  String get runningCoachFootStrikeOverSummary;

  /// No description provided for @runningCoachFootStrikeOverCue.
  ///
  /// In en, this message translates to:
  /// **'Bring the landing point back under the hips and think push back, not reach forward.'**
  String get runningCoachFootStrikeOverCue;

  /// No description provided for @runningCoachFootStrikeOverDrill.
  ///
  /// In en, this message translates to:
  /// **'Drill: 2 x 20m A-march plus 2 x 20m wicket-style runs with shorter contacts.'**
  String get runningCoachFootStrikeOverDrill;

  /// No description provided for @runningCoachInsightKneeTitle.
  ///
  /// In en, this message translates to:
  /// **'Knee flexion'**
  String get runningCoachInsightKneeTitle;

  /// No description provided for @runningCoachKneeGoodSummary.
  ///
  /// In en, this message translates to:
  /// **'The support knee is bending enough to stay springy without collapsing.'**
  String get runningCoachKneeGoodSummary;

  /// No description provided for @runningCoachKneeGoodCue.
  ///
  /// In en, this message translates to:
  /// **'Keep the stance leg soft and reactive instead of locking on landing.'**
  String get runningCoachKneeGoodCue;

  /// No description provided for @runningCoachKneeGoodDrill.
  ///
  /// In en, this message translates to:
  /// **'Drill: 2 x 20m pogo runs, then 2 x 20m dribble runs.'**
  String get runningCoachKneeGoodDrill;

  /// No description provided for @runningCoachKneeStraightSummary.
  ///
  /// In en, this message translates to:
  /// **'The support knee is landing too straight, which can make the step look stiff and heavy.'**
  String get runningCoachKneeStraightSummary;

  /// No description provided for @runningCoachKneeStraightCue.
  ///
  /// In en, this message translates to:
  /// **'Soften the landing knee and let the leg accept the ground under the hips.'**
  String get runningCoachKneeStraightCue;

  /// No description provided for @runningCoachKneeStraightDrill.
  ///
  /// In en, this message translates to:
  /// **'Drill: 2 x 20m dribble runs with bent-knee contacts and quick steps.'**
  String get runningCoachKneeStraightDrill;

  /// No description provided for @runningCoachKneeCollapseSummary.
  ///
  /// In en, this message translates to:
  /// **'The support knee is folding too much after contact, so the stance leg is losing stiffness.'**
  String get runningCoachKneeCollapseSummary;

  /// No description provided for @runningCoachKneeCollapseCue.
  ///
  /// In en, this message translates to:
  /// **'Stay springy through the stance leg and keep the hips stacked over the foot.'**
  String get runningCoachKneeCollapseCue;

  /// No description provided for @runningCoachKneeCollapseDrill.
  ///
  /// In en, this message translates to:
  /// **'Drill: 2 x 15m single-leg pogo hops per side, then 2 x 20m dribble runs.'**
  String get runningCoachKneeCollapseDrill;

  /// No description provided for @runningCoachInsightArmTitle.
  ///
  /// In en, this message translates to:
  /// **'Arm carriage'**
  String get runningCoachInsightArmTitle;

  /// No description provided for @runningCoachArmGoodSummary.
  ///
  /// In en, this message translates to:
  /// **'Your elbows stay in a compact range that supports rhythm without over-tensing the upper body.'**
  String get runningCoachArmGoodSummary;

  /// No description provided for @runningCoachArmGoodCue.
  ///
  /// In en, this message translates to:
  /// **'Keep the elbows bent and let the hands travel front to back with the same rhythm as the legs.'**
  String get runningCoachArmGoodCue;

  /// No description provided for @runningCoachArmGoodDrill.
  ///
  /// In en, this message translates to:
  /// **'Drill: 2 x 20s wall arm switches, then 2 x 20m arm-drive marches.'**
  String get runningCoachArmGoodDrill;

  /// No description provided for @runningCoachArmOpenSummary.
  ///
  /// In en, this message translates to:
  /// **'Your elbows are opening too much, so the arms may be leaking rhythm instead of helping it.'**
  String get runningCoachArmOpenSummary;

  /// No description provided for @runningCoachArmOpenCue.
  ///
  /// In en, this message translates to:
  /// **'Keep the elbows more bent and drive the hands back past the hips instead of reaching long.'**
  String get runningCoachArmOpenCue;

  /// No description provided for @runningCoachArmOpenDrill.
  ///
  /// In en, this message translates to:
  /// **'Drill: 2 x 20s wall arm switches while holding a compact 80-100 degree elbow bend.'**
  String get runningCoachArmOpenDrill;

  /// No description provided for @runningCoachArmTightSummary.
  ///
  /// In en, this message translates to:
  /// **'Your elbows are staying too tight, which can shorten the arm swing and make the stride feel forced.'**
  String get runningCoachArmTightSummary;

  /// No description provided for @runningCoachArmTightCue.
  ///
  /// In en, this message translates to:
  /// **'Relax the shoulders and let the elbows open a little more while the hands keep moving backward.'**
  String get runningCoachArmTightCue;

  /// No description provided for @runningCoachArmTightDrill.
  ///
  /// In en, this message translates to:
  /// **'Drill: 2 x 20m marching arm swings with relaxed shoulders and a smoother back drive.'**
  String get runningCoachArmTightDrill;

  /// No description provided for @runningCoachInsightStrideTitle.
  ///
  /// In en, this message translates to:
  /// **'Stride reach'**
  String get runningCoachInsightStrideTitle;

  /// No description provided for @runningCoachStrideGoodSummary.
  ///
  /// In en, this message translates to:
  /// **'Your front foot stays close to a useful landing window under the body.'**
  String get runningCoachStrideGoodSummary;

  /// No description provided for @runningCoachStrideGoodCue.
  ///
  /// In en, this message translates to:
  /// **'Keep the same timing and let the stride open from force, not from reaching.'**
  String get runningCoachStrideGoodCue;

  /// No description provided for @runningCoachStrideGoodDrill.
  ///
  /// In en, this message translates to:
  /// **'Drill: 2 x 20m wicket-style quick step runs to keep the same rhythm.'**
  String get runningCoachStrideGoodDrill;

  /// No description provided for @runningCoachStrideShortSummary.
  ///
  /// In en, this message translates to:
  /// **'Your stride reach looks short, so you may be holding back and not opening the run enough.'**
  String get runningCoachStrideShortSummary;

  /// No description provided for @runningCoachStrideShortCue.
  ///
  /// In en, this message translates to:
  /// **'Drive the knee forward and let the step open naturally behind a faster arm rhythm.'**
  String get runningCoachStrideShortCue;

  /// No description provided for @runningCoachStrideShortDrill.
  ///
  /// In en, this message translates to:
  /// **'Drill: 2 x 20m A-march into A-skip to build front-side mechanics.'**
  String get runningCoachStrideShortDrill;

  /// No description provided for @runningCoachStrideOverSummary.
  ///
  /// In en, this message translates to:
  /// **'The front foot is reaching too far ahead of the body, which can create braking.'**
  String get runningCoachStrideOverSummary;

  /// No description provided for @runningCoachStrideOverCue.
  ///
  /// In en, this message translates to:
  /// **'Land closer under the hips and let speed come from push-off, not reaching.'**
  String get runningCoachStrideOverCue;

  /// No description provided for @runningCoachStrideOverDrill.
  ///
  /// In en, this message translates to:
  /// **'Drill: 2 x 20m A-march and 2 x 20m wicket-style runs with short contacts.'**
  String get runningCoachStrideOverDrill;

  /// No description provided for @runningCoachSprintDebugToggle.
  ///
  /// In en, this message translates to:
  /// **'Toggle sprint debug overlay'**
  String get runningCoachSprintDebugToggle;

  /// No description provided for @runningCoachSprintDebugPanelTitle.
  ///
  /// In en, this message translates to:
  /// **'Debug overlay'**
  String get runningCoachSprintDebugPanelTitle;

  /// No description provided for @runningCoachSprintCueWhyLabel.
  ///
  /// In en, this message translates to:
  /// **'Why'**
  String get runningCoachSprintCueWhyLabel;

  /// No description provided for @runningCoachSprintCueTryLabel.
  ///
  /// In en, this message translates to:
  /// **'Try'**
  String get runningCoachSprintCueTryLabel;

  /// No description provided for @runningCoachSprintTrackingStateBodyTooSmall.
  ///
  /// In en, this message translates to:
  /// **'Move closer'**
  String get runningCoachSprintTrackingStateBodyTooSmall;

  /// No description provided for @runningCoachSprintTrackingStateBodyOutOfFrame.
  ///
  /// In en, this message translates to:
  /// **'Keep the full body in frame'**
  String get runningCoachSprintTrackingStateBodyOutOfFrame;

  /// No description provided for @runningCoachSprintTrackingStateLowConfidence.
  ///
  /// In en, this message translates to:
  /// **'Raise tracking confidence'**
  String get runningCoachSprintTrackingStateLowConfidence;

  /// No description provided for @runningCoachSprintTrackingStateSideViewUnstable.
  ///
  /// In en, this message translates to:
  /// **'Settle the side view'**
  String get runningCoachSprintTrackingStateSideViewUnstable;

  /// No description provided for @runningCoachSprintTrackingStateReady.
  ///
  /// In en, this message translates to:
  /// **'Ready for analysis'**
  String get runningCoachSprintTrackingStateReady;

  /// No description provided for @runningCoachSprintTrackingHintBodyTooSmall.
  ///
  /// In en, this message translates to:
  /// **'The runner is too small in frame. Move closer before analyzing.'**
  String get runningCoachSprintTrackingHintBodyTooSmall;

  /// No description provided for @runningCoachSprintTrackingHintBodyOutOfFrame.
  ///
  /// In en, this message translates to:
  /// **'Some joints are leaving the frame, so the pose line cannot stay locked.'**
  String get runningCoachSprintTrackingHintBodyOutOfFrame;

  /// No description provided for @runningCoachSprintTrackingHintLowConfidence.
  ///
  /// In en, this message translates to:
  /// **'Pose confidence is low right now. Hold a steadier shot for a moment.'**
  String get runningCoachSprintTrackingHintLowConfidence;

  /// No description provided for @runningCoachSprintTrackingHintSideViewUnstable.
  ///
  /// In en, this message translates to:
  /// **'The side-view motion is still unstable. Keep a cleaner lateral run path.'**
  String get runningCoachSprintTrackingHintSideViewUnstable;

  /// No description provided for @runningCoachSprintTrackingDiagnosisBodyTooSmall.
  ///
  /// In en, this message translates to:
  /// **'The current body box is too small for stable trunk, knee, and rhythm measurements on device.'**
  String get runningCoachSprintTrackingDiagnosisBodyTooSmall;

  /// No description provided for @runningCoachSprintTrackingDiagnosisBodyOutOfFrame.
  ///
  /// In en, this message translates to:
  /// **'Core joints are clipping near the edge, so the pose line and sprint metrics may drift.'**
  String get runningCoachSprintTrackingDiagnosisBodyOutOfFrame;

  /// No description provided for @runningCoachSprintTrackingDiagnosisLowConfidence.
  ///
  /// In en, this message translates to:
  /// **'Visible joints or average landmark confidence are below the quality gate for coaching.'**
  String get runningCoachSprintTrackingDiagnosisLowConfidence;

  /// No description provided for @runningCoachSprintTrackingDiagnosisSideViewUnstable.
  ///
  /// In en, this message translates to:
  /// **'The motion path is not staying lateral enough yet, so side-view analysis is being held back.'**
  String get runningCoachSprintTrackingDiagnosisSideViewUnstable;

  /// No description provided for @runningCoachSprintTrackingActionBodyTooSmall.
  ///
  /// In en, this message translates to:
  /// **'Bring the camera closer until the body fills at least about half of the screen height.'**
  String get runningCoachSprintTrackingActionBodyTooSmall;

  /// No description provided for @runningCoachSprintTrackingActionBodyOutOfFrame.
  ///
  /// In en, this message translates to:
  /// **'Keep the head, elbows, hips, and ankles inside the guide frame before sprinting again.'**
  String get runningCoachSprintTrackingActionBodyOutOfFrame;

  /// No description provided for @runningCoachSprintTrackingActionLowConfidence.
  ///
  /// In en, this message translates to:
  /// **'Use a steadier camera, clearer lighting, and keep the runner centered for a few frames.'**
  String get runningCoachSprintTrackingActionLowConfidence;

  /// No description provided for @runningCoachSprintTrackingActionSideViewUnstable.
  ///
  /// In en, this message translates to:
  /// **'Run across the frame from the side instead of drifting toward the camera or diagonally.'**
  String get runningCoachSprintTrackingActionSideViewUnstable;

  /// No description provided for @runningCoachSprintTrackingSummary.
  ///
  /// In en, this message translates to:
  /// **'{state} · height {heightPercent}% · area {areaPercent}%'**
  String runningCoachSprintTrackingSummary(
      Object state, int heightPercent, int areaPercent);

  /// No description provided for @runningCoachSprintSpeechSummary.
  ///
  /// In en, this message translates to:
  /// **'Speech {state} · {reason}'**
  String runningCoachSprintSpeechSummary(Object state, Object reason);

  /// No description provided for @runningCoachSprintSpeechStateIdle.
  ///
  /// In en, this message translates to:
  /// **'Idle'**
  String get runningCoachSprintSpeechStateIdle;

  /// No description provided for @runningCoachSprintSpeechStateQueued.
  ///
  /// In en, this message translates to:
  /// **'Queued'**
  String get runningCoachSprintSpeechStateQueued;

  /// No description provided for @runningCoachSprintSpeechStateStarted.
  ///
  /// In en, this message translates to:
  /// **'Started'**
  String get runningCoachSprintSpeechStateStarted;

  /// No description provided for @runningCoachSprintSpeechStateCompleted.
  ///
  /// In en, this message translates to:
  /// **'Completed'**
  String get runningCoachSprintSpeechStateCompleted;

  /// No description provided for @runningCoachSprintSpeechStateSkipped.
  ///
  /// In en, this message translates to:
  /// **'Skipped'**
  String get runningCoachSprintSpeechStateSkipped;

  /// No description provided for @runningCoachSprintSpeechStateCancelled.
  ///
  /// In en, this message translates to:
  /// **'Cancelled'**
  String get runningCoachSprintSpeechStateCancelled;

  /// No description provided for @runningCoachSprintSpeechStateError.
  ///
  /// In en, this message translates to:
  /// **'Error'**
  String get runningCoachSprintSpeechStateError;

  /// No description provided for @runningCoachSprintSpeechSkipNone.
  ///
  /// In en, this message translates to:
  /// **'No skip'**
  String get runningCoachSprintSpeechSkipNone;

  /// No description provided for @runningCoachSprintSpeechSkipDisabled.
  ///
  /// In en, this message translates to:
  /// **'Voice feedback is off'**
  String get runningCoachSprintSpeechSkipDisabled;

  /// No description provided for @runningCoachSprintSpeechSkipNoFeedbackSelected.
  ///
  /// In en, this message translates to:
  /// **'No feedback selected'**
  String get runningCoachSprintSpeechSkipNoFeedbackSelected;

  /// No description provided for @runningCoachSprintSpeechSkipEmptyCue.
  ///
  /// In en, this message translates to:
  /// **'Cue text is empty'**
  String get runningCoachSprintSpeechSkipEmptyCue;

  /// No description provided for @runningCoachSprintSpeechSkipInfoFeedback.
  ///
  /// In en, this message translates to:
  /// **'Only warning cues are spoken'**
  String get runningCoachSprintSpeechSkipInfoFeedback;

  /// No description provided for @runningCoachSprintSpeechSkipTrackingNotReady.
  ///
  /// In en, this message translates to:
  /// **'Tracking is not ready yet'**
  String get runningCoachSprintSpeechSkipTrackingNotReady;

  /// No description provided for @runningCoachSprintSpeechSkipLowConfidence.
  ///
  /// In en, this message translates to:
  /// **'Feedback confidence is too low for speech'**
  String get runningCoachSprintSpeechSkipLowConfidence;

  /// No description provided for @runningCoachSprintSpeechSkipTrackingNotStable.
  ///
  /// In en, this message translates to:
  /// **'Tracking has not stayed stable long enough'**
  String get runningCoachSprintSpeechSkipTrackingNotStable;

  /// No description provided for @runningCoachSprintSpeechSkipCooldownActive.
  ///
  /// In en, this message translates to:
  /// **'Speech cooldown is active'**
  String get runningCoachSprintSpeechSkipCooldownActive;

  /// No description provided for @runningCoachSprintDiagnosisLeanForward.
  ///
  /// In en, this message translates to:
  /// **'The trunk is rising too early, so the first acceleration steps lose forward push.'**
  String get runningCoachSprintDiagnosisLeanForward;

  /// No description provided for @runningCoachSprintDiagnosisDriveKnee.
  ///
  /// In en, this message translates to:
  /// **'The knee drive is staying low relative to the hips, so the front-side step does not connect strongly.'**
  String get runningCoachSprintDiagnosisDriveKnee;

  /// No description provided for @runningCoachSprintDiagnosisKeepRhythm.
  ///
  /// In en, this message translates to:
  /// **'Step timing is varying too much, so the left-right sprint rhythm is drifting.'**
  String get runningCoachSprintDiagnosisKeepRhythm;

  /// No description provided for @runningCoachSprintDiagnosisBalanceArms.
  ///
  /// In en, this message translates to:
  /// **'One arm is contributing less backward drive, so rhythm support from the upper body is uneven.'**
  String get runningCoachSprintDiagnosisBalanceArms;

  /// No description provided for @runningCoachSprintDiagnosisKeepPushing.
  ///
  /// In en, this message translates to:
  /// **'The main sprint metrics are inside the stable range, so the app is holding the current cue.'**
  String get runningCoachSprintDiagnosisKeepPushing;

  /// No description provided for @runningCoachSprintActionLeanForward.
  ///
  /// In en, this message translates to:
  /// **'Keep the chest low for the first three steps so the hip-to-shoulder axis stays inside the 8-24° range.'**
  String get runningCoachSprintActionLeanForward;

  /// No description provided for @runningCoachSprintActionDriveKnee.
  ///
  /// In en, this message translates to:
  /// **'Push the ground harder and let the knee come through instead of trying to lift it by itself.'**
  String get runningCoachSprintActionDriveKnee;

  /// No description provided for @runningCoachSprintActionKeepRhythm.
  ///
  /// In en, this message translates to:
  /// **'Do not reach for a longer step. Keep ground contacts evenly spaced for the next few strides.'**
  String get runningCoachSprintActionKeepRhythm;

  /// No description provided for @runningCoachSprintActionBalanceArms.
  ///
  /// In en, this message translates to:
  /// **'Match the backward arm drive on both sides and keep the shoulders quieter.'**
  String get runningCoachSprintActionBalanceArms;

  /// No description provided for @runningCoachSprintActionKeepPushing.
  ///
  /// In en, this message translates to:
  /// **'Stay with the same shape for another few steps so the app can confirm stability.'**
  String get runningCoachSprintActionKeepPushing;

  /// No description provided for @runningCoachSprintSessionTrackingStateLabel.
  ///
  /// In en, this message translates to:
  /// **'Tracking state'**
  String get runningCoachSprintSessionTrackingStateLabel;

  /// No description provided for @runningCoachSprintSessionPersonSizeLabel.
  ///
  /// In en, this message translates to:
  /// **'Person size'**
  String get runningCoachSprintSessionPersonSizeLabel;

  /// No description provided for @runningCoachSprintSessionPersonSizeValue.
  ///
  /// In en, this message translates to:
  /// **'height {heightPercent}% · area {areaPercent}%'**
  String runningCoachSprintSessionPersonSizeValue(
      int heightPercent, int areaPercent);

  /// No description provided for @runningCoachSprintSessionVisibleJointCountLabel.
  ///
  /// In en, this message translates to:
  /// **'Visible joints'**
  String get runningCoachSprintSessionVisibleJointCountLabel;

  /// No description provided for @runningCoachSprintSessionVisibleJointCountValue.
  ///
  /// In en, this message translates to:
  /// **'{count} joints · avg {confidence}'**
  String runningCoachSprintSessionVisibleJointCountValue(
      int count, Object confidence);

  /// No description provided for @runningCoachSprintSessionSpeechStateLabel.
  ///
  /// In en, this message translates to:
  /// **'Speech state'**
  String get runningCoachSprintSessionSpeechStateLabel;

  /// No description provided for @runningCoachSprintSessionSpeechStateValue.
  ///
  /// In en, this message translates to:
  /// **'{state} · {reason} · cooldown {cooldownMs}ms'**
  String runningCoachSprintSessionSpeechStateValue(
      Object state, Object reason, int cooldownMs);

  /// No description provided for @runningCoachSprintSessionFeatureConfidenceLabel.
  ///
  /// In en, this message translates to:
  /// **'Feature confidence'**
  String get runningCoachSprintSessionFeatureConfidenceLabel;

  /// No description provided for @runningCoachSprintSessionFeatureConfidenceValue.
  ///
  /// In en, this message translates to:
  /// **'{trunk} / {knee} / {rhythm}'**
  String runningCoachSprintSessionFeatureConfidenceValue(
      Object trunk, Object knee, Object rhythm);

  /// No description provided for @runningCoachSprintSessionFeatureDebugValue.
  ///
  /// In en, this message translates to:
  /// **'{feature} {value} ({confidence}%)'**
  String runningCoachSprintSessionFeatureDebugValue(
      Object feature, Object value, int confidence);

  /// No description provided for @runningCoachSprintSessionFeatureUnavailableValue.
  ///
  /// In en, this message translates to:
  /// **'{feature} unavailable: {reason}'**
  String runningCoachSprintSessionFeatureUnavailableValue(
      Object feature, Object reason);

  /// No description provided for @runningCoachSprintFeatureUnavailableJointWindow.
  ///
  /// In en, this message translates to:
  /// **'not enough stable joint frames'**
  String get runningCoachSprintFeatureUnavailableJointWindow;

  /// No description provided for @runningCoachSprintFeatureUnavailableStepEvents.
  ///
  /// In en, this message translates to:
  /// **'not enough stable step events'**
  String get runningCoachSprintFeatureUnavailableStepEvents;

  /// No description provided for @homeWeatherNeedsLocationTitle.
  ///
  /// In en, this message translates to:
  /// **'Need location'**
  String get homeWeatherNeedsLocationTitle;

  /// No description provided for @homeWeatherNeedsLocationSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Turn location on'**
  String get homeWeatherNeedsLocationSubtitle;

  /// No description provided for @homeStreakBadgeActive.
  ///
  /// In en, this message translates to:
  /// **'Momentum'**
  String get homeStreakBadgeActive;

  /// No description provided for @homeStreakBadgeResume.
  ///
  /// In en, this message translates to:
  /// **'Restart'**
  String get homeStreakBadgeResume;

  /// No description provided for @homeStreakActiveTodayTitle.
  ///
  /// In en, this message translates to:
  /// **'{count} straight days'**
  String homeStreakActiveTodayTitle(int count);

  /// No description provided for @homeStreakActiveYesterdayTitle.
  ///
  /// In en, this message translates to:
  /// **'{count} days through yesterday'**
  String homeStreakActiveYesterdayTitle(int count);

  /// No description provided for @homeStreakPausedTitle.
  ///
  /// In en, this message translates to:
  /// **'{count}-day streak paused'**
  String homeStreakPausedTitle(int count);

  /// No description provided for @homeStreakActiveTodayBody.
  ///
  /// In en, this message translates to:
  /// **'Today\'s session is already in. One more short log tomorrow keeps the rhythm building.'**
  String get homeStreakActiveTodayBody;

  /// No description provided for @homeStreakActiveYesterdayBody.
  ///
  /// In en, this message translates to:
  /// **'Add one more session today and the recent rhythm carries straight forward.'**
  String get homeStreakActiveYesterdayBody;

  /// No description provided for @homeStreakPausedBody.
  ///
  /// In en, this message translates to:
  /// **'You have been away for {gap} days. Restart with a short session and the rhythm comes back quickly.'**
  String homeStreakPausedBody(int gap);

  /// No description provided for @homeStreakLastLogged.
  ///
  /// In en, this message translates to:
  /// **'Last log {date}'**
  String homeStreakLastLogged(Object date);

  /// No description provided for @homeStreakDaysValue.
  ///
  /// In en, this message translates to:
  /// **'{count} days'**
  String homeStreakDaysValue(int count);

  /// No description provided for @homeStreakActionContinue.
  ///
  /// In en, this message translates to:
  /// **'Log today'**
  String get homeStreakActionContinue;

  /// No description provided for @homeStreakActionReview.
  ///
  /// In en, this message translates to:
  /// **'Week'**
  String get homeStreakActionReview;

  /// No description provided for @educationScreenTitle.
  ///
  /// In en, this message translates to:
  /// **'The World Cup Story Dad Tells Taeo'**
  String get educationScreenTitle;

  /// No description provided for @educationStoryIntroBody.
  ///
  /// In en, this message translates to:
  /// **'Taeo, tonight I do not want you to flip through the World Cup like a workbook. I want you to read it like one long story. It lasts much longer when you remember not only the names of the champions, but also the smell, the noise, and the expressions each tournament left behind. I want you to grow into the kind of player who looks at the faces and the air of an era as carefully as the scoreline.\n\nThat is why this screen no longer chops the story into little pages. You can read it in one long stretch now. Instead of turning chapters with your thumb, just keep moving slowly through the years. I want Uruguay 1930 and the still-unopened page of North America 2026 to feel connected in one line.'**
  String get educationStoryIntroBody;

  /// No description provided for @educationStoryOriginsTitle.
  ///
  /// In en, this message translates to:
  /// **'1930-1938, the first World Cup arrived by ship'**
  String get educationStoryOriginsTitle;

  /// No description provided for @educationStoryOriginsBody.
  ///
  /// In en, this message translates to:
  /// **'Taeo, the first World Cup began in an age when ships mattered more than planes. European teams spent weeks crossing the sea to reach Uruguay, and the hosts hurried the Estadio Centenario to completion inside the heat of a centenary celebration. By modern standards the whole thing looks inconvenient, but that very slowness is why the first tournament still feels so sharp. The World Cup was teaching us from the start that big occasions often arrive carrying a little discomfort.\n\nAnd when the story moves into Italy 1934 and France 1938, I do not want you to look only at the result sheet. Look at Mussolini\'s shadow, the long travel, the resentment around participation, and the refereeing arguments too. The World Cup was never only football. Travel technology, politics, and the emotions between nations were already sticking to the grass.\n\nSo when you remember 1930, 1934, and 1938, do not keep only three numbers. Keep the smell of salt, the tone of speeches, and the sound of uneasy applause with them. History stops feeling like an exam answer when you remember it as a real scene.'**
  String get educationStoryOriginsBody;

  /// No description provided for @educationStoryReturnTitle.
  ///
  /// In en, this message translates to:
  /// **'1950-1970, when silence and a smile stayed in the same tournament'**
  String get educationStoryReturnTitle;

  /// No description provided for @educationStoryReturnBody.
  ///
  /// In en, this message translates to:
  /// **'After the years emptied out by war, the World Cup returned in Brazil in 1950, and people probably expected celebration first. But Taeo, whenever I talk about that tournament, I start with the silence of the Maracana. Uruguay beating Brazil showed that one result can change the volume of an entire country.\n\nThen the story runs quickly through the Miracle of Bern in 1954, seventeen-year-old Pele in 1958, Garrincha in 1962, England in 1966, and the golden Brazil of 1970. By then the World Cup had become more than a tournament. It had turned into a machine for making collective memory. Someone falls, someone appears, and someone becomes so complete that he starts to look like legend.\n\nWhen you read this stretch, I want you to keep five words beside it: restart, shock, birth, revenge, and completion. Those words fold a long era into your hand without shrinking any of its feeling.'**
  String get educationStoryReturnBody;

  /// No description provided for @educationStoryMiddleTitle.
  ///
  /// In en, this message translates to:
  /// **'1974-2006, beauty and argument have to be remembered together'**
  String get educationStoryMiddleTitle;

  /// No description provided for @educationStoryMiddleBody.
  ///
  /// In en, this message translates to:
  /// **'By 1974 the texture of the air changes again. The trophy changes, the Netherlands shake the coordinates of the pitch with total football, and West Germany turn that beautiful chaos into a result. Taeo, every time I read this era I am reminded that football is one of the few places where idealism and reality collide in full public view. Grace is easy to love, but trophies usually lean toward something heavier.\n\nBut this period never fits inside tactics alone. Argentina 1978 carries the chill of military rule. Battiston\'s fall in 1982 stays in the mind far too long. Maradona in 1986 feels almost like weather. Then Roger Milla\'s dance in 1990, Korea\'s semi-final run in 2002, and Zidane\'s headbutt in 2006 show how the World Cup can spill out of the television and change the atmosphere inside a home.\n\nAnd 2002 is not somebody else\'s timeline for us. It includes the shouting in the streets, the late-night surge, and the air that refused to settle after the whistle. So when you read this era, do not remember only who scored. Remember what kind of night it was.'**
  String get educationStoryMiddleBody;

  /// No description provided for @educationStoryRecentTitle.
  ///
  /// In en, this message translates to:
  /// **'2010-2022, the more numbers arrived, the sharper the scenes became'**
  String get educationStoryRecentTitle;

  /// No description provided for @educationStoryRecentBody.
  ///
  /// In en, this message translates to:
  /// **'Open South Africa 2010 and you hear the vuvuzelas first. Open Brazil 2014 and the 7-1 scoreboard appears before anything else. In Russia 2018 there is the silence in front of the VAR monitor, and in Qatar 2022 Messi and Mbappe hold both a passing of generations and a collision of generations inside one final. Taeo, it sounds as if more data and more technology should blur the story, but the World Cup somehow moved in the opposite direction. The more numbers arrived, the more strongly the scenes stayed inside the body.\n\nKlose\'s sixteenth goal, Morocco reaching the semi-finals, and Suarez\'s handball on the line can all be listed in a record book. But what people hold onto for years is still the human expression of the moment. That is what I most want to tell you. Tables organize. Scenes make you understand.\n\nSo when you watch the recent World Cups, do not stop at the scoreline and the data. Ask why people were shocked, why they kept talking, and why the image lingered. That is how your football map grows wider.'**
  String get educationStoryRecentBody;

  /// No description provided for @educationStoryPeopleTitle.
  ///
  /// In en, this message translates to:
  /// **'You need the people, the politics, and the technology too'**
  String get educationStoryPeopleTitle;

  /// No description provided for @educationStoryPeopleBody.
  ///
  /// In en, this message translates to:
  /// **'Taeo, the World Cup can never be explained by a champions table alone. You need the faces that pulled whole eras forward: Jules Rimet, Pozzo, Pele, Beckenbauer, Maradona, Ronaldo, Messi. You also need moments such as the cancelled tournaments of 1942 and 1946, when war was strong enough to stop even football\'s grandest calendar. Only then do you see how quickly the World Cup began to resemble the wider world.\n\nThe dog Pickles recovering the Jules Rimet Trophy in 1966, the Schumacher-Battiston collision in 1982, Lampard\'s disallowed goal in 2010, goal-line technology in 2014, VAR in 2018, and semi-automated offside in 2022 all belong on the same line. Football always wants to become fairer, while also revealing that perfect fairness never fully arrives.\n\nSo keep writing two questions beside every tournament. Who won. And what changed. Once you start holding those two lines together, history becomes less stiff and more accurate at the same time.'**
  String get educationStoryPeopleBody;

  /// No description provided for @educationStoryFutureTitle.
  ///
  /// In en, this message translates to:
  /// **'Beyond 2026, how to read a page that has not opened yet'**
  String get educationStoryFutureTitle;

  /// No description provided for @educationStoryFutureBody.
  ///
  /// In en, this message translates to:
  /// **'Now look toward North America 2026. A field of 48 teams, 104 matches, and three host nations already gives it a different face from older tournaments. Taeo, when I see those numbers, I think before anything else about travel distance, recovery time, bench strength, and the ability to decode unfamiliar opponents quickly. The longer a tournament becomes, the more it depends on a whole structure of endurance rather than one star.\n\nSo reading the future is not the same as guessing one winner like a fortune teller. It is practice in seeing which team can survive the minutes when set-pieces begin to tilt a match, which side can keep its rhythm over a long road, and which squad can hold real competitive level from players eighteen through twenty-three. The longer you read World Cup history, the sooner those conditions begin to stand out.\n\nI want you to read 2026 the same way you read the past. Do not write down only the team name. Write down the pressing, the transitions, the set-pieces, and the defensive line stability beside it. Then you will understand that good prediction grows out of good memory.'**
  String get educationStoryFutureBody;

  /// No description provided for @educationStoryClosingBody.
  ///
  /// In en, this message translates to:
  /// **'In the end, Taeo, watching the World Cup well is not about memorizing one final score. It is about following the long thread from the first voyage in 1930 to the next question waiting in 2026. Every time you read that story, I hope you learn to see people more clearly than numbers, the air more clearly than the result, and an era more clearly than a single match.'**
  String get educationStoryClosingBody;

  /// No description provided for @educationHeroEyebrow.
  ///
  /// In en, this message translates to:
  /// **'YOUTH SESSION KIT'**
  String get educationHeroEyebrow;

  /// No description provided for @educationHeroTitle.
  ///
  /// In en, this message translates to:
  /// **'Youth football content you can coach right away'**
  String get educationHeroTitle;

  /// No description provided for @educationHeroBody.
  ///
  /// In en, this message translates to:
  /// **'Keep the explanations short, the repetitions high, and finish with one question. These three sessions are built for that flow.'**
  String get educationHeroBody;

  /// No description provided for @educationHeroStatLessons.
  ///
  /// In en, this message translates to:
  /// **'3 ready lessons'**
  String get educationHeroStatLessons;

  /// No description provided for @educationHeroStatMinutes.
  ///
  /// In en, this message translates to:
  /// **'45-minute flow'**
  String get educationHeroStatMinutes;

  /// No description provided for @educationHeroStatPrinciples.
  ///
  /// In en, this message translates to:
  /// **'Coach cues included'**
  String get educationHeroStatPrinciples;

  /// No description provided for @educationHeroStatHistory.
  ///
  /// In en, this message translates to:
  /// **'Quiz history included'**
  String get educationHeroStatHistory;

  /// No description provided for @educationSectionLessonsTitle.
  ///
  /// In en, this message translates to:
  /// **'Ready Lessons'**
  String get educationSectionLessonsTitle;

  /// No description provided for @educationSectionHistoryTitle.
  ///
  /// In en, this message translates to:
  /// **'Quiz History Study'**
  String get educationSectionHistoryTitle;

  /// No description provided for @educationSectionHistoryBody.
  ///
  /// In en, this message translates to:
  /// **'These cards group together the years, competition names, and iconic moments that appear often in the quiz. Review one card, then jump straight into a round while the timeline is still fresh.'**
  String get educationSectionHistoryBody;

  /// No description provided for @educationSectionPrinciplesTitle.
  ///
  /// In en, this message translates to:
  /// **'Coaching Principles'**
  String get educationSectionPrinciplesTitle;

  /// No description provided for @educationHistoryWorldCupEyebrow.
  ///
  /// In en, this message translates to:
  /// **'WORLD CUP ROOTS'**
  String get educationHistoryWorldCupEyebrow;

  /// No description provided for @educationHistoryWorldCupTitle.
  ///
  /// In en, this message translates to:
  /// **'World Cup Foundations'**
  String get educationHistoryWorldCupTitle;

  /// No description provided for @educationHistoryWorldCupSummary.
  ///
  /// In en, this message translates to:
  /// **'Use one card to lock in the first tournament, trophy change, and headline records that frame many World Cup history questions.'**
  String get educationHistoryWorldCupSummary;

  /// No description provided for @educationHistoryWorldCupFocus.
  ///
  /// In en, this message translates to:
  /// **'Year + host'**
  String get educationHistoryWorldCupFocus;

  /// No description provided for @educationHistoryWorldCupFact1.
  ///
  /// In en, this message translates to:
  /// **'The first FIFA World Cup was held in Uruguay in 1930.'**
  String get educationHistoryWorldCupFact1;

  /// No description provided for @educationHistoryWorldCupFact2.
  ///
  /// In en, this message translates to:
  /// **'The Jules Rimet Trophy was used through 1970, and the current FIFA World Cup Trophy has been used since 1974.'**
  String get educationHistoryWorldCupFact2;

  /// No description provided for @educationHistoryWorldCupFact3.
  ///
  /// In en, this message translates to:
  /// **'Brazil is the most common answer for the most men’s World Cup titles, and Miroslav Klose is the landmark all-time scorer.'**
  String get educationHistoryWorldCupFact3;

  /// No description provided for @educationHistoryCompetitionEyebrow.
  ///
  /// In en, this message translates to:
  /// **'COMPETITION TIMELINE'**
  String get educationHistoryCompetitionEyebrow;

  /// No description provided for @educationHistoryCompetitionTitle.
  ///
  /// In en, this message translates to:
  /// **'Competition Names And Launches'**
  String get educationHistoryCompetitionTitle;

  /// No description provided for @educationHistoryCompetitionSummary.
  ///
  /// In en, this message translates to:
  /// **'League and European competition questions get easier when you pair launch years with inaugural champions or rebrand seasons.'**
  String get educationHistoryCompetitionSummary;

  /// No description provided for @educationHistoryCompetitionFocus.
  ///
  /// In en, this message translates to:
  /// **'Launch + first champion'**
  String get educationHistoryCompetitionFocus;

  /// No description provided for @educationHistoryCompetitionFact1.
  ///
  /// In en, this message translates to:
  /// **'The Premier League launched in 1992, and Manchester United won the inaugural 1992-93 title.'**
  String get educationHistoryCompetitionFact1;

  /// No description provided for @educationHistoryCompetitionFact2.
  ///
  /// In en, this message translates to:
  /// **'The European Cup began operating as the UEFA Champions League from the 1992-93 season.'**
  String get educationHistoryCompetitionFact2;

  /// No description provided for @educationHistoryCompetitionFact3.
  ///
  /// In en, this message translates to:
  /// **'Arsenal’s 2003-04 Invincibles season is one of the most common Premier League history anchors.'**
  String get educationHistoryCompetitionFact3;

  /// No description provided for @educationHistoryMomentsEyebrow.
  ///
  /// In en, this message translates to:
  /// **'ICONIC MOMENTS'**
  String get educationHistoryMomentsEyebrow;

  /// No description provided for @educationHistoryMomentsTitle.
  ///
  /// In en, this message translates to:
  /// **'Iconic Moments And Women’s Football'**
  String get educationHistoryMomentsTitle;

  /// No description provided for @educationHistoryMomentsSummary.
  ///
  /// In en, this message translates to:
  /// **'Pair famous scenes with both the year and the opponent, and keep women’s football on its own timeline for faster recall.'**
  String get educationHistoryMomentsSummary;

  /// No description provided for @educationHistoryMomentsFocus.
  ///
  /// In en, this message translates to:
  /// **'Moment + opponent'**
  String get educationHistoryMomentsFocus;

  /// No description provided for @educationHistoryMomentsFact1.
  ///
  /// In en, this message translates to:
  /// **'Maradona’s “Hand of God” happened against England at the 1986 World Cup.'**
  String get educationHistoryMomentsFact1;

  /// No description provided for @educationHistoryMomentsFact2.
  ///
  /// In en, this message translates to:
  /// **'Zidane’s headbutt is an iconic scene from the 2006 FIFA World Cup final.'**
  String get educationHistoryMomentsFact2;

  /// No description provided for @educationHistoryMomentsFact3.
  ///
  /// In en, this message translates to:
  /// **'The first FIFA Women’s World Cup was held in China in 1991.'**
  String get educationHistoryMomentsFact3;

  /// No description provided for @educationModuleBallEyebrow.
  ///
  /// In en, this message translates to:
  /// **'BALL MASTERY'**
  String get educationModuleBallEyebrow;

  /// No description provided for @educationModuleBallTitle.
  ///
  /// In en, this message translates to:
  /// **'Increase Touch Count'**
  String get educationModuleBallTitle;

  /// No description provided for @educationModuleBallSummary.
  ///
  /// In en, this message translates to:
  /// **'A session that keeps both-foot inside and outside touches plus turns connected so younger players get comfortable with the ball.'**
  String get educationModuleBallSummary;

  /// No description provided for @educationModuleBallAge.
  ///
  /// In en, this message translates to:
  /// **'U8-U10'**
  String get educationModuleBallAge;

  /// No description provided for @educationModuleBallDuration.
  ///
  /// In en, this message translates to:
  /// **'12 min'**
  String get educationModuleBallDuration;

  /// No description provided for @educationModuleBallCue1.
  ///
  /// In en, this message translates to:
  /// **'Let the eyes come up sometimes while the feet stay light and active.'**
  String get educationModuleBallCue1;

  /// No description provided for @educationModuleBallCue2.
  ///
  /// In en, this message translates to:
  /// **'Before asking for speed, check that the ball stays close to the body.'**
  String get educationModuleBallCue2;

  /// No description provided for @educationModuleBallCue3.
  ///
  /// In en, this message translates to:
  /// **'After mistakes, encourage the next touch instead of stopping the drill.'**
  String get educationModuleBallCue3;

  /// No description provided for @educationModulePassEyebrow.
  ///
  /// In en, this message translates to:
  /// **'FIRST TOUCH & PASS'**
  String get educationModulePassEyebrow;

  /// No description provided for @educationModulePassTitle.
  ///
  /// In en, this message translates to:
  /// **'First Touch Into Pass'**
  String get educationModulePassTitle;

  /// No description provided for @educationModulePassSummary.
  ///
  /// In en, this message translates to:
  /// **'Receive, turn, and release. This session links touch direction with passing accuracy in one flow.'**
  String get educationModulePassSummary;

  /// No description provided for @educationModulePassAge.
  ///
  /// In en, this message translates to:
  /// **'U10-U12'**
  String get educationModulePassAge;

  /// No description provided for @educationModulePassDuration.
  ///
  /// In en, this message translates to:
  /// **'15 min'**
  String get educationModulePassDuration;

  /// No description provided for @educationModulePassCue1.
  ///
  /// In en, this message translates to:
  /// **'Ask players to scan over the shoulder once before receiving.'**
  String get educationModulePassCue1;

  /// No description provided for @educationModulePassCue2.
  ///
  /// In en, this message translates to:
  /// **'Coach the first touch into the space where the next pass should go.'**
  String get educationModulePassCue2;

  /// No description provided for @educationModulePassCue3.
  ///
  /// In en, this message translates to:
  /// **'Set the body shape and contact surface before asking for stronger pace.'**
  String get educationModulePassCue3;

  /// No description provided for @educationModuleDecisionEyebrow.
  ///
  /// In en, this message translates to:
  /// **'1V1 DECISION'**
  String get educationModuleDecisionEyebrow;

  /// No description provided for @educationModuleDecisionTitle.
  ///
  /// In en, this message translates to:
  /// **'1v1 Breakthrough And Choice'**
  String get educationModuleDecisionTitle;

  /// No description provided for @educationModuleDecisionSummary.
  ///
  /// In en, this message translates to:
  /// **'A decision session built around changing speed, freezing the defender, then finishing with either a shot or a pass.'**
  String get educationModuleDecisionSummary;

  /// No description provided for @educationModuleDecisionAge.
  ///
  /// In en, this message translates to:
  /// **'U11-U13'**
  String get educationModuleDecisionAge;

  /// No description provided for @educationModuleDecisionDuration.
  ///
  /// In en, this message translates to:
  /// **'18 min'**
  String get educationModuleDecisionDuration;

  /// No description provided for @educationModuleDecisionCue1.
  ///
  /// In en, this message translates to:
  /// **'Make the first step big, then keep the direction change short and sharp.'**
  String get educationModuleDecisionCue1;

  /// No description provided for @educationModuleDecisionCue2.
  ///
  /// In en, this message translates to:
  /// **'Praise the timing and preparation first, not only the final result.'**
  String get educationModuleDecisionCue2;

  /// No description provided for @educationModuleDecisionCue3.
  ///
  /// In en, this message translates to:
  /// **'After a success, revisit why it worked in one short sentence.'**
  String get educationModuleDecisionCue3;

  /// No description provided for @educationPrincipleOneTitle.
  ///
  /// In en, this message translates to:
  /// **'One cue at a time'**
  String get educationPrincipleOneTitle;

  /// No description provided for @educationPrincipleOneBody.
  ///
  /// In en, this message translates to:
  /// **'Keep instructions short and actionable. Single-word cues such as \"open\", \"scan\", and \"connect\" work well.'**
  String get educationPrincipleOneBody;

  /// No description provided for @educationPrincipleTwoTitle.
  ///
  /// In en, this message translates to:
  /// **'Find praise right after mistakes'**
  String get educationPrincipleTwoTitle;

  /// No description provided for @educationPrincipleTwoBody.
  ///
  /// In en, this message translates to:
  /// **'If you praise the preparation instead of only the outcome, players keep trying instead of freezing.'**
  String get educationPrincipleTwoBody;

  /// No description provided for @educationPrincipleThreeTitle.
  ///
  /// In en, this message translates to:
  /// **'Use the last two minutes for questions'**
  String get educationPrincipleThreeTitle;

  /// No description provided for @educationPrincipleThreeBody.
  ///
  /// In en, this message translates to:
  /// **'Ask what felt easy today and what they want to change next time. That reflection helps the lesson stick.'**
  String get educationPrincipleThreeBody;

  /// No description provided for @educationBookSectionStory.
  ///
  /// In en, this message translates to:
  /// **'Taeo\'s Scene'**
  String get educationBookSectionStory;

  /// No description provided for @educationBookSectionTimeline.
  ///
  /// In en, this message translates to:
  /// **'Core Timeline'**
  String get educationBookSectionTimeline;

  /// No description provided for @educationBookSectionFacts.
  ///
  /// In en, this message translates to:
  /// **'Memory Data'**
  String get educationBookSectionFacts;

  /// No description provided for @educationBookSectionNote.
  ///
  /// In en, this message translates to:
  /// **'Taeo\'s Note'**
  String get educationBookSectionNote;

  /// No description provided for @educationBookSwipeHint.
  ///
  /// In en, this message translates to:
  /// **'Pages turn only with a side swipe. Read each chapter by slowly scrolling downward.'**
  String get educationBookSwipeHint;

  /// No description provided for @educationBookPreviousButton.
  ///
  /// In en, this message translates to:
  /// **'Previous'**
  String get educationBookPreviousButton;

  /// No description provided for @educationBookNextButton.
  ///
  /// In en, this message translates to:
  /// **'Next'**
  String get educationBookNextButton;

  /// No description provided for @educationBookProgressLabel.
  ///
  /// In en, this message translates to:
  /// **'{current}/{total} chapters'**
  String educationBookProgressLabel(int current, int total);

  /// No description provided for @educationBookCoverLabel.
  ///
  /// In en, this message translates to:
  /// **'Prologue'**
  String get educationBookCoverLabel;

  /// No description provided for @educationBookCoverTitle.
  ///
  /// In en, this message translates to:
  /// **'Taking the World Cup Down From a Shelf at Night'**
  String get educationBookCoverTitle;

  /// No description provided for @educationBookCoverSubtitle.
  ///
  /// In en, this message translates to:
  /// **'How Taeo opens the first page of a history book'**
  String get educationBookCoverSubtitle;

  /// No description provided for @educationBookCoverStory.
  ///
  /// In en, this message translates to:
  /// **'On some nights after training, paper feels heavier than the ball. Taeo runs a cooling hand along a shelf of old World Cup programmes. The pages smell faintly of dust, and inside them lie the port of Montevideo, the steps of the Maracana, the sunlight over the Azteca, and the polished night above Lusail. It feels as if someone folded whole seasons into paper and left them here for later.\n\nThis book does not try to explain all of football. It follows only one river: the World Cup. It begins in Uruguay in 1930, passes through Qatar in 2022, and pauses at the far edge of 2026 in North America, still waiting to be written. Taeo likes that restraint. Sometimes looking at one thing for a long time is more exact than trying to hold everything at once.\n\nSo he writes down 1930, 1950, 1958, 1970, 1986, 1998, 2002, 2010, 2018, 2022, and 2026 on a blank page. Years look like numbers, but if you stare at them long enough, they begin to feel like rooms with different temperatures. One room holds Pele\'s smile. One holds the silence of the Maracana. Another keeps the moment Messi finally lets himself exhale. Tonight Taeo decides to touch each doorknob in turn.'**
  String get educationBookCoverStory;

  /// No description provided for @educationBookCoverTimeline.
  ///
  /// In en, this message translates to:
  /// **'FIFA was founded in 1904, building the administrative frame that later made the World Cup possible.\nThe first men\'s FIFA World Cup was held in Uruguay in 1930.\nThe 1942 and 1946 editions were cancelled because of World War II.\nFrom 1974 onward, the current FIFA World Cup Trophy replaced the Jules Rimet Trophy.\nFrance 1998 expanded the finals to a 32-team format.\nRussia 2018 was the first men\'s World Cup with full VAR implementation.\nCanada, Mexico, and the United States are due to stage a 48-team, 104-match tournament in 2026.'**
  String get educationBookCoverTimeline;

  /// No description provided for @educationBookCoverFacts.
  ///
  /// In en, this message translates to:
  /// **'Taeo\'s bookmark 1: through Qatar 2022, the men\'s World Cup has been completed 22 times.\nTaeo\'s bookmark 2: Brazil with 5 titles, Germany with 4, Italy with 4, and Argentina with 3 are the main title anchors.\nTaeo\'s bookmark 3: Miroslav Klose\'s 16 goals remain the all-time men\'s World Cup scoring record.\nTaeo\'s bookmark 4: World Cup history sticks best when year, host, champion, iconic scene, and leading figure are grouped together.'**
  String get educationBookCoverFacts;

  /// No description provided for @educationBookCoverNote.
  ///
  /// In en, this message translates to:
  /// **'Taeo writes that this book is not just a list of winners. It is a chronicle of what kind of face the world showed every four years. That is why he chooses to remember the latest completed tournament in 2022 and the next door opening in 2026 side by side.'**
  String get educationBookCoverNote;

  /// No description provided for @educationBookOriginsLabel.
  ///
  /// In en, this message translates to:
  /// **'Chapter 1'**
  String get educationBookOriginsLabel;

  /// No description provided for @educationBookOriginsTitle.
  ///
  /// In en, this message translates to:
  /// **'The First Summer Arrived By Ship'**
  String get educationBookOriginsTitle;

  /// No description provided for @educationBookOriginsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Uruguay 1930, Italy 1934, and France 1938'**
  String get educationBookOriginsSubtitle;

  /// No description provided for @educationBookOriginsStory.
  ///
  /// In en, this message translates to:
  /// **'The first chapter begins in an age when ships mattered more than planes. European teams spent weeks crossing the sea to reach Uruguay, and the hosts finished the Estadio Centenario in a rush thick with the heat of a centenary celebration. By modern standards everything was slow and inconvenient, yet that slowness makes the tournament seem sharper. Big events often arrive carrying a little discomfort with them. The World Cup knew that from the start.\n\nAs Uruguay become the first champions in 1930 and Italy follow with titles in 1934 and 1938, Taeo finds himself reading the air around the results before the scorelines themselves. Mussolini\'s shadow stretches over one tournament. War has not yet begun, but it is already walking quietly through the corridors of Europe. The World Cup starts resembling the world much earlier than he expected. Travel, politics, boycotts, and refereeing arguments all enter the same cover.\n\nReading this period, Taeo learns that the World Cup was never innocent in its earliest form. The sea delayed the teams, but it also made the tournament look like legend. Things that take a long time to arrive are rarely forgotten. So he decides to remember 1930, 1934, and 1938 not only as numbers, but as the smell of salt, the tone of speeches, and the sound of uneasy applause.'**
  String get educationBookOriginsStory;

  /// No description provided for @educationBookOriginsTimeline.
  ///
  /// In en, this message translates to:
  /// **'Uruguay 1930 featured only 13 teams, but the hosts became the first champions and set the tone of the tournament.\nThe 1930 final ended as a South American duel, with Uruguay beating Argentina 4-2.\nItaly 1934 was the first World Cup to apply a fully developed qualification path before the finals.\nUruguay skipped the 1934 tournament in protest after many European teams had stayed away from 1930.\nUnder coach Vittorio Pozzo, Italy won back-to-back titles in 1934 and 1938.\nAt France 1938, the Dutch East Indies became the first Asian team to appear in the men\'s World Cup finals.'**
  String get educationBookOriginsTimeline;

  /// No description provided for @educationBookOriginsFacts.
  ///
  /// In en, this message translates to:
  /// **'Jules Rimet was the central administrator who pushed the tournament into existence and later gave his name to the original trophy.\nVittorio Pozzo is still the only coach to win back-to-back men\'s World Cups.\nThe long travel distance between Europe and South America shaped participation more heavily than modern fans often expect.\nTaeo files away 1930, 1934, and 1938 as the first tournament, the first full qualifying era, and the first back-to-back title run.'**
  String get educationBookOriginsFacts;

  /// No description provided for @educationBookOriginsNote.
  ///
  /// In en, this message translates to:
  /// **'Taeo keeps 1930, 1934, and 1938 as one cluster. The first tournament, the first qualification era, and the first repeat champions all arrived together. From the very beginning, the World Cup was already more than football.'**
  String get educationBookOriginsNote;

  /// No description provided for @educationBookWorldCupLabel.
  ///
  /// In en, this message translates to:
  /// **'Chapter 2'**
  String get educationBookWorldCupLabel;

  /// No description provided for @educationBookWorldCupTitle.
  ///
  /// In en, this message translates to:
  /// **'How Silence and Celebration Stay in the Same Stadium'**
  String get educationBookWorldCupTitle;

  /// No description provided for @educationBookWorldCupSubtitle.
  ///
  /// In en, this message translates to:
  /// **'From Brazil 1950 to Mexico 1970'**
  String get educationBookWorldCupSubtitle;

  /// No description provided for @educationBookWorldCupStory.
  ///
  /// In en, this message translates to:
  /// **'When the World Cup returned in Brazil in 1950 after two empty summers lost to war, people probably expected celebration first. But the first scene Taeo meets is silence. Uruguay\'s win over Brazil in the decisive match at the Maracana shows him that one result can alter the volume of an entire country. From that point on, the World Cup looks less like a sports event than a machine for making collective memory.\n\nThe pages that follow turn into legend with surprising speed. The Miracle of Bern in 1954. Seventeen-year-old Pele arriving in 1958. Brazil carried by Garrincha in 1962. England\'s one and only title in 1966. The golden Brazil of 1970 in Mexico. The more Taeo reads, the clearer it becomes that history books borrow faces and movement in order to stay alive. Someone falls. Someone appears. Someone becomes so complete that he starts to look invented.\n\nSo Taeo folds 1950 through 1970 into five words: restart, shock, birth, revenge, completion. On paper that feels small enough to fit in one hand. But the feelings inside those words do not shrink with them. The silence of the Maracana and the smile of Pele remain, each in a different direction, for a very long time.'**
  String get educationBookWorldCupStory;

  /// No description provided for @educationBookWorldCupTimeline.
  ///
  /// In en, this message translates to:
  /// **'Brazil 1950 used a final group instead of a one-match final, and Uruguay\'s win over Brazil became the Maracana shock.\nWest Germany beat mighty Hungary in 1954 to create the Miracle of Bern.\nAt Sweden 1958, 17-year-old Pele rose as the game\'s brightest new star.\nBrazil retained the trophy in Chile 1962 with Garrincha carrying the side through key matches.\nEngland won their only men\'s World Cup in 1966, with Geoff Hurst scoring a famous hat-trick in the final.\nBrazil\'s third title in Mexico 1970 gave them permanent ownership of the Jules Rimet Trophy.\nCarlos Alberto\'s goal in the 1970 final is still replayed as the symbol of collective team football.'**
  String get educationBookWorldCupTimeline;

  /// No description provided for @educationBookWorldCupFacts.
  ///
  /// In en, this message translates to:
  /// **'Hungary arrived at the 1954 final as the team many saw as the strongest in the world.\nJairzinho scored in every match Brazil played during their 1970 title run.\nGordon Banks\' save from Pele\'s header is still labeled by many as the save of the century.\nTaeo groups together the Maracana shock of 1950, the emergence of Pele in 1958, and Brazil\'s masterpiece in 1970.'**
  String get educationBookWorldCupFacts;

  /// No description provided for @educationBookWorldCupNote.
  ///
  /// In en, this message translates to:
  /// **'Taeo writes that the World Cup from 1950 to 1970 was both a return ceremony after war and the biggest stage in the world for introducing a new genius.'**
  String get educationBookWorldCupNote;

  /// No description provided for @educationBookClubLabel.
  ///
  /// In en, this message translates to:
  /// **'Chapter 3'**
  String get educationBookClubLabel;

  /// No description provided for @educationBookClubTitle.
  ///
  /// In en, this message translates to:
  /// **'An Era Where Beauty and Discomfort Grow Together'**
  String get educationBookClubTitle;

  /// No description provided for @educationBookClubSubtitle.
  ///
  /// In en, this message translates to:
  /// **'From West Germany 1974 to Italy 1990'**
  String get educationBookClubSubtitle;

  /// No description provided for @educationBookClubStory.
  ///
  /// In en, this message translates to:
  /// **'By 1974, the air inside the book changes. The trophy changes too. The Netherlands shake the coordinates of the pitch with total football, and West Germany finally arranges that beautiful chaos into a result. Whenever Taeo reads this chapter, he thinks football is one of the few places where idealism and reality collide in full public view. Grace is easy to love, but the trophy usually leans toward something heavier.\n\nYet this era cannot be explained by tactics alone. Argentina 1978 carries the chill of military rule. In 1982, Battiston\'s fall tears open the time of the match itself. Maradona in 1986 appears less like a player than a weather system. The Hand of God and the goal past five men happen in the same summer, and the contradiction only makes the face of the World Cup clearer.\n\nBy the time Taeo reaches 1990, he understands that an era does not always end in a tidy sentence. Roger Milla\'s dancing, Beckenbauer\'s title as a coach, and Maradona\'s tears remain at different temperatures. History lasts longer when it is slightly mixed rather than perfectly arranged. So he binds this stretch together only loosely, with four words: beauty, discomfort, talent, and argument.'**
  String get educationBookClubStory;

  /// No description provided for @educationBookClubTimeline.
  ///
  /// In en, this message translates to:
  /// **'West Germany 1974 was the first tournament to award the current FIFA World Cup Trophy.\nCruyff\'s turn and the Netherlands\' total football left images that outlived even the final result.\nArgentina won their first title in 1978, but the tournament remains tied to the political climate of the junta.\nSpain 1982 was the first men\'s World Cup with 24 teams.\nFrance against West Germany in the 1982 semifinal was the first World Cup match decided by a penalty shootout and is also remembered for the Schumacher-Battiston collision.\nMaradona\'s 1986 performance against England gave football both the Hand of God and the Goal of the Century.\nCameroon reached the quarter-finals in 1990, becoming the first African team to go that far in the men\'s World Cup.'**
  String get educationBookClubTimeline;

  /// No description provided for @educationBookClubFacts.
  ///
  /// In en, this message translates to:
  /// **'Franz Beckenbauer stands as a defining symbol because he won the World Cup as a player in 1974 and as a coach in 1990.\nPaolo Rossi returned from suspension in time to become the face of Italy\'s 1982 title.\nItaly 1990 is often cited as a tournament whose defensive trend helped push later rule discussions.\nTaeo groups 1974, 1978, 1982, 1986, and 1990 as World Cup years that left both beauty and discomfort behind.'**
  String get educationBookClubFacts;

  /// No description provided for @educationBookClubNote.
  ///
  /// In en, this message translates to:
  /// **'Taeo writes that this period proves the World Cup does not leave behind only clean, beautiful stories. That is also why it lasts. History has to remember what made people uncomfortable as well as what made them cheer.'**
  String get educationBookClubNote;

  /// No description provided for @educationBookTacticsLabel.
  ///
  /// In en, this message translates to:
  /// **'Chapter 4'**
  String get educationBookTacticsLabel;

  /// No description provided for @educationBookTacticsTitle.
  ///
  /// In en, this message translates to:
  /// **'When the World Cup Walked From Television Into the Living Room'**
  String get educationBookTacticsTitle;

  /// No description provided for @educationBookTacticsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'USA 1994, France 1998, Korea and Japan 2002, Germany 2006'**
  String get educationBookTacticsSubtitle;

  /// No description provided for @educationBookTacticsStory.
  ///
  /// In en, this message translates to:
  /// **'By USA 1994, Taeo sees the tournament acquiring a completely different size. Giant stadiums, the brightness of the advertising boards, the heat spreading through television screens, and Baggio\'s kick rising into the sky all settle into the same memory. The World Cup no longer feels like a distant celebration in another country. It feels like a huge piece of furniture suddenly placed in the middle of the living room. No one passes it without noticing.\n\nAs he moves through Zidane\'s France in 1998, Korea\'s semi-final run and Ronaldo\'s redemption in 2002, and Zidane\'s headbutt in the 2006 final, Taeo starts to feel that these tournaments are unusually friendly to replay. Strong scenes are easy to repeat, and repeated scenes become shared memory for a generation. For him, 2002 is not someone else\'s history at all. It comes with the shouting in nearby streets, the empty cans under the television, and the night air that took a long time to settle after the final whistle.\n\nSeen that way, the World Cup is always slightly wider than the scoreline. Some tournaments are remembered less for who scored than for what kind of night they became. When Taeo thinks of 1994, 1998, 2002, and 2006, he remembers faces, noise, and camera angles before he remembers the numbers. Maybe that is how modern history books are written now.'**
  String get educationBookTacticsStory;

  /// No description provided for @educationBookTacticsTimeline.
  ///
  /// In en, this message translates to:
  /// **'The 1994 final was the first men\'s World Cup final decided by a penalty shootout.\nRoberto Baggio\'s miss in 1994 became one of the best-known images in World Cup history.\nFrance 1998 marked the beginning of the 32-team finals format.\nLaurent Blanc scored the first golden goal in World Cup history at France 1998.\nKorea and Japan 2002 became the first co-hosts of a men\'s World Cup, and South Korea reached the semi-finals.\nRonaldo scored eight times in 2002 and turned the pain of the 1998 final into a story of redemption.\nGermany 2006 ended with Zidane\'s red card in the final and Italy taking the title.'**
  String get educationBookTacticsTimeline;

  /// No description provided for @educationBookTacticsFacts.
  ///
  /// In en, this message translates to:
  /// **'Names such as Hiddink, Scolari, and Lippi are attached to the memory of this era as strongly as the players are.\nCroatia\'s Davor Suker won the Golden Boot in 1998 while his team surged to third place.\nSenegal\'s run to the quarter-finals and Turkey\'s run to the semi-finals in 2002 showed again that the World Cup is never moved only by the giants.\nTaeo writes that 1994, 1998, 2002, and 2006 have to be remembered through their final scenes to stay alive.'**
  String get educationBookTacticsFacts;

  /// No description provided for @educationBookTacticsNote.
  ///
  /// In en, this message translates to:
  /// **'Taeo lingers especially long over the 2002 chapter. For Korean fans, World Cup history is not a distant timeline. It is a memory line that touches home directly. That is why he decides to remember not only the result sheet, but the atmosphere and the sound around it too.'**
  String get educationBookTacticsNote;

  /// No description provided for @educationBookLegendsLabel.
  ///
  /// In en, this message translates to:
  /// **'Chapter 5'**
  String get educationBookLegendsLabel;

  /// No description provided for @educationBookLegendsTitle.
  ///
  /// In en, this message translates to:
  /// **'The More Numbers There Were, the Sharper the Scenes Became'**
  String get educationBookLegendsTitle;

  /// No description provided for @educationBookLegendsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'From South Africa 2010 to Qatar 2022'**
  String get educationBookLegendsSubtitle;

  /// No description provided for @educationBookLegendsStory.
  ///
  /// In en, this message translates to:
  /// **'When Taeo opens South Africa 2010, he hears the vuvuzelas first. Some tournaments are remembered through the ears before the eyes. Spain\'s title, Suarez\'s handball on the line, Ghana\'s exit, and the strange fame of Paul the Octopus show him that different kinds of seriousness can live inside the same month. The World Cup remains a history book, but it is also a storage room for rumor, jokes, and collective obsession.\n\nBy the time he reaches Brazil\'s 7-1 collapse in 2014, the full arrival of VAR in 2018, and the final in Qatar in 2022, Taeo starts to feel that more numbers do not blur the story. They sharpen the scenes instead. Klose\'s sixteenth goal, Mbappe\'s acceleration, the final missing piece in Messi\'s career, and Morocco\'s run to the semi-finals all push history from different angles. Data helps explain things, but what remains in the body is never data alone.\n\nWhenever Taeo reads the recent World Cups, he returns to the same conclusion. People remember scenes longer than tables. The 7-1 scoreboard. The silence in front of the VAR monitor. The brief moment when Messi lowers his head after extra time. Records are filed away on shelves. Scenes stick to the inside of the body.'**
  String get educationBookLegendsStory;

  /// No description provided for @educationBookLegendsTimeline.
  ///
  /// In en, this message translates to:
  /// **'South Africa 2010 was the first men\'s World Cup held on the African continent.\nSpain won their first World Cup in 2010 thanks to Iniesta\'s extra-time goal in the final.\nSuarez\'s handball against Ghana in 2010 became one of the hottest argument scenes in World Cup memory.\nGermany beat Brazil 7-1 in the 2014 semi-final and then went on to win the title.\nKlose\'s goal against Brazil in 2014 set the men\'s World Cup all-time scoring record at 16.\nRussia 2018 was the first men\'s World Cup with full VAR use throughout the tournament.\nAt Qatar 2022, Morocco reached the semi-finals and Argentina won with Messi at the center.'**
  String get educationBookLegendsTimeline;

  /// No description provided for @educationBookLegendsFacts.
  ///
  /// In en, this message translates to:
  /// **'Paul the Octopus became a prediction icon in 2010 by repeatedly getting match outcomes right.\nKylian Mbappe\'s 2018 title and 2022 final hat-trick built the strongest young World Cup narrative since Pele.\nLionel Messi used 2022 to fill the final empty space in his World Cup career.\nTaeo remembers 2010, 2014, 2018, and 2022 through five feelings: sound, collapse, technology, youth, and completion.'**
  String get educationBookLegendsFacts;

  /// No description provided for @educationBookLegendsNote.
  ///
  /// In en, this message translates to:
  /// **'Taeo writes that even in the most data-heavy World Cups, people still remember scenes first. The vuvuzelas, the 7-1 scoreboard, the VAR check, and Messi\'s smile stay longer than any spreadsheet.'**
  String get educationBookLegendsNote;

  /// No description provided for @educationBookAsiaLabel.
  ///
  /// In en, this message translates to:
  /// **'Chapter 6'**
  String get educationBookAsiaLabel;

  /// No description provided for @educationBookAsiaTitle.
  ///
  /// In en, this message translates to:
  /// **'The Moment Faces Come to Mind Before Years'**
  String get educationBookAsiaTitle;

  /// No description provided for @educationBookAsiaSubtitle.
  ///
  /// In en, this message translates to:
  /// **'From Jules Rimet to Pele, Maradona, Beckenbauer, and Messi'**
  String get educationBookAsiaSubtitle;

  /// No description provided for @educationBookAsiaStory.
  ///
  /// In en, this message translates to:
  /// **'At some point Taeo begins to remember the World Cup through faces before he remembers it through years. Jules Rimet, who helped make the tournament possible. Pozzo, who shaped back-to-back titles. Pele, who stood at the top three times. Beckenbauer, who passed through both the door of player and the door of coach. Maradona, who turned one summer into myth. Read one by one, these names give history a surprisingly personal expression. Even a massive tournament can end up summarized by the breathing of a few people.\n\nNone of the figures in this chapter are complete. Garrincha carries an injured team. Ronaldo turns the memory of one lost final inside out four years later. Zidane leaves behind both genius and fracture. Messi finishes his own sentence only at the end. So Taeo feels that the World Cup is not really a place that creates heroes from nothing. It is a place that enlarges the outline of people who were already shaking.\n\nHe always writes a year and a scene next to the name. Pele means 1958 and 1970. Maradona means 1986. Ronaldo means 2002. Messi means 2022. Names alone feel like exam notes. Add the scene, and suddenly they become stories. Perhaps history books survive only in that form.'**
  String get educationBookAsiaStory;

  /// No description provided for @educationBookAsiaTimeline.
  ///
  /// In en, this message translates to:
  /// **'Jules Rimet gave the competition both its early political drive and the name of its first trophy.\nVittorio Pozzo coached Italy to back-to-back titles in 1934 and 1938.\nPele won the men\'s World Cup in 1958, 1962, and 1970, a record no other male player has matched.\nFranz Beckenbauer won the trophy as a player in 1974 and as a coach in 1990.\nMaradona\'s 1986 campaign is still large enough to explain a huge part of World Cup mythology by itself.\nRonaldo\'s eight goals in 2002 turned the pain of 1998 into one of football\'s cleanest redemption arcs.\nMessi and Mbappe used the 2022 final to show both a passing of generations and a collision of generations at once.'**
  String get educationBookAsiaTimeline;

  /// No description provided for @educationBookAsiaFacts.
  ///
  /// In en, this message translates to:
  /// **'Just Fontaine\'s 13 goals remain the all-time record for one single World Cup tournament.\nMiroslav Klose\'s 16 goals remain the all-time men\'s World Cup scoring record across multiple editions.\nMario Zagallo, Franz Beckenbauer, and Didier Deschamps are among the iconic figures who won the World Cup both as players and as coaches.\nTaeo records each figure in one line by pairing name, country, defining tournament, and defining scene.'**
  String get educationBookAsiaFacts;

  /// No description provided for @educationBookAsiaNote.
  ///
  /// In en, this message translates to:
  /// **'Taeo decides that the fastest way to remember the World Cup is to remember it through people. Years alone feel like a test. Faces and scenes turn it into a story.'**
  String get educationBookAsiaNote;

  /// No description provided for @educationBookWomenLabel.
  ///
  /// In en, this message translates to:
  /// **'Chapter 7'**
  String get educationBookWomenLabel;

  /// No description provided for @educationBookWomenTitle.
  ///
  /// In en, this message translates to:
  /// **'How to Read the Air Outside the Stadium Too'**
  String get educationBookWomenTitle;

  /// No description provided for @educationBookWomenSubtitle.
  ///
  /// In en, this message translates to:
  /// **'War, politics, theft, and the technology of judgement'**
  String get educationBookWomenSubtitle;

  /// No description provided for @educationBookWomenStory.
  ///
  /// In en, this message translates to:
  /// **'At some point Taeo decides that a history book listing only champions is slightly rude. The World Cup has never happened only inside the stadium. Some tournaments disappeared completely because of war. Some were played beneath dictatorship. Some are remembered as much for events beyond the pitch as for the football itself. The air of the wider world always seeps onto the grass.\n\nThe theft of the Jules Rimet Trophy in 1966 and its recovery by a dog called Pickles is so strange it almost refuses to feel true. Battiston falling in 1982, Lampard\'s disallowed goal in 2010, goal-line technology in 2014, VAR in 2018, and semi-automated offside in 2022 show how long football has wrestled with human imperfection in judgement. The sport always wants to become fairer, while knowing it can never become perfectly fair.\n\nSo Taeo writes two questions next to every tournament. Who won. And what changed. Put those sentences together, and the outline of an event becomes much clearer. History does not end at the scoreboard. It has to be read together with the air behind it.'**
  String get educationBookWomenStory;

  /// No description provided for @educationBookWomenTimeline.
  ///
  /// In en, this message translates to:
  /// **'The cancellations of 1942 and 1946 showed that world war could halt even football\'s grandest calendar.\nBefore England 1966 began, the Jules Rimet Trophy was stolen and then found by a dog named Pickles.\nArgentina 1978 remains tied to the political pressure of the ruling military regime.\nThe Schumacher-Battiston collision in the 1982 semi-final expanded the argument about sportsmanship and refereeing.\nFrank Lampard\'s disallowed goal against Germany in 2010 made the case for technical review even louder.\nGoal-line technology was used at Brazil 2014.\nVAR arrived in 2018 and semi-automated offside followed in 2022, changing the look of elite refereeing again.'**
  String get educationBookWomenTimeline;

  /// No description provided for @educationBookWomenFacts.
  ///
  /// In en, this message translates to:
  /// **'Pickles became the most famous dog in football history after helping recover the World Cup trophy.\nTechnology does not erase World Cup controversy. It changes the kind of controversy people argue about.\nPolitics and social conditions reshape host memory, crowd emotion, and the way a tournament is remembered.\nTaeo always writes the social setting next to the scoreline when he studies historic events.'**
  String get educationBookWomenFacts;

  /// No description provided for @educationBookWomenNote.
  ///
  /// In en, this message translates to:
  /// **'Taeo writes that the World Cup is not only the biggest football tournament. It is also a place where the era\'s politics, technology, and fairness arguments all gather at once. That is why he refuses to treat the off-field story as a footnote.'**
  String get educationBookWomenNote;

  /// No description provided for @educationBookModernLabel.
  ///
  /// In en, this message translates to:
  /// **'Chapter 8'**
  String get educationBookModernLabel;

  /// No description provided for @educationBookModernTitle.
  ///
  /// In en, this message translates to:
  /// **'Things Worth Writing Down While Waiting for the Next Tournament'**
  String get educationBookModernTitle;

  /// No description provided for @educationBookModernSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Taeo\'s notes toward North America 2026'**
  String get educationBookModernSubtitle;

  /// No description provided for @educationBookModernStory.
  ///
  /// In en, this message translates to:
  /// **'Now the book walks slowly toward a tournament that has not yet been played. North America 2026 already wears a different expression: 48 teams, 104 matches, three host nations. When Taeo looks at those numbers, he thinks first not of favorites but of travel distance, recovery time, and the breathing of the bench. The longer a tournament becomes, the more it seems to depend on a whole way of enduring rather than on one star.\n\nThat is why this chapter feels closer to observation than prophecy. Which teams can decode unfamiliar opponents quickly. Which teams can survive the minutes when set pieces begin to tilt a match. Which teams can keep their rhythm over a long road. Taeo believes that the conditions of a strong side are usually born from dull detail rather than glamorous sentences. History, strangely enough, agrees with him more often than not.\n\nIt feels risky to speak too loudly about a tournament that has not yet arrived. The future usually comes in a drier form than expected, and predictions often miss. Even so, Taeo leaves a few pages blank. He thinks the last virtue of a history book is always the space it keeps for the next sentence.'**
  String get educationBookModernStory;

  /// No description provided for @educationBookModernTimeline.
  ///
  /// In en, this message translates to:
  /// **'The 2026 World Cup will be the first men\'s edition jointly hosted by Canada, Mexico, and the United States.\nFrom 2026 onward, the men\'s World Cup finals expand to 48 teams.\nA 48-team format means 104 matches, giving scheduling and rotation even more strategic weight.\nLong travel routes and climate variation are likely to matter more than in many previous editions.\nSet-pieces, bench scoring, and the speed of analytical preparation should rise in value in a longer event.\nTaeo decides to treat 2026 as a search for the conditions of strength rather than only a hunt for the winner.'**
  String get educationBookModernTimeline;

  /// No description provided for @educationBookModernFacts.
  ///
  /// In en, this message translates to:
  /// **'The longer a tournament becomes, the more the real competitive level of players 18 through 23 matters along with the starting eleven.\nA 48-team field also increases the chance of surprise runs from Asia, Africa, and Concacaf.\nTraditional giants still carry the greatest baseline, but the number of possible twists may grow with the format.\nWhen Taeo writes a prediction, he adds pressing, transitions, set-pieces, and defensive stability beside the team name.'**
  String get educationBookModernFacts;

  /// No description provided for @educationBookModernNote.
  ///
  /// In en, this message translates to:
  /// **'Taeo writes that prediction is not a game of lucky guesses. It is practice in reading the conditions of a strong team. That is why he writes more about why a side looks powerful than about the name itself.'**
  String get educationBookModernNote;

  /// No description provided for @educationBookFinaleLabel.
  ///
  /// In en, this message translates to:
  /// **'Epilogue'**
  String get educationBookFinaleLabel;

  /// No description provided for @educationBookFinaleTitle.
  ///
  /// In en, this message translates to:
  /// **'The Final Page Always Closes a Little More Slowly'**
  String get educationBookFinaleTitle;

  /// No description provided for @educationBookFinaleSubtitle.
  ///
  /// In en, this message translates to:
  /// **'An epilogue tying 1930 and 2026 into one line'**
  String get educationBookFinaleSubtitle;

  /// No description provided for @educationBookFinaleStory.
  ///
  /// In en, this message translates to:
  /// **'By the last page, Taeo starts to think the World Cup is really a very thick magazine published once every four years. The era keeps changing, but the title on the cover stays the same, and inside it the air, faces, and arguments of that moment are compressed together. The players who sailed to Uruguay and the players running under cameras and sensors today end up resting on the same spine. That feels slightly strange, and also exactly right.\n\nSome years remain because of names such as Pele, Maradona, and Messi. Some remain because of scores like the Maracana shock or 7-1. Some remain because of war, dictatorship, or the technology of judgement. So Taeo decides that reading the World Cup is not really about memorizing football. It is closer to running a hand along the grain of time. Once you realize that an era is folded behind a single match, even the score begins to weigh more.\n\nBefore he closes the book, he reads 1930, 1950, 1958, 1970, 1986, 1998, 2002, 2010, 2018, 2022, and 2026 one more time. Now they no longer sound like cold dates. They sound like room names under different lights. Some rooms are already behind him. One is still about to open. That, Taeo thinks, is why history books matter. They let you walk slowly through the space in between.'**
  String get educationBookFinaleStory;

  /// No description provided for @educationBookFinaleTimeline.
  ///
  /// In en, this message translates to:
  /// **'Taeo learned from the early World Cups how quickly the tournament moved into the center of world history.\nTaeo learned from the post-war era that one match can become a nation\'s memory.\nTaeo learned from recent tournaments that even in a data-heavy age, people still remember scenes and faces first.\nTaeo learned from the 2026 preview that reading the future begins by seeing the patterns of the past.'**
  String get educationBookFinaleTimeline;

  /// No description provided for @educationBookFinaleFacts.
  ///
  /// In en, this message translates to:
  /// **'Review anchor 1: tie together the year, host, champion, iconic scene, and leading figure in one line.\nReview anchor 2: 1930, 1950, 1970, 1986, 1998, 2002, 2018, and 2022 are non-negotiable review years.\nReview anchor 3: connect records to signature numbers such as Pele\'s 3 titles, Brazil\'s 5 titles, and Klose\'s 16 goals.\nReview anchor 4: predictions get stronger when tactics, fitness, and squad depth are written beside the team name.'**
  String get educationBookFinaleFacts;

  /// No description provided for @educationBookFinaleNote.
  ///
  /// In en, this message translates to:
  /// **'As he closes the book, Taeo writes the first line of his next journal like this. To really watch the World Cup well is not to memorize only one final score, but to follow the whole long story from the first kick in 1930 to the next question waiting in 2026.'**
  String get educationBookFinaleNote;

  /// No description provided for @familySharing.
  ///
  /// In en, this message translates to:
  /// **'Parent mode/player sharing'**
  String get familySharing;

  /// No description provided for @familySharedBackupDescription.
  ///
  /// In en, this message translates to:
  /// **'Use one shared Drive backup without a server. Player mode manages core records directly, while parent mode syncs only feedback and reward names.'**
  String get familySharedBackupDescription;

  /// No description provided for @familyBackupIncludesMedia.
  ///
  /// In en, this message translates to:
  /// **'Back up profile photos and training photos too when those files can be collected locally.'**
  String get familyBackupIncludesMedia;

  /// No description provided for @familyParentAutoSyncDescription.
  ///
  /// In en, this message translates to:
  /// **'In parent or coach mode, only training feedback and reward names sync automatically. Back up and restore player records from player mode.'**
  String get familyParentAutoSyncDescription;

  /// No description provided for @familyChildDriveConnectionTitle.
  ///
  /// In en, this message translates to:
  /// **'Connect shared backup Drive'**
  String get familyChildDriveConnectionTitle;

  /// No description provided for @familyChildDriveConnectionDescription.
  ///
  /// In en, this message translates to:
  /// **'In parent mode, connect the Google Drive account that holds the player\'s source data so both modes can share the same backup file.'**
  String get familyChildDriveConnectionDescription;

  /// No description provided for @familyConnectChildDrive.
  ///
  /// In en, this message translates to:
  /// **'Connect shared Drive'**
  String get familyConnectChildDrive;

  /// No description provided for @familyDisconnectChildDrive.
  ///
  /// In en, this message translates to:
  /// **'Disconnect shared Drive'**
  String get familyDisconnectChildDrive;

  /// No description provided for @familyRoleChild.
  ///
  /// In en, this message translates to:
  /// **'Player'**
  String get familyRoleChild;

  /// No description provided for @familyRolePlayer.
  ///
  /// In en, this message translates to:
  /// **'Player'**
  String get familyRolePlayer;

  /// No description provided for @familyRoleParent.
  ///
  /// In en, this message translates to:
  /// **'Parent'**
  String get familyRoleParent;

  /// No description provided for @familyRoleCoach.
  ///
  /// In en, this message translates to:
  /// **'Coach'**
  String get familyRoleCoach;

  /// No description provided for @familyRoleSelectionTitle.
  ///
  /// In en, this message translates to:
  /// **'Usage mode selection'**
  String get familyRoleSelectionTitle;

  /// No description provided for @familyRoleSelectionDescription.
  ///
  /// In en, this message translates to:
  /// **'Choose whether this device is used by the player directly, by a parent, or by a coach managing multiple players.'**
  String get familyRoleSelectionDescription;

  /// No description provided for @settingsUsageModeTitle.
  ///
  /// In en, this message translates to:
  /// **'Usage mode'**
  String get settingsUsageModeTitle;

  /// No description provided for @settingsRoleAndSyncTitle.
  ///
  /// In en, this message translates to:
  /// **'Usage & sync'**
  String get settingsRoleAndSyncTitle;

  /// No description provided for @settingsInfoTooltip.
  ///
  /// In en, this message translates to:
  /// **'Show description'**
  String get settingsInfoTooltip;

  /// No description provided for @settingsSupportModeLabel.
  ///
  /// In en, this message translates to:
  /// **'Parent'**
  String get settingsSupportModeLabel;

  /// No description provided for @settingsCoachRosterTitle.
  ///
  /// In en, this message translates to:
  /// **'Coach roster'**
  String get settingsCoachRosterTitle;

  /// No description provided for @settingsCoachRosterDescription.
  ///
  /// In en, this message translates to:
  /// **'Select the active player before writing feedback, reward names, or Drive backups.'**
  String get settingsCoachRosterDescription;

  /// No description provided for @settingsCoachRosterEmpty.
  ///
  /// In en, this message translates to:
  /// **'No players are registered yet.'**
  String get settingsCoachRosterEmpty;

  /// No description provided for @settingsCoachRosterAddPlayer.
  ///
  /// In en, this message translates to:
  /// **'Add player'**
  String get settingsCoachRosterAddPlayer;

  /// No description provided for @settingsCoachRosterEditPlayer.
  ///
  /// In en, this message translates to:
  /// **'Edit player'**
  String get settingsCoachRosterEditPlayer;

  /// No description provided for @settingsCoachRosterDeletePlayer.
  ///
  /// In en, this message translates to:
  /// **'Delete player'**
  String get settingsCoachRosterDeletePlayer;

  /// No description provided for @settingsCoachRosterDeleteTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete player'**
  String get settingsCoachRosterDeleteTitle;

  /// No description provided for @settingsCoachRosterDeleteMessage.
  ///
  /// In en, this message translates to:
  /// **'Delete {player} from the coach roster?'**
  String settingsCoachRosterDeleteMessage(Object player);

  /// No description provided for @settingsCoachRosterDeleted.
  ///
  /// In en, this message translates to:
  /// **'{player} was deleted.'**
  String settingsCoachRosterDeleted(Object player);

  /// No description provided for @settingsCoachRosterRenamed.
  ///
  /// In en, this message translates to:
  /// **'{player} was updated.'**
  String settingsCoachRosterRenamed(Object player);

  /// No description provided for @settingsCoachRosterLastPlayerRequired.
  ///
  /// In en, this message translates to:
  /// **'Keep at least one player in coach mode.'**
  String get settingsCoachRosterLastPlayerRequired;

  /// No description provided for @settingsCoachRosterDriveAccount.
  ///
  /// In en, this message translates to:
  /// **'Drive: {email}'**
  String settingsCoachRosterDriveAccount(Object email);

  /// No description provided for @settingsCoachRosterNoDriveAccount.
  ///
  /// In en, this message translates to:
  /// **'No Drive account saved for this player yet.'**
  String get settingsCoachRosterNoDriveAccount;

  /// No description provided for @settingsCoachRosterPlayerNameLabel.
  ///
  /// In en, this message translates to:
  /// **'Player name'**
  String get settingsCoachRosterPlayerNameLabel;

  /// No description provided for @settingsCoachRosterPlayerNameHint.
  ///
  /// In en, this message translates to:
  /// **'Example: Minjun'**
  String get settingsCoachRosterPlayerNameHint;

  /// No description provided for @settingsCoachRosterAdded.
  ///
  /// In en, this message translates to:
  /// **'{player} was added.'**
  String settingsCoachRosterAdded(Object player);

  /// No description provided for @settingsCoachRosterActivated.
  ///
  /// In en, this message translates to:
  /// **'{player} is now active.'**
  String settingsCoachRosterActivated(Object player);

  /// No description provided for @settingsSupportRoleTitle.
  ///
  /// In en, this message translates to:
  /// **'Parent mode details'**
  String get settingsSupportRoleTitle;

  /// No description provided for @settingsDriveConnectionTitle.
  ///
  /// In en, this message translates to:
  /// **'Google Drive connection'**
  String get settingsDriveConnectionTitle;

  /// No description provided for @settingsDriveConnectionPlayerSummary.
  ///
  /// In en, this message translates to:
  /// **'Check which Google Drive account stores and imports this device\'s records.'**
  String get settingsDriveConnectionPlayerSummary;

  /// No description provided for @settingsDriveConnectionSupportSummary.
  ///
  /// In en, this message translates to:
  /// **'Check the currently connected Google Drive account.'**
  String get settingsDriveConnectionSupportSummary;

  /// No description provided for @settingsDataSyncTitle.
  ///
  /// In en, this message translates to:
  /// **'Data sync'**
  String get settingsDataSyncTitle;

  /// No description provided for @settingsDataSyncPlayerSummary.
  ///
  /// In en, this message translates to:
  /// **'Check freshness between current data and Drive backup, then run Drive actions.'**
  String get settingsDataSyncPlayerSummary;

  /// No description provided for @settingsDataSyncSupportSummary.
  ///
  /// In en, this message translates to:
  /// **'Import the latest backup and write shared changes back to the parent or active player file.'**
  String get settingsDataSyncSupportSummary;

  /// No description provided for @settingsSyncSourceStatusTitle.
  ///
  /// In en, this message translates to:
  /// **'Backup data'**
  String get settingsSyncSourceStatusTitle;

  /// No description provided for @settingsSyncStatusTitle.
  ///
  /// In en, this message translates to:
  /// **'Data sync status'**
  String get settingsSyncStatusTitle;

  /// No description provided for @settingsSyncShowDetails.
  ///
  /// In en, this message translates to:
  /// **'Show details'**
  String get settingsSyncShowDetails;

  /// No description provided for @settingsSyncHideDetails.
  ///
  /// In en, this message translates to:
  /// **'Hide details'**
  String get settingsSyncHideDetails;

  /// No description provided for @settingsSyncGoogleConnected.
  ///
  /// In en, this message translates to:
  /// **'Google connected'**
  String get settingsSyncGoogleConnected;

  /// No description provided for @settingsSyncGoogleDisconnected.
  ///
  /// In en, this message translates to:
  /// **'Google disconnected'**
  String get settingsSyncGoogleDisconnected;

  /// No description provided for @settingsSyncDailyOn.
  ///
  /// In en, this message translates to:
  /// **'Daily backup on'**
  String get settingsSyncDailyOn;

  /// No description provided for @settingsSyncDailyOff.
  ///
  /// In en, this message translates to:
  /// **'Daily backup off'**
  String get settingsSyncDailyOff;

  /// No description provided for @settingsSyncOnSaveOn.
  ///
  /// In en, this message translates to:
  /// **'Backup on save on'**
  String get settingsSyncOnSaveOn;

  /// No description provided for @settingsSyncOnSaveOff.
  ///
  /// In en, this message translates to:
  /// **'Backup on save off'**
  String get settingsSyncOnSaveOff;

  /// No description provided for @settingsSyncBackedUpDataTime.
  ///
  /// In en, this message translates to:
  /// **'Backed-up data: {time}'**
  String settingsSyncBackedUpDataTime(Object time);

  /// No description provided for @settingsSyncCurrentDataSnapshot.
  ///
  /// In en, this message translates to:
  /// **'Current data snapshot: {time}'**
  String settingsSyncCurrentDataSnapshot(Object time);

  /// No description provided for @settingsSyncStatusChecking.
  ///
  /// In en, this message translates to:
  /// **'Checking'**
  String get settingsSyncStatusChecking;

  /// No description provided for @settingsSyncBackupDataReady.
  ///
  /// In en, this message translates to:
  /// **'Backup source found.'**
  String get settingsSyncBackupDataReady;

  /// No description provided for @settingsSyncStatusSignInNeeded.
  ///
  /// In en, this message translates to:
  /// **'Connect'**
  String get settingsSyncStatusSignInNeeded;

  /// No description provided for @settingsSyncStatusNoBackup.
  ///
  /// In en, this message translates to:
  /// **'No backup'**
  String get settingsSyncStatusNoBackup;

  /// No description provided for @settingsSyncStatusCurrent.
  ///
  /// In en, this message translates to:
  /// **'Recent backup'**
  String get settingsSyncStatusCurrent;

  /// No description provided for @settingsSyncStatusReview.
  ///
  /// In en, this message translates to:
  /// **'Check backup'**
  String get settingsSyncStatusReview;

  /// No description provided for @settingsSyncStatusStale.
  ///
  /// In en, this message translates to:
  /// **'Backup stale'**
  String get settingsSyncStatusStale;

  /// No description provided for @settingsSyncSummaryChecking.
  ///
  /// In en, this message translates to:
  /// **'Checking the Drive backup status.'**
  String get settingsSyncSummaryChecking;

  /// No description provided for @settingsSyncSummarySignInNeeded.
  ///
  /// In en, this message translates to:
  /// **'Connect an account to compare this device with Drive backup and run import or backup actions.'**
  String get settingsSyncSummarySignInNeeded;

  /// No description provided for @settingsSyncSummaryNoBackup.
  ///
  /// In en, this message translates to:
  /// **'No Drive backup file exists yet. Use Back up data to store the current data first.'**
  String get settingsSyncSummaryNoBackup;

  /// No description provided for @settingsSyncSummaryCurrent.
  ///
  /// In en, this message translates to:
  /// **'The Drive backup was created around {time}. Check this time before replacing or overwriting data.'**
  String settingsSyncSummaryCurrent(Object time);

  /// No description provided for @settingsSyncSummaryStale.
  ///
  /// In en, this message translates to:
  /// **'The Drive backup is from {time}. Changes made after that may not be backed up yet.'**
  String settingsSyncSummaryStale(Object time);

  /// No description provided for @settingsDriveActionFilePath.
  ///
  /// In en, this message translates to:
  /// **'File path: {path}'**
  String settingsDriveActionFilePath(Object path);

  /// No description provided for @settingsDriveActionBackupTime.
  ///
  /// In en, this message translates to:
  /// **'Backup saved at: {time}'**
  String settingsDriveActionBackupTime(Object time);

  /// No description provided for @settingsDriveActionBackupTimeUnknown.
  ///
  /// In en, this message translates to:
  /// **'Backup saved time: not available on this device yet.'**
  String get settingsDriveActionBackupTimeUnknown;

  /// No description provided for @settingsDriveConnectAction.
  ///
  /// In en, this message translates to:
  /// **'Connect Google Drive'**
  String get settingsDriveConnectAction;

  /// No description provided for @settingsDriveDisconnectAction.
  ///
  /// In en, this message translates to:
  /// **'Disconnect Google Drive'**
  String get settingsDriveDisconnectAction;

  /// No description provided for @settingsRestoreLatestActionTitle.
  ///
  /// In en, this message translates to:
  /// **'Import latest data'**
  String get settingsRestoreLatestActionTitle;

  /// No description provided for @settingsBackupDataActionTitle.
  ///
  /// In en, this message translates to:
  /// **'Back up data'**
  String get settingsBackupDataActionTitle;

  /// No description provided for @settingsRoleAccountSummary.
  ///
  /// In en, this message translates to:
  /// **'Choose this device usage mode first.'**
  String get settingsRoleAccountSummary;

  /// No description provided for @settingsRoleAccountTitle.
  ///
  /// In en, this message translates to:
  /// **'Usage mode and account'**
  String get settingsRoleAccountTitle;

  /// No description provided for @settingsRoleAccountDescription.
  ///
  /// In en, this message translates to:
  /// **'Choose how this device will be used first. The account connection below changes to match that mode.'**
  String get settingsRoleAccountDescription;

  /// No description provided for @settingsRoleAccountUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Google Drive account connection is unavailable in this build.'**
  String get settingsRoleAccountUnavailable;

  /// No description provided for @settingsRolePlayerDescription.
  ///
  /// In en, this message translates to:
  /// **'Record training, meals, sketches, XP, and backups in player mode.'**
  String get settingsRolePlayerDescription;

  /// No description provided for @settingsRoleParentDescription.
  ///
  /// In en, this message translates to:
  /// **'Read player records and manage feedback or reward names without editing core records.'**
  String get settingsRoleParentDescription;

  /// No description provided for @settingsRoleCoachDescription.
  ///
  /// In en, this message translates to:
  /// **'Review player records and sketches in parent mode, with shared feedback focused on training.'**
  String get settingsRoleCoachDescription;

  /// No description provided for @settingsRoleActionTitle.
  ///
  /// In en, this message translates to:
  /// **'Mode-based actions'**
  String get settingsRoleActionTitle;

  /// No description provided for @settingsPlayerActionSummary.
  ///
  /// In en, this message translates to:
  /// **'In player mode, use backup first to protect new records, and use the import actions below only when you need to restore older data.'**
  String get settingsPlayerActionSummary;

  /// No description provided for @settingsSupportActionSummary.
  ///
  /// In en, this message translates to:
  /// **'Parent mode does not create new source backups here. Instead, it imports player data or rolls back to the state saved before the last import.'**
  String get settingsSupportActionSummary;

  /// No description provided for @settingsPlayerAccountTitle.
  ///
  /// In en, this message translates to:
  /// **'Record backup Drive account'**
  String get settingsPlayerAccountTitle;

  /// No description provided for @settingsPlayerAccountDescription.
  ///
  /// In en, this message translates to:
  /// **'Connect the Google Drive account used to back up and import this device\'s training records.'**
  String get settingsPlayerAccountDescription;

  /// No description provided for @settingsPlayerBackupActionBody.
  ///
  /// In en, this message translates to:
  /// **'Save the current device records as the latest Google Drive backup. Use this first when protecting new entries.'**
  String get settingsPlayerBackupActionBody;

  /// No description provided for @settingsPlayerRestoreDriveActionTitle.
  ///
  /// In en, this message translates to:
  /// **'Import latest data'**
  String get settingsPlayerRestoreDriveActionTitle;

  /// No description provided for @settingsPlayerRestoreDriveActionBody.
  ///
  /// In en, this message translates to:
  /// **'Replace the current device data with the latest backup stored on Google Drive.'**
  String get settingsPlayerRestoreDriveActionBody;

  /// No description provided for @settingsPlayerRestoreLocalActionTitle.
  ///
  /// In en, this message translates to:
  /// **'Undo latest import'**
  String get settingsPlayerRestoreLocalActionTitle;

  /// No description provided for @settingsPlayerRestoreLocalActionBody.
  ///
  /// In en, this message translates to:
  /// **'Revert this device to the state it had before the latest import changed it.'**
  String get settingsPlayerRestoreLocalActionBody;

  /// No description provided for @settingsSupportRestoreDriveActionTitle.
  ///
  /// In en, this message translates to:
  /// **'Import latest player data'**
  String get settingsSupportRestoreDriveActionTitle;

  /// No description provided for @settingsSupportRestoreDriveActionBody.
  ///
  /// In en, this message translates to:
  /// **'Pull the latest Google Drive backup that was saved in player mode onto this device.'**
  String get settingsSupportRestoreDriveActionBody;

  /// No description provided for @settingsSupportRestoreLocalActionTitle.
  ///
  /// In en, this message translates to:
  /// **'Undo latest import'**
  String get settingsSupportRestoreLocalActionTitle;

  /// No description provided for @settingsSupportRestoreLocalActionBody.
  ///
  /// In en, this message translates to:
  /// **'Revert the latest imported player-data changes on this device to the previous state.'**
  String get settingsSupportRestoreLocalActionBody;

  /// No description provided for @settingsSupportBackupConfirm.
  ///
  /// In en, this message translates to:
  /// **'Back up parent-mode feedback and level reward names into the player\'s source Drive backup?'**
  String get settingsSupportBackupConfirm;

  /// No description provided for @settingsSupportBackupSuccess.
  ///
  /// In en, this message translates to:
  /// **'Shared changes were backed up to the player\'s source Drive.'**
  String get settingsSupportBackupSuccess;

  /// No description provided for @settingsSupportBackupFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not back up shared changes. Check that this Drive account already has a player-mode backup.'**
  String get settingsSupportBackupFailed;

  /// No description provided for @settingsRestoreRollbackTitle.
  ///
  /// In en, this message translates to:
  /// **'Import rollback'**
  String get settingsRestoreRollbackTitle;

  /// No description provided for @settingsRestoreRollbackBody.
  ///
  /// In en, this message translates to:
  /// **'This is advanced recovery for undoing the last import on this device, not a regular backup action.'**
  String get settingsRestoreRollbackBody;

  /// No description provided for @familyRoleActivated.
  ///
  /// In en, this message translates to:
  /// **'{role} mode activated.'**
  String familyRoleActivated(Object role);

  /// No description provided for @familyParentModeEnabled.
  ///
  /// In en, this message translates to:
  /// **'Enable parent mode'**
  String get familyParentModeEnabled;

  /// No description provided for @familyParentModeDescription.
  ///
  /// In en, this message translates to:
  /// **'Turn this on for parent mode. Turn it off to return to player mode.'**
  String get familyParentModeDescription;

  /// No description provided for @familyChildName.
  ///
  /// In en, this message translates to:
  /// **'Player name'**
  String get familyChildName;

  /// No description provided for @familyParentName.
  ///
  /// In en, this message translates to:
  /// **'Parent name'**
  String get familyParentName;

  /// No description provided for @familyChildNameEmpty.
  ///
  /// In en, this message translates to:
  /// **'Set the player name'**
  String get familyChildNameEmpty;

  /// No description provided for @familyParentNameEmpty.
  ///
  /// In en, this message translates to:
  /// **'Set the parent name'**
  String get familyParentNameEmpty;

  /// No description provided for @familyEditNames.
  ///
  /// In en, this message translates to:
  /// **'Edit family names'**
  String get familyEditNames;

  /// No description provided for @familyPolicyTitle.
  ///
  /// In en, this message translates to:
  /// **'Parent mode/player sharing policy'**
  String get familyPolicyTitle;

  /// No description provided for @familyPolicyChildOwnsData.
  ///
  /// In en, this message translates to:
  /// **'Player mode backs up training, profile, diary, meals, and plans as the source of truth.'**
  String get familyPolicyChildOwnsData;

  /// No description provided for @familyPolicyParentWritesOnly.
  ///
  /// In en, this message translates to:
  /// **'Parent mode can save training feedback and level reward names only.'**
  String get familyPolicyParentWritesOnly;

  /// No description provided for @familyPolicyParentSeedRequired.
  ///
  /// In en, this message translates to:
  /// **'Connect the parent device after at least one player backup already exists.'**
  String get familyPolicyParentSeedRequired;

  /// No description provided for @familyRoleChildActivated.
  ///
  /// In en, this message translates to:
  /// **'Player mode activated.'**
  String get familyRoleChildActivated;

  /// No description provided for @familyRoleParentActivated.
  ///
  /// In en, this message translates to:
  /// **'Parent mode activated.'**
  String get familyRoleParentActivated;

  /// No description provided for @familyNamesSaved.
  ///
  /// In en, this message translates to:
  /// **'Family names saved.'**
  String get familyNamesSaved;

  /// No description provided for @driveConnectedAccount.
  ///
  /// In en, this message translates to:
  /// **'Connected Drive account'**
  String get driveConnectedAccount;

  /// No description provided for @driveConnectedAccountEmpty.
  ///
  /// In en, this message translates to:
  /// **'No Google Drive account is connected yet.'**
  String get driveConnectedAccountEmpty;

  /// No description provided for @driveSavedPlayerAccount.
  ///
  /// In en, this message translates to:
  /// **'Player-mode backup Drive'**
  String get driveSavedPlayerAccount;

  /// No description provided for @driveReconnectSavedPlayer.
  ///
  /// In en, this message translates to:
  /// **'Reconnect player-mode Drive'**
  String get driveReconnectSavedPlayer;

  /// No description provided for @driveReconnectSavedPlayerHint.
  ///
  /// In en, this message translates to:
  /// **'After leaving parent mode, reconnect the saved player-mode Drive account here.'**
  String get driveReconnectSavedPlayerHint;

  /// No description provided for @driveReconnectSavedPlayerMismatch.
  ///
  /// In en, this message translates to:
  /// **'Please reconnect with the saved player-mode Drive account.'**
  String get driveReconnectSavedPlayerMismatch;

  /// No description provided for @driveSavedParentAccount.
  ///
  /// In en, this message translates to:
  /// **'Saved parent-mode Drive'**
  String get driveSavedParentAccount;

  /// No description provided for @driveReconnectSavedParent.
  ///
  /// In en, this message translates to:
  /// **'Reconnect saved parent-mode Drive'**
  String get driveReconnectSavedParent;

  /// No description provided for @driveReconnectSavedParentHint.
  ///
  /// In en, this message translates to:
  /// **'Reconnect the Drive account that was used most recently in parent mode.'**
  String get driveReconnectSavedParentHint;

  /// No description provided for @driveReconnectSavedParentMismatch.
  ///
  /// In en, this message translates to:
  /// **'Please reconnect with the saved parent-mode Drive account.'**
  String get driveReconnectSavedParentMismatch;

  /// No description provided for @driveSharedChildAccount.
  ///
  /// In en, this message translates to:
  /// **'Source backup Drive'**
  String get driveSharedChildAccount;

  /// No description provided for @driveSharedChildAccountEmpty.
  ///
  /// In en, this message translates to:
  /// **'No source backup is known yet. Create at least one backup first.'**
  String get driveSharedChildAccountEmpty;

  /// No description provided for @driveSharedChildAccountRemoteBackup.
  ///
  /// In en, this message translates to:
  /// **'A remote backup was found. Connect the same Google Drive account.'**
  String get driveSharedChildAccountRemoteBackup;

  /// No description provided for @familyChildDriveConnectionSummary.
  ///
  /// In en, this message translates to:
  /// **'Use the Google Drive account that holds the source backup.'**
  String get familyChildDriveConnectionSummary;

  /// No description provided for @familyParentUsesChildDriveSummary.
  ///
  /// In en, this message translates to:
  /// **'Use the source backup Drive account here.'**
  String get familyParentUsesChildDriveSummary;

  /// No description provided for @familyParentUsesChildDriveHint.
  ///
  /// In en, this message translates to:
  /// **'In parent mode, sign in with the Google Drive account that holds the player\'s source data to sync training feedback and reward names into the same backup file.'**
  String get familyParentUsesChildDriveHint;

  /// No description provided for @familyParentUsesChildDriveWarning.
  ///
  /// In en, this message translates to:
  /// **'Parent mode should connect to the Google Drive account that holds the player\'s source data so training feedback and reward names sync safely into the same backup file.'**
  String get familyParentUsesChildDriveWarning;

  /// No description provided for @familySharedSyncTitle.
  ///
  /// In en, this message translates to:
  /// **'Data sync status'**
  String get familySharedSyncTitle;

  /// No description provided for @familySharedSyncDescription.
  ///
  /// In en, this message translates to:
  /// **'Parent feedback and level reward names are written automatically into the same player backup file.'**
  String get familySharedSyncDescription;

  /// No description provided for @familySyncAlertTitle.
  ///
  /// In en, this message translates to:
  /// **'Parent sync'**
  String get familySyncAlertTitle;

  /// No description provided for @familySyncParentTrainingAdded.
  ///
  /// In en, this message translates to:
  /// **'{count} new player training log(s) synced.'**
  String familySyncParentTrainingAdded(int count);

  /// No description provided for @familySyncParentRewardClaimed.
  ///
  /// In en, this message translates to:
  /// **'{count} player reward claim(s) synced.'**
  String familySyncParentRewardClaimed(int count);

  /// No description provided for @familySyncParentTrainingAndRewardClaimed.
  ///
  /// In en, this message translates to:
  /// **'{trainingCount} new player training log(s) and {rewardCount} reward claim(s) synced.'**
  String familySyncParentTrainingAndRewardClaimed(
      int trainingCount, int rewardCount);

  /// No description provided for @familySyncChildFeedbackAdded.
  ///
  /// In en, this message translates to:
  /// **'{count} parent feedback update(s) synced.'**
  String familySyncChildFeedbackAdded(int count);

  /// No description provided for @familySyncChildRewardUpdated.
  ///
  /// In en, this message translates to:
  /// **'Level reward names synced.'**
  String get familySyncChildRewardUpdated;

  /// No description provided for @familySyncChildFeedbackAndReward.
  ///
  /// In en, this message translates to:
  /// **'{count} parent feedback update(s) and reward names synced.'**
  String familySyncChildFeedbackAndReward(int count);

  /// No description provided for @familySharedLastSync.
  ///
  /// In en, this message translates to:
  /// **'Last parent/player sync'**
  String get familySharedLastSync;

  /// No description provided for @familySharedLastPush.
  ///
  /// In en, this message translates to:
  /// **'Last push'**
  String get familySharedLastPush;

  /// No description provided for @familySharedLastRefresh.
  ///
  /// In en, this message translates to:
  /// **'Last import check'**
  String get familySharedLastRefresh;

  /// No description provided for @familySharedAutoRefreshDescription.
  ///
  /// In en, this message translates to:
  /// **'When parent mode opens or the app resumes, the latest state is checked automatically. Auto checks pause when local changes are still waiting to be pushed to Drive.'**
  String get familySharedAutoRefreshDescription;

  /// No description provided for @familySharedPendingLocalChanges.
  ///
  /// In en, this message translates to:
  /// **'Automatic import is paused because local changes still need to be pushed to Drive.'**
  String get familySharedPendingLocalChanges;

  /// No description provided for @familySharedRestore.
  ///
  /// In en, this message translates to:
  /// **'Import player data'**
  String get familySharedRestore;

  /// No description provided for @familySharedRestoreConfirm.
  ///
  /// In en, this message translates to:
  /// **'Import the latest player data from Google Drive? This replaces the player records and shared data shown on this device.'**
  String get familySharedRestoreConfirm;

  /// No description provided for @familySharedRestoreSuccess.
  ///
  /// In en, this message translates to:
  /// **'Player data imported.'**
  String get familySharedRestoreSuccess;

  /// No description provided for @familySharedRestoreFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to import player data. Please try again.'**
  String get familySharedRestoreFailed;

  /// No description provided for @familySharedRestoreLocal.
  ///
  /// In en, this message translates to:
  /// **'Import previous player data'**
  String get familySharedRestoreLocal;

  /// No description provided for @familySharedRestoreLocalConfirm.
  ///
  /// In en, this message translates to:
  /// **'Undo the latest imported player-data changes on this device? This replaces the player records and shared data shown on this device.'**
  String get familySharedRestoreLocalConfirm;

  /// No description provided for @familySharedRestoreLocalSuccess.
  ///
  /// In en, this message translates to:
  /// **'The latest import was undone.'**
  String get familySharedRestoreLocalSuccess;

  /// No description provided for @familySharedRestoreLocalFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to undo the latest import. Please try again.'**
  String get familySharedRestoreLocalFailed;

  /// No description provided for @restoreReconfirmTitle.
  ///
  /// In en, this message translates to:
  /// **'Restore confirmation'**
  String get restoreReconfirmTitle;

  /// No description provided for @restoreReconfirmBody.
  ///
  /// In en, this message translates to:
  /// **'Do you really want to restore? Current data will be replaced.'**
  String get restoreReconfirmBody;

  /// No description provided for @familyParentFamilyMismatch.
  ///
  /// In en, this message translates to:
  /// **'The connected Drive backup does not match this parent/player sharing data.'**
  String get familyParentFamilyMismatch;

  /// No description provided for @moreInfoAction.
  ///
  /// In en, this message translates to:
  /// **'More info'**
  String get moreInfoAction;

  /// No description provided for @parentReadOnlyProfileSummary.
  ///
  /// In en, this message translates to:
  /// **'Profile is view only here.'**
  String get parentReadOnlyProfileSummary;

  /// No description provided for @parentReadOnlyProfileDescription.
  ///
  /// In en, this message translates to:
  /// **'Parent mode keeps the profile read-only. Leave training feedback from the training log and set reward names from the level guide.'**
  String get parentReadOnlyProfileDescription;

  /// No description provided for @parentReadOnlySettingsOptions.
  ///
  /// In en, this message translates to:
  /// **'Parent mode cannot edit the sport, default values, or news filters. Change them in player mode.'**
  String get parentReadOnlySettingsOptions;

  /// No description provided for @benchmarkReferencesTitle.
  ///
  /// In en, this message translates to:
  /// **'Average benchmarks'**
  String get benchmarkReferencesTitle;

  /// No description provided for @benchmarkRefreshAction.
  ///
  /// In en, this message translates to:
  /// **'Refresh average'**
  String get benchmarkRefreshAction;

  /// No description provided for @benchmarkRefreshInProgress.
  ///
  /// In en, this message translates to:
  /// **'Refreshing'**
  String get benchmarkRefreshInProgress;

  /// No description provided for @benchmarkLastSynced.
  ///
  /// In en, this message translates to:
  /// **'Last sync: {date}'**
  String benchmarkLastSynced(Object date);

  /// No description provided for @benchmarkRefreshSuccess.
  ///
  /// In en, this message translates to:
  /// **'Average benchmark data updated.'**
  String get benchmarkRefreshSuccess;

  /// No description provided for @benchmarkRefreshFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to update average benchmark data. Check network.'**
  String get benchmarkRefreshFailed;

  /// No description provided for @benchmarkReferenceNote.
  ///
  /// In en, this message translates to:
  /// **'Height and weight use CDC growth-chart medians. Activity time uses WHO youth guidance. Sport-specific conditioning ranges are app training references, not medical standards.'**
  String get benchmarkReferenceNote;

  /// No description provided for @benchmarkAgeTableTitle.
  ///
  /// In en, this message translates to:
  /// **'Averages by age'**
  String get benchmarkAgeTableTitle;

  /// No description provided for @benchmarkAgeTableNote.
  ///
  /// In en, this message translates to:
  /// **'If the player\'s age is set, that row is highlighted. Weekly targets are adjusted by the entered sport experience.'**
  String get benchmarkAgeTableNote;

  /// No description provided for @benchmarkAgeColumnAge.
  ///
  /// In en, this message translates to:
  /// **'Age'**
  String get benchmarkAgeColumnAge;

  /// No description provided for @benchmarkAgeColumnHeight.
  ///
  /// In en, this message translates to:
  /// **'Avg height'**
  String get benchmarkAgeColumnHeight;

  /// No description provided for @benchmarkAgeColumnWeight.
  ///
  /// In en, this message translates to:
  /// **'Avg weight'**
  String get benchmarkAgeColumnWeight;

  /// No description provided for @benchmarkAgeColumnLifting.
  ///
  /// In en, this message translates to:
  /// **'Lifting/session'**
  String get benchmarkAgeColumnLifting;

  /// No description provided for @benchmarkAgeColumnConditioning.
  ///
  /// In en, this message translates to:
  /// **'{metric}/session'**
  String benchmarkAgeColumnConditioning(Object metric);

  /// No description provided for @benchmarkAgeColumnWeeklyTarget.
  ///
  /// In en, this message translates to:
  /// **'Weekly target'**
  String get benchmarkAgeColumnWeeklyTarget;

  /// No description provided for @benchmarkAgeValue.
  ///
  /// In en, this message translates to:
  /// **'Age {age}'**
  String benchmarkAgeValue(int age);

  /// No description provided for @benchmarkAgeCurrentBadge.
  ///
  /// In en, this message translates to:
  /// **'Current'**
  String get benchmarkAgeCurrentBadge;

  /// No description provided for @benchmarkAgeLiftingValue.
  ///
  /// In en, this message translates to:
  /// **'{count} reps'**
  String benchmarkAgeLiftingValue(int count);

  /// No description provided for @benchmarkAgeWeeklyTargetValue.
  ///
  /// In en, this message translates to:
  /// **'{minutes} min · {sessions} sessions'**
  String benchmarkAgeWeeklyTargetValue(int minutes, int sessions);

  /// No description provided for @parentReadOnlyEntryTitle.
  ///
  /// In en, this message translates to:
  /// **'Parent mode cannot edit training notes.'**
  String get parentReadOnlyEntryTitle;

  /// No description provided for @parentReadOnlyEntryBody.
  ///
  /// In en, this message translates to:
  /// **'Core records like training, meals, and diary stay in player mode. Parent mode leaves the original record untouched and stores only feedback and reward naming separately.'**
  String get parentReadOnlyEntryBody;

  /// No description provided for @parentReadOnlyLogsSummary.
  ///
  /// In en, this message translates to:
  /// **'View training logs and leave feedback only.'**
  String get parentReadOnlyLogsSummary;

  /// No description provided for @parentReadOnlyLogsBanner.
  ///
  /// In en, this message translates to:
  /// **'Parent mode does not delete training logs. Open a record to leave feedback instead.'**
  String get parentReadOnlyLogsBanner;

  /// No description provided for @parentReadOnlyLogsMessage.
  ///
  /// In en, this message translates to:
  /// **'Parent mode cannot delete training logs.'**
  String get parentReadOnlyLogsMessage;

  /// No description provided for @parentReadOnlyMealLogSummary.
  ///
  /// In en, this message translates to:
  /// **'Meal log is view only here.'**
  String get parentReadOnlyMealLogSummary;

  /// No description provided for @parentReadOnlyMealLog.
  ///
  /// In en, this message translates to:
  /// **'Parent mode cannot edit meal logs. Update meals in player mode.'**
  String get parentReadOnlyMealLog;

  /// No description provided for @parentReadOnlyQuiz.
  ///
  /// In en, this message translates to:
  /// **'Parent mode does not run the quiz. Quiz history and XP stay in player mode.'**
  String get parentReadOnlyQuiz;

  /// No description provided for @parentReadOnlyDrawerMessage.
  ///
  /// In en, this message translates to:
  /// **'Parent mode keeps core records read-only. Use shared data and reward naming instead.'**
  String get parentReadOnlyDrawerMessage;

  /// No description provided for @parentReadOnlyCoreDataMessage.
  ///
  /// In en, this message translates to:
  /// **'Parent mode cannot edit player core data. Switch to player mode to change it.'**
  String get parentReadOnlyCoreDataMessage;

  /// No description provided for @parentReadOnlyCalendarSummary.
  ///
  /// In en, this message translates to:
  /// **'Calendar is view only here.'**
  String get parentReadOnlyCalendarSummary;

  /// No description provided for @parentReadOnlyCalendarBanner.
  ///
  /// In en, this message translates to:
  /// **'Parent mode keeps the calendar read-only. Update plans, matches, and meals in player mode.'**
  String get parentReadOnlyCalendarBanner;

  /// No description provided for @parentReadOnlyCalendarMessage.
  ///
  /// In en, this message translates to:
  /// **'Parent mode cannot edit the calendar.'**
  String get parentReadOnlyCalendarMessage;

  /// No description provided for @parentReadOnlyChallengeSummary.
  ///
  /// In en, this message translates to:
  /// **'Parent mode can create challenges.'**
  String get parentReadOnlyChallengeSummary;

  /// No description provided for @parentReadOnlyChallengeMessage.
  ///
  /// In en, this message translates to:
  /// **'In Parent mode, you can create challenges and set finish gifts. Mission records are still entered in player mode.'**
  String get parentReadOnlyChallengeMessage;

  /// No description provided for @parentReadOnlyDiaryMessage.
  ///
  /// In en, this message translates to:
  /// **'Parent mode cannot edit the diary.'**
  String get parentReadOnlyDiaryMessage;

  /// No description provided for @parentReadOnlyDiaryBadge.
  ///
  /// In en, this message translates to:
  /// **'Parent mode read-only'**
  String get parentReadOnlyDiaryBadge;

  /// No description provided for @parentReadOnlySketchMessage.
  ///
  /// In en, this message translates to:
  /// **'Parent mode cannot edit training sketches.'**
  String get parentReadOnlySketchMessage;

  /// No description provided for @parentReadOnlyFortuneEmpty.
  ///
  /// In en, this message translates to:
  /// **'No saved mood card is available yet.'**
  String get parentReadOnlyFortuneEmpty;

  /// No description provided for @parentFeedbackSectionTitle.
  ///
  /// In en, this message translates to:
  /// **'Parent feedback'**
  String get parentFeedbackSectionTitle;

  /// No description provided for @parentFeedbackHelper.
  ///
  /// In en, this message translates to:
  /// **'Keep the original training record untouched and store only the parent feedback for this session separately.'**
  String get parentFeedbackHelper;

  /// No description provided for @parentFeedbackReadOnlyHint.
  ///
  /// In en, this message translates to:
  /// **'Feedback left on this training log by a parent.'**
  String get parentFeedbackReadOnlyHint;

  /// No description provided for @parentFeedbackInputLabel.
  ///
  /// In en, this message translates to:
  /// **'Parent feedback'**
  String get parentFeedbackInputLabel;

  /// No description provided for @parentFeedbackInputHint.
  ///
  /// In en, this message translates to:
  /// **'Write what a parent wants to praise or what to watch next time.'**
  String get parentFeedbackInputHint;

  /// No description provided for @parentFeedbackSave.
  ///
  /// In en, this message translates to:
  /// **'Save feedback'**
  String get parentFeedbackSave;

  /// No description provided for @parentFeedbackClear.
  ///
  /// In en, this message translates to:
  /// **'Clear'**
  String get parentFeedbackClear;

  /// No description provided for @parentFeedbackWriteAction.
  ///
  /// In en, this message translates to:
  /// **'Write feedback'**
  String get parentFeedbackWriteAction;

  /// No description provided for @parentFeedbackEditAction.
  ///
  /// In en, this message translates to:
  /// **'Edit feedback'**
  String get parentFeedbackEditAction;

  /// No description provided for @parentFeedbackViewAction.
  ///
  /// In en, this message translates to:
  /// **'View feedback'**
  String get parentFeedbackViewAction;

  /// No description provided for @parentFeedbackDiscardTitle.
  ///
  /// In en, this message translates to:
  /// **'Unsaved feedback'**
  String get parentFeedbackDiscardTitle;

  /// No description provided for @parentFeedbackDiscardBody.
  ///
  /// In en, this message translates to:
  /// **'You have unsaved feedback. Leave without saving?'**
  String get parentFeedbackDiscardBody;

  /// No description provided for @parentFeedbackDiscardAction.
  ///
  /// In en, this message translates to:
  /// **'Leave'**
  String get parentFeedbackDiscardAction;

  /// No description provided for @parentFeedbackSaved.
  ///
  /// In en, this message translates to:
  /// **'Feedback saved.'**
  String get parentFeedbackSaved;

  /// No description provided for @parentFeedbackSaveFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not save feedback. Try again.'**
  String get parentFeedbackSaveFailed;

  /// No description provided for @parentFeedbackCleared.
  ///
  /// In en, this message translates to:
  /// **'Feedback cleared.'**
  String get parentFeedbackCleared;

  /// No description provided for @parentFeedbackEmpty.
  ///
  /// In en, this message translates to:
  /// **'There is no feedback yet.'**
  String get parentFeedbackEmpty;

  /// No description provided for @parentFeedbackReactionOnly.
  ///
  /// In en, this message translates to:
  /// **'The player left a reaction.'**
  String get parentFeedbackReactionOnly;

  /// No description provided for @parentFeedbackReactionLabel.
  ///
  /// In en, this message translates to:
  /// **'Reaction'**
  String get parentFeedbackReactionLabel;

  /// No description provided for @parentFeedbackReactionNone.
  ///
  /// In en, this message translates to:
  /// **'None'**
  String get parentFeedbackReactionNone;

  /// No description provided for @parentFeedbackReactionThanks.
  ///
  /// In en, this message translates to:
  /// **'Thanks'**
  String get parentFeedbackReactionThanks;

  /// No description provided for @parentFeedbackReactionProud.
  ///
  /// In en, this message translates to:
  /// **'Proud'**
  String get parentFeedbackReactionProud;

  /// No description provided for @parentFeedbackReactionReview.
  ///
  /// In en, this message translates to:
  /// **'Review'**
  String get parentFeedbackReactionReview;

  /// No description provided for @parentFeedbackReactionTry.
  ///
  /// In en, this message translates to:
  /// **'Try next'**
  String get parentFeedbackReactionTry;

  /// No description provided for @parentFeedbackOpenExistingEntryTitle.
  ///
  /// In en, this message translates to:
  /// **'Open an existing training log to leave feedback.'**
  String get parentFeedbackOpenExistingEntryTitle;

  /// No description provided for @parentFeedbackOpenExistingEntryBody.
  ///
  /// In en, this message translates to:
  /// **'Parent mode does not create new training logs. Parent feedback can only be saved on an existing training log after the player records it first.'**
  String get parentFeedbackOpenExistingEntryBody;

  /// No description provided for @parentSharedSyncInProgress.
  ///
  /// In en, this message translates to:
  /// **'Syncing to the player\'s Drive...'**
  String get parentSharedSyncInProgress;

  /// No description provided for @parentSharedSyncDone.
  ///
  /// In en, this message translates to:
  /// **'Synced to the player\'s Drive too.'**
  String get parentSharedSyncDone;

  /// No description provided for @parentSharedSyncPending.
  ///
  /// In en, this message translates to:
  /// **'It will sync into the same player backup file after Drive is connected.'**
  String get parentSharedSyncPending;

  /// No description provided for @levelGuideParentModeLabel.
  ///
  /// In en, this message translates to:
  /// **'Parent mode'**
  String get levelGuideParentModeLabel;

  /// No description provided for @levelGuideChildModeLabel.
  ///
  /// In en, this message translates to:
  /// **'Player mode'**
  String get levelGuideChildModeLabel;

  /// No description provided for @levelGuideParentModeDescription.
  ///
  /// In en, this message translates to:
  /// **'Parent mode can save reward names only, and saved reward names also sync into the shared player Drive backup. Reward received marks stay in player mode.'**
  String get levelGuideParentModeDescription;

  /// No description provided for @levelGuideChildModeDescription.
  ///
  /// In en, this message translates to:
  /// **'Player mode can mark received level rewards. Reward naming stays in parent mode.'**
  String get levelGuideChildModeDescription;

  /// No description provided for @levelGuideModeInfoTooltip.
  ///
  /// In en, this message translates to:
  /// **'Show mode description'**
  String get levelGuideModeInfoTooltip;

  /// No description provided for @levelGuideClaimChildOnly.
  ///
  /// In en, this message translates to:
  /// **'Claim in player mode'**
  String get levelGuideClaimChildOnly;

  /// No description provided for @levelGuideRewardFallbackName.
  ///
  /// In en, this message translates to:
  /// **'Reward'**
  String get levelGuideRewardFallbackName;

  /// No description provided for @levelGuideRewardClaimed.
  ///
  /// In en, this message translates to:
  /// **'Claimed {rewardName}.'**
  String levelGuideRewardClaimed(Object rewardName);

  /// No description provided for @levelGuideRewardSaved.
  ///
  /// In en, this message translates to:
  /// **'Reward saved.'**
  String get levelGuideRewardSaved;

  /// No description provided for @levelGuideRewardCleared.
  ///
  /// In en, this message translates to:
  /// **'Reward cleared.'**
  String get levelGuideRewardCleared;

  /// No description provided for @levelGuideMaxLevelRangeLabel.
  ///
  /// In en, this message translates to:
  /// **'{minXp} XP+ · max level'**
  String levelGuideMaxLevelRangeLabel(Object minXp);

  /// No description provided for @levelGuideMaxLevelMasteryHint.
  ///
  /// In en, this message translates to:
  /// **'There is no next level. Keep earning a mastery star every {masterySpan} XP.'**
  String levelGuideMaxLevelMasteryHint(Object masterySpan);

  /// No description provided for @trainingPlanAddTitle.
  ///
  /// In en, this message translates to:
  /// **'Add Training Plan'**
  String get trainingPlanAddTitle;

  /// No description provided for @trainingPlanEditTitle.
  ///
  /// In en, this message translates to:
  /// **'Edit Training Plan'**
  String get trainingPlanEditTitle;

  /// No description provided for @trainingPlanViewTitle.
  ///
  /// In en, this message translates to:
  /// **'View Training Plan'**
  String get trainingPlanViewTitle;

  /// No description provided for @matchAddTitle.
  ///
  /// In en, this message translates to:
  /// **'Add Match'**
  String get matchAddTitle;

  /// No description provided for @matchEditTitle.
  ///
  /// In en, this message translates to:
  /// **'Edit Match'**
  String get matchEditTitle;

  /// No description provided for @matchViewTitle.
  ///
  /// In en, this message translates to:
  /// **'View Match'**
  String get matchViewTitle;

  /// No description provided for @matchKindFriendly.
  ///
  /// In en, this message translates to:
  /// **'Friendly'**
  String get matchKindFriendly;

  /// No description provided for @matchKindLeague.
  ///
  /// In en, this message translates to:
  /// **'League'**
  String get matchKindLeague;

  /// No description provided for @matchKindTournament.
  ///
  /// In en, this message translates to:
  /// **'Tournament'**
  String get matchKindTournament;

  /// No description provided for @matchFriendlyResultLabel.
  ///
  /// In en, this message translates to:
  /// **'Friendly result'**
  String get matchFriendlyResultLabel;

  /// No description provided for @matchResultLabel.
  ///
  /// In en, this message translates to:
  /// **'Match result'**
  String get matchResultLabel;

  /// No description provided for @matchResultUnset.
  ///
  /// In en, this message translates to:
  /// **'Unset'**
  String get matchResultUnset;

  /// No description provided for @matchResultWin.
  ///
  /// In en, this message translates to:
  /// **'Win'**
  String get matchResultWin;

  /// No description provided for @matchResultDraw.
  ///
  /// In en, this message translates to:
  /// **'Draw'**
  String get matchResultDraw;

  /// No description provided for @matchResultLoss.
  ///
  /// In en, this message translates to:
  /// **'Loss'**
  String get matchResultLoss;

  /// No description provided for @matchLeagueSectionTitle.
  ///
  /// In en, this message translates to:
  /// **'League details'**
  String get matchLeagueSectionTitle;

  /// No description provided for @matchTournamentSectionTitle.
  ///
  /// In en, this message translates to:
  /// **'Tournament details'**
  String get matchTournamentSectionTitle;

  /// No description provided for @matchCompetitionNameLabel.
  ///
  /// In en, this message translates to:
  /// **'Competition name'**
  String get matchCompetitionNameLabel;

  /// No description provided for @matchLeagueNameHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. Weekend League'**
  String get matchLeagueNameHint;

  /// No description provided for @matchTournamentNameHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. Cup tournament'**
  String get matchTournamentNameHint;

  /// No description provided for @matchCompetitionSelectLabel.
  ///
  /// In en, this message translates to:
  /// **'Saved competitions'**
  String get matchCompetitionSelectLabel;

  /// No description provided for @matchCompetitionStatusLabel.
  ///
  /// In en, this message translates to:
  /// **'Competition status'**
  String get matchCompetitionStatusLabel;

  /// No description provided for @matchCompetitionStatusActive.
  ///
  /// In en, this message translates to:
  /// **'Active'**
  String get matchCompetitionStatusActive;

  /// No description provided for @matchCompetitionStatusFinished.
  ///
  /// In en, this message translates to:
  /// **'Finished'**
  String get matchCompetitionStatusFinished;

  /// No description provided for @matchCompetitionOptionActive.
  ///
  /// In en, this message translates to:
  /// **'{name} · active'**
  String matchCompetitionOptionActive(Object name);

  /// No description provided for @matchCompetitionOptionFinished.
  ///
  /// In en, this message translates to:
  /// **'{name} · finished'**
  String matchCompetitionOptionFinished(Object name);

  /// No description provided for @matchCompetitionFinishedNotice.
  ///
  /// In en, this message translates to:
  /// **'This competition is finished. Select it when organizing past match records.'**
  String get matchCompetitionFinishedNotice;

  /// No description provided for @matchCompetitionManageButton.
  ///
  /// In en, this message translates to:
  /// **'Teams / results'**
  String get matchCompetitionManageButton;

  /// No description provided for @matchCompetitionOpenButton.
  ///
  /// In en, this message translates to:
  /// **'Competition management'**
  String get matchCompetitionOpenButton;

  /// No description provided for @matchCompetitionOpenHelper.
  ///
  /// In en, this message translates to:
  /// **'Run leagues and tournaments'**
  String get matchCompetitionOpenHelper;

  /// No description provided for @matchCompetitionProTitle.
  ///
  /// In en, this message translates to:
  /// **'Competition Operations Center'**
  String get matchCompetitionProTitle;

  /// No description provided for @matchCompetitionProSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Manage participating teams, operations details, standings, and brackets with coaches and players.'**
  String get matchCompetitionProSubtitle;

  /// No description provided for @matchCompetitionOperationsSummaryTitle.
  ///
  /// In en, this message translates to:
  /// **'Operations summary'**
  String get matchCompetitionOperationsSummaryTitle;

  /// No description provided for @matchCompetitionListTitle.
  ///
  /// In en, this message translates to:
  /// **'Competition status'**
  String get matchCompetitionListTitle;

  /// No description provided for @matchCompetitionListCount.
  ///
  /// In en, this message translates to:
  /// **'{count} competitions'**
  String matchCompetitionListCount(int count);

  /// No description provided for @matchCompetitionCreateLeagueButton.
  ///
  /// In en, this message translates to:
  /// **'Create league'**
  String get matchCompetitionCreateLeagueButton;

  /// No description provided for @matchCompetitionCreateTournamentButton.
  ///
  /// In en, this message translates to:
  /// **'Create tournament'**
  String get matchCompetitionCreateTournamentButton;

  /// No description provided for @matchCompetitionSeasonLabel.
  ///
  /// In en, this message translates to:
  /// **'Season'**
  String get matchCompetitionSeasonLabel;

  /// No description provided for @matchCompetitionSeasonHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. Summer 2026'**
  String get matchCompetitionSeasonHint;

  /// No description provided for @matchCompetitionVenueLabel.
  ///
  /// In en, this message translates to:
  /// **'Venue'**
  String get matchCompetitionVenueLabel;

  /// No description provided for @matchCompetitionVenueHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. Main pitch'**
  String get matchCompetitionVenueHint;

  /// No description provided for @matchCompetitionOrganizerLabel.
  ///
  /// In en, this message translates to:
  /// **'Lead'**
  String get matchCompetitionOrganizerLabel;

  /// No description provided for @matchCompetitionOrganizerHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. Coach Kim'**
  String get matchCompetitionOrganizerHint;

  /// No description provided for @matchCompetitionNoteLabel.
  ///
  /// In en, this message translates to:
  /// **'Operations note'**
  String get matchCompetitionNoteLabel;

  /// No description provided for @matchCompetitionNoteHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. Groups into knockout, rotation required'**
  String get matchCompetitionNoteHint;

  /// No description provided for @matchCompetitionSaveCompetition.
  ///
  /// In en, this message translates to:
  /// **'Save competition'**
  String get matchCompetitionSaveCompetition;

  /// No description provided for @matchCompetitionEditButton.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get matchCompetitionEditButton;

  /// No description provided for @matchCompetitionEditorBasicsTitle.
  ///
  /// In en, this message translates to:
  /// **'Competition basics'**
  String get matchCompetitionEditorBasicsTitle;

  /// No description provided for @matchCompetitionEditorOperationsTitle.
  ///
  /// In en, this message translates to:
  /// **'Operations details'**
  String get matchCompetitionEditorOperationsTitle;

  /// No description provided for @matchCompetitionNoCompetitionsProBody.
  ///
  /// In en, this message translates to:
  /// **'Create a league or tournament first to manage teams, operations details, standings, and brackets professionally.'**
  String get matchCompetitionNoCompetitionsProBody;

  /// No description provided for @matchCompetitionOperationsDetailEmpty.
  ///
  /// In en, this message translates to:
  /// **'No operations details'**
  String get matchCompetitionOperationsDetailEmpty;

  /// No description provided for @matchCompetitionNextActionLabel.
  ///
  /// In en, this message translates to:
  /// **'Next operation'**
  String get matchCompetitionNextActionLabel;

  /// No description provided for @matchCompetitionNextRegisterTeams.
  ///
  /// In en, this message translates to:
  /// **'Register teams'**
  String get matchCompetitionNextRegisterTeams;

  /// No description provided for @matchCompetitionNextRecordFirstMatch.
  ///
  /// In en, this message translates to:
  /// **'Record first match'**
  String get matchCompetitionNextRecordFirstMatch;

  /// No description provided for @matchCompetitionNextRecordNextMatch.
  ///
  /// In en, this message translates to:
  /// **'Record next match'**
  String get matchCompetitionNextRecordNextMatch;

  /// No description provided for @matchCompetitionNextCloseCompetition.
  ///
  /// In en, this message translates to:
  /// **'Review closing'**
  String get matchCompetitionNextCloseCompetition;

  /// No description provided for @matchCompetitionNextReviewArchive.
  ///
  /// In en, this message translates to:
  /// **'Review archive'**
  String get matchCompetitionNextReviewArchive;

  /// No description provided for @matchCompetitionProgressPercent.
  ///
  /// In en, this message translates to:
  /// **'Progress {percent}%'**
  String matchCompetitionProgressPercent(int percent);

  /// No description provided for @matchCompetitionManagerNewTitle.
  ///
  /// In en, this message translates to:
  /// **'Competition manager'**
  String get matchCompetitionManagerNewTitle;

  /// No description provided for @matchCompetitionManagerTitle.
  ///
  /// In en, this message translates to:
  /// **'{name} manager'**
  String matchCompetitionManagerTitle(String name);

  /// No description provided for @matchCompetitionTeamsTab.
  ///
  /// In en, this message translates to:
  /// **'Teams'**
  String get matchCompetitionTeamsTab;

  /// No description provided for @matchCompetitionResultsTab.
  ///
  /// In en, this message translates to:
  /// **'Results'**
  String get matchCompetitionResultsTab;

  /// No description provided for @matchCompetitionBackButton.
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get matchCompetitionBackButton;

  /// No description provided for @matchCompetitionTeamPreviewTitle.
  ///
  /// In en, this message translates to:
  /// **'Team preview'**
  String get matchCompetitionTeamPreviewTitle;

  /// No description provided for @matchCompetitionTeamNameLabel.
  ///
  /// In en, this message translates to:
  /// **'Team name'**
  String get matchCompetitionTeamNameLabel;

  /// No description provided for @matchCompetitionAddTeamButton.
  ///
  /// In en, this message translates to:
  /// **'Add'**
  String get matchCompetitionAddTeamButton;

  /// No description provided for @matchCompetitionTeamNameRequired.
  ///
  /// In en, this message translates to:
  /// **'Enter a team name.'**
  String get matchCompetitionTeamNameRequired;

  /// No description provided for @matchCompetitionTeamAlreadyAdded.
  ///
  /// In en, this message translates to:
  /// **'That team is already registered.'**
  String get matchCompetitionTeamAlreadyAdded;

  /// No description provided for @matchCompetitionTeamsListTitle.
  ///
  /// In en, this message translates to:
  /// **'Registered teams'**
  String get matchCompetitionTeamsListTitle;

  /// No description provided for @matchCompetitionRemoveTeamTooltip.
  ///
  /// In en, this message translates to:
  /// **'Remove {team}'**
  String matchCompetitionRemoveTeamTooltip(String team);

  /// No description provided for @matchCompetitionTeamsInputLabel.
  ///
  /// In en, this message translates to:
  /// **'Participating teams'**
  String get matchCompetitionTeamsInputLabel;

  /// No description provided for @matchCompetitionTeamsInputHint.
  ///
  /// In en, this message translates to:
  /// **'Enter one team per line or separate with commas'**
  String get matchCompetitionTeamsInputHint;

  /// No description provided for @matchCompetitionTeamCount.
  ///
  /// In en, this message translates to:
  /// **'{count} team(s) registered'**
  String matchCompetitionTeamCount(int count);

  /// No description provided for @matchCompetitionSaveTeams.
  ///
  /// In en, this message translates to:
  /// **'Save teams'**
  String get matchCompetitionSaveTeams;

  /// No description provided for @matchCompetitionSavedFeedback.
  ///
  /// In en, this message translates to:
  /// **'Competition details saved.'**
  String get matchCompetitionSavedFeedback;

  /// No description provided for @matchCompetitionNameRequired.
  ///
  /// In en, this message translates to:
  /// **'Enter a competition name.'**
  String get matchCompetitionNameRequired;

  /// No description provided for @matchLeagueStandingsTitle.
  ///
  /// In en, this message translates to:
  /// **'League standings'**
  String get matchLeagueStandingsTitle;

  /// No description provided for @matchTournamentBracketTitle.
  ///
  /// In en, this message translates to:
  /// **'Tournament bracket'**
  String get matchTournamentBracketTitle;

  /// No description provided for @matchCompetitionNoTeams.
  ///
  /// In en, this message translates to:
  /// **'No teams are registered.'**
  String get matchCompetitionNoTeams;

  /// No description provided for @matchCompetitionNoMatches.
  ///
  /// In en, this message translates to:
  /// **'No matches are recorded yet.'**
  String get matchCompetitionNoMatches;

  /// No description provided for @matchCompetitionMyTeamFallback.
  ///
  /// In en, this message translates to:
  /// **'Our team'**
  String get matchCompetitionMyTeamFallback;

  /// No description provided for @matchTournamentByeLabel.
  ///
  /// In en, this message translates to:
  /// **'Bye'**
  String get matchTournamentByeLabel;

  /// No description provided for @matchTournamentPairLabel.
  ///
  /// In en, this message translates to:
  /// **'Match {number}'**
  String matchTournamentPairLabel(int number);

  /// No description provided for @matchTournamentPairText.
  ///
  /// In en, this message translates to:
  /// **'{teamA} vs {teamB}'**
  String matchTournamentPairText(String teamA, String teamB);

  /// No description provided for @matchTournamentRecordedProgressTitle.
  ///
  /// In en, this message translates to:
  /// **'Recorded progress'**
  String get matchTournamentRecordedProgressTitle;

  /// No description provided for @matchTournamentRecordedProgress.
  ///
  /// In en, this message translates to:
  /// **'{stage} · vs {opponent} · {outcome}'**
  String matchTournamentRecordedProgress(
      String stage, String opponent, String outcome);

  /// No description provided for @matchCompetitionSummaryTeams.
  ///
  /// In en, this message translates to:
  /// **'Teams'**
  String get matchCompetitionSummaryTeams;

  /// No description provided for @matchCompetitionSummaryMatches.
  ///
  /// In en, this message translates to:
  /// **'Recorded matches'**
  String get matchCompetitionSummaryMatches;

  /// No description provided for @matchCompetitionSummaryLeader.
  ///
  /// In en, this message translates to:
  /// **'Leader'**
  String get matchCompetitionSummaryLeader;

  /// No description provided for @matchCompetitionSummaryRecorded.
  ///
  /// In en, this message translates to:
  /// **'Recorded'**
  String get matchCompetitionSummaryRecorded;

  /// No description provided for @matchCompetitionSummaryProgress.
  ///
  /// In en, this message translates to:
  /// **'Progress'**
  String get matchCompetitionSummaryProgress;

  /// No description provided for @matchCompetitionNoLeader.
  ///
  /// In en, this message translates to:
  /// **'None yet'**
  String get matchCompetitionNoLeader;

  /// No description provided for @matchTournamentSummarySlots.
  ///
  /// In en, this message translates to:
  /// **'Bracket slots'**
  String get matchTournamentSummarySlots;

  /// No description provided for @matchTournamentSlotProgress.
  ///
  /// In en, this message translates to:
  /// **'{recorded}/{total}'**
  String matchTournamentSlotProgress(int recorded, int total);

  /// No description provided for @matchTournamentPairPending.
  ///
  /// In en, this message translates to:
  /// **'Pending'**
  String get matchTournamentPairPending;

  /// No description provided for @matchTournamentPairByeStatus.
  ///
  /// In en, this message translates to:
  /// **'Bye'**
  String get matchTournamentPairByeStatus;

  /// No description provided for @matchTournamentVersusLabel.
  ///
  /// In en, this message translates to:
  /// **'vs'**
  String get matchTournamentVersusLabel;

  /// No description provided for @matchLeaguePlayedSummary.
  ///
  /// In en, this message translates to:
  /// **'{played} played'**
  String matchLeaguePlayedSummary(int played);

  /// No description provided for @matchLeagueRecordSummary.
  ///
  /// In en, this message translates to:
  /// **'{wins}W {draws}D {losses}L'**
  String matchLeagueRecordSummary(int wins, int draws, int losses);

  /// No description provided for @matchLeagueGoalDifferenceSummary.
  ///
  /// In en, this message translates to:
  /// **'GD {difference}'**
  String matchLeagueGoalDifferenceSummary(int difference);

  /// No description provided for @matchLeaguePointsSummary.
  ///
  /// In en, this message translates to:
  /// **'{points} pts'**
  String matchLeaguePointsSummary(int points);

  /// No description provided for @matchLeagueRoundLabel.
  ///
  /// In en, this message translates to:
  /// **'Round or matchday'**
  String get matchLeagueRoundLabel;

  /// No description provided for @matchLeagueRoundHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. Round 3'**
  String get matchLeagueRoundHint;

  /// No description provided for @matchTournamentStageLabel.
  ///
  /// In en, this message translates to:
  /// **'Tournament stage'**
  String get matchTournamentStageLabel;

  /// No description provided for @matchTournamentStagePreliminary.
  ///
  /// In en, this message translates to:
  /// **'Preliminary'**
  String get matchTournamentStagePreliminary;

  /// No description provided for @matchTournamentStageRound16.
  ///
  /// In en, this message translates to:
  /// **'Round of 16'**
  String get matchTournamentStageRound16;

  /// No description provided for @matchTournamentStageQuarterfinal.
  ///
  /// In en, this message translates to:
  /// **'Quarterfinal'**
  String get matchTournamentStageQuarterfinal;

  /// No description provided for @matchTournamentStageSemifinal.
  ///
  /// In en, this message translates to:
  /// **'Semifinal'**
  String get matchTournamentStageSemifinal;

  /// No description provided for @matchTournamentStageFinal.
  ///
  /// In en, this message translates to:
  /// **'Final'**
  String get matchTournamentStageFinal;

  /// No description provided for @matchTournamentOutcomeLabel.
  ///
  /// In en, this message translates to:
  /// **'Progress result'**
  String get matchTournamentOutcomeLabel;

  /// No description provided for @matchTournamentOutcomeOngoing.
  ///
  /// In en, this message translates to:
  /// **'In progress'**
  String get matchTournamentOutcomeOngoing;

  /// No description provided for @matchTournamentOutcomeAdvanced.
  ///
  /// In en, this message translates to:
  /// **'Advanced'**
  String get matchTournamentOutcomeAdvanced;

  /// No description provided for @matchTournamentOutcomeEliminated.
  ///
  /// In en, this message translates to:
  /// **'Eliminated'**
  String get matchTournamentOutcomeEliminated;

  /// No description provided for @matchTournamentOutcomeChampion.
  ///
  /// In en, this message translates to:
  /// **'Champion'**
  String get matchTournamentOutcomeChampion;

  /// No description provided for @matchOpponentTeamLabel.
  ///
  /// In en, this message translates to:
  /// **'Opponent team'**
  String get matchOpponentTeamLabel;

  /// No description provided for @matchOpponentTeamHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. Suwon U15'**
  String get matchOpponentTeamHint;

  /// No description provided for @matchLocationHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. Main stadium'**
  String get matchLocationHint;

  /// No description provided for @matchFlowBasicSectionTitle.
  ///
  /// In en, this message translates to:
  /// **'Basics'**
  String get matchFlowBasicSectionTitle;

  /// No description provided for @matchFlowCompetitionSectionTitle.
  ///
  /// In en, this message translates to:
  /// **'Competition setup'**
  String get matchFlowCompetitionSectionTitle;

  /// No description provided for @matchFlowCompetitionSectionHelper.
  ///
  /// In en, this message translates to:
  /// **'Select a saved competition first to fill teams and status together.'**
  String get matchFlowCompetitionSectionHelper;

  /// No description provided for @matchFlowOpponentSectionTitle.
  ///
  /// In en, this message translates to:
  /// **'Opponent'**
  String get matchFlowOpponentSectionTitle;

  /// No description provided for @matchFlowOpponentSectionHelper.
  ///
  /// In en, this message translates to:
  /// **'Choose this match\'s opponent from the registered teams.'**
  String get matchFlowOpponentSectionHelper;

  /// No description provided for @matchFlowResultSectionTitle.
  ///
  /// In en, this message translates to:
  /// **'Result'**
  String get matchFlowResultSectionTitle;

  /// No description provided for @matchFlowResultSectionHelper.
  ///
  /// In en, this message translates to:
  /// **'Pick W/D/L first, then adjust the score and competition result.'**
  String get matchFlowResultSectionHelper;

  /// No description provided for @matchFlowPersonalSectionTitle.
  ///
  /// In en, this message translates to:
  /// **'Personal record'**
  String get matchFlowPersonalSectionTitle;

  /// No description provided for @matchFlowPersonalSectionHelper.
  ///
  /// In en, this message translates to:
  /// **'Add values you want to review later, such as goals, assists, and minutes.'**
  String get matchFlowPersonalSectionHelper;

  /// No description provided for @matchLeagueTeamsLabel.
  ///
  /// In en, this message translates to:
  /// **'League teams'**
  String get matchLeagueTeamsLabel;

  /// No description provided for @matchLeagueTeamsHint.
  ///
  /// In en, this message translates to:
  /// **'Enter one team per line or separate with commas'**
  String get matchLeagueTeamsHint;

  /// No description provided for @matchTournamentTeamsLabel.
  ///
  /// In en, this message translates to:
  /// **'Tournament teams'**
  String get matchTournamentTeamsLabel;

  /// No description provided for @matchTournamentTeamsHint.
  ///
  /// In en, this message translates to:
  /// **'Enter participating teams one per line or separate them with commas'**
  String get matchTournamentTeamsHint;

  /// No description provided for @matchLeaguePointsMode.
  ///
  /// In en, this message translates to:
  /// **'Points'**
  String get matchLeaguePointsMode;

  /// No description provided for @matchTournamentWinsMode.
  ///
  /// In en, this message translates to:
  /// **'Tournament wins'**
  String get matchTournamentWinsMode;

  /// No description provided for @matchLeaguePointsLabel.
  ///
  /// In en, this message translates to:
  /// **'League points'**
  String get matchLeaguePointsLabel;

  /// No description provided for @matchTournamentWinsLabel.
  ///
  /// In en, this message translates to:
  /// **'Tournament wins'**
  String get matchTournamentWinsLabel;

  /// No description provided for @matchLeaguePointsValue.
  ///
  /// In en, this message translates to:
  /// **'{points} pts'**
  String matchLeaguePointsValue(int points);

  /// No description provided for @matchTournamentWinsValue.
  ///
  /// In en, this message translates to:
  /// **'{count} wins'**
  String matchTournamentWinsValue(int count);

  /// No description provided for @matchOurScoreLabel.
  ///
  /// In en, this message translates to:
  /// **'Our score'**
  String get matchOurScoreLabel;

  /// No description provided for @matchOpponentScoreLabel.
  ///
  /// In en, this message translates to:
  /// **'Opponent score'**
  String get matchOpponentScoreLabel;

  /// No description provided for @matchGoalsLabel.
  ///
  /// In en, this message translates to:
  /// **'Goals'**
  String get matchGoalsLabel;

  /// No description provided for @matchAssistsLabel.
  ///
  /// In en, this message translates to:
  /// **'Assists'**
  String get matchAssistsLabel;

  /// No description provided for @matchCountIncreaseTooltip.
  ///
  /// In en, this message translates to:
  /// **'Increase {label}'**
  String matchCountIncreaseTooltip(String label);

  /// No description provided for @matchCountDecreaseTooltip.
  ///
  /// In en, this message translates to:
  /// **'Decrease {label}'**
  String matchCountDecreaseTooltip(String label);

  /// No description provided for @matchMinutesPlayedLabel.
  ///
  /// In en, this message translates to:
  /// **'Minutes played'**
  String get matchMinutesPlayedLabel;

  /// No description provided for @matchMinutesPlayedHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. 70'**
  String get matchMinutesPlayedHint;

  /// No description provided for @matchNoteOptionalLabel.
  ///
  /// In en, this message translates to:
  /// **'Note (optional)'**
  String get matchNoteOptionalLabel;

  /// No description provided for @matchShotsOnTargetLabel.
  ///
  /// In en, this message translates to:
  /// **'Shots on target'**
  String get matchShotsOnTargetLabel;

  /// No description provided for @matchBallsWonLabel.
  ///
  /// In en, this message translates to:
  /// **'Balls won'**
  String get matchBallsWonLabel;

  /// No description provided for @matchHubTopActionTooltip.
  ///
  /// In en, this message translates to:
  /// **'Match Hub'**
  String get matchHubTopActionTooltip;

  /// No description provided for @matchHubTitle.
  ///
  /// In en, this message translates to:
  /// **'Match Hub'**
  String get matchHubTitle;

  /// No description provided for @matchHubSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Organize match records, competitions, and schedule flow, then connect them to your team operations.'**
  String get matchHubSubtitle;

  /// No description provided for @matchHubOverviewTitle.
  ///
  /// In en, this message translates to:
  /// **'Match operations board'**
  String get matchHubOverviewTitle;

  /// No description provided for @matchHubRecentFormLabel.
  ///
  /// In en, this message translates to:
  /// **'Recent form'**
  String get matchHubRecentFormLabel;

  /// No description provided for @matchHubRecordButton.
  ///
  /// In en, this message translates to:
  /// **'Record match'**
  String get matchHubRecordButton;

  /// No description provided for @matchEntryManagedInHubTitle.
  ///
  /// In en, this message translates to:
  /// **'Match records are managed in the Match Hub.'**
  String get matchEntryManagedInHubTitle;

  /// No description provided for @matchEntryManagedInHubBody.
  ///
  /// In en, this message translates to:
  /// **'Training notes no longer show match details. View and edit matches from the top Match Hub.'**
  String get matchEntryManagedInHubBody;

  /// No description provided for @matchHubRecordHelper.
  ///
  /// In en, this message translates to:
  /// **'Enter today\'s result quickly'**
  String get matchHubRecordHelper;

  /// No description provided for @matchRecordsOpenButton.
  ///
  /// In en, this message translates to:
  /// **'Match records'**
  String get matchRecordsOpenButton;

  /// No description provided for @matchRecordsOpenHelper.
  ///
  /// In en, this message translates to:
  /// **'Review past match results'**
  String get matchRecordsOpenHelper;

  /// No description provided for @matchRecordsTitle.
  ///
  /// In en, this message translates to:
  /// **'Match records'**
  String get matchRecordsTitle;

  /// No description provided for @matchRecordsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Review friendly, league, and tournament results by date.'**
  String get matchRecordsSubtitle;

  /// No description provided for @matchRecordsSummaryTitle.
  ///
  /// In en, this message translates to:
  /// **'Record summary'**
  String get matchRecordsSummaryTitle;

  /// No description provided for @matchRecordsListTitle.
  ///
  /// In en, this message translates to:
  /// **'All match records'**
  String get matchRecordsListTitle;

  /// No description provided for @matchHubCalendarButton.
  ///
  /// In en, this message translates to:
  /// **'Open calendar'**
  String get matchHubCalendarButton;

  /// No description provided for @matchHubCalendarHelper.
  ///
  /// In en, this message translates to:
  /// **'Review matches and plans by date'**
  String get matchHubCalendarHelper;

  /// No description provided for @matchHubStatsButton.
  ///
  /// In en, this message translates to:
  /// **'Match stats'**
  String get matchHubStatsButton;

  /// No description provided for @matchHubStatsHelper.
  ///
  /// In en, this message translates to:
  /// **'Analyze record and personal output'**
  String get matchHubStatsHelper;

  /// No description provided for @matchHubCompetitionHelper.
  ///
  /// In en, this message translates to:
  /// **'Manage teams and competition results'**
  String get matchHubCompetitionHelper;

  /// No description provided for @matchHubCompetitionsTitle.
  ///
  /// In en, this message translates to:
  /// **'Competition board'**
  String get matchHubCompetitionsTitle;

  /// No description provided for @matchHubNoCompetitionsTitle.
  ///
  /// In en, this message translates to:
  /// **'No competitions registered.'**
  String get matchHubNoCompetitionsTitle;

  /// No description provided for @matchHubNoCompetitionsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'When you record league or tournament matches, teams, standings, and brackets collect here.'**
  String get matchHubNoCompetitionsSubtitle;

  /// No description provided for @matchHubRecentMatchesTitle.
  ///
  /// In en, this message translates to:
  /// **'Recent matches'**
  String get matchHubRecentMatchesTitle;

  /// No description provided for @matchHubEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'No match records yet.'**
  String get matchHubEmptyTitle;

  /// No description provided for @matchHubEmptySubtitle.
  ///
  /// In en, this message translates to:
  /// **'Start with a friendly match to calculate win rate and recent form.'**
  String get matchHubEmptySubtitle;

  /// No description provided for @matchHubOpeningFeedback.
  ///
  /// In en, this message translates to:
  /// **'Opening Match Hub.'**
  String get matchHubOpeningFeedback;

  /// No description provided for @matchHubRecordedOnlyProgress.
  ///
  /// In en, this message translates to:
  /// **'{count} match(es) recorded'**
  String matchHubRecordedOnlyProgress(int count);

  /// No description provided for @matchHubKindBreakdown.
  ///
  /// In en, this message translates to:
  /// **'Friendly {friendly} · League {league} · Tournament {tournament}'**
  String matchHubKindBreakdown(int friendly, int league, int tournament);

  /// No description provided for @matchHubCompetitionStateLabel.
  ///
  /// In en, this message translates to:
  /// **'Competition status'**
  String get matchHubCompetitionStateLabel;

  /// No description provided for @matchHubCompetitionStateValue.
  ///
  /// In en, this message translates to:
  /// **'Active {active} · Finished {finished}'**
  String matchHubCompetitionStateValue(int active, int finished);

  /// No description provided for @matchHubTeamManagementHeaderSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Review match records, competitions, and team status in the match flow.'**
  String get matchHubTeamManagementHeaderSubtitle;

  /// No description provided for @matchHubTeamManagementTitle.
  ///
  /// In en, this message translates to:
  /// **'Our team'**
  String get matchHubTeamManagementTitle;

  /// No description provided for @matchHubTeamManagementHelper.
  ///
  /// In en, this message translates to:
  /// **'Manage roster, schedule, and lineup'**
  String get matchHubTeamManagementHelper;

  /// No description provided for @matchHubTeamStateLabel.
  ///
  /// In en, this message translates to:
  /// **'Our team'**
  String get matchHubTeamStateLabel;

  /// No description provided for @matchHubTeamStateValue.
  ///
  /// In en, this message translates to:
  /// **'{count} team(s)'**
  String matchHubTeamStateValue(int count);

  /// No description provided for @matchHubNoPrimaryTeamValue.
  ///
  /// In en, this message translates to:
  /// **'Not set'**
  String get matchHubNoPrimaryTeamValue;

  /// No description provided for @matchHubNoTeamsTitle.
  ///
  /// In en, this message translates to:
  /// **'No team set yet.'**
  String get matchHubNoTeamsTitle;

  /// No description provided for @matchHubNoTeamsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Prepare your team in the team operations screen where the roster is visible immediately.'**
  String get matchHubNoTeamsSubtitle;

  /// No description provided for @matchHubMoreTeamsCount.
  ///
  /// In en, this message translates to:
  /// **'{count} more team(s)'**
  String matchHubMoreTeamsCount(int count);

  /// No description provided for @matchHubTeamFormationValue.
  ///
  /// In en, this message translates to:
  /// **'{formation} formation'**
  String matchHubTeamFormationValue(Object formation);

  /// No description provided for @clubScheduleTitle.
  ///
  /// In en, this message translates to:
  /// **'Club Schedule'**
  String get clubScheduleTitle;

  /// No description provided for @clubScheduleSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Check weekly training times and uniform colors quickly.'**
  String get clubScheduleSubtitle;

  /// No description provided for @clubScheduleHomeTitle.
  ///
  /// In en, this message translates to:
  /// **'Club schedule'**
  String get clubScheduleHomeTitle;

  /// No description provided for @clubScheduleHomeTodayRest.
  ///
  /// In en, this message translates to:
  /// **'No training today'**
  String get clubScheduleHomeTodayRest;

  /// No description provided for @clubScheduleHomeSetupHint.
  ///
  /// In en, this message translates to:
  /// **'Add training times and uniform colors.'**
  String get clubScheduleHomeSetupHint;

  /// No description provided for @clubScheduleHomeNextTraining.
  ///
  /// In en, this message translates to:
  /// **'Next training {weekday} {time}'**
  String clubScheduleHomeNextTraining(Object weekday, Object time);

  /// No description provided for @clubScheduleTodayTraining.
  ///
  /// In en, this message translates to:
  /// **'Today {time}'**
  String clubScheduleTodayTraining(Object time);

  /// No description provided for @clubScheduleTodayNoTraining.
  ///
  /// In en, this message translates to:
  /// **'No training is set for today.'**
  String get clubScheduleTodayNoTraining;

  /// No description provided for @clubScheduleNextTraining.
  ///
  /// In en, this message translates to:
  /// **'Next training: {weekday} {time}'**
  String clubScheduleNextTraining(Object weekday, Object time);

  /// No description provided for @clubScheduleNoUpcomingTraining.
  ///
  /// In en, this message translates to:
  /// **'No upcoming training.'**
  String get clubScheduleNoUpcomingTraining;

  /// No description provided for @clubScheduleClubNameLabel.
  ///
  /// In en, this message translates to:
  /// **'Club name'**
  String get clubScheduleClubNameLabel;

  /// No description provided for @clubScheduleClubNameHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. Seongnam U15'**
  String get clubScheduleClubNameHint;

  /// No description provided for @clubScheduleWeekdayTitle.
  ///
  /// In en, this message translates to:
  /// **'Weekly training times'**
  String get clubScheduleWeekdayTitle;

  /// No description provided for @clubScheduleWeekdayHelper.
  ///
  /// In en, this message translates to:
  /// **'Turn on training days, then set start time, end time, and uniform color.'**
  String get clubScheduleWeekdayHelper;

  /// No description provided for @clubScheduleStartTimeLabel.
  ///
  /// In en, this message translates to:
  /// **'Start'**
  String get clubScheduleStartTimeLabel;

  /// No description provided for @clubScheduleEndTimeLabel.
  ///
  /// In en, this message translates to:
  /// **'End'**
  String get clubScheduleEndTimeLabel;

  /// No description provided for @clubScheduleDayOffLabel.
  ///
  /// In en, this message translates to:
  /// **'Off'**
  String get clubScheduleDayOffLabel;

  /// No description provided for @clubScheduleDayUniformLabel.
  ///
  /// In en, this message translates to:
  /// **'Uniform'**
  String get clubScheduleDayUniformLabel;

  /// No description provided for @clubScheduleUniformTitle.
  ///
  /// In en, this message translates to:
  /// **'Uniform colors'**
  String get clubScheduleUniformTitle;

  /// No description provided for @clubScheduleUniformHelper.
  ///
  /// In en, this message translates to:
  /// **'Save the home, away, and goalkeeper colors you need at training.'**
  String get clubScheduleUniformHelper;

  /// No description provided for @clubScheduleHomeKitLabel.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get clubScheduleHomeKitLabel;

  /// No description provided for @clubScheduleAwayKitLabel.
  ///
  /// In en, this message translates to:
  /// **'Away'**
  String get clubScheduleAwayKitLabel;

  /// No description provided for @clubScheduleKeeperKitLabel.
  ///
  /// In en, this message translates to:
  /// **'GK'**
  String get clubScheduleKeeperKitLabel;

  /// No description provided for @clubScheduleColorSelectTooltip.
  ///
  /// In en, this message translates to:
  /// **'Select color'**
  String get clubScheduleColorSelectTooltip;

  /// No description provided for @clubScheduleColorPresetsLabel.
  ///
  /// In en, this message translates to:
  /// **'Common colors'**
  String get clubScheduleColorPresetsLabel;

  /// No description provided for @clubScheduleColorHueLabel.
  ///
  /// In en, this message translates to:
  /// **'Hue'**
  String get clubScheduleColorHueLabel;

  /// No description provided for @clubScheduleColorSaturationLabel.
  ///
  /// In en, this message translates to:
  /// **'Saturation'**
  String get clubScheduleColorSaturationLabel;

  /// No description provided for @clubScheduleColorBrightnessLabel.
  ///
  /// In en, this message translates to:
  /// **'Brightness'**
  String get clubScheduleColorBrightnessLabel;

  /// No description provided for @clubScheduleSaveButton.
  ///
  /// In en, this message translates to:
  /// **'Save club schedule'**
  String get clubScheduleSaveButton;

  /// No description provided for @clubScheduleSavedFeedback.
  ///
  /// In en, this message translates to:
  /// **'Club schedule saved.'**
  String get clubScheduleSavedFeedback;

  /// No description provided for @clubScheduleSaveFailedFeedback.
  ///
  /// In en, this message translates to:
  /// **'Could not save the club schedule. Please try again.'**
  String get clubScheduleSaveFailedFeedback;

  /// No description provided for @clubScheduleUnsavedDialogTitle.
  ///
  /// In en, this message translates to:
  /// **'Unsaved changes'**
  String get clubScheduleUnsavedDialogTitle;

  /// No description provided for @clubScheduleUnsavedDialogBody.
  ///
  /// In en, this message translates to:
  /// **'Some club schedule changes have not been saved yet. Save before leaving?'**
  String get clubScheduleUnsavedDialogBody;

  /// No description provided for @clubScheduleUnsavedKeepEditing.
  ///
  /// In en, this message translates to:
  /// **'Keep editing'**
  String get clubScheduleUnsavedKeepEditing;

  /// No description provided for @clubScheduleUnsavedLeaveWithoutSaving.
  ///
  /// In en, this message translates to:
  /// **'Leave without saving'**
  String get clubScheduleUnsavedLeaveWithoutSaving;

  /// No description provided for @clubScheduleUnsavedSaveAndLeave.
  ///
  /// In en, this message translates to:
  /// **'Save and leave'**
  String get clubScheduleUnsavedSaveAndLeave;

  /// No description provided for @clubTrainingNotificationChannelName.
  ///
  /// In en, this message translates to:
  /// **'Club training alerts'**
  String get clubTrainingNotificationChannelName;

  /// No description provided for @clubTrainingNotificationChannelDescription.
  ///
  /// In en, this message translates to:
  /// **'Reminders before club training starts'**
  String get clubTrainingNotificationChannelDescription;

  /// No description provided for @clubTrainingNotificationTitle.
  ///
  /// In en, this message translates to:
  /// **'{clubName} training prep'**
  String clubTrainingNotificationTitle(Object clubName);

  /// No description provided for @clubTrainingNotificationBody.
  ///
  /// In en, this message translates to:
  /// **'Training in {minutesBefore} min · {timeRange} · Uniform {uniform}'**
  String clubTrainingNotificationBody(
      int minutesBefore, Object timeRange, Object uniform);

  /// No description provided for @teamManagementTitle.
  ///
  /// In en, this message translates to:
  /// **'Team Operations'**
  String get teamManagementTitle;

  /// No description provided for @teamManagementSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Manage one team roster, schedule, lineup, and tactics board on one screen.'**
  String get teamManagementSubtitle;

  /// No description provided for @teamManagementOpenButton.
  ///
  /// In en, this message translates to:
  /// **'Team operations'**
  String get teamManagementOpenButton;

  /// No description provided for @teamManagementDefaultTeamName.
  ///
  /// In en, this message translates to:
  /// **'Our team'**
  String get teamManagementDefaultTeamName;

  /// No description provided for @teamManagementSavedTeamsTitle.
  ///
  /// In en, this message translates to:
  /// **'Team selector'**
  String get teamManagementSavedTeamsTitle;

  /// No description provided for @teamManagementSavedTeamsHelper.
  ///
  /// In en, this message translates to:
  /// **'Select a saved team to continue operating its roster, tactical principles, and board placement.'**
  String get teamManagementSavedTeamsHelper;

  /// No description provided for @teamManagementNoTeamsTitle.
  ///
  /// In en, this message translates to:
  /// **'Preparing your first team.'**
  String get teamManagementNoTeamsTitle;

  /// No description provided for @teamManagementNoTeamsBody.
  ///
  /// In en, this message translates to:
  /// **'Enter a team name and roster, and it will auto-save into a team card here.'**
  String get teamManagementNoTeamsBody;

  /// No description provided for @teamManagementOperationsTitle.
  ///
  /// In en, this message translates to:
  /// **'Operations Summary'**
  String get teamManagementOperationsTitle;

  /// No description provided for @teamManagementOperationsHelper.
  ///
  /// In en, this message translates to:
  /// **'Review next training, roster status, lineup readiness, and competitions at a glance.'**
  String get teamManagementOperationsHelper;

  /// No description provided for @teamManagementOperationsNextTrainingLabel.
  ///
  /// In en, this message translates to:
  /// **'Next training'**
  String get teamManagementOperationsNextTrainingLabel;

  /// No description provided for @teamManagementOperationsNextTrainingUnset.
  ///
  /// In en, this message translates to:
  /// **'No training set'**
  String get teamManagementOperationsNextTrainingUnset;

  /// No description provided for @teamManagementOperationsRosterLabel.
  ///
  /// In en, this message translates to:
  /// **'Roster status'**
  String get teamManagementOperationsRosterLabel;

  /// No description provided for @teamManagementOperationsRosterValue.
  ///
  /// In en, this message translates to:
  /// **'{total} total · {managed} managed'**
  String teamManagementOperationsRosterValue(int total, int managed);

  /// No description provided for @teamManagementOperationsLineupLabel.
  ///
  /// In en, this message translates to:
  /// **'Lineup'**
  String get teamManagementOperationsLineupLabel;

  /// No description provided for @teamManagementOperationsCompetitionsLabel.
  ///
  /// In en, this message translates to:
  /// **'Competitions'**
  String get teamManagementOperationsCompetitionsLabel;

  /// No description provided for @teamManagementOperationsCompetitionsValue.
  ///
  /// In en, this message translates to:
  /// **'{active} active · {total} total'**
  String teamManagementOperationsCompetitionsValue(int active, int total);

  /// No description provided for @teamManagementOperationsScheduleTitle.
  ///
  /// In en, this message translates to:
  /// **'Schedule and competitions'**
  String get teamManagementOperationsScheduleTitle;

  /// No description provided for @teamManagementOperationsScheduleHelper.
  ///
  /// In en, this message translates to:
  /// **'Organize training days, uniforms, and competitions in the schedule section.'**
  String get teamManagementOperationsScheduleHelper;

  /// No description provided for @teamManagementOperationsOpenScheduleButton.
  ///
  /// In en, this message translates to:
  /// **'Edit schedule'**
  String get teamManagementOperationsOpenScheduleButton;

  /// No description provided for @teamManagementOperationsNoTraining.
  ///
  /// In en, this message translates to:
  /// **'No training schedule has been set.'**
  String get teamManagementOperationsNoTraining;

  /// No description provided for @teamManagementOperationsUniformLabel.
  ///
  /// In en, this message translates to:
  /// **'Uniforms'**
  String get teamManagementOperationsUniformLabel;

  /// No description provided for @teamManagementOperationsCompetitionTitle.
  ///
  /// In en, this message translates to:
  /// **'Competitions'**
  String get teamManagementOperationsCompetitionTitle;

  /// No description provided for @teamManagementOperationsNoCompetitions.
  ///
  /// In en, this message translates to:
  /// **'Create leagues or tournaments in competition management to show their status here.'**
  String get teamManagementOperationsNoCompetitions;

  /// No description provided for @teamManagementNewTeamButton.
  ///
  /// In en, this message translates to:
  /// **'New team'**
  String get teamManagementNewTeamButton;

  /// No description provided for @teamManagementBasicsTitle.
  ///
  /// In en, this message translates to:
  /// **'Team profile and principles'**
  String get teamManagementBasicsTitle;

  /// No description provided for @teamManagementBasicsHelper.
  ///
  /// In en, this message translates to:
  /// **'Set the team name and match principles the roster should share.'**
  String get teamManagementBasicsHelper;

  /// No description provided for @teamManagementTeamNameLabel.
  ///
  /// In en, this message translates to:
  /// **'Team name'**
  String get teamManagementTeamNameLabel;

  /// No description provided for @teamManagementTeamNameHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. Our U15'**
  String get teamManagementTeamNameHint;

  /// No description provided for @teamManagementStrategyLabel.
  ///
  /// In en, this message translates to:
  /// **'Tactical notes'**
  String get teamManagementStrategyLabel;

  /// No description provided for @teamManagementStrategyHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. Pressing trigger, wide switch rule, defensive block standard'**
  String get teamManagementStrategyHint;

  /// No description provided for @teamManagementFormationTitle.
  ///
  /// In en, this message translates to:
  /// **'Lineup / tactics board'**
  String get teamManagementFormationTitle;

  /// No description provided for @teamManagementFormationHelper.
  ///
  /// In en, this message translates to:
  /// **'Organize starting placement and tactical notes together. Drag player chips anywhere on the pitch, then use marker mode for movement lines or pressing directions.'**
  String get teamManagementFormationHelper;

  /// No description provided for @teamManagementFormationLabel.
  ///
  /// In en, this message translates to:
  /// **'Formation'**
  String get teamManagementFormationLabel;

  /// No description provided for @teamManagementFormationSpotLabel.
  ///
  /// In en, this message translates to:
  /// **'{spot}'**
  String teamManagementFormationSpotLabel(Object spot);

  /// No description provided for @teamManagementSelectPositionPrompt.
  ///
  /// In en, this message translates to:
  /// **'Select a position on the pitch.'**
  String get teamManagementSelectPositionPrompt;

  /// No description provided for @teamManagementSelectedPosition.
  ///
  /// In en, this message translates to:
  /// **'Assign {position}'**
  String teamManagementSelectedPosition(Object position);

  /// No description provided for @teamManagementAssignedPlayerLabel.
  ///
  /// In en, this message translates to:
  /// **'Assigned player'**
  String get teamManagementAssignedPlayerLabel;

  /// No description provided for @teamManagementUnassignedPlayer.
  ///
  /// In en, this message translates to:
  /// **'Unassigned'**
  String get teamManagementUnassignedPlayer;

  /// No description provided for @teamManagementPlayersTitle.
  ///
  /// In en, this message translates to:
  /// **'Roster'**
  String get teamManagementPlayersTitle;

  /// No description provided for @teamManagementPlayersHelper.
  ///
  /// In en, this message translates to:
  /// **'Manage number, position, preferred foot, condition, and notes as roster cards.'**
  String get teamManagementPlayersHelper;

  /// No description provided for @teamManagementPlayerNameLabel.
  ///
  /// In en, this message translates to:
  /// **'Player name'**
  String get teamManagementPlayerNameLabel;

  /// No description provided for @teamManagementPlayerNameHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. Minjun Kim'**
  String get teamManagementPlayerNameHint;

  /// No description provided for @teamManagementPlayerNumberLabel.
  ///
  /// In en, this message translates to:
  /// **'No.'**
  String get teamManagementPlayerNumberLabel;

  /// No description provided for @teamManagementPlayerNumberHint.
  ///
  /// In en, this message translates to:
  /// **'10'**
  String get teamManagementPlayerNumberHint;

  /// No description provided for @teamManagementPlayerRoleLabel.
  ///
  /// In en, this message translates to:
  /// **'Default position'**
  String get teamManagementPlayerRoleLabel;

  /// No description provided for @teamManagementPlayerFootLabel.
  ///
  /// In en, this message translates to:
  /// **'Preferred foot'**
  String get teamManagementPlayerFootLabel;

  /// No description provided for @teamManagementPlayerFootRight.
  ///
  /// In en, this message translates to:
  /// **'Right'**
  String get teamManagementPlayerFootRight;

  /// No description provided for @teamManagementPlayerFootLeft.
  ///
  /// In en, this message translates to:
  /// **'Left'**
  String get teamManagementPlayerFootLeft;

  /// No description provided for @teamManagementPlayerFootBoth.
  ///
  /// In en, this message translates to:
  /// **'Both'**
  String get teamManagementPlayerFootBoth;

  /// No description provided for @teamManagementPlayerConditionLabel.
  ///
  /// In en, this message translates to:
  /// **'Condition'**
  String get teamManagementPlayerConditionLabel;

  /// No description provided for @teamManagementPlayerConditionReady.
  ///
  /// In en, this message translates to:
  /// **'Ready'**
  String get teamManagementPlayerConditionReady;

  /// No description provided for @teamManagementPlayerConditionWatch.
  ///
  /// In en, this message translates to:
  /// **'Manage'**
  String get teamManagementPlayerConditionWatch;

  /// No description provided for @teamManagementPlayerConditionRest.
  ///
  /// In en, this message translates to:
  /// **'Rest advised'**
  String get teamManagementPlayerConditionRest;

  /// No description provided for @teamManagementPlayerNoteLabel.
  ///
  /// In en, this message translates to:
  /// **'Player note'**
  String get teamManagementPlayerNoteLabel;

  /// No description provided for @teamManagementPlayerNoteHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. Strong left foot, quick pressing transition, monitor knee load'**
  String get teamManagementPlayerNoteHint;

  /// No description provided for @teamManagementAddPlayerButton.
  ///
  /// In en, this message translates to:
  /// **'Add player'**
  String get teamManagementAddPlayerButton;

  /// No description provided for @teamManagementUpdatePlayerButton.
  ///
  /// In en, this message translates to:
  /// **'Save changes'**
  String get teamManagementUpdatePlayerButton;

  /// No description provided for @teamManagementCancelPlayerEditButton.
  ///
  /// In en, this message translates to:
  /// **'Cancel edit'**
  String get teamManagementCancelPlayerEditButton;

  /// No description provided for @teamManagementEditPlayerButton.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get teamManagementEditPlayerButton;

  /// No description provided for @teamManagementNoPlayersTitle.
  ///
  /// In en, this message translates to:
  /// **'No players registered.'**
  String get teamManagementNoPlayersTitle;

  /// No description provided for @teamManagementNoPlayersBody.
  ///
  /// In en, this message translates to:
  /// **'Add players to drag them directly onto the pitch board.'**
  String get teamManagementNoPlayersBody;

  /// No description provided for @teamManagementPlayerMeta.
  ///
  /// In en, this message translates to:
  /// **'{role} · {count} board placement(s)'**
  String teamManagementPlayerMeta(Object role, int count);

  /// No description provided for @teamManagementPlayerDetailMeta.
  ///
  /// In en, this message translates to:
  /// **'{role} · {foot} · {condition} · {count} placed'**
  String teamManagementPlayerDetailMeta(
      Object role, Object foot, Object condition, int count);

  /// No description provided for @teamManagementPlayerTrayTitle.
  ///
  /// In en, this message translates to:
  /// **'Players to drag'**
  String get teamManagementPlayerTrayTitle;

  /// No description provided for @teamManagementPlayerTrayEmpty.
  ///
  /// In en, this message translates to:
  /// **'Register players first, then drag them from here directly onto the pitch.'**
  String get teamManagementPlayerTrayEmpty;

  /// No description provided for @teamManagementBoardMovePlayersMode.
  ///
  /// In en, this message translates to:
  /// **'Place players'**
  String get teamManagementBoardMovePlayersMode;

  /// No description provided for @teamManagementBoardDrawMode.
  ///
  /// In en, this message translates to:
  /// **'Board marker'**
  String get teamManagementBoardDrawMode;

  /// No description provided for @teamManagementBoardClearLinesButton.
  ///
  /// In en, this message translates to:
  /// **'Clear lines'**
  String get teamManagementBoardClearLinesButton;

  /// No description provided for @teamManagementTacticLinesCount.
  ///
  /// In en, this message translates to:
  /// **'{count} movement line(s)'**
  String teamManagementTacticLinesCount(int count);

  /// No description provided for @teamManagementFormationDropHint.
  ///
  /// In en, this message translates to:
  /// **'Drop player chips anywhere on the pitch. The formation below is only a guide and does not need to be selected first.'**
  String get teamManagementFormationDropHint;

  /// No description provided for @teamManagementRemovePlayerButton.
  ///
  /// In en, this message translates to:
  /// **'Remove'**
  String get teamManagementRemovePlayerButton;

  /// No description provided for @teamManagementDeleteTeamButton.
  ///
  /// In en, this message translates to:
  /// **'Delete team'**
  String get teamManagementDeleteTeamButton;

  /// No description provided for @teamManagementSaveTeamButton.
  ///
  /// In en, this message translates to:
  /// **'Save team'**
  String get teamManagementSaveTeamButton;

  /// No description provided for @teamManagementSaveHint.
  ///
  /// In en, this message translates to:
  /// **'Your team roster, tactics, and board placement auto-save as you edit and appear in the Match Hub team card.'**
  String get teamManagementSaveHint;

  /// No description provided for @teamManagementAutoSaveReady.
  ///
  /// In en, this message translates to:
  /// **'Auto-save'**
  String get teamManagementAutoSaveReady;

  /// No description provided for @teamManagementAutoSavePending.
  ///
  /// In en, this message translates to:
  /// **'Pending'**
  String get teamManagementAutoSavePending;

  /// No description provided for @teamManagementAutoSaveSaving.
  ///
  /// In en, this message translates to:
  /// **'Saving'**
  String get teamManagementAutoSaveSaving;

  /// No description provided for @teamManagementAutoSaveSaved.
  ///
  /// In en, this message translates to:
  /// **'Saved'**
  String get teamManagementAutoSaveSaved;

  /// No description provided for @teamManagementAutoSaveNeedsName.
  ///
  /// In en, this message translates to:
  /// **'Name needed'**
  String get teamManagementAutoSaveNeedsName;

  /// No description provided for @teamManagementNameRequired.
  ///
  /// In en, this message translates to:
  /// **'Enter a team name.'**
  String get teamManagementNameRequired;

  /// No description provided for @teamManagementPlayerRequired.
  ///
  /// In en, this message translates to:
  /// **'Enter a player name.'**
  String get teamManagementPlayerRequired;

  /// No description provided for @teamManagementSavedFeedback.
  ///
  /// In en, this message translates to:
  /// **'Team details saved.'**
  String get teamManagementSavedFeedback;

  /// No description provided for @teamManagementDeletedFeedback.
  ///
  /// In en, this message translates to:
  /// **'Team deleted.'**
  String get teamManagementDeletedFeedback;

  /// No description provided for @teamManagementRoleGoalkeeper.
  ///
  /// In en, this message translates to:
  /// **'Goalkeeper'**
  String get teamManagementRoleGoalkeeper;

  /// No description provided for @teamManagementRoleDefender.
  ///
  /// In en, this message translates to:
  /// **'Defender'**
  String get teamManagementRoleDefender;

  /// No description provided for @teamManagementRoleMidfielder.
  ///
  /// In en, this message translates to:
  /// **'Midfielder'**
  String get teamManagementRoleMidfielder;

  /// No description provided for @teamManagementRoleForward.
  ///
  /// In en, this message translates to:
  /// **'Forward'**
  String get teamManagementRoleForward;

  /// No description provided for @teamManagementLineupFilled.
  ///
  /// In en, this message translates to:
  /// **'{filled}/{total} assigned'**
  String teamManagementLineupFilled(int filled, int total);

  /// No description provided for @teamManagementPlayerCount.
  ///
  /// In en, this message translates to:
  /// **'{count} player(s)'**
  String teamManagementPlayerCount(int count);

  /// No description provided for @baseballMatchHitsLabel.
  ///
  /// In en, this message translates to:
  /// **'Hits'**
  String get baseballMatchHitsLabel;

  /// No description provided for @baseballMatchRbisLabel.
  ///
  /// In en, this message translates to:
  /// **'RBIs'**
  String get baseballMatchRbisLabel;

  /// No description provided for @baseballMatchRunsLabel.
  ///
  /// In en, this message translates to:
  /// **'Runs'**
  String get baseballMatchRunsLabel;

  /// No description provided for @baseballMatchDefensivePlaysLabel.
  ///
  /// In en, this message translates to:
  /// **'Defensive plays'**
  String get baseballMatchDefensivePlaysLabel;

  /// No description provided for @basketballMatchPointsLabel.
  ///
  /// In en, this message translates to:
  /// **'Points'**
  String get basketballMatchPointsLabel;

  /// No description provided for @basketballMatchAssistsLabel.
  ///
  /// In en, this message translates to:
  /// **'Assists'**
  String get basketballMatchAssistsLabel;

  /// No description provided for @basketballMatchReboundsLabel.
  ///
  /// In en, this message translates to:
  /// **'Rebounds'**
  String get basketballMatchReboundsLabel;

  /// No description provided for @basketballMatchStealsLabel.
  ///
  /// In en, this message translates to:
  /// **'Steals'**
  String get basketballMatchStealsLabel;

  /// No description provided for @tennisMatchGamesWonLabel.
  ///
  /// In en, this message translates to:
  /// **'Games won'**
  String get tennisMatchGamesWonLabel;

  /// No description provided for @tennisMatchAcesLabel.
  ///
  /// In en, this message translates to:
  /// **'Aces'**
  String get tennisMatchAcesLabel;

  /// No description provided for @tennisMatchFirstServesInLabel.
  ///
  /// In en, this message translates to:
  /// **'First serves in'**
  String get tennisMatchFirstServesInLabel;

  /// No description provided for @tennisMatchBreakPointsWonLabel.
  ///
  /// In en, this message translates to:
  /// **'Break points won'**
  String get tennisMatchBreakPointsWonLabel;

  /// No description provided for @calendarMatchXpSourceLabel.
  ///
  /// In en, this message translates to:
  /// **'Match record'**
  String get calendarMatchXpSourceLabel;

  /// No description provided for @matchSavedFeedback.
  ///
  /// In en, this message translates to:
  /// **'Match record saved.'**
  String get matchSavedFeedback;

  /// No description provided for @matchUpdatedFeedback.
  ///
  /// In en, this message translates to:
  /// **'Match record updated.'**
  String get matchUpdatedFeedback;

  /// No description provided for @matchSavedWithXpFeedback.
  ///
  /// In en, this message translates to:
  /// **'Match saved +{count} XP'**
  String matchSavedWithXpFeedback(int count);

  /// No description provided for @trainingSketchControlsPanel.
  ///
  /// In en, this message translates to:
  /// **'Tools and selection'**
  String get trainingSketchControlsPanel;

  /// No description provided for @trainingSketchTacticalOverlay.
  ///
  /// In en, this message translates to:
  /// **'Show tactical zones'**
  String get trainingSketchTacticalOverlay;

  /// No description provided for @trainingSketchPlayTooltip.
  ///
  /// In en, this message translates to:
  /// **'Play'**
  String get trainingSketchPlayTooltip;

  /// No description provided for @trainingSketchPdfExportTooltip.
  ///
  /// In en, this message translates to:
  /// **'Download sketch PDF'**
  String get trainingSketchPdfExportTooltip;

  /// No description provided for @trainingSketchPdfExportedSnack.
  ///
  /// In en, this message translates to:
  /// **'Sketch PDF is ready.'**
  String get trainingSketchPdfExportedSnack;

  /// No description provided for @trainingSketchPdfExportFailedSnack.
  ///
  /// In en, this message translates to:
  /// **'Could not create the sketch PDF.'**
  String get trainingSketchPdfExportFailedSnack;

  /// No description provided for @trainingSketchLandscapeModeTooltip.
  ///
  /// In en, this message translates to:
  /// **'Landscape mode'**
  String get trainingSketchLandscapeModeTooltip;

  /// No description provided for @trainingSketchPortraitModeTooltip.
  ///
  /// In en, this message translates to:
  /// **'Portrait mode'**
  String get trainingSketchPortraitModeTooltip;

  /// No description provided for @trainingSketchPlaybackSpeedTooltip.
  ///
  /// In en, this message translates to:
  /// **'Playback speed'**
  String get trainingSketchPlaybackSpeedTooltip;

  /// No description provided for @trainingSketchAddSketchTooltip.
  ///
  /// In en, this message translates to:
  /// **'Add sketch'**
  String get trainingSketchAddSketchTooltip;

  /// No description provided for @trainingSketchCopySketchTooltip.
  ///
  /// In en, this message translates to:
  /// **'Copy from another sketch'**
  String get trainingSketchCopySketchTooltip;

  /// No description provided for @trainingSketchDeleteSketchTooltip.
  ///
  /// In en, this message translates to:
  /// **'Delete sketch'**
  String get trainingSketchDeleteSketchTooltip;

  /// No description provided for @trainingSketchImportSketchTooltip.
  ///
  /// In en, this message translates to:
  /// **'Import previous sketch'**
  String get trainingSketchImportSketchTooltip;

  /// No description provided for @trainingSketchRenameSketchTooltip.
  ///
  /// In en, this message translates to:
  /// **'Rename sketch'**
  String get trainingSketchRenameSketchTooltip;

  /// No description provided for @trainingSketchBoardNameLabel.
  ///
  /// In en, this message translates to:
  /// **'Board name'**
  String get trainingSketchBoardNameLabel;

  /// No description provided for @trainingSketchBoardNameHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. Pass warm-up'**
  String get trainingSketchBoardNameHint;

  /// No description provided for @trainingSketchMemoLabel.
  ///
  /// In en, this message translates to:
  /// **'Training sketch note'**
  String get trainingSketchMemoLabel;

  /// No description provided for @trainingSketchMemoHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. Two-touch dribble between cones then pass'**
  String get trainingSketchMemoHint;

  /// No description provided for @trainingSketchVoiceInputTooltip.
  ///
  /// In en, this message translates to:
  /// **'Voice input'**
  String get trainingSketchVoiceInputTooltip;

  /// No description provided for @trainingSketchConeButton.
  ///
  /// In en, this message translates to:
  /// **'Cone'**
  String get trainingSketchConeButton;

  /// No description provided for @trainingSketchLowHurdleButton.
  ///
  /// In en, this message translates to:
  /// **'Low hurdle'**
  String get trainingSketchLowHurdleButton;

  /// No description provided for @trainingSketchPlayerButton.
  ///
  /// In en, this message translates to:
  /// **'Player'**
  String get trainingSketchPlayerButton;

  /// No description provided for @trainingSketchBallButton.
  ///
  /// In en, this message translates to:
  /// **'Ball'**
  String get trainingSketchBallButton;

  /// No description provided for @trainingSketchLadderButton.
  ///
  /// In en, this message translates to:
  /// **'Ladder'**
  String get trainingSketchLadderButton;

  /// No description provided for @trainingSketchTargetButton.
  ///
  /// In en, this message translates to:
  /// **'Target'**
  String get trainingSketchTargetButton;

  /// No description provided for @trainingSketchBaseButton.
  ///
  /// In en, this message translates to:
  /// **'Base'**
  String get trainingSketchBaseButton;

  /// No description provided for @trainingSketchBasketButton.
  ///
  /// In en, this message translates to:
  /// **'Hoop'**
  String get trainingSketchBasketButton;

  /// No description provided for @trainingSketchPenButton.
  ///
  /// In en, this message translates to:
  /// **'Pen'**
  String get trainingSketchPenButton;

  /// No description provided for @trainingSketchAddElementMenuButton.
  ///
  /// In en, this message translates to:
  /// **'Add item'**
  String get trainingSketchAddElementMenuButton;

  /// No description provided for @trainingSketchClearInkButton.
  ///
  /// In en, this message translates to:
  /// **'Clear ink'**
  String get trainingSketchClearInkButton;

  /// No description provided for @trainingSketchResetButton.
  ///
  /// In en, this message translates to:
  /// **'Clear'**
  String get trainingSketchResetButton;

  /// No description provided for @trainingSketchPenModeHint.
  ///
  /// In en, this message translates to:
  /// **'Pen mode: drag on the board to draw.'**
  String get trainingSketchPenModeHint;

  /// No description provided for @trainingSketchPenColorLabel.
  ///
  /// In en, this message translates to:
  /// **'Pen color'**
  String get trainingSketchPenColorLabel;

  /// No description provided for @trainingSketchQuickStart.
  ///
  /// In en, this message translates to:
  /// **'Quick start: Select a player, tap an action, then tap the target player or space.'**
  String get trainingSketchQuickStart;

  /// No description provided for @trainingSketchNextActionButton.
  ///
  /// In en, this message translates to:
  /// **'Add next action'**
  String get trainingSketchNextActionButton;

  /// No description provided for @trainingSketchPlayerFlowTitle.
  ///
  /// In en, this message translates to:
  /// **'Player {index} flow'**
  String trainingSketchPlayerFlowTitle(int index);

  /// No description provided for @trainingSketchPlayerFlowWithBall.
  ///
  /// In en, this message translates to:
  /// **'Has ball'**
  String get trainingSketchPlayerFlowWithBall;

  /// No description provided for @trainingSketchPlayerFlowWithoutBall.
  ///
  /// In en, this message translates to:
  /// **'No ball'**
  String get trainingSketchPlayerFlowWithoutBall;

  /// No description provided for @trainingSketchPlayerFlowHint.
  ///
  /// In en, this message translates to:
  /// **'Choose the player\'s next action and the stage and ball movement will connect automatically.'**
  String get trainingSketchPlayerFlowHint;

  /// No description provided for @trainingSketchPlayerFlowPassSection.
  ///
  /// In en, this message translates to:
  /// **'Connect to teammate'**
  String get trainingSketchPlayerFlowPassSection;

  /// No description provided for @trainingSketchPlayerFlowBallSection.
  ///
  /// In en, this message translates to:
  /// **'Ball actions'**
  String get trainingSketchPlayerFlowBallSection;

  /// No description provided for @trainingSketchPlayerFlowMoveSection.
  ///
  /// In en, this message translates to:
  /// **'Movement'**
  String get trainingSketchPlayerFlowMoveSection;

  /// No description provided for @trainingSketchGlobalStagesTitle.
  ///
  /// In en, this message translates to:
  /// **'Overall stages'**
  String get trainingSketchGlobalStagesTitle;

  /// No description provided for @trainingSketchGlobalStagesHint.
  ///
  /// In en, this message translates to:
  /// **'Build the board as one sequence, and add several actions to the same stage when they should happen together.'**
  String get trainingSketchGlobalStagesHint;

  /// No description provided for @trainingSketchGlobalStagesEmpty.
  ///
  /// In en, this message translates to:
  /// **'No stages yet. The first action starts as stage 1.'**
  String get trainingSketchGlobalStagesEmpty;

  /// No description provided for @trainingSketchGlobalStageChip.
  ///
  /// In en, this message translates to:
  /// **'Stage {stage} · {count} actions'**
  String trainingSketchGlobalStageChip(int stage, int count);

  /// No description provided for @trainingSketchStageActionUnknownItem.
  ///
  /// In en, this message translates to:
  /// **'Item'**
  String get trainingSketchStageActionUnknownItem;

  /// No description provided for @trainingSketchStageActionPlayerMove.
  ///
  /// In en, this message translates to:
  /// **'{actor} moves'**
  String trainingSketchStageActionPlayerMove(Object actor);

  /// No description provided for @trainingSketchStageActionBallMove.
  ///
  /// In en, this message translates to:
  /// **'{actor} moves the ball'**
  String trainingSketchStageActionBallMove(Object actor);

  /// No description provided for @trainingSketchStageActionBallToTarget.
  ///
  /// In en, this message translates to:
  /// **'{actor} moves the ball to {target}'**
  String trainingSketchStageActionBallToTarget(Object actor, Object target);

  /// No description provided for @trainingSketchStageActionUnownedBallMove.
  ///
  /// In en, this message translates to:
  /// **'{ball} moves'**
  String trainingSketchStageActionUnownedBallMove(Object ball);

  /// No description provided for @trainingSketchAddSameStageButton.
  ///
  /// In en, this message translates to:
  /// **'Add together in stage {stage}'**
  String trainingSketchAddSameStageButton(int stage);

  /// No description provided for @trainingSketchAddNextStageButton.
  ///
  /// In en, this message translates to:
  /// **'Create new stage {stage}'**
  String trainingSketchAddNextStageButton(int stage);

  /// No description provided for @trainingSketchRegisteredNextGlobalStageHint.
  ///
  /// In en, this message translates to:
  /// **'Editing overall stage {stage}.'**
  String trainingSketchRegisteredNextGlobalStageHint(int stage);

  /// No description provided for @trainingSketchBallPossessionRequiredSnack.
  ///
  /// In en, this message translates to:
  /// **'{player} does not have the ball. Have them receive a pass first or select the ball they own.'**
  String trainingSketchBallPossessionRequiredSnack(Object player);

  /// No description provided for @trainingSketchBallOwnershipTitle.
  ///
  /// In en, this message translates to:
  /// **'Ball ownership'**
  String get trainingSketchBallOwnershipTitle;

  /// No description provided for @trainingSketchBallOwnedBy.
  ///
  /// In en, this message translates to:
  /// **'{ball}: owned by {player}'**
  String trainingSketchBallOwnedBy(Object ball, Object player);

  /// No description provided for @trainingSketchBallMovingToTarget.
  ///
  /// In en, this message translates to:
  /// **'{ball}: moving from {actor} to {target}'**
  String trainingSketchBallMovingToTarget(
      Object ball, Object actor, Object target);

  /// No description provided for @trainingSketchBallUnowned.
  ///
  /// In en, this message translates to:
  /// **'{ball}: no owner'**
  String trainingSketchBallUnowned(Object ball);

  /// No description provided for @trainingSketchSelectedItemTitle.
  ///
  /// In en, this message translates to:
  /// **'Selected item'**
  String get trainingSketchSelectedItemTitle;

  /// No description provided for @trainingSketchAssignColorLabel.
  ///
  /// In en, this message translates to:
  /// **'Assign color'**
  String get trainingSketchAssignColorLabel;

  /// No description provided for @trainingSketchPlayerStagesTitle.
  ///
  /// In en, this message translates to:
  /// **'Player stages'**
  String get trainingSketchPlayerStagesTitle;

  /// No description provided for @trainingSketchPlayerStagesEmpty.
  ///
  /// In en, this message translates to:
  /// **'No stages are registered for this player yet.'**
  String get trainingSketchPlayerStagesEmpty;

  /// No description provided for @trainingSketchPlayerStageChip.
  ///
  /// In en, this message translates to:
  /// **'Stage {stage} · {count} actions'**
  String trainingSketchPlayerStageChip(int stage, int count);

  /// No description provided for @trainingSketchRegisterNextPlayerStageButton.
  ///
  /// In en, this message translates to:
  /// **'Register stage {stage}'**
  String trainingSketchRegisterNextPlayerStageButton(int stage);

  /// No description provided for @trainingSketchRegisteredNextPlayerStageHint.
  ///
  /// In en, this message translates to:
  /// **'The next action will be created as stage {stage}.'**
  String trainingSketchRegisteredNextPlayerStageHint(int stage);

  /// No description provided for @trainingSketchDrawRouteFirst.
  ///
  /// In en, this message translates to:
  /// **'Draw or select a route first.'**
  String get trainingSketchDrawRouteFirst;

  /// No description provided for @trainingSketchAddPlayerFirst.
  ///
  /// In en, this message translates to:
  /// **'Add a player icon first.'**
  String get trainingSketchAddPlayerFirst;

  /// No description provided for @trainingSketchAddBallFirst.
  ///
  /// In en, this message translates to:
  /// **'Add a ball icon first.'**
  String get trainingSketchAddBallFirst;

  /// No description provided for @trainingSketchRoutesButton.
  ///
  /// In en, this message translates to:
  /// **'Actions'**
  String get trainingSketchRoutesButton;

  /// No description provided for @trainingSketchLinkRoutesInOrderButton.
  ///
  /// In en, this message translates to:
  /// **'Chain all in order'**
  String get trainingSketchLinkRoutesInOrderButton;

  /// No description provided for @trainingSketchLinkRoutesInOrderSnack.
  ///
  /// In en, this message translates to:
  /// **'Routes now start one by one in the order they were drawn.'**
  String get trainingSketchLinkRoutesInOrderSnack;

  /// No description provided for @trainingSketchLinkRoutesNeedTwoSnack.
  ///
  /// In en, this message translates to:
  /// **'Add at least two routes to chain them.'**
  String get trainingSketchLinkRoutesNeedTwoSnack;

  /// No description provided for @trainingSketchCreatedSnack.
  ///
  /// In en, this message translates to:
  /// **'Training sketch created.'**
  String get trainingSketchCreatedSnack;

  /// No description provided for @trainingSketchSavedSnack.
  ///
  /// In en, this message translates to:
  /// **'Training sketch saved.'**
  String get trainingSketchSavedSnack;

  /// No description provided for @trainingSketchPreviousCopiedSnack.
  ///
  /// In en, this message translates to:
  /// **'Previous sketch copied.'**
  String get trainingSketchPreviousCopiedSnack;

  /// No description provided for @trainingSketchDuplicatedSnack.
  ///
  /// In en, this message translates to:
  /// **'Sketch duplicated.'**
  String get trainingSketchDuplicatedSnack;

  /// No description provided for @trainingSketchCopiedFromAnotherSnack.
  ///
  /// In en, this message translates to:
  /// **'Sketch copied from another one.'**
  String get trainingSketchCopiedFromAnotherSnack;

  /// No description provided for @trainingBoardListTitle.
  ///
  /// In en, this message translates to:
  /// **'Training sketch list'**
  String get trainingBoardListTitle;

  /// No description provided for @trainingBoardTitleDialogTitle.
  ///
  /// In en, this message translates to:
  /// **'Training sketch title'**
  String get trainingBoardTitleDialogTitle;

  /// No description provided for @trainingBoardTitleHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. Pass warm-up'**
  String get trainingBoardTitleHint;

  /// No description provided for @trainingBoardRenamedSnack.
  ///
  /// In en, this message translates to:
  /// **'Board renamed.'**
  String get trainingBoardRenamedSnack;

  /// No description provided for @trainingBoardRenameUndoneSnack.
  ///
  /// In en, this message translates to:
  /// **'Rename undone.'**
  String get trainingBoardRenameUndoneSnack;

  /// No description provided for @trainingBoardNoCopySourceSnack.
  ///
  /// In en, this message translates to:
  /// **'No training sketch to copy.'**
  String get trainingBoardNoCopySourceSnack;

  /// No description provided for @trainingBoardDefaultCopyTitle.
  ///
  /// In en, this message translates to:
  /// **'{title} Copy'**
  String trainingBoardDefaultCopyTitle(Object title);

  /// No description provided for @trainingBoardDeleteTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete training sketch'**
  String get trainingBoardDeleteTitle;

  /// No description provided for @trainingBoardDeleteConfirm.
  ///
  /// In en, this message translates to:
  /// **'Delete \"{title}\"?'**
  String trainingBoardDeleteConfirm(Object title);

  /// No description provided for @trainingBoardDeletedSnack.
  ///
  /// In en, this message translates to:
  /// **'Board deleted.'**
  String get trainingBoardDeletedSnack;

  /// No description provided for @trainingBoardDeleteUndoneSnack.
  ///
  /// In en, this message translates to:
  /// **'Delete undone.'**
  String get trainingBoardDeleteUndoneSnack;

  /// No description provided for @trainingBoardDefaultTitle.
  ///
  /// In en, this message translates to:
  /// **'Training Board'**
  String get trainingBoardDefaultTitle;

  /// No description provided for @trainingBoardSearchCloseTooltip.
  ///
  /// In en, this message translates to:
  /// **'Close search'**
  String get trainingBoardSearchCloseTooltip;

  /// No description provided for @trainingBoardSearchTooltip.
  ///
  /// In en, this message translates to:
  /// **'Search boards'**
  String get trainingBoardSearchTooltip;

  /// No description provided for @trainingBoardSortTooltip.
  ///
  /// In en, this message translates to:
  /// **'Sort'**
  String get trainingBoardSortTooltip;

  /// No description provided for @trainingBoardSortRecentlyUpdated.
  ///
  /// In en, this message translates to:
  /// **'Recently updated'**
  String get trainingBoardSortRecentlyUpdated;

  /// No description provided for @trainingBoardSortTrainingDate.
  ///
  /// In en, this message translates to:
  /// **'Training date'**
  String get trainingBoardSortTrainingDate;

  /// No description provided for @trainingBoardSortName.
  ///
  /// In en, this message translates to:
  /// **'Name A-Z'**
  String get trainingBoardSortName;

  /// No description provided for @trainingBoardAddTooltip.
  ///
  /// In en, this message translates to:
  /// **'Add training sketch'**
  String get trainingBoardAddTooltip;

  /// No description provided for @trainingBoardCreateNewAction.
  ///
  /// In en, this message translates to:
  /// **'Create new sketch'**
  String get trainingBoardCreateNewAction;

  /// No description provided for @trainingBoardCopyPreviousAction.
  ///
  /// In en, this message translates to:
  /// **'Copy previous sketch'**
  String get trainingBoardCopyPreviousAction;

  /// No description provided for @trainingBoardDoneAction.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get trainingBoardDoneAction;

  /// No description provided for @trainingBoardEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'No boards yet.'**
  String get trainingBoardEmptyTitle;

  /// No description provided for @trainingBoardEmptySubtitle.
  ///
  /// In en, this message translates to:
  /// **'Create one directly from a training note.'**
  String get trainingBoardEmptySubtitle;

  /// No description provided for @trainingBoardBackToNotes.
  ///
  /// In en, this message translates to:
  /// **'Back to notes'**
  String get trainingBoardBackToNotes;

  /// No description provided for @trainingBoardSearchHint.
  ///
  /// In en, this message translates to:
  /// **'Search board'**
  String get trainingBoardSearchHint;

  /// No description provided for @trainingBoardNoSearchResults.
  ///
  /// In en, this message translates to:
  /// **'No search results.'**
  String get trainingBoardNoSearchResults;

  /// No description provided for @trainingBoardListItemSubtitle.
  ///
  /// In en, this message translates to:
  /// **'{count} items · Training date {date}'**
  String trainingBoardListItemSubtitle(Object count, Object date);

  /// No description provided for @trainingBoardRenameAction.
  ///
  /// In en, this message translates to:
  /// **'Rename'**
  String get trainingBoardRenameAction;

  /// No description provided for @trainingBoardDuplicateAction.
  ///
  /// In en, this message translates to:
  /// **'Duplicate'**
  String get trainingBoardDuplicateAction;

  /// No description provided for @trainingSketchAutoStagesButton.
  ///
  /// In en, this message translates to:
  /// **'Auto stages'**
  String get trainingSketchAutoStagesButton;

  /// No description provided for @trainingSketchAutoStagesSnack.
  ///
  /// In en, this message translates to:
  /// **'Routes were split into stages starting from stage 1.'**
  String get trainingSketchAutoStagesSnack;

  /// No description provided for @trainingSketchAutoStagesNeedTwoSnack.
  ///
  /// In en, this message translates to:
  /// **'Add at least two routes to split stages.'**
  String get trainingSketchAutoStagesNeedTwoSnack;

  /// No description provided for @trainingSketchRouteStageTitle.
  ///
  /// In en, this message translates to:
  /// **'Movement stage'**
  String get trainingSketchRouteStageTitle;

  /// No description provided for @trainingSketchRouteStageChip.
  ///
  /// In en, this message translates to:
  /// **'Stage {stage}'**
  String trainingSketchRouteStageChip(Object stage);

  /// No description provided for @trainingSketchSelectRouteForStageHint.
  ///
  /// In en, this message translates to:
  /// **'Select a player or ball to change its route stage.'**
  String get trainingSketchSelectRouteForStageHint;

  /// No description provided for @trainingSketchPreviousStageButton.
  ///
  /// In en, this message translates to:
  /// **'Previous stage'**
  String get trainingSketchPreviousStageButton;

  /// No description provided for @trainingSketchNextStageButton.
  ///
  /// In en, this message translates to:
  /// **'Next stage'**
  String get trainingSketchNextStageButton;

  /// No description provided for @trainingSketchRouteAfterBallButton.
  ///
  /// In en, this message translates to:
  /// **'After ball'**
  String get trainingSketchRouteAfterBallButton;

  /// No description provided for @trainingSketchFinishRouteButton.
  ///
  /// In en, this message translates to:
  /// **'Finish route'**
  String get trainingSketchFinishRouteButton;

  /// No description provided for @trainingSketchUndoLastRoutePointButton.
  ///
  /// In en, this message translates to:
  /// **'Undo last point'**
  String get trainingSketchUndoLastRoutePointButton;

  /// No description provided for @trainingSketchClearAllRoutesButton.
  ///
  /// In en, this message translates to:
  /// **'Clear all action lines'**
  String get trainingSketchClearAllRoutesButton;

  /// No description provided for @trainingSketchPlayerRoutesTitle.
  ///
  /// In en, this message translates to:
  /// **'Player actions'**
  String get trainingSketchPlayerRoutesTitle;

  /// No description provided for @trainingSketchBallRoutesTitle.
  ///
  /// In en, this message translates to:
  /// **'Ball actions'**
  String get trainingSketchBallRoutesTitle;

  /// No description provided for @trainingSketchRoutesEmpty.
  ///
  /// In en, this message translates to:
  /// **'No action lines yet for this type.'**
  String get trainingSketchRoutesEmpty;

  /// No description provided for @trainingSketchExtendRouteButton.
  ///
  /// In en, this message translates to:
  /// **'Extend from end'**
  String get trainingSketchExtendRouteButton;

  /// No description provided for @trainingSketchReverseRouteButton.
  ///
  /// In en, this message translates to:
  /// **'Reverse direction'**
  String get trainingSketchReverseRouteButton;

  /// No description provided for @trainingSketchRedrawRouteButton.
  ///
  /// In en, this message translates to:
  /// **'Redraw selected'**
  String get trainingSketchRedrawRouteButton;

  /// No description provided for @trainingSketchDeleteRouteButton.
  ///
  /// In en, this message translates to:
  /// **'Delete selected'**
  String get trainingSketchDeleteRouteButton;

  /// No description provided for @trainingSketchPlayerRouteChip.
  ///
  /// In en, this message translates to:
  /// **'Player {index}'**
  String trainingSketchPlayerRouteChip(int index);

  /// No description provided for @trainingSketchBallRouteChip.
  ///
  /// In en, this message translates to:
  /// **'Ball {index}'**
  String trainingSketchBallRouteChip(int index);

  /// No description provided for @trainingSketchRouteReplaceHint.
  ///
  /// In en, this message translates to:
  /// **'Tap the destination, then finish the route to replace the selected route.'**
  String get trainingSketchRouteReplaceHint;

  /// No description provided for @trainingSketchSelectedPlayerRouteHint.
  ///
  /// In en, this message translates to:
  /// **'Tap a destination, then finish the route. You can still drag to draw.'**
  String get trainingSketchSelectedPlayerRouteHint;

  /// No description provided for @trainingSketchSelectedBallRouteHint.
  ///
  /// In en, this message translates to:
  /// **'Tap a pass destination, then finish the route. You can still drag to draw.'**
  String get trainingSketchSelectedBallRouteHint;

  /// No description provided for @trainingSketchPlayerRouteHint.
  ///
  /// In en, this message translates to:
  /// **'Select a player or tap the board to start, then tap a destination and finish.'**
  String get trainingSketchPlayerRouteHint;

  /// No description provided for @trainingSketchBallRouteHint.
  ///
  /// In en, this message translates to:
  /// **'Select a ball or tap the board to start, then tap a pass destination and finish.'**
  String get trainingSketchBallRouteHint;

  /// No description provided for @trainingSketchLinkPlayerHint.
  ///
  /// In en, this message translates to:
  /// **'Tap an action, then tap a destination or target player. Actions that need a ball create one beside the player automatically.'**
  String get trainingSketchLinkPlayerHint;

  /// No description provided for @trainingSketchLinkBallHint.
  ///
  /// In en, this message translates to:
  /// **'Use this only when you want to move the ball by itself. Player actions create the needed ball movement together.'**
  String get trainingSketchLinkBallHint;

  /// No description provided for @trainingSketchActionTargetHint.
  ///
  /// In en, this message translates to:
  /// **'Tap the target or space for {action}.'**
  String trainingSketchActionTargetHint(Object action);

  /// No description provided for @trainingSketchActionTargetCancelButton.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get trainingSketchActionTargetCancelButton;

  /// No description provided for @trainingSketchSelectedItemActionsTitle.
  ///
  /// In en, this message translates to:
  /// **'Quick actions'**
  String get trainingSketchSelectedItemActionsTitle;

  /// No description provided for @trainingSketchPlayerActionsTitle.
  ///
  /// In en, this message translates to:
  /// **'Player actions'**
  String get trainingSketchPlayerActionsTitle;

  /// No description provided for @trainingSketchBallActionsTitle.
  ///
  /// In en, this message translates to:
  /// **'Ball actions'**
  String get trainingSketchBallActionsTitle;

  /// No description provided for @trainingSketchCreateMoveRouteButton.
  ///
  /// In en, this message translates to:
  /// **'Create move'**
  String get trainingSketchCreateMoveRouteButton;

  /// No description provided for @trainingSketchCreatePassRouteButton.
  ///
  /// In en, this message translates to:
  /// **'Create pass'**
  String get trainingSketchCreatePassRouteButton;

  /// No description provided for @trainingSketchQuickMoveButton.
  ///
  /// In en, this message translates to:
  /// **'Move'**
  String get trainingSketchQuickMoveButton;

  /// No description provided for @trainingSketchQuickPassButton.
  ///
  /// In en, this message translates to:
  /// **'Pass'**
  String get trainingSketchQuickPassButton;

  /// No description provided for @trainingSketchQuickPassAndMoveButton.
  ///
  /// In en, this message translates to:
  /// **'Pass then move'**
  String get trainingSketchQuickPassAndMoveButton;

  /// No description provided for @trainingSketchQuickDribbleButton.
  ///
  /// In en, this message translates to:
  /// **'Dribble'**
  String get trainingSketchQuickDribbleButton;

  /// No description provided for @trainingSketchQuickReceiveMoveButton.
  ///
  /// In en, this message translates to:
  /// **'Receive and move'**
  String get trainingSketchQuickReceiveMoveButton;

  /// No description provided for @trainingSketchQuickReturnMoveButton.
  ///
  /// In en, this message translates to:
  /// **'Return'**
  String get trainingSketchQuickReturnMoveButton;

  /// No description provided for @trainingSketchQuickOverlapButton.
  ///
  /// In en, this message translates to:
  /// **'Overlap'**
  String get trainingSketchQuickOverlapButton;

  /// No description provided for @trainingSketchQuickShotButton.
  ///
  /// In en, this message translates to:
  /// **'Shoot'**
  String get trainingSketchQuickShotButton;

  /// No description provided for @trainingSketchQuickCrossButton.
  ///
  /// In en, this message translates to:
  /// **'Cross'**
  String get trainingSketchQuickCrossButton;

  /// No description provided for @trainingSketchQuickDriveButton.
  ///
  /// In en, this message translates to:
  /// **'Drive'**
  String get trainingSketchQuickDriveButton;

  /// No description provided for @trainingSketchQuickCutButton.
  ///
  /// In en, this message translates to:
  /// **'Cut'**
  String get trainingSketchQuickCutButton;

  /// No description provided for @trainingSketchQuickScreenButton.
  ///
  /// In en, this message translates to:
  /// **'Screen'**
  String get trainingSketchQuickScreenButton;

  /// No description provided for @trainingSketchQuickConeTurnButton.
  ///
  /// In en, this message translates to:
  /// **'Circle cone'**
  String get trainingSketchQuickConeTurnButton;

  /// No description provided for @trainingSketchQuickConeJumpButton.
  ///
  /// In en, this message translates to:
  /// **'Jump cone'**
  String get trainingSketchQuickConeJumpButton;

  /// No description provided for @trainingSketchQuickHurdleJumpButton.
  ///
  /// In en, this message translates to:
  /// **'Jump hurdle'**
  String get trainingSketchQuickHurdleJumpButton;

  /// No description provided for @trainingSketchQuickRunBaseButton.
  ///
  /// In en, this message translates to:
  /// **'Base run'**
  String get trainingSketchQuickRunBaseButton;

  /// No description provided for @trainingSketchQuickFieldingButton.
  ///
  /// In en, this message translates to:
  /// **'Fielding move'**
  String get trainingSketchQuickFieldingButton;

  /// No description provided for @trainingSketchQuickThrowButton.
  ///
  /// In en, this message translates to:
  /// **'Throw'**
  String get trainingSketchQuickThrowButton;

  /// No description provided for @trainingSketchQuickServeButton.
  ///
  /// In en, this message translates to:
  /// **'Serve'**
  String get trainingSketchQuickServeButton;

  /// No description provided for @trainingSketchQuickRallyButton.
  ///
  /// In en, this message translates to:
  /// **'Rally'**
  String get trainingSketchQuickRallyButton;

  /// No description provided for @trainingSketchQuickRecoverButton.
  ///
  /// In en, this message translates to:
  /// **'Recover'**
  String get trainingSketchQuickRecoverButton;

  /// No description provided for @trainingSketchPassToPlayerButton.
  ///
  /// In en, this message translates to:
  /// **'Pass to player {index}'**
  String trainingSketchPassToPlayerButton(int index);

  /// No description provided for @trainingSketchPassToNewPlayerButton.
  ///
  /// In en, this message translates to:
  /// **'Pass to new player'**
  String get trainingSketchPassToNewPlayerButton;

  /// No description provided for @trainingSketchPassToSpotButton.
  ///
  /// In en, this message translates to:
  /// **'Pass to {target} {index}'**
  String trainingSketchPassToSpotButton(Object target, int index);

  /// No description provided for @trainingSketchThrowToPlayerButton.
  ///
  /// In en, this message translates to:
  /// **'Throw to player {index}'**
  String trainingSketchThrowToPlayerButton(int index);

  /// No description provided for @trainingSketchThrowToNewPlayerButton.
  ///
  /// In en, this message translates to:
  /// **'Throw to new player'**
  String get trainingSketchThrowToNewPlayerButton;

  /// No description provided for @trainingSketchThrowToSpotButton.
  ///
  /// In en, this message translates to:
  /// **'Throw to {target} {index}'**
  String trainingSketchThrowToSpotButton(Object target, int index);

  /// No description provided for @trainingSketchRallyToPlayerButton.
  ///
  /// In en, this message translates to:
  /// **'Rally to player {index}'**
  String trainingSketchRallyToPlayerButton(int index);

  /// No description provided for @trainingSketchRallyToNewPlayerButton.
  ///
  /// In en, this message translates to:
  /// **'Rally to new player'**
  String get trainingSketchRallyToNewPlayerButton;

  /// No description provided for @trainingSketchRallyToSpotButton.
  ///
  /// In en, this message translates to:
  /// **'Rally to {target} {index}'**
  String trainingSketchRallyToSpotButton(Object target, int index);

  /// No description provided for @trainingSketchPlayerRouteLimitReached.
  ///
  /// In en, this message translates to:
  /// **'All player action lines are already assigned. Select a player to replace or redraw its action.'**
  String get trainingSketchPlayerRouteLimitReached;

  /// No description provided for @trainingSketchBallRouteLimitReached.
  ///
  /// In en, this message translates to:
  /// **'All ball action lines are already assigned. Select a ball to replace or redraw its action.'**
  String get trainingSketchBallRouteLimitReached;

  /// No description provided for @trainingSketchTemplatePickerTitle.
  ///
  /// In en, this message translates to:
  /// **'Choose template'**
  String get trainingSketchTemplatePickerTitle;

  /// No description provided for @trainingSketchTemplateBlankLabel.
  ///
  /// In en, this message translates to:
  /// **'Blank sketch'**
  String get trainingSketchTemplateBlankLabel;

  /// No description provided for @trainingSketchTemplateBlankDescription.
  ///
  /// In en, this message translates to:
  /// **'Start from an empty board'**
  String get trainingSketchTemplateBlankDescription;

  /// No description provided for @trainingSketchTemplatePassWarmupLabel.
  ///
  /// In en, this message translates to:
  /// **'Pass and move triangle'**
  String get trainingSketchTemplatePassWarmupLabel;

  /// No description provided for @trainingSketchTemplatePassWarmupDescription.
  ///
  /// In en, this message translates to:
  /// **'Pass, support, and rotate'**
  String get trainingSketchTemplatePassWarmupDescription;

  /// No description provided for @trainingSketchTemplatePassWarmupMethod.
  ///
  /// In en, this message translates to:
  /// **'Open the body before receiving and move after every pass'**
  String get trainingSketchTemplatePassWarmupMethod;

  /// No description provided for @trainingSketchTemplateBuildUpLabel.
  ///
  /// In en, this message translates to:
  /// **'Build-out escape'**
  String get trainingSketchTemplateBuildUpLabel;

  /// No description provided for @trainingSketchTemplateBuildUpDescription.
  ///
  /// In en, this message translates to:
  /// **'Goalkeeper, center backs, and the 6'**
  String get trainingSketchTemplateBuildUpDescription;

  /// No description provided for @trainingSketchTemplateBuildUpMethod.
  ///
  /// In en, this message translates to:
  /// **'Draw pressure, find the 6, then release to the far fullback'**
  String get trainingSketchTemplateBuildUpMethod;

  /// No description provided for @trainingSketchTemplatePressingLabel.
  ///
  /// In en, this message translates to:
  /// **'5-second counterpress'**
  String get trainingSketchTemplatePressingLabel;

  /// No description provided for @trainingSketchTemplatePressingDescription.
  ///
  /// In en, this message translates to:
  /// **'Immediate pressure and cover after loss'**
  String get trainingSketchTemplatePressingDescription;

  /// No description provided for @trainingSketchTemplatePressingMethod.
  ///
  /// In en, this message translates to:
  /// **'Nearest player presses while support players block passing lanes'**
  String get trainingSketchTemplatePressingMethod;

  /// No description provided for @trainingSketchTemplateSetPieceLabel.
  ///
  /// In en, this message translates to:
  /// **'Near-far corner'**
  String get trainingSketchTemplateSetPieceLabel;

  /// No description provided for @trainingSketchTemplateSetPieceDescription.
  ///
  /// In en, this message translates to:
  /// **'Screen, near touch, far-post run'**
  String get trainingSketchTemplateSetPieceDescription;

  /// No description provided for @trainingSketchTemplateSetPieceMethod.
  ///
  /// In en, this message translates to:
  /// **'Use the blocker, flick near-post, then attack the far post'**
  String get trainingSketchTemplateSetPieceMethod;

  /// No description provided for @trainingSketchTemplateRondoLabel.
  ///
  /// In en, this message translates to:
  /// **'5v2 rondo switch'**
  String get trainingSketchTemplateRondoLabel;

  /// No description provided for @trainingSketchTemplateRondoDescription.
  ///
  /// In en, this message translates to:
  /// **'Split pass and support rotation with a joker'**
  String get trainingSketchTemplateRondoDescription;

  /// No description provided for @trainingSketchTemplateRondoMethod.
  ///
  /// In en, this message translates to:
  /// **'Break the pressure line, then rotate the support positions'**
  String get trainingSketchTemplateRondoMethod;

  /// No description provided for @trainingSketchTemplateFinishingLabel.
  ///
  /// In en, this message translates to:
  /// **'Cutback finishing'**
  String get trainingSketchTemplateFinishingLabel;

  /// No description provided for @trainingSketchTemplateFinishingDescription.
  ///
  /// In en, this message translates to:
  /// **'Wide drive, cutback, box arrivals'**
  String get trainingSketchTemplateFinishingDescription;

  /// No description provided for @trainingSketchTemplateFinishingMethod.
  ///
  /// In en, this message translates to:
  /// **'Attack near post, cutback zone, and far post at the same time'**
  String get trainingSketchTemplateFinishingMethod;

  /// No description provided for @trainingSketchTemplateWingCombinationLabel.
  ///
  /// In en, this message translates to:
  /// **'Overlap and underlap'**
  String get trainingSketchTemplateWingCombinationLabel;

  /// No description provided for @trainingSketchTemplateWingCombinationDescription.
  ///
  /// In en, this message translates to:
  /// **'Wide overload with fullback, winger, and 8'**
  String get trainingSketchTemplateWingCombinationDescription;

  /// No description provided for @trainingSketchTemplateWingCombinationMethod.
  ///
  /// In en, this message translates to:
  /// **'Pin inside with the winger, then overlap or underlap for a cutback'**
  String get trainingSketchTemplateWingCombinationMethod;

  /// No description provided for @trainingSketchTemplateTransitionAttackLabel.
  ///
  /// In en, this message translates to:
  /// **'6-second counterattack'**
  String get trainingSketchTemplateTransitionAttackLabel;

  /// No description provided for @trainingSketchTemplateTransitionAttackDescription.
  ///
  /// In en, this message translates to:
  /// **'First pass, depth run, and wide carry'**
  String get trainingSketchTemplateTransitionAttackDescription;

  /// No description provided for @trainingSketchTemplateTransitionAttackMethod.
  ///
  /// In en, this message translates to:
  /// **'Use the first forward pass before the defense can reset'**
  String get trainingSketchTemplateTransitionAttackMethod;

  /// No description provided for @trainingSketchTemplateSwitchPlayLabel.
  ///
  /// In en, this message translates to:
  /// **'Switch of play'**
  String get trainingSketchTemplateSwitchPlayLabel;

  /// No description provided for @trainingSketchTemplateSwitchPlayDescription.
  ///
  /// In en, this message translates to:
  /// **'Draw pressure, then switch to the far winger'**
  String get trainingSketchTemplateSwitchPlayDescription;

  /// No description provided for @trainingSketchTemplateSwitchPlayMethod.
  ///
  /// In en, this message translates to:
  /// **'Attract pressure on one side, then use the 6 and center back to switch'**
  String get trainingSketchTemplateSwitchPlayMethod;

  /// No description provided for @trainingSketchTemplateDefensiveShiftLabel.
  ///
  /// In en, this message translates to:
  /// **'Defensive line shift'**
  String get trainingSketchTemplateDefensiveShiftLabel;

  /// No description provided for @trainingSketchTemplateDefensiveShiftDescription.
  ///
  /// In en, this message translates to:
  /// **'Line slide and cover as the ball moves'**
  String get trainingSketchTemplateDefensiveShiftDescription;

  /// No description provided for @trainingSketchTemplateDefensiveShiftMethod.
  ///
  /// In en, this message translates to:
  /// **'When the ball switches sides, the back four and 6 move together'**
  String get trainingSketchTemplateDefensiveShiftMethod;

  /// No description provided for @trainingSketchTemplateBaseballThrowingLabel.
  ///
  /// In en, this message translates to:
  /// **'Throwing relay'**
  String get trainingSketchTemplateBaseballThrowingLabel;

  /// No description provided for @trainingSketchTemplateBaseballThrowingDescription.
  ///
  /// In en, this message translates to:
  /// **'Basic catch-and-throw connection'**
  String get trainingSketchTemplateBaseballThrowingDescription;

  /// No description provided for @trainingSketchTemplateBaseballThrowingMethod.
  ///
  /// In en, this message translates to:
  /// **'Receive cleanly and throw quickly to the target'**
  String get trainingSketchTemplateBaseballThrowingMethod;

  /// No description provided for @trainingSketchTemplateBaseballBattingLabel.
  ///
  /// In en, this message translates to:
  /// **'Hit and run'**
  String get trainingSketchTemplateBaseballBattingLabel;

  /// No description provided for @trainingSketchTemplateBaseballBattingDescription.
  ///
  /// In en, this message translates to:
  /// **'Batting direction and first-base run'**
  String get trainingSketchTemplateBaseballBattingDescription;

  /// No description provided for @trainingSketchTemplateBaseballBattingMethod.
  ///
  /// In en, this message translates to:
  /// **'Check contact direction, then sprint through first base'**
  String get trainingSketchTemplateBaseballBattingMethod;

  /// No description provided for @trainingSketchTemplateBaseballFieldingLabel.
  ///
  /// In en, this message translates to:
  /// **'Fielding play'**
  String get trainingSketchTemplateBaseballFieldingLabel;

  /// No description provided for @trainingSketchTemplateBaseballFieldingDescription.
  ///
  /// In en, this message translates to:
  /// **'Batted-ball reaction and relay throw'**
  String get trainingSketchTemplateBaseballFieldingDescription;

  /// No description provided for @trainingSketchTemplateBaseballFieldingMethod.
  ///
  /// In en, this message translates to:
  /// **'React, field the ball, and throw accurately to the relay spot'**
  String get trainingSketchTemplateBaseballFieldingMethod;

  /// No description provided for @trainingSketchTemplateBasketballShootingLabel.
  ///
  /// In en, this message translates to:
  /// **'Shooting spots'**
  String get trainingSketchTemplateBasketballShootingLabel;

  /// No description provided for @trainingSketchTemplateBasketballShootingDescription.
  ///
  /// In en, this message translates to:
  /// **'Drive path and shot locations'**
  String get trainingSketchTemplateBasketballShootingDescription;

  /// No description provided for @trainingSketchTemplateBasketballShootingMethod.
  ///
  /// In en, this message translates to:
  /// **'Catch, set the feet, and shoot from the assigned spot'**
  String get trainingSketchTemplateBasketballShootingMethod;

  /// No description provided for @trainingSketchTemplateBasketballPassingLabel.
  ///
  /// In en, this message translates to:
  /// **'Pass and cut'**
  String get trainingSketchTemplateBasketballPassingLabel;

  /// No description provided for @trainingSketchTemplateBasketballPassingDescription.
  ///
  /// In en, this message translates to:
  /// **'Cut timing and pass connection'**
  String get trainingSketchTemplateBasketballPassingDescription;

  /// No description provided for @trainingSketchTemplateBasketballPassingMethod.
  ///
  /// In en, this message translates to:
  /// **'Time the pass with the cutter\'s movement'**
  String get trainingSketchTemplateBasketballPassingMethod;

  /// No description provided for @trainingSketchTemplateBasketballDefenseLabel.
  ///
  /// In en, this message translates to:
  /// **'Defensive slides'**
  String get trainingSketchTemplateBasketballDefenseLabel;

  /// No description provided for @trainingSketchTemplateBasketballDefenseDescription.
  ///
  /// In en, this message translates to:
  /// **'Lateral slide and pressure positions'**
  String get trainingSketchTemplateBasketballDefenseDescription;

  /// No description provided for @trainingSketchTemplateBasketballDefenseMethod.
  ///
  /// In en, this message translates to:
  /// **'Stay in front and repeat controlled lateral slides'**
  String get trainingSketchTemplateBasketballDefenseMethod;

  /// No description provided for @trainingSketchTemplateTennisServeLabel.
  ///
  /// In en, this message translates to:
  /// **'Serve targets'**
  String get trainingSketchTemplateTennisServeLabel;

  /// No description provided for @trainingSketchTemplateTennisServeDescription.
  ///
  /// In en, this message translates to:
  /// **'Serve direction and recovery position'**
  String get trainingSketchTemplateTennisServeDescription;

  /// No description provided for @trainingSketchTemplateTennisServeMethod.
  ///
  /// In en, this message translates to:
  /// **'Serve to the target, then recover to the middle'**
  String get trainingSketchTemplateTennisServeMethod;

  /// No description provided for @trainingSketchTemplateTennisRallyLabel.
  ///
  /// In en, this message translates to:
  /// **'Cross-court rally'**
  String get trainingSketchTemplateTennisRallyLabel;

  /// No description provided for @trainingSketchTemplateTennisRallyDescription.
  ///
  /// In en, this message translates to:
  /// **'Cross-court rally and recovery'**
  String get trainingSketchTemplateTennisRallyDescription;

  /// No description provided for @trainingSketchTemplateTennisRallyMethod.
  ///
  /// In en, this message translates to:
  /// **'Send cross-court and recover to center for the next ball'**
  String get trainingSketchTemplateTennisRallyMethod;

  /// No description provided for @trainingSketchTemplateTennisFootworkLabel.
  ///
  /// In en, this message translates to:
  /// **'Footwork pattern'**
  String get trainingSketchTemplateTennisFootworkLabel;

  /// No description provided for @trainingSketchTemplateTennisFootworkDescription.
  ///
  /// In en, this message translates to:
  /// **'Split step and side-to-side movement'**
  String get trainingSketchTemplateTennisFootworkDescription;

  /// No description provided for @trainingSketchTemplateTennisFootworkMethod.
  ///
  /// In en, this message translates to:
  /// **'Split step, move side to side, and recover balance'**
  String get trainingSketchTemplateTennisFootworkMethod;

  /// No description provided for @trainingSketchTemplateGalleryAction.
  ///
  /// In en, this message translates to:
  /// **'View templates'**
  String get trainingSketchTemplateGalleryAction;

  /// No description provided for @trainingSketchTemplateGalleryTitle.
  ///
  /// In en, this message translates to:
  /// **'Training template gallery'**
  String get trainingSketchTemplateGalleryTitle;

  /// No description provided for @trainingSketchTemplateGallerySubtitle.
  ///
  /// In en, this message translates to:
  /// **'Preview movement lines and notes before creating a sketch.'**
  String get trainingSketchTemplateGallerySubtitle;

  /// No description provided for @challengeTitle.
  ///
  /// In en, this message translates to:
  /// **'Challenge'**
  String get challengeTitle;

  /// No description provided for @challengeRewardAction.
  ///
  /// In en, this message translates to:
  /// **'Rewards'**
  String get challengeRewardAction;

  /// No description provided for @challengeHistoryAction.
  ///
  /// In en, this message translates to:
  /// **'History'**
  String get challengeHistoryAction;

  /// No description provided for @challengeListTitle.
  ///
  /// In en, this message translates to:
  /// **'Active challenges'**
  String get challengeListTitle;

  /// No description provided for @challengeListBody.
  ///
  /// In en, this message translates to:
  /// **'{count} challenges are ready or in progress. Prepared challenges and today\'s rounds are grouped here.'**
  String challengeListBody(int count);

  /// No description provided for @challengeCreateTitle.
  ///
  /// In en, this message translates to:
  /// **'Create challenge'**
  String get challengeCreateTitle;

  /// No description provided for @challengeCreateAction.
  ///
  /// In en, this message translates to:
  /// **'Create challenge'**
  String get challengeCreateAction;

  /// No description provided for @challengeDetailTitle.
  ///
  /// In en, this message translates to:
  /// **'Challenge detail'**
  String get challengeDetailTitle;

  /// No description provided for @challengeDetailAction.
  ///
  /// In en, this message translates to:
  /// **'Details'**
  String get challengeDetailAction;

  /// No description provided for @challengeEditTitle.
  ///
  /// In en, this message translates to:
  /// **'Edit challenge'**
  String get challengeEditTitle;

  /// No description provided for @challengeEditAction.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get challengeEditAction;

  /// No description provided for @challengeEditBody.
  ///
  /// In en, this message translates to:
  /// **'Adjust the duration, round frequency, and mission setup before the challenge starts.'**
  String get challengeEditBody;

  /// No description provided for @challengeUpdateAction.
  ///
  /// In en, this message translates to:
  /// **'Save changes'**
  String get challengeUpdateAction;

  /// No description provided for @challengeUpdateSnack.
  ///
  /// In en, this message translates to:
  /// **'Challenge updated.'**
  String get challengeUpdateSnack;

  /// No description provided for @challengeEditUnavailableSnack.
  ///
  /// In en, this message translates to:
  /// **'Challenges with started records cannot be edited.'**
  String get challengeEditUnavailableSnack;

  /// No description provided for @challengeDeletePendingAction.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get challengeDeletePendingAction;

  /// No description provided for @challengeDeletePendingTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete challenge'**
  String get challengeDeletePendingTitle;

  /// No description provided for @challengeDeletePendingBody.
  ///
  /// In en, this message translates to:
  /// **'This challenge has not started yet. Delete this challenge?'**
  String get challengeDeletePendingBody;

  /// No description provided for @challengeDeletePendingConfirm.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get challengeDeletePendingConfirm;

  /// No description provided for @challengeDeletePendingSnack.
  ///
  /// In en, this message translates to:
  /// **'Challenge deleted.'**
  String get challengeDeletePendingSnack;

  /// No description provided for @challengeDeletePendingUnavailableSnack.
  ///
  /// In en, this message translates to:
  /// **'Challenges with started records cannot be deleted.'**
  String get challengeDeletePendingUnavailableSnack;

  /// No description provided for @challengeStartHeroTitle.
  ///
  /// In en, this message translates to:
  /// **'Rinzy\'s Challenge Mode'**
  String get challengeStartHeroTitle;

  /// No description provided for @challengeStartHeroBody.
  ///
  /// In en, this message translates to:
  /// **'Choose a duration and mission amounts, then prepare the challenge. When ready, the player can start from today.'**
  String get challengeStartHeroBody;

  /// No description provided for @challengeLatestComplete.
  ///
  /// In en, this message translates to:
  /// **'Latest challenge complete'**
  String get challengeLatestComplete;

  /// No description provided for @challengeSelectTitle.
  ///
  /// In en, this message translates to:
  /// **'Choose a challenge'**
  String get challengeSelectTitle;

  /// No description provided for @challengeActiveCardTitle.
  ///
  /// In en, this message translates to:
  /// **'{title} in progress'**
  String challengeActiveCardTitle(Object title);

  /// No description provided for @challengeCreateAnotherTitle.
  ///
  /// In en, this message translates to:
  /// **'Add another challenge'**
  String get challengeCreateAnotherTitle;

  /// No description provided for @challengeDurationSelectTitle.
  ///
  /// In en, this message translates to:
  /// **'1. Choose duration'**
  String get challengeDurationSelectTitle;

  /// No description provided for @challengeCadenceSelectTitle.
  ///
  /// In en, this message translates to:
  /// **'Round frequency'**
  String get challengeCadenceSelectTitle;

  /// No description provided for @challengeCadenceDaily.
  ///
  /// In en, this message translates to:
  /// **'Every day'**
  String get challengeCadenceDaily;

  /// No description provided for @challengeCadenceEveryTwoDays.
  ///
  /// In en, this message translates to:
  /// **'Every 2 days'**
  String get challengeCadenceEveryTwoDays;

  /// No description provided for @challengeCadenceWeekly.
  ///
  /// In en, this message translates to:
  /// **'Once a week'**
  String get challengeCadenceWeekly;

  /// No description provided for @challengeCadenceEveryNDays.
  ///
  /// In en, this message translates to:
  /// **'Every {days} days'**
  String challengeCadenceEveryNDays(int days);

  /// No description provided for @challengeTemplateStarterTitle.
  ///
  /// In en, this message translates to:
  /// **'3-day Challenge'**
  String get challengeTemplateStarterTitle;

  /// No description provided for @challengeTemplateStarterDescription.
  ///
  /// In en, this message translates to:
  /// **'Learn the challenge rhythm with a short focused run.'**
  String get challengeTemplateStarterDescription;

  /// No description provided for @challengeTemplateWeeklyTitle.
  ///
  /// In en, this message translates to:
  /// **'7-day Challenge'**
  String get challengeTemplateWeeklyTitle;

  /// No description provided for @challengeTemplateWeeklyDescription.
  ///
  /// In en, this message translates to:
  /// **'Keep a daily routine for one full week.'**
  String get challengeTemplateWeeklyDescription;

  /// No description provided for @challengeTemplateFocusTitle.
  ///
  /// In en, this message translates to:
  /// **'14-day Challenge'**
  String get challengeTemplateFocusTitle;

  /// No description provided for @challengeTemplateFocusDescription.
  ///
  /// In en, this message translates to:
  /// **'Build consistency across two steady weeks.'**
  String get challengeTemplateFocusDescription;

  /// No description provided for @challengeDifficultySprout.
  ///
  /// In en, this message translates to:
  /// **'Sprout'**
  String get challengeDifficultySprout;

  /// No description provided for @challengeDifficultyBoost.
  ///
  /// In en, this message translates to:
  /// **'Grow-Up'**
  String get challengeDifficultyBoost;

  /// No description provided for @challengeDifficultyStar.
  ///
  /// In en, this message translates to:
  /// **'Star'**
  String get challengeDifficultyStar;

  /// No description provided for @challengeTrainingLevelTitle.
  ///
  /// In en, this message translates to:
  /// **'2. Choose level'**
  String get challengeTrainingLevelTitle;

  /// No description provided for @challengeTrainingLevelRookieTitle.
  ///
  /// In en, this message translates to:
  /// **'Rookie level'**
  String get challengeTrainingLevelRookieTitle;

  /// No description provided for @challengeTrainingLevelRookieDescription.
  ///
  /// In en, this message translates to:
  /// **'A lighter target for younger players or players just starting soccer.'**
  String get challengeTrainingLevelRookieDescription;

  /// No description provided for @challengeTrainingLevelGrowthTitle.
  ///
  /// In en, this message translates to:
  /// **'Grow-Up level'**
  String get challengeTrainingLevelGrowthTitle;

  /// No description provided for @challengeTrainingLevelGrowthDescription.
  ///
  /// In en, this message translates to:
  /// **'A steady target for players with basic rhythm and regular practice.'**
  String get challengeTrainingLevelGrowthDescription;

  /// No description provided for @challengeTrainingLevelAceTitle.
  ///
  /// In en, this message translates to:
  /// **'Ace level'**
  String get challengeTrainingLevelAceTitle;

  /// No description provided for @challengeTrainingLevelAceDescription.
  ///
  /// In en, this message translates to:
  /// **'A challenging target for older players with more soccer experience.'**
  String get challengeTrainingLevelAceDescription;

  /// No description provided for @challengeRecommendedLevelBadge.
  ///
  /// In en, this message translates to:
  /// **'Recommended'**
  String get challengeRecommendedLevelBadge;

  /// No description provided for @challengeSkillSelectTitle.
  ///
  /// In en, this message translates to:
  /// **'2. Choose missions'**
  String get challengeSkillSelectTitle;

  /// No description provided for @challengeSkillSelectSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Choose training programs, auxiliary drills, and meal missions for this challenge, then adjust each daily target.'**
  String get challengeSkillSelectSubtitle;

  /// No description provided for @challengeMissionOtherSectionTitle.
  ///
  /// In en, this message translates to:
  /// **'Extra missions'**
  String get challengeMissionOtherSectionTitle;

  /// No description provided for @challengeMissionTargetsTitle.
  ///
  /// In en, this message translates to:
  /// **'Mission targets'**
  String get challengeMissionTargetsTitle;

  /// No description provided for @challengeMissionTargetsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Choose the daily amount for each selected mission.'**
  String get challengeMissionTargetsSubtitle;

  /// No description provided for @challengeTrainingProgramLinkTitle.
  ///
  /// In en, this message translates to:
  /// **'Edit training programs'**
  String get challengeTrainingProgramLinkTitle;

  /// No description provided for @challengeTrainingProgramLinkBody.
  ///
  /// In en, this message translates to:
  /// **'Open Settings defaults to edit the training program options.'**
  String get challengeTrainingProgramLinkBody;

  /// No description provided for @challengeTrainingProgramLinkAction.
  ///
  /// In en, this message translates to:
  /// **'Open'**
  String get challengeTrainingProgramLinkAction;

  /// No description provided for @challengeTrainingProgramMissionLabel.
  ///
  /// In en, this message translates to:
  /// **'Training programs'**
  String get challengeTrainingProgramMissionLabel;

  /// No description provided for @challengeMissionSummaryTitle.
  ///
  /// In en, this message translates to:
  /// **'Selected missions'**
  String get challengeMissionSummaryTitle;

  /// No description provided for @challengeMissionProgramSummary.
  ///
  /// In en, this message translates to:
  /// **'{label}: {programs}'**
  String challengeMissionProgramSummary(Object label, Object programs);

  /// No description provided for @challengeRiceBowlsOption.
  ///
  /// In en, this message translates to:
  /// **'{bowls} bowls'**
  String challengeRiceBowlsOption(Object bowls);

  /// No description provided for @challengeSkillDribble.
  ///
  /// In en, this message translates to:
  /// **'Dribble'**
  String get challengeSkillDribble;

  /// No description provided for @challengeSkillSpeedRun.
  ///
  /// In en, this message translates to:
  /// **'Speed run'**
  String get challengeSkillSpeedRun;

  /// No description provided for @challengeSkillJumpRope.
  ///
  /// In en, this message translates to:
  /// **'Jump rope'**
  String get challengeSkillJumpRope;

  /// No description provided for @challengeSkillLifting.
  ///
  /// In en, this message translates to:
  /// **'Lifting'**
  String get challengeSkillLifting;

  /// No description provided for @challengeSkillPassing.
  ///
  /// In en, this message translates to:
  /// **'Passing'**
  String get challengeSkillPassing;

  /// No description provided for @challengeSkillShooting.
  ///
  /// In en, this message translates to:
  /// **'Shooting'**
  String get challengeSkillShooting;

  /// No description provided for @challengeSkillFirstTouch.
  ///
  /// In en, this message translates to:
  /// **'First touch'**
  String get challengeSkillFirstTouch;

  /// No description provided for @challengeSkillDefense.
  ///
  /// In en, this message translates to:
  /// **'Defense'**
  String get challengeSkillDefense;

  /// No description provided for @challengeLevelTrainingTargetLabel.
  ///
  /// In en, this message translates to:
  /// **'Total training {minutes} min'**
  String challengeLevelTrainingTargetLabel(int minutes);

  /// No description provided for @challengeLevelJumpRopeTargetLabel.
  ///
  /// In en, this message translates to:
  /// **'Jump rope {minutes} min'**
  String challengeLevelJumpRopeTargetLabel(int minutes);

  /// No description provided for @challengeLevelLiftingTargetLabel.
  ///
  /// In en, this message translates to:
  /// **'Lifting {minutes} min'**
  String challengeLevelLiftingTargetLabel(int minutes);

  /// No description provided for @challengeDaysLabel.
  ///
  /// In en, this message translates to:
  /// **'{days} days'**
  String challengeDaysLabel(int days);

  /// No description provided for @challengeRewardXp.
  ///
  /// In en, this message translates to:
  /// **'+{xp} XP'**
  String challengeRewardXp(int xp);

  /// No description provided for @challengeRoundXpLabel.
  ///
  /// In en, this message translates to:
  /// **'Round +{xp} XP'**
  String challengeRoundXpLabel(int xp);

  /// No description provided for @challengeStreakBonusLabel.
  ///
  /// In en, this message translates to:
  /// **'Streak bonus +{xp} XP'**
  String challengeStreakBonusLabel(int xp);

  /// No description provided for @challengeActiveLevelPill.
  ///
  /// In en, this message translates to:
  /// **'Level: {level}'**
  String challengeActiveLevelPill(Object level);

  /// No description provided for @challengeInfoStatusLabel.
  ///
  /// In en, this message translates to:
  /// **'Status'**
  String get challengeInfoStatusLabel;

  /// No description provided for @challengeInfoLevelLabel.
  ///
  /// In en, this message translates to:
  /// **'Level'**
  String get challengeInfoLevelLabel;

  /// No description provided for @challengeInfoRoundXpLabel.
  ///
  /// In en, this message translates to:
  /// **'Round reward'**
  String get challengeInfoRoundXpLabel;

  /// No description provided for @challengeInfoPotentialXpLabel.
  ///
  /// In en, this message translates to:
  /// **'Challenge reward'**
  String get challengeInfoPotentialXpLabel;

  /// No description provided for @challengeInfoPeriodLabel.
  ///
  /// In en, this message translates to:
  /// **'Period'**
  String get challengeInfoPeriodLabel;

  /// No description provided for @challengeInfoRoundProgressLabel.
  ///
  /// In en, this message translates to:
  /// **'Round progress'**
  String get challengeInfoRoundProgressLabel;

  /// No description provided for @challengePotentialXpPill.
  ///
  /// In en, this message translates to:
  /// **'Potential XP +{xp}'**
  String challengePotentialXpPill(int xp);

  /// No description provided for @challengeCompletionBonusLabel.
  ///
  /// In en, this message translates to:
  /// **'Finish bonus +{xp} XP'**
  String challengeCompletionBonusLabel(int xp);

  /// No description provided for @challengeTotalXpLabel.
  ///
  /// In en, this message translates to:
  /// **'Up to +{xp} XP'**
  String challengeTotalXpLabel(int xp);

  /// No description provided for @challengeRewardPitchTitle.
  ///
  /// In en, this message translates to:
  /// **'A big finish bonus is waiting'**
  String get challengeRewardPitchTitle;

  /// No description provided for @challengeRewardGiftSectionTitle.
  ///
  /// In en, this message translates to:
  /// **'Gift reward'**
  String get challengeRewardGiftSectionTitle;

  /// No description provided for @challengeRewardGiftSectionSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Write the gift to give when the challenge is finished.'**
  String get challengeRewardGiftSectionSubtitle;

  /// No description provided for @challengeRewardGiftInputLabel.
  ///
  /// In en, this message translates to:
  /// **'Finish gift'**
  String get challengeRewardGiftInputLabel;

  /// No description provided for @challengeRewardGiftInputHint.
  ///
  /// In en, this message translates to:
  /// **'Example: new football'**
  String get challengeRewardGiftInputHint;

  /// No description provided for @challengeRewardGiftPill.
  ///
  /// In en, this message translates to:
  /// **'Gift: {gift}'**
  String challengeRewardGiftPill(Object gift);

  /// No description provided for @challengeRewardGiftPromisedLabel.
  ///
  /// In en, this message translates to:
  /// **'Finish gift'**
  String get challengeRewardGiftPromisedLabel;

  /// No description provided for @challengeRewardGiftPromisedBody.
  ///
  /// In en, this message translates to:
  /// **'Finish the challenge to earn this gift: {gift}.'**
  String challengeRewardGiftPromisedBody(Object gift);

  /// No description provided for @challengeGiftReceiveTitle.
  ///
  /// In en, this message translates to:
  /// **'Rinzy brought your gift!'**
  String get challengeGiftReceiveTitle;

  /// No description provided for @challengeGiftReceiveBody.
  ///
  /// In en, this message translates to:
  /// **'It is time to receive {gift}. Rinzy is celebrating the promise you finished.'**
  String challengeGiftReceiveBody(Object gift);

  /// No description provided for @challengeGiftReceiveAction.
  ///
  /// In en, this message translates to:
  /// **'Gift received'**
  String get challengeGiftReceiveAction;

  /// No description provided for @challengeRewardGuideTitle.
  ///
  /// In en, this message translates to:
  /// **'Challenge rewards'**
  String get challengeRewardGuideTitle;

  /// No description provided for @challengeRewardGuideBody.
  ///
  /// In en, this message translates to:
  /// **'Round rewards grow when rounds are completed consecutively. A finished challenge also adds the finish bonus.'**
  String get challengeRewardGuideBody;

  /// No description provided for @challengeRewardGuideNoActive.
  ///
  /// In en, this message translates to:
  /// **'No active challenge is running. Start a challenge to see earned and remaining XP.'**
  String get challengeRewardGuideNoActive;

  /// No description provided for @challengeRewardGuideActiveTitle.
  ///
  /// In en, this message translates to:
  /// **'Current challenge'**
  String get challengeRewardGuideActiveTitle;

  /// No description provided for @challengeRewardGuideTemplatesTitle.
  ///
  /// In en, this message translates to:
  /// **'Reward plans by challenge'**
  String get challengeRewardGuideTemplatesTitle;

  /// No description provided for @challengeRewardGuideTemplateTitle.
  ///
  /// In en, this message translates to:
  /// **'{title} reward plan'**
  String challengeRewardGuideTemplateTitle(Object title);

  /// No description provided for @challengeRewardGuideHistoryTitle.
  ///
  /// In en, this message translates to:
  /// **'Reward plan'**
  String get challengeRewardGuideHistoryTitle;

  /// No description provided for @challengeRewardGuideBaseRoundLabel.
  ///
  /// In en, this message translates to:
  /// **'Base round'**
  String get challengeRewardGuideBaseRoundLabel;

  /// No description provided for @challengeRewardGuideStreakBonusLabel.
  ///
  /// In en, this message translates to:
  /// **'Max streak bonus'**
  String get challengeRewardGuideStreakBonusLabel;

  /// No description provided for @challengeRewardGuideRoundTotalLabel.
  ///
  /// In en, this message translates to:
  /// **'Rounds total'**
  String get challengeRewardGuideRoundTotalLabel;

  /// No description provided for @challengeRewardGuideFinishBonusLabel.
  ///
  /// In en, this message translates to:
  /// **'Finish bonus'**
  String get challengeRewardGuideFinishBonusLabel;

  /// No description provided for @challengeRewardGuidePotentialLabel.
  ///
  /// In en, this message translates to:
  /// **'Maximum XP'**
  String get challengeRewardGuidePotentialLabel;

  /// No description provided for @challengeRewardGuideEarnedLabel.
  ///
  /// In en, this message translates to:
  /// **'Earned so far'**
  String get challengeRewardGuideEarnedLabel;

  /// No description provided for @challengeRewardGuideRemainingLabel.
  ///
  /// In en, this message translates to:
  /// **'Remaining'**
  String get challengeRewardGuideRemainingLabel;

  /// No description provided for @challengeRewardGuideRoundsTitle.
  ///
  /// In en, this message translates to:
  /// **'Round rewards'**
  String get challengeRewardGuideRoundsTitle;

  /// No description provided for @challengeRewardGuideRoundReward.
  ///
  /// In en, this message translates to:
  /// **'Round {round}: +{xp} XP'**
  String challengeRewardGuideRoundReward(int round, int xp);

  /// No description provided for @challengeRewardGuideRoundRewardWithBonus.
  ///
  /// In en, this message translates to:
  /// **'Round {round}: +{xp} XP (streak +{bonus})'**
  String challengeRewardGuideRoundRewardWithBonus(int round, int xp, int bonus);

  /// No description provided for @challengeStartReadyTitle.
  ///
  /// In en, this message translates to:
  /// **'3. Save setup'**
  String get challengeStartReadyTitle;

  /// No description provided for @challengePrepareAction.
  ///
  /// In en, this message translates to:
  /// **'Prepare challenge'**
  String get challengePrepareAction;

  /// No description provided for @challengeStartAction.
  ///
  /// In en, this message translates to:
  /// **'Start challenge'**
  String get challengeStartAction;

  /// No description provided for @challengeRoundCount.
  ///
  /// In en, this message translates to:
  /// **'{completed}/{total} rounds complete'**
  String challengeRoundCount(int completed, int total);

  /// No description provided for @challengeMissionCount.
  ///
  /// In en, this message translates to:
  /// **'{completed}/{total} missions complete'**
  String challengeMissionCount(int completed, int total);

  /// No description provided for @challengeProgressPercent.
  ///
  /// In en, this message translates to:
  /// **'{percent}% complete'**
  String challengeProgressPercent(int percent);

  /// No description provided for @challengeTodayRoundTitle.
  ///
  /// In en, this message translates to:
  /// **'Today · Round {round}'**
  String challengeTodayRoundTitle(int round);

  /// No description provided for @challengeUpcomingRoundTitle.
  ///
  /// In en, this message translates to:
  /// **'Next · Round {round}'**
  String challengeUpcomingRoundTitle(int round);

  /// No description provided for @challengeRoundsTitle.
  ///
  /// In en, this message translates to:
  /// **'Rounds'**
  String get challengeRoundsTitle;

  /// No description provided for @challengeRoundTitle.
  ///
  /// In en, this message translates to:
  /// **'Round {round}'**
  String challengeRoundTitle(int round);

  /// No description provided for @challengeTrainingLabel.
  ///
  /// In en, this message translates to:
  /// **'Training'**
  String get challengeTrainingLabel;

  /// No description provided for @challengeJumpRopeLabel.
  ///
  /// In en, this message translates to:
  /// **'Jump rope'**
  String get challengeJumpRopeLabel;

  /// No description provided for @challengeLiftingLabel.
  ///
  /// In en, this message translates to:
  /// **'Lifting'**
  String get challengeLiftingLabel;

  /// No description provided for @challengeMealLabel.
  ///
  /// In en, this message translates to:
  /// **'Meals'**
  String get challengeMealLabel;

  /// No description provided for @challengeTrainingGoalValue.
  ///
  /// In en, this message translates to:
  /// **'{current}/{target} min'**
  String challengeTrainingGoalValue(int current, int target);

  /// No description provided for @challengeMealGoalValue.
  ///
  /// In en, this message translates to:
  /// **'{current}/{target} bowls'**
  String challengeMealGoalValue(Object current, Object target);

  /// No description provided for @challengeCompletedBadge.
  ///
  /// In en, this message translates to:
  /// **'Complete'**
  String get challengeCompletedBadge;

  /// No description provided for @challengeReadyBadge.
  ///
  /// In en, this message translates to:
  /// **'Not started'**
  String get challengeReadyBadge;

  /// No description provided for @challengePendingBadge.
  ///
  /// In en, this message translates to:
  /// **'In progress'**
  String get challengePendingBadge;

  /// No description provided for @challengeReadyPeriodLabel.
  ///
  /// In en, this message translates to:
  /// **'The schedule starts from the day you begin.'**
  String get challengeReadyPeriodLabel;

  /// No description provided for @challengeReadyCardTitle.
  ///
  /// In en, this message translates to:
  /// **'{title} is ready'**
  String challengeReadyCardTitle(Object title);

  /// No description provided for @challengeReadyPlayerBody.
  ///
  /// In en, this message translates to:
  /// **'Start when you are ready. The round schedule and mission tracking open from the start day.'**
  String get challengeReadyPlayerBody;

  /// No description provided for @challengeReadyParentBody.
  ///
  /// In en, this message translates to:
  /// **'The player can start this from player mode when ready. Before it starts, you can still edit or delete it.'**
  String get challengeReadyParentBody;

  /// No description provided for @challengeReadyStartAction.
  ///
  /// In en, this message translates to:
  /// **'Start now'**
  String get challengeReadyStartAction;

  /// No description provided for @challengeCompletedSummary.
  ///
  /// In en, this message translates to:
  /// **'{title} complete'**
  String challengeCompletedSummary(Object title);

  /// No description provided for @challengeRoundDateToday.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get challengeRoundDateToday;

  /// No description provided for @challengePrepareSnack.
  ///
  /// In en, this message translates to:
  /// **'{title} prepared.'**
  String challengePrepareSnack(Object title);

  /// No description provided for @challengeStartSnack.
  ///
  /// In en, this message translates to:
  /// **'{title} started.'**
  String challengeStartSnack(Object title);

  /// No description provided for @challengeAwardSnack.
  ///
  /// In en, this message translates to:
  /// **'Challenge round complete +{xp} XP'**
  String challengeAwardSnack(int xp);

  /// No description provided for @challengeCompletedSnack.
  ///
  /// In en, this message translates to:
  /// **'Challenge complete.'**
  String get challengeCompletedSnack;

  /// No description provided for @challengeFailedSnack.
  ///
  /// In en, this message translates to:
  /// **'Round {round} was missed, so the challenge ended as failed.'**
  String challengeFailedSnack(int round);

  /// No description provided for @challengeFailureTitle.
  ///
  /// In en, this message translates to:
  /// **'Round {round} stopped here'**
  String challengeFailureTitle(int round);

  /// No description provided for @challengeFailureSimpleTitle.
  ///
  /// In en, this message translates to:
  /// **'Rinzy is sad today'**
  String get challengeFailureSimpleTitle;

  /// No description provided for @challengeFailureBody.
  ///
  /// In en, this message translates to:
  /// **'Rinzy is sad, but tomorrow\'s round can start stronger.'**
  String get challengeFailureBody;

  /// No description provided for @challengeFailureAction.
  ///
  /// In en, this message translates to:
  /// **'Check the round'**
  String get challengeFailureAction;

  /// No description provided for @challengeCelebrationTitle.
  ///
  /// In en, this message translates to:
  /// **'Mission complete!'**
  String get challengeCelebrationTitle;

  /// No description provided for @challengeCelebrationBody.
  ///
  /// In en, this message translates to:
  /// **'Round {rounds} complete. Rinzy is cheering. You earned +{xp} XP.'**
  String challengeCelebrationBody(int rounds, int xp);

  /// No description provided for @challengeCelebrationBodyNoXp.
  ///
  /// In en, this message translates to:
  /// **'Round missions complete. Review the record.'**
  String get challengeCelebrationBodyNoXp;

  /// No description provided for @challengeCelebrationCompleteTitle.
  ///
  /// In en, this message translates to:
  /// **'Challenge complete!'**
  String get challengeCelebrationCompleteTitle;

  /// No description provided for @challengeCelebrationCompleteBody.
  ///
  /// In en, this message translates to:
  /// **'You finished every round. That consistency is becoming real skill. You earned +{xp} XP.'**
  String challengeCelebrationCompleteBody(int xp);

  /// No description provided for @challengeCelebrationCompleteBodyNoXp.
  ///
  /// In en, this message translates to:
  /// **'All missions are recorded. Carry this finish into the next challenge.'**
  String get challengeCelebrationCompleteBodyNoXp;

  /// No description provided for @challengeCelebrationMissionsTitle.
  ///
  /// In en, this message translates to:
  /// **'Completed missions'**
  String get challengeCelebrationMissionsTitle;

  /// No description provided for @challengeCelebrationAction.
  ///
  /// In en, this message translates to:
  /// **'Nice!'**
  String get challengeCelebrationAction;

  /// No description provided for @challengeCelebrationNextChallengeAction.
  ///
  /// In en, this message translates to:
  /// **'Create next challenge'**
  String get challengeCelebrationNextChallengeAction;

  /// No description provided for @challengeFinishedPraiseTitle.
  ///
  /// In en, this message translates to:
  /// **'You finished it all'**
  String get challengeFinishedPraiseTitle;

  /// No description provided for @challengeFinishedPraiseBody.
  ///
  /// In en, this message translates to:
  /// **'You completed all {rounds} rounds of {title}. Keep the rhythm going with the next challenge.'**
  String challengeFinishedPraiseBody(Object title, int rounds);

  /// No description provided for @challengeFinishedCompletedRoundsLabel.
  ///
  /// In en, this message translates to:
  /// **'{rounds} rounds completed'**
  String challengeFinishedCompletedRoundsLabel(int rounds);

  /// No description provided for @challengeFinishedNextPrompt.
  ///
  /// In en, this message translates to:
  /// **'Choose the next challenge below'**
  String get challengeFinishedNextPrompt;

  /// No description provided for @challengeHistoryTitle.
  ///
  /// In en, this message translates to:
  /// **'Challenge history'**
  String get challengeHistoryTitle;

  /// No description provided for @challengeHistorySummaryTitle.
  ///
  /// In en, this message translates to:
  /// **'Challenge summary'**
  String get challengeHistorySummaryTitle;

  /// No description provided for @challengeHistoryListTitle.
  ///
  /// In en, this message translates to:
  /// **'Challenge records'**
  String get challengeHistoryListTitle;

  /// No description provided for @challengeHistorySummaryTotalLabel.
  ///
  /// In en, this message translates to:
  /// **'Total'**
  String get challengeHistorySummaryTotalLabel;

  /// No description provided for @challengeHistorySummarySuccessLabel.
  ///
  /// In en, this message translates to:
  /// **'Success'**
  String get challengeHistorySummarySuccessLabel;

  /// No description provided for @challengeHistorySummaryLatestLabel.
  ///
  /// In en, this message translates to:
  /// **'Latest'**
  String get challengeHistorySummaryLatestLabel;

  /// No description provided for @challengeHistoryEmpty.
  ///
  /// In en, this message translates to:
  /// **'No challenge history yet.'**
  String get challengeHistoryEmpty;

  /// No description provided for @challengeHistoryStarted.
  ///
  /// In en, this message translates to:
  /// **'Started {date}'**
  String challengeHistoryStarted(Object date);

  /// No description provided for @challengeHistoryFailedRound.
  ///
  /// In en, this message translates to:
  /// **'Started {date} · failed at round {round}'**
  String challengeHistoryFailedRound(Object date, int round);

  /// No description provided for @challengeHistoryResultCompleted.
  ///
  /// In en, this message translates to:
  /// **'Success'**
  String get challengeHistoryResultCompleted;

  /// No description provided for @challengeHistoryResultFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed'**
  String get challengeHistoryResultFailed;

  /// No description provided for @challengeHistoryResultAbandoned.
  ///
  /// In en, this message translates to:
  /// **'Ended'**
  String get challengeHistoryResultAbandoned;

  /// No description provided for @challengeHistoryResultInProgress.
  ///
  /// In en, this message translates to:
  /// **'In progress'**
  String get challengeHistoryResultInProgress;

  /// No description provided for @challengeHistoryRoundSuccessCount.
  ///
  /// In en, this message translates to:
  /// **'Success {success}/{total}'**
  String challengeHistoryRoundSuccessCount(int success, int total);

  /// No description provided for @challengeHistoryRoundFailureCount.
  ///
  /// In en, this message translates to:
  /// **'Fail {failure}/{total}'**
  String challengeHistoryRoundFailureCount(int failure, int total);

  /// No description provided for @challengeHistoryDetailTitle.
  ///
  /// In en, this message translates to:
  /// **'Challenge detail'**
  String get challengeHistoryDetailTitle;

  /// No description provided for @challengeHistoryDetailCompletedBody.
  ///
  /// In en, this message translates to:
  /// **'All rounds were completed. Review the reward plan and round dates.'**
  String get challengeHistoryDetailCompletedBody;

  /// No description provided for @challengeHistoryDetailFailedBody.
  ///
  /// In en, this message translates to:
  /// **'This challenge stopped at round {round}. Review the round sequence and reward plan.'**
  String challengeHistoryDetailFailedBody(int round);

  /// No description provided for @challengeHistoryDetailAbandonedBody.
  ///
  /// In en, this message translates to:
  /// **'This challenge was ended before completion. Review the original round plan.'**
  String get challengeHistoryDetailAbandonedBody;

  /// No description provided for @challengeHistoryDetailPeriodValue.
  ///
  /// In en, this message translates to:
  /// **'{start} - {end}'**
  String challengeHistoryDetailPeriodValue(Object start, Object end);

  /// No description provided for @challengeHistoryDetailMissionsLabel.
  ///
  /// In en, this message translates to:
  /// **'Missions'**
  String get challengeHistoryDetailMissionsLabel;

  /// No description provided for @challengeHistoryDetailEarnedXpLabel.
  ///
  /// In en, this message translates to:
  /// **'Earned XP'**
  String get challengeHistoryDetailEarnedXpLabel;

  /// No description provided for @challengeHistoryDetailNoMissions.
  ///
  /// In en, this message translates to:
  /// **'Extra missions only'**
  String get challengeHistoryDetailNoMissions;

  /// No description provided for @challengeHistoryDetailRoundsTitle.
  ///
  /// In en, this message translates to:
  /// **'Round detail'**
  String get challengeHistoryDetailRoundsTitle;

  /// No description provided for @challengeHistoryDetailRoundDate.
  ///
  /// In en, this message translates to:
  /// **'Round {round} · {date}'**
  String challengeHistoryDetailRoundDate(int round, Object date);

  /// No description provided for @challengeHistoryDetailRoundCompleted.
  ///
  /// In en, this message translates to:
  /// **'Completed'**
  String get challengeHistoryDetailRoundCompleted;

  /// No description provided for @challengeHistoryDetailRoundFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed here'**
  String get challengeHistoryDetailRoundFailed;

  /// No description provided for @challengeHistoryDetailRoundEnded.
  ///
  /// In en, this message translates to:
  /// **'Not counted'**
  String get challengeHistoryDetailRoundEnded;

  /// No description provided for @challengeAbandonAction.
  ///
  /// In en, this message translates to:
  /// **'End'**
  String get challengeAbandonAction;

  /// No description provided for @challengeAbandonTitle.
  ///
  /// In en, this message translates to:
  /// **'End challenge'**
  String get challengeAbandonTitle;

  /// No description provided for @challengeAbandonBody.
  ///
  /// In en, this message translates to:
  /// **'End the current challenge and choose another?'**
  String get challengeAbandonBody;

  /// No description provided for @challengeAbandonConfirm.
  ///
  /// In en, this message translates to:
  /// **'End'**
  String get challengeAbandonConfirm;

  /// No description provided for @homeChallengeEmptyBody.
  ///
  /// In en, this message translates to:
  /// **'Start a challenge with Rinzy.'**
  String get homeChallengeEmptyBody;

  /// No description provided for @homeChallengeActiveBody.
  ///
  /// In en, this message translates to:
  /// **'{completed}/{total} complete · Round {round} today'**
  String homeChallengeActiveBody(int completed, int total, int round);

  /// No description provided for @xpHistoryChallengeRound.
  ///
  /// In en, this message translates to:
  /// **'Challenge round · {label}'**
  String xpHistoryChallengeRound(Object label);

  /// No description provided for @xpHistoryReasonChallengeRoundCompleted.
  ///
  /// In en, this message translates to:
  /// **'challenge round complete'**
  String get xpHistoryReasonChallengeRoundCompleted;

  /// No description provided for @xpHistoryReasonChallengeRoundStreakBonus.
  ///
  /// In en, this message translates to:
  /// **'challenge streak bonus'**
  String get xpHistoryReasonChallengeRoundStreakBonus;

  /// No description provided for @xpHistoryReasonChallengeCompletionBonus.
  ///
  /// In en, this message translates to:
  /// **'challenge finish bonus'**
  String get xpHistoryReasonChallengeCompletionBonus;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'ja', 'ko'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'ja':
      return AppLocalizationsJa();
    case 'ko':
      return AppLocalizationsKo();
  }

  throw FlutterError(
      'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
      'an issue with the localizations generation tool. Please file an issue '
      'on GitHub with a reproducible sample app and the gen-l10n configuration '
      'that was used.');
}
