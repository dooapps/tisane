// ignore_for_file: constant_identifier_names, non_constant_identifier_names
import 'dart:async';

import '../types/sear/types.dart';

import '../client/interfaces.dart';
import '../sear/authenticate.dart';
import '../sear/create_user.dart';
import '../sear/sign.dart';
import '../types/tt.dart';
import 'tt_sea_client.dart';

class UserReference {
  String alias;
  String pub;

  UserReference.from({required this.alias, required this.pub});

  factory UserReference.fromJson(Map<String, dynamic> parsedJson) {
    return UserReference.from(
      alias: parsedJson['alias'],
      pub: parsedJson['pub'],
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
    'alias': alias,
    'pub': pub,
  };
}

class AckErr {
  String err;

  AckErr.from({required this.err});
}

class UserCredentials {
  String alias;
  String epub;
  String pub;
  String epriv;
  String priv;

  UserCredentials.from({
    required this.alias,
    required this.epub,
    required this.pub,
    required this.epriv,
    required this.priv,
  });

  Map<String, dynamic> toJson() => <String, dynamic>{
    'alias': alias,
    'epub': epub,
    'pub': pub,
    'epriv': epriv,
    'priv': priv,
  };

  factory UserCredentials.fromJson(Map<String, dynamic> parsedJson) {
    return UserCredentials.from(
      alias: parsedJson['alias'],
      epub: parsedJson['epub'],
      pub: parsedJson['pub'],
      epriv: parsedJson['epriv'],
      priv: parsedJson['priv'],
    );
  }
}

typedef LoginCallback = void Function(dynamic userRef);

typedef SignMiddleWareFnType =
    FutureOr<TTGraphData> Function(
      TTGraphData graph,
      TTGraphData graphSnapshot,
    );

const DEFAULT_CREATE_OPTS = {};
const DEFAULT_AUTH_OPTS = {};

/// Thin wrapper around SEA user flows for TTSeaClient consumers.
class TTUserApi {
  late TTSeaClient _client;
  UserReference? isu;
  SignMiddleWareFnType? _signMiddleware;

  TTUserApi({required TTSeaClient ttSeaClient}) {
    _client = ttSeaClient;
  }

  ///
  /// https://gun.eco/docs/User#user-create
  ///
  /// @param alias
  /// @param password
  /// @param cb
  /// @param opt
  Future<UserReference> create(
    String alias,
    String password, [
    LoginCallback? cb,
    opt = DEFAULT_CREATE_OPTS,
  ]) async {
    try {
      final user = await createUser(_client, alias, password);
      final ref = useCredentials(UserCredentials.fromJson(user.toJson()));
      if (cb != null) {
        cb(ref);
      }
      return ref;
    } catch (err) {
      if (cb != null) {
        cb({err});
      }
      throw (err.toString());
    }
  }

  ///
  /// https://gun.eco/docs/User#user-auth
  ///
  /// @param alias
  /// @param password
  /// @param pair
  /// @param cb
  /// @param opt
  Future<UserReference> auth({
    String? alias,
    String? password,
    PairReturnType? pair,
    LoginCallback? cb,
    opt = DEFAULT_AUTH_OPTS,
  }) async {
    if ((alias == null || password == null) && pair == null) {
      throw ("Either Enter Pair or User alias and pass");
    }

    alias ??= pair!.pub;
    password ??= pair!.epriv;

    try {
      final user = await authenticate(_client, alias, password);
      final ref = useCredentials(UserCredentials.fromJson(user.toJson()));
      if (cb != null) {
        cb(ref);
      }
      return ref;
    } catch (err) {
      if (cb != null) {
        cb({err});
      }
      throw (err.toString());
    }
  }

  /// https://gun.eco/docs/User#user-leave
  TTUserApi leave() {
    if (_signMiddleware != null) {
      _client.graph.unuse(_signMiddleware!, kind: TTMiddlewareType.write);
      _signMiddleware = null;
      isu = null;
    }

    return this;
  }

  UserReference useCredentials(UserCredentials credentials) {
    leave();
    _signMiddleware = graphSigner(
      PairReturnType.from(
        pub: credentials.pub,
        priv: credentials.priv,
        epriv: credentials.epriv,
        epub: credentials.epub,
      ),
    );
    _client.graph.use(_signMiddleware!, kind: TTMiddlewareType.write);

    return (isu = UserReference.from(
      alias: credentials.alias,
      pub: credentials.pub,
    ));
  }
}
