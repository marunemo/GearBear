import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'models/chat_room.dart';
import 'models/camp_site.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import '../chatRoom.dart';

class MakeRSVPPage extends StatefulWidget {
  final CampSite campSite; 

  const MakeRSVPPage({Key? key, required this.campSite}) : super(key: key);

  @override
  State<MakeRSVPPage> createState() => _MakeRSVPPageState();
}

class _MakeRSVPPageState extends State<MakeRSVPPage> {
  @override
  Widget build(BuildContext context) {
    final latitude = widget.campSite.latitude;
    final longitude = widget.campSite.longitude;

    return Scaffold(
      appBar: AppBar(
        leading: BackButton(),
        title: Text(widget.campSite.name, overflow: TextOverflow.ellipsis),
        centerTitle: true,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('chat_room')
            .orderBy('date')
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return Center(child: CircularProgressIndicator());
          }
          final docs = snapshot.data!.docs;
          final filteredDocs = docs.where((doc) {
            final data = doc.data() as Map<String, dynamic>;
            return (data['latitude'] == latitude && data['longitude'] == longitude);
          }).toList();
          if (filteredDocs.isEmpty) {
            return Center(child: Text('No chat rooms created yet.'));
          }
          return ListView.builder(
            itemCount: filteredDocs.length,
            itemBuilder: (context, idx) {
              final room = ChatRoom.fromFirestore(filteredDocs[idx]);
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: ListTile(
                  title: Text(room.name, style: TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text('Planned Date: ${DateFormat('yyyy-MM-dd').format(room.date)}'),
                  trailing: Icon(Icons.arrow_forward_ios, size: 16),
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
      floatingActionButton: FloatingActionButton.small(
        onPressed: () => showAddRoomDialog(context, latitude, longitude),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('+', style: TextStyle(fontSize: 20)),
          ],
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }

  void showAddRoomDialog(BuildContext context, double latitude, double longitude) {
    final _nameController = TextEditingController();
    DateTime? selectedDate;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return Padding(
          padding: MediaQuery.of(context).viewInsets.add(EdgeInsets.all(20)),
          child: StatefulBuilder(
            builder: (context, setModalState) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Chat Room Name', style: TextStyle(fontWeight: FontWeight.bold)),
                  TextField(
                    controller: _nameController,
                    decoration: InputDecoration(hintText: 'Enter chat room name'),
                  ),
                  SizedBox(height: 12),
                  Text('Planned Date', style: TextStyle(fontWeight: FontWeight.bold)),
                  Row(
                    children: [
                      Text(
                        selectedDate == null
                            ? 'Select a date'
                            : DateFormat('yyyy-MM-dd').format(selectedDate!),
                        style: TextStyle(fontSize: 16),
                      ),
                      Spacer(),
                      ElevatedButton(
                        onPressed: () async {
                          final now = DateTime.now();
                          final picked = await showDatePicker(
                            context: context,
                            initialDate: now,
                            firstDate: now,
                            lastDate: now.add(Duration(days: 365)),
                          );
                          if (picked != null) {
                            setModalState(() {
                              selectedDate = picked;
                            });
                          }
                        },
                        child: Text('Select Date'),
                      ),
                    ],
                  ),
                  SizedBox(height: 20),
                  Center(
                    child: ElevatedButton(
                      onPressed: () async {
                        final roomName = _nameController.text.trim();
                        if (roomName.isEmpty || selectedDate == null) return;
                        final user = FirebaseAuth.instance.currentUser;
                        if (user == null) return;
                        await FirebaseFirestore.instance
                            .collection('chat_room')
                            .add({
                          'name': roomName,
                          'date': Timestamp.fromDate(selectedDate!),
                          'ownerUid': user.uid,
                          'createdAt': Timestamp.now(),
                          'latitude': latitude,
                          'longitude': longitude,
                          'participants': [user.uid],
                        });
                        Navigator.pop(context);
                      },
                      child: Text('Create'),
                    ),
                  ),
                  SizedBox(height: 8),
                ],
              );
            },
          ),
        );
      },
    );
  }
}