import 'package:asatex_compensation/utils/logger.dart';
import 'package:dio/dio.dart';

class ApiService {
  // Singleton pattern
  ApiService._privateConstructor();
  static final ApiService _instance = ApiService._privateConstructor();
  factory ApiService() {
    return _instance;
  }

  final Dio _dio = Dio(
    BaseOptions(
      baseUrl: 'https://jsonplaceholder.typicode.com',
      connectTimeout: const Duration(milliseconds: 5000),
      receiveTimeout: const Duration(milliseconds: 3000),
    ),
  );

  Future<Response> get(String path, {Map<String, dynamic>? queryParameters}) async {
    try {
      return await _dio.get(path, queryParameters: queryParameters);
    } on DioException catch (e) {
      // The request was made and the server responded with a status code
      // that falls out of the range of 2xx and is also not 304.
      if (e.response != null) {
        logger.e(
          'Dio error!',
          error: {
            'data': e.response?.data,
            'headers': e.response?.headers,
            'requestOptions': e.response?.requestOptions,
          },
        );
      } else {
        // Something happened in setting up or sending the request that triggered an Error
        logger.e(
          'Dio error: sending request failed.',
          error: {
            'requestOptions': e.requestOptions,
            'message': e.message,
          },
        );
      }
      rethrow;
    }
  }
} 