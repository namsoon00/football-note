import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../domain/repositories/option_repository.dart';

class CoachLessonScreen extends StatefulWidget {
  final OptionRepository optionRepository;

  const CoachLessonScreen({
    super.key,
    required this.optionRepository,
  });

  @override
  State<CoachLessonScreen> createState() => _CoachLessonScreenState();
}

class _CoachLessonScreenState extends State<CoachLessonScreen> {
  static const int _maxHabitCount = 30;
  static const String _recentLessonIdKey = 'coach_recent_lesson_id_v1';
  static const String _diagnosisKey = 'manual_diagnosis_scores_v1';
  static const String _progressCurrentKey = 'manual_progress_current_v1';
  static const String _progressPreviousKey = 'manual_progress_previous_v1';
  static const String _habitFlagsKey = 'manual_habit_flags_v1';
  static const String _habitMissionDoneKey = 'manual_habit_mission_done_v1';
  static const String _failureLogsKey = 'manual_failure_logs_v1';
  static const String _customHabitsKey = 'manual_custom_habits_v1';
  static const String _habitQuestionAnswersKey = 'manual_habit_questions_v1';

  late final List<_ManualLesson> _lessons;
  late String _selectedLessonId;
  _ManualTab _tab = _ManualTab.diagnosis;

  Map<String, int> _diagnosisScores = <String, int>{
    'dribble': 3,
    'passing': 3,
    'first_touch': 3,
    'shooting': 3,
  };
  Map<String, _ManualProgress> _currentProgressByLesson =
      <String, _ManualProgress>{};
  Map<String, _ManualProgress> _previousProgressByLesson =
      <String, _ManualProgress>{};

  final Map<String, bool> _habitFlags = <String, bool>{};
  List<_HabitIssue> _customHabits = <_HabitIssue>[];
  final Map<String, bool> _questionAnswers = <String, bool>{
    for (final q in _habitQuestions) q.id: false,
  };
  Map<String, bool> _habitMissionDone = <String, bool>{};
  List<_FailureLog> _failureLogs = <_FailureLog>[];

  double _editSuccessRate = 60;
  int _editStreak = 6;
  double _editWeakFootRate = 40;

  bool get _isKo => Localizations.localeOf(context).languageCode == 'ko';
  List<_HabitIssue> get _allHabits => [..._habitCatalog, ..._customHabits];
  _ManualLesson get _selectedLesson =>
      _lessons.firstWhere((lesson) => lesson.id == _selectedLessonId);

