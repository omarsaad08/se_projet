import 'package:dio/dio.dart';
import 'dart:convert';
import 'package:crypto/crypto.dart';

/// Google Earth Engine Service for fetching pixel-wise imagery
///
/// This service uses the GEE REST API to generate map tiles
/// with pixel-wise NDVI, EVI, NDWI, and temperature data
class GeeService {
  static final Dio _dio = Dio();

  // GEE API Configuration
  static String? _accessToken;
  static String? _projectId;
  static String? _serviceAccountEmail;
  static String? _privateKey;

  // GEE REST API base URL
  static const String _geeApiBase = 'https://earthengine.googleapis.com/v1';
  static const String _tokenUrl = 'https://oauth2.googleapis.com/token';

  /// Initialize the service with service account credentials
  /// Call this once at app startup with your GEE credentials
  static void initialize({
    required String projectId,
    required String serviceAccountEmail,
    required String privateKey,
  }) {
    _projectId = projectId;
    _serviceAccountEmail = serviceAccountEmail;
    _privateKey = privateKey;
  }

  /// Check if the service is initialized
  static bool get isInitialized =>
      _projectId != null && _serviceAccountEmail != null && _privateKey != null;

  /// Generate JWT token for service account authentication
  static Future<String?> _getAccessToken() async {
    if (!isInitialized) return null;

    try {
      // JWT header
      final header = {'alg': 'RS256', 'typ': 'JWT'};

      // JWT payload (claims)
      final now = DateTime.now();
      final expiry = now.add(const Duration(hours: 1));

      final payload = {
        'iss': _serviceAccountEmail,
        'scope': 'https://www.googleapis.com/auth/earthengine',
        'aud': _tokenUrl,
        'exp': expiry.millisecondsSinceEpoch ~/ 1000,
        'iat': now.millisecondsSinceEpoch ~/ 1000,
      };

      // Encode header and payload
      final headerEncoded = base64Url
          .encode(utf8.encode(jsonEncode(header)))
          .toString()
          .replaceAll('=', '');
      final payloadEncoded = base64Url
          .encode(utf8.encode(jsonEncode(payload)))
          .toString()
          .replaceAll('=', '');

      final signingInput = '$headerEncoded.$payloadEncoded';

      // For now, return a placeholder
      // In production, you would sign this with RS256
      // For Flutter, consider using a backend endpoint to get tokens
      print('GEE Service Account: $_serviceAccountEmail');
      return null;
    } catch (e) {
      print('Error generating access token: $e');
      return null;
    }
  }

