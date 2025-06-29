import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:photo_view/photo_view.dart';
import 'package:share_plus/share_plus.dart';
import 'package:photo_manager/photo_manager.dart';
import 'home_screen.dart'; // To import CategorizedImage class

class FullImageViewer extends StatefulWidget {
  final List<CategorizedImage> images;
  final int initialIndex;

  const FullImageViewer({super.key, required this.images, required this.initialIndex});

  @override
  State<FullImageViewer> createState() => _FullImageViewerState();
}

class _FullImageViewerState extends State<FullImageViewer> {
  late PageController _pageController;
  late int currentIndex;

  @override
  void initState() {
    super.initState();
    currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: currentIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _shareImage(AssetEntity entity) async {
    final file = await entity.file;
    if (file != null) {
      await Share.shareXFiles([XFile(file.path)]);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: Text('${currentIndex + 1} / ${widget.images.length}'),
        actions: [
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: () => _shareImage(widget.images[currentIndex].entity),
          ),
        ],
      ),
      body: Stack(
        children: [
          PageView.builder(
            controller: _pageController,
            itemCount: widget.images.length,
            onPageChanged: (index) => setState(() => currentIndex = index),
            itemBuilder: (_, index) {
              return FutureBuilder<Uint8List?>(
                future: widget.images[index].entity.originBytes,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.done && snapshot.hasData) {
                    return PhotoView(
                      imageProvider: MemoryImage(snapshot.data!),
                      backgroundDecoration: const BoxDecoration(color: Colors.black),
                    );
                  }
                  return const Center(child: CircularProgressIndicator(color: Colors.white));
                },
              );
            },
          ),
          Positioned(
            bottom: 20,
            left: 0,
            right: 0,
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.black87,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(
                  widget.images[currentIndex].label,
                  style: const TextStyle(color: Colors.white70, fontSize: 16, fontWeight: FontWeight.w500),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
