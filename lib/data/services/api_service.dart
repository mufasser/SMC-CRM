import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/car_model.dart';

class ApiService {
  final String baseUrl = "https://your-api-domain.com/api";

  // GET ALL CARS (Stock & Leads)
  Future<List<CarModel>> fetchCars() async {
    final response = await http.get(Uri.parse('$baseUrl/vehicles'));

    if (response.statusCode == 200) {
      List jsonResponse = json.decode(response.body);
      return jsonResponse.map((data) => CarModel.fromJson(data)).toList();
    } else {
      throw Exception('Failed to load inventory');
    }
  }

  // UPDATE STATUS (e.g., Moving Lead to Stock)
  Future<bool> updateVehicleStatus(String id, CarStatus status) async {
    final response = await http.put(
      Uri.parse('$baseUrl/vehicles/$id'),
      body: jsonEncode({'status': status.name}),
      headers: {'Content-Type': 'application/json'},
    );
    return response.statusCode == 200;
  }
}
