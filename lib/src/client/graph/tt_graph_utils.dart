import 'dart:collection';

import 'package:uuid/uuid.dart';

import '../../types/tt.dart';
import '../tt_link.dart';
import '../interfaces.dart';
import 'tt_graph_node.dart';
import '../../ports/graph/graph_merge_port.dart';

String generateMessageId() {
  return const Uuid().v4();
}

List<List<String>> diffSets(
  final List<String> initial,
  final List<String> updated,
) {
  return [
    updated.where((key) => !initial.contains(key)).toList(),
    initial.where((key) => !updated.contains(key)).toList(),
  ];
}

bool isObject(Object? node) {
  return !(node is int ||
      node is String ||
      node is num ||
      num is double ||
      node is bool ||
      node == null);
}

bool isArray(Object? node) {
  return !(node == null || node is! List);
}

bool isMap(Object? node) {
  return !(node == null || node is! Map || node is! MapBase);
}

bool isNull(Object? node) {
  return node == null;
}

TTGraphData nodeToGraph(TTNode node, GraphMergePort mergePort) {
  final modified = {...node};
  TTGraphData nodes = TTGraphData();
  final nodeSoul = node.nodeMetaData?.key;

  for (final key in node.keys) {
    final val = node[key];
    if (!isObject(val) || val == null) {
      continue;
    }

    if (val is TTGraphNode) {
      if (val.soul.isNotEmpty) {
        final edge = {'#': val.soul};
        modified[key] = edge;

        continue;
      }
    }

    String soul = '';

    if (val is TTNode) {
      soul = val.nodeMetaData!.key!;
    }

    if (val is TTLink && val.soul != null && val.soul!.isNotEmpty) {
      soul = val.soul!;
    }

    if (soul.isNotEmpty) {
      final edge = {'#': soul};
      modified[key] = edge;
      final graph = mergePort.addMissingState(nodeToGraph(val, mergePort));
      final diff = mergePort.diffGraph(graph, nodes);
      nodes = !isNull(diff) ? mergePort.mergeGraph(nodes, diff!) : nodes;
    }
  }

  // print('SD:: ${modified.toString()} $nodeSoul');

  TTGraphData raw = TTGraphData();
  raw[nodeSoul!] = TTNode.fromJson(modified);
  final withMissingState = mergePort.addMissingState(raw);
  final graphDiff = mergePort.diffGraph(withMissingState, nodes);
  nodes = !isNull(graphDiff) ? mergePort.mergeGraph(nodes, graphDiff!) : nodes;

  return nodes;
}

TTGraphData flattenGraphData(GraphMergePort mergePort, TTGraphData data) {
  final List<TTGraphData> graphs = [];
  TTGraphData flatGraph = TTGraphData();

  for (final soul in data.keys) {
    final node = data[soul];
    if (!isNull(node)) {
      graphs.add(nodeToGraph(node!, mergePort));
    }
  }

  for (final graph in graphs) {
    final diff = mergePort.diffGraph(graph, flatGraph);
    flatGraph = !isNull(diff)
        ? mergePort.mergeGraph(flatGraph, diff!)
        : flatGraph;
  }

  return flatGraph;
}

PathData getPathData(List<String> keys, TTGraphData graph) {
  final lastKey = keys[keys.length - 1];

  if (keys.length == 1) {
    return PathData(
      souls: keys,
      complete: graph.containsKey(lastKey),
      value: graph[lastKey],
    );
  }

  PathData getPathDataParent = getPathData(
    keys.sublist(0, keys.length - 1),
    graph,
  );

  if (!isObject(getPathDataParent.value)) {
    return PathData(
      souls: getPathDataParent.souls,
      complete: getPathDataParent.complete || !isNull(getPathDataParent.value),
      value: null,
    );
  }

  final value = getPathDataParent.value[lastKey];

  if (isNull(value)) {
    return PathData(
      souls: getPathDataParent.souls,
      complete: true,
      value: value,
    );
  }

  String? edgeSoul;

  if (isObject(value)) {
    edgeSoul = value['#'];
  }

  if (!isNull(edgeSoul)) {
    return PathData(
      souls: [...getPathDataParent.souls, edgeSoul!],
      complete: graph.containsKey(edgeSoul),
      value: graph[edgeSoul],
    );
  }

  return PathData(souls: getPathDataParent.souls, complete: true, value: value);
}
