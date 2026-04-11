// Could probably use ChangeNotifier here, but I'd like this code not to depend on flutter
abstract mixin class Stateful<T extends MutationEvent> {
  final List<Function(bool isRollback, T update)> _listeners = [];

  void addListener(Function(bool isRollback, T event) callback) {
    _listeners.add(callback);
  }

  void clearListeners() {
    _listeners.clear();
  }

  void notifyListeners(bool isRollback, T update) {
    for (var callback in _listeners) {
      callback(isRollback, update);
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
