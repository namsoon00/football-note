import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;
import 'dart:io' show Platform;

import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/services.dart';

import '../../application/backup_service.dart';
import '../../application/locale_service.dart';
import '../../application/settings_service.dart';
import '../../application/training_service.dart';
import '../../domain/repositories/option_repository.dart';
import '../widgets/app_background.dart';
import 'game_guide_screen.dart';
import 'game_ranking_screen.dart';
import 'skill_quiz_screen.dart';

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
  static const _rankingHistoryKey = 'space_speed_ranking_history_v1';
  static const _quizCompletedAtKey = SkillQuizScreen.completionKey;
  static const _gamePlayedCountKey = 'space_speed_played_count_v1';
  static const _playsPerTrainingNote = 5;

  static const _dt = 0.05;
  static const _passerX = 0.10;
  static const _passerY = 0.72;
  static const _ballMinSpeed = 0.35;
  static const _ballMaxSpeed = 1.25;
  static const _fieldMinX = 0.04;
  static const _fieldMaxX = 0.98;
  static const _fieldMinY = 0.04;
  static const _fieldMaxY = 0.96;
  static const _goalLineX = 0.88;
  static const _goalTopY = 0.30;
  static const _goalBottomY = 0.70;
  static const _joystickAccelX = 0.11;
  static const _joystickAccelY = 0.12;
  static const _playerJoystickMaxVx = 0.76;
  static const _playerJoystickMaxVy = 0.64;
  static const _maxRankingEntries = 10;

  final _random = math.Random();
  Timer? _timer;
  Timer? _gameTimer;
  Timer? _failEndTimer;

  int _score = 0;
  int _goals = 0;
  int _combo = 0;
  int _bonusScore = 0;
  int _lives = 3;
  int _weeklyBest = 0;
  int _level = 1;
  bool _gameStarted = false;
  int _remainingSeconds = 20;
  bool _timeUp = false;
  int _trainingNoteCount = 0;
  int _playedGameCount = 0;
  bool _quizCompleted = false;
  bool _endedByFail = false;
  int _maxComboInRun = 0;
  _PassResult? _lastFailedReason;
  DateTime _lastInteractionAt = DateTime.now();
  bool _finalShotMode = false;
  String _finalRanking = '';
  late String _weekKey;

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
  _ShotOutcome _lastShotOutcome = _ShotOutcome.none;
  Timer? _shotOutcomeTimer;
  bool _awaitingShotOutcome = false;
  bool _awaitingFailFinish = false;

  bool _charging = false;
  DateTime? _chargeStartedAt;
  double _chargedBallSpeed = _ballMinSpeed;

  bool _ballFlying = false;
  bool _ballSettling = false;
  double _ballX = _passerX;
  double _ballY = _passerY;
  double _ballVx = 0;
  double _ballVy = 0;
  double _flightElapsed = 0;
  double _settleControlProbability = 0;

  double _targetX = 0.60;
  double _targetY = 0.36;
  double _aimX = 0.60;
  double _aimY = 0.36;
  bool _flightGuideLocked = false;
  double _flightGuideFromX = 0.60;
  double _flightGuideToX = 0.60;
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
  _PassRiskType _currentPassRisk = _PassRiskType.safe;
  _GameEvent _activeEvent = _GameEvent.none;
  _DefenderPattern _defenderPattern = _DefenderPattern.laneClosing;
  int _eventSecondsRemaining = 0;
  int _patternSecondsRemaining = 0;
  int _feverSecondsRemaining = 0;
  DateTime? _lastSuccessAt;
  int _rhythmStreak = 0;
  _MissionState _mission = const _MissionState(
    type: _MissionType.safePasses,
    target: 4,
    progress: 0,
  );
  double _plannedPassOpenSpace = 0;
  List<GameRankingEntry> _rankingHistory = const [];
  _PassRiskType? _lastSuccessfulPassRisk;
  int _samePassRiskStreak = 0;
  Offset _joystickInput = Offset.zero;
  bool _joystickActive = false;
  int? _joystickPointerId;
  bool _passPressed = false;
  Offset _passAimInput = Offset.zero;
  bool _passAimActive = false;
  int? _passPointerId;
  bool _passChargeArmed = false;
  final GlobalKey _passPadKey = GlobalKey();

  int get _rankScore =>
      (_score * 10) + (_level * 15) + (_goals * 60) + _bonusScore;
  double get _attackerPaceScale =>
      (0.82 + ((_level - 1) * 0.040)).clamp(0.82, 1.35);
  double get _defenderPaceScale =>
      (0.34 + ((_level - 1) * 0.032)).clamp(0.34, 1.18);
  _GameDifficulty get _difficulty {
    if (!_gameStarted) return _GameDifficulty.easy;
    final timeTier = switch (_remainingSeconds) {
      > 13 => 0,
      > 6 => 1,
      _ => 2,
    };
    final levelTier = switch (_level) {
      >= 9 => 2,
      >= 5 => 1,
      _ => 0,
    };
    return _GameDifficulty.values[math.max(timeTier, levelTier)];
  }

  double get _pitchZoom {
    if (_finalShotMode) return 1.12;
    if (_goalChanceActive) return 1.08;
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
  bool get _isControllingPasser => !(_ballFlying && !_goalChanceActive);
  bool get _isPasserControllable =>
      _isControllingPasser ? _attackerAIsPasser : !_attackerAIsPasser;
  bool get _isReceiverControllable =>
      _isControllingPasser ? !_attackerAIsPasser : _attackerAIsPasser;
  double get _passAimStrength => _passAimInput.distance.clamp(0.0, 1.0);
  double get _passLengthScale =>
      (0.70 + (_passAimStrength * 1.10)).clamp(0.70, 1.90);
  bool get _freezeShotScene =>
      (_goalChanceActive && _ballFlying) || _awaitingShotOutcome;
  bool get _showIdleHint =>
      _gameStarted &&
      !_timeUp &&
      !_awaitingShotOutcome &&
      !_awaitingFailFinish &&
      !_ballFlying &&
      DateTime.now().difference(_lastInteractionAt).inMilliseconds >= 3000;

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

  double get _eventReceiveWindowScale {
    switch (_activeEvent) {
      case _GameEvent.narrowLanes:
        return 0.82;
      case _GameEvent.wideLanes:
        return 1.18;
      case _GameEvent.tailWind:
      case _GameEvent.none:
        return 1.0;
    }
  }

  double get _eventBallSpeedScale {
    switch (_activeEvent) {
      case _GameEvent.tailWind:
        return 1.12;
      case _GameEvent.narrowLanes:
      case _GameEvent.wideLanes:
      case _GameEvent.none:
        return 1.0;
    }
  }

  _RoundArcStage get _roundArcStage {
    if (!_gameStarted) return _RoundArcStage.read;
    if (_remainingSeconds > 17) return _RoundArcStage.read;
    if (_remainingSeconds > 10) return _RoundArcStage.rhythm;
    return _RoundArcStage.chance;
  }

  bool get _openUpperSide => _openUpperSpaceScore >= _openLowerSpaceScore;

  double get _openUpperSpaceScore => _spaceScoreForBand(0.18, 0.42);

  double get _openLowerSpaceScore => _spaceScoreForBand(0.58, 0.82);

  _DefenderState? get _nearestPressureDefender {
    if (_defenders.isEmpty) return null;
    _DefenderState? nearest;
    var nearestDist = double.infinity;
    for (final defender in _defenders) {
      final d = _distance(
        _activePasserX,
        _activePasserY,
        defender.x,
        defender.y,
      );
      if (d < nearestDist) {
        nearestDist = d;
        nearest = defender;
      }
    }
    return nearest;
  }

  double get _feverScoreScale => _feverSecondsRemaining > 0 ? 2.0 : 1.0;

  String _passRiskLabel(bool isKo, _PassRiskType type) {
    switch (type) {
      case _PassRiskType.safe:
        return isKo ? '안전 패스' : 'Safe pass';
      case _PassRiskType.killer:
        return isKo ? '킬 패스' : 'Killer pass';
      case _PassRiskType.risky:
        return isKo ? '위험 패스' : 'Risky pass';
    }
  }

  String _eventLabel(bool isKo, _GameEvent event) {
    switch (event) {
      case _GameEvent.none:
        return isKo ? '이벤트 없음' : 'No event';
      case _GameEvent.narrowLanes:
        return isKo ? '좁은 라인' : 'Narrow lanes';
      case _GameEvent.wideLanes:
        return isKo ? '넓은 라인' : 'Wide lanes';
      case _GameEvent.tailWind:
        return isKo ? '순풍' : 'Tail wind';
    }
  }

  String _patternLabel(bool isKo, _DefenderPattern pattern) {
    switch (pattern) {
      case _DefenderPattern.laneClosing:
        return isKo ? '라인 닫기' : 'Lane closing';
      case _DefenderPattern.receiverTracking:
        return isKo ? '리시버 추적' : 'Receiver tracking';
      case _DefenderPattern.counterPress:
        return isKo ? '역압박' : 'Counter-press';
    }
  }

  String _missionLabel(bool isKo, _MissionState mission) {
    switch (mission.type) {
      case _MissionType.safePasses:
        return isKo ? '안전 패스' : 'Safe passes';
      case _MissionType.killerPasses:
        return isKo ? '킬 패스' : 'Killer passes';
      case _MissionType.riskyPasses:
        return isKo ? '위험 패스' : 'Risky passes';
      case _MissionType.combo:
        return isKo ? '콤보 달성' : 'Combo';
      case _MissionType.goals:
        return isKo ? '골 넣기' : 'Goals';
    }
  }

  String _roundArcLabel(bool isKo) {
    switch (_roundArcStage) {
      case _RoundArcStage.read:
        return isKo ? '오프닝 리드' : 'Opening read';
      case _RoundArcStage.rhythm:
        return isKo ? '리듬 축적' : 'Build rhythm';
      case _RoundArcStage.chance:
        return isKo ? '찬스 폭발' : 'Chance push';
    }
  }

  String _openSideLabel(bool isKo) {
    if (_openUpperSide) {
      return isKo ? '상단 공간 열림' : 'Upper side open';
    }
    return isKo ? '하단 공간 열림' : 'Lower side open';
  }

  String _recommendedMissionText(bool isKo) {
    final missionLine = _missionLabel(isKo, _mission);
    return isKo
        ? '오늘의 추천 미션: $missionLine ${_mission.target}회'
        : 'Recommended mission: $missionLine x${_mission.target}';
  }

  double _predictKeeperY(double time) {
    const center = (_goalTopY + _goalBottomY) * 0.5;
    const amp = (_goalBottomY - _goalTopY) * 0.36;
    final nextPhase = _keeperPhase + (time * 2.6);
    return (center + (math.sin(nextPhase) * amp)).clamp(
      _goalTopY + 0.05,
      _goalBottomY - 0.05,
    );
  }

  @override
  void initState() {
    super.initState();
    _weekKey = _currentWeekKey(DateTime.now());
    _loadSavedState();
    _resetRound(keepScore: true);
    _startLoop();
    unawaited(_refreshPlayGateState());
  }

  @override
  void dispose() {
    _timer?.cancel();
    _gameTimer?.cancel();
    _failEndTimer?.cancel();
    _shotOutcomeTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isKo = Localizations.localeOf(context).languageCode == 'ko';
    final shotHint = _shotWindowHint(isKo);
    final showPassGuide = _passPressed;
    final guideFromX = _activePasserX;
    final guideFromY = _activePasserY;
    final guideToX = _aimX;
    final guideToY = _aimY;

    return Scaffold(
      appBar: AppBar(
        title: Text(isKo ? '게임' : 'Game'),
        actions: [
          _buildHeaderIconButton(
            context,
            icon: Icons.menu_book_outlined,
            label: isKo ? '가이드' : 'Guide',
            onPressed: () => _openGameGuide(context),
          ),
          _buildHeaderIconButton(
            context,
            icon: Icons.quiz_outlined,
            label: isKo ? '퀴즈' : 'Quiz',
            onPressed: () => _openSkillQuiz(context),
          ),
          _buildHeaderIconButton(
            context,
            icon: Icons.emoji_events_outlined,
            label: isKo ? '랭킹' : 'Ranking',
            onPressed: () => _openRankingScreen(context),
          ),
          const SizedBox(width: 6),
        ],
      ),
      body: AppBackground(
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _buildStatChip(
                        context,
                        label: isKo ? '성공 패스' : 'Passes',
                        value: '$_score',
                        icon: Icons.sync_alt_rounded,
                      ),
                      const SizedBox(width: 8),
                      _buildStatChip(
                        context,
                        label: isKo ? '남은 시간' : 'Time',
                        value: isKo
                            ? '$_remainingSeconds초'
                            : '${_remainingSeconds}s',
                        icon: Icons.timer_outlined,
                      ),
                      const SizedBox(width: 8),
                      _buildStatChip(
                        context,
                        label: isKo ? '레벨' : 'Level',
                        value: 'Lv.$_level',
                        icon: Icons.trending_up_rounded,
                      ),
                      const SizedBox(width: 8),
                      _buildStatChip(
                        context,
                        label: isKo ? '생명' : 'Lives',
                        value: '$_lives',
                        icon: Icons.favorite_border,
                      ),
                      if (_bonusScore > 0) ...[
                        const SizedBox(width: 8),
                        _buildStatChip(
                          context,
                          label: isKo ? '보너스' : 'Bonus',
                          value: '+$_bonusScore',
                          icon: Icons.auto_awesome,
                        ),
                      ],
                    ],
                  ),
                ),
                if (_isAndroidGateEnabled) ...[
                  const SizedBox(height: 8),
                  Text(
                    isKo
                        ? '훈련노트 $_trainingNoteCount개 · 사용 $_playedGameCount판 · 남은 $_remainingGameCount판'
                        : 'Notes $_trainingNoteCount · Used $_playedGameCount · Left $_remainingGameCount',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                ],
                const SizedBox(height: 8),
                Expanded(
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final width = constraints.maxWidth;
                      final height = constraints.maxHeight;
                      return AnimatedScale(
                        scale: _pitchZoom,
                        duration: const Duration(milliseconds: 260),
                        curve: Curves.easeOutCubic,
                        child: Container(
                          decoration: BoxDecoration(
                            color: const Color(0xFF132B3E),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: const Color(0xFF4DD0E1).withAlpha(180),
                            ),
                          ),
                          child: Stack(
                            children: [
                              Positioned.fill(
                                child: CustomPaint(
                                  painter: _SpaceCuePainter(
                                    highlightUpperSide: _openUpperSide,
                                    pressureDefender:
                                        _nearestPressureDefender == null
                                            ? null
                                            : Offset(
                                                _nearestPressureDefender!.x,
                                                _nearestPressureDefender!.y,
                                              ),
                                  ),
                                ),
                              ),
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
                              if (_goalChanceActive || _finalShotMode)
                                const Positioned.fill(
                                  child: CustomPaint(
                                    painter: _GoalPainter(
                                      goalLineX: _goalLineX,
                                      goalTopY: _goalTopY,
                                      goalBottomY: _goalBottomY,
                                    ),
                                  ),
                                ),
                              if (showPassGuide)
                                Positioned.fill(
                                  child: CustomPaint(
                                    painter: _GuidePainter(
                                      fromX: guideFromX,
                                      fromY: guideFromY,
                                      toX: guideToX,
                                      toY: guideToY,
                                      color: const Color(0xB34DD0E1),
                                    ),
                                  ),
                                ),
                              if (showPassGuide)
                                Positioned(
                                  left: guideToX * width - 10,
                                  top: guideToY * height - 10,
                                  child: Container(
                                    width: 20,
                                    height: 20,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: const Color(0xFFFFE082),
                                        width: 2,
                                      ),
                                      color: const Color(0x55FFE082),
                                    ),
                                  ),
                                ),
                              _entity(
                                context,
                                x: _passerXPos,
                                y: _passerYPos,
                                size: 29,
                                color: const Color(0xFFFFD54F),
                                kind: _EntityKind.attacker,
                                label: '',
                                width: width,
                                height: height,
                                emphasize: _attackerAIsPasser,
                                markBallOwner:
                                    !_ballFlying && _attackerAIsPasser,
                                markControllable: _isPasserControllable,
                              ),
                              _entity(
                                context,
                                x: _receiverX,
                                y: _receiverY,
                                size: 29,
                                color: const Color(0xFFFFC107),
                                kind: _EntityKind.attacker,
                                label: '',
                                width: width,
                                height: height,
                                emphasize: !_attackerAIsPasser,
                                markBallOwner:
                                    !_ballFlying && !_attackerAIsPasser,
                                markControllable: _isReceiverControllable,
                              ),
                              if (_reactionLabel.isNotEmpty)
                                Positioned(
                                  top: 68,
                                  left: 10,
                                  right: 10,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 8,
                                    ),
                                    decoration: BoxDecoration(
                                      color: _reactionColor.withValues(
                                        alpha: 0.58,
                                      ),
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
                                                    fontWeight: FontWeight.w600,
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
                              Positioned(
                                top: 10,
                                left: 10,
                                child: _PitchInfoBadge(
                                  title:
                                      '${isKo ? '미션' : 'Mission'} ${_mission.progress}/${_mission.target}',
                                  body: _missionLabel(isKo, _mission),
                                  icon: Icons.flag_outlined,
                                ),
                              ),
                              Positioned(
                                top: 10,
                                right: 10,
                                child: ConstrainedBox(
                                  constraints: const BoxConstraints(
                                    maxWidth: 196,
                                  ),
                                  child: _PitchInfoBadge(
                                    title:
                                        '${_roundArcLabel(isKo)} · ${_passRiskLabel(isKo, _currentPassRisk)}',
                                    body:
                                        '${_eventLabel(isKo, _activeEvent)}${_eventSecondsRemaining > 0 ? ' ${_eventSecondsRemaining}s' : ''}${_feverSecondsRemaining > 0 ? ' · ${isKo ? '피버' : 'Fever'} ${_feverSecondsRemaining}s' : ''}\n${_openSideLabel(isKo)} · ${_patternLabel(isKo, _defenderPattern)}${_patternSecondsRemaining > 0 ? ' ${_patternSecondsRemaining}s' : ''}',
                                    icon:
                                        _roundArcStage == _RoundArcStage.chance
                                            ? Icons.flash_on_rounded
                                            : _roundArcStage ==
                                                    _RoundArcStage.rhythm
                                                ? Icons.sync_alt_rounded
                                                : Icons.visibility_outlined,
                                    alignEnd: true,
                                  ),
                                ),
                              ),
                              if (_goalChanceActive)
                                Positioned(
                                  left: 10,
                                  right: 10,
                                  bottom: 156,
                                  child: _PitchInfoBadge(
                                    title: shotHint.label,
                                    body: shotHint.detail,
                                    icon: Icons.sports_soccer,
                                    accent: shotHint.color,
                                  ),
                                ),
                              if (_lastShotOutcome != _ShotOutcome.none)
                                Positioned(
                                  left: 0,
                                  right: 0,
                                  bottom: 130,
                                  child: Center(
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 12,
                                        vertical: 7,
                                      ),
                                      decoration: BoxDecoration(
                                        color: switch (_lastShotOutcome) {
                                          _ShotOutcome.goal => const Color(
                                              0x990FA968,
                                            ),
                                          _ShotOutcome.saved => const Color(
                                              0x992F80ED,
                                            ),
                                          _ShotOutcome.miss => const Color(
                                              0x99EB5757,
                                            ),
                                          _ShotOutcome.none => const Color(
                                              0x99607D8B,
                                            ),
                                        },
                                        borderRadius: BorderRadius.circular(
                                          999,
                                        ),
                                      ),
                                      child: Text(
                                        _lastShotOutcome == _ShotOutcome.goal
                                            ? (isKo ? '골 성공!' : 'Goal!')
                                            : _lastShotOutcome ==
                                                    _ShotOutcome.saved
                                                ? (isKo
                                                    ? '골키퍼 선방'
                                                    : 'Keeper save')
                                                : (isKo
                                                    ? '슛 빗나감'
                                                    : 'Shot missed'),
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.w800,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              if (_showIdleHint)
                                Positioned(
                                  left: 12,
                                  right: 12,
                                  bottom: 88,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 8,
                                    ),
                                    decoration: BoxDecoration(
                                      color: const Color(0x7A102A43),
                                      borderRadius: BorderRadius.circular(10),
                                      border: Border.all(
                                        color: const Color(
                                          0xFF5DADE2,
                                        ).withValues(alpha: 0.55),
                                      ),
                                    ),
                                    child: Text(
                                      _idleHintText(isKo),
                                      textAlign: TextAlign.center,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 12,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ),
                                ),
                              for (var i = 0; i < _defenders.length; i++)
                                _entity(
                                  context,
                                  x: _defenders[i].x,
                                  y: _defenders[i].y,
                                  size: 29,
                                  color: _defenders[i].ghostType.color,
                                  kind: _EntityKind.defender,
                                  label: '',
                                  width: width,
                                  height: height,
                                ),
                              if (_goalChanceActive)
                                _entity(
                                  context,
                                  x: _goalLineX - 0.01,
                                  y: _keeperY,
                                  size: 29,
                                  color: const Color(0xFFFF6B6B),
                                  kind: _EntityKind.defender,
                                  label: '',
                                  width: width,
                                  height: height,
                                ),
                              _entity(
                                context,
                                x: _ballX,
                                y: _ballY,
                                size: 12,
                                color: Colors.white,
                                kind: _EntityKind.ball,
                                label: '',
                                width: width,
                                height: height,
                              ),
                              if (_charging)
                                Positioned(
                                  right: 14,
                                  bottom: 116,
                                  child: _PointerGauge(
                                    ratio: _chargeRatio,
                                    isKo: isKo,
                                  ),
                                ),
                              _buildJoystickControl(context),
                              _buildPassButton(context, isKo: isKo),
                              if (!_gameStarted || _timeUp)
                                Positioned.fill(
                                  child: Container(
                                    color: Colors.black.withAlpha(96),
                                    padding: const EdgeInsets.fromLTRB(
                                      20,
                                      24,
                                      20,
                                      28,
                                    ),
                                    child: Column(
                                      children: [
                                        const Spacer(),
                                        Container(
                                          constraints: const BoxConstraints(
                                            maxWidth: 320,
                                          ),
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 16,
                                            vertical: 14,
                                          ),
                                          decoration: BoxDecoration(
                                            color: Theme.of(context)
                                                .colorScheme
                                                .surface
                                                .withValues(alpha: 0.97),
                                            borderRadius: BorderRadius.circular(
                                              16,
                                            ),
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
                                                    fontWeight: FontWeight.w800,
                                                  ),
                                                ),
                                              if (_timeUp || _endedByFail)
                                                const SizedBox(height: 12),
                                              if (_timeUp || _endedByFail)
                                                Column(
                                                  children: [
                                                    Container(
                                                      width: double.infinity,
                                                      padding:
                                                          const EdgeInsets.all(
                                                        10,
                                                      ),
                                                      decoration: BoxDecoration(
                                                        color: Theme.of(context)
                                                            .colorScheme
                                                            .surfaceContainerHighest
                                                            .withValues(
                                                              alpha: 0.75,
                                                            ),
                                                        borderRadius:
                                                            BorderRadius
                                                                .circular(
                                                          10,
                                                        ),
                                                      ),
                                                      child: Column(
                                                        crossAxisAlignment:
                                                            CrossAxisAlignment
                                                                .start,
                                                        children: [
                                                          Text(
                                                            isKo
                                                                ? '무엇이 잘됐나: ${_bestPointText(isKo)}'
                                                                : 'What worked: ${_bestPointText(isKo)}',
                                                            style:
                                                                const TextStyle(
                                                              fontSize: 12,
                                                              fontWeight:
                                                                  FontWeight
                                                                      .w700,
                                                            ),
                                                          ),
                                                          const SizedBox(
                                                            height: 4,
                                                          ),
                                                          Text(
                                                            isKo
                                                                ? '무엇이 막혔나: ${_failureReasonText(isKo)}'
                                                                : 'What failed: ${_failureReasonText(isKo)}',
                                                            style:
                                                                const TextStyle(
                                                              fontSize: 12,
                                                              fontWeight:
                                                                  FontWeight
                                                                      .w700,
                                                            ),
                                                          ),
                                                          const SizedBox(
                                                            height: 4,
                                                          ),
                                                          Text(
                                                            isKo
                                                                ? '다음 실험: ${_improvePointText(isKo)}'
                                                                : 'Next experiment: ${_improvePointText(isKo)}',
                                                            style:
                                                                const TextStyle(
                                                              fontSize: 12,
                                                              fontWeight:
                                                                  FontWeight
                                                                      .w700,
                                                            ),
                                                          ),
                                                        ],
                                                      ),
                                                    ),
                                                    const SizedBox(height: 10),
                                                    Text(
                                                      isKo
                                                          ? '랭킹 ${_finalRanking.isEmpty ? _rankingLabel(_rankScore, isKo) : _finalRanking} ($_rankScore점)'
                                                          : 'Rank ${_finalRanking.isEmpty ? _rankingLabel(_rankScore, isKo) : _finalRanking} ($_rankScore)',
                                                      style: TextStyle(
                                                        fontSize: 18,
                                                        fontWeight:
                                                            FontWeight.w900,
                                                        color: Theme.of(
                                                          context,
                                                        ).colorScheme.primary,
                                                      ),
                                                    ),
                                                    const SizedBox(height: 6),
                                                    Text(
                                                      isKo
                                                          ? '점수 $_score  보너스 $_bonusScore  레벨 Lv.$_level  골 $_goals'
                                                          : 'Score $_score  Bonus $_bonusScore  Level Lv.$_level  Goals $_goals',
                                                      textAlign:
                                                          TextAlign.center,
                                                      style: const TextStyle(
                                                        fontWeight:
                                                            FontWeight.w700,
                                                      ),
                                                    ),
                                                    const SizedBox(height: 14),
                                                  ],
                                                ),
                                              FilledButton.icon(
                                                onPressed: _canStartByGate
                                                    ? _tryStartGame
                                                    : _tryStartGame,
                                                icon: const Icon(
                                                  Icons.play_arrow_rounded,
                                                  size: 24,
                                                ),
                                                label: Text(
                                                  isKo ? '게임 시작' : 'Start Game',
                                                  style: const TextStyle(
                                                    fontWeight: FontWeight.w800,
                                                    fontSize: 16,
                                                  ),
                                                ),
                                                style: FilledButton.styleFrom(
                                                  minimumSize:
                                                      const Size.fromHeight(52),
                                                  shape: RoundedRectangleBorder(
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                      14,
                                                    ),
                                                  ),
                                                ),
                                              ),
                                              const SizedBox(height: 10),
                                              Container(
                                                width: double.infinity,
                                                padding: const EdgeInsets.all(
                                                  10,
                                                ),
                                                decoration: BoxDecoration(
                                                  color: const Color(
                                                    0xFF102A43,
                                                  ).withValues(alpha: 0.92),
                                                  borderRadius:
                                                      BorderRadius.circular(10),
                                                  border: Border.all(
                                                    color: const Color(
                                                      0xFF5DADE2,
                                                    ).withValues(alpha: 0.45),
                                                  ),
                                                ),
                                                child: Text(
                                                  _recommendedMissionText(isKo),
                                                  textAlign: TextAlign.center,
                                                  style: const TextStyle(
                                                    color: Colors.white,
                                                    fontSize: 12,
                                                    fontWeight: FontWeight.w700,
                                                  ),
                                                ),
                                              ),
                                              if (_isAndroidGateEnabled) ...[
                                                const SizedBox(height: 10),
                                                Text(
                                                  isKo
                                                      ? '훈련노트 $_trainingNoteCount개 · 사용 $_playedGameCount판 · 남은 $_remainingGameCount판'
                                                      : 'Notes $_trainingNoteCount · Used $_playedGameCount · Left $_remainingGameCount',
                                                  textAlign: TextAlign.center,
                                                  style: Theme.of(context)
                                                      .textTheme
                                                      .bodySmall
                                                      ?.copyWith(
                                                        color: Theme.of(context)
                                                            .colorScheme
                                                            .onSurfaceVariant,
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
                            ],
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

  Widget _buildHeaderIconButton(
    BuildContext context, {
    required IconData icon,
    required String label,
    required VoidCallback onPressed,
  }) {
    return Tooltip(
      message: label,
      child: IconButton.outlined(
        onPressed: onPressed,
        icon: Icon(icon, size: 20),
        visualDensity: VisualDensity.compact,
        style: IconButton.styleFrom(
          backgroundColor: Theme.of(
            context,
          ).colorScheme.surface.withValues(alpha: 0.76),
        ),
      ),
    );
  }

  Widget _buildStatChip(
    BuildContext context, {
    required String label,
    required String value,
    required IconData icon,
    bool emphasize = false,
  }) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: emphasize
            ? scheme.primaryContainer.withValues(alpha: 0.82)
            : scheme.surfaceContainerHighest.withValues(alpha: 0.82),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: emphasize
              ? scheme.primary.withValues(alpha: 0.72)
              : scheme.outlineVariant.withValues(alpha: 0.8),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 15,
            color: emphasize ? scheme.primary : scheme.onSurfaceVariant,
          ),
          const SizedBox(width: 6),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(label, style: Theme.of(context).textTheme.labelSmall),
              const SizedBox(height: 1),
              Text(
                value,
                style: Theme.of(
                  context,
                ).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w900),
              ),
            ],
          ),
        ],
      ),
    );
  }

  _PassPrediction _predictPassTo(
    double ballSpeed,
    double targetX,
    double targetY,
  ) {
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
        if (_awaitingShotOutcome || _awaitingFailFinish) return;
        _fieldScrollX = (_fieldScrollX + (_dt * 0.42)) % 1.0;
        _updatePlayers();
        if (!_gameStarted || _timeUp) return;
        _updateCharge();
        _updateBall();
      });
    });
  }

  void _startGame() {
    setState(() {
      _gameStarted = true;
      _timeUp = false;
      _endedByFail = false;
      _finalRanking = '';
      _remainingSeconds = 20;
      _score = 0;
      _goals = 0;
      _combo = 0;
      _bonusScore = 0;
      _lives = 3;
      _maxComboInRun = 0;
      _lastFailedReason = null;
      _lastInteractionAt = DateTime.now();
      _finalShotMode = false;
      _goalChanceActive = false;
      _attackerAIsPasser = true;
      _level = 1;
      _currentPassRisk = _PassRiskType.safe;
      _activeEvent = _GameEvent.none;
      _defenderPattern = _DefenderPattern.laneClosing;
      _eventSecondsRemaining = 0;
      _patternSecondsRemaining = 6;
      _feverSecondsRemaining = 0;
      _lastSuccessAt = null;
      _rhythmStreak = 0;
      _mission = _rollMission();
      _plannedPassOpenSpace = 0;
      _lastSuccessfulPassRisk = null;
      _samePassRiskStreak = 0;
      _resetRound(keepScore: false);
      _reactionLabel = '';
      _reactionDetail = '';
      _reactionColor = const Color(0xFF8FA3BF);
      _reactionIcon = Icons.adjust;
      _lastShotOutcome = _ShotOutcome.none;
      _awaitingShotOutcome = false;
      _awaitingFailFinish = false;
      _failEndTimer?.cancel();
      _shotOutcomeTimer?.cancel();
    });
    _startGameTimer();
  }

  void _startGameTimer() {
    _gameTimer?.cancel();
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
        if (_awaitingShotOutcome) return;
        _remainingSeconds = (_remainingSeconds - 1).clamp(0, 999);
        if (_eventSecondsRemaining > 0) {
          _eventSecondsRemaining -= 1;
          if (_eventSecondsRemaining <= 0) {
            _activeEvent = _GameEvent.none;
          }
        } else if (_remainingSeconds > 3 && _random.nextDouble() < 0.35) {
          _rollRandomEvent();
        }
        if (_patternSecondsRemaining > 0) {
          _patternSecondsRemaining -= 1;
        }
        if (_patternSecondsRemaining <= 0) {
          _rollDefenderPattern();
        }
        if (_feverSecondsRemaining > 0) {
          _feverSecondsRemaining -= 1;
        }
        _syncDefendersForLevel();
        if (_remainingSeconds <= 0) {
          _remainingSeconds = 0;
          _enterFinalShotMode();
          timer.cancel();
        }
      });
    });
  }

  _MissionState _rollMission() {
    const missionTypes = <_MissionType>[
      _MissionType.safePasses,
      _MissionType.killerPasses,
      _MissionType.riskyPasses,
      _MissionType.combo,
      _MissionType.goals,
    ];
    final type = missionTypes[_random.nextInt(missionTypes.length)];
    final target = switch (type) {
      _MissionType.safePasses => 4,
      _MissionType.killerPasses => 3,
      _MissionType.riskyPasses => 2,
      _MissionType.combo => 8,
      _MissionType.goals => 1,
    };
    return _MissionState(type: type, target: target, progress: 0);
  }

  void _rollRandomEvent() {
    const events = <_GameEvent>[
      _GameEvent.narrowLanes,
      _GameEvent.wideLanes,
      _GameEvent.tailWind,
    ];
    _activeEvent = events[_random.nextInt(events.length)];
    _eventSecondsRemaining = 8;
  }

  void _rollDefenderPattern() {
    const patterns = <_DefenderPattern>[
      _DefenderPattern.laneClosing,
      _DefenderPattern.receiverTracking,
      _DefenderPattern.counterPress,
    ];
    final currentIndex = patterns.indexOf(_defenderPattern);
    final nextIndex =
        (currentIndex + 1 + _random.nextInt(patterns.length - 1)) %
            patterns.length;
    _defenderPattern = patterns[nextIndex];
    _patternSecondsRemaining = _remainingSeconds <= 10 ? 4 : 6;
  }

  void _updatePlayers() {
    final attackerPace = _attackerPaceScale;
    final defenderPace = _defenderPaceScale;
    final feverMoveBoost = _feverSecondsRemaining > 0 ? 1.06 : 1.0;
    final feverDefenderSlow = _feverSecondsRemaining > 0 ? 0.86 : 1.0;
    final comboBoost = (1 + (_combo * 0.05)).clamp(1.0, 1.8);
    final levelBoost = (1 + ((_level - 1) * 0.04)).clamp(1.0, 1.6);
    final runSpeed = (0.11 + ((_level - 1) * 0.006)).clamp(0.11, 0.22);
    final clutchBoost = _remainingSeconds <= 15 ? 1.12 : 1.0;
    final patternLaneMul = switch (_defenderPattern) {
      _DefenderPattern.laneClosing => 1.40,
      _DefenderPattern.receiverTracking => 0.88,
      _DefenderPattern.counterPress => 0.95,
    };
    final patternRoleMul = switch (_defenderPattern) {
      _DefenderPattern.laneClosing => 0.95,
      _DefenderPattern.receiverTracking => 1.45,
      _DefenderPattern.counterPress => 1.55,
    };
    final patternSpeedMul = switch (_defenderPattern) {
      _DefenderPattern.laneClosing => 1.00,
      _DefenderPattern.receiverTracking => 1.04,
      _DefenderPattern.counterPress => 1.12,
    };
    const avoidRadius = 0.22;
    var passerAvoidX = 0.0;
    var passerAvoidY = 0.0;
    var receiverAvoidX = 0.0;
    var receiverAvoidY = 0.0;
    var passerThreatAhead = 0;
    var receiverThreatAhead = 0;
    for (final defender in _defenders) {
      final passerDx = _passerXPos - defender.x;
      final passerDy = _passerYPos - defender.y;
      final passerDist = math.sqrt(
        (passerDx * passerDx) + (passerDy * passerDy),
      );
      if (passerDist > 1e-4 && passerDist < avoidRadius) {
        final strength = (avoidRadius - passerDist) / avoidRadius;
        passerAvoidX += (passerDx / passerDist) * strength;
        passerAvoidY += (passerDy / passerDist) * strength;
        if (defender.x > _passerXPos) {
          passerThreatAhead++;
        }
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
        if (defender.x > _receiverX) {
          receiverThreatAhead++;
        }
      }
    }

    final passerIsA = _attackerAIsPasser;
    final controlPasser = _isControllingPasser;
    final controlA = controlPasser ? passerIsA : !passerIsA;
    final aiA = !controlA;
    final aiPasser = controlPasser ? !passerIsA : passerIsA;
    final freezeShotScene = _freezeShotScene;
    if (aiA && _random.nextDouble() < 0.05) {
      _passerVx += (_random.nextDouble() * 0.08) - 0.02;
      _passerVy += (_random.nextDouble() * 0.16) - 0.08;
    }
    if (!aiA && _random.nextDouble() < 0.05) {
      _receiverVx += (_random.nextDouble() * 0.08) - 0.02;
      _receiverVy += (_random.nextDouble() * 0.16) - 0.08;
    }
    final forwardBoost = (1.0 + (passerAvoidX.abs() * 0.18)).clamp(1.0, 1.5);
    final forwardBoostB = (1.0 + (receiverAvoidX.abs() * 0.18)).clamp(1.0, 1.5);
    if (aiPasser) {
      _passerVx += 0.018 * forwardBoost;
      _passerVy += passerAvoidY * 0.045;
      final aheadPressure = passerThreatAhead.clamp(0, 3);
      if (aheadPressure > 0) {
        _passerVx +=
            (0.016 * aheadPressure) + (math.max(0.0, -passerAvoidX) * 0.045);
        _passerVy += passerAvoidY * 0.060;
      }
      if (passerAvoidY.abs() < 0.015 && aheadPressure > 0) {
        _passerVy += (_random.nextBool() ? 1 : -1) * 0.020;
      }
    }
    if (!aiPasser) {
      _receiverVx += 0.018 * forwardBoostB;
      _receiverVy += receiverAvoidY * 0.045;
      final aheadPressure = receiverThreatAhead.clamp(0, 3);
      if (aheadPressure > 0) {
        _receiverVx +=
            (0.016 * aheadPressure) + (math.max(0.0, -receiverAvoidX) * 0.045);
        _receiverVy += receiverAvoidY * 0.060;
      }
      if (receiverAvoidY.abs() < 0.015 && aheadPressure > 0) {
        _receiverVy += (_random.nextBool() ? 1 : -1) * 0.020;
      }
    }
    if (!freezeShotScene) {
      _applyJoystickToControlledAttacker();
      if (controlA) {
        _passerVx *= 0.94;
        _passerVy *= 0.94;
      } else {
        _receiverVx *= 0.94;
        _receiverVy *= 0.94;
      }
      _passerVx = controlA
          ? _passerVx.clamp(-_playerJoystickMaxVx, _playerJoystickMaxVx)
          : _passerVx.clamp(
              aiPasser ? 0.06 : 0.07,
              (runSpeed + (aiPasser ? 0.06 : 0.07)) * clutchBoost,
            );
      _receiverVx = controlA
          ? _receiverVx.clamp(
              aiPasser ? 0.06 : 0.07,
              (runSpeed + (aiPasser ? 0.06 : 0.07)) * clutchBoost,
            )
          : _receiverVx.clamp(-_playerJoystickMaxVx, _playerJoystickMaxVx);
      _passerVy = _passerVy.clamp(-_playerJoystickMaxVy, _playerJoystickMaxVy);
      _receiverVy = _receiverVy.clamp(
        -_playerJoystickMaxVy,
        _playerJoystickMaxVy,
      );
      // Give the passer a short natural follow-through acceleration right after release.
      if (_ballFlying && !_goalChanceActive) {
        final flyingBoost = (0.010 + ((_level - 1) * 0.0015)).clamp(
          0.010,
          0.022,
        );
        if (passerIsA) {
          _passerVx = (_passerVx + flyingBoost).clamp(
            0.10,
            _playerJoystickMaxVx,
          );
        } else {
          _receiverVx = (_receiverVx + flyingBoost).clamp(
            0.10,
            _playerJoystickMaxVx,
          );
        }
      }
      _passerSpeedMul = 1.0;
      _receiverSpeedMul = 1.0;
      _passerXPos += _passerVx * _dt * attackerPace * feverMoveBoost;
      _passerYPos += _passerVy * _dt * attackerPace * feverMoveBoost;
      _receiverX += _receiverVx * _dt * attackerPace * feverMoveBoost;
      _receiverY += _receiverVy * _dt * attackerPace * feverMoveBoost;

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
        _passerVy = 0;
        _passerYPos = _passerYPos.clamp(minY, maxY);
      }
      if (_receiverY <= minY || _receiverY >= maxY) {
        _receiverVy = 0;
        _receiverY = _receiverY.clamp(minY, maxY);
      }
      const minForwardGap = 0.10;
      if (_activeReceiverX < (_activePasserX + minForwardGap)) {
        if (_attackerAIsPasser) {
          _receiverVx = (_receiverVx + 0.05).clamp(0.07, 0.26);
          _receiverX = (_receiverX + 0.014).clamp(minX, maxX);
        } else {
          _passerXPos = (_passerXPos + 0.014).clamp(minX, maxX);
          _passerVx = (_passerVx + 0.05).clamp(0.07, 0.26);
        }
      }
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

    if (!freezeShotScene) {
      for (final defender in _defenders) {
        final passBySpeed = defender.speed *
            defender.ghostType.speedFactor *
            comboBoost *
            levelBoost *
            clutchBoost *
            patternSpeedMul;
        defender.x -= passBySpeed * _dt * defenderPace * feverDefenderSlow;
        final lanePoint = _lanePointAtX(defender.x);
        final roleTargetY = _roleTargetY(defender, lanePoint.dy);
        final lanePull = (lanePoint.dy - defender.y) *
            defender.ghostType.lanePull *
            patternLaneMul *
            _dt *
            defenderPace;
        final rolePull = (roleTargetY - defender.y) *
            defender.ghostType.rolePull *
            patternRoleMul *
            _dt *
            defenderPace;
        defender.y += (defender.vy *
                passBySpeed *
                defender.ghostType.wobbleFactor *
                _dt *
                defenderPace *
                feverDefenderSlow) +
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
          defender.y = (roleY + ((_random.nextDouble() - 0.5) * 0.20)).clamp(
            defender.minY,
            defender.maxY,
          );
        }
      }
    }

    if (_finalShotMode && !freezeShotScene) {
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

    if (!freezeShotScene) {
      final leadX = math.max(_passerXPos, _receiverX);
      if (leadX > 0.60) {
        final shift = leadX - 0.60;
        _passerXPos -= shift;
        _receiverX -= shift;
        _ballX -= shift;
        _targetX = (_targetX - shift).clamp(_fieldMinX, _fieldMaxX);
        _aimX = (_aimX - shift).clamp(_fieldMinX, _fieldMaxX);
        if (_flightGuideLocked) {
          _flightGuideFromX = (_flightGuideFromX - shift).clamp(
            _fieldMinX,
            _fieldMaxX,
          );
          _flightGuideToX = (_flightGuideToX - shift).clamp(
            _fieldMinX,
            _fieldMaxX,
          );
        }
        for (final defender in _defenders) {
          defender.x -= shift;
        }
        _fieldScrollX = (_fieldScrollX + (shift * 2.8)).remainder(1.0);
      }
    }

    _updateAutoAim();
    if (_isActivePasserHitByGhost()) {
      _onFail(_PassResult.passerHit);
    }
  }

  void _applyJoystickToControlledAttacker() {
    final input = _joystickInput;
    if (input.distanceSquared <= 0.0001) return;
    final controlX = input.dx.clamp(-1.0, 1.0);
    final controlY = input.dy.clamp(-1.0, 1.0);
    final boost = (1.0 + (input.distance * 1.35)).clamp(1.0, 2.55);
    final controlA =
        _isControllingPasser ? _attackerAIsPasser : !_attackerAIsPasser;
    if (controlA) {
      _passerVx += controlX * _joystickAccelX * boost;
      _passerVy += controlY * _joystickAccelY * boost;
    } else {
      _receiverVx += controlX * _joystickAccelX * boost;
      _receiverVy += controlY * _joystickAccelY * boost;
    }
  }

  void _stopControlledAttacker() {
    final controlA =
        _isControllingPasser ? _attackerAIsPasser : !_attackerAIsPasser;
    if (controlA) {
      _passerVx = 0;
      _passerVy = 0;
    } else {
      _receiverVx = 0;
      _receiverVy = 0;
    }
  }

  void _updateAutoAim() {
    if (_ballFlying) return;
    if (_goalChanceActive) {
      var aimX = _goalLineX;
      var aimY = (_activePasserY + (_activeReceiverVy * 0.20)).clamp(
        _goalTopY + 0.04,
        _goalBottomY - 0.04,
      );
      if (_passAimActive) {
        aimX = (aimX + (_passAimInput.dx * 0.06)).clamp(0.72, _goalLineX);
        aimY = (aimY + (_passAimInput.dy * 0.18)).clamp(
          _goalTopY + 0.02,
          _goalBottomY - 0.02,
        );
      }
      _aimX = aimX;
      _aimY = aimY;
      return;
    }
    var aimX = (_activeReceiverX + _leadDistance).clamp(_fieldMinX, _fieldMaxX);
    var aimY = _activeReceiverY.clamp(_fieldMinY, _fieldMaxY);
    if (_passAimActive) {
      final minForwardX = math.min(_fieldMaxX, _activePasserX + 0.06);
      final strength = _passAimStrength;
      final dir = _passAimInput / math.max(strength, 0.001);
      final distanceByAim = 0.14 + (strength * 0.62);
      final fallbackX =
          (_activeReceiverX + _leadDistance + (_passAimInput.dx * 0.28)).clamp(
        minForwardX,
        _fieldMaxX,
      );
      final fallbackY = (_activeReceiverY + (_passAimInput.dy * 0.32)).clamp(
        _fieldMinY,
        _fieldMaxY,
      );
      final aimedX = (_activePasserX + (dir.dx * distanceByAim)).clamp(
        minForwardX,
        _fieldMaxX,
      );
      final aimedY = (_activePasserY + (dir.dy * (0.10 + (strength * 0.42))))
          .clamp(_fieldMinY, _fieldMaxY);
      final blend = (0.42 + (strength * 0.48)).clamp(0.42, 0.90);
      aimX = (fallbackX * (1 - blend)) + (aimedX * blend);
      aimY = (fallbackY * (1 - blend)) + (aimedY * blend);
    }
    _aimX = aimX;
    _aimY = aimY;
  }

  bool _isActivePasserHitByGhost() {
    if (_phase != _PlayPhase.ready || _ballFlying || !_gameStarted) {
      return false;
    }
    for (final defender in _defenders) {
      if (_distance(_activePasserX, _activePasserY, defender.x, defender.y) <=
          0.050) {
        return true;
      }
    }
    return false;
  }

  void _updateCharge() {
    if (!_charging || _chargeStartedAt == null) return;
    final held =
        DateTime.now().difference(_chargeStartedAt!).inMilliseconds / 1000.0;
    _chargedBallSpeed = (_ballMinSpeed + held * 0.8).clamp(
      _ballMinSpeed,
      _ballMaxSpeed,
    );
  }

  void _updateBall() {
    if (!_ballFlying) {
      final holdPoint = _activePasserBallHoldPoint();
      _ballX = holdPoint.dx;
      _ballY = holdPoint.dy;
      return;
    }
    if (_ballSettling) {
      _updateBallSettling();
      return;
    }

    final ballScale = (0.80 + ((_attackerPaceScale - 1.0) * 0.35)).clamp(
      0.80,
      1.35,
    );
    _flightElapsed += _dt;
    _ballX += _ballVx * _dt * ballScale;
    _ballY += _ballVy * _dt * ballScale;

    final currentDistance = _distance(
      _ballX,
      _ballY,
      _activeReceiverX,
      _activeReceiverY,
    );
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
    final controllableCenter = caughtByCenter &&
        receivingEval.along >= -(receivingEval.backReach * 0.20);
    if (controllableCenter || caughtByWindow) {
      if (caughtByWindow && !caughtByCenter) {
        _closestReceiverDistance = math.min(_closestReceiverDistance, 0.055);
      }
      final timingGap = (_flightElapsed - _predReceiverTime).abs();
      _lastControlProbability = _controlProbability(
        receivingEval,
        timingGap: timingGap,
        byCenter: caughtByCenter,
      );
      _beginBallSettling(_lastControlProbability);
      return;
    }

    final reachedTarget =
        _distance(_ballX, _ballY, _targetX, _targetY) <= 0.025;
    final out = _ballX > 1.02 ||
        _ballY < -0.05 ||
        _ballY > 1.05 ||
        _flightElapsed > 3.0;
    if (reachedTarget || (_flightElapsed > 3.0 && !_isLooseBallOutOfBounds())) {
      if (_recoverLooseBall()) {
        return;
      }
    }
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

  bool _isLooseBallOutOfBounds() {
    return _ballX > 1.02 || _ballY < -0.05 || _ballY > 1.05;
  }

  void _beginCharge() {
    if (_phase != _PlayPhase.ready || _ballFlying) return;
    _charging = true;
    _ballSettling = false;
    _chargeStartedAt = DateTime.now();
    _chargedBallSpeed = _ballMinSpeed;
    _effectiveBallSpeed = _ballMinSpeed;
  }

  void _beginBallSettling(double controlProbability) {
    _ballSettling = true;
    _settleControlProbability = controlProbability;
    _ballVx *= 0.42;
    _ballVy *= 0.42;
  }

  void _updateBallSettling() {
    final holdPoint = _activeReceiverBallHoldPoint();
    final dx = holdPoint.dx - _ballX;
    final dy = holdPoint.dy - _ballY;
    final distance = math.sqrt((dx * dx) + (dy * dy));
    final blend = (0.28 + ((_effectiveBallSpeed / _ballMaxSpeed) * 0.18)).clamp(
      0.28,
      0.48,
    );
    _ballX += dx * blend;
    _ballY += dy * blend;
    _ballVx *= 0.62;
    _ballVy *= 0.62;
    if (distance <= 0.012) {
      _ballX = holdPoint.dx;
      _ballY = holdPoint.dy;
      _ballSettling = false;
      _onSuccess(controlProbability: _settleControlProbability);
    }
  }

  void _releaseChargeAndPass() {
    if (!_charging || _phase != _PlayPhase.ready || _ballFlying) return;
    _charging = false;
    _chargeStartedAt = null;
    if (_goalChanceActive) {
      final passerIsA = _attackerAIsPasser;
      _targetX = _aimX.clamp(0.72, _goalLineX);
      _targetY = _aimY.clamp(_goalTopY, _goalBottomY);
      final dx = _targetX - _activePasserX;
      final dy = _targetY - _activePasserY;
      final dist = math.sqrt(dx * dx + dy * dy);
      if (dist < 1e-6) return;
      final dirX = dx / dist;
      final dirY = dy / dist;
      _effectiveBallSpeed = _chargedBallSpeed.clamp(
        _ballMinSpeed,
        _ballMaxSpeed,
      );
      _predReceiverTime = 0;
      _ballVx = dirX * _effectiveBallSpeed;
      _ballVy = dirY * _effectiveBallSpeed;
      final holdPoint = _activePasserBallHoldPoint();
      _ballX = holdPoint.dx;
      _ballY = holdPoint.dy;
      _flightElapsed = 0;
      _closestReceiverDistance = 999;
      _timingDiffAtClosest = 999;
      _ballFlying = true;
      _phase = _PlayPhase.flying;
      _flightNearMissAwarded = false;
      _lockFlightGuide(fromX: _activePasserX, toX: _targetX);
      _applyImmediatePasserAdvance(
        passerIsA: passerIsA,
        passDirX: dirX,
        passDirY: dirY,
      );
      _applyPasserBurst(dirX, dirY);
      _currentPassRisk = _PassRiskType.killer;
      _plannedPassOpenSpace = _minDefenderDistanceToPoint(_targetX, _targetY);
      return;
    }
    final passerIsA = _attackerAIsPasser;
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
      math.sqrt(
        _activePasserVx * _activePasserVx + _activePasserVy * _activePasserVy,
      ),
    );
    final passerDirX = _activePasserVx / passerSpeed;
    final passerDirY = _activePasserVy / passerSpeed;
    final bodyTurn = _turnAngle(passerDirX, passerDirY, passDirX, passDirY);
    final bodyTurnPenalty = (1 - (0.20 * (bodyTurn / math.pi))).clamp(
      0.78,
      1.0,
    );
    _effectiveBallSpeed =
        (_chargedBallSpeed * bodyTurnPenalty * _passLengthScale).clamp(
      _ballMinSpeed,
      _ballMaxSpeed,
    );
    _effectiveBallSpeed = (_effectiveBallSpeed * _eventBallSpeedScale).clamp(
      _ballMinSpeed,
      1.35,
    );
    _currentPassRisk = _classifyPassRisk(
      passDistance: dist,
      targetOpenSpace: _minDefenderDistanceToPoint(_targetX, _targetY),
    );
    _plannedPassOpenSpace = _minDefenderDistanceToPoint(_targetX, _targetY);
    _ballVx = passDirX * _effectiveBallSpeed;
    _ballVy = passDirY * _effectiveBallSpeed;
    final holdPoint = _activePasserBallHoldPoint();
    _ballX = holdPoint.dx;
    _ballY = holdPoint.dy;
    _flightElapsed = 0;
    _closestReceiverDistance = 999;
    _timingDiffAtClosest = 999;
    _ballFlying = true;
    _phase = _PlayPhase.flying;
    _flightNearMissAwarded = false;
    _lockFlightGuide(fromX: _activePasserX, toX: _targetX);
    _applyImmediatePasserAdvance(
      passerIsA: passerIsA,
      passDirX: passDirX,
      passDirY: passDirY,
    );
    _applyPasserBurst(passDirX, passDirY);
  }

  _PassRiskType _classifyPassRisk({
    required double passDistance,
    required double targetOpenSpace,
  }) {
    if (passDistance <= 0.26 && targetOpenSpace >= 0.10) {
      return _PassRiskType.safe;
    }
    if (passDistance >= 0.42 || targetOpenSpace <= 0.055) {
      return _PassRiskType.risky;
    }
    return _PassRiskType.killer;
  }

  double _minDefenderDistanceToPoint(double x, double y) {
    var nearest = 999.0;
    for (final defender in _defenders) {
      final d = _distance(x, y, defender.x, defender.y);
      if (d < nearest) nearest = d;
    }
    return nearest.isFinite ? nearest : 0;
  }

  void _applyImmediatePasserAdvance({
    required bool passerIsA,
    required double passDirX,
    required double passDirY,
  }) {
    final chargeRatio =
        ((_chargedBallSpeed - _ballMinSpeed) / (_ballMaxSpeed - _ballMinSpeed))
            .clamp(0.0, 1.0);
    final forwardKick = (0.24 + (chargeRatio * 0.20)).clamp(0.24, 0.44);
    final lateralKick = (passDirY * (0.05 + (chargeRatio * 0.04))).clamp(
      -0.12,
      0.12,
    );
    const immediateStep = 0.015;

    if (passerIsA) {
      _passerVx = math.max(_passerVx, forwardKick);
      _passerVy = (_passerVy + lateralKick).clamp(-0.28, 0.28);
      _passerXPos = (_passerXPos + immediateStep).clamp(_fieldMinX, _fieldMaxX);
    } else {
      _receiverVx = math.max(_receiverVx, forwardKick);
      _receiverVy = (_receiverVy + lateralKick).clamp(-0.28, 0.28);
      _receiverX = (_receiverX + immediateStep).clamp(_fieldMinX, _fieldMaxX);
    }
  }

  void _lockFlightGuide({required double fromX, required double toX}) {
    _flightGuideLocked = true;
    _flightGuideFromX = fromX;
    _flightGuideToX = toX;
  }

  void _clearFlightGuide() {
    _flightGuideLocked = false;
  }

  void _applyPasserBurst(double dirX, double dirY) {
    final normalizedCharge =
        ((_chargedBallSpeed - _ballMinSpeed) / (_ballMaxSpeed - _ballMinSpeed))
            .clamp(0.0, 1.0);
    final burst = (0.16 + (normalizedCharge * 0.18)).clamp(0.16, 0.34);
    final vxBoost = (math.max(0.12, dirX) * burst).clamp(0.12, 0.40);
    final vyBoost = (dirY * (burst * 0.45)).clamp(-0.16, 0.16);

    if (_attackerAIsPasser) {
      _passerVx = math.max(_passerVx, vxBoost);
      _passerVy = ((_passerVy * 0.45) + vyBoost).clamp(-0.26, 0.26);
    } else {
      _receiverVx = math.max(_receiverVx, vxBoost);
      _receiverVy = ((_receiverVy * 0.45) + vyBoost).clamp(-0.26, 0.26);
    }
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
    _charging = false;
    _chargeStartedAt = null;
    _chargedBallSpeed = _ballMinSpeed;
    _effectiveBallSpeed = _ballMinSpeed;
    _passPressed = false;
    _passPointerId = null;
    _passChargeArmed = false;
  }

  void _onSuccess({double? controlProbability}) {
    _lastInteractionAt = DateTime.now();
    _clearFlightGuide();
    _playGameSound(_GameSoundType.passComplete);
    _setReaction(_PassResult.perfect, controlProbability: controlProbability);
    _attackerAIsPasser = !_attackerAIsPasser;
    _score += 1;
    _combo += 1;
    final now = DateTime.now();
    if (_lastSuccessAt != null) {
      final gap = now.difference(_lastSuccessAt!).inMilliseconds;
      if (gap >= 350 && gap <= 1200) {
        _rhythmStreak += 1;
      } else {
        _rhythmStreak = 1;
      }
    } else {
      _rhythmStreak = 1;
    }
    _lastSuccessAt = now;
    if (_rhythmStreak >= 3) {
      _awardBonus(3, reason: _koText('리듬 보너스', 'Rhythm bonus'));
      _rhythmStreak = 0;
    }
    final passBonus = switch (_currentPassRisk) {
      _PassRiskType.safe => 1,
      _PassRiskType.killer => 4,
      _PassRiskType.risky => 6,
    };
    if (_lastSuccessfulPassRisk == _currentPassRisk) {
      _samePassRiskStreak += 1;
    } else {
      _samePassRiskStreak = 1;
      _lastSuccessfulPassRisk = _currentPassRisk;
    }
    final efficiencyMultiplier = _passEfficiencyMultiplier;
    _awardBonus(
      (passBonus * efficiencyMultiplier).round(),
      reason: _passRiskLabel(_isKoLocale, _currentPassRisk),
    );
    if (_plannedPassOpenSpace >= 0.13) {
      _awardBonus(4, reason: _koText('공간 선택', 'Space found'));
    }
    if (_samePassRiskStreak >= 3) {
      _reactionDetail = _koText(
        '같은 패스가 $_samePassRiskStreak회째라 효율이 ${((efficiencyMultiplier) * 100).round()}%로 감소합니다. 다음엔 반대 선택을 섞어보세요.',
        'Same pass repeated $_samePassRiskStreak times, so efficiency dropped to ${((efficiencyMultiplier) * 100).round()}%. Mix a different option next.',
      );
    }
    if (_combo > _maxComboInRun) {
      _maxComboInRun = _combo;
    }
    if (_combo >= 8 && _feverSecondsRemaining <= 0) {
      _feverSecondsRemaining = 5;
      _setReaction(_PassResult.fever);
    }
    _updateMissionProgress(success: true);
    _maybeLevelUp();
    _updateWeeklyBest();
    _continueAfterSuccess();
  }

  double get _passEfficiencyMultiplier {
    if (_samePassRiskStreak <= 2) return 1.0;
    if (_samePassRiskStreak == 3) return 0.75;
    if (_samePassRiskStreak == 4) return 0.55;
    return 0.40;
  }

  void _onGoalScored() {
    _lastInteractionAt = DateTime.now();
    final wasFinalShot = _finalShotMode || _remainingSeconds <= 0;
    _playGameSound(_GameSoundType.goal);
    _goals += 1;
    _score += 3;
    _lastShotOutcome = _ShotOutcome.goal;
    _awaitingShotOutcome = true;
    _goalChanceActive = false;
    _finalShotMode = false;
    _ballFlying = false;
    _ballSettling = false;
    _setReaction(_PassResult.goal);
    _awardBonus(10, reason: _koText('골 보너스', 'Goal bonus'));
    _updateMissionProgress(goalScored: true);
    _scheduleShotOutcomeFinish(
      failed: false,
      restartAfterOutcome: wasFinalShot,
    );
  }

  bool _recoverLooseBall() {
    if (_goalChanceActive || _finalShotMode || _isLooseBallOutOfBounds()) {
      return false;
    }
    final controlledIsA = !_attackerAIsPasser;
    final controlledDistance = controlledIsA
        ? _distance(_ballX, _ballY, _passerXPos, _passerYPos)
        : _distance(_ballX, _ballY, _receiverX, _receiverY);
    final supportDistance = controlledIsA
        ? _distance(_ballX, _ballY, _receiverX, _receiverY)
        : _distance(_ballX, _ballY, _passerXPos, _passerYPos);

    bool ownerIsA;
    if (controlledDistance <= 0.16) {
      ownerIsA = controlledIsA;
    } else if (supportDistance <= 0.12) {
      ownerIsA = !controlledIsA;
    } else {
      return false;
    }

    if (ownerIsA) {
      _passerXPos = _ballX.clamp(0.22, 0.80);
      _passerYPos = _ballY.clamp(0.14, 0.86);
      _passerVx = 0.08;
      _passerVy = 0;
    } else {
      _receiverX = _ballX.clamp(0.22, 0.80);
      _receiverY = _ballY.clamp(0.14, 0.86);
      _receiverVx = 0.08;
      _receiverVy = 0;
    }

    _attackerAIsPasser = ownerIsA;
    _ballFlying = false;
    _ballSettling = false;
    _phase = _PlayPhase.ready;
    _charging = false;
    _chargeStartedAt = null;
    _chargedBallSpeed = _ballMinSpeed;
    _effectiveBallSpeed = _ballMinSpeed;
    _flightElapsed = 0;
    _closestReceiverDistance = 999;
    _timingDiffAtClosest = 999;
    _ballVx = 0;
    _ballVy = 0;
    _clearFlightGuide();
    final holdPoint = _activePasserBallHoldPoint();
    _ballX = holdPoint.dx;
    _ballY = holdPoint.dy;
    _targetX = (_activeReceiverX + _leadDistance).clamp(_fieldMinX, _fieldMaxX);
    _targetY = _activeReceiverY;
    _aimX = _targetX;
    _aimY = _targetY;
    _reactionIcon = Icons.sports_soccer;
    _reactionColor = const Color(0xFF2F80ED);
    _reactionLabel = _koText('공 소유 유지', 'Keep possession');
    _reactionDetail = _koText(
      '직접 연결은 아니었지만 가장 가까운 공격수가 공을 잡아 공격을 이어갑니다.',
      'The pass did not connect cleanly, but the nearest attacker kept the ball.',
    );
    return true;
  }

  void _activateGoalChance() {
    _goalChanceActive = true;
    _setReaction(_PassResult.shotReady);
    _phase = _PlayPhase.ready;
    _ballFlying = false;
    _ballSettling = false;
    _charging = false;
    _chargeStartedAt = null;
    _ballVx = 0;
    _ballVy = 0;
    _flightElapsed = 0;
    _closestReceiverDistance = 999;
    _timingDiffAtClosest = 999;
    _aimX = _goalLineX;
    _aimY = ((_activePasserY + _activeReceiverY) * 0.5).clamp(
      _goalTopY,
      _goalBottomY,
    );
    final holdPoint = _activePasserBallHoldPoint();
    _ballX = holdPoint.dx;
    _ballY = holdPoint.dy;
  }

  void _enterFinalShotMode() {
    _finalShotMode = true;
    _defenders.clear();
    _activateGoalChance();
    _setReaction(_PassResult.shotReady);
  }

  void _onFail([_PassResult result = _PassResult.miss]) {
    _lastInteractionAt = DateTime.now();
    _playGameSound(_GameSoundType.fail);
    _lastSuccessAt = null;
    _rhythmStreak = 0;
    _lastFailedReason = result;
    _lastSuccessfulPassRisk = null;
    _samePassRiskStreak = 0;
    _clearFlightGuide();
    _combo = 0;
    final wasShotRound = _goalChanceActive || _finalShotMode;
    if (wasShotRound &&
        (result == _PassResult.saved || result == _PassResult.miss)) {
      _lastShotOutcome =
          result == _PassResult.saved ? _ShotOutcome.saved : _ShotOutcome.miss;
    }
    _setReaction(result);
    if (_mission.type == _MissionType.combo) {
      _mission = _mission.copyWith(progress: _combo.clamp(0, _mission.target));
    }
    if (_finalShotMode) {
      _goalChanceActive = false;
      _ballFlying = false;
      _awaitingShotOutcome = true;
      _scheduleShotOutcomeFinish(failed: true, restartAfterOutcome: true);
    } else {
      _scheduleFailFinish();
    }
  }

  void _scheduleFailFinish() {
    _failEndTimer?.cancel();
    _phase = _PlayPhase.roundEnd;
    _ballFlying = false;
    _ballSettling = false;
    _clearFlightGuide();
    _charging = false;
    _chargeStartedAt = null;
    _joystickInput = Offset.zero;
    _joystickActive = false;
    _joystickPointerId = null;
    _passPressed = false;
    _passAimInput = Offset.zero;
    _passAimActive = false;
    _passPointerId = null;
    _passChargeArmed = false;
    _awaitingFailFinish = true;
    _failEndTimer = Timer(const Duration(milliseconds: 1100), () {
      if (!mounted) return;
      setState(() {
        _awaitingFailFinish = false;
        _consumeLifeOrEndGame();
      });
    });
  }

  void _consumeLifeOrEndGame({bool restartClock = false}) {
    if (_lives > 1) {
      _lives -= 1;
      _setReaction(_PassResult.retry);
      if (restartClock) {
        _remainingSeconds = 20;
        _timeUp = false;
        _gameStarted = true;
        _endedByFail = false;
        _startGameTimer();
      }
      _resetRound(keepScore: true);
      return;
    }
    _lives = 0;
    _endGameOnFail();
  }

  void _scheduleShotOutcomeFinish({
    required bool failed,
    required bool restartAfterOutcome,
  }) {
    _shotOutcomeTimer?.cancel();
    _shotOutcomeTimer = Timer(const Duration(milliseconds: 1400), () {
      if (!mounted) return;
      setState(() {
        _awaitingShotOutcome = false;
        if (failed) {
          _consumeLifeOrEndGame(restartClock: restartAfterOutcome);
        } else {
          _continueAfterGoalScored(restartClock: restartAfterOutcome);
        }
      });
    });
  }

  void _continueAfterGoalScored({bool restartClock = false}) {
    if (restartClock) {
      _remainingSeconds = 20;
      _timeUp = false;
      _gameStarted = true;
      _endedByFail = false;
      _startGameTimer();
    }
    _resetRound(keepScore: true);
    _lastShotOutcome = _ShotOutcome.none;
    _awaitingShotOutcome = false;
  }

  void _awardBonus(int basePoints, {String? reason}) {
    final scaled = (basePoints * _feverScoreScale).round();
    if (scaled <= 0) return;
    _bonusScore += scaled;
    if (reason != null && reason.trim().isNotEmpty) {
      _reactionDetail = _koText(
        '${reason.trim()} +$scaled',
        '${reason.trim()} +$scaled',
      );
    }
  }

  bool get _isKoLocale => Localizations.localeOf(context).languageCode == 'ko';

  void _updateMissionProgress({bool success = false, bool goalScored = false}) {
    var nextProgress = _mission.progress;
    switch (_mission.type) {
      case _MissionType.safePasses:
        if (success && _currentPassRisk == _PassRiskType.safe) {
          nextProgress += 1;
        }
        break;
      case _MissionType.killerPasses:
        if (success && _currentPassRisk == _PassRiskType.killer) {
          nextProgress += 1;
        }
        break;
      case _MissionType.riskyPasses:
        if (success && _currentPassRisk == _PassRiskType.risky) {
          nextProgress += 1;
        }
        break;
      case _MissionType.combo:
        nextProgress = _combo.clamp(0, _mission.target);
        break;
      case _MissionType.goals:
        if (goalScored) {
          nextProgress += 1;
        }
        break;
    }
    if (nextProgress >= _mission.target) {
      _awardBonus(12, reason: _koText('미션 완료', 'Mission complete'));
      _mission = _rollMission();
      _setReaction(_PassResult.missionComplete);
      return;
    }
    _mission = _mission.copyWith(progress: nextProgress);
  }

  void _continueAfterSuccess() {
    _phase = _PlayPhase.ready;
    _ballFlying = false;
    _ballSettling = false;
    _clearFlightGuide();
    _charging = false;
    _chargeStartedAt = null;
    _chargedBallSpeed = _ballMinSpeed;
    _effectiveBallSpeed = _ballMinSpeed;
    final holdPoint = _activePasserBallHoldPoint();
    _ballX = holdPoint.dx;
    _ballY = holdPoint.dy;
    _ballVx = 0;
    _ballVy = 0;
    _flightElapsed = 0;
    _closestReceiverDistance = 999;
    _timingDiffAtClosest = 999;

    _passerVx = _passerVx.abs().clamp(0.06, 0.16);
    _passerVy = 0;
    _receiverVx = _receiverVx.abs().clamp(0.07, 0.17);
    _receiverVy = 0;
    _stopControlledAttacker();

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
    _lastShotOutcome = _ShotOutcome.none;
  }

  void _maybeLevelUp() {
    final expectedLevel = ((_score ~/ _levelUpEveryPasses) + 1).clamp(1, 20);
    if (expectedLevel <= _level) return;
    _level = expectedLevel;
    _syncDefendersForLevel();
    _reactionLabel = _koText('레벨 업! Lv.$_level', 'Level Up! Lv.$_level');
    _reactionDetail = _koText(
      '수비가 더 빨라지고 강해집니다.',
      'Defenders get faster and stronger.',
    );
    _reactionIcon = Icons.trending_up_rounded;
    _reactionColor = const Color(0xFF2F80ED);
  }

  int _defenderCountForCurrentLevel() {
    final bonus = (_level - 1);
    return (_difficulty.defenderCount + bonus)
        .clamp(_difficulty.defenderCount, _difficultyMaxDefenders(_difficulty))
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
    _ballSettling = false;
    _clearFlightGuide();
    _charging = false;
    _chargeStartedAt = null;
    _joystickInput = Offset.zero;
    _joystickActive = false;
    _joystickPointerId = null;
    _passPressed = false;
    _passAimInput = Offset.zero;
    _passAimActive = false;
    _passPointerId = null;
    _passChargeArmed = false;
    _gameStarted = false;
    _endedByFail = true;
    _timeUp = true;
    _finalRanking = _rankingLabel(_rankScore, true);
    _appendRankingRecord();
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
    _passerVx = 0;
    _passerVy = 0;
    _passerSpeedMul = 1.0;
    _receiverX = 0.34;
    _receiverY = 0.46;
    _receiverVx = 0.11;
    _receiverVy = 0;
    _receiverSpeedMul = 1.0;

    _defenders
      ..clear()
      ..addAll(
        _buildDefenders(_difficulty, count: _defenderCountForCurrentLevel()),
      );

    _ballFlying = false;
    _ballSettling = false;
    _clearFlightGuide();
    final holdPoint = _activePasserBallHoldPoint();
    _ballX = holdPoint.dx;
    _ballY = holdPoint.dy;
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
    _currentPassRisk = _PassRiskType.safe;
    _plannedPassOpenSpace = 0;
    _joystickInput = Offset.zero;
    _joystickActive = false;
    _joystickPointerId = null;
    _passPressed = false;
    _passAimInput = Offset.zero;
    _passAimActive = false;
    _passPointerId = null;
    _passChargeArmed = false;
    _awaitingShotOutcome = false;
    _awaitingFailFinish = false;
    _failEndTimer?.cancel();
    _shotOutcomeTimer?.cancel();
    _predReceiverTime = 0;
    _idealBallSpeed = _ballMinSpeed;
    _forwardWindow = false;
    _forwardAlignment = 0;
    _leadAlongMove = 0;
    _lastControlProbability = 0;
    _keeperY = (_goalTopY + _goalBottomY) / 2;
    _keeperVy = _random.nextBool() ? 0.45 : -0.45;
    _fieldScrollX = 0;
    _stopControlledAttacker();
    if (!keepScore) {
      _lastAccuracy = 0;
      _bonusScore = 0;
      _lives = 3;
      _eventSecondsRemaining = 0;
      _activeEvent = _GameEvent.none;
      _feverSecondsRemaining = 0;
      _lastSuccessAt = null;
      _rhythmStreak = 0;
      _lastSuccessfulPassRisk = null;
      _samePassRiskStreak = 0;
      _reactionLabel = '';
      _reactionDetail = '';
      _reactionColor = const Color(0xFF8FA3BF);
      _reactionIcon = Icons.adjust;
      _lastShotOutcome = _ShotOutcome.none;
    }
  }

  void _onJoystickStart(int pointer, Offset local) {
    if (_joystickPointerId != null) return;
    _joystickPointerId = pointer;
    _lastInteractionAt = DateTime.now();
    _updateJoystickFromLocal(local);
  }

  void _onJoystickMove(int pointer, Offset local) {
    if (_joystickPointerId != pointer) return;
    _lastInteractionAt = DateTime.now();
    _updateJoystickFromLocal(local);
  }

  void _onJoystickEnd(int pointer) {
    if (_joystickPointerId != pointer) return;
    _joystickPointerId = null;
    if (!_joystickActive && _joystickInput.distanceSquared <= 0.0001) return;
    setState(() {
      _joystickActive = false;
      _joystickInput = Offset.zero;
    });
  }

  void _updateJoystickFromLocal(Offset local) {
    const center = Offset(44, 44);
    const radius = 34.0;
    final delta = local - center;
    final dist = delta.distance;
    final clamped = dist <= radius ? delta : delta * (radius / dist);
    _joystickInput = Offset(clamped.dx / radius, clamped.dy / radius);
    _joystickActive = true;
  }

  bool _canStartPassGesture() {
    return _gameStarted &&
        !_timeUp &&
        !_awaitingShotOutcome &&
        _phase == _PlayPhase.ready &&
        !_ballFlying;
  }

  void _onPassDown(int pointer, Offset globalPosition) {
    if (_passPointerId != null) return;
    if (!_canStartPassGesture()) {
      return;
    }
    _passPointerId = pointer;
    _lastInteractionAt = DateTime.now();
    _updatePassAimFromGlobal(globalPosition);
    _updateAutoAim();
    _passPressed = true;
    _passChargeArmed = true;
    _beginCharge();
  }

  void _onPassMove(int pointer, Offset globalPosition) {
    if (_passPointerId != pointer) return;
    if (!_passPressed || !_canStartPassGesture()) return;
    _lastInteractionAt = DateTime.now();
    _updatePassAimFromGlobal(globalPosition);
  }

  void _onPassUp(int pointer, [Offset? globalPosition]) {
    if (_passPointerId != pointer) return;
    _passPointerId = null;
    if (globalPosition != null) {
      _lastInteractionAt = DateTime.now();
      _updatePassAimFromGlobal(globalPosition);
    }
    final wasPressed = _passPressed;
    _passPressed = false;
    final wasArmed = _passChargeArmed;
    _passChargeArmed = false;
    if (!wasPressed) return;
    if (!wasArmed || !_canStartPassGesture()) {
      if (_charging) {
        _cancelCharge();
      }
      return;
    }
    // Fallback: if charge state gets dropped by gesture race, still fire.
    if (!_charging) {
      _charging = true;
      _chargedBallSpeed = _ballMinSpeed;
    }
    _playGameSound(
      _goalChanceActive
          ? _GameSoundType.shotRelease
          : _GameSoundType.passRelease,
    );
    _releaseChargeAndPass();
    _passAimInput = Offset.zero;
    _passAimActive = false;
  }

  void _onPassCancel(int pointer) {
    if (_passPointerId != pointer) return;
    _passPointerId = null;
    // iOS can emit cancel during gesture arena conflicts; treat it like release
    // so pass doesn't get dropped.
    _onPassUp(pointer);
  }

  void _updatePassAimFromGlobal(Offset globalPosition) {
    final ctx = _passPadKey.currentContext;
    final obj = ctx?.findRenderObject();
    if (obj is! RenderBox) return;
    final local = obj.globalToLocal(globalPosition);
    _updatePassAimFromLocal(local);
  }

  void _updatePassAimFromLocal(Offset local) {
    const center = Offset(53, 53);
    const radius = 41.0;
    final delta = local - center;
    final dist = delta.distance;
    final clamped = dist <= radius ? delta : delta * (radius / dist);
    _passAimInput = Offset(clamped.dx / radius, clamped.dy / radius);
    _passAimActive = _passAimInput.distanceSquared > 0.0004;
    _updateAutoAim();
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
        along: 0,
        backReach: 0.001,
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
    final anticipationTime = _predReceiverTime.clamp(0.20, 0.95);
    final forwardReach = (0.09 +
            (runnerNorm * 0.02) +
            (speed * anticipationTime * 0.22) +
            (_forwardWindow ? 0.012 : 0.0))
        .clamp(0.09, 0.17);
    final backReach = (0.008 + ((1 - speedNorm) * 0.006)).clamp(0.006, 0.014);
    final lateralReach = (0.070 +
            (runnerNorm * 0.020) +
            (_forwardWindow ? 0.010 : 0.0) -
            (speedNorm * 0.010))
        .clamp(0.055, 0.100);
    final eventScale = _eventReceiveWindowScale;
    final adjustedForwardReach = (forwardReach * eventScale).clamp(0.06, 0.20);
    final adjustedBackReach = (backReach * eventScale).clamp(0.005, 0.025);
    final adjustedLateralReach = (lateralReach * eventScale).clamp(0.045, 0.12);

    final inside = along >= -adjustedBackReach &&
        along <= adjustedForwardReach &&
        lateral <= adjustedLateralReach;
    if (!inside) {
      return _ReceivingWindowEval(
        inside: false,
        fit: 0,
        along: along,
        backReach: adjustedBackReach,
      );
    }

    final alongFit = along >= 0
        ? (1 - ((along / adjustedForwardReach) * 0.70)).clamp(0.0, 1.0)
        : (1 - ((along.abs() / adjustedBackReach) * 0.90)).clamp(0.0, 1.0);
    final lateralFit = (1 - (lateral / adjustedLateralReach)).clamp(0.0, 1.0);
    final fit = (alongFit * 0.45 + lateralFit * 0.55).clamp(0.0, 1.0);

    return _ReceivingWindowEval(
      inside: true,
      fit: fit,
      along: along,
      backReach: adjustedBackReach,
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

  int _setReaction(_PassResult result, {double? controlProbability}) {
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
      case _PassResult.passerHit:
        _reactionIcon = Icons.warning_amber_rounded;
        _reactionColor = const Color(0xFFEB5757);
        _reactionLabel = _koText('패서 충돌', 'Passer hit');
        _reactionDetail = _koText(
          '패스하는 팩맨이 고스트와 충돌해 경기가 종료됐어요.',
          'The passing Pac-Man collided with a ghost and the round ended.',
        );
        return 0;
      case _PassResult.saved:
        _reactionIcon = Icons.sports_handball;
        _reactionColor = const Color(0xFFFF7043);
        _reactionLabel = _koText('골키퍼 선방!', 'Keeper save!');
        _reactionDetail = _koText(
          '골키퍼에게 막혔어요. 빈 공간을 보고 다시 시도하세요.',
          'Shot was saved by the keeper. Find more open space.',
        );
        return 0;
      case _PassResult.shotReady:
        _reactionIcon = Icons.ads_click;
        _reactionColor = const Color(0xFF2F80ED);
        _reactionLabel = _koText('슈팅 찬스 오픈', 'Shot chance open');
        _reactionDetail = _koText(
          '골대 안쪽으로 길게 눌러 슈팅하세요.',
          'Hold and release to shoot into the goal.',
        );
        return 0;
      case _PassResult.goalUnlocked:
        _reactionIcon = Icons.flag_circle;
        _reactionColor = const Color(0xFF2F80ED);
        _reactionLabel = _koText('골대가 나타났어요!', 'Goal is now visible!');
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
        _reactionLabel = _koText('아슬아슬 통과!', 'Near miss!');
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
            ? _koText('빠름(속도)  누르는 시간을 줄이세요', 'Too fast (speed)  hold shorter')
            : leadCause
                ? _koText(
                    '빠름(리드)  목표를 조금 뒤로', 'Too fast (lead)  aim slightly back')
                : _koText('빠름  속도/방향을 함께 조절', 'Too fast  tune speed and aim');
        _reactionDetail = _koText(
          '공이 선수보다 일찍 도착해 안정적인 첫 터치가 어려웠어요.',
          'Ball arrived earlier than runner timing, reducing first-touch control.',
        );
        return 0;
      case _PassResult.tooSlow:
        _reactionIcon = Icons.slow_motion_video;
        _reactionColor = const Color(0xFF4D8BFF);
        _reactionLabel = _koText('느림  더 길게 눌러 속도 증가', 'Too slow  hold longer');
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
        _reactionLabel = _koText('3초 무패스', 'No pass for 3s');
        _reactionDetail = _koText(
          '3초 안에 패스를 시도하지 않아 라운드가 종료됐어요.',
          'Round ended because no pass was attempted within 3 seconds.',
        );
        return 0;
      case _PassResult.retry:
        _reactionIcon = Icons.replay_rounded;
        _reactionColor = const Color(0xFF2F80ED);
        _reactionLabel = _koText('다시 도전!', 'Try again!');
        _reactionDetail = _koText(
          '실수 1회를 사용했어요. 남은 생명으로 다시 이어갑니다.',
          'One life was used. Keep playing with the remaining lives.',
        );
        return 0;
      case _PassResult.missionComplete:
        _reactionIcon = Icons.flag_rounded;
        _reactionColor = const Color(0xFF0FA968);
        _reactionLabel = _koText('미션 완료!', 'Mission complete!');
        _reactionDetail = _koText(
          '보너스 점수를 획득하고 새로운 미션이 시작됩니다.',
          'Bonus score awarded and a new mission has started.',
        );
        return 1;
      case _PassResult.fever:
        _reactionIcon = Icons.local_fire_department;
        _reactionColor = const Color(0xFFFF8A3D);
        _reactionLabel = _koText('피버 타임!', 'Fever time!');
        _reactionDetail = _koText(
          '5초 동안 보너스 점수가 2배로 적용됩니다.',
          'Bonus points are doubled for 5 seconds.',
        );
        return 1;
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
      final spawnY = (laneCenter + ((_random.nextDouble() - 0.5) * 0.08)).clamp(
        minY,
        maxY,
      );
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

  Offset _ballHoldPointFor({
    required double bodyX,
    required double bodyY,
    required double vx,
    required double vy,
  }) {
    final speed = math.sqrt((vx * vx) + (vy * vy));
    final dirX = speed > 0.03 ? (vx / speed) : 1.0;
    final dirY = speed > 0.03 ? (vy / speed) : 0.0;
    const mouthLeadX = 0.036;
    const momentumLead = 0.014;
    final x = (bodyX + mouthLeadX + (dirX * momentumLead)).clamp(
      _fieldMinX,
      _fieldMaxX,
    );
    final y = (bodyY + (dirY * momentumLead * 0.9)).clamp(
      _fieldMinY,
      _fieldMaxY,
    );
    return Offset(x, y);
  }

  Offset _activePasserBallHoldPoint() {
    if (_attackerAIsPasser) {
      return _ballHoldPointFor(
        bodyX: _passerXPos,
        bodyY: _passerYPos,
        vx: _passerVx,
        vy: _passerVy,
      );
    }
    return _ballHoldPointFor(
      bodyX: _receiverX,
      bodyY: _receiverY,
      vx: _receiverVx,
      vy: _receiverVy,
    );
  }

  Offset _activeReceiverBallHoldPoint() {
    if (_attackerAIsPasser) {
      return _ballHoldPointFor(
        bodyX: _receiverX,
        bodyY: _receiverY,
        vx: _receiverVx,
        vy: _receiverVy,
      );
    }
    return _ballHoldPointFor(
      bodyX: _passerXPos,
      bodyY: _passerYPos,
      vx: _passerVx,
      vy: _passerVy,
    );
  }

  void _playGameSound(_GameSoundType type) {
    final systemSound = switch (type) {
      _GameSoundType.passRelease => SystemSoundType.click,
      _GameSoundType.passComplete => SystemSoundType.click,
      _GameSoundType.shotRelease => SystemSoundType.click,
      _GameSoundType.goal => SystemSoundType.alert,
      _GameSoundType.fail => SystemSoundType.alert,
    };
    unawaited(SystemSound.play(systemSound));
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
    if (_defenderPattern == _DefenderPattern.laneClosing) {
      return laneY.clamp(defender.minY, defender.maxY);
    }
    if (_defenderPattern == _DefenderPattern.counterPress) {
      final pressY =
          _ballFlying ? _ballY : ((_activePasserY + _activeReceiverY) * 0.5);
      return pressY.clamp(defender.minY, defender.maxY);
    }
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
        math.sqrt(
              _activeReceiverVx * _activeReceiverVx +
                  _activeReceiverVy * _activeReceiverVy,
            ) *
            (_attackerAIsPasser ? _receiverSpeedMul : _passerSpeedMul),
      );

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

  String _idleHintText(bool isKo) {
    if (_goalChanceActive) {
      return isKo
          ? '힌트: 슈팅 버튼을 길게 눌러 파워를 모은 뒤 골대 빈 공간으로 보내세요.'
          : 'Hint: Hold to charge, then shoot into open goal space.';
    }
    return isKo
        ? '힌트: 3초 안에 패스를 시도하면 흐름을 유지할 수 있어요.'
        : 'Hint: Attempt a pass within 3s to keep the flow.';
  }

  String _bestPointText(bool isKo) {
    if (_goals > 0) {
      return isKo ? '골 결정력이 좋았어요.' : 'Great finishing in front of goal.';
    }
    if (_maxComboInRun >= 5) {
      return isKo ? '연속 패스 리듬이 좋았어요.' : 'Your pass-combo rhythm was strong.';
    }
    if (_level >= 4) {
      return isKo
          ? '압박 상황에서도 레벨을 잘 올렸어요.'
          : 'You handled pressure and leveled up well.';
    }
    return isKo
        ? '기본 연결을 안정적으로 유지했어요.'
        : 'You maintained stable basic link play.';
  }

  String _failureReasonText(bool isKo) {
    switch (_lastFailedReason) {
      case _PassResult.intercepted:
        return isKo
            ? '패스 라인이 수비에게 닫혔어요.'
            : 'The passing lane was closed by defenders.';
      case _PassResult.saved:
        return isKo
            ? '골키퍼 정면으로 슈팅했어요.'
            : 'The shot went into the keeper’s cover.';
      case _PassResult.miss:
        return isKo
            ? '도착 지점이 컨트롤 범위를 벗어났어요.'
            : 'The target landed outside the controllable window.';
      case _PassResult.tooFast:
        return isKo
            ? '공이 선수 타이밍보다 빨랐어요.'
            : 'The ball arrived before the runner timing.';
      case _PassResult.tooSlow:
        return isKo
            ? '공이 늦어 흐름이 끊겼어요.'
            : 'The ball arrived too late and broke the flow.';
      case _PassResult.idleTimeout:
        return isKo
            ? '템포가 멈춰 압박을 허용했어요.'
            : 'Tempo stopped and invited pressure.';
      case _PassResult.passerHit:
        return isKo
            ? '패서 주변 공간을 먼저 확보하지 못했어요.'
            : 'You did not secure space around the passer first.';
      default:
        return isKo
            ? '큰 실패 없이 기본 흐름은 유지했어요.'
            : 'The base flow stayed intact without a major failure.';
    }
  }

  String _improvePointText(bool isKo) {
    switch (_lastFailedReason) {
      case _PassResult.intercepted:
        return isKo
            ? '패스 각도를 조금 더 바깥으로 열어보세요.'
            : 'Open your passing lane a bit wider.';
      case _PassResult.saved:
        return isKo
            ? '슈팅은 골키퍼 반대 공간으로 노려보세요.'
            : 'Aim shots to the keeper’s opposite side.';
      case _PassResult.miss:
        return isKo
            ? '패스/슈팅 파워를 한 단계 낮춰보세요.'
            : 'Use slightly less power on pass/shot.';
      case _PassResult.tooFast:
        return isKo
            ? '패스 버튼 누르는 시간을 조금 줄여보세요.'
            : 'Hold the pass button a bit shorter.';
      case _PassResult.tooSlow:
        return isKo
            ? '패스 버튼을 조금 더 길게 눌러보세요.'
            : 'Hold the pass button a bit longer.';
      case _PassResult.idleTimeout:
        return isKo
            ? '템포 유지를 위해 3초 내 패스를 습관화해보세요.'
            : 'Build a habit of passing within 3 seconds.';
      case _PassResult.passerHit:
        return isKo
            ? '패서와 수비 거리부터 먼저 확보해보세요.'
            : 'Create more space from defenders before passing.';
      default:
        return isKo
            ? '받기 전 짧은 스캔으로 다음 선택을 미리 준비해보세요.'
            : 'Use quick pre-scans before receiving.';
    }
  }

  double _spaceScoreForBand(double minY, double maxY) {
    var score = 0.0;
    for (final defender in _defenders) {
      if (defender.y >= minY && defender.y <= maxY) {
        score += 1.0 / math.max(0.06, defender.x - _activePasserX + 0.12);
      }
    }
    return -score;
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
        return const <_GhostType>[_GhostType.blue, _GhostType.orange];
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
    _weeklyBest =
        widget.optionRepository.getValue<int>('$_weeklyBestPrefix$_weekKey') ??
            0;
    _rankingHistory = _loadRankingHistory();
  }

  void _updateWeeklyBest() {
    if (_score <= _weeklyBest) return;
    _weeklyBest = _score;
    widget.optionRepository.setValue(
      '$_weeklyBestPrefix$_weekKey',
      _weeklyBest,
    );
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
    required _EntityKind kind,
    required String label,
    required double width,
    required double height,
    bool emphasize = false,
    bool markBallOwner = false,
    bool markControllable = false,
  }) {
    final onSurface = Theme.of(context).colorScheme.onSurface;
    final controllablePadding = markControllable ? 14.0 : 0.0;
    final visualSize = size + (controllablePadding * 2);
    return Positioned(
      left: x * width - visualSize / 2,
      top: y * height - visualSize / 2,
      child: Column(
        children: [
          SizedBox(
            width: visualSize,
            height: visualSize,
            child: Stack(
              alignment: Alignment.center,
              children: [
                if (markBallOwner)
                  Container(
                    width: size,
                    height: size,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: const Color(0xFFFFE082),
                        width: 2.4,
                      ),
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0x66FFE082),
                          blurRadius: 8,
                          spreadRadius: 1,
                        ),
                      ],
                    ),
                  ),
                if (markControllable)
                  Container(
                    width: size + 18,
                    height: size + 18,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: const Color(0xFFFF5252),
                        width: 3.0,
                      ),
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0x99FF5252),
                          blurRadius: 16,
                          spreadRadius: 4,
                        ),
                      ],
                    ),
                  ),
                if (markControllable)
                  Container(
                    width: size + 8,
                    height: size + 8,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: const Color(0x36FF5252),
                      border: Border.all(
                        color: const Color(0xFFFF8A80),
                        width: 2.6,
                      ),
                    ),
                  ),
                CustomPaint(
                  size: Size.square(size),
                  painter: switch (kind) {
                    _EntityKind.ball => _BallEntityPainter(
                        color: color,
                        emphasize: emphasize,
                      ),
                    _EntityKind.attacker => _PacmanEntityPainter(
                        color: color,
                        emphasize: emphasize,
                      ),
                    _EntityKind.defender => _GhostEntityPainter(
                        color: color,
                        emphasize: emphasize,
                      ),
                  },
                ),
              ],
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

  void _openGameGuide(BuildContext context) {
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => const GameGuideScreen()));
  }

  void _openRankingScreen(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => GameRankingScreen(entries: _rankingHistory),
      ),
    );
  }

  void _openSkillQuiz(BuildContext context) {
    Navigator.of(context)
        .push(
          MaterialPageRoute(
            builder: (_) =>
                SkillQuizScreen(optionRepository: widget.optionRepository),
          ),
        )
        .then((_) => _refreshPlayGateState());
  }

  bool get _isAndroidGateEnabled => !kIsWeb && Platform.isAndroid;
  int get _allowedGameCount => _trainingNoteCount * _playsPerTrainingNote;
  int get _remainingGameCount =>
      (_allowedGameCount - _playedGameCount).clamp(0, 1 << 30);
  bool get _canStartByGate =>
      !_isAndroidGateEnabled ||
      (_trainingNoteCount > 0 && _quizCompleted && _remainingGameCount > 0);

  Future<void> _refreshPlayGateState() async {
    final entries = await widget.trainingService.allEntries();
    if (!mounted) return;
    final noteCount = entries.where((entry) => !entry.isMatch).length;
    final played =
        widget.optionRepository.getValue<int>(_gamePlayedCountKey) ?? 0;
    final completedAt =
        widget.optionRepository.getValue<String>(_quizCompletedAtKey) ?? '';
    setState(() {
      _trainingNoteCount = noteCount;
      _playedGameCount = played;
      _quizCompleted = completedAt.trim().isNotEmpty;
    });
  }

  Future<void> _tryStartGame() async {
    if (!_isAndroidGateEnabled) {
      _startGame();
      return;
    }
    await _refreshPlayGateState();
    if (!mounted) return;
    final isKo = Localizations.localeOf(context).languageCode == 'ko';
    if (_trainingNoteCount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            isKo
                ? '먼저 훈련 노트를 1개 이상 작성해 주세요.'
                : 'Create at least one training note first.',
          ),
        ),
      );
      return;
    }
    if (!_quizCompleted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            isKo
                ? '먼저 퀴즈를 완료해야 게임을 시작할 수 있어요.'
                : 'Complete the quiz first to start the game.',
          ),
        ),
      );
      return;
    }
    if (_remainingGameCount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            isKo
                ? '남은 게임 횟수가 없습니다. 훈련 노트를 추가하면 5판이 더 열려요.'
                : 'No game attempts left. Add a training note to unlock 5 more games.',
          ),
        ),
      );
      return;
    }
    final nextPlayed = _playedGameCount + 1;
    await widget.optionRepository.setValue(_gamePlayedCountKey, nextPlayed);
    if (!mounted) return;
    setState(() => _playedGameCount = nextPlayed);
    _startGame();
  }

  Widget _buildJoystickControl(BuildContext context) {
    final knobOffset = Offset(_joystickInput.dx * 22, _joystickInput.dy * 22);
    return Positioned(
      left: 12,
      bottom: 12,
      child: Listener(
        onPointerDown: (event) {
          if (!_gameStarted || _timeUp) return;
          setState(() => _onJoystickStart(event.pointer, event.localPosition));
        },
        onPointerMove: (event) {
          if (!_gameStarted || _timeUp) return;
          setState(() => _onJoystickMove(event.pointer, event.localPosition));
        },
        onPointerUp: (event) => _onJoystickEnd(event.pointer),
        onPointerCancel: (event) => _onJoystickEnd(event.pointer),
        child: SizedBox(
          width: 88,
          height: 88,
          child: Stack(
            alignment: Alignment.center,
            children: [
              Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFF1F2A35).withValues(alpha: 0.42),
                  border: Border.all(
                    color: _joystickActive
                        ? const Color(0xFF8FA3B8).withValues(alpha: 0.88)
                        : Colors.white.withValues(alpha: 0.38),
                  ),
                ),
              ),
              Transform.translate(
                offset: knobOffset,
                child: Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: const Color(0xFF9AA7B5).withValues(alpha: 0.72),
                    border: Border.all(
                      color: Colors.black.withValues(alpha: 0.28),
                    ),
                  ),
                  child: const Icon(
                    Icons.sports_esports,
                    size: 16,
                    color: Color(0xFF12202D),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPassButton(BuildContext context, {required bool isKo}) {
    return Positioned(
      right: 10,
      bottom: 12,
      child: Listener(
        key: _passPadKey,
        onPointerDown: (event) => _onPassDown(event.pointer, event.position),
        onPointerMove: (event) => _onPassMove(event.pointer, event.position),
        onPointerUp: (event) => _onPassUp(event.pointer, event.position),
        onPointerCancel: (event) => _onPassCancel(event.pointer),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 90),
          width: 106,
          height: 106,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: _passPressed
                ? const Color(0xFF6F7E8D).withValues(alpha: 0.52)
                : const Color(0xFF8795A4).withValues(alpha: 0.42),
            border: Border.all(color: Colors.white.withValues(alpha: 0.58)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.16),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Center(
            child: Stack(
              alignment: Alignment.center,
              children: [
                Transform.translate(
                  offset: Offset(_passAimInput.dx * 22, _passAimInput.dy * 22),
                  child: Container(
                    width: 36,
                    height: 36,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.black.withValues(alpha: 0.16),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.48),
                      ),
                    ),
                    child: const Icon(
                      Icons.sports_soccer,
                      size: 18,
                      color: Colors.white,
                    ),
                  ),
                ),
                const SizedBox.shrink(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  List<GameRankingEntry> _loadRankingHistory() {
    final raw = widget.optionRepository.getValue<String>(_rankingHistoryKey);
    if (raw == null || raw.isEmpty) return const [];
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) return const [];
      final items = decoded
          .whereType<Map>()
          .map((e) => GameRankingEntry.fromMap(e.cast<String, dynamic>()))
          .whereType<GameRankingEntry>()
          .toList()
        ..sort((a, b) {
          final score = b.rankScore.compareTo(a.rankScore);
          if (score != 0) return score;
          return b.playedAt.compareTo(a.playedAt);
        });
      if (items.length > _maxRankingEntries) {
        items.removeRange(_maxRankingEntries, items.length);
      }
      return items;
    } catch (_) {
      return const [];
    }
  }

  Future<void> _appendRankingRecord() async {
    final previousBest =
        _rankingHistory.isEmpty ? -1 : _rankingHistory.first.rankScore;
    final record = GameRankingEntry(
      playedAt: DateTime.now(),
      score: _score,
      level: _level,
      goals: _goals,
      rankScore: _rankScore,
      rankLabel: _rankingLabel(_rankScore, false),
    );
    final next = [..._rankingHistory, record]..sort((a, b) {
        final score = b.rankScore.compareTo(a.rankScore);
        if (score != 0) return score;
        return b.playedAt.compareTo(a.playedAt);
      });
    if (next.length > _maxRankingEntries) {
      next.removeRange(_maxRankingEntries, next.length);
    }
    _rankingHistory = next;
    await widget.optionRepository.setValue(
      _rankingHistoryKey,
      jsonEncode(_rankingHistory.map((e) => e.toMap()).toList(growable: false)),
    );
    if (!mounted) return;
    final isKo = Localizations.localeOf(context).languageCode == 'ko';
    if (_rankScore > previousBest) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            isKo
                ? '축하합니다! 새로운 최고 랭킹을 달성했어요: ${_rankingLabel(_rankScore, true)} ($_rankScore점)'
                : 'Congrats! New best rank achieved: ${_rankingLabel(_rankScore, false)} ($_rankScore)',
          ),
        ),
      );
    }
  }
}

