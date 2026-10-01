import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../providers/student_provider.dart';
import '../../../core/widgets/skeleton_loading.dart';

class StudentAttendanceHistoryTab extends StatefulWidget {
  const StudentAttendanceHistoryTab({super.key});

  @override
  State<StudentAttendanceHistoryTab> createState() =>
      _StudentAttendanceHistoryTabState();
}

class _StudentAttendanceHistoryTabState
    extends State<StudentAttendanceHistoryTab> {
  bool _isLoading = true;
  List<Map<String, dynamic>> _history = [];
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetchHistory();
  }

  Future<void> _fetchHistory() async {
    final studentId = context.read<StudentProvider>().student?.id;
    if (studentId == null) return;

    try {
      final res = await Supabase.instance.client
          .from('daily_reports')
          .select('report_date, attendance, status, created_at')
          .eq('student_id', studentId)
          .order('report_date', ascending: false);
          
      setState(() {
        _history = List<Map<String, dynamic>>.from(res);
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'حدث خطأ أثناء جلب سجل الحضور';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : const Color(0xFF2A1B38);
    final cardColor = isDark ? const Color(0xFF1E1E1E) : Colors.white;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 20),
          Text(
            'سجل الغياب والحضور',
            textAlign: TextAlign.right,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: textColor,
            ),
          ),
          const SizedBox(height: 20),
          Expanded(
            child: _isLoading
                ? const SkeletonListLoading(itemCount: 8)
                : _error != null
                    ? Center(
                        child: Text(
                          _error!,
                          style: const TextStyle(color: Colors.red),
                        ),
                      )
                    : _history.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.history_rounded,
                                    size: 60, color: Colors.grey.shade400),
                                const SizedBox(height: 16),
                                Text(
                                  'لا يوجد سجل حضور وغياب حتى الآن',
                                  style: TextStyle(
                                    color: Colors.grey.shade500,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          )
                        : ListView.builder(
                            itemCount: _history.length,
                            itemBuilder: (context, index) {
                              final item = _history[index];
                              // Fallback to created_at if report_date is somehow null
                              final dateStr = item['report_date'] ?? 
                                  (item['created_at'] != null 
                                      ? item['created_at'].toString().split('T')[0] 
                                      : 'غير معروف');
                              final bool isPresent = item['attendance'] == true || item['status'] == 'present';

                              return Container(
                                margin: const EdgeInsets.only(bottom: 12),
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: cardColor,
                                  borderRadius: BorderRadius.circular(16),
                                  boxShadow: isDark
                                      ? []
                                      : [
                                          BoxShadow(
                                            color: Colors.black.withOpacity(0.04),
                                            blurRadius: 8,
                                            offset: const Offset(0, 2),
                                          ),
                                        ],
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    // Status
                                    Row(
                                      children: [
                                        Container(
                                          width: 36,
                                          height: 36,
                                          decoration: BoxDecoration(
                                            shape: BoxShape.circle,
                                            color: isPresent
                                                ? Colors.green.withOpacity(0.15)
                                                : Colors.red.withOpacity(0.15),
                                          ),
                                          child: Icon(
                                            isPresent ? Icons.check : Icons.close,
                                            color: isPresent ? Colors.green : Colors.red,
                                            size: 20,
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        Text(
                                          isPresent ? 'حاضر' : 'غائب',
                                          style: TextStyle(
                                            color: isPresent ? Colors.green : Colors.red,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 16,
                                          ),
                                        ),
                                      ],
                                    ),
                                    // Date
                                    Row(
                                      children: [
                                        Text(
                                          dateStr,
                                          style: TextStyle(
                                            color: textColor,
                                            fontSize: 15,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Icon(
                                          Icons.calendar_today_rounded,
                                          size: 18,
                                          color: Colors.grey.shade400,
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
          ),
        ],
      ),
    );
  }
}
