import 'package:flutter/material.dart';
import 'screens/connection_screen.dart';

void main() {
  runApp(const DaraApp());
}

class DaraApp extends StatelessWidget {
  const DaraApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Dara - Jogo de Estratégia',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.brown,
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
      ),
      home: const ConnectionScreen(),
    );
  }
}
