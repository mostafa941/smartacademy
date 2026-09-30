import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../providers/admin_provider.dart';
import '../widgets/add_student_modal.dart';

class StudentsView extends StatelessWidget {
  final AdminProvider provider;

  const StudentsView({super.key, required this.provider});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        children: [
          Row(
            children: [
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.addBtnBg,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
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
                    builder: (_) => AddStudentModal(provider: provider),
                  );
                },
              ),
              const SizedBox(width: 16),
              Expanded(
                child: SizedBox(
                  height: 48,
                  child: TextField(
                    onChanged: (val) => provider.setSearchQuery(val),
                    decoration: InputDecoration(
                      hintText: 'Ø§Ø¨Ø­Ø« Ø¨Ø£Ø³Ù… Ø§Ù„Ø·Ø§Ù„Ø¨ Ø§Ùˆ Ø±Ù‚Ù… Ø§Ù„Ù‡Ø§ØªÙ...',
                      hintStyle: const TextStyle(fontSize: 13, color: Colors.black38),
                      fillColor: Colors.white,
                      filled: true,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: ListView(
                  children: [
                    Container(
                      color: AppColors.sidebarBg,
                      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
                      child: Row(
                        children: const [
                          Expanded(flex: 2, child: Text('Ø§Ø³Ù… Ø§Ù„Ø·Ø§Ù„Ø¨', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
                          Expanded(flex: 1, child: Text('Ø§Ù„ÙØ¦Ø© Ø§Ù„Ø¹Ù…Ø±ÙŠØ©', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
                          Expanded(flex: 2, child: Text('Ø±Ù‚Ù… ÙˆÙ„ÙŠ Ø§Ù„Ø£Ù…Ø± Ø§Ù„Ø·Ø§Ù„Ø¨', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
                          Expanded(flex: 2, child: Text('Ø§Ù„Ø­Ø¶ÙˆØ± ÙˆØ§Ù„ØºÙŠØ§Ø¨', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
                          Expanded(flex: 1, child: Text('Ø§Ù„Ø£Ø¬Ø±Ø§Ø¡Ø§Øª', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
                        ],
                      ),
                    ),
                    if (provider.filteredStudents.isEmpty)
                      const Padding(
                        padding: EdgeInsets.all(32.0),
                        child: Center(child: Text('Ù„Ø§ ØªÙˆØ¬Ø¯ Ù†ØªØ§Ø¦Ø¬ Ù…Ø·Ø§Ø¨Ù‚Ø© Ù„Ù„Ø¨Ø­Ø«')),
                      )
                    else
                      ...provider.filteredStudents.map((student) {
                        final attendanceRate = provider.getStudentAttendanceRate(student['id']);

                        return Container(
                          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                          decoration: const BoxDecoration(
                            border: Border(bottom: BorderSide(color: Colors.black12)),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                flex: 2, 
                                child: Row(
                                  children: [
                                    CircleAvatar(
                                      radius: 14,
                                      backgroundColor: const Color(0xFFE6E6FA),
                                      backgroundImage: student['photo_url'] != null && student['photo_url'].toString().isNotEmpty
                                          ? CachedNetworkImageProvider(student['photo_url'])
                                          : null,
                                      child: (student['photo_url'] == null || student['photo_url'].toString().isEmpty)
                                          ? Text(
                                              (student['full_name'] != null && student['full_name'].toString().isNotEmpty)
                                                  ? student['full_name'][0]
                                                  : '?',
                                              style: const TextStyle(color: Colors.black54, fontWeight: FontWeight.bold, fontSize: 10),
                                            )
                                          : null,
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(child: Text(student['full_name'] ?? 'Ø¨Ø¯ÙˆÙ† Ø§Ø³Ù…', style: const TextStyle(fontWeight: FontWeight.w600))),
                                  ],
                                ),
                              ),
                              Expanded(flex: 1, child: Align(alignment: Alignment.centerRight, child: _buildTag(student['age_group'] ?? 'Baby Class'))),
                              Expanded(flex: 2, child: Text(student['parent_phone'] ?? '01000000000')),
                              Expanded(flex: 2, child: _buildAttendanceBadge(attendanceRate)),
                              Expanded(
                                flex: 1,
                                child: OutlinedButton(
                                  style: OutlinedButton.styleFrom(
                                    backgroundColor: const Color(0xFFE6E6FA),
                                    side: BorderSide.none,
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                                  ),
                                  onPressed: () {
                                    provider.selectStudent(student);
                                  },
                                  child: const Text('ÙØªØ­ Ø§Ù„Ù…Ù„Ù', style: TextStyle(color: Colors.black87, fontSize: 12)),
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTag(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: const Color(0xFFE6E6FA),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(text, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
    );
  }

  Widget _buildAttendanceBadge(String rate) {
    int percentage = int.tryParse(rate.replaceAll('%', '')) ?? 0;

    Color color = Colors.green;
    IconData icon = Icons.check_circle;

    if (percentage < 50) {
      color = Colors.red;
      icon = Icons.cancel;
    } else if (percentage < 75) {
      color = Colors.orange;
      icon = Icons.error;
    }

    return Row(
      children: [
        Icon(icon, color: color, size: 16),
        const SizedBox(width: 4),
        Text(rate, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 13)),
      ],
    );
  }
}
