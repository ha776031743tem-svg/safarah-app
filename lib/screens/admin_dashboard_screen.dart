import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import '../services/pdf_service.dart';
import '../core/constants.dart';
import '../models/user_model.dart';
import '../models/student_model.dart';
import '../models/daily_log_model.dart';
import '../services/database_helper.dart';
import '../services/sync_service.dart';
import 'role_selection_screen.dart';

class AdminDashboardScreen extends StatefulWidget {
  final UserModel adminUser;

  const AdminDashboardScreen({super.key, required this.adminUser});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  List<UserModel> _teachers = [];
  List<StudentModel> _students = [];
  List<DailyLogModel> _logs = [];
  bool _isLoading = true;

  // الفترة الزمنية للإحصائيات والتقارير (افتراضياً آخر 30 يوماً)
  DateTime _rangeStart = DateTime.now().subtract(const Duration(days: 29));
  DateTime _rangeEnd = DateTime.now();
  int _selectedPresetDays = 30; // 7, 30, 90, or 0 for custom

  @override
  void initState() {
    super.initState();
    _loadDashboardData();
  }

  Future<void> _loadDashboardData() async {
    setState(() => _isLoading = true);
    await SyncService.instance.pullUserDataFromCloud(widget.adminUser);
    final db = DatabaseHelper.instance;
    final teachers = await db.getTeachersByAdmin(widget.adminUser.id);
    final students = await db.getStudentsByAdmin(widget.adminUser.id);
    final logs = await db.getLogsByAdmin(widget.adminUser.id);

    if (mounted) {
      setState(() {
        _teachers = teachers;
        _students = students;
        _logs = logs;
        _isLoading = false;
      });
    }
  }

