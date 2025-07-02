import 'package:caesar_puzzle/presentation/pages/puzzle/puzzle_screen.dart';
import 'package:flutter/material.dart';

import 'injection.dart';

Future<void> main() async {
  configureInjection();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Caesar Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: Material(
        child: const PuzzleScreen(),
      ),
    );
  }
}
