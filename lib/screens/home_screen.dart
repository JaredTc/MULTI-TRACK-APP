import 'package:flutter/material.dart';
import 'package:multitracks/screens/library_screen.dart';
import 'package:multitracks/screens/new_sesion_screen.dart';
import 'package:multitracks/widgets/app_bar_nav.dart';
import 'package:multitracks/widgets/header_card.dart';
import 'package:multitracks/widgets/navigation_squads.dart';

class HomeScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBarNav(),
      body: SafeArea(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            HeaderCard(),
            Image.asset('assets/title.png', width: 1200, height: 200),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                NavigationWidget(
                  title: 'NEW SESION',
                  icon: Icons.add,
                  description: 'Create a new mix',
                  targetScreen:
                      NewSesionScreen(), // Replace with the actual target screen
                ),
                NavigationWidget(
                  title: 'SAVED SESIONS',
                  icon: Icons.replay_outlined,
                  description: 'View your saved sessions',
                  targetScreen:
                      LibraryScreen(), // Replace with the actual target screen
                ),
              ],
            ),
            // Add your home screen content here
          ],
        ),
      ),
    );
  }
}
