import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'dart:convert';
import 'dart:math' as math;
import 'package:se_project/data/gee_service.dart';
import 'package:se_project/presentation/components/pixel_wise_map_widget.dart';
import 'package:se_project/helpers/app_theme.dart';

class PixelWisePage extends StatefulWidget {
  const PixelWisePage({super.key});

  @override
  State<PixelWisePage> createState() => _PixelWisePageState();
}

class _PixelWisePageState extends State<PixelWisePage> {
  // Dropdown values
  String selectedMetric = 'ndvi';
  String selectedSeason = 'all';
  String selectedAreaId = 'all';
  int selectedYear = 2023;

  // Data
  List<Map<String, dynamic>> availableAreas = [];
  Map<String, dynamic>? geoJsonData;
  bool isLoading = false;
  bool isMapLoading = false;
  String? errorMessage;
  bool showOverlay = false;

  // GEE Configuration
  bool isGeeConfigured = false;

  // GEE Map Response
  GeeMapResponse? geeMapResponse;

  // Constants
  static const List<String> metrics = [
    'ndvi',
    'evi',
    'ndwi',
    'savi',
    'ndmi',
    'ndbi',
    'temp',
  ];
  static const List<String> seasons = [
    'all',
    'winter',
    'spring',
    'summer',
    'autumn',
  ];
  static const int minYear = 2013; // Landsat 8 started in 2013
  static const int maxYear = 2024;

  // Map controller
  final MapController _mapController = MapController();

  @override
  void initState() {
    super.initState();
    _loadGeoJson();
    _checkServerHealth();
  }

  Future<void> _checkServerHealth() async {
    try {
      final isHealthy = await GeeService.checkServerHealth();
      setState(() {
        isGeeConfigured = isHealthy;
      });
      if (isHealthy) {
        print('Python GEE server is running!');
      } else {
        print(
          'Python GEE server is not running. Please start it with: python gee_server/server.py',
        );
      }
    } catch (e) {
      print('Error checking server health: $e');
      setState(() {
        isGeeConfigured = false;
      });
    }
  }

  Future<void> _loadGeoJson() async {
    try {
      final String jsonString = await rootBundle.loadString(
        'assets/ProtectedAreas.geojson',
      );
      final data = jsonDecode(jsonString) as Map<String, dynamic>;

      setState(() {
        geoJsonData = data;
      });

      // Extract area names/IDs from GeoJSON features
      if (data['features'] != null) {
        final features = data['features'] as List;
        final areas = <Map<String, dynamic>>[];

        for (int i = 0; i < features.length; i++) {
          final feature = features[i] as Map<String, dynamic>;
          final properties = feature['properties'] as Map<String, dynamic>?;

          // Get area name from properties
          String areaName =
              properties?['اسم__12'] ??
              properties?['اسم__1'] ??
              'Area ${i + 1}';
          // Use index as unique identifier since OBJECTID may have duplicates
          areas.add({'id': i, 'name': areaName, 'index': i});
        }

        setState(() {
          availableAreas = areas;
        });
      }
    } catch (e) {
      print("Error loading GeoJSON: $e");
      setState(() {
        errorMessage = 'Error loading area data: $e';
      });
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
      case 'savi':
        return 'SAVI (Soil-Adjusted Vegetation)';
      case 'ndmi':
        return 'NDMI (Moisture Index)';
      case 'ndbi':
        return 'NDBI (Built-up Index)';
      case 'temp':
        return 'Temperature (°C)';
      default:
        return metric.toUpperCase();
    }
  }

  String getSeasonLabel(String season) {
    switch (season) {
      case 'all':
        return 'All Seasons (Full Year)';
      case 'winter':
        return 'Winter (Dec-Feb)';
      case 'spring':
        return 'Spring (Mar-May)';
      case 'summer':
        return 'Summer (Jun-Aug)';
      case 'autumn':
        return 'Autumn (Sep-Nov)';
      default:
        return season;
    }
  }

