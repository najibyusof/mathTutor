import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_endpoints.dart';
import '../../domain/entities/handwriting_sample.dart';
import '../../../../models/recognition_result.dart';
import 'handwriting_recognition_service.dart';

/// Sends the normalized strokes to the Laravel API.
///
/// Only vector points travel over the wire; no bitmap is produced or stored.
class RemoteHandwritingRecognitionService
    implements HandwritingRecognitionService {
  const RemoteHandwritingRecognitionService(this._client);

  final ApiClient _client;

  @override
  Future<RecognitionResult> recognize(HandwritingSample sample) async {
    final Map<String, dynamic> json = await _client.post(
      ApiEndpoints.solveHandwriting,
      body: sample.toJson(),
    );
    final Map<String, dynamic> payload =
        json['data'] as Map<String, dynamic>? ?? json;
    return RecognitionResult.fromJson(payload);
  }
}
