import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class ControlScreen extends StatefulWidget {
  @override
  ControlScreenState createState() => ControlScreenState();
}

class ControlScreenState extends State<ControlScreen> {
  Map<String, bool> controlState = {
    'ventilation': false,
    'watering1': false,
    'watering2': false,
    'lighting': false,
  };

  String lastUpdate = "Никогда";

  @override
  void initState() {
    super.initState();
    _loadLastUpdate();
    fetchControlState();
  }

  Future<void> _loadLastUpdate() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      lastUpdate = prefs.getString('last_control_update') ?? "Никогда";
    });
  }

  Future<void> _saveLastUpdate(String date) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('last_control_update', date);
  }

  Future<void> fetchControlState({bool manualRefresh = false}) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('access_token');

    if (token == null || token.isEmpty) {
      print(manualRefresh);
      if (manualRefresh) {
        _showAuthDialog();
      }
      return;
    }

    final url = Uri.parse('http://alexandergh2023.tplinkdns.com/device-states/0000BFE7');
    try {
      final response = await http.get(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final deviceStates = data['latest_device_states'] as List;

        setState(() {
          for (var deviceState in deviceStates) {
            final id = deviceState['id_device'];
            final state = deviceState['state'];
            switch (id) {
              case 1:
                controlState['ventilation'] = state ?? false;
              case 2:
                controlState['watering1'] = state ?? false;
              case 3:
                controlState['watering2'] = state ?? false;
              case 4:
                continue;
              case 5:
                controlState['lighting'] = state ?? false;
            }
          }

          final now = DateTime.now();
          lastUpdate =
              "${now.day.toString().padLeft(2, '0')}.${now.month.toString().padLeft(2, '0')}.${now.year} ${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}:${now.second.toString().padLeft(2, '0')}";
          _saveLastUpdate(lastUpdate);
        });
      } else {
        print('Failed to fetch control state: ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching control state: $e');
    }
  }

  void _showAuthDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Необходима авторизация'),
          content: Text('Для управления устройствами необходимо авторизоваться.'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context); // Просто скрываем окно
              },
              style: TextButton.styleFrom(
                foregroundColor: Colors.purple,
              ),
              child: Text('OK'),
            ),
          ],
        );
      },
    );
  }

  Future<void> updateControlState(String controlName, bool state) async {

    final url = Uri.parse('http://alexandergh2023.tplinkdns.com/device-states/0000BFE7/control/$controlName/${state ? '1' : '0'}');
    try {
      final response = await http.post(url);
      if (response.statusCode == 200) {
        print('$controlName updated to ${state ? 'ON' : 'OFF'}');
      } else {
        print('Failed to update $controlName: ${response.statusCode}');
      }
    } catch (e) {
      print('Error updating control state for $controlName: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: () => fetchControlState(manualRefresh: true),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Последнее обновление: $lastUpdate',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
          ),
          Expanded(
            child: GridView.count(
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              padding: EdgeInsets.all(16.0),
              children: [
                buildControlCard('Проветривание', 'ventilation', Icons.air),
                buildControlCard('Освещение', 'lighting', Icons.light_sharp),
                buildControlCard('Полив грядки 1', 'watering1', Icons.opacity),
                buildControlCard('Полив грядки 2', 'watering2', Icons.opacity),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget buildControlCard(String title, String controlName, IconData icon) {
    return Card(
      elevation: 6,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.purple[300]!, Colors.purple[500]!],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 48, color: Colors.white),
            SizedBox(height: 8),
            Text(
              title,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 8),
            Switch(
              value: controlState[controlName] ?? false,
              activeColor: Colors.white, // Цвет ползунка, когда включён
              activeTrackColor: Colors.green, // Цвет трека, когда включён
              inactiveThumbColor: Colors.grey, // Цвет ползунка, когда выключен
              inactiveTrackColor: Colors.grey.shade300, // Цвет трека, когда выключен
              onChanged: (bool value) async {
                final prefs = await SharedPreferences.getInstance();
                final token = prefs.getString('access_token');

                if (token == null || token.isEmpty) {
                  _showAuthDialog();
                  return;
                }
                setState(() {
                  controlState[controlName] = value;
                });
                updateControlState(controlName, value);
              },
            ),
          ],
        ),
      ),
    );
  }
}
