class FactorioException implements Exception {
  final String message;

  const FactorioException(this.message);
  
  @override
  String toString() => 'FactorioException: $message';
}