  void _showGeeConfigDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Google Earth Engine Status'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    isGeeConfigured ? Icons.check_circle : Icons.error_outline,
                    color: isGeeConfigured ? Colors.green : Colors.red,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      isGeeConfigured
                          ? 'Google Earth Engine is configured!'
                          : 'GEE not configured.',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: isGeeConfigured ? Colors.green : Colors.red,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              if (isGeeConfigured) ...[
                const Text(
                  'Service Account: earthengine-service@drhaithamproject.iam.gserviceaccount.com',
                ),
                const SizedBox(height: 8),
                const Text('Project: drhaithamproject'),
                const SizedBox(height: 8),
                const Text('Status: Connected ✓'),
              ] else ...[
                const Text('There was an error initializing GEE.'),
                const SizedBox(height: 8),
                const Text('Please check your credentials and restart.'),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
            },
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Future<void> _generateMap() async {
    setState(() {
      isMapLoading = true;
      errorMessage = null;
      geeMapResponse = null;
    });

    try {
      // Call GEE service to get map tiles
      final response = await GeeService.getMapTiles(
        year: selectedYear,
        season: selectedSeason,
        metric: selectedMetric,
      );

      if (response != null) {
        setState(() {
          geeMapResponse = response;
          showOverlay = true;
          isMapLoading = false;
        });
        print('GEE Map tiles ready: ${response.tileUrlTemplate}');
      } else {
        setState(() {
          errorMessage =
              'Failed to generate map. Please check GEE configuration.';
          isMapLoading = false;
          showOverlay = false;
        });
      }
    } catch (e) {
      setState(() {
        errorMessage = 'Error generating map: $e';
        isMapLoading = false;
        showOverlay = false;
      });
      print('Error in _generateMap: $e');
    }
  }

  /// Get the bounds of a specific area or all areas
  LatLngBounds? _getAreaBounds() {
    if (geoJsonData == null) return null;

    final features = geoJsonData!['features'] as List;
    List<LatLng> allPoints = [];

    if (selectedAreaId == 'all') {
      // Get bounds of all areas
      for (var feature in features) {
        allPoints.addAll(_extractPointsFromFeature(feature));
      }
    } else {
      // Get bounds of selected area - selectedAreaId is now the index
      final areaIndex = int.tryParse(selectedAreaId) ?? 0;

      if (areaIndex < features.length) {
        allPoints = _extractPointsFromFeature(features[areaIndex]);
      }
    }

    if (allPoints.isEmpty) return null;

    double minLat = allPoints.first.latitude;
    double maxLat = allPoints.first.latitude;
    double minLng = allPoints.first.longitude;
    double maxLng = allPoints.first.longitude;

    for (var point in allPoints) {
      if (point.latitude < minLat) minLat = point.latitude;
      if (point.latitude > maxLat) maxLat = point.latitude;
      if (point.longitude < minLng) minLng = point.longitude;
      if (point.longitude > maxLng) maxLng = point.longitude;
    }

    return LatLngBounds(LatLng(minLat, minLng), LatLng(maxLat, maxLng));
  }

  List<LatLng> _extractPointsFromFeature(Map<String, dynamic> feature) {
    final geometry = feature['geometry'] as Map<String, dynamic>;
    final type = geometry['type'] as String;
    final coordinates = geometry['coordinates'];

    List<LatLng> points = [];

    if (type == 'Polygon') {
      for (var ring in coordinates) {
        for (var coord in ring) {
          points.add(_parseCoordinate(coord));
        }
      }
    } else if (type == 'MultiPolygon') {
      for (var polygon in coordinates) {
        for (var ring in polygon) {
          for (var coord in ring) {
            points.add(_parseCoordinate(coord));
          }
        }
      }
    }

    return points;
  }

  /// Parse a coordinate and convert from UTM to WGS84 if needed
  LatLng _parseCoordinate(List coord) {
    double lng = (coord[0] as num).toDouble();
    double lat = (coord[1] as num).toDouble();

    // Check if coordinates are in UTM format (large numbers)
    // UTM coordinates are typically in meters, so values > 180 indicate UTM
    if (lng.abs() > 180 || lat.abs() > 90) {
      // Convert from UTM Zone 35N (EPSG:32635) to WGS84
      return _utmToLatLng(lng, lat, 35, true);
    } else {
      return LatLng(lat, lng);
    }
  }

