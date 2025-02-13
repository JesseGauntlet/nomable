import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import '../models/restaurant.dart';
import '../services/location_service.dart';
import '../services/restaurant_service.dart';

class ExploreScreen extends StatefulWidget {
  const ExploreScreen({Key? key}) : super(key: key);

  @override
  _ExploreScreenState createState() => _ExploreScreenState();
}

class _ExploreScreenState extends State<ExploreScreen> {
  final LocationService _locationService = LocationService();
  final RestaurantService _restaurantService = RestaurantService();

  List<Restaurant> _restaurants = [];
  bool _isLoading = false;
  String? _error;
  Position?
      _currentPosition; // Store current position for distance calculations

  @override
  void initState() {
    super.initState();
    _loadRestaurants(forceRefresh: false);
  }

  Future<void> _loadRestaurants({bool forceRefresh = false}) async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      // If no cache or force refresh, proceed with API call
      final position = await _locationService.getCurrentPosition();
      _currentPosition = position;

      // TODO: Get user tags from user service
      final Map<String, int> mockTags = {
        'pizza': 10,
        'sushi': 6,
        'ramen': 2,
      };

      // Fetch recommendations
      final recommendations = await _restaurantService.getRecommendations(
        position: position,
        tags: mockTags,
        forceRefresh: forceRefresh,
      );

      setState(() {
        _restaurants = recommendations;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  // Format distance in a human-readable way
  String _formatDistance(double meters) {
    if (meters < 1000) {
      return '${meters.round()}m';
    } else {
      final km = meters / 1000;
      return '${km.toStringAsFixed(1)}km';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Explore Restaurants'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => _loadRestaurants(forceRefresh: true),
          ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Error: $_error',
              style: const TextStyle(color: Colors.red),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => _loadRestaurants(forceRefresh: true),
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (_restaurants.isEmpty) {
      return const Center(
        child: Text('No restaurants found nearby'),
      );
    }

    return RefreshIndicator(
      onRefresh: () => _loadRestaurants(forceRefresh: true),
      child: ListView.builder(
        itemCount: _restaurants.length,
        itemBuilder: (context, index) {
          final restaurant = _restaurants[index];
          return _buildRestaurantCard(restaurant);
        },
      ),
    );
  }

  Widget _buildRestaurantCard(Restaurant restaurant) {
    // Calculate distance if we have current position
    final distance = _currentPosition != null
        ? Geolocator.distanceBetween(
            _currentPosition!.latitude,
            _currentPosition!.longitude,
            restaurant.latitude,
            restaurant.longitude,
          )
        : null;

    if (distance != null) {
      debugPrint(
          'Current position: ${_currentPosition!.latitude}, ${_currentPosition!.longitude}');
      debugPrint(
          'Restaurant position: ${restaurant.latitude}, ${restaurant.longitude}');
      debugPrint('Calculated distance: $distance meters');
    }

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        restaurant.name,
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                    ),
                    if (distance != null)
                      Text(
                        _formatDistance(distance),
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: Theme.of(context).colorScheme.secondary,
                            ),
                      ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(
                      Icons.star,
                      size: 20,
                      color: Colors.amber,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      restaurant.rating.toString(),
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    if (restaurant.priceLevel != null) ...[
                      const SizedBox(width: 16),
                      Text(
                        '\$' * restaurant.priceLevel!.round(),
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ],
                    if (restaurant.isOpen) ...[
                      const SizedBox(width: 16),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.green.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          'Open',
                          style:
                              Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: Colors.green,
                                  ),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  restaurant.address,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
