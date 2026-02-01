part of 'models.dart';

enum ItemType { item, fluid }

abstract class Item {
  final ItemType type;
  final String name;

  final double? fuelValue;

  Item._internal(this.type, Map json)
    : name = json['name'],
      fuelValue = _convertStringToEnergy(json['fuel_value']);
}

class SolidItem extends Item {
  final int stackSize;
  final int? spoilTicks;
  final String? _spoilResult; // TODO

  final String? fuelCategory;
  final String? _burnResult; // TODO
  final double? fuelEmissionsMultiplier;

  SolidItem.fromJson(Map json)
    : stackSize = json['stack_size'],
      spoilTicks = json['spoil_ticks'],
      _spoilResult = json['spoil_result'],
      fuelCategory = json['fuel_category'],
      _burnResult = json['burnt_result'],
      fuelEmissionsMultiplier = json['fuel_emissions_multiplier']?.toDouble(),
      super._internal(ItemType.item, json);
}

class FluidItem extends Item {
  final double defaultTemperature;
  final double heatCapacity;
  final double maxTemperature;
  final double emissionsMultipler;

  FluidItem.fromJson(Map json)
    : defaultTemperature = json['default_temperature'].toDouble(),
      heatCapacity = _convertStringToEnergy(json['heat_capacity']) ?? 1000,
      maxTemperature =
          json['max_temperature']?.toDouble() ??
          json['default_temperature'].toDouble(),
      emissionsMultipler = json['emissions_multiplier']?.toDouble() ?? 1,
      super._internal(ItemType.fluid, json);
}
