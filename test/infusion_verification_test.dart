import 'package:flutter_test/flutter_test.dart';
import 'package:infusion_ffi/infusion_ffi.dart';
import 'dart:typed_data';
import 'dart:io';

void main() {
  group('Infusion FFI Verification', () {
    if (Platform.environment.containsKey('CI')) {
      return;
    }
    test('Can generate mnemonic', () async {
      final mnemonic = await InfusionFFI.mnemonicGenerate(wordCount: 12);
      expect(mnemonic, isNotNull);
      expect(mnemonic.split(' ').length, 12);
    });

    test('Can create InfusionFFI instance and derive key', () async {
      // Use dummy hex keys (32 bytes = 64 hex chars)
      final encKey = '0' * 64;
      final signSeed = '0' * 64;

      final infusion = await InfusionFFI.create(
        encKeyHex: encKey,
        signSeedHex: signSeed,
      );

      expect(infusion, isNotNull);

      final context = Uint8List.fromList([1, 2, 3, 4]);
      final derivedKey = await infusion.deriveKey(context);
      expect(derivedKey, isNotNull);
      expect(derivedKey.length, greaterThan(0));

      await infusion.dispose();
    });
  });
}
