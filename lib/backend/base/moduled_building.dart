import 'dart:collection';

import 'package:factorio_ratios/backend/factorio_objects/objects.dart';
import 'package:sorted_list/sorted_list.dart';

const maxModules = 50;
const minMultipliers = {
  CraftingEffect.speed: 0.2,
  CraftingEffect.productivity: 1.0,
  CraftingEffect.powerConsumption: 0.2,
  CraftingEffect.pollution: 1.0
};

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
          CraftingEffect.powerConsumption: 1.0,
          CraftingEffect.pollution: 1.0
        };

  ImmutableModuledBuilding._fromRTMB(RealTimeModuledBuilding rtmb)
      : building = rtmb.building,
        buildingModules = List.unmodifiable(rtmb._buildingModules),
        beaconModules = Map.unmodifiable(rtmb._beaconModules.map(
            (beacon, modules) => MapEntry(beacon, List.unmodifiable(modules)))),
        multipliers = Map.unmodifiable(rtmb._multipliers);

  RealTimeModuledBuilding createRealTimeModuledBuilding() =>
      RealTimeModuledBuilding._fromImmutableModuledBuilding(this);
}

// Used in sorted lists
int Function(Module, Module) _compareModules =
    (module1, module2) => module1.name.compareTo(module2.name);

/// Intended to be used in GUIs
/// Will allow users to swap out buildings, beacons and modules,
/// and see the effects in real time
/// Modifications to number of modules must be done through provided add/remove methods
class RealTimeModuledBuilding implements AbstractModuledBuilding {
  CraftingBuilding _building;

  // Lists are sorted alphabetically according to .name
  // TODO: Is alphabetically the best way to sort?
  final SortedList<Module> _buildingModules;
  final Map<Beacon, SortedList<Module>> _beaconModules;

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
        _buildingModules = SortedList(_compareModules)
          ..addAll(parent.buildingModules),
        _beaconModules = Map.from(parent.beaconModules.map((beacon,
                moduleList) =>
            MapEntry(beacon, SortedList(_compareModules)..addAll(moduleList)))),
        _multipliers = Map.from(parent.multipliers),
        _cachedBuilding = parent,
        _edited = false;

  set building(CraftingBuilding newBuilding) {
    // Remove any forbidden modules
    if (!_building.allowedEffects
        .every((effect) => newBuilding.allowedEffects.contains(effect))) {
      _buildingModules.removeWhere(
          (module) => !newBuilding.allowedModules.contains(module));

      // Remove any beacon entries that have been completely emptied
      _beaconModules
        ..forEach((beacon, modules) => modules.removeWhere(
            (module) => !newBuilding.allowedModules.contains(module)))
        ..removeWhere((beacon, modules) => modules.isEmpty);
    }

    // If newBuilding has less slots, remove modules
    if (newBuilding.moduleSlots < _buildingModules.length) {
      _buildingModules.removeRange(
          newBuilding.moduleSlots, _buildingModules.length);
    }

    _building = newBuilding;

    _calculateMultipliers();
  }

  void addBuildingModule(Module module) {
    if (!_building.allowedModules.contains(module)) {
      throw ModuledBuildingException(
          "Module '${module.name}' cannot be placed in building '${_building.name}'");
    } else if (_buildingModules.length >= _building.moduleSlots) {
      throw const ModuledBuildingException("Building module slots are full");
    }

    _buildingModules.add(module);

    _calculateMultipliers();
  }

  void removeBuildingModule(Module module) {
    if (!_buildingModules.remove(module)) {
      throw const ModuledBuildingException(
          "Module must be in building in order to be removed");
    }

    _calculateMultipliers();
  }

  void clearBuildingModules() {
    if (_buildingModules.isNotEmpty) {
      _buildingModules.removeRange(0, _buildingModules.length);
    }

    _calculateMultipliers();
  }

  void addBeaconModule(Beacon beacon, Module module) {
    if ((_beaconModules[beacon]?.length ?? 0) >= maxModules) {
      throw const ModuledBuildingException(
          "Cannot apply more than $maxModules modules to a beacon");
    }

    if (!_building.allowedModules.contains(module) ||
        !beacon.allowedModules.contains(module)) {
      throw ModuledBuildingException(
          "Module '${module.name} is forbidden either by building '${building.name}' or beacon '${beacon.name}'");
    }

    _beaconModules.update(beacon, (modules) => modules..add(module),
        ifAbsent: () => SortedList(_compareModules)..add(module));

    _calculateMultipliers();
  }

  void removeBeaconModule(Beacon beacon, Module module) {
    if (!(_beaconModules[beacon]?.remove(module) ?? false)) {
      throw const ModuledBuildingException(
          "Module must be applied to beacon in order to be removed");
    }

    if (_beaconModules[beacon]!.isEmpty) {
      _beaconModules.remove(beacon);
    }

    _calculateMultipliers();
  }

  void clearBeacon(Beacon beacon) {
    if (_beaconModules.remove(beacon) == null) {
      throw const ModuledBuildingException(
          "Beacon must be present in order to be cleared");
    }

    _calculateMultipliers();
  }

  ImmutableModuledBuilding createImmutableModuledBuilding() {
    if (_edited) {
      _edited = false;
      _cachedBuilding = ImmutableModuledBuilding._fromRTMB(this);
    }

    return _cachedBuilding;
  }

  void _calculateMultipliers() {
    // Create a map of module: counter
    // This also takes distributionEffectivity of beacons into account
    // I prefer doing this as opposed to straight incrementing as this reduces
    // floating point inaccuracies
    var allModules = <Module, double>{};

    for (var module in _buildingModules) {
      allModules.update(module, (counter) => counter + 1, ifAbsent: () => 1);
    }

    _beaconModules.forEach((beacon, modules) {
      for (var module in modules) {
        allModules.update(
            module, (counter) => counter + beacon.distributionEffectivity,
            ifAbsent: () => beacon.distributionEffectivity);
      }
    });

    // Reset to default values
    _multipliers.updateAll((effect, multiplier) => 1.0);
    // Apply bonuses to multipliers
    allModules.forEach((module, counter) {
      module.effects.forEach((effect, bonus) => _multipliers.update(
          effect, (multiplier) => multiplier + bonus * counter));
    });

    // Compare against minimum values
    _multipliers.updateAll((effect, multiplier) =>
        multiplier < minMultipliers[effect]!
            ? minMultipliers[effect]!
            : multiplier);

    // Apply building base speed multiplier
    _multipliers[CraftingEffect.speed] =
        _multipliers[CraftingEffect.speed]! * _building.baseSpeed;

    _edited = true;
  }

  bool get edited => _edited;
  @override
  CraftingBuilding get building => _building;
  @override
  List<Module> get buildingModules => _buildingModulesView;
  @override
  Map<Beacon, List<Module>> get beaconModules => _beaconModulesView;
  @override
  Map<CraftingEffect, double> get multipliers => _multipliersView;
}
