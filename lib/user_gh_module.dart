import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'package:fluttertoast/fluttertoast.dart';
import 'dart:convert';

class UserGreenhouseModule extends StatefulWidget {
  @override
  UserGreenhouseModuleState createState() => UserGreenhouseModuleState();
}

class UserGreenhouseModuleState extends State<UserGreenhouseModule> {
  List<Map<String, String>> _greenhouses = [];

  @override
  void initState() {
    super.initState();
    _fetchGreenhouses();
  }

  Future<void> _fetchGreenhouses() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('access_token');

    final response = await http.get(
      Uri.parse('http://alexandergh2023.tplinkdns.com/greenhouses/my'),
      headers: {
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body);

      setState(() {
        _greenhouses = data.map((item) {
          return {
            'guid': item['guid'] as String,
            'title': item['title'] as String,
          };
        }).toList();
      });
    } else {
      Fluttertoast.showToast(
        msg: "Ошибка при загрузке теплиц: ${response.statusCode}",
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.TOP,
        backgroundColor: Colors.red,
        textColor: Colors.white,
      );
    }
  }

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
                decoration: InputDecoration(
                    labelText: 'GUID',
                    border: OutlineInputBorder(),
                    enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.grey, width: 2.0),
                  ),
                ),
              ),
              SizedBox(height: 10),
              TextField(
                onChanged: (value) => pin = value,
                decoration: InputDecoration(
                    labelText: 'PIN',
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
      Fluttertoast.showToast(
        msg: "Теплица успешно привязана!",
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.TOP,
        backgroundColor: Colors.green,
        textColor: Colors.white,
      );
      await _fetchGreenhouses();
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

  @override
  Widget build(BuildContext context) {
    return Container(
      width: MediaQuery.of(context).size.width * 0.9, // Почти на всю ширину экрана
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.black),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (_greenhouses.isEmpty)
            Center(
              child: Text(
                'Нет привязанных теплиц',
                style: TextStyle(fontSize: 16, fontStyle: FontStyle.italic),
              ),
            )
          else
            ..._greenhouses.asMap().entries.map((entry) {
              final index = entry.key + 1;
              final greenhouse = entry.value;
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 4.0),
                child: Text(
                  '$index. ${greenhouse['title']} (${greenhouse['guid']})',
                  style: TextStyle(fontSize: 16),
                ),
              );
            }),
          Divider(color: Colors.grey),
          Center(
            child: IconButton(
              icon: Icon(Icons.add_circle, size: 30, color: Colors.green),
              onPressed: () => _bindGreenhouse(context),
            ),
          ),
        ],
      ),
    );
  }
}
