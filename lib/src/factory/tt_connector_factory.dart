import '../client/transports/tt_graph_connector.dart';
import '../ports/transport_port.dart';
import '../adapters/graph/default_graph_transport_adapter.dart';
import '../ports/graph/graph_transport_port.dart';
import '../adapters/transport/web_socket_transport_adapter.dart';

/// Factory responsible for producing graph connectors used by the client.
abstract class TTConnectorFactory {
  /// Returns a connector (legacy) for advanced use or wrapping.
  TTGraphConnector create(String url);

  /// Convenience wrapper that produces a GraphTransportPort using a connector under the hood.
  GraphTransportPort createTransport(String url);
}

class DefaultTTConnectorFactory implements TTConnectorFactory {
  DefaultTTConnectorFactory({TTTransportPort? transportPort})
      : _transportPort = transportPort ?? createDefaultTransportPort();

  final TTTransportPort _transportPort;

  @override
  TTGraphConnector create(String url) {
    return _transportPort.createConnector(url);
  }

  @override
  GraphTransportPort createTransport(String url) =>
      DefaultGraphTransportAdapter(create(url));
}
