// ignore_for_file: use_build_context_synchronously

import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:device_calendar/device_calendar.dart';
import 'package:intl/intl.dart';
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
  List<ValueNotifier<bool>> deleteControllers = [];
  Calendar? selectedCalendar;

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

      final deleteController = ValueNotifier<bool>(false);
      deleteControllers.add(deleteController);
    }

    _initializeCalendar();
  }

  Future<void> _initializeCalendar() async {
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
    if (calendarsResult.isSuccess && calendarsResult.data!.isNotEmpty) {
      setState(() {
        selectedCalendar = calendarsResult.data!.first;
      });
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
    for (var controller in deleteControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> selectCalendar(BuildContext context) async {
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
    final groupedCalendars = calendarsResult.data!
        .where((calendar) => calendar.isReadOnly == false)
        .groupListsBy((calendar) => calendar.accountName);

    final selected = await showDialog<Calendar>(
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
                        padding: const EdgeInsets.symmetric(
                            vertical: 4, horizontal: 16),
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
        });

    if (selected != null) {
      setState(() {
        selectedCalendar = selected;
      });
    }
  }

  void registCalendar(BuildContext context) async {
    final Calendar? calendar = selectedCalendar;

    if (calendar == null) {
      logger.severe("カレンダーが選択されませんでした．");
      return;
    }

    for (var ind = 0; ind < controllers.length; ind++) {
      if (deleteControllers[ind].value) {
        logger.fine("登録スキップ");
        continue;
      }
      final e = widget.json['events'][ind];
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

  String formatSavedTime(int seconds) {
    if (seconds >= 60) {
      int minutes = seconds ~/ 60;
      return '$minutes 分';
    } else {
      return '$seconds 秒';
    }
  }

  @override
  Widget build(BuildContext context) {
    // 節約できた時間を計算する
    // 予定の内容をすべて（タイトル，時刻，場所，詳細）入力した場合に
    // 1イベントあたり1.5分節約できたと計算する
    // タイトルと時刻を入力した場合に
    // 1イベントあたり30秒節約できたと計算する
    // chatgptの処理は1イベントあたりわずか4秒程度しかかからないため計算しない
    int eventNum = widget.json['events'].length;
    String timeSavedPerFullEvent = formatSavedTime(eventNum * 90);
    String timeSavedPerBasicEvent = formatSavedTime(eventNum * 30);

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
              const SizedBox(height: 8),
              InkWell(
                onTap: () {
                  showDialog(
                    context: context,
                    builder: (BuildContext context) {
                      return AlertDialog(
                        title: const Text('変換結果詳細'),
                        content: SingleChildScrollView(
                          child: Column(
                            children: [
                              const Text('予定登録件数'),
                              const SizedBox(height: 4),
                              Text(
                                '$eventNum 件',
                                style: TextStyle(
                                  color: Theme.of(context).primaryColor,
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 24),
                              const Text(
                                '予定入力の削減時間',
                              ),
                              const Text('（全ての情報を入力したとき）',
                                  style: TextStyle(
                                    fontSize: 12,
                                  )),
                              const SizedBox(height: 4),
                              Text(
                                timeSavedPerFullEvent,
                                style: TextStyle(
                                  color: Theme.of(context).primaryColor,
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 16),
                              const Text(
                                '予定入力の削減時間',
                              ),
                              const Text(
                                '（タイトル，時刻のみ入力したとき）',
                                style: TextStyle(
                                  fontSize: 12,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                timeSavedPerBasicEvent,
                                style: TextStyle(
                                  color: Theme.of(context).primaryColor,
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                        actions: <Widget>[
                          TextButton(
                            onPressed: () {
                              Navigator.of(context).pop();
                            },
                            child: const Text('閉じる'),
                          ),
                        ],
                      );
                    },
                  );
                },
                child: RichText(
                  text: TextSpan(
                      style: const TextStyle(color: Colors.black),
                      children: [
                        const TextSpan(
                          text: "予定入力の手間を ",
                        ),
                        TextSpan(
                          text: timeSavedPerFullEvent,
                          style: TextStyle(
                            color: Theme.of(context).primaryColor,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const TextSpan(text: " 削減しました  "),
                      ]),
                ),
              ),
              const SizedBox(height: 40),
              InkWell(
                onTap: () => selectCalendar(context),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const Text("カレンダー："),
                    const SizedBox(width: 16),
                    if (selectedCalendar == null)
                      const Text(
                        '未選択',
                        style: TextStyle(
                          fontSize: 16,
                        ),
                      ),
                    if (selectedCalendar != null) ...[
                      Container(
                        width: 16,
                        height: 16,
                        decoration: BoxDecoration(
                          color: Color(selectedCalendar!.color ?? 0xff0000),
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        selectedCalendar!.name ?? '無名のカレンダー',
                        style: const TextStyle(fontSize: 16),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 24),
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: controllers.length,
                itemBuilder: (context, index) {
                  final eventControllers = controllers[index];
                  if (deleteControllers[index].value) {
                    return const SizedBox.shrink();
                  }
                  return EventCard(
                    summaryController: eventControllers['summary']!,
                    descriptionController: eventControllers['description']!,
                    locationController: eventControllers['location']!,
                    startController: eventControllers['dtstart']!,
                    endController: eventControllers['dtend']!,
                    deleteController: deleteControllers[index],
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
  final ValueNotifier<bool> deleteController;

  const EventCard(
      {super.key,
      required this.summaryController,
      required this.descriptionController,
      required this.locationController,
      required this.startController,
      required this.endController,
      required this.deleteController});

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
  late bool isDeleted;

  late TextEditingController startDateController;
  late TextEditingController startTimeController;
  late TextEditingController endDateController;
  late TextEditingController endTimeController;

  bool isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  @override
  void initState() {
    super.initState();
    // 初期値としてコントローラーの内容を設定
    summary = widget.summaryController.text;
    description = widget.descriptionController.text;
    location = widget.locationController.text;
    start = widget.startController.text;
    end = widget.endController.text;
    isDeleted = widget.deleteController.value;

    startDateController = TextEditingController();
    startDateController.text = start.split('T')[0];

    startTimeController = TextEditingController();
    startTimeController.text = start.split('T')[1];

    endDateController = TextEditingController();
    endDateController.text = end.split('T')[0];

    endTimeController = TextEditingController();
    endTimeController.text = end.split('T')[1];
  }

  @override
  Widget build(BuildContext context) {
    String fStart =
        DateFormat('yyyy/MM/dd HH:mm').format(DateTime.parse(start));
    String fEnd = DateFormat('yyyy/MM/dd HH:mm').format(DateTime.parse(end));
    String fDate;
    if (isSameDay(DateTime.parse(start), DateTime.parse(end))) {
      fDate = '$fStart ~ ${DateFormat('HH:mm').format(DateTime.parse(end))}';
    } else {
      fDate = '$fStart ~ $fEnd';
    }

    if (isDeleted) {
      return const SizedBox.shrink();
    }
    return GestureDetector(
      onTap: () {
        _showEditDialog(context);
      },
      child: Card(
        child: ListTile(
          title: Text(
            summary,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: isLandscape(context) ? 20 : 16,
            ),
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (description.isNotEmpty)
                Text(
                  description,
                  style: TextStyle(
                    fontSize: isLandscape(context) ? 16 : 14,
                  ),
                ),
              if (fDate.isNotEmpty)
                Text(
                  fDate,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: isLandscape(context) ? 18 : 14,
                  ),
                ),
              if (location.isNotEmpty)
                Text(
                  '@ $location',
                  style: TextStyle(
                    fontSize: isLandscape(context) ? 16 : 14,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  void _showEditDialog(BuildContext context) {
    logger.fine("Start : Show Edit Dialog");
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
                Row(
                  children: [
                    Expanded(
                      child:
                          _buildDateField(context, "開始日", startDateController),
                    ),
                    Expanded(
                      child:
                          _buildTimeField(context, "開始時刻", startTimeController),
                    ),
                  ],
                ),
                Row(
                  children: [
                    Expanded(
                      child: _buildDateField(context, "終了日", endDateController),
                    ),
                    Expanded(
                      child:
                          _buildTimeField(context, "終了時刻", endTimeController),
                    ),
                  ],
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
                  widget.deleteController.value = true;
                  isDeleted = true;
                });
                Navigator.of(context).pop();
              },
              child: const Text(
                '削除',
                style: TextStyle(
                  color: Colors.red,
                ),
              ),
            ),
            TextButton(
              onPressed: () {
                setState(() {
                  // ダイアログのテキストを保存して更新
                  summary = widget.summaryController.text;
                  description = widget.descriptionController.text;
                  location = widget.locationController.text;
                  start =
                      '${startDateController.text}T${startTimeController.text}';
                  end = '${endDateController.text}T${endTimeController.text}';
                  widget.startController.text = start;
                  widget.endController.text = end;
                });
                Navigator.of(context).pop();
              },
              child: const Text("保存"),
            ),
          ],
        );
      },
    );
    logger.fine("Finish : Show Edit Dialog");
  }

  Widget _buildDateField(
    BuildContext context,
    String label,
    TextEditingController controller,
  ) {
    logger.fine("Build Date Field : $label");
    return TextField(
      controller: controller,
      readOnly: true,
      decoration: InputDecoration(
        labelText: label,
        suffixIcon: const Icon(Icons.calendar_today),
      ),
      onTap: () async {
        final date = await showDatePicker(
          context: context,
          initialDate: DateTime.parse(controller.text),
          firstDate: DateTime(2000),
          lastDate: DateTime(2100),
        );

        if (date == null || !mounted) return;

        controller.text = DateFormat('yyyy-MM-dd').format(date);
      },
    );
  }

  Widget _buildTimeField(
    BuildContext context,
    String label,
    TextEditingController controller,
  ) {
    logger.fine("Build Time Field : $label");
    return TextField(
      controller: controller,
      readOnly: true,
      decoration: InputDecoration(
        labelText: label,
        suffixIcon: const Icon(Icons.access_time),
      ),
      onTap: () async {
        List<String> parts = controller.text.split(':');
        final int hour = int.parse(parts[0]);
        final int minute = int.parse(parts[1]);

        final time = await showTimePicker(
          context: context,
          initialTime: TimeOfDay(hour: hour, minute: minute),
        );

        if (time == null || !mounted) return;

        controller.text = time.format(context);
      },
    );
  }
}
