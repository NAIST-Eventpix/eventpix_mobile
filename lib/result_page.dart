import 'package:flutter/material.dart';
import 'dart:convert';

import 'utils.dart';

class ResultPage extends StatelessWidget {
  final Json json;

  const ResultPage({super.key, required this.json});

  @override
  Widget build(BuildContext context) {
    String jsonString = jsonEncode(json);
    return Scaffold(
        appBar: const MyAppBar(),
        body: Center(
          child: Text(jsonString),
        ));
  }
}