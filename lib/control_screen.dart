import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

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
    fetchControlState();
  }

  Future<void> fetchControlState() async {
    final url = Uri.parse('http://alexandergh2023.tplinkdns.com/api/st/get');
    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          controlState = {
            'ventilation': data['vSt'] == 1,
            'watering1': data['wSt1'] == 1,
            'watering2': data['wSt2'] == 1,
            'lighting': data['lSt'] == 1,
          };
          // Обновляем дату последнего обновления
          final now = DateTime.now();
          lastUpdate =
              "${now.day.toString().padLeft(2, '0')}.${now.month.toString().padLeft(2, '0')}.${now.year} ${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}:${now.second.toString().padLeft(2, '0')}";
        });
      } else {
        print('Failed to fetch control state: ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching control state: $e');
    }
  }

  Future<void> updateControlState(String controlName, bool state) async {
    final url = Uri.parse('http://alexandergh2023.tplinkdns.com/api/c/$controlName/${state ? '1' : '0'}');
    try {
      final response = await http.get(url);
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
      onRefresh: fetchControlState,
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
                buildControlCard('Полив грядки 1', 'watering1', Icons.opacity),
                buildControlCard('Полив грядки 2', 'watering2', Icons.opacity),
                buildControlCard('Освещение', 'lighting', Icons.lightbulb),
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
              onChanged: (bool value) {
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
