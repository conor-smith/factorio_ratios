part of 'production_line.dart';

class InGameCraftingMachine {
  // TODO - modules
  CraftingMachine _internalMachine;
  int _machineQuality;
  Surface? _surface;
  RecipeWithQuality? _recipe;
  InGameItem? _fuel;

  late SingleCraftingMachineDataBreakdown _dataBreakdown;

  InGameCraftingMachine({
    required CraftingMachine machine,
    int quality = 1,
    Surface? surface,
    RecipeWithQuality? recipe,
    InGameItem? fuel,
  }) : _internalMachine = machine,
       _machineQuality = quality,
       _surface = surface,
       _recipe = recipe,
       _fuel = fuel {
    if (!_verifyMachineAndRecipe(_internalMachine, _recipe!)) {
      throw FactorioException(
        'Machine $_internalMachine is incompatible with recipe $_recipe',
      );
    } else if (!_verifyMachineAndFuel(_internalMachine, _fuel!)) {
      throw FactorioException(
        'Machine $_internalMachine is incompatible with fuel $_fuel',
      );
    } else if (!_verifyRecipeAndSurface(_recipe!, _surface!)) {
      throw FactorioException(
        'Recipe $_recipe cannot be crafted on surface $_surface',
      );
    }

    _calculate();
  }

  CraftingMachine get internalMachine => _internalMachine;
  int get machineQuality => _machineQuality;
  Surface? get surface => _surface;
  RecipeWithQuality? get recipe => _recipe;
  InGameItem? get fuel => _fuel;
  SingleCraftingMachineDataBreakdown get dataBreakdown => _dataBreakdown;

  @override
  double get energyUsage => _dataBreakdown.finalPowerConsumption;
  @override
  double get craftingSpeed => _dataBreakdown.finalCraftingSpeed;

  @override
  List<String> get allowedEffects => _internalMachine.allowedEffects;
  @override
  bool get needsFuel => _internalMachine.needsFuel;
  @override
  List<String> get craftingCategories => _internalMachine.craftingCategories;
  @override
  EffectReceiver get effectReceiver => _internalMachine.effectReceiver;
  @override
  CraftingMachineEnergySource get energySource => _internalMachine.energySource;
  @override
  FactorioDatabase get factorioDb => _internalMachine.factorioDb;
  @override
  String get localisedName => _internalMachine.localisedName;
  @override
  int get moduleSlots => _internalMachine.moduleSlots;
  @override
  String get name => _internalMachine.name;
  @override
  List<Recipe> get recipes => _internalMachine.recipes;

  bool verifyAndSetMachine(CraftingMachine newMachine, [int? newQuality]) {
    newQuality ??= _machineQuality;

    bool existingFuelValid = _verifyMachineAndFuel(newMachine, _fuel);
    bool existingRecipeValid = _verifyMachineAndRecipe(newMachine, _recipe);
    bool valid = machineQuality >= 1 && machineQuality <= 5;

    if (valid) {
      _internalMachine = newMachine;
      _fuel = existingFuelValid ? _fuel : null;
      _recipe = existingRecipeValid ? _recipe : null;
      _calculate();
    }

    return valid;
  }

  bool verifyAndSetRecipe(RecipeWithQuality newRecipe) {
    bool valid =
        _verifyMachineAndRecipe(_internalMachine, newRecipe) &&
        _verifyRecipeAndSurface(newRecipe, _surface);

    if (valid) {
      _recipe = newRecipe;
      _calculate();
    }

    return valid;
  }

  bool verifyAndSetSurface(Surface newSurface) {
    bool valid = _verifyRecipeAndSurface(_recipe, newSurface);

    if (valid) {
      _surface = newSurface;
      _calculate();
    }

    return valid;
  }

  bool verifyAndSetFuel(InGameItem newFuel) {
    bool valid = _verifyMachineAndFuel(_internalMachine, newFuel);

    if (valid) {
      _fuel = newFuel;
      _calculate();
    }

    return valid;
  }

