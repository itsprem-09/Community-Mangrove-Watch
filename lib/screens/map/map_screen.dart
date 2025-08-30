import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';

import '../../services/location_service.dart';
import '../../core/theme.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  final MapController _mapController = MapController();
  final LocationService _locationService = LocationService();
  Position? _currentPosition;
  List<Marker> _markers = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _initializeMap();
  }

  Future<void> _initializeMap() async {
    try {
      final position = await _locationService.getCurrentPosition();
      if (position != null) {
        setState(() {
          _currentPosition = position;
          _isLoading = false;
          _loadMarkers();
        });
      } else {
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading location: $e')),
        );
      }
    }
  }

  void _loadMarkers() {
    // TODO: Load actual incident markers from API
    // For now, using sample markers
    _markers = [
      if (_currentPosition != null)
        Marker(
          point: LatLng(_currentPosition!.latitude, _currentPosition!.longitude),
          width: 80,
          height: 80,
          child: const Icon(
            Icons.my_location,
            color: Colors.blue,
            size: 40,
          ),
        ),
      // Sample incident markers
      Marker(
        point: LatLng(
          _currentPosition!.latitude + 0.01,
          _currentPosition!.longitude + 0.01,
        ),
        width: 80,
        height: 80,
        child: GestureDetector(
          onTap: () => _showIncidentDetails('Pollution Detected'),
          child: const Icon(
            Icons.warning,
            color: Colors.red,
            size: 35,
          ),
        ),
      ),
      Marker(
        point: LatLng(
          _currentPosition!.latitude - 0.01,
          _currentPosition!.longitude + 0.01,
        ),
        width: 80,
        height: 80,
        child: GestureDetector(
          onTap: () => _showIncidentDetails('Illegal Logging'),
          child: const Icon(
            Icons.report_problem,
            color: Colors.orange,
            size: 35,
          ),
        ),
      ),
    ];
  }

  void _showIncidentDetails(String title) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            const Text('Reported 2 hours ago'),
            const SizedBox(height: 16),
            const Text(
              'Description: Signs of pollution detected in this area. Authorities have been notified.',
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                      // TODO: Navigate to incident details
                    },
                    child: const Text('View Details'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Close'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Incident Map'),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: () {
              // TODO: Show filter options
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Filter options coming soon')),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.my_location),
            onPressed: () {
              if (_currentPosition != null) {
                _mapController.move(
                  LatLng(_currentPosition!.latitude, _currentPosition!.longitude),
                  15,
                );
              }
            },
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : FlutterMap(
              mapController: _mapController,
              options: MapOptions(
                initialCenter: _currentPosition != null
                    ? LatLng(_currentPosition!.latitude, _currentPosition!.longitude)
                    : const LatLng(0, 0),
                initialZoom: 13,
                minZoom: 5,
                maxZoom: 18,
              ),
              children: [
                TileLayer(
                  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'com.example.mangrove',
                ),
                MarkerLayer(markers: _markers),
              ],
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push('/report'),
        backgroundColor: AppTheme.primaryGreen,
        child: const Icon(Icons.add_location_alt),
      ),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        selectedItemColor: AppTheme.primaryGreen,
        unselectedItemColor: AppTheme.textSecondary,
        currentIndex: 1,
        onTap: (index) {
          switch (index) {
            case 0:
              context.go('/home');
              break;
            case 1:
              // Already on map
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
    );
  }
}
