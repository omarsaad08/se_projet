import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:se_project/data/ndvi_services.dart';
import 'package:se_project/helpers/geoJsonLoader.dart';
import 'package:se_project/presentation/components/navbar.dart';
import 'package:se_project/helpers/app_theme.dart';

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
  String _selectedSeason = 'Winter';
  late int _selectedYear;
  
  Map<int, double> _ndviData = {};
  Map<int, double> _eviData = {};
  Map<int, double> _ndwiData = {};
  Map<int, double> _tempData = {};
  
  bool _isLoading = false;
  bool _isLoadingNdvi = false;
  bool _showNdviColors = false;
  String? _currentFeature; // Tracks which feature is currently displayed
  List<CustomPolygon> _customPolygons = [];
  bool _polygonsLoaded = false;

  final int _minYear = 1983;
  final int _maxYear = 2050;

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
      _selectedSeason = 'Winter';
      _selectedYear = DateTime.now().year.clamp(_minYear, _maxYear);
      _currentFeature = null;
      _ndviData = {};
      _eviData = {};
      _ndwiData = {};
      _tempData = {};
    });
  }

  Future<void> _loadFeatureData(String feature) async {
    if (!_polygonsLoaded) {
      print('⚠️ Polygons not loaded yet, waiting...');
      return;
    }

    setState(() {
      _isLoading = true;
    });

    if (_selectedYear >= 2025) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Note: Showing predicted data. Actual data not available.',
            style: TextStyle(color: Colors.white),
          ),
          backgroundColor: Colors.purple,
          duration: Duration(seconds: 2),
        ),
      );
    }

    try {
      final data = await NdviServices.getAverageNdvi(
        _selectedYear,
        _selectedSeason,
        1,
        feature: feature,
      );

      if (data != null && data is List) {
        setState(() {
          switch (feature) {
            case 'ndvi':
              final ndviMap = <int, double>{};
              for (final item in data) {
                final areaId = item['area_id'] as int;
                final value = item['ndvi'] as double;
                ndviMap[areaId] = value;
              }
              _ndviData = ndviMap;
              break;
            case 'evi':
              final eviMap = <int, double>{};
              for (final item in data) {
                final areaId = item['area_id'] as int;
                final value = item['evi'] as double;
                eviMap[areaId] = value;
              }
              _eviData = eviMap;
              break;
            case 'ndwi':
              final ndwiMap = <int, double>{};
              for (final item in data) {
                final areaId = item['area_id'] as int;
                final value = item['ndwi'] as double;
                ndwiMap[areaId] = value;
              }
              _ndwiData = ndwiMap;
              break;
            case 'temp':
              final tempMap = <int, double>{};
              for (final item in data) {
                final areaId = item['area_id'] as int;
                final value = item['temp'] as double;
                tempMap[areaId] = value;
              }
              _tempData = tempMap;
              break;
          }
          _currentFeature = feature;
        });

        print('✅ Loaded $feature data for ${data.length} areas');
      } else {
        print('❌ No data received for $feature');
        setState(() {
          _currentFeature = null;
        });
      }
    } catch (e) {
      print("❌ Error loading $feature data: $e");
      setState(() {
        _currentFeature = null;
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }
  Color _getColorForNdvi(double? ndviValue) {
    if (ndviValue == null) {
      return Colors.grey.withOpacity(0.5);
    }
    // NDVI: Brown (low/dead vegetation) to Dark Green (high vegetation)
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

  Color _getColorForEvi(double? eviValue) {
    if (eviValue == null) {
      return Colors.grey.withOpacity(0.5);
    }
    // EVI: Similar to NDVI but enhanced - Brown to Bright Green
    if (eviValue < -0.3) return const Color(0xFF654321);
    if (eviValue < 0) return const Color(0xFFD4A574);
    if (eviValue < 0.1) return const Color(0xFFADFF2F);
    if (eviValue < 0.2) return const Color(0xFF7FFF00);
    if (eviValue < 0.3) return const Color(0xFF00FF00);
    if (eviValue < 0.4) return const Color(0xFF00DD00);
    if (eviValue < 0.5) return const Color(0xFF00AA00);
    return const Color(0xFF008000);
  }

  Color _getColorForNdwi(double? ndwiValue) {
    if (ndwiValue == null) {
      return Colors.grey.withOpacity(0.5);
    }
    // NDWI: Red (dry) to Blue (water/moisture)
    if (ndwiValue < -0.3) return const Color(0xFFFF0000);
    if (ndwiValue < -0.1) return const Color(0xFFFF6B6B);
    if (ndwiValue < 0) return const Color(0xFFFFB6C1);
    if (ndwiValue < 0.1) return const Color(0xFFFFEBCD);
    if (ndwiValue < 0.2) return const Color(0xFF87CEEB);
    if (ndwiValue < 0.3) return const Color(0xFF1E90FF);
    if (ndwiValue < 0.4) return const Color(0xFF0047AB);
    return const Color(0xFF00008B);
  }

  Color _getColorForTemp(double? tempValue) {
    if (tempValue == null) {
      return Colors.grey.withOpacity(0.5);
    }
    // Temperature: Cool (blue) to Hot (red)
    if (tempValue < 10) return const Color(0xFF00008B);
    if (tempValue < 15) return const Color(0xFF4169E1);
    if (tempValue < 20) return const Color(0xFF87CEEB);
    if (tempValue < 25) return const Color(0xFF90EE90);
    if (tempValue < 30) return const Color(0xFFFFFF00);
    if (tempValue < 35) return const Color(0xFFFF8C00);
    return const Color(0xFFFF0000);
  }

  Color _getColorForCurrentFeature(int areaId) {
    switch (_currentFeature) {
      case 'ndvi':
        return _getColorForNdvi(_ndviData[areaId]);
      case 'evi':
        return _getColorForEvi(_eviData[areaId]);
      case 'ndwi':
        return _getColorForNdwi(_ndwiData[areaId]);
      case 'temp':
        return _getColorForTemp(_tempData[areaId]);
      default:
        return Colors.transparent;
    }
  }

  int? _extractAreaIdFromPolygon(CustomPolygon polygon) {
    final arabicName = polygon.properties['اسم__12'] as String?;

    if (arabicName != null) {
      final areaId = _protectedAreaToId[arabicName];
      return areaId;
    }

    return null;
  }

  Widget _buildFeatureButton({
    required String feature,
    required String label,
    required Color color,
    required IconData icon,
  }) {
    final isActive = _currentFeature == feature;
    final Color textColor = color.computeLuminance() > 0.5 ? Colors.black : Colors.white;

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [color, color.withOpacity(0.8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
        boxShadow: isActive
            ? [
                BoxShadow(
                  color: color.withOpacity(0.5),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ]
            : [],
      ),
      child: ElevatedButton(
        onPressed: _polygonsLoaded ? () => _loadFeatureData(feature) : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          padding: const EdgeInsets.symmetric(vertical: 12),
          side: isActive ? BorderSide(color: Colors.white, width: 2) : BorderSide.none,
        ),
        child: _isLoading && _currentFeature == feature
            ? SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  valueColor: AlwaysStoppedAnimation<Color>(textColor),
                ),
              )
            : Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(icon, size: 20, color: textColor),
                  const SizedBox(height: 4),
                  Text(
                    label,
                    style: TextStyle(
                      fontWeight: isActive ? FontWeight.bold : FontWeight.w600,
                      fontSize: 12,
                      color: textColor,
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cairo = LatLng(30.0444, 31.2357);

    // Create polygons
    final mapPolygons = _customPolygons.map((customPolygon) {
      final areaId = _extractAreaIdFromPolygon(customPolygon);
      final arabicName = customPolygon.properties['اسم__12'] as String?;

      final Color fillColor = _currentFeature != null && areaId != null
          ? _getColorForCurrentFeature(areaId).withOpacity(0.8)
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
      backgroundColor: AppTheme.darkBg,
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Filter Panel
            SingleChildScrollView(
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
              padding: const EdgeInsets.all(16.0),
              decoration: BoxDecoration(
                color: AppTheme.darkBgSecondary,
                borderRadius: BorderRadius.circular(16.0),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.3),
                    blurRadius: 16,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryBlue.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(
                          Icons.tune,
                          color: AppTheme.primaryBlue,
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Text(
                        'Filters',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.darkText,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),

                  // Season Dropdown
                  _buildFilterLabel('Season'),
                  const SizedBox(height: 8),
                  Container(
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade700),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: DropdownButton<String>(
                      isExpanded: true,
                      value: _selectedSeason,
                      underline: const SizedBox(),
                      borderRadius: BorderRadius.circular(12),
                      items: const [
                        DropdownMenuItem(value: 'Winter', child: Padding(
                          padding: EdgeInsets.symmetric(horizontal: 12),
                          child: Text('Winter ❄️', style: TextStyle(color: Colors.white)),
                        )),
                        DropdownMenuItem(value: 'Spring', child: Padding(
                          padding: EdgeInsets.symmetric(horizontal: 12),
                          child: Text('Spring 🌱', style: TextStyle(color: Colors.white)),
                        )),
                        DropdownMenuItem(value: 'Summer', child: Padding(
                          padding: EdgeInsets.symmetric(horizontal: 12),
                          child: Text('Summer ☀️', style: TextStyle(color: Colors.white)),
                        )),
                        DropdownMenuItem(value: 'Autumn', child: Padding(
                          padding: EdgeInsets.symmetric(horizontal: 12),
                          child: Text('Autumn 🍂', style: TextStyle(color: Colors.white)),
                        )),
                      ],
                      onChanged: (v) {
                        if (v == null) return;
                        setState(() {
                          _selectedSeason = v;
                          _showNdviColors = false;
                          _currentFeature = null;
                        });
                      },
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Year Slider
                  _buildFilterLabel('Year Range'),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryBlue.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '$_minYear',
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppTheme.darkTextSecondary,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: const BoxDecoration(
                            color: AppTheme.primaryBlue,
                            borderRadius: BorderRadius.all(Radius.circular(8)),
                          ),
                          child: Text(
                            '$_selectedYear',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                              fontSize: 14,
                            ),
                          ),
                        ),
                        Text(
                          '$_maxYear',
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppTheme.darkTextSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  SliderTheme(
                    data: SliderThemeData(
                      trackHeight: 6,
                      activeTrackColor: AppTheme.primaryBlue,
                      inactiveTrackColor: Colors.grey.shade700,
                      thumbColor: AppTheme.primaryBlue,
                      overlayColor: AppTheme.primaryBlue.withOpacity(0.2),
                    ),
                    child: Slider(
                      min: _minYear.toDouble(),
                      max: _maxYear.toDouble(),
                      divisions: _maxYear - _minYear,
                      value: _selectedYear.toDouble(),
                      label: '$_selectedYear',
                      onChanged: (v) {
                        setState(() {
                          _selectedYear = v.round();
                          _currentFeature = null;
                          // Clear all data when year changes
                          _ndviData = {};
                          _eviData = {};
                          _ndwiData = {};
                          _tempData = {};
                        });
                      },
                    ),
                  ),
                  const SizedBox(height: 18),

                  // Feature Buttons
                  Column(
                    children: [
                      // First row - NDVI and EVI
                      Row(
                        children: [
                          Expanded(
                            child: _buildFeatureButton(
                              feature: 'ndvi',
                              label: 'NDVI',
                              color: AppTheme.primaryBlue,
                              icon: Icons.eco,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _buildFeatureButton(
                              feature: 'evi',
                              label: 'EVI',
                              color: const Color(0xFF7FFF00),
                              icon: Icons.grass,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      // Second row - NDWI and Temperature
                      Row(
                        children: [
                          Expanded(
                            child: _buildFeatureButton(
                              feature: 'ndwi',
                              label: 'NDWI',
                              color: const Color(0xFF1E90FF),
                              icon: Icons.opacity,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _buildFeatureButton(
                              feature: 'temp',
                              label: 'Temperature',
                              color: const Color(0xFFFF6347),
                              icon: Icons.thermostat,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      // Reset button
                      SizedBox(
                        width: double.infinity,
                        child: Container(
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey.shade600),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: OutlinedButton(
                            onPressed: _resetFilters,
                            style: OutlinedButton.styleFrom(
                              side: BorderSide(color: Colors.grey.shade600),
                              padding: const EdgeInsets.symmetric(vertical: 14),
                            ),
                            child: const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.refresh, size: 18),
                                SizedBox(width: 8),
                                Text('Reset Filters'),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  if (!_polygonsLoaded) ...[
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.orange.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.info_outline, color: Colors.orange, size: 18),
                          const SizedBox(width: 8),
                          const Expanded(
                            child: Text(
                              'Loading map data...',
                              style: TextStyle(
                                color: Colors.orange,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],

                  // Dynamic Legend - Shows based on current feature
                  if (_currentFeature != null) ...[
                    const SizedBox(height: 16),
                    _buildLegendForCurrentFeature(),
                  ],
                ],
              ),
            ),
          ),

          // Map Container
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 16.0,
              vertical: 6.0,
            ),
            child: Container(
              height: 400,
              decoration: BoxDecoration(
                color: AppTheme.darkBgSecondary,
                borderRadius: BorderRadius.circular(16.0),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.3),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16.0),
                child: Column(
                  children: [
                    // Map Header
                    Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            AppTheme.primaryBlue,
                            AppTheme.primaryBlueDark,
                          ],
                        ),
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.map, color: Colors.white, size: 20),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'All Protected Areas',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                    color: Colors.white,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  '$_selectedSeason · $_selectedYear',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: Colors.white70,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (_isLoadingNdvi) ...[
                              const SizedBox(width: 8),
                              const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                ),
                              ),
                            ],
                            if (_showNdviColors) ...[
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 5,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: const Row(
                                  children: [
                                    Icon(
                                      Icons.check_circle,
                                      size: 12,
                                      color: Colors.white,
                                    ),
                                    SizedBox(width: 4),
                                    Text(
                                      'NDVI Active',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                      // Map
                      Expanded(
                        child: FlutterMap(
                          options: MapOptions(
                            initialCenter: cairo,
                            initialZoom: 5.0,
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
          
          const SizedBox(height: 12),
        ],
        ),
      ),
    );
  }

  Widget _buildFilterLabel(String text) {
    return Text(
      text,
      style: const TextStyle(
        fontWeight: FontWeight.w600,
        fontSize: 13,
        color: AppTheme.darkText,
      ),
    );
  }

  Widget _buildLegendForCurrentFeature() {
    switch (_currentFeature) {
      case 'ndvi':
        return _buildNdviLegend();
      case 'evi':
        return _buildEviLegend();
      case 'ndwi':
        return _buildNdwiLegend();
      case 'temp':
        return _buildTempLegend();
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildNdviLegend() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.primaryGreen.withOpacity(0.08),
        border: Border.all(color: AppTheme.primaryGreen.withOpacity(0.3)),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(
                Icons.eco,
                color: AppTheme.primaryGreen,
                size: 16,
              ),
              SizedBox(width: 8),
              Text(
                'NDVI - Vegetation Index',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                  color: AppTheme.primaryGreen,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          _buildLegendItem(const Color(0xFF8B4513), 'Barren/Built-up', '< -0.2'),
          _buildLegendItem(const Color(0xFFF4A460), 'Soil/Sand', '-0.2 to 0'),
          _buildLegendItem(const Color(0xFF9ACD32), 'Sparse Veg.', '0 to 0.2'),
          _buildLegendItem(const Color(0xFF228B22), 'Moderate Veg.', '0.2 to 0.4'),
          _buildLegendItem(const Color(0xFF004D00), 'Dense Veg.', '> 0.4'),
          _buildLegendItem(Colors.grey, 'No data', ''),
        ],
      ),
    );
  }

  Widget _buildEviLegend() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.green.withOpacity(0.08),
        border: Border.all(color: Colors.green.withOpacity(0.3)),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(
                Icons.grass,
                color: Colors.green,
                size: 16,
              ),
              SizedBox(width: 8),
              Text(
                'EVI - Enhanced Vegetation Index',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                  color: Colors.green,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          _buildLegendItem(const Color(0xFF654321), 'Very Low', '< -0.3'),
          _buildLegendItem(const Color(0xFFD4A574), 'Low', '-0.3 to 0'),
          _buildLegendItem(const Color(0xFFADFF2F), 'Moderate-Low', '0 to 0.1'),
          _buildLegendItem(const Color(0xFF7FFF00), 'Moderate', '0.1 to 0.2'),
          _buildLegendItem(const Color(0xFF00FF00), 'High', '0.2 to 0.3'),
          _buildLegendItem(const Color(0xFF00DD00), 'Very High', '0.3 to 0.4'),
          _buildLegendItem(const Color(0xFF008000), 'Excellent', '> 0.4'),
          _buildLegendItem(Colors.grey, 'No data', ''),
        ],
      ),
    );
  }

  Widget _buildNdwiLegend() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.blue.withOpacity(0.08),
        border: Border.all(color: Colors.blue.withOpacity(0.3)),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(
                Icons.water_drop,
                color: Colors.blue,
                size: 16,
              ),
              SizedBox(width: 8),
              Text(
                'NDWI - Water Index',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                  color: Colors.blue,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          _buildLegendItem(const Color(0xFFFF0000), 'Very Dry', '< -0.3'),
          _buildLegendItem(const Color(0xFFFF6B6B), 'Dry', '-0.3 to -0.1'),
          _buildLegendItem(const Color(0xFFFFB6C1), 'Moderate-Dry', '-0.1 to 0'),
          _buildLegendItem(const Color(0xFFFFEBCD), 'Moderate-Wet', '0 to 0.1'),
          _buildLegendItem(const Color(0xFF87CEEB), 'Wet', '0.1 to 0.2'),
          _buildLegendItem(const Color(0xFF1E90FF), 'Very Wet', '0.2 to 0.3'),
          _buildLegendItem(const Color(0xFF0047AB), 'Saturated', '0.3 to 0.4'),
          _buildLegendItem(const Color(0xFF00008B), 'Water Body', '> 0.4'),
          _buildLegendItem(Colors.grey, 'No data', ''),
        ],
      ),
    );
  }

  Widget _buildTempLegend() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.orange.withOpacity(0.08),
        border: Border.all(color: Colors.orange.withOpacity(0.3)),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(
                Icons.thermostat,
                color: Colors.orange,
                size: 16,
              ),
              SizedBox(width: 8),
              Text(
                'Temperature (°C)',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                  color: Colors.orange,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          _buildLegendItem(const Color(0xFF00008B), 'Very Cold', '< 10°C'),
          _buildLegendItem(const Color(0xFF4169E1), 'Cold', '10-15°C'),
          _buildLegendItem(const Color(0xFF87CEEB), 'Cool', '15-20°C'),
          _buildLegendItem(const Color(0xFF90EE90), 'Mild', '20-25°C'),
          _buildLegendItem(const Color(0xFFFFFF00), 'Warm', '25-30°C'),
          _buildLegendItem(const Color(0xFFFF8C00), 'Hot', '30-35°C'),
          _buildLegendItem(const Color(0xFFFF0000), 'Very Hot', '> 35°C'),
          _buildLegendItem(Colors.grey, 'No data', ''),
        ],
      ),
    );
  }

  Widget _buildLegendItem(Color color, String text, String range) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5.0),
      child: Row(
        children: [
          Container(
            width: 14,
            height: 14,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(3),
              border: Border.all(
                color: Colors.black.withOpacity(0.1),
                width: 0.5,
              ),
            ),
            margin: const EdgeInsets.only(right: 10),
          ),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                fontSize: 12,
                color: AppTheme.darkText,
              ),
            ),
          ),
          Text(
            range,
            style: const TextStyle(
              fontSize: 11,
              color: AppTheme.darkTextSecondary,
            ),
          ),
        ],
      ),
    );
  }
}
