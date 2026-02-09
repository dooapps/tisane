import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:convert/convert.dart';
import 'package:infusion_ffi/infusion_ffi.dart';
import 'infusion_types.dart';
import '../ports/infusion_storage_port.dart';
import '../adapters/infusion_storage_adapter.dart';

/// The core security manager for Tisane, handling Vault lifecycle and cryptographic operations.
///
/// This class uses a Singleton pattern accessed via `Infusion.instance`.
/// For backward compatibility, static methods on `InfusionManager` proxy to the singleton instance.
class Infusion {
  static final Infusion _instance = Infusion._internal();
  static Infusion get instance => _instance;

  Infusion._internal();

  static const _kEncKey = 'infusion_enc_key';
  static const _kSignSeed = 'infusion_sign_seed';
  static const _kAuthorPub = 'infusion_author_pub';
  static const _kOwnerPub = 'infusion_owner_pub';

  InfusionStoragePort _storage = const SecureStorageAdapter();
  InfusionFFI? _vault;
  Completer<void>? _initCompleter;
  InfusionConfig _config = const InfusionConfig();

  InfusionConfig get config => _config;

  /// Configures the global Infusion instance.
  ///
  /// You can optionally provide a custom [storage] adapter (e.g., for testing).
  void configure(InfusionConfig config, {InfusionStoragePort? storage}) {
    _config = config;
    if (storage != null) {
      _storage = storage;
    }
  }

  /// ACCESSOR for the underlying storage. Used primarily for testing.
  InfusionStoragePort get storage => _storage;

  /// ACCESSOR for the underlying Vault. Initializes if needed.
  Future<InfusionFFI> get vault async {
    if (_vault == null) await initialize();
    return _vault!;
  }

  /// Ensures Infusion is initialized with keys from Storage.
  /// Generates new keys if none exist.
  Future<void> initialize({
    bool allowPartialRekey = false,
    InfusionConfig? config,
    InfusionStoragePort? storage,
  }) async {
    if (config != null) _config = config;
    if (storage != null) _storage = storage;

    print(
      '🔐 Infusion: initialize() called. Vault exists: ${_vault != null}, Init in progress: ${_initCompleter != null}',
    );

    if (_vault != null) return;
    if (_initCompleter != null) {
      print('🔐 Infusion: Waiting for existing init...');
      return _initCompleter!.future;
    }

    final completer = Completer<void>();
    _initCompleter = completer;

    try {
      String? encHex = await _storage.read(key: _kEncKey);
      String? signHex = await _storage.read(key: _kSignSeed);

      print(
        '🔐 Infusion: Initializing. Stored EncKey: ${encHex != null}, Stored SignSeed: ${signHex != null}',
      );

      if (encHex == null && signHex == null) {
        await _resetKeys();
        encHex = await _storage.read(key: _kEncKey);
        signHex = await _storage.read(key: _kSignSeed);
      } else if (encHex == null || signHex == null) {
        if (!allowPartialRekey) {
          throw StateError(
            'Partial Infusion key material found; refusing to rekey automatically. '
            'Restore from mnemonic or clear stored keys explicitly.',
          );
        }
        await _resetKeys();
        encHex = await _storage.read(key: _kEncKey);
        signHex = await _storage.read(key: _kSignSeed);
      }

      // Load identity
      final storedAuthor = await _storage.read(key: _kAuthorPub);
      final storedOwner = await _storage.read(key: _kOwnerPub);
      _mergeIdentity(
        authorHex: storedAuthor,
        ownerHex: storedOwner,
        requesterHex: storedOwner,
      );

      print('🔐 Infusion: Creating vault (FFI)...');
      _vault = await InfusionFFI.create(
        encKeyHex: encHex!,
        signSeedHex: signHex!,
        authorPubHex: _config.authorPubHex,
        ownerPubHex: _config.ownerPubHex,
        requesterPubHex: _config.requesterPubHex,
        alg: _config.alg,
      );
      print('🔐 Infusion: Vault created successfully.');
      completer.complete();
    } catch (e, st) {
      final mapped = _mapMissingNativeError(e);
      if (!completer.isCompleted) completer.completeError(mapped ?? e, st);
      if (mapped != null) Error.throwWithStackTrace(mapped, st);
      rethrow;
    } finally {
      if (identical(_initCompleter, completer)) {
        _initCompleter = null;
      }
    }
  }

