import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

import '../../application/backup_service.dart';
import '../../application/locale_service.dart';
import '../../application/settings_service.dart';
import '../../application/training_board_service.dart';
import '../../application/training_service.dart';
import '../../domain/entities/training_board.dart';
import '../../domain/entities/training_entry.dart';
import '../../domain/repositories/option_repository.dart';
import '../../gen/app_localizations.dart';
import '../models/training_board_link_codec.dart';
import '../models/training_method_layout.dart';
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
  static const Color _starbucksGreen = Color(0xFF0F5A43);
  static const Color _deepGreen = Color(0xFF123B2D);
  static const Color _paper = Color(0xFFF7F1E7);
  static const Color _paperBorder = Color(0xFFD8CBB5);
  static const Color _coffee = Color(0xFF6E5A49);
  static const String _plansStorageKey = 'training_plans_v1';

  final PageController _pageController = PageController();
  int _selectedDayIndex = 0;

  bool get _isKo => Localizations.localeOf(context).languageCode == 'ko';
  ThemeData get _theme => Theme.of(context);
  ColorScheme get _scheme => _theme.colorScheme;
  bool get _isDark => _theme.brightness == Brightness.dark;
  AppLocalizations get _l10n => AppLocalizations.of(context)!;
  Color get _paperSurface => _isDark
      ? Color.lerp(_scheme.surfaceContainerHigh, _scheme.surface, 0.38)!
      : _paper;
  Color get _paperEdge =>
      _isDark ? _scheme.outline.withValues(alpha: 0.5) : _paperBorder;
  Color get _headlineInk => _isDark ? _scheme.onSurface : _deepGreen;
  Color get _bodyInk => _isDark ? _scheme.onSurfaceVariant : _coffee;
  Color get _accentInk => _isDark ? _scheme.primaryFixedDim : _starbucksGreen;
  Color get _accentWash => _accentInk.withValues(alpha: _isDark ? 0.16 : 0.1);
  Color get _tileSurface => _isDark
      ? _scheme.surfaceContainerHighest.withValues(alpha: 0.52)
      : Colors.white.withValues(alpha: 0.58);
  Color get _notebookLine => _isDark
      ? _scheme.outlineVariant.withValues(alpha: 0.28)
      : const Color(0xFFC8DBF5);
  Color get _notebookMargin =>
      _isDark ? _scheme.error.withValues(alpha: 0.35) : const Color(0xFFE6A6A6);
  Color get _holeColor => _isDark
      ? _scheme.surface.withValues(alpha: 0.95)
      : const Color(0xFFE6DDCF);

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

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
              final entries = [...(snapshot.data ?? const <TrainingEntry>[])]
                ..sort(TrainingEntry.compareByRecentCreated);
              final boardMap = TrainingBoardService(
                widget.optionRepository,
              ).boardMap();
              final days = _buildDays(entries, _loadPlans(), boardMap);
              if (days.isEmpty) {
                return ListView(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                  children: [_buildEmptyCard()],
                );
              }

              final selectedIndex = _selectedDayIndex.clamp(0, days.length - 1);
              if (selectedIndex != _selectedDayIndex) {
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (!mounted) return;
                  setState(() => _selectedDayIndex = selectedIndex);
                  if (_pageController.hasClients) {
                    _pageController.jumpToPage(selectedIndex);
                  }
                });
              }
              final selectedDay = days[selectedIndex];

              return Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                    child: _buildPagerCard(
                      dayCount: days.length,
                      selectedIndex: selectedIndex,
                      selectedLabel: _formatDiaryDate(selectedDay.date),
                    ),
                  ),
                  Expanded(
                    child: PageView.builder(
                      key: const ValueKey('diary-page-view'),
                      controller: _pageController,
                      itemCount: days.length,
                      onPageChanged: (index) {
                        if (_selectedDayIndex == index) return;
                        setState(() => _selectedDayIndex = index);
                      },
                      itemBuilder: (context, index) {
                        return _buildDiaryPage(days[index]);
                      },
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildPagerCard({
    required int dayCount,
    required int selectedIndex,
    required String selectedLabel,
  }) {
    final canGoPrev = selectedIndex < dayCount - 1;
    final canGoNext = selectedIndex > 0;
    return Container(
      decoration: _paperDecoration(),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
        child: Row(
          children: [
            IconButton(
              tooltip: _isKo ? '이전 날짜' : 'Previous day',
              onPressed: canGoPrev ? () => _movePage(selectedIndex + 1) : null,
              icon: const Icon(Icons.chevron_left),
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text(
                    selectedLabel,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      color: _headlineInk,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _isKo
                        ? '${selectedIndex + 1} / $dayCount 페이지 · 좌우로 넘기기'
                        : 'Page ${selectedIndex + 1} / $dayCount · swipe left or right',
                    style: Theme.of(
                      context,
                    ).textTheme.bodySmall?.copyWith(color: _bodyInk),
                  ),
                ],
              ),
            ),
            IconButton(
              tooltip: _isKo ? '다음 날짜' : 'Next day',
              onPressed: canGoNext ? () => _movePage(selectedIndex - 1) : null,
              icon: const Icon(Icons.chevron_right),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _movePage(int index) async {
    await _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 260),
      curve: Curves.easeOutCubic,
    );
  }

  Widget _buildDiaryPage(_DiaryDayData day) {
    final diary = _buildDiary(day);
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
      child: _buildNotebookSheet(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildDayHeadlineCard(day),
            const SizedBox(height: 12),
            _buildEncouragementCard(day),
            const SizedBox(height: 12),
            _buildFortuneCard(day),
            const SizedBox(height: 12),
            _buildNightReviewCard(day, diary),
            if (day.plans.isNotEmpty) ...[
              const SizedBox(height: 12),
              _buildPlanCard(day.plans),
            ],
            if (day.matchEntries.isNotEmpty) ...[
              const SizedBox(height: 12),
              _buildMatchCard(day.matchEntries),
            ],
            if (day.trainingEntries.isNotEmpty) ...[
              const SizedBox(height: 12),
              _buildTrainingCard(day.trainingEntries),
            ],
            if (_hasRecoveryRecord(day)) ...[
              const SizedBox(height: 12),
              _buildRecoveryCard(day),
            ],
            if (day.boards.isNotEmpty) ...[
              const SizedBox(height: 12),
              _buildBoardCard(day),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildDayHeadlineCard(_DiaryDayData day) {
    final totalMinutes = day.entries.fold<int>(
      0,
      (sum, entry) => sum + entry.durationMinutes,
    );
    final trainingCount = day.trainingEntries.length;
    final matchCount = day.matchEntries.length;
    return Container(
      decoration: _paperDecoration(),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(18, 18, 18, 18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _formatDiaryDate(day.date),
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: _headlineInk,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _isKo
                  ? '저장된 계획, 경기, 훈련, 회복 기록을 한 편의 일기처럼 이어서 읽을 수 있도록 정리했습니다.'
                  : 'Saved plans, matches, training, and recovery notes are gathered here as one diary entry.',
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: _bodyInk, height: 1.45),
            ),
            const SizedBox(height: 14),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _buildStatChip(
                  _isKo ? '훈련 $trainingCount개' : '$trainingCount trainings',
                ),
                _buildStatChip(
                  _isKo ? '시합 $matchCount개' : '$matchCount matches',
                ),
                _buildStatChip(
                  _isKo
                      ? '계획 ${day.plans.length}개'
                      : '${day.plans.length} plans',
                ),
                _buildStatChip(
                  _isKo ? '합계 $totalMinutes분' : '$totalMinutes min total',
                ),
                if (day.boards.isNotEmpty)
                  _buildStatChip(
                    _isKo
                        ? '보드 ${day.boards.length}개'
                        : '${day.boards.length} boards',
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatChip(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: _accentWash,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelLarge?.copyWith(
          color: _accentInk,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }

  Widget _buildEncouragementCard(_DiaryDayData day) {
    return _buildPaperCard(
      title: _isKo ? '오늘의 응원' : 'Today encouragement',
      subtitle: _isKo
          ? '기록 전체를 묶어서 오늘의 흐름을 한 문장으로 정리했어요.'
          : 'A quick encouragement blended from today\'s full log.',
      child: Text(
        _buildEncouragement(day),
        style: _theme.textTheme.bodyLarge?.copyWith(
          height: 1.65,
          color: _headlineInk,
        ),
      ),
    );
  }

  Widget _buildFortuneCard(_DiaryDayData day) {
    final lines = _buildFortuneLines(day);
    return _buildPaperCard(
      title: _isKo ? '오늘의 운세 노트' : 'Today fortune note',
      subtitle: _isKo
          ? '기록을 바탕으로 가볍게 읽는 오늘의 재미 요소예요.'
          : 'A playful fortune digest based on the day\'s record.',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: lines
            .map(
              (line) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text(
                  line,
                  style: _theme.textTheme.bodyMedium?.copyWith(
                    height: 1.55,
                    color: _headlineInk,
                  ),
                ),
              ),
            )
            .toList(growable: false),
      ),
    );
  }

  Widget _buildNightReviewCard(_DiaryDayData day, String diary) {
    return _buildPaperCard(
      title: _isKo ? '자기 전 다이어리' : 'Night review diary',
      subtitle: _isKo
          ? '기록에 있는 사실만 연결해서 오늘을 다시 읽습니다.'
          : 'This recap only uses details already recorded in your logs.',
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            tooltip: _isKo ? '복사' : 'Copy',
            onPressed: () => _copyDiary(diary),
            icon: const Icon(Icons.content_copy_outlined),
          ),
        ],
      ),
      child: SelectableText(
        diary,
        style: Theme.of(
          context,
        ).textTheme.bodyLarge?.copyWith(height: 1.7, color: _headlineInk),
      ),
    );
  }

  Widget _buildPlanCard(List<_DiaryPlan> plans) {
    return _buildPaperCard(
      title: _isKo ? '훈련 계획' : 'Training plans',
      child: Column(
        children: plans
            .map(
              (plan) => _buildTimelineTile(
                title: '${_formatTime(plan.scheduledAt)} · ${plan.category}',
                detail: _isKo
                    ? '${plan.durationMinutes}분${plan.note.trim().isEmpty ? '' : ' · ${plan.note.trim()}'}'
                    : '${plan.durationMinutes} min${plan.note.trim().isEmpty ? '' : ' · ${plan.note.trim()}'}',
              ),
            )
            .toList(growable: false),
      ),
    );
  }

  Widget _buildMatchCard(List<TrainingEntry> entries) {
    return _buildPaperCard(
      title: _isKo ? '시합 기록' : 'Match records',
      child: Column(
        children: entries
            .map(
              (entry) => _buildTimelineTile(
                title:
                    '${_formatTime(entry.date)} · ${entry.opponentTeam.isEmpty ? entry.type : entry.opponentTeam}',
                detail: _matchSummary(entry),
              ),
            )
            .toList(growable: false),
      ),
    );
  }

  Widget _buildTrainingCard(List<TrainingEntry> entries) {
    return _buildPaperCard(
      title: _isKo ? '훈련 기록' : 'Training records',
      child: Column(
        children: entries
            .map(
              (entry) => _buildTimelineTile(
                title: '${_formatTime(entry.date)} · ${entry.type}',
                detail: _trainingSummary(entry),
              ),
            )
            .toList(growable: false),
      ),
    );
  }

  Widget _buildRecoveryCard(_DiaryDayData day) {
    final lifting = _buildLiftingSummary(day.entries);
    final jumpRope = _buildJumpRopeSummary(day.entries);
    final injuryNotes = day.entries
        .where((entry) => entry.injury)
        .map(_injurySummary)
        .toList(growable: false);
    return _buildPaperCard(
      title: _isKo ? '부상 · 리프팅 · 줄넘기' : 'Injury, lifting, jump rope',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (injuryNotes.isNotEmpty)
            _buildSummaryLine(
              _isKo
                  ? '부상: ${injuryNotes.join(' / ')}'
                  : 'Injury: ${injuryNotes.join(' / ')}',
            ),
          if (lifting.isNotEmpty)
            _buildSummaryLine(_isKo ? '리프팅: $lifting' : 'Lifting: $lifting'),
          if (jumpRope.isNotEmpty)
            _buildSummaryLine(
              _isKo ? '줄넘기: $jumpRope' : 'Jump rope: $jumpRope',
            ),
        ],
      ),
    );
  }

  Widget _buildBoardCard(_DiaryDayData day) {
    return _buildPaperCard(
      title: _isKo ? '다이어리에 담긴 훈련보드' : 'Training boards in this diary',
      subtitle: _isKo
          ? '실제 보드 화면과 보드 메모, 연결된 기록 메모를 함께 남깁니다.'
          : 'Keeps the board preview, board memo, and linked log notes together.',
      child: Column(
        children: day.boards
            .map((board) => _buildBoardDiaryTile(day: day, board: board))
            .toList(growable: false),
      ),
    );
  }

  Widget _buildEmptyCard() {
    return _buildPaperCard(
      title: _isKo ? '아직 기록이 없습니다.' : 'No records yet',
      child: Text(
        _isKo
            ? '훈련이나 시합, 계획을 남기면 날짜별 다이어리 페이지가 자동으로 만들어집니다.'
            : 'Once you add a training note, match, or plan, this screen will build a diary page for that date.',
        style: Theme.of(
          context,
        ).textTheme.bodyMedium?.copyWith(color: _bodyInk, height: 1.5),
      ),
    );
  }

  Widget _buildPaperCard({
    required String title,
    String? subtitle,
    Widget? trailing,
    required Widget child,
  }) {
    return Container(
      decoration: _paperDecoration(),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(
                              color: _headlineInk,
                              fontWeight: FontWeight.w900,
                            ),
                      ),
                      if (subtitle != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          subtitle,
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(color: _bodyInk, height: 1.45),
                        ),
                      ],
                    ],
                  ),
                ),
                if (trailing != null) trailing,
              ],
            ),
            const SizedBox(height: 14),
            child,
          ],
        ),
      ),
    );
  }

  Widget _buildTimelineTile({required String title, required String detail}) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
      decoration: BoxDecoration(
        color: _tileSurface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _paperEdge),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
              color: _headlineInk,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            detail,
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: _bodyInk, height: 1.45),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryLine(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        text,
        style: Theme.of(
          context,
        ).textTheme.bodyMedium?.copyWith(color: _headlineInk, height: 1.5),
      ),
    );
  }

  BoxDecoration _paperDecoration() {
    return BoxDecoration(
      color: _paperSurface,
      borderRadius: BorderRadius.circular(26),
      border: Border.all(color: _paperEdge),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withValues(alpha: _isDark ? 0.26 : 0.07),
          blurRadius: _isDark ? 26 : 18,
          offset: const Offset(0, 10),
        ),
      ],
    );
  }

  List<_DiaryDayData> _buildDays(
    List<TrainingEntry> entries,
    List<_DiaryPlan> plans,
    Map<String, TrainingBoard> boardMap,
  ) {
    final dayKeys = <DateTime>{};
    final entriesByDay = <DateTime, List<TrainingEntry>>{};
    final plansByDay = <DateTime, List<_DiaryPlan>>{};

    for (final entry in entries) {
      final day = _normalizeDay(entry.date);
      dayKeys.add(day);
      entriesByDay.putIfAbsent(day, () => <TrainingEntry>[]).add(entry);
    }
    for (final plan in plans) {
      final day = _normalizeDay(plan.scheduledAt);
      dayKeys.add(day);
      plansByDay.putIfAbsent(day, () => <_DiaryPlan>[]).add(plan);
    }

    final days =
        dayKeys
            .map((day) {
              final dayEntries = entriesByDay[day] ?? const <TrainingEntry>[];
              final linkedBoards = <String, TrainingBoard>{};
              for (final entry in dayEntries) {
                for (final id in TrainingBoardLinkCodec.decodeBoardIds(
                  entry.drills,
                )) {
                  final board = boardMap[id];
                  if (board != null) linkedBoards[id] = board;
                }
              }
              return _DiaryDayData(
                date: day,
                entries: [...dayEntries]
                  ..sort((a, b) => a.date.compareTo(b.date)),
                plans: [...(plansByDay[day] ?? const <_DiaryPlan>[])]
                  ..sort((a, b) => a.scheduledAt.compareTo(b.scheduledAt)),
                boards: linkedBoards.values.toList(growable: false)
                  ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt)),
              );
            })
            .toList(growable: false)
          ..sort((a, b) => b.date.compareTo(a.date));
    return days;
  }

  List<_DiaryPlan> _loadPlans() {
    final raw = widget.optionRepository.getValue<String>(_plansStorageKey);
    if (raw == null || raw.trim().isEmpty) return const <_DiaryPlan>[];
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) return const <_DiaryPlan>[];
      return decoded
          .whereType<Map>()
          .map((map) => _DiaryPlan.fromMap(map.cast<String, dynamic>()))
          .toList(growable: false);
    } catch (_) {
      return const <_DiaryPlan>[];
    }
  }

  String _buildDiary(_DiaryDayData day) {
    final paragraphs = <String>[
      _isKo
          ? '${_formatDiaryDate(day.date)}에는 ${_topPlaces(day.entries)}에서 움직였고, 하루의 중심은 ${_topFocus(day.trainingEntries)}에 맞춰졌다.'
          : 'On ${_formatDiaryDate(day.date)}, the day unfolded around ${_topPlaces(day.entries)} with ${_topFocus(day.trainingEntries)} as the main focus.',
    ];

    if (day.plans.isNotEmpty) {
      final planLines = day.plans
          .map(
            (plan) => _isKo
                ? '${_formatTime(plan.scheduledAt)} ${plan.category} ${plan.durationMinutes}분${plan.note.trim().isEmpty ? '' : ' (${plan.note.trim()})'}'
                : '${_formatTime(plan.scheduledAt)} ${plan.category} ${plan.durationMinutes} min${plan.note.trim().isEmpty ? '' : ' (${plan.note.trim()})'}',
          )
          .join(', ');
      paragraphs.add(
        _isKo
            ? '먼저 계획은 $planLines 순서로 잡혀 있었다.'
            : 'The plan for the day was set as: $planLines.',
      );
    }

    if (day.trainingEntries.isNotEmpty) {
      final totalMinutes = day.trainingEntries.fold<int>(
        0,
        (sum, entry) => sum + entry.durationMinutes,
      );
      paragraphs.add(
        _isKo
            ? '훈련 기록은 ${day.trainingEntries.length}개, 총 $totalMinutes분이었다. ${day.trainingEntries.map(_trainingDiarySentence).join(' ')}'
            : 'There were ${day.trainingEntries.length} training logs for $totalMinutes minutes total. ${day.trainingEntries.map(_trainingDiarySentence).join(' ')}',
      );
    }

    if (day.matchEntries.isNotEmpty) {
      paragraphs.add(
        _isKo
            ? '실전에서는 ${day.matchEntries.map(_matchDiarySentence).join(' ')}'
            : 'In matches, ${day.matchEntries.map(_matchDiarySentence).join(' ')}',
      );
    }

    final recoveryParagraph = _buildRecoveryDiaryParagraph(day);
    if (recoveryParagraph.isNotEmpty) {
      paragraphs.add(recoveryParagraph);
    }

    final boardParagraph = _buildBoardDiaryParagraph(day);
    if (boardParagraph.isNotEmpty) {
      paragraphs.add(boardParagraph);
    }

    paragraphs.add(_buildEncouragement(day));
    paragraphs.add(_buildFortuneDiaryParagraph(day));

    paragraphs.add(
      _isKo
          ? '오늘 남긴 메모를 다시 읽으면 무엇이 잘됐고 무엇을 다음 목표로 가져가야 하는지 흐름이 자연스럽게 이어진다.'
          : 'Reading the saved notes back makes the next goal easier to carry forward from what worked and what still needs work.',
    );
    return paragraphs.join('\n\n');
  }

  String _topFocus(List<TrainingEntry> entries) {
    if (entries.isEmpty) return _isKo ? '기본기' : 'fundamentals';
    final counts = <String, int>{};
    for (final entry in entries) {
      for (final raw in <String>[
        entry.program,
        entry.type,
        ...entry.goalFocuses,
      ]) {
        final text = raw.trim();
        if (text.isEmpty) continue;
        counts[text] = (counts[text] ?? 0) + 1;
      }
    }
    if (counts.isEmpty) return _isKo ? '기본기' : 'fundamentals';
    final sorted = counts.entries.toList()
      ..sort((a, b) {
        final countCompare = b.value.compareTo(a.value);
        if (countCompare != 0) return countCompare;
        return a.key.compareTo(b.key);
      });
    return sorted.first.key;
  }

  String _topPlaces(List<TrainingEntry> entries) {
    final counts = <String, int>{};
    for (final entry in entries) {
      final value = entry.effectiveMatchLocation.trim();
      if (value.isEmpty) continue;
      counts[value] = (counts[value] ?? 0) + 1;
    }
    if (counts.isEmpty) {
      return _isKo ? '장소 기록 없음' : 'No location logged';
    }
    final sorted = counts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return sorted.take(2).map((entry) => entry.key).join(', ');
  }

  bool _hasRecoveryRecord(_DiaryDayData day) {
    return day.entries.any(
      (entry) =>
          entry.injury ||
          entry.liftingByPart.values.any((count) => count > 0) ||
          entry.jumpRopeCount > 0 ||
          entry.jumpRopeMinutes > 0 ||
          entry.jumpRopeNote.trim().isNotEmpty,
    );
  }

  String _trainingSummary(TrainingEntry entry) {
    final details = <String>[
      if (entry.program.trim().isNotEmpty) entry.program.trim(),
      if (!TrainingBoardLinkCodec.isBoardLinkPayload(entry.drills) &&
          entry.drills.trim().isNotEmpty)
        entry.drills.trim(),
      if (entry.goodPoints.trim().isNotEmpty) entry.goodPoints.trim(),
      if (entry.improvements.trim().isNotEmpty) entry.improvements.trim(),
      if (entry.nextGoal.trim().isNotEmpty) entry.nextGoal.trim(),
      if (entry.notes.trim().isNotEmpty) entry.notes.trim(),
    ];
    final detailText = details.isEmpty
        ? (_isKo ? '세부 메모 없음' : 'No detailed note')
        : details.join(' · ');
    return _isKo
        ? '${entry.type} ${entry.durationMinutes}분, ${entry.location.trim().isEmpty ? '장소 기록 없음' : entry.location.trim()}, $detailText'
        : '${entry.type} for ${entry.durationMinutes} min at ${entry.location.trim().isEmpty ? 'no location logged' : entry.location.trim()}, $detailText';
  }

  String _trainingDiarySentence(TrainingEntry entry) {
    final noteParts = <String>[
      if (entry.goodPoints.trim().isNotEmpty)
        _isKo
            ? '잘된 점은 ${entry.goodPoints.trim()}'
            : 'the good part was ${entry.goodPoints.trim()}',
      if (entry.improvements.trim().isNotEmpty)
        _isKo
            ? '보완할 점은 ${entry.improvements.trim()}'
            : 'the adjustment point was ${entry.improvements.trim()}',
      if (entry.nextGoal.trim().isNotEmpty)
        _isKo
            ? '다음 목표는 ${entry.nextGoal.trim()}'
            : 'the next goal was ${entry.nextGoal.trim()}',
      if (entry.notes.trim().isNotEmpty)
        _isKo
            ? '메모에는 ${entry.notes.trim()}'
            : 'the note said ${entry.notes.trim()}',
    ];
    final suffix = noteParts.isEmpty ? '' : ' ${noteParts.join('. ')}.';
    return _isKo
        ? '${_formatTime(entry.date)} ${entry.type} ${entry.durationMinutes}분을 ${entry.location.trim().isEmpty ? '장소 기록 없이' : entry.location.trim()}에서 진행했다.$suffix'
        : 'At ${_formatTime(entry.date)}, ${entry.type} ran for ${entry.durationMinutes} minutes ${entry.location.trim().isEmpty ? 'without a logged location' : 'at ${entry.location.trim()}'}.$suffix';
  }

  String _matchSummary(TrainingEntry entry) {
    final parts = <String>[
      if (_isKo)
        '${entry.opponentTeam.isEmpty ? '상대 팀 미기록' : entry.opponentTeam}전'
      else
        'vs ${entry.opponentTeam.isEmpty ? 'unknown opponent' : entry.opponentTeam}',
      if (entry.scoredGoals != null || entry.concededGoals != null)
        _isKo
            ? '스코어 ${entry.scoredGoals ?? 0}:${entry.concededGoals ?? 0}'
            : 'score ${entry.scoredGoals ?? 0}:${entry.concededGoals ?? 0}',
      if (entry.playerGoals != null)
        _isKo ? '개인 득점 ${entry.playerGoals}' : 'goals ${entry.playerGoals}',
      if (entry.playerAssists != null)
        _isKo ? '도움 ${entry.playerAssists}' : 'assists ${entry.playerAssists}',
      if (entry.minutesPlayed != null)
        _isKo
            ? '출전 ${entry.minutesPlayed}분'
            : '${entry.minutesPlayed} min played',
      if (entry.effectiveMatchLocation.trim().isNotEmpty)
        entry.effectiveMatchLocation.trim(),
      if (entry.notes.trim().isNotEmpty) entry.notes.trim(),
    ];
    return parts.join(' · ');
  }

  String _matchDiarySentence(TrainingEntry entry) {
    final result = (entry.scoredGoals != null || entry.concededGoals != null)
        ? '${entry.scoredGoals ?? 0}:${entry.concededGoals ?? 0}'
        : null;
    final extras = <String>[
      if (entry.playerGoals != null)
        _isKo ? '개인 득점 ${entry.playerGoals}' : '${entry.playerGoals} goal(s)',
      if (entry.playerAssists != null)
        _isKo
            ? '도움 ${entry.playerAssists}'
            : '${entry.playerAssists} assist(s)',
      if (entry.notes.trim().isNotEmpty) entry.notes.trim(),
    ];
    return _isKo
        ? '${entry.opponentTeam.isEmpty ? '상대 팀 미기록 경기' : '${entry.opponentTeam}전'}${result == null ? '' : '은 $result'}으로 남았고${extras.isEmpty ? ' 세부 메모는 비어 있었다.' : ' ${extras.join(', ')}까지 기록했다.'}'
        : '${entry.opponentTeam.isEmpty ? 'the opponent was not logged' : 'vs ${entry.opponentTeam}'}${result == null ? '' : ' ended $result'}${extras.isEmpty ? '.' : ' with ${extras.join(', ')} recorded.'}';
  }

  String _injurySummary(TrainingEntry entry) {
    final parts = <String>[
      if (entry.injuryPart.trim().isNotEmpty)
        entry.injuryPart.trim()
      else if (_isKo)
        '부위 미기록'
      else
        'part not logged',
      if (entry.painLevel != null)
        _isKo ? '통증 ${entry.painLevel}/10' : 'pain ${entry.painLevel}/10',
      if (entry.rehab) _isKo ? '재활 포함' : 'rehab included',
    ];
    return parts.join(' · ');
  }

  String _buildLiftingSummary(List<TrainingEntry> entries) {
    final totals = <String, int>{};
    for (final entry in entries) {
      entry.liftingByPart.forEach((part, count) {
        if (count <= 0) return;
        totals[part] = (totals[part] ?? 0) + count;
      });
    }
    if (totals.isEmpty) return '';
    final sorted = totals.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return sorted
        .map((entry) => '${_liftingPartLabel(entry.key)} ${entry.value}회')
        .join(', ');
  }

  String _buildJumpRopeSummary(List<TrainingEntry> entries) {
    final totalCount = entries.fold<int>(
      0,
      (sum, entry) => sum + entry.jumpRopeCount,
    );
    final totalMinutes = entries.fold<int>(
      0,
      (sum, entry) => sum + entry.jumpRopeMinutes,
    );
    final notes = entries
        .map((entry) => entry.jumpRopeNote.trim())
        .where((text) => text.isNotEmpty)
        .toSet()
        .toList(growable: false);
    if (totalCount == 0 && totalMinutes == 0 && notes.isEmpty) return '';
    final parts = <String>[
      if (totalCount > 0) _isKo ? '$totalCount회' : '$totalCount reps',
      if (totalMinutes > 0) _isKo ? '$totalMinutes분' : '$totalMinutes min',
      if (notes.isNotEmpty) notes.join(' / '),
    ];
    return parts.join(' · ');
  }

  String _buildRecoveryDiaryParagraph(_DiaryDayData day) {
    final injuries = day.entries
        .where((entry) => entry.injury)
        .map(_injurySummary)
        .toList(growable: false);
    final lifting = _buildLiftingSummary(day.entries);
    final jumpRope = _buildJumpRopeSummary(day.entries);
    if (injuries.isEmpty && lifting.isEmpty && jumpRope.isEmpty) return '';
    final parts = <String>[
      if (injuries.isNotEmpty)
        _isKo
            ? '부상 기록은 ${injuries.join(' / ')}'
            : 'injury notes were ${injuries.join(' / ')}',
      if (lifting.isNotEmpty) _isKo ? '리프팅은 $lifting' : 'lifting was $lifting',
      if (jumpRope.isNotEmpty)
        _isKo ? '줄넘기는 $jumpRope' : 'jump rope was $jumpRope',
    ];
    return _isKo
        ? '회복과 보조 기록까지 보면 ${parts.join(', ')}.'
        : 'For recovery and supporting work, ${parts.join(', ')}.';
  }

  String _buildEncouragement(_DiaryDayData day) {
    final focus = _topFocus(day.trainingEntries);
    final totalMinutes = day.entries.fold<int>(
      0,
      (sum, entry) => sum + entry.durationMinutes,
    );
    final recovery = _hasRecoveryRecord(day);
    final boards = day.boards.isNotEmpty;
    if (_isKo) {
      final details = <String>[
        '$focus에 계속 중심을 둔 점이 좋았고',
        '$totalMinutes분 동안 흐름을 끊지 않은 집중력이 남아 있습니다',
        if (recovery) '회복 기록까지 남겨서 다음 훈련 준비도 꼼꼼합니다',
        if (boards) '훈련보드로 생각을 시각화한 점도 큰 자산입니다',
      ];
      return '${details.join(', ')}. 오늘처럼 기록을 끝까지 남기는 습관이면 성장 속도가 꾸준히 이어집니다.';
    }
    final details = <String>[
      'you kept the day centered on $focus',
      'your focus held for $totalMinutes minutes',
      if (recovery) 'you also logged recovery details for the next session',
      if (boards) 'the board notes turned ideas into something concrete',
    ];
    return '${details.join('. ')}. Keeping records this consistently will keep your growth steady.';
  }

  List<String> _buildFortuneLines(_DiaryDayData day) {
    final lastEntry = day.entries.isNotEmpty ? day.entries.last : null;
    final totalLifting = day.entries.fold<int>(
      0,
      (sum, entry) =>
          sum + entry.liftingByPart.values.fold<int>(0, (a, b) => a + b),
    );
    final jumpRopeMinutes = day.entries.fold<int>(
      0,
      (sum, entry) => sum + entry.jumpRopeMinutes,
    );
    final fortuneSnippet = day.entries
        .map((entry) => entry.fortuneComment.trim())
        .firstWhere((text) => text.isNotEmpty, orElse: () => '');
    final recommendation = day.entries
        .map((entry) => entry.fortuneRecommendation.trim())
        .firstWhere((text) => text.isNotEmpty, orElse: () => '');
    final luckyPlay = totalLifting >= 100
        ? (_isKo ? '리듬을 살리는 짧은 볼터치' : 'short rhythm-setting ball touches')
        : jumpRopeMinutes >= 10
        ? (_isKo ? '가볍게 발을 푸는 스텝워크' : 'light footwork to wake up your feet')
        : (_isKo
              ? '${_topFocus(day.trainingEntries)} 복습 한 세트'
              : 'one more rep of ${_topFocus(day.trainingEntries)}');
    final luckyMood =
        (day.matchEntries.isNotEmpty && day.trainingEntries.isNotEmpty)
        ? (_isKo
              ? '실전 감각과 훈련 감각이 같이 붙는 날'
              : 'training feel and match feel work together')
        : day.plans.isNotEmpty
        ? (_isKo
              ? '계획한 걸 그대로 해낼 때 운이 붙는 날'
              : 'luck follows finishing what you planned')
        : (_isKo
              ? '작게 시작할수록 템포가 살아나는 날'
              : 'starting small brings your tempo alive');
    final luckyTiming = day.entries.length >= 2
        ? (_isKo
              ? '기록 사이 간격이 짧을수록 감각이 더 선명해져요.'
              : 'short gaps between sessions sharpen your feel.')
        : (_isKo
              ? '처음 10분 집중이 하루 운세를 끌어올려요.'
              : 'the first 10 focused minutes set the tone.');

    final lines = <String>[
      _isKo ? '행운 플레이: $luckyPlay' : 'Lucky play: $luckyPlay',
      _isKo ? '오늘의 신호: $luckyMood' : 'Today signal: $luckyMood',
      _isKo ? '읽는 포인트: $luckyTiming' : 'Reading point: $luckyTiming',
    ];
    if (fortuneSnippet.isNotEmpty) {
      final firstLine = fortuneSnippet.split('\n').first.trim();
      lines.add(_isKo ? '저장된 운세: $firstLine' : 'Saved fortune: $firstLine');
    }
    if (recommendation.isNotEmpty) {
      lines.add(
        _isKo ? '다음 한 걸음: $recommendation' : 'Next step: $recommendation',
      );
    } else if (lastEntry != null) {
      lines.add(
        _isKo
            ? '다음 한 걸음: ${lastEntry.nextGoal.trim().isNotEmpty ? lastEntry.nextGoal.trim() : '${_topFocus(day.trainingEntries)}를 한 번 더 깔끔하게'}'
            : 'Next step: ${lastEntry.nextGoal.trim().isNotEmpty ? lastEntry.nextGoal.trim() : 'one cleaner rep of ${_topFocus(day.trainingEntries)}'}',
      );
    }
    return lines;
  }

  String _buildFortuneDiaryParagraph(_DiaryDayData day) {
    final lines = _buildFortuneLines(day);
    return _isKo
        ? '가볍게 운세를 덧붙이면 ${lines.join(', ')}.'
        : 'For a playful fortune note, ${lines.join(', ')}.';
  }

  String _liftingPartLabel(String key) {
    switch (key) {
      case 'infront':
        return _l10n.liftingPartInfront;
      case 'inside':
        return _l10n.liftingPartInside;
      case 'outside':
        return _l10n.liftingPartOutside;
      case 'muple':
        return _l10n.liftingPartMuple;
      case 'head':
        return _l10n.liftingPartHead;
      case 'chest':
        return _l10n.liftingPartChest;
      case 'left_foot':
        return '${_l10n.liftingPartInfront} (${_l10n.legacyLabel})';
      case 'right_foot':
        return '${_l10n.liftingPartInside} (${_l10n.legacyLabel})';
      case 'left_thigh':
        return '${_l10n.liftingPartOutside} (${_l10n.legacyLabel})';
      case 'right_thigh':
        return '${_l10n.liftingPartMuple} (${_l10n.legacyLabel})';
      case 'back':
        return '${_l10n.liftingPartInside} (${_l10n.oldLabel})';
      case 'legs':
        return '${_l10n.liftingPartOutside} (${_l10n.oldLabel})';
      case 'shoulders':
        return '${_l10n.liftingPartMuple} (${_l10n.oldLabel})';
      case 'arms':
        return '${_l10n.liftingPartHead} (${_l10n.legacyLabel})';
      case 'core':
        return '${_l10n.liftingPartChest} (${_l10n.legacyLabel})';
      default:
        return key;
    }
  }

  String _buildBoardDiaryParagraph(_DiaryDayData day) {
    if (day.boards.isEmpty) return '';
    final boardNotes = day.boards
        .map((board) {
          final layout = TrainingMethodLayout.decode(board.layoutJson);
          final memo = layout.pages.isNotEmpty
              ? layout.pages.first.methodText.trim()
              : '';
          final linkedEntryNotes = _boardLinkedEntryNotes(
            day: day,
            board: board,
          );
          if (_isKo) {
            return memo.isEmpty && linkedEntryNotes.isEmpty
                ? board.title
                : '${board.title}${memo.isEmpty ? '' : ' 메모는 "$memo"'}${linkedEntryNotes.isEmpty ? '' : ', 기록 메모는 $linkedEntryNotes'}';
          }
          return memo.isEmpty && linkedEntryNotes.isEmpty
              ? board.title
              : '${board.title}${memo.isEmpty ? '' : ' memo was "$memo"'}${linkedEntryNotes.isEmpty ? '' : ', linked log notes were $linkedEntryNotes'}';
        })
        .join(' / ');
    return _isKo
        ? '훈련보드에는 $boardNotes 같은 그림과 메모를 함께 남겼다.'
        : 'The training boards kept both the visual sketch and notes such as $boardNotes.';
  }

  Widget _buildBoardDiaryTile({
    required _DiaryDayData day,
    required TrainingBoard board,
  }) {
    final layout = TrainingMethodLayout.decode(board.layoutJson);
    final page = layout.pages.isNotEmpty ? layout.pages.first : null;
    final boardMemo = page?.methodText.trim() ?? '';
    final linkedNotes = _boardLinkedEntryNotes(day: day, board: board);
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
      decoration: BoxDecoration(
        color: _tileSurface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _paperEdge),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  board.title,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    color: _headlineInk,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                _isKo
                    ? DateFormat('M.d HH:mm', 'ko').format(board.updatedAt)
                    : DateFormat('MMM d HH:mm', 'en').format(board.updatedAt),
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: _bodyInk),
              ),
            ],
          ),
          const SizedBox(height: 10),
          _DiaryBoardPreview(layout: layout),
          if (boardMemo.isNotEmpty) ...[
            const SizedBox(height: 10),
            _buildSummaryLine(
              _isKo ? '보드 메모: $boardMemo' : 'Board note: $boardMemo',
            ),
          ],
          if (linkedNotes.isNotEmpty)
            _buildSummaryLine(
              _isKo
                  ? '연결된 기록 메모: $linkedNotes'
                  : 'Linked log notes: $linkedNotes',
            ),
        ],
      ),
    );
  }

  String _boardLinkedEntryNotes({
    required _DiaryDayData day,
    required TrainingBoard board,
  }) {
    final notes = day.entries
        .where(
          (entry) => TrainingBoardLinkCodec.decodeBoardIds(
            entry.drills,
          ).contains(board.id),
        )
        .expand(
          (entry) => <String>[
            entry.program.trim(),
            entry.goodPoints.trim(),
            entry.improvements.trim(),
            entry.nextGoal.trim(),
            entry.notes.trim(),
          ],
        )
        .where((text) => text.isNotEmpty)
        .toSet()
        .toList(growable: false);
    return notes.join(' / ');
  }

  Future<void> _copyDiary(String diary) async {
    await Clipboard.setData(ClipboardData(text: diary));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(_isKo ? '일기를 복사했어요.' : 'Diary copied.')),
    );
  }

  DateTime _normalizeDay(DateTime value) {
    return DateTime(value.year, value.month, value.day);
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

  Widget _buildNotebookSheet({required Widget child}) {
    return Container(
      decoration: _paperDecoration(),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(26),
        child: Stack(
          children: [
            Positioned.fill(
              child: CustomPaint(
                painter: _NotebookSheetPainter(
                  lineColor: _notebookLine,
                  marginColor: _notebookMargin,
                  holeColor: _holeColor,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(32, 18, 18, 18),
              child: child,
            ),
          ],
        ),
      ),
    );
  }
}

class _NotebookSheetPainter extends CustomPainter {
  final Color lineColor;
  final Color marginColor;
  final Color holeColor;

  const _NotebookSheetPainter({
    required this.lineColor,
    required this.marginColor,
    required this.holeColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final linePaint = Paint()
      ..color = lineColor
      ..strokeWidth = 1;
    final marginPaint = Paint()
      ..color = marginColor
      ..strokeWidth = 1.4;
    final holePaint = Paint()..color = holeColor;
    final holeBorder = Paint()
      ..color = lineColor.withValues(alpha: 0.7)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;

    canvas.drawLine(const Offset(22, 0), Offset(22, size.height), marginPaint);

    for (double y = 24; y < size.height; y += 28) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), linePaint);
    }

    for (double y = 28; y < size.height - 8; y += 72) {
      canvas.drawCircle(Offset(12, y), 5, holePaint);
      canvas.drawCircle(Offset(12, y), 5, holeBorder);
    }
  }

  @override
  bool shouldRepaint(covariant _NotebookSheetPainter oldDelegate) {
    return oldDelegate.lineColor != lineColor ||
        oldDelegate.marginColor != marginColor ||
        oldDelegate.holeColor != holeColor;
  }
}

