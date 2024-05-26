import 'dart:collection';

import 'package:factorio_ratios/backend/factorio_objects/objects.dart';

abstract class AbstractModuledBuilding {
  CraftingBuilding get building;
  Map<Module, int> get buildingModules;
  Map<Beacon, Map<Module, int>> get beaconModules;
  Map<CraftingEffect, double> get multipliers;
}

/// Represents a crafting building with modules applied
class ImmutableModuledBuilding implements AbstractModuledBuilding {
  @override
  final CraftingBuilding building;
  @override
  final Map<Module, int> buildingModules;
  @override
  final Map<Beacon, Map<Module, int>> beaconModules;
  @override
  final Map<CraftingEffect, double> multipliers;

  ImmutableModuledBuilding(this.building)
      : buildingModules = const {},
        beaconModules = const {},
        multipliers = {
          CraftingEffect.speed: building.baseSpeed,
          CraftingEffect.productivity: 1.0,
          CraftingEffect.consumption: 1.0,
          CraftingEffect.pollution: 1.0
        };

  ImmutableModuledBuilding._fromRTMB(RealTimeModuledBuilding rtmb)
      : building = rtmb.building,
        buildingModules = Map.unmodifiable(rtmb._buildingModules),
        beaconModules = Map.unmodifiable(rtmb._beaconModules.map(
            (beacon, modules) => MapEntry(beacon, Map.unmodifiable(modules)))),
        multipliers = Map.unmodifiable(rtmb._multipliers);
}

/// Intended to be used in GUIs
/// Will allow users to swap out buildings, beacons and modules,
/// and see the effects in real time
/// Modifications to number of modules must be done through provided add/remove methods
class RealTimeModuledBuilding implements AbstractModuledBuilding {
  CraftingBuilding _building;
  final Map<Module, int> _buildingModules;
  final Map<Beacon, Map<Module, int>> _beaconModules;

  late final Map<Module, int> _buildingModulesView =
      UnmodifiableMapView(_buildingModules);
  // It is technically still possible to edit the Map<Module, int> values in this map
  // I considered creating a new view object for each value, or copying the whole map for each get
  // but that seemed overkill
  // I'm sure it's fine
  late final Map<Beacon, Map<Module, int>> _beaconModulesView =
      UnmodifiableMapView(_beaconModules);

  final Map<CraftingEffect, double> _multipliers;
  late final Map<CraftingEffect, double> _multipliersView =
      UnmodifiableMapView(_multipliers);

  RealTimeModuledBuilding(CraftingBuilding building)
      : _building = building,
        _buildingModules = {},
        _beaconModules = {},
        _multipliers = {
          CraftingEffect.speed: building.baseSpeed,
          CraftingEffect.productivity: 1.0,
          CraftingEffect.consumption: 1.0,
          CraftingEffect.pollution: 1.0
        };

  set building(CraftingBuilding building) => throw UnimplementedError();

  void addBuildingModule(Module module) => throw UnimplementedError();
  void removeBuildingModule(Module module) => throw UnimplementedError();

  void addBeaconModule(Beacon beacon, Module module) =>
      throw UnimplementedError();
  void removeBeaconModule(Beacon beacon, Module module) =>
      throw UnimplementedError();

  @override
  CraftingBuilding get building => _building;
  @override
  Map<Module, int> get buildingModules => _buildingModulesView;
  @override
  Map<Beacon, Map<Module, int>> get beaconModules => _beaconModulesView;
  @override
  Map<CraftingEffect, double> get multipliers => _multipliersView;
}
