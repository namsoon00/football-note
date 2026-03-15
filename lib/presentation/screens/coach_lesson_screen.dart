import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

import '../../application/backup_service.dart';
import '../../application/locale_service.dart';
import '../../application/settings_service.dart';
import '../../application/training_service.dart';
import '../../domain/entities/training_entry.dart';
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
  _DiaryRange _selectedRange = _DiaryRange.week;
  int _variantSeed = 0;

  bool get _isKo => Localizations.localeOf(context).languageCode == 'ko';

  @override
  Widget build(BuildContext context) {
    final stream = widget.trainingService?.watchEntries() ??
        Stream<List<TrainingEntry>>.value(const <TrainingEntry>[]);
    return Scaffold(
      body: AppBackground(
        child: SafeArea(
          child: StreamBuilder<List<TrainingEntry>>(
            stream: stream,
            builder: (context, snapshot) {
              final entries = (snapshot.data ?? const <TrainingEntry>[])
                  .where((entry) => !entry.isMatch)
                  .toList(growable: false)
                ..sort(TrainingEntry.compareByRecentCreated);
              final filtered = _filterEntries(entries);
              final diary = _buildDiary(filtered);
              return ListView(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                children: [
                  _buildIntroCard(filtered),
                  const SizedBox(height: 12),
                  _buildRangeCard(),
                  const SizedBox(height: 12),
                  if (filtered.isEmpty)
                    _buildEmptyCard()
                  else ...[
                    _buildSummaryCard(filtered),
                    const SizedBox(height: 12),
                    _buildDiaryCard(diary),
                    const SizedBox(height: 12),
                    _buildRecentRecordsCard(filtered),
                  ],
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildIntroCard(List<TrainingEntry> entries) {
    final count = entries.length;
    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CircleAvatar(
              radius: 22,
              backgroundColor: Theme.of(context).colorScheme.primaryContainer,
              child: Icon(
                Icons.auto_stories_outlined,
                color: Theme.of(context).colorScheme.onPrimaryContainer,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _isKo ? '훈련 기록 일기 변환' : 'Training diary writer',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _isKo
                        ? '훈련기록을 바탕으로 일기나 다이어리 형식의 문장으로 다시 써줍니다.'
                        : 'Turn your training records into a diary-style journal entry.',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      Chip(
                        label: Text(
                          _isKo ? '기록 $count개 반영' : '$count records used',
                        ),
                      ),
                      Chip(
                        label: Text(
                          _isKo
                              ? _selectedRange.labelKo
                              : _selectedRange.labelEn,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRangeCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _isKo ? '반영 기간' : 'Coverage',
              style: Theme.of(
                context,
              ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _DiaryRange.values
                  .map(
                    (range) => ChoiceChip(
                      selected: _selectedRange == range,
                      label: Text(_isKo ? range.labelKo : range.labelEn),
                      onSelected: (_) {
                        setState(() {
                          _selectedRange = range;
                          _variantSeed += 1;
                        });
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

  Widget _buildEmptyCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 16, 14, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _isKo ? '아직 훈련 기록이 없습니다.' : 'No training records yet.',
              style: Theme.of(
                context,
              ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 6),
            Text(
              _isKo
                  ? '기록을 남기면 여기서 자동으로 일기 형식의 문장을 만들어 줍니다.'
                  : 'Add training entries first, then this screen will draft a diary entry automatically.',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryCard(List<TrainingEntry> entries) {
    final totalMinutes = entries.fold<int>(
      0,
      (sum, entry) => sum + entry.durationMinutes,
    );
    final avgMood =
        entries.fold<int>(0, (sum, entry) => sum + entry.mood) / entries.length;
    final focus = _topFocus(entries);
    final latest = entries.first;
    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _isKo ? '기록 요약' : 'Record summary',
              style: Theme.of(
                context,
              ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                Chip(
                  label: Text(
                    _isKo
                        ? '총 ${entries.length}회'
                        : '${entries.length} sessions',
                  ),
                ),
                Chip(
                  label: Text(
                    _isKo ? '누적 $totalMinutes분' : '$totalMinutes minutes total',
                  ),
                ),
                Chip(
                  label: Text(
                    _isKo
                        ? '평균 컨디션 ${avgMood.toStringAsFixed(1)}/5'
                        : 'Avg mood ${avgMood.toStringAsFixed(1)}/5',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(_isKo ? '가장 자주 나온 주제: $focus' : 'Most frequent focus: $focus'),
            const SizedBox(height: 4),
            Text(
              _isKo
                  ? '최근 기록: ${_formatDate(latest.date)} · ${latest.type}'
                  : 'Latest record: ${_formatDate(latest.date)} · ${latest.type}',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDiaryCard(String diary) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    _isKo ? '훈련 일기' : 'Diary draft',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                ),
                IconButton(
                  tooltip: _isKo ? '새 문장 만들기' : 'Regenerate',
                  onPressed: () => setState(() => _variantSeed += 1),
                  icon: const Icon(Icons.refresh_rounded),
                ),
                IconButton(
                  tooltip: _isKo ? '복사' : 'Copy',
                  onPressed: () => _copyDiary(diary),
                  icon: const Icon(Icons.content_copy_outlined),
                ),
              ],
            ),
            const SizedBox(height: 8),
            SelectableText(
              diary,
              style: Theme.of(
                context,
              ).textTheme.bodyLarge?.copyWith(height: 1.6),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentRecordsCard(List<TrainingEntry> entries) {
    final visible = entries.take(4).toList(growable: false);
    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _isKo ? '참고한 최근 기록' : 'Recent records used',
              style: Theme.of(
                context,
              ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            ...visible.map(
              (entry) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${_formatDate(entry.date)} · ${entry.type}',
                      style: Theme.of(context).textTheme.labelLarge,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _summarizeEntry(entry),
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<TrainingEntry> _filterEntries(List<TrainingEntry> entries) {
    final now = DateTime.now();
    if (_selectedRange.days == null) return entries;
    final start = now.subtract(Duration(days: _selectedRange.days! - 1));
    return entries
        .where(
          (entry) => !entry.date.isBefore(
            DateTime(start.year, start.month, start.day),
          ),
        )
        .toList(growable: false);
  }

  String _buildDiary(List<TrainingEntry> entries) {
    if (entries.isEmpty) {
      return _isKo
          ? '오늘은 아직 남겨 둔 훈련 기록이 없다. 다음 훈련을 기록하면 이 공간이 나만의 축구 일기로 채워질 것이다.'
          : 'There are no training records yet. Once you log a session, this space will turn it into your football diary.';
    }

    final latest = entries.first;
    final oldest = entries.last;
    final totalMinutes = entries.fold<int>(
      0,
      (sum, entry) => sum + entry.durationMinutes,
    );
    final opener = _pickOpener();
    final body = _buildBody(entries, totalMinutes);
    final closing = _buildClosing(entries);

    if (_isKo) {
      return '$opener\n\n${_formatDate(oldest.date)}부터 ${_formatDate(latest.date)}까지 총 ${entries.length}번의 훈련을 했다. $body\n\n$closing';
    }
    return '$opener\n\nFrom ${_formatDate(oldest.date)} to ${_formatDate(latest.date)}, I logged ${entries.length} training sessions. $body\n\n$closing';
  }

  String _pickOpener() {
    final ko = <String>[
      '오늘은 내 훈련 기록을 다시 읽어 보며 하루를 정리했다.',
      '훈련 노트를 펼쳐 보니 내가 어떻게 쌓아 왔는지가 한눈에 들어왔다.',
      '짧게 남겨 둔 기록들이 모이니 하나의 축구 일기처럼 느껴졌다.',
    ];
    final en = <String>[
      'Today I looked back through my training notes and turned them into one journal entry.',
      'Reading my logs again made the flow of recent training much clearer.',
      'The short notes I left behind now read like one football diary entry.',
    ];
    final options = _isKo ? ko : en;
    return options[_variantSeed % options.length];
  }

  String _buildBody(List<TrainingEntry> entries, int totalMinutes) {
    final latest = entries.first;
    final focus = _topFocus(entries);
    final places = _topPlaces(entries);
    final keyMoments = entries
        .take(3)
        .map(_entryMoment)
        .where((text) => text.isNotEmpty)
        .join(_isKo ? ' ' : ' ');
    if (_isKo) {
      final moodSentence = _moodSentence(entries);
      return '누적 시간은 $totalMinutes분이었고, 가장 자주 붙잡은 주제는 $focus였다. $moodSentence 최근에는 ${latest.type} 훈련을 ${latest.location}에서 진행했고, 기록 속 장면들은 이렇게 이어졌다. $keyMoments ${places.isNotEmpty ? '주로 $places에서 리듬을 이어 갔다.' : ''}'
          .trim();
    }
    final moodSentence = _moodSentence(entries);
    return 'The total volume came to $totalMinutes minutes, and the focus that appeared most often was $focus. $moodSentence Most recently I worked on ${latest.type} at ${latest.location}, and the notes connected into these moments: $keyMoments ${places.isNotEmpty ? 'The routine kept returning to $places.' : ''}'
        .trim();
  }

  String _buildClosing(List<TrainingEntry> entries) {
    final latest = entries.first;
    final nextGoal = _firstNonEmpty(<String>[
      latest.nextGoal,
      latest.goal,
      latest.improvements,
    ]);
    final strength = _firstNonEmpty(<String>[
      latest.goodPoints,
      latest.feedback,
      latest.notes,
    ]);
    if (_isKo) {
      final goalText = nextGoal.isEmpty
          ? '다음 기록에서는 조금 더 선명한 목표를 남겨 보고 싶다.'
          : '다음 목표는 $nextGoal 이다.';
      final strengthText = strength.isEmpty
          ? '그래도 기록을 남긴 덕분에 흐름을 놓치지 않았다.'
          : '특히 $strength 부분은 계속 살리고 싶다.';
      return '$strengthText $goalText';
    }
    final goalText = nextGoal.isEmpty
        ? 'Next time I want to leave a clearer target in the log.'
        : 'My next target is $nextGoal.';
    final strengthText = strength.isEmpty
        ? 'Still, keeping the log helped me hold onto the flow.'
        : 'I want to keep building on $strength.';
    return '$strengthText $goalText';
  }

  String _moodSentence(List<TrainingEntry> entries) {
    final avgMood =
        entries.fold<int>(0, (sum, entry) => sum + entry.mood) / entries.length;
    if (_isKo) {
      if (avgMood >= 4) {
        return '전체적인 컨디션과 기분은 꽤 안정적이었다.';
      }
      if (avgMood >= 3) {
        return '기복은 있었지만 전체 흐름은 무난했다.';
      }
      return '몸과 마음이 가벼운 날만 있었던 것은 아니었다.';
    }
    if (avgMood >= 4) {
      return 'The overall feeling stayed steady and positive.';
    }
    if (avgMood >= 3) {
      return 'There were ups and downs, but the rhythm stayed fairly stable.';
    }
    return 'Not every session felt light, but the record still moved forward.';
  }

  String _entryMoment(TrainingEntry entry) {
    final pieces = <String>[
      entry.program,
      entry.drills,
      entry.goodPoints,
      entry.improvements,
      entry.nextGoal,
      entry.notes,
    ].map((text) => text.trim()).where((text) => text.isNotEmpty).toList();
    if (pieces.isEmpty) {
      if (_isKo) {
        return '${_formatDate(entry.date)}에는 ${entry.type}에 시간을 썼다.';
      }
      return 'On ${_formatDate(entry.date)}, I spent time on ${entry.type}.';
    }
    final detail = pieces.first;
    if (_isKo) {
      return '${_formatDate(entry.date)}에는 ${entry.type} 훈련에서 $detail 를 남겼다.';
    }
    return 'On ${_formatDate(entry.date)}, ${entry.type} training left me with: $detail.';
  }

  String _topFocus(List<TrainingEntry> entries) {
    final counts = <String, int>{};
    for (final entry in entries) {
      for (final raw in <String>[
        entry.program,
        entry.type,
        ...entry.goalFocuses,
      ]) {
        final value = raw.trim();
        if (value.isEmpty) continue;
        counts[value] = (counts[value] ?? 0) + 1;
      }
    }
    if (counts.isEmpty) {
      return _isKo ? '기본기' : 'fundamentals';
    }
    final sorted = counts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return sorted.first.key;
  }

  String _topPlaces(List<TrainingEntry> entries) {
    final counts = <String, int>{};
    for (final entry in entries) {
      final location = entry.location.trim();
      if (location.isEmpty) continue;
      counts[location] = (counts[location] ?? 0) + 1;
    }
    if (counts.isEmpty) return '';
    final sorted = counts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return sorted.take(2).map((entry) => entry.key).join(_isKo ? ', ' : ', ');
  }

  String _summarizeEntry(TrainingEntry entry) {
    final details = <String>[
      entry.program,
      entry.drills,
      entry.goodPoints,
      entry.improvements,
      entry.nextGoal,
      entry.notes,
    ].map((text) => text.trim()).where((text) => text.isNotEmpty).toList();
    final summary = details.isEmpty
        ? (_isKo ? '세부 메모 없음' : 'No detailed notes')
        : details.first;
    return _isKo
        ? '${entry.durationMinutes}분 · ${entry.location} · $summary'
        : '${entry.durationMinutes} min · ${entry.location} · $summary';
  }

  String _firstNonEmpty(List<String> values) {
    for (final value in values) {
      final trimmed = value.trim();
      if (trimmed.isNotEmpty) return trimmed;
    }
    return '';
  }

  Future<void> _copyDiary(String diary) async {
    await Clipboard.setData(ClipboardData(text: diary));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(_isKo ? '일기를 복사했어요.' : 'Diary copied.')),
    );
  }

  String _formatDate(DateTime date) {
    return _isKo
        ? DateFormat('M월 d일', 'ko').format(date)
        : DateFormat('MMM d', 'en').format(date);
  }
}

enum _DiaryRange {
  week(7, '최근 7일', 'Last 7 days'),
  twoWeeks(14, '최근 14일', 'Last 14 days'),
  month(30, '최근 30일', 'Last 30 days'),
  all(null, '전체 기록', 'All records');

  const _DiaryRange(this.days, this.labelKo, this.labelEn);

  final int? days;
  final String labelKo;
  final String labelEn;
}
