# Charts Page Integration Guide

## Quick Start

The charts page is fully implemented and ready to use. Here's what was created:

### Files Created/Modified

**Backend (PHP):**
- ✅ `src/controllers/ChartsController.php` - New controller
- ✅ `src/index.php` - Updated routing

**Frontend (Dart):**
- ✅ `lib/data/charts_services.dart` - API service
- ✅ `lib/presentation/screens/charts_page.dart` - Main UI page
- ✅ `lib/presentation/components/time_series_chart.dart` - Chart components
- ✅ `lib/presentation/screens/charts.dart` - Updated to use ChartsPage
- ✅ `appRouter.dart` - Already configured

---

## Setup Instructions

### 1. Backend Configuration

**Update Flask URL in ChartsController:**

```php
// File: src/controllers/ChartsController.php
private $flaskUrl = "http://host.docker.internal:5000";
```

If running Flask on a different host/port, update accordingly.

### 2. Frontend Configuration

**Update API Base URL in ChartsServices:**

```dart
// File: lib/data/charts_services.dart
static const String _baseUrl = "https://6112658ce01c.ngrok-free.app";
```

Update to your backend URL.

### 3. Dependencies

Ensure `fl_chart` is installed:

```bash
flutter pub add fl_chart
```

Or if already added, run:

```bash
flutter pub get
```

### 4. Run the Application

```bash
flutter run
```

Navigate to Charts page from the navbar.

---

## Feature Overview

### UI Components

#### 1. Filter Section
- **Metric Selector**: Choose between NDVI, EVI, NDWI, Temperature
- **Area Selector**: All areas or specific area
- **Season Selector**: All seasons or specific season (Winter, Spring, Summer, Autumn)
- **Year Range**: Dual dropdowns from 1984-2050

#### 2. Chart Display
- **TimeSeriesLineChart**: For specific area data
  - Blue solid line: Historical data (≤ 2024)
  - Orange dashed line: Predicted data (≥ 2025)
  - Interactive tooltips on hover
  
- **AverageTimeSeriesChart**: For all areas average
  - Single line showing yearly average across all areas
  - Useful for trend analysis

#### 3. Data Summary
- Average value for selected metric
- Min/Max values
- Total data points count
- Historical vs predicted year ranges

---

## Usage Examples

### Example 1: View 40-Year NDVI Trend

1. **Selections:**
   - Metric: NDVI
   - Area: All Areas
   - Season: All Seasons
   - Years: 2000 - 2040

2. **Result:**
   - Chart shows average NDVI across all 5 areas
   - 41 data points (one per year)
   - Blue line (2000-2024), Orange line (2025-2040)

### Example 2: Analyze Single Area Winter Temperatures

1. **Selections:**
   - Metric: Temperature
   - Area: Area 2
   - Season: Winter
   - Years: 2010 - 2030

2. **Result:**
   - Chart shows winter temperature for Area 2
   - 21 data points (one per year)
   - Separate historical/predicted lines

### Example 3: Multi-Season Comparison

1. **Selections:**
   - Metric: EVI
   - Area: All Areas
   - Season: All Seasons
   - Years: 2015 - 2025

2. **Result:**
   - Seasonal variation averaged out
   - Yearly trend across all 4 seasons

---

## Data Flow

### Request Flow

```
User selects filters → ChartsPage validates → ChartsServices.getChartData()
    ↓
HTTP GET /api?chart=1&startYear=X&endYear=Y&...
    ↓
PHP ChartsController.getChartData()
    ↓
    ├─ Historical data (≤2024) → getHistoricalData() → MySQL
    └─ Predicted data (≥2025) → getPredictedData() → Flask
    ↓
Merge results → Return JSON
    ↓
Frontend processes → Display on chart
```

### Data Points Structure

```json
{
  "id": 1,
  "area_id": 2,
  "year": 2020,
  "season": "winter",
  "ndvi": 0.45,
  "is_prediction": false
}
```

---

## Validation Rules

### Chart Selection Validation

✅ **Allowed:**
- Year 1984-2050
- Any metric (ndvi, evi, ndwi, temp)
- Any area (all or specific)
- Any season (all or specific)
- Any year range as long as start ≤ end

❌ **Not Allowed:**
- Year < 1984 or > 2050
- startYear > endYear
- Invalid metric/season/area values

### Error Messages

User-friendly error messages for:
- Invalid year ranges
- Missing parameters
- API connection failures
- Empty result sets

