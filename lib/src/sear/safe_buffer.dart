import 'dart:typed_data';
import 'dart:convert';

import '../types/generic.dart';
import 'base64.dart';

class SafeBuffer extends GenericCustomList<int> {
  static SafeBuffer from(dynamic input, [String? enc]) {
    enc ??= 'utf-8';
    SafeBuffer buf = SafeBuffer();

    if (input is String) {
      if (enc == 'hex') {
        final bytes = RegExp(r"([\da-fA-F]{2})")
            .allMatches(input)
            .map((match) => int.parse(match.group(0)!, radix: 16))
            .toList();
        if (bytes.isEmpty) {
          throw ("Invalid first argument for type 'hex'.");
        }
        buf = SafeBuffer();
        for (final b in bytes) {
          buf.add(b);
        }
      } else if (enc == 'utf8' || enc == 'utf-8') {
        final bytes = utf8.encode(input);
        buf = SafeBuffer();
        for (final b in bytes) {
          buf.add(b);
        }
      } else if (enc == 'base64') {
        final dec = SearBase64.atob(input);
        buf = SafeBuffer();
        for (final b in dec) {
          buf.add(b);
        }
      } else if (enc == 'binary') {
        final codes = input.codeUnits;
        buf = SafeBuffer();
        for (final b in codes) {
          buf.add(b & 0xFF);
        }
      } else {
        throw ('SafeBuffer.from unknown encoding: $enc');
      }
      return buf;
    }
    // Handle non-string input types robustly
    if (input is ByteBuffer) {
      final view = input.asUint8List();
      final out = SafeBuffer();
      for (final b in view) {
        out.add(b);
      }
      return out;
    } else if (input is Uint8List) {
      final out = SafeBuffer();
      for (final b in input) {
        out.add(b);
      }
      return out;
    } else if (input is List<int>) {
      final out = SafeBuffer();
      for (final b in input) {
        out.add(b);
      }
      return out;
    } else {
      // Fallback: attempt to iterate if it's any Iterable of ints
      if (input is Iterable) {
        final out = SafeBuffer();
        for (final b in input) {
          if (b is int) out.add(b);
        }
        return out;
      }
    }
    return buf;
  }

  // This is 'safe-buffer.alloc' sans encoding support
  static Uint8List alloc(int length, [fill = 0]) {
    return Uint8List.fromList(List.filled(length, fill));
  }

  // This is normal UNSAFE 'buffer.alloc' or 'new Buffer(length)' - don't use!
  static SafeBuffer allocUnsafe(int length) {
    return SafeBuffer.from(Uint8List.fromList(List.filled(length, 0)));
  }

  // This puts together array of array like members
  static SafeBuffer concat(List<dynamic> arr) {
    final out = SafeBuffer();
    for (final item in arr) {
      if (item is Iterable) {
        for (final b in item) {
          if (b is int) out.add(b);
        }
      }
    }
    return out;
  }
}
