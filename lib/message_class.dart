import 'package:cloud_firestore/cloud_firestore.dart';

class Message {
  final String senderEmail;
  final String message;
  final Timestamp timestamp;
  final String messageId;

  Message({
    required this.senderEmail,
    required this.message,
    required this.timestamp,
    required this.messageId,
  });

  factory Message.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Message(
      senderEmail: data['senderEmail'],
      message: data['message'],
      timestamp: data['timestamp'],
      messageId: doc.id,
    );
  }
}
