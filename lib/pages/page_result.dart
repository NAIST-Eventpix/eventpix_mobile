import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:device_calendar/device_calendar.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:intl/intl.dart';

import '../utils.dart';

final DeviceCalendarPlugin _deviceCalendarPlugin = DeviceCalendarPlugin();

class PageResult extends StatefulWidget {
  final Json json;

  const PageResult({super.key, required this.json});

  @override
  PageResultState createState() => PageResultState();
}

class PageResultState extends State<PageResult> {
  late List<EventCard> eventCards;

  @override
  void initState() {
    super.initState();
    // EventCardのリストを初期化
    eventCards = widget.json['events'].map<EventCard>((event) {
      return EventCard(
        title: event['summary'],
        description: event['description'],
        start: DateTime.parse(event['dtstart']),
        end: DateTime.parse(event['dtend']),
        location: event['location'],
      );
    }).toList();
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

    for (var eventCard in eventCards) {
      final event = Event(calendar.id);
      event.title = eventCard.title;
      event.start = tz.TZDateTime.from(eventCard.start, tz.local);
      event.end = tz.TZDateTime.from(eventCard.end, tz.local);
      event.description = eventCard.description;
      event.location = eventCard.location;

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
    var children = <Widget>[
      const Text(
        '変換結果',
        style: TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.bold,
        ),
      ),
      const SizedBox(height: 16),
    ];

    children.addAll(eventCards);

    return Scaffold(
      appBar: const MyAppBar(),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            children: children,
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
  EventCardState createState() => EventCardState();
}

class EventCardState extends State<EventCard> {
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
