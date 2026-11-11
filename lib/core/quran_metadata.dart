class SurahInfo {
  final int number;
  final String name;
  final int ayahCount;
  final int startPage;
  final int endPage;

  const SurahInfo({
    required this.number,
    required this.name,
    required this.ayahCount,
    required this.startPage,
    required this.endPage,
  });
}

class QuranMetadata {
  static const List<SurahInfo> surahs = [
    SurahInfo(number: 1, name: 'الفاتحة', ayahCount: 7, startPage: 1, endPage: 1),
    SurahInfo(number: 2, name: 'البقرة', ayahCount: 286, startPage: 2, endPage: 49),
    SurahInfo(number: 3, name: 'آل عمران', ayahCount: 200, startPage: 50, endPage: 76),
    SurahInfo(number: 4, name: 'النساء', ayahCount: 176, startPage: 77, endPage: 106),
    SurahInfo(number: 5, name: 'المائدة', ayahCount: 120, startPage: 106, endPage: 127),
    SurahInfo(number: 6, name: 'الأنعام', ayahCount: 165, startPage: 128, endPage: 150),
    SurahInfo(number: 7, name: 'الأعراف', ayahCount: 206, startPage: 151, endPage: 176),
    SurahInfo(number: 8, name: 'الأنفال', ayahCount: 75, startPage: 177, endPage: 186),
    SurahInfo(number: 9, name: 'التوبة', ayahCount: 129, startPage: 187, endPage: 207),
    SurahInfo(number: 10, name: 'يونس', ayahCount: 109, startPage: 208, endPage: 221),
    SurahInfo(number: 11, name: 'هود', ayahCount: 123, startPage: 221, endPage: 235),
    SurahInfo(number: 12, name: 'يوسف', ayahCount: 111, startPage: 235, endPage: 248),
    SurahInfo(number: 13, name: 'الرعد', ayahCount: 43, startPage: 249, endPage: 255),
    SurahInfo(number: 14, name: 'إبراهيم', ayahCount: 52, startPage: 255, endPage: 261),
    SurahInfo(number: 15, name: 'الحجر', ayahCount: 99, startPage: 262, endPage: 267),
    SurahInfo(number: 16, name: 'النحل', ayahCount: 128, startPage: 267, endPage: 281),
    SurahInfo(number: 17, name: 'الإسراء', ayahCount: 111, startPage: 282, endPage: 293),
    SurahInfo(number: 18, name: 'الكهف', ayahCount: 110, startPage: 293, endPage: 304),
    SurahInfo(number: 19, name: 'مريم', ayahCount: 98, startPage: 305, endPage: 312),
    SurahInfo(number: 20, name: 'طه', ayahCount: 135, startPage: 312, endPage: 321),
    SurahInfo(number: 21, name: 'الأنبياء', ayahCount: 112, startPage: 322, endPage: 331),
    SurahInfo(number: 22, name: 'الحج', ayahCount: 78, startPage: 332, endPage: 341),
    SurahInfo(number: 23, name: 'المؤمنون', ayahCount: 118, startPage: 342, endPage: 349),
    SurahInfo(number: 24, name: 'النور', ayahCount: 64, startPage: 350, endPage: 359),
    SurahInfo(number: 25, name: 'الفرقان', ayahCount: 77, startPage: 359, endPage: 366),
    SurahInfo(number: 26, name: 'الشعراء', ayahCount: 227, startPage: 367, endPage: 376),
    SurahInfo(number: 27, name: 'النمل', ayahCount: 93, startPage: 377, endPage: 385),
    SurahInfo(number: 28, name: 'القصص', ayahCount: 88, startPage: 385, endPage: 396),
    SurahInfo(number: 29, name: 'العنكبوت', ayahCount: 69, startPage: 396, endPage: 404),
    SurahInfo(number: 30, name: 'الروم', ayahCount: 60, startPage: 404, endPage: 410),
    SurahInfo(number: 31, name: 'لقمان', ayahCount: 34, startPage: 411, endPage: 414),
    SurahInfo(number: 32, name: 'السجدة', ayahCount: 30, startPage: 415, endPage: 417),
    SurahInfo(number: 33, name: 'الأحزاب', ayahCount: 73, startPage: 418, endPage: 427),
    SurahInfo(number: 34, name: 'سبأ', ayahCount: 54, startPage: 428, endPage: 434),
    SurahInfo(number: 35, name: 'فاطر', ayahCount: 45, startPage: 434, endPage: 440),
    SurahInfo(number: 36, name: 'يس', ayahCount: 83, startPage: 440, endPage: 445),
    SurahInfo(number: 37, name: 'الصافات', ayahCount: 182, startPage: 446, endPage: 452),
    SurahInfo(number: 38, name: 'ص', ayahCount: 88, startPage: 453, endPage: 458),
    SurahInfo(number: 39, name: 'الزمر', ayahCount: 75, startPage: 458, endPage: 467),
    SurahInfo(number: 40, name: 'غافر', ayahCount: 85, startPage: 467, endPage: 476),
    SurahInfo(number: 41, name: 'فصلت', ayahCount: 54, startPage: 477, endPage: 482),
    SurahInfo(number: 42, name: 'الشورى', ayahCount: 53, startPage: 483, endPage: 489),
    SurahInfo(number: 43, name: 'الزخرف', ayahCount: 89, startPage: 489, endPage: 495),
    SurahInfo(number: 44, name: 'الدخان', ayahCount: 59, startPage: 496, endPage: 498),
    SurahInfo(number: 45, name: 'الجاثية', ayahCount: 37, startPage: 499, endPage: 502),
    SurahInfo(number: 46, name: 'الأحقاف', ayahCount: 35, startPage: 502, endPage: 506),
    SurahInfo(number: 47, name: 'محمد', ayahCount: 38, startPage: 507, endPage: 510),
    SurahInfo(number: 48, name: 'الفتح', ayahCount: 29, startPage: 511, endPage: 515),
    SurahInfo(number: 49, name: 'الحجرات', ayahCount: 18, startPage: 515, endPage: 517),
    SurahInfo(number: 50, name: 'ق', ayahCount: 45, startPage: 518, endPage: 520),
    SurahInfo(number: 51, name: 'الذاريات', ayahCount: 60, startPage: 520, endPage: 523),
    SurahInfo(number: 52, name: 'الطور', ayahCount: 49, startPage: 523, endPage: 525),
    SurahInfo(number: 53, name: 'النجم', ayahCount: 62, startPage: 526, endPage: 528),
    SurahInfo(number: 54, name: 'القمر', ayahCount: 55, startPage: 528, endPage: 531),
    SurahInfo(number: 55, name: 'الرحمن', ayahCount: 78, startPage: 531, endPage: 534),
    SurahInfo(number: 56, name: 'الواقعة', ayahCount: 96, startPage: 534, endPage: 537),
    SurahInfo(number: 57, name: 'الحديد', ayahCount: 29, startPage: 537, endPage: 541),
    SurahInfo(number: 58, name: 'المجادلة', ayahCount: 22, startPage: 542, endPage: 545),
    SurahInfo(number: 59, name: 'الحشر', ayahCount: 24, startPage: 545, endPage: 548),
    SurahInfo(number: 60, name: 'الممتحنة', ayahCount: 13, startPage: 549, endPage: 551),
    SurahInfo(number: 61, name: 'الصف', ayahCount: 14, startPage: 551, endPage: 552),
    SurahInfo(number: 62, name: 'الجمعة', ayahCount: 11, startPage: 553, endPage: 554),
    SurahInfo(number: 63, name: 'المنافقون', ayahCount: 11, startPage: 554, endPage: 555),
    SurahInfo(number: 64, name: 'التغابن', ayahCount: 18, startPage: 556, endPage: 557),
    SurahInfo(number: 65, name: 'الطلاق', ayahCount: 12, startPage: 558, endPage: 559),
    SurahInfo(number: 66, name: 'التحريم', ayahCount: 12, startPage: 560, endPage: 561),
    SurahInfo(number: 67, name: 'الملك', ayahCount: 30, startPage: 562, endPage: 564),
    SurahInfo(number: 68, name: 'القلم', ayahCount: 52, startPage: 564, endPage: 566),
    SurahInfo(number: 69, name: 'الحاقة', ayahCount: 52, startPage: 566, endPage: 568),
    SurahInfo(number: 70, name: 'المعارج', ayahCount: 44, startPage: 568, endPage: 570),
    SurahInfo(number: 71, name: 'نوح', ayahCount: 28, startPage: 570, endPage: 571),
    SurahInfo(number: 72, name: 'الجن', ayahCount: 28, startPage: 572, endPage: 573),
    SurahInfo(number: 73, name: 'المزمل', ayahCount: 20, startPage: 574, endPage: 575),
    SurahInfo(number: 74, name: 'المدثر', ayahCount: 56, startPage: 575, endPage: 577),
    SurahInfo(number: 75, name: 'القيامة', ayahCount: 40, startPage: 577, endPage: 578),
    SurahInfo(number: 76, name: 'الإنسان', ayahCount: 31, startPage: 578, endPage: 580),
    SurahInfo(number: 77, name: 'المرسلات', ayahCount: 50, startPage: 580, endPage: 581),
    SurahInfo(number: 78, name: 'النبأ', ayahCount: 40, startPage: 582, endPage: 583),
    SurahInfo(number: 79, name: 'النازعات', ayahCount: 46, startPage: 583, endPage: 584),
    SurahInfo(number: 80, name: 'عبس', ayahCount: 42, startPage: 585, endPage: 585),
    SurahInfo(number: 81, name: 'التكوير', ayahCount: 29, startPage: 586, endPage: 586),
    SurahInfo(number: 82, name: 'الانفطار', ayahCount: 19, startPage: 587, endPage: 587),
    SurahInfo(number: 83, name: 'المطففين', ayahCount: 36, startPage: 587, endPage: 589),
    SurahInfo(number: 84, name: 'الانشقاق', ayahCount: 25, startPage: 589, endPage: 589),
    SurahInfo(number: 85, name: 'البروج', ayahCount: 22, startPage: 590, endPage: 590),
    SurahInfo(number: 86, name: 'الطارق', ayahCount: 17, startPage: 591, endPage: 591),
    SurahInfo(number: 87, name: 'الأعلى', ayahCount: 19, startPage: 591, endPage: 592),
    SurahInfo(number: 88, name: 'الغاشية', ayahCount: 26, startPage: 592, endPage: 592),
    SurahInfo(number: 89, name: 'الفجر', ayahCount: 30, startPage: 593, endPage: 594),
    SurahInfo(number: 90, name: 'البلد', ayahCount: 20, startPage: 594, endPage: 594),
    SurahInfo(number: 91, name: 'الشمس', ayahCount: 15, startPage: 595, endPage: 595),
    SurahInfo(number: 92, name: 'الليل', ayahCount: 21, startPage: 595, endPage: 596),
    SurahInfo(number: 93, name: 'الضحى', ayahCount: 11, startPage: 596, endPage: 596),
    SurahInfo(number: 94, name: 'الشرح', ayahCount: 8, startPage: 596, endPage: 596),
    SurahInfo(number: 95, name: 'التين', ayahCount: 8, startPage: 597, endPage: 597),
    SurahInfo(number: 96, name: 'العلق', ayahCount: 19, startPage: 597, endPage: 597),
    SurahInfo(number: 97, name: 'القدر', ayahCount: 5, startPage: 598, endPage: 598),
    SurahInfo(number: 98, name: 'البينة', ayahCount: 8, startPage: 598, endPage: 599),
    SurahInfo(number: 99, name: 'الزلزلة', ayahCount: 8, startPage: 599, endPage: 599),
    SurahInfo(number: 100, name: 'العاديات', ayahCount: 11, startPage: 599, endPage: 600),
    SurahInfo(number: 101, name: 'القارعة', ayahCount: 11, startPage: 600, endPage: 600),
    SurahInfo(number: 102, name: 'التكاثر', ayahCount: 8, startPage: 600, endPage: 600),
    SurahInfo(number: 103, name: 'العصر', ayahCount: 3, startPage: 601, endPage: 601),
    SurahInfo(number: 104, name: 'الهمزة', ayahCount: 9, startPage: 601, endPage: 601),
    SurahInfo(number: 105, name: 'الفيل', ayahCount: 5, startPage: 601, endPage: 601),
    SurahInfo(number: 106, name: 'قريش', ayahCount: 4, startPage: 602, endPage: 602),
    SurahInfo(number: 107, name: 'الماعون', ayahCount: 7, startPage: 602, endPage: 602),
    SurahInfo(number: 108, name: 'الكوثر', ayahCount: 3, startPage: 602, endPage: 602),
    SurahInfo(number: 109, name: 'الكافرون', ayahCount: 6, startPage: 603, endPage: 603),
    SurahInfo(number: 110, name: 'النصر', ayahCount: 3, startPage: 603, endPage: 603),
    SurahInfo(number: 111, name: 'المسد', ayahCount: 5, startPage: 603, endPage: 603),
    SurahInfo(number: 112, name: 'الإخلاص', ayahCount: 4, startPage: 604, endPage: 604),
    SurahInfo(number: 113, name: 'الفلق', ayahCount: 5, startPage: 604, endPage: 604),
    SurahInfo(number: 114, name: 'الناس', ayahCount: 6, startPage: 604, endPage: 604),
  ];

