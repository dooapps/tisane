import 'dart:async';

import '../types/tt_graph_types.dart';
import '../types/tt.dart';
import '../types/graph_change.dart';
import 'tt_client.dart';
import 'flow/tt_event.dart';
import 'graph/tt_graph_utils.dart';
import 'interfaces.dart';

class TTLink {
  final String key;
  late String? soul;

  late TTLinkOptions _opt;
  late final TTEvent<TTValue?, String, dynamic> _updateEvent;
  late final TTClient _client;
  TTLink? _parent;
  VoidCallback? _endQuery;
  TTValue? _lastValue;
  late bool _hasReceived;

  TTLink({required this.key, required TTClient client, TTLink? parent}) {
    if (isNull(parent)) {
      soul = key;
    }
    _opt = TTLinkOptions();
    _client = client;
    _parent = parent;
    _hasReceived = false;
    _updateEvent = TTEvent<TTValue?, String, dynamic>(
      name: getPath().join('|'),
    );
  }

  /// Publish a value to the current graph location, awaiting optional ack.
  Future<void> publish(TTValue value, {TTMsgCb? onAck}) async {
    await _client.graph.putPath(getPath(), value, onAck, opt().uuid);
  }

  /// Snapshot the current value without subscribing to updates.
  Future<TTValue?> snapshot({int? timeout}) async {
    // Guard against any potential re-entrancy by querying the graph directly.
    final completer = Completer<TTValue?>();
    VoidCallback dispose = () {};
    var completed = false;

    void onValue(TTValue? value, [String? _, dynamic __]) {
      if (completed) return;
      completed = true;
      completer.complete(value);
      dispose();
    }

    final path = getPath();
    dispose = _client.graph.query(path, onValue);
    final souls = await _client.graph.getPathSouls(path);
    for (final soul in souls) {
      final cleanup = _client.graph.get(soul);
      cleanup();
    }
    return completer.future;
  }

  /// Subscribe to updates and receive a disposer callback.
  VoidCallback subscribe(TTOnCb listener) {
    if (key == '') {
      // TODO: "Map logic"
    }

    _updateEvent.on(listener);
    if (isNull(_endQuery)) {
      _endQuery = _client.graph.query(getPath(), _onQueryResponse);
    }
    if (_hasReceived) {
      listener(_lastValue, key);
    }
    return () => unsubscribe(listener);
  }

  /// Remove a listener or all listeners for this link.
  void unsubscribe([TTOnCb? listener]) {
    if (!isNull(listener)) {
      _updateEvent.off(listener!);
      if (!isNull(_endQuery) && _updateEvent.listenerCount() == 0) {
        _endQuery!();
      }
    } else {
      if (!isNull(_endQuery)) {
        _endQuery!();
      }
      _updateEvent.reset();
    }
  }

  /// Request synchronization of the current path.
  Future<void> requestSync({TTMsgCb? onAck}) async {
    final souls = await _client.graph.getPathSouls(getPath());
    for (final soul in souls) {
      final disposer = _client.graph.get(soul, onAck);
      disposer();
    }
  }

  /// @returns path of this node
  List<String> getPath() {
    if (!isNull(_parent)) {
      return [...?_parent?.getPath(), key];
    }

    return [key];
  }

  /// Traverse a location in the graph
  ///
  /// @param key Key to read data from
  /// @param cb
  /// @returns New link context corresponding to given key
  TTLink get(String key, [TTMsgCb? cb]) {
    return TTLink(key: key, client: _client, parent: this);
  }

  /// Move up to the parent context on the client hierarchy.
  ///
  /// Every time a new link is created, a reference to the old context is kept to go back to.
  ///
  /// @param amount The number of times you want to go back up the link stack. {-1} or {Infinity} will take you to the root.
  /// @returns a parent link context
  dynamic back([int amount = 1]) {
    if (amount < 0 || amount == double.maxFinite.toInt()) {
      return _client;
    }
    if (amount == 1) {
      return _parent ?? _client;
    }
    return back(amount - 1);
  }

  /// Save data into the TT graph, syncing it with your connected peers.
  ///
  /// You do not need to re-save the entire object every time, TT will automatically
  /// merge your data into what already exists as a "partial" update.
  ///
  /// @param value the data to save
  /// @param cb an optional callback, invoked on each acknowledgment
  /// @returns same link context
  @Deprecated('Use publish() instead')
  TTLink put(TTValue value, [TTMsgCb? cb]) {
    publish(value, onAck: cb);
    return this;
  }