class _PointerGauge extends StatelessWidget {
  final double ratio;
  final bool isKo;

  const _PointerGauge({required this.ratio, required this.isKo});

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
        color: const Color(0x7A111A27),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: const Color(0xFF4DD0E1).withValues(alpha: 0.70),
        ),
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
              valueColor: const AlwaysStoppedAnimation<Color>(
                Color(0xFF4DD0E1),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PitchInfoBadge extends StatelessWidget {
  final String title;
  final String body;
  final IconData icon;
  final Color? accent;
  final bool alignEnd;

  const _PitchInfoBadge({
    required this.title,
    required this.body,
    required this.icon,
    this.accent,
    this.alignEnd = false,
  });

  @override
  Widget build(BuildContext context) {
    final resolvedAccent = accent ?? const Color(0xFF7DD3FC);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0x70132332),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: resolvedAccent.withValues(alpha: 0.42)),
      ),
      child: Column(
        crossAxisAlignment:
            alignEnd ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 15, color: resolvedAccent),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  title,
                  textAlign: alignEnd ? TextAlign.end : TextAlign.start,
                  style: TextStyle(
                    color: resolvedAccent,
                    fontWeight: FontWeight.w800,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            body,
            textAlign: alignEnd ? TextAlign.end : TextAlign.start,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 11,
              fontWeight: FontWeight.w600,
              height: 1.28,
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
  final double along;
  final double backReach;

  const _ReceivingWindowEval({
    required this.inside,
    required this.fit,
    required this.along,
    required this.backReach,
  });
}

