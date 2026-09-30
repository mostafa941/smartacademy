import 'package:cached_network_image/cached_network_image.dart';
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
  // ØªØªØ¨Ø¹ Ø§Ù„Ù…Ø±Ø­Ù„Ø©/Ø§Ù„ÙØ¦Ø© Ø§Ù„Ø¹Ù…Ø±ÙŠØ© Ø§Ù„Ù…Ø­Ø¯Ø¯Ø© Ø­Ø§Ù„ÙŠØ§Ù‹
  String? _selectedStage;

  @override
  Widget build(BuildContext context) {
    final teacher = widget.provider.selectedTeacher;
    if (teacher == null) return const SizedBox.shrink();

    final String teacherName = teacher['full_name'] ?? '';
    final String subjectName = teacher['subject'] ?? 'ØºÙŠØ± Ù…Ø­Ø¯Ø¯';
    final String ageGroup = teacher['age_group'] ?? 'ØºÙŠØ± Ù…Ø­Ø¯Ø¯';

    // Ù‚Ø§Ø¦Ù…Ø© Ø§Ù„Ù…Ø±Ø§Ø­Ù„ Ø§Ù„Ø®Ø§ØµØ© Ø¨Ø§Ù„Ù…Ø¯Ø±Ø³
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
            // 1. Ø§Ù„Ø´Ø±ÙŠØ· Ø§Ù„Ø¹Ù„ÙˆÙŠ (Ø¨ÙŠØ§Ù†Ø§Øª Ø§Ù„Ù…Ø¯Ø±Ø³ ÙˆØ£Ø²Ø±Ø§Ø± Ø§Ù„ØªØ­ÙƒÙ…)
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
                          ? CachedNetworkImageProvider(teacher['avatar_url'])
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
                          'Ù…Ù„Ù Ø§Ù„Ù…Ø¯Ø±Ø³ : $teacherName',
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
                              'Ø§Ù„Ù…Ø§Ø¯Ø©: $subjectName',
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
                                'Ø§Ù„Ù…Ø±Ø­Ù„Ø©: $ageGroup',
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

                // Ø£Ø²Ø±Ø§Ø± Ø§Ù„ØªØ¹Ø¯ÙŠÙ„ ÙˆØ§Ù„Ø­Ø°Ù
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
                        'ØªØ¹Ø¯ÙŠÙ„',
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
                        'Ø­Ø°Ù',
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

            // 2. ÙƒØ±ÙˆØª Ø§Ù„Ø¥Ø­ØµØ§Ø¦ÙŠØ§Øª (Ø£ÙŠØ§Ù… Ø§Ù„Ø­Ø¶ÙˆØ± - Ø¹Ø¯Ø¯ Ø§Ù„Ø·Ù„Ø§Ø¨)
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
                      title: 'Ø£ÙŠØ§Ù… Ø§Ù„Ø­Ø¶ÙˆØ±',
                      value: widget.provider.teacherAttendanceCount.toString(),
                      isClickable: true,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildStatCard(
                    title: 'Ø¹Ø¯Ø¯ Ø§Ù„Ø·Ù„Ø§Ø¨',
                    value: widget.provider.teacherStudentsCount.toString(),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 32),

            // 3. Ø¹Ø±Ø¶ Ù‚Ø§Ø¦Ù…Ø© Ø§Ø®ØªÙŠØ§Ø± Ø§Ù„ÙØ¦Ø§Øª Ø£Ùˆ Ø¹Ø±Ø¶ Ø¬Ø¯ÙˆÙ„ Ø§Ù„Ø·Ù„Ø§Ø¨ Ø¨Ù†Ø§Ø¡Ù‹ Ø¹Ù„Ù‰ Ø§Ù„Ø§Ø®ØªÙŠØ§Ø±
            _selectedStage == null
                ? _buildStageSelectionSection(stagesList)
                : _buildStageStudentsSection(_selectedStage!),
          ],
        ),
      ),
    );
  }

  // ÙƒØ±Øª Ø§Ù„Ø¥Ø­ØµØ§Ø¦ÙŠØ§Øª
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

  // ÙˆØ§Ø¬Ù‡Ø© Ø§Ø®ØªÙŠØ§Ø± Ø§Ù„Ù…Ø±Ø§Ø­Ù„/Ø§Ù„ÙØ¦Ø§Øª Ø§Ù„Ø¹Ù…Ø±ÙŠØ©
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
              Text('ðŸ« ', style: TextStyle(fontSize: 16)),
              Text(
                'Ø§Ø®ØªØ± Ø§Ù„Ù…Ø±Ø­Ù„Ø© Ø§Ù„Ø¹Ù…Ø±ÙŠØ© ÙˆØ§Ù„Ø¯Ø±Ø§Ø³ÙŠØ© Ù„Ù…ØªØ§Ø¨Ø¹Ø© Ø§Ù„Ø­Ø¶ÙˆØ± ÙˆØ§Ù„ØºÙŠØ§Ø¨ ÙˆØ§Ù„Ø·Ù„Ø§Ø¨',
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

  // Ø¨Ø·Ø§Ù‚Ø© Ø§Ù„Ù…Ø±Ø­Ù„Ø© Ø§Ù„Ø¹Ù…Ø±ÙŠØ© Ø§Ù„Ù‚Ø§Ø¨Ù„Ø© Ù„Ù„Ø¶ØºØ·
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
            const Text('ðŸŽ’', style: TextStyle(fontSize: 28)),
            const SizedBox(height: 8),
            Text(
              'Ø§Ù„Ù…Ø±Ø­Ù„Ø© $stageName',
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

  // Ø¬Ø¯ÙˆÙ„ Ø·Ù„Ø§Ø¨ Ø§Ù„ÙØ¦Ø© Ø§Ù„Ù…Ø®ØªØ§Ø±Ø©
  Widget _buildStageStudentsSection(String stageName) {
    // ØªØµÙÙŠØ© Ø§Ù„Ø·Ù„Ø§Ø¨ Ø§Ù„ØªØ§Ø¨Ø¹ÙŠÙ† Ù„Ù„Ù…Ø±Ø­Ù„Ø© Ø§Ù„Ù…Ø®ØªØ§Ø±Ø©
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
          // Ø§Ù„Ø´Ø±ÙŠØ· Ø§Ù„Ø¹Ù„ÙˆÙŠ Ù„Ù„Ø¬Ø¯ÙˆÙ„
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'ðŸ‘¨â€ðŸŽ“ Ø·Ù„Ø§Ø¨ Ø§Ù„ØµÙ $stageName',
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
                      'Ø§Ø¶Ø§ÙØ© Ø·Ø§Ù„Ø¨ Ø¬Ø¯ÙŠØ¯',
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
                          'Ø¹ÙˆØ¯Ø©',
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

          // Ø¬Ø¯ÙˆÙ„ Ø§Ù„Ø¨ÙŠØ§Ù†Ø§Øª
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
                  // Ø§Ù„Ø¹Ù†Ø§ÙˆÙŠÙ†
                  Container(
                    color: const Color(0xFF2A1B38),
                    padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
                    child: const Row(
                      children: [
                        Expanded(
                          flex: 2,
                          child: Text(
                            'Ø§Ø³Ù… Ø§Ù„Ø·Ø§Ù„Ø¨',
                            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                          ),
                        ),
                        Expanded(
                          flex: 2,
                          child: Text(
                            'Ø§Ù„ÙØ¦Ø© Ø§Ù„Ø¹Ù…Ø±ÙŠØ©',
                            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                          ),
                        ),
                        Expanded(
                          flex: 2,
                          child: Text(
                            'Ø±Ù‚Ù… ÙˆÙ„ÙŠ Ø§Ù„Ø£Ù…Ø± Ø§Ù„Ø·Ø§Ù„Ø¨',
                            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                          ),
                        ),
                        Expanded(
                          flex: 2,
                          child: Text(
                            'Ø§Ù„Ø­Ø¶ÙˆØ± ÙˆØ§Ù„ØºÙŠØ§Ø¨',
                            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                          ),
                        ),
                        Expanded(
                          flex: 1,
                          child: Text(
                            'Ø§Ù„Ø§Ø¬Ø±Ø§Ø¡Ø§Øª',
                            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Ù‚Ø§Ø¦Ù…Ø© Ø§Ù„ØµÙÙˆÙ
                  if (filteredStudents.isEmpty)
                    const Padding(
                      padding: EdgeInsets.all(24.0),
                      child: Text(
                        'Ù„Ø§ ÙŠÙˆØ¬Ø¯ Ø·Ù„Ø§Ø¨ Ù…Ø¶Ø§ÙÙŠÙ† Ù„Ù‡Ø°Ù‡ Ø§Ù„Ù…Ø±Ø­Ù„Ø© Ø­Ø§Ù„ÙŠØ§Ù‹',
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
                                      'ÙØªØ­ Ø§Ù„Ù…Ù„Ù',
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

  // Ù†Ø§ÙØ°Ø© ØªØ¹Ø¯ÙŠÙ„ Ø§Ù„Ù…Ø¯Ø±Ø³
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
          title: const Text('ØªØ¹Ø¯ÙŠÙ„ Ø¨ÙŠØ§Ù†Ø§Øª Ø§Ù„Ù…Ø¯Ø±Ø³'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    labelText: 'Ø§Ù„Ø§Ø³Ù… Ø¨Ø§Ù„ÙƒØ§Ù…Ù„',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: phoneController,
                  decoration: const InputDecoration(
                    labelText: 'Ø±Ù‚Ù… Ø§Ù„Ù‡Ø§ØªÙ',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: subjectController,
                  decoration: const InputDecoration(
                    labelText: 'Ø§Ù„Ù…Ø§Ø¯Ø© Ø§Ù„Ø¯Ø±Ø§Ø³ÙŠØ©',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: ageGroupsController,
                  decoration: const InputDecoration(
                    labelText: 'Ø§Ù„Ù…Ø±Ø§Ø­Ù„ Ø§Ù„ØªØ¹Ù„ÙŠÙ…ÙŠØ© (Ù…ÙØµÙˆÙ„Ø© Ø¨ÙÙˆØ§ØµÙ„)',
                    hintText: 'Ù…Ø«Ø§Ù„: KG1, KG2',
                    border: OutlineInputBorder(),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Ø¥Ù„ØºØ§Ø¡'),
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
                      const SnackBar(content: Text('ØªÙ… ØªØ¹Ø¯ÙŠÙ„ Ø¨ÙŠØ§Ù†Ø§Øª Ø§Ù„Ù…Ø¯Ø±Ø³ Ø¨Ù†Ø¬Ø§Ø­')),
                    );
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Ø­Ø¯Ø« Ø®Ø·Ø£ Ø£Ø«Ù†Ø§Ø¡ Ø§Ù„ØªØ¹Ø¯ÙŠÙ„')),
                    );
                  }
                }
              },
              child: const Text('Ø­ÙØ¸ Ø§Ù„ØªØ¹Ø¯ÙŠÙ„Ø§Øª', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  // Ù†Ø§ÙØ°Ø© Ø­Ø°Ù Ø§Ù„Ù…Ø¯Ø±Ø³
  void _showDeleteConfirmDialog(BuildContext context, dynamic teacherId) {
    showDialog(
      context: context,
      builder: (ctx) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          title: const Text('ØªØ£ÙƒÙŠØ¯ Ø§Ù„Ø­Ø°Ù'),
          content: const Text('Ù‡Ù„ Ø£Ù†Øª ØªØ£ÙƒØ¯ Ù…Ù† Ø±ØºØ¨ØªÙƒ ÙÙŠ Ø­Ø°Ù Ù‡Ø°Ø§ Ø§Ù„Ù…Ø¯Ø±Ø³ Ù†Ù‡Ø§Ø¦ÙŠØ§Ù‹ØŸ'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Ø¥Ù„ØºØ§Ø¡'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              onPressed: () async {
                Navigator.pop(ctx);
                await widget.provider.deleteTeacher(teacherId.toString());
              },
              child: const Text('Ø­Ø°Ù', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }
}
