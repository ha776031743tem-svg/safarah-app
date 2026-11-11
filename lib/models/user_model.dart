class UserModel {
  final String id;
  final String username;
  final String password;
  final String fullName;
  final String role;
  final String halqaName;
  final String? adminId;
  final String? email;
  final String createdAt;
  final int isSynced;

  UserModel({
    required this.id,
    required this.username,
    required this.password,
    required this.fullName,
    required this.role,
    required this.halqaName,
    this.adminId,
    this.email,
    required this.createdAt,
    this.isSynced = 0,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'username': username,
      'password': password,
      'full_name': fullName,
      'role': role,
      'halqa_name': halqaName,
      'admin_id': adminId,
      'email': email,
      'created_at': createdAt,
      'is_synced': isSynced,
    };
  }

  Map<String, dynamic> toSupabaseMap() {
    return {
      'id': id,
      'username': username,
      'password': password,
      'full_name': fullName,
      'role': role,
      'halqa_name': halqaName,
      'admin_id': adminId,
      'email': email,
      'created_at': createdAt,
    };
  }

  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      id: map['id']?.toString() ?? '',
      username: map['username']?.toString() ?? '',
      password: map['password']?.toString() ?? '',
      fullName: map['full_name']?.toString() ?? '',
      role: map['role']?.toString() ?? 'independent_teacher',
      halqaName: map['halqa_name']?.toString() ?? '',
      adminId: map['admin_id']?.toString(),
      email: map['email']?.toString(),
      createdAt: map['created_at']?.toString() ?? DateTime.now().toIso8601String(),
      isSynced: map['is_synced'] is int ? map['is_synced'] as int : 1,
    );
  }

  UserModel copyWith({
    String? id,
    String? username,
    String? password,
    String? fullName,
    String? role,
    String? halqaName,
    String? adminId,
    String? email,
    String? createdAt,
    int? isSynced,
  }) {
    return UserModel(
      id: id ?? this.id,
      username: username ?? this.username,
      password: password ?? this.password,
      fullName: fullName ?? this.fullName,
      role: role ?? this.role,
      halqaName: halqaName ?? this.halqaName,
      adminId: adminId ?? this.adminId,
      email: email ?? this.email,
      createdAt: createdAt ?? this.createdAt,
      isSynced: isSynced ?? this.isSynced,
    );
  }
}