import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart'; 
import 'package:image_picker/image_picker.dart';
import 'firestore_service.dart';

class AddPlantScreen extends StatefulWidget {
  @override
  _AddPlantScreenState createState() => _AddPlantScreenState();
}

class _AddPlantScreenState extends State<AddPlantScreen> {
  final nameController = TextEditingController();
  final freqController = TextEditingController();
  final service = FirestoreService();
  String? _imagePath;

  void _pickImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);
    if (image != null) setState(() => _imagePath = image.path);
  }

  void savePlant() async {
    if (nameController.text.isEmpty || freqController.text.isEmpty) return;
    await service.addPlant(nameController.text, int.parse(freqController.text), _imagePath ?? "");
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Add Plant 🌱")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            if (_imagePath != null)
              Container(
                height: 150, width: 150,
                margin: const EdgeInsets.only(bottom: 10),
                decoration: BoxDecoration(borderRadius: BorderRadius.circular(10), border: Border.all(color: Colors.grey.shade300)),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: kIsWeb ? Image.network(_imagePath!, fit: BoxFit.cover) : Image.file(File(_imagePath!), fit: BoxFit.cover),
                ),
              )
            else
              const Icon(Icons.image, size: 100, color: Colors.grey),

            ElevatedButton.icon(onPressed: _pickImage, icon: const Icon(Icons.photo_library), label: const Text("Pick Image")),
            const SizedBox(height: 10),
            TextField(controller: nameController, decoration: const InputDecoration(labelText: "Plant Name", border: OutlineInputBorder())),
            const SizedBox(height: 10),
            TextField(controller: freqController, decoration: const InputDecoration(labelText: "Water every (days)", border: OutlineInputBorder()), keyboardType: TextInputType.number),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: savePlant,
                style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 15), backgroundColor: Colors.green, foregroundColor: Colors.white),
                child: const Text("Save Plant"),
              ),
            ),
          ],
        ),
      ),
    );
  }
}