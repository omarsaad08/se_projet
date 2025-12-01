import 'package:flutter/material.dart';
import 'package:se_project/data/charts_services.dart';
import 'package:se_project/presentation/components/time_series_chart.dart';
import 'package:intl/intl.dart';

class ChartsPage extends StatefulWidget {
  const ChartsPage({Key? key}) : super(key: key);

  @override
  State<ChartsPage> createState() => _ChartsPageState();
}

class _ChartsPageState extends State<ChartsPage> {
  // Dropdown values
  String selectedMetric = 'ndvi';
  String selectedSeason = 'all';
  String selectedAreaId = 'all';
  int startYear = 2000;
  int endYear = 2024;

  // Data
  List<int> availableAreas = [];
  ChartDataResponse? chartData;
  bool isLoading = false;
  String? errorMessage;

  // Constants
  static const List<String> metrics = ['ndvi', 'evi', 'ndwi', 'temp'];
  static const List<String> seasons = ['all', 'winter', 'spring', 'summer', 'autumn'];
  static const int minYear = 1984;
  static const int maxYear = 2050;

  @override
  void initState() {
    super.initState();
    _loadAreas();
  }

  Future<void> _loadAreas() async {
    try {
      final areas = await ChartsServices.getAllAreas();
      if (areas != null) {
        setState(() {
          availableAreas = areas;
        });
      }
    } catch (e) {
      print("Error loading areas: $e");
    }
  }

  String getMetricLabel(String metric) {
    switch (metric) {
      case 'ndvi':
        return 'NDVI (Vegetation Index)';
      case 'evi':
        return 'EVI (Enhanced Vegetation Index)';
      case 'ndwi':
        return 'NDWI (Water Index)';
      case 'temp':
        return 'Temperature (°C)';
      default:
        return metric.toUpperCase();
    }
  }

  String getSeasonLabel(String season) {
    switch (season) {
      case 'all':
        return 'All Seasons';
      case 'winter':
        return 'Winter';
      case 'spring':
        return 'Spring';
      case 'summer':
        return 'Summer';
      case 'autumn':
        return 'Autumn';
      default:
        return season;
    }
  }

  bool _isValidChartSelection() {
    // Check year range validity
    if (startYear > endYear) {
      setState(() {
        errorMessage = 'Start year must be before end year';
      });
      return false;
    }

    if (startYear < minYear || endYear > maxYear) {
      setState(() {
        errorMessage = 'Years must be between $minYear and $maxYear';
      });
      return false;
    }

    // Clear error if validation passes
    setState(() {
      errorMessage = null;
    });
    return true;
  }

