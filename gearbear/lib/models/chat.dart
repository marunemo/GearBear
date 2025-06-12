import 'package:cloud_firestore/cloud_firestore.dart';

class ChatMessage {
  final String id;            // Firestore 메시지 문서 ID
  final String senderUid;     // 보낸 사용자 UID
  final String senderName;    // 보낸 사용자 이름
  final String message;       // 메시지 텍스트
  final Timestamp timestamp;  // 메시지 전송 시간

  ChatMessage({
    required this.id,
    required this.senderUid,
    required this.senderName,
    required this.message,
    required this.timestamp,
  });

  factory ChatMessage.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return ChatMessage(
      id: doc.id,
      senderUid: data['senderUid'] ?? '',
      senderName: data['senderName'] ?? '',
      message: data['message'] ?? '',
      timestamp: data['timestamp'] ?? Timestamp.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'senderUid': senderUid,
      'senderName': senderName,
      'message': message,
      'timestamp': timestamp,
    };
  }
}