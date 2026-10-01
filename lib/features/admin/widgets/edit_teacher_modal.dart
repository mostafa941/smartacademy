import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../providers/admin_provider.dart';

class EditTeacherModal extends StatefulWidget {
  final AdminProvider provider;
  final Map<String, dynamic> teacher;

  const EditTeacherModal({
    super.key,
    required this.provider,
    required this.teacher,
  });

  @override
  State<EditTeacherModal> createState() => _EditTeacherModalState();
}

class _EditTeacherModalState extends State<EditTeacherModal> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _phoneController;

  String? _selectedSubject;
  final List<String> _subjects = [
    'English',
    'Math',
    'UcMath',
    'عربي',
    'حساب',
    'قرأن و سلوكيات و أداب',
  ];

  List<String> _selectedAgeGroups = [];
  bool _isLoading = false;

  final List<String> _ageGroups = [
    'Baby Class',
    'KG1',
    'KG2',
  ];

  @override
  void initState() {
    super.initState();
    _nameController =
        TextEditingController(text: widget.teacher['full_name'] ?? '');
    _phoneController =
        TextEditingController(text: widget.teacher['phone'] ?? '');

    final currentSubject = widget.teacher['subject'] ?? '';
    if (currentSubject.isNotEmpty && currentSubject != 'غير محدد') {
      if (_subjects.contains(currentSubject)) {
        _selectedSubject = currentSubject;
      } else {
        _subjects.add(currentSubject);
        _selectedSubject = currentSubject;
      }
    }

    final currentAgeGroup = widget.teacher['age_group'] ?? '';
    if (currentAgeGroup != 'غير محدد' && currentAgeGroup.isNotEmpty) {
      _selectedAgeGroups =
          currentAgeGroup.split(',').map((e) => e.trim()).toList();
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedAgeGroups.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('برجاء اختيار مرحلة تعليمية واحدة على الأقل'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final success = await widget.provider.updateTeacher(
        teacherId: widget.teacher['id'],
        fullName: _nameController.text.trim(),
        phone: _phoneController.text.trim(),
        subject: _selectedSubject ?? '',
        ageGroups: _selectedAgeGroups,
      );

      setState(() => _isLoading = false);

      if (mounted) {
        if (success) {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('تم تعديل بيانات المدرس بنجاح')),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('حدث خطأ أثناء تعديل بيانات المدرس.'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('خطأ: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final dialogWidth = screenWidth > 900 ? 650.0 : screenWidth * 0.85;

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: dialogWidth,
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: const Border(
            top: BorderSide(
              color: AppColors.sidebarBg,
              width: 8,
            ),
          ),
        ),
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'تعديل بيانات المدرس',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: AppColors.sidebarBg,
                  ),
                ),
                const SizedBox(height: 24),

                // اسم المدرس
                _buildFieldLabel('اسم المدرس:'),
                const SizedBox(height: 6),
                TextFormField(
                  controller: _nameController,
                  textAlign: TextAlign.right,
                  validator: (val) =>
                      val == null || val.isEmpty ? 'برجاء إدخال اسم المدرس' : null,
                  decoration: _inputDecoration(''),
                ),
                const SizedBox(height: 16),

                // رقم هاتف المدرس
                _buildFieldLabel('رقم هاتف المدرس:'),
                const SizedBox(height: 6),
                TextFormField(
                  controller: _phoneController,
                  textAlign: TextAlign.right,
                  keyboardType: TextInputType.phone,
                  validator: (val) =>
                      val == null || val.isEmpty ? 'برجاء إدخال رقم الهاتف' : null,
                  decoration: _inputDecoration(''),
                ),
                const SizedBox(height: 16),

                // المادة الدراسية
                _buildFieldLabel('المادة الدراسية:'),
                const SizedBox(height: 6),
                DropdownButtonFormField<String>(
                  value: _selectedSubject,
                  alignment: AlignmentDirectional.centerEnd,
                  items: _subjects.map((subject) {
                    return DropdownMenuItem(
                      value: subject,
                      child: Text(
                        subject,
                        style: const TextStyle(
                          fontFamily: 'smart_font',
                          color: Color(0xFF2A1B38),
                        ),
                      ),
                    );
                  }).toList(),
                  onChanged: (val) {
                    setState(() {
                      _selectedSubject = val;
                    });
                  },
                  validator: (val) =>
                      val == null || val.isEmpty ? 'برجاء اختيار المادة الدراسية' : null,
                  decoration: _inputDecoration(''),
                  icon: const Icon(Icons.arrow_drop_down, color: Color(0xFF724F96)),
                  dropdownColor: Colors.white,
                ),
                const SizedBox(height: 20),

                // اختيار المراحل بـ Checkbox
                _buildFieldLabel('المراحل التعليمية المسندة:'),
                const SizedBox(height: 8),
                Container(
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.black26),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    children: _ageGroups.map((group) {
                      final isSelected = _selectedAgeGroups.contains(group);
                      return CheckboxListTile(
                        title: Text(
                          group,
                          textAlign: TextAlign.right,
                          style: const TextStyle(fontSize: 14),
                        ),
                        value: isSelected,
                        activeColor: AppColors.sidebarBg,
                        controlAffinity: ListTileControlAffinity.trailing,
                        onChanged: (bool? checked) {
                          setState(() {
                            if (checked == true) {
                              if (!_selectedAgeGroups.contains(group)) {
                                _selectedAgeGroups.add(group);
                              }
                            } else {
                              _selectedAgeGroups.remove(group);
                            }
                          });
                        },
                      );
                    }).toList(),
                  ),
                ),
                const SizedBox(height: 32),

                // أزرار التحكم
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          backgroundColor: const Color(0xFFE6E6FA),
                          side: BorderSide.none,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        onPressed: () => Navigator.pop(context),
                        child: const Text(
                          'إلغاء',
                          style: TextStyle(
                            color: Colors.black87,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.addBtnBg,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        onPressed: _isLoading ? null : _submit,
                        child: _isLoading
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                ),
                              )
                            : const Text(
                                'حفظ التعديلات',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFieldLabel(String label) {
    return Align(
      alignment: Alignment.centerRight,
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 13,
          color: Colors.black87,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: Colors.black26),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: Colors.black26),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: AppColors.sidebarBg),
      ),
    );
  }
}