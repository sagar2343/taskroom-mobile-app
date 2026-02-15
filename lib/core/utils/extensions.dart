extension IterableExtension<T> on List<T> {
  Iterable<T> distinctBy(String Function(T e) getCompareValue) {
    var idSet = <Object>{};
    var distinct = <T>[];
    for (var d in this) {
      if (idSet.add(getCompareValue(d))) {
        distinct.add(d);
      }
    }

    return distinct;
  }
}
