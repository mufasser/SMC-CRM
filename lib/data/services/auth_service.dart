import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:smc_crm/core/config/api_endpoints.dart';
import 'package:smc_crm/core/config/config_manager.dart';
import 'package:smc_crm/core/notification_service.dart';

class AuthService {
  final _storage = const FlutterSecureStorage();
  final _notificationService = NotificationService();

  final Dio _dio = Dio(
    BaseOptions(
      baseUrl: ConfigManager.baseUrl,
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
      validateStatus: (status) => status! < 500,
    ),
  );

  Future<bool> login(String email, String password) async {
    try {
      // 1. Get the FCM Token from the device first
      String? fcmToken = await _notificationService.getDeviceToken();

      // 2. Prepare the payload exactly as the CRM expects
      final payload = {
        "email": email.trim(),
        "password": password.trim(),
        "deviceToken": fcmToken, // Restored functionality
        "platform": "android", // Identifying the OS
      };

      print("Attempting Login with Payload: $payload");

      final response = await _dio.post(ApiEndpoints.login, data: payload);

      if (response.statusCode == 200 && response.data['success'] == true) {
        // 3. Save the JWT Token
        String token = response.data['token'];
        await _storage.write(key: 'auth_token', value: token);

        print("Login Successful. Token Saved.");
        return true;
      } else {
        print("Login Failed (Status ${response.statusCode}): ${response.data}");
        return false;
      }
    } catch (e) {
      print("System Error during Login: $e");
      return false;
    }
  }

  // Helper to retrieve token for other API calls
  Future<String?> getToken() async => await _storage.read(key: 'auth_token');

  Future<void> logout() async => await _storage.delete(key: 'auth_token');
}
