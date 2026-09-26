import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../constants/app_colors.dart';
import '../providers/admin_provider.dart';

class AddTeacherModal extends StatefulWidget {
  final AdminProvider provider;

  const AddTeacherModal({super.key, required this.provider});

  @override
  State<AddTeacherModal> createState() => _AddTeacherModalState();
}

class _AddTeacherModalState extends State<AddTeacherModal> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _subjectController = TextEditingController();

  // قائمة الفئات المختارة
  final List<String> _selectedAgeGroups = [];
  bool _isLoading = false;

  final List<String> _ageGroups = [
    'Baby Class',
    'KG1',
    'KG2',
  ];

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _subjectController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedAgeGroups.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('برجاء اختيار فئة عمرية واحدة على الأقل'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final success = await widget.provider.addTeacher(
        fullName: _nameController.text.trim(),
        phone: _phoneController.text.trim(),
        subject: _subjectController.text.trim(),
        ageGroups: _selectedAgeGroups,
      );

      setState(() => _isLoading = false);

      if (mounted) {
        if (success) {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('تم إضافة المدرس بنجاح')),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('حدث خطأ أثناء إضافة المدرس. راجع التيرمينال للتفاصيل.'),
            ),
          );
        }
      }
    } on PostgrestException catch (e) {
      debugPrint('================ FULL SUPABASE ERROR ================');
      debugPrint('Code: ${e.code}');
      debugPrint('Message: ${e.message}');
      debugPrint('Details: ${e.details}');
      debugPrint('Hint: ${e.hint}');
      debugPrint('=====================================================');

      setState(() => _isLoading = false);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('خطأ Supabase (${e.code}): ${e.message}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      debugPrint('================ GENERAL ERROR ================');
      debugPrint(e.toString());
      debugPrint('===============================================');

      setState(() => _isLoading = false);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('خطأ عام: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: 480,
        padding: const EdgeInsets.all(28),
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
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'إضافة مدرس جديد',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppColors.sidebarBg,
                ),
              ),
              const SizedBox(height: 20),

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
              TextFormField(
                controller: _subjectController,
                textAlign: TextAlign.right,
                validator: (val) =>
                    val == null || val.isEmpty ? 'برجاء إدخال المادة الدراسية' : null,
                decoration: _inputDecoration(''),
              ),
              const SizedBox(height: 16),

              // الفئات العمرية (اختيار متعدد)
              _buildFieldLabel('الفئة العمرية (يمكنك اختيار أكثر من فئة):'),
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerRight,
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _ageGroups.map<Widget>((group) {
                    final isSelected = _selectedAgeGroups.contains(group);
                    return FilterChip(
                      label: Text(group),
                      selected: isSelected,
                      selectedColor: AppColors.sidebarBg.withOpacity(0.15),
                      checkmarkColor: AppColors.sidebarBg, // استبدال checkColor بـ checkmarkColor
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                        side: BorderSide(
                          color: isSelected ? AppColors.sidebarBg : Colors.black26,
                        ),
                      ),
                      labelStyle: TextStyle(
                        color: isSelected ? AppColors.sidebarBg : Colors.black87,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      ),
                      onSelected: (selected) {
                        setState(() {
                          if (selected) {
                            _selectedAgeGroups.add(group);
                          } else {
                            _selectedAgeGroups.remove(group);
                          }
                        });
                      },
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: 28),

              // الأزرار
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
                              'اضافة المدرس',
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