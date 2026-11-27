part of 'data_dump.dart';

class DataDump {
  final List<SolidItemJson> solidItems;
  final List<FluidJson> fluid;
  final List<RecipeJson> recipes;
  final List<CraftingMachineJson> craftingMachines;
  final List<ItemGroupJson> groups;
  final List<ItemSubgroupJson> subgroups;
  final List<QualityJson> qualities;
  final List<SurfaceJson> surfaces;
  final List<TechnologyJson> technologies;

  DataDump._({
    required Iterable<SolidItemJson> solidItems,
    required Iterable<FluidJson> fluids,
    required Iterable<RecipeJson> recipes,
    required Iterable<CraftingMachineJson> craftingMachines,
    required Iterable<ItemGroupJson> groups,
    required Iterable<ItemSubgroupJson> subgroups,
    required Iterable<QualityJson> qualities,
    required Iterable<SurfaceJson> surfaces,
    required Iterable<TechnologyJson> technologies,
  }) : solidItems = List.unmodifiableOf(solidItems),
       fluid = List.unmodifiableOf(fluids),
       recipes = List.unmodifiableOf(recipes),
       craftingMachines = List.unmodifiableOf(craftingMachines),
       groups = List.unmodifiableOf(groups),
       subgroups = List.unmodifiableOf(subgroups),
       qualities = List.unmodifiableOf(qualities),
       surfaces = List.unmodifiableOf(surfaces),
       technologies = List.unmodifiableOf(technologies);

  DataDump.fromJson(Map dataDumpJson)
    : this._(
        solidItems: _deserialisePrototypes(dataDumpJson, const [
          'item',
          'module',
          'gun',
          'ammo',
          'armor',
          'repair-tool',
          'tool',
          'item-with-entity-data',
          'capsule',
          'rail-planner',
          'space-platform-starter-pack',
          'blueprint',
          'blueprint-book',
          'deconstruction-item',
          'upgrade-item',
          'selection-tool',
        ], SolidItemJson.fromJson),
        fluids: _deserialisePrototypes(dataDumpJson, const [
          'fluid',
        ], FluidJson.fromJson),
        recipes: _deserialisePrototypes(dataDumpJson, const [
          'recipe',
        ], RecipeJson.fromJson),
        craftingMachines: _deserialisePrototypes(dataDumpJson, const [
          'assembling-machine',
          'rocket-silo',
          'furnace',
        ], CraftingMachineJson.fromJson),
        groups: _deserialisePrototypes(dataDumpJson, const [
          'item-group',
        ], ItemGroupJson.fromJson),
        subgroups: _deserialisePrototypes(dataDumpJson, const [
          'item-subgroup',
        ], ItemSubgroupJson.fromJson),
        qualities: _deserialisePrototypes(dataDumpJson, const [
          'quality',
        ], QualityJson.fromJson),
        surfaces: _deserialisePrototypes(dataDumpJson, const [
          'planet',
          'surface',
        ], SurfaceJson.fromJson),
        technologies: _deserialisePrototypes(dataDumpJson, const [
          'technology',
        ], TechnologyJson.fromJson),
      );
}

Iterable<T> _deserialisePrototypes<T>(
  Map dataDumpJson,
  Iterable keyList,
  T Function(Map) deserializationFunction,
) => keyList
    .expand((key) => (dataDumpJson[key] as Map?)?.values ?? const [])
    .cast<Map>()
    .where((json) => json['parameter'] != true)
    .map((json) {
      try {
        return deserializationFunction.call(json);
      } catch (e, st) {
        throw FactorioException.withCause(
          'Encountered error when attempting to deserialize "${json['name']}" of type "${json['type']}"',
          e,
          st,
        );
      }
    });
