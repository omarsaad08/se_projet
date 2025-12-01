# Charts System - Quick Reference Card

## 🚀 Quick Start

### 1. Start Backend Services
```bash
# Flask (predictions)
cd se_project_backend
python src/models/predict_service.py
# Runs on http://localhost:5000

# PHP/MySQL (should be running)
# Update ngrok URL in code if needed
```

### 2. Run Flutter App
```bash
cd se_project
flutter pub get
flutter run
```

### 3. Navigate to Charts
Click "Charts" in the navbar to view the page.

---

## 📊 What Users See

### Filters
```
┌─────────────────────────────────────┐
│ METRIC SELECTOR                     │
│ ┌─ NDVI                             │
│ ├─ EVI                              │
│ ├─ NDWI                             │
│ └─ Temperature                      │
├─────────────────────────────────────┤
│ AREA SELECTOR                       │
│ ┌─ All Areas (average)              │
│ ├─ Area 1                           │
│ ├─ Area 2                           │
│ ├─ Area 3                           │
│ ├─ Area 4                           │
│ └─ Area 5                           │
├─────────────────────────────────────┤
│ SEASON SELECTOR                     │
│ ┌─ All Seasons                      │
│ ├─ Winter                           │
│ ├─ Spring                           │
│ ├─ Summer                           │
│ └─ Autumn                           │
├─────────────────────────────────────┤
│ YEAR RANGE                          │
│ Start: [1984 ▼] End: [2050 ▼]      │
├─────────────────────────────────────┤
│ [GENERATE CHART]                    │
└─────────────────────────────────────┘
```

### Chart Display
```
┌──────────────────────────────────────┐
│ NDVI - All Seasons (2000-2040)      │
├──────────────────────────────────────┤
│  0.6 ┤                  ╭─────╮      │
│  0.5 ┤    ╭──╮      ╭───╯    │      │
│  0.4 ┤╭──╯  ╰──╮───╯        ╰──    │
│      │                              │
│  2000 .... 2024 ≈≈ 2025 .... 2040   │
│                                      │
│ ● Historical Data (actual)           │
│ ≈ Predicted Data (forecast)          │
└──────────────────────────────────────┘
```

---

## 🔧 Configuration

### Backend URL (PHP)
**File**: `src/controllers/ChartsController.php` Line 11
```php
private $flaskUrl = "http://host.docker.internal:5000";
```
Change if Flask on different machine.

### Frontend URL (Dart)
**File**: `lib/data/charts_services.dart` Line 5
```dart
static const String _baseUrl = "https://6112658ce01c.ngrok-free.app";
```
Update with your backend URL.

---

## 📋 API Endpoints

### Get Areas
```
GET /api?areas=1
Response: {"areas": [1,2,3,4,5], "count": 5}
```

### Get Chart Data
```
GET /api?chart=1&startYear=2000&endYear=2040&areaId=all&season=all&metric=ndvi
Response: {data: [...], metadata: {...}}
```

---

## ✅ Validation Rules

| Field | Valid Range | Examples |
|-------|------------|----------|
| startYear | 1984-2050 | 2000, 2025, 2050 |
| endYear | 1984-2050 | 2024, 2040, 2050 |
| Constraint | startYear ≤ endYear | ✅ 2000-2040, ❌ 2040-2000 |
| Metric | 4 values | ndvi, evi, ndwi, temp |
| Season | 5 values | all, winter, spring, summer, autumn |
| Area | 6 values | all, 1, 2, 3, 4, 5 |

---

## 📂 Key Files

### Backend
```
ChartsController.php    ← Main logic
predict_service.py      ← Flask service
PREDICTION_SYSTEM_EXPLAINED.md  ← How ML works
CHARTS_SYSTEM.md        ← System architecture
```

### Frontend
```
charts_page.dart        ← Main UI page
charts_services.dart    ← API communication
time_series_chart.dart  ← Chart visualization
CHARTS_INTEGRATION_GUIDE.md  ← Setup guide
```

---

## 🔍 How It Works (Simple)

```
User Selects Filters
        ↓
PHP Gets Historical Data (from MySQL)
        ↓
PHP Gets Predicted Data (from Flask)
        ↓
PHP Merges Both Datasets
        ↓
Frontend Receives Combined Data
        ↓
Chart Displays Two Lines:
  • Blue (historical)
  • Orange (predicted)
```

---

## ⚡ Common Tasks

### View Last 25 Years of NDVI
- Metric: NDVI
- Area: All Areas
- Season: All Seasons
- Years: 2000-2024

### Analyze Single Area Winter Trends
- Metric: Any (choose one)
- Area: Area 1 (or 2-5)
- Season: Winter
- Years: 1984-2050

### Compare All Seasons for One Area
- Metric: NDVI
- Area: Area 3
- Season: All Seasons (shows average)
- Years: 2010-2030

---

## 🐛 Quick Troubleshooting

| Problem | Check |
|---------|-------|
| No data | Flask running? Year range valid? |
| Slow loading | Reduce years? Use 1 season? |
| Chart not visible | fl_chart installed? |
| Wrong values | Scaling correct? Models loaded? |
| Connection error | Backend URL correct? Network ok? |

---

## 📊 Data Types

### Historical (≤2024)
- ✅ From database
- ✅ Actual measurements
- ✅ Blue solid line

### Predicted (≥2025)
- ✅ From ML models
- ✅ XGBoost forecasts
- ✅ Orange dashed line

---

## 🎯 Performance Tips

✅ **Faster Loading:**
- Use specific years (not 1984-2050)
- Use one season (not "all")
- Use one area (not "all")

❌ **Slower Loading:**
- Large year ranges
- All seasons (4× multiplier)
- All areas requires aggregation

---

## 📚 Detailed Documentation

For complete information, see:
- `CHARTS_SYSTEM.md` (architecture)
- `CHARTS_INTEGRATION_GUIDE.md` (setup)
- `PREDICTION_SYSTEM_EXPLAINED.md` (ML details)
- `IMPLEMENTATION_COMPLETE.md` (full summary)

---

## ✨ Features at a Glance

✅ Interactive filters
✅ 40-year data range (1984-2050)
✅ Historical + predicted data
✅ 4 environmental metrics
✅ 5 protected areas
✅ 4 seasons
✅ Real-time validation
✅ Error handling
✅ Responsive charts
✅ Data summary stats
✅ Tooltip information
✅ Grid references

---

## 🔐 Status

**Version**: 1.0
**Status**: ✅ Production Ready
**Created**: December 1, 2025
**Tested**: ✅ All components
**Documented**: ✅ Complete

---

## 📞 Support

If issues occur:
1. Check endpoints with curl
2. Review console logs
3. Verify backend running
4. Check database connectivity
5. Review detailed documentation

---

**Built with**: Flutter + PHP + Python + XGBoost + fl_chart
**Time to Implement**: ~30 mins
**Ready to Deploy**: ✅ Yes
