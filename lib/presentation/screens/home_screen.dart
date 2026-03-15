import 'dart:async';

import 'package:flutter/material.dart';
import '../../application/training_service.dart';
import '../../domain/repositories/option_repository.dart';
import '../../application/locale_service.dart';
import '../../application/settings_service.dart';
import '../../application/backup_service.dart';
import 'package:football_note/gen/app_localizations.dart';
import 'calendar_screen.dart';
import 'logs_screen.dart';
import 'stats_screen.dart';
import 'news_screen.dart';
import 'space_speed_game_screen.dart';
import 'entry_form_screen.dart';
import '../widgets/app_page_route.dart';

class HomeScreen extends StatefulWidget {
  final TrainingService trainingService;
  final OptionRepository optionRepository;
  final LocaleService localeService;
  final SettingsService settingsService;
  final BackupService? driveBackupService;
  final int initialIndex;
  final CalendarQuickCreateAction? calendarQuickCreateAction;

  const HomeScreen({
    super.key,
    required this.trainingService,
    required this.optionRepository,
    required this.localeService,
    required this.settingsService,
    this.driveBackupService,
    this.initialIndex = 0,
    this.calendarQuickCreateAction,
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late int _index;
  DateTime? _calendarSelectedDay;
  final Set<int> _guideCheckedInSession = <int>{};

  @override
  void initState() {
    super.initState();
    _index = widget.initialIndex;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      unawaited(_showTabGuideIfNeeded(_index));
    });
  }

  @override
  Widget build(BuildContext context) {
    final navBackground = Theme.of(context).colorScheme.surface;
    final pages = <Widget>[
      LogsScreen(
        trainingService: widget.trainingService,
        localeService: widget.localeService,
        optionRepository: widget.optionRepository,
        settingsService: widget.settingsService,
        driveBackupService: widget.driveBackupService,
        onEdit: _openEdit,
        onCreate: _openCreate,
      ),
      CalendarScreen(
        trainingService: widget.trainingService,
        localeService: widget.localeService,
        optionRepository: widget.optionRepository,
        settingsService: widget.settingsService,
        driveBackupService: widget.driveBackupService,
        onEdit: _openEdit,
        onCreate: () => _openCreate(initialDate: _calendarSelectedDay),
        quickCreateAction: widget.calendarQuickCreateAction,
        onSelectedDayChanged: (day) {
          _calendarSelectedDay = DateTime(day.year, day.month, day.day);
        },
      ),
      StatsScreen(
        trainingService: widget.trainingService,
        localeService: widget.localeService,
        onCreate: _openCreate,
        optionRepository: widget.optionRepository,
        settingsService: widget.settingsService,
        driveBackupService: widget.driveBackupService,
      ),
      NewsScreen(
        trainingService: widget.trainingService,
        localeService: widget.localeService,
        optionRepository: widget.optionRepository,
        settingsService: widget.settingsService,
        driveBackupService: widget.driveBackupService,
        isActive: _index == 3,
      ),
      SpaceSpeedGameScreen(
        trainingService: widget.trainingService,
        localeService: widget.localeService,
        optionRepository: widget.optionRepository,
        settingsService: widget.settingsService,
        driveBackupService: widget.driveBackupService,
      ),
    ];
    return Scaffold(
      body: IndexedStack(index: _index, children: pages),
      bottomNavigationBar: NavigationBar(
        backgroundColor: navBackground,
        indicatorColor: Theme.of(context).colorScheme.primary.withAlpha(38),
        labelBehavior: NavigationDestinationLabelBehavior.onlyShowSelected,
        selectedIndex: _index,
        onDestinationSelected: _onDestinationSelected,
        destinations: [
          NavigationDestination(
            icon: const Icon(Icons.list_alt_outlined),
            selectedIcon: const Icon(Icons.list_alt),
            label: AppLocalizations.of(context)!.tabLogs,
          ),
          NavigationDestination(
            icon: const Icon(Icons.calendar_month_outlined),
            selectedIcon: const Icon(Icons.calendar_month),
            label: AppLocalizations.of(context)!.tabCalendar,
          ),
          NavigationDestination(
            icon: const Icon(Icons.bar_chart_outlined),
            selectedIcon: const Icon(Icons.bar_chart),
            label: AppLocalizations.of(context)!.tabStats,
          ),
          NavigationDestination(
            icon: const Icon(Icons.newspaper_outlined),
            selectedIcon: const Icon(Icons.newspaper),
            label: AppLocalizations.of(context)!.tabNews,
          ),
          NavigationDestination(
            icon: const Icon(Icons.sports_esports_outlined),
            selectedIcon: const Icon(Icons.sports_esports),
            label: AppLocalizations.of(context)!.tabGame,
          ),
        ],
      ),
      floatingActionButton: null,
    );
  }

