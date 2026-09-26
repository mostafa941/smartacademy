import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'student_evaluation_screen.dart';

class TeacherHomeTab extends StatefulWidget {
  final String userId;
  final String userName;
  final String? filterCategory;

  const TeacherHomeTab({
    super.key,
    required this.userId,
    required this.userName,
    this.filterCategory,
  });

  @override
  State<TeacherHomeTab> createState() => _TeacherHomeTabState();
}

class _TeacherHomeTabState extends State<TeacherHomeTab> {
  final SupabaseClient _supabase = Supabase.instance.client;
  bool _isLoading = true;
  List<Map<String, dynamic>> _students = [];
  String _searchQuery = '';
  RealtimeChannel? _studentsChannel;

  @override
  void initState() {
    super.initState();
    _fetchStudents();
    _setupRealtimeStudents();
  }

  void _setupRealtimeStudents() {
    _studentsChannel = _supabase
        .channel('public:students')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'students',
          callback: (payload) {
            debugPrint('🔄 Student table changed. Refreshing list...');
            _fetchStudents();
          },
        )
        .subscribe();
  }

  @override
  void dispose() {
    _studentsChannel?.unsubscribe();
    super.dispose();
  }

  Future<void> _fetchStudents() async {
    setState(() => _isLoading = true);
    try {
      final stagesRes = await _supabase
          .from('teacher_stages')
          .select('stages(name)')
          .eq('teacher_id', widget.userId);

      List<String> teacherStages = (stagesRes as List)
          .map((e) => e['stages']?['name']?.toString() ?? '')
          .where((name) => name.isNotEmpty)
          .toList();

      if (teacherStages.isEmpty) {
        if (mounted) setState(() { _students = []; _isLoading = false; });
        return;
      }

      if (widget.filterCategory != null && widget.filterCategory!.isNotEmpty) {
        if (teacherStages.contains(widget.filterCategory)) {
          teacherStages = [widget.filterCategory!];
        } else {
          teacherStages = [];
        }
      }

      if (teacherStages.isEmpty) {
        if (mounted) setState(() { _students = []; _isLoading = false; });
        return;
      }

      final studentsRes = await _supabase
          .from('students')
          .select('*')
          .filter('age_group', 'in', teacherStages);

      List<Map<String, dynamic>> studentsData =
          List<Map<String, dynamic>>.from(studentsRes);

      final todayStr = DateTime.now().toIso8601String().split('T')[0];
      final reportsRes = await _supabase
          .from('daily_reports')
          .select('*')
          .eq('teacher_id', widget.userId)
          .gte('created_at', '${todayStr}T00:00:00Z')
          .lte('created_at', '${todayStr}T23:59:59Z');

      List<Map<String, dynamic>> todayReports =
          List<Map<String, dynamic>>.from(reportsRes);

      for (var student in studentsData) {
        final report =
            todayReports.where((r) => r['student_id'] == student['id']).toList();
        if (report.isNotEmpty) {
          final status = report.last['status'];
          final attendance = report.last['attendance'];
          student['is_present'] = status == 'present' || attendance == true;
          student['is_evaluated'] = true;
        } else {
          student['is_present'] = false;
          student['is_evaluated'] = false;
        }
      }

      if (mounted) {
        setState(() {
          _students = studentsData;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error fetching students: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  List<Map<String, dynamic>> get _filteredStudents {
    if (_searchQuery.trim().isEmpty) return _students;
    final q = _searchQuery.toLowerCase().trim();
    return _students.where((s) {
      final name = (s['full_name'] ?? '').toString().toLowerCase();
      return name.contains(q);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : const Color(0xFF2A1B38);
    final cardColor = isDark ? const Color(0xFF1E1E1E) : Colors.white;
    final searchBg = isDark ? const Color(0xFF1E1E1E) : Colors.white;
    final hintColor = isDark
        ? Colors.white38
        : const Color(0xFF2A1B38).withOpacity(0.5);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 20),
          // Search Bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: searchBg,
              borderRadius: BorderRadius.circular(24),
              boxShadow: isDark
                  ? []
                  : [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    textAlign: TextAlign.right,
                    style: TextStyle(color: textColor),
                    onChanged: (val) => setState(() => _searchQuery = val),
                    decoration: InputDecoration(
                      hintText: 'بحث عن اسم الطالب...',
                      hintStyle: TextStyle(
                        color: hintColor,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                      border: InputBorder.none,
                    ),
                  ),
                ),
                Icon(Icons.search, color: hintColor),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Text(
            widget.filterCategory == null
                ? 'الطلاب - الفئة العمرية (جميع الفئات)'
                : 'الطلاب - الفئة العمرية (${widget.filterCategory})',
            textAlign: TextAlign.right,
            style: TextStyle(
              color: textColor,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(color: Color(0xFF724F96)))
                : _filteredStudents.isEmpty
                    ? Center(
                        child: Text(
                          'لا يوجد طلاب في هذه الفئة',
                          style: TextStyle(
                            color: textColor,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      )
                    : ListView.separated(
                        itemCount: _filteredStudents.length,
                        separatorBuilder: (context, index) =>
                            const SizedBox(height: 12),
                        itemBuilder: (context, index) {
                          final student = _filteredStudents[index];
                          final name = student['full_name'] ?? 'بدون اسم';
                          final category = student['age_group'] ?? '';
                          final initial =
                              name.isNotEmpty ? name[0] : '?';
                          final isEvaluated =
                              student['is_evaluated'] ?? false;
                          final isPresent = student['is_present'] ?? false;

                          return GestureDetector(
                            onTap: () async {
                              await Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) => StudentEvaluationScreen(
                                    studentId: student['id'].toString(),
                                    teacherId: widget.userId,
                                    studentName: name,
                                    category: category,
                                    initial: initial,
                                    photoUrl: student['photo_url'] as String?,
                                  ),
                                ),
                              );
                              _fetchStudents();
                            },
                            child: _buildStudentCard(
                              name: name,
                              category: category,
                              initial: initial,
                              photoUrl: student['photo_url'] as String?,
                              isEvaluated: isEvaluated,
                              isPresent: isPresent,
                              cardColor: cardColor,
                              textColor: textColor,
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildStudentCard({
    required String name,
    required String category,
    required String initial,
    String? photoUrl,
    required bool isEvaluated,
    required bool isPresent,
    required Color cardColor,
    required Color textColor,
  }) {
    final avatarBg = Theme.of(context).brightness == Brightness.dark
        ? const Color(0xFF2A2A2A)
        : const Color(0xFFEEEEEE);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Status indicator (left side in RTL = visual right)
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: !isEvaluated
                  ? Colors.grey.shade400
                  : (isPresent ? Colors.green : Colors.red),
            ),
            child: Icon(
              !isEvaluated
                  ? Icons.horizontal_rule
                  : (isPresent ? Icons.check : Icons.close),
              color: Colors.white,
              size: 16,
            ),
          ),
          // Name and avatar (right side in RTL = visual left)
          Row(
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    name,
                    style: TextStyle(
                      color: textColor,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    'الفئة: $category',
                    style: const TextStyle(
                      color: Colors.grey,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 12),
              CircleAvatar(
                radius: 22,
                backgroundColor: avatarBg,
                backgroundImage: photoUrl != null && photoUrl.isNotEmpty
                    ? NetworkImage(photoUrl)
                    : null,
                child: photoUrl == null || photoUrl.isEmpty
                    ? Text(
                        initial,
                        style: TextStyle(
                          color: textColor,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      )
                    : null,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
