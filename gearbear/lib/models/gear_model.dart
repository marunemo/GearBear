import 'package:cloud_firestore/cloud_firestore.dart';

final categories = [
  'Tent',
  'Sleeping Bag',
  'Matt',
  'BackPack',
  'Cook Set',
  'Clothes',
  'Electonics',
  'etc'
];

class Gear {
  final String uid;
  final String gid;
  final String gearName;
  final String manufacturer;
  final String type;
  final int weight;
  final int quantity;
  final String imgUrl;

  Gear({
    required this.uid,
    required this.gid,
    required this.gearName,
    required this.manufacturer,
    required this.type,
    required this.weight,
    required this.quantity,
    required this.imgUrl,
  });

  factory Gear.fromFirestore(Map<String, dynamic> data) {
    return Gear(
      uid: data['uid'] ?? '',
      gid: data['gid'] ?? '',
      gearName: data['gear_name'] ?? '',
      manufacturer: data['manufacturer'] ?? '',
      type: data['type'] ?? '',
      weight: data['weight'] ?? 0,
      quantity: data['quantity'] ?? 0,
      imgUrl: data['img_url'] ?? ''
    );
  }

  // toMap: Firestore에 저장할 때 사용
  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'gid': gid,
      'gear_name': gearName,
      'manufacturer': manufacturer,
      'type': type,
      'weight': weight,
      'quantity': quantity,
      'img_url': imgUrl,
    };
  }

  // fromDocument: Firestore에서 데이터를 읽어올 때 사용
  factory Gear.fromDocument(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Gear(
      uid: data['uid'],
      gid: data['gid'],
      gearName: data['gear_name'],
      manufacturer: data['manufacturer'],
      type: data['type'],
      weight: data['weight'],
      quantity: data['quantity'],
      imgUrl: data['img_url'],
    );
  }
}