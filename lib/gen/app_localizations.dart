import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
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
    Locale('ko')
  ];

  /// No description provided for @appTitle.
  ///
  /// In en, this message translates to:
  /// **'Football Training Log'**
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
  /// **'Today News'**
  String get tabNews;

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

  /// No description provided for @settings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settings;

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
  /// **'Backup to Google Drive'**
  String get backupToDrive;

  /// No description provided for @restoreFromDrive.
  ///
  /// In en, this message translates to:
  /// **'Restore from Google Drive'**
  String get restoreFromDrive;

  /// No description provided for @backupConfirm.
  ///
  /// In en, this message translates to:
  /// **'Create a new backup on Google Drive?'**
  String get backupConfirm;

  /// No description provided for @restoreConfirm.
  ///
  /// In en, this message translates to:
  /// **'Restore the latest backup from Google Drive? This will replace current data.'**
  String get restoreConfirm;

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
  /// **'Restore completed.'**
  String get restoreSuccess;

  /// No description provided for @restoreFailed.
  ///
  /// In en, this message translates to:
  /// **'Restore failed. Please try again.'**
  String get restoreFailed;

  /// No description provided for @backupInProgress.
  ///
  /// In en, this message translates to:
  /// **'Backing up...'**
  String get backupInProgress;

  /// No description provided for @restoreInProgress.
  ///
  /// In en, this message translates to:
  /// **'Restoring...'**
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
  /// **'Restore local backup'**
  String get restoreLocalBackup;

  /// No description provided for @restoreLocalConfirm.
  ///
  /// In en, this message translates to:
  /// **'Restore the backup saved before the last restore? This will replace current data.'**
  String get restoreLocalConfirm;

  /// No description provided for @restoreLocalSuccess.
  ///
  /// In en, this message translates to:
  /// **'Local restore completed.'**
  String get restoreLocalSuccess;

  /// No description provided for @restoreLocalFailed.
  ///
  /// In en, this message translates to:
  /// **'Local restore failed. Please try again.'**
  String get restoreLocalFailed;

  /// No description provided for @localBackup.
  ///
  /// In en, this message translates to:
  /// **'Local safety backup'**
  String get localBackup;

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

  /// No description provided for @diaryTitlePlaceholder.
  ///
  /// In en, this message translates to:
  /// **'Please enter a title'**
  String get diaryTitlePlaceholder;

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
  /// **'Recommended football outfit'**
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

  /// No description provided for @homeWeatherPm10.
  ///
  /// In en, this message translates to:
  /// **'PM10'**
  String get homeWeatherPm10;

  /// No description provided for @homeWeatherPm25.
  ///
  /// In en, this message translates to:
  /// **'PM2.5'**
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
  /// **'Unhealthy for sensitive groups'**
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

  /// No description provided for @homeWeatherSuggestionTitle.
  ///
  /// In en, this message translates to:
  /// **'Suggested training focus'**
  String get homeWeatherSuggestionTitle;

  /// No description provided for @homeWeatherSuggestionButton.
  ///
  /// In en, this message translates to:
  /// **'Training focus'**
  String get homeWeatherSuggestionButton;

  /// No description provided for @homeWeatherSuggestionClear.
  ///
  /// In en, this message translates to:
  /// **'Good time for outdoor first-touch work, passing rhythm, and short sprint sets.'**
  String get homeWeatherSuggestionClear;

  /// No description provided for @homeWeatherSuggestionCloudy.
  ///
  /// In en, this message translates to:
  /// **'Use the stable conditions for tactical pattern work and longer tempo drills.'**
  String get homeWeatherSuggestionCloudy;

  /// No description provided for @homeWeatherSuggestionRain.
  ///
  /// In en, this message translates to:
  /// **'Shift to indoor touches, wall passing, and balance or core work.'**
  String get homeWeatherSuggestionRain;

  /// No description provided for @homeWeatherSuggestionSnow.
  ///
  /// In en, this message translates to:
  /// **'Prioritize indoor coordination, mobility, and light technical repetitions.'**
  String get homeWeatherSuggestionSnow;

  /// No description provided for @homeWeatherSuggestionStorm.
  ///
  /// In en, this message translates to:
  /// **'Keep it safe with recovery, video review, and short indoor activation.'**
  String get homeWeatherSuggestionStorm;

  /// No description provided for @homeWeatherSuggestionHot.
  ///
  /// In en, this message translates to:
  /// **'Reduce volume, extend recovery, and focus on technique with hydration breaks.'**
  String get homeWeatherSuggestionHot;

  /// No description provided for @homeWeatherSuggestionCold.
  ///
  /// In en, this message translates to:
  /// **'Spend extra time warming up, then build intensity gradually with tight touches.'**
  String get homeWeatherSuggestionCold;

  /// No description provided for @homeWeatherSuggestionAirCaution.
  ///
  /// In en, this message translates to:
  /// **'Air quality is poor, so reduce outdoor load and switch to indoor technical or recovery work if possible.'**
  String get homeWeatherSuggestionAirCaution;

  /// No description provided for @homeWeatherSuggestionAirWatch.
  ///
  /// In en, this message translates to:
  /// **'If you train outside, shorten hard intervals and monitor your breathing because the air quality is not fully stable.'**
  String get homeWeatherSuggestionAirWatch;

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
  /// **'Drag to reorder them.'**
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
  /// **'Pin as sticker'**
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
  /// **'3 meals complete +15 XP'**
  String get mealXpFull;

  /// No description provided for @mealXpFullBonus.
  ///
  /// In en, this message translates to:
  /// **'3 meals complete + 5+ rice bowls +20 XP'**
  String get mealXpFullBonus;

  /// No description provided for @mealXpPartial.
  ///
  /// In en, this message translates to:
  /// **'2+ meals +5 XP'**
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
  /// **'Log meals today'**
  String get homeMealCoachRecordAction;

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
  /// **'Upload a short side-view running clip and get stricter feedback on posture, bounce, foot strike, knee flexion, and arm carriage.'**
  String get runningCoachHeroBody;

  /// No description provided for @runningCoachTipsTitle.
  ///
  /// In en, this message translates to:
  /// **'How to record'**
  String get runningCoachTipsTitle;

  /// No description provided for @runningCoachTipWholeBody.
  ///
  /// In en, this message translates to:
  /// **'Keep the full body in frame from head to ankle, with elbows and feet visible for the whole clip.'**
  String get runningCoachTipWholeBody;

  /// No description provided for @runningCoachTipSideView.
  ///
  /// In en, this message translates to:
  /// **'Record from the side while the runner moves across the frame.'**
  String get runningCoachTipSideView;

  /// No description provided for @runningCoachTipSteadyCamera.
  ///
  /// In en, this message translates to:
  /// **'Use a steady camera and capture 5-15 seconds of relaxed sprint or running form.'**
  String get runningCoachTipSteadyCamera;

  /// No description provided for @runningCoachLiveCardTitle.
  ///
  /// In en, this message translates to:
  /// **'Live coach'**
  String get runningCoachLiveCardTitle;

  /// No description provided for @runningCoachLiveCardBody.
  ///
  /// In en, this message translates to:
  /// **'Turn on the camera and the app will first correct framing, then coach posture, bounce, foot strike, knee bend, and arm carriage once the side view stabilizes.'**
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
  /// **'Keep the runner centered and the score out to the side'**
  String get runningCoachLiveGuideHeroTitle;

  /// No description provided for @runningCoachLiveGuideHeroBody.
  ///
  /// In en, this message translates to:
  /// **'The runner should stay inside the center frame while the app keeps score and coaching badges on the edges. Use the setup below for steadier live tracking.'**
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
  /// **'Leave space around the runner'**
  String get runningCoachLiveGuideTipHudTitle;

  /// No description provided for @runningCoachLiveGuideTipHudBody.
  ///
  /// In en, this message translates to:
  /// **'Scores and metrics sit on the outer edges of the screen. Keep the runner inside the center guide so the body is not covered.'**
  String get runningCoachLiveGuideTipHudBody;

  /// No description provided for @runningCoachLiveGuideTipCameraTitle.
  ///
  /// In en, this message translates to:
  /// **'Keep the camera fixed and the body large enough'**
  String get runningCoachLiveGuideTipCameraTitle;

  /// No description provided for @runningCoachLiveGuideTipCameraBody.
  ///
  /// In en, this message translates to:
  /// **'Hold the camera steady and frame the runner so the full body fills at least about half of the screen height.'**
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

  /// No description provided for @runningCoachSprintLiveCardTitle.
  ///
  /// In en, this message translates to:
  /// **'Sprint live MVP'**
  String get runningCoachSprintLiveCardTitle;

  /// No description provided for @runningCoachSprintLiveCardBody.
  ///
  /// In en, this message translates to:
  /// **'Connect the side-view camera directly so trunk lean, knee drive, step rhythm, arm balance, and session FPS/skip/visibility logs can be checked together on-device.'**
  String get runningCoachSprintLiveCardBody;

  /// No description provided for @runningCoachSprintLiveAction.
  ///
  /// In en, this message translates to:
  /// **'Start sprint MVP'**
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
  /// **'Session debug'**
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

  /// No description provided for @runningCoachMetricValueLabel.
  ///
  /// In en, this message translates to:
  /// **'Measured value'**
  String get runningCoachMetricValueLabel;

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
  /// **'Core joints are clipping near the edge, so overlay and feature values will drift.'**
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
  /// **'The main sprint features are inside the current MVP range, so the app is holding the current cue.'**
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

  /// No description provided for @headerEducationTooltip.
  ///
  /// In en, this message translates to:
  /// **'World Cup history book'**
  String get headerEducationTooltip;

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
  /// **'{count} straight days are alive'**
  String homeStreakActiveTodayTitle(int count);

  /// No description provided for @homeStreakActiveYesterdayTitle.
  ///
  /// In en, this message translates to:
  /// **'You logged {count} straight days through yesterday'**
  String homeStreakActiveYesterdayTitle(int count);

  /// No description provided for @homeStreakPausedTitle.
  ///
  /// In en, this message translates to:
  /// **'Your {count}-day streak paused for a moment'**
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
  /// **'Weekly flow'**
  String get homeStreakActionReview;

  /// No description provided for @educationScreenTitle.
  ///
  /// In en, this message translates to:
  /// **'Taeo\'s World Cup History Book'**
  String get educationScreenTitle;

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
  /// **'Swipe sideways to turn pages and scroll vertically inside each page.'**
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
  /// **'A World Cup Chronicle With Taeo'**
  String get educationBookCoverTitle;

  /// No description provided for @educationBookCoverSubtitle.
  ///
  /// In en, this message translates to:
  /// **'From Uruguay 1930 to a preview of North America 2026'**
  String get educationBookCoverSubtitle;

  /// No description provided for @educationBookCoverStory.
  ///
  /// In en, this message translates to:
  /// **'After training, Taeo stops in front of a shelf filled with old World Cup programmes. The moment he opens the first page, the port of Montevideo, the stands of the Maracana, the altitude of the Azteca, and the night sky above Lusail all connect into one book.\n\nThis volume does not cover all of football history. It follows only the men\'s FIFA World Cup, from the first tournament in 1930 to the most recently completed edition in Qatar in 2022, then adds a look ahead to the still-upcoming 2026 tournament in Canada, Mexico, and the United States. Taeo does not memorize only the champions. He reads who changed the era, which events shook the tournament, and why some scenes are still replayed decades later.\n\nBefore he turns another page, Taeo writes down 1930, 1950, 1958, 1970, 1986, 1998, 2002, 2010, 2018, 2022, and 2026. The first launch, the most famous shock, Pele\'s arrival, the golden Brazil side, Maradona\'s summer, the 32-team era, Korea\'s semifinal run, the first World Cup in Africa, the VAR era, Messi\'s completion, and the 48-team expansion make the whole map much easier to hold in one line.'**
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
  /// **'The first three World Cups began with long sea journeys'**
  String get educationBookOriginsTitle;

  /// No description provided for @educationBookOriginsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Uruguay 1930, Italy 1934, and France 1938'**
  String get educationBookOriginsSubtitle;

  /// No description provided for @educationBookOriginsStory.
  ///
  /// In en, this message translates to:
  /// **'In the first main chapter, Taeo meets a World Cup era when teams traveled by ship more often than by plane. European sides spent weeks crossing the Atlantic to reach Uruguay, while the hosts rushed to complete the Estadio Centenario as part of a centenary celebration. The World Cup began like an adventure story before it fully became a modern media event.\n\nUruguay beat Argentina 4-2 in the 1930 final and became the inaugural champions, while Guillermo Stabile of Argentina finished as the first top scorer. Yet the early years were never only romantic. Italy\'s 1934 tournament took place in the shadow of Mussolini\'s regime, and France 1938 was staged under the growing tension of a continent moving toward war.\n\nTaeo is struck by how quickly the World Cup already carried long-distance travel, political pressure, boycotts, and refereeing arguments. So when he studies the first three editions, he reads not only who lifted the trophy, but also how fast the competition moved into the middle of world history.'**
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
  /// **'The World Cup returned after war and built Brazil\'s golden age'**
  String get educationBookWorldCupTitle;

  /// No description provided for @educationBookWorldCupSubtitle.
  ///
  /// In en, this message translates to:
  /// **'From Brazil 1950 to Mexico 1970'**
  String get educationBookWorldCupSubtitle;

  /// No description provided for @educationBookWorldCupStory.
  ///
  /// In en, this message translates to:
  /// **'After the cancellations of 1942 and 1946, Brazil 1950 looked like the joyful return of world football. Taeo\'s first memory there, however, is not celebration but silence. Uruguay\'s win over Brazil in the decisive final group match created the Maracana shock and proved that the World Cup could also crush the dreams of a host nation in front of its own people.\n\nThe next pages are even more legendary. West Germany\'s Miracle of Bern in 1954, the arrival of 17-year-old Pele in 1958, Garrincha carrying Brazil in 1962 when Pele was hurt, England\'s only title in 1966, and the complete golden Brazil team of 1970 follow without pause.\n\nTaeo learns that this era is not just a list of winners. It is the age in which new heroes appeared, some countries took national scars, and some styles became the global reference for what great football should look like. He summarizes 1950 through 1970 with five words: restart, shock, genius, revenge, and completion.'**
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
  /// **'A new trophy, total football, and an age full of argument'**
  String get educationBookClubTitle;

  /// No description provided for @educationBookClubSubtitle.
  ///
  /// In en, this message translates to:
  /// **'From West Germany 1974 to Italy 1990'**
  String get educationBookClubSubtitle;

  /// No description provided for @educationBookClubStory.
  ///
  /// In en, this message translates to:
  /// **'From 1974 onward, Taeo sees a new trophy. The Netherlands, led by Johan Cruyff, played total football with constant movement and position exchange, only for West Germany and Franz Beckenbauer to stop that revolution in the final. The World Cup looked like a laboratory where beautiful ideas and cold realism collided in public.\n\nYet this period can never be explained by football alone. Argentina 1978 was played under the shadow of a military dictatorship. Spain 1982 is remembered both for Paolo Rossi\'s return and for the violent collision and shootout drama of France against West Germany. Then Mexico 1986 pushed Diego Maradona to the top of World Cup mythology when he left both the Hand of God and the solo goal past five players in the same campaign.\n\nBy the time Taeo reaches Italy 1990, he understands how emotionally crowded the World Cup can be. Roger Milla\'s dancing, Beckenbauer winning as a coach, and Maradona crying after defeat in the final all live in the same stretch of history. He writes down this era as a blend of tactical innovation, political shadows, superhuman skill, and permanent debate.'**
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
  /// **'A globalized World Cup and finals that felt like theater'**
  String get educationBookTacticsTitle;

  /// No description provided for @educationBookTacticsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'USA 1994, France 1998, Korea and Japan 2002, Germany 2006'**
  String get educationBookTacticsSubtitle;

  /// No description provided for @educationBookTacticsStory.
  ///
  /// In en, this message translates to:
  /// **'By USA 1994, Taeo feels that the World Cup has fully become a global mega-event. Enormous American stadiums, Romario\'s smile, and Roberto Baggio\'s shot flying over the bar in the shootout all belong to the same memory. The tournament proved that the World Cup could become enormous even in a country where football was not the main sport.\n\nFrance 1998 opened the 32-team era and left behind Zinedine Zidane\'s two headed goals in the final together with the mystery and tension around Ronaldo\'s physical condition before kickoff. Korea and Japan 2002 brought Korea\'s semifinal run, Guus Hiddink\'s leadership, scenes from Ahn Jung-hwan and Park Ji-sung, and Ronaldo\'s eight-goal redemption arc into one unforgettable tournament.\n\nGermany 2006 restored the smile of a football festival, but the final ended with Zidane\'s headbutt turning the whole emotional weather of the night. Taeo learns that as the World Cup grows bigger, the drama grows with it. He summarizes 1994 through 2006 as globalization, expansion, Korea\'s summer, and one final reversal.'**
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
  /// **'The data era, and Messi\'s final completion'**
  String get educationBookLegendsTitle;

  /// No description provided for @educationBookLegendsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'From South Africa 2010 to Qatar 2022'**
  String get educationBookLegendsSubtitle;

  /// No description provided for @educationBookLegendsStory.
  ///
  /// In en, this message translates to:
  /// **'When Taeo opens the 2010 South Africa chapter, he hears vuvuzelas before anything else. The first men\'s World Cup on African soil looked and sounded different from the start, and Spain completed its era through Andres Iniesta\'s extra-time winner in the final. The same tournament also gave him Luis Suarez\'s goal-line handball against Ghana and even the bizarre fame of Paul the Octopus, proving once more that the World Cup can be serious history and internet folklore at the same time.\n\nBrazil 2014 left the Mineirazo, Germany\'s 7-1 destruction of the host nation, and Miroslav Klose\'s 16th career World Cup goal. Russia 2018 delivered Kylian Mbappe\'s breakout, France\'s second title, Croatia\'s exhausting run through extra time, and the first full use of VAR in a men\'s World Cup.\n\nThen Qatar 2022 gave Taeo Messi\'s title at last. Morocco became the first African semi-finalist, Argentina and France played one of the wildest finals the tournament has ever seen, Mbappe scored a hat-trick in defeat, and Emiliano Martinez made the save that helped close the story. Taeo realizes that some World Cups finish a career, while others reset what an entire continent believes is possible.'**
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
  /// **'How to remember the World Cup through people'**
  String get educationBookAsiaTitle;

  /// No description provided for @educationBookAsiaSubtitle.
  ///
  /// In en, this message translates to:
  /// **'From Jules Rimet to Pele, Maradona, Beckenbauer, and Messi'**
  String get educationBookAsiaSubtitle;

  /// No description provided for @educationBookAsiaStory.
  ///
  /// In en, this message translates to:
  /// **'At some point, Taeo realizes he no longer remembers the World Cup only through years. He starts to remember it through people. Jules Rimet, who pushed the tournament into existence. Vittorio Pozzo, who won two straight titles. Pele, who won three. Beckenbauer, who reached the summit as both player and coach. Maradona, who turned one World Cup into an entire mythology.\n\nThis chapter is not filled only with heroes. Garrincha carried a hurt Brazil side in 1962. Ronaldo turned the pain of one final into redemption four years later. Zidane left both genius and explosion behind. Messi finally closed the last open chapter in his own story. Taeo understands that the World Cup is where human narratives become loudest.\n\nThat is why he refuses to memorize names by themselves. Pele means 1958 and 1970. Maradona means England in 1986. Beckenbauer means 1974 and 1990. Ronaldo means 2002. Messi means 2022. A name only becomes history once the year and the scene are attached to it.'**
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
  /// **'Upsets, arguments, and the stories beyond the pitch'**
  String get educationBookWomenTitle;

  /// No description provided for @educationBookWomenSubtitle.
  ///
  /// In en, this message translates to:
  /// **'War, dictatorship, a stolen trophy, and technological review'**
  String get educationBookWomenSubtitle;

  /// No description provided for @educationBookWomenStory.
  ///
  /// In en, this message translates to:
  /// **'This chapter teaches Taeo that a World Cup history book explains only half the truth if it lists nothing but champions. Some tournaments never happened because of war. Some were played under dictatorships. In others, the off-field events became almost as famous as the football itself. The World Cup always absorbs the air of the wider world.\n\nIn 1966, the Jules Rimet Trophy was stolen before the tournament opened and later found by a dog called Pickles. In 1982, the Battiston collision left a lasting argument about sportsmanship. In 2010, Frank Lampard\'s disallowed goal pushed the demand for technology harder. By the time Taeo reaches goal-line technology in 2014, VAR in 2018, and semi-automated offside in 2022, he understands that the World Cup is also a history of how football tries to judge itself.\n\nSo Taeo starts writing down two questions for every tournament. Who won on the pitch, and what changed outside it? He feels that only by keeping both questions together can a real history book exist.'**
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
  /// **'The next page is 2026, Taeo\'s prediction notebook'**
  String get educationBookModernTitle;

  /// No description provided for @educationBookModernSubtitle.
  ///
  /// In en, this message translates to:
  /// **'What a 48-team World Cup may change'**
  String get educationBookModernSubtitle;

  /// No description provided for @educationBookModernStory.
  ///
  /// In en, this message translates to:
  /// **'In the final main chapter, Taeo looks at the still-unplayed 2026 World Cup in North America. A 48-team field, 104 matches, and a three-country host setup already make it feel different from previous tournaments. The longer schedule suggests that squad depth, recovery management, and adaptation to long travel will matter more than ever.\n\nInstead of naming a champion too quickly, Taeo writes down the conditions that usually favor one. A midfield that can press and build, set-piece detail that can decide a tight knockout match, goal output spread beyond one star, and a coaching staff that can analyze unfamiliar opponents quickly all feel more valuable in an expanded event. Traditional powers will still be powerful, but a 48-team structure may also create more strange paths and more dark horses.\n\nSo Taeo treats 2026 less like a guessing game and more like an exercise in observation. He wonders which of the three host nations will go furthest, which South American and European powers will define the new standard, and which Asian or African side might push the ceiling higher again.'**
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
  /// **'Taeo\'s final bookmark'**
  String get educationBookFinaleTitle;

  /// No description provided for @educationBookFinaleSubtitle.
  ///
  /// In en, this message translates to:
  /// **'How to tie together 1930 and 2026 in one line'**
  String get educationBookFinaleSubtitle;

  /// No description provided for @educationBookFinaleStory.
  ///
  /// In en, this message translates to:
  /// **'After closing the final page, Taeo realizes that the World Cup is really a giant summary written once every four years. Players sailing to Uruguay and modern stars playing under satellite cameras and VAR all belong to the same tournament line.\n\nSome eras are remembered through giants such as Pele, Maradona, and Messi. Some are remembered through scores like the Maracana shock or 7-1. Others survive because of a stolen trophy, war, or arguments over technology. Taeo concludes that reading World Cup history is not simple memorization. It is training the eye to read world history through the language of one competition.\n\nSo before he puts the book away, he repeats 1930, 1950, 1958, 1970, 1986, 1998, 2002, 2010, 2018, 2022, and 2026 in order one more time. If the year, host, leading figures, and defining event all rise together in his head, he believes every future match will feel much deeper.'**
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
      <String>['en', 'ko'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'ko':
      return AppLocalizationsKo();
  }

  throw FlutterError(
      'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
      'an issue with the localizations generation tool. Please file an issue '
      'on GitHub with a reproducible sample app and the gen-l10n configuration '
      'that was used.');
}
