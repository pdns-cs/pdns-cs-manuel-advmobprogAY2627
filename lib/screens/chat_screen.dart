import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../services/chat_service.dart';
import '../services/user_service.dart';
import '../widgets/custom_text.dart';
import 'chatdetail_screen.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _searchChatController = TextEditingController();
  final ChatService _chatService = ChatService();
  final Map<String, Stream<int>> _unreadCountStreams = {};
  final Map<String, Timestamp?> _latestMessageTimestamps = {};
  final Map<String, StreamSubscription<Timestamp?>>
  _latestMessageSubscriptions = {};
  Set<String> _subscribedUserIds = {};
  String? _currentUserEmail;
  String? _currentUserId;
  String _searchText = '';

  Stream<int> _unreadCountStream(String userId) {
    return _unreadCountStreams.putIfAbsent(
      userId,
      () => _chatService.getUnreadMessageCount(userId),
    );
  }

  @override
  void initState() {
    super.initState();
    _loadCurrentUserEmail();
  }

  Future<void> _loadCurrentUserEmail() async {
    final userData = await userService.value.getUserData();
    if (!mounted) return;
    setState(() {
      _currentUserEmail = userData['email'];
      _currentUserId = (userData['uid'] ?? '').toString();
    });
  }

  void _watchLatestMessages(List<Map<String, dynamic>> users) {
    final currentUserId = _currentUserId;
    if (currentUserId == null || currentUserId.isEmpty) return;

    final userIds = users
        .map((user) => (user['uid'] ?? '').toString())
        .where((userId) => userId.isNotEmpty)
        .toSet();
    for (final userId in _subscribedUserIds.difference(userIds)) {
      unawaited(_latestMessageSubscriptions.remove(userId)?.cancel());
      _latestMessageTimestamps.remove(userId);
    }
    _subscribedUserIds = userIds;

    for (final userId in userIds.difference(
      _latestMessageSubscriptions.keys.toSet(),
    )) {
      _latestMessageSubscriptions[userId] = _chatService
          .getLatestMessageTimestamp(currentUserId, userId)
          .listen(
            (timestamp) {
              if (!mounted ||
                  _latestMessageTimestamps[userId] == timestamp) {
                return;
              }
              setState(() {
                _latestMessageTimestamps[userId] = timestamp;
              });
            },
            onError: (Object error, StackTrace stackTrace) {
              debugPrint('Failed to load latest chat message: $error');
            },
          );
    }
  }

  @override
  void dispose() {
    _searchChatController.dispose();
    for (final subscription in _latestMessageSubscriptions.values) {
      unawaited(subscription.cancel());
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Chats')),
      body: SingleChildScrollView(
        child: Column(
          children: [
            SizedBox(height: 20.h),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 23.w),
              child: TextField(
                controller: _searchChatController,
                textInputAction: TextInputAction.search,
                onChanged: (value) =>
                    setState(() => _searchText = value.trim()),
                decoration: InputDecoration(
                  hintText: 'Search chat...',
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: _searchChatController.text.isNotEmpty
                      ? IconButton(
                          tooltip: 'Clear',
                          icon: const Icon(Icons.cancel),
                          onPressed: () {
                            setState(() {
                              _searchChatController.clear();
                              _searchText = '';
                            });
                          },
                        )
                      : null,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ),
            SizedBox(height: 10.h),
            StreamBuilder<List<Map<String, dynamic>>>(
              stream: _chatService.getUsersStream(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Container(
                    height: ScreenUtil().screenHeight * 0.6,
                    padding: EdgeInsets.all(16.sp),
                    child: const Center(
                      child: CircularProgressIndicator.adaptive(),
                    ),
                  );
                }
                if (snapshot.hasError) {
                  return Container(
                    height: ScreenUtil().screenHeight * 0.6,
                    padding: EdgeInsets.all(16.sp),
                    child: Center(
                      child: CustomText(
                        text: 'Error loading users',
                        fontSize: 16.sp,
                      ),
                    ),
                  );
                }
                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return Container(
                    height: ScreenUtil().screenHeight * 0.6,
                    padding: EdgeInsets.all(16.sp),
                    child: Center(
                      child: CustomText(
                        text: 'No users found',
                        fontSize: 16.sp,
                      ),
                    ),
                  );
                }

                final allUsers = snapshot.data!;
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (mounted) _watchLatestMessages(allUsers);
                });

                final query = _searchText.toLowerCase();
                final users = allUsers.where((user) {
                  final name = [
                    user['firstName'] ?? '',
                    user['lastName'] ?? '',
                  ].join(' ').toLowerCase();
                  final email = (user['email'] ?? '').toString().toLowerCase();
                  return name.contains(query) || email.contains(query);
                }).toList();
                final originalOrder = {
                  for (var index = 0; index < users.length; index++)
                    (users[index]['uid'] ?? '').toString(): index,
                };
                users.sort((first, second) {
                  final firstId = (first['uid'] ?? '').toString();
                  final secondId = (second['uid'] ?? '').toString();
                  final firstTimestamp = _latestMessageTimestamps[firstId];
                  final secondTimestamp = _latestMessageTimestamps[secondId];
                  if (firstTimestamp == null && secondTimestamp == null) {
                    return originalOrder[firstId]!.compareTo(
                      originalOrder[secondId]!,
                    );
                  }
                  if (firstTimestamp == null) return 1;
                  if (secondTimestamp == null) return -1;
                  final timeOrder = secondTimestamp.compareTo(firstTimestamp);
                  return timeOrder != 0
                      ? timeOrder
                      : originalOrder[firstId]!.compareTo(
                          originalOrder[secondId]!,
                        );
                });

                if (users.isEmpty) {
                  return Container(
                    height: ScreenUtil().screenHeight * 0.6,
                    padding: EdgeInsets.all(16.sp),
                    child: Center(
                      child: CustomText(
                        text: 'No users match your search',
                        fontSize: 16.sp,
                      ),
                    ),
                  );
                }

                return ListView.builder(
                  shrinkWrap: true,
                  padding: EdgeInsets.symmetric(horizontal: 16.w),
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: users.length,
                  itemBuilder: (context, index) {
                    final user = users[index];
                    final userId = (user['uid'] ?? '').toString();
                    return GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => ChatDetailScreen(
                              currentUserEmail: _currentUserEmail ?? '',
                              tappedUser: user,
                            ),
                          ),
                        );
                      },
                      child: Card(
                        child: ListTile(
                          leading: StreamBuilder<int>(
                            stream: _unreadCountStream(userId),
                            builder: (context, unreadSnapshot) {
                              final hasUnread = (unreadSnapshot.data ?? 0) > 0;
                              return Stack(
                                clipBehavior: Clip.none,
                                children: [
                                  CircleAvatar(
                                    child: CustomText(
                                      text:
                                          (user['firstName'] ?? '')
                                              .toString()
                                              .isNotEmpty
                                          ? user['firstName'][0].toUpperCase()
                                          : '?',
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  if (hasUnread)
                                    Positioned(
                                      top: -2,
                                      right: -2,
                                      child: Container(
                                        width: 12,
                                        height: 12,
                                        decoration: BoxDecoration(
                                          color: Colors.red,
                                          shape: BoxShape.circle,
                                          border: Border.all(
                                            color: Theme.of(context).cardColor,
                                            width: 2,
                                          ),
                                        ),
                                      ),
                                    ),
                                ],
                              );
                            },
                          ),
                          title: CustomText(
                            text: user['firstName'] ?? 'Unknown',
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                          subtitle: CustomText(
                            text: user['email'] ?? 'No email',
                            fontSize: 12,
                            fontWeight: FontWeight.w300,
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
