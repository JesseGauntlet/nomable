// Model class for restaurant data from Google Places API
import 'package:flutter/foundation.dart';

class Restaurant {
  final String id;
  final String name;
  final double rating;
  final String address;
  final double latitude;
  final double longitude;
  final String photoReference;
  final List<String> types;
  final bool isOpen;
  final double? priceLevel;

  Restaurant({
    required this.id,
    required this.name,
    required this.rating,
    required this.address,
    required this.latitude,
    required this.longitude,
    required this.photoReference,
    required this.types,
    required this.isOpen,
    this.priceLevel,
  });

  // Create Restaurant object from Google Places API response
  factory Restaurant.fromMap(Map<String, dynamic> map) {
    // Add logging to see the raw map data
    debugPrint('Creating Restaurant from map: $map');

    return Restaurant(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      rating: (map['rating'] ?? 0).toDouble(),
      address: map['address'] ?? '',
      latitude: (map['latitude'] ?? 0).toDouble(),
      longitude: (map['longitude'] ?? 0).toDouble(),
      photoReference: map['photoReference'] ?? '',
      types: List<String>.from(map['types'] ?? []),
      isOpen: map['isOpen'] ?? false,
      priceLevel: map['priceLevel']?.toDouble(),
    );
  }

  // Convert Restaurant object to Map for local storage
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'rating': rating,
      'address': address,
      'latitude': latitude,
      'longitude': longitude,
      'photoReference': photoReference,
      'types': types,
      'isOpen': isOpen,
      'priceLevel': priceLevel,
    };
  }
}
