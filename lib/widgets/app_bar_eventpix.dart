import 'package:flutter/material.dart';

class AppBarEventpix extends StatelessWidget implements PreferredSizeWidget {
  @override
  final Size preferredSize;

  const AppBarEventpix({super.key})
      : preferredSize = const Size.fromHeight(56.0),
        super();

  @override
  Widget build(BuildContext context) {
    return AppBar(
      centerTitle: true,
      backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      title: InkWell(
        child: Image.asset(
          'assets/icon/logo_name.png',
          height: 40,
        ),
        onTap: () {
          Navigator.of(context).pushReplacementNamed('/');
        },
      ),
    );
  }
}
