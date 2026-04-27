import "dart:collection";

class LimitedQueue<T> {
  final int maxSize;
  final Queue<T> _queue = Queue();

  LimitedQueue(this.maxSize) {
    if (maxSize < 0) {
      throw ArgumentError("Must be non-negative");
    }
  }

  void add(T value) {
    if (_queue.length >= maxSize) {
      _queue.removeFirst();
    }
    _queue.addLast(value);
  }

  void clear() => _queue.clear();

  List<T> get items => List.unmodifiable(_queue);
}
