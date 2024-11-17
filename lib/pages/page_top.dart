import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:quick_actions/quick_actions.dart';
import 'package:flutter_sharing_intent/model/sharing_file.dart';
import 'package:flutter_sharing_intent/flutter_sharing_intent.dart';

import 'dart:convert';
import 'dart:async';

import 'page_result.dart';
import '../utils.dart';

class PageTop extends StatefulWidget {
  const PageTop({super.key, required this.title});
  final String title;

  @override
  StatePageTop createState() => StatePageTop();
}

class StatePageTop extends State<PageTop> {
  String shortcut = '';
  List<SharedFile>? list;
  final picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    initSharingListener();
    setupQuickActions();
  }

  void setupQuickActions() {
    const QuickActions()
      ..initialize((String shortcutType) {
        setState(() => shortcut = shortcutType);
      })
      ..setShortcutItems(<ShortcutItem>[
        const ShortcutItem(
          type: 'camera',
          localizedTitle: '写真を撮る',
          icon: 'ic_launcher',
        ),
      ]);
  }

  void initSharingListener() {
    logger.fine("Shared: initSharingListener");

    FlutterSharingIntent.instance.getMediaStream().listen(
      (List<SharedFile> value) {
        setState(() {
          list = value;
        });
        logger.fine(
            "Shared: getMediaStream ${value.map((f) => f.value).join(",")}");
        _pickFromFlutterSharingIntent();
      },
      onError: (err) {
        logger.severe("Shared: getIntentDataStream error: $err");
      },
    );

    FlutterSharingIntent.instance
        .getInitialSharing()
        .then((List<SharedFile> value) {
      logger.fine(
          "Shared: getInitialMedia => ${value.map((f) => f.value).join(",")}");
      setState(() {
        list = value;
      });
      _pickFromFlutterSharingIntent();
    });
  }

  Future<Json> apiRequestFromImage(XFile pickedFile) async {
    logger.fine('API Request : Start');
    showLoadingDialog();

    Json json;
    // try {
    //   final request = http.MultipartRequest(
    //     'POST',
    //     Uri.https(apiDomain, '/pick_schedule_from_image'),
    //   );
    //   request.files
    //       .add(await http.MultipartFile.fromPath('file', pickedFile.path));
    //   final response = await http.Response.fromStream(await request.send());
    //   json = jsonDecode(utf8.decode(response.bodyBytes));
    // } catch (e) {
    //   json = {'error': e.toString()};
    // }

    // logger.fine('API Result  : ${json.toString()}');
    // if (!mounted) return {};
    // if (json.containsKey('error')) {
    //   errorDialog(context, '変換中にエラーが発生しました．\n${json['error']}');
    // }

    json = {
      'events': [
        {
          'summary': 'ABC社 就職説明会',
          'description': '',
          'location': 'ABC社 東京本社',
          'dtstart': '2024-11-17T15:00:00',
          'dtend': '2024-11-17T16:00:00',
        },
        {
          'summary': 'XYZ社 就活セミナー',
          'description': '',
          'location': 'オフィス',
          'dtstart': '2024-11-18T18:00:00',
          'dtend': '2024-11-18T20:00:00',
        },
      ],
    };

    await Future.delayed(const Duration(seconds: 5));

    if(!mounted) return {};

    Navigator.of(context).pop();
    return json;
  }

  Future<void> _pickImage(ImageSource source) async {
    final pickedFile = await picker.pickImage(source: source);
    if (pickedFile != null) {
      final json = await apiRequestFromImage(pickedFile);
      if (!mounted) return;
      Navigator.push(
        context,
        NoAnimationPageRoute(builder: (context) => PageResult(json: json)),
      );
    }
  }

  Future<Json> apiRequestFromText(String text) async {
    logger.fine('API Request : Start');
    showLoadingDialog();

    Json json;
    try {
      final response = await http.post(
        Uri.https(apiDomain, '/pick_schedule_from_text'),
        body: jsonEncode({'text': text}),
        headers: {'Content-Type': 'application/json'},
      );
      json = jsonDecode(utf8.decode(response.bodyBytes));
    } catch (e) {
      json = {'error': e.toString()};
    }

    logger.fine('API Result  : ${json.toString()}');
    if (!mounted) return {};
    if (json.containsKey('error')) {
      errorDialog(context, '変換中にエラーが発生しました．\n${json['error']}');
    }
    Navigator.of(context).pop();
    return json;
  }

  Future<void> _pickFromFlutterSharingIntent() async {
    if (list != null && list!.isNotEmpty) {
      final sharedFile = list!.first;
      final String path = sharedFile.value!;
      final XFile xFile = XFile(path);
      final Json json;

      if (sharedFile.type == SharedMediaType.TEXT) {
        json = await apiRequestFromText(sharedFile.value!);
      } else {
        json = await apiRequestFromImage(xFile);
      }

      if (!mounted) return;
      Navigator.push(
        context,
        NoAnimationPageRoute(builder: (context) => PageResult(json: json)),
      );
    }
  }

  void showLoadingDialog() {
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
              const SizedBox(height: 16),
              const Text('変換中です...', style: TextStyle(fontSize: 24)),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                child: const Text('キャンセル'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (shortcut == 'camera') {
      _pickImage(ImageSource.camera);
    }
    return Scaffold(
      appBar: const MyAppBar(),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Text(
              'スケジュールを読み込む画像を選択してください',
              style: TextStyle(fontSize: isLandscape(context) ? 24 : 16),
            ),
            SizedBox(height: isLandscape(context) ? 48 : 32),
            SizedBox(
              width: isLandscape(context) ? 450 : 300,
              child: ElevatedButton(
                onPressed: () => _pickImage(ImageSource.gallery),
                style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16)),
                child: Text(
                  'ライブラリから選択する',
                  style: TextStyle(fontSize: isLandscape(context) ? 24 : 16),
                ),
              ),
            ),
            SizedBox(height: isLandscape(context) ? 24 : 16),
            SizedBox(
              width: isLandscape(context) ? 450 : 300,
              child: ElevatedButton(
                onPressed: () => _pickImage(ImageSource.camera),
                style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16)),
                child: Text(
                  'カメラで写真を撮る',
                  style: TextStyle(fontSize: isLandscape(context) ? 24 : 16),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
