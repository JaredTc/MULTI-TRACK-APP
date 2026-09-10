import 'package:flutter/material.dart';
import 'package:multitracks/widgets/app_bar_nav.dart';

class LibraryScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBarNav(),
      body: Center(child: Text('Library Screen')),
    );
  }
}
