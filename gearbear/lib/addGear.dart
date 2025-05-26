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
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _weightController = TextEditingController();
  final _manufacturerController = TextEditingController();
  final _qtyController = TextEditingController();
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
    _manufacturerController.dispose();
    _qtyController.dispose();
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
              if (!_formKey.currentState!.validate()) return;
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Saving.... Please Wait')),
              );

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

              final parsedQty = int.tryParse(_qtyController.text.trim());
              final gear = Gear(
                uid: uid,
                gid: gid,
                gearName: _nameController.text.trim(),
                manufacturer: _manufacturerController.text.trim(),
                type: _selectedType,
                weight: int.tryParse(_weightController.text.trim()) ?? 0,
                quantity: (parsedQty != null ? parsedQty.clamp(1, 1000) : 1),
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
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 이미지 업로드 영역
                Center(
                  child: GestureDetector(
                    onTap: _pickImage,
                    child: Container(
                      width: double.infinity,
                      height: 240,
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
                TextFormField(
                  controller: _manufacturerController,
                  decoration: InputDecoration(
                    hintText: 'Ex) MSR',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter a manufacturer';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                
                // 이름 입력 필드
                const Text('Name', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                TextFormField(
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
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter a name';
                    }
                    return null;
                  },
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
                TextFormField(
                  controller: _weightController,
                  decoration: InputDecoration(
                    hintText: 'Ex) 1160',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    suffixText: 'g',
                  ),
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter a weight';
                    }
                    return null;
                  },
                ),
                
                const SizedBox(height: 24),

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
                const SizedBox(height: 16),
                
              ],
            ),
          ),
        ),
      ),
    );
  }
}
