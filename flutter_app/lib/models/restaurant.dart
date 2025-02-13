// Model class for restaurant data from Google Places API
class Restaurant {
  final String id;
  final String name;
  final double rating;
  final String address;
  final double latitude;
  final double longitude;
  final String photoReference;
  final String photoUrl;
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
    required this.photoUrl,
    required this.types,
    required this.isOpen,
    this.priceLevel,
  });

  // Create Restaurant object from Google Places API response
  factory Restaurant.fromMap(Map<String, dynamic> map) {
    return Restaurant(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      rating: (map['rating'] ?? 0).toDouble(),
      address: map['address'] ?? '',
      latitude: map['latitude'] ?? 0.0,
      longitude: map['longitude'] ?? 0.0,
      photoReference: map['photoReference'] ?? '',
      photoUrl: map['photoUrl'] ?? '',
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
      'photoUrl': photoUrl,
      'types': types,
      'isOpen': isOpen,
      'priceLevel': priceLevel,
    };
  }
}
