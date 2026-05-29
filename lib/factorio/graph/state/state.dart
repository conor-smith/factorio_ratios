import 'package:factorio_ratios/factorio/dynamic_models/dynamic_models.dart';
import 'package:factorio_ratios/factorio/graph/graph.dart';
import 'package:factorio_ratios/factorio/graph/geometry/geometry.dart';
import 'package:factorio_ratios/factorio/production_lines/production_line.dart';

part 'base_event.dart';
part 'edge_event.dart';
part 'graph_event.dart';
part 'node_event.dart';

abstract class EventNotifier<T extends MutationEvent> {
  final List<Function(T update)> _listeners = [];

  void addListener(Function(T event) callback) {
    _listeners.add(callback);
  }

  void clearListeners() {
    _listeners.clear();
  }

  void notifyListeners(T update) {
    for (var callback in _listeners) {
      callback(update);
    }
  }
}

/// A stateful class can only have it's internal state be meaningfully modified
/// by applying a MutationEvent.
/// Said mutationEvents can also be rolled back and redone, completely restoring
/// a previously existing state.
///
/// A stateful object can be listened to.
/// The object may update listeners with events as required.
abstract class Stateful<T extends MutationEvent> extends EventNotifier<T> {
  void apply(T event);
  void redo(T event);
  void rollback(T event);
}

/// Represents a single state update
/// A mutation event isn't necessarily atomic
abstract class MutationEvent {}

class MutationException implements Exception {
  final String message;

  const MutationException(this.message);

  @override
  String toString() => 'MutationException: $message';
}

Map<K, V>? _unmodifiableOrNullMap<K, V>(Map<K, V>? collection) =>
    collection != null ? Map.unmodifiable(collection) : null;

Set<T>? _unmodifiableOrNullSet<T>(Iterable<T>? collection) =>
    collection != null ? Set.unmodifiable(collection) : null;

List<T>? _unmodifiableOrNullList<T>(Iterable<T>? collection) =>
    collection != null ? List.unmodifiable(collection) : null;
