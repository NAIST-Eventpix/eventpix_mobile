import 'package:flutter/material.dart';
import 'package:device_calendar/device_calendar.dart';
import 'package:timezone/timezone.dart' as tz;

import '../utils.dart';

final DeviceCalendarPlugin _deviceCalendarPlugin = DeviceCalendarPlugin();

class ResultPage extends StatelessWidget {
  final Json json;

  const ResultPage({super.key, required this.json});

  Future<Calendar?> selectCalendar(
      BuildContext context, List<Calendar> calendars) async {
    return await showDialog<Calendar>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('カレンダー選択'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              for (var calendar in calendars)
                ListTile(
                  title: Text(calendar.name ?? '無名のカレンダー'),
                  onTap: () {
                    Navigator.of(context).pop(calendar);
                  },
                ),
            ],
          ),
        );
      },
    );
  }

  void registCalendar(BuildContext context, Json json) async {
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

    final Calendar? calendar =
        await selectCalendar(context, calendarsResult.data!.toList());

    if (calendar == null) {
      logger.severe("カレンダーが選択されませんでした．");
      return;
    }

    for (var eventData in json['events']) {
      final event = Event(calendar.id);
      final DateTime dateStart = DateTime.parse(eventData['dtstart']);
      final DateTime dateEnd = DateTime.parse(eventData['dtend']);
      event.title = eventData['summary'];
      event.start = tz.TZDateTime.from(dateStart, tz.local);
      event.end = tz.TZDateTime.from(dateEnd, tz.local);
      event.description = eventData['description'];
      event.location = eventData['location'];

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
    var children = <Widget>[const Text('変換結果')];
    for (var event in json['events']) {
      logger.info(event['dtstart']);
      logger.info(event['dtend']);
      children.add(
        EventCard(
          title: event['summary'],
          description: event['description'],
          start: DateTime.parse(event['dtstart']),
          end: DateTime.parse(event['dtend']),
          location: event['location'],
        ),
      );
    }
    return Scaffold(
      appBar: const MyAppBar(),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            children: children +
                [
                  ElevatedButton(
                    onPressed: () {
                      registCalendar(context, json);
                    },
                    child: const Text('カレンダーに登録'),
                  ),
                ],
          ),
        ),
      ),
    );
  }
}
