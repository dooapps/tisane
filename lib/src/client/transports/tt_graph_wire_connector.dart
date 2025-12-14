import '../../types/tt_graph_types.dart';
import '../../types/generic.dart';
import '../../types/tt.dart';
import '../graph/tt_graph_utils.dart';
import 'tt_graph_connector.dart';
import '../../types/graph_change.dart';

class CallBacksMap extends GenericCustomValueMap<String, TTMsgCb> {}

abstract class TTGraphWireConnector extends TTGraphConnector {
  late final CallBacksMap _callbacks;

  TTGraphWireConnector({super.name = 'TTWireProtocol'}) {
    _callbacks = CallBacksMap();
    super.inputQueue.completed.on(_onProcessedInput);
  }

  @override
  TTGraphWireConnector off(String msgId, [dynamic _, dynamic __]) {
    super.off(msgId);
    _callbacks.remove(msgId);
    return this;
  }

  /// Send graph data for one or more nodes
  ///
  /// @returns A function to be called to clean up callback listeners
  @override
  VoidCallback put(TTPut request, [dynamic _, dynamic __]) {
    final TTMsg msg = TTMsg(put: request.graph);
    if (!isNull(request.msgId)) {
      msg.key = request.msgId;
    }
    if (!isNull(request.replyTo)) {
      msg.pos = request.replyTo;
    }

    return req(msg, request.cb);
  }

  /// Request data for a given soul
  ///
  /// @returns A function to be called to clean up callback listeners
  @override
  VoidCallback get(TTGet request, [dynamic _, dynamic __]) {
    final TTMsgGet get = TTMsgGet(key: request.soul);
    final TTMsg msg = TTMsg(get: get);
    if (!isNull(request.msgId)) {
      msg.key = request.msgId;
    }

    return req(msg, request.cb);
  }

  /// Send a message that expects responses via @
  ///
  /// @param msg
  /// @param cb
  VoidCallback req(TTMsg msg, TTMsgCb? cb) {
    final String reqId = msg.key = msg.key ?? generateMessageId();
    if (!isNull(cb)) {
      _callbacks[reqId] = cb!;
    }
    send([msg]);
    return () {
      off(reqId);
    };
  }

  void _onProcessedInput(TTMsg? msg, [dynamic _, dynamic __]) {
    if (isNull(msg)) {
      return;
    }
    final id = msg?.key;
    final replyTo = msg?.pos;

    if (!isNull(msg?.put)) {
      events.graphData.trigger(msg!.put!, id, replyTo);
    }

    if (!isNull(replyTo)) {
      final cb = _callbacks[replyTo];
      if (!isNull(cb)) {
        cb!(msg!);
      }
    }

    events.receiveMessage.trigger(msg!);
  }
}
