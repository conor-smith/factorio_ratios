part of '../production_line.dart';

class ItemData {
  final Item item;
  final int? quality;
  final double? temperature;

  ItemData._(this.item, this.quality, this.temperature);

  factory ItemData(Item item, {int? quality, double? temperature}) {
    if (item.type == 'fluid') {
      if (quality != null) {
        throw FactorioException(
          'Quality not applicable to fluid "${item.name}"',
        );
      }

      temperature ??= (item as FluidItem).defaultTemperature;
    } else {
      if (temperature != null) {
        throw FactorioException(
          'Temperature not applicable to item "${item.name}"',
        );
      }

      quality ??= 1;
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

abstract class ModuledMachineAndRecipe {
  CraftingMachine get craftingMachine;
  Recipe? get recipe;
  ItemData? get fuel;
  double get totalCraftingSpeed;
  double get totalProductivity;
  double get totalEnergyUsage;
  Map<String, double> get totalEmissionsPerMinute;
  Map<ItemData, double> get totalIoPerSecond;
}

class MutableModuledMachineAndRecipe implements ModuledMachineAndRecipe {
  /*
   * TODO
   * FluidEnergySource
   * Quality machine, fuel, recipe, and multiplier
   * Modules
   */
  CraftingMachine _craftingMachine;
  Recipe? _recipe;
  ItemData? _fuel;

  double _totalCraftingSpeed;
  double _totalProductivity;
  double _totalEnergyUsage;
  final Map<String, double> _totalEmissionsPerMinute;
  final Map<ItemData, double> _totalIoPerSecond;

  // Initially false. Only set to true during first call of .update(...)
  bool _initialised;

  // Immutable instance is cached as there's no need to generate
  // a new instance if this object is unchanged
  ImmutableModuledMachineAndRecipe? _cachedImmutable;

  @override
  CraftingMachine get craftingMachine => _craftingMachine;
  @override
  Recipe? get recipe => _recipe;
  @override
  ItemData? get fuel => _fuel;
  @override
  double get totalCraftingSpeed => _totalCraftingSpeed;
  @override
  double get totalProductivity => _totalProductivity;
  @override
  double get totalEnergyUsage => _totalEnergyUsage;
  @override
  late final Map<String, double> totalEmissionsPerMinute = UnmodifiableMapView(
    _totalEmissionsPerMinute,
  );
  @override
  late final Map<ItemData, double> totalIoPerSecond = UnmodifiableMapView(
    _totalIoPerSecond,
  );

  MutableModuledMachineAndRecipe({
    required CraftingMachine craftingMachine,
    Recipe? recipe,
    ItemData? fuel,
  }) : _craftingMachine = craftingMachine,
       _totalCraftingSpeed = 0,
       _totalProductivity = 0,
       _totalEnergyUsage = 0,
       _totalEmissionsPerMinute = {},
       _totalIoPerSecond = {},
       _initialised = false {
    update(newRecipe: recipe, newMachine: craftingMachine, newFuel: fuel);
  }

  MutableModuledMachineAndRecipe._from(ModuledMachineAndRecipe other)
    : _craftingMachine = other.craftingMachine,
      _recipe = other.recipe,
      _fuel = other.fuel,
      _totalCraftingSpeed = other.totalCraftingSpeed,
      _totalProductivity = other.totalProductivity,
      _totalEnergyUsage = other.totalEnergyUsage,
      _totalEmissionsPerMinute = Map.from(other.totalEmissionsPerMinute),
      _totalIoPerSecond = Map.from(other.totalIoPerSecond),
      _initialised = true;

  void update({
    Recipe? newRecipe,
    CraftingMachine? newMachine,
    ItemData? newFuel,
  }) {
    // Determine if an update has occurred for each field
    // If _initialised == false, all fields are considered updated
    bool recipeUpdate = newRecipe != _recipe || !_initialised;
    bool machineUpdate = newMachine != _craftingMachine || !_initialised;
    bool fuelUpdate = newFuel != _fuel || !_initialised;

    newRecipe ??= _recipe;
    newMachine ??= _craftingMachine;

    _initialised = true;

    // If either fuel or machine has been updated
    // Check if fuel or lack thereof is compatible
    if (machineUpdate || fuelUpdate) {
      if (newMachine.energySource.type == EnergySourceType.burner) {
        // Machine requries fuel. Check if fuel is compatible
        newFuel ??= _fuel;

        BurnerEnergySource energySource =
            craftingMachine.energySource as BurnerEnergySource;

        if (newFuel == null) {
          throw FactorioException(
            'Crafting machine "$newMachine" requires fuel',
          );
        } else if (!energySource.fuelItems.contains(newFuel.item)) {
          throw FactorioException(
            'Crafting machine "$newMachine" cannot use item "$newFuel" as fuel',
          );
        }
      } else if (newFuel != null) {
        // Will only get here if machine does not require fuel
        // In which case, no fuel should be provided
        throw FactorioException(
          'Crafting machine "$newMachine" does not require fuel',
        );
      }
    }

    // If recipe or fuel have been updated
    // Check if recipe is compatible with machine
    if ((recipeUpdate || machineUpdate) &&
        newRecipe != null &&
        !newRecipe.craftingMachines.contains(newMachine)) {
      throw FactorioException(
        'Crafting machine "$newMachine" cannot craft recipe $newRecipe',
      );
    }

    if (recipeUpdate || machineUpdate || fuelUpdate) {
      _craftingMachine = newMachine;
      _fuel = newFuel;
      _recipe = newRecipe;

      _internalUpdate();
    }
  }

  void clearRecipe() {
    if (_recipe != null) {
      _recipe = null;

      _internalUpdate();
    }
  }

  ImmutableModuledMachineAndRecipe makeImmutable() {
    if (_recipe == null) {
      throw const FactorioException(
        'Must set a recipe before creating immutable version',
      );
    }

    _cachedImmutable ??= ImmutableModuledMachineAndRecipe._from(this);

    return _cachedImmutable!;
  }

  void _internalUpdate() {
    // Clear cached immutable
    _cachedImmutable = null;

    // Do the math
    double fuelEmissionsMultiplier =
        (_fuel as SolidItem?)?.fuelEmissionsMultiplier ?? 1;
    double recipeEmissionsMultiplier = _recipe?.emissionsMultiplier ?? 1;
    double recipeMaxProductivity =
        _recipe?.maximumProductivity ?? double.infinity;

    double speedMultiplier =
        1 + craftingMachine.effectReceiver.baseEffect.speed;
    double productivityMultiplier =
        1 + craftingMachine.effectReceiver.baseEffect.productivity;
    double pollutionMultiplier =
        (1 + craftingMachine.effectReceiver.baseEffect.pollution) *
        fuelEmissionsMultiplier *
        recipeEmissionsMultiplier;
    double energyMultiplier =
        1 + craftingMachine.effectReceiver.baseEffect.consumption;

    // Multipliers have minimum values. Reset to minimum if lower
    speedMultiplier = speedMultiplier >= 0.2 ? speedMultiplier : 0.2;
    productivityMultiplier = productivityMultiplier >= 1
        ? productivityMultiplier
        : 1;
    productivityMultiplier = productivityMultiplier <= recipeMaxProductivity
        ? productivityMultiplier
        : recipeMaxProductivity;
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

    _totalIoPerSecond.clear();

    if (_recipe != null) {
      double recipesPerSecond = _recipe!.energyRequired / _totalCraftingSpeed;

      // TODO - Account for quality outputs
      for (var ingredient in _recipe!.ingredients) {
        _totalIoPerSecond[ItemData(ingredient.item)] =
            -ingredient.amount * recipesPerSecond;
      }

      for (var result in _recipe!.results) {
        var itemData = ItemData(result.item);
        var netOutput =
            result.amount * result.probability * recipesPerSecond -
            (_totalIoPerSecond[itemData] ?? 0);
        netOutput = _recipe!.allowProductivity
            ? netOutput * _totalProductivity
            : netOutput;

        _totalIoPerSecond[itemData] = netOutput;
      }

      if (_fuel != null) {
        double fuelPerSecond = totalEnergyUsage / _fuel!.item.fuelValue!;
        _totalIoPerSecond.update(
          _fuel!,
          (amount) => amount - fuelPerSecond,
          ifAbsent: () => -fuelPerSecond,
        );
      }
    }
  }
}

// Recipe will always be present
class ImmutableModuledMachineAndRecipe implements ModuledMachineAndRecipe {
  @override
  final CraftingMachine craftingMachine;
  @override
  final Recipe? recipe;
  @override
  final ItemData? fuel;
  @override
  final double totalCraftingSpeed;
  @override
  final double totalProductivity;
  @override
  final double totalEnergyUsage;
  @override
  final Map<String, double> totalEmissionsPerMinute;
  @override
  final Map<ItemData, double> totalIoPerSecond;

  ImmutableModuledMachineAndRecipe._from(MutableModuledMachineAndRecipe mutable)
    : craftingMachine = mutable._craftingMachine,
      recipe = mutable._recipe!,
      fuel = mutable._fuel,
      totalCraftingSpeed = mutable._totalCraftingSpeed,
      totalProductivity = mutable._totalCraftingSpeed,
      totalEnergyUsage = mutable._totalEnergyUsage,
      totalEmissionsPerMinute = Map.unmodifiable(
        mutable._totalEmissionsPerMinute,
      ),
      totalIoPerSecond = Map.unmodifiable(mutable._totalIoPerSecond);

  MutableModuledMachineAndRecipe getMutable() =>
      MutableModuledMachineAndRecipe._from(this);
}
