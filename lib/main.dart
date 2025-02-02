import 'package:flutter/material.dart';
import 'package:buildai/screens/search_screen.dart';

void main() {
  runApp(const BuildAIApp());
}

class BuildAIApp extends StatelessWidget {
  const BuildAIApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'BuildAI',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: const SearchScreen(),
    );
  }
}
