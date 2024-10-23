import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'dart:convert';

typedef Json = Map<String, dynamic>;

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Eventpix',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.orange),
        useMaterial3: true,
      ),
      home: const MyHomePage(title: 'Eventpix'),
    );
  }
}

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
        Uri.parse('http://localhost:8000/pick_schedule_from_image'),
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

class MyAppBar extends StatelessWidget implements PreferredSizeWidget {
  @override
  final Size preferredSize;

  const MyAppBar({super.key}) : preferredSize = const Size.fromHeight(56.0);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      title: Image.asset(
        'assets/icon/logo_name.png',
        height: 40,
      ),
    );
  }
}

class ImageDisplayPage extends StatelessWidget {
  final Json json;

  const ImageDisplayPage({super.key, required this.json});

  @override
  Widget build(BuildContext context) {
    String jsonString = jsonEncode(json);
    return Scaffold(
        appBar: const MyAppBar(),
        body: Center(
          child: Text(jsonString),
        ));
  }
}

class NoAnimationPageRoute<T> extends MaterialPageRoute<T> {
  NoAnimationPageRoute({required super.builder});

  @override
  Widget buildTransitions(BuildContext context, Animation<double> animation,
      Animation<double> secondaryAnimation, Widget child) {
    // 遷移アニメーションを無効化
    return child;
  }
}
