import 'package:flutter/material.dart';
import 'home_screen.dart';
import 'album_screen.dart';

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
        child: Column(
          children: [
            const DrawerHeader(
              decoration: BoxDecoration(color: Color(0xFF8B61C2)),
              child: Center(
                child: Text('Sortify Menu',
                    style: TextStyle(color: Colors.white, fontSize: 24)),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.image),
              title: const Text('All Photos'),
              selected: selectedIndex == 0,
              selectedTileColor: Colors.purple[100],
              onTap: () => _selectScreen(0),
            ),
            ListTile(
              leading: const Icon(Icons.photo_album),
              title: const Text('Albums'),
              selected: selectedIndex == 1,
              selectedTileColor: Colors.purple[100],
              onTap: () => _selectScreen(1),
            ),
            const Spacer(),
            const Divider(),
            Padding(
              padding: const EdgeInsets.all(10),
              child: Text('© 2025 Sortify',
                  style: TextStyle(color: Colors.grey[600])),
            ),
          ],
        ),
      ),
      body: screens[selectedIndex],
    );
  }
}
