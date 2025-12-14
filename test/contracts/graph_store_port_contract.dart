import 'package:test/test.dart';
import 'package:tisane/src/ports/graph/graph_store_port.dart';
import 'package:tisane/src/ports/graph/graph_read_options.dart';
import 'package:tisane/src/types/tt.dart';

/// Reusable contract tests for GraphStorePort implementations.
///
/// Adapters must support basic CRUD roundtrips and tolerate optional
/// GraphReadOptions without throwing. Implementations may ignore options.
void defineGraphStorePortContract(
  String name,
  GraphStorePort Function() create,
  void Function(GraphStorePort) dispose,
) {
  group('GraphStorePort contract: $name', () {
    late GraphStorePort store;

    setUp(() {
      store = create();
    });

    tearDown(() {
      dispose(store);
    });

    TTGraphData graphWith(
      String soul,
      Map<String, dynamic> value, {
      int ts = 1,
    }) {
      final node = TTNode.fromJson({
        '_': {
          '#': soul,
          '>': {for (final k in value.keys) k: ts},
        },
        ...value,
      });
      final data = TTGraphData();
      data[soul] = node;
      return data;
    }

    test('writeGraph then fetchNode returns value', () async {
      final soul = 's1';
      final data = graphWith(soul, {'field': 'v'});

      final written = await store.writeGraph(data);
      expect(written, isNotNull);

      final fetched = await store.fetchNode(soul);
      expect(fetched, isNotNull);
      expect(fetched!['field'], equals('v'));

      // Sync path parity
      final fetchedSync = store.fetchNodeSync(soul);
      expect(fetchedSync, isNotNull);
      expect(fetchedSync!['field'], equals('v'));
    });

    test('fetchNodeJson mirrors fetchNode', () async {
      final soul = 's2';
      await store.writeGraph(graphWith(soul, {'x': 1}, ts: 2));

      final json = await store.fetchNodeJson(soul);
      final jsonSync = store.fetchNodeJsonSync(soul);
      expect(json, isNotNull);
      expect(jsonSync, isNotNull);
    });

    test('missing keys return null and options tolerated', () async {
      final opts = const GraphReadOptions(
        point: '.',
        forward: '>',
        backward: '<',
      );
      expect(await store.fetchNode('missing', options: opts), isNull);
      expect(store.fetchNodeSync('missing', options: opts), isNull);
      expect(await store.fetchNodeJson('missing', options: opts), isNull);
      expect(store.fetchNodeJsonSync('missing', options: opts), isNull);
    });

    test('writeGraphSync consistent with writeGraph', () async {
      final soul = 's3';
      final data = graphWith(soul, {'a': true});
      final w1 = await store.writeGraph(data);
      final w2 = store.writeGraphSync(data);
      expect(w1?.keys, contains(soul));
      expect(w2?.keys, contains(soul));
    });

    test('close does not throw', () {
      expect(() => store.close(), returnsNormally);
    });
  });
}
