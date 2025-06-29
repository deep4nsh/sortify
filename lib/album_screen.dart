import 'package:flutter/material.dart';
import 'home_screen.dart';
import 'album_detail_screen.dart';
import 'home_screen.dart' as _HomeScreenState;

class AlbumScreen extends StatelessWidget {
  const AlbumScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final images = _HomeScreenState.allImagesGlobal;
    final categories = images.map((e) => e.label).toSet().toList();

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('Albums'),
        backgroundColor: const Color(0xFF8B61C2),
      ),
      body: ListView.builder(
        itemCount: categories.length,
        itemBuilder: (context, index) {
          final label = categories[index];
          final count = images.where((e) => e.label == label).length;

          return ListTile(
            leading: const Icon(Icons.folder, color: Colors.white),
            title: Text(label, style: const TextStyle(color: Colors.white)),
            subtitle: Text('$count image(s)', style: const TextStyle(color: Colors.white70)),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => AlbumDetailScreen(label: label),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
