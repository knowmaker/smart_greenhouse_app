import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'login_screen.dart';
import 'auth_provider.dart';

class ControlScreen extends StatefulWidget {
  final Map<String, String>? greenhouse;
  final Future<void> Function() onLoadGreenhouses;

  ControlScreen({required this.greenhouse, required this.onLoadGreenhouses});

  @override
  ControlScreenState createState() => ControlScreenState();
}

class ControlScreenState extends State<ControlScreen> {
  Map<String, bool?> controlState = {
    'ventilation': null,
    'watering1': null,
    'watering2': null,
    'lighting': null,
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
  void didUpdateWidget(ControlScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.greenhouse != oldWidget.greenhouse) {
      loadSelectedGreenhouse();
    }
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

  Future<void> loadSelectedGreenhouse() async {
    final prefs = await SharedPreferences.getInstance();
    final guid = prefs.getString('selected_greenhouse_guid');
    setState(() {
      selectedGreenhouseGuid = guid;
    });
    if (GlobalAuth.isLoggedIn && guid != null) {
      fetchControlState();
    }
  }

  Future<void> fetchControlState() async {
    if (!GlobalAuth.isLoggedIn || selectedGreenhouseGuid == null) return;

    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('access_token');
    final url = Uri.parse('http://alexandergh2023.tplinkdns.com/device-states/$selectedGreenhouseGuid');

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
          if (deviceStates.isEmpty) {
            controlState.updateAll((key, value) => null);
          } else {
            for (var deviceState in deviceStates) {
              final label = deviceState['device_label'];
              final state = deviceState['state'];
              controlState[label] = state;
            }

            final now = DateTime.now();
            lastUpdate =
                "${now.day.toString().padLeft(2, '0')}.${now.month.toString().padLeft(2, '0')}.${now.year} ${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}:${now.second.toString().padLeft(2, '0')}";
            _saveLastUpdate(lastUpdate);
          }
        });
      } else {
        setState(() {
          controlState.updateAll((key, value) => null);
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

  Future<void> updateControlState(String controlName, bool state) async {
    if (!GlobalAuth.isLoggedIn || selectedGreenhouseGuid == null) return;

    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('access_token');
    final url = Uri.parse(
        'http://alexandergh2023.tplinkdns.com/device-states/$selectedGreenhouseGuid/control/$controlName/${state ? '1' : '0'}');
    try {
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );
      if (response.statusCode == 200) {
        Fluttertoast.showToast(
            msg: "Команда управления отправлена",
            toastLength: Toast.LENGTH_LONG,
            gravity: ToastGravity.TOP,
            backgroundColor: Colors.green,
            textColor: Colors.white,
        );
      } else {
        final errorDetail = json.decode(response.body)['detail'] ?? 'Неизвестная ошибка';
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
    final state = controlState[controlName];
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
        padding: const EdgeInsets.all(6),
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
            SizedBox(
              height: 40,
              child: state == null
                  ? Center(
                      child: Text(
                        '-',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    )
                  : Switch(
                      value: state,
                      activeColor: Colors.white,
                      activeTrackColor: Colors.green,
                      inactiveThumbColor: Colors.grey,
                      inactiveTrackColor: Colors.grey.shade300,
                      onChanged: (bool value) {
                        setState(() {
                          controlState[controlName] = value;
                        });
                        updateControlState(controlName, value);
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
