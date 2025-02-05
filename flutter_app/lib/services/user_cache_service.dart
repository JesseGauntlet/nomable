import 'package:cloud_firestore/cloud_firestore.dart';

class UserCacheService {
  static final UserCacheService _instance = UserCacheService._internal();
  factory UserCacheService() => _instance;
  UserCacheService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final Map<String, String> _userNameCache = {};

  Future<String> getUserName(String userId) async {
    // Check cache first
    if (_userNameCache.containsKey(userId)) {
      return _userNameCache[userId]!;
    }

    try {
      final doc = await _firestore.collection('users').doc(userId).get();
      if (!doc.exists) {
        return 'Unknown User';
      }

      final name = doc.data()?['name'] as String? ?? 'Unknown User';
      // Cache the result
      _userNameCache[userId] = name;
      return name;
    } catch (e) {
      print('Error fetching user name: $e');
      return 'Unknown User';
    }
  }

  void clearCache() {
    _userNameCache.clear();
  }
}
