import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:device_calendar/device_calendar.dart';
import 'package:timezone/timezone.dart' as tz;

import '../utils.dart';

final DeviceCalendarPlugin _deviceCalendarPlugin = DeviceCalendarPlugin();

class PageResult extends StatefulWidget {
  final Json json;

  const PageResult({super.key, required this.json});

  @override
  PageResultState createState() => PageResultState();
}

class PageResultState extends State<PageResult> {
  List<Map<String, TextEditingController>> controllers = [];

  @override
  void initState() {
    super.initState();
    // 各イベントのコントローラーを初期化してリスナーを設定
    for (var event in widget.json['events']) {
      final controllerMap = {
        'summary': TextEditingController(text: event['summary']),
        'description': TextEditingController(text: event['description']),
        'location': TextEditingController(text: event['location']),
        'dtstart': TextEditingController(text: event['dtstart']),
        'dtend': TextEditingController(text: event['dtend']),
      };

      // 各コントローラーにリスナーを追加して、jsonデータを更新
      controllerMap.forEach((key, controller) {
        controller.addListener(() {
          event[key] = controller.text;
        });
      });

      controllers.add(controllerMap);
    }    
  }

  @override
  void dispose() {
    // 各コントローラーを破棄
    for (var controllerMap in controllers) {
      for (var controller in controllerMap.values) {
        controller.dispose();
      }
    }
    super.dispose();
  }

  Future<Calendar?> selectCalendar(
      BuildContext context, Map<String?, List<Calendar>> groupedCalendars) async {
    return await showDialog<Calendar>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('カレンダー選択'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              for (var entry in groupedCalendars.entries) ...[
                Text(
                  entry.key ?? '無名のアカウント',
                  style: const TextStyle(fontSize: 20),
                ),
                const SizedBox(height: 8),
                for (var calendar in entry.value)
                  InkWell(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 16),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.start,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Container(
                            width: 16,
                            height: 16,
                            decoration: BoxDecoration(
                              color: Color(calendar.color ?? 0xff0000),
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            calendar.name ?? '無名のカレンダー',
                            style: const TextStyle(fontSize: 16),
                          ),
                        ],
                      ),
                    ),
                    onTap: () {
                      Navigator.of(context).pop(calendar);
                    },
                  ),
              ]
            ],
          ),
        );
      },
    );
  }

  void registCalendar(BuildContext context) async {
    var permissionsGranted = await _deviceCalendarPlugin.hasPermissions();
    if (permissionsGranted.isSuccess && !permissionsGranted.data!) {
      permissionsGranted = await _deviceCalendarPlugin.requestPermissions();
      if (!permissionsGranted.isSuccess || !permissionsGranted.data!) {
        logger.severe("カレンダーへのアクセスが拒否されました．");
        return;
      }
    }

    var calendarsResult = await _deviceCalendarPlugin.retrieveCalendars();
    if (!calendarsResult.isSuccess || calendarsResult.data == null) {
      logger.severe("カレンダーが見つかりませんでした．");
      return;
    }

    if (!context.mounted) return;

    final groupedCalendars = calendarsResult.data!
      .where((calendar) => calendar.isReadOnly == false)
      .groupListsBy((calendar) => calendar.accountName);

    final Calendar? calendar = await selectCalendar(context, groupedCalendars);

    if (calendar == null) {
      logger.severe("カレンダーが選択されませんでした．");
      return;
    }

    for (var e in widget.json['events']) {
      final event = Event(calendar.id);
      event.title = e['summary'];
      event.start = tz.TZDateTime.from(DateTime.parse(e['dtstart']), tz.local);
      event.end = tz.TZDateTime.from(DateTime.parse(e['dtend']), tz.local);
      event.description = e['description'];
      event.location = e['location'];

      // カレンダーにイベントを追加
      final result = await _deviceCalendarPlugin.createOrUpdateEvent(event);
      if (result!.isSuccess && result.data != null) {
        logger.fine("イベントが正常に追加されました: ${event.title}");
      } else {
        logger.severe("イベントの追加に失敗しました: ${event.title}");
      }
    }

    if (!context.mounted) return;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('成功'),
          content: const Text('カレンダーの登録に成功しました！'),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // ダイアログを閉じる
              },
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const MyAppBar(),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            children: [
              const Text(
                '変換結果',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: controllers.length,
                itemBuilder: (context, index) {
                  final eventControllers = controllers[index];
                  return EventCard(
                    summaryController: eventControllers['summary']!,
                    descriptionController: eventControllers['description']!,
                    locationController: eventControllers['location']!,
                    startController: eventControllers['dtstart']!,
                    endController: eventControllers['dtend']!,
                  );
                },
              )
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          registCalendar(context);
        },
        child: const Icon(Icons.calendar_month),
      ),
    );
  }
}

class EventCard extends StatefulWidget {
  final TextEditingController summaryController;
  final TextEditingController descriptionController;
  final TextEditingController locationController;
  final TextEditingController startController;
  final TextEditingController endController;

  const EventCard({
    super.key,
    required this.summaryController,
    required this.descriptionController,
    required this.locationController,
    required this.startController,
    required this.endController,
  });

  @override
  EventCardState createState() => EventCardState();
}

class EventCardState extends State<EventCard> {
  // 表示用のテキストを保持するための変数
  late String summary;
  late String description;
  late String location;
  late String start;
  late String end;

  @override
  void initState() {
    super.initState();
    // 初期値としてコントローラーの内容を設定
    summary = widget.summaryController.text;
    description = widget.descriptionController.text;
    location = widget.locationController.text;
    start = widget.startController.text;
    end = widget.endController.text;
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        _showEditDialog(context);
      },
      child: Card(
        margin: const EdgeInsets.symmetric(vertical: 8.0),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("Summary: $summary"),
              Text("Description: $description"),
              Text("Location: $location"),
              Text("Start: $start"),
              Text("End: $end"),
            ],
          ),
        ),
      ),
    );
  }

  void _showEditDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("Edit Event"),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: widget.summaryController,
                  decoration: const InputDecoration(labelText: 'タイトル'),
                ),
                TextField(
                  controller: widget.descriptionController,
                  decoration: const InputDecoration(labelText: '説明'),
                  maxLines: null,
                ),
                TextField(
                  controller: widget.locationController,
                  decoration: const InputDecoration(labelText: '場所'),
                  maxLines: null,
                ),
                TextField(
                  controller: widget.startController,
                  decoration: const InputDecoration(labelText: '開始日時'),
                  maxLines: 1,
                ),
                TextField(
                  controller: widget.endController,
                  decoration: const InputDecoration(labelText: '終了日時'),
                  maxLines: 1,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text("キャンセル"),
            ),
            TextButton(
              onPressed: () {
                setState(() {
                  // ダイアログのテキストを保存して更新
                  summary = widget.summaryController.text;
                  description = widget.descriptionController.text;
                  location = widget.locationController.text;
                  start = widget.startController.text;
                  end = widget.endController.text;
                });
                Navigator.of(context).pop();
              },
              child: const Text("保存"),
            ),
          ],
        );
      },
    );
  }
}