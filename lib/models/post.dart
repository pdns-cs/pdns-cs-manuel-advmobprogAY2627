class Post {
  final int id;
  final String title;
  final String body;
  final List<String> tags;
  final int likes;
  final int dislikes;
  final int views;
  final int userId;

  Post({
    required this.id,
    required this.title,
    required this.body,
    required this.tags,
    required this.likes,
    required this.dislikes,
    required this.views,
    required this.userId,
  });

  factory Post.fromJson(Map<String, dynamic> json) {
    final reactions = json['reactions'] is Map<String, dynamic>
        ? json['reactions'] as Map<String, dynamic>
        : <String, dynamic>{};

    return Post(
      id: json['id'] ?? 0,
      title: json['title'] ?? '',
      body: json['body'] ?? '',
      tags: (json['tags'] as List<dynamic>? ?? [])
          .map((tag) => tag.toString())
          .toList(),
      likes: reactions['likes'] ?? 0,
      dislikes: reactions['dislikes'] ?? 0,
      views: json['views'] ?? 0,
      userId: json['userId'] ?? 0,
    );
  }
}
