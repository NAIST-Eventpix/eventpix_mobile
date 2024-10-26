import 'package:flutter/material.dart';
import 'dart:convert';

import 'utils.dart';

class ImageDisplayPage extends StatelessWidget {
  final Json json;

  const ImageDisplayPage({super.key, required this.json});

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