import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:se_project/data/charts_services.dart';

class TimeSeriesLineChart extends StatelessWidget {
  final ChartDataResponse data;
  final String metric;
  final String selectedAreaId;
  final String selectedSeason;

  const TimeSeriesLineChart({
    super.key,
    required this.data,
    required this.metric,
    required this.selectedAreaId,
    required this.selectedSeason,
  });

  /// Get color based on data type (historical vs predicted)
  Color getLineColor(bool isPrediction) {
    return isPrediction ? Colors.orange : Colors.blue;
  }

  /// Get separate line data for historical and predicted data
  List<LineChartBarData> _getLineChartBarData() {
    List<ChartDataPoint> filteredData = data.data;

    // Filter by area if specific area is selected
    if (selectedAreaId != 'all') {
      filteredData = filteredData
          .where((p) => p.areaId == int.parse(selectedAreaId))
          .toList();
    }

    // Separate historical and predicted data
    Map<int, List<double>> historicalYearValues = {};
    Map<int, List<double>> predictedYearValues = {};

    for (var point in filteredData) {
      if (point.isPrediction) {
        if (!predictedYearValues.containsKey(point.year)) {
          predictedYearValues[point.year] = [];
        }
        predictedYearValues[point.year]!.add(point.value);
      } else {
        if (!historicalYearValues.containsKey(point.year)) {
          historicalYearValues[point.year] = [];
        }
        historicalYearValues[point.year]!.add(point.value);
      }
    }

    List<LineChartBarData> lineBarsData = [];

    // Historical data line
    if (historicalYearValues.isNotEmpty) {
      List<FlSpot> historicalSpots = [];
      historicalYearValues.forEach((year, values) {
        final average = values.reduce((a, b) => a + b) / values.length;
        historicalSpots.add(FlSpot(year.toDouble(), average));
      });
      historicalSpots.sort((a, b) => a.x.compareTo(b.x));

      lineBarsData.add(
        LineChartBarData(
          spots: historicalSpots,
          isCurved: true,
          color: Colors.blue,
          barWidth: 3,
          isStrokeCapRound: true,
          dotData: FlDotData(
            show: true,
            getDotPainter: (spot, percent, barData, index) =>
                FlDotCirclePainter(
              radius: 4,
              color: Colors.blue,
              strokeWidth: 0,
            ),
          ),
          belowBarData: BarAreaData(
            show: true,
            color: Colors.blue.withValues(alpha: 0.1),
          ),
        ),
      );
    }

    // Predicted data line
    if (predictedYearValues.isNotEmpty) {
      List<FlSpot> predictedSpots = [];
      predictedYearValues.forEach((year, values) {
        final average = values.reduce((a, b) => a + b) / values.length;
        predictedSpots.add(FlSpot(year.toDouble(), average));
      });
      predictedSpots.sort((a, b) => a.x.compareTo(b.x));

      lineBarsData.add(
        LineChartBarData(
          spots: predictedSpots,
          isCurved: true,
          color: Colors.orange,
          barWidth: 3,
          isStrokeCapRound: true,
          dashArray: [5, 5], // Dashed line for predictions
          dotData: FlDotData(
            show: true,
            getDotPainter: (spot, percent, barData, index) =>
                FlDotCirclePainter(
              radius: 4,
              color: Colors.orange,
              strokeWidth: 0,
            ),
          ),
          belowBarData: BarAreaData(
            show: true,
            color: Colors.orange.withValues(alpha: 0.1),
          ),
        ),
      );
    }

    return lineBarsData;
  }

  @override
  Widget build(BuildContext context) {
    final lineChartBarData = _getLineChartBarData();

    if (lineChartBarData.isEmpty) {
      return Center(
        child: Text(
          'No data available',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
      );
    }

    // Calculate min and max values for Y axis
    double minY = double.infinity;
    double maxY = double.negativeInfinity;

    for (var line in lineChartBarData) {
      for (var spot in line.spots) {
        if (spot.y < minY) minY = spot.y;
        if (spot.y > maxY) maxY = spot.y;
      }
    }

    // Add some padding to the Y axis
    final yPadding = (maxY - minY) * 0.1;
    minY = (minY - yPadding).clamp(0, double.infinity);
    maxY = maxY + yPadding;

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          // Legend
          Padding(
            padding: const EdgeInsets.only(bottom: 16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildLegendItem('Historical Data', Colors.blue),
                const SizedBox(width: 24),
                _buildLegendItem('Predicted Data', Colors.orange),
              ],
            ),
          ),
          // Chart
          Expanded(
            child: LineChart(
              LineChartData(
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: true,
                  horizontalInterval: 1,
                  verticalInterval: 1,
                ),
                titlesData: FlTitlesData(
                  show: true,
                  rightTitles: AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  topTitles: AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 30,
                      interval: _getYearInterval(),
                      getTitlesWidget: (value, meta) {
                        return Text(
                          '${value.toInt()}',
                          style: const TextStyle(fontSize: 10),
                        );
                      },
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 40,
                      interval: _getValueInterval(maxY - minY),
                      getTitlesWidget: (value, meta) {
                        return Text(
                          '${value.toStringAsFixed(1)}',
                          style: const TextStyle(fontSize: 10),
                        );
                      },
                    ),
                  ),
                ),
                borderData: FlBorderData(
                  show: true,
                  border: Border.all(color: Colors.grey.withOpacity(0.5)),
                ),
                lineBarsData: lineChartBarData,
                minY: minY,
                maxY: maxY,
                lineTouchData: LineTouchData(
                  enabled: true,
                  touchTooltipData: LineTouchTooltipData(
                    getTooltipItems: (touchedSpots) {
                      return touchedSpots.map((LineBarSpot touchedBarSpot) {
                        const flStyle = TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        );
                        return LineTooltipItem(
                          'Year: ${touchedBarSpot.x.toInt()}\nValue: ${touchedBarSpot.y.toStringAsFixed(3)}',
                          flStyle,
                        );
                      }).toList();
                    },
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  double _getYearInterval() {
    final yearRange = data.endYear - data.startYear;
    if (yearRange <= 5) return 1;
    if (yearRange <= 10) return 2;
    if (yearRange <= 20) return 5;
    return 10;
  }

  double _getValueInterval(double range) {
    if (range <= 0.1) return 0.01;
    if (range <= 1) return 0.1;
    if (range <= 10) return 1;
    if (range <= 100) return 10;
    return 50;
  }

  Widget _buildLegendItem(String label, Color color) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 8),
        Text(
          label,
          style: const TextStyle(fontSize: 12),
        ),
      ],
    );
  }
}

