import 'dart:convert';

import 'package:flutter/material.dart';

import '../../application/backup_service.dart';
import '../../application/locale_service.dart';
import '../../application/settings_service.dart';
import '../../application/training_service.dart';
import '../../domain/repositories/option_repository.dart';
import '../widgets/app_background.dart';

class CoachLessonScreen extends StatefulWidget {
  final OptionRepository optionRepository;
  final TrainingService? trainingService;
  final LocaleService? localeService;
  final SettingsService? settingsService;
  final BackupService? driveBackupService;

  const CoachLessonScreen({
    super.key,
    required this.optionRepository,
    this.trainingService,
    this.localeService,
    this.settingsService,
    this.driveBackupService,
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
  DateTime? _lastSavedAt;
  int _currentFlowStep = 0;
  static const List<_FlowStepMeta> _flowSteps = <_FlowStepMeta>[
    _FlowStepMeta(
      index: 0,
      titleKo: '찾기',
      titleEn: 'Find',
    ),
    _FlowStepMeta(
      index: 1,
      titleKo: '실행',
      titleEn: 'Do',
    ),
    _FlowStepMeta(
      index: 2,
      titleKo: '결과',
      titleEn: 'Result',
    ),
  ];

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
    final activeStep = _flowSteps[_currentFlowStep];
    return Scaffold(
      body: AppBackground(
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                child: Column(
                  children: [
                    _buildIntroCard(),
                    const SizedBox(height: 12),
                    _buildFlowNavigator(),
                  ],
                ),
              ),
              Expanded(
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 220),
                  child: ListView(
                    key: ValueKey<int>(_currentFlowStep),
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                    children: _buildActiveStepWidgets(activeStep.index),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFlowNavigator() {
    return SizedBox(
      height: 40,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemBuilder: (context, index) {
          final step = _flowSteps[index];
          final selected = index == _currentFlowStep;
          return ChoiceChip(
            selected: selected,
            label: Text(_isKo ? step.titleKo : step.titleEn),
            onSelected: (_) => setState(() => _currentFlowStep = index),
          );
        },
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemCount: _flowSteps.length,
      ),
    );
  }

  List<Widget> _buildActiveStepWidgets(int step) {
    if (step == 0) {
      return [
        _buildFocusHabitCard(),
        const SizedBox(height: 12),
        _buildDiagnosisCard(),
      ];
    }
    if (step == 1) {
      return [
        _buildHabitMissionCard(),
        const SizedBox(height: 12),
        _buildFailureLogCard(),
      ];
    }
    return [
      _buildSelfCheckCard(),
      const SizedBox(height: 12),
      _buildMaintainCard(),
      const SizedBox(height: 12),
      _buildWeeklyHabitSummaryCard(),
    ];
  }

  Widget _buildIntroCard() {
    final weekDone = _habitMissionDone.entries
        .where((entry) => entry.value && _isMissionInLastDays(entry.key, 7))
        .length;
    final stars = weekDone.clamp(0, 5);
    final progress = (stars / 5).toDouble();
    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 22,
                  backgroundColor:
                      Theme.of(context).colorScheme.primaryContainer,
                  child: Icon(
                    Icons.emoji_events_outlined,
                    color: Theme.of(context).colorScheme.onPrimaryContainer,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    _isKo
                        ? '오늘의 축구 미션: 나쁜 습관 1개만 고치자'
                        : 'Today mission: fix just one bad habit',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                ),
                if (_lastSavedAt != null)
                  Chip(
                    visualDensity: VisualDensity.compact,
                    label: Text(_isKo ? '저장됨' : 'Saved'),
                  ),
              ],
            ),
            const SizedBox(height: 10),
            Text(_isKo ? '별 $stars/5' : 'Stars $stars/5'),
            const SizedBox(height: 6),
            LinearProgressIndicator(value: progress),
          ],
        ),
      ),
    );
  }

  Widget _buildQuestionCard(_HabitQuestion question) {
    final isYes = _questionAnswers[question.id] == true;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(_isKo ? question.titleKo : question.titleEn),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: FilledButton.tonal(
                  style: FilledButton.styleFrom(
                    backgroundColor: isYes
                        ? Theme.of(context).colorScheme.primaryContainer
                        : null,
                  ),
                  onPressed: () async {
                    setState(() => _questionAnswers[question.id] = true);
                    await _saveQuestionAnswers();
                  },
                  child: Text(_isKo ? '맞아요' : 'Yes'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton(
                  onPressed: () async {
                    setState(() => _questionAnswers[question.id] = false);
                    await _saveQuestionAnswers();
                  },
                  style: OutlinedButton.styleFrom(
                    backgroundColor: isYes
                        ? Theme.of(context).colorScheme.surface
                        : Theme.of(context).colorScheme.primaryContainer,
                  ),
                  child: Text(_isKo ? '괜찮아요' : 'No'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSkillMoodSelector() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: _diagnosisScores.entries.map((entry) {
        return FilterChip(
          selected: entry.value >= 4,
          label: Text(
            _isKo
                ? '${_skillLabel(entry.key)} 자신있음'
                : '${_skillLabel(entry.key)} confident',
          ),
          onSelected: (selected) {
            setState(() => _diagnosisScores[entry.key] = selected ? 4 : 2);
            _saveDiagnosisScores();
          },
        );
      }).toList(growable: false),
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
              _isKo ? '탐정 놀이: 어디가 어려웠을까?' : 'Detective game: what was hard?',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
            ),
            const SizedBox(height: 8),
            ..._habitQuestions.map(_buildQuestionCard),
            const SizedBox(height: 10),
            Chip(label: Text(_isKo ? '레벨 $level' : 'Level $level')),
            const SizedBox(height: 10),
            ExpansionTile(
              tilePadding: EdgeInsets.zero,
              title: Text(
                _isKo ? '코치 고급 설정(보호자용)' : 'Coach advanced setup',
              ),
              subtitle: Text(
                _isKo
                    ? '${_allHabits.length}/$_maxHabitCount 등록됨'
                    : '${_allHabits.length}/$_maxHabitCount registered',
              ),
              children: [
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    _isKo ? '기술 자신감 빠르게 체크' : 'Quick confidence check',
                  ),
                ),
                const SizedBox(height: 6),
                _buildSkillMoodSelector(),
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
                Align(
                  alignment: Alignment.centerLeft,
                  child: OutlinedButton.icon(
                    onPressed: _allHabits.length >= _maxHabitCount
                        ? null
                        : _showAddCustomHabitDialog,
                    icon: const Icon(Icons.add_circle_outline),
                    label: Text(
                      _isKo ? '나쁜 습관 직접 추가' : 'Add custom bad habit',
                    ),
                  ),
                ),
              ],
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
                _isKo ? '먼저 질문에 답해줘!' : 'Answer questions first!',
                style: Theme.of(context).textTheme.bodySmall,
              )
            : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _isKo ? '오늘의 타깃 습관' : 'Today target habit',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    _isKo ? top.labelKo : top.labelEn,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 10),
                  FilledButton.icon(
                    onPressed: () => setState(() => _currentFlowStep = 1),
                    icon: const Icon(Icons.sports_soccer),
                    label: Text(_isKo ? '이 습관 고치기 시작' : 'Start fixing this'),
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
          title: Text(_isKo ? '미션 가이드' : 'Mission guide'),
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
              _isKo ? '오늘의 미션 카드' : 'Today mission card',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
            ),
            const SizedBox(height: 10),
            _buildMissionHabitCard(habits.first, true),
            if (habits.length > 1) ...[
              const SizedBox(height: 8),
              ExpansionTile(
                tilePadding: EdgeInsets.zero,
                title: Text(_isKo ? '보너스 미션 보기' : 'Show bonus mission'),
                children: [
                  _buildMissionHabitCard(habits[1], false),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildMissionHabitCard(_HabitIssue habit, bool isCore) {
    final missionKey = _todayMissionKey(habit.id);
    final done = _habitMissionDone[missionKey] ?? false;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${isCore ? (_isKo ? '핵심 미션' : 'Core mission') : (_isKo ? '보너스 미션' : 'Bonus mission')}: ${_isKo ? habit.labelKo : habit.labelEn}',
            style: Theme.of(context).textTheme.labelLarge,
          ),
          const SizedBox(height: 4),
          Text(_isKo ? habit.missionKo : habit.missionEn),
          const SizedBox(height: 6),
          FilledButton.tonalIcon(
            onPressed: () => _toggleMissionDone(habit.id),
            icon:
                Icon(done ? Icons.check_circle : Icons.radio_button_unchecked),
            label: Text(
              done
                  ? (_isKo ? '완료했어!' : 'Done!')
                  : (_isKo ? '완료 체크' : 'Mark done'),
            ),
          ),
        ],
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
              _isKo ? '오늘 점검하기' : 'Today check-in',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                FilledButton.tonal(
                  onPressed: () async {
                    setState(() {
                      _editSuccessRate = 30;
                      _editStreak = 2;
                      _editWeakFootRate = 20;
                    });
                    await _saveSelfCheck();
                  },
                  child: Text(_isKo ? '어려웠어' : 'Hard'),
                ),
                FilledButton.tonal(
                  onPressed: () async {
                    setState(() {
                      _editSuccessRate = 60;
                      _editStreak = 6;
                      _editWeakFootRate = 45;
                    });
                    await _saveSelfCheck();
                  },
                  child: Text(_isKo ? '보통이야' : 'Okay'),
                ),
                FilledButton.tonal(
                  onPressed: () async {
                    setState(() {
                      _editSuccessRate = 85;
                      _editStreak = 12;
                      _editWeakFootRate = 70;
                    });
                    await _saveSelfCheck();
                  },
                  child: Text(_isKo ? '잘했어' : 'Great'),
                ),
              ],
            ),
            const SizedBox(height: 8),
            ExpansionTile(
              tilePadding: EdgeInsets.zero,
              title: Text(_isKo ? '세부 점수 조정' : 'Detailed score'),
              children: [
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
              ],
            ),
            const SizedBox(height: 8),
            FilledButton.icon(
              onPressed: _saveSelfCheck,
              icon: const Icon(Icons.save_outlined),
              label: Text(_isKo ? '점검 결과 저장' : 'Save check result'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFailureLogCard() {
    final active = _activeHabits();
    final quickHabits =
        active.isNotEmpty ? active : _allHabits.take(4).toList();
    final extraHabits = _allHabits
        .where((habit) => !quickHabits.any((q) => q.id == habit.id))
        .toList(growable: false);
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
              _isKo ? '어떤 실수를 했을까?' : 'What mistake happened?',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: quickHabits
                  .map(
                    (habit) => OutlinedButton(
                      onPressed: () => _logFailure(habit.id),
                      child: Text(_isKo ? habit.shortKo : habit.shortEn),
                    ),
                  )
                  .toList(growable: false),
            ),
            if (extraHabits.isNotEmpty)
              ExpansionTile(
                tilePadding: EdgeInsets.zero,
                title: Text(_isKo ? '다른 실수도 기록하기' : 'Log other mistakes'),
                children: [
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: extraHabits
                        .map(
                          (habit) => OutlinedButton(
                            onPressed: () => _logFailure(habit.id),
                            child: Text(_isKo ? habit.shortKo : habit.shortEn),
                          ),
                        )
                        .toList(growable: false),
                  ),
                ],
              ),
            const SizedBox(height: 8),
            if (recent.isEmpty)
              Text(
                _isKo ? '최근 기록 없음' : 'No recent log',
                style: Theme.of(context).textTheme.bodySmall,
              )
            else
              Text(
                _isKo
                    ? '최근 3일 실수 ${recent.length}회'
                    : '${recent.length} mistakes in 3 days',
                style: Theme.of(context).textTheme.bodySmall,
              ),
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
    final stars = missionDoneInWeek.clamp(0, 5);
    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _isKo ? '성장 결과' : 'Growth result',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              _isKo ? '이번 주 별: $stars/5' : 'Stars this week: $stars/5',
            ),
            const SizedBox(height: 4),
            Text(
              _isKo ? '판정: ${status.labelKo}' : 'Status: ${status.labelEn}',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: status.color,
                  ),
            ),
            const SizedBox(height: 10),
            FilledButton.tonalIcon(
              onPressed: () => setState(() => _currentFlowStep = 0),
              icon: const Icon(Icons.refresh),
              label: Text(_isKo ? '다음 주 다시 시작' : 'Restart next week'),
            ),
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
    _markSaved();
  }

  Future<void> _saveHabitFlags() async {
    await widget.optionRepository
        .setValue(_habitFlagsKey, jsonEncode(_habitFlags));
    _markSaved();
  }

  Future<void> _saveQuestionAnswers() async {
    await widget.optionRepository
        .setValue(_habitQuestionAnswersKey, jsonEncode(_questionAnswers));
    _markSaved();
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
    _markSaved();

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
    _markSaved();
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
    _markSaved();
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

  void _markSaved() {
    if (!mounted) return;
    setState(() => _lastSavedAt = DateTime.now());
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

  _MaintainStatus _maintainStatus() {
    if (_currentProgress == null || _previousProgress == null) {
      return _MaintainStatus(
        labelKo: '데이터 부족',
        labelEn: 'Not enough data',
        color: Theme.of(context).colorScheme.outline,
      );
    }
    final delta =
        _currentProgress!.successRate - _previousProgress!.successRate;
    if (delta >= 5) {
      return const _MaintainStatus(
        labelKo: '개선',
        labelEn: 'Improving',
        color: Colors.green,
      );
    }
    if (delta <= -5) {
      return const _MaintainStatus(
        labelKo: '악화',
        labelEn: 'Regressing',
        color: Colors.red,
      );
    }
    return const _MaintainStatus(
      labelKo: '유지',
      labelEn: 'Stable',
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
  final Color color;

  const _MaintainStatus({
    required this.labelKo,
    required this.labelEn,
    required this.color,
  });
}

class _FlowStepMeta {
  final int index;
  final String titleKo;
  final String titleEn;

  const _FlowStepMeta({
    required this.index,
    required this.titleKo,
    required this.titleEn,
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
