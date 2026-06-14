// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Japanese (`ja`).
class AppLocalizationsJa extends AppLocalizations {
  AppLocalizationsJa([String locale = 'ja']) : super(locale);

  @override
  String get appTitle => 'サッカートレーニングログ';

  @override
  String get tabHome => '家';

  @override
  String get tabLogs => 'ログ';

  @override
  String get tabCalendar => 'カレンダー';

  @override
  String get tabStats => '統計';

  @override
  String get tabDiary => '日記';

  @override
  String get tabNews => 'ニュース';

  @override
  String tabGuideTitle(Object tabName) {
    return '$tabName ガイド';
  }

  @override
  String get welcomeGuideTitle => '最初に画面を一緒に確認しましょう';

  @override
  String get welcomeGuideIntro => '最初にタップする場所をハイライトし、リンジーがコーチマークで順番を案内します。';

  @override
  String get welcomeGuidePrimaryAction => '開始';

  @override
  String get welcomeGuideSectionFlow => '段階的な流れ';

  @override
  String get welcomeGuideNextTabHint => '上の別のタブを選択して、そのボタンをプレビューします。';

  @override
  String get welcomeGuidePreviewLabel => '画面ハイライト';

  @override
  String get welcomeGuideCoachMarkLabel => 'コーチマーク';

  @override
  String get parentWelcomeGuideTitle => '保護者モードガイド';

  @override
  String get parentWelcomeGuideIntro =>
      '親モードは、プレーヤーの記録を確認し、既存のトレーニング ログにフィードバックを残すためのものです。';

  @override
  String get parentWelcomeGuideStepLogs =>
      'まず [ログ] タブを開いて、プレーヤーによって保存されたレコードを確認します。';

  @override
  String get parentWelcomeGuideStepFeedback =>
      '既存のレコード内にフィードバックとして賞賛と次回のメモを残します。';

  @override
  String get parentWelcomeGuideStepSync =>
      '共有データの同期を維持するには、プレーヤーのバックアップを保持する Google ドライブ アカウントに接続します。';

  @override
  String get guideActionToday => '今日';

  @override
  String get guideActionMeal => '食事';

  @override
  String get guideActionCardList => 'カード/リスト';

  @override
  String get guideActionSelectDate => '日付を選択してください';

  @override
  String get guideActionPlus => '+';

  @override
  String get guideActionPeriod => '期間';

  @override
  String get guideActionBenchmark => '平均';

  @override
  String get guideActionWeakPoint => '集中';

  @override
  String get guideActionOpenToday => '今日の日記';

  @override
  String get guideActionRecordSticker => 'ステッカー';

  @override
  String get guideActionSaveDiary => '日記を保存する';

  @override
  String get welcomeHomeOverview => 'アプリに次の有用なアクションを決定させたい場合は、ホームから開始します。';

  @override
  String get welcomeHomeStepToday => '今日の計画、簡単なアクション、次の未完了のルーチンを最初に確認します。';

  @override
  String get welcomeHomeStepMeal => '一日が終わる前に食事ボタンから食事を追加すると、回復記録が完全な状態に保たれます。';

  @override
  String get welcomeHomeStepStats =>
      'ログイン後にホームから週間統計を開いて、その週のバランスが取れているかどうかを確認します。';

  @override
  String get welcomeLogsOverview => '実際のトレーニング ノートを作成または確認する場合は、ログを使用します。';

  @override
  String get welcomeLogsStepAdd =>
      '[エントリの追加] をタップし、セッションの基本情報を入力して、最初のメモを保存します。';

  @override
  String get welcomeLogsStepBoard => 'ドリルの形状や移動パスが重要な場合は、ノート内のボードを開きます。';

  @override
  String get welcomeLogsStepReview =>
      'カード/リストとフィルターを切り替えると、メモをすべて読まなくても最近の記録を見つけることができます。';

  @override
  String get welcomeCalendarOverview =>
      '日付が重要な場合はカレンダーを使用します。計画、試合、食事、メモをまとめて保存できます。';

  @override
  String get welcomeCalendarStepDate =>
      'すべての作成アクションが適切な日に開始されるように、最初に日付を選択します。';

  @override
  String get welcomeCalendarStepPlus =>
      '+ を使用して、選択した日付の計画、試合、またはトレーニングのメモを追加します。';

  @override
  String get welcomeCalendarStepMeal => '回復が一日の一部である場合は、同じ日付の食事記録を追加します。';

  @override
  String get welcomeStatsOverview =>
      'いくつかのレコードが存在し、次のトレーニング ターゲットが必要な場合は、統計を使用します。';

  @override
  String get welcomeStatsStepPeriod => '今週、先週、またはカスタム範囲を比較する期間を変更します。';

  @override
  String get welcomeStatsStepAverage => '平均比較を開いて、どのメトリクスが進んでいるか遅れているかを確認します。';

  @override
  String get welcomeStatsStepFocus => '最も弱いシグナルを次の計画またはメモの目標に変えます。';

  @override
  String get welcomeChallengeOverview =>
      'チャレンジでは、リンジーが毎日のラウンドミッションを確認し、完了を大きな XP に変えてくれます。';

  @override
  String get welcomeChallengeActionStart => 'チャレンジ開始';

  @override
  String get welcomeChallengeStepStart => '期間を選ぶと、今日から続けるラウンドが作られます。';

  @override
  String get welcomeChallengeActionMission => 'ミッション入力';

  @override
  String get welcomeChallengeStepMission =>
      'トレーニング、縄跳び、リフティング、食事のミッションをタップすると記録画面が開きます。';

  @override
  String get welcomeChallengeActionReward => 'XP 報酬';

  @override
  String get welcomeChallengeStepReward =>
      'ラウンドを終えるたびに XP が貯まり、完走するとリンジーが祝ってくれます。';

  @override
  String get welcomeDiaryOverview =>
      '日記を使用すると、トレーニング、食事、ステッカーなどで 1 日を 1 つの読みやすいストーリーに変えることができます。';

  @override
  String get welcomeDiaryStepToday => '記録後、ホームまたは日記タブから今日の日記を開きます。';

  @override
  String get welcomeDiaryStepSticker => '今日の記録シールを引いて、読む順番を並べます。';

  @override
  String get welcomeDiaryStepSave => 'タイトル、ストーリー、またはステッカーの選択の準備ができたら、日記を保存します。';

  @override
  String get logsQuickGuideTitle => 'クイックスタートガイド';

  @override
  String get logsQuickGuideIntro => 'この順序で最初のレコードを作成し、ここに戻って確認します。';

  @override
  String get newsFifaHubButton => 'FIFA';

  @override
  String get newsWorldCupButton => 'W杯';

  @override
  String get newsKLeagueStandingsButton => 'リーグ';

  @override
  String get newsMoreActionsTooltip => 'リーグビュー';

  @override
  String get newsMoreActionsTitle => 'もっと';

  @override
  String get newsRankingMoreButton => 'リーグビュー';

  @override
  String get newsLeagueStandingsAction => 'リーグ';

  @override
  String get newsLeagueStandingsTitle => 'リーグビュー';

  @override
  String get newsKLeagueStandingsTitle => 'Kリーグ1';

  @override
  String get newsPremierLeagueStandingsTitle => 'プレミアリーグ';

  @override
  String get newsChampionsLeagueStandingsTitle => 'チャンピオンズリーグ';

  @override
  String get newsLaLigaStandingsTitle => 'ラ・リーガ';

  @override
  String get newsBundesligaStandingsTitle => 'ブンデスリーガ';

  @override
  String get newsMajorLeagueSoccerStandingsTitle => 'MLS';

  @override
  String get newsSaudiProLeagueStandingsTitle => 'サウジプロリーグ';

  @override
  String newsLeagueStandingsUpdated(Object date) {
    return '$dateを更新しました';
  }

  @override
  String get newsLeagueStandingsOpenSource => 'オープンソーステーブル';

  @override
  String get newsLeagueStandingsEmpty => '現在、順位表はありません。';

  @override
  String get newsLeagueStandingsError => '順位表を読み込めませんでした。';

  @override
  String get newsLeagueStandingsRetry => 'リトライ';

  @override
  String get newsLeagueFixturesTitle => '日程カレンダー';

  @override
  String get newsLeagueFixturesCalendarTitle => '試合日程カレンダー';

  @override
  String get newsLeagueFixturesOpenCalendar => 'カレンダーで表示';

  @override
  String get newsLeagueFixturesCalendarEmptyDay => 'この日に配置された試合はありません。';

  @override
  String get newsLeagueFixturesSubtitle => 'カレンダーで今後の日程と最近の結果を確認します。';

  @override
  String get newsLeagueFixturesEmpty => 'より広い日程範囲を確認しましたが、表示できる試合は見つかりませんでした。';

  @override
  String get newsLeagueFixturesShowAll => 'すべての備品を表示';

  @override
  String get newsLeagueFixturesCollapse => '器具を折りたたむ';

  @override
  String get newsLeagueFixturesSelectedTeamsOnly => '選ばれたチームのみ';

  @override
  String get newsLeagueFixturesSelectedTeamsEmpty =>
      'このリーグのスケジュールでは、選択チームの試合はありません。';

  @override
  String newsLeagueFixturesEmptyReason(String league) {
    return '$league は、元の日程フィードが空か現在シーズンの日程がまだ公開されていないため、表示できる試合がありません。';
  }

  @override
  String get newsLeagueFixtureScheduled => '治具';

  @override
  String get newsLeagueFixtureLive => 'ライブ';

  @override
  String get newsLeagueFixtureFullTime => 'FT';

  @override
  String newsLeagueTeamDetailTitle(String team) {
    return '$team 情報';
  }

  @override
  String get newsLeagueTeamDetailRosterTitle => '選手名簿';

  @override
  String get newsLeagueTeamDetailTacticsTitle => '戦術';

  @override
  String get newsLeagueTeamDetailFixturesTitle => 'チーム日程';

  @override
  String get newsLeagueTeamDetailNoFixtures => '読み込んだ日程内で、このチームの試合は見つかりませんでした。';

  @override
  String get newsLeagueTeamDetailTacticsSummary =>
      '現在の順位表と得失点データからチームの流れを確認できます。公式の戦術や選手名簿が提供された場合は、この画面に表示されます。';

  @override
  String get newsLeagueTeamDetailSourceNote => '公式リーグフィードで確認できる情報のみ表示します。';

  @override
  String get newsLeagueFavoriteTeamTitle => '好きなチーム';

  @override
  String get newsLeagueFavoriteTeamManage => 'お気に入りのチームを選択してください';

  @override
  String get newsLeagueFavoriteTeamSubtitle =>
      'お気に入りのチームを選択して、ロードされた試合に関するアラートを受け取ります。';

  @override
  String get newsLeagueFavoriteTeamSelect => 'チームを選択する';

  @override
  String get newsLeagueFavoriteTeamClear => 'クリア';

  @override
  String get newsLeagueFavoriteTeamNone => 'チームが選択されていません';

  @override
  String get newsLeagueFavoriteTeamSheetTitle => 'お気に入りのチームを選択してください';

  @override
  String get newsLeagueFavoriteTeamSaveAction => '保存';

  @override
  String get newsLeagueFavoriteTeamLoadError => 'チームリストを読み込めませんでした。';

  @override
  String get newsLeagueFavoriteTeamEmpty => '利用可能なチームはありません。';

  @override
  String newsLeagueFavoriteTeamSelectedCount(int count) {
    return '$count team(s) selected';
  }

  @override
  String get newsLeagueFavoriteTeamSaved => 'お気に入りのチームが保存されました。';

  @override
  String get newsLeagueFavoriteTeamNoUpcoming => '一致アラートはスケジュールされていません。';

  @override
  String newsLeagueFavoriteTeamReminderCount(int count) {
    return '$count マッチアラートがスケジュールされています';
  }

  @override
  String newsLeagueFavoriteTeamNotificationBody(
      Object team, Object opponent, Object kickoff) {
    return '$team 試合に関するアラート: $kickoff での対 $opponent';
  }

  @override
  String get newsLeagueFixtureNotificationChannelName => 'リーグの試合速報';

  @override
  String get newsLeagueFixtureNotificationChannelDescription =>
      '優先リーグチームの試合日程アラート';

  @override
  String get notificationAppTitle => 'テオのノート';

  @override
  String get worldCupFixtureNotificationChannelName => 'W杯試合通知';

  @override
  String get worldCupFixtureNotificationChannelDescription => '選択したW杯出場国の日程通知';

  @override
  String worldCupFixtureNotificationBody(
      Object team, Object opponent, Object kickoff) {
    return '$team W杯の試合: $opponent戦 $kickoff';
  }

  @override
  String get newsLeagueStandingsTeamColumn => 'チーム';

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
  String get newsLeagueStandingsPointsColumn => 'ポイント';

  @override
  String get newsSearchAction => 'ニュースを検索';

  @override
  String get newsChannelsAction => 'チャンネル';

  @override
  String get newsShowAllNewsAction => 'すべてのニュースを表示';

  @override
  String get newsShowScrappedOnlyAction => 'スクラップのみを表示';

  @override
  String get newsViewedHistoryAction => '閲覧したニュース';

  @override
  String get newsViewedHistoryTitle => '閲覧したニュース';

  @override
  String get newsViewedHistoryEmpty => 'まだ閲覧されたニュースはありません。';

  @override
  String get newsTitleTranslateEnabledTooltip => 'タイトル翻訳オン';

  @override
  String get newsTitleTranslateDisabledTooltip => 'タイトル翻訳オフ';

  @override
  String get newsTranslateAction => '翻訳する';

  @override
  String get newsSelectChannelsTitle => 'ニュースチャンネルを選択する';

  @override
  String get newsSelectAll => 'すべて選択';

  @override
  String get newsClearAll => 'すべてクリア';

  @override
  String get newsDomesticFeedsLabel => '韓国フィード';

  @override
  String get newsInternationalFeedsLabel => '国際フィード';

  @override
  String get newsRegionAllLabel => '全て';

  @override
  String get newsRegionDomesticLabel => '韓国';

  @override
  String get newsRegionInternationalLabel => '世界';

  @override
  String get newsNationalSnapshotTitle => '代表チームのスナップショット';

  @override
  String get newsNationalSnapshotSubtitle => '韓国男子チーム概要（公式ページより）';

  @override
  String get newsFifaRankingTitle => 'FIFAランキング';

  @override
  String get newsRankingCurrentLabel => '現在のランク';

  @override
  String get newsRankingUpdatedLabel => '更新されました';

  @override
  String get newsRecentAMatchTitle => '最近のAマッチ';

  @override
  String get newsRecentAMatchEmpty => '最近のAマッチ結果は見つかりませんでした。';

  @override
  String get newsOpenOfficialSource => '公式ページを開く';

  @override
  String get newsOfficialSourceFifa => 'FIFA公式';

  @override
  String get newsOfficialSourceKfa => 'KFA関係者';

  @override
  String get newsMatchResultWin => '勝つ';

  @override
  String get newsMatchResultDraw => '描く';

  @override
  String get newsMatchResultLoss => '損失';

  @override
  String matchKickoffKoreaOnly(String time) {
    return '韓国時間 $time';
  }

  @override
  String matchKickoffLocalAndKorea(String localTime, String koreaTime) {
    return '$localTime · 韓国時間 $koreaTime';
  }

  @override
  String get worldCupTitle => 'ワールドカップ表示';

  @override
  String get worldCupInfoAction => '説明';

  @override
  String get worldCupSourceShortAction => 'FIFA';

  @override
  String get worldCupHeroTitle => 'FIFAワールドカップ2026';

  @override
  String get worldCupHeroSubtitle => 'カナダ、メキシコ、アメリカ · 48チーム';

  @override
  String worldCupCountdownDays(int days) {
    return 'あと$days日';
  }

  @override
  String get worldCupCountdownToday => '開幕日';

  @override
  String get worldCupCountdownStarted => '大会開催中';

  @override
  String get worldCupCountdownComplete => '大会終了';

  @override
  String get worldCupScheduleTab => '日程';

  @override
  String get worldCupStandingsTab => '順位';

  @override
  String get worldCupTournamentTab => 'トーナメント';

  @override
  String get worldCupOverviewTitle => '大会概要';

  @override
  String get worldCupOverviewIntro =>
      '今回のワールドカップはこれまでより大きく、カナダ、メキシコ、アメリカで48か国が12グループに分かれて104試合を行います。';

  @override
  String get worldCupHostsLabel => '開催国';

  @override
  String get worldCupHostsValue => 'カナダ · メキシコ · アメリカ';

  @override
  String get worldCupDatesLabel => '日程';

  @override
  String worldCupDateRange(String start, String end) {
    return '$start - $end';
  }

  @override
  String get worldCupFormatLabel => '形式';

  @override
  String get worldCupFormatValue => '48チーム · 12グループ';

  @override
  String get worldCupMatchesLabel => '試合';

  @override
  String get worldCupMatchesValue => '16開催都市で104試合';

  @override
  String worldCupMatchesCountValue(int count) {
    return '16開催都市で$count試合';
  }

  @override
  String get worldCupGuideFormatTitle => '今回の進み方';

  @override
  String get worldCupGuideFormatBullets =>
      '48か国が4チームずつ12グループに分かれます。\n各国はグループで3試合を行います。\n各グループの1位と2位、そして3位の中で成績のよい8チームが進みます。\nその後のラウンド32からは、1回負けると敗退するトーナメントです。';

  @override
  String get worldCupGuideMatchRulesTitle => '試合の基本ルール';

  @override
  String get worldCupGuideMatchRulesBullets =>
      '1試合は前半45分、後半45分です。\nグループステージは引き分けで終わることがあり、両チームが勝点1を得ます。\nトーナメントで90分後に同点なら延長戦を行い、それでも同点ならPK戦で勝者を決めます。\nグループステージの勝点は勝ち3、引き分け1、負け0です。';

  @override
  String get worldCupGuideTiebreakTitle => '順位が同じとき';

  @override
  String get worldCupGuideTiebreakBullets =>
      '最初に勝点を見ます。\n同じグループで勝点が並んだら、直接対決の勝点、直接対決の得失点差、直接対決の得点を順に見ます。\nまだ同じなら、全体の得失点差、全体の得点、チーム行動スコア、最新のFIFAランキングを見ます。\n3位チーム同士は、勝点、得失点差、得点、チーム行動スコア、FIFAランキングの順で上位8チームを決めます。';

  @override
  String get worldCupGuideRefereeTitle => '審判とサポート';

  @override
  String get worldCupGuideRefereeBullets =>
      'FIFAは大会のために主審52人、副審88人、ビデオ審判30人を選びました。\nピッチでは主審1人が試合を進め、副審2人、第四審判、必要な予備審判が助けます。\n副審はオフサイド、スローイン、ゴールキック、コーナーキック、交代、PKの確認を助けます。\n最後の決定はいつも主審が行います。';

  @override
  String get worldCupGuideVarTitle => 'VARとテクノロジー';

  @override
  String get worldCupGuideVarBullets =>
      'VARはビデオで大事な場面を確認する審判です。\nゴールかどうか、PKかどうか、直接レッドカードか、カードを受けた選手が正しいかなどを確認します。\n主審は必要なら画面を見てオンフィールドレビューを行いますが、最終判断は主審がします。\nゴールライン技術、進化した半自動オフサイド支援、コネクテッドボール技術も、事実判定を速く正確にする助けになります。';

  @override
  String get worldCupTeamSettingsTitle => '自分のワールドカップ国';

  @override
  String get worldCupSupportCountryLabel => '応援する国';

  @override
  String get worldCupInterestCountriesLabel => '注目国';

  @override
  String get worldCupInterestCountriesEmpty => '注目国はまだ選択されていません。';

  @override
  String get worldCupEditInterestCountriesAction => '国を編集';

  @override
  String get worldCupClearInterestCountriesAction => 'クリア';

  @override
  String get worldCupSelectedCountriesOnly => '選択した国の試合のみ表示';

  @override
  String get worldCupHighlightedMatchesTitle => '選択国の試合';

  @override
  String get worldCupNoHighlightedMatches => '応援する国や注目国を選ぶと、その試合日程が強調されます。';

  @override
  String get worldCupCalendarTitle => '全試合カレンダー';

  @override
  String worldCupDayMatchesTitle(String date, int count) {
    return '$date · $count試合';
  }

  @override
  String get worldCupNoMatchesOnDay => 'この日に試合はありません。';

  @override
  String worldCupMatchNumber(int number) {
    return 'M$number';
  }

  @override
  String get worldCupVersusShort => '対';

  @override
  String get worldCupMatchScheduled => '予定';

  @override
  String get worldCupMatchLive => 'ライブ';

  @override
  String get worldCupMatchAwaitingUpdate => '結果更新待ち';

  @override
  String get worldCupMatchResultFinal => '結果';

  @override
  String get worldCupMatchDetailTitle => '試合詳細';

  @override
  String get worldCupMatchComparisonTitle => '戦力比較';

  @override
  String get worldCupMatchRecordsTitle => '試合記録';

  @override
  String get worldCupMatchRecordUnavailable => '公式データが利用可能になると、ライブ試合記録が表示されます。';

  @override
  String get worldCupMatchDetailLoading => 'FIFAの試合データを読み込んでいます...';

  @override
  String get worldCupMatchScorersTitle => '得点者';

  @override
  String get worldCupMatchLineupsTitle => 'ラインアップ';

  @override
  String get worldCupStartingPlayersLabel => '先発';

  @override
  String get worldCupBenchPlayersLabel => 'ベンチ';

  @override
  String get worldCupCaptainAbbreviation => '(C)';

  @override
  String get worldCupOfficialSourceNote =>
      'スコア、選手リスト、試合記録は、このページを開くたびにFIFAデータから更新されます。';

  @override
  String get worldCupMatchPossessionLabel => 'ポゼッション';

  @override
  String worldCupMatchPossessionValue(int home, int away) {
    return '$home% · $away%';
  }

  @override
  String get worldCupMatchAttendanceLabel => '観客数';

  @override
  String get worldCupMatchTacticsLabel => '戦術';

  @override
  String worldCupPlayerProfileTitle(String player) {
    return '$player プロフィール';
  }

  @override
  String get worldCupPlayerProfileTeamLabel => '代表チーム';

  @override
  String get worldCupPlayerProfilePositionLabel => 'ポジション';

  @override
  String get worldCupPlayerProfileClubLabel => '所属クラブ';

  @override
  String get worldCupPlayerClubPending => 'クラブ更新待ち';

  @override
  String get worldCupPlayerProfileSourceNote => '公式写真がない場合は、選手の顔アイコンを表示します。';

  @override
  String get worldCupScorePending => '- : -';

  @override
  String worldCupScoreLine(int homeScore, int awayScore) {
    return '$homeScore : $awayScore';
  }

  @override
  String get worldCupResultPendingTeam => '試合前';

  @override
  String get worldCupResultWin => '勝';

  @override
  String get worldCupResultDraw => '分';

  @override
  String get worldCupResultLoss => '敗';

  @override
  String get worldCupResultWinSummary => '勝ち';

  @override
  String get worldCupResultDrawSummary => '引き分け';

  @override
  String get worldCupResultLossSummary => '負け';

  @override
  String worldCupGroupStageLabel(String group) {
    return 'グループ$group';
  }

  @override
  String get worldCupRoundOf32Label => 'ラウンド32';

  @override
  String get worldCupRoundOf16Label => 'ラウンド16';

  @override
  String get worldCupQuarterFinalLabel => '準々決勝';

  @override
  String get worldCupSemiFinalLabel => '準決勝';

  @override
  String get worldCupThirdPlaceLabel => '3位決定戦';

  @override
  String get worldCupFinalLabel => '決勝';

  @override
  String get worldCupCountryAlgeria => 'アルジェリア';

  @override
  String get worldCupCountryArgentina => 'アルゼンチン';

  @override
  String get worldCupCountryAustralia => 'オーストラリア';

  @override
  String get worldCupCountryAustria => 'オーストリア';

  @override
  String get worldCupCountryBelgium => 'ベルギー';

  @override
  String get worldCupCountryBosniaAndHerzegovina => 'ボスニア・ヘルツェゴビナ';

  @override
  String get worldCupCountryBrazil => 'ブラジル';

  @override
  String get worldCupCountryCanada => 'カナダ';

  @override
  String get worldCupCountryCapeVerde => 'カーボベルデ';

  @override
  String get worldCupCountryColombia => 'コロンビア';

  @override
  String get worldCupCountryCongoDr => 'コンゴ民主共和国';

  @override
  String get worldCupCountryCroatia => 'クロアチア';

  @override
  String get worldCupCountryCuracao => 'キュラソー';

  @override
  String get worldCupCountryCzechia => 'チェコ';

  @override
  String get worldCupCountryEcuador => 'エクアドル';

  @override
  String get worldCupCountryEgypt => 'エジプト';

  @override
  String get worldCupCountryEngland => 'イングランド';

  @override
  String get worldCupCountryFrance => 'フランス';

  @override
  String get worldCupCountryGermany => 'ドイツ';

  @override
  String get worldCupCountryGhana => 'ガーナ';

  @override
  String get worldCupCountryHaiti => 'ハイチ';

  @override
  String get worldCupCountryIran => 'イラン';

  @override
  String get worldCupCountryIraq => 'イラク';

  @override
  String get worldCupCountryIvoryCoast => 'コートジボワール';

  @override
  String get worldCupCountryJapan => '日本';

  @override
  String get worldCupCountryJordan => 'ヨルダン';

  @override
  String get worldCupCountryKoreaRepublic => '韓国';

  @override
  String get worldCupCountryMexico => 'メキシコ';

  @override
  String get worldCupCountryMorocco => 'モロッコ';

  @override
  String get worldCupCountryNetherlands => 'オランダ';

  @override
  String get worldCupCountryNewZealand => 'ニュージーランド';

  @override
  String get worldCupCountryNorway => 'ノルウェー';

  @override
  String get worldCupCountryPanama => 'パナマ';

  @override
  String get worldCupCountryParaguay => 'パラグアイ';

  @override
  String get worldCupCountryPortugal => 'ポルトガル';

  @override
  String get worldCupCountryQatar => 'カタール';

  @override
  String get worldCupCountrySaudiArabia => 'サウジアラビア';

  @override
  String get worldCupCountryScotland => 'スコットランド';

  @override
  String get worldCupCountrySenegal => 'セネガル';

  @override
  String get worldCupCountrySouthAfrica => '南アフリカ';

  @override
  String get worldCupCountrySpain => 'スペイン';

  @override
  String get worldCupCountrySweden => 'スウェーデン';

  @override
  String get worldCupCountrySwitzerland => 'スイス';

  @override
  String get worldCupCountryTunisia => 'チュニジア';

  @override
  String get worldCupCountryTurkiye => 'トルコ';

  @override
  String get worldCupCountryUsa => 'アメリカ';

  @override
  String get worldCupCountryUruguay => 'ウルグアイ';

  @override
  String get worldCupCountryUzbekistan => 'ウズベキスタン';

  @override
  String get worldCupVenueAttDallas => 'AT&Tスタジアム, ダラス';

  @override
  String get worldCupVenueBcPlaceVancouver => 'BCプレイス, バンクーバー';

  @override
  String get worldCupVenueBmoFieldToronto => 'BMOフィールド, トロント';

  @override
  String get worldCupVenueEstadioAkronGuadalajara => 'エスタディオ・アクロン, グアダラハラ';

  @override
  String get worldCupVenueEstadioAztecaMexicoCity => 'エスタディオ・アステカ, メキシコシティ';

  @override
  String get worldCupVenueEstadioBbvaMonterrey => 'エスタディオBBVA, モンテレイ';

  @override
  String get worldCupVenueGehaArrowheadKansasCity =>
      'GEHAフィールド・アット・アローヘッド・スタジアム, カンザスシティ';

  @override
  String get worldCupVenueGilletteBoston => 'ジレット・スタジアム, ボストン';

  @override
  String get worldCupVenueHardRockMiami => 'ハードロック・スタジアム, マイアミ';

  @override
  String get worldCupVenueLevisSanFranciscoBayArea =>
      'リーバイス・スタジアム, サンフランシスコ・ベイエリア';

  @override
  String get worldCupVenueLincolnFinancialPhiladelphia =>
      'リンカーン・フィナンシャル・フィールド, フィラデルフィア';

  @override
  String get worldCupVenueLumenSeattle => 'ルーメン・フィールド, シアトル';

  @override
  String get worldCupVenueMercedesBenzAtlanta => 'メルセデス・ベンツ・スタジアム, アトランタ';

  @override
  String get worldCupVenueMetLifeNewYorkNewJersey =>
      'メットライフ・スタジアム, ニューヨーク/ニュージャージー';

  @override
  String get worldCupVenueNrgHouston => 'NRGスタジアム, ヒューストン';

  @override
  String get worldCupVenueSofiLosAngeles => 'SoFiスタジアム, ロサンゼルス';

  @override
  String worldCupKickoffLocal(String time) {
    return '$time 現地時間';
  }

  @override
  String get worldCupSupportBadge => '応援';

  @override
  String get worldCupInterestBadge => '注目';

  @override
  String get worldCupKoreaTitle => '韓国代表を見る';

  @override
  String get worldCupKoreaBody => '韓国代表はグループAでチェコとのグアダラハラ初戦から始まります。';

  @override
  String get worldCupKoreaGroupLabel => 'グループ';

  @override
  String get worldCupKoreaGroup => 'グループA';

  @override
  String get worldCupKoreaOpenerLabel => '初戦';

  @override
  String get worldCupKoreaOpener => '韓国 対 チェコ · エスタディオ・グアダラハラ';

  @override
  String get worldCupMilestonesTitle => '決勝までの流れ';

  @override
  String get worldCupMilestoneOpeningLabel => '開幕戦';

  @override
  String get worldCupOpeningMatch =>
      'メキシコ 対 南アフリカ · 2026年6月11日 · メキシコシティ・スタジアム';

  @override
  String get worldCupMilestoneGroupLabel => 'グループステージ';

  @override
  String get worldCupGroupStage => '6月11日にグループステージが始まり、32チームの決勝トーナメントへ進みます。';

  @override
  String get worldCupMilestoneKnockoutLabel => '決勝トーナメント';

  @override
  String get worldCupKnockouts => 'グループステージ後にラウンド32が始まります。';

  @override
  String get worldCupMilestoneFinalLabel => '決勝';

  @override
  String get worldCupFinalMatch => '2026年7月19日 · ニューヨーク・ニュージャージー・スタジアム';

  @override
  String get worldCupStandingsTitle => 'グループ順位';

  @override
  String get worldCupStandingsPlanBody =>
      '日程に入った試合結果をもとに、グループ順位をすぐ整理します。公式の詳細タイブレークが確定するまでは、勝点、得失点差、得点、勝利、敗戦、国名の順で並べます。';

  @override
  String get worldCupStandingsRuleLabel => '順位基準';

  @override
  String get worldCupStandingsRuleValue =>
      '勝点 · 直接対決 · 得失点差 · 得点 · 行動スコア · FIFAランキング';

  @override
  String get worldCupStandingsTableTitle => 'グループ順位表';

  @override
  String get worldCupStandingsRankColumn => '順位';

  @override
  String get worldCupStandingsTeamColumn => '国';

  @override
  String get worldCupStandingsRecordColumn => '勝-分-敗';

  @override
  String get worldCupStandingsPointsColumn => '勝点';

  @override
  String worldCupStandingsRecordValue(int wins, int draws, int losses) {
    return '$wins-$draws-$losses';
  }

  @override
  String get worldCupGroupTeamsTitle => 'グループ別チーム';

  @override
  String worldCupTeamRosterOpenTooltip(String team) {
    return '$team の選手名簿を開く';
  }

  @override
  String worldCupTeamRosterTitle(String team) {
    return '$team 選手名簿';
  }

  @override
  String get worldCupTeamRosterSubtitle => 'ポジション別の名簿とフォーメーション配置でチームの形を確認できます。';

  @override
  String worldCupTeamRosterFormationLabel(String formation) {
    return '$formation フォーメーション';
  }

  @override
  String get worldCupTeamRosterSourceNote =>
      'この国の公式2026年スカッドデータはまだアプリに含まれていないため、安定した合法的なソースが接続されるまでポジション枠を表示します。';

  @override
  String get worldCupTeamRosterCandidateSourceNote =>
      '公開された2026年スカッド情報と予想フォーメーションデータをもとに表示しています。負傷交代や試合当日の選択はキックオフ前まで変わる可能性があります。';

  @override
  String get worldCupTeamRosterGoalkeepers => 'ゴールキーパー';

  @override
  String get worldCupTeamRosterDefenders => 'ディフェンダー';

  @override
  String get worldCupTeamRosterMidfielders => 'ミッドフィルダー';

  @override
  String get worldCupTeamRosterForwards => 'フォワード';

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
  String get worldCupTournamentTitle => 'トーナメント表';

  @override
  String get worldCupTournamentPlanBody =>
      '現在は公式日程のグループ順位枠と前試合の勝者枠を基準に表示します。グループ結果が確定したら、各枠を実際の国の道筋として追えます。';

  @override
  String worldCupStageMatchCount(int count) {
    return '$count試合';
  }

  @override
  String worldCupBracketRoundSummary(String dateRange, int count) {
    return '$dateRange · $count試合';
  }

