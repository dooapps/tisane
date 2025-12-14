import '../../crdt/index.dart' as crdt;
import '../../ports/graph/graph_merge_port.dart';
import '../../types/enum.dart';
import '../../types/tt.dart';

class DefaultGraphMergePort implements GraphMergePort {
  const DefaultGraphMergePort();

  @override
  TTGraphData addMissingState(TTGraphData graphData) =>
      crdt.addMissingState(graphData);

  @override
  TTGraphData? diffGraph(TTGraphData updatedGraph, TTGraphData existingGraph) =>
      crdt.diffTTCRDT(updatedGraph, existingGraph);

  @override
  TTGraphData mergeGraph(TTGraphData existing, TTGraphData diff,
          {MutableEnum mut = MutableEnum.immutable}) =>
      crdt.mergeGraph(existing, diff, mut: mut);

  @override
  TTNode? mergeNodes(TTNode? existing, TTNode? updates,
          {MutableEnum mut = MutableEnum.immutable}) =>
      crdt.mergeTTNodes(existing, updates, mut: mut);
}
