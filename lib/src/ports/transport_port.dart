import '../client/transports/tt_graph_connector.dart';

/// Port that can create connectors for graph transport.
abstract class TTTransportPort {
  TTGraphConnector createConnector(String url);
}
