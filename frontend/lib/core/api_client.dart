import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Points at the local NestJS dev server by default. Override at build time with
/// --dart-define=API_BASE_URL=https://your-backend.onrender.com
const apiBaseUrl = String.fromEnvironment(
  'API_BASE_URL',
  defaultValue: 'http://localhost:3000',
);

class ApiClient {
  final Dio dio;
  String? token;

  ApiClient()
      : dio = Dio(
          BaseOptions(
            baseUrl: apiBaseUrl,
            // Render's free tier can take up to ~50s to wake a cold backend -
            // long enough to cover that without leaving a stuck request
            // hanging forever if the server is genuinely unreachable.
            connectTimeout: const Duration(seconds: 60),
            receiveTimeout: const Duration(seconds: 60),
          ),
        ) {
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          if (token != null) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          handler.next(options);
        },
      ),
    );
  }
}

/// Extracts a human-readable message from a NestJS error response
/// (`{ statusCode, message, error }`, where `message` may be a string or a
/// list of validation errors).
String apiErrorMessage(Object error) {
  if (error is DioException) {
    final data = error.response?.data;
    if (data is Map<String, dynamic> && data['message'] != null) {
      final message = data['message'];
      if (message is List) return message.join(', ');
      return message.toString();
    }
    return error.message ?? 'Something went wrong';
  }
  return error.toString();
}

final apiClientProvider = Provider<ApiClient>((ref) => ApiClient());
