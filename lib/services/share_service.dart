import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_sharing_intent/flutter_sharing_intent.dart';

class ShareService {
  static const String _groupName = 'group.com.example.eventpixMobile';
  static const String _sharedTextKey = 'sharedText';
  static const String _sharedImageUrlKey = 'sharedImageURL';

  Future<Map<String, dynamic>> getSharedContent() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      final text = prefs.getString(_sharedTextKey);
      final imageUrl = prefs.getString(_sharedImageUrlKey);
      
      // 取得後はデータをクリア
      if (text != null) await prefs.remove(_sharedTextKey);
      if (imageUrl != null) await prefs.remove(_sharedImageUrlKey);
      
      return {
        'text': text,
        'imageUrl': imageUrl,
      };
    } catch (e) {
      print('Error reading shared content: $e');
      return {
        'text': null,
        'imageUrl': null,
      };
    }
  }
}