import 'dart:convert';
import 'dart:io';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';
import '../models/user_model.dart';
import '../models/student_model.dart';
import '../models/daily_log_model.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('safarah_offline.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 4,
      onCreate: _createDB,
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 4) {
          try {
            await db.execute('ALTER TABLE users ADD COLUMN email TEXT;');
          } catch (_) {}
        }
        if (oldVersion < 2) {
          await db.execute("UPDATE daily_logs SET status = 'present' WHERE status = 'recited'");
          await db.execute("UPDATE daily_logs SET status = 'attended_no_recite' WHERE status = 'attended_no_recitation'");
          await db.execute("""
            CREATE TRIGGER IF NOT EXISTS daily_logs_status_insert_guard
            BEFORE INSERT ON daily_logs
            WHEN NEW.status NOT IN ('present', 'absent', 'attended_no_recite', 'excused')
            BEGIN SELECT RAISE(ABORT, 'Invalid attendance status'); END
          """);
          await db.execute("""
            CREATE TRIGGER IF NOT EXISTS daily_logs_status_update_guard
            BEFORE UPDATE OF status ON daily_logs
            WHEN NEW.status NOT IN ('present', 'absent', 'attended_no_recite', 'excused')
            BEGIN SELECT RAISE(ABORT, 'Invalid attendance status'); END
          """);
        }
      if (oldVersion < 3) {
        try {
          await db.execute('ALTER TABLE users ADD COLUMN email TEXT;');
        } catch (_) {}
      }
      },
      onOpen: (db) async {
        try {
          await db.execute('ALTER TABLE users ADD COLUMN email TEXT;');
        } catch (_) {}
      },
    );
  }

  Future<void> _createDB(Database db, int version) async {
    await db.execute('''\nCREATE TABLE users (\nid TEXT PRIMARY KEY,\nusername TEXT UNIQUE NOT NULL,\npassword TEXT NOT NULL,\nfull_name TEXT NOT NULL,\nrole TEXT NOT NULL,\nhalqa_name TEXT DEFAULT '',\nadmin_id TEXT,
  email TEXT,\ncreated_at TEXT NOT NULL,\nis_synced INTEGER DEFAULT 0\n)\n''');

    await db.execute('''\nCREATE TABLE students (\nid TEXT PRIMARY KEY,\nname TEXT NOT NULL,\nteacher_id TEXT NOT NULL,\nadmin_id TEXT,
  email TEXT,\nhalqa_name TEXT DEFAULT '',\nparent_phone TEXT DEFAULT '',\nlast_surah_number INTEGER DEFAULT 1,\nlast_surah_name TEXT DEFAULT 'الفاتحة',\nlast_ayah INTEGER DEFAULT 1,\nlast_page INTEGER DEFAULT 1,\ncreated_at TEXT NOT NULL,\nis_synced INTEGER DEFAULT 0\n)\n''');

    await db.execute('''\nCREATE TABLE daily_logs (\nid TEXT PRIMARY KEY,\nstudent_id TEXT NOT NULL,\nteacher_id TEXT NOT NULL,\nadmin_id TEXT,
  email TEXT,\nlog_date TEXT NOT NULL,\nstatus TEXT NOT NULL CHECK(status IN ('present', 'absent', 'attended_no_recite', 'excused')),\nmem_surah_number INTEGER,\nmem_surah_name TEXT,\nmem_from_ayah INTEGER,\nmem_to_ayah INTEGER,\nmem_from_page INTEGER,\nmem_to_page INTEGER,\nrev_surah_number INTEGER,\nrev_surah_name TEXT,\nrev_from_ayah INTEGER,\nrev_to_ayah INTEGER,\nrev_from_page INTEGER,\nrev_to_page INTEGER,\nnotes TEXT DEFAULT '',\ncreated_at TEXT NOT NULL,\nis_synced INTEGER DEFAULT 0\n)\n''');
  }

  // ==========================================================================
  // عمليات المستخدمين (Users CRUD)
  // ==========================================================================
  Future<void> upsertUser(UserModel user) async {
    final db = await instance.database;
    await db.insert(
      'users',
      user.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<UserModel?> getUserByCredentials(
    String username,
    String password,
    String role,
  ) async {
    final db = await instance.database;
    final maps = await db.query(
      'users',
      where: 'LOWER(username) = LOWER(?) AND password = ? AND role = ?',
      whereArgs: [username.trim(), password.trim(), role],
    );
    if (maps.isNotEmpty) {
      return UserModel.fromMap(maps.first);
    }
    return null;
  }

  Future<UserModel?> getUserByUsername(String username) async {
    final db = await instance.database;
    final maps = await db.query(
      'users',
      where: 'username = ?',
      whereArgs: [username.trim()],
    );
    if (maps.isNotEmpty) {
      return UserModel.fromMap(maps.first);
    }
    return null;
  }

  Future<UserModel?> getUserById(String id) async {
    final db = await instance.database;
    final maps = await db.query(
      'users',
      where: 'id = ?',
      whereArgs: [id],
    );
    if (maps.isNotEmpty) {
      return UserModel.fromMap(maps.first);
    }
    return null;
  }

  Future<List<UserModel>> getTeachersByAdmin(String adminId) async {
    final db = await instance.database;
    final maps = await db.query(
      'users',
      where: 'admin_id = ? AND role = ?',
      whereArgs: [adminId, 'managed_teacher'],
      orderBy: 'created_at DESC',
    );
    return maps.map((e) => UserModel.fromMap(e)).toList();
  }

  // ==========================================================================
  // عمليات الطلاب (Students CRUD)
  // ==========================================================================
  Future<void> upsertStudent(StudentModel student) async {
    final db = await instance.database;
    await db.insert(
      'students',
      student.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<StudentModel>> getStudentsByTeacher(String teacherId) async {
    final db = await instance.database;
    final maps = await db.query(
      'students',
      where: 'teacher_id = ?',
      whereArgs: [teacherId],
      orderBy: 'name ASC',
    );
    return maps.map((e) => StudentModel.fromMap(e)).toList();
  }

  Future<List<StudentModel>> getStudentsByAdmin(String adminId) async {
    final db = await instance.database;
    final maps = await db.query(
      'students',
      where: 'admin_id = ?',
      whereArgs: [adminId],
      orderBy: 'name ASC',
    );
    return maps.map((e) => StudentModel.fromMap(e)).toList();
  }

  Future<StudentModel?> getStudentById(String id) async {
    final db = await instance.database;
    final maps = await db.query(
      'students',
      where: 'id = ?',
      whereArgs: [id],
    );
    if (maps.isNotEmpty) {
      return StudentModel.fromMap(maps.first);
    }
    return null;
  }

  Future<void> deleteStudent(String studentId) async {
    final db = await instance.database;
    await db.delete('students', where: 'id = ?', whereArgs: [studentId]);
    await db.delete('daily_logs', where: 'student_id = ?', whereArgs: [studentId]);
  }

  // ==========================================================================
  // عمليات السجلات اليومية (Daily Logs CRUD)
  // ==========================================================================
  Future<void> upsertDailyLog(DailyLogModel log) async {
    final db = await instance.database;
    await db.insert(
      'daily_logs',
      log.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );

    // إذا كان السجل يتضمن تسميعاً جديداً للحفظ، نحدث موضع توقف الطالب تلقائياً
    if (log.status == 'present' &&
        log.memSurahNumber != null &&
        log.memSurahName != null &&
        log.memToAyah != null &&
        log.memToPage != null) {
      final student = await getStudentById(log.studentId);
      if (student != null) {
        final updatedStudent = student.copyWith(
          lastSurahNumber: log.memSurahNumber!,
          lastSurahName: log.memSurahName!,
          lastAyah: log.memToAyah!,
          lastPage: log.memToPage!,
          isSynced: 0,
        );
        await upsertStudent(updatedStudent);
      }
    }
  }

  Future<DailyLogModel?> getStudentLogByDate(
    String studentId,
    String logDate,
  ) async {
    final db = await instance.database;
    final maps = await db.query(
      'daily_logs',
      where: 'student_id = ? AND log_date = ?',
      whereArgs: [studentId, logDate],
      orderBy: 'created_at DESC',
      limit: 1,
    );
    if (maps.isNotEmpty) {
      return DailyLogModel.fromMap(maps.first);
    }
    return null;
  }

  Future<List<DailyLogModel>> getLogsByStudent(String studentId) async {
    final db = await instance.database;
    final maps = await db.query(
      'daily_logs',
      where: 'student_id = ?',
      whereArgs: [studentId],
      orderBy: 'log_date DESC, created_at DESC',
    );
    return maps.map((e) => DailyLogModel.fromMap(e)).toList();
  }

  Future<List<DailyLogModel>> getLogsByStudentInDateRange(
    String studentId,
    String startDate,
    String endDate,
  ) async {
    final db = await instance.database;
    final maps = await db.query(
      'daily_logs',
      where: 'student_id = ? AND log_date >= ? AND log_date <= ?',
      whereArgs: [studentId, startDate, endDate],
      orderBy: 'log_date DESC',
    );
    return maps.map((e) => DailyLogModel.fromMap(e)).toList();
  }

  Future<List<DailyLogModel>> getLogsByAdmin(String adminId) async {
    final db = await instance.database;
    final maps = await db.query(
      'daily_logs',
      where: 'admin_id = ?',
      whereArgs: [adminId],
      orderBy: 'log_date DESC',
    );
    return maps.map((e) => DailyLogModel.fromMap(e)).toList();
  }

  // ==========================================================================
  // استعلامات السجلات غير المتزامنة (Unsynced Records)
  // ==========================================================================
  Future<List<UserModel>> getUnsyncedUsers() async {
    final db = await instance.database;
    final maps = await db.query('users', where: 'is_synced = 0');
    return maps.map((e) => UserModel.fromMap(e)).toList();
  }

  Future<List<StudentModel>> getUnsyncedStudents() async {
    final db = await instance.database;
    final maps = await db.query('students', where: 'is_synced = 0');
    return maps.map((e) => StudentModel.fromMap(e)).toList();
  }

  Future<List<DailyLogModel>> getUnsyncedLogs() async {
    final db = await instance.database;
    final maps = await db.query('daily_logs', where: 'is_synced = 0');
    return maps.map((e) => DailyLogModel.fromMap(e)).toList();
  }

  Future<int> getUnsyncedCount() async {
    final u = await getUnsyncedUsers();
    final s = await getUnsyncedStudents();
    final l = await getUnsyncedLogs();
    return u.length + s.length + l.length;
  }

  Future<void> markRecordSynced(String table, String id) async {
    final db = await instance.database;
    await db.update(
      table,
      {'is_synced': 1},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // ==========================================================================
  // النسخ الاحتياطي المحلي اليومي بصيغة JSON في مجلد التحميلات / المستندات
  // ==========================================================================
  Future<String> exportDailyJsonBackup() async {
    final db = await instance.database;
    final users = await db.query('users');
    final students = await db.query('students');
    final logs = await db.query('daily_logs');

    final backupPayload = {
      'app': 'Safarah - سَفَرَة',
      'backup_date': DateTime.now().toIso8601String(),
      'users': users,
      'students': students,
      'daily_logs': logs,
    };

    final jsonString = const JsonEncoder.withIndent('  ').convert(backupPayload);
    final dateSlug = DateTime.now().toIso8601String().split('T').first;

    Directory targetDir;
    if (Platform.isAndroid) {
      final downloadDir = Directory('/storage/emulated/0/Download');
      if (await downloadDir.exists()) {
        targetDir = downloadDir;
      } else {
        targetDir = await getExternalStorageDirectory() ??
            await getApplicationDocumentsDirectory();
      }
    } else {
      targetDir = await getApplicationDocumentsDirectory();
    }

    final filePath = join(targetDir.path, 'safarah_backup_$dateSlug.json');
    final file = File(filePath);
    await file.writeAsString(jsonString, flush: true);
    return filePath;
  }
}
