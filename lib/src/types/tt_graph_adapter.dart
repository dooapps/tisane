import '../ports/graph/graph_read_options.dart';
import '../ports/graph/graph_replication_port.dart';
import '../ports/graph/graph_store_port.dart';
import 'graph_change.dart';
import 'tt.dart';

@Deprecated('Use GraphStorePort and GraphReplicationPort')
abstract class TTGraphAdapter implements GraphStorePort, GraphReplicationPort {
  @override
  Future<TTNode?> fetchNode(String soul, {GraphReadOptions? options});

  @override
  Future<String?> fetchNodeJson(String soul, {GraphReadOptions? options});

  @override
  TTNode? fetchNodeSync(String soul, {GraphReadOptions? options});

  @override
  String? fetchNodeJsonSync(String soul, {GraphReadOptions? options});

  @override
  Future<TTGraphData?> writeGraph(TTGraphData graphData);

  @override
  TTGraphData? writeGraphSync(TTGraphData graphData);

  @override
  Future<void> pruneChangelog(num before);

  @override
  ChangeSetEntryFunc changesetFeed(String from);

  @override
  VoidCallback onChange(SetChangeSetEntryFunc handler, {String? from});

  @override
  void close();
}

typedef TTGetOpts = GraphReadOptions;
