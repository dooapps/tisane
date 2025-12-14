import 'dart:async';

import 'package:test/test.dart';
import 'package:tisane/src/adapters/graph/default_graph_replication_adapter.dart';
import 'package:tisane/src/adapters/graph/default_graph_merge_adapter.dart';
import 'package:tisane/src/ports/graph/graph_replication_port.dart';
import 'package:tisane/src/ports/graph/graph_store_port.dart';
import 'package:tisane/src/types/tt.dart';

import '../contracts/graph_replication_port_contract.dart';
import 'package:tisane/src/ports/graph/graph_read_options.dart';

class _InMemoryStore implements GraphStorePort {
  final Map<String, TTNode?> _store = {};

  @override
  Future<TTNode?> fetchNode(String soul, {GraphReadOptions? options}) async =>
      _store[soul];

  @override
  Future<String?> fetchNodeJson(
    String soul, {
    GraphReadOptions? options,
  }) async => _store[soul]?.toJson().toString();

  @override
  TTNode? fetchNodeSync(String soul, {GraphReadOptions? options}) =>
      _store[soul];

  @override
  String? fetchNodeJsonSync(String soul, {GraphReadOptions? options}) =>
      _store[soul]?.toJson().toString();

  @override
  Future<TTGraphData?> writeGraph(TTGraphData graphData) async {
    _store.addAll(graphData);
    return graphData;
  }

  @override
  TTGraphData? writeGraphSync(TTGraphData graphData) {
    _store.addAll(graphData);
    return graphData;
  }

  @override
  void close() {}
}

void main() {
  defineGraphReplicationPortContract(
    'DefaultGraphReplicationAdapter',
    () => DefaultGraphReplicationAdapter(
      store: _InMemoryStore(),
      merge: const DefaultGraphMergePort(),
    ),
    (GraphReplicationPort port, change) async {
      // Drive changes through the adapter by calling applyInbound
      final adapter = port as DefaultGraphReplicationAdapter;
      await adapter.applyInbound(change.item2);
    },
  );

  test('applyInbound is idempotent at store level', () async {
    final store = _InMemoryStore();
    final adapter = DefaultGraphReplicationAdapter(
      store: store,
      merge: const DefaultGraphMergePort(),
    );
    TTGraphData diff = TTGraphData()
      ..['a'] = TTNode.fromJson({
        '_': {
          '#': 'a',
          '>': {'v': 1},
        },
        'v': 1,
      });
    await adapter.applyInbound(diff);
    await adapter.applyInbound(diff);
    final node = await store.fetchNode('a');
    expect(node?['v'], equals(1));
  });
}
