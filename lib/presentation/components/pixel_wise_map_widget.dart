import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'dart:math' as math;
import 'dart:ui' as ui;
import 'dart:typed_data';
// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;
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
  final GeeMapResponse? geeMapResponse;

  const PixelWiseMapWidget({
    super.key,
    required this.mapController,
    required this.geoJsonData,
    required this.selectedAreaId,
    required this.selectedMetric,
    required this.selectedYear,
    required this.selectedSeason,
    required this.showOverlay,
    required this.availableAreas,
    this.geeMapResponse,
  });

  @override
  State<PixelWiseMapWidget> createState() => _PixelWiseMapWidgetState();
}

class _PixelWiseMapWidgetState extends State<PixelWiseMapWidget> {
  // Default center of Egypt
  static const LatLng egyptCenter = LatLng(26.8206, 30.8025);

  // Key for capturing the map as an image
  final GlobalKey _mapKey = GlobalKey();
  bool _isCapturing = false;

  // Pixel info popup state
  PointInfoResponse? _pixelInfo;
  bool _isLoadingPixelInfo = false;
  LatLng? _tappedPoint;

  /// Fetch pixel information when map is tapped
  Future<void> _onMapTap(TapPosition tapPosition, LatLng point) async {
    if (!widget.showOverlay) return; // Only when overlay is visible

    setState(() {
      _isLoadingPixelInfo = true;
      _tappedPoint = point;
      _pixelInfo = null;
    });

    try {
      final result = await GeeService.getPointInfo(
        lat: point.latitude,
        lng: point.longitude,
        year: widget.selectedYear,
        season: widget.selectedSeason,
      );

      if (mounted) {
        setState(() {
          _pixelInfo = result;
          _isLoadingPixelInfo = false;
        });
      }
    } catch (e) {
      print('Error fetching pixel info: $e');
      if (mounted) {
        setState(() {
          _isLoadingPixelInfo = false;
        });
      }
    }
  }

  /// Close the pixel info popup
  void _closePixelInfo() {
    setState(() {
      _pixelInfo = null;
      _tappedPoint = null;
    });
  }

  /// Capture the map as an image and download it
  Future<void> _captureAndDownloadMap() async {
    setState(() {
      _isCapturing = true;
    });

    try {
      // Find the RenderRepaintBoundary
      RenderRepaintBoundary? boundary =
          _mapKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;

      if (boundary == null) {
        _showSnackBar('Error: Could not capture map');
        return;
      }

      // Capture the image at higher resolution for better quality
      ui.Image image = await boundary.toImage(pixelRatio: 2.0);
      ByteData? byteData = await image.toByteData(
        format: ui.ImageByteFormat.png,
      );

      if (byteData == null) {
        _showSnackBar('Error: Could not convert image');
        return;
      }

      Uint8List pngBytes = byteData.buffer.asUint8List();

      // Create filename with area, metric, year, season
      String areaName = widget.selectedAreaId == 'all'
          ? 'AllAreas'
          : 'Area_${widget.selectedAreaId}';
      String filename =
          '${widget.selectedMetric}_${areaName}_${widget.selectedYear}_${widget.selectedSeason}.png';

      // Download the image (web)
      final blob = html.Blob([pngBytes], 'image/png');
      final url = html.Url.createObjectUrlFromBlob(blob);
      final anchor = html.AnchorElement(href: url)
        ..setAttribute('download', filename)
        ..click();
      html.Url.revokeObjectUrl(url);

      _showSnackBar('Map downloaded as $filename');
    } catch (e) {
      print('Error capturing map: $e');
      _showSnackBar('Error downloading map: $e');
    } finally {
      setState(() {
        _isCapturing = false;
      });
    }
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), duration: const Duration(seconds: 3)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        RepaintBoundary(
          key: _mapKey,
          child: FlutterMap(
            mapController: widget.mapController,
            options: MapOptions(
              initialCenter: egyptCenter,
              initialZoom: 6.0,
              minZoom: 3.0,
              maxZoom: 18.0,
              onTap: _onMapTap, // Handle map taps for pixel info
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

              // GEE Tile Layer for environmental data overlay
              if (widget.showOverlay) _buildGeeTileLayer(),

              // Area labels
              if (widget.geoJsonData != null)
                MarkerLayer(markers: _buildAreaLabels()),

              // Marker for tapped point (when loading or showing pixel info)
              if (_tappedPoint != null)
                MarkerLayer(
                  markers: [
                    Marker(
                      point: _tappedPoint!,
                      width: 40,
                      height: 40,
                      child: Icon(
                        Icons.location_pin,
                        color: Colors.red,
                        size: 40,
                        shadows: const [
                          Shadow(color: Colors.black54, blurRadius: 4),
                        ],
                      ),
                    ),
                  ],
                ),
            ],
          ),
        ),

