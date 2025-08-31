import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../../services/location_service.dart';
import '../../services/gee_service.dart';
import '../../core/theme.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  final LocationService _locationService = LocationService();
  final GeeService _geeService = GeeService();
  final MapController _mapController = MapController();
  
  Position? _currentPosition;
  bool _isLoading = true;
  bool _backendAvailable = false;
  Map<String, dynamic>? _visualizationData;
  String _errorMessage = '';
  List<Marker> _mangroveMarkers = [];
  String? _geeMapUrl;

  @override
  void initState() {
    super.initState();
    _initializeMap();
  }

  Future<void> _initializeMap() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      print('[MapScreen] Initializing GEE map...');
      
      // Check backend health first
      _backendAvailable = await _geeService.checkBackendHealth();
      print('[MapScreen] Backend available: $_backendAvailable');
      
      // Get location with detailed status
      final locationResult = await _locationService.getCurrentPositionWithStatus();
      
      if (locationResult.isSuccess) {
        _currentPosition = locationResult.position;
        print('[MapScreen] Got user location: ${_currentPosition?.latitude}, ${_currentPosition?.longitude}');
      } else {
        print('[MapScreen] Location error: ${locationResult.message}');
        // Continue without location - we'll use default coordinates
      }
      
      // Try to load GEE visualization data
      try {
        await _loadGeeVisualization();
        print('[MapScreen] Successfully loaded GEE visualization data');
      } catch (e) {
        print('[MapScreen] GEE visualization failed, using static fallback: $e');
        // Set up mock data for the static fallback
        _visualizationData = {
          'layer_info': {
            'name': 'Mangrove Visualization (Offline Mode)',
            'description': 'Sample mangrove data visualization - Backend not available',
            'year': 2020,
            'resolution': '30m'
          },
          'center': {
            'latitude': _currentPosition?.latitude ?? -2.0164,
            'longitude': _currentPosition?.longitude ?? -44.5626
          },
          'statistics': {
            'mangrove_pixel_count': 5000.0,
            'ndvi_mean': 0.65,
            'area_analyzed_km2': 31415.93
          }
        };
        
        // Set up sample mangrove markers for static visualization
        _setupMangroveMarkers();
      }
      
      setState(() {
        _isLoading = false;
      });
      
    } catch (e) {
      print('[MapScreen] Critical error initializing map: $e');
      setState(() {
        _isLoading = false;
        _errorMessage = 'Failed to load mangrove data: ${e.toString()}';
      });
    }
  }


  Future<void> _loadGeeVisualization() async {
    try {
      print('[MapScreen] Loading GEE visualization...');
      
      // Get center coordinates (use user location if available, otherwise default)
      final centerLat = _currentPosition?.latitude ?? -2.0164;
      final centerLng = _currentPosition?.longitude ?? -44.5626;
      
      print('[MapScreen] Center coordinates: $centerLat, $centerLng');
      
      if (_backendAvailable) {
        // Get visualization data from the backend
        _visualizationData = await _geeService.getMangroveVisualizationData(
          centerLat: centerLat,
          centerLng: centerLng,
          zoom: 9,
        );
        
        print('[MapScreen] Got visualization data: ${_visualizationData?['layer_info']['name']}');
        
        // Extract tile URL template from GEE visualization data
        try {
          _geeMapUrl = _visualizationData?['tile_url_template'];
          if (_geeMapUrl != null) {
            print('[MapScreen] Got GEE tile URL template: $_geeMapUrl');
          } else {
            print('[MapScreen] No tile URL template in visualization data');
            _geeMapUrl = null;
          }
        } catch (e) {
          print('[MapScreen] Could not extract GEE tile URL: $e');
          _geeMapUrl = null;
        }
        
        // Setup real-time mangrove markers from GEE data
        await _setupGeeMangroveMarkers();
      } else {
        print('[MapScreen] Backend not available, using sample data');
        throw Exception('Backend not available');
      }
      
    } catch (e) {
      print('[MapScreen] Error in GEE visualization: $e');
      rethrow; // This will trigger the static fallback in _initializeMap
    }
  }


  List<Widget> _buildTitleWidgets() {
    List<Widget> widgets = [
      const Icon(Icons.forest, color: Colors.white),
      const SizedBox(width: 8),
      const Text('Mangrove Detection'),
    ];
    
    if (!_backendAvailable) {
      widgets.add(const SizedBox(width: 8));
      widgets.add(
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(
            color: Colors.orange,
            borderRadius: BorderRadius.circular(10),
          ),
          child: const Text(
            'SAMPLE DATA',
            style: TextStyle(fontSize: 10, color: Colors.white),
          ),
        ),
      );
    }
    
    return widgets;
  }

  Future<void> _setupGeeMangroveMarkers() async {
    print('[MapScreen] Setting up GEE-based mangrove markers...');
    
    List<Marker> markers = [];
    
    // Get mangrove locations from visualization data
    final mangroveLocations = _visualizationData?['mangrove_locations'] ?? 
                              _visualizationData?['known_mangrove_locations'] ?? [];
    
    print('[MapScreen] Found ${mangroveLocations.length} mangrove locations in data');
    
    if (mangroveLocations.isNotEmpty) {
      // Create markers for all mangrove locations
      for (var location in mangroveLocations) {
        final lat = (location['lat'] as num).toDouble();
        final lng = (location['lng'] as num).toDouble();
        final name = location['name'] as String? ?? 'Mangrove Location';
        final region = location['region'] as String? ?? 'Unknown';
        
        markers.add(
          Marker(
            point: LatLng(lat, lng),
            width: 30,
            height: 30,
            child: GestureDetector(
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('🌿 $name\n$region\n${lat.toStringAsFixed(4)}, ${lng.toStringAsFixed(4)}'),
                    duration: const Duration(seconds: 3),
                    backgroundColor: AppTheme.primaryGreen,
                  ),
                );
              },
              child: Container(
                decoration: BoxDecoration(
                  color: const Color(0xFFd40115),
                  borderRadius: BorderRadius.circular(15),
                  border: Border.all(color: Colors.white, width: 2),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.3),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.forest,
                  color: Colors.white,
                  size: 16,
                ),
              ),
            ),
          ),
        );
      }
    } else {
      // Fallback: create a marker at the center if no locations found
      final centerLat = _visualizationData?['center']['latitude'] ?? -2.0164;
      final centerLng = _visualizationData?['center']['longitude'] ?? -44.5626;
      
      markers.add(
        Marker(
          point: LatLng(centerLat, centerLng),
          width: 30,
          height: 30,
          child: GestureDetector(
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Real-time mangrove detection\n${centerLat.toStringAsFixed(4)}, ${centerLng.toStringAsFixed(4)}'),
                  duration: const Duration(seconds: 3),
                ),
              );
            },
            child: Container(
              decoration: BoxDecoration(
                color: const Color(0xFFd40115),
                borderRadius: BorderRadius.circular(15),
                border: Border.all(color: Colors.white, width: 2),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.3),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: const Icon(
                Icons.forest,
                color: Colors.white,
                size: 16,
              ),
            ),
          ),
        ),
      );
    }
    
    _mangroveMarkers = markers;
    print('[MapScreen] Created ${_mangroveMarkers.length} GEE-based markers');
  }
  
  void _setupMangroveMarkers() {
    print('[MapScreen] Setting up sample mangrove markers...');
    
    // Use comprehensive global mangrove locations for offline mode
    final mangroveLocations = [
      // Major mangrove areas worldwide
      {'name': 'Sundarbans, Bangladesh', 'lat': 22.0, 'lng': 89.5, 'region': 'Asia'},
      {'name': 'Amazon Delta, Brazil', 'lat': -1.0, 'lng': -49.3, 'region': 'South America'},
      {'name': 'Everglades, Florida', 'lat': 25.5, 'lng': -80.9, 'region': 'North America'},
      {'name': 'Mumbai Mangroves, India', 'lat': 19.0, 'lng': 72.8, 'region': 'Asia'},
      {'name': 'Jakarta Bay, Indonesia', 'lat': -6.2, 'lng': 106.8, 'region': 'Asia'},
      {'name': 'Chennai Coast, India', 'lat': 13.0, 'lng': 80.2, 'region': 'Asia'},
      {'name': 'Niger Delta, Nigeria', 'lat': 4.8, 'lng': 6.8, 'region': 'Africa'},
      {'name': 'Darwin Harbour, Australia', 'lat': -12.4, 'lng': 130.8, 'region': 'Oceania'},
      {'name': 'Cairns, Queensland', 'lat': -16.9, 'lng': 145.8, 'region': 'Oceania'},
      {'name': 'Gambia River Mangroves', 'lat': 13.5, 'lng': -16.0, 'region': 'Africa'},
      {'name': 'Irrawaddy Delta, Myanmar', 'lat': 16.0, 'lng': 94.8, 'region': 'Asia'},
      {'name': 'Can Gio, Vietnam', 'lat': 10.8, 'lng': 106.7, 'region': 'Asia'},
      {'name': 'Red Sea Mangroves, Egypt', 'lat': 25.3, 'lng': 35.0, 'region': 'Africa'},
      {'name': 'Bhitarkanika, Odisha', 'lat': 21.5, 'lng': 87.0, 'region': 'Asia'},
      {'name': 'Pichavaram, Tamil Nadu', 'lat': 11.4, 'lng': 79.8, 'region': 'Asia'},
      {'name': 'Kutch Mangroves, Gujarat', 'lat': 23.2, 'lng': 69.7, 'region': 'Asia'},
      {'name': 'Biscayne Bay, Florida', 'lat': 25.2, 'lng': -80.5, 'region': 'North America'},
      {'name': 'Yucatan Peninsula, Mexico', 'lat': 21.3, 'lng': -89.6, 'region': 'North America'},
      {'name': 'Zapata Swamp, Cuba', 'lat': 21.5, 'lng': -82.4, 'region': 'Caribbean'},
      {'name': 'Guinea-Bissau Mangroves', 'lat': 12.3, 'lng': -16.9, 'region': 'Africa'},
    ];
    
    _mangroveMarkers = mangroveLocations.map((location) {
      final lat = location['lat'] as double;
      final lng = location['lng'] as double;
      final name = location['name'] as String;
      
      return Marker(
        point: LatLng(lat, lng),
        width: 30,
        height: 30,
        child: GestureDetector(
          onTap: () {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('$name Mangroves (Sample Data)\n${lat.toStringAsFixed(2)}, ${lng.toStringAsFixed(2)}'),
                duration: const Duration(seconds: 3),
              ),
            );
          },
          child: Container(
            decoration: BoxDecoration(
              color: const Color(0xFFd40115),
              borderRadius: BorderRadius.circular(15),
              border: Border.all(color: Colors.white, width: 2),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.3),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: const Icon(
              Icons.forest,
              color: Colors.white,
              size: 16,
            ),
          ),
        ),
      );
    }).toList();
    
    print('[MapScreen] Created ${_mangroveMarkers.length} sample markers');
  }

  void _centerOnLocation() async {
    if (_currentPosition != null) {
      try {
        // Center the flutter_map on user location
        _mapController.move(
          LatLng(_currentPosition!.latitude, _currentPosition!.longitude), 
          12.0
        );
        
        // Reload GEE visualization for this location
        await _loadGeeVisualization();
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Centered on your location: ${_currentPosition!.latitude.toStringAsFixed(4)}, ${_currentPosition!.longitude.toStringAsFixed(4)}'),
            duration: const Duration(seconds: 2),
          ),
        );
      } catch (e) {
        print('[MapScreen] Error centering on location: $e');
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Location not available'),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }
  
  Widget _buildFlutterMap() {
    final centerLat = _currentPosition?.latitude ?? 
                      _visualizationData?['center']['latitude'] ?? 
                      -2.0164;
    final centerLng = _currentPosition?.longitude ?? 
                      _visualizationData?['center']['longitude'] ?? 
                      -44.5626;
    
    return FlutterMap(
      mapController: _mapController,
      options: MapOptions(
        initialCenter: LatLng(centerLat, centerLng),
        initialZoom: _backendAvailable ? 9.0 : 4.0,
        maxZoom: 18.0,
        minZoom: 2.0,
      ),
      children: [
        // Base map layer
        TileLayer(
          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
          userAgentPackageName: 'com.example.mangrove_detection',
          maxZoom: 18,
        ),
        
        // GEE overlay layer (if available)
        if (_geeMapUrl != null && _backendAvailable)
          TileLayer(
            urlTemplate: _geeMapUrl!,
            userAgentPackageName: 'com.example.mangrove_detection',
            maxZoom: 18,
            backgroundColor: Colors.transparent,
            tileBuilder: (context, tileWidget, tile) {
              // Ensure GEE tiles render with transparency
              return ColorFiltered(
                colorFilter: const ColorFilter.mode(
                  Colors.transparent,
                  BlendMode.dst,
                ),
                child: tileWidget,
              );
            },
          ),
        
        // Mangrove markers layer
        MarkerLayer(
          markers: [
            ..._mangroveMarkers,
            // User location marker
            if (_currentPosition != null)
              Marker(
                point: LatLng(_currentPosition!.latitude, _currentPosition!.longitude),
                width: 30,
                height: 30,
                child: Container(
                  decoration: BoxDecoration(
                    color: AppTheme.primaryGreen,
                    borderRadius: BorderRadius.circular(15),
                    border: Border.all(color: Colors.white, width: 2),
                  ),
                  child: const Icon(
                    Icons.my_location,
                    color: Colors.white,
                    size: 16,
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }

  void _showMangroveInfo() {
    if (_visualizationData == null) return;
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        maxChildSize: 0.9,
        minChildSize: 0.3,
        builder: (context, scrollController) => Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
          ),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryGreen.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.forest,
                      color: AppTheme.primaryGreen,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _visualizationData!['layer_info']['name'] ?? 'Mangrove Data',
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          _visualizationData!['layer_info']['description'] ?? 'Global mangrove coverage data',
                          style: TextStyle(color: Colors.grey[600]),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Expanded(
                child: ListView(
                  controller: scrollController,
                  children: [
                    _buildInfoCard(
                      'Dataset Information',
                      Icons.dataset,
                      [
                        _buildInfoRow('Year', _visualizationData!['layer_info']['year'].toString()),
                        _buildInfoRow('Resolution', _visualizationData!['layer_info']['resolution']),
                        _buildInfoRow('Source', 'Global Mangrove Watch'),
                      ],
                    ),
                    const SizedBox(height: 12),
                    _buildInfoCard(
                      'Current View Statistics',
                      Icons.analytics,
                      [
                        _buildInfoRow(
                          'Center Location',
                          '${_visualizationData!['center']['latitude'].toStringAsFixed(4)}, ${_visualizationData!['center']['longitude'].toStringAsFixed(4)}',
                        ),
                        _buildInfoRow(
                          'Mangrove Pixels',
                          '${_visualizationData!['statistics']['mangrove_pixel_count'].toStringAsFixed(0)}',
                        ),
                        _buildInfoRow(
                          'Average NDVI',
                          _visualizationData!['statistics']['ndvi_mean'].toStringAsFixed(3),
                        ),
                        _buildInfoRow(
                          'Analysis Area',
                          '${(_visualizationData!['statistics']['area_analyzed_km2']).toStringAsFixed(0)} km²',
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    _buildInfoCard(
                      'Legend',
                      Icons.legend_toggle,
                      [
                        _buildLegendRow('Mangrove Areas', const Color(0xFFd40115)),
                        _buildLegendRow('Water Bodies', Colors.blue),
                        _buildLegendRow('Other Vegetation', Colors.green),
                        _buildLegendRow('Land/Urban', Colors.grey),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoCard(String title, IconData icon, List<Widget> children) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 20, color: AppTheme.primaryGreen),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.w500,
                color: Colors.grey[700],
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.w400),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLegendRow(String label, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Container(
            width: 20,
            height: 20,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(4),
              border: Border.all(color: Colors.grey[300]!),
            ),
          ),
          const SizedBox(width: 12),
          Text(label),
        ],
      ),
    );
  }



  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: _buildTitleWidgets(),
        ),
        backgroundColor: AppTheme.primaryGreen,
        actions: [
          if (_visualizationData != null)
            IconButton(
              icon: const Icon(Icons.info_outline),
              onPressed: () {
                _showMangroveInfo();
              },
            ),
          IconButton(
            icon: const Icon(Icons.my_location),
            onPressed: _centerOnLocation,
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              _initializeMap();
            },
          ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(color: AppTheme.primaryGreen),
                  SizedBox(height: 16),
                  Text('Loading mangrove data...'),
                ],
              ),
            )
          : _errorMessage.isNotEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.error_outline,
                        size: 64,
                        color: Colors.red,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Error Loading Map',
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                      const SizedBox(height: 8),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 32),
                        child: Text(
                          _errorMessage,
                          textAlign: TextAlign.center,
                        ),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _initializeMap,
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
              )
              : Stack(
                  children: [
                    _buildFlutterMap(),
                    // Info overlay positioned on top of the map
                    Positioned(
                      top: 16,
                      right: 16,
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.9),
                          borderRadius: BorderRadius.circular(8),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (!_backendAvailable)
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: Colors.orange,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: const Text(
                                  'OFFLINE MODE',
                                  style: TextStyle(fontSize: 10, color: Colors.white, fontWeight: FontWeight.bold),
                                ),
                              )
                            else
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: AppTheme.primaryGreen,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: const Text(
                                  'REAL-TIME GEE',
                                  style: TextStyle(fontSize: 10, color: Colors.white, fontWeight: FontWeight.bold),
                                ),
                              ),
                            const SizedBox(height: 4),
                            const Text(
                              '🌿 Mangrove Detection',
                              style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              _backendAvailable ? 'Live GEE data' : 'Sample locations',
                              style: const TextStyle(fontSize: 10, color: Colors.grey),
                            ),
                          ],
                        ),
                      ),
                    ),
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

