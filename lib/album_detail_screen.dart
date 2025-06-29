import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:photo_manager/photo_manager.dart';
import 'home_screen.dart';
import 'home_screen.dart' as _HomeScreenState;

class AlbumDetailScreen extends StatelessWidget {
  final String label;

  const AlbumDetailScreen({super.key, required this.label});

  @override
  Widget build(BuildContext context) {
    final images = _HomeScreenState.allImagesGlobal
        .where((element) => element.label == label)
        .toList();

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: Text(label),
        backgroundColor: const Color(0xFF8B61C2),
      ),
      body: GridView.builder(
        padding: const EdgeInsets.all(8),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          mainAxisSpacing: 4,
          crossAxisSpacing: 4,
        ),
        itemCount: images.length,
        itemBuilder: (context, index) {
          return FutureBuilder<Uint8List?>(
            future: images[index].entity.thumbnailDataWithSize(const ThumbnailSize(200, 200)),
            builder: (_, snapshot) {
              if (snapshot.hasData) {
                return ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.memory(snapshot.data!, fit: BoxFit.cover),
                );
              }
              return const Center(child: CircularProgressIndicator(color: Color(0xFF8B61C2)));
            },
          );
        },
      ),
    );
  }
}
