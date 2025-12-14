import '../../client/graph/tt_graph.dart';
import '../../client/flow/tt_event.dart';

class GraphTransportEvents {
  final TTEvent<dynamic, String?, String?> graphData;
  final TTEvent<bool, dynamic, dynamic> connection;

  GraphTransportEvents({required this.graphData, required this.connection});
}

/// Abstraction over graph transport wiring so TTGraph does not
/// depend on concrete connector types.
abstract class GraphTransportPort {
  GraphTransportEvents get events;
  bool get isConnected;
  GraphTransportPort connectToGraph(TTGraph graph);
  void detach();
}
