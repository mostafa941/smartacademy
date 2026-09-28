import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

class AdminProvider extends ChangeNotifier {
  final SupabaseClient _supabase = Supabase.instance.client;

  // بيانات الأدمن (الاسم والوصف) للعرض في الـ Sidebar
  String _adminName = 'مدير النظام';
  String get adminName => _adminName;

  String _adminDescription = 'الأدمن الرئيسي';
  String get adminDescription => _adminDescription;

  // تحديث بيانات الأدمن (الاسم والوصف)
  void updateAdminSettings({required String name, required String description}) {
    _adminName = name.trim().isNotEmpty ? name.trim() : 'مدير النظام';
    _adminDescription = description.trim().isNotEmpty ? description.trim() : 'الأدمن الرئيسي';
    notifyListeners();
  }
  bool _isLoading = false;
  bool get isLoading => _isLoading;

  int _selectedNavIndex = 0;
  int get selectedNavIndex => _selectedNavIndex;

  String _searchQuery = '';
  String get searchQuery => _searchQuery;

  String _teacherSearchQuery = '';
  String get teacherSearchQuery => _teacherSearchQuery;

  List<Map<String, dynamic>> _profiles = [];
  List<Map<String, dynamic>> _students = [];
  List<Map<String, dynamic>> _teachers = [];
  List<Map<String, dynamic>> _dailyReports = [];

  // الطالب المنسق لعرض صفحة التفاصيل
  Map<String, dynamic>? _selectedStudent;
  Map<String, dynamic>? get selectedStudent => _selectedStudent;

  // المدرس المنسق لعرض صفحة التفاصيل
  Map<String, dynamic>? _selectedTeacher;
  Map<String, dynamic>? get selectedTeacher => _selectedTeacher;

  int teacherAttendanceCount = 0;
  int teacherStudentsCount = 0;
  List<String> teacherStagesList = [];

  List<Map<String, dynamic>> get students => _students;
  List<Map<String, dynamic>> get teachers => _teachers;

  // Getters مضافة لحل المشكلة وتوفير قائمة الطلاب مباشرة للـ Views
  List<Map<String, dynamic>> get studentsList => _students;
  List<Map<String, dynamic>> get teacherStudents => _students;

  void setNavIndex(int index) {
    _selectedNavIndex = index;
    notifyListeners();
  }

  void setSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  void setTeacherSearchQuery(String query) {
    _teacherSearchQuery = query;
    notifyListeners();
  }

  // اختيار/إلغاء اختيار الطالب لعرض شاشة الملف
  void selectStudent(Map<String, dynamic>? student) {
    _selectedStudent = student;
    notifyListeners();
  }

  // اختيار/إلغاء اختيار المدرس لعرض شاشة التفاصيل
  void selectTeacher(Map<String, dynamic> teacher) async {
    _selectedTeacher = teacher;
    notifyListeners();
    await fetchTeacherDetails(teacher['id'], teacher['age_group']);
  }

  void clearSelectedTeacher() {
    _selectedTeacher = null;
    notifyListeners();
  }

  // جلب تفاصيل المدرس (الحضور والطلاب والمراحل)
  Future<void> fetchTeacherDetails(String teacherId, String ageGroup) async {
    try {
      // 1. عدد أيام الحضور
      final attendanceRes = await _supabase
          .from('teacher_attendance')
          .select('id')
          .eq('teacher_id', teacherId);
      teacherAttendanceCount = (attendanceRes as List).length;

      // 2. معالجة المراحل المتعددة (مثل "KG1, KG2")
      List<String> stages = [];
      if (ageGroup.isNotEmpty && ageGroup != 'غير محدد') {
        stages = ageGroup
            .split(',')
            .map((s) => s.trim())
            .where((s) => s.isNotEmpty)
            .toList();
      }

      // 3. جلب قائمة المراحل المرتبطة بالمدرس من قاعدة البيانات
      final stagesRes = await _supabase
          .from('teacher_stages')
          .select('stages(name)')
          .eq('teacher_id', teacherId);

      teacherStagesList = (stagesRes as List)
          .map((e) => e['stages']?['name']?.toString() ?? '')
          .where((name) => name.isNotEmpty)
          .toList();

      if (teacherStagesList.isEmpty) {
        teacherStagesList = stages;
      }

      // 4. حساب عدد الطلاب الإجمالي المسجلين في أي من مراحل المدرس
      if (stages.isNotEmpty) {
        final studentsRes = await _supabase
            .from('students')
            .select('id')
            .filter('age_group', 'in', stages);
        teacherStudentsCount = (studentsRes as List).length;
      } else {
        teacherStudentsCount = 0;
      }

      notifyListeners();
    } catch (e) {
      debugPrint('Error fetching teacher details: $e');
    }
  }

