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
  DateTime? _savedUpdatedAt;
  bool _isSaving = false;

  bool get _canEdit {
    return FamilyAccessService(
      widget.optionRepository,
    ).loadState().isParentMode;
  }

  bool get _hasChanges {
    return _controller.text.trim() != _savedMessage.trim();
  }

  bool get _canClear {
    return !_isSaving &&
        (_controller.text.trim().isNotEmpty || _savedMessage.trim().isNotEmpty);
  }

  @override
  void initState() {
    super.initState();
    _feedbackService = ParentSharedFeedbackService(widget.optionRepository);
    final feedback = _feedbackService.feedbackForEntry(widget.entry);
    _savedMessage = feedback?.message ?? '';
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
    if (!_canEdit || !_hasChanges || _isSaving) {
      return;
    }
    setState(() => _isSaving = true);
    try {
      final saved = await _feedbackService.saveFeedbackForEntry(
        widget.entry,
        _controller.text,
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
    if (backup == null || !_canEdit) {
      return false;
    }
    try {
      await backup.markParentSharedDataDirty();
      return await backup.backupIfSignedIn();
    } catch (_) {
      return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final localeTag = Localizations.localeOf(context).toString();
    final previewText = _savedMessage.trim().isEmpty
        ? l10n.parentFeedbackEmpty
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
                        TextField(
                          controller: _controller,
                          minLines: 8,
                          maxLines: 14,
                          autofocus: true,
                          enabled: !_isSaving,
                          decoration: InputDecoration(
                            labelText: l10n.parentFeedbackInputLabel,
                            hintText: l10n.parentFeedbackInputHint,
                            alignLabelWithHint: true,
                          ),
                        )
                      else
                        Text(
                          previewText,
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
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
        bottomNavigationBar: !_canEdit
            ? null
            : SafeArea(
                top: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  child: Row(
                    children: [
                      TextButton(
                        onPressed: _canClear ? () => _controller.clear() : null,
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
}
