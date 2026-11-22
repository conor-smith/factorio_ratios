part of 'data_dump.dart';

class DDDatabase {
  final List<DDSolidItem> solidItems;
  final List<DDFluid> fluid;
  final List<DDRecipe> recipes;
  final List<DDCraftingMachine> craftingMachines;
  final List<DDItemGroup> groups;
  final List<DDItemSubgroup> subgroups;
  final List<DDQuality> qualities;
  final List<DDSurface> surfaces;
  final List<DDTechnology> technologies;

  DDDatabase._({
    required Iterable<DDSolidItem> solidItems,
    required Iterable<DDFluid> fluids,
    required Iterable<DDRecipe> recipes,
    required Iterable<DDCraftingMachine> craftingMachines,
    required Iterable<DDItemGroup> groups,
    required Iterable<DDItemSubgroup> subgroups,
    required Iterable<DDQuality> qualities,
    required Iterable<DDSurface> surfaces,
    required Iterable<DDTechnology> technologies,
  }) : solidItems = List.unmodifiableOf(solidItems),
       fluid = List.unmodifiableOf(fluids),
       recipes = List.unmodifiableOf(recipes),
       craftingMachines = List.unmodifiableOf(craftingMachines),
       groups = List.unmodifiableOf(groups),
       subgroups = List.unmodifiableOf(subgroups),
       qualities = List.unmodifiableOf(qualities),
       surfaces = List.unmodifiableOf(surfaces),
       technologies = List.unmodifiableOf(technologies);

  DDDatabase.fromJson(Map dataDumpJson)
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
        ], DDSolidItem.fromJson),
        fluids: _deserialisePrototypes(dataDumpJson, const [
          'fluid',
        ], DDFluid.fromJson),
        recipes: _deserialisePrototypes(dataDumpJson, const [
          'recipe',
        ], DDRecipe.fromJson),
        craftingMachines: _deserialisePrototypes(dataDumpJson, const [
          'assembling-machine',
          'rocket-silo',
          'furnace',
        ], DDCraftingMachine.fromJson),
        groups: _deserialisePrototypes(dataDumpJson, const [
          'item-group',
        ], DDItemGroup.fromJson),
        subgroups: _deserialisePrototypes(dataDumpJson, const [
          'item-subgroup',
        ], DDItemSubgroup.fromJson),
        qualities: _deserialisePrototypes(dataDumpJson, const [
          'quality',
        ], DDQuality.fromJson),
        surfaces: _deserialisePrototypes(dataDumpJson, const [
          'planet',
          'surface',
        ], DDSurface.fromJson),
        technologies: _deserialisePrototypes(dataDumpJson, const [
          'technology',
        ], DDTechnology.fromJson),
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
