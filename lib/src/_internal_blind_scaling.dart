import 'sea/infusion_manager.dart';

typedef FutureIntResolver = Future<int> Function(String assetType);

Future<int> getBlindScale(String assetType) async {
  // Uses InfusionManager to get a blind index hash
  final hexResult = await InfusionManager.getBlindIndex(assetType);
  
  // Use first 15 chars to ensure it fits in a signed 64-bit int (safe parsing)
  final sub = hexResult.length > 15 ? hexResult.substring(0, 15) : hexResult;
  return int.parse(sub, radix: 16);
}

Future<int> encodeScale(double value, String assetType) async {
  final hash = await getBlindScale(assetType);
  return (value * hash).round();
}

Future<double> decodeScale(int value, String assetType) async {
  final hash = await getBlindScale(assetType);
  return value / hash;
}

Future<double> generateBlindScale(String assetType) async {
  final hash = await getBlindScale(assetType);
  return hash.toDouble();
}

Future<List<double>> applyBlindScale(
    List<int> encodedValues, double blindScale) async {
  return encodedValues.map((e) => e / blindScale).toList();
}

Future<List<int>> revertBlindScale(
    List<double> blindValues, double blindScale) async {
  return blindValues.map((e) => (e * blindScale).round()).toList();
}
