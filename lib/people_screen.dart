import 'dart:io';
import 'package:flutter/material.dart';
import 'package:photo_manager/photo_manager.dart';
import 'home_screen.dart';
import 'services/face_service.dart';
import 'full_image_viewer.dart';

class PeopleScreen extends StatefulWidget {
  const PeopleScreen({super.key});

  @override
  State<PeopleScreen> createState() => _PeopleScreenState();
}

class _PeopleScreenState extends State<PeopleScreen> {
  bool _isScanning = false;
  List<Person> _people = [];
  String _statusMessage = "";
  double _progress = 0.0;

  @override
  void initState() {
    super.initState();
    _initializeAndScan();
  }

  Future<void> _initializeAndScan() async {
    await FaceService.initialize();
    _startScanning();
  }

  Future<void> _startScanning() async {
    setState(() {
      _isScanning = true;
      _statusMessage = "Preparing to scan...";
      _progress = 0.0;
    });

    // Use the global list of images from HomeScreen
    // Note: In a real app, we should probably fetch them fresh or pass them in.
    // For now, accessing the global variable is a quick hack.
    // Ensure we have files.
    
    List<FaceData> allFaces = [];
    final images = allImagesGlobal; // From home_screen.dart
    int total = images.length;
    int processed = 0;

    for (var img in images) {
      processed++;
      setState(() {
        _progress = processed / total;
        _statusMessage = "Scanning image $processed / $total";
      });

      try {
        final file = await img.entity.file;
        if (file != null) {
          final faces = await FaceService.detectFaces(file);
          for (var face in faces) {
            final embedding = await FaceService.getEmbedding(file, face);
            if (embedding != null) {
              allFaces.add(FaceData(file.path, face, embedding));
            }
          }
        }
      } catch (e) {
        print("Error processing image: $e");
      }
      
      // Yield to UI thread occasionally
      if (processed % 5 == 0) await Future.delayed(Duration.zero);
    }

    setState(() {
      _statusMessage = "Clustering faces...";
    });

    // Cluster
    final people = FaceService.clusterFaces(allFaces);

    setState(() {
      _people = people;
      _isScanning = false;
      _statusMessage = "Found ${people.length} people";
    });
  }

  void _renamePerson(Person person) {
    TextEditingController controller = TextEditingController(text: person.name);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Rename Person"),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(hintText: "Enter name"),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () {
              setState(() {
                person.name = controller.text;
              });
              Navigator.pop(context);
            },
            child: const Text("Save"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('People'),
        backgroundColor: const Color(0xFF8B61C2),
      ),
      body: _isScanning
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const CircularProgressIndicator(color: Color(0xFF8B61C2)),
                  const SizedBox(height: 20),
                  Text(
                    _statusMessage,
                    style: const TextStyle(color: Colors.white70),
                  ),
                  const SizedBox(height: 10),
                  LinearProgressIndicator(value: _progress),
                ],
              ),
            )
          : _people.isEmpty
              ? const Center(
                  child: Text(
                    "No faces found.",
                    style: TextStyle(color: Colors.white54),
                  ),
                )
              : GridView.builder(
                  padding: const EdgeInsets.all(12),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: 0.8,
                  ),
                  itemCount: _people.length,
                  itemBuilder: (context, index) {
                    final person = _people[index];
                    // Use the first face image as thumbnail
                    final thumbPath = person.faces.first.imagePath;
                    
                    return GestureDetector(
                      onTap: () {
                        // TODO: Show all images for this person
                        // For now, just rename
                        _renamePerson(person);
                      },
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.grey[900],
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          children: [
                            Expanded(
                              child: ClipRRect(
                                borderRadius: const BorderRadius.vertical(
                                    top: Radius.circular(12)),
                                child: Image.file(
                                  File(thumbPath),
                                  fit: BoxFit.cover,
                                  width: double.infinity,
                                ),
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Column(
                                children: [
                                  Text(
                                    person.name,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  Text(
                                    "${person.faces.length} photos",
                                    style: const TextStyle(
                                      color: Colors.white54,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}
