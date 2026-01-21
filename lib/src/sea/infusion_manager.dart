import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:convert/convert.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:infusion_ffi/infusion_ffi.dart';
import 'infusion_types.dart';

class InfusionManager {
  static const _storage = FlutterSecureStorage();
  static const _kEncKey = 'infusion_enc_key';
  static const _kSignSeed = 'infusion_sign_seed';
  static const _kAuthorPub = 'infusion_author_pub';
  static const _kOwnerPub = 'infusion_owner_pub';

  // Holds the active vault context. Null if not initialized.
  static InfusionFFI? _vault;
  static Completer<void>? _initCompleter;
  static InfusionConfig _config = const InfusionConfig();

  static InfusionConfig get config => _config;

  static void configure(InfusionConfig config) {
    _config = config;
  }

  /// Ensures Infusion is initialized with keys from SecureStorage.
  /// Generates new keys if none exist.
  /// If only one key exists, the default policy is to throw unless
  /// [allowPartialRekey] is explicitly set to true.
  static Future<void> initialize({
    bool allowPartialRekey = false,
    InfusionConfig? config,
  }) async {
    if (config != null) {
      _config = config;
    }
    print(
      '🔐 Infusion: initialize() called. Vault exists: ${_vault != null}, Init in progress: ${_initCompleter != null}',
    );
    // If already holding a valid vault handle, do nothing.
    if (_vault != null) return;
    final initCompleter = _initCompleter;
    if (initCompleter != null) {
      print('🔐 Infusion: Waiting for existing init...');
      return initCompleter.future;
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
        await _storage.delete(key: _kAuthorPub);
        await _storage.delete(key: _kOwnerPub);
        if (config == null) {
          _clearIdentity();
        }
        print('🔐 Infusion: No keys found. GENERATING NEW KEYS.');
        final rng = Random.secure();
        final enc = Uint8List(32);
        final sign = Uint8List(32);
        for (int i = 0; i < 32; i++) {
          enc[i] = rng.nextInt(256);
          sign[i] = rng.nextInt(256);
        }

        encHex = hex.encode(enc);
        signHex = hex.encode(sign);

        await _storage.write(key: _kEncKey, value: encHex);
        await _storage.write(key: _kSignSeed, value: signHex);
      } else if (encHex == null || signHex == null) {
        if (!allowPartialRekey) {
          throw StateError(
            'Partial Infusion key material found; refusing to rekey automatically. '
            'Restore from mnemonic or clear stored keys explicitly.',
          );
        }
        await _storage.delete(key: _kEncKey);
        await _storage.delete(key: _kSignSeed);
        await _storage.delete(key: _kAuthorPub);
        await _storage.delete(key: _kOwnerPub);
        if (config == null) {
          _clearIdentity();
        }
        final rng = Random.secure();
        final enc = Uint8List(32);
        final sign = Uint8List(32);
        for (int i = 0; i < 32; i++) {
          enc[i] = rng.nextInt(256);
          sign[i] = rng.nextInt(256);
        }
        encHex = hex.encode(enc);
        signHex = hex.encode(sign);
        await _storage.write(key: _kEncKey, value: encHex);
        await _storage.write(key: _kSignSeed, value: signHex);
      }

      final storedAuthor = await _storage.read(key: _kAuthorPub);
      final storedOwner = await _storage.read(key: _kOwnerPub);
      _mergeIdentity(
        authorHex: storedAuthor,
        ownerHex: storedOwner,
        requesterHex: storedOwner,
      );

      print('🔐 Infusion: Creating vault (FFI)...');
      // Create new vault (FFI alloc)
      _vault = await InfusionFFI.create(
        encKeyHex: encHex,
        signSeedHex: signHex,
        authorPubHex: _config.authorPubHex,
        ownerPubHex: _config.ownerPubHex,
        requesterPubHex: _config.requesterPubHex,
        alg: _config.alg,
      );
      print('🔐 Infusion: Vault created successfully.');
      completer.complete();
    } catch (e, st) {
      final mapped = _mapMissingNativeError(e);
      if (!completer.isCompleted) {
        completer.completeError(mapped ?? e, st);
      }
      if (mapped != null) {
        Error.throwWithStackTrace(mapped, st);
      }
      rethrow;
    } finally {
      if (identical(_initCompleter, completer)) {
        _initCompleter = null;
      }
    }
  }

  /// Manually disposes the current vault. Used during logout or re-keying.
  static Future<void> dispose() async {
    final vault = _vault;
    if (vault != null) {
      await vault.dispose();
      _vault = null;
    }
  }

  /// Accessor for the underlying FFI wrapper. Initializes if needed.
  static Future<InfusionFFI> get vault async {
    if (_vault == null) await initialize();
    return _vault!;
  }

  /// Derives the key for Hive storage from the Infusion master key.
  static Future<Uint8List> getHiveKey() async {
    final v = await vault;
    // Context info "hive_storage" as bytes
    final context = Uint8List.fromList(utf8.encode("hive_storage"));
    return v.deriveKey(context);
  }

  /// Generates a deterministic blind index for the given input.
  /// Used for searching encrypted data without revealing the content.
  static Future<String> getBlindIndex(String input) async {
    final v = await vault;
    return hex.encode(await v.blindIndex(input));
  }

  /// Exports the private credentials (Master Keys) of the Vault.
  /// WARNING: These keys grant full control over the vault and data.
  static Future<Map<String, String>> exportCredentials() async {
    if (_vault == null) await initialize();

    final enc = await _storage.read(key: _kEncKey);
    final sign = await _storage.read(key: _kSignSeed);

    if (enc == null || sign == null) throw Exception("Vault not initialized");

    return {'enc_key_hex': enc, 'sign_seed_hex': sign};
  }

  /// Generates a new 12-word BIP-39 mnemonic.
  static Future<String> generateMnemonic() async {
    return await InfusionFFI.mnemonicGenerate(wordCount: 12);
  }

  /// Restores the Vault keys from a BIP-39 mnemonic phrase.
  /// Overwrites current keys in SecureStorage and re-initializes Infusion.
  static Future<void> restoreFromMnemonic(String phrase) async {
    // 1. Restore keys from phrase via FFI (Stateless)
    // Returns JSON config: {"enc_key_hex": "...", "sign_seed_hex": "..."}
    final jsonConfigStr = await InfusionFFI.mnemonicRestore(phrase);

    // 2. Parse JSON
    final Map<String, dynamic> config = jsonDecode(jsonConfigStr);

    // 3. Extract Keys
    final String? enc = config['enc_key_hex'];
    final String? sign = config['sign_seed_hex'];
    final String? author = config['author_pub_hex'];
    final String? owner = config['owner_pub_hex'];

    if (enc == null || sign == null) {
      throw Exception("Failed to restore keys: invalid config returned");
    }

    // 4. Save to Storage (Overwrite existing)
    await _storage.write(key: _kEncKey, value: enc);
    await _storage.write(key: _kSignSeed, value: sign);
    if (author != null && author.isNotEmpty) {
      await _storage.write(key: _kAuthorPub, value: author);
    }
    if (owner != null && owner.isNotEmpty) {
      await _storage.write(key: _kOwnerPub, value: owner);
    }

    _mergeIdentity(authorHex: author, ownerHex: owner, requesterHex: owner);

    // 5. Re-initialize memory (Dispose old vault, create new one)
    await dispose();
    await initialize();
  }

  /// Encrypts data using the vault's key and a policy ID.
  static Future<Uint8List> seal({
    required Uint8List data,
    int policyId = 0,
    Uint8List? aad,
  }) async {
    final v = await vault;
    final result = await v.seal(data: data, policyId: policyId, aad: aad);
    print(
      '🔐 Infusion: Seal policy $policyId. Data length: ${data.length}, Result length: ${result.length}',
    );
    return result;
  }

  /// Decrypts data sealed by this vault.
  static Future<Uint8List> open(
    Uint8List sealedData, {
    Uint8List? capToken,
  }) async {
    final v = await vault;
    try {
      final decrypted = await v.open(sealedData, capToken: capToken);
      print(
        '🔐 Infusion: Open success. Sealed length: ${sealedData.length}, Decrypted length: ${decrypted.length}',
      );
      return decrypted;
    } catch (e) {
      print(
        '🔐 Infusion: Open FAILED. Sealed length: ${sealedData.length}. Error: $e',
      );
      rethrow;
    }
  }

  /// Derives a key for a specific context.
  /// This is the generic version of [getHiveKey].
  static Future<Uint8List> deriveKey(Uint8List context) async {
    final v = await vault;
    return v.deriveKey(context);
  }

  /// Issues a capability (delegation) for a resource.
  /// [delegatedPub32]: The public key of the delegate (32 bytes).
  /// [expTs]: Expiration timestamp (seconds since epoch).
  /// [rights]: Bitmask of rights.
  /// [scopeCid]: Content ID of the resource scope (32 bytes).
  static Future<Uint8List> issueCap({
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

  /// Verifies a capability token for a specific requester.
  ///
  /// This uses the Infusion FFI helper that understands capability tokens,
  /// avoiding frame deserialization errors for non-frame inputs.
  static Future<bool> verify({
    required Uint8List capToken,
    required Uint8List requesterPub32,
  }) async {
    final v = await vault;
    return v.verifyCap(capToken: capToken, requesterPub32: requesterPub32);
  }

  static Future<bool> verifyCapToken({
    required Uint8List capToken,
    required Uint8List requesterPub32,
  }) {
    return verify(capToken: capToken, requesterPub32: requesterPub32);
  }

  static Future<VerifyResult> verifyFrame(Uint8List frame) async {
    final v = await vault;
    return v.verifyDetailed(frame);
  }

  static Future<Map<String, String?>> exportIdentity() async {
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

  static InfusionPolicy policyFor(int policyId) {
    return _config.policyCatalog.resolve(policyId);
  }

  static int resolvePolicyId({
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

  static InfusionAad buildAad({
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

  static Future<Uint8List?> resolveCapToken(InfusionCapContext context) async {
    final provider = _config.capTokenProvider;
    if (provider == null) return null;
    return provider(context);
  }

  static Future<Uint8List?> resolveRequesterPub(
    InfusionCapContext context,
  ) async {
    final provider = _config.requesterProvider;
    if (provider != null) {
      return provider(context);
    }
    return _hexToBytes(_config.requesterPubHex);
  }

  static Uint8List? _hexToBytes(String? value) {
    if (value == null || value.isEmpty) return null;
    try {
      return Uint8List.fromList(hex.decode(value));
    } catch (_) {
      return null;
    }
  }

  static StateError? _mapMissingNativeError(Object error) {
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

  static void _mergeIdentity({
    String? authorHex,
    String? ownerHex,
    String? requesterHex,
  }) {
    if (authorHex == null && ownerHex == null && requesterHex == null) {
      return;
    }
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

  static void _clearIdentity() {
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