  @override
  void initState() {
    super.initState();
    _lessons = _defaultLessons();
    for (final habit in _habitCatalog) {
      _habitFlags[habit.id] = false;
    }
    final recent =
        widget.optionRepository.getValue<String>(_recentLessonIdKey)?.trim();
    _selectedLessonId = _lessons.any((lesson) => lesson.id == recent)
        ? recent!
        : _lessons.first.id;
    _loadStoredData();
    _syncEditWithSelectedLesson();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(_isKo ? '축구 교습서' : 'Football Manual')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        children: [
          _buildIntroCard(),
          const SizedBox(height: 12),
          _buildTabSelector(),
          const SizedBox(height: 12),
          if (_tab == _ManualTab.diagnosis) ...[
            _buildDiagnosisCard(),
          ] else if (_tab == _ManualTab.study) ...[
            _buildLessonSelector(),
            const SizedBox(height: 12),
            _buildLessonOverviewCard(),
            const SizedBox(height: 12),
            ..._selectedLesson.sessions.map(
              (session) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _buildSessionCard(
                  session,
                  showDemo: false,
                  showVideos: false,
                ),
              ),
            ),
          ] else if (_tab == _ManualTab.practice) ...[
            _buildLessonSelector(),
            const SizedBox(height: 12),
            ..._selectedLesson.sessions.map(
              (session) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _buildSessionCard(
                  session,
                  showDemo: true,
                  showVideos: true,
                ),
              ),
            ),
          ] else ...[
            _buildLessonSelector(),
            const SizedBox(height: 12),
            _buildSelfCheckCard(),
            const SizedBox(height: 12),
            _buildHabitMissionCard(),
            const SizedBox(height: 12),
            _buildFailureLogCard(),
            const SizedBox(height: 12),
            _buildWeeklyHabitSummaryCard(),
          ],
        ],
      ),
    );
  }

  Widget _buildIntroCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
        child: Row(
          children: [
            CircleAvatar(
              radius: 22,
              backgroundColor: Theme.of(context).colorScheme.primaryContainer,
              child: Icon(
                Icons.menu_book,
                color: Theme.of(context).colorScheme.onPrimaryContainer,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                _isKo
                    ? 'U12 자습서: 진단 → 학습 → 따라하기 → 자가체크로 성장하고, 나쁜 습관을 교정하세요.'
                    : 'U12 self-study: Diagnose -> Learn -> Practice -> Self-check, then fix bad habits.',
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTabSelector() {
    return SegmentedButton<_ManualTab>(
      segments: <ButtonSegment<_ManualTab>>[
        ButtonSegment<_ManualTab>(
          value: _ManualTab.diagnosis,
          icon: const Icon(Icons.fact_check_outlined),
          label: Text(_isKo ? '진단' : 'Diagnose'),
        ),
        ButtonSegment<_ManualTab>(
          value: _ManualTab.study,
          icon: const Icon(Icons.school_outlined),
          label: Text(_isKo ? '학습' : 'Learn'),
        ),
        ButtonSegment<_ManualTab>(
          value: _ManualTab.practice,
          icon: const Icon(Icons.play_circle_outline),
          label: Text(_isKo ? '따라하기' : 'Practice'),
        ),
        ButtonSegment<_ManualTab>(
          value: _ManualTab.selfCheck,
          icon: const Icon(Icons.analytics_outlined),
          label: Text(_isKo ? '자가체크' : 'Self-check'),
        ),
      ],
      selected: <_ManualTab>{_tab},
      onSelectionChanged: (value) => setState(() => _tab = value.first),
      showSelectedIcon: false,
    );
  }

  Widget _buildLessonSelector() {
    final lesson = _selectedLesson;
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: _lessons.map((item) {
        final selected = item.id == lesson.id;
        return ChoiceChip(
          selected: selected,
          avatar: Icon(item.icon, size: 18),
          label: Text(_isKo ? item.titleKo : item.titleEn),
          onSelected: (_) => _selectLesson(item.id),
        );
      }).toList(growable: false),
    );
  }

  Widget _buildDiagnosisCard() {
    final avg = _diagnosisScores.values.fold<int>(0, (a, b) => a + b) / 4.0;
    final level = _levelText(avg);
    final recommendedLessonIds = _recommendedLessonsByDiagnosis();
    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _isKo ? '3분 셀프 진단(U12)' : '3-minute self diagnosis (U12)',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
            ),
            const SizedBox(height: 8),
            ..._diagnosisScores.entries.map(
              (entry) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('${_skillLabel(entry.key)}: ${entry.value}/5'),
                    Slider(
                      value: entry.value.toDouble(),
                      min: 1,
                      max: 5,
                      divisions: 4,
                      label: entry.value.toString(),
                      onChanged: (v) {
                        setState(() => _diagnosisScores[entry.key] = v.round());
                        _saveDiagnosisScores();
                      },
                    ),
                  ],
                ),
              ),
            ),
            Text(_isKo ? '현재 레벨: $level' : 'Current level: $level'),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: recommendedLessonIds
                  .map((id) => _lessons.firstWhere((lesson) => lesson.id == id))
                  .map(
                    (lesson) => ActionChip(
                      avatar: Icon(lesson.icon, size: 16),
                      label: Text(_isKo ? lesson.titleKo : lesson.titleEn),
                      onPressed: () {
                        _selectLesson(lesson.id);
                        setState(() => _tab = _ManualTab.study);
                      },
                    ),
                  )
                  .toList(growable: false),
            ),
            const SizedBox(height: 12),
            Divider(color: Theme.of(context).colorScheme.outlineVariant),
            const SizedBox(height: 8),
            Text(
              _isKo ? '자가 진단 문항' : 'Self-check questions',
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const SizedBox(height: 6),
            ..._habitQuestions.map(
              (question) => CheckboxListTile(
                dense: true,
                contentPadding: EdgeInsets.zero,
                title: Text(_isKo ? question.titleKo : question.titleEn),
                value: _questionAnswers[question.id] ?? false,
                onChanged: (value) {
                  setState(() => _questionAnswers[question.id] = value == true);
                  _saveQuestionAnswers();
                },
              ),
            ),
            const SizedBox(height: 10),
            Text(
              _isKo ? '현재 나쁜 습관 체크' : 'Current bad habits',
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const SizedBox(height: 4),
            Text(
              _isKo
                  ? '${_allHabits.length}/$_maxHabitCount 등록됨'
                  : '${_allHabits.length}/$_maxHabitCount registered',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 6),
            ..._allHabits.map(
              (habit) => SwitchListTile(
                dense: true,
                contentPadding: EdgeInsets.zero,
                title: Text(_isKo ? habit.labelKo : habit.labelEn),
                subtitle: Text(_isKo ? habit.hintKo : habit.hintEn),
                value: _habitFlags[habit.id] ?? false,
                onChanged: (v) {
                  setState(() => _habitFlags[habit.id] = v);
                  _saveHabitFlags();
                },
              ),
            ),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: _allHabits.length >= _maxHabitCount
                  ? null
                  : _showAddCustomHabitDialog,
              icon: const Icon(Icons.add_circle_outline),
              label: Text(
                _isKo ? '나쁜 습관 직접 추가' : 'Add custom bad habit',
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLessonOverviewCard() {
    final lesson = _selectedLesson;
    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _isKo ? lesson.titleKo : lesson.titleEn,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
            ),
            const SizedBox(height: 6),
            Text(_isKo ? lesson.summaryKo : lesson.summaryEn),
            const SizedBox(height: 10),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
              ),
              child: Text(_isKo ? lesson.studyCueKo : lesson.studyCueEn),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSessionCard(
    _ManualSession session, {
    required bool showDemo,
    required bool showVideos,
  }) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _isKo ? session.titleKo : session.titleEn,
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
            ),
            const SizedBox(height: 8),
            _labeledText('목적', 'Goal', session.goalKo, session.goalEn),
            const SizedBox(height: 6),
            _labeledText(
                '진행 방법', 'How to run', session.howToKo, session.howToEn),
            const SizedBox(height: 6),
            _labeledText(
              '자주 하는 실수',
              'Common mistakes',
              session.mistakeKo,
              session.mistakeEn,
            ),
            const SizedBox(height: 6),
            _labeledText(
              '성공 기준',
              'Success target',
              session.successKo,
              session.successEn,
            ),
            if (showDemo && session.demoType != null) ...[
              const SizedBox(height: 10),
              Text(
                _isKo ? '인앱 움직임 데모' : 'In-app movement demo',
                style: Theme.of(context).textTheme.labelLarge,
              ),
              const SizedBox(height: 8),
              _CoachMotionDemo(demoType: session.demoType!, isKo: _isKo),
            ],
            if (showVideos) ...[
              const SizedBox(height: 10),
              Text(
                _isKo ? '관련 영상' : 'Related videos',
                style: Theme.of(context).textTheme.labelLarge,
              ),
              const SizedBox(height: 8),
              ...session.videos.map(
                (video) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: OutlinedButton.icon(
                    onPressed: () => _openVideo(video.url),
                    icon: const Icon(Icons.play_circle_outline),
                    label: Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        _isKo ? video.titleKo : video.titleEn,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSelfCheckCard() {
    final current = _currentProgressByLesson[_selectedLessonId];
    final prev = _previousProgressByLesson[_selectedLessonId];
    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _isKo ? '성과 기록' : 'Performance record',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
            ),
            const SizedBox(height: 10),
            Text(_isKo
                ? '성공률 ${_editSuccessRate.round()}%'
                : 'Success ${_editSuccessRate.round()}%'),
            Slider(
              value: _editSuccessRate,
              min: 0,
              max: 100,
              divisions: 20,
              onChanged: (v) => setState(() => _editSuccessRate = v),
            ),
            Text(_isKo ? '연속 성공 $_editStreak회' : 'Streak $_editStreak'),
            Slider(
              value: _editStreak.toDouble(),
              min: 0,
              max: 20,
              divisions: 20,
              onChanged: (v) => setState(() => _editStreak = v.round()),
            ),
            Text(
              _isKo
                  ? '약발 성공률 ${_editWeakFootRate.round()}%'
                  : 'Weak-foot ${_editWeakFootRate.round()}%',
            ),
            Slider(
              value: _editWeakFootRate,
              min: 0,
              max: 100,
              divisions: 20,
              onChanged: (v) => setState(() => _editWeakFootRate = v),
            ),
            const SizedBox(height: 8),
            FilledButton.icon(
              onPressed: _saveSelfCheck,
              icon: const Icon(Icons.save_outlined),
              label: Text(_isKo ? '기록 저장' : 'Save record'),
            ),
            const SizedBox(height: 10),
            if (current != null)
              Text(
                _isKo
                    ? '최근: 성공률 ${current.successRate.round()}% · 연속 ${current.streak} · 약발 ${current.weakFootRate.round()}%'
                    : 'Latest: success ${current.successRate.round()}% · streak ${current.streak} · weak-foot ${current.weakFootRate.round()}%',
              ),
            if (prev != null && current != null)
              Text(
                _isKo
                    ? '이전 대비: 성공률 ${_deltaText(current.successRate - prev.successRate)} · 연속 ${_deltaText((current.streak - prev.streak).toDouble())}'
                    : 'Delta: success ${_deltaText(current.successRate - prev.successRate)} · streak ${_deltaText((current.streak - prev.streak).toDouble())}',
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildHabitMissionCard() {
    final habits = _activeHabits();
    if (habits.isEmpty) {
      return Card(
        child: ListTile(
          title: Text(_isKo ? '교정 미션' : 'Correction mission'),
          subtitle: Text(
            _isKo
                ? '진단 탭에서 현재 나쁜 습관을 먼저 체크해주세요.'
                : 'Mark current bad habits in Diagnose tab first.',
          ),
        ),
      );
    }
    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _isKo ? '교정 미션' : 'Correction mission',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
            ),
            const SizedBox(height: 10),
            ...habits.indexed.map((entry) {
              final index = entry.$1;
              final habit = entry.$2;
              final missionKey = _todayMissionKey(habit.id);
              final done = _habitMissionDone[missionKey] ?? false;
              return Padding(
                padding: EdgeInsets.only(
                    bottom: index == habits.length - 1 ? 0 : 12),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    color:
                        Theme.of(context).colorScheme.surfaceContainerHighest,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${index == 0 ? (_isKo ? '핵심 습관' : 'Core habit') : (_isKo ? '보조 습관' : 'Support habit')}: ${_isKo ? habit.labelKo : habit.labelEn}',
                        style: Theme.of(context).textTheme.labelLarge,
                      ),
                      const SizedBox(height: 4),
                      Text(_isKo ? habit.missionKo : habit.missionEn),
                      const SizedBox(height: 4),
                      Text(
                        _isKo ? habit.cueKo : habit.cueEn,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                      const SizedBox(height: 6),
                      FilledButton.tonalIcon(
                        onPressed: () => _toggleMissionDone(habit.id),
                        icon: Icon(done
                            ? Icons.check_circle
                            : Icons.radio_button_unchecked),
                        label: Text(
                          done
                              ? (_isKo ? '오늘 미션 완료' : 'Mission done today')
                              : (_isKo ? '오늘 미션 완료로 표시' : 'Mark mission done'),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildFailureLogCard() {
    final recent = _failureLogs
        .where((log) => _withinLastDays(log.at, 3))
        .toList(growable: false)
      ..sort((a, b) => b.at.compareTo(a.at));
    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _isKo ? '실패 패턴 로그' : 'Failure pattern log',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _allHabits
                  .map(
                    (habit) => OutlinedButton(
                      onPressed: () => _logFailure(habit.id),
                      child: Text(_isKo ? habit.shortKo : habit.shortEn),
                    ),
                  )
                  .toList(growable: false),
            ),
            const SizedBox(height: 8),
            if (recent.isEmpty)
              Text(
                _isKo ? '최근 3일 기록이 없습니다.' : 'No logs in last 3 days.',
                style: Theme.of(context).textTheme.bodySmall,
              )
            else
              ...recent.take(5).map((log) {
                final habit = _habitById(log.habitId);
                final date =
                    '${log.at.month}/${log.at.day} ${log.at.hour.toString().padLeft(2, '0')}:${log.at.minute.toString().padLeft(2, '0')}';
                return Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Text(
                    '• $date · ${_isKo ? habit?.labelKo ?? log.habitId : habit?.labelEn ?? log.habitId}',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                );
              }),
          ],
        ),
      ),
    );
  }

  Widget _buildWeeklyHabitSummaryCard() {
    final counts = <String, int>{for (final habit in _allHabits) habit.id: 0};
    for (final log in _failureLogs) {
      if (!_withinLastDays(log.at, 7)) continue;
      counts[log.habitId] = (counts[log.habitId] ?? 0) + 1;
    }
    final sorted = counts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final top =
        sorted.take(3).where((e) => e.value > 0).toList(growable: false);
    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _isKo ? '주간 습관 요약(7일)' : 'Weekly habit summary (7 days)',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
            ),
            const SizedBox(height: 8),
            if (top.isEmpty)
              Text(
                _isKo ? '아직 기록이 없습니다.' : 'No data yet.',
                style: Theme.of(context).textTheme.bodySmall,
              )
            else
              ...top.map((entry) {
                final habit = _habitById(entry.key);
                return Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Text(
                    '• ${_isKo ? habit?.labelKo ?? entry.key : habit?.labelEn ?? entry.key}: ${entry.value}${_isKo ? '회' : ' times'}',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                );
              }),
          ],
        ),
      ),
    );
  }

  Widget _labeledText(
    String labelKo,
    String labelEn,
    String valueKo,
    String valueEn,
  ) {
    final text = _isKo ? valueKo : valueEn;
    return RichText(
      text: TextSpan(
        style: Theme.of(context).textTheme.bodySmall,
        children: [
          TextSpan(
            text: '${_isKo ? labelKo : labelEn}: ',
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
          TextSpan(text: text),
        ],
      ),
    );
  }

  void _selectLesson(String lessonId) {
    setState(() => _selectedLessonId = lessonId);
    widget.optionRepository.setValue(_recentLessonIdKey, lessonId);
    _syncEditWithSelectedLesson();
  }

  Future<void> _openVideo(String url) async {
    final uri = Uri.tryParse(url);
    if (uri == null) return;
    final opened = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!opened && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_isKo ? '영상 열기에 실패했습니다.' : 'Failed to open video.'),
        ),
      );
    }
  }

  void _loadStoredData() {
    final customHabitRaw =
        widget.optionRepository.getValue<String>(_customHabitsKey);
    if (customHabitRaw != null && customHabitRaw.isNotEmpty) {
      try {
        final decoded = jsonDecode(customHabitRaw);
        if (decoded is List) {
          _customHabits = decoded
              .whereType<Map>()
              .map((e) => _HabitIssue.fromMap(e.cast<String, dynamic>()))
              .toList(growable: false);
          for (final habit in _customHabits) {
            _habitFlags.putIfAbsent(habit.id, () => false);
          }
        }
      } catch (_) {}
    }

    final diagnosisRaw =
        widget.optionRepository.getValue<String>(_diagnosisKey);
    if (diagnosisRaw != null && diagnosisRaw.isNotEmpty) {
      try {
        final decoded = jsonDecode(diagnosisRaw);
        if (decoded is Map<String, dynamic>) {
          _diagnosisScores = {
            for (final entry in _diagnosisScores.entries)
              entry.key: (decoded[entry.key] as num?)?.round() ?? entry.value,
          };
        }
      } catch (_) {}
    }

    _currentProgressByLesson = _loadProgressMap(_progressCurrentKey);
    _previousProgressByLesson = _loadProgressMap(_progressPreviousKey);

    final habitRaw = widget.optionRepository.getValue<String>(_habitFlagsKey);
    if (habitRaw != null && habitRaw.isNotEmpty) {
      try {
        final decoded = jsonDecode(habitRaw);
        if (decoded is Map<String, dynamic>) {
          for (final habit in _allHabits) {
            _habitFlags[habit.id] = decoded[habit.id] == true;
          }
        }
      } catch (_) {}
    }

    final questionRaw =
        widget.optionRepository.getValue<String>(_habitQuestionAnswersKey);
    if (questionRaw != null && questionRaw.isNotEmpty) {
      try {
        final decoded = jsonDecode(questionRaw);
        if (decoded is Map<String, dynamic>) {
          for (final question in _habitQuestions) {
            _questionAnswers[question.id] = decoded[question.id] == true;
          }
        }
      } catch (_) {}
    }

    final missionRaw =
        widget.optionRepository.getValue<String>(_habitMissionDoneKey);
    if (missionRaw != null && missionRaw.isNotEmpty) {
      try {
        final decoded = jsonDecode(missionRaw);
        if (decoded is Map<String, dynamic>) {
          _habitMissionDone = {
            for (final entry in decoded.entries) entry.key: entry.value == true,
          };
        }
      } catch (_) {}
    }

    final logRaw = widget.optionRepository.getValue<String>(_failureLogsKey);
    if (logRaw != null && logRaw.isNotEmpty) {
      try {
        final decoded = jsonDecode(logRaw);
        if (decoded is List) {
          _failureLogs = decoded
              .whereType<Map>()
              .map((e) => _FailureLog.fromMap(e.cast<String, dynamic>()))
              .toList(growable: false);
        }
      } catch (_) {}
    }
  }

  Map<String, _ManualProgress> _loadProgressMap(String key) {
    final raw = widget.optionRepository.getValue<String>(key);
    if (raw == null || raw.isEmpty) return <String, _ManualProgress>{};
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map<String, dynamic>) return <String, _ManualProgress>{};
      final result = <String, _ManualProgress>{};
      decoded.forEach((lessonId, value) {
        if (value is Map<String, dynamic>) {
          result[lessonId] = _ManualProgress.fromMap(value);
        }
      });
      return result;
    } catch (_) {
      return <String, _ManualProgress>{};
    }
  }

  Future<void> _saveDiagnosisScores() async {
    await widget.optionRepository
        .setValue(_diagnosisKey, jsonEncode(_diagnosisScores));
  }

  Future<void> _saveHabitFlags() async {
    await widget.optionRepository
        .setValue(_habitFlagsKey, jsonEncode(_habitFlags));
  }

  Future<void> _saveQuestionAnswers() async {
    await widget.optionRepository
        .setValue(_habitQuestionAnswersKey, jsonEncode(_questionAnswers));
  }

  void _syncEditWithSelectedLesson() {
    final current = _currentProgressByLesson[_selectedLessonId];
    if (current == null) return;
    _editSuccessRate = current.successRate;
    _editStreak = current.streak;
    _editWeakFootRate = current.weakFootRate;
  }

  Future<void> _saveSelfCheck() async {
    final lessonId = _selectedLessonId;
    final current = _ManualProgress(
      successRate: _editSuccessRate,
      streak: _editStreak,
      weakFootRate: _editWeakFootRate,
      recordedAt: DateTime.now(),
    );
    final nextCurrent =
        Map<String, _ManualProgress>.from(_currentProgressByLesson);
    final nextPrevious =
        Map<String, _ManualProgress>.from(_previousProgressByLesson);
    final oldCurrent = nextCurrent[lessonId];
    if (oldCurrent != null) {
      nextPrevious[lessonId] = oldCurrent;
    }
    nextCurrent[lessonId] = current;
    setState(() {
      _currentProgressByLesson = nextCurrent;
      _previousProgressByLesson = nextPrevious;
    });
    await widget.optionRepository.setValue(
      _progressCurrentKey,
      jsonEncode(
          nextCurrent.map((k, v) => MapEntry<String, dynamic>(k, v.toMap()))),
    );
    await widget.optionRepository.setValue(
      _progressPreviousKey,
      jsonEncode(
          nextPrevious.map((k, v) => MapEntry<String, dynamic>(k, v.toMap()))),
    );
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(_isKo ? '성과를 기록했어요.' : 'Performance saved.')),
    );
  }

  Future<void> _toggleMissionDone(String habitId) async {
    final key = _todayMissionKey(habitId);
    final next = Map<String, bool>.from(_habitMissionDone);
    next[key] = !(next[key] ?? false);
    setState(() => _habitMissionDone = next);
    await widget.optionRepository
        .setValue(_habitMissionDoneKey, jsonEncode(next));
  }

  Future<void> _logFailure(String habitId) async {
    final next = [
      ..._failureLogs,
      _FailureLog(habitId: habitId, at: DateTime.now())
    ];
    setState(() => _failureLogs = next);
    await widget.optionRepository.setValue(
      _failureLogsKey,
      jsonEncode(next.map((e) => e.toMap()).toList(growable: false)),
    );
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
          content: Text(_isKo ? '실패 패턴을 기록했어요.' : 'Failure pattern saved.')),
    );
  }

  String _skillLabel(String key) {
    switch (key) {
      case 'dribble':
        return _isKo ? '드리블' : 'Dribble';
      case 'passing':
        return _isKo ? '패스' : 'Passing';
      case 'first_touch':
        return _isKo ? '퍼스트터치' : 'First touch';
      case 'shooting':
        return _isKo ? '슈팅' : 'Shooting';
      default:
        return key;
    }
  }

  List<String> _recommendedLessonsByDiagnosis() {
    final entries = _diagnosisScores.entries.toList()
      ..sort((a, b) => a.value.compareTo(b.value));
    final weakKeys = entries.take(2).map((e) => e.key).toList(growable: false);
    final recommended = <String>{};
    for (final key in weakKeys) {
      if (key == 'dribble') recommended.add('dribble');
      if (key == 'passing' || key == 'first_touch') recommended.add('passing');
      if (key == 'shooting') recommended.add('shooting');
    }
    return recommended.toList(growable: false);
  }

  Set<String> _detectedHabitIdsByQuestion() {
    final detected = <String>{};
    for (final question in _habitQuestions) {
      if (_questionAnswers[question.id] == true) {
        detected.addAll(question.habitIds);
      }
    }
    return detected;
  }

  List<String> _recommendedHabitIdsByDiagnosis() {
    final lessonIds = _recommendedLessonsByDiagnosis();
    final result = <String>[];
    if (lessonIds.contains('dribble')) {
      result.addAll(<String>['head_down', 'long_first_touch']);
    }
    if (lessonIds.contains('passing')) {
      result.addAll(<String>['closed_body', 'wrong_plant_foot']);
    }
    if (lessonIds.contains('shooting')) {
      result.addAll(<String>['lean_back_shot', 'weak_foot_avoid']);
    }
    return result;
  }

  List<_HabitIssue> _activeHabits() {
    final detected = _detectedHabitIdsByQuestion();
    final recommended = _recommendedHabitIdsByDiagnosis().toSet();
    final counts = <String, int>{for (final h in _allHabits) h.id: 0};
    for (final log in _failureLogs) {
      if (_withinLastDays(log.at, 7)) {
        counts[log.habitId] = (counts[log.habitId] ?? 0) + 1;
      }
    }
    final scored = _allHabits.map((habit) {
      var score = 0;
      if (_habitFlags[habit.id] == true) score += 3;
      if (detected.contains(habit.id)) score += 2;
      if (recommended.contains(habit.id)) score += 1;
      score += math.min(counts[habit.id] ?? 0, 3);
      return (habit: habit, score: score);
    }).toList(growable: false)
      ..sort((a, b) => b.score.compareTo(a.score));
    final top = scored.where((entry) => entry.score > 0).take(2).toList();
    if (top.isNotEmpty) {
      return top.map((entry) => entry.habit).toList(growable: false);
    }
    return _allHabits.take(2).toList(growable: false);
  }

  _HabitIssue? _habitById(String id) {
    for (final habit in _allHabits) {
      if (habit.id == id) return habit;
    }
    return null;
  }

  Future<void> _showAddCustomHabitDialog() async {
    final titleController = TextEditingController();
    final hintController = TextEditingController();
    final missionController = TextEditingController();
    final cueController = TextEditingController();
    final added = await showDialog<_HabitIssue>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(_isKo ? '나쁜 습관 추가' : 'Add bad habit'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: titleController,
                  decoration: InputDecoration(
                    labelText: _isKo ? '습관명' : 'Habit title',
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: hintController,
                  decoration: InputDecoration(
                    labelText: _isKo ? '문제 설명' : 'Problem description',
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: missionController,
                  decoration: InputDecoration(
                    labelText: _isKo ? '교정 미션' : 'Correction mission',
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: cueController,
                  decoration: InputDecoration(
                    labelText: _isKo ? '코칭 큐' : 'Coaching cue',
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(_isKo ? '취소' : 'Cancel'),
            ),
            FilledButton(
              onPressed: () {
                final title = titleController.text.trim();
                if (title.isEmpty) return;
                final id =
                    'custom_${DateTime.now().microsecondsSinceEpoch.toString()}';
                final hint = hintController.text.trim();
                final mission = missionController.text.trim();
                final cue = cueController.text.trim();
                Navigator.of(context).pop(
                  _HabitIssue(
                    id: id,
                    labelKo: title,
                    labelEn: title,
                    shortKo: title,
                    shortEn: title,
                    hintKo: hint.isEmpty ? title : hint,
                    hintEn: hint.isEmpty ? title : hint,
                    missionKo: mission.isEmpty ? title : mission,
                    missionEn: mission.isEmpty ? title : mission,
                    cueKo: cue.isEmpty ? title : cue,
                    cueEn: cue.isEmpty ? title : cue,
                  ),
                );
              },
              child: Text(_isKo ? '추가' : 'Add'),
            ),
          ],
        );
      },
    );
    titleController.dispose();
    hintController.dispose();
    missionController.dispose();
    cueController.dispose();
    if (added == null) return;
    final next = [..._customHabits, added];
    setState(() {
      _customHabits = next;
      _habitFlags.putIfAbsent(added.id, () => false);
    });
    await widget.optionRepository.setValue(
      _customHabitsKey,
      jsonEncode(next.map((habit) => habit.toMap()).toList(growable: false)),
    );
    await _saveHabitFlags();
  }

  String _todayMissionKey(String habitId) {
    final now = DateTime.now();
    final d = '${now.year}-${now.month}-${now.day}';
    return '$habitId::$d';
  }

  bool _withinLastDays(DateTime at, int days) {
    final now = DateTime.now();
    return now.difference(at).inDays < days;
  }

  String _levelText(double avg) {
    if (avg < 2.1) return _isKo ? 'L1 기초' : 'L1 Basic';
    if (avg < 3.1) return _isKo ? 'L2 기본' : 'L2 Foundation';
    if (avg < 4.1) return _isKo ? 'L3 표준' : 'L3 Standard';
    return _isKo ? 'L4 심화' : 'L4 Advanced';
  }

  String _deltaText(double value) {
    if (value > 0) return '+${value.round()}';
    if (value < 0) return value.round().toString();
    return '0';
  }

  List<_ManualLesson> _defaultLessons() {
    return const <_ManualLesson>[
      _ManualLesson(
        id: 'dribble',
        icon: Icons.directions_run,
        titleKo: '드리블 기본기',
        titleEn: 'Dribbling Fundamentals',
        summaryKo: '낮은 중심과 짧은 터치로 볼을 보호하며 방향 전환합니다.',
        summaryEn:
            'Protect the ball with low center and short controlled touches.',
        studyCueKo: '핵심 원리: 첫 터치는 다음 행동을 위한 준비 터치여야 합니다.',
        studyCueEn: 'Core principle: first touch must prepare the next action.',
        sessions: <_ManualSession>[
          _ManualSession(
            titleKo: '세션 1. 볼 감각 워밍업 (5분)',
            titleEn: 'Session 1. Ball-feel warm-up (5 min)',
            goalKo: '발바닥/인사이드 터치 리듬 만들기',
            goalEn: 'Build touch rhythm with sole and inside contacts',
            howToKo: '양발 번갈아 1m 범위 안에서 30초씩 4세트',
            howToEn: 'Alternate both feet in 1m zone, 30s x 4 sets',
            mistakeKo: '발과 볼 거리 벌어짐',
            mistakeEn: 'Distance between foot and ball gets too large',
            successKo: '30초 동안 볼이 1m 밖으로 벗어나지 않음',
            successEn: 'Ball stays within 1m for full 30 seconds',
            demoType: _CoachDemoType.dribbleSlalom,
            videos: <_ManualVideo>[
              _ManualVideo(
                titleKo: '기본 볼터치 드리블',
                titleEn: 'Basic ball-touch dribbling',
                url: 'https://www.youtube.com/watch?v=4F3S4M9J8wM',
              ),
            ],
          ),
          _ManualSession(
            titleKo: '세션 2. 방향 전환 드리블 (12분)',
            titleEn: 'Session 2. Direction-change dribble (12 min)',
            goalKo: '턴 후 첫 2스텝 가속 습관화',
            goalEn: 'Automate first two acceleration steps after turn',
            howToKo: '콘 4개 다이아 배치 후 각 코너 턴 반복',
            howToEn: '4-cone diamond, repeat turns at each corner',
            mistakeKo: '턴 직후 시야가 아래로 고정됨',
            mistakeEn: 'Head stays down right after turn',
            successKo: '턴 후 2스텝 안에 가속',
            successEn: 'Accelerate within 2 steps after turn',
            demoType: _CoachDemoType.dribbleTurn,
            videos: <_ManualVideo>[
              _ManualVideo(
                titleKo: '방향 전환 드리블',
                titleEn: 'Direction-change dribbling',
                url: 'https://www.youtube.com/watch?v=0C2J6h6w7l4',
              ),
            ],
          ),
        ],
      ),
      _ManualLesson(
        id: 'passing',
        icon: Icons.swap_horiz,
        titleKo: '패스 정확도',
        titleEn: 'Passing Accuracy',
        summaryKo: '지지발과 임팩트 정렬로 패스 오차를 줄입니다.',
        summaryEn: 'Reduce pass error with plant-foot and impact alignment.',
        studyCueKo: '핵심 원리: 타깃을 먼저 보고 임팩트 후에도 몸을 열어둡니다.',
        studyCueEn: 'Core principle: scan target first and keep body open.',
        sessions: <_ManualSession>[
          _ManualSession(
            titleKo: '세션 1. 짧은 패스 정확도 (8분)',
            titleEn: 'Session 1. Short-pass accuracy (8 min)',
            goalKo: '짧은 거리 패스 오차 최소화',
            goalEn: 'Minimize pass error at short range',
            howToKo: '7m 타깃 2개를 번갈아 40회 패스',
            howToEn: 'Alternate 40 passes to two 7m targets',
            mistakeKo: '임팩트 시 발목 흔들림',
            mistakeEn: 'Ankle wobbles at impact',
            successKo: '40회 중 32회 이상 타깃 존 통과',
            successEn: '32+ out of 40 hit target zone',
            demoType: _CoachDemoType.passTriangle,
            videos: <_ManualVideo>[
              _ManualVideo(
                titleKo: '정확한 인사이드 패스',
                titleEn: 'Accurate inside passing',
                url: 'https://www.youtube.com/watch?v=1E0eL8g6f84',
              ),
            ],
          ),
          _ManualSession(
            titleKo: '세션 2. 원터치 템포 (7분)',
            titleEn: 'Session 2. One-touch tempo (7 min)',
            goalKo: '받고 내주는 시간 1초 이내',
            goalEn: 'Receive-and-release under 1 second',
            howToKo: '벽 패스 또는 2인 1조 20회 x 3라운드',
            howToEn: 'Wall/partner pass, 20 reps x 3 rounds',
            mistakeKo: '첫 터치가 길어져 투터치로 변함',
            mistakeEn: 'First touch too long becomes two-touch',
            successKo: '연속 10회 원터치 성공',
            successEn: '10 consecutive successful one-touch passes',
            demoType: _CoachDemoType.passOneTouch,
            videos: <_ManualVideo>[
              _ManualVideo(
                titleKo: '원터치 패스 훈련',
                titleEn: 'One-touch pass drill',
                url: 'https://www.youtube.com/watch?v=CNlQ7f1A6rU',
              ),
            ],
          ),
        ],
      ),
      _ManualLesson(
        id: 'shooting',
        icon: Icons.sports_soccer,
        titleKo: '슈팅 기본',
        titleEn: 'Shooting Basics',
        summaryKo: '임팩트 타이밍과 몸 각도 정렬로 정확도를 높입니다.',
        summaryEn: 'Increase accuracy with impact timing and body angle.',
        studyCueKo: '핵심 원리: 지지발 위치가 슈팅 방향을 결정합니다.',
        studyCueEn: 'Core principle: plant-foot position sets shot direction.',
        sessions: <_ManualSession>[
          _ManualSession(
            titleKo: '세션 1. 정지볼 임팩트 (8분)',
            titleEn: 'Session 1. Static-ball impact (8 min)',
            goalKo: '발등 임팩트 각도 고정',
            goalEn: 'Fix instep impact angle',
            howToKo: '정지볼 15회 x 2세트',
            howToEn: 'Static shots 15 reps x 2 sets',
            mistakeKo: '상체가 뒤로 젖어 공이 뜸',
            mistakeEn: 'Leaning back sends ball high',
            successKo: '30회 중 18회 목표 구역 안착',
            successEn: '18+ of 30 land in target zones',
            videos: <_ManualVideo>[
              _ManualVideo(
                titleKo: '슛 임팩트 기본',
                titleEn: 'Shooting impact basics',
                url: 'https://www.youtube.com/watch?v=X4lB8Lr4e9M',
              ),
            ],
          ),
          _ManualSession(
            titleKo: '세션 2. 1터치 후 슈팅 (10분)',
            titleEn: 'Session 2. One-touch then shoot (10 min)',
            goalKo: '첫 터치 후 2초 내 슈팅',
            goalEn: 'Shoot within 2 seconds after first touch',
            howToKo: '패스 후 전진 터치 뒤 좌우 코너 슈팅',
            howToEn: 'Receive, forward touch, then corner finish',
            mistakeKo: '터치가 길어 슈팅 타이밍 지연',
            mistakeEn: 'Touch too long delays shot timing',
            successKo: '12회 중 8회 이상 2초 내 슈팅',
            successEn: '8+ out of 12 shots within 2 seconds',
            videos: <_ManualVideo>[
              _ManualVideo(
                titleKo: '정확도 향상 슈팅 훈련',
                titleEn: 'Accuracy shooting drill',
                url: 'https://www.youtube.com/watch?v=3lM4Qm2dK8I',
              ),
            ],
          ),
        ],
      ),
    ];
  }
}

