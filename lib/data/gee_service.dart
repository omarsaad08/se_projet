import 'package:dio/dio.dart';

class GeeService {
  static final Dio _dio = Dio();
  static const String _serverUrl = 'http://localhost:5000';

  static Future<bool> checkServerHealth() async {
    try {
      final response = await _dio.get(
        _serverUrl,
        options: Options(receiveTimeout: const Duration(seconds: 5)),
      );
      return response.statusCode == 200;
    } catch (e) {
      print('Server health check failed: $e');
      return false;
    }
  }

  static Map<String, dynamic> getVisualizationParams(String metric) {
    switch (metric) {
      case 'ndvi':
        // NDVI: Brown (bare) -> Green (vegetation)
        return {
          'min': -0.2,
          'max': 0.8,
          'palette': [
            '#8B4513',
            '#A0522D',
            '#CD853F',
            '#DAA520',
            '#F0E68C',
            '#ADFF2F',
            '#32CD32',
            '#228B22',
            '#006400',
            '#004D00',
          ],
        };
      case 'evi':
        // EVI: Similar to NDVI
        return {
          'min': -0.2,
          'max': 0.8,
          'palette': [
            '#8B4513',
            '#A0522D',
            '#CD853F',
            '#DAA520',
            '#F0E68C',
            '#9ACD32',
            '#32CD32',
            '#228B22',
            '#006400',
            '#004D00',
          ],
        };
      case 'ndwi':
        // NDWI: Brown (dry) -> Blue (water)
        return {
          'min': -0.4,
          'max': 0.4,
          'palette': [
            '#AA6600',
            '#CC8833',
            '#DDAA66',
            '#EECCAA',
            '#F5F5DC',
            '#BBDDEE',
            '#66B3FF',
            '#3399FF',
            '#0066CC',
            '#003D99',
          ],
        };
      case 'savi':
        // SAVI: Soil-Adjusted Vegetation Index - Brown (bare) -> Green (vegetation)
        return {
          'min': -0.2,
          'max': 0.8,
          'palette': [
            '#8B4513',
            '#A0522D',
            '#CD853F',
            '#DAA520',
            '#F0E68C',
            '#ADFF2F',
            '#32CD32',
            '#228B22',
            '#006400',
            '#004D00',
          ],
        };
      case 'ndmi':
        // NDMI: Normalized Difference Moisture Index - Brown (dry) -> Green (moist)
        return {
          'min': -0.5,
          'max': 0.6,
          'palette': [
            '#8B4513',
            '#A0522D',
            '#CD853F',
            '#DAA520',
            '#F0E68C',
            '#ADFF2F',
            '#32CD32',
            '#228B22',
            '#006400',
            '#004D00',
          ],
        };
      case 'ndbi':
        // NDBI: Normalized Difference Built-up Index - Green (vegetation) -> Gray -> Red (built-up)
        return {
          'min': -0.4,
          'max': 0.4,
          'palette': [
            '#006400',
            '#228B22',
            '#32CD32',
            '#90EE90',
            '#D3D3D3',
            '#A9A9A9',
            '#FF9966',
            '#FF6633',
            '#CC3300',
            '#8B0000',
          ],
        };
      case 'temp':
        // Temperature: Blue (cold) -> Red (hot)
        return {
          'min': 7, // ~280K in Celsius
          'max': 47, // ~320K in Celsius
          'palette': [
            '#313695',
            '#4575B4',
            '#74ADD1',
            '#ABD9E9',
            '#E0F3F8',
            '#FFFFBF',
            '#FEE090',
            '#FDAE61',
            '#F46D43',
            '#D73027',
            '#A50026',
          ],
        };
      default:
        return {
          'min': 0,
          'max': 1,
          'palette': ['#000000', '#ffffff'],
        };
    }
  }

  static Future<GeeMapResponse?> getMapTiles({
    required int year,
    required String season,
    required String metric,
  }) async {
    try {
      print('Requesting $metric for $year ($season) from Python server...');

      final response = await _dio.get(
        '$_serverUrl/compute',
        queryParameters: {'year': year, 'season': season, 'metric': metric},
        options: Options(receiveTimeout: const Duration(seconds: 60)),
      );

      if (response.statusCode == 200) {
        final data = response.data;

        if (data['success'] == true && data['tileUrl'] != null) {
          final tileUrl = data['tileUrl'] as String;
          print('Tile URL received successfully!');

          return GeeMapResponse(
            tileUrlTemplate: tileUrl,
            metric: metric,
            year: year,
            season: season,
          );
        } else {
          print('Server returned error: ${data['error']}');
          return null;
        }
      }

      print('Server returned status: ${response.statusCode}');
      return null;
    } catch (e) {
      print('Error calling GEE server: $e');
      if (e is DioException && e.type == DioExceptionType.connectionError) {
        print(
          'Make sure the Python server is running: python gee_server/server.py',
        );
      }
      return null;
    }
  }

  /// Get detailed pixel information at a specific point
  static Future<PointInfoResponse?> getPointInfo({
    required double lat,
    required double lng,
    required int year,
    required String season,
  }) async {
    try {
      print('Getting point info at ($lat, $lng) for $year ($season)...');

      final response = await _dio.get(
        '$_serverUrl/point-info',
        queryParameters: {
          'lat': lat,
          'lng': lng,
          'year': year,
          'season': season,
        },
        options: Options(receiveTimeout: const Duration(seconds: 30)),
      );

      if (response.statusCode == 200) {
        final data = response.data;

        if (data['success'] == true) {
          return PointInfoResponse.fromJson(data);
        } else {
          print('Point info error: ${data['error']}');
          return PointInfoResponse(
            success: false,
            errorMessage: data['error'] ?? 'Unknown error',
            isWithinProtected: data['isWithinProtected'] ?? false,
          );
        }
      }

      return null;
    } catch (e) {
      print('Error getting point info: $e');
      return null;
    }
  }
}

