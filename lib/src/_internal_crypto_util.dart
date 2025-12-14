import 'dart:convert';
import 'package:crypto/crypto.dart';

int generateNumericSymbol(String ticker) {
  var bytes = utf8.encode(ticker);
  var hash = sha256.convert(bytes).toString();
  return int.parse(hash.substring(0, 10), radix: 16) % 1000000000;
}

int generateSecureNumericHash(String input) {
  final String sanitizedInput = input.trim().toUpperCase();
  final hash = sha256.convert(utf8.encode(sanitizedInput)).bytes;

  // Converte os primeiros 8 bytes em um inteiro positivo
  return List.generate(
    8,
    (i) => hash[i],
  ).fold(0, (acc, byte) => (acc << 8) | byte).abs();
}
