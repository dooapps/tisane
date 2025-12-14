import '../../client/transports/tt_graph_connector.dart';
import '../../client/transports/web_socket_graph_connector.dart';
import '../../ports/logger_port.dart';
import '../../ports/transport_port.dart';

/// Adapter that produces WebSocket-backed graph connectors via the transport port.
class WebSocketTransportAdapter implements TTTransportPort {
  WebSocketTransportAdapter({TTLogger? logger})
    : _logger = logger ?? createDefaultLogger();

  final TTLogger _logger;

  @override
  TTGraphConnector createConnector(String url) {
    _logger.debug('Creating WebSocket graph connector', context: {'url': url});
    return WebSocketGraphConnector(url: url);
  }
}

TTTransportPort createDefaultTransportPort({TTLogger? logger}) =>
    WebSocketTransportAdapter(logger: logger);