  void clearRecipe() {
    _recipe = null;
    _calculate();
  }

  void clearSurface() {
    _surface = null;
    _calculate();
  }

  void clearFuel() {
    _fuel = null;
    _calculate();
  }

  bool reset({
    required CraftingMachine newMachine,
    int newQuality = 1,
    Surface? newSurface,
    RecipeWithQuality? newRecipe,
    InGameItem? newFuel,
  }) {
    bool valid =
        _verifyMachineAndRecipe(newMachine, newRecipe) &&
        _verifyMachineAndFuel(newMachine, newFuel) &&
        _verifyRecipeAndSurface(newRecipe, newSurface);

    if (valid) {
      _internalMachine = newMachine;
      _machineQuality = newQuality;
      _recipe = newRecipe;
      _fuel = newFuel;
      _surface = newSurface;
      _calculate();
    }

    return valid;
  }

  bool _verifyMachineAndRecipe(
    CraftingMachine machine,
    RecipeWithQuality? recipe,
  ) => recipe == null || machine.recipes.contains(recipe.internalRecipe);

  bool _verifyMachineAndFuel(CraftingMachine machine, InGameItem? fuel) {
    var energySource = machine.energySource;

    if (energySource is BurnerEnergySource) {
      return energySource.fuelItems.contains(fuel?.internalItem);
    } else {
      return true;
    }
  }

  bool _verifyRecipeAndSurface(RecipeWithQuality? recipe, Surface? surface) =>
      recipe == null ||
      surface == null ||
      recipe.internalRecipe.surfaces.contains(surface);

  void _calculate() {}
}

class SingleCraftingMachineDataBreakdown {
  final CraftingMachine craftingMachine;
  final int machineQuality;
  final Surface? surface;
  final RecipeWithQuality? recipe;
  final InGameItem? fuel;

  final double finalCraftingSpeed;
  double get baseCraftingSpeed => craftingMachine.craftingSpeed;

  final double finalPowerConsumption;
  double get basePowerConsumption => craftingMachine.energyUsage;

  final Map<String, double> finalEmissionsPerMinute;
  Map<String, double> get baseEmissions =>
      craftingMachine.energySource.emissionsPerMinute;

  final double? recipesPerSecond;
  final ItemIo? recipeInput;
  final ItemIo? recipeOutput;
  final ItemIo? fuelInput;
  final ItemIo? burntOutput;
  final Set<InGameItem> possibleSpoilage;
  final ItemIo? netIo;

  final double? finalProductivityBonus;
  final double? totalProductivityBonus;
  final double? maxProductivityBonus;
  final double? machineBaseProductivityBonus;

  final double? finalSpeedBonus;
  final double? totalSpeedBonus;
  final double? machineBaseSpeedBonus;

  final double? finalPollutionBonus;
  final double? totalPollutionBonus;
  final double? machineBasePollutionBonus;
  final double? recipePollutionBonus;
  final double? fuelPollutionBonus;

  final double? finalConsumptionBonus;
  final double? totalConsumptionBonus;
  final double? machineBaseConsumptionBonus;

