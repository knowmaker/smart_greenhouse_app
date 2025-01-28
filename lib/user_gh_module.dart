import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'package:fluttertoast/fluttertoast.dart';
import 'dart:convert';

class UserGreenhouseModule extends StatefulWidget {
  final Future<void> Function() onUpdate;

  UserGreenhouseModule({required this.onUpdate});
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

    if (token == null) return;

    try {
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
        final errorDetail = json.decode(response.body)['detail'] ?? 'Неизвестная ошибка';
        Fluttertoast.showToast(
          msg: "Ошибка при загрузке теплиц: $errorDetail",
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

    try {
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
        await widget.onUpdate();
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
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.TOP,
        backgroundColor: Colors.yellow,
        textColor: Colors.black,
      );
    }
  }

  Future<void> _editGreenhouse(BuildContext context, Map<String, String> greenhouse) async {
    String newTitle = greenhouse['title']!;

    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Редактировать теплицу'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                onChanged: (value) => newTitle = value,
                controller: TextEditingController(text: greenhouse['title']),
                decoration: InputDecoration(
                  labelText: 'Название теплицы',
                  border: OutlineInputBorder(),
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.grey, width: 2.0),
                  ),
                ),
              ),
            ],
          ),
          actions: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text('Отмена', style: TextStyle(color: Colors.black)),
                ),
                TextButton(
                  onPressed: () async {
                    Navigator.pop(context);
                    await _unbindGreenhouse(context, greenhouse['guid']!);
                  },
                  child: Text('Отвязать', style: TextStyle(color: Colors.red)),
                ),
                TextButton(
                  onPressed: () async {
                    Navigator.pop(context);
                    await _updateGreenhouseTitle(greenhouse['guid']!, newTitle);
                  },
                  child: Text('Сохранить'),
                ),
              ],
            )
          ],
        );
      },
    );
  }

  Future<void> _updateGreenhouseTitle(String guid, String newTitle) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('access_token');

    try {
      final response = await http.patch(
        Uri.parse('http://alexandergh2023.tplinkdns.com/greenhouses/$guid'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode({
          'title': newTitle,
        }),
      );

      if (response.statusCode == 200) {
        Fluttertoast.showToast(
          msg: "Название теплицы обновлено!",
          toastLength: Toast.LENGTH_SHORT,
          gravity: ToastGravity.TOP,
          backgroundColor: Colors.green,
          textColor: Colors.white,
        );
        await _fetchGreenhouses();
        await widget.onUpdate();
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
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.TOP,
        backgroundColor: Colors.yellow,
        textColor: Colors.black,
      );
    }
  }

  Future<void> _unbindGreenhouse(BuildContext context, String guid) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('access_token');

    try {
      final response = await http.patch(
        Uri.parse('http://alexandergh2023.tplinkdns.com/greenhouses/unbind'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: '{"guid": "$guid"}',
      );

      if (response.statusCode == 200) {
        Fluttertoast.showToast(
          msg: "Теплица успешно отвязана!",
          toastLength: Toast.LENGTH_SHORT,
          gravity: ToastGravity.TOP,
          backgroundColor: Colors.green,
          textColor: Colors.white,
        );
        await prefs.remove('selected_greenhouse_guid');
        await _fetchGreenhouses();
        await widget.onUpdate();
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
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.TOP,
        backgroundColor: Colors.yellow,
        textColor: Colors.black,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: MediaQuery.of(context).size.width * 0.92,
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
                padding: const EdgeInsets.symmetric(vertical: 6.0),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        '$index. ${greenhouse['title']} (${greenhouse['guid']})',
                        style: TextStyle(fontSize: 16),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      ),
                    ),
                    IconButton(
                      icon: Icon(Icons.edit, size: 20, color: Colors.blue),
                      onPressed: () => _editGreenhouse(context, greenhouse),
                      padding: EdgeInsets.zero,
                      constraints: BoxConstraints(),
                      style: const ButtonStyle(
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                    ),
                  ],
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
