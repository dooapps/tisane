import '../../types/tt.dart';

class TTQueue<T extends TTMsg> {
  final String name;
  late final List<T> _queue;

  TTQueue({this.name = 'TTQueue'}) : _queue = [];

  num count() {
    return _queue.length;
  }

  bool has(T item) {
    return _queue.contains(item);
  }

  TTQueue<T> enqueue(T item) {
    if (has(item)) {
      return this;
    }

    _queue.insert(0, item);
    return this;
  }

  T? dequeue() {
    return _queue.removeLast();
  }

  TTQueue<T> enqueueMany(final List<T> items) {
    final filtered = items.where((item) => !has(item)).toList();
    final List<T> filteredListReverse = [];

    for (var i = filtered.length - 1; i >= 0; i--) {
      filteredListReverse.add(filtered[i]);
    }
    if (filtered.isNotEmpty) {
      _queue.insertAll(0, filteredListReverse);
    }

    return this;
  }
}
