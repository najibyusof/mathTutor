import 'package:flutter/foundation.dart';

import '../../../../core/errors/failure_messages.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/network/result.dart';
import '../../../../models/recognition_result.dart';
import '../../data/services/image_processor.dart';
import '../../data/services/image_source_service.dart';
import '../../domain/entities/image_crop.dart';
import '../../domain/entities/math_image.dart';
import '../../domain/repositories/math_image_repository.dart';

/// Steps of the scan workflow.
enum CameraStage { idle, loading, preview, recognizing, result }

/// Drives capture → preview → crop → confirm → recognize.
class CameraMathController extends ChangeNotifier {
  CameraMathController({
    required MathImageRepository repository,
    required ImageSourceService imageSource,
    ImageProcessor processor = const DartImageProcessor(),
  }) : _repository = repository,
       _imageSource = imageSource,
       _processor = processor;

  final MathImageRepository _repository;
  final ImageSourceService _imageSource;
  final ImageProcessor _processor;

  CameraStage _stage = CameraStage.idle;
  MathImage? _image;
  MathImage? _prepared;
  ImageCrop _crop = ImageCrop.full;
  RecognitionResult? _result;
  String? _errorMessage;

  CameraStage get stage => _stage;
  MathImage? get image => _image;

  /// Cropped and compressed bytes actually sent for recognition.
  MathImage? get preparedImage => _prepared;
  ImageCrop get crop => _crop;
  RecognitionResult? get result => _result;
  String? get errorMessage => _errorMessage;
  bool get isBusy =>
      _stage == CameraStage.loading || _stage == CameraStage.recognizing;
  bool get hasImage => _image != null;

  Future<void> captureFromCamera() =>
      _load(_imageSource.capturePhoto, MathImageSource.camera);

  Future<void> pickFromGallery() =>
      _load(_imageSource.pickFromGallery, MathImageSource.gallery);

  void setCrop(ImageCrop crop) {
    _crop = crop;
    notifyListeners();
  }

  void resetCrop() => setCrop(ImageCrop.full);

  /// Discards the picture and returns to the capture options.
  void retake() {
    _image = null;
    _prepared = null;
    _crop = ImageCrop.full;
    _result = null;
    _errorMessage = null;
    _stage = CameraStage.idle;
    notifyListeners();
  }

  /// Applies the crop, compresses, and sends the picture for recognition.
  Future<bool> confirmAndRecognize() async {
    final MathImage? original = _image;
    if (original == null || isBusy) {
      return false;
    }

    _stage = CameraStage.recognizing;
    _errorMessage = null;
    _result = null;
    notifyListeners();

    final MathImage prepared;
    try {
      prepared = _processor.prepareForUpload(original, crop: _crop);
    } catch (error) {
      return _fail(mapExceptionToFailure(error), CameraStage.preview);
    }
    _prepared = prepared;

    final Result<RecognitionResult> result = await _repository
        .recognizeMathImage(prepared);

    return result.when<bool>(
      onSuccess: (RecognitionResult value) {
        _result = value;
        _stage = CameraStage.result;
        notifyListeners();
        return true;
      },
      onFailure: (Failure failure) => _fail(failure, CameraStage.preview),
    );
  }

  void dismissResult() {
    if (_result == null && _errorMessage == null) {
      return;
    }
    _result = null;
    _errorMessage = null;
    _stage = _image == null ? CameraStage.idle : CameraStage.preview;
    notifyListeners();
  }

  Future<void> _load(
    Future<Uint8List?> Function() pick,
    MathImageSource source,
  ) async {
    if (isBusy) {
      return;
    }

    _stage = CameraStage.loading;
    _errorMessage = null;
    notifyListeners();

    try {
      final Uint8List? bytes = await pick();
      if (bytes == null) {
        _stage = _image == null ? CameraStage.idle : CameraStage.preview;
        notifyListeners();
        return;
      }

      _image = _processor.decode(bytes, source);
      _prepared = null;
      _crop = ImageCrop.full;
      _result = null;
      _stage = CameraStage.preview;
      notifyListeners();
    } catch (error) {
      _fail(mapExceptionToFailure(error), CameraStage.idle);
    }
  }

  bool _fail(Failure failure, CameraStage stage) {
    _errorMessage = friendlyMessage(failure);
    _stage = stage;
    notifyListeners();
    return false;
  }
}
