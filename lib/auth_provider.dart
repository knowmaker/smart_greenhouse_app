import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:http/http.dart' as http;
import 'package:fluttertoast/fluttertoast.dart';

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

  static Future<void> sendFcmTokenToServer(String token) async {
    final fcmToken = await FirebaseMessaging.instance.getToken();
    if (fcmToken == null) return;

    try {
      await http.put(
        Uri.parse('http://alexandergh2023.tplinkdns.com/users/fcm'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: json.encode({'fcm_token': fcmToken}),
      );
    } catch (e) {
      Fluttertoast.showToast(
        msg: "Ошибка сервера при отправке FCM токена",
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.BOTTOM,
        backgroundColor: Colors.yellow,
        textColor: Colors.black,
      );
    }
  }
}
