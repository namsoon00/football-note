import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';

import '../../application/player_profile_service.dart';
import '../../domain/entities/player_profile.dart';
import '../../domain/repositories/option_repository.dart';

class ProfileScreen extends StatefulWidget {
  final OptionRepository optionRepository;

  const ProfileScreen({super.key, required this.optionRepository});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  late final PlayerProfileService _profileService;
  late final TextEditingController _nameController;
  late final TextEditingController _heightController;
  late final TextEditingController _weightController;

  String _photoPath = '';
  String _gender = '';
  String _mbtiResult = '';
  String _positionTestResult = '';
  DateTime? _birthDate;
  DateTime? _soccerStartDate;
  Timer? _saveDebounce;
  bool _saveInProgress = false;
  PlayerProfile? _pendingProfileSave;

  @override
  void initState() {
    super.initState();
    _profileService = PlayerProfileService(widget.optionRepository);
    final profile = _profileService.load();
    _nameController = TextEditingController(text: profile.name);
    _heightController = TextEditingController(
      text: _formatEditableNumber(profile.heightCm),
    );
    _weightController = TextEditingController(
      text: _formatEditableNumber(profile.weightKg),
    );
    _photoPath = profile.photoUrl;
    _gender = profile.gender;
    _mbtiResult = profile.mbtiResult;
    _positionTestResult = profile.positionTestResult;
    _birthDate = profile.birthDate;
    _soccerStartDate = profile.soccerStartDate;
  }

