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
    String? photoUrl,
    String? bio,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('No authenticated user found');

      await _firestore.collection('users').doc(user.uid).set({
        'name': name,
        'email': user.email,
        'photoUrl': photoUrl,
        'bio': bio,
        'videosCount': 0,
        'followersCount': 0,
        'followingCount': 0,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (e) {
      throw Exception('Failed to update user data: $e');
    }
  }

  // Get user's videos
  Future<List<Map<String, dynamic>>> getUserVideos(String userId) async {
    try {
      final videosSnapshot = await _firestore
          .collection('videos')
          .where('userId', isEqualTo: userId)
          .orderBy('createdAt', descending: true)
          .get();

      return videosSnapshot.docs
          .map((doc) => {'id': doc.id, ...doc.data()})
          .toList();
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
}
