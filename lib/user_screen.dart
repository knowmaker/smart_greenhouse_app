import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'package:fluttertoast/fluttertoast.dart';
import 'user_gh_module.dart';
import 'login_screen.dart';
import 'dart:convert';
import 'auth_provider.dart';

class UserScreen extends StatefulWidget {
  final Future<void> Function() onLoadGreenhouses;

  UserScreen({required this.onLoadGreenhouses});
  @override
  UserScreenState createState() => UserScreenState();
}

class UserScreenState extends State<UserScreen> {
  String? _email;
  String? _firstName;
  String? _lastName;

  String? _editingField;
  String? _newValue;


  @override
  void initState() {
    super.initState();
    GlobalAuth.initialize();
    _fetchUserData();
  }


  Future<void> _fetchUserData() async {
    if (!GlobalAuth.isLoggedIn) return;

    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('access_token');
    final url = Uri.parse('http://alexandergh2023.tplinkdns.com/users/me');

    try {
      final response = await http.get(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final data = Map<String, dynamic>.from(json.decode(response.body));

        setState(() {
          _email = data['email'];
          _firstName = data['first_name'];
          _lastName = data['last_name'];
        });
      } else {
        final errorDetail = json.decode(response.body)['detail'] ?? 'Неизвестная ошибка';
        Fluttertoast.showToast(
          msg: "Ошибка при загрузке данных пользователя: $errorDetail",
          toastLength: Toast.LENGTH_LONG,
          gravity: ToastGravity.TOP,
          backgroundColor: Colors.red,
          textColor: Colors.white,
        );
      }
    } catch (e) {
      Fluttertoast.showToast(
        msg: "Ошибка сервера",
        toastLength: Toast.LENGTH_LONG,
        gravity: ToastGravity.TOP,
        backgroundColor: Colors.yellow,
        textColor: Colors.black,
      );
    }
  }

  Future<void> _updateUserField(String field, String value) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('access_token');
    final url = Uri.parse('http://alexandergh2023.tplinkdns.com/users/update');

    try {
      final response = await http.patch(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode({field: value}),
      );

      if (response.statusCode == 200) {
        Fluttertoast.showToast(
          msg: "Данные успешно обновлены!",
          toastLength: Toast.LENGTH_SHORT,
          gravity: ToastGravity.TOP,
          backgroundColor: Colors.green,
          textColor: Colors.white,
        );
        setState(() {
          if (field == 'first_name') _firstName = value;
          if (field == 'last_name') _lastName = value;
          _editingField = null;
        });
      } else {
        final errorDetail = json.decode(response.body)['detail'] ?? 'Неизвестная ошибка';
        Fluttertoast.showToast(
          msg: "Ошибка: $errorDetail",
          toastLength: Toast.LENGTH_SHORT,
          gravity: ToastGravity.TOP,
          backgroundColor: Colors.red,
          textColor: Colors.white,
        );
      }
    } catch (e) {
      Fluttertoast.showToast(
        msg: "Ошибка сервера",
        toastLength: Toast.LENGTH_LONG,
        gravity: ToastGravity.TOP,
        backgroundColor: Colors.yellow,
        textColor: Colors.black,
      );
    }
  }


  Future<void> _logout() async {
    await GlobalAuth.logout();
    setState(() {
      _email = null;
      _firstName = null;
      _lastName = null;
    });
    Fluttertoast.showToast(
      msg: "Вы вышли из аккаунта",
      toastLength: Toast.LENGTH_LONG,
      gravity: ToastGravity.TOP,
      backgroundColor: Colors.green,
      textColor: Colors.white,
    );
    await widget.onLoadGreenhouses();
  }

  Widget _buildInfoRow(IconData icon, String label, String? content, String field) {
    final isEditing = _editingField == field;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: Colors.grey),
            SizedBox(width: 10),
            Expanded(
              child: isEditing
                  ? TextField(
                      autofocus: true,
                      onChanged: (value) => _newValue = value,
                      controller: TextEditingController(text: content),
                      decoration: InputDecoration(
                        border: UnderlineInputBorder(),
                        hintText: 'Введите новое значение',
                      ),
                    )
                  : Column(
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
            if (field.isNotEmpty)
              SizedBox(width: 10),
            if (field.isNotEmpty)
              IconButton(
                icon: Icon(isEditing ? Icons.check : Icons.edit,
                    color: isEditing ? Colors.green : Colors.grey),
                onPressed: () async {
                  if (isEditing && _newValue != null && _newValue!.trim().isNotEmpty) {
                    await _updateUserField(field, _newValue!.trim());
                  } else {
                    setState(() {
                      _editingField = isEditing ? null : field;
                      _newValue = content;
                    });
                  }
                },
              ),
          ],
        ),
        Divider(color: Colors.grey[300]),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!GlobalAuth.isLoggedIn) {
      return Scaffold(
        body: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Image.asset(
                  'images/smgh_logo.png',
                  width: 200,
                  height: 200,
                ),
                const SizedBox(height: 24),
                Text(
                  'Добро пожаловать\nв Smart Greenhouse!',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.green[800],
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'С помощью нашего приложения вы можете:\n\n'
                  '🌱 Следить за состоянием вашей теплицы\n'
                  '⚙️ Управлять оборудованием и настройками\n'
                  '🔔 Получать уведомления о важных событиях\n',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 16,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: () async {
                    await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => LoginScreen(onUpdate: widget.onLoadGreenhouses),
                      ),
                    );
                    await GlobalAuth.initialize();
                    _fetchUserData();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green[700],
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                    textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  child: const Text('Войти'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      body: SingleChildScrollView(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 20),
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
                  _buildInfoRow(Icons.email, 'Email', _email, ''),
                  _buildInfoRow(Icons.person, 'Имя', _firstName, 'first_name'),
                  _buildInfoRow(Icons.person_outline, 'Фамилия', _lastName, 'last_name'),
                ],
              ),
            ),
            Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Мои теплицы',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 10),
                  UserGreenhouseModule(onUpdate: widget.onLoadGreenhouses),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Center(
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                  ),
                  onPressed: _logout,
                  child: Text('Выйти из аккаунта'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
