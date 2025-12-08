# Software Engineering Principles Applied in This Project

## Overview

This document outlines the key software engineering principles and patterns implemented across the frontend (Flutter) and backend (PHP/Python) of the environmental data visualization system.

---

## Architecture & Design Patterns

### 1. **Layered Architecture (N-Tier)**

**Frontend:**
- **Presentation Layer:** `charts_page.dart`, `time_series_chart.dart` - UI components
- **Logic/State Layer:** State management in `_ChartsPageState`
- **Data Layer:** `charts_services.dart` - API communication

**Backend:**
- **Controller Layer:** `ChartsController.php`, `NdviController.php` - Request handling
- **Model Layer:** `NdviData.php` - Database operations
- **Service Layer:** `predict_service.py` - Business logic (predictions)
- **Database Layer:** MySQL - Data persistence

**Benefit:** Clear separation of concerns, easier to test and maintain.

---

### 2. **MVC Pattern (Model-View-Controller)**

**Frontend:**
- **Model:** `ChartDataResponse`, `ChartDataPoint`, `ChartMetadata` data classes
- **View:** `TimeSeriesLineChart`, `AverageTimeSeriesChart` widgets
- **Controller:** `_ChartsPageState` manages state and logic

**Backend:**
- **Model:** Database models in `models/` folder
- **View:** JSON responses returned to client
- **Controller:** Handles business logic and routing

**Benefit:** Standardized structure makes code predictable and organized.

---

### 3. **Service Layer Pattern**

**Frontend:**
```dart
class ChartsServices {
  static Future<List<int>?> getAllAreas() async { ... }
  static Future<ChartDataResponse?> getChartData(...) async { ... }
}
```

**Backend:**
```php
class ChartsController {
  public function getChartData() { ... }
}
```

**Benefit:** Encapsulates API communication logic, reusable across components.

---

## Design Principles

### 4. **SOLID Principles**

#### **S - Single Responsibility Principle**
- `ChartsServices` → Only handles API calls
- `TimeSeriesLineChart` → Only renders time series chart
- `ChartDataPoint` → Only represents a single data point
- `NdviController.php` → Only handles NDVI-related requests

**Benefit:** Each class has one reason to change.

---

#### **O - Open/Closed Principle**
- Chart components are **open for extension** (can inherit and customize)
- **Closed for modification** (use parameters instead of changing code)
- Example: `TimeSeriesLineChart` accepts different data via constructor parameters

**Benefit:** Add new metrics without modifying existing code.

---

#### **L - Liskov Substitution Principle**
- Both `TimeSeriesLineChart` and `AverageTimeSeriesChart` implement the same interface (StatelessWidget)
- Can be swapped without breaking the UI
- Backend: All controllers inherit from base controller pattern

**Benefit:** Flexible component composition in UI.

---

#### **I - Interface Segregation Principle**
- `ChartDataResponse` only exposes relevant methods
- Frontend doesn't access unnecessary backend details
- Backend models only expose needed fields

**Benefit:** Clients depend only on what they use.

---

#### **D - Dependency Inversion Principle**
- Frontend depends on abstractions (`ChartsServices` interface)
- Frontend doesn't depend on concrete HTTP implementation
- Easy to mock for testing

**Benefit:** Loose coupling, testable code.

---

### 5. **DRY (Don't Repeat Yourself)**

**Frontend:**
- `_getYearInterval()` and `_getValueInterval()` used by both chart components
- `_buildLegendItem()` creates legend items without duplication
- Reusable `_summaryRow()` widget

**Backend:**
- `Database.php` centralizes database connection
- Common validation logic extracted into methods
- Shared utility functions for data processing

**Benefit:** Reduced code duplication, easier maintenance.

---

### 6. **KISS (Keep It Simple, Stupid)**

- UI logic is straightforward and easy to follow
- Chart data filtering is simple and readable
- API endpoints are simple and focused
- Error handling uses clear try-catch blocks

**Benefit:** Code is easier to understand and maintain.

---

## Code Organization

### 7. **Modular Design**

**Frontend Modules:**
```
data/
  ├── charts_services.dart          # Data fetching
presentation/
  ├── screens/
  │   ├── charts.dart              # Screen wrapper
  │   └── charts_page.dart         # Screen logic
  └── components/
      └── time_series_chart.dart   # Reusable components
```

**Backend Modules:**
```
src/
  ├── controllers/                  # Request handlers
  ├── models/                       # Database models
  ├── config/                       # Database config
  └── index.php                     # Entry point
```

**Benefit:** Easy to locate code, clear responsibilities.

---

### 8. **Configuration Management**

**Frontend:**
```dart
static const String _baseUrl = "https://driveable-carmel-stalkily.ngrok-free.app";
static const List<String> metrics = ['ndvi', 'evi', 'ndwi', 'temp'];
static const int minYear = 1984;
```

