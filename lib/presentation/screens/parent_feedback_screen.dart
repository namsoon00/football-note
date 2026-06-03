import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../application/backup_service.dart';
import '../../application/family_access_service.dart';
import '../../application/parent_shared_feedback_service.dart';
import '../../domain/entities/training_entry.dart';
import '../../domain/repositories/option_repository.dart';
import '../../gen/app_localizations.dart';
import '../widgets/app_feedback.dart';
import '../widgets/watch_cart/watch_cart_card.dart';

class ParentFeedbackScreenResult {
  final bool changed;
  final ParentTrainingFeedback? feedback;
  final bool didSync;

  const ParentFeedbackScreenResult({
    required this.changed,
    required this.feedback,
    required this.didSync,
  });
}

class ParentFeedbackScreen extends StatefulWidget {
  final TrainingEntry entry;
  final OptionRepository optionRepository;
  final BackupService? driveBackupService;

  const ParentFeedbackScreen({
    super.key,
    required this.entry,
    required this.optionRepository,
    required this.driveBackupService,
  });

  @override
  State<ParentFeedbackScreen> createState() => _ParentFeedbackScreenState();
}

class _ParentFeedbackScreenState extends State<ParentFeedbackScreen> {
  late final ParentSharedFeedbackService _feedbackService;
  late final TextEditingController _controller;
  String _savedMessage = '';
  List<String> _savedReactions = const <String>[];
  Set<String> _selectedReactions = <String>{};
  DateTime? _savedUpdatedAt;
  bool _isSaving = false;

  bool get _canEdit {
    return FamilyAccessService(
      widget.optionRepository,
    ).loadState().isParentMode;
  }

  bool get _isPlayerMode {
    return FamilyAccessService(
      widget.optionRepository,
    ).loadState().isChildMode;
  }

  bool get _hasChanges {
    final reactionsChanged = !_sameReactionSet(
      _selectedReactions,
      _savedReactions.toSet(),
    );
    if (_canEdit) {
      return _controller.text.trim() != _savedMessage.trim();
    }
    return _canReact && reactionsChanged;
  }

  bool get _canReact {
    return _isPlayerMode &&
        (_savedMessage.trim().isNotEmpty || _savedReactions.isNotEmpty);
  }

  bool get _canClear {
    if (_isSaving) return false;
    if (_canEdit) {
      return _controller.text.trim().isNotEmpty ||
          _savedMessage.trim().isNotEmpty;
    }
    return _selectedReactions.isNotEmpty || _savedReactions.isNotEmpty;
  }

  @override
  void initState() {
    super.initState();
    _feedbackService = ParentSharedFeedbackService(widget.optionRepository);
    final feedback = _feedbackService.feedbackForEntry(widget.entry);
    _savedMessage = feedback?.message ?? '';
    _savedReactions = feedback?.reactions ?? const <String>[];
    _selectedReactions = _savedReactions.toSet();
    _savedUpdatedAt = feedback?.updatedAt;
    _controller = TextEditingController(text: _savedMessage)
      ..addListener(_handleControllerChanged);
  }

  @override
  void dispose() {
    _controller
      ..removeListener(_handleControllerChanged)
      ..dispose();
    super.dispose();
  }

