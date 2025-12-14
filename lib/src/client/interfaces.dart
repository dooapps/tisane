import 'dart:async';

import '../types/tt.dart';
import 'flow/tt_event.dart';

typedef FutureOrStringFunc = FutureOr<String> Function(List<String> path);

/// Per-link configuration hooks.
class TTLinkOptions {
  FutureOrStringFunc? uuid;
}

typedef TTOnCb = EventCb<dynamic, String?, dynamic>;
typedef TTNodeListenCb = EventCb<TTNode?, dynamic, dynamic>;

class PathData {
  final List<String> souls;
  final TTValue value;
  final bool complete;

  PathData({required this.souls, this.value, this.complete = false});
}

typedef TTMiddleware = FutureOr<TTGraphData?> Function(
    TTGraphData updates, TTGraphData existingGraph);

enum TTMiddlewareType { read, write }
