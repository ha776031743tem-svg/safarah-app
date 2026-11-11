import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/constants.dart';
import '../models/user_model.dart';
import '../services/database_helper.dart';
import '../services/sync_service.dart';
import 'admin_dashboard_screen.dart';
import 'teacher_home_screen.dart';

class AuthScreen extends StatefulWidget {
  final String role;
  final bool allowRegister;

  const AuthScreen({
    super.key,
    required this.role,
    required this.allowRegister,
  });

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _fullNameController = TextEditingController();
  final _halqaNameController = TextEditingController();

  bool _isLogin = true;
  bool _isLoading = false;

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    _fullNameController.dispose();
    _halqaNameController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final username = _usernameController.text.trim();
      final password = _passwordController.text.trim();
      final db = DatabaseHelper.instance;

      UserModel? user;

      if (_isLogin) {
        user = await db.getUserByCredentials(username, password, widget.role);

        user ??= await SyncService.instance.authenticateFromCloud(
          username,
          password,
          widget.role,
        );

        if (user == null) {
          _showMessage('بيانات الدخول غير صحيحة أو الحساب غير مسجل لهذا الدور.');
          setState(() => _isLoading = false);
          return;
        }

        await SyncService.instance.pullUserDataFromCloud(user);
      } else {
        final existing = await db.getUserByUsername(username);
        if (existing != null) {
          _showMessage('اسم المستخدم مسجل مسبقاً، اختر اسماً آخر.');
          setState(() => _isLoading = false);
          return;
        }

        final newUser = UserModel(
          id: 'usr_${DateTime.now().millisecondsSinceEpoch}',
          username: username,
          password: password,
          fullName: _fullNameController.text.trim(),
          role: widget.role,
          halqaName: widget.role == AppConstants.roleAdmin
              ? (_halqaNameController.text.trim().isEmpty
                  ? 'مركز تحفيظ القرآن'
                  : _halqaNameController.text.trim())
              : (_halqaNameController.text.trim().isEmpty
                  ? 'حلقة النور'
                  : _halqaNameController.text.trim()),
          adminId: null,
          createdAt: DateTime.now().toIso8601String(),
          isSynced: 0,
        );

        await db.upsertUser(newUser);
        await SyncService.instance.pushUserImmediately(newUser);
        await SyncService.instance.syncAllPendingData();
        user = newUser;
      }

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('logged_in_user_id', user.id);

      if (!mounted) return;
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(
          builder: (_) => user!.role == AppConstants.roleAdmin
              ? AdminDashboardScreen(adminUser: user)
              : TeacherHomeScreen(teacherUser: user),
        ),
        (route) => false,
      );
    } catch (e) {
      _showMessage('حدث خطأ أثناء العملية: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _showMessage(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final roleTitle = AppConstants.roleLabelAr(widget.role);

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: Text(roleTitle),
      ),
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: AppConstants.emeraldBackgroundGradient,
        ),
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Card(
              elevation: 6,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
                side: const BorderSide(color: AppConstants.goldAccent, width: 1.2),
              ),
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppConstants.goldAccent.withOpacity(0.15),
                          border: Border.all(color: AppConstants.goldAccent, width: 1.5),
                        ),
                        child: Icon(
                          _isLogin
                              ? Icons.lock_open_rounded
                              : Icons.person_add_alt_1_rounded,
                          size: 42,
                          color: AppConstants.goldAccent,
                        ),
                      ),
                      const SizedBox(height: 14),
                      Text(
                        _isLogin ? 'تسجيل الدخول' : 'إنشاء حساب جديد',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 23,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        roleTitle,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: AppConstants.goldAccent,
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 24),
                      if (!_isLogin) ...[
                        TextFormField(
                          controller: _fullNameController,
                          style: const TextStyle(color: Colors.white),
                          decoration: InputDecoration(
                            labelText: widget.role == AppConstants.roleAdmin
                                ? 'اسم المدير الكامل'
                                : 'اسم المعلم الكامل',
                            prefixIcon: const Icon(Icons.badge_outlined),
                          ),
                          validator: (val) =>
                              val == null || val.trim().isEmpty ? 'هذا الحقل مطلوب' : null,
                        ),
                        const SizedBox(height: 14),
                        TextFormField(
                          controller: _halqaNameController,
                          style: const TextStyle(color: Colors.white),
                          decoration: InputDecoration(
                            labelText: widget.role == AppConstants.roleAdmin
                                ? 'اسم المركز أو المسجد'
                                : 'اسم الحلقة القرآنية',
                            prefixIcon: const Icon(Icons.mosque_outlined),
                          ),
                          validator: (val) =>
                              val == null || val.trim().isEmpty ? 'هذا الحقل مطلوب' : null,
                        ),
                        const SizedBox(height: 14),
                      ],
                      TextFormField(
                        controller: _usernameController,
                        style: const TextStyle(color: Colors.white),
                        decoration: const InputDecoration(
                          labelText: 'اسم المستخدم (Username)',
                          prefixIcon: Icon(Icons.person_outline),
                        ),
                        validator: (val) =>
                            val == null || val.trim().isEmpty ? 'أدخل اسم المستخدم' : null,
                      ),
                      const SizedBox(height: 14),
                      TextFormField(
                        controller: _passwordController,
                        obscureText: true,
                        style: const TextStyle(color: Colors.white),
                        decoration: const InputDecoration(
                          labelText: 'كلمة المرور (Password)',
                          prefixIcon: Icon(Icons.key_outlined),
                        ),
                        validator: (val) =>
                            val == null || val.trim().length < 3 ? 'أدخل كلمة مرور صالحة' : null,
                      ),
                      const SizedBox(height: 24),
                      ElevatedButton(
                        onPressed: _isLoading ? null : _submit,
                        child: _isLoading
                            ? const SizedBox(
                                height: 22,
                                width: 22,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.5,
                                  color: AppConstants.darkEmerald,
                                ),
                              )
                            : Text(_isLogin ? 'دخول' : 'إنشاء الحساب والبدء'),
                      ),
                      if (widget.allowRegister) ...[
                        const SizedBox(height: 14),
                        TextButton(
                          onPressed: () {
                            setState(() {
                              _isLogin = !_isLogin;
                            });
                          },
                          child: Text(
                            _isLogin
                                ? 'ليس لديك حساب؟ إنشاء حساب جديد'
                                : 'لديك حساب بالفعل؟ تسجيل الدخول',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: AppConstants.goldAccent,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ] else ...[
                        const SizedBox(height: 14),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: AppConstants.goldAccent.withOpacity(0.4)),
                          ),
                          child: const Text(
                            'ملاحظة: يتم تزويدك باسم المستخدم وكلمة المرور من قِبل مدير المركز/المسجد. عند دخولك سيقوم التطبيق بسحب بيانات حلقتك وطلابك تلقائياً.',
                            textAlign: TextAlign.center,
                            style: TextStyle(fontSize: 12.5, color: Colors.white70, height: 1.4),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
