import 'package:dio/dio.dart';

Dio dio = Dio();

class NdviServices {
  static Future<List<dynamic>?> getAverageNdvi(
    int year,
    String season,
    int area_id,
  ) async {
    try {
      print("area_id: $area_id, season: $season, year: $year");
      var response = await dio.get(
        "http://localhost:8080/api/ndvi?year=$year&season=${season.toLowerCase()}",
      );
      print("data: ${response.data['data']}");
      return response.data['data'] as List<dynamic>?;
    } catch (e) {
      print("no data: $e");
      return null;
    }
  }
}
