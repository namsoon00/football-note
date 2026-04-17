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
  String get headerEducationTooltip => 'Football history book';

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
  String get educationScreenTitle => 'Taeo\'s Football History Book';

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
  String get educationBookHeaderEyebrow => 'TAEO FOOTBALL ARCHIVE';

  @override
  String get educationBookHeaderTitle =>
      'Football history that Taeo turns page by page';

  @override
  String get educationBookHeaderBody =>
      'This book-style education screen stretches from the roots of ball games to formal rules, World Cups, club football, tactical revolutions, women\'s football, and the timeline of Korea and Asia.';

  @override
  String get educationBookHeaderChipChapters => '10 chapters';

  @override
  String get educationBookHeaderChipRoots => 'Ancient to modern';

  @override
  String get educationBookHeaderChipTactics => 'Tactics and legends';

  @override
  String get educationBookHeaderChipSwipe => 'Page-turn UX';

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
  String get educationBookCoverTitle => 'Taeo\'s Football Time Travel';

  @override
  String get educationBookCoverSubtitle =>
      'One long volume of rules, tournaments, tactics, and legends';

  @override
  String get educationBookCoverStory =>
      'After training, Taeo walks into an archive packed with old football books. The moment he opens the first page, the roots of ball games and the age of modern data football connect into one long story.\n\nTaeo is the main character of this book, but every page also introduces the players, coaches, crowds, and rules that changed the game. As he keeps turning pages, he learns that football is more than a match. It is a language shaped by culture, industry, and education together.';

  @override
  String get educationBookCoverTimeline =>
      'Ancient-era cuju and kemari remained as early traditions of playing with the feet.\nIn 1863, the Football Association in England drew the starting line of modern football by codifying rules.\nThe founding of FIFA in 1904 and the first World Cup in 1930 created a shared global stage.\nThe 1991 Women\'s World Cup and the 2018 men\'s World Cup use of VAR show how football kept expanding in scope and officiating.';

  @override
  String get educationBookCoverFacts =>
      'Taeo\'s bookmark 1: each chapter mixes story, timeline, and memory anchors.\nTaeo\'s bookmark 2: World Cup and league history stick faster when year, place, and champion are grouped together.\nTaeo\'s bookmark 3: tactical history makes more sense when read beside rule changes.\nTaeo\'s bookmark 4: women\'s football and Asian football become clearer when followed as their own timelines.';

  @override
  String get educationBookCoverNote =>
      'Taeo decides that after finishing the book, he will write down five years that stayed in his head. History study becomes much easier once you build your own anchor points.';

  @override
  String get educationBookOriginsLabel => 'Chapter 1';

  @override
  String get educationBookOriginsTitle =>
      'The roots of ball games and the birth of rules';

  @override
  String get educationBookOriginsSubtitle =>
      'From cuju, kemari, and folk football to the 1863 rule book';

  @override
  String get educationBookOriginsStory =>
      'In the oldest chapter, Taeo meets ball games that look nothing like the modern version. In some eras people kicked the ball, in others they kept it in the air like a ritual, and in many towns entire streets became part of the contest.\n\nOnce matches spread across regions, everyone needed the same set of promises. Taeo underlines a key lesson: football did not truly begin with the first goal, but with agreement on the rules.';

  @override
  String get educationBookOriginsTimeline =>
      'Cuju from Han-era China is often cited as one of the clearest early records of kicking a leather ball.\nJapan\'s kemari valued technique and rhythm over direct competition.\nMedieval European folk football was closer to a rough town-wide festival than an organized sport.\nThe Cambridge Rules of 1848 helped create an early shared draft for schools and universities.\nIn 1863, the Football Association separated association football from rugby-style handling.\nThe FA Cup began in 1871, and England vs Scotland in 1872 is recorded as the first official international match.';

  @override
  String get educationBookOriginsFacts =>
      'Early offside rules were far stricter than today\'s version, so forward passing was much harder.\nThe penalty kick arrived in 1891 and clarified responsibility around fouls near goal.\nAs crossbars, nets, and referee systems became standardized, scoring decisions grew more stable.\nTaeo notes that once rules were unified, skill comparison and tactical experimentation became possible.';

  @override
  String get educationBookOriginsNote =>
      'Taeo writes that football was never a finished sport from day one. It was the result of a long negotiation that turned chaotic play into a common language.';

  @override
  String get educationBookWorldCupLabel => 'Chapter 2';

  @override
  String get educationBookWorldCupTitle =>
      'The start of FIFA and the World Cup';

  @override
  String get educationBookWorldCupSubtitle =>
      'An international body, the first world event, and the restart after war';

  @override
  String get educationBookWorldCupStory =>
      'When Taeo turns the next page, he sees a meeting room in Paris and a stadium in Uruguay inside the same chapter. A handful of countries gather to build an international body, and soon after, a new stage appears to crown a world champion.\n\nTo Taeo, World Cup history feels like more than a list of matches. It looks like a global announcement that the world now shares one football language. That is why he starts reading year, host, and champion as a single unit.';

  @override
  String get educationBookWorldCupTimeline =>
      'FIFA was founded in Paris in 1904, creating a center for international football governance.\nFootball at the 1908 London Olympics helped strengthen the structure of international competition.\nUruguay won the 1924 and 1928 Olympic tournaments, boosting the symbolism of hosting the first World Cup.\nThe first FIFA World Cup was held in Uruguay in 1930, and the hosts became the inaugural champions.\nThe 1942 and 1946 tournaments were not played because of World War II.\nThe 1950 World Cup in Brazil left behind the historic Maracana shock delivered by Uruguay.\nThe current FIFA World Cup Trophy has been used since 1974.';

  @override
  String get educationBookWorldCupFacts =>
      'The Jules Rimet Trophy was the prize lifted by World Cup champions through 1970.\nBrazil remains the standard reference for the most men\'s World Cup titles.\nMiroslav Klose\'s 16 goals are the all-time men\'s World Cup scoring record.\nTaeo studies World Cup history by grouping host nation, champion, and iconic scene together.';

  @override
  String get educationBookWorldCupNote =>
      'Taeo writes that the World Cup feels less like a single tournament and more like the largest presentation in the world proving that one set of rules can connect everyone.';

  @override
  String get educationBookClubLabel => 'Chapter 3';

  @override
  String get educationBookClubTitle =>
      'The expansion of club football and the European stage';

  @override
  String get educationBookClubSubtitle =>
      'League launches, the European Cup, and the Premier League era';

  @override
  String get educationBookClubStory =>
      'Taeo watches industrial-city weekends and European away nights merge inside one chapter. If the World Cup is the calendar of nations, club football feels like the weekly rhythm of cities.\n\nPeople who follow one club for life, streets waiting for derby day, and the global fandom created by broadcasting all show up in this section. Taeo is struck by how football can hold local identity and global industry at the same time.';

  @override
  String get educationBookClubTimeline =>
      'The Football League launched in England in 1888, establishing regular home-and-away league structure.\nThe European Cup began in 1955 and created an ongoing story for the strongest clubs in Europe.\nReal Madrid\'s first five European Cups quickly raised the prestige of the competition.\nThe Premier League launched in 1992, and Manchester United won the inaugural 1992-93 title.\nFrom the 1992-93 season, the European Cup was reorganized as the UEFA Champions League.\nThe 1995 Bosman ruling changed player movement and squad-building across Europe.';

  @override
  String get educationBookClubFacts =>
      'Arsenal\'s 2003-04 Invincibles remain the classic example of an unbeaten league title.\nThe Champions League accelerated the globalization of club football through group stages and broadcast growth.\nClub badges, kits, songs, and derby culture show how deeply football can merge with local identity.\nTaeo writes down league launch years, dominant dynasties, and media-capital turning points together.';

  @override
  String get educationBookClubNote =>
      'Taeo concludes that knowing club football history is not just about counting trophies. It is about understanding which era belonged to which team.';

  @override
  String get educationBookTacticsLabel => 'Chapter 4';

  @override
  String get educationBookTacticsTitle =>
      'How tactical revolutions changed the picture of the game';

  @override
  String get educationBookTacticsSubtitle =>
      'Pyramid, WM, catenaccio, total football, tiki-taka, and gegenpressing';

  @override
  String get educationBookTacticsStory =>
      'Inside the tactical chapter, Taeo learns that formations are not just codes. The same numbers can describe very different teams depending on where the ball starts, who empties a space, and who triggers the press.\n\nThis chapter teaches him that tactical study is not about memorizing names alone. It is about seeing how rule changes and player profiles reshape the entire picture of a match. That is why he always adds the question why next to the timeline.';

  @override
  String get educationBookTacticsTimeline =>
      'Early football often used the 2-3-5 pyramid, with large numbers committed to attack.\nAfter the 1925 offside law change, Herbert Chapman\'s WM helped rebuild defensive balance.\nCatenaccio, widely associated with Inter in the 1960s, emphasized cover defense and efficient transition.\nAjax and the Netherlands in the 1970s made total football the ideal of rotation, pressing, and position exchange.\nArrigo Sacchi\'s Milan in the 1980s refined spacing between lines and collective pressing.\nFrom 2008 onward, Barcelona and Spain pushed tiki-taka and positional play toward global standard status.\nKlopp teams in the 2010s made the reaction immediately after losing the ball a tactical center through gegenpressing.';

  @override
  String get educationBookTacticsFacts =>
      'Tactical change moves together with rule changes, player athleticism, pitch conditions, and refereeing trends.\nThe 1992 back-pass rule change sharply altered build-up speed by restricting goalkeeper hand use.\nModern analysis uses tools such as xG, pressing intensity, and field position to read tactics through numbers.\nTaeo writes that real tactical study means understanding where the ball moved and why, not only reciting a formation name.';

  @override
  String get educationBookTacticsNote =>
      'Taeo decides not to stare only at number shapes on the board. Even one 4-3-3 can become a completely different team depending on press height, fullback roles, and the personality of the number 6.';

  @override
  String get educationBookLegendsLabel => 'Chapter 5';

  @override
  String get educationBookLegendsTitle =>
      'Legends and iconic scenes build football memory';

  @override
  String get educationBookLegendsSubtitle =>
      'The reference points left by Pele, Maradona, Cruyff, Zidane, and Messi';

  @override
  String get educationBookLegendsStory =>
      'When Taeo enters the chapter of film archives, he sees one era-defining scene after another. One player ruled the World Cup as a teenager, another left a whole football language inside one turn, and another ended decades of waiting with a final title.\n\nThis is where Taeo realizes that a truly great player is not remembered only for volume of records. Greatness also means leaving an image that people immediately recall whenever football history is discussed.';

  @override
  String get educationBookLegendsTimeline =>
      'Pele stunned the world in 1958 by winning the World Cup at age 17.\nThe Cruyff Turn at the 1974 World Cup showed that one move can become a symbol of an era.\nAt Mexico 1986, Maradona left both the Hand of God and the solo goal past five players in the same tournament.\nAt France 1998, Zidane led the hosts to the title with two headed goals in the final.\nThe 2006 World Cup final is remembered as a peak of drama, including Zidane\'s final red card.\nThe 2022 World Cup in Qatar ended with Messi winning the trophy and Argentina closing a long wait.';

  @override
  String get educationBookLegendsFacts =>
      'Pele owns the unmatched reference point of three men\'s World Cup titles.\nDiego Maradona, Johan Cruyff, Zinedine Zidane, and Lionel Messi are remembered as era symbols as much as elite performers.\nThe Ballon d\'Or compresses an individual story, but many supporters still judge players through both World Cup and club legacy.\nTaeo memorizes big moments by pairing the player, year, opponent, stage, and why the scene mattered.';

  @override
  String get educationBookLegendsNote =>
      'Taeo writes that the greatest players are not only the most skilled ones. They are the people who leave scenes that instantly appear in everyone\'s mind when football is explained.';

  @override
  String get educationBookAsiaLabel => 'Chapter 6';

  @override
  String get educationBookAsiaTitle =>
      'The timetable of Asian and Korean football';

  @override
  String get educationBookAsiaSubtitle =>
      'From the founding of the AFC to the 2002 World Cup and today\'s Korea';

  @override
  String get educationBookAsiaStory =>
      'Now Taeo follows city names such as Seoul, Tokyo, and Doha as the book opens the map of Asian football. Even with huge travel distances, different climates, and uneven investment, football across the continent built its own timeline of growth.\n\nThe Korean section keeps repeating one lesson: national-team results alone do not tell the whole story. Pro league structure, overseas careers, and generation change moved together. Taeo decides that he should never separate the national team from the league base when reading a country\'s football history.';

  @override
  String get educationBookAsiaTimeline =>
      'The AFC was founded in 1954, establishing a continental organization for Asian football.\nThe first AFC Asian Cup was held in 1956, and South Korea won back-to-back titles in 1956 and 1960.\nThe K League launched in 1983 and began the full professional era of Korean football.\nSouth Korea and Japan co-hosted the 2002 World Cup, and Korea reached the semifinals to set a new Asian benchmark.\nJapan\'s women\'s World Cup triumph in 2011 proved that Asia could reach the top of the global women\'s game.\nSon Heung-min\'s success in Europe raised the perceived ceiling of a Korean player\'s career once again.';

  @override
  String get educationBookAsiaFacts =>
      'Cha Bum-kun, Park Ji-sung, and Son Heung-min are often linked as overseas reference points from different generations.\nKorean football makes more sense when World Cups, youth tournaments, the domestic league, and overseas growth are read together.\nAsian football development is tied to travel distance, climate, league investment, and youth-system differences.\nTaeo writes down how the league base changed alongside national-team results.';

  @override
  String get educationBookAsiaNote =>
      'Taeo refuses to see 2002 as just a single miracle. He notes that major scenes are built when preparation, hosting, generational change, and league experience come together.';

  @override
  String get educationBookWomenLabel => 'Chapter 7';

  @override
  String get educationBookWomenTitle =>
      'Women\'s football grew through bans, return, and expansion';

  @override
  String get educationBookWomenSubtitle =>
      'The 1921 ban, the 1991 World Cup, and the growth of professional leagues';

  @override
  String get educationBookWomenStory =>
      'When Taeo reaches the chapter on women\'s football, he first meets the history of closed doors before he reaches the trophy lifts. Many players had to fight a lack of access before they could even fight opponents on the field.\n\nThat is why this chapter treats institutional change and the return of crowds as seriously as the list of champions. Taeo decides not to forget that the starting line of football was never equal for everyone.';

  @override
  String get educationBookWomenTimeline =>
      'In 1920, Dick, Kerr Ladies drew huge crowds in England and showed the scale of women\'s football potential.\nThe Football Association ban of 1921 cast a long shadow over the development of the women\'s game.\nThe ban was lifted in 1971, allowing women\'s football to move back into official structures.\nThe first FIFA Women\'s World Cup was held in China in 1991.\nWomen\'s football became an Olympic sport in 1996.\nThe 1999 Women\'s World Cup final in the United States proved mainstream appeal in front of more than 90,000 fans.\nSpain announced a new power in 2023 by winning its first Women\'s World Cup title.';

  @override
  String get educationBookWomenFacts =>
      'The history of women\'s football is not only about expansion of a sport, but also about the recovery of opportunity.\nThe United States, Germany, Norway, Japan, and Spain are among the clearest examples of era-specific power cycles.\nJapan\'s 2011 title remains the first Women\'s World Cup won by an Asian nation.\nTaeo uses this page to think about how one major tournament can shift participation for the next generation.';

  @override
  String get educationBookWomenNote =>
      'Taeo feels that a real history book cannot list only the champions. It also has to record whose door was closed, and when that door opened again.';

  @override
  String get educationBookModernLabel => 'Chapter 8';

  @override
  String get educationBookModernTitle =>
      'Modern football is read again through data and technology';

  @override
  String get educationBookModernSubtitle =>
      'Back-pass reform, goal-line technology, VAR, and analytical football';

  @override
  String get educationBookModernStory =>
      'As the book reaches the modern era, Taeo finds graphs, heat maps, and video tags on the page beside match scenes. Analysts sit near coaches, and player movement gets stored as both numbers and images.\n\nEven so, Taeo notices that the central football questions remain familiar. Who scanned first, who created the better space, and who made the faster decision still define the match.';

  @override
  String get educationBookModernTimeline =>
      'The 1992 back-pass rule change altered the build-up language of goalkeepers and defensive lines.\nIn 2012, FIFA approved goal-line technology, and it was used at the 2014 World Cup.\nThe 2018 men\'s World Cup was the first tournament to apply VAR at full scale.\nWearable GPS, video tagging, and event data became standard tools in training and scouting through the 2010s.\nModern clubs often work with set-piece coaches, data analysts, and performance scientists together.';

  @override
  String get educationBookModernFacts =>
      'xG is a useful headline measure of shot quality, but it needs context such as pressing and field position.\nData is not a tool that removes a coach\'s feel. It is a second language that sharpens the basis for decisions.\nAs technical review expands, fairness rises, but arguments about rhythm and emotion in the game also grow.\nTaeo writes that the latest football still demands a way of reading numbers, video, and field feel together.';

  @override
  String get educationBookModernNote =>
      'Taeo concludes that modern players are not fundamentally different from the old ones. There is more data around them, but first touch, speed of thought, and connection with teammates remain the center of the sport.';

  @override
  String get educationBookFinaleLabel => 'Epilogue';

  @override
  String get educationBookFinaleTitle => 'Taeo\'s final bookmark';

  @override
  String get educationBookFinaleSubtitle =>
      'Now it is time to turn history into training language';

  @override
  String get educationBookFinaleStory =>
      'When Taeo closes the last page, he understands that what he read is not just memory work for a quiz score. It is a lens for seeing football more deeply.\n\nSome coaches search rule changes for ideas. Some players draw courage from legendary scenes. Some supporters love their club more fiercely once they understand which era it represented. Taeo now feels he can practice one simple action on the field while still seeing the long history behind it.';

  @override
  String get educationBookFinaleTimeline =>
      'From the history of rules, Taeo learned that football is a sport of shared agreement.\nFrom the history of the World Cup, he saw how one match can compress the memory of a nation.\nFrom tactical history, he confirmed that the answer is never only one shape, but something that changes with era and players.\nFrom the history of women\'s football and Asian football, he learned how strongly opportunity and environment shape growth.';

  @override
  String get educationBookFinaleFacts =>
      'Review anchor 1: memorize years such as 1863, 1904, 1930, 1991, 2002, and 2018 first.\nReview anchor 2: connect era-defining names such as Pele, Maradona, Cruyff, Zidane, Messi, and Son Heung-min to the timeline.\nReview anchor 3: understand WM, total football, tiki-taka, and gegenpressing alongside their historical background.\nReview anchor 4: keep the World Cup, Champions League, Asian Cup, and Women\'s World Cup as separate competition axes in memory.';

  @override
  String get educationBookFinaleNote =>
      'As Taeo shuts the book, he writes the first line of his next training diary: seeing football well means not only watching the action in front of you, but tracing where that action came from all the way back.';
}
