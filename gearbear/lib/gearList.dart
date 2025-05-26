import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'models/gear_model.dart';

class GearListPage extends StatefulWidget {
  const GearListPage({Key? key}) : super(key: key);

  @override
  State<GearListPage> createState() => _GearListPageState();
}

class _GearListPageState extends State<GearListPage> {
  bool _isDrawerOpen = false;

  void _toggleDrawer() {
    setState(() {
      _isDrawerOpen = !_isDrawerOpen;
    });
  }

  @override
  Widget build(BuildContext context) {
    final gearStream = FirebaseFirestore.instance.collection('gear').snapshots();
    
    return Scaffold(
      body: Stack(
        children: [
          // Main content
          Column(
            children: [
              AppBar(
                title: const Text('Gear List'),
                leading: IconButton(
                  icon: const Icon(Icons.menu),
                  onPressed: _toggleDrawer,
                ),
              ),
              Expanded(
                child: StreamBuilder<QuerySnapshot>(
                  stream: gearStream,
                  builder: (context, snapshot) {
                    if (snapshot.hasError) {
                      return Center(child: Text('Error occured: ${snapshot.error}'));
                    }
                
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return Center(child: CircularProgressIndicator());
                    }
                
                    final docs = snapshot.data?.docs ?? [];
                    final List<Gear> gearList = docs.map((doc) => Gear.fromFirestore(doc.data() as Map<String, dynamic>)).toList();
                
                    if (gearList.isEmpty) {
                      return Center(child: Text('No gears added.'));
                    }
                
                    return ListView.builder(
                      itemCount: gearList.length,
                      itemBuilder: (context, index) {
                        final gear = gearList[index];
                        return Card(
                          elevation: 3,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: ListTile(
                            contentPadding: const EdgeInsets.symmetric(
                              vertical: 12,
                              horizontal: 16,
                            ),
                            leading: SizedBox(
                          width: 56,
                          height: 56,
                          child: gear.imgUrl.isNotEmpty
                              ? ClipRRect(
                                  borderRadius: BorderRadius.circular(12),
                                  child: Image.network(
                                    gear.imgUrl,
                                    width: 56,
                                    height: 56,
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, error, stackTrace) => 
                                      Container(
                                        color: Colors.grey[200],
                                        child: const Icon(Icons.image_not_supported, size: 32, color: Colors.grey),
                                      ),
                                  ),
                                )
                              : Container(
                                  decoration: BoxDecoration(
                                    color: Colors.grey[200],
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: const Icon(Icons.image_not_supported, size: 32, color: Colors.grey),
                                ),
                            ),
                            title: Text(
                              gear.gearName,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 18,
                              ),
                            ),
                            subtitle: Padding(
                              padding: const EdgeInsets.only(top: 6.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    gear.manufacturer,
                                    style: TextStyle(
                                      color: Colors.blueGrey[700],
                                      fontSize: 14,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Row(
                                    children: [
                                      Icon(
                                        Icons.category,
                                        size: 16,
                                        color: Colors.blueGrey[400],
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        gear.type,
                                        style: const TextStyle(fontSize: 13),
                                      ),
                                      const SizedBox(width: 12),
                                      Icon(
                                        Icons.scale,
                                        size: 16,
                                        color: Colors.blueGrey[400],
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        '${gear.weight}g',
                                        style: const TextStyle(fontSize: 13),
                                      ),
                                      const SizedBox(width: 12),
                                      Icon(
                                        Icons.confirmation_num,
                                        size: 16,
                                        color: Colors.blueGrey[400],
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        'x${gear.quantity}',
                                        style: const TextStyle(fontSize: 13),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            trailing: Icon(
                              Icons.chevron_right,
                              color: Colors.grey[400],
                            ),
                            onTap: () {
                              // 상세 페이지 이동 등 원하는 동작 추가
                            },
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),

          // Floating drawer
          if (_isDrawerOpen)
            Positioned(
              top: 60,
              left: 10,
              child: Material(
                elevation: 6,
                borderRadius: BorderRadius.circular(10),
                color: Colors.white.withOpacity(0.95),
                child: Container(
                  width: 180,
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      ListTile(
                        title: const Text('Gear List'),
                        onTap: () {
                          // TODO: Navigate to Gear List
                          _toggleDrawer();
                        },
                      ),
                      ListTile(
                        title: const Text('Add Gear'),
                        onTap: () {
                          Navigator.pushNamed(context, '/add_gear');
                          _toggleDrawer();
                        },
                      ),
                      ListTile(
                        title: const Text('My Camp'),
                        onTap: () {
                          // TODO: Navigate to Summarization
                          _toggleDrawer();
                        },
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