enum _ManualTab { diagnosis, study, practice, selfCheck }

class _ManualLesson {
  final String id;
  final IconData icon;
  final String titleKo;
  final String titleEn;
  final String summaryKo;
  final String summaryEn;
  final String studyCueKo;
  final String studyCueEn;
  final List<_ManualSession> sessions;

  const _ManualLesson({
    required this.id,
    required this.icon,
    required this.titleKo,
    required this.titleEn,
    required this.summaryKo,
    required this.summaryEn,
    required this.studyCueKo,
    required this.studyCueEn,
    required this.sessions,
  });
}

class _ManualSession {
  final String titleKo;
  final String titleEn;
  final String goalKo;
  final String goalEn;
  final String howToKo;
  final String howToEn;
  final String mistakeKo;
  final String mistakeEn;
  final String successKo;
  final String successEn;
  final _CoachDemoType? demoType;
  final List<_ManualVideo> videos;

  const _ManualSession({
    required this.titleKo,
    required this.titleEn,
    required this.goalKo,
    required this.goalEn,
    required this.howToKo,
    required this.howToEn,
    required this.mistakeKo,
    required this.mistakeEn,
    required this.successKo,
    required this.successEn,
    this.demoType,
    required this.videos,
  });
}

class _ManualVideo {
  final String titleKo;
  final String titleEn;
  final String url;

