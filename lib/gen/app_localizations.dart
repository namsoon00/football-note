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

  /// No description provided for @fortuneDialogSubtitle.
  ///
  /// In en, this message translates to:
  /// **'A short reading for today.'**
  String get fortuneDialogSubtitle;

  /// No description provided for @mealStatsNoTrainingOrMealEntries.
  ///
  /// In en, this message translates to:
  /// **'No training or meal entries in the selected period.'**
  String get mealStatsNoTrainingOrMealEntries;
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
