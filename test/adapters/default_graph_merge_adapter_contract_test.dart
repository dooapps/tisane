import 'package:test/test.dart';
import 'package:tisane/src/adapters/graph/default_graph_merge_adapter.dart';
import 'package:tisane/src/ports/graph/graph_merge_port.dart';

import '../contracts/graph_merge_port_contract.dart';

void main() {
  defineGraphMergePortContract(
    'DefaultGraphMergePort',
    () => const DefaultGraphMergePort(),
  );

  test('instantiation', () {
    final port = const DefaultGraphMergePort();
    expect(port, isA<GraphMergePort>());
  });
}
