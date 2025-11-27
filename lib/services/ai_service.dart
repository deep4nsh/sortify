import 'dart:io';
import 'package:google_generative_ai/google_generative_ai.dart';

class AIService {
  // TODO: Replace with your actual API key or use --dart-define
  static const String _apiKey = 'AIzaSyA6NejQdg3Z6PzF4Yubrk5M6AwvlfBscYs';

  static final GenerativeModel _model = GenerativeModel(
    model: 'gemini-1.5-flash',
    apiKey: _apiKey,
  );

  static Future<String?> classifyImage(File imageFile) async {
    try {
      final imageBytes = await imageFile.readAsBytes();
      final content = [
        Content.multi([
          TextPart('Classify this image into a single, short category name (e.g., "Cat", "Sunset", "Document", "Selfie"). Return ONLY the category name.'),
          DataPart('image/jpeg', imageBytes),
        ])
      ];

      final response = await _model.generateContent(content);
      return response.text?.trim();
    } catch (e) {
      print('AI Service Error: $e');
      return null;
    }
  }
}
