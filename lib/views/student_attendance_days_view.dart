import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class StudentAttendanceDaysView extends StatefulWidget {
  final String studentId;
  final String studentName;
  final bool showPresent; // true = حضور, false = غياب

  const StudentAttendanceDaysView({
    super.key,
    required this.studentId,
    required this.studentName,
    required this.showPresent,
  });

  @override
  State<StudentAttendanceDaysView> createState() => _StudentAttendanceDaysViewState();
}

class _StudentAttendanceDaysViewState extends State<StudentAttendanceDaysView> {
  final SupabaseClient _supabase = Supabase.instance.client;
  bool _isLoading = true;
  List<Map<String, dynamic>> _days = [];

  @override
  void initState() {
    super.initState();
    _fetchDays();
  }

  Future<void> _fetchDays() async {
    setState(() => _isLoading = true);
    try {
      // Fetch all reports for this student
      final res = await _supabase
          .from('daily_reports')
          .select('*')
          .eq('student_id', widget.studentId)
          .order('created_at', ascending: false);

      final all = List<Map<String, dynamic>>.from(res);

      // Filter based on present/absent
      final filtered = all.where((r) {
        final isPresent = r['status'] == 'present' || r['attendance'] == true;
        return widget.showPresent ? isPresent : !isPresent;
      }).toList();

      setState(() {
        _days = filtered;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error fetching student attendance: $e');
      setState(() => _isLoading = false);
    }
  }

  String _formatDate(String? isoDate) {
    if (isoDate == null) return 'تاريخ غير معروف';
    try {
      final dt = DateTime.parse(isoDate).toLocal();
      const days = ['الاثنين', 'الثلاثاء', 'الأربعاء', 'الخميس', 'الجمعة', 'السبت', 'الأحد'];
      const months = [
        '', 'يناير', 'فبراير', 'مارس', 'أبريل', 'مايو', 'يونيو',
        'يوليو', 'أغسطس', 'سبتمبر', 'أكتوبر', 'نوفمبر', 'ديسمبر'
      ];
      return '${days[dt.weekday - 1]}  ${dt.day} ${months[dt.month]} ${dt.year}';
    } catch (_) {
      return isoDate;
    }
  }

  String _formatTime(String? isoDate) {
    if (isoDate == null) return '';
    try {
      final dt = DateTime.parse(isoDate).toLocal();
      return DateFormat('hh:mm a').format(dt);
    } catch (_) {
      return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    final isPresent = widget.showPresent;
    final color = isPresent ? Colors.green : Colors.red;
    final label = isPresent ? 'أيام الحضور' : 'أيام الغياب';
    final icon = isPresent ? Icons.how_to_reg_rounded : Icons.person_off_rounded;
    final dayLabel = isPresent ? 'حاضر' : 'غائب';

    return Scaffold(
      backgroundColor: const Color(0xFFE6E6FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF2A1B38)),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: const TextStyle(
                color: Color(0xFF2A1B38),
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              widget.studentName,
              style: const TextStyle(color: Colors.grey, fontSize: 12),
            ),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _buildBody(isPresent, color, label, icon, dayLabel),
    );
  }

  Widget _buildBody(bool isPresent, Color color, String label, IconData icon, String dayLabel) {
    // Special case: no absences at all
    if (!isPresent && _days.isEmpty) {
      return _buildNeverAbsent();
    }

    if (_days.isEmpty) {
      return _buildEmpty(isPresent);
    }

    return Column(
      children: [
        // Summary Card
        Padding(
          padding: const EdgeInsets.all(20),
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: isPresent
                    ? [const Color(0xFF1E7D34), const Color(0xFF34A853)]
                    : [const Color(0xFFB71C1C), const Color(0xFFE53935)],
                begin: Alignment.topRight,
                end: Alignment.bottomLeft,
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Icon(icon, color: Colors.white70, size: 40),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      'إجمالي $label',
                      style: const TextStyle(color: Colors.white70, fontSize: 13),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${_days.length} يوم',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),

        // List
        Expanded(
          child: ListView.separated(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
            itemCount: _days.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (context, index) {
              final day = _days[index];
              final createdAt = day['created_at']?.toString();
              final note = day['note']?.toString() ?? '';

              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.04),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // Time + Badge
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _formatTime(createdAt),
                              style: const TextStyle(color: Colors.grey, fontSize: 12),
                            ),
                            const SizedBox(height: 4),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: color.withOpacity(0.08),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                dayLabel,
                                style: TextStyle(
                                  color: color,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                        // Date + Icon
                        Row(
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  _formatDate(createdAt),
                                  style: const TextStyle(
                                    color: Color(0xFF2A1B38),
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                  ),
                                ),
                                Text(
                                  'سجل رقم ${_days.length - index}',
                                  style: const TextStyle(color: Colors.grey, fontSize: 12),
                                ),
                              ],
                            ),
                            const SizedBox(width: 12),
                            Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color: color.withOpacity(0.08),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Icon(
                                isPresent ? Icons.check_circle_rounded : Icons.cancel_rounded,
                                color: color,
                                size: 22,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    // Note if exists
                    if (note.isNotEmpty) ...[
                      const SizedBox(height: 10),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF5F5F5),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          note,
                          textAlign: TextAlign.right,
                          style: const TextStyle(fontSize: 12, color: Color(0xFF2A1B38)),
                        ),
                      ),
                    ],
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildNeverAbsent() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              color: Colors.green.shade50,
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.stars_rounded, size: 64, color: Colors.green.shade400),
          ),
          const SizedBox(height: 24),
          const Text(
            '🎉 الطالب لم يغب أبداً!',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Color(0xFF2A1B38),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'سجل حضور مثالي - لا يوجد أي غياب مسجل',
            style: TextStyle(fontSize: 14, color: Colors.grey.shade500),
          ),
        ],
      ),
    );
  }

  Widget _buildEmpty(bool isPresent) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            isPresent ? Icons.event_busy_rounded : Icons.check_circle_outline_rounded,
            size: 80,
            color: Colors.grey.shade300,
          ),
          const SizedBox(height: 16),
          Text(
            isPresent ? 'لا توجد أيام حضور مسجلة' : 'لا توجد أيام غياب مسجلة',
            style: TextStyle(
              color: Colors.grey.shade500,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
