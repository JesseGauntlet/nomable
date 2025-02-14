import 'package:flutter/material.dart';
import '../models/user_model.dart';
import '../services/user_service.dart';
import '../services/auth_service.dart';
import '../widgets/profile/profile_cravings_tab.dart';
import '../widgets/profile/profile_videos_tab.dart';
import '../widgets/profile/swipe_progress_avatar.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:io';
import '../widgets/radar_chart_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ProfileScreen extends StatefulWidget {
  final String userId;

  const ProfileScreen({super.key, required this.userId});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen>
    with SingleTickerProviderStateMixin {
  final _userService = UserService();
  UserModel? _user;
  List<Map<String, dynamic>> _userVideos = [];
  bool _isLoading = true;
  late TabController _tabController;
  bool _isCurrentUser = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadUserData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadUserData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final user = await _userService.getUserById(widget.userId);
      final currentUserId = FirebaseAuth.instance.currentUser?.uid;
      _isCurrentUser = currentUserId == widget.userId;

      if (user != null) {
        final videos = await _userService.getUserVideos(user.id);
        if (mounted) {
          setState(() {
            _user = user;
            _userVideos = videos;
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading profile: $e')),
        );
      }
    }
  }

  // Method to update videos list without full reload
  Future<void> _updateVideos() async {
    if (_user == null) return;

    try {
      final videos = await _userService.getUserVideos(_user!.id);
      if (mounted) {
        setState(() {
          _userVideos = videos;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error updating videos: $e')),
        );
      }
    }
  }

  Future<void> _editProfile() async {
    try {
      // Show a modal bottom sheet with options
      final action = await showModalBottomSheet<String>(
        context: context,
        builder: (BuildContext context) {
          return SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                ListTile(
                  leading: const Icon(Icons.photo_camera),
                  title: const Text('Take a photo'),
                  onTap: () => Navigator.pop(context, 'camera'),
                ),
                ListTile(
                  leading: const Icon(Icons.photo_library),
                  title: const Text('Choose from gallery'),
                  onTap: () => Navigator.pop(context, 'gallery'),
                ),
              ],
            ),
          );
        },
      );

      if (action == null) return;

      // Get image from camera or gallery
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: action == 'camera' ? ImageSource.camera : ImageSource.gallery,
        maxWidth: 1024, // Reasonable max width for profile photos
        maxHeight: 1024,
        imageQuality: 85, // Good quality while keeping file size reasonable
      );

      if (image == null) return;

      // Show loading indicator
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Uploading image...')),
      );

      // Upload to Firebase Storage
      final storageRef = FirebaseStorage.instance
          .ref()
          .child('profile_images')
          .child(_user!.id)
          .child('profile.jpg');

      await storageRef.putFile(
        File(image.path),
        SettableMetadata(contentType: 'image/jpeg'),
      );

      // Get download URL
      final downloadUrl = await storageRef.getDownloadURL();

      // Update user's photoUrl in Firestore
      await _userService.updateUser(_user!.id, {'photoUrl': downloadUrl});

      // Update local state
      if (mounted) {
        setState(() {
          _user = _user!.copyWith(photoUrl: downloadUrl);
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile photo updated successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error updating profile photo: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_user == null) {
      return const Scaffold(
        body: Center(child: Text('Error loading profile')),
      );
    }

    final topPadding = MediaQuery.of(context).padding.top;

    return Scaffold(
      body: Stack(
        children: [
          // Main content
          Column(
            children: [
              // Profile Header
              Padding(
                padding: EdgeInsets.fromLTRB(16, topPadding + 16, 16, 16),
                child: Column(
                  children: [
                    // Profile Picture with Swipe Progress
                    SwipeProgressAvatar(
                      photoUrl: _user?.photoUrl,
                      name: _user!.name,
                      currentSwipes: _user!.swipeCount,
                      radius: 42,
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
                        if (_isCurrentUser)
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
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              fontSize: 13,
                            ),
                      ),
                    ],
                    const SizedBox(height: 12),
                    // Stats
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Expanded(
                          child: _buildStat('Following', _user!.followingCount),
                        ),
                        Expanded(
                          child: _buildStat('Followers', _user!.followersCount),
                        ),
                        Expanded(
                          child: _buildStat('Likes', _user!.heartCount),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                  ],
                ),
              ),

              // TabView section
              Expanded(
                child: Column(
                  children: [
                    TabBar(
                      controller: _tabController,
                      indicatorColor: Theme.of(context).primaryColor,
                      labelColor: Theme.of(context).primaryColor,
                      unselectedLabelColor: Colors.grey,
                      labelStyle: const TextStyle(fontSize: 12),
                      tabs: const [
                        Tab(
                            icon: Icon(Icons.fastfood, size: 20),
                            text: 'Cravings'),
                        Tab(icon: Icon(Icons.radar), text: 'Preferences'),
                        Tab(
                            icon: Icon(Icons.grid_view, size: 20),
                            text: 'Videos'),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Expanded(
                      child: TabBarView(
                        controller: _tabController,
                        children: [
                          ProfileCravingsTab(userId: widget.userId),
                          PreferencesRadarChart(
                            preferences: _user!.foodPreferences,
                            userId: widget.userId,
                            userName: _user!.name,
                          ),
                          ProfileVideosTab(
                            videos: _userVideos,
                            onVideosDeleted:
                                _isCurrentUser ? _updateVideos : null,
                            isOwner: _isCurrentUser,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          // Logout button (only for current user)
          if (_isCurrentUser)
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
