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
  String? selectedHourRange;
  bool isLineChart = false;
  List<BarChartGroupData> barChartData = [];
  List<FlSpot> lineChartData = [];
  List<String> xLabels = [];
  int currentPage = 0;
  int itemsPerPage = 6;
  double maxYValue = 100;

  final List<String> hourRanges = List.generate(
    24,
    (index) => '$index:00-${index + 1}:00',
  );

  final List<String> monthNames = [
    "Январь", "Февраль", "Март", "Апрель", "Май", "Июнь",
    "Июль", "Август", "Сентябрь", "Октябрь", "Ноябрь", "Декабрь"
  ];

  Future<void> fetchSensorStatistics() async {
    if (!GlobalAuth.isLoggedIn) return;

    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('access_token');

    final url =
        '${dotenv.env['API_BASE_URL']}/sensor-readings/${widget.greenhouseGuid}/${widget.sensorKey}';

    Map<String, String> queryParams = {'month': selectedMonth.toString()};
    if (selectedDay != null) queryParams['day'] = selectedDay.toString();
    if (selectedHourRange != null) {
      List<String> hours = selectedHourRange!.split('-');
      queryParams['start_hour'] = hours[0].split(':')[0];
      queryParams['end_hour'] = hours[1].split(':')[0];
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

  void parseSensorData(Map<String, dynamic> data) {
    List<BarChartGroupData> bars = [];
    List<FlSpot> spots = [];
    List<String> labels = [];
    int index = 0;
    double maxValue = 0;

    List<String> sortedKeys = data.keys.toList()..sort();

    for (var key in sortedKeys) {
      var value = data[key];

      if (value is num) {
        double numericValue = value.toDouble();
        maxValue = numericValue > maxValue ? numericValue : maxValue;

        if (selectedHourRange != null) {
          spots.add(FlSpot(index.toDouble(), numericValue));
        } else {
          bars.add(
            BarChartGroupData(
              x: index,
              barRods: [
                BarChartRodData(
                  toY: numericValue,
                  width: 30,
                  color: Colors.purple,
                  borderRadius: BorderRadius.circular(4),
                ),
              ],
              barsSpace: 0,
            ),
          );
        }
        labels.add(key);
      }
      index++;
    }

    double adjustedMaxY = ((maxValue / 10).ceil() * 10) + 10;
    if (adjustedMaxY > 100) adjustedMaxY = 100;

    setState(() {
      isLineChart = selectedHourRange != null;
      barChartData = bars;
      lineChartData = spots;
      xLabels = labels;
      maxYValue = adjustedMaxY;
      currentPage = 0;
    });
  }

  void nextPage() {
    setState(() {
    if (currentPage + itemsPerPage < barChartData.length) {
      currentPage++;
      }
    });
  }

  void prevPage() {
    setState(() {
      if (currentPage > 0) {
      currentPage--;
      }
    });
  }

  Widget buildChart() {
    if (isLineChart) {
      return LineChart(
        LineChartData(
          lineBarsData: [
            LineChartBarData(
              spots: lineChartData,
              isCurved: false,
              color: Colors.blue,
              barWidth: 2,
              dotData: FlDotData(show: false),
            ),
          ],
          titlesData: FlTitlesData(
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, meta) {
                  int index = value.toInt();
                  if (index == 0 || index == lineChartData.length - 1) {
                    return Text(xLabels[index], style: TextStyle(fontSize: 10));
                  }
                  return Container();
                },
                reservedSize: 30,
              ),
            ),
          ),
          minY: 0,
          maxY: maxYValue,
        ),
      );
    } else {
      List<BarChartGroupData> visibleData =
          barChartData.skip(currentPage).take(itemsPerPage).toList();
      return BarChart(
        BarChartData(
          barGroups: visibleData,
          maxY: maxYValue,
          minY: 0,
          titlesData: FlTitlesData(
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, meta) {
                  int index = value.toInt() - currentPage;
                  if (index >= 0 && index < xLabels.length) {
                    return RotatedBox(
                      quarterTurns: -1,
                      child: Text(
                        xLabels[value.toInt()],
                        style: TextStyle(fontSize: 10),
                        overflow: TextOverflow.visible)
                  );
                  }
                  return Container();
                },
                reservedSize: 60,
              ),
            ),
          topTitles: AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
        ),
        ),
      );
    }
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
                const SizedBox(width: 10),
                buildDropdown<String>(
                  hint: 'Месяц',
                  value: monthNames[selectedMonth - 1],
                  items: monthNames,
                  onChanged: (value) =>
                      setState(() => selectedMonth = monthNames.indexOf(value!) + 1),
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
                buildDropdown<String?>(
                  hint: 'Часовой интервал',
                  value: selectedHourRange,
                  items: [null, ...hourRanges],
                  onChanged: (value) => setState(() => selectedHourRange = value),
                ),
                const SizedBox(width: 10),
            ElevatedButton(
              onPressed: fetchSensorStatistics,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    padding: EdgeInsets.symmetric(vertical: 14),
                  ),
                  child: Icon(
                    Icons.insert_chart,
                    color: Colors.white,
                    size: 24,
                  ),
            ),
              ],
            ),
            const SizedBox(height: 20),
            Expanded(child: buildChart()),
            if (!isLineChart)
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  TextButton.icon(
                    onPressed: prevPage,
                    icon: Icon(Icons.arrow_back, color: Colors.blue),
                    label: Text("Назад", style: TextStyle(color: Colors.blue))),
                  TextButton.icon(
                    onPressed: nextPage,
                    icon: Icon(Icons.arrow_forward, color: Colors.blue,),
                    label: Text("Вперед", style: TextStyle(color: Colors.blue))),
                ],
              ),
          ],
        ),
      ),
    );
  }
}
