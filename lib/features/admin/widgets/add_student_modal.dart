import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../providers/admin_provider.dart';

class AddStudentModal extends StatefulWidget {
  final AdminProvider provider;

  const AddStudentModal({super.key, required this.provider});

  @override
  State<AddStudentModal> createState() => _AddStudentModalState();
}

class _AddStudentModalState extends State<AddStudentModal> {
  final nameCtrl = TextEditingController();
  final phoneCtrl = TextEditingController();
  String selectedAgeGroup = 'Baby Class';

  @override
  void dispose() {
    nameCtrl.dispose();
    phoneCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: Container(
          width: 480,
          padding: const EdgeInsets.all(28),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: const Border(
              top: BorderSide(
                color: AppColors.modalBorder, // لون البوردر المعتمد
                width: 8, // السُمك 8px
              ),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'إضافة طالب جديد',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppColors.modalBorder,
                ),
              ),
              const SizedBox(height: 24),
              const Align(
                alignment: Alignment.centerRight,
                child: Text('اسم الطالب:', style: TextStyle(fontSize: 12, color: Colors.black87)),
              ),
              const SizedBox(height: 6),
              SizedBox(
                height: 40,
                child: TextField(
                  controller: nameCtrl,
                  decoration: outlineInputDecoration(),
                ),
              ),
              const SizedBox(height: 16),
              const Align(
                alignment: Alignment.centerRight,
                child: Text('رقم هاتف ولي امر الطالب:', style: TextStyle(fontSize: 12, color: Colors.black87)),
              ),
              const SizedBox(height: 6),
              SizedBox(
                height: 40,
                child: TextField(
                  controller: phoneCtrl,
                  keyboardType: TextInputType.phone,
                  decoration: outlineInputDecoration(),
                ),
              ),
              const SizedBox(height: 16),
              const Align(
                alignment: Alignment.centerRight,
                child: Text('الفئة العمرية:', style: TextStyle(fontSize: 12, color: Colors.black87)),
              ),
              const SizedBox(height: 6),
              SizedBox(
                height: 40,
                child: DropdownButtonFormField<String>(
                  value: selectedAgeGroup,
                  items: const [
                    DropdownMenuItem(value: 'Baby Class', child: Text('Baby Class', style: TextStyle(fontSize: 13))),
                    DropdownMenuItem(value: 'KG1', child: Text('KG1', style: TextStyle(fontSize: 13))),
                    DropdownMenuItem(value: 'KG2', child: Text('KG2', style: TextStyle(fontSize: 13))),
                  ],
                  onChanged: (val) => setState(() => selectedAgeGroup = val!),
                  decoration: outlineInputDecoration(),
                ),
              ),
              const SizedBox(height: 28),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.addBtnBg,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      onPressed: () async {
                        if (nameCtrl.text.isNotEmpty) {
                          bool success = await widget.provider.addStudent(
                            fullName: nameCtrl.text,
                            parentPhone: phoneCtrl.text,
                            ageGroup: selectedAgeGroup,
                          );
                          if (mounted) {
                            if (success) {
                              Navigator.pop(context);
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('تم اضافة الطالب بنجاح'), backgroundColor: Colors.green),
                              );
                            } else {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('حدث خطأ أثناء إضافة الطالب. يرجى التأكد من تطابق أعمدة قاعدة البيانات.'), backgroundColor: Colors.red),
                              );
                            }
                          }
                        }
                      },
                      child: const Text('اضافة الطالب', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        backgroundColor: const Color(0xFFE6E6FA),
                        side: BorderSide.none,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      onPressed: () => Navigator.pop(context),
                      child: const Text('إلغاء', style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              )
            ],
          ),
        ),
      ),
    );
  }

  InputDecoration outlineInputDecoration() {
    return InputDecoration(
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
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
        borderSide: const BorderSide(color: AppColors.modalBorder),
      ),
    );
  }
}