**Backend:**
```php
// config/Database.php - centralized configuration
class Database {
  private $host = 'db_container';
  private $db = 'se_db';
}
```

**Benefit:** Easy to change settings without modifying logic code.

---

## Data Management

### 9. **Data Validation**

**Frontend:**
```dart
bool _isValidChartSelection() {
  if (startYear > endYear) return false;
  if (startYear < minYear || endYear > maxYear) return false;
  return true;
}
```

**Backend:**
```php
if (startYear < 1984 || endYear > 2050 || startYear > endYear) {
  throw Exception('Invalid year range');
}
```

**Benefit:** Prevents invalid data from being processed.

---

### 10. **Data Models & Type Safety**

**Frontend - Strongly Typed:**
```dart
class ChartDataResponse {
  final int startYear;
  final int endYear;
  final List<ChartDataPoint> data;
  final ChartMetadata metadata;
  
  factory ChartDataResponse.fromJson(Map<String, dynamic> json) { ... }
}
```

**Backend - PHP Type Hints:**
```php
public function getChartData(): ChartDataResponse {
  return new ChartDataResponse(...);
}
```

**Benefit:** Catches type errors early, improves code clarity.

---

### 11. **Separation of Concerns - Historical vs Predicted Data**

```dart
// Clear separation in data model
final bool isPrediction;

// Separate processing logic
if (point.isPrediction) {
  predictedYearValues[point.year]!.add(point.value);
} else {
  historicalYearValues[point.year]!.add(point.value);
}
```

**Benefit:** Easy to handle different data types differently.

---

## Error Handling & Validation

### 12. **Comprehensive Error Handling**

**Frontend:**
```dart
try {
  final data = await ChartsServices.getChartData(...);
  if (data != null && data.data.isNotEmpty) {
    setState(() { chartData = data; });
  } else {
    setState(() { errorMessage = 'No data available'; });
  }
} catch (e) {
  setState(() { errorMessage = 'Error: $e'; });
}
```

**Backend:**
```php
try {
  // Process request
} catch (Exception $e) {
  http_response_code(500);
  return json_encode(['error' => $e->getMessage()]);
}
```

**Benefit:** Graceful degradation, user-friendly error messages.

---

### 13. **Input Sanitization (Backend)**

```php
$startYear = (int)$_GET['startYear'];
$endYear = (int)$_GET['endYear'];
$areaId = isset($_GET['areaId']) ? $_GET['areaId'] : 'all';
```

**Benefit:** Prevents SQL injection and type errors.

---

## UI/UX Principles

### 14. **Progressive Enhancement**

**Frontend:**
1. Show loading state while fetching
2. Display error messages clearly
3. Show helpful instruction when no chart exists
4. Display data summary after chart loads

**Benefit:** User knows what's happening at each stage.

---

### 15. **Responsive & Adaptive UI**

**Frontend:**
```dart
Container(
  height: 300,  // Fixed size, adapts to parent
  width: double.infinity,
)
```

**Chart Axes:**
```dart
double _getYearInterval() {
  // Adapts label density to data range
}
```

**Benefit:** Works well on different screen sizes.

---

### 16. **Visual Feedback & Affordances**

- **Loading spinner:** Shows when fetching data
- **Error messages:** Clear, contextual error text
- **Legend:** Explains chart colors (blue=historical, orange=predicted)
- **Tooltips:** Interactive feedback on hover
- **Color coding:** Visually distinguishes data types

**Benefit:** Clear, intuitive user interface.

---

## Performance & Optimization

### 17. **Lazy Loading & On-Demand Fetching**

- Chart data only fetched when user clicks "Generate Chart"
- Areas fetched once on page load
- No unnecessary API calls

**Benefit:** Reduces server load, faster page load.

---

### 18. **Data Aggregation**

**Frontend:**
```dart
// Multiple data points per year averaged
final average = values.reduce((a, b) => a + b) / values.length;
```

**Benefit:** Reduces chart complexity, improves rendering performance.

---

### 19. **Smart Axis Intervals**

```dart
// Intervals adapt to data range
double _getYearInterval() {
  final yearRange = data.endYear - data.startYear;
  if (yearRange <= 5) return 1;
  if (yearRange <= 10) return 2;
  return 10;
}
```

**Benefit:** Chart remains readable at any zoom level.

---

## Testing & Maintainability

### 20. **Testability**

**Separation enables testing:**
- `ChartDataResponse.fromJson()` can be unit tested with mock JSON
- `_getYearInterval()` can be unit tested with different ranges
- API calls can be mocked in `ChartsServices`

**Benefit:** Easy to write unit tests.

---

### 21. **Code Readability**

