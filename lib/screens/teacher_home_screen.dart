import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/constants.dart';
import '../core/quran_metadata.dart';
import '../models/user_model.dart';
import '../models/student_model.dart';
import '../models/daily_log_model.dart';
import '../services/database_helper.dart';
import '../services/sync_service.dart';
import 'role_selection_screen.dart';
import 'student_detail_screen.dart';

class TeacherHomeScreen extends StatefulWidget {
  final UserModel teacherUser;

  const TeacherHomeScreen({super.key, required this.teacherUser});

  @override
  State<TeacherHomeScreen> createState() => _TeacherHomeScreenState();
}

class _TeacherHomeScreenState extends State<TeacherHomeScreen> {
  List<StudentModel> _students = [];
  Map<String, DailyLogModel?> _todayLogs = {};
  bool _isLoading = true;
  late String _todayDate;

  @override
  void initState() {
    super.initState();
    _todayDate = DateFormat('yyyy-MM-dd').format(DateTime.now());
    _loadStudents();
  }

  Future<void> _loadStudents() async {
    setState(() => _isLoading = true);
    final db = DatabaseHelper.instance;
    final students = await db.getStudentsByTeacher(widget.teacherUser.id);

    final Map<String, DailyLogModel?> todayMap = {};
    for (final st in students) {
      todayMap[st.id] = await db.getStudentLogByDate(st.id, _todayDate);
    }

    await SyncService.instance.refreshPendingCount();

    if (mounted) {
      setState(() {
        _students = students;
        _todayLogs = todayMap;
        _isLoading = false;
      });
    }
  }

