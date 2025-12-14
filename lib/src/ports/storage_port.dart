import 'dart:typed_data';

/// Function signature for initializing the storage backend.
typedef StorageInitializer =
    Future<void> Function({Uint8List? encryptionKeyUint8List, String? key});

/// Function signature for checking whether the storage backend is open.
typedef StorageOpenCheck = bool Function();

StorageInitializer? storageInitializer;
StorageOpenCheck? storageOpenChecker;

/// Storage abstraction that mirrors the existing Hive-based behaviour.
abstract class TTStoragePort {
  Future<void> ensureInitialized({
    Uint8List? encryptionKeyUint8List,
    String? key,
  });

  bool get isOpen;
}

class HiveStoragePort implements TTStoragePort {
  const HiveStoragePort({
    StorageInitializer? initializer,
    StorageOpenCheck? openCheck,
  }) : _initializer = initializer,
       _openCheck = openCheck;

  final StorageInitializer? _initializer;
  final StorageOpenCheck? _openCheck;

  @override
  Future<void> ensureInitialized({
    Uint8List? encryptionKeyUint8List,
    String? key,
  }) async {
    final initializer = _initializer ?? storageInitializer;
    if (initializer == null) {
      throw StateError('TT storage initializer not registered');
    }
    await initializer(encryptionKeyUint8List: encryptionKeyUint8List, key: key);
  }

  @override
  bool get isOpen {
    final checker = _openCheck ?? storageOpenChecker;
    if (checker == null) {
      return false;
    }
    return checker();
  }
}

TTStoragePort createDefaultStoragePort() => const HiveStoragePort();
