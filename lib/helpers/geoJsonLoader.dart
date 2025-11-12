import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'dart:convert';
import 'package:flutter/services.dart';

class CustomPolygon {
  final List<LatLng> points;
  final List<List<LatLng>>? holes;
  final Map<String, dynamic> properties;

  CustomPolygon({required this.points, this.holes, required this.properties});
}

Future<List<CustomPolygon>> loadPolygons() async {
  try {
    final String data = await rootBundle.loadString(
      'assets/ProtectedAreas.geojson',
    );
    final geoJson = json.decode(data);

    List<CustomPolygon> polygons = [];

    // First pass: find the actual bounds of UTM coordinates
    double minX = double.infinity;
    double maxX = -double.infinity;
    double minY = double.infinity;
    double maxY = -double.infinity;

    for (var feature in geoJson['features']) {
      var geometry = feature['geometry'];

      if (geometry['type'] == 'MultiPolygon') {
        for (var polygonCoords in geometry['coordinates']) {
          for (var ring in polygonCoords) {
            for (var coord in ring) {
              double x = coord[0].toDouble();
              double y = coord[1].toDouble();
              if (x < minX) minX = x;
              if (x > maxX) maxX = x;
              if (y < minY) minY = y;
              if (y > maxY) maxY = y;
            }
          }
        }
      }
    }

    print('UTM bounds: X($minX - $maxX), Y($minY - $maxY)');

    // Second pass: convert coordinates with proper scaling
    for (var feature in geoJson['features']) {
      var properties = feature['properties'];
      var geometry = feature['geometry'];

      if (geometry['type'] == 'MultiPolygon') {
        for (var polygonCoords in geometry['coordinates']) {
          for (var ring in polygonCoords) {
            List<LatLng> points = [];

            for (var coord in ring) {
              double x = coord[0].toDouble();
              double y = coord[1].toDouble();

              // Scale UTM coordinates to fit Egypt bounds
              // Egypt: Lat 22-32°N, Lng 25-35°E
              double lat =
                  22.0 +
                  ((y - minY) / (maxY - minY)) * 10.0; // 10° latitude range
              double lng =
                  25.0 +
                  ((x - minX) / (maxX - minX)) * 10.0; // 10° longitude range

              points.add(LatLng(lat, lng));
            }

            polygons.add(
              CustomPolygon(
                points: points,
                properties: Map<String, dynamic>.from(properties),
              ),
            );
          }
        }
      }
    }

    print('Successfully loaded ${polygons.length} polygons from GeoJSON');

    // Debug: print coordinate bounds
    if (polygons.isNotEmpty) {
      double minLat = double.infinity;
      double maxLat = -double.infinity;
      double minLng = double.infinity;
      double maxLng = -double.infinity;

      for (var polygon in polygons) {
        for (var point in polygon.points) {
          if (point.latitude < minLat) minLat = point.latitude;
          if (point.latitude > maxLat) maxLat = point.latitude;
          if (point.longitude < minLng) minLng = point.longitude;
          if (point.longitude > maxLng) maxLng = point.longitude;
        }
      }

      print(
        'Coordinate bounds: Lat($minLat - $maxLat), Lng($minLng - $maxLng)',
      );
      print('Expected Egypt bounds: Lat(22 - 32), Lng(25 - 35)');
    }

    return polygons;
  } catch (e) {
    print('Error loading polygons: $e');
    return [];
  }
}
