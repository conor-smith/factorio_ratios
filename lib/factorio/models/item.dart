part of 'models.dart';

enum ItemType { item, fluid }

abstract class Item {
  ItemType type;
  String name;
  String icon;

  double? fuelValue;

  Item._internal(this.type, Map json)
    : name = json['name'],
      icon = _getIcon(json) ?? _defaultIcon,
      fuelValue = _convertStringToJoules(json['fuel_value']);
}

class SolidItem extends Item {
  int stackSize;
  int spoilTicks;
  String? spoilResult;

  String? fuelCategory;
  String? burnResult;
  double? fuelEmissionsMultiplier;

  SolidItem.fromJson(Map json)
    : stackSize = json['stack_size'],
      spoilTicks = json['spoil_ticks'] ?? 0,
      spoilResult = json['spoil_result'],
      fuelCategory = json['fuel_category'],
      burnResult = json['burnt_result'],
      fuelEmissionsMultiplier = json['fuel_emissions_multiplier']?.toDouble(),
      super._internal(ItemType.item, json);
}

class FluidItem extends Item {
  double defaultTemperature;
  double heatCapacity;
  double maxTemperature;
  double emissionsMultipler;

  FluidItem.fromJson(Map json)
    : defaultTemperature = json['default_temperature'],
      heatCapacity = _convertStringToJoules(json['heat_capacity']),
      maxTemperature = json['max_temperature'] ?? json['default_temperature'],
      emissionsMultipler = json['emissions_multiplier'] ?? 1,
      super._internal(ItemType.fluid, json);
}
