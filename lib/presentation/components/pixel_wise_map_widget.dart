import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'dart:math' as math;
import 'package:se_project/data/gee_service.dart';

/// A Flutter Map widget with pixel-wise environmental data overlay
class PixelWiseMapWidget extends StatefulWidget {
  final MapController mapController;
  final Map<String, dynamic>? geoJsonData;
  final String selectedAreaId;
  final String selectedMetric;
  final int selectedYear;
  final String selectedSeason;
  final bool showOverlay;
  final List<Map<String, dynamic>> availableAreas;

  const PixelWiseMapWidget({
    Key? key,
    required this.mapController,
    required this.geoJsonData,
    required this.selectedAreaId,
    required this.selectedMetric,
    required this.selectedYear,
    required this.selectedSeason,
    required this.showOverlay,
    required this.availableAreas,
  }) : super(key: key);

  @override
  State<PixelWiseMapWidget> createState() => _PixelWiseMapWidgetState();
}

class _PixelWiseMapWidgetState extends State<PixelWiseMapWidget> {
  // Default center of Egypt
  static const LatLng egyptCenter = LatLng(26.8206, 30.8025);

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        FlutterMap(
          mapController: widget.mapController,
          options: MapOptions(
            initialCenter: egyptCenter,
            initialZoom: 6.0,
            minZoom: 3.0,
            maxZoom: 18.0,
          ),
          children: [
            // Base map layer (OpenStreetMap)
            TileLayer(
              urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
              userAgentPackageName: 'com.example.se_project',
              maxZoom: 19,
            ),

            // GeoJSON polygon layer for protected areas
            if (widget.geoJsonData != null)
              PolygonLayer(polygons: _buildPolygons()),

            // Pixel-wise overlay layer (simulated with gradient polygons)
            if (widget.showOverlay && widget.geoJsonData != null)
              PolygonLayer(polygons: _buildOverlayPolygons()),

            // Area labels
            if (widget.geoJsonData != null)
              MarkerLayer(markers: _buildAreaLabels()),
          ],
        ),

        // Map controls overlay
        Positioned(
          top: 16,
          right: 16,
          child: Column(
            children: [
              _buildMapControl(
                icon: Icons.add,
                onPressed: () {
                  final currentZoom = widget.mapController.camera.zoom;
                  widget.mapController.move(
                    widget.mapController.camera.center,
                    currentZoom + 1,
                  );
                },
              ),
              const SizedBox(height: 8),
              _buildMapControl(
                icon: Icons.remove,
                onPressed: () {
                  final currentZoom = widget.mapController.camera.zoom;
                  widget.mapController.move(
                    widget.mapController.camera.center,
                    currentZoom - 1,
                  );
                },
              ),
              const SizedBox(height: 8),
              _buildMapControl(
                icon: Icons.my_location,
                onPressed: () {
                  widget.mapController.move(egyptCenter, 6.0);
                },
              ),
            ],
          ),
        ),

