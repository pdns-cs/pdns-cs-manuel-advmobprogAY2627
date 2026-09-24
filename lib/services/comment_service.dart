import 'dart:convert';

import 'package:http/http.dart' as http;

import '../constants.dart';
import '../models/comment.dart';

class CommentService {
  Future<List<Comment>> getCommentsByPostId(int postId) async {
    final response = await http.get(Uri.parse('$host/comments/post/$postId'));

    if (response.statusCode == 200) {
      final Map<String, dynamic> data = jsonDecode(response.body);
      final List commentsJson = data['comments'] ?? [];
      return commentsJson.map((json) => Comment.fromJson(json)).toList();
    } else {
      throw Exception('Failed to load comments');
    }
  }

  Future<Comment> addComment({
    required int postId,
    required String body,
    required int userId,
  }) async {
    final response = await http.post(
      Uri.parse('$host/comments/add'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'body': body,
        'postId': postId,
        'userId': userId,
      }),
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      final Map<String, dynamic> data = jsonDecode(response.body);
      return Comment.fromJson(data);
    } else {
      throw Exception('Failed to add comment');
    }
  }
}
