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
  static const String _recentLessonIdKey = 'coach_recent_lesson_id_v1';
  static const String _diagnosisKey = 'manual_diagnosis_scores_v1';
  static const String _progressCurrentKey = 'manual_progress_current_v1';
  static const String _progressPreviousKey = 'manual_progress_previous_v1';

  late final List<_CoachLesson> _lessons;
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

  double _editSuccessRate = 60;
  int _editStreak = 6;
  double _editWeakFootRate = 40;

  bool get _isKo => Localizations.localeOf(context).languageCode == 'ko';

  _CoachLesson get _selectedLesson =>
      _lessons.firstWhere((lesson) => lesson.id == _selectedLessonId);

  @override
  void initState() {
    super.initState();
    _lessons = _defaultLessons();
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
      appBar: AppBar(
        title: Text(_isKo ? '축구 교습서' : 'Football Manual'),
      ),
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
                    ? 'U12 자습서: 진단 → 학습 → 따라하기 → 자가체크 순서로 스스로 성장하세요.'
                    : 'U12 self-study: Diagnose -> Learn -> Practice -> Self-check.',
                style: Theme.of(context).textTheme.bodyMedium,
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
                    Text(
                      '${_skillLabel(entry.key)}: ${entry.value}/5',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    Slider(
                      value: entry.value.toDouble(),
                      min: 1,
                      max: 5,
                      divisions: 4,
                      label: entry.value.toString(),
                      onChanged: (v) {
                        setState(() {
                          _diagnosisScores[entry.key] = v.round();
                        });
                        _saveDiagnosisScores();
                      },
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              _isKo ? '현재 레벨: $level' : 'Current level: $level',
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const SizedBox(height: 6),
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
    _CoachSession session, {
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
            Text(
              _isKo
                  ? '성공률 ${_editSuccessRate.round()}%'
                  : 'Success ${_editSuccessRate.round()}%',
            ),
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
                    ? '최근 기록: 성공률 ${current.successRate.round()}% · 연속 ${current.streak} · 약발 ${current.weakFootRate.round()}%'
                    : 'Latest: success ${current.successRate.round()}% · streak ${current.streak} · weak-foot ${current.weakFootRate.round()}%',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            if (prev != null && current != null)
              Text(
                _isKo
                    ? '이전 대비: 성공률 ${_deltaText(current.successRate - prev.successRate)} · 연속 ${_deltaText((current.streak - prev.streak).toDouble())}'
                    : 'Delta: success ${_deltaText(current.successRate - prev.successRate)} · streak ${_deltaText((current.streak - prev.streak).toDouble())}',
                style: Theme.of(context).textTheme.bodySmall,
              ),
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
        nextCurrent.map((k, v) => MapEntry<String, dynamic>(k, v.toMap())),
      ),
    );
    await widget.optionRepository.setValue(
      _progressPreviousKey,
      jsonEncode(
        nextPrevious.map((k, v) => MapEntry<String, dynamic>(k, v.toMap())),
      ),
    );
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(_isKo ? '성과를 기록했어요.' : 'Performance saved.'),
      ),
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

  List<_CoachLesson> _defaultLessons() {
    return const <_CoachLesson>[
      _CoachLesson(
        id: 'dribble',
        icon: Icons.directions_run,
        titleKo: '드리블 기본기',
        titleEn: 'Dribbling Fundamentals',
        summaryKo: '낮은 중심과 짧은 터치로 볼을 보호하며 방향 전환합니다.',
        summaryEn:
            'Protect the ball with low center and short controlled touches.',
        studyCueKo: '핵심 원리: 첫 터치는 다음 행동(패스/턴/가속)을 위한 준비 터치여야 합니다.',
        studyCueEn:
            'Core principle: first touch should prepare the next action (pass/turn/acceleration).',
        sessions: <_CoachSession>[
          _CoachSession(
            titleKo: '세션 1. 볼 감각 워밍업 (5분)',
            titleEn: 'Session 1. Ball-feel warm-up (5 min)',
            goalKo: '발바닥/인사이드 터치 리듬 만들기',
            goalEn: 'Build touch rhythm with sole and inside contacts',
            howToKo: '양발 번갈아 1m 범위 안에서 30초씩 4세트 진행',
            howToEn: 'Alternate both feet in a 1m zone, 30s each for 4 sets',
            mistakeKo: '발이 너무 멀어져 볼과 거리 벌어짐',
            mistakeEn: 'Feet drift too far and lose close control',
            successKo: '30초 동안 볼이 몸에서 1m 이상 벗어나지 않음',
            successEn: 'Ball stays within 1m for full 30 seconds',
            demoType: _CoachDemoType.dribbleSlalom,
            videos: <_CoachVideo>[
              _CoachVideo(
                titleKo: '기본 볼터치 드리블',
                titleEn: 'Basic ball-touch dribbling',
                url: 'https://www.youtube.com/watch?v=4F3S4M9J8wM',
              ),
            ],
          ),
          _CoachSession(
            titleKo: '세션 2. 방향 전환 드리블 (12분)',
            titleEn: 'Session 2. Direction-change dribble (12 min)',
            goalKo: '턴 후 첫 2스텝 가속 습관화',
            goalEn: 'Automate first two acceleration steps after each turn',
            howToKo: '콘 4개를 다이아로 배치해 각 코너에서 컷 인/아웃 반복',
            howToEn:
                'Set 4 cones in a diamond and repeat cut-ins/outs on each corner',
            mistakeKo: '턴 직후 고개가 아래로 고정되어 시야 손실',
            mistakeEn: 'Head stays down after turn and loses scanning',
            successKo: '턴 후 2스텝 안에 최고 속도의 70% 이상 도달',
            successEn: 'Reach 70%+ top speed within 2 steps after turn',
            demoType: _CoachDemoType.dribbleTurn,
            videos: <_CoachVideo>[
              _CoachVideo(
                titleKo: '방향 전환 드리블',
                titleEn: 'Direction-change dribbling',
                url: 'https://www.youtube.com/watch?v=0C2J6h6w7l4',
              ),
            ],
          ),
        ],
      ),
      _CoachLesson(
        id: 'passing',
        icon: Icons.swap_horiz,
        titleKo: '패스 정확도',
        titleEn: 'Passing Accuracy',
        summaryKo: '지지발 방향과 볼 중심 임팩트를 고정해 패스 안정성을 높입니다.',
        summaryEn:
            'Fix plant-foot angle and ball strike point for stable passing.',
        studyCueKo: '핵심 원리: 패스 전에 타깃을 먼저 보고, 임팩트 후에도 몸을 타깃으로 유지합니다.',
        studyCueEn:
            'Core principle: scan target first, then keep body line to target after impact.',
        sessions: <_CoachSession>[
          _CoachSession(
            titleKo: '세션 1. 짧은 패스 정확도 (8분)',
            titleEn: 'Session 1. Short-pass accuracy (8 min)',
            goalKo: '짧은 거리에서 패스 오차 최소화',
            goalEn: 'Minimize pass error on short distance',
            howToKo: '7m 거리 타깃 2개를 번갈아 40회 패스',
            howToEn: 'Alternate 40 passes to two targets at 7m',
            mistakeKo: '임팩트 순간 발목 흔들림으로 공이 뜸',
            mistakeEn: 'Ankle wobble at impact lifts the ball',
            successKo: '40회 중 32회 이상 타깃 존 통과',
            successEn: '32+ out of 40 passes hit target zone',
            demoType: _CoachDemoType.passTriangle,
            videos: <_CoachVideo>[
              _CoachVideo(
                titleKo: '정확한 인사이드 패스',
                titleEn: 'Accurate inside passing',
                url: 'https://www.youtube.com/watch?v=1E0eL8g6f84',
              ),
            ],
          ),
          _CoachSession(
            titleKo: '세션 2. 원터치 패스 템포 (7분)',
            titleEn: 'Session 2. One-touch passing tempo (7 min)',
            goalKo: '받고-내주는 시간 1초 이내 유지',
            goalEn: 'Keep receive-and-release under 1 second',
            howToKo: '벽 패스 또는 2인 1조로 20회씩 3라운드',
            howToEn: 'Use wall or partner drills, 20 reps for 3 rounds',
            mistakeKo: '첫 터치 컨트롤이 길어 원터치가 투터치로 바뀜',
            mistakeEn:
                'First touch too long and turns one-touch into two-touch',
            successKo: '연속 10회 이상 원터치 성공',
            successEn: '10+ consecutive successful one-touch passes',
            demoType: _CoachDemoType.passOneTouch,
            videos: <_CoachVideo>[
              _CoachVideo(
                titleKo: '원터치 패스 훈련',
                titleEn: 'One-touch pass drill',
                url: 'https://www.youtube.com/watch?v=CNlQ7f1A6rU',
              ),
            ],
          ),
        ],
      ),
      _CoachLesson(
        id: 'shooting',
        icon: Icons.sports_soccer,
        titleKo: '슈팅 기본',
        titleEn: 'Shooting Basics',
        summaryKo: '임팩트 타이밍과 몸의 각도를 맞춰 강하고 정확하게 슈팅합니다.',
        summaryEn: 'Match impact timing and body angle for power and accuracy.',
        studyCueKo: '핵심 원리: 지지발 위치가 슈팅 방향을 결정하므로 지지발 정렬이 먼저입니다.',
        studyCueEn:
            'Core principle: plant foot alignment decides shot direction before impact.',
        sessions: <_CoachSession>[
          _CoachSession(
            titleKo: '세션 1. 정지볼 임팩트 (8분)',
            titleEn: 'Session 1. Static-ball impact (8 min)',
            goalKo: '정확한 발등 임팩트 각도 만들기',
            goalEn: 'Build consistent instep impact angle',
            howToKo: '정지볼 15회 × 2세트, 골대 4분할 타깃으로 진행',
            howToEn: '2 sets of 15 static shots aiming at 4 goal zones',
            mistakeKo: '상체가 뒤로 젖혀져 슈팅이 뜸',
            mistakeEn: 'Leaning back causes ball to sail high',
            successKo: '30회 중 18회 이상 목표 구역 안착',
            successEn: '18+ of 30 shots land in target zones',
            videos: <_CoachVideo>[
              _CoachVideo(
                titleKo: '슛 임팩트 기본',
                titleEn: 'Shooting impact basics',
                url: 'https://www.youtube.com/watch?v=X4lB8Lr4e9M',
              ),
            ],
          ),
          _CoachSession(
            titleKo: '세션 2. 1터치 후 슈팅 (10분)',
            titleEn: 'Session 2. One-touch then shoot (10 min)',
            goalKo: '첫 터치 후 2초 이내 슈팅 실행',
            goalEn: 'Release shot within 2 seconds after first touch',
            howToKo: '패스 받고 전진 첫 터치 후 좌우 코너 슈팅 반복',
            howToEn:
                'Receive pass, forward first touch, then alternate corner shots',
            mistakeKo: '터치 방향이 몸 바깥으로 길어 슈팅 타이밍 지연',
            mistakeEn: 'Touch goes too wide and delays shooting timing',
            successKo: '12회 중 8회 이상 2초 이내 슈팅 완료',
            successEn: '8+ of 12 reps finished within 2 seconds',
            videos: <_CoachVideo>[
              _CoachVideo(
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

class _CoachLesson {
  final String id;
  final IconData icon;
  final String titleKo;
  final String titleEn;
  final String summaryKo;
  final String summaryEn;
  final String studyCueKo;
  final String studyCueEn;
  final List<_CoachSession> sessions;

  const _CoachLesson({
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

class _CoachSession {
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
  final List<_CoachVideo> videos;

  const _CoachSession({
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

class _CoachVideo {
  final String titleKo;
  final String titleEn;
  final String url;

  const _CoachVideo({
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

    final centerCircle = Rect.fromCircle(
      center: Offset(size.width * 0.5, size.height * 0.5),
      radius: size.height * 0.14,
    );
    canvas.drawOval(centerCircle, linePaint);

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

    final text = TextPainter(
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
    text.paint(canvas, const Offset(10, 10));
  }

  List<Offset> _playerPositions(double t) {
    switch (demoType) {
      case _CoachDemoType.dribbleSlalom:
        final lead = Offset(
          0.12 + (0.78 * t),
          0.5 + (0.16 * math.sin(t * math.pi * 6)),
        );
        return <Offset>[lead];
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
            const Offset(0.2, 0.72),
            const Offset(0.5, 0.28),
            t / 0.33,
          );
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
          Offset(0.70, 0.68),
        ];
      case _CoachDemoType.dribbleTurn:
        return const <Offset>[
          Offset(0.2, 0.72),
          Offset(0.82, 0.36),
        ];
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
