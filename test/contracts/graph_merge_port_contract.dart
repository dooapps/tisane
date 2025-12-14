import 'dart:math';

import 'package:test/test.dart';
import 'package:tisane/src/ports/graph/graph_merge_port.dart';
import 'package:tisane/src/types/tt.dart';

/// Contract tests for GraphMergePort invariants: commutativity,
/// associativity, and idempotence.
void defineGraphMergePortContract(
  String name,
  GraphMergePort Function() create,
) {
  group('GraphMergePort contract: $name', () {
    late GraphMergePort merge;
    setUp(() => merge = create());

    TTGraphData buildGraph(num price, num ts) {
      final node = TTNode.fromJson({
        '_': {
          '#': 'soul',
          '>': {'price': ts},
        },
        'price': price,
      });
      final data = TTGraphData();
      data['soul'] = node;
      return data;
    }

    test('idempotent merge (applying same diff twice)', () {
      final base = buildGraph(10, 1000);
      final update = buildGraph(12, 1100);
      final diff = merge.diffGraph(update, base)!;
      final once = merge.mergeGraph(base, diff);
      final twice = merge.mergeGraph(once, diff);
      expect(once['soul']?['price'], equals(twice['soul']?['price']));
    });

    test('commutative merge order for unrelated diffs', () {
      final random = Random(42);
      for (var i = 0; i < 10; i++) {
        final base = buildGraph(10, 1000);
        final left = buildGraph(random.nextInt(50) + 10, 1100 + i);
        final right = buildGraph(random.nextInt(50) + 10, 1200 + i);

        final leftDiff = merge.diffGraph(left, base) ?? TTGraphData();
        final rightDiff = merge.diffGraph(right, base) ?? TTGraphData();

        final leftFirst = merge.mergeGraph(
          merge.mergeGraph(base, leftDiff),
          rightDiff,
        );
        final rightFirst = merge.mergeGraph(
          merge.mergeGraph(base, rightDiff),
          leftDiff,
        );

        expect(
          leftFirst['soul']?['price'],
          equals(rightFirst['soul']?['price']),
        );
      }
    });

    test('associativity (merge(a, merge(b,c)) == merge(merge(a,b), c))', () {
      final a = buildGraph(10, 1000);
      final b = buildGraph(11, 1100);
      final c = buildGraph(13, 1200);

      final ab = merge.mergeGraph(a, merge.diffGraph(b, a) ?? TTGraphData());
      final bc = merge.mergeGraph(b, merge.diffGraph(c, b) ?? TTGraphData());

      final left = merge.mergeGraph(a, merge.diffGraph(bc, a) ?? TTGraphData());
      final right = merge.mergeGraph(
        ab,
        merge.diffGraph(c, ab) ?? TTGraphData(),
      );

      expect(left['soul']?['price'], equals(right['soul']?['price']));
    });
  });
}
