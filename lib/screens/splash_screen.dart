import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:lottie/lottie.dart';

import '../blocs/auth/auth_bloc.dart';
import '../core/theme.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    // Check authentication status
    context.read<AuthBloc>().add(AuthCheckRequested());
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthBloc, AuthState>(
      listener: (context, state) {
        if (state is AuthAuthenticated) {
          context.go('/home');
        } else if (state is AuthUnauthenticated) {
          context.go('/login');
        } else if (state is AuthError) {
          context.go('/login');
        }
      },
      child: Scaffold(
        backgroundColor: AppTheme.primaryGreen,
        body: SafeArea(
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Logo
                Container(
                  width: 120,
                  height: 120,
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.forest,
                    size: 60,
                    color: AppTheme.primaryGreen,
                  ),
                ),
                const SizedBox(height: 32),
                
                // App Title
                const Text(
                  'Mangrove Watch',
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 8),
                
                // Subtitle
                const Text(
                  'Community Conservation Platform',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.white70,
                  ),
                ),
                const SizedBox(height: 48),
                
                // Loading indicator
                Container(
                  width: 100,
                  height: 100,
                  child: Lottie.asset(
                    'assets/animations/loading.json',
                    errorBuilder: (context, error, stackTrace) {
                      return const CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 24),
                
                // Loading text
                BlocBuilder<AuthBloc, AuthState>(
                  builder: (context, state) {
                    String loadingText = 'Initializing...';
                    
                    if (state is AuthLoading) {
                      loadingText = 'Checking authentication...';
                    } else if (state is AuthError) {
                      loadingText = 'Authentication error';
                    }
                    
                    return Text(
                      loadingText,
                      style: const TextStyle(
                        fontSize: 14,
                        color: Colors.white60,
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
