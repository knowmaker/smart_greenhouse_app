import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
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
  int? selectedDay;
  int? startHour;
  int? endHour;
  Map<String, double> sensorData = {};

  Future<void> fetchSensorStatistics() async {
    final String baseUrl =
        'http://alexandergh2023.tplinkdns.com/sensor-readings/${widget.greenhouseGuid}/${widget.sensorKey}';

    Map<String, String> queryParams = {'month': selectedMonth.toString()};
    if (selectedDay != null) queryParams['day'] = selectedDay.toString();
    if (startHour != null && endHour != null) {
      queryParams['start_hour'] = startHour.toString();
      queryParams['end_hour'] = endHour.toString();
    }

    final uri = Uri.parse(baseUrl).replace(queryParameters: queryParams);
    final response = await http.get(uri);

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      setState(() {
        sensorData = Map<String, double>.from(
            data['data'].map((k, v) => MapEntry(k, (v as num).toDouble())));
      });
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
                DropdownButton<int>(
                  value: selectedMonth,
                  onChanged: (value) {
                    setState(() {
                      selectedMonth = value!;
                      fetchSensorStatistics();
                    });
                  },
                  items: List.generate(
                      12,
                      (index) => DropdownMenuItem(
                          value: index + 1, child: Text('${index + 1} месяц'))),
                ),
                const SizedBox(width: 10),
                DropdownButton<int?>(
                  value: selectedDay,
                  hint: Text('День'),
                  onChanged: (value) {
                    setState(() {
                      selectedDay = value;
                      fetchSensorStatistics();
                    });
                  },
                  items: List.generate(
                      31,
                      (index) => DropdownMenuItem(
                          value: index + 1, child: Text('${index + 1}'))),
                ),
              ],
            ),
            Row(
              children: [
                DropdownButton<int?>(
                  value: startHour,
                  hint: Text('Начало'),
                  onChanged: (value) {
                    setState(() {
                      startHour = value;
                      fetchSensorStatistics();
                    });
                  },
                  items: List.generate(
                      24,
                      (index) => DropdownMenuItem(
                          value: index, child: Text('$index:00'))),
                ),
                const SizedBox(width: 10),
                DropdownButton<int?>(
                  value: endHour,
                  hint: Text('Конец'),
                  onChanged: (value) {
                    setState(() {
                      endHour = value;
                      fetchSensorStatistics();
                    });
                  },
                  items: List.generate(
                      24,
                      (index) => DropdownMenuItem(
                          value: index, child: Text('$index:00'))),
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
                      // colors: [Colors.green],
                      belowBarData: BarAreaData(show: false),
                    ),
                  ],
                  // titlesData: FlTitlesData(
                  //   leftTitles: SideTitles(showTitles: true),
                  //   bottomTitles: SideTitles(
                  //     showTitles: true,
                  //     getTitles: (value) {
                  //       int index = value.toInt();
                  //       if (index >= 0 && index < sensorData.keys.length) {
                  //         return sensorData.keys.elementAt(index);
                  //       }
                  //       return '';
                  //     },
                  //   ),
                  // ),
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
