import 'dart:io';
import 'package:google_mlkit_image_labeling/google_mlkit_image_labeling.dart';

class ImageLabelerHelper {
  static final ImageLabeler _labeler = ImageLabeler(
    options: ImageLabelerOptions(confidenceThreshold: 0.5),
  );

  static Future<String> classify(File file) async {
    final inputImage = InputImage.fromFile(file);
    final labels = await _labeler.processImage(inputImage);

    if (labels.isNotEmpty) {
      return labels.first.label;
    } else {
      return "Unknown";
    }
  }

  static void dispose() {
    _labeler.close();
  }
}
