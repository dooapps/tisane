import 'package:hive/hive.dart';
import '../sea/infusion_manager.dart';

/// Adapter for higher-level encrypted storage operations.
///
/// While basic storage encryption is handled by [InitStorage] opening the box
/// with a key, this adapter provides helpers for:
/// - Blind Indexing (searching encrypted data)
class EncryptedStorageAdapter {
  
  /// Generates a deterministic blind index for a given value (e.g., an email).
  /// 
  /// This index can be used as a key/soul in the graph to point to the actual interface,
  /// allowing lookups without revealing the value itself.
  /// 
  /// Example:
  /// ```dart
  /// final idx = await EncryptedStorageAdapter.computeBlindIndex('alice@example.com');
  /// final soul = 'email/$idx';
  /// ```
  static Future<String> computeBlindIndex(String cleartextValue) async {
    return await InfusionManager.getBlindIndex(cleartextValue);
  }

  /// Helper to store a mapping from a blind index to a target soul.
  /// 
  /// [indexerSoulPrefix]: e.g., 'email'
  /// [cleartextValue]: e.g., 'alice@example.com'
  /// [targetSoul]: e.g., 'user/123'
  /// [box]: The open Hive box.
  static Future<void> saveBindIndex(
    Box box,
    String indexerSoulPrefix,
    String cleartextValue,
    String targetSoul,
  ) async {
    final idx = await computeBlindIndex(cleartextValue);
    final indexSoul = '$indexerSoulPrefix/$idx';
    
    // We store the targetSoul at this index.
    // In a full graph, this might be a node `{ "#": "user/123" }`
    // For simple KV storage:
    await box.put(indexSoul, targetSoul);
  }
  
  /// Resolves a blind index to the target soul.
  static Future<String?> resolveBlindIndex(
    Box box,
    String indexerSoulPrefix,
    String cleartextValue,
  ) async {
    final idx = await computeBlindIndex(cleartextValue);
    final indexSoul = '$indexerSoulPrefix/$idx';
    
    return box.get(indexSoul); // Returns targetSoul or null
  }
}