  @override
  void dispose() {
    _saveDebounce?.cancel();
    _pendingProfileSave = _buildCurrentProfile();
    unawaited(_flushQueuedSaves());
    _nameController.dispose();
    _heightController.dispose();
    _weightController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isKo = Localizations.localeOf(context).languageCode == 'ko';
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        await _saveLatestNow();
        if (!context.mounted) return;
        Navigator.of(context).pop(result);
      },
      child: Scaffold(
        appBar: AppBar(title: Text(isKo ? '유저 프로필' : 'Player Profile')),
        body: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Row(
              children: [
                _ProfileAvatar(
                  photoSource: _photoPath,
                  onTap: _pickProfilePhoto,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _nameController.text.trim().isEmpty
                            ? (isKo ? '이름을 입력해 주세요' : 'Enter player name')
                            : _nameController.text.trim(),
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _genderLabel(_gender, isKo),
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
                if (_photoPath.isNotEmpty)
                  IconButton(
                    tooltip: isKo ? '사진 삭제' : 'Remove photo',
                    onPressed: () {
                      setState(() => _photoPath = '');
                      _scheduleAutoSave();
                    },
                    icon: const Icon(Icons.delete_outline),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _nameController,
              decoration: InputDecoration(labelText: isKo ? '이름' : 'Name'),
              onChanged: (_) {
                setState(() {});
                _scheduleAutoSave();
              },
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _heightController,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    inputFormatters: [_decimalInputFormatter],
                    decoration: InputDecoration(
                      labelText: isKo ? '키(cm)' : 'Height (cm)',
                      hintText: '150.5',
                    ),
                    onChanged: (_) => _scheduleAutoSave(),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: TextField(
                    controller: _weightController,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    inputFormatters: [_decimalInputFormatter],
                    decoration: InputDecoration(
                      labelText: isKo ? '몸무게(kg)' : 'Weight (kg)',
                      hintText: '42.5',
                    ),
                    onChanged: (_) => _scheduleAutoSave(),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            DropdownButtonFormField<String>(
              initialValue: _gender.isEmpty ? null : _gender,
              decoration: InputDecoration(labelText: isKo ? '성별' : 'Gender'),
              items: [
                DropdownMenuItem<String>(
                  value: '',
                  child: Text(isKo ? '미입력' : 'Not set'),
                ),
                DropdownMenuItem<String>(
                  value: 'male',
                  child: Text(isKo ? '남성' : 'Male'),
                ),
                DropdownMenuItem<String>(
                  value: 'female',
                  child: Text(isKo ? '여성' : 'Female'),
                ),
                DropdownMenuItem<String>(
                  value: 'other',
                  child: Text(isKo ? '기타' : 'Other'),
                ),
              ],
              onChanged: (value) {
                setState(() => _gender = value ?? '');
                _scheduleAutoSave();
              },
            ),
            const SizedBox(height: 4),
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(isKo ? '생년월일' : 'Birth date'),
              subtitle: Text(_formatDate(_birthDate, isKo)),
              trailing: IconButton(
                icon: const Icon(Icons.event),
                onPressed: () => _pickDate(
                  initial: _birthDate,
                  onPicked: (value) {
                    setState(() => _birthDate = value);
                    _scheduleAutoSave();
                  },
                ),
              ),
            ),
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(isKo ? '축구 시작일' : 'Soccer start date'),
              subtitle: Text(_formatDate(_soccerStartDate, isKo)),
              trailing: IconButton(
                icon: const Icon(Icons.sports_soccer),
                onPressed: () => _pickDate(
                  initial: _soccerStartDate,
                  onPicked: (value) {
                    setState(() => _soccerStartDate = value);
                    _scheduleAutoSave();
                  },
                ),
              ),
            ),
            const SizedBox(height: 12),
            _buildProfileTestSection(isKo),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime? value, bool isKo) {
    if (value == null) return isKo ? '미입력' : 'Not set';
    return DateFormat('yyyy.MM.dd').format(value);
  }

  Future<void> _pickDate({
    required DateTime? initial,
    required ValueChanged<DateTime?> onPicked,
  }) async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: initial ?? DateTime(now.year - 10, now.month, now.day),
      firstDate: DateTime(1950, 1, 1),
      lastDate: DateTime(now.year, now.month, now.day),
    );
    if (picked == null) return;
    onPicked(DateTime(picked.year, picked.month, picked.day));
  }

  void _scheduleAutoSave() {
    _saveDebounce?.cancel();
    _saveDebounce = Timer(
      const Duration(milliseconds: 350),
      () => unawaited(_queueLatestProfileSave()),
    );
  }

  PlayerProfile _buildCurrentProfile() {
    return PlayerProfile(
      name: _nameController.text.trim(),
      photoUrl: _photoPath.trim(),
      birthDate: _birthDate,
      soccerStartDate: _soccerStartDate,
      heightCm: _parseDouble(_heightController.text),
      weightKg: _parseDouble(_weightController.text),
      gender: _gender,
      mbtiResult: _mbtiResult,
      positionTestResult: _positionTestResult,
    );
  }

  Widget _buildProfileTestSection(bool isKo) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          isKo ? '성향 테스트' : 'Profile tests',
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 10),
        _buildTestCard(
          title: isKo ? 'MBTI 테스트' : 'MBTI test',
          description: isKo
              ? '4개 질문으로 훈련 성향을 빠르게 정리합니다.'
              : 'Four questions to capture your training style.',
          result: _mbtiResult,
          emptyLabel: isKo ? '아직 결과가 없습니다.' : 'No result yet.',
          buttonLabel: _mbtiResult.isEmpty
              ? (isKo ? '테스트 시작' : 'Start test')
              : (isKo ? '다시 테스트' : 'Retake'),
          onPressed: () => _runMbtiTest(isKo),
        ),
        const SizedBox(height: 10),
        _buildTestCard(
          title: isKo ? '포지션 테스트' : 'Position test',
          description: isKo
              ? '플레이 선호를 기반으로 어울리는 포지션을 찾습니다.'
              : 'Find a fitting role based on your play preferences.',
          result: _positionTestResult,
          emptyLabel: isKo ? '아직 결과가 없습니다.' : 'No result yet.',
          buttonLabel: _positionTestResult.isEmpty
              ? (isKo ? '테스트 시작' : 'Start test')
              : (isKo ? '다시 테스트' : 'Retake'),
          onPressed: () => _runPositionTest(isKo),
        ),
      ],
    );
  }

  Widget _buildTestCard({
    required String title,
    required String description,
    required String result,
    required String emptyLabel,
    required String buttonLabel,
    required VoidCallback onPressed,
  }) {
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: Theme.of(
                context,
              ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 4),
            Text(description, style: Theme.of(context).textTheme.bodyMedium),
            const SizedBox(height: 10),
            if (result.trim().isEmpty)
              Text(emptyLabel, style: Theme.of(context).textTheme.bodySmall)
            else
              Chip(
                avatar: const Icon(Icons.psychology_alt_outlined, size: 18),
                label: Text(result),
              ),
            const SizedBox(height: 10),
            Align(
              alignment: Alignment.centerRight,
              child: FilledButton.tonal(
                onPressed: onPressed,
                child: Text(buttonLabel),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _saveLatestNow() async {
    _saveDebounce?.cancel();
    await _queueLatestProfileSave();
  }

  Future<void> _queueLatestProfileSave() async {
    _pendingProfileSave = _buildCurrentProfile();
    await _flushQueuedSaves();
  }

  Future<void> _flushQueuedSaves() async {
    if (_saveInProgress) return;
    _saveInProgress = true;
    try {
      while (true) {
        final profile = _pendingProfileSave;
        if (profile == null) break;
        _pendingProfileSave = null;
        await _profileService.save(profile);
      }
    } catch (_) {
      if (!mounted) return;
      final isKo = Localizations.localeOf(context).languageCode == 'ko';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            isKo
                ? '프로필 저장에 실패했습니다. 사진 크기를 줄여 다시 시도해 주세요.'
                : 'Failed to save profile. Try a smaller image.',
          ),
        ),
      );
    } finally {
      _saveInProgress = false;
    }
  }

  Future<void> _runMbtiTest(bool isKo) async {
    final result = await showDialog<String>(
      context: context,
      builder: (context) {
        final answers = List<int?>.filled(_mbtiQuestions.length, null);
        return StatefulBuilder(
          builder: (context, setDialogState) {
            final isComplete = answers.every((answer) => answer != null);
            return AlertDialog(
              title: Text(isKo ? 'MBTI 테스트' : 'MBTI test'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    for (var i = 0; i < _mbtiQuestions.length; i++) ...[
                      Text(
                        '${i + 1}. ${isKo ? _mbtiQuestions[i].koPrompt : _mbtiQuestions[i].enPrompt}',
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          for (var optionIndex = 0;
                              optionIndex < _mbtiQuestions[i].options.length;
                              optionIndex++)
                            ChoiceChip(
                              label: Text(
                                isKo
                                    ? _mbtiQuestions[i]
                                        .options[optionIndex]
                                        .koLabel
                                    : _mbtiQuestions[i]
                                        .options[optionIndex]
                                        .enLabel,
                              ),
                              selected: answers[i] == optionIndex,
                              onSelected: (_) {
                                setDialogState(() => answers[i] = optionIndex);
                              },
                            ),
                        ],
                      ),
                      if (i != _mbtiQuestions.length - 1)
                        const Divider(height: 20),
                    ],
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text(isKo ? '취소' : 'Cancel'),
                ),
                FilledButton(
                  onPressed: !isComplete
                      ? null
                      : () {
                          Navigator.of(
                            context,
                          ).pop(_buildMbtiResult(answers.cast<int>()));
                        },
                  child: Text(isKo ? '결과 저장' : 'Save result'),
                ),
              ],
            );
          },
        );
      },
    );
    if (result == null || !mounted) return;
    setState(() => _mbtiResult = result);
    await _saveLatestNow();
  }

  Future<void> _runPositionTest(bool isKo) async {
    final result = await showDialog<String>(
      context: context,
      builder: (context) {
        final answers = List<int?>.filled(_positionQuestions.length, null);
        return StatefulBuilder(
          builder: (context, setDialogState) {
            final isComplete = answers.every((answer) => answer != null);
            return AlertDialog(
              title: Text(isKo ? '포지션 테스트' : 'Position test'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    for (var i = 0; i < _positionQuestions.length; i++) ...[
                      Text(
                        '${i + 1}. ${isKo ? _positionQuestions[i].koPrompt : _positionQuestions[i].enPrompt}',
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          for (var optionIndex = 0;
                              optionIndex <
                                  _positionQuestions[i].options.length;
                              optionIndex++)
                            ChoiceChip(
                              label: Text(
                                isKo
                                    ? _positionQuestions[i]
                                        .options[optionIndex]
                                        .koLabel
                                    : _positionQuestions[i]
                                        .options[optionIndex]
                                        .enLabel,
                              ),
                              selected: answers[i] == optionIndex,
                              onSelected: (_) {
                                setDialogState(() => answers[i] = optionIndex);
                              },
                            ),
                        ],
                      ),
                      if (i != _positionQuestions.length - 1)
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 16),
                          child: Divider(height: 1),
                        ),
                    ],
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text(isKo ? '취소' : 'Cancel'),
                ),
                FilledButton(
                  onPressed: !isComplete
                      ? null
                      : () {
                          Navigator.of(context).pop(
                            _buildPositionResult(answers.cast<int>(), isKo),
                          );
                        },
                  child: Text(isKo ? '결과 저장' : 'Save result'),
                ),
              ],
            );
          },
        );
      },
    );
    if (result == null || !mounted) return;
    setState(() => _positionTestResult = result);
    await _saveLatestNow();
  }

  String _buildMbtiResult(List<int> answers) {
    final buffer = StringBuffer();
    for (var i = 0; i < answers.length; i++) {
      buffer.write(_mbtiQuestions[i].options[answers[i]].letter);
    }
    return buffer.toString();
  }

  String _buildPositionResult(List<int> answers, bool isKo) {
    final scores = <String, int>{'GK': 0, 'DF': 0, 'MF': 0, 'FW': 0};
    for (var i = 0; i < answers.length; i++) {
      final option = _positionQuestions[i].options[answers[i]];
      option.scores.forEach((key, value) {
        scores.update(key, (current) => current + value, ifAbsent: () => value);
      });
    }
    final sorted = scores.entries.toList()
      ..sort((a, b) {
        final scoreCompare = b.value.compareTo(a.value);
        if (scoreCompare != 0) return scoreCompare;
        return a.key.compareTo(b.key);
      });
    final best = sorted.first.key;
    final label = isKo ? _positionLabelKo(best) : _positionLabelEn(best);
    return '$best · $label';
  }

  String _positionLabelKo(String value) {
    return switch (value) {
      'GK' => '골키퍼형',
      'DF' => '수비수형',
      'MF' => '미드필더형',
      'FW' => '공격수형',
      _ => value,
    };
  }

  String _positionLabelEn(String value) {
    return switch (value) {
      'GK' => 'Goalkeeper',
      'DF' => 'Defender',
      'MF' => 'Midfielder',
      'FW' => 'Forward',
      _ => value,
    };
  }

  double? _parseDouble(String raw) {
    final value = raw.trim();
    if (value.isEmpty) return null;
    return double.tryParse(value.replaceAll(',', '.'));
  }

  String _formatEditableNumber(double? value) {
    if (value == null) return '';
    final rounded = value.toStringAsFixed(2);
    return rounded
        .replaceFirst(RegExp(r'0+$'), '')
        .replaceFirst(RegExp(r'\.$'), '');
  }

  String _genderLabel(String value, bool isKo) {
    return switch (value) {
      'male' => isKo ? '남성' : 'Male',
      'female' => isKo ? '여성' : 'Female',
      'other' => isKo ? '기타' : 'Other',
      _ => isKo ? '성별 미입력' : 'Gender not set',
    };
  }

  static final TextInputFormatter _decimalInputFormatter =
      TextInputFormatter.withFunction((oldValue, newValue) {
    final text = newValue.text;
    if (text.isEmpty) return newValue;
    final normalized = text.replaceAll(',', '.');
    if (!RegExp(r'^\d*(?:\.\d{0,2})?$').hasMatch(normalized)) {
      return oldValue;
    }
    return newValue;
  });

  Future<void> _pickProfilePhoto() async {
    try {
      final picker = ImagePicker();
      final picked = await picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 60,
        maxWidth: 512,
      );
      if (picked == null || !mounted) return;
      if (kIsWeb) {
        // Keep immediate preview even if bytes conversion fails.
        setState(() => _photoPath = picked.path);
        final bytes = await picked.readAsBytes();
        final mime = picked.mimeType ?? 'image/jpeg';
        final dataUrl = 'data:$mime;base64,${base64Encode(bytes)}';
        if (!mounted) return;
        setState(() => _photoPath = dataUrl);
        _scheduleAutoSave();
        return;
      }
      setState(() => _photoPath = picked.path);
      _scheduleAutoSave();
    } catch (_) {
      if (!mounted) return;
      final isKo = Localizations.localeOf(context).languageCode == 'ko';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            isKo
                ? '이미지를 불러오지 못했습니다. 다른 사진으로 다시 시도해 주세요.'
                : 'Could not load image. Please try another photo.',
          ),
        ),
      );
    }
  }
}

