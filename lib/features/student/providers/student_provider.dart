import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/student_model.dart';
import '../models/daily_report_model.dart';
import '../models/weekly_report_model.dart';
import '../models/supervisor_review_model.dart';

class StudentProvider extends ChangeNotifier {
  final _supabase = Supabase.instance.client;

  StudentModel? student;
  DailyReportModel? dailyReport;
  List<DailyReportModel> dailyReports = [];
  WeeklyReportModel? weeklyReport;
  List<SupervisorReviewModel> todayReviews = [];

  // ── Weekly reports list (for student weekly view) ──
  List<WeeklyReportModel> weeklyReports = [];
  bool isLoadingWeekly = false;

  bool isLoading = false;
  String? errorMessage;

  DateTime selectedDate = DateTime.now();

  // ── Week/Year selection for weekly view ──
  int selectedWeek = _getCurrentWeekNumber();
  int selectedYear = DateTime.now().year;

  static int _getCurrentWeekNumber() {
    final now = DateTime.now();
    final startOfYear = DateTime(now.year, 1, 1);
    final diff = now.difference(startOfYear);
    return ((diff.inDays + startOfYear.weekday) / 7).ceil();
  }

  RealtimeChannel? _dailyReportsChannel;
  RealtimeChannel? _supervisorReviewsChannel;
  RealtimeChannel? _weeklyEvaluationsChannel;

  Future<void> fetchStudentData(String identifier,
      {bool isParentPhone = true}) async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();

    try {
      // 1. Fetch Student Info
      final studentRes = await _supabase
          .from('students')
          .select()
          .eq(isParentPhone ? 'parent_phone' : 'id', identifier)
          .maybeSingle();

      if (studentRes == null) {
        errorMessage = 'لم يتم العثور على بيانات الطالب.';
        isLoading = false;
        notifyListeners();
        return;
      }

      student = StudentModel.fromJson(studentRes);

      // Setup realtime after student is loaded
      _setupRealtime();

      // Fetch other data based on student.id and selectedDate
      await fetchReportsForDate(selectedDate);
    } catch (e) {
      errorMessage = 'حدث خطأ أثناء جلب البيانات: $e';
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  void _setupRealtime() {
    if (student == null) return;

    // Unsubscribe old channels
    _dailyReportsChannel?.unsubscribe();
    _supervisorReviewsChannel?.unsubscribe();
    _weeklyEvaluationsChannel?.unsubscribe();

    final studentId = student!.id;

    // Listen to daily_reports changes for this student
    _dailyReportsChannel = _supabase
        .channel('daily_reports_student_$studentId')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'daily_reports',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'student_id',
            value: studentId,
          ),
          callback: (payload) {
            debugPrint('🔄 Daily report changed. Refreshing...');
            fetchReportsForDate(selectedDate);
          },
        )
        .subscribe();