    static const Map<int, List<int>> _surahPageEndAyahs = {
    36: [12, 27, 40, 54, 70, 83],
    40: [7, 16, 25, 33, 40, 49, 58, 66, 77, 85],
  };

  static int getPageForAyah(int surahNumber, int ayahNumber) {
    final surah = getByNumber(surahNumber);
    if (surah.startPage == surah.endPage) return surah.startPage;
    final safeAyah = ayahNumber.clamp(1, surah.ayahCount);
    final pageEnds = _surahPageEndAyahs[surahNumber];
    if (pageEnds != null) {
      for (int i = 0; i < pageEnds.length; i++) {
        if (safeAyah <= pageEnds[i]) return (surah.startPage + i).clamp(surah.startPage, surah.endPage);
      }
      return surah.endPage;
    }
    final totalPages = surah.endPage - surah.startPage + 1;
    final ratio = (safeAyah - 1) / (surah.ayahCount > 1 ? surah.ayahCount - 1 : 1);
    return (surah.startPage + (ratio * (totalPages - 1)).round()).clamp(surah.startPage, surah.endPage);
  }

  static Map<String, int> getPageRangeForAyahs({required int surahNumber, required int fromAyah, required int toAyah}) {
    final surah = getByNumber(surahNumber);
    final sA = fromAyah.clamp(1, surah.ayahCount);
    final eA = toAyah.clamp(sA, surah.ayahCount);
    final fP = getPageForAyah(surahNumber, sA);
    final tP = getPageForAyah(surahNumber, eA);
    return {'fromPage': fP, 'toPage': tP >= fP ? tP : fP};
  }
  static SurahInfo getByNumber(int number) {
    return surahs.firstWhere(
      (s) => s.number == number,
      orElse: () => surahs.first,
    );
  }

