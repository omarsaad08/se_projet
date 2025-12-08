# Charts System - Complete Explanation

## Overview

The charts system in this project displays environmental data (NDVI, EVI, NDWI, Temperature) across different time periods, areas, and seasons. It combines **historical data** (observed values) with **predicted data** (future projections) and visualizes them using interactive line charts.

---

## Architecture

### File Structure

```
lib/
├── data/
│   └── charts_services.dart          # API communication & data models
├── presentation/
│   ├── screens/
│   │   ├── charts.dart               # Main screen wrapper
│   │   └── charts_page.dart          # Chart UI & logic
│   └── components/
│       └── time_series_chart.dart    # Chart visualization components
```

---

## Data Flow

```
User Interaction
    ↓
charts_page.dart (State Management)
    ↓
ChartsServices (API Calls)
    ↓
Backend API Response
    ↓
Data Models (ChartDataResponse, ChartDataPoint, etc.)
    ↓
Chart Components (TimeSeriesLineChart / AverageTimeSeriesChart)
    ↓
fl_chart Package (Visualization)
    ↓
User Sees Chart
```

---

## Detailed Component Breakdown

### 1. **charts.dart** - Main Screen Wrapper

```dart
class Charts extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const NavBar(currentRoute: 'charts'),
      body: const ChartsPage(),
    );
  }
}
```

**Purpose:** Simple wrapper that provides:
- Navigation bar at the top
- Container for the ChartsPage content

---

### 2. **charts_page.dart** - Core Logic & UI

#### State Variables

```dart
// Dropdown selections
String selectedMetric = 'ndvi';        // Which environmental metric
String selectedSeason = 'all';         // Which season
String selectedAreaId = 'all';         // Which geographic area
int startYear = 2000;                  // Chart start year
int endYear = 2024;                    // Chart end year

// Data & UI state
List<int> availableAreas = [];         // Areas fetched from backend
ChartDataResponse? chartData;          // Chart data after API call
bool isLoading = false;                // Loading indicator
String? errorMessage;                  // Error display
```

#### Constants

```dart
static const List<String> metrics = ['ndvi', 'evi', 'ndwi', 'temp'];
static const List<String> seasons = ['all', 'winter', 'spring', 'summer', 'autumn'];
static const int minYear = 1984;       // Earliest year available
static const int maxYear = 2050;       // Latest year available (including predictions)
```

#### Key Methods

##### `_loadAreas()`
Called in `initState()` to populate the area dropdown.

```dart
Future<void> _loadAreas() async {
  try {
    final areas = await ChartsServices.getAllAreas();
    if (areas != null) {
      setState(() {
        availableAreas = areas;  // Update dropdown options
      });
    }
  } catch (e) {
    print("Error loading areas: $e");
  }
}
```

**What happens:**
1. Calls backend API to get list of available area IDs
2. Stores them in `availableAreas`
3. Updates UI to show these areas in the dropdown

---

##### `_isValidChartSelection()`
Validates the user's selections before fetching data.

```dart
bool _isValidChartSelection() {
  // Check 1: Start year must be before end year
  if (startYear > endYear) {
    setState(() {
      errorMessage = 'Start year must be before end year';
    });
    return false;
  }

  // Check 2: Years must be within valid range
  if (startYear < minYear || endYear > maxYear) {
    setState(() {
      errorMessage = 'Years must be between $minYear and $maxYear';
    });
    return false;
  }

  // Clear error if all validations pass
  setState(() {
    errorMessage = null;
  });
  return true;
}
```

**Validations:**
- Start year < End year
- Both years within 1984-2050 range

---

##### `_generateChart()`
Main method called when user clicks "Generate Chart" button.

