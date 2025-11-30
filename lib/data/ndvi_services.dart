import 'package:dio/dio.dart';
import 'dart:convert';

Dio dio = Dio();

class NdviServices {
  // Update this to your actual ngrok URL
  static const String _baseUrl = "https://aa2335d91376.ngrok-free.app";

  static Future<List<dynamic>?> getAverageNdvi(
    int year,
    String season,
    int area_id,
  ) async {
    try {
      print("area_id: $area_id, season: $season, year: $year");
      final url =
          "$_baseUrl/api/ndvi?year=$year&season=${season.toLowerCase()}";
      print("Requesting: $url");

      var response = await dio.get(
        url,
        options: Options(
          headers: {
            "Content-Type": "application/json",
            "ngrok-skip-browser-warning": "true",
          },
          responseType: ResponseType.json,
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
