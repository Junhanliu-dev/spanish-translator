import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

/// Utility for compressing images before sending to the Vision API.
///
/// Uses the platform-native image codecs (libjpeg on Android/iOS) via
/// `flutter_image_compress`. The plugin itself dispatches work off the UI
/// isolate over its platform channel, so the UI thread stays responsive while
/// a large camera image is being decoded, resized, and re-encoded.
class ImageCompressor {
  ImageCompressor._();

  /// Compress an image file.
  ///
  /// The output is bounded by [maxDimension] on its shortest side (aspect
  /// ratio preserved) and encoded as JPEG at [quality] (0-100). Picks are
  /// typically ~1024×768 or ~768×1024 after compression.
  ///
  /// Returns the path to the compressed file in the temp directory.
  static Future<String> compress({
    required String imagePath,
    int maxDimension = 1024,
    int quality = 80,
  }) async {
    final tempDir = await getTemporaryDirectory();
    final outputPath = p.join(
      tempDir.path,
      'compressed_${DateTime.now().millisecondsSinceEpoch}.jpg',
    );

    final result = await FlutterImageCompress.compressAndGetFile(
      imagePath,
      outputPath,
      quality: quality,
      minWidth: maxDimension,
      minHeight: maxDimension,
      keepExif: false,
      format: CompressFormat.jpeg,
    );

    if (result == null) {
      throw Exception('Could not compress image at $imagePath');
    }

    return result.path;
  }
}
