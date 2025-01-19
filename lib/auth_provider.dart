import 'package:shared_preferences/shared_preferences.dart';

class GlobalAuth {
  static bool isLoggedIn = false;

  static Future<void> initialize() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('access_token');
    isLoggedIn = token != null && token.isNotEmpty;
  }

  // static Future<void> login(String token) async {
  //   final prefs = await SharedPreferences.getInstance();
  //   await prefs.setString('access_token', token);
  //   isLoggedIn = true;
  // }

  static Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    isLoggedIn = false;
  }
}
