import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/message.dart';

class ChatService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;

  Stream<List<Map<String, dynamic>>> getUsersStream() {
    final currentUserId = _firebaseAuth.currentUser?.uid;
    return _firestore.collection('chat_users').snapshots().map((snapshot) {
      return snapshot.docs
          .where((doc) => doc.id != currentUserId)
          .map((doc) => {...doc.data(), 'uid': doc.id})
          .toList();
    });
  }

  Future<void> sendMessage(String receiverId, String message) async {
    final currentUser = _firebaseAuth.currentUser;
    if (currentUser == null) {
      throw StateError('Sign in before sending messages.');
    }

    final newMessage = MessageModel(
      senderId: currentUser.uid,
      senderEmail: currentUser.email ?? '',
      receiverId: receiverId,
      message: message,
      timestamp: Timestamp.now(),
    );

    final ids = [currentUser.uid, receiverId]..sort();
    final chatRoomId = ids.join('_');
    final messages = _firestore
        .collection('chat_rooms')
        .doc(chatRoomId)
        .collection('messages');
    final messageRef = await messages.add({
      ...newMessage.toMap(),
      'status': 'sending',
    });
    await messageRef.update({
      'status': 'delivered',
      'deliveredAt': FieldValue.serverTimestamp(),
    });
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> getMessage(
    String userID,
    String otherUserID,
  ) {
    final ids = [userID, otherUserID]..sort();
    final chatRoomId = ids.join('_');
    return _firestore
        .collection('chat_rooms')
        .doc(chatRoomId)
        .collection('messages')
        .orderBy('timestamp', descending: true)
        .snapshots();
  }

  Stream<Timestamp?> getLatestMessageTimestamp(
    String userId,
    String otherUserId,
  ) {
    final ids = [userId, otherUserId]..sort();
    return _firestore
        .collection('chat_rooms')
        .doc(ids.join('_'))
        .collection('messages')
        .orderBy('timestamp', descending: true)
        .limit(1)
        .snapshots()
        .map((snapshot) {
          if (snapshot.docs.isEmpty) return null;
          final timestamp = snapshot.docs.first.data()['timestamp'];
          return timestamp is Timestamp ? timestamp : null;
        });
  }

  Stream<int> getUnreadMessageCount(String otherUserId) {
    final currentUserId = _firebaseAuth.currentUser?.uid;
    if (currentUserId == null) return Stream<int>.value(0);

    final ids = [currentUserId, otherUserId]..sort();
    return _firestore
        .collection('chat_rooms')
        .doc(ids.join('_'))
        .collection('messages')
        .where('receiverId', isEqualTo: currentUserId)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .where((doc) => doc.data()['status'] == 'delivered')
              .length,
        );
  }

  Future<void> markMessagesAsSeen(
    String userId,
    String otherUserId,
    List<String> messageIds,
  ) async {
    final ids = [userId, otherUserId]..sort();
    final messages = _firestore
        .collection('chat_rooms')
        .doc(ids.join('_'))
        .collection('messages');

    for (var start = 0; start < messageIds.length; start += 450) {
      final end = (start + 450).clamp(0, messageIds.length);
      final batch = _firestore.batch();
      for (final messageId in messageIds.sublist(start, end)) {
        batch.update(messages.doc(messageId), {
          'status': 'seen',
          'seenAt': FieldValue.serverTimestamp(),
        });
      }
      await batch.commit();
    }
  }

  Future<String?> getUidByEmail(String email) async {
    final q = await _firestore
        .collection('chat_users')
        .where('email', isEqualTo: email)
        .limit(1)
        .get();
    if (q.docs.isEmpty) return null;
    return q.docs.first.id;
  }
}