  void _onDestinationSelected(int value) {
    if (_index == value) return;
    setState(() => _index = value);
    unawaited(_showTabGuideIfNeeded(value));
  }

  Future<void> _showTabGuideIfNeeded(int tabIndex) async {
    if (!mounted) return;
    if (_guideCheckedInSession.contains(tabIndex)) return;
    _guideCheckedInSession.add(tabIndex);
    final key = 'tab_quick_guide_seen_v1_$tabIndex';
    final alreadySeen = widget.optionRepository.getValue<bool>(key) ?? false;
    if (alreadySeen) return;
    await widget.optionRepository.setValue(key, true);
    if (!mounted) return;
    final isKo = Localizations.localeOf(context).languageCode == 'ko';
    final (title, body) = _tabGuideCopy(tabIndex, isKo);
    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(body),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(isKo ? '확인' : 'OK'),
          ),
        ],
      ),
    );
  }

  (String, String) _tabGuideCopy(int tabIndex, bool isKo) {
    switch (tabIndex) {
      case 0:
        return (
          isKo ? '훈련기록 가이드' : 'Logs Guide',
          isKo
              ? '기록추가에서 훈련 노트를 만들고, 카드/리스트로 과거 기록을 빠르게 확인할 수 있어요.'
              : 'Create training notes from Add, then review past records in card/list views.',
        );
      case 1:
        return (
          isKo ? '캘린더 가이드' : 'Calendar Guide',
          isKo
              ? '날짜를 누르면 해당일 기록과 계획을 함께 볼 수 있어요. + 버튼으로 계획/시합/노트를 추가하세요.'
              : 'Tap a date to view that day’s notes and plans. Use + to add plan/match/note.',
        );
      case 2:
        return (
          isKo ? '통계 가이드' : 'Stats Guide',
          isKo
              ? '기간을 바꿔 성장 추이를 비교하고, 약한 지표를 다음 훈련 목표로 연결해보세요.'
              : 'Change period to compare trends and turn weak metrics into next training goals.',
        );
      case 3:
        return (
          isKo ? '소식 가이드' : 'News Guide',
          isKo
              ? '채널 선택과 검색으로 원하는 뉴스만 빠르게 확인할 수 있어요.'
              : 'Filter by channel and search to focus on the news you need.',
        );
      case 4:
        return (
          isKo ? '게임 가이드' : 'Game Guide',
          isKo
              ? '패스 게임/퀴즈로 판단력과 집중력을 짧게 반복 훈련할 수 있어요.'
              : 'Use pass game/quiz for short, repeatable decision-making training.',
        );
      default:
        return ('Guide', 'Quick guide');
    }
  }

  Future<void> _openCreate({DateTime? initialDate}) async {
    await Navigator.of(context).push(
      AppPageRoute(
        builder: (_) => EntryFormScreen(
          trainingService: widget.trainingService,
          optionRepository: widget.optionRepository,
          localeService: widget.localeService,
          settingsService: widget.settingsService,
          driveBackupService: widget.driveBackupService,
          initialDate: initialDate,
        ),
      ),
    );
  }

  Future<void> _openEdit(entry) async {
    await Navigator.of(context).push(
      AppPageRoute(
        builder: (_) => EntryFormScreen(
          trainingService: widget.trainingService,
          optionRepository: widget.optionRepository,
          entry: entry,
          localeService: widget.localeService,
          settingsService: widget.settingsService,
          driveBackupService: widget.driveBackupService,
        ),
      ),
    );
  }
}
