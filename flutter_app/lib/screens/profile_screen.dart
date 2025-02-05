import 'package:flutter/material.dart';
import '../models/user_model.dart';
import '../services/user_service.dart';
import '../widgets/feed_video_player.dart';
import '../services/auth_service.dart';

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
                            Container(
                              height: 255,
                              child: TabBarView(
                                children: [
                                  // Cravings view
                                  Center(
                                      child: Text("User Cravings Data Here")),
                                  // Trends view
                                  Center(
                                      child: Text(
                                          "Historical Trend Cravings Data Here")),
                                  // Videos view
                                  GridView.builder(
                                    shrinkWrap: true,
                                    physics:
                                        const NeverScrollableScrollPhysics(),
                                    padding: const EdgeInsets.all(8),
                                    gridDelegate:
                                        const SliverGridDelegateWithFixedCrossAxisCount(
                                      crossAxisCount: 3,
                                      crossAxisSpacing: 8,
                                      mainAxisSpacing: 8,
                                      childAspectRatio: 0.8,
                                    ),
                                    itemCount: _userVideos.length,
                                    itemBuilder: (context, index) {
                                      final video = _userVideos[index];
                                      return GestureDetector(
                                        onTap: () {
                                          // TODO: Open video in full screen
                                        },
                                        child: Container(
                                          decoration: BoxDecoration(
                                            borderRadius:
                                                BorderRadius.circular(8),
                                            color: Colors.grey[300],
                                          ),
                                          child: Stack(
                                            fit: StackFit.expand,
                                            children: [
                                              ClipRRect(
                                                borderRadius:
                                                    BorderRadius.circular(8),
                                                child: FeedVideoPlayer(
                                                  videoUrl: video['videoUrl'],
                                                ),
                                              ),
                                              Positioned(
                                                bottom: 8,
                                                right: 8,
                                                child: Container(
                                                  padding: const EdgeInsets
                                                      .symmetric(
                                                      horizontal: 8,
                                                      vertical: 4),
                                                  decoration: BoxDecoration(
                                                    color: Colors.black
                                                        .withOpacity(0.7),
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            12),
                                                  ),
                                                  child: Row(
                                                    mainAxisSize:
                                                        MainAxisSize.min,
                                                    children: [
                                                      const Icon(Icons.favorite,
                                                          color: Colors.white,
                                                          size: 16),
                                                      const SizedBox(width: 4),
                                                      Text(
                                                        '${video['likes'] ?? 0}',
                                                        style: const TextStyle(
                                                            color: Colors.white,
                                                            fontSize: 12),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      );
                                    },
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
