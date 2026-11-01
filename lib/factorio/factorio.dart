class FactorioException implements Exception {
  final String message;
  final Object? cause;
  final StackTrace? stackTrace;

  const FactorioException(this.message) : cause = null, stackTrace = null;

  const FactorioException.withCause(
    this.message,
    Object this.cause,
    StackTrace this.stackTrace,
  );

  @override
  String toString() {
    var string = '${runtimeType.toString()}: $message';
    if (cause != null) {
      string += '\ncaused by\n$cause\nat\n$stackTrace';
    }

    return string;
  }
}