  Future<void> _showAddStudentDialog() async {
    final nameCtrl = TextEditingController();
    final phoneCtrl = TextEditingController();
    SurahInfo selectedSurah = QuranMetadata.surahs.first;
    final ayahCtrl = TextEditingController(text: '1');
    final pageCtrl = TextEditingController(text: '1');
    final formKey = GlobalKey<FormState>();

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Text('إضافة طالب جديد للحلقة'),
          content: SingleChildScrollView(
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  TextFormField(
                    controller: nameCtrl,
                    style: const TextStyle(color: Colors.white),
                    decoration: const InputDecoration(
                      labelText: 'اسم الطالب الثلاثي',
                      prefixIcon: Icon(Icons.person_outline),
                    ),
                    validator: (v) =>
                        v == null || v.trim().isEmpty ? 'أدخل اسم الطالب' : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: phoneCtrl,
                    keyboardType: TextInputType.phone,
                    style: const TextStyle(color: Colors.white),
                    decoration: const InputDecoration(
                      labelText: 'رقم هاتف ولي الأمر (اختياري)',
                      prefixIcon: Icon(Icons.phone_outlined),
                    ),
                  ),
                  const SizedBox(height: 14),
                  const Text(
                    'موضع البداية الحالي للطالب في الحفظ:',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 13.5,
                      color: AppConstants.goldAccent,
                    ),
                  ),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<int>(
                    value: selectedSurah.number,
                    dropdownColor: AppConstants.surfaceEmerald,
                    style: const TextStyle(color: Colors.white),
                    decoration: const InputDecoration(labelText: 'السورة الحالية'),
                    items: QuranMetadata.surahs
                        .map(
                          (s) => DropdownMenuItem<int>(
                            value: s.number,
                            child: Text(
                              '${s.number}. سورة ${s.name}',
                              style: const TextStyle(color: Colors.white),
                            ),
                          ),
                        )
                        .toList(),
                    onChanged: (val) {
                      if (val != null) {
                        final s = QuranMetadata.getByNumber(val);
                        setDialogState(() {
                          selectedSurah = s;
                          ayahCtrl.text = '1';
                          pageCtrl.text = s.startPage.toString();
                        });
                      }
                    },
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: ayahCtrl,
                          keyboardType: TextInputType.number,
                          style: const TextStyle(color: Colors.white),
                          decoration: const InputDecoration(labelText: 'آخر آية'),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: TextFormField(
                          controller: pageCtrl,
                          keyboardType: TextInputType.number,
                          style: const TextStyle(color: Colors.white),
                          decoration: const InputDecoration(labelText: 'الصفحة'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('إلغاء', style: TextStyle(color: Colors.white70)),
            ),
            ElevatedButton(
              onPressed: () async {
                if (!formKey.currentState!.validate()) return;

                final newStudent = StudentModel(
                  id: 'stu_${DateTime.now().millisecondsSinceEpoch}',
                  name: nameCtrl.text.trim(),
                  teacherId: widget.teacherUser.id,
                  adminId: widget.teacherUser.adminId,
                  halqaName: widget.teacherUser.halqaName,
                  parentPhone: phoneCtrl.text.trim(),
                  lastSurahNumber: selectedSurah.number,
                  lastSurahName: selectedSurah.name,
                  lastAyah: int.tryParse(ayahCtrl.text) ?? 1,
                  lastPage: int.tryParse(pageCtrl.text) ?? selectedSurah.startPage,
                  createdAt: DateTime.now().toIso8601String(),
                  isSynced: 0,
                );

                await DatabaseHelper.instance.upsertStudent(newStudent);
                await SyncService.instance.syncAllPendingData();
                if (ctx.mounted) Navigator.pop(ctx);
                await _loadStudents();
              },
              child: const Text('إضافة الطالب'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('logged_in_user_id');
    if (!mounted) return;
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const RoleSelectionScreen()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    int recitedToday = 0;
    int noReciteToday = 0;
    int excusedToday = 0;
    int absentToday = 0;
    for (final log in _todayLogs.values) {
      if (log?.status == AppConstants.statusRecited) recitedToday++;
      if (log?.status == AppConstants.statusAttendedNoRecitation) noReciteToday++;
      if (log?.status == AppConstants.statusExcused) excusedToday++;
      if (log?.status == AppConstants.statusAbsent) absentToday++;
    }

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: Column(
          children: [
            Text('حلقة: ${widget.teacherUser.halqaName}'),
            Text(
              'المعلم: ${widget.teacherUser.fullName}',
              style: const TextStyle(fontSize: 12, color: AppConstants.lightGold),
            ),
          ],
        ),
        actions: [
          ValueListenableBuilder<int>(
            valueListenable: SyncService.instance.pendingCountNotifier,
            builder: (ctx, pendingCount, _) {
              return IconButton(
                tooltip: pendingCount > 0
                    ? 'يوجد $pendingCount سجل بانتظار المزامنة'
                    : 'جميع البيانات متزامنة سحابياً',
                onPressed: () async {
                  final synced = await SyncService.instance.syncAllPendingData();
                  await SyncService.instance.pullUserDataFromCloud(widget.teacherUser);
                  await _loadStudents();
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          synced
                              ? 'تمت المزامنة السحابية والنسخ الاحتياطي بنجاح'
                              : 'تم الحفظ محلياً (سيتم الرفع تلقائياً عند توفر الإنترنت)',
                        ),
                      ),
                    );
                  }
                },
                icon: Badge(
                  isLabelVisible: pendingCount > 0,
                  label: Text('$pendingCount'),
                  child: Icon(
                    pendingCount > 0
                        ? Icons.cloud_upload_outlined
                        : Icons.cloud_done_rounded,
                  ),
                ),
              );
            },
          ),
          IconButton(
            tooltip: 'حفظ نسخة احتياطية JSON في الهاتف',
            icon: const Icon(Icons.download_for_offline_outlined),
            onPressed: () async {
              final path = await DatabaseHelper.instance.exportDailyJsonBackup();
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('تم حفظ النسخة الاحتياطية اليومية في:\n$path')),
                );
              }
            },
          ),
          IconButton(
            tooltip: 'تسجيل الخروج',
            icon: const Icon(Icons.logout_rounded),
            onPressed: _logout,
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppConstants.goldAccent,
        foregroundColor: AppConstants.darkEmerald,
        onPressed: _showAddStudentDialog,
        icon: const Icon(Icons.person_add_alt_1_rounded),
        label: const Text(
          'إضافة طالب جديد',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: AppConstants.emeraldBackgroundGradient,
        ),
        child: Column(
          children: [
            // شريط ملخص اليوم بـ 4 حالات كاملة
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: const BoxDecoration(
                color: Color(0xE6052E1C),
                border: Border(bottom: BorderSide(color: AppConstants.goldAccent, width: 1)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          const Icon(
                            Icons.calendar_today_rounded,
                            size: 16,
                            color: AppConstants.goldAccent,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'اليوم: $_todayDate',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: AppConstants.goldAccent,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                      Text(
                        'إجمالي الطلاب: ${_students.length}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: [
                      _miniChip('حاضر (سمّع): $recitedToday', const Color(0xFF2ECC71)),
                      _miniChip('حضر ولم يسمّع: $noReciteToday', const Color(0xFFF39C12)),
                      _miniChip('غائب: $absentToday', const Color(0xFFFF6B6B)),
                      _miniChip('مستأذن: $excusedToday', AppConstants.goldAccent),
                    ],
                  ),
                ],
              ),
            ),
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _students.isEmpty
                      ? Center(
                          child: Padding(
                            padding: const EdgeInsets.all(24.0),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.menu_book_rounded,
                                  size: 68,
                                  color: AppConstants.goldAccent.withOpacity(0.55),
                                ),
                                const SizedBox(height: 14),
                                const Text(
                                  'لا يوجد طلاب في الحلقة حالياً.\nاضغط على زر "إضافة طالب جديد" لبدء تسجيل التسميع اليومي.',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: 15.5,
                                    color: Colors.white70,
                                    height: 1.5,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        )
                      : RefreshIndicator(
                          onRefresh: _loadStudents,
                          child: ListView.builder(
                            padding: const EdgeInsets.fromLTRB(16, 16, 16, 85),
                            itemCount: _students.length,
                            itemBuilder: (ctx, i) {
                              final student = _students[i];
                              final todayLog = _todayLogs[student.id];
                              final statusStr = todayLog?.status ?? 'none';
                              final statusLabel = AppConstants.statusLabelAr(statusStr);
                              final statusColor = AppConstants.statusColor(statusStr);

                              return Card(
                                margin: const EdgeInsets.only(bottom: 12),
                                elevation: 4,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                  side: const BorderSide(color: AppConstants.goldAccent, width: 0.9),
                                ),
                                child: InkWell(
                                  borderRadius: BorderRadius.circular(16),
                                  onTap: () async {
                                    await Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => StudentDetailScreen(
                                          student: student,
                                          teacher: widget.teacherUser,
                                        ),
                                      ),
                                    );
                                    await _loadStudents();
                                  },
                                  child: Padding(
                                    padding: const EdgeInsets.all(14.0),
                                    child: Row(
                                      children: [
                                        CircleAvatar(
                                          radius: 24,
                                          backgroundColor: AppConstants.goldAccent.withOpacity(0.2),
                                          child: Text(
                                            student.name.isNotEmpty ? student.name.characters.first : 'ط',
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 18,
                                              color: AppConstants.goldAccent,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 14),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                student.name,
                                                style: const TextStyle(
                                                  fontSize: 17,
                                                  fontWeight: FontWeight.bold,
                                                  color: Colors.white,
                                                ),
                                              ),
                                              const SizedBox(height: 5),
                                              Row(
                                                children: [
                                                  const Icon(
                                                    Icons.bookmark_rounded,
                                                    size: 15,
                                                    color: AppConstants.goldAccent,
                                                  ),
                                                  const SizedBox(width: 4),
                                                  Expanded(
                                                    child: Text(
                                                      'آخر موضع: سورة ${student.lastSurahName} | آية ${student.lastAyah} | ص ${student.lastPage}',
                                                      style: const TextStyle(
                                                        fontSize: 12.5,
                                                        color: Colors.white70,
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ],
                                          ),
                                        ),
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 10,
                                            vertical: 6,
                                          ),
                                          decoration: BoxDecoration(
                                            color: statusColor.withOpacity(0.18),
                                            borderRadius: BorderRadius.circular(20),
                                            border: Border.all(
                                              color: statusColor,
                                              width: 1,
                                            ),
                                          ),
                                          child: Text(
                                            statusLabel,
                                            style: TextStyle(
                                              fontSize: 11.5,
                                              fontWeight: FontWeight.bold,
                                              color: statusColor,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _miniChip(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.18),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.7)),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 11.5,
          fontWeight: FontWeight.bold,
          color: color,
        ),
      ),
    );
  }
}