  const _ManualVideo({
    required this.titleKo,
    required this.titleEn,
    required this.url,
  });
}

class _ManualProgress {
  final double successRate;
  final int streak;
  final double weakFootRate;
  final DateTime recordedAt;

  const _ManualProgress({
    required this.successRate,
    required this.streak,
    required this.weakFootRate,
    required this.recordedAt,
  });

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'successRate': successRate,
      'streak': streak,
      'weakFootRate': weakFootRate,
      'recordedAt': recordedAt.toIso8601String(),
    };
  }

  factory _ManualProgress.fromMap(Map<String, dynamic> map) {
    return _ManualProgress(
      successRate: (map['successRate'] as num?)?.toDouble() ?? 0,
      streak: (map['streak'] as num?)?.round() ?? 0,
      weakFootRate: (map['weakFootRate'] as num?)?.toDouble() ?? 0,
      recordedAt: DateTime.tryParse(map['recordedAt']?.toString() ?? '') ??
          DateTime.now(),
    );
  }
}

class _FailureLog {
  final String habitId;
  final DateTime at;

  const _FailureLog({required this.habitId, required this.at});

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'habitId': habitId,
      'at': at.toIso8601String(),
    };
  }

  factory _FailureLog.fromMap(Map<String, dynamic> map) {
    return _FailureLog(
      habitId: map['habitId']?.toString() ?? '',
      at: DateTime.tryParse(map['at']?.toString() ?? '') ?? DateTime.now(),
    );
  }
}

