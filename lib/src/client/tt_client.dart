import 'dart:async';

import '../adapters/graph/default_graph_merge_adapter.dart';
import '../factory/tt_connector_factory.dart';
import '../ports/logger_port.dart';
import '../types/tt_graph_types.dart';
import '../types/graph_change.dart';
import 'tt_link.dart';
import 'graph/tt_graph.dart';
import 'interfaces.dart';
import '../sea/middleware/infusion_security_middleware.dart';

/// Configuration values shared across the TipTool client.
class TTOptions {
  TTOptions({
    List<String>? peers,
    this.graph,
    this.connectorFactory,
    this.logger,
  }) : peers = peers ?? <String>[];

  List<String> peers;
  TTGraph? graph;
  TTConnectorFactory? connectorFactory;
  TTLogger? logger;

  void merge(TTOptions options) {
    if (options.peers.isNotEmpty) {
      peers = options.peers;
    }
    graph = options.graph ?? graph;
    connectorFactory = options.connectorFactory ?? connectorFactory;
    logger = options.logger ?? logger;
  }
}

/// Main entry point for working with TT graphs and remote peers.
class TTClient {
  TTClient({
    this.linkClass,
    TTOptions? options,
    TTConnectorFactory? connectorFactory,
    TTLogger? logger,
  }) : _connectorFactory =
           connectorFactory ??
           options?.connectorFactory ??
           DefaultTTConnectorFactory(),
       _logger = logger ?? options?.logger ?? createDefaultLogger() {
    _initialize(linkClass: linkClass, options: options);
  }

  late final TTGraph graph;
  TTLink? linkClass;

  final TTConnectorFactory _connectorFactory;
  TTLogger _logger;

  void _initialize({TTLink? linkClass, TTOptions? options}) {
    final effectiveOptions = options ?? TTOptions();
    this.linkClass = linkClass;

    graph = effectiveOptions.graph ?? _createDefaultGraph();
    _logger = effectiveOptions.logger ?? _logger;

    if (effectiveOptions.peers.isNotEmpty) {
      _wirePeers(effectiveOptions.peers);
    }
  }

  TTGraph _createDefaultGraph() {
    const mergePort = DefaultGraphMergePort();
    final instance = TTGraph(mergePort: mergePort);

    // Register Infusion IP Vault Middleware
    instance.use(
      InfusionSecurityMiddleware.onRead,
      kind: TTMiddlewareType.read,
    );
    instance.use(
      InfusionSecurityMiddleware.onWrite,
      kind: TTMiddlewareType.write,
    );

    instance.use(mergePort.diffGraph);
    instance.use(mergePort.diffGraph, kind: TTMiddlewareType.write);
    return instance;
  }

  /// Configure the TT client
  ///
  /// @param options
  TTClient opt(TTOptions options) {
    if (options.logger != null) {
      _logger = options.logger!;
    }

    if (options.peers.isNotEmpty) {
      _wirePeers(options.peers);
    }

    return this;
  }

  void _wirePeers(List<String> peers) {
    for (final peer in peers) {
      final transport = _connectorFactory.createTransport(peer);
      graph.connect(transport);
      _logger.debug('Connected TTClient peer', context: {'peer': peer});
    }
  }

  /// Traverse a location in the graph
  ///
  /// @param key Key to read data from
  /// @param cb
  /// @returns New link context corresponding to given key
  TTLink get(String soul, [TTMsgCb? cb]) {
    return linkClass = TTLink(key: soul, client: this);
  }

  /// Traverse a location in the graph and Return the data
  ///
  /// @param key Key to read data from
  /// @param cb
  /// @returns New link context corresponding to given key
  Future<dynamic> getValue(
    String soul, {
    TTMsgCb? cb,
    Duration timeout = const Duration(seconds: 5),
  }) async {
    final completer = Completer<dynamic>();
    VoidCallback? disposeQuery;
    VoidCallback? disposeGet;
    Timer? timer;
    var completed = false;

    void finish(dynamic value, {Object? error}) {
      if (completed) return;
      completed = true;
      timer?.cancel();
      disposeQuery?.call();
      disposeGet?.call();
      
      if (error != null) {
        completer.completeError(error);
      } else {
        completer.complete(value);
      }
    }

    // Query the graph directly to avoid TTLink snapshot/once recursion.
    void onValue(dynamic value, [String? _, dynamic __]) {
      finish(value);
    }

    disposeQuery = graph.query([soul], onValue);
    
    // Proactively request the soul to ensure read-after-write over transports.
    // We keep this subscription active until we get a value or timeout.
    disposeGet = graph.get(soul, cb);

    timer = Timer(timeout, () {
      finish(null, error: TimeoutException('getValue timed out for $soul', timeout));
    });

    return completer.future;
  }
}
