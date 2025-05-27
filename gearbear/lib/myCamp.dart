import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/camp_model.dart';
import '../models/gear_model.dart';

class MyCampPage extends StatefulWidget {
  const MyCampPage({Key? key}) : super(key: key);

  @override
  State<MyCampPage> createState() => _MyCampPageState();
}

class _MyCampPageState extends State<MyCampPage> {
  bool _isDrawerOpen = false;
  Camp? _selectedCamp;
  List<Camp> _myCamps = [];
  List<Gear> _allGears = [];

  @override
  void initState() {
    super.initState();
    _fetchCamps();
    _fetchAllGears();
  }

  Future<void> _fetchCamps() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    final snapshot = await FirebaseFirestore.instance
        .collection('Camp')
        .where('uid', isEqualTo: uid)
        .get();

    final camps = snapshot.docs.map((doc) => Camp.fromMap(doc.id, doc.data())).toList();

    setState(() {
      _myCamps = camps;
      if (camps.isNotEmpty) _selectedCamp = camps[0];
    });
  }

  void _fetchAllGears() async {
    final snapshot = await FirebaseFirestore.instance.collection('Gear').get();
    final gears = snapshot.docs
        .map((doc) => Gear.fromFirestore(doc.data() as Map<String, dynamic>))
        .toList();

    setState(() {
      _allGears = gears;
    });
  }

  void _toggleDrawer() {
    setState(() {
      _isDrawerOpen = !_isDrawerOpen;
    });
  }

  List<Gear> _filterGearsByType(List<String> gids, List<String> types) {
    return _allGears.where((g) => gids.contains(g.gid) && types.contains(g.type)).toList();
  }

  Widget _buildGearSection(String title, List<Gear> gears, List<String> typeFilter) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12.0),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.deepPurple.shade50,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            ...gears.map((gear) => Dismissible(
              key: Key(gear.gid),
              direction: DismissDirection.endToStart,
              onDismissed: (_) async {
                final campRef = FirebaseFirestore.instance.collection('Camp').doc(_selectedCamp!.cid);
                await campRef.update({
                  'gid_list': FieldValue.arrayRemove([gear.gid])
                });
                setState(() {
                  _selectedCamp!.gidList.remove(gear.gid);
                });
              },
              background: Container(
                color: Colors.red,
                alignment: Alignment.centerRight,
                padding: const EdgeInsets.only(right: 20),
                child: const Icon(Icons.delete, color: Colors.white),
              ),
              child: ListTile(
                leading: gear.imgUrl.isNotEmpty
                    ? Image.network(gear.imgUrl, width: 40, height: 40, fit: BoxFit.cover)
                    : const Icon(Icons.image_not_supported),
                title: Text(gear.gearName),
                trailing: Text('${gear.weight} g'),
              ),
            )),
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: () {
                final selectedGids = <String>{};
                final currentGids = Set<String>.from(_selectedCamp?.gidList ?? []);
                final availableGears = _allGears
                    .where((g) => g.uid == FirebaseAuth.instance.currentUser?.uid && typeFilter.contains(g.type))
                    .toList();

                selectedGids.addAll(currentGids.where((gid) => availableGears.any((g) => g.gid == gid)));

                showDialog(
                  context: context,
                  builder: (context) {
                    return StatefulBuilder(
                      builder: (context, setStateDialog) {
                        return AlertDialog(
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                          title: const Text('Select Gear to Add'),
                          content: SizedBox(
                            width: double.maxFinite,
                            child: ListView(
                              shrinkWrap: true,
                              children: availableGears.map((gear) {
                                return CheckboxListTile(
                                  value: selectedGids.contains(gear.gid),
                                  onChanged: (bool? checked) {
                                    setStateDialog(() {
                                      if (checked == true) {
                                        selectedGids.add(gear.gid);
                                      } else {
                                        selectedGids.remove(gear.gid);
                                      }
                                    });
                                  },
                                  title: Text(gear.gearName),
                                );
                              }).toList(),
                            ),
                          ),
                          actions: [
                            TextButton(
                              onPressed: () async {
                                final groupGids = availableGears.map((g) => g.gid).toSet();
                                final currentGroupGids = currentGids.intersection(groupGids);
                                final newGidsToAdd = selectedGids.difference(currentGids);
                                final gidsToRemove = currentGroupGids.difference(selectedGids);
                                final campRef = FirebaseFirestore.instance.collection('Camp').doc(_selectedCamp!.cid);
                                if (newGidsToAdd.isNotEmpty) {
                                  await campRef.update({
                                    'gid_list': FieldValue.arrayUnion(newGidsToAdd.toList())
                                  });
                                }
                                if (gidsToRemove.isNotEmpty) {
                                  await campRef.update({
                                    'gid_list': FieldValue.arrayRemove(gidsToRemove.toList())
                                  });
                                }

                                Navigator.pop(context);
                                final currentCid = _selectedCamp!.cid;
                                await _fetchCamps();
                                setState(() {
                                  _selectedCamp = _myCamps.any((c) => c.cid == currentCid)
                                      ? _myCamps.firstWhere((c) => c.cid == currentCid)
                                      : (_myCamps.isNotEmpty ? _myCamps[0] : null);
                                });
                              },
                              child: const Text('Complete', style: TextStyle(color: Colors.deepPurple)),
                            ),
                          ],
                        );
                      },
                    );
                  },
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.deepPurple,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              ),
              child: const Text('Add gear'),
            )
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return const Center(child: Text("Please log in."));

    final gids = _selectedCamp?.gidList ?? [];
    final big4 = _filterGearsByType(gids, ['Tent', 'Sleeping Bag', 'Matt', 'BackPack']);
    final cook = _filterGearsByType(gids, ['Cook Set']);
    final clothes = _filterGearsByType(gids, ['Clothes']);
    final electronics = _filterGearsByType(gids, ['Electronics']);
    final etc = _filterGearsByType(gids, ['etc']);

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Camp'),
        leading: IconButton(icon: const Icon(Icons.menu), onPressed: _toggleDrawer),
        actions: [
          IconButton(
            icon: Icon(Icons.bar_chart),
            onPressed: () {
              // TODO: Navigate to chart page
            },
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          showModalBottomSheet(
            context: context,
            isScrollControlled: true,
            shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
            builder: (context) {
              final _campNameController = TextEditingController();
              return Padding(
                padding: EdgeInsets.only(
                  bottom: MediaQuery.of(context).viewInsets.bottom,
                  left: 20,
                  right: 20,
                  top: 20,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('Create New Camp', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _campNameController,
                      decoration: const InputDecoration(
                        labelText: 'Camp Name',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: () async {
                        final campName = _campNameController.text.trim();
                        final uid = FirebaseAuth.instance.currentUser?.uid;
                        if (campName.isNotEmpty && uid != null) {
                          final newDoc = FirebaseFirestore.instance.collection('Camp').doc();
                          final newCamp = Camp(
                            cid: newDoc.id,
                            uid: uid,
                            campName: campName,
                            gidList: [],
                          );
                          await newDoc.set(newCamp.toMap());
                          Navigator.of(context).pop();
                          _fetchCamps();
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.deepPurple,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Text('Save'),
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              );
            },
          );
        },
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
        child: const Icon(Icons.add),
      ),
      body: Stack(
        children: [
          if (_myCamps.isNotEmpty)
            Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: DropdownButton<Camp>(
                    value: _selectedCamp,
                    isExpanded: true,
                    items: _myCamps.map((c) => DropdownMenuItem(value: c, child: Text(c.campName))).toList(),
                    onChanged: (camp) => setState(() => _selectedCamp = camp),
                  ),
                ),
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    children: [
                      _buildGearSection("Big 4", big4, ['Tent', 'Sleeping Bag', 'Matt', 'BackPack']),
                      _buildGearSection("Cook Set", cook, ['Cook Set']),
                      _buildGearSection("Clothes", clothes, ['Clothes']),
                      _buildGearSection("Electronics", electronics, ['Electronics']),
                      _buildGearSection("etc", etc, ['etc']),
                    ],
                  ),
                )
              ],
            ),
          if (_isDrawerOpen)
            Positioned(
              top: 0,
              left: 10,
              child: Material(
                elevation: 6,
                borderRadius: BorderRadius.circular(10),
                color: Colors.white.withOpacity(0.95),
                child: SizedBox(
                  width: 180,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      ListTile(
                        title: const Text('Gear List'),
                        onTap: () {
                          Navigator.pushNamed(context, '/gear_list');
                          _toggleDrawer();
                        },
                      ),
                      ListTile(
                        title: const Text('My Camp'),
                        onTap: _toggleDrawer,
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}