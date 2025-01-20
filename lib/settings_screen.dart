import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'login_screen.dart';
import 'auth_provider.dart';

class SettingsScreen extends StatefulWidget {
  final Map<String, String>? greenhouse;
  final Future<void> Function() onLoadGreenhouses;

  SettingsScreen({required this.greenhouse, required this.onLoadGreenhouses});

  @override
  SettingsScreenState createState() => SettingsScreenState();
}

class SettingsScreenState extends State<SettingsScreen> {
  Map<String, dynamic> settingData = {
    'airTempThreshold': '-',
    'airHumThreshold': '-',
    'soilMoistThreshold1': '-',
    'soilMoistThreshold2': '-',
    'waterTempThreshold1': '-',
    'waterTempThreshold2': '-',
    'waterLevelThreshold': '-',
    'lightThreshold': '-',
    'motionThreshold': '-',
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
  void didUpdateWidget(SettingsScreen oldWidget) {
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
      fetchSettingState();
    }
  }

  Future<void> fetchSettingState() async {
    if (!GlobalAuth.isLoggedIn || selectedGreenhouseGuid == null) return;

    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('access_token');
    final url = Uri.parse('http://alexandergh2023.tplinkdns.com/settings/$selectedGreenhouseGuid');

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
        final settings = data['latest_settings'] as List;

        setState(() {
          if (settings.isEmpty) {
            settingData = settingData.map((key, value) => MapEntry(key, '-'));
          } else {
            for (var setting in settings) {
              final label = setting['parameter_label'];
              final value = setting['value'];
              settingData[label] = value;
            }

            final now = DateTime.now();
            lastUpdate =
                "${now.day.toString().padLeft(2, '0')}.${now.month.toString().padLeft(2, '0')}.${now.year} ${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}:${now.second.toString().padLeft(2, '0')}";
            _saveLastUpdate(lastUpdate);
          }
        });
      } else {
        setState(() {
          settingData = settingData.map((key, value) => MapEntry(key, '-'));
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

  Future<void> updateSetting() async {
    final url = Uri.parse('http://alexandergh2023.tplinkdns.com/settings/$selectedGreenhouseGuid');
    try {
      final response = await http.post(url);
      if (response.statusCode == 200) {
        print('Настройки обновлены');
      } else {
        print('Ошибка обновления настроек');
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
            padding: const EdgeInsets.all(0),
            child: Align(
              alignment: Alignment.center,
              child: SizedBox(
                width: double.infinity,
                child: TextButton(
                  onPressed: updateSetting,
                  style: TextButton.styleFrom(
                    backgroundColor: Colors.lightGreenAccent,
                    foregroundColor: Colors.purple,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    shape: const RoundedRectangleBorder(),
                    textStyle: const TextStyle(
                      fontSize: 16,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                  child: const Text('Применить все изменения и сохранить'),
                ),
              ),
            ),
          ),
          Expanded(
            child: GridView.count(
              crossAxisCount: 1,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 2,
              padding: EdgeInsets.all(16.0),
              children: [
                buildSettingCard('Температура воздуха', settingData['airTempThreshold'], '°C',
                    Icons.thermostat, min: -10, max: 40),
                buildSettingCard('Влажность воздуха', settingData['airHumThreshold'], '%',
                    Icons.water_drop, min: 0, max: 100),
                buildSettingCard('Влажность почвы грядки 1', settingData['soilMoistThreshold1'], '%',
                    Icons.grass, min: 0, max: 100),
                buildSettingCard('Влажность почвы грядки 2', settingData['soilMoistThreshold2'], '%',
                    Icons.grass, min: 0, max: 100),
                buildSettingCard('Температура воды 1', settingData['waterTempThreshold1'], '°C',
                    Icons.opacity, min: 0, max: 50),
                buildSettingCard('Температура воды 2', settingData['waterTempThreshold2'], '°C',
                    Icons.opacity, min: 0, max: 50),
                buildSettingCard('Уровень воды', settingData['waterLevelThreshold'], '/ 3',
                    Icons.water, min: 0, max: 3),
                buildSettingCard('Освещенность', settingData['lightThreshold'], '%', Icons.light_mode,
                    min: 0, max: 1000),
                buildSettingCard('Движение', settingData['motionThreshold'], '', Icons.motion_photos_on,
                    min: 0, max: 1),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget buildSettingCard(String title, dynamic value, String unit, IconData icon, {required int min, required int max}) {
    // int currentValue = (value != '-' && value != null) ? int.tryParse(value.toString()) ?? min : min;

    return Card(
      elevation: 6,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.orange[300]!, Colors.orange[500]!],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Row(
              children: [
                Icon(icon, size: 48, color: Colors.white),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            SizedBox(height: 8),
            value != '-'
                ? Column(
                    children: [
                      Text(
                        "${value.toStringAsFixed(1)} $unit",
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      Slider(
                        value: value.toDouble(),
                        min: min.toDouble(),
                        max: max.toDouble(),
                        divisions: max - min,
                        activeColor: Colors.white,
                        inactiveColor: Colors.white54,
                        onChanged: (newValue) {
                          setState(() {
                            settingData[title] = newValue.toStringAsFixed(1);
                          });
                        },
                      ),
                    ],
                  )
                : Center(
                    child: Text(
                      '-',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
          ],
        ),
      ),
    );
  }
}
