import 'package:go_router/go_router.dart';
import '../screens/splash_screen.dart';
import '../screens/auth/login_screen.dart';
import '../screens/auth/register_screen.dart';
import '../screens/home/home_screen.dart';
import '../screens/report/report_screen.dart';
import '../screens/report/camera_screen.dart';
import '../screens/profile/profile_screen.dart';
import '../screens/leaderboard/leaderboard_screen.dart';
import '../screens/map/map_screen.dart';
import '../screens/detection/mangrove_detection_screen.dart';
import '../screens/report/report_details_screen.dart';
import '../models/incident_report.dart';

class AppRouter {
  static final GoRouter router = GoRouter(
    initialLocation: '/',
    routes: [
      GoRoute(
        path: '/',
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/register',
        builder: (context, state) => const RegisterScreen(),
      ),
      GoRoute(
        path: '/home',
        builder: (context, state) => const HomeScreen(),
      ),
      GoRoute(
        path: '/report',
        builder: (context, state) => const ReportScreen(),
      ),
      GoRoute(
        path: '/camera',
        builder: (context, state) => const CameraScreen(),
      ),
      GoRoute(
        path: '/profile',
        builder: (context, state) => const ProfileScreen(),
      ),
      GoRoute(
        path: '/leaderboard',
        builder: (context, state) => const LeaderboardScreen(),
      ),
      GoRoute(
        path: '/map',
        builder: (context, state) => const MapScreen(),
      ),
      GoRoute(
        path: '/detection',
        builder: (context, state) => const MangroveDetectionScreen(),
      ),
      GoRoute(
        path: '/report-details',
        builder: (context, state) {
          final report = state.extra as IncidentReport;
          return ReportDetailsScreen(report: report);
        },
      ),
    ],
  );
}
