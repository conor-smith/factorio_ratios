import 'package:factorio_ratios/factorio/graph/graph.dart';
import 'package:factorio_ratios/factorio/graph/geometry/geometry.dart';
import 'package:factorio_ratios/factorio/production_lines/production_line.dart';

part 'edge_event.dart';
part 'graph_event.dart';
part 'node_event.dart';


/// A stateful class can only have it's internal state be meaningfully modified
/// by applying a MutationEvent
/// 
/// Said mutationEvents can also be rolled back and redone, completely restoring
/// a previously existing state
/// 
/// A stateful object can be listened to
/// The object may update listeners with events as required
abstract mixin class Stateful<T extends MutationEvent> {
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

  void apply(T event);
  void redo(T event);
  void rollback(T event);
}

/// Represents a single, reversible state update
/// A mutation event needn't necessarily be atomic
abstract class MutationEvent {
  bool get isReversed;
  MutationEvent get reversed;
}

class MutationException implements Exception {
  final String message;

  const MutationException(this.message);

  @override
  String toString() => 'MutationException: $message';
}

void _removedWhereBothContain(Set set1, Set set2) {
  for (var item in List.from(set1)) {
    if (set2.contains(item)) {
      set1.remove(item);
      set2.remove(item);
    }
  }
}
