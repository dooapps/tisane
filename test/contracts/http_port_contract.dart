import 'package:test/test.dart';
import 'package:tisane/src/ports/http_port.dart';

/// Contract tests for TTHttpClient behaviour.
///
/// Requires two clients: one that returns success, and one that throws
/// TTHttpException with consistent mapping.
void defineHttpPortContract(
  String name,
  TTHttpClient Function() createSuccessClient,
  TTHttpClient Function() createErrorClient,
) {
  group('TTHttpClient contract: $name', () {
    test('successful GET returns status, data, headers', () async {
      final client = createSuccessClient();
      final res = await client.get(TTHttpRequest(url: 'https://example.org'));
      expect(res.statusCode, greaterThanOrEqualTo(200));
      expect(res.data, isNotNull);
      expect(res.headers, isA<Map<String, List<String>>>());
    });

    test('errors are mapped to TTHttpException', () async {
      final client = createErrorClient();
      expect(
        () async => client.get(TTHttpRequest(url: 'https://example.org/fail')),
        throwsA(isA<TTHttpException>()),
      );
    });
  });
}
