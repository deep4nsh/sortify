import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:photo_manager/photo_manager.dart';
import 'full_image_viewer.dart';
import 'image_labeler.dart';
import 'services/ai_service.dart';

class CategorizedImage {
  final AssetEntity entity;
  final String label;
  CategorizedImage(this.entity, this.label);
}

List<CategorizedImage> allImagesGlobal = [];

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  DateTime? selectedDate;
  Set<String> favoriteIds = {};
  List<CategorizedImage> allImages = [];
  String selectedCategory = 'All';
  bool isLoading = true;
  bool permissionDenied = false;
  final ScrollController _categoryController = ScrollController();
  TextEditingController _searchController = TextEditingController();
  String searchQuery = '';


  // For progressive loading
  bool _isLoadingMore = false;
  int _loadedCount = 0;
  static const int _batchSize = 30;
  List<AssetEntity> _allEntities = [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _showLoadingDialog(context);
      _fetchInitialImages().then((_) {
        Navigator.of(context, rootNavigator: true).pop(); // Close dialog
      });
    });
  }

  Future<void> _showLoadingDialog(BuildContext context) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        backgroundColor: Colors.black87,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(color: Color(0xFF8B61C2)),
            const SizedBox(height: 24),
            const Text(
              'Sorting your gallery...\nThis will only take a moment!',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white70),
            ),
            const SizedBox(height: 12),
            const Text(
              'Tip: You can tap categories to filter your images.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.purpleAccent, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _fetchInitialImages() async {
    final PermissionState result = await PhotoManager.requestPermissionExtend(
      requestOption: const PermissionRequestOption(
        androidPermission: AndroidPermission(
          type: RequestType.image,
          mediaLocation: false,
        ),
      ),
    );
    final bool granted = result.isAuth || result.hasAccess;

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
          allImagesGlobal = [];
          isLoading = false;
        });
        return;
      }
      // Get all asset entities (for lazy loading)
      final totalAssets = await albums.first.assetCountAsync;
      _allEntities = await albums.first.getAssetListRange(
        start: 0,
        end: totalAssets,
      );

      // Load first batch
      await _loadMoreImages();

      setState(() {
        isLoading = false;
        permissionDenied = false;
      });

      // Start loading more in background
      _progressiveLoad();
    } catch (e) {
      setState(() {
        permissionDenied = true;
        isLoading = false;
      });
    }
  }

  Future<void> _loadMoreImages() async {
    if (_loadedCount >= _allEntities.length) return;
    setState(() => _isLoadingMore = true);

    final nextBatch = _allEntities.skip(_loadedCount).take(_batchSize).toList();
    final futures = nextBatch.map((entity) async {
      try {
        final file = await entity.file;
        if (file != null) {
          // 1. Try on-device ML first
          String label = await ImageLabelerHelper.classify(file);
          
          // 2. Fallback to AI if Unknown
          if (label == "Unknown") {
             // Note: In a real app, you might want to rate-limit this or only do it for specific cases
             // to avoid burning through API quota or slowing down too much.
             final aiLabel = await AIService.classifyImage(file);
             if (aiLabel != null && aiLabel.isNotEmpty) {
               label = aiLabel;
             }
          }
          
          return CategorizedImage(entity, label);
        }
      } catch (_) {}
      return null;
    }).toList();

    final results = await Future.wait(futures);
    final newImages = results.whereType<CategorizedImage>().toList();

    setState(() {
      allImages.addAll(newImages);
      allImagesGlobal = allImages;
      _loadedCount += nextBatch.length;
      _isLoadingMore = false;
    });
  }

  void _progressiveLoad() async {
    while (_loadedCount < _allEntities.length) {
      await _loadMoreImages();
      // Optionally add a delay for smoother progressive loading
      // await Future.delayed(Duration(milliseconds: 100));
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
        const Text('Permission Required\nGrant access to your photo library',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.white70, fontSize: 16)),
        const SizedBox(height: 20),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF8B61C2),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12)),
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

  Widget _buildImageTile(CategorizedImage img, int index, List<CategorizedImage> list) {
    return FutureBuilder<Uint8List?>(
      future: img.entity.thumbnailDataWithSize(const ThumbnailSize(250, 250)),
      builder: (_, snapshot) {
        if (snapshot.hasData) {
          final isFavorite = favoriteIds.contains(img.entity.id);
          return GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => FullImageViewer(
                    images: list,
                    initialIndex: index,
                  ),
                ),
              );
            },
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Stack(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.memory(snapshot.data!, fit: BoxFit.cover, width: double.infinity),
                      ),
                      Positioned(
                        top: 4,
                        right: 4,
                        child: GestureDetector(
                          onTap: () {
                            setState(() {
                              if (isFavorite) {
                                favoriteIds.remove(img.entity.id);
                              } else {
                                favoriteIds.add(img.entity.id);
                              }
                            });
                          },
                          child: Icon(
                            isFavorite ? Icons.favorite : Icons.favorite_border,
                            color: isFavorite ? Colors.redAccent : Colors.white,
                            size: 20,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  img.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: Colors.white70, fontSize: 12),
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
  @override
  Widget build(BuildContext context) {
    final filteredImages = allImages.where((img) {
      final matchesCategory = selectedCategory == 'All' || img.label == selectedCategory;
      final matchesSearch = searchQuery.isEmpty || img.label.toLowerCase().contains(searchQuery.toLowerCase());
      return matchesCategory && matchesSearch;
    }).toList();

    final categories = ['All', ...Set.from(allImages.map((img) => img.label))];

    return Scaffold(
      backgroundColor: const Color(0xFF1A1A1A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF8B61C2),
        title: const Text(
          'Sortify',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
        ),
        elevation: 2,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              setState(() {
                isLoading = true;
                allImages.clear();
                allImagesGlobal.clear();
                _allEntities.clear();
                _loadedCount = 0;
              });
              WidgetsBinding.instance.addPostFrameCallback((_) {
                _showLoadingDialog(context);
                _fetchInitialImages().then((_) {
                  Navigator.of(context, rootNavigator: true).pop();
                });
              });
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
          // Search Bar
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: Material(
              elevation: 2,
              borderRadius: BorderRadius.circular(25),
              color: Colors.white12,
              child: TextField(
                controller: _searchController,
                onChanged: (value) => setState(() => searchQuery = value),
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  prefixIcon: const Icon(Icons.search, color: Colors.white70),
                  hintText: 'Search by label (e.g., cat)',
                  hintStyle: const TextStyle(color: Colors.white54),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
                ),
              ),
            ),
          ),

          // Category Chips
          Container(
            alignment: Alignment.centerLeft,
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 6),
            child: const Text(
              'Categories',
              style: TextStyle(
                color: Colors.white70,
                fontWeight: FontWeight.w600,
                fontSize: 16,
              ),
            ),
          ),
          SizedBox(
            height: 48,
            child: ListView.builder(
              controller: _categoryController,
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              itemCount: categories.length,
              itemBuilder: (_, index) => _buildCategoryChip(categories[index]),
            ),
          ),

          // Image Grid
          const SizedBox(height: 6),
          Expanded(
            child: filteredImages.isEmpty
                ? const Center(
              child: Text(
                'No images found',
                style: TextStyle(color: Colors.white54, fontSize: 16),
              ),
            )
                : NotificationListener<ScrollNotification>(
              onNotification: (notification) {
                if (!_isLoadingMore &&
                    notification.metrics.pixels >=
                        notification.metrics.maxScrollExtent - 200 &&
                    _loadedCount < _allEntities.length) {
                  _loadMoreImages();
                }
                return false;
              },
              child: GridView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  crossAxisSpacing: 6,
                  mainAxisSpacing: 6,
                  childAspectRatio: 0.75,
                ),
                itemCount: filteredImages.length,
                itemBuilder: (_, index) => _buildImageTile(filteredImages[index], index, filteredImages),
              ),
            ),
          ),

          if (_isLoadingMore)
            const Padding(
              padding: EdgeInsets.all(8.0),
              child: CircularProgressIndicator(color: Color(0xFF8B61C2)),
            ),
        ],
      ),
    );
  }
}
