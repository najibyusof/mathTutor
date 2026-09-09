import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../core/errors/exceptions.dart';
import '../../domain/entities/math_image.dart';

/// Supplies pictures to the capture flow.
///
/// Abstracted so the `image_picker` implementation can be swapped for a live
/// in-app camera preview without touching the UI.
abstract interface class ImageSourceService {
  /// Opens the camera; returns `null` when the user backs out.
  Future<Uint8List?> capturePhoto();

  /// Opens the system gallery; returns `null` when the user backs out.
  Future<Uint8List?> pickFromGallery();
}

/// `image_picker` implementation.
///
/// The plugin asks the OS for camera/photo permission and reports refusal and
/// missing hardware through platform errors, which are translated here.
class ImagePickerSourceService implements ImageSourceService {
  ImagePickerSourceService({ImagePicker? picker})
    : _picker = picker ?? ImagePicker();

  final ImagePicker _picker;

  /// First-pass downscale so a 12 MP photo never reaches memory at full size.
  static const double _maxPickerDimension = 2400;
  static const int _pickerQuality = 90;

  @override
  Future<Uint8List?> capturePhoto() =>
      _pick(ImageSource.camera, MathImageSource.camera);

  @override
  Future<Uint8List?> pickFromGallery() =>
      _pick(ImageSource.gallery, MathImageSource.gallery);

  Future<Uint8List?> _pick(ImageSource source, MathImageSource kind) async {
    try {
      final XFile? file = await _picker.pickImage(
        source: source,
        maxWidth: _maxPickerDimension,
        maxHeight: _maxPickerDimension,
        imageQuality: _pickerQuality,
        preferredCameraDevice: CameraDevice.rear,
      );
      return file == null ? null : await file.readAsBytes();
    } on PlatformException catch (error) {
      throw _translate(error, kind);
    }
  }

  AppException _translate(PlatformException error, MathImageSource kind) {
    return switch (error.code) {
      'camera_access_denied' => const PermissionDeniedException(
        'MathTutor needs camera access to scan a question. '
        'Enable it in Settings.',
      ),
      'photo_access_denied' => const PermissionDeniedException(
        'MathTutor needs photo access to pick a picture. '
        'Enable it in Settings.',
      ),
      'no_available_camera' => const DeviceUnavailableException(
        'No camera is available on this device.',
      ),
      'invalid_image' || 'invalid_source' => const InvalidImageException(
        'That file is not a picture we can read.',
      ),
      _ => DeviceUnavailableException(
        kind == MathImageSource.camera
            ? 'The camera could not be opened. Please try again.'
            : 'The gallery could not be opened. Please try again.',
      ),
    };
  }
}
