import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../models/test_entry.dart';
import '../providers/auth_provider.dart';
import '../screens/admin_screen.dart';
import '../screens/dietary_screen.dart';
import '../screens/history_screen.dart';
import '../screens/home_screen.dart';
import '../screens/login_screen.dart';
import '../screens/new_test_screen.dart';
import '../screens/profile_screen.dart';
import '../screens/test_results_screen.dart';

GoRouter buildRouter(AuthProvider auth) {
  return GoRouter(
    initialLocation: '/',
    refreshListenable: auth,
    redirect: (context, state) {
      final location = state.matchedLocation;
      if (!auth.initialized) return location == '/' ? null : '/';
      if (!auth.isAuthenticated) return location == '/login' ? null : '/login';
      if (location == '/' || location == '/login') return '/home';
      return null;
    },
    routes: [
      GoRoute(
        path: '/',
        builder: (context, state) => const Scaffold(
          body: Center(child: CircularProgressIndicator()),
        ),
      ),
      GoRoute(
        path: '/login',
        name: 'login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/home',
        name: 'home',
        builder: (context, state) => const HomeScreen(),
        routes: [
          GoRoute(
            path: 'new-test',
            name: 'newTest',
            builder: (context, state) => const NewTestScreen(),
          ),
          GoRoute(
            path: 'results/:testId',
            name: 'testResults',
            builder: (context, state) {
              final extra = state.extra;
              return TestResultsScreen(
                testId: state.pathParameters['testId'],
                entry: extra is TestEntry ? extra : null,
              );
            },
          ),
          GoRoute(
            path: 'history',
            name: 'history',
            builder: (context, state) => const HistoryScreen(),
          ),
          GoRoute(
            path: 'profile',
            name: 'profile',
            builder: (context, state) => const ProfileScreen(),
          ),
          GoRoute(
            path: 'dietary',
            name: 'dietary',
            builder: (context, state) {
              final extra = state.extra;
              return DietaryRecommendationsScreen(entry: extra is TestEntry ? extra : null);
            },
          ),
          GoRoute(
            path: 'admin',
            name: 'admin',
            builder: (context, state) => const AdminScreen(),
          ),
        ],
      ),
    ],
  );
}
