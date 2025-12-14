import 'dart:convert';

import '../../tt.dart';
import 'pair.dart' as create_pair;

Future<CreateUserReturnType> createUser(
  TTSeaClient ttClient,
  String alias,
  String password,
) async {
  final aliasSoul = "~@$alias";

  // "pseudo-randomly create a salt, then use PBKDF2 function to extend the password with it."
  final salt = pseudoRandomText(64);

  final proof = await work(
    password,
    PairReturnType.from(epriv: "", epub: salt, priv: "", pub: ""),
  );
  final pair = await create_pair.pair();
  final pubSoul = "~${pair.pub}";

  final ek = await encrypt(
    jsonEncode({'priv': pair.priv, 'epriv': pair.epriv}),
    PairReturnType.from(epriv: proof, epub: "", priv: "", pub: ""),
    DefaultAESEncryptKey.from(raw: true),
  );

  final auth = jsonEncode({'ek': ek, 's': salt});
  final data = {
    'alias': alias,
    'auth': auth,
    'epub': pair.epub,
    'pub': pair.pub,
  };

  final now = DateTime.now().millisecondsSinceEpoch;

  final TTGraphData tempGraph = TTGraphData();
  final Map<String, num> tempForwardGraph = {};

  for (var innerKey in data.keys) {
    tempForwardGraph[innerKey] = now;
  }

  tempGraph[pubSoul] = TTNode.fromJson({
    '_': {'#': pubSoul, '>': tempForwardGraph},
    ...data,
  });

  final graph = await signGraph(tempGraph, pair);

  await () async {
    final tempNodePut = ttClient.get(pubSoul);
    await tempNodePut.publish(graph[pubSoul]);
    final tempPut = ttClient.get(aliasSoul);
    await tempPut.publish({'#': pubSoul});
  }();

  return CreateUserReturnType.fromJson({
    ...data,
    'epriv': pair.epriv,
    'priv': pair.priv,
    'pub': pair.pub,
  });
}
