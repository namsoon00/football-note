import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../application/backup_service.dart';
import '../../application/locale_service.dart';
import '../../application/settings_service.dart';
import '../../application/training_service.dart';
import '../../domain/repositories/option_repository.dart';
import '../widgets/app_background.dart';
import '../widgets/app_drawer.dart';
import '../widgets/watch_cart/main_app_bar.dart';
import 'game_guide_screen.dart';
import 'profile_screen.dart';
import 'settings_screen.dart';

class SpaceSpeedGameScreen extends StatefulWidget {
  final TrainingService trainingService;
  final LocaleService localeService;
  final OptionRepository optionRepository;
  final SettingsService settingsService;
  final BackupService? driveBackupService;

  const SpaceSpeedGameScreen({
    super.key,
    required this.trainingService,
    required this.localeService,
    required this.optionRepository,
    required this.settingsService,
    this.driveBackupService,
  });

  @override
  State<SpaceSpeedGameScreen> createState() => _SpaceSpeedGameScreenState();
}

class _SpaceSpeedGameScreenState extends State<SpaceSpeedGameScreen> {
  static const _weeklyBestPrefix = 'space_speed_weekly_best_';
  static const _difficultyKey = 'space_speed_difficulty';

  static const _dt = 0.05;
  static const _passerX = 0.10;
  static const _passerY = 0.72;
  static const _ballMinSpeed = 0.35;
  static const _ballMaxSpeed = 1.25;
  static const _fieldMinX = 0.04;
  static const _fieldMaxX = 0.98;
  static const _fieldMinY = 0.04;
  static const _fieldMaxY = 0.96;
  static const _goalLineX = 0.965;
  static const _goalTopY = 0.30;
  static const _goalBottomY = 0.70;

  final _random = math.Random();
  Timer? _timer;
  Timer? _gameTimer;

  int _score = 0;
  int _goals = 0;
  int _combo = 0;
  int _weeklyBest = 0;
  int _level = 1;
  bool _gameStarted = false;
  int _remainingSeconds = 60;
  bool _timeUp = false;
  bool _endedByFail = false;
  bool _finalShotMode = false;
  String _finalRanking = '';
  late String _weekKey;

  _GameDifficulty _difficulty = _GameDifficulty.medium;
  _PlayPhase _phase = _PlayPhase.ready;

  double _receiverX = 0.50;
  double _receiverY = 0.36;
  double _receiverVx = 0.16;
  double _receiverVy = 0.07;
  double _passerXPos = _passerX;
  double _passerYPos = _passerY;
  double _passerVx = 0.06;
  double _passerVy = -0.02;
  double _passerSpeedMul = 1.0;
  double _receiverSpeedMul = 1.0;
  final double _leadDistance = 0.10;
  final List<_DefenderState> _defenders = <_DefenderState>[];
  static const int _levelUpEveryPasses = 3;
  bool _goalChanceActive = false;
  double _keeperY = (_goalTopY + _goalBottomY) / 2;
  double _keeperVy = 0.45;
  double _keeperPhase = 0;
  double _fieldScrollX = 0;
  bool _flightNearMissAwarded = false;

  bool _charging = false;
  DateTime? _chargeStartedAt;
  double _chargedBallSpeed = _ballMinSpeed;

  bool _ballFlying = false;
  double _ballX = _passerX;
  double _ballY = _passerY;
  double _ballVx = 0;
  double _ballVy = 0;
  double _flightElapsed = 0;
  double _noPassElapsed = 0;

  double _targetX = 0.60;
  double _targetY = 0.36;
  double _aimX = 0.60;
  double _aimY = 0.36;
  double? _pointerX;
  double? _pointerY;
  double _predReceiverTime = 0;
  double _idealBallSpeed = _ballMinSpeed;
  double _effectiveBallSpeed = _ballMinSpeed;
  double _passDistance = 0;
  double _lastAccuracy = 0;
  double _closestReceiverDistance = 999;
  double _timingDiffAtClosest = 999;
  bool _forwardWindow = false;
  double _forwardAlignment = 0;
  double _leadAlongMove = 0;
  double _lastControlProbability = 0;
  String _reactionLabel = '';
  String _reactionDetail = '';
  Color _reactionColor = const Color(0xFF8FA3BF);
  IconData _reactionIcon = Icons.adjust;
  bool _attackerAIsPasser = true;

  int get _rankScore => (_score * 10) + (_level * 15) + (_goals * 60);

  double get _pitchZoom {
    if (_finalShotMode) return 1.28;
    if (_goalChanceActive) return 1.16;
    return 1.0;
  }

  double get _activePasserX => _attackerAIsPasser ? _passerXPos : _receiverX;
  double get _activePasserY => _attackerAIsPasser ? _passerYPos : _receiverY;
  double get _activePasserVx => _attackerAIsPasser ? _passerVx : _receiverVx;
  double get _activePasserVy => _attackerAIsPasser ? _passerVy : _receiverVy;

  double get _activeReceiverX => _attackerAIsPasser ? _receiverX : _passerXPos;
  double get _activeReceiverY => _attackerAIsPasser ? _receiverY : _passerYPos;
  double get _activeReceiverVx => _attackerAIsPasser ? _receiverVx : _passerVx;
  double get _activeReceiverVy => _attackerAIsPasser ? _receiverVy : _passerVy;

  _ShotWindowHint _shotWindowHint(bool isKo) {
    if (!_goalChanceActive) {
      return const _ShotWindowHint(
        label: '',
        detail: '',
        color: Color(0xFF607D8B),
      );
    }
    final fromX = _activePasserX;
    final fromY = _activePasserY;
    final toX = _aimX.clamp(0.72, _goalLineX);
    final toY = _aimY.clamp(_goalTopY, _goalBottomY);
    final dist = _distance(fromX, fromY, toX, toY);
    final eta = dist / math.max(_chargedBallSpeed, 0.001);
    final keeperAtEta = _predictKeeperY(eta);
    final gap = (keeperAtEta - toY).abs();

    if (gap >= 0.12) {
      return _ShotWindowHint(
        label: isKo ? '지금 슛!' : 'Shoot now!',
        detail: isKo
            ? '골키퍼 빈 공간 큼 (ETA ${eta.toStringAsFixed(2)}s)'
            : 'Large keeper gap (ETA ${eta.toStringAsFixed(2)}s)',
        color: const Color(0xFF0FA968),
      );
    }

    double? bestT;
    for (var t = 0.15; t <= 1.8; t += 0.05) {
      final k = _predictKeeperY(t);
      if ((k - toY).abs() >= 0.12) {
        bestT = t;
        break;
      }
    }
    if (bestT != null) {
      return _ShotWindowHint(
        label: isKo ? '타이밍 대기' : 'Wait timing',
        detail: isKo
            ? '${bestT.toStringAsFixed(2)}초 뒤 슛 추천'
            : 'Shoot in ${bestT.toStringAsFixed(2)}s',
        color: const Color(0xFFF2994A),
      );
    }
    return _ShotWindowHint(
      label: isKo ? '빠른 슛 필요' : 'Fast release needed',
      detail: isKo ? '골키퍼가 라인을 잘 막고 있어요' : 'Keeper is covering the lane',
      color: const Color(0xFFEB5757),
    );
  }

  double _predictKeeperY(double time) {
    const center = (_goalTopY + _goalBottomY) * 0.5;
    const amp = (_goalBottomY - _goalTopY) * 0.36;
    final nextPhase = _keeperPhase + (time * 2.6);
    return (center + (math.sin(nextPhase) * amp))
        .clamp(_goalTopY + 0.05, _goalBottomY - 0.05);
  }

