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
  String? lastSyncError;

  Future<void> initialize() async {
    await refreshPendingCount();
    try {
      await DatabaseHelper.instance.exportDailyJsonBackup();
    } catch (_) {}

    _connectivitySubscription = Connectivity()
        .onConnectivityChanged
        .listen((List<ConnectivityResult> results) async {
      if (results.any((r) => r != ConnectivityResult.none)) {
        await syncAllPendingData();
      }
    });

    Future.delayed(const Duration(seconds: 2), () {
      syncAllPendingData();
    });
  }

  Future<void> refreshPendingCount() async {
    final count = await DatabaseHelper.instance.getUnsyncedCount();
    pendingCountNotifier.value = count;
  }

  /// رفع فوري لمستخدم (مدير أو معلم) إلى Supabase
  Future<bool> pushUserImmediately(UserModel user) async {
    if (!AppConstants.isSupabaseConfigured) return false;
    try {
      final supabase = Supabase.instance.client;
      await supabase.from('users').upsert(user.toSupabaseMap());
      await DatabaseHelper.instance.markRecordSynced('users', user.id);
      await refreshPendingCount();
      lastSyncError = null;
      return true;
    } catch (e) {
      lastSyncError = e.toString();
      debugPrint('Immediate user push error: $e');
      return false;
    }
  }

  Future<bool> syncAllPendingData() async {
    if (_isSyncing || !AppConstants.isSupabaseConfigured) return false;

    _isSyncing = true;
    isSyncingNotifier.value = true;
    bool allSuccess = true;

    try {
      final supabase = Supabase.instance.client;
      final db = DatabaseHelper.instance;

      // 1. رفع المستخدمين
      final unsyncedUsers = await db.getUnsyncedUsers();
      for (final user in unsyncedUsers) {
        try {
          await supabase.from('users').upsert(user.toSupabaseMap());
          await db.markRecordSynced('users', user.id);
        } catch (e) {
          allSuccess = false;
          lastSyncError = e.toString();
          debugPrint('User sync error: $e');
        }
      }

      // 2. رفع الطلاب
      final unsyncedStudents = await db.getUnsyncedStudents();
      for (final student in unsyncedStudents) {
        try {
          await supabase.from('students').upsert(student.toSupabaseMap());
          await db.markRecordSynced('students', student.id);
        } catch (e) {
          allSuccess = false;
          lastSyncError = e.toString();
          debugPrint('Student sync error: $e');
        }
      }

      // 3. رفع السجلات اليومية
      final unsyncedLogs = await db.getUnsyncedLogs();
      for (final log in unsyncedLogs) {
        try {
          await supabase.from('daily_logs').upsert(log.toSupabaseMap());
          await db.markRecordSynced('daily_logs', log.id);
        } catch (e) {
          try {
            final fallbackMap = Map<String, dynamic>.from(log.toSupabaseMap());
            if (fallbackMap['status'] == 'present') fallbackMap['status'] = 'recited';
            if (fallbackMap['status'] == 'attended_no_recite') fallbackMap['status'] = 'attended_no_recitation';
            if (fallbackMap['status'] == 'excused') fallbackMap['status'] = 'absent';
            await supabase.from('daily_logs').upsert(fallbackMap);
            await db.markRecordSynced('daily_logs', log.id);
          } catch (e2) {
            allSuccess = false;
            lastSyncError = e2.toString();
            debugPrint('Log sync error: $e2');
          }
        }
      }

      await refreshPendingCount();
      return allSuccess;
    } finally {
      _isSyncing = false;
      isSyncingNotifier.value = false;
    }
  }

  Future<void> pullUserDataFromCloud(UserModel user) async {
    if (!AppConstants.isSupabaseConfigured) return;
    try {
      final supabase = Supabase.instance.client;
      final db = DatabaseHelper.instance;

      if (user.role == AppConstants.roleAdmin) {
        final teachersData = await supabase.from('users').select().eq('admin_id', user.id);
        for (final row in teachersData) {
          await db.upsertUser(UserModel.fromMap(row).copyWith(isSynced: 1));
        }
        final studentsData = await supabase.from('students').select().eq('admin_id', user.id);
        for (final row in studentsData) {
          await db.upsertStudent(StudentModel.fromMap(row).copyWith(isSynced: 1));
        }
        final logsData = await supabase.from('daily_logs').select().eq('admin_id', user.id);
        for (final row in logsData) {
          await db.upsertDailyLog(DailyLogModel.fromMap(row).copyWithSynced(1));
        }
      } else {
        final studentsData = await supabase.from('students').select().eq('teacher_id', user.id);
        for (final row in studentsData) {
          await db.upsertStudent(StudentModel.fromMap(row).copyWith(isSynced: 1));
        }
        final logsData = await supabase.from('daily_logs').select().eq('teacher_id', user.id);
        for (final row in logsData) {
          await db.upsertDailyLog(DailyLogModel.fromMap(row).copyWithSynced(1));
        }
      }
      await refreshPendingCount();
    } catch (e) {
      debugPrint('Cloud pull error: $e');
    }
  }

  Future<UserModel?> authenticateFromCloud(String username, String password, String role) async {
    if (!AppConstants.isSupabaseConfigured) return null;
    try {
      final supabase = Supabase.instance.client;
      final cleanUser = username.trim().toLowerCase();
      final cleanPass = password.trim();

      final allUsers = await supabase.from('users').select();
      for (final row in allUsers) {
        final dbUser = (row['username']?.toString() ?? '').trim().toLowerCase();
        final dbPass = (row['password']?.toString() ?? '').trim();
        final dbRole = (row['role']?.toString() ?? '').trim();

        if (dbUser == cleanUser && dbPass == cleanPass && dbRole == role) {
          final user = UserModel.fromMap(row).copyWith(isSynced: 1);
          await DatabaseHelper.instance.upsertUser(user);
          await pullUserDataFromCloud(user);
          return user;
        }
      }
    } catch (e) {
      lastSyncError = e.toString();
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
      id: id, studentId: studentId, teacherId: teacherId, adminId: adminId,
      logDate: logDate, status: status, memSurahNumber: memSurahNumber,
      memSurahName: memSurahName, memFromAyah: memFromAyah, memToAyah: memToAyah,
      memFromPage: memFromPage, memToPage: memToPage, revSurahNumber: revSurahNumber,
      revSurahName: revSurahName, revFromAyah: revFromAyah, revToAyah: revToAyah,
      revFromPage: revFromPage, revToPage: revToPage, notes: notes,
      createdAt: createdAt, isSynced: syncedValue,
    );
  }
}