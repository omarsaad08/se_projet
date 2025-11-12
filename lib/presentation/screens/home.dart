import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:se_project/data/ndvi_services.dart';
import 'package:se_project/helpers/geoJsonLoader.dart';
import 'package:se_project/presentation/components/navbar.dart';

const protectedAreas = [
  "محميية ابوجالوم",
  "محمية اشتوم الجميل",
  "محمية نبق",
  "محمية وادي العلاقي",
  "محمية العميد",
  "محمية الدبابية",
  "محمية قبة الحسنة",
  "محمية وادي الاسيوطي",
  "محمية الغابة المتحجرة",
  "محمية وادي دجلة",
  "محمية كهف سنور",
  "محمية الزرانيق",
  "محمية قارون",
  "محمية وادي الجمال",
  "محمية سالوجا وغزال",
  "محمية راس محمد",
  "محمية وادي الريان",
  "محمية سانت كاثرين",
  "محمية الاحراش",
  "محمية الجلف الكبير",
  "محمية نيزك جبل كامل",
  "محمية سيوة -القطاع الشرقي",
  "محمية سيوة - القطاع الاوسط الجنوبي",
  "محمية سيوة - القطاع الغربي",
  "محمية الصحراء البيضاء",
  "محمية الواحات البحرية الجزء الشرقي- الصحراء السوداء",
  "محمية الواحات البحرية الجزء الوسطي -جبل منديشة (جبل الانجليز)",
  "محمية الواحات البحرية الجزء الغربي -الدست والمغرفة",
  "محمية علبة",
  "محمية الجزر الشمالية للبحر الاحمر",
  "محمية السلوم",
  "محمية البرلس",
  "محمية طابا",
];

class Home extends StatefulWidget {
  const Home({super.key});

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  String? _selectedProtectedArea;
  String _selectedSeason = 'Winter';
  late int _selectedYear;
  Map<int, double> _ndviData = {};
  bool _isLoadingNdvi = false;
  List<CustomPolygon> _customPolygons = [];
  bool _showNdviColors = false;
  bool _polygonsLoaded = false;

  final int _minYear = 1983;
  final int _maxYear = 2025;

  final Map<String, int> _protectedAreaToId = {
    "محمية الجلف الكبير": 20,
    "محمية السلوم": 31,
    "محمية نيزك جبل كامل": 21,
    "محمية سيوة -القطاع الشرقي": 22,
    "محمية سيوة - القطاع الاوسط الجنوبي": 23,
    "محمية سيوة - القطاع الغربي": 25,
    "محمية الصحراء البيضاء": 26,
    "محمية الواحات البحرية الجزء الشرقي- الصحراء السوداء": 27,
    "محمية الواحات البحرية الجزء الوسطي -جبل منديشة (جبل الانجليز)": 28,
    "محمية الواحات البحرية الجزء الغربي -الدست والمغرفة": 29,
    "محمية علبة": 30,
    "محمية الجزر الشمالية للبحر الاحمر": 32,
    "محمية البرلس": 33,
    "محمية طابا": 34,
    "محميية ابوجالوم": 1,
    "محمية اشتوم الجميل": 2,
    "محمية نبق": 3,
    "محمية وادي العلاقي": 4,
    "محمية العميد": 5,
    "محمية الدبابية": 6,
    "محمية قبة الحسنة": 7,
    "محمية وادي الاسيوطي": 9,
    "محمية الغابة المتحجرة": 10,
    "محمية وادي دجلة": 11,
    "محمية كهف سنور": 12,
    "محمية الزرانيق": 13,
    "محمية قارون": 14,
    "محمية وادي الجمال": 15,
    "محمية سالوجا وغزال": 16,
    "محمية راس محمد": 17,
    "محمية وادي الريان": 18,
    "محمية سانت كاثرين": 19,
    "محمية الاحراش": 24,
  };

  @override
  void initState() {
    super.initState();
    final now = DateTime.now().year;
    _selectedYear = now.clamp(_minYear, _maxYear);
    _loadPolygons();
  }

  Future<void> _loadPolygons() async {
    try {
      final polygons = await loadPolygons();
      setState(() {
        _customPolygons = polygons;
        _polygonsLoaded = true;
      });
      print('✅ Loaded ${polygons.length} polygons');

      // Debug: print all polygon names
      for (var polygon in polygons) {
        final name = polygon.properties['اسم__12'] as String?;
        if (name != null) {
          print('📌 Polygon: $name');
        }
      }
    } catch (e) {
      print('❌ Error loading polygons: $e');
      setState(() {
        _polygonsLoaded = true;
      });
    }
  }

