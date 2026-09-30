import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:smart_academy/features/admin/widgets/add_teacher_modal.dart';
import 'package:smart_academy/features/admin/constants/app_colors.dart';
import 'package:smart_academy/features/admin/providers/admin_provider.dart';
import 'package:smart_academy/views/teacher_detail_view.dart';

class TeachersView extends StatelessWidget {
  final AdminProvider provider;

  const TeachersView({super.key, required this.provider});

  @override
  Widget build(BuildContext context) {
    // Ø§Ù„ØªØ¨Ø¯ÙŠÙ„ Ø¥Ù„Ù‰ Ø´Ø§Ø´Ø© Ø§Ù„ØªÙØ§ØµÙŠÙ„ ÙÙˆØ± Ø§Ø®ØªÙŠØ§Ø± Ù…Ø¯Ø±Ø³
    if (provider.selectedTeacher != null) {
      return TeacherDetailView(provider: provider);
    }

    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        children: [
          // Ø´Ø±ÙŠØ· Ø¥Ø¶Ø§ÙØ© Ù…Ø¯Ø±Ø³ ÙˆØ§Ù„Ø¨Ø­Ø«
          Row(
            children: [
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.sidebarBg,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                icon: const Icon(Icons.add, color: Colors.white, size: 18),
                label: const Text(
                  'Ø§Ø¶Ø§ÙØ© Ù…Ø¯Ø±Ø³ Ø¬Ø¯ÙŠØ¯',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (_) => AddTeacherModal(provider: provider),
                  );
                },
              ),
              const SizedBox(width: 16),
              Expanded(
                child: SizedBox(
                  height: 48,
                  child: TextField(
                    onChanged: (val) => provider.setTeacherSearchQuery(val),
                    decoration: InputDecoration(
                      hintText: 'Ø§Ø¨Ø­Ø« Ø¨Ø£Ø³Ù… Ø§Ù„Ù…Ø¯Ø±Ø³ Ø§Ùˆ Ø§Ù„Ù…Ø§Ø¯Ø©...',
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

          // Ø¬Ø¯ÙˆÙ„ Ø§Ù„Ù…Ø¯Ø±Ø³ÙŠÙ†
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
                    // Ø§Ù„Ù‡ÙŠØ¯Ø±
                    Container(
                      color: AppColors.sidebarBg,
                      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
                      child: const Row(
                        children: [
                          Expanded(
                            flex: 3,
                            child: Text(
                              'Ø§Ø³Ù… Ø§Ù„Ù…Ø¯Ø±Ø³',
                              textAlign: TextAlign.right,
                              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                            ),
                          ),
                          Expanded(
                            flex: 2,
                            child: Text(
                              'Ø§Ù„ÙØ¦Ø© Ø§Ù„Ø¹Ù…Ø±ÙŠØ©',
                              textAlign: TextAlign.right,
                              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                            ),
                          ),
                          Expanded(
                            flex: 3,
                            child: Text(
                              'Ø±Ù‚Ù… Ù‡Ø§ØªÙ Ø§Ù„Ù…Ø¯Ø±Ø³',
                              textAlign: TextAlign.right,
                              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                            ),
                          ),
                          Expanded(
                            flex: 3,
                            child: Text(
                              'Ø§Ù„Ù…Ø§Ø¯Ø©',
                              textAlign: TextAlign.right,
                              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                            ),
                          ),
                          Expanded(
                            flex: 2,
                            child: Text(
                              'Ø§Ù„Ø£Ø¬Ø±Ø§Ø¡Ø§Øª',
                              textAlign: TextAlign.right,
                              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Ù…Ø­ØªÙˆÙ‰ Ø§Ù„ØµÙÙˆÙ
                    if (provider.filteredTeachers.isEmpty)
                      const Padding(
                        padding: EdgeInsets.all(32.0),
                        child: Center(child: Text('Ù„Ø§ ØªÙˆØ¬Ø¯ Ù†ØªØ§Ø¦Ø¬ Ù…Ø·Ø§Ø¨Ù‚Ø©')),
                      )
                    else
                      ...provider.filteredTeachers.map((teacher) {
                        return Container(
                          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
                          decoration: const BoxDecoration(
                            border: Border(bottom: BorderSide(color: Color(0xFFF0F0F0))),
                          ),
                          child: Row(
                            children: [
                              // 1. Ø§Ø³Ù… Ø§Ù„Ù…Ø¯Ø±Ø³
                              Expanded(
                                flex: 3,
                                child: Row(
                                  children: [
                                    CircleAvatar(
                                      radius: 16,
                                      backgroundColor: const Color(0xFFE6E6FA),
                                      backgroundImage: teacher['avatar_url'] != null && teacher['avatar_url'].toString().isNotEmpty
                                          ? CachedNetworkImageProvider(teacher['avatar_url'])
                                          : null,
                                      child: (teacher['avatar_url'] == null || teacher['avatar_url'].toString().isEmpty)
                                          ? Text(
                                              (teacher['full_name'] != null && teacher['full_name'].toString().isNotEmpty)
                                                  ? teacher['full_name'][0]
                                                  : '?',
                                              style: const TextStyle(color: AppColors.sidebarBg, fontWeight: FontWeight.bold, fontSize: 12),
                                            )
                                          : null,
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Text(
                                        teacher['full_name'] ?? '',
                                        textAlign: TextAlign.right,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 14,
                                          color: Colors.black87,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                              // 2. Ø§Ù„ÙØ¦Ø© Ø§Ù„Ø¹Ù…Ø±ÙŠØ©
                              Expanded(
                                flex: 2,
                                child: Align(
                                  alignment: Alignment.centerRight,
                                  child: _buildTag(teacher['age_group'] ?? 'KG1'),
                                ),
                              ),

                              // 3. Ø±Ù‚Ù… Ù‡Ø§ØªÙ Ø§Ù„Ù…Ø¯Ø±Ø³
                              Expanded(
                                flex: 3,
                                child: Text(
                                  teacher['phone'] ?? '',
                                  textAlign: TextAlign.right,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                    color: Colors.black87,
                                  ),
                                ),
                              ),

                              // 4. Ø§Ù„Ù…Ø§Ø¯Ø©
                              Expanded(
                                flex: 3,
                                child: Text(
                                  teacher['subject'] ?? '',
                                  textAlign: TextAlign.right,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                    color: Colors.black87,
                                  ),
                                ),
                              ),

                              // 5. Ø²Ø± ÙØªØ­ Ø§Ù„Ù…Ù„Ù
                              Expanded(
                                flex: 2,
                                child: Align(
                                  alignment: Alignment.centerRight,
                                  child: TextButton(
                                    style: TextButton.styleFrom(
                                      backgroundColor: const Color(0xFFE6E6FA),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                    ),
                                    onPressed: () {
                                      provider.selectTeacher(teacher);
                                    },
                                    child: const Text(
                                      'ÙØªØ­ Ø§Ù„Ù…Ù„Ù',
                                      style: TextStyle(
                                        color: AppColors.sidebarBg,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 13,
                                      ),
                                    ),
                                  ),
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
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFFE6E6FA),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.bold,
          color: AppColors.sidebarBg,
        ),
      ),
    );
  }
}
