# Charts System - Architecture & Diagrams

## High-Level System Architecture

```
┌──────────────────────────────────────────────────────────────────────┐
│                         FRONTEND (Flutter)                           │
│                                                                      │
│  ┌─────────────────────────────────────────────────────────────┐   │
│  │                    CHARTS PAGE                              │   │
│  │                                                             │   │
│  │  ┌──────────────┐  ┌─────────────┐  ┌──────────────────┐  │   │
│  │  │ Metric       │  │ Area        │  │ Season           │  │   │
│  │  │ Selector     │  │ Selector    │  │ Selector         │  │   │
│  │  └──────────────┘  └─────────────┘  └──────────────────┘  │   │
│  │         │                 │                    │           │   │
│  │         └─────────────────┴────────────────────┘           │   │
│  │                        │                                   │   │
│  │         ┌──────────────────────────────┐                  │   │
│  │         │  Year Range Selector         │                  │   │
│  │         │  Start: [______] End: [___] │                  │   │
│  │         └──────────────────────────────┘                  │   │
│  │                        │                                   │   │
│  │              [GENERATE CHART BUTTON]                      │   │
│  │                        │                                   │   │
│  │         ┌──────────────────────────────┐                  │   │
│  │         │  CHART DISPLAY               │                  │   │
│  │         │                              │                  │   │
│  │         │  ╭────────────────╮          │                  │   │
│  │         │ ╭╯                ╰╮         │                  │   │
│  │         │╱                    ╲        │                  │   │
│  │         │                      ╲      │                  │   │
│  │         │                       ╲─────│                  │   │
│  │         └──────────────────────────────┘                  │   │
│  │                                                             │   │
│  │         ┌──────────────────────────────┐                  │   │
│  │         │  Data Summary                │                  │   │
│  │         │  Avg: 0.45  Min: 0.40        │                  │   │
│  │         │  Max: 0.50  Points: 820      │                  │   │
│  │         └──────────────────────────────┘                  │   │
│  └─────────────────────────────────────────────────────────────┘   │
│                                                                      │
│                    ▼                                                 │
│              ChartsServices (API Layer)                             │
│                                                                      │
└──────────────────────────────────────────────────────────────────────┘
                            │
                    HTTP GET Request
                            │
                            ▼
┌──────────────────────────────────────────────────────────────────────┐
│                      BACKEND (PHP)                                   │
│                                                                      │
│              ChartsController::getChartData()                        │
│                        │                                            │
│         ┌──────────────┼──────────────┐                             │
│         │              │              │                             │
│         ▼              ▼              ▼                             │
│    Validation      Year Split     Area Check                        │
│    - Years         Historical     From DB                           │
│    - Metric        vs Predicted   (Verify)                          │
│    - Season                                                         │
│    - Area                                                           │
│         │              │              │                             │
│         └──────────────┴──────────────┘                             │
│                        │                                            │
│         ┌──────────────┴──────────────┐                             │
│         │                             │                             │
│         ▼                             ▼                             │
│    Historical Data            Predicted Data                        │
│    (≤2024)                    (≥2025)                               │
│         │                             │                             │
│         │ SELECT * FROM               │ POST /predict-batch        │
│         │ WHERE year                  │ to Flask                   │
│         │ BETWEEN 2000 AND 2024      │                             │
│         │                             │                             │
│         ▼                             ▼                             │
│    ┌─────────────┐             ┌─────────────┐                    │
│    │  MySQL DB   │             │ Flask       │                    │
│    │ ~100 points │             │ ~720 points │                    │
│    │ (4 queries) │             │ (16 calls)  │                    │
│    └─────────────┘             └─────────────┘                    │
│         │                             │                             │
│         └──────────────┬──────────────┘                             │
│                        │                                            │
│                        ▼                                            │
│                 Merge & Sort                                        │
│                 - Combine datasets                                  │
│                 - Sort by year, area_id                            │
│                 - Add metadata                                     │
│                 - 820 total points                                 │
│                        │                                            │
│                        ▼                                            │
│              JSON Response sent to frontend                         │
│                                                                      │
└──────────────────────────────────────────────────────────────────────┘
```

