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
  static const String _completedStepsKey = 'coach_lesson_completed_steps_v1';
  static const String _recentLessonIdKey = 'coach_recent_lesson_id_v1';

  late final List<_CoachLesson> _lessons;
  late String _selectedLessonId;
  Set<String> _completedStepKeys = <String>{};

  bool get _isKo => Localizations.localeOf(context).languageCode == 'ko';

  _CoachLesson get _selectedLesson =>
      _lessons.firstWhere((lesson) => lesson.id == _selectedLessonId);

  @override
  void initState() {
    super.initState();
    _lessons = _defaultLessons();
    _completedStepKeys = widget.optionRepository
        .getOptions(_completedStepsKey, const [])
        .map((value) => value.trim())
        .where((value) => value.isNotEmpty)
        .toSet();
    final recent =
        widget.optionRepository.getValue<String>(_recentLessonIdKey)?.trim();
    _selectedLessonId = _lessons.any((lesson) => lesson.id == recent)
        ? recent!
        : _lessons.first.id;
  }

  @override
  Widget build(BuildContext context) {
    final lesson = _selectedLesson;
    final doneCount = lesson.steps
        .where((step) => _completedStepKeys.contains(_stepKey(lesson.id, step)))
        .length;
    final progress =
        lesson.steps.isEmpty ? 0.0 : doneCount / lesson.steps.length;

    return Scaffold(
      appBar: AppBar(
        title: Text(_isKo ? '축구 코치' : 'Football Coach'),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        children: [
          _buildCoachIntroCard(),
          const SizedBox(height: 12),
          Wrap(
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
          ),
          const SizedBox(height: 12),
          Card(
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
                      color:
                          Theme.of(context).colorScheme.surfaceContainerHighest,
                    ),
                    child: Text(
                      _isKo ? lesson.coachCueKo : lesson.coachCueEn,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    _isKo ? '레슨 플로우' : 'Lesson flow',
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                  const SizedBox(height: 6),
                  ...lesson.flows.map(
                    (flow) => Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Text(
                        '• ${_isKo ? flow.ko : flow.en}',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Card(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _isKo ? '교본 영상' : 'Guide videos',
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                  const SizedBox(height: 8),
                  ...lesson.videos.map(
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
              ),
            ),
          ),
          const SizedBox(height: 12),
          Card(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _isKo ? '오늘 레슨 체크리스트' : 'Today checklist',
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                  const SizedBox(height: 8),
                  ...lesson.steps.map(
                    (step) => CheckboxListTile(
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                      value: _completedStepKeys
                          .contains(_stepKey(lesson.id, step)),
                      controlAffinity: ListTileControlAffinity.leading,
                      title: Text(_isKo ? step.textKo : step.textEn),
                      subtitle: Text(
                        _isKo ? '${step.repsKo} 반복' : '${step.repsEn} reps',
                      ),
                      onChanged: (_) => _toggleStep(lesson.id, step),
                    ),
                  ),
                  const SizedBox(height: 8),
                  LinearProgressIndicator(value: progress),
                  const SizedBox(height: 6),
                  Text(
                    _isKo
                        ? '진행률: $doneCount/${lesson.steps.length}'
                        : 'Progress: $doneCount/${lesson.steps.length}',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCoachIntroCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
        child: Row(
          children: [
            CircleAvatar(
              radius: 22,
              backgroundColor: Theme.of(context).colorScheme.primaryContainer,
              child: Icon(
                Icons.sports,
                color: Theme.of(context).colorScheme.onPrimaryContainer,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                _isKo
                    ? '코치 모드: 오늘은 1개 기본기에 집중해서, 영상을 보고 그대로 따라해보세요.'
                    : 'Coach mode: focus on one fundamental today, watch, and follow exactly.',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _selectLesson(String lessonId) {
    setState(() => _selectedLessonId = lessonId);
    widget.optionRepository.setValue(_recentLessonIdKey, lessonId);
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

  Future<void> _toggleStep(String lessonId, _CoachStep step) async {
    final key = _stepKey(lessonId, step);
    final next = Set<String>.from(_completedStepKeys);
    if (next.contains(key)) {
      next.remove(key);
    } else {
      next.add(key);
    }
    setState(() => _completedStepKeys = next);
    await widget.optionRepository.saveOptions(
      _completedStepsKey,
      next.toList(growable: false),
    );
  }

  String _stepKey(String lessonId, _CoachStep step) => '$lessonId::${step.id}';

  List<_CoachLesson> _defaultLessons() {
    return <_CoachLesson>[
      const _CoachLesson(
        id: 'dribble',
        icon: Icons.directions_run,
        titleKo: '드리블 기본기',
        titleEn: 'Dribbling Fundamentals',
        summaryKo: '낮은 중심과 짧은 터치로 볼을 보호하며 방향 전환합니다.',
        summaryEn:
            'Protect the ball with low center and short controlled touches.',
        coachCueKo: '시선은 2초마다 앞-볼-앞 순서로 체크하세요.',
        coachCueEn: 'Scan every 2 seconds: forward-ball-forward.',
        flows: <_CoachFlow>[
          _CoachFlow(ko: '1) 워밍업 5분', en: '1) 5-min warm-up'),
          _CoachFlow(
              ko: '2) 원터치/투터치 드리블 12분', en: '2) One/two-touch dribble 12 min'),
          _CoachFlow(ko: '3) 방향전환 + 가속 8분', en: '3) Turn + accelerate 8 min'),
        ],
        videos: <_CoachVideo>[
          _CoachVideo(
            titleKo: '기본 볼터치 드리블',
            titleEn: 'Basic ball-touch dribbling',
            url: 'https://www.youtube.com/watch?v=4F3S4M9J8wM',
          ),
          _CoachVideo(
            titleKo: '방향 전환 드리블',
            titleEn: 'Direction-change dribbling',
            url: 'https://www.youtube.com/watch?v=0C2J6h6w7l4',
          ),
        ],
        steps: <_CoachStep>[
          _CoachStep(
              id: 'a',
              textKo: '인사이드 터치 30회',
              textEn: '30 inside touches',
              repsKo: '30',
              repsEn: '30'),
          _CoachStep(
              id: 'b',
              textKo: '양발 번갈아 20회',
              textEn: '20 alternating touches',
              repsKo: '20',
              repsEn: '20'),
          _CoachStep(
              id: 'c',
              textKo: '턴 후 가속 10회',
              textEn: '10 turn-and-go reps',
              repsKo: '10',
              repsEn: '10'),
        ],
      ),
      const _CoachLesson(
        id: 'passing',
        icon: Icons.swap_horiz,
        titleKo: '패스 정확도',
        titleEn: 'Passing Accuracy',
        summaryKo: '지지발 방향과 볼 중심 임팩트를 고정해 패스 안정성을 높입니다.',
        summaryEn:
            'Fix plant-foot angle and ball strike point for stable passing.',
        coachCueKo: '지지발은 타깃 방향 30도, 임팩트 후 1걸음 따라가세요.',
        coachCueEn: 'Plant 30° to target and follow through one step.',
        flows: <_CoachFlow>[
          _CoachFlow(ko: '1) 짧은 패스 8분', en: '1) Short passing 8 min'),
          _CoachFlow(ko: '2) 중거리 패스 10분', en: '2) Mid-range passing 10 min'),
          _CoachFlow(ko: '3) 원터치 패스 7분', en: '3) One-touch passing 7 min'),
        ],
        videos: <_CoachVideo>[
          _CoachVideo(
            titleKo: '정확한 인사이드 패스',
            titleEn: 'Accurate inside passing',
            url: 'https://www.youtube.com/watch?v=1E0eL8g6f84',
          ),
          _CoachVideo(
            titleKo: '원터치 패스 훈련',
            titleEn: 'One-touch pass drill',
            url: 'https://www.youtube.com/watch?v=CNlQ7f1A6rU',
          ),
        ],
        steps: <_CoachStep>[
          _CoachStep(
              id: 'a',
              textKo: '짧은 패스 40회',
              textEn: '40 short passes',
              repsKo: '40',
              repsEn: '40'),
          _CoachStep(
              id: 'b',
              textKo: '중거리 패스 20회',
              textEn: '20 medium passes',
              repsKo: '20',
              repsEn: '20'),
          _CoachStep(
              id: 'c',
              textKo: '원터치 패스 20회',
              textEn: '20 one-touch passes',
              repsKo: '20',
              repsEn: '20'),
        ],
      ),
      const _CoachLesson(
        id: 'shooting',
        icon: Icons.sports_soccer,
        titleKo: '슈팅 기본',
        titleEn: 'Shooting Basics',
        summaryKo: '임팩트 타이밍과 몸의 각도를 맞춰 강하고 정확하게 슈팅합니다.',
        summaryEn: 'Match impact timing and body angle for power and accuracy.',
        coachCueKo: '볼을 끝까지 보고, 발목을 고정한 채 강하게 관통하세요.',
        coachCueEn: 'Keep eyes on ball, lock ankle, strike through the ball.',
        flows: <_CoachFlow>[
          _CoachFlow(ko: '1) 정지볼 슈팅 8분', en: '1) Static ball shots 8 min'),
          _CoachFlow(
              ko: '2) 1터치 후 슈팅 10분', en: '2) One-touch then shot 10 min'),
          _CoachFlow(
              ko: '3) 좌우 각도 슈팅 8분', en: '3) Angle shots both sides 8 min'),
        ],
        videos: <_CoachVideo>[
          _CoachVideo(
            titleKo: '슛 임팩트 기본',
            titleEn: 'Shooting impact basics',
            url: 'https://www.youtube.com/watch?v=X4lB8Lr4e9M',
          ),
          _CoachVideo(
            titleKo: '정확도 향상 슈팅 훈련',
            titleEn: 'Accuracy shooting drill',
            url: 'https://www.youtube.com/watch?v=3lM4Qm2dK8I',
          ),
        ],
        steps: <_CoachStep>[
          _CoachStep(
              id: 'a',
              textKo: '정지볼 슈팅 15회',
              textEn: '15 static shots',
              repsKo: '15',
              repsEn: '15'),
          _CoachStep(
              id: 'b',
              textKo: '1터치 후 슈팅 12회',
              textEn: '12 one-touch shots',
              repsKo: '12',
              repsEn: '12'),
          _CoachStep(
              id: 'c',
              textKo: '약발 슈팅 8회',
              textEn: '8 weak-foot shots',
              repsKo: '8',
              repsEn: '8'),
        ],
      ),
    ];
  }
}

class _CoachLesson {
  final String id;
  final IconData icon;
  final String titleKo;
  final String titleEn;
  final String summaryKo;
  final String summaryEn;
  final String coachCueKo;
  final String coachCueEn;
  final List<_CoachFlow> flows;
  final List<_CoachVideo> videos;
  final List<_CoachStep> steps;

  const _CoachLesson({
    required this.id,
    required this.icon,
    required this.titleKo,
    required this.titleEn,
    required this.summaryKo,
    required this.summaryEn,
    required this.coachCueKo,
    required this.coachCueEn,
    required this.flows,
    required this.videos,
    required this.steps,
  });
}

class _CoachFlow {
  final String ko;
  final String en;

  const _CoachFlow({required this.ko, required this.en});
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

class _CoachStep {
  final String id;
  final String textKo;
  final String textEn;
  final String repsKo;
  final String repsEn;

  const _CoachStep({
    required this.id,
    required this.textKo,
    required this.textEn,
    required this.repsKo,
    required this.repsEn,
  });
}