class _DiaryBoardPreview extends StatelessWidget {
  final TrainingMethodLayout layout;

  const _DiaryBoardPreview({required this.layout});

  @override
  Widget build(BuildContext context) {
    final previewPage = layout.pages.isNotEmpty
        ? layout.pages.first
        : TrainingMethodLayout.empty().pages.first;
    final itemCount = layout.pages.fold<int>(
      0,
      (sum, page) => sum + page.items.length,
    );
    return Container(
      height: 148,
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        gradient: const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF2E7D32), Color(0xFF1B5E20)],
        ),
        border: Border.all(color: Colors.white.withValues(alpha: 0.24)),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final width = constraints.maxWidth;
          final height = constraints.maxHeight;
          return Stack(
            children: [
              CustomPaint(
                size: Size(width, height),
                painter: _DiaryBoardPreviewPainter(page: previewPage),
              ),
              ...previewPage.items.take(14).map((item) {
                final icon = switch (item.type) {
                  'cone' => Icons.change_history,
                  'player' => Icons.person,
                  'ball' => Icons.sports_soccer,
                  'ladder' => Icons.view_week,
                  _ => Icons.circle,
                };
                return Positioned(
                  left: (item.x * width).clamp(6.0, width - 20.0),
                  top: (item.y * height).clamp(4.0, height - 20.0),
                  child: Transform.rotate(
                    angle: item.rotationDeg * 3.1415926535897932 / 180,
                    child: Icon(
                      icon,
                      size: (item.size * 0.42).clamp(10.0, 20.0),
                      color: Color(item.colorValue).withValues(alpha: 0.96),
                    ),
                  ),
                );
              }),
              Positioned(
                right: 8,
                top: 8,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    '$itemCount',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _DiaryBoardPreviewPainter extends CustomPainter {
  final TrainingMethodPage page;

  const _DiaryBoardPreviewPainter({required this.page});

  @override
  void paint(Canvas canvas, Size size) {
    final line = Paint()
      ..color = Colors.white.withValues(alpha: 0.55)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4;
    final pathPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.72)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.8
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final centerX = size.width / 2;
    final centerY = size.height / 2;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(2, 2, size.width - 4, size.height - 4),
        const Radius.circular(14),
      ),
      line,
    );
    canvas.drawLine(Offset(centerX, 2), Offset(centerX, size.height - 2), line);
    canvas.drawCircle(Offset(centerX, centerY), 16, line);

    for (final stroke in page.strokes) {
      if (stroke.points.length < 2) continue;
      final strokePaint = Paint()
        ..color = Color(stroke.colorValue).withValues(alpha: 0.92)
        ..style = PaintingStyle.stroke
        ..strokeWidth = stroke.width.clamp(1.0, 4.0)
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round;
      final path = Path()
        ..moveTo(
          stroke.points.first.x * size.width,
          stroke.points.first.y * size.height,
        );
      for (final point in stroke.points.skip(1)) {
        path.lineTo(point.x * size.width, point.y * size.height);
      }
      canvas.drawPath(path, strokePaint);
    }

    if (page.playerPath.length >= 2) {
      final playerPath = Path()
        ..moveTo(
          page.playerPath.first.x * size.width,
          page.playerPath.first.y * size.height,
        );
      for (final point in page.playerPath.skip(1)) {
        playerPath.lineTo(point.x * size.width, point.y * size.height);
      }
      canvas.drawPath(playerPath, pathPaint);
    }

    if (page.ballPath.length >= 2) {
      final ballPaint = Paint()
        ..color = const Color(0xFFFFF59D)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.6
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round;
      final ballPath = Path()
        ..moveTo(
          page.ballPath.first.x * size.width,
          page.ballPath.first.y * size.height,
        );
      for (final point in page.ballPath.skip(1)) {
        ballPath.lineTo(point.x * size.width, point.y * size.height);
      }
      canvas.drawPath(ballPath, ballPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _DiaryBoardPreviewPainter oldDelegate) {
    return oldDelegate.page != page;
  }
}

class _DiaryDayData {
  final DateTime date;
  final List<TrainingEntry> entries;
  final List<_DiaryPlan> plans;
  final List<TrainingBoard> boards;

  const _DiaryDayData({
    required this.date,
    required this.entries,
    required this.plans,
    required this.boards,
  });

  List<TrainingEntry> get trainingEntries =>
      entries.where((entry) => !entry.isMatch).toList(growable: false);

  List<TrainingEntry> get matchEntries =>
      entries.where((entry) => entry.isMatch).toList(growable: false);
}

class _DiaryPlan {
  final String id;
  final DateTime scheduledAt;
  final String category;
  final int durationMinutes;
  final String note;

  const _DiaryPlan({
    required this.id,
    required this.scheduledAt,
    required this.category,
    required this.durationMinutes,
    required this.note,
  });

  factory _DiaryPlan.fromMap(Map<String, dynamic> map) {
    return _DiaryPlan(
      id:
          map['id']?.toString() ??
          DateTime.now().microsecondsSinceEpoch.toString(),
      scheduledAt:
          DateTime.tryParse(map['scheduledAt']?.toString() ?? '') ??
          DateTime.now(),
      category: map['category']?.toString() ?? '',
      durationMinutes: (map['durationMinutes'] as num?)?.toInt() ?? 60,
      note: map['note']?.toString() ?? '',
    );
  }
}