```dart
Future<void> _generateChart() async {
  // Step 1: Validate selections
  if (!_isValidChartSelection()) {
    return;  // Stop if validation fails
  }

  // Step 2: Show loading state
  setState(() {
    isLoading = true;
    errorMessage = null;
  });

  try {
    // Step 3: Fetch data from backend
    final data = await ChartsServices.getChartData(
      startYear: startYear,
      endYear: endYear,
      areaId: selectedAreaId,
      season: selectedSeason,
      metric: selectedMetric,
    );

    // Step 4: Check if data exists
    if (data != null && data.data.isNotEmpty) {
      setState(() {
        chartData = data;        // Store data for chart
        isLoading = false;       // Hide loading indicator
      });
    } else {
      setState(() {
        errorMessage = 'No data available for the selected parameters';
        isLoading = false;
        chartData = null;
      });
    }
  } catch (e) {
    // Step 5: Handle errors
    setState(() {
      errorMessage = 'Error loading chart data: $e';
      isLoading = false;
      chartData = null;
    });
  }
}
```

**Flow:**
1. Validate user inputs
2. Show loading spinner
3. Call API with selected filters
4. Store response or show error
5. Update UI

---

#### UI Build Method

The UI has three main sections:

**Section 1: Filter Card**
- Metric dropdown (ndvi, evi, ndwi, temp)
- Area dropdown (all areas + specific areas)
- Season dropdown (all, winter, spring, summer, autumn)
- Year range sliders/dropdowns
- Error message display
- "Generate Chart" button

**Section 2: Chart Display** (shown when `chartData != null`)
- Chart title showing selected filters
- Metadata box (total points, historical years, predicted years)
- **Chart itself** (conditional rendering)
- Data summary statistics

**Section 3: Empty State** (shown when no chart data)
- Info icon + message asking user to generate chart

---

#### Chart Selection Logic

```dart
Container(
  width: double.infinity,
  height: 300,
  child: selectedAreaId == 'all'
      ? AverageTimeSeriesChart(        // Show when ALL areas
          data: chartData!,
          metric: selectedMetric,
        )
      : TimeSeriesLineChart(           // Show when SPECIFIC area
          data: chartData!,
          metric: selectedMetric,
          selectedAreaId: selectedAreaId,
          selectedSeason: selectedSeason,
        ),
)
```

**Decision Logic:**
- **"All Areas"** → Use `AverageTimeSeriesChart` (single aggregated line)
- **Specific Area** → Use `TimeSeriesLineChart` (dual historical + predicted lines)

---

#### Helper Methods

##### `getMetricLabel()`
Converts metric codes to user-friendly labels.

```dart
String getMetricLabel(String metric) {
  switch (metric) {
    case 'ndvi': return 'NDVI (Vegetation Index)';
    case 'evi': return 'EVI (Enhanced Vegetation Index)';
    case 'ndwi': return 'NDWI (Water Index)';
    case 'temp': return 'Temperature (°C)';
    default: return metric.toUpperCase();
  }
}
```

##### `getSeasonLabel()`
Converts season codes to readable names.

```dart
String getSeasonLabel(String season) {
  switch (season) {
    case 'all': return 'All Seasons';
    case 'winter': return 'Winter';
    case 'spring': return 'Spring';
    case 'summer': return 'Summer';
    case 'autumn': return 'Autumn';
    default: return season;
  }
}
```

##### `_buildDataSummary()`
Calculates and displays min, max, average values.

```dart
Widget _buildDataSummary() {
  if (chartData == null || chartData!.data.isEmpty) {
    return const SizedBox.shrink();
  }

  final values = chartData!.data.map((p) => p.value).toList();
  final avgValue = values.reduce((a, b) => a + b) / values.length;
  final minValue = values.reduce((a, b) => a < b ? a : b);
  final maxValue = values.reduce((a, b) => a > b ? a : b);

  return Column(
    children: [
      _summaryRow('Average ${selectedMetric.toUpperCase()}:', '$avgValue'),
      _summaryRow('Min ${selectedMetric.toUpperCase()}:', '$minValue'),
      _summaryRow('Max ${selectedMetric.toUpperCase()}:', '$maxValue'),
      _summaryRow('Data Points:', '${chartData!.data.length}'),
    ],
  );
}
```

---

### 3. **time_series_chart.dart** - Visualization Components

This file contains two chart classes using the **fl_chart** package.

#### Component 1: TimeSeriesLineChart

