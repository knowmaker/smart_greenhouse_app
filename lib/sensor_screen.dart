import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class SensorScreen extends StatefulWidget {
  @override
  SensorScreenState createState() => SensorScreenState();
}

class SensorScreenState extends State<SensorScreen> {
  Map<String, dynamic> sensorData = {
    'airT': 0,
    'airH': 0,
    'soilM1': 0,
    'soilM2': 0,
    'waterT': 0,
    'level': 0,
    'light': 0,
  };

  String lastUpdate = "Никогда";

  @override
  void initState() {
    super.initState();
    fetchSensorData();
  }

  Future<void> fetchSensorData() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('access_token');

    if (token == null || token.isEmpty) {
      _showAuthDialog();
      return;
    }

    final url = Uri.parse('http://alexandergh2023.tplinkdns.com/sensor-readings/0000BFE7');
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
        final readings = data['latest_readings'] as List;

        // Обновляем данные сенсоров, сопоставляя id_sensor с ожидаемыми показаниями
        setState(() {
          for (var reading in readings) {
            final id = reading['id_sensor'];
            final value = reading['value'];
            switch (id) {
              case 1:
                sensorData['airT'] = value ?? 0;
              case 2:
                sensorData['airH'] = value ?? 0;
              case 3:
                sensorData['soilM1'] = value ?? 0;
              case 4:
                sensorData['soilM2'] = value ?? 0;
              case 5:
                sensorData['waterT'] = value ?? 0;
              case 6:
                sensorData['level'] = value ?? 0;
              case 7:
                sensorData['light'] = value ?? 0;

            }
          }

          final now = DateTime.now();
          lastUpdate =
              "${now.day.toString().padLeft(2, '0')}.${now.month.toString().padLeft(2, '0')}.${now.year} ${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}:${now.second.toString().padLeft(2, '0')}";
        });
      } else {
        print('Failed to load sensor data: ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching sensor data: $e');
    }
  }

  void _showAuthDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Необходима авторизация'),
          content: Text('Для получения данных сенсоров необходимо авторизоваться.'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context); // Просто скрываем окно
              },
              child: Text('OK'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: fetchSensorData,
      color: Colors.purple,
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
                buildSensorCard(
                    'Температура воздуха', sensorData['airT'], '°C', Icons.thermostat),
                buildSensorCard(
                    'Влажность воздуха', sensorData['airH'], '%', Icons.water_drop),
                buildSensorCard(
                    'Влажность почвы грядки 1', sensorData['soilM1'], '%', Icons.grass),
                buildSensorCard(
                    'Влажность почвы грядки 2', sensorData['soilM2'], '%', Icons.grass),
                buildSensorCard(
                    'Температура\nводы', sensorData['waterT'], '°C', Icons.opacity),
                buildSensorCard(
                    'Уровень\nводы', sensorData['level'], '/ 3', Icons.water),
                buildLightSensorCard('Освещенность', sensorData['light']),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget buildSensorCard(String title, dynamic value, String unit, IconData icon) {
    return Card(
      elevation: 6,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.green[300]!, Colors.green[500]!],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 48,
                color: Colors.white,
              ),
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
              Text(
                '$value $unit',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget buildLightSensorCard(String title, int lightValue) {
    IconData icon = lightValue == 0 ? Icons.wb_sunny : Icons.nights_stay;
    String label = lightValue == 0 ? 'Светло' : 'Темно';

    return Card(
      elevation: 6,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.green[300]!, Colors.green[500]!],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 48,
                color: Colors.white,
              ),
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
              Text(
                label,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
