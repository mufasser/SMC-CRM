enum Environment { dev, prod }

class AppConfig {
  final String baseUrl;
  final Environment environment;

  AppConfig({required this.baseUrl, required this.environment});

  // For Android Emulator to talk to your Next.js localhost
  factory AppConfig.dev() {
    return AppConfig(
      baseUrl: 'http://192.168.100.215:3000/api/mobile/v1',
      environment: Environment.dev,
    );
  }

  // Your actual live CRM
  factory AppConfig.prod() {
    return AppConfig(
      baseUrl: 'https://crm.sellmycartoday.uk/api/mobile/v1',
      environment: Environment.prod,
    );
  }
}