    // Listen to student_reviews changes for this student
    _supervisorReviewsChannel = _supabase
        .channel('student_reviews_student_$studentId')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'student_reviews',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'student_id',
            value: studentId,
          ),
          callback: (payload) {
            debugPrint('🔄 Supervisor review changed. Refreshing...');
            fetchReportsForDate(selectedDate);
          },
        )
        .subscribe();

    // Listen to weekly_evaluations changes for this student
    _weeklyEvaluationsChannel = _supabase
        .channel('weekly_evaluations_student_$studentId')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'weekly_evaluations',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'student_id',
            value: studentId,
          ),
          callback: (payload) {
            debugPrint('🔄 Weekly evaluation changed. Refreshing...');
            fetchReportsForDate(selectedDate);
            fetchWeeklyReports(selectedWeek, selectedYear);
          },
        )
        .subscribe();
  }

  Future<void> fetchReportsForDate(DateTime date) async {
    if (student == null) return;

    selectedDate = date;
    isLoading = true;
    errorMessage = null;
    notifyListeners();

    try {
      final String dateString =
          '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

      // 2. Fetch All Daily Reports
      List<dynamic> dailyResList = [];
      try {
        dailyResList = await _supabase
            .from('daily_reports')
            .select()
            .eq('student_id', student!.id)
            .eq('report_date', dateString)
            .order('created_at', ascending: false);
      } catch (_) {}

      if (dailyResList.isEmpty) {
        try {
          dailyResList = await _supabase
              .from('daily_reports')
              .select()
              .eq('student_id', student!.id)
              .gte('created_at', '${dateString}T00:00:00')
              .lte('created_at', '${dateString}T23:59:59')
              .order('created_at', ascending: false);
        } catch (_) {}
      }

      List<DailyReportModel> fetchedReports = [];
      for (var r in dailyResList) {
        String? tName   = r['teacher_name']?.toString();   // already stored?
        String? tPhoto  = r['teacher_photo_url']?.toString();
        String? tSubject = r['subject']?.toString() ?? r['category']?.toString();
        final String? tId = r['teacher_id']?.toString();

        // Only do DB look-up if we still don't have the name
        if ((tName == null || tName.isEmpty) && tId != null) {
          try {
            final p = await _supabase
                .from('profiles')
                .select('full_name, avatar_url')
                .eq('id', tId)
                .maybeSingle();
            if (p != null) {
              tName  ??= p['full_name']?.toString();
              tPhoto ??= p['avatar_url']?.toString();
            }
          } catch (_) {}

          try {
            final t = await _supabase
                .from('teachers')
                .select('full_name, name, category')
                .eq('id', tId)
                .maybeSingle();
            if (t != null) {
              tName    ??= t['full_name']?.toString() ?? t['name']?.toString();
              tSubject ??= t['category']?.toString();
            }
          } catch (_) {}
        }

        final rMap = Map<String, dynamic>.from(r);
        rMap['teacher_name']      = (tName != null && tName.isNotEmpty) ? tName : 'المدرس';
        rMap['teacher_photo_url'] = tPhoto;
        rMap['subject']           = (tSubject != null && tSubject.isNotEmpty) ? tSubject : 'يومي';
        fetchedReports.add(DailyReportModel.fromJson(rMap));
      }

      dailyReports = fetchedReports;
      dailyReport = fetchedReports.isNotEmpty ? fetchedReports.first : null;

      // 3. Fetch Supervisor Reviews - try by review_date, then created_at
      List supervisorRes = [];
      try {
        supervisorRes = await _supabase
            .from('student_reviews')
            .select()
            .eq('student_id', student!.id)
            .eq('review_date', dateString);
      } catch (_) {}

      // Fallback by created_at
      if (supervisorRes.isEmpty) {
        try {
          supervisorRes = await _supabase
              .from('student_reviews')
              .select()
              .eq('student_id', student!.id)
              .gte('created_at', '${dateString}T00:00:00')
              .lte('created_at', '${dateString}T23:59:59');
        } catch (_) {}
      }

      todayReviews = supervisorRes
          .map((e) => SupervisorReviewModel.fromJson(e as Map<String, dynamic>))
          .toList();

      // 4. Fetch Weekly Report (get the latest evaluation for this student on or before the selected date)
      final weeklyRes = await _supabase
          .from('weekly_evaluations')
          .select()
          .eq('student_id', student!.id)
          .lte('created_at', '${dateString}T23:59:59Z')
          .order('created_at', ascending: false)
          .limit(1)
          .maybeSingle();

      if (weeklyRes != null) {
        weeklyReport = WeeklyReportModel.fromJson(weeklyRes);
      } else {
        weeklyReport = null;
      }
    } catch (e) {
      errorMessage = 'حدث خطأ أثناء تحديث التقارير: $e';
      debugPrint('StudentProvider error: $e');
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  /// Fetch all weekly evaluations for a given week number + year
  Future<void> fetchWeeklyReports(int week, int year) async {
    if (student == null) return;

    selectedWeek = week;
    selectedYear = year;
    isLoadingWeekly = true;
    notifyListeners();

    try {
      final startOfYear = DateTime(year, 1, 1);
      final startOfWeek = startOfYear.add(Duration(days: (week - 1) * 7));
      final endOfWeek = startOfWeek.add(
          const Duration(days: 6, hours: 23, minutes: 59, seconds: 59));

      final startStr = startOfWeek.toIso8601String().split('T')[0];
      final endStr = endOfWeek.toIso8601String().split('T')[0];

      final res = await _supabase
          .from('weekly_evaluations')
          .select()
          .eq('student_id', student!.id)
          .gte('created_at', '${startStr}T00:00:00Z')
          .lte('created_at', '${endStr}T23:59:59Z')
          .order('created_at', ascending: false);

      List<WeeklyReportModel> fetchedWeekly = [];
      for (var w in (res as List)) {
        String? tName    = w['teacher_name']?.toString();   // already stored?
        String? tPhoto   = w['teacher_photo_url']?.toString();
        String? tSubject = w['subject']?.toString() ?? w['category']?.toString();
        final String? tId = w['teacher_id']?.toString();

        if ((tName == null || tName.isEmpty) && tId != null) {
          try {
            final p = await _supabase
                .from('profiles')
                .select('full_name, avatar_url')
                .eq('id', tId)
                .maybeSingle();
            if (p != null) {
              tName  ??= p['full_name']?.toString();
              tPhoto ??= p['avatar_url']?.toString();
            }
          } catch (_) {}

          try {
            final t = await _supabase
                .from('teachers')
                .select('full_name, name, category')
                .eq('id', tId)
                .maybeSingle();
            if (t != null) {
              tName    ??= t['full_name']?.toString() ?? t['name']?.toString();
              tSubject ??= t['category']?.toString();
            }
          } catch (_) {}
        }

        final wMap = Map<String, dynamic>.from(w);
        wMap['teacher_name']      = (tName != null && tName.isNotEmpty) ? tName : 'المدرس';
        wMap['teacher_photo_url'] = tPhoto;
        wMap['subject']           = (tSubject != null && tSubject.isNotEmpty) ? tSubject : 'أسبوعي';
        fetchedWeekly.add(WeeklyReportModel.fromJson(wMap));
      }

      weeklyReports = fetchedWeekly;
    } catch (e) {
      debugPrint('fetchWeeklyReports error: $e');
      weeklyReports = [];
    } finally {
      isLoadingWeekly = false;
      notifyListeners();
    }
  }

  void changeDate(DateTime newDate) {
    fetchReportsForDate(newDate);
  }

  void changeWeek(int week, int year) {
    fetchWeeklyReports(week, year);
  }

  @override
  void dispose() {
    _dailyReportsChannel?.unsubscribe();
    _supervisorReviewsChannel?.unsubscribe();
    _weeklyEvaluationsChannel?.unsubscribe();
    super.dispose();
  }
}

