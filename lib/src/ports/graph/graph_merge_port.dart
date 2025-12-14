import '../../types/tt.dart';
import '../../types/enum.dart';

abstract class GraphMergePort {
  TTGraphData addMissingState(TTGraphData graphData);

  TTGraphData? diffGraph(TTGraphData updatedGraph, TTGraphData existingGraph);

  TTGraphData mergeGraph(TTGraphData existing, TTGraphData diff,
      {MutableEnum mut = MutableEnum.immutable});

  TTNode? mergeNodes(TTNode? existing, TTNode? updates,
      {MutableEnum mut = MutableEnum.immutable});
}
