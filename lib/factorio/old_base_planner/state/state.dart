import 'package:factorio_ratios/factorio/dynamic_models/dynamic_models.dart';
import 'package:factorio_ratios/factorio/old_base_planner/base_planner.dart';
import 'package:factorio_ratios/factorio/old_base_planner/geometry/geometry.dart';
import 'package:factorio_ratios/factorio/factorio.dart';
import 'package:factorio_ratios/factorio/production_lines/production_line.dart';

part 'base_event.dart';
part 'edge_event.dart';
part 'graph_event.dart';
part 'node_event.dart';

/// A stateful class can only have it's internal state be meaningfully modified
/// by applying a MutationEvent.
/// Said mutationEvents can also be rolled back and redone, completely restoring
/// a previously existing state.
///
/// A stateful object can be listened to.
/// The object may update listeners with events as required.
abstract class Stateful<T extends MutationEvent> {
  final List<Function(T event)> _listeners = [];

  void addListener(Function(T event) callback) {
    _listeners.add(callback);
  }

  void clearListeners() {
    _listeners.clear();
  }

  void notifyListeners(T event) {
    for (var callback in _listeners) {
      callback(event);
    }
  }

  void apply(T event);
  void redo(T event);
  void rollback(T event);
}

/// Represents a single state update
/// A mutation event isn't necessarily atomic
abstract class MutationEvent {}

class MutationException extends FactorioException {
  const MutationException(super.message, [super.cause]);
}

Map<K, V>? _unmodifiableOrNullMap<K, V>(Map<K, V>? collection) =>
    collection != null ? Map.unmodifiable(collection) : null;

Set<T>? _unmodifiableOrNullSet<T>(Iterable<T>? collection) =>
    collection != null ? Set.unmodifiable(collection) : null;

List<T>? _unmodifiableOrNullList<T>(Iterable<T>? collection) =>
    collection != null ? List.unmodifiable(collection) : null;
