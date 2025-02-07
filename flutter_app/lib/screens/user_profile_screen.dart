import 'package:flutter/material.dart';
import '../models/user_model.dart';
import '../services/user_service.dart';
import '../widgets/profile/profile_cravings_tab.dart';
import '../widgets/profile/profile_trends_tab.dart';
import '../widgets/profile/profile_videos_tab.dart';

class UserProfileScreen extends StatefulWidget {
  final String userId;
  final String?
      initialUsername; // Optional, can be used to show username immediately

  const UserProfileScreen({
    super.key,
    required this.userId,
    this.initialUsername,
  });

  @override
  State<UserProfileScreen> createState() => _UserProfileScreenState();
}

class _UserProfileScreenState extends State<UserProfileScreen> {
  final _userService = UserService();
  UserModel? _user;
  List<Map<String, dynamic>> _userVideos = [];
  bool _isLoading = true;
  bool _isFollowing = false;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    setState(() => _isLoading = true);
    try {
      // Load user data and check following status in parallel
      final userFuture = _userService.getUserById(widget.userId);
      final isFollowingFuture = _userService.isFollowing(widget.userId);

      final user = await userFuture;
      if (user != null) {
        final videos = await _userService.getUserVideos(user.id);
        final isFollowing = await isFollowingFuture;

        if (mounted) {
          setState(() {
            _user = user;
            _userVideos = videos;
            _isFollowing = isFollowing;
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

  Future<void> _toggleFollow() async {
    try {
      if (_isFollowing) {
        await _userService.unfollowUser(widget.userId);
      } else {
        await _userService.followUser(widget.userId);
      }

      if (mounted) {
        setState(() => _isFollowing = !_isFollowing);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: Text(widget.initialUsername ?? 'Profile'),
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_user == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Profile'),
        ),
        body: const Center(child: Text('Error loading profile')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(_user!.name),
        actions: [
          TextButton(
            onPressed: _toggleFollow,
            child: Text(_isFollowing ? 'Unfollow' : 'Follow'),
          ),
        ],
      ),
      body: Column(
        children: [
          // Profile Header
          Padding(
            padding: const EdgeInsets.all(16),
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
                // Username
                Text(
                  _user!.name,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontSize: 20,
                      ),
                ),
                if (_user?.bio != null) ...[
                  const SizedBox(height: 6),
                  Text(
                    _user!.bio!,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontSize: 13,
                        ),
                  ),
                ],
                const SizedBox(height: 12),
                // Stats
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildStat('Following', _user!.followingCount),
                    _buildStat('Followers', _user!.followersCount),
                    _buildStat('Likes', _user!.heartCount),
                  ],
                ),
              ],
            ),
          ),

          // TabView for "Cravings, Trends, Videos"
          Expanded(
            child: DefaultTabController(
              length: 3,
              child: Column(
                children: [
                  TabBar(
                    indicatorColor: Theme.of(context).primaryColor,
                    labelColor: Theme.of(context).primaryColor,
                    unselectedLabelColor: Colors.grey,
                    labelStyle: const TextStyle(fontSize: 12),
                    tabs: const [
                      Tab(
                          icon: Icon(Icons.fastfood, size: 20),
                          text: 'Cravings'),
                      Tab(
                          icon: Icon(Icons.bar_chart, size: 20),
                          text: 'Trends'),
                      Tab(
                          icon: Icon(Icons.grid_view, size: 20),
                          text: 'Videos'),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Expanded(
                    child: TabBarView(
                      children: [
                        const ProfileCravingsTab(),
                        const ProfileTrendsTab(),
                        ProfileVideosTab(
                          videos: _userVideos,
                          isOwner: false,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
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
