import '../../types/tt.dart';
import 'graph_read_options.dart';

/// CRUD-focused graph storage operations.
abstract class GraphStorePort {
  Future<TTNode?> fetchNode(String soul, {GraphReadOptions? options});

  Future<String?> fetchNodeJson(String soul, {GraphReadOptions? options});

  TTNode? fetchNodeSync(String soul, {GraphReadOptions? options});

  String? fetchNodeJsonSync(String soul, {GraphReadOptions? options});

  Future<TTGraphData?> writeGraph(TTGraphData graphData);

  TTGraphData? writeGraphSync(TTGraphData graphData);

  void close();
}
