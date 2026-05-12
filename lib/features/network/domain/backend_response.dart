/// Represents a response from the backend API.
class BackendResponse<T> {
  const BackendResponse({
    required this.data,
    required this.success,
    this.message,
    this.statusCode,
    this.error,
  });

  /// The response data
  final T? data;

  /// Whether the request was successful
  final bool success;

  /// Response message from server
  final String? message;

  /// HTTP status code
  final int? statusCode;

  /// Error information (if any)
  final dynamic error;

  /// Check if response is a success
  bool get isSuccess => success && data != null;

  /// Check if response is a failure
  bool get isFailure => !success || data == null;

  /// Create a success response
  factory BackendResponse.success(
    T data, {
    String? message,
    int? statusCode,
  }) {
    return BackendResponse(
      data: data,
      success: true,
      message: message ?? 'Request successful',
      statusCode: statusCode ?? 200,
    );
  }

  /// Create a failure response
  factory BackendResponse.failure({
    required String message,
    int? statusCode,
    dynamic error,
  }) {
    return BackendResponse(
      data: null,
      success: false,
      message: message,
      statusCode: statusCode ?? 500,
      error: error,
    );
  }

  /// Create from HTTP response
  factory BackendResponse.fromHttpResponse({
    required int statusCode,
    required String body,
    required bool Function(int) isSuccess,
  }) {
    final success = isSuccess(statusCode);
    return BackendResponse<String>(
      data: success ? body : null,
      success: success,
      statusCode: statusCode,
      message: success ? 'Success' : 'HTTP $statusCode',
    ) as BackendResponse<T>;
  }

  @override
  String toString() => 'BackendResponse(success=$success, statusCode=$statusCode, message=$message)';
}
