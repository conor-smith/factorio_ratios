part of 'models.dart';

abstract class Item extends PrototypeWithIcon {
  double? get fuelValue;

  bool get hidden;

  List<Recipe> get consumedBy;
  List<Recipe> get producedBy;

  Item._();

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
}

class SolidItem extends Item {
  @override
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
  final String type;
  @override
  final String localisedName;

  @override
  final double? fuelValue;
  final String? _subgroupString;

  @override
  final bool hidden;

  @override
  late final List<Recipe> consumedBy = UnmodifiableListView(
    factorioDb._consumedBy[this] ?? const [],
  );
  @override
  late final List<Recipe> producedBy = UnmodifiableListView(
    factorioDb._producedBy[this] ?? const [],
  );

  final int stackSize;
  final int? spoilTicks;

  final String? fuelCategory;
  final double? fuelEmissionsMultiplier;

  final String? _placeResultString;

  final int? spoilQualityChange;
  final String? _spoilQualityMinString;
  final String? _spoilQualityMaxString;
  late final Quality? spoilQualityMin =
      factorioDb.qualityMap[_spoilQualityMinString];
  late final Quality? spoilQualityMax =
      factorioDb.qualityMap[_spoilQualityMaxString];

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
    required this.factorioDb,
    required this.name,
    required this.type,
    required this.fuelValue,
    required this.localisedName,
    required this.icon,
    required String? subgroupString,
    required this.order,
    required this.hidden,
    required this.stackSize,
    required this.spoilTicks,
    required this.fuelCategory,
    required this.fuelEmissionsMultiplier,
    required this.spoilQualityChange,
    required String? spoilQualityMin,
    required String? spoilQualityMax,
    required String? placeResultString,
    required String? spoilResultString,
    required String? burntResultString,
  }) : _subgroupString = subgroupString,
       _spoilQualityMinString = spoilQualityMin,
       _spoilQualityMaxString = spoilQualityMax,
       _placeResultString = placeResultString,
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
        subgroupString: json['subgroup'],
        order: json['order'] ?? '',
        icon: Icon.fromTopLevelJson(json, ExpectedIconSize.other),
        hidden: json['hidden'] ?? false,
        stackSize: json['stack_size'],
        spoilTicks: json['spoil_ticks'],
        fuelCategory: json['fuel_category'],
        fuelEmissionsMultiplier:
            json['fuel_emissions_multiplier']?.toDouble() ?? 1,
        spoilQualityChange: json['spoil_quality_change'],
        spoilQualityMin: json['spoil_quality_min'],
        spoilQualityMax: json['spoil_quality_max'],
        placeResultString: json['place_result'],
        spoilResultString: json['spoil_result'],
        burntResultString: json['burnt_result'],
      );
}

class FluidItem extends Item {
  @override
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
  final String type;
  @override
  final String localisedName;

  @override
  final double? fuelValue;
  final String? _subgroupString;

  @override
  final bool hidden;

  @override
  late final List<Recipe> consumedBy = UnmodifiableListView(
    factorioDb._consumedBy[this] ?? const [],
  );
  @override
  late final List<Recipe> producedBy = UnmodifiableListView(
    factorioDb._producedBy[this] ?? const [],
  );

  final double defaultTemperature;
  final double heatCapacity;
  final double maxTemperature;
  final double emissionsMultiplier;

  FluidItem._({
    required this.factorioDb,
    required this.name,
    required this.type,
    required this.localisedName,
    required this.fuelValue,
    required String? subgroupString,
    required this.order,
    required this.icon,
    required this.hidden,
    required this.defaultTemperature,
    required this.heatCapacity,
    required this.maxTemperature,
    required this.emissionsMultiplier,
  }) : _subgroupString = subgroupString,
       super._();

  factory FluidItem.fromJson(FactorioDatabase factorioDb, Map json) =>
      FluidItem._(
        factorioDb: factorioDb,
        name: json['name'],
        type: json['type'],
        fuelValue: _convertStringToEnergy(json['fuel_value']),
        localisedName: Item._getLocalisedName(json),
        order: json['order'] ?? '',
        subgroupString: json['subgroup'],
        icon: Icon.fromTopLevelJson(json, ExpectedIconSize.other),
        hidden: json['hidden'] ?? false,
        defaultTemperature: json['default_temperature'].toDouble(),
        heatCapacity: _convertStringToEnergy(json['heat_capacity']) ?? 1000,
        maxTemperature:
            json['max_temperature']?.toDouble() ??
            json['default_temperature'].toDouble(),
        emissionsMultiplier: json['emissions_multiplier']?.toDouble() ?? 1,
      );
}
