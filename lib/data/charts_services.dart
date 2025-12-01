import 'package:dio/dio.dart';
import 'dart:convert';

Dio dio = Dio();

class ChartsServices {
  static const String _baseUrl = "https://49b1938e84a5.ngrok-free.app";

  /// Get all available areas
  static Future<List<int>?> getAllAreas() async {
    try {
      final response = await dio.get(
        "$_baseUrl/api?areas=1",
        options: Options(
          responseType: ResponseType.json,
          headers: {"ngrok-skip-browser-warning": "true"},
        ),
      );

      if (response.statusCode == 200) {
        var responseData = response.data;
        if (responseData is String) {
          responseData = jsonDecode(responseData) as Map<String, dynamic>;
        }

        if (responseData is Map<String, dynamic> &&
            responseData.containsKey('areas')) {
          List<int> areas = List<int>.from(responseData['areas']);
          return areas;
        }
      }
      return null;
    } catch (e) {
      print("Error fetching areas: $e");
      return null;
    }
  }

  /// Get chart data with merged historical and predicted data
  /// 
  /// Parameters:
  /// - startYear: 1984 to 2050
  /// - endYear: 1984 to 2050
  /// - areaId: 'all' or specific area ID
  /// - season: 'all', 'winter', 'spring', 'summer', 'autumn'
  /// - metric: 'ndvi', 'evi', 'ndwi', 'temp'
  static Future<ChartDataResponse?> getChartData({
    required int startYear,
    required int endYear,
    required String areaId,
    required String season,
    required String metric,
  }) async {
    try {
      // Validate parameters
      if (startYear < 1984 || endYear > 2050 || startYear > endYear) {
        throw Exception(
            'Invalid year range. Years must be between 1984 and 2050');
      }

      final url =
          "$_baseUrl/api?chart=1&startYear=$startYear&endYear=$endYear&areaId=$areaId&season=$season&metric=$metric";

      print("Requesting chart data: $url");

      final response = await dio.get(
        url,
        options: Options(
          responseType: ResponseType.json,
          headers: {"ngrok-skip-browser-warning": "true"},
        ),
      );

      print("Chart response status: ${response.statusCode}");

      if (response.statusCode == 200) {
        var responseData = response.data;
        if (responseData is String) {
          responseData = jsonDecode(responseData) as Map<String, dynamic>;
        }

        if (responseData is Map<String, dynamic>) {
          return ChartDataResponse.fromJson(responseData);
        }
      }

      return null;
    } catch (e) {
      print("Error fetching chart data: $e");
      return null;
    }
  }
}

class ChartDataResponse {
  final int startYear;
  final int endYear;
  final dynamic areaId; // 'all' or int
  final String season;
  final String metric;
  final List<ChartDataPoint> data;
  final ChartMetadata metadata;

  ChartDataResponse({
    required this.startYear,
    required this.endYear,
    required this.areaId,
    required this.season,
    required this.metric,
    required this.data,
    required this.metadata,
  });

  factory ChartDataResponse.fromJson(Map<String, dynamic> json) {
    List<ChartDataPoint> dataPoints = [];
    if (json['data'] is List) {
      dataPoints = (json['data'] as List)
          .map((e) => ChartDataPoint.fromJson(e as Map<String, dynamic>))
          .toList();
    }

    return ChartDataResponse(
      startYear: json['startYear'] ?? 0,
      endYear: json['endYear'] ?? 0,
      areaId: json['areaId'],
      season: json['season'] ?? 'all',
      metric: json['metric'] ?? 'ndvi',
      data: dataPoints,
      metadata: ChartMetadata.fromJson(
          json['metadata'] as Map<String, dynamic>? ?? {}),
    );
  }

  /// Calculate average values grouped by year
  Map<int, double> getAverageByYear() {
    Map<int, double> yearAverages = {};
    Map<int, List<double>> yearValues = {};

    for (var point in data) {
      if (!yearValues.containsKey(point.year)) {
        yearValues[point.year] = [];
      }
      yearValues[point.year]!.add(point.value);
    }

    yearValues.forEach((year, values) {
      yearAverages[year] =
          values.reduce((a, b) => a + b) / values.length;
    });

    return yearAverages;
  }

  /// Calculate average values grouped by area
  Map<int, double> getAverageByArea() {
    Map<int, double> areaAverages = {};
    Map<int, List<double>> areaValues = {};

    for (var point in data) {
      if (!areaValues.containsKey(point.areaId)) {
        areaValues[point.areaId] = [];
      }
      areaValues[point.areaId]!.add(point.value);
    }

    areaValues.forEach((area, values) {
      areaAverages[area] = values.reduce((a, b) => a + b) / values.length;
    });

    return areaAverages;
  }

  /// Get data for a specific area
  List<ChartDataPoint> getDataForArea(int areaId) {
    return data.where((point) => point.areaId == areaId).toList();
  }

  /// Get data for a specific season
  List<ChartDataPoint> getDataForSeason(String season) {
    return data.where((point) => point.season == season).toList();
  }
}

class ChartDataPoint {
  final int? id;
  final int areaId;
  final int year;
  final String season;
  final double value;
  final bool isPrediction;

  ChartDataPoint({
    required this.id,
    required this.areaId,
    required this.year,
    required this.season,
    required this.value,
    required this.isPrediction,
  });

  factory ChartDataPoint.fromJson(Map<String, dynamic> json) {
    return ChartDataPoint(
      id: json['id'],
      areaId: json['area_id'] ?? 0,
      year: json['year'] ?? 0,
      season: json['season'] ?? 'unknown',
      value: (json.values
              .where((v) =>
                  v is num &&
                  json.keys.firstWhere((k) => json[k] == v,
                          orElse: () => '') ==
                      'ndvi' ||
                  json.keys.firstWhere((k) => json[k] == v,
                          orElse: () => '') ==
                      'evi' ||
                  json.keys.firstWhere((k) => json[k] == v,
                          orElse: () => '') ==
                      'ndwi' ||
                  json.keys.firstWhere((k) => json[k] == v,
                          orElse: () => '') ==
                      'temp')
              .firstOrNull ??
          0.0)
          .toDouble(),
      isPrediction: json['is_prediction'] ?? false,
    );
  }
}

class ChartMetadata {
  final List<int> historicalYears;
  final List<int> predictedYears;
  final int totalDataPoints;

  ChartMetadata({
    required this.historicalYears,
    required this.predictedYears,
    required this.totalDataPoints,
  });

  factory ChartMetadata.fromJson(Map<String, dynamic> json) {
    return ChartMetadata(
      historicalYears: List<int>.from(json['historical_years'] ?? []),
      predictedYears: List<int>.from(json['predicted_years'] ?? []),
      totalDataPoints: json['total_data_points'] ?? 0,
    );
  }
}
