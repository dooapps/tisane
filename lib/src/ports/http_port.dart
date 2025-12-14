import 'dart:typed_data';

/// Supported HTTP methods for TipTool adapters.
enum TTHttpMethod { get }

class TTHttpRequest {
  TTHttpRequest({
    required this.url,
    this.method = TTHttpMethod.get,
    Map<String, dynamic>? queryParameters,
    Map<String, String>? headers,
    Duration? connectTimeout,
    Duration? receiveTimeout,
  }) : queryParameters = queryParameters ?? <String, dynamic>{},
       headers = headers ?? <String, String>{},
       connectTimeout = connectTimeout ?? const Duration(seconds: 10),
       receiveTimeout = receiveTimeout ?? const Duration(seconds: 10);

  final String url;
  final TTHttpMethod method;
  final Map<String, dynamic> queryParameters;
  final Map<String, String> headers;
  final Duration connectTimeout;
  final Duration receiveTimeout;
}

class TTHttpResponse {
  TTHttpResponse({
    required this.statusCode,
    required this.data,
    Map<String, List<String>>? headers,
  }) : headers = headers ?? <String, List<String>>{};

  final int statusCode;
  final dynamic data;
  final Map<String, List<String>> headers;
}

class TTHttpException implements Exception {
  TTHttpException({
    this.statusCode,
    this.message,
    this.data,
    Map<String, List<String>>? headers,
  }) : headers = headers ?? <String, List<String>>{};

  final int? statusCode;
  final String? message;
  final dynamic data;
  final Map<String, List<String>> headers;

  @override
  String toString() =>
      'TTHttpException(statusCode: $statusCode, message: $message, data: $data)';
}

abstract class TTHttpClient {
  Future<TTHttpResponse> get(TTHttpRequest request);
}

/// Optional helper for adapters requiring raw payload access.
Uint8List? httpResponseBytes(dynamic data) {
  if (data is Uint8List) {
    return data;
  }
  return null;
}
