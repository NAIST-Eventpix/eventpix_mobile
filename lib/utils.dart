import 'package:flutter/material.dart';
import 'package:logging/logging.dart';

final Logger logger = Logger('Eventpix');

void setupLogging() {
  Logger.root.level = Level.ALL;
  Logger.root.onRecord.listen((record) {
    print('${record.level.name}: ${record.time}: ${record.message}');
  });
}

typedef Json = Map<String, dynamic>;

const String API_DOMAIN = 'eventpix.jp';

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

class NoAnimationPageRoute<T> extends MaterialPageRoute<T> {
  NoAnimationPageRoute({required super.builder});

  @override
  Widget buildTransitions(BuildContext context, Animation<double> animation,
      Animation<double> secondaryAnimation, Widget child) {
    // 遷移アニメーションを無効化
    return child;
  }
}

class EventCard extends StatelessWidget {
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
  Widget build(BuildContext context) {
    return Card(
      child: Column(
        children: <Widget>[
          ListTile(
            title: Text(title),
            subtitle: Text(description),
          ),
          ListTile(
            title: Text('開始: $start'),
            subtitle: Text('終了: $end'),
          ),
          ListTile(
            title: Text('場所: $location'),
          ),
        ],
      ),
    );
  }
}