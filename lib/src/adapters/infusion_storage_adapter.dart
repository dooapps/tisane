import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../ports/infusion_storage_port.dart';

/// Implementation of [InfusionStoragePort] using [FlutterSecureStorage].
class SecureStorageAdapter implements InfusionStoragePort {
  const SecureStorageAdapter([this._storage = const FlutterSecureStorage()]);

  final FlutterSecureStorage _storage;

  @override
  Future<String?> read({required String key}) {
    return _storage.read(key: key);
  }

  @override
  Future<void> write({required String key, required String value}) {
    return _storage.write(key: key, value: value);
  }

  @override
  Future<void> delete({required String key}) {
    return _storage.delete(key: key);
  }
}

/// In-memory implementation of [InfusionStoragePort] for testing.
class MemoryStorageAdapter implements InfusionStoragePort {
  final Map<String, String> _storage = {};

  @override
  Future<String?> read({required String key}) async {
    return _storage[key];
  }

  @override
  Future<void> write({required String key, required String value}) async {
    _storage[key] = value;
  }

  @override
  Future<void> delete({required String key}) async {
    _storage.remove(key);
  }
}