class GeeMapResponse {
  final String tileUrlTemplate;
  final String metric;
  final int year;
  final String season;

  GeeMapResponse({
    required this.tileUrlTemplate,
    required this.metric,
    required this.year,
    required this.season,
  });
}

class MetricColorMapper {
  static int getColorForValue(double value, String metric) {
    final params = GeeService.getVisualizationParams(metric);
    final min = (params['min'] as num).toDouble();
    final max = (params['max'] as num).toDouble();
    final palette = params['palette'] as List<String>;

    final normalized = ((value - min) / (max - min)).clamp(0.0, 1.0);
    final colorIndex = (normalized * (palette.length - 1)).floor();
    final nextIndex = (colorIndex + 1).clamp(0, palette.length - 1);
    final t = (normalized * (palette.length - 1)) - colorIndex;

    final color1 = _parseHexColor(palette[colorIndex]);
    final color2 = _parseHexColor(palette[nextIndex]);

    return _interpolateColor(color1, color2, t);
  }

  static int _parseHexColor(String hex) {
    hex = hex.replaceFirst('#', '');
    if (hex.length == 6) hex = 'FF$hex';
    return int.parse(hex, radix: 16);
  }

  static int _interpolateColor(int color1, int color2, double t) {
    final a1 = (color1 >> 24) & 0xFF;
    final r1 = (color1 >> 16) & 0xFF;
    final g1 = (color1 >> 8) & 0xFF;
    final b1 = color1 & 0xFF;

    final a2 = (color2 >> 24) & 0xFF;
    final r2 = (color2 >> 16) & 0xFF;
    final g2 = (color2 >> 8) & 0xFF;
    final b2 = color2 & 0xFF;

    final a = (a1 + (a2 - a1) * t).round();
    final r = (r1 + (r2 - r1) * t).round();
    final g = (g1 + (g2 - g1) * t).round();
    final b = (b1 + (b2 - b1) * t).round();

    return (a << 24) | (r << 16) | (g << 8) | b;
  }

  static List<LegendItem> getLegendItems(String metric) {
    final params = GeeService.getVisualizationParams(metric);
    final min = (params['min'] as num).toDouble();
    final max = (params['max'] as num).toDouble();
    final palette = params['palette'] as List<String>;

    final items = <LegendItem>[];
    for (int i = 0; i < palette.length; i++) {
      final value = min + (max - min) * (i / (palette.length - 1));
      items.add(
        LegendItem(
          color: _parseHexColor(palette[i]),
          value: value,
          label: value.toStringAsFixed(2),
        ),
      );
    }
    return items;
  }
}

class LegendItem {
  final int color;
  final double value;
  final String label;

  LegendItem({required this.color, required this.value, required this.label});
}

/// Response class for point info queries
class PointInfoResponse {
  final bool success;
  final String? errorMessage;
  final bool isWithinProtected;
  final double? lat;
  final double? lng;
  final Map<String, double?>? metrics;
  final Map<String, String>? interpretation;
  final Map<String, dynamic>? metadata;

  PointInfoResponse({
    required this.success,
    this.errorMessage,
    this.isWithinProtected = false,
    this.lat,
    this.lng,
    this.metrics,
    this.interpretation,
    this.metadata,
  });

  factory PointInfoResponse.fromJson(Map<String, dynamic> json) {
    final coords = json['coordinates'] as Map<String, dynamic>?;
    final rawMetrics = json['metrics'] as Map<String, dynamic>?;
    final rawInterpretation = json['interpretation'] as Map<String, dynamic>?;

    // Convert metrics to proper types
    Map<String, double?>? metrics;
    if (rawMetrics != null) {
      metrics = {};
      rawMetrics.forEach((key, value) {
        metrics![key] = value != null ? (value as num).toDouble() : null;
      });
    }

    // Convert interpretation to String map
    Map<String, String>? interpretation;
    if (rawInterpretation != null) {
      interpretation = {};
      rawInterpretation.forEach((key, value) {
        interpretation![key] = value?.toString() ?? 'Unknown';
      });
    }

    return PointInfoResponse(
      success: json['success'] == true,
      errorMessage: json['error'] as String?,
      isWithinProtected: json['isWithinProtected'] == true,
      lat: coords?['lat'] != null ? (coords!['lat'] as num).toDouble() : null,
      lng: coords?['lng'] != null ? (coords!['lng'] as num).toDouble() : null,
      metrics: metrics,
      interpretation: interpretation,
      metadata: json['metadata'] as Map<String, dynamic>?,
    );
  }

  /// Get a formatted string for a metric value
  String getMetricDisplay(String metricKey) {
    if (metrics == null || metrics![metricKey] == null) {
      return 'N/A';
    }
    final value = metrics![metricKey]!;
    if (metricKey == 'temp') {
      return '${value.toStringAsFixed(1)}°C';
    }
    return value.toStringAsFixed(4);
  }

  /// Get a user-friendly label for a metric
  static String getMetricLabel(String key) {
    const labels = {
      'ndvi': 'NDVI (Vegetation)',
      'evi': 'EVI (Enhanced Vegetation)',
      'ndwi': 'NDWI (Water)',
      'savi': 'SAVI (Soil-Adjusted Veg.)',
      'ndmi': 'NDMI (Moisture)',
      'ndbi': 'NDBI (Built-up)',
      'temp': 'Temperature',
    };
    return labels[key] ?? key.toUpperCase();
  }
}
