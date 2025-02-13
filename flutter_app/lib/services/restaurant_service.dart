import 'dart:convert';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/restaurant.dart';
import 'package:flutter/foundation.dart';

class RestaurantService {
  // Singleton pattern
  static final RestaurantService _instance = RestaurantService._internal();
  factory RestaurantService() => _instance;
  RestaurantService._internal();

  final FirebaseFunctions _functions = FirebaseFunctions.instance;
  static const String _cacheKey = 'cached_restaurants';
  static const String _cacheDateKey = 'restaurants_cache_date';
  static const Duration _cacheExpiration = Duration(hours: 24);

  /// Fetch restaurant recommendations with caching
  Future<List<Restaurant>> getRecommendations({
    required Position position,
    required Map<String, int> tags,
    int? radius,
    bool forceRefresh = false,
  }) async {
    try {
      // Check cache first if not forcing refresh
      if (!forceRefresh) {
        final cachedResults = await getCachedRestaurants();
        if (cachedResults.isNotEmpty) {
          debugPrint('Using cached results');
          for (var restaurant in cachedResults) {
            debugPrint(
                'Cached restaurant ${restaurant.name}: lat=${restaurant.latitude}, lng=${restaurant.longitude}');
          }
          return cachedResults;
        }
      }

      // If cache is empty or forcing refresh, fetch from API
      debugPrint(
          'Fetching from API with position: lat=${position.latitude}, lng=${position.longitude}');
      final callable = _functions.httpsCallable('getRestaurantRecommendations');
      final response = await callable.call({
        'latitude': position.latitude,
        'longitude': position.longitude,
        'tags': tags,
        if (radius != null) 'radius': radius,
      });

      // Cloud Functions typically returns JSON structured as dynamic
      final List<dynamic> rawResults = response.data ?? [];
      debugPrint('Raw response from API: $rawResults');

      // Convert each dynamic item to a Map<String, dynamic> before fromMap
      final results = rawResults.map((item) {
        debugPrint('Processing item from API: $item');
        final restaurant = Restaurant.fromMap(Map<String, dynamic>.from(item));
        debugPrint(
            'Created restaurant ${restaurant.name}: lat=${restaurant.latitude}, lng=${restaurant.longitude}');
        return restaurant;
      }).toList();

      // Cache the results
      await cacheRestaurants(results);

      return results;
    } catch (e) {
      debugPrint('Error in getRecommendations: $e');
      throw Exception('Failed to fetch restaurant recommendations: $e');
    }
  }

  /// Cache restaurant data locally
  Future<void> cacheRestaurants(List<Restaurant> restaurants) async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Convert restaurants to JSON
      final jsonData = restaurants.map((r) {
        final map = r.toMap();
        debugPrint(
            'Caching restaurant ${r.name}: lat=${map['latitude']}, lng=${map['longitude']}');
        return map;
      }).toList();

      // Save restaurants and cache date
      await prefs.setString(_cacheKey, jsonEncode(jsonData));
      await prefs.setString(_cacheDateKey, DateTime.now().toIso8601String());
    } catch (e) {
      debugPrint('Error caching restaurants: $e');
    }
  }

  /// Get cached restaurants if available and not expired
  Future<List<Restaurant>> getCachedRestaurants() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Check if we have cached data
      final cachedData = prefs.getString(_cacheKey);
      final cacheDateStr = prefs.getString(_cacheDateKey);

      if (cachedData == null || cacheDateStr == null) {
        return [];
      }

      // Check if cache is expired
      final cacheDate = DateTime.parse(cacheDateStr);
      if (DateTime.now().difference(cacheDate) > _cacheExpiration) {
        // Clear expired cache
        await clearCache();
        return [];
      }

      // Parse cached data
      final List<dynamic> jsonData = jsonDecode(cachedData);
      debugPrint('Retrieved cached data: $jsonData');

      final results = jsonData.map((data) {
        final restaurant = Restaurant.fromMap(data);
        debugPrint(
            'Restored restaurant ${restaurant.name}: lat=${restaurant.latitude}, lng=${restaurant.longitude}');
        return restaurant;
      }).toList();

      return results;
    } catch (e) {
      debugPrint('Error reading cached restaurants: $e');
      return [];
    }
  }

  /// Clear the restaurant cache
  Future<void> clearCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_cacheKey);
      await prefs.remove(_cacheDateKey);
    } catch (e) {
      print('Error clearing restaurant cache: $e');
    }
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