class _MovingPitchPainter extends CustomPainter {
  final double scroll;

  const _MovingPitchPainter({required this.scroll});

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
      Offset(0, topTouchY),
      Offset(size.width, topTouchY),
      linePaint,
    );
    canvas.drawLine(
      Offset(0, bottomTouchY),
      Offset(size.width, bottomTouchY),
      linePaint,
    );
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

  const _BallEntityPainter({required this.color, required this.emphasize});

  @override
  void paint(Canvas canvas, Size size) {
    final radius = size.shortestSide / 2;
    final center = Offset(size.width / 2, size.height / 2);
    final fill = Paint()..color = Color.lerp(Colors.white, color, 0.08)!;
    final border = Paint()
      ..color = emphasize ? const Color(0xFFFFF59D) : const Color(0xE6FFFFFF)
      ..style = PaintingStyle.stroke
      ..strokeWidth = emphasize ? 2.2 : 1.0;
    canvas.drawCircle(center, radius, fill);
    canvas.drawCircle(center, radius - 0.6, border);

    final panel = Paint()
      ..color = const Color(
        0xFF1A1A1A,
      ).withValues(alpha: emphasize ? 0.95 : 0.86)
      ..style = PaintingStyle.fill;
    final seam = Paint()
      ..color = const Color(0xFF1A1A1A).withValues(alpha: 0.55)
      ..style = PaintingStyle.stroke
      ..strokeWidth = radius * 0.08;

    final main = Path();
    final mainR = radius * 0.28;
    for (var i = 0; i < 5; i++) {
      final a = (-math.pi / 2) + ((math.pi * 2 * i) / 5);
      final p = Offset(
        center.dx + (math.cos(a) * mainR),
        center.dy + (math.sin(a) * mainR),
      );
      if (i == 0) {
        main.moveTo(p.dx, p.dy);
      } else {
        main.lineTo(p.dx, p.dy);
      }
    }
    main.close();
    canvas.drawPath(main, panel);

    final panelCenters = <Offset>[
      Offset(center.dx, center.dy - (radius * 0.62)),
      Offset(center.dx + (radius * 0.58), center.dy - (radius * 0.18)),
      Offset(center.dx + (radius * 0.35), center.dy + (radius * 0.52)),
      Offset(center.dx - (radius * 0.35), center.dy + (radius * 0.52)),
      Offset(center.dx - (radius * 0.58), center.dy - (radius * 0.18)),
    ];
    final panelR = radius * 0.16;
    for (final c in panelCenters) {
      canvas.drawCircle(c, panelR, panel);
      canvas.drawLine(center, c, seam);
    }
  }

  @override
  bool shouldRepaint(covariant _BallEntityPainter oldDelegate) {
    return oldDelegate.color != color || oldDelegate.emphasize != emphasize;
  }
}

