
import "dart:core";
import "dart:math";

import "package:luffy/util.dart";

class JsUnpacker {
  JsUnpacker(String? packedJS) {
    _packedJS = packedJS;
  }

  String? _packedJS;

  bool detect() {
    final js = _packedJS?.replaceAll(" ", "");
    final p = RegExp(r"eval\(function\(p,a,c,k,e,[rd]");
    return p.hasMatch(js ?? "");
  }

  String? unpack() {
    final js = _packedJS;

    if (js == null) {
      return null;
    }

    try {
      final p = RegExp(
        r"\}\s*\('(.*)',\s*(.*?),\s*(\d+),\s*'(.*?)'\.split\('\|'\)",
        dotAll: true,
      );

      final matches = p.allMatches(js);

      for (final match in matches) {
        if (match.groupCount != 4) {
          continue;
        }

        var payload = match.group(1)!.replaceAll(r"\'", "'");
        final radixStr = match.group(2)!;
        final countStr = match.group(3)!;
        final symtab = match.group(4)!.split(RegExp(r"\|"));
        final radix = int.tryParse(radixStr) ?? 36;
        final count = int.tryParse(countStr) ?? 0;

        if (symtab.length != count) {
          throw Exception("Unknown p.a.c.k.e.r. encoding");
        }

        final unbase = Unbase(radix);
        final matches2 = RegExp(r"\b\w+\b").allMatches(payload);
        int replaceOffset = 0;

        for (final match2 in matches2) {
          final word = match2.group(0)!;
          final x = unbase.unbase(word);

          String? value;

          if (x < symtab.length && x >= 0) {
            value = symtab[x];
          }

          if (value != null && value.isNotEmpty) {
            final start = match2.start + replaceOffset;
            final end = match2.end + replaceOffset;

            payload = payload.replaceRange(
              start,
              end,
              value,
            );

            replaceOffset += value.length - word.length;
          }
        }

        return payload;
      }
    } catch (e) {
      logError(e);
    }

    return null;
  }

  void logError(dynamic e) {
    prints("JsUnpacker error: $e");
  }
}

class Unbase {
  Unbase(int radix) : _radix = radix {
    if (radix <= 36) {
      return;
    }

    if (radix < 62) {
      _alphabet = alphabet62.substring(0, radix);
    } else if (radix >= 63 && radix <= 94) {
      _alphabet = alphabet95.substring(0, radix);
    } else if (radix == 62) {
      _alphabet = alphabet62;
    } else if (radix == 95) {
      _alphabet = alphabet95;
    }

    _dictionary = <String, int>{};

    for (int i = 0; i < _alphabet!.length; i++) {
      _dictionary![_alphabet!.substring(i, i + 1)] = i;
    }
  }

  static const alphabet62 =
      "0123456789abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ";
  static const alphabet95 =
      " !\"#\$%&\\'()*+,-./0123456789:;<=>?@ABCDEFGHIJKLMNOPQRSTUVWXYZ[\\\\]^_`abcdefghijklmnopqrstuvwxyz{|}~";

  String? _alphabet;
  late Map<String, int>? _dictionary;
  final int _radix;

  int unbase(String str) {
    if (_alphabet == null) {
      return int.parse(str, radix: _radix);
    }

    final tmp = str.split("").reversed.join();

    int ret = 0;

    int multiplyToInt32Max(int a, int b) {
      const int32MaxValue = 2147483647;

      return (a * b).clamp(-int32MaxValue - 1, int32MaxValue);
    }

    for (int i = 0; i < tmp.length; i++) {
      final powResult = pow(_radix, i).toInt();
      final dictResult = _dictionary![tmp.substring(i, i + 1)]!;
      final multiplyResult = multiplyToInt32Max(powResult, dictResult);

      ret += multiplyResult;
    }

    return ret;
  }
}

final _packedRegex = RegExp(r"eval\(function\(p,a,c,k,e,.*\)\)");

List<String?> getAndUnpack(String str) {
  final matches = _packedRegex.allMatches(str);

  return matches.map((e) => JsUnpacker(e.group(0)).unpack()).toList();
}
