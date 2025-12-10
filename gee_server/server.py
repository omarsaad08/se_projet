"""
Simple Google Earth Engine Server for NDVI/EVI/NDWI computation
Run with: python server.py
Listens on: http://localhost:5000
"""

import ee
import json
import os
from http.server import HTTPServer, BaseHTTPRequestHandler
from urllib.parse import urlparse, parse_qs
import ssl

# ============== CONFIGURATION ==============
PORT = 5000
SERVICE_ACCOUNT = 'earthengine-service@drhaithamproject.iam.gserviceaccount.com'

# Path to the protected areas GeoJSON file
GEOJSON_PATH = os.path.join(os.path.dirname(__file__), '..', 'assets', 'ProtectedAreas.geojson')
PRIVATE_KEY = '''-----BEGIN PRIVATE KEY-----
MIIEvgIBADANBgkqhkiG9w0BAQEFAASCBKgwggSkAgEAAoIBAQChlp3JsPgNxS84
atsewr3W+T7myDGqf/JNL10wfbkFMDzMKY9m5KRxcUYxMrqR3Ax92XRx5MIkOpyP
V75mFfyWK4/wg+KLN79qpiehJ75OFrsX3s27qtA5JWgVc3tzDcF7jRzl/hnMWXlA
g3BFlkqq4Yl3b44C6dhVvxpnp6T0qx7qV3GWoAV2IlTAcnJfa5X+fvx6TPmZTfQ8
QpObjVuvy0UZJBPoLEZq9uImIRoIrmXWueWD/vFMlppZoeIex+oFkL23KfJ56eVr
1EZcd7IkRhaNX2BLzCW1kKrtxCXIVY4jSwVRr3wtjCm78/PwgSpBBx81/k932RDI
HKFDDvYTAgMBAAECggEABH3m2NQ+nZCFdHGsjTu1na9tCNiTqW91ynwy7lOmExd9
ruE1KaXYvKyPNeGdesuCE/U5mTkxoT4LkoTKZYLL9DK1qdQkI6q51tGc4fniEOTt
S36A1yMFycRP7nS42yT6Y7KhS/MgGy2d1VOfwCCZL8MBYZyjCVKyXyz5I27vObvg
Y09IvPznzh5u//L5BGy/BtYidjBJByVqNKI9GlH5jV6lQnN7ZveIV2rfbnypiuit
9Iaarv8RMq2jYsBz58YicBNbsAxFFR4rvakx7PXN8OEBqVmPNeVqSfBLVIR/sMyQ
Dj9F8yuVBhSGBcxxR9mZjWjE/UIbjQk24l/oqxACPQKBgQDdQtd3tiZslapb2jlI
mVVznUw+HQrVLptzkd9B2Ke7R0mboiFr6Cs/XfhjZm3vBC5/U6b1iUqHFqP77e7g
uLD8HsPfSFv38xeyE6rRNYeD5dKwUjYVoHDfKnB7gNMAVTjOe1BUVbQM/KxkbAqi
wfwpu7tDCNVGrW82HYPYxClNDwKBgQC69Vg97mqmkwH84WjGSfgPOh7gzo3iDNOy
UCF98nFK8V3e/W915rgk1povGlfVwE4x7FDyvtj2m3zK6USQSYxOI6eX/AtwPTuH
/fdZfNrV1IZqC50pyJZhBa3LChQ8w7S2gkNkv9MOrheX8E0tNQ9/6YNeyYboz9i0
6fDaoIHOvQKBgQDIIv3jOs/myDoge3P1Rz0UJuQgCwURb+cM0pWvadnOfN0H+c9h
W9BCsS1MPAqUeKPWaERNNLJFHyWVa9L3UhhE9U8XWMxXq3tziHaqZlD97ZR2COcD
CO0P78Nu80fotS19F+3BWwRR+vu0mkXEktMUrMrmB8di9t3xhSENoeH54QKBgQCA
i9LpejWAZNHYExBcTl2t8pNqlPr/MzyXfPsaQwlcswqNGQp7MXDpe1i2DFHaWYgq
UUbzMP+yyAQM7EjFQJyk2WURXi5rNN7qyVc6A1vf7GmjHmsoYI/tE9+EHGD/yrxF
RNmbuz0d+dulD4exDquikmdOVBhbmRVyhuuhFv1JrQKBgAwgt5Mkw6Hbl0VLFkbr
uLfeJOuf9dO/q0UgSoRp0hx977U2o/Q/AMEgMz/MH7D6xjLyGAffN/O0DcmonyoH
bU/h87iK2BDFkuFu0K8/EshDH84ifAFnWCmW39ne5BH2+ApXevjSpvWKVFvndPPQ
OXnekbnUUAR7xhpyttxt/2j+
-----END PRIVATE KEY-----'''

