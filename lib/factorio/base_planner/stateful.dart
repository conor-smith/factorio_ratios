import 'dart:math';

import 'package:factorio_ratios/json/json.dart';

interface class EventNotifier<T> {
  final List<Function(T event)> _callbacks = [];

  void addCallback(Function(T event) callback) => _callbacks.add(callback);
  void clearCallbacks() => _callbacks.clear();

  void notifyListeners(T event) {
    for (var callback in _callbacks) {
      callback(event);
    }
  }
}

abstract interface class ElementState implements ToJson {}

abstract interface class BasePlannerElement<St extends ElementState, E>
    implements EventNotifier<E>, ToJson {
  static final Random _random = Random(DateTime.now().millisecondsSinceEpoch);

  static int generateId() => _random.nextInt(1000000000);

  int get id;

  St get state;
  set state(St state);

  void notifyListenerOfStateChange(St oldState, St newState);
}

abstract interface class Builder<T> {
  T build();
}
