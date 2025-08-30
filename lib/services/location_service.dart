import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:io' show Platform;
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
    try {
      // First check if location services are enabled
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        print('[LocationService] Location services are disabled');
        return false;
      }

      // Check current permission status
      LocationPermission permission = await Geolocator.checkPermission();
      print('[LocationService] Current permission status: $permission');

      if (permission == LocationPermission.denied) {
        // Request permission
        permission = await Geolocator.requestPermission();
        print('[LocationService] Permission after request: $permission');
      }

      return permission == LocationPermission.always || 
             permission == LocationPermission.whileInUse;
    } catch (e) {
      print('[LocationService] Error requesting permission: $e');
      return false;
    }
  }

  // Check location permission status
  Future<LocationPermission> checkLocationPermission() async {
    return await Geolocator.checkPermission();
  }

  // Main method to get current position with proper error handling
  Future<LocationResult> getCurrentPositionWithStatus() async {
    try {
      print('[LocationService] Starting location request...');
      
      // Step 1: Check if location services are enabled
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      print('[LocationService] Location services enabled: $serviceEnabled');
      
      if (!serviceEnabled) {
        return LocationResult(
          position: null,
          error: LocationError.servicesDisabled,
          message: 'Location services are disabled. Please enable them in your device settings.',
        );
      }

      // Step 2: Check location permissions
      LocationPermission permission = await Geolocator.checkPermission();
      print('[LocationService] Initial permission status: $permission');
      
      if (permission == LocationPermission.denied) {
        // Request permission
        print('[LocationService] Requesting location permission...');
        permission = await Geolocator.requestPermission();
        print('[LocationService] Permission after request: $permission');
        
        if (permission == LocationPermission.denied) {
          return LocationResult(
            position: null,
            error: LocationError.permissionDenied,
            message: 'Location permission denied. Please grant permission to use this feature.',
          );
        }
      }

      if (permission == LocationPermission.deniedForever) {
        print('[LocationService] Permission permanently denied');
        return LocationResult(
          position: null,
          error: LocationError.permissionDeniedForever,
          message: 'Location permissions are permanently denied. Please enable them in app settings.',
        );
      }

      // Step 3: Get current position with timeout handling
      print('[LocationService] Getting current position...');
      
      Position? position;
      try {
        // Try to get position with timeout
        position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high,
          timeLimit: const Duration(seconds: 10),
        );
      } catch (e) {
        print('[LocationService] High accuracy failed, trying with best accuracy: $e');
        // If high accuracy fails, try with best accuracy
        position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.best,
        );
      }
      
      print('[LocationService] Position obtained: Lat ${position.latitude}, Lng ${position.longitude}');

      return LocationResult(
        position: position,
        error: LocationError.none,
        message: 'Location retrieved successfully',
      );

    } catch (e, stackTrace) {
      print('[LocationService] Error getting location: $e');
      print('[LocationService] Stack trace: $stackTrace');
      
      // Provide more specific error messages
      String errorMessage = 'Failed to get location';
      if (e.toString().contains('timeout')) {
        errorMessage = 'Location request timed out. Please try again.';
      } else if (e.toString().contains('service')) {
        errorMessage = 'Location service error. Please check your device settings.';
      } else if (e.toString().contains('permission')) {
        errorMessage = 'Location permission error. Please check app permissions.';
      }
      
      return LocationResult(
        position: null,
        error: LocationError.unknown,
        message: '$errorMessage: ${e.toString()}',
      );
    }
  }

  // Backward compatible method
  Future<Position?> getCurrentPosition() async {
    try {
      final result = await getCurrentPositionWithStatus();
      if (result.isSuccess) {
        return result.position;
      } else {
        print('[LocationService] Failed to get position: ${result.message}');
        return null;
      }
    } catch (e) {
      print('[LocationService] Error in getCurrentPosition: $e');
      return null;
    }
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