  @override
  String worldCupBracketFirstSeed(String group) {
    return 'グループ$group 1位';
  }

  @override
  String worldCupBracketSecondSeed(String group) {
    return 'グループ$group 2位';
  }

  @override
  String worldCupBracketThirdSeed(String groups) {
    return '$groupsの3位チームから1チーム';
  }

  @override
  String worldCupBracketWinnerSlot(int matchNumber) {
    return 'M$matchNumber勝者';
  }

  @override
  String worldCupBracketLoserSlot(int matchNumber) {
    return 'M$matchNumber敗者';
  }

  @override
  String worldCupBracketSourceMatch(int matchNumber, String home, String away) {
    return 'M$matchNumber: $home 対 $away';
  }

  @override
  String get worldCupSourceAction => 'FIFA日程を開く';

  @override
  String get worldCupOfficialRefreshAction => 'FIFAデータを更新';

  @override
  String get worldCupOfficialRefreshing => 'FIFA更新中';

  @override
  String get worldCupOfficialUnavailable => 'FIFA利用不可';

  @override
  String worldCupOfficialUpdatedAt(String time) {
    return 'FIFA $time';
  }

  @override
  String get homeTodayPlanCardTitle => '今日のトレーニングプラン';

  @override
  String homeTodayPlanCardSummary(int count) {
    return '今日: $count プラン';
  }

  @override
  String get homeTodayPlanOpenAction => 'オープンプラン';

  @override
  String get homeTodayPlanSelectForLogTitle => 'トレーニングログにするプランを選択してください';

  @override
  String get homeHubTitleShort => '家';

  @override
  String get homeDailyCheckTitle => '今日のタスク';

  @override
  String homeDailyCheckCompletedCount(int completed, int total) {
    return '$completed/$total完成しました';
  }

  @override
  String get homeTodoTrainingLogShort => 'ログ';

  @override
  String get homeTodoLiftingShort => 'リフティング';

  @override
  String get homeTodoJumpRopeShort => 'ジャンプ';

  @override
  String get jumpRopeRecordTitle => '縄跳び記録';

  @override
  String get jumpRopeMinutesLabel => '縄跳び時間(分)';

  @override
  String get jumpRopeCountLabel => '縄跳び回数';

  @override
  String get jumpRopeMemoLabel => 'メモ';

  @override
  String get jumpRopeMemoHint => '縄跳び中に感じたことを書いてください。';

  @override
  String get homeTodoQuizShort => 'クイズ';

  @override
  String get homeTodoNewsShort => 'ニュース';

  @override
  String get homeTodoDiaryShort => '日記';

  @override
  String get homeTodoBoardSketchShort => 'スケッチ';

  @override
  String get homeQuickActionsTitle => 'クイック操作';

  @override
  String get homeQuickActionMatch => '試合を記録';

  @override
  String get homeQuickActionPlan => '練習計画を追加';

  @override
  String get homeContinueTitle => '続きから';

  @override
  String get homeContinueEmpty => '今日は続きから再開する項目がありません。下から新しいアクションを選びましょう。';

  @override
  String get homeContinueWrongAnswerReview => '間違えた問題の復習を続ける';

  @override
  String get homeContinueQuiz => 'クイズを続ける';

  @override
  String get homeContinueStartQuiz => '新しいクイズを始める';

  @override
  String homeContinueQuizProgress(int current, int total) {
    return '$current / $total 進行中';
  }

  @override
  String get homeContinueQuizStartSubtitle => '今日のクイズをもう一度始めましょう。';

  @override
  String get homeContinueTodayTrainingLog => '今日の練習記録';

  @override
  String homeContinueTrainingDuration(Object date, int duration) {
    return '$date · $duration分';
  }

  @override
  String get homeContinueTrainingButton => '続きを書く';

  @override
  String get homeContinueTodayPlanTitle => '今日の練習計画';

  @override
  String homeContinueTodayPlanSubtitle(int count) {
    return '今日の計画が $count 件あります。';
  }

  @override
  String get homeContinuePlanButton => '計画を見る';

  @override
  String get homeContinueQuizButton => 'クイズを開く';

  @override
  String get homeContinueRecentBoardTitle => '最近の練習ボード';

  @override
  String homeContinueBoardCount(int count) {
    return 'スケッチ $count 件';
  }

  @override
  String homeContinueBoardSaved(Object title, Object date) {
    return '$title · 最近保存 $date';
  }

  @override
  String get homeContinueBoardButton => '今すぐ編集';

  @override
  String get dailyTasksXpDialogTitle => '今日のタスクは完了しました';

  @override
  String get dailyTasksXpDialogMessage => 'ルーチン全体がチェックされます。その一貫性が成長の原動力となりました。';

  @override
  String dailyTasksXpDialogGems(int count) {
    return '+$count ジェム';
  }

  @override
  String dailyTasksXpDialogProgress(int totalXp, int remainingXp) {
    return '次のレベルへの合計 $totalXp XP · $remainingXp XP';
  }

  @override
  String dailyTasksXpDialogMaxProgress(int totalXp, int remainingXp) {
    return '次のマスタリースターまでの合計 $totalXp XP · $remainingXp XP';
  }

  @override
  String get dailyTasksXpDialogAction => '続けて';

  @override
  String get trainingXpDialogTitle => 'トレーニングログが保存されました';

  @override
  String get trainingXpDialogMessage => '保存されたトレーニング ログにより、XP と成長ジェムが追加されました。';

  @override
  String get trainingXpDialogJumpRopeTitle => '縄跳びのリズムが保存されました';

  @override
  String get trainingXpDialogJumpRopeMessage =>
      '追加された縄跳びのワークは、足の速い成長の宝石になりました。';

  @override
  String get trainingXpDialogLiftingTitle => '持ち上げる労力を節約';

  @override
  String get trainingXpDialogLiftingMessage =>
      '追加されたリフティング作業は、より強い体の成長の宝石となりました。';

  @override
  String get trainingXpDialogMealTitle => '回復ルーチンが保存されました';

  @override
  String get trainingXpDialogMealMessage => '食事と回復の記録により、着実な成長の宝石が追加されました。';

  @override
  String get diaryXpDialogTitle => 'ダイアリーサファイア';

  @override
  String get diaryXpDialogMessage => 'あなたの反射は穏やかなサファイア XP に変わりました。';

  @override
  String get trainingSketchXpDialogTitle => 'スケッチゴールド';

  @override
  String get trainingSketchXpDialogMessage =>
      'トレーニングのアイデア スケッチが、明るい金色の XP に変わりました。';

  @override
  String trainingXpDialogXp(int count) {
    return '+$count XP';
  }

  @override
  String get trainingXpDialogRewardLabel => '獲得XP';

  @override
  String get trainingXpDialogTotalLabel => '累計XP';

  @override
  String trainingXpDialogTotalValue(int totalXp) {
    return '$totalXp XP';
  }

  @override
  String get trainingXpDialogLevelLabel => '現在のレベル';

  @override
  String trainingXpDialogLevelValue(int level, String levelName) {
    return 'Lv.$level $levelName';
  }

  @override
  String get trainingXpDialogAction => 'わかりました';

  @override
  String get trainingXpSourceTrainingLog => 'トレーニングログ';

  @override
  String get trainingXpSourceTrainingUpdate => 'トレーニングの最新情報';

  @override
  String get trainingXpSourceLifting => 'リフティング';

  @override
  String get trainingXpSourceJumpRope => '縄跳び';

  @override
  String get trainingXpSourceTrainingSketch => 'トレーニングスケッチ';

  @override
  String get trainingXpSourceDiary => '日記';

  @override
  String get trainingSaveToastPlain => 'トレーニングノートが保存されました。';

  @override
  String trainingSaveToastWithXp(int gainedXp, Object details) {
    return 'トレーニングノートが保存されました。 +$gainedXp XP・$details';
  }

  @override
  String trainingSaveToastLevelUp(
      int gainedXp, Object details, int level, Object levelName) {
    return 'トレーニングノートが保存されました。 +$gainedXp XP · $details · Lv.$level $levelNameに到達';
  }

  @override
  String get trainingXpToastReasonLiftingMissed => 'リフトミス';

  @override
  String get trainingXpToastReasonJumpRopeMissed => '縄跳びを失敗した';

  @override
  String get trainingXpToastReasonMealFullBonus => '三食+丼5杯以上';

  @override
  String get trainingXpToastReasonRoutineComplete => 'トレーニングルーチンが完了しました';

  @override
  String get trainingXpToastReasonStreakDaily2 => '2～3日連続ボーナス';

  @override
  String get trainingXpToastReasonStreakDaily4 => '4～6日連続ボーナス';

  @override
  String get trainingXpToastReasonStreakDaily7 => '7日以上連続ボーナス';

  @override
  String get trainingXpToastReasonStreak3 => '3日連続';

  @override
  String get trainingXpToastReasonStreak7 => '7日連続';

  @override
  String get trainingXpToastReasonWeekly3 => '今週は3ログ';

  @override
  String get trainingXpToastReasonWeekly5 => '今週は5ログ';

  @override
  String get trainingXpToastReasonDailyCap => '1 日あたりの上限が適用される';

  @override
  String trainingXpToastMoreReasons(int count) {
    return 'もっと見る';
  }

  @override
  String diarySavedWithXpFeedback(int count) {
    return '日記が保存されました +$count XP';
  }

  @override
  String trainingStreakCheerTitle(int count) {
    return '$count 1 日連続トレーニング';
  }

  @override
  String get trainingStreakCheerMessage =>
      '日々のトレーニングノートが実際のルーチンにつながっています。次のセッションはシンプルで繰り返し可能なものにしてください。';

  @override
  String get trainingStreakCheerAction => '続けて';

  @override
  String get levelUpDialogTitle => 'レベルアップ！';

  @override
  String levelUpDialogLevelLabel(int level, Object levelName) {
    return 'Lv.$level $levelName';
  }

  @override
  String get levelUpDialogEncouragement =>
      '今日の取り組みが明るい成長となりました。次のセッションでもこのリズムを維持してください。';

  @override
  String levelUpDialogEncouragementWithReward(Object rewardName) {
    return '今日の努力は輝かしい成長となり、$rewardNameも準備が整いました。';
  }

  @override
  String levelUpDialogProgress(int xp, Object stageName) {
    return '+$xp ジェムを獲得しました · 現在は $stageName です';
  }

  @override
  String get levelUpDialogRewardTitle => '褒美';

  @override
  String get levelUpDialogLater => '後で';

  @override
  String get levelUpDialogClaimReward => '報酬を受け取る';

  @override
  String get levelUpDialogConfirm => '素晴らしい';

  @override
  String levelUpRewardClaimed(Object rewardName) {
    return '$rewardNameを主張しました。';
  }

  @override
  String get xpGuideDailyTasksCompleteTitle => '今日のタスクはすべて完了しました';

  @override
  String get quizXpSourceLabel => 'サッカークイズ';

  @override
  String get quizScreenTitle => '今日のクイズ';

  @override
  String get quizLibraryAction => '問題';

  @override
  String get quizHistoryAction => '履歴';

  @override
  String get quizBackHomeTooltip => 'クイズホームに戻る';

  @override
  String get quizResultMissReviewCountLabel => '復習するミス';

  @override
  String get quizResultNoMissedQuestions => '今回のセットにミスした問題はありません。';

  @override
  String quizXpSavedFeedback(int count) {
    return 'クイズ完了 +$count XP';
  }

  @override
  String get playerXpGuideTitle => 'XPの上がり方';

  @override
  String playerXpGuideHeroLevel(int level) {
    return 'あなたはLv.$levelです';
  }

  @override
  String playerXpGuideHeroBody(int remainingXp) {
    return 'このページでは、すべての XP ソースを明確にグループ化します。 $remainingXp XP は次のレベルまで残ります。';
  }

  @override
  String playerXpGuideHeroMax(int masterySpan, int remainingXp) {
    return 'Lv.20以降、$masterySpan XPごとにマスタリースターを獲得します。 $remainingXp XP は次のスターまで残ります。';
  }

  @override
  String get playerXpGuideLoggingTitle => 'トレーニングログからのXP';

  @override
  String get playerXpGuideLoggingSubtitle =>
      'コアの成長は、一貫したトレーニング ログを保存することで実現します。';

  @override
  String get playerXpGuideTrainingLogSaved => 'トレーニングログが保存されました';

  @override
  String get playerXpGuideFirstDailyLog => 'その日の最初のログ';

  @override
  String get playerXpGuidePlannedDayComplete => '計画された日を完了する';

  @override
  String get playerXpGuideLiftingRecorded => 'リフティングを記録しました';

  @override
  String get playerXpGuideJumpRopeRecorded => '縄跳びを録画しました';

  @override
  String get playerXpGuideTrainingRoutineComplete => 'リフティング+縄跳び+リカバリーを完了する';

  @override
  String get playerXpGuideMissingConditioning => 'リフティングや縄跳びを失敗すると XP が消費されます';

  @override
  String get playerXpGuideMissingConditioningXp => '各 -5 XP';

  @override
  String get playerXpGuideStreakTitle => '連続ボーナスと毎週のボーナス';

  @override
  String get playerXpGuideStreakSubtitle => '繰り返しが安定すると、より大きなボーナスがロック解除されます。';

  @override
  String get playerXpGuideStreakMilestones => '3日/7日連続';

  @override
  String get playerXpGuideStreakDailyBonus => '連続記録による毎日のボーナス';

  @override
  String get playerXpGuideWeeklyBonus => '1週間に3ログ/5ログ';

  @override
  String get playerXpGuideActivityTitle => 'その他のアクティビティ XP';

  @override
  String get playerXpGuideActivitySubtitle =>
      '計画、スケッチ、食事、日記、クイズ、毎日の完了も保存時に XP を追加します。';

  @override
  String get playerXpGuidePlanCreated => 'トレーニング計画を作成しました';

  @override
  String get playerXpGuideMatchLogged => '試合ログが保存されました';

  @override
  String get playerXpGuideTrainingSketchSaved => 'トレーニングスケッチが保存されました';

  @override
  String get playerXpGuideTrainingSketchSavedXp => '+5 XP / +2 XP';

  @override
  String get playerXpGuideDiaryCreated => '日記が作成されました';

  @override
  String get playerXpGuideQuizComplete => 'クイズが完了しました';

  @override
  String get playerXpGuideQuizCompleteXp => '正解数に応じて +2〜+15 XP';

  @override
  String get playerXpGuideMealTwoPlus => '2 回以上の食事が記録されている';

  @override
  String get playerXpGuideMealFull => '3食/3食丼5杯以上';

  @override
  String get playerXpGuideDailyTasksComplete => '毎日の家事がすべて完了しました';

  @override
  String get playerXpGuideDailyCap => '1 日あたりのプラス XP の上限';

  @override
  String get playerLevelName1 => 'キックオフ';

  @override
  String get playerLevelName2 => 'ルーキー';

  @override
  String get playerLevelName3 => 'スターター';

  @override
  String get playerLevelName4 => 'チャレンジャー';

  @override
  String get playerLevelName5 => '司令塔';

  @override
  String get playerLevelName6 => 'エンジン';

  @override
  String get playerLevelName7 => 'キャプテン';

  @override
  String get playerLevelName8 => 'エリート';

  @override
  String get playerLevelName9 => 'マッチリーダー';

  @override
  String get playerLevelName10 => 'ハイパフォーマー';

  @override
  String get playerLevelName11 => 'ドライバ';

  @override
  String get playerLevelName12 => 'フィールドメーカー';

  @override
  String get playerLevelName13 => '管制塔';

  @override
  String get playerLevelName14 => 'アイアンキャプテン';

  @override
  String get playerLevelName15 => 'ゲームチェンジャー';

  @override
  String get playerLevelName16 => 'セッションマスター';

  @override
  String get playerLevelName17 => 'エースコア';

  @override
  String get playerLevelName18 => 'ピッチアーティスト';

  @override
  String get playerLevelName19 => 'スタジアムのアイコン';

  @override
  String get playerLevelName20 => 'フットボールギフトマスター';

  @override
  String get playerLevelStage1 => '新しい境地';

  @override
  String get playerLevelStage2 => 'トレーニングルーキー';

  @override
  String get playerLevelStage3 => 'ファーストチームの立ち上がり';

  @override
  String get playerLevelStage4 => 'マッチリーダー';

  @override
  String get playerLevelStage5 => '上段';

  @override
  String get playerLevelStage6 => 'コアエース';

  @override
  String get playerLevelStage7 => 'エリートトラック';

  @override
  String get playerLevelIllustration1 => 'スターターホイッスル';

  @override
  String get playerLevelIllustration2 => '初めてのサッカー';

  @override
  String get playerLevelIllustration3 => 'トレーニングコーン';

  @override
  String get playerLevelIllustration4 => 'スピードブーツ';

  @override
  String get playerLevelIllustration5 => '縄跳びのリズム';

  @override
  String get playerLevelIllustration6 => 'パワーダンベル';

  @override
  String get playerLevelIllustration7 => '戦術ボード';

  @override
  String get playerLevelIllustration8 => 'キャプテンクラウン';

  @override
  String get playerLevelIllustration9 => '優勝トロフィー';

  @override
  String get playerLevelIllustration10 => '祝賀花火';

  @override
  String get playerLevelIllustration11 => 'Defense shield';

  @override
  String get playerLevelIllustration12 => 'キーパーグローブ';

  @override
  String get playerLevelIllustration13 => '戦術レーダー';

  @override
  String get playerLevelIllustration14 => 'Sprint lightning';

  @override
  String get playerLevelIllustration15 => '勝利のメダル';

  @override
  String get playerLevelIllustration16 => 'ホームスタジアム';

  @override
  String get playerLevelIllustration17 => 'エースロケット';

  @override
  String get playerLevelIllustration18 => 'ピッチスター';

  @override
  String get playerLevelIllustration19 => 'スタジアムギフトボックス';

  @override
  String get playerLevelIllustration20 => 'レジェンドギャラクシー';

  @override
  String get levelGuideTitle => 'レベルガイド';

  @override
  String get levelGuideOpenXpGuideTooltip => 'XP ガイドを開く';

  @override
  String get levelGuideXpHistoryTooltip => 'XP 履歴';

  @override
  String get levelGuideCurrentProgressTitle => '現在の進捗状況';

  @override
  String levelGuideCurrentProgressTotal(int level, int totalXp) {
    return 'Lv.$level・$totalXp XP合計';
  }

  @override
  String levelGuideCurrentProgressMax(int stars, int remainingXp) {
    return '$stars マスタリー スター · $remainingXp XP は次のスターまで残ります。';
  }

  @override
  String levelGuideCurrentProgressNext(int remainingXp) {
    return '$remainingXp XP は次のレベルまで残ります。 XP ガイドと履歴については、右上のアクションを使用します。';
  }

  @override
  String get levelGuideSetRewardTitle => 'レベル報酬を設定する';

  @override
  String get levelGuideRewardNameLabel => '報酬名';

  @override
  String get levelGuideRewardNameHint => '例えば新しいサッカーソックス';

  @override
  String get levelGuideClearRewardAction => 'クリア';

  @override
  String get levelGuideCurrentBadge => '現在';

  @override
  String levelGuideXpRangeLabel(int minXp, int maxXp) {
    return '$minXp XP ～ $maxXp XP';
  }

  @override
  String get levelGuideRewardTitle => 'レベル報酬';

  @override
  String get levelGuideEditReward => '編集';

  @override
  String get levelGuideRewardNotSet => '未設定';

  @override
  String get levelGuideSyncing => '同期中...';

  @override
  String get levelGuideRewardNeedsName => '報酬を請求に追加する';

  @override
  String get levelGuideRewardAlreadyClaimed => 'すでに主張済み';

  @override
  String get levelGuideClaimReward => '報酬を受け取る';

  @override
  String levelGuideRewardLocked(int level) {
    return 'Lv.$levelで請求';
  }

  @override
  String get xpHistoryTitle => 'XP 履歴';

  @override
  String get xpHistoryClearAllAction => 'すべてクリア';

  @override
  String get xpHistoryEmpty => 'XP 履歴はまだありません。';

  @override
  String get xpHistoryMessageDeleted => 'XP メッセージが削除されました。';

  @override
  String get xpHistoryDeleteDialogTitle => 'XP メッセージを削除する';

  @override
  String get xpHistoryDeleteDialogBody => '保存されている XP メッセージをすべて削除しますか?';

  @override
  String get xpHistoryAllDeleted => 'すべての XP メッセージが削除されました。';

  @override
  String get xpHistoryRecentFlow => '最近の XP フロー';

  @override
  String xpHistorySummaryCount(int count) {
    return '$countの履歴項目が保存されます。';
  }

  @override
  String xpHistorySummaryLatest(Object title) {
    return '以下に、エントリを日付と時刻の順に並べます。最新エントリー：$title。';
  }

  @override
  String xpHistoryDayEventCount(int count) {
    return '$count XP イベント';
  }

  @override
  String get xpHistoryDeleteMessageTooltip => 'メッセージを削除する';

  @override
  String xpHistoryTotalXp(int totalXp) {
    return '$totalXp 合計 XP';
  }

  @override
  String xpHistoryStayedAtLevel(int level) {
    return 'Lv.$levelに滞在';
  }

  @override
  String get xpHistoryTrainingLog => 'トレーニングログ';

  @override
  String xpHistoryTrainingLogWithLabel(Object label) {
    return 'トレーニングログ・$label';
  }

  @override
  String get xpHistoryMatchLog => '試合ログが保存されました';

  @override
  String xpHistoryMatchLogWithLabel(Object label) {
    return '試合ログ・$label';
  }

  @override
  String get xpHistoryMealLog => '食事ログが保存されました';

  @override
  String get xpHistoryQuizCompletion => 'クイズの完了';

  @override
  String get xpHistoryPlanCreated => 'トレーニング計画を作成しました';

  @override
  String get xpHistoryBoardSaved => 'トレーニングスケッチが保存されました';

  @override
  String xpHistoryBoardSavedWithLabel(Object label) {
    return 'トレーニングスケッチ・$label';
  }

  @override
  String get xpHistoryDiaryCreated => '今日の日記を作成しました';

  @override
  String get xpHistoryDailyTasksComplete => '今日のタスクは完了しました';

  @override
  String get xpHistoryTrainingLabelLifting => 'リフティング';

  @override
  String get xpHistoryTrainingLabelJumpRope => '縄跳び';

  @override
  String get xpHistoryReasonLog => 'ベースログ';

  @override
  String get xpHistoryReasonFirstDailyLog => '一日の始まり';

  @override
  String get xpHistoryReasonPlanCompleted => '予定日';

  @override
  String get xpHistoryReasonLiftingRecorded => 'リフティングが記録されました';

  @override
  String get xpHistoryReasonJumpRopeRecorded => '縄跳びを録音しました';

  @override
  String get xpHistoryReasonLiftingMissed => '持ち上げなし';

  @override
  String get xpHistoryReasonJumpRopeMissed => '縄跳びはありません';

  @override
  String get xpHistoryReasonLiftingAdded => 'リフティングが追加されました';

  @override
  String get xpHistoryReasonJumpRopeAdded => '縄跳びを追加しました';

  @override
  String get xpHistoryReasonMealTwoPlus => '2食以上';

  @override
  String get xpHistoryReasonMealFullDay => '3食完食';

  @override
  String get xpHistoryReasonMealFullDayBonus => '3食+丼5杯以上';

  @override
  String get xpHistoryReasonStreak3 => '3日連続';

  @override
  String get xpHistoryReasonStreak7 => '7日連続';

  @override
  String get xpHistoryReasonStreakDaily2 => '毎日の連続 (2 ～ 3 日)';

  @override
  String get xpHistoryReasonStreakDaily4 => '毎日の連続 (4 ～ 6 日間)';

  @override
  String get xpHistoryReasonStreakDaily7 => '毎日の連続記録 (7 日以上)';

  @override
  String get xpHistoryReasonRoutineComplete => '日課完了';

  @override
  String get xpHistoryReasonWeekly3 => '今週は3件';

  @override
  String get xpHistoryReasonWeekly5 => '今週は5件';

  @override
  String get xpHistoryReasonQuizComplete => 'クイズ完了';

  @override
  String get xpHistoryReasonPlanCreated => '計画が作成されました';

  @override
  String xpHistoryReasonPlanGroupCreated(int count) {
    return '$count-プランシリーズ';
  }

  @override
  String get xpHistoryReasonMatchLogged => '記録された試合';

  @override
  String get xpHistoryReasonMatchResultRecorded => '記録された結果';

  @override
  String get xpHistoryReasonMatchContributionRecorded => '貢献が記録されました';

  @override
  String get xpHistoryReasonBoardCreated => 'ボードが作成されました';

  @override
  String get xpHistoryReasonBoardSaved => 'ボードが保存されました';

  @override
  String get xpHistoryReasonDiaryCreated => '日記が作成されました';

  @override
  String get xpHistoryReasonDailyTasksCompleted => '今日のタスクは完了しました';

  @override
  String get xpHistoryReasonDailyCap => '毎日の上限';

  @override
  String get profilePlayerLevelLabel => 'プレイヤーレベル';

  @override
  String get profileVisualGrowthTier => 'ビジュアル成長層';

  @override
  String profileRewardReadySummary(int count) {
    return '$count 報酬準備完了';
  }

  @override
  String get profileNoNextReward => '次の報酬はまだありません';

  @override
  String profileRewardNow(Object rewardName) {
    return '今すぐ報酬: $rewardName';
  }

  @override
  String profileNextReward(int level, Object rewardName) {
    return '次の報酬 Lv.$level $rewardName';
  }

  @override
  String profileLevelProgressMax(int stars, int remainingXp) {
    return '$stars マスタリー スター · $remainingXp XP が残っています';
  }

  @override
  String profileLevelProgressNext(int remainingXp, int totalXp) {
    return '次のレベルへの $remainingXp XP · 合計 $totalXp XP';
  }

  @override
  String homeLevelProgressMax(int stars, int remainingXp) {
    return '$stars スター · $remainingXp XP 残り';
  }

  @override
  String homeLevelProgressNext(int remainingXp) {
    return '$remainingXp XP 残り';
  }

  @override
  String get homePriorityCheckPlansMessage => '開始する前に、残りのトレーニング計画を確認してください。';

  @override
  String get homePriorityPlansAction => '予定';

  @override
  String get homePriorityPlanNextMessage => '短いトレーニング計画を追加します。';

  @override
  String get homePriorityPlanNextAction => 'プランの追加';

  @override
  String get homePriorityReviewWeekMessage => '今週のトレーニングの流れを確認し、次の目標を選択します。';

  @override
  String get homePriorityStatsAction => '統計';

  @override
  String get homePrioritySketchNextMessage => '次回のセッションで試してみたい動きをスケッチします。';

  @override
  String get homePriorityBoardAction => 'ボード';

  @override
  String get homePriorityConditionMessage => '最近の体調の傾向を確認し、回復を調整します。';

  @override
  String get homePriorityRewardsMessage => 'レベル報酬と次の成長目標を確認します。';

  @override
  String get homePriorityLevelAction => 'レベル';

  @override
  String get homeMealSuggestionDoneShort => '3回の食事はすべて記録されます。リズムを保ち続けてください。';

  @override
  String get homeMealSuggestionTwoShort => 'もう 1 回食事を記録してください。';

  @override
  String get homeMealSuggestionOneShort => 'あと 2 回の食事を記録してください。';

  @override
  String get homeMealSuggestionNoneShort => '今日の最初の食事から始めてください。';

  @override
  String get homeNextTrainingTitle => '次のトレーニング';

  @override
  String get homeNextTrainingToday => '今日';

  @override
  String get homeNextTrainingTomorrow => '明日';

  @override
  String homeNextTrainingInDays(int count) {
    return '$count 日以内';
  }

  @override
  String homeNextTrainingCount(int count) {
    return '$count予定';
  }

  @override
  String get profileTestsActionLabel => 'プロファイルテスト';

  @override
  String entryStartedFromPlanSummary(String summary) {
    return '今日の予定からスタート：$summary';
  }

  @override
  String get fifaHubAppBarTitle => 'FIFAランキングハブ';

  @override
  String get fifaHubHeroTitle => '世界的な FIFA ランキングと A マッチ トラッカー';

  @override
  String get fifaHubHeroSubtitle =>
      'FIFA 公式データから完全なランキング、最近の結果、今後の試合をチェックしてください。';

  @override
  String get fifaHubMenLabel => '男性';

  @override
  String get fifaHubWomenLabel => '女性';

  @override
  String get fifaHubLeaderLabel => '現在のNo.1';

  @override
  String fifaHubRankedTeamsCount(int count) {
    return '$count ランクのチーム';
  }

  @override
  String fifaHubConfederationCount(int count) {
    return '$count 連合';
  }

  @override
  String fifaHubRecentResultsCount(int count) {
    return '$count 最近の結果';
  }

  @override
  String fifaHubUpcomingFixturesCount(int count) {
    return '$count 今後の試合予定';
  }

  @override
  String get fifaHubNextUpdateLabel => '次回の更新';

  @override
  String get fifaHubDataSourceLabel => '出典: FIFA 公式ランキングとライブ試合フィード';

  @override
  String get fifaHubHighlightsTitle => '動きのハイライト';

  @override
  String get fifaHubBiggestClimber => '最大の登山者';

  @override
  String get fifaHubBiggestFaller => '最大の転倒者';

  @override
  String get fifaHubGlobalRankingTitle => '世界ランキング';

  @override
  String get fifaHubGlobalRankingSubtitle => 'セクションを開いて代表チームの順位を確認します。';

  @override
  String get fifaHubShowAll => 'すべて表示';

  @override
  String get fifaHubShowLess => '表示を少なくする';

  @override
  String get fifaHubShowAllList => '全リストを表示';

  @override
  String get fifaHubCollapseList => 'リストを閉じる';

  @override
  String get fifaHubRecentResultsTitle => '最近のワールドワイドAマッチ結果';

  @override
  String get fifaHubRecentResultsSubtitle =>
      'FIFA マッチフィードからフィルターされたシニア代表チームの試合。';

  @override
  String get fifaHubRecentResultsEmpty => '最近のワールドワイド A マッチの結果は見つかりませんでした。';

  @override
  String get fifaHubUpcomingFixturesTitle => '今後の世界的な A マッチの試合予定';

  @override
  String get fifaHubUpcomingFixturesSubtitle =>
      '最新のFIFAスケジュールウィンドウからの今後のシニア代表チームの試合。';

  @override
  String get fifaHubUpcomingFixturesEmpty => '今後のワールドワイド A マッチの試合は見つかりませんでした。';

  @override
  String get fifaHubKfaUpcomingFixturesTitle => 'KFA韓国試合スケジュール';

  @override
  String get fifaHubKfaUpcomingFixturesSubtitle => '大韓サッカー協会公式次試合フィードより。';

  @override
  String get fifaHubKfaUpcomingFixturesEmpty => 'KFA韓国の試合スケジュールは見つかりませんでした。';

  @override
  String get fifaHubKfaRecentResultsTitle => 'KFA韓国試合結果';

  @override
  String get fifaHubKfaRecentResultsSubtitle => '大韓サッカー協会公式試合結果フィードより。';

  @override
  String get fifaHubKfaRecentResultsEmpty => 'KFA Koreaの試合結果は見つかりませんでした。';

  @override
  String get fifaHubMatchStatusResult => '結果';

  @override
  String get fifaHubMatchStatusLive => 'ライブ';

  @override
  String get fifaHubMatchStatusFixture => '治具';

  @override
  String get fifaHubLoadError => 'FIFAデータのロードに失敗しました。プルダウンして更新します。';

  @override
  String get fifaHubNoData => '現在、FIFA ランキングや A マッチのデータは入手できません。';

  @override
  String get fifaMatchDetailTitle => '試合詳細';

  @override
  String get fifaMatchDetailResultSummaryTitle => '結果の概要';

  @override
  String get fifaMatchDetailFixtureSummaryTitle => '試合概要';

  @override
  String get fifaMatchDetailCompetitionLabel => '競争';

  @override
  String get fifaMatchDetailKickoffLabel => 'キックオフ';

  @override
  String get fifaMatchDetailDateLabel => '日付';

  @override
  String get fifaMatchDetailStageLabel => 'ステージ';

  @override
  String get fifaMatchDetailVenueLabel => '会場';

  @override
  String get fifaMatchDetailCityLabel => '市';

  @override
  String get fifaMatchDetailMatchIdLabel => '一致ID';

  @override
  String get fifaMatchDetailScoreUnavailable => 'スコアは未確認';

  @override
  String get fifaMatchDetailVersusLabel => '対';

  @override
  String get fifaMatchDetailHomeTeamLabel => '家';

  @override
  String get fifaMatchDetailAwayTeamLabel => '離れて';

  @override
  String get fifaMatchDetailScorersTitle => '得点者';

  @override
  String get fifaMatchDetailPossessionTitle => 'ボールポゼッション';

  @override
  String get fifaMatchDetailAdvancedLoading => '詳細な記録を確認しています...';

  @override
  String get fifaMatchDetailAdvancedUnavailable =>
      '得点者とボール保持率はソース データには見つかりませんでした。';

  @override
  String get fifaMatchDetailScorersUnavailable => '得点者情報が見つかりませんでした。';