  // حذف مدرس
  Future<bool> deleteTeacher(String teacherId) async {
    try {
      await _supabase.from('profiles').delete().eq('id', teacherId);
      clearSelectedTeacher();
      await fetchDashboardData();
      return true;
    } catch (e) {
      debugPrint('Error deleting teacher: $e');
      return false;
    }
  }

  List<Map<String, dynamic>> get filteredStudents {
    if (_searchQuery.trim().isEmpty) return _students;
    final q = _searchQuery.toLowerCase().trim();
    return _students.where((s) {
      final name = (s['full_name'] ?? '').toString().toLowerCase();
      final phone = (s['parent_phone'] ?? '').toString().toLowerCase();
      return name.contains(q) || phone.contains(q);
    }).toList();
  }

  // قائمة المدرسين المفلترة للبحث
  List<Map<String, dynamic>> get filteredTeachers {
    if (_teacherSearchQuery.trim().isEmpty) return _teachers;
    final q = _teacherSearchQuery.toLowerCase().trim();
    return _teachers.where((t) {
      final name = (t['full_name'] ?? '').toString().toLowerCase();
      final subject = (t['subject'] ?? '').toString().toLowerCase();
      final phone = (t['phone'] ?? '').toString().toLowerCase();
      final ageGroup = (t['age_group'] ?? '').toString().toLowerCase();
      return name.contains(q) ||
          subject.contains(q) ||
          phone.contains(q) ||
          ageGroup.contains(q);
    }).toList();
  }

  Future<void> fetchDashboardData() async {
    _setLoading(true);
    try {
      // 1. جلب بيانات المستخدمين الأساسية
      final profilesRes = await _supabase.from('profiles').select();
      _profiles = List<Map<String, dynamic>>.from(profilesRes);

      // 2. جلب المدرسين بالتكامل مع teacher_stages و teacher_subjects و stages و subjects
      final teachersRes = await _supabase.from('profiles').select('''
        id,
        full_name,
        phone,
        avatar_url,
        teacher_stages (
          stages ( name )
        ),
        teacher_subjects (
          subjects ( name )
        )
      ''').eq('role', 'teacher');

      _teachers = List<Map<String, dynamic>>.from(teachersRes).map((t) {
        final List stagesList = (t['teacher_stages'] as List?) ?? [];
        final List<String> stageNames = stagesList
            .map((s) => s['stages']?['name']?.toString() ?? '')
            .where((name) => name.isNotEmpty)
            .toList();

        final List subjectsList = (t['teacher_subjects'] as List?) ?? [];
        final List<String> subjectNames = subjectsList
            .map((s) => s['subjects']?['name']?.toString() ?? '')
            .where((name) => name.isNotEmpty)
            .toList();

        return {
          'id': t['id'],
          'full_name': t['full_name'] ?? '',
          'phone': t['phone'] ?? '',
          'avatar_url': t['avatar_url'],
          'age_group': stageNames.isNotEmpty ? stageNames.join(', ') : 'غير محدد',
          'subject': subjectNames.isNotEmpty ? subjectNames.join(', ') : 'غير محدد',
        };
      }).toList();

      // 3. جلب الطلاب والتقارير اليومية
      final studentsRes = await _supabase.from('students').select('*');
      _students = List<Map<String, dynamic>>.from(studentsRes);

      final reportsRes = await _supabase.from('daily_reports').select();
      _dailyReports = List<Map<String, dynamic>>.from(reportsRes);

      if (_selectedStudent != null) {
        final updated =
            _students.where((s) => s['id'] == _selectedStudent!['id']).toList();
        if (updated.isNotEmpty) {
          _selectedStudent = updated.first;
        } else {
          _selectedStudent = null;
        }
      }
    } catch (e) {
      debugPrint('Error fetching data: $e');
    } finally {
      _setLoading(false);
    }
  }

