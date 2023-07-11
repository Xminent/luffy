import "dart:convert";

import "package:flutter/foundation.dart";

dynamic tryJsonDecode(String s) {
  try {
    return jsonDecode(s);
  } catch (e) {
    return null;
  }
}

void prints(s1) {
  if (!kDebugMode) {
    return;
  }

  final s = s1.toString();
  final pattern = RegExp(".{1,800}");

  pattern.allMatches(s).forEach((match) {
    final m = match.group(0);

    if (m != null) {
      print(m);
    }
  });
}

int get unixTime => DateTime.now().millisecondsSinceEpoch ~/ 1000;