class _HabitIssue {
  final String id;
  final String labelKo;
  final String labelEn;
  final String shortKo;
  final String shortEn;
  final String hintKo;
  final String hintEn;
  final String missionKo;
  final String missionEn;
  final String cueKo;
  final String cueEn;

  const _HabitIssue({
    required this.id,
    required this.labelKo,
    required this.labelEn,
    required this.shortKo,
    required this.shortEn,
    required this.hintKo,
    required this.hintEn,
    required this.missionKo,
    required this.missionEn,
    required this.cueKo,
    required this.cueEn,
  });

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'id': id,
      'labelKo': labelKo,
      'labelEn': labelEn,
      'shortKo': shortKo,
      'shortEn': shortEn,
      'hintKo': hintKo,
      'hintEn': hintEn,
      'missionKo': missionKo,
      'missionEn': missionEn,
      'cueKo': cueKo,
      'cueEn': cueEn,
    };
  }

  factory _HabitIssue.fromMap(Map<String, dynamic> map) {
    return _HabitIssue(
      id: map['id']?.toString() ?? 'custom',
      labelKo: map['labelKo']?.toString() ?? '',
      labelEn: map['labelEn']?.toString() ?? '',
      shortKo: map['shortKo']?.toString() ?? '',
      shortEn: map['shortEn']?.toString() ?? '',
      hintKo: map['hintKo']?.toString() ?? '',
      hintEn: map['hintEn']?.toString() ?? '',
      missionKo: map['missionKo']?.toString() ?? '',
      missionEn: map['missionEn']?.toString() ?? '',
      cueKo: map['cueKo']?.toString() ?? '',
      cueEn: map['cueEn']?.toString() ?? '',
    );
  }
}

