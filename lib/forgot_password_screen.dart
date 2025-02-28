import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class ForgotPasswordScreen extends StatefulWidget {
  @override
  ForgotPasswordScreenState createState() => ForgotPasswordScreenState();
}

class ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final TextEditingController _emailController = TextEditingController();
  String? _hashCode;
  String? _savedEmail;
  bool _isLoading = false;
  bool _isEmailValid = false;
  bool _emailTouched = false;

  void _validateEmail(String value) {
    setState(() {
      _emailTouched = true;
      _isEmailValid = RegExp(r"^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$").hasMatch(value);
    });
  }

  Future<void> _sendResetRequest() async {
    setState(() {
      _isLoading = true;
    });

    final url = Uri.parse('${dotenv.env['API_BASE_URL']}/users/forgot-password');

    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'email': _emailController.text,
        }),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        _hashCode = data['hash_code'];

        _savedEmail = _emailController.text;
        _emailController.clear();

        if (mounted) {
          Fluttertoast.showToast(
            msg: "Код смены пароля выслан на почту",
            toastLength: Toast.LENGTH_LONG,
            gravity: ToastGravity.TOP,
            backgroundColor: Colors.green,
            textColor: Colors.white,
          );
          _showResetDialog();
        }
      } else {
        final errorDetail = json.decode(response.body)['detail'] ?? 'Ошибка';
        Fluttertoast.showToast(
          msg: "Ошибка: $errorDetail",
          toastLength: Toast.LENGTH_LONG,
          backgroundColor: Colors.red,
          textColor: Colors.white,
        );
      }
    } catch (e) {
      Fluttertoast.showToast(
        msg: "Ошибка сервера",
        toastLength: Toast.LENGTH_LONG,
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

  void _showResetDialog() {
    final TextEditingController codeController = TextEditingController();
    final TextEditingController newPasswordController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text("Введите код и новый пароль"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
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
              SizedBox(height: 10),
              TextField(
                controller: newPasswordController,
                decoration: InputDecoration(
                  labelText: "Новый пароль",
                  border: OutlineInputBorder(),
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.grey, width: 2.0),
                  ),
                ),
                obscureText: true,
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
                await _resetPassword(codeController.text, newPasswordController.text);
              },
              child: Text("Сбросить пароль"),
            ),
          ],
        );
      },
    );
  }

  Future<void> _resetPassword(String code, String newPassword) async {
    final url = Uri.parse('${dotenv.env['API_BASE_URL']}/users/reset-password');

    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'email': _savedEmail,
          'entered_code': code,
          'received_hash': _hashCode,
          'new_password': newPassword,
        }),
      );

      if (response.statusCode == 200) {
        if (mounted) {
          Fluttertoast.showToast(
            msg: "Пароль успешно изменен",
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      appBar: AppBar(title: Text("Восстановление пароля")),
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
              controller: _emailController,
              decoration: InputDecoration(
                labelText: 'Email',
                border: OutlineInputBorder(),
                enabledBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: Colors.black, width: 2.0),
                ),
                errorText: _emailTouched && !_isEmailValid ? 'Некорректный email' : null,
              ),
              onChanged: _validateEmail,
            ),
            SizedBox(height: 24),
            _isLoading
                ? CircularProgressIndicator()
                : ElevatedButton(
                  onPressed: _isEmailValid
                        ? _sendResetRequest
                        : null,
                  style: ElevatedButton.styleFrom(
                    foregroundColor: Colors.white,
                    backgroundColor: Colors.green,
                    padding: EdgeInsets.symmetric(vertical: 16.0, horizontal: 32.0),
                    textStyle: TextStyle(fontSize: 18),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8.0),
                    ),
                  ),
                  child: Text("Отправить запрос")
                ),
          ],
        ),
      ),
    );
  }
}
