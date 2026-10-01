import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/widgets/skeleton_loading.dart';
import '../../../providers/theme_provider.dart';
import '../../../services/cloudinary_service.dart';

class TeacherProfileTab extends StatefulWidget {
  final String userId;
  final VoidCallback onBackToHome;
  final void Function(String)? onAvatarUpdated;

  const TeacherProfileTab({
    super.key,
    required this.userId,
    required this.onBackToHome,
    this.onAvatarUpdated,
  });

  @override
  State<TeacherProfileTab> createState() => _TeacherProfileTabState();
}

class _TeacherProfileTabState extends State<TeacherProfileTab> {
  final _supabase = Supabase.instance.client;
  bool _isLoading = true;
  bool _isSaving = false;
  bool _isUploading = false;

  String _fullName = '';
  String _jobDescription = '';
  String _teacherTitle = ''; // e.g. معلمة عربي - فئة KG1, KG2
  String _avatarUrl = '';

  late TextEditingController _nameController;
  late TextEditingController _descController;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _descController = TextEditingController();
    _fetchProfileData();
  }

  Future<void> _fetchProfileData() async {
    setState(() => _isLoading = true);
    try {
      // Fetch profile data
      final profileRes = await _supabase
          .from('profiles')
          .select('full_name, avatar_url, job_description')
          .eq('id', widget.userId)
          .maybeSingle();

      if (profileRes != null) {
        _fullName = profileRes['full_name'] ?? '';
        _avatarUrl = profileRes['avatar_url'] ?? '';
        _jobDescription = profileRes['job_description'] ?? '';
      }

      // Fetch teacher subjects
      final subjectRes = await _supabase
          .from('teacher_subjects')
          .select('subjects(name)')
          .eq('teacher_id', widget.userId);

      List<String> subjectNames = (subjectRes as List)
          .map((e) => e['subjects']?['name']?.toString() ?? '')
          .where((name) => name.isNotEmpty)
          .toList();
      
      String subjects = subjectNames.join(', ');

      // Fetch teacher stages
      final stageRes = await _supabase
          .from('teacher_stages')
          .select('stages(name)')
          .eq('teacher_id', widget.userId);

      List<String> stageNames = (stageRes as List)
          .map((e) => e['stages']?['name']?.toString() ?? '')
          .where((name) => name.isNotEmpty)
          .toList();
      
      String stages = stageNames.join(', ');

      String title = '';
      if (subjects.isNotEmpty) title += 'معلم $subjects';

      if (stages.isNotEmpty) {
        if (title.isNotEmpty) title += ' - ';
        title += 'فئة $stages';
      }
      _teacherTitle = title.isEmpty ? 'معلم' : title;

      _nameController.text = _fullName;
      _descController.text = _jobDescription;

      if (mounted) setState(() => _isLoading = false);
    } catch (e) {
      debugPrint('Error fetching profile: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _saveProfile() async {
    setState(() => _isSaving = true);
    try {
      await _supabase.from('profiles').update({
        'full_name': _nameController.text.trim(),
        'job_description': _descController.text.trim(),
      }).eq('id', widget.userId);

      _fullName = _nameController.text.trim();
      _jobDescription = _descController.text.trim();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تم حفظ التعديلات بنجاح')),
        );
        setState(() {
          _isSaving = false;
        });
      }
    } catch (e) {
      debugPrint('Error saving profile: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('حدث خطأ أثناء الحفظ')),
        );
      }
    }
  }

  Future<void> _uploadAvatar() async {
    try {
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(source: ImageSource.gallery);
      
      if (pickedFile == null) return;

      setState(() => _isUploading = true);

      final secureUrl = await CloudinaryService.uploadImage(pickedFile);

      if (secureUrl != null) {
        await _supabase.from('profiles').update({
          'avatar_url': secureUrl,
        }).eq('id', widget.userId);

        if (mounted) {
          setState(() {
            _avatarUrl = secureUrl!;
            _isUploading = false;
          });
          widget.onAvatarUpdated?.call(secureUrl!);
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
      if (mounted) setState(() => _isUploading = false);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : const Color(0xFF2A1B38);
    final cardColor = isDark ? const Color(0xFF1E1E1E) : Colors.white;

    if (_isLoading) {
      return const SkeletonProfileLoading();
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        children: [
          const SizedBox(height: 20),
          // Back button
          Align(
            alignment: Alignment.centerRight,
            child: TextButton.icon(
              onPressed: widget.onBackToHome,
              iconAlignment: IconAlignment.end, // هذه الخاصية تقوم بنقل الأيقونة إلى جهة اليمين (بعد النص)
              icon: Icon(Icons.arrow_forward_rounded, color: textColor),
              label: Text(
                'عودة القائمة',
                style: TextStyle(
                  color: textColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          
          Expanded(
            child: SingleChildScrollView(
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(28),
                decoration: BoxDecoration(
                  color: cardColor,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.08),
                      blurRadius: 16,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    // Avatar section
                    Column(
                      children: [
                        GestureDetector(
                          onTap: _uploadAvatar,
                          child: Stack(
                            children: [
                              Container(
                                width: 120,
                                height: 120,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: Colors.grey[200],
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.1),
                                      blurRadius: 8,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: _isUploading
                                    ? const Center(
                                        child: CircularProgressIndicator(),
                                      )
                                    : ClipOval(
                                        child: _avatarUrl.isNotEmpty
                                            ? CachedNetworkImage(
                                                imageUrl: _avatarUrl,
                                                fit: BoxFit.cover,
                                                placeholder: (_, __) => const Center(
                                                  child: CircularProgressIndicator(),
                                                ),
                                                errorWidget: (_, __, ___) => Icon(
                                                  Icons.person,
                                                  size: 60,
                                                  color: Colors.grey[400],
                                                ),
                                              )
                                            : Icon(
                                                Icons.person,
                                                size: 60,
                                                color: Colors.grey[400],
                                              ),
                                      ),
                              ),
                              Positioned(
                                bottom: 0,
                                right: 0,
                                child: Container(
                                  width: 36,
                                  height: 36,
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF2A1B38),
                                    shape: BoxShape.circle,
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.2),
                                        blurRadius: 4,
                                        offset: const Offset(0, 1),
                                      ),
                                    ],
                                  ),
                                  child: const Icon(
                                    Icons.camera_alt,
                                    color: Colors.white,
                                    size: 20,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          _fullName.isNotEmpty ? _fullName : 'اسم المعلمة',
                          style: TextStyle(
                            color: textColor,
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _teacherTitle,
                          style: const TextStyle(
                            color: Colors.grey,
                            fontSize: 16,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),

                    const SizedBox(height: 40),

                    // Form section
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          'الاسم الكامل',
                          style: TextStyle(
                            color: textColor,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        TextField(
                          controller: _nameController,
                          textAlign: TextAlign.right,
                          style: TextStyle(color: textColor),
                          decoration: InputDecoration(
                            hintText: 'أدخل الاسم الكامل',
                            hintStyle: TextStyle(color: textColor.withOpacity(0.5)),
                            filled: true,
                            fillColor: isDark 
                                ? const Color(0xFF2A2A2A) 
                                : const Color(0xFFF8F9FA),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide.none,
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 16,
                            ),
                          ),
                        ),

                        const SizedBox(height: 24),

                        Text(
                          'الوصف الوظيفي',
                          style: TextStyle(
                            color: textColor,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        TextField(
                          controller: _descController,
                          textAlign: TextAlign.right,
                          style: TextStyle(color: textColor),
                          maxLines: 3,
                          decoration: InputDecoration(
                            hintText: 'أدخل وصف مختصر عن عملك',
                            hintStyle: TextStyle(color: textColor.withOpacity(0.5)),
                            filled: true,
                            fillColor: isDark 
                                ? const Color(0xFF2A2A2A) 
                                : const Color(0xFFF8F9FA),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide.none,
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 16,
                            ),
                          ),
                        ),

                        const SizedBox(height: 32),

                        // Save button
                        SizedBox(
                          width: double.infinity,
                          height: 48,
                          child: ElevatedButton(
                            onPressed: _isSaving ? null : _saveProfile,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF2A1B38),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: _isSaving
                                ? const CircularProgressIndicator(color: Colors.white)
                                : const Text(
                                    'حفظ التعديلات',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                          ),
                        ),

                        const SizedBox(height: 24),

                        // Theme toggle
                        Consumer<ThemeProvider>(
                          builder: (context, themeProvider, child) {
                            return Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: isDark 
                                    ? const Color(0xFF2A2A2A) 
                                    : const Color(0xFFF8F9FA),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Switch(
                                    value: themeProvider.isDarkMode,
                                    onChanged: (value) {
                                      themeProvider.toggleTheme();
                                    },
                                    activeColor: const Color(0xFF2A1B38),
                                  ),
                                  Text(
                                    'الوضع الليلي',
                                    style: TextStyle(
                                      color: textColor,
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),

                        const SizedBox(height: 16),

                        // View all students button
                        SizedBox(
                          width: double.infinity,
                          height: 48,
                          child: OutlinedButton(
                            onPressed: widget.onBackToHome,
                            style: OutlinedButton.styleFrom(
                              side: BorderSide(color: textColor.withOpacity(0.3)),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: const Text(
                              'رؤية جميع الطلاب',
                              style: TextStyle(
                                fontSize: 16,
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
        ],
      ),
    );
  }
}