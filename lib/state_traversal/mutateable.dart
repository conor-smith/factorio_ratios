// Could probably use ChangeNotifier here, but I'd like this code not to depend on flutter
abstract mixin class Mutateable<T extends MutationEvent> {
  final List<Function(bool isRollback, List<T> updates)> _listeners = [];

  void addListener(Function(bool isRollback, List<T> event) callback) {
    _listeners.add(callback);
  }

  void clearListeners() {
    _listeners.clear();
  }

  void notifyListeners(bool isRollback, List<T> updates) {
    for (var callback in _listeners) {
      callback(isRollback, updates);
    }
  }

  void apply(T event);
  void redo(T event);
  void rollback(T event);
}

abstract class MutationEvent {}

class MutationException implements Exception {
  final String message;

  const MutationException(this.message);

  @override
  String toString() => 'MutationException: $message';
}
