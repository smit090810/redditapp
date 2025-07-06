class CommentModel {
  final String id;
  final String postId;
  final String content;
  final String authorId;
  final String authorName;
  final int upvotes;
  final int downvotes;
  final DateTime createdAt;

  CommentModel({
    required this.id,
    required this.postId,
    required this.content,
    required this.authorId,
    required this.authorName,
    required this.upvotes,
    required this.downvotes,
    required this.createdAt,
  });

  int get score => upvotes - downvotes;

  factory CommentModel.fromMap(Map<String, dynamic> map, String id) {
    return CommentModel(
      id: id,
      postId: map['postId'] ?? '',
      content: map['content'] ?? '',
      authorId: map['createdBy'] ?? '',
      authorName: map['authorName'] ?? 'Anonymous',
      upvotes: map['upvotes'] ?? 0,
      downvotes: map['downvotes'] ?? 0,
      createdAt: map['createdAt']?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'postId': postId,
      'content': content,
      'createdBy': authorId,
      'authorName': authorName,
      'upvotes': upvotes,
      'downvotes': downvotes,
      'createdAt': createdAt,
    };
  }
}
