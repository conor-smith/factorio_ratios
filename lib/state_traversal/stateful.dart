/*
 * A stateful class can only have it's internal state be meaningfully modified
 * by applying a MutationEvent
 * Said mutationEvents can also be rolled back and redone, completely restoring
 * a previously existing state
 * 
 * There also exist Delayed Event Operations (DEO for convenience)
 * A DEO will change the apparent state of the object, but can be cancelled at any time
 * When cancelled, the object will return to it's state before the start of the DEO
 * Calling finishDelayedEventOperation will internally generate an event and commit the changes
 */
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

  void startDelayedEventOperation();
  void cancelDelayedEventOperation();
  void finishDelayedEventOperation();
  bool get performingDelayedEventOperation;
}

abstract class MutationEvent {}

class MutationException implements Exception {
  final String message;

  const MutationException(this.message);

  @override
  String toString() => 'MutationException: $message';
}
