import 'package:flutter_test/flutter_test.dart';
import 'package:smc_crm/core/config/app_config.dart';
import 'package:smc_crm/core/config/config_manager.dart';
import 'package:smc_crm/main.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('SMC CRM shell renders bottom navigation', (
    WidgetTester tester,
  ) async {
    ConfigManager.initialize(Environment.prod);

    await tester.pumpWidget(const SMCCRMApp(initialRoute: '/home'));
    await tester.pump();

    expect(find.text('Home'), findsOneWidget);
    expect(find.text('Leads'), findsOneWidget);
    expect(find.text('Stock'), findsOneWidget);
    expect(find.text('Offers'), findsOneWidget);
    expect(find.text('Settings'), findsOneWidget);
  });
}