**Purpose:** Display data for a **specific area** with separate lines for historical vs predicted data.

**Constructor Parameters:**
```dart
final ChartDataResponse data;         // Full response with all data
final String metric;                  // Which metric (for display)
final String selectedAreaId;          // Which area to filter
final String selectedSeason;          // Which season (for display)
```

##### Data Processing: `_getLineChartBarData()`

```dart
List<LineChartBarData> _getLineChartBarData() {
  // Step 1: Start with all data
  List<ChartDataPoint> filteredData = data.data;

  // Step 2: Filter by selected area (if not 'all')
  if (selectedAreaId != 'all') {
    filteredData = filteredData
        .where((p) => p.areaId == int.parse(selectedAreaId))
        .toList();
  }

  // Step 3: Separate into historical and predicted groups by year
  Map<int, List<double>> historicalYearValues = {};
  Map<int, List<double>> predictedYearValues = {};

  for (var point in filteredData) {
    if (point.isPrediction) {
      predictedYearValues.putIfAbsent(point.year, () => []).add(point.value);
    } else {
      historicalYearValues.putIfAbsent(point.year, () => []).add(point.value);
    }
  }

  // Step 4: Convert to chart points
  List<LineChartBarData> lineBarsData = [];

  // Create historical line
  if (historicalYearValues.isNotEmpty) {
    List<FlSpot> historicalSpots = [];
    historicalYearValues.forEach((year, values) {
      // Average values for the year
      final average = values.reduce((a, b) => a + b) / values.length;
      historicalSpots.add(FlSpot(year.toDouble(), average));
    });
    historicalSpots.sort((a, b) => a.x.compareTo(b.x));

    // Create blue line for historical data
    lineBarsData.add(
      LineChartBarData(
        spots: historicalSpots,
        isCurved: true,
        color: Colors.blue,
        barWidth: 3,
        isStrokeCapRound: true,
        dotData: FlDotData(show: true, ...),
        belowBarData: BarAreaData(
          show: true,
          color: Colors.blue.withValues(alpha: 0.1),  // Semi-transparent fill
        ),
      ),
    );
  }

  // Create predicted line (same logic but orange with dashes)
  if (predictedYearValues.isNotEmpty) {
    List<FlSpot> predictedSpots = [];
    predictedYearValues.forEach((year, values) {
      final average = values.reduce((a, b) => a + b) / values.length;
      predictedSpots.add(FlSpot(year.toDouble(), average));
    });
    predictedSpots.sort((a, b) => a.x.compareTo(b.x));

    lineBarsData.add(
      LineChartBarData(
        spots: predictedSpots,
        color: Colors.orange,
        dashArray: [5, 5],  // Dashed line to show it's predicted
        ...
      ),
    );
  }

  return lineBarsData;
}
```

**Processing Steps:**
1. Filter by selected area
2. Group data by year and separate historical vs predicted
3. Calculate average value per year (handles multiple data points per year per area)
4. Convert to `FlSpot` points (x=year, y=value)
5. Sort chronologically
6. Create LineChartBarData objects with styling

**Visual Styling:**
- **Historical (Blue):** Solid line, blue color, semi-transparent fill below
- **Predicted (Orange):** Dashed line, orange color, semi-transparent fill below
- Both have circular dots at data points

##### Building the Chart: `build()`

```dart
@override
Widget build(BuildContext context) {
  final lineChartBarData = _getLineChartBarData();

  // Handle empty data
  if (lineChartBarData.isEmpty) {
    return Center(child: Text('No data available'));
  }

  // Calculate Y-axis range with 10% padding
  double minY = double.infinity;
  double maxY = double.negativeInfinity;

  for (var line in lineChartBarData) {
    for (var spot in line.spots) {
      minY = min(minY, spot.y);
      maxY = max(maxY, spot.y);
    }
  }

  final yPadding = (maxY - minY) * 0.1;
  minY = (minY - yPadding).clamp(0, double.infinity);
  maxY = maxY + yPadding;

  return Padding(
    padding: const EdgeInsets.all(16.0),
    child: Column(
      children: [
        // Legend showing what each color means
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildLegendItem('Historical Data', Colors.blue),
            SizedBox(width: 24),
            _buildLegendItem('Predicted Data', Colors.orange),
          ],
        ),
        // Actual chart
        Expanded(
          child: LineChart(
            LineChartData(
              gridData: FlGridData(...),           // Background grid
              titlesData: FlTitlesData(...),       // Axis labels
              borderData: FlBorderData(...),       // Chart border
              lineBarsData: lineChartBarData,      // Our data lines
              minY: minY,
              maxY: maxY,
              lineTouchData: LineTouchData(...),   // Interactive tooltips
            ),
          ),
        ),
      ],
    ),
  );
}
```

