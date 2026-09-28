import 'package:cloud_firestore/cloud_firestore.dart';

class Message {
  const Message({
    required this.id,
    required this.senderId,
    required this.receiverId,
    required this.text,
    required this.status,
    this.createdAt,
  });

  final String id;
  final String senderId;
  final String receiverId;
  final String text;
  final DateTime? createdAt;

  /// `sending` is local-only. Firestore messages use `sent` after the write
  /// succeeds; delivery/read states are not claimed without implementing them.
  final String status;

  factory Message.fromFirestore(String id, Map<String, dynamic> data) {
    final timestamp = data['createdAt'];
    return Message(
      id: id,
      senderId: data['senderId'] as String? ?? '',
      receiverId: data['receiverId'] as String? ?? '',
      text: data['text'] as String? ?? '',
      status: data['status'] as String? ?? 'sent',
      createdAt: timestamp is Timestamp ? timestamp.toDate() : null,
    );
  }
}
