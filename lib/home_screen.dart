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
  final ScrollController _categoryController = ScrollController();

  @override
  void initState() {
    super.initState();
    _fetchImages();
  }

  Future<void> _fetchImages() async {
    print("Checking permissions...");

    final PermissionState result = await PhotoManager.requestPermissionExtend();
    final bool granted = result.isAuth || result.hasAccess;

    print("Permission granted: $granted");

    if (!granted) {
      setState(() {
        permissionDenied = true;
        isLoading = false;
      });
      return;
    }

    try {
      final albums = await PhotoManager.getAssetPathList(
        onlyAll: true,
        type: RequestType.image,
      );

      if (albums.isEmpty) {
        setState(() {
          allImages = [];
          isLoading = false;
        });
        return;
      }

      final recentImages = await albums.first.getAssetListPaged(page: 0, size: 30);

      List<CategorizedImage> tempList = [];

      for (final entity in recentImages) {
        final file = await entity.file;
        if (file != null) {
          final label = await ImageLabelerHelper.classify(file);
          tempList.add(CategorizedImage(entity, label));
        }
      }

      setState(() {
        allImages = tempList;
        isLoading = false;
        permissionDenied = false;
      });
    } catch (e) {
      print("Error loading images: $e");
      setState(() {
        permissionDenied = true;
        isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    ImageLabelerHelper.dispose();
    _categoryController.dispose();
    super.dispose();
  }

  Widget _buildPermissionDenied() => Center(
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Text(
          'Permission Required\nGrant access to your photo library',
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.white70, fontSize: 16),
        ),
        const SizedBox(height: 20),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF8B61C2),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          ),
          onPressed: PhotoManager.openSetting,
          child: const Text('Open Settings', style: TextStyle(fontSize: 16)),
        ),
      ],
    ),
  );

  Widget _buildCategoryChip(String label) {
    final isSelected = label == selectedCategory;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: ChoiceChip(
        label: Text(label, overflow: TextOverflow.ellipsis),
        selected: isSelected,
        onSelected: (_) => setState(() => selectedCategory = label),
        labelStyle: TextStyle(
          color: isSelected ? const Color(0xFF8B61C2) : Colors.white,
          fontWeight: FontWeight.bold,
        ),
        backgroundColor: Colors.white24,
        selectedColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
    );
  }

  Widget _buildImageTile(CategorizedImage img) {
    return FutureBuilder<Uint8List?>(
      future: img.entity.thumbnailDataWithSize(const ThumbnailSize(250, 250)),
      builder: (_, snapshot) {
        if (snapshot.hasData) {
          return ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Stack(
              children: [
                Positioned.fill(
                  child: Image.memory(snapshot.data!, fit: BoxFit.cover),
                ),
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: Container(
                    color: Colors.black54,
                    padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 6),
                    child: Text(
                      img.label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        }
        return Container(
          decoration: BoxDecoration(
            color: Colors.grey[800],
            borderRadius: BorderRadius.circular(10),
          ),
          child: const Center(
            child: CircularProgressIndicator(color: Color(0xFF8B61C2)),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final filteredImages = selectedCategory == 'All'
        ? allImages
        : allImages.where((img) => img.label == selectedCategory).toList();

    final categories = ['All', ...Set.from(allImages.map((img) => img.label))];

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('Sortify', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFF8B61C2),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              setState(() => isLoading = true);
              _fetchImages();
            },
          ),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF8B61C2)))
          : permissionDenied
          ? _buildPermissionDenied()
          : Column(
        children: [
          Container(
            height: 60,
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: ListView.builder(
              controller: _categoryController,
              scrollDirection: Axis.horizontal,
              itemCount: categories.length,
              itemBuilder: (_, index) =>
                  _buildCategoryChip(categories[index]),
            ),
          ),
          Expanded(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              child: filteredImages.isEmpty
                  ? const Center(
                child: Text(
                  'No images found',
                  style: TextStyle(
                      color: Colors.white70, fontSize: 18),
                ),
              )
                  : GridView.builder(
                key: ValueKey<String>(selectedCategory),
                padding: const EdgeInsets.all(8),
                gridDelegate:
                const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  mainAxisSpacing: 4,
                  crossAxisSpacing: 4,
                  childAspectRatio: 0.8,
                ),
                itemCount: filteredImages.length,
                itemBuilder: (_, index) =>
                    _buildImageTile(filteredImages[index]),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
