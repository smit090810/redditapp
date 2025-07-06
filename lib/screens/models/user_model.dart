class UserModel {
  final String id;
  final String username;
  final String? name;
  final String? profileImageUrl;
  final String? bio;
  final int karma;
  final DateTime createdAt;
  final List<String> communities;

  UserModel({
    required this.id,
    required this.username,
    this.name,
    this.profileImageUrl,
    this.bio,
    required this.karma,
    required this.createdAt,
    required this.communities,
  });

  // Factory constructor to create a UserModel from a Firestore document
  factory UserModel.fromMap(Map<String, dynamic> map, String id) {
    return UserModel(
      id: id,
      username: map['username'] ?? '',
      name: map['name'],
      profileImageUrl: map['profileImageUrl'],
      bio: map['bio'],
      karma: map['karma'] ?? 0,
      createdAt: map['createdAt']?.toDate() ?? DateTime.now(),
      communities: List<String>.from(map['communities'] ?? []),
    );
  }

  // Convert UserModel to a Map for Firestore
  Map<String, dynamic> toMap() {
    return {
      'username': username,
      'name': name,
      'profileImageUrl': profileImageUrl,
      'bio': bio,
      'karma': karma,
      'createdAt': createdAt,
      'communities': communities,
    };
  }
}