---

## Data Flow Diagram

### Request Timeline

```
Time  │ Frontend          │ Backend         │ Database/ML
──────┼──────────────────┼─────────────────┼──────────────────
  0ms │ User clicks      │                 │
      │ "Generate"       │                 │
      │                  │                 │
  1ms │ Validate inputs  │                 │
      │ Create request   │                 │
      │                  │                 │
  5ms │ Send HTTP GET    │                 │
      │ /api?chart=1...  │ Receive         │
      │                  │                 │
 10ms │                  │ Validate params │
      │                  │ Parse query     │
      │                  │                 │
 20ms │                  │ Query MySQL     │                  Query
      │                  │ getHistorical()  ├─────────────────────→
      │                  │                 │
200ms │                  │                 │ Return 100 points
      │                  │                 │ (historical data)
      │                  │←─────────────────│
      │                  │                 │
210ms │                  │ For each year:  │
      │                  │ 2025-2040       │
      │                  │ season=all      │
      │                  │ (16 iterations) │
      │                  │                 │
220ms │                  │ Flask call 1    │                Model 1
      │                  │ /predict-batch  ├─────────────────────→
      │                  │ (5 areas)       │
      │                  │                 │
250ms │                  │                 │ Return 5 predictions
      │                  │←─────────────────│
      │                  │                 │
      │                  │ Flask call 2... │
      │                  │ (15 more calls) │
      │                  │                 │
      │                  │ Calls span:     │
3500ms │                  │ 250-3500ms      │
      │                  │ (3.25 seconds)  │
      │                  │                 │
3510ms│                  │ All predictions │
      │                  │ collected       │
      │                  │ Merge data      │
      │                  │                 │
3520ms│                  │ Response ready  │
      │                  │ Send JSON       │
      │                  │                 │
3525ms│ Receive response │                 │
      │ Parse JSON       │                 │
      │                 │                 │
3530ms│ Create chart    │                 │
      │ Render to screen │                 │
      │                 │                 │
3600ms│ Chart visible   │                 │
      │ to user         │                 │
```

**Total time: ~3.6 seconds for 2000-2040 data**

---

## Data Structure Diagram

### Request

```
GET /api?chart=1&startYear=2000&endYear=2040&areaId=all&season=all&metric=ndvi

Query Parameters:
├── chart: 1 (flag to route to ChartsController)
├── startYear: 2000
├── endYear: 2040
├── areaId: "all"
├── season: "all"
└── metric: "ndvi"
```

### Response

```json
{
  "startYear": 2000,           // Echo back
  "endYear": 2040,             // Echo back
  "areaId": "all",             // Echo back
  "season": "all",             // Echo back
  "metric": "ndvi",            // Echo back
  
  "data": [                    // Array of 820 points
    {
      "id": null,              // null for predictions
      "area_id": 1,            // Protected area ID
      "year": 2000,            // Year of data
      "season": "winter",      // Season
      "ndvi": 0.45,            // NDVI value
      "is_prediction": false   // Historical or predicted
    },
    {
      "id": null,
      "area_id": 2,
      "year": 2000,
      "season": "winter",
      "ndvi": 0.48,
      "is_prediction": false
    },
    // ... 818 more points, mixed historical/predicted
  ],
  
  "metadata": {
    "historical_years": [2000, 2001, ..., 2024],  // 25 years
    "predicted_years": [2025, 2026, ..., 2040],   // 16 years
    "total_data_points": 820
  }
}
```

---

## Component Interaction Diagram

