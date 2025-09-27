import 'package:demo_appointment/models/location_models.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class LocationService {
  final String baseUrl =
      "http://20.20.20.37:8080/proyashospital/api/all_divisional";

  Future<List<Division>> fetchDivisions() async {
    final response = await http.get(Uri.parse(baseUrl));

    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body);
      return data.map((json) => Division.fromJson(json)).toList();
    } else {
      throw Exception("Failed to load divisions");
    }
  }
}
