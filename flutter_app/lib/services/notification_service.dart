import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';

class NotificationService {
  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  static final GlobalKey<ScaffoldMessengerState> messengerKey =
      GlobalKey<ScaffoldMessengerState>();
  static final GlobalKey<NavigatorState> navigatorKey =
      GlobalKey<NavigatorState>();

  // Static flag to indicate if a permission request is already in progress
  static bool _isPermissionRequestInProgress = false;

  // Initialize notification settings and request permissions
  Future<void> initialize() async {
    // If a permission request is already happening, skip this call
    if (_isPermissionRequestInProgress) {
      print('Permission request already in progress, skipping initialization.');
      return;
    }

    _isPermissionRequestInProgress = true;
    try {
      // Set up background message handler
      FirebaseMessaging.onBackgroundMessage(
          _firebaseMessagingBackgroundHandler);

      // Request notification permissions using FirebaseMessaging
      NotificationSettings settings = await _messaging.requestPermission(
        alert: true,
        announcement: false,
        badge: true,
        carPlay: false,
        criticalAlert: false,
        provisional: false,
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
    } catch (e) {
      print('Failed to initialize notifications: $e');
    } finally {
      // Reset the flag so future calls can proceed
      _isPermissionRequestInProgress = false;
    }
  }

  // Background message handler
  static Future<void> _firebaseMessagingBackgroundHandler(
      RemoteMessage message) async {
    print("Handling a background message: ${message.messageId}");
    // Ensure Firebase is initialized
    if (Firebase.apps.isEmpty) {
      await Firebase.initializeApp();
    }
    // The notification will be shown automatically by the system
  }

  // Handle foreground messages
  void _handleForegroundMessage(RemoteMessage message) {
    print("Received foreground message: ${message.notification?.title}");
    // Show a simple dialog or snackbar when a message is received
    if (message.notification != null) {
      final messenger = messengerKey.currentState;
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
      } else {
        print("Could not show notification: no messenger state available");
      }
    }
  }

  // Handle background messages
  void _handleBackgroundMessage(RemoteMessage message) {
    // Handle notification tap when app is in background
    _handleNotificationTap(message.data);
  }

  // Handle notification tap
  Future<void> _handleNotificationTap(Map<String, dynamic> data) async {
    // Handle different types of notifications
    if (data['type'] == 'group_vote' && data['groupId'] != null) {
      print('Navigating to group ${data['groupId']} for voting');
      try {
        // Fetch group name from Firestore
        final groupDoc =
            await _firestore.collection('groups').doc(data['groupId']).get();
        final groupName =
            groupDoc.data()?['name'] as String? ?? 'Unknown Group';

        // Navigate to group preferences screen
        navigatorKey.currentState?.pushNamed(
          '/group_preferences',
          arguments: {'groupId': data['groupId'], 'groupName': groupName},
        );
      } catch (e) {
        print('Error navigating to group: $e');
        final messenger = messengerKey.currentState;
        if (messenger != null) {
          messenger.showSnackBar(
            SnackBar(
              content: Text('Error opening group: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
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
}