  // إضافة مدرس مع دعم استقبال قائمة بالمراحل التعليمية Multiple Age Groups
  Future<bool> addTeacher({
    required String fullName,
    required String phone,
    required String subject,
    required List<String> ageGroups,
  }) async {
    try {
      final profileRes = await _supabase
          .from('profiles')
          .insert({
            'full_name': fullName,
            'phone': phone,
            'role': 'teacher',
          })
          .select()
          .single();

      final String teacherId = profileRes['id'];

      // تكرار على كل مرحلة في القائمة وإضافتها لجدول teacher_stages
      for (String ageGroup in ageGroups) {
        if (ageGroup.trim().isNotEmpty) {
          var stageRes = await _supabase
              .from('stages')
              .select('id')
              .eq('name', ageGroup.trim())
              .maybeSingle();

          dynamic stageId;
          if (stageRes == null) {
            final newStage = await _supabase
                .from('stages')
                .insert({'name': ageGroup.trim()})
                .select()
                .single();
            stageId = newStage['id'];
          } else {
            stageId = stageRes['id'];
          }

          await _supabase.from('teacher_stages').insert({
            'teacher_id': teacherId,
            'stage_id': stageId,
          });
        }
      }

      if (subject.trim().isNotEmpty) {
        var subjectRes = await _supabase
            .from('subjects')
            .select('id')
            .eq('name', subject.trim())
            .maybeSingle();

        dynamic subjectId;
        if (subjectRes == null) {
          final newSubject = await _supabase
              .from('subjects')
              .insert({'name': subject.trim()})
              .select()
              .single();
          subjectId = newSubject['id'];
        } else {
          subjectId = subjectRes['id'];
        }

        await _supabase.from('teacher_subjects').insert({
          'teacher_id': teacherId,
          'subject_id': subjectId,
        });
      }

      await fetchDashboardData();
      return true;
    } catch (e) {
      debugPrint('Error adding teacher: $e');
      return false;
    }
  }

  // تعديل بيانات المدرس (الاسم، الهاتف، المادة، والمراحل التعليمية)
  Future<bool> updateTeacher({
    required String teacherId,
    required String fullName,
    required String phone,
    required String subject,
    required List<String> ageGroups,
  }) async {
    try {
      // 1. تحديث الاسم ورقم الهاتف في جدول profiles
      await _supabase.from('profiles').update({
        'full_name': fullName,
        'phone': phone,
      }).eq('id', teacherId);

      // 2. تحديث المراحل التعليمية (حذف القديمة ثم إضافة الجديدة)
      await _supabase.from('teacher_stages').delete().eq('teacher_id', teacherId);

      for (String ageGroup in ageGroups) {
        if (ageGroup.trim().isNotEmpty) {
          var stageRes = await _supabase
              .from('stages')
              .select('id')
              .eq('name', ageGroup.trim())
              .maybeSingle();

          dynamic stageId;
          if (stageRes == null) {
            final newStage = await _supabase
                .from('stages')
                .insert({'name': ageGroup.trim()})
                .select()
                .single();
            stageId = newStage['id'];
          } else {
            stageId = stageRes['id'];
          }

          await _supabase.from('teacher_stages').insert({
            'teacher_id': teacherId,
            'stage_id': stageId,
          });
        }
      }

      // 3. تحديث المادة الدراسية (حذف القديمة ثم إضافة الجديدة)
      await _supabase.from('teacher_subjects').delete().eq('teacher_id', teacherId);

      if (subject.trim().isNotEmpty) {
        var subjectRes = await _supabase
            .from('subjects')
            .select('id')
            .eq('name', subject.trim())
            .maybeSingle();

        dynamic subjectId;
        if (subjectRes == null) {
          final newSubject = await _supabase
              .from('subjects')
              .insert({'name': subject.trim()})
              .select()
              .single();
          subjectId = newSubject['id'];
        } else {
          subjectId = subjectRes['id'];
        }

        await _supabase.from('teacher_subjects').insert({
          'teacher_id': teacherId,
          'subject_id': subjectId,
        });
      }

      await fetchDashboardData();
      return true;
    } catch (e) {
      debugPrint('Error updating teacher: $e');
      return false;
    }
  }

  int getStudentPresentCount(dynamic studentId) {
    return _dailyReports
        .where((r) =>
            r['student_id'] == studentId &&
            (r['status'] == 'present' || r['attendance'] == true))
        .length;
  }

  int getStudentAbsentCount(dynamic studentId) {
    return _dailyReports
        .where((r) =>
            r['student_id'] == studentId &&
            (r['status'] == 'absent' || r['attendance'] == false))
        .length;
  }

  String getStudentLatestNote(dynamic studentId) {
    final studentReports = _dailyReports
        .where((r) =>
            r['student_id'] == studentId &&
            r['note'] != null &&
            r['note'].toString().trim().isNotEmpty)
        .toList();

    if (studentReports.isEmpty) return 'لا يوجد';
    return studentReports.last['note'].toString();
  }

  String getStudentAttendanceRate(dynamic studentId) {
    if (_dailyReports.isEmpty) return '0%';

    final studentReports =
        _dailyReports.where((r) => r['student_id'] == studentId).toList();

    if (studentReports.isEmpty) return '0%';

    final presentCount = studentReports
        .where((r) => r['status'] == 'present' || r['attendance'] == true)
        .length;

    final double rate = (presentCount / studentReports.length) * 100;
    return '${rate.toStringAsFixed(0)}%';
  }

