import 'package:cloud_firestore/cloud_firestore.dart';

class ChatRoom {
  final String id;      
  final String name;  
  final DateTime date;   
  final String ownerUid;  
  final DateTime createdAt;
  final double latitude; 
  final double longitude; 
  final List<String> participants;

  ChatRoom({
    required this.id,
    required this.name,
    required this.date,
    required this.ownerUid,
    required this.createdAt,
    required this.latitude,
    required this.longitude,
    required this.participants,
  });

  factory ChatRoom.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return ChatRoom(
      id: doc.id,
      name: data['name'] ?? '',
      date: (data['date'] as Timestamp).toDate(),
      ownerUid: data['ownerUid'] ?? '',
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      latitude: (data['latitude'] as num?)?.toDouble() ?? 0.0,
      longitude: (data['longitude'] as num?)?.toDouble() ?? 0.0,
      participants: List<String>.from(data['participants'] ?? []),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'date': Timestamp.fromDate(date),
      'ownerUid': ownerUid,
      'createdAt': Timestamp.fromDate(createdAt),
      'latitude': latitude,
      'longitude': longitude,
      'participants': participants,
    };
  }
}