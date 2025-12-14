import 'dart:math' as math;

String pseudoRandomText([
  int length = 24,
  String charset =
      '0123456789ABCDEFGHIJKLMNOPQRSTUVWXZabcdefghijklmnopqrstuvwxyz',
]) {
  final buffer = StringBuffer();
  final random = math.Random();

  for (var i = 0; i < length; i++) {
    buffer.write(charset[random.nextInt(charset.length)]);
  }

  return buffer.toString();
}
