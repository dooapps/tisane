import '../../types/tt.dart';
import '../flow/tt_event.dart';
import '../interfaces.dart';
import 'tt_graph.dart';
import '../../types/graph_change.dart';

typedef UpdateGraphFunc =
    void Function(TTGraphData data, [String? id, String? replyToId]);

class TTGraphNode {
  final String soul;

  late final TTEvent<TTNode?, dynamic, dynamic> _data;
  late final TTGraph _graph;
  VoidCallback? _endCurQuery;
  late final UpdateGraphFunc _updateGraph;

  TTGraphNode({
    required this.soul,
    required TTGraph graph,
    required UpdateGraphFunc updateGraph,
  }) {
    _graph = graph;
    _updateGraph = updateGraph;
    _data = TTEvent<TTNode?, dynamic, dynamic>(name: '<TTGraphNode $soul>');
  }

  num listenerCount() {
    return _data.listenerCount();
  }

  TTGraphNode get(TTNodeListenCb? cb) {
    if (cb != null) {
      on(cb);
    }
    _ask();
    return this;
  }

  TTGraphNode on(TTNodeListenCb cb) {
    _data.on(cb);
    return this;
  }

  TTGraphNode off([TTNodeListenCb? cb]) {
    if (cb != null) {
      _data.off(cb);
    } else {
      _data.reset();
    }

    if (_endCurQuery != null && _data.listenerCount() == 0) {
      _endCurQuery!();
      _endCurQuery = null;
    }

    return this;
  }

  TTGraphNode receive(TTNode? data) {
    _data.trigger(data, soul);
    return this;
  }

  TTGraphNode _ask() {
    if (_endCurQuery != null) {
      return this;
    }

    _graph.get(soul, _onDirectQueryReply);
    return this;
  }

  void _onDirectQueryReply(TTMsg msg) {
    if (msg.put == null) {
      TTGraphData ttGraphData = TTGraphData();
      ttGraphData[soul] = null;
      _updateGraph(ttGraphData, msg.pos);
    }
  }
}
