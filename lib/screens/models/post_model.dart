class PostModel {
  final String id;
  final String title;
  final String content;
  final String authorId;
  final String authorName;
  final String communityName;
  final String? imageUrl;
  final int upvotes;
  final int downvotes;
  final int commentCount;
  final DateTime createdAt;

  PostModel({
    required this.id,
    required this.title,
    required this.content,
    required this.authorId,
    required this.authorName,
    required this.communityName,
    this.imageUrl,
    required this.upvotes,
    required this.downvotes,
    required this.commentCount,
    required this.createdAt,
  });

  int get score => upvotes - downvotes;

  // Factory constructor to create a PostModel from a Firestore document
  factory PostModel.fromMap(Map<String, dynamic> map, String id) {
    return PostModel(
      id: id,
      title: map['title'] ?? '',
      content: map['content'] ?? '',
      authorId: map['authorId'] ?? '',
      authorName: map['authorName'] ?? '',
      communityName: map['communityName'] ?? '',
      imageUrl: map['imageUrl'],
      upvotes: map['upvotes'] ?? 0,
      downvotes: map['downvotes'] ?? 0,
      commentCount: map['commentCount'] ?? 0,
      createdAt: map['createdAt']?.toDate() ?? DateTime.now(),
    );
  }

  // Convert PostModel to a Map for Firestore
  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'content': content,
      'authorId': authorId,
      'authorName': authorName,
      'communityName': communityName,
      'imageUrl': imageUrl,
      'upvotes': upvotes,
      'downvotes': downvotes,
      'commentCount': commentCount,
      'createdAt': createdAt,
    };
  }
}
