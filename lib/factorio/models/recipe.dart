part of 'models.dart';

class Recipe extends PrototypeWithQuality<Recipe> {
  @override
  final RecipeJson internalJson;

  Recipe({
    required super.database,
    required super.quality,
    required this.internalJson,
  });

  @override
  Recipe withQuality(Quality quality) => throw UnimplementedError(); // TODO
}
