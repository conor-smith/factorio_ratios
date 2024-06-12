import 'package:factorio_ratios/backend/factorio_objects/objects.dart';
import 'package:factorio_ratios/backend/base/moduled_machine.dart';
import 'package:test/test.dart';

import '../../test_item_context.dart';

void main() {
  initialiseTestContext();

  group("Test immutableModuledMachine", () {
    test("create immutableModuledMachine", () {
      var slowImmutable =
          ImmutableModuledMachine(craftingMachine0SlotsLowSpeed);

      expect(slowImmutable.machine, craftingMachine0SlotsLowSpeed);
      expect(slowImmutable.machineModules, isEmpty);
      expect(slowImmutable.beaconModules, isEmpty);
      expect(
          slowImmutable.multipliers,
          equals({
            CraftingEffect.speed: craftingMachine0SlotsLowSpeed.baseSpeed,
            CraftingEffect.productivity: 1.0,
            CraftingEffect.powerConsumption: 1.0,
            CraftingEffect.pollution: 1.0
          }));
      expect(slowImmutable.basePowerConsumption,
          craftingMachine0SlotsLowSpeed.powerConsumption);
      expect(slowImmutable.moduledPowerConsumption,
          craftingMachine0SlotsLowSpeed.powerConsumption);
      expect(
          slowImmutable.powerDrain, craftingMachine0SlotsLowSpeed.powerDrain);
      expect(slowImmutable.basePollutionPerMin,
          craftingMachine0SlotsLowSpeed.pollutionPerMin);
      expect(slowImmutable.moduledPollutionPerMin,
          craftingMachine0SlotsLowSpeed.pollutionPerMin);

      var normalImmutable =
          ImmutableModuledMachine(craftingMachineExclusive2SlotsNormalSpeed);

      expect(
          normalImmutable.multipliers,
          equals({
            CraftingEffect.speed:
                craftingMachineExclusive2SlotsNormalSpeed.baseSpeed,
            CraftingEffect.productivity: 1.0,
            CraftingEffect.powerConsumption: 1.0,
            CraftingEffect.pollution: 1.0
          }));
    });
  });

  group("Test realTimeModuledMachine", () {
    var normalImmutable =
        ImmutableModuledMachine(craftingMachineExclusive2SlotsNormalSpeed);

    test("edited field works", () {
      var rtb = normalImmutable.createRealTimeModuledMachine();

      expect(rtb.edited, isFalse);

      rtb.machine = craftingMachine0SlotsLowSpeed;

      expect(rtb.edited, isTrue);

      var newImmutable = rtb.createImmutableModuledMachine();

      expect(newImmutable, isNotNull);
      expect(rtb.edited, isFalse);
    });

    test("add and remove modules", () {
      var rtb = normalImmutable.createRealTimeModuledMachine();

      rtb
        ..addMachineModule(efficiencyModule)
        ..addMachineModule(efficiencyModule);
      expect(rtb.machineModules, equals([efficiencyModule, efficiencyModule]));

      rtb.removeMachineModule(efficiencyModule);
      expect(rtb.machineModules, equals([efficiencyModule]));

      rtb.addMachineModule(speedModule);
      expect(rtb.machineModules, containsAll([efficiencyModule, speedModule]));

      rtb.clearMachineModules();
      expect(rtb.machineModules, isEmpty);

      rtb
        ..addBeaconModule(beaconDefault, speedModule)
        ..addBeaconModule(beaconDistributionEffectivity, efficiencyModule)
        ..addBeaconModule(beaconDistributionEffectivity, efficiencyModule);
      expect(
          rtb.beaconModules,
          equals({
            beaconDefault: [speedModule],
            beaconDistributionEffectivity: [efficiencyModule, efficiencyModule]
          }));

      rtb.removeBeaconModule(beaconDistributionEffectivity, efficiencyModule);
      expect(
          rtb.beaconModules,
          equals({
            beaconDefault: [speedModule],
            beaconDistributionEffectivity: [efficiencyModule]
          }));

      rtb.clearBeacon(beaconDistributionEffectivity);
      expect(
          rtb.beaconModules,
          equals({
            beaconDefault: [speedModule]
          }));

      rtb.removeBeaconModule(beaconDefault, speedModule);
      expect(rtb.beaconModules, isEmpty);

      expect(() => rtb.removeBeaconModule(beaconDefault, speedModule),
          throwsException);
      expect(() => rtb.removeMachineModule(speedModule), throwsException);
    });

    test("calculate module multipliers", () {
      var rtb = normalImmutable.createRealTimeModuledMachine();
      expect(rtb.moduledPowerConsumption,
          craftingMachineExclusive2SlotsNormalSpeed.powerConsumption);
      expect(rtb.moduledPollutionPerMin,
          craftingMachineExclusive2SlotsNormalSpeed.pollutionPerMin);

      rtb
        ..addMachineModule(productivityModule)
        ..addMachineModule(productivityModule)
        ..addBeaconModule(beaconDefault, efficiencyModule)
        ..addBeaconModule(beaconDefault, efficiencyModule)
        ..addBeaconModule(beaconDefault, efficiencyModule)
        ..addBeaconModule(beaconDistributionEffectivity, speedModule);

      // effects = 2 * productivity module + 3 * efficiency module + 0.5 * speed module
      var newMultipliers = {
        CraftingEffect.speed: 1.0 +
            productivityModule.effects[CraftingEffect.speed]! * 2 +
            speedModule.effects[CraftingEffect.speed]! * 0.5,
        CraftingEffect.productivity:
            1.0 + productivityModule.effects[CraftingEffect.productivity]! * 2,
        CraftingEffect.powerConsumption: 1.0 +
            productivityModule.effects[CraftingEffect.powerConsumption]! * 2 +
            efficiencyModule.effects[CraftingEffect.powerConsumption]! * 3 +
            speedModule.effects[CraftingEffect.powerConsumption]! * 0.5,
        CraftingEffect.pollution:
            1.0 + productivityModule.effects[CraftingEffect.pollution]! * 2
      };

      expect(
          rtb.machineModules, equals([productivityModule, productivityModule]));
      expect(
          rtb.beaconModules,
          equals({
            beaconDefault: [
              efficiencyModule,
              efficiencyModule,
              efficiencyModule
            ],
            beaconDistributionEffectivity: [speedModule]
          }));

      // Accounting for small inaccuracies on account of double operations
      expect(rtb.multipliers[CraftingEffect.speed],
          closeTo(newMultipliers[CraftingEffect.speed]!, 0.001));
      expect(rtb.multipliers[CraftingEffect.productivity],
          closeTo(newMultipliers[CraftingEffect.productivity]!, 0.001));
      expect(rtb.multipliers[CraftingEffect.powerConsumption],
          closeTo(newMultipliers[CraftingEffect.powerConsumption]!, 0.001));
      expect(rtb.multipliers[CraftingEffect.pollution],
          closeTo(newMultipliers[CraftingEffect.pollution]!, 0.001));
      expect(rtb.basePowerConsumption,
          craftingMachineExclusive2SlotsNormalSpeed.powerConsumption);
      expect(
          rtb.moduledPowerConsumption,
          craftingMachineExclusive2SlotsNormalSpeed.powerConsumption *
              rtb.multipliers[CraftingEffect.powerConsumption]!);
      expect(rtb.basePollutionPerMin,
          craftingMachineExclusive2SlotsNormalSpeed.pollutionPerMin);
      expect(
          rtb.moduledPollutionPerMin,
          craftingMachineExclusive2SlotsNormalSpeed.pollutionPerMin *
              rtb.multipliers[CraftingEffect.pollution]!);
    });

    test("calculate machine multipliers", () {
      var rtb = normalImmutable.createRealTimeModuledMachine();

      rtb.machine = craftingMachine0SlotsLowSpeed;

      expect(rtb.multipliers[CraftingEffect.speed],
          craftingMachine0SlotsLowSpeed.baseSpeed);

      rtb.addBeaconModule(beaconDefault, speedModule);

      expect(
          rtb.multipliers[CraftingEffect.speed],
          craftingMachine0SlotsLowSpeed.baseSpeed *
              (1.0 + speedModule.effects[CraftingEffect.speed]!));
    });

    test("multipliers do not drop below min value", () {
      var rtb = normalImmutable.createRealTimeModuledMachine();

      rtb.machine = craftingMachine0SlotsLowSpeed;

      rtb.addBeaconModule(beaconDefault, impossibleModule);

      // Speed minimum = 0.2 * machine base speed
      // TODO: Confirm minimum pollution
      expect(
          rtb.multipliers,
          equals({
            CraftingEffect.speed: craftingMachine0SlotsLowSpeed.baseSpeed * 0.2,
            CraftingEffect.productivity: 1.0,
            CraftingEffect.powerConsumption: 0.2,
            CraftingEffect.pollution: 1.0
          }));
    });

    test("machine modules does not exceed maximum amount", () {
      var rtb = normalImmutable.createRealTimeModuledMachine();

      rtb.addMachineModule(speedModule);
      rtb.addMachineModule(speedModule);

      expect(() => rtb.addMachineModule(speedModule), throwsException);

      rtb.machine = craftingMachine0SlotsLowSpeed;

      expect(rtb.machineModules, isEmpty);
      expect(() => rtb.addMachineModule(speedModule), throwsException);
    });

    test("beacon modules do not exceed maximum amount", () {
      var rtb = normalImmutable.createRealTimeModuledMachine();

      for (var i = 0; i < maxModules; i++) {
        rtb.addBeaconModule(beaconDefault, speedModule);
      }

      expect(() => rtb.addBeaconModule(beaconDefault, speedModule),
          throwsException);

      // Should execute without issue
      rtb.addBeaconModule(beaconDistributionEffectivity, speedModule);
    });

    test("machine and modules allowed effects", () {
      var rtb = normalImmutable.createRealTimeModuledMachine();

      // Executes without issue
      rtb.addBeaconModule(beaconAllowedEffects, efficiencyModule);
      expect(
          () => rtb.addBeaconModule(beaconAllowedEffects, productivityModule),
          throwsException);

      rtb.clearBeacon(beaconAllowedEffects);

      rtb
        ..addMachineModule(productivityModule)
        ..addMachineModule(speedModule)
        ..addBeaconModule(beaconDefault, productivityModule)
        ..addBeaconModule(beaconDefault, speedModule);

      expect(rtb.machineModules, contains(productivityModule));
      expect(rtb.beaconModules[beaconDefault], contains(productivityModule));

      // Removes forbidden modules upon machine change
      rtb.machine = craftingMachineAllowedEffects4SlotsHighSpeed;
      expect(rtb.machineModules.contains(productivityModule), isFalse);
      expect(rtb.beaconModules[beaconDefault]!.contains(productivityModule),
          isFalse);

      expect(() => rtb.addMachineModule(productivityModule), throwsException);
      expect(() => rtb.addBeaconModule(beaconDefault, productivityModule),
          throwsException);
    });
  });
}
