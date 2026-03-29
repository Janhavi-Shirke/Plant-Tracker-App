import 'package:cloud_firestore/cloud_firestore.dart';

class FirestoreService {
  final db = FirebaseFirestore.instance;

  // Add plant
  Future<void> addPlant(String name, int frequency, String imagePath) async {
    await db.collection('plants').add({
      'name': name,
      'frequency': frequency,
      'imagePath': imagePath, // Path to local file or URL
      'lastWatered': DateTime.now().toIso8601String(),
    });
  }

Future<void> markAsWatered(String docId) async {
    await db.collection('plants').doc(docId).update({
      'lastWatered': DateTime.now().toIso8601String(),
    });
  }

  // Delete plant (Swipe to remove)
  Future<void> deletePlant(String docId) async {
    await db.collection('plants').doc(docId).delete();
  }

  // Get plants with IDs
  Future<List<Map<String, dynamic>>> getPlants() async {
    final snapshot = await db.collection('plants').get();
    return snapshot.docs.map((doc) {
      var data = doc.data();
      data['id'] = doc.id; // Store ID for updates/deletes
      return data;
    }).toList();
  }
}