import 'dart:ui' as ui;
import 'dart:typed_data';

import '../../../../core/errors/exceptions.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_endpoints.dart';
import '../../domain/entities/handwriting_sample.dart';
import '../../../../models/recognition_result.dart';
import 'handwriting_recognition_service.dart';

/// Renders the normalized strokes at submission time because the API accepts
/// a canvas image, then polls the asynchronous recognition job.
class RemoteHandwritingRecognitionService
    implements HandwritingRecognitionService {
  const RemoteHandwritingRecognitionService(this._client);

  final ApiClient _client;

  @override
  Future<RecognitionResult> recognize(HandwritingSample sample) async {
    final List<int> png = await _renderPng(sample);
    final Map<String, dynamic> submitted = await _client.postMultipart(
      ApiEndpoints.recognitionHandwriting,
      fieldName: 'image',
      bytes: png,
      filename: 'handwriting.png',
    );
    final Map<String, dynamic> data = _data(submitted);
    final Object? rawId = data['recognition_id'] ?? data['id'];
    if (rawId == null) {
      throw const ParsingException('The recognition response had no job id.');
    }
    return _poll('$rawId');
  }

  Future<RecognitionResult> _poll(String id) async {
    for (int attempt = 0; attempt < 20; attempt++) {
      final Map<String, dynamic> response = await _client.get(
        ApiEndpoints.recognitionItem(id),
      );
      final Map<String, dynamic> data = _data(response);
      final String status =
          '${data['processing_status'] ?? data['status'] ?? ''}';
      if (status == 'completed') {
        return RecognitionResult.fromJson(<String, dynamic>{
          'expression': data['recognized_expression'],
          'confidence': data['confidence'],
          'alternatives': data['alternatives'],
        });
      }
      if (status == 'failed') {
        final Object? error = data['error'];
        throw ServerException(
          error is Map<String, dynamic>
              ? '${error['message'] ?? 'Recognition failed.'}'
              : 'Recognition failed.',
        );
      }
      await Future<void>.delayed(const Duration(milliseconds: 500));
    }
    throw const NetworkException(
      'Recognition is taking too long. Please try again.',
    );
  }

  Future<List<int>> _renderPng(HandwritingSample sample) async {
    final int width = sample.canvasSize.width.clamp(1, 1200).round();
    final int height = sample.canvasSize.height.clamp(1, 1200).round();
    final ui.PictureRecorder recorder = ui.PictureRecorder();
    final ui.Canvas canvas = ui.Canvas(recorder);
    canvas.drawColor(const ui.Color(0xFFFFFFFF), ui.BlendMode.src);
    final ui.Paint paint = ui.Paint()
      ..color = const ui.Color(0xFF111111)
      ..strokeWidth = 4
      ..strokeCap = ui.StrokeCap.round
      ..style = ui.PaintingStyle.stroke;
    for (final List<List<double>> stroke in sample.strokes) {
      final ui.Path path = ui.Path();
      for (int index = 0; index < stroke.length; index++) {
        final List<double> point = stroke[index];
        final double x = point[0] * width;
        final double y = point[1] * height;
        if (index == 0) {
          path.moveTo(x, y);
        } else {
          path.lineTo(x, y);
        }
      }
      canvas.drawPath(path, paint);
    }
    final ui.Image image = await recorder.endRecording().toImage(width, height);
    final ByteData? bytes = await image.toByteData(
      format: ui.ImageByteFormat.png,
    );
    image.dispose();
    if (bytes == null) {
      throw const DeviceUnavailableException('Could not render handwriting.');
    }
    return bytes.buffer.asUint8List();
  }

  static Map<String, dynamic> _data(Map<String, dynamic> response) {
    final Object? data = response['data'];
    return data is Map<String, dynamic> ? data : response;
  }
}
