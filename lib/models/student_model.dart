class StudentModel {
  final String id;
  final String name;
  final String teacherId;
  final String? adminId;
  final String halqaName;
  final String parentPhone;
  final int lastSurahNumber;
  final String lastSurahName;
  final int lastAyah;
  final int lastPage;
  final String createdAt;
  final int isSynced;

  StudentModel({
    required this.id,
    required this.name,
    required this.teacherId,
    this.adminId,
    required this.halqaName,
    this.parentPhone = '',
    this.lastSurahNumber = 1,
    this.lastSurahName = 'الفاتحة',
    this.lastAyah = 1,
    this.lastPage = 1,
    required this.createdAt,
    this.isSynced = 0,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'teacher_id': teacherId,
      'admin_id': adminId,
      'halqa_name': halqaName,
      'parent_phone': parentPhone,
      'last_surah_number': lastSurahNumber,
      'last_surah_name': lastSurahName,
      'last_ayah': lastAyah,
      'last_page': lastPage,
      'created_at': createdAt,
      'is_synced': isSynced,
    };
  }

  Map<String, dynamic> toSupabaseMap() {
    return {
      'id': id,
      'name': name,
      'teacher_id': teacherId,
      'admin_id': adminId,
      'halqa_name': halqaName,
      'parent_phone': parentPhone,
      'last_surah_number': lastSurahNumber,
      'last_surah_name': lastSurahName,
      'last_ayah': lastAyah,
      'last_page': lastPage,
      'created_at': createdAt,
    };
  }

  factory StudentModel.fromMap(Map<String, dynamic> map) {
    return StudentModel(
      id: map['id']?.toString() ?? '',
      name: map['name']?.toString() ?? '',
      teacherId: map['teacher_id']?.toString() ?? '',
      adminId: map['admin_id']?.toString(),
      halqaName: map['halqa_name']?.toString() ?? '',
      parentPhone: map['parent_phone']?.toString() ?? '',
      lastSurahNumber: (map['last_surah_number'] as num?)?.toInt() ?? 1,
      lastSurahName: map['last_surah_name']?.toString() ?? 'الفاتحة',
      lastAyah: (map['last_ayah'] as num?)?.toInt() ?? 1,
      lastPage: (map['last_page'] as num?)?.toInt() ?? 1,
      createdAt: map['created_at']?.toString() ?? DateTime.now().toIso8601String(),
      isSynced: map['is_synced'] is int ? map['is_synced'] as int : 1,
    );
  }

  StudentModel copyWith({
    String? id,
    String? name,
    String? teacherId,
    String? adminId,
    String? halqaName,
    String? parentPhone,
    int? lastSurahNumber,
    String? lastSurahName,
    int? lastAyah,
    int? lastPage,
    String? createdAt,
    int? isSynced,
  }) {
    return StudentModel(
      id: id ?? this.id,
      name: name ?? this.name,
      teacherId: teacherId ?? this.teacherId,
      adminId: adminId ?? this.adminId,
      halqaName: halqaName ?? this.halqaName,
      parentPhone: parentPhone ?? this.parentPhone,
      lastSurahNumber: lastSurahNumber ?? this.lastSurahNumber,
      lastSurahName: lastSurahName ?? this.lastSurahName,
      lastAyah: lastAyah ?? this.lastAyah,
      lastPage: lastPage ?? this.lastPage,
      createdAt: createdAt ?? this.createdAt,
      isSynced: isSynced ?? this.isSynced,
    );
  }
}
