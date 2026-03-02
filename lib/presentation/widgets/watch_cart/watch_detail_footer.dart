import 'package:flutter/material.dart';
import 'constants.dart';

class WatchDetailFooter extends StatelessWidget {
  final String primaryLabel;
  final VoidCallback onPrimary;
  final VoidCallback? onSecondary;
  final IconData secondaryIcon;

  const WatchDetailFooter({
    super.key,
    required this.primaryLabel,
    required this.onPrimary,
    this.onSecondary,
    this.secondaryIcon = Icons.add_a_photo_outlined,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final primaryColor = isDark
        ? theme.colorScheme.primaryContainer
        : WatchCartConstants.primaryColor;
    final borderColor = isDark
        ? theme.colorScheme.outline.withValues(alpha: 0.42)
        : const Color.fromRGBO(230, 230, 230, 1);
    final primaryTextColor =
        isDark ? theme.colorScheme.onPrimaryContainer : Colors.white;
    return Row(
      children: [
        if (onSecondary != null)
          Material(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(8.0),
            child: InkWell(
              onTap: onSecondary,
              borderRadius: BorderRadius.circular(8.0),
              splashColor: WatchCartConstants.primaryColor.withAlpha(40),
              highlightColor: WatchCartConstants.primaryColor.withAlpha(20),
              child: Container(
                margin: const EdgeInsets.only(right: 15.0),
                width: 60.0,
                height: 60.0,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8.0),
                  border: Border.all(
                    color: borderColor,
                  ),
                ),
                child: Icon(secondaryIcon),
              ),
            ),
          ),
        Expanded(
          child: Material(
            color: primaryColor,
            borderRadius: BorderRadius.circular(8.0),
            child: InkWell(
              onTap: onPrimary,
              borderRadius: BorderRadius.circular(8.0),
              splashColor: primaryTextColor.withAlpha(40),
              highlightColor: primaryTextColor.withAlpha(20),
              child: Container(
                height: 60.0,
                padding: const EdgeInsets.symmetric(horizontal: 32.0),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8.0),
                  border: Border.all(
                    color: borderColor,
                  ),
                ),
                child: Center(
                  child: Text(
                    primaryLabel,
                    style: TextStyle(
                      color: primaryTextColor,
                      fontWeight: FontWeight.w600,
                      fontSize: 14.0,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
