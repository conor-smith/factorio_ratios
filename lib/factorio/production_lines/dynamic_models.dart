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

  @override
  String toString() => item.toString();
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

  @override
  String toString() => recipe.toString();
}

class ModuledMachine {
  // TODO - Actually account for modules
  // TODO - Quality
  final CraftingMachine craftingMachine;

  double _totalCraftingSpeed = 0;
  double _totalProductivity = 0;
  double _totalEnergyUsage = 0;
  final Map<String, double> _totalEmissionsPerMinute;

  ModuledMachine(this.craftingMachine)
    : _totalEmissionsPerMinute = Map.from(
        craftingMachine.energySource.emissionsPerMinute,
      ) {
    _update();
  }

  double get totalCraftingSpeed => _totalCraftingSpeed;
  double get totalProductivity => _totalProductivity;
  double get totalEnergyUsage => _totalEnergyUsage;
  late final Map<String, double> totalEmissionsPerMinute = UnmodifiableMapView(
    _totalEmissionsPerMinute,
  );

  void _update() {
    double speedMultiplier =
        1 + craftingMachine.effectReceiver.baseEffect.speed;
    double productivityMultiplier =
        1 + craftingMachine.effectReceiver.baseEffect.productivity;
    double pollutionMultiplier =
        1 + craftingMachine.effectReceiver.baseEffect.pollution;
    double energyMultiplier =
        1 + craftingMachine.effectReceiver.baseEffect.consumption;

    speedMultiplier = speedMultiplier >= 0.2 ? speedMultiplier : 0.2;
    productivityMultiplier = productivityMultiplier >= 1
        ? productivityMultiplier
        : 1;
    pollutionMultiplier = pollutionMultiplier >= 0.2
        ? pollutionMultiplier
        : 0.2;
    energyMultiplier = energyMultiplier >= 0.2 ? energyMultiplier : 0.2;

    _totalCraftingSpeed = craftingMachine.craftingSpeed * speedMultiplier;
    _totalProductivity = productivityMultiplier;
    _totalEnergyUsage = craftingMachine.energyUsage * energyMultiplier;
    craftingMachine.energySource.emissionsPerMinute.forEach(
      (emission, amount) =>
          _totalEmissionsPerMinute[emission] = amount * pollutionMultiplier,
    );
  }

  @override
  String toString() => craftingMachine.toString();
}
