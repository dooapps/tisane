import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import '../../types/tt.dart';
import '../infusion_manager.dart';
import '../infusion_types.dart';

/// Middleware that protects graph data using Infusion (IP Vault).
///
/// - Writes: Seals all node values (encrypts + signs).
/// - Reads: Opens sealed values (verifies signature + decrypts).
class InfusionSecurityMiddleware {
  /// Intercepts data writing to the graph.
  /// Encrypts/Signs every field value before it touches the graph.
  static FutureOr<TTGraphData?> onWrite(
    TTGraphData data,
    TTGraphData graphSnapshot,
  ) async {
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

          final policyId = InfusionManager.resolvePolicyId(
            soul: soul,
            field: key,
            value: value,
            nodeMeta: node.nodeMetaData?.toJson(),
          );
          final aad = InfusionManager.buildAad(
            soul: soul,
            field: key,
            policyId: policyId,
          );
          final aadBytes = aad.toBytes();

          // Seal (Encrypt + Sign) with AAD and policy
          final sealedFrame = await InfusionManager.seal(
            data: bytes,
            policyId: policyId,
            aad: aadBytes,
          );

          Uint8List? capToken;
          if (InfusionManager.config.embedCapToken) {
            capToken = await InfusionManager.resolveCapToken(
              InfusionCapContext(
                soul: soul,
                field: key,
                policyId: policyId,
                aad: aadBytes,
                value: value,
              ),
            );
          }

          final envelope = InfusionEnvelope(
            version: 1,
            policyId: policyId,
            frame: sealedFrame,
            aad: aadBytes,
            capToken: capToken,
          );

          // Encode as structured envelope to store in graph string
          final storageValue = envelope.encode();
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
    TTGraphData data,
    TTGraphData graphSnapshot,
  ) async {
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
        if (value is String) {
          final envelope = InfusionEnvelope.tryParse(
            value,
            defaultPolicyId: InfusionManager.config.defaultPolicyId,
          );
          if (envelope == null) {
            revealedNode[key] = value;
            continue;
          }
          try {
            final policy = InfusionManager.policyFor(envelope.policyId);
            final aadBytes = envelope.aad;
            if (InfusionManager.config.enforceAadContext && aadBytes != null) {
              final aad = InfusionAad.tryParse(aadBytes);
              if (aad == null ||
                  aad.soul != soul ||
                  aad.field != key ||
                  aad.policyId != envelope.policyId) {
                continue;
              }
            }

            final capContext = InfusionCapContext(
              soul: soul,
              field: key,
              policyId: envelope.policyId,
              aad: aadBytes,
              value: value,
            );

            Uint8List? capToken = envelope.capToken;
            final providedToken = await InfusionManager.resolveCapToken(
              capContext,
            );
            if (providedToken != null) {
              capToken = providedToken;
            }

            final requesterPub = await InfusionManager.resolveRequesterPub(
              capContext,
            );

            if (policy.requiresCapToken) {
              if (capToken == null || requesterPub == null) {
                continue;
              }
              final ok = await InfusionManager.verifyCapToken(
                capToken: capToken,
                requesterPub32: requesterPub,
              );
              if (!ok) continue;
            } else if (capToken != null && requesterPub != null) {
              final ok = await InfusionManager.verifyCapToken(
                capToken: capToken,
                requesterPub32: requesterPub,
              );
              if (!ok) {
                capToken = null;
              }
            }

            if (InfusionManager.config.verifyFrameBeforeOpen) {
              final result = await InfusionManager.verifyFrame(envelope.frame);
              if (!result.ok) continue;
            }

            // Open (Verify Signature + Decrypt)
            final clearBytes = await InfusionManager.open(
              envelope.frame,
              capToken: capToken,
            );

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
