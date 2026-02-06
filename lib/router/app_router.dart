import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../models/plan_type.dart';
import '../providers/auth_provider.dart';
import '../pages/login_page.dart';
import '../pages/signup_page.dart';
import '../pages/forgot_password_page.dart';
import '../pages/dashboard_page.dart';

final goRouterProvider = Provider<GoRouter>((ref) {
  final auth = ref.watch(firebaseAuthProvider);

  return GoRouter(
    initialLocation: '/login',
    refreshListenable: GoRouterRefreshStream(auth.authStateChanges()),
    redirect: (context, state) {
      final isLoggedIn = auth.currentUser != null;

      final loc = state.matchedLocation;
      final isAuthRoute =
          loc == '/login' ||
              loc == '/signup-solo' ||
              loc == '/signup-five' ||
              loc == '/signup-nine' ||
              loc == '/forgot-password';

      if (!isLoggedIn && !isAuthRoute) return '/login';
      if (isLoggedIn && isAuthRoute) return '/dashboard';

      return null;
    },
    routes: [
      GoRoute(path: '/login', builder: (_, __) => const LoginPage()),

      GoRoute(
        path: '/signup-solo',
        builder: (_, __) => const SignupPage(planType: PlanType.solo),
      ),
      GoRoute(
        path: '/signup-five',
        builder: (_, __) => const SignupPage(planType: PlanType.five),
      ),
      GoRoute(
        path: '/signup-nine',
        builder: (_, __) => const SignupPage(planType: PlanType.nine),
      ),

      GoRoute(
        path: '/forgot-password',
        builder: (_, __) => const ForgotPasswordPage(),
      ),
      GoRoute(
        path: '/dashboard',
        builder: (_, __) => const DashboardPage(),
      ),
    ],
  );
});

class GoRouterRefreshStream extends ChangeNotifier {
  GoRouterRefreshStream(Stream<dynamic> stream) {
    _sub = stream.asBroadcastStream().listen((_) => notifyListeners());
  }

  late final StreamSubscription<dynamic> _sub;

  @override
  void dispose() {
    _sub.cancel();
    super.dispose();
  }
}