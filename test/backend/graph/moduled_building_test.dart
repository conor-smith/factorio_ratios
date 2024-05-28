import 'package:factorio_ratios/backend/factorio_objects/objects.dart';
import 'package:factorio_ratios/backend/graph/moduled_building.dart';
import 'package:test/test.dart';

import '../../test_item_context.dart';

void main() {
  initialiseTestContext();

  group("Test immutableModuledBuilding", () {
    test("create immutableModuledBuilding", () {
      var slowImmutable =
          ImmutableModuledBuilding(craftingBuilding0SlotsLowSpeed);

      expect(slowImmutable.building, craftingBuilding0SlotsLowSpeed);
      expect(slowImmutable.buildingModules, isEmpty);
      expect(slowImmutable.beaconModules, isEmpty);
      expect(
          slowImmutable.multipliers,
          equals({
            CraftingEffect.speed: craftingBuilding0SlotsLowSpeed.baseSpeed,
            CraftingEffect.productivity: 1.0,
            CraftingEffect.consumption: 1.0,
            CraftingEffect.pollution: 1.0
          }));

      var normalImmutable =
          ImmutableModuledBuilding(craftingBuildingExclusive2SlotsNormalSpeed);

      expect(
          normalImmutable.multipliers,
          equals({
            CraftingEffect.speed:
                craftingBuildingExclusive2SlotsNormalSpeed.baseSpeed,
            CraftingEffect.productivity: 1.0,
            CraftingEffect.consumption: 1.0,
            CraftingEffect.pollution: 1.0
          }));
    });
  });

  group("Test realTimeModuledBuilding", () {
    var normalImmutable =
        ImmutableModuledBuilding(craftingBuildingExclusive2SlotsNormalSpeed);

    test("edited field works", () {
      var rtb = normalImmutable.createRealTimeModuledBuilding();

      expect(rtb.edited, isFalse);

      rtb.building = craftingBuilding0SlotsLowSpeed;

      expect(rtb.edited, isTrue);

      var newImmutable = rtb.createImmutableModuledBuilding();

      expect(newImmutable, isNotNull);
      expect(rtb.edited, isFalse);
    });

    test("add and remove modules", () {
      var rtb = normalImmutable.createRealTimeModuledBuilding();

      rtb
        ..addBuildingModule(efficiencyModule)
        ..addBuildingModule(efficiencyModule);
      expect(rtb.buildingModules, equals([efficiencyModule, efficiencyModule]));

      rtb.removeBuildingModule(efficiencyModule);
      expect(rtb.buildingModules, equals([efficiencyModule]));

      rtb.addBuildingModule(speedModule);
      expect(rtb.buildingModules, containsAll([efficiencyModule, speedModule]));

      rtb.clearBuildingModules();
      expect(rtb.buildingModules, isEmpty);

      rtb
        ..addBeaconModule(beacon, speedModule)
        ..addBeaconModule(beaconDistributionEffectivity, efficiencyModule)
        ..addBeaconModule(beaconDistributionEffectivity, efficiencyModule);
      expect(
          rtb.beaconModules,
          equals({
            beacon: [speedModule],
            beaconDistributionEffectivity: [efficiencyModule, efficiencyModule]
          }));

      rtb.removeBeaconModule(beaconDistributionEffectivity, efficiencyModule);
      expect(
          rtb.beaconModules,
          equals({
            beacon: [speedModule],
            beaconDistributionEffectivity: [efficiencyModule]
          }));

      rtb.clearBeacon(beaconDistributionEffectivity);
      expect(
          rtb.beaconModules,
          equals({
            beacon: [speedModule]
          }));

      rtb.removeBeaconModule(beacon, speedModule);
      expect(rtb.beaconModules, isEmpty);

      expect(
          () => rtb.removeBeaconModule(beacon, speedModule), throwsException);
      expect(() => rtb.removeBuildingModule(speedModule), throwsException);
    });

    test("calculate module multipliers", () {
      var rtb = normalImmutable.createRealTimeModuledBuilding();

      rtb
        ..addBuildingModule(productivityModule)
        ..addBuildingModule(productivityModule)
        ..addBeaconModule(beacon, efficiencyModule)
        ..addBeaconModule(beacon, efficiencyModule)
        ..addBeaconModule(beacon, efficiencyModule)
        ..addBeaconModule(beaconDistributionEffectivity, speedModule);

      // effects = 2 * productivity module + 3 * efficiency module + 0.5 * speed module
      var newMultipliers = {
        CraftingEffect.speed: 1.0 +
            productivityModule.effects[CraftingEffect.speed]! * 2 +
            speedModule.effects[CraftingEffect.speed]! * 0.5,
        CraftingEffect.productivity:
            1.0 + productivityModule.effects[CraftingEffect.productivity]! * 2,
        CraftingEffect.consumption: 1.0 +
            productivityModule.effects[CraftingEffect.consumption]! * 2 +
            efficiencyModule.effects[CraftingEffect.consumption]! * 3 +
            speedModule.effects[CraftingEffect.consumption]! * 0.5,
        CraftingEffect.pollution:
            1.0 + productivityModule.effects[CraftingEffect.pollution]! * 2
      };

      expect(rtb.buildingModules,
          equals([productivityModule, productivityModule]));
      expect(
          rtb.beaconModules,
          equals({
            beacon: [efficiencyModule, efficiencyModule, efficiencyModule],
            beaconDistributionEffectivity: [speedModule]
          }));

      // Accounting for small inaccuracies on account of double operations
      expect(rtb.multipliers[CraftingEffect.speed],
          closeTo(newMultipliers[CraftingEffect.speed]!, 0.001));
      expect(rtb.multipliers[CraftingEffect.productivity],
          closeTo(newMultipliers[CraftingEffect.productivity]!, 0.001));
      expect(rtb.multipliers[CraftingEffect.consumption],
          closeTo(newMultipliers[CraftingEffect.consumption]!, 0.001));
      expect(rtb.multipliers[CraftingEffect.pollution],
          closeTo(newMultipliers[CraftingEffect.pollution]!, 0.001));
    });

    test("calculate building multipliers", () {
      var rtb = normalImmutable.createRealTimeModuledBuilding();

      rtb.building = craftingBuilding0SlotsLowSpeed;

      expect(rtb.multipliers[CraftingEffect.speed],
          craftingBuilding0SlotsLowSpeed.baseSpeed);

      rtb.addBeaconModule(beacon, speedModule);

      expect(
          rtb.multipliers[CraftingEffect.speed],
          craftingBuilding0SlotsLowSpeed.baseSpeed *
              (1.0 + speedModule.effects[CraftingEffect.speed]!));
    });

    test("multipliers do not drop below min value", () {
      var rtb = normalImmutable.createRealTimeModuledBuilding();

      rtb.building = craftingBuilding0SlotsLowSpeed;

      rtb.addBeaconModule(beacon, impossibleModule);

      // Speed minimum = 0.2 * building base speed
      // TODO: Confirm minimum pollution
      expect(
          rtb.multipliers,
          equals({
            CraftingEffect.speed:
                craftingBuilding0SlotsLowSpeed.baseSpeed * 0.2,
            CraftingEffect.productivity: 1.0,
            CraftingEffect.consumption: 0.2,
            CraftingEffect.pollution: 1.0
          }));
    });

    test("building modules does not exceed maximum amount", () {
      var rtb = normalImmutable.createRealTimeModuledBuilding();

      rtb.addBuildingModule(speedModule);
      rtb.addBuildingModule(speedModule);

      expect(() => rtb.addBuildingModule(speedModule), throwsException);

      rtb.building = craftingBuilding0SlotsLowSpeed;

      expect(rtb.buildingModules, isEmpty);
      expect(() => rtb.addBuildingModule(speedModule), throwsException);
    });

    test("beacon modules do not exceed maximum amount", () {
      var rtb = normalImmutable.createRealTimeModuledBuilding();

      for (var i = 0; i < maxModules; i++) {
        rtb.addBeaconModule(beacon, speedModule);
      }

      expect(() => rtb.addBeaconModule(beacon, speedModule), throwsException);

      // Should execute without issue
      rtb.addBeaconModule(beaconDistributionEffectivity, speedModule);
    });

    test("building and modules allowed effects", () {
      var rtb = normalImmutable.createRealTimeModuledBuilding();

      // Executes without issue
      rtb.addBeaconModule(beaconAllowedEffects, efficiencyModule);
      expect(
          () => rtb.addBeaconModule(beaconAllowedEffects, productivityModule),
          throwsException);

      rtb.clearBeacon(beaconAllowedEffects);

      rtb
        ..addBuildingModule(productivityModule)
        ..addBuildingModule(speedModule)
        ..addBeaconModule(beacon, productivityModule)
        ..addBeaconModule(beacon, speedModule);

      expect(rtb.buildingModules, contains(productivityModule));
      expect(rtb.beaconModules[beacon], contains(productivityModule));

      // Removes forbidden modules upon building change
      rtb.building = craftingBuildingAllowedEffects4SlotsHighSpeed;
      expect(rtb.buildingModules.contains(productivityModule), isFalse);
      expect(rtb.beaconModules[beacon]!.contains(productivityModule), isFalse);

      expect(() => rtb.addBuildingModule(productivityModule), throwsException);
      expect(() => rtb.addBeaconModule(beacon, productivityModule),
          throwsException);
    });
  });
}