```
┌─────────────────────────────────────────────────────┐
│ Flutter App                                         │
│                                                     │
│  ChartsPage (StatefulWidget)                       │
│  ├─ State management:                              │
│  │  ├─ selectedMetric                              │
│  │  ├─ selectedSeason                              │
│  │  ├─ selectedAreaId                              │
│  │  ├─ startYear                                   │
│  │  ├─ endYear                                     │
│  │  ├─ chartData                                   │
│  │  └─ isLoading                                   │
│  │                                                 │
│  ├─ Methods:                                       │
│  │  ├─ _loadAreas()      ────┐                    │
│  │  ├─ _isValidChartSelection()                   │
│  │  └─ _generateChart()      │ Calls              │
│  │         │                 │                    │
│  │         └────────────────→│                    │
│  │                           │                    │
│  └─────────────────────────────────────────┐      │
│                                            │      │
│                         ChartsServices     │      │
│                         ├─ getAllAreas()   │◄─────┘
│                         └─ getChartData()  │◄─────────┐
│                                            │          │
│                                            ├──────────┼─────┐
└────────────────────────────────────────────┘          │     │
                                                        │     │
                    HTTP GET                            │     │
                         ▼                              │     │
┌─────────────────────────────────────────────────────┐│     │
│ PHP Backend                                         ││     │
│                                                     ││     │
│ index.php                                          ││     │
│  └─ Routes to ChartsController                     ││     │
│      └─ handleGet()                               ││     │
│          ├─ getChartData()                        ││     │
│          │  ├─ _isValidChartSelection()           ││     │
│          │  ├─ getHistoricalData() ──────┐        ││     │
│          │  ├─ getPredictedData()        │        ││     │
│          │  └─ Returns merged JSON       │        ││     │
│          │                               │        ││     │
│          └─ getAllAreas()  ──────────────┼────────┘│     │
│             └─ Returns area list         │         │     │
│                                          ▼         │     │
│                                       MySQL        │     │
│                                       Database     │     │
│                                                    │     │
│ Calls to Flask:                                   │     │
│  makePredictionRequest()                          │     │
│   └─ POST /predict-batch                          │     │
│      Returns predictions                          │     │
└────────────────────────────────────────────────────┘     │
                                                           │
                    JSON Response ◄─────────────────────────┘
```

---

## State Management Flow

```
ChartsPage UI Update Cycle:

User Input (dropdown, button click)
    ↓
setState({ variable = newValue })
    ↓
Widget rebuild triggered
    ↓
Build method called
    ↓
UI reflects new state
    ↓
If Generate button clicked:
    ├─ _isValidChartSelection()
    │  ├─ Validate years
    │  ├─ Validate metric
    │  ├─ Validate season
    │  └─ Validate area
    │
    ├─ setState({ isLoading = true })
    │  ↓ (UI shows loading spinner)
    │
    ├─ ChartsServices.getChartData()
    │  ├─ Build URL with parameters
    │  ├─ Make HTTP GET request
    │  ├─ Parse JSON response
    │  └─ Return ChartDataResponse
    │
    └─ setState({ 
         isLoading = false
         chartData = response
       })
       ↓ (UI renders chart)
```

---

## Chart Rendering Logic

```
if (chartData == null)
    Display: "Select filters and generate chart"

else if (chartData.data.isEmpty)
    Display: "No data for selection"

else if (selectedAreaId == 'all')
    ├─ Use: AverageTimeSeriesChart
    ├─ Process:
    │  ├─ Group data by year
    │  ├─ Calculate average per year across all areas
    │  └─ Create single line chart
    └─ Display: Yearly trend line

else
    ├─ Use: TimeSeriesLineChart
    ├─ Process:
    │  ├─ Filter data for selected area
    │  ├─ Separate historical vs predicted
    │  ├─ Group by year
    │  ├─ Calculate average per year per data type
    │  └─ Create dual line chart
    └─ Display: 
       ├─ Blue solid line (historical ≤2024)
       └─ Orange dashed line (predicted ≥2025)
```

---

## Error Handling Flow

```
User Request
    ↓
ChartsPage._generateChart()
    ├─ if (!_isValidChartSelection())
    │  └─ Show error message
    │     └─ Return (do nothing)
    │
    ├─ setState({ isLoading = true })
    │
    └─ try {
        ├─ ChartsServices.getChartData()
        │  ├─ if (response.statusCode == 200)
        │  │  └─ Parse and return
        │  └─ else
        │     └─ throw exception
        │
        ├─ if (data == null || data.data.isEmpty)
        │  └─ Show "No data" message
        │
        └─ setState({ chartData = data })
    }
    catch (e) {
        └─ setState({
             errorMessage = "Error: $e"
             chartData = null
           })
    }
    finally {
        └─ setState({ isLoading = false })
    }
```

