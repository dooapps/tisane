import 'package:test/test.dart';
import 'package:tisane/src/adapters/graph/default_graph_transport_adapter.dart';
import 'package:tisane/src/client/transports/tt_graph_connector.dart';

import '../contracts/graph_transport_port_contract.dart';

class _RecordingConnector extends TTGraphConnector {
  _RecordingConnector() : super(name: 'RecordingConnector');
}

void main() {
  defineGraphTransportPortContract(
    'DefaultGraphTransportAdapter',
    () => DefaultGraphTransportAdapter(_RecordingConnector()),
  );

  test('exposes connector-backed events', () {
    final transport = DefaultGraphTransportAdapter(_RecordingConnector());
    expect(transport.events.connection, isNotNull);
    expect(transport.isConnected, isFalse);
  });
}
