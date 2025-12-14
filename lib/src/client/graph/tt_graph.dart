import 'dart:async';
import 'dart:collection';

import '../../types/tt_graph_types.dart';
import '../../types/enum.dart';
import '../../types/generic.dart';
import '../../types/tt.dart';
import '../../ports/graph/graph_merge_port.dart';
import '../../adapters/graph/default_graph_merge_adapter.dart';
import '../../types/graph_change.dart';
import '../flow/tt_event.dart';
import '../interfaces.dart';
import '../../ports/graph/graph_transport_port.dart';
import 'tt_graph_node.dart';
import 'tt_graph_utils.dart';

class TTGraphOptions {
  MutableEnum? mutable;
}

typedef UUIDFuncType = FutureOr<String> Function(List<String> path);
typedef GraphConnectorFuncType = void Function(GraphTransportPort transport);

class TTGraphEvent {
  final TTEvent<TTGraphData, String?, String?> graphData;

  final TTEvent<TTPut, dynamic, dynamic> put;
  final TTEvent<TTGet, dynamic, dynamic> get;
  final TTEvent<String, dynamic, dynamic> off;

  TTGraphEvent(
      {required this.graphData,
      required this.put,
      required this.get,
      required this.off});
}

class TTGraphNodeMap extends GenericCustomValueMap<String, TTGraphNode> {}

class TTGraph {
  final GraphMergePort _mergePort;

  late final String id;

  late final TTGraphEvent events;

  late num activeConnectors;

  late final TTGraphOptions _opt;

  late final List<GraphTransportPort> _transports;

  late final List<TTMiddleware> _readMiddleware;

  late final List<TTMiddleware> _writeMiddleware;

  late final TTGraphData _graph;

  late final TTGraphNodeMap _nodes;
  late final Map<GraphTransportPort, EventCb<dynamic, String?, String?>>
      _graphDataHandlers;

  TTGraph({GraphMergePort? mergePort})
      : _mergePort = mergePort ?? const DefaultGraphMergePort() {
    id = generateMessageId();
    activeConnectors = 0;
    events = TTGraphEvent(
      graphData: TTEvent<TTGraphData, String?, String?>(name: 'graph data'),
      get: TTEvent<TTGet, dynamic, dynamic>(name: 'request soul'),
      off: TTEvent<String, dynamic, dynamic>(name: 'off event'),
      put: TTEvent<TTPut, dynamic, dynamic>(name: 'put data'),
    );
    _opt = TTGraphOptions();
    _opt.mutable = MutableEnum.immutable;
    _graph = TTGraphData();
    _nodes = TTGraphNodeMap();
    _transports = [];
    _readMiddleware = [];
    _writeMiddleware = [];
    _graphDataHandlers = {};
  }

  /// Configure graph options
  ///
  /// Currently unused
  ///
  /// @param options
  TTGraph opt(TTGraphOptions options) {
    _opt = options;
    return this;
  }

  TTGraphOptions getOpt() {
    return _opt;
  }

  /// Connect to a source/destination for graph data
  ///
  /// @param connector the source or destination for graph data
  TTGraph connect(GraphTransportPort transport) {
    if (_transports.contains(transport)) {
      return this;
    }
    _transports.add(transport.connectToGraph(this));

    transport.events.connection.on(__onConnectorStatus);
    FutureOr<void> handler(dynamic a, [String? id, String? reply]) =>
        _receiveGraphData(a as TTGraphData, id, reply);
    transport.events.graphData.on(handler);
    _graphDataHandlers[transport] = handler;

    if (transport.isConnected) {
      activeConnectors++;
    }
    return this;
  }

  /// Disconnect from a source/destination for graph data
  ///
  /// @param connector the source or destination for graph data
  TTGraph disconnect(GraphTransportPort transport) {
    final idx = _transports.indexOf(transport);
    if (idx != -1) {
      final t = _transports[idx];
      final handler = _graphDataHandlers.remove(t);
      if (handler != null) {
        t.events.graphData.off(handler);
      }
      t.events.connection.off(__onConnectorStatus);
      t.detach();
      _transports.removeAt(idx);
    }
    return this;
  }

  /// Register graph middleware
  ///
  /// @param middleware The middleware function to add
  /// @param kind Optionaly register write middleware instead of read by passing "write"
  TTGraph use(TTMiddleware middleware,
      {TTMiddlewareType kind = TTMiddlewareType.read}) {
    if (kind == TTMiddlewareType.read) {
      _readMiddleware.add(middleware);
    } else if (kind == TTMiddlewareType.write) {
      _writeMiddleware.add(middleware);
    }
    return this;
  }

