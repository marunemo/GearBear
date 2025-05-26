import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'models/gear_model.dart';

class AddGearPage extends StatefulWidget {
  const AddGearPage({Key? key}) : super(key: key);

  @override
  _AddGearPageState createState() => _AddGearPageState();
}

class _AddGearPageState extends State<AddGearPage> {
  final _nameController = TextEditingController();
  final _weightController = TextEditingController();
  final _qtyController = TextEditingController();
  final _manufacturerController = TextEditingController();
  String _selectedType = 'Tent';
  File? _imageFile;

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _imageFile = File(pickedFile.path);
      });
    }
  }
  
  @override
  void dispose() {
    _nameController.dispose();
    _weightController.dispose();
    _qtyController.dispose();
    _manufacturerController.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Gear'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          TextButton(
            onPressed: () async {
              final uid = FirebaseAuth.instance.currentUser?.uid;
              if (uid == null) return;

              final gearCollection = FirebaseFirestore.instance.collection('Gear');
              final docRef = gearCollection.doc();
              final gid = docRef.id;

              String imageUrl = '';
              if (_imageFile != null) {
                final ref = FirebaseStorage.instance.ref().child('gear_images/$gid.jpg');
                await ref.putFile(_imageFile!);
                imageUrl = await ref.getDownloadURL();
              }

              final gear = Gear(
                uid: uid,
                gid: gid,
                gearName: _nameController.text.trim(),
                manufacturer: _manufacturerController.text.trim(),
                type: _selectedType,
                weight: int.tryParse(_weightController.text.trim()) ?? 0,
                quantity: int.tryParse(_qtyController.text.trim()) ?? 0,
                imgUrl: imageUrl,
              );

              await docRef.set(gear.toMap());

              if (context.mounted) Navigator.of(context).pop();
            },
            child: const Text(
              'Save',
              style: TextStyle(color: Colors.black),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 이미지 업로드 영역
              Center(
                child: GestureDetector(
                  onTap: _pickImage,
                  child: Container(
                    width: 180,
                    height: 180,
                    decoration: BoxDecoration(
                      color: Colors.grey[200],
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: _imageFile == null
                        ? const Center(
                            child: Icon(
                              Icons.add_a_photo,
                              size: 60,
                              color: Colors.grey,
                            ),
                          )
                        : ClipRRect(
                            borderRadius: BorderRadius.circular(20),
                            child: Image.file(
                              _imageFile!,
                              fit: BoxFit.cover,
                            ),
                          ),
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // 제조사 입력 필드
              const Text('Manufacturer', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              TextField(
                controller: _manufacturerController,
                decoration: InputDecoration(
                  hintText: 'Ex) MSR',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              
              // 이름 입력 필드
              const Text('Name', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              TextField(
                controller: _nameController,
                decoration: InputDecoration(
                  hintText: 'Ex) Hubba Hubba',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.clear),
                    onPressed: () => _nameController.clear(),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              
              // 유형 선택 드롭다운
              const Text('Type', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: DropdownButton<String>(
                  value: _selectedType,
                  isExpanded: true,
                  underline: Container(),
                  onChanged: (String? newValue) {
                    setState(() {
                      _selectedType = newValue!;
                    });
                  },
                  items: <String>[
                    'Tent',
                    'Sleeping Bag',
                    'Matt',
                    'BackPack',
                    'Cook Set',
                    'Clothes',
                    'Electonics',
                    'etc'
                  ].map<DropdownMenuItem<String>>((String value) {
                    return DropdownMenuItem<String>(
                      value: value,
                      child: Text(value),
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: 16),

              // 무게 입력 필드
              const Text('Weight', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              TextField(
                controller: _weightController,
                decoration: InputDecoration(
                  hintText: '1160',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  suffixText: 'g',
                ),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 16),
              
              // 수량 입력 필드
              const Text('QTY', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              TextField(
                controller: _qtyController,
                decoration: InputDecoration(
                  hintText: '1',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                keyboardType: TextInputType.number,
              ),
              
              const SizedBox(height: 24),
              
            ],
          ),
        ),
      ),
    );
  }
}