class _MbtiQuestion {
  final String koPrompt;
  final String enPrompt;
  final List<_MbtiOption> options;

  const _MbtiQuestion({
    required this.koPrompt,
    required this.enPrompt,
    required this.options,
  });
}

class _MbtiOption {
  final String letter;
  final String koLabel;
  final String enLabel;

  const _MbtiOption({
    required this.letter,
    required this.koLabel,
    required this.enLabel,
  });
}

class _PositionQuestion {
  final String koPrompt;
  final String enPrompt;
  final List<_PositionOption> options;

  const _PositionQuestion({
    required this.koPrompt,
    required this.enPrompt,
    required this.options,
  });
}

class _PositionOption {
  final String koLabel;
  final String enLabel;
  final Map<String, int> scores;

  const _PositionOption({
    required this.koLabel,
    required this.enLabel,
    required this.scores,
  });
}

const List<_MbtiQuestion> _mbtiQuestions = [
  _MbtiQuestion(
    koPrompt: '훈련을 시작하기 전, 에너지를 채우는 방식은 무엇에 가깝나요?',
    enPrompt: 'Before training, how do you recharge your energy?',
    options: [
      _MbtiOption(
        letter: 'E',
        koLabel: '팀원과 바로 이야기하며 분위기를 끌어올린다',
        enLabel: 'I talk with teammates and raise the energy.',
      ),
      _MbtiOption(
        letter: 'I',
        koLabel: '혼자 루틴을 정리하며 집중을 만든다',
        enLabel: 'I settle into focus through a solo routine.',
      ),
    ],
  ),
  _MbtiQuestion(
    koPrompt: '전술 설명을 들을 때 더 먼저 잡히는 것은 무엇인가요?',
    enPrompt: 'When hearing tactics, what do you lock onto first?',
    options: [
      _MbtiOption(
        letter: 'S',
        koLabel: '구체적인 위치, 타이밍, 동작 순서',
        enLabel: 'Specific positions, timing, and sequence.',
      ),
      _MbtiOption(
        letter: 'N',
        koLabel: '전체 흐름과 다음 장면의 가능성',
        enLabel: 'The bigger flow and the next possibility.',
      ),
    ],
  ),
  _MbtiQuestion(
    koPrompt: '경기 중 판단이 필요할 때 더 크게 작동하는 기준은 무엇인가요?',
    enPrompt: 'In matches, what drives your decisions more strongly?',
    options: [
      _MbtiOption(
        letter: 'T',
        koLabel: '효율, 확률, 전술적인 정답',
        enLabel: 'Efficiency, probability, and tactical correctness.',
      ),
      _MbtiOption(
        letter: 'F',
        koLabel: '팀 분위기, 자신감, 동료의 상태',
        enLabel: 'Team mood, confidence, and teammate condition.',
      ),
    ],
  ),
  _MbtiQuestion(
    koPrompt: '훈련 계획을 대하는 태도는 어느 쪽에 더 가깝나요?',
    enPrompt: 'How do you usually approach your training plan?',
    options: [
      _MbtiOption(
        letter: 'J',
        koLabel: '미리 계획하고 정한 흐름대로 가는 편이다',
        enLabel: 'I prefer a plan and sticking to it.',
      ),
      _MbtiOption(
        letter: 'P',
        koLabel: '현장 컨디션에 따라 유연하게 바꾸는 편이다',
        enLabel: 'I adjust flexibly to the situation.',
      ),
    ],
  ),
];

