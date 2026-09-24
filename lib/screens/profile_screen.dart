import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../models/comment.dart';
import '../models/post.dart';
import '../services/comment_service.dart';
import '../services/post_service.dart';
import '../services/user_service.dart';
import '../widgets/custom_text.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final UserService _userService = UserService();
  final PostService _postService = PostService();
  final CommentService _commentService = CommentService();

  Map<String, dynamic> _userData = {};
  List<Post> _posts = [];
  final Map<int, List<Comment>> _commentsByPostId = {};
  final Map<int, bool> _likedPosts = {};
  final Map<int, int> _likesByPostId = {};
  final Map<int, TextEditingController> _commentControllers = {};

  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  @override
  void dispose() {
    for (final controller in _commentControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _loadUserData() async {
    try {
      final data = await _userService.getUserData();
      if (!mounted) return;

      setState(() {
        _userData = data;
        _isLoading = false;
      });

      await _loadUserPosts();
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _loadUserPosts() async {
    final userId = _userData['id'] ?? 0;

    if (userId == 0) {
      setState(() {
        _posts = [];
      });
      return;
    }

    try {
      final posts = await _postService.getPostsByUserId(userId);
      final commentLists = await Future.wait(
        posts.map((post) => _commentService.getCommentsByPostId(post.id)),
      );

      if (!mounted) return;

      setState(() {
        _posts = posts;
        _commentsByPostId.clear();
        _likedPosts.clear();
        _likesByPostId.clear();

        for (var i = 0; i < posts.length; i++) {
          final post = posts[i];
          _commentsByPostId[post.id] = commentLists[i];
          _likesByPostId[post.id] = post.likes;
          _likedPosts[post.id] = false;
          _commentControllers.putIfAbsent(
            post.id,
            () => TextEditingController(),
          );
        }
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _posts = [];
      });
    }
  }

  void _toggleLike(int postId) {
    setState(() {
      final isLiked = _likedPosts[postId] ?? false;
      final currentLikes = _likesByPostId[postId] ?? 0;

      _likedPosts[postId] = !isLiked;
      _likesByPostId[postId] = isLiked ? currentLikes - 1 : currentLikes + 1;
    });
  }

  Future<void> _addComment(int postId) async {
    final controller = _commentControllers[postId];
    final text = controller?.text.trim() ?? '';

    if (text.isEmpty) {
      return;
    }

    final userId = _userData['id'] ?? 0;
    if (userId == 0) {
      return;
    }

    try {
      final newComment = await _commentService.addComment(
        postId: postId,
        body: text,
        userId: userId,
      );

      if (!mounted) return;

      setState(() {
        final existingComments = _commentsByPostId[postId] ?? [];
        _commentsByPostId[postId] = [newComment, ...existingComments];
        controller?.clear();
      });
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Unable to add comment right now.')),
        );
      }
    }
  }

  String _fullName() {
    final firstName = (_userData['firstName'] ?? '').toString().trim();
    final lastName = (_userData['lastName'] ?? '').toString().trim();
    final fullName = '$firstName $lastName'.trim();

    return fullName.isEmpty
        ? (_userData['username'] ?? 'User').toString()
        : fullName;
  }

  String _userEmail() {
    return (_userData['email'] ?? 'No email').toString();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(16.w, 16.h, 16.w, 16.h),
      child: Column(
        children: [
          Container(
            width: double.infinity,
            padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 22.h),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24.r),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.08),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              children: [
                SizedBox(
                  width: 120.w,
                  height: 120.w,
                  child: _buildAvatarPattern(),
                ),
                SizedBox(height: 18.h),
                CustomText(
                  text: _fullName(),
                  fontSize: 22.sp,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF1D2238),
                ),
                SizedBox(height: 6.h),
                CustomText(
                  text: '@${(_userData['username'] ?? 'user').toString()}',
                  fontSize: 16.sp,
                  fontWeight: FontWeight.w500,
                  color: const Color(0xFF6F7592),
                ),
              ],
            ),
          ),
          SizedBox(height: 20.h),
          Container(
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(22.r),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.06),
                  blurRadius: 10,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Column(
              children: [
                _infoRow(
                  icon: Icons.mail_outline_rounded,
                  iconColor: const Color(0xFF5B7AE5),
                  label: 'Email',
                  value: _userEmail(),
                ),
                _divider(),
                _infoRow(
                  icon: Icons.person_outline_rounded,
                  iconColor: const Color(0xFFE5A64D),
                  label: 'Gender',
                  value: (_userData['gender'] ?? 'female').toString(),
                ),
                _divider(),
                _infoRow(
                  icon: Icons.badge_outlined,
                  iconColor: const Color(0xFF43B3AE),
                  label: 'User ID',
                  value: '#${(_userData['id'] ?? 1).toString()}',
                ),
              ],
            ),
          ),
          SizedBox(height: 22.h),
          Align(
            alignment: Alignment.centerLeft,
            child: CustomText(
              text: 'My Posts',
              fontSize: 18.sp,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF1D2238),
            ),
          ),
          SizedBox(height: 10.h),
          if (_posts.isEmpty)
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(16.r),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16.r),
              ),
              child: CustomText(
                text: 'No posts found for this user.',
                fontSize: 14.sp,
                color: const Color(0xFF6F7592),
              ),
            )
          else
            ..._posts.map((post) => _buildPostCard(post)),
          SizedBox(height: 22.h),
          SizedBox(
            width: double.infinity,
            height: 58.h,
            child: ElevatedButton.icon(
              onPressed: () async {
                await _userService.logout();
                if (!mounted) return;
                if (!context.mounted) return;

                Navigator.pushNamedAndRemoveUntil(
                  context,
                  '/signin',
                  (route) => false,
                );
              },
              icon: Icon(Icons.logout_rounded, size: 24.sp, color: Colors.white),
              label: CustomText(
                text: 'Log Out',
                fontSize: 18.sp,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFEF6B56),
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18.r),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPostCard(Post post) {
    final comments = _commentsByPostId[post.id] ?? const <Comment>[];
    final controller = _commentControllers.putIfAbsent(
      post.id,
      () => TextEditingController(),
    );
    final liked = _likedPosts[post.id] ?? false;
    final likes = _likesByPostId[post.id] ?? post.likes;

    return Container(
      width: double.infinity,
      margin: EdgeInsets.only(bottom: 12.h),
      padding: EdgeInsets.all(14.r),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: CustomText(
                  text: post.title,
                  fontSize: 15.sp,
                  fontWeight: FontWeight.w700,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              SizedBox(width: 8.w),
              InkWell(
                onTap: () => _toggleLike(post.id),
                borderRadius: BorderRadius.circular(20.r),
                child: Row(
                  children: [
                    Icon(
                      liked ? Icons.favorite : Icons.favorite_border,
                      size: 16.sp,
                      color: liked ? Colors.red : Colors.grey,
                    ),
                    SizedBox(width: 4.w),
                    CustomText(
                      text: likes.toString(),
                      fontSize: 12.sp,
                      color: const Color(0xFF6F7592),
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: 8.h),
          CustomText(
            text: post.body,
            fontSize: 12.sp,
            color: const Color(0xFF4F5670),
            maxLines: 4,
            overflow: TextOverflow.ellipsis,
          ),
          SizedBox(height: 10.h),
          Wrap(
            spacing: 6.w,
            runSpacing: 6.h,
            children: post.tags
                .map(
                  (tag) => Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: 8.w,
                      vertical: 4.h,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE8ECFF),
                      borderRadius: BorderRadius.circular(999.r),
                    ),
                    child: CustomText(
                      text: '#$tag',
                      fontSize: 10.sp,
                      color: const Color(0xFF4B63C7),
                    ),
                  ),
                )
                .toList(),
          ),
          SizedBox(height: 12.h),
          CustomText(
            text: 'Comments',
            fontSize: 13.sp,
            fontWeight: FontWeight.w700,
            color: const Color(0xFF1D2238),
          ),
          SizedBox(height: 8.h),
          if (comments.isEmpty)
            CustomText(
              text: 'No comments yet.',
              fontSize: 11.sp,
              color: const Color(0xFF6F7592),
            )
          else
            ...comments.map(
              (comment) => Container(
                width: double.infinity,
                margin: EdgeInsets.only(bottom: 6.h),
                padding: EdgeInsets.all(10.r),
                decoration: BoxDecoration(
                  color: const Color(0xFFF5F6FA),
                  borderRadius: BorderRadius.circular(12.r),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.person_outline_rounded, size: 14.sp),
                        SizedBox(width: 4.w),
                        Expanded(
                          child: CustomText(
                            text: comment.userFullName.isNotEmpty
                                ? comment.userFullName
                                : comment.username,
                            fontSize: 11.sp,
                            fontWeight: FontWeight.w600,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        CustomText(
                          text: '${comment.likes} likes',
                          fontSize: 10.sp,
                          color: const Color(0xFF6F7592),
                        ),
                      ],
                    ),
                    SizedBox(height: 4.h),
                    CustomText(
                      text: comment.body,
                      fontSize: 11.sp,
                      color: const Color(0xFF4F5670),
                    ),
                  ],
                ),
              ),
            ),
          SizedBox(height: 10.h),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: controller,
                  decoration: InputDecoration(
                    hintText: 'Add comment...',
                    isDense: true,
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 12.w,
                      vertical: 10.h,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10.r),
                    ),
                  ),
                ),
              ),
              SizedBox(width: 8.w),
              SizedBox(
                height: 38.h,
                child: ElevatedButton(
                  onPressed: () => _addComment(post.id),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1F2D6D),
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(horizontal: 12.w),
                  ),
                  child: const Icon(Icons.send_rounded),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAvatarPattern() {
    final colors = [
      const Color(0xFF8FE1D4),
      const Color(0xFFE6D26F),
      const Color(0xFFD8E2F2),
      const Color(0xFF6DBDB8),
      const Color(0xFFF4E7A3),
      const Color(0xFF9ED1C1),
    ];

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFE7F4F2),
        borderRadius: BorderRadius.circular(28.r),
      ),
      padding: EdgeInsets.all(18.w),
      child: GridView.builder(
        padding: EdgeInsets.zero,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: 9,
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          crossAxisSpacing: 6.w,
          mainAxisSpacing: 6.h,
        ),
        itemBuilder: (context, index) {
          return Container(
            decoration: BoxDecoration(
              color: colors[index % colors.length],
              borderRadius: BorderRadius.circular(10.r),
            ),
          );
        },
      ),
    );
  }

  Widget _divider() {
    return Divider(
      height: 1,
      thickness: 1,
      color: const Color(0xFFE8EAF1),
      indent: 16.w,
      endIndent: 16.w,
    );
  }

  Widget _infoRow({
    required IconData icon,
    required Color iconColor,
    required String label,
    required String value,
  }) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 18.w, vertical: 12.h),
      child: Row(
        children: [
          Container(
            width: 32.w,
            height: 32.w,
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(10.r),
            ),
            child: Icon(icon, color: iconColor, size: 20.sp),
          ),
          SizedBox(width: 14.w),
          Expanded(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  child: CustomText(
                    text: label,
                    fontSize: 17.sp,
                    fontWeight: FontWeight.w500,
                    color: const Color(0xFF1D2238),
                  ),
                ),
                SizedBox(width: 10.w),
                Flexible(
                  child: Align(
                    alignment: Alignment.centerRight,
                    child: CustomText(
                      text: value,
                      fontSize: 15.sp,
                      fontWeight: FontWeight.w500,
                      color: const Color(0xFF6F7592),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
