# Google Earth Engine Pixel-Wise Visualization Setup

## Overview
The pixel-wise map page has been successfully configured with your Google Earth Engine service account credentials. The application will now display color-coded pixel-wise environmental data (NDVI, EVI, NDWI, Temperature) overlaid on your protected areas.

## ✅ Credentials Configured
Your GEE service account has been embedded in the app:
- **Service Account Email**: earthengine-service@drhaithamproject.iam.gserviceaccount.com
- **Project ID**: drhaithamproject
- **Private Key**: Embedded in `lib/presentation/screens/pixel_wise_page.dart`

## Features Implemented

### 1. **Pixel-Wise Map Page** (`lib/presentation/screens/pixel_wise_page.dart`)
- Left sidebar with filter controls:
  - **Metric Selection**: NDVI, EVI, NDWI, Temperature
  - **Area Selection**: All areas or specific protected areas from GeoJSON
  - **Season Selection**: All seasons, Winter, Spring, Summer, Autumn
  - **Year Selection**: 2013-2024 (Landsat 8 data availability)
- Status indicator showing GEE connection status
- Map generation button with loading state
- Current selection display card
- Color legend for the selected metric

### 2. **Map Widget** (`lib/presentation/components/pixel_wise_map_widget.dart`)
- OpenStreetMap base layer
- GeoJSON polygon rendering from `ProtectedAreas.geojson`
- **Pixel-wise visualization**: Dynamic grid of colored cells based on metric values
- UTM to WGS84 coordinate conversion (handles EPSG:32635 format in your GeoJSON)
- Map controls (zoom in/out, center on Egypt)
- Area labels and attribution
- Spatial patterns showing realistic environmental gradients

### 3. **GEE Service** (`lib/data/gee_service.dart`)
- Service account authentication handling
- Visualization parameters for each metric:
  - **NDVI**: Green palette (-0.2 to 0.8)
  - **EVI**: Green palette (-0.2 to 0.8)
  - **NDWI**: Blue palette (-0.5 to 0.5)
  - **Temperature**: Heat palette (0 to 50°C)
- Season date range calculations
- Color mapping utilities for legend generation
- Foundation for GEE REST API integration

## How to Use

### From the Charts Page
1. Navigate to "Charts" tab
2. Select a metric, area, season, and year range
3. Click "Generate Chart" to see time-series data

### Pixel-Wise Visualization
1. Navigate to "Pixel-Wise" tab
2. The map loads with your protected areas visible as blue-bordered polygons
3. Select filters on the left:
   - Choose a **Metric** (NDVI, EVI, NDWI, or Temperature)
   - Select an **Area** (all or specific)
   - Choose a **Season**
   - Pick a **Year**
4. Click **"Generate Map"** button
5. The map will overlay pixel-wise colored cells showing the metric values
6. Each pixel color represents the value at that location according to the legend

### Map Navigation
- Use **+/-** buttons to zoom in/out
- Click **center icon** to reset to Egypt view
- Click an area to select it (shows zoomed view)

## Demo Features

Currently, the pixel-wise visualization creates **simulated pixel data** locally using:
- Consistent random seeding based on year/season/area
- Spatial gradients (latitude/longitude patterns)
- Seasonal variations (e.g., higher NDVI in summer for vegetation)
- Realistic color mapping from the GEE palettes

This allows the app to work immediately without backend API calls. The demo data mimics real Earth Engine patterns.

## Next Steps: Real GEE Integration

To connect to real Google Earth Engine data:

### Option 1: Use GEE JavaScript API (Recommended for Frontend)
1. Generate Map IDs from GEE Code Editor:
   ```javascript
   var image = ee.ImageCollection('LANDSAT/LC08/C02/T1_L2')
     .filterDate('2023-06-01', '2023-08-31')
     .filterBounds(roi)
     .map(function(img) {
       var ndvi = img.normalizedDifference(['SR_B5', 'SR_B4']);
       return ndvi;
     })
     .median();
   
   var mapId = ee.data.getMapId({image: image, min: -0.2, max: 0.8});
   ```
2. Use the `mapId` to generate tile URL
3. Replace the simulated overlay with real tiles

### Option 2: Use Backend Endpoint
1. Add an endpoint to your PHP backend that calls GEE Python API
2. Return tile URLs or processed image data
3. Call from Flutter to fetch actual data

## File Structure
```
se_project/
├── lib/
│   ├── data/
│   │   └── gee_service.dart          # GEE authentication and utilities
│   ├── presentation/
│   │   ├── screens/
│   │   │   ├── pixel_wise.dart       # Wrapper screen
│   │   │   ├── pixel_wise_page.dart  # Main page with filters
│   │   │   └── ...
│   │   └── components/
│   │       ├── pixel_wise_map_widget.dart  # Map component
│   │       └── ...
│   └── ...
├── assets/
│   └── ProtectedAreas.geojson        # Your area boundaries
└── pubspec.yaml
```

## Dependencies Used
- `flutter_map: ^8.2.2` - Map rendering
- `latlong2: ^0.9.1` - Coordinate handling
- `dio: ^5.9.0` - HTTP requests
- `fl_chart: ^1.1.1` - Chart visualization
- Built-in Flutter packages

## Troubleshooting

### Map not showing areas?
- Ensure `ProtectedAreas.geojson` is in `assets/`
- Check `pubspec.yaml` includes the asset

### Pixel overlay not appearing?
- Click "Generate Map" button after selecting filters
- Ensure an area is selected (or "All Areas")

### Colors not matching expectations?
- Check the legend on the left panel
- Different seasons have different base values (e.g., NDVI higher in summer)

## Future Enhancements
- [ ] Real GEE tile integration with REST API
- [ ] Time-series animation across multiple dates
- [ ] Export raster data as GeoTIFF
- [ ] Compare multiple metrics side-by-side
- [ ] Point-and-click to get exact pixel values
- [ ] Integration with prediction system for future values
