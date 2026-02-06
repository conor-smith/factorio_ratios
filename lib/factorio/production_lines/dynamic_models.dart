part of '../production_line.dart';

class ItemData {
  final Item item;
  final int? quality;
  final double? temperature;

  ItemData._(this.item, this.quality, this.temperature);

  factory ItemData(Item item, {int? quality, double? temperature}) {
    switch (item.type) {
      case ItemType.item:
        if (temperature != null) {
          throw FactorioException(
            'Temperature not applicable to item "${item.name}"',
          );
        }

        quality ??= 1;
        break;
      case ItemType.fluid:
        if (quality != null) {
          throw FactorioException(
            'Quality not applicable to fluid "${item.name}"',
          );
        }

        temperature ??= (item as FluidItem).defaultTemperature;
    }

    return ItemData._(item, quality, temperature);
  }

  // + 20 is ensures that a fluid item of temperature 0 returns a different hashcode
  @override
  int get hashCode => item.hashCode + 20 + (quality ?? temperature!.toInt());

  @override
  bool operator ==(Object other) =>
      other is ItemData && hashCode == other.hashCode;
}

class QualityRecipe {
  final Recipe recipe;
  final int quality;

  QualityRecipe(this.recipe, {this.quality = 1});

  @override
  int get hashCode => recipe.hashCode + quality;

  @override
  bool operator ==(Object other) =>
      other is QualityRecipe && hashCode == other.hashCode;
}

class ModuledMachine with ModuledMachineMixin {
  CraftingMachine craftingMachine;

  ModuledMachine(this.craftingMachine);
}

mixin ModuledMachineMixin {}
