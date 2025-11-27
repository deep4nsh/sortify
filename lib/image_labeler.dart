import 'dart:io';
import 'package:google_mlkit_image_labeling/google_mlkit_image_labeling.dart';

class ImageLabelerHelper {
  static final ImageLabeler _labeler = ImageLabeler(
    options: ImageLabelerOptions(confidenceThreshold: 0.3),
  );

  static Future<String> classify(File file) async {
    final inputImage = InputImage.fromFile(file);
    final labels = await _labeler.processImage(inputImage);

    if (labels.isNotEmpty) {
      // Sort by confidence
      labels.sort((a, b) => b.confidence.compareTo(a.confidence));
      
      // Filter out generic terms
      const blocklist = [
        'Fun', 'Snapshot', 'Photography', 'Event', 'Room', 'Space', 
        'Vehicle', 'Product', 'Design', 'Pattern', 'Colorfulness'
      ];

      for (final label in labels) {
        if (!blocklist.contains(label.label)) {
          return label.label;
        }
      }
      
      // Fallback to top label if all are in blocklist
      return labels.first.label;
    } else {
      return "Unknown";
    }
  }

  static void dispose() {
    _labeler.close();
  }
}
