import 'package:flutter/material.dart';

import 'utils.dart';

class ResultPage extends StatelessWidget {
  final Json json;

  const ResultPage({super.key, required this.json});

  @override
  Widget build(BuildContext context) {
    var children = <Widget>[const Text('変換結果')];
    for (var event in json['events']) {
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
            children: children,
          ),
        ),
      ),
    );
  }
}