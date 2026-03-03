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
