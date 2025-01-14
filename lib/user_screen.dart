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
  String? _email;
  String? _firstName;
  String? _lastName;

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
      await _fetchUserData();
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

  Widget _buildInfoRow(IconData icon, String label, String? content) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: Colors.grey),
            SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                  SizedBox(height: 5),
                  Text(
                    content ?? '-',
                    style: TextStyle(fontSize: 16, color: Colors.black),
                  ),
                ],
              ),
            ),
          ],
        ),
        Divider(color: Colors.grey[300]),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: _isLoggedIn
            ? SingleChildScrollView(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: double.infinity,
                      padding: EdgeInsets.symmetric(vertical: 20),
                      color: Colors.green[300],
                      child: Center(
                        child: CircleAvatar(
                          radius: 50,
                          backgroundColor: Colors.grey[300],
                          child: Icon(Icons.person, size: 50, color: Colors.grey[700]),
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        children: [
                          _buildInfoRow(Icons.email, 'Email', _email),
                          _buildInfoRow(Icons.person, 'Имя', _firstName),
                          _buildInfoRow(Icons.person_outline, 'Фамилия', _lastName),
                        ],
                      ),
                    ),
                    if (_guid != null)
                      UserGreenhouseModule(
                        guid: _guid,
                        onGreenhouseBound: _onGreenhouseBound,
                      ),
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: ElevatedButton(
                        onPressed: _logout,
                        child: Text('Выйти из аккаунта'),
                      ),
                    ),
                  ],
                ),
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
      ),
    );
  }
}