        // Pixel Info Popup
        if (_tappedPoint != null) _buildPixelInfoPopup(),

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
              // Download button - only show when overlay is visible
              if (widget.showOverlay) ...[
                const SizedBox(height: 8),
                _buildMapControl(
                  icon: _isCapturing ? Icons.hourglass_empty : Icons.download,
                  onPressed: _isCapturing
                      ? null
                      : () => _captureAndDownloadMap(),
                  tooltip: 'Download Map Image',
                ),
              ],
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

  /// Build the pixel info popup widget
  Widget _buildPixelInfoPopup() {
    return Positioned(
      bottom: 16,
      left: 16,
      right: 80, // Leave space for map controls
      child: Container(
        constraints: const BoxConstraints(maxWidth: 400),
        decoration: BoxDecoration(
          color: const Color(0xFF1E1E2C),
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.3),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: const Color(0xFF2A2A3C),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(12),
                  topRight: Radius.circular(12),
                ),
              ),
              child: Row(
                children: [
                  Icon(Icons.pin_drop, color: Colors.orange, size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Pixel Information',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ),
                  // Close button
                  InkWell(
                    onTap: _closePixelInfo,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: Colors.red.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Icon(
                        Icons.close,
                        color: Colors.red,
                        size: 16,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Content
            if (_isLoadingPixelInfo)
              const Padding(
                padding: EdgeInsets.all(20),
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.orange,
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Fetching pixel data...',
                        style: TextStyle(color: Colors.white70, fontSize: 12),
                      ),
                    ],
                  ),
                ),
              )
            else if (_pixelInfo == null)
              const Padding(
                padding: EdgeInsets.all(16),
                child: Text(
                  'Error loading pixel data',
                  style: TextStyle(color: Colors.red, fontSize: 12),
                ),
              )
            else if (!_pixelInfo!.success)
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.warning, color: Colors.amber, size: 16),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _pixelInfo!.errorMessage ?? 'No data available',
                            style: const TextStyle(
                              color: Colors.amber,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Coordinates: ${_tappedPoint!.latitude.toStringAsFixed(4)}, ${_tappedPoint!.longitude.toStringAsFixed(4)}',
                      style: const TextStyle(
                        color: Colors.white54,
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
              )
            else
              _buildPixelInfoContent(),
          ],
        ),
      ),
    );
  }

  /// Build the content of the pixel info popup
  Widget _buildPixelInfoContent() {
    final info = _pixelInfo!;
    final metrics = info.metrics ?? {};

    return Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Coordinates
          Row(
            children: [
              Icon(Icons.location_on, color: Colors.blue.shade300, size: 14),
              const SizedBox(width: 6),
              Text(
                '${info.lat?.toStringAsFixed(5)}, ${info.lng?.toStringAsFixed(5)}',
                style: const TextStyle(color: Colors.white70, fontSize: 11),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Interpretation section
          if (info.interpretation != null) ...[
            _buildInterpretationCard(info.interpretation!),
            const SizedBox(height: 10),
          ],

          // Metrics Grid
          Text(
            'Index Values',
            style: TextStyle(
              color: Colors.white.withOpacity(0.9),
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 6),
          Wrap(
            spacing: 8,
            runSpacing: 6,
            children: metrics.entries.map((entry) {
              return _buildMetricChip(
                entry.key,
                info.getMetricDisplay(entry.key),
                entry.key == widget.selectedMetric,
              );
            }).toList(),
          ),

          // Metadata
          if (info.metadata != null) ...[
            const SizedBox(height: 10),
            Divider(color: Colors.white24, height: 1),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.info_outline, color: Colors.white38, size: 12),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    '${info.metadata!['imageCount']} images | ${info.metadata!['resolution']}',
                    style: const TextStyle(color: Colors.white38, fontSize: 10),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  /// Build the interpretation card
  Widget _buildInterpretationCard(Map<String, String> interpretation) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.green.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.green.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (interpretation['landCover'] != null)
            _buildInterpretationRow(
              Icons.landscape,
              'Land Cover',
              interpretation['landCover']!,
              Colors.green,
            ),
          if (interpretation['vegetationHealth'] != null) ...[
            const SizedBox(height: 6),
            _buildInterpretationRow(
              Icons.eco,
              'Vegetation',
              interpretation['vegetationHealth']!,
              Colors.lightGreen,
            ),
          ],
          if (interpretation['moistureStatus'] != null) ...[
            const SizedBox(height: 6),
            _buildInterpretationRow(
              Icons.water_drop,
              'Moisture',
              interpretation['moistureStatus']!,
              Colors.blue,
            ),
          ],
        ],
      ),
    );
  }

  /// Build an interpretation row
  Widget _buildInterpretationRow(
    IconData icon,
    String label,
    String value,
    Color color,
  ) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: color, size: 14),
        const SizedBox(width: 6),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  color: Colors.white54,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                value,
                style: const TextStyle(color: Colors.white, fontSize: 11),
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// Build a metric chip widget
  Widget _buildMetricChip(String key, String value, bool isSelected) {
    final color = isSelected ? Colors.orange : Colors.white54;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: isSelected
            ? Colors.orange.withOpacity(0.15)
            : Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: isSelected ? Colors.orange.withOpacity(0.5) : Colors.white24,
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            key.toUpperCase(),
            style: TextStyle(
              color: color,
              fontSize: 9,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              color: isSelected ? Colors.orange : Colors.white,
              fontSize: 11,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMapControl({
    required IconData icon,
    VoidCallback? onPressed,
    String? tooltip,
  }) {
    final button = Container(
      decoration: BoxDecoration(
        color: onPressed == null ? Colors.grey.shade300 : Colors.white,
        borderRadius: BorderRadius.circular(4),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 4),
        ],
      ),
      child: IconButton(
        icon: Icon(
          icon,
          size: 20,
          color: onPressed == null ? Colors.grey : null,
        ),
        onPressed: onPressed,
        constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
        padding: EdgeInsets.zero,
      ),
    );

    if (tooltip != null) {
      return Tooltip(message: tooltip, child: button);
    }
    return button;
  }

  /// Build polygon layers from GeoJSON
  List<Polygon> _buildPolygons() {
    if (widget.geoJsonData == null) return [];

    final features = widget.geoJsonData!['features'] as List;
    final polygons = <Polygon>[];

    for (int i = 0; i < features.length; i++) {
      final feature = features[i] as Map<String, dynamic>;
      // Use index for selection since OBJECTID may have duplicates
      final isSelected =
          widget.selectedAreaId == 'all' ||
          widget.selectedAreaId == i.toString();

      final featurePolygons = _parseGeometry(
        feature['geometry'] as Map<String, dynamic>,
        isSelected: isSelected,
        showOverlay: false, // Border only
      );

      polygons.addAll(featurePolygons);
    }

    return polygons;
  }

  /// Build GEE Tile Layer for environmental data
  Widget _buildGeeTileLayer() {
    // Check if we have a valid GEE map response
    if (widget.geeMapResponse == null ||
        widget.geeMapResponse!.tileUrlTemplate.isEmpty) {
      return const SizedBox.shrink();
    }

    final response = widget.geeMapResponse!;

    // GEE tiles from Python server already include auth
    // Wrap in Opacity widget to allow base map to show through
    return Opacity(
      opacity: 0.75, // 75% opacity to let the base map show through
      child: TileLayer(
        urlTemplate: response.tileUrlTemplate,
        userAgentPackageName: 'com.example.se_project',
        maxZoom: 18,
        errorTileCallback: (tile, error, stackTrace) {
          print('GEE Tile error at ${tile.coordinates}: $error');
        },
      ),
    );
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
      // Use index for selection since OBJECTID may have duplicates
      final isSelected =
          widget.selectedAreaId == 'all' ||
          widget.selectedAreaId == i.toString();

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
          width: 100,
          height: 28,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.9),
              borderRadius: BorderRadius.circular(4),
              boxShadow: [
                BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 4),
              ],
            ),
            child: Text(
              areaName.toString(),
              style: const TextStyle(fontSize: 8, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
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
