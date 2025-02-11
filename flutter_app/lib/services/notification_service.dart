import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class NotificationService {
  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Initialize notification settings and request permissions
  Future<void> initialize() async {
    // Request permission for iOS
    NotificationSettings settings = await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    print('Notification permission status: ${settings.authorizationStatus}');

    // Handle incoming messages when app is in foreground
    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

    // Handle notification tap when app is in background or terminated
    FirebaseMessaging.onMessageOpenedApp.listen(_handleBackgroundMessage);

    // Update FCM token when it changes
    _messaging.onTokenRefresh.listen((token) {
      print('FCM Token refreshed: $token');
      _updateToken(token);
    });

    // Get initial token
    String? token = await _messaging.getToken();

    // If no token exists but we have permission, force a refresh
    if (token == null &&
        settings.authorizationStatus == AuthorizationStatus.authorized) {
      print('No token found, forcing refresh...');
      await _messaging.deleteToken();
      token = await _messaging.getToken();
    }

    if (token != null) {
      print('Initial FCM Token: $token');
      await _updateToken(token);
    } else {
      print(
          'Failed to get FCM token. Authorization status: ${settings.authorizationStatus}');
    }
  }

  // Handle foreground messages
  void _handleForegroundMessage(RemoteMessage message) {
    // Show a simple dialog or snackbar when a message is received
    if (message.notification != null) {
      // Find the current context and show a snackbar
      // Note: This requires a BuildContext, so you might want to use a GlobalKey or
      // pass the context from the UI layer
      final messenger = GlobalKey<ScaffoldMessengerState>().currentState;
      if (messenger != null) {
        messenger.showSnackBar(
          SnackBar(
            content: Text(message.notification!.body ?? ''),
            action: SnackBarAction(
              label: 'View',
              onPressed: () {
                // Handle notification tap
                _handleNotificationTap(message.data);
              },
            ),
          ),
        );
      }
    }
  }

  // Handle background messages
  void _handleBackgroundMessage(RemoteMessage message) {
    // Handle notification tap when app is in background
    _handleNotificationTap(message.data);
  }

  // Handle notification tap
  void _handleNotificationTap(Map<String, dynamic> data) {
    // Handle different types of notifications
    if (data['type'] == 'group_vote' && data['groupId'] != null) {
      // Navigate to group preferences screen
      // Note: This requires navigation context, so you might want to use
      // a navigation service or pass the context from the UI layer
    }
  }

  // Update FCM token in Firestore
  Future<void> _updateToken(String token) async {
    final user = _auth.currentUser;
    if (user != null) {
      try {
        print('Updating FCM token for user ${user.uid}');
        // First check if the document exists
        final docSnapshot =
            await _firestore.collection('users').doc(user.uid).get();

        if (docSnapshot.exists) {
          // Update existing document
          await _firestore.collection('users').doc(user.uid).update({
            'fcmToken': token,
            'updatedAt': FieldValue.serverTimestamp(),
          });
          print('Successfully updated FCM token in Firestore');
        } else {
          // Create new document with required fields
          await _firestore.collection('users').doc(user.uid).set({
            'name': user.displayName ?? 'User',
            'email': user.email ?? '',
            'fcmToken': token,
            'videosCount': 0,
            'followersCount': 0,
            'followingCount': 0,
            'heartCount': 0,
            'swipeCount': 0,
            'foodPreferences': {},
            'currentCraving': '',
            'createdAt': FieldValue.serverTimestamp(),
            'updatedAt': FieldValue.serverTimestamp(),
          });
          print('Successfully created new user document with FCM token');
        }
      } catch (e) {
        print('Error updating FCM token: $e');
        // Don't throw the error as this is not critical for app function
      }
    } else {
      print('Cannot update FCM token: No user is currently logged in');
    }
  }

  // Send notification to group members about voting
  Future<void> notifyGroupMembers(
      String groupId, List<String> memberIds) async {
    try {
      // Get FCM tokens for all members
      final membersSnapshot = await _firestore
          .collection('users')
          .where(FieldPath.documentId, whereIn: memberIds)
          .get();

      final List<String> tokens = membersSnapshot.docs
          .map((doc) => doc.data()['fcmToken'] as String?)
          .where((token) => token != null)
          .cast<String>()
          .toList();

      // Send notification through Firebase Cloud Functions
      await _firestore.collection('notifications').add({
        'tokens': tokens,
        'title': "It's Froupin' time!",
        'body': 'Time to start swiping! Complete your 10 daily swipes.',
        'type': 'group_vote',
        'groupId': groupId,
        'timestamp': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('Error sending notifications: $e');
    }
  }
}
