import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:smart_academy/features/admin/constants/app_colors.dart';
import 'package:smart_academy/features/admin/providers/admin_provider.dart';
import 'package:smart_academy/features/admin/widgets/edit_student_modal.dart';
import 'package:smart_academy/features/admin/widgets/teacher_evaluations_modal.dart';
import 'package:smart_academy/views/student_attendance_days_view.dart';

class StudentDetailView extends StatelessWidget {
  final AdminProvider provider;

  const StudentDetailView({super.key, required this.provider});

  @override
  Widget build(BuildContext context) {
    final student = provider.selectedStudent;
    if (student == null) return const SizedBox();

    final presentCount = provider.getStudentPresentCount(student['id']);
    final absentCount = provider.getStudentAbsentCount(student['id']);
    final teacherNote = provider.getStudentLatestNote(student['id']);
    final teacherEvaluations = provider.getStudentTeacherEvaluations(student['id']);

    final List<String> subjects = List<String>.from(
      student['subjects'] ?? [
        'english',
        'math',
        'Ucmath',
        'عربي',
        'حساب',
        'قران',
        'سلوكيات و اداب',
      ],
    );

    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // الشريط العلوي
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // أزرار التعديل والحذف على اليمين
              Row(
                children: [
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.sidebarBg,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    ),
                    icon: const Icon(Icons.edit, size: 18, color: Colors.white),
                    label: const Text('تعديل', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    onPressed: () {
                      showDialog(
                        context: context,
                        builder: (_) => EditStudentModal(provider: provider, student: student),
                      );
                    },
                  ),
                  const SizedBox(width: 12),
                  OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red,
                      side: const BorderSide(color: Colors.red),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    ),
                    icon: const Icon(Icons.delete_outline, size: 18),
                    label: const Text('حذف', style: TextStyle(fontWeight: FontWeight.bold)),
                    onPressed: () => _showDeleteDialog(context, student['id']),
                  ),
                ],
              ),

              // اسم الطالب والمرحلة وسهم الرجوع على الشمال
              Row(
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        'ملف الطالب : ${student['full_name'] ?? ''}',
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      Text(
                        'المرحله : ${student['age_group'] ?? ''}',
                        style: const TextStyle(color: Colors.black45, fontSize: 13),
                      ),
                    ],
                  ),
                  const SizedBox(width: 16),
                  CircleAvatar(
                    radius: 25,
                    backgroundColor: Colors.grey[200],
                    backgroundImage: student['photo_url'] != null && student['photo_url'].toString().isNotEmpty
                        ? CachedNetworkImageProvider(student['photo_url'])
                        : null,
                    child: student['photo_url'] == null || student['photo_url'].toString().isEmpty
                        ? Text(
                            (student['full_name'] ?? '?')[0],
                            style: const TextStyle(color: Colors.black87, fontWeight: FontWeight.bold, fontSize: 20),
                          )
                        : null,
                  ),
                  const SizedBox(width: 16),
                  TextButton(
                    onPressed: () => provider.selectStudent(null),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'عودة',
                          style: TextStyle(
                            color: Colors.black87,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(width: 4),
                        Icon(Icons.arrow_forward, color: Colors.black87),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 24),

          // كروت البيانات والحضور
          LayoutBuilder(
            builder: (context, constraints) {
              final isNarrow = constraints.maxWidth < 750;

              // 1. كارت البيانات الأساسية والمواد
              final basicInfoCard = _buildCard(
                title: 'البيانات الأساسية',
                onTap: () => _showTeacherEvaluations(context, student),
                headerTrailing: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.18),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.white30),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.touch_app_rounded, color: Colors.white, size: 13),
                      SizedBox(width: 4),
                      Text(
                        'عرض تقييمات المدرسين',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // رقم ولي الطالب
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('رقم ولي الطالب:', style: TextStyle(color: Colors.black54, fontWeight: FontWeight.w600)),
                        Text(student['parent_phone'] ?? '', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // المواد
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('المواد:', style: TextStyle(color: Colors.black54, fontWeight: FontWeight.w600)),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Directionality(
                            textDirection: TextDirection.rtl,
                            child: Wrap(
                              spacing: 8,
                              runSpacing: 6,
                              alignment: WrapAlignment.start,
                              children: subjects
                                  .map((sub) => Text(sub, style: const TextStyle(fontWeight: FontWeight.bold)))
                                  .toList(),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // ملاحظة من المدرس
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Text('ملاحظه من المدرس:', style: TextStyle(color: Colors.black54, fontWeight: FontWeight.w600)),
                            if (teacherEvaluations.isNotEmpty) ...[
                              const SizedBox(width: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF724F96).withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Text(
                                  '${teacherEvaluations.length} تقييم',
                                  style: const TextStyle(
                                    fontSize: 10,
                                    color: Color(0xFF724F96),
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                teacherNote,
                                textAlign: TextAlign.left,
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                              ),
                              if (teacherEvaluations.isNotEmpty) ...[
                                const SizedBox(height: 8),
                                Wrap(
                                  spacing: 8,
                                  runSpacing: 6,
                                  children: teacherEvaluations.take(3).map((e) {
                                    final String name = e['teacher_name'] ?? '';
                                    final String initial = name.isNotEmpty ? name.trim()[0] : 'م';
                                    final String? avatar = e['teacher_avatar'];
                                    final String sub = e['subject'] ?? '';
                                    return Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: Colors.grey.shade100,
                                        borderRadius: BorderRadius.circular(20),
                                        border: Border.all(color: Colors.grey.shade300),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          CircleAvatar(
                                            radius: 11,
                                            backgroundColor: const Color(0xFF724F96),
                                            backgroundImage: avatar != null && avatar.isNotEmpty
                                                ? CachedNetworkImageProvider(avatar)
                                                : null,
                                            child: avatar == null || avatar.isEmpty
                                                ? Text(
                                                    initial,
                                                    style: const TextStyle(
                                                      fontSize: 10,
                                                      color: Colors.white,
                                                      fontWeight: FontWeight.bold,
                                                    ),
                                                  )
                                                : null,
                                          ),
                                          const SizedBox(width: 5),
                                          Flexible(
                                            child: Text(
                                              '$name (${sub.isNotEmpty ? sub : "مادة"})',
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              style: TextStyle(
                                                fontSize: 11,
                                                color: Colors.grey.shade800,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    );
                                  }).toList(),
                                ),
                                const SizedBox(height: 6),
                           
                              ],
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // زر فتح تقييمات المدرسين
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF724F96),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 11, horizontal: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          elevation: 1,
                        ),
                        icon: const Icon(Icons.people_alt_outlined, size: 18),
                        label: Text(
                          teacherEvaluations.isNotEmpty
                              ? 'عرض جميع تقييمات المدرسين (${teacherEvaluations.length})'
                              : 'عرض تقييمات وملاحظات المدرسين',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                        ),
                        onPressed: () => _showTeacherEvaluations(context, student),
                      ),
                    ),
                  ],
                ),
              );

              // 2. كارت الحضور والغياب
              final attendanceCard = _buildCard(
                title: 'الحضور والغياب',
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildCountColumn(
                      context: context,
                      label: 'غياب',
                      value: '$absentCount',
                      isPresent: false,
                      student: student,
                    ),
                    _buildCountColumn(
                      context: context,
                      label: 'حضور',
                      value: '$presentCount',
                      isPresent: true,
                      student: student,
                    ),
                  ],
                ),
              );

              if (isNarrow) {
                return Column(
                  children: [
                    basicInfoCard,
                    const SizedBox(height: 20),
                    attendanceCard,
                  ],
                );
              }

              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: basicInfoCard),
                  const SizedBox(width: 20),
                  Expanded(child: attendanceCard),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  void _showDeleteDialog(BuildContext context, dynamic studentId) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('تأكيد الحذف', textAlign: TextAlign.right),
        content: const Text('هل أنت متأكد من حذف هذا الطالب نهائياً من النظام؟'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('إلغاء')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              Navigator.pop(ctx);
              final success = await provider.deleteStudent(studentId);
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(success ? 'تم حذف الطالب بنجاح' : 'حدث خطأ أثناء الحذف')),
                );
              }
            },
            child: const Text('نعم، إحذف', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Widget _buildCard({
    required String title,
    required Widget child,
    VoidCallback? onTap,
    Widget? headerTrailing,
  }) {
    return MouseRegion(
      cursor: onTap != null ? SystemMouseCursors.click : SystemMouseCursors.basic,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            color: const Color(0xFF724F96),
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.08),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: onTap,
              borderRadius: BorderRadius.circular(12),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        if (headerTrailing != null)
                          Flexible(child: headerTrailing)
                        else
                          const SizedBox.shrink(),
                        const SizedBox(width: 8),
                        Text(
                          title,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const Divider(color: Colors.white24, height: 24),
                    GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: onTap,
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: child,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _showTeacherEvaluations(BuildContext context, Map<String, dynamic> student) {
    showDialog(
      context: context,
      builder: (_) => TeacherEvaluationsModal(
        provider: provider,
        studentId: student['id'],
        studentName: student['full_name'] ?? '',
      ),
    );
  }

  Widget _buildCountColumn({
    required BuildContext context,
    required String label,
    required String value,
    required bool isPresent,
    required Map<String, dynamic> student,
  }) {
    final color = isPresent ? Colors.green : Colors.red;
    return GestureDetector(
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => StudentAttendanceDaysView(
              studentId: student['id'].toString(),
              studentName: student['full_name'] ?? '',
              showPresent: isPresent,
            ),
          ),
        );
      },
      child: Column(
        children: [
          Text(label, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          Text(value, style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: color)),
          const SizedBox(height: 6),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.touch_app_rounded, size: 11, color: Colors.grey.shade400),
              const SizedBox(width: 3),
              Text('اضغط للتفاصيل', style: TextStyle(fontSize: 10, color: Colors.grey.shade400)),
            ],
          ),
        ],
      ),
    );
  }
}