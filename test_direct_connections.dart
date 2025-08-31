import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;

void main() async {
  print('🔍 Testing Direct Backend Connections...\n');
  
  // Express Backend Tests (localhost:5000)
  print('📊 EXPRESS BACKEND (localhost:5000) - Auth, Incidents, Uploads, Email');
  await testEndpoint('http://localhost:5000/health', 'Express Health Check');
  
  // Python Backend Tests (localhost:8000)
  print('\n🐍 PYTHON BACKEND (localhost:8000) - AI/ML, GEE, Predictions');
  await testEndpoint('http://localhost:8000/health', 'Python Health Check');
  await testEndpoint('http://localhost:8000/', 'Python Root Info');
  await testEndpoint('http://localhost:8000/gee/mangrove-visualization', 'GEE Visualization');
  
  print('\n✅ Direct connection test completed!');
  print('\n📋 BACKEND ROUTING SUMMARY:');
  print('   Express (localhost:5000): Auth, Incidents, Uploads, Email');
  print('   Python (localhost:8000): AI/ML, GEE, Predictions, Analytics');
  
  exit(0);
}

Future<void> testEndpoint(String url, String description) async {
  try {
    print('   Testing: $description');
    print('   URL: $url');
    
    final response = await http.get(
      Uri.parse(url),
      headers: {'Content-Type': 'application/json'},
    ).timeout(Duration(seconds: 10));
    
    if (response.statusCode == 200) {
      print('   ✅ SUCCESS: ${response.statusCode}');
      
      // Try to parse JSON response
      try {
        final data = jsonDecode(response.body);
        if (data is Map && data.containsKey('status')) {
          print('   📊 Status: ${data['status']}');
        }
        if (data is Map && data.containsKey('service')) {
          print('   🏷️  Service: ${data['service']}');
        }
      } catch (e) {
        print('   📄 Response: ${response.body.substring(0, 100)}...');
      }
    } else {
      print('   ❌ FAILED: ${response.statusCode}');
    }
  } catch (e) {
    print('   ❌ ERROR: $e');
  }
  print('');
}
