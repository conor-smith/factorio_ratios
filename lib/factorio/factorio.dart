abstract class TPrototype implements Comparable<TPrototype> {
  String get name;
  String get type;
  String get order;
  String? get localisedName;

  @override
  int compareTo(TPrototype other) {
    var toReturn = order.compareTo(other.order);

    return toReturn != 0 ? toReturn : name.compareTo(other.name);
  }

  @override
  String toString() => name;
}

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
