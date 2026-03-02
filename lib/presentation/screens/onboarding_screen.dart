import 'package:flutter/material.dart';
import '../../application/training_service.dart';
import '../../domain/repositories/option_repository.dart';
import '../../application/locale_service.dart';
import '../../application/settings_service.dart';
import 'home_screen.dart';
import '../widgets/airbnb/onboarding_page.dart';
import 'package:football_note/gen/app_localizations.dart';

class OnboardingScreen extends StatefulWidget {
  final TrainingService trainingService;
  final OptionRepository optionRepository;
  final LocaleService localeService;
  final SettingsService settingsService;

  const OnboardingScreen({
    super.key,
    required this.trainingService,
    required this.optionRepository,
    required this.localeService,
    required this.settingsService,
  });

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _controller = PageController();
  int _currentPage = 0;

  @override
  void initState() {
    super.initState();
    _controller.addListener(() {
      final next = _controller.page?.round() ?? 0;
      if (next != _currentPage) {
        setState(() => _currentPage = next);
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final pages = [
      {
        'title': AppLocalizations.of(context)!.onboard1,
        'image': 'assets/airbnb/images/page1.png',
      },
      {
        'title': AppLocalizations.of(context)!.onboard2,
        'image': 'assets/airbnb/images/page2.png',
      },
      {
        'title': AppLocalizations.of(context)!.onboard3,
        'image': 'assets/airbnb/images/page1.png',
      },
    ];

    return Scaffold(
      body: PageView.builder(
        controller: _controller,
        itemCount: pages.length,
        itemBuilder: (context, index) {
          final page = pages[index];
          return AirbnbOnboardingPage(
            activePage: _currentPage,
            totalPages: pages.length,
            title: page['title']!,
            imagePath: page['image']!,
            buttonText: index == pages.length - 1
                ? AppLocalizations.of(context)!.start
                : AppLocalizations.of(context)!.next,
            footerText: AppLocalizations.of(context)!.heroMessage,
            onPressed: () {
              if (index == pages.length - 1) {
                Navigator.of(context).pushReplacement(
                  MaterialPageRoute(
                    builder: (_) => HomeScreen(
                      trainingService: widget.trainingService,
                      optionRepository: widget.optionRepository,
                      localeService: widget.localeService,
                      settingsService: widget.settingsService,
                    ),
                  ),
                );
              } else {
                _controller.nextPage(
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeOut,
                );
              }
            },
          );
        },
      ),
    );
  }
}
