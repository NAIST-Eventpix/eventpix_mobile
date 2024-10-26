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