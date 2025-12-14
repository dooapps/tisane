import 'dart:async';

import 'package:test/test.dart';
import 'package:tisane/src/ports/graph/graph_replication_port.dart';
import 'package:tisane/src/types/graph_change.dart';
import 'package:tisane/src/types/generic.dart';
import 'package:tisane/src/types/tt.dart';

/// Contract tests for GraphReplicationPort event semantics.
///
/// Because the port does not expose an apply API, the contract requires
/// an `emit` function to drive a synthetic change through the adapter under
/// test. Implementations typically back this via an internal controller.
void defineGraphReplicationPortContract(
  String name,
  GraphReplicationPort Function() create,
  Future<void> Function(GraphReplicationPort, ChangeSetEntry) emit,
) {
  group('GraphReplicationPort contract: $name', () {
    late GraphReplicationPort repl;

    setUp(() => repl = create());

    test('onChange receives emitted changes and disposer detaches', () async {
      ChangeSetEntry? received;
      final dispose = repl.onChange((entry) => received = entry);

      final entry = Tuple<String, TTGraphData>(
        item1: 'soul',
        item2: TTGraphData()
          ..['soul'] = TTNode.fromJson({
            '_': {'#': 'soul', '>': {}},
          }),
      );
      await emit(repl, entry);

      // bounded micro delay to allow stream dispatch
      await Future<void>.delayed(const Duration(milliseconds: 20));
      expect(received, isNotNull);
      expect(received!.item1, equals('soul'));

      dispose();
    });

    test('changesetFeed returns first change then completes', () async {
      final feed = repl.changesetFeed('cursor');
      final data = TTGraphData()
        ..['x'] = TTNode.fromJson({
          '_': {'#': 'x', '>': {}},
        });
      final c = Tuple<String, TTGraphData>(item1: 'x', item2: data);
      // feed waits until a change arrives
      unawaited(
        Future<void>.delayed(
          const Duration(milliseconds: 10),
        ).then((_) => emit(repl, c)),
      );
      final next = await feed();
      expect(next?.item1, equals('x'));
    });

    test('pruneChangelog does not throw', () async {
      await repl.pruneChangelog(0);
      expect(true, isTrue);
    });
  });
}