  @override
  String get fifaMatchDetailPossessionUnavailable => 'ボール保持情報が見つかりませんでした。';

  @override
  String get fifaMatchDetailUnknownScorer => 'プレーヤーが提供されていません';

  @override
  String get fifaMatchDetailFifaSourceNote => 'FIFA公式試合APIをベースにしています。';

  @override
  String get fifaMatchDetailKfaSourceNote =>
      'KFA ホームフィードに基づいています。得点者とボール所有者は情報源から提供されない場合があります。';

  @override
  String get fifaMatchDetailOpenSource => 'オープンソース';

  @override
  String get fifaCountryDetailRankingSummaryTitle => 'ランキングまとめ';

  @override
  String get fifaCountryDetailTeamProfileTitle => 'チームプロフィール';

  @override
  String get fifaCountryDetailCurrentRankLabel => '現在のランク';

  @override
  String get fifaCountryDetailPreviousRankLabel => '前のランク';

  @override
  String get fifaCountryDetailPointsLabel => 'ポイント';

  @override
  String get fifaCountryDetailPointChangeLabel => 'ポイント変更';

  @override
  String get fifaCountryDetailConfederationLabel => '連合';

  @override
  String get fifaCountryDetailCountryCodeLabel => '国コード';

  @override
  String get fifaCountryDetailTeamIdLabel => 'FIFAチームID';

  @override
  String get fifaCountryDetailAbbreviationLabel => '略語';

  @override
  String get fifaCountryDetailFoundationYearLabel => '設立';

  @override
  String get fifaCountryDetailCityLabel => '市';

  @override
  String get fifaCountryDetailStadiumLabel => 'スタジアム';

  @override
  String get fifaCountryDetailAddressLabel => '住所';

  @override
  String get fifaCountryDetailProfileUnavailable =>
      '現在、追加の FIFA チーム プロフィールはありません。';

  @override
  String get fifaCountryDetailProfileSource => 'FIFA公式チームAPIからのプロフィールデータ。';

  @override
  String get fifaCountryDetailRecentMatchesTitle => 'このチームの最近のAマッチ';

  @override
  String get fifaCountryDetailUpcomingMatchesTitle => 'このチームの今後の A マッチ';

  @override
  String get fifaCountryDetailMatchesUnavailable =>
      '読み込まれた FIFA フィードにはこのチームの試合が見つかりませんでした。';

  @override
  String get tabGame => 'ミニゲーム';

  @override
  String get drawerMainScreens => 'メイン画面';

  @override
  String get drawerQuickAdd => 'クイック追加';

  @override
  String get drawerToolsContent => 'ツールとコンテンツ';

  @override
  String get drawerTrainingPlan => 'トレーニング計画';

  @override
  String get drawerMatch => 'マッチ';

  @override
  String get drawerAddTrainingSketch => 'トレーニングスケッチを追加';

  @override
  String get drawerNotifications => '通知';

  @override
  String get drawerQuiz => 'クイズ';

  @override
  String get addEntry => 'エントリの追加';

  @override
  String get editEntry => 'エントリーの編集';

  @override
  String get save => '保存';

  @override
  String get update => 'アップデート';

  @override
  String get add => '追加';

  @override
  String get edit => '編集';

  @override
  String get newItem => '新しいアイテム';

  @override
  String get trainingDate => 'トレーニング日';

  @override
  String get trainingDuration => 'トレーニング期間';

  @override
  String minutes(Object value) {
    return '$value 分';
  }

  @override
  String times(Object value) {
    return '$value 回';
  }

  @override
  String get notSet => '未設定';

  @override
  String get trainingType => 'トレーニングの種類';

  @override
  String get status => 'トレーニング状況';

  @override
  String get statusGreat => '素晴らしい';

  @override
  String get statusGood => '良い';

  @override
  String get statusNormal => '普通';

  @override
  String get statusTough => '厳しい';

  @override
  String get statusRecovery => '回復';

  @override
  String get typeTechnical => 'テクニカル';

  @override
  String get typePhysical => '物理的な';

  @override
  String get typeTactical => '戦術的';

  @override
  String get typeMatch => 'マッチ';

  @override
  String get typeRecovery => '回復';

  @override
  String get intensity => '強度';

  @override
  String get condition => '状態';

  @override
  String get location => '位置';

  @override
  String get program => 'プログラム';

  @override
  String get entryProgramDurationsTitle => 'トレーニングプログラム';

  @override
  String get entryProgramDurationsSubtitle => 'プログラムと時間を一緒に記録します。';

  @override
  String entryProgramDurationTotal(Object minutes) {
    return '合計 $minutes';
  }

  @override
  String get entryProgramDurationAddAction => 'プログラムを追加';

  @override
  String get entryProgramDurationRemoveTooltip => 'プログラム時間を削除';

  @override
  String get entryProgramDurationEmpty => 'トレーニングプログラムを追加しましょう。';

  @override
  String get entryProgramOptionAddTooltip => 'プログラム項目を追加';

  @override
  String get entryDurationOptionAddTooltip => '時間項目を追加';

  @override
  String get entryTodayGoalsTitle => '今日の目標';

  @override
  String get entryTodayGoalAddTitle => '今日の目標を追加';

  @override
  String get entryTodayGoalAddTooltip => '目標を追加';

  @override
  String get entryTodayGoalsSelectTooltip => '今日の目標を選択';

  @override
  String get entryTodayGoalsSelectTitle => '今日の目標を選択';

  @override
  String get entryTodayGoalsDone => '完了';

  @override
  String get entryTodayGoalsNone => '選択された目標はありません';

  @override
  String entryTodayGoalsSelectedCount(int count) {
    return '$count件選択中';
  }

  @override
  String get drills => 'セッションドリル';

  @override
  String get injury => 'けが';

  @override
  String get injuryPart => '損傷部位';

  @override
  String get painLevel => '痛みのレベル (1-10)';

  @override
  String get rehab => 'リハビリ';

  @override
  String get goal => 'ゴール';

  @override
  String get feedback => 'フィードバック';

  @override
  String get notes => '注意事項';

  @override
  String get growth => '成長';

  @override
  String get height => '身長(cm)';

  @override
  String get weight => '重量(kg)';

  @override
  String get calendar => 'カレンダー';

  @override
  String get calendarFormatMonth => '月';

  @override
  String get calendarFormatTwoWeeks => '2週間';

  @override
  String get calendarFormatWeek => '週';

  @override
  String get noEntries => 'まだエントリーはありません。';

  @override
  String get noEntriesForDay => 'この日のエントリーはありません。';

  @override
  String get noResults => '検索に一致するエントリはありません。';

  @override
  String get searchHint => 'トレーニングログの検索';

  @override
  String get filterTitle => 'ログのフィルタリング';

  @override
  String get filterAll => '全て';

  @override
  String get filterInjuryOnly => '怪我のみ';

  @override
  String get filterJumpRopeOnly => '縄跳びの日のみ';

  @override
  String get filterFeedbackOnly => 'フィードバックありのみ';

  @override
  String get filterEmptyResetHint => 'フィルターをリセットすると、ほかの記録も表示できます。';

  @override
  String get filterReset => 'リセット';

  @override
  String get filterApply => '適用する';

  @override
  String get deleteEntry => 'エントリの削除';

  @override
  String get deleteConfirm => 'このエントリを削除しますか?';

  @override
  String get cancel => 'キャンセル';

  @override
  String get delete => '消去';

  @override
  String get undo => '元に戻す';

  @override
  String get statsRecent7 => '過去 7 日間';

  @override
  String get statsRecent30 => '過去 30 日間';

  @override
  String get statsTotalSessions => '合計セッション数';

  @override
  String get statsTotalMinutes => '合計分';

  @override
  String get statsAvgIntensity => '平均強度';

  @override
  String get statsAvgCondition => '平均的な状態';

  @override
  String get statsInjuryCount => '怪我の数';

  @override
  String get statsAvgPain => '平均的な痛み';

  @override
  String get statsRehabCount => 'リハビリカウント';

  @override
  String get statsSummary => 'まとめ';

  @override
  String get statsTypeRatio => '研修プログラム比率';

  @override
  String get statsWeeklyMinutes => '毎週の議事録';

  @override
  String get growthHistory => '成長の歴史';

  @override
  String level(Object value) {
    return 'レベル$value';
  }

  @override
  String levelUpRemaining(Object value) {
    return '$valueさらにレベルアップ';
  }

  @override
  String get missionComplete => 'ミッション完了！週間目標達成！';

  @override
  String get missionKeepGoing => '素晴らしい仕事だ！今週は残り3セッションまであと少し！';

  @override
  String get onboard1 => '今日のトレーニングを記録する';

  @override
  String get onboard2 => '成長履歴を追跡する';

  @override
  String get onboard3 => '目標を持ってレベルアップする';

  @override
  String get next => '次';

  @override
  String get start => '始める';

  @override
  String get heroMessage => '今日は素晴らしい仕事でした！ロギングは成長を早めるのに役立ちます。';

  @override
  String get logsHeadline1 => 'トレーニング';

  @override
  String get logsHeadline2 => 'セッション';

  @override
  String get entryHeadline1 => 'ログ';

  @override
  String get entryHeadline2 => 'あなたのトレーニング';

  @override
  String get statsHeadline1 => '進捗';

  @override
  String get statsHeadline2 => '概要';

  @override
  String get durationNotSet => '時間がない';

  @override
  String get defaultLocation1 => '学校のグラウンド';

  @override
  String get defaultLocation2 => 'コミュニティフィールド';

  @override
  String get defaultLocation3 => '屋内ジム';

  @override
  String get defaultProgram1 => '基本';

  @override
  String get defaultProgram2 => '物理的な';

  @override
  String get defaultProgram3 => '戦術的';

  @override
  String get defaultProgram4 => '回復';

  @override
  String get defaultDrill1 => 'ロンド 5:2';

  @override
  String get defaultDrill2 => '1対1のディフェンス';

  @override
  String get defaultDrill3 => '射撃回数';

  @override
  String get defaultDrill4 => 'スプリント';

  @override
  String get defaultInjury1 => 'ハムストリング';

  @override
  String get defaultInjury2 => '膝';

  @override
  String get defaultInjury3 => '足首';

  @override
  String get defaultInjury4 => '大腿';

  @override
  String get defaultInjury5 => 'カーフ';

  @override
  String get languageEnglish => '英語';

  @override
  String get languageKorean => '韓国語';

  @override
  String get languageJapanese => '日本語';

  @override
  String get settings => '設定';

  @override
  String get settingsGeneralSection => '一般設定';

  @override
  String get settingsApiUsageTitle => 'このアプリで使用するAPI';

  @override
  String get settingsApiUsageSubtitle =>
      'このアプリは以下の公開APIまたはユーザー同意ベースのAPIを使用します。プロバイダーごとに割り当ては変わる可能性があるため、可能な場所ではキャッシュし、バックグラウンド更新を制限します。';

  @override
  String get settingsApiTrafficLabel => 'トラフィック';

  @override
  String get settingsApiLegalLabel => '合法的な使用';

  @override
  String get settingsApiOpenMeteoProvider =>
      'Open-Meteo 天気、大気質、ジオコーディング、過去天気API';

  @override
  String get settingsApiOpenMeteoTraffic =>
      '公正利用を前提とした無料公開サービスです。天気画面のリクエストはキャッシュし、必要な時だけ更新します。';

  @override
  String get settingsApiOpenMeteoLegal =>
      'Open-Meteoの公開API規約に従って使用し、天気機能で出典を表示します。';

  @override
  String get settingsApiKoreaPublicProvider => '韓国公共データの天気および大気質API';

  @override
  String get settingsApiKoreaPublicTraffic => '発行された公共データサービスキーと各機関の制限に従います。';

  @override
  String get settingsApiKoreaPublicLegal =>
      '発行されたサービスキーと韓国公共データポータルの利用条件に従って使用します。';

  @override
  String get settingsApiKakaoProvider => 'Kakao Local 検索/ジオコーディングAPI';

  @override
  String get settingsApiKakaoTraffic =>
      '登録されたKakao DevelopersアプリとREST APIキーの割り当てに従います。';

  @override
  String get settingsApiKakaoLegal =>
      'アプリキーとプラットフォーム設定が許可する範囲でKakao Developers規約に従って使用します。';

  @override
  String get settingsApiFootballProvider => 'サッカー日程、順位、ワールドカップのソースページ/API';

  @override
  String get settingsApiFootballTraffic =>
      '読み取り専用の取得はキャッシュし、控えめに再試行します。利用可否はソースサービスに依存します。';

  @override
  String get settingsApiFootballLegal =>
      '公開されている日程/順位データをアプリ表示用に使用し、提供される場合はリンクと出典を表示します。';

  @override
  String get settingsApiNewsProvider => 'RSSフィードとニュース取得補助API';

  @override
  String get settingsApiNewsTraffic =>
      'RSS/ニュース応答は繰り返し通信を減らすためにキャッシュし、フィルタリングします。';

  @override
  String get settingsApiNewsLegal => '記事全文を再公開せず、記事メタデータと元の出版社ページへのリンクを表示します。';

  @override
  String get settingsApiGoogleProvider => 'Google DriveおよびFirebaseサービス';

  @override
  String get settingsApiGoogleTraffic =>
      '接続されたGoogle CloudプロジェクトとユーザーのDrive割り当てに従います。';

  @override
  String get settingsApiGoogleLegal =>
      'ユーザーの同意を得て、ユーザー自身のバックアップファイルに必要なアプリバックアップ範囲でアクセスします。';

  @override
  String get account => 'アカウント';

  @override
  String get signInWithGoogle => 'Googleでサインイン';

  @override
  String get signInFailed => 'サインインに失敗しました。もう一度試してください。';

  @override
  String get signedIn => 'サインインしました';

  @override
  String get signOut => 'サインアウト';

  @override
  String get webLoginNotAvailable => 'Google ログインはウェブ上では利用できません。';

  @override
  String get backupToDrive => 'データのバックアップ';

  @override
  String get restoreFromDrive => '最新データをインポートする';

  @override
  String get restorePreviousBackup => '以前のバックアップをインポートする';

  @override
  String get restorePreviousBackupInfo =>
      '以前のバックアップ インポートは、最近のインポートを元に戻したり、古い状態を確認したりするための回復ツールです。実行する前に、現在のデータが以前のバックアップによって置き換えられることを確認してください。';

  @override
  String get backupConfirm => 'Google ドライブに新しいバックアップを作成しますか?';

  @override
  String get restoreConfirm =>
      'Google ドライブから最新のデータをインポートしますか?これにより、現在のデータが置き換えられます。';

  @override
  String get restorePreviousConfirm =>
      '以前の Google ドライブのバックアップをインポートしますか?現在のデータは置き換えられます。';

  @override
  String get backupSuccess => 'バックアップが完了しました。';

  @override
  String get backupFailed => 'バックアップに失敗しました。もう一度試してください。';

  @override
  String get restoreSuccess => 'データがインポートされました。';

  @override
  String get restoreFailed => 'データのインポートに失敗しました。もう一度試してください。';

  @override
  String get restorePreviousSuccess => '以前のバックアップがインポートされました。';

  @override
  String get restorePreviousFailed => '前回のバックアップのインポートに失敗しました。もう一度試してください。';

  @override
  String get backupInProgress => 'バックアップ中...';

  @override
  String get restoreInProgress => 'データをインポートしています...';

  @override
  String get backupDailyEnabled => '毎日のバックアップが有効になっています';

  @override
  String get backupDailyDesc => 'アプリを開いたときに 1 日に 1 回バックアップします';

  @override
  String get backupAutoOnSave => '保存時の自動バックアップ';

  @override
  String get backupAutoOnSaveDesc => 'ログを追加または更新するたびにバックアップします';

  @override
  String get lastBackup => '最後のバックアップ';

  @override
  String get timeJustNow => 'ちょうど今';

  @override
  String timeMinutesAgo(int count) {
    return '$count 分前';
  }

  @override
  String timeHoursAgo(int count) {
    return '$count 1 時間前';
  }

  @override
  String get timeYesterday => '昨日';

  @override
  String get restoreLocalBackup => '最新のインポートを元に戻す';

  @override
  String get restoreLocalConfirm =>
      'このデバイスでの最新のインポートによって加えられた変更を元に戻しますか?これにより、現在のデータが置き換えられます。';

  @override
  String get restoreLocalSuccess => '最新のインポートは取り消されました。';

  @override
  String get restoreLocalFailed => '最新のインポートを元に戻すことができませんでした。もう一度試してください。';

  @override
  String get localBackup => '地域の安全バックアップ';

  @override
  String get driveBackupLockedAccountChanged =>
      'Googleアカウントが変わりました。このアカウントでバックアップする前に、最新のデータをインポートしてください。';

  @override
  String get backupVersionUnsupported =>
      'このバックアップは新しいバージョンのアプリで作成されたため、まだここにはインポートできません。アプリを更新して、もう一度お試しください。';

  @override
  String get backupPayloadInvalid =>
      'バックアップデータの形式を確認できなかったため、インポートを中止しました。別のバックアップを試してください。';

  @override
  String get loginRequired => 'ドライブのバックアップを使用するには、Google にログインしてください。';

  @override
  String get signOutDone => 'サインアウトしました。';

  @override
  String get voiceNotAvailable => 'このデバイスでは音声入力は利用できません。';

  @override
  String get liftingRecord => 'リフティング記録';

  @override
  String get liftingByPart => 'リフティング（部位ごとの回数）';

  @override
  String get liftingMinutesLabel => 'リフティング時間（分）';

  @override
  String get liftingPartInfront => '前に';

  @override
  String get liftingPartInside => '内部';

  @override
  String get liftingPartOutside => '外';

  @override
  String get liftingPartMuple => '膝';

  @override
  String get liftingPartHead => '頭';

  @override
  String get liftingPartChest => '胸';

  @override
  String get liftingByBodyPartTitle => '部位別のリフティング';

  @override
  String get liftingNoRecords => '持ち上げ記録はありません。';

  @override
  String get legacyLabel => '遺産';

  @override
  String get oldLabel => '古い';

  @override
  String get confirm => '確認する';

  @override
  String get language => '言語';

  @override
  String get theme => 'テーマ';

  @override
  String get themeSystem => 'システム';

  @override
  String get themeLight => 'ライト';

  @override
  String get themeDark => '暗い';

  @override
  String get defaults => 'デフォルト';

  @override
  String get defaultDuration => 'デフォルトの期間';

  @override
  String get defaultIntensity => 'デフォルトの強度';

  @override
  String get defaultCondition => 'デフォルトの状態';

  @override
  String get defaultLocation => 'デフォルトの場所';

  @override
  String get defaultProgram => 'デフォルトのプログラム';

  @override
  String get notifications => '通知';

  @override
  String get notificationSettingsAction => '設定';

  @override
  String get notificationSettingsTitle => '通知設定';

  @override
  String get notificationSettingsCloseTooltip => '通知設定を閉じる';

  @override
  String get notificationRefreshAction => 'リフレッシュ';

  @override
  String get notificationMuteStatusPaused => '通知は現在一時停止中です。';

  @override
  String get notificationMuteControlTitle => '繰り返し通知の管理';

  @override
  String get notificationMuteControlSubtitle => '通知を一時停止したり、いつでも再開できます。';

  @override
  String get notificationMute8HoursAction => '8時間オフ';

  @override
  String get notificationResumeAction => '再開';

  @override
  String get notificationAllSettingsTitle => 'すべての通知';

  @override
  String get notificationTrainingPlanVibrationTitle => 'トレーニング計画の振動通知';

  @override
  String get notificationXpAlertSettingsTitle => 'XP通知';

  @override
  String get notificationXpAlertSettingsSubtitle => 'XPを獲得したときに通知します。';

  @override
  String get notificationLevelUpSettingsTitle => 'レベルアップ通知';

  @override
  String notificationFamilySectionTitle(int count) {
    return '$count 件の保護者同期アラート';
  }

  @override
  String get notificationFamilyEmpty => '保護者同期アラートはまだありません。';

  @override
  String notificationFixtureSectionTitle(int count) {
    return '$count 件の試合日程アラート';
  }

  @override
  String get notificationFixtureEmpty => '試合日程アラートはまだありません。';

  @override
  String get notificationFamilySettingsTitle => '保護者同期アラート';

  @override
  String get notificationFamilySettingsSubtitle =>
      '選手の記録や保護者フィードバック/報酬が同期されたときに通知します。';

  @override
  String get notificationLeagueFixtureSettingsTitle => 'お気に入りのチームの試合アラート';

  @override
  String get notificationLeagueFixtureSettingsSubtitle =>
      '選択したお気に入りチームの試合をロードする前に通知します。';

  @override
  String get reminderEnabled => '毎日のリマインダーを有効にする';

  @override
  String get reminderTime => 'リマインダー時間';

  @override
  String get photo => '写真';

  @override
  String get addPhoto => '写真を追加';

  @override
  String get removePhoto => '取り除く';

  @override
  String get noImage => 'まだ画像がありません';

  @override
  String get imageLoadFailed => '画像のロードに失敗しました';

  @override
  String get more => 'もっと';

  @override
  String get camera => 'カメラ';

  @override
  String get gallery => 'ギャラリー';

  @override
  String get crop => '作物';

  @override
  String get photoHint => '「保存」の横にあるカメラアイコンをタップして写真を追加します。';

  @override
  String get reorderPhotos => '写真を並べ替える';

  @override
  String photoIndex(Object value) {
    return '写真$value';
  }

  @override
  String photoLimitReached(Object value) {
    return '$value までの写真を追加できます。';
  }

  @override
  String get gameGuideTitle => 'ゲームガイド';

  @override
  String get gameGuideQuickTitle => '現在のゲームの流れ';

  @override
  String get gameGuideQuickLine1 =>
      '各実行時間は 20 秒で、ライフは 3 つから始まります。失敗した場合は、ライフが残っている間にすぐに再試行できます。';

  @override
  String get gameGuideQuickLine2 =>
      'パスボタンを使用して方向とパワーを制御し、安全なパス、キラーパス、または危険なパスを選択します。';

  @override
  String get gameGuideQuickLine3 =>
      '連続成功でコンボを構築します。コンボ 8+ では、フィーバーが 5 秒間始まり、ボーナス ポイントが 2 倍になります。';

  @override
  String get gameGuideQuickLine4 =>
      '走行中にランダムなイベント (狭い車線、広い車線、追い風) とミッションが変わるため、すぐに適応してください。';

  @override
  String get gameGuideRiskTitle => '意思決定戦略';

  @override
  String get gameGuideRiskLine1 =>
      '安全なパス: 安定性が最も高く、リズムを保ち、安全にミッションをクリアするのに最適です。';

  @override
  String get gameGuideRiskLine2 =>
      'キラーパス: リスクは中程度ですが、スコアが急速に伸びるための強力な報酬が得られます。';

  @override
  String get gameGuideRiskLine3 => 'リスキーパス: 最も難しいオプションですが、完了すると最大の報酬が得られます。';

  @override
  String get gameGuideRiskLine4 =>
      'オープンスペースへのパスは追加のボーナスを与えるため、リリース前にディフェンダーのスペースを読んでください。';

  @override
  String get gameGuideFailureTitle => '間違いから立ち直る';

  @override
  String get gameGuideFailureLine1 =>
      'まだライフがある場合、インターセプト、衝突、ミスによってランがすぐに終了することはなくなりました。';

  @override
  String get gameGuideFailureLine2 =>
      '速すぎる/遅すぎるフィードバックを使用して、次回の試行時にホールド タイミングを調整します。';

  @override
  String get gameGuideFailureLine3 => 'ノーパス 3 が表示された場合は、まず短い安全なパスでテンポをリセットします。';

  @override
  String get gameGuideFailureLine4 => 'ライフが残り少なくなったら、より安全な選択に切り替えて逃げを守りましょう。';

  @override
  String get gameGuideRankingTitle => 'スコア計算式';

  @override
  String get gameGuideRankingLine1 =>
      'ランクスコア = (完了したパス x 10) + (レベル x 15) + (ゴール x 60) + ボーナススコア。';

  @override
  String get gameGuideRankingLine2 =>
      'ボーナススコアソース: パスタイプの報酬、オープンスペースの報酬、リズム報酬、ミッション報酬。';

  @override
  String get gameGuideRankingLine3 =>
      'フィーバー中はボーナススコアが2倍になり、短い時間で大きなジャンプが可能になります。';

  @override
  String get gameGuideRankingLine4 =>
      'ハイスコ​​アルート: 安全なパスでリズムを築き、キラー/リスキーなパスで展開し、ミッションとゴールの報酬で終了します。';

  @override
  String get gameGuideCharPacTitle => 'パックマンアタッカー';

  @override
  String get gameGuideCharPacSubtitle => 'スタートとリンクのパス';

  @override
  String get gameGuideCharPacTag => '攻撃';

  @override
  String get gameGuideCharBlueTitle => 'ブルーゴースト - ブロック';

  @override
  String get gameGuideCharBlueSubtitle => '追い越し車線をブロックする';

  @override
  String get gameGuideCharBlueTag => 'ブロック';

  @override
  String get gameGuideCharOrangeTitle => 'オレンジゴースト - プレス';

  @override
  String get gameGuideCharOrangeSubtitle => 'ボール付近のプレッシャー';

  @override
  String get gameGuideCharOrangeTag => 'プレス';

  @override
  String get gameGuideCharRedTitle => 'レッドゴースト - マーク';

  @override
  String get gameGuideCharRedSubtitle => '通行人をマークします';

  @override
  String get gameGuideCharRedTag => 'マーク';

  @override
  String get gameGuideCharPinkTitle => 'ピンクの幽霊 - 読む';

  @override
  String get gameGuideCharPinkSubtitle => '受信ルートを予測します';

  @override
  String get gameGuideCharPinkTag => '読む';

  @override
  String get hideKeyboard => 'キーボードを隠す';

  @override
  String get diaryComposerSavePromptTitle => '保存しますか？';

  @override
  String get diaryComposerSavePromptBody => '未保存の変更があります。保存して閉じますか？';

  @override
  String get diaryComposerDontSave => '保存しない';

  @override
  String get diaryNewAction => '新しい日記';

  @override
  String get diaryNextDayTooltip => '次の日付';

  @override
  String get diaryPreviousDayTooltip => '前の日付';

  @override
  String get diaryComposeTooltip => '作成';

  @override
  String get diaryEmptyTitle => '作成した日記はまだありません';

  @override
  String get diaryEmptyBody => '日付を選んで最初のページを作成すると、日記を始められます。';

  @override
  String get diaryCreateFirstAction => '最初の日記を作成';

  @override
  String get diaryDeleteDialogTitle => '日記を削除';

  @override
  String get diaryDeleteDialogBody => 'この日の日記を削除しますか？';

  @override
  String get diaryDeletedMessage => '日記を削除しました。';

  @override
  String get diaryDeleteRestoredMessage => '削除した日記を元に戻しました。';

  @override
  String get diaryThemeNotebookName => 'ノート';

  @override
  String get diaryThemeNotebookDescription => '落ち着いた紙の質感の基本テーマです。';

  @override
  String get diaryThemeDuskName => '夕焼け';

  @override
  String get diaryThemeDuskDescription => '赤い夕暮れのような温かい雰囲気で読めます。';

  @override
  String get diaryThemeOceanName => '明け方の海';

  @override
  String get diaryThemeOceanDescription => '青いインクのようにくっきり涼しいページです。';

  @override
  String get diaryVoiceInputTooltip => '音声入力';

  @override
  String get diaryVoiceInputUnavailable => 'この端末では音声入力を使用できません。';

  @override
  String get diaryComposerTitle => '今日の日記を書く';

  @override
  String get diaryComposerDescription => '今日の記録からステッカーを選び、本文は短く自分で書きましょう。';

  @override
  String get diaryEmptyHint => '要点だけを短く記録しましょう。';

  @override
  String get diaryLastSavedPrefix => '最終保存';

  @override
  String get diarySavedMessage => '日記を保存しました。';

  @override
  String get diaryTitlePlaceholder => 'タイトルを入力してください';

  @override
  String get diaryTitleLabel => 'タイトル';

  @override
  String get diaryTitleHint => '例: 雨の日も続いたパスのリズム';

  @override
  String get diaryStoryLabel => '本文';

  @override
  String get diaryStoryPlaceholder => '本文を入力してください';

  @override
  String get diarySaveEmptyMessage =>
      'まだ保存する内容がありません。タイトル、本文、ステッカー、写真のいずれかを追加してください。';

  @override
  String get diaryClearConfirmTitle => 'すべて消しますか？';

  @override
  String get diaryClearConfirmBody => 'タイトル、本文、選択したステッカー、写真をすべて消します。';

  @override
  String get diaryClearAction => '消去';

  @override
  String get diaryCustomEmotionLabel => '自分自身の感情を創造する';

  @override
  String get diaryCustomEmotionHint => '自分の言葉でムードステッカーを追加';

  @override
  String get diaryCustomEmotionAdd => '感情を加える';

  @override
  String diaryExpandNewsStickers(int count) {
    return 'すべてのニュースステッカーを表示 ($count)';
  }

  @override
  String get diaryCollapseNewsStickers => 'ニュースステッカーを折りたたむ';

  @override
  String get homeWeatherTitle => '天気コーチ';

  @override
  String get homeWeatherTodayTitle => '今日の天気';

  @override
  String get homeWeatherSubtitle => '現地の状況を確認し、トレーニングの焦点を調整します。';

  @override
  String get homeWeatherLoad => '地元の天気をロードする';

  @override
  String get homeWeatherLoading => '地元の天気を読み込んでいます...';

  @override
  String get homeWeatherUnavailable => '位置情報へのアクセスが許可されると、ここで気象情報が準備されます。';

  @override
  String get homeWeatherPermissionNeeded => '地元の天気を読み込むための位置情報へのアクセスを許可します。';

  @override
  String get homeWeatherLoadFailed => '地元の天気を読み込めませんでした。';

  @override
  String get entryWeatherLoading => '天気を読み込み中...';

  @override
  String get entryWeatherHomeMissing => '先にホームで天気を読み込んでください。';

  @override
  String get entryWeatherUseLocationTooltip => '現在地の天気を使う';

  @override
  String get homeWeatherRetryTitle => '天気を再試行';

  @override
  String get homeWeatherRetrySubtitle => 'タップしてロード';

  @override
  String get homeWeatherLocationUnknown => '現在地';

  @override
  String get homeWeatherCountryKorea => '韓国';

  @override
  String get homeWeatherDetailsTitle => '天気の詳細';

  @override
  String get homeWeatherDetailsSubtitle => '現在地の天気と空気の質を確認してください。';

  @override
  String get homeWeatherTomorrowTitle => '明日の天気';

  @override
  String get homeWeatherWeeklyTitle => '週間天気';

  @override
  String get homeWeatherMorningLabel => '朝';

  @override
  String get homeWeatherEveningLabel => '夕方';

  @override
  String get homeWeatherCacheHint => '最近取得した天気を 10 分間再利用します。';

  @override
  String get homeWeatherDailyHighLow => '高/低';

  @override
  String get homeWeatherTomorrowFallback => '明日の予報はまだ出ていません。';

  @override
  String get homeWeatherTomorrowOutfitTitle => '明日の服装';

  @override
  String get homeWeatherTomorrowOutfitFallback => '明日の服装ガイドはまだ準備ができていません。';

  @override
  String get homeWeatherTemperatureRange => '高/低';

  @override
  String get homeWeatherFeelsLike => 'みたいな感じ';

  @override
  String get homeWeatherHumidity => '湿度';

  @override
  String get homeWeatherPrecipitation => '降水量';

  @override
  String get weatherPrecipitationNone => '雨ほぼなし';

  @override
  String get weatherPrecipitationTrace => '弱い雨';

  @override
  String get weatherPrecipitationLight => '小雨';

  @override
  String get weatherPrecipitationModerate => '雨';

  @override
  String get weatherPrecipitationHeavy => '強い雨';

  @override
  String get weatherPrecipitationVeryHeavy => '大雨';

  @override
  String get homeWeatherHourlyPrecipitation => '時間降水量';

  @override
  String get homeWeatherHourlyTemperature => '時間ごとの気温';

  @override
  String get homeWeatherWindSpeed => '風';

  @override
  String get homeWeatherUvIndex => '紫外線指数';

  @override
  String get homeWeatherOutfitTitle => 'おすすめのサッカー服装';

  @override
  String get homeWeatherOutfitBaseHot => '半袖キット、薄手のショーツ、通気性のあるソックス。';

  @override
  String get homeWeatherOutfitBaseCold => 'サーマルベースレイヤー、手袋、長い靴下、必要に応じてビーニー帽。';

  @override
  String get homeWeatherOutfitBaseMild => '軽いベースレイヤーを備えた標準キットで十分です。';

  @override
  String get homeWeatherOutfitRain => '薄い防水シェルと予備の靴下を用意してください。';

  @override
  String get homeWeatherOutfitSnow =>
      '暖かいベースレイヤーと厚手の靴下を着用してください。滑りやすい地面に注意してください。';

  @override
  String get homeWeatherOutfitWind => '体温を安定させるためにウィンドブレーカーを追加します。';

  @override
  String get homeWeatherOutfitAirCaution =>
      '空気の質が悪い場合は、通勤時にマスクを着用し、屋外でのハードな作業を減らしてください。';

