import 'package:dio/dio.dart';
import '../models/car_model.dart';
import '../../core/api/api_client.dart';

class CarRepository {
  final ApiClient _client = ApiClient();

  Future<List<CarModel>> getDashboardLeads() async {
    try {
      // Calling your custom API endpoint
      final response = await _client.dio.get('/dashboard/leads');

      if (response.statusCode == 200) {
        // Map the List from JSON
        return (response.data['leads'] as List)
            .map((json) => CarModel.fromJson(json))
            .take(5) // Ensure we only take 5 for the dashboard
            .toList();
      }
      return [];
    } catch (e) {
      throw Exception("Failed to load leads: $e");
    }
  }
}
