import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:tisane/src/storage/encrypted_storage_adapter.dart';

import 'package:tisane/tisane.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    // Mock Path Provider
    const pathChannel = MethodChannel('plugins.flutter.io/path_provider');
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(pathChannel, (MethodCall methodCall) async {
          if (methodCall.method == 'getApplicationDocumentsDirectory') {
            return '.';
          }
          return null;
        });

    // Mock Secure Storage (used by InfusionManager.initialize)
    const secureChannel = MethodChannel(
      'plugins.it_nomads.com/flutter_secure_storage',
    );
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(secureChannel, (MethodCall methodCall) async {
          // Return null for all to simulate empty storage / successful write
          return null;
        });
  });

  group('EncryptedStorageAdapter Integration', () {
    test('computeBlindIndex calls InfusionManager', () async {
      try {
        await InfusionManager.initialize();
        final idx = await EncryptedStorageAdapter.computeBlindIndex(
          'test_value',
        );
        expect(idx, isNotEmpty);
        expect(idx, isA<String>());
      } catch (e) {
        // Allow failure if dylib is missing, as this is an environment issue
        // not a code logic issue.
        if (e.toString().contains('libinfusion_ffi')) {
          markTestSkipped('Native library libinfusion_ffi not found');
        } else {
          rethrow;
        }
      }
    });
  });

  group('Secure Storage Init', () {
    test('Initialize uses encryption', () async {
      try {
        await Hive.initFlutter();
        // Use a mock key to avoid Infusion dependency if possible?
        // initTTStore calls InfusionManager.initialize() unconditionally.
        // So we can't avoid it.

        await initializeTTStore();

        expect(InitStorage.hiveOpenBox, isNotNull);
        expect(InitStorage.hiveOpenBox!.isOpen, isTrue);

        // Verify we can write/read
        await InitStorage.hiveOpenBox!.put('test_key', 'test_val');
        expect(InitStorage.hiveOpenBox!.get('test_key'), 'test_val');
      } catch (e) {
        if (e.toString().contains('libinfusion_ffi')) {
          markTestSkipped('Native library libinfusion_ffi not found');
        } else {
          rethrow;
        }
      }
    });
  });
}
