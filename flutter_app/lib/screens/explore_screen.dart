import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import '../models/restaurant.dart';
import '../services/location_service.dart';
import '../services/restaurant_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

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
  // State variable to track selected sorting option
  String _selectedSortOption = 'Rating';

  @override
  void initState() {
    super.initState();
    _loadRestaurants(forceRefresh: false);
  }

  // Helper function to fetch real user tags from Firestore
  Future<Map<String, int>> _getUserTags() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      throw Exception('User not logged in.');
    }
    final userDoc = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .get();
    final data = userDoc.data();
    if (data != null && data.containsKey('foodPreferences')) {
      return Map<String, int>.from(data['foodPreferences']);
    }
    return {};
  }

  Future<void> _loadRestaurants({bool forceRefresh = false}) async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      // Use cached location if not forcing refresh
      final position = forceRefresh
          ? await _locationService.getCurrentPosition()
          : await _locationService.getLastKnownPosition();
      _currentPosition = position;

      // Fetch real user tags from Firestore
      final Map<String, int> userTags = await _getUserTags();
      if (userTags.isEmpty) {
        throw Exception('No food preferences found for the user.');
      }

      // Fetch recommendations using the real user tags
      final recommendations = await _restaurantService.getRecommendations(
        position: position,
        tags: userTags,
        forceRefresh: forceRefresh,
      );

      setState(() {
        _restaurants = recommendations;
        _isLoading = false;
      });

      // Apply current sorting option after loading
      _sortRestaurants(_selectedSortOption);
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

  // Helper function to get a fun color for a given tag
  Color _getTagColor(String tag) {
    // Define a list of fun colors
    final List<Color> funColors = [
      Colors.redAccent,
      Colors.blueAccent,
      Colors.greenAccent,
      Colors.orangeAccent,
      Colors.pinkAccent,
      Colors.purpleAccent,
      Colors.tealAccent,
      Colors.cyanAccent,
      Colors.amberAccent,
      Colors.limeAccent,
    ];
    // Use hashCode to pick a color from the list
    final index = tag.hashCode.abs() % funColors.length;
    return funColors[index];
  }

  // Method to sort restaurants based on selected sort option
  void _sortRestaurants(String sortOption) {
    if (sortOption == 'Rating') {
      // Sort by rating descending
      setState(() {
        _restaurants = _restaurantService.sortByRating(List.from(_restaurants),
            ascending: false);
      });
    } else if (sortOption == 'Distance') {
      if (_currentPosition != null) {
        // Sort by distance ascending
        setState(() {
          _restaurants = _restaurantService.sortByDistance(
              List.from(_restaurants), _currentPosition!,
              ascending: true);
        });
      } else {
        debugPrint('Current position is null, cannot sort by distance');
      }
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

    // Build sorting controls and restaurant list
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Sort by:'),
              DropdownButton<String>(
                value: _selectedSortOption,
                items: const [
                  DropdownMenuItem(value: 'Rating', child: Text('Rating')),
                  DropdownMenuItem(value: 'Distance', child: Text('Distance')),
                ],
                onChanged: (value) {
                  if (value != null) {
                    setState(() {
                      _selectedSortOption = value;
                    });
                    _sortRestaurants(value);
                  }
                },
              ),
            ],
          ),
        ),
        Expanded(
          child: RefreshIndicator(
            onRefresh: () => _loadRestaurants(forceRefresh: true),
            child: ListView.builder(
              itemCount: _restaurants.length,
              itemBuilder: (context, index) {
                final restaurant = _restaurants[index];
                return _buildRestaurantCard(restaurant);
              },
            ),
          ),
        ),
      ],
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
                if (restaurant.matchedTag != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: Chip(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      visualDensity: VisualDensity.compact,
                      label: Text(
                        '${restaurant.matchedTag}',
                        style: Theme.of(context)
                            .textTheme
                            .bodySmall
                            ?.copyWith(fontSize: 10, color: Colors.white),
                      ),
                      backgroundColor: _getTagColor(restaurant.matchedTag!),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
