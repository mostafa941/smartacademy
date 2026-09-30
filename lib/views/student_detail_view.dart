import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:smart_academy/features/admin/constants/app_colors.dart';
import 'package:smart_academy/features/admin/providers/admin_provider.dart';
import 'package:smart_academy/features/admin/widgets/edit_student_modal.dart';
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

    final List<String> subjects = List<String>.from(
      student['subjects'] ?? [
        'english',
        'math',
        'Ucmath',
        'Ø¹Ø±Ø¨ÙŠ',
        'Ø­Ø³Ø§Ø¨',
        'Ù‚Ø±Ø§Ù†',
        'Ø³Ù„ÙˆÙƒÙŠØ§Øª Ùˆ Ø§Ø¯Ø§Ø¨',
      ],
    );

    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Ø§Ù„Ø´Ø±ÙŠØ· Ø§Ù„Ø¹Ù„ÙˆÙŠ
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Ø£Ø²Ø±Ø§Ø± Ø§Ù„ØªØ¹Ø¯ÙŠÙ„ ÙˆØ§Ù„Ø­Ø°Ù Ø¹Ù„Ù‰ Ø§Ù„ÙŠÙ…ÙŠÙ†
              Row(
                children: [
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.sidebarBg,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    ),
                    icon: const Icon(Icons.edit, size: 18, color: Colors.white),
                    label: const Text('ØªØ¹Ø¯ÙŠÙ„', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
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
                    label: const Text('Ø­Ø°Ù', style: TextStyle(fontWeight: FontWeight.bold)),
                    onPressed: () => _showDeleteDialog(context, student['id']),
                  ),
                ],
              ),

              // Ø§Ø³Ù… Ø§Ù„Ø·Ø§Ù„Ø¨ ÙˆØ§Ù„Ù…Ø±Ø­Ù„Ø© ÙˆØ³Ù‡Ù… Ø§Ù„Ø±Ø¬ÙˆØ¹ Ø¹Ù„Ù‰ Ø§Ù„Ø´Ù…Ø§Ù„
              Row(
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        'Ù…Ù„Ù Ø§Ù„Ø·Ø§Ù„Ø¨ : ${student['full_name'] ?? ''}',
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      Text(
                        'Ø§Ù„Ù…Ø±Ø­Ù„Ù‡ : ${student['age_group'] ?? ''}',
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
                          'Ø¹ÙˆØ¯Ø©',
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

          // ÙƒØ±ÙˆØª Ø§Ù„Ø¨ÙŠØ§Ù†Ø§Øª ÙˆØ§Ù„Ø­Ø¶ÙˆØ±
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. ÙƒØ§Ø±Øª Ø§Ù„Ø¨ÙŠØ§Ù†Ø§Øª Ø§Ù„Ø£Ø³Ø§Ø³ÙŠØ© ÙˆØ§Ù„Ù…ÙˆØ§Ø¯ (Ø¬Ù‡Ø© Ø§Ù„ÙŠÙ…ÙŠÙ†)
              Expanded(
                child: _buildCard(
                  title: 'Ø§Ù„Ø¨ÙŠØ§Ù†Ø§Øª Ø§Ù„Ø£Ø³Ø§Ø³ÙŠØ©',
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Ø±Ù‚Ù… ÙˆÙ„ÙŠ Ø§Ù„Ø·Ø§Ù„Ø¨
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Ø±Ù‚Ù… ÙˆÙ„ÙŠ Ø§Ù„Ø·Ø§Ù„Ø¨:', style: TextStyle(color: Colors.black54, fontWeight: FontWeight.w600)),
                          Text(student['parent_phone'] ?? '', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Ø§Ù„Ù…ÙˆØ§Ø¯
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Ø§Ù„Ù…ÙˆØ§Ø¯:', style: TextStyle(color: Colors.black54, fontWeight: FontWeight.w600)),
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

                      // Ù…Ù„Ø§Ø­Ø¸Ø© Ù…Ù† Ø§Ù„Ù…Ø¯Ø±Ø³
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Ù…Ù„Ø§Ø­Ø¸Ù‡ Ù…Ù† Ø§Ù„Ù…Ø¯Ø±Ø³:', style: TextStyle(color: Colors.black54, fontWeight: FontWeight.w600)),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              teacherNote,
                              textAlign: TextAlign.left,
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 20),

              // 2. ÙƒØ§Ø±Øª Ø§Ù„Ø­Ø¶ÙˆØ± ÙˆØ§Ù„ØºÙŠØ§Ø¨ (Ø¬Ù‡Ø© Ø§Ù„ÙŠØ³Ø§Ø±)
              Expanded(
                child: _buildCard(
                  title: 'Ø§Ù„Ø­Ø¶ÙˆØ± ÙˆØ§Ù„ØºÙŠØ§Ø¨',
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildCountColumn(
                        context: context,
                        label: 'ØºÙÙŠØ§Ø¨',
                        value: '$absentCount',
                        isPresent: false,
                        student: student,
                      ),
                      _buildCountColumn(
                        context: context,
                        label: 'Ø­Ø¶ÙˆØ±',
                        value: '$presentCount',
                        isPresent: true,
                        student: student,
                      ),
                    ],
                  ),
                ),
              ),

            ],
          ),
        ],
      ),
    );
  }

  void _showDeleteDialog(BuildContext context, dynamic studentId) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('ØªØ£ÙƒÙŠØ¯ Ø§Ù„Ø­Ø°Ù', textAlign: TextAlign.right),
        content: const Text('Ù‡Ù„ Ø£Ù†Øª Ù…ØªØ£ÙƒØ¯ Ù…Ù† Ø­Ø°Ù Ù‡Ø°Ø§ Ø§Ù„Ø·Ø§Ù„Ø¨ Ù†Ù‡Ø§Ø¦ÙŠØ§Ù‹ Ù…Ù† Ø§Ù„Ù†Ø¸Ø§Ù…ØŸ'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Ø¥Ù„ØºØ§Ø¡')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              Navigator.pop(ctx);
              final success = await provider.deleteStudent(studentId);
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(success ? 'ØªÙ… Ø­Ø°Ù Ø§Ù„Ø·Ø§Ù„Ø¨ Ø¨Ù†Ø¬Ø§Ø­' : 'Ø­Ø¯Ø« Ø®Ø·Ø£ Ø£Ø«Ù†Ø§Ø¡ Ø§Ù„Ø­Ø°Ù')),
                );
              }
            },
            child: const Text('Ù†Ø¹Ù…ØŒ Ø¥Ø­Ø°Ù', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Widget _buildCard({required String title, required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        // Ø§Ø³ØªØ®Ø¯Ø§Ù… Ø¯Ø±Ø¬Ø© Ø£Ø²Ø±Ù‚ Ø®ÙÙŠÙØ© ÙˆÙ‡Ø§Ø¯Ø¦Ø© Ù…Ø¹ Ø§Ù†Ø­Ù†Ø§Ø¡ Ø®ÙÙŠÙ ÙˆØ¨ÙˆØ±Ø¯Ø± Ù„Ø·ÙŠÙ
        color: const Color(0xFF724F96),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(title, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
          const Divider(color: Colors.white24, height: 24),
          Container(
            padding: const EdgeInsets.all(16),
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
            ),
            child: child,
          ),
        ],
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
              Text('Ø§Ø¶ØºØ· Ù„Ù„ØªÙØ§ØµÙŠÙ„', style: TextStyle(fontSize: 10, color: Colors.grey.shade400)),
            ],
          ),
        ],
      ),
    );
  }
}

