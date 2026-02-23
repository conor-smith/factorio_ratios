part of '../models.dart';

abstract class Ordered implements Comparable<Ordered> {
  String get name;
  String get order;

  @override
  int compareTo(Ordered other) {
    var order = this.order.compareTo(other.order);

    return order != 0 ? order : name.compareTo(other.name);
  }
}

abstract class OrderedWithSubgroup extends Ordered implements HasIcon {
  ItemSubgroup? get subgroup;
}

abstract class HasIcon {
  List<IconData>? get icons;
}