**Chart Configuration:**
- Grid with horizontal and vertical lines
- X-axis: Years (with smart intervals)
- Y-axis: Metric values (with smart intervals)
- Interactive tooltips on tap/hover
- Legend at top

##### Axis Interval Calculation

```dart
double _getYearInterval() {
  final yearRange = data.endYear - data.startYear;
  if (yearRange <= 5) return 1;      // Show every year
  if (yearRange <= 10) return 2;     // Show every 2 years
  if (yearRange <= 20) return 5;     // Show every 5 years
  return 10;                          // Show every 10 years
}

double _getValueInterval(double range) {
  if (range <= 0.1) return 0.01;     // Very fine scale
  if (range <= 1) return 0.1;
  if (range <= 10) return 1;
  if (range <= 100) return 10;
  return 50;                          // Large scale
}
```

**Smart Intervals:** Prevents axis labels from overlapping by adapting to data range.

---

##### Legend Display: `_buildLegendItem()`

```dart
Widget _buildLegendItem(String label, Color color) {
  return Row(
    children: [
      Container(
        width: 12,
        height: 12,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
        ),
      ),
      const SizedBox(width: 8),
      Text(
        label,
        style: const TextStyle(fontSize: 12),
      ),
    ],
  );
}
```

**Renders:** A small colored circle next to text label for chart legend.
- Used in both TimeSeriesLineChart (2 items) and AverageTimeSeriesChart (if needed)

---

##### Chart Rendering Details

**LineChartData Configuration:**

```dart
LineChartData(
  gridData: FlGridData(
    show: true,
    drawVerticalLine: true,
    horizontalInterval: 1,      // Grid line interval
    verticalInterval: 1,         // Grid line interval
  ),
  titlesData: FlTitlesData(
    show: true,
    rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
    topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
    bottomTitles: AxisTitles(
      sideTitles: SideTitles(
        showTitles: true,
        reservedSize: 30,                    // Space for labels
        interval: _getYearInterval(),        // Smart interval
        getTitlesWidget: (value, meta) {
          return Text(
            '${value.toInt()}',              // Convert float to year string
            style: const TextStyle(fontSize: 10),
          );
        },
      ),
    ),
    leftTitles: AxisTitles(
      sideTitles: SideTitles(
        showTitles: true,
        reservedSize: 40,
        interval: _getValueInterval(maxY - minY),  // Smart interval based on range
        getTitlesWidget: (value, meta) {
          return Text(
            '${value.toStringAsFixed(1)}',         // Format to 1 decimal place
            style: const TextStyle(fontSize: 10),
          );
        },
      ),
    ),
  ),
  borderData: FlBorderData(
    show: true,
    border: Border.all(color: Colors.grey.withOpacity(0.5)),
  ),
  lineBarsData: lineChartBarData,  // Our processed data lines
  minY: minY,                       // Dynamic Y-axis minimum
  maxY: maxY,                       // Dynamic Y-axis maximum
  lineTouchData: LineTouchData(
    enabled: true,
    touchTooltipData: LineTouchTooltipData(
      getTooltipItems: (touchedSpots) {
        return touchedSpots.map((LineBarSpot touchedBarSpot) {
          const flStyle = TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 12,
          );
          return LineTooltipItem(
            'Year: ${touchedBarSpot.x.toInt()}\nValue: ${touchedBarSpot.y.toStringAsFixed(3)}',
            flStyle,
          );
        }).toList();
      },
    ),
  ),
)
```

