import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String id;
  final String name;
  final String email;
  final String? photoUrl;
  final int videosCount;
  final int followersCount;
  final int followingCount;
  final String? bio;

  UserModel({
    required this.id,
    required this.name,
    required this.email,
    this.photoUrl,
    this.videosCount = 0,
    this.followersCount = 0,
    this.followingCount = 0,
    this.bio,
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
      bio: data['bio'],
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
      'bio': bio,
    };
  }

  UserModel copyWith({
    String? name,
    String? email,
    String? photoUrl,
    int? videosCount,
    int? followersCount,
    int? followingCount,
    String? bio,
  }) {
    return UserModel(
      id: id,
      name: name ?? this.name,
      email: email ?? this.email,
      photoUrl: photoUrl ?? this.photoUrl,
      videosCount: videosCount ?? this.videosCount,
      followersCount: followersCount ?? this.followersCount,
      followingCount: followingCount ?? this.followingCount,
      bio: bio ?? this.bio,
    );
  }
}