  /// Add a unique item to an unordered list.
  ///
  /// Works like a mathematical set, where each item in the list is unique.
  /// If the item is added twice, it will be merged.
  /// This means only objects, for now, are supported.
  ///
  /// @param data should be a TT reference or an object
  /// @param cb The callback is invoked exactly the same as .put
  /// @returns link context for added object
  @Deprecated('Use publish() with explicit payload instead')
  TTLink set(dynamic data, [TTMsgCb? cb]) {
    if (data is TTLink && !isNull(data.soul)) {
      final temp = {};
      temp[data.soul] = {'#': data.soul};
      put(temp, cb);
    } else if (data is TTNode) {
      final temp = {};
      temp[data.nodeMetaData?.key] = data;
      put(temp, cb);
    } else {
      throw ('set() is only partially supported');
    }

    return this;
  }

  /// Register a callback for when it appears a record does not exist
  ///
  /// If you need to know whether a property or key exists, you can check with .not.
  /// It will consult the connected peers and invoke the callback if there's reasonable certainty that none of them have the data available.
  ///
  /// @param cb If there's reason to believe the data doesn't exist, the callback will be invoked. This can be used as a check to prevent implicitly writing data
  /// @returns same link context
  @Deprecated('Use snapshot() and handle null results instead')
  TTLink not(void Function(String key) cb) {
    promise().then((val) {
      if (isNull(val)) {
        cb(key);
      }
    });
    return this;
  }

  /// Change the configuration of this link
  ///
  /// @param options
  /// @returns current options
  TTLinkOptions opt([TTLinkOptions? options]) {
    if (!isNull(options)) {
      _opt = options!;
    }
    if (!isNull(_parent)) {
      return _opt;
    }
    return _opt;
  }

  /// Get the current data without subscribing to updates. Or undefined if it cannot be found.
  ///
  /// @param cb The data is the value for that link at that given point in time. And the key is the last property name or ID of the node.
  /// @returns same link context
  @Deprecated('Use snapshot() instead')
  TTLink once(TTOnCb cb) {
    snapshot().then((val) => cb(val, key));
    return this;
  }

  /// Subscribe to updates and changes on a node or property in realtime.
  ///
  /// Triggered once initially and whenever the property or node you're focused on changes,
  /// Since TT streams data, the callback will probably be called multiple times as new chunks come in.
  ///
  /// To remove a listener call .off() on the same property or node.
  ///
  /// @param cb The callback is immediately fired with the data as it is at that point in time.
  /// @returns same link context
  @Deprecated('Use subscribe() instead')
  TTLink on(TTOnCb cb) {
    subscribe(cb);
    return this;
  }

  /// Unsubscribe one or all listeners subscribed with on
  ///
  /// @returns same link context
  @Deprecated('Use unsubscribe() instead')
  TTLink off([TTOnCb? cb]) {
    unsubscribe(cb);
    return this;
  }

  @Deprecated('Use snapshot() instead')
  Future<TTValue> promise([int timeout = 0]) {
    var completer = Completer<TTValue>();
    snapshot(timeout: timeout).then((val) {
      if (!completer.isCompleted) completer.complete(val);
    });
    return completer.future;
  }

  Future<dynamic> then(dynamic Function(TTValue ttValue) fn) {
    return snapshot().then(fn);
  }

  /// Iterates over each property and item on a node, passing it down the link chain
  ///
  /// Not yet supported
  ///
  /// Behaves like a forEach on your data.
  /// It also subscribes to every item as well and listens for newly inserted items.
  ///
  /// @returns a new link context holding many links simultaneously.
  TTLink map() {
    throw ("map() isn't supported yet");
  }

  /// No plans to support this
  TTLink path(String path) {
    throw ('No plans to support this');
  }

  /// No plans to support this
  TTLink open(dynamic cb) {
    throw ('No plans to support this');
  }

  /// No plans to support this
  TTLink load(dynamic cb) {
    throw ('No plans to support this');
  }

  /// No plans to support this
  TTLink bye() {
    throw ('No plans to support this');
  }

  /// No plans to support this
  TTLink later() {
    throw ('No plans to support this');
  }

  /// No plans to support this
  TTLink unset(TTNode node) {
    throw ('No plans to support this');
  }

  void _onQueryResponse(TTValue? value, [String? _, dynamic __]) {
    _updateEvent.trigger(value, key);
    _lastValue = value;
    _hasReceived = true;
  }
}