  @override
  String get homeWeatherOutfitButton => '服装ガイド';

  @override
  String get homeWeatherTodayRecommendationsTitle => '今日の天気に合わせたおすすめ';

  @override
  String get homeWeatherOutfitLayersLabel => '最上層';

  @override
  String get homeWeatherOutfitOuterLabel => '外層';

  @override
  String get homeWeatherOutfitBottomLabel => '底';

  @override
  String get homeWeatherOutfitAccessoriesLabel => '付属品';

  @override
  String get homeWeatherOutfitNotesLabel => '注意事項';

  @override
  String get homeWeatherOutfitViewAllCases => 'すべての衣装ケースを見る';

  @override
  String get homeWeatherOutfitAllCasesTitle => 'All outfit cases';

  @override
  String get homeWeatherOutfitAllCasesSubtitle =>
      '各ウェザーバンドをトップレイヤー、アウターレイヤー、ボトムス、アクセサリーの詳細とともに確認します。';

  @override
  String get homeWeatherOutfitCaseHotTitle => '暑い夏';

  @override
  String get homeWeatherOutfitCaseHotRange => '体感温度は30℃以上';

  @override
  String get homeWeatherOutfitCaseWarmTitle => '暖かいトレーニングの日';

  @override
  String get homeWeatherOutfitCaseWarmRange => '体感温度は22～29℃くらい';

  @override
  String get homeWeatherOutfitCaseMildTitle => '穏やかな日';

  @override
  String get homeWeatherOutfitCaseMildRange => '体感温度は15～21℃くらい';

  @override
  String get homeWeatherOutfitCaseCoolTitle => '涼しい日';

  @override
  String get homeWeatherOutfitCaseCoolRange => '体感温度は8～14℃くらい';

  @override
  String get homeWeatherOutfitCaseColdTitle => '寒い日';

  @override
  String get homeWeatherOutfitCaseColdRange => '体感温度は2～7℃くらい';

  @override
  String get homeWeatherOutfitCaseWetTitle => '雨や雪の日';

  @override
  String get homeWeatherOutfitCaseWetRange => '雨や雪の場合';

  @override
  String get homeWeatherAirQualityTitle => '空気の質';

  @override
  String get homeWeatherAirQualitySubtitle => '通常、数値が低いほど、屋外で呼吸がしやすいことを意味します。';

  @override
  String get homeWeatherAirQualityForecastMissingReason =>
      'この地域または時間帯では空気質予報が提供されていません。';

  @override
  String get homeWeatherAirGuideTitle => 'アウトドアアクティビティガイド';

  @override
  String get homeWeatherAirGuideUnknown => '空気データを更新して、屋外アクティビティのガイダンスを確認します。';

  @override
  String get homeWeatherAirGuideGood => '空気の質は通常の屋外活動やトレーニングに十分安定しています。';

  @override
  String get homeWeatherAirGuideModerate =>
      'ほとんどの屋外アクティビティは問題ありませんが、呼吸が敏感な場合は負荷を下げてください。';

  @override
  String get homeWeatherAirGuideSensitive =>
      '呼吸が荒くなりやすい場合は、屋外での長時間の作業や激しい運動を減らしてください。';

  @override
  String get homeWeatherAirGuideUnhealthy =>
      '屋外での激しい活動は避け、可能であれば屋内でのトレーニングやリカバリーに切り替えてください。';

  @override
  String get homeWeatherAirGuideVeryUnhealthy =>
      '屋外での活動を最小限に抑え、屋内での回復や技術的な作業に移ります。';

  @override
  String get homeWeatherAirGuideHazardous => '屋外活動を中止し、可能であれば屋内に留まってください。';

  @override
  String get homeWeatherComparedYesterday => '対昨日';

  @override
  String get homeWeatherPm10 => '細かい粉塵';

  @override
  String get homeWeatherPm25 => '超微細粉塵';

  @override
  String get homeWeatherAqi => 'アキ';

  @override
  String get homeWeatherAqiLabel => '空気の質の指標';

  @override
  String get homeWeatherAqiDescription =>
      'AQI は、空気がどの程度きれいだと感じているかを示す単純なスコアです。';

  @override
  String get homeWeatherAqiScaleGood => '0-50 良い';

  @override
  String get homeWeatherAqiScaleModerate => '51-100 中程度';

  @override
  String get homeWeatherAqiScaleSensitive => '101+ 注意';

  @override
  String get homeWeatherTomorrowCondition => '状態';

  @override
  String get homeWeatherWeeklyDateLabel => '日付';

  @override
  String get homeWeatherWeeklyConditionLabel => '予報';

  @override
  String get homeWeatherStatusGood => '良い';

  @override
  String get homeWeatherStatusModerate => '適度';

  @override
  String get homeWeatherStatusSensitive => '呼吸が敏感な場合は注意してください';

  @override
  String get homeWeatherStatusUnhealthy => '不健康';

  @override
  String get homeWeatherStatusVeryUnhealthy => '非常に不健康';

  @override
  String get homeWeatherStatusHazardous => '危険';

  @override
  String get homeWeatherSuggestionTitle => '推奨されるトレーニングの焦点';

  @override
  String get homeWeatherSuggestionButton => 'トレーニングの焦点';

  @override
  String get homeWeatherSuggestionSheetSubtitleDefault =>
      '現在の天気に合った効率的なトレーニング方向です。';

  @override
  String homeWeatherSuggestionSheetSubtitle(Object location) {
    return '$location の天気に合わせたトレーニング方向です。';
  }

  @override
  String get homeWeatherSuggestionFocusLabel => '今日の集中';

  @override
  String get homeWeatherSuggestionCautionLabel => '運用のヒント';

  @override
  String get homeWeatherSuggestionRecoveryLabel => '回復チェック';

  @override
  String get homeWeatherSuggestionClear =>
      '屋外でのファーストタッチワーク、パスのリズム、短いスプリントセットに適した時期です。';

  @override
  String get homeWeatherSuggestionCloudy =>
      '戦術的なパターンワークやより長いテンポのドリルには、安定した条件を使用してください。';

  @override
  String get homeWeatherSuggestionRain => 'インドアタッチ、ウォールパス、バランスやコアワークに移行します。';

  @override
  String get homeWeatherSuggestionSnow => '屋内での調整、機動性、軽い技術の繰り返しを優先します。';

  @override
  String get homeWeatherSuggestionStorm =>
      'リカバリ、ビデオレビュー、屋内での短時間のアクティベーションにより安全に保ちます。';

  @override
  String get homeWeatherSuggestionHot =>
      'ボリュームを減らし、回復時間を延ばし、水分補給をしながらテクニックに集中します。';

  @override
  String get homeWeatherSuggestionCold =>
      'ウォーミングアップに余分な時間を費やし、しっかりとしたタッチで徐々に強度を上げてください。';

  @override
  String get homeWeatherSuggestionAirCaution =>
      '空気の質が悪いため、屋外の負荷を減らし、可能であれば屋内の技術作業または復旧作業に切り替えてください。';

  @override
  String get homeWeatherSuggestionAirWatch =>
      '屋外でトレーニングする場合は、空気の質が完全に安定していないため、ハードなインターバルを短くし、呼吸に注意してください。';

  @override
  String get weatherLabelDefault => '天気';

  @override
  String get weatherLabelClear => 'クリア';

  @override
  String get weatherLabelCloudy => '曇り';

  @override
  String get weatherLabelFog => '霧';

  @override
  String get weatherLabelDrizzle => '霧雨';

  @override
  String get weatherLabelRain => '雨';

  @override
  String get weatherLabelSnow => '雪';

  @override
  String get weatherLabelThunderstorm => '雷雨';

  @override
  String get diaryStickerTraining => 'トレーニング';

  @override
  String get diaryStickerMatch => 'マッチ';

  @override
  String get diaryStickerPlan => 'プラン';

  @override
  String get diaryStickerFortune => '運';

  @override
  String get diaryStickerBoard => 'ボード';

  @override
  String get diaryStickerNews => 'ニュース';

  @override
  String get diaryStickerMeal => '丼もの';

  @override
  String get diaryStickerConditioning => '縄跳び・リフティング';

  @override
  String get diaryStickerInjury => 'けが';

  @override
  String get diaryStickerQuiz => 'クイズ';

  @override
  String get diaryStickerWeather => '天気';

  @override
  String get diaryStickerParentFeedback => '保護者からのフィードバック';

  @override
  String get diaryInjuryNoDetails => '負傷記録は保存されていなかった。';

  @override
  String get diaryInjuryRehab => 'リハビリ';

  @override
  String get diaryInjuryStorySentence => '痛みが現れた瞬間と、次に何を回復する必要があるかを書きます。';

  @override
  String get diaryQuizStorySentence => 'クイズの実行から残しておきたい質問やコンセプトを書きます。';

  @override
  String diaryParentFeedbackStorySentence(String message) {
    return '保護者からのフィードバック: $message';
  }

  @override
  String diaryQuizSummaryPerfect(int score, int total) {
    return '$score/$total 正解・ミスなし';
  }

  @override
  String diaryQuizSummaryWithMisses(int score, int total, int wrongCount) {
    return '$score/$total は正解ですが、$wrongCount はミスです';
  }

  @override
  String diaryQuizExpandQuestions(int count) {
    return 'すべての回答を表示 ($count)';
  }

  @override
  String get diaryQuizCollapseQuestions => '回答を折りたたむ';

  @override
  String get diaryQuizQuestionLabel => '質問';

  @override
  String get diaryQuizAnswerLabel => '答え';

  @override
  String get diaryQuizWrongAnswerLabel => '不正解';

  @override
  String get diaryQuizWrongAnswerNone => '間違った答えはありません';

  @override
  String get diaryQuizNoMissesLabel => '今回のクイズはミスなく終了しました。';

  @override
  String get diaryTrainingStatusLabel => 'トレーニング状況';

  @override
  String get diaryConditioningJumpRopeLabel => '縄跳び';

  @override
  String get diaryConditioningLiftingLabel => 'リフティング';

  @override
  String get diaryWeatherEmpty => '天気は記録されていませんでした。';

  @override
  String get diaryUnknownSource => '出典なし';

  @override
  String get diaryLocationUnset => '場所未記録';

  @override
  String get diaryLocationNotLogged => '場所の記録なし';

  @override
  String get diaryFundamentalsFallback => '基礎';

  @override
  String diaryUpdatedAt(String date) {
    return '更新 $date';
  }

  @override
  String get diaryMatchOpponentUnknown => '相手チーム未記録';

  @override
  String diaryMatchOpponentLabel(String opponent) {
    return '$opponent戦';
  }

  @override
  String diaryMatchScoreLabel(String score) {
    return 'スコア $score';
  }

  @override
  String diaryMatchGoalsLabel(int count) {
    return '個人得点 $count';
  }

  @override
  String diaryMatchAssistsLabel(int count) {
    return 'アシスト $count';
  }

  @override
  String diaryMatchMinutesPlayed(String minutes) {
    return '出場 $minutes';
  }

  @override
  String diaryMatchPersonalStats(int goals, int assists) {
    return '${goals}G ${assists}A';
  }

  @override
  String diaryTotalRiceBowls(String count) {
    return '合計 $count杯';
  }

  @override
  String diaryCompletedMeals(int count) {
    return '$count食を記録';
  }

  @override
  String diaryReps(int count) {
    return '$count回';
  }

  @override
  String diaryTotalReps(int count) {
    return '合計 $count回';
  }

  @override
  String diaryLiftingReps(int count) {
    return 'リフティング $count回';
  }

  @override
  String diaryJumpRopeReps(int count) {
    return '縄跳び $count回';
  }

  @override
  String diaryJumpRopeMinutes(String minutes) {
    return '縄跳び $minutes';
  }

  @override
  String diaryJumpRopeCombined(int count, String minutes) {
    return '縄跳び $minutes/$count回';
  }

  @override
  String diaryConditioningSummary(
      int liftingCount, int jumpCount, String jumpMinutes) {
    return 'リフティング $liftingCount回 · 縄跳び $jumpMinutes/$jumpCount回';
  }

  @override
  String diaryStoryPromptFromSeed(String title) {
    return '$titleから始めて、今日残したい場面を書き続けましょう。予定していたこと、実際にしたこと、気持ちの変化を自然につなげても大丈夫です。';
  }

  @override
  String diaryStoryPromptDefault(String place, String focus) {
    return '今日$placeであったことを自分の言葉で書きましょう。$focusで一番印象に残った場面、楽しかったこと、惜しかったことを自由に残して大丈夫です。';
  }

  @override
  String diaryPlanStorySentence(String title) {
    return '$titleの予定を思い出しながら、なぜ今日の日記に残したいのかを書いてみる。';
  }

  @override
  String diaryPlanNoteTitle(String category) {
    return '$categoryメモ';
  }

  @override
  String diaryPlanDurationLabel(String duration) {
    return '$durationの計画';
  }

  @override
  String get diaryPinnedPlanTooltip => '計画を固定';

  @override
  String diaryTrainingTodoTitle(String label) {
    return 'トレーニング · $label';
  }

  @override
  String diaryTrainingSummaryTitle(String label) {
    return '$labelのトレーニング要約';
  }

  @override
  String get diaryFortunePinSummary => '今日の記録に残った運勢の流れを日記ステッカーとして貼れます。';

  @override
  String get diaryFortuneStorySentence => '今日の運勢で残したい流れや応援の一言を書いてみる。';

  @override
  String get diaryFortuneNoteTitle => '今日の運勢メモ';

  @override
  String get diaryMatchTodoTitleNoOpponent => '試合';

  @override
  String diaryMatchTodoTitleWithOpponent(String opponent) {
    return '試合 · $opponent戦';
  }

  @override
  String get diaryMatchStorySentence =>
      '試合の流れを場面ごとに思い出し、良かった判断と惜しかった判断を一緒に書いてみる。';

  @override
  String get diaryMatchFlowTitle => '試合の流れ';

  @override
  String get diaryMatchSectionBodyDefault => '試合で一番印象に残った流れを書く。';

  @override
  String get diaryBoardStickerFallbackSummary => 'このボードで記録した動きとアイデア';

  @override
  String diaryBoardNotePrefix(String memo) {
    return 'ボードメモ: $memo';
  }

  @override
  String diaryBoardTodoTitle(String title) {
    return 'ボード · $title';
  }

  @override
  String get diaryBoardStorySentence => 'このボードから残したい動きやアイデアを書く。';

  @override
  String get diaryBoardFallbackSummary => '戦術アイデアを日記に移せます。';

  @override
  String diaryBoardNoteTitle(String title) {
    return '$titleメモ';
  }

  @override
  String get diaryLiftingStorySentence => 'リフティングの反復が今日のボール感覚をどう支えたかを書いてみる。';

  @override
  String get diaryLiftingNoteTitle => 'リフティングメモ';

  @override
  String get diaryLiftingSectionBody => '回数と一緒に、足元の感覚が安定した瞬間を残す。';

  @override
  String get diaryJumpRopeStorySentence => '縄跳びで体が起きた瞬間と呼吸の変化を書いてみる。';

  @override
  String get diaryJumpRopeNoteTitle => '縄跳びメモ';

  @override
  String get diaryJumpRopeSectionBody => '回数、時間、体が軽くなったタイミングを一緒に残す。';

  @override
  String get diaryWeatherStorySentence =>
      'その日の天気がトレーニングの流れや体の状態にどう影響したかを書きましょう。';

  @override
  String diaryNewsTodoTitle(String title) {
    return 'ニュース · $title';
  }

  @override
  String diaryNewsStorySentence(String title) {
    return '$titleの記事を読んで、覚えておきたいポイントを一行で残す。';
  }

  @override
  String get diaryTodayNewsTitle => '今日読んだニュース';

  @override
  String diaryNewsSectionBody(String source, String title) {
    return '$sourceの記事: $title';
  }

  @override
  String get quizWrongAnswerTimeout => 'タイムアウトしました';

  @override
  String get quizWrongAnswerRevealed => '答えを明らかにした';

  @override
  String get quizWrongAnswerSkipped => '回答が選択されていません';

  @override
  String get quizWrongAnswerEmpty => '入力なし';

  @override
  String get quizShortAnswerHintAction => 'ヒントを表示';

  @override
  String get quizRevealAnswerAction => '答えを明らかにする';

  @override
  String get quizShortAnswerHintUnavailable => 'ヒントはまだありません。';

  @override
  String quizShortAnswerHintStartsWith(Object first, Object length) {
    return '「$first」で始まり、$lengthの文字が入っています。';
  }

  @override
  String quizShortAnswerHintNumber(Object first, Object length) {
    return '$firstで始まる$length桁の答えです。';
  }

  @override
  String get diaryTrainingSelectedGoalsLabel => '選択された目標';

  @override
  String get diaryTrainingStrongPointLabel => '何がうまくいったのか';

  @override
  String get diaryTrainingNeedsWorkLabel => '仕事が必要です';

  @override
  String get diaryTrainingNextGoalLabel => '次の目標';

  @override
  String get diarySelectedRecordStickersTitle => '厳選されたレコードステッカー';

  @override
  String get diarySelectedRecordStickersHint =>
      'ハンドルをドラッグして順序を変更するか、削除を使用してステッカーを削除します。';

  @override
  String get diaryRecordStickerSectionTitle => 'レコードステッカーのレイアウト';

  @override
  String get diaryRecordStickerSectionSubtitle => '今日の記録から抜粋して、上記の読む順序を整理します。';

  @override
  String get diaryRecordStickerSourceTitle => '今日の記録から抜粋';

  @override
  String diaryRecordStickerAvailableCount(int count) {
    return '$count アイテム';
  }

  @override
  String diaryRecordStickerSelectedCount(int count) {
    return '$countが選択されました';
  }

  @override
  String diaryRecordStickerSelectedOrder(int order) {
    return '$orderを注文する';
  }

  @override
  String get diaryRecordStickerEmptyHint => '以下のステッカーを選択して、ここですぐに並べ替えてください。';

  @override
  String get diaryRecordStickerReorder => 'ステッカーを再注文する';

  @override
  String get diaryRecordStickerRemove => 'ステッカーを剥がす';

  @override
  String get diaryRecordStickerPinned => 'ステッカーを追加しました';

  @override
  String get diaryRecordStickerPin => 'ステッカーを追加する';

  @override
  String get diaryMealStorySentence =>
      '今日食べたものを振り返って、食事の量が体の調子にどのように関係しているかに注目してください。';

  @override
  String get diaryMealSectionTitle => '食事メモ';

  @override
  String get diaryMealSectionBody => '3食の食事、ご飯の量、体の感じを短いメモにまとめます。';

  @override
  String get diaryNewsOpenFailed => '記事を開けませんでした。';

  @override
  String get mealRoutineTitle => '食べることもトレーニングです';

  @override
  String get mealRoutineSubtitle => 'カロリーの計算を省略して、ご飯茶わんの数で 3 回の食事を記録するだけです。';

  @override
  String get mealBreakfast => '朝食';

  @override
  String get mealLunch => 'ランチ';

  @override
  String get mealDinner => '夕食';

  @override
  String get mealShortLabel => '食事';

  @override
  String get mealDone => '終わり';

  @override
  String get mealSkipped => 'スキップされました';

  @override
  String get mealRiceNone => '0杯';

  @override
  String mealRiceBowls(int count) {
    return '$count ボウル';
  }

  @override
  String get mealRiceLabel => '米';

  @override
  String get mealCoachHeadlinePerfect => '３食の食事は順調に進んでいます。';

  @override
  String get mealCoachHeadlineAlmost => 'あと一食でルーチンは終了です。';

  @override
  String get mealCoachHeadlineNeedsMore => '食事のルーチンにはもっと構造が必要です。';

  @override
  String get mealCoachHeadlineStart => '今日は食事をトレーニングとして捉えてください。';

  @override
  String get mealCoachBodySteady =>
      '食事のタイミングとご飯の量は安定しているようです。次のセッションでテンポを保つには良い日です。';

  @override
  String get mealCoachBodyThreeMeals =>
      '3 回の食事すべてを記録しました。次のステップは、食事ごとにご飯の量があまりにも多くならないようにすることです。';

  @override
  String get mealCoachBodyTwoMealsSolid =>
      '２食しっかりです。回復を安定させるために、不足した食事を一定時間にロックします。';

  @override
  String get mealCoachBodyTwoMealsLight =>
      '2食記録されていますが、ボリュームは軽めです。まずは次の食事を1つのボウルに固定することから始めます。';

  @override
  String get mealCoachBodyOneMeal =>
      '食事は1食のみ記録されます。今日のトレーニングの質を心配する前に、食事を追加してください。';

  @override
  String get mealCoachBodyZeroMeal =>
      'まずは三食のチェックから始めましょう。詳細な計算よりも、欠食を減らすことが重要です。';

  @override
  String get mealXpFull => '3 食完了 +8 XP';

  @override
  String get mealXpFullBonus => '3食完食 + 丼5杯以上 +10 XP';

  @override
  String get mealXpPartial => '2食以上 +3 XP';

  @override
  String get mealXpNeutral => '1食以下ではボーナスなし';

  @override
  String get homeMealCoachTitle => '食事コーチ';

  @override
  String get homeMealCoachRecordAction => '食事';

  @override
  String get homeParentWelcomeMessage => '親モード: 記録とフィードバックのみをレビューします。';

  @override
  String get homeParentWelcomeAction => 'ログ';

  @override
  String get homeMealCoachOtherSuggestions => '他の提案を表示する';

  @override
  String get homeMealCoachHeadlinePerfect => '完了';

  @override
  String get homeMealCoachHeadlineAlmost => 'もうすぐそこ';

  @override
  String get homeMealCoachHeadlineNeedsMore => '仕事が必要です';

  @override
  String get homeMealCoachHeadlineStart => '開始されていません';

  @override
  String get homeMealCoachNoEntry =>
      '今日のトレーニングノートはまだありません。まずは食べた食事を記録することから始めましょう。';

  @override
  String homeMealCoachSummary(
      String breakfastLabel,
      String breakfastValue,
      String lunchLabel,
      String lunchValue,
      String dinnerLabel,
      String dinnerValue) {
    return '$breakfastLabel $breakfastValue・$lunchLabel $lunchValue・$dinnerLabel $dinnerValue';
  }

  @override
  String get homeMealCoachSuggestionStart1 => 'まず、最も頻繁に抜く 1 食を安定させます。';

  @override
  String get homeMealCoachSuggestionStart2 => '記録を開始すると、カロリーよりも食事回数が重要になります。';

  @override
  String get homeMealCoachSuggestionStart3 => '今日最初の食事を記録し、明日その時間を繰り返します。';

  @override
  String get homeMealCoachSuggestionOne1 =>
      '記録されるのは 1 回の食事だけです。次の食事を忘れないように明確な時間に修正してください。';

  @override
  String get homeMealCoachSuggestionOne2 =>
      '食べたらご飯の量も追加してください。次のコーチングのステップがはるかに簡単になります。';

  @override
  String get homeMealCoachSuggestionOne3 =>
      '今では、クイズや日記を終えることよりも、食事を追加することが重要です。';

  @override
  String get homeMealCoachSuggestionTwoLight1 =>
      '2食記録されていますが、ボリュームは軽めです。次の食事では少なくともボウル一杯一杯を目標にしましょう。';

  @override
  String get homeMealCoachSuggestionTwoLight2 =>
      '不足している食事をランダムなスナックに置き換えないでください。本物の食事スロットとして保管してください。';

  @override
  String get homeMealCoachSuggestionTwoLight3 =>
      '食事回数は許容範囲内です。再現可能な米ベンチマークも構築しましょう。';

  @override
  String get homeMealCoachSuggestionTwoSolid1 =>
      '二食のリズムもいいですね。毎日同じ時間枠で不足している食事を修正します。';

  @override
  String get homeMealCoachSuggestionTwoSolid2 =>
      '今日は食事のリズムもまあまあだったので、トレーニング後の体の調子にも注目。';

  @override
  String get homeMealCoachSuggestionTwoSolid3 =>
      '2 回の食事が安定している場合、3 回目の食事は主にスケジュールの問題です。';

  @override
  String get homeMealCoachSuggestionThree1 =>
      '3 回の食事すべてを記録しました。次に、食事ごとの分量の差を減らします。';

  @override
  String get homeMealCoachSuggestionThree2 => '丸三食の日は、日記と組み合わせて回復ルーチンを完了します。';

  @override
  String get homeMealCoachSuggestionThree3 =>
      'リズムが安定しているので、動きがどのくらい軽いか重いかを記録します。';

  @override
  String get homeMealCoachSuggestionSteady1 =>
      '食事のタイミングや量も安定していました。次にトレーニングのテンポを維持することに集中できます。';

  @override
  String get homeMealCoachSuggestionSteady2 =>
      '今日はエネルギー補給がうまくいったようだ。あなたの体がどのように反応したかについての短いメモを追加してください。';

  @override
  String get homeMealCoachSuggestionSteady3 =>
      '食事が安定したので、次の提案は睡眠と日記の見直しをリンクさせることです。';

  @override
  String mealCompactSummary(String label, int count) {
    return '$label $count ボウル';
  }

  @override
  String mealCompactSkipped(String label) {
    return '$label スキップされました';
  }

  @override
  String mealRiceBowlsValue(String count) {
    return '$count ボウル';
  }

  @override
  String get mealLogScreenTitle => '食事記録';

  @override
  String get mealLogDateLabel => 'ログの日付';

  @override
  String get mealLogDatePickerHelp => '食事記録の日付を選択してください';

  @override
  String get mealSaveAction => '食事記録を保存する';

  @override
  String get mealDeleteAction => '食事記録を削除する';

  @override
  String get mealDeleteConfirmBody => 'この日の食事記録を削除しますか?';

  @override
  String get mealSavedFeedback => '食事ログが保存されました。';

  @override
  String mealSavedWithXpFeedback(int count) {
    return '食事ログの保存 +$count XP';
  }

  @override
  String get mealDeletedFeedback => '食事記録削除しました。';

  @override
  String get mealLogXpSourceLabel => '食事記録';

  @override
  String mealAverageExpectedValue(String value) {
    return '予想される平均 $value ボウル';
  }

  @override
  String mealAverageActualValue(String value) {
    return '$value ボウル';
  }

  @override
  String get mealStatsEmpty => '選択した期間に食事のエントリはありません。';

  @override
  String get mealStatsSectionTitle => '食事記録';

  @override
  String get mealStatsTrendTitle => '食事の流れ';

  @override
  String get mealStatsTodayRiceBowlTitle => '最新の丼もの';

  @override
  String get mealStatsLoggedDays => '記録された日数';

  @override
  String get mealStatsExpectedAverage => '予想される平均値';

  @override
  String get mealStatsActualAverage => '実際の平均';

  @override
  String get mealStatsBestDay => '最高の一日';

  @override
  String get mealIncreaseAction => 'ボウルを追加する';

  @override
  String get mealDecreaseAction => 'ボウルを取り外す';

  @override
  String get mealStatsWeightLinkedHint => '体重記録のある日は同じグラフ上でリンクされます。';

  @override
  String get homeRiceBowlTitle => '本日の丼もの';

  @override
  String get homeRiceBowlSubtitle => '一杯のボウル、半分のボウル、スキップされたボウルが一目でわかります。';

  @override
  String get homeRiceBowlFull => 'ボウルいっぱい';

  @override
  String get homeRiceBowlHalf => '半丼';

  @override
  String get homeRiceBowlEmpty => 'スキップされました';

  @override
  String get fortuneDialogTitle => '今日の運勢';

  @override
  String get fortuneDialogSubtitle => '今日のラッキー情報をチェック。';

  @override
  String get fortuneDialogOverviewTitle => 'フォーチュンの概要';

  @override
  String get fortuneDialogOverallFortuneLabel => '全体的な運勢';

  @override
  String get fortuneDialogLuckyInfoLabel => 'ラッキー情報';

  @override
  String fortuneDialogOverallFortuneCount(int count) {
    return '$count ライン';
  }

  @override
  String fortuneDialogLuckyInfoCount(int count) {
    return '$count アイテム';
  }

  @override
  String get fortuneDialogLuckyInfoTitle => 'ラッキー情報';

  @override
  String get fortuneDialogPoolSizeLabel => 'フォーチュンプール';

  @override
  String fortuneDialogPoolSizeCount(String count) {
    return '$count ケース';
  }

  @override
  String get fortuneDialogRecommendedProgramTitle => 'おすすめのトレーニング';

  @override
  String get fortuneDialogRecommendationTitle => 'フォーチュンノート';

  @override
  String get fortuneDialogEncouragement => '今日も最高のプレーを応援します。';

  @override
  String get fortuneDialogAction => 'ニース';

  @override
  String get mealStatsNoTrainingOrMealEntries =>
      '選択した期間にトレーニングや食事のエントリーはありません。';

  @override
  String get drawerRunningCoach => 'ランニングコーチ';

  @override
  String get runningCoachScreenTitle => 'ランニングコーチ';

  @override
  String get runningCoachHeroTitle => 'サイドビューランニングフォームコーチ';

  @override
  String get runningCoachHeroBody =>
      '短い横から見たランニング クリップをアップロードすると、姿勢、バウンス、足の着地、膝の屈曲、腕の動きに関する厳密なフィードバックが得られます。';

  @override
  String get runningCoachAnalyzeBody =>
      '横から撮ったクリップを選ぶと、スコア、関節角度、接地の目安、最初に直す動きが一緒に表示されます。';

  @override
  String get runningCoachTipsTitle => '録音方法';

  @override
  String get runningCoachTipWholeBody =>
      '頭から接地する足まで全身を入れ、肩、腰、膝、足首、肘、手首が見えるようにします。';

  @override
  String get runningCoachTipSideView => 'ランナーがカメラに近づいたり離れたりせず、画面を横切る真横の映像にします。';

  @override
  String get runningCoachTipSteadyCamera =>
      'カメラを固定し、明るく均一な光で、きれいな3歩以上を含む5〜15秒を撮影します。';

  @override
  String get runningCoachUploadGuideTitle => '動画アップロードガイド';

  @override
  String get runningCoachUploadGuideBody =>
      'サンプルガイドで良いフォームと悪いフォームのループを比較し、コーチが読む関節、角度、接地点を確認します。';

  @override
  String get runningCoachUploadGuideStepSide =>
      'スマートフォンを走路に対して直角、腰の高さに置き、ランナーが左右に通過するように撮影します。';

  @override
  String get runningCoachUploadGuideStepDistance =>
      '前後に余白を取り、頭、腰、膝、足首、足、肘、手首が全ステップで見えるようにします。';

  @override
  String get runningCoachUploadGuideStepDuration =>
      '3〜6歩のきれいなストライドを含む5〜15秒を使い、準備歩き、ターン、停止フレームは切ります。';

  @override
  String get runningCoachUploadGuideStepLight =>
      '明るく均一な光とシンプルな背景で撮影し、影、切れた足、背後を横切る人を避けます。';

  @override
  String get runningCoachSampleTitle => 'サンプルビデオガイド';

  @override
  String get runningCoachSampleBody =>
      '基準ループと悪いフォームのループを切り替え、姿勢、着地、膝の負荷、腕の角度、バウンス、フレーム品質をどう読むか確認します。';

  @override
  String get runningCoachSampleGuideAction => 'サンプルビデオガイドを開く';

  @override
  String runningCoachSampleFrameLabel(int current, int total) {
    return 'フレーム $current/$total';
  }

  @override
  String get runningCoachSampleFrameGuideTitle => '動画で比較するもの';

  @override
  String get runningCoachSampleFrameGuideBody =>
      'ランナーと一緒にオーバーレイを読み取ります。姿勢、着地、腕のタイミング、フレーム カバレッジが、単なるテキスト リストとしてではなく、サンプルの上に表示されます。';

  @override
  String get runningCoachSampleCueLean => 'ウエストを折らずに足首から肩まで傾ける';

  @override
  String get runningCoachSampleCueFrame => '頭、腰、膝、足は見えたままになります';

  @override
  String get runningCoachSampleCueFoot => '足はつま先を前にして腰の下で着地する';

  @override
  String get runningCoachSampleCueArms => '肘は曲げたままにし、足とは反対側に振ります';

  @override
  String get runningCoachSampleReferenceTab => '基準サンプル';

  @override
  String get runningCoachSampleMistakeTab => '悪いフォーム';

  @override
  String get runningCoachSampleReferenceTitle => '基準フォームの読み取り';

  @override
  String get runningCoachSampleMistakeTitle => '悪いフォームの読み取り';

  @override
  String get runningCoachSampleReferenceBody =>
      '目標のループです。全身を少し前傾させ、腰の近くに着地し、膝で柔らかく受け、腕はコンパクトに保ちます。';

  @override
  String get runningCoachSampleMistakeBody =>
      'よくある失敗例です。胴体が立ち、足が前に出過ぎ、接地膝が伸び、肘が開き、上下のバウンスが増えます。';

  @override
  String get runningCoachSampleReferencePosture =>
      '姿勢線: 足首-腰-肩の前傾は10°で、腰折れはありません。';

  @override
  String get runningCoachSampleReferenceFoot => '接地点: 着地距離は0.08で、腰の下に近く収まります。';

  @override
  String get runningCoachSampleReferenceKnee => '接地膝: 155°で、ロックせず柔らかく負荷を受けます。';

