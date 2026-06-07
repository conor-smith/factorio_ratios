import 'package:factorio_ratios/factorio/factorio.dart';
import 'package:factorio_ratios/factorio/models/models.dart';
import 'package:factorio_ratios/json/json.dart';

part 'display_data.dart';
part 'in_game_item.dart';
part 'recipe_with_quality.dart';
part 'machine_with_quality.dart';

typedef ItemAmounts = Map<InGameItem, double>;

// TODO
List<IconData>? _verifyQualityAndUpdateIcon(
  List<IconData>? icons,
  int quality,
) {
  return icons;
}
