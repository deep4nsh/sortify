import 'dart:typed_data';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:photo_manager/photo_manager.dart';
import 'image_labeler.dart';

class CategorizedImage {
  final AssetEntity entity;
  final String label;

  CategorizedImage(this.entity, this.label);
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<CategorizedImage> allImages = [];
  String selectedCategory = 'All';
  bool isLoading = true;
  bool permissionDenied = false;

  @override
  void initState() {
    super.initState();
    _fetchImages();
  }

  Future<void> _fetchImages() async {
    final result = await PhotoManager.requestPermissionExtend();

    if (!result.hasAccess) {
      setState(() {
        permissionDenied = true;
        isLoading = false;
      });
      return;
    }

    final albums = await PhotoManager.getAssetPathList(
      onlyAll: true,
      type: RequestType.image,
    );

    final recentImages = await albums.first.getAssetListPaged(page: 0, size: 20);
    List<CategorizedImage> tempList = [];

    for (var entity in recentImages) {
      final file = await entity.file;
      if (file != null) {
        final label = await ImageLabelerHelper.classify(file);
        tempList.add(CategorizedImage(entity, label));
      }
    }

    setState(() {
      allImages = tempList;
      isLoading = false;
    });
  }

  @override
  void dispose() {
    ImageLabelerHelper.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final filtered = selectedCategory == 'All'
        ? allImages
        : allImages.where((img) => img.label == selectedCategory).toList();

    final categories = ['All', ...{...allImages.map((img) => img.label)}];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Sortify'),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : permissionDenied
          ? const Center(
        child: Text('Permission Denied. Please allow access.',
            style: TextStyle(color: Colors.white70)),
      )
          : Column(
        children: [
          SizedBox(
            height: 50,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: categories.length,
              itemBuilder: (_, index) {
                final cat = categories[index];
                final selected = cat == selectedCategory;
                return GestureDetector(
                  onTap: () => setState(() => selectedCategory = cat),
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 6, vertical: 10),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: selected ? Colors.white : Colors.white24,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      cat,
                      style: TextStyle(
                        color: selected ? const Color(0xFF8B61C2) : Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          Expanded(
            child: GridView.builder(
              padding: const EdgeInsets.all(8),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                mainAxisSpacing: 4,
                crossAxisSpacing: 4,
              ),
              itemCount: filtered.length,
              itemBuilder: (_, index) {
                final img = filtered[index];
                return FutureBuilder<Uint8List?>(
                  future: img.entity.thumbnailDataWithSize(const ThumbnailSize(200, 200)),
                  builder: (_, snapshot) {
                    if (snapshot.connectionState == ConnectionState.done &&
                        snapshot.hasData) {
                      return Image.memory(snapshot.data!, fit: BoxFit.cover);
                    } else {
                      return const ColoredBox(
                        color: Colors.grey,
                        child: Center(child: CircularProgressIndicator()),
                      );
                    }
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
