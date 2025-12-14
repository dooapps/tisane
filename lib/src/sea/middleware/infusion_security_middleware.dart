
import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:convert/convert.dart';
import '../../types/tt.dart';
import '../infusion_manager.dart';

/// Middleware that protects graph data using Infusion (IP Vault).
///
/// - Writes: Seals all node values (encrypts + signs).
/// - Reads: Opens sealed values (verifies signature + decrypts).
class InfusionSecurityMiddleware {
  static const String _kPrefix = 'INF:';

  /// Intercepts data writing to the graph.
  /// Encrypts/Signs every field value before it touches the graph.
  static FutureOr<TTGraphData?> onWrite(
      TTGraphData data, TTGraphData graphSnapshot) async {
    final TTGraphData protected = TTGraphData();

    for (final soul in data.keys) {
      final node = data[soul];
      if (node == null) continue;

      final TTNode protectedNode = TTNode();
      // Preserve metadata if present
      if (node.nodeMetaData != null) {
        protectedNode.nodeMetaData = node.nodeMetaData;
      }

      for (final key in node.keys) {
        // Skip metadata key '_' if it leaked here (though TTNode separates it)
        if (key == '_') continue;

        final value = node[key];
        if (value == null) continue;

        try {
          // Serialize value to bytes
          final jsonStr = jsonEncode(value);
          final bytes = Uint8List.fromList(utf8.encode(jsonStr));

          // Seal (Encrypt + Sign)
          // Uses policyId=0 (default) and empty metadata for now.
          // Accessing ffi directly from InfusionManager
          final vault = await InfusionManager.vault;
          final sealedFrame = await vault.seal(
            data: bytes,
            policyId: 0,
          );

          // Encode as hex or base64 to store in graph string
          // Prefixing to identify it's an Infusion Frame
          final storageValue = '$_kPrefix${hex.encode(sealedFrame)}';
          protectedNode[key] = storageValue;
        } catch (e) {
          // If sealing fails, what do we do?
          // For now, rethrow to block the write. Data MUST be protected.
          throw Exception('Infusion Sealing failed for $key: $e');
        }
      }
      protected[soul] = protectedNode;
    }

    return protected;
  }

  /// Intercepts data reading from the graph.
  /// Decrypts/Verifies every field value.
  static FutureOr<TTGraphData?> onRead(
      TTGraphData data, TTGraphData graphSnapshot) async {
    final TTGraphData revealed = TTGraphData();

    for (final soul in data.keys) {
      final node = data[soul];
      if (node == null) continue;

      final TTNode revealedNode = TTNode();
      if (node.nodeMetaData != null) {
        revealedNode.nodeMetaData = node.nodeMetaData;
      }

      for (final key in node.keys) {
        if (key == '_') continue;

        final value = node[key];
        // Check if value is a String and has our prefix
        if (value is String && value.startsWith(_kPrefix)) {
          try {
            final hexFrame = value.substring(_kPrefix.length);
            final frameBytes = Uint8List.fromList(hex.decode(hexFrame));

            // Open (Verify Signature + Decrypt)
            final vault = await InfusionManager.vault;
            final clearBytes = await vault.open(frameBytes);
            
            // Deserialize
            final jsonStr = utf8.decode(clearBytes);
            final originalValue = jsonDecode(jsonStr);
            
            revealedNode[key] = originalValue;
          } catch (e) {
            // Verification failed or Decryption failed.
            // Requirement: "Se a assinatura for inválida... O dado é rejeitado."
            // We simply DO NOT include this key in the revealed node.
            // The reader sees nothing (effectively "access denied").
            // print('Infusion access denied for $soul/$key');
            continue;
          }
        } else {
          // Pass through unprotected data?
          // Policy check: Do we allow mixed content?
          // If we want "Strict Mode", we should drop it.
          // For transition/compatibility, we might pass it.
          // User said "O cofre serve para armazenar qualquer tipo de dados".
          // Better safe: If it's not sealed, it might be system data or legacy.
          // Let's pass it through but maybe flag it? 
          // For now: Pass through.
          revealedNode[key] = value;
        }
      }
      revealed[soul] = revealedNode;
    }

    return revealed;
  }
}
