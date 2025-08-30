import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:permission_handler/permission_handler.dart';
import '../models/location_result.dart';

class LocationService {
  // Check if location services are enabled
  Future<bool> isLocationServiceEnabled() async {
    return await Geolocator.isLocationServiceEnabled();
  }

  // Open location settings
  Future<bool> openLocationSettings() async {
    return await Geolocator.openLocationSettings();
  }

  // Open app settings for permissions
  Future<bool> openAppPermissionSettings() async {
    return await openAppSettings();
  }

  // Request location permission with better handling
  Future<bool> requestLocationPermission() async {
    final permission = await Permission.location.request();
    return permission.isGranted || permission.isLimited;
  }

  // Check location permission status
  Future<LocationPermission> checkLocationPermission() async {
    return await Geolocator.checkPermission();
  }

  // Main method to get current position with proper error handling
  Future<LocationResult> getCurrentPositionWithStatus() async {
    try {
      // Step 1: Check if location services are enabled
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        return LocationResult(
          position: null,
          error: LocationError.servicesDisabled,
          message: 'Location services are disabled. Please enable them in your device settings.',
        );
      }

      // Step 2: Check location permissions
      LocationPermission permission = await Geolocator.checkPermission();
      
      if (permission == LocationPermission.denied) {
        // Request permission
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          return LocationResult(
            position: null,
            error: LocationError.permissionDenied,
            message: 'Location permission denied. Please grant permission to use this feature.',
          );
        }
      }

      if (permission == LocationPermission.deniedForever) {
        return LocationResult(
          position: null,
          error: LocationError.permissionDeniedForever,
          message: 'Location permissions are permanently denied. Please enable them in app settings.',
        );
      }

      // Step 3: Get current position
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 15),
      );

      return LocationResult(
        position: position,
        error: LocationError.none,
        message: 'Location retrieved successfully',
      );

    } catch (e) {
      print('Error getting location: $e');
      return LocationResult(
        position: null,
        error: LocationError.unknown,
        message: 'Failed to get location: ${e.toString()}',
      );
    }
  }

  // Backward compatible method
  Future<Position?> getCurrentPosition() async {
    final result = await getCurrentPositionWithStatus();
    return result.position;
  }

  Future<String?> getAddressFromCoordinates(double latitude, double longitude) async {
    try {
      List<Placemark> placemarks = await placemarkFromCoordinates(latitude, longitude);
      if (placemarks.isNotEmpty) {
        Placemark place = placemarks[0];
        return '${place.street}, ${place.locality}, ${place.administrativeArea}, ${place.country}';
      }
    } catch (e) {
      print('Error getting address: $e');
    }
    return null;
  }

  Future<List<Location>?> getCoordinatesFromAddress(String address) async {
    try {
      return await locationFromAddress(address);
    } catch (e) {
      print('Error getting coordinates: $e');
      return null;
    }
  }

  double calculateDistance(double lat1, double lon1, double lat2, double lon2) {
    return Geolocator.distanceBetween(lat1, lon1, lat2, lon2);
  }

  Stream<Position> getPositionStream() {
    return Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 10, // Update every 10 meters
      ),
    );
  }
}