  /// Unregister graph middleware
  ///
  /// @param middleware The middleware function to remove
  /// @param kind Optionaly unregister write middleware instead of read by passing "write"
  TTGraph unuse(TTMiddleware middleware,
      {TTMiddlewareType kind = TTMiddlewareType.read}) {
    if (kind == TTMiddlewareType.read) {
      final idx = _readMiddleware.indexOf(middleware);
      if (idx != -1) {
        _readMiddleware.removeAt(idx);
      }
    } else if (kind == TTMiddlewareType.write) {
      final idx = _writeMiddleware.indexOf(middleware);
      if (idx != -1) {
        _writeMiddleware.removeAt(idx);
      }
    }

    return this;
  }

  /// Read a potentially multi-level deep path from the graph
  ///
  /// @param path The path to read
  /// @param cb The callback to invoke with results
  /// @returns a cleanup function to after done with query
  VoidCallback query(List<String> path, TTOnCb cb) {
    List<String> lastSouls = [];
    TTValue currentValue;

    updateQuery(TTNode? _, [dynamic __, dynamic ___]) {
      PathData getPathDateList = getPathData(path, _graph);

      List<String> souls = getPathDateList.souls;
      TTValue value = getPathDateList.value;
      bool complete = getPathDateList.complete;

      final diffSetsList = diffSets(lastSouls, souls);

      List<String> added = diffSetsList[0];
      List<String> removed = diffSetsList[1];

      if ((complete && currentValue == null) ||
          (value != null && value != currentValue)) {
        currentValue = value;
        cb(value, path[path.length - 1]);
      }

      for (final soul in added) {
        _requestSoul(soul, updateQuery);
      }

      for (final soul in removed) {
        _unlistenSoul(soul, updateQuery);
      }

      lastSouls = souls;
    }

    updateQuery(null);

    return () {
      for (final soul in lastSouls) {
        _unlistenSoul(soul, updateQuery);
      }
    };
  }

  FutureOr<String> _internalUUIdFn(List<String> path) {
    return path.join('/');
  }

  TTGraphData _getPutPathTTGraph(List<String> souls, TTValue data) {
    // Create a new Map for the converted JSON
    TTGraphData data2 = TTGraphData();
    var data1 = {};
    var temp = data1;
    for (var i = 0; i < souls.length; i++) {
      if (i != souls.length - 1) {
        temp[souls[i]] = {};
        temp = temp[souls[i]];
      } else {
        temp[souls[i]] = data;
      }
    }

    // Create a queue to store the keys and values that need to be processed
    var queue = Queue();
    var pathQueue = Queue();

    // Add the root data to the queue
    queue.addAll(data1.entries);
    for (var i = 0; i < data1.entries.length; i++) {
      pathQueue.add("");
    }

    // Keep processing the keys and values in the queue until it is empty
    while (queue.isNotEmpty) {
      // Get the next key and value from the queue
      var entry = queue.removeFirst();
      var key = entry.key;
      var value = entry.value;
      var path = "";
      if (pathQueue.isNotEmpty) {
        path = pathQueue.removeFirst();
      }
      // Concatenate the current key to the path
      var currentPath = path.isEmpty
          ? key
          : path.contains("~@")
              ? key
              : '$path/$key';

      // Check if the value is a Map (i.e. another nested dictionary)
      if (value is Map) {
        // If it is a Map, create a new Map for the converted data
        Map<String, dynamic> currentData2 = {};

        // Add the metadata to the Map
        currentData2['_'] = {'#': currentPath, '>': {}};

        for (final entry in value.entries) {
          currentData2['_']['>'][entry.key] =
              DateTime.now().millisecondsSinceEpoch;
          if (entry.value is Map) {
            currentData2[entry.key] = {
              "#": currentPath.contains("~@")
                  ? entry.key
                  : "$currentPath/${entry.key}"
            };
          } else {
            currentData2[entry.key] = entry.value;
          }
        }

        // Add the Map to the converted data
        data2[currentPath] = TTNode.fromJson(currentData2);

        // Add the nested data to the queue
        queue.addAll(value.entries);
        for (var i = 0; i < value.entries.length; i++) {
          pathQueue.add(currentPath);
        }
      }
    }

    return data2;
  }

  /// Write graph data to a potentially multi-level deep path in the graph
  ///
  /// @param path The path to read
  /// @param data The value to write
  /// @param cb Callback function to be invoked for write acks
  /// @returns a promise
  Future<void> putPath(final List<String> fullPath, TTValue data,
      [TTMsgCb? cb, UUIDFuncType? uuidFn]) async {
    uuidFn ??= _internalUUIdFn;
    if (fullPath.isEmpty) {
      throw ("No path specified");
    }

    TTGraphData graph = _getPutPathTTGraph(fullPath, data);

    put(graph, cb);
  }

