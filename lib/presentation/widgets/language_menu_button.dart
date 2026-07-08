import 'package:flutter/material.dart';
import 'package:football_note/gen/app_localizations.dart';
import '../../application/locale_service.dart';
import 'app_bar_action_button.dart';

class LanguageMenuButton extends StatelessWidget {
  final LocaleService localeService;

  const LanguageMenuButton({super.key, required this.localeService});

  @override
  Widget build(BuildContext context) {
    return AppBarActionMenuButton<String>(
      icon: Icons.language,
      tooltip: AppLocalizations.of(context)!.language,
      onSelected: (value) {
        if (value == 'system') {
          localeService.setLocale(null);
        } else if (value == 'en') {
          localeService.setLocale(const Locale('en'));
        } else if (value == 'ja') {
          localeService.setLocale(const Locale('ja'));
        } else if (value == 'ko') {
          localeService.setLocale(const Locale('ko', 'KR'));
        }
      },
      itemBuilder: (context) => [
        PopupMenuItem(
          value: 'system',
          child: Text(AppLocalizations.of(context)!.languageSystemDefault),
        ),
        PopupMenuItem(
          value: 'en',
          child: Text(AppLocalizations.of(context)!.languageEnglish),
        ),
        PopupMenuItem(
          value: 'ko',
          child: Text(AppLocalizations.of(context)!.languageKorean),
        ),
        PopupMenuItem(
          value: 'ja',
          child: Text(AppLocalizations.of(context)!.languageJapanese),
        ),
      ],
    );
  }
}
