import 'package:cloud_firestore/cloud_firestore.dart';

class FeedItem {
  final String id;
  final String userId;
  final String mediaUrl;
  final String? previewUrl;
  final String? hlsUrl;
  final bool previewGenerated;
  final String mediaType;
  final List<String> foodTags;
  final String description;
  final int swipeCounts;
  int heartCount;
  final int bookmarkCount;
  final DateTime? createdAt;
  final List<dynamic>? recipe;
  final List<dynamic>? ingredients;
  // Content moderation fields
  final bool? isFoodRelated;
  final bool? isNsfw;
  final String? moderationReason;

  FeedItem({
    required this.id,
    required this.userId,
    required this.mediaUrl,
    this.previewUrl,
    this.hlsUrl,
    this.previewGenerated = false,
    required this.mediaType,
    required this.foodTags,
    this.description = '',
    this.swipeCounts = 0,
    this.heartCount = 0,
    this.bookmarkCount = 0,
    this.createdAt,
    this.recipe,
    this.ingredients,
    this.isFoodRelated,
    this.isNsfw,
    this.moderationReason,
  });

  factory FeedItem.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    // Extract content moderation data
    final contentModeration =
        data['content_moderation'] as Map<String, dynamic>?;

    return FeedItem(
      id: doc.id,
      userId: data['userId'] as String,
      mediaUrl: data['mediaUrl'] as String,
      previewUrl: data['previewUrl'] as String?,
      hlsUrl: data['hlsUrl'] as String?,
      previewGenerated: data['previewGenerated'] as bool? ?? false,
      mediaType: data['mediaType'] as String,
      foodTags: List<String>.from(data['foodTags'] ?? []),
      description: data['description'] as String? ?? '',
      swipeCounts: data['swipeCounts'] as int? ?? 0,
      heartCount: data['heartCount'] as int? ?? 0,
      bookmarkCount: data['bookmarkCount'] as int? ?? 0,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
      recipe: data['recipe'] as List<dynamic>?,
      ingredients: data['ingredients'] as List<dynamic>?,
      // Add content moderation fields
      isFoodRelated: contentModeration?['is_food_related'] as bool?,
      isNsfw: contentModeration?['is_nsfw'] as bool?,
      moderationReason: contentModeration?['reason'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'mediaUrl': mediaUrl,
      'previewUrl': previewUrl,
      'hlsUrl': hlsUrl,
      'previewGenerated': previewGenerated,
      'mediaType': mediaType,
      'foodTags': foodTags,
      'description': description,
      'swipeCounts': swipeCounts,
      'heartCount': heartCount,
      'bookmarkCount': bookmarkCount,
      if (createdAt != null) 'createdAt': Timestamp.fromDate(createdAt!),
    };
  }

  @override
  String toString() {
    return 'FeedItem(id: $id, userId: $userId, mediaType: $mediaType, description: $description)';
  }
}
