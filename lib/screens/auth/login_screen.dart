import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../blocs/auth/auth_bloc.dart';
import '../../core/theme.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isPasswordVisible = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: BlocListener<AuthBloc, AuthState>(
        listener: (context, state) {
          if (state is AuthAuthenticated) {
            context.go('/home');
          } else if (state is AuthError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: AppTheme.warningRed,
              ),
            );
          }
        },
        child: SafeArea(
          child: Padding(
            padding: EdgeInsets.all(24.w),
            child: Form(
              key: _formKey,
              child: Column(
                children: [
                  Expanded(
                    child: SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SizedBox(height: 60.h),
                          
                          // Logo and Title
                          Center(
                            child: Column(
                              children: [
                                Container(
                                  width: 80.w,
                                  height: 80.w,
                                  decoration: const BoxDecoration(
                                    color: AppTheme.primaryGreen,
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    Icons.forest,
                                    size: 40.w,
                                    color: Colors.white,
                                  ),
                                ),
                                SizedBox(height: 16.h),
                                Text(
                                  'Welcome Back',
                                  style: AppTheme.headlineLarge.copyWith(
                                    fontSize: 28.sp,
                                  ),
                                ),
                                SizedBox(height: 8.h),
                                Text(
                                  'Sign in to continue protecting mangroves',
                                  style: AppTheme.bodyMedium.copyWith(
                                    fontSize: 14.sp,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ),
                          ),
                          
                          SizedBox(height: 48.h),
                          
                          // Email Field
                          Text(
                            'Email',
                            style: AppTheme.titleLarge.copyWith(fontSize: 16.sp),
                          ),
                          SizedBox(height: 8.h),
                          TextFormField(
                            controller: _emailController,
                            keyboardType: TextInputType.emailAddress,
                            textInputAction: TextInputAction.next,
                            decoration: const InputDecoration(
                              hintText: 'Enter your email',
                              prefixIcon: Icon(Icons.email_outlined),
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please enter your email';
                              }
                              if (!RegExp(r'^[\\w-\\.]+@([\\w-]+\\.)+[\\w-]{2,4}$').hasMatch(value)) {
                                return 'Please enter a valid email';
                              }
                              return null;
                            },
                          ),
                          
                          SizedBox(height: 24.h),
                          
                          // Password Field
                          Text(
                            'Password',
                            style: AppTheme.titleLarge.copyWith(fontSize: 16.sp),
                          ),
                          SizedBox(height: 8.h),
                          TextFormField(
                            controller: _passwordController,
                            obscureText: !_isPasswordVisible,
                            textInputAction: TextInputAction.done,
                            decoration: InputDecoration(
                              hintText: 'Enter your password',
                              prefixIcon: const Icon(Icons.lock_outlined),
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _isPasswordVisible
                                      ? Icons.visibility_off
                                      : Icons.visibility,
                                ),
                                onPressed: () {
                                  setState(() {
                                    _isPasswordVisible = !_isPasswordVisible;
                                  });
                                },
                              ),
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please enter your password';
                              }
                              if (value.length < 6) {
                                return 'Password must be at least 6 characters';
                              }
                              return null;
                            },
                          ),
                          
                          SizedBox(height: 32.h),
                          
                          // Login Button
                          BlocBuilder<AuthBloc, AuthState>(
                            builder: (context, state) {
                              final isLoading = state is AuthLoading;
                              
                              return SizedBox(
                                width: double.infinity,
                                height: 48.h,
                                child: ElevatedButton(
                                  onPressed: isLoading ? null : _handleLogin,
                                  child: isLoading
                                      ? SizedBox(
                                          width: 20.w,
                                          height: 20.w,
                                          child: const CircularProgressIndicator(
                                            strokeWidth: 2,
                                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                          ),
                                        )
                                      : const Text('Sign In'),
                                ),
                              );
                            },
                          ),
                          
                          SizedBox(height: 24.h),
                          
                          // Forgot Password
                          Center(
                            child: TextButton(
                              onPressed: () {
                                // TODO: Implement forgot password
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Forgot password feature coming soon'),
                                  ),
                                );
                              },
                              child: const Text('Forgot Password?'),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  
                  // Register Link
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        "Don't have an account? ",
                        style: AppTheme.bodyMedium.copyWith(fontSize: 14.sp),
                      ),
                      TextButton(
                        onPressed: () => context.go('/register'),
                        child: Text(
                          'Sign Up',
                          style: TextStyle(
                            fontSize: 14.sp,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _handleLogin() {
    if (_formKey.currentState?.validate() ?? false) {
      context.read<AuthBloc>().add(
        AuthLoginRequested(
          email: _emailController.text.trim(),
          password: _passwordController.text,
        ),
      );
    }
  }
}
