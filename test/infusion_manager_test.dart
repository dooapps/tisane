import 'dart:convert';
import 'dart:developer' as developer;
import 'dart:math';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tisane/tisane.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final mockStorage = <String, String>{};

  setUp(() {
    mockStorage.clear();

    const channel = MethodChannel(
      'plugins.it_nomads.com/flutter_secure_storage',
    );

    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (MethodCall methodCall) async {
          if (methodCall.method == 'read') {
            final Map<dynamic, dynamic> args = methodCall.arguments;
            final key = args['key'] as String;
            final val = mockStorage[key];
            developer.log(
              'MockStorage Read: $key -> $val',
              name: 'tisane.tests',
            );
            return val;
          }
          if (methodCall.method == 'write') {
            final Map<dynamic, dynamic> args = methodCall.arguments;
            final key = args['key'] as String;
            final value = args['value'] as String;
            developer.log(
              'MockStorage Write: $key -> $value',
              name: 'tisane.tests',
            );
            mockStorage[key] = value;
            return null;
          }
          return null;
        });
  });

  tearDown(() async {
    await InfusionManager.dispose();
  });

  group('InfusionManager Integration', () {
    // Check if we can load the library. If not, skip the group.
    setUp(() async {
      try {
        await InfusionManager.initialize();
      } catch (e) {
        if (e.toString().contains('libinfusion_ffi')) {
          markTestSkipped('Native library libinfusion_ffi not found');
        } else {
          rethrow;
        }
      }
    });

    test('seal and open work correctly', () async {
      try {
        await InfusionManager.initialize();
      } catch (e) {
        if (e.toString().contains('libinfusion_ffi')) {
          markTestSkipped('Native library libinfusion_ffi not found');
          return;
        }
        rethrow;
      }

      final data = Uint8List.fromList(utf8.encode("Sensitive Data"));

      // 1. Seal
      final sealed = await InfusionManager.seal(data: data);
      expect(sealed, isNotNull);
      expect(sealed, isNot(data));

      // 2. Open
      final opened = await InfusionManager.open(sealed);
      expect(opened, data);
    });

    test('deriveKey returns correct length', () async {
      try {
        await InfusionManager.initialize();
      } catch (e) {
        if (e.toString().contains('libinfusion_ffi')) {
          markTestSkipped('Native library libinfusion_ffi not found');
          return;
        }
        rethrow;
      }
      final context = Uint8List.fromList(utf8.encode("context"));
      final key = await InfusionManager.deriveKey(context);
      expect(key.length, greaterThan(0));
    });

    test('issueCap and verify flow', () async {
      // Generate a real mnemonic and restore to ensure valid keys
      try {
        await InfusionManager.initialize();
      } catch (e) {
        if (e.toString().contains('libinfusion_ffi')) {
          markTestSkipped('Native library libinfusion_ffi not found');
          return;
        }
        rethrow;
      }
      final mnemonic = await InfusionManager.generateMnemonic();
      await InfusionManager.restoreFromMnemonic(mnemonic);

      final rng = Random.secure();
      final delegatedPub = Uint8List(32);
      final scopeCid = Uint8List(32);
      for (var i = 0; i < 32; i++) {
        delegatedPub[i] = rng.nextInt(256);
        scopeCid[i] = rng.nextInt(256);
      }

      final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;

      final res = await InfusionManager.issueCap(
        delegatedPub32: delegatedPub,
        expTs: now + 3600,
        rights: 1,
        scopeCid: scopeCid,
      );

      expect(res, isNotNull);
      expect(res, isA<Uint8List>());
      expect(res.isNotEmpty, true);

      // Verify
      try {
        final isValid = await InfusionManager.verify(res);
        expect(isValid, isTrue);
      } catch (e) {
        developer.log(
          'Verification failed for cap: ${base64Encode(res)}',
          name: 'tisane.tests',
          level: 1000,
        );
        // Temporarily skipping due to known bug/stale binary
        rethrow;
      }
    });

    test('getBlindIndex returns deterministic hash', () async {
      try {
        await InfusionManager.initialize();
      } catch (e) {
        if (e.toString().contains('libinfusion_ffi')) {
          markTestSkipped('Native library libinfusion_ffi not found');
          return;
        }
        rethrow;
      }
      final idx1 = await InfusionManager.getBlindIndex("test_input");
      final idx2 = await InfusionManager.getBlindIndex("test_input");
      final idx3 = await InfusionManager.getBlindIndex("other_input");

      expect(idx1, isNotEmpty);
      expect(idx1, equals(idx2));
      expect(idx1, isNot(equals(idx3)));
    });

    test('getHiveKey returns valid key', () async {
      try {
        await InfusionManager.initialize();
      } catch (e) {
        if (e.toString().contains('libinfusion_ffi')) {
          markTestSkipped('Native library libinfusion_ffi not found');
          return;
        }
        rethrow;
      }
      final key = await InfusionManager.getHiveKey();
      expect(key, isA<Uint8List>());
      expect(key.length, greaterThan(0));
    });

    test('exportCredentials returns keys', () async {
      try {
        await InfusionManager.initialize();
      } catch (e) {
        if (e.toString().contains('libinfusion_ffi')) {
          markTestSkipped('Native library libinfusion_ffi not found');
          return;
        }
        rethrow;
      }
      final creds = await InfusionManager.exportCredentials();
      expect(creds.containsKey('enc_key_hex'), true);
      expect(creds.containsKey('sign_seed_hex'), true);
      expect(creds['enc_key_hex'], isNotEmpty);
    });

    test('seal encrypts with different policyId', () async {
      try {
        await InfusionManager.initialize();
      } catch (e) {
        if (e.toString().contains('libinfusion_ffi')) {
          markTestSkipped('Native library libinfusion_ffi not found');
          return;
        }
        rethrow;
      }
      final data = Uint8List.fromList(utf8.encode("Policy Data"));

      // Seal with default policy (0)
      final sealed0 = await InfusionManager.seal(data: data, policyId: 0);

      // Seal with specific policy (e.g., 100)
      final sealed100 = await InfusionManager.seal(data: data, policyId: 100);

      expect(sealed0, isNot(equals(sealed100)));

      // Both should be openable by the same owner (since policy is for capabilities, but owner has full access)
      // This verifies open works on data sealed with different policies
      final opened0 = await InfusionManager.open(sealed0);
      final opened100 = await InfusionManager.open(sealed100);

      expect(opened0, equals(data));
      expect(opened100, equals(data));
    });

    test('issueCap handles custom rights and expiration', () async {
      try {
        await InfusionManager.initialize();
      } catch (e) {
        if (e.toString().contains('libinfusion_ffi')) {
          markTestSkipped('Native library libinfusion_ffi not found');
          return;
        }
        rethrow;
      }

      // Ensure keys are set up
      if ((await InfusionManager.exportCredentials())['enc_key_hex'] == null) {
        await InfusionManager.initialize();
      }

      final rng = Random.secure();
      final delegatedPub = Uint8List(32);
      final scopeCid = Uint8List(32);
      for (var i = 0; i < 32; i++) {
        delegatedPub[i] = rng.nextInt(256);
        scopeCid[i] = rng.nextInt(256);
      }

      final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;

      // Test Case 1: Minimal rights
      final cap1 = await InfusionManager.issueCap(
        delegatedPub32: delegatedPub,
        expTs: now + 3600,
        rights: 0, // No rights
        scopeCid: scopeCid,
      );
      expect(await InfusionManager.verify(cap1), isTrue);

      // Test Case 2: Max rights
      final cap2 = await InfusionManager.issueCap(
        delegatedPub32: delegatedPub,
        expTs: now + 86400,
        rights:
            255, // All 8 bits set (assuming 8-bit rights field for now, though it's likely u64 in Rust)
        scopeCid: scopeCid,
      );
      expect(await InfusionManager.verify(cap2), isTrue);
    });

    test('deriveKey produces distinct keys for distinct contexts', () async {
      try {
        await InfusionManager.initialize();
      } catch (e) {
        if (e.toString().contains('libinfusion_ffi')) {
          markTestSkipped('Native library libinfusion_ffi not found');
          return;
        }
        rethrow;
      }
      final ctx1 = Uint8List.fromList(utf8.encode("context_one"));
      final ctx2 = Uint8List.fromList(utf8.encode("context_two"));

      final key1 = await InfusionManager.deriveKey(ctx1);
      final key2 = await InfusionManager.deriveKey(ctx2);

      expect(key1, isNot(equals(key2)));
      expect(key1.length, 32); // Assuming 32-byte keys
      expect(key2.length, 32);
    });

    test('Mnemonic flow (generate and restore)', () async {
      try {
        await InfusionManager.initialize();
      } catch (e) {
        if (e.toString().contains('libinfusion_ffi')) {
          markTestSkipped('Native library libinfusion_ffi not found');
          return;
        }
        rethrow;
      }
      final mnemonic = await InfusionManager.generateMnemonic();
      expect(mnemonic.split(' ').length, 12);

      await InfusionManager.restoreFromMnemonic(mnemonic);
      final creds = await InfusionManager.exportCredentials();

      expect(creds['enc_key_hex'], isNotEmpty);
      expect(creds['sign_seed_hex'], isNotEmpty);
    });
  });
}
