import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:manuel_mobile/widgets/custom_text.dart';

import '../services/chat_service.dart';
import '../services/user_service.dart';

final ChatService chatService = ChatService();

class ChatDetailScreen extends StatefulWidget {
  final String currentUserEmail;
  final Map<String, dynamic> tappedUser;

  const ChatDetailScreen({
    super.key,
    required this.currentUserEmail,
    required this.tappedUser,
  });

  @override
  State<ChatDetailScreen> createState() => _ChatDetailScreenState();
}

class _ChatDetailScreenState extends State<ChatDetailScreen> {
  final TextEditingController _msgCtrl = TextEditingController();
  final FocusNode _msgFocus = FocusNode();
  final ScrollController _scrollCtrl = ScrollController();

  late Future<String?> _currentUserIdFuture;
  bool _isSending = false;
  bool _markingSeen = false;

  @override
  void initState() {
    super.initState();
    _currentUserIdFuture = _getCurrentUserId();
  }

  Future<String?> _getCurrentUserId() async {
    final userData = await userService.value.getUserData();
    return (userData['uid'] ?? '').toString();
  }

  @override
  void dispose() {
    _msgCtrl.dispose();
    _msgFocus.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  Future<void> _send(String receiverId) async {
    final text = _msgCtrl.text.trim();
    if (text.isEmpty || _isSending) return;

    setState(() {
      _isSending = true;
    });

    try {
      await chatService.sendMessage(receiverId, text);
      _msgCtrl.clear();
      _msgFocus.requestFocus();

      if (_scrollCtrl.hasClients) {
        _scrollCtrl.animateTo(
          0.0,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to send: $e')));
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSending = false;
        });
      }
    }
  }

