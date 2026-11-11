import 'package:flutter/material.dart';

class AppConstants {
  // ==========================================================================
  // إعدادات Supabase السحابية
  // ==========================================================================
  static const String supabaseUrl = 'https://cqcizgdngoennqizjdoq.supabase.co';
  static const String supabaseAnonKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImNxY2l6Z2RuZ29lbm5xaXpqZG9xIiwicm9sZSI6ImFub24iLCJpYXQiOjE3OTQxNTI3MjYsImV4cCI6MjEwOTcyODcyNn0.HA0g6DAWYcyDNffOrAtE_cIHOcqr6Ly4nQILnFvNUbA';

  static bool get isSupabaseConfigured =>
      supabaseUrl.startsWith('https://') &&
      !supabaseUrl.contains('YOUR_PROJECT_ID') &&
      supabaseAnonKey.isNotEmpty &&
      !supabaseAnonKey.contains('YOUR_SUPABASE_ANON_KEY');

  // الهوية البصرية الفاخرة لتطبيق "سَفَرَة" (الزمرد الإسلامي والذهب)
  static const Color primaryColor = Color(0xFF0B5335); // أخضر زمردي ملكي
  static const Color secondaryColor = Color(0xFF146C43); // أخضر زمردي متوسط
  static const Color darkEmerald = Color(0xFF042F1D); // أخضر داكن للخلفيات العميقة
  static const Color surfaceEmerald = Color(0xFF073B24); // لون الأسطح والبطاقات الداكنة
  static const Color cardBackground = Color(0xFF0A462C); // خلفية البطاقات المرتفعة
  static const Color goldAccent = Color(0xFFD4AF37); // ذهبي إسلامي فاخر
  static const Color lightGold = Color(0xFFF3E5AB); // ذهبي فاتح للنصوص المميزة
  static const Color scaffoldBackground = Color(0xFF042F1D);

  static const LinearGradient emeraldBackgroundGradient = LinearGradient(
    begin: Alignment.topRight,
    end: Alignment.bottomLeft,
    colors: [
      Color(0xFF042F1D),
      Color(0xFF0B5335),
      Color(0xFF146C43),
      Color(0xFF073B24),
    ],
  );

  // حالات التسميع والحضور اليومي الموحدة (4 حالات)
  static const String statusRecited = 'present';
  static const String statusAttendedNoRecitation = 'attended_no_recite';
  static const String statusAbsent = 'absent';
  static const String statusExcused = 'excused';

  static String statusLabelAr(String status) {
    switch (status) {
      case statusRecited:
      case 'recited':
        return 'حاضر (سمّع)';
      case statusAttendedNoRecitation:
      case 'attended_no_recitation':
        return 'حضر ولم يُسمّع';
      case statusAbsent:
        return 'غائب';
      case statusExcused:
        return 'مستأذن';
      default:
        return 'لم يُسجّل اليوم';
    }
  }

  static Color statusColor(String status) {
    switch (status) {
      case statusRecited:
      case 'recited':
        return const Color(0xFF2ECC71); // أخضر مشرق واضح على الخلفية الداكنة
      case statusAttendedNoRecitation:
      case 'attended_no_recitation':
        return const Color(0xFFF39C12); // برتقالي كهرماني واضح
      case statusAbsent:
        return const Color(0xFFFF6B6B); // أحمر مرجاني واضح جداً على الخلفية الداكنة
      case statusExcused:
        return const Color(0xFFD4AF37); // ذهبي واضح للمستأذن
      default:
        return Colors.white60;
    }
  }

  // الأدوار
  static const String roleAdmin = 'admin';
  static const String roleManagedTeacher = 'managed_teacher';
  static const String roleIndependentTeacher = 'independent_teacher';

  static String roleLabelAr(String role) {
    switch (role) {
      case roleAdmin:
        return 'مدير مركز / مسجد';
      case roleManagedTeacher:
        return 'معلم حلقة (تابع لإدارة)';
      case roleIndependentTeacher:
        return 'معلم مستقل';
      default:
        return 'مستخدم';
    }
  }
}
