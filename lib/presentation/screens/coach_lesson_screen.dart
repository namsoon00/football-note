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
import '../models/training_board_link_codec.dart';
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

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final stream = widget.trainingService?.watchEntries() ??
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
                  children: [
                    _buildIntroCard(dayCount: 0, selectedLabel: _emptyLabel),
                    const SizedBox(height: 12),
                    _buildEmptyCard(),
                  ],
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
                    child: _buildIntroCard(
                      dayCount: days.length,
                      selectedLabel: _formatDiaryDate(selectedDay.date),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                    child: _buildPagerCard(days.length, selectedIndex),
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

  String get _emptyLabel => _isKo ? '작성할 기록 없음' : 'No diary day yet';

  Widget _buildIntroCard({
    required int dayCount,
    required String selectedLabel,
  }) {
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [_starbucksGreen, _deepGreen],
        ),
        borderRadius: BorderRadius.circular(28),
        boxShadow: const [
          BoxShadow(
            color: Color(0x24000000),
            blurRadius: 24,
            offset: Offset(0, 12),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _isKo
                  ? '하루의 모든 기록을 밤에 다시 읽는 다이어리'
                  : 'A nightly diary for your full day',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              _isKo
                  ? '시합, 훈련 계획, 훈련 기록, 부상, 리프팅, 줄넘기, 훈련보드를 날짜별 한 페이지에 모았습니다.'
                  : 'Each page combines match notes, plans, training logs, injury, lifting, jump rope, and board links for one date.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.white70,
                    height: 1.45,
                  ),
            ),
            const SizedBox(height: 14),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _buildHeroChip(
                  _isKo ? '다이어리 $dayCount일치' : '$dayCount diary days',
                ),
                _buildHeroChip(selectedLabel),
                _buildHeroChip(_isKo ? '좌우 스와이프' : 'Swipe pages'),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeroChip(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white.withValues(alpha: 0.18)),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelLarge?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w700,
            ),
      ),
    );
  }

  Widget _buildPagerCard(int dayCount, int selectedIndex) {
    final canGoPrev = selectedIndex < dayCount - 1;
    final canGoNext = selectedIndex > 0;
    return Container(
      decoration: _paperDecoration(),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
        child: Row(
          children: [
            IconButton(
              tooltip: _isKo ? '이전 날짜' : 'Previous day',
              onPressed: canGoPrev ? () => _movePage(selectedIndex + 1) : null,
              icon: const Icon(Icons.chevron_left),
            ),
            Expanded(
              child: Column(
                children: [
                  Text(
                    _isKo ? '하루씩 넘겨보는 다이어리' : 'Daily football diary',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          color: _deepGreen,
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
                    ).textTheme.bodySmall?.copyWith(color: _coffee),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildDayHeadlineCard(day),
          const SizedBox(height: 12),
          _buildNightReviewCard(day, diary),
          const SizedBox(height: 12),
          _buildFactSummaryCard(day),
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
            _buildBoardCard(day.boards),
          ],
        ],
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
                    color: _deepGreen,
                    fontWeight: FontWeight.w900,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              _isKo
                  ? '자기 전에 오늘의 계획과 실전, 훈련 세부 기록을 한 번에 다시 읽는 페이지입니다.'
                  : 'A single page to revisit the day’s plan, match work, and training details before bed.',
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: _coffee, height: 1.45),
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
        color: _starbucksGreen.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelLarge?.copyWith(
              color: _starbucksGreen,
              fontWeight: FontWeight.w800,
            ),
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
        ).textTheme.bodyLarge?.copyWith(height: 1.7, color: _deepGreen),
      ),
    );
  }

  Widget _buildFactSummaryCard(_DiaryDayData day) {
    final liftingTotal = day.entries.fold<int>(
      0,
      (sum, entry) =>
          sum + entry.liftingByPart.values.fold<int>(0, (a, b) => a + b),
    );
    final jumpRopeCount = day.entries.fold<int>(
      0,
      (sum, entry) => sum + entry.jumpRopeCount,
    );
    final jumpRopeMinutes = day.entries.fold<int>(
      0,
      (sum, entry) => sum + entry.jumpRopeMinutes,
    );
    final injuries = day.entries.where((entry) => entry.injury).toList();

    return _buildPaperCard(
      title: _isKo ? '하루 요약' : 'Day summary',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSummaryLine(
            _isKo
                ? '훈련 주제: ${_topFocus(day.trainingEntries)}'
                : 'Training focus: ${_topFocus(day.trainingEntries)}',
          ),
          _buildSummaryLine(
            _isKo
                ? '기록 장소: ${_topPlaces(day.entries)}'
                : 'Locations: ${_topPlaces(day.entries)}',
          ),
          if (injuries.isNotEmpty)
            _buildSummaryLine(
              _isKo
                  ? '부상 기록: ${injuries.map(_injurySummary).join(' / ')}'
                  : 'Injury notes: ${injuries.map(_injurySummary).join(' / ')}',
            ),
          if (liftingTotal > 0)
            _buildSummaryLine(
              _isKo ? '리프팅 합계: $liftingTotal회' : 'Lifting total: $liftingTotal',
            ),
          if (jumpRopeCount > 0 || jumpRopeMinutes > 0)
            _buildSummaryLine(
              _isKo
                  ? '줄넘기: ${jumpRopeCount > 0 ? '$jumpRopeCount회' : ''}${jumpRopeCount > 0 && jumpRopeMinutes > 0 ? ' · ' : ''}${jumpRopeMinutes > 0 ? '$jumpRopeMinutes분' : ''}'
                  : 'Jump rope: ${jumpRopeCount > 0 ? '$jumpRopeCount reps' : ''}${jumpRopeCount > 0 && jumpRopeMinutes > 0 ? ' · ' : ''}${jumpRopeMinutes > 0 ? '$jumpRopeMinutes min' : ''}',
            ),
        ],
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

  Widget _buildBoardCard(List<TrainingBoard> boards) {
    return _buildPaperCard(
      title: _isKo ? '연결된 훈련보드' : 'Linked training boards',
      child: Column(
        children: boards
            .map(
              (board) => _buildTimelineTile(
                title: board.title,
                detail: _isKo
                    ? '보드 업데이트 ${DateFormat('M.d HH:mm', 'ko').format(board.updatedAt)}'
                    : 'Updated ${DateFormat('MMM d HH:mm', 'en').format(board.updatedAt)}',
              ),
            )
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
        ).textTheme.bodyMedium?.copyWith(color: _coffee, height: 1.5),
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
                        style:
                            Theme.of(context).textTheme.titleMedium?.copyWith(
                                  color: _deepGreen,
                                  fontWeight: FontWeight.w900,
                                ),
                      ),
                      if (subtitle != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          subtitle,
                          style: Theme.of(context)
                              .textTheme
                              .bodySmall
                              ?.copyWith(color: _coffee, height: 1.45),
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
        color: Colors.white.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _paperBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  color: _deepGreen,
                  fontWeight: FontWeight.w800,
                ),
          ),
          const SizedBox(height: 4),
          Text(
            detail,
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: _coffee, height: 1.45),
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
        ).textTheme.bodyMedium?.copyWith(color: _deepGreen, height: 1.5),
      ),
    );
  }

  BoxDecoration _paperDecoration() {
    return BoxDecoration(
      color: _paper,
      borderRadius: BorderRadius.circular(26),
      border: Border.all(color: _paperBorder),
      boxShadow: const [
        BoxShadow(
          color: Color(0x12000000),
          blurRadius: 18,
          offset: Offset(0, 10),
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

    final days = dayKeys.map((day) {
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
        entries: [...dayEntries]..sort((a, b) => a.date.compareTo(b.date)),
        plans: [...(plansByDay[day] ?? const <_DiaryPlan>[])]
          ..sort((a, b) => a.scheduledAt.compareTo(b.scheduledAt)),
        boards: linkedBoards.values.toList(growable: false)
          ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt)),
      );
    }).toList(growable: false)
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
    final lines = <String>[
      _isKo
          ? '${_formatDiaryDate(day.date)} 기록 요약'
          : 'Daily review for ${_formatDiaryDate(day.date)}',
    ];

    if (day.plans.isNotEmpty) {
      lines.add(
        _isKo
            ? '훈련 계획 ${day.plans.length}개가 있었고, ${day.plans.map((plan) => '${_formatTime(plan.scheduledAt)} ${plan.category} ${plan.durationMinutes}분').join(', ')}${day.plans.any((plan) => plan.note.trim().isNotEmpty) ? ' 일정 메모는 ${day.plans.map((plan) => plan.note.trim()).where((note) => note.isNotEmpty).join(' / ')}.' : '.'}'
            : 'There were ${day.plans.length} training plans: ${day.plans.map((plan) => '${_formatTime(plan.scheduledAt)} ${plan.category} ${plan.durationMinutes} min').join(', ')}${day.plans.any((plan) => plan.note.trim().isNotEmpty) ? '. Plan notes: ${day.plans.map((plan) => plan.note.trim()).where((note) => note.isNotEmpty).join(' / ')}.' : '.'}',
      );
    }

    if (day.matchEntries.isNotEmpty) {
      lines.add(
        _isKo
            ? '시합 기록은 ${day.matchEntries.map(_matchSummary).join(' / ')}'
            : 'Match record: ${day.matchEntries.map(_matchSummary).join(' / ')}',
      );
    }

    if (day.trainingEntries.isNotEmpty) {
      final totalMinutes = day.trainingEntries.fold<int>(
        0,
        (sum, entry) => sum + entry.durationMinutes,
      );
      lines.add(
        _isKo
            ? '훈련은 총 ${day.trainingEntries.length}개 기록으로 $totalMinutes분 진행했다. 핵심 주제는 ${_topFocus(day.trainingEntries)}이고, 세부 내용은 ${day.trainingEntries.map(_trainingSummary).join(' / ')}'
            : 'Training covered ${day.trainingEntries.length} logs and $totalMinutes minutes in total. Main focus was ${_topFocus(day.trainingEntries)}. Details: ${day.trainingEntries.map(_trainingSummary).join(' / ')}',
      );
    }

    final injuryEntries = day.entries.where((entry) => entry.injury).toList();
    if (injuryEntries.isNotEmpty) {
      lines.add(
        _isKo
            ? '부상 기록은 ${injuryEntries.map(_injurySummary).join(' / ')}'
            : 'Injury record: ${injuryEntries.map(_injurySummary).join(' / ')}',
      );
    }

    final lifting = _buildLiftingSummary(day.entries);
    if (lifting.isNotEmpty) {
      lines.add(_isKo ? '리프팅 기록은 $lifting' : 'Lifting record: $lifting');
    }

    final jumpRope = _buildJumpRopeSummary(day.entries);
    if (jumpRope.isNotEmpty) {
      lines.add(_isKo ? '줄넘기 기록은 $jumpRope' : 'Jump rope record: $jumpRope');
    }

    if (day.boards.isNotEmpty) {
      lines.add(
        _isKo
            ? '연결된 훈련보드는 ${day.boards.map((board) => board.title).join(', ')}'
            : 'Linked boards: ${day.boards.map((board) => board.title).join(', ')}',
      );
    }

    lines.add(
      _isKo
          ? '오늘 남긴 계획과 기록을 한 페이지에서 다시 읽고, 다음 목표는 입력된 메모와 목표 항목을 기준으로 정리하면 된다.'
          : 'This page keeps the full day in one place so the next target can be reviewed directly from the saved notes and goals.',
    );
    return lines.join('\n\n');
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
    return sorted.map((entry) => '${entry.key} ${entry.value}회').join(', ');
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
      id: map['id']?.toString() ??
          DateTime.now().microsecondsSinceEpoch.toString(),
      scheduledAt: DateTime.tryParse(map['scheduledAt']?.toString() ?? '') ??
          DateTime.now(),
      category: map['category']?.toString() ?? '',
      durationMinutes: (map['durationMinutes'] as num?)?.toInt() ?? 60,
      note: map['note']?.toString() ?? '',
    );
  }
}
