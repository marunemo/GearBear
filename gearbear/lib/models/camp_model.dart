class Camp {
  final String cid;
  final String uid;
  final String campName;
  final List<String> gidList;

  Camp({
    required this.cid,
    required this.uid,
    required this.campName,
    required this.gidList,
  });

  Map<String, dynamic> toMap() {
    return {
      'cid': cid,
      'uid': uid,
      'camp_name': campName,
      'gid_list': gidList,
    };
  }

  factory Camp.fromMap(String id, Map<String, dynamic> data) {
    return Camp(
      cid: id,
      uid: data['uid'] ?? '',
      campName: data['camp_name'] ?? '',
      gidList: List<String>.from(data['gid_list'] ?? []),
    );
  }
}