const List<_PositionQuestion> _positionQuestions = [
  _PositionQuestion(
    koPrompt: '가장 자신 있는 장면은 무엇인가요?',
    enPrompt: 'Which moment feels most natural to you?',
    options: [
      _PositionOption(
        koLabel: '슈팅 마무리',
        enLabel: 'Finishing chances',
        scores: {'FW': 3, 'MF': 1},
      ),
      _PositionOption(
        koLabel: '패스 전개',
        enLabel: 'Building with passes',
        scores: {'MF': 3, 'DF': 1},
      ),
      _PositionOption(
        koLabel: '태클과 커버',
        enLabel: 'Tackles and cover',
        scores: {'DF': 3, 'GK': 1},
      ),
      _PositionOption(
        koLabel: '세이브와 지시',
        enLabel: 'Saves and organizing',
        scores: {'GK': 3, 'DF': 1},
      ),
    ],
  ),
  _PositionQuestion(
    koPrompt: '팀이 밀릴 때 먼저 하고 싶은 역할은 무엇인가요?',
    enPrompt: 'When the team is under pressure, what role do you want first?',
    options: [
      _PositionOption(
        koLabel: '앞에서 한 번에 분위기를 바꾼다',
        enLabel: 'Change the game from the front',
        scores: {'FW': 3},
      ),
      _PositionOption(
        koLabel: '중앙에서 템포를 다시 잡는다',
        enLabel: 'Reset the tempo in midfield',
        scores: {'MF': 3, 'DF': 1},
      ),
      _PositionOption(
        koLabel: '라인을 정리하고 실점을 막는다',
        enLabel: 'Organize the line and stop conceding',
        scores: {'DF': 3, 'GK': 1},
      ),
      _PositionOption(
        koLabel: '뒤에서 전체를 보며 침착하게 조율한다',
        enLabel: 'Calmly direct everyone from the back',
        scores: {'GK': 3, 'DF': 1},
      ),
    ],
  ),
  _PositionQuestion(
    koPrompt: '훈련에서 가장 재미있는 과제는 무엇인가요?',
    enPrompt: 'Which drill do you enjoy most?',
    options: [
      _PositionOption(
        koLabel: '침투와 결정력 훈련',
        enLabel: 'Runs and finishing drills',
        scores: {'FW': 3},
      ),
      _PositionOption(
        koLabel: '좁은 공간 패스 게임',
        enLabel: 'Tight-space passing games',
        scores: {'MF': 3, 'FW': 1},
      ),
      _PositionOption(
        koLabel: '1대1 수비와 대인 마크',
        enLabel: '1v1 defending and marking',
        scores: {'DF': 3},
      ),
      _PositionOption(
        koLabel: '반사신경과 캐칭 훈련',
        enLabel: 'Reaction and catching drills',
        scores: {'GK': 3},
      ),
    ],
  ),
  _PositionQuestion(
    koPrompt: '감독이 한 가지 역할을 맡긴다면 무엇이 가장 편한가요?',
    enPrompt: 'If the coach gives you one clear job, which feels best?',
    options: [
      _PositionOption(
        koLabel: '득점으로 결과를 만든다',
        enLabel: 'Deliver goals',
        scores: {'FW': 3},
      ),
      _PositionOption(
        koLabel: '볼 흐름을 연결한다',
        enLabel: 'Connect the flow of possession',
        scores: {'MF': 3, 'DF': 1},
      ),
      _PositionOption(
        koLabel: '상대 핵심을 지운다',
        enLabel: 'Erase the opponent\'s key threat',
        scores: {'DF': 3},
      ),
      _PositionOption(
        koLabel: '마지막 안전장치가 된다',
        enLabel: 'Be the last line of safety',
        scores: {'GK': 3},
      ),
    ],
  ),
];

