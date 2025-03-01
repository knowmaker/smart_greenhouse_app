import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:math';
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

  String? selectedGreenhouseGuid;
  Map<String, bool> flippedCards = {};

  final Map<String, Map<String, int>> predefinedCrops = {
    'Огурцы': {
      'airTempThreshold': 25,
      'airHumThreshold': 80,
      'soilMoistThreshold1': 60,
      'soilMoistThreshold2': 60,
      'waterTempThreshold1': 22,
      'waterTempThreshold2': 22,
      'waterLevelThreshold': 2,
      'lightThreshold': 800,
      'motionThreshold': 0,
    },
    'Помидоры': {
      'airTempThreshold': 22,
      'airHumThreshold': 75,
      'soilMoistThreshold1': 50,
      'soilMoistThreshold2': 50,
      'waterTempThreshold1': 20,
      'waterTempThreshold2': 20,
      'waterLevelThreshold': 2,
      'lightThreshold': 900,
      'motionThreshold': 0,
    },
    'Перец': {
      'airTempThreshold': 26,
      'airHumThreshold': 70,
      'soilMoistThreshold1': 55,
      'soilMoistThreshold2': 55,
      'waterTempThreshold1': 24,
      'waterTempThreshold2': 24,
      'waterLevelThreshold': 2,
      'lightThreshold': 850,
      'motionThreshold': 0,
    },
  };

  @override
  void initState() {
    super.initState();
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
    final url = Uri.parse('${dotenv.env['API_BASE_URL']}/settings/$selectedGreenhouseGuid');

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
    if (!GlobalAuth.isLoggedIn || selectedGreenhouseGuid == null) return;

    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('access_token');
    final url = Uri.parse('${dotenv.env['API_BASE_URL']}/settings/$selectedGreenhouseGuid');

    // Формируем список настроек для отправки
    final newSettings = settingData.entries.map((entry) {
      return {
        "parameter_label": entry.key,
        "value": entry.value,
      };
    }).toList();

    try {
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          "new_settings": newSettings,
        }),
      );

      if (response.statusCode == 200) {
        Fluttertoast.showToast(
          msg: "Настройки успешно обновлены",
          toastLength: Toast.LENGTH_LONG,
          gravity: ToastGravity.TOP,
          backgroundColor: Colors.green,
          textColor: Colors.white,
        );
      } else {
        Fluttertoast.showToast(
          msg: "Ошибка обновления настроек",
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
              mainAxisSpacing: 12,
              childAspectRatio: 2,
              padding: EdgeInsets.all(16.0),
              children: [
                buildSettingCard('Температура воздуха', 'airTempThreshold', '°C',
                    Icons.thermostat, min: 0, max: 80),
                buildSettingCard('Влажность воздуха', 'airHumThreshold', '%',
                    Icons.water_drop, min: 0, max: 100),
                buildSettingCard('Влажность почвы грядки 1', 'soilMoistThreshold1', '%',
                    Icons.grass, min: 0, max: 100),
                buildSettingCard('Влажность почвы грядки 2', 'soilMoistThreshold2', '%',
                    Icons.grass, min: 0, max: 100),
                buildSettingCard('Температура воды\nдля грядки 1', 'waterTempThreshold1', '°C',
                    Icons.opacity, min: 0, max: 70),
                buildSettingCard('Температура воды\nдля грядки 2', 'waterTempThreshold2', '°C',
                    Icons.opacity, min: 0, max: 70),
                buildSettingCard('Уровень воды', 'waterLevelThreshold', '/ 3',
                    Icons.water, min: 0, max: 3),
                buildSettingCard('Освещенность', 'lightThreshold', '%', Icons.light_mode,
                    min: 0, max: 1000),
                buildSettingCard('Движение', 'motionThreshold', '', Icons.motion_photos_on,
                    min: 0, max: 1),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget buildSettingCard(String title, String settingName, String unit, IconData icon,
      {required int min, required int max}) {
    bool isFlipped = flippedCards[settingName] ?? false;
    final setting = settingData[settingName];
    double? currentValue = (setting != '-' && setting != null)
        ? double.tryParse(setting.toString())
        : null;

    return GestureDetector(
      onTap: () {
        setState(() {
          flippedCards[settingName] = !isFlipped;
        });
      },
      child: AnimatedSwitcher(
        duration: Duration(milliseconds: 500),
        transitionBuilder: (widget, animation) {
          final rotateAnim = Tween(begin: 0.0, end: 1.0).animate(animation);
          return AnimatedBuilder(
            animation: rotateAnim,
            builder: (context, child) {
              final angle = rotateAnim.value * pi;
              final isReverse = angle > pi / 2;

              return Transform(
                transform: Matrix4.rotationY(angle),
                alignment: Alignment.center,
                child: isReverse
                    ? Transform(
                        transform: Matrix4.rotationY(pi),
                        alignment: Alignment.center,
                        child: isFlipped
                            ? buildCropSelectionCard(title, settingName)
                            : buildMainSettingCard(title, settingName,
                                currentValue, unit, icon, min, max),
                      )
                    : isFlipped
                        ? buildMainSettingCard(title, settingName, currentValue,
                            unit, icon, min, max)
                        : buildCropSelectionCard(title, settingName),
              );
            },
          );
        },
        child: isFlipped
            ? buildCropSelectionCard(title, settingName)
            : buildMainSettingCard(
                title, settingName, currentValue, unit, icon, min, max),
      ),
    );
  }

  Widget buildMainSettingCard(String title, String settingName,
      double? currentValue, String unit, IconData icon, int min, int max) {
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
        padding: const EdgeInsets.all(12),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
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
            SizedBox(height: 6),
            currentValue != null
                ? Column(
                    children: [
                      Text(
                        "${currentValue.toInt()} $unit",
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      Slider(
                        value: currentValue,
                        min: min.toDouble(),
                        max: max.toDouble(),
                        divisions: max - min,
                        activeColor: Colors.lightGreen,
                        inactiveColor: Colors.lightGreen.withValues(alpha: 150),
                        thumbColor: Colors.purple,
                        onChanged: (newValue) {
                          setState(() {
                            settingData[settingName] = newValue.toInt();
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

  Widget buildCropSelectionCard(String title, String settingName) {
    return Card(
      key: ValueKey(true),
      elevation: 6,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      color: Colors.deepPurple,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              '$title для культур',
              textAlign: TextAlign.center,
              style: TextStyle(
                  fontSize: 18,
                  color: Colors.white,
                  fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 10),
            Expanded(
              child: ListView(
                children: predefinedCrops.keys.map((crop) {
                  return ListTile(
                    title: Text(
                      crop,
                      style: TextStyle(color: Colors.white),
                    ),
                    trailing: Icon(Icons.check, color: Colors.white),
                    onTap: () {
                      setState(() {
                        settingData[settingName] =
                            predefinedCrops[crop]![settingName]?.toInt() ??
                                settingData[settingName];
                        flippedCards[settingName] =
                            false; // Переворачиваем обратно
                      });
                    },
                  );
                }).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
