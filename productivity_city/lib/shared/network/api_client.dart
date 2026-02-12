import 'package:dio/dio.dart';
import 'package:productivity_city/shared/network/api_exceptions.dart';
import 'package:productivity_city/shared/session/session_storage.dart';

class ApiClient {
  ApiClient({required String baseUrl, required SessionStorage storage})
    : _storage = storage,
      _dio = Dio(
        BaseOptions(
          baseUrl: '${baseUrl.replaceFirst(RegExp(r'/$'), '')}/api',
          connectTimeout: const Duration(seconds: 10),
          receiveTimeout: const Duration(seconds: 20),
          sendTimeout: const Duration(seconds: 20),
          responseType: ResponseType.json,
        ),
      ) {
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest:
            (RequestOptions options, RequestInterceptorHandler handler) async {
              final String? token = await _storage.readToken();
              if (token != null && token.isNotEmpty) {
                options.headers['Authorization'] = 'Bearer $token';
              }
              handler.next(options);
            },
        onError: (DioException error, ErrorInterceptorHandler handler) async {
          final ApiException mapped = await _mapException(error);
          handler.reject(
            DioException(
              requestOptions: error.requestOptions,
              response: error.response,
              type: error.type,
              error: mapped,
            ),
          );
        },
      ),
    );
  }

  final Dio _dio;
  final SessionStorage _storage;

  Future<dynamic> get(
    String path, {
    Map<String, dynamic>? queryParameters,
  }) async {
    try {
      final Response<dynamic> response = await _dio.get<dynamic>(
        path,
        queryParameters: queryParameters,
      );
      return response.data;
    } on DioException catch (error) {
      throw _unwrap(error);
    }
  }

  Future<dynamic> post(
    String path, {
    Object? data,
    Map<String, dynamic>? queryParameters,
  }) async {
    try {
      final Response<dynamic> response = await _dio.post<dynamic>(
        path,
        data: data,
        queryParameters: queryParameters,
      );
      return response.data;
    } on DioException catch (error) {
      throw _unwrap(error);
    }
  }

  Future<dynamic> postForm(
    String path, {
    required Map<String, dynamic> data,
  }) async {
    try {
      final Response<dynamic> response = await _dio.post<dynamic>(
        path,
        data: data,
        options: Options(contentType: Headers.formUrlEncodedContentType),
      );
      return response.data;
    } on DioException catch (error) {
      throw _unwrap(error);
    }
  }

  Future<dynamic> patch(
    String path, {
    Object? data,
    Map<String, dynamic>? queryParameters,
  }) async {
    try {
      final Response<dynamic> response = await _dio.patch<dynamic>(
        path,
        data: data,
        queryParameters: queryParameters,
      );
      return response.data;
    } on DioException catch (error) {
      throw _unwrap(error);
    }
  }

  Future<dynamic> delete(String path) async {
    try {
      final Response<dynamic> response = await _dio.delete<dynamic>(path);
      return response.data;
    } on DioException catch (error) {
      throw _unwrap(error);
    }
  }

  ApiException _unwrap(DioException error) {
    final Object? payload = error.error;
    if (payload is ApiException) {
      return payload;
    }
    return ApiException(
      message: error.message ?? 'Unexpected network error.',
      payload: payload,
    );
  }

  Future<ApiException> _mapException(DioException error) async {
    final int? statusCode = error.response?.statusCode;
    final dynamic data = error.response?.data;
    final String message = _extractMessage(data, error);

    if (statusCode == 401) {
      await _storage.clearToken();
      return UnauthorizedException(message: message, payload: data);
    }

    return ApiException(
      message: message,
      statusCode: statusCode,
      payload: data,
    );
  }

  String _extractMessage(dynamic data, DioException error) {
    if (data is Map<String, dynamic>) {
      final dynamic detail = data['detail'];
      if (detail is String && detail.isNotEmpty) {
        return detail;
      }
      if (detail is List) {
        final String? validationMessage = _extractValidationMessage(detail);
        if (validationMessage != null) {
          return validationMessage;
        }
      }
    }
    if (data is String && data.isNotEmpty) {
      return data;
    }
    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return 'Request timed out. Please try again.';
      case DioExceptionType.connectionError:
        return 'Unable to reach the server. Please check your connection.';
      default:
        return error.message ?? 'Unexpected network error.';
    }
  }

  String? _extractValidationMessage(List<dynamic> detail) {
    for (final dynamic item in detail) {
      if (item is! Map) {
        continue;
      }

      final Map<String, dynamic> issue = Map<String, dynamic>.from(item);
      final List<dynamic> location = issue['loc'] is List
          ? List<dynamic>.from(issue['loc'] as List)
          : const <dynamic>[];
      final String field = location.isNotEmpty ? '${location.last}' : '';
      final String message = (issue['msg'] as String?)?.trim() ?? '';
      final Map<String, dynamic> ctx = issue['ctx'] is Map
          ? Map<String, dynamic>.from(issue['ctx'] as Map)
          : const <String, dynamic>{};

      final String? mapped = _mapValidationMessage(
        field: field,
        message: message,
        ctx: ctx,
      );
      if (mapped != null && mapped.isNotEmpty) {
        return mapped;
      }
    }
    return null;
  }

  String? _mapValidationMessage({
    required String field,
    required String message,
    required Map<String, dynamic> ctx,
  }) {
    final String normalizedField = field.toLowerCase();
    final String normalizedMessage = message.toLowerCase();

    if (normalizedField == 'password' &&
        normalizedMessage.contains('at least')) {
      final dynamic minLength = ctx['min_length'];
      if (minLength is int) {
        return 'Пароль должен содержать минимум $minLength символов.';
      }
      return 'Пароль должен содержать минимум 8 символов.';
    }

    if (normalizedField == 'username' &&
        normalizedMessage.contains('at least')) {
      final dynamic minLength = ctx['min_length'];
      if (minLength is int) {
        return 'Имя пользователя должно содержать минимум $minLength символа.';
      }
      return 'Имя пользователя слишком короткое.';
    }

    if (normalizedField == 'email' &&
        (normalizedMessage.contains('valid email') ||
            normalizedMessage.contains('value is not a valid email'))) {
      return 'Введите корректный email.';
    }

    if (message.isNotEmpty) {
      return message;
    }

    return null;
  }
}
