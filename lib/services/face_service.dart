import 'dart:io';
import 'dart:math';
import 'dart:typed_data';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'package:tflite_flutter/tflite_flutter.dart';
import 'package:image/image.dart' as img;

class FaceData {
  final String imagePath;
  final Face face;
  final List<double> embedding;

  FaceData(this.imagePath, this.face, this.embedding);
}

class Person {
  String id;
  String name;
  List<FaceData> faces;

  Person({required this.id, required this.name, required this.faces});
}

class FaceService {
  static final FaceDetector _faceDetector = FaceDetector(
    options: FaceDetectorOptions(
      performanceMode: FaceDetectorMode.accurate,
      enableLandmarks: true,
    ),
  );

  static Interpreter? _interpreter;

  static Future<void> initialize() async {
    try {
      _interpreter = await Interpreter.fromAsset('assets/MobileFaceNet.tflite');
      print('FaceService: TFLite model loaded.');
    } catch (e) {
      print('FaceService: Failed to load model: $e');
    }
  }

  static Future<List<Face>> detectFaces(File imageFile) async {
    final inputImage = InputImage.fromFile(imageFile);
    return await _faceDetector.processImage(inputImage);
  }

  // Preprocess image for MobileFaceNet (112x112, normalized)
  static Future<List<double>?> getEmbedding(File imageFile, Face face) async {
    if (_interpreter == null) return null;

    try {
      final bytes = await imageFile.readAsBytes();
      final img.Image? originalImage = img.decodeImage(bytes);
      if (originalImage == null) return null;

      // Crop the face
      final x = face.boundingBox.left.toInt().clamp(0, originalImage.width);
      final y = face.boundingBox.top.toInt().clamp(0, originalImage.height);
      final w = face.boundingBox.width.toInt().clamp(0, originalImage.width - x);
      final h = face.boundingBox.height.toInt().clamp(0, originalImage.height - y);

      img.Image faceImage = img.copyCrop(originalImage, x: x, y: y, width: w, height: h);
      
      // Resize to 112x112 (standard for MobileFaceNet)
      faceImage = img.copyResize(faceImage, width: 112, height: 112);

      // Convert to input format [1, 112, 112, 3]
      // MobileFaceNet expects values normalized to [-1, 1] usually, or [0, 1].
      // Standard MobileFaceNet often uses (pixel - 127.5) / 128.0
      
      var input = List.generate(1, (i) => List.generate(112, (j) => List.generate(112, (k) => List.filled(3, 0.0))));
      
      for (int y = 0; y < 112; y++) {
        for (int x = 0; x < 112; x++) {
          final pixel = faceImage.getPixel(x, y);
          input[0][y][x][0] = (pixel.r - 127.5) / 128.0;
          input[0][y][x][1] = (pixel.g - 127.5) / 128.0;
          input[0][y][x][2] = (pixel.b - 127.5) / 128.0;
        }
      }

      // Output buffer [1, 192] (MobileFaceNet output size)
      var output = List.filled(1 * 192, 0.0).reshape([1, 192]);

      _interpreter!.run(input, output);

      return List<double>.from(output[0]);
    } catch (e) {
      print('FaceService: Embedding error: $e');
      return null;
    }
  }

  static double _euclideanDistance(List<double> e1, List<double> e2) {
    double sum = 0.0;
    for (int i = 0; i < e1.length; i++) {
      sum += pow(e1[i] - e2[i], 2);
    }
    return sqrt(sum);
  }

  // Simple clustering
  static List<Person> clusterFaces(List<FaceData> allFaces) {
    List<Person> people = [];
    double threshold = 0.8; // Tune this value (0.8 - 1.2 usually for Euclidean)

    for (var faceData in allFaces) {
      bool found = false;
      for (var person in people) {
        // Compare with the first face of the person (or centroid)
        // For simplicity, comparing with the first one.
        // Better: Compare with all and take average or min distance.
        
        double dist = _euclideanDistance(faceData.embedding, person.faces.first.embedding);
        if (dist < threshold) {
          person.faces.add(faceData);
          found = true;
          break;
        }
      }

      if (!found) {
        people.add(Person(
          id: DateTime.now().millisecondsSinceEpoch.toString() + people.length.toString(),
          name: "Person ${people.length + 1}",
          faces: [faceData],
        ));
      }
    }
    return people;
  }
  
  static void dispose() {
    _faceDetector.close();
    _interpreter?.close();
  }
}
