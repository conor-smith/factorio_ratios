import 'package:factorio_ratios/backend/factorio_objects/objects.dart';
import 'package:factorio_ratios/backend/graph/moduled_building.dart';
import 'package:test/test.dart';

import '../../test_item_context.dart';

void main() {
  var context = testContext;

  test("create moduledBuilding", () {
    var slowImmutable =
        ImmutableModuledBuilding(craftingBuilding0SlotsLowSpeed);

    expect(slowImmutable.building, craftingBuilding0SlotsLowSpeed);
    expect(slowImmutable.buildingModules, equals(const {}));
    expect(slowImmutable.beaconModules, equals(const {}));
    expect(
        slowImmutable.multipliers,
        equals({
          CraftingEffect.speed: craftingBuilding0SlotsLowSpeed.baseSpeed,
          CraftingEffect.productivity: 1.0,
          CraftingEffect.consumption: 1.0,
          CraftingEffect.pollution: 1.0
        }));

    var normalImmutable =
        ImmutableModuledBuilding(craftingBuildingExclusive2SlotsNormalSPeed);

    expect(
        normalImmutable.multipliers,
        equals({
          CraftingEffect.speed:
              craftingBuildingExclusive2SlotsNormalSPeed.baseSpeed,
          CraftingEffect.productivity: 1.0,
          CraftingEffect.consumption: 1.0,
          CraftingEffect.pollution: 1.0
        }));
  });
}
