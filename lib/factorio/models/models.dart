import 'dart:collection';
import 'dart:convert';

import 'package:factorio_ratios/factorio/factorio.dart';
import 'package:factorio_ratios/utility/collections.dart';

part 'crafting_machines.dart';
part 'database.dart';
part 'group.dart';
part 'icon.dart';
part 'item.dart';
part 'other_interfaces.dart';
part 'quality.dart';
part 'recipe.dart';
part 'resource.dart';
part 'subgroup.dart';
part 'surface.dart';
part 'technology.dart';

const Map<String, double> _multipliers = {
  "k": 1.0e3,
  "M": 1.0e6,
  "G": 1.0e9,
  "T": 1.0e12,
  "P": 1.0e15,
  "E": 1.0e18,
  "Z": 1.0e21,
  "Y": 1.0e24,
  "R": 1.0e27,
  "Q": 1.0e30,
};

class Colour {
  static const defaultIconTint = Colour._(1, 1, 1, 1);

  final double r;
  final double g;
  final double b;
  final double a;

  const Colour._(this.r, this.g, this.b, this.a);

  factory Colour.fromJson(dynamic json) {
    double r, g, b, a;

    if (json is Map) {
      r = json['r']?.toDouble() ?? 0;
      g = json['g']?.toDouble() ?? 0;
      b = json['b']?.toDouble() ?? 0;
      a = json['a']?.toDouble() ?? 1;
    } else {
      List jsonList = json as List;
      r = jsonList[0].toDouble();
      g = jsonList[1].toDouble();
      b = jsonList[2].toDouble();
      a = jsonList.length == 4 ? jsonList[3].toDouble() : 1;
    }

    if (r > 1 || g > 1 || b > 1 || a > 1) {
      r /= 255;
      g /= 255;
      b /= 255;
      a /= 255;
    }

    return Colour._(r, g, b, a);
  }

  @override
  bool operator ==(Object other) =>
      super == other ||
      (other is Colour &&
          r == other.r &&
          g == other.g &&
          b == other.b &&
          a == other.a);

  @override
  int get hashCode =>
      r.hashCode +
      (g * 100).hashCode +
      (b * 10000).hashCode +
      (a * 1000000).hashCode;
}

enum Effects {
  consumption('consumption', minMultiplier: 0.2),
  productivity('productivity', minMultiplier: 1),
  speed('speed', minMultiplier: 0.2),
  pollution('pollution'),
  quality('quality', defaultMultiplier: 0);

  final String name;
  final double defaultMultiplier;

  final double minMultiplier;
  final double maxMultiplier;

  final double minBonus;
  final double maxBonus;

  const Effects(
    this.name, {
    this.defaultMultiplier = 1,
    this.minMultiplier = double.negativeInfinity,
    this.maxMultiplier = double.infinity,
  }) : minBonus = minMultiplier - defaultMultiplier,
       maxBonus = maxMultiplier - defaultMultiplier;

  double bonusOrBound(double bonus) {
    if (bonus > maxBonus) {
      return maxBonus;
    } else if (bonus < minBonus) {
      return minBonus;
    } else {
      return bonus;
    }
  }

  @override
  String toString() => name;
}

Map<String, double> _parseStringDoubleMap(Map? json) {
  json ??= const {};

  // JSON interpreter sometimes returns ints rather than doubles
  // So this is the easiest solution
  Map<String, double> toReturn = {};
  json.forEach((key, value) => toReturn[key] = value.toDouble());

  return Map.unmodifiable(toReturn);
}

double? _convertStringToEnergy(String? energyUsage) {
  if (energyUsage == null) {
    return null;
  }

  String multiplier = energyUsage.substring(
    energyUsage.length - 2,
    energyUsage.length - 1,
  );

  if (_multipliers.containsKey(multiplier)) {
    return double.parse(energyUsage.substring(0, energyUsage.length - 2)) *
        _multipliers[multiplier]!;
  } else {
    return double.parse(energyUsage.substring(0, energyUsage.length - 1));
  }
}
