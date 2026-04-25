import 'package:factorio_ratios/factorio/models/models.dart';

part 'in_game_item.dart';
part 'recipe_with_quality.dart';
part 'machine_with_quality.dart';

typedef ItemIo = Map<InGameItem, double>;

// TODO
List<IconData>? _verifyQualityAndUpdateIcon(
  List<IconData>? icons,
  int quality,
) {
  return icons;
}
