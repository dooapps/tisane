// ignore_for_file: constant_identifier_names, non_constant_identifier_names
import 'dart:developer' as developer;

import '../../tt.dart';

const Map<String, dynamic> DEFAULT_OPTS = {};

Future<AuthenticateReturnDataType?> authenticateAccount(
  dynamic ident,
  String password, [
  String encoding = 'base64',
]) async {
  if (ident == null || (ident is Map && !ident.containsKey('auth'))) {
    return null;
  }

  dynamic decrypted;

  try {
    final proof = await work(
      password,
      ident['auth']['s'],
      DefaultWorkFn.from(encode: encoding),
    );
    decrypted = await decrypt(
      ident['auth']['ek'],
      PairReturnType.from(epriv: proof, epub: "", priv: "", pub: ""),
      DefaultAESDecryptKey.from(encode: encoding),
    );
  } catch (e) {
    final proof = await work(
      password,
      ident['auth']['s'],
      DefaultWorkFn.from(encode: encoding),
    );
    decrypted = await decrypt(
      ident['auth']['ek'],
      PairReturnType.from(epriv: proof, epub: "", priv: "", pub: ""),
      DefaultAESDecryptKey.from(encode: encoding),
    );
  }

  if (decrypted == null) {
    return null;
  }

  return AuthenticateReturnDataType.from(
    alias: ident['alias'],
    epriv: decrypted['epriv'],
    epub: ident['epub'],
    priv: decrypted['priv'],
    pub: ident['pub'],
  );
}

Future<AuthenticateReturnDataType?> authenticateIdentity(
  TTSeaClient ttClient,
  String soul,
  String password, [
  String encoding = 'base64',
]) async {
  final ident = await ttClient.getValue(soul);
  return authenticateAccount(ident, password, encoding);
}

Future<AuthenticateReturnDataType> authenticate(
  TTSeaClient ttClient,
  String alias,
  String password, [
  Map<String, dynamic> opt = DEFAULT_OPTS,
]) async {
  final aliasSoul = "~@$alias";
  final idents = await ttClient.getValue(aliasSoul);

  for (var soul in (idents is Map ? idents : {}).keys) {
    if (soul == '_') {
      continue;
    }

    AuthenticateReturnDataType? pair;

    try {
      pair = await authenticateIdentity(ttClient, soul, password);
    } catch (e, st) {
      _debugLog('Error during authenticate: $e');
      _debugLog('$st');
    }

    if (pair != null) {
      return pair;
    }
  }

  throw ('Wrong alias or password.');
}

void _debugLog(String message) {
  assert(() {
    developer.log(message, name: 'tisane.sear.authenticate', level: 900);
    return true;
  }());
}