  Future<void> _generateChart() async {
    if (!_isValidChartSelection()) {
      return;
    }

    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      final data = await ChartsServices.getChartData(
        startYear: startYear,
        endYear: endYear,
        areaId: selectedAreaId,
        season: selectedSeason,
        metric: selectedMetric,
      );

      if (data != null && data.data.isNotEmpty) {
        setState(() {
          chartData = data;
          isLoading = false;
        });
      } else {
        setState(() {
          errorMessage = 'No data available for the selected parameters';
          isLoading = false;
          chartData = null;
        });
      }
    } catch (e) {
      setState(() {
        errorMessage = 'Error loading chart data: $e';
        isLoading = false;
        chartData = null;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Environmental Data Charts'),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Filters Card
            Card(
              elevation: 2,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Chart Filters',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 16),

                    // Metric Selector
                    Text('Metric', style: Theme.of(context).textTheme.labelLarge),
                    DropdownButton<String>(
                      value: selectedMetric,
                      isExpanded: true,
                      items: metrics
                          .map((metric) => DropdownMenuItem(
                                value: metric,
                                child: Text(getMetricLabel(metric)),
                              ))
                          .toList(),
                      onChanged: (value) {
                        if (value != null) {
                          setState(() {
                            selectedMetric = value;
                          });
                        }
                      },
                    ),
                    const SizedBox(height: 16),

                    // Area Selector
                    Text('Area', style: Theme.of(context).textTheme.labelLarge),
                    DropdownButton<String>(
                      value: selectedAreaId,
                      isExpanded: true,
                      items: [
                        const DropdownMenuItem(
                          value: 'all',
                          child: Text('All Areas'),
                        ),
                        ...availableAreas.map((area) => DropdownMenuItem(
                              value: area.toString(),
                              child: Text('Area $area'),
                            )),
                      ],
                      onChanged: (value) {
                        if (value != null) {
                          setState(() {
                            selectedAreaId = value;
                          });
                        }
                      },
                    ),
                    const SizedBox(height: 16),

                    // Season Selector
                    Text('Season', style: Theme.of(context).textTheme.labelLarge),
                    DropdownButton<String>(
                      value: selectedSeason,
                      isExpanded: true,
                      items: seasons
                          .map((season) => DropdownMenuItem(
                                value: season,
                                child: Text(getSeasonLabel(season)),
                              ))
                          .toList(),
                      onChanged: (value) {
                        if (value != null) {
                          setState(() {
                            selectedSeason = value;
                          });
                        }
                      },
                    ),
                    const SizedBox(height: 16),

                    // Year Range Selector
                    Text('Year Range', style: Theme.of(context).textTheme.labelLarge),
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Start Year', style: Theme.of(context).textTheme.labelSmall),
                              DropdownButton<int>(
                                value: startYear,
                                isExpanded: true,
                                items: List.generate(
                                  maxYear - minYear + 1,
                                  (index) => minYear + index,
                                )
                                    .map((year) => DropdownMenuItem(
                                          value: year,
                                          child: Text('$year'),
                                        ))
                                    .toList(),
                                onChanged: (value) {
                                  if (value != null) {
                                    setState(() {
                                      startYear = value;
                                    });
                                  }
                                },
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('End Year', style: Theme.of(context).textTheme.labelSmall),
                              DropdownButton<int>(
                                value: endYear,
                                isExpanded: true,
                                items: List.generate(
                                  maxYear - minYear + 1,
                                  (index) => minYear + index,
                                )
                                    .map((year) => DropdownMenuItem(
                                          value: year,
                                          child: Text('$year'),
                                        ))
                                    .toList(),
                                onChanged: (value) {
                                  if (value != null) {
                                    setState(() {
                                      endYear = value;
                                    });
                                  }
                                },
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // Error Message
                    if (errorMessage != null)
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.red.shade100,
                          border: Border.all(color: Colors.red),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          errorMessage!,
                          style: TextStyle(color: Colors.red.shade700),
                        ),
                      ),
                    const SizedBox(height: 16),

                    // Generate Chart Button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: isLoading ? null : _generateChart,
                        child: isLoading
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Text('Generate Chart'),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Chart Display
            if (chartData != null)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Card(
                    elevation: 2,
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Chart Data',
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '${getMetricLabel(selectedMetric)} - ${getSeasonLabel(selectedSeason)} ($startYear-$endYear)',
                            style: Theme.of(context).textTheme.bodyLarge,
                          ),
                          const SizedBox(height: 16),

                          // Metadata
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.grey.shade100,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Total Data Points: ${chartData!.metadata.totalDataPoints}',
                                  style: Theme.of(context).textTheme.bodySmall,
                                ),
                                if (chartData!.metadata.historicalYears.isNotEmpty)
                                  Text(
                                    'Historical Years: ${chartData!.metadata.historicalYears.first} - ${chartData!.metadata.historicalYears.last}',
                                    style: Theme.of(context).textTheme.bodySmall,
                                  ),
                                if (chartData!.metadata.predictedYears.isNotEmpty)
                                  Text(
                                    'Predicted Years: ${chartData!.metadata.predictedYears.first} - ${chartData!.metadata.predictedYears.last}',
                                    style: Theme.of(context).textTheme.bodySmall,
                                  ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 24),

                          // Chart Placeholder (for fl_chart implementation)
                          Container(
                            width: double.infinity,
                            height: 300,
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.grey),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: selectedAreaId == 'all'
                                ? AverageTimeSeriesChart(
                                    data: chartData!,
                                    metric: selectedMetric,
                                  )
                                : TimeSeriesLineChart(
                                    data: chartData!,
                                    metric: selectedMetric,
                                    selectedAreaId: selectedAreaId,
                                    selectedSeason: selectedSeason,
                                  ),
                          ),

                          const SizedBox(height: 16),

                          // Data Summary
                          Text(
                            'Data Summary',
                            style: Theme.of(context).textTheme.labelLarge,
                          ),
                          const SizedBox(height: 8),
                          _buildDataSummary(),
                        ],
                      ),
                    ),
                  ),
                ],
              )
            else if (!isLoading)
              Center(
                child: Padding(
                  padding: const EdgeInsets.all(32.0),
                  child: Column(
                    children: [
                      Icon(Icons.info_outline, color: Colors.grey, size: 48),
                      const SizedBox(height: 16),
                      Text(
                        'Select filters and click "Generate Chart" to view data',
                        style: Theme.of(context).textTheme.bodyMedium,
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildDataSummary() {
    if (chartData == null || chartData!.data.isEmpty) {
      return const SizedBox.shrink();
    }

    final values = chartData!.data.map((p) => p.value).toList();
    final avgValue = values.reduce((a, b) => a + b) / values.length;
    final minValue = values.reduce((a, b) => a < b ? a : b);
    final maxValue = values.reduce((a, b) => a > b ? a : b);

    return Column(
      children: [
        _summaryRow('Average ${selectedMetric.toUpperCase()}:', '$avgValue'),
        _summaryRow('Min ${selectedMetric.toUpperCase()}:', '$minValue'),
        _summaryRow('Max ${selectedMetric.toUpperCase()}:', '$maxValue'),
        _summaryRow('Data Points:', '${chartData!.data.length}'),
      ],
    );
  }

  Widget _summaryRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: Theme.of(context).textTheme.bodySmall),
          Text(value, style: Theme.of(context).textTheme.bodySmall?.copyWith(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}
