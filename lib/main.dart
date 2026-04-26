import 'package:flutter/material.dart';
import 'package:frontend_app/screens/main_navigation.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MiHeladeriaApp());
}

class MiHeladeriaApp extends StatelessWidget {
  const MiHeladeriaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Heladería App',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      // Aquí le decimos que la pantalla inicial es el Dashboard
      home: const MainNavigation(),
    );
  }
}