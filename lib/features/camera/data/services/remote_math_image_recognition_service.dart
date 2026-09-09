import 'dart:convert';

import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_endpoints.dart';
import '../../../../models/recognition_result.dart';
import '../../domain/entities/math_image.dart';
import 'math_image_recognition_service.dart';

/// Uploads the compressed picture to the Laravel API for OCR.
class RemoteMathImageRecognitionService implements MathImageRecognitionService {
  const RemoteMathImageRecognitionService(this._client);

  final ApiClient _client;

  @override
  Future<RecognitionResult> recognize(MathImage image) async {
    final Map<String, dynamic> json = await _client.post(
      ApiEndpoints.solveImage,
      body: <String, dynamic>{
        'mime_type': image.mimeType,
        'width': image.width,
        'height': image.height,
        'image': base64Encode(image.bytes),
      },
    );
    final Map<String, dynamic> payload =
        json['data'] as Map<String, dynamic>? ?? json;
    return RecognitionResult.fromJson(payload);
  }
}
