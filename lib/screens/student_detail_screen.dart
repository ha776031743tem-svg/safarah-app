import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../core/constants.dart';
import '../core/quran_metadata.dart';
import '../models/student_model.dart';
import '../models/user_model.dart';
import '../models/daily_log_model.dart';
import '../services/database_helper.dart';
import '../services/sync_service.dart';
import '../services/pdf_service.dart';

class StudentDetailScreen extends StatefulWidget {
  final StudentModel student;
  final UserModel teacher;

  const StudentDetailScreen({
    super.key,
    required this.student,
    required this.teacher,
  });

  @override
  State<StudentDetailScreen> createState() => _StudentDetailScreenState();
}

class _StudentDetailScreenState extends State<StudentDetailScreen> {
  late StudentModel _student;
  late String _todayDate;
  List<DailyLogModel> _historyLogs = [];
  bool _isLoading = true;
  bool _isSaving = false;

  // حقول بطاقة الحفظ (Memorization)
  late int _memSurahNum;
  final _memFromAyahCtrl = TextEditingController();
  final _memToAyahCtrl = TextEditingController();
  final _memFromPageCtrl = TextEditingController();
  final _memToPageCtrl = TextEditingController();

  // حقول بطاقة المراجعة (Revision)
  late int _revSurahNum;
  final _revFromAyahCtrl = TextEditingController();
  final _revToAyahCtrl = TextEditingController();
  final _revFromPageCtrl = TextEditingController();
  final _revToPageCtrl = TextEditingController();

