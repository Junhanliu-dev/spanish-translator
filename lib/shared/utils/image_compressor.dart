import 'dart:io';

import 'package:image/image.dart' as img;
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

/// Utility for compressing images before sending to the Vision API.
class ImageCompressor {
  ImageCompressor._();

  /// Compress an image file.
  ///
  /// Resizes so the longest dimension is at most [maxDimension] pixels
  /// and encodes as JPEG with the given [quality] (0-100).
  ///
  /// Returns the path to the compressed file in the temp directory.
  static Future<String> compress({
    required String imagePath,
    int maxDimension = 1024,
    int quality = 80,
  }) async {
    final file = File(imagePath);
    final bytes = await file.readAsBytes();

    var image = img.decodeImage(bytes);
    if (image == null) {
      throw Exception('Could not decode image at $imagePath');
    }

    // Resize if needed, preserving aspect ratio.
    if (image.width > maxDimension || image.height > maxDimension) {
      if (image.width >= image.height) {
        image = img.copyResize(image, width: maxDimension);
      } else {
        image = img.copyResize(image, height: maxDimension);
      }
    }

    // Encode as JPEG.
    final compressed = img.encodeJpg(image, quality: quality);

    // Write to temp directory.
    final tempDir = await getTemporaryDirectory();
    final outputPath = p.join(
      tempDir.path,
      'compressed_${DateTime.now().millisecondsSinceEpoch}.jpg',
    );
    final outputFile = File(outputPath);
    await outputFile.writeAsBytes(compressed);

    return outputPath;
  }
}
