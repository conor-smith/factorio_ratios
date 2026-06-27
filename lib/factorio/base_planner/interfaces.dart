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

/// All objects that are part of [BasePlanner] implement this interface.
///
/// As all elements are listenable, state changes should only be
/// registered via events.
///
/// [state], once set, is an immutable object.
/// However, [getStateBuilder] will return a relevant builder.
/// Any changes to the stateBuilder will be reflected in [state] unless
/// [cancelStateBuilder] is called, at which point, [state] will be reset.
abstract interface class BasePlannerElement<St, E>
    implements EventNotifier<E>, ToJson {
  BasePlanner get basePlanner;
  Graph get parentGraph;
  Geometry get geometry;

  /// Returns immutable object representing state
  St get state;

  bool get isSelected;
  void select();
  void deselect();

  /// Will only be permitted if [BasePlanner] allows. Will throw an exception otherwise.
  set state(covariant St state);

  /// Return mutable object representing [state].
  /// All changes will be reflected unless [cancelStateBuilder] is called.
  StateBuilder<St> getStateBuilder();
  void cancelStateBuilder();

  /// Used in the event of a dragging or resizing operation.
  /// Allows notifying listeners of some [Geometry] object without updating [state].
  void notifyListenersOfGeometryUpdate(covariant Geometry geometry);

  /// Used whenever state is updated
  void notifyListenersOfStateUpdate(
    covariant St oldState,
    covariant St newState,
  );
}
