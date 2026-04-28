import 'package:dio/dio.dart';
import 'package:smc_crm/core/config/config_manager.dart';

class LeadService {
  final Dio _dio = Dio(BaseOptions(baseUrl: ConfigManager.baseUrl));

  Future<List<dynamic>> getHomeData(String endpoint, String token) async {
    final response = await _dio.get(
      endpoint,
      queryParameters: {"page": 1, "limit": 10},
      options: Options(headers: {"Authorization": "Bearer $token"}),
    );
    return response.data['data'] ?? [];
  }
}
