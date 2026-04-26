import '../../core/api/api_client.dart';
import '../models/car_model.dart';

class LeadRepository {
  final ApiClient _apiClient = ApiClient();

  Future<List<CarModel>> fetchRecentLeads() async {
    try {
      final response = await _apiClient.dio.get('/leads/recent');
      if (response.statusCode == 200) {
        // We assume your API returns a list under a 'data' key
        List data = response.data['data'];
        return data.map((json) => CarModel.fromJson(json)).toList();
      }
      return [];
    } catch (e) {
      // Professional logging
      throw Exception("Failed to fetch leads: $e");
    }
  }
}