  /// Convert UTM coordinates to Lat/Lng (WGS84)
  LatLng _utmToLatLng(
    double easting,
    double northing,
    int zone,
    bool northern,
  ) {
    // WGS84 ellipsoid parameters
    const double a = 6378137.0; // Semi-major axis
    const double f = 1 / 298.257223563; // Flattening
    const double k0 = 0.9996; // Scale factor

    final double e = math.sqrt(2 * f - f * f); // Eccentricity
    final double e2 = e * e;
    final double e1 = (1 - math.sqrt(1 - e2)) / (1 + math.sqrt(1 - e2));

    // Remove false easting and northing
    final double x = easting - 500000.0;
    double y = northing;
    if (!northern) {
      y = y - 10000000.0;
    }

    // Central meridian
    final double lonOrigin = (zone - 1) * 6 - 180 + 3;

    final double M = y / k0;
    final double mu =
        M / (a * (1 - e2 / 4 - 3 * e2 * e2 / 64 - 5 * e2 * e2 * e2 / 256));

    final double phi1 =
        mu +
        (3 * e1 / 2 - 27 * e1 * e1 * e1 / 32) * math.sin(2 * mu) +
        (21 * e1 * e1 / 16 - 55 * e1 * e1 * e1 * e1 / 32) * math.sin(4 * mu) +
        (151 * e1 * e1 * e1 / 96) * math.sin(6 * mu);

    final double sinPhi1 = math.sin(phi1);
    final double cosPhi1 = math.cos(phi1);
    final double tanPhi1 = math.tan(phi1);

    final double N1 = a / math.sqrt(1 - e2 * sinPhi1 * sinPhi1);
    final double T1 = tanPhi1 * tanPhi1;
    final double C1 = e2 / (1 - e2) * cosPhi1 * cosPhi1;
    final double R1 = a * (1 - e2) / math.pow(1 - e2 * sinPhi1 * sinPhi1, 1.5);
    final double D = x / (N1 * k0);

    double lat =
        phi1 -
        (N1 * tanPhi1 / R1) *
            (D * D / 2 -
                (5 + 3 * T1 + 10 * C1 - 4 * C1 * C1 - 9 * e2 / (1 - e2)) *
                    D *
                    D *
                    D *
                    D /
                    24 +
                (61 +
                        90 * T1 +
                        298 * C1 +
                        45 * T1 * T1 -
                        252 * e2 / (1 - e2) -
                        3 * C1 * C1) *
                    D *
                    D *
                    D *
                    D *
                    D *
                    D /
                    720);

    double lon =
        (D -
            (1 + 2 * T1 + C1) * D * D * D / 6 +
            (5 -
                    2 * C1 +
                    28 * T1 -
                    3 * C1 * C1 +
                    8 * e2 / (1 - e2) +
                    24 * T1 * T1) *
                D *
                D *
                D *
                D *
                D /
                120) /
        cosPhi1;

    lat = lat * 180 / math.pi;
    lon = lonOrigin + lon * 180 / math.pi;

    return LatLng(lat, lon);
  }

