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

class ModuledMachineException implements Exception {
  final String message;

  const ModuledMachineException(this.message);
}

abstract class AbstractModuledMachine {
  CraftingMachine get machine;
  List<Module> get machineModules;
  Map<Beacon, List<Module>> get beaconModules;
  Map<CraftingEffect, double> get multipliers;
  double get moduledPowerConsumption;
  double get moduledPollutionPerMin;

  double get basePowerConsumption => machine.powerConsumption;
  double get basePollutionPerMin => machine.pollutionPerMin;
  double get powerDrain => machine.powerDrain;
}

/// Represents a crafting machine with modules applied
class ImmutableModuledMachine extends AbstractModuledMachine {
  @override
  final CraftingMachine machine;
  @override
  final List<Module> machineModules;
  @override
  final Map<Beacon, List<Module>> beaconModules;
  @override
  final Map<CraftingEffect, double> multipliers;
  @override
  final double moduledPowerConsumption;
  @override
  final double moduledPollutionPerMin;

  ImmutableModuledMachine(this.machine)
      : machineModules = const [],
        beaconModules = const {},
        multipliers = {
          CraftingEffect.speed: machine.baseSpeed,
          CraftingEffect.productivity: 1.0,
          CraftingEffect.powerConsumption: 1.0,
          CraftingEffect.pollution: 1.0
        },
        moduledPowerConsumption = machine.powerConsumption,
        moduledPollutionPerMin = machine.pollutionPerMin;

  ImmutableModuledMachine._fromRTMM(RealTimeModuledMachine rtmm)
      : machine = rtmm.machine,
        machineModules = List.unmodifiable(rtmm._machineModules),
        beaconModules = Map.unmodifiable(rtmm._beaconModules.map(
            (beacon, modules) => MapEntry(beacon, List.unmodifiable(modules)))),
        multipliers = Map.unmodifiable(rtmm._multipliers),
        moduledPowerConsumption = rtmm.moduledPowerConsumption,
        moduledPollutionPerMin = rtmm.moduledPollutionPerMin;

  RealTimeModuledMachine createRealTimeModuledMachine() =>
      RealTimeModuledMachine._fromIMM(this);
}

// Used in sorted lists
int Function(Module, Module) _compareModules =
    (module1, module2) => module1.name.compareTo(module2.name);

/// Intended to be used in GUIs
/// Will allow users to swap out machines, beacons and modules,
/// and see the effects in real time
/// Modifications to number of modules must be done through provided add/remove methods
class RealTimeModuledMachine extends AbstractModuledMachine {
  CraftingMachine _machine;

  // Lists are sorted alphabetically according to .name
  // TODO: Is alphabetically the best way to sort?
  final SortedList<Module> _machineModules;
  final Map<Beacon, SortedList<Module>> _beaconModules;

  ImmutableModuledMachine _cachedMachine;
  bool _edited;

  late final List<Module> _machineModulesView =
      UnmodifiableListView(_machineModules);
  // It is technically still possible to edit the List<Module> values in this map view
  // I considered creating a new view object for each value, or copying the whole map for each get
  // but that seemed overkill
  // I'm sure it's fine
  late final Map<Beacon, List<Module>> _beaconModulesView =
      UnmodifiableMapView(_beaconModules);

  final Map<CraftingEffect, double> _multipliers;
  late final Map<CraftingEffect, double> _multipliersView =
      UnmodifiableMapView(_multipliers);

  RealTimeModuledMachine._fromIMM(ImmutableModuledMachine parent)
      : _machine = parent.machine,
        _machineModules = SortedList(_compareModules)
          ..addAll(parent.machineModules),
        _beaconModules = Map.from(parent.beaconModules.map((beacon,
                moduleList) =>
            MapEntry(beacon, SortedList(_compareModules)..addAll(moduleList)))),
        _multipliers = Map.from(parent.multipliers),
        _cachedMachine = parent,
        _edited = false;

