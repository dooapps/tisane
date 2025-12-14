import 'dart:convert';

import 'package:hive_flutter/adapters.dart';

import '../../ports/graph/graph_read_options.dart';
import '../../ports/graph/graph_store_port.dart';
import '../../storage/init.dart';
import '../../storage/store.dart' as store;
import '../../types/tt.dart';

/// Hive-backed GraphStorePort adapter.
///
/// Respects existing on-disk schema and box naming via InitStorage.
class HiveGraphStoreAdapter implements GraphStorePort {
  const HiveGraphStoreAdapter();

  Box<dynamic>? get _box => InitStorage.hiveOpenBox;

  @override
  Future<TTNode?> fetchNode(String soul, {GraphReadOptions? options}) async {
    if (_box == null || !_box!.isOpen || !_box!.containsKey(soul)) {
      return null;
    }
    return TTNode.fromJson(jsonDecode(_box!.get(soul)) as Map<String, dynamic>);
  }

  @override
  Future<String?> fetchNodeJson(
    String soul, {
    GraphReadOptions? options,
  }) async {
    if (_box == null || !_box!.isOpen || !_box!.containsKey(soul)) {
      return null;
    }
    return _box!.get(soul) as String?;
  }

  @override
  TTNode? fetchNodeSync(String soul, {GraphReadOptions? options}) {
    if (_box == null || !_box!.isOpen || !_box!.containsKey(soul)) {
      return null;
    }
    return TTNode.fromJson(jsonDecode(_box!.get(soul)) as Map<String, dynamic>);
  }

  @override
  String? fetchNodeJsonSync(String soul, {GraphReadOptions? options}) {
    if (_box == null || !_box!.isOpen || !_box!.containsKey(soul)) {
      return null;
    }
    return _box!.get(soul) as String?;
  }

  @override
  Future<TTGraphData?> writeGraph(TTGraphData graphData) async {
    // Delegate to existing storage util which merges and persists
    return store.setStoreData(graphData);
  }

  @override
  TTGraphData? writeGraphSync(TTGraphData graphData) {
    // No direct sync path; rely on async writeGraph semantics
    return store.setStoreData(graphData);
  }

  @override
  void close() {
    // No-op; lifecycle managed by InitStorage
  }
}
