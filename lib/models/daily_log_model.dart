class DailyLogModel {
  final String id;
  final String studentId;
  final String teacherId;
  final String? adminId;
  final String logDate; // YYYY-MM-DD
  final String status; // present, absent, attended_no_recite, excused

  // بيانات الحفظ
  final int? memSurahNumber;
  final String? memSurahName;
  final int? memFromAyah;
  final int? memToAyah;
  final int? memFromPage;
  final int? memToPage;

  // بيانات المراجعة
  final int? revSurahNumber;
  final String? revSurahName;
  final int? revFromAyah;
  final int? revToAyah;
  final int? revFromPage;
  final int? revToPage;

  final String notes;
  final String createdAt;
  final int isSynced;

  DailyLogModel({
    required this.id,
    required this.studentId,
    required this.teacherId,
    this.adminId,
    required this.logDate,
    required this.status,
    this.memSurahNumber,
    this.memSurahName,
    this.memFromAyah,
    this.memToAyah,
    this.memFromPage,
    this.memToPage,
    this.revSurahNumber,
    this.revSurahName,
    this.revFromAyah,
    this.revToAyah,
    this.revFromPage,
    this.revToPage,
    this.notes = '',
    required this.createdAt,
    this.isSynced = 0,
  });

  int get memPagesCount {
    if ((status != 'present' && status != 'recited') || memFromPage == null || memToPage == null) return 0;
    final diff = memToPage! - memFromPage! + 1;
    return diff > 0 ? diff : 1;
  }

  int get revPagesCount {
    if ((status != 'present' && status != 'recited') || revFromPage == null || revToPage == null) return 0;
    final diff = revToPage! - revFromPage! + 1;
    return diff > 0 ? diff : 1;
  }

  String get formattedMemorization {
    if ((status != 'present' && status != 'recited') || memSurahName == null || memSurahName!.isEmpty) {
      return '-';
    }
    return 'سورة $memSurahName: آية (${memFromAyah ?? 1} - ${memToAyah ?? 1}) | ص (${memFromPage ?? 1} - ${memToPage ?? 1})';
  }

  String get formattedRevision {
    if ((status != 'present' && status != 'recited') || revSurahName == null || revSurahName!.isEmpty) {
      return '-';
    }
    return 'سورة $revSurahName: آية (${revFromAyah ?? 1} - ${revToAyah ?? 1}) | ص (${revFromPage ?? 1} - ${revToPage ?? 1})';
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'student_id': studentId,
      'teacher_id': teacherId,
      'admin_id': adminId,
      'log_date': logDate,
      'status': status,
      'mem_surah_number': memSurahNumber,
      'mem_surah_name': memSurahName,
      'mem_from_ayah': memFromAyah,
      'mem_to_ayah': memToAyah,
      'mem_from_page': memFromPage,
      'mem_to_page': memToPage,
      'rev_surah_number': revSurahNumber,
      'rev_surah_name': revSurahName,
      'rev_from_ayah': revFromAyah,
      'rev_to_ayah': revToAyah,
      'rev_from_page': revFromPage,
      'rev_to_page': revToPage,
      'notes': notes,
      'created_at': createdAt,
      'is_synced': isSynced,
    };
  }

  Map<String, dynamic> toSupabaseMap() {
    return {
      'id': id,
      'student_id': studentId,
      'teacher_id': teacherId,
      'admin_id': adminId,
      'log_date': logDate,
      'status': status,
      'mem_surah_number': memSurahNumber,
      'mem_surah_name': memSurahName,
      'mem_from_ayah': memFromAyah,
      'mem_to_ayah': memToAyah,
      'mem_from_page': memFromPage,
      'mem_to_page': memToPage,
      'rev_surah_number': revSurahNumber,
      'rev_surah_name': revSurahName,
      'rev_from_ayah': revFromAyah,
      'rev_to_ayah': revToAyah,
      'rev_from_page': revFromPage,
      'rev_to_page': revToPage,
      'notes': notes,
      'created_at': createdAt,
    };
  }

  static String _normalizeStatus(String? value) {
    switch (value) {
      case 'recited':
      case 'present':
        return 'present';
      case 'attended_no_recitation':
      case 'attended_no_recite':
        return 'attended_no_recite';
      case 'absent':
        return 'absent';
      case 'excused':
        return 'excused';
      default:
        return 'present';
    }
  }

  factory DailyLogModel.fromMap(Map<String, dynamic> map) {
    return DailyLogModel(
      id: map['id']?.toString() ?? '',
      studentId: map['student_id']?.toString() ?? '',
      teacherId: map['teacher_id']?.toString() ?? '',
      adminId: map['admin_id']?.toString(),
      logDate: map['log_date']?.toString() ?? '',
      status: _normalizeStatus(map['status']?.toString()),
      memSurahNumber: (map['mem_surah_number'] as num?)?.toInt(),
      memSurahName: map['mem_surah_name']?.toString(),
      memFromAyah: (map['mem_from_ayah'] as num?)?.toInt(),
      memToAyah: (map['mem_to_ayah'] as num?)?.toInt(),
      memFromPage: (map['mem_from_page'] as num?)?.toInt(),
      memToPage: (map['mem_to_page'] as num?)?.toInt(),
      revSurahNumber: (map['rev_surah_number'] as num?)?.toInt(),
      revSurahName: map['rev_surah_name']?.toString(),
      revFromAyah: (map['rev_from_ayah'] as num?)?.toInt(),
      revToAyah: (map['rev_to_ayah'] as num?)?.toInt(),
      revFromPage: (map['rev_from_page'] as num?)?.toInt(),
      revToPage: (map['rev_to_page'] as num?)?.toInt(),
      notes: map['notes']?.toString() ?? '',
      createdAt: map['created_at']?.toString() ?? DateTime.now().toIso8601String(),
      isSynced: map['is_synced'] is int ? map['is_synced'] as int : 1,
    );
  }
}
