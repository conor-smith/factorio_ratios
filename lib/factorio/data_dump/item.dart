part of 'data_dump.dart';

abstract class ItemJson extends PrototypeWithIconJson {
  bool get hidden;
}

class SolidItemJson extends ItemJson {
  @override
  final String name;
  @override
  final String type;
  @override
  final String order;
  @override
  final String? subgroupName;
  @override
  final dynamic localisedName;
  @override
  final Icon? icon;

  @override
  final bool hidden;

  final int stackSize;

  final String placeResult;

  final List<String>? fuelCategories;

  final String burntResult;
  final String? spoilResult;
  final String? spoilQualityMin;
  final String? spoilQualityMax;
  final int spoilQualityChange;

  final String? plantResult;

  final int spoilTicks;
  final bool qualityAffectsSpoilTicks;

  final String fuelValue;
  final double fuelEmissionsMultiplier;

  final double? weight;

  final List<String>? rocketLaunchProducts;

  final bool labIgnoresSpoilPercent;
  final double scienceCapacity;

  SolidItemJson._({
    required this.name,
    required this.type,
    required String? order,
    required this.subgroupName,
    required dynamic localisedName,
    required this.icon,
    required bool? hidden,
    required this.stackSize,
    required String? placeResult,
    required List<String>? fuelCategories,
    required String? burntResult,
    required this.spoilResult,
    required this.spoilQualityMin,
    required this.spoilQualityMax,
    required int? spoilQualityChange,
    required this.plantResult,
    required int? spoilTicks,
    required bool? qualityAffectsSpoilTicks,
    required String? fuelValue,
    required double? fuelEmissionsMultiplier,
    required this.weight,
    required List<String>? rocketLaunchProducts,
    required bool? labIgnoresSpoilPercent,
    required double? scienceCapacity,
  }) : hidden = hidden ?? false,
       localisedName = _unmodifiableLocalisedString(localisedName),
       order = order ?? PrototypeJson._defaultOrder,
       placeResult = placeResult ?? "",
       fuelCategories = _unmodifiableOrNullList(fuelCategories),
       burntResult = burntResult ?? "",
       spoilQualityChange = spoilQualityChange ?? 0,
       spoilTicks = spoilTicks ?? 0,
       qualityAffectsSpoilTicks = qualityAffectsSpoilTicks ?? true,
       fuelValue = fuelValue ?? '0J',
       fuelEmissionsMultiplier = fuelEmissionsMultiplier ?? 1,
       rocketLaunchProducts = _unmodifiableOrNullList(rocketLaunchProducts),
       labIgnoresSpoilPercent = labIgnoresSpoilPercent ?? false,
       scienceCapacity = scienceCapacity ?? 1;

  factory SolidItemJson.fromJson(Map json) => SolidItemJson._(
    name: json['name'],
    type: json['type'],
    order: json['order'],
    subgroupName: json['subgroup'],
    localisedName: json['localised_name'],
    icon: Icon.fromTopLevelJson(json, ExpectedIconSize.other),
    hidden: json['hidden'],
    stackSize: json['stack_size'],
    placeResult: json['place_result'],
    fuelCategories: json['fuel_categories']?.cast<String>(),
    burntResult: json['burnt_result'],
    spoilResult: json['spoil_result'],
    spoilQualityMin: json['spoil_quality_min'],
    spoilQualityMax: json['spoil_quality_max'],
    spoilQualityChange: json['spoil_quality_change'],
    plantResult: json['plant_result'],
    spoilTicks: json['spoil_ticks'],
    qualityAffectsSpoilTicks: json['quality_affects_spoil_ticks'],
    fuelValue: json['fuel_value'],
    fuelEmissionsMultiplier: json['fuel_emissions_multiplier']?.toDouble(),
    weight: json['weight']?.toDouble(),
    rocketLaunchProducts: json['rocket_launch_products'],
    labIgnoresSpoilPercent: json['lab_ignores_spoil_percent'],
    scienceCapacity: json['science_capacity'],
  );
}

class FluidJson extends ItemJson {
  @override
  final String name;
  @override
  final String type;
  @override
  final String order;
  @override
  final String? subgroupName;
  @override
  final dynamic localisedName;
  @override
  final Icon? icon;

  @override
  final bool hidden;

  final double defaultTemperature;
  final double maxTemperature;
  final String heatCapacity;
  final String fuelValue;
  final double emissionsMultiplier;
  final SpentFluidSpecification? spentFluid;

  FluidJson._({
    required this.name,
    required this.type,
    required String? order,
    required this.subgroupName,
    required dynamic localisedName,
    required this.icon,
    required bool? hidden,
    required this.defaultTemperature,
    required double? maxTemperature,
    required String? heatCapacity,
    required String? fuelValue,
    required double? emissionsMultiplier,
    required this.spentFluid,
  }) : order = order ?? PrototypeJson._defaultOrder,
       localisedName = _unmodifiableLocalisedString(localisedName),
       hidden = hidden ?? false,
       maxTemperature = maxTemperature ?? defaultTemperature,
       heatCapacity = heatCapacity ?? '1kJ',
       fuelValue = fuelValue ?? '0J',
       emissionsMultiplier = emissionsMultiplier ?? 1;

  factory FluidJson.fromJson(Map json) {
    Map? spentFluidJson = json['spent_fluid'];
    var spentFluid = spentFluidJson != null
        ? SpentFluidSpecification.fromJson(spentFluidJson)
        : null;

    return FluidJson._(
      name: json['name'],
      type: json['type'],
      order: json['order'],
      subgroupName: json['subgroup'],
      localisedName: json['localised_name'],
      icon: Icon.fromTopLevelJson(json, ExpectedIconSize.other),
      hidden: json['hidden'],
      defaultTemperature: json['default_temperature'].toDouble(),
      maxTemperature: json['max_temperature']?.toDouble(),
      heatCapacity: json['heat_capacity'],
      fuelValue: json['fuel_value'],
      emissionsMultiplier: json['emissions_multiplier']?.toDouble(),
      spentFluid: spentFluid,
    );
  }
}
