enum GearType { tent, sleepingBag, backpack, stove, etc }

GearType gearTypeFromString(String type) {
  switch (type) {
    case 'tent': return GearType.tent;
    case 'sleepingBag': return GearType.sleepingBag;
    case 'backpack': return GearType.backpack;
    case 'stove': return GearType.stove;
    default: return GearType.etc;
  }
}

class Gear {
  final String uid;
  final String gid;
  final String gearName;
  final String manufacturer;
  final GearType type;
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
      type: gearTypeFromString(data['type'] ?? ''),
      weight: data['weight'] ?? 0,
      quantity: data['quantity'] ?? 0,
      imgUrl: data['img_url'] ?? '',
    );
  }
}