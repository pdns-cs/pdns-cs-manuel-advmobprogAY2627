class Comment {
  final int id;
  final String body;
  final int postId;
  final int likes;
  final int userId;
  final String username;
  final String userFullName;

  Comment({
    required this.id,
    required this.body,
    required this.postId,
    required this.likes,
    required this.userId,
    required this.username,
    required this.userFullName,
  });

  factory Comment.fromJson(Map<String, dynamic> json) {
    final user = json['user'] is Map<String, dynamic>
        ? json['user'] as Map<String, dynamic>
        : <String, dynamic>{};

    return Comment(
      id: json['id'] ?? 0,
      body: json['body'] ?? '',
      postId: json['postId'] ?? 0,
      likes: json['likes'] ?? 0,
      userId: user['id'] ?? 0,
      username: user['username'] ?? '',
      userFullName: user['fullName'] ?? '',
    );
  }
}
