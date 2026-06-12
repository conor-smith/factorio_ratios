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

