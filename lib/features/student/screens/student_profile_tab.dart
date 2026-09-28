import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/widgets/skeleton_loading.dart';
import '../../../providers/theme_provider.dart';
import '../providers/student_provider.dart';
import '../../../services/cloudinary_service.dart';

class StudentProfileTab extends StatefulWidget {
  final String userId;
  final VoidCallback onBackToHome;

  const StudentProfileTab({
    super.key,
    required this.userId,
    required this.onBackToHome,
  });

  @override
  State<StudentProfileTab> createState() => _StudentProfileTabState();
}

class _StudentProfileTabState extends State<StudentProfileTab> {
  bool _isUploading = false;

  Future<void> _uploadProfileImage() async {
    try {
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(source: ImageSource.gallery);
      if (pickedFile == null) return;

      setState(() => _isUploading = true);

      final secureUrl = await CloudinaryService.uploadImage(pickedFile);

      if (secureUrl != null) {
        // Save to Supabase
        await Supabase.instance.client
            .from('students')
            .update({'photo_url': secureUrl})
            .eq('id', widget.userId);

        if (mounted) {
          // Refresh provider
          context.read<StudentProvider>().fetchStudentData(widget.userId, isParentPhone: false);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('تم تحديث الصورة بنجاح!')),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('فشل في رفع الصورة.')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('حدث خطأ: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isUploading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = context.watch<ThemeProvider>().isDarkMode;
    final textColor = isDark ? Colors.white : const Color(0xFF2A1B38);
    final inputBg = isDark ? const Color(0xFF1E1E1E) : Colors.white;
    final provider = context.watch<StudentProvider>();
    final student = provider.student;

    if (student == null) {
      return const SkeletonProfileLoading();
    }

    if (student.name.trim().isEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        provider.fetchStudentData(widget.userId, isParentPhone: false);
      });
    }

    final studentName = (student.name.trim().isNotEmpty) ? student.name : 'طالب';
    final studentGrade = (student.grade.trim().isNotEmpty) ? student.grade : 'غير محدد';
    final initial = studentName.isNotEmpty ? studentName[0] : '?';

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Back Button
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              onPressed: widget.onBackToHome,
              iconAlignment: IconAlignment.end,
              icon: Icon(Icons.arrow_forward_rounded, color: textColor),
              label: Text(
                'عودة القائمة',
                style: TextStyle(
                  color: textColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              style: TextButton.styleFrom(
                padding: EdgeInsets.zero,
                alignment: Alignment.centerLeft,
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Avatar
          Center(
            child: CircleAvatar(
              radius: 50,
              backgroundColor: Colors.grey.shade300,
              backgroundImage:
                  student.photoUrl != null && student.photoUrl!.isNotEmpty ? NetworkImage(student.photoUrl!) : null,
              child: (student.photoUrl == null || student.photoUrl!.isEmpty)
                  ? Text(
                      initial,
                      style: const TextStyle(
                        fontSize: 40,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    )
                  : null,
            ),
          ),
          const SizedBox(height: 16),

          // Name
          Text(
            studentName,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: textColor,
              fontSize: 28,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'الصف: $studentGrade',
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.grey,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 24),

          // Back to home button
          ElevatedButton(
            onPressed: widget.onBackToHome,
            style: ElevatedButton.styleFrom(
              backgroundColor: inputBg,
              foregroundColor: textColor,
              padding: const EdgeInsets.symmetric(vertical: 16),
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text(
              'عودة للرئيسية',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(height: 40),

          // Student Info Section
          Text(
            'بيانات الطالب',
            style: TextStyle(
              color: textColor,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 20),

          // Student Name
          Text(
            'اسم الطالب:',
            style: TextStyle(color: textColor, fontSize: 14),
          ),
          const SizedBox(height: 8),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            decoration: BoxDecoration(
              color: inputBg,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              studentName,
              style: TextStyle(color: textColor, fontSize: 16),
            ),
          ),
          const SizedBox(height: 20),

          // Parent Phone
          Text(
            'رقم هاتف ولي الأمر:',
            style: TextStyle(color: textColor, fontSize: 14),
          ),
          const SizedBox(height: 8),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            decoration: BoxDecoration(
              color: inputBg,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              student.parentPhone,
              textDirection: TextDirection.ltr,
              style: TextStyle(color: textColor, fontSize: 16),
            ),
          ),
          const SizedBox(height: 20),

          // Upload Image Placeholder
          Text(
            'ارفع الصورة الشخصية:',
            style: TextStyle(color: textColor, fontSize: 14),
          ),
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerRight,
            child: InkWell(
              onTap: _isUploading ? null : _uploadProfileImage,
              child: Container(
                width: 100,
                height: 80,
                decoration: BoxDecoration(
                  color: Colors.grey.shade400,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: _isUploading
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                        )
                      : const Icon(Icons.upload_rounded, color: Colors.white, size: 32),
                ),
              ),
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}
