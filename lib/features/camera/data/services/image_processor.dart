import 'dart:typed_data';

import 'package:image/image.dart' as img;

import '../../../../core/errors/exceptions.dart';
import '../../../../core/utils/app_logger.dart';
import '../../domain/entities/image_crop.dart';
import '../../domain/entities/math_image.dart';

/// Decodes, crops and compresses pictures before they leave the device.
abstract interface class ImageProcessor {
  /// Reads the picture's dimensions and rejects undecodable data.
  MathImage decode(Uint8List bytes, MathImageSource source);

  /// Applies [crop] and shrinks the result to the upload budget.
  MathImage prepareForUpload(MathImage image, {ImageCrop crop = ImageCrop.full});
}

/// Pure-Dart implementation (`package:image`), so it also runs in tests.
class DartImageProcessor implements ImageProcessor {
  const DartImageProcessor();

  /// Longest edge kept after compression; enough for OCR, small to upload.
  static const int maxDimension = 1600;

  /// Upload budget; quality is stepped down until the bytes fit.
  static const int maxUploadBytes = 900 * 1024;

  static const List<int> _qualitySteps = <int>[85, 70, 55, 40];

  @override
  MathImage decode(Uint8List bytes, MathImageSource source) {
    if (bytes.isEmpty) {
      throw const InvalidImageException('That picture appears to be empty.');
    }

    final img.Image? decoded = _decode(bytes);
    if (decoded == null || decoded.width < 8 || decoded.height < 8) {
      throw const InvalidImageException(
        'That file is not a picture we can read.',
      );
    }

    return MathImage(
      bytes: bytes,
      width: decoded.width,
      height: decoded.height,
      source: source,
    );
  }

  @override
  MathImage prepareForUpload(
    MathImage image, {
    ImageCrop crop = ImageCrop.full,
  }) {
    final img.Image? decoded = _decode(image.bytes);
    if (decoded == null) {
      throw const InvalidImageException(
        'That file is not a picture we can read.',
      );
    }

    img.Image working = decoded;

    if (!crop.isFull) {
      final int x = (crop.left * decoded.width).round();
      final int y = (crop.top * decoded.height).round();
      final int width = (crop.width * decoded.width).round().clamp(
        1,
        decoded.width - x,
      );
      final int height = (crop.height * decoded.height).round().clamp(
        1,
        decoded.height - y,
      );
      working = img.copyCrop(
        working,
        x: x,
        y: y,
        width: width,
        height: height,
      );
    }

    final int longestEdge = working.width > working.height
        ? working.width
        : working.height;
    if (longestEdge > maxDimension) {
      working = working.width >= working.height
          ? img.copyResize(working, width: maxDimension)
          : img.copyResize(working, height: maxDimension);
    }

    Uint8List encoded = img.encodeJpg(working, quality: _qualitySteps.first);
    for (final int quality in _qualitySteps.skip(1)) {
      if (encoded.lengthInBytes <= maxUploadBytes) {
        break;
      }
      encoded = img.encodeJpg(working, quality: quality);
    }

    AppLogger.debug(
      'Prepared image ${working.width}x${working.height}, '
      '${(encoded.lengthInBytes / 1024).toStringAsFixed(0)} KB',
    );

    return image.copyWith(
      bytes: encoded,
      width: working.width,
      height: working.height,
      mimeType: 'image/jpeg',
    );
  }

  /// Corrupt files make the decoder throw rather than return `null`.
  img.Image? _decode(Uint8List bytes) {
    try {
      return img.decodeImage(bytes);
    } catch (_) {
      return null;
    }
  }
}
