import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../widgets/watch_cart/constants.dart';

class AppSpacing {
  static const double xxs = 4;
  static const double xs = 8;
  static const double sm = 12;
  static const double md = 16;
  static const double lg = 20;
  static const double xl = 24;
  static const double xxl = 32;

  static const EdgeInsets screen = EdgeInsets.symmetric(
    horizontal: md,
    vertical: sm,
  );
  static const EdgeInsets card = EdgeInsets.all(md);
}

class AppRadius {
  static const double xs = 8;
  static const double sm = 12;
  static const double md = 16;
  static const double card = 20;
  static const double pill = 999;

  static BorderRadius get small => BorderRadius.circular(sm);
  static BorderRadius get control => BorderRadius.circular(md);
  static BorderRadius get surface => BorderRadius.circular(card);
  static BorderRadius get full => BorderRadius.circular(pill);
}

class AppSizes {
  static const double minTouchTarget = 48;
  static const double appBarAction = 40;
  static const double iconControl = 56;
  static const double primaryButtonHeight = 54;
}

class AppShadows {
  static List<BoxShadow>? surface(Brightness brightness) {
    if (brightness == Brightness.dark) return null;
    return const [
      BoxShadow(
        color: Color(0x10111F3C),
        blurRadius: 18,
        offset: Offset(0, 6),
      ),
    ];
  }
}

class AppSurfaces {
  static Color cardColor(ColorScheme scheme, Brightness brightness) {
    return brightness == Brightness.dark
        ? scheme.surfaceContainerHighest
        : scheme.surface;
  }

  static Color subtleColor(ColorScheme scheme, Brightness brightness) {
    return brightness == Brightness.dark
        ? scheme.surfaceContainerHighest.withValues(alpha: 0.42)
        : scheme.surfaceContainerHighest.withValues(alpha: 0.72);
  }

  static Color borderColor(ColorScheme scheme, Brightness brightness) {
    return brightness == Brightness.dark
        ? scheme.outline.withValues(alpha: 0.46)
        : scheme.outline.withValues(alpha: 0.72);
  }

  static BoxDecoration cardDecoration(
    ColorScheme scheme,
    Brightness brightness,
  ) {
    return BoxDecoration(
      color: cardColor(scheme, brightness),
      borderRadius: AppRadius.surface,
      border: Border.all(color: borderColor(scheme, brightness)),
      boxShadow: AppShadows.surface(brightness),
    );
  }

  static BoxDecoration subtleDecoration(
    ColorScheme scheme,
    Brightness brightness, {
    Color? accent,
    double accentAlpha = 0.08,
  }) {
    final card = cardColor(scheme, brightness);
    final tint = accent ?? scheme.primary;
    return BoxDecoration(
      gradient: LinearGradient(
        begin: AlignmentDirectional.topStart,
        end: AlignmentDirectional.bottomEnd,
        colors: [
          tint.withValues(
            alpha: brightness == Brightness.dark
                ? (accentAlpha + 0.06).clamp(0.0, 1.0).toDouble()
                : accentAlpha,
          ),
          card,
        ],
      ),
      borderRadius: AppRadius.surface,
      border: Border.all(
        color: tint.withValues(
          alpha: brightness == Brightness.dark ? 0.34 : 0.2,
        ),
      ),
      boxShadow: AppShadows.surface(brightness),
    );
  }

  static BoxDecoration heroDecoration(
    ColorScheme scheme,
    Brightness brightness, {
    Color? accent,
  }) {
    final base = accent ?? scheme.primary;
    final end = Color.lerp(base, Colors.black, 0.38) ?? base;
    return BoxDecoration(
      gradient: LinearGradient(
        begin: AlignmentDirectional.topStart,
        end: AlignmentDirectional.bottomEnd,
        colors: [base, end],
      ),
      borderRadius: AppRadius.surface,
      border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
      boxShadow: AppShadows.surface(brightness),
    );
  }
}

