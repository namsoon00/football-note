import 'package:flutter/material.dart';

class AppFeedback {
  static void showMessage(
    BuildContext context, {
    required String text,
    SnackBarAction? action,
  }) {
    final messenger = ScaffoldMessenger.of(context);
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          content: Text(text),
          action: action,
          duration: const Duration(seconds: 2),
        ),
      );
  }

  static void showSuccess(BuildContext context, {required String text}) {
    final scheme = Theme.of(context).colorScheme;
    final messenger = ScaffoldMessenger.of(context);
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          backgroundColor: scheme.primaryContainer,
          content: Text(
            text,
            style: TextStyle(color: scheme.onPrimaryContainer),
          ),
          duration: const Duration(seconds: 2),
        ),
      );
  }

  static void showUndo(
    BuildContext context, {
    required String text,
    required String undoLabel,
    required VoidCallback onUndo,
  }) {
    final messenger = ScaffoldMessenger.of(context);
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          duration: const Duration(seconds: 5),
          content: Text(text),
          action: SnackBarAction(label: undoLabel, onPressed: onUndo),
        ),
      );
  }
}
