import 'dart:convert';
import 'package:http/http.dart' as http;
import 'api_config.dart';

class DashboardService {
  static String get pythonUrl => ApiConfig.pythonBackendUrl;

  // Get dashboard analytics data
  Future<Map<String, dynamic>> getDashboardData() async {
    try {
      print('[DashboardService] Fetching dashboard analytics...');
      
      final response = await http.get(
        Uri.parse('$pythonUrl/analytics/dashboard'),
        headers: {'Content-Type': 'application/json'},
      ).timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          print('[DashboardService] Request timed out, using mock data');
          throw Exception('Dashboard request timeout');
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        print('[DashboardService] Received dashboard data: $data');
        return _validateDashboardData(data);
      } else {
        print('[DashboardService] Backend returned status: ${response.statusCode}');
        throw Exception('Backend error: ${response.statusCode}');
      }
    } catch (e) {
      print('[DashboardService] Failed to fetch dashboard data: $e');
      return _generateMockDashboardData();
    }
  }

  // Get community impact statistics
  Future<Map<String, dynamic>> getCommunityStats() async {
    try {
      final response = await http.get(
        Uri.parse('$pythonUrl/analytics/community-stats'),
        headers: {'Content-Type': 'application/json'},
      ).timeout(const Duration(seconds: 8));

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
      throw Exception('Failed to fetch community stats');
    } catch (e) {
      print('[DashboardService] Using mock community stats: $e');
      return _generateMockCommunityStats();
    }
  }

  // Get recent incidents with proper formatting
  Future<List<Map<String, dynamic>>> getRecentIncidents({int limit = 5}) async {
    try {
      final response = await http.get(
        Uri.parse('${ApiConfig.expressBackendUrl}/incidents?limit=$limit&sort=recent'),
        headers: {'Content-Type': 'application/json'},
      ).timeout(const Duration(seconds: 8));

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.cast<Map<String, dynamic>>();
      }
      throw Exception('Failed to fetch recent incidents');
    } catch (e) {
      print('[DashboardService] Using mock recent incidents: $e');
      return _generateMockRecentIncidents(limit);
    }
  }

  // Get user activity statistics
  Future<Map<String, dynamic>> getUserActivityStats() async {
    try {
      final response = await http.get(
        Uri.parse('$pythonUrl/analytics/user-activity'),
        headers: {'Content-Type': 'application/json'},
      ).timeout(const Duration(seconds: 8));

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
      throw Exception('Failed to fetch user activity');
    } catch (e) {
      print('[DashboardService] Using mock user activity: $e');
      return _generateMockUserActivity();
    }
  }

  // Validate dashboard data and ensure realistic values
  Map<String, dynamic> _validateDashboardData(Map<String, dynamic> data) {
    return {
      'total_reports': (data['total_reports'] ?? 0).toInt(),
      'verified_reports': (data['verified_reports'] ?? 0).toInt(),
      'active_users': (data['active_users'] ?? 0).toInt(),
      'protected_area_ha': (data['protected_area_ha'] ?? 0.0).toDouble(),
      'growth_rates': {
        'reports': data['growth_rates']?['reports'] ?? 0.0,
        'users': data['growth_rates']?['users'] ?? 0.0,
        'verification': data['growth_rates']?['verification'] ?? 0.0,
        'protected_area': data['growth_rates']?['protected_area'] ?? 0.0,
      },
      'is_mock': false,
    };
  }

  // Generate realistic mock dashboard data
  Map<String, dynamic> _generateMockDashboardData() {
    final now = DateTime.now();
    final seed = now.day + now.month * 31; // Changes daily
    final random = _PseudoRandom(seed);
    
    // Generate realistic numbers that grow over time
    final baseReports = 850 + (now.difference(DateTime(2024, 1, 1)).inDays * 2);
    final baseUsers = 320 + (now.difference(DateTime(2024, 1, 1)).inDays ~/ 3);
    
    return {
      'total_reports': baseReports + random.nextInt(50),
      'verified_reports': (baseReports * (0.75 + random.nextDouble() * 0.15)).toInt(),
      'active_users': baseUsers + random.nextInt(20),
      'protected_area_ha': 23500.0 + random.nextDouble() * 2000,
      'growth_rates': {
        'reports': 8.0 + random.nextDouble() * 8, // 8-16%
        'users': 12.0 + random.nextDouble() * 8, // 12-20%
        'verification': 5.0 + random.nextDouble() * 5, // 5-10%
        'protected_area': 3.0 + random.nextDouble() * 4, // 3-7%
      },
      'is_mock': true,
    };
  }

  // Generate mock community stats
  Map<String, dynamic> _generateMockCommunityStats() {
    final random = _PseudoRandom(DateTime.now().millisecondsSinceEpoch ~/ 86400000);
    
    return {
      'top_contributors': [
        {'name': 'EcoWarrior', 'reports': 127, 'verified': 98},
        {'name': 'GreenGuardian', 'reports': 89, 'verified': 76},
        {'name': 'MangroveHero', 'reports': 65, 'verified': 58},
      ],
      'this_month': {
        'new_reports': 45 + random.nextInt(20),
        'verifications': 38 + random.nextInt(15),
        'new_users': 23 + random.nextInt(10),
      },
      'is_mock': true,
    };
  }

  // Generate mock recent incidents
  List<Map<String, dynamic>> _generateMockRecentIncidents(int limit) {
    final incidents = <Map<String, dynamic>>[];
    final now = DateTime.now();
    final types = ['pollution', 'deforestation', 'coastal_erosion', 'illegal_fishing'];
    final severities = ['low', 'medium', 'high'];
    final locations = [
      {'name': 'Sundarbans Delta', 'lat': 21.9497, 'lng': 89.1833},
      {'name': 'Everglades National Park', 'lat': 25.2866, 'lng': -80.8987},
      {'name': 'Moreton Bay', 'lat': -27.1917, 'lng': 153.1167},
      {'name': 'Laguna de Términos', 'lat': 18.6500, 'lng': -91.8000},
    ];

    for (int i = 0; i < limit; i++) {
      final location = locations[i % locations.length];
      final random = _PseudoRandom(i + now.day);
      
      incidents.add({
        'id': 'mock_${i}_${now.millisecondsSinceEpoch}',
        'title': 'Incident at ${location['name']}',
        'description': 'Environmental concern reported in mangrove area',
        'type': types[i % types.length],
        'severity': severities[i % severities.length],
        'latitude': location['lat'],
        'longitude': location['lng'],
        'timestamp': now.subtract(Duration(hours: i * 6)).toIso8601String(),
        'status': i < 2 ? 'verified' : 'pending',
        'images': [],
        'userId': 'user_${i + 1}',
        'reporterName': 'Community Member ${i + 1}',
        'verificationCount': i < 2 ? 3 : 0,
      });
    }

    return incidents;
  }

  // Generate mock user activity
  Map<String, dynamic> _generateMockUserActivity() {
    final random = _PseudoRandom(DateTime.now().millisecondsSinceEpoch ~/ 3600000);
    
    return {
      'daily_active_users': 45 + random.nextInt(25),
      'weekly_active_users': 156 + random.nextInt(50),
      'monthly_active_users': 432 + random.nextInt(100),
      'reports_this_week': 28 + random.nextInt(15),
      'average_verification_time_hours': 12 + random.nextInt(12),
      'is_mock': true,
    };
  }
}

// Simple pseudo-random number generator
class _PseudoRandom {
  int _seed;
  
  _PseudoRandom(this._seed);
  
  double nextDouble() {
    _seed = (_seed * 1103515245 + 12345) & 0x7fffffff;
    return _seed / 0x7fffffff;
  }
  
  int nextInt(int max) {
    return (nextDouble() * max).floor();
  }
}
