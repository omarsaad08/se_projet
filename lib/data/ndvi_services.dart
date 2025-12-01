import 'package:dio/dio.dart';
import 'dart:convert';

Dio dio = Dio();

class NdviServices {
  static const String _baseUrl = "https://49b1938e84a5.ngrok-free.app";

  static Future<List<dynamic>?> getAverageNdvi(
    int year,
    String season,
    int area_id, {
    String feature = 'ndvi',
  }) async {
    try {
      print("area_id: $area_id, season: $season, year: $year, feature: $feature");
      
      // Determine if this is a prediction or historical data
      String url;
      if (year >= 2025) {
        url = "$_baseUrl/api?predict=1&year=$year&season=${season.toLowerCase()}&metric=$feature";
      } else {
        url = "$_baseUrl/api?year=$year&season=${season.toLowerCase()}&feature=$feature";
      }
      
      print("Requesting: $url");

      var response = await dio.get(
        url,
        options: Options(
          responseType: ResponseType.json,
          headers: {"ngrok-skip-browser-warning": "true"},
        ),
      );
      print("Response: ${response.data}");
      print("Response type: ${response.data.runtimeType}");
      
      // Handle the response data
      var responseData = response.data;
      if (responseData is String) {
        responseData = jsonDecode(responseData) as Map<String, dynamic>;
      }
      
      // Handle prediction response format (map of area_id -> value)
      if (year >= 2025) {
        if (responseData is Map<String, dynamic> && responseData.containsKey('data')) {
          final predictionData = responseData['data'] as Map<String, dynamic>;
          // Convert to list format to match historical data structure
          List<dynamic> formattedList = [];
          predictionData.forEach((key, value) {
            formattedList.add({
              'area_id': int.parse(key),
              'year': year,
              'season': season,
              feature: value,
            });
          });
          return formattedList;
        }
      } 
      // Handle historical response format (list of objects)
      else if (responseData is Map<String, dynamic> && responseData.containsKey('data')) {
        return responseData['data'] as List<dynamic>?;
      }
      
      return null;
    } catch (e) {
      print("no data: $e");
      return null;
    }
  }
}
