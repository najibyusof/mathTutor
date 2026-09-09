import 'dart:typed_data';
import 'dart:ui';

/// Where a picture came from.
enum MathImageSource { camera, gallery }

/// An in-memory picture of a math question.
///
/// Bytes are kept only for the duration of the capture/recognition flow; the
/// app never writes them to disk.
class MathImage {
  const MathImage({
    required this.bytes,
    required this.width,
    required this.height,
    required this.source,
    this.mimeType = 'image/jpeg',
  });

  final Uint8List bytes;
  final int width;
  final int height;
  final MathImageSource source;
  final String mimeType;

  int get sizeBytes => bytes.lengthInBytes;

  double get sizeKb => sizeBytes / 1024;

  Size get size => Size(width.toDouble(), height.toDouble());

  double get aspectRatio => height == 0 ? 1 : width / height;

  MathImage copyWith({
    Uint8List? bytes,
    int? width,
    int? height,
    String? mimeType,
  }) => MathImage(
    bytes: bytes ?? this.bytes,
    width: width ?? this.width,
    height: height ?? this.height,
    source: source,
    mimeType: mimeType ?? this.mimeType,
  );
}
