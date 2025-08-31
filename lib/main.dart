import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:provider/provider.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'core/app_router.dart';
import 'core/theme.dart';
import 'services/api_service.dart';
import 'services/location_service.dart';
import 'services/auth_service.dart';
import 'services/onnx_model_service.dart';
import 'blocs/auth/auth_bloc.dart';
import 'blocs/report/report_bloc.dart';
import 'blocs/leaderboard/leaderboard_bloc.dart';
import 'blocs/image_analysis/image_analysis_bloc.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Hive
  await Hive.initFlutter();

  runApp(const MangroveWatchApp());
}

class MangroveWatchApp extends StatelessWidget {
  const MangroveWatchApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider<ApiService>(create: (_) => ApiService()),
        Provider<LocationService>(create: (_) => LocationService()),
        Provider<AuthService>(create: (_) => AuthService()),
      ],
      child: MultiBlocProvider(
        providers: [
          BlocProvider<AuthBloc>(
            create: (context) => AuthBloc(context.read<AuthService>()),
          ),
          BlocProvider<ReportBloc>(
            create: (context) => ReportBloc(context.read<ApiService>()),
          ),
          BlocProvider<LeaderboardBloc>(
            create: (context) => LeaderboardBloc(context.read<ApiService>()),
          ),
          BlocProvider<ImageAnalysisBloc>(
            create: (context) => ImageAnalysisBloc(context.read<ApiService>()),
          ),
        ],
        child: ScreenUtilInit(
          designSize: const Size(375, 812),
          child: MaterialApp.router(
            title: 'Mangrove Watch',
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            routerConfig: AppRouter.router,
            debugShowCheckedModeBanner: false,
          ),
        ),
      ),
    );
  }
}
