import 'dart:convert';

import 'package:http/http.dart' as http;

import '../constants.dart';
import '../models/post.dart';

class PostService {
  Future<List<Post>> getAllPosts() async {
    final response = await http.get(Uri.parse('$host/posts'));

    if (response.statusCode == 200) {
      final Map<String, dynamic> data = jsonDecode(response.body);
      final List postsJson = data['posts'] ?? [];
      return postsJson.map((json) => Post.fromJson(json)).toList();
    } else {
      throw Exception('Failed to load posts');
    }
  }

  Future<List<Post>> getPostsByUserId(int userId) async {
    final response = await http.get(Uri.parse('$host/posts/user/$userId'));

    if (response.statusCode == 200) {
      final Map<String, dynamic> data = jsonDecode(response.body);
      final List postsJson = data['posts'] ?? [];
      return postsJson.map((json) => Post.fromJson(json)).toList();
    } else {
      throw Exception('Failed to load user posts');
    }
  }
}
