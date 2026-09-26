import 'package:flutter/material.dart';
import 'package:smart_academy/features/admin/constants/app_colors.dart';
import 'package:smart_academy/features/admin/providers/admin_provider.dart';
import 'package:smart_academy/features/admin/widgets/add_student_modal.dart';
import 'package:smart_academy/views/teacher_attendance_days_view.dart';

class TeacherDetailView extends StatefulWidget {
  final AdminProvider provider;

  const TeacherDetailView({super.key, required this.provider});

  @override
  State<TeacherDetailView> createState() => _TeacherDetailViewState();
}

class _TeacherDetailViewState extends State<TeacherDetailView> {
  // تتبع المرحلة/الفئة العمرية المحددة حالياً
  String? _selectedStage;

  @override
  Widget build(BuildContext context) {
    final teacher = widget.provider.selectedTeacher;
    if (teacher == null) return const SizedBox.shrink();

    final String teacherName = teacher['full_name'] ?? '';
    final String subjectName = teacher['subject'] ?? 'غير محدد';
    final String ageGroup = teacher['age_group'] ?? 'غير محدد';

    // قائمة المراحل الخاصة بالمدرس
    final List<String> stagesList = widget.provider.teacherStagesList.isNotEmpty
        ? widget.provider.teacherStagesList
        : ageGroup.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList();

    return Directionality(
      textDirection: TextDirection.rtl,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. الشريط العلوي (بيانات المدرس وأزرار التحكم)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back, color: Colors.black87),
                      onPressed: () => widget.provider.clearSelectedTeacher(),
                    ),
                    const SizedBox(width: 8),
                    CircleAvatar(
                      radius: 25,
                      backgroundColor: Colors.grey[200],
                      backgroundImage: teacher['avatar_url'] != null && teacher['avatar_url'].toString().isNotEmpty
                          ? NetworkImage(teacher['avatar_url'])
                          : null,
                      child: teacher['avatar_url'] == null || teacher['avatar_url'].toString().isEmpty
                          ? Text(
                              teacherName.isNotEmpty ? teacherName[0] : '?',
                              style: const TextStyle(color: Colors.black87, fontWeight: FontWeight.bold, fontSize: 20),
                            )
                          : null,
                    ),
                    const SizedBox(width: 16),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'ملف المدرس : $teacherName',
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Text(
                              'المادة: $subjectName',
                              style: const TextStyle(
                                fontSize: 14,
                                color: Colors.grey,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: const Color(0xFFE6E6FA),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                'المرحلة: $ageGroup',
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: AppColors.sidebarBg,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),

                // أزرار التعديل والحذف
                Row(
                  children: [
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF2A1B38),
                        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      icon: const Icon(Icons.edit, color: Colors.white, size: 16),
                      label: const Text(
                        'تعديل',
                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                      ),
                      onPressed: () {
                        _showEditTeacherDialog(context, teacher);
                      },
                    ),
                    const SizedBox(width: 12),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: Colors.red,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      icon: const Icon(Icons.delete_outline, color: Colors.red, size: 18),
                      label: const Text(
                        'حذف',
                        style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
                      ),
                      onPressed: () {
                        _showDeleteConfirmDialog(context, teacher['id']);
                      },
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 24),