  Future<void> _resetKeys() async {
    await _storage.delete(key: _kAuthorPub);
    await _storage.delete(key: _kOwnerPub);
    await _storage.delete(key: _kEncKey);
    await _storage.delete(key: _kSignSeed);

    if (_config.authorPubHex == null) {
      _clearIdentityCopy();
    }

    print('🔐 Infusion: GENERATING NEW KEYS.');
    final rng = Random.secure();
    final enc = Uint8List(32);
    final sign = Uint8List(32);
    for (int i = 0; i < 32; i++) {
      enc[i] = rng.nextInt(256);
      sign[i] = rng.nextInt(256);
    }

    await _storage.write(key: _kEncKey, value: hex.encode(enc));
    await _storage.write(key: _kSignSeed, value: hex.encode(sign));
  }

  Future<void> dispose() async {
    final vault = _vault;
    if (vault != null) {
      await vault.dispose();
      _vault = null;
    }
  }

  Future<Uint8List> getHiveKey() async {
    final v = await vault;
    final context = Uint8List.fromList(utf8.encode("hive_storage"));
    return v.deriveKey(context);
  }

  Future<String> getBlindIndex(String input) async {
    final v = await vault;
    return hex.encode(await v.blindIndex(input));
  }

  Future<Map<String, String>> exportCredentials() async {
    if (_vault == null) await initialize();
    final enc = await _storage.read(key: _kEncKey);
    final sign = await _storage.read(key: _kSignSeed);
    if (enc == null || sign == null) throw Exception("Vault not initialized");
    return {'enc_key_hex': enc, 'sign_seed_hex': sign};
  }

  Future<String> generateMnemonic() async {
    return await InfusionFFI.mnemonicGenerate(wordCount: 12);
  }

  Future<void> restoreFromMnemonic(String phrase) async {
    final jsonConfigStr = await InfusionFFI.mnemonicRestore(phrase);
    final Map<String, dynamic> config = jsonDecode(jsonConfigStr);

    final String? enc = config['enc_key_hex'];
    final String? sign = config['sign_seed_hex'];
    final String? author = config['author_pub_hex'];
    final String? owner = config['owner_pub_hex'];

    if (enc == null || sign == null) {
      throw Exception("Failed to restore keys: invalid config returned");
    }

    await _storage.write(key: _kEncKey, value: enc);
    await _storage.write(key: _kSignSeed, value: sign);
    if (author != null && author.isNotEmpty) {
      await _storage.write(key: _kAuthorPub, value: author);
    }
    if (owner != null && owner.isNotEmpty) {
      await _storage.write(key: _kOwnerPub, value: owner);
    }

    _mergeIdentity(authorHex: author, ownerHex: owner, requesterHex: owner);
    await dispose();
    await initialize();
  }

  Future<Uint8List> seal({
    required Uint8List data,
    int policyId = 0,
    Uint8List? aad,
  }) async {
    final v = await vault;
    final result = await v.seal(data: data, policyId: policyId, aad: aad);
    print(
        '🔐 Infusion: Seal policy $policyId. Data length: ${data.length}, Result length: ${result.length}');
    return result;
  }

  Future<Uint8List> open(
    Uint8List sealedData, {
    Uint8List? capToken,
  }) async {
    final v = await vault;
    try {
      final decrypted = await v.open(sealedData, capToken: capToken);
      print(
          '🔐 Infusion: Open success. Sealed length: ${sealedData.length}, Decrypted length: ${decrypted.length}');
      return decrypted;
    } catch (e) {
      print(
          '🔐 Infusion: Open FAILED. Sealed length: ${sealedData.length}. Error: $e');
      rethrow;
    }
  }

  Future<Uint8List> deriveKey(Uint8List context) async {
    final v = await vault;
    return v.deriveKey(context);
  }

  Future<Uint8List> issueCap({
    required Uint8List delegatedPub32,
    required int expTs,
    required int rights,
    required Uint8List scopeCid,
  }) async {
    final v = await vault;
    return v.issueCap(
      delegatedPub32: delegatedPub32,
      expTs: expTs,
      rights: rights,
      scopeCid: scopeCid,
    );
  }

