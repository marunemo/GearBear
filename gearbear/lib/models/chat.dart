import 'package:cloud_firestore/cloud_firestore.dart';

class ChatMessage {
  final String id;        
  final String senderUid;   
  final String senderName;  
  final String message;      
  final Timestamp timestamp; 

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