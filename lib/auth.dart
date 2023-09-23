import "dart:convert";
import "dart:developer";

import "package:flutter_secure_storage/flutter_secure_storage.dart";
import "package:http/http.dart" as http;

const String malClientId = "688adc65bbae7a2517e8d8ed7cff8c28";
// const String _malApiBaseUrl = 'https://api.myanimelist.net/v2';

class MalToken {
  MalToken._(this.accessToken, this.expirationTime);
  static MalToken? _instance;
  String accessToken;
  int expirationTime;

  bool isValid() {
    return accessToken.isNotEmpty &&
        expirationTime > 0 &&
        DateTime.now().millisecondsSinceEpoch < expirationTime;
  }

  static Future<MalToken?> getInstance() async {
    if (_instance == null) {
      const storage = FlutterSecureStorage();

      final accessToken = await storage.read(key: "access_token");
      final expirationTime = await storage.read(key: "expiration_time");

      if (accessToken == null || expirationTime == null) {
        return null;
      }

      _instance = MalToken._(accessToken, int.parse(expirationTime));
    }

    if (!_instance!.isValid()) {
      await _instance!.refresh();
    }

    return _instance;
  }

  Future<void> set(Map<String, dynamic> token) async {
    const storage = FlutterSecureStorage();
    await storage.write(key: "access_token", value: token["access_token"]);
    await storage.write(
      key: "expiration_time",
      value: token["expiration_time"].toString(),
    );
    await storage.write(key: "refresh_token", value: token["refresh_token"]);

    _instance = MalToken._(
      token["access_token"],
      token["expiration_time"],
    );
  }

  Future<void> refresh() async {
    log("refreshing token...");

    const storage = FlutterSecureStorage();
    final refresh = await storage.read(key: "refresh_token");

    if (refresh == null) {
      return;
    }

    try {
      final response = await http.post(
        Uri.parse("https://myanimelist.net/v1/oauth2/token"),
        headers: {
          "Content-Type": "application/x-www-form-urlencoded",
        },
        body:
            "grant_type=refresh_token&refresh_token=$refresh&client_id=$malClientId",
      );

      log({"refreshResponse": response.body}.toString());

      final json = jsonDecode(response.body);

      final expirationTime =
          DateTime.now().millisecondsSinceEpoch + json["expires_in"] * 1000;

      json["expiration_time"] = expirationTime;

      await _instance?.set(json);
    } catch (e) {
      log("Failed to refresh token: $e");
    }
  }
}
