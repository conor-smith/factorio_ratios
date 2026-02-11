part of '../models.dart';

enum ItemType { item, fluid }

abstract class Item {
  final FactorioDatabase factorioDb;

  final ItemType type;
  final String name;

  final double? fuelValue;

  // Populated when recipe relationships are built
  late final List<Recipe> consumedBy = UnmodifiableListView(
    factorioDb._consumedBy[this] ?? const [],
  );
  late final List<Recipe> producedBy = UnmodifiableListView(
    factorioDb._producedBy[this] ?? const [],
  );

  Item._({
    required this.factorioDb,
    required this.type,
    required this.name,
    required this.fuelValue,
  });

  factory Item.fromJson(FactorioDatabase factorioDb, Map json) {
    return switch (json['type']) {
      'fluid' => FluidItem.fromJson(factorioDb, json),
      _ => SolidItem.fromJson(factorioDb, json),
    };
  }

  @override
  String toString() => name;
}

class SolidItem extends Item {
  final int stackSize;
  final int? spoilTicks;

  final String? fuelCategory;
  final double? fuelEmissionsMultiplier;

  final String? _spoilResultString;
  late final Item? spoilResult;
  late final List<Item> producedFromSpoiling = UnmodifiableListView(
    factorioDb._spoilResults[this] ?? const [],
  );

  final String? _burnResultString;
  late final Item? burntResult;
  late final List<Item> producedFromBurning = UnmodifiableListView(
    factorioDb._burnResults[this] ?? const [],
  );

  SolidItem._({
    required super.factorioDb,
    required super.name,
    required super.fuelValue,
    required this.stackSize,
    required this.spoilTicks,
    required this.fuelCategory,
    required this.fuelEmissionsMultiplier,
    required String? spoilResultString,
    required String? burntResultString,
  }) : _spoilResultString = spoilResultString,
       _burnResultString = burntResultString,
       super._(type: ItemType.item);

  factory SolidItem.fromJson(FactorioDatabase factorioDb, Map json) =>
      SolidItem._(
        factorioDb: factorioDb,
        name: json['name'],
        fuelValue: _convertStringToEnergy(json['fuel_value']),
        stackSize: json['stack_size'],
        spoilTicks: json['spoil_ticks'],
        fuelCategory: json['fuel_category'],
        fuelEmissionsMultiplier:
            json['fuel_emissions_multiplier']?.toDouble() ?? 1,
        spoilResultString: json['spoil_result'],
        burntResultString: json['burnt_result'],
      );
}

class FluidItem extends Item {
  final double defaultTemperature;
  final double heatCapacity;
  final double maxTemperature;
  final double emissionsMultipler;

  FluidItem._({
    required super.factorioDb,
    required super.name,
    required super.fuelValue,
    required this.defaultTemperature,
    required this.heatCapacity,
    required this.maxTemperature,
    required this.emissionsMultipler,
  }) : super._(type: ItemType.fluid);

  factory FluidItem.fromJson(FactorioDatabase factorioDb, Map json) =>
      FluidItem._(
        factorioDb: factorioDb,
        name: json['name'],
        fuelValue: _convertStringToEnergy(json['fuel_value']),
        defaultTemperature: json['default_temperature'].toDouble(),
        heatCapacity: _convertStringToEnergy(json['heat_capacity']) ?? 1000,
        maxTemperature:
            json['max_temperature']?.toDouble() ??
            json['default_temperature'].toDouble(),
        emissionsMultipler: json['emissions_multiplier']?.toDouble() ?? 1,
      );
}