  set machine(CraftingMachine newMachine) {
    // Remove any forbidden modules
    if (!_machine.allowedEffects
        .every((effect) => newMachine.allowedEffects.contains(effect))) {
      _machineModules
          .removeWhere((module) => !newMachine.allowedModules.contains(module));

      // Remove any beacon entries that have been completely emptied
      _beaconModules
        ..forEach((beacon, modules) => modules.removeWhere(
            (module) => !newMachine.allowedModules.contains(module)))
        ..removeWhere((beacon, modules) => modules.isEmpty);
    }

    // If newMachine has less slots, remove modules
    if (newMachine.moduleSlots < _machineModules.length) {
      _machineModules.removeRange(
          newMachine.moduleSlots, _machineModules.length);
    }

    _machine = newMachine;

    _calculateMultipliers();
  }

  void addMachineModule(Module module) {
    if (!_machine.allowedModules.contains(module)) {
      throw ModuledMachineException(
          "Module '${module.name}' cannot be placed in machine '${_machine.name}'");
    } else if (_machineModules.length >= _machine.moduleSlots) {
      throw const ModuledMachineException("Machine module slots are full");
    }

    _machineModules.add(module);

    _calculateMultipliers();
  }

  void removeMachineModule(Module module) {
    if (!_machineModules.remove(module)) {
      throw const ModuledMachineException(
          "Module must be in machine in order to be removed");
    }

    _calculateMultipliers();
  }

  void clearMachineModules() {
    if (_machineModules.isNotEmpty) {
      _machineModules.removeRange(0, _machineModules.length);
    }

    _calculateMultipliers();
  }

  void addBeaconModule(Beacon beacon, Module module) {
    if ((_beaconModules[beacon]?.length ?? 0) >= maxModules) {
      throw const ModuledMachineException(
          "Cannot apply more than $maxModules modules to a beacon");
    }

    if (!_machine.allowedModules.contains(module) ||
        !beacon.allowedModules.contains(module)) {
      throw ModuledMachineException(
          "Module '${module.name} is forbidden either by machine '${machine.name}' or beacon '${beacon.name}'");
    }

    _beaconModules.update(beacon, (modules) => modules..add(module),
        ifAbsent: () => SortedList(_compareModules)..add(module));

    _calculateMultipliers();
  }

  void removeBeaconModule(Beacon beacon, Module module) {
    if (!(_beaconModules[beacon]?.remove(module) ?? false)) {
      throw const ModuledMachineException(
          "Module must be applied to beacon in order to be removed");
    }

    if (_beaconModules[beacon]!.isEmpty) {
      _beaconModules.remove(beacon);
    }

    _calculateMultipliers();
  }

  void clearBeacon(Beacon beacon) {
    if (_beaconModules.remove(beacon) == null) {
      throw const ModuledMachineException(
          "Beacon must be present in order to be cleared");
    }

    _calculateMultipliers();
  }

  ImmutableModuledMachine createImmutableModuledMachine() {
    if (_edited) {
      _edited = false;
      _cachedMachine = ImmutableModuledMachine._fromRTMM(this);
    }

    return _cachedMachine;
  }

  void _calculateMultipliers() {
    // Create a map of module: counter
    // This also takes distributionEffectivity of beacons into account
    // I prefer doing this as opposed to straight incrementing as this reduces
    // floating point inaccuracies
    var allModules = <Module, double>{};

    for (var module in _machineModules) {
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

    // Apply machine base speed multiplier
    _multipliers[CraftingEffect.speed] =
        _multipliers[CraftingEffect.speed]! * _machine.baseSpeed;

    _edited = true;
  }

  bool get edited => _edited;
  @override
  CraftingMachine get machine => _machine;
  @override
  List<Module> get machineModules => _machineModulesView;
  @override
  Map<Beacon, List<Module>> get beaconModules => _beaconModulesView;
  @override
  Map<CraftingEffect, double> get multipliers => _multipliersView;
  @override
  double get moduledPowerConsumption =>
      _machine.powerConsumption *
      (multipliers[CraftingEffect.powerConsumption] ?? 1);
  @override
  double get moduledPollutionPerMin =>
      _machine.pollutionPerMin * (multipliers[CraftingEffect.pollution] ?? 1);
}