class _PacmanEntityPainter extends CustomPainter {
  final Color color;
  final bool emphasize;

  const _PacmanEntityPainter({required this.color, required this.emphasize});

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

  const _GhostEntityPainter({required this.color, required this.emphasize});

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
        height: h * 0.21,
      ),
      eyeWhite,
    );
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(w * 0.60, h * 0.50),
        width: w * 0.15,
        height: h * 0.21,
      ),
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
    final backPx = minSize * 0.02;
    final halfWidthPx = minSize * 0.085;

    final rect = Rect.fromLTWH(
      -backPx,
      -halfWidthPx,
      forwardPx + backPx,
      halfWidthPx * 2,
    );
    final zone = RRect.fromRectAndRadius(rect, Radius.circular(halfWidthPx));

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
      Offset(-backPx + 3, 0),
      Offset(forwardPx - 3, 0),
      centerLine,
    );
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

class _SpaceCuePainter extends CustomPainter {
  final bool highlightUpperSide;
  final Offset? pressureDefender;

  const _SpaceCuePainter({
    required this.highlightUpperSide,
    required this.pressureDefender,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final highlightRect = Rect.fromLTWH(
      0,
      highlightUpperSide ? size.height * 0.08 : size.height * 0.56,
      size.width,
      size.height * 0.26,
    );
    final highlightPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.centerLeft,
        end: Alignment.centerRight,
        colors: highlightUpperSide
            ? const [Color(0x1032D74B), Color(0x4D32D74B), Color(0x1032D74B)]
            : const [Color(0x1018A0FB), Color(0x4D18A0FB), Color(0x1018A0FB)],
      ).createShader(highlightRect);
    canvas.drawRRect(
      RRect.fromRectAndRadius(highlightRect, const Radius.circular(22)),
      highlightPaint,
    );

    if (pressureDefender != null) {
      final center = Offset(
        pressureDefender!.dx * size.width,
        pressureDefender!.dy * size.height,
      );
      final pressurePaint = Paint()
        ..shader = const RadialGradient(
          colors: [Color(0x66FF6B6B), Color(0x00FF6B6B)],
        ).createShader(Rect.fromCircle(center: center, radius: 42));
      canvas.drawCircle(center, 42, pressurePaint);
    }
  }

