import 'dart:math';

import 'package:factorio_ratios/json/json.dart';

interface class EventNotifier<T> {
  Function(T event)? _eventCallback;

  bool get hasCallback => _eventCallback != null;
  set eventCallback(Function(T event) callback) => _eventCallback = callback;
  void clearCallback() => _eventCallback = null;

  void notifyListener(T event) {
    var callback = _eventCallback;
    if (callback != null) {
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
