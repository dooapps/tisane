import 'dart:async';

import '../../types/tt_graph_types.dart';
import '../../types/tt.dart';
import '../../types/graph_change.dart';
import '../flow/tt_event.dart';
import '../flow/tt_process_queue.dart';
import '../graph/tt_graph.dart';

class TTGraphConnectorEventType {
  final TTEvent<TTGraphData, String?, String?> graphData;

  final TTEvent<TTMsg, dynamic, dynamic> receiveMessage;
  final TTEvent<bool, dynamic, dynamic> connection;

  TTGraphConnectorEventType({
    required this.graphData,
    required this.receiveMessage,
    required this.connection,
  });
}

abstract class TTGraphConnector {
  final String name;
  late bool isConnected;

  late final TTGraphConnectorEventType events;

  late final TTProcessQueue<TTMsg, dynamic, dynamic> inputQueue;

  late final TTProcessQueue<TTMsg, dynamic, dynamic> outputQueue;

  TTGraphConnector({this.name = 'TTGraphConnector'}) {
    isConnected = false;
    inputQueue = TTProcessQueue<TTMsg, dynamic, dynamic>(
      name: '$name.inputQueue',
    );
    outputQueue = TTProcessQueue<TTMsg, dynamic, dynamic>(
      name: '$name.outputQueue',
    );
    events = TTGraphConnectorEventType(
      graphData: TTEvent<TTGraphData, String?, String?>(
        name: '$name.events.graphData',
      ),
      receiveMessage: TTEvent<TTMsg, dynamic, dynamic>(
        name: '$name.events.receiveMessage',
      ),
      connection: TTEvent<bool, dynamic, dynamic>(
        name: '$name.events.connection',
      ),
    );
    events.connection.on(__onConnectedChange);
  }

  TTGraphConnector off(String msgId, [dynamic _, dynamic __]) {
    return this;
  }

  TTGraphConnector sendPutsFromGraph(TTGraph graph) {
    graph.events.put.on(put);
    return this;
  }

  TTGraphConnector sendRequestsFromGraph(TTGraph graph) {
    graph.events.get.on((req, [dynamic _, dynamic __]) {
      get(req);
    });
    return this;
  }

  FutureOr<void> waitForConnection() {
    var completer = Completer<void>();

    if (isConnected) {
      return Future<void>.value();
    }
    onConnected(bool? connected, [dynamic _, dynamic __]) {
      if (!(connected ?? false)) {
        return;
      }
      completer.complete();
      events.connection.off(onConnected);
    }

    events.connection.on(onConnected);

    return completer.future;
  }

  /// Send graph data for one or more nodes
  ///
  /// @returns A function to be called to clean up callback listeners
  VoidCallback put(TTPut params, [dynamic _, dynamic __]) {
    return () {};
  }

  /// Request data for a given soul
  ///
  /// @returns A function to be called to clean up callback listeners
  VoidCallback get(TTGet params, [dynamic _, dynamic __]) {
    return () => {};
  }

  /// Queues outgoing messages for sending
  ///
  /// @param msgs The TT wire protocol messages to enqueue
  TTGraphConnector send(List<TTMsg> msgs) {
    outputQueue.enqueueMany(msgs);
    if (isConnected) {
      outputQueue.process();
    }

    return this;
  }

  /// Queue incoming messages for processing
  ///
  /// @param msgs
  TTGraphConnector ingest(List<TTMsg> msgs) {
    inputQueue.enqueueMany(msgs).process();

    return this;
  }

  TTGraphConnector connectToGraph(TTGraph graph) {
    graph.events.off.on(off);
    return this;
  }

  void __onConnectedChange(bool connected, [dynamic _, dynamic __]) {
    if (connected) {
      isConnected = true;
      outputQueue.process();
    } else {
      isConnected = false;
    }
  }
}
