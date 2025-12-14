import 'dart:convert';

import '../types/tt_graph_types.dart';
import '../types/enum.dart';
import '../types/tt.dart';

TTGraphData addMissingState(TTGraphData graphData) {
  final updatedGraphData = graphData;
  final now = DateTime.now().millisecondsSinceEpoch;

  for (final soul in graphData.entries) {
    if (soul.value == null) {
      continue;
    }

    var node = soul.value;

    var meta = (node?.nodeMetaData = node.nodeMetaData ?? TTNodeMeta());
    meta?.key = soul.key;
    var state = (meta?.forward = meta.forward ?? TTNodeState());

    for (final key in node!.keys) {
      if (key == '_') {
        continue;
      }
      state?[key] = state[key] ?? now;
    }
    updatedGraphData[soul.key] = node;
  }

  return updatedGraphData;
}

TTGraphData? diffTTCRDT(TTGraphData updatedGraph, TTGraphData existingGraph,
    {CrdtOption? opts}) {
  opts ??= CrdtOption(lexical: jsonEncode, futureGrace: 10 * 60 * 1000);

  var machineState = DateTime.now().millisecondsSinceEpoch,
      futureGrace = opts.futureGrace,
      lexical = opts.lexical!;

  final maxState = machineState + futureGrace!;

  final TTGraphData allUpdates = TTGraphData();

  for (final soul in updatedGraph.entries) {
    final TTNode? existing = existingGraph[soul.key];
    final TTNode? updated = soul.value;

    final TTNodeState existingState =
        existing?.nodeMetaData?.forward ?? TTNodeState();
    final TTNodeState updatedState =
        updated?.nodeMetaData?.forward ?? TTNodeState();

    if (updated == null) {
      if (existing == null) {
        allUpdates[soul.key] = updated;
      }
      continue;
    }

    var hasUpdates = false;

    final TTNode updates =
        TTNode(nodeMetaData: TTNodeMeta(key: soul.key, forward: TTNodeState()));

    for (final key in updatedState.keys) {
      final existingKeyState = existingState[key];
      final updatedKeyState = updatedState[key];

      if (updatedKeyState == null || updatedKeyState > maxState) {
        continue;
      }
      if (existingKeyState != null && existingKeyState >= updatedKeyState) {
        continue;
      }

      if (existingKeyState == updatedKeyState) {
        final existingVal = existing?[key];
        final updatedVal = updated[key];
        // This follows the original GUN conflict resolution logic
        if (lexical(updatedVal) <= lexical(existingVal)) {
          continue;
        }
      }

      updates[key] = updated[key];
      updates.nodeMetaData?.forward![key] = updatedKeyState;
      hasUpdates = true;
    }

    if (hasUpdates) {
      allUpdates[soul.key] = updates;
    }
  }

  return allUpdates.isNotEmpty ? allUpdates : null;
}

TTNode? mergeTTNodes(TTNode? existing, TTNode? updates,
    {MutableEnum mut = MutableEnum.immutable}) {
  if (existing == null) {
    return updates;
  }
  if (updates == null) {
    return existing;
  }
  final existingMeta = existing.nodeMetaData ?? TTNodeMeta();
  final existingState = existingMeta.forward ?? TTNodeState();
  final updatedMeta = updates.nodeMetaData ?? TTNodeMeta();
  final updatedState = updatedMeta.forward ?? TTNodeState();

  if (mut == MutableEnum.mutable) {
    existingMeta.forward = existingState;
    existing.nodeMetaData = existingMeta;

    for (final key in updatedState.keys) {
      existing[key] = updates[key];
      existingState[key] = updatedState[key]!;
    }

    return existing;
  }

  return TTNode.fromJson({
    ...existing,
    ...updates,
    "_": {
      "#": existingMeta.key,
      ">": {...?existingMeta.forward, ...?updates.nodeMetaData?.forward}
    }
  });
}

TTGraphData mergeGraph(TTGraphData existing, TTGraphData diff,
    {MutableEnum mut = MutableEnum.immutable}) {
  final TTGraphData result = existing;
  for (final soul in diff.keys) {
    result[soul] = mergeTTNodes(existing[soul], diff[soul], mut: mut);
  }

  return result;
}
