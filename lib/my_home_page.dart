import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'dart:convert';

import 'image_display_page.dart';
import 'utils.dart';

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});
  final String title;

  @override
  MyHomePageState createState() => MyHomePageState();
}

class MyHomePageState extends State<MyHomePage> {
  final picker = ImagePicker();

  Future<Json> apiRequest(XFile pickedFile) async {
    try {
      http.MultipartRequest request = http.MultipartRequest(
        'POST',
        Uri.https(API_DOMAIN, '/pick_schedule_from_image'),
      );

      request.files.add(
        await http.MultipartFile.fromPath(
          'file',
          pickedFile.path,
        ),
      );

      var streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      final json = jsonDecode(response.body);
      return json;
    } catch (e) {
      return {
        'error': e.toString(),
      };
    }
  }

  Future<void> _pickImage(ImageSource source) async {
    final pickedFile = await picker.pickImage(source: source);

    if (pickedFile != null) {
      final json = await apiRequest(pickedFile);

      if (!mounted) return;

      Navigator.push(
          context,
          NoAnimationPageRoute(
            builder: (context) => ImageDisplayPage(json: json),
          ));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const MyAppBar(),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            const Text(
              'スケジュールを読み込む画像を選択してください',
            ),
            ElevatedButton(
              onPressed: () => _pickImage(ImageSource.gallery),
              child: const Text('ライブラリから選択する'),
            ),
            ElevatedButton(
                onPressed: () => _pickImage(ImageSource.camera),
                child: const Text('カメラで写真を撮る'))
          ],
        ),
      ),
    );
  }
}