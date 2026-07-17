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

// Not technically a factorio type, but helpful for this use case
abstract class PrototypeWithIcon extends Prototype {
  Icon? get icon;
}
