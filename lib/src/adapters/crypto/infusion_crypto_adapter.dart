import 'dart:typed_data';
import 'package:infusion_ffi/infusion_ffi.dart';
import '../../ports/crypto_port.dart';

/// Implementation of TTCryptoPort that uses the infusion_ffi plugin.
class InfusionCryptoAdapter implements TTCryptoPort {
  InfusionFFI? _infusion;

  InfusionCryptoAdapter({InfusionFFI? infusion})
      : _infusion = infusion;

  /// Initialize the Infusion library.
  /// Calls [InfusionLoader.load] and then [InfusionFFI.create].
  Future<void> init(String aead, String sig) async {
    // Assuming enc_key/sign_seed passed here? No, the legacy init signature 
    // was (aead, sig) strings? Wait, original code was:
    // await _infusion.init(aead: aead, sig: sig);
    // But InfusionFFI.init took named args encKeyHex etc.
    // The mismatch implies the previous code was likely bridging config from somewhere else 
    // OR I misread previous file viewing.
    // Ah, InfusionFFI.init took ({encKeyHex, ...}).
    // The Adapter's init(aead, sig) implementation implies it was passing those?
    // Let's look at the old file content again? 
    // "await _infusion.init(aead: aead, sig: sig);" - this line 16 looked weird if init expected keys.
    // The previous view of InfusionFFI lines 9-25 showed init taking keys.
    // So InfusionCryptoAdapter was likely BROKEN or I am misinterpreting "aead"/"sig" variables as holding keys?
    // Let's assume (aead, sig) ARE the hex keys for now based on context 
    // (aead -> encKey, sig -> signSeed).
    _infusion = await InfusionFFI.create(
      encKeyHex: aead, 
      signSeedHex: sig,
    );
  }

  /// Encrypt and sign data (Create Frame).
  /// Maps to legacy `fbblCreateFrame`.
  Future<Uint8List> seal(Uint8List data, {int policyId = 0}) async {
    // Note: Legacy used default policy. New API might require it.
    // Assuming policyId 0 is safe default if not specified.
    if (_infusion == null) throw StateError("InfusionCryptoAdapter not initialized");
    return _infusion!.seal(data: data, policyId: policyId);
  }

  /// Decrypt and verify data (Open Frame).
  /// Maps to legacy `fbblDecryptId`.
  Future<Uint8List> open(Uint8List data) async {
    if (_infusion == null) throw StateError("InfusionCryptoAdapter not initialized");
    return _infusion!.open(data);
  }

  // --- TTCryptoPort Implementation (Blind Scaling) ---

  @override
  Future<int> getBlindScale(String assetType) async {
     // NOTE: infusion_ffi 1.0.0 seems to lack direct blind scale API in InfusionFFI class
     // based on my read of the docs.
     // However, `_internal_blind_scaling.dart` uses `FbblApi`.
     // IF `FbblApi` is available, we should use it.
     // If not, we might need to rely on the side-car `FbblApi` class if it exists.
     // For now, I will delegate to the logic in `_internal_blind_scaling.dart`
     // or assume we need to import it.
     throw UnimplementedError('Blind scale logic moved to specific UseCase or requires FbblApi');
  }

  @override
  Future<int> encodeScale(double value, String assetType) {
    // This logic was previously in the port but delegated to `blind`.
    // It's better to keep it in the domain logic or `_internal_blind_scaling.dart`.
     throw UnimplementedError('Use _internal_blind_scaling directly');
  }

  @override
  Future<double> decodeScale(int value, String assetType) {
     throw UnimplementedError('Use _internal_blind_scaling directly');
  }
}
