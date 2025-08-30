import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../services/auth_service.dart';
import '../../models/user.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final AuthService _authService = AuthService();
  User? currentUser;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
  }

  Future<void> _loadUserProfile() async {
    try {
      // TODO: Get current user from auth service
      // For now, using mock data
      setState(() {
        currentUser = User(
          id: '1',
          name: 'John Doe',
          email: 'john.doe@example.com',
          role: UserRole.citizen,
          joinedDate: DateTime.now().subtract(const Duration(days: 90)),
          points: 1250,
          level: 5,
          avatarUrl: null,
          totalReports: 23,
          verifiedReports: 18,
          badges: ['Early Adopter', 'Mangrove Guardian', 'Pollution Fighter'],
        );
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading profile: $e')),
        );
      }
    }
  }

  Future<void> _handleLogout() async {
    final shouldLogout = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Logout'),
          ),
        ],
      ),
    );

    if (shouldLogout == true) {
      await _authService.logout();
      if (mounted) {
        context.go('/login');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (currentUser == null) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('No user data available'),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => context.go('/login'),
                child: const Text('Login'),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 280,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Theme.of(context).primaryColor,
                      Theme.of(context).primaryColor.withOpacity(0.7),
                    ],
                  ),
                ),
                child: SafeArea(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Avatar
                      CircleAvatar(
                        radius: 50,
                        backgroundColor: Colors.white,
                        child: currentUser!.avatarUrl != null
                            ? ClipOval(
                                child: Image.network(
                                  currentUser!.avatarUrl!,
                                  fit: BoxFit.cover,
                                ),
                              )
                            : Text(
                                currentUser!.name[0].toUpperCase(),
                                style: const TextStyle(
                                  fontSize: 40,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                      ),
                      const SizedBox(height: 16),
                      // Name
                      Text(
                        currentUser!.name,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      // Email
                      Text(
                        currentUser!.email,
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.9),
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 16),
                      // Stats Row
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          _buildStatItem('Points', currentUser!.points.toString()),
                          _buildStatItem('Level', currentUser!.level.toString()),
                          _buildStatItem('Reports', currentUser!.totalReports.toString()),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Progress Section
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Level Progress',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Text('Level ${currentUser!.level}'),
                              const Spacer(),
                              Text('Level ${currentUser!.level + 1}'),
                            ],
                          ),
                          const SizedBox(height: 8),
                          LinearProgressIndicator(
                            value: 0.65, // TODO: Calculate actual progress
                            backgroundColor: Colors.grey[300],
                            minHeight: 8,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '${currentUser!.points} / ${(currentUser!.level + 1) * 300} points',
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Badges Section
                  if (currentUser!.badges.isNotEmpty) ...[
                    const Text(
                      'Badges',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      height: 100,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: currentUser!.badges.length,
                        itemBuilder: (context, index) {
                          return Container(
                            width: 80,
                            margin: const EdgeInsets.only(right: 12),
                            child: Column(
                              children: [
                                Container(
                                  width: 60,
                                  height: 60,
                                  decoration: BoxDecoration(
                                    color: Theme.of(context).primaryColor.withOpacity(0.1),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    _getBadgeIcon(currentUser!.badges[index]),
                                    color: Theme.of(context).primaryColor,
                                    size: 30,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  currentUser!.badges[index],
                                  style: const TextStyle(fontSize: 10),
                                  textAlign: TextAlign.center,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],

                  // Statistics Card
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Statistics',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 16),
                          _buildStatRow('Total Reports', currentUser!.totalReports.toString()),
                          _buildStatRow('Verified Reports', currentUser!.verifiedReports.toString()),
                          _buildStatRow('Success Rate', 
                              currentUser!.totalReports != null && currentUser!.totalReports! > 0
                                  ? '${((currentUser!.verifiedReports! / currentUser!.totalReports!) * 100).toStringAsFixed(1)}%'
                                  : 'N/A'),
                          _buildStatRow('Member Since', 
                              '${DateTime.now().difference(currentUser!.joinDate ?? currentUser!.joinedDate).inDays} days'),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Settings Section
                  Card(
                    child: Column(
                      children: [
                        ListTile(
                          leading: const Icon(Icons.person),
                          title: const Text('Edit Profile'),
                          trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                          onTap: () {
                            // TODO: Navigate to edit profile
                          },
                        ),
                        const Divider(height: 1),
                        ListTile(
                          leading: const Icon(Icons.notifications),
                          title: const Text('Notifications'),
                          trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                          onTap: () {
                            // TODO: Navigate to notifications settings
                          },
                        ),
                        const Divider(height: 1),
                        ListTile(
                          leading: const Icon(Icons.security),
                          title: const Text('Privacy & Security'),
                          trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                          onTap: () {
                            // TODO: Navigate to privacy settings
                          },
                        ),
                        const Divider(height: 1),
                        ListTile(
                          leading: const Icon(Icons.help),
                          title: const Text('Help & Support'),
                          trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                          onTap: () {
                            // TODO: Navigate to help
                          },
                        ),
                        const Divider(height: 1),
                        ListTile(
                          leading: const Icon(Icons.logout, color: Colors.red),
                          title: const Text('Logout', style: TextStyle(color: Colors.red)),
                          onTap: _handleLogout,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withOpacity(0.8),
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  Widget _buildStatRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              color: Colors.grey[600],
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  IconData _getBadgeIcon(String badge) {
    switch (badge) {
      case 'Early Adopter':
        return Icons.star;
      case 'Mangrove Guardian':
        return Icons.shield;
      case 'Pollution Fighter':
        return Icons.warning;
      default:
        return Icons.military_tech;
    }
  }
}