class _ProfileAvatar extends StatelessWidget {
  final String photoSource;
  final VoidCallback? onTap;

  const _ProfileAvatar({required this.photoSource, this.onTap});

  @override
  Widget build(BuildContext context) {
    final source = photoSource.trim();
    Widget avatar;
    if (source.isEmpty) {
      avatar = const CircleAvatar(
        radius: 34,
        child: Icon(Icons.person, size: 36),
      );
    } else {
      final provider = _profileImageProvider(source);
      if (provider == null) {
        avatar = const CircleAvatar(
          radius: 34,
          child: Icon(Icons.person, size: 36),
        );
      } else {
        avatar = CircleAvatar(
          radius: 34,
          backgroundImage: provider,
          onBackgroundImageError: (_, __) {},
          child: const SizedBox.shrink(),
        );
      }
    }
    return InkWell(
      borderRadius: BorderRadius.circular(40),
      onTap: onTap,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          avatar,
          Positioned(
            right: -2,
            bottom: -2,
            child: Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary,
                shape: BoxShape.circle,
                border: Border.all(
                  color: Theme.of(context).scaffoldBackgroundColor,
                  width: 2,
                ),
              ),
              child: const Icon(Icons.edit, size: 13, color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  ImageProvider? _profileImageProvider(String source) {
    if (source.startsWith('data:image/')) {
      final comma = source.indexOf(',');
      if (comma > 0) {
        final b64 = source.substring(comma + 1);
        try {
          return MemoryImage(base64Decode(b64));
        } catch (_) {
          return null;
        }
      }
      return null;
    }
    if (source.startsWith('http://') ||
        source.startsWith('https://') ||
        source.startsWith('blob:')) {
      return NetworkImage(source);
    }
    if (kIsWeb) {
      return NetworkImage(source);
    }
    if (!kIsWeb) {
      final file = File(source);
      if (file.existsSync()) {
        return FileImage(file);
      }
    }
    return null;
  }
}
