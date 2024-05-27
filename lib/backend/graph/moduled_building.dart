import 'dart:collection';

import 'package:factorio_ratios/backend/factorio_objects/objects.dart';

const maxModules = 50;

class ModuledBuildingException implements Exception {
  final String message;

  const ModuledBuildingException(this.message);
}

abstract class AbstractModuledBuilding {
  CraftingBuilding get building;
  List<Module> get buildingModules;
  Map<Beacon, List<Module>> get beaconModules;
  Map<CraftingEffect, double> get multipliers;
}

/// Represents a crafting building with modules applied
class ImmutableModuledBuilding implements AbstractModuledBuilding {
  @override
  final CraftingBuilding building;
  @override
  final List<Module> buildingModules;
  @override
  final Map<Beacon, List<Module>> beaconModules;
  @override
  final Map<CraftingEffect, double> multipliers;

  ImmutableModuledBuilding(this.building)
      : buildingModules = const [],
        beaconModules = const {},
        multipliers = {
          CraftingEffect.speed: building.baseSpeed,
          CraftingEffect.productivity: 1.0,
          CraftingEffect.consumption: 1.0,
          CraftingEffect.pollution: 1.0
        };

  ImmutableModuledBuilding._fromRTMB(RealTimeModuledBuilding rtmb)
      : building = rtmb.building,
        buildingModules = List.unmodifiable(rtmb._buildingModules),
        beaconModules = Map.unmodifiable(rtmb._beaconModules.map(
            (beacon, modules) => MapEntry(beacon, List.unmodifiable(modules)))),
        multipliers = Map.unmodifiable(rtmb._multipliers);

  RealTimeModuledBuilding createRealTimeModuledBuilding() {
    throw UnimplementedError();
  }
}

/// Intended to be used in GUIs
/// Will allow users to swap out buildings, beacons and modules,
/// and see the effects in real time
/// Modifications to number of modules must be done through provided add/remove methods
class RealTimeModuledBuilding implements AbstractModuledBuilding {
  CraftingBuilding _building;

  final List<Module> _buildingModules;
  final Map<Beacon, List<Module>> _beaconModules;

  ImmutableModuledBuilding _cachedBuilding;
  bool _edited;

  late final List<Module> _buildingModulesView =
      UnmodifiableListView(_buildingModules);
  // It is technically still possible to edit the List<Module> values in this map view
  // I considered creating a new view object for each value, or copying the whole map for each get
  // but that seemed overkill
  // I'm sure it's fine
  late final Map<Beacon, List<Module>> _beaconModulesView =
      UnmodifiableMapView(_beaconModules);

  final Map<CraftingEffect, double> _multipliers;
  late final Map<CraftingEffect, double> _multipliersView =
      UnmodifiableMapView(_multipliers);

  RealTimeModuledBuilding._fromImmutableModuledBuilding(
      ImmutableModuledBuilding parent)
      : _building = parent.building,
        _buildingModules = List.from(parent.buildingModules),
        _beaconModules = Map.from(parent.beaconModules.map(
            (beacon, moduleMap) => MapEntry(beacon, List.from(moduleMap)))),
        _multipliers = Map.from(parent.multipliers),
        _cachedBuilding = parent,
        _edited = false;

  set building(CraftingBuilding building) => throw UnimplementedError();

  void addBuildingModule(Module module) => throw UnimplementedError();
  void removeBuildingModule(Module module) => throw UnimplementedError();
  void clearBuildingModules() => throw UnimplementedError();

  void addBeaconModule(Beacon beacon, Module module) =>
      throw UnimplementedError();
  void removeBeaconModule(Beacon beacon, Module module) =>
      throw UnimplementedError();
  void clearBeacon(Beacon beacon) => throw UnimplementedError();

  bool get edited => _edited;

  ImmutableModuledBuilding createImmutableModuledBuilding() {
    throw UnimplementedError();
  }

  @override
  CraftingBuilding get building => _building;
  @override
  List<Module> get buildingModules => _buildingModulesView;
  @override
  Map<Beacon, List<Module>> get beaconModules => _beaconModulesView;
  @override
  Map<CraftingEffect, double> get multipliers => _multipliersView;
}
