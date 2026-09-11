import 'package:flutter_test/flutter_test.dart';
import 'package:mathtutor/core/errors/failure_messages.dart';
import 'package:mathtutor/core/errors/failures.dart';
import 'package:mathtutor/core/utils/app_logger.dart';

void main() {
  test('redacts credentials, tokens and secrets from development logs', () {
    final String safe = AppLogger.sanitize(
      'password=secret token=abc123 Authorization: Bearer xyz '
      'api_key=private',
    );

    expect(safe, isNot(contains('secret')));
    expect(safe, isNot(contains('abc123')));
    expect(safe, isNot(contains('xyz')));
    expect(safe, isNot(contains('private')));
    expect(safe, contains('password=[REDACTED]'));
  });

  test('uses stable friendly messages for expected failures', () {
    expect(
      friendlyMessage(const NetworkFailure('SocketException')),
      contains('Unable to connect to the server'),
    );
    expect(
      friendlyMessage(const MathParserFailure('ParserException')),
      contains('couldn\'t understand this equation'),
    );
    expect(
      friendlyMessage(const AIExplanationFailure('provider unavailable')),
      contains('explanation service is unavailable'),
    );
  });
}