# ============== INITIALIZE EARTH ENGINE ==============
def initialize_ee():
    """Initialize Earth Engine with service account credentials"""
    try:
        credentials = ee.ServiceAccountCredentials(SERVICE_ACCOUNT, key_data=PRIVATE_KEY)
        ee.Initialize(credentials)
        print("✓ Earth Engine initialized successfully!")
        return True
    except Exception as e:
        print(f"✗ Error initializing Earth Engine: {e}")
        return False

# ============== PROTECTED AREAS GEOMETRY ==============
# Global variable to cache the protected areas geometry
_protected_areas_geometry = None

def utm_to_wgs84(easting, northing, zone=35, northern=True):
    """Convert UTM coordinates to WGS84 (lat/lng)"""
    import math
    
    # WGS84 ellipsoid parameters
    a = 6378137.0  # Semi-major axis
    f = 1 / 298.257223563  # Flattening
    k0 = 0.9996  # Scale factor
    
    e = math.sqrt(2 * f - f * f)  # Eccentricity
    e2 = e * e
    e1 = (1 - math.sqrt(1 - e2)) / (1 + math.sqrt(1 - e2))
    
    # Remove false easting and northing
    x = easting - 500000.0
    y = northing
    if not northern:
        y = y - 10000000.0
    
    # Central meridian
    lon_origin = (zone - 1) * 6 - 180 + 3
    
    M = y / k0
    mu = M / (a * (1 - e2 / 4 - 3 * e2 * e2 / 64 - 5 * e2 * e2 * e2 / 256))
    
    phi1 = mu + (3 * e1 / 2 - 27 * e1**3 / 32) * math.sin(2 * mu) + \
           (21 * e1**2 / 16 - 55 * e1**4 / 32) * math.sin(4 * mu) + \
           (151 * e1**3 / 96) * math.sin(6 * mu)
    
    sin_phi1 = math.sin(phi1)
    cos_phi1 = math.cos(phi1)
    tan_phi1 = math.tan(phi1)
    
    N1 = a / math.sqrt(1 - e2 * sin_phi1 * sin_phi1)
    T1 = tan_phi1 * tan_phi1
    C1 = e2 / (1 - e2) * cos_phi1 * cos_phi1
    R1 = a * (1 - e2) / math.pow(1 - e2 * sin_phi1 * sin_phi1, 1.5)
    D = x / (N1 * k0)
    
    lat = phi1 - (N1 * tan_phi1 / R1) * \
          (D * D / 2 - (5 + 3 * T1 + 10 * C1 - 4 * C1 * C1 - 9 * e2 / (1 - e2)) * D**4 / 24 +
           (61 + 90 * T1 + 298 * C1 + 45 * T1 * T1 - 252 * e2 / (1 - e2) - 3 * C1 * C1) * D**6 / 720)
    
    lon = (D - (1 + 2 * T1 + C1) * D**3 / 6 +
           (5 - 2 * C1 + 28 * T1 - 3 * C1 * C1 + 8 * e2 / (1 - e2) + 24 * T1 * T1) * D**5 / 120) / cos_phi1
    
    lat_deg = lat * 180 / math.pi
    lon_deg = lon_origin + lon * 180 / math.pi
    
    return lon_deg, lat_deg  # Return as [lng, lat] for GeoJSON format

def convert_coordinates(coords, is_utm=True):
    """Convert a list of coordinates from UTM to WGS84 if needed"""
    if not is_utm:
        return coords
    
    converted = []
    for coord in coords:
        lng, lat = coord[0], coord[1]
        # Check if coordinates are in UTM format (large numbers)
        if abs(lng) > 180 or abs(lat) > 90:
            lng, lat = utm_to_wgs84(lng, lat, zone=35, northern=True)
        converted.append([lng, lat])
    return converted

