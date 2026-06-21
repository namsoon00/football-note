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
  /// **'Position groups and a formation view for quickly reading the squad shape.'**
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

  /// No description provided for @worldCupQualificationScenariosGuide.
  ///
  /// In en, this message translates to:
  /// **'Each row is one result combination for this team\'s remaining matches. Auto means finishing 1st or 2nd in the group. 3rd-place race means finishing 3rd, then needing to be among the 8 best third-place teams overall. The denominators for auto, 3rd-place race, and out count every win/draw/loss combination for the other remaining matches in the same group. Opponent countries translate the bracket slot using the current table.'**
  String get worldCupQualificationScenariosGuide;

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

  /// No description provided for @worldCupQualificationThirdPlaceNote.
  ///
  /// In en, this message translates to:
  /// **'A third-place finish still needs to rank among the 8 best third-place teams across the 12 groups.'**
  String get worldCupQualificationThirdPlaceNote;

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
  /// **'M{matchNumber} · {opponent}'**
  String worldCupQualificationOpponentCandidate(
      int matchNumber, String opponent);

  /// No description provided for @worldCupQualificationOpponentCandidateWithCountries.
  ///
  /// In en, this message translates to:
  /// **'M{matchNumber} · {opponent} → {countries}'**
  String worldCupQualificationOpponentCandidateWithCountries(
      int matchNumber, String opponent, String countries);

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

  /// No description provided for @worldCupTeamRosterSourceNote.
  ///
  /// In en, this message translates to:
  /// **'Official 2026 squad data is not bundled for this country yet, so position slots are shown until a stable legal source is connected.'**
  String get worldCupTeamRosterSourceNote;

  /// No description provided for @worldCupTeamRosterCandidateSourceNote.
  ///
  /// In en, this message translates to:
  /// **'Shown from published 2026 squad information and expected formation data. Injury replacements and match-day choices can still change before kickoff.'**
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
  /// **'This currently shows the official group-position and previous-match-winner slots. Once group results are fixed, each slot can be followed as the actual country path.'**
  String get worldCupTournamentPlanBody;

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

  /// No description provided for @homeTodayPlanCardTitle.
  ///
  /// In en, this message translates to:
  /// **'Today training plan'**
  String get homeTodayPlanCardTitle;

  /// No description provided for @homeTodayPlanCardSummary.
  ///
  /// In en, this message translates to:
  /// **'Today: {count} plan(s)'**
  String homeTodayPlanCardSummary(int count);

  /// No description provided for @homeTodayPlanOpenAction.
  ///
  /// In en, this message translates to:
  /// **'Open plans'**
  String get homeTodayPlanOpenAction;

  /// No description provided for @homeTodayPlanSelectForLogTitle.
  ///
  /// In en, this message translates to:
  /// **'Choose a plan to turn into a training log'**
  String get homeTodayPlanSelectForLogTitle;

  /// No description provided for @homeHubTitleShort.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get homeHubTitleShort;

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

  /// No description provided for @homeContinueTodayPlanTitle.
  ///
  /// In en, this message translates to:
  /// **'Today training plan'**
  String get homeContinueTodayPlanTitle;

  /// No description provided for @homeContinueTodayPlanSubtitle.
  ///
  /// In en, this message translates to:
  /// **'{count} plans are waiting today.'**
  String homeContinueTodayPlanSubtitle(int count);

  /// No description provided for @homeContinuePlanButton.
  ///
  /// In en, this message translates to:
  /// **'Open plans'**
  String get homeContinuePlanButton;

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

  /// No description provided for @averageComparisonProfileMissingTitle.
  ///
  /// In en, this message translates to:
  /// **'Enter age and soccer experience'**
  String get averageComparisonProfileMissingTitle;

  /// No description provided for @averageComparisonProfileMissingMessage.
  ///
  /// In en, this message translates to:
  /// **'Average comparison is hidden because age and soccer experience are missing. Add birth date and soccer start date in profile.'**
  String get averageComparisonProfileMissingMessage;

  /// No description provided for @averageComparisonOpenProfileAction.
  ///
  /// In en, this message translates to:
  /// **'Open Profile'**
  String get averageComparisonOpenProfileAction;

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
  /// **'Weather details'**
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
  /// **'Almost no rain'**
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
  /// **'Fortune'**
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
  /// **'Pin today\'s fortune flow as a diary sticker.'**
  String get diaryFortunePinSummary;

  /// No description provided for @diaryFortuneStorySentence.
  ///
  /// In en, this message translates to:
  /// **'Write the one flow or encouragement you want to keep from today\'s fortune.'**
  String get diaryFortuneStorySentence;

  /// No description provided for @diaryFortuneNoteTitle.
  ///
  /// In en, this message translates to:
  /// **'Today fortune note'**
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
  /// **'Today fortune'**
  String get fortuneDialogTitle;

  /// No description provided for @fortuneDialogSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Check today lucky info.'**
  String get fortuneDialogSubtitle;

  /// No description provided for @fortuneDialogOverviewTitle.
  ///
  /// In en, this message translates to:
  /// **'Fortune overview'**
  String get fortuneDialogOverviewTitle;

  /// No description provided for @fortuneDialogOverallFortuneLabel.
  ///
  /// In en, this message translates to:
  /// **'Overall fortune'**
  String get fortuneDialogOverallFortuneLabel;

  /// No description provided for @fortuneDialogLuckyInfoLabel.
  ///
  /// In en, this message translates to:
  /// **'Lucky info'**
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
  /// **'Lucky info'**
  String get fortuneDialogLuckyInfoTitle;

  /// No description provided for @fortuneDialogPoolSizeLabel.
  ///
  /// In en, this message translates to:
  /// **'Fortune pool'**
  String get fortuneDialogPoolSizeLabel;

  /// No description provided for @fortuneDialogPoolSizeCount.
  ///
  /// In en, this message translates to:
  /// **'{count} cases'**
  String fortuneDialogPoolSizeCount(String count);

  /// No description provided for @fortuneDialogRecommendedProgramTitle.
  ///
  /// In en, this message translates to:
  /// **'Recommended training'**
  String get fortuneDialogRecommendedProgramTitle;

  /// No description provided for @fortuneDialogRecommendationTitle.
  ///
  /// In en, this message translates to:
  /// **'Fortune note'**
  String get fortuneDialogRecommendationTitle;

  /// No description provided for @fortuneDialogEncouragement.
  ///
  /// In en, this message translates to:
  /// **'Cheering for your best play today.'**
  String get fortuneDialogEncouragement;

  /// No description provided for @fortuneDialogAction.
  ///
  /// In en, this message translates to:
  /// **'Nice'**
  String get fortuneDialogAction;

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
  /// **'Ankle-to-shoulder lean without folding at the waist'**
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
  /// **'This loop shows the common failure pattern: upright torso, overstride, straight contact knee, open elbows, and extra vertical bounce.'**
  String get runningCoachSampleMistakeBody;

  /// No description provided for @runningCoachSampleReferencePosture.
  ///
  /// In en, this message translates to:
  /// **'Posture line: ankle-hip-shoulder lean is 10° without folding at the waist.'**
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
  /// **'Posture line: lean is only 2°, so the runner sits tall instead of driving forward.'**
  String get runningCoachSampleMistakePosture;

  /// No description provided for @runningCoachSampleMistakeFoot.
  ///
  /// In en, this message translates to:
  /// **'Contact point: overstride is 0.24 ahead of the hip, increasing braking.'**
  String get runningCoachSampleMistakeFoot;

  /// No description provided for @runningCoachSampleMistakeKnee.
  ///
  /// In en, this message translates to:
  /// **'Stance knee: 176° at contact, too straight to absorb and push.'**
  String get runningCoachSampleMistakeKnee;

  /// No description provided for @runningCoachSampleMistakeArms.
  ///
  /// In en, this message translates to:
  /// **'Arm angle: elbows open to 132°, slowing the arm-leg rhythm.'**
  String get runningCoachSampleMistakeArms;

  /// No description provided for @runningCoachSampleMistakeBounce.
  ///
  /// In en, this message translates to:
  /// **'Bounce: vertical motion rises to 12%, wasting force upward.'**
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

  /// No description provided for @runningCoachSampleOverlayFrames.
  ///
  /// In en, this message translates to:
  /// **'24/24 frames'**
  String get runningCoachSampleOverlayFrames;

  /// No description provided for @runningCoachSampleMistakeOverlayPosture.
  ///
  /// In en, this message translates to:
  /// **'Upright 2°'**
  String get runningCoachSampleMistakeOverlayPosture;

  /// No description provided for @runningCoachSampleMistakeOverlayArms.
  ///
  /// In en, this message translates to:
  /// **'Arms 132°'**
  String get runningCoachSampleMistakeOverlayArms;

  /// No description provided for @runningCoachSampleMistakeOverlayFoot.
  ///
  /// In en, this message translates to:
  /// **'Overstride 0.24'**
  String get runningCoachSampleMistakeOverlayFoot;

  /// No description provided for @runningCoachSampleMistakeOverlayBounce.
  ///
  /// In en, this message translates to:
  /// **'Bounce 12%'**
  String get runningCoachSampleMistakeOverlayBounce;

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
  /// **'Use the side-view camera to read trunk lean, knee drive, step rhythm, and arm balance, then get the one sprint cue to fix now.'**
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
  /// **'Keep the lean slightly more forward from the ankles, not by folding at the waist.'**
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
  /// **'Keep the chest lower for the first three steps and let the lean come from the ankles.'**
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
  /// **'Height and weight use CDC growth-chart medians. Activity time uses WHO youth guidance. Juggling ranges are a soccer training reference, not a medical standard.'**
  String get benchmarkReferenceNote;

  /// No description provided for @benchmarkAgeTableTitle.
  ///
  /// In en, this message translates to:
  /// **'Averages by age'**
  String get benchmarkAgeTableTitle;

  /// No description provided for @benchmarkAgeTableNote.
  ///
  /// In en, this message translates to:
  /// **'If the player\'s age is set, that row is highlighted. Weekly targets are adjusted by the entered soccer experience.'**
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
  /// **'Challenge is view only here.'**
  String get parentReadOnlyChallengeSummary;

  /// No description provided for @parentReadOnlyChallengeMessage.
  ///
  /// In en, this message translates to:
  /// **'Parent mode cannot start challenges or edit missions. You can only review challenge progress created in player mode.'**
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
  /// **'No saved fortune is available yet.'**
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

  /// No description provided for @matchCompetitionManageButton.
  ///
  /// In en, this message translates to:
  /// **'Teams / results'**
  String get matchCompetitionManageButton;

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

  /// No description provided for @trainingSketchPenButton.
  ///
  /// In en, this message translates to:
  /// **'Pen'**
  String get trainingSketchPenButton;

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
  /// **'Quick start: Select a player or ball, then tap a quick action like move, pass, or dribble.'**
  String get trainingSketchQuickStart;

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
  /// **'Tap a destination to create a move, or drag the player to adjust the position.'**
  String get trainingSketchLinkPlayerHint;

  /// No description provided for @trainingSketchLinkBallHint.
  ///
  /// In en, this message translates to:
  /// **'Tap a pass destination to create a ball action, or drag the ball to adjust the position.'**
  String get trainingSketchLinkBallHint;

  /// No description provided for @trainingSketchSelectedItemActionsTitle.
  ///
  /// In en, this message translates to:
  /// **'Quick actions'**
  String get trainingSketchSelectedItemActionsTitle;

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
  /// **'Pass warm-up'**
  String get trainingSketchTemplatePassWarmupLabel;

  /// No description provided for @trainingSketchTemplatePassWarmupDescription.
  ///
  /// In en, this message translates to:
  /// **'Basic 3-player passing setup'**
  String get trainingSketchTemplatePassWarmupDescription;

  /// No description provided for @trainingSketchTemplatePassWarmupMethod.
  ///
  /// In en, this message translates to:
  /// **'Two-touch pass plus rotate'**
  String get trainingSketchTemplatePassWarmupMethod;

  /// No description provided for @trainingSketchTemplateBuildUpLabel.
  ///
  /// In en, this message translates to:
  /// **'Build-up pattern'**
  String get trainingSketchTemplateBuildUpLabel;

  /// No description provided for @trainingSketchTemplateBuildUpDescription.
  ///
  /// In en, this message translates to:
  /// **'Back build-up structure'**
  String get trainingSketchTemplateBuildUpDescription;

  /// No description provided for @trainingSketchTemplateBuildUpMethod.
  ///
  /// In en, this message translates to:
  /// **'Back build-up in a 3-2 shape'**
  String get trainingSketchTemplateBuildUpMethod;

  /// No description provided for @trainingSketchTemplatePressingLabel.
  ///
  /// In en, this message translates to:
  /// **'Pressing transition'**
  String get trainingSketchTemplatePressingLabel;

  /// No description provided for @trainingSketchTemplatePressingDescription.
  ///
  /// In en, this message translates to:
  /// **'Front pressing trigger shape'**
  String get trainingSketchTemplatePressingDescription;

  /// No description provided for @trainingSketchTemplatePressingMethod.
  ///
  /// In en, this message translates to:
  /// **'Check front-press trigger cues'**
  String get trainingSketchTemplatePressingMethod;

  /// No description provided for @trainingSketchTemplateSetPieceLabel.
  ///
  /// In en, this message translates to:
  /// **'Set piece'**
  String get trainingSketchTemplateSetPieceLabel;

  /// No description provided for @trainingSketchTemplateSetPieceDescription.
  ///
  /// In en, this message translates to:
  /// **'Corner-kick layout'**
  String get trainingSketchTemplateSetPieceDescription;

  /// No description provided for @trainingSketchTemplateSetPieceMethod.
  ///
  /// In en, this message translates to:
  /// **'Corner-kick attacking setup'**
  String get trainingSketchTemplateSetPieceMethod;

  /// No description provided for @trainingSketchTemplateRondoLabel.
  ///
  /// In en, this message translates to:
  /// **'Rondo'**
  String get trainingSketchTemplateRondoLabel;

  /// No description provided for @trainingSketchTemplateRondoDescription.
  ///
  /// In en, this message translates to:
  /// **'4v1 keep-away shape'**
  String get trainingSketchTemplateRondoDescription;

  /// No description provided for @trainingSketchTemplateRondoMethod.
  ///
  /// In en, this message translates to:
  /// **'4v1 rondo with a two-touch limit'**
  String get trainingSketchTemplateRondoMethod;

  /// No description provided for @trainingSketchTemplateFinishingLabel.
  ///
  /// In en, this message translates to:
  /// **'Finishing pattern'**
  String get trainingSketchTemplateFinishingLabel;

  /// No description provided for @trainingSketchTemplateFinishingDescription.
  ///
  /// In en, this message translates to:
  /// **'Cross and box-finishing flow'**
  String get trainingSketchTemplateFinishingDescription;

  /// No description provided for @trainingSketchTemplateFinishingMethod.
  ///
  /// In en, this message translates to:
  /// **'Wide combination into a box finish'**
  String get trainingSketchTemplateFinishingMethod;

  /// No description provided for @trainingSketchTemplateWingCombinationLabel.
  ///
  /// In en, this message translates to:
  /// **'Wide combination'**
  String get trainingSketchTemplateWingCombinationLabel;

  /// No description provided for @trainingSketchTemplateWingCombinationDescription.
  ///
  /// In en, this message translates to:
  /// **'Winger and fullback overlap pattern'**
  String get trainingSketchTemplateWingCombinationDescription;

  /// No description provided for @trainingSketchTemplateWingCombinationMethod.
  ///
  /// In en, this message translates to:
  /// **'Winger-fullback overlap into a cutback'**
  String get trainingSketchTemplateWingCombinationMethod;

  /// No description provided for @trainingSketchTemplateTransitionAttackLabel.
  ///
  /// In en, this message translates to:
  /// **'Transition attack'**
  String get trainingSketchTemplateTransitionAttackLabel;

  /// No description provided for @trainingSketchTemplateTransitionAttackDescription.
  ///
  /// In en, this message translates to:
  /// **'Quick attack right after the regain'**
  String get trainingSketchTemplateTransitionAttackDescription;

  /// No description provided for @trainingSketchTemplateTransitionAttackMethod.
  ///
  /// In en, this message translates to:
  /// **'Attack forward within six seconds of the regain'**
  String get trainingSketchTemplateTransitionAttackMethod;

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

  /// No description provided for @challengeStartHeroTitle.
  ///
  /// In en, this message translates to:
  /// **'Rinzy\'s Challenge Mode'**
  String get challengeStartHeroTitle;

  /// No description provided for @challengeStartHeroBody.
  ///
  /// In en, this message translates to:
  /// **'Choose a duration and mission amounts, then press start to begin. Missing even one day ends the challenge.'**
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

  /// No description provided for @challengeDurationSelectTitle.
  ///
  /// In en, this message translates to:
  /// **'1. Choose duration'**
  String get challengeDurationSelectTitle;

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
  /// **'3. Ready to start'**
  String get challengeStartReadyTitle;

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

  /// No description provided for @challengePendingBadge.
  ///
  /// In en, this message translates to:
  /// **'In progress'**
  String get challengePendingBadge;

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
  /// **'All rounds are done. You earned +{xp} XP.'**
  String challengeCelebrationCompleteBody(int xp);

  /// No description provided for @challengeCelebrationCompleteBodyNoXp.
  ///
  /// In en, this message translates to:
  /// **'All missions are recorded. Review the challenge completion screen.'**
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
