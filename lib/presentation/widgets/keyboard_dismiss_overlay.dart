import 'package:flutter/material.dart';

import 'package:football_note/gen/app_localizations.dart';

class KeyboardDismissOverlay extends StatelessWidget {
  final Widget child;

  const KeyboardDismissOverlay({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final keyboardInset = MediaQuery.viewInsetsOf(context).bottom;
    final showButton = keyboardInset > 0;
    final label = AppLocalizations.of(context)!.hideKeyboard;
    final button = Semantics(
      button: true,
      label: label,
      child: IconButton.filledTonal(
        onPressed: () => FocusManager.instance.primaryFocus?.unfocus(),
        style: IconButton.styleFrom(
          fixedSize: const Size.square(42),
          minimumSize: const Size.square(42),
          padding: EdgeInsets.zero,
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        ),
        icon: const Icon(Icons.keyboard_hide_rounded, size: 20),
      ),
    );
    final dismissButton = Overlay.maybeOf(context) == null
        ? button
        : Tooltip(message: label, child: button);

    return Stack(
      fit: StackFit.expand,
      children: [
        child,
        IgnorePointer(
          ignoring: !showButton,
          child: AnimatedOpacity(
            opacity: showButton ? 1 : 0,
            duration: const Duration(milliseconds: 180),
            child: Align(
              alignment: Alignment.bottomRight,
              child: Padding(
                padding: EdgeInsets.only(right: 16, bottom: keyboardInset + 16),
                child: SafeArea(
                  top: false,
                  left: false,
                  child: dismissButton,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
