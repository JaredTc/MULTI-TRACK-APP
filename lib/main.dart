import 'package:flutter/material.dart';
import 'package:flutter_soloud/flutter_soloud.dart';
import 'package:multitracks/config/app_config.dart';
import 'package:multitracks/config/app_theme.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:multitracks/screens/home_screen.dart';
import 'package:multitracks/services/hive_service.dart';

// void main() async {
//   WidgetsFlutterBinding.ensureInitialized();
//   await HiveService.init();
//   runApp(const ProviderScope(child: MyApp()));
// }
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Si SoLoud ya estaba inicializado antes del Hot Restart, lo apagamos primero
  if (SoLoud.instance.isInitialized) {
    SoLoud.instance.deinit();
  }

  // Inicializamos el motor limpiamente
  await SoLoud.instance.init();
  await HiveService.init();

  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: AppConfig.appName,
      theme: ThemeData.dark(),
      darkTheme: AppTheme.darkTheme,
      home: HomeScreen(),
    );
  }
}
