import 'package:flutter/material.dart';
import 'home_screen.dart';
import 'album_screen.dart';
import 'package:provider/provider.dart';
import 'theme_provider.dart';

class MainHome extends StatefulWidget {
  const MainHome({super.key});

  @override
  State<MainHome> createState() => _MainHomeState();
}

class _MainHomeState extends State<MainHome> {
  int selectedIndex = 0;

  final List<Widget> screens = const [
    HomeScreen(),
    AlbumScreen(),
  ];

  final List<String> titles = [
    'All Photos',
    'Albums',
  ];

  void _selectScreen(int index) {
    setState(() => selectedIndex = index);
    Navigator.pop(context); // Close drawer
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Switched to ${titles[index]}'),
        duration: const Duration(milliseconds: 800),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(titles[selectedIndex],
            style: const TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFF8B61C2),
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            const DrawerHeader(
              decoration: BoxDecoration(color: Color(0xFF8B61C2)),
              child: Text('Sortify Menu', style: TextStyle(color: Colors.white, fontSize: 24)),
            ),
            ListTile(
              leading: const Icon(Icons.image),
              title: const Text('All Photos'),
              selected: selectedIndex == 0,
              selectedTileColor: Colors.purple[50],
              onTap: () {
                setState(() => selectedIndex = 0);
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_album),
              title: const Text('Albums'),
              selected: selectedIndex == 1,
              selectedTileColor: Colors.purple[50],
              onTap: () {
                setState(() => selectedIndex = 1);
                Navigator.pop(context);
              },
            ),
            const Divider(),
            Consumer<ThemeProvider>(
              builder: (context, themeProvider, _) => SwitchListTile(
                title: const Text("Dark Theme"),
                secondary: Icon(
                  themeProvider.isDarkMode ? Icons.dark_mode : Icons.light_mode,
                  color: themeProvider.isDarkMode ? Colors.white : Colors.black,
                ),
                value: themeProvider.isDarkMode,
                onChanged: (value) => themeProvider.toggleTheme(value),
              ),
            ),
          ],
        ),
      ),
      body: screens[selectedIndex],
    );
  }
}
