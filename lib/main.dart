import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'main_home.dart';
import 'theme_provider.dart';
import 'splash_screen.dart';

void main() {
  runApp(
    ChangeNotifierProvider(
      create: (_) => ThemeProvider(),
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Sortify',
      themeMode: themeProvider.themeMode,
      theme: ThemeData(
        brightness: Brightness.light,
        fontFamily: 'Poppins',
        primarySwatch: Colors.deepPurple,
      ),
      darkTheme: ThemeData(
        brightness: Brightness.dark,
        fontFamily: 'Poppins',
        scaffoldBackgroundColor: Colors.black,
        appBarTheme: const AppBarTheme(backgroundColor: Color(0xFF8B61C2)),
        colorScheme: ColorScheme.dark(
          primary: const Color(0xFF8B61C2),
          secondary: Colors.deepPurpleAccent,
        ),
      ),
      home: const SplashScreen(),
    );
  }
}
