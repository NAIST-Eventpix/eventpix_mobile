import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:logging/logging.dart';
import 'package:intl/intl.dart';

final Logger logger = Logger('Eventpix');

void setupLogging() {
  Logger.root.level = Level.ALL;
  Logger.root.onRecord.listen((record) {
    if (kDebugMode) {
      print('${record.level.name}: ${record.time}: ${record.message}');
    }
  });
}

typedef Json = Map<String, dynamic>;

const String apiDomain = 'eventpix.jp';

class MyAppBar extends StatelessWidget implements PreferredSizeWidget {
  @override
  final Size preferredSize;

  const MyAppBar({super.key}) : preferredSize = const Size.fromHeight(56.0);

  @override
  Widget build(BuildContext context) {
    Widget appBarTitle;
    Widget image = InkWell(
      child: Image.asset(
        'assets/icon/logo_name.png',
        height: 40,
      ),
      onTap:() {
        Navigator.of(context).pushReplacementNamed('/');
      },
    );
    if (Platform.isIOS) {
      appBarTitle = image;
    } else {
      appBarTitle = Center(child: image,);
    }
    return AppBar(
      backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      title: appBarTitle,
    );
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

class EventCard extends StatefulWidget {
  final String title;
  final String description;
  final DateTime start;
  final DateTime end;
  final String location;

  const EventCard({
    super.key,
    required this.title,
    required this.description,
    required this.start,
    required this.end,
    required this.location,
  });

  @override
  _EventCardState createState() => _EventCardState();
}

class _EventCardState extends State<EventCard> {
  late String title;
  late String description;
  late DateTime start;
  late DateTime end;
  late String location;

  @override
  void initState() {
    super.initState();
    title = widget.title;
    description = widget.description;
    start = widget.start;
    end = widget.end;
    location = widget.location;
  }

  bool isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  void showEditDialog() {
    final titleController = TextEditingController(text: title);
    final descriptionController = TextEditingController(text: description);
    final locationController = TextEditingController(text: location);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('イベントを編集'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: titleController,
              decoration: const InputDecoration(labelText: 'タイトル'),
            ),
            TextField(
              maxLines: null,
              controller: descriptionController,
              decoration: const InputDecoration(labelText: '説明'),
            ),
            TextField(
              controller: locationController,
              decoration: const InputDecoration(labelText: '場所'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('キャンセル'),
          ),
          TextButton(
            onPressed: () {
              setState(() {
                title = titleController.text;
                description = descriptionController.text;
                location = locationController.text;
              });
              Navigator.of(context).pop();
            },
            child: const Text('保存'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    String fStart = DateFormat('yyyy/MM/dd HH:mm').format(start);
    String fEnd = DateFormat('yyyy/MM/dd HH:mm').format(end);
    String fDate;
    if (isSameDay(start, end)) {
      fDate = '$fStart ~ ${DateFormat('HH:mm').format(end)}';
    } else {
      fDate = '$fStart ~ $fEnd';
    }
    return GestureDetector(
      onTap: showEditDialog,
      child: Card(
        child: Column(
          children: <Widget>[
            ListTile(
              title: Text(
                title,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    description,
                    style: const TextStyle(fontSize: 12),
                  ),
                  Text(
                    fDate,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    '@ $location',
                    style: const TextStyle(fontSize: 12),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

void errorDialog(BuildContext context, String errorMessage,
    {VoidCallback? onRetry}) {
  showDialog(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        title: const Text('ERROR!'),
        content: Text(errorMessage),
        actions: <Widget>[
          // 再試行ボタン
          if (onRetry != null)
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // ダイアログを閉じる
                onRetry(); // 再試行のコールバックを実行
              },
              child: const Text('再試行'),
            ),
          // OKボタン
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              Navigator.of(context).pushReplacementNamed('/');
            },
            child: const Text('OK'),
          ),
        ],
      );
    },
  );
}
