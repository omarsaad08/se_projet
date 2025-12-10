import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'dart:convert';
import 'package:se_project/data/gee_service.dart';
import 'package:se_project/presentation/components/pixel_wise_map_widget.dart';

class PixelWisePage extends StatefulWidget {
  const PixelWisePage({Key? key}) : super(key: key);

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

  // Constants
  static const List<String> metrics = ['ndvi', 'evi', 'ndwi', 'temp'];
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
    _initializeGee();
  }

  Future<void> _initializeGee() async {
    try {
      // Initialize GEE with your service account credentials
      GeeService.initialize(
        projectId: 'drhaithamproject',
        serviceAccountEmail:
            'earthengine-service@drhaithamproject.iam.gserviceaccount.com',
        privateKey: r'''-----BEGIN PRIVATE KEY-----
MIIEvgIBADANBgkqhkiG9w0BAQEFAASCBKgwggSkAgEAAoIBAQChlp3JsPgNxS84
atsewr3W+T7myDGqf/JNL10wfbkFMDzMKY9m5KRxcUYxMrqR3Ax92XRx5MIkOpyP
V75mFfyWK4/wg+KLN79qpiehJ75OFrsX3s27qtA5JWgVc3tzDcF7jRzl/hnMWXlA
g3BFlkqq4Yl3b44C6dhVvxpnp6T0qx7qV3GWoAV2IlTAcnJfa5X+fvx6TPmZTfQ8
QpObjVuvy0UZJBPoLEZq9uImIRoIrmXWueWD/vFMlppZoeIex+oFkL23KfJ56eVr
1EZcd7IkRhaNX2BLzCW1kKrtxCXIVY4jSwVRr3wtjCm78/PwgSpBBx81/k932RDI
HKFDDvYTAgMBAAECggEABH3m2NQ+nZCFdHGsjTu1na9tCNiTqW91ynwy7lOmExd9
ruE1KaXYvKyPNeGdesuCE/U5mTkxoT4LkoTKZYLL9DK1qdQkI6q51tGc4fniEOTt
S36A1yMFycRP7nS42yT6Y7KhS/MgGy2d1VOfwCCZL8MBYZyjCVKyXyz5I27vObvg
Y09IvPznzh5u//L5BGy/BtYidjBJByVqNKI9GlH5jV6lQnN7ZveIV2rfbnypiuit
9Iaarv8RMq2jYsBz58YicBNbsAxFFR4rvakx7PXN8OEBqVmPNeVqSfBLVIR/sMyQ
Dj9F8yuVBhSGBcxxR9mZjWjE/UIbjQk24l/oqxACPQKBgQDdQtd3tiZslapb2jlI
mVVznUw+HQrVLptzkd9B2Ke7R0mboiFr6Cs/XfhjZm3vBC5/U6b1iUqHFqP77e7g
uLD8HsPfSFv38xeyE6rRNYeD5dKwUjYVoHDfKnB7gNMAVTjOe1BUVbQM/KxkbAqi
wfwpu7tDCNVGrW82HYPYxClNDwKBgQC69Vg97mqmkwH84WjGSfgPOh7gzo3iDNOy
UCF98nFK8V3e/W915rgk1povGlfVwE4x7FDyvtj2m3zK6USQSYxOI6eX/AtwPTuH
/fdZfNrV1IZqC50pyJZhBa3LChQ8w7S2gkNkv9MOrheX8E0tNQ9/6YNeyYboz9i0
6fDaoIHOvQKBgQDIIv3jOs/myDoge3P1Rz0UJuQgCwURb+cM0pWvadnOfN0H+c9h
W9BCsS1MPAqUeKPWaERNNLJFHyWVa9L3UhhE9U8XWMxXq3tziHaqZlD97ZR2COcD
CO0P78Nu80fotS19F+3BWwRR+vu0mkXEktMUrMrmB8di9t3xhSENoeH54QKBgQCA
i9LpejWAZNHYExBcTl2t8pNqlPr/MzyXfPsaQwlcswqNGQp7MXDpe1i2DFHaWYgq
UUbzMP+yyAQM7EjFQJyk2WURXi5rNN7qyVc6A1vf7GmjHmsoYI/tE9+EHGD/yrxF
RNmbuz0d+dulD4exDquikmdOVBhbmRVyhuuhFv1JrQKBgAwgt5Mkw6Hbl0VLFkbr
uLfeJOuf9dO/q0UgSoRp0hx977U2o/Q/AMEgMz/MH7D6xjLyGAffN/O0DcmonyoH
bU/h87iK2BDFkuFu0K8/EshDH84ifAFnWCmW39ne5BH2+ApXevjSpvWKVFvndPPQ
OXnekbnUUAR7xhpyttxt/2j+
-----END PRIVATE KEY-----''',
      );

      setState(() {
        isGeeConfigured = true;
      });

      print('GEE initialized successfully!');
    } catch (e) {
      print('Error initializing GEE: $e');
      setState(() {
        errorMessage = 'Error initializing GEE: $e';
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
          int areaId = properties?['OBJECTID'] ?? (i + 1);

          areas.add({'id': areaId, 'name': areaName, 'index': i});
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
      showOverlay = true;
    });

    // Simulate loading for demo purposes
    // In production, this would call GeeService.getMapTiles()
    await Future.delayed(const Duration(seconds: 1));

    setState(() {
      isMapLoading = false;
    });
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
      // Get bounds of selected area
      final areaIndex =
          availableAreas.firstWhere(
                (a) => a['id'].toString() == selectedAreaId,
                orElse: () => {'index': 0},
              )['index']
              as int;

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
          // Note: GeoJSON is [longitude, latitude]
          // The file uses EPSG:32635 (UTM zone 35N), we need to convert to WGS84
          // For now, assuming coordinates are already in WGS84 format
          points.add(LatLng(coord[1].toDouble(), coord[0].toDouble()));
        }
      }
    } else if (type == 'MultiPolygon') {
      for (var polygon in coordinates) {
        for (var ring in polygon) {
          for (var coord in ring) {
            points.add(LatLng(coord[1].toDouble(), coord[0].toDouble()));
          }
        }
      }
    }

    return points;
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
      body: Row(
        children: [
          // Left Panel - Filters
          Container(
            width: 320,
            decoration: BoxDecoration(
              border: Border(right: BorderSide(color: Colors.grey.shade300)),
            ),
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title
                  Text(
                    'Map Filters',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 16),

                  // Metric Selector
                  Text('Metric', style: Theme.of(context).textTheme.labelLarge),
                  const SizedBox(height: 4),
                  DropdownButtonFormField<String>(
                    value: selectedMetric,
                    isExpanded: true,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(
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
                  Text('Area', style: Theme.of(context).textTheme.labelLarge),
                  const SizedBox(height: 4),
                  DropdownButtonFormField<String>(
                    value: selectedAreaId,
                    isExpanded: true,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(
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
                          value: area['id'].toString(),
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
                  Text('Season', style: Theme.of(context).textTheme.labelLarge),
                  const SizedBox(height: 4),
                  DropdownButtonFormField<String>(
                    value: selectedSeason,
                    isExpanded: true,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(
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
                  Text('Year', style: Theme.of(context).textTheme.labelLarge),
                  const SizedBox(height: 4),
                  DropdownButtonFormField<int>(
                    value: selectedYear,
                    isExpanded: true,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(
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
                        color: Colors.red.shade100,
                        border: Border.all(color: Colors.red),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        errorMessage!,
                        style: TextStyle(color: Colors.red.shade700),
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
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.map),
                      label: Text(isMapLoading ? 'Loading...' : 'Generate Map'),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
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
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Legend
                  if (showOverlay) ...[
                    Text(
                      'Legend',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    _buildLegend(),
                  ],

                  const SizedBox(height: 24),

                  // Info Card
                  Card(
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
                                color: Colors.blue.shade700,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Current Selection',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.blue.shade700,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text('Metric: ${getMetricLabel(selectedMetric)}'),
                          Text('Season: ${getSeasonLabel(selectedSeason)}'),
                          Text('Year: $selectedYear'),
                          Text(
                            'Area: ${selectedAreaId == 'all' ? 'All Areas' : availableAreas.firstWhere((a) => a['id'].toString() == selectedAreaId, orElse: () => {'name': 'Unknown'})['name']}',
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
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            getMetricLabel(selectedMetric),
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
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
                style: const TextStyle(fontSize: 10),
              ),
              Text(
                legendItems.last.label,
                style: const TextStyle(fontSize: 10),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