  Future<void> _showCreateTeacherDialog() async {
    final nameCtrl = TextEditingController();
    final halqaCtrl = TextEditingController();
    final userCtrl = TextEditingController();
    final passCtrl = TextEditingController();
    final formKey = GlobalKey<FormState>();

    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('إضافة معلم حلقة جديد'),
        content: SingleChildScrollView(
          child: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: nameCtrl,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(
                    labelText: 'اسم المعلم الكامل',
                    prefixIcon: Icon(Icons.person),
                  ),
                  validator: (v) => v == null || v.trim().isEmpty ? 'مطلوب' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: halqaCtrl,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(
                    labelText: 'اسم الحلقة القرآنية',
                    prefixIcon: Icon(Icons.groups),
                  ),
                  validator: (v) => v == null || v.trim().isEmpty ? 'مطلوب' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: userCtrl,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(
                    labelText: 'اسم المستخدم للدخول (Username)',
                    prefixIcon: Icon(Icons.account_circle_outlined),
                  ),
                  validator: (v) => v == null || v.trim().isEmpty ? 'مطلوب' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: passCtrl,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(
                    labelText: 'كلمة المرور (Password)',
                    prefixIcon: Icon(Icons.lock_outline),
                  ),
                  validator: (v) => v == null || v.trim().isEmpty ? 'مطلوب' : null,
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

              final existing = await DatabaseHelper.instance
                  .getUserByUsername(userCtrl.text.trim());
              if (existing != null) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('اسم المستخدم مستخدم مسبقاً')),
                  );
                }
                return;
              }

              final newTeacher = UserModel(
                id: 'tch_${DateTime.now().millisecondsSinceEpoch}',
                username: userCtrl.text.trim(),
                password: passCtrl.text.trim(),
                fullName: nameCtrl.text.trim(),
                role: AppConstants.roleManagedTeacher,
                halqaName: halqaCtrl.text.trim(),
                adminId: widget.adminUser.id,
                createdAt: DateTime.now().toIso8601String(),
                isSynced: 0,
              );

              await DatabaseHelper.instance.upsertUser(newTeacher);
              await SyncService.instance.pushUserImmediately(newTeacher);
              await SyncService.instance.syncAllPendingData();
              if (ctx.mounted) Navigator.pop(ctx);
              await _loadDashboardData();
            },
            child: const Text('حفظ وإنشاء الحساب'),
          ),
        ],
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

  /// حساب إحصائيات الطالب خلال الفترة المحددة بدقة
  Map<String, int> _calculateStudentStats(String studentId) {
    int memPages = 0;
    int revPages = 0;
    int presentDays = 0;
    int absentDays = 0;
    int noReciteDays = 0;
    int excusedDays = 0;

    final startStr = DateFormat('yyyy-MM-dd').format(_rangeStart);
    final endStr = DateFormat('yyyy-MM-dd').format(_rangeEnd);

    for (final log in _logs) {
      if (log.studentId != studentId) continue;
      if (log.logDate.compareTo(startStr) < 0 || log.logDate.compareTo(endStr) > 0) {
        continue;
      }

      if (log.status == AppConstants.statusRecited) {
        presentDays++;
        memPages += log.memPagesCount;
        revPages += log.revPagesCount;
      } else if (log.status == AppConstants.statusAttendedNoRecitation) {
        presentDays++;
        noReciteDays++;
      } else if (log.status == AppConstants.statusAbsent) {
        absentDays++;
      } else if (log.status == AppConstants.statusExcused) {
        excusedDays++;
      }
    }

    return {
      'memPages': memPages,
      'revPages': revPages,
      'presentDays': presentDays,
      'absentDays': absentDays,
      'noReciteDays': noReciteDays,
      'excusedDays': excusedDays,
    };
  }

  Future<void> _pickCustomRange() async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      initialDateRange: DateTimeRange(start: _rangeStart, end: _rangeEnd),
      helpText: 'اختر فترة الإحصائيات والتقارير',
      saveText: 'اعتماد الفترة',
    );
    if (picked != null && mounted) {
      setState(() {
        _selectedPresetDays = 0;
        _rangeStart = picked.start;
        _rangeEnd = picked.end;
      });
    }
  }

  void _applyPresetRange(int days) {
    final now = DateTime.now();
    setState(() {
      _selectedPresetDays = days;
      _rangeEnd = DateTime(now.year, now.month, now.day);
      _rangeStart = _rangeEnd.subtract(Duration(days: days - 1));
    });
  }

  Future<void> _exportCircleReport(UserModel teacher, {required bool share}) async {
    try {
      final circleStudents =
          _students.where((s) => s.teacherId == teacher.id).toList();
      final start = DateFormat('yyyy-MM-dd').format(_rangeStart);
      final end = DateFormat('yyyy-MM-dd').format(_rangeEnd);
      final circleIds = circleStudents.map((s) => s.id).toSet();
      final circleLogs = _logs
          .where((l) =>
              circleIds.contains(l.studentId) &&
              l.logDate.compareTo(start) >= 0 &&
              l.logDate.compareTo(end) <= 0)
          .toList();

      final file = await PdfService.generateCircleInstitutionalReport(
        teacher: teacher,
        students: circleStudents,
        logs: circleLogs,
        startDate: start,
        endDate: end,
        organizationName: widget.adminUser.halqaName.isNotEmpty
            ? widget.adminUser.halqaName
            : 'مركز سَفَرَة لتحفيظ القرآن الكريم',
      );

      if (share) {
        await PdfService.shareInstitutionalReport(file, teacher.halqaName);
      } else {
        await PdfService.previewAndPrintPdf(file);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('تعذر إنشاء التقرير المؤسسي: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final startStr = DateFormat('yyyy-MM-dd').format(_rangeStart);
    final endStr = DateFormat('yyyy-MM-dd').format(_rangeEnd);

    final filteredLogs = _logs.where((l) =>
        l.logDate.compareTo(startStr) >= 0 && l.logDate.compareTo(endStr) <= 0).toList();

    final presentCount = filteredLogs
        .where((l) =>
            l.status == AppConstants.statusRecited ||
            l.status == AppConstants.statusAttendedNoRecitation)
        .length;
    final eligibleAttendance = filteredLogs
        .where((l) => l.status != AppConstants.statusExcused)
        .length;
    final attendanceRate = eligibleAttendance == 0
        ? 0
        : (presentCount * 100 / eligibleAttendance).round();
    final recitationActivity = filteredLogs
        .where((l) => l.status == AppConstants.statusRecited)
        .length;

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: Column(
          children: [
            Text('لوحة إدارة: ${widget.adminUser.halqaName}'),
            Text(
              'المدير: ${widget.adminUser.fullName}',
              style: const TextStyle(fontSize: 12, color: AppConstants.lightGold),
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'مزامنة وتحديث البيانات',
            icon: const Icon(Icons.sync_rounded),
            onPressed: () async {
              await SyncService.instance.syncAllPendingData();
              await _loadDashboardData();
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('تمت المزامنة وتحديث الإحصائيات')),
                );
              }
            },
          ),
          IconButton(
            tooltip: 'نسخة احتياطية JSON',
            icon: const Icon(Icons.save_alt_rounded),
            onPressed: () async {
              final path = await DatabaseHelper.instance.exportDailyJsonBackup();
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('تم حفظ النسخة الاحتياطية في:\n$path')),
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
        onPressed: _showCreateTeacherDialog,
        icon: const Icon(Icons.person_add_alt_1_rounded),
        label: const Text(
          'إضافة معلم حلقة',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: AppConstants.emeraldBackgroundGradient,
        ),
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : Column(
                children: [
                  // شريط المؤشرات التشغيلية للمركز (بدون عدادات صفحات الحفظ والمراجعة في الأعلى)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                    decoration: const BoxDecoration(
                      color: Color(0xE6052E1C),
                      border: Border(
                        bottom: BorderSide(color: AppConstants.goldAccent, width: 1.2),
                      ),
                    ),
                    child: Wrap(
                      alignment: WrapAlignment.spaceAround,
                      spacing: 14,
                      runSpacing: 10,
                      children: [
                        _buildTopStat(
                          'الحلقات والمعلمون',
                          '${_teachers.length}',
                          Icons.mosque_rounded,
                        ),
                        _buildTopStat(
                          'إجمالي الطلاب',
                          '${_students.length}',
                          Icons.school_rounded,
                        ),
                        _buildTopStat(
                          'معدل الحضور',
                          '$attendanceRate%',
                          Icons.fact_check_rounded,
                        ),
                        _buildTopStat(
                          'عمليات التسميع',
                          '$recitationActivity',
                          Icons.menu_book_rounded,
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: RefreshIndicator(
                      onRefresh: _loadDashboardData,
                      child: ListView(
                        padding: const EdgeInsets.fromLTRB(16, 14, 16, 90),
                        children: [
                          _buildDateFilterCard(),
                          const SizedBox(height: 14),
                          const Row(
                            children: [
                              Icon(Icons.account_tree_rounded, color: AppConstants.goldAccent, size: 20),
                              SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'الحلقات والمعلمون (اضغط على المعلم لعرض طلابه، وعلى الطالب لعرض إحصائياته):',
                                  style: TextStyle(
                                    color: AppConstants.lightGold,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13.5,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          if (_teachers.isEmpty)
                            Container(
                              padding: const EdgeInsets.all(28),
                              decoration: BoxDecoration(
                                color: const Color(0xFF073B24),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: AppConstants.goldAccent.withOpacity(0.5)),
                              ),
                              child: const Column(
                                children: [
                                  Icon(Icons.groups_rounded, size: 56, color: AppConstants.goldAccent),
                                  SizedBox(height: 12),
                                  Text(
                                    'لا يوجد معلمون مسجلون في المركز حتى الآن.\nاضغط على زر "إضافة معلم حلقة" بالأسفل لإنشاء أول حلقة.',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(color: Colors.white70, height: 1.5),
                                  ),
                                ],
                              ),
                            )
                          else
                            ..._teachers.map(_buildTeacherDrillDownCard),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildTopStat(String label, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF0A462C),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppConstants.goldAccent.withOpacity(0.55)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: AppConstants.goldAccent, size: 22),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 18,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(
              fontSize: 11.5,
              color: AppConstants.lightGold,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDateFilterCard() {
    final fmt = DateFormat('yyyy-MM-dd');
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: AppConstants.goldAccent, width: 1.1),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Row(
                  children: [
                    Icon(Icons.date_range_rounded, color: AppConstants.goldAccent, size: 20),
                    SizedBox(width: 8),
                    Text(
                      'تحديد فترة الإحصائيات والتقارير:',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 14.5,
                      ),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppConstants.darkEmerald,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppConstants.goldAccent.withOpacity(0.6)),
                  ),
                  child: Text(
                    '${fmt.format(_rangeStart)}  ⬅  ${fmt.format(_rangeEnd)}',
                    style: const TextStyle(
                      color: AppConstants.goldAccent,
                      fontSize: 11.5,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                ChoiceChip(
                  label: const Text('آخر 7 أيام'),
                  selected: _selectedPresetDays == 7,
                  onSelected: (_) => _applyPresetRange(7),
                ),
                ChoiceChip(
                  label: const Text('آخر 30 يوماً'),
                  selected: _selectedPresetDays == 30,
                  onSelected: (_) => _applyPresetRange(30),
                ),
                ChoiceChip(
                  label: const Text('آخر 3 أشهر'),
                  selected: _selectedPresetDays == 90,
                  onSelected: (_) => _applyPresetRange(90),
                ),
                ActionChip(
                  backgroundColor: _selectedPresetDays == 0
                      ? AppConstants.goldAccent
                      : const Color(0xFF063521),
                  avatar: Icon(
                    Icons.calendar_month_rounded,
                    size: 17,
                    color: _selectedPresetDays == 0
                        ? AppConstants.darkEmerald
                        : AppConstants.goldAccent,
                  ),
                  label: Text(
                    'فترة مخصصة (من - إلى)',
                    style: TextStyle(
                      color: _selectedPresetDays == 0
                          ? AppConstants.darkEmerald
                          : Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  onPressed: _pickCustomRange,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// بطاقة المعلم (المستوى الأول): عند الضغط عليها يظهر طلابه + زر تقرير المنظمة للحلقة
  Widget _buildTeacherDrillDownCard(UserModel teacher) {
    final teacherStudents =
        _students.where((st) => st.teacherId == teacher.id).toList();

    return Card(
      margin: const EdgeInsets.only(bottom: 14),
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: AppConstants.goldAccent, width: 1.1),
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          iconColor: AppConstants.goldAccent,
          collapsedIconColor: AppConstants.goldAccent,
          leading: Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppConstants.goldAccent.withOpacity(0.18),
              shape: BoxShape.circle,
              border: Border.all(color: AppConstants.goldAccent),
            ),
            child: const Icon(
              Icons.mosque_rounded,
              color: AppConstants.goldAccent,
              size: 22,
            ),
          ),
          title: Text(
            'المعلم: ${teacher.fullName}',
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 16.5,
            ),
          ),
          subtitle: Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              'الحلقة: ${teacher.halqaName}  |  الطلاب: ${teacherStudents.length}  |  المستخدم: ${teacher.username}',
              style: const TextStyle(
                color: AppConstants.lightGold,
                fontSize: 12.5,
              ),
            ),
          ),
          childrenPadding: const EdgeInsets.fromLTRB(12, 0, 12, 14),
          children: [
            const Divider(color: AppConstants.goldAccent, height: 16),
            // أزرار تصدير ومشاركة التقرير المؤسسي للحلقة لتسليمه للمنظمة
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFF063521),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppConstants.goldAccent.withOpacity(0.6)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.workspace_premium_rounded,
                      color: AppConstants.goldAccent, size: 22),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      'تقرير الحلقة الرسمي للمنظمة / الإدارة:',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                  ),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      textStyle: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold),
                    ),
                    icon: const Icon(Icons.picture_as_pdf_rounded, size: 17),
                    label: const Text('معاينة PDF'),
                    onPressed: () => _exportCircleReport(teacher, share: false),
                  ),
                  const SizedBox(width: 8),
                  OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                      textStyle: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold),
                    ),
                    icon: const Icon(Icons.share_rounded, size: 17),
                    label: const Text('مشاركة'),
                    onPressed: () => _exportCircleReport(teacher, share: true),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            if (teacherStudents.isEmpty)
              const Padding(
                padding: EdgeInsets.all(16.0),
                child: Text(
                  'لا يوجد طلاب مسجلون لدى هذا المعلم حتى الآن.',
                  style: TextStyle(color: Colors.white70),
                ),
              )
            else
              ...teacherStudents.map(_buildStudentDrillDownCard),
          ],
        ),
      ),
    );
  }

  /// بطاقة الطالب (المستوى الثاني): عند الضغط على الطالب تظهر إحصائياته الـ 6 كاملة للفترة المحددة
  Widget _buildStudentDrillDownCard(StudentModel student) {
    final stats = _calculateStudentStats(student.id);

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      color: const Color(0xFF063521),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: AppConstants.goldAccent.withOpacity(0.65), width: 0.9),
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          iconColor: AppConstants.goldAccent,
          collapsedIconColor: Colors.white70,
          leading: CircleAvatar(
            radius: 18,
            backgroundColor: AppConstants.goldAccent.withOpacity(0.2),
            child: Text(
              student.name.isNotEmpty ? student.name.characters.first : 'ط',
              style: const TextStyle(
                color: AppConstants.goldAccent,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          title: Text(
            student.name,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 15,
            ),
          ),
          subtitle: Text(
            'آخر موضع: سورة ${student.lastSurahName} (آية ${student.lastAyah} - ص ${student.lastPage})',
            style: const TextStyle(color: Colors.white70, fontSize: 12),
          ),
          childrenPadding: const EdgeInsets.fromLTRB(12, 4, 12, 14),
          children: [
            const Divider(color: Colors.white24, height: 12),
            GridView.count(
              crossAxisCount: 3,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 8,
              crossAxisSpacing: 8,
              childAspectRatio: 1.35,
              children: [
                _buildStatTile(
                  'صفحات الحفظ',
                  '${stats['memPages']}',
                  Icons.menu_book_rounded,
                  const Color(0xFF2ECC71),
                ),
                _buildStatTile(
                  'صفحات المراجعة',
                  '${stats['revPages']}',
                  Icons.autorenew_rounded,
                  const Color(0xFF3498DB),
                ),
                _buildStatTile(
                  'أيام الحضور',
                  '${stats['presentDays']}',
                  Icons.check_circle_outline_rounded,
                  const Color(0xFF2ECC71),
                ),
                _buildStatTile(
                  'أيام الغياب',
                  '${stats['absentDays']}',
                  Icons.cancel_outlined,
                  const Color(0xFFFF6B6B),
                ),
                _buildStatTile(
                  'حضر ولم يسمّع',
                  '${stats['noReciteDays']}',
                  Icons.person_off_outlined,
                  const Color(0xFFF39C12),
                ),
                _buildStatTile(
                  'أيام الاستئذان',
                  '${stats['excusedDays']}',
                  Icons.event_busy_rounded,
                  AppConstants.goldAccent,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatTile(String label, String value, IconData icon, Color accentColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFF0A462C),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: accentColor.withOpacity(0.75), width: 1),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: accentColor, size: 15),
              const SizedBox(width: 4),
              Text(
                value,
                style: TextStyle(
                  color: accentColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 17,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              label,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