  final _notesCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _student = widget.student;
    _todayDate = DateFormat('yyyy-MM-dd').format(DateTime.now());
    _memSurahNum = _student.lastSurahNumber;
    _revSurahNum = _student.lastSurahNumber;
    _initializeSmartFieldsAndLoadHistory();
  }

  @override
  void dispose() {
    _memFromAyahCtrl.dispose();
    _memToAyahCtrl.dispose();
    _memFromPageCtrl.dispose();
    _memToPageCtrl.dispose();
    _revFromAyahCtrl.dispose();
    _revToAyahCtrl.dispose();
    _revFromPageCtrl.dispose();
    _revToPageCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  /// تحديث صفحات الحفظ تلقائياً عند تغيير رقم الآية (من آية / إلى آية)
  void _syncMemPagesFromAyahs() {
    final s = QuranMetadata.getByNumber(_memSurahNum);
    final fromAyah = int.tryParse(_memFromAyahCtrl.text.trim()) ?? 1;
    final toAyah = int.tryParse(_memToAyahCtrl.text.trim()) ?? s.ayahCount;
    final pages = QuranMetadata.getPageRangeForAyahs(
      surahNumber: _memSurahNum,
      fromAyah: fromAyah,
      toAyah: toAyah,
    );
    _memFromPageCtrl.text = pages['fromPage'].toString();
    _memToPageCtrl.text = pages['toPage'].toString();
  }

  /// تحديث صفحات المراجعة تلقائياً عند تغيير رقم الآية (من آية / إلى آية)
  void _syncRevPagesFromAyahs() {
    final s = QuranMetadata.getByNumber(_revSurahNum);
    final fromAyah = int.tryParse(_revFromAyahCtrl.text.trim()) ?? 1;
    final toAyah = int.tryParse(_revToAyahCtrl.text.trim()) ?? s.ayahCount;
    final pages = QuranMetadata.getPageRangeForAyahs(
      surahNumber: _revSurahNum,
      fromAyah: fromAyah,
      toAyah: toAyah,
    );
    _revFromPageCtrl.text = pages['fromPage'].toString();
    _revToPageCtrl.text = pages['toPage'].toString();
  }

  Future<void> _initializeSmartFieldsAndLoadHistory() async {
    setState(() => _isLoading = true);
    final db = DatabaseHelper.instance;

    final refreshedStudent = await db.getStudentById(_student.id);
    if (refreshedStudent != null) {
      _student = refreshedStudent;
    }

    final logs = await db.getLogsByStudent(_student.id);
    final todayExistingLog = await db.getStudentLogByDate(_student.id, _todayDate);

    if (todayExistingLog != null &&
        todayExistingLog.status == AppConstants.statusRecited) {
      _memSurahNum = todayExistingLog.memSurahNumber ?? _student.lastSurahNumber;
      final memFromA = todayExistingLog.memFromAyah ?? 1;
      final memToA = todayExistingLog.memToAyah ?? 10;
      _memFromAyahCtrl.text = memFromA.toString();
      _memToAyahCtrl.text = memToA.toString();
      final memPages = QuranMetadata.getPageRangeForAyahs(
        surahNumber: _memSurahNum,
        fromAyah: memFromA,
        toAyah: memToA,
      );
      _memFromPageCtrl.text = (todayExistingLog.memFromPage ?? memPages['fromPage']!).toString();
      _memToPageCtrl.text = (todayExistingLog.memToPage ?? memPages['toPage']!).toString();

      _revSurahNum = todayExistingLog.revSurahNumber ?? _student.lastSurahNumber;
      final revFromA = todayExistingLog.revFromAyah ?? 1;
      final revToA = todayExistingLog.revToAyah ?? 20;
      _revFromAyahCtrl.text = revFromA.toString();
      _revToAyahCtrl.text = revToA.toString();
      final revPages = QuranMetadata.getPageRangeForAyahs(
        surahNumber: _revSurahNum,
        fromAyah: revFromA,
        toAyah: revToA,
      );
      _revFromPageCtrl.text = (todayExistingLog.revFromPage ?? revPages['fromPage']!).toString();
      _revToPageCtrl.text = (todayExistingLog.revToPage ?? revPages['toPage']!).toString();
      _notesCtrl.text = todayExistingLog.notes;
    } else {
      final nextPos = QuranMetadata.getNextPosition(
        lastSurahNumber: _student.lastSurahNumber,
        lastAyah: _student.lastAyah,
        lastPage: _student.lastPage,
      );

      _memSurahNum = nextPos['surahNumber'] as int;
      _memFromAyahCtrl.text = nextPos['fromAyah'].toString();
      _memToAyahCtrl.text = nextPos['toAyah'].toString();
      _memFromPageCtrl.text = nextPos['fromPage'].toString();
      _memToPageCtrl.text = nextPos['toPage'].toString();

      final revSurah = QuranMetadata.getByNumber(_student.lastSurahNumber);
      _revSurahNum = revSurah.number;
      _revFromAyahCtrl.text = '1';
      _revToAyahCtrl.text = _student.lastAyah.toString();
      final revPages = QuranMetadata.getPageRangeForAyahs(
        surahNumber: revSurah.number,
        fromAyah: 1,
        toAyah: _student.lastAyah,
      );
      _revFromPageCtrl.text = revPages['fromPage'].toString();
      _revToPageCtrl.text = revPages['toPage'].toString();
    }

    if (mounted) {
      setState(() {
        _historyLogs = logs;
        _isLoading = false;
      });
    }
  }

  /// تسجيل سريع لحالات (حضر ولم يُسمّع / غائب / مستأذن)
  Future<void> _recordQuickStatus(String status) async {
    setState(() => _isSaving = true);
    try {
      final db = DatabaseHelper.instance;
      final existingToday = await db.getStudentLogByDate(_student.id, _todayDate);

      final log = DailyLogModel(
        id: existingToday?.id ?? 'log_${_student.id}_$_todayDate',
        studentId: _student.id,
        teacherId: widget.teacher.id,
        adminId: widget.teacher.adminId,
        logDate: _todayDate,
        status: status,
        notes: _notesCtrl.text.trim(),
        createdAt: DateTime.now().toIso8601String(),
        isSynced: 0,
      );

      await db.upsertDailyLog(log);
      await SyncService.instance.syncAllPendingData();
      await _initializeSmartFieldsAndLoadHistory();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: AppConstants.surfaceEmerald,
            content: Text(
              'تم تسجيل حالة الطالب اليوم: ${AppConstants.statusLabelAr(status)}',
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            ),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  /// حفظ بطاقتي الحفظ والمراجعة لليوم
  Future<void> _saveRecitationLog() async {
    setState(() => _isSaving = true);
    try {
      final db = DatabaseHelper.instance;
      final existingToday = await db.getStudentLogByDate(_student.id, _todayDate);

      final memSurah = QuranMetadata.getByNumber(_memSurahNum);
      final revSurah = QuranMetadata.getByNumber(_revSurahNum);

      final memFromAyah = (int.tryParse(_memFromAyahCtrl.text.trim()) ?? 1).clamp(1, memSurah.ayahCount);
      final memToAyah = (int.tryParse(_memToAyahCtrl.text.trim()) ?? memSurah.ayahCount).clamp(memFromAyah, memSurah.ayahCount);
      final exactMemPages = QuranMetadata.getPageRangeForAyahs(
        surahNumber: memSurah.number,
        fromAyah: memFromAyah,
        toAyah: memToAyah,
      );
      final memFromPage = int.tryParse(_memFromPageCtrl.text.trim()) ?? exactMemPages['fromPage']!;
      final memToPage = int.tryParse(_memToPageCtrl.text.trim()) ?? exactMemPages['toPage']!;

      final revFromAyah = (int.tryParse(_revFromAyahCtrl.text.trim()) ?? 1).clamp(1, revSurah.ayahCount);
      final revToAyah = (int.tryParse(_revToAyahCtrl.text.trim()) ?? revSurah.ayahCount).clamp(revFromAyah, revSurah.ayahCount);
      final exactRevPages = QuranMetadata.getPageRangeForAyahs(
        surahNumber: revSurah.number,
        fromAyah: revFromAyah,
        toAyah: revToAyah,
      );
      final revFromPage = int.tryParse(_revFromPageCtrl.text.trim()) ?? exactRevPages['fromPage']!;
      final revToPage = int.tryParse(_revToPageCtrl.text.trim()) ?? exactRevPages['toPage']!;

      final log = DailyLogModel(
        id: existingToday?.id ?? 'log_${_student.id}_$_todayDate',
        studentId: _student.id,
        teacherId: widget.teacher.id,
        adminId: widget.teacher.adminId,
        logDate: _todayDate,
        status: AppConstants.statusRecited,
        memSurahNumber: memSurah.number,
        memSurahName: memSurah.name,
        memFromAyah: memFromAyah,
        memToAyah: memToAyah,
        memFromPage: memFromPage,
        memToPage: memToPage,
        revSurahNumber: revSurah.number,
        revSurahName: revSurah.name,
        revFromAyah: revFromAyah,
        revToAyah: revToAyah,
        revFromPage: revFromPage,
        revToPage: revToPage,
        notes: _notesCtrl.text.trim(),
        createdAt: DateTime.now().toIso8601String(),
        isSynced: 0,
      );

      await db.upsertDailyLog(log);
      await SyncService.instance.syncAllPendingData();
      await _initializeSmartFieldsAndLoadHistory();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            backgroundColor: AppConstants.secondaryColor,
            content: Text(
              'تم حفظ التسميع وتحديث آخر موضع وصفحة للطالب بنجاح',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            ),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  /// نافذة تصدير ومشاركة تقرير PDF لولي الأمر
  Future<void> _showExportPdfModal() async {
    int selectedRangeOption = 7;
    DateTime customStart = DateTime.now().subtract(const Duration(days: 7));
    DateTime customEnd = DateTime.now();
    final parentNoteCtrl = TextEditingController(
      text: 'بارك الله في الطالب ${_student.name} وزاده حرصاً وتوفيقاً لحفظ كتاب الله.',
    );
    bool isGeneratingPdf = false;

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppConstants.surfaceEmerald,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        side: BorderSide(color: AppConstants.goldAccent, width: 1.2),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) {
          String getFormattedDate(DateTime dt) => DateFormat('yyyy-MM-dd').format(dt);

          Future<void> handleExport({required bool shareViaWhatsapp}) async {
            setModalState(() => isGeneratingPdf = true);
            try {
              DateTime startDt;
              DateTime endDt = DateTime.now();
              if (selectedRangeOption == 0) {
                startDt = customStart;
                endDt = customEnd;
              } else {
                startDt = DateTime.now().subtract(Duration(days: selectedRangeOption - 1));
              }

              final startStr = getFormattedDate(startDt);
              final endStr = getFormattedDate(endDt);

              final logsInPeriod = await DatabaseHelper.instance
                  .getLogsByStudentInDateRange(_student.id, startStr, endStr);

              final pdfFile = await PdfService.generateParentReport(
                student: _student,
                teacher: widget.teacher,
                logs: logsInPeriod,
                startDate: startStr,
                endDate: endStr,
                parentNote: parentNoteCtrl.text,
              );

              if (ctx.mounted) Navigator.pop(ctx);

              if (shareViaWhatsapp) {
                await PdfService.sharePdfReport(pdfFile, _student);
              } else {
                await PdfService.previewAndPrintPdf(pdfFile);
              }
            } catch (e) {
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('تعذر توليد ملف الـ PDF: $e')),
                );
              }
            } finally {
              if (ctx.mounted) setModalState(() => isGeneratingPdf = false);
            }
          }

          return Padding(
            padding: EdgeInsets.only(
              left: 20,
              right: 20,
              top: 20,
              bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.picture_as_pdf_rounded, color: AppConstants.goldAccent),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'تصدير تقرير PDF لولي أمر (${_student.name})',
                          style: const TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const Divider(height: 24, color: AppConstants.goldAccent),
                  const Text(
                    'حدد الفترة الزمنية للتقرير:',
                    style: TextStyle(fontWeight: FontWeight.bold, color: AppConstants.lightGold),
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      ChoiceChip(
                        label: const Text('آخر 7 أيام'),
                        selected: selectedRangeOption == 7,
                        onSelected: (_) => setModalState(() => selectedRangeOption = 7),
                      ),
                      ChoiceChip(
                        label: const Text('آخر 10 أيام'),
                        selected: selectedRangeOption == 10,
                        onSelected: (_) => setModalState(() => selectedRangeOption = 10),
                      ),
                      ChoiceChip(
                        label: const Text('آخر 30 يوماً'),
                        selected: selectedRangeOption == 30,
                        onSelected: (_) => setModalState(() => selectedRangeOption = 30),
                      ),
                      ChoiceChip(
                        label: const Text('تاريخ مخصص (من - إلى)'),
                        selected: selectedRangeOption == 0,
                        onSelected: (_) => setModalState(() => selectedRangeOption = 0),
                      ),
                    ],
                  ),
                  if (selectedRangeOption == 0) ...[
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            icon: const Icon(Icons.date_range, size: 18),
                            label: Text('من: ${getFormattedDate(customStart)}'),
                            onPressed: () async {
                              final picked = await showDatePicker(
                                context: ctx,
                                initialDate: customStart,
                                firstDate: DateTime(2020),
                                lastDate: DateTime.now(),
                              );
                              if (picked != null) {
                                setModalState(() => customStart = picked);
                              }
                            },
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: OutlinedButton.icon(
                            icon: const Icon(Icons.date_range, size: 18),
                            label: Text('إلى: ${getFormattedDate(customEnd)}'),
                            onPressed: () async {
                              final picked = await showDatePicker(
                                context: ctx,
                                initialDate: customEnd,
                                firstDate: DateTime(2020),
                                lastDate: DateTime.now(),
                              );
                              if (picked != null) {
                                setModalState(() => customEnd = picked);
                              }
                            },
                          ),
                        ),
                      ],
                    ),
                  ],
                  const SizedBox(height: 16),
                  TextField(
                    controller: parentNoteCtrl,
                    maxLines: 3,
                    style: const TextStyle(color: Colors.white),
                    decoration: const InputDecoration(
                      labelText: 'ملاحظة المعلم لولي الأمر (تظهر أسفل جدول الـ PDF)',
                      alignLabelWithHint: true,
                      prefixIcon: Icon(Icons.rate_review_outlined),
                    ),
                  ),
                  const SizedBox(height: 20),
                  if (isGeneratingPdf)
                    const Center(child: CircularProgressIndicator())
                  else
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            icon: const Icon(Icons.share_rounded),
                            label: const Text('مشاركة عبر واتساب'),
                            onPressed: () => handleExport(shareViaWhatsapp: true),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: OutlinedButton.icon(
                            icon: const Icon(Icons.print_rounded),
                            label: const Text('معاينة / طباعة'),
                            onPressed: () => handleExport(shareViaWhatsapp: false),
                          ),
                        ),
                      ],
                    ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: Column(
          children: [
            Text(_student.name),
            Text(
              'آخر حفظ: سورة ${_student.lastSurahName} (آية ${_student.lastAyah} - ص ${_student.lastPage})',
              style: const TextStyle(fontSize: 11.5, color: AppConstants.lightGold),
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'تصدير تقرير PDF لولي الأمر',
            icon: const Icon(Icons.picture_as_pdf_rounded),
            onPressed: _showExportPdfModal,
          ),
        ],
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: AppConstants.emeraldBackgroundGradient,
        ),
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        backgroundColor: AppConstants.surfaceEmerald,
                        foregroundColor: AppConstants.goldAccent,
                        side: const BorderSide(color: AppConstants.goldAccent, width: 1.4),
                        padding: const EdgeInsets.symmetric(vertical: 13),
                      ),
                      onPressed: _showExportPdfModal,
                      icon: const Icon(Icons.picture_as_pdf_rounded),
                      label: const Text('تصدير تقرير PDF لولي الأمر ومشاركته عبر واتساب'),
                    ),
                    const SizedBox(height: 16),

                    // 1. أزرار الحالة السريعة في الأعلى: (حضر ولم يسمع | غائب | مستأذن)
                    Card(
                      elevation: 3,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                        side: const BorderSide(color: AppConstants.goldAccent, width: 0.9),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(14),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Icon(Icons.bolt_rounded, color: AppConstants.goldAccent, size: 20),
                                const SizedBox(width: 6),
                                Text(
                                  'تسجيل حالة سريعة لليوم ($_todayDate):',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                    color: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                Expanded(
                                  child: ElevatedButton.icon(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color(0xFFE67E22),
                                      foregroundColor: Colors.white,
                                      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 6),
                                    ),
                                    onPressed: _isSaving
                                        ? null
                                        : () => _recordQuickStatus(
                                              AppConstants.statusAttendedNoRecitation,
                                            ),
                                    icon: const Icon(Icons.person_off_outlined, size: 17),
                                    label: const FittedBox(
                                      fit: BoxFit.scaleDown,
                                      child: Text('حضر ولم يسمّع'),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: ElevatedButton.icon(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color(0xFFDC3545),
                                      foregroundColor: Colors.white,
                                      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 6),
                                    ),
                                    onPressed: _isSaving
                                        ? null
                                        : () => _recordQuickStatus(
                                              AppConstants.statusAbsent,
                                            ),
                                    icon: const Icon(Icons.cancel_outlined, size: 17),
                                    label: const FittedBox(
                                      fit: BoxFit.scaleDown,
                                      child: Text('غائب'),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: ElevatedButton.icon(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: AppConstants.goldAccent,
                                      foregroundColor: AppConstants.darkEmerald,
                                      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 6),
                                    ),
                                    onPressed: _isSaving
                                        ? null
                                        : () => _recordQuickStatus(AppConstants.statusExcused),
                                    icon: const Icon(Icons.event_busy_rounded, size: 17),
                                    label: const FittedBox(
                                      fit: BoxFit.scaleDown,
                                      child: Text('مستأذن'),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),

                    // 2. بطاقة تسجيل الحفظ (Memorization Card) مع ربط تلقائي بين الآيات والصفحات
                    _buildQuranInputCard(
                      title: 'بطاقة تسجيل الحفظ الجديد (ربط تلقائي بالصفحات)',
                      icon: Icons.menu_book_rounded,
                      headerColor: AppConstants.primaryColor,
                      selectedSurahNum: _memSurahNum,
                      fromAyahCtrl: _memFromAyahCtrl,
                      toAyahCtrl: _memToAyahCtrl,
                      fromPageCtrl: _memFromPageCtrl,
                      toPageCtrl: _memToPageCtrl,
                      onAyahChanged: _syncMemPagesFromAyahs,
                      onSurahChanged: (val) {
                        if (val != null) {
                          final s = QuranMetadata.getByNumber(val);
                          setState(() {
                            _memSurahNum = val;
                            _memFromAyahCtrl.text = '1';
                            _memToAyahCtrl.text = s.ayahCount.toString();
                            _memFromPageCtrl.text = s.startPage.toString();
                            _memToPageCtrl.text = s.endPage.toString();
                          });
                        }
                      },
                    ),
                    const SizedBox(height: 14),

                    // 3. بطاقة تسجيل المراجعة (Revision Card) مع ربط تلقائي بين الآيات والصفحات
                    _buildQuranInputCard(
                      title: 'بطاقة تسجيل المراجعة اليومية (ربط تلقائي بالصفحات)',
                      icon: Icons.autorenew_rounded,
                      headerColor: AppConstants.secondaryColor,
                      selectedSurahNum: _revSurahNum,
                      fromAyahCtrl: _revFromAyahCtrl,
                      toAyahCtrl: _revToAyahCtrl,
                      fromPageCtrl: _revFromPageCtrl,
                      toPageCtrl: _revToPageCtrl,
                      onAyahChanged: _syncRevPagesFromAyahs,
                      onSurahChanged: (val) {
                        if (val != null) {
                          final s = QuranMetadata.getByNumber(val);
                          setState(() {
                            _revSurahNum = val;
                            _revFromAyahCtrl.text = '1';
                            _revToAyahCtrl.text = s.ayahCount.toString();
                            _revFromPageCtrl.text = s.startPage.toString();
                            _revToPageCtrl.text = s.endPage.toString();
                          });
                        }
                      },
                    ),
                    const SizedBox(height: 12),

                    TextField(
                      controller: _notesCtrl,
                      style: const TextStyle(color: Colors.white),
                      decoration: const InputDecoration(
                        labelText: 'ملاحظات التسميع اليوم (اختياري - مثل: ممتاز / يحتاج تركيز في المدود)',
                        prefixIcon: Icon(Icons.edit_note_rounded),
                      ),
                    ),
                    const SizedBox(height: 14),

                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppConstants.goldAccent,
                        foregroundColor: AppConstants.darkEmerald,
                        padding: const EdgeInsets.symmetric(vertical: 15),
                      ),
                      onPressed: _isSaving ? null : _saveRecitationLog,
                      icon: const Icon(Icons.check_circle_rounded),
                      label: Text(
                        _isSaving ? 'جارٍ الحفظ...' : 'اعتماد وحفظ تسميع اليوم (حاضر وسمّع)',
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                    ),
                    const SizedBox(height: 26),

                    // 4. سجل الأيام السابقة (History List)
                    Row(
                      children: [
                        const Icon(Icons.history_rounded, color: AppConstants.goldAccent),
                        const SizedBox(width: 8),
                        Text(
                          'سجل الأيام السابقة (${_historyLogs.length} يوم):',
                          style: const TextStyle(
                            fontSize: 16.5,
                            fontWeight: FontWeight.bold,
                            color: AppConstants.goldAccent,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    if (_historyLogs.isEmpty)
                      Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: AppConstants.surfaceEmerald,
                          border: Border.all(color: AppConstants.goldAccent.withOpacity(0.5)),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: const Text(
                          'لا توجد سجلات سابقة لهذا الطالب حتى الآن.',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.white70),
                        ),
                      )
                    else
                      ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: _historyLogs.length,
                        itemBuilder: (ctx, idx) {
                          final item = _historyLogs[idx];
                          final statusColor = AppConstants.statusColor(item.status);
                          final statusLabel = AppConstants.statusLabelAr(item.status);

                          return Card(
                            margin: const EdgeInsets.only(bottom: 10),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                              side: const BorderSide(color: AppConstants.goldAccent, width: 0.7),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(14),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Row(
                                        children: [
                                          const Icon(
                                            Icons.event_note_rounded,
                                            size: 18,
                                            color: AppConstants.goldAccent,
                                          ),
                                          const SizedBox(width: 6),
                                          Text(
                                            item.logDate,
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 14.5,
                                              color: Colors.white,
                                            ),
                                          ),
                                        ],
                                      ),
                                      Row(
                                        children: [
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 10,
                                              vertical: 4,
                                            ),
                                            decoration: BoxDecoration(
                                              color: statusColor.withOpacity(0.18),
                                              borderRadius: BorderRadius.circular(14),
                                              border: Border.all(color: statusColor),
                                            ),
                                            child: Text(
                                              statusLabel,
                                              style: TextStyle(
                                                color: statusColor,
                                                fontSize: 11.5,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          Tooltip(
                                            message: item.isSynced == 1
                                                ? 'مرفوع ومحفوظ في قاعدة البيانات السحابية'
                                                : 'محفوظ محلياً بانتظار الإنترنت',
                                            child: Icon(
                                              item.isSynced == 1
                                                  ? Icons.cloud_done_rounded
                                                  : Icons.cloud_upload_outlined,
                                              size: 18,
                                              color: item.isSynced == 1
                                                  ? const Color(0xFF2ECC71)
                                                  : AppConstants.goldAccent,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                  if (item.status == AppConstants.statusRecited) ...[
                                    const Divider(height: 16, color: Colors.white24),
                                    Text(
                                      '• الحفظ: ${item.formattedMemorization}',
                                      style: const TextStyle(fontSize: 13.5, color: Colors.white),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      '• المراجعة: ${item.formattedRevision}',
                                      style: const TextStyle(fontSize: 13.5, color: Colors.white),
                                    ),
                                  ],
                                  if (item.notes.isNotEmpty) ...[
                                    const SizedBox(height: 6),
                                    Text(
                                      'ملاحظة: ${item.notes}',
                                      style: const TextStyle(
                                        fontSize: 12.5,
                                        color: AppConstants.lightGold,
                                        fontStyle: FontStyle.italic,
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _buildQuranInputCard({
    required String title,
    required IconData icon,
    required Color headerColor,
    required int selectedSurahNum,
    required TextEditingController fromAyahCtrl,
    required TextEditingController toAyahCtrl,
    required TextEditingController fromPageCtrl,
    required TextEditingController toPageCtrl,
    required VoidCallback onAyahChanged,
    required ValueChanged<int?> onSurahChanged,
  }) {
    final surahInfo = QuranMetadata.getByNumber(selectedSurahNum);

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: AppConstants.goldAccent, width: 0.9),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
            decoration: BoxDecoration(
              color: headerColor,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
              border: const Border(
                bottom: BorderSide(color: AppConstants.goldAccent, width: 0.8),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Row(
                    children: [
                      Icon(icon, color: AppConstants.goldAccent, size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          title,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Text(
                  'آياتها: ${surahInfo.ayahCount} | ص ${surahInfo.startPage}-${surahInfo.endPage}',
                  style: const TextStyle(color: AppConstants.lightGold, fontSize: 11.5),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      flex: 5,
                      child: DropdownButtonFormField<int>(
                        value: selectedSurahNum,
                        isExpanded: true,
                        dropdownColor: AppConstants.surfaceEmerald,
                        style: const TextStyle(color: Colors.white),
                        decoration: const InputDecoration(
                          labelText: 'السورة (114 سورة)',
                        ),
                        items: QuranMetadata.surahs
                            .map(
                              (s) => DropdownMenuItem<int>(
                                value: s.number,
                                child: Text(
                                  '${s.number}. ${s.name}',
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(fontSize: 13.5, color: Colors.white),
                                ),
                              ),
                            )
                            .toList(),
                        onChanged: onSurahChanged,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      flex: 2,
                      child: TextField(
                        controller: fromAyahCtrl,
                        keyboardType: TextInputType.number,
                        style: const TextStyle(color: Colors.white),
                        decoration: const InputDecoration(labelText: 'من آية'),
                        onChanged: (_) => onAyahChanged(),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      flex: 2,
                      child: TextField(
                        controller: toAyahCtrl,
                        keyboardType: TextInputType.number,
                        style: const TextStyle(color: Colors.white),
                        decoration: const InputDecoration(labelText: 'إلى آية'),
                        onChanged: (_) => onAyahChanged(),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: fromPageCtrl,
                        keyboardType: TextInputType.number,
                        style: const TextStyle(color: Colors.white),
                        decoration: const InputDecoration(
                          labelText: 'من صفحة (تُحسب تلقائياً)',
                          prefixIcon: Icon(Icons.find_in_page_outlined, size: 18),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextField(
                        controller: toPageCtrl,
                        keyboardType: TextInputType.number,
                        style: const TextStyle(color: Colors.white),
                        decoration: const InputDecoration(
                          labelText: 'إلى صفحة (تُحسب تلقائياً)',
                          prefixIcon: Icon(Icons.find_in_page_outlined, size: 18),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
