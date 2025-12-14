import '../../types/graph_change.dart';

abstract class GraphReplicationPort {
  Future<void> pruneChangelog(num before);

  ChangeSetEntryFunc changesetFeed(String from);

  VoidCallback onChange(SetChangeSetEntryFunc handler, {String? from});
}
