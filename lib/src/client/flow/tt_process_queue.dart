import 'dart:developer' as developer;

import '../../types/tt.dart';
import 'tt_event.dart';
import 'tt_queue.dart';
import 'middleware_system.dart';

enum ProcessDupesOptionType { processDupes, dontProcessDupes }

class TTProcessQueue<T extends TTMsg, U, V> extends TTQueue<T> {
  late final MiddlewareSystem<T, U, V> middleware;
  late bool isProcessing;
  late final TTEvent<T, dynamic, dynamic> completed;
  late final TTEvent<bool, dynamic, dynamic> emptied;
  final ProcessDupesOptionType processDupes;

  late List<T> alreadyProcessed;

  TTProcessQueue({
    String name = 'TTProcessQueue',
    this.processDupes = ProcessDupesOptionType.processDupes,
  }) : super(name: name) {
    alreadyProcessed = [];
    isProcessing = false;
    completed = TTEvent<T, dynamic, dynamic>(name: '$name.processed');
    emptied = TTEvent<bool, dynamic, dynamic>(name: '$name.emptied');
    middleware = MiddlewareSystem<T, U, V>(name: '$name.middleware');
  }

  @override
  bool has(T item) {
    return super.has(item) || alreadyProcessed.contains(item);
  }

  Future<void> processNext([U? b, V? c]) async {
    var item = dequeue();
    final processedItem = item;

    if (item == null) {
      return;
    }

    item = await middleware.process(item, b, c);

    if (processedItem != null &&
        processDupes == ProcessDupesOptionType.dontProcessDupes) {
      alreadyProcessed.add(processedItem);
    }

    if (item != null) {
      completed.trigger(item);
    }
  }

  @override
  TTProcessQueue<T, U, V> enqueueMany(final List<T> items) {
    super.enqueueMany(items);
    return this;
  }

  Future<void> process() async {
    if (isProcessing) {
      return;
    }

    if (count() == 0) {
      return;
    }

    isProcessing = true;
    while (count() > 0) {
      try {
        await processNext();
      } catch (e) {
        assert(() {
          developer.log(
            'Process Queue error: ${e.toString()}',
            name: 'tisane.process_queue',
            level: 1000,
          );
          return true;
        }());
      }
    }

    emptied.trigger(true);

    isProcessing = false;
  }
}