  Future<List<String>> getPathSouls(List<String> path) async {
    var completer = Completer<List<String>>();

    if (path.length == 1) {
      completer.complete(path);
    }

    List<String> lastSouls = [];

    updateQuery(TTNode? _, [dynamic __, dynamic ___]) {
      PathData getPathDataList = getPathData(path, _graph);

      List<String> souls = getPathDataList.souls;
      bool complete = getPathDataList.complete;

      // print('updateQuery: ${souls.toString()} -- $complete');

      final diffSetsList = diffSets(lastSouls, souls);

      dynamic added = diffSetsList[0];
      dynamic removed = diffSetsList[1];

      // print('diffSetsList:: ${added.toString()} -- ${removed.toString()}');

      end() {
        for (final soul in lastSouls) {
          _unlistenSoul(soul, updateQuery);
        }
        lastSouls = [];
      }

      if (complete) {
        end();
        if (!completer.isCompleted) {
          completer.complete(souls);
        }
        return;
      } else {
        for (final soul in added) {
          _requestSoul(soul, updateQuery);
        }

        for (final soul in removed) {
          _unlistenSoul(soul, updateQuery);
        }
      }

      lastSouls = souls;
    }

    updateQuery(null);

    return completer.future;
  }

  /// Request node data
  ///
  /// @param soul identifier of node to request
  /// @param cb callback for response messages
  /// @param msgId optional unique message identifier
  /// @returns a function to cleanup listeners when done
  VoidCallback get(String soul, [TTMsgCb? cb, String? msgId]) {
    String id = msgId ?? generateMessageId();

    events.get.trigger(TTGet(cb: cb, msgId: msgId, soul: soul));

    return () => events.off.trigger(id);
  }

  /// Write node data
  ///
  /// @param data one or more TT nodes keyed by soul
  /// @param cb optional callback for response messages
  /// @param msgId optional unique message identifier
  /// @returns a function to clean up listeners when done
  VoidCallback put(TTGraphData data, [TTMsgCb? cb, String? msgId]) {
    final TTGraphData normalized = _mergePort.addMissingState(data);
    TTGraphData? diff = flattenGraphData(_mergePort, normalized);

    final String id = msgId ?? generateMessageId();
    (() async {
      for (final fn in _writeMiddleware) {
        if (diff == null) {
          return;
        }
        diff = await fn(diff!, _graph);
      }
      if (diff == null) {
        return;
      }

      // print('Data-->Encoded::Sent:: ${jsonEncode(diff)}');

      events.put.trigger(TTPut(graph: diff!, cb: cb, msgId: id));

      _receiveGraphData(diff!);
    })();

    return () => events.off.trigger(id);
  }

  /// Synchronously invoke callback function for each connector to this graph
  ///
  /// @param cb The callback to invoke
  TTGraph eachConnector(GraphConnectorFuncType cb) {
    // No-op: connector callback retained for compatibility; transports conceal connector types.

    return this;
  }

  /// Update graph data in this node from some local or external source
  ///
  /// @param data node data to include
  FutureOr<void> _receiveGraphData(TTGraphData data,
      [String? id, String? replyToId]) async {
    TTGraphData? diff = data;

    for (final fn in _readMiddleware) {
      if (diff == null) {
        return;
      }
      diff = await fn(diff, _graph);
    }

    if (diff == null) {
      return;
    }

    for (final soul in diff.keys) {
      final node = _nodes[soul];
      if (node == null) {
        continue;
      }
      node.receive((_graph[soul] =
          _mergePort.mergeNodes(_graph[soul], diff[soul], mut: _opt.mutable!)));
    }

    events.graphData.trigger(diff, id, replyToId);
  }

  TTGraphNode _node(String soul) {
    return (_nodes[soul] = _nodes[soul] ??
        TTGraphNode(graph: this, soul: soul, updateGraph: _receiveGraphData));
  }

  TTGraph _requestSoul(String soul, TTNodeListenCb cb) {
    _node(soul).get(cb);
    return this;
  }

  TTGraph _unlistenSoul(String soul, TTNodeListenCb cb) {
    if (!_nodes.containsKey(soul)) {
      return this;
    }
    final node = _nodes[soul];
    if (node == null) {
      return this;
    }
    node.off(cb);
    if (node.listenerCount() <= 0) {
      node.off();
      _forgetSoul(soul);
    }
    return this;
  }

  TTGraph _forgetSoul(String soul) {
    if (!_nodes.containsKey(soul)) {
      return this;
    }
    final node = _nodes[soul];
    if (node != null) {
      node.off();
      _nodes.remove(soul);
    }

    _graph.remove(soul);
    return this;
  }

  void __onConnectorStatus(bool connected, [dynamic _, dynamic __]) {
    if (connected == true) {
      activeConnectors++;
    } else {
      activeConnectors--;
    }
  }
}