---

## Database Query Flow

### Historical Data Query

```
ChartsController::getHistoricalData()
    │
    └─ Build SQL:
       │
       SELECT id, area_id, year, season, ndvi, evi, ndwi, temp
       FROM environmental_data
       WHERE year BETWEEN ? AND ?
       [AND area_id = ?]
       [AND season = ?]
       ORDER BY year ASC, area_id ASC
       │
       └─ Execute with parameters:
          ├─ startYear (e.g., 2000)
          ├─ endYear (e.g., 2024)
          ├─ area_id (optional, if not 'all')
          └─ season (optional, if not 'all')
          
          ↓ Result: 100-400 rows
```

### Predicted Data Query (via Flask)

```
ChartsController::getPredictedData()
    │
    ├─ Get all areas from DB
    │  SELECT DISTINCT area_id FROM environmental_data
    │
    ├─ For each year in range (2025-2040):
    │  For each season (or all):
    │     ├─ Scale inputs:
    │     │  ├─ year_scaled = (year - 2000) / 25
    │     │  ├─ area_ids_scaled = (area_id - 16) / 9
    │     │  └─ season_one_hot = encode(season)
    │     │
    │     └─ POST to Flask:
    │        curl_exec(
    │          url: localhost:5000/predict-batch
    │          payload: {
    │            year_scaled,
    │            area_ids_scaled,
    │            season,
    │            metric
    │          }
    │        )
    │        ↓ Result: 5 predictions (1 per area)
    │
    └─ Collect all predictions
       Total: 16 years × 4 seasons × 5 areas
```

---

## Memory Usage Pattern

```
Initial Load:
├─ availableAreas: ~100 bytes (5 area IDs)
└─ Small UI state: ~500 bytes

After Chart Generation (2000-2040 example):
├─ chartData.data: 820 points × 100 bytes each = 82 KB
├─ chartData.metadata: ~1 KB
├─ Chart rendering data: ~50 KB
└─ Total: ~134 KB (fits comfortably in memory)

Typical Flutter app available: 500+ MB
Headroom: Excellent ✅
```

---

## Performance Profile

```
Operation              Time    Depends On
─────────────────────────────────────────────────────
Validate inputs        1ms     Input complexity
Get areas              100ms   Network + DB query
Get historical data    50-100ms Database size
Get predictions        2500-3500ms Flask latency × 16
Parse response         20ms    Data size
Render chart           80ms    Chart complexity
─────────────────────────────────────────────────────
Total (typical)        3500ms  ~3.6 seconds

Optimization:
- Cache areas on first load
- Batch predictions (current)
- Lazy load chart when needed
- Compress JSON responses
```

---

## Deployment Architecture

```
┌─────────────────────────────┐
│   Users' Devices            │
│   (Flutter App)             │
│                             │
│   ├─ iOS devices            │
│   ├─ Android devices        │
│   └─ Web (future)           │
└────────────┬────────────────┘
             │ HTTPS/TLS
             ▼
┌─────────────────────────────┐
│   Load Balancer (nginx)     │
│   :443 (HTTPS)              │
└────────┬────────────────────┘
         │
    ┌────┴────┬────────┐
    ▼         ▼        ▼
┌────────┬────────┬────────┐
│ PHP    │ PHP    │ PHP    │
│ Container 1    │ Container 2    │ Container 3
│ :80    │ :80    │ :80    │
└────┬───┴────┬───┴────┬───┘
     │        │        │
     └────────┼────────┘
              │
         ┌────▼──────┐
         │  MySQL DB │
         │  (Docker) │
         └───────────┘

         ┌─────────────────┐
         │ Flask Service   │
         │ :5000 (Docker)  │
         │ (XGBoost models)│
         └─────────────────┘
```

---

**Diagram Version**: 1.0  
**Date**: December 1, 2025  
**Status**: Complete