  @override
  bool shouldRepaint(covariant _SpaceCuePainter oldDelegate) {
    return oldDelegate.highlightUpperSide != highlightUpperSide ||
        oldDelegate.pressureDefender != pressureDefender;
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

enum _PlayPhase { ready, flying, roundEnd }

enum _EntityKind { attacker, defender, ball }

enum _GameSoundType { passRelease, passComplete, shotRelease, goal, fail }

enum _ShotOutcome { none, goal, saved, miss }

enum _PassRiskType { safe, killer, risky }

enum _GameEvent { none, narrowLanes, wideLanes, tailWind }

enum _DefenderPattern { laneClosing, receiverTracking, counterPress }

enum _RoundArcStage { read, rhythm, chance }

enum _MissionType { safePasses, killerPasses, riskyPasses, combo, goals }

enum _PassResult {
  perfect,
  intercepted,
  passerHit,
  saved,
  shotReady,
  goalUnlocked,
  goal,
  nearMiss,
  tooFast,
  tooSlow,
  miss,
  idleTimeout,
  retry,
  missionComplete,
  fever,
}

class _MissionState {
  final _MissionType type;
  final int target;
  final int progress;

  const _MissionState({
    required this.type,
    required this.target,
    required this.progress,
  });

  _MissionState copyWith({_MissionType? type, int? target, int? progress}) {
    return _MissionState(
      type: type ?? this.type,
      target: target ?? this.target,
      progress: progress ?? this.progress,
    );
  }
}

enum _AccuracyTier { perfect, great, good, okay, low }

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

enum _GameDifficulty { easy, medium, hard }

enum _GhostType { blue, orange, red, pink }

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
