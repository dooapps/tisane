import 'settings.dart' show shuffleAttackCutoff, check, parse;
import 'soul.dart' show pubFromSoul;
import '../types/enum.dart';
import '../types/tt.dart';

dynamic unpack([dynamic passedValue, String? key, TTNode? node]) {
  var value = passedValue;

  if (value == null) {
    return;
  }

  if (value.runtimeType == {}.runtimeType && value.containsKey(':')) {
    final val = value[':'];
    if (val != null) {
      return val;
    }
  }

  if (value.runtimeType == {}.runtimeType && value.containsKey('m')) {
    final val = value['m'];
    if (val != null) {
      value = int.parse(val);
    }
  }

  if (key == null || value == null) {
    return;
  }

  if (value == node![key]) {
    return value;
  }
  if (!check(node[key])) {
    return value;
  }
  final soul = node.nodeMetaData?.key;
  final state = node.nodeMetaData != null
      ? node.nodeMetaData!.forward != null
          ? node.nodeMetaData!.forward![key]
          : null
      : null;

  if (value is List &&
      value.length == 4 &&
      value[0] == soul &&
      value[1] == key &&
      state?.floor() == value[3].floor()) {
    return value[2];
  }

  if (state! < shuffleAttackCutoff) {
    return value;
  }
}

TTNode unpackNode(TTNode node, [MutableEnum mut = MutableEnum.immutable]) {
  final TTNode result = mut == MutableEnum.mutable
      ? node
      : TTNode.fromJson({'_': node.nodeMetaData?.toJson()});

  for (final key in node.keys) {
    result[key] = unpack(parse(node[key]), key, node);
  }

  return result;
}

TTGraphData unpackGraph(TTGraphData graph,
    [MutableEnum mut = MutableEnum.immutable]) {
  final TTGraphData unpackedGraph =
      mut == MutableEnum.mutable ? graph : TTGraphData();

  for (final soul in graph.keys) {
    final node = graph[soul];
    final pub = pubFromSoul(soul);

    unpackedGraph[soul] =
        node != null && pub.isNotEmpty ? unpackNode(node, mut) : node;
  }

  return unpackedGraph;
}
