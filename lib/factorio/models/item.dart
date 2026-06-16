part of 'models.dart';

abstract class Item extends EntityPrototype {
  static const double _expectedIconSize = 64;
  static const double _defaultScale =
      (_expectedIconSize / 2) / _expectedIconSize;

  final FactorioDatabase factorioDb;

  @override
  final String name;
  @override
  final String order;
  @override
  late final ItemSubgroup? subgroup =
      factorioDb.itemSubgroupMap[_subgroupString];

  @override
  final Icon? icon;
  @override
  double get expectedIconSize => _expectedIconSize;
  @override
  double get defaultScale => _defaultScale;

  final String type;
  final String localisedName;

  final double? fuelValue;
  final String? _subgroupString;

  final bool hidden;

  late final List<Recipe> consumedBy = UnmodifiableListView(
    factorioDb._consumedBy[this] ?? const [],
  );
  late final List<Recipe> producedBy = UnmodifiableListView(
    factorioDb._producedBy[this] ?? const [],
  );

  Item._({
    required this.factorioDb,
    required this.name,
    required this.type,
    required this.localisedName,
    required this.icon,
    required this.fuelValue,
    required this.order,
    required String? subgroup,
    required this.hidden,
  }) : _subgroupString = subgroup;

  factory Item.fromJson(FactorioDatabase factorioDb, Map json) {
    return switch (json['type']) {
      'fluid' => FluidItem.fromJson(factorioDb, json),
      _ => SolidItem.fromJson(factorioDb, json),
    };
  }

  // TODO - Actual localisation
  static String _getLocalisedName(Map json) {
    String name = json['name']!;

    return '${name[0].toUpperCase()}${name.substring(1).replaceAll('-', ' ')}';
  }

  @override
  String toString() => name;
}

class SolidItem extends Item {
  final int stackSize;
  final int? spoilTicks;

  final String? fuelCategory;
  final double? fuelEmissionsMultiplier;

  final String? _placeResultString;

  final String? _spoilResultString;
  late final Item? spoilResult = _spoilResultString != null
      ? factorioDb.itemMap[_spoilResultString]!
      : null;
  late final List<Item> producedFromSpoiling = UnmodifiableListView(
    factorioDb._spoilResults[this] ?? const [],
  );

  final String? _burnResultString;
  late final Item? burntResult = _burnResultString != null
      ? factorioDb.itemMap[_burnResultString]!
      : null;
  late final List<Item> producedFromBurning = UnmodifiableListView(
    factorioDb._burnResults[this] ?? const [],
  );

  SolidItem._({
    required super.factorioDb,
    required super.name,
    required super.type,
    required super.fuelValue,
    required super.localisedName,
    required super.icon,
    required super.subgroup,
    required super.order,
    required super.hidden,
    required this.stackSize,
    required this.spoilTicks,
    required this.fuelCategory,
    required this.fuelEmissionsMultiplier,
    required String? placeResultString,
    required String? spoilResultString,
    required String? burntResultString,
  }) : _placeResultString = placeResultString,
       _spoilResultString = spoilResultString,
       _burnResultString = burntResultString,
       super._();

  factory SolidItem.fromJson(FactorioDatabase factorioDb, Map json) =>
      SolidItem._(
        factorioDb: factorioDb,
        name: json['name'],
        type: json['type'],
        localisedName: Item._getLocalisedName(json),
        fuelValue: _convertStringToEnergy(json['fuel_value']),
        subgroup: json['subgroup'],
        order: json['order'] ?? '',
        icon: Icon.fromTopLevelJson(json, Item._expectedIconSize),
        hidden: json['hidden'] ?? false,
        stackSize: json['stack_size'],
        spoilTicks: json['spoil_ticks'],
        fuelCategory: json['fuel_category'],
        fuelEmissionsMultiplier:
            json['fuel_emissions_multiplier']?.toDouble() ?? 1,
        placeResultString: json['place_result'],
        spoilResultString: json['spoil_result'],
        burntResultString: json['burnt_result'],
      );
}

class FluidItem extends Item {
  final double defaultTemperature;
  final double heatCapacity;
  final double maxTemperature;
  final double emissionsMultiplier;

  FluidItem._({
    required super.factorioDb,
    required super.name,
    required super.type,
    required super.localisedName,
    required super.fuelValue,
    required super.subgroup,
    required super.order,
    required super.icon,
    required super.hidden,
    required this.defaultTemperature,
    required this.heatCapacity,
    required this.maxTemperature,
    required this.emissionsMultiplier,
  }) : super._();

  factory FluidItem.fromJson(FactorioDatabase factorioDb, Map json) =>
      FluidItem._(
        factorioDb: factorioDb,
        name: json['name'],
        type: json['type'],
        fuelValue: _convertStringToEnergy(json['fuel_value']),
        localisedName: Item._getLocalisedName(json),
        order: json['order'] ?? '',
        subgroup: json['subgroup'],
        icon: Icon.fromTopLevelJson(json, Item._expectedIconSize),
        hidden: json['hidden'] ?? false,
        defaultTemperature: json['default_temperature'].toDouble(),
        heatCapacity: _convertStringToEnergy(json['heat_capacity']) ?? 1000,
        maxTemperature:
            json['max_temperature']?.toDouble() ??
            json['default_temperature'].toDouble(),
        emissionsMultiplier: json['emissions_multiplier']?.toDouble() ?? 1,
      );
}
