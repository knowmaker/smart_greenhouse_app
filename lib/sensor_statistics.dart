import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'dart:convert';
import 'package:fl_chart/fl_chart.dart';
import 'auth_provider.dart';

class SensorStatisticsScreen extends StatefulWidget {
  final String sensorTitle;
  final String greenhouseGuid;
  final String sensorKey;

  SensorStatisticsScreen({
    required this.sensorTitle,
    required this.greenhouseGuid,
    required this.sensorKey,
  });

  @override
  SensorStatisticsScreenState createState() => SensorStatisticsScreenState();
}

class SensorStatisticsScreenState extends State<SensorStatisticsScreen> {
  int selectedMonth = DateTime.now().month;
  int? selectedDay = DateTime.now().day;
  int? startHour;
  int? endHour;
  List<FlSpot> chartData = [];
  List<String> xLabels = [];

  Future<void> fetchSensorStatistics() async {
    if (!GlobalAuth.isLoggedIn) return;

    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('access_token');

    final url =
        '${dotenv.env['API_BASE_URL']}/sensor-readings/${widget.greenhouseGuid}/${widget.sensorKey}';

    Map<String, String> queryParams = {'month': selectedMonth.toString()};
    if (selectedDay != null) queryParams['day'] = selectedDay.toString();
    if (startHour != null && endHour != null) {
      queryParams['start_hour'] = startHour.toString();
      queryParams['end_hour'] = endHour.toString();
    }

    final uri = Uri.parse(url).replace(queryParameters: queryParams);
    try {
      final response = await http.get(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        parseSensorData(data['data']);
      }
    } catch (e) {
      // Обработать ошибку запроса
    }
  }

  void parseSensorData(dynamic data) {
    List<FlSpot> spots = [];
    List<String> labels = [];
    int index = 0;

    if (data is Map<String, dynamic>) {
      data.forEach((key, value) {
        if (value is num) {
          // Формат { "2025-01-10": 22.6 }
          spots.add(FlSpot(index.toDouble(), value.toDouble()));
          labels.add(key);
        } else if (value is Map<String, dynamic>) {
          // Формат { "2025-01-10 10:00": { "30-59": 22 } }
          value.forEach((time, temp) {
            if (temp is num) {
              spots.add(FlSpot(index.toDouble(), temp.toDouble()));
              labels.add("$key $time");
            } else if (temp is Map<String, num>) {
              temp.forEach((range, t) {
                spots.add(FlSpot(index.toDouble(), t.toDouble()));
                labels.add("$key $time-$range");
              });
            }
          });
        }
        index++;
      });
    }

    setState(() {
      chartData = spots;
      xLabels = labels;
    });
  }

  Widget buildDropdown<T>({
    required String hint,
    required T? value,
    required List<T?> items,
    required ValueChanged<T?> onChanged,
  }) {
    return Expanded(
      child: DropdownButtonFormField<T>(
        value: value,
        decoration: InputDecoration(
          labelText: hint,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8.0),
            borderSide: BorderSide(
              color: Colors.blue,
              width: 1.5,
            ),
          ),
          contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        ),
        onChanged: onChanged,
        items: items.map((item) {
          return DropdownMenuItem<T>(
            value: item,
            child: Text(item == null ? "-" : item.toString()),
          );
        }).toList(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.sensorTitle.replaceAll('\n', ' '))),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                SizedBox(
                  width: 80,
                  child: TextFormField(
                    initialValue: DateTime.now().year.toString(),
                    decoration: InputDecoration(
                      labelText: 'Год',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8.0),
                      ),
                      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    ),
                    enabled: false,
                  ),
                ),
                const SizedBox(height: 20),
                buildDropdown<int>(
                  hint: 'Месяц',
                  value: selectedMonth,
                  items: [for (var i = 1; i <= 12; i++) i],
                  onChanged: (value) => setState(() => selectedMonth = value!),
                ),
                const SizedBox(width: 10),
                buildDropdown<int?>(
                  hint: 'День',
                  value: selectedDay,
                  items: [null, for (var i = 1; i <= 31; i++) i],
                  onChanged: (value) => setState(() => selectedDay = value),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                buildDropdown<int?>(
                  hint: 'Начало',
                  value: startHour,
                  items: [null, for (var i = 0; i < 24; i++) i],
                  onChanged: (value) => setState(() => startHour = value),
                ),
                const SizedBox(width: 10),
                buildDropdown<int?>(
                  hint: 'Конец',
                  value: endHour,
                  items: [null, for (var i = 0; i < 24; i++) i],
                  onChanged: (value) => setState(() => endHour = value),
                ),
                const SizedBox(width: 10),
                ElevatedButton(
                  onPressed: fetchSensorStatistics,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    padding: EdgeInsets.symmetric(vertical: 14),
                    textStyle: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  child: Icon(
                    Icons.insert_chart,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Expanded(
              child: LineChart(
                LineChartData(
                  lineBarsData: [
                    LineChartBarData(
                      spots: chartData,
                      isCurved: true,
                      barWidth: 3,
                      color: Colors.purple,
                      belowBarData: BarAreaData(show: false),
                    ),
                  ],
                  titlesData: FlTitlesData(
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(showTitles: true),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        interval: chartData.isNotEmpty ? (chartData.length / 5).ceilToDouble() : 1,
                        getTitlesWidget: (value, meta) {
                          int index = value.toInt();
                          if (index >= 0 && index < xLabels.length) {
                            return Text(
                              xLabels[index],
                              style: TextStyle(fontSize: 10),
                              overflow: TextOverflow.ellipsis,
                            );
                          }
                          return Container();
                        },
                      ),
                    ),
                  ),
                  borderData: FlBorderData(show: true),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
