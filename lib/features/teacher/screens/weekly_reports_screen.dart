import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/widgets/skeleton_loading.dart';

class WeeklyReportsScreen extends StatefulWidget {
  final String teacherId;

  const WeeklyReportsScreen({super.key, required this.teacherId});

  @override
  State<WeeklyReportsScreen> createState() => _WeeklyReportsScreenState();
}

class _WeeklyReportsScreenState extends State<WeeklyReportsScreen> {
  final SupabaseClient _supabase = Supabase.instance.client;

  bool _isLoading = true;
  int _selectedWeek = _getCurrentWeekNumber();
  int _selectedYear = DateTime.now().year;
  List<Map<String, dynamic>> _reports = [];

  static int _getCurrentWeekNumber() {
    final now = DateTime.now();
    final startOfYear = DateTime(now.year, 1, 1);
    final diff = now.difference(startOfYear);
    return ((diff.inDays + startOfYear.weekday) / 7).ceil();
  }

  @override
  void initState() {
    super.initState();
    _fetchReports();
  }

  Future<void> _fetchReports() async {
    setState(() => _isLoading = true);
    try {
      // Calculate start and end of selected week
      final startOfYear = DateTime(_selectedYear, 1, 1);
      final startOfWeek = startOfYear.add(Duration(days: (_selectedWeek - 1) * 7));
      final endOfWeek = startOfWeek.add(const Duration(days: 6, hours: 23, minutes: 59, seconds: 59));

      final startStr = startOfWeek.toIso8601String().split('T')[0];
      final endStr = endOfWeek.toIso8601String().split('T')[0];

      final reportsRes = await _supabase
          .from('weekly_evaluations')
          .select('*, students(full_name, age_group)')
          .gte('created_at', '${startStr}T00:00:00Z')
          .lte('created_at', '${endStr}T23:59:59Z')
          .order('created_at', ascending: false);

      setState(() {
        _reports = List<Map<String, dynamic>>.from(reportsRes);
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error fetching weekly reports: $e');
      setState(() {
        _reports = [];
        _isLoading = false;
      });
    }
  }

  // Get start/end dates of selected week for display
  String _getWeekDateRange() {
    final startOfYear = DateTime(_selectedYear, 1, 1);
    final startOfWeek = startOfYear.add(Duration(days: (_selectedWeek - 1) * 7));
    final endOfWeek = startOfWeek.add(const Duration(days: 6));

    final months = [
      '', 'يناير', 'فبراير', 'مارس', 'أبريل', 'مايو', 'يونيو',
      'يوليو', 'أغسطس', 'سبتمبر', 'أكتوبر', 'نوفمبر', 'ديسمبر'
    ];

    return '${startOfWeek.day} ${months[startOfWeek.month]} - ${endOfWeek.day} ${months[endOfWeek.month]}';
  }

  String _weekLabel(int week) {
    const ordinals = [
      '', 'الأول', 'الثاني', 'الثالث', 'الرابع', 'الخامس',
      'السادس', 'السابع', 'الثامن', 'التاسع', 'العاشر',
      'الحادي عشر', 'الثاني عشر', 'الثالث عشر', 'الرابع عشر', 'الخامس عشر',
      'السادس عشر', 'السابع عشر', 'الثامن عشر', 'التاسع عشر', 'العشرون',
      'الحادي والعشرون', 'الثاني والعشرون', 'الثالث والعشرون', 'الرابع والعشرون',
      'الخامس والعشرون', 'السادس والعشرون', 'السابع والعشرون', 'الثامن والعشرون',
      'التاسع والعشرون', 'الثلاثون', 'الحادي والثلاثون', 'الثاني والثلاثون',
      'الثالث والثلاثون', 'الرابع والثلاثون', 'الخامس والثلاثون',
      'السادس والثلاثون', 'السابع والثلاثون', 'الثامن والثلاثون',
      'التاسع والثلاثون', 'الأربعون', 'الحادي والأربعون', 'الثاني والأربعون',
      'الثالث والأربعون', 'الرابع والأربعون', 'الخامس والأربعون',
      'السادس والأربعون', 'السابع والأربعون', 'الثامن والأربعون',
      'التاسع والأربعون', 'الخمسون', 'الحادي والخمسون', 'الثاني والخمسون',
    ];
    if (week < 1 || week >= ordinals.length) return 'الأسبوع $week';
    return 'الأسبوع ${ordinals[week]}';
  }

  @override
  Widget build(BuildContext context) {
    final totalWeeks = 52;
    final currentWeek = _getCurrentWeekNumber();

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? Colors.black : const Color(0xFFE6E6FA);
    final textColor = isDark ? Colors.white : const Color(0xFF2A1B38);
    final cardColor = isDark ? const Color(0xFF1E1E1E) : Colors.white;

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: bgColor,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: textColor),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'سجل التقييمات الأسبوعية',
          style: TextStyle(
            color: textColor,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          // Week Selector Card
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF724F96),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        _getWeekDateRange(),
                        style: const TextStyle(color: Colors.white70, fontSize: 13),
                      ),
                      Text(
                        _weekLabel(_selectedWeek),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  // Week Navigation
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Next Week
                      GestureDetector(
                        onTap: _selectedWeek < totalWeeks
                            ? () {
                                setState(() => _selectedWeek++);
                                _fetchReports();
                              }
                            : null,
                        child: Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(
                                _selectedWeek < totalWeeks ? 0.2 : 0.05),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            Icons.chevron_left_rounded,
                            color: Colors.white.withOpacity(
                                _selectedWeek < totalWeeks ? 1 : 0.3),
                          ),
                        ),
                      ),
                      // Week Picker DropDown
                      GestureDetector(
                        onTap: () => _showWeekPicker(context, totalWeeks),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Row(
                            children: [
                              Icon(Icons.expand_more_rounded, color: Colors.white, size: 18),
                              SizedBox(width: 6),
                              Text(
                                'اختر أسبوع',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      // Previous Week
                      GestureDetector(
                        onTap: _selectedWeek > 1
                            ? () {
                                setState(() => _selectedWeek--);
                                _fetchReports();
                              }
                            : null,
                        child: Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.white
                                .withOpacity(_selectedWeek > 1 ? 0.2 : 0.05),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            Icons.chevron_right_rounded,
                            color: Colors.white
                                .withOpacity(_selectedWeek > 1 ? 1 : 0.3),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Count
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: cardColor,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '${_reports.length} تقييم',
                    style: const TextStyle(
                      color: Color(0xFF724F96),
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                ),
                Text(
                  'التقييمات الأسبوعية',
                  style: TextStyle(
                    color: textColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),

          // Reports List
          Expanded(
            child: _isLoading
                ? const SkeletonListLoading(itemCount: 6)
                : _reports.isEmpty
                    ? _buildEmpty(textColor)
                    : ListView.separated(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                        itemCount: _reports.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 12),
                        itemBuilder: (context, index) {
                          return _buildWeeklyCard(_reports[index], cardColor: cardColor, textColor: textColor);
                        },
                      ),
          ),
        ],
      ),
    );
  }

  void _showWeekPicker(BuildContext context, int totalWeeks) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return Column(
          children: [
            const SizedBox(height: 12),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'اختر الأسبوع',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: ListView.builder(
                itemCount: totalWeeks,
                itemBuilder: (_, i) {
                  final week = i + 1;
                  final isSelected = week == _selectedWeek;
                  return ListTile(
                    selected: isSelected,
                    selectedTileColor: const Color(0xFFE6E6FA),
                    onTap: () {
                      Navigator.pop(ctx);
                      setState(() => _selectedWeek = week);
                      _fetchReports();
                    },
                    trailing: Text(
                      _weekLabel(week),
                      style: TextStyle(
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                        color: isSelected ? const Color(0xFF724F96) : Colors.black87,
                        fontSize: 15,
                      ),
                    ),
                    leading: isSelected
                        ? const Icon(Icons.check_circle, color: Color(0xFF724F96))
                        : null,
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildEmpty(Color textColor) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.date_range_rounded, size: 80, color: Colors.grey.shade400),
          const SizedBox(height: 16),
          Text(
            'لا توجد تقييمات في هذا الأسبوع',
            style: TextStyle(
              color: textColor,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'اختر أسبوعاً آخر أو قم بإضافة تقييمات',
            style: TextStyle(color: Colors.grey.shade500, fontSize: 13),
          ),
        ],
      ),
    );
  }

  Widget _buildWeeklyCard(Map<String, dynamic> report, {required Color cardColor, required Color textColor}) {
    final student = report['students'] as Map<String, dynamic>?;
    final studentName = student?['full_name'] ?? 'طالب غير معروف';
    final ageGroup = student?['age_group'] ?? '';
    final initial = studentName.isNotEmpty ? studentName[0] : '?';
    final completedDuties = report['completed_duties'] == true;
    final completedLessons = report['completed_lessons']?.toString() ?? '';
    final note = report['note']?.toString() ?? '';
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final noteBg = isDark ? const Color(0xFF2A2A2A) : const Color(0xFFF5F5F5);
    final avatarBg = isDark ? const Color(0xFF2A3A4A) : const Color(0xFFE6E6FA);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: completedDuties ? Colors.green.shade50 : Colors.orange.shade50,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: completedDuties ? Colors.green.shade200 : Colors.orange.shade200,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      completedDuties ? Icons.task_alt_rounded : Icons.pending_rounded,
                      color: completedDuties ? Colors.green : Colors.orange,
                      size: 16,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      completedDuties ? 'أكمل الواجبات' : 'لم يكمل الواجبات',
                      style: TextStyle(
                        color: completedDuties ? Colors.green.shade700 : Colors.orange.shade700,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              Row(
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        studentName,
                        style: TextStyle(
                          color: textColor,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(ageGroup, style: const TextStyle(color: Colors.grey, fontSize: 12)),
                    ],
                  ),
                  const SizedBox(width: 10),
                  CircleAvatar(
                    radius: 20,
                    backgroundColor: avatarBg,
                    child: Text(
                      initial,
                      style: const TextStyle(
                        color: Color(0xFF724F96),
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),

          if (completedLessons.isNotEmpty) ...[
            const SizedBox(height: 12),
            Divider(height: 1, color: Colors.grey.withOpacity(0.2)),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Expanded(
                  child: Text(
                    completedLessons,
                    textAlign: TextAlign.right,
                    style: TextStyle(fontSize: 13, color: textColor),
                  ),
                ),
                const SizedBox(width: 8),
                const Text(
                  'الدروس المنجزة:',
                  style: TextStyle(
                    color: Colors.grey,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ],

          if (note.isNotEmpty) ...[
            const SizedBox(height: 10),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: noteBg,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Expanded(
                    child: Text(
                      note,
                      textAlign: TextAlign.right,
                      style: TextStyle(fontSize: 13, color: textColor),
                    ),
                  ),
                  const SizedBox(width: 6),
                  const Icon(Icons.notes_rounded, size: 16, color: Colors.grey),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
