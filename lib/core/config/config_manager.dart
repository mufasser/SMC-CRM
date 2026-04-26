import 'app_config.dart';

class ConfigManager {
  static late AppConfig _config;

  static void initialize(Environment env) {
    _config = env == Environment.dev ? AppConfig.dev() : AppConfig.prod();
  }

  static String get baseUrl => _config.baseUrl;
}
