import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../core/constants.dart';
import '../models/user_model.dart';
import '../models/student_model.dart';
import '../models/daily_log_model.dart';
import 'database_helper.dart';

class SyncService {
  static final SyncService instance = SyncService._internal();
  SyncService._internal();

  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;
  bool _isSyncing = false;
  final ValueNotifier<bool> isSyncingNotifier = ValueNotifier<bool>(false);
  final ValueNotifier<int> pendingCountNotifier = ValueNotifier<int>(0);

  Future<void> initialize() async {
    await refreshPendingCount();

    // عمل نسخة احتياطية محلية يومية تلقائية بصيغة JSON عند تشغيل التطبيق
    try {
      await DatabaseHelper.instance.exportDailyJsonBackup();
    } catch (e) {
      debugPrint('Daily local JSON backup notice: $e');
    }

    // الاستماع لتغير حالة الاتصال بالإنترنت للمزامنة الفورية
    _connectivitySubscription = Connectivity()
        .onConnectivityChanged
        .listen((List<ConnectivityResult> results) async {
      final hasConnection = results.any((r) => r != ConnectivityResult.none);
      if (hasConnection) {
        await syncAllPendingData();
      }
    });

    // محاولة مزامنة أولية عند فتح التطبيق
    final currentConnectivity = await Connectivity().checkConnectivity();
    if (currentConnectivity.any((r) => r != ConnectivityResult.none)) {
      await syncAllPendingData();
    }
  }

  Future<void> refreshPendingCount() async {
    final count = await DatabaseHelper.instance.getUnsyncedCount();
    pendingCountNotifier.value = count;
  }

  /// رفع كافة السجلات المحلية غير المتزامنة (is_synced = 0) إلى Supabase
  Future<bool> syncAllPendingData() async {
    if (_isSyncing) return false;
    await refreshPendingCount();

    if (!AppConstants.isSupabaseConfigured) {
      return false;
    }

    _isSyncing = true;
    isSyncingNotifier.value = true;

    try {
      final supabase = Supabase.instance.client;
      final db = DatabaseHelper.instance;

      // 1. رفع المستخدمين غير المتزامنين
      final unsyncedUsers = await db.getUnsyncedUsers();
      for (final user in unsyncedUsers) {
        await supabase.from('users').upsert(user.toSupabaseMap());
        await db.markRecordSynced('users', user.id);
      }

      // 2. رفع الطلاب غير المتزامنين
      final unsyncedStudents = await db.getUnsyncedStudents();
      for (final student in unsyncedStudents) {
        await supabase.from('students').upsert(student.toSupabaseMap());
        await db.markRecordSynced('students', student.id);
      }

      // 3. رفع سجلات التسميع اليومي غير المتزامنة
      final unsyncedLogs = await db.getUnsyncedLogs();
      for (final log in unsyncedLogs) {
        await supabase.from('daily_logs').upsert(log.toSupabaseMap());
        await db.markRecordSynced('daily_logs', log.id);
      }

      // حفظ نسخة JSON محلية محدثة بعد نجاح المزامنة
      try {
        await db.exportDailyJsonBackup();
      } catch (_) {}

      await refreshPendingCount();
      return true;
    } catch (e) {
      debugPrint('Sync error: $e');
      return false;
    } finally {
      _isSyncing = false;
      isSyncingNotifier.value = false;
    }
  }

  /// استعادة وسحب كافة بيانات المستخدم (معلم أو مدير) من Supabase إلى SQLite المحلي
  /// مفيد عند تسجيل الدخول من هاتف جديد أو دخول معلم بديل
  Future<void> pullUserDataFromCloud(UserModel user) async {
    if (!AppConstants.isSupabaseConfigured) return;

    try {
      final supabase = Supabase.instance.client;
      final db = DatabaseHelper.instance;

      if (user.role == AppConstants.roleAdmin) {
        // سحب جميع المعلمين التابعين لهذا المدير
        final teachersData = await supabase
            .from('users')
            .select()
            .eq('admin_id', user.id);
        for (final row in teachersData) {
          final teacher = UserModel.fromMap(row).copyWith(isSynced: 1);
          await db.upsertUser(teacher);
        }

        // سحب جميع طلاب المركز
        final studentsData = await supabase
            .from('students')
            .select()
            .eq('admin_id', user.id);
        for (final row in studentsData) {
          final student = StudentModel.fromMap(row).copyWith(isSynced: 1);
          await db.upsertStudent(student);
        }

        // سحب جميع السجلات اليومية للمركز
        final logsData = await supabase
            .from('daily_logs')
            .select()
            .eq('admin_id', user.id);
        for (final row in logsData) {
          final log = DailyLogModel.fromMap(row).copyWithSynced(1);
          await db.upsertDailyLog(log);
        }
      } else {
        // سحب طلاب المعلم (سواء كان معلماً تابعاً أو مستقلاً)
        final studentsData = await supabase
            .from('students')
            .select()
            .eq('teacher_id', user.id);
        for (final row in studentsData) {
          final student = StudentModel.fromMap(row).copyWith(isSynced: 1);
          await db.upsertStudent(student);
        }

        // سحب سجلات التسميع الخاصة بطلاب هذا المعلم
        final logsData = await supabase
            .from('daily_logs')
            .select()
            .eq('teacher_id', user.id);
        for (final row in logsData) {
          final log = DailyLogModel.fromMap(row).copyWithSynced(1);
          await db.upsertDailyLog(log);
        }
      }

      await refreshPendingCount();
    } catch (e) {
      debugPrint('Cloud pull error: $e');
    }
  }

  /// التحقق من بيانات تسجيل الدخول سحابياً إذا لم يكن الحساب موجوداً على الجهاز المحلي
  Future<UserModel?> authenticateFromCloud(
    String username,
    String password,
    String role,
  ) async {
    if (!AppConstants.isSupabaseConfigured) return null;

    try {
      final supabase = Supabase.instance.client;
      final response = await supabase
          .from('users')
          .select()
          .eq('username', username.trim())
          .eq('password', password.trim())
          .eq('role', role)
          .maybeSingle();

      if (response != null) {
        final user = UserModel.fromMap(response).copyWith(isSynced: 1);
        await DatabaseHelper.instance.upsertUser(user);
        await pullUserDataFromCloud(user);
        return user;
      }
    } catch (e) {
      debugPrint('Cloud auth error: $e');
    }
    return null;
  }

  void dispose() {
    _connectivitySubscription?.cancel();
  }
}

extension DailyLogSyncExt on DailyLogModel {
  DailyLogModel copyWithSynced(int syncedValue) {
    return DailyLogModel(
      id: id,
      studentId: studentId,
      teacherId: teacherId,
      adminId: adminId,
      logDate: logDate,
      status: status,
      memSurahNumber: memSurahNumber,
      memSurahName: memSurahName,
      memFromAyah: memFromAyah,
      memToAyah: memToAyah,
      memFromPage: memFromPage,
      memToPage: memToPage,
      revSurahNumber: revSurahNumber,
      revSurahName: revSurahName,
      revFromAyah: revFromAyah,
      revToAyah: revToAyah,
      revFromPage: revFromPage,
      revToPage: revToPage,
      notes: notes,
      createdAt: createdAt,
      isSynced: syncedValue,
    );
  }
}
