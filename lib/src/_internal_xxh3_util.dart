import 'dart:convert' show utf8;
import 'package:xxh3/xxh3.dart';

int generateXxh3Hash(String input) {
  final String sanitizedInput = input.trim().toUpperCase();
  return xxh3(utf8.encode(sanitizedInput));
}
