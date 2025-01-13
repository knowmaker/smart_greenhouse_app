import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'package:fluttertoast/fluttertoast.dart';
import 'user_gh_module.dart'; // Импорт нового модуля
import 'login_screen.dart';
import 'dart:convert';

class UserScreen extends StatefulWidget {
  @override
  UserScreenState createState() => UserScreenState();
}

class UserScreenState extends State<UserScreen> {
  bool _isLoggedIn = false;
  String? _guid;
  String? _email; // Email пользователя
  String? _firstName; // Имя пользователя
  String? _lastName; // Фамилия пользователя

  @override
  void initState() {
    super.initState();
    _checkLoginStatus();
    _loadGreenhouseGUID();
  }

  Future<void> _checkLoginStatus() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('access_token');
    if (token != null && token.isNotEmpty) {
      await _fetchUserData(); // Загружаем данные пользователя
      if (mounted) {
        setState(() {
          _isLoggedIn = true;
        });
      }
    }
  }

  Future<void> _loadGreenhouseGUID() async {
    final prefs = await SharedPreferences.getInstance();
    if (mounted) {
      setState(() {
        _guid = prefs.getString('greenhouse_guid');
      });
    }
  }

  Future<void> _fetchUserData() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('access_token');

    final response = await http.get(
      Uri.parse('http://alexandergh2023.tplinkdns.com/users/me'),
      headers: {
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      final data = Map<String, dynamic>.from(json.decode(response.body));

      if (mounted) {
        setState(() {
          _email = data['email'];
          _firstName = data['first_name'];
          _lastName = data['last_name'];
        });
      }
    } else {
      Fluttertoast.showToast(
        msg: "Ошибка при загрузке данных пользователя: ${response.statusCode}",
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.TOP,
        backgroundColor: Colors.red,
        textColor: Colors.white,
      );
    }
  }

  Future<void> _logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('access_token');
    if (mounted) {
      setState(() {
        _isLoggedIn = false;
        _guid = null;
        _email = null;
        _firstName = null;
        _lastName = null;
      });
    }
    Fluttertoast.showToast(
      msg: "Вы вышли из аккаунта",
      toastLength: Toast.LENGTH_SHORT,
      gravity: ToastGravity.TOP,
      backgroundColor: Colors.black,
      textColor: Colors.white,
    );
  }

  void _onGreenhouseBound(String guid) {
    setState(() {
      _guid = guid;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: _isLoggedIn
          ? Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.account_circle, size: 100, color: Colors.green),
                SizedBox(height: 20),
                if (_firstName != null && _lastName != null)
                  Text(
                    'Добро пожаловать, $_firstName $_lastName!',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                if (_email != null)
                  Text(
                    'Email: $_email',
                    style: TextStyle(fontSize: 16),
                  ),
                SizedBox(height: 10),
                ElevatedButton(
                  onPressed: _logout,
                  child: Text('Выйти из аккаунта'),
                ),
                SizedBox(height: 20),
                UserGreenhouseModule(
                  guid: _guid,
                  onGreenhouseBound: _onGreenhouseBound,
                ),
              ],
            )
          : Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.account_circle, size: 100, color: Colors.grey),
                SizedBox(height: 20),
                Text(
                  'Вы не авторизованы',
                  style: TextStyle(fontSize: 18),
                ),
                SizedBox(height: 10),
                ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => LoginScreen()),
                    );
                  },
                  child: Text('Войти'),
                ),
              ],
            ),
    );
  }
}
