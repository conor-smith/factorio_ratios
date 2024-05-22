import 'dart:collection';

import 'package:factorio_ratios/backend/factorio_objects/objects.dart';

abstract class AbstractModuledBuilding {
  CraftingBuilding get building;
  Map<Module, int> get buildingModules;
  Map<Beacon, Map<Module, int>> get beaconModules;
  double get speedMultiplier;
  double get productivityMultiplier;
  double get consumptionMultiplier;
  double get pollutionMultiplier;
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
  final double speedMultiplier;
  @override
  final double productivityMultiplier;
  @override
  final double consumptionMultiplier;
  @override
  final double pollutionMultiplier;

  ImmutableModuledBuilding._(
      {required this.building,
      required Map<Module, int> buildingModules,
      required Map<Beacon, Map<Module, int>> beaconModules,
      required this.speedMultiplier,
      required this.productivityMultiplier,
      required this.consumptionMultiplier,
      required this.pollutionMultiplier})
      : buildingModules = Map.unmodifiable(buildingModules),
        beaconModules = Map.unmodifiable(beaconModules.map(
            (beacon, modules) => MapEntry(beacon, Map.unmodifiable(modules))));
}

/// Intended to be used in GUIs
/// Will allow users to swap out buildings, beacons and modules,
/// and see the effects in real time
/// Modifications to number of modules must be done through provided add/remove methods
class RealTimeModuledBuilding implements AbstractModuledBuilding {
  CraftingBuilding _building;
  final Map<Module, int> _buildingModules;
  late final Map<Module, int> _buildingModulesView;
  final Map<Beacon, Map<Module, int>> _beaconModules;
  late final Map<Beacon, Map<Module, int>> _beaconModulesView;
  double _speedMultiplier;
  double _productivityMultiplier;
  double _consumptionMultiplier;
  double _pollutionMultiplier;

  RealTimeModuledBuilding(CraftingBuilding building)
      : _building = building,
        _buildingModules = {},
        _beaconModules = {},
        _speedMultiplier = building.baseSpeed,
        _productivityMultiplier = 1.0,
        _consumptionMultiplier = 1.0,
        _pollutionMultiplier = 1.0 {
    _buildingModulesView = UnmodifiableMapView(_buildingModules);
    _beaconModulesView = UnmodifiableMapView(_beaconModules);
  }

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
  double get speedMultiplier => _speedMultiplier;
  @override
  double get productivityMultiplier => _productivityMultiplier;
  @override
  double get consumptionMultiplier => _consumptionMultiplier;
  @override
  double get pollutionMultiplier => _pollutionMultiplier;
}
