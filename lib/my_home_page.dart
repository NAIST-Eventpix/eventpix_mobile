import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';

import 'dart:convert';

import 'result_page.dart';
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
    logger.fine('API Request : Start');
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              const CircularProgressIndicator(),
              const SizedBox(height: 16.0),
              const Text('変換中です...'),
              ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  Navigator.of(context).pushReplacementNamed('/');
                },
                child: const Text('キャンセル'),
              ),
            ],
          ),
        ),
      ),
    );

    Json json;

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

      json = jsonDecode(utf8.decode(response.bodyBytes));
    } catch (e) {
      json = {'error': e.toString(),};
    } finally {
      Navigator.of(context).pop();
    }
    logger.fine('API Result  : ${json.toString()}');
    return json;
  }

  Future<void> _pickImage(ImageSource source) async {
    final pickedFile = await picker.pickImage(source: source);

    if (pickedFile != null) {
      final json = await apiRequest(pickedFile);

      if (!mounted) return;

      Navigator.push(
        context,
        NoAnimationPageRoute(
          builder: (context) => ResultPage(json: json),
        )
      );
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