import '_internal_blind_scaling.dart';
import '_internal_crypto_util.dart';

Future<List<num>> generateCandleVector({
  required String assetType,
  required String ticker,
  required int timestamp,
  required double open,
  required double close,
  required double low,
  required double high,
}) async {
  final encodedOpen = await encodeScale(open, assetType);
  final encodedClose = await encodeScale(close, assetType);
  final encodedLow = await encodeScale(low, assetType);
  final encodedHigh = await encodeScale(high, assetType);

  final blindScale = await generateBlindScale(assetType);
  final blindOHLC = await applyBlindScale([
    encodedOpen,
    encodedClose,
    encodedLow,
    encodedHigh,
  ], blindScale);

  final fbblNumber = generateSecureNumericHash(ticker);

  return [timestamp, ...blindOHLC, fbblNumber];
}

Future<List<List<num>>> generateCandleVectors({
  required String assetType,
  required String ticker,
  required List<int> timestamps,
  required List<double> opens,
  required List<double> closes,
  required List<double> lows,
  required List<double> highs,
}) async {
  final int length = timestamps.length;
  if ([opens, closes, lows, highs].any((list) => list.length != length)) {
    throw ArgumentError(
      'Todas as listas devem ter o mesmo tamanho e não podem estar vazias.',
    );
  }
  if (length == 0) {
    throw ArgumentError('As listas não podem estar vazias.');
  }

  final fbblNumber = generateSecureNumericHash(ticker);
  final blindScale = await generateBlindScale(assetType);

  List<List<num>> vectors = [];

  for (int i = 0; i < length; i++) {
    final encodedOpen = await encodeScale(opens[i], assetType);
    final encodedClose = await encodeScale(closes[i], assetType);
    final encodedLow = await encodeScale(lows[i], assetType);
    final encodedHigh = await encodeScale(highs[i], assetType);

    final blindOHLC = await applyBlindScale([
      encodedOpen,
      encodedClose,
      encodedLow,
      encodedHigh,
    ], blindScale);

    vectors.add([timestamps[i], ...blindOHLC, fbblNumber]);
  }

  return vectors;
}

Future<List<Map<String, dynamic>>> unpackCandleVectors({
  required List<List<num>> vectors,
  required String assetType,
  required double blindScale,
}) async {
  final List<Map<String, dynamic>> unpacked = [];

  for (final vector in vectors) {
    if (vector.length != 6) {
      continue; // segurança: formato esperado [timestamp, o, c, l, h, id]
    }

    final timestamp = vector[0].toInt();
    final blindOHLC = vector.sublist(1, 5).cast<double>();
    final decodedOHLCBlind = await revertBlindScale(blindOHLC, blindScale);
    final scale = await getBlindScale(assetType);
    final decodedOHLC = decodedOHLCBlind.map((v) => v / scale).toList();

    unpacked.add({
      'timestamp': timestamp,
      'open': decodedOHLC[0],
      'close': decodedOHLC[1],
      'low': decodedOHLC[2],
      'high': decodedOHLC[3],
      'fbblNumber': vector[5].toInt(),
    });
  }

  return unpacked;
}