  Future<bool> verify({
    required Uint8List capToken,
    required Uint8List requesterPub32,
  }) async {
    final v = await vault;
    return v.verifyCap(capToken: capToken, requesterPub32: requesterPub32);
  }
    
  Future<VerifyResult> verifyDetailed(Uint8List frame) async {
     final v = await vault;
     return v.verifyDetailed(frame);
  }

  Future<Map<String, String?>> exportIdentity() async {
    final storedAuthor = await _storage.read(key: _kAuthorPub);
    final storedOwner = await _storage.read(key: _kOwnerPub);
    final author = _config.authorPubHex ?? storedAuthor ?? storedOwner;
    final owner = _config.ownerPubHex ?? storedOwner ?? storedAuthor;
    final requester =
        _config.requesterPubHex ?? storedOwner ?? storedAuthor ?? owner;
    return {
      'author_pub_hex': author,
      'owner_pub_hex': owner,
      'requester_pub_hex': requester,
    };
  }

  InfusionPolicy policyFor(int policyId) {
    return _config.policyCatalog.resolve(policyId);
  }

  int resolvePolicyId({
    required String soul,
    required String field,
    Object? value,
    Map<String, dynamic>? nodeMeta,
  }) {
    final resolver = _config.policyResolver;
    if (resolver != null) {
      return resolver(
        InfusionPolicyContext(
          soul: soul,
          field: field,
          value: value,
          nodeMeta: nodeMeta,
        ),
      );
    }
    return _config.defaultPolicyId;
  }

  InfusionAad buildAad({
    required String soul,
    required String field,
    required int policyId,
  }) {
    return _config.aadBuilder(
      InfusionAadContext(
        soul: soul,
        field: field,
        policyId: policyId,
        schemaVersion: _config.aadSchemaVersion,
      ),
    );
  }

  Future<Uint8List?> resolveCapToken(InfusionCapContext context) async {
    final provider = _config.capTokenProvider;
    if (provider == null) return null;
    return provider(context);
  }

  Future<Uint8List?> resolveRequesterPub(InfusionCapContext context) async {
    final provider = _config.requesterProvider;
    if (provider != null) return provider(context);
    return _hexToBytes(_config.requesterPubHex);
  }

  Uint8List? _hexToBytes(String? value) {
    if (value == null || value.isEmpty) return null;
    try {
      return Uint8List.fromList(hex.decode(value));
    } catch (_) {
      return null;
    }
  }

  StateError? _mapMissingNativeError(Object error) {
    final message = error.toString();
    final lowered = message.toLowerCase();
    if (lowered.contains('libinfusion_ffi') ||
        (lowered.contains('infusion_ffi') &&
            lowered.contains('could not find'))) {
      return StateError(
        'Infusion native library unavailable. '
        'Ensure libinfusion_ffi is bundled or set INFUSION_LIB_PATH. '
        'Original error: $message',
      );
    }
    return null;
  }

  void _mergeIdentity({
    String? authorHex,
    String? ownerHex,
    String? requesterHex,
  }) {
    if (authorHex == null && ownerHex == null && requesterHex == null) return;
    final resolvedAuthor = _config.authorPubHex ?? authorHex ?? ownerHex;
    final resolvedOwner = _config.ownerPubHex ?? ownerHex ?? authorHex;
    final resolvedRequester =
        _config.requesterPubHex ?? requesterHex ?? resolvedOwner;
    _config = InfusionConfig(
      alg: _config.alg,
      authorPubHex: resolvedAuthor,
      ownerPubHex: resolvedOwner,
      requesterPubHex: resolvedRequester,
      defaultPolicyId: _config.defaultPolicyId,
      aadSchemaVersion: _config.aadSchemaVersion,
      policyCatalog: _config.policyCatalog,
      policyResolver: _config.policyResolver,
      aadBuilder: _config.aadBuilder,
      capTokenProvider: _config.capTokenProvider,
      requesterProvider: _config.requesterProvider,
      embedCapToken: _config.embedCapToken,
      verifyFrameBeforeOpen: _config.verifyFrameBeforeOpen,
      enforceAadContext: _config.enforceAadContext,
    );
  }

