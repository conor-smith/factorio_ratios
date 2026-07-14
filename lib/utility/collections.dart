Set<T>? unmodifableSetOrNull<T>(Iterable<T>? iterable) =>
    iterable != null ? Set.unmodifiable(iterable) : null;
List<T>? unmodifiableListOrNull<T>(Iterable<T>? iterable) =>
    iterable != null ? List.unmodifiable(iterable) : null;
Map<K, V>? unmodifiableMapOrNull<K, V>(Map<K, V>? map) =>
    map != null ? Map.unmodifiable(map) : null;

void sumMaps<K>(Map<K, double> accumulator, Map<K, double> toAdd) =>
    toAdd.forEach(
      (item, amount) => accumulator.update(
        item,
        (existingAmount) => existingAmount + amount,
        ifAbsent: () => amount,
      ),
    );

bool compareMaps<K, V>(Map<K, V> map1, Map<K, V> map2) =>
    map1 == map2 ||
    (map1.length == map2.length &&
        map1.entries.every((entry) => map2[entry.key] == entry.value));

bool compareSets<T>(Set<T> set1, Set<T> set2) =>
    set1 == set2 || (set1.length == set2.length && set1.containsAll(set2));

bool compareLists<T>(List<T> list1, List<T> list2) {
  if (list1 == list2) {
    return true;
  } else if (list1.length == list2.length) {
    for (var i = 0; i < list1.length; i++) {
      if (list1[i] != list2[i]) {
        return false;
      }
    }
    return true;
  } else {
    return false;
  }
}

Map<K, double> multiplyMap<K>(Map<K, double> toMultiply, double multiplier) =>
    toMultiply.map((key, value) => MapEntry(key, value * multiplier));

Map<K, double> divideMap<K>(Map<K, double> toDivide, double divisor) =>
    toDivide.map((key, value) => MapEntry(key, value / divisor));

T? maxOrNull<T>(Iterable<T> iterable, Comparator<T> comparator) {
  if (iterable.isEmpty) {
    return null;
  } else {
    T max = iterable.first;

    for (T item in iterable.skip(1)) {
      if (comparator(item, max) > 0) {
        max = item;
      }
    }

    return max;
  }
}
