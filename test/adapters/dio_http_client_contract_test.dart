import 'dart:async';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:tisane/src/adapters/http/dio_http_client.dart';
import 'package:tisane/src/ports/http_port.dart';

import '../contracts/http_port_contract.dart';

class _SuccessAdapter implements HttpClientAdapter {
  @override
  void close({bool force = false}) {}

  @override
  Future<ResponseBody> fetch(RequestOptions options,
      Stream<List<int>>? requestStream, Future? cancelFuture) async {
    return ResponseBody.fromBytes(Uint8List.fromList('ok'.codeUnits), 200,
        headers: {
          Headers.contentTypeHeader: ['text/plain']
        });
  }
}

class _ErrorAdapter implements HttpClientAdapter {
  @override
  void close({bool force = false}) {}

  @override
  Future<ResponseBody> fetch(RequestOptions options,
      Stream<List<int>>? requestStream, Future? cancelFuture) async {
    throw DioException(
      requestOptions: options,
      response:
          Response(requestOptions: options, statusCode: 500, data: 'fail'),
      message: 'server error',
      type: DioExceptionType.badResponse,
    );
  }
}

void main() {
  TTHttpClient clientWithAdapter(HttpClientAdapter adapter) {
    final dio = Dio();
    dio.httpClientAdapter = adapter;
    return DioHttpClient(dio: dio);
  }

  defineHttpPortContract(
    'DioHttpClient',
    () => clientWithAdapter(_SuccessAdapter()),
    () => clientWithAdapter(_ErrorAdapter()),
  );
}
