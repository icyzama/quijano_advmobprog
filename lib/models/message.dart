import 'package:cloud_firestore/cloud_firestore.dart';

class Message {
  const Message({
    required this.id,
    required this.senderId,
    required this.senderEmail,
    required this.receiverId,
    required this.text,
    required this.sentAt,
    required this.status,
  });

  final String id;
  final String senderId;
  final String senderEmail;
  final String receiverId;
  final String text;
  final DateTime? sentAt;
  final String status;

  factory Message.fromSnapshot(
    QueryDocumentSnapshot<Map<String, dynamic>> snapshot,
  ) {
    final data = snapshot.data();
    final timestamp = data['timestamp'];

    return Message(
      id: snapshot.id,
      senderId: data['senderId'] as String? ?? '',
      senderEmail: data['senderEmail'] as String? ?? '',
      receiverId: data['receiverId'] as String? ?? '',
      text: data['message'] as String? ?? '',
      sentAt: timestamp is Timestamp ? timestamp.toDate() : null,
      status: data['status'] as String? ?? 'sent',
    );
  }
}
