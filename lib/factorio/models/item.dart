part of '../models.dart';

enum ItemType { item, fluid }

abstract class Item {
  final FactorioDatabase _factorioDb;

  final ItemType type;
  final String name;

  final double? fuelValue;

  // Populated when recipe relationships are built
  List<Recipe> _consumedBy = [];
  List<Recipe> _producedBy = [];

  Item._internal(this._factorioDb, this.type, Map json)
    : name = json['name'],
      fuelValue = _convertStringToEnergy(json['fuel_value']);

  List<Recipe> get consumedBy => _consumedBy;
  List<Recipe> get producedBy => _producedBy;
}

class SolidItem extends Item {
  final int stackSize;
  final int? spoilTicks;

  final String? fuelCategory;
  final double? fuelEmissionsMultiplier;

  final String? _spoilResultString;
  late final Item? spoiledResult = _factorioDb.itemMap[_spoilResultString];

  final String? _burnResultString;
  late final Item? burntResult = _factorioDb.itemMap[_burnResultString];

  SolidItem.fromJson(FactorioDatabase factorioDb, Map json)
    : stackSize = json['stack_size'],
      spoilTicks = json['spoil_ticks'],
      _spoilResultString = json['spoil_result'],
      fuelCategory = json['fuel_category'],
      _burnResultString = json['burnt_result'],
      fuelEmissionsMultiplier = json['fuel_emissions_multiplier']?.toDouble(),
      super._internal(factorioDb, ItemType.item, json);
}

class FluidItem extends Item {
  final double defaultTemperature;
  final double heatCapacity;
  final double maxTemperature;
  final double emissionsMultipler;

  FluidItem.fromJson(FactorioDatabase factorioDb, Map json)
    : defaultTemperature = json['default_temperature'].toDouble(),
      heatCapacity = _convertStringToEnergy(json['heat_capacity']) ?? 1000,
      maxTemperature =
          json['max_temperature']?.toDouble() ??
          json['default_temperature'].toDouble(),
      emissionsMultipler = json['emissions_multiplier']?.toDouble() ?? 1,
      super._internal(factorioDb, ItemType.fluid, json);
}
