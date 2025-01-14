import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'sensor_screen.dart';
import 'control_screen.dart';
import 'settings_screen.dart';
import 'user_screen.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'auth_provider.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]).then((_) {
    runApp(MyApp());
  });
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Smart Greenhouse',
      theme: ThemeData(
        primarySwatch: Colors.green,
        colorScheme: ColorScheme.fromSwatch(primarySwatch: Colors.green).copyWith(secondary: Colors.greenAccent),
      ),
      home: MainScreen(),
    );
  }
}

class MainScreen extends StatefulWidget {
  @override
  MainScreenState createState() => MainScreenState();
}

class MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;
  // bool _isLoggedIn = false;
  List<Map<String, String>> _greenhouses = [];
  Map<String, String>? _selectedGreenhouse;

  @override
  void initState() {
    super.initState();
    // _checkLoginStatus();
    GlobalAuth.initialize();
    _loadGreenhouses();
  }

  // Future<void> _checkLoginStatus() async {
  //   final prefs = await SharedPreferences.getInstance();
  //   final token = prefs.getString('access_token');
  //   setState(() {
  //     _isLoggedIn = token != null && token.isNotEmpty;
  //   });
  // }

  Future<void> _loadGreenhouses() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('access_token');
    if (token == null) return;

    final response = await http.get(
      Uri.parse('http://alexandergh2023.tplinkdns.com/greenhouses/my'),
      headers: {'Authorization': 'Bearer $token'},
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

      final savedGuid = prefs.getString('selected_greenhouse_guid');

      // if (savedGuid != null && _greenhouses.any((gh) => gh['guid'] == savedGuid)) {
      //   _selectedGreenhouse = _greenhouses.firstWhere((gh) => gh['guid'] == savedGuid);
      // } else if (_greenhouses.isNotEmpty) {
      //   _selectedGreenhouse = _greenhouses.first;
      // } else {
      //   _selectedGreenhouse = null;
      // }
      if (savedGuid != null) {
        _selectedGreenhouse =
            _greenhouses.firstWhere((gh) => gh['guid'] == savedGuid, orElse: () => _greenhouses.first);
      }
    }
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  Future<void> _saveSelectedGreenhouse(Map<String, String> greenhouse) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('selected_greenhouse_guid', greenhouse['guid']!);
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> screens = [
      SensorScreen(onLoadGreenhouses: _loadGreenhouses), // Передаем метод как параметр
      ControlScreen(),
      SettingsScreen(),
      UserScreen(onLoadGreenhouses: _loadGreenhouses),
    ];

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            if (_selectedGreenhouse == null)
              Text('SMART GREENHOUSE')
            else
              Flexible(
                child: Row(
                  children: [
                    Icon(Icons.holiday_village_rounded, size: 24),
                    SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        _selectedGreenhouse!['title']!,
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                        style: TextStyle(fontSize: 20),
                      ),
                    ),
                  ],
                ),
              ),
            if (GlobalAuth.isLoggedIn && _greenhouses.isNotEmpty)
              IconButton(
                icon: Icon(Icons.arrow_drop_down, size: 28),
                onPressed: () {
                  showModalBottomSheet(
                    context: context,
                    builder: (context) {
                      return ListView.builder(
                        itemCount: _greenhouses.length,
                        itemBuilder: (context, index) {
                          final greenhouse = _greenhouses[index];
                          return ListTile(
                            leading: Icon(Icons.house),
                            title: Text(greenhouse['title']!),
                            onTap: () {
                              setState(() {
                                _selectedGreenhouse = greenhouse;
                              });
                              _saveSelectedGreenhouse(greenhouse);
                              Navigator.pop(context);
                            },
                          );
                        },
                      );
                    },
                  );
                },
              ),
          ],
        ),
      ),
      body: screens[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.sensors),
            label: 'Состояние',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings_remote),
            label: 'Управление',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings),
            label: 'Настройки',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Профиль',
          ),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: Colors.green[700],
        selectedFontSize: 14,
        unselectedFontSize: 12,
        onTap: _onItemTapped,
      ),
    );
  }
}
