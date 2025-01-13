import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'package:fluttertoast/fluttertoast.dart';

typedef OnGreenhouseBound = void Function(String guid);

class UserGreenhouseModule extends StatelessWidget {
  final String? guid;
  final OnGreenhouseBound onGreenhouseBound;

  UserGreenhouseModule({required this.guid, required this.onGreenhouseBound});

  Future<void> _bindGreenhouse(BuildContext context) async {
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
                await _sendBindRequest(context, guid, pin);
              },
              child: Text('Привязать'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _sendBindRequest(BuildContext context, String guid, String pin) async {
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
      onGreenhouseBound(guid);
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

  Future<void> _saveGreenhouseGUID(String guid) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('greenhouse_guid', guid);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(10),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.black),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        children: [
          if (guid != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 8.0),
              child: Text(
                'GUID: $guid',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
          IconButton(
            icon: Icon(Icons.add_circle, size: 30, color: Colors.green),
            onPressed: () => _bindGreenhouse(context),
          ),
        ],
      ),
    );
  }
}
