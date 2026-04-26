import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:smc_crm/core/notification_service.dart';
// MAKE SURE THIS PATH IS CORRECT
import 'ui/screens/main_navigation.dart';

void main() async {
  // Required for Firebase
  WidgetsFlutterBinding.ensureInitialized();

  // 1. Start Firebase
  await Firebase.initializeApp();

  // 2. Setup Notifications
  final notificationService = NotificationService();
  await notificationService.initNotification();

  // 3. Print Token for your Postman Test
  String? token = await notificationService.getDeviceToken();
  print("--------- SMC FCM TOKEN ---------");
  print(token);
  print("---------------------------------");

  runApp(const SMCCRMApp());
}

class SMCCRMApp extends StatelessWidget {
  const SMCCRMApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Define your custom yellow color
    const Color brandYellow = Color(0xFFFACC14);
    const Color brandBlack = Color(0xFF000000);

    return MaterialApp(
      title: 'SMC CRM',
      debugShowCheckedModeBanner: false,
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
      home: const MainNavigation(),
    );
  }
}
