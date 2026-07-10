part of 'base_planner.dart';

/// A simple, listenable interface which emits events.
///
/// Probably could have used a Flutter class, but I wanted the code here to be
/// as independent as possible.
abstract mixin class EventNotifier<T> {
  final Map<Object, Function(T event)> _listeners = {};

  bool get hasListeners => _listeners.isNotEmpty;
  void addListener(Object listener, Function(T event) callback) =>
      _listeners[listener] = callback;
  void removeListener(Object listener) => _listeners.remove(listener);
  void clearListeners() => _listeners.clear();

  void notifyListeners(T event) {
    for (var callback in _listeners.values) {
      callback(event);
    }
  }
}