/// Alternative simpler line chart that shows average by year for all areas
class AverageTimeSeriesChart extends StatelessWidget {
  final ChartDataResponse data;
  final String metric;

  const AverageTimeSeriesChart({
    Key? key,
    required this.data,
    required this.metric,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Group data by year and calculate average across all areas
    Map<int, List<double>> yearValues = {};
    for (var point in data.data) {
      if (!yearValues.containsKey(point.year)) {
        yearValues[point.year] = [];
      }
      yearValues[point.year]!.add(point.value);
    }

    List<FlSpot> spots = [];
    yearValues.forEach((year, values) {
      final average = values.reduce((a, b) => a + b) / values.length;
      spots.add(FlSpot(year.toDouble(), average));
    });

    spots.sort((a, b) => a.x.compareTo(b.x));

    if (spots.isEmpty) {
      return Center(
        child: Text(
          'No data available',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
      );
    }

    // Calculate min and max values for Y axis
    double minY = spots.map((s) => s.y).reduce((a, b) => a < b ? a : b);
    double maxY = spots.map((s) => s.y).reduce((a, b) => a > b ? a : b);

    final yPadding = (maxY - minY) * 0.1;
    minY = (minY - yPadding).clamp(0, double.infinity);
    maxY = maxY + yPadding;

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: LineChart(
        LineChartData(
          gridData: FlGridData(
            show: true,
            drawVerticalLine: true,
            horizontalInterval: 1,
            verticalInterval: 1,
          ),
          titlesData: FlTitlesData(
            show: true,
            rightTitles: AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            topTitles: AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 30,
                interval: _getYearInterval(),
                getTitlesWidget: (value, meta) {
                  return Text(
                    '${value.toInt()}',
                    style: const TextStyle(fontSize: 10),
                  );
                },
              ),
            ),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 40,
                interval: _getValueInterval(maxY - minY),
                getTitlesWidget: (value, meta) {
                  return Text(
                    '${value.toStringAsFixed(1)}',
                    style: const TextStyle(fontSize: 10),
                  );
                },
              ),
            ),
          ),
          borderData: FlBorderData(
            show: true,
            border: Border.all(color: Colors.grey.withOpacity(0.5)),
          ),
          lineBarsData: [
            LineChartBarData(
              spots: spots,
              isCurved: true,
              color: Colors.blue,
              barWidth: 3,
              isStrokeCapRound: true,
              dotData: FlDotData(
                show: true,
                getDotPainter: (spot, percent, barData, index) =>
                    FlDotCirclePainter(
                  radius: 4,
                  color: Colors.blue,
                  strokeWidth: 0,
                ),
              ),
              belowBarData: BarAreaData(
                show: true,
                color: Colors.blue.withValues(alpha: 0.1),
              ),
            ),
          ],
          minY: minY,
          maxY: maxY,
          lineTouchData: LineTouchData(
            enabled: true,
            touchTooltipData: LineTouchTooltipData(
              getTooltipItems: (touchedSpots) {
                return touchedSpots.map((LineBarSpot touchedBarSpot) {
                  const flStyle = TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  );
                  return LineTooltipItem(
                    'Year: ${touchedBarSpot.x.toInt()}\nAvg $metric: ${touchedBarSpot.y.toStringAsFixed(3)}',
                    flStyle,
                  );
                }).toList();
              },
            ),
          ),
        ),
      ),
    );
  }

  double _getYearInterval() {
    final yearRange = data.endYear - data.startYear;
    if (yearRange <= 5) return 1;
    if (yearRange <= 10) return 2;
    if (yearRange <= 20) return 5;
    return 10;
  }

  double _getValueInterval(double range) {
    if (range <= 0.1) return 0.01;
    if (range <= 1) return 0.1;
    if (range <= 10) return 1;
    if (range <= 100) return 10;
    return 50;
  }
}