class _HabitQuestion {
  final String id;
  final String titleKo;
  final String titleEn;
  final List<String> habitIds;

  const _HabitQuestion({
    required this.id,
    required this.titleKo,
    required this.titleEn,
    required this.habitIds,
  });
}

const List<_HabitIssue> _habitCatalog = <_HabitIssue>[
  _HabitIssue(
    id: 'head_down',
    labelKo: '시선이 계속 아래로 고정됨',
    labelEn: 'Eyes stay down too long',
    shortKo: '시선 고정',
    shortEn: 'No scanning',
    hintKo: '드리블/패스 전에 주변 확인이 부족해요.',
    hintEn: 'Limited scanning before dribble/pass.',
    missionKo: '오늘 드릴마다 2초 간격으로 앞-볼-앞 시선 전환 10회',
    missionEn: 'Do 10 scan cycles (front-ball-front) every 2 seconds.',
    cueKo: '고개를 들고 먼저 공간을 본 뒤 터치하세요.',
    cueEn: 'Lift your head, read space, then touch.',
  ),
  _HabitIssue(
    id: 'long_first_touch',
    labelKo: '첫 터치가 길어서 볼을 놓침',
    labelEn: 'First touch is too long',
    shortKo: '긴 첫 터치',
    shortEn: 'Long first touch',
    hintKo: '첫 터치가 다음 동작 준비가 아니라 탈출 터치가 됨',
    hintEn: 'First touch escapes instead of preparing next action.',
    missionKo: '첫 터치 거리 1m 이내 유지 10회 성공',
    missionEn: 'Keep first-touch distance under 1m for 10 reps.',
    cueKo: '다음 동작 방향으로 짧고 부드럽게 터치하세요.',
    cueEn: 'Use soft, short touch toward next action.',
  ),
  _HabitIssue(
    id: 'weak_foot_avoid',
    labelKo: '약발 사용을 회피함',
    labelEn: 'Avoids weak foot usage',
    shortKo: '약발 회피',
    shortEn: 'Weak-foot avoid',
    hintKo: '실전에서 선택지가 줄어듭니다.',
    hintEn: 'Reduces options in game situations.',
    missionKo: '약발 패스/터치만으로 15회 연속 수행',
    missionEn: 'Complete 15 consecutive weak-foot touches/passes.',
    cueKo: '정확도보다 반복 일관성을 우선하세요.',
    cueEn: 'Prioritize repeat consistency over power.',
  ),
  _HabitIssue(
    id: 'closed_body',
    labelKo: '몸이 닫혀서 패스 각도가 좁음',
    labelEn: 'Body stays closed and limits angle',
    shortKo: '닫힌 바디',
    shortEn: 'Closed body',
    hintKo: '받을 때 어깨 각도 때문에 시야와 선택이 제한됨',
    hintEn: 'Shoulder angle limits vision and options on receive.',
    missionKo: '받기 전 어깨 오픈 후 패스 12회 성공',
    missionEn: 'Open body before receive and complete 12 passes.',
    cueKo: '받기 전에 반 바퀴 열어두고 받으세요.',
    cueEn: 'Half-open your body before receiving.',
  ),
  _HabitIssue(
    id: 'wrong_plant_foot',
    labelKo: '지지발 위치가 불안정함',
    labelEn: 'Plant-foot position is unstable',
    shortKo: '지지발 불안정',
    shortEn: 'Plant-foot issue',
    hintKo: '패스/슈팅 방향이 흔들립니다.',
    hintEn: 'Pass/shot direction becomes inconsistent.',
    missionKo: '지지발을 공 옆 15~20cm에 두고 20회 반복',
    missionEn: 'Repeat 20 reps with plant foot 15-20cm beside the ball.',
    cueKo: '지지발 발끝은 목표를 향하게 두세요.',
    cueEn: 'Point your plant-foot toes at the target.',
  ),
  _HabitIssue(
    id: 'lean_back_shot',
    labelKo: '슈팅 때 상체가 뒤로 젖음',
    labelEn: 'Leans back while shooting',
    shortKo: '상체 뒤로',
    shortEn: 'Lean-back shot',
    hintKo: '공이 뜨거나 힘이 분산됩니다.',
    hintEn: 'Ball flies high and power leaks.',
    missionKo: '슈팅 15회 동안 코-무릎 라인 전방 유지',
    missionEn: 'Keep nose-knee line forward for 15 shots.',
    cueKo: '임팩트 순간 가슴을 공 위에 두세요.',
    cueEn: 'Keep chest over the ball at impact.',
  ),
  _HabitIssue(
    id: 'late_scan',
    labelKo: '볼 받은 뒤에만 주변을 봄',
    labelEn: 'Scans only after receiving',
    shortKo: '늦은 스캔',
    shortEn: 'Late scan',
    hintKo: '결정이 늦어집니다.',
    hintEn: 'Decision gets delayed.',
    missionKo: '받기 전 스캔 2회 후 첫 터치 12회',
    missionEn: 'Two scans before receive for 12 reps.',
    cueKo: '받기 전에 이미 다음 선택지를 정하세요.',
    cueEn: 'Decide options before the ball arrives.',
  ),
  _HabitIssue(
    id: 'flat_dribble',
    labelKo: '드리블 속도 변화가 없음',
    labelEn: 'Dribble lacks speed change',
    shortKo: '속도 단조',
    shortEn: 'Flat speed',
    hintKo: '수비를 떼어내기 어렵습니다.',
    hintEn: 'Hard to unbalance defenders.',
    missionKo: '3터치 느리게 + 2터치 빠르게 패턴 10회',
    missionEn: '10 reps of 3 slow touches + 2 fast touches.',
    cueKo: '속도 변화를 의도적으로 만드세요.',
    cueEn: 'Create deliberate tempo changes.',
  ),
  _HabitIssue(
    id: 'ball_watch_only',
    labelKo: '공만 보고 상대를 못 봄',
    labelEn: 'Watches ball only, not defender',
    shortKo: '공만 보기',
    shortEn: 'Ball-only gaze',
    hintKo: '수비 발 위치를 못 읽습니다.',
    hintEn: 'Cannot read defender foot positioning.',
    missionKo: '드릴 중 수비 발(가상) 방향 콜아웃 10회',
    missionEn: 'Call defender-foot direction 10 times during drill.',
    cueKo: '공-상대-공 순서로 시선을 배분하세요.',
    cueEn: 'Split gaze ball-defender-ball.',
  ),
  _HabitIssue(
    id: 'slow_release',
    labelKo: '볼을 오래 끌어 패스 타이밍을 놓침',
    labelEn: 'Holds ball too long and misses pass timing',
    shortKo: '패스 지연',
    shortEn: 'Late release',
    hintKo: '동료의 유리한 타이밍이 사라집니다.',
    hintEn: 'Teammate advantage timing disappears.',
    missionKo: '터치 3회 이내 패스 결정 15회',
    missionEn: 'Decide pass within 3 touches for 15 reps.',
    cueKo: '좋은 선택은 빠른 선택입니다.',
    cueEn: 'Good choice is timely choice.',
  ),
];

