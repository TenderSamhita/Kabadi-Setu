import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'app_state.dart';
import 'screens/launch_screen.dart';
import 'theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final appState = AppState();
  await appState.init();
  runApp(
    ChangeNotifierProvider<AppState>.value(
      value: appState,
      child: const KabadiSetuApp(),
    ),
  );
}

class KabadiSetuApp extends StatelessWidget {
  const KabadiSetuApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Kabadi Setu',
      debugShowCheckedModeBanner: false,
      theme: kabadiTheme(),
      home: const LaunchScreen(),
    );
  }
}