def load_protected_areas_geometry():
    """Load the protected areas GeoJSON and convert to Earth Engine geometry"""
    global _protected_areas_geometry
    
    if _protected_areas_geometry is not None:
        return _protected_areas_geometry
    
    try:
        # Load GeoJSON file
        geojson_path = os.path.abspath(GEOJSON_PATH)
        print(f"Loading protected areas from: {geojson_path}")
        
        with open(geojson_path, 'r', encoding='utf-8') as f:
            geojson_data = json.load(f)
        
        # Check if coordinates are in UTM (EPSG:32635)
        crs = geojson_data.get('crs', {}).get('properties', {}).get('name', '')
        is_utm = '32635' in crs
        print(f"CRS: {crs}, Is UTM: {is_utm}")
        
        # Collect all polygons
        all_polygons = []
        
        for feature in geojson_data.get('features', []):
            geometry = feature.get('geometry', {})
            geom_type = geometry.get('type', '')
            coordinates = geometry.get('coordinates', [])
            
            if geom_type == 'Polygon':
                # Convert coordinates if needed
                converted_rings = []
                for ring in coordinates:
                    converted_ring = convert_coordinates(ring, is_utm)
                    converted_rings.append(converted_ring)
                all_polygons.append(converted_rings)
                
            elif geom_type == 'MultiPolygon':
                for polygon in coordinates:
                    converted_rings = []
                    for ring in polygon:
                        converted_ring = convert_coordinates(ring, is_utm)
                        converted_rings.append(converted_ring)
                    all_polygons.append(converted_rings)
        
        print(f"Loaded {len(all_polygons)} polygons from protected areas")
        
        # Create Earth Engine MultiPolygon geometry
        ee_polygons = []
        for polygon_coords in all_polygons:
            try:
                ee_polygon = ee.Geometry.Polygon(polygon_coords)
                ee_polygons.append(ee_polygon)
            except Exception as e:
                print(f"Warning: Could not create polygon: {e}")
                continue
        
        # Combine all polygons into a single geometry
        if len(ee_polygons) > 0:
            _protected_areas_geometry = ee.Geometry.MultiPolygon([p.coordinates() for p in ee_polygons])
            print(f"✓ Created Earth Engine geometry with {len(ee_polygons)} polygons")
        else:
            print("✗ No valid polygons found")
            return None
        
        return _protected_areas_geometry
        
    except Exception as e:
        print(f"✗ Error loading protected areas: {e}")
        import traceback
        traceback.print_exc()
        return None

