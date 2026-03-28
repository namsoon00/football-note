import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';

import '../../application/player_level_service.dart';
import '../../application/player_profile_service.dart';
import '../../domain/entities/player_profile.dart';
import '../../domain/repositories/option_repository.dart';
import '../widgets/player_level_visuals.dart';
import 'player_level_guide_screen.dart';

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
    final levelState = PlayerLevelService(widget.optionRepository).loadState();
    final rewardStatuses = PlayerLevelService(
      widget.optionRepository,
    ).loadRewardStatuses();
    final mbtiSummary = _mbtiResultSummary(_mbtiResult, isKo);
    final positionSummary = _positionResultSummary(_positionTestResult, isKo);
    // ignore: deprecated_member_use
    return WillPopScope(
      onWillPop: () async {
        await _saveLatestNow();
        return true;
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(isKo ? '유저 프로필' : 'Player Profile'),
          actions: [
            IconButton(
              tooltip: isKo ? '성향 테스트' : 'Profile tests',
              onPressed: () => _openProfileTestsScreen(context),
              iconSize: 28,
              constraints: const BoxConstraints(minWidth: 52, minHeight: 52),
              icon: const Icon(Icons.psychology_alt_outlined),
            ),
          ],
        ),
        body: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _ProfileLevelHeroCard(
              levelState: levelState,
              rewardStatuses: rewardStatuses,
              isKo: isKo,
              onTap: _openLevelGuide,
            ),
            const SizedBox(height: 12),
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
                      if (mbtiSummary.title.trim().isNotEmpty ||
                          positionSummary.title.trim().isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            if (mbtiSummary.title.trim().isNotEmpty)
                              _resultChip(
                                label:
                                    '${isKo ? 'MBTI' : 'MBTI'} · ${mbtiSummary.title.trim()}',
                              ),
                            if (positionSummary.title.trim().isNotEmpty)
                              _resultChip(
                                label:
                                    '${isKo ? '포지션' : 'Position'} · ${positionSummary.title.trim()}',
                              ),
                          ],
                        ),
                      ],
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
          ],
        ),
      ),
    );
  }

  Widget _resultChip({required String label}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primaryContainer,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: Theme.of(context).colorScheme.onPrimaryContainer,
              fontWeight: FontWeight.w700,
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
    final saved = _profileService.load();
    return PlayerProfile(
      name: _nameController.text.trim(),
      photoUrl: _photoPath.trim(),
      birthDate: _birthDate,
      soccerStartDate: _soccerStartDate,
      heightCm: _parseDouble(_heightController.text),
      weightKg: _parseDouble(_weightController.text),
      gender: _gender,
      mbtiResult: saved.mbtiResult,
      positionTestResult: saved.positionTestResult,
      mbtiAnswers: saved.mbtiAnswers,
      positionTestAnswers: saved.positionTestAnswers,
    );
  }

  Future<void> _openProfileTestsScreen(BuildContext context) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) =>
            ProfileTestsScreen(optionRepository: widget.optionRepository),
      ),
    );
    if (!mounted) return;
    final saved = _profileService.load();
    setState(() {
      _mbtiResult = saved.mbtiResult;
      _positionTestResult = saved.positionTestResult;
      _mbtiAnswers = List<int>.from(saved.mbtiAnswers);
      _positionTestAnswers = List<int>.from(saved.positionTestAnswers);
    });
  }

  // ignore: unused_element
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
          onPressed: () => _openMbtiTestScreen(isKo),
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
          onPressed: () => _openPositionTestScreen(isKo),
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
                            style: Theme.of(context)
                                .textTheme
                                .titleSmall
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

  Future<void> _openMbtiTestScreen(bool isKo) async {
    final result = await Navigator.of(context).push<_CompletedTest>(
      MaterialPageRoute(
        builder: (_) => _ProfileTestScreen(
          title: isKo ? 'MBTI 테스트' : 'MBTI test',
          description: isKo
              ? '20개 문항으로 훈련 성향을 더 세밀하게 정리합니다.'
              : 'Twenty questions to map your training style in more detail.',
          questions: _mbtiQuestions
              .map(
                (question) => _ProfileTestQuestionData(
                  koPrompt: question.koPrompt,
                  enPrompt: question.enPrompt,
                  options: question.options
                      .map(
                        (option) => _ProfileTestOptionData(
                          koLabel: option.koLabel,
                          enLabel: option.enLabel,
                        ),
                      )
                      .toList(growable: false),
                ),
              )
              .toList(growable: false),
          savedAnswers: _mbtiAnswers,
          buildResult: (answers) => _buildMbtiResult(answers),
        ),
      ),
    );
    if (result == null || !mounted) return;
    setState(() {
      _mbtiResult = result.result;
      _mbtiAnswers = result.answers;
    });
    await _saveLatestNow();
  }

  Future<void> _openPositionTestScreen(bool isKo) async {
    final result = await Navigator.of(context).push<_CompletedTest>(
      MaterialPageRoute(
        builder: (_) => _ProfileTestScreen(
          title: isKo ? '포지션 테스트' : 'Position test',
          description: isKo
              ? '20개 문항으로 플레이 선호를 분석해 어울리는 포지션을 찾습니다.'
              : 'Twenty questions analyze your play preferences to suggest a fitting role.',
          questions: _positionQuestions
              .map(
                (question) => _ProfileTestQuestionData(
                  koPrompt: question.koPrompt,
                  enPrompt: question.enPrompt,
                  options: question.options
                      .map(
                        (option) => _ProfileTestOptionData(
                          koLabel: option.koLabel,
                          enLabel: option.enLabel,
                        ),
                      )
                      .toList(growable: false),
                ),
              )
              .toList(growable: false),
          savedAnswers: _positionTestAnswers,
          buildResult: (answers) => _buildPositionResult(answers, isKo),
        ),
      ),
    );
    if (result == null || !mounted) return;
    setState(() {
      _positionTestResult = result.result;
      _positionTestAnswers = result.answers;
    });
    await _saveLatestNow();
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
    for (var i = 0;
        i < _positionQuestions.length && i < _positionTestAnswers.length;
        i++) {
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
      'ISTJ' => isKo
          ? '루틴과 기준을 지키며 안정적으로 훈련을 쌓는 성향입니다.'
          : 'Builds training consistency through routines and clear standards.',
      'ISFJ' => isKo
          ? '팀을 세심하게 챙기며 맡은 역할을 꾸준히 수행하는 성향입니다.'
          : 'Supports the team carefully and executes responsibilities consistently.',
      'INFJ' => isKo
          ? '흐름을 읽고 팀에 필요한 방향을 조용히 제시하는 성향입니다.'
          : 'Reads the flow and quietly suggests the direction the team needs.',
      'INTJ' => isKo
          ? '장기 그림과 전술 구조를 먼저 설계하는 성향입니다.'
          : 'Prefers designing long-term plans and tactical structure first.',
      'ISTP' => isKo
          ? '실전 상황에서 빠르게 판단하고 해결책을 찾는 성향입니다.'
          : 'Adapts quickly in real situations and finds practical solutions.',
      'ISFP' => isKo
          ? '몸 상태와 리듬을 살피며 균형 있게 플레이하는 성향입니다.'
          : 'Plays with balance by tracking body condition and rhythm.',
      'INFP' => isKo
          ? '자신의 기준과 의미를 느낄 때 몰입도가 커지는 성향입니다.'
          : 'Engages deeply when training aligns with personal values and meaning.',
      'INTP' => isKo
          ? '패턴을 분석하고 새로운 해법을 탐색하는 성향입니다.'
          : 'Enjoys analyzing patterns and exploring new solutions.',
      'ESTP' => isKo
          ? '순간 판단과 과감한 실행으로 흐름을 바꾸는 성향입니다.'
          : 'Changes momentum through decisive instincts and bold execution.',
      'ESFP' => isKo
          ? '현장 에너지를 끌어올리고 팀 분위기를 밝히는 성향입니다.'
          : 'Lifts team energy and brightens the environment in the moment.',
      'ENFP' => isKo
          ? '새로운 자극과 가능성에서 동기를 얻는 성향입니다.'
          : 'Finds motivation in new stimuli and emerging possibilities.',
      'ENTP' => isKo
          ? '변화를 두려워하지 않고 다양한 시도를 즐기는 성향입니다.'
          : 'Experiments freely and is comfortable with change.',
      'ESTJ' => isKo
          ? '목표를 분명히 세우고 실행을 끝까지 끌고 가는 성향입니다.'
          : 'Sets clear goals and drives execution through to the end.',
      'ESFJ' => isKo
          ? '팀 컨디션과 호흡을 챙기며 조직력을 높이는 성향입니다.'
          : 'Improves cohesion by caring about team condition and chemistry.',
      'ENFJ' => isKo
          ? '동료를 북돋우며 팀의 집중력을 함께 끌어올리는 성향입니다.'
          : 'Raises team focus by encouraging and aligning teammates.',
      'ENTJ' => isKo
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

  Future<void> _openLevelGuide() async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => PlayerLevelGuideScreen(
          currentLevel: PlayerLevelService(
            widget.optionRepository,
          ).loadState().level,
          optionRepository: widget.optionRepository,
        ),
      ),
    );
    if (!mounted) return;
    setState(() {});
  }
}

