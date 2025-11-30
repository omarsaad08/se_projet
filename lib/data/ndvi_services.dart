import 'package:dio/dio.dart';
import 'dart:convert';

Dio dio = Dio();

class NdviServices {
  // Update this to your actual ngrok URL
  static const String _baseUrl = "https://2ce6fd8eaffe.ngrok-free.app";

  static Future<List<dynamic>?> getAverageNdvi(
    int year,
    String season,
    int area_id, {
    String feature = 'ndvi',
  }) async {
    try {
      print("area_id: $area_id, season: $season, year: $year, feature: $feature");
      final url =
          "$_baseUrl/api?year=$year&season=${season.toLowerCase()}&feature=$feature";
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
      
      if (responseData is Map<String, dynamic> && responseData.containsKey('data')) {
        return responseData['data'] as List<dynamic>?;
      }
      
      return null;
    } catch (e) {
      print("no data: $e");
      return null;
    }
  }
}