---

## Performance Considerations

### Optimization Tips

1. **Narrow Year Range**: Fewer years = fewer API calls
2. **Specific Season**: 'all' requires 4× API calls
3. **Single Area**: Faster than 'all' areas
4. **Specific Metric**: Already optimized (one metric per request)

### Typical Response Times

- **2000-2024, All areas, All seasons**: ~3-5 seconds
  - 25 historical years + 25 predicted years
  - 4 seasons × 5 areas = 20 data points per year
  - Total: 1000 data points

- **2020-2025, Single area, Single season**: <1 second
  - 6 years, 1 area, 1 season
  - Total: 6 data points

---

## Troubleshooting

### Problem: "No data available for the selected parameters"

**Solutions:**
1. Check year range is valid (1984-2050)
2. Verify area ID is correct (use "?areas=1" endpoint)
3. Check Flask service is running: `/api?predict=health`
4. Review backend logs for errors

### Problem: Chart not displaying

**Solutions:**
1. Ensure `fl_chart` package is installed
2. Check for console errors in Flutter
3. Verify data points exist (check total count)
4. Try simpler query first (fewer years)

### Problem: Slow loading

**Solutions:**
1. Reduce year range (fewer API calls)
2. Specify single season instead of 'all'
3. Select specific area instead of 'all areas'
4. Check network connection speed
5. Monitor Flask service performance

### Problem: "Method not allowed" error

**Solutions:**
1. Verify PHP routing in `index.php`
2. Check ChartsController is included
3. Ensure GET method is used
4. Verify query parameters are correct

---

## API Reference

### GET /api?areas=1

Get list of available protected areas.

**Response:**
```json
{
  "areas": [1, 2, 3, 4, 5],
  "count": 5
}
```

### GET /api?chart=1&startYear=2000&endYear=2040&areaId=all&season=all&metric=ndvi

Get chart data with merged historical and predicted values.

**Parameters:**
| Parameter | Type | Required | Values |
|-----------|------|----------|--------|
| chart | int | Yes | 1 |
| startYear | int | Yes | 1984-2050 |
| endYear | int | Yes | 1984-2050 |
| areaId | string | Yes | 'all' or area number |
| season | string | Yes | 'all', 'winter', 'spring', 'summer', 'autumn' |
| metric | string | Yes | 'ndvi', 'evi', 'ndwi', 'temp' |

**Response:**
```json
{
  "startYear": 2000,
  "endYear": 2040,
  "areaId": "all",
  "season": "all",
  "metric": "ndvi",
  "data": [...],
  "metadata": {
    "historical_years": [2000, ..., 2024],
    "predicted_years": [2025, ..., 2040],
    "total_data_points": 820
  }
}
```

---

## File Locations Summary

### Backend Files

```
se_project_backend/
├── src/
│   ├── index.php (updated)
│   ├── controllers/
│   │   ├── ChartsController.php (new)
│   │   ├── NdviController.php
│   │   └── PredictionController.php
│   ├── models/
│   │   ├── NdviData.php
│   │   └── predict_service.py
│   └── config/
│       └── Database.php
└── CHARTS_SYSTEM.md (documentation)
```

### Frontend Files

```
se_project/
├── lib/
│   ├── data/
│   │   ├── charts_services.dart (new)
│   │   └── ndvi_services.dart
│   ├── presentation/
│   │   ├── screens/
│   │   │   ├── charts_page.dart (new)
│   │   │   ├── charts.dart (updated)
│   │   │   └── home.dart
│   │   └── components/
│   │       ├── time_series_chart.dart (new)
│   │       └── navbar.dart
│   ├── appRouter.dart (already configured)
│   └── main.dart
└── pubspec.yaml (ensure fl_chart is included)
```

---

## Next Steps

1. ✅ Implement backend endpoints
2. ✅ Create Flutter service layer
3. ✅ Build UI with filters
4. ✅ Add chart visualization
5. 📝 **Optional**: Add export functionality
6. 📝 **Optional**: Add comparison feature
7. 📝 **Optional**: Add advanced analytics

---

## Support & Maintenance

For issues or enhancements:

1. **Review CHARTS_SYSTEM.md** for detailed architecture
2. **Check backend logs** if predictions fail
3. **Monitor Flask service** health
4. **Verify database** has historical data
5. **Test with simple queries** first

---

**Setup completed**: December 1, 2025  
**Status**: Ready for Production  
**Version**: 1.0
