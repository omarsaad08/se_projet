# GEE Server Setup

This is a simple Python server that computes NDVI/EVI/NDWI/Temperature using Google Earth Engine and returns tile URLs for display in the Flutter app.

## Prerequisites

1. **Python 3.8+** installed
2. **Earth Engine API** installed

## Installation

```bash
cd gee_server
pip install -r requirements.txt
```

## Running the Server

```bash
python server.py
```

The server will start on `http://localhost:5000`

## API Endpoints

### Health Check
```
GET /
```
Returns server status.

### Compute Metric
```
GET /compute?year=2023&season=all&metric=ndvi
```

Parameters:
- `year`: 2013-2024 (Landsat 8 data availability)
- `season`: all, winter, spring, summer, autumn
- `metric`: ndvi, evi, ndwi, temp

Returns:
```json
{
  "success": true,
  "tileUrl": "https://earthengine.googleapis.com/...",
  "metric": "ndvi",
  "year": 2023,
  "season": "all"
}
```

## Usage with Flutter

1. Start the Python server: `python gee_server/server.py`
2. Run the Flutter app: `flutter run -d chrome`
3. Go to the Pixel-Wise page and click "Generate Map"

## Troubleshooting

### "Earth Engine not initialized"
- Make sure your service account has Earth Engine access
- Check that the private key is correct in `server.py`

### "Permission denied"
- Go to Google Cloud Console
- Enable the Earth Engine API
- Grant "Earth Engine Resource Writer" role to your service account
- Register your project at https://code.earthengine.google.com/register

### Connection refused
- Make sure the Python server is running
- Check that port 5000 is not blocked
