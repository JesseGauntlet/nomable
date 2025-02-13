import 'package:geolocator/geolocator.dart';

class LocationService {
  // Singleton instance
  static final LocationService _instance = LocationService._internal();
  factory LocationService() => _instance;
  LocationService._internal();

  // Cache the last known position
  Position? _lastKnownPosition;

  /// Determine if location services are enabled and request permissions if needed
  Future<bool> _checkLocationPermission() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw Exception('Location services are disabled.');
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        throw Exception('Location permissions are denied.');
      }
    }

    if (permission == LocationPermission.deniedForever) {
      throw Exception('Location permissions are permanently denied.');
    }

    return true;
  }

  /// Get the current position with high accuracy
  Future<Position> getCurrentPosition() async {
    await _checkLocationPermission();

    try {
      _lastKnownPosition = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      return _lastKnownPosition!;
    } catch (e) {
      throw Exception('Failed to get current location: $e');
    }
  }

  /// Get the last known position or fetch new if not available
  Future<Position> getLastKnownPosition() async {
    if (_lastKnownPosition != null) {
      return _lastKnownPosition!;
    }
    return getCurrentPosition();
  }

  /// Calculate distance between two points in meters
  double calculateDistance(
    double startLatitude,
    double startLongitude,
    double endLatitude,
    double endLongitude,
  ) {
    return Geolocator.distanceBetween(
      startLatitude,
      startLongitude,
      endLatitude,
      endLongitude,
    );
  }
}