class _ProfileLevelHeroCard extends StatelessWidget {
  final PlayerLevelState levelState;
  final List<PlayerLevelRewardStatus> rewardStatuses;
  final bool isKo;
  final VoidCallback onTap;

  const _ProfileLevelHeroCard({
    required this.levelState,
    required this.rewardStatuses,
    required this.isKo,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final spec = PlayerLevelVisualSpec.fromLevel(levelState.level);
    final claimableRewards = rewardStatuses.where(
      (item) =>
          item.isAvailable &&
          !item.isClaimed &&
          item.customRewardName.trim().isNotEmpty,
    );
    PlayerLevelRewardStatus? nextReward;
    for (final status in rewardStatuses) {
      if (status.customRewardName.trim().isEmpty || status.isClaimed) continue;
      nextReward = status;
      break;
    }
    final rewardSummary = claimableRewards.isNotEmpty
        ? (isKo
            ? '지금 받을 선물 ${claimableRewards.length}개'
            : '${claimableRewards.length} rewards ready')
        : nextReward == null
            ? (isKo ? '다음 선물이 아직 없어요' : 'No next reward yet')
            : nextReward.isAvailable
                ? (isKo
                    ? '지금 선물: ${nextReward.customRewardName}'
                    : 'Reward now: ${nextReward.customRewardName}')
                : (isKo
                    ? '다음 선물 Lv.${nextReward.reward.level} ${nextReward.customRewardName}'
                    : 'Next reward Lv.${nextReward.reward.level} ${nextReward.customRewardName}');

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Ink(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: spec.colors,
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20),
            boxShadow: const [
              BoxShadow(
                color: Color(0x14000000),
                blurRadius: 18,
                offset: Offset(0, 6),
              ),
            ],
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isKo ? '선수 레벨' : 'Player level',
                      style: Theme.of(context).textTheme.labelLarge?.copyWith(
                            color: Colors.white.withValues(alpha: 0.86),
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Lv.${levelState.level} ${PlayerLevelService.levelName(levelState.level, isKo)}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w900,
                          ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      PlayerLevelService.stageName(levelState.level, isKo),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Colors.white.withValues(alpha: 0.9),
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                    const SizedBox(height: 10),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(999),
                      child: LinearProgressIndicator(
                        value: levelState.progress,
                        minHeight: 8,
                        backgroundColor: Colors.white.withValues(alpha: 0.22),
                        valueColor: const AlwaysStoppedAnimation<Color>(
                          Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      isKo
                          ? '다음 ${levelState.xpToNextLevel} XP · 총 ${levelState.totalXp} XP'
                          : '${levelState.xpToNextLevel} XP to next level · ${levelState.totalXp} XP total',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      rewardSummary,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.labelMedium?.copyWith(
                            color: Colors.white.withValues(alpha: 0.94),
                            fontWeight: FontWeight.w800,
                          ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              _ProfileLevelIllustration(isKo: isKo, level: levelState.level),
            ],
          ),
        ),
      ),
    );
  }
}

class _ProfileLevelIllustration extends StatelessWidget {
  final bool isKo;
  final int level;

