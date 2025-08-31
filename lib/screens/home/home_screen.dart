import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:geolocator/geolocator.dart';

import '../../blocs/auth/auth_bloc.dart';
import '../../core/theme.dart';
import '../../services/location_service.dart';
import '../../services/dashboard_service.dart';
import '../../widgets/dashboard_card.dart';
import '../../widgets/recent_incidents_widget.dart';
import '../../widgets/mangrove_health_widget.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final LocationService _locationService = LocationService();
  final DashboardService _dashboardService = DashboardService();
  Position? _currentPosition;
  String _greeting = 'Good morning';
  Map<String, dynamic>? _dashboardData;
  bool _isLoadingDashboard = true;

  @override
  void initState() {
    super.initState();
    _setGreeting();
    _getCurrentLocation();
    _loadDashboardData();
  }

  void _setGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) {
      _greeting = 'Good morning';
    } else if (hour < 17) {
      _greeting = 'Good afternoon';
    } else {
      _greeting = 'Good evening';
    }
  }

  Future<void> _getCurrentLocation() async {
    try {
      final position = await _locationService.getCurrentPosition();
      if (position != null) {
        setState(() {
          _currentPosition = position;
        });
      }
    } catch (e) {
      print('Error getting location: $e');
    }
  }

  Future<void> _loadDashboardData() async {
    try {
      setState(() {
        _isLoadingDashboard = true;
      });
      
      final data = await _dashboardService.getDashboardData();
      setState(() {
        _dashboardData = data;
        _isLoadingDashboard = false;
      });
    } catch (e) {
      print('Error loading dashboard data: $e');
      setState(() {
        _isLoadingDashboard = false;
      });
    }
  }

  String _formatNumber(int number) {
    if (number >= 1000000) {
      return '${(number / 1000000).toStringAsFixed(1)}M';
    } else if (number >= 1000) {
      return '${(number / 1000).toStringAsFixed(1)}k';
    }
    return number.toString();
  }

  String _formatArea(double area) {
    if (area >= 1000) {
      return '${(area / 1000).toStringAsFixed(1)}k ha';
    }
    return '${area.toStringAsFixed(0)} ha';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mangrove Watch'),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_outlined),
            onPressed: () {
              // TODO: Navigate to notifications
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Notifications coming soon')),
              );
            },
          ),
          BlocBuilder<AuthBloc, AuthState>(
            builder: (context, state) {
              if (state is AuthAuthenticated) {
                return PopupMenuButton(
                  icon: CircleAvatar(
                    backgroundColor: AppTheme.accentBlue,
                    child: Text(
                      state.user.name[0].toUpperCase(),
                      style: const TextStyle(color: Colors.white),
                    ),
                  ),
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: 'profile',
                      child: Row(
                        children: [
                          Icon(Icons.person),
                          SizedBox(width: 8),
                          Text('Profile'),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'settings',
                      child: Row(
                        children: [
                          Icon(Icons.settings),
                          SizedBox(width: 8),
                          Text('Settings'),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'logout',
                      child: Row(
                        children: [
                          Icon(Icons.logout),
                          SizedBox(width: 8),
                          Text('Logout'),
                        ],
                      ),
                    ),
                  ],
                  onSelected: (value) {
                    switch (value) {
                      case 'profile':
                        context.push('/profile');
                        break;
                      case 'settings':
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Settings coming soon')),
                        );
                        break;
                      case 'logout':
                        context.read<AuthBloc>().add(AuthLogoutRequested());
                        break;
                    }
                  },
                );
              }
              return const SizedBox();
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          // Refresh all data
          await Future.wait([
            _getCurrentLocation(),
            _loadDashboardData(),
          ]);
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: EdgeInsets.all(16.w),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Greeting and Welcome
              BlocBuilder<AuthBloc, AuthState>(
                builder: (context, state) {
                  if (state is AuthAuthenticated) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '$_greeting, ${state.user.name.split(' ').first}!',
                          style: AppTheme.headlineMedium.copyWith(
                            fontSize: 22.sp,
                            color: AppTheme.primaryGreen,
                          ),
                        ),
                        SizedBox(height: 4.h),
                        Text(
                          'Let\'s protect mangroves together',
                          style: AppTheme.bodyMedium.copyWith(fontSize: 14.sp),
                        ),
                      ],
                    );
                  }
                  return const SizedBox();
                },
              ),
              
              SizedBox(height: 24.h),
              
              // Quick Actions
              Text(
                'Quick Actions',
                style: AppTheme.titleLarge.copyWith(fontSize: 18.sp),
              ),
              SizedBox(height: 16.h),
              
              Row(
                children: [
                  Expanded(
                    child: _QuickActionCard(
                      title: 'Report Incident',
                      icon: Icons.report_problem,
                      color: AppTheme.warningRed,
                      onTap: () => context.push('/report'),
                    ),
                  ),
                  SizedBox(width: 12.w),
                  Expanded(
                    child: _QuickActionCard(
                      title: 'Detect Mangrove',
                      icon: Icons.nature,
                      color: AppTheme.accentBlue,
                      onTap: () => context.push('/detection'),
                    ),
                  ),
                ],
              ),
              
              SizedBox(height: 12.h),
              
              Row(
                children: [
                  Expanded(
                    child: _QuickActionCard(
                      title: 'View Map',
                      icon: Icons.map,
                      color: AppTheme.primaryGreen,
                      onTap: () => context.push('/map'),
                    ),
                  ),
                  SizedBox(width: 12.w),
                  Expanded(
                    child: _QuickActionCard(
                      title: 'Leaderboard',
                      icon: Icons.leaderboard,
                      color: AppTheme.secondaryGreen,
                      onTap: () => context.push('/leaderboard'),
                    ),
                  ),
                ],
              ),
              
              SizedBox(height: 24.h),
              
              // Current Location Mangrove Health
              if (_currentPosition != null) ...[
                Text(
                  'Mangrove Health Near You',
                  style: AppTheme.titleLarge.copyWith(fontSize: 18.sp),
                ),
                SizedBox(height: 16.h),
                MangroveHealthWidget(
                  latitude: _currentPosition!.latitude,
                  longitude: _currentPosition!.longitude,
                ),
                SizedBox(height: 24.h),
              ],
              
              // Dashboard Statistics
              Row(
                children: [
                  Text(
                    'Community Impact',
                    style: AppTheme.titleLarge.copyWith(fontSize: 18.sp),
                  ),
                  const Spacer(),
                  if (_dashboardData != null && _dashboardData!['is_mock'] == true)
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 2.h),
                      decoration: BoxDecoration(
                        color: Colors.orange.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.orange.withOpacity(0.3)),
                      ),
                      child: Text(
                        'Demo Data',
                        style: TextStyle(
                          fontSize: 10.sp,
                          color: Colors.orange[700],
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                ],
              ),
              SizedBox(height: 16.h),
              
              if (_isLoadingDashboard)
                const Center(
                  child: CircularProgressIndicator(),
                )
              else if (_dashboardData != null) ...[
                Row(
                  children: [
                    Expanded(
                      child: DashboardCard(
                        title: 'Total Reports',
                        value: _formatNumber(_dashboardData!['total_reports'] ?? 0),
                        icon: Icons.report,
                        trend: '+${(_dashboardData!['growth_rates']?['reports'] ?? 0.0).toStringAsFixed(1)}%',
                        trendUp: (_dashboardData!['growth_rates']?['reports'] ?? 0.0) > 0,
                      ),
                    ),
                    SizedBox(width: 12.w),
                    Expanded(
                      child: DashboardCard(
                        title: 'Verified',
                        value: _formatNumber(_dashboardData!['verified_reports'] ?? 0),
                        icon: Icons.verified,
                        trend: '+${(_dashboardData!['growth_rates']?['verification'] ?? 0.0).toStringAsFixed(1)}%',
                        trendUp: (_dashboardData!['growth_rates']?['verification'] ?? 0.0) > 0,
                      ),
                    ),
                  ],
                ),
                
                SizedBox(height: 12.h),
                
                Row(
                  children: [
                    Expanded(
                      child: DashboardCard(
                        title: 'Active Users',
                        value: _formatNumber(_dashboardData!['active_users'] ?? 0),
                        icon: Icons.people,
                        trend: '+${(_dashboardData!['growth_rates']?['users'] ?? 0.0).toStringAsFixed(1)}%',
                        trendUp: (_dashboardData!['growth_rates']?['users'] ?? 0.0) > 0,
                      ),
                    ),
                    SizedBox(width: 12.w),
                    Expanded(
                      child: DashboardCard(
                        title: 'Areas Protected',
                        value: _formatArea(_dashboardData!['protected_area_ha'] ?? 0.0),
                        icon: Icons.forest,
                        trend: '+${(_dashboardData!['growth_rates']?['protected_area'] ?? 0.0).toStringAsFixed(1)}%',
                        trendUp: (_dashboardData!['growth_rates']?['protected_area'] ?? 0.0) > 0,
                      ),
                    ),
                  ],
                ),
              ] else
                Container(
                  height: 120.h,
                  child: const Center(
                    child: Text(
                      'Failed to load dashboard data',
                      style: TextStyle(color: Colors.grey),
                    ),
                  ),
                ),
              
              SizedBox(height: 24.h),
              
              // Recent Incidents
              Text(
                'Recent Incidents',
                style: AppTheme.titleLarge.copyWith(fontSize: 18.sp),
              ),
              SizedBox(height: 16.h),
              
              const RecentIncidentsWidget(),
              
              SizedBox(height: 24.h),
            ],
          ),
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        selectedItemColor: AppTheme.primaryGreen,
        unselectedItemColor: AppTheme.textSecondary,
        currentIndex: 0,
        onTap: (index) {
          switch (index) {
            case 0:
              // Already on home
              break;
            case 1:
              context.push('/map');
              break;
            case 2:
              context.push('/report');
              break;
            case 3:
              context.push('/leaderboard');
              break;
            case 4:
              context.push('/profile');
              break;
          }
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.map),
            label: 'Map',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.report),
            label: 'Report',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.leaderboard),
            label: 'Leaderboard',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push('/detection'),
        child: const Icon(Icons.nature),
      ),
    );
  }
}

class _QuickActionCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _QuickActionCard({
    required this.title,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: EdgeInsets.all(16.w),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              size: 32.w,
              color: color,
            ),
            SizedBox(height: 8.h),
            Text(
              title,
              style: TextStyle(
                fontSize: 12.sp,
                fontWeight: FontWeight.w600,
                color: color,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