- Clear variable names: `selectedAreaId`, `historicalYearValues`
- Meaningful method names: `_getLineChartBarData()`, `_isValidChartSelection()`
- Comments explain complex logic
- Consistent code style (Dart/PHP conventions)

**Benefit:** Easy to understand and modify.

---

### 22. **Logging & Debugging**

**Frontend:**
```dart
print("Requesting chart data: $url");
print("Chart response status: ${response.statusCode}");
```

**Backend:**
```php
error_log("Processing chart request: " . json_encode($_GET));
```

**Benefit:** Helps diagnose issues in production.

---

## API Design

### 23. **RESTful API Principles**

**Backend:**
- `/api?areas=1` → GET request to fetch areas
- `/api?chart=1&startYear=...&endYear=...` → GET request with query parameters
- Proper HTTP status codes (200 for success, 500 for error)
- JSON response format

**Benefit:** Standard, easy to use API.

---

### 24. **Stateless Communication**

- Each API request is independent
- No session state required
- Client can make requests in any order

**Benefit:** Scalable, easy to cache, load-balanceable.

---

## Database Design

### 25. **Relational Database Structure**

**Backend:**
- Normalized tables (areas, data points)
- Foreign keys establish relationships
- Indexes on frequently queried columns
- Clear schema definition

**Benefit:** Data integrity, efficient queries.

---

### 26. **SQL Queries Optimization**

**Backend:**
- Use `WHERE` clauses to filter at database level
- Aggregate data at database level (GROUP BY)
- Select only needed columns

**Benefit:** Reduces data transfer, improves performance.

---

## Version Control & Collaboration

### 27. **Git Repository Structure**

- Clear commit messages
- Organized folder structure
- Configuration files separated from code

**Benefit:** Easy to track changes, collaborate with team.

---

## Documentation

### 28. **Code Documentation**

**Frontend:**
```dart
/// Get chart data with merged historical and predicted data
///
/// Parameters:
/// - startYear: 1984 to 2050
/// - metric: 'ndvi', 'evi', 'ndwi', 'temp'
static Future<ChartDataResponse?> getChartData({...}) async
```

**Backend:**
- Inline comments explaining complex logic
- Method documentation with parameter descriptions

**Benefit:** Easier onboarding, clearer API contracts.

---

### 29. **Architecture Documentation**

- `CHARTS_SYSTEM_EXPLAINED.md` - System overview
- `CHARTS_INTEGRATION_GUIDE.md` - Integration instructions
- `README.md` - Project setup and overview
- `DEPLOY_QUICK_START.md` - Deployment guide

**Benefit:** New developers understand system quickly.

---

## Security

### 30. **Input Validation**

- Year range validated on both frontend and backend
- Area ID converted to integer (prevents injection)
- Metric and season values checked against allowed list

**Benefit:** Prevents invalid or malicious input.

---

### 31. **Error Information Leakage Prevention**

- Generic error messages to users
- Detailed logging on server side only
- No sensitive data in API responses

**Benefit:** Prevents information disclosure.

---

## Scalability & Maintainability

### 32. **Extensible Design**

**Easy to add:**
- New metrics (just update list and label method)
- New seasons (just update list and label method)
- New data visualization types (new chart component)
- New geographic areas (loaded from backend)

**Benefit:** System grows with requirements.

---

### 33. **Containerization (DevOps)**

**Backend:**
- `Dockerfile` - Standardized environment
- `docker-compose.yml` - Multi-container setup
- `nginx/nginx.conf` - Web server configuration

**Benefit:** Consistent deployment across environments.

---

## Summary of Key Principles

| Principle | Application | Benefit |
|-----------|-------------|---------|
| Separation of Concerns | Layered architecture | Easy to test and maintain |
| DRY | Reusable methods and components | Less code duplication |
| SOLID | Single responsibility per class | Flexible and extensible |
| Validation | Input checked at multiple layers | Data integrity |
| Error Handling | Try-catch blocks, user feedback | Graceful failures |
| Modularity | Organized folder structure | Easy to navigate |
| Documentation | Comments and guides | Faster onboarding |
| RESTful Design | Standard API endpoints | Easy to consume |
| Type Safety | Strong typing in both languages | Fewer runtime errors |
| Responsive UI | Adaptive components | Works on all devices |

---

## Conclusion

This project demonstrates professional software engineering practices by:

1. **Following established patterns** (MVC, layered architecture, service layer)
2. **Adhering to SOLID principles** for maintainable code
3. **Separating concerns** between frontend, backend, and database
4. **Validating inputs** at multiple layers for security
5. **Handling errors gracefully** with clear feedback
6. **Documenting** code and architecture thoroughly
7. **Organizing** code logically and modularly
8. **Designing** scalable, extensible systems
9. **Prioritizing** user experience and performance
10. **Enabling** easy testing and debugging

These practices make the codebase **maintainable**, **scalable**, **secure**, and **professional-grade**.
