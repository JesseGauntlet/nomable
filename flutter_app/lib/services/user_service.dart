import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/user_model.dart';

class UserService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Get current user data
  Future<UserModel?> getCurrentUser() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return null;

      final doc = await _firestore.collection('users').doc(user.uid).get();
      if (!doc.exists) return null;

      return UserModel.fromFirestore(doc);
    } catch (e) {
      print('Error getting current user: $e');
      return null;
    }
  }

  // Create or update user data
  Future<void> createOrUpdateUser({
    required String name,
    String? uid,
    String? photoUrl,
    String? bio,
    Map<String, int>? foodPreferences,
    String? currentCraving,
  }) async {
    try {
      // Use provided uid or get from current user
      final userId = uid ?? _auth.currentUser?.uid;
      if (userId == null)
        throw Exception('No user ID provided or authenticated user found');

      // Always get email from current user if available
      final userEmail = _auth.currentUser?.email;

      final data = {
        'name': name,
        'email': userEmail,
        if (photoUrl != null) 'photoUrl': photoUrl,
        if (bio != null) 'bio': bio,
        if (foodPreferences != null) 'foodPreferences': foodPreferences,
        if (currentCraving != null) 'currentCraving': currentCraving,
        'videosCount': 0,
        'followersCount': 0,
        'followingCount': 0,
        'heartCount': 0,
        'updatedAt': FieldValue.serverTimestamp(),
      };

      // Only set createdAt and initialize fields for new users
      if (uid != null) {
        data['createdAt'] = FieldValue.serverTimestamp();
        // Initialize other fields for new users if not provided
        if (foodPreferences == null) {
          data['foodPreferences'] = {};
        }
        if (currentCraving == null) {
          data['currentCraving'] = '';
        }
      }

      await _firestore.collection('users').doc(userId).set(
            data,
            SetOptions(merge: true),
          );
    } catch (e) {
      throw Exception('Failed to update user data: $e');
    }
  }

  // Get user's videos
  Future<List<Map<String, dynamic>>> getUserVideos(String userId) async {
    try {
      final videosSnapshot = await _firestore
          .collection('posts')
          .where('userId', isEqualTo: userId)
          .where('mediaType', isEqualTo: 'video')
          .orderBy('createdAt', descending: true)
          .get();

      // Include thumbnailUrl in the returned data
      return videosSnapshot.docs.map((doc) {
        final data = doc.data();
        return {
          'id': doc.id,
          ...data,
          // Ensure thumbnailUrl is included if it exists
          if (!data.containsKey('thumbnailUrl'))
            'thumbnailUrl': '', // Provide default empty string if not exists
        };
      }).toList();
    } catch (e) {
      print('Error getting user videos: $e');
      return [];
    }
  }

  // Follow user
  Future<void> followUser(String targetUserId) async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) throw Exception('No authenticated user found');

      final batch = _firestore.batch();

      // Add to following collection
      final followingRef = _firestore
          .collection('users')
          .doc(currentUser.uid)
          .collection('following')
          .doc(targetUserId);

      // Add to followers collection
      final followerRef = _firestore
          .collection('users')
          .doc(targetUserId)
          .collection('followers')
          .doc(currentUser.uid);

      batch.set(followingRef, {
        'timestamp': FieldValue.serverTimestamp(),
      });

      batch.set(followerRef, {
        'timestamp': FieldValue.serverTimestamp(),
      });

      // Update counts
      batch.update(
        _firestore.collection('users').doc(currentUser.uid),
        {'followingCount': FieldValue.increment(1)},
      );

      batch.update(
        _firestore.collection('users').doc(targetUserId),
        {'followersCount': FieldValue.increment(1)},
      );

      await batch.commit();
    } catch (e) {
      throw Exception('Failed to follow user: $e');
    }
  }

  // Unfollow user
  Future<void> unfollowUser(String targetUserId) async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) throw Exception('No authenticated user found');

      final batch = _firestore.batch();

      // Remove from following collection
      final followingRef = _firestore
          .collection('users')
          .doc(currentUser.uid)
          .collection('following')
          .doc(targetUserId);

      // Remove from followers collection
      final followerRef = _firestore
          .collection('users')
          .doc(targetUserId)
          .collection('followers')
          .doc(currentUser.uid);

      batch.delete(followingRef);
      batch.delete(followerRef);

      // Update counts
      batch.update(
        _firestore.collection('users').doc(currentUser.uid),
        {'followingCount': FieldValue.increment(-1)},
      );

      batch.update(
        _firestore.collection('users').doc(targetUserId),
        {'followersCount': FieldValue.increment(-1)},
      );

      await batch.commit();
    } catch (e) {
      throw Exception('Failed to unfollow user: $e');
    }
  }

  // Check if following
  Future<bool> isFollowing(String targetUserId) async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) return false;

      final doc = await _firestore
          .collection('users')
          .doc(currentUser.uid)
          .collection('following')
          .doc(targetUserId)
          .get();

      return doc.exists;
    } catch (e) {
      print('Error checking following status: $e');
      return false;
    }
  }

  Future<void> addUserVideo(
    String userId,
    String videoUrl, {
    String description = '',
    List<String> foodTags = const [],
  }) async {
    try {
      await _firestore.collection('users').doc(userId).update({
        'videosCount': FieldValue.increment(1),
      });

      await _firestore.collection('posts').add({
        'userId': userId,
        'mediaUrl': videoUrl,
        'mediaType': 'video',
        'foodTags': foodTags,
        'createdAt': FieldValue.serverTimestamp(),
        'description': description,
        'swipeCounts': 0,
        'heartCount': 0,
        'bookmarkCount': 0,
      });
    } catch (e) {
      throw Exception('Failed to record video: $e');
    }
  }

  // Heart a post and update user's food preferences based on the post's foodTags
  Future<void> heartPost({
    required String postId,
    required List<String> foodTags,
  }) async {
    try {
      // Ensure the user is authenticated
      final currentUser = _auth.currentUser;
      if (currentUser == null) {
        throw Exception('User not authenticated');
      }

      // Get the post to find the owner
      final postDoc = await _firestore.collection('posts').doc(postId).get();
      if (!postDoc.exists) {
        throw Exception('Post not found');
      }
      final postData = postDoc.data() as Map<String, dynamic>;
      final postOwnerId = postData['userId'] as String;

      // Start a batch write
      final batch = _firestore.batch();

      // 1. Increment the heartCount of the post in the 'posts' collection
      batch.update(_firestore.collection('posts').doc(postId), {
        'heartCount': FieldValue.increment(1),
      });

      // 2. Increment the heartCount of the post owner
      batch.update(_firestore.collection('users').doc(postOwnerId), {
        'heartCount': FieldValue.increment(1),
      });

      // 3. Prepare a map update to increment the count for each food tag in the user's foodPreferences
      Map<String, dynamic> updateData = {};
      for (String tag in foodTags) {
        // Convert tag to lowercase for consistency
        updateData['foodPreferences.${tag.toLowerCase()}'] =
            FieldValue.increment(1);
      }

      // 4. Update the current user's document with the new food preferences
      batch.update(
          _firestore.collection('users').doc(currentUser.uid), updateData);

      // Commit all the updates atomically
      await batch.commit();
    } catch (e) {
      throw Exception('Failed to heart post: $e');
    }
  }

  // Update specific user fields
  Future<void> updateUser(String userId, Map<String, dynamic> data) async {
    try {
      await _firestore.collection('users').doc(userId).update({
        ...data,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('Failed to update user: $e');
    }
  }

  // Delete a post and update user's video count
  Future<void> deletePost(String postId) async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) throw Exception('No authenticated user found');

      // Get the post to verify ownership
      final postDoc = await _firestore.collection('posts').doc(postId).get();
      if (!postDoc.exists) throw Exception('Post not found');

      final postData = postDoc.data() as Map<String, dynamic>;
      if (postData['userId'] != currentUser.uid) {
        throw Exception('Not authorized to delete this post');
      }

      // Start a batch write
      final batch = _firestore.batch();

      // Delete the post
      batch.delete(_firestore.collection('posts').doc(postId));

      // Decrement user's video count
      batch.update(_firestore.collection('users').doc(currentUser.uid), {
        'videosCount': FieldValue.increment(-1),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // Commit the batch
      await batch.commit();
    } catch (e) {
      throw Exception('Failed to delete post: $e');
    }
  }

  // Archive current preferences and reset them
  Future<void> archiveAndResetPreferences(
      String userId, Map<String, int> currentPreferences) async {
    try {
      final batch = _firestore.batch();

      // Create a new preference history document
      final historyRef = _firestore
          .collection('users')
          .doc(userId)
          .collection('preferenceHistory')
          .doc();

      // Store current preferences with timestamp
      batch.set(historyRef, {
        'date': FieldValue.serverTimestamp(),
        'preferences': currentPreferences,
      });

      // Reset the user's current preferences
      final userRef = _firestore.collection('users').doc(userId);
      batch.update(userRef, {
        'foodPreferences': {},
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // Commit both operations atomically
      await batch.commit();
    } catch (e) {
      throw Exception('Failed to archive and reset preferences: $e');
    }
  }

  // Get user by ID
  Future<UserModel?> getUserById(String userId) async {
    try {
      final doc = await _firestore.collection('users').doc(userId).get();
      if (!doc.exists) return null;

      return UserModel.fromFirestore(doc);
    } catch (e) {
      print('Error getting user by ID: $e');
      return null;
    }
  }
}
