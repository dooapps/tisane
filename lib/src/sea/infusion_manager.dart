import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:convert/convert.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:infusion_ffi/infusion_ffi.dart';

class InfusionManager {
  static const _storage = FlutterSecureStorage();
  static const _kEncKey = 'infusion_enc_key';
  static const _kSignSeed = 'infusion_sign_seed';

  // Holds the active vault context. Null if not initialized.
  static InfusionFFI? _vault;

  /// Ensures Infusion is initialized with keys from SecureStorage.
  /// Generates new keys if none exist.
  static Future<void> initialize() async {
    // If already holding a valid vault handle, do nothing.
    if (_vault != null) return;

    String? encHex = await _storage.read(key: _kEncKey);
    String? signHex = await _storage.read(key: _kSignSeed);

    if (encHex == null || signHex == null) {
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

    // Create new vault (FFI alloc)
    _vault = await InfusionFFI.create(encKeyHex: encHex, signSeedHex: signHex);
  }

  /// Manually disposes the current vault. Used during logout or re-keying.
  static Future<void> dispose() async {
    if (_vault != null) {
      await _vault!.dispose();
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

    if (enc == null || sign == null) {
      throw Exception("Failed to restore keys: invalid config returned");
    }

    // 4. Save to Storage (Overwrite existing)
    await _storage.write(key: _kEncKey, value: enc);
    await _storage.write(key: _kSignSeed, value: sign);

    // 5. Re-initialize memory (Dispose old vault, create new one)
    await dispose();
    await initialize();
  }
}
