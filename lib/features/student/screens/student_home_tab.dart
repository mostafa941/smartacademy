import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/student_provider.dart';
import '../widgets/date_filter_widget.dart';

class StudentHomeTab extends StatelessWidget {
  final String userId;
  final String userName;

  const StudentHomeTab({
    super.key,
    required this.userId,
    required this.userName,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : const Color(0xFF2A1B38);
    final cardColor = isDark ? const Color(0xFF1E1E1E) : Colors.white;
    final provider = context.watch<StudentProvider>();

    final studentName = (provider.student?.name != null && provider.student!.name.trim().isNotEmpty)
        ? provider.student!.name
        : (userName.trim().isNotEmpty ? userName : 'طالب');

    final studentGrade = (provider.student?.grade != null && provider.student!.grade.trim().isNotEmpty)
        ? provider.student!.grade
        : 'غير محدد';

    final initial = studentName.isNotEmpty ? studentName[0] : '?';

    return RefreshIndicator(
      color: const Color(0xFF724F96),
      onRefresh: () => provider.fetchStudentData(userId, isParentPhone: false),
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 20),

            // ── Welcome Card ──
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: cardColor,
                borderRadius: BorderRadius.circular(24),
                boxShadow: isDark
                    ? []
                    : [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.06),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 28,
                    backgroundColor:
                        isDark ? const Color(0xFF2A2A2A) : const Color(0xFFEEEEEE),
                    backgroundImage: provider.student?.photoUrl != null && provider.student!.photoUrl!.isNotEmpty
                        ? CachedNetworkImageProvider(provider.student!.photoUrl!)
                        : null,
                    child: provider.student?.photoUrl == null || provider.student!.photoUrl!.isEmpty
                        ? Text(
                            initial,
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: textColor,
                            ),
                          )
                        : null,
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'أهلاً $studentName 👋',
                          style: TextStyle(
                            color: textColor,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'الصف: $studentGrade',
                          style: const TextStyle(
                            color: Colors.grey,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // ── Date Filter ──
            const DateFilterWidget(),

            const SizedBox(height: 16),

            // ── Attendance Card ──
            _buildSectionTitle('حالة الحضور', textColor),
            const SizedBox(height: 10),
            _buildAttendanceCard(provider, cardColor, textColor, isDark),

            const SizedBox(height: 20),

            // ── Daily Activity Card ──
            _buildSectionTitle('النشاط اليومي', textColor),
            const SizedBox(height: 10),
            _buildDailyActivityCard(provider, cardColor, textColor, isDark),

            const SizedBox(height: 20),

            // ── Weekly Report Section ──
            if (provider.weeklyReport != null) ...[
              _buildSectionTitle('التقرير الأسبوعي', textColor),
              const SizedBox(height: 10),
              _buildWeeklyCard(provider, cardColor, textColor, isDark),
              const SizedBox(height: 20),
            ],

            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title, Color textColor) {
    return Text(
      title,
      textAlign: TextAlign.right,
      style: TextStyle(
        color: textColor,
        fontSize: 16,
        fontWeight: FontWeight.bold,
      ),
    );
  }

  Widget _buildAttendanceCard(
      StudentProvider provider, Color cardColor, Color textColor, bool isDark) {
    final report = provider.dailyReport;
    final bool isPresent = report?.isPresent ?? false;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(24),
        boxShadow: isDark
            ? []
            : [
                BoxShadow(
                  color: Colors.black.withOpacity(0.06),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
      ),
      child: report == null
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Text('لا يوجد تقرير لهذا اليوم',
                    style: TextStyle(color: Colors.grey.shade500)),
              ),
            )
          : Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Arrival time
                if (isPresent && report.arrivalTime != null)
                  Column(
                    children: [
                      Text(
                        report.arrivalTime!,
                        style: TextStyle(
                          color: textColor,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 2),
                      const Text('وقت الحضور',
                          style: TextStyle(color: Colors.grey, fontSize: 11)),
                    ],
                  ),
                // Status
                Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isPresent ? Colors.green : Colors.red,
                      ),
                      child: Icon(
                        isPresent ? Icons.check : Icons.close,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          isPresent ? 'حاضر' : 'غائب',
                          style: TextStyle(
                            color: textColor,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const Text('حالة اليوم',
                            style: TextStyle(color: Colors.grey, fontSize: 11)),
                      ],
                    ),
                  ],
                ),
              ],
            ),
    );
  }

  Widget _buildDailyActivityCard(
      StudentProvider provider, Color cardColor, Color textColor, bool isDark) {
    final report = provider.dailyReport;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(24),
        boxShadow: isDark
            ? []
            : [
                BoxShadow(
                  color: Colors.black.withOpacity(0.06),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
      ),
      child: report == null
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Text('لا يوجد نشاط مسجل',
                    style: TextStyle(color: Colors.grey.shade500)),
              ),
            )
          : Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildActivityItem(
                  icon: Icons.restaurant_rounded,
                  label: 'الوجبة',
                  value: report.mealEaten ? 'أكل ✅' : 'لم يأكل',
                  isGood: report.mealEaten,
                  textColor: textColor,
                ),
                Container(
                  width: 1,
                  height: 40,
                  color: Colors.grey.withOpacity(0.3),
                ),
                _buildActivityItem(
                  icon: Icons.sports_esports_rounded,
                  label: 'الاستراحة',
                  value: report.breakTaken ? 'أخذ استراحة ✅' : 'لم يأخذ',
                  isGood: report.breakTaken,
                  textColor: textColor,
                ),
              ],
            ),
    );
  }

  Widget _buildActivityItem({
    required IconData icon,
    required String label,
    required String value,
    required bool isGood,
    required Color textColor,
  }) {
    return Column(
      children: [
        Icon(icon,
            color: isGood ? const Color(0xFF724F96) : Colors.grey, size: 28),
        const SizedBox(height: 6),
        Text(label, style: const TextStyle(color: Colors.grey, fontSize: 12)),
        const SizedBox(height: 2),
        Text(
          value,
          style: TextStyle(
            color: textColor,
            fontSize: 13,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildWeeklyCard(
      StudentProvider provider, Color cardColor, Color textColor, bool isDark) {
    final weekly = provider.weeklyReport!;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(24),
        boxShadow: isDark
            ? []
            : [
                BoxShadow(
                  color: Colors.black.withOpacity(0.06),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Icon(
                weekly.completedDuties ? Icons.check_circle_rounded : Icons.cancel_rounded,
                color: weekly.completedDuties ? Colors.green : Colors.red,
                size: 28,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'أكمل الواجبات الأسبوعية',
                  style: TextStyle(
                    color: textColor,
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Divider(color: Colors.grey.withOpacity(0.3)),
          const SizedBox(height: 10),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.menu_book_rounded, color: Color(0xFF724F96)),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'الدروس المنجزة:',
                      style: TextStyle(color: Colors.grey, fontSize: 12),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      weekly.completedLessons,
                      style: TextStyle(color: textColor, fontSize: 14, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.note_alt_rounded, color: Color(0xFF724F96)),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'ملاحظات المدرس:',
                      style: TextStyle(color: Colors.grey, fontSize: 12),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      weekly.note,
                      style: TextStyle(color: textColor, fontSize: 14, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildWeeklyStat(
      String title, String value, Color color, Color textColor) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
              fontSize: 24, fontWeight: FontWeight.bold, color: color),
        ),
        const SizedBox(height: 4),
        Text(title, style: const TextStyle(color: Colors.grey, fontSize: 12)),
      ],
    );
  }
}