  void _zoomToArea() {
    final bounds = _getAreaBounds();
    if (bounds != null) {
      _mapController.fitCamera(
        CameraFit.bounds(bounds: bounds, padding: const EdgeInsets.all(50)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pixel-Wise Environmental Map'),
        elevation: 0,
        actions: [
          // GEE Status indicator
          Container(
            margin: const EdgeInsets.only(right: 16),
            child: Row(
              children: [
                Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isGeeConfigured ? Colors.green : Colors.red,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  isGeeConfigured ? 'GEE Connected' : 'GEE Offline',
                  style: const TextStyle(fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
      body: Row(
        children: [
          // Left Panel - Filters
          Container(
            width: 320,
            decoration: BoxDecoration(
              color: AppTheme.darkBgSecondary,
              border: Border(right: BorderSide(color: AppTheme.darkBgTertiary)),
            ),
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title
                  Text(
                    'Map Filters',
                    style: Theme.of(
                      context,
                    ).textTheme.titleLarge?.copyWith(color: AppTheme.darkText),
                  ),
                  const SizedBox(height: 16),

                  // Metric Selector
                  Text(
                    'Metric',
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      color: AppTheme.darkTextSecondary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  DropdownButtonFormField<String>(
                    initialValue: selectedMetric,
                    isExpanded: true,
                    dropdownColor: AppTheme.darkBgTertiary,
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: AppTheme.darkBgTertiary,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: AppTheme.primaryBlue),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.grey.shade700),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                    ),
                    items: metrics
                        .map(
                          (metric) => DropdownMenuItem(
                            value: metric,
                            child: Text(getMetricLabel(metric)),
                          ),
                        )
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
                  Text(
                    'Area',
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      color: AppTheme.darkTextSecondary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  DropdownButtonFormField<String>(
                    initialValue: selectedAreaId,
                    isExpanded: true,
                    dropdownColor: AppTheme.darkBgTertiary,
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: AppTheme.darkBgTertiary,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: AppTheme.primaryBlue),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.grey.shade700),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                    ),
                    items: [
                      const DropdownMenuItem(
                        value: 'all',
                        child: Text('All Areas'),
                      ),
                      ...availableAreas.map(
                        (area) => DropdownMenuItem(
                          value: area['index'].toString(),
                          child: Text(area['name'].toString()),
                        ),
                      ),
                    ],
                    onChanged: (value) {
                      if (value != null) {
                        setState(() {
                          selectedAreaId = value;
                        });
                        _zoomToArea();
                      }
                    },
                  ),
                  const SizedBox(height: 16),

                  // Season Selector
                  Text(
                    'Season',
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      color: AppTheme.darkTextSecondary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  DropdownButtonFormField<String>(
                    initialValue: selectedSeason,
                    isExpanded: true,
                    dropdownColor: AppTheme.darkBgTertiary,
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: AppTheme.darkBgTertiary,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: AppTheme.primaryBlue),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.grey.shade700),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                    ),
                    items: seasons
                        .map(
                          (season) => DropdownMenuItem(
                            value: season,
                            child: Text(getSeasonLabel(season)),
                          ),
                        )
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

                  // Year Selector
                  Text(
                    'Year',
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      color: AppTheme.darkTextSecondary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  DropdownButtonFormField<int>(
                    initialValue: selectedYear,
                    isExpanded: true,
                    dropdownColor: AppTheme.darkBgTertiary,
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: AppTheme.darkBgTertiary,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: AppTheme.primaryBlue),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.grey.shade700),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                    ),
                    items:
                        List.generate(
                              maxYear - minYear + 1,
                              (index) => maxYear - index,
                            )
                            .map(
                              (year) => DropdownMenuItem(
                                value: year,
                                child: Text('$year'),
                              ),
                            )
                            .toList(),
                    onChanged: (value) {
                      if (value != null) {
                        setState(() {
                          selectedYear = value;
                        });
                      }
                    },
                  ),
                  const SizedBox(height: 24),

                  // Error Message
                  if (errorMessage != null)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppTheme.error.withOpacity(0.2),
                        border: Border.all(color: AppTheme.error),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        errorMessage!,
                        style: TextStyle(color: AppTheme.error),
                      ),
                    ),
                  if (errorMessage != null) const SizedBox(height: 16),

                  // Generate Map Button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: isMapLoading ? null : _generateMap,
                      icon: isMapLoading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(Icons.map),
                      label: Text(isMapLoading ? 'Loading...' : 'Generate Map'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryBlue,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Zoom to Area Button
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: _zoomToArea,
                      icon: const Icon(Icons.zoom_in_map),
                      label: const Text('Zoom to Selected Area'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppTheme.primaryBlue,
                        side: BorderSide(color: AppTheme.primaryBlue),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Legend
                  if (showOverlay) ...[
                    Text(
                      'Legend',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: AppTheme.darkText,
                      ),
                    ),
                    const SizedBox(height: 8),
                    _buildLegend(),
                  ],

                  const SizedBox(height: 24),

                  // Info Card
                  Card(
                    color: AppTheme.darkBgTertiary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.info_outline,
                                size: 20,
                                color: AppTheme.primaryBlue,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Current Selection',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.primaryBlue,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Metric: ${getMetricLabel(selectedMetric)}',
                            style: TextStyle(color: AppTheme.darkTextSecondary),
                          ),
                          Text(
                            'Season: ${getSeasonLabel(selectedSeason)}',
                            style: TextStyle(color: AppTheme.darkTextSecondary),
                          ),
                          Text(
                            'Year: $selectedYear',
                            style: TextStyle(color: AppTheme.darkTextSecondary),
                          ),
                          Text(
                            'Area: ${selectedAreaId == 'all' ? 'All Areas' : availableAreas.firstWhere((a) => a['index'].toString() == selectedAreaId, orElse: () => {'name': 'Unknown'})['name']}',
                            style: TextStyle(color: AppTheme.darkTextSecondary),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Right Panel - Map
          Expanded(
            child: PixelWiseMapWidget(
              mapController: _mapController,
              geoJsonData: geoJsonData,
              selectedAreaId: selectedAreaId,
              selectedMetric: selectedMetric,
              selectedYear: selectedYear,
              selectedSeason: selectedSeason,
              showOverlay: showOverlay,
              availableAreas: availableAreas,
              geeMapResponse: geeMapResponse,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLegend() {
    final legendItems = MetricColorMapper.getLegendItems(selectedMetric);

    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: AppTheme.darkBgTertiary,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            getMetricLabel(selectedMetric),
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 12,
              color: AppTheme.darkText,
            ),
          ),
          const SizedBox(height: 8),
          // Gradient bar
          Container(
            height: 20,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: legendItems.map((item) => Color(item.color)).toList(),
              ),
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          const SizedBox(height: 4),
          // Labels
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                legendItems.first.label,
                style: TextStyle(
                  fontSize: 10,
                  color: AppTheme.darkTextSecondary,
                ),
              ),
              Text(
                legendItems.last.label,
                style: TextStyle(
                  fontSize: 10,
                  color: AppTheme.darkTextSecondary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
