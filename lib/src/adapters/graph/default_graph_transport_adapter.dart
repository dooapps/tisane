import '../../client/graph/tt_graph.dart';
import '../../client/transports/tt_graph_connector.dart';
import '../../ports/graph/graph_transport_port.dart';

/// Adapter that wraps an existing TTGraphConnector behind GraphTransportPort.
class DefaultGraphTransportAdapter implements GraphTransportPort {
  DefaultGraphTransportAdapter(this._connector);

  final TTGraphConnector _connector;
  late final GraphTransportEvents _events = GraphTransportEvents(
    graphData: _connector.events.graphData
        as dynamic, // erase generic for port cohesion
    connection: _connector.events.connection,
  );

  @override
  GraphTransportPort connectToGraph(TTGraph graph) {
    _connector
      ..sendPutsFromGraph(graph)
      ..sendRequestsFromGraph(graph)
      ..connectToGraph(graph);
    return this;
  }

  @override
  void detach() {}

  @override
  @override
  GraphTransportEvents get events => _events;

  @override
  bool get isConnected => _connector.isConnected;
}