  @override
  void initState() {
    super.initState();
    _weekKey = _currentWeekKey(DateTime.now());
    _loadSavedState();
    _resetRound(keepScore: true);
    _startLoop();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _gameTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isKo = Localizations.localeOf(context).languageCode == 'ko';
    final shotHint = _shotWindowHint(isKo);

    final showTargetX = _ballFlying ? _targetX : _aimX;
    final showTargetY = _ballFlying ? _targetY : _aimY;

    return Scaffold(
      drawer: AppDrawer(
        trainingService: widget.trainingService,
        optionRepository: widget.optionRepository,
        localeService: widget.localeService,
        settingsService: widget.settingsService,
        driveBackupService: widget.driveBackupService,
        currentIndex: 4,
      ),
      body: AppBackground(
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Builder(
                  builder: (context) => WatchCartAppBar(
                    onMenuTap: () => Scaffold.of(context).openDrawer(),
                    profilePhotoSource: widget.optionRepository
                            .getValue<String>('profile_photo_url') ??
                        '',
                    onProfileTap: () => _openProfile(context),
                    onSettingsTap: () => _openSettings(context),
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: Theme.of(context)
                              .colorScheme
                              .surfaceContainerHighest
                              .withValues(alpha: 0.82),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: Theme.of(context)
                                .colorScheme
                                .primary
                                .withValues(alpha: 0.55),
                          ),
                        ),
                        child: Column(
                          children: [
                            Text(
                              isKo ? '성공 패스' : 'Passes',
                              style: Theme.of(context).textTheme.labelSmall,
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '$_score',
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                fontWeight: FontWeight.w900,
                                fontSize: 18,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: Theme.of(context)
                              .colorScheme
                              .surfaceContainerHighest
                              .withValues(alpha: 0.82),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: Theme.of(context)
                                .colorScheme
                                .primary
                                .withValues(alpha: 0.55),
                          ),
                        ),
                        child: Column(
                          children: [
                            Text(
                              isKo ? '남은 시간' : 'Time Left',
                              style: Theme.of(context).textTheme.labelSmall,
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '${_remainingSeconds}s',
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                fontWeight: FontWeight.w900,
                                fontSize: 18,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: Theme.of(context)
                              .colorScheme
                              .surfaceContainerHighest
                              .withValues(alpha: 0.82),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: Theme.of(context)
                                .colorScheme
                                .primary
                                .withValues(alpha: 0.55),
                          ),
                        ),
                        child: Column(
                          children: [
                            Text(
                              isKo ? '레벨' : 'Level',
                              style: Theme.of(context).textTheme.labelSmall,
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Lv.$_level',
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                fontWeight: FontWeight.w900,
                                fontSize: 18,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: Theme.of(context)
                              .colorScheme
                              .surfaceContainerHighest
                              .withValues(alpha: 0.82),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: Theme.of(context)
                                .colorScheme
                                .primary
                                .withValues(alpha: 0.55),
                          ),
                        ),
                        child: Column(
                          children: [
                            Text(
                              isKo ? '랭킹' : 'Rank',
                              style: Theme.of(context).textTheme.labelSmall,
                            ),
                            const SizedBox(height: 2),
                            Text(
                              _rankingLabel(_rankScore, isKo),
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                fontWeight: FontWeight.w900,
                                fontSize: 18,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        _goalChanceActive
                            ? (isKo ? '현재: 최종 슈팅 라운드' : 'Now: Final shot round')
                            : (isKo ? '현재: 패스 라운드' : 'Now: Pass round'),
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                      ),
                    ),
                    TextButton.icon(
                      onPressed: () => _openGameGuide(context),
                      icon: const Icon(Icons.menu_book_outlined, size: 16),
                      label: Text(isKo ? '게임 가이드' : 'Guide'),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                if (_goalChanceActive) ...[
                  const SizedBox(height: 6),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: shotHint.color.withAlpha(28),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: shotHint.color.withAlpha(160)),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.timer_outlined,
                            color: shotHint.color, size: 18),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                shotHint.label,
                                style: TextStyle(
                                  fontWeight: FontWeight.w800,
                                  color: shotHint.color,
                                ),
                              ),
                              Text(
                                shotHint.detail,
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 6),
                SegmentedButton<_GameDifficulty>(
                  segments: [
                    ButtonSegment(
                      value: _GameDifficulty.easy,
                      label: Text(isKo ? '초급' : 'Easy'),
                      icon: const Icon(Icons.sentiment_satisfied_alt),
                    ),
                    ButtonSegment(
                      value: _GameDifficulty.medium,
                      label: Text(isKo ? '중급' : 'Medium'),
                      icon: const Icon(Icons.sports_soccer),
                    ),
                    ButtonSegment(
                      value: _GameDifficulty.hard,
                      label: Text(isKo ? '고급' : 'Hard'),
                      icon: const Icon(Icons.bolt),
                    ),
                  ],
                  selected: {_difficulty},
                  onSelectionChanged: (selection) {
                    final next = selection.first;
                    if (next == _difficulty) return;
                    setState(() {
                      _difficulty = next;
                      _combo = 0;
                      _level =
                          ((_score ~/ _levelUpEveryPasses) + 1).clamp(1, 20);
                    });
                    widget.optionRepository.setValue(_difficultyKey, next.name);
                    _resetRound(keepScore: true);
                  },
                ),
                const SizedBox(height: 4),
                Expanded(
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final width = constraints.maxWidth;
                      final height = constraints.maxHeight;
                      return GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTapDown: (details) => _onFieldPointerDown(
                            details.localPosition, width, height),
                        onTapUp: (details) => _onFieldPointerUp(
                            details.localPosition, width, height),
                        onPanStart: (details) => _onFieldPointerDown(
                            details.localPosition, width, height),
                        onPanUpdate: (details) {
                          if (!_gameStarted ||
                              _phase != _PlayPhase.ready ||
                              _ballFlying) {
                            return;
                          }
                          setState(() {
                            _updatePointerFromLocal(
                                details.localPosition, width, height);
                            _updateAimFromLocal(
                                details.localPosition, width, height);
                          });
                        },
                        onPanEnd: (_) {
                          setState(() {
                            _releaseChargeAndPass();
                            _pointerX = null;
                            _pointerY = null;
                          });
                        },
                        onPanCancel: _cancelCharge,
                        child: AnimatedScale(
                          scale: _pitchZoom,
                          duration: const Duration(milliseconds: 260),
                          curve: Curves.easeOutCubic,
                          child: Container(
                            decoration: BoxDecoration(
                              color: const Color(0xFF132B3E),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                  color:
                                      const Color(0xFF4DD0E1).withAlpha(180)),
                            ),
                            child: Stack(
                              children: [
                                Positioned.fill(
                                  child: CustomPaint(
                                    painter: _MovingPitchPainter(
                                      scroll: _fieldScrollX,
                                    ),
                                  ),
                                ),
                                Positioned.fill(
                                  child: CustomPaint(
                                    painter: _ReceiverLanePainter(
                                      receiverX: _activeReceiverX,
                                      receiverY: _activeReceiverY,
                                      vx: _activeReceiverVx,
                                      vy: _activeReceiverVy,
                                    ),
                                  ),
                                ),
                                if (_goalChanceActive)
                                  const Positioned.fill(
                                    child: CustomPaint(
                                      painter: _GoalPainter(
                                        goalLineX: _goalLineX,
                                        goalTopY: _goalTopY,
                                        goalBottomY: _goalBottomY,
                                      ),
                                    ),
                                  ),
                                Positioned.fill(
                                  child: CustomPaint(
                                    painter: _GuidePainter(
                                      fromX: _activePasserX,
                                      fromY: _activePasserY,
                                      toX: showTargetX,
                                      toY: showTargetY,
                                      color: const Color(0xB34DD0E1),
                                    ),
                                  ),
                                ),
                                Positioned(
                                  left: showTargetX * width - 10,
                                  top: showTargetY * height - 10,
                                  child: Container(
                                    width: 20,
                                    height: 20,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                          color: const Color(0xFFFFE082),
                                          width: 2),
                                      color: const Color(0x55FFE082),
                                    ),
                                  ),
                                ),
                                _entity(
                                  context,
                                  x: _passerXPos,
                                  y: _passerYPos,
                                  size: 23,
                                  color: const Color(0xFFFFD54F),
                                  label: isKo ? '공격수 A' : 'Attacker A',
                                  width: width,
                                  height: height,
                                  emphasize: _attackerAIsPasser,
                                  roleTag: _attackerAIsPasser ? 'PASS' : 'NEXT',
                                ),
                                _entity(
                                  context,
                                  x: _receiverX,
                                  y: _receiverY,
                                  size: 23,
                                  color: const Color(0xFFFFC107),
                                  label: isKo ? '공격수 B' : 'Attacker B',
                                  width: width,
                                  height: height,
                                  emphasize: !_attackerAIsPasser,
                                  roleTag:
                                      !_attackerAIsPasser ? 'PASS' : 'NEXT',
                                ),
                                if (_reactionLabel.isNotEmpty)
                                  Positioned(
                                    top: 8,
                                    left: 10,
                                    right: 10,
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 12, vertical: 8),
                                      decoration: BoxDecoration(
                                        color: _reactionColor.withAlpha(230),
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: Row(
                                        children: [
                                          Expanded(
                                            child: Column(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                Row(
                                                  children: [
                                                    Icon(
                                                      _reactionIcon,
                                                      color: Colors.white,
                                                      size: 18,
                                                    ),
                                                    const SizedBox(width: 8),
                                                    Expanded(
                                                      child: Text(
                                                        _reactionLabel,
                                                        textAlign:
                                                            TextAlign.center,
                                                        style: const TextStyle(
                                                          color: Colors.white,
                                                          fontWeight:
                                                              FontWeight.w800,
                                                          fontSize: 14,
                                                        ),
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                                if (_reactionDetail
                                                    .isNotEmpty) ...[
                                                  const SizedBox(height: 4),
                                                  Text(
                                                    _reactionDetail,
                                                    textAlign: TextAlign.center,
                                                    style: const TextStyle(
                                                      color: Colors.white,
                                                      fontSize: 11,
                                                      fontWeight:
                                                          FontWeight.w600,
                                                      height: 1.2,
                                                    ),
                                                  ),
                                                ],
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                for (var i = 0; i < _defenders.length; i++)
                                  _entity(
                                    context,
                                    x: _defenders[i].x,
                                    y: _defenders[i].y,
                                    size: 21,
                                    color: _defenders[i].ghostType.color,
                                    label: isKo
                                        ? _defenders[i].ghostType.labelKo
                                        : _defenders[i].ghostType.labelEn,
                                    width: width,
                                    height: height,
                                    roleTag: _defenders[i].ghostType.roleTag,
                                  ),
                                if (_goalChanceActive)
                                  _entity(
                                    context,
                                    x: _goalLineX - 0.01,
                                    y: _keeperY,
                                    size: 22,
                                    color: const Color(0xFFFF6B6B),
                                    label: isKo ? 'GK' : 'GK',
                                    width: width,
                                    height: height,
                                  ),
                                _entity(
                                  context,
                                  x: _ballX,
                                  y: _ballY,
                                  size: 12,
                                  color: Colors.white,
                                  label: '',
                                  width: width,
                                  height: height,
                                ),
                                if (_charging &&
                                    _pointerX != null &&
                                    _pointerY != null)
                                  Positioned(
                                    left: (_pointerX! * width - 30)
                                        .clamp(6.0, width - 66.0),
                                    top: (_pointerY! * height - 64)
                                        .clamp(6.0, height - 54.0),
                                    child: _PointerGauge(
                                      ratio: _chargeRatio,
                                      isKo: isKo,
                                    ),
                                  ),
                                if (!_gameStarted || _timeUp)
                                  Positioned.fill(
                                    child: Container(
                                      color: Colors.black.withAlpha(96),
                                      padding: const EdgeInsets.fromLTRB(
                                          20, 24, 20, 28),
                                      child: Column(
                                        children: [
                                          const Spacer(),
                                          Container(
                                            constraints: const BoxConstraints(
                                                maxWidth: 320),
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 16,
                                              vertical: 14,
                                            ),
                                            decoration: BoxDecoration(
                                              color: Theme.of(context)
                                                  .colorScheme
                                                  .surface
                                                  .withValues(alpha: 0.97),
                                              borderRadius:
                                                  BorderRadius.circular(16),
                                              border: Border.all(
                                                color: Theme.of(context)
                                                    .colorScheme
                                                    .primary
                                                    .withValues(alpha: 0.8),
                                                width: 1.3,
                                              ),
                                              boxShadow: const [
                                                BoxShadow(
                                                  color: Color(0x66000000),
                                                  blurRadius: 16,
                                                  offset: Offset(0, 8),
                                                ),
                                              ],
                                            ),
                                            child: Column(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                if (_timeUp || _endedByFail)
                                                  Text(
                                                    isKo
                                                        ? (_endedByFail
                                                            ? '경기 종료'
                                                            : '최종 결과')
                                                        : (_endedByFail
                                                            ? 'Match Over'
                                                            : 'Final Result'),
                                                    style: const TextStyle(
                                                      fontSize: 18,
                                                      fontWeight:
                                                          FontWeight.w800,
                                                    ),
                                                  ),
                                                if (_timeUp || _endedByFail)
                                                  const SizedBox(height: 12),
                                                if (_timeUp || _endedByFail)
                                                  Column(
                                                    children: [
                                                      Text(
                                                        isKo
                                                            ? '랭킹 ${_finalRanking.isEmpty ? _rankingLabel(_rankScore, isKo) : _finalRanking}'
                                                            : 'Rank ${_finalRanking.isEmpty ? _rankingLabel(_rankScore, isKo) : _finalRanking}',
                                                        style: TextStyle(
                                                          fontSize: 18,
                                                          fontWeight:
                                                              FontWeight.w900,
                                                          color:
                                                              Theme.of(context)
                                                                  .colorScheme
                                                                  .primary,
                                                        ),
                                                      ),
                                                      const SizedBox(height: 6),
                                                      Text(
                                                        isKo
                                                            ? '점수 $_score  레벨 Lv.$_level  골 $_goals'
                                                            : 'Score $_score  Level Lv.$_level  Goals $_goals',
                                                        textAlign:
                                                            TextAlign.center,
                                                        style: const TextStyle(
                                                          fontWeight:
                                                              FontWeight.w700,
                                                        ),
                                                      ),
                                                      const SizedBox(
                                                          height: 14),
                                                    ],
                                                  ),
                                                FilledButton.icon(
                                                  onPressed: _startGame,
                                                  icon: const Icon(
                                                    Icons.play_arrow_rounded,
                                                    size: 24,
                                                  ),
                                                  label: Text(
                                                    isKo
                                                        ? '게임 시작'
                                                        : 'Start Game',
                                                    style: const TextStyle(
                                                      fontWeight:
                                                          FontWeight.w800,
                                                      fontSize: 16,
                                                    ),
                                                  ),
                                                  style: FilledButton.styleFrom(
                                                    minimumSize:
                                                        const Size.fromHeight(
                                                            52),
                                                    shape:
                                                        RoundedRectangleBorder(
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                              14),
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  _PassPrediction _predictPassTo(
      double ballSpeed, double targetX, double targetY) {
    final minForwardX = math.min(_fieldMaxX, _activePasserX + 0.06);
    final leadX = targetX.clamp(minForwardX, _fieldMaxX);
    final leadY = targetY.clamp(_fieldMinY, _fieldMaxY);
    final predTime = _distance(_activePasserX, _activePasserY, leadX, leadY) /
        math.max(ballSpeed, 0.001);
    final receiverTime =
        _distance(_activeReceiverX, _activeReceiverY, leadX, leadY) /
            _activeReceiverSpeedAbs;
    final idealSpeed = _distance(_activePasserX, _activePasserY, leadX, leadY) /
        math.max(receiverTime, 0.001);
    return _PassPrediction(
      targetX: leadX,
      targetY: leadY,
      ballTime: predTime,
      receiverTime: receiverTime,
      idealBallSpeed: idealSpeed,
    );
  }

  double get _chargeRatio {
    const range = _ballMaxSpeed - _ballMinSpeed;
    if (range <= 0) return 0;
    return ((_chargedBallSpeed - _ballMinSpeed) / range).clamp(0.0, 1.0);
  }

  void _startLoop() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(milliseconds: 50), (_) {
      if (!mounted) return;
      setState(() {
        if (!_gameStarted) return;
        if (_phase == _PlayPhase.ready && !_ballFlying) {
          _noPassElapsed += _dt;
          if (_noPassElapsed >= 3.0) {
            _onFail(_PassResult.idleTimeout);
            return;
          }
        } else {
          _noPassElapsed = 0;
        }
        _fieldScrollX = (_fieldScrollX + (_dt * 0.42)) % 1.0;
        _updatePlayers();
        _updateCharge();
        _updateBall();
      });
    });
  }

  void _startGame() {
    _gameTimer?.cancel();
    setState(() {
      _gameStarted = true;
      _timeUp = false;
      _endedByFail = false;
      _finalRanking = '';
      _remainingSeconds = 60;
      _score = 0;
      _goals = 0;
      _combo = 0;
      _finalShotMode = false;
      _goalChanceActive = false;
      _attackerAIsPasser = true;
      _level = 1;
      _resetRound(keepScore: false);
      _reactionLabel = '';
      _reactionDetail = '';
      _reactionColor = const Color(0xFF8FA3BF);
      _reactionIcon = Icons.adjust;
      _noPassElapsed = 0;
    });
    _gameTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      if (!_gameStarted || _timeUp) {
        timer.cancel();
        return;
      }
      setState(() {
        _remainingSeconds = (_remainingSeconds - 1).clamp(0, 999);
        if (_remainingSeconds <= 0) {
          _remainingSeconds = 0;
          _enterFinalShotMode();
          timer.cancel();
        }
      });
    });
  }

  void _updatePlayers() {
    final comboBoost = (1 + (_combo * 0.05)).clamp(1.0, 1.8);
    final levelBoost = (1 + ((_level - 1) * 0.07)).clamp(1.0, 2.1);
    final runSpeed = (0.15 + ((_level - 1) * 0.01)).clamp(0.15, 0.33);
    final clutchBoost = _remainingSeconds <= 15 ? 1.28 : 1.0;
    const avoidRadius = 0.22;
    var passerAvoidX = 0.0;
    var passerAvoidY = 0.0;
    var receiverAvoidX = 0.0;
    var receiverAvoidY = 0.0;
    for (final defender in _defenders) {
      final passerDx = _passerXPos - defender.x;
      final passerDy = _passerYPos - defender.y;
      final passerDist =
          math.sqrt((passerDx * passerDx) + (passerDy * passerDy));
      if (passerDist > 1e-4 && passerDist < avoidRadius) {
        final strength = (avoidRadius - passerDist) / avoidRadius;
        passerAvoidX += (passerDx / passerDist) * strength;
        passerAvoidY += (passerDy / passerDist) * strength;
      }

      final receiverDx = _receiverX - defender.x;
      final receiverDy = _receiverY - defender.y;
      final receiverDist = math.sqrt(
        (receiverDx * receiverDx) + (receiverDy * receiverDy),
      );
      if (receiverDist > 1e-4 && receiverDist < avoidRadius) {
        final strength = (avoidRadius - receiverDist) / avoidRadius;
        receiverAvoidX += (receiverDx / receiverDist) * strength;
        receiverAvoidY += (receiverDy / receiverDist) * strength;
      }
    }

    if (_random.nextDouble() < 0.05) {
      _passerVx += (_random.nextDouble() * 0.08) - 0.02;
      _passerVy += (_random.nextDouble() * 0.16) - 0.08;
    }
    if (_random.nextDouble() < 0.05) {
      _receiverVx += (_random.nextDouble() * 0.08) - 0.02;
      _receiverVy += (_random.nextDouble() * 0.16) - 0.08;
    }
    final forwardBoost = (1.0 + (passerAvoidX.abs() * 0.18)).clamp(1.0, 1.5);
    final forwardBoostB = (1.0 + (receiverAvoidX.abs() * 0.18)).clamp(1.0, 1.5);
    _passerVx += 0.018 * forwardBoost;
    _receiverVx += 0.018 * forwardBoostB;
    _passerVy += passerAvoidY * 0.045;
    _receiverVy += receiverAvoidY * 0.045;
    _passerVx = _passerVx.clamp(0.11, (runSpeed + 0.10) * clutchBoost);
    _receiverVx = _receiverVx.clamp(0.12, (runSpeed + 0.12) * clutchBoost);
    _passerVy = _passerVy.clamp(-0.19, 0.19);
    _receiverVy = _receiverVy.clamp(-0.19, 0.19);
    _passerSpeedMul = 1.0;
    _receiverSpeedMul = 1.0;
    _passerXPos += _passerVx * _dt;
    _passerYPos += _passerVy * _dt;
    _receiverX += _receiverVx * _dt;
    _receiverY += _receiverVy * _dt;

    const minX = 0.22;
    const maxX = 0.80;
    const minY = 0.14;
    const maxY = 0.86;
    if (_passerXPos <= minX || _passerXPos >= maxX) {
      _passerVx = _passerVx.abs() * 0.85;
      _passerXPos = _passerXPos.clamp(minX, maxX);
    }
    if (_receiverX <= minX || _receiverX >= maxX) {
      _receiverVx = _receiverVx.abs() * 0.85;
      _receiverX = _receiverX.clamp(minX, maxX);
    }
    if (_passerYPos <= minY || _passerYPos >= maxY) {
      _passerVy = -_passerVy;
      _passerYPos = _passerYPos.clamp(minY, maxY);
    }
    if (_receiverY <= minY || _receiverY >= maxY) {
      _receiverVy = -_receiverVy;
      _receiverY = _receiverY.clamp(minY, maxY);
    }
    const minForwardGap = 0.10;
    if (_activeReceiverX < (_activePasserX + minForwardGap)) {
      if (_attackerAIsPasser) {
        _receiverVx = (_receiverVx + 0.08).clamp(0.12, 0.38);
        _passerVx = (_passerVx - 0.03).clamp(0.10, 0.34);
        _receiverX = (_receiverX + 0.018).clamp(minX, maxX);
      } else {
        _passerVx = (_passerVx + 0.08).clamp(0.12, 0.38);
        _receiverVx = (_receiverVx - 0.03).clamp(0.10, 0.34);
        _passerXPos = (_passerXPos + 0.018).clamp(minX, maxX);
      }
    }

    final d = _distance(_passerXPos, _passerYPos, _receiverX, _receiverY);
    if (d < 0.16) {
      _receiverY = (_receiverY + 0.06).clamp(minY, maxY);
      _passerYPos = (_passerYPos - 0.06).clamp(minY, maxY);
    }

    if (_goalChanceActive) {
      _keeperPhase += _dt * 2.6;
      final baseY = _predictKeeperY(0);
      if (_ballFlying) {
        final dir = (_ballY - _keeperY).sign;
        _keeperY += dir * (_keeperVy * 1.45) * _dt;
      } else {
        _keeperY += (baseY - _keeperY) * 0.28;
      }
      _keeperY = _keeperY.clamp(_goalTopY + 0.05, _goalBottomY - 0.05);
    } else {
      _keeperPhase += _dt * 1.8;
      _keeperY += (_predictKeeperY(0) - _keeperY) * 0.20;
      _keeperY = _keeperY.clamp(_goalTopY + 0.05, _goalBottomY - 0.05);
    }

    for (final defender in _defenders) {
      final passBySpeed = defender.speed *
          defender.ghostType.speedFactor *
          comboBoost *
          levelBoost *
          clutchBoost;
      defender.x -= passBySpeed * _dt;
      final lanePoint = _lanePointAtX(defender.x);
      final roleTargetY = _roleTargetY(defender, lanePoint.dy);
      final lanePull =
          (lanePoint.dy - defender.y) * defender.ghostType.lanePull * _dt;
      final rolePull =
          (roleTargetY - defender.y) * defender.ghostType.rolePull * _dt;
      defender.y +=
          (defender.vy * passBySpeed * defender.ghostType.wobbleFactor * _dt) +
              lanePull +
              rolePull;
      if (_random.nextDouble() <
          (defender.turnChance * defender.ghostType.turnFactor)) {
        defender.vy += (_random.nextDouble() * 2 - 1) * defender.turnRadians;
      }
      defender.vy = defender.vy.clamp(-1.5, 1.5);
      if (defender.y > defender.maxY || defender.y < defender.minY) {
        defender.vy = -defender.vy;
        defender.y = defender.y.clamp(defender.minY, defender.maxY);
      }
      if (defender.x < defender.minX) {
        final furthestX = _furthestDefenderX(except: defender);
        defender.x = math.max(defender.maxX, furthestX + 0.28);
        final lane = _lanePointAtX(defender.x);
        final roleY = _roleTargetY(defender, lane.dy);
        defender.y = (roleY + ((_random.nextDouble() - 0.5) * 0.20))
            .clamp(defender.minY, defender.maxY);
      }
    }

    if (_finalShotMode) {
      const targetShooterX = 0.72;
      const targetSupportX = 0.62;
      if (_attackerAIsPasser) {
        _passerXPos += (targetShooterX - _passerXPos) * 0.14;
        _receiverX += (targetSupportX - _receiverX) * 0.12;
      } else {
        _receiverX += (targetShooterX - _receiverX) * 0.14;
        _passerXPos += (targetSupportX - _passerXPos) * 0.12;
      }
      _passerYPos = _passerYPos.clamp(0.28, 0.82);
      _receiverY = _receiverY.clamp(0.22, 0.86);
    }

    final leadX = math.max(_passerXPos, _receiverX);
    if (leadX > 0.60) {
      final shift = leadX - 0.60;
      _passerXPos -= shift;
      _receiverX -= shift;
      _ballX -= shift;
      _targetX = (_targetX - shift).clamp(_fieldMinX, _fieldMaxX);
      _aimX = (_aimX - shift).clamp(_fieldMinX, _fieldMaxX);
      for (final defender in _defenders) {
        defender.x -= shift;
      }
      _fieldScrollX = (_fieldScrollX + (shift * 2.8)).remainder(1.0);
    }
  }

  void _updateCharge() {
    if (!_charging || _chargeStartedAt == null) return;
    final held =
        DateTime.now().difference(_chargeStartedAt!).inMilliseconds / 1000.0;
    _chargedBallSpeed =
        (_ballMinSpeed + held * 0.8).clamp(_ballMinSpeed, _ballMaxSpeed);
  }

  void _updateBall() {
    if (!_ballFlying) {
      _ballX = _activePasserX;
      _ballY = _activePasserY;
      return;
    }

    _flightElapsed += _dt;
    _ballX += _ballVx * _dt;
    _ballY += _ballVy * _dt;

    final currentDistance =
        _distance(_ballX, _ballY, _activeReceiverX, _activeReceiverY);
    if (currentDistance < _closestReceiverDistance) {
      _closestReceiverDistance = currentDistance;
      _timingDiffAtClosest = _flightElapsed - _predReceiverTime;
    }

    if (_isIntercepted()) {
      _onFail(_PassResult.intercepted);
      return;
    }
    _trackNearMiss();

    if (_goalChanceActive) {
      if (_crossedGoalLine()) {
        final blocked =
            _distance(_ballX, _ballY, _goalLineX - 0.01, _keeperY) <= 0.055;
        if (blocked) {
          _onFail(_PassResult.saved);
        } else {
          _onGoalScored();
        }
        return;
      }

      final outShot = _ballX > 1.02 ||
          _ballY < 0.05 ||
          _ballY > 0.95 ||
          _flightElapsed > 3.2;
      if (outShot) {
        _onFail(_PassResult.miss);
      }
      return;
    }

    final caughtByCenter =
        _distance(_ballX, _ballY, _activeReceiverX, _activeReceiverY) <=
            (_forwardWindow ? 0.060 : 0.045);
    final receivingEval = _receivingWindowEvaluation();
    final caughtByWindow = receivingEval.inside;
    if (caughtByCenter || caughtByWindow) {
      if (caughtByWindow && !caughtByCenter) {
        _closestReceiverDistance = math.min(_closestReceiverDistance, 0.055);
      }
      final timingGap = (_flightElapsed - _predReceiverTime).abs();
      _lastControlProbability = _controlProbability(
        receivingEval,
        timingGap: timingGap,
        byCenter: caughtByCenter,
      );
      _onSuccess();
      return;
    }

    final reachedTarget =
        _distance(_ballX, _ballY, _targetX, _targetY) <= 0.025;
    final out = _ballX > 1.02 ||
        _ballY < -0.05 ||
        _ballY > 1.05 ||
        _flightElapsed > 3.0;
    if (reachedTarget || out) {
      _onFail(_PassResult.miss);
    }
  }

  bool _isIntercepted() {
    for (final defender in _defenders) {
      if (_distance(_ballX, _ballY, defender.x, defender.y) <=
          defender.ghostType.interceptRadius) {
        return true;
      }
    }
    return false;
  }

  bool _crossedGoalLine() {
    return _ballX >= _goalLineX &&
        _ballY >= _goalTopY &&
        _ballY <= _goalBottomY;
  }

  void _beginCharge() {
    if (_phase != _PlayPhase.ready || _ballFlying) return;
    _charging = true;
    _chargeStartedAt = DateTime.now();
    _chargedBallSpeed = _ballMinSpeed;
    _effectiveBallSpeed = _ballMinSpeed;
  }

  void _releaseChargeAndPass() {
    if (!_charging || _phase != _PlayPhase.ready || _ballFlying) return;
    _charging = false;
    _chargeStartedAt = null;
    _noPassElapsed = 0;
    if (_goalChanceActive) {
      _targetX = _aimX.clamp(0.72, _goalLineX);
      _targetY = _aimY.clamp(_goalTopY, _goalBottomY);
      final dx = _targetX - _activePasserX;
      final dy = _targetY - _activePasserY;
      final dist = math.sqrt(dx * dx + dy * dy);
      if (dist < 1e-6) return;
      final dirX = dx / dist;
      final dirY = dy / dist;
      _effectiveBallSpeed =
          _chargedBallSpeed.clamp(_ballMinSpeed, _ballMaxSpeed);
      _predReceiverTime = 0;
      _ballVx = dirX * _effectiveBallSpeed;
      _ballVy = dirY * _effectiveBallSpeed;
      _ballX = _activePasserX;
      _ballY = _activePasserY;
      _flightElapsed = 0;
      _closestReceiverDistance = 999;
      _timingDiffAtClosest = 999;
      _ballFlying = true;
      _phase = _PlayPhase.flying;
      _flightNearMissAwarded = false;
      return;
    }
    final prediction = _predictPassTo(_chargedBallSpeed, _aimX, _aimY);
    _targetX = prediction.targetX;
    _targetY = prediction.targetY;

    final dx = _targetX - _activePasserX;
    final dy = _targetY - _activePasserY;
    final dist = math.sqrt(dx * dx + dy * dy);
    if (dist < 1e-6) return;
    _passDistance = dist;

    _predReceiverTime = prediction.receiverTime;
    _idealBallSpeed = prediction.idealBallSpeed;
    final forward = _forwardPassInfo(_targetX, _targetY);
    _forwardWindow = forward.inWindow;
    _forwardAlignment = forward.alignment;
    _leadAlongMove = forward.leadAlongMove;

    final passDirX = dx / dist;
    final passDirY = dy / dist;
    final passerSpeed = math.max(
      0.001,
      math.sqrt(_activePasserVx * _activePasserVx +
          _activePasserVy * _activePasserVy),
    );
    final passerDirX = _activePasserVx / passerSpeed;
    final passerDirY = _activePasserVy / passerSpeed;
    final bodyTurn = _turnAngle(
      passerDirX,
      passerDirY,
      passDirX,
      passDirY,
    );
    final bodyTurnPenalty =
        (1 - (0.20 * (bodyTurn / math.pi))).clamp(0.78, 1.0);
    _effectiveBallSpeed = (_chargedBallSpeed * bodyTurnPenalty)
        .clamp(_ballMinSpeed, _ballMaxSpeed);
    _ballVx = passDirX * _effectiveBallSpeed;
    _ballVy = passDirY * _effectiveBallSpeed;
    _ballX = _activePasserX;
    _ballY = _activePasserY;
    _flightElapsed = 0;
    _closestReceiverDistance = 999;
    _timingDiffAtClosest = 999;
    _ballFlying = true;
    _phase = _PlayPhase.flying;
    _flightNearMissAwarded = false;
  }

  void _trackNearMiss() {
    if (_flightNearMissAwarded) return;
    var nearest = 999.0;
    for (final defender in _defenders) {
      final d = _distance(_ballX, _ballY, defender.x, defender.y);
      if (d < nearest) nearest = d;
    }
    if (nearest > 0.038 && nearest <= 0.070) {
      _flightNearMissAwarded = true;
      _setReaction(_PassResult.nearMiss);
    }
  }

  void _cancelCharge() {
    if (!_charging) return;
    setState(() {
      _charging = false;
      _chargeStartedAt = null;
      _chargedBallSpeed = _ballMinSpeed;
      _effectiveBallSpeed = _ballMinSpeed;
      _pointerX = null;
      _pointerY = null;
    });
  }

  void _onSuccess() {
    _setReaction(_PassResult.perfect);
    _attackerAIsPasser = !_attackerAIsPasser;
    _score += 1;
    _combo += 1;
    _maybeLevelUp();
    _updateWeeklyBest();
    _continueAfterSuccess();
  }

  void _onGoalScored() {
    _goals += 1;
    _score += 3;
    _goalChanceActive = false;
    _finalShotMode = false;
    _setReaction(_PassResult.goal);
    _finishMatch();
  }

  void _activateGoalChance() {
    _goalChanceActive = true;
    _setReaction(_PassResult.shotReady);
    _phase = _PlayPhase.ready;
    _attackerAIsPasser = true;
    _ballFlying = false;
    _charging = false;
    _chargeStartedAt = null;
    _ballVx = 0;
    _ballVy = 0;
    _flightElapsed = 0;
    _closestReceiverDistance = 999;
    _timingDiffAtClosest = 999;
    _aimX = _goalLineX;
    _aimY = ((_activePasserY + _activeReceiverY) * 0.5)
        .clamp(_goalTopY, _goalBottomY);
    _ballX = _activePasserX;
    _ballY = _activePasserY;
  }

  void _enterFinalShotMode() {
    _finalShotMode = true;
    _defenders.clear();
    _noPassElapsed = 0;
    _activateGoalChance();
    _setReaction(_PassResult.shotReady);
  }

  void _finishMatch({bool failed = false}) {
    _phase = _PlayPhase.roundEnd;
    _ballFlying = false;
    _charging = false;
    _chargeStartedAt = null;
    _pointerX = null;
    _pointerY = null;
    _gameStarted = false;
    _timeUp = true;
    _endedByFail = failed;
    _goalChanceActive = false;
    _finalShotMode = false;
    _finalRanking = _rankingLabel(_rankScore, true);
    _updateWeeklyBest();
    _gameTimer?.cancel();
  }

  void _onFail([_PassResult result = _PassResult.miss]) {
    _combo = 0;
    _setReaction(result);
    if (_finalShotMode) {
      _finishMatch(failed: true);
    } else {
      _endGameOnFail();
    }
  }

  void _continueAfterSuccess() {
    _phase = _PlayPhase.ready;
    _ballFlying = false;
    _charging = false;
    _chargeStartedAt = null;
    _chargedBallSpeed = _ballMinSpeed;
    _effectiveBallSpeed = _ballMinSpeed;
    _ballX = _activePasserX;
    _ballY = _activePasserY;
    _ballVx = 0;
    _ballVy = 0;
    _flightElapsed = 0;
    _closestReceiverDistance = 999;
    _timingDiffAtClosest = 999;

    _passerVx = _passerVx.abs().clamp(0.12, 0.24);
    _passerVy = 0;
    _receiverVx = _receiverVx.abs().clamp(0.14, 0.26);
    _receiverVy = 0;

    _targetX = (_activeReceiverX + _leadDistance).clamp(_fieldMinX, _fieldMaxX);
    _targetY = _activeReceiverY;
    _predReceiverTime = 0;
    _idealBallSpeed = _ballMinSpeed;
    _forwardWindow = false;
    _forwardAlignment = 0;
    _leadAlongMove = 0;
    if (!_goalChanceActive) {
      _aimX = _targetX;
      _aimY = _targetY;
    }
  }

  void _maybeLevelUp() {
    final expectedLevel = ((_score ~/ _levelUpEveryPasses) + 1).clamp(1, 20);
    if (expectedLevel <= _level) return;
    _level = expectedLevel;
    _syncDefendersForLevel();
    _reactionLabel = _koText(
      '레벨 업! Lv.$_level',
      'Level Up! Lv.$_level',
    );
    _reactionDetail = _koText(
      '수비수가 더 빨라지고 압박이 강해집니다.',
      'Defenders get faster and pressure increases.',
    );
    _reactionIcon = Icons.trending_up_rounded;
    _reactionColor = const Color(0xFF2F80ED);
  }

  int _defenderCountForCurrentLevel() {
    final bonus = (_level - 1);
    return (_difficulty.defenderCount + bonus)
        .clamp(
          _difficulty.defenderCount,
          _difficultyMaxDefenders(_difficulty),
        )
        .toInt();
  }

  void _syncDefendersForLevel() {
    final targetCount = _defenderCountForCurrentLevel();
    if (_defenders.length < targetCount) {
      _defenders.addAll(
        _buildDefenders(_difficulty, count: targetCount - _defenders.length),
      );
    } else if (_defenders.length > targetCount) {
      _defenders.removeRange(targetCount, _defenders.length);
    }
  }

  void _endGameOnFail() {
    _phase = _PlayPhase.roundEnd;
    _ballFlying = false;
    _charging = false;
    _chargeStartedAt = null;
    _pointerX = null;
    _pointerY = null;
    _gameStarted = false;
    _endedByFail = true;
    _timeUp = true;
    _finalRanking = _rankingLabel(_rankScore, true);
    _updateWeeklyBest();
    _gameTimer?.cancel();
  }

  void _resetRound({required bool keepScore}) {
    if (!keepScore) {
      _score = 0;
      _goals = 0;
      _combo = 0;
      _finalShotMode = false;
      _goalChanceActive = false;
    }

    _phase = _PlayPhase.ready;
    _passerXPos = 0.14;
    _passerYPos = 0.68;
    _passerVx = 0.14;
    _passerVy = 0;
    _passerSpeedMul = 1.0;
    _receiverX = 0.34;
    _receiverY = 0.46;
    _receiverVx = 0.17;
    _receiverVy = 0;
    _receiverSpeedMul = 1.0;

    _defenders
      ..clear()
      ..addAll(
        _buildDefenders(_difficulty, count: _defenderCountForCurrentLevel()),
      );

    _ballFlying = false;
    _ballX = _passerXPos;
    _ballY = _passerYPos;
    _ballVx = 0;
    _ballVy = 0;
    _flightElapsed = 0;

    _charging = false;
    _chargeStartedAt = null;
    _chargedBallSpeed = _ballMinSpeed;
    _effectiveBallSpeed = _ballMinSpeed;

    _targetX = (_receiverX + _leadDistance).clamp(_fieldMinX, _fieldMaxX);
    _targetY = _receiverY;
    _aimX = _targetX;
    _aimY = _targetY;
    _pointerX = null;
    _pointerY = null;
    _predReceiverTime = 0;
    _idealBallSpeed = _ballMinSpeed;
    _forwardWindow = false;
    _forwardAlignment = 0;
    _leadAlongMove = 0;
    _lastControlProbability = 0;
    _keeperY = (_goalTopY + _goalBottomY) / 2;
    _keeperVy = _random.nextBool() ? 0.45 : -0.45;
    _fieldScrollX = 0;
    _noPassElapsed = 0;
    if (!keepScore) {
      _lastAccuracy = 0;
      _reactionLabel = '';
      _reactionDetail = '';
      _reactionColor = const Color(0xFF8FA3BF);
      _reactionIcon = Icons.adjust;
    }
  }

  void _onFieldPointerDown(Offset local, double width, double height) {
    if (!_gameStarted || _phase != _PlayPhase.ready || _ballFlying) return;
    setState(() {
      _updatePointerFromLocal(local, width, height);
      _updateAimFromLocal(local, width, height);
      _beginCharge();
    });
  }

  void _onFieldPointerUp(Offset local, double width, double height) {
    if (!_gameStarted || _phase != _PlayPhase.ready || _ballFlying) return;
    setState(() {
      _updatePointerFromLocal(local, width, height);
      _updateAimFromLocal(local, width, height);
      _releaseChargeAndPass();
      _pointerX = null;
      _pointerY = null;
    });
  }

  void _updateAimFromLocal(Offset local, double width, double height) {
    if (width <= 0 || height <= 0) return;
    final nx = (local.dx / width).clamp(_fieldMinX, _fieldMaxX);
    final ny = (local.dy / height).clamp(_fieldMinY, _fieldMaxY);
    if (_goalChanceActive) {
      _aimX = nx.clamp(0.72, _goalLineX);
      _aimY = ny.clamp(_goalTopY, _goalBottomY);
      return;
    }
    final end = _forwardOnlyTarget(_rayToBoundary(nx, ny));
    _aimX = end.dx;
    _aimY = end.dy;
  }

  Offset _forwardOnlyTarget(Offset target) {
    final minForwardX = math.min(_fieldMaxX, _activePasserX + 0.06);
    return Offset(
      target.dx.clamp(minForwardX, _fieldMaxX),
      target.dy.clamp(_fieldMinY, _fieldMaxY),
    );
  }

  void _updatePointerFromLocal(Offset local, double width, double height) {
    if (width <= 0 || height <= 0) return;
    _pointerX = (local.dx / width).clamp(0.0, 1.0);
    _pointerY = (local.dy / height).clamp(0.0, 1.0);
  }

  Offset _rayToBoundary(double aimX, double aimY) {
    const minX = _fieldMinX;
    const maxX = _fieldMaxX;
    const minY = _fieldMinY;
    const maxY = _fieldMaxY;

    final sx = _activePasserX;
    final sy = _activePasserY;
    final dx = aimX - sx;
    final dy = aimY - sy;
    if (dx.abs() < 1e-6 && dy.abs() < 1e-6) {
      return Offset(maxX, sy);
    }

    final candidates = <double>[];
    if (dx.abs() > 1e-6) {
      candidates.add((minX - sx) / dx);
      candidates.add((maxX - sx) / dx);
    }
    if (dy.abs() > 1e-6) {
      candidates.add((minY - sy) / dy);
      candidates.add((maxY - sy) / dy);
    }

    double? bestT;
    Offset? best;
    for (final t in candidates) {
      if (t <= 0) continue;
      final x = sx + dx * t;
      final y = sy + dy * t;
      if (x < minX - 1e-6 || x > maxX + 1e-6) continue;
      if (y < minY - 1e-6 || y > maxY + 1e-6) continue;
      if (bestT == null || t < bestT) {
        bestT = t;
        best = Offset(x.clamp(minX, maxX), y.clamp(minY, maxY));
      }
    }

    return best ?? Offset(aimX.clamp(minX, maxX), aimY.clamp(minY, maxY));
  }

  _ForwardPassInfo _forwardPassInfo(double targetX, double targetY) {
    final speed = _activeReceiverSpeedAbs;
    if (speed <= 0.001) {
      return const _ForwardPassInfo(
        inWindow: false,
        alignment: 0,
        leadAlongMove: 0,
      );
    }
    final dirX = _activeReceiverVx / speed;
    final dirY = _activeReceiverVy / speed;
    final toX = targetX - _activeReceiverX;
    final toY = targetY - _activeReceiverY;
    final dist = math.sqrt(toX * toX + toY * toY);
    if (dist <= 1e-6) {
      return const _ForwardPassInfo(
        inWindow: false,
        alignment: 0,
        leadAlongMove: 0,
      );
    }
    final alignment = (toX * dirX + toY * dirY) / dist;
    final leadAlongMove = (toX * dirX + toY * dirY);
    final inWindow = alignment >= 0.25 && leadAlongMove > 0;
    return _ForwardPassInfo(
      inWindow: inWindow,
      alignment: alignment,
      leadAlongMove: leadAlongMove,
    );
  }

  _ReceivingWindowEval _receivingWindowEvaluation() {
    final speed = _activeReceiverSpeedAbs;
    if (speed <= 1e-6) {
      return const _ReceivingWindowEval(
        inside: false,
        fit: 0,
      );
    }

    final dirX = _activeReceiverVx / speed;
    final dirY = _activeReceiverVy / speed;
    final perpX = -dirY;
    final perpY = dirX;

    final relX = _ballX - _activeReceiverX;
    final relY = _ballY - _activeReceiverY;
    final along = relX * dirX + relY * dirY;
    final lateral = (relX * perpX + relY * perpY).abs();

    final speedNorm = ((_effectiveBallSpeed - _ballMinSpeed) /
            (_ballMaxSpeed - _ballMinSpeed))
        .clamp(0.0, 1.0);
    final runnerNorm = ((speed - _difficulty.receiverBaseSpeed) /
            math.max(_difficulty.receiverRange, 0.001))
        .clamp(0.0, 1.0);

    // Soccer receive window: more range forward, moderate side tolerance,
    // and smaller room behind the runner.
    final forwardReach =
        (0.10 + (runnerNorm * 0.03) + (_forwardWindow ? 0.02 : 0.0))
            .clamp(0.10, 0.16);
    final backReach = (0.055 + ((1 - speedNorm) * 0.015)).clamp(0.045, 0.075);
    final lateralReach = (0.070 +
            (runnerNorm * 0.020) +
            (_forwardWindow ? 0.015 : 0.0) -
            (speedNorm * 0.010))
        .clamp(0.060, 0.105);

    final inside =
        along >= -backReach && along <= forwardReach && lateral <= lateralReach;
    if (!inside) {
      return const _ReceivingWindowEval(
        inside: false,
        fit: 0,
      );
    }

    final alongFit = along >= 0
        ? (1 - ((along / forwardReach) * 0.70)).clamp(0.0, 1.0)
        : (1 - ((along.abs() / backReach) * 0.90)).clamp(0.0, 1.0);
    final lateralFit = (1 - (lateral / lateralReach)).clamp(0.0, 1.0);
    final fit = (alongFit * 0.45 + lateralFit * 0.55).clamp(0.0, 1.0);

    return _ReceivingWindowEval(
      inside: true,
      fit: fit,
    );
  }

  double _controlProbability(
    _ReceivingWindowEval receivingEval, {
    required double timingGap,
    required bool byCenter,
  }) {
    // Data-inspired weighting: pass control quality is strongly driven by
    // pass angle/direction, arrival timing, and relative speed.
    final speedGapRatio = ((_effectiveBallSpeed - _idealBallSpeed).abs() /
            math.max(_idealBallSpeed, 0.001))
        .clamp(0.0, 1.5);
    final timingScore = (1 - (timingGap / 0.55)).clamp(0.0, 1.0);
    final speedScore = (1 - (speedGapRatio / 1.0)).clamp(0.0, 1.0);
    final distanceScore =
        (1 - ((_passDistance - 0.42).abs() / 0.45)).clamp(0.0, 1.0).toDouble();
    final directionalScore =
        ((_forwardAlignment + 0.15) / 1.15).clamp(0.0, 1.0).toDouble();
    final leadScore =
        (1 - ((_leadAlongMove - 0.08).abs() / 0.28)).clamp(0.0, 1.0).toDouble();
    final fitScore = receivingEval.fit;

    var probability = (fitScore * 0.36) +
        (directionalScore * 0.19) +
        (leadScore * 0.10) +
        (timingScore * 0.18) +
        (speedScore * 0.11) +
        (distanceScore * 0.06);
    if (byCenter) probability += 0.10;
    if (_forwardWindow) probability += 0.04;

    return probability.clamp(0.20, 0.99);
  }

  String _qualityDetailText(double controlPct) {
    final isKo = Localizations.localeOf(context).languageCode == 'ko';
    if (isKo) {
      if (controlPct >= 88) return '패스 품질 최고';
      if (controlPct >= 72) return '패스 품질 좋음';
      if (controlPct >= 56) return '패스 품질 보통';
      return '패스 품질 낮음';
    }
    if (controlPct >= 88) return 'Pass quality: elite';
    if (controlPct >= 72) return 'Pass quality: good';
    if (controlPct >= 56) return 'Pass quality: fair';
    return 'Pass quality: low';
  }

  int _setReaction(
    _PassResult result, {
    double? controlProbability,
  }) {
    final timingGap = _timingDiffAtClosest.isFinite
        ? _timingDiffAtClosest.abs()
        : (_flightElapsed - _predReceiverTime).abs();
    final positionGap = _closestReceiverDistance.isFinite
        ? _closestReceiverDistance
        : _distance(_ballX, _ballY, _receiverX, _receiverY);
    final speedGapRatio = ((_effectiveBallSpeed - _idealBallSpeed).abs() /
            math.max(_idealBallSpeed, 0.001))
        .clamp(0.0, 1.5);

    final timingScore = (1 - (timingGap / 0.35)).clamp(0.0, 1.0);
    final positionScore = (1 - (positionGap / 0.14)).clamp(0.0, 1.0);
    final speedScore = (1 - (speedGapRatio / 0.9)).clamp(0.0, 1.0);
    final base =
        (timingScore * 0.55 + positionScore * 0.25 + speedScore * 0.20) * 100;
    _lastAccuracy = result == _PassResult.perfect ? base : 0;

    switch (result) {
      case _PassResult.perfect:
        final controlProb =
            (controlProbability ?? _lastControlProbability).clamp(0.20, 0.99);
        final controlPct = controlProb * 100;
        _lastAccuracy = controlPct;
        final tier = _accuracyTier(_lastAccuracy);
        _reactionIcon = tier.icon;
        _reactionColor = tier.color;
        _reactionLabel = _koText(
          '${tier.labelKo} 패스 성공',
          '${tier.labelEn} pass complete',
        );
        _reactionDetail = _qualityDetailText(controlPct);
        return 1;
      case _PassResult.intercepted:
        _reactionIcon = Icons.shield;
        _reactionColor = const Color(0xFFEB5757);
        _reactionLabel = _koText(
          '차단됨  공간을 더 바깥으로',
          'Intercepted  aim wider lane',
        );
        _reactionDetail = _koText(
          '수비수에게 먼저 닿아 성공 패스로 인정되지 않았어요.',
          'Defender touched first, so this was not counted as a successful pass.',
        );
        return 0;
      case _PassResult.saved:
        _reactionIcon = Icons.sports_handball;
        _reactionColor = const Color(0xFFFF7043);
        _reactionLabel = _koText(
          '골키퍼 선방!',
          'Keeper save!',
        );
        _reactionDetail = _koText(
          '골키퍼에게 막혔어요. 빈 공간을 보고 다시 시도하세요.',
          'Shot was saved by the keeper. Find more open space.',
        );
        return 0;
      case _PassResult.shotReady:
        _reactionIcon = Icons.ads_click;
        _reactionColor = const Color(0xFF2F80ED);
        _reactionLabel = _koText(
          '슈팅 찬스 오픈',
          'Shot chance open',
        );
        _reactionDetail = _koText(
          '골대 안쪽으로 길게 눌러 슈팅하세요.',
          'Hold and release to shoot into the goal.',
        );
        return 0;
      case _PassResult.goalUnlocked:
        _reactionIcon = Icons.flag_circle;
        _reactionColor = const Color(0xFF2F80ED);
        _reactionLabel = _koText(
          '골대가 나타났어요!',
          'Goal is now visible!',
        );
        _reactionDetail = _koText(
          '마지막 패스를 성공하면 슈팅 찬스로 넘어갑니다.',
          'Complete one final pass to enter shot chance.',
        );
        return 0;
      case _PassResult.goal:
        _reactionIcon = Icons.sports_score;
        _reactionColor = const Color(0xFF0FA968);
        _reactionLabel = _koText('GOAL!', 'GOAL!');
        _reactionDetail = _koText(
          '골 성공! 다시 패스를 이어가며 다음 찬스를 만드세요.',
          'Goal scored! Keep passing for the next chance.',
        );
        return 1;
      case _PassResult.nearMiss:
        _reactionIcon = Icons.local_fire_department;
        _reactionColor = const Color(0xFFFF8A3D);
        _reactionLabel = _koText(
          '아슬아슬 통과!',
          'Near miss!',
        );
        _reactionDetail = _koText(
          '수비 바로 옆을 스쳐 지나갔어요.',
          'Ball grazed past a defender.',
        );
        return 0;
      case _PassResult.tooFast:
        _reactionIcon = Icons.fast_forward;
        _reactionColor = const Color(0xFFF2994A);
        final speedCause = speedGapRatio >= 0.35;
        final leadCause =
            _forwardAlignment >= 0.25 && _leadAlongMove >= 0.10 && !speedCause;
        _reactionLabel = speedCause
            ? _koText(
                '빠름(속도)  누르는 시간을 줄이세요',
                'Too fast (speed)  hold shorter',
              )
            : leadCause
                ? _koText(
                    '빠름(리드)  목표를 조금 뒤로',
                    'Too fast (lead)  aim slightly back',
                  )
                : _koText(
                    '빠름  속도/방향을 함께 조절',
                    'Too fast  tune speed and aim',
                  );
        _reactionDetail = _koText(
          '공이 선수보다 일찍 도착해 안정적인 첫 터치가 어려웠어요.',
          'Ball arrived earlier than runner timing, reducing first-touch control.',
        );
        return 0;
      case _PassResult.tooSlow:
        _reactionIcon = Icons.slow_motion_video;
        _reactionColor = const Color(0xFF4D8BFF);
        _reactionLabel = _koText(
          '느림  더 길게 눌러 속도 증가',
          'Too slow  hold longer',
        );
        _reactionDetail = _koText(
          '공이 늦게 도착해 리시버 진행방향 타이밍을 놓쳤어요.',
          'Ball arrived late and missed the runner movement timing.',
        );
        return 0;
      case _PassResult.miss:
        _reactionIcon = Icons.my_location;
        _reactionColor = const Color(0xFF9B51E0);
        _reactionLabel = _koText(
          '빗나감  리드 거리 다시 조절',
          'Missed  retune lead distance',
        );
        _reactionDetail = _koText(
          '허용 범위 바깥으로 도착해 컨트롤 가능한 영역을 벗어났어요.',
          'Pass landed outside the controllable receiving window.',
        );
        return 0;
      case _PassResult.idleTimeout:
        _reactionIcon = Icons.timer_off;
        _reactionColor = const Color(0xFFEB5757);
        _reactionLabel = _koText(
          '3초 무패스 종료',
          'No pass for 3s',
        );
        _reactionDetail = _koText(
          '3초 안에 패스를 시도하지 않아 라운드가 종료됐어요.',
          'Round ended because no pass was attempted within 3 seconds.',
        );
        return 0;
    }
  }

  List<_DefenderState> _buildDefenders(
    _GameDifficulty difficulty, {
    int? count,
  }) {
    final defenderCount = count ?? difficulty.defenderCount;
    const spawnGap = 0.30;
    const laneCount = 5;
    return List<_DefenderState>.generate(defenderCount, (index) {
      final roster = _difficultyGhostRoster(difficulty);
      final ghostType = roster[index % roster.length];
      const minX = -0.20;
      final maxX = 1.24 + (index * spawnGap);
      const minY = 0.10;
      const maxY = 0.90;
      final speed = difficulty.defenderBaseSpeed +
          (_random.nextDouble() * difficulty.defenderRange);
      final laneIndex = index % laneCount;
      final laneCenter = minY + ((laneIndex + 0.5) / laneCount) * (maxY - minY);
      final spawnY = (laneCenter + ((_random.nextDouble() - 0.5) * 0.08))
          .clamp(minY, maxY);
      return _DefenderState(
        x: maxX + (_random.nextDouble() * 0.08),
        y: spawnY,
        speed: speed,
        vx: -1.0,
        vy: _random.nextBool() ? 1.0 : -1.0,
        minX: minX,
        maxX: maxX,
        minY: minY,
        maxY: maxY,
        turnChance: 0.08,
        turnRadians: 0.22,
        ghostType: ghostType,
      );
    });
  }

  double _furthestDefenderX({_DefenderState? except}) {
    var furthest = 1.0;
    for (final defender in _defenders) {
      if (identical(defender, except)) continue;
      if (defender.x > furthest) furthest = defender.x;
    }
    return furthest;
  }

  double _distance(double x1, double y1, double x2, double y2) {
    final dx = x1 - x2;
    final dy = y1 - y2;
    return math.sqrt(dx * dx + dy * dy);
  }

  Offset _lanePointAtX(double x) {
    final sx = _activePasserX;
    final sy = _activePasserY;
    final tx = _activeReceiverX;
    final ty = _activeReceiverY;
    final dx = tx - sx;
    if (dx.abs() < 1e-6) {
      return Offset(x, ((sy + ty) * 0.5).clamp(_fieldMinY, _fieldMaxY));
    }
    final t = ((x - sx) / dx).clamp(0.0, 1.0);
    final y = sy + ((ty - sy) * t);
    return Offset(x, y.clamp(_fieldMinY, _fieldMaxY));
  }

  double _roleTargetY(_DefenderState defender, double laneY) {
    switch (defender.ghostType) {
      case _GhostType.blue:
        return laneY;
      case _GhostType.orange:
        final pressY =
            _ballFlying ? _ballY : ((_activePasserY + _activeReceiverY) * 0.5);
        return pressY.clamp(defender.minY, defender.maxY);
      case _GhostType.red:
        final markerY = _activePasserY + (math.sin(_keeperPhase * 1.7) * 0.02);
        return markerY.clamp(defender.minY, defender.maxY);
      case _GhostType.pink:
        final predictY = (_activeReceiverY + (_activeReceiverVy * 0.33));
        return predictY.clamp(defender.minY, defender.maxY);
    }
  }

  double _turnAngle(double vx1, double vy1, double vx2, double vy2) {
    final a = math.sqrt(vx1 * vx1 + vy1 * vy1);
    final b = math.sqrt(vx2 * vx2 + vy2 * vy2);
    if (a <= 1e-6 || b <= 1e-6) return 0;
    final dot = ((vx1 * vx2) + (vy1 * vy2)) / (a * b);
    return math.acos(dot.clamp(-1.0, 1.0));
  }

  double get _activeReceiverSpeedAbs => math.max(
      0.001,
      math.sqrt(_activeReceiverVx * _activeReceiverVx +
              _activeReceiverVy * _activeReceiverVy) *
          (_attackerAIsPasser ? _receiverSpeedMul : _passerSpeedMul));

  _AccuracyTier _accuracyTier(double accuracy) {
    if (accuracy >= 90) return _AccuracyTier.perfect;
    if (accuracy >= 75) return _AccuracyTier.great;
    if (accuracy >= 60) return _AccuracyTier.good;
    if (accuracy >= 45) return _AccuracyTier.okay;
    return _AccuracyTier.low;
  }

  String _rankingLabel(int rankScore, bool isKo) {
    if (rankScore >= 320) return 'S';
    if (rankScore >= 240) return 'A';
    if (rankScore >= 170) return 'B';
    if (rankScore >= 110) return 'C';
    return isKo ? 'D' : 'D';
  }

  String _koText(String ko, String en) {
    final isKo = Localizations.localeOf(context).languageCode == 'ko';
    return isKo ? ko : en;
  }

  int _difficultyMaxDefenders(_GameDifficulty difficulty) {
    switch (difficulty) {
      case _GameDifficulty.easy:
        return 6;
      case _GameDifficulty.medium:
        return 9;
      case _GameDifficulty.hard:
        return 12;
    }
  }

  List<_GhostType> _difficultyGhostRoster(_GameDifficulty difficulty) {
    switch (difficulty) {
      case _GameDifficulty.easy:
        return const <_GhostType>[
          _GhostType.blue,
          _GhostType.orange,
        ];
      case _GameDifficulty.medium:
        return const <_GhostType>[
          _GhostType.blue,
          _GhostType.orange,
          _GhostType.red,
        ];
      case _GameDifficulty.hard:
        return const <_GhostType>[
          _GhostType.blue,
          _GhostType.orange,
          _GhostType.red,
          _GhostType.pink,
        ];
    }
  }

  void _loadSavedState() {
    final savedDifficulty =
        widget.optionRepository.getValue<String>(_difficultyKey);
    if (savedDifficulty != null) {
      _difficulty = _GameDifficulty.values.firstWhere(
        (e) => e.name == savedDifficulty,
        orElse: () => _GameDifficulty.medium,
      );
    }
    _weeklyBest =
        widget.optionRepository.getValue<int>('$_weeklyBestPrefix$_weekKey') ??
            0;
  }

  void _updateWeeklyBest() {
    if (_score <= _weeklyBest) return;
    _weeklyBest = _score;
    widget.optionRepository
        .setValue('$_weeklyBestPrefix$_weekKey', _weeklyBest);
  }

  String _currentWeekKey(DateTime date) {
    final thursday = date.add(Duration(days: 4 - date.weekday));
    final week = _isoWeekNumber(date);
    return '${thursday.year}-W$week';
  }

  int _isoWeekNumber(DateTime date) {
    final thursday = date.add(Duration(days: 4 - date.weekday));
    final firstThursday = DateTime(thursday.year, 1, 4);
    final diffDays = thursday.difference(firstThursday).inDays;
    return 1 + (diffDays ~/ 7);
  }

  Widget _entity(
    BuildContext context, {
    required double x,
    required double y,
    required double size,
    required Color color,
    required String label,
    required double width,
    required double height,
    bool emphasize = false,
    String roleTag = '',
  }) {
    final onSurface = Theme.of(context).colorScheme.onSurface;
    final isBall = label.isEmpty;
    final isAttacker = label.startsWith('Attacker') || label.startsWith('공격수');
    final isDefender = label.startsWith('Def ') || label.startsWith('수비');
    return Positioned(
      left: x * width - size / 2,
      top: y * height - size / 2,
      child: Column(
        children: [
          SizedBox(
            width: size,
            height: size,
            child: CustomPaint(
              painter: isBall
                  ? _BallEntityPainter(
                      color: color,
                      emphasize: emphasize,
                    )
                  : (isAttacker
                      ? _PacmanEntityPainter(
                          color: color,
                          emphasize: emphasize,
                        )
                      : (isDefender
                          ? _GhostEntityPainter(
                              color: color,
                              emphasize: emphasize,
                            )
                          : _BallEntityPainter(
                              color: color,
                              emphasize: emphasize,
                            ))),
            ),
          ),
          if (roleTag.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                decoration: BoxDecoration(
                  color: const Color(0xCC0F172A),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                    color: emphasize
                        ? const Color(0x99FFF59D)
                        : const Color(0x66FFFFFF),
                  ),
                ),
                child: Text(
                  roleTag,
                  style: const TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                    height: 1.0,
                  ),
                ),
              ),
            ),
          if (label.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 3),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                decoration: BoxDecoration(
                  color: const Color(0xCC111A27),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: onSurface,
                    height: 1.1,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  void _openSettings(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => SettingsScreen(
          localeService: widget.localeService,
          settingsService: widget.settingsService,
          optionRepository: widget.optionRepository,
          driveBackupService: widget.driveBackupService,
        ),
      ),
    );
  }

  Future<void> _openProfile(BuildContext context) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) =>
            ProfileScreen(optionRepository: widget.optionRepository),
      ),
    );
    if (mounted) setState(() {});
  }

  void _openGameGuide(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => const GameGuideScreen(),
      ),
    );
  }
}

class _PointerGauge extends StatelessWidget {
  final double ratio;
  final bool isKo;

  const _PointerGauge({
    required this.ratio,
    required this.isKo,
  });

  @override
  Widget build(BuildContext context) {
    final p = ratio.clamp(0.0, 1.0);
    final label = isKo
        ? '파워 ${(p * 100).toStringAsFixed(0)}%'
        : 'Power ${(p * 100).toStringAsFixed(0)}%';
    return Container(
      width: 60,
      padding: const EdgeInsets.fromLTRB(8, 6, 8, 6),
      decoration: BoxDecoration(
        color: const Color(0xD0111A27),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFF4DD0E1)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 9,
              fontWeight: FontWeight.w700,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: p,
              minHeight: 6,
              backgroundColor: Colors.white24,
              valueColor:
                  const AlwaysStoppedAnimation<Color>(Color(0xFF4DD0E1)),
            ),
          ),
        ],
      ),
    );
  }
}

class _ForwardPassInfo {
  final bool inWindow;
  final double alignment;
  final double leadAlongMove;

  const _ForwardPassInfo({
    required this.inWindow,
    required this.alignment,
    required this.leadAlongMove,
  });
}

class _ShotWindowHint {
  final String label;
  final String detail;
  final Color color;

  const _ShotWindowHint({
    required this.label,
    required this.detail,
    required this.color,
  });
}

class _ReceivingWindowEval {
  final bool inside;
  final double fit;

  const _ReceivingWindowEval({
    required this.inside,
    required this.fit,
  });
}

class _MovingPitchPainter extends CustomPainter {
  final double scroll;

  const _MovingPitchPainter({
    required this.scroll,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final base = Paint()..color = const Color(0xFF123F2A);
    canvas.drawRect(Offset.zero & size, base);

    final stripeW = size.width / 7;
    final shift = (scroll * stripeW * 2);
    for (var i = -1; i <= 8; i++) {
      final x = (i * stripeW * 2) - shift;
      final rect = Rect.fromLTWH(x, 0, stripeW, size.height);
      canvas.drawRect(rect, Paint()..color = const Color(0xFF175334));
    }

    final linePaint = Paint()
      ..color = Colors.white.withAlpha(120)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;
    final topTouchY = size.height * 0.20;
    final bottomTouchY = size.height * 0.80;
    canvas.drawLine(
        Offset(0, topTouchY), Offset(size.width, topTouchY), linePaint);
    canvas.drawLine(
        Offset(0, bottomTouchY), Offset(size.width, bottomTouchY), linePaint);
  }

  @override
  bool shouldRepaint(covariant _MovingPitchPainter oldDelegate) {
    return oldDelegate.scroll != scroll;
  }
}

class _GoalPainter extends CustomPainter {
  final double goalLineX;
  final double goalTopY;
  final double goalBottomY;

  const _GoalPainter({
    required this.goalLineX,
    required this.goalTopY,
    required this.goalBottomY,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final left = goalLineX * size.width;
    final top = goalTopY * size.height;
    final bottom = goalBottomY * size.height;
    final depth = (size.width * 0.06).clamp(24.0, 54.0);
    final post = Paint()
      ..color = Colors.white.withAlpha(240)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.2;
    final net = Paint()
      ..color = Colors.white.withAlpha(80)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;
    final shadow = Paint()
      ..color = const Color(0x55000000)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4.4;

    final frontRect = Rect.fromLTRB(left, top, left + depth, bottom);
    canvas.drawLine(
      Offset(frontRect.left + 1.0, top + 1.5),
      Offset(frontRect.left + 1.0, bottom + 1.5),
      shadow,
    );
    canvas.drawRect(frontRect, post);

    const rows = 6;
    const cols = 5;
    for (var r = 1; r < rows; r++) {
      final y = top + ((bottom - top) * (r / rows));
      canvas.drawLine(Offset(left, y), Offset(left + depth, y), net);
    }
    for (var c = 1; c < cols; c++) {
      final x = left + (depth * (c / cols));
      canvas.drawLine(Offset(x, top), Offset(x, bottom), net);
    }
  }

  @override
  bool shouldRepaint(covariant _GoalPainter oldDelegate) {
    return oldDelegate.goalLineX != goalLineX ||
        oldDelegate.goalTopY != goalTopY ||
        oldDelegate.goalBottomY != goalBottomY;
  }
}

class _BallEntityPainter extends CustomPainter {
  final Color color;
  final bool emphasize;

  const _BallEntityPainter({
    required this.color,
    required this.emphasize,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final radius = size.shortestSide / 2;
    final center = Offset(size.width / 2, size.height / 2);
    final fill = Paint()..color = color;
    final border = Paint()
      ..color = emphasize ? const Color(0xFFFFF59D) : const Color(0xE6FFFFFF)
      ..style = PaintingStyle.stroke
      ..strokeWidth = emphasize ? 2.2 : 1.0;
    canvas.drawCircle(center, radius, fill);
    canvas.drawCircle(center, radius - 0.6, border);
  }

  @override
  bool shouldRepaint(covariant _BallEntityPainter oldDelegate) {
    return oldDelegate.color != color || oldDelegate.emphasize != emphasize;
  }
}

class _PacmanEntityPainter extends CustomPainter {
  final Color color;
  final bool emphasize;

  const _PacmanEntityPainter({
    required this.color,
    required this.emphasize,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final radius = size.shortestSide / 2;
    final center = Offset(size.width / 2, size.height / 2);
    const mouth = 0.78; // radians
    final fill = Paint()..color = color;
    final border = Paint()
      ..color = emphasize ? const Color(0xFFFFF59D) : const Color(0xE6FFFFFF)
      ..style = PaintingStyle.stroke
      ..strokeWidth = emphasize ? 2.2 : 1.0;

    final path = Path()
      ..moveTo(center.dx, center.dy)
      ..arcTo(
        Rect.fromCircle(center: center, radius: radius),
        mouth / 2,
        (math.pi * 2) - mouth,
        false,
      )
      ..close();
    canvas.drawPath(path, fill);
    canvas.drawPath(path, border);

    final eyePaint = Paint()..color = const Color(0xCC0F172A);
    canvas.drawCircle(
      Offset(center.dx + (radius * 0.16), center.dy - (radius * 0.35)),
      radius * 0.12,
      eyePaint,
    );
  }

  @override
  bool shouldRepaint(covariant _PacmanEntityPainter oldDelegate) {
    return oldDelegate.color != color || oldDelegate.emphasize != emphasize;
  }
}

class _GhostEntityPainter extends CustomPainter {
  final Color color;
  final bool emphasize;

  const _GhostEntityPainter({
    required this.color,
    required this.emphasize,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final path = Path()
      ..moveTo(w * 0.2, h * 0.92)
      ..quadraticBezierTo(w * 0.25, h * 0.80, w * 0.30, h * 0.92)
      ..quadraticBezierTo(w * 0.38, h * 0.80, w * 0.46, h * 0.92)
      ..quadraticBezierTo(w * 0.54, h * 0.80, w * 0.62, h * 0.92)
      ..quadraticBezierTo(w * 0.70, h * 0.80, w * 0.78, h * 0.92)
      ..lineTo(w * 0.80, h * 0.38)
      ..arcToPoint(
        Offset(w * 0.20, h * 0.38),
        radius: Radius.elliptical(w * 0.30, h * 0.30),
        clockwise: false,
      )
      ..close();

    final fill = Paint()..color = color;
    final border = Paint()
      ..color = emphasize ? const Color(0xFFFFF59D) : const Color(0xE6FFFFFF)
      ..style = PaintingStyle.stroke
      ..strokeWidth = emphasize ? 2.2 : 1.0;
    canvas.drawPath(path, fill);
    canvas.drawPath(path, border);

    final eyeWhite = Paint()..color = Colors.white.withAlpha(235);
    final pupil = Paint()..color = const Color(0xFF0F172A);
    canvas.drawOval(
      Rect.fromCenter(
          center: Offset(w * 0.40, h * 0.50),
          width: w * 0.15,
          height: h * 0.21),
      eyeWhite,
    );
    canvas.drawOval(
      Rect.fromCenter(
          center: Offset(w * 0.60, h * 0.50),
          width: w * 0.15,
          height: h * 0.21),
      eyeWhite,
    );
    canvas.drawCircle(Offset(w * 0.43, h * 0.52), w * 0.035, pupil);
    canvas.drawCircle(Offset(w * 0.63, h * 0.52), w * 0.035, pupil);
  }

  @override
  bool shouldRepaint(covariant _GhostEntityPainter oldDelegate) {
    return oldDelegate.color != color || oldDelegate.emphasize != emphasize;
  }
}

class _ReceiverLanePainter extends CustomPainter {
  final double receiverX;
  final double receiverY;
  final double vx;
  final double vy;

  const _ReceiverLanePainter({
    required this.receiverX,
    required this.receiverY,
    required this.vx,
    required this.vy,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final speed = math.sqrt(vx * vx + vy * vy);
    if (speed <= 1e-6) return;
    final dirX = vx / speed;
    final dirY = vy / speed;
    final origin = Offset(receiverX * size.width, receiverY * size.height);
    final angle = math.atan2(dirY, dirX);
    final minSize = math.min(size.width, size.height);
    final forwardPx = minSize * 0.15;
    final backPx = minSize * 0.08;
    final halfWidthPx = minSize * 0.085;

    final rect = Rect.fromLTWH(
      -backPx,
      -halfWidthPx,
      forwardPx + backPx,
      halfWidthPx * 2,
    );
    final zone = RRect.fromRectAndRadius(
      rect,
      Radius.circular(halfWidthPx),
    );

    final fill = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.centerLeft,
        end: Alignment.centerRight,
        colors: [Color(0x224DD0E1), Color(0x5556F0FF)],
      ).createShader(rect);
    final stroke = Paint()
      ..color = const Color(0x884DD0E1)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    final centerLine = Paint()
      ..color = const Color(0xAAE6FAFF)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;

    canvas.save();
    canvas.translate(origin.dx, origin.dy);
    canvas.rotate(angle);
    canvas.drawRRect(zone, fill);
    canvas.drawRRect(zone, stroke);
    canvas.drawLine(
        Offset(-backPx + 3, 0), Offset(forwardPx - 3, 0), centerLine);
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _ReceiverLanePainter oldDelegate) {
    return oldDelegate.receiverX != receiverX ||
        oldDelegate.receiverY != receiverY ||
        oldDelegate.vx != vx ||
        oldDelegate.vy != vy;
  }
}

class _GuidePainter extends CustomPainter {
  final double fromX;
  final double fromY;
  final double toX;
  final double toY;
  final Color color;

  const _GuidePainter({
    required this.fromX,
    required this.fromY,
    required this.toX,
    required this.toY,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    final start = Offset(fromX * size.width, fromY * size.height);
    final end = Offset(toX * size.width, toY * size.height);

    const dash = 7.0;
    const gap = 5.0;
    final total = (end - start).distance;
    if (total <= 0.0001) return;

    final dir = (end - start) / total;
    var drawn = 0.0;
    while (drawn < total) {
      final segStart = start + dir * drawn;
      final segEnd = start + dir * math.min(drawn + dash, total);
      canvas.drawLine(segStart, segEnd, paint);
      drawn += dash + gap;
    }
  }

  @override
  bool shouldRepaint(covariant _GuidePainter oldDelegate) {
    return oldDelegate.fromX != fromX ||
        oldDelegate.fromY != fromY ||
        oldDelegate.toX != toX ||
        oldDelegate.toY != toY;
  }
}

class _PassPrediction {
  final double targetX;
  final double targetY;
  final double ballTime;
  final double receiverTime;
  final double idealBallSpeed;

  const _PassPrediction({
    required this.targetX,
    required this.targetY,
    required this.ballTime,
    required this.receiverTime,
    required this.idealBallSpeed,
  });
}

enum _PlayPhase {
  ready,
  flying,
  roundEnd,
}

enum _PassResult {
  perfect,
  intercepted,
  saved,
  shotReady,
  goalUnlocked,
  goal,
  nearMiss,
  tooFast,
  tooSlow,
  miss,
  idleTimeout,
}

enum _AccuracyTier {
  perfect,
  great,
  good,
  okay,
  low,
}

extension _AccuracyTierSpec on _AccuracyTier {
  Color get color {
    switch (this) {
      case _AccuracyTier.perfect:
        return const Color(0xFF0FA968);
      case _AccuracyTier.great:
        return const Color(0xFF2F80ED);
      case _AccuracyTier.good:
        return const Color(0xFFF2994A);
      case _AccuracyTier.okay:
        return const Color(0xFF9B51E0);
      case _AccuracyTier.low:
        return const Color(0xFF6B7280);
    }
  }

  IconData get icon {
    switch (this) {
      case _AccuracyTier.perfect:
        return Icons.workspace_premium;
      case _AccuracyTier.great:
        return Icons.verified;
      case _AccuracyTier.good:
        return Icons.thumb_up_alt;
      case _AccuracyTier.okay:
        return Icons.check_circle_outline;
      case _AccuracyTier.low:
        return Icons.radio_button_unchecked;
    }
  }

  String get labelKo {
    switch (this) {
      case _AccuracyTier.perfect:
        return '퍼펙트';
      case _AccuracyTier.great:
        return '그레이트';
      case _AccuracyTier.good:
        return '굿';
      case _AccuracyTier.okay:
        return '오케이';
      case _AccuracyTier.low:
        return '낮음';
    }
  }

  String get labelEn {
    switch (this) {
      case _AccuracyTier.perfect:
        return 'PERFECT';
      case _AccuracyTier.great:
        return 'GREAT';
      case _AccuracyTier.good:
        return 'GOOD';
      case _AccuracyTier.okay:
        return 'OKAY';
      case _AccuracyTier.low:
        return 'LOW';
    }
  }
}

enum _GameDifficulty {
  easy,
  medium,
  hard,
}

enum _GhostType {
  blue,
  orange,
  red,
  pink,
}

extension _GhostTypeSpec on _GhostType {
  Color get color {
    switch (this) {
      case _GhostType.blue:
        return const Color(0xFF42A5F5);
      case _GhostType.orange:
        return const Color(0xFFFFA726);
      case _GhostType.red:
        return const Color(0xFFEF5350);
      case _GhostType.pink:
        return const Color(0xFFEC70C0);
    }
  }

  double get speedFactor {
    switch (this) {
      case _GhostType.blue:
        return 0.95;
      case _GhostType.orange:
        return 1.18;
      case _GhostType.red:
        return 1.08;
      case _GhostType.pink:
        return 1.00;
    }
  }

  double get lanePull {
    switch (this) {
      case _GhostType.blue:
        return 2.0;
      case _GhostType.orange:
        return 1.1;
      case _GhostType.red:
        return 1.3;
      case _GhostType.pink:
        return 1.4;
    }
  }

  double get rolePull {
    switch (this) {
      case _GhostType.blue:
        return 1.2;
      case _GhostType.orange:
        return 2.2;
      case _GhostType.red:
        return 2.0;
      case _GhostType.pink:
        return 2.4;
    }
  }

  double get wobbleFactor {
    switch (this) {
      case _GhostType.blue:
        return 0.34;
      case _GhostType.orange:
        return 0.52;
      case _GhostType.red:
        return 0.40;
      case _GhostType.pink:
        return 0.46;
    }
  }

  double get turnFactor {
    switch (this) {
      case _GhostType.blue:
        return 1.3;
      case _GhostType.orange:
        return 1.9;
      case _GhostType.red:
        return 1.6;
      case _GhostType.pink:
        return 2.0;
    }
  }

  double get interceptRadius {
    switch (this) {
      case _GhostType.blue:
        return 0.043;
      case _GhostType.orange:
        return 0.034;
      case _GhostType.red:
        return 0.046;
      case _GhostType.pink:
        return 0.040;
    }
  }

  String get labelKo {
    switch (this) {
      case _GhostType.blue:
        return '수비(차단)';
      case _GhostType.orange:
        return '수비(압박)';
      case _GhostType.red:
        return '수비(마크)';
      case _GhostType.pink:
        return '수비(예측)';
    }
  }

  String get labelEn {
    switch (this) {
      case _GhostType.blue:
        return 'Blocker';
      case _GhostType.orange:
        return 'Presser';
      case _GhostType.red:
        return 'Marker';
      case _GhostType.pink:
        return 'Anticipator';
    }
  }

  String get roleTag {
    switch (this) {
      case _GhostType.blue:
        return 'BLOCK';
      case _GhostType.orange:
        return 'PRESS';
      case _GhostType.red:
        return 'MARK';
      case _GhostType.pink:
        return 'READ';
    }
  }
}

extension _GameDifficultySpec on _GameDifficulty {
  int get defenderCount {
    switch (this) {
      case _GameDifficulty.easy:
        return 3;
      case _GameDifficulty.medium:
        return 5;
      case _GameDifficulty.hard:
        return 7;
    }
  }

  double get receiverBaseSpeed {
    switch (this) {
      case _GameDifficulty.easy:
        return 0.13;
      case _GameDifficulty.medium:
        return 0.16;
      case _GameDifficulty.hard:
        return 0.19;
    }
  }

  double get receiverRange {
    switch (this) {
      case _GameDifficulty.easy:
        return 0.03;
      case _GameDifficulty.medium:
        return 0.05;
      case _GameDifficulty.hard:
        return 0.07;
    }
  }

  double get defenderBaseSpeed {
    switch (this) {
      case _GameDifficulty.easy:
        return 0.13;
      case _GameDifficulty.medium:
        return 0.17;
      case _GameDifficulty.hard:
        return 0.21;
    }
  }

  double get defenderRange {
    switch (this) {
      case _GameDifficulty.easy:
        return 0.04;
      case _GameDifficulty.medium:
        return 0.06;
      case _GameDifficulty.hard:
        return 0.09;
    }
  }
}

class _DefenderState {
  final double speed;
  final double minX;
  final double maxX;
  final double minY;
  final double maxY;
  final double turnChance;
  final double turnRadians;
  final _GhostType ghostType;
  double x;
  double y;
  double vx;
  double vy;

  _DefenderState({
    required this.x,
    required this.y,
    required this.speed,
    required this.vx,
    required this.vy,
    required this.minX,
    required this.maxX,
    required this.minY,
    required this.maxY,
    required this.turnChance,
    required this.turnRadians,
    required this.ghostType,
  });
}
