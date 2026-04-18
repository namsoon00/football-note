// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Football Training Log';

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
  String get tabNews => 'Today News';

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
  String get filterReset => 'Reset';

  @override
  String get filterApply => 'Apply';

  @override
  String get deleteEntry => 'Delete Entry';

  @override
  String get deleteConfirm => 'Delete this entry?';

  @override
  String get cancel => 'Cancel';

  @override
  String get delete => 'Delete';

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
  String get settings => 'Settings';

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
  String get backupToDrive => 'Backup to Google Drive';

  @override
  String get restoreFromDrive => 'Restore from Google Drive';

  @override
  String get backupConfirm => 'Create a new backup on Google Drive?';

  @override
  String get restoreConfirm =>
      'Restore the latest backup from Google Drive? This will replace current data.';

  @override
  String get backupSuccess => 'Backup completed.';

  @override
  String get backupFailed => 'Backup failed. Please try again.';

  @override
  String get restoreSuccess => 'Restore completed.';

  @override
  String get restoreFailed => 'Restore failed. Please try again.';

  @override
  String get backupInProgress => 'Backing up...';

  @override
  String get restoreInProgress => 'Restoring...';

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
  String get restoreLocalBackup => 'Restore local backup';

  @override
  String get restoreLocalConfirm =>
      'Restore the backup saved before the last restore? This will replace current data.';

  @override
  String get restoreLocalSuccess => 'Local restore completed.';

  @override
  String get restoreLocalFailed => 'Local restore failed. Please try again.';

  @override
  String get localBackup => 'Local safety backup';

  @override
  String get loginRequired => 'Please sign in to Google to use Drive backup.';

  @override
  String get signOutDone => 'Signed out.';

  @override
  String get voiceNotAvailable =>
      'Voice input is not available on this device.';

  @override
  String get liftingRecord => 'Lifting Record';

  @override
  String get liftingByPart => 'Lifting (reps by part)';

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
  String get diaryTitlePlaceholder => 'Please enter a title';

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
  String get homeWeatherLocationUnknown => 'Current location';

  @override
  String get homeWeatherCountryKorea => 'Korea';

  @override
  String get homeWeatherDetailsTitle => 'Weather details';

  @override
  String get homeWeatherDetailsSubtitle =>
      'Check local weather and air quality for your current location.';

  @override
  String get homeWeatherTomorrowTitle => 'Tomorrow\'s weather';

  @override
  String get homeWeatherWeeklyTitle => 'Weekly weather';

  @override
  String get homeWeatherCacheHint =>
      'Recently fetched weather is reused for 10 minutes.';

  @override
  String get homeWeatherDailyHighLow => 'High/Low';

  @override
  String get homeWeatherTomorrowFallback =>
      'Tomorrow\'s forecast is not available yet.';

  @override
  String get homeWeatherTemperatureRange => 'High/Low';

  @override
  String get homeWeatherFeelsLike => 'Feels like';

  @override
  String get homeWeatherHumidity => 'Humidity';

  @override
  String get homeWeatherPrecipitation => 'Precipitation';

  @override
  String get homeWeatherWindSpeed => 'Wind';

  @override
  String get homeWeatherUvIndex => 'UV index';

  @override
  String get homeWeatherOutfitTitle => 'Recommended football outfit';

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
  String get homeWeatherOutfitLayersLabel => 'Layers';

  @override
  String get homeWeatherOutfitOuterLabel => 'Outerwear';

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
      'Review each weather band with layer, bottom, and accessory details.';

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
  String get homeWeatherAirQualityTitle => 'Air quality';

  @override
  String get homeWeatherAirQualitySubtitle =>
      'Lower numbers usually mean easier breathing outdoors.';

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
      'Sensitive groups should reduce long outdoor sessions and hard efforts.';

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
  String get homeWeatherComparedYesterday => 'Vs. yesterday at this time';

  @override
  String get homeWeatherPm10 => 'PM10';

  @override
  String get homeWeatherPm25 => 'PM2.5';

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
  String get homeWeatherStatusSensitive => 'Unhealthy for sensitive groups';

  @override
  String get homeWeatherStatusUnhealthy => 'Unhealthy';

  @override
  String get homeWeatherStatusVeryUnhealthy => 'Very unhealthy';

  @override
  String get homeWeatherStatusHazardous => 'Hazardous';

  @override
  String get homeWeatherSuggestionTitle => 'Suggested training focus';

  @override
  String get homeWeatherSuggestionButton => 'Training focus';

  @override
  String get homeWeatherSuggestionClear =>
      'Good time for outdoor first-touch work, passing rhythm, and short sprint sets.';

  @override
  String get homeWeatherSuggestionCloudy =>
      'Use the stable conditions for tactical pattern work and longer tempo drills.';

  @override
  String get homeWeatherSuggestionRain =>
      'Shift to indoor touches, wall passing, and balance or core work.';

  @override
  String get homeWeatherSuggestionSnow =>
      'Prioritize indoor coordination, mobility, and light technical repetitions.';

  @override
  String get homeWeatherSuggestionStorm =>
      'Keep it safe with recovery, video review, and short indoor activation.';

  @override
  String get homeWeatherSuggestionHot =>
      'Reduce volume, extend recovery, and focus on technique with hydration breaks.';

  @override
  String get homeWeatherSuggestionCold =>
      'Spend extra time warming up, then build intensity gradually with tight touches.';

  @override
  String get homeWeatherSuggestionAirCaution =>
      'Air quality is poor, so reduce outdoor load and switch to indoor technical or recovery work if possible.';

  @override
  String get homeWeatherSuggestionAirWatch =>
      'If you train outside, shorten hard intervals and monitor your breathing because the air quality is not fully stable.';

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
  String get diaryStickerFortune => 'Fortune';

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
  String get quizWrongAnswerTimeout => 'Timed out';

  @override
  String get quizWrongAnswerRevealed => 'Revealed the answer';

  @override
  String get quizWrongAnswerSkipped => 'No answer selected';

  @override
  String get quizWrongAnswerEmpty => 'No input';

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
  String get diarySelectedRecordStickersHint => 'Drag to reorder them.';

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
  String get diaryRecordStickerPin => 'Pin as sticker';

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
  String get mealXpFull => '3 meals complete +15 XP';

  @override
  String get mealXpFullBonus => '3 meals complete + 5+ rice bowls +20 XP';

  @override
  String get mealXpPartial => '2+ meals +5 XP';

  @override
  String get mealXpNeutral => 'One meal or less gives no bonus';

  @override
  String get homeMealCoachTitle => 'Meal coach';

  @override
  String get homeMealCoachRecordAction => 'Log meals today';

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
  String get mealSaveAction => 'Save meal log';

  @override
  String get mealDeleteAction => 'Delete meal log';

  @override
  String get mealDeleteConfirmBody => 'Delete this day\'s meal log?';

  @override
  String get mealSavedFeedback => 'Meal log saved.';

  @override
  String get mealDeletedFeedback => 'Meal log deleted.';

  @override
  String get mealLogXpSourceLabel => 'Meal log';

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
  String get fortuneDialogTitle => 'Today fortune';

  @override
  String get fortuneDialogSubtitle => 'Check today lucky info.';

  @override
  String get fortuneDialogOverviewTitle => 'Fortune overview';

  @override
  String get fortuneDialogOverallFortuneLabel => 'Overall fortune';

  @override
  String get fortuneDialogLuckyInfoLabel => 'Lucky info';

  @override
  String fortuneDialogOverallFortuneCount(int count) {
    return '$count lines';
  }

  @override
  String fortuneDialogLuckyInfoCount(int count) {
    return '$count items';
  }

  @override
  String get fortuneDialogLuckyInfoTitle => 'Lucky info';

  @override
  String get fortuneDialogPoolSizeLabel => 'Fortune pool';

  @override
  String fortuneDialogPoolSizeCount(String count) {
    return '$count cases';
  }

  @override
  String get fortuneDialogRecommendedProgramTitle => 'Recommended training';

  @override
  String get fortuneDialogRecommendationTitle => 'Fortune note';

  @override
  String get fortuneDialogEncouragement => 'Cheering for your best play today.';

  @override
  String get fortuneDialogAction => 'Nice';

  @override
  String get mealStatsNoTrainingOrMealEntries =>
      'No training or meal entries in the selected period.';

  @override
  String get drawerRunningCoach => 'Running Coach';

  @override
  String get runningCoachScreenTitle => 'Running Coach';

  @override
  String get runningCoachHeroTitle => 'Side-view running form coach';

  @override
  String get runningCoachHeroBody =>
      'Upload a short side-view running clip and get stricter feedback on posture, bounce, foot strike, knee flexion, and arm carriage.';

  @override
  String get runningCoachTipsTitle => 'How to record';

  @override
  String get runningCoachTipWholeBody =>
      'Keep the full body in frame from head to ankle, with elbows and feet visible for the whole clip.';

  @override
  String get runningCoachTipSideView =>
      'Record from the side while the runner moves across the frame.';

  @override
  String get runningCoachTipSteadyCamera =>
      'Use a steady camera and capture 5-15 seconds of relaxed sprint or running form.';

  @override
  String get runningCoachLiveCardTitle => 'Live coach';

  @override
  String get runningCoachLiveCardBody =>
      'Turn on the camera and the app will first correct framing, then coach posture, bounce, foot strike, knee bend, and arm carriage once the side view stabilizes.';

  @override
  String get runningCoachLiveAction => 'Start live coach';

  @override
  String get runningCoachLiveGuideAction => 'Shooting guide';

  @override
  String get runningCoachLiveScreenTitle => 'Live running coach';

  @override
  String get runningCoachLiveGuideScreenTitle => 'Live shooting guide';

  @override
  String get runningCoachLiveGuideHeroTitle =>
      'Keep the runner centered and the score out to the side';

  @override
  String get runningCoachLiveGuideHeroBody =>
      'The runner should stay inside the center frame while the app keeps score and coaching badges on the edges. Use the setup below for steadier live tracking.';

  @override
  String get runningCoachLiveGuideTipSideTitle => 'Show a side view';

  @override
  String get runningCoachLiveGuideTipSideBody =>
      'The runner should move across the frame from the side, not straight toward the camera or on a heavy diagonal.';

  @override
  String get runningCoachLiveGuideTipBodyTitle => 'Keep the full body in frame';

  @override
  String get runningCoachLiveGuideTipBodyBody =>
      'The head, elbows, hips, and ankles all need to stay visible so the pose line and score can stay stable.';

  @override
  String get runningCoachLiveGuideTipHudTitle =>
      'Leave space around the runner';

  @override
  String get runningCoachLiveGuideTipHudBody =>
      'Scores and metrics sit on the outer edges of the screen. Keep the runner inside the center guide so the body is not covered.';

  @override
  String get runningCoachLiveGuideTipCameraTitle =>
      'Keep the camera fixed and the body large enough';

  @override
  String get runningCoachLiveGuideTipCameraBody =>
      'Hold the camera steady and frame the runner so the full body fills at least about half of the screen height.';

  @override
  String get runningCoachLivePreparingTitle => 'Preparing camera';

  @override
  String get runningCoachLivePreparingBody =>
      'Opening the rear camera and getting live pose tracking ready.';

  @override
  String get runningCoachLiveCameraIssueTitle => 'Camera check needed';

  @override
  String get runningCoachLiveCameraDenied =>
      'Camera access is required for live running coaching.';

  @override
  String get runningCoachLiveCameraFailed =>
      'The live coach camera could not be opened. Try again.';

  @override
  String get runningCoachLiveRetryAction => 'Try again';

  @override
  String get runningCoachLiveVoiceOn => 'Voice coaching on';

  @override
  String get runningCoachLiveVoiceOff => 'Voice coaching off';

  @override
  String get runningCoachLiveSwitchCamera => 'Switch camera';

  @override
  String get runningCoachLiveStatusFraming => 'Fix the framing first';

  @override
  String get runningCoachLiveStatusCollecting => 'Collecting movement';

  @override
  String get runningCoachLiveStatusCoaching => 'Live coaching active';

  @override
  String get runningCoachLiveCueNoRunner =>
      'The runner is not clear enough yet. Step into the frame.';

  @override
  String get runningCoachLiveCueStepBack =>
      'Step back and fit the whole body in frame from head to toe.';

  @override
  String get runningCoachLiveCueMoveCloser =>
      'The runner looks too small. Move a bit closer to the camera.';

  @override
  String get runningCoachLiveCueCenterRunner =>
      'Center the runner more clearly in the frame.';

  @override
  String get runningCoachLiveCueTurnSideways =>
      'Turn more to the side so the running shape is easier to read.';

  @override
  String get runningCoachLiveCueKeepRunning =>
      'Good. Keep the same rhythm for a few more steps and coaching will appear.';

  @override
  String get runningCoachLiveCueLookingGood =>
      'Good. Keep this rhythm and hold the same shape.';

  @override
  String runningCoachLiveTrackedFrames(int count) {
    return 'Tracked frames $count';
  }

  @override
  String get runningCoachLiveScorePending => 'Scoring...';

  @override
  String runningCoachLiveOverallScore(int score) {
    return 'Live score $score/100';
  }

  @override
  String get runningCoachSprintLiveCardTitle => 'Sprint live MVP';

  @override
  String get runningCoachSprintLiveCardBody =>
      'Connect the side-view camera directly so trunk lean, knee drive, step rhythm, arm balance, and session FPS/skip/visibility logs can be checked together on-device.';

  @override
  String get runningCoachSprintLiveAction => 'Start sprint MVP';

  @override
  String get runningCoachSprintLiveScreenTitle => 'Live sprint coaching';

  @override
  String get runningCoachSprintLiveStatusLowConfidence =>
      'Fix full-body framing first';

  @override
  String get runningCoachSprintLiveStatusCollecting =>
      'Stabilizing sprint rhythm';

  @override
  String get runningCoachSprintLiveStatusReady => 'Live feedback ready';

  @override
  String get runningCoachSprintLiveStatusCoaching =>
      'Live sprint feedback active';

  @override
  String get runningCoachSprintLiveCueCollecting =>
      'Hold a few more steps so rhythm and knee-drive readings can settle.';

  @override
  String get runningCoachSprintLiveCueReady =>
      'Good. Keep this shape and sprint for another 5-10 seconds.';

  @override
  String get runningCoachSprintGuideSideCapture => 'Keep a clear side view';

  @override
  String get runningCoachSprintGuideFullBodyFraming =>
      'Keep the full body inside the frame';

  @override
  String runningCoachSprintTrackingConfidenceValue(int percent) {
    return 'Tracking $percent%';
  }

  @override
  String runningCoachSprintTrackedFrames(int count) {
    return 'Tracked $count frames';
  }

  @override
  String runningCoachSprintDetectedSteps(int count) {
    return 'Step events $count';
  }

  @override
  String get runningCoachSprintSessionLogTitle => 'Session debug';

  @override
  String get runningCoachSprintSessionCameraFpsLabel => 'Camera input FPS';

  @override
  String get runningCoachSprintSessionAnalyzedFpsLabel => 'Analyzed FPS';

  @override
  String get runningCoachSprintSessionAverageProcessingLabel =>
      'Avg processing';

  @override
  String runningCoachSprintSessionAverageProcessingValue(Object ms) {
    return '${ms}ms';
  }

  @override
  String get runningCoachSprintSessionSkippedFramesLabel => 'Dropped / skipped';

  @override
  String runningCoachSprintSessionSkippedFramesValue(int count) {
    return '$count frames';
  }

  @override
  String get runningCoachSprintSessionBodyNotVisibleLabel => 'Body loss ratio';

  @override
  String runningCoachSprintSessionBodyNotVisibleValue(int percent) {
    return '$percent%';
  }

  @override
  String get runningCoachSprintSessionBodyVisibilityLabel => 'Body visibility';

  @override
  String runningCoachSprintSessionBodyVisibilityValue(
      Object status, int visible, int total, int percent) {
    return '$status · core $visible/$total · $percent%';
  }

  @override
  String get runningCoachSprintSessionActiveFeedbackLabel => 'Active feedback';

  @override
  String runningCoachSprintSessionActiveFeedbackValue(Object key, Object text) {
    return '$key · $text';
  }

  @override
  String get runningCoachSprintSessionFeedbackEmpty => 'Waiting';

  @override
  String get runningCoachSprintSessionFeedbackChangesLabel =>
      'Feedback changes';

  @override
  String runningCoachSprintSessionFeedbackChangesValue(
      int count, Object perMinute, int suppressed) {
    return '$count changes / $perMinute per min · cooldown holds $suppressed';
  }

  @override
  String get runningCoachSprintSessionReadinessLabel => 'Readiness';

  @override
  String runningCoachSprintSessionReadinessValue(
      int visible, int missing, int stable, Object travel) {
    return 'visible $visible · miss $missing · stable $stable · travel $travel';
  }

  @override
  String get runningCoachSprintSessionStepDetectorLabel => 'Step detector';

  @override
  String runningCoachSprintSessionStepDetectorValue(
      int switches, int accepted, int lowVelocity, int minInterval) {
    return 'switch $switches · ok $accepted · lowV $lowVelocity · gap $minInterval';
  }

  @override
  String get runningCoachSprintSessionConfidenceLabel => 'Landmark confidence';

  @override
  String runningCoachSprintSessionConfidenceValue(
      int high, int medium, int low) {
    return '0.8+ $high% · 0.6-0.8 $medium% · <0.6 $low%';
  }

  @override
  String get runningCoachSprintMetricPending => '--';

  @override
  String get runningCoachSprintMetricTrunkLabel => 'Trunk lean';

  @override
  String runningCoachSprintMetricTrunkValue(Object value) {
    return '$value°';
  }

  @override
  String get runningCoachSprintMetricKneeDriveLabel => 'Knee drive';

  @override
  String runningCoachSprintMetricKneeDriveValue(Object value) {
    return 'Scale $value%';
  }

  @override
  String get runningCoachSprintMetricCadenceLabel => 'Cadence';

  @override
  String runningCoachSprintMetricCadenceValue(Object value) {
    return '$value spm';
  }

  @override
  String get runningCoachSprintMetricRhythmLabel => 'Rhythm drift';

  @override
  String runningCoachSprintMetricRhythmValue(Object value) {
    return '${value}ms';
  }

  @override
  String get runningCoachSprintMetricArmBalanceLabel => 'Arm balance';

  @override
  String runningCoachSprintMetricArmBalanceValue(Object value) {
    return 'Gap $value%';
  }

  @override
  String get runningCoachSprintBodyVisibilityFull => 'Full body locked';

  @override
  String get runningCoachSprintBodyVisibilityPartial => 'Partial landmarks';

  @override
  String get runningCoachSprintBodyVisibilityNotVisible => 'Body lost';

  @override
  String get runningCoachSprintCueBodyVisible =>
      'Adjust one more step so the full body stays inside the frame.';

  @override
  String get runningCoachSprintCueLeanForward =>
      'Keep the lean slightly more forward from the ankles, not by folding at the waist.';

  @override
  String get runningCoachSprintCueDriveKnee =>
      'After the push-off, drive the knee forward a little more aggressively.';

  @override
  String get runningCoachSprintCueKeepRhythm =>
      'The left-right rhythm is drifting. Try to keep the ground contacts more even.';

  @override
  String get runningCoachSprintCueBalanceArms =>
      'The arm swing is unbalanced. Match the backward drive on both sides more closely.';

  @override
  String get runningCoachSprintCueKeepPushing =>
      'Good. Keep pushing with the same rhythm and forward lean.';

  @override
  String get runningCoachSelectedVideoLabel => 'Selected video';

  @override
  String get runningCoachNoVideoSelected => 'No video selected yet.';

  @override
  String get runningCoachPickVideoAction => 'Pick video';

  @override
  String get runningCoachAnalyzeAction => 'Analyze run';

  @override
  String get runningCoachAnalysisInProgress => 'Analyzing...';

  @override
  String get runningCoachPickVideoFailed => 'Could not open the video picker.';

  @override
  String get runningCoachUnsupportedPlatform =>
      'Running video analysis is available only on Android and iPhone/iPad app builds.';

  @override
  String get runningCoachNativeAnalyzerUnavailable =>
      'This app build does not include the running video analyzer yet. Reinstall the latest mobile app build and try again.';

  @override
  String get runningCoachVideoFileMissing =>
      'The selected video file could not be found.';

  @override
  String get runningCoachVideoTooShort =>
      'The video is too short. Record at least a few running steps.';

  @override
  String get runningCoachNoPoseDetected =>
      'The runner could not be tracked well enough. Try a clearer side-view clip with elbows, knees, and feet visible.';

  @override
  String get runningCoachAnalysisFailedGeneric =>
      'Running analysis failed. Try another clip with a clearer side view.';

  @override
  String get runningCoachResultsTitle => 'Coaching results';

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
  String get runningCoachDurationLabel => 'Clip';

  @override
  String get runningCoachFramesAnalyzedLabel => 'Frames';

  @override
  String get runningCoachCoverageLabel => 'Coverage';

  @override
  String get runningCoachMetricValueLabel => 'Measured value';

  @override
  String get runningCoachStatusGood => 'Good';

  @override
  String get runningCoachStatusWatch => 'Watch';

  @override
  String get runningCoachStatusNeedsWork => 'Needs work';

  @override
  String runningCoachLeanValue(Object value) {
    return '$value° forward lean';
  }

  @override
  String runningCoachBounceValue(Object value) {
    return '$value% vertical bounce';
  }

  @override
  String runningCoachFootStrikeValue(Object value) {
    return '${value}x ahead of hips';
  }

  @override
  String runningCoachKneeValue(Object value) {
    return '$value° support knee angle';
  }

  @override
  String runningCoachArmValue(Object value) {
    return '$value° elbow angle';
  }

  @override
  String runningCoachStrideValue(Object value) {
    return '${value}x stride reach';
  }

  @override
  String get runningCoachInsightPostureTitle => 'Posture';

  @override
  String get runningCoachPostureGoodSummary =>
      'Your body angle is close to a clean sprint posture with a slight forward lean.';

  @override
  String get runningCoachPostureGoodCue =>
      'Keep the chest tall and let the whole body fall forward together.';

  @override
  String get runningCoachPostureGoodDrill =>
      'Drill: 2 x 15m wall-lean marches to lock in the same body line.';

  @override
  String get runningCoachPostureUprightSummary =>
      'Your torso stays too upright, so you may be losing forward intent on each step.';

  @override
  String get runningCoachPostureUprightCue =>
      'Think \"nose over toes\" and let the lean come from the ankles, not the waist.';

  @override
  String get runningCoachPostureUprightDrill =>
      'Drill: 2 x 15m falling starts, then 2 x 15m wall-lean marches.';

  @override
  String get runningCoachPostureLeanSummary =>
      'Your torso is leaning too much, which can make the stride collapse and slow recovery.';

  @override
  String get runningCoachPostureLeanCue =>
      'Run tall through the hips and keep the ribs stacked over the pelvis.';

  @override
  String get runningCoachPostureLeanDrill =>
      'Drill: 2 x 20m tall posture runs with light quick steps.';

  @override
  String get runningCoachInsightBounceTitle => 'Bounce';

  @override
  String get runningCoachBounceGoodSummary =>
      'Your vertical movement looks controlled, which helps keep energy moving forward.';

  @override
  String get runningCoachBounceGoodCue =>
      'Keep pushing backward into the ground instead of bouncing upward.';

  @override
  String get runningCoachBounceGoodDrill =>
      'Drill: 2 x 20m ankle dribbles before your next sprint set.';

  @override
  String get runningCoachBounceHighSummary =>
      'There is extra up-and-down bounce in the clip, which can waste energy.';

  @override
  String get runningCoachBounceHighCue =>
      'Think quick contacts and push the ground behind you, not straight down.';

  @override
  String get runningCoachBounceHighDrill =>
      'Drill: 3 x 20m ankle dribbles and straight-leg runs with short contacts.';

  @override
  String get runningCoachInsightFootStrikeTitle => 'Foot strike';

  @override
  String get runningCoachFootStrikeGoodSummary =>
      'The lead foot is landing close enough to the hips that the step can keep rolling forward.';

  @override
  String get runningCoachFootStrikeGoodCue =>
      'Keep landing under the hips and let speed come from push-off, not reaching.';

  @override
  String get runningCoachFootStrikeGoodDrill =>
      'Drill: 2 x 20m wicket-style runs with short, quick contacts.';

  @override
  String get runningCoachFootStrikeOverSummary =>
      'The lead foot is reaching too far in front of the hips, which can create braking at contact.';

  @override
  String get runningCoachFootStrikeOverCue =>
      'Bring the landing point back under the hips and think push back, not reach forward.';

  @override
  String get runningCoachFootStrikeOverDrill =>
      'Drill: 2 x 20m A-march plus 2 x 20m wicket-style runs with shorter contacts.';

  @override
  String get runningCoachInsightKneeTitle => 'Knee flexion';

  @override
  String get runningCoachKneeGoodSummary =>
      'The support knee is bending enough to stay springy without collapsing.';

  @override
  String get runningCoachKneeGoodCue =>
      'Keep the stance leg soft and reactive instead of locking on landing.';

  @override
  String get runningCoachKneeGoodDrill =>
      'Drill: 2 x 20m pogo runs, then 2 x 20m dribble runs.';

  @override
  String get runningCoachKneeStraightSummary =>
      'The support knee is landing too straight, which can make the step look stiff and heavy.';

  @override
  String get runningCoachKneeStraightCue =>
      'Soften the landing knee and let the leg accept the ground under the hips.';

  @override
  String get runningCoachKneeStraightDrill =>
      'Drill: 2 x 20m dribble runs with bent-knee contacts and quick steps.';

  @override
  String get runningCoachKneeCollapseSummary =>
      'The support knee is folding too much after contact, so the stance leg is losing stiffness.';

  @override
  String get runningCoachKneeCollapseCue =>
      'Stay springy through the stance leg and keep the hips stacked over the foot.';

  @override
  String get runningCoachKneeCollapseDrill =>
      'Drill: 2 x 15m single-leg pogo hops per side, then 2 x 20m dribble runs.';

  @override
  String get runningCoachInsightArmTitle => 'Arm carriage';

  @override
  String get runningCoachArmGoodSummary =>
      'Your elbows stay in a compact range that supports rhythm without over-tensing the upper body.';

  @override
  String get runningCoachArmGoodCue =>
      'Keep the elbows bent and let the hands travel front to back with the same rhythm as the legs.';

  @override
  String get runningCoachArmGoodDrill =>
      'Drill: 2 x 20s wall arm switches, then 2 x 20m arm-drive marches.';

  @override
  String get runningCoachArmOpenSummary =>
      'Your elbows are opening too much, so the arms may be leaking rhythm instead of helping it.';

  @override
  String get runningCoachArmOpenCue =>
      'Keep the elbows more bent and drive the hands back past the hips instead of reaching long.';

  @override
  String get runningCoachArmOpenDrill =>
      'Drill: 2 x 20s wall arm switches while holding a compact 80-100 degree elbow bend.';

  @override
  String get runningCoachArmTightSummary =>
      'Your elbows are staying too tight, which can shorten the arm swing and make the stride feel forced.';

  @override
  String get runningCoachArmTightCue =>
      'Relax the shoulders and let the elbows open a little more while the hands keep moving backward.';

  @override
  String get runningCoachArmTightDrill =>
      'Drill: 2 x 20m marching arm swings with relaxed shoulders and a smoother back drive.';

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
  String get runningCoachSprintDebugToggle => 'Toggle sprint debug overlay';

  @override
  String get runningCoachSprintDebugPanelTitle => 'Debug overlay';

  @override
  String get runningCoachSprintCueWhyLabel => 'Why';

  @override
  String get runningCoachSprintCueTryLabel => 'Try';

  @override
  String get runningCoachSprintTrackingStateBodyTooSmall => 'Move closer';

  @override
  String get runningCoachSprintTrackingStateBodyOutOfFrame =>
      'Keep the full body in frame';

  @override
  String get runningCoachSprintTrackingStateLowConfidence =>
      'Raise tracking confidence';

  @override
  String get runningCoachSprintTrackingStateSideViewUnstable =>
      'Settle the side view';

  @override
  String get runningCoachSprintTrackingStateReady => 'Ready for analysis';

  @override
  String get runningCoachSprintTrackingHintBodyTooSmall =>
      'The runner is too small in frame. Move closer before analyzing.';

  @override
  String get runningCoachSprintTrackingHintBodyOutOfFrame =>
      'Some joints are leaving the frame, so the pose line cannot stay locked.';

  @override
  String get runningCoachSprintTrackingHintLowConfidence =>
      'Pose confidence is low right now. Hold a steadier shot for a moment.';

  @override
  String get runningCoachSprintTrackingHintSideViewUnstable =>
      'The side-view motion is still unstable. Keep a cleaner lateral run path.';

  @override
  String get runningCoachSprintTrackingDiagnosisBodyTooSmall =>
      'The current body box is too small for stable trunk, knee, and rhythm measurements on device.';

  @override
  String get runningCoachSprintTrackingDiagnosisBodyOutOfFrame =>
      'Core joints are clipping near the edge, so overlay and feature values will drift.';

  @override
  String get runningCoachSprintTrackingDiagnosisLowConfidence =>
      'Visible joints or average landmark confidence are below the quality gate for coaching.';

  @override
  String get runningCoachSprintTrackingDiagnosisSideViewUnstable =>
      'The motion path is not staying lateral enough yet, so side-view analysis is being held back.';

  @override
  String get runningCoachSprintTrackingActionBodyTooSmall =>
      'Bring the camera closer until the body fills at least about half of the screen height.';

  @override
  String get runningCoachSprintTrackingActionBodyOutOfFrame =>
      'Keep the head, elbows, hips, and ankles inside the guide frame before sprinting again.';

  @override
  String get runningCoachSprintTrackingActionLowConfidence =>
      'Use a steadier camera, clearer lighting, and keep the runner centered for a few frames.';

  @override
  String get runningCoachSprintTrackingActionSideViewUnstable =>
      'Run across the frame from the side instead of drifting toward the camera or diagonally.';

  @override
  String runningCoachSprintTrackingSummary(
      Object state, int heightPercent, int areaPercent) {
    return '$state · height $heightPercent% · area $areaPercent%';
  }

  @override
  String runningCoachSprintSpeechSummary(Object state, Object reason) {
    return 'Speech $state · $reason';
  }

  @override
  String get runningCoachSprintSpeechStateIdle => 'Idle';

  @override
  String get runningCoachSprintSpeechStateQueued => 'Queued';

  @override
  String get runningCoachSprintSpeechStateStarted => 'Started';

  @override
  String get runningCoachSprintSpeechStateCompleted => 'Completed';

  @override
  String get runningCoachSprintSpeechStateSkipped => 'Skipped';

  @override
  String get runningCoachSprintSpeechStateCancelled => 'Cancelled';

  @override
  String get runningCoachSprintSpeechStateError => 'Error';

  @override
  String get runningCoachSprintSpeechSkipNone => 'No skip';

  @override
  String get runningCoachSprintSpeechSkipDisabled => 'Voice feedback is off';

  @override
  String get runningCoachSprintSpeechSkipNoFeedbackSelected =>
      'No feedback selected';

  @override
  String get runningCoachSprintSpeechSkipEmptyCue => 'Cue text is empty';

  @override
  String get runningCoachSprintSpeechSkipInfoFeedback =>
      'Only warning cues are spoken';

  @override
  String get runningCoachSprintSpeechSkipTrackingNotReady =>
      'Tracking is not ready yet';

  @override
  String get runningCoachSprintSpeechSkipLowConfidence =>
      'Feedback confidence is too low for speech';

  @override
  String get runningCoachSprintSpeechSkipTrackingNotStable =>
      'Tracking has not stayed stable long enough';

  @override
  String get runningCoachSprintSpeechSkipCooldownActive =>
      'Speech cooldown is active';

  @override
  String get runningCoachSprintDiagnosisLeanForward =>
      'The trunk is rising too early, so the first acceleration steps lose forward push.';

  @override
  String get runningCoachSprintDiagnosisDriveKnee =>
      'The knee drive is staying low relative to the hips, so the front-side step does not connect strongly.';

  @override
  String get runningCoachSprintDiagnosisKeepRhythm =>
      'Step timing is varying too much, so the left-right sprint rhythm is drifting.';

  @override
  String get runningCoachSprintDiagnosisBalanceArms =>
      'One arm is contributing less backward drive, so rhythm support from the upper body is uneven.';

  @override
  String get runningCoachSprintDiagnosisKeepPushing =>
      'The main sprint features are inside the current MVP range, so the app is holding the current cue.';

  @override
  String get runningCoachSprintActionLeanForward =>
      'Keep the chest lower for the first three steps and let the lean come from the ankles.';

  @override
  String get runningCoachSprintActionDriveKnee =>
      'Push the ground harder and let the knee come through instead of trying to lift it by itself.';

  @override
  String get runningCoachSprintActionKeepRhythm =>
      'Do not reach for a longer step. Keep ground contacts evenly spaced for the next few strides.';

  @override
  String get runningCoachSprintActionBalanceArms =>
      'Match the backward arm drive on both sides and keep the shoulders quieter.';

  @override
  String get runningCoachSprintActionKeepPushing =>
      'Stay with the same shape for another few steps so the app can confirm stability.';

  @override
  String get runningCoachSprintSessionTrackingStateLabel => 'Tracking state';

  @override
  String get runningCoachSprintSessionPersonSizeLabel => 'Person size';

  @override
  String runningCoachSprintSessionPersonSizeValue(
      int heightPercent, int areaPercent) {
    return 'height $heightPercent% · area $areaPercent%';
  }

  @override
  String get runningCoachSprintSessionVisibleJointCountLabel =>
      'Visible joints';

  @override
  String runningCoachSprintSessionVisibleJointCountValue(
      int count, Object confidence) {
    return '$count joints · avg $confidence';
  }

  @override
  String get runningCoachSprintSessionSpeechStateLabel => 'Speech state';

  @override
  String runningCoachSprintSessionSpeechStateValue(
      Object state, Object reason, int cooldownMs) {
    return '$state · $reason · cooldown ${cooldownMs}ms';
  }

  @override
  String get runningCoachSprintSessionFeatureConfidenceLabel =>
      'Feature confidence';

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
    return '$feature unavailable: $reason';
  }

  @override
  String get runningCoachSprintFeatureUnavailableJointWindow =>
      'not enough stable joint frames';

  @override
  String get runningCoachSprintFeatureUnavailableStepEvents =>
      'not enough stable step events';

  @override
  String get headerEducationTooltip => 'World Cup history book';

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
    return '$count straight days are alive';
  }

  @override
  String homeStreakActiveYesterdayTitle(int count) {
    return 'You logged $count straight days through yesterday';
  }

  @override
  String homeStreakPausedTitle(int count) {
    return 'Your $count-day streak paused for a moment';
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
  String get homeStreakActionReview => 'Weekly flow';

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
  String get familySharing => 'Family sharing';

  @override
  String get familySharedBackupDescription =>
      'Use one shared Drive backup without a server. Child mode owns core records, while parent mode only syncs the family layer.';

  @override
  String get familyBackupIncludesMedia =>
      'Back up profile photos and training photos too when those files can be collected locally.';

  @override
  String get familyChildDriveConnectionTitle => 'Connect child\'s Google Drive';

  @override
  String get familyChildDriveConnectionDescription =>
      'In parent mode, connect the same Google Drive account the child uses so both roles can share one family backup file.';

  @override
  String get familyConnectChildDrive => 'Connect child Drive';

  @override
  String get familyDisconnectChildDrive => 'Disconnect child Drive';

  @override
  String get familyRoleChild => 'Child';

  @override
  String get familyRoleParent => 'Parent';

  @override
  String get familyChildName => 'Child name';

  @override
  String get familyParentName => 'Parent name';

  @override
  String get familyChildNameEmpty => 'Set the child name';

  @override
  String get familyParentNameEmpty => 'Set the parent name';

  @override
  String get familyEditNames => 'Edit family names';

  @override
  String get familyPolicyTitle => 'Shared backup policy';

  @override
  String get familyPolicyChildOwnsData =>
      'Child mode backs up training, profile, diary, meals, and plans as the source of truth.';

  @override
  String get familyPolicyParentWritesOnly =>
      'Parent mode can save feedback messages, family messages, and level reward names only.';

  @override
  String get familyPolicyParentSeedRequired =>
      'Connect the parent device after at least one child backup already exists.';

  @override
  String get familyOpenSpace => 'Open family space';

  @override
  String get familyRoleChildActivated => 'Child mode activated.';

  @override
  String get familyRoleParentActivated => 'Parent mode activated.';

  @override
  String get familyNamesSaved => 'Family names saved.';

  @override
  String get familySpaceTitle => 'Family space';

  @override
  String get familySpaceSubtitleChild =>
      'Leave notes for your parent and check shared feedback here.';

  @override
  String get familySpaceSubtitleParent =>
      'Leave feedback for your child here while the rest of the app stays read-only.';

  @override
  String get familyMessagesEmpty =>
      'No family messages yet. Start the first note here.';

  @override
  String get familyMessageTypeFeedback => 'Feedback';

  @override
  String get familyMessageTypeNote => 'Note';

  @override
  String get familyMessageComposerLabel => 'Family message';

  @override
  String get familyMessageComposerHintParent =>
      'Write feedback for today’s training or mood.';

  @override
  String get familyMessageComposerHintChild =>
      'Share how today felt or what you want help with.';

  @override
  String get familyMessageComposerEmpty => 'Please enter a family message.';

  @override
  String get familyMessageSend => 'Send';

  @override
  String get familyMessageSent => 'Family message sent.';

  @override
  String get driveConnectedAccount => 'Connected Drive account';

  @override
  String get driveConnectedAccountEmpty =>
      'No Google Drive account is connected yet.';

  @override
  String get driveSharedChildAccount => 'Shared child Drive';

  @override
  String get driveSharedChildAccountEmpty =>
      'No child Drive account is known yet. Create at least one child backup first.';

  @override
  String get familyParentUsesChildDriveHint =>
      'In parent mode, sign in with the child\'s Google Drive account to sync feedback and family messages into the same backup file.';

  @override
  String get familyParentUsesChildDriveWarning =>
      'Parent mode should connect to the child\'s Google Drive account to sync safely into the same family backup.';

  @override
  String get familyParentFamilyMismatch =>
      'The connected Drive backup does not match this family data.';

  @override
  String get parentReadOnlyProfileDescription =>
      'Parent mode keeps the profile read-only. Use family sharing for feedback and the level guide for reward naming.';

  @override
  String get parentReadOnlyEntryTitle =>
      'Parent mode cannot edit training notes.';

  @override
  String get parentReadOnlyEntryBody =>
      'Core records like training, meals, and diary stay in child mode. Parent mode is limited to family sharing and reward naming.';

  @override
  String get parentReadOnlyMealLog =>
      'Parent mode cannot edit meal logs. Update meals in child mode.';

  @override
  String get parentReadOnlyQuiz =>
      'Parent mode does not run the quiz. Quiz history and XP stay in child mode.';

  @override
  String get parentReadOnlyDrawerMessage =>
      'Parent mode keeps core records read-only. Use family sharing and reward naming instead.';

  @override
  String get parentReadOnlyCalendarBanner =>
      'Parent mode keeps the calendar read-only. Update plans, matches, and meals in child mode.';

  @override
  String get parentReadOnlyCalendarMessage =>
      'Parent mode cannot edit the calendar.';

  @override
  String get parentReadOnlyDiaryMessage => 'Parent mode cannot edit the diary.';

  @override
  String get parentReadOnlyDiaryBadge => 'Parent read-only';

  @override
  String get parentReadOnlySketchMessage =>
      'Parent mode cannot edit training sketches.';

  @override
  String get levelGuideParentModeLabel => 'Parent mode';

  @override
  String get levelGuideChildModeLabel => 'Child mode';

  @override
  String get levelGuideParentModeDescription =>
      'Parent mode can save reward names only. Reward claims stay in child mode.';

  @override
  String get levelGuideChildModeDescription =>
      'Child mode can claim rewards. Reward naming stays in parent mode.';

  @override
  String get levelGuideClaimChildOnly => 'Claim in child mode';
}
