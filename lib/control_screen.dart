import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
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
  Map<String, bool> controlState = {
    'ventilation': false,
    'watering1': false,
    'watering2': false,
    'lighting': false,
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

        if (deviceStates.isEmpty) {
          setState(() {
            controlState = controlState.map((key, value) => MapEntry(key, false));
          });
        } else {
          setState(() {
            for (var deviceState in deviceStates) {
              final label = deviceState['device_label'];
              final state = deviceState['state'];
              controlState[label] = state;
            }

            final now = DateTime.now();
            lastUpdate =
                "${now.day.toString().padLeft(2, '0')}.${now.month.toString().padLeft(2, '0')}.${now.year} ${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}:${now.second.toString().padLeft(2, '0')}";
          _saveLastUpdate(lastUpdate);
          });
        }
      } else {
        setState(() {
          controlState = controlState.map((key, value) => MapEntry(key, false));
        });
      }
    } catch (e) {
      print('Error fetching sensor data: $e');
    }
  }

  Future<void> updateControlState(String controlName, bool state) async {

    final url = Uri.parse('http://alexandergh2023.tplinkdns.com/device-states/$selectedGreenhouseGuid/control/$controlName/${state ? '1' : '0'}');
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
    if (!GlobalAuth.isLoggedIn) {
      return Center(
        child: ElevatedButton(
          onPressed: () async {
            await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => LoginScreen(
                  onUpdate: widget.onLoadGreenhouses,
                ),
              ),
            );
            GlobalAuth.initialize();
          },
          child: Text('Войти'),
        ),
      );
    }

    if (selectedGreenhouseGuid == null) {
      return Center(
        child: Text(
          'Перейдите в профиль для привязки теплицы.',
          style: TextStyle(
            fontSize: 16,
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
            controlState[controlName] == false
              ? Text(
                  '-',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                )
              : Switch(
                value: controlState[controlName] ?? false,
                activeColor: Colors.white, // Цвет ползунка, когда включён
                activeTrackColor: Colors.green, // Цвет трека, когда включён
                inactiveThumbColor: Colors.grey, // Цвет ползунка, когда выключен
                inactiveTrackColor: Colors.grey.shade300, // Цвет трека, когда выключен
                onChanged: (bool value){
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
