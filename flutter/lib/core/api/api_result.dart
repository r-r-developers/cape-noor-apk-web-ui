import 'package:dio/dio.dart';

/// Typed result wrapper — avoids throwing exceptions across the UI layer.
sealed class ApiResult<T> {
  const ApiResult();
}

final class ApiSuccess<T> extends ApiResult<T> {
  final T data;
  const ApiSuccess(this.data);
}

final class ApiError<T> extends ApiResult<T> {
  final String message;
  final int? statusCode;
  const ApiError(this.message, {this.statusCode});
}

/// Wraps a Dio call and converts it into an ApiResult.
Future<ApiResult<T>> apiCall<T>(
  Future<Response> Function() request,
  T Function(Map<String, dynamic>) fromJson,
) async {
  try {
    final response = await request();
    final data     = response.data as Map<String, dynamic>;

    if (data['success'] == true) {
      return ApiSuccess<T>(fromJson(data));
    }

    return ApiError<T>(data['error'] ?? 'Unknown error', statusCode: response.statusCode);
  } on DioException catch (e) {
    final body = e.response?.data;
    final msg  = (body is Map ? body['error'] : null) ?? e.message ?? 'Network error';
    return ApiError<T>(msg, statusCode: e.response?.statusCode);
  } catch (e) {
    return ApiError<T>(e.toString());
  }
}