  static SurahInfo getByName(String name) {
    return surahs.firstWhere(
      (s) => s.name == name,
      orElse: () => surahs.first,
    );
  }

  /// يحسب موضع التسميع الذكي التالي بناءً على آخر سورة وآية وصفحة توقف عندها الطالب
  static Map<String, dynamic> getNextPosition({
    required int lastSurahNumber,
    required int lastAyah,
    required int lastPage,
  }) {
    final currentSurah = getByNumber(lastSurahNumber);
    if (lastAyah < currentSurah.ayahCount) {
      return {
        'surahNumber': currentSurah.number,
        'surahName': currentSurah.name,
        'fromAyah': lastAyah + 1,
        'toAyah': currentSurah.ayahCount,
        'fromPage': lastPage,
        'toPage': currentSurah.endPage,
      };
    } else {
      // انتهت السورة السابقة، ننتقل إلى السورة التالية (أو العودة للبقرة بعد الناس)
      final nextSurahNum = lastSurahNumber < 114 ? lastSurahNumber + 1 : 2;
      final nextSurah = getByNumber(nextSurahNum);
      return {
        'surahNumber': nextSurah.number,
        'surahName': nextSurah.name,
        'fromAyah': 1,
        'toAyah': nextSurah.ayahCount >= 10 ? 10 : nextSurah.ayahCount,
        'fromPage': nextSurah.startPage,
        'toPage': nextSurah.startPage,
      };
    }
  }
}