  const _ProfileLevelIllustration({required this.isKo, required this.level});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 94,
      height: 102,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned(
            right: 2,
            top: 2,
            child: Container(
              width: 70,
              height: 70,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.14),
                shape: BoxShape.circle,
              ),
            ),
          ),
          Positioned(
            right: 8,
            top: 6,
            child: PlayerLevelIllustration(level: level, size: 68),
          ),
          Positioned(
            right: 0,
            bottom: 0,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.18),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.white.withValues(alpha: 0.28)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    PlayerLevelService.illustrationLabel(level, isKo),
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                        ),
                  ),
                  const SizedBox(height: 1),
                  Text(
                    isKo ? '비주얼 성장 단계' : 'Visual growth tier',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: Colors.white.withValues(alpha: 0.82),
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class ProfileTestsScreen extends StatefulWidget {
  final OptionRepository optionRepository;

  const ProfileTestsScreen({super.key, required this.optionRepository});

  @override
  State<ProfileTestsScreen> createState() => _ProfileTestsScreenState();
}

class _ProfileTestsScreenState extends State<ProfileTestsScreen> {
  late final PlayerProfileService _profileService;

  String _mbtiResult = '';
  String _positionTestResult = '';
  List<int> _mbtiAnswers = const <int>[];
  List<int> _positionTestAnswers = const <int>[];

  @override
  void initState() {
    super.initState();
    _profileService = PlayerProfileService(widget.optionRepository);
    final profile = _profileService.load();
    _mbtiResult = profile.mbtiResult;
    _positionTestResult = profile.positionTestResult;
    _mbtiAnswers = List<int>.from(profile.mbtiAnswers);
    _positionTestAnswers = List<int>.from(profile.positionTestAnswers);
  }

  @override
  Widget build(BuildContext context) {
    final isKo = Localizations.localeOf(context).languageCode == 'ko';
    return Scaffold(
      appBar: AppBar(title: Text(isKo ? '성향 테스트' : 'Profile tests')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [_buildProfileTestSection(isKo)],
      ),
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
          isKo ? '테스트 결과와 응답' : 'Results and answers',
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 10),
        SizedBox(
          width: double.infinity,
          child: FilledButton.icon(
            onPressed: () => _startTestsInOrder(isKo),
            icon: const Icon(Icons.play_arrow_rounded),
            label: Text(isKo ? '두 테스트 이어서 하기' : 'Run both tests'),
          ),
        ),
        const SizedBox(height: 10),
        _buildTestCard(
          title: isKo ? 'MBTI 테스트' : 'MBTI test',
          description: isKo
              ? '짧은 질문으로 나와 맞는 훈련 스타일을 찾습니다.'
              : 'Find your training style with short and simple questions.',
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
          onPressed: () => _openMbtiTestScreen(isKo),
        ),
        const SizedBox(height: 10),
        _buildTestCard(
          title: isKo ? '포지션 테스트' : 'Position test',
          description: isKo
              ? '재미있는 선택 문제로 어울리는 포지션을 찾습니다.'
              : 'Fun choices help suggest your best position.',
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
          onPressed: () => _openPositionTestScreen(isKo),
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
                            style: Theme.of(context)
                                .textTheme
                                .titleSmall
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

  Future<void> _openMbtiTestScreen(bool isKo) async {
    final result = await _launchMbtiTest(isKo);
    if (result == null || !mounted) return;
    setState(() {
      _mbtiResult = result.result;
      _mbtiAnswers = result.answers;
    });
    await _saveCurrentProfile();
  }

  Future<void> _openPositionTestScreen(bool isKo) async {
    final result = await _launchPositionTest(isKo);
    if (result == null || !mounted) return;
    setState(() {
      _positionTestResult = result.result;
      _positionTestAnswers = result.answers;
    });
    await _saveCurrentProfile();
  }

  Future<void> _startTestsInOrder(bool isKo) async {
    final mbtiEmpty = _mbtiResult.trim().isEmpty;
    final positionEmpty = _positionTestResult.trim().isEmpty;
    if (mbtiEmpty || (!mbtiEmpty && !positionEmpty)) {
      final mbti = await _launchMbtiTest(isKo);
      if (mbti == null || !mounted) return;
      setState(() {
        _mbtiResult = mbti.result;
        _mbtiAnswers = mbti.answers;
      });
      await _saveCurrentProfile();
      if (!positionEmpty && mbtiEmpty) {
        return;
      }
      final position = await _launchPositionTest(isKo);
      if (position == null || !mounted) return;
      setState(() {
        _positionTestResult = position.result;
        _positionTestAnswers = position.answers;
      });
      await _saveCurrentProfile();
      return;
    }

    final position = await _launchPositionTest(isKo);
    if (position == null || !mounted) return;
    setState(() {
      _positionTestResult = position.result;
      _positionTestAnswers = position.answers;
    });
    await _saveCurrentProfile();
    if (positionEmpty && !mbtiEmpty) {
      return;
    }

    final mbti = await _launchMbtiTest(isKo);
    if (mbti == null || !mounted) return;
    setState(() {
      _mbtiResult = mbti.result;
      _mbtiAnswers = mbti.answers;
    });
    await _saveCurrentProfile();
  }

  Future<_CompletedTest?> _launchMbtiTest(bool isKo) {
    return Navigator.of(context).push<_CompletedTest>(
      MaterialPageRoute(
        builder: (_) => _ProfileTestScreen(
          title: isKo ? 'MBTI 테스트' : 'MBTI test',
          description:
              isKo ? '내 성향을 찾는 간단 테스트예요.' : 'A simple test to find your style.',
          questions: _mbtiQuestions
              .map(
                (question) => _ProfileTestQuestionData(
                  koPrompt: question.koPrompt,
                  enPrompt: question.enPrompt,
                  options: question.options
                      .map(
                        (option) => _ProfileTestOptionData(
                          koLabel: option.koLabel,
                          enLabel: option.enLabel,
                        ),
                      )
                      .toList(growable: false),
                ),
              )
              .toList(growable: false),
          savedAnswers: _mbtiAnswers,
          buildResult: _buildMbtiResult,
        ),
      ),
    );
  }

  Future<_CompletedTest?> _launchPositionTest(bool isKo) {
    return Navigator.of(context).push<_CompletedTest>(
      MaterialPageRoute(
        builder: (_) => _ProfileTestScreen(
          title: isKo ? '포지션 테스트' : 'Position test',
          description: isKo
              ? '내 플레이에 맞는 포지션을 찾는 테스트예요.'
              : 'A simple test to find your best position.',
          questions: _positionQuestions
              .map(
                (question) => _ProfileTestQuestionData(
                  koPrompt: question.koPrompt,
                  enPrompt: question.enPrompt,
                  options: question.options
                      .map(
                        (option) => _ProfileTestOptionData(
                          koLabel: option.koLabel,
                          enLabel: option.enLabel,
                        ),
                      )
                      .toList(growable: false),
                ),
              )
              .toList(growable: false),
          savedAnswers: _positionTestAnswers,
          buildResult: (answers) => _buildPositionResult(answers, isKo),
        ),
      ),
    );
  }

  Future<void> _saveCurrentProfile() async {
    final saved = _profileService.load();
    await _profileService.save(
      saved.copyWith(
        mbtiResult: _mbtiResult,
        positionTestResult: _positionTestResult,
        mbtiAnswers: _mbtiAnswers,
        positionTestAnswers: _positionTestAnswers,
      ),
    );
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
    for (var i = 0;
        i < _positionQuestions.length && i < _positionTestAnswers.length;
        i++) {
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
      'ISTJ' => isKo
          ? '루틴과 기준을 지키며 안정적으로 훈련을 쌓는 성향입니다.'
          : 'Builds training consistency through routines and clear standards.',
      'ISFJ' => isKo
          ? '팀을 세심하게 챙기며 맡은 역할을 꾸준히 수행하는 성향입니다.'
          : 'Supports the team carefully and executes responsibilities consistently.',
      'INFJ' => isKo
          ? '흐름을 읽고 팀에 필요한 방향을 조용히 제시하는 성향입니다.'
          : 'Reads the flow and quietly suggests the direction the team needs.',
      'INTJ' => isKo
          ? '장기 그림과 전술 구조를 먼저 설계하는 성향입니다.'
          : 'Prefers designing long-term plans and tactical structure first.',
      'ISTP' => isKo
          ? '실전 상황에서 빠르게 판단하고 해결책을 찾는 성향입니다.'
          : 'Adapts quickly in real situations and finds practical solutions.',
      'ISFP' => isKo
          ? '몸 상태와 리듬을 살피며 균형 있게 플레이하는 성향입니다.'
          : 'Plays with balance by tracking body condition and rhythm.',
      'INFP' => isKo
          ? '자신의 기준과 의미를 느낄 때 몰입도가 커지는 성향입니다.'
          : 'Engages deeply when training aligns with personal values and meaning.',
      'INTP' => isKo
          ? '패턴을 분석하고 새로운 해법을 탐색하는 성향입니다.'
          : 'Enjoys analyzing patterns and exploring new solutions.',
      'ESTP' => isKo
          ? '순간 판단과 과감한 실행으로 흐름을 바꾸는 성향입니다.'
          : 'Changes momentum through decisive instincts and bold execution.',
      'ESFP' => isKo
          ? '현장 에너지를 끌어올리고 팀 분위기를 밝히는 성향입니다.'
          : 'Lifts team energy and brightens the environment in the moment.',
      'ENFP' => isKo
          ? '새로운 자극과 가능성에서 동기를 얻는 성향입니다.'
          : 'Finds motivation in new stimuli and emerging possibilities.',
      'ENTP' => isKo
          ? '변화를 두려워하지 않고 다양한 시도를 즐기는 성향입니다.'
          : 'Experiments freely and is comfortable with change.',
      'ESTJ' => isKo
          ? '목표를 분명히 세우고 실행을 끝까지 끌고 가는 성향입니다.'
          : 'Sets clear goals and drives execution through to the end.',
      'ESFJ' => isKo
          ? '팀 컨디션과 호흡을 챙기며 조직력을 높이는 성향입니다.'
          : 'Improves cohesion by caring about team condition and chemistry.',
      'ENFJ' => isKo
          ? '동료를 북돋우며 팀의 집중력을 함께 끌어올리는 성향입니다.'
          : 'Raises team focus by encouraging and aligning teammates.',
      'ENTJ' => isKo
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

class _ProfileTestQuestionData {
  final String koPrompt;
  final String enPrompt;
  final List<_ProfileTestOptionData> options;

  const _ProfileTestQuestionData({
    required this.koPrompt,
    required this.enPrompt,
    required this.options,
  });
}

class _ProfileTestOptionData {
  final String koLabel;
  final String enLabel;

  const _ProfileTestOptionData({required this.koLabel, required this.enLabel});
}

class _ProfileTestScreen extends StatefulWidget {
  final String title;
  final String description;
  final List<_ProfileTestQuestionData> questions;
  final List<int> savedAnswers;
  final String Function(List<int>) buildResult;

  const _ProfileTestScreen({
    required this.title,
    required this.description,
    required this.questions,
    required this.savedAnswers,
    required this.buildResult,
  });

  @override
  State<_ProfileTestScreen> createState() => _ProfileTestScreenState();
}

class _ProfileTestScreenState extends State<_ProfileTestScreen> {
  late final List<int?> _answers;
  late final List<int> _questionOrder;
  late final List<List<int>> _optionOrderByQuestion;

  @override
  void initState() {
    super.initState();
    _answers = List<int?>.generate(widget.questions.length, (index) {
      if (index >= widget.savedAnswers.length) return null;
      final saved = widget.savedAnswers[index];
      final optionCount = widget.questions[index].options.length;
      return saved >= 0 && saved < optionCount ? saved : null;
    });
    final random = Random();
    _questionOrder = List<int>.generate(widget.questions.length, (i) => i)
      ..shuffle(random);
    _optionOrderByQuestion = List<List<int>>.generate(widget.questions.length, (
      questionIndex,
    ) {
      final order = List<int>.generate(
        widget.questions[questionIndex].options.length,
        (i) => i,
      );
      order.shuffle(random);
      return order;
    });
  }

  @override
  Widget build(BuildContext context) {
    final isKo = Localizations.localeOf(context).languageCode == 'ko';
    final isComplete = _answers.every((answer) => answer != null);
    return Scaffold(
      appBar: AppBar(title: Text(widget.title)),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        children: [
          Card(
            margin: EdgeInsets.zero,
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.description,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    isKo
                        ? '${widget.questions.length}개를 다 고르면 결과가 저장돼요.'
                        : 'Pick all ${widget.questions.length} to save your result.',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          for (var i = 0; i < widget.questions.length; i++) ...[
            _ProfileTestQuestionCard(
              index: i,
              question: widget.questions[_questionOrder[i]],
              optionOrder: _optionOrderByQuestion[_questionOrder[i]],
              selectedIndex: _answers[_questionOrder[i]],
              isKo: isKo,
              onSelected: (optionIndex) {
                setState(() => _answers[_questionOrder[i]] = optionIndex);
              },
            ),
            if (i != widget.questions.length - 1) const SizedBox(height: 10),
          ],
          const SizedBox(height: 20),
          FilledButton(
            onPressed: !isComplete
                ? null
                : () {
                    final answers = _answers.cast<int>();
                    Navigator.of(context).pop(
                      _CompletedTest(
                        result: widget.buildResult(answers),
                        answers: answers,
                      ),
                    );
                  },
            child: Text(isKo ? '결과 저장' : 'Save result'),
          ),
        ],
      ),
    );
  }
}

class _ProfileTestQuestionCard extends StatelessWidget {
  final int index;
  final _ProfileTestQuestionData question;
  final List<int> optionOrder;
  final int? selectedIndex;
  final bool isKo;
  final ValueChanged<int> onSelected;

  const _ProfileTestQuestionCard({
    required this.index,
    required this.question,
    required this.optionOrder,
    required this.selectedIndex,
    required this.isKo,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${index + 1}. ${isKo ? question.koPrompt : question.enPrompt}',
              style: Theme.of(
                context,
              ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final optionIndex in optionOrder)
                  ChoiceChip(
                    label: Text(
                      isKo
                          ? question.options[optionIndex].koLabel
                          : question.options[optionIndex].enLabel,
                    ),
                    selected: selectedIndex == optionIndex,
                    onSelected: (_) => onSelected(optionIndex),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
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
    koPrompt: '경기 전에 나는?',
    enPrompt: 'Before a game, I usually...',
    options: [
      _MbtiOption(
        letter: 'E',
        koLabel: '친구와 같이 몸을 푼다',
        enLabel: 'Warm up with teammates',
      ),
      _MbtiOption(
        letter: 'I',
        koLabel: '혼자 조용히 준비한다',
        enLabel: 'Prepare quietly alone',
      ),
    ],
  ),
  _MbtiQuestion(
    koPrompt: '코치 설명을 들을 때 나는?',
    enPrompt: 'When coach explains, I focus on...',
    options: [
      _MbtiOption(
        letter: 'S',
        koLabel: '지금 해야 할 동작',
        enLabel: 'Exact moves to do now',
      ),
      _MbtiOption(
        letter: 'N',
        koLabel: '왜 하는지 큰 그림',
        enLabel: 'The big reason behind it',
      ),
    ],
  ),
  _MbtiQuestion(
    koPrompt: '친구가 실수하면 나는?',
    enPrompt: 'If a teammate makes a mistake, I...',
    options: [
      _MbtiOption(
        letter: 'T',
        koLabel: '어떻게 고칠지 먼저 말한다',
        enLabel: 'Talk about how to fix it',
      ),
      _MbtiOption(
        letter: 'F',
        koLabel: '먼저 괜찮다고 말해준다',
        enLabel: 'Encourage first',
      ),
    ],
  ),
  _MbtiQuestion(
    koPrompt: '훈련 계획은?',
    enPrompt: 'My training plan is usually...',
    options: [
      _MbtiOption(letter: 'J', koLabel: '미리 정해서 지킨다', enLabel: 'Planned ahead'),
      _MbtiOption(
        letter: 'P',
        koLabel: '그날 컨디션에 맞춘다',
        enLabel: 'Adjusted on the day',
      ),
    ],
  ),
  _MbtiQuestion(
    koPrompt: '훈련이 끝난 뒤 나는?',
    enPrompt: 'After training, I recharge by...',
    options: [
      _MbtiOption(
        letter: 'E',
        koLabel: '같이 이야기한다',
        enLabel: 'Talking together',
      ),
      _MbtiOption(letter: 'I', koLabel: '혼자 정리한다', enLabel: 'Reflecting alone'),
    ],
  ),
  _MbtiQuestion(
    koPrompt: '경기 영상을 보면 나는?',
    enPrompt: 'When watching game clips, I notice...',
    options: [
      _MbtiOption(
        letter: 'S',
        koLabel: '패스, 위치 같은 디테일',
        enLabel: 'Details like pass and position',
      ),
      _MbtiOption(
        letter: 'N',
        koLabel: '전체 흐름과 다음 장면',
        enLabel: 'Flow and what comes next',
      ),
    ],
  ),
  _MbtiQuestion(
    koPrompt: '빠르게 선택해야 할 때 나는?',
    enPrompt: 'When I must choose fast, I use...',
    options: [
      _MbtiOption(
        letter: 'T',
        koLabel: '가장 좋은 확률',
        enLabel: 'Best probability',
      ),
      _MbtiOption(
        letter: 'F',
        koLabel: '팀 분위기와 자신감',
        enLabel: 'Team feeling and confidence',
      ),
    ],
  ),
  _MbtiQuestion(
    koPrompt: '가방 챙길 때 나는?',
    enPrompt: 'When packing my bag, I...',
    options: [
      _MbtiOption(
        letter: 'J',
        koLabel: '전날 미리 챙긴다',
        enLabel: 'Pack the day before',
      ),
      _MbtiOption(letter: 'P', koLabel: '당일에 챙긴다', enLabel: 'Pack on the day'),
    ],
  ),
  _MbtiQuestion(
    koPrompt: '새 팀에 가면 나는?',
    enPrompt: 'In a new team, I...',
    options: [
      _MbtiOption(
        letter: 'E',
        koLabel: '먼저 인사하고 말 건다',
        enLabel: 'Say hi and start talking',
      ),
      _MbtiOption(
        letter: 'I',
        koLabel: '먼저 보고 천천히 친해진다',
        enLabel: 'Observe first, then open up',
      ),
    ],
  ),
  _MbtiQuestion(
    koPrompt: '새 전술을 배울 때 나는?',
    enPrompt: 'When learning new tactics, I want...',
    options: [
      _MbtiOption(
        letter: 'S',
        koLabel: '한 단계씩 정확하게',
        enLabel: 'Step-by-step details',
      ),
      _MbtiOption(
        letter: 'N',
        koLabel: '어디에 쓰는지 먼저',
        enLabel: 'Where it will be used',
      ),
    ],
  ),
  _MbtiQuestion(
    koPrompt: '피드백을 들을 때 나는?',
    enPrompt: 'For feedback, I prefer...',
    options: [
      _MbtiOption(
        letter: 'T',
        koLabel: '고칠 점을 딱 알려주기',
        enLabel: 'Clear fix points',
      ),
      _MbtiOption(
        letter: 'F',
        koLabel: '잘한 점도 같이 듣기',
        enLabel: 'Strengths with fix points',
      ),
    ],
  ),
  _MbtiQuestion(
    koPrompt: '갑자기 계획이 바뀌면 나는?',
    enPrompt: 'If plans suddenly change, I...',
    options: [
      _MbtiOption(
        letter: 'J',
        koLabel: '다시 정리해서 맞춘다',
        enLabel: 'Re-plan quickly',
      ),
      _MbtiOption(
        letter: 'P',
        koLabel: '그 상황에 맞게 움직인다',
        enLabel: 'Go with the moment',
      ),
    ],
  ),
  _MbtiQuestion(
    koPrompt: '쉬는 시간에 나는?',
    enPrompt: 'During breaks, I usually...',
    options: [
      _MbtiOption(
        letter: 'E',
        koLabel: '친구랑 같이 웃고 이야기한다',
        enLabel: 'Chat and laugh with teammates',
      ),
      _MbtiOption(
        letter: 'I',
        koLabel: '조용히 숨 고르며 쉰다',
        enLabel: 'Rest quietly by myself',
      ),
    ],
  ),
  _MbtiQuestion(
    koPrompt: '훈련을 배울 때 더 쉬운 건?',
    enPrompt: 'What is easier when learning drills?',
    options: [
      _MbtiOption(
        letter: 'S',
        koLabel: '동작을 따라 해보는 것',
        enLabel: 'Copying the movement',
      ),
      _MbtiOption(
        letter: 'N',
        koLabel: '이유를 먼저 듣는 것',
        enLabel: 'Hearing the reason first',
      ),
    ],
  ),
  _MbtiQuestion(
    koPrompt: '승부 순간에 나는?',
    enPrompt: 'In clutch moments, I trust...',
    options: [
      _MbtiOption(
        letter: 'T',
        koLabel: '냉정한 선택',
        enLabel: 'Calm and logical choices',
      ),
      _MbtiOption(
        letter: 'F',
        koLabel: '팀의 기운',
        enLabel: 'Team spirit and feeling',
      ),
    ],
  ),
  _MbtiQuestion(
    koPrompt: '숙제 훈련은 보통?',
    enPrompt: 'For homework practice, I...',
    options: [
      _MbtiOption(
        letter: 'J',
        koLabel: '정해둔 시간에 딱 한다',
        enLabel: 'Do it at fixed time',
      ),
      _MbtiOption(
        letter: 'P',
        koLabel: '가능한 시간에 유연하게 한다',
        enLabel: 'Do it flexibly when I can',
      ),
    ],
  ),
  _MbtiQuestion(
    koPrompt: '새 친구를 만나면 나는?',
    enPrompt: 'When I meet new friends, I...',
    options: [
      _MbtiOption(
        letter: 'E',
        koLabel: '먼저 말을 건다',
        enLabel: 'Start talking first',
      ),
      _MbtiOption(
        letter: 'I',
        koLabel: '조금 보고 나서 말한다',
        enLabel: 'Talk after observing first',
      ),
    ],
  ),
  _MbtiQuestion(
    koPrompt: '전술판을 볼 때 먼저 보는 건?',
    enPrompt: 'On tactics board, I first look at...',
    options: [
      _MbtiOption(
        letter: 'S',
        koLabel: '내 위치와 이동선',
        enLabel: 'My spot and movement line',
      ),
      _MbtiOption(
        letter: 'N',
        koLabel: '전체 흐름과 전략',
        enLabel: 'Overall flow and strategy',
      ),
    ],
  ),
  _MbtiQuestion(
    koPrompt: '친구에게 조언할 때 나는?',
    enPrompt: 'When giving advice, I...',
    options: [
      _MbtiOption(
        letter: 'T',
        koLabel: '바로 고칠 방법을 말한다',
        enLabel: 'Give direct fix tips',
      ),
      _MbtiOption(
        letter: 'F',
        koLabel: '먼저 마음을 다독인다',
        enLabel: 'Comfort first, then guide',
      ),
    ],
  ),
  _MbtiQuestion(
    koPrompt: '경기 날 준비는?',
    enPrompt: 'Game-day preparation is...',
    options: [
      _MbtiOption(
        letter: 'J',
        koLabel: '체크리스트로 준비',
        enLabel: 'Checklist preparation',
      ),
      _MbtiOption(
        letter: 'P',
        koLabel: '상황 보며 바로 준비',
        enLabel: 'Prepare as things happen',
      ),
    ],
  ),
];

const List<_PositionQuestion> _positionQuestions = [
  _PositionQuestion(
    koPrompt: '가장 재미있는 순간은?',
    enPrompt: 'What moment is most fun for you?',
    options: [
      _PositionOption(
        koLabel: '골 넣기',
        enLabel: 'Scoring',
        scores: {'FW': 3, 'MF': 1},
      ),
      _PositionOption(
        koLabel: '패스로 연결하기',
        enLabel: 'Connecting passes',
        scores: {'MF': 3, 'DF': 1},
      ),
      _PositionOption(
        koLabel: '상대 공 뺏기',
        enLabel: 'Winning the ball',
        scores: {'DF': 3, 'GK': 1},
      ),
      _PositionOption(
        koLabel: '골 막기',
        enLabel: 'Making saves',
        scores: {'GK': 3, 'DF': 1},
      ),
    ],
  ),
  _PositionQuestion(
    koPrompt: '팀이 힘들 때 먼저 하고 싶은 일은?',
    enPrompt: 'When team is struggling, what do you do first?',
    options: [
      _PositionOption(
        koLabel: '한 번에 골 기회 만들기',
        enLabel: 'Create a scoring chance',
        scores: {'FW': 3},
      ),
      _PositionOption(
        koLabel: '공을 잡고 리듬 만들기',
        enLabel: 'Hold ball and set rhythm',
        scores: {'MF': 3, 'DF': 1},
      ),
      _PositionOption(
        koLabel: '뒤에서 막아주기',
        enLabel: 'Stop attacks from behind',
        scores: {'DF': 3, 'GK': 1},
      ),
      _PositionOption(
        koLabel: '크게 소리쳐 정리하기',
        enLabel: 'Organize with loud calls',
        scores: {'GK': 3, 'DF': 1},
      ),
    ],
  ),
  _PositionQuestion(
    koPrompt: '개인 훈련에서 제일 하고 싶은 건?',
    enPrompt: 'What do you want to train most?',
    options: [
      _PositionOption(koLabel: '슈팅', enLabel: 'Shooting', scores: {'FW': 3}),
      _PositionOption(
        koLabel: '패스와 턴',
        enLabel: 'Passing and turns',
        scores: {'MF': 3, 'FW': 1},
      ),
      _PositionOption(
        koLabel: '태클과 몸싸움',
        enLabel: 'Tackles and duels',
        scores: {'DF': 3},
      ),
      _PositionOption(
        koLabel: '다이빙과 캐칭',
        enLabel: 'Diving and catching',
        scores: {'GK': 3},
      ),
    ],
  ),
  _PositionQuestion(
    koPrompt: '미니게임에서 자주 가는 자리는?',
    enPrompt: 'Where do you often stand in mini games?',
    options: [
      _PositionOption(
        koLabel: '상대 골문 근처',
        enLabel: 'Near opponent goal',
        scores: {'FW': 3},
      ),
      _PositionOption(
        koLabel: '가운데',
        enLabel: 'Middle area',
        scores: {'MF': 3},
      ),
      _PositionOption(
        koLabel: '우리 진영 뒤쪽',
        enLabel: 'Our back line',
        scores: {'DF': 3},
      ),
      _PositionOption(
        koLabel: '골문 앞',
        enLabel: 'In front of our goal',
        scores: {'GK': 3},
      ),
    ],
  ),
  _PositionQuestion(
    koPrompt: '내 강점은?',
    enPrompt: 'What is your biggest strength?',
    options: [
      _PositionOption(
        koLabel: '빠른 침투',
        enLabel: 'Fast runs',
        scores: {'FW': 3, 'MF': 1},
      ),
      _PositionOption(
        koLabel: '게임 읽기',
        enLabel: 'Reading the game',
        scores: {'MF': 3, 'DF': 1},
      ),
      _PositionOption(
        koLabel: '상대 막기',
        enLabel: 'Stopping opponents',
        scores: {'DF': 3, 'GK': 1},
      ),
      _PositionOption(
        koLabel: '반응 속도',
        enLabel: 'Quick reactions',
        scores: {'GK': 3},
      ),
    ],
  ),
  _PositionQuestion(
    koPrompt: '코치가 한 가지 임무를 주면?',
    enPrompt: 'If coach gives one mission, you choose...',
    options: [
      _PositionOption(
        koLabel: '골로 마무리',
        enLabel: 'Finish with goals',
        scores: {'FW': 3},
      ),
      _PositionOption(
        koLabel: '공을 계속 연결',
        enLabel: 'Keep ball moving',
        scores: {'MF': 3, 'DF': 1},
      ),
      _PositionOption(
        koLabel: '상대 에이스 막기',
        enLabel: 'Mark the star player',
        scores: {'DF': 3},
      ),
      _PositionOption(
        koLabel: '마지막 실점 막기',
        enLabel: 'Protect the final line',
        scores: {'GK': 3},
      ),
    ],
  ),
  _PositionQuestion(
    koPrompt: '비 오는 날 더 자신 있는 건?',
    enPrompt: 'On rainy days, you are most confident in...',
    options: [
      _PositionOption(
        koLabel: '문전 슈팅',
        enLabel: 'Close-range finishes',
        scores: {'FW': 3},
      ),
      _PositionOption(
        koLabel: '짧은 패스 유지',
        enLabel: 'Keeping short passes',
        scores: {'MF': 3},
      ),
      _PositionOption(
        koLabel: '몸으로 막아내기',
        enLabel: 'Physical defending',
        scores: {'DF': 3},
      ),
      _PositionOption(
        koLabel: '미끄러운 공 잡기',
        enLabel: 'Handling slippery balls',
        scores: {'GK': 3},
      ),
    ],
  ),
  _PositionQuestion(
    koPrompt: '실수 후 가장 먼저 하는 행동은?',
    enPrompt: 'After a mistake, your first action is...',
    options: [
      _PositionOption(
        koLabel: '다음 공격에 바로 도전',
        enLabel: 'Try next attack right away',
        scores: {'FW': 3},
      ),
      _PositionOption(
        koLabel: '공을 받아 흐름 되찾기',
        enLabel: 'Get on the ball again',
        scores: {'MF': 3},
      ),
      _PositionOption(
        koLabel: '수비 위치 다시 맞추기',
        enLabel: 'Reset defensive position',
        scores: {'DF': 3},
      ),
      _PositionOption(
        koLabel: '전체 라인 정리하기',
        enLabel: 'Reorganize whole line',
        scores: {'GK': 3, 'DF': 1},
      ),
    ],
  ),
  _PositionQuestion(
    koPrompt: '경기 마지막 5분, 리드 중이라면?',
    enPrompt: 'Last 5 minutes with a lead, you prefer...',
    options: [
      _PositionOption(
        koLabel: '추가 골 노리기',
        enLabel: 'Push for one more goal',
        scores: {'FW': 3},
      ),
      _PositionOption(
        koLabel: '공 소유하며 시간 쓰기',
        enLabel: 'Keep possession and time',
        scores: {'MF': 3, 'DF': 1},
      ),
      _PositionOption(
        koLabel: '위험 지역 닫기',
        enLabel: 'Close dangerous spaces',
        scores: {'DF': 3, 'GK': 1},
      ),
      _PositionOption(
        koLabel: '뒤에서 모두 지휘',
        enLabel: 'Command everyone from back',
        scores: {'GK': 3, 'DF': 1},
      ),
    ],
  ),
  _PositionQuestion(
    koPrompt: '세트피스 수비 때 편한 역할은?',
    enPrompt: 'During set-piece defense, you like...',
    options: [
      _PositionOption(
        koLabel: '클리어 후 역습 시작',
        enLabel: 'Start counter after clearance',
        scores: {'FW': 3, 'MF': 1},
      ),
      _PositionOption(
        koLabel: '세컨드볼 회수',
        enLabel: 'Collect second balls',
        scores: {'MF': 3, 'DF': 1},
      ),
      _PositionOption(
        koLabel: '강하게 마크',
        enLabel: 'Strong marking',
        scores: {'DF': 3},
      ),
      _PositionOption(
        koLabel: '캐칭과 콜',
        enLabel: 'Catching and calls',
        scores: {'GK': 3},
      ),
    ],
  ),
  _PositionQuestion(
    koPrompt: '좋은 경기라고 느낄 때는?',
    enPrompt: 'A good game for you is when...',
    options: [
      _PositionOption(
        koLabel: '골이나 도움을 했다',
        enLabel: 'I scored or assisted',
        scores: {'FW': 3},
      ),
      _PositionOption(
        koLabel: '패스가 잘 풀렸다',
        enLabel: 'Pass flow was great',
        scores: {'MF': 3},
      ),
      _PositionOption(
        koLabel: '상대를 잘 막았다',
        enLabel: 'I stopped opponents well',
        scores: {'DF': 3},
      ),
      _PositionOption(
        koLabel: '실점 위기를 막았다',
        enLabel: 'I made key saves',
        scores: {'GK': 3},
      ),
    ],
  ),
  _PositionQuestion(
    koPrompt: '팀을 위해 내가 제일 잘하는 희생은?',
    enPrompt: 'For the team, I can sacrifice by...',
    options: [
      _PositionOption(
        koLabel: '많이 뛰며 공간 만들기',
        enLabel: 'Running to create space',
        scores: {'FW': 3, 'MF': 1},
      ),
      _PositionOption(
        koLabel: '받고 주는 연결 계속하기',
        enLabel: 'Keep passing connections',
        scores: {'MF': 3, 'DF': 1},
      ),
      _PositionOption(
        koLabel: '몸 던져 막아내기',
        enLabel: 'Blocking with my body',
        scores: {'DF': 3},
      ),
      _PositionOption(
        koLabel: '뒤에서 안정감 주기',
        enLabel: 'Giving stability from back',
        scores: {'GK': 3},
      ),
    ],
  ),
  _PositionQuestion(
    koPrompt: '공을 받기 전 가장 먼저 하는 건?',
    enPrompt: 'Before receiving the ball, I first...',
    options: [
      _PositionOption(
        koLabel: '골문 쪽 공간을 본다',
        enLabel: 'Check scoring space',
        scores: {'FW': 3, 'MF': 1},
      ),
      _PositionOption(
        koLabel: '패스 줄을 본다',
        enLabel: 'Check passing lanes',
        scores: {'MF': 3, 'DF': 1},
      ),
      _PositionOption(
        koLabel: '뒤 커버를 먼저 본다',
        enLabel: 'Check defensive cover first',
        scores: {'DF': 3, 'GK': 1},
      ),
      _PositionOption(
        koLabel: '전체 라인을 살핀다',
        enLabel: 'Scan whole defensive line',
        scores: {'GK': 3, 'DF': 1},
      ),
    ],
  ),
  _PositionQuestion(
    koPrompt: '내가 가장 자신 있는 패스는?',
    enPrompt: 'Which pass are you most confident with?',
    options: [
      _PositionOption(
        koLabel: '마무리로 가는 침투 패스',
        enLabel: 'Final through pass',
        scores: {'FW': 3, 'MF': 1},
      ),
      _PositionOption(
        koLabel: '짧고 빠른 연결 패스',
        enLabel: 'Quick short connection pass',
        scores: {'MF': 3},
      ),
      _PositionOption(
        koLabel: '안전한 빌드업 패스',
        enLabel: 'Safe build-up pass',
        scores: {'DF': 3, 'MF': 1},
      ),
      _PositionOption(
        koLabel: '뒤에서 길게 전환 패스',
        enLabel: 'Long switch from the back',
        scores: {'GK': 3, 'DF': 1},
      ),
    ],
  ),
  _PositionQuestion(
    koPrompt: '수비할 때 제일 자신 있는 건?',
    enPrompt: 'What are you best at in defense?',
    options: [
      _PositionOption(
        koLabel: '앞에서 압박 시작',
        enLabel: 'Start pressing from front',
        scores: {'FW': 3, 'MF': 1},
      ),
      _PositionOption(
        koLabel: '중앙에서 길목 차단',
        enLabel: 'Block central lanes',
        scores: {'MF': 3, 'DF': 1},
      ),
      _PositionOption(
        koLabel: '1대1 막기',
        enLabel: '1v1 defending',
        scores: {'DF': 3},
      ),
      _PositionOption(
        koLabel: '마지막 슈팅 막기',
        enLabel: 'Stopping final shots',
        scores: {'GK': 3},
      ),
    ],
  ),
  _PositionQuestion(
    koPrompt: '공격할 때 나는 어디에 있나?',
    enPrompt: 'In attack, where am I most often?',
    options: [
      _PositionOption(
        koLabel: '골대 가까운 곳',
        enLabel: 'Near the goal',
        scores: {'FW': 3},
      ),
      _PositionOption(
        koLabel: '중앙 연결 지점',
        enLabel: 'Center connection point',
        scores: {'MF': 3},
      ),
      _PositionOption(
        koLabel: '뒤에서 밸런스 지키는 곳',
        enLabel: 'Back line for balance',
        scores: {'DF': 3},
      ),
      _PositionOption(
        koLabel: '골문 앞 지휘 위치',
        enLabel: 'Goal-front command spot',
        scores: {'GK': 3},
      ),
    ],
  ),
  _PositionQuestion(
    koPrompt: '코치가 칭찬해 주는 점은?',
    enPrompt: 'What does your coach praise most?',
    options: [
      _PositionOption(
        koLabel: '결정적인 마무리',
        enLabel: 'Decisive finishing',
        scores: {'FW': 3},
      ),
      _PositionOption(
        koLabel: '게임 조율 능력',
        enLabel: 'Game control and tempo',
        scores: {'MF': 3},
      ),
      _PositionOption(
        koLabel: '안정적인 수비',
        enLabel: 'Reliable defending',
        scores: {'DF': 3},
      ),
      _PositionOption(
        koLabel: '위기 선방',
        enLabel: 'Crisis saves',
        scores: {'GK': 3},
      ),
    ],
  ),
  _PositionQuestion(
    koPrompt: '친구들이 자주 맡기는 역할은?',
    enPrompt: 'What role do teammates often ask you to do?',
    options: [
      _PositionOption(
        koLabel: '골 넣는 역할',
        enLabel: 'Goal scorer',
        scores: {'FW': 3},
      ),
      _PositionOption(
        koLabel: '패스 연결 역할',
        enLabel: 'Pass connector',
        scores: {'MF': 3},
      ),
      _PositionOption(
        koLabel: '상대 막는 역할',
        enLabel: 'Main stopper',
        scores: {'DF': 3},
      ),
      _PositionOption(
        koLabel: '골문 지키는 역할',
        enLabel: 'Goal protector',
        scores: {'GK': 3},
      ),
    ],
  ),
  _PositionQuestion(
    koPrompt: '연습 게임 시작하면 제일 먼저 하는 건?',
    enPrompt: 'At kick-off in practice game, I first...',
    options: [
      _PositionOption(
        koLabel: '앞으로 침투한다',
        enLabel: 'Make a forward run',
        scores: {'FW': 3, 'MF': 1},
      ),
      _PositionOption(
        koLabel: '공 받아 방향 전환한다',
        enLabel: 'Receive and switch play',
        scores: {'MF': 3},
      ),
      _PositionOption(
        koLabel: '뒤 정렬부터 맞춘다',
        enLabel: 'Set defensive shape first',
        scores: {'DF': 3},
      ),
      _PositionOption(
        koLabel: '수비 라인에 콜을 준다',
        enLabel: 'Give calls to back line',
        scores: {'GK': 3, 'DF': 1},
      ),
    ],
  ),
  _PositionQuestion(
    koPrompt: '승리했을 때 가장 뿌듯한 순간은?',
    enPrompt: 'After winning, what feels best?',
    options: [
      _PositionOption(
        koLabel: '내 골로 이긴 순간',
        enLabel: 'Winning with my goal',
        scores: {'FW': 3},
      ),
      _PositionOption(
        koLabel: '팀 플레이가 잘 맞은 순간',
        enLabel: 'Team play clicked perfectly',
        scores: {'MF': 3},
      ),
      _PositionOption(
        koLabel: '실점 없이 막아낸 순간',
        enLabel: 'Stopping goals together',
        scores: {'DF': 3},
      ),
      _PositionOption(
        koLabel: '결정적 선방으로 지킨 순간',
        enLabel: 'Saving the key last chance',
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
