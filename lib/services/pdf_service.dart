import 'package:flutter/services.dart' show rootBundle;
import 'dart:io';
import 'package:intl/intl.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:share_plus/share_plus.dart';
import '../core/constants.dart';
import '../models/student_model.dart';
import '../models/user_model.dart';
import '../models/daily_log_model.dart';

class PdfService {
  static Future<pw.Font> _loadSafeArabicFont(String assetPath, bool isBold) async {
    try {
      final data = await rootBundle.load(assetPath);
      if (data.lengthInBytes > 1000) {
        return pw.Font.ttf(data);
      }
    } catch (_) {}
    return isBold ? await _loadSafeArabicFont('assets/fonts/NotoSansArabic-Bold.ttf', true) : await _loadSafeArabicFont('assets/fonts/NotoSansArabic-Regular.ttf', false);
  }
  static Future<File> generateParentReport({
    required StudentModel student,
    required UserModel teacher,
    required List<DailyLogModel> logs,
    required String startDate,
    required String endDate,
    required String parentNote,
  }) async {
    pw.Font arabicRegular;
    pw.Font arabicBold;
    try {
      arabicRegular = await _loadSafeArabicFont('assets/fonts/NotoSansArabic-Regular.ttf', false);
      arabicBold = await _loadSafeArabicFont('assets/fonts/NotoSansArabic-Bold.ttf', true);
    } catch (_) {
      arabicRegular = pw.Font.helvetica();
      arabicBold = pw.Font.helveticaBold();
    }

    final pdf = pw.Document();

    int recitedDays = 0;
    int attendedNoReciteDays = 0;
    int absentDays = 0;
    int excusedDays = 0;
    int totalMemPages = 0;
    int totalRevPages = 0;

    for (final log in logs) {
      if (log.status == AppConstants.statusRecited) {
        recitedDays++;
        totalMemPages += log.memPagesCount;
        totalRevPages += log.revPagesCount;
      } else if (log.status == AppConstants.statusAttendedNoRecitation) {
        attendedNoReciteDays++;
      } else if (log.status == AppConstants.statusAbsent) {
        absentDays++;
      } else if (log.status == AppConstants.statusExcused) {
        excusedDays++;
      }
    }

    final totalPresentDays = recitedDays + attendedNoReciteDays;

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(28),
        textDirection: pw.TextDirection.rtl,
        theme: pw.ThemeData.withFont(
          base: arabicRegular,
          bold: arabicBold,
        ),
        header: (context) => _buildHeader(
          student: student,
          teacher: teacher,
          startDate: startDate,
          endDate: endDate,
          boldFont: arabicBold,
        ),
        footer: (context) => _buildFooter(context),
        build: (context) => [
          pw.SizedBox(height: 14),
          _buildLogsTable(logs, arabicBold),
          pw.SizedBox(height: 18),
          _buildSummarySection(
            totalPresentDays: totalPresentDays,
            recitedDays: recitedDays,
            attendedNoReciteDays: attendedNoReciteDays,
            absentDays: absentDays,
            excusedDays: excusedDays,
            totalMemPages: totalMemPages,
            totalRevPages: totalRevPages,
            boldFont: arabicBold,
          ),
          if (parentNote.trim().isNotEmpty) ...[
            pw.SizedBox(height: 16),
            _buildTeacherNoteBox(parentNote.trim(), arabicBold),
          ],
        ],
      ),
    );

    final outputDir = await getTemporaryDirectory();
    final safeName = student.name.replaceAll(RegExp(r'[\/:*?"<>| ]'), '_');
    final filePath = p.join(
      outputDir.path,
      'تقرير_سفرة_${safeName}_$endDate.pdf',
    );
    final file = File(filePath);
    await file.writeAsBytes(await pdf.save());
    return file;
  }

  /// توليد التقرير المؤسسي الرسمي للحلقة لتسليمه للمنظمة أو إدارة المركز
  static Future<File> generateCircleInstitutionalReport({
    required UserModel teacher,
    required List<StudentModel> students,
    required List<DailyLogModel> logs,
    required String startDate,
    required String endDate,
    String organizationName = 'مركز سَفَرَة لتحفيظ القرآن الكريم',
  }) async {
    pw.Font regular;
    pw.Font bold;
    try {
      regular = await _loadSafeArabicFont('assets/fonts/NotoSansArabic-Regular.ttf', false);
      bold = await _loadSafeArabicFont('assets/fonts/NotoSansArabic-Bold.ttf', true);
    } catch (_) {
      regular = pw.Font.helvetica();
      bold = pw.Font.helveticaBold();
    }

    final pdf = pw.Document();
    final studentById = {for (final student in students) student.id: student};

    final present = logs
        .where((l) =>
            l.status == AppConstants.statusRecited ||
            l.status == AppConstants.statusAttendedNoRecitation)
        .length;
    final absent = logs.where((l) => l.status == AppConstants.statusAbsent).length;
    final noRecite = logs
        .where((l) => l.status == AppConstants.statusAttendedNoRecitation)
        .length;
    final excused = logs.where((l) => l.status == AppConstants.statusExcused).length;
    final memPages = logs.fold<int>(0, (sum, l) => sum + l.memPagesCount);
    final revPages = logs.fold<int>(0, (sum, l) => sum + l.revPagesCount);
    final total = logs.where((l) => l.status != AppConstants.statusExcused).length;
    final attendanceRate = total == 0 ? 0 : (present * 100 / total).round();

    // جدول ملخص شامل لكل طالب في الحلقة (يطلبه المشرفون والمنظمات الداعمة)
    final studentSummaryRows = students.map((st) {
      final stLogs = logs.where((l) => l.studentId == st.id).toList();
      final stPresent = stLogs
          .where((l) =>
              l.status == AppConstants.statusRecited ||
              l.status == AppConstants.statusAttendedNoRecitation)
          .length;
      final stAbsent =
          stLogs.where((l) => l.status == AppConstants.statusAbsent).length;
      final stNoRecite = stLogs
          .where((l) => l.status == AppConstants.statusAttendedNoRecitation)
          .length;
      final stExcused =
          stLogs.where((l) => l.status == AppConstants.statusExcused).length;
      final stMem = stLogs.fold<int>(0, (sum, l) => sum + l.memPagesCount);
      final stRev = stLogs.fold<int>(0, (sum, l) => sum + l.revPagesCount);

      return [
        '$stRev ص',
        '$stMem ص',
        '$stExcused',
        '$stNoRecite',
        '$stAbsent',
        '$stPresent',
        'سورة ${st.lastSurahName} (آية ${st.lastAyah})',
        st.name,
      ];
    }).toList();

    pw.Widget ledger(String title, bool revision) {
      final rows = logs
          .where((l) => revision
              ? l.revSurahName != null && l.revSurahName!.isNotEmpty
              : l.memSurahName != null && l.memSurahName!.isNotEmpty)
          .toList();
      return pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.stretch,
        children: [
          pw.Container(
            padding: const pw.EdgeInsets.all(8),
            color: PdfColor.fromInt(0xFF0B5335),
            child: pw.Text(
              title,
              textAlign: pw.TextAlign.center,
              style: pw.TextStyle(font: bold, color: PdfColors.white, fontSize: 11.5),
            ),
          ),
          if (rows.isEmpty)
            pw.Container(
              padding: const pw.EdgeInsets.all(10),
              decoration: pw.BoxDecoration(
                border: pw.Border.all(color: PdfColors.grey400, width: 0.5),
              ),
              child: pw.Text(
                'لا توجد سجلات مسجلة خلال الفترة المحددة',
                textAlign: pw.TextAlign.center,
                style: pw.TextStyle(font: regular, fontSize: 9.5),
              ),
            )
          else
            pw.TableHelper.fromTextArray(
              headers: ['التاريخ', 'الصفحات', 'الآيات', 'السورة', 'اسم الطالب'],
              data: rows.map((l) {
                final name = studentById[l.studentId]?.name ?? '—';
                final surah =
                    revision ? (l.revSurahName ?? '—') : (l.memSurahName ?? '—');
                final fromAyah = revision ? l.revFromAyah : l.memFromAyah;
                final toAyah = revision ? l.revToAyah : l.memToAyah;
                final fromPage = revision ? l.revFromPage : l.memFromPage;
                final toPage = revision ? l.revToPage : l.memToPage;
                return [
                  l.logDate,
                  '${fromPage ?? '—'} إلى ${toPage ?? '—'}',
                  '${fromAyah ?? '—'} إلى ${toAyah ?? '—'}',
                  'سورة $surah',
                  name,
                ];
              }).toList(),
              headerStyle:
                  pw.TextStyle(font: bold, fontSize: 9, color: PdfColors.white),
              headerDecoration:
                  pw.BoxDecoration(color: PdfColor.fromInt(0xFF146C43)),
              cellStyle: pw.TextStyle(font: regular, fontSize: 8.5),
              cellAlignment: pw.Alignment.center,
              cellPadding: const pw.EdgeInsets.all(5),
              border: pw.TableBorder.all(color: PdfColors.grey400, width: .5),
            ),
        ],
      );
    }

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(24),
        textDirection: pw.TextDirection.rtl,
        theme: pw.ThemeData.withFont(base: regular, bold: bold),
        header: (_) => pw.Container(
          padding: const pw.EdgeInsets.all(14),
          decoration: pw.BoxDecoration(
            color: PdfColor.fromInt(0xFF042F1D),
            border: pw.Border.all(color: PdfColor.fromInt(0xFFD4AF37), width: 1.5),
            borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
          ),
          child: pw.Column(
            children: [
              pw.Text(
                'بسم الله الرحمن الرحيم — $organizationName',
                style: pw.TextStyle(font: bold, color: PdfColors.white, fontSize: 15),
              ),
              pw.SizedBox(height: 4),
              pw.Text(
                'التقرير المؤسسي الرسمي لإنجاز الحلقة القرآنية (مُعتمد للجهات الإشرافية والمنظمات)',
                style: pw.TextStyle(
                  font: bold,
                  color: PdfColor.fromInt(0xFFD4AF37),
                  fontSize: 10.5,
                ),
              ),
              pw.Divider(color: PdfColor.fromInt(0xFFD4AF37), thickness: 0.8),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text(
                    'الحلقة: ${teacher.halqaName}',
                    style: pw.TextStyle(font: bold, color: PdfColors.white, fontSize: 10),
                  ),
                  pw.Text(
                    'المعلم: ${teacher.fullName}',
                    style: pw.TextStyle(font: bold, color: PdfColors.white, fontSize: 10),
                  ),
                  pw.Text(
                    'الفترة: $startDate إلى $endDate',
                    style: pw.TextStyle(font: regular, color: PdfColors.white, fontSize: 9.5),
                  ),
                ],
              ),
            ],
          ),
        ),
        footer: (ctx) => pw.Container(
          margin: const pw.EdgeInsets.only(top: 8),
          padding: const pw.EdgeInsets.only(top: 6),
          decoration: const pw.BoxDecoration(
            border: pw.Border(top: pw.BorderSide(color: PdfColors.grey400)),
          ),
          child: pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text(
                'نظام سَفَرَة لإدارة الحلقات القرآنية — تقرير مؤسسي رسمي',
                style: pw.TextStyle(font: regular, fontSize: 8, color: PdfColors.grey700),
              ),
              pw.Text(
                'صفحة ${ctx.pageNumber} من ${ctx.pagesCount}',
                style: pw.TextStyle(font: regular, fontSize: 8, color: PdfColors.grey700),
              ),
            ],
          ),
        ),
        build: (_) => [
          pw.SizedBox(height: 12),
          pw.Text(
            'أولاً: الملخص الإحصائي العام للحلقة خلال الفترة:',
            style: pw.TextStyle(
              font: bold,
              fontSize: 12,
              color: PdfColor.fromInt(0xFF042F1D),
            ),
          ),
          pw.SizedBox(height: 6),
          pw.TableHelper.fromTextArray(
            headers: [
              'صفحات المراجعة',
              'صفحات الحفظ',
              'نسبة الانضباط',
              'مستأذن',
              'حضر ولم يسمّع',
              'أيام الغياب',
              'أيام الحضور',
              'عدد الطلاب',
            ],
            data: [
              [
                '$revPages ص',
                '$memPages ص',
                '$attendanceRate%',
                '$excused',
                '$noRecite',
                '$absent',
                '$present',
                '${students.length}',
              ]
            ],
            headerStyle:
                pw.TextStyle(font: bold, fontSize: 8.5, color: PdfColors.white),
            headerDecoration:
                pw.BoxDecoration(color: PdfColor.fromInt(0xFF0B5335)),
            cellStyle: pw.TextStyle(font: bold, fontSize: 9.5),
            cellAlignment: pw.Alignment.center,
            border: pw.TableBorder.all(color: PdfColors.grey400, width: .6),
          ),
          pw.SizedBox(height: 16),
          pw.Text(
            'ثانياً: بيان إنجاز وحضور كل طالب في الحلقة:',
            style: pw.TextStyle(
              font: bold,
              fontSize: 12,
              color: PdfColor.fromInt(0xFF042F1D),
            ),
          ),
          pw.SizedBox(height: 6),
          if (studentSummaryRows.isEmpty)
            pw.Text('لا يوجد طلاب مسجلون في هذه الحلقة.')
          else
            pw.TableHelper.fromTextArray(
              headers: [
                'مراجعة',
                'حفظ',
                'مستأذن',
                'لم يسمّع',
                'غياب',
                'حضور',
                'آخر موضع حفظ',
                'اسم الطالب',
              ],
              data: studentSummaryRows,
              headerStyle:
                  pw.TextStyle(font: bold, fontSize: 8.5, color: PdfColors.white),
              headerDecoration:
                  pw.BoxDecoration(color: PdfColor.fromInt(0xFF146C43)),
              cellStyle: pw.TextStyle(font: regular, fontSize: 8.5),
              cellAlignment: pw.Alignment.center,
              border: pw.TableBorder.all(color: PdfColors.grey400, width: .5),
            ),
          pw.SizedBox(height: 16),
          ledger('ثالثاً: السجل التفصيلي للحفظ الجديد', false),
          pw.SizedBox(height: 16),
          ledger('رابعاً: السجل التفصيلي للمراجعة اليومية', true),
          pw.SizedBox(height: 22),
          pw.Container(
            padding: const pw.EdgeInsets.all(12),
            decoration: pw.BoxDecoration(
              color: PdfColor.fromInt(0xFFF8F9FA),
              border: pw.Border.all(color: PdfColor.fromInt(0xFFD4AF37), width: 1),
              borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6)),
            ),
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text(
                  'توقيع معلم الحلقة: ................................',
                  style: pw.TextStyle(font: bold, fontSize: 9.5),
                ),
                pw.Text(
                  'ختم واعتماد إدارة المركز / المنظمة: ................................',
                  style: pw.TextStyle(font: bold, fontSize: 9.5),
                ),
              ],
            ),
          ),
        ],
      ),
    );

    final dir = await getTemporaryDirectory();
    final safeHalqa =
        teacher.halqaName.replaceAll(RegExp(r'[\/:*?"<>| ]'), '_');
    final file = File(
      p.join(dir.path, 'تقرير_مؤسسي_${safeHalqa}_$endDate.pdf'),
    );
    await file.writeAsBytes(await pdf.save(), flush: true);
    return file;
  }

  static Future<void> sharePdfReport(File pdfFile, StudentModel student) async {
    await Share.shareXFiles(
      [XFile(pdfFile.path)],
      text: 'تقرير متابعة الحفظ والمراجعة للطالب (${student.name}) عبر تطبيق سَفَرَة',
    );
  }

  static Future<void> shareInstitutionalReport(
      File pdfFile, String halqaName) async {
    await Share.shareXFiles(
      [XFile(pdfFile.path)],
      text: 'التقرير المؤسسي الرسمي لحلقة ($halqaName) الصادر عبر نظام سَفَرَة',
    );
  }

  static Future<void> previewAndPrintPdf(File pdfFile) async {
    final bytes = await pdfFile.readAsBytes();
    await Printing.layoutPdf(onLayout: (_) async => bytes);
  }

  static pw.Widget _buildHeader({
    required StudentModel student,
    required UserModel teacher,
    required String startDate,
    required String endDate,
    required pw.Font boldFont,
  }) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(14),
      decoration: pw.BoxDecoration(
        color: PdfColor.fromInt(0xFF0F5132),
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.stretch,
        children: [
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text(
                'تطبيق سَفَرَة - تقرير متابعة ولي الأمر',
                style: pw.TextStyle(
                  font: boldFont,
                  color: PdfColors.white,
                  fontSize: 16,
                ),
              ),
              pw.Text(
                'الفترة: من $startDate إلى $endDate',
                style: const pw.TextStyle(
                  color: PdfColors.white,
                  fontSize: 11,
                ),
              ),
            ],
          ),
          pw.Divider(color: PdfColor.fromInt(0xFFD4AF37), thickness: 1),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text(
                'اسم الطالب: ${student.name}',
                style: pw.TextStyle(
                  font: boldFont,
                  color: PdfColors.white,
                  fontSize: 12,
                ),
              ),
              pw.Text(
                'الحلقة: ${student.halqaName.isNotEmpty ? student.halqaName : teacher.halqaName}',
                style: const pw.TextStyle(
                  color: PdfColors.white,
                  fontSize: 12,
                ),
              ),
              pw.Text(
                'المعلم: ${teacher.fullName}',
                style: const pw.TextStyle(
                  color: PdfColors.white,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  static pw.Widget _buildLogsTable(
    List<DailyLogModel> logs,
    pw.Font boldFont,
  ) {
    if (logs.isEmpty) {
      return pw.Container(
        padding: const pw.EdgeInsets.all(20),
        alignment: pw.Alignment.center,
        decoration: pw.BoxDecoration(
          border: pw.Border.all(color: PdfColors.grey400),
          borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6)),
        ),
        child: pw.Text('لا توجد سجلات مسجلة خلال هذه الفترة الزمنية.'),
      );
    }

    final headers = [
      'المراجعة (السورة - الآيات - الصفحات)',
      'الحفظ (السورة - الآيات - الصفحات)',
      'الحالة',
      'اليوم والتاريخ',
    ];

    final dataRows = logs.map((log) {
      final dayName = _getArabicDayName(log.logDate);
      final statusAr = AppConstants.statusLabelAr(log.status);

      String memText = '-';
      String revText = '-';

      if (log.status == AppConstants.statusRecited) {
        if (log.memSurahName != null && log.memSurahName!.isNotEmpty) {
          memText =
              'سورة ${log.memSurahName}: آية ${log.memFromAyah} إلى ${log.memToAyah} (ص ${log.memFromPage} إلى ${log.memToPage})';
        }
        if (log.revSurahName != null && log.revSurahName!.isNotEmpty) {
          revText =
              'سورة ${log.revSurahName}: آية ${log.revFromAyah} إلى ${log.revToAyah} (ص ${log.revFromPage} إلى ${log.revToPage})';
        }
      } else if (log.status == AppConstants.statusAttendedNoRecitation) {
        memText = 'حضر ولم يُسمّع';
        revText = 'حضر ولم يُسمّع';
      } else if (log.status == AppConstants.statusAbsent) {
        memText = 'غائب';
        revText = 'غائب';
      } else if (log.status == AppConstants.statusExcused) {
        memText = 'مستأذن';
        revText = 'مستأذن';
      }

      return [
        revText,
        memText,
        statusAr,
        '$dayName (${log.logDate})',
      ];
    }).toList();

    return pw.TableHelper.fromTextArray(
      headers: headers,
      data: dataRows,
      border: pw.TableBorder.all(color: PdfColors.grey400, width: 0.7),
      headerStyle: pw.TextStyle(
        font: boldFont,
        color: PdfColors.white,
        fontSize: 10,
      ),
      headerDecoration: pw.BoxDecoration(
        color: PdfColor.fromInt(0xFF198754),
      ),
      cellStyle: const pw.TextStyle(fontSize: 9.5),
      cellAlignment: pw.Alignment.centerRight,
      headerAlignment: pw.Alignment.center,
      columnWidths: {
        0: const pw.FlexColumnWidth(3.2),
        1: const pw.FlexColumnWidth(3.2),
        2: const pw.FlexColumnWidth(1.5),
        3: const pw.FlexColumnWidth(2.1),
      },
    );
  }

  static pw.Widget _buildSummarySection({
    required int totalPresentDays,
    required int recitedDays,
    required int attendedNoReciteDays,
    required int absentDays,
    required int excusedDays,
    required int totalMemPages,
    required int totalRevPages,
    required pw.Font boldFont,
  }) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(12),
      decoration: pw.BoxDecoration(
        color: PdfColor.fromInt(0xFFF7F5F0),
        border: pw.Border.all(color: PdfColor.fromInt(0xFF0F5132), width: 1),
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            'الملخص الإحصائي للفترة:',
            style: pw.TextStyle(
              font: boldFont,
              fontSize: 12,
              color: PdfColor.fromInt(0xFF0F5132),
            ),
          ),
          pw.SizedBox(height: 8),
          pw.Wrap(
            spacing: 12,
            runSpacing: 8,
            children: [
              _statBadge('أيام الحضور الكلية', '$totalPresentDays يوم', boldFont),
              _statBadge('أيام التسميع', '$recitedDays يوم', boldFont),
              _statBadge('حضر بدون تسميع', '$attendedNoReciteDays يوم', boldFont),
              _statBadge('أيام الغياب', '$absentDays يوم', boldFont),
              _statBadge('أيام الاستئذان', '$excusedDays يوم', boldFont),
              _statBadge('إجمالي صفحات الحفظ', '$totalMemPages ص', boldFont),
              _statBadge('إجمالي صفحات المراجعة', '$totalRevPages ص', boldFont),
            ],
          ),
        ],
      ),
    );
  }

  static pw.Widget _statBadge(String title, String value, pw.Font boldFont) {
    return pw.Column(
      children: [
        pw.Text(title, style: const pw.TextStyle(fontSize: 9)),
        pw.SizedBox(height: 3),
        pw.Text(
          value,
          style: pw.TextStyle(
            font: boldFont,
            fontSize: 11,
            color: PdfColor.fromInt(0xFF0F5132),
          ),
        ),
      ],
    );
  }

  static pw.Widget _buildTeacherNoteBox(String note, pw.Font boldFont) {
    return pw.Container(
      width: double.infinity,
      padding: const pw.EdgeInsets.all(12),
      decoration: pw.BoxDecoration(
        color: PdfColor.fromInt(0xFFFFFBEB),
        border: pw.Border.all(color: PdfColor.fromInt(0xFFD4AF37), width: 1.2),
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            'ملاحظة المعلم لولي الأمر:',
            style: pw.TextStyle(
              font: boldFont,
              fontSize: 11,
              color: PdfColor.fromInt(0xFF856404),
            ),
          ),
          pw.SizedBox(height: 5),
          pw.Text(
            note,
            style: const pw.TextStyle(fontSize: 10.5),
          ),
        ],
      ),
    );
  }

  static pw.Widget _buildFooter(pw.Context context) {
    final nowStr = DateFormat('yyyy-MM-dd HH:mm').format(DateTime.now());
    return pw.Container(
      margin: const pw.EdgeInsets.only(top: 10),
      padding: const pw.EdgeInsets.only(top: 6),
      decoration: const pw.BoxDecoration(
        border: pw.Border(top: pw.BorderSide(color: PdfColors.grey300)),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(
            'صدر عبر تطبيق "سَفَرَة" لإدارة حلقات تحفيظ القرآن الكريم',
            style: const pw.TextStyle(fontSize: 8.5, color: PdfColors.grey700),
          ),
          pw.Text(
            'تاريخ الإصدار: $nowStr | صفحة ${context.pageNumber} من ${context.pagesCount}',
            style: const pw.TextStyle(fontSize: 8.5, color: PdfColors.grey700),
          ),
        ],
      ),
    );
  }

  static String _getArabicDayName(String dateStr) {
    try {
      final dt = DateTime.parse(dateStr);
      const days = {
        1: 'الإثنين',
        2: 'الثلاثاء',
        3: 'الأربعاء',
        4: 'الخميس',
        5: 'الجمعة',
        6: 'السبت',
        7: 'الأحد',
      };
      return days[dt.weekday] ?? '';
    } catch (_) {
      return '';
    }
  }
}
