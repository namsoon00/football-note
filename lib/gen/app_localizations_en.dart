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
  String get homeWeatherAirQualityTitle => 'Air quality';

  @override
  String get homeWeatherAirQualitySubtitle =>
      'Lower numbers usually mean easier breathing outdoors.';

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
  String get educationScreenTitle => 'Taeo\'s World Cup History Book';

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
      'Swipe sideways to turn pages and scroll vertically inside each page.';

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
  String get educationBookCoverTitle => 'A World Cup Chronicle With Taeo';

  @override
  String get educationBookCoverSubtitle =>
      'From Uruguay 1930 to a preview of North America 2026';

  @override
  String get educationBookCoverStory =>
      'After training, Taeo stops in front of a shelf filled with old World Cup programmes. The moment he opens the first page, the port of Montevideo, the stands of the Maracana, the altitude of the Azteca, and the night sky above Lusail all connect into one book.\n\nThis volume does not cover all of football history. It follows only the men\'s FIFA World Cup, from the first tournament in 1930 to the most recently completed edition in Qatar in 2022, then adds a look ahead to the still-upcoming 2026 tournament in Canada, Mexico, and the United States. Taeo does not memorize only the champions. He reads who changed the era, which events shook the tournament, and why some scenes are still replayed decades later.\n\nBefore he turns another page, Taeo writes down 1930, 1950, 1958, 1970, 1986, 1998, 2002, 2010, 2018, 2022, and 2026. The first launch, the most famous shock, Pele\'s arrival, the golden Brazil side, Maradona\'s summer, the 32-team era, Korea\'s semifinal run, the first World Cup in Africa, the VAR era, Messi\'s completion, and the 48-team expansion make the whole map much easier to hold in one line.';

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
  String get educationBookOriginsTitle =>
      'The first three World Cups began with long sea journeys';

  @override
  String get educationBookOriginsSubtitle =>
      'Uruguay 1930, Italy 1934, and France 1938';

  @override
  String get educationBookOriginsStory =>
      'In the first main chapter, Taeo meets a World Cup era when teams traveled by ship more often than by plane. European sides spent weeks crossing the Atlantic to reach Uruguay, while the hosts rushed to complete the Estadio Centenario as part of a centenary celebration. The World Cup began like an adventure story before it fully became a modern media event.\n\nUruguay beat Argentina 4-2 in the 1930 final and became the inaugural champions, while Guillermo Stabile of Argentina finished as the first top scorer. Yet the early years were never only romantic. Italy\'s 1934 tournament took place in the shadow of Mussolini\'s regime, and France 1938 was staged under the growing tension of a continent moving toward war.\n\nTaeo is struck by how quickly the World Cup already carried long-distance travel, political pressure, boycotts, and refereeing arguments. So when he studies the first three editions, he reads not only who lifted the trophy, but also how fast the competition moved into the middle of world history.';

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
      'The World Cup returned after war and built Brazil\'s golden age';

  @override
  String get educationBookWorldCupSubtitle => 'From Brazil 1950 to Mexico 1970';

  @override
  String get educationBookWorldCupStory =>
      'After the cancellations of 1942 and 1946, Brazil 1950 looked like the joyful return of world football. Taeo\'s first memory there, however, is not celebration but silence. Uruguay\'s win over Brazil in the decisive final group match created the Maracana shock and proved that the World Cup could also crush the dreams of a host nation in front of its own people.\n\nThe next pages are even more legendary. West Germany\'s Miracle of Bern in 1954, the arrival of 17-year-old Pele in 1958, Garrincha carrying Brazil in 1962 when Pele was hurt, England\'s only title in 1966, and the complete golden Brazil team of 1970 follow without pause.\n\nTaeo learns that this era is not just a list of winners. It is the age in which new heroes appeared, some countries took national scars, and some styles became the global reference for what great football should look like. He summarizes 1950 through 1970 with five words: restart, shock, genius, revenge, and completion.';

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
      'A new trophy, total football, and an age full of argument';

  @override
  String get educationBookClubSubtitle =>
      'From West Germany 1974 to Italy 1990';

  @override
  String get educationBookClubStory =>
      'From 1974 onward, Taeo sees a new trophy. The Netherlands, led by Johan Cruyff, played total football with constant movement and position exchange, only for West Germany and Franz Beckenbauer to stop that revolution in the final. The World Cup looked like a laboratory where beautiful ideas and cold realism collided in public.\n\nYet this period can never be explained by football alone. Argentina 1978 was played under the shadow of a military dictatorship. Spain 1982 is remembered both for Paolo Rossi\'s return and for the violent collision and shootout drama of France against West Germany. Then Mexico 1986 pushed Diego Maradona to the top of World Cup mythology when he left both the Hand of God and the solo goal past five players in the same campaign.\n\nBy the time Taeo reaches Italy 1990, he understands how emotionally crowded the World Cup can be. Roger Milla\'s dancing, Beckenbauer winning as a coach, and Maradona crying after defeat in the final all live in the same stretch of history. He writes down this era as a blend of tactical innovation, political shadows, superhuman skill, and permanent debate.';

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
      'A globalized World Cup and finals that felt like theater';

  @override
  String get educationBookTacticsSubtitle =>
      'USA 1994, France 1998, Korea and Japan 2002, Germany 2006';

  @override
  String get educationBookTacticsStory =>
      'By USA 1994, Taeo feels that the World Cup has fully become a global mega-event. Enormous American stadiums, Romario\'s smile, and Roberto Baggio\'s shot flying over the bar in the shootout all belong to the same memory. The tournament proved that the World Cup could become enormous even in a country where football was not the main sport.\n\nFrance 1998 opened the 32-team era and left behind Zinedine Zidane\'s two headed goals in the final together with the mystery and tension around Ronaldo\'s physical condition before kickoff. Korea and Japan 2002 brought Korea\'s semifinal run, Guus Hiddink\'s leadership, scenes from Ahn Jung-hwan and Park Ji-sung, and Ronaldo\'s eight-goal redemption arc into one unforgettable tournament.\n\nGermany 2006 restored the smile of a football festival, but the final ended with Zidane\'s headbutt turning the whole emotional weather of the night. Taeo learns that as the World Cup grows bigger, the drama grows with it. He summarizes 1994 through 2006 as globalization, expansion, Korea\'s summer, and one final reversal.';

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
      'The data era, and Messi\'s final completion';

  @override
  String get educationBookLegendsSubtitle =>
      'From South Africa 2010 to Qatar 2022';

  @override
  String get educationBookLegendsStory =>
      'When Taeo opens the 2010 South Africa chapter, he hears vuvuzelas before anything else. The first men\'s World Cup on African soil looked and sounded different from the start, and Spain completed its era through Andres Iniesta\'s extra-time winner in the final. The same tournament also gave him Luis Suarez\'s goal-line handball against Ghana and even the bizarre fame of Paul the Octopus, proving once more that the World Cup can be serious history and internet folklore at the same time.\n\nBrazil 2014 left the Mineirazo, Germany\'s 7-1 destruction of the host nation, and Miroslav Klose\'s 16th career World Cup goal. Russia 2018 delivered Kylian Mbappe\'s breakout, France\'s second title, Croatia\'s exhausting run through extra time, and the first full use of VAR in a men\'s World Cup.\n\nThen Qatar 2022 gave Taeo Messi\'s title at last. Morocco became the first African semi-finalist, Argentina and France played one of the wildest finals the tournament has ever seen, Mbappe scored a hat-trick in defeat, and Emiliano Martinez made the save that helped close the story. Taeo realizes that some World Cups finish a career, while others reset what an entire continent believes is possible.';

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
      'How to remember the World Cup through people';

  @override
  String get educationBookAsiaSubtitle =>
      'From Jules Rimet to Pele, Maradona, Beckenbauer, and Messi';

  @override
  String get educationBookAsiaStory =>
      'At some point, Taeo realizes he no longer remembers the World Cup only through years. He starts to remember it through people. Jules Rimet, who pushed the tournament into existence. Vittorio Pozzo, who won two straight titles. Pele, who won three. Beckenbauer, who reached the summit as both player and coach. Maradona, who turned one World Cup into an entire mythology.\n\nThis chapter is not filled only with heroes. Garrincha carried a hurt Brazil side in 1962. Ronaldo turned the pain of one final into redemption four years later. Zidane left both genius and explosion behind. Messi finally closed the last open chapter in his own story. Taeo understands that the World Cup is where human narratives become loudest.\n\nThat is why he refuses to memorize names by themselves. Pele means 1958 and 1970. Maradona means England in 1986. Beckenbauer means 1974 and 1990. Ronaldo means 2002. Messi means 2022. A name only becomes history once the year and the scene are attached to it.';

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
      'Upsets, arguments, and the stories beyond the pitch';

  @override
  String get educationBookWomenSubtitle =>
      'War, dictatorship, a stolen trophy, and technological review';

  @override
  String get educationBookWomenStory =>
      'This chapter teaches Taeo that a World Cup history book explains only half the truth if it lists nothing but champions. Some tournaments never happened because of war. Some were played under dictatorships. In others, the off-field events became almost as famous as the football itself. The World Cup always absorbs the air of the wider world.\n\nIn 1966, the Jules Rimet Trophy was stolen before the tournament opened and later found by a dog called Pickles. In 1982, the Battiston collision left a lasting argument about sportsmanship. In 2010, Frank Lampard\'s disallowed goal pushed the demand for technology harder. By the time Taeo reaches goal-line technology in 2014, VAR in 2018, and semi-automated offside in 2022, he understands that the World Cup is also a history of how football tries to judge itself.\n\nSo Taeo starts writing down two questions for every tournament. Who won on the pitch, and what changed outside it? He feels that only by keeping both questions together can a real history book exist.';

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
      'The next page is 2026, Taeo\'s prediction notebook';

  @override
  String get educationBookModernSubtitle =>
      'What a 48-team World Cup may change';

  @override
  String get educationBookModernStory =>
      'In the final main chapter, Taeo looks at the still-unplayed 2026 World Cup in North America. A 48-team field, 104 matches, and a three-country host setup already make it feel different from previous tournaments. The longer schedule suggests that squad depth, recovery management, and adaptation to long travel will matter more than ever.\n\nInstead of naming a champion too quickly, Taeo writes down the conditions that usually favor one. A midfield that can press and build, set-piece detail that can decide a tight knockout match, goal output spread beyond one star, and a coaching staff that can analyze unfamiliar opponents quickly all feel more valuable in an expanded event. Traditional powers will still be powerful, but a 48-team structure may also create more strange paths and more dark horses.\n\nSo Taeo treats 2026 less like a guessing game and more like an exercise in observation. He wonders which of the three host nations will go furthest, which South American and European powers will define the new standard, and which Asian or African side might push the ceiling higher again.';

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
  String get educationBookFinaleTitle => 'Taeo\'s final bookmark';

  @override
  String get educationBookFinaleSubtitle =>
      'How to tie together 1930 and 2026 in one line';

  @override
  String get educationBookFinaleStory =>
      'After closing the final page, Taeo realizes that the World Cup is really a giant summary written once every four years. Players sailing to Uruguay and modern stars playing under satellite cameras and VAR all belong to the same tournament line.\n\nSome eras are remembered through giants such as Pele, Maradona, and Messi. Some are remembered through scores like the Maracana shock or 7-1. Others survive because of a stolen trophy, war, or arguments over technology. Taeo concludes that reading World Cup history is not simple memorization. It is training the eye to read world history through the language of one competition.\n\nSo before he puts the book away, he repeats 1930, 1950, 1958, 1970, 1986, 1998, 2002, 2010, 2018, 2022, and 2026 in order one more time. If the year, host, leading figures, and defining event all rise together in his head, he believes every future match will feel much deeper.';

  @override
  String get educationBookFinaleTimeline =>
      'Taeo learned from the early World Cups how quickly the tournament moved into the center of world history.\nTaeo learned from the post-war era that one match can become a nation\'s memory.\nTaeo learned from recent tournaments that even in a data-heavy age, people still remember scenes and faces first.\nTaeo learned from the 2026 preview that reading the future begins by seeing the patterns of the past.';

  @override
  String get educationBookFinaleFacts =>
      'Review anchor 1: tie together the year, host, champion, iconic scene, and leading figure in one line.\nReview anchor 2: 1930, 1950, 1970, 1986, 1998, 2002, 2018, and 2022 are non-negotiable review years.\nReview anchor 3: connect records to signature numbers such as Pele\'s 3 titles, Brazil\'s 5 titles, and Klose\'s 16 goals.\nReview anchor 4: predictions get stronger when tactics, fitness, and squad depth are written beside the team name.';

  @override
  String get educationBookFinaleNote =>
      'As he closes the book, Taeo writes the first line of his next journal like this. To really watch the World Cup well is not to memorize only one final score, but to follow the whole long story from the first kick in 1930 to the next question waiting in 2026.';
}
