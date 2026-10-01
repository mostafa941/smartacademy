import 'package:flutter/material.dart';
import 'package:smart_academy/features/admin/constants/app_colors.dart';
import 'package:smart_academy/features/admin/providers/admin_provider.dart';

class SupervisorView extends StatelessWidget {
  final AdminProvider provider;

  const SupervisorView({super.key, required this.provider});

  @override
  Widget build(BuildContext context) {
    // قائمة المدرسين الحقيقية من الداتا بيز مع تصفير التفاعلات لعدم وجود تطبيق المشرفة بعد
    final teachersList = provider.teachers;

    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // كروت إحصائيات للمشرفة
          Row(
            children: [
              Expanded(child: _buildStatCard('إجمالي الملاحظات', '0')),
              const SizedBox(width: 16),
              Expanded(child: _buildStatCard('التقارير المستلمة', '0')),
              const SizedBox(width: 16),
              Expanded(child: _buildStatCard('المدرسين المتابعين', '${provider.totalTeachers}')),
            ],
          ),
          const SizedBox(height: 32),
          const Text(
            'نشاط المشرفة وتقارير المدرسين (نسخة تجريبية)',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 16),
          // جدول نشاط المشرفة
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
                    // الهيدر
                    Container(
                      color: AppColors.sidebarBg,
                      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
                      child: const Row(
                        children: [
                          Expanded(flex: 2, child: Text('اسم المدرس', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
                          Expanded(flex: 1, child: Text('الملاحظات', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
                          Expanded(flex: 3, child: Text('آخر تقرير مرسل', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
                          Expanded(flex: 3, child: Text('الملخص الأسبوعي للمشرفة', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
                        ],
                      ),
                    ),
                    // محتوى الصفوف
                    if (teachersList.isEmpty)
                      const Padding(
                        padding: EdgeInsets.all(32.0),
                        child: Center(child: Text('لا يوجد مدرسين حالياً')),
                      )
                    else
                      ...teachersList.map((t) {
                        return Container(
                          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
                          decoration: const BoxDecoration(
                            border: Border(bottom: BorderSide(color: Color(0xFFF0F0F0))),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                flex: 2, 
                                child: Text(t['full_name'] ?? 'بدون اسم', style: const TextStyle(fontWeight: FontWeight.bold))
                              ),
                              Expanded(
                                flex: 1, 
                                child: Align(
                                  alignment: Alignment.centerRight,
                                  child: _buildTag('0 ملاحظة', Colors.green)
                                )
                              ),
                              const Expanded(
                                flex: 3, 
                                child: Text('لا يوجد تقارير بعد', style: TextStyle(color: Colors.grey))
                              ),
                              const Expanded(
                                flex: 3, 
                                child: Text('لا يوجد ملخص بعد', style: TextStyle(color: Colors.grey))
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

  Widget _buildStatCard(String title, String count) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 14,
              color: Colors.grey,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            count,
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: AppColors.sidebarBg,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTag(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: color,
        ),
      ),
    );
  }
}
