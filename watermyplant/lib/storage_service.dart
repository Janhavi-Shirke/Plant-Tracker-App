import 'dart:io';
import 'dart:convert';
import 'package:path_provider/path_provider.dart';

class StorageService {
  // Get the local path to save the JSON file
  Future<File> get _localFile async {
    final directory = await getApplicationDocumentsDirectory();
    return File('${directory.path}/plants_data.json');
  }

  // Save the list of plants to a JSON file
  Future<void> saveToLocalJSON(List plants) async {
    final file = await _localFile;
    await file.writeAsString(jsonEncode(plants));
    print("Data saved locally to JSON");
  }

  // Read the plants from the local JSON file (useful for offline)
  Future<List> readFromLocalJSON() async {
    try {
      final file = await _localFile;
      String contents = await file.readAsString();
      return jsonDecode(contents);
    } catch (e) {
      return []; // Return empty list if file doesn't exist yet
    }
  }
}