import 'dart:io';
import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../core/config/config_manager.dart';
import '../../core/config/api_endpoints.dart';
import '../../core/notification_service.dart';

class AuthService {
  final _storage = const FlutterSecureStorage();
  final _dio = Dio(
    BaseOptions(
      baseUrl: ConfigManager.baseUrl,
      headers: {'Content-Type': 'application/json'},
      validateStatus: (status) => status! < 500,
    ),
  );

  Future<bool> login(String email, String password) async {
    try {
      // 1. Collect Device & App Info
      DeviceInfoPlugin deviceInfo = DeviceInfoPlugin();
      PackageInfo packageInfo = await PackageInfo.fromPlatform();
      NotificationService notifService = NotificationService();

      String model = "Unknown";
      if (Platform.isAndroid) {
        AndroidDeviceInfo androidInfo = await deviceInfo.androidInfo;
        model = androidInfo.model;
      } else if (Platform.isIOS) {
        IosDeviceInfo iosInfo = await deviceInfo.iosInfo;
        model = iosInfo.utsname.machine;
      }

      String? fcmToken = await notifService.getDeviceToken();

      // 2. Construct Payload
      final payload = {
        "email": email.trim(),
        "password": password.trim(),
        "deviceToken": fcmToken ?? "no-token",
        "platform": Platform.isAndroid ? "android" : "ios",
        "deviceModel": model,
        "appVersion": packageInfo.version,
      };

      final response = await _dio.post(ApiEndpoints.login, data: payload);

      if (response.statusCode == 200 && response.data['success'] == true) {
        // Save JWT
        await _storage.write(key: 'auth_token', value: response.data['token']);
        // Save basic user/session info for the dashboard and settings UI
        await _storage.write(
          key: 'user_name',
          value: response.data['user']['name'],
        );
        await _storage.write(
          key: 'user_email',
          value: response.data['user']['email'],
        );
        await _storage.write(
          key: 'user_role',
          value: response.data['user']['role'],
        );
        await _storage.write(
          key: 'tenant_name',
          value: response.data['user']['tenant']['name'],
        );
        await _storage.write(
          key: 'tenant_slug',
          value: response.data['user']['tenant']['slug'],
        );
        await _storage.write(
          key: 'dashboard_stats',
          value: jsonEncode(response.data['stats'] ?? const {}),
        );
        return true;
      }
      return false;
    } catch (e) {
      debugPrint("Login Integration Error: $e");
      return false;
    }
  }

  Future<String?> getToken() async => await _storage.read(key: 'auth_token');

  Future<Map<String, dynamic>> getDashboardStats() async {
    final raw = await _storage.read(key: 'dashboard_stats');
    if (raw == null || raw.isEmpty) {
      return {};
    }

    try {
      final decoded = jsonDecode(raw);
      if (decoded is Map<String, dynamic>) {
        return decoded;
      }
      return {};
    } catch (e) {
      debugPrint("Dashboard stats decode error: $e");
      return {};
    }
  }

  Future<void> saveDashboardStats(Map<String, dynamic> stats) async {
    await _storage.write(key: 'dashboard_stats', value: jsonEncode(stats));
  }

  Future<String?> getUserName() async => await _storage.read(key: 'user_name');

  Future<String?> getTenantName() async => await _storage.read(key: 'tenant_name');

  Future<void> logout() async {
    await _storage.delete(key: 'auth_token');
    await _storage.delete(key: 'user_name');
    await _storage.delete(key: 'user_email');
    await _storage.delete(key: 'user_role');
    await _storage.delete(key: 'tenant_name');
    await _storage.delete(key: 'tenant_slug');
    await _storage.delete(key: 'dashboard_stats');
  }
}
