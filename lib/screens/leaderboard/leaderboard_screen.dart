import 'package:flutter/material.dart';
import '../../models/user.dart';

class LeaderboardScreen extends StatefulWidget {
  const LeaderboardScreen({super.key});

  @override
  State<LeaderboardScreen> createState() => _LeaderboardScreenState();
}

class _LeaderboardScreenState extends State<LeaderboardScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<User> allTimeLeaders = [];
  List<User> monthlyLeaders = [];
  List<User> weeklyLeaders = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadLeaderboardData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadLeaderboardData() async {
    // TODO: Fetch actual data from API
    // Using mock data for now
    await Future.delayed(const Duration(seconds: 1));
    
    setState(() {
      allTimeLeaders = _generateMockUsers(20);
      monthlyLeaders = _generateMockUsers(15);
      weeklyLeaders = _generateMockUsers(10);
      isLoading = false;
    });
  }

  List<User> _generateMockUsers(int count) {
    return List.generate(count, (index) {
      return User(
        id: 'user_$index',
        name: _getRandomName(index),
        email: 'user$index@example.com',
        role: UserRole.citizen,
        joinedDate: DateTime.now().subtract(Duration(days: 30 * (index + 1))),
        points: (1000 - index * 50 + (index % 3) * 10),
        level: 10 - (index ~/ 2),
        avatarUrl: null,
        joinDate: DateTime.now().subtract(Duration(days: 30 * (index + 1))),
        totalReports: 50 - index,
        verifiedReports: 45 - index,
        badges: index < 3 ? ['Top Contributor', 'Elite Guardian'] : ['Active Member'],
      );
    });
  }

  String _getRandomName(int index) {
    final names = [
      'Sarah Johnson', 'Mike Chen', 'Emily Davis', 'James Wilson',
      'Maria Garcia', 'John Smith', 'Lisa Anderson', 'David Lee',
      'Jennifer Brown', 'Robert Taylor', 'Amanda White', 'Chris Martin',
      'Jessica Thompson', 'Daniel Moore', 'Ashley Jackson', 'Matthew Harris',
      'Olivia Clark', 'Andrew Lewis', 'Sophia Walker', 'Ryan Hall'
    ];
    return names[index % names.length];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Leaderboard'),
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'All Time'),
            Tab(text: 'This Month'),
            Tab(text: 'This Week'),
          ],
        ),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _buildLeaderboardList(allTimeLeaders),
                _buildLeaderboardList(monthlyLeaders),
                _buildLeaderboardList(weeklyLeaders),
              ],
            ),
    );
  }

  Widget _buildLeaderboardList(List<User> users) {
    return RefreshIndicator(
      onRefresh: _loadLeaderboardData,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(vertical: 8),
        itemCount: users.length,
        itemBuilder: (context, index) {
          final user = users[index];
          final isTopThree = index < 3;
          
          return Container(
            margin: EdgeInsets.symmetric(
              horizontal: isTopThree ? 12 : 8,
              vertical: isTopThree ? 6 : 4,
            ),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              gradient: isTopThree
                  ? LinearGradient(
                      colors: _getGradientColors(index),
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    )
                  : null,
              color: !isTopThree ? Colors.white : null,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(isTopThree ? 0.15 : 0.05),
                  blurRadius: isTopThree ? 10 : 5,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              leading: Stack(
                alignment: Alignment.center,
                children: [
                  CircleAvatar(
                    radius: 25,
                    backgroundColor: isTopThree 
                        ? Colors.white.withOpacity(0.9)
                        : Theme.of(context).primaryColor.withOpacity(0.1),
                    child: user.avatarUrl != null
                        ? ClipOval(
                            child: Image.network(
                              user.avatarUrl!,
                              fit: BoxFit.cover,
                            ),
                          )
                        : Text(
                            user.name[0].toUpperCase(),
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: isTopThree 
                                  ? _getGradientColors(index)[0]
                                  : Theme.of(context).primaryColor,
                            ),
                          ),
                  ),
                  if (isTopThree)
                    Positioned(
                      bottom: -2,
                      right: -2,
                      child: Container(
                        width: 20,
                        height: 20,
                        decoration: BoxDecoration(
                          color: _getMedalColor(index),
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2),
                        ),
                        child: Center(
                          child: Text(
                            '${index + 1}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
              title: Row(
                children: [
                  if (!isTopThree)
                    Container(
                      width: 30,
                      margin: const EdgeInsets.only(right: 8),
                      child: Text(
                        '#${index + 1}',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.grey[600],
                        ),
                      ),
                    ),
                  Expanded(
                    child: Text(
                      user.name,
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                        color: isTopThree ? Colors.white : Colors.black87,
                      ),
                    ),
                  ),
                  if (user.badges.isNotEmpty && index < 5)
                    Container(
                      margin: const EdgeInsets.only(left: 4),
                      child: Icon(
                        Icons.verified,
                        size: 16,
                        color: isTopThree ? Colors.white : Colors.blue,
                      ),
                    ),
                ],
              ),
              subtitle: Row(
                children: [
                  if (!isTopThree) const SizedBox(width: 38),
                  Icon(
                    Icons.eco,
                    size: 14,
                    color: isTopThree ? Colors.white70 : Colors.green,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '${user.totalReports} reports',
                    style: TextStyle(
                      fontSize: 12,
                      color: isTopThree ? Colors.white70 : Colors.grey[600],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Icon(
                    Icons.star,
                    size: 14,
                    color: isTopThree ? Colors.white70 : Colors.amber,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'Level ${user.level}',
                    style: TextStyle(
                      fontSize: 12,
                      color: isTopThree ? Colors.white70 : Colors.grey[600],
                    ),
                  ),
                ],
              ),
              trailing: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '${user.points}',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: isTopThree ? Colors.white : Theme.of(context).primaryColor,
                    ),
                  ),
                  Text(
                    'points',
                    style: TextStyle(
                      fontSize: 11,
                      color: isTopThree ? Colors.white70 : Colors.grey[600],
                    ),
                  ),
                ],
              ),
              onTap: () {
                _showUserDetails(user, index + 1);
              },
            ),
          );
        },
      ),
    );
  }

  List<Color> _getGradientColors(int index) {
    switch (index) {
      case 0:
        return [Colors.amber[600]!, Colors.orange[400]!];
      case 1:
        return [Colors.grey[600]!, Colors.blueGrey[400]!];
      case 2:
        return [Colors.brown[600]!, Colors.brown[400]!];
      default:
        return [Theme.of(context).primaryColor, Theme.of(context).primaryColor.withOpacity(0.7)];
    }
  }

  Color _getMedalColor(int index) {
    switch (index) {
      case 0:
        return Colors.amber[700]!;
      case 1:
        return Colors.grey[600]!;
      case 2:
        return Colors.brown[600]!;
      default:
        return Theme.of(context).primaryColor;
    }
  }

  void _showUserDetails(User user, int rank) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          height: MediaQuery.of(context).size.height * 0.6,
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(20),
              topRight: Radius.circular(20),
            ),
          ),
          child: Column(
            children: [
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(top: 12),
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      CircleAvatar(
                        radius: 40,
                        backgroundColor: Theme.of(context).primaryColor.withOpacity(0.1),
                        child: Text(
                          user.name[0].toUpperCase(),
                          style: TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).primaryColor,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        user.name,
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                        decoration: BoxDecoration(
                          color: _getMedalColor(rank - 1).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          'Rank #$rank',
                          style: TextStyle(
                            color: _getMedalColor(rank - 1),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          _buildStatColumn('Points', user.points.toString()),
                          _buildStatColumn('Level', user.level.toString()),
                          _buildStatColumn('Reports', user.totalReports.toString()),
                        ],
                      ),
                      const SizedBox(height: 24),
                      if (user.badges.isNotEmpty) ...[
                        const Text(
                          'Achievements',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 8,
                          children: user.badges.map((badge) {
                            return Chip(
                              label: Text(
                                badge,
                                style: const TextStyle(fontSize: 12),
                              ),
                              backgroundColor: Theme.of(context).primaryColor.withOpacity(0.1),
                            );
                          }).toList(),
                        ),
                      ],
                      const Spacer(),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () {
                            // TODO: Navigate to user profile
                            Navigator.pop(context);
                          },
                          child: const Text('View Full Profile'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStatColumn(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            color: Colors.grey[600],
            fontSize: 12,
          ),
        ),
      ],
    );
  }
}
