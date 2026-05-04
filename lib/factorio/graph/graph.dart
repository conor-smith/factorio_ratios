import 'dart:collection';
import 'dart:ui';

import 'package:factorio_ratios/factorio/dynamic_models/dynamic_models.dart';
import 'package:factorio_ratios/factorio/factorio.dart';
import 'package:factorio_ratios/factorio/graph/geometry/geometry.dart';
import 'package:factorio_ratios/factorio/graph/state/state.dart';
import 'package:factorio_ratios/factorio/models/models.dart';
import 'package:factorio_ratios/factorio/production_lines/production_line.dart';
import 'package:factorio_ratios/ui/graph/overlay_widget.dart';

part 'base_graph.dart';
part 'edge.dart';
part 'event_history.dart';
part 'node.dart';

/// This object represents the entire base, and is the single source of truth for the app
/// Stores all event history, default recipes, and any global data
/// 
/// Creates a single PlanetBase to act as the root base
/// As a planetBase is a production line, a node can itself contain a planetBase object
/// This creates a tree structure
/// Every planetBase object will have reference to this object
/// 
/// The root PlanetBase cannot have input or output nodes
class FactorioBase {
  final FactorioDatabase factorioDb;
  final _EventHistory _history;

  late final PlanetBase rootGraph;
  final Map<Surface, _SurfaceProperties> _surfaceProperties;

  FactorioBase(this.factorioDb)
    : _history = _EventHistory(20),
      _surfaceProperties = factorioDb.surfaceMap.map(
        (name, surface) => MapEntry(
          surface,
          _SurfaceProperties(
            defaultRecipes: surface.recipes
                .where((recipe) => recipe.isSimple)
                .map((recipe) => InGameRecipe(recipe)),
            resources: surface.resourceItems.map((item) => InGameItem(item)),
            availableSolidFuels: surface.resourceItems
                .whereType<SolidItem>()
                .where((solidItem) => (solidItem.fuelValue ?? 0) > 0)
                .map((solidItem) => InGameSolidItem(solidItem)),
          ),
        ),
      ) {
    var nauvis = factorioDb.surfaceMap['nauvis']!;

    // TODO - Top graph should have no surface
    rootGraph = PlanetBase._root(
      globalData: this,
      surface: nauvis,
      surfaceProperties: _surfaceProperties[nauvis]!,
    );
  }
}

class GraphException extends ProductionLineException {
  const GraphException(super.message);

  @override
  String toString() => 'GraphException: $message';
}

class _SurfaceProperties {
  final List<Recipe> defaultRecipes;
  final List<InGameItem> resources;
  final List<InGameSolidItem> availableSolidFuels;
  // TODO - Liquid fuels

  _SurfaceProperties({
    required Iterable<Recipe> defaultRecipes,
    required Iterable<InGameItem> resources,
    required Iterable<InGameSolidItem> availableSolidFuels,
  }) : defaultRecipes = List.unmodifiable(defaultRecipes),
       resources = List.unmodifiable(resources),
       availableSolidFuels = List.unmodifiable(availableSolidFuels);
}
