import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'models/chat_room.dart';
import '../chatRoom.dart';

class MyChatPage extends StatefulWidget {
  const MyChatPage({Key? key}) : super(key: key);

  @override
  State<MyChatPage> createState() => _MyChatPageState();
}

class _MyChatPageState extends State<MyChatPage> {
  bool _isDrawerOpen = false;

  void _toggleDrawer() {
    setState(() {
      _isDrawerOpen = !_isDrawerOpen;
    });
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('My Chat'),
        ),
        body: const Center(child: Text('Please log in.')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.menu),
          onPressed: _toggleDrawer,
        ),
        title: const Text('My Chat'),
        centerTitle: true,
      ),
      body: Stack(
        children: [
          // Main chat list content
          StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('chat_room')
                .where('participants', arrayContains: user.uid)
                .snapshots(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
              final docs = snapshot.data!.docs;
              docs.sort((a, b) {
                final adate = (a['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now();
                final bdate = (b['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now();
                return bdate.compareTo(adate); // 최신순
              });
              if (docs.isEmpty) {
                return const Center(child: Text('No chat rooms found.'));
              }
              return ListView.builder(
                itemCount: docs.length,
                itemBuilder: (context, idx) {
                  final room = ChatRoom.fromFirestore(docs[idx]);
                  return Card(
                    margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: ListTile(
                      title: Text(room.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: Text('Planned Date: ${room.date.toLocal().toIso8601String().split("T").first}'),
                      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => ChatRoomPage(chatRoom: room),
                          ),
                        );
                      },
                    ),
                  );
                },
              );
            },
          ),
          // Floating drawer (same structure as gearList.dart)
          if (_isDrawerOpen)
            Positioned(
              top: 0,
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
                          Navigator.pushNamed(context, '/');
                          _toggleDrawer();
                        },
                      ),
                      ListTile(
                        title: const Text('My Camp'),
                        onTap: () {
                          Navigator.pushNamed(context, '/my_camp');
                          _toggleDrawer();
                        },
                      ),
                      ListTile(
                        title: const Text('Camp Map'),
                        onTap: () {
                          Navigator.pushNamed(context, '/camp_map');
                          _toggleDrawer();
                        },
                      ),
                      ListTile(
                        title: const Text('Gear Doctor'),
                        onTap: () {
                          Navigator.pushNamed(context, '/gear_doctor');
                          _toggleDrawer();
                        },
                      ),
                      ListTile(
                        title: const Text('My Chat'),
                        onTap: () {
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