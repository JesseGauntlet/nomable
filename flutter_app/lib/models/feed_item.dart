class FeedItem {
  final String id;
  final String userId;
  final String videoUrl;
  final String description;
  final int likes;
  final int comments;

  FeedItem({
    required this.id,
    required this.userId,
    required this.videoUrl,
    required this.description,
    required this.likes,
    required this.comments,
  });

  factory FeedItem.fromJson(Map<String, dynamic> json) {
    return FeedItem(
      id: json['id'] as String,
      userId: json['userId'] as String,
      videoUrl: json['videoUrl'] as String,
      description: json['description'] as String,
      likes: json['likes'] as int,
      comments: json['comments'] as int,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'videoUrl': videoUrl,
      'description': description,
      'likes': likes,
      'comments': comments,
    };
  }
}
