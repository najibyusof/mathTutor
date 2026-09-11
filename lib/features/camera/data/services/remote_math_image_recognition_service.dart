import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_endpoints.dart';
import '../../../../core/errors/exceptions.dart';
import '../../../../models/recognition_result.dart';
import '../../domain/entities/math_image.dart';
import 'math_image_recognition_service.dart';

/// Uploads the compressed picture to the Laravel API for OCR.
class RemoteMathImageRecognitionService implements MathImageRecognitionService {
  const RemoteMathImageRecognitionService(this._client);

  final ApiClient _client;

  @override
  Future<RecognitionResult> recognize(MathImage image) async {
    final Map<String, dynamic> submitted = await _client.postMultipart(
      ApiEndpoints.recognitionImage,
      fieldName: 'image',
      bytes: image.bytes,
      filename: 'math-image.${image.mimeType.split('/').last}',
    );
    final Map<String, dynamic> data = _data(submitted);
    final String id = '${data['recognition_id'] ?? data['id']}'.trim();
    if (id == 'null' || id.isEmpty) {
      throw const ParsingException('The recognition response had no job id.');
    }
    return _poll(id);
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

  static Map<String, dynamic> _data(Map<String, dynamic> response) {
    final Object? data = response['data'];
    return data is Map<String, dynamic> ? data : response;
  }
}
