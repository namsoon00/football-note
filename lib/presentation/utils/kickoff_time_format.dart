import 'package:flutter/widgets.dart';
import 'package:intl/intl.dart';

import '../../gen/app_localizations.dart';

const Duration _koreaTimeOffset = Duration(hours: 9);

String formatKickoffWithKoreaTime(BuildContext context, DateTime kickoffAt) {
  final l10n = AppLocalizations.of(context)!;
  final localeName = Localizations.localeOf(context).toLanguageTag();
  final formatter = DateFormat.MMMd(localeName).add_Hm();
  final localText = formatter.format(kickoffAt.toLocal());
  final koreaText = formatter.format(koreaTimeFor(kickoffAt));
  if (localText == koreaText) {
    return l10n.matchKickoffKoreaOnly(koreaText);
  }
  return l10n.matchKickoffLocalAndKorea(localText, koreaText);
}

String formatKoreaKickoffTime(BuildContext context, DateTime kickoffAt) {
  final localeName = Localizations.localeOf(context).toLanguageTag();
  return DateFormat.MMMd(localeName).add_Hm().format(koreaTimeFor(kickoffAt));
}

DateTime koreaTimeFor(DateTime kickoffAt) {
  final korea = kickoffAt.toUtc().add(_koreaTimeOffset);
  return DateTime(
    korea.year,
    korea.month,
    korea.day,
    korea.hour,
    korea.minute,
    korea.second,
    korea.millisecond,
    korea.microsecond,
  );
}
