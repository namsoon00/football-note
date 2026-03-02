import 'package:flutter/material.dart';
import 'package:football_note/gen/app_localizations.dart';
import '../../application/locale_service.dart';

class LanguageMenuButton extends StatelessWidget {
  final LocaleService localeService;

  const LanguageMenuButton({
    super.key,
    required this.localeService,
  });

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String>(
      icon: const Icon(Icons.language),
      onSelected: (value) {
        if (value == 'en') {
          localeService.setLocale(const Locale('en'));
        } else if (value == 'ko') {
          localeService.setLocale(const Locale('ko', 'KR'));
        }
      },
      itemBuilder: (context) => [
        PopupMenuItem(
          value: 'en',
          child: Text(AppLocalizations.of(context)!.languageEnglish),
        ),
        PopupMenuItem(
          value: 'ko',
          child: Text(AppLocalizations.of(context)!.languageKorean),
        ),
      ],
    );
  }
}
