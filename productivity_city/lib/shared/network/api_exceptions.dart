class ApiException implements Exception {
  const ApiException({required this.message, this.statusCode, this.payload});

  final String message;
  final int? statusCode;
  final Object? payload;

  @override
  String toString() => message;
}

class UnauthorizedException extends ApiException {
  const UnauthorizedException({
    super.message = 'Session expired. Please sign in again.',
    super.payload,
  }) : super(statusCode: 401);
}

class FeatureUnavailableException implements Exception {
  const FeatureUnavailableException(this.message);

  final String message;

  @override
  String toString() => message;
}
