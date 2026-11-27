part of 'models.dart';

class Recipe extends PrototypeWithQuality {
  @override
  final RecipeJson internalJson;

  Recipe({
    required super.database,
    required super.qualityName,
    required this.internalJson,
  });
}