  /// Get visualization parameters for different metrics
  static Map<String, dynamic> getVisualizationParams(String metric) {
    switch (metric) {
      case 'ndvi':
        return {
          'min': -0.2,
          'max': 0.8,
          'palette': [
            '#d73027',
            '#f46d43',
            '#fdae61',
            '#fee08b',
            '#ffffbf',
            '#d9ef8b',
            '#a6d96a',
            '#66bd63',
            '#1a9850',
          ],
        };
      case 'evi':
        return {
          'min': -0.2,
          'max': 0.8,
          'palette': [
            '#d73027',
            '#f46d43',
            '#fdae61',
            '#fee08b',
            '#ffffbf',
            '#d9ef8b',
            '#a6d96a',
            '#66bd63',
            '#1a9850',
          ],
        };
      case 'ndwi':
        return {
          'min': -0.5,
          'max': 0.5,
          'palette': [
            '#8b4513',
            '#d2691e',
            '#f4a460',
            '#fffacd',
            '#87ceeb',
            '#4169e1',
            '#00008b',
          ],
        };
      case 'temp':
        return {
          'min': 0,
          'max': 50,
          'palette': [
            '#313695',
            '#4575b4',
            '#74add1',
            '#abd9e9',
            '#e0f3f8',
            '#ffffbf',
            '#fee090',
            '#fdae61',
            '#f46d43',
            '#d73027',
            '#a50026',
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

  /// Get season date range
  static Map<String, String> getSeasonDateRange(int year, String season) {
    switch (season) {
      case 'winter':
        return {'start': '$year-12-01', 'end': '${year + 1}-02-28'};
      case 'spring':
        return {'start': '$year-03-01', 'end': '$year-05-31'};
      case 'summer':
        return {'start': '$year-06-01', 'end': '$year-08-31'};
      case 'autumn':
        return {'start': '$year-09-01', 'end': '$year-11-30'};
      case 'all':
      default:
        return {'start': '$year-01-01', 'end': '$year-12-31'};
    }
  }

  /// Build the Earth Engine expression for the metric
  static String getMetricExpression(String metric) {
    switch (metric) {
      case 'ndvi':
        return '(NIR - RED) / (NIR + RED)';
      case 'evi':
        return '2.5 * ((NIR - RED) / (NIR + 6 * RED - 7.5 * BLUE + 1))';
      case 'ndwi':
        return '(GREEN - NIR) / (GREEN + NIR)';
      case 'temp':
        return 'ST_B10'; // Surface temperature band
      default:
        return '(NIR - RED) / (NIR + RED)';
    }
  }

  /// Generate a map tile URL for the given parameters
  /// This creates a URL template that can be used with flutter_map TileLayer
  ///
  /// Returns a tile URL template with {z}/{x}/{y} placeholders
  static Future<GeeMapResponse?> getMapTiles({
    required int year,
    required String season,
    required String metric,
    required List<List<double>>
    regionCoordinates, // Polygon coordinates in WGS84
  }) async {
    if (!isInitialized) {
      throw Exception('GeeService not initialized. Call initialize() first.');
    }

    try {
      final dateRange = getSeasonDateRange(year, season);
      final visParams = getVisualizationParams(metric);

      // Build the Earth Engine API request
      // This creates a computation request that generates map tiles
      final requestBody = _buildComputationRequest(
        metric: metric,
        startDate: dateRange['start']!,
        endDate: dateRange['end']!,
        visParams: visParams,
        regionCoordinates: regionCoordinates,
      );

      final response = await _dio.post(
        '$_geeApiBase/projects/$_projectId/maps',
        data: jsonEncode(requestBody),
        options: Options(
          headers: {
            'Authorization': 'Bearer $_accessToken',
            'Content-Type': 'application/json',
          },
        ),
      );

      if (response.statusCode == 200) {
        final data = response.data;
        return GeeMapResponse(
          tileUrlTemplate: data['urlFormat'] ?? '',
          mapName: data['name'] ?? '',
          attribution: '© Google Earth Engine',
        );
      }

      return null;
    } catch (e) {
      print('Error getting GEE map tiles: $e');
      return null;
    }
  }

  /// Build the computation request body for Earth Engine
  static Map<String, dynamic> _buildComputationRequest({
    required String metric,
    required String startDate,
    required String endDate,
    required Map<String, dynamic> visParams,
    required List<List<double>> regionCoordinates,
  }) {
    // Use Landsat 8/9 Collection 2 for vegetation indices
    // Use MODIS for temperature if needed
    String collection;
    String bandMapping;

    if (metric == 'temp') {
      collection = 'LANDSAT/LC08/C02/T1_L2';
      bandMapping =
          '''
        var image = collection
          .filterDate('$startDate', '$endDate')
          .filterBounds(region)
          .map(function(img) {
            return img.multiply(0.00341802).add(149.0).subtract(273.15);
          })
          .median()
          .select(['ST_B10'], ['temp']);
      ''';
    } else {
      collection = 'LANDSAT/LC08/C02/T1_L2';
      bandMapping =
          '''
        var image = collection
          .filterDate('$startDate', '$endDate')
          .filterBounds(region)
          .map(function(img) {
            var nir = img.select('SR_B5').multiply(0.0000275).add(-0.2);
            var red = img.select('SR_B4').multiply(0.0000275).add(-0.2);
            var green = img.select('SR_B3').multiply(0.0000275).add(-0.2);
            var blue = img.select('SR_B2').multiply(0.0000275).add(-0.2);
            ${_getMetricCalculation(metric)}
          })
          .median();
      ''';
    }

    return {
      'expression': {
        'result': '0',
        'values': {
          '0': {
            'functionInvocationValue': {
              'functionName': 'Map.addLayer',
              'arguments': {
                'eeObject': {
                  'functionInvocationValue': {
                    'functionName': 'Image.visualize',
                    'arguments': {
                      'image': {'argumentReference': 'computedImage'},
                      'min': {'constantValue': visParams['min']},
                      'max': {'constantValue': visParams['max']},
                      'palette': {'constantValue': visParams['palette']},
                    },
                  },
                },
              },
            },
          },
        },
      },
    };
  }

  static String _getMetricCalculation(String metric) {
    switch (metric) {
      case 'ndvi':
        return 'return nir.subtract(red).divide(nir.add(red)).rename("ndvi");';
      case 'evi':
        return '''
          var evi = nir.subtract(red)
            .divide(nir.add(red.multiply(6)).subtract(blue.multiply(7.5)).add(1))
            .multiply(2.5)
            .rename("evi");
          return evi;
        ''';
      case 'ndwi':
        return 'return green.subtract(nir).divide(green.add(nir)).rename("ndwi");';
      default:
        return 'return nir.subtract(red).divide(nir.add(red)).rename("ndvi");';
    }
  }
}

/// Response from GEE map tile generation
class GeeMapResponse {
  final String tileUrlTemplate;
  final String mapName;
  final String attribution;

  GeeMapResponse({
    required this.tileUrlTemplate,
    required this.mapName,
    required this.attribution,
  });
}

/// Color mapping utility for creating local NDVI visualization
class MetricColorMapper {
  /// Get color for a metric value
  static int getColorForValue(double value, String metric) {
    final params = GeeService.getVisualizationParams(metric);
    final min = (params['min'] as num).toDouble();
    final max = (params['max'] as num).toDouble();
    final palette = params['palette'] as List<String>;

    // Normalize value to 0-1 range
    final normalized = ((value - min) / (max - min)).clamp(0.0, 1.0);

    // Get color index
    final colorIndex = (normalized * (palette.length - 1)).floor();
    final nextIndex = (colorIndex + 1).clamp(0, palette.length - 1);

    // Interpolate between colors
    final t = (normalized * (palette.length - 1)) - colorIndex;

    final color1 = _parseHexColor(palette[colorIndex]);
    final color2 = _parseHexColor(palette[nextIndex]);

    return _interpolateColor(color1, color2, t);
  }

  static int _parseHexColor(String hex) {
    hex = hex.replaceFirst('#', '');
    if (hex.length == 6) {
      hex = 'FF$hex';
    }
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

  /// Get the color palette for legend display
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
