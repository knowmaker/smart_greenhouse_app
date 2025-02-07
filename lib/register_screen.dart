import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class RegisterScreen extends StatefulWidget {
  @override
  RegisterScreenState createState() => RegisterScreenState();
}

class RegisterScreenState extends State<RegisterScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _firstNameController = TextEditingController();
  final TextEditingController _lastNameController = TextEditingController();

  String? _hashCode;
  bool _isLoading = false;

  Future<void> _register() async {
    setState(() {
      _isLoading = true;
    });

    final url = Uri.parse('${dotenv.env['API_BASE_URL']}/users/register');

    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'email': _emailController.text,
          'password': _passwordController.text,
          'last_name': _lastNameController.text,
          'first_name': _firstNameController.text,
        }),
      );

      if (response.statusCode == 201) {
        final data = json.decode(response.body);
        _hashCode = data['hash_code'];

        _emailController.clear();
        _passwordController.clear();
        _firstNameController.clear();
        _lastNameController.clear();

        if (mounted) {
          Fluttertoast.showToast(
            msg: "Регистрация успешна. Подтвердите почту",
            toastLength: Toast.LENGTH_LONG,
            gravity: ToastGravity.TOP,
            backgroundColor: Colors.green,
            textColor: Colors.white,
          );

          _showVerificationDialog();
        }
      } else {
        final errorDetail = json.decode(response.body)['detail'] ?? 'Неизвестная ошибка';
        Fluttertoast.showToast(
          msg: "Ошибка регистрации: $errorDetail",
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
    } finally {
        if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _showVerificationDialog({String? email}) {
    final TextEditingController codeController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text("Подтверждение email"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(height: 10),
              TextField(
                controller: codeController,
                decoration: InputDecoration(
                  labelText: "Код подтверждения",
                  border: OutlineInputBorder(),
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.grey, width: 2.0),
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text("Отмена", style: TextStyle(color: Colors.black)),
            ),
            TextButton(
              onPressed: () async {
                Navigator.pop(context);
                await _verifyEmail(codeController.text, email: email);
              },
              child: Text("Подтвердить"),
            ),
          ],
        );
      },
    );
  }

  Future<void> _verifyEmail(String code, {String? email}) async {
    final url = Uri.parse('${dotenv.env['API_BASE_URL']}/users/verify-email');

    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'email': email ?? _emailController.text,
          'entered_code': code,
          'received_hash': _hashCode,
        }),
      );

      if (response.statusCode == 200) {
        if (mounted) {
          Fluttertoast.showToast(
            msg: "Email подтверждён!",
            toastLength: Toast.LENGTH_LONG,
            gravity: ToastGravity.TOP,
            backgroundColor: Colors.green,
            textColor: Colors.white,
          );
          Navigator.pop(context);
        }
      } else {
        final errorDetail = json.decode(response.body)['detail'] ?? 'Ошибка';
        Fluttertoast.showToast(
          msg: "Ошибка: $errorDetail",
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

  Future<void> _resendVerificationCode() async {
    final TextEditingController emailController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text("Запрос нового кода"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(height: 10),
              TextField(
                controller: emailController,
                decoration: InputDecoration(
                  labelText: "Email",
                  border: OutlineInputBorder(),
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.grey, width: 2.0),
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text("Отмена", style: TextStyle(color: Colors.black)),
            ),
            TextButton(
              onPressed: () async {
                Navigator.pop(context);
                await _requestNewCode(emailController.text);
              },
              child: Text("Запросить код"),
            ),
          ],
        );
      },
    );
  }

  Future<void> _requestNewCode(String email) async {
    final url = Uri.parse('${dotenv.env['API_BASE_URL']}/users/resend-verification-code');

    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'email': email}),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        _hashCode = data['hash_code'];

        Fluttertoast.showToast(
          msg: "Новый код отправлен!",
          toastLength: Toast.LENGTH_LONG,
          gravity: ToastGravity.TOP,
          backgroundColor: Colors.green,
          textColor: Colors.white,
        );

        _showVerificationDialog(email: email);
      } else {
        final errorDetail = json.decode(response.body)['detail'] ?? 'Ошибка';
        Fluttertoast.showToast(
          msg: "Ошибка: $errorDetail",
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      appBar: AppBar(title: Text('Регистрация')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Image.asset(
              'images/smgh_logo.png',
              width: 200,
              height: 200,
            ),
            SizedBox(height: 24),
            TextField(
              controller: _firstNameController,
              decoration: InputDecoration(
                labelText: 'Имя',
                border: OutlineInputBorder(),
                enabledBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: Colors.black, width: 2.0),
                ),
              )
            ),
            SizedBox(height: 20),
            TextField(
              controller: _lastNameController,
              decoration: InputDecoration(
                labelText: 'Фамилия',
                border: OutlineInputBorder(),
                enabledBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: Colors.black, width: 2.0),
                ),
              )
            ),
            SizedBox(height: 20),
            TextField(
              controller: _emailController,
              decoration: InputDecoration(
                labelText: 'Email',
                border: OutlineInputBorder(),
                enabledBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: Colors.black, width: 2.0),
                ),
              ),
            ),
            SizedBox(height: 20),
            TextField(
              controller: _passwordController,
              decoration: InputDecoration(
                labelText: 'Пароль',
                border: OutlineInputBorder(),
                enabledBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: Colors.black, width: 2.0),
                ),
              ),
              obscureText: true,
            ),
            SizedBox(height: 24),
            _isLoading
                ? CircularProgressIndicator()
                : ElevatedButton(
                  onPressed: _register,
                  style: ElevatedButton.styleFrom(
                    foregroundColor: Colors.white,
                    backgroundColor: Colors.green,
                    padding: EdgeInsets.symmetric(vertical: 16.0, horizontal: 32.0),
                    textStyle: TextStyle(fontSize: 18),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8.0),
                    ),
                  ),
                  child: Text('Зарегистрироваться')
                ),
            SizedBox(height: 10),
            TextButton(
              onPressed: () => _resendVerificationCode(),
              child: Text('Подтвердить почту', style: TextStyle(color: Colors.purple)),
            ),
          ],
        ),
      ),
    );
  }
}
