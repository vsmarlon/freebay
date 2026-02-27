class ApiError {
  final String code;
  final String message;

  const ApiError({required this.code, required this.message});

  factory ApiError.fromJson(Map<String, dynamic> json) {
    return ApiError(
      code: json['code'] as String? ?? 'UNKNOWN_ERROR',
      message: json['message'] as String? ?? 'Erro desconhecido',
    );
  }
}

class ApiResponse<T> {
  final bool success;
  final T? data;
  final ApiError? error;

  const ApiResponse({required this.success, this.data, this.error});

  factory ApiResponse.fromJson(
    Map<String, dynamic> json,
    T Function(Object? json)? fromJsonT,
  ) {
    final success = json['success'] as bool? ?? false;

    if (success) {
      return ApiResponse(
        success: true,
        data: fromJsonT != null && json['data'] != null
            ? fromJsonT(json['data'])
            : json['data'] as T?,
      );
    } else {
      return ApiResponse(
        success: false,
        error: json['error'] != null
            ? ApiError.fromJson(json['error'] as Map<String, dynamic>)
            : const ApiError(code: 'UNKNOWN', message: 'Erro desconhecido'),
      );
    }
  }
}