  void _handleControllerChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  Future<bool> _confirmExitWithoutSave() async {
    if (!_canEdit || !_hasChanges || _isSaving) {
      return true;
    }
    final l10n = AppLocalizations.of(context)!;
    final shouldLeave = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.parentFeedbackDiscardTitle),
        content: Text(l10n.parentFeedbackDiscardBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(l10n.parentFeedbackDiscardAction),
          ),
        ],
      ),
    );
    return shouldLeave ?? false;
  }

  Future<void> _saveFeedback() async {
    if ((!_canEdit && !_canReact) || !_hasChanges || _isSaving) {
      return;
    }
    setState(() => _isSaving = true);
    try {
      final saved = await _feedbackService.saveFeedbackForEntry(
        widget.entry,
        _canEdit ? _controller.text : _savedMessage,
        _canEdit ? _savedReactions : _selectedReactions.toList(),
      );
      final didSync = await _syncParentSharedDataIfPossible();
      if (!mounted) {
        return;
      }
      Navigator.of(context).pop(
        ParentFeedbackScreenResult(
          changed: true,
          feedback: saved,
          didSync: didSync,
        ),
      );
    } catch (_) {
      if (!mounted) {
        return;
      }
      final l10n = AppLocalizations.of(context)!;
      AppFeedback.showMessage(context, text: l10n.parentFeedbackSaveFailed);
      setState(() => _isSaving = false);
    }
  }

  Future<bool> _syncParentSharedDataIfPossible() async {
    final backup = widget.driveBackupService;
    if (backup == null) {
      return false;
    }
    try {
      if (_canEdit) {
        await backup.markParentSharedDataDirty();
        return await backup.backupIfSignedIn();
      }
      return await backup.backupIfSignedIn(requireAutoOnSave: true);
    } catch (_) {
      return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final localeTag = Localizations.localeOf(context).toString();
    final previewText = _savedMessage.trim().isEmpty
        ? (_savedReactions.isEmpty
            ? l10n.parentFeedbackEmpty
            : l10n.parentFeedbackReactionOnly)
        : _savedMessage.trim();
    final updatedLabel = _savedUpdatedAt == null
        ? ''
        : DateFormat(
            Localizations.localeOf(context).languageCode == 'ko'
                ? 'M/d HH:mm'
                : 'MMM d HH:mm',
            localeTag,
          ).format(_savedUpdatedAt!);
    final sessionLabel = DateFormat(
      'yyyy.MM.dd',
      localeTag,
    ).format(widget.entry.date);

    final canPop = !_canEdit || !_hasChanges || _isSaving;
    return PopScope(
      canPop: canPop,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop || canPop) {
          return;
        }
        final navigator = Navigator.of(context);
        final shouldLeave = await _confirmExitWithoutSave();
        if (!mounted || !shouldLeave) {
          return;
        }
        navigator.pop();
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(l10n.parentFeedbackSectionTitle),
          actions: [
            if (_canEdit)
              TextButton(
                onPressed: (_isSaving || !_hasChanges) ? null : _saveFeedback,
                child: Text(l10n.parentFeedbackSave),
              ),
          ],
        ),
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                WatchCartCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.parentFeedbackSectionTitle,
                        style: Theme.of(context)
                            .textTheme
                            .titleMedium
                            ?.copyWith(fontWeight: FontWeight.w800),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        _canEdit
                            ? l10n.parentFeedbackHelper
                            : l10n.parentFeedbackReadOnlyHint,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          Chip(label: Text(sessionLabel)),
                          if (widget.entry.program.trim().isNotEmpty)
                            Chip(label: Text(widget.entry.program.trim())),
                          if (updatedLabel.isNotEmpty)
                            Chip(label: Text(updatedLabel)),
                        ],
                      ),
                      const SizedBox(height: 16),
                      if (_canEdit)
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            TextField(
                              controller: _controller,
                              minLines: 8,
                              maxLines: 14,
                              autofocus: true,
                              enabled: !_isSaving,
                              keyboardType: TextInputType.multiline,
                              textInputAction: TextInputAction.newline,
                              decoration: InputDecoration(
                                labelText: l10n.parentFeedbackInputLabel,
                                hintText: l10n.parentFeedbackInputHint,
                                alignLabelWithHint: true,
                              ),
                            ),
                            if (_savedReactions.isNotEmpty) ...[
                              const SizedBox(height: 16),
                              _ParentFeedbackReactionPicker(
                                selectedReactions: _savedReactions.toSet(),
                                canEdit: false,
                                onChanged: (_) {},
                              ),
                            ],
                          ],
                        )
                      else
                        Text(
                          previewText,
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      if (_canReact) ...[
                        const SizedBox(height: 16),
                        _ParentFeedbackReactionPicker(
                          selectedReactions: _selectedReactions,
                          canEdit: !_isSaving,
                          onChanged: (value) {
                            setState(() => _selectedReactions = value);
                          },
                        ),
                      ],
                      if (_isSaving) ...[
                        const SizedBox(height: 16),
                        const LinearProgressIndicator(),
                        const SizedBox(height: 8),
                        Text(
                          l10n.parentSharedSyncInProgress,
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        bottomNavigationBar: (!_canEdit && !_canReact)
            ? null
            : SafeArea(
                top: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  child: Row(
                    children: [
                      if (_canEdit)
                        TextButton(
                          onPressed:
                              _canClear ? () => _controller.clear() : null,
                          child: Text(l10n.parentFeedbackClear),
                        ),
                      const Spacer(),
                      FilledButton.icon(
                        onPressed:
                            (_isSaving || !_hasChanges) ? null : _saveFeedback,
                        icon: const Icon(Icons.save_outlined),
                        label: Text(l10n.parentFeedbackSave),
                      ),
                    ],
                  ),
                ),
              ),
      ),
    );
  }

  bool _sameReactionSet(Set<String> a, Set<String> b) {
    return a.length == b.length && a.containsAll(b);
  }
}

class _ParentFeedbackReactionPicker extends StatelessWidget {
  final Set<String> selectedReactions;
  final bool canEdit;
  final ValueChanged<Set<String>> onChanged;

  const _ParentFeedbackReactionPicker({
    required this.selectedReactions,
    required this.canEdit,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final options = <_ParentFeedbackReactionOption>[
      _ParentFeedbackReactionOption(
        id: 'thanks',
        icon: Icons.favorite_rounded,
        label: l10n.parentFeedbackReactionThanks,
      ),
      _ParentFeedbackReactionOption(
        id: 'proud',
        icon: Icons.emoji_events_rounded,
        label: l10n.parentFeedbackReactionProud,
      ),
      _ParentFeedbackReactionOption(
        id: 'review',
        icon: Icons.rate_review_rounded,
        label: l10n.parentFeedbackReactionReview,
      ),
      _ParentFeedbackReactionOption(
        id: 'try',
        icon: Icons.directions_run_rounded,
        label: l10n.parentFeedbackReactionTry,
      ),
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.parentFeedbackReactionLabel,
          style: Theme.of(
            context,
          ).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            ChoiceChip(
              avatar: const Icon(
                Icons.radio_button_unchecked_rounded,
                size: 18,
              ),
              label: Text(l10n.parentFeedbackReactionNone),
              selected: selectedReactions.isEmpty,
              onSelected: !canEdit ? null : (_) => onChanged(<String>{}),
            ),
            for (final option in options)
              FilterChip(
                avatar: Icon(option.icon, size: 18),
                label: Text(option.label),
                selected: selectedReactions.contains(option.id),
                onSelected: !canEdit
                    ? null
                    : (selected) {
                        final next = Set<String>.of(selectedReactions);
                        if (selected) {
                          next.add(option.id);
                        } else {
                          next.remove(option.id);
                        }
                        onChanged(next);
                      },
              ),
          ],
        ),
      ],
    );
  }
}

class _ParentFeedbackReactionOption {
  final String id;
  final IconData icon;
  final String label;

  const _ParentFeedbackReactionOption({
    required this.id,
    required this.icon,
    required this.label,
  });
}
