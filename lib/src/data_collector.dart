import 'dart:convert';

import '_internal_utils.dart';
import 'adapters/http/dio_http_client.dart';
import 'ports/http_port.dart';
import 'ports/logger_port.dart';

class DataCollector {
  static Future<Map<String, dynamic>> fetchStockData(
    String publicKey,
    String urlCollector,
    Map<String, dynamic> params,
    Map<String, String> headers,
    Map<String, String> fieldMappings, {
    TTHttpClient? httpClient,
    TTLogger? logger,
    Duration? connectTimeout,
    Duration? receiveTimeout,
    bool logRequests = true,
    bool logErrors = true,
    bool logResponses = false,
  }) async {
    final effectiveLogger = logger ?? createDefaultLogger();
    final client =
        httpClient ?? createDefaultHttpClient(logger: effectiveLogger);
    final queryString = buildQueryParams(params);
    final requestUrl = '$urlCollector$queryString';

    if (logRequests) {
      effectiveLogger
          .debug('Fetching data from collector', context: {'url': requestUrl});
    }

    final request = TTHttpRequest(
      url: urlCollector,
      queryParameters: params,
      headers: headers,
      connectTimeout: connectTimeout ?? const Duration(seconds: 10),
      receiveTimeout: receiveTimeout ?? const Duration(seconds: 10),
    );

    try {
      final response = await client.get(request);
      final body = _parseResponse(response.data);

      if (logResponses) {
        effectiveLogger.debug('Collector response received', context: {
          'url': requestUrl,
          'statusCode': response.statusCode,
        });
      }

      return {
        'statusCode': response.statusCode,
        'body': body,
        'success': response.statusCode >= 200 && response.statusCode < 300,
      };
    } on TTHttpException catch (error) {
      if (logErrors) {
        effectiveLogger.warn('Collector HTTP error',
            context: {
              'url': requestUrl,
              'statusCode': error.statusCode,
            },
            error: error.message);
      }

      return {
        'statusCode': error.statusCode ?? 500,
        'error': error.message,
        'success': false,
      };
    } catch (error, stackTrace) {
      effectiveLogger.error('Unexpected collector error',
          context: {'url': requestUrl}, error: error, stackTrace: stackTrace);
      return {
        'statusCode': 500,
        'error': error.toString(),
        'success': false,
      };
    }
  }

  static dynamic _parseResponse(dynamic data) {
    try {
      if (data is String) {
        return jsonDecode(data);
      }
      return data;
    } catch (_) {
      return {'error': 'Invalid JSON response'};
    }
  }
}
