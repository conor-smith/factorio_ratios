part of 'base_planner.dart';

abstract interface class EventNotifier<T> {
  void addListener(Object listener, Function(T event) callback);
  void removeListener(Object listener);
  void clearListeners();
  void notifyListeners(T event);
}

abstract interface class BasePlannerElement<St extends ToJson, E>
    implements EventNotifier<E>, ToJson {
  static final Random _random = Random(DateTime.now().millisecondsSinceEpoch);
  static int generateId() => _random.nextInt(1000000000);

  int get id;

  St get state;
  set state(covariant St state);

  void remove();

  Builder<St> getStateBuilder();

  void notifyListenersOfStateChange(St oldState, St newState);
  void notifyListenersOfGeometryUpdate(covariant Geometry geometry);
}

abstract interface class Builder<T> {
  T build();
}