  Future<void> _markMessagesAsSeen(
    String currentUserId,
    String otherUserId,
    List<String> messageIds,
  ) async {
    try {
      await chatService.markMessagesAsSeen(
        currentUserId,
        otherUserId,
        messageIds,
      );
    } catch (error) {
      debugPrint('Failed to mark chat messages as seen: $error');
    } finally {
      _markingSeen = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final tappedUserId = (widget.tappedUser['uid'] ?? '').toString();
    final tappedUserName = [
      widget.tappedUser['firstName'] ?? '',
      widget.tappedUser['lastName'] ?? '',
    ].where((part) => part.toString().isNotEmpty).join(' ');

    return FutureBuilder<String?>(
      future: _currentUserIdFuture,
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        if (snap.hasError || !snap.hasData || snap.data!.isEmpty) {
          return const Scaffold(
            body: Center(child: Text('Error loading user data')),
          );
        }

        final currentUserId = snap.data!;

        return Scaffold(
          appBar: AppBar(
            centerTitle: true,
            title: CustomText(text: tappedUserName, fontSize: 25.sp),
          ),
          body: Column(
            children: [
              // Messages
              Expanded(
                child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                  stream: chatService.getMessage(currentUserId, tappedUserId),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    if (snapshot.hasError) {
                      return Center(
                        child: Text(
                          'Error loading messages: ${snapshot.error}',
                        ),
                      );
                    }

                    final docs = snapshot.data?.docs ?? [];
                    final unseenMessageIds = docs
                        .where((doc) {
                          final data = doc.data();
                          return data['senderId'] == tappedUserId &&
                              data['receiverId'] == currentUserId &&
                              data['status'] == 'delivered';
                        })
                        .map((doc) => doc.id)
                        .toList();

                    if (!_markingSeen && unseenMessageIds.isNotEmpty) {
                      _markingSeen = true;
                      WidgetsBinding.instance.addPostFrameCallback((_) {
                        unawaited(
                          _markMessagesAsSeen(
                            currentUserId,
                            tappedUserId,
                            unseenMessageIds,
                          ),
                        );
                      });
                    }

                    if (docs.isEmpty) {
                      return const Center(child: Text('No messages yet'));
                    }

                    return ListView.builder(
                      controller: _scrollCtrl,
                      reverse: true,
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      itemCount: docs.length,
                      itemBuilder: (context, index) {
                        final data = docs[index].data();
                        final msgText = (data['message'] ?? '')
                            .toString()
                            .trim();
                        final senderId = (data['senderId'] ?? '').toString();
                        final isMe = senderId == currentUserId;
                        final hasNewerReply =
                            isMe &&
                            docs
                                .take(index)
                                .any(
                                  (doc) =>
                                      doc.data()['senderId'] == tappedUserId,
                                );
                        final showStatus = isMe && !hasNewerReply;
                        final status = (data['status'] ?? 'delivered')
                            .toString();
                        final statusLabel = status == 'seen'
                            ? 'Seen'
                            : status == 'delivered'
                            ? 'Delivered'
                            : 'Sending...';
                        final statusIcon = status == 'seen'
                            ? Icons.done_all_rounded
                            : status == 'delivered'
                            ? Icons.done_rounded
                            : Icons.schedule_rounded;
                        final colorScheme = Theme.of(context).colorScheme;
                        final bubbleColor = isMe
                            ? colorScheme.secondary
                            : colorScheme.surface;
                        final bubbleTextColor = isMe
                            ? colorScheme.onSecondary
                            : colorScheme.onSurface;

                        return TweenAnimationBuilder<double>(
                          key: ValueKey(docs[index].id),
                          tween: Tween(begin: 0, end: 1),
                          duration: const Duration(milliseconds: 240),
                          curve: Curves.easeOutCubic,
                          builder: (context, progress, child) {
                            return Opacity(
                              opacity: progress,
                              child: Transform.translate(
                                offset: Offset(
                                  (isMe ? 1 : -1) * 14 * (1 - progress),
                                  8 * (1 - progress),
                                ),
                                child: child,
                              ),
                            );
                          },
                          child: Align(
                            alignment: isMe
                                ? Alignment.centerRight
                                : Alignment.centerLeft,
                            child: Container(
                              margin: const EdgeInsets.symmetric(
                                vertical: 5,
                                horizontal: 12,
                              ),
                              padding: const EdgeInsets.symmetric(
                                vertical: 8,
                                horizontal: 12,
                              ),
                              constraints: BoxConstraints(
                                maxWidth:
                                    MediaQuery.of(context).size.width * 0.78,
                              ),
                              decoration: BoxDecoration(
                                color: bubbleColor,
                                borderRadius: BorderRadius.only(
                                  topLeft: const Radius.circular(18),
                                  topRight: const Radius.circular(18),
                                  bottomLeft: Radius.circular(isMe ? 18 : 5),
                                  bottomRight: Radius.circular(isMe ? 5 : 18),
                                ),
                              ),
                              child: Stack(
                                children: [
                                  Padding(
                                    padding: EdgeInsets.only(
                                      bottom: showStatus ? 18 : 0,
                                    ),
                                    child: Text(
                                      msgText.isNotEmpty ? msgText : '(empty)',
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodyMedium
                                          ?.copyWith(color: bubbleTextColor),
                                    ),
                                  ),
                                  if (showStatus)
                                    Positioned(
                                      right: 0,
                                      bottom: 0,
                                      child: Tooltip(
                                        message: statusLabel,
                                        child: Icon(
                                          statusIcon,
                                          size: 14,
                                          color: bubbleTextColor.withValues(
                                            alpha: 0.9,
                                          ),
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),

              // Composer
              SafeArea(
                top: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _msgCtrl,
                          focusNode: _msgFocus,
                          enabled: !_isSending,
                          textInputAction: TextInputAction.send,
                          minLines: 1,
                          maxLines: 4,
                          onSubmitted: (_) => _send(tappedUserId),
                          decoration: InputDecoration(
                            hintText: 'Type a message...',
                            filled: true,
                            fillColor: Theme.of(
                              context,
                            ).colorScheme.surfaceContainerHighest,
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 18,
                              vertical: 12,
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(24),
                              borderSide: BorderSide(
                                color: Theme.of(context).colorScheme.outline,
                              ),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(24),
                              borderSide: BorderSide(
                                color: Theme.of(context).colorScheme.outline,
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(24),
                              borderSide: BorderSide(
                                color: Theme.of(context).colorScheme.primary,
                                width: 1.5,
                              ),
                            ),
                            isDense: true,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      _isSending
                          ? Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  'Sending...',
                                  style: Theme.of(
                                    context,
                                  ).textTheme.labelMedium,
                                ),
                                const SizedBox(width: 8),
                                const SizedBox(
                                  height: 22,
                                  width: 22,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                ),
                              ],
                            )
                          : IconButton.filled(
                              tooltip: 'Send message',
                              icon: const Icon(Icons.send_rounded),
                              onPressed: () => _send(tappedUserId),
                            ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
