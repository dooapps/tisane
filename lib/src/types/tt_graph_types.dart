import 'tt.dart';

typedef TTMsgCb = void Function(TTMsg msg);
typedef LexicalFunc = dynamic Function(TTValue x);

/// Envelope for graph updates sent to TT connectors.
class TTPut {
  late TTGraphData graph;
  String? msgId;
  String? replyTo;
  TTMsgCb? cb;

  TTPut({required this.graph, this.msgId, this.replyTo, this.cb});
}

/// Envelope for graph read requests sent to TT connectors.
class TTGet {
  late String soul;
  String? msgId;
  String? key;
  TTMsgCb? cb;
  TTGet({required this.soul, this.msgId, this.key, this.cb});
}

class CrdtOption {
  num? machineState;
  num? futureGrace;
  LexicalFunc? lexical;

  CrdtOption({this.machineState, this.futureGrace, this.lexical});
}
