import 'package:flutter/material.dart';
import 'home_screen.dart';

void main() {
  runApp(const SortifyApp());
}

class SortifyApp extends StatelessWidget {
  const SortifyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Sortify MLKit',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        scaffoldBackgroundColor: Colors.black,
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF8B61C2),
        ),
      ),
      home: const HomeScreen(),
    );
  }
}
