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

  @override
  void initState() {
    super.initState();
    _loadRestaurants();
  }

  Future<void> _loadRestaurants() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      // Get current location
      final position = await _locationService.getCurrentPosition();

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Explore Restaurants'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadRestaurants,
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
              onPressed: _loadRestaurants,
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
      onRefresh: _loadRestaurants,
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
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (restaurant.photoReference.isNotEmpty)
            Image.network(
              // TODO: Replace with actual photo URL from Google Places
              'https://via.placeholder.com/400x200',
              width: double.infinity,
              height: 200,
              fit: BoxFit.cover,
            ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  restaurant.name,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(
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
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  restaurant.address,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children: restaurant.types
                      .map((type) => Chip(
                            label: Text(type),
                            backgroundColor:
                                Theme.of(context).colorScheme.surfaceVariant,
                          ))
                      .toList(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
