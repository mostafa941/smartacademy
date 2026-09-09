import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../providers/admin_provider.dart';

class EditStudentModal extends StatefulWidget {
  final AdminProvider provider;
  final Map<String, dynamic> student;

  const EditStudentModal({super.key, required this.provider, required this.student});

  @override
  State<EditStudentModal> createState() => _EditStudentModalState();
}

class _EditStudentModalState extends State<EditStudentModal> {
  late TextEditingController _nameController;
  late TextEditingController _phoneController;
  late String _selectedAgeGroup;

  final List<String> _ageGroups = ['Baby Class', 'KG1', 'KG2'];

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.student['full_name'] ?? '');
    _phoneController = TextEditingController(text: widget.student['parent_phone'] ?? '');
    _selectedAgeGroup = widget.student['age_group'] ?? 'KG1';
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('تعديل بيانات الطالب', textAlign: TextAlign.right),
      content: SizedBox(
        width: 400,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(labelText: 'اسم الطالب'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _phoneController,
              decoration: const InputDecoration(labelText: 'رقم ولي الأمر'),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: _ageGroups.contains(_selectedAgeGroup) ? _selectedAgeGroup : _ageGroups.first,
              items: _ageGroups.map((group) => DropdownMenuItem(value: group, child: Text(group))).toList(),
              onChanged: (val) => setState(() => _selectedAgeGroup = val!),
              decoration: const InputDecoration(labelText: 'المرحلة / الفئة العمرية'),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('إلغاء'),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(backgroundColor: AppColors.sidebarBg),
          onPressed: () async {
            final success = await widget.provider.updateStudent(
              id: widget.student['id'],
              fullName: _nameController.text,
              parentPhone: _phoneController.text,
              ageGroup: _selectedAgeGroup,
            );
            if (context.mounted) {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(success ? 'تم التعديل بنجاح' : 'حدث خطأ أثناء التعديل')),
              );
            }
          },
          child: const Text('حفظ التعديلات', style: TextStyle(color: Colors.white)),
        ),
      ],
    );
  }
}