  void _clearIdentityCopy() {
    _config = InfusionConfig(
      alg: _config.alg,
      authorPubHex: null,
      ownerPubHex: null,
      requesterPubHex: null,
      defaultPolicyId: _config.defaultPolicyId,
      aadSchemaVersion: _config.aadSchemaVersion,
      policyCatalog: _config.policyCatalog,
      policyResolver: _config.policyResolver,
      aadBuilder: _config.aadBuilder,
      capTokenProvider: _config.capTokenProvider,
      requesterProvider: _config.requesterProvider,
      embedCapToken: _config.embedCapToken,
      verifyFrameBeforeOpen: _config.verifyFrameBeforeOpen,
      enforceAadContext: _config.enforceAadContext,
    );
  }
}

/// Static Proxy Class for backward compatibility.
class InfusionManager {
  static InfusionConfig get config => Infusion.instance.config;

  static void configure(InfusionConfig config) =>
      Infusion.instance.configure(config);

  static Future<void> initialize({
    bool allowPartialRekey = false,
    InfusionConfig? config,
    InfusionStoragePort? storage,
  }) => Infusion.instance.initialize(
        allowPartialRekey: allowPartialRekey,
        config: config,
        storage: storage,
      );

  static Future<void> dispose() => Infusion.instance.dispose();

  static Future<InfusionFFI> get vault => Infusion.instance.vault;

  static Future<Uint8List> getHiveKey() => Infusion.instance.getHiveKey();

  static Future<String> getBlindIndex(String input) =>
      Infusion.instance.getBlindIndex(input);

  static Future<Map<String, String>> exportCredentials() =>
      Infusion.instance.exportCredentials();

  static Future<String> generateMnemonic() =>
      Infusion.instance.generateMnemonic();

  static Future<void> restoreFromMnemonic(String phrase) =>
      Infusion.instance.restoreFromMnemonic(phrase);

  static Future<Uint8List> seal({
    required Uint8List data,
    int policyId = 0,
    Uint8List? aad,
  }) => Infusion.instance.seal(data: data, policyId: policyId, aad: aad);

  static Future<Uint8List> open(
    Uint8List sealedData, {
    Uint8List? capToken,
  }) => Infusion.instance.open(sealedData, capToken: capToken);

  static Future<Uint8List> deriveKey(Uint8List context) =>
      Infusion.instance.deriveKey(context);

  static Future<Uint8List> issueCap({
    required Uint8List delegatedPub32,
    required int expTs,
    required int rights,
    required Uint8List scopeCid,
  }) => Infusion.instance.issueCap(
        delegatedPub32: delegatedPub32,
        expTs: expTs,
        rights: rights,
        scopeCid: scopeCid,
      );

  static Future<bool> verify({
    required Uint8List capToken,
    required Uint8List requesterPub32,
  }) => Infusion.instance.verify(
        capToken: capToken,
        requesterPub32: requesterPub32,
      );

  static Future<bool> verifyCapToken({
    required Uint8List capToken,
    required Uint8List requesterPub32,
  }) => Infusion.instance.verify(
        capToken: capToken,
        requesterPub32: requesterPub32,
      );

  static Future<VerifyResult> verifyFrame(Uint8List frame) =>
      Infusion.instance.verifyDetailed(frame);

  static Future<Map<String, String?>> exportIdentity() =>
      Infusion.instance.exportIdentity();

  static InfusionPolicy policyFor(int policyId) =>
      Infusion.instance.policyFor(policyId);

  static int resolvePolicyId({
    required String soul,
    required String field,
    Object? value,
    Map<String, dynamic>? nodeMeta,
  }) => Infusion.instance.resolvePolicyId(
        soul: soul,
        field: field,
        value: value,
        nodeMeta: nodeMeta,
      );

  static InfusionAad buildAad({
    required String soul,
    required String field,
    required int policyId,
  }) => Infusion.instance.buildAad(
        soul: soul,
        field: field,
        policyId: policyId,
      );

  static Future<Uint8List?> resolveCapToken(InfusionCapContext context) =>
      Infusion.instance.resolveCapToken(context);

  static Future<Uint8List?> resolveRequesterPub(InfusionCapContext context) =>
      Infusion.instance.resolveRequesterPub(context);
}
