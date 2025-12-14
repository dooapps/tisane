import 'dart:typed_data';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:hive_flutter/adapters.dart';

import '../ports/storage_port.dart' as storage_port;
import '../sea/infusion_manager.dart';

class InitStorage {
  static const secureStorage = FlutterSecureStorage();
  static Box<dynamic>? hiveOpenBox;
  static const _internalHiveBoxKey = 'secure-vaultBox';

  Future<Uint8List> _getEncryptedKey([String? key]) async {
    // If a specific key override is requested, we could handle it here,
    // but for the main vault, we recommend deriving from Infusion.
    return InfusionManager.getHiveKey();
  }

  static Future<Box<dynamic>> getHiveBox({
    Uint8List? encryptionKeyUint8List,
    String? key,
  }) async {
    return (hiveOpenBox = await Hive.openBox(
      _internalHiveBoxKey,
      encryptionCipher: HiveAesCipher(
        encryptionKeyUint8List ?? await InitStorage()._getEncryptedKey(key),
      ),
    ));
  }
}

Future<void> initializeTTStore({
  Uint8List? encryptionKeyUint8List,
  String? key,
}) async {
  _registerStoragePortDefaults();
  await Hive.initFlutter();
  await InfusionManager.initialize();
  await InitStorage.getHiveBox(
    encryptionKeyUint8List: encryptionKeyUint8List,
    key: key,
  );
}

void _registerStoragePortDefaults() {
  storage_port.storageInitializer ??= initializeTTStore;
  storage_port.storageOpenChecker ??= () =>
      InitStorage.hiveOpenBox?.isOpen ?? false;
}
