import 'package:flutter/material.dart';

class AppFeedback {
  static const Duration _quickDuration = Duration(milliseconds: 2500);
  static const Duration _undoDuration = Duration(seconds: 5);

  static void showMessage(
    BuildContext context, {
    required String text,
    SnackBarAction? action,
  }) {
    final messenger = ScaffoldMessenger.of(context);
    messenger
      ..removeCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(text),
          action: action,
          duration: _quickDuration,
        ),
      );
  }

  static void showSuccess(BuildContext context, {required String text}) {
    final messenger = ScaffoldMessenger.of(context);
    messenger
      ..removeCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(text),
          duration: _quickDuration,
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
      ..removeCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          duration: _undoDuration,
          content: Text(text),
          action: SnackBarAction(
            label: undoLabel,
            onPressed: onUndo,
          ),
        ),
      );
  }
}
