import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String id;
  final String name;
  final String email;
  final String? photoUrl;
  final int videosCount;
  final int followersCount;
  final int followingCount;
  final int heartCount; // Total likes received
  final int swipeCount; // Daily swipes count
  final String?
      fcmToken; // Firebase Cloud Messaging token for push notifications
  final String? bio;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final Map<String, int> foodPreferences;
  final String currentCraving;

  UserModel({
    required this.id,
    required this.name,
    required this.email,
    this.photoUrl,
    this.videosCount = 0,
    this.followersCount = 0,
    this.followingCount = 0,
    this.heartCount = 0,
    this.swipeCount = 0,
    this.fcmToken,
    this.bio,
    this.createdAt,
    this.updatedAt,
    this.foodPreferences = const {},
    this.currentCraving = '',
  });

  factory UserModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return UserModel(
      id: doc.id,
      name: data['name'] ?? '',
      email: data['email'] ?? '',
      photoUrl: data['photoUrl'],
      videosCount: data['videosCount'] ?? 0,
      followersCount: data['followersCount'] ?? 0,
      followingCount: data['followingCount'] ?? 0,
      heartCount: data['heartCount'] ?? 0,
      swipeCount: data['swipeCount'] ?? 0,
      fcmToken: data['fcmToken'],
      bio: data['bio'],
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate(),
      foodPreferences: Map<String, int>.from(data['foodPreferences'] ?? {}),
      currentCraving: data['currentCraving'] as String? ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'email': email,
      'photoUrl': photoUrl,
      'videosCount': videosCount,
      'followersCount': followersCount,
      'followingCount': followingCount,
      'heartCount': heartCount,
      'swipeCount': swipeCount,
      'fcmToken': fcmToken,
      'bio': bio,
      if (createdAt != null) 'createdAt': Timestamp.fromDate(createdAt!),
      if (updatedAt != null) 'updatedAt': Timestamp.fromDate(updatedAt!),
      'foodPreferences': foodPreferences,
      'currentCraving': currentCraving,
    };
  }

  UserModel copyWith({
    String? name,
    String? email,
    String? photoUrl,
    int? videosCount,
    int? followersCount,
    int? followingCount,
    int? heartCount,
    int? swipeCount,
    String? fcmToken,
    String? bio,
    DateTime? createdAt,
    DateTime? updatedAt,
    Map<String, int>? foodPreferences,
    String? currentCraving,
  }) {
    return UserModel(
      id: id,
      name: name ?? this.name,
      email: email ?? this.email,
      photoUrl: photoUrl ?? this.photoUrl,
      videosCount: videosCount ?? this.videosCount,
      followersCount: followersCount ?? this.followersCount,
      followingCount: followingCount ?? this.followingCount,
      heartCount: heartCount ?? this.heartCount,
      swipeCount: swipeCount ?? this.swipeCount,
      fcmToken: fcmToken ?? this.fcmToken,
      bio: bio ?? this.bio,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      foodPreferences: foodPreferences ?? this.foodPreferences,
      currentCraving: currentCraving ?? this.currentCraving,
    );
  }
}
