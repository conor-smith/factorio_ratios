part of 'models.dart';

class Recipe extends PrototypeWithIcon {
  @override
  final RecipeJson internalJson;

  Recipe({required super.database, required this.internalJson});
}
