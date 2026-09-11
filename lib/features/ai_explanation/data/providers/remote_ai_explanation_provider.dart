import '../../../../core/errors/exceptions.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_endpoints.dart';
import '../../domain/models/ai_explanation_models.dart';
import '../../domain/services/ai_explanation_service.dart';

/// Remote provider that delegates model access to the Laravel backend.
///
/// No provider key is accepted or stored by this class. Authentication and
/// secret provider credentials remain server-side.
class RemoteAIExplanationProvider implements AIExplanationProvider {
  const RemoteAIExplanationProvider(this._client);

  final ApiClient _client;

  @override
  Future<AIExplanation> generate(AIExplanationRequest request) async {
    final Map<String, dynamic> payload = _payload(
      await _post(request, ApiEndpoints.solutionExplanation),
    );
    return AIExplanation.fromJson(<String, dynamic>{
      'explanation': payload['content'],
      'concept': _conceptText(payload['concepts']),
      'hints': const <String>[],
      'simplified_explanation': null,
    });
  }

  @override
  Future<String> generateHint(AIExplanationRequest request) async {
    final Map<String, dynamic> payload = _payload(
      await _post(request, ApiEndpoints.solutionHint),
    );
    return _requiredString(payload, 'content');
  }

  @override
  Future<String> identifyConcept(AIExplanationRequest request) async {
    final Map<String, dynamic> payload = _payload(
      await _post(request, ApiEndpoints.solutionExplanation),
    );
    return _conceptText(payload['concepts']) ??
        _requiredString(payload, 'content');
  }

  @override
  Future<String> simplify(AIExplanationRequest request) async {
    final Map<String, dynamic> payload = _payload(
      await _post(request, ApiEndpoints.solutionExplanation),
    );
    return _requiredString(payload, 'content');
  }

  Future<Map<String, dynamic>> _post(
    AIExplanationRequest request,
    String Function(String) endpoint,
  ) {
    final int? solutionId = request.solution.id;
    if (solutionId == null) {
      throw const ParsingException(
        'The solution has not been saved on the server yet.',
      );
    }
    return _client.post(
      endpoint('$solutionId'),
      authenticated: true,
      body: <String, dynamic>{'difficulty': request.difficulty.name},
    );
  }

  Map<String, dynamic> _payload(Map<String, dynamic> json) {
    final Object? data = json['data'];
    if (data is! Map<String, dynamic>) {
      throw const ParsingException('The AI response was malformed.');
    }
    return data;
  }

  String _requiredString(Map<String, dynamic> json, String key) {
    final String? value = json[key] as String?;
    if (value == null || value.trim().isEmpty) {
      throw const ParsingException('The AI response was missing a text field.');
    }
    return value.trim();
  }

  String? _conceptText(Object? concepts) {
    if (concepts is List) {
      final List<String> values = concepts.whereType<String>().toList();
      return values.isEmpty ? null : values.join(', ');
    }
    return concepts is String && concepts.trim().isNotEmpty ? concepts : null;
  }
}