            // 2. كروت الإحصائيات (أيام الحضور - عدد الطلاب)
            Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => TeacherAttendanceDaysView(
                            teacherId: teacher['id'].toString(),
                            teacherName: teacherName,
                          ),
                        ),
                      );
                    },
                    child: _buildStatCard(
                      title: 'أيام الحضور',
                      value: widget.provider.teacherAttendanceCount.toString(),
                      isClickable: true,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildStatCard(
                    title: 'عدد الطلاب',
                    value: widget.provider.teacherStudentsCount.toString(),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 32),

            // 3. عرض قائمة اختيار الفئات أو عرض جدول الطلاب بناءً على الاختيار
            _selectedStage == null
                ? _buildStageSelectionSection(stagesList)
                : _buildStageStudentsSection(_selectedStage!),
          ],
        ),
      ),
    );
  }

  // كرت الإحصائيات
  Widget _buildStatCard({required String title, required String value, bool isClickable = false}) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              if (isClickable)
                const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: Colors.grey),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 14,
                  color: Colors.grey,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
        ],
      ),
    );
  }

  // واجهة اختيار المراحل/الفئات العمرية
  Widget _buildStageSelectionSection(List<String> stages) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFE6E6FA).withOpacity(0.5),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Text('🏫 ', style: TextStyle(fontSize: 16)),
              Text(
                'اختر المرحلة العمرية والدراسية لمتابعة الحضور والغياب والطلاب',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Wrap(
            spacing: 16,
            runSpacing: 16,
            children: stages.map((stage) => _buildStageCard(stage)).toList(),
          ),
        ],
      ),
    );
  }

  // بطاقة المرحلة العمرية القابلة للضغط
  Widget _buildStageCard(String stageName) {
    return InkWell(
      onTap: () {
        setState(() {
          _selectedStage = stageName;
        });
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: 220,
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.9),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.black12),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('🎒', style: TextStyle(fontSize: 28)),
            const SizedBox(height: 8),
            Text(
              'المرحلة $stageName',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // جدول طلاب الفئة المختارة
  Widget _buildStageStudentsSection(String stageName) {
    // تصفية الطلاب التابعين للمرحلة المختارة
    final filteredStudents = widget.provider.studentsList.where((s) {
      final String studentAgeGroup = s['age_group'] ?? '';
      return studentAgeGroup.trim() == stageName.trim();
    }).toList();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFE6E6FA).withOpacity(0.6),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // الشريط العلوي للجدول
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '👨‍🎓 طلاب الصف $stageName',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              Row(
                children: [
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2A1B38),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    icon: const Icon(Icons.add, color: Colors.white, size: 18),
                    label: const Text(
                      'اضافة طالب جديد',
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                    ),
                    onPressed: () {
                      showDialog(
                        context: context,
                        builder: (_) => AddStudentModal(provider: widget.provider),
                      );
                    },
                  ),
                  const SizedBox(width: 12),
                  TextButton(
                    style: TextButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    ),
                    onPressed: () {
                      setState(() {
                        _selectedStage = null;
                      });
                    },
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'عودة',
                          style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold),
                        ),
                        SizedBox(width: 4),
                        Icon(Icons.undo, color: Colors.black87, size: 18),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 20),

          // جدول البيانات
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.03),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Column(
                children: [
                  // العناوين
                  Container(
                    color: const Color(0xFF2A1B38),
                    padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
                    child: const Row(
                      children: [
                        Expanded(
                          flex: 2,
                          child: Text(
                            'اسم الطالب',
                            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                          ),
                        ),
                        Expanded(
                          flex: 2,
                          child: Text(
                            'الفئة العمرية',
                            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                          ),
                        ),
                        Expanded(
                          flex: 2,
                          child: Text(
                            'رقم ولي الأمر الطالب',
                            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                          ),
                        ),
                        Expanded(
                          flex: 2,
                          child: Text(
                            'الحضور والغياب',
                            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                          ),
                        ),
                        Expanded(
                          flex: 1,
                          child: Text(
                            'الاجراءات',
                            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // قائمة الصفوف
                  if (filteredStudents.isEmpty)
                    const Padding(
                      padding: EdgeInsets.all(24.0),
                      child: Text(
                        'لا يوجد طلاب مضافين لهذه المرحلة حالياً',
                        style: TextStyle(color: Colors.grey, fontSize: 14),
                      ),
                    )
                  else
                    ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: filteredStudents.length,
                      separatorBuilder: (context, index) => const Divider(height: 1, color: Colors.black12),
                      itemBuilder: (context, index) {
                        final student = filteredStudents[index];
                        final String attendanceRate = student['attendance'] ?? '0%';
                        final bool isHighAttendance = !attendanceRate.contains('45');

                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                          child: Row(
                            children: [
                              Expanded(
                                flex: 2,
                                child: Text(
                                  student['full_name'] ?? '',
                                  style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                                ),
                              ),
                              Expanded(
                                flex: 2,
                                child: Align(
                                  alignment: Alignment.centerRight,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFE6E6FA),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      student['age_group'] ?? stageName,
                                      style: const TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                        color: AppColors.sidebarBg,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              Expanded(
                                flex: 2,
                                child: Text(
                                  student['parent_phone'] ?? '',
                                  style: const TextStyle(fontSize: 14, color: Colors.black87),
                                ),
                              ),
                              Expanded(
                                flex: 2,
                                child: Row(
                                  children: [
                                    Icon(
                                      isHighAttendance ? Icons.check_circle : Icons.cancel,
                                      color: isHighAttendance ? Colors.green : Colors.red,
                                      size: 16,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      attendanceRate,
                                      style: TextStyle(
                                        color: isHighAttendance ? Colors.green : Colors.red,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 13,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Expanded(
                                flex: 1,
                                child: Align(
                                  alignment: Alignment.centerRight,
                                  child: ElevatedButton(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color(0xFFE6E6FA),
                                      elevation: 0,
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                    ),
                                    onPressed: () {
                                      widget.provider.selectStudent(student);
                                    },
                                    child: const Text(
                                      'فتح الملف',
                                      style: TextStyle(
                                        color: AppColors.sidebarBg,
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // نافذة تعديل المدرس
  void _showEditTeacherDialog(BuildContext context, Map<String, dynamic> teacher) {
    final nameController = TextEditingController(text: teacher['full_name'] ?? '');
    final phoneController = TextEditingController(text: teacher['phone'] ?? '');
    final subjectController = TextEditingController(text: teacher['subject'] ?? '');

    final stagesStr = widget.provider.teacherStagesList.isNotEmpty
        ? widget.provider.teacherStagesList.join(', ')
        : (teacher['age_group'] ?? '');
    final ageGroupsController = TextEditingController(text: stagesStr);

    showDialog(
      context: context,
      builder: (ctx) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          title: const Text('تعديل بيانات المدرس'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    labelText: 'الاسم بالكامل',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: phoneController,
                  decoration: const InputDecoration(
                    labelText: 'رقم الهاتف',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: subjectController,
                  decoration: const InputDecoration(
                    labelText: 'المادة الدراسية',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: ageGroupsController,
                  decoration: const InputDecoration(
                    labelText: 'المراحل التعليمية (مفصولة بفواصل)',
                    hintText: 'مثال: KG1, KG2',
                    border: OutlineInputBorder(),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('إلغاء'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2A1B38),
              ),
              onPressed: () async {
                final stagesList = ageGroupsController.text
                    .split(',')
                    .map((s) => s.trim())
                    .where((s) => s.isNotEmpty)
                    .toList();

                final success = await widget.provider.updateTeacher(
                  teacherId: teacher['id'],
                  fullName: nameController.text.trim(),
                  phone: phoneController.text.trim(),
                  subject: subjectController.text.trim(),
                  ageGroups: stagesList,
                );

                if (context.mounted) {
                  Navigator.pop(ctx);
                  if (success) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('تم تعديل بيانات المدرس بنجاح')),
                    );
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('حدث خطأ أثناء التعديل')),
                    );
                  }
                }
              },
              child: const Text('حفظ التعديلات', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  // نافذة حذف المدرس
  void _showDeleteConfirmDialog(BuildContext context, dynamic teacherId) {
    showDialog(
      context: context,
      builder: (ctx) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          title: const Text('تأكيد الحذف'),
          content: const Text('هل أنت تأكد من رغبتك في حذف هذا المدرس نهائياً؟'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('إلغاء'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              onPressed: () async {
                Navigator.pop(ctx);
                await widget.provider.deleteTeacher(teacherId.toString());
              },
              child: const Text('حذف', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }
}