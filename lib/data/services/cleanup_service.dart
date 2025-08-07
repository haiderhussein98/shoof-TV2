import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:path_provider/path_provider.dart';

class CleanupService {
  static Future<void> performCleanup() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();

      final tempDir = await getTemporaryDirectory();
      if (tempDir.existsSync()) {
        tempDir.deleteSync(recursive: true);
      }

    } catch (e) {
      debugPrint("Cleanup error: $e");
    }
  }
}
