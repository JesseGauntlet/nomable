import 'package:cloud_firestore/cloud_firestore.dart';

class UserCacheService {
  static final UserCacheService _instance = UserCacheService._internal();
  factory UserCacheService() => _instance;
  UserCacheService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final Map<String, String> _userNameCache = {};
  final Map<String, String?> _userPhotoCache = {};

  Future<(String, String?)> getUserInfo(String userId) async {
    // Check cache first
    if (_userNameCache.containsKey(userId) &&
        _userPhotoCache.containsKey(userId)) {
      return (_userNameCache[userId]!, _userPhotoCache[userId]);
    }

    try {
      final doc = await _firestore.collection('users').doc(userId).get();
      if (!doc.exists) {
        return ('Unknown User', null);
      }

      final name = doc.data()?['name'] as String? ?? 'Unknown User';
      final photoUrl = doc.data()?['photoUrl'] as String?;

      // Cache the results
      _userNameCache[userId] = name;
      _userPhotoCache[userId] = photoUrl;

      return (name, photoUrl);
    } catch (e) {
      print('Error fetching user info: $e');
      return ('Unknown User', null);
    }
  }

  Future<String> getUserName(String userId) async {
    final (name, _) = await getUserInfo(userId);
    return name;
  }

  Future<String?> getUserPhoto(String userId) async {
    final (_, photoUrl) = await getUserInfo(userId);
    return photoUrl;
  }

  void clearCache() {
    _userNameCache.clear();
    _userPhotoCache.clear();
  }
}
