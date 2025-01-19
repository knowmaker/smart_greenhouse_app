import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'login_screen.dart';
import 'auth_provider.dart';

class SensorScreen extends StatefulWidget {
  final Map<String, String>? greenhouse;
  final Future<void> Function() onLoadGreenhouses;

  SensorScreen({required this.greenhouse, required this.onLoadGreenhouses});

  @override
  SensorScreenState createState() => SensorScreenState();
}

class SensorScreenState extends State<SensorScreen> {
  Map<String, dynamic> sensorData = {
    'airTemp': '-',
    'airHum': '-',
    'soilMoist1': '-',
    'soilMoist2': '-',
    'waterTemp': '-',
    'waterLevel': '-',
    'light': '-',
  };

  String lastUpdate = "Никогда";
  String? selectedGreenhouseGuid;

  @override
  void initState() {
    super.initState();
    _loadLastUpdate();
    GlobalAuth.initialize();
    loadSelectedGreenhouse();
  }

  @override
  void didUpdateWidget(SensorScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.greenhouse != oldWidget.greenhouse) {
      loadSelectedGreenhouse();
    }
  }

  Future<void> _loadLastUpdate() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      lastUpdate = prefs.getString('last_sensor_update') ?? "Никогда";
    });
  }

  Future<void> _saveLastUpdate(String date) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('last_sensor_update', date);
  }

  Future<void> loadSelectedGreenhouse() async {
    final prefs = await SharedPreferences.getInstance();
    final guid = prefs.getString('selected_greenhouse_guid');
    setState(() {
      selectedGreenhouseGuid = guid;
    });
    if (GlobalAuth.isLoggedIn && guid != null) {
      fetchSensorData();
    }
  }

  Future<void> fetchSensorData() async {
    if (!GlobalAuth.isLoggedIn || selectedGreenhouseGuid == null) return;

    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('access_token');
    final url = Uri.parse('http://alexandergh2023.tplinkdns.com/sensor-readings/$selectedGreenhouseGuid');

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

        if (readings.isEmpty) {
          setState(() {
            sensorData = sensorData.map((key, value) => MapEntry(key, '-'));
          });
        } else {
          setState(() {
            for (var reading in readings) {
              final label = reading['sensor_label'];
              final value = reading['value'] ?? '-';
              sensorData[label] = value;
            }

            final now = DateTime.now();
            lastUpdate =
                "${now.day.toString().padLeft(2, '0')}.${now.month.toString().padLeft(2, '0')}.${now.year} ${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}:${now.second.toString().padLeft(2, '0')}";
          _saveLastUpdate(lastUpdate);
          });
        }
      } else {
        setState(() {
          sensorData = sensorData.map((key, value) => MapEntry(key, '-'));
        });
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
    if (!GlobalAuth.isLoggedIn) {
      return Center(
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
              // Приветственное сообщение
              Text(
                'Добро пожаловать в Smart Greenhouse!',
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
              // Кнопка входа
              ElevatedButton(
                onPressed: () async {
                  await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => LoginScreen(onUpdate: widget.onLoadGreenhouses),
                    ),
                  );
                  GlobalAuth.initialize();
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
      );
    }

    if (selectedGreenhouseGuid == null) {
      return Center(
        child: Text(
          'Перейдите в профиль для привязки теплицы',
          style: TextStyle(
            fontSize: 20,
            fontStyle: FontStyle.italic,
            color: Colors.grey,
          ),
          textAlign: TextAlign.center,
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: loadSelectedGreenhouse,
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
                    'Температура воздуха', sensorData['airTemp'], '°C', Icons.thermostat),
                buildSensorCard(
                    'Влажность воздуха', sensorData['airHum'], '%', Icons.water_drop),
                buildSensorCard(
                    'Влажность почвы грядки 1', sensorData['soilMoist1'], '%', Icons.grass),
                buildSensorCard(
                    'Влажность почвы грядки 2', sensorData['soilMoist2'], '%', Icons.grass),
                buildSensorCard(
                    'Температура\nводы', sensorData['waterTemp'], '°C', Icons.opacity),
                buildSensorCard(
                    'Уровень\nводы', sensorData['waterLevel'], '/ 3', Icons.water),
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

  Widget buildLightSensorCard(String title, dynamic lightValue) {
    IconData icon = lightValue == '-'
        ? Icons.wb_sunny
        : lightValue == 0
            ? Icons.wb_sunny
            : Icons.nights_stay;
    String label = lightValue == '-'
        ? '-'
        : lightValue == 0
            ? 'Светло'
            : 'Темно';

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
