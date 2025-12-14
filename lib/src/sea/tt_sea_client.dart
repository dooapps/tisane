import '../client/tt_client.dart';
import '../client/interfaces.dart';
import '../sear/unpack.dart';
import '../storage/store.dart';
import '../types/tt.dart';
import 'tt_sea_user_api.dart';

/// SEA-aware TT client that wires signature and storage middleware on demand.
class TTSeaClient extends TTClient {
  TTUserApi? _user;

  TTSeaClient({
    super.linkClass,
    TTOptions? options,
    bool registerStorage = false,
  }) : super(
         options:
             options ??
             (TTOptions()..peers = ["wss://gun-manhattan.herokuapp.com/gun"]),
       ) {
    if (registerStorage) {
      registerStorageMiddleware();
    } else {
      registerSearMiddleware();
    }
  }

  TTUserApi user() {
    return (_user ??= TTUserApi(ttSeaClient: this));
  }

  void registerSearMiddleware() {
    graph.use(
      (TTGraphData updates, TTGraphData existingGraph) =>
          unpackGraph(updates, graph.getOpt().mutable!),
    );
  }

  void registerStorageMiddleware() {
    // For the Read Use Case
    graph.use(
      (TTGraphData updates, TTGraphData existingGraph) => getStoreData(
        unpackGraph(updates, graph.getOpt().mutable!),
        graph.activeConnectors,
      ),
    );

    // For the Write Use Case
    graph.use(
      (TTGraphData updates, TTGraphData existingGraph) => setStoreData(updates),
      kind: TTMiddlewareType.write,
    );
  }
}
