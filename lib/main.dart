import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'core/constants.dart';
import 'models/user_model.dart';
import 'services/database_helper.dart';
import 'services/sync_service.dart';
import 'screens/role_selection_screen.dart';
import 'screens/admin_dashboard_screen.dart';
import 'screens/teacher_home_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  if (AppConstants.isSupabaseConfigured) {
    try {
      await Supabase.initialize(
        url: AppConstants.supabaseUrl,
        anonKey: AppConstants.supabaseAnonKey,
      );
    } catch (e) {
      debugPrint('Supabase initialization warning: $e');
    }
  }

  await DatabaseHelper.instance.database;
  await SyncService.instance.initialize();

  final prefs = await SharedPreferences.getInstance();
  final savedUserId = prefs.getString('logged_in_user_id');
  UserModel? initialUser;
  if (savedUserId != null && savedUserId.isNotEmpty) {
    initialUser = await DatabaseHelper.instance.getUserById(savedUserId);
  }

  runApp(SafarahApp(initialUser: initialUser));
}

class SafarahApp extends StatelessWidget {
  final UserModel? initialUser;

  const SafarahApp({super.key, this.initialUser});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'سَفَرَة - حلقات التحفيظ',
      debugShowCheckedModeBanner: false,
      locale: const Locale('ar', 'SA'),
      supportedLocales: const [
        Locale('ar', 'SA'),
      ],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      builder: (context, child) {
        return Directionality(
          textDirection: TextDirection.rtl,
          child: DecoratedBox(
            decoration: const BoxDecoration(
              gradient: AppConstants.emeraldBackgroundGradient,
            ),
            child: child ?? const SizedBox.shrink(),
          ),
        );
      },
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        scaffoldBackgroundColor: Colors.transparent,
        canvasColor: AppConstants.surfaceEmerald,
        colorScheme: const ColorScheme.dark(
          primary: AppConstants.goldAccent,
          onPrimary: AppConstants.darkEmerald,
          secondary: AppConstants.secondaryColor,
          onSecondary: Colors.white,
          surface: AppConstants.cardBackground,
          onSurface: Colors.white,
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF063521),
          foregroundColor: Colors.white,
          centerTitle: true,
          elevation: 2,
          iconTheme: IconThemeData(color: AppConstants.goldAccent),
          titleTextStyle: TextStyle(
            fontSize: 19,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppConstants.goldAccent,
            foregroundColor: AppConstants.darkEmerald,
            padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
            elevation: 3,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            textStyle: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 15.5,
            ),
          ),
        ),
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            foregroundColor: AppConstants.goldAccent,
            side: const BorderSide(color: AppConstants.goldAccent, width: 1.2),
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            textStyle: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
        ),
        cardTheme: CardThemeData(
          color: const Color(0xFF0A462C),
          elevation: 5,
          shadowColor: Colors.black54,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: const BorderSide(color: AppConstants.goldAccent, width: 0.9),
          ),
        ),
        dialogTheme: DialogThemeData(
          backgroundColor: const Color(0xFF073B24),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
            side: const BorderSide(color: AppConstants.goldAccent, width: 1.2),
          ),
          titleTextStyle: const TextStyle(
            color: AppConstants.goldAccent,
            fontSize: 19,
            fontWeight: FontWeight.bold,
          ),
          contentTextStyle: const TextStyle(color: Colors.white),
        ),
        chipTheme: ChipThemeData(
          backgroundColor: const Color(0xFF063521),
          selectedColor: AppConstants.goldAccent,
          labelStyle: const TextStyle(color: Colors.white, fontSize: 12.5),
          secondaryLabelStyle: const TextStyle(
            color: AppConstants.darkEmerald,
            fontWeight: FontWeight.bold,
          ),
          side: const BorderSide(color: AppConstants.goldAccent, width: 0.8),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
        inputDecorationTheme: InputDecorationTheme(
          labelStyle: const TextStyle(color: AppConstants.lightGold, fontSize: 13.5),
          hintStyle: const TextStyle(color: Colors.white54),
          prefixIconColor: AppConstants.goldAccent,
          suffixIconColor: AppConstants.goldAccent,
          filled: true,
          fillColor: const Color(0xFF052E1C),
          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppConstants.goldAccent, width: 1),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: AppConstants.goldAccent.withOpacity(0.55), width: 1),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppConstants.goldAccent, width: 1.8),
          ),
        ),
      ),
      home: _resolveHomeScreen(),
    );
  }

  Widget _resolveHomeScreen() {
    if (initialUser == null) {
      return const RoleSelectionScreen();
    }
    if (initialUser!.role == AppConstants.roleAdmin) {
      return AdminDashboardScreen(adminUser: initialUser!);
    }
    return TeacherHomeScreen(teacherUser: initialUser!);
  }
}
