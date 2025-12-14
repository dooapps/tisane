import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:infusion_ffi/infusion_ffi.dart';
// For hex decoding if needed

import 'dart:io';

void main() {
  group('Infusion FFI Full Functionality Verification', () {
    if (Platform.environment.containsKey('CI')) {
      print('Skipping Infusion FFI verification tests in CI environment');
      return;
    }
    test('mnemonicGenerate returns valid 12-word mnemonic', () async {
      final mnemonic = await InfusionFFI.mnemonicGenerate(wordCount: 12);
      expect(mnemonic, isNotNull);
      expect(mnemonic.isNotEmpty, true);
      final words = mnemonic.split(' ');
      expect(words.length, 12, reason: 'Mnemonic should have 12 words');
    });

    test('mnemonicRestore works and returns valid key config', () async {
      // 1. Generate a valid mnemonic first
      final mnemonic = await InfusionFFI.mnemonicGenerate(wordCount: 12);

      // 2. Restore from it
      final jsonConfig = await InfusionFFI.mnemonicRestore(mnemonic);
      expect(jsonConfig, isNotNull);

      // 3. Parse JSON
      final Map<String, dynamic> config = jsonDecode(jsonConfig);
      expect(config.containsKey('enc_key_hex'), true);
      expect(config.containsKey('sign_seed_hex'), true);

      final encKey = config['enc_key_hex'];
      final signSeed = config['sign_seed_hex'];

      expect(encKey, isNotNull);
      expect(signSeed, isNotNull);
      // Expecting 32 bytes hex encoded = 64 chars
      expect(encKey.length, 64);
      expect(signSeed.length, 64);
    });

    test('Cycle: Create -> Seal -> Open -> Dispose', () async {
      // Setup keys
      final mnemonic = await InfusionFFI.mnemonicGenerate(wordCount: 12);
      final jsonConfig = await InfusionFFI.mnemonicRestore(mnemonic);
      final Map<String, dynamic> config = jsonDecode(jsonConfig);

      final encKey = config['enc_key_hex'];
      final signSeed = config['sign_seed_hex'];

      // Create Vault
      final vault = await InfusionFFI.create(
        encKeyHex: encKey,
        signSeedHex: signSeed,
      );
      expect(vault, isNotNull);

      // Data to encrypt
      final plainText = 'Hello Infusion!';
      final data = Uint8List.fromList(utf8.encode(plainText));

      // Seal (Encrypt)
      final sealed = await vault.seal(data: data, policyId: 0);
      expect(sealed, isNotNull);
      expect(sealed.isNotEmpty, true);
      expect(
        listEquals(sealed, data),
        false,
        reason: 'Ciphertext should differ from plaintext',
      );

      // Open (Decrypt)
      final opened = await vault.open(sealed);
      expect(opened, isNotNull);
      expect(
        listEquals(opened, data),
        true,
        reason: 'Decrypted data should match original',
      );

      // Dispose
      await vault.dispose();
    });

    test('blindIndex generates deterministic output', () async {
      // Setup keys
      final mnemonic = await InfusionFFI.mnemonicGenerate(wordCount: 12);
      final jsonConfig = await InfusionFFI.mnemonicRestore(mnemonic);
      final Map<String, dynamic> config = jsonDecode(jsonConfig);

      final vault = await InfusionFFI.create(
        encKeyHex: config['enc_key_hex'],
        signSeedHex: config['sign_seed_hex'],
      );

      final input = "search_term";

      // Call 1
      final blind1 = await vault.blindIndex(input);
      expect(blind1, isNotNull);

      // Call 2
      final blind2 = await vault.blindIndex(input);
      expect(blind2, isNotNull);

      // Verify Determinism
      expect(
        listEquals(blind1, blind2),
        true,
        reason: 'Blind index should be deterministic for same input and key',
      );

      // Call 3 with different input
      final blind3 = await vault.blindIndex("different_term");
      expect(
        listEquals(blind1, blind3),
        false,
        reason: 'Different inputs should produce different indexes',
      );

      await vault.dispose();
    });

    test('deriveKey returns derived bytes', () async {
      // Setup keys
      final mnemonic = await InfusionFFI.mnemonicGenerate(wordCount: 12);
      final jsonConfig = await InfusionFFI.mnemonicRestore(mnemonic);
      final Map<String, dynamic> config = jsonDecode(jsonConfig);

      final vault = await InfusionFFI.create(
        encKeyHex: config['enc_key_hex'],
        signSeedHex: config['sign_seed_hex'],
      );

      final context = Uint8List.fromList(utf8.encode("test_context"));
      final derived = await vault.deriveKey(context);

      expect(derived, isNotNull);
      expect(derived.length, greaterThan(0));

      await vault.dispose();
    });
  });
}
