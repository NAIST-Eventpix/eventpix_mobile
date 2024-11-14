import 'package:shared_preferences/shared_preferences.dart';

class ShareService {
  static const String _groupName = 'group.com.example.eventpixMobile.shareExtension_new';
  static const String _sharedTextKey = 'sharedText';
  static const String _sharedImageUrlKey = 'sharedImageURL';

  Future<Map<String, dynamic>> getSharedContent() async {
    final prefs = await SharedPreferences.getInstance();
    
    final text = prefs.getString(_sharedTextKey);
    final imageUrl = prefs.getString(_sharedImageUrlKey);
    
    // 取得後はデータをクリア
    await prefs.remove(_sharedTextKey);
    await prefs.remove(_sharedImageUrlKey);
    
    return {
      'text': text,
      'imageUrl': imageUrl,
    };
  }
}