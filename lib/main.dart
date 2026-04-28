import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:smc_crm/core/config/app_config.dart';
import 'package:smc_crm/core/config/config_manager.dart';
import 'package:smc_crm/core/notification_service.dart';
import 'package:smc_crm/data/services/auth_service.dart';
import 'package:smc_crm/ui/screens/auth/forgot_password_screen.dart';
import 'package:smc_crm/ui/screens/auth/login_screen.dart';
import 'ui/screens/main_navigation.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Set this to Environment.dev for local testing with your Next.js server
  ConfigManager.initialize(Environment.prod);

  await Firebase.initializeApp();

  // Initialize Auth and check for existing token
  final authService = AuthService();
  final notificationService = NotificationService();

  // Initialize notifications
  await notificationService.initNotification();

  // Check if a user is already logged in
  String? token = await authService.getToken();

  runApp(SMCCRMApp(initialRoute: token == null ? '/login' : '/home'));
}

class SMCCRMApp extends StatelessWidget {
  final String initialRoute;

  const SMCCRMApp({super.key, this.initialRoute = '/home'});

  @override
  Widget build(BuildContext context) {
    // Define your custom yellow color
    const Color brandYellow = Color(0xFFFACC14);
    const Color brandBlack = Color(0xFF000000);

    return MaterialApp(
      title: 'SMC CRM',
      debugShowCheckedModeBanner: false,
      initialRoute: initialRoute,
      theme: ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: Colors.white,

        // 1. Color Scheme Definition
        colorScheme: ColorScheme.fromSeed(
          seedColor: brandYellow,
          primary: brandYellow,
          onPrimary: brandBlack, // Text on yellow should be black
          secondary: brandBlack,
          onSecondary: Colors.white,
          surface: Colors.white,
          onSurface: brandBlack,
        ),

        // 2. AppBar Theme (White background, black text/icons)
        appBarTheme: const AppBarTheme(
          backgroundColor: brandYellow,
          foregroundColor: brandBlack,
          elevation: 0,
          centerTitle: true,
          titleTextStyle: TextStyle(
            color: brandBlack,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),

        // 3. Global Text Theme
        textTheme: const TextTheme(
          displayLarge: TextStyle(
            color: brandBlack,
            fontWeight: FontWeight.bold,
          ),
          bodyLarge: TextStyle(color: brandBlack),
          bodyMedium: TextStyle(color: brandBlack),
        ),

        // 4. Elevated Button Theme (The "Bolt" and "Save" buttons)
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: brandYellow,
            foregroundColor: brandBlack,
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            textStyle: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ),

        // 5. Input Decoration (For your Search & Add Stock fields)
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.grey[50],
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 12,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey.shade200),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey.shade100),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: brandYellow, width: 2),
          ),
          labelStyle: const TextStyle(color: Colors.grey, fontSize: 14),
        ),

        // 6. TabBar Theme
        tabBarTheme: const TabBarThemeData(
          // Changed to TabBarThemeData
          labelColor: brandBlack,
          unselectedLabelColor: Colors.grey,
          indicatorSize: TabBarIndicatorSize.label,
          labelStyle: TextStyle(fontWeight: FontWeight.bold),
          indicatorColor: brandYellow, // Cleaner way to set the line color
          dividerColor: Colors
              .transparent, // Removes the thin grey line under the tab bar
        ),
      ),
      routes: {
        '/login': (context) => const LoginScreen(),
        '/forgot-password': (context) => const ForgotPasswordScreen(),
        '/home': (context) => const MainNavigation(),
      },
    );
  }
}
