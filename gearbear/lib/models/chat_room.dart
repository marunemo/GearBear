import 'package:cloud_firestore/cloud_firestore.dart';

class ChatRoom {
  final String id;        // Firestore 문서 ID
  final String name;      // 채팅방 이름
  final DateTime date;    // 캠핑 예정 날짜
  final String ownerUid;  // 방장 UID
  final DateTime createdAt;
  final double latitude;  // 캠핑장 위도
  final double longitude; // 캠핑장 경도
  final List<String> participants; // 참가자 UID 리스트

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