# ============== NDVI COMPUTATION ==============
def get_visualization_params(metric):
    """Get visualization parameters for different metrics"""
    params = {
        'ndvi': {
            # NDVI: -1 to 1, but typically -0.2 to 0.8 for land
            # Brown (bare/dead) -> Yellow (sparse) -> Green (healthy vegetation)
            'min': -0.2,
            'max': 0.8,
            'palette': [
                '8B4513',  # Saddle brown - bare soil/rock
                'A0522D',  # Sienna - very sparse
                'CD853F',  # Peru - sparse vegetation
                'DAA520',  # Goldenrod - light vegetation
                'F0E68C',  # Khaki - transitional
                'ADFF2F',  # Green yellow - moderate vegetation
                '32CD32',  # Lime green - healthy vegetation  
                '228B22',  # Forest green - dense vegetation
                '006400',  # Dark green - very dense vegetation
                '004D00'   # Darkest green - maximum vegetation
            ]
        },
        'evi': {
            # EVI: Enhanced Vegetation Index, similar range to NDVI but less saturated
            'min': -0.2,
            'max': 0.8,
            'palette': [
                '8B4513',  # Brown - bare
                'A0522D',  # Sienna
                'CD853F',  # Peru
                'DAA520',  # Goldenrod
                'F0E68C',  # Khaki
                '9ACD32',  # Yellow green
                '32CD32',  # Lime green
                '228B22',  # Forest green
                '006400',  # Dark green
                '004D00'   # Darkest green
            ]
        },
        'ndwi': {
            # NDWI: Water Index - negative = dry/vegetation, positive = water
            # Brown (very dry) -> Tan -> White (transition) -> Light blue -> Dark blue (water)
            'min': -0.4,
            'max': 0.4,
            'palette': [
                'AA6600',  # Brown - very dry/bare soil
                'CC8833',  # Tan brown - dry
                'DDAA66',  # Light tan - somewhat dry
                'EECCAA',  # Pale tan - dry vegetation
                'F5F5DC',  # Beige - transition (near 0)
                'BBDDEE',  # Very light blue - moist/shallow water
                '66B3FF',  # Light blue - water presence
                '3399FF',  # Medium blue - clear water
                '0066CC',  # Blue - deeper water
                '003D99'   # Dark blue - deep water bodies
            ]
        },
        'savi': {
            # SAVI: Soil-Adjusted Vegetation Index
            # Similar to NDVI but reduces soil background effects
            'min': -0.2,
            'max': 0.8,
            'palette': [
                '8B4513',  # Brown - bare soil
                'A0522D',  # Sienna
                'CD853F',  # Peru
                'DAA520',  # Goldenrod
                'F0E68C',  # Khaki
                'ADFF2F',  # Green yellow
                '32CD32',  # Lime green
                '228B22',  # Forest green
                '006400',  # Dark green
                '004D00'   # Darkest green
            ]
        },
        'ndmi': {
            # NDMI: Normalized Difference Moisture Index
            # Measures vegetation water content
            'min': -0.5,
            'max': 0.6,
            'palette': [
                '8B4513',  # Brown - very dry/stressed
                'A0522D',  # Sienna - dry
                'CD853F',  # Peru - somewhat dry
                'DAA520',  # Goldenrod - low moisture
                'F0E68C',  # Khaki - moderate
                'ADFF2F',  # Green yellow - good moisture
                '32CD32',  # Lime green - moist
                '228B22',  # Forest green - high moisture
                '006400',  # Dark green - very moist
                '004D00'   # Darkest green - saturated
            ]
        },
        'ndbi': {
            # NDBI: Normalized Difference Built-up Index
            # Highlights urban/built-up areas
            'min': -0.4,
            'max': 0.4,
            'palette': [
                '006400',  # Dark green - dense vegetation
                '228B22',  # Forest green
                '32CD32',  # Lime green
                '90EE90',  # Light green
                'D3D3D3',  # Light gray - transition
                'A9A9A9',  # Gray - sparse built-up
                'FF9966',  # Light orange - built-up
                'FF6633',  # Orange - urban
                'CC3300',  # Red orange - dense urban
                '8B0000'   # Dark red - very dense built-up
            ]
        },
        'temp': {
            # Temperature in Kelvin from Landsat (typically 270-320K = -3°C to 47°C)
            # Blue (cold) -> Cyan -> Green -> Yellow -> Orange -> Red (hot)
            'min': 280,
            'max': 320,
            'palette': [
                '313695',  # Dark blue - very cold
                '4575B4',  # Blue - cold
                '74ADD1',  # Light blue - cool
                'ABD9E9',  # Pale blue - mild cool
                'E0F3F8',  # Very pale blue - cool neutral
                'FFFFBF',  # Pale yellow - warm neutral
                'FEE090',  # Light orange - warm
                'FDAE61',  # Orange - hot
                'F46D43',  # Red orange - very hot
                'D73027',  # Red - extremely hot
                'A50026'   # Dark red - maximum heat
            ]
        }
    }
    return params.get(metric, params['ndvi'])

def get_date_range(year, season):
    """Get date range for season"""
    if season == 'winter':
        return f'{year-1}-12-01', f'{year}-02-28'
    elif season == 'spring':
        return f'{year}-03-01', f'{year}-05-31'
    elif season == 'summer':
        return f'{year}-06-01', f'{year}-08-31'
    elif season == 'autumn':
        return f'{year}-09-01', f'{year}-11-30'
    else:  # all
        return f'{year}-01-01', f'{year}-12-31'

def compute_metric(year, season, metric):
    """Compute vegetation index and return tile URL"""
    try:
        start_date, end_date = get_date_range(year, season)
        vis_params = get_visualization_params(metric)
        
        print(f"Computing {metric} for {year} ({season})...")
        print(f"Date range: {start_date} to {end_date}")
        
        # Load protected areas geometry for clipping
        protected_areas = load_protected_areas_geometry()
        if protected_areas is None:
            print("Warning: Could not load protected areas, showing full extent")
        
        # Load Landsat 8 Collection 2 Level 2
        collection = ee.ImageCollection('LANDSAT/LC08/C02/T1_L2') \
            .filterDate(start_date, end_date)
        
        # Filter by bounds if we have protected areas
        if protected_areas is not None:
            collection = collection.filterBounds(protected_areas)
        
        if metric == 'temp':
            # Surface temperature
            def compute_temp(img):
                thermal = img.select('ST_B10').multiply(0.00341802).add(149.0)
                return thermal.rename('temp')
            
            image = collection.map(compute_temp).median()
        else:
            # Vegetation indices
            def compute_index(img):
                # Scale factors for Collection 2
                nir = img.select('SR_B5').multiply(0.0000275).add(-0.2)
                red = img.select('SR_B4').multiply(0.0000275).add(-0.2)
                green = img.select('SR_B3').multiply(0.0000275).add(-0.2)
                blue = img.select('SR_B2').multiply(0.0000275).add(-0.2)
                swir1 = img.select('SR_B6').multiply(0.0000275).add(-0.2)  # SWIR1 band for NDMI/NDBI
                
                if metric == 'ndvi':
                    # NDVI = (NIR - Red) / (NIR + Red)
                    index = nir.subtract(red).divide(nir.add(red)).rename('ndvi')
                elif metric == 'evi':
                    # EVI = 2.5 * (NIR - Red) / (NIR + 6*Red - 7.5*Blue + 1)
                    index = nir.subtract(red).divide(
                        nir.add(red.multiply(6)).subtract(blue.multiply(7.5)).add(1)
                    ).multiply(2.5).rename('evi')
                elif metric == 'ndwi':
                    # NDWI = (Green - NIR) / (Green + NIR)
                    index = green.subtract(nir).divide(green.add(nir)).rename('ndwi')
                elif metric == 'savi':
                    # SAVI = ((NIR - Red) / (NIR + Red + L)) * (1 + L), where L = 0.5
                    L = 0.5
                    index = nir.subtract(red).divide(nir.add(red).add(L)).multiply(1 + L).rename('savi')
                elif metric == 'ndmi':
                    # NDMI = (NIR - SWIR1) / (NIR + SWIR1)
                    index = nir.subtract(swir1).divide(nir.add(swir1)).rename('ndmi')
                elif metric == 'ndbi':
                    # NDBI = (SWIR1 - NIR) / (SWIR1 + NIR)
                    index = swir1.subtract(nir).divide(swir1.add(nir)).rename('ndbi')
                else:
                    index = nir.subtract(red).divide(nir.add(red)).rename('ndvi')
                
                return index
            
            image = collection.map(compute_index).median()
        
        # Clip to protected areas boundaries
        if protected_areas is not None:
            image = image.clip(protected_areas)
            print("✓ Image clipped to protected areas boundaries")
        
        # Get map ID for tile URL
        map_id = image.getMapId(vis_params)
        tile_url = map_id['tile_fetcher'].url_format
        
        print(f"✓ Tile URL generated successfully!")
        return {
            'success': True,
            'tileUrl': tile_url,
            'metric': metric,
            'year': year,
            'season': season
        }
        
    except Exception as e:
        print(f"✗ Error computing {metric}: {e}")
        return {
            'success': False,
            'error': str(e)
        }

def get_point_info(lat, lng, year, season):
    """Get detailed pixel information at a specific location"""
    try:
        start_date, end_date = get_date_range(year, season)
        
        print(f"Getting point info at ({lat}, {lng}) for {year} ({season})...")
        
        # Create point geometry
        point = ee.Geometry.Point([lng, lat])
        
        # Load protected areas to check if point is within
        protected_areas = load_protected_areas_geometry()
        
        # Check if point is within protected areas
        is_within_protected = False
        if protected_areas is not None:
            is_within_protected = protected_areas.contains(point).getInfo()
        
        if not is_within_protected:
            return {
                'success': False,
                'error': 'Point is outside protected areas',
                'isWithinProtected': False
            }
        
        # Load Landsat 8 Collection 2 Level 2
        collection = ee.ImageCollection('LANDSAT/LC08/C02/T1_L2') \
            .filterDate(start_date, end_date) \
            .filterBounds(point)
        
        # Get collection size
        collection_size = collection.size().getInfo()
        
        if collection_size == 0:
            return {
                'success': False,
                'error': 'No imagery available for this location and time period',
                'isWithinProtected': True
            }
        
        # Compute all metrics on the median composite
        def compute_all_indices(img):
            # Scale factors for Collection 2
            nir = img.select('SR_B5').multiply(0.0000275).add(-0.2)
            red = img.select('SR_B4').multiply(0.0000275).add(-0.2)
            green = img.select('SR_B3').multiply(0.0000275).add(-0.2)
            blue = img.select('SR_B2').multiply(0.0000275).add(-0.2)
            swir1 = img.select('SR_B6').multiply(0.0000275).add(-0.2)
            
            # Temperature
            temp_kelvin = img.select('ST_B10').multiply(0.00341802).add(149.0)
            temp_celsius = temp_kelvin.subtract(273.15)
            
            # NDVI
            ndvi = nir.subtract(red).divide(nir.add(red)).rename('ndvi')
            
            # EVI
            evi = nir.subtract(red).divide(
                nir.add(red.multiply(6)).subtract(blue.multiply(7.5)).add(1)
            ).multiply(2.5).rename('evi')
            
            # NDWI
            ndwi = green.subtract(nir).divide(green.add(nir)).rename('ndwi')
            
            # SAVI (L = 0.5)
            L = 0.5
            savi = nir.subtract(red).divide(nir.add(red).add(L)).multiply(1 + L).rename('savi')
            
            # NDMI
            ndmi = nir.subtract(swir1).divide(nir.add(swir1)).rename('ndmi')
            
            # NDBI
            ndbi = swir1.subtract(nir).divide(swir1.add(nir)).rename('ndbi')
            
            return img.addBands([ndvi, evi, ndwi, savi, ndmi, ndbi, temp_celsius.rename('temp')])
        
        # Apply to collection and get median
        processed = collection.map(compute_all_indices)
        median_image = processed.median()
        
        # Sample at the point location (30m scale for Landsat)
        sample = median_image.sample(
            region=point,
            scale=30,
            numPixels=1
        ).first()
        
        if sample is None:
            return {
                'success': False,
                'error': 'Could not sample data at this location',
                'isWithinProtected': True
            }
        
        # Get values
        values = sample.getInfo()
        
        if values is None or 'properties' not in values:
            return {
                'success': False,
                'error': 'No data available at this location',
                'isWithinProtected': True
            }
        
        props = values['properties']
        
        # Get land cover interpretation
        ndvi_val = props.get('ndvi')
        land_cover = interpret_land_cover(props)
        vegetation_health = interpret_vegetation_health(ndvi_val) if ndvi_val else 'Unknown'
        moisture_status = interpret_moisture(props.get('ndmi')) if props.get('ndmi') else 'Unknown'
        
        return {
            'success': True,
            'isWithinProtected': True,
            'coordinates': {
                'lat': lat,
                'lng': lng
            },
            'metrics': {
                'ndvi': round(props.get('ndvi', 0), 4) if props.get('ndvi') else None,
                'evi': round(props.get('evi', 0), 4) if props.get('evi') else None,
                'ndwi': round(props.get('ndwi', 0), 4) if props.get('ndwi') else None,
                'savi': round(props.get('savi', 0), 4) if props.get('savi') else None,
                'ndmi': round(props.get('ndmi', 0), 4) if props.get('ndmi') else None,
                'ndbi': round(props.get('ndbi', 0), 4) if props.get('ndbi') else None,
                'temp': round(props.get('temp', 0), 1) if props.get('temp') else None,
            },
            'interpretation': {
                'landCover': land_cover,
                'vegetationHealth': vegetation_health,
                'moistureStatus': moisture_status
            },
            'metadata': {
                'year': year,
                'season': season,
                'imageCount': collection_size,
                'resolution': '30m (Landsat 8)'
            }
        }
        
    except Exception as e:
        print(f"✗ Error getting point info: {e}")
        import traceback
        traceback.print_exc()
        return {
            'success': False,
            'error': str(e)
        }

def interpret_land_cover(props):
    """Interpret land cover based on index values"""
    ndvi = props.get('ndvi', 0)
    ndwi = props.get('ndwi', 0)
    ndbi = props.get('ndbi', 0)
    
    if ndwi > 0.2:
        return 'Water Body'
    elif ndbi > 0.1:
        return 'Built-up / Urban'
    elif ndvi > 0.6:
        return 'Dense Vegetation / Forest'
    elif ndvi > 0.4:
        return 'Moderate Vegetation / Cropland'
    elif ndvi > 0.2:
        return 'Sparse Vegetation / Grassland'
    elif ndvi > 0:
        return 'Bare Soil / Desert'
    else:
        return 'Barren / Rock / Sand'

def interpret_vegetation_health(ndvi):
    """Interpret vegetation health from NDVI"""
    if ndvi is None:
        return 'Unknown'
    elif ndvi > 0.6:
        return 'Excellent - Very healthy vegetation'
    elif ndvi > 0.4:
        return 'Good - Healthy vegetation'
    elif ndvi > 0.2:
        return 'Fair - Moderate vegetation stress'
    elif ndvi > 0:
        return 'Poor - Significant vegetation stress'
    else:
        return 'No vegetation detected'

def interpret_moisture(ndmi):
    """Interpret moisture status from NDMI"""
    if ndmi is None:
        return 'Unknown'
    elif ndmi > 0.4:
        return 'Very High - Saturated / Waterlogged'
    elif ndmi > 0.2:
        return 'High - Well-watered'
    elif ndmi > 0:
        return 'Moderate - Adequate moisture'
    elif ndmi > -0.2:
        return 'Low - Moisture stress'
    else:
        return 'Very Low - Severe drought stress'

# ============== HTTP SERVER ==============
class GEEHandler(BaseHTTPRequestHandler):
    def _set_headers(self, status=200):
        self.send_response(status)
        self.send_header('Content-type', 'application/json')
        self.send_header('Access-Control-Allow-Origin', '*')
        self.send_header('Access-Control-Allow-Methods', 'GET, OPTIONS')
        self.send_header('Access-Control-Allow-Headers', 'Content-Type')
        self.end_headers()
    
    def do_OPTIONS(self):
        self._set_headers()
    
    def do_GET(self):
        parsed = urlparse(self.path)
        
        if parsed.path == '/':
            # Health check
            self._set_headers()
            response = {'status': 'ok', 'message': 'GEE Server is running'}
            self.wfile.write(json.dumps(response).encode())
            
        elif parsed.path == '/compute':
            # Parse query parameters
            params = parse_qs(parsed.query)
            year = int(params.get('year', [2023])[0])
            season = params.get('season', ['all'])[0]
            metric = params.get('metric', ['ndvi'])[0]
            
            # Compute the metric
            result = compute_metric(year, season, metric)
            
            if result['success']:
                self._set_headers(200)
            else:
                self._set_headers(500)
            
            self.wfile.write(json.dumps(result).encode())
        
        elif parsed.path == '/point-info':
            # Get pixel information at a specific point
            params = parse_qs(parsed.query)
            lat = float(params.get('lat', [0])[0])
            lng = float(params.get('lng', [0])[0])
            year = int(params.get('year', [2023])[0])
            season = params.get('season', ['all'])[0]
            
            result = get_point_info(lat, lng, year, season)
            
            if result['success']:
                self._set_headers(200)
            else:
                self._set_headers(400 if 'outside' in result.get('error', '').lower() else 500)
            
            self.wfile.write(json.dumps(result).encode())
            
        else:
            self._set_headers(404)
            response = {'error': 'Not found'}
            self.wfile.write(json.dumps(response).encode())

def run_server():
    """Start the HTTP server"""
    if not initialize_ee():
        print("Failed to initialize Earth Engine. Exiting.")
        return
    
    server_address = ('', PORT)
    httpd = HTTPServer(server_address, GEEHandler)
    
    print(f"\n{'='*50}")
    print(f"  GEE Server running on http://localhost:{PORT}")
    print(f"{'='*50}")
    print(f"\nEndpoints:")
    print(f"  GET /            - Health check")
    print(f"  GET /compute     - Compute metric")
    print(f"    ?year=2023     - Year (2013-2024)")
    print(f"    &season=all    - Season (all/winter/spring/summer/autumn)")
    print(f"    &metric=ndvi   - Metric (ndvi/evi/ndwi/savi/ndmi/ndbi/temp)")
    print(f"  GET /point-info  - Get pixel information at a point")
    print(f"    ?lat=26.8      - Latitude")
    print(f"    &lng=30.8      - Longitude")
    print(f"    &year=2023     - Year")
    print(f"    &season=all    - Season")
    print(f"\nExamples:")
    print(f"  http://localhost:{PORT}/compute?year=2023&season=all&metric=ndvi")
    print(f"  http://localhost:{PORT}/point-info?lat=26.8&lng=30.8&year=2023&season=all")
    print(f"\nPress Ctrl+C to stop the server.\n")
    
    try:
        httpd.serve_forever()
    except KeyboardInterrupt:
        print("\nServer stopped.")
        httpd.shutdown()

if __name__ == '__main__':
    run_server()
