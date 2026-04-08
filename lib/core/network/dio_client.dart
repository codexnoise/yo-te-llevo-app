import 'package:dio/dio.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

import '../constants/mapbox_constants.dart';

class DioClient {
  late final Dio _dio;

  DioClient() {
    _dio = Dio(
      BaseOptions(
        baseUrl: MapboxConstants.baseUrl,
        connectTimeout: const Duration(
          milliseconds: MapboxConstants.connectionTimeout,
        ),
        receiveTimeout: const Duration(
          milliseconds: MapboxConstants.receiveTimeout,
        ),
        queryParameters: {
          'access_token': dotenv.env['MAPBOX_ACCESS_TOKEN'] ?? '',
        },
      ),
    );

    _dio.interceptors.add(
      LogInterceptor(requestBody: true, responseBody: true),
    );
  }

  Dio get dio => _dio;

  Future<Response> get(
    String path, {
    Map<String, dynamic>? queryParameters,
  }) async {
    return _dio.get(path, queryParameters: queryParameters);
  }
}
