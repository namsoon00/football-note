import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';

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
  List<int> _mbtiAnswers = const <int>[];
  List<int> _positionTestAnswers = const <int>[];
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
    _mbtiAnswers = List<int>.from(profile.mbtiAnswers);
    _positionTestAnswers = List<int>.from(profile.positionTestAnswers);
    _birthDate = profile.birthDate;
    _soccerStartDate = profile.soccerStartDate;
    if (!kIsWeb) {
      unawaited(_migrateProfilePhotoToPersistentStorage());
    }
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
                    onPressed: () async {
                      await _deleteManagedProfilePhotoIfNeeded();
                      if (!mounted) return;
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
      mbtiAnswers: _mbtiAnswers,
      positionTestAnswers: _positionTestAnswers,
    );
  }

  Widget _buildProfileTestSection(bool isKo) {
    final mbtiSummary = _mbtiResultSummary(_mbtiResult, isKo);
    final positionSummary = _positionResultSummary(_positionTestResult, isKo);
    final mbtiSavedAnswers = _savedMbtiAnswerEntries(isKo);
    final positionSavedAnswers = _savedPositionAnswerEntries(isKo);
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
              ? '20개 문항으로 훈련 성향을 더 세밀하게 정리합니다.'
              : 'Twenty questions to map your training style in more detail.',
          result: mbtiSummary.title,
          resultDetail: mbtiSummary.subtitle,
          emptyLabel: isKo ? '아직 결과가 없습니다.' : 'No result yet.',
          buttonLabel: _mbtiResult.isEmpty
              ? (isKo ? '테스트 시작' : 'Start test')
              : (isKo ? '다시 테스트' : 'Retake'),
          savedAnswers: _buildSavedAnswersSection(
            isKo: isKo,
            entries: mbtiSavedAnswers,
          ),
          onPressed: () => _runMbtiTest(isKo),
        ),
        const SizedBox(height: 10),
        _buildTestCard(
          title: isKo ? '포지션 테스트' : 'Position test',
          description: isKo
              ? '20개 문항으로 플레이 선호를 분석해 어울리는 포지션을 찾습니다.'
              : 'Twenty questions analyze your play preferences to suggest a fitting role.',
          result: positionSummary.title,
          resultDetail: positionSummary.subtitle,
          emptyLabel: isKo ? '아직 결과가 없습니다.' : 'No result yet.',
          buttonLabel: _positionTestResult.isEmpty
              ? (isKo ? '테스트 시작' : 'Start test')
              : (isKo ? '다시 테스트' : 'Retake'),
          savedAnswers: _buildSavedAnswersSection(
            isKo: isKo,
            entries: positionSavedAnswers,
          ),
          onPressed: () => _runPositionTest(isKo),
        ),
      ],
    );
  }

  Widget _buildTestCard({
    required String title,
    required String description,
    required String result,
    required String? resultDetail,
    required String emptyLabel,
    required String buttonLabel,
    required Widget? savedAnswers,
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
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Padding(
                      padding: EdgeInsets.only(top: 2),
                      child: Icon(Icons.psychology_alt_outlined, size: 18),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            result,
                            style: Theme.of(context).textTheme.titleSmall
                                ?.copyWith(fontWeight: FontWeight.w700),
                          ),
                          if (resultDetail != null &&
                              resultDetail.isNotEmpty) ...[
                            const SizedBox(height: 2),
                            Text(
                              resultDetail,
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            if (savedAnswers != null) ...[
              const SizedBox(height: 10),
              savedAnswers,
            ],
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
    final result = await showDialog<_CompletedTest>(
      context: context,
      builder: (context) {
        final answers = _restoreAnswers(
          savedAnswers: _mbtiAnswers,
          questionCount: _mbtiQuestions.length,
          optionCountForIndex: (index) => _mbtiQuestions[index].options.length,
        );
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
                          for (
                            var optionIndex = 0;
                            optionIndex < _mbtiQuestions[i].options.length;
                            optionIndex++
                          )
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
                          Navigator.of(context).pop(
                            _CompletedTest(
                              result: _buildMbtiResult(answers.cast<int>()),
                              answers: answers.cast<int>(),
                            ),
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
    setState(() {
      _mbtiResult = result.result;
      _mbtiAnswers = result.answers;
    });
    await _saveLatestNow();
  }

  Future<void> _runPositionTest(bool isKo) async {
    final result = await showDialog<_CompletedTest>(
      context: context,
      builder: (context) {
        final answers = _restoreAnswers(
          savedAnswers: _positionTestAnswers,
          questionCount: _positionQuestions.length,
          optionCountForIndex: (index) =>
              _positionQuestions[index].options.length,
        );
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
                          for (
                            var optionIndex = 0;
                            optionIndex < _positionQuestions[i].options.length;
                            optionIndex++
                          )
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
                            _CompletedTest(
                              result: _buildPositionResult(
                                answers.cast<int>(),
                                isKo,
                              ),
                              answers: answers.cast<int>(),
                            ),
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
    setState(() {
      _positionTestResult = result.result;
      _positionTestAnswers = result.answers;
    });
    await _saveLatestNow();
  }

  List<int?> _restoreAnswers({
    required List<int> savedAnswers,
    required int questionCount,
    required int Function(int index) optionCountForIndex,
  }) {
    return List<int?>.generate(questionCount, (index) {
      if (index >= savedAnswers.length) return null;
      final answer = savedAnswers[index];
      return answer >= 0 && answer < optionCountForIndex(index) ? answer : null;
    });
  }

  List<_SavedAnswerEntry> _savedMbtiAnswerEntries(bool isKo) {
    final entries = <_SavedAnswerEntry>[];
    for (var i = 0; i < _mbtiQuestions.length && i < _mbtiAnswers.length; i++) {
      final answerIndex = _mbtiAnswers[i];
      if (answerIndex < 0 || answerIndex >= _mbtiQuestions[i].options.length) {
        continue;
      }
      final question = _mbtiQuestions[i];
      final option = question.options[answerIndex];
      entries.add(
        _SavedAnswerEntry(
          question: '${i + 1}. ${isKo ? question.koPrompt : question.enPrompt}',
          answer: isKo ? option.koLabel : option.enLabel,
        ),
      );
    }
    return entries;
  }

  List<_SavedAnswerEntry> _savedPositionAnswerEntries(bool isKo) {
    final entries = <_SavedAnswerEntry>[];
    for (
      var i = 0;
      i < _positionQuestions.length && i < _positionTestAnswers.length;
      i++
    ) {
      final answerIndex = _positionTestAnswers[i];
      if (answerIndex < 0 ||
          answerIndex >= _positionQuestions[i].options.length) {
        continue;
      }
      final question = _positionQuestions[i];
      final option = question.options[answerIndex];
      entries.add(
        _SavedAnswerEntry(
          question: '${i + 1}. ${isKo ? question.koPrompt : question.enPrompt}',
          answer: isKo ? option.koLabel : option.enLabel,
        ),
      );
    }
    return entries;
  }

  Widget? _buildSavedAnswersSection({
    required bool isKo,
    required List<_SavedAnswerEntry> entries,
  }) {
    if (entries.isEmpty) return null;
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.2),
        ),
      ),
      child: ExpansionTile(
        tilePadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
        childrenPadding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
        leading: const Icon(Icons.fact_check_outlined, size: 18),
        title: Text(
          isKo
              ? '저장한 응답 ${entries.length}개'
              : 'Saved answers (${entries.length})',
          style: Theme.of(
            context,
          ).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w700),
        ),
        subtitle: Text(
          isKo ? '선택한 항목을 다시 확인할 수 있습니다.' : 'Review the selections you saved.',
          style: Theme.of(context).textTheme.bodySmall,
        ),
        children: [
          for (final entry in entries) ...[
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                entry.question,
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w700),
              ),
            ),
            const SizedBox(height: 4),
            Align(alignment: Alignment.centerLeft, child: Text(entry.answer)),
            if (entry != entries.last) const Divider(height: 20),
          ],
        ],
      ),
    );
  }

  String _buildMbtiResult(List<int> answers) {
    final counts = <String, int>{};
    for (var i = 0; i < answers.length; i++) {
      final letter = _mbtiQuestions[i].options[answers[i]].letter;
      counts.update(letter, (value) => value + 1, ifAbsent: () => 1);
    }
    final result = StringBuffer();
    for (final pair in const [('E', 'I'), ('S', 'N'), ('T', 'F'), ('J', 'P')]) {
      final first = pair.$1;
      final second = pair.$2;
      final firstCount = counts[first] ?? 0;
      final secondCount = counts[second] ?? 0;
      result.write(firstCount >= secondCount ? first : second);
    }
    return result.toString();
  }

  _TestResultSummary _mbtiResultSummary(String raw, bool isKo) {
    final normalized = raw.trim().toUpperCase();
    if (normalized.isEmpty) {
      return const _TestResultSummary(title: '', subtitle: null);
    }
    final codeMatch = RegExp(r'[EINSFTJP]{4}').firstMatch(normalized);
    if (codeMatch == null) {
      return _TestResultSummary(title: raw.trim(), subtitle: null);
    }
    final code = codeMatch.group(0)!;
    final label = _mbtiTypeLabel(code, isKo);
    final description = _mbtiTypeDescription(code, isKo);
    return _TestResultSummary(
      title: label == null ? code : '$code · $label',
      subtitle: description,
    );
  }

  _TestResultSummary _positionResultSummary(String raw, bool isKo) {
    final trimmed = raw.trim();
    if (trimmed.isEmpty) {
      return const _TestResultSummary(title: '', subtitle: null);
    }
    final parts = trimmed.split('·').map((part) => part.trim()).toList();
    if (parts.length >= 2) {
      return _TestResultSummary(title: trimmed, subtitle: null);
    }
    final label = switch (trimmed) {
      'GK' => isKo ? '골키퍼형' : 'Goalkeeper',
      'DF' => isKo ? '수비수형' : 'Defender',
      'MF' => isKo ? '미드필더형' : 'Midfielder',
      'FW' => isKo ? '공격수형' : 'Forward',
      _ => null,
    };
    return _TestResultSummary(
      title: label == null ? trimmed : '$trimmed · $label',
      subtitle: null,
    );
  }

  String? _mbtiTypeLabel(String code, bool isKo) {
    return switch (code) {
      'ISTJ' => isKo ? '원칙 정비형' : 'Organizer',
      'ISFJ' => isKo ? '헌신 지원형' : 'Supporter',
      'INFJ' => isKo ? '통찰 코치형' : 'Insight Coach',
      'INTJ' => isKo ? '전략 설계형' : 'Strategist',
      'ISTP' => isKo ? '실전 해결형' : 'Problem Solver',
      'ISFP' => isKo ? '감각 밸런서형' : 'Balancer',
      'INFP' => isKo ? '가치 몰입형' : 'Idealist',
      'INTP' => isKo ? '분석 탐구형' : 'Analyst',
      'ESTP' => isKo ? '승부 직감형' : 'Playmaker',
      'ESFP' => isKo ? '분위기 점화형' : 'Energizer',
      'ENFP' => isKo ? '영감 확장형' : 'Motivator',
      'ENTP' => isKo ? '변화 실험형' : 'Experimenter',
      'ESTJ' => isKo ? '실행 리더형' : 'Leader',
      'ESFJ' => isKo ? '팀 케어형' : 'Caretaker',
      'ENFJ' => isKo ? '동기 코칭형' : 'Coach',
      'ENTJ' => isKo ? '전술 지휘형' : 'Commander',
      _ => null,
    };
  }

  String? _mbtiTypeDescription(String code, bool isKo) {
    return switch (code) {
      'ISTJ' =>
        isKo
            ? '루틴과 기준을 지키며 안정적으로 훈련을 쌓는 성향입니다.'
            : 'Builds training consistency through routines and clear standards.',
      'ISFJ' =>
        isKo
            ? '팀을 세심하게 챙기며 맡은 역할을 꾸준히 수행하는 성향입니다.'
            : 'Supports the team carefully and executes responsibilities consistently.',
      'INFJ' =>
        isKo
            ? '흐름을 읽고 팀에 필요한 방향을 조용히 제시하는 성향입니다.'
            : 'Reads the flow and quietly suggests the direction the team needs.',
      'INTJ' =>
        isKo
            ? '장기 그림과 전술 구조를 먼저 설계하는 성향입니다.'
            : 'Prefers designing long-term plans and tactical structure first.',
      'ISTP' =>
        isKo
            ? '실전 상황에서 빠르게 판단하고 해결책을 찾는 성향입니다.'
            : 'Adapts quickly in real situations and finds practical solutions.',
      'ISFP' =>
        isKo
            ? '몸 상태와 리듬을 살피며 균형 있게 플레이하는 성향입니다.'
            : 'Plays with balance by tracking body condition and rhythm.',
      'INFP' =>
        isKo
            ? '자신의 기준과 의미를 느낄 때 몰입도가 커지는 성향입니다.'
            : 'Engages deeply when training aligns with personal values and meaning.',
      'INTP' =>
        isKo
            ? '패턴을 분석하고 새로운 해법을 탐색하는 성향입니다.'
            : 'Enjoys analyzing patterns and exploring new solutions.',
      'ESTP' =>
        isKo
            ? '순간 판단과 과감한 실행으로 흐름을 바꾸는 성향입니다.'
            : 'Changes momentum through decisive instincts and bold execution.',
      'ESFP' =>
        isKo
            ? '현장 에너지를 끌어올리고 팀 분위기를 밝히는 성향입니다.'
            : 'Lifts team energy and brightens the environment in the moment.',
      'ENFP' =>
        isKo
            ? '새로운 자극과 가능성에서 동기를 얻는 성향입니다.'
            : 'Finds motivation in new stimuli and emerging possibilities.',
      'ENTP' =>
        isKo
            ? '변화를 두려워하지 않고 다양한 시도를 즐기는 성향입니다.'
            : 'Experiments freely and is comfortable with change.',
      'ESTJ' =>
        isKo
            ? '목표를 분명히 세우고 실행을 끝까지 끌고 가는 성향입니다.'
            : 'Sets clear goals and drives execution through to the end.',
      'ESFJ' =>
        isKo
            ? '팀 컨디션과 호흡을 챙기며 조직력을 높이는 성향입니다.'
            : 'Improves cohesion by caring about team condition and chemistry.',
      'ENFJ' =>
        isKo
            ? '동료를 북돋우며 팀의 집중력을 함께 끌어올리는 성향입니다.'
            : 'Raises team focus by encouraging and aligning teammates.',
      'ENTJ' =>
        isKo
            ? '전술 방향을 정리하고 목표 달성을 주도하는 성향입니다.'
            : 'Clarifies tactical direction and leads the push toward goals.',
      _ => null,
    };
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
      final storedPath = await _storeProfilePhoto(File(picked.path));
      if (!mounted) return;
      setState(() => _photoPath = storedPath);
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

  Future<void> _migrateProfilePhotoToPersistentStorage() async {
    final source = _photoPath.trim();
    if (source.isEmpty || source.startsWith('data:image/')) return;
    final file = File(source);
    if (!file.existsSync()) return;
    if (await _isManagedProfilePhotoPath(source)) return;
    try {
      final storedPath = await _storeProfilePhoto(file);
      if (!mounted) return;
      setState(() => _photoPath = storedPath);
      await _saveLatestNow();
    } catch (_) {
      // Keep the existing path if migration fails.
    }
  }

  Future<String> _storeProfilePhoto(File sourceFile) async {
    final directory = await _profilePhotoDirectory();
    final extension = _normalizedImageExtension(sourceFile.path);
    final destination = File('${directory.path}/profile_photo$extension');
    if (destination.path != sourceFile.path) {
      if (destination.existsSync()) {
        await destination.delete();
      }
      await sourceFile.copy(destination.path);
    }
    await _deleteManagedProfilePhotoIfNeeded(exceptPath: destination.path);
    return destination.path;
  }

  Future<Directory> _profilePhotoDirectory() async {
    final base = await getApplicationSupportDirectory();
    final directory = Directory('${base.path}/profile');
    if (!directory.existsSync()) {
      await directory.create(recursive: true);
    }
    return directory;
  }

  String _normalizedImageExtension(String path) {
    final normalized = path.toLowerCase();
    for (final extension in const ['.png', '.webp', '.gif', '.heic', '.heif']) {
      if (normalized.endsWith(extension)) return extension;
    }
    return '.jpg';
  }

  Future<bool> _isManagedProfilePhotoPath(String path) async {
    final directory = await _profilePhotoDirectory();
    return path.startsWith('${directory.path}/');
  }

  Future<void> _deleteManagedProfilePhotoIfNeeded({
    String? exceptPath,
    String? source,
  }) async {
    if (kIsWeb) return;
    final target = (source ?? _photoPath).trim();
    if (target.isEmpty || target == exceptPath) return;
    if (!await _isManagedProfilePhotoPath(target)) return;
    final file = File(target);
    if (file.existsSync()) {
      await file.delete();
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

class _TestResultSummary {
  final String title;
  final String? subtitle;

  const _TestResultSummary({required this.title, required this.subtitle});
}

class _CompletedTest {
  final String result;
  final List<int> answers;

  const _CompletedTest({required this.result, required this.answers});
}

class _SavedAnswerEntry {
  final String question;
  final String answer;

  const _SavedAnswerEntry({required this.question, required this.answer});
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
    koPrompt: '팀 훈련 전 대기 시간에 더 자연스러운 모습은 무엇인가요?',
    enPrompt: 'During pre-training downtime, what feels most natural?',
    options: [
      _MbtiOption(
        letter: 'E',
        koLabel: '여러 사람과 가볍게 대화하며 몸을 푼다',
        enLabel: 'I loosen up by chatting with several people.',
      ),
      _MbtiOption(
        letter: 'I',
        koLabel: '조용히 스트레칭하며 컨디션을 점검한다',
        enLabel: 'I quietly stretch and check my condition.',
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
    koPrompt: '새로운 훈련 메뉴를 익힐 때 더 믿는 것은 무엇인가요?',
    enPrompt: 'When learning a new drill, what do you trust more?',
    options: [
      _MbtiOption(
        letter: 'S',
        koLabel: '코치가 보여준 정확한 자세와 순서',
        enLabel: 'The exact form and sequence the coach showed.',
      ),
      _MbtiOption(
        letter: 'N',
        koLabel: '이 훈련이 경기에서 연결될 장면',
        enLabel: 'How the drill will connect to match situations.',
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
    koPrompt: '동료의 실수가 나왔을 때 먼저 드는 생각은 무엇인가요?',
    enPrompt: 'When a teammate makes a mistake, what comes first?',
    options: [
      _MbtiOption(
        letter: 'T',
        koLabel: '왜 그런 선택이 나왔는지 원인을 본다',
        enLabel: 'I look for the reason behind the decision.',
      ),
      _MbtiOption(
        letter: 'F',
        koLabel: '동료의 표정과 자신감부터 살핀다',
        enLabel: 'I check the teammate’s emotions and confidence first.',
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
  _MbtiQuestion(
    koPrompt: '경기 준비물과 일정 관리는 보통 어떻게 하나요?',
    enPrompt: 'How do you usually manage match prep and logistics?',
    options: [
      _MbtiOption(
        letter: 'J',
        koLabel: '전날부터 체크리스트로 미리 챙긴다',
        enLabel: 'I prepare early with a checklist.',
      ),
      _MbtiOption(
        letter: 'P',
        koLabel: '당일 흐름에 맞춰 필요한 것을 맞춘다',
        enLabel: 'I sort things out on the day as needed.',
      ),
    ],
  ),
  _MbtiQuestion(
    koPrompt: '훈련이 끝난 뒤 에너지를 회복하는 데 더 도움이 되는 것은 무엇인가요?',
    enPrompt: 'After training, what helps you recover your energy more?',
    options: [
      _MbtiOption(
        letter: 'E',
        koLabel: '팀원과 훈련 이야기를 나누며 정리한다',
        enLabel: 'I debrief by talking through training with teammates.',
      ),
      _MbtiOption(
        letter: 'I',
        koLabel: '혼자 돌아보며 몸과 생각을 정리한다',
        enLabel: 'I recover by reflecting on my own.',
      ),
    ],
  ),
  _MbtiQuestion(
    koPrompt: '상대 분석 자료를 볼 때 더 먼저 눈에 들어오는 것은 무엇인가요?',
    enPrompt: 'When reviewing opponent analysis, what stands out first?',
    options: [
      _MbtiOption(
        letter: 'S',
        koLabel: '반복되는 패턴과 구체적인 움직임',
        enLabel: 'Repeated patterns and concrete movements.',
      ),
      _MbtiOption(
        letter: 'N',
        koLabel: '상대가 노리는 큰 의도와 흐름',
        enLabel: 'The bigger intent and flow behind their play.',
      ),
    ],
  ),
  _MbtiQuestion(
    koPrompt: '주전 경쟁 상황에서 더 중요하게 보는 것은 무엇인가요?',
    enPrompt: 'In competition for a starting spot, what matters more to you?',
    options: [
      _MbtiOption(
        letter: 'T',
        koLabel: '수치와 경기력으로 공정하게 증명하는 것',
        enLabel: 'Proving it fairly through performance and numbers.',
      ),
      _MbtiOption(
        letter: 'F',
        koLabel: '팀 안에서 신뢰를 만들고 유지하는 것',
        enLabel: 'Building and keeping trust within the team.',
      ),
    ],
  ),
  _MbtiQuestion(
    koPrompt: '예상과 다른 변수가 생기면 어떤 편인가요?',
    enPrompt:
        'When an unexpected variable appears, which sounds more like you?',
    options: [
      _MbtiOption(
        letter: 'J',
        koLabel: '빠르게 기준을 다시 세우고 정리한다',
        enLabel: 'I quickly reset the structure and plan.',
      ),
      _MbtiOption(
        letter: 'P',
        koLabel: '상황을 보며 가장 자연스러운 선택을 찾는다',
        enLabel: 'I read the moment and find the most natural response.',
      ),
    ],
  ),
  _MbtiQuestion(
    koPrompt: '팀 미팅에서 의견을 낼 때 더 편한 방식은 무엇인가요?',
    enPrompt: 'When speaking in a team meeting, what feels easier?',
    options: [
      _MbtiOption(
        letter: 'E',
        koLabel: '생각이 들면 바로 말하며 다듬는다',
        enLabel: 'I refine my thoughts by speaking them out.',
      ),
      _MbtiOption(
        letter: 'I',
        koLabel: '생각을 정리한 뒤 핵심만 말한다',
        enLabel: 'I organize my thoughts first, then speak briefly.',
      ),
    ],
  ),
  _MbtiQuestion(
    koPrompt: '실전 감각을 높이기 위해 더 중요한 것은 무엇인가요?',
    enPrompt: 'To sharpen match sense, what feels more important?',
    options: [
      _MbtiOption(
        letter: 'S',
        koLabel: '반복 훈련으로 몸에 익힌 디테일',
        enLabel: 'Details ingrained through repetition.',
      ),
      _MbtiOption(
        letter: 'N',
        koLabel: '상황별로 떠오르는 아이디어와 응용',
        enLabel: 'Ideas and adaptations that appear in the moment.',
      ),
    ],
  ),
  _MbtiQuestion(
    koPrompt: '경기 후 피드백을 받을 때 더 선호하는 것은 무엇인가요?',
    enPrompt: 'What kind of post-match feedback do you prefer more?',
    options: [
      _MbtiOption(
        letter: 'T',
        koLabel: '명확한 기준과 개선 포인트',
        enLabel: 'Clear standards and improvement points.',
      ),
      _MbtiOption(
        letter: 'F',
        koLabel: '강점과 함께 동기부여가 되는 피드백',
        enLabel: 'Encouraging feedback that also notes strengths.',
      ),
    ],
  ),
  _MbtiQuestion(
    koPrompt: '주간 개인 훈련은 어떤 방식이 더 잘 맞나요?',
    enPrompt: 'Which approach fits your weekly individual training better?',
    options: [
      _MbtiOption(
        letter: 'J',
        koLabel: '요일별 목표를 정해 꾸준히 진행한다',
        enLabel: 'I set targets by day and stick to them.',
      ),
      _MbtiOption(
        letter: 'P',
        koLabel: '몸 상태에 따라 메뉴를 유연하게 조정한다',
        enLabel: 'I adjust the menu based on how I feel.',
      ),
    ],
  ),
  _MbtiQuestion(
    koPrompt: '새 팀에 합류했을 때 더 먼저 하는 행동은 무엇인가요?',
    enPrompt: 'When joining a new team, what do you do first?',
    options: [
      _MbtiOption(
        letter: 'E',
        koLabel: '먼저 말을 걸며 관계를 만든다',
        enLabel: 'I start conversations and build connections quickly.',
      ),
      _MbtiOption(
        letter: 'I',
        koLabel: '분위기를 파악하며 천천히 적응한다',
        enLabel: 'I observe the environment and adapt gradually.',
      ),
    ],
  ),
  _MbtiQuestion(
    koPrompt: '코치의 한마디를 기억할 때 더 오래 남는 것은 무엇인가요?',
    enPrompt: 'When remembering a coach’s message, what sticks longer?',
    options: [
      _MbtiOption(
        letter: 'S',
        koLabel: '정확한 단어와 동작 지시',
        enLabel: 'The exact words and action cues.',
      ),
      _MbtiOption(
        letter: 'N',
        koLabel: '그 말이 담고 있는 방향성과 의도',
        enLabel: 'The direction and intent behind the message.',
      ),
    ],
  ),
  _MbtiQuestion(
    koPrompt: '팀 운영에 불만이 생기면 더 먼저 따지는 것은 무엇인가요?',
    enPrompt:
        'If you’re unhappy with team management, what do you examine first?',
    options: [
      _MbtiOption(
        letter: 'T',
        koLabel: '기준이 일관되고 합리적인지',
        enLabel: 'Whether the standards are consistent and rational.',
      ),
      _MbtiOption(
        letter: 'F',
        koLabel: '구성원들이 존중받고 있는지',
        enLabel: 'Whether people feel respected.',
      ),
    ],
  ),
  _MbtiQuestion(
    koPrompt: '원정 경기 준비에서 더 안심되는 방식은 무엇인가요?',
    enPrompt: 'For an away match, which prep style makes you feel safer?',
    options: [
      _MbtiOption(
        letter: 'J',
        koLabel: '이동, 식사, 준비 시간을 미리 계산한다',
        enLabel: 'I map out travel, meals, and prep time in advance.',
      ),
      _MbtiOption(
        letter: 'P',
        koLabel: '변수를 감안해 여유 있게 현장에서 대응한다',
        enLabel: 'I stay loose and handle variables on site.',
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
    koPrompt: '경기 흐름을 바꾸기 위해 가장 먼저 쓰고 싶은 강점은 무엇인가요?',
    enPrompt: 'Which strength would you use first to change a match?',
    options: [
      _PositionOption(
        koLabel: '한 번의 침투와 마무리',
        enLabel: 'One sharp run and finish',
        scores: {'FW': 3, 'MF': 1},
      ),
      _PositionOption(
        koLabel: '패스 선택과 템포 조절',
        enLabel: 'Passing choices and tempo control',
        scores: {'MF': 3, 'DF': 1},
      ),
      _PositionOption(
        koLabel: '차단과 압박 타이밍',
        enLabel: 'Interceptions and pressing timing',
        scores: {'DF': 3, 'MF': 1},
      ),
      _PositionOption(
        koLabel: '세이브와 안정감',
        enLabel: 'Shot-stopping and calmness',
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
    koPrompt: '상대 에이스를 상대해야 할 때 가장 끌리는 임무는 무엇인가요?',
    enPrompt:
        'Against the opponent’s star player, which duty attracts you most?',
    options: [
      _PositionOption(
        koLabel: '앞에서 득점으로 더 큰 위협을 준다',
        enLabel: 'Punish them by scoring at the other end',
        scores: {'FW': 3},
      ),
      _PositionOption(
        koLabel: '중원에서 공 점유를 지배한다',
        enLabel: 'Dominate possession in midfield',
        scores: {'MF': 3, 'DF': 1},
      ),
      _PositionOption(
        koLabel: '직접 막아내며 영향력을 줄인다',
        enLabel: 'Mark them directly and limit their impact',
        scores: {'DF': 3, 'GK': 1},
      ),
      _PositionOption(
        koLabel: '뒤에서 실점 가능성을 지운다',
        enLabel: 'Erase the danger from behind',
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
    koPrompt: '팀 훈련에서 가장 자신 있는 콜은 무엇인가요?',
    enPrompt: 'What kind of on-field communication are you best at?',
    options: [
      _PositionOption(
        koLabel: '침투 타이밍을 맞춰 달라는 콜',
        enLabel: 'Calling for the through-ball timing',
        scores: {'FW': 3, 'MF': 1},
      ),
      _PositionOption(
        koLabel: '패스 각도와 순환을 정리하는 콜',
        enLabel: 'Directing passing lanes and circulation',
        scores: {'MF': 3, 'DF': 1},
      ),
      _PositionOption(
        koLabel: '라인 정렬과 압박 시작 신호',
        enLabel: 'Setting the line and pressing triggers',
        scores: {'DF': 3, 'GK': 1},
      ),
      _PositionOption(
        koLabel: '수비 전체를 뒤에서 조율하는 콜',
        enLabel: 'Organizing the whole defense from behind',
        scores: {'GK': 3, 'DF': 1},
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
  _PositionQuestion(
    koPrompt: '비 오는 날 경기에서 더 기대되는 역할은 무엇인가요?',
    enPrompt: 'In a rainy match, which role sounds most exciting?',
    options: [
      _PositionOption(
        koLabel: '세컨드볼을 노린 마무리',
        enLabel: 'Finishing off second balls',
        scores: {'FW': 3, 'MF': 1},
      ),
      _PositionOption(
        koLabel: '미끄러운 상황에서도 볼을 돌리는 중심',
        enLabel: 'Being the hub who keeps the ball moving',
        scores: {'MF': 3},
      ),
      _PositionOption(
        koLabel: '몸싸움과 커버로 버티는 수비',
        enLabel: 'Physical defending and cover work',
        scores: {'DF': 3, 'GK': 1},
      ),
      _PositionOption(
        koLabel: '불규칙 바운드를 막아내는 선방',
        enLabel: 'Handling awkward bounces with saves',
        scores: {'GK': 3},
      ),
    ],
  ),
  _PositionQuestion(
    koPrompt: '하프라인 근처에서 공을 잡았을 때 가장 먼저 떠오르는 선택은 무엇인가요?',
    enPrompt:
        'When you receive the ball near halfway, what comes to mind first?',
    options: [
      _PositionOption(
        koLabel: '곧바로 공간 뒤를 공략한다',
        enLabel: 'Attack the space behind immediately',
        scores: {'FW': 3, 'MF': 1},
      ),
      _PositionOption(
        koLabel: '가장 좋은 연결 경로를 찾는다',
        enLabel: 'Find the best connection route',
        scores: {'MF': 3, 'DF': 1},
      ),
      _PositionOption(
        koLabel: '위험을 줄이는 안정적인 전개를 택한다',
        enLabel: 'Choose the safer progression',
        scores: {'DF': 3, 'MF': 1},
      ),
      _PositionOption(
        koLabel: '라인 전체 위치부터 빠르게 확인한다',
        enLabel: 'Check the whole line positioning first',
        scores: {'GK': 3, 'DF': 1},
      ),
    ],
  ),
  _PositionQuestion(
    koPrompt: '개인 훈련 시간을 더 쓰고 싶은 기술은 무엇인가요?',
    enPrompt: 'Which skill would you invest extra solo practice into?',
    options: [
      _PositionOption(
        koLabel: '슈팅 각도와 골 결정력',
        enLabel: 'Shooting angles and finishing',
        scores: {'FW': 3},
      ),
      _PositionOption(
        koLabel: '턴과 전진 패스',
        enLabel: 'Turns and progressive passing',
        scores: {'MF': 3, 'FW': 1},
      ),
      _PositionOption(
        koLabel: '수비 스텝과 대인 대응',
        enLabel: 'Defensive footwork and duels',
        scores: {'DF': 3},
      ),
      _PositionOption(
        koLabel: '다이빙과 펀칭',
        enLabel: 'Diving and punching',
        scores: {'GK': 3},
      ),
    ],
  ),
  _PositionQuestion(
    koPrompt: '세트피스 상황에서 가장 빛나고 싶은 방식은 무엇인가요?',
    enPrompt: 'In set-piece situations, how would you most like to shine?',
    options: [
      _PositionOption(
        koLabel: '박스 안에서 마무리한다',
        enLabel: 'Finish in the box',
        scores: {'FW': 3, 'DF': 1},
      ),
      _PositionOption(
        koLabel: '정확한 킥과 세컨드볼 회수',
        enLabel: 'Deliver precise service and collect second balls',
        scores: {'MF': 3, 'FW': 1},
      ),
      _PositionOption(
        koLabel: '제공권과 클리어링으로 막아낸다',
        enLabel: 'Win aerial duels and clear danger',
        scores: {'DF': 3, 'GK': 1},
      ),
      _PositionOption(
        koLabel: '박스 안을 장악하며 지휘한다',
        enLabel: 'Command the box and organize everyone',
        scores: {'GK': 3, 'DF': 1},
      ),
    ],
  ),
  _PositionQuestion(
    koPrompt: '좁은 공간에서 볼을 잃지 않기 위해 가장 믿는 것은 무엇인가요?',
    enPrompt: 'In tight spaces, what do you trust most to keep the ball?',
    options: [
      _PositionOption(
        koLabel: '빠른 터치 뒤 슈팅 기회',
        enLabel: 'Quick touches into a shooting chance',
        scores: {'FW': 3, 'MF': 1},
      ),
      _PositionOption(
        koLabel: '퍼스트 터치와 방향 전환',
        enLabel: 'First touch and body orientation',
        scores: {'MF': 3},
      ),
      _PositionOption(
        koLabel: '몸으로 버티며 탈압박',
        enLabel: 'Shielding and playing out',
        scores: {'DF': 3, 'MF': 1},
      ),
      _PositionOption(
        koLabel: '리스크를 읽고 안전하게 처리',
        enLabel: 'Reading risk and choosing the safe action',
        scores: {'GK': 3, 'DF': 1},
      ),
    ],
  ),
  _PositionQuestion(
    koPrompt: '팀이 리드를 지키는 후반 막판, 가장 맡고 싶은 역할은 무엇인가요?',
    enPrompt:
        'Late in the second half protecting a lead, what role do you want most?',
    options: [
      _PositionOption(
        koLabel: '역습 한 방으로 경기를 끝낸다',
        enLabel: 'End it with one counterattack',
        scores: {'FW': 3},
      ),
      _PositionOption(
        koLabel: '볼을 지키며 흐름을 관리한다',
        enLabel: 'Manage the flow by keeping possession',
        scores: {'MF': 3, 'DF': 1},
      ),
      _PositionOption(
        koLabel: '박스 앞을 지키며 위험을 차단한다',
        enLabel: 'Protect the edge of the box and block danger',
        scores: {'DF': 3, 'GK': 1},
      ),
      _PositionOption(
        koLabel: '마지막 위기를 모두 정리한다',
        enLabel: 'Clean up every final threat',
        scores: {'GK': 3, 'DF': 1},
      ),
    ],
  ),
  _PositionQuestion(
    koPrompt: '벤치에서 경기를 볼 때 가장 먼저 읽히는 구역은 어디인가요?',
    enPrompt: 'When watching from the bench, which area do you read first?',
    options: [
      _PositionOption(
        koLabel: '상대 최종라인 뒤 공간',
        enLabel: 'The space behind the opponent back line',
        scores: {'FW': 3, 'MF': 1},
      ),
      _PositionOption(
        koLabel: '중앙의 수적 우위와 패스 길',
        enLabel: 'Midfield overloads and passing lanes',
        scores: {'MF': 3},
      ),
      _PositionOption(
        koLabel: '수비 간격과 커버 거리',
        enLabel: 'Defensive spacing and cover distances',
        scores: {'DF': 3, 'GK': 1},
      ),
      _PositionOption(
        koLabel: '실점으로 이어질 위험 구역',
        enLabel: 'The zones most likely to lead to conceding',
        scores: {'GK': 3, 'DF': 1},
      ),
    ],
  ),
  _PositionQuestion(
    koPrompt: '가장 칭찬받고 싶은 장면은 무엇인가요?',
    enPrompt: 'Which moment would you most like to be praised for?',
    options: [
      _PositionOption(
        koLabel: '승부를 결정하는 골',
        enLabel: 'A goal that decides the match',
        scores: {'FW': 3},
      ),
      _PositionOption(
        koLabel: '경기를 지배한 플레이메이킹',
        enLabel: 'Playmaking that controlled the game',
        scores: {'MF': 3, 'FW': 1},
      ),
      _PositionOption(
        koLabel: '실점을 막아낸 완벽한 수비',
        enLabel: 'Defending that completely shut danger down',
        scores: {'DF': 3},
      ),
      _PositionOption(
        koLabel: '팀을 살린 결정적 선방',
        enLabel: 'A critical save that kept the team alive',
        scores: {'GK': 3},
      ),
    ],
  ),
  _PositionQuestion(
    koPrompt: '경기 전 몸을 풀 때 가장 집중되는 감각은 무엇인가요?',
    enPrompt: 'During warm-up, which feeling do you dial into most?',
    options: [
      _PositionOption(
        koLabel: '골문 앞 움직임과 타이밍',
        enLabel: 'Movement and timing near goal',
        scores: {'FW': 3},
      ),
      _PositionOption(
        koLabel: '볼 감각과 패스 리듬',
        enLabel: 'Ball feel and passing rhythm',
        scores: {'MF': 3, 'DF': 1},
      ),
      _PositionOption(
        koLabel: '거리 조절과 몸싸움 준비',
        enLabel: 'Distance control and duel readiness',
        scores: {'DF': 3},
      ),
      _PositionOption(
        koLabel: '캐칭과 발밑 안정감',
        enLabel: 'Handling and comfort with the ball at my feet',
        scores: {'GK': 3, 'DF': 1},
      ),
    ],
  ),
  _PositionQuestion(
    koPrompt: '작은 실수를 했을 때 가장 빨리 회복하는 방식은 무엇인가요?',
    enPrompt: 'After a small mistake, how do you reset fastest?',
    options: [
      _PositionOption(
        koLabel: '다음 찬스에서 바로 만회한다',
        enLabel: 'Make up for it with the next chance',
        scores: {'FW': 3},
      ),
      _PositionOption(
        koLabel: '볼을 다시 만지며 흐름을 되찾는다',
        enLabel: 'Touch the ball again and restore rhythm',
        scores: {'MF': 3},
      ),
      _PositionOption(
        koLabel: '기본 위치와 수비 원칙부터 재정렬한다',
        enLabel: 'Reset my position and defensive basics',
        scores: {'DF': 3, 'GK': 1},
      ),
      _PositionOption(
        koLabel: '다음 장면 전체를 읽고 침착해진다',
        enLabel: 'Read the whole next phase and calm things down',
        scores: {'GK': 3, 'DF': 1},
      ),
    ],
  ),
  _PositionQuestion(
    koPrompt: '팀을 위해 가장 희생하기 쉬운 부분은 무엇인가요?',
    enPrompt: 'What are you most willing to sacrifice for the team?',
    options: [
      _PositionOption(
        koLabel: '득점보다 압박과 공간 만들기',
        enLabel: 'Pressing and creating space over scoring',
        scores: {'FW': 3, 'MF': 1},
      ),
      _PositionOption(
        koLabel: '개인 기록보다 연결과 밸런스',
        enLabel: 'Connection and balance over personal stats',
        scores: {'MF': 3, 'DF': 1},
      ),
      _PositionOption(
        koLabel: '화려함보다 몸을 던지는 수비',
        enLabel: 'Throwing my body in rather than seeking flair',
        scores: {'DF': 3},
      ),
      _PositionOption(
        koLabel: '눈에 띄지 않아도 뒤에서 안정감 제공',
        enLabel: 'Providing unseen stability from the back',
        scores: {'GK': 3},
      ),
    ],
  ),
  _PositionQuestion(
    koPrompt: '5대5 미니게임에서 가장 자주 서게 되는 위치는 어디인가요?',
    enPrompt: 'In a 5v5 game, where do you naturally end up most often?',
    options: [
      _PositionOption(
        koLabel: '마지막 마무리 구역',
        enLabel: 'The final finishing zone',
        scores: {'FW': 3},
      ),
      _PositionOption(
        koLabel: '공이 가장 많이 모이는 중앙',
        enLabel: 'The central area where the ball flows most',
        scores: {'MF': 3},
      ),
      _PositionOption(
        koLabel: '상대 진입을 끊는 뒤쪽',
        enLabel: 'The deeper area that cuts off entries',
        scores: {'DF': 3},
      ),
      _PositionOption(
        koLabel: '골문과 수비를 동시에 관리하는 뒤끝',
        enLabel: 'The very back managing both goal and defenders',
        scores: {'GK': 3},
      ),
    ],
  ),
  _PositionQuestion(
    koPrompt: '팀 전술판을 볼 때 가장 먼저 확인하는 기호는 무엇인가요?',
    enPrompt: 'On the tactics board, which marker do you check first?',
    options: [
      _PositionOption(
        koLabel: '내가 파고들 공간과 마무리 지점',
        enLabel: 'My attacking lane and finishing spot',
        scores: {'FW': 3, 'MF': 1},
      ),
      _PositionOption(
        koLabel: '패스 삼각형과 연결선',
        enLabel: 'Passing triangles and connections',
        scores: {'MF': 3},
      ),
      _PositionOption(
        koLabel: '수비 라인과 커버 관계',
        enLabel: 'The back line and cover relationships',
        scores: {'DF': 3, 'GK': 1},
      ),
      _PositionOption(
        koLabel: '상대 침투에 대한 최종 안전선',
        enLabel: 'The final safety line against runs in behind',
        scores: {'GK': 3, 'DF': 1},
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
