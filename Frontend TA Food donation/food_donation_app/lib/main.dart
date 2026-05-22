import 'package:flutter/material.dart';

import 'pages/login_page.dart';
import 'pages/onboarding_page.dart';
import 'pages/register_page.dart';
import 'pages/splash_page.dart';
import 'theme/app_theme.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const FoodDonationApp());
}

class FoodDonationApp extends StatelessWidget {
  const FoodDonationApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'FoodShare',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      initialRoute: '/',
      routes: {
        '/': (_) => const SplashPage(),
        '/onboarding': (_) => const OnboardingPage(),
        '/login': (_) => const LoginPage(),
        '/register': (_) => const RegisterPage(),
      },
      builder: (context, child) {
        return _ResponsiveAppFrame(
          child: child ?? const SizedBox.shrink(),
        );
      },
    );
  }
}

class _ResponsiveAppFrame extends StatelessWidget {
  final Widget child;

  const _ResponsiveAppFrame({
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final double screenWidth = MediaQuery.of(context).size.width;
    final bool isDesktopWidth = screenWidth >= AppBreakpoints.desktopMinWidth;

    return ColoredBox(
      color: isDesktopWidth ? AppColors.webBackground : AppColors.background,
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(
            maxWidth: AppBreakpoints.maxContentWidth,
          ),
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: AppColors.background,
              boxShadow: isDesktopWidth ? AppShadows.webFrame : const [],
            ),
            child: child,
          ),
        ),
      ),
    );
  }
}