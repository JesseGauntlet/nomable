import 'package:flutter/material.dart';
import '../models/user_model.dart';
import '../services/user_service.dart';
import '../services/auth_service.dart';
import '../widgets/profile/profile_cravings_tab.dart';
import '../widgets/profile/profile_trends_tab.dart';
import '../widgets/profile/profile_videos_tab.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _userService = UserService();
  UserModel? _user;
  List<Map<String, dynamic>> _userVideos = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    setState(() => _isLoading = true);
    try {
      final user = await _userService.getCurrentUser();
      if (user != null) {
        final videos = await _userService.getUserVideos(user.id);
        if (mounted) {
          setState(() {
            _user = user;
            _userVideos = videos;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading profile: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _editProfile() async {
    // TODO: Implement edit profile functionality
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_user == null) {
      return const Center(child: Text('Error loading profile'));
    }

    final topPadding = MediaQuery.of(context).padding.top;

    return Stack(
      children: [
        // Main content
        RefreshIndicator(
          onRefresh: _loadUserData,
          child: SingleChildScrollView(
            child: Column(
              children: [
                // Profile Header
                Padding(
                  padding: EdgeInsets.fromLTRB(16, topPadding + 16, 16, 16),
                  child: Column(
                    children: [
                      // Profile Picture
                      CircleAvatar(
                        radius: 42,
                        backgroundImage: _user?.photoUrl != null
                            ? NetworkImage(_user!.photoUrl!)
                            : null,
                        child: _user?.photoUrl == null
                            ? Text(
                                _user!.name[0].toUpperCase(),
                                style: const TextStyle(fontSize: 27),
                              )
                            : null,
                      ),
                      const SizedBox(height: 12),
                      // Name and Edit Button
                      Stack(
                        alignment: Alignment.center,
                        children: [
                          // Centered username
                          Center(
                            child: Text(
                              _user!.name,
                              style: Theme.of(context)
                                  .textTheme
                                  .titleLarge
                                  ?.copyWith(
                                    fontSize: 20,
                                  ),
                            ),
                          ),
                          // Edit button positioned to the right
                          Positioned(
                            right: 0,
                            child: TextButton.icon(
                              onPressed: _editProfile,
                              icon: const Icon(Icons.edit, size: 14),
                              label: const Text('Edit'),
                              style: TextButton.styleFrom(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 5,
                                ),
                                textStyle: const TextStyle(fontSize: 11),
                              ),
                            ),
                          ),
                        ],
                      ),
                      if (_user?.bio != null) ...[
                        const SizedBox(height: 6),
                        Text(
                          _user!.bio!,
                          textAlign: TextAlign.center,
                          style:
                              Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    fontSize: 13,
                                  ),
                        ),
                      ],
                      const SizedBox(height: 12),
                      // Stats
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          _buildStat('Videos', _user!.videosCount),
                          _buildStat('Followers', _user!.followersCount),
                          _buildStat('Following', _user!.followingCount),
                        ],
                      ),
                      const SizedBox(height: 12),

                      // New TabView section for "Cravings, Trends, Videos"
                      DefaultTabController(
                        length: 3,
                        child: Column(
                          children: [
                            TabBar(
                              indicatorColor: Theme.of(context).primaryColor,
                              labelColor: Theme.of(context).primaryColor,
                              unselectedLabelColor: Colors.grey,
                              labelStyle: const TextStyle(fontSize: 12),
                              tabs: [
                                Tab(
                                    icon: const Icon(Icons.fastfood, size: 20),
                                    text: 'Cravings'),
                                Tab(
                                    icon: const Icon(Icons.bar_chart, size: 20),
                                    text: 'Trends'),
                                Tab(
                                    icon: const Icon(Icons.grid_view, size: 20),
                                    text: 'Videos'),
                              ],
                            ),
                            const SizedBox(height: 6),
                            SizedBox(
                              height: 255,
                              child: TabBarView(
                                children: [
                                  const ProfileCravingsTab(),
                                  const ProfileTrendsTab(),
                                  ProfileVideosTab(videos: _userVideos),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        // Logout button
        Positioned(
          top: topPadding + 8,
          right: 8,
          child: IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              final authService = AuthService();
              await authService.signOut();
              if (mounted) {
                Navigator.of(context).pushReplacementNamed('/login');
              }
            },
          ),
        ),
      ],
    );
  }

  Widget _buildStat(String label, int value) {
    return Column(
      children: [
        Text(
          value.toString(),
          style: Theme.of(context).textTheme.titleLarge,
        ),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
    );
  }
}
