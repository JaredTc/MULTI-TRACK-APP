import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:multitracks/providers/session_provider.dart'; // Ajusta esta importación según la ruta de tu proyecto
import 'package:multitracks/screens/library_screen.dart';
import 'package:multitracks/screens/soloud_editor_screen.dart';
import 'package:multitracks/widgets/app_bar_nav.dart';
import 'package:multitracks/widgets/header_card.dart';
import 'package:multitracks/widgets/navigation_squads.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
                // Ajuste para la navegación con reseteo previo:
                InkWell(
                  onTap: () async {
                    // 1. Vacia la sesión anterior y libera reproductores
                    await ref.read(sessionProvider.notifier).resetSession();

                    // 2. Navega a la nueva sesión
                    if (context.mounted) {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const NewSesionScreen(),
                        ),
                      );
                    }
                  },
                  child: IgnorePointer(
                    child: NavigationWidget(
                      title: 'NEW SESION',
                      icon: Icons.add,
                      description: 'Create a new mix',
                      targetScreen: const NewSesionScreen(),
                    ),
                  ),
                ),
                NavigationWidget(
                  title: 'SAVED SESIONS',
                  icon: Icons.replay_outlined,
                  description: 'View your saved sessions',
                  targetScreen: const LibraryScreen(),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
