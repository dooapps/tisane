import '../_internal_blind_scaling.dart' as blind;

typedef FutureIntEncoder = Future<int> Function(double value, String assetType);
typedef FutureDoubleDecoder =
    Future<double> Function(int value, String assetType);

/// Encapsulates crypto/FFI helpers so they can be stubbed in tests.
abstract class TTCryptoPort {
  Future<int> getBlindScale(String assetType);

  Future<int> encodeScale(double value, String assetType);

  Future<double> decodeScale(int value, String assetType);
}

class FbblCryptoPort implements TTCryptoPort {
  const FbblCryptoPort({
    blind.FutureIntResolver? resolver,
    FutureIntEncoder? encoder,
    FutureDoubleDecoder? decoder,
  }) : _resolver = resolver,
       _encoder = encoder,
       _decoder = decoder;

  final blind.FutureIntResolver? _resolver;
  final FutureIntEncoder? _encoder;
  final FutureDoubleDecoder? _decoder;

  @override
  Future<int> getBlindScale(String assetType) {
    final resolver = _resolver;
    if (resolver != null) {
      return resolver(assetType);
    }
    return blind.getBlindScale(assetType);
  }

  @override
  Future<int> encodeScale(double value, String assetType) async {
    final encoder = _encoder;
    if (encoder != null) {
      return encoder(value, assetType);
    }
    return blind.encodeScale(value, assetType);
  }

  @override
  Future<double> decodeScale(int value, String assetType) async {
    final decoder = _decoder;
    if (decoder != null) {
      return decoder(value, assetType);
    }
    return blind.decodeScale(value, assetType);
  }
}

TTCryptoPort createDefaultCryptoPort() => const FbblCryptoPort();
