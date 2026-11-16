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

Future<void> _initCloudInBackground() async {
  if (AppConstants.isSupabaseConfigured) {
    try {
      await Supabase.initialize(
        url: AppConstants.supabaseUrl,
        anonKey: AppConstants.supabaseAnonKey,
      ).timeout(const Duration(seconds: 4));
    } catch (e) {
      debugPrint('Offline/Cloud init skipped: $e');
    }
  }
  try {
    await SyncService.instance.initialize();
  } catch (e) {
    debugPrint('Background sync init skipped: $e');
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await DatabaseHelper.instance.database;

  final prefs = await SharedPreferences.getInstance();
  final savedUserId = prefs.getString('logged_in_user_id');
  UserModel? initialUser;
  if (savedUserId != null && savedUserId.isNotEmpty) {
    initialUser = await DatabaseHelper.instance.getUserById(savedUserId);
  }

  runApp(SafarahApp(initialUser: initialUser));

  // تشغيل السحابة والمزامنة في الخلفية بدون تأخير فتح التطبيق أوفلاين
  _initCloudInBackground();
}

class SafarahApp extends StatelessWidget {
  final UserModel? initialUser;

  const SafarahApp({super.key, this.initialUser});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'سفرة - حلقات التحفيظ',
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
        fontFamily: 'SafarahArabic',
        scaffoldBackgroundColor: Colors.transparent,
        canvasColor: AppConstants.surfaceEmerald,
        colorScheme: const ColorScheme.dark(
          primary: AppConstants.goldAccent,
          secondary: AppConstants.lightGold,
          surface: AppConstants.surfaceEmerald,
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.transparent,
          elevation: 0,
          centerTitle: true,
          titleTextStyle: TextStyle(
            fontFamily: 'SafarahArabic',
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
          iconTheme: IconThemeData(color: AppConstants.goldAccent),
        ),
        cardTheme: CardThemeData(
          color: AppConstants.cardBackground.withOpacity(0.92),
          elevation: 4,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(
              color: AppConstants.goldAccent.withOpacity(0.35),
              width: 1,
            ),
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppConstants.goldAccent,
            foregroundColor: AppConstants.darkEmerald,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
            textStyle: const TextStyle(
              fontFamily: 'SafarahArabic',
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: const Color(0xFF0D1726),
          labelStyle: const TextStyle(color: Colors.white70),
          prefixIconColor: AppConstants.goldAccent,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: AppConstants.goldAccent.withOpacity(0.4)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: AppConstants.goldAccent.withOpacity(0.4)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppConstants.goldAccent, width: 1.8),
          ),
        ),
      ),
      home: initialUser == null
          ? const RoleSelectionScreen()
          : (initialUser!.role == AppConstants.roleAdmin
              ? AdminDashboardScreen(adminUser: initialUser!)
              : TeacherHomeScreen(teacherUser: initialUser!)),
    );
  }
}