const List<_HabitQuestion> _habitQuestions = <_HabitQuestion>[
  _HabitQuestion(
    id: 'q_scan_before_receive',
    titleKo: '패스 받기 전에 주변을 거의 보지 않는다.',
    titleEn: 'I rarely scan before receiving the pass.',
    habitIds: <String>['head_down', 'late_scan', 'ball_watch_only'],
  ),
  _HabitQuestion(
    id: 'q_first_touch_long',
    titleKo: '첫 터치가 길어서 공을 자주 놓친다.',
    titleEn: 'My first touch is often too long.',
    habitIds: <String>['long_first_touch'],
  ),
  _HabitQuestion(
    id: 'q_weak_foot',
    titleKo: '약발로는 불안해서 거의 사용하지 않는다.',
    titleEn: 'I avoid using my weak foot.',
    habitIds: <String>['weak_foot_avoid'],
  ),
  _HabitQuestion(
    id: 'q_closed_body',
    titleKo: '공을 받을 때 몸이 닫혀 다음 선택이 적다.',
    titleEn: 'My body stays closed when receiving.',
    habitIds: <String>['closed_body'],
  ),
  _HabitQuestion(
    id: 'q_plant_foot',
    titleKo: '패스/슈팅할 때 방향이 일정하지 않다.',
    titleEn: 'My pass/shot direction is inconsistent.',
    habitIds: <String>['wrong_plant_foot'],
  ),
  _HabitQuestion(
    id: 'q_shot_lean_back',
    titleKo: '슈팅할 때 공이 자주 뜬다.',
    titleEn: 'My shots often go too high.',
    habitIds: <String>['lean_back_shot'],
  ),
  _HabitQuestion(
    id: 'q_flat_speed',
    titleKo: '드리블에서 속도 변화를 잘 주지 못한다.',
    titleEn: 'I struggle to change dribble speed.',
    habitIds: <String>['flat_dribble'],
  ),
  _HabitQuestion(
    id: 'q_release_timing',
    titleKo: '패스 타이밍을 놓쳐서 볼을 오래 끈다.',
    titleEn: 'I hold the ball too long and miss pass timing.',
    habitIds: <String>['slow_release'],
  ),
];

enum _CoachDemoType {
  dribbleSlalom,
  dribbleTurn,
  passTriangle,
  passOneTouch,
}

class _CoachMotionDemo extends StatefulWidget {
  final _CoachDemoType demoType;
  final bool isKo;

  const _CoachMotionDemo({
    required this.demoType,
    required this.isKo,
  });

  @override
  State<_CoachMotionDemo> createState() => _CoachMotionDemoState();
}

class _CoachMotionDemoState extends State<_CoachMotionDemo>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 5),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 180,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, _) => CustomPaint(
            painter: _CoachDemoPainter(
              t: _controller.value,
              demoType: widget.demoType,
              isKo: widget.isKo,
            ),
            child: const SizedBox.expand(),
          ),
        ),
      ),
    );
  }
}

class _CoachDemoPainter extends CustomPainter {
  final double t;
  final _CoachDemoType demoType;
  final bool isKo;

  const _CoachDemoPainter({
    required this.t,
    required this.demoType,
    required this.isKo,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final fieldPaint = Paint()..color = const Color(0xFF1F7A43);
    canvas.drawRect(Offset.zero & size, fieldPaint);

    final linePaint = Paint()
      ..color = const Color(0xD9FFFFFF)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.8;
    final border = RRect.fromRectAndRadius(
      Rect.fromLTWH(6, 6, size.width - 12, size.height - 12),
      const Radius.circular(10),
    );
    canvas.drawRRect(border, linePaint);
    canvas.drawLine(
      Offset(size.width * 0.5, 6),
      Offset(size.width * 0.5, size.height - 6),
      linePaint,
    );
    canvas.drawOval(
      Rect.fromCircle(
        center: Offset(size.width * 0.5, size.height * 0.5),
        radius: size.height * 0.14,
      ),
      linePaint,
    );

    final players = _playerPositions(t);
    final ball = _ballPosition(t);
    final cones = _conePositions();

    final conePaint = Paint()..color = const Color(0xFFF9A825);
    for (final cone in cones) {
      final p = Offset(cone.dx * size.width, cone.dy * size.height);
      final path = Path()
        ..moveTo(p.dx, p.dy - 8)
        ..lineTo(p.dx - 7, p.dy + 6)
        ..lineTo(p.dx + 7, p.dy + 6)
        ..close();
      canvas.drawPath(path, conePaint);
    }

    final playerPaint = Paint()..color = const Color(0xFF1976D2);
    for (final player in players) {
      final p = Offset(player.dx * size.width, player.dy * size.height);
      canvas.drawCircle(p, 8, playerPaint);
      canvas.drawCircle(
        p,
        8,
        Paint()
          ..color = Colors.white.withAlpha(180)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1,
      );
    }

    final ballP = Offset(ball.dx * size.width, ball.dy * size.height);
    canvas.drawCircle(ballP, 4.5, Paint()..color = Colors.white);
    canvas.drawCircle(
      ballP,
      4.5,
      Paint()
        ..color = Colors.black.withAlpha(100)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.8,
    );

    final label = TextPainter(
      text: TextSpan(
        text: _labelForDemo(),
        style: const TextStyle(
          color: Colors.white,
          fontSize: 11,
          fontWeight: FontWeight.w700,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout(maxWidth: size.width - 20);
    label.paint(canvas, const Offset(10, 10));
  }

  List<Offset> _playerPositions(double t) {
    switch (demoType) {
      case _CoachDemoType.dribbleSlalom:
        return <Offset>[
          Offset(0.12 + (0.78 * t), 0.5 + (0.16 * math.sin(t * math.pi * 6))),
        ];
      case _CoachDemoType.dribbleTurn:
        final u = t < 0.5 ? t * 2 : (1 - t) * 2;
        final y = t < 0.5 ? 0.72 - (u * 0.35) : 0.37 + (u * 0.35);
        return <Offset>[Offset(0.2 + (u * 0.62), y)];
      case _CoachDemoType.passTriangle:
        return const <Offset>[
          Offset(0.2, 0.72),
          Offset(0.5, 0.28),
          Offset(0.8, 0.72),
        ];
      case _CoachDemoType.passOneTouch:
        return <Offset>[
          const Offset(0.2, 0.6),
          const Offset(0.8, 0.6),
          Offset(0.5, 0.38 + 0.06 * math.sin(t * math.pi * 2)),
        ];
    }
  }

  Offset _ballPosition(double t) {
    switch (demoType) {
      case _CoachDemoType.dribbleSlalom:
        final px = 0.12 + (0.78 * t);
        final py = 0.5 + (0.16 * math.sin(t * math.pi * 6));
        return Offset(px + 0.018, py + 0.018 * math.sin(t * math.pi * 14));
      case _CoachDemoType.dribbleTurn:
        final u = t < 0.5 ? t * 2 : (1 - t) * 2;
        final y = t < 0.5 ? 0.72 - (u * 0.35) : 0.37 + (u * 0.35);
        return Offset(0.2 + (u * 0.62) + 0.015, y + 0.015);
      case _CoachDemoType.passTriangle:
        if (t < 0.33) {
          return _lerp(
              const Offset(0.2, 0.72), const Offset(0.5, 0.28), t / 0.33);
        }
        if (t < 0.66) {
          return _lerp(
            const Offset(0.5, 0.28),
            const Offset(0.8, 0.72),
            (t - 0.33) / 0.33,
          );
        }
        return _lerp(
          const Offset(0.8, 0.72),
          const Offset(0.2, 0.72),
          (t - 0.66) / 0.34,
        );
      case _CoachDemoType.passOneTouch:
        final phase = (t * 4).floor() % 4;
        final local = (t * 4) % 1.0;
        if (phase == 0) {
          return _lerp(const Offset(0.2, 0.6), const Offset(0.8, 0.6), local);
        }
        if (phase == 1) {
          return _lerp(const Offset(0.8, 0.6), const Offset(0.5, 0.4), local);
        }
        if (phase == 2) {
          return _lerp(const Offset(0.5, 0.4), const Offset(0.2, 0.6), local);
        }
        return _lerp(const Offset(0.2, 0.6), const Offset(0.5, 0.4), local);
    }
  }

  List<Offset> _conePositions() {
    switch (demoType) {
      case _CoachDemoType.dribbleSlalom:
        return const <Offset>[
          Offset(0.28, 0.32),
          Offset(0.42, 0.68),
          Offset(0.56, 0.32),
          Offset(0.7, 0.68),
        ];
      case _CoachDemoType.dribbleTurn:
        return const <Offset>[Offset(0.2, 0.72), Offset(0.82, 0.36)];
      case _CoachDemoType.passTriangle:
      case _CoachDemoType.passOneTouch:
        return const <Offset>[];
    }
  }

  Offset _lerp(Offset a, Offset b, double t) =>
      Offset(a.dx + (b.dx - a.dx) * t, a.dy + (b.dy - a.dy) * t);

  String _labelForDemo() {
    switch (demoType) {
      case _CoachDemoType.dribbleSlalom:
        return isKo ? '드리블 슬라럼' : 'Dribble slalom';
      case _CoachDemoType.dribbleTurn:
        return isKo ? '턴 후 가속' : 'Turn and accelerate';
      case _CoachDemoType.passTriangle:
        return isKo ? '삼각 패스' : 'Triangle passing';
      case _CoachDemoType.passOneTouch:
        return isKo ? '원터치 연계' : 'One-touch sequence';
    }
  }

  @override
  bool shouldRepaint(covariant _CoachDemoPainter oldDelegate) {
    return oldDelegate.t != t ||
        oldDelegate.demoType != demoType ||
        oldDelegate.isKo != isKo;
  }
}
