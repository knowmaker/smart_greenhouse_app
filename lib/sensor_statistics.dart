import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:fluttertoast/fluttertoast.dart';
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
  double maxYValue = 100;
  double minYValue = 0;
  bool isDataLoaded = false;
  bool isDataEmpty = false;

  final List<String> hourRanges = List.generate(24, (index) => '$index:00-${index + 1}:00');

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
        if (data['data'].isEmpty) {
          setState(() {
            isDataLoaded = true;
            isDataEmpty = true;
          });
        } else {
          parseSensorData(data['data']);
          setState(() {
            isDataLoaded = true;
            isDataEmpty = false;
          });
        }
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

  void parseSensorData(Map<String, dynamic> data) {
    List<BarChartGroupData> bars = [];
    List<FlSpot> spots = [];
    List<String> labels = [];
    int index = 0;
    double maxValue = double.negativeInfinity;
    double minValue = double.infinity;

    List<String> sortedKeys = data.keys.toList()..sort();

    for (var key in sortedKeys) {
      var value = data[key];

      if (value is num) {
        double numericValue = value.toDouble();
        maxValue = numericValue > maxValue ? numericValue : maxValue;
        minValue = numericValue < minValue ? numericValue : minValue;

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
    double adjustedMinY = ((minValue / 10).floor() * 10) - 10;
    if (adjustedMinY < 0) adjustedMinY = 0;

    setState(() {
      isLineChart = selectedHourRange != null;
      barChartData = bars;
      lineChartData = spots;
      xLabels = labels;
      maxYValue = adjustedMaxY;
      minYValue = adjustedMinY;
      currentPage = 0;
    });
  }

  void nextPage() {
    setState(() {
      int step = isLineChart ? 5 : 1;
      if (currentPage + (isLineChart ? 10 : 6) < (isLineChart ? lineChartData.length : barChartData.length)) {
        currentPage += step;
      }
    });
  }

  void prevPage() {
    setState(() {
      int step = isLineChart ? 5 : 1;
      if (currentPage - step >= 0) {
        currentPage -= step;
      }
    });
  }

  Widget buildChart() {
    if (!isDataLoaded) {
      return Center(
        child: Text(
          "Заполните поля и нажмите кнопку",
          style: TextStyle(color: Colors.grey, fontSize: 16),
        ),
      );
    }

    if (isDataEmpty) {
      return Center(
        child: Text(
          "Данных нет",
          style: TextStyle(color: Colors.purple, fontSize: 16),
        ),
      );
    }

    if (isLineChart) {
      List<FlSpot> visibleData =
          lineChartData.skip(currentPage).take(10).toList();
      return LineChart(
        LineChartData(
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
          ),
          lineBarsData: [
            LineChartBarData(
              spots: visibleData,
              isCurved: true,
              curveSmoothness: 0.1,
              color: Colors.purple,
              barWidth: 2,
              dotData: FlDotData(show: true),
              showingIndicators: List.generate(visibleData.length, (index) => index),
            ),
          ],
          lineTouchData: LineTouchData(
            touchTooltipData: LineTouchTooltipData(
              getTooltipItems: (List<LineBarSpot> touchedSpots) {
                return touchedSpots.map((spot) {
                  return LineTooltipItem(
                    'Время: ${xLabels[spot.x.toInt()]}\nПоказание: ${spot.y.toStringAsFixed(2)}',
                    TextStyle(color: Colors.white),
                  );
                }).toList();
              },
            ),
            touchCallback: (FlTouchEvent event, LineTouchResponse? response) {},
            handleBuiltInTouches: true,
          ),
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
                        xLabels[value.toInt()].split(' ')[1],
                        style: TextStyle(fontSize: 10),
                      ),
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
          minY: minYValue,
          maxY: maxYValue,
        ),
      );
    } else {
      List<BarChartGroupData> visibleData =
          barChartData.skip(currentPage).take(6).toList();
      return BarChart(
        BarChartData(
          barGroups: visibleData,
          maxY: maxYValue,
          minY: 0,
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
          ),
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
                      ),
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
            child: Text(item == null ? "Нет" : item.toString()),
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
                  hint: 'Число',
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
            if (isDataLoaded && !isDataEmpty)
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
