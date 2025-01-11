import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'sensor_screen.dart';
import 'control_screen.dart';
import 'settings_screen.dart';
import 'login_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
      title: 'Умная Теплица',
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
  bool _isLoggedIn = false; // Флаг для проверки входа

  @override
  void initState() {
    super.initState();
    _checkLoginStatus(); // Проверяем статус входа при старте
  }

  Future<void> _checkLoginStatus() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('access_token');
    setState(() {
      _isLoggedIn = token != null && token.isNotEmpty; // Проверяем наличие токена
    });
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  Future<void> _logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('access_token'); // Удаляем токен при выходе
    setState(() {
      _isLoggedIn = false; // Обновляем статус входа
    });
  }

  final List<Widget> _screens = [
    SensorScreen(),
    ControlScreen(),
    SettingsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Умная Теплица'),
        actions: [
          IconButton(
            icon: Icon(
              _isLoggedIn ? Icons.exit_to_app : Icons.account_circle, // Меняем иконку
              size: 30,
            ),
            onPressed: () async {
              if (_isLoggedIn) {
                _logout(); // Если вошли, выходим
              } else {
                await Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => LoginScreen()), // Переход на экран входа
                );
                _checkLoginStatus();
              }
            },
          ),
        ],
      ),
      body: _screens[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
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
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: Colors.green[700],
        onTap: _onItemTapped,
      ),
    );
  }
}
