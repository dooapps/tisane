import 'dart:async';

import 'package:test/test.dart';
import 'package:tisane/src/data_collector.dart';
import 'package:tisane/src/ports/http_port.dart';
import 'package:tisane/src/ports/logger_port.dart';

class FakeHttpClient implements TTHttpClient {
  FakeHttpClient({this.response, this.exception, this.onGet});

  TTHttpResponse? response;
  TTHttpException? exception;
  void Function(TTHttpRequest request)? onGet;
  final List<TTHttpRequest> requests = [];

  @override
  Future<TTHttpResponse> get(TTHttpRequest request) async {
    requests.add(request);
    onGet?.call(request);
    if (exception != null) {
      throw exception!;
    }
    if (response != null) {
      return response!;
    }
    throw StateError('No response configured');
  }
}

class RecordingLogger implements TTLogger {
  final List<String> messages = [];

  @override
  void debug(String message, {Map<String, Object?>? context}) {
    messages.add('DEBUG:$message');
  }

  @override
  void error(String message,
      {Map<String, Object?>? context, Object? error, StackTrace? stackTrace}) {
    messages.add('ERROR:$message:${error ?? ''}');
  }

  @override
  void info(String message, {Map<String, Object?>? context}) {
    messages.add('INFO:$message');
  }

  @override
  void warn(String message,
      {Map<String, Object?>? context, Object? error, StackTrace? stackTrace}) {
    messages.add('WARN:$message:${error ?? ''}');
  }
}

void main() {
  group('DataCollector with injected HTTP client', () {
    test('returns decoded JSON payload on success', () async {
      final httpClient = FakeHttpClient(
        response:
            TTHttpResponse(statusCode: 200, data: '{"data": [{"price": 42}]}'),
      );
      final logger = RecordingLogger();

      final result = await DataCollector.fetchStockData(
        'public',
        'https://collector.test/endpoint',
        {'symbol': 'XYZ'},
        {'header': 'value'},
        {'price': 'price'},
        httpClient: httpClient,
        logger: logger,
        logResponses: true,
      );

      expect(result['statusCode'], equals(200));
      expect(result['success'], isTrue);
      expect(result['body'], isA<Map<String, dynamic>>());
      expect(
          httpClient.requests.single.queryParameters['symbol'], equals('XYZ'));
      expect(
          logger.messages.any(
              (msg) => msg.startsWith('DEBUG:Collector response received')),
          isTrue);
    });

    test('maps TTHttpException to error payload', () async {
      final httpClient = FakeHttpClient(
        exception: TTHttpException(statusCode: 401, message: 'unauthorized'),
      );
      final logger = RecordingLogger();

      final result = await DataCollector.fetchStockData(
        'public',
        'https://collector.test/endpoint',
        const {},
        const {},
        const {},
        httpClient: httpClient,
        logger: logger,
        logResponses: false,
      );

      expect(result['statusCode'], equals(401));
      expect(result['success'], isFalse);
      expect(result['error'], equals('unauthorized'));
      expect(
        logger.messages
            .any((msg) => msg.startsWith('WARN:Collector HTTP error')),
        isTrue,
      );
    });

    test('captures unexpected errors', () async {
      final httpClient = FakeHttpClient(onGet: (_) => throw StateError('boom'));
      final logger = RecordingLogger();

      final result = await DataCollector.fetchStockData(
        'public',
        'https://collector.test/endpoint',
        const {},
        const {},
        const {},
        httpClient: httpClient,
        logger: logger,
        logResponses: false,
      );

      expect(result['statusCode'], equals(500));
      expect(result['success'], isFalse);
      expect(result['error'], equals('Bad state: boom'));
      expect(
        logger.messages
            .any((msg) => msg.startsWith('ERROR:Unexpected collector error')),
        isTrue,
      );
    });
  });
}
