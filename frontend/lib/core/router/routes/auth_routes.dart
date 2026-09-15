import 'package:go_router/go_router.dart';
import 'package:freebay/core/router/app_routes.dart';
import 'package:freebay/core/router/route_helpers.dart';
import 'package:freebay/features/auth/presentation/pages/splash_page.dart';
import 'package:freebay/features/auth/presentation/pages/login_page.dart';
import 'package:freebay/features/auth/presentation/pages/register_page.dart';
import 'package:freebay/features/auth/presentation/pages/complete_profile_page.dart';
import 'package:freebay/features/auth/presentation/pages/password_recovery_page.dart';
import 'package:freebay/features/auth/presentation/pages/reset_password_page.dart';
import 'package:freebay/features/onboarding/presentation/pages/onboarding_page.dart';
import 'package:freebay/features/onboarding/presentation/pages/welcome_setup_page.dart';

final List<RouteBase> authRoutes = [
  GoRoute(
    path: AppRoutes.splash,
    builder: (context, state) => const SplashPage(),
  ),
  appSharedAxisHRoute(AppRoutes.login, (context, state) => const LoginPage()),
  appCupertinoRoute(
    AppRoutes.register,
    (context, state) => const RegisterPage(),
  ),
  appCupertinoRoute(
    AppRoutes.completeProfile,
    (context, state) => const CompleteProfilePage(),
  ),
  appCupertinoRoute(
    AppRoutes.recoverPassword,
    (context, state) => const PasswordRecoveryPage(),
  ),
  appCupertinoRoute(
    AppRoutes.resetPassword,
    (context, state) => ResetPasswordPage(
      token: state.uri.queryParameters['token'] ?? '',
      email: state.uri.queryParameters['email'] ?? '',
    ),
  ),
  appFadeRoute(
    AppRoutes.onboarding,
    (context, state) => const OnboardingPage(),
  ),
  appCupertinoRoute(
    AppRoutes.welcome,
    (context, state) => const WelcomeSetupPage(),
  ),
];
