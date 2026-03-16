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
  int _selectedDayIndex = 0;
  int _variantSeed = 0;

  bool get _isKo => Localizations.localeOf(context).languageCode == 'ko';

  @override
  Widget build(BuildContext context) {
    final stream =
        widget.trainingService?.watchEntries() ??
        Stream<List<TrainingEntry>>.value(const <TrainingEntry>[]);
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
        title: Text(_isKo ? '다이어리' : 'Diary'),
      ),
      body: AppBackground(
        child: SafeArea(
          child: StreamBuilder<List<TrainingEntry>>(
            stream: stream,
            builder: (context, snapshot) {
              final entries =
                  (snapshot.data ?? const <TrainingEntry>[])
                      .where((entry) => !entry.isMatch)
                      .toList(growable: false)
                    ..sort(TrainingEntry.compareByRecentCreated);
              final days = _groupEntriesByDay(entries);
              final selectedIndex = days.isEmpty
                  ? 0
                  : _selectedDayIndex.clamp(0, days.length - 1);
              final selectedDay = days.isEmpty ? null : days[selectedIndex];
              final diary = selectedDay == null ? '' : _buildDiary(selectedDay);

              return ListView(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                children: [
                  _buildIntroCard(days, selectedDay),
                  const SizedBox(height: 12),
                  if (selectedDay == null)
                    _buildEmptyCard()
                  else ...[
                    _buildDayPagerCard(days, selectedIndex),
                    const SizedBox(height: 12),
                    _buildSummaryCard(selectedDay),
                    const SizedBox(height: 12),
                    _buildDiaryCard(diary),
                    const SizedBox(height: 12),
                    _buildRecentRecordsCard(selectedDay.entries),
                  ],
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildIntroCard(List<_DiaryDayData> days, _DiaryDayData? selectedDay) {
    final dayCount = days.length;
    final selectedLabel = selectedDay == null
        ? (_isKo ? '작성할 기록 없음' : 'No diary day yet')
        : _formatDiaryDate(selectedDay.date);
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
                    _isKo ? '하루씩 넘겨보는 다이어리' : 'Daily football diary',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _isKo
                        ? '기간 전체를 합치지 않고, 기록이 있는 날짜마다 하루치 일기를 따로 정리합니다.'
                        : 'Each page stays focused on one day instead of merging multiple days into one entry.',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      Chip(
                        label: Text(
                          _isKo ? '일기 $dayCount일치' : '$dayCount diary days',
                        ),
                      ),
                      Chip(label: Text(selectedLabel)),
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

  Widget _buildDayPagerCard(List<_DiaryDayData> days, int selectedIndex) {
    final day = days[selectedIndex];
    final canGoPrev = selectedIndex < days.length - 1;
    final canGoNext = selectedIndex > 0;
    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
        child: Row(
          children: [
            IconButton(
              tooltip: _isKo ? '이전 날짜' : 'Previous day',
              onPressed: canGoPrev
                  ? () {
                      setState(() {
                        _selectedDayIndex += 1;
                        _variantSeed = 0;
                      });
                    }
                  : null,
              icon: const Icon(Icons.chevron_left),
            ),
            Expanded(
              child: Column(
                children: [
                  Text(
                    _formatDiaryDate(day.date),
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    _isKo
                        ? '${selectedIndex + 1} / ${days.length} 페이지'
                        : 'Page ${selectedIndex + 1} of ${days.length}',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
            IconButton(
              tooltip: _isKo ? '다음 날짜' : 'Next day',
              onPressed: canGoNext
                  ? () {
                      setState(() {
                        _selectedDayIndex -= 1;
                        _variantSeed = 0;
                      });
                    }
                  : null,
              icon: const Icon(Icons.chevron_right),
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
                  ? '하루 기록을 남기면 날짜별 다이어리 페이지가 하나씩 만들어집니다.'
                  : 'Once you add a training log, this screen will create a diary page for that day.',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryCard(_DiaryDayData day) {
    final entries = day.entries;
    final totalMinutes = entries.fold<int>(
      0,
      (sum, entry) => sum + entry.durationMinutes,
    );
    final avgMood =
        entries.fold<int>(0, (sum, entry) => sum + entry.mood) / entries.length;
    final focus = _topFocus(entries);
    final places = _topPlaces(entries);
    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _isKo ? '하루 요약' : 'Day summary',
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
                    _isKo ? '기록 ${entries.length}개' : '${entries.length} logs',
                  ),
                ),
                Chip(
                  label: Text(
                    _isKo ? '합계 $totalMinutes분' : '$totalMinutes minutes',
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
            Text(_isKo ? '오늘 붙잡은 주제: $focus' : 'Today focus: $focus'),
            if (places.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                _isKo ? '기록한 장소: $places' : 'Logged places: $places',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
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
                    _isKo ? '오늘의 일기' : 'Diary entry',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                IconButton(
                  tooltip: _isKo ? '다른 문장으로 다시 쓰기' : 'Regenerate',
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
              _isKo ? '이 날의 기록' : 'Logs from this day',
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
                      '${_formatTime(entry.date)} · ${entry.type}',
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

  List<_DiaryDayData> _groupEntriesByDay(List<TrainingEntry> entries) {
    final byDay = <DateTime, List<TrainingEntry>>{};
    for (final entry in entries) {
      final day = DateTime(entry.date.year, entry.date.month, entry.date.day);
      byDay.putIfAbsent(day, () => <TrainingEntry>[]).add(entry);
    }
    final days =
        byDay.entries
            .map(
              (item) => _DiaryDayData(
                date: item.key,
                entries: item.value..sort(TrainingEntry.compareByRecentCreated),
              ),
            )
            .toList(growable: false)
          ..sort((a, b) => b.date.compareTo(a.date));
    return days;
  }

  String _buildDiary(_DiaryDayData day) {
    final entries = day.entries;
    if (entries.isEmpty) {
      return _isKo
          ? '이 날에는 아직 정리할 기록이 없다.'
          : 'There is no diary content for this day yet.';
    }
    final totalMinutes = entries.fold<int>(
      0,
      (sum, entry) => sum + entry.durationMinutes,
    );
    final opener = _pickOpener(day.date);
    final body = _buildBody(entries, totalMinutes);
    final closing = _buildClosing(entries);
    return '$opener\n\n$body\n\n$closing';
  }

  String _pickOpener(DateTime date) {
    final label = _formatDiaryDate(date);
    final ko = <String>[
      '$label의 훈련을 다시 읽어 보니 하루의 흐름이 또렷하게 살아났다.',
      '$label은 짧은 메모들이 모여 하나의 축구 일기가 된 날이었다.',
      '$label의 기록을 넘겨 보며 그날의 리듬을 차분히 정리했다.',
    ];
    final en = <String>[
      'Reading back through $label made the whole day feel vivid again.',
      '$label turned a few short notes into one football diary page.',
      'Looking over $label helped me line up the rhythm of that day.',
    ];
    final options = _isKo ? ko : en;
    return options[_variantSeed % options.length];
  }

  String _buildBody(List<TrainingEntry> entries, int totalMinutes) {
    final latest = entries.first;
    final focus = _topFocus(entries);
    final places = _topPlaces(entries);
    final keyMoments = entries
        .map(_entryMoment)
        .where((text) => text.isNotEmpty)
        .join(' ');
    final moodSentence = _moodSentence(entries);
    if (_isKo) {
      return '이날은 총 ${entries.length}개의 기록으로 $totalMinutes분을 채웠고, 가장 오래 붙잡은 주제는 $focus였다. $moodSentence ${latest.type} 훈련을 중심으로 하루가 이어졌고, 메모에는 $keyMoments ${places.isNotEmpty ? '주로 $places에서 움직였다.' : ''}'
          .trim();
    }
    return 'That day held ${entries.length} logs and $totalMinutes minutes in total, with $focus showing up as the clearest focus. $moodSentence The day revolved around ${latest.type} work, and the notes read like this: $keyMoments ${places.isNotEmpty ? 'Most of it happened around $places.' : ''}'
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
      final strengthText = strength.isEmpty
          ? '그날의 흐름을 기록으로 남긴 것만으로도 충분히 의미가 있었다.'
          : '특히 $strength 부분은 다음 훈련에도 이어 가고 싶다.';
      final goalText = nextGoal.isEmpty
          ? '다음 기록에는 더 또렷한 목표를 적어 두고 싶다.'
          : '다음 목표는 $nextGoal 이다.';
      return '$strengthText $goalText';
    }
    final strengthText = strength.isEmpty
        ? 'Keeping a record of the day already gave the session some shape.'
        : 'I want to keep building on $strength.';
    final goalText = nextGoal.isEmpty
        ? 'Next time I want to leave a clearer target in the log.'
        : 'My next target is $nextGoal.';
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
        return '기복은 있었지만 흐름은 무너지지 않았다.';
      }
      return '몸이 가벼운 날만 있었던 것은 아니지만 끝까지 기록을 남겼다.';
    }
    if (avgMood >= 4) {
      return 'The overall feeling stayed steady and positive.';
    }
    if (avgMood >= 3) {
      return 'There were some ups and downs, but the rhythm held together.';
    }
    return 'It was not an easy day throughout, but the notes still carried it forward.';
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
        return '${entry.type}에 시간을 썼다.';
      }
      return 'I spent time on ${entry.type}.';
    }
    final detail = pieces.first;
    if (_isKo) {
      return '${entry.type}에서는 $detail 를 남겼다.';
    }
    return '${entry.type} left me with $detail.';
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
    return sorted.take(2).map((entry) => entry.key).join(', ');
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

  String _formatDiaryDate(DateTime date) {
    return _isKo
        ? DateFormat('M월 d일 EEEE', 'ko').format(date)
        : DateFormat('EEE, MMM d', 'en').format(date);
  }

  String _formatTime(DateTime date) {
    return _isKo
        ? DateFormat('a h:mm', 'ko').format(date)
        : DateFormat('h:mm a', 'en').format(date);
  }
}

class _DiaryDayData {
  final DateTime date;
  final List<TrainingEntry> entries;

  const _DiaryDayData({required this.date, required this.entries});
}
