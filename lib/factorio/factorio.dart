class FactorioException implements Exception {
  final String message;
  final Object? cause;

  const FactorioException(this.message, [this.cause]);

  @override
  String toString() {
    var string = '${runtimeType.toString()}: $message';
    if (cause != null) {
      string += '\ncaused by $cause';
    }

    return string;
  }
}
