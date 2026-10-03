import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/message.dart';
import '../models/user.dart';

class ChatService {
  ChatService({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  Stream<List<User>> watchUsers(String currentUserId) {
    return _firestore.collection('users').snapshots().map((snapshot) {
      return snapshot.docs
          .where((document) => document.id != currentUserId)
          .map((document) {
            final data = document.data();
            final uid = data['uid'] as String? ?? document.id;

            return User.firebaseProfile(
              firebaseUid: uid,
              email: data['email'] as String? ?? '',
              username: data['username'] as String? ?? '',
              firstName: data['firstName'] as String? ?? '',
              lastName: data['lastName'] as String? ?? '',
              age: (data['age'] as num?)?.toInt() ?? 0,
              contactNumber: data['contactNumber'] as String? ?? '',
              image: data['image'] as String? ?? '',
            );
          })
          .where((user) => user.email.isNotEmpty)
          .toList()
        ..sort((a, b) => a.fullName.toLowerCase().compareTo(
              b.fullName.toLowerCase(),
            ));
    });
  }

  String conversationId(String firstUserId, String secondUserId) {
    final participants = [firstUserId, secondUserId]..sort();
    return participants.join('__');
  }

  Stream<List<Message>> watchMessages(
      String currentUserId, String otherUserId) {
    return _messages(currentUserId, otherUserId)
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs.map(Message.fromSnapshot).toList());
  }

  Future<void> sendMessage({
    required String senderId,
    required String senderEmail,
    required String receiverId,
    required String text,
  }) async {
    final trimmedText = text.trim();
    if (trimmedText.isEmpty) return;
    if (trimmedText.length > 4000) {
      throw const ChatServiceException(
          'Messages must be under 4,000 characters.');
    }

    final roomId = conversationId(senderId, receiverId);
    final participants = [senderId, receiverId]..sort();
    final room = _firestore.collection('chat_rooms').doc(roomId);

    await room.set({
      'participants': participants,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    await room.collection('messages').add({
      'senderId': senderId,
      'senderEmail': senderEmail,
      'receiverId': receiverId,
      'message': trimmedText,
      'timestamp': FieldValue.serverTimestamp(),
      'status': 'sent',
    });
  }

  Future<void> updateMessageStatus({
    required String senderId,
    required String receiverId,
    required String messageId,
    required String status,
  }) async {
    if (status != 'delivered' && status != 'seen') return;

    await _messages(senderId, receiverId).doc(messageId).update({
      'status': status,
    });
  }

  CollectionReference<Map<String, dynamic>> _messages(
    String firstUserId,
    String secondUserId,
  ) {
    return _firestore
        .collection('chat_rooms')
        .doc(conversationId(firstUserId, secondUserId))
        .collection('messages');
  }
}

class ChatServiceException implements Exception {
  const ChatServiceException(this.message);

  final String message;
}