  void _resetFilters() {
    setState(() {
      _selectedProtectedArea = null;
      _selectedSeason = 'Winter';
      _selectedYear = DateTime.now().year.clamp(_minYear, _maxYear);
      _showNdviColors = false;
      _ndviData = {};
    });
  }

  Future<void> _loadNdviData() async {
    if (!_polygonsLoaded) {
      print('⚠️ Polygons not loaded yet, waiting...');
      return;
    }

    setState(() {
      _isLoadingNdvi = true;
    });

    try {
      final data = await NdviServices.getAverageNdvi(
        _selectedYear,
        _selectedSeason,
        1,
      );

      if (data != null && data is List) {
        final ndviMap = <int, double>{};
        for (final item in data) {
          final areaId = item['area_id'] as int;
          final avgNdvi = item['avg_ndvi'] as double;
          ndviMap[areaId] = avgNdvi;
        }

        setState(() {
          _ndviData = ndviMap;
          _showNdviColors = true;
        });

        print('✅ Loaded NDVI data for ${ndviMap.length} areas');

        // Debug: print matching info
        int matchedCount = 0;
        for (var polygon in _customPolygons) {
          final areaId = _extractAreaIdFromPolygon(polygon);
          if (areaId != null && ndviMap.containsKey(areaId)) {
            matchedCount++;
            print(
              '🎯 Matched: ${polygon.properties['اسم__12']} -> Area ID: $areaId -> NDVI: ${ndviMap[areaId]}',
            );
          }
        }
        print(
          '📊 Total polygons matched with NDVI data: $matchedCount/${_customPolygons.length}',
        );
      } else {
        print('❌ No NDVI data received');
        setState(() {
          _showNdviColors = false;
        });
      }
    } catch (e) {
      print("❌ Error loading NDVI data: $e");
      setState(() {
        _showNdviColors = false;
      });
    } finally {
      setState(() {
        _isLoadingNdvi = false;
      });
    }
  }

  Color _getColorForNdvi(double? ndviValue) {
    if (ndviValue == null) {
      return Colors.grey.withOpacity(0.5);
    }

    if (ndviValue < -0.5) return const Color(0xFF8B4513);
    if (ndviValue < -0.2) return const Color(0xFFCD853F);
    if (ndviValue < -0.1) return const Color(0xFFDEB887);
    if (ndviValue < 0) return const Color(0xFFF4A460);
    if (ndviValue < 0.1) return const Color(0xFF9ACD32);
    if (ndviValue < 0.2) return const Color(0xFF32CD32);
    if (ndviValue < 0.3) return const Color(0xFF228B22);
    if (ndviValue < 0.4) return const Color(0xFF006400);
    return const Color(0xFF004D00);
  }

  int? _extractAreaIdFromPolygon(CustomPolygon polygon) {
    final arabicName = polygon.properties['اسم__12'] as String?;

    if (arabicName != null) {
      final areaId = _protectedAreaToId[arabicName];
      return areaId;
    }

    return null;
  }

