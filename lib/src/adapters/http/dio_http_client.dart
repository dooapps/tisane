import 'package:dio/dio.dart';

import '../../ports/http_port.dart';
import '../../ports/logger_port.dart';

class DioHttpClient implements TTHttpClient {
  DioHttpClient({Dio? dio, TTLogger? logger})
    : _dio = dio ?? Dio(_defaultBaseOptions),
      _logger = logger ?? createDefaultLogger() {
    if (dio == null) {
      _dio.interceptors.add(
        LogInterceptor(
          request: true,
          requestBody: true,
          responseBody: true,
          error: true,
        ),
      );
    }
  }

  final Dio _dio;
  final TTLogger _logger;

  static final BaseOptions _defaultBaseOptions = BaseOptions(
    connectTimeout: const Duration(seconds: 10),
    receiveTimeout: const Duration(seconds: 10),
  );

  @override
  Future<TTHttpResponse> get(TTHttpRequest request) async {
    final previousOptions = _dio.options;
    _dio.options = previousOptions.copyWith(
      connectTimeout: request.connectTimeout,
      receiveTimeout: request.receiveTimeout,
    );

    try {
      final response = await _dio.get(
        request.url,
        queryParameters: request.queryParameters.isEmpty
            ? null
            : request.queryParameters,
        options: Options(
          headers: request.headers,
          responseType: ResponseType.plain,
        ),
      );

      return TTHttpResponse(
        statusCode: response.statusCode ?? 0,
        data: response.data,
        headers: response.headers.map.map(
          (key, value) => MapEntry(key, List<String>.from(value)),
        ),
      );
    } on DioException catch (error) {
      final status = error.response?.statusCode;
      final data = error.response?.data;
      final headers =
          error.response?.headers.map.map(
            (key, value) => MapEntry(key, List<String>.from(value)),
          ) ??
          <String, List<String>>{};

      throw TTHttpException(
        statusCode: status,
        message: error.message,
        data: data,
        headers: headers,
      );
    } catch (error, stackTrace) {
      _logger.error(
        'Unexpected HTTP client error',
        error: error,
        stackTrace: stackTrace,
      );
      rethrow;
    } finally {
      _dio.options = previousOptions;
    }
  }
}

TTHttpClient createDefaultHttpClient({TTLogger? logger}) =>
    DioHttpClient(logger: logger);
