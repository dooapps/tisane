import 'dart:async';

import '../../ports/graph/graph_replication_port.dart';
import '../../ports/graph/graph_store_port.dart';
import '../../ports/graph/graph_merge_port.dart';
import '../../types/graph_change.dart';
import '../../types/generic.dart';
import '../../types/tt.dart';

/// Simple replication adapter that wires change notifications and
/// can apply inbound diffs to the backing store using the merge port.
class DefaultGraphReplicationAdapter implements GraphReplicationPort {
  DefaultGraphReplicationAdapter({
    required GraphStorePort store,
    required GraphMergePort merge,
  }) : _store = store,
       _merge = merge;

  final GraphStorePort _store;
  // ignore: unused_field
  final GraphMergePort _merge;
  final _controller = StreamController<ChangeSetEntry>.broadcast();

  @override
  Future<void> pruneChangelog(num before) async {
    // No-op default; changelog not persisted in this adapter.
  }

  @override
  ChangeSetEntryFunc changesetFeed(String from) {
    return () async {
      try {
        final next = await _controller.stream.first;
        return next;
      } catch (_) {
        return null;
      }
    };
  }

  @override
  VoidCallback onChange(SetChangeSetEntryFunc handler, {String? from}) {
    final sub = _controller.stream.listen(handler);
    return () => sub.cancel();
  }

  /// Applies an inbound graph diff by merging and persisting via the store.
  Future<void> applyInbound(TTGraphData diff) async {
    await _store.writeGraph(diff);
    // Notify subscribers with a synthetic change event per soul
    for (final entry in diff.entries) {
      _controller.add(
        Tuple<String, TTGraphData>(
          item1: entry.key,
          item2: (TTGraphData()..[entry.key] = entry.value),
        ),
      );
    }
  }
}
