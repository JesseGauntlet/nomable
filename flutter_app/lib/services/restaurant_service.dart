import 'package:cloud_functions/cloud_functions.dart';
import 'package:geolocator/geolocator.dart';
import '../models/restaurant.dart';

class RestaurantService {
  // Singleton pattern
  static final RestaurantService _instance = RestaurantService._internal();
  factory RestaurantService() => _instance;
  RestaurantService._internal();

  final FirebaseFunctions _functions = FirebaseFunctions.instance;

  /// Fetch restaurant recommendations
  Future<List<Restaurant>> getRecommendations({
    required Position position,
    required Map<String, int> tags,
    int? radius, // Make radius optional
  }) async {
    try {
      final callable = _functions.httpsCallable('getRestaurantRecommendations');
      final response = await callable.call({
        'latitude': position.latitude,
        'longitude': position.longitude,
        'tags': tags,
        if (radius != null) 'radius': radius, // Only include if provided
      });

      // Cloud Functions typically returns JSON structured as dynamic
      final List<dynamic> rawResults = response.data ?? [];

      // Convert each dynamic item to a Map<String, dynamic> before fromMap
      final results = rawResults
          .map((item) => Restaurant.fromMap(Map<String, dynamic>.from(item)))
          .toList();

      return results;
    } catch (e) {
      throw Exception('Failed to fetch restaurant recommendations: $e');
    }
  }

  /// Cache restaurant data locally (can be expanded later)
  Future<void> cacheRestaurants(List<Restaurant> restaurants) async {
    // TODO: Implement local caching using shared_preferences or hive
  }

  /// Get cached restaurants (can be expanded later)
  Future<List<Restaurant>> getCachedRestaurants() async {
    // TODO: Implement getting cached restaurants
    return [];
  }

  /// Filter restaurants by type
  List<Restaurant> filterByType(List<Restaurant> restaurants, String type) {
    return restaurants
        .where((restaurant) => restaurant.types.contains(type.toLowerCase()))
        .toList();
  }

  /// Sort restaurants by rating
  List<Restaurant> sortByRating(List<Restaurant> restaurants,
      {bool ascending = false}) {
    restaurants.sort((a, b) => ascending
        ? a.rating.compareTo(b.rating)
        : b.rating.compareTo(a.rating));
    return restaurants;
  }

  /// Sort restaurants by distance from a given position
  List<Restaurant> sortByDistance(
      List<Restaurant> restaurants, Position userPosition,
      {bool ascending = true}) {
    restaurants.sort((a, b) {
      double distanceA = Geolocator.distanceBetween(
        userPosition.latitude,
        userPosition.longitude,
        a.latitude,
        a.longitude,
      );
      double distanceB = Geolocator.distanceBetween(
        userPosition.latitude,
        userPosition.longitude,
        b.latitude,
        b.longitude,
      );
      return ascending
          ? distanceA.compareTo(distanceB)
          : distanceB.compareTo(distanceA);
    });
    return restaurants;
  }
}
