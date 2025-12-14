import 'dart:typed_data';

import 'package:test/test.dart';
import 'package:tisane/src/ports/storage_port.dart';

/// Contract tests for TTStoragePort behaviour.
void defineStoragePortContract(
  String name,
  TTStoragePort Function() create,
) {
  group('TTStoragePort contract: $name', () {
    test('ensureInitialized invokes initializer; isOpen reflects checker',
        () async {
      bool initialized = false;
      bool open = false;

      final port = HiveStoragePort(
        initializer: ({Uint8List? encryptionKeyUint8List, String? key}) async {
          initialized = true;
        },
        openCheck: () => open,
      );

      expect(port.isOpen, isFalse);
      await port.ensureInitialized();
      expect(initialized, isTrue);
      expect(port.isOpen, isFalse);
      open = true;
      expect(port.isOpen, isTrue);
    });
  });
}
