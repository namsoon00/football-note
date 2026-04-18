import 'package:flutter/material.dart';
import 'package:football_note/gen/app_localizations.dart';

import '../../application/backup_service.dart';
import '../../application/family_access_service.dart';
import '../../domain/repositories/option_repository.dart';
import '../widgets/app_feedback.dart';

class FamilySpaceScreen extends StatefulWidget {
  final OptionRepository optionRepository;
  final BackupService? driveBackupService;

  const FamilySpaceScreen({
    super.key,
    required this.optionRepository,
    this.driveBackupService,
  });

  @override
  State<FamilySpaceScreen> createState() => _FamilySpaceScreenState();
}

class _FamilySpaceScreenState extends State<FamilySpaceScreen> {
  late final FamilyAccessService _familyService;
  late final TextEditingController _messageController;
  bool _sending = false;

  @override
  void initState() {
    super.initState();
    _familyService = FamilyAccessService(widget.optionRepository);
    _messageController = TextEditingController();
  }

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final state = _familyService.loadState();
    final isParent = state.isParentMode;
    final latestMessages = state.messages;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.familySpaceTitle)),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: _FamilySpaceSummaryCard(
                roleLabel:
                    isParent ? l10n.familyRoleParent : l10n.familyRoleChild,
                title: l10n.familySharing,
                subtitle: isParent
                    ? l10n.familySpaceSubtitleParent
                    : l10n.familySpaceSubtitleChild,
                childName: state.childName.trim().isEmpty
                    ? l10n.familyRoleChild
                    : state.childName.trim(),
                parentName: state.parentName.trim().isEmpty
                    ? l10n.familyRoleParent
                    : state.parentName.trim(),
              ),
            ),
            Expanded(
              child: latestMessages.isEmpty
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Text(
                          l10n.familyMessagesEmpty,
                          textAlign: TextAlign.center,
                          style: theme.textTheme.bodyLarge,
                        ),
                      ),
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                      itemCount: latestMessages.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 10),
                      itemBuilder: (context, index) {
                        final message = latestMessages[index];
                        final isOwnRole =
                            message.authorRole == state.currentRole;
                        final isFeedback =
                            message.kind == FamilyMessageKind.feedback;
                        return _FamilyMessageCard(
                          author: message.authorName.trim().isEmpty
                              ? (message.authorRole == FamilyRole.parent
                                  ? l10n.familyRoleParent
                                  : l10n.familyRoleChild)
                              : message.authorName.trim(),
                          body: message.body,
                          label: isFeedback
                              ? l10n.familyMessageTypeFeedback
                              : l10n.familyMessageTypeNote,
                          timestamp: MaterialLocalizations.of(
                            context,
                          ).formatShortDate(message.createdAt),
                          highlight: isOwnRole,
                        );
                      },
                    ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(
                    child: TextField(
                      controller: _messageController,
                      minLines: 2,
                      maxLines: 4,
                      textInputAction: TextInputAction.newline,
                      decoration: InputDecoration(
                        labelText: l10n.familyMessageComposerLabel,
                        hintText: isParent
                            ? l10n.familyMessageComposerHintParent
                            : l10n.familyMessageComposerHintChild,
                        border: const OutlineInputBorder(),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  FilledButton(
                    onPressed: _sending ? null : _sendMessage,
                    child: Text(l10n.familyMessageSend),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _sendMessage() async {
    final l10n = AppLocalizations.of(context)!;
    final body = _messageController.text.trim();
    if (body.isEmpty) {
      AppFeedback.showMessage(
        context,
        text: l10n.familyMessageComposerEmpty,
      );
      return;
    }
    setState(() => _sending = true);
    try {
      final state = _familyService.loadState();
      await _familyService.addMessage(
        body: body,
        authorRole: state.currentRole,
        authorName: state.currentRole == FamilyRole.parent
            ? (state.parentName.trim().isEmpty
                ? l10n.familyRoleParent
                : state.parentName.trim())
            : (state.childName.trim().isEmpty
                ? l10n.familyRoleChild
                : state.childName.trim()),
      );
      _messageController.clear();
      if (widget.driveBackupService != null) {
        try {
          await widget.driveBackupService!.backupIfSignedIn();
        } catch (_) {
          // Family messages still remain local if shared backup is unavailable.
        }
      }
      if (!mounted) return;
      setState(() {});
      AppFeedback.showSuccess(context, text: l10n.familyMessageSent);
    } finally {
      if (mounted) {
        setState(() => _sending = false);
      }
    }
  }
}

class _FamilySpaceSummaryCard extends StatelessWidget {
  final String roleLabel;
  final String title;
  final String subtitle;
  final String childName;
  final String parentName;

  const _FamilySpaceSummaryCard({
    required this.roleLabel,
    required this.title,
    required this.subtitle,
    required this.childName,
    required this.parentName,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 8,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Text(
                title,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w900,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  roleLabel,
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: theme.colorScheme.primary,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(subtitle, style: theme.textTheme.bodyMedium),
          const SizedBox(height: 10),
          Text(
            '$childName  ·  $parentName',
            style: theme.textTheme.labelLarge?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _FamilyMessageCard extends StatelessWidget {
  final String author;
  final String label;
  final String body;
  final String timestamp;
  final bool highlight;

  const _FamilyMessageCard({
    required this.author,
    required this.label,
    required this.body,
    required this.timestamp,
    required this.highlight,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: highlight
            ? theme.colorScheme.primaryContainer.withValues(alpha: 0.72)
            : theme.colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  author,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              Text(
                label,
                style: theme.textTheme.labelMedium?.copyWith(
                  color: theme.colorScheme.primary,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(body, style: theme.textTheme.bodyMedium),
          const SizedBox(height: 8),
          Text(
            timestamp,
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}
