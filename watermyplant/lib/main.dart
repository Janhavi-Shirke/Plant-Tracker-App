import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart'; 
import 'package:firebase_core/firebase_core.dart';
import 'package:intl/intl.dart'; 
import 'firestore_service.dart';
import 'add_plant_screen.dart';
import 'storage_service.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await dotenv.load(fileName: ".env"); // 👈 IMPORTANT
  

  await Firebase.initializeApp(
    options: FirebaseOptions(
      apiKey: dotenv.env['API_KEY']!,
      authDomain: dotenv.env['AUTH_DOMAIN']!,
      projectId: dotenv.env['PROJECT_ID']!,
      storageBucket: dotenv.env['STORAGE_BUCKET']!,
      messagingSenderId: dotenv.env['MESSAGING_SENDER_ID']!,
      appId: dotenv.env['APP_ID']!,
    ),
  );
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Plant Tracker',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.green),
        useMaterial3: true,
    ),
      home: HomeScreen(),
    );
  }
}

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final service = FirestoreService();
  final storageService = StorageService();
  List plants = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    loadPlants();
  }

  String getDaysRemaining(String lastWateredStr, int frequency) {
    try {
      DateTime lastDate = DateTime.parse(lastWateredStr);
      DateTime nextDate = lastDate.add(Duration(days: frequency));
      DateTime today = DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day);
      DateTime nextMidnight = DateTime(nextDate.year, nextDate.month, nextDate.day);
      int difference = nextMidnight.difference(today).inDays;

      if (difference == 0) return "Due Today ⚠️";
      if (difference < 0) return "${difference.abs()} Days Overdue 🚨";
      return "In $difference days";
    } catch (e) { return "N/A"; }
  }

  String formatLastWatered(String lastWateredStr) {
    try {
      DateTime lastDate = DateTime.parse(lastWateredStr);
      return "Last Watered: ${DateFormat('MMM d').format(lastDate)}";
    } catch (e) { return "History Unknown"; }
  }

  bool isWateredToday(String lastWateredStr) {
    try {
      DateTime lastDate = DateTime.parse(lastWateredStr);
      DateTime now = DateTime.now();
      return lastDate.year == now.year && lastDate.month == now.month && lastDate.day == now.day;
    } catch (e) { return false; }
  }

  void loadPlants() async {
    setState(() => isLoading = true);
    try {
      plants = await service.getPlants();
      plants.sort((a, b) {
        DateTime nextA = DateTime.parse(a['lastWatered']).add(Duration(days: a['frequency']));
        DateTime nextB = DateTime.parse(b['lastWatered']).add(Duration(days: b['frequency']));
        return nextA.compareTo(nextB);
      });
      if (!kIsWeb) await storageService.saveToLocalJSON(plants);
    } catch (e) {
      debugPrint("Error: $e");
    } finally {
      setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("🌿 My Plant Collection"),
        centerTitle: true,
        actions: [IconButton(icon: const Icon(Icons.refresh), onPressed: loadPlants)],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : plants.isEmpty
              ? const Center(child: Text("No plants found.\nTap + to start!", textAlign: TextAlign.center))
              : ListView.builder(
                  padding: const EdgeInsets.all(8),
                  itemCount: plants.length,
                  itemBuilder: (context, index) {
                    final plant = plants[index];
                    String daysRemaining = getDaysRemaining(plant['lastWatered'] ?? "", plant['frequency'] ?? 1);
                    String history = formatLastWatered(plant['lastWatered'] ?? "");
                    bool wateredToday = isWateredToday(plant['lastWatered'] ?? "");

                    return Dismissible(
                      key: Key(plant['id']),
                      direction: DismissDirection.endToStart,
                      background: Container(
                        color: Colors.red.shade400,
                        alignment: Alignment.centerRight,
                        padding: const EdgeInsets.only(right: 20),
                        child: const Icon(Icons.delete, color: Colors.white),
                      ),
                      onDismissed: (direction) async {
                        await service.deletePlant(plant['id']);
                        setState(() => plants.removeAt(index));
                      },
                      child: Card(
                        elevation: 2,
                        margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          leading: (!kIsWeb && plant['imagePath'] != "")
                              ? CircleAvatar(radius: 25, backgroundImage: FileImage(File(plant['imagePath'])))
                              : CircleAvatar(
                                  radius: 25,
                                  backgroundColor: wateredToday ? Colors.blue.shade50 : Colors.green.shade50,
                                  child: Icon(Icons.local_florist, color: wateredToday ? Colors.blue : Colors.green),
                                ),
                          title: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(plant['name'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 17)),
                              Text(history, style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                            ],
                          ),
                          subtitle: Padding(
                            padding: const EdgeInsets.only(top: 8.0),
                            child: Wrap(
                              spacing: 8,
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: daysRemaining.contains("Overdue") ? Colors.red.shade50 : Colors.orange.shade50,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(daysRemaining, style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: daysRemaining.contains("Overdue") ? Colors.red : Colors.orange.shade900)),
                                ),
                                if (wateredToday)
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(color: Colors.blue.shade50, borderRadius: BorderRadius.circular(8)),
                                    child: const Text("Watered Today", style: TextStyle(fontSize: 11, color: Colors.blue, fontWeight: FontWeight.bold)),
                                  ),
                              ],
                            ),
                          ),
                          trailing: IconButton(
                            icon: Icon(wateredToday ? Icons.check_circle : Icons.water_drop_outlined, size: 28, color: wateredToday ? Colors.blue : Colors.grey),
                            onPressed: () async {
                              await service.markAsWatered(plant['id']);
                              loadPlants();
                            },
                          ),
                        ),
                      ),
                    );
                  },
                ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          await Navigator.push(context, MaterialPageRoute(builder: (_) => AddPlantScreen()));
          loadPlants();
        },
        label: const Text("Add Plant"),
        icon: const Icon(Icons.add),
      ),
    );
  }
}