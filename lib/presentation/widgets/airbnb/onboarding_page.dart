import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'page_indicator.dart';
import 'primary_button.dart';

class AirbnbOnboardingPage extends StatelessWidget {
  final int activePage;
  final int totalPages;
  final String imagePath;
  final String title;
  final String buttonText;
  final String footerText;
  final VoidCallback onPressed;

  const AirbnbOnboardingPage({
    super.key,
    required this.activePage,
    required this.totalPages,
    required this.imagePath,
    required this.title,
    required this.buttonText,
    required this.footerText,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    return Column(
      children: [
        Expanded(
          child: Container(
            decoration: BoxDecoration(
              image: DecorationImage(
                fit: BoxFit.cover,
                image: AssetImage(imagePath),
              ),
            ),
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
          constraints: BoxConstraints(minWidth: size.height * 0.4),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 26.0,
                  height: 1.4,
                  color: Color.fromRGBO(33, 45, 82, 1),
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 15.0),
              AirbnbPageIndicator(activePage: activePage, total: totalPages),
              const SizedBox(height: 24.0),
              AirbnbPrimaryButton(text: buttonText, onPressed: onPressed),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(bottom: 16.0),
          child: Text(
            footerText,
            style: GoogleFonts.inter(
              fontSize: 14.0,
              color: const Color.fromRGBO(64, 74, 106, 1),
            ),
          ),
        ),
      ],
    );
  }
}
