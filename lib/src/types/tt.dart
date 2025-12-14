import 'generic.dart';

/// Timestamp of last change for each attribute
class TTNodeState extends GenericCustomValueMap<String, num> {}

/// Soul and state metadata for a TT node
class TTNodeMeta {
  String? key; // #
  TTNodeState? forward; // >

  TTNodeMeta({this.key, this.forward});

  Map<String, dynamic> toJson() => <String, dynamic>{
    '#': key,
    '>': forward?.toMap(),
  };

  factory TTNodeMeta.fromJson(Map<String, dynamic> parsedJson) {
    TTNodeState nodeState = TTNodeState();
    if (parsedJson.containsKey('>')) {
      nodeState.merge(parsedJson['>']);
    }
    return TTNodeMeta(key: parsedJson['#'].toString(), forward: nodeState);
  }
}

/// A node (or partial node data) in a TT graph
class TTNode extends GenericCustomValueMap<String, dynamic> {
  late TTNodeMeta? nodeMetaData; // _

  TTNode({this.nodeMetaData});

  Map<String, dynamic> toJson() => <String, dynamic>{
    '_': nodeMetaData?.toJson(),
    ...toMap(),
  };

  factory TTNode.fromJson(Map<String, dynamic> parsedJson) {
    TTNodeMeta nodeMeta = TTNodeMeta();
    if (parsedJson.containsKey('_')) {
      nodeMeta = TTNodeMeta.fromJson(parsedJson['_']);
      parsedJson.remove('_');
    }
    TTNode node = TTNode(nodeMetaData: nodeMeta);
    node.merge(parsedJson);
    return node;
  }
}

/// TT graph data consists of one or more full or partial nodes
class TTGraphData extends GenericCustomValueMap<String, TTNode?> {
  TTGraphData();

  factory TTGraphData.fromJson(Map<String, dynamic> parsedJson) {
    TTGraphData graphData = TTGraphData();
    graphData.addAll(
      parsedJson.map<String, TTNode?>(
        (key, value) => MapEntry(key, TTNode.fromJson(value)),
      ),
    );
    return graphData;
  }
}

class TTMsgGet {
  String? key; // #

  TTMsgGet({this.key});

  Map<String, dynamic> toJson() => <String, dynamic>{'#': key};

  factory TTMsgGet.fromJson(Map<String, dynamic> parsedJson) {
    return TTMsgGet(key: parsedJson['#'].toString());
  }
}

/// A standard TT protocol message
class TTMsg {
  String? key; // #
  String? pos; // @
  bool? ack;
  dynamic err;
  dynamic ok;
  TTGraphData? put;
  TTMsgGet? get;

  TTMsg({this.key, this.pos, this.put, this.get, this.ack, this.err, this.ok});

  Map<String, dynamic> toJson() {
    final data = <String, dynamic>{
      '#': key,
      '@': pos,
      'ack': ack,
      'err': err,
      'ok': ok,
      'get': get?.toJson(),
      'put': put?.toMap().map<String, dynamic>(
        (key, value) => MapEntry(key, value?.toJson()),
      ),
    };
    data.removeWhere((key, value) => value == null);
    return data;
  }

  factory TTMsg.fromJson(Map<String, dynamic> parsedJson) => TTMsg(
    key: parsedJson['#']?.toString(),
    pos: parsedJson['@']?.toString(),
    ack: parsedJson['ack']?.toString() == 'true',
    ok: parsedJson['ok'],
    err: parsedJson['err']?.toString(),
    get: parsedJson.containsKey('get')
        ? TTMsgGet.fromJson(parsedJson['get'])
        : null,
    put: parsedJson.containsKey('put')
        ? TTGraphData.fromJson(parsedJson['put'])
        : null,
  );
}

typedef TTValue = dynamic;