**Interactive Features:**
- **Touch/Hover:** Shows tooltip with year and exact value (3 decimal places)
- **Grid:** Helps read values by providing reference lines
- **Dynamic Axes:** Y-axis adjusts to data range
- **Smart Labels:** X and Y labels show at appropriate intervals

---

#### Component 2: AverageTimeSeriesChart

**Purpose:** Display **aggregated data across all areas** with a single line showing average by year.

**Constructor:**
```dart
const AverageTimeSeriesChart({
  Key? key,
  required this.data,
  required this.metric,
})

final ChartDataResponse data;         // Full response with all data
final String metric;                  // Which metric (for display in tooltip)
```

##### Data Processing

```dart
// Group all data by year, regardless of area
Map<int, List<double>> yearValues = {};
for (var point in data.data) {
  yearValues.putIfAbsent(point.year, () => []).add(point.value);
}

// Calculate yearly average across all areas
List<FlSpot> spots = [];
yearValues.forEach((year, values) {
  final average = values.reduce((a, b) => a + b) / values.length;
  spots.add(FlSpot(year.toDouble(), average));
});

// Sort by year (chronological order)
spots.sort((a, b) => a.x.compareTo(b.x));
```

**Processing Steps:**
1. Iterate through all data points
2. Group values by year (ignores area since we're showing all)
3. Calculate average for each year
4. Convert to `FlSpot` (x=year, y=average value)
5. Sort chronologically

**Difference from TimeSeriesLineChart:**
- Does NOT separate historical vs predicted
- Does NOT filter by area
- Shows SINGLE blue line for all data aggregated by year
- Simpler, cleaner visualization for overview

---

##### Building the Chart

```dart
@override
Widget build(BuildContext context) {
  // ... (data processing and calculations as above)

  // Calculate Y-axis range
  double minY = spots.map((s) => s.y).reduce((a, b) => a < b ? a : b);
  double maxY = spots.map((s) => s.y).reduce((a, b) => a > b ? a : b);

  final yPadding = (maxY - minY) * 0.1;
  minY = (minY - yPadding).clamp(0, double.infinity);
  maxY = maxY + yPadding;

  return Padding(
    padding: const EdgeInsets.all(16.0),
    child: LineChart(
      LineChartData(
        gridData: FlGridData(
          show: true,
          drawVerticalLine: true,
          horizontalInterval: 1,
          verticalInterval: 1,
        ),
        titlesData: FlTitlesData(
          show: true,
          rightTitles: AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          topTitles: AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 30,
              interval: _getYearInterval(),
              getTitlesWidget: (value, meta) {
                return Text('${value.toInt()}', style: TextStyle(fontSize: 10));
              },
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 40,
              interval: _getValueInterval(maxY - minY),
              getTitlesWidget: (value, meta) {
                return Text('${value.toStringAsFixed(1)}', style: TextStyle(fontSize: 10));
              },
            ),
          ),
        ),
        borderData: FlBorderData(
          show: true,
          border: Border.all(color: Colors.grey.withOpacity(0.5)),
        ),
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: true,
            color: Colors.blue,
            barWidth: 3,
            isStrokeCapRound: true,
            dotData: FlDotData(
              show: true,
              getDotPainter: (spot, percent, barData, index) =>
                  FlDotCirclePainter(
                radius: 4,
                color: Colors.blue,
                strokeWidth: 0,
              ),
            ),
            belowBarData: BarAreaData(
              show: true,
              color: Colors.blue.withValues(alpha: 0.1),
            ),
          ),
        ],
        minY: minY,
        maxY: maxY,
        lineTouchData: LineTouchData(
          enabled: true,
          touchTooltipData: LineTouchTooltipData(
            getTooltipItems: (touchedSpots) {
              return touchedSpots.map((LineBarSpot touchedBarSpot) {
                const flStyle = TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                );
                return LineTooltipItem(
                  'Year: ${touchedBarSpot.x.toInt()}\nAvg $metric: ${touchedBarSpot.y.toStringAsFixed(3)}',
                  flStyle,
                );
              }).toList();
            },
          ),
        ),
      ),
    ),
  );
}
```

**Visual Design:**
- Single blue solid line
- Light blue fill below the line (semi-transparent)
- Dots at each year's data point
- Same grid and interactive tooltips as TimeSeriesLineChart
- Tooltip shows: "Year: XXXX\nAvg [metric]: X.XXX"

---

#### Common Helper Methods (Both Charts)

##### `_getYearInterval()`

```dart
double _getYearInterval() {
  final yearRange = data.endYear - data.startYear;
  if (yearRange <= 5) return 1;      // 1985, 1986, 1987, ...
  if (yearRange <= 10) return 2;     // 1985, 1987, 1989, ...
  if (yearRange <= 20) return 5;     // 1985, 1990, 1995, ...
  return 10;                          // 1985, 1995, 2005, 2015, ...
}
```

**Purpose:** Prevent X-axis label crowding by adapting interval to range
- **Small ranges (≤5 years):** Show every year
- **Medium ranges (≤10 years):** Show every 2 years
- **Large ranges (≤20 years):** Show every 5 years
- **Very large ranges (>20 years):** Show every 10 years

**Example:**
- Showing 2000-2024 (24 years) → returns 10 → shows: 2000, 2010, 2020
- Showing 2020-2024 (4 years) → returns 1 → shows: 2020, 2021, 2022, 2023, 2024

---

##### `_getValueInterval(double range)`

```dart
double _getValueInterval(double range) {
  if (range <= 0.1) return 0.01;     // Fine scale: 0.00, 0.01, 0.02, ...
  if (range <= 1) return 0.1;        // Medium: 0.0, 0.1, 0.2, ...
  if (range <= 10) return 1;         // Standard: 0, 1, 2, 3, ...
  if (range <= 100) return 10;       // Large: 0, 10, 20, 30, ...
  return 50;                          // Very large: 0, 50, 100, 150, ...
}
```

**Purpose:** Adapt Y-axis interval based on data range to maintain readability
- **Small ranges (≤0.1):** Fine intervals (0.01)
- **Medium ranges (≤1):** Moderate intervals (0.1)
- **Standard ranges (≤10):** Unit intervals (1)
- **Large ranges (≤100):** Tens (10)
- **Very large ranges (>100):** Fifties (50)

**Example:**
- NDVI values 0.30-0.60 (range=0.30) → returns 0.1 → shows: 0.3, 0.4, 0.5, 0.6
- Temperature 15-35°C (range=20) → returns 10 → shows: 15, 25, 35

---

### 4. **charts_services.dart** - API & Data Models

#### ChartsServices Class

##### `getAllAreas()` - Fetch available areas

```dart
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
        return List<int>.from(responseData['areas']);
      }
    }
    return null;
  } catch (e) {
    print("Error fetching areas: $e");
    return null;
  }
}
```

**API Call:** `GET /api?areas=1`

**Response Expected:**
```json
{
  "areas": [1, 2, 3, 4, 5]
}
```

---

##### `getChartData()` - Fetch chart data

```dart
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
      throw Exception('Invalid year range');
    }

    // Build URL with query parameters
    final url =
        "$_baseUrl/api?chart=1&startYear=$startYear&endYear=$endYear"
        "&areaId=$areaId&season=$season&metric=$metric";

    final response = await dio.get(url, ...);

    if (response.statusCode == 200) {
      var responseData = response.data;
      if (responseData is String) {
        responseData = jsonDecode(responseData);
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
```

**API Call:** `GET /api?chart=1&startYear=2000&endYear=2024&areaId=all&season=all&metric=ndvi`

**Parameters:**
- `startYear`: 1984 to 2050
- `endYear`: 1984 to 2050
- `areaId`: 'all' or specific area ID (as string)
- `season`: 'all', 'winter', 'spring', 'summer', 'autumn'
- `metric`: 'ndvi', 'evi', 'ndwi', 'temp'

---

#### Data Models

##### ChartDataResponse

Represents the entire chart data response.

```dart
class ChartDataResponse {
  final int startYear;
  final int endYear;
  final dynamic areaId;                    // 'all' or int
  final String season;
  final String metric;
  final List<ChartDataPoint> data;         // Actual data points
  final ChartMetadata metadata;            // Summary info

  factory ChartDataResponse.fromJson(Map<String, dynamic> json) {
    // Parse array of data points
    List<ChartDataPoint> dataPoints = [];
    if (json['data'] is List) {
      dataPoints = (json['data'] as List)
          .map((e) => ChartDataPoint.fromJson(e))
          .toList();
    }

    return ChartDataResponse(
      startYear: json['startYear'] ?? 0,
      endYear: json['endYear'] ?? 0,
      areaId: json['areaId'],
      season: json['season'] ?? 'all',
      metric: json['metric'] ?? 'ndvi',
      data: dataPoints,
      metadata: ChartMetadata.fromJson(json['metadata'] ?? {}),
    );
  }

  // Helper methods
  Map<int, double> getAverageByYear() { ... }
  Map<int, double> getAverageByArea() { ... }
  List<ChartDataPoint> getDataForArea(int areaId) { ... }
  List<ChartDataPoint> getDataForSeason(String season) { ... }
}
```

**Helper Methods Explained:**

`getAverageByYear()` - Returns map of year → average value
```dart
Map<int, double> getAverageByYear() {
  Map<int, double> yearAverages = {};
  Map<int, List<double>> yearValues = {};

  // Group values by year
  for (var point in data) {
    yearValues.putIfAbsent(point.year, () => []).add(point.value);
  }

  // Average each year
  yearValues.forEach((year, values) {
    yearAverages[year] = values.reduce((a, b) => a + b) / values.length;
  });

  return yearAverages;
}
```

---

##### ChartDataPoint

Individual data point.

```dart
class ChartDataPoint {
  final int? id;
  final int areaId;
  final int year;
  final String season;
  final double value;                    // The actual metric value
  final bool isPrediction;               // Is this historical or predicted?

  factory ChartDataPoint.fromJson(Map<String, dynamic> json) {
    return ChartDataPoint(
      id: json['id'],
      areaId: json['area_id'] ?? 0,
      year: json['year'] ?? 0,
      season: json['season'] ?? 'unknown',
      value: (extract numeric metric value from json),
      isPrediction: json['is_prediction'] ?? false,
    );
  }
}
```

**Key Field:** `isPrediction` - Determines if data point uses blue (false) or orange (true) in charts.

---

##### ChartMetadata

Summary metadata about the dataset.

```dart
class ChartMetadata {
  final List<int> historicalYears;     // Which years have real data
  final List<int> predictedYears;      // Which years have predictions
  final int totalDataPoints;           // Total count

  factory ChartMetadata.fromJson(Map<String, dynamic> json) {
    return ChartMetadata(
      historicalYears: List<int>.from(json['historical_years'] ?? []),
      predictedYears: List<int>.from(json['predicted_years'] ?? []),
      totalDataPoints: json['total_data_points'] ?? 0,
    );
  }
}
```

Used to display information like:
```
Historical Years: 1984 - 2023
Predicted Years: 2024 - 2050
Total Data Points: 1,234
```

---

## Complete User Flow

### Scenario: User wants to see NDVI predictions for Area 5 from 2010 to 2025

1. **Page Loads**
   - `initState()` calls `_loadAreas()`
   - Backend returns: `[1, 2, 3, 4, 5, 6]`
   - Area dropdown populated

2. **User Selects Options**
   - Metric: `ndvi`
   - Area: `5`
   - Season: `all`
   - Years: `2010` to `2025`

3. **User Clicks "Generate Chart"**
   - Validation passes
   - Loading spinner shows
   - API call: `GET /api?chart=1&startYear=2010&endYear=2025&areaId=5&season=all&metric=ndvi`

4. **Backend Returns Data**
   ```json
   {
     "startYear": 2010,
     "endYear": 2025,
     "areaId": 5,
     "season": "all",
     "metric": "ndvi",
     "data": [
       {"id": 1, "area_id": 5, "year": 2010, "season": "all", "ndvi": 0.45, "is_prediction": false},
       {"id": 2, "area_id": 5, "year": 2011, "season": "all", "ndvi": 0.47, "is_prediction": false},
       ...
       {"id": 16, "area_id": 5, "year": 2024, "season": "all", "ndvi": 0.52, "is_prediction": true},
       {"id": 17, "area_id": 5, "year": 2025, "season": "all", "ndvi": 0.53, "is_prediction": true}
     ],
     "metadata": {
       "historical_years": [2010, 2011, ..., 2023],
       "predicted_years": [2024, 2025],
       "total_data_points": 16
     }
   }
   ```

5. **Data Processing**
   - `ChartDataResponse.fromJson()` parses data
   - 16 `ChartDataPoint` objects created
   - Metadata stored

6. **Chart Display Decision**
   - `selectedAreaId = '5'` (not 'all')
   - Use `TimeSeriesLineChart`

7. **TimeSeriesLineChart Processing**
   - Filters by area 5 (already filtered by API)
   - Separates into historical (2010-2023) and predicted (2024-2025)
   - Groups by year (already 1 per year in this case)
   - Creates two line chart data sets
   - Y-axis range calculated

8. **Rendering**
   - Legend shows: "Historical Data (Blue)" and "Predicted Data (Orange)"
   - Blue line: 2010-2023 with solid line and dots
   - Orange line: 2024-2025 with dashed line and dots
   - X-axis: Years (interval = 2)
   - Y-axis: NDVI values (interval auto-calculated)
   - Tooltip on hover shows: "Year: 2024, Value: 0.520"

9. **Summary Display**
   - Average NDVI: 0.49
   - Min NDVI: 0.45
   - Max NDVI: 0.53
   - Data Points: 16

---

## Key Design Decisions

### 1. **Two Chart Components**
- **TimeSeriesLineChart:** For specific area analysis
- **AverageTimeSeriesChart:** For aggregated view
- Prevents code duplication while serving different use cases

### 2. **Historical vs Predicted Visualization**
- Solid blue for observed data (trustworthy)
- Dashed orange for predictions (uncertain)
- Clear visual distinction helps users understand data reliability

### 3. **Smart Axis Intervals**
- Adapts to data range to avoid overcrowding
- Improves readability across different scales

### 4. **Data Aggregation**
- Multiple data points per year per area are averaged
- Simplifies visualization
- Reduces chart complexity

### 5. **Client-Side Filtering**
- Area filtering happens in API (recommended)
- Could be done client-side if all data fetched
- Reduces payload size

---

## Error Handling

### Validation Errors
- Start year > End year → Error message shown
- Years out of range → Error message shown

### API Errors
- Network failure → Error message with exception
- Empty data → Message asking to change filters
- Invalid JSON → Error message

### UI Errors
- No data available → "No data available" message in chart area
- Empty dropdown → Shows all areas as default

---

## Performance Considerations

1. **Data Size:** If many data points, consider pagination
2. **API Response:** Backend should filter/aggregate to reduce payload
3. **Chart Rendering:** fl_chart handles large datasets efficiently
4. **State Management:** Using simple `setState()` is fine for this scale

---

## Extension Points

### To Add a New Metric
1. Add to `metrics` list in `charts_page.dart`
2. Update `getMetricLabel()` switch statement
3. Backend handles the rest

### To Add a New Season
1. Add to `seasons` list
2. Update `getSeasonLabel()` switch statement
3. Backend already filters by season

### To Add a New Chart Type
1. Create new component in `time_series_chart.dart`
2. Add conditional logic in `charts_page.dart` build method
3. Implement data processing similar to existing components

---

## Summary

The charts system provides an interactive way to explore environmental data with filtering by metric, area, season, and year range. It combines historical observations with future predictions and visualizes them clearly using color coding and line styles. The architecture separates concerns between data fetching, state management, and visualization, making it maintainable and extensible.