  factory SingleCraftingMachineDataBreakdown.calculate(
    CraftingMachine craftingMachine,
    int machineQuality, {
    Surface? surface,
    RecipeWithQuality? recipe,
    InGameItem? fuel,
  }) {
    // Calculate productivity multiplier
    double machineBaseProductivityBonus =
        craftingMachine.effectReceiver.baseEffect.productivity;
    double totalProductivityBonus = machineBaseProductivityBonus;
    // TODO - determine if recipe value is for bonus or for multiplier
    double? maxProductivityBonus = recipe?.maximumProductivity;
    double finalProductivityBonus =
        maxProductivityBonus == null ||
            totalProductivityBonus < maxProductivityBonus
        ? totalProductivityBonus
        : maxProductivityBonus;
    double productivityMultiplier =
        Effects.productivity.defaultMultiplier + finalProductivityBonus;

    // Calculate speed multiplier
    double machineBaseSpeedBonus =
        craftingMachine.effectReceiver.baseEffect.speed;
    double totalSpeedBonus = machineBaseSpeedBonus;
    double finalSpeedBonus = totalSpeedBonus;
    double speedMultiplier = Effects.speed.defaultMultiplier + finalSpeedBonus;
    if (speedMultiplier < Effects.speed.minMultiplier) {
      speedMultiplier = Effects.speed.minMultiplier;
      finalSpeedBonus =
          Effects.speed.minMultiplier - Effects.speed.defaultMultiplier;
    }

    // Calculate pollution multiplier
    double machineBasePollutionBonus =
        craftingMachine.effectReceiver.baseEffect.pollution;
    double recipePollutionBonus = 1 - (recipe?.emissionsMultiplier ?? 1);
    double fuelPollutionBonus;
    if (fuel != null && fuel is SolidItemWithQuality) {
      // TODO - account for liquid fuels
      fuelPollutionBonus = 1 - (fuel.fuelEmissionsMultiplier ?? 1);
    } else {
      fuelPollutionBonus = 0;
    }
    double totalPollutionBonus =
        machineBasePollutionBonus + recipePollutionBonus + fuelPollutionBonus;
    double finalPollutionBonus = totalPollutionBonus;
    double pollutionMultiplier =
        Effects.pollution.defaultMultiplier + finalPollutionBonus;

    // Calculate consumption multiplier
    double machineBaseConsumptionBonus =
        craftingMachine.effectReceiver.baseEffect.consumption;
    double totalConsumptionBonus = machineBaseConsumptionBonus;
    double finalConsumptionBonus = totalConsumptionBonus;
    double consumptionMultiplier =
        Effects.consumption.defaultMultiplier + finalConsumptionBonus;
    if (consumptionMultiplier < Effects.consumption.minMultiplier) {
      consumptionMultiplier = Effects.consumption.minMultiplier;
      finalConsumptionBonus =
          Effects.consumption.minMultiplier -
          Effects.consumption.defaultMultiplier;
    }

    // Calculate machine information
    double finalCraftingSpeed = craftingMachine.craftingSpeed * speedMultiplier;
    double finalPowerConsumption =
        craftingMachine.energyUsage * consumptionMultiplier;
    // TODO - determine which pollution is allowed on what surface
    Map<String, double> finalEmissionsPerMinute = Map.unmodifiable(
      craftingMachine.energySource.emissionsPerMinute.map(
        (key, value) => MapEntry(key, value * pollutionMultiplier),
      ),
    );
  }

  SingleCraftingMachineDataBreakdown({
    required this.craftingMachine,
    required this.machineQuality,
    required this.surface,
    required this.recipe,
    required this.fuel,
    required this.finalCraftingSpeed,
    required this.finalPowerConsumption,
    required this.finalEmissionsPerMinute,
    required this.recipesPerSecond,
    required this.recipeInput,
    required this.recipeOutput,
    required this.fuelInput,
    required this.burntOutput,
    required this.possibleSpoilage,
    required this.netIo,
    required this.finalProductivityBonus,
    required this.totalProductivityBonus,
    required this.maxProductivityBonus,
    required this.machineBaseProductivityBonus,
    required this.finalSpeedBonus,
    required this.totalSpeedBonus,
    required this.machineBaseSpeedBonus,
    required this.finalPollutionBonus,
    required this.totalPollutionBonus,
    required this.recipePollutionBonus,
    required this.fuelPollutionBonus,
    required this.machineBasePollutionBonus,
    required this.finalConsumptionBonus,
    required this.totalConsumptionBonus,
    required this.machineBaseConsumptionBonus,
  });
}