  @override
  String get runningCoachSampleReferenceArms => '腕角度: 肘は90°付近で、脚と反対に振れます。';

  @override
  String get runningCoachSampleReferenceFrame =>
      'フレーム品質: 主要関節が見える24/24の使用可能フレーム。';

  @override
  String get runningCoachSampleMistakePosture => '姿勢線: 前傾は2°だけで、前へ押せず体が立っています。';

  @override
  String get runningCoachSampleMistakeFoot => '接地点: 腰より0.24前に着くオーバーストライドです。';

  @override
  String get runningCoachSampleMistakeKnee => '接地膝: 176°で、受けて押すには伸びすぎています。';

  @override
  String get runningCoachSampleMistakeArms => '腕角度: 肘が132°まで開き、腕と脚のリズムが遅れます。';

  @override
  String get runningCoachSampleMistakeBounce => 'バウンス: 上下動が12%まで増え、力が上へ逃げます。';

  @override
  String get runningCoachSampleAnalysisMethodTitle => 'コーチの分析方法';

  @override
  String get runningCoachSampleAnalysisMethodBody =>
      '安定した横向きフレームをサンプリングし、ポーズランドマークを追跡し、接地区間を推定して、各指標を信頼度付きで採点します。';

  @override
  String get runningCoachSampleMethodPose =>
      'ポーズランドマーク: 肩、腰、膝、足首、肘、手首、頭が見えている必要があります。';

  @override
  String get runningCoachSampleMethodAngles => '角度: 前傾、接地膝、肘の角度をフレームごとに測定します。';

  @override
  String get runningCoachSampleMethodContact =>
      '接地: 着地に近いフレームから、腰の線に対する足の距離を推定します。';

  @override
  String get runningCoachSampleMethodConfidence =>
      '信頼度: 追跡範囲が低い、または安定フレームが少ない場合は再確認を促します。';

  @override
  String get runningCoachSampleRecordingGuideTitle => 'サンプルのように録音する';

  @override
  String get runningCoachSampleOverlayPosture => 'リーン10°';

  @override
  String get runningCoachSampleOverlayArms => 'アーム90°';

  @override
  String get runningCoachSampleOverlayFoot => '着地 0.08';

  @override
  String get runningCoachSampleOverlayFrames => '24/24フレーム';

  @override
  String get runningCoachSampleMistakeOverlayPosture => '直立 2°';

  @override
  String get runningCoachSampleMistakeOverlayArms => '腕 132°';

  @override
  String get runningCoachSampleMistakeOverlayFoot => '過大 0.24';

  @override
  String get runningCoachSampleMistakeOverlayBounce => '上下 12%';

  @override
  String get runningCoachLiveCardTitle => 'ライブコーチ';

  @override
  String get runningCoachLiveCardBody =>
      'ランナーの輪郭とポーズラインをライブで追跡し、体幹の傾き、膝のドライブ、ステップのリズム、腕のバランスに関するスプリント固有のフィードバックに直接切り替えます。';

  @override
  String get runningCoachLiveAction => 'ライブコーチを開始する';

  @override
  String get runningCoachLiveGuideAction => '撮影ガイド';

  @override
  String get runningCoachLiveScreenTitle => 'ライブランニングコーチ';

  @override
  String get runningCoachLiveGuideScreenTitle => 'ライブ撮影ガイド';

  @override
  String get runningCoachLiveGuideHeroTitle =>
      'ランナーの概要を追跡し、下部のコーチングパネルを一緒に読みます';

  @override
  String get runningCoachLiveGuideHeroBody =>
      'ライブコーチはランナーの輪郭とポーズラインを画面上に直接マークし、下部パネルには説明と結果がまとめて表示されます。トラッキングとフィードバックを安定に保つには、以下のセットアップを使用してください。';

  @override
  String get runningCoachLiveGuideTipSideTitle => '側面図を表示する';

  @override
  String get runningCoachLiveGuideTipSideBody =>
      'ランナーは、カメラに向かってまっすぐに移動したり、斜めに移動したりするのではなく、横からフレームを横切って移動する必要があります。';

  @override
  String get runningCoachLiveGuideTipBodyTitle => '全身をフレーム内に収める';

  @override
  String get runningCoachLiveGuideTipBodyBody =>
      'ポーズ ラインとスコアが安定するように、頭、肘、腰、足首はすべて表示されたままにする必要があります。';

  @override
  String get runningCoachLiveGuideTipHudTitle => '上部のキューと下部の結果を一緒に読み取ります';

  @override
  String get runningCoachLiveGuideTipHudBody =>
      '黄色のボックスの代わりに、画面には上部のステータス キューとランナーのアウトライン マークが表示され、下部のパネルには理由、修正、ボディパーツの結果がまとめて表示されます。';

  @override
  String get runningCoachLiveGuideTipCameraTitle => 'カメラを固定し、本体を十分な大きさに保ちます';

  @override
  String get runningCoachLiveGuideTipCameraBody =>
      'カメラをしっかりと保持し、全身が画面の高さの少なくとも約半分を占めるようにランナーをフレームに収めます。フレームが充実するほど、ポーズ ラインと音声コーチングがより安定します。';

  @override
  String get runningCoachLivePreparingTitle => 'カメラの準備中';

  @override
  String get runningCoachLivePreparingBody => '背面カメラを開いて、ライブポーズ追跡を準備します。';

  @override
  String get runningCoachLiveCameraIssueTitle => 'カメラチェックが必要です';

  @override
  String get runningCoachLiveCameraDenied => 'ライブランニングコーチングにはカメラへのアクセスが必要です。';

  @override
  String get runningCoachLiveCameraFailed =>
      'コーチのライブカメラを開けませんでした。もう一度やり直してください。';

  @override
  String get runningCoachLiveRetryAction => 'もう一度やり直してください';

  @override
  String get runningCoachLiveVoiceOn => '音声コーチングオン';

  @override
  String get runningCoachLiveVoiceOff => '音声コーチングはオフです';

  @override
  String get runningCoachLiveSwitchCamera => 'カメラを切り替える';

  @override
  String get runningCoachLiveStatusFraming => 'まずは枠を固定する';

  @override
  String get runningCoachLiveStatusCollecting => '収集動作';

  @override
  String get runningCoachLiveStatusCoaching => 'ライブコーチングがアクティブです';

  @override
  String get runningCoachLiveCueNoRunner =>
      'ランナーはまだ十分に明確ではありません。フレームに足を踏み入れます。';

  @override
  String get runningCoachLiveCueStepBack => '後ろに下がり、頭からつま先まで全身をフレームに収めます。';

  @override
  String get runningCoachLiveCueMoveCloser => 'ランナーが小さく見えます。もう少しカメラに近づきます。';

  @override
  String get runningCoachLiveCueCenterRunner => 'ランナーをフレームの中央にはっきりと配置します。';

  @override
  String get runningCoachLiveCueTurnSideways => 'より横に回すと走行形状が読みやすくなります。';

  @override
  String get runningCoachLiveCueKeepRunning =>
      '良い。さらに数ステップ同じリズムを維持すると、コーチングが表示されます。';

  @override
  String get runningCoachLiveCueLookingGood => '良い。このリズムを保ち、同じ形を保ちます。';

  @override
  String runningCoachLiveTrackedFrames(int count) {
    return '追跡フレーム $count';
  }

  @override
  String get runningCoachLiveScorePending => '採点中...';

  @override
  String runningCoachLiveOverallScore(int score) {
    return 'ライブスコア $score/100';
  }

  @override
  String get runningCoachLiveGuidanceTitle => '現在のガイダンス';

  @override
  String get runningCoachSprintLiveCardTitle => 'ライブスプリントコーチング';

  @override
  String get runningCoachSprintLiveCardBody =>
      'サイドビュー カメラを使用して体幹の傾き、膝のドライブ、ステップのリズム、腕のバランスを読み取り、今修正すべき 1 つのスプリント キューを取得します。';

  @override
  String get runningCoachSprintLiveAction => 'スプリントコーチングを始める';

  @override
  String get runningCoachSprintLiveScreenTitle => 'ライブスプリントコーチング';

  @override
  String get runningCoachSprintLiveStatusLowConfidence => '最初に全身のフレームを修正します';

  @override
  String get runningCoachSprintLiveStatusCollecting => 'スプリントのリズムを安定させる';

  @override
  String get runningCoachSprintLiveStatusReady => 'ライブフィードバックの準備完了';

  @override
  String get runningCoachSprintLiveStatusCoaching => 'ライブスプリントフィードバックが有効です';

  @override
  String get runningCoachSprintLiveCueCollecting =>
      'リズムとニードライブの測定値が安定するように、さらに数歩保持します。';

  @override
  String get runningCoachSprintLiveCueReady =>
      '良い。この形を保ち、さらに 5 ～ 10 秒間全力疾走します。';

  @override
  String get runningCoachSprintGuideSideCapture => 'サイドビューをクリアに保つ';

  @override
  String get runningCoachSprintGuideFullBodyFraming => '全身をフレーム内に収める';

  @override
  String runningCoachSprintTrackingConfidenceValue(int percent) {
    return '追跡 $percent%';
  }

  @override
  String runningCoachSprintTrackedFrames(int count) {
    return '追跡された $count フレーム';
  }

  @override
  String runningCoachSprintDetectedSteps(int count) {
    return 'ステップイベント $count';
  }

  @override
  String get runningCoachSprintSessionLogTitle => 'セッションの概要';

  @override
  String get runningCoachSprintSessionCameraFpsLabel => 'カメラ入力FPS';

  @override
  String get runningCoachSprintSessionAnalyzedFpsLabel => '分析された FPS';

  @override
  String get runningCoachSprintSessionAverageProcessingLabel => '平均処理';

  @override
  String runningCoachSprintSessionAverageProcessingValue(Object ms) {
    return '${ms}ms';
  }

  @override
  String get runningCoachSprintSessionSkippedFramesLabel => 'ドロップ/スキップ';

  @override
  String runningCoachSprintSessionSkippedFramesValue(int count) {
    return '$count フレーム';
  }

  @override
  String get runningCoachSprintSessionBodyNotVisibleLabel => '本体損失率';

  @override
  String runningCoachSprintSessionBodyNotVisibleValue(int percent) {
    return '$percent%';
  }

  @override
  String get runningCoachSprintSessionBodyVisibilityLabel => '身体の可視性';

  @override
  String runningCoachSprintSessionBodyVisibilityValue(
      Object status, int visible, int total, int percent) {
    return '$status・コア$visible/$total・$percent%';
  }

  @override
  String get runningCoachSprintSessionActiveFeedbackLabel => 'アクティブなフィードバック';

  @override
  String runningCoachSprintSessionActiveFeedbackValue(Object key, Object text) {
    return '$key・$text';
  }

  @override
  String get runningCoachSprintSessionFeedbackEmpty => '待っている';

  @override
  String get runningCoachSprintSessionFeedbackChangesLabel => 'フィードバックの変更';

  @override
  String runningCoachSprintSessionFeedbackChangesValue(
      int count, Object perMinute, int suppressed) {
    return '$count の変化 / 分ごとの $perMinute · クールダウン保持 $suppressed';
  }

  @override
  String get runningCoachSprintSessionReadinessLabel => '準備完了';

  @override
  String runningCoachSprintSessionReadinessValue(
      int visible, int missing, int stable, Object travel) {
    return '可視 $visible · ミス $missing · 安定した $stable · トラベル $travel';
  }

  @override
  String get runningCoachSprintSessionStepDetectorLabel => '段差検出器';

  @override
  String runningCoachSprintSessionStepDetectorValue(
      int switches, int accepted, int lowVelocity, int minInterval) {
    return 'スイッチ $switches ・ ok $accepted ・ lowV $lowVelocity ・ ギャップ $minInterval';
  }

  @override
  String get runningCoachSprintSessionConfidenceLabel => '画期的な信頼性';

  @override
  String runningCoachSprintSessionConfidenceValue(
      int high, int medium, int low) {
    return '0.8+ $high% · 0.6-0.8 $medium% · <0.6 $low%';
  }

  @override
  String get runningCoachSprintMetricPending => '--';

  @override
  String get runningCoachSprintMetricTrunkLabel => '体幹スリム';

  @override
  String runningCoachSprintMetricTrunkValue(Object value) {
    return '$value°';
  }

  @override
  String get runningCoachSprintMetricKneeDriveLabel => 'ニードライブ';

  @override
  String runningCoachSprintMetricKneeDriveValue(Object value) {
    return 'スケール $value%';
  }

  @override
  String get runningCoachSprintMetricCadenceLabel => 'ケイデンス';

  @override
  String runningCoachSprintMetricCadenceValue(Object value) {
    return '$value spm';
  }

  @override
  String get runningCoachSprintMetricRhythmLabel => 'リズムドリフト';

  @override
  String runningCoachSprintMetricRhythmValue(Object value) {
    return '${value}ms';
  }

  @override
  String get runningCoachSprintMetricArmBalanceLabel => 'アームバランス';

  @override
  String runningCoachSprintMetricArmBalanceValue(Object value) {
    return 'ギャップ $value%';
  }

  @override
  String get runningCoachSprintBodyVisibilityFull => '全身ロック';

  @override
  String get runningCoachSprintBodyVisibilityPartial => '部分的なランドマーク';

  @override
  String get runningCoachSprintBodyVisibilityNotVisible => '身体が失われた';

  @override
  String get runningCoachSprintCueBodyVisible => '全身がフレーム内に収まるようにもう 1 段階調整します。';

  @override
  String get runningCoachSprintCueLeanForward =>
      'ウエストで折るのではなく、足首から少し前傾するようにします。';

  @override
  String get runningCoachSprintCueDriveKnee => '押し出した後、膝をもう少し積極的に前に動かします。';

  @override
  String get runningCoachSprintCueKeepRhythm =>
      '左右のリズムが漂います。接地接触をより均一に保つようにしてください。';

  @override
  String get runningCoachSprintCueBalanceArms =>
      '腕の振りがアンバランスです。両側の後進ドライブをより厳密に一致させます。';

  @override
  String get runningCoachSprintCueKeepPushing => '良い。同じリズムで前傾姿勢で押し続けます。';

  @override
  String get runningCoachSelectedVideoLabel => '選択したビデオ';

  @override
  String get runningCoachNoVideoSelected => 'まだビデオが選択されていません。';

  @override
  String get runningCoachPickVideoAction => 'ビデオを選択';

  @override
  String get runningCoachAnalyzeAction => '分析実行';

  @override
  String get runningCoachAnalysisInProgress => '分析中...';

  @override
  String get runningCoachPickVideoFailed => 'ビデオピッカーを開けませんでした。';

  @override
  String get runningCoachUnsupportedPlatform =>
      'ビデオ分析の実行は、Android および iPhone/iPad アプリのビルドでのみ利用できます。';

  @override
  String get runningCoachNativeAnalyzerUnavailable =>
      'このアプリのビルドには、実行中のビデオ アナライザーがまだ含まれていません。最新のモバイル アプリ ビルドを再インストールして、もう一度試してください。';

  @override
  String get runningCoachVideoFileMissing => '選択したビデオ ファイルが見つかりませんでした。';

  @override
  String get runningCoachVideoTooShort =>
      'ビデオが短すぎます。少なくともいくつかのランニングステップを記録します。';

  @override
  String get runningCoachNoPoseDetected =>
      'ランナーを十分に追跡できませんでした。肘、膝、足が見える、より鮮明なサイドビュー クリップを試してください。';

  @override
  String get runningCoachAnalysisFailedGeneric =>
      '分析の実行に失敗しました。より鮮明な側面図を持つ別のクリップを試してください。';

  @override
  String get runningCoachResultsTitle => 'コーチング実績';

  @override
  String get runningCoachOverallHeadlineStrong => '力強いランニング形状';

  @override
  String get runningCoachOverallHeadlineSolid => '1 つの明確な修正を備えた強固なベース';

  @override
  String get runningCoachOverallHeadlineNeedsWork => 'よりクリーンなランニングパターンを構築する';

  @override
  String runningCoachOverallSummary(int score) {
    return '総合ランニングスコア $score/100';
  }

  @override
  String get runningCoachOverallScoreLabel => '総合スコア';

  @override
  String get runningCoachDurationLabel => 'クリップ';

  @override
  String get runningCoachFramesAnalyzedLabel => 'フレーム';

  @override
  String get runningCoachCoverageLabel => 'カバレッジ';

  @override
  String get runningCoachMetricScoresTitle => 'メトリクススコア';

  @override
  String get runningCoachFocusTitle => 'まず集中してください';

  @override
  String get runningCoachMaintainTitle => 'これらを保管してください';

  @override
  String runningCoachMetricScore(int score) {
    return 'スコア $score';
  }

  @override
  String runningCoachPriorityLabel(int priority) {
    return '優先順位 $priority';
  }

  @override
  String get runningCoachMetricValueLabel => '測定値';

  @override
  String get runningCoachBodyRegionUpper => '上半身';

  @override
  String get runningCoachBodyRegionLower => '下半身';

  @override
  String get runningCoachBodyRegionWhole => '全身のリズム';

  @override
  String get runningCoachStatusGood => '良い';

  @override
  String get runningCoachStatusWatch => '時計';

  @override
  String get runningCoachStatusNeedsWork => '仕事が必要です';

  @override
  String runningCoachLeanValue(Object value) {
    return '$value° 前傾';
  }

  @override
  String runningCoachBounceValue(Object value) {
    return '$value% 垂直バウンド';
  }

  @override
  String runningCoachFootStrikeValue(Object value) {
    return '${value}x 腰より前';
  }

  @override
  String runningCoachKneeValue(Object value) {
    return '$value°サポート膝角度';
  }

  @override
  String runningCoachArmValue(Object value) {
    return '$value° エルボ角度';
  }

  @override
  String runningCoachStrideValue(Object value) {
    return '${value}x ストライドリーチ';
  }

  @override
  String get runningCoachInsightPostureTitle => '姿勢';

  @override
  String get runningCoachPostureGoodSummary =>
      '体の角度は、わずかに前傾したきれいなスプリント姿勢に近いです。';

  @override
  String get runningCoachPostureGoodCue => '胸を高く保ち、体全体を前に倒します。';

  @override
  String get runningCoachPostureGoodDrill =>
      'ドリル: 同じボディラインを固定するために、15m の壁沿いの行進を 2 回行います。';

  @override
  String get runningCoachPostureUprightSummary =>
      '胴体が直立しすぎているため、一歩ごとに前向きな姿勢が失われている可能性があります。';

  @override
  String get runningCoachPostureUprightCue =>
      '「つま先よりも鼻」を考えて、ウエストではなく足首から痩せるようにしましょう。';

  @override
  String get runningCoachPostureUprightDrill =>
      'ドリル: 15m の落下スタートを 2 回、その後 15m の壁沿いの行進を 2 回。';

  @override
  String get runningCoachPostureLeanSummary =>
      '上体が傾きすぎると、歩幅が崩れ、回復が遅くなることがあります。';

  @override
  String get runningCoachPostureLeanCue => '腰から背を高く伸ばし、肋骨が骨盤の上に重なるようにします。';

  @override
  String get runningCoachPostureLeanDrill =>
      'ドリル: 高さ 20 メートル x 2 回の姿勢で、軽く素早いステップで走ります。';

  @override
  String get runningCoachInsightBounceTitle => 'バウンス';

  @override
  String get runningCoachBounceGoodSummary =>
      '垂直方向の動きが制御されているように見え、エネルギーを前に進めるのに役立ちます。';

  @override
  String get runningCoachBounceGoodCue => '上に跳ね返るのではなく、地面を後ろに押し続けます。';

  @override
  String get runningCoachBounceGoodDrill =>
      'ドリル: 次のスプリントセットの前に、20m の足首ドリブルを 2 回実行します。';

  @override
  String get runningCoachBounceHighSummary =>
      'クリップには余分な上下のバウンスがあり、エネルギーを浪費する可能性があります。';

  @override
  String get runningCoachBounceHighCue =>
      '素早いコンタクトを考えて、まっすぐ下にではなく、地面を後ろに押してください。';

  @override
  String get runningCoachBounceHighDrill =>
      'ドリル: 3 x 20mの足首ドリブルと短いコンタクトでのストレートレッグラン。';

  @override
  String get runningCoachInsightFootStrikeTitle => 'フットストライク';

  @override
  String get runningCoachFootStrikeGoodSummary =>
      '先頭の足は、ステップが前方に転がり続けることができるほど十分に腰の近くで着地します。';

  @override
  String get runningCoachFootStrikeGoodCue =>
      '腰の下で着地を続け、手を伸ばすのではなく、押し出すことからスピードを出しましょう。';

  @override
  String get runningCoachFootStrikeGoodDrill =>
      'ドリル: 短く素早いコンタクトを伴う 2 x 20m のウィケットスタイルのラン。';

  @override
  String get runningCoachFootStrikeOverSummary =>
      '先頭の足が腰の前に伸びすぎているため、接地時にブレーキがかかる可能性があります。';

  @override
  String get runningCoachFootStrikeOverCue =>
      '着地点を腰の下に戻し、前方に手を伸ばすのではなく、後ろに押すことを考えてください。';

  @override
  String get runningCoachFootStrikeOverDrill =>
      'ドリル: 20m の A マーチ 2 回と、コンタクトが短い 20m のウィケットスタイルのラン 2 回。';

  @override
  String get runningCoachInsightKneeTitle => '膝の屈曲';

  @override
  String get runningCoachKneeGoodSummary =>
      'サポート膝は十分に曲がっており、崩れることなく弾力性を保っています。';

  @override
  String get runningCoachKneeGoodCue =>
      '着地時にロックするのではなく、スタンス脚を柔らかく反応性のある状態に保ちます。';

  @override
  String get runningCoachKneeGoodDrill =>
      'ドリル: 20m ポゴラン 2 回、その後 20m ドリブルラン 2 回。';

  @override
  String get runningCoachKneeStraightSummary =>
      'サポート膝が真っすぐに着地しすぎると、ステップが硬くて重く見えることがあります。';

  @override
  String get runningCoachKneeStraightCue => '着地の膝を柔らかくし、脚が腰の下で地面を受け入れるようにします。';

  @override
  String get runningCoachKneeStraightDrill =>
      'ドリル: 膝を曲げたコンタクトと素早いステップでの 20m ドリブル ランを 2 回実行します。';

  @override
  String get runningCoachKneeCollapseSummary =>
      'サポート膝が接地後に折りすぎているため、スタンス脚の剛性が失われています。';

  @override
  String get runningCoachKneeCollapseCue => 'スタンスレッグ全体で弾力を保ち、腰を足の上に重ねた状態に保ちます。';

  @override
  String get runningCoachKneeCollapseDrill =>
      'ドリル: 片側あたり 15 メートルの片足ポゴホップを 2 回、その後 20 メートルのドリブルランを 2 回行います。';

  @override
  String get runningCoachInsightArmTitle => 'アームキャリッジ';

  @override
  String get runningCoachArmGoodSummary =>
      '肘はコンパクトな範囲に留まり、上半身を過度に緊張させることなくリズムをサポートします。';

  @override
  String get runningCoachArmGoodCue => '肘を曲げたまま、脚と同じリズムで手を前から後ろに動かします。';

  @override
  String get runningCoachArmGoodDrill =>
      'ドリル：20秒の壁アームスイッチ×2、次に20メートルアームドライブ行進×2。';

  @override
  String get runningCoachArmOpenSummary =>
      '肘が開きすぎているため、腕がリズムを​​助けるどころか漏れている可能性があります。';

  @override
  String get runningCoachArmOpenCue =>
      '肘をさらに曲げたままにし、手を長く伸ばすのではなく、腰の後ろを後ろに動かします。';

  @override
  String get runningCoachArmOpenDrill =>
      'ドリル: 肘を 80 ～ 100 度コンパクトに曲げた状態で、20 秒の壁アーム スイッチを 2 回実行します。';

  @override
  String get runningCoachArmTightSummary =>
      '肘が固すぎると腕の振りが短くなり、ストライドが無理に感じられることがあります。';

  @override
  String get runningCoachArmTightCue => '肩をリラックスさせ、肘をもう少し開きながら、手を後ろに動かし続けます。';

  @override
  String get runningCoachArmTightDrill =>
      'ドリル: 肩をリラックスさせてバックドライブをスムーズにして、20m のマーチングアームを 2 回振ります。';

  @override
  String get runningCoachInsightStrideTitle => 'ストライドリーチ';

  @override
  String get runningCoachStrideGoodSummary => '前足は体の下にある便利な着地窓の近くに留まります。';

  @override
  String get runningCoachStrideGoodCue => '同じタイミングを保ち、手を伸ばすのではなく力でストライドを広げます。';

  @override
  String get runningCoachStrideGoodDrill =>
      'ドリル: 同じリズムを保つために、20m のウィケットスタイルの素早いステップを 2 回実行します。';

  @override
  String get runningCoachStrideShortSummary =>
      'ストライドの到達距離が短​​く見えるので、足を引っ張って十分に走り始めていない可能性があります。';

  @override
  String get runningCoachStrideShortCue =>
      '膝を前方に動かし、より速い腕のリズムに合わせてステップを自然に開きます。';

  @override
  String get runningCoachStrideShortDrill =>
      'ドリル: 2 x 20m の A マーチを A スキップに入れてフロントサイドのメカニックを構築します。';

  @override
  String get runningCoachStrideOverSummary => '前足が体の前方に伸びすぎて、ブレーキがかかる可能性があります。';

  @override
  String get runningCoachStrideOverCue =>
      '腰の下に近い位置で着地し、手を伸ばすのではなく、押し出すことからスピードを出しましょう。';

  @override
  String get runningCoachStrideOverDrill =>
      'ドリル: 20m の A マーチを 2 回、短いコンタクトを伴う 20m のウィケットスタイルのランを 2 回。';

  @override
  String get runningCoachSprintDebugToggle => 'スプリント デバッグ オーバーレイの切り替え';

  @override
  String get runningCoachSprintDebugPanelTitle => 'デバッグオーバーレイ';

  @override
  String get runningCoachSprintCueWhyLabel => 'なぜ';

  @override
  String get runningCoachSprintCueTryLabel => '試す';

  @override
  String get runningCoachSprintTrackingStateBodyTooSmall => '近くに移動してください';

  @override
  String get runningCoachSprintTrackingStateBodyOutOfFrame => '全身をフレーム内に収める';

  @override
  String get runningCoachSprintTrackingStateLowConfidence => '追跡の信頼性を高める';

  @override
  String get runningCoachSprintTrackingStateSideViewUnstable => 'サイドビューを決める';

  @override
  String get runningCoachSprintTrackingStateReady => '分析の準備完了';

  @override
  String get runningCoachSprintTrackingHintBodyTooSmall =>
      'ランナーのフレームが小さすぎます。分析する前に近づいてください。';

  @override
  String get runningCoachSprintTrackingHintBodyOutOfFrame =>
      '一部のジョイントがフレームから外れているため、ポーズ ラインをロックしたままにすることができません。';

  @override
  String get runningCoachSprintTrackingHintLowConfidence =>
      '今のところポーズの信頼性は低いです。もう少し安定したショットを続けてください。';

  @override
  String get runningCoachSprintTrackingHintSideViewUnstable =>
      'サイドビューの動きがまだ不安定です。きれいな横方向の走行経路を維持します。';

  @override
  String get runningCoachSprintTrackingDiagnosisBodyTooSmall =>
      '現在のボディボックスは小さすぎるため、デバイス上で体幹、膝、リズムを安定して測定できません。';

  @override
  String get runningCoachSprintTrackingDiagnosisBodyOutOfFrame =>
      'コア ジョイントがエッジ付近でクリッピングしているため、ポーズ ラインとスプリント メトリクスがドリフトする可能性があります。';

  @override
  String get runningCoachSprintTrackingDiagnosisLowConfidence =>
      '目に見える関節やランドマークの信頼度の平均は、コーチングの品質基準を下回っています。';

  @override
  String get runningCoachSprintTrackingDiagnosisSideViewUnstable =>
      'モーション パスはまだ十分に横方向にとどまっていないため、側面図の分析は差し控えられています。';

  @override
  String get runningCoachSprintTrackingActionBodyTooSmall =>
      '本体が画面の高さの約半分以上になるまでカメラを近づけます。';

  @override
  String get runningCoachSprintTrackingActionBodyOutOfFrame =>
      '再び全力疾走する前に、頭、肘、腰、足首をガイド フレーム内に保ってください。';

  @override
  String get runningCoachSprintTrackingActionLowConfidence =>
      'より安定したカメラ、より鮮明な照明を使用し、数フレームの間ランナーを中心に保ちます。';

  @override
  String get runningCoachSprintTrackingActionSideViewUnstable =>
      'カメラに向かって流したり斜めに流したりするのではなく、横からフレームを横切って走ります。';

  @override
  String runningCoachSprintTrackingSummary(
      Object state, int heightPercent, int areaPercent) {
    return '$state・高さ $heightPercent%・面積 $areaPercent%';
  }

  @override
  String runningCoachSprintSpeechSummary(Object state, Object reason) {
    return 'スピーチ $state・$reason';
  }

  @override
  String get runningCoachSprintSpeechStateIdle => 'アイドル状態';

  @override
  String get runningCoachSprintSpeechStateQueued => 'キューに入れられました';

  @override
  String get runningCoachSprintSpeechStateStarted => '開始しました';

  @override
  String get runningCoachSprintSpeechStateCompleted => '完了';

  @override
  String get runningCoachSprintSpeechStateSkipped => 'スキップされました';

  @override
  String get runningCoachSprintSpeechStateCancelled => 'キャンセル';

  @override
  String get runningCoachSprintSpeechStateError => 'エラー';

  @override
  String get runningCoachSprintSpeechSkipNone => 'スキップなし';

  @override
  String get runningCoachSprintSpeechSkipDisabled => '音声フィードバックがオフになっています';

  @override
  String get runningCoachSprintSpeechSkipNoFeedbackSelected =>
      'フィードバックが選択されていません';

  @override
  String get runningCoachSprintSpeechSkipEmptyCue => 'キューテキストが空です';

  @override
  String get runningCoachSprintSpeechSkipInfoFeedback => '警告信号のみが読み上げられます';

  @override
  String get runningCoachSprintSpeechSkipTrackingNotReady => '追跡はまだ準備ができていません';

  @override
  String get runningCoachSprintSpeechSkipLowConfidence =>
      'フィードバックの信頼性が低すぎてスピーチができない';

  @override
  String get runningCoachSprintSpeechSkipTrackingNotStable =>
      'トラッキングが十分に長く安定していない';

  @override
  String get runningCoachSprintSpeechSkipCooldownActive => 'スピーチのクールダウンが有効です';

  @override
  String get runningCoachSprintDiagnosisLeanForward =>
      '体幹の立ち上がりが早すぎるため、最初の加速ステップで前方への推進力が失われます。';

  @override
  String get runningCoachSprintDiagnosisDriveKnee =>
      '膝ドライブが腰に対して低い位置にあるため、フロントサイドステップが強くつながりません。';

  @override
  String get runningCoachSprintDiagnosisKeepRhythm =>
      'ステップのタイミングがばらつきすぎて、左右のスプリントのリズムがズレてしまいます。';

  @override
  String get runningCoachSprintDiagnosisBalanceArms =>
      '片方の腕は後方への駆動にあまり貢献していないため、上半身からのリズムサポートが不均一になります。';

  @override
  String get runningCoachSprintDiagnosisKeepPushing =>
      '主要なスプリント指標は安定範囲内にあるため、アプリは現在のキューを保持しています。';

  @override
  String get runningCoachSprintActionLeanForward =>
      '最初の 3 ステップでは胸を低く保ち、足首から前傾するようにします。';

  @override
  String get runningCoachSprintActionDriveKnee =>
      '地面を強く押して、膝を自分で持ち上げようとするのではなく、膝を通すようにします。';

  @override
  String get runningCoachSprintActionKeepRhythm =>
      'それ以上長いステップに手を伸ばさないでください。次の数歩の間、接地点を等間隔に保ちます。';

  @override
  String get runningCoachSprintActionBalanceArms =>
      '両側の後方アームドライブを一致させ、肩を静かに保ちます。';

  @override
  String get runningCoachSprintActionKeepPushing =>
      'アプリが安定性を確認できるように、さらに数ステップ同じ形状を維持します。';

  @override
  String get runningCoachSprintSessionTrackingStateLabel => '追跡状態';

  @override
  String get runningCoachSprintSessionPersonSizeLabel => '人のサイズ';

  @override
  String runningCoachSprintSessionPersonSizeValue(
      int heightPercent, int areaPercent) {
    return '高さ $heightPercent% · 面積 $areaPercent%';
  }

  @override
  String get runningCoachSprintSessionVisibleJointCountLabel => '目に見える接合部';

  @override
  String runningCoachSprintSessionVisibleJointCountValue(
      int count, Object confidence) {
    return '$count ジョイント · 平均 $confidence';
  }

  @override
  String get runningCoachSprintSessionSpeechStateLabel => '発話状態';

  @override
  String runningCoachSprintSessionSpeechStateValue(
      Object state, Object reason, int cooldownMs) {
    return '$state · $reason · クールダウン ${cooldownMs}ms';
  }

