import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'models/gear_model.dart';

class EditGearPage extends StatefulWidget {
  final Gear gear;

  const EditGearPage({Key? key, required this.gear}) : super(key: key);

  @override
  State<EditGearPage> createState() => _EditGearPageState();
}

class _EditGearPageState extends State<EditGearPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _manufacturerController = TextEditingController();
  final _weightController = TextEditingController();
  final _qtyController = TextEditingController();
  String _selectedType = 'Tent';
  File? _imageFile;

  @override
  void initState() {
    super.initState();
    final gear = widget.gear;
    _nameController.text = gear.gearName;
    _manufacturerController.text = gear.manufacturer;
    _weightController.text = gear.weight.toString();
    _qtyController.text = gear.quantity.toString();
    _selectedType = gear.type;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _manufacturerController.dispose();
    _weightController.dispose();
    _qtyController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery);
    if (picked != null) {
      setState(() {
        _imageFile = File(picked.path);
      });
    }
  }

  Future<void> _saveGear() async {
    if (!_formKey.currentState!.validate()) return;


    String imageUrl = widget.gear.imgUrl;
    if (_imageFile != null) {
      final ref = FirebaseStorage.instance.ref().child('gear_images/${widget.gear.gid}.jpg');
      await ref.putFile(_imageFile!);
      imageUrl = await ref.getDownloadURL();
    }

    final updated = Gear(
      uid: widget.gear.uid,
      gid: widget.gear.gid,
      gearName: _nameController.text.trim(),
      manufacturer: _manufacturerController.text.trim(),
      type: _selectedType,
      weight: int.tryParse(_weightController.text.trim()) ?? 0,
      quantity: int.tryParse(_qtyController.text.trim()) ?? 1,
      imgUrl: imageUrl,
    );

    await FirebaseFirestore.instance.collection('Gear').doc(updated.gid).set(updated.toMap());

    if (context.mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final gear = widget.gear;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Gear'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          TextButton(
            onPressed: _saveGear,
            child: const Text('Save', style: TextStyle(color: Colors.black)),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                GestureDetector(
                  onTap: _pickImage,
                  child: Container(
                    height: 240,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Colors.grey[200],
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: _imageFile != null
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(16),
                            child: Image.file(_imageFile!, fit: BoxFit.cover),
                          )
                        : gear.imgUrl.isNotEmpty
                            ? ClipRRect(
                                borderRadius: BorderRadius.circular(16),
                                child: Image.network(gear.imgUrl, fit: BoxFit.cover),
                              )
                            : const Center(child: Icon(Icons.add_a_photo, size: 60, color: Colors.grey)),
                  ),
                ),
                const SizedBox(height: 24),

                const Text('Manufacturer', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _manufacturerController,
                  decoration: const InputDecoration(border: OutlineInputBorder()),
                  validator: (v) => v == null || v.trim().isEmpty ? 'Please enter manufacturer' : null,
                ),
                const SizedBox(height: 16),

                const Text('Name', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(border: OutlineInputBorder()),
                  validator: (v) => v == null || v.trim().isEmpty ? 'Please enter name' : null,
                ),
                const SizedBox(height: 16),

                const Text('Type', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  value: _selectedType,
                  onChanged: (val) => setState(() => _selectedType = val ?? 'Tent'),
                  items: [
                    'Tent', 'Sleeping Bag', 'Matt', 'BackPack', 'Cook Set', 'Clothes', 'Electonics', 'etc'
                  ].map((t) => DropdownMenuItem(value: t, child: Text(t))).toList(),
                ),
                const SizedBox(height: 16),

                const Text('Weight', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _weightController,
                  decoration: const InputDecoration(border: OutlineInputBorder(), suffixText: 'g'),
                  keyboardType: TextInputType.number,
                  validator: (v) => v == null || v.trim().isEmpty ? 'Please enter weight' : null,
                ),
                const SizedBox(height: 16),

                const Text('QTY', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _qtyController,
                  decoration: const InputDecoration(border: OutlineInputBorder()),
                  keyboardType: TextInputType.number,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