        // Attribution
        Positioned(
          bottom: 4,
          right: 4,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.8),
              borderRadius: BorderRadius.circular(4),
            ),
            child: const Text(
              '© OpenStreetMap contributors | GEE',
              style: TextStyle(fontSize: 10),
            ),
          ),
        ),

        // Loading indicator when showOverlay is true but still loading
        if (widget.showOverlay)
          Positioned(
            top: 16,
            left: 16,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 4,
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: Colors.green,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '${widget.selectedMetric.toUpperCase()} - ${widget.selectedYear}',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildMapControl({
    required IconData icon,
    required VoidCallback onPressed,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(4),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 4),
        ],
      ),
      child: IconButton(
        icon: Icon(icon, size: 20),
        onPressed: onPressed,
        constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
        padding: EdgeInsets.zero,
      ),
    );
  }

  /// Build polygon layers from GeoJSON
  List<Polygon> _buildPolygons() {
    if (widget.geoJsonData == null) return [];

    final features = widget.geoJsonData!['features'] as List;
    final polygons = <Polygon>[];

    for (int i = 0; i < features.length; i++) {
      final feature = features[i] as Map<String, dynamic>;
      final properties = feature['properties'] as Map<String, dynamic>?;
      final areaId = properties?['OBJECTID']?.toString() ?? (i + 1).toString();

      final isSelected =
          widget.selectedAreaId == 'all' || widget.selectedAreaId == areaId;

      final featurePolygons = _parseGeometry(
        feature['geometry'] as Map<String, dynamic>,
        isSelected: isSelected,
        showOverlay: false, // Border only
      );

      polygons.addAll(featurePolygons);
    }

    return polygons;
  }

  /// Build overlay polygons with metric-based coloring
  List<Polygon> _buildOverlayPolygons() {
    if (widget.geoJsonData == null || !widget.showOverlay) return [];

    final features = widget.geoJsonData!['features'] as List;
    final polygons = <Polygon>[];

    for (int i = 0; i < features.length; i++) {
      final feature = features[i] as Map<String, dynamic>;
      final properties = feature['properties'] as Map<String, dynamic>?;
      final areaId = properties?['OBJECTID']?.toString() ?? (i + 1).toString();

      final isSelected =
          widget.selectedAreaId == 'all' || widget.selectedAreaId == areaId;

      if (!isSelected) continue;

      // Generate simulated pixel-wise data for demo
      // In production, this would come from GEE
      final featurePolygons = _parseGeometryWithOverlay(
        feature['geometry'] as Map<String, dynamic>,
        areaIndex: i,
      );

      polygons.addAll(featurePolygons);
    }

    return polygons;
  }

  List<Polygon> _parseGeometry(
    Map<String, dynamic> geometry, {
    required bool isSelected,
    required bool showOverlay,
  }) {
    final type = geometry['type'] as String;
    final coordinates = geometry['coordinates'];
    final polygons = <Polygon>[];

    if (type == 'Polygon') {
      final points = _parsePolygonCoordinates(coordinates[0]);
      if (points.isNotEmpty) {
        polygons.add(
          Polygon(
            points: points,
            color: isSelected
                ? Colors.blue.withOpacity(0.1)
                : Colors.grey.withOpacity(0.05),
            borderColor: isSelected ? Colors.blue : Colors.grey,
            borderStrokeWidth: isSelected ? 2.0 : 1.0,
          ),
        );
      }
    } else if (type == 'MultiPolygon') {
      for (var polygon in coordinates) {
        final points = _parsePolygonCoordinates(polygon[0]);
        if (points.isNotEmpty) {
          polygons.add(
            Polygon(
              points: points,
              color: isSelected
                  ? Colors.blue.withOpacity(0.1)
                  : Colors.grey.withOpacity(0.05),
              borderColor: isSelected ? Colors.blue : Colors.grey,
              borderStrokeWidth: isSelected ? 2.0 : 1.0,
            ),
          );
        }
      }
    }

    return polygons;
  }

  /// Parse geometry and create pixel-wise overlay with gradient colors
  List<Polygon> _parseGeometryWithOverlay(
    Map<String, dynamic> geometry, {
    required int areaIndex,
  }) {
    final type = geometry['type'] as String;
    final coordinates = geometry['coordinates'];
    final polygons = <Polygon>[];

    // Create a grid of smaller polygons to simulate pixel-wise data
    if (type == 'Polygon') {
      polygons.addAll(_createPixelGrid(coordinates[0], areaIndex));
    } else if (type == 'MultiPolygon') {
      for (var polygon in coordinates) {
        polygons.addAll(_createPixelGrid(polygon[0], areaIndex));
      }
    }

    return polygons;
  }

  /// Create a grid of colored cells to simulate pixel-wise visualization
  List<Polygon> _createPixelGrid(List coordinates, int areaIndex) {
    final polygons = <Polygon>[];
    final points = _parsePolygonCoordinates(coordinates);

    if (points.isEmpty) return polygons;

    // Calculate bounding box
    double minLat = points.first.latitude;
    double maxLat = points.first.latitude;
    double minLng = points.first.longitude;
    double maxLng = points.first.longitude;

    for (var point in points) {
      if (point.latitude < minLat) minLat = point.latitude;
      if (point.latitude > maxLat) maxLat = point.latitude;
      if (point.longitude < minLng) minLng = point.longitude;
      if (point.longitude > maxLng) maxLng = point.longitude;
    }

    // Create grid cells
    // Adjust grid size based on area size for performance
    final latRange = maxLat - minLat;
    final lngRange = maxLng - minLng;

    // Dynamic grid size based on area
    int gridRows = math.min(20, math.max(5, (latRange * 10).round()));
    int gridCols = math.min(20, math.max(5, (lngRange * 10).round()));

    final cellHeight = latRange / gridRows;
    final cellWidth = lngRange / gridCols;

    // Random seed based on year, season, and area for consistent "data"
    final seed =
        widget.selectedYear * 1000 + widget.selectedSeason.hashCode + areaIndex;
    final random = math.Random(seed);

    for (int row = 0; row < gridRows; row++) {
      for (int col = 0; col < gridCols; col++) {
        final cellMinLat = minLat + row * cellHeight;
        final cellMaxLat = minLat + (row + 1) * cellHeight;
        final cellMinLng = minLng + col * cellWidth;
        final cellMaxLng = minLng + (col + 1) * cellWidth;

        // Cell center
        final centerLat = (cellMinLat + cellMaxLat) / 2;
        final centerLng = (cellMinLng + cellMaxLng) / 2;

        // Check if cell center is inside the polygon
        if (!_isPointInPolygon(LatLng(centerLat, centerLng), points)) {
          continue;
        }

        // Generate simulated metric value
        // This creates a gradient effect with some noise
        final baseValue = _getBaseValueForMetric(widget.selectedMetric);
        final latFactor = (row / gridRows);
        final lngFactor = (col / gridCols);
        final noise = (random.nextDouble() - 0.5) * 0.3;

        // Create spatial pattern
        double value =
            baseValue + (latFactor * 0.3) + (lngFactor * 0.2) + noise;

        // Clamp to valid range
        value = value.clamp(-0.5, 1.0);

        // Get color for this value
        final colorInt = MetricColorMapper.getColorForValue(
          value,
          widget.selectedMetric,
        );
        final color = Color(colorInt).withOpacity(0.7);

        // Create cell polygon
        final cellPoints = [
          LatLng(cellMinLat, cellMinLng),
          LatLng(cellMinLat, cellMaxLng),
          LatLng(cellMaxLat, cellMaxLng),
          LatLng(cellMaxLat, cellMinLng),
        ];

        polygons.add(
          Polygon(
            points: cellPoints,
            color: color,
            borderColor: color,
            borderStrokeWidth: 0.5,
          ),
        );
      }
    }

    return polygons;
  }

  double _getBaseValueForMetric(String metric) {
    switch (metric) {
      case 'ndvi':
        return 0.3 + (widget.selectedSeason == 'summer' ? 0.2 : 0.0);
      case 'evi':
        return 0.25 + (widget.selectedSeason == 'summer' ? 0.15 : 0.0);
      case 'ndwi':
        return -0.1 + (widget.selectedSeason == 'winter' ? 0.2 : 0.0);
      case 'temp':
        return 0.5 + (widget.selectedSeason == 'summer' ? 0.3 : -0.2);
      default:
        return 0.5;
    }
  }

  /// Check if a point is inside a polygon using ray casting
  bool _isPointInPolygon(LatLng point, List<LatLng> polygon) {
    bool inside = false;
    int j = polygon.length - 1;

    for (int i = 0; i < polygon.length; i++) {
      if ((polygon[i].longitude > point.longitude) !=
              (polygon[j].longitude > point.longitude) &&
          point.latitude <
              (polygon[j].latitude - polygon[i].latitude) *
                      (point.longitude - polygon[i].longitude) /
                      (polygon[j].longitude - polygon[i].longitude) +
                  polygon[i].latitude) {
        inside = !inside;
      }
      j = i;
    }

    return inside;
  }

  List<LatLng> _parsePolygonCoordinates(List coordinates) {
    final points = <LatLng>[];

    for (var coord in coordinates) {
      if (coord is List && coord.length >= 2) {
        // GeoJSON format: [longitude, latitude]
        // The file uses EPSG:32635 (UTM), need to check if conversion is needed
        double lng = (coord[0] as num).toDouble();
        double lat = (coord[1] as num).toDouble();

        // Check if coordinates are in UTM format (large numbers)
        // UTM coordinates are typically in meters, so values > 180 indicate UTM
        if (lng.abs() > 180 || lat.abs() > 90) {
          // Convert from UTM Zone 35N (EPSG:32635) to WGS84
          final converted = _utmToLatLng(lng, lat, 35, true);
          points.add(converted);
        } else {
          points.add(LatLng(lat, lng));
        }
      }
    }

    return points;
  }

  /// Convert UTM coordinates to Lat/Lng (WGS84)
  /// zone: UTM zone number
  /// northern: true for northern hemisphere
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

  /// Build markers for area labels
  List<Marker> _buildAreaLabels() {
    if (widget.geoJsonData == null) return [];

    final features = widget.geoJsonData!['features'] as List;
    final markers = <Marker>[];

    for (int i = 0; i < features.length; i++) {
      final feature = features[i] as Map<String, dynamic>;
      final properties = feature['properties'] as Map<String, dynamic>?;
      final areaId = properties?['OBJECTID']?.toString() ?? (i + 1).toString();

      final isSelected =
          widget.selectedAreaId == 'all' || widget.selectedAreaId == areaId;

      if (!isSelected) continue;

      // Get center of the polygon for label placement
      final center = _getPolygonCenter(
        feature['geometry'] as Map<String, dynamic>,
      );
      if (center == null) continue;

      final areaName =
          properties?['اسم__12'] ?? properties?['اسم__1'] ?? 'Area ${i + 1}';

      markers.add(
        Marker(
          point: center,
          width: 150,
          height: 40,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.9),
              borderRadius: BorderRadius.circular(4),
              boxShadow: [
                BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 4),
              ],
            ),
            child: Text(
              areaName.toString(),
              style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ),
      );
    }

    return markers;
  }

  LatLng? _getPolygonCenter(Map<String, dynamic> geometry) {
    final type = geometry['type'] as String;
    final coordinates = geometry['coordinates'];

    List coords;
    if (type == 'Polygon') {
      coords = coordinates[0];
    } else if (type == 'MultiPolygon') {
      coords = coordinates[0][0];
    } else {
      return null;
    }

    final points = _parsePolygonCoordinates(coords);
    if (points.isEmpty) return null;

    double sumLat = 0;
    double sumLng = 0;

    for (var point in points) {
      sumLat += point.latitude;
      sumLng += point.longitude;
    }

    return LatLng(sumLat / points.length, sumLng / points.length);
  }
}