  @override
  Widget build(BuildContext context) {
    final cairo = LatLng(30.0444, 31.2357);

    // Create polygons
    final mapPolygons = _customPolygons.map((customPolygon) {
      final areaId = _extractAreaIdFromPolygon(customPolygon);
      final ndviValue = _ndviData[areaId];
      final arabicName = customPolygon.properties['اسم__12'] as String?;

      final Color fillColor = _showNdviColors
          ? _getColorForNdvi(ndviValue).withOpacity(0.8)
          : Colors.transparent;

      return Polygon(
        points: customPolygon.points,
        color: fillColor,
        borderColor: Colors.blue.withOpacity(0.7),
        borderStrokeWidth: 2.0,
        label: arabicName ?? 'Unknown Area',
      );
    }).toList();

    return Scaffold(
      appBar: const NavBar(currentRoute: 'home'),
      body: Column(
        children: [
          Container(
            margin: const EdgeInsets.all(12.0),
            padding: const EdgeInsets.all(12.0),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade400),
              borderRadius: BorderRadius.circular(8.0),
              color: Colors.white,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Protected area'),
                const SizedBox(height: 8),
                DropdownButton<String>(
                  isExpanded: true,
                  value: _selectedProtectedArea,
                  hint: const Text('Select protected area'),
                  items: protectedAreas
                      .map((p) => DropdownMenuItem(value: p, child: Text(p)))
                      .toList(),
                  onChanged: (v) => setState(() => _selectedProtectedArea = v),
                ),

                const SizedBox(height: 12),

                const Text('Season'),
                const SizedBox(height: 8),
                DropdownButton<String>(
                  isExpanded: true,
                  value: _selectedSeason,
                  items: const [
                    DropdownMenuItem(value: 'Winter', child: Text('Winter')),
                    DropdownMenuItem(value: 'Spring', child: Text('Spring')),
                    DropdownMenuItem(value: 'Summer', child: Text('Summer')),
                    DropdownMenuItem(value: 'Autumn', child: Text('Autumn')),
                  ],
                  onChanged: (v) {
                    if (v == null) return;
                    setState(() {
                      _selectedSeason = v;
                      _showNdviColors = false;
                    });
                  },
                ),

                const SizedBox(height: 12),

                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [const Text('Year'), Text('$_selectedYear')],
                ),
                Slider(
                  min: _minYear.toDouble(),
                  max: _maxYear.toDouble(),
                  divisions: _maxYear - _minYear,
                  value: _selectedYear.toDouble(),
                  label: '$_selectedYear',
                  onChanged: (v) {
                    setState(() {
                      _selectedYear = v.round();
                      _showNdviColors = false;
                    });
                  },
                ),

                const SizedBox(height: 12),

                Row(
                  children: [
                    ElevatedButton(
                      onPressed: _polygonsLoaded ? _loadNdviData : null,
                      child: _isLoadingNdvi
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text('Show NDVI'),
                    ),
                    const SizedBox(width: 12),
                    OutlinedButton(
                      onPressed: _resetFilters,
                      child: const Text('Reset Filters'),
                    ),
                  ],
                ),

                if (!_polygonsLoaded) ...[
                  const SizedBox(height: 12),
                  const Text(
                    'Loading map data...',
                    style: TextStyle(color: Colors.orange),
                  ),
                ],

                if (_showNdviColors) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade300),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'NDVI Legend',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 8),
                        _buildLegendItem(
                          const Color(0xFF8B4513),
                          'Barren/Built-up (< -0.2)',
                        ),
                        _buildLegendItem(
                          const Color(0xFFF4A460),
                          'Soil/Sand (-0.2 to 0)',
                        ),
                        _buildLegendItem(
                          const Color(0xFF9ACD32),
                          'Sparse Veg. (0 to 0.2)',
                        ),
                        _buildLegendItem(
                          const Color(0xFF228B22),
                          'Moderate Veg. (0.2 to 0.4)',
                        ),
                        _buildLegendItem(
                          const Color(0xFF004D00),
                          'Dense Veg. (> 0.4)',
                        ),
                        _buildLegendItem(Colors.grey, 'No data'),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),

          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 12.0,
                vertical: 6.0,
              ),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12.0),
                  border: Border.all(color: Colors.grey.shade300),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.04),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12.0),
                  child: Column(
                    children: [
                      Container(
                        width: double.infinity,
                        color: Colors.grey.shade50,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                _selectedProtectedArea ?? 'All protected areas',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              '$_selectedSeason · $_selectedYear',
                              style: TextStyle(color: Colors.grey.shade700),
                            ),
                            if (_isLoadingNdvi) ...[
                              const SizedBox(width: 8),
                              const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              ),
                            ],
                            if (_showNdviColors) ...[
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.green.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  'NDVI Active',
                                  style: TextStyle(
                                    color: Colors.green.shade700,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                      Expanded(
                        child: FlutterMap(
                          options: MapOptions(
                            initialCenter: cairo,
                            initialZoom: 5.0, // Slightly more zoomed out
                          ),
                          children: [
                            TileLayer(
                              urlTemplate:
                                  'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                              userAgentPackageName: 'com.example.se_project',
                            ),
                            if (mapPolygons.isNotEmpty)
                              PolygonLayer(polygons: mapPolygons),
                            MarkerLayer(
                              markers: [
                                Marker(
                                  point: cairo,
                                  width: 80,
                                  height: 80,
                                  child: const Icon(
                                    Icons.location_on,
                                    color: Colors.red,
                                    size: 40,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLegendItem(Color color, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2.0),
      child: Row(
        children: [
          Container(
            width: 16,
            height: 16,
            color: color,
            margin: const EdgeInsets.only(right: 8),
          ),
          Text(text, style: const TextStyle(fontSize: 12)),
        ],
      ),
    );
  }
}