  @override
  String get runningCoachSprintSessionFeatureConfidenceLabel => '特徴の信頼度';

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
    return '$feature は利用不可: $reason';
  }

  @override
  String get runningCoachSprintFeatureUnavailableJointWindow =>
      '十分な安定した関節フレームがありません';

  @override
  String get runningCoachSprintFeatureUnavailableStepEvents =>
      '十分な安定したステップイベントがありません';

  @override
  String get homeWeatherNeedsLocationTitle => '場所が必要です';

  @override
  String get homeWeatherNeedsLocationSubtitle => '位置情報をオンにする';

  @override
  String get homeStreakBadgeActive => '勢い';

  @override
  String get homeStreakBadgeResume => '再起動';

  @override
  String homeStreakActiveTodayTitle(int count) {
    return '$count 連続日';
  }

  @override
  String homeStreakActiveYesterdayTitle(int count) {
    return '$count 昨日までの数日間';
  }

  @override
  String homeStreakPausedTitle(int count) {
    return '$count 日連続記録が一時停止';
  }

  @override
  String get homeStreakActiveTodayBody =>
      '今日のセッションはすでに始まっています。明日はもう 1 つの短いログでリズムを構築していきます。';

  @override
  String get homeStreakActiveYesterdayBody =>
      '今日、セッションをもう 1 つ追加すると、最近のリズムがまっすぐに進みます。';

  @override
  String homeStreakPausedBody(int gap) {
    return '$gap 日間ご不在でした。短いセッションから再開すると、すぐにリズムが戻ります。';
  }

  @override
  String homeStreakLastLogged(Object date) {
    return '最終ログ $date';
  }

  @override
  String homeStreakDaysValue(int count) {
    return '$count 日';
  }

  @override
  String get homeStreakActionContinue => '今日の記録';

  @override
  String get homeStreakActionReview => '週';

  @override
  String get educationScreenTitle => 'お父さんがテオに語るワールドカップの物語';

  @override
  String get educationStoryIntroBody =>
      'テオ、今夜はワールドカップを問題集のようにめくってほしくない。ひとつの長い物語として読んでほしい。チャンピオンの名前だけでなく、各トーナメントが残した匂い、騒音、表情を思い出すと、その気持ちはずっと長く続きます。スコアラインと同じくらい、顔や時代の空気を見つめる選手に成長してほしい。\n\nそのため、この画面ではストーリーが小さなページに分割されなくなりました。これで一気に長く読めます。親指で章をめくるのではなく、何年もゆっくりと進み続けてください。 1930 年のウルグアイと 2026 年の北米のまだ開かれていないページが 1 つの線でつながっているように感じてもらいたいのです。';

  @override
  String get educationStoryOriginsTitle => '1930 ～ 1938 年、初めてのワールドカップが船で到着';

  @override
  String get educationStoryOriginsBody =>
      'テオ、最初のワールドカップは飛行機よりも船が重要だった時代に始まりました。ヨーロッパのチームは数週間をかけて海を渡りウルグアイに到着し、ホストチームは100周年祝賀の熱気の中でエスタディオ・センテナリオの完成を急いだ。現代の基準からすると、すべてが不便に見えますが、その遅さこそが、最初のトーナメントが依然として非常に鋭く感じられる理由です。ワールドカップは最初から私たちに、大きな出来事はしばしば多少の不快感を抱えてやってくることを教えてくれました。\n\nそして、物語が 1934 年のイタリアと 1938 年のフランスに移るとき、結果表だけを見てほしくないのです。ムッソリーニの影、長旅、出場をめぐる憤り、そして審判の議論にも目を向けてほしい。ワールドカップは決してサッカーだけのものではありませんでした。旅行技術、政治、国家間の感情はすでに草にくっついていました。\n\nしたがって、1930 年、1934 年、1938 年を思い出すときは、3 つの数字だけを覚えてはいけません。塩の匂い、スピーチの調子、不安な拍手の音をそのままにしておきます。歴史を実際の場面として思い出すと、歴史は試験の答えのように感じなくなります。';

  @override
  String get educationStoryReturnTitle => '1950 年から 1970 年、同じトーナメントに沈黙と笑顔があった頃';

  @override
  String get educationStoryReturnBody =>
      '戦争で空いた年月を経て、1950 年にブラジルでワールドカップが復活し、人々はおそらく最初に祝賀会を期待したでしょう。しかし、テオ、私があのトーナメントについて話すときはいつも、マラカナンの沈黙から始めます。ウルグアイがブラジルに勝利したことは、一つの結果が国全体の規模を変える可能性があることを示した。\n\nその後、物語は 1954 年のベルンの奇跡、1958 年の 17 歳のペレ、1962 年のガリンシャ、1966 年のイングランド、そして 1970 年の黄金のブラジルへと急速に進みます。その時までに、ワールドカップは単なるトーナメント以上のものになっていました。それは集合的な記憶を作るための機械と化していました。誰かが倒れ、誰かが現れ、そして誰かが非常に完成して伝説のように見え始める。\n\nこの続きを読むときは、再起動、衝撃、誕生、復讐、完了という 5 つの単語を横に置いておいてください。その言葉は、長い時代を、その思いを少しも萎縮させることなく、あなたの手に折り畳む。';

  @override
  String get educationStoryMiddleTitle =>
      '1974 年から 2006 年まで、美しさと議論は一緒に記憶されなければなりません';

  @override
  String get educationStoryMiddleBody =>
      '1974年までに、空気の質感は再び変わります。トロフィーが変わり、オランダはトータルフットボールでピッチの座標を揺るがし、西ドイツはその美しい混乱を結果に変えた。テオ、この時代を読むたびに、サッカーは理想主義と現実が公の場で衝突する数少ない場所の一つであることを思い出します。グレースは愛されやすいですが、トロフィーは通常、より重いものに傾いています。\n\nしかし、この時期は決して戦術の内側だけに当てはまるものではありません。 1978 年のアルゼンチンには軍事政権の寒さが漂っています。 1982年のバティストンの転倒は、あまりにも長い間記憶に残っている。 1986年のマラドーナはまるで天気のようだ。そして、1990年のロジェ・ミラのダンス、2002年の韓国の準決勝進出、そして2006年のジダンの頭突きは、ワールドカップがいかにテレビから溢れ出て家庭内の雰囲気を変えるのかを示している。\n\nそして、2002 年は私たちにとって他人のタイムラインではありません。そこには、街頭での叫び声、深夜の喧騒、そしてホイッスルが鳴った後も静まり返らない空気が含まれます。したがって、この時代を読むときは、誰が得点したかだけを思い出さないでください。それがどんな夜だったのか思い出してください。';

  @override
  String get educationStoryRecentTitle =>
      '2010 年から 2022 年、数字が増えるほど、シーンはより鮮明になりました';

  @override
  String get educationStoryRecentBody =>
      'South Africa 2010 を開くと、最初にブブゼラが聞こえます。ブラジル 2014 を開くと、7 対 1 のスコアボードが何よりも早く表示されます。 2018年のロシアではVARモニターの前で黙とうがあり、2022年のカタールではメッシとムバッペが一つの決勝戦の中​​で世代の継承と世代の衝突の両方を抱えている。テオさん、データとテクノロジーが増えれば話が曖昧になるように聞こえますが、ワールドカップはどういうわけか逆の方向に進みました。数字が多くなればなるほど、その光景はより強く身体の中に残ります。\n\nクローゼの16点目、モロッコの準決勝進出、そしてスアレスのハンドボールはすべて記録簿に残るだろう。しかし、人々が何年も抱き続けているものは、依然としてその瞬間の人間の表現です。それが私が一番伝えたいことです。テーブルが整理されます。シーンはそれを理解させます。\n\nしたがって、最近のワールドカップを観るときは、スコアラインやデータだけに止まらないでください。なぜ人々はショックを受けたのか、なぜ話し続けたのか、なぜそのイメージが残ったのかを尋ねてください。そうやってサッカーの地図は広がっていくのです。';

  @override
  String get educationStoryPeopleTitle => '人も政治もテクノロジーも必要だ';

  @override
  String get educationStoryPeopleBody =>
      'テオさん、ワールドカップはチャンピオンズテーブルだけでは決して説明できません。ジュール・リメ、ポッツォ、ペレ、ベッケンバウアー、マラドーナ、ロナウド、メッシなど、時代全体を前進させた顔が必要です。また、戦争がサッカーの最も壮大なカレンダーを止めるほど強かった1942年と1946年の中止されたトーナメントのような瞬間も必要です。そうして初めて、ワールドカップがいかに急速に広い世界に似てきたかがわかります。\n\n1966年にジュール・リメ・トロフィーを取り戻した犬ピクルス、1982年のシューマッハとバティストンの衝突、2010年のランパードの取り消しゴール、2014年のゴールラインテクノロジー、2018年のVAR、2022年の半自動オフサイドはすべて同じ線上に属します。サッカーは常により公平になることを望んでいますが、同時に完璧な公平性が完全には実現しないことも明らかにしています。\n\nしたがって、すべてのトーナメントの横に 2 つの質問を書き続けてください。誰が勝ったのか。そして何が変わったのか。これら 2 つの線をまとめ始めると、歴史は堅苦しくなくなり、同時により正確になります。';

  @override
  String get educationStoryFutureTitle => '2026年以降、まだ開かれていないページを読むには';

  @override
  String get educationStoryFutureBody =>
      '次に、2026 年の北米に目を向けましょう。48 チーム、104 試合、3 つの開催国が参加するこのフィールドは、すでに以前のトーナメントとは異なる顔を見せています。テオ、これらの数字を見ると、移動距離、回復時間、ベンチの強さ、不慣れな相手を素早く解読する能力について何よりも考えます。トーナメントが長くなればなるほど、1 つのスターよりも耐久力全体の構造に依存するようになります。\n\nしたがって、未来を読むことは、占い師のように 1 人の勝者を推測することと同じではありません。それは、セットプレーで試合が傾き始めた瞬間にどのチームが生き残れるか、どちらのチームが長い道のりでリズムを維持できるか、そしてどのチームが18歳から23歳の選手まで真の競争力を維持できるかを見極める練習だ。ワールドカップの歴史を長く読めば読むほど、そのような状況が早くから目立ち始めます。\n\n2026 年も過去と同じように読んでほしいと思います。チーム名だけを書かないでください。プレス、トランジション、セットプレー、そしてその横にディフェンスラインの安定性を書きます。そうすれば、良い予測は良い記憶から生まれることが理解できるでしょう。';

  @override
  String get educationStoryClosingBody =>
      '結局のところ、テオ、ワールドカップをよく見るということは、最後のスコアを一つ覚えることではありません。これは、1930 年の最初の航海から 2026 年に待つ次の問題までの長い糸をたどる物語です。この物語を読むたびに、数字よりも人間を、結果よりも空気を、そして一試合よりも時代をより鮮明に見ることを学んでいただければと思います。';

  @override
  String get educationHeroEyebrow => 'ユースセッションキット';

  @override
  String get educationHeroTitle => 'すぐに指導できるユースサッカーコンテンツ';

  @override
  String get educationHeroBody =>
      '説明は短く、繰り返しは多く、質問は 1 つで終わります。これら 3 つのセッションは、そのフロー用に構築されています。';

  @override
  String get educationHeroStatLessons => '3 つのレッスンが用意されています';

  @override
  String get educationHeroStatMinutes => '45分の流れ';

  @override
  String get educationHeroStatPrinciples => 'コーチキューが含まれています';

  @override
  String get educationHeroStatHistory => 'クイズ履歴が含まれています';

  @override
  String get educationSectionLessonsTitle => '準備完了のレッスン';

  @override
  String get educationSectionHistoryTitle => 'クイズ歴史学習';

  @override
  String get educationSectionHistoryBody =>
      'これらのカードには、クイズに頻繁に登場する年、競技名、象徴的な瞬間がグループ化されています。 1 枚のカードを確認し、タイムラインがまだ新しいうちにラウンドに直接進みます。';

  @override
  String get educationSectionPrinciplesTitle => 'コーチングの原則';

  @override
  String get educationHistoryWorldCupEyebrow => 'ワールドカップのルーツ';

  @override
  String get educationHistoryWorldCupTitle => 'ワールドカップ財団';

  @override
  String get educationHistoryWorldCupSummary =>
      '1 枚のカードを使用して、最初のトーナメント、トロフィーの変更、ワールドカップの歴史の多くの疑問を構成する見出しの記録を固定します。';

  @override
  String get educationHistoryWorldCupFocus => '年 + ホスト';

  @override
  String get educationHistoryWorldCupFact1 =>
      '1930年にウルグアイで第1回FIFAワールドカップが開催された。';

  @override
  String get educationHistoryWorldCupFact2 =>
      'ジュール リメ トロフィーは 1970 年まで使用され、現在の FIFA ワールドカップ トロフィーは 1974 年から使用されています。';

  @override
  String get educationHistoryWorldCupFact3 =>
      '男子ワールドカップのタイトル獲得数で最も多いのはブラジルであり、ミロスラフ・クローゼは画期的な歴代得点者である。';

  @override
  String get educationHistoryCompetitionEyebrow => 'コンテストのタイムライン';

  @override
  String get educationHistoryCompetitionTitle => 'コンテストの名前と発表';

  @override
  String get educationHistoryCompetitionSummary =>
      'リーグやヨーロッパの大会に関する質問は、発足年と初代チャンピオンまたはブランド変更シーズンを組み合わせると、より簡単になります。';

  @override
  String get educationHistoryCompetitionFocus => 'ローンチ + 初代チャンピオン';

  @override
  String get educationHistoryCompetitionFact1 =>
      'プレミアリーグは1992年に発足し、マンチェスター・ユナイテッドが1992-93年に初代タイトルを獲得した。';

  @override
  String get educationHistoryCompetitionFact2 =>
      'ヨーロピアンカップは1992-93シーズンからUEFAチャンピオンズリーグとして運営を開始した。';

  @override
  String get educationHistoryCompetitionFact3 =>
      'アーセナルの2003-04シーズンのインヴィンシブルズは、プレミアリーグ史上最も多くのアンカーを務めた選手の1人となった。';

  @override
  String get educationHistoryMomentsEyebrow => '象徴的な瞬間';

  @override
  String get educationHistoryMomentsTitle => '象徴的な瞬間と女子サッカー';

  @override
  String get educationHistoryMomentsSummary =>
      '有名なシーンと年と対戦相手の両方を組み合わせて、女子サッカーを独自のタイムラインに保持して、すばやく思い出すことができます。';

  @override
  String get educationHistoryMomentsFocus => '瞬間＋相手';

  @override
  String get educationHistoryMomentsFact1 =>
      'マラドーナの「神の手」は1986年のワールドカップのイングランド戦で起こった。';

  @override
  String get educationHistoryMomentsFact2 =>
      'ジダンの頭突きは、2006 FIFA ワールドカップ決勝の象徴的なシーンです。';

  @override
  String get educationHistoryMomentsFact3 => '1991年に中国で第1回FIFA女子ワールドカップが開催された。';

  @override
  String get educationModuleBallEyebrow => 'ボールマスタリー';

  @override
  String get educationModuleBallTitle => 'タッチ数を増やす';

  @override
  String get educationModuleBallSummary =>
      '両足のインサイドとアウトサイドのタッチとターンを繋ぎ続けるセッションで、若いプレーヤーがボールに慣れることができます。';

  @override
  String get educationModuleBallAge => 'U8-U10';

  @override
  String get educationModuleBallDuration => '12分';

  @override
  String get educationModuleBallCue1 => '足を軽く活動的に保ちながら、時々目を上げましょう。';

  @override
  String get educationModuleBallCue2 => 'スピードを求める前に、ボールが体の近くにあるかどうかを確認してください。';

  @override
  String get educationModuleBallCue3 => 'ミスをした後は、ドリルを止めるのではなく、次のタッチを奨励します。';

  @override
  String get educationModulePassEyebrow => 'ファーストタッチ＆パス';

  @override
  String get educationModulePassTitle => 'ファーストタッチインパス';

  @override
  String get educationModulePassSummary =>
      '受け取って、回して、放す。このセッションでは、タッチの方向とパスの精度を 1 つの流れで結び付けます。';

  @override
  String get educationModulePassAge => 'U10-U12';

  @override
  String get educationModulePassDuration => '15分';

  @override
  String get educationModulePassCue1 => 'プレイヤーに、受信する前に一度肩越しにスキャンするように指示します。';

  @override
  String get educationModulePassCue2 => '次のパスが送られるべきスペースへの最初のタッチを指導します。';

  @override
  String get educationModulePassCue3 => 'より強いペースを求める前に、体の形状と接地面を設定してください。';

  @override
  String get educationModuleDecisionEyebrow => '1対1の判定';

  @override
  String get educationModuleDecisionTitle => '1v1 の突破と選択';

  @override
  String get educationModuleDecisionSummary =>
      '決定セッションは、スピードの変化、ディフェンダーの動きを止めてから、シュートまたはパスで終了することを中心に構築されました。';

  @override
  String get educationModuleDecisionAge => 'U11-U13';

  @override
  String get educationModuleDecisionDuration => '18分';

  @override
  String get educationModuleDecisionCue1 => '最初の一歩を大きく踏み出し、その後の方向転換は短く鋭く保ちます。';

  @override
  String get educationModuleDecisionCue2 => '最終的な結果だけでなく、まずタイミングと準備を褒めます。';

  @override
  String get educationModuleDecisionCue3 =>
      '成功したら、なぜそれがうまくいったのかを短い文でもう一度考えてみましょう。';

  @override
  String get educationPrincipleOneTitle => '一度に 1 つのキュー';

  @override
  String get educationPrincipleOneBody =>
      '指示は短く、実行可能なものにしてください。 「開く」、「スキャン」、「接続」などの単一単語の合図はうまく機能します。';

  @override
  String get educationPrincipleTwoTitle => '間違いの直後に褒め言葉を見つける';

  @override
  String get educationPrincipleTwoBody =>
      '結果だけではなく準備を褒めると、選手たちは立ち止まらずに努力を続けます。';

  @override
  String get educationPrincipleThreeTitle => '最後の 2 分間は質問に使用してください';

  @override
  String get educationPrincipleThreeBody =>
      '今日は何が楽だったか、次回は何を変えたいかを尋ねます。その反省がレッスンを定着させるのに役立ちます。';

  @override
  String get educationBookSectionStory => 'テオのシーン';

  @override
  String get educationBookSectionTimeline => 'コアタイムライン';

  @override
  String get educationBookSectionFacts => 'メモリデータ';

  @override
  String get educationBookSectionNote => 'テオのメモ';

  @override
  String get educationBookSwipeHint =>
      'ページめくりは横スワイプのみです。各章をゆっくりと下にスクロールして読んでください。';

  @override
  String get educationBookPreviousButton => '前の';

  @override
  String get educationBookNextButton => '次';

  @override
  String educationBookProgressLabel(int current, int total) {
    return '$current/$total 章';
  }

  @override
  String get educationBookCoverLabel => 'プロローグ';

  @override
  String get educationBookCoverTitle => '夜に棚からワールドカップを降ろす';

  @override
  String get educationBookCoverSubtitle => 'テオが歴史の本の最初のページを開く方法';

  @override
  String get educationBookCoverStory =>
      'トレーニング後、紙の方がボールよりも重く感じる夜もあります。テオは古いワールドカップ番組の棚に沿って涼しい手を走らせます。ページからはほのかに埃の匂いが漂い、その中にはモンテビデオの港、マラカナンの階段、アステカの陽光、そしてルサイルの磨かれた夜が横たわっている。まるで誰かが季節全体を紙に折りたたんで、後のためにここに置いてきたような気がします。\n\nこの本はサッカーのすべてを解説しようとするものではありません。それはただ一つの川、ワールドカップを追っているだけだ。この物語は 1930 年にウルグアイで始まり、2022 年にカタールを通過し、2026 年の北アメリカの端で停止し、まだ書かれるのを待っています。テオはその抑制が好きです。場合によっては、一度にすべてを保持しようとするよりも、1 つのことを長時間見つめるほうが正確な場合があります。\n\nそこで彼は、1930 年、1950 年、1958 年、1970 年、1986 年、1998 年、2002 年、2010 年、2018 年、2022 年、2026 年を空白のページに書き留めます。年は数字のように見えますが、じっと見つめていると、温度が異なる部屋のように感じられます。ある部屋にはペレの笑顔が保管されています。人はマラカナンの沈黙を守ります。もう一人は、メッシがついに息を吐き出す瞬間を記録している。今夜、テオは各ドアノブを順番に触ることにしました。';

  @override
  String get educationBookCoverTimeline =>
      'FIFA は 1904 年に設立され、後にワールド カップの開催を可能にする管理体制を構築しました。\n1930年にウルグアイで初の男子FIFAワールドカップが開催された。\n1942 年版と 1946 年版は第二次世界大戦のため中止されました。\n1974 年以降、ジュール リメ トロフィーは現在の FIFA ワールドカップ トロフィーに置き換えられました。\n1998 年のフランスでは、決勝戦が 32 チームの形式に拡大されました。\n2018年ロシア大会は、VARが完全に導入された初の男子ワールドカップとなった。\nカナダ、メキシコ、米国は 2026 年に 48 チーム、104 試合のトーナメントを開催する予定です。';

  @override
  String get educationBookCoverFacts =>
      'テオさんのブックマーク 1: 2022 年のカタールまで、男子ワールドカップは 22 回開催されました。\nテオのブックマーク 2: 5 タイトルのブラジル、4 のドイツ、4 のイタリア、3 のアルゼンチンが主なタイトルアンカーです。\nテオのブックマーク 3: ミロスラフ クローゼの 16 ゴールは、依然として男子ワールドカップの歴代得点記録です。\nテオのブックマーク 4: ワールドカップの歴史は、年、開催地、チャンピオン、象徴的なシーン、そして主役が一緒にグループ化されたときに最もよく残ります。';

  @override
  String get educationBookCoverNote =>
      'テオは、この本は単なる勝者のリストではないと書いています。世界が4年ごとにどんな顔を見せたのかを記した記録である。だからこそ、彼は 2022 年に終了した最新のトーナメントと、隣の 2026 年に開幕するトーナメントを並べて記憶することにしたのです。';

  @override
  String get educationBookOriginsLabel => '第1章';

  @override
  String get educationBookOriginsTitle => '船でやって来た初めての夏';

  @override
  String get educationBookOriginsSubtitle =>
      '1930 年ウルグアイ、1934 年イタリア、1938 年フランス';

  @override
  String get educationBookOriginsStory =>
      '最初の章は、飛行機よりも船が重要だった時代から始まります。ヨーロッパのチームは何週間もかけて海を渡りウルグアイに到着し、開催国側は100周年の祝賀の熱気で慌ただしくエスタディオ・センテナリオを終えた。現代の基準からすると、すべてが遅くて不便ですが、その遅さによってトーナメントがよりシャープに見えます。大きなイベントは、少なからず不快感を伴いながらやってくることがよくあります。ワールドカップは最初からそれを分かっていた。\n\n1930年にウルグアイが初代チャンピオンとなり、イタリアが1934年と1938年にタイトルを獲得する中、テオはスコアラインより先に結果の空気を読んでいる自分に気づいた。ムッソリーニの影は一つの大会にまで及ぶ。戦争はまだ始まっていないが、すでにヨーロッパの回廊を静かに歩き始めている。ワールドカップは彼が予想していたよりもはるかに早く世界に似てきました。旅行、政治、ボイコット、審判の議論はすべて同じ表紙に収まります。\n\nこの時代を読んだテオは、ワールドカップが初期の形では決して無実ではなかったことを知ります。海のせいでチームは遅れたが、そのおかげでトーナメントは伝説のようになった。到着までに長い時間がかかるものは、ほとんど忘れられません。そこで彼は、1930 年、1934 年、1938 年を数字としてだけでなく、塩の匂い、スピーチの調子、そして不安な拍手の音として記憶することにしました。';

  @override
  String get educationBookOriginsTimeline =>
      '1930 年のウルグアイ大会には 13 チームしか参加しませんでしたが、開催国が初代チャンピオンとなり、トーナメントの雰囲気を決めました。\n1930年の決勝戦は南米の戦いとして終わり、ウルグアイがアルゼンチンを4対2で破った。\n1934 年のイタリア大会は、決勝戦の前に完全に開発された予選パスが適用された最初のワールドカップでした。\nウルグアイは多くのヨーロッパチームが1930年大会から参加しなかったことに抗議して1934年の大会を欠場した。\nヴィットリオ・ポッツォ監督の下、イタリアは1934年と1938年に連覇を達成した。\n1938 年のフランス大会では、オランダ東インドがアジアのチームとして初めて男子ワールドカップ決勝に出場しました。';

  @override
  String get educationBookOriginsFacts =>
      'ジュール・リメはトーナメントの存続を推進した中央管理者であり、後にオリジナルのトロフィーに彼の名前を与えました。\nヴィットリオ・ポッツォは依然として男子ワールドカップで連覇を達成した唯一の監督である。\nヨーロッパと南米の間の長い移動距離は、現代のファンがよく予想するよりも参加を大きく左右しました。\nテオは 1930 年、1934 年、1938 年を最初のトーナメント、最初の完全予選時代、そして最初の連続タイトルランとして記録しました。';

  @override
  String get educationBookOriginsNote =>
      'Taeo は 1930 年、1934 年、1938 年を 1 つのクラスターとして保持します。最初のトーナメント、最初の予選時代、そして最初のリピートチャンピオンがすべて揃って到着しました。ワールドカップは最初からすでにサッカー以上のものでした。';

  @override
  String get educationBookWorldCupLabel => '第2章';

  @override
  String get educationBookWorldCupTitle => '同じスタジアムで静寂と祝賀がどのように保たれるか';

  @override
  String get educationBookWorldCupSubtitle => '1950 年のブラジルから 1970 年のメキシコまで';

  @override
  String get educationBookWorldCupStory =>
      '空白の2夏が戦争に敗れた後、1950年にブラジルでワールドカップが再開されたとき、人々はおそらく最初に祝賀会を期待しただろう。しかし、テオが最初に出会った光景は沈黙だった。マラカナンでの決戦でウルグアイがブラジルに勝利したことは、一つの結果が国全体の規模を変えることができることを彼に示した。その時点から、ワールドカップはスポーツイベントというよりも、集団の記憶を作るためのマシンのように見えます。\n\nその後に続くページは、驚くべきスピードで伝説へと変わっていきます。 1954年のベルンの奇跡。1958年に到着した17歳のペレ。1962年にガリンシャが背負ったブラジル。1966年イングランドの唯一のタイトル。1970年のメキシコでの黄金のブラジル。テオが読めば読むほど、歴史書は生き続けるために顔や動きを借用していることが明らかになる。誰かが倒れます。誰かが現れます。誰かが非常に完成され、発明されたように見え始めます。\n\nそこでテオは、1950 年から 1970 年までを、再起動、衝撃、誕生、復讐、完了という 5 つの単語にまとめます。片手に収まるくらいの小さな紙に。しかし、その言葉の中にある感情は、それによって萎縮することはありません。マラカナンの沈黙とペレの微笑みは、それぞれ異なる方向を向いて、非常に長い間残り続けます。';

  @override
  String get educationBookWorldCupTimeline =>
      '1950年のブラジル大会では1試合決勝ではなく最終グループ制が採用され、ウルグアイのブラジルに対する勝利はマラカナンショックとなった。\n1954年に西ドイツが強豪ハンガリーを破り、ベルンの奇跡を起こした。\n1958 年のスウェーデン大会では、17 歳のペレがこの競技界で最も輝かしい新星として浮上しました。\nブラジルは1962年のチリ戦でガリンシャが重要な試合でチームを牽引し、トロフィーを保持した。\nイングランドは1966年の男子ワールドカップで唯一優勝し、決勝ではジェフ・ハーストが有名なハットトリックを達成した。\n1970年のメキシコ大会でブラジルは3度目のタイトルを獲得し、ジュール・リメ・トロフィーの永久所有権を獲得した。\n1970 年の決勝戦でのカルロス アルベルトのゴールは、今でもチーム フットボールの象徴として再生され続けています。';

  @override
  String get educationBookWorldCupFacts =>
      'ハンガリーは多くの人が世界最強とみなしていたチームとして、1954年の決勝に進出した。\nジャイルジーニョは、1970年のタイトル獲得に向けてブラジルが出場したすべての試合でゴールを決めた。\nペレのヘディングシュートからのゴードン・バンクスのセーブは今でも多くの人から世紀のセーブとして評価されている。\nテオは、1950 年のマラカナン ショック、1958 年のペレの出現、1970 年のブラジルの傑作をまとめています。';

  @override
  String get educationBookWorldCupNote =>
      'テオ氏は、1950年から1970年までのワールドカップは戦後の復帰式典であると同時に、新たな天才を紹介する世界最大の舞台でもあったと書いている。';

  @override
  String get educationBookClubLabel => '第3章';

  @override
  String get educationBookClubTitle => '美と不快が共存する時代';

  @override
  String get educationBookClubSubtitle => '1974 年の西ドイツから 1990 年のイタリアまで';

  @override
  String get educationBookClubStory =>
      '1974年になると、本の中の空気が変わります。トロフィーも変わります。オランダはトータルフットボールでピッチの座標を揺るがし、西ドイツは最終的にその美しい混沌を結果として整理する。テオはこの章を読むたびに、サッカーは理想主義と現実が公の場で衝突する数少ない場所の一つだと思う。グレースは愛されやすいですが、トロフィーは通常、より重いものに傾いています。\n\nしかし、この時代は戦術だけでは説明できません。 1978 年のアルゼンチンには軍事政権の寒さが漂っています。 1982年、バティストンの転倒による涙が試合そのものの時間を切り開いた。 1986年のマラドーナは選手というよりは気象システムのように見える。神の手と5人抜きのゴールは同じ夏に起こり、この矛盾はワールドカップの様相をより鮮明にするだけだ。\n\nテオは 1990 年に達する頃には、時代が必ずしも整った文章で終わるわけではないことを理解しています。ロジャー・ミラのダンス、ベッケンバウアーの指導者としての肩書、そしてマラドーナの涙は温度が異なるままだ。歴史は完璧に整えられるよりも、少しだけ混ざり合ったほうが長く続きます。そこで彼は、このストレッチを、美しさ、不快さ、才能、議論という 4 つの単語で緩く結び付けています。';

  @override
  String get educationBookClubTimeline =>
      '1974 年の西ドイツ大会は、現在の FIFA ワールドカップ トロフィーを授与された最初の大会でした。\nクライフのターンとオランダのトータルフットボールは、最終結果を超えて残るイメージを残した。\nアルゼンチンは 1978 年に初のタイトルを獲得しましたが、トーナメントは依然として軍事政権の政治情勢と結びついています。\n1982年のスペイン大会は24チームによる初の男子ワールドカップとなった。\n1982年の準決勝のフランス対西ドイツ戦は、ワールドカップで初めてPK戦で決着がついた試合であり、シューマッハとバティストンの衝突でも記憶されている。\nマラドーナの1986年のイングランド戦でのパフォーマンスは、サッカー界に神の手と世紀のゴールの両方をもたらした。\nカメルーンは1990年に準々決勝に進出し、男子ワールドカップで準々決勝に進出した最初のアフリカチームとなった。';

  @override
  String get educationBookClubFacts =>
      'フランツ・ベッケンバウアーは、1974年に選手として、1990年にコーチとしてワールドカップで優勝したため、決定的なシンボルとして立っています。\nパオロ・ロッシは出場停止から復帰し、1982年のイタリアタイトルの顔となった。\n1990 年のイタリアは、守備の傾向がその後のルール議論を促進した大会としてよく引用されます。\nテオ氏は、1974年、1978年、1982年、1986年、1990年を、美しさと不快さの両方を残したワールドカップの年として分類する。';

  @override
  String get educationBookClubNote =>
      'テオは、この時期はワールドカップがきれいで美しい物語だけを残さないことを証明していると書いている。それが長続きする理由でもあります。歴史は、何が人々を不快にさせたのか、何が人々を歓喜させたのかを記憶しなければなりません。';

  @override
  String get educationBookTacticsLabel => '第4章';

  @override
  String get educationBookTacticsTitle => 'ワールドカップがテレビからリビングルームに伝わったとき';

  @override
  String get educationBookTacticsSubtitle =>
      '米国 1994 年、フランス 1998 年、韓国と日本 2002 年、ドイツ 2006 年';

  @override
  String get educationBookTacticsStory =>
      'USA 1994 までに、テオはトーナメントがまったく異なる規模になっていると見ています。巨大なスタジアム、広告ボードの明るさ、テレビ画面を通して広がる熱気、空に舞い上がるバッジョのキックはすべて同じ記憶に定着する。ワールドカップはもはや、他国での遠いお祭りのようには感じられません。リビングの真ん中に突然大きな家具が置かれたような感じです。気づかずに通り過ぎる人はいません。\n\n1998年のジダン率いるフランス戦、2002年の韓国の準決勝進出とロナウドの挽回、2006年の決勝でのジダンの頭突きなどを経験していくうちに、テオはこれらの大会が異常にリプレイしやすいと感じ始める。強烈なシーンは繰り返しやすく、繰り返されたシーンは世代を超えて共有される記憶になります。彼にとって 2002 年は決して他人事ではありません。近くの通りでの叫び声、テレビの下の空き缶、そして試合終了のホイッスルが鳴った後、静まるまでに長い時間を要した夜の空気。\n\nそう見ると、ワールドカップは常にスコアラインよりわずかに広いです。トーナメントの中には、誰が得点したかよりも、どんな夜になったかが記憶に残るものもあります。テオは 1994 年、1998 年、2002 年、2006 年のことを考えるとき、数字を思い出す前に、顔、騒音、カメラ アングルを思い出します。おそらく、現代の歴史の本はそのように書かれているのでしょう。';

  @override
  String get educationBookTacticsTimeline =>
      '1994年の決勝は、PK戦で決着した初めての男子ワールドカップ決勝となった。\n1994年のロベルト・バッジョのミスはワールドカップ史上最も有名な映像の一つとなった。\n1998 年のフランスでは、32 チームによる決勝戦形式が始まりました。\nローラン・ブランは1998年フランス大会でワールドカップ史上初の金ゴールを決めた。\n2002 年には日韓両国が男子ワールドカップの初の共同開催国となり、韓国は準決勝に進出した。\nロナウドは2002年に8得点を挙げ、1998年の決勝の痛みを救いの物語に変えた。\n2006年のドイツ大会は決勝でジダンのレッドカードで終わり、イタリアが優勝した。';

  @override
  String get educationBookTacticsFacts =>
      'ヒディンク、スコラーリ、リッピなどの名前は、選手たちと同じくらいこの時代の記憶に強く残っている。\nクロアチアのダヴォル・シュケル選手は1998年にゴールデンブーツ賞を獲得し、チームは3位に急上昇した。\n2002年のセネガルの準々決勝進出とトルコの準決勝進出は、ワールドカップが決して巨人だけによって動かされるわけではないことを改めて示した。\nテオは、1994年、1998年、2002年、2006年が生き続けるためには、最後のシーンを通して思い出されなければならないと書いています。';

  @override
  String get educationBookTacticsNote =>
      'テオは、2002 年の章に特に長く残ります。韓国のファンにとって、ワールドカップの歴史は遠い時間軸ではありません。それは心に直接触れる思い出のラインです。だからこそ、彼はリザルトシートだけでなく、その周囲の雰囲気や音も覚えておくことにしたのです。';

  @override
  String get educationBookLegendsLabel => '第5章';

  @override
  String get educationBookLegendsTitle => '数字が多ければ多いほど、シーンはより鮮明になります';

  @override
  String get educationBookLegendsSubtitle => '2010 年の南アフリカから 2022 年のカタールまで';

  @override
  String get educationBookLegendsStory =>
      'テオが南アフリカ 2010 のオープニングを飾るとき、彼は最初にブブゼラを聞きました。いくつかのトーナメントは、目よりも耳を通して記憶されます。スペインのタイトル、スアレスのハンドボールの危機、ガーナの退場、そしてタコのポールの奇妙な名声は、同じ月の中に異なる種類の真剣さが存在し得ることを彼に示した。ワールドカップは歴史の本であることに変わりはありませんが、噂、ジョーク、集団的な執着の保管庫でもあります。\n\n2014年にブラジルが7-1で大敗し、2018年にVARが完全に導入され、2022年にカタールでの決勝に至るまでに、テオは、数字が増えても物語は曖昧ではないと感じ始める。代わりに彼らはシーンを鮮明にします。クローゼの16点目、ムバッペの加速、メッシのキャリアに欠けていた最後のピース、そしてモロッコの準決勝進出はすべて、さまざまな角度から歴史を押し上げている。データは物事を説明するのに役立ちますが、身体に残るのは決してデータだけではありません。\n\nテオは最近のワールドカップを読むたびに、同じ結論に戻ります。人はテーブルよりも長くシーンを覚えています。 7-1のスコアボード。 VARモニターの前の静寂。延長戦終了後、メッシが頭を下げる一瞬。記録は棚に保管されています。情景が体の内側にこびりつきます。';

  @override
  String get educationBookLegendsTimeline =>
      '2010 年南アフリカ大会はアフリカ大陸で初めて開催された男子ワールドカップでした。\nスペインは2010年ワールドカップ決勝でイニエスタの延長戦ゴールで初優勝を果たした。\n2010年のガーナ戦でのスアレスのハンドボールは、ワールドカップの記憶に残る最も熱い口論シーンの一つとなった。\nドイツは2014年の準決勝でブラジルを7対1で破り、そのまま優勝を果たした。\n2014年のブラジル戦でのクローゼのゴールは、男子ワールドカップの歴代得点記録を16に更新した。\n2018年ロシア大会は、大会を通じてVARが全面的に使用された初の男子ワールドカップとなった。\n2022年のカタールではモロッコが準決勝に進出し、アルゼンチンはメッシを中心に勝利した。';

  @override
  String get educationBookLegendsFacts =>
      'タコのポールは、何度も試合結果を的中させたことで、2010 年に予言のアイコンとなりました。\nキリアン・ムバッペの2018年のタイトルと2022年の決勝ハットトリックは、ペレ以来最強の若いワールドカップの物語を築き上げた。\nリオネル・メッシは2022年をワールドカップのキャリアにおける最後の空白を埋めるために利用した。\nテオは音、崩壊、テクノロジー、青春、完成という5つの感情を通して2010年、2014年、2018年、2022年を思い出します。';

  @override
  String get educationBookLegendsNote =>
      'テオ氏は、最もデータ量の多いワールドカップであっても、人々は依然としてシーンを最初に覚えていると書いています。ブブゼラ、7-1 のスコアボード、VAR チェック、そしてメッシの笑顔は、どのスプレッドシートよりも長く残ります。';

  @override
  String get educationBookAsiaLabel => '第6章';

  @override
  String get educationBookAsiaTitle => '何年も前に顔が思い浮かぶ瞬間';

  @override
  String get educationBookAsiaSubtitle => 'ジュール・リメからペレ、マラドーナ、ベッケンバウアー、メッシまで';

  @override
  String get educationBookAsiaStory =>
      'ある時点で、テオは何年もかけてワールドカップを思い出す前に、顔を通してワールドカップを覚え始めます。ジュール・リメ氏はトーナメントの実現に貢献してくれました。連続タイトルを形作ったポッツォ。 3度頂点に立ったペレ。選手の門も監督の門もくぐり抜けたベッケンバウアー。ひと夏を神話に変えたマラドーナ。一つ一つ読んでいくと、これらの名前は歴史に驚くほど個人的な表現を与えてくれます。大規模なトーナメントであっても、結局は数人の息遣いでまとめられてしまうこともあります。\n\nこの章の図はどれも完成していません。ガリンシャは負傷したチームを背負っている。ロナウドは、決勝戦で敗れた記憶を4年後に裏返す。ジダンは天才性と破壊力の両方を残した。メッシは最後だけ自分の言葉を終える。だからテオは、ワールドカップは実際には何もないところからヒーローを生み出す場所ではないと感じています。すでに震えていた人々の輪郭を拡大する場所です。\n\n彼は名前の横に必ず年と場面を書きます。ペレは 1958 年と 1970 年を意味します。マラドーナは 1986 年を意味します。ロナウドは 2002 年を意味します。メッシは 2022 年を意味します。名前だけでは試験ノートのように感じます。シーンを追加すると、突然物語になります。おそらく歴史書はその形でしか生き残らないのでしょう。';

  @override
  String get educationBookAsiaTimeline =>
      'ジュール・リメは、このコンクールに初期の政治的動機と最初のトロフィーの名前を与えました。\nヴィットリオ・ポッツォは1934年と1938年にイタリアを連覇させた。\nペレは 1958 年、1962 年、1970 年に男子ワールドカップで優勝しており、これは他の男子選手が達成できない記録です。\nフランツ・ベッケンバウアーは1974年に選手として、1990年にコーチとしてトロフィーを獲得した。\n1986年のマラドーナのキャンペーンは、それだけでワールドカップ神話の大部分を説明できるほど大きなものである。\n2002 年のロナウドの 8 ゴールは、1998 年の痛みをサッカー史上最もクリーンな償いの一つに変えました。\nメッシとムバッペは、2022年の決勝を利用して、世代の通過と世代の衝突の両方を同時に示した。';

  @override
  String get educationBookAsiaFacts =>
      'フォンテーヌの 13 ゴールだけが、ワールドカップ 1 大会における史上最高記録として残っています。\nミロスラフ・クローゼの16ゴールは、複数の大会を通じた男子ワールドカップの歴代最多得点記録であり続けている。\nマリオ・ザガロ、フランツ・ベッケンバウアー、ディディエ・デシャンは、選手としても監督としてもワールドカップで優勝した象徴的な人物の一人です。\nTaeo は、名前、国、トーナメントの定義、シーンの定義を組み合わせて、各図を 1 行に記録します。';

  @override
  String get educationBookAsiaNote =>
      'テオは、ワールドカップを思い出す最も早い方法は、人を通して思い出すことだと判断しました。何年も続くと、まるで試練のように感じます。顔とシーンがそれを物語に変えます。';

  @override
  String get educationBookWomenLabel => '第7章';

  @override
  String get educationBookWomenTitle => 'スタジアムの外の空気も読む方法';

  @override
  String get educationBookWomenSubtitle => '戦争、政治、窃盗、そして判断の技術';

  @override
  String get educationBookWomenStory =>
      'ある時点でテオは、チャンピオンだけを列挙する歴史書は少し失礼だと判断しました。ワールドカップがスタジアム内だけで起こったことは一度もありません。戦争により完全に消滅したトーナメントもありました。独裁政権下でプレイされたものもあった。サッカーそのものだけでなく、ピッチ外の出来事でも記憶に残っている人もいます。広い世界の空気が常に芝生に染み出ています。\n\n1966年にジュール・リメ・トロフィーが盗まれ、ピクルスと呼ばれる犬がそれを回収した事件は、現実とは思えないほど奇妙だ。 1982年のバティストンの転倒、2010年のランパードの取り消しゴール、2014年のゴールラインテクノロジー、2018年のVAR、そして2022年の半自動オフサイドは、サッカーが人間の判断における不完全さとどれだけ長く格闘してきたかを示している。スポーツは常に、完全に公平になることは不可能であることを承知しながら、より公平になることを望んでいます。\n\nそこで、テオはすべてのトーナメントの横に 2 つの質問を書きます。誰が勝ったのか。そして何が変わったのか。これらの文を組み合わせると、出来事の概要がより明確になります。歴史はスコアボードで終わるわけではありません。背後にある空気と合わせて読まなければなりません。';

  @override
  String get educationBookWomenTimeline =>
      '1942年と1946年の中止は、世界大戦がサッカーの最も壮大なカレンダーさえも中止する可能性があることを示した。\n1966 年のイングランド大会が始まる前に、ジュール リメ トロフィーが盗まれ、ピクルスという名前の犬によって発見されました。\n1978 年のアルゼンチンは依然として軍事政権の政治的圧力と結びついています。\n1982年の準決勝でのシューマッハとバティストンの衝突は、スポーツマンシップと審判に関する議論を拡大させた。\n2010年のドイツ戦でのフランク・ランパードのゴールが取り消されたことにより、技術的見直しの主張はさらに大きくなった。\nゴールラインテクノロジーはブラジル2014で使用されました。\n2018年にVARが導入され、2022年には半自動オフサイドが導入され、エリート審判の様子が再び変わった。';

  @override
  String get educationBookWomenFacts =>
      'ピクルスは、ワールドカップのトロフィーの回収に貢献した後、サッカー史上最も有名な犬になりました。\nテクノロジーがワールドカップの論争を消すわけではない。それは人々が議論する論争の種類を変えます。\n政治や社会情勢は、主催者の記憶、観客の感情、そしてトーナメントの記憶の仕方を変えます。\nテオは歴史上の出来事を研究するとき、常にスコアラインの横に社会的背景を書きます。';

  @override
  String get educationBookWomenNote =>
      'テオ氏は、ワールドカップは最大のサッカートーナメントだけではないと書いています。時代の政治、テクノロジー、公平性の議論が一度に集まる場所でもあります。だからこそ、彼はフィールド外の話を脚注として扱うことを拒否している。';

  @override
  String get educationBookModernLabel => '第8章';

  @override
  String get educationBookModernTitle => '次のトーナメントを待つ間に書き留めておく価値のあること';

  @override
  String get educationBookModernSubtitle => '2026年北米に向けたテオのメモ';

  @override
  String get educationBookModernStory =>
      'さて、本はまだ開催されていないトーナメントに向かってゆっくりと歩きます。 2026 年の北米はすでに別の表情をしています。48 チーム、104 試合、3 つの開催国です。テオがこれらの数字を見たとき、彼は本命ではなく、移動距離、回復時間、そしてベンチの呼吸を最初に考えます。トーナメントが長くなるにつれて、1 つのスターではなく、全体的な忍耐力に依存するようです。\n\nそのため、この章は預言よりも観察に近いと感じられます。どのチームが不慣れな相手を素早く解読できるか。セットプレーで試合が傾き始めた数分間、どのチームが生き残ることができるか。どのチームが長い道のりでもリズムを維持できるか。テオは、強い側の条件は通常、華やかな文章よりも退屈な詳細から生まれると信じています。不思議なことに、歴史は彼と一致することが多い。\n\nまだ開催されていないトーナメントについてあまり大声で話すのは危険だと感じます。未来は通常、予想よりも無味乾燥な形で到来し、予測は外れることがよくあります。それでも、テオは数ページを空白にしてしまいます。彼は、歴史書の最後の美点は常に次の文のためにスペースを確保していることだと考えています。';

  @override
  String get educationBookModernTimeline =>
      '2026年のワールドカップは、カナダ、メキシコ、米国が共催する初めての男子大会となる。\n2026年以降、男子ワールドカップ決勝の参加チームは48チームに拡大される。\n48 チームのフォーマットでは 104 試合が行われることになり、スケジュールとローテーションが戦略的にさらに重視されます。\n長距離の移動ルートと気候変動は、これまでの多くの版よりも重要になる可能性があります。\nセットプレー、ベンチスコアリング、分析準備のスピードは、イベントが長くなればなるほど価値が高まるはずだ。\nテオは、2026 年を単に勝者を探すのではなく、強さの条件を探すものとして扱うことにしました。';

  @override
  String get educationBookModernFacts =>
      'トーナメントが長くなるにつれて、スターター 11 人とともに 18 人から 23 人までの選手の実際の競技レベルがより重要になります。\n48 チームのフィールドでは、アジア、アフリカ、コンカフからのサプライズの可能性も高まります。\n伝統的な巨人は依然として最大のベースラインを持っていますが、可能なひねりの数はフォーマットとともに増加する可能性があります。\nテオは予想を書くとき、チーム名の横にプレッシング、トランジション、セットプレー、守備の安定性を追加します。';

  @override
  String get educationBookModernNote =>
      'テオ氏は、予測は幸運を当てるゲームではないと書いています。強いチームの状況を読む練習です。だからこそ、彼は名前そのものよりも、なぜそのチームが強力に見えるのかについて詳しく書いている。';

  @override
  String get educationBookFinaleLabel => 'エピローグ';

  @override
  String get educationBookFinaleTitle => '最後のページが閉じるのがいつも少し遅い';

  @override
  String get educationBookFinaleSubtitle => '1930年と2026年を一本の線で結ぶエピローグ';

  @override
  String get educationBookFinaleStory =>
      '最後のページまでに、テオはワールドカップが実際には 4 年に 1 度発行される非常に分厚い雑誌であると考え始めます。時代は移り変わりますが、表紙のタイトルは変わらず、その中にその時の空気、顔、主張が凝縮されています。ウルグアイに渡った選手たちも、今日カメラやセンサーの下を走っている選手たちも、結局は同じ背骨の上で休むことになる。それは少し奇妙に感じますが、まさにその通りでもあります。\n\nペレ、マラドーナ、メッシなどの名前が残っている年もある。マラカナンショックや7-1などのスコアのせいで残る人もいる。戦争、独裁政権、または判断技術のせいで残っている人もいます。そこでテオは、ワールドカップを読むことはサッカーを暗記することではないと判断しました。それは時間の流れに沿って手を動かすことに近いです。ひとつの試合の背後に時代が折り畳まれていることに気づくと、スコアさえも重みを持ち始める。\n\n本を閉じる前に、1930年、1950年、1958年、1970年、1986年、1998年、2002年、2010年、2018年、2022年、2026年をもう一度読みます。今では、冷たいデーツのように聞こえなくなりました。異なる照明の下では部屋の名前のように聞こえます。いくつかの部屋はすでに彼の後ろにあります。 1つはまだオープン寸前です。だからこそ歴史書が重要なのだとテオさんは考えている。その間の空間をゆっくりと歩くことができます。';

  @override
  String get educationBookFinaleTimeline =>
      'テオはワールドカップ初期の大会から、この大会がいかに急速に世界史の中心に躍り出たかを学びました。\nテオは戦後の時代から、一つの試合が国民の記憶になり得ることを学んだ。\nテオ氏は最近のトーナメントから、データが多用される時代であっても、人々は依然としてシーンと顔を最初に覚えていることを学びました。\nテオは 2026 年のプレビューから、未来を読むには過去のパターンを見ることから始まることを学びました。';

  @override
  String get educationBookFinaleFacts =>
      'アンカー 1 を確認する: 年、主催者、チャンピオン、象徴的なシーン、主要人物を 1 行に結び付けます。\nレビューアンカー 2: 1930 年、1950 年、1970 年、1986 年、1998 年、2002 年、2018 年、2022 年は交渉の余地のないレビュー年です。\nアンカー 3 を確認する: ペレの 3 回のタイトル、ブラジルの 5 回のタイトル、クローゼの 16 ゴールなどの代表的な数字に記録を結びつけます。\nアンカー 4 を確認する: チーム名の横に戦術、フィットネス、チームの層の厚さが書かれていると、予測がより強力になります。';

  @override
  String get educationBookFinaleNote =>
      '本を閉じるとき、テオは次の日記の最初の行をこのように書きます。ワールドカップを本当によく見るということは、決勝スコアを 1 つだけ暗記することではなく、1930 年の最初のキックから 2026 年に待つ次の問題までの長い物語全体を追うことです。';

  @override
  String get familySharing => '親モード/プレーヤー共有';

  @override
  String get familySharedBackupDescription =>
      'サーバーなしで 1 つの共有ドライブのバックアップを使用します。プレーヤー モードはコア レコードを直接管理しますが、親モードはフィードバックと報酬名のみを同期します。';

  @override
  String get familyBackupIncludesMedia =>
      'プロフィール写真やトレーニング写真のファイルをローカルに収集できる場合は、それらの写真もバックアップします。';

  @override
  String get familyParentAutoSyncDescription =>
      '親モードでは、トレーニングのフィードバックと報酬名のみが自動的に同期されます。プレーヤー モードからプレーヤー レコードをバックアップおよび復元します。';

  @override
  String get familyChildDriveConnectionTitle => '共有バックアップドライブを接続する';

  @override
  String get familyChildDriveConnectionDescription =>
      '親モードでは、プレーヤーのソース データを保持する Google ドライブ アカウントに接続し、両方のモードで同じバックアップ ファイルを共有できるようにします。';

  @override
  String get familyConnectChildDrive => '共有ドライブを接続する';

  @override
  String get familyDisconnectChildDrive => '共有ドライブを切断する';

  @override
  String get familyRoleChild => 'プレーヤー';

  @override
  String get familyRolePlayer => 'プレーヤー';

  @override
  String get familyRoleParent => '親';

  @override
  String get familyRoleCoach => '親';

  @override
  String get familyRoleSelectionTitle => '使用モードの選択';

  @override
  String get familyRoleSelectionDescription =>
      'このデバイスをプレーヤーが直接使用するか、最初にレビューのために保護者が使用するかを選択します。';

  @override
  String get settingsUsageModeTitle => '使用モード';

  @override
  String get settingsRoleAndSyncTitle => '使用法と同期';

  @override
  String get settingsInfoTooltip => '説明を表示';

  @override
  String get settingsSupportModeLabel => '親';

  @override
  String get settingsSupportRoleTitle => '親モードの詳細';

  @override
  String get settingsDriveConnectionTitle => 'Googleドライブ接続';

  @override
  String get settingsDriveConnectionPlayerSummary =>
      'このデバイスの記録を保存およびインポートしている Google ドライブ アカウントを確認してください。';

  @override
  String get settingsDriveConnectionSupportSummary =>
      '現在接続されているGoogleドライブアカウントを確認してください。';

  @override
  String get settingsDataSyncTitle => 'データ同期';

  @override
  String get settingsDataSyncPlayerSummary =>
      '現在のデータとドライブのバックアップの間の鮮度を確認し、ドライブのアクションを実行します。';

  @override
  String get settingsDataSyncSupportSummary =>
      '最新のバックアップをインポートし、共有された変更を同じファイルに書き込みます。';

  @override
  String get settingsSyncSourceStatusTitle => 'バックアップデータ';

  @override
  String get settingsSyncStatusTitle => 'データ同期ステータス';

  @override
  String get settingsSyncShowDetails => '詳細を表示';

  @override
  String get settingsSyncHideDetails => '詳細を隠す';

  @override
  String get settingsSyncGoogleConnected => 'Google が接続しました';

  @override
  String get settingsSyncGoogleDisconnected => 'Google が切断されました';

  @override
  String get settingsSyncDailyOn => '毎日のバックアップがオン';

  @override
  String get settingsSyncDailyOff => '毎日のバックアップがオフになっている';

  @override
  String get settingsSyncOnSaveOn => '保存時にバックアップ';

  @override
  String get settingsSyncOnSaveOff => 'セーブオフ時のバックアップ';

  @override
  String settingsSyncBackedUpDataTime(Object time) {
    return 'バックアップデータ：$time';
  }

  @override
  String settingsSyncCurrentDataSnapshot(Object time) {
    return '現在のデータのスナップショット: $time';
  }

  @override
  String get settingsSyncStatusChecking => 'チェック中';

  @override
  String get settingsSyncBackupDataReady => 'バックアップソースが見つかりました。';

  @override
  String get settingsSyncStatusSignInNeeded => '接続する';

  @override
  String get settingsSyncStatusNoBackup => 'バックアップなし';

  @override
  String get settingsSyncStatusCurrent => '最近のバックアップ';

  @override
  String get settingsSyncStatusReview => 'バックアップを確認する';

  @override
  String get settingsSyncStatusStale => 'バックアップが古い';

  @override
  String get settingsSyncSummaryChecking => 'ドライブのバックアップステータスを確認しています。';

  @override
  String get settingsSyncSummarySignInNeeded =>
      'アカウントを接続して、このデバイスをドライブ バックアップと比較し、インポートまたはバックアップ アクションを実行します。';

  @override
  String get settingsSyncSummaryNoBackup =>
      'ドライブのバックアップ ファイルはまだ存在しません。まず、「データのバックアップ」を使用して現在のデータを保存します。';

  @override
  String settingsSyncSummaryCurrent(Object time) {
    return 'ドライブのバックアップは $time 頃に作成されました。データを置き換えたり上書きしたりする前に、この時間を確認してください。';
  }

  @override
  String settingsSyncSummaryStale(Object time) {
    return 'ドライブのバックアップは $time からのものです。それ以降に行われた変更はまだバックアップされていない可能性があります。';
  }

  @override
  String settingsDriveActionFilePath(Object path) {
    return 'ファイルパス: $path';
  }

  @override
  String settingsDriveActionBackupTime(Object time) {
    return 'バックアップの保存場所: $time';
  }

  @override
  String get settingsDriveActionBackupTimeUnknown =>
      'バックアップ保存時間: このデバイスではまだ利用できません。';

  @override
  String get settingsDriveConnectAction => 'Googleドライブに接続する';

  @override
  String get settingsDriveDisconnectAction => 'Googleドライブを切断する';

  @override
  String get settingsRestoreLatestActionTitle => '最新データをインポートする';

  @override
  String get settingsBackupDataActionTitle => 'データのバックアップ';

  @override
  String get settingsRoleAccountSummary => '最初にこのデバイス使用モードを選択します。';

  @override
  String get settingsRoleAccountTitle => '利用モードとアカウント';

  @override
  String get settingsRoleAccountDescription =>
      '最初にこのデバイスの使用方法を選択します。以下のアカウント接続は、そのモードに合わせて変更されます。';

  @override
  String get settingsRoleAccountUnavailable =>
      'このビルドでは Google ドライブ アカウントの接続は利用できません。';

  @override
  String get settingsRolePlayerDescription =>
      'プレーヤーモードでトレーニング、食事、スケッチ、XP、バックアップを記録します。';

  @override
  String get settingsRoleParentDescription =>
      'コアレコードを編集せずに、プレーヤーのレコードを読み取り、フィードバックや報酬の名前を管理します。';

  @override
  String get settingsRoleCoachDescription =>
      'トレーニングに焦点を当てたフィードバックを共有して、親モードでプレーヤーの記録とスケッチを確認します。';

  @override
  String get settingsRoleActionTitle => 'モードベースのアクション';

  @override
  String get settingsPlayerActionSummary =>
      'プレーヤー モードでは、最初にバックアップを使用して新しいレコードを保護し、古いデータを復元する必要がある場合にのみ、以下のインポート アクションを使用します。';

  @override
  String get settingsSupportActionSummary =>
      '親モードでは、ここでは新しいソース バックアップは作成されません。代わりに、プレーヤー データをインポートするか、最後のインポート前に保存された状態にロールバックします。';

  @override
  String get settingsPlayerAccountTitle => 'バックアップ ドライブ アカウントを記録する';

  @override
  String get settingsPlayerAccountDescription =>
      'このデバイスのトレーニング記録のバックアップとインポートに使用する Google ドライブ アカウントを接続します。';

  @override
  String get settingsPlayerBackupActionBody =>
      '現在のデバイスのレコードを最新の Google ドライブのバックアップとして保存します。新しいエントリを保護する場合は、最初にこれを使用します。';

  @override
  String get settingsPlayerRestoreDriveActionTitle => '最新データをインポートする';

  @override
  String get settingsPlayerRestoreDriveActionBody =>
      '現在のデバイスのデータを、Google ドライブに保存されている最新のバックアップに置き換えます。';

  @override
  String get settingsPlayerRestoreLocalActionTitle => '最新のインポートを元に戻す';

  @override
  String get settingsPlayerRestoreLocalActionBody =>
      'このデバイスを、最新のインポートによって変更される前の状態に戻します。';

  @override
  String get settingsSupportRestoreDriveActionTitle => '最新のプレイヤーデータをインポートする';

  @override
  String get settingsSupportRestoreDriveActionBody =>
      'プレーヤー モードで保存された最新の Google ドライブ バックアップをこのデバイスにプルします。';

  @override
  String get settingsSupportRestoreLocalActionTitle => '最新のインポートを元に戻す';

  @override
  String get settingsSupportRestoreLocalActionBody =>
      'このデバイスにインポートされた最新のプレーヤー データの変更を以前の状態に戻します。';

  @override
  String get settingsSupportBackupConfirm =>
      '親モードのフィードバックとレベル報酬名をプレーヤーのソース ドライブのバックアップにバックアップしますか?';

  @override
  String get settingsSupportBackupSuccess =>
      '共有された変更は、プレーヤーのソース ドライブにバックアップされました。';

  @override
  String get settingsSupportBackupFailed =>
      '共有された変更をバックアップできませんでした。このドライブ アカウントにプレーヤー モードのバックアップが既に存在することを確認してください。';

  @override
  String get settingsRestoreRollbackTitle => 'インポートのロールバック';

  @override
  String get settingsRestoreRollbackBody =>
      'これは、このデバイスでの最後のインポートを元に戻すための高度なリカバリであり、通常のバックアップ アクションではありません。';

  @override
  String familyRoleActivated(Object role) {
    return '$role モードが有効になりました。';
  }

  @override
  String get familyParentModeEnabled => '親モードを有効にする';

  @override
  String get familyParentModeDescription =>
      '親モードではこれをオンにします。プレーヤーモードに戻るにはオフにします。';

  @override
  String get familyChildName => 'プレイヤー名';

  @override
  String get familyParentName => '親の名前';

  @override
  String get familyChildNameEmpty => 'プレイヤー名を設定します';

  @override
  String get familyParentNameEmpty => '親の名前を設定します';

  @override
  String get familyEditNames => '姓を編集する';

  @override
  String get familyPolicyTitle => '親モード/プレーヤー共有ポリシー';

  @override
  String get familyPolicyChildOwnsData =>
      'プレーヤー モードでは、トレーニング、プロフィール、日記、食事、計画を真実の情報源としてバックアップします。';

  @override
  String get familyPolicyParentWritesOnly =>
      '親モードでは、トレーニング フィードバックとレベル報酬名のみを保存できます。';

  @override
  String get familyPolicyParentSeedRequired =>
      '少なくとも 1 つのプレーヤーのバックアップがすでに存在している場合は、親デバイスを接続します。';

  @override
  String get familyRoleChildActivated => 'プレイヤーモードが有効になりました。';

  @override
  String get familyRoleParentActivated => '親モードが有効になりました。';

  @override
  String get familyNamesSaved => '家族名が保存されました。';

  @override
  String get driveConnectedAccount => '接続されたドライブ アカウント';

  @override
  String get driveConnectedAccountEmpty => 'Google ドライブ アカウントがまだ接続されていません。';

  @override
  String get driveSavedPlayerAccount => 'プレーヤーモードのバックアップドライブ';

  @override
  String get driveReconnectSavedPlayer => 'プレーヤーモードドライブを再接続します';

  @override
  String get driveReconnectSavedPlayerHint =>
      '親モードを終了した後、ここで保存したプレーヤーモードのドライブ アカウントに再接続します。';

  @override
  String get driveReconnectSavedPlayerMismatch =>
      '保存したプレーヤーモードのドライブ アカウントに再接続してください。';

  @override
  String get driveSavedParentAccount => '保存された親モードのドライブ';

  @override
  String get driveReconnectSavedParent => '保存された親モードのドライブを再接続します';

  @override
  String get driveReconnectSavedParentHint => '親モードで最後に使用したドライブ アカウントを再接続します。';

  @override
  String get driveReconnectSavedParentMismatch =>
      '保存した保護者モードのドライブ アカウントに再接続してください。';

  @override
  String get driveSharedChildAccount => 'ソースバックアップドライブ';

  @override
  String get driveSharedChildAccountEmpty =>
      'バックアップ元はまだ不明です。最初に少なくとも 1 つのバックアップを作成します。';

  @override
  String get driveSharedChildAccountRemoteBackup =>
      'リモート バックアップが見つかりました。同じ Google ドライブ アカウントを接続します。';

  @override
  String get familyChildDriveConnectionSummary =>
      'ソース バックアップを保持する Google ドライブ アカウントを使用します。';

  @override
  String get familyParentUsesChildDriveSummary =>
      'ここではソース バックアップ ドライブ アカウントを使用します。';

  @override
  String get familyParentUsesChildDriveHint =>
      '親モードでは、プレーヤーのソース データを保持する Google ドライブ アカウントでサインインし、トレーニング フィードバックと報酬名を同じバックアップ ファイルに同期します。';

  @override
  String get familyParentUsesChildDriveWarning =>
      '親モードでは、トレーニング フィードバックと報酬名が同じバックアップ ファイルに安全に同期されるように、プレーヤーのソース データを保持する Google ドライブ アカウントに接続する必要があります。';

  @override
  String get familySharedSyncTitle => 'データ同期ステータス';

  @override
  String get familySharedSyncDescription =>
      '親のフィードバックとレベル報酬の名前は、同じプレーヤーのバックアップ ファイルに自動的に書き込まれます。';

  @override
  String get familySyncAlertTitle => '保護者同期';

  @override
  String familySyncParentTrainingAdded(int count) {
    return '$count 新しいプレーヤーのトレーニング ログが同期されました。';
  }

  @override
  String familySyncParentRewardClaimed(int count) {
    return '$count プレーヤーの報酬請求が同期されました。';
  }

  @override
  String familySyncParentTrainingAndRewardClaimed(
      int trainingCount, int rewardCount) {
    return '$trainingCount の新規プレーヤーのトレーニング ログと $rewardCount の報酬請求が同期されました。';
  }

  @override
  String familySyncChildFeedbackAdded(int count) {
    return '$count 親フィードバックの更新が同期されました。';
  }

  @override
  String get familySyncChildRewardUpdated => 'レベル報酬名が同期されました。';

  @override
  String familySyncChildFeedbackAndReward(int count) {
    return '$count 親フィードバックの更新と報酬名が同期されました。';
  }

  @override
  String get familySharedLastSync => '最後の親/プレーヤーの同期';

  @override
  String get familySharedLastPush => '最後のひと押し';

  @override
  String get familySharedLastRefresh => '最終インポートチェック';

  @override
  String get familySharedAutoRefreshDescription =>
      '親モードが開くか、アプリが再開されると、最新の状態が自動的にチェックされます。ローカルの変更がドライブにプッシュされるのをまだ待機している場合、自動チェックは一時停止します。';

  @override
  String get familySharedPendingLocalChanges =>
      'ローカルの変更をドライブにプッシュする必要があるため、自動インポートは一時停止されています。';

  @override
  String get familySharedRestore => 'プレイヤーデータをインポートする';

  @override
  String get familySharedRestoreConfirm =>
      'Google ドライブから最新のプレーヤー データをインポートしますか?これにより、このデバイスに表示されるプレーヤーのレコードと共有データが置き換えられます。';

  @override
  String get familySharedRestoreSuccess => 'プレイヤーデータをインポートしました。';

  @override
  String get familySharedRestoreFailed => 'プレイヤーデータのインポートに失敗しました。もう一度試してください。';

  @override
  String get familySharedRestoreLocal => '以前のプレイヤーデータをインポートする';

  @override
  String get familySharedRestoreLocalConfirm =>
      'このデバイスにインポートされた最新のプレーヤー データの変更を元に戻しますか?これにより、このデバイスに表示されるプレーヤーのレコードと共有データが置き換えられます。';

  @override
  String get familySharedRestoreLocalSuccess => '最新のインポートは取り消されました。';

  @override
  String get familySharedRestoreLocalFailed =>
      '最新のインポートを元に戻すことができませんでした。もう一度試してください。';

  @override
  String get restoreReconfirmTitle => '復元の確認';

  @override
  String get restoreReconfirmBody => '本当に復元しますか?現在のデータは置き換えられます。';

  @override
  String get familyParentFamilyMismatch =>
      '接続されたドライブのバックアップは、この親/プレーヤーの共有データと一致しません。';

  @override
  String get moreInfoAction => '詳細情報';

  @override
  String get parentReadOnlyProfileSummary => 'プロフィールはここでのみ閲覧可能です。';

  @override
  String get parentReadOnlyProfileDescription =>
      '親モードでは、プロファイルは読み取り専用に保たれます。トレーニング ログからトレーニング フィードバックを残し、レベル ガイドから報酬名を設定します。';

  @override
  String get parentReadOnlySettingsOptions =>
      '親モードでは、デフォルト値やニュース フィルターを編集できません。プレイヤーモードで変更してください。';

  @override
  String get benchmarkReferencesTitle => '平均基準';

  @override
  String get benchmarkRefreshAction => '平均を更新';

  @override
  String get benchmarkRefreshInProgress => '更新中';

  @override
  String benchmarkLastSynced(Object date) {
    return '最終同期: $date';
  }

  @override
  String get benchmarkRefreshSuccess => '平均基準データを更新しました。';

  @override
  String get benchmarkRefreshFailed => '平均基準データの更新に失敗しました。ネットワークを確認してください。';

  @override
  String get benchmarkReferenceNote =>
      '身長と体重は CDC 成長曲線の中央値を使用します。活動時間はWHOの青少年指導を利用しています。ジャグリング練習場はサッカーのトレーニングの基準であり、医学的な基準ではありません。';

  @override
  String get parentReadOnlyEntryTitle => '親モードではトレーニングノートを編集できません。';

  @override
  String get parentReadOnlyEntryBody =>
      'トレーニング、食事、日記などの主要な記録はプレーヤー モードに残ります。親モードでは、元のレコードは変更されず、フィードバックと報酬の名前のみが個別に保存されます。';

  @override
  String get parentReadOnlyLogsSummary => 'トレーニング ログを表示し、フィードバックのみを残します。';

  @override
  String get parentReadOnlyLogsBanner =>
      '親モードではトレーニング ログは削除されません。代わりにレコードを開いてフィードバックを残してください。';

  @override
  String get parentReadOnlyLogsMessage => '親モードではトレーニング ログを削除できません。';

  @override
  String get parentReadOnlyMealLogSummary => '食事ログはここでのみ閲覧可能です。';

  @override
  String get parentReadOnlyMealLog => '親モードでは食事ログを編集できません。プレイヤーモードの食事を更新します。';

  @override
  String get parentReadOnlyQuiz =>
      '親モードではクイズは実行されません。クイズ履歴と XP はプレーヤー モードのままです。';

  @override
  String get parentReadOnlyDrawerMessage =>
      '親モードでは、コア レコードが読み取り専用に保持されます。代わりに共有データを使用し、ネーミングに報酬を与えます。';

  @override
  String get parentReadOnlyCalendarSummary => 'カレンダーはここでのみ表示されます。';

  @override
  String get parentReadOnlyCalendarBanner =>
      '親モードでは、カレンダーは読み取り専用になります。プレーヤーモードでのプラン、試合、食事を更新します。';

  @override
  String get parentReadOnlyCalendarMessage => '親モードではカレンダーを編集できません。';

  @override
  String get parentReadOnlyChallengeSummary => 'チャレンジはここでのみ表示されます。';

  @override
  String get parentReadOnlyChallengeMessage =>
      '親モードではチャレンジを開始したりミッションを編集したりできません。プレイヤーモードで進めたチャレンジ状況のみ確認できます。';

  @override
  String get parentReadOnlyDiaryMessage => '親モードでは日記を編集できません。';

  @override
  String get parentReadOnlyDiaryBadge => '親モードは読み取り専用';

  @override
  String get parentReadOnlySketchMessage => '親モードではトレーニング スケッチを編集できません。';

  @override
  String get parentReadOnlyFortuneEmpty => '保存されたフォーチュンはまだありません。';

  @override
  String get parentFeedbackSectionTitle => '保護者からのフィードバック';

  @override
  String get parentFeedbackHelper =>
      '元のトレーニング記録はそのままにして、このセッションの親のフィードバックのみを個別に保存します。';

  @override
  String get parentFeedbackReadOnlyHint => '保護者がこのトレーニング ログに残したフィードバック。';

  @override
  String get parentFeedbackInputLabel => '保護者からのフィードバック';

  @override
  String get parentFeedbackInputHint => '親が褒めたいこと、次に見てほしいことを書きます。';

  @override
  String get parentFeedbackSave => 'フィードバックを保存する';

  @override
  String get parentFeedbackClear => 'クリア';

  @override
  String get parentFeedbackWriteAction => 'フィードバックを書く';

  @override
  String get parentFeedbackEditAction => 'フィードバックを編集する';

  @override
  String get parentFeedbackViewAction => 'フィードバックを見る';

  @override
  String get parentFeedbackDiscardTitle => '保存されていないフィードバック';

  @override
  String get parentFeedbackDiscardBody => '未保存のフィードバックがあります。保存せずに終了しますか?';

  @override
  String get parentFeedbackDiscardAction => '離れる';

  @override
  String get parentFeedbackSaved => 'フィードバックが保存されました。';

  @override
  String get parentFeedbackSaveFailed => 'フィードバックを保存できませんでした。もう一度やり直してください。';

  @override
  String get parentFeedbackCleared => 'フィードバックがクリアされました。';

  @override
  String get parentFeedbackEmpty => 'まだフィードバックはありません。';

  @override
  String get parentFeedbackReactionOnly => '選手がリアクションを残しました。';

  @override
  String get parentFeedbackReactionLabel => '反応';

  @override
  String get parentFeedbackReactionNone => 'なし';

  @override
  String get parentFeedbackReactionThanks => 'ありがとう';

  @override
  String get parentFeedbackReactionProud => '誇りに思う';

  @override
  String get parentFeedbackReactionReview => 'レビュー';

  @override
  String get parentFeedbackReactionTry => '次に試してください';

  @override
  String get parentFeedbackOpenExistingEntryTitle =>
      '既存のトレーニング ログを開いてフィードバックを残してください。';

  @override
  String get parentFeedbackOpenExistingEntryBody =>
      '親モードでは、新しいトレーニング ログは作成されません。親のフィードバックは、プレーヤーが最初に記録した後でのみ、既存のトレーニング ログに保存できます。';

  @override
  String get parentSharedSyncInProgress => 'プレーヤーのドライブと同期しています...';

  @override
  String get parentSharedSyncDone => 'プレーヤーのドライブにも同期されます。';

  @override
  String get parentSharedSyncPending =>
      'ドライブが接続された後、同じプレーヤーのバックアップ ファイルに同期されます。';

  @override
  String get levelGuideParentModeLabel => '親モード';

  @override
  String get levelGuideChildModeLabel => 'プレイヤーモード';

  @override
  String get levelGuideParentModeDescription =>
      '親モードでは報酬名のみを保存でき、保存された報酬名は共有プレーヤーのドライブのバックアップにも同期されます。報酬で受け取ったマークはプレーヤー モードに残ります。';

  @override
  String get levelGuideChildModeDescription =>
      'プレイヤーモードでは、受け取ったレベル報酬をマークできます。報酬の名前は親モードのままです。';

  @override
  String get levelGuideModeInfoTooltip => 'モードの説明を表示';

  @override
  String get levelGuideClaimChildOnly => 'プレイヤーモードで請求する';

  @override
  String get levelGuideRewardFallbackName => '褒美';

  @override
  String levelGuideRewardClaimed(Object rewardName) {
    return '$rewardNameを主張しました。';
  }

  @override
  String get levelGuideRewardSaved => '報酬が保存されました。';

  @override
  String get levelGuideRewardCleared => '報酬クリアしました。';

  @override
  String levelGuideMaxLevelRangeLabel(Object minXp) {
    return '$minXp XP+ · 最大レベル';
  }

  @override
  String levelGuideMaxLevelMasteryHint(Object masterySpan) {
    return '次のレベルはありません。 $masterySpan XP ごとにマスタリー スターを獲得し続けます。';
  }

  @override
  String get trainingPlanAddTitle => 'トレーニングプランを追加';

  @override
  String get trainingPlanEditTitle => 'トレーニング計画の編集';

  @override
  String get trainingPlanViewTitle => 'トレーニングプランを見る';

  @override
  String get matchAddTitle => '一致を追加';

  @override
  String get matchEditTitle => 'マッチの編集';

  @override
  String get matchViewTitle => '試合を見る';

  @override
  String get matchKindFriendly => '親善試合';

  @override
  String get matchKindLeague => 'リーグ戦';

  @override
  String get matchOpponentTeamLabel => '相手チーム';

  @override
  String get matchOpponentTeamHint => '例えば水原U15';

  @override
  String get matchLeagueTeamsLabel => 'リーグ参加チーム';

  @override
  String get matchLeagueTeamsHint => '1行に1チーム、またはカンマ区切りで入力';

  @override
  String get matchLeaguePointsMode => '勝ち点';

  @override
  String get matchTournamentWinsMode => 'トーナメント勝利';

  @override
  String get matchLeaguePointsLabel => '勝ち点';

  @override
  String get matchTournamentWinsLabel => 'トーナメント勝利';

  @override
  String matchLeaguePointsValue(int points) {
    return '勝ち点 $points';
  }

  @override
  String matchTournamentWinsValue(int count) {
    return '$count勝';
  }

  @override
  String get matchOurScoreLabel => '私たちのスコア';

  @override
  String get matchOpponentScoreLabel => '相手のスコア';

  @override
  String get matchGoalsLabel => '目標';

  @override
  String get matchAssistsLabel => 'アシスト';

  @override
  String get matchMinutesPlayedLabel => 'プレイ時間（分）';

  @override
  String get matchMinutesPlayedHint => '例えば70';

  @override
  String get matchNoteOptionalLabel => '注記 (オプション)';

  @override
  String get matchShotsOnTargetLabel => '枠内シュート';

  @override
  String get matchBallsWonLabel => '獲得したボール';

  @override
  String get calendarMatchXpSourceLabel => '対戦成績';

  @override
  String matchSavedWithXpFeedback(int count) {
    return '保存されたマッチ +$count XP';
  }

  @override
  String get trainingSketchControlsPanel => 'ツールと選択';

  @override
  String get trainingSketchPlayTooltip => '遊ぶ';

  @override
  String get trainingSketchPlaybackSpeedTooltip => '再生速度';

  @override
  String get trainingSketchAddSketchTooltip => 'スケッチを追加';

  @override
  String get trainingSketchCopySketchTooltip => '別のスケッチからコピーする';

  @override
  String get trainingSketchDeleteSketchTooltip => 'スケッチの削除';

  @override
  String get trainingSketchImportSketchTooltip => '以前のスケッチをインポートする';

  @override
  String get trainingSketchRenameSketchTooltip => 'スケッチの名前を変更';

  @override
  String get trainingSketchMemoLabel => 'トレーニングスケッチノート';

  @override
  String get trainingSketchMemoHint => '例えばコーン間をツータッチドリブルしてパスする';

  @override
  String get trainingSketchVoiceInputTooltip => '音声入力';

  @override
  String get trainingSketchConeButton => '円錐';

  @override
  String get trainingSketchLowHurdleButton => 'ハードルが低い';

  @override
  String get trainingSketchPlayerButton => 'プレーヤー';

  @override
  String get trainingSketchBallButton => 'ボール';

  @override
  String get trainingSketchLadderButton => 'ラダー';

  @override
  String get trainingSketchPenButton => 'ペン';

  @override
  String get trainingSketchClearInkButton => 'クリアインク';

  @override
  String get trainingSketchResetButton => 'クリア';

  @override
  String get trainingSketchPenModeHint => 'ペンモード: ボード上をドラッグして描画します。';

  @override
  String get trainingSketchPenColorLabel => 'ペンの色';

  @override
  String get trainingSketchQuickStart =>
      'クイックスタート: プレーヤー/ボールを追加 -> パスを描画 -> 再生 (速度) -> 保存';

  @override
  String get trainingSketchSelectedItemTitle => '選択した項目';

  @override
  String get trainingSketchAssignColorLabel => '色の割り当て';

  @override
  String get trainingSketchDrawRouteFirst => 'まずルートを描画または選択します。';

  @override
  String get trainingSketchAddPlayerFirst => 'まずプレーヤーアイコンを追加します。';

  @override
  String get trainingSketchAddBallFirst => 'まずボールアイコンを追加します。';

  @override
  String get trainingSketchRoutesButton => 'ルート';

  @override
  String get trainingSketchPassDribbleMoveFlowButton => 'パス・ドリブルフロー';

  @override
  String get trainingSketchPassDribbleMoveFlowSnack =>
      '1番のパス、2番のドリブル、3番の移動フローを適用しました。';

  @override
  String get trainingSketchClearAllRoutesButton => '全ルートクリア';

  @override
  String get trainingSketchPlayerRoutesTitle => 'プレイヤールート';

  @override
  String get trainingSketchBallRoutesTitle => 'ボールルート';

  @override
  String get trainingSketchRoutesEmpty => 'このタイプにはまだルートがありません。';

  @override
  String get trainingSketchRedrawRouteButton => '選択された再描画';

  @override
  String get trainingSketchDeleteRouteButton => '選択したものを削除';

  @override
  String trainingSketchPlayerRouteChip(int index) {
    return 'プレイヤー $index';
  }

  @override
  String trainingSketchBallRouteChip(int index) {
    return 'ボール $index';
  }

  @override
  String get trainingSketchRouteReplaceHint => 'ボード上でドラッグして、選択したルートを置き換えます。';

  @override
  String get trainingSketchSelectedPlayerRouteHint =>
      'ボード上をドラッグして、選択したプレイヤーのルートを設定します。すでに存在する場合は置き換えられます。';

  @override
  String get trainingSketchSelectedBallRouteHint =>
      'ボード上でドラッグして、選択したボールのルートを設定します。すでに存在する場合は置き換えられます。';

  @override
  String get trainingSketchPlayerRouteHint =>
      'ボード上をドラッグして、未使用のプレイヤー ルートを割り当てます。特定のプレイヤーをターゲットにしたい場合は、最初にプレイヤーを選択します。';

  @override
  String get trainingSketchBallRouteHint =>
      'ボード上をドラッグして、未使用のボール ルートを割り当てます。特定のボールをターゲットにしたい場合は、最初にボールを選択します。';

  @override
  String get trainingSketchLinkPlayerHint =>
      'ルート モードでは、このプレーヤーを選択し、ドラッグしてルートを割り当てるか置き換えます。';

  @override
  String get trainingSketchLinkBallHint =>
      'ルート モードでは、このボールを選択してドラッグし、そのルートを割り当てるか置き換えます。';

  @override
  String get trainingSketchPlayerRouteLimitReached =>
      'すべてのプレイヤーのルートはすでに割り当てられています。ルートを置き換えるか再描画するプレーヤーを選択します。';

  @override
  String get trainingSketchBallRouteLimitReached =>
      'すべてのボールルートはすでに割り当てられています。ボールを選択してルートを置き換えるか、再描画します。';

  @override
  String get trainingSketchTemplatePickerTitle => 'テンプレートを選択';

  @override
  String get trainingSketchTemplateBlankLabel => '空白のスケッチ';

  @override
  String get trainingSketchTemplateBlankDescription => '空のボードから始める';

  @override
  String get trainingSketchTemplatePassWarmupLabel => 'パスウォームアップ';

  @override
  String get trainingSketchTemplatePassWarmupDescription =>
      '基本的な 3 プレーヤーのパスのセットアップ';

  @override
  String get trainingSketchTemplatePassWarmupMethod => 'ツータッチパスとローテーション';

  @override
  String get trainingSketchTemplateBuildUpLabel => 'ビルドアップパターン';

  @override
  String get trainingSketchTemplateBuildUpDescription => '背面ビルドアップ構造';

  @override
  String get trainingSketchTemplateBuildUpMethod => '3-2の形での後方ビルドアップ';

  @override
  String get trainingSketchTemplatePressingLabel => 'プレストランジション';

  @override
  String get trainingSketchTemplatePressingDescription => '前押しトリガー形状';

  @override
  String get trainingSketchTemplatePressingMethod => '前押しトリガーのキューを確認する';

  @override
  String get trainingSketchTemplateSetPieceLabel => 'セットピース';

  @override
  String get trainingSketchTemplateSetPieceDescription => 'コーナーキックのレイアウト';

  @override
  String get trainingSketchTemplateSetPieceMethod => 'コーナーキック攻撃のセットアップ';

  @override
  String get trainingSketchTemplateRondoLabel => 'ロンド';

  @override
  String get trainingSketchTemplateRondoDescription => '4対1のキープアウェイシェイプ';

  @override
  String get trainingSketchTemplateRondoMethod => '2 タッチ制限のある 4 対 1 ロンド';

  @override
  String get trainingSketchTemplateFinishingLabel => '仕上げパターン';

  @override
  String get trainingSketchTemplateFinishingDescription => 'クロス・ボックス仕上げの流れ';

  @override
  String get trainingSketchTemplateFinishingMethod => '幅広い組み合わせでボックス仕上げ';

  @override
  String get trainingSketchTemplateWingCombinationLabel => '幅広い組み合わせ';

  @override
  String get trainingSketchTemplateWingCombinationDescription =>
      'ウィンガーとフルバックのオーバーラップパターン';

  @override
  String get trainingSketchTemplateWingCombinationMethod =>
      'ウィンガーとフルバックのオーバーラップからカットバックへ';

  @override
  String get trainingSketchTemplateTransitionAttackLabel => 'トランジション攻撃';

  @override
  String get trainingSketchTemplateTransitionAttackDescription => 'リゲイン直後の速攻';

  @override
  String get trainingSketchTemplateTransitionAttackMethod =>
      '取り戻してから6秒以内に前方に攻撃する';

  @override
  String get trainingSketchTemplateGalleryAction => 'テンプレートを表示する';

  @override
  String get trainingSketchTemplateGalleryTitle => 'トレーニング テンプレート ギャラリー';

  @override
  String get trainingSketchTemplateGallerySubtitle =>
      'スケッチを作成する前に、動線と注記をプレビューします。';

  @override
  String get challengeTitle => 'チャレンジ';

  @override
  String get challengeRewardAction => '報酬';

  @override
  String get challengeHistoryAction => '履歴';

  @override
  String get challengeStartHeroTitle => 'リンジーのチャレンジモード';

  @override
  String get challengeStartHeroBody =>
      '期間とミッション別の量を選び、開始ボタンを押すと始まります。1日でも逃すと失敗です。';

  @override
  String get challengeLatestComplete => '最新チャレンジ完了';

  @override
  String get challengeSelectTitle => 'チャレンジを選択';

  @override
  String get challengeDurationSelectTitle => '1. 期間を選択';

  @override
  String get challengeTemplateStarterTitle => '3日チャレンジ';

  @override
  String get challengeTemplateStarterDescription => '短く集中してチャレンジのリズムを覚えます。';

  @override
  String get challengeTemplateWeeklyTitle => '7日チャレンジ';

  @override
  String get challengeTemplateWeeklyDescription => '1週間、毎日のルーティンを続けます。';

  @override
  String get challengeTemplateFocusTitle => '14日チャレンジ';

  @override
  String get challengeTemplateFocusDescription => '2週間、コツコツ続ける力を伸ばします。';

  @override
  String get challengeDifficultySprout => 'めばえ';

  @override
  String get challengeDifficultyBoost => 'ぐんぐん';

  @override
  String get challengeDifficultyStar => 'スター';

  @override
  String get challengeTrainingLevelTitle => '2. レベルを選択';

  @override
  String get challengeTrainingLevelRookieTitle => 'ルーキーレベル';

  @override
  String get challengeTrainingLevelRookieDescription =>
      '低学年やサッカーを始めたばかりの選手向けの軽めの目標です。';

  @override
  String get challengeTrainingLevelGrowthTitle => 'ぐんぐんレベル';

  @override
  String get challengeTrainingLevelGrowthDescription =>
      '基礎のリズムができ、定期的に練習する選手向けの標準目標です。';

  @override
  String get challengeTrainingLevelAceTitle => 'エースレベル';

  @override
  String get challengeTrainingLevelAceDescription =>
      '年齢とサッカー経験がある選手向けの挑戦的な目標です。';

  @override
  String get challengeRecommendedLevelBadge => 'おすすめ';

  @override
  String get challengeSkillSelectTitle => '2. ミッションを選択';

  @override
  String get challengeSkillSelectSubtitle =>
      'このチャレンジに入れるトレーニングプログラム、縄跳び、リフティング、食事ミッションを選び、毎日の目標量を調整します。';

  @override
  String get challengeMissionOtherSectionTitle => '追加ミッション';

  @override
  String get challengeMissionTargetsTitle => 'ミッション別目標';

  @override
  String get challengeMissionTargetsSubtitle => '選択したミッションごとに毎日の達成量を選びます。';

  @override
  String get challengeTrainingProgramLinkTitle => 'トレーニングプログラム編集';

  @override
  String get challengeTrainingProgramLinkBody =>
      '設定のデフォルトからトレーニングプログラム項目を編集します。';

  @override
  String get challengeTrainingProgramLinkAction => '開く';

  @override
  String get challengeTrainingProgramMissionLabel => 'トレーニングプログラム';

  @override
  String get challengeMissionSummaryTitle => '選択したミッション';

  @override
  String challengeMissionProgramSummary(Object label, Object programs) {
    return '$label: $programs';
  }

  @override
  String challengeRiceBowlsOption(Object bowls) {
    return '$bowls杯';
  }

  @override
  String get challengeSkillDribble => 'ドリブル';

  @override
  String get challengeSkillSpeedRun => 'スピード走';

  @override
  String get challengeSkillJumpRope => '縄跳び';

  @override
  String get challengeSkillLifting => 'リフティング';

  @override
  String get challengeSkillPassing => 'パス';

  @override
  String get challengeSkillShooting => 'シュート';

  @override
  String get challengeSkillFirstTouch => 'ファーストタッチ';

  @override
  String get challengeSkillDefense => '守備';

  @override
  String challengeLevelTrainingTargetLabel(int minutes) {
    return '総トレーニング $minutes分';
  }

  @override
  String challengeLevelJumpRopeTargetLabel(int minutes) {
    return '縄跳び $minutes分';
  }

  @override
  String challengeLevelLiftingTargetLabel(int minutes) {
    return 'リフティング $minutes分';
  }

  @override
  String challengeDaysLabel(int days) {
    return '$days日';
  }

  @override
  String challengeRewardXp(int xp) {
    return '+$xp XP';
  }

  @override
  String challengeRoundXpLabel(int xp) {
    return 'ラウンド +$xp XP';
  }

  @override
  String challengeStreakBonusLabel(int xp) {
    return '連続ボーナス +$xp XP';
  }

  @override
  String challengeActiveLevelPill(Object level) {
    return 'レベル: $level';
  }

  @override
  String get challengeInfoStatusLabel => '状態';

  @override
  String get challengeInfoLevelLabel => 'レベル';

  @override
  String get challengeInfoRoundXpLabel => 'ラウンド報酬';

  @override
  String get challengeInfoPotentialXpLabel => 'チャレンジ報酬';

  @override
  String get challengeInfoPeriodLabel => '期間';

  @override
  String get challengeInfoRoundProgressLabel => 'ラウンド進捗';

  @override
  String challengePotentialXpPill(int xp) {
    return '獲得可能 XP +$xp';
  }

  @override
  String challengeCompletionBonusLabel(int xp) {
    return '完走ボーナス +$xp XP';
  }

  @override
  String challengeTotalXpLabel(int xp) {
    return '最大 +$xp XP';
  }

  @override
  String get challengeRewardPitchTitle => '完走すると大きなボーナスがあります';

  @override
  String get challengeRewardGuideTitle => 'チャレンジ報酬';

  @override
  String get challengeRewardGuideBody =>
      'ラウンドを連続で完了するほどラウンド報酬が増えます。最後まで完走すると完走ボーナスも加算されます。';

  @override
  String get challengeRewardGuideNoActive =>
      '進行中のチャレンジはありません。チャレンジを始めると獲得済みXPと残りXPを確認できます。';

  @override
  String get challengeRewardGuideActiveTitle => '現在のチャレンジ';

  @override
  String get challengeRewardGuideTemplatesTitle => 'チャレンジ別の報酬プラン';

  @override
  String challengeRewardGuideTemplateTitle(Object title) {
    return '$title 報酬プラン';
  }

  @override
  String get challengeRewardGuideHistoryTitle => '報酬プラン';

  @override
  String get challengeRewardGuideBaseRoundLabel => '基本ラウンド';

  @override
  String get challengeRewardGuideStreakBonusLabel => '最大連続ボーナス';

  @override
  String get challengeRewardGuideRoundTotalLabel => 'ラウンド合計';

  @override
  String get challengeRewardGuideFinishBonusLabel => '完走ボーナス';

  @override
  String get challengeRewardGuidePotentialLabel => '最大XP';

  @override
  String get challengeRewardGuideEarnedLabel => '現在獲得';

  @override
  String get challengeRewardGuideRemainingLabel => '残りXP';

  @override
  String get challengeRewardGuideRoundsTitle => 'ラウンド報酬';

  @override
  String challengeRewardGuideRoundReward(int round, int xp) {
    return 'ラウンド $round: +$xp XP';
  }

  @override
  String challengeRewardGuideRoundRewardWithBonus(
      int round, int xp, int bonus) {
    return 'ラウンド $round: +$xp XP (連続 +$bonus)';
  }

  @override
  String get challengeStartReadyTitle => '3. 開始準備';

  @override
  String get challengeStartAction => 'チャレンジ開始';

  @override
  String challengeRoundCount(int completed, int total) {
    return '$completed/$total ラウンド完了';
  }

  @override
  String challengeMissionCount(int completed, int total) {
    return '$completed/$total ミッション完了';
  }

  @override
  String challengeProgressPercent(int percent) {
    return '$percent% 完了';
  }

  @override
  String challengeTodayRoundTitle(int round) {
    return '今日 · ラウンド $round';
  }

  @override
  String challengeUpcomingRoundTitle(int round) {
    return '次 · ラウンド $round';
  }

  @override
  String get challengeRoundsTitle => 'ラウンド';

  @override
  String challengeRoundTitle(int round) {
    return 'ラウンド $round';
  }

  @override
  String get challengeTrainingLabel => 'トレーニング';

  @override
  String get challengeJumpRopeLabel => '縄跳び';

  @override
  String get challengeLiftingLabel => 'リフティング';

  @override
  String get challengeMealLabel => '食事';

  @override
  String challengeTrainingGoalValue(int current, int target) {
    return '$current/$target分';
  }

  @override
  String challengeMealGoalValue(Object current, Object target) {
    return '$current/$target杯';
  }

  @override
  String get challengeCompletedBadge => '完了';

  @override
  String get challengePendingBadge => '進行中';

  @override
  String challengeCompletedSummary(Object title) {
    return '$title 完了';
  }

  @override
  String get challengeRoundDateToday => '今日';

  @override
  String challengeStartSnack(Object title) {
    return '$titleを開始しました。';
  }

  @override
  String challengeAwardSnack(int xp) {
    return 'チャレンジラウンド完了 +$xp XP';
  }

  @override
  String get challengeCompletedSnack => 'チャレンジ完了。';

  @override
  String challengeFailedSnack(int round) {
    return 'ラウンド $round を逃したため、チャレンジは失敗で終了しました。';
  }

  @override
  String challengeFailureTitle(int round) {
    return 'ラウンド $round で止まりました';
  }

  @override
  String get challengeFailureSimpleTitle => '今日はリンジーが悲しそうです';

  @override
  String get challengeFailureBody => 'リンジーは残念そうです。でも次の挑戦はもっと力強く始められます。';

  @override
  String get challengeFailureAction => 'ラウンドを確認';

  @override
  String get challengeCelebrationTitle => 'ミッション完了!';

  @override
  String challengeCelebrationBody(int rounds, int xp) {
    return 'ラウンド $rounds 完了! リンジーが応援しています。+$xp XP を受け取りました。';
  }

  @override
  String get challengeCelebrationCompleteTitle => 'チャレンジ完走!';

  @override
  String challengeCelebrationCompleteBody(int xp) {
    return 'すべてのラウンドが終わりました。+$xp XP を受け取りました。';
  }

  @override
  String get challengeCelebrationCompleteBodyNoXp =>
      'すべてのミッション記録が完了しました。チャレンジ完了画面で進行状況を確認してください。';

  @override
  String get challengeCelebrationMissionsTitle => '完了したミッション';

  @override
  String get challengeCelebrationAction => 'いいね!';

  @override
  String get challengeHistoryTitle => 'チャレンジ履歴';

  @override
  String get challengeHistorySummaryTitle => 'チャレンジ概要';

  @override
  String get challengeHistoryListTitle => 'チャレンジ記録';

  @override
  String get challengeHistorySummaryTotalLabel => '合計';

  @override
  String get challengeHistorySummarySuccessLabel => '成功';

  @override
  String get challengeHistorySummaryLatestLabel => '最新';

  @override
  String get challengeHistoryEmpty => 'まだチャレンジ履歴がありません。';

  @override
  String challengeHistoryStarted(Object date) {
    return '$date 開始';
  }

  @override
  String challengeHistoryFailedRound(Object date, int round) {
    return '$date 開始 · ラウンド $round 失敗';
  }

  @override
  String get challengeHistoryResultCompleted => '成功';

  @override
  String get challengeHistoryResultFailed => '失敗';

  @override
  String get challengeHistoryResultAbandoned => '終了';

  @override
  String get challengeHistoryResultInProgress => '進行中';

  @override
  String challengeHistoryRoundSuccessCount(int success, int total) {
    return '成功 $success/$total';
  }

  @override
  String challengeHistoryRoundFailureCount(int failure, int total) {
    return '失敗 $failure/$total';
  }

  @override
  String get challengeHistoryDetailTitle => 'チャレンジ詳細';

  @override
  String get challengeHistoryDetailCompletedBody =>
      'すべてのラウンドを完了しました。報酬プランとラウンド日を確認しましょう。';

  @override
  String challengeHistoryDetailFailedBody(int round) {
    return 'このチャレンジはラウンド $round で止まりました。ラウンドの流れと報酬プランを確認しましょう。';
  }

  @override
  String get challengeHistoryDetailAbandonedBody =>
      '完了前に終了したチャレンジです。元のラウンド計画を確認しましょう。';

  @override
  String challengeHistoryDetailPeriodValue(Object start, Object end) {
    return '$start - $end';
  }

  @override
  String get challengeHistoryDetailMissionsLabel => 'ミッション';

  @override
  String get challengeHistoryDetailEarnedXpLabel => '獲得XP';

  @override
  String get challengeHistoryDetailNoMissions => '追加ミッションのみ';

  @override
  String get challengeHistoryDetailRoundsTitle => 'ラウンド詳細';

  @override
  String challengeHistoryDetailRoundDate(int round, Object date) {
    return 'ラウンド $round · $date';
  }

  @override
  String get challengeHistoryDetailRoundCompleted => '完了';

  @override
  String get challengeHistoryDetailRoundFailed => 'ここで失敗';

  @override
  String get challengeHistoryDetailRoundEnded => '未集計';

  @override
  String get challengeAbandonAction => '終了';

  @override
  String get challengeAbandonTitle => 'チャレンジを終了';

  @override
  String get challengeAbandonBody => '現在のチャレンジを終了して別のチャレンジを選択しますか?';

  @override
  String get challengeAbandonConfirm => '終了';

  @override
  String get homeChallengeEmptyBody => 'リンジーとチャレンジを始めましょう。';

  @override
  String homeChallengeActiveBody(int completed, int total, int round) {
    return '$completed/$total 完了 · 今日ラウンド $round';
  }

  @override
  String xpHistoryChallengeRound(Object label) {
    return 'チャレンジラウンド · $label';
  }

  @override
  String get xpHistoryReasonChallengeRoundCompleted => 'チャレンジラウンド完了';

  @override
  String get xpHistoryReasonChallengeRoundStreakBonus => 'チャレンジ連続ボーナス';

  @override
  String get xpHistoryReasonChallengeCompletionBonus => 'チャレンジ完走ボーナス';
}
