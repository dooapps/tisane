import 'package:test/test.dart';
import 'package:tisane/src/ports/graph/graph_transport_port.dart';
import 'package:tisane/src/client/graph/tt_graph.dart';

/// Contract tests for GraphTransportPort minimal semantics.
///
/// Verifies wiring to TTGraph and connection signalling via events.
void defineGraphTransportPortContract(
  String name,
  GraphTransportPort Function() create,
) {
  group('GraphTransportPort contract: $name', () {
    test(
      'connectToGraph returns self and connection signals propagate',
      () async {
        final transport = create();
        final graph = TTGraph();

        expect(() => transport.connectToGraph(graph), returnsNormally);
        // Simulate underlying connection=True via port event and observe proxy
        transport.events.connection.trigger(true);
        await Future<void>.delayed(const Duration(milliseconds: 20));
        expect(transport.isConnected, isTrue);

        // and then False
        transport.events.connection.trigger(false);
        await Future<void>.delayed(const Duration(milliseconds: 20));
        expect(transport.isConnected, isFalse);

        expect(() => transport.detach(), returnsNormally);
      },
    );
  });
}
