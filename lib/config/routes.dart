import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../screens/login_screen.dart';
import '../screens/home_screen.dart';
import '../screens/new_test_screen.dart';
import '../screens/test_results_screen.dart';
import '../screens/history_screen.dart';
import '../screens/profile_screen.dart';
import '../screens/dietary_screen.dart';
import '../screens/image_analysis_screen.dart';

final routerConfig = GoRouter(
  initialLocation: '/login',
  redirect: (context, state) {
    // Add authentication redirect logic here
    return null;
  },
  routes: [
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
            final testId = state.pathParameters['testId'];
            return TestResultsScreen(testId: testId);
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
          builder: (context, state) => const DietaryRecommendationsScreen(),
        ),
        GoRoute(
          path: 'image-analysis',
          name: 'imageAnalysis',
          builder: (context, state) => const ImageAnalysisScreen(),
        ),
      ],
    ),
  ],
);
