import 'package:flutter/material.dart';

import 'utils.dart';

class ResultPage extends StatelessWidget {
  final Json json;

  const ResultPage({super.key, required this.json});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const MyAppBar(),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: <Widget>[
            const Text('変換結果'),
            DataTable(
              columns: const [
                DataColumn(label: Text("Summary")),
                DataColumn(label: Text("Description")),
                DataColumn(label: Text("DT Start")),
                DataColumn(label: Text("DT End")),
                DataColumn(label: Text("Location")),
              ],
              rows: json['events'].map<DataRow>((event) {
                return DataRow(cells: [
                  DataCell(Text(event['summary'])),
                  DataCell(Text(event['description'])),
                  DataCell(Text(event['dtstart'])),
                  DataCell(Text(event['dtend'])),
                  DataCell(Text(event['location'])),
                ]);
              }).toList(),
            )
          ],
        ),
      ),
    );
  }
}