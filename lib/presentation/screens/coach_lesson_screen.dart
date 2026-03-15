import 'dart:convert';

import 'package:flutter/material.dart';

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

  static const String _diagnosisKey = 'manual_diagnosis_scores_v1';
  static const String _habitFlagsKey = 'manual_habit_flags_v1';
  static const String _habitMissionDoneKey = 'manual_habit_mission_done_v1';
  static const String _failureLogsKey = 'manual_failure_logs_v1';
  static const String _customHabitsKey = 'manual_custom_habits_v1';
  static const String _habitQuestionAnswersKey = 'manual_habit_questions_v1';
  static const String _progressCurrentKey = 'manual_progress_current_global_v1';
  static const String _progressPreviousKey =
      'manual_progress_previous_global_v1';

  final Map<String, int> _diagnosisScores = <String, int>{
    'dribble': 3,
    'passing': 3,
    'first_touch': 3,
    'shooting': 3,
  };

  final Map<String, bool> _habitFlags = <String, bool>{};
  final Map<String, bool> _questionAnswers = <String, bool>{
    for (final q in _habitQuestions) q.id: false,
  };

  List<_HabitIssue> _customHabits = <_HabitIssue>[];
  Map<String, bool> _habitMissionDone = <String, bool>{};
  List<_FailureLog> _failureLogs = <_FailureLog>[];

  _HabitProgress? _currentProgress;
  _HabitProgress? _previousProgress;
  double _editSuccessRate = 60;
  int _editStreak = 6;
  double _editWeakFootRate = 40;

  bool get _isKo => Localizations.localeOf(context).languageCode == 'ko';
  List<_HabitIssue> get _allHabits => [..._habitCatalog, ..._customHabits];

  @override
  void initState() {
    super.initState();
    for (final habit in _habitCatalog) {
      _habitFlags[habit.id] = false;
    }
    _loadStoredData();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isKo ? '나쁜 습관 교정 코치' : 'Bad Habit Correction Coach'),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        children: [
          _buildIntroCard(),
          const SizedBox(height: 12),
          _buildFlowStepHeader(
            step: 1,
            titleKo: '발견',
            titleEn: 'Discover',
            subtitleKo: '지금 가장 먼저 고칠 습관을 찾습니다.',
            subtitleEn: 'Find the one habit to fix first.',
          ),
          const SizedBox(height: 8),
          _buildDiagnosisCard(),
          const SizedBox(height: 12),
          _buildFocusHabitCard(),
          const SizedBox(height: 12),
          _buildFlowStepHeader(
            step: 2,
            titleKo: '교정',
            titleEn: 'Correct',
            subtitleKo: '오늘 할 1개 미션에 집중합니다.',
            subtitleEn: 'Focus on one mission for today.',
          ),
          const SizedBox(height: 8),
          _buildHabitMissionCard(),
          const SizedBox(height: 12),
          _buildFlowStepHeader(
            step: 3,
            titleKo: '검증',
            titleEn: 'Verify',
            subtitleKo: '수행 전/후 지표를 기록하고 실패 패턴을 남깁니다.',
            subtitleEn: 'Record before/after metrics and log failure patterns.',
          ),
          const SizedBox(height: 8),
          _buildSelfCheckCard(),
          const SizedBox(height: 12),
          _buildFailureLogCard(),
          const SizedBox(height: 12),
          _buildFlowStepHeader(
            step: 4,
            titleKo: '유지',
            titleEn: 'Maintain',
            subtitleKo: '7일 기준으로 유지/개선/악화를 판정합니다.',
            subtitleEn: 'Judge keep/improve/regress based on 7 days.',
          ),
          const SizedBox(height: 8),
          _buildMaintainCard(),
          const SizedBox(height: 12),
          _buildWeeklyHabitSummaryCard(),
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
                Icons.psychology_alt_outlined,
                color: Theme.of(context).colorScheme.onPrimaryContainer,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                _isKo
                    ? '루프: 발견 → 교정 → 검증 → 유지. 지금 고칠 습관 1개에 집중하세요.'
                    : 'Loop: Discover -> Correct -> Verify -> Maintain. Focus on one habit now.',
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFlowStepHeader({
    required int step,
    required String titleKo,
    required String titleEn,
    required String subtitleKo,
    required String subtitleEn,
  }) {
    return Row(
      children: [
        CircleAvatar(
          radius: 12,
          child: Text(
            '$step',
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _isKo ? titleKo : titleEn,
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
              ),
              Text(
                _isKo ? subtitleKo : subtitleEn,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDiagnosisCard() {
    final avg = _diagnosisScores.values.fold<int>(0, (a, b) => a + b) / 4.0;
    final level = _levelText(avg);

    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _isKo ? '셀프 진단' : 'Self diagnosis',
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

  Widget _buildFocusHabitCard() {
    final habits = _activeHabits();
    final top = habits.isNotEmpty ? habits.first : null;
    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
        child: top == null
            ? Text(
                _isKo
                    ? '진단 문항 또는 습관 체크를 입력하면 핵심 습관을 자동으로 제시합니다.'
                    : 'Once you fill diagnosis/checks, your top habit appears here.',
                style: Theme.of(context).textTheme.bodySmall,
              )
            : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _isKo ? '지금의 핵심 습관 1개' : 'Your top habit now',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    _isKo ? top.labelKo : top.labelEn,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _isKo ? _habitImpactKo(top.id) : _habitImpactEn(top.id),
                    style: Theme.of(context).textTheme.bodySmall,
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
          title: Text(_isKo ? '교정 가이드' : 'Correction guide'),
          subtitle: Text(
            _isKo
                ? '진단 문항/습관 체크를 먼저 입력해 주세요.'
                : 'Complete diagnosis questions/habit checks first.',
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
              _isKo ? '오늘의 교정 가이드' : 'Today\'s correction guide',
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
                      const SizedBox(height: 2),
                      Text(
                        _isKo
                            ? '실패 시 대체동작: ${_fallbackCueKo(habit.id)}'
                            : 'Fallback when failed: ${_fallbackCueEn(habit.id)}',
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

  Widget _buildSelfCheckCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _isKo ? '교정 진행도 기록' : 'Correction progress record',
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
              label: Text(_isKo ? '검증 저장' : 'Save verification'),
            ),
            const SizedBox(height: 10),
            if (_currentProgress != null)
              Text(
                _isKo
                    ? '최근: 성공률 ${_currentProgress!.successRate.round()}% · 연속 ${_currentProgress!.streak} · 약발 ${_currentProgress!.weakFootRate.round()}%'
                    : 'Latest: success ${_currentProgress!.successRate.round()}% · streak ${_currentProgress!.streak} · weak-foot ${_currentProgress!.weakFootRate.round()}%',
              ),
            if (_previousProgress != null && _currentProgress != null)
              Text(
                _isKo
                    ? '이전 대비: 성공률 ${_deltaText(_currentProgress!.successRate - _previousProgress!.successRate)} · 연속 ${_deltaText((_currentProgress!.streak - _previousProgress!.streak).toDouble())}'
                    : 'Delta: success ${_deltaText(_currentProgress!.successRate - _previousProgress!.successRate)} · streak ${_deltaText((_currentProgress!.streak - _previousProgress!.streak).toDouble())}',
              ),
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

  Widget _buildMaintainCard() {
    final status = _maintainStatus();
    final missionDoneInWeek = _habitMissionDone.entries
        .where((entry) => entry.value && _isMissionInLastDays(entry.key, 7))
        .length;
    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _isKo ? '유지 판정' : 'Maintain status',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              _isKo
                  ? '최근 7일 미션 완료: $missionDoneInWeek회'
                  : 'Mission done in 7 days: $missionDoneInWeek',
            ),
            const SizedBox(height: 4),
            Text(
              _isKo ? '판정: ${status.labelKo}' : 'Status: ${status.labelEn}',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: status.color,
                  ),
            ),
            const SizedBox(height: 4),
            Text(_isKo ? status.guideKo : status.guideEn),
          ],
        ),
      ),
    );
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
          for (final entry in _diagnosisScores.entries) {
            _diagnosisScores[entry.key] =
                (decoded[entry.key] as num?)?.round() ?? entry.value;
          }
        }
      } catch (_) {}
    }

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

    _currentProgress = _loadProgress(_progressCurrentKey);
    _previousProgress = _loadProgress(_progressPreviousKey);
    if (_currentProgress != null) {
      _editSuccessRate = _currentProgress!.successRate;
      _editStreak = _currentProgress!.streak;
      _editWeakFootRate = _currentProgress!.weakFootRate;
    }
  }

  _HabitProgress? _loadProgress(String key) {
    final raw = widget.optionRepository.getValue<String>(key);
    if (raw == null || raw.isEmpty) return null;
    try {
      final decoded = jsonDecode(raw);
      if (decoded is Map<String, dynamic>) {
        return _HabitProgress.fromMap(decoded);
      }
      return null;
    } catch (_) {
      return null;
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

  Future<void> _saveSelfCheck() async {
    final current = _HabitProgress(
      successRate: _editSuccessRate,
      streak: _editStreak,
      weakFootRate: _editWeakFootRate,
      recordedAt: DateTime.now(),
    );

    final previous = _currentProgress;
    setState(() {
      _previousProgress = previous;
      _currentProgress = current;
    });

    await widget.optionRepository
        .setValue(_progressCurrentKey, jsonEncode(current.toMap()));
    if (previous != null) {
      await widget.optionRepository
          .setValue(_progressPreviousKey, jsonEncode(previous.toMap()));
    }

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(_isKo ? '진행도를 기록했어요.' : 'Progress saved.')),
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
    final entries = _diagnosisScores.entries.toList()
      ..sort((a, b) => a.value.compareTo(b.value));
    final weakKeys = entries.take(2).map((e) => e.key).toList(growable: false);

    final result = <String>[];
    for (final key in weakKeys) {
      if (key == 'dribble') {
        result
            .addAll(<String>['head_down', 'long_first_touch', 'flat_dribble']);
      }
      if (key == 'passing' || key == 'first_touch') {
        result.addAll(<String>['closed_body', 'late_scan', 'slow_release']);
      }
      if (key == 'shooting') {
        result.addAll(
            <String>['lean_back_shot', 'weak_foot_avoid', 'wrong_plant_foot']);
      }
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
      score += (counts[habit.id] ?? 0).clamp(0, 3);
      return (habit: habit, score: score);
    }).toList(growable: false)
      ..sort((a, b) => b.score.compareTo(a.score));

    final top = scored
        .where((entry) => entry.score > 0)
        .take(2)
        .toList(growable: false);
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

                final id = 'custom_${DateTime.now().microsecondsSinceEpoch}';
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
    return '$habitId::${now.year}-${now.month}-${now.day}';
  }

  bool _withinLastDays(DateTime at, int days) {
    return DateTime.now().difference(at).inDays < days;
  }

  bool _isMissionInLastDays(String missionKey, int days) {
    final parts = missionKey.split('::');
    if (parts.length != 2) return false;
    final date = DateTime.tryParse(parts[1]);
    if (date == null) return false;
    return _withinLastDays(date, days);
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

  String _habitImpactKo(String id) {
    switch (id) {
      case 'head_down':
      case 'late_scan':
        return '주변 인식이 늦어 패스 선택이 늦어집니다.';
      case 'long_first_touch':
        return '첫 터치 이후 볼 소유 유지율이 떨어집니다.';
      case 'closed_body':
      case 'slow_release':
        return '패스 각도와 타이밍이 줄어 공격 전개가 느려집니다.';
      case 'lean_back_shot':
      case 'wrong_plant_foot':
        return '슈팅 정확도가 떨어져 득점 확률이 낮아집니다.';
      default:
        return '반복될수록 경기 중 의사결정 품질이 떨어집니다.';
    }
  }

  String _habitImpactEn(String id) {
    switch (id) {
      case 'head_down':
      case 'late_scan':
        return 'Late scanning delays passing decisions.';
      case 'long_first_touch':
        return 'Ball retention drops after first touch.';
      case 'closed_body':
      case 'slow_release':
        return 'Passing angle/timing shrink and buildup slows down.';
      case 'lean_back_shot':
      case 'wrong_plant_foot':
        return 'Shooting accuracy drops and scoring chance falls.';
      default:
        return 'Repeated habit lowers game decision quality.';
    }
  }

  String _fallbackCueKo(String id) {
    switch (id) {
      case 'head_down':
      case 'late_scan':
        return '터치 전 멈추고 1초 스캔 후 재시도';
      case 'long_first_touch':
        return '터치 강도를 절반으로 줄여 5회 반복';
      case 'weak_foot_avoid':
        return '약발만으로 짧은 터치 10회 먼저 수행';
      case 'closed_body':
        return '받기 전 어깨를 먼저 열고 제자리 패스';
      default:
        return '동작 속도를 낮추고 정확도 우선으로 재시도';
    }
  }

  String _fallbackCueEn(String id) {
    switch (id) {
      case 'head_down':
      case 'late_scan':
        return 'Pause, 1-sec scan, then retry';
      case 'long_first_touch':
        return 'Cut touch power in half for 5 reps';
      case 'weak_foot_avoid':
        return 'Do 10 short weak-foot reps first';
      case 'closed_body':
        return 'Open shoulder before receive, then retry pass';
      default:
        return 'Slow down and retry with accuracy first';
    }
  }

  _MaintainStatus _maintainStatus() {
    if (_currentProgress == null || _previousProgress == null) {
      return _MaintainStatus(
        labelKo: '데이터 부족',
        labelEn: 'Not enough data',
        guideKo: '검증을 2회 이상 저장하면 판정을 제공합니다.',
        guideEn: 'Save verification 2+ times to get status.',
        color: Theme.of(context).colorScheme.outline,
      );
    }
    final delta =
        _currentProgress!.successRate - _previousProgress!.successRate;
    if (delta >= 5) {
      return const _MaintainStatus(
        labelKo: '개선',
        labelEn: 'Improving',
        guideKo: '현 난이도를 3일 유지 후 다음 난이도로 올리세요.',
        guideEn: 'Keep this level for 3 days, then increase difficulty.',
        color: Colors.green,
      );
    }
    if (delta <= -5) {
      return const _MaintainStatus(
        labelKo: '악화',
        labelEn: 'Regressing',
        guideKo: '이전 난이도로 2일 롤백하고 핵심 미션 1개만 수행하세요.',
        guideEn: 'Rollback for 2 days and do only one core mission.',
        color: Colors.red,
      );
    }
    return const _MaintainStatus(
      labelKo: '유지',
      labelEn: 'Stable',
      guideKo: '현재 강도로 반복하면서 실패 패턴을 줄이세요.',
      guideEn: 'Keep current intensity and reduce failure patterns.',
      color: Colors.orange,
    );
  }
}

class _HabitProgress {
  final double successRate;
  final int streak;
  final double weakFootRate;
  final DateTime recordedAt;

  const _HabitProgress({
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

  factory _HabitProgress.fromMap(Map<String, dynamic> map) {
    return _HabitProgress(
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

class _MaintainStatus {
  final String labelKo;
  final String labelEn;
  final String guideKo;
  final String guideEn;
  final Color color;

  const _MaintainStatus({
    required this.labelKo,
    required this.labelEn,
    required this.guideKo,
    required this.guideEn,
    required this.color,
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
    habitIds: <String>['head_down', 'late_scan'],
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