class AppTheme {
  static SnackBarThemeData _snackBarTheme({
    required Color backgroundColor,
    required Color foregroundColor,
    required Color borderColor,
    required Color actionColor,
    required Color disabledActionColor,
    required Color actionBackgroundColor,
    required TextStyle contentTextStyle,
  }) {
    return SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      insetPadding: const EdgeInsets.fromLTRB(
        AppSpacing.md,
        0,
        AppSpacing.md,
        AppSpacing.md,
      ),
      elevation: 0,
      backgroundColor: backgroundColor,
      contentTextStyle: contentTextStyle.copyWith(
        color: foregroundColor,
        fontSize: 13,
        fontWeight: FontWeight.w800,
        height: 1.32,
      ),
      actionTextColor: actionColor,
      disabledActionTextColor: disabledActionColor,
      actionBackgroundColor: actionBackgroundColor,
      disabledActionBackgroundColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: AppRadius.control,
        side: BorderSide(color: borderColor),
      ),
    );
  }

  static ThemeData light() {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: WatchCartConstants.primaryColor,
      brightness: Brightness.light,
    ).copyWith(
      brightness: Brightness.light,
      primary: const Color(0xFF2B6FF3),
      onPrimary: Colors.white,
      secondary: const Color(0xFF2B6FF3),
      onSecondary: Colors.white,
      secondaryContainer: const Color(0xFFEAF2FF),
      onSecondaryContainer: const Color(0xFF183F8F),
      surface: Colors.white,
      onSurface: const Color(0xFF191F2B),
      surfaceContainerHighest: const Color(0xFFF4F7FC),
      outline: const Color(0xFFE4EAF3),
    );
    final baseTextTheme = GoogleFonts.notoSansKrTextTheme();
    final textTheme = baseTextTheme.copyWith(
      headlineLarge: baseTextTheme.headlineLarge?.copyWith(
        fontSize: 30,
        fontWeight: FontWeight.w800,
        height: 1.22,
        color: const Color(0xFF111827),
      ),
      headlineMedium: baseTextTheme.headlineMedium?.copyWith(
        fontSize: 26,
        fontWeight: FontWeight.w800,
        height: 1.24,
        color: const Color(0xFF111827),
      ),
      headlineSmall: baseTextTheme.headlineSmall?.copyWith(
        fontSize: 24,
        fontWeight: FontWeight.w800,
        height: 1.24,
        color: const Color(0xFF111827),
      ),
      titleLarge: baseTextTheme.titleLarge?.copyWith(
        fontSize: 20,
        fontWeight: FontWeight.w700,
        color: const Color(0xFF111827),
      ),
      titleMedium: baseTextTheme.titleMedium?.copyWith(
        fontSize: 16,
        fontWeight: FontWeight.w700,
        color: const Color(0xFF1F2937),
      ),
      bodyLarge: baseTextTheme.bodyLarge?.copyWith(
        fontSize: 16,
        fontWeight: FontWeight.w500,
        color: const Color(0xFF1F2937),
      ),
      bodyMedium: baseTextTheme.bodyMedium?.copyWith(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        color: const Color(0xFF374151),
      ),
      bodySmall: baseTextTheme.bodySmall?.copyWith(
        fontSize: 13,
        fontWeight: FontWeight.w500,
        color: const Color(0xFF6B7280),
      ),
    );

    return ThemeData(
      brightness: Brightness.light,
      colorScheme: colorScheme,
      useMaterial3: true,
      scaffoldBackgroundColor: const Color(0xFFF6F8FC),
      textTheme: textTheme,
      splashFactory: InkRipple.splashFactory,
      snackBarTheme: _snackBarTheme(
        backgroundColor: const Color(0xFF172033),
        foregroundColor: Colors.white,
        borderColor: Colors.white.withValues(alpha: 0.10),
        actionColor: const Color(0xFFB9D4FF),
        disabledActionColor: Colors.white.withValues(alpha: 0.42),
        actionBackgroundColor: Colors.white.withValues(alpha: 0.10),
        contentTextStyle: textTheme.bodyMedium ?? const TextStyle(),
      ),
      iconButtonTheme: IconButtonThemeData(
        style: ButtonStyle(
          overlayColor: WidgetStateProperty.all(
            colorScheme.primary.withAlpha(26),
          ),
          splashFactory: InkRipple.splashFactory,
        ),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: colorScheme.primary,
        foregroundColor: Colors.white,
        splashColor: Colors.white.withAlpha(38),
        shape: RoundedRectangleBorder(borderRadius: AppRadius.control),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        foregroundColor: const Color(0xFF111827),
        iconTheme: const IconThemeData(color: Color(0xFF111827)),
        actionsIconTheme: const IconThemeData(color: Color(0xFF111827)),
        systemOverlayStyle: SystemUiOverlayStyle.dark.copyWith(
          statusBarColor: Colors.transparent,
          systemNavigationBarColor: const Color(0xFFF6F8FC),
          systemNavigationBarIconBrightness: Brightness.dark,
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: ButtonStyle(
          foregroundColor: WidgetStateProperty.all(colorScheme.secondary),
          overlayColor: WidgetStateProperty.all(
            colorScheme.secondary.withAlpha(16),
          ),
          splashFactory: InkRipple.splashFactory,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: colorScheme.primary,
          side: BorderSide(color: colorScheme.outline),
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: AppRadius.control,
          ),
          minimumSize: const Size(0, AppSizes.primaryButtonHeight),
        ).copyWith(
          overlayColor: WidgetStateProperty.all(
            colorScheme.primary.withAlpha(16),
          ),
          splashFactory: InkRipple.splashFactory,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          elevation: 0,
          foregroundColor: Colors.white,
          backgroundColor: colorScheme.primary,
          shape: RoundedRectangleBorder(
            borderRadius: AppRadius.control,
          ),
          minimumSize: const Size.fromHeight(AppSizes.primaryButtonHeight),
        ).copyWith(
          overlayColor: WidgetStateProperty.all(Colors.white.withAlpha(28)),
          splashFactory: InkRipple.splashFactory,
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          elevation: 0,
          foregroundColor: Colors.white,
          backgroundColor: colorScheme.primary,
          shape: RoundedRectangleBorder(
            borderRadius: AppRadius.control,
          ),
          minimumSize: const Size.fromHeight(AppSizes.primaryButtonHeight),
        ).copyWith(
          overlayColor: WidgetStateProperty.all(Colors.white.withAlpha(28)),
          splashFactory: InkRipple.splashFactory,
        ),
      ),
      cardTheme: CardThemeData(
        color: Colors.white,
        elevation: 0,
        shadowColor: const Color(0x14111F3C),
        shape: RoundedRectangleBorder(
          borderRadius: AppRadius.surface,
          side: BorderSide(color: colorScheme.outline),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFFF8FAFD),
        hintStyle: const TextStyle(color: Color(0xFF94A3B8)),
        labelStyle: const TextStyle(color: Color(0xFF475569)),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 14,
        ),
        border: OutlineInputBorder(
          borderRadius: AppRadius.control,
          borderSide: BorderSide(color: colorScheme.outline),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: AppRadius.control,
          borderSide: BorderSide(color: colorScheme.outline),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: AppRadius.control,
          borderSide: BorderSide(color: colorScheme.primary, width: 1.5),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: Colors.white,
        indicatorColor: colorScheme.primary.withAlpha(24),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const TextStyle(fontSize: 12, fontWeight: FontWeight.w700);
          }
          return const TextStyle(fontSize: 12, fontWeight: FontWeight.w600);
        }),
      ),
      radioTheme: RadioThemeData(
        fillColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.disabled)) {
            return const Color(0xFFB8C4DD);
          }
          if (states.contains(WidgetState.selected)) {
            return colorScheme.primary;
          }
          return const Color(0xFF6D7FA3);
        }),
      ),
    );
  }

  static ThemeData dark() {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: WatchCartConstants.primaryColor,
      brightness: Brightness.dark,
    ).copyWith(
      brightness: Brightness.dark,
      surface: const Color(0xFF1B1F2A),
      onSurface: const Color(0xFFF2F5FA),
      outline: const Color(0xFF4A556D),
      surfaceContainerHighest: const Color(0xFF2A3040),
    );
    final baseTextTheme = GoogleFonts.notoSansKrTextTheme(
      ThemeData.dark().textTheme,
    );
    final textTheme = baseTextTheme.apply(
      bodyColor: const Color(0xFFF2F5FA),
      displayColor: const Color(0xFFF2F5FA),
    );

    return ThemeData(
      brightness: Brightness.dark,
      colorScheme: colorScheme,
      useMaterial3: true,
      scaffoldBackgroundColor: const Color(0xFF0F131A),
      textTheme: textTheme,
      splashFactory: InkRipple.splashFactory,
      snackBarTheme: _snackBarTheme(
        backgroundColor: const Color(0xFF252D3B),
        foregroundColor: const Color(0xFFF4F7FB),
        borderColor: const Color(0xFF465166),
        actionColor: const Color(0xFFB9D4FF),
        disabledActionColor: const Color(0xFF808A9B),
        actionBackgroundColor: Colors.white.withValues(alpha: 0.10),
        contentTextStyle: textTheme.bodyMedium ?? const TextStyle(),
      ),
      iconButtonTheme: IconButtonThemeData(
        style: ButtonStyle(
          overlayColor: WidgetStateProperty.all(Colors.white.withAlpha(28)),
          splashFactory: InkRipple.splashFactory,
        ),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: colorScheme.primary,
        foregroundColor: Colors.black,
        splashColor: Colors.white.withAlpha(36),
        shape: RoundedRectangleBorder(borderRadius: AppRadius.control),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        foregroundColor: const Color(0xFFF2F5FA),
        iconTheme: const IconThemeData(color: Color(0xFFF2F5FA)),
        actionsIconTheme: const IconThemeData(color: Color(0xFFF2F5FA)),
        systemOverlayStyle: SystemUiOverlayStyle.light.copyWith(
          statusBarColor: Colors.transparent,
          systemNavigationBarColor: const Color(0xFF0F131A),
          systemNavigationBarIconBrightness: Brightness.light,
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: ButtonStyle(
          overlayColor: WidgetStateProperty.all(Colors.white.withAlpha(12)),
          splashFactory: InkRipple.splashFactory,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: ButtonStyle(
          overlayColor: WidgetStateProperty.all(Colors.white.withAlpha(24)),
          splashFactory: InkRipple.splashFactory,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ButtonStyle(
          overlayColor: WidgetStateProperty.all(Colors.white.withAlpha(30)),
          splashFactory: InkRipple.splashFactory,
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          shape: RoundedRectangleBorder(
            borderRadius: AppRadius.control,
          ),
        ).copyWith(
          overlayColor: WidgetStateProperty.all(Colors.white.withAlpha(30)),
          splashFactory: InkRipple.splashFactory,
        ),
      ),
      cardTheme: CardThemeData(
        color: const Color(0xFF1C2433),
        elevation: 1,
        shape: RoundedRectangleBorder(borderRadius: AppRadius.surface),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFF242D3D),
        hintStyle: const TextStyle(color: Color(0xFFB6C0D3)),
        labelStyle: const TextStyle(color: Color(0xFFD2DAEA)),
        border: OutlineInputBorder(
          borderRadius: AppRadius.control,
          borderSide: const BorderSide(color: Color(0xFF4A556D)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: AppRadius.control,
          borderSide: const BorderSide(color: Color(0xFF4A556D)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: AppRadius.control,
          borderSide: BorderSide(color: colorScheme.primary, width: 1.6),
        ),
      ),
      radioTheme: RadioThemeData(
        fillColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.disabled)) {
            return const Color(0xFF5E6678);
          }
          if (states.contains(WidgetState.selected)) {
            return colorScheme.primary;
          }
          return const Color(0xFFACB6CA);
        }),
      ),
    );
  }
}
