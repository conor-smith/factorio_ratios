part of 'base_planner.dart';

class EventNotifierImpl<T> implements EventNotifier<T> {
  final Map<Object, Function(T event)> _listeners = {};

  @override
  void addListener(Object listener, Function(T event) callback) =>
      _listeners[listener] = callback;
  @override
  void removeListener(Object listener) => _listeners.remove(listener);
  @override
  void clearListeners() => _listeners.clear();

  @override
  void notifyListeners(T event) {
    for (var callback in _listeners.values) {
      callback(event);
    }
  }
}