  String get attendancePercentage {
    if (_dailyReports.isEmpty) return '0%';
    final presentCount = _dailyReports
        .where((r) => r['status'] == 'present' || r['attendance'] == true)
        .length;
    final double rate = (presentCount / _dailyReports.length) * 100;
    return '${rate.toStringAsFixed(0)}%';
  }

  Future<bool> addStudent({
    required String fullName,
    required String parentPhone,
    required String ageGroup,
  }) async {
    try {
      // 1. إضافة الطالب واسترجاع بياناته
      final studentRes = await _supabase.from('students').insert({
        'full_name': fullName,
        'parent_phone': parentPhone,
        'age_group': ageGroup,
      }).select().single();

      final studentId = studentRes['id'];

      // 2. جلب المرحلة من جدول stages للحصول على stage_id
      final stageRes = await _supabase
          .from('stages')
          .select('id')
          .eq('name', ageGroup.trim())
          .maybeSingle();

      if (stageRes != null) {
        final stageId = stageRes['id'];

        // 3. جلب المعلمين المرتبطين بهذه المرحلة مباشرة من teacher_stages
        final teacherStagesRes = await _supabase
            .from('teacher_stages')
            .select('teacher_id')
            .eq('stage_id', stageId);

        final List<String> teacherIds = (teacherStagesRes as List)
            .map((e) => e['teacher_id'].toString())
            .toList();

        if (teacherIds.isNotEmpty) {
          // 4. إنشاء إشعارات لهؤلاء المعلمين في Supabase
          final notificationsToInsert = teacherIds.map((teacherId) {
            return {
              'teacher_id': teacherId,
              'title': 'طالب جديد',
              'body': 'تم إضافة الطالب $fullName إلى مرحلة $ageGroup',
              'student_id': studentId,
              'is_read': false,
            };
          }).toList();

          await _supabase.from('notifications').insert(notificationsToInsert);
          debugPrint('Notifications sent to ${teacherIds.length} teachers for: $fullName');

          // 5. إرسال Push Notification عبر OneSignal (REST API) - اختياري
          const String oneSignalAppId = "YOUR_ONESIGNAL_APP_ID";
          const String restApiKey = "YOUR_ONESIGNAL_REST_API_KEY";

          if (oneSignalAppId != "YOUR_ONESIGNAL_APP_ID") {
            try {
              await http.post(
                Uri.parse('https://onesignal.com/api/v1/notifications'),
                headers: {
                  'Content-Type': 'application/json; charset=utf-8',
                  'Authorization': 'Basic $restApiKey',
                },
                body: jsonEncode({
                  'app_id': oneSignalAppId,
                  'include_external_user_ids': teacherIds,
                  'channel_for_external_user_ids': 'push',
                  'headings': {'en': 'طالب جديد', 'ar': 'طالب جديد'},
                  'contents': {
                    'en': 'تم إضافة الطالب $fullName إلى مرحلة $ageGroup',
                    'ar': 'تم إضافة الطالب $fullName إلى مرحلة $ageGroup',
                  },
                }),
              );
            } catch (pushErr) {
              debugPrint('Error sending OneSignal push: $pushErr');
            }
          }
        } else {
          debugPrint('No teachers found for stage: $ageGroup');
        }
      } else {
        debugPrint('Stage not found in DB: $ageGroup — no notifications sent');
      }

      await fetchDashboardData();
      return true;
    } catch (e) {
      debugPrint('Error adding student: $e');
      return false;
    }
  }


  Future<bool> updateStudent({
    required dynamic id,
    required String fullName,
    required String parentPhone,
    required String ageGroup,
  }) async {
    try {
      await _supabase.from('students').update({
        'full_name': fullName,
        'parent_phone': parentPhone,
        'age_group': ageGroup,
      }).eq('id', id);

      await fetchDashboardData();
      return true;
    } catch (e) {
      debugPrint('Error updating student: $e');
      return false;
    }
  }

  Future<bool> deleteStudent(dynamic id) async {
    try {
      await _supabase.from('students').delete().eq('id', id);
      _selectedStudent = null;
      await fetchDashboardData();
      return true;
    } catch (e) {
      debugPrint('Error deleting student: $e');
      return false;
    }
  }

  int get totalStudents => _students.length;
  int get totalTeachers => _teachers.length;

  void _setLoading(bool val) {
    _isLoading = val;
    notifyListeners();
  }
}