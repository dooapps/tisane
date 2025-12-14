import 'dart:convert';

import '../crdt/index.dart' show mergeTTNodes;

import '../types/tt.dart';
import 'init.dart';

TTGraphData getStoreData(TTGraphData graph, [num activeConnectors = 0]) {
  if (InitStorage.hiveOpenBox == null ||
      InitStorage.hiveOpenBox!.isOpen == false) {
    throw ("Initialize TipTool storage using: `await initializeTTStore()`");
  }

  if (activeConnectors > 0) {
    return graph;
  }

  final TTGraphData unpackedGraph = graph;

  for (final soul in graph.keys) {
    TTNode? node;
    if (InitStorage.hiveOpenBox!.containsKey(soul)) {
      TTNode tempNode =
          TTNode.fromJson(jsonDecode(InitStorage.hiveOpenBox?.get(soul)));
      node = mergeTTNodes(tempNode, graph[soul]);
      node?.nodeMetaData = graph[soul]?.nodeMetaData;
    } else {
      node = graph[soul];
    }

    unpackedGraph[soul] = node;
  }

  return unpackedGraph;
}

TTGraphData setStoreData(TTGraphData graph) {
  if (InitStorage.hiveOpenBox == null ||
      InitStorage.hiveOpenBox!.isOpen == false) {
    throw ("Initialize TipTool storage using: `await initializeTTStore()`");
  }

  final TTGraphData unpackedGraph = graph;

  for (final soul in graph.keys) {
    TTNode? node;
    if (InitStorage.hiveOpenBox!.containsKey(soul)) {
      TTNode tempNode =
          TTNode.fromJson(jsonDecode(InitStorage.hiveOpenBox?.get(soul)));
      node = mergeTTNodes(tempNode, graph[soul]);
      node?.nodeMetaData = graph[soul]?.nodeMetaData;
    } else {
      node = graph[soul];
    }

    InitStorage.hiveOpenBox?.put(soul, jsonEncode(node));

    unpackedGraph[soul] = node;
  }

  return unpackedGraph;
}
