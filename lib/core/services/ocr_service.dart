import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

/// Thin wrapper around Google ML Kit text recognition.
/// Single responsibility: image path → raw OCR text.
class OcrService {
  final TextRecognizer _recognizer = TextRecognizer();

  /// Extract all text from a single image file.
  Future<String> extractText(String imagePath) async {
    final inputImage = InputImage.fromFilePath(imagePath);
    final recognized = await _recognizer.processImage(inputImage);
    return recognized.text;
  }

  /// Process multiple images and return (path, text) pairs.
  /// Calls [onProgress] after each image completes.
  /// Individual failures return empty text (not throws) — caller handles.
  Future<List<({String path, String text})>> extractBatch(
    List<String> imagePaths, {
    void Function(int completed, int total)? onProgress,
  }) async {
    final results = <({String path, String text})>[];
    for (var i = 0; i < imagePaths.length; i++) {
      try {
        final text = await extractText(imagePaths[i]);
        results.add((path: imagePaths[i], text: text));
      } catch (_) {
        results.add((path: imagePaths[i], text: ''));
      }
      onProgress?.call(i + 1, imagePaths.length);
    }
    return results;
  }

  void dispose() => _recognizer.close();
}
