import 'package:flutter/material.dart';
import 'package:football_note/gen/app_localizations.dart';

class InfoBanner extends StatelessWidget {
  final String summary;
  final String? detailsTitle;
  final String? detailsMessage;
  final IconData icon;
  final EdgeInsetsGeometry padding;
  final Color? backgroundColor;
  final Color? borderColor;
  final TextStyle? textStyle;

  const InfoBanner({
    super.key,
    required this.summary,
    this.detailsTitle,
    this.detailsMessage,
    this.icon = Icons.info_outline_rounded,
    this.padding = const EdgeInsets.all(14),
    this.backgroundColor,
    this.borderColor,
    this.textStyle,
  });

  bool get _hasDetails => detailsMessage?.trim().isNotEmpty == true;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    final background =
        backgroundColor ?? theme.colorScheme.surfaceContainerHigh;
    final border =
        borderColor ?? theme.colorScheme.outline.withValues(alpha: 0.14);

    return Container(
      width: double.infinity,
      padding: padding,
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              color: theme.colorScheme.primary.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 18, color: theme.colorScheme.primary),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              summary,
              style:
                  textStyle ??
                  theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
          ),
          if (_hasDetails) ...[
            const SizedBox(width: 4),
            IconButton(
              constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
              visualDensity: VisualDensity.compact,
              tooltip: l10n.moreInfoAction,
              onPressed: () => _showDetails(context),
              icon: const Icon(Icons.info_outline_rounded, size: 18),
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _showDetails(BuildContext context) async {
    final message = detailsMessage?.trim() ?? '';
    if (message.isEmpty) return;
    final l10n = AppLocalizations.of(context)!;
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text((detailsTitle ?? summary).trim()),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: Text(l10n.confirm),
          ),
        ],
      ),
    );
  }
}
