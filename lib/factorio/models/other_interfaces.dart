part of 'models.dart';

abstract class Prototype implements Comparable<Prototype> {
  String get name;
  String get type;
  String get localisedName;
  String get order;
  ItemSubgroup? get subgroup;

  @override
  int compareTo(Prototype other) {
    var order = this.order.compareTo(other.order);

    return order != 0 ? order : name.compareTo(other.name);
  }
}

abstract class EntityPrototype extends Prototype {
  Icon? get icon;
  double get expectedIconSize;
  double get defaultScale;
}
