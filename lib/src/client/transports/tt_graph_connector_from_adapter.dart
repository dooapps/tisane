import '../../types/tt.dart';

import '../../types/tt_graph_types.dart';
import '../../ports/graph/graph_store_port.dart';
import '../../ports/graph/graph_replication_port.dart';
import '../../types/graph_change.dart';
import '../graph/tt_graph_utils.dart';
import 'tt_graph_wire_connector.dart';

Null noop() => null;

class TTGraphConnectorFromAdapter extends TTGraphWireConnector {
  TTGraphConnectorFromAdapter({
    required GraphStorePort store,
    GraphReplicationPort? replication,
    super.name = 'TTGraphConnectorFromAdapter',
  })  : _store = store,
        _replication = replication ?? _NoopReplication();

  final GraphStorePort _store;
  // Currently not used directly in this connector, kept for parity with factory wiring
  // ignore: unused_field
  final GraphReplicationPort _replication;

  @override
  VoidCallback get(TTGet request, [dynamic _, dynamic __]) {
    _store.fetchNode(request.soul).then((node) {
      TTGraphData ttGraphData = TTGraphData();
      ttGraphData[request.soul] = node;
      return TTMsg(
          key: generateMessageId(),
          pos: request.msgId ?? '',
          put: !isNull(node) ? ttGraphData : null);
    }).catchError((err) {
      assert(() {
        // ignore: avoid_print
        print(err);
        return true;
      }());

      return TTMsg(
          key: generateMessageId(),
          pos: request.msgId ?? '',
          err: 'Error fetching node');
    }).then((msg) {
      ingest([msg]);
      if (!isNull(request.cb)) {
        request.cb!(msg);
      }
    });

    return noop;
  }

  @override
  VoidCallback put(TTPut request, [dynamic _, dynamic __]) {
    _store
        .writeGraph(request.graph)
        .then((node) => TTMsg(
            key: generateMessageId(),
            pos: request.msgId ?? '',
            err: null,
            ok: true))
        .catchError((err) {
      assert(() {
        // ignore: avoid_print
        print(err);
        return true;
      }());

      return TTMsg(
          key: generateMessageId(),
          pos: request.msgId ?? '',
          err: 'Error saving put',
          ok: false);
    }).then((msg) {
      ingest([msg]);
      if (!isNull(request.cb)) {
        request.cb!(msg);
      }
    });

    return noop;
  }
}

class _NoopReplication implements GraphReplicationPort {
  @override
  ChangeSetEntryFunc changesetFeed(String from) => () async => null;

  @override
  VoidCallback onChange(SetChangeSetEntryFunc handler, {String? from}) => () {};

  @override
  Future<void> pruneChangelog(num before) async {}
}
