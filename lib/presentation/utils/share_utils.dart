import 'package:flutter/foundation.dart';
import 'package:share_plus/share_plus.dart';

typedef TextShareOverride = Future<void> Function({
  required String text,
  required String subject,
});

@visibleForTesting
TextShareOverride? debugTextShareOverride;

Future<void> shareTextContent({
  required String text,
  required String subject,
}) async {
  final override = debugTextShareOverride;
  if (override != null) {
    await override(text: text, subject: subject);
    return;
  }
  await SharePlus.instance.share(
    ShareParams(
      text: text,
      subject: subject,
      title: subject,
    ),
  );
}
