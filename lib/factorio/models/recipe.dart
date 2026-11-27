part of 'models.dart';

class Recipe extends PrototypeWithQuality {
  @override
  final RecipeJson _internalJson;

  Recipe({
    required super.database,
    required super.qualityName,
    required this._internalJson,
  });
}
