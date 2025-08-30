import 'package:geolocator/geolocator.dart';

enum LocationError {
  none,
  servicesDisabled,
  permissionDenied,
  permissionDeniedForever,
  unknown,
}

class LocationResult {
  final Position? position;
  final LocationError error;
  final String message;

  LocationResult({
    required this.position,
    required this.error,
    required this.message,
  });

  bool get hasError => error != LocationError.none;
  bool get isSuccess => error == LocationError.none && position != null;
}
