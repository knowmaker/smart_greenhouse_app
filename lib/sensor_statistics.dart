import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'dart:convert';
import 'package:fl_chart/fl_chart.dart';

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
  Map<String, double> sensorData = {};

  Future<void> fetchSensorStatistics() async {
    final url = '${dotenv.env['API_BASE_URL']}/sensor-readings/${widget.greenhouseGuid}/${widget.sensorKey}';

    Map<String, String> queryParams = {'month': selectedMonth.toString()};
    if (selectedDay != null) queryParams['day'] = selectedDay.toString();
    if (startHour != null && endHour != null) {
      queryParams['start_hour'] = startHour.toString();
      queryParams['end_hour'] = endHour.toString();
    }

    final uri = Uri.parse(url).replace(queryParameters: queryParams);
    try {
      final response = await http.get(uri);
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
        sensorData = Map<String, double>.from(
            data['data'].map((k, v) => MapEntry(k, (v as num).toDouble())));
        });
      }
    } catch (e) {
      // Обработать ошибку запроса
    }
  }

  List<FlSpot> getChartData() {
    List<FlSpot> spots = [];
    int index = 0;
    sensorData.forEach((key, value) {
      spots.add(FlSpot(index.toDouble(), value));
      index++;
    });
    return spots;
  }

  Widget buildDropdown<T>(
      {required String hint,
      required T? value,
      required List<T> items,
      required ValueChanged<T?> onChanged}) {
    return DropdownButton<T>(
      value: value,
      hint: Text(hint),
      onChanged: onChanged,
      items: items
          .map((item) =>
              DropdownMenuItem(value: item, child: Text(item.toString())))
          .toList(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.sensorTitle)),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                buildDropdown<int>(
                  hint: 'Месяц',
                  value: selectedMonth,
                  items: List.generate(12, (index) => index + 1),
                  onChanged: (value) {
                    setState(() {
                      selectedMonth = value!;
                      fetchSensorStatistics();
                    });
                  },
                ),
                const SizedBox(width: 10),
                buildDropdown<int?>(
                  hint: 'День',
                  value: selectedDay,
                  items: List.generate(31, (index) => index + 1),
                  onChanged: (value) {
                    setState(() {
                      selectedDay = value;
                      fetchSensorStatistics();
                    });
                  },
                ),
              ],
            ),
            Row(
              children: [
                buildDropdown<int?>(
                  hint: 'Начало',
                  value: startHour,
                  items: List.generate(24, (index) => index),
                  onChanged: (value) {
                    setState(() {
                      startHour = value;
                      fetchSensorStatistics();
                    });
                  },
                ),
                const SizedBox(width: 10),
                buildDropdown<int?>(
                  hint: 'Конец',
                  value: endHour,
                  items: List.generate(24, (index) => index),
                  onChanged: (value) {
                    setState(() {
                      endHour = value;
                      fetchSensorStatistics();
                    });
                  },
                ),
              ],
            ),
            const SizedBox(height: 20),
            Expanded(
              child: LineChart(
                LineChartData(
                  lineBarsData: [
                    LineChartBarData(
                      spots: getChartData(),
                      isCurved: true,
                      barWidth: 3,
                      color: Colors.green,
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
                        getTitlesWidget: (value, meta) {
                          int index = value.toInt();
                          if (index >= 0 && index < sensorData.keys.length) {
                            return Text(
                              sensorData.keys.elementAt(index),
                              style: TextStyle(fontSize: 10),
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
