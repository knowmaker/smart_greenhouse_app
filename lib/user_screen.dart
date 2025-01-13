import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'package:fluttertoast/fluttertoast.dart';
import 'login_screen.dart';

class UserScreen extends StatefulWidget {
  @override
  _UserScreenState createState() => _UserScreenState();
}

class _UserScreenState extends State<UserScreen> {
  bool _isLoggedIn = false;
  String? _guid; // Храним GUID теплицы

  @override
  void initState() {
    super.initState();
    _checkLoginStatus();
    _loadGreenhouseGUID();
  }

  Future<void> _checkLoginStatus() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('access_token');
    if (mounted) {
      setState(() {
        _isLoggedIn = token != null && token.isNotEmpty;
      });
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

  Future<void> _saveGreenhouseGUID(String guid) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('greenhouse_guid', guid);
    setState(() {
      _guid = guid;
    });
  }

  Future<void> _bindGreenhouse() async {
    String guid = '';
    String pin = '';

    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Привязать теплицу'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                onChanged: (value) => guid = value,
                decoration: InputDecoration(labelText: 'GUID'),
              ),
              TextField(
                onChanged: (value) => pin = value,
                decoration: InputDecoration(labelText: 'PIN'),
                obscureText: true,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Отмена'),
            ),
            TextButton(
              onPressed: () async {
                Navigator.pop(context);
                await _sendBindRequest(guid, pin);
              },
              child: Text('Привязать'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _sendBindRequest(String guid, String pin) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('access_token');

    final response = await http.patch(
      Uri.parse('http://alexandergh2023.tplinkdns.com/greenhouses/bind'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: '{"guid": "$guid", "pin": "$pin"}',
    );

    if (response.statusCode == 200) {
      await _saveGreenhouseGUID(guid);
      Fluttertoast.showToast(
        msg: "Теплица успешно привязана!",
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.TOP,
        backgroundColor: Colors.green,
        textColor: Colors.white,
      );
    } else {
      Fluttertoast.showToast(
        msg: "Ошибка: ${response.body}",
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

  @override
  Widget build(BuildContext context) {
    return Center(
      child: _isLoggedIn
          ? Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.account_circle, size: 100, color: Colors.green),
                SizedBox(height: 20),
                Text(
                  'Добро пожаловать!',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 10),
                ElevatedButton(
                  onPressed: _logout,
                  child: Text('Выйти из аккаунта'),
                ),
                SizedBox(height: 20),
                Container(
                  padding: EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.black),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Column(
                    children: [
                      if (_guid != null)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 8.0),
                          child: Text(
                            'GUID: $_guid',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                        ),
                      IconButton(
                        icon: Icon(Icons.add_circle, size: 30, color: Colors.green),
                        onPressed: _bindGreenhouse,
                      ),
                    ],
                  ),
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
