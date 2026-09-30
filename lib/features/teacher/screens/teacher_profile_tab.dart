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
  String _teacherTitle = ''; // e.g. Ù…Ø¹Ù„Ù…Ø© Ø¹Ø±Ø¨ÙŠ - ÙØ¦Ø© KG1, KG2
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
      // Fetch profile
      final profileRes = await _supabase
          .from('profiles')
          .select('full_name, phone')
          .eq('id', widget.userId)
          .single();

      _fullName = profileRes['full_name'] ?? '';
      
      // Attempt to fetch description/avatar_url if they exist, catch silently if columns are missing
      try {
        final extraRes = await _supabase
            .from('profiles')
            .select('description, avatar_url')
            .eq('id', widget.userId)
            .single();
        _jobDescription = extraRes['description'] ?? '';
        _avatarUrl = extraRes['avatar_url'] ?? '';
      } catch (_) {
        // columns might not exist yet
      }

      // Fetch stages and subjects for title
      final stagesRes = await _supabase
          .from('teacher_stages')
          .select('stages(name)')
          .eq('teacher_id', widget.userId);
          
      final subjectsRes = await _supabase
          .from('teacher_subjects')
          .select('subjects(name)')
          .eq('teacher_id', widget.userId);

      final stages = (stagesRes as List)
          .map((e) => e['stages']['name'].toString())
          .join(', ');
          
      final subjects = (subjectsRes as List)
          .map((e) => e['subjects']['name'].toString())
          .join(', ');

      String title = '';
      if (subjects.isNotEmpty) title += 'Ù…Ø¹Ù„Ù… $subjects';
      if (stages.isNotEmpty) {
        if (title.isNotEmpty) title += ' - ';
        title += 'ÙØ¦Ø© $stages';
      }
      _teacherTitle = title.isEmpty ? 'Ù…Ø¹Ù„Ù…' : title;

      _nameController.text = _fullName;
      _descController.text = _jobDescription;

    } catch (e) {
      debugPrint('Error fetching profile: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _saveProfile() async {
    setState(() => _isSaving = true);
    try {
      await _supabase.from('profiles').update({
        'full_name': _nameController.text.trim(),
      }).eq('id', widget.userId);
      
      // Try saving description if column exists
      try {
        await _supabase.from('profiles').update({
          'description': _descController.text.trim(),
        }).eq('id', widget.userId);
      } catch (_) {}
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('ØªÙ… Ø­ÙØ¸ Ø§Ù„ØªØ¹Ø¯ÙŠÙ„Ø§Øª Ø¨Ù†Ø¬Ø§Ø­')),
        );
        setState(() {
          _fullName = _nameController.text.trim();
          _jobDescription = _descController.text.trim();
        });
      }
    } catch (e) {
      debugPrint('Error saving profile: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Ø­Ø¯Ø« Ø®Ø·Ø£ Ø£Ø«Ù†Ø§Ø¡ Ø§Ù„Ø­ÙØ¸')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  Future<void> _onUploadImage() async {
    try {
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(source: ImageSource.gallery);
      if (pickedFile == null) return;

      setState(() => _isUploading = true);

      final secureUrl = await CloudinaryService.uploadImage(pickedFile);

      if (secureUrl != null) {
        // Save to Supabase
        await _supabase
            .from('profiles')
            .update({'avatar_url': secureUrl})
            .eq('id', widget.userId);

        if (mounted) {
          setState(() {
            _avatarUrl = secureUrl;
          });
          widget.onAvatarUpdated?.call(secureUrl);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('ØªÙ… ØªØ­Ø¯ÙŠØ« Ø§Ù„ØµÙˆØ±Ø© Ø¨Ù†Ø¬Ø§Ø­!')),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('ÙØ´Ù„ ÙÙŠ Ø±ÙØ¹ Ø§Ù„ØµÙˆØ±Ø©.')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ø­Ø¯Ø« Ø®Ø·Ø£: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isUploading = false);
      }
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
    final isDark = context.watch<ThemeProvider>().isDarkMode;
    final textColor = isDark ? Colors.white : const Color(0xFF2A1B38);
    final inputBg = isDark ? const Color(0xFF1E1E1E) : Colors.white;

    if (_isLoading) {
      return const SkeletonProfileLoading();
    }

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
              iconAlignment: IconAlignment.end, // Ù‡Ø°Ù‡ Ø§Ù„Ø®Ø§ØµÙŠØ© ØªÙ‚ÙˆÙ… Ø¨Ù†Ù‚Ù„ Ø§Ù„Ø£ÙŠÙ‚ÙˆÙ†Ø© Ø¥Ù„Ù‰ Ø¬Ù‡Ø© Ø§Ù„ÙŠÙ…ÙŠÙ† (Ø¨Ø¹Ø¯ Ø§Ù„Ù†Øµ)
              icon: Icon(Icons.arrow_forward_rounded, color: textColor),
              label: Text(
                'Ø¹ÙˆØ¯Ø© Ø§Ù„Ù‚Ø§Ø¦Ù…Ø©',
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
              backgroundImage: _avatarUrl.isNotEmpty ? CachedNetworkImageProvider(_avatarUrl) : null,
              child: _avatarUrl.isEmpty
                  ? Text(
                      _fullName.isNotEmpty ? _fullName[0] : '?',
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
          
          // Name and Title
          Text(
            _fullName,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: textColor,
              fontSize: 28,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _teacherTitle,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.grey,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 24),
          
          // Show all students button
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
              'Ø±Ø¤ÙŠØ© Ø¬Ù…ÙŠØ¹ Ø§Ù„Ø·Ù„Ø§Ø¨',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(height: 40),
          
          // Edit Profile Section
          Text(
            'ØªØ¹Ø¯ÙŠÙ„ Ø§Ù„Ø¨Ø±ÙˆÙØ§ÙŠÙ„ Ø§Ù„Ø´Ø®ØµÙŠ',
            style: TextStyle(
              color: textColor,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 20),
          
          // Teacher Name Input
          Text(
            'Ø§Ø³Ù… Ø§Ù„Ù…Ø¹Ù„Ù…Ø©:',
            style: TextStyle(color: textColor, fontSize: 14),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _nameController,
            style: TextStyle(color: textColor),
            decoration: InputDecoration(
              hintText: 'Ø£Ø¯Ø®Ù„ Ø§Ù„Ø§Ø³Ù…',
              hintStyle: const TextStyle(color: Colors.grey),
              filled: true,
              fillColor: inputBg,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            ),
          ),
          const SizedBox(height: 20),
          
          // Job Description Input
          Text(
            'Ø§Ù„ÙˆØµÙ Ø§Ù„ÙˆØ¸ÙŠÙÙŠ:',
            style: TextStyle(color: textColor, fontSize: 14),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _descController,
            style: TextStyle(color: textColor),
            maxLines: 4,
            decoration: InputDecoration(
              hintText: 'Ø§ÙƒØªØ¨ ÙˆØµÙØ§Ù‹ Ù…Ø®ØªØµØ±Ø§Ù‹ Ø¹Ù†Ùƒ',
              hintStyle: const TextStyle(color: Colors.grey),
              filled: true,
              fillColor: inputBg,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            ),
          ),
          const SizedBox(height: 20),
          
          // Upload Image
          Text(
            'Ø§Ø±ÙØ¹ Ø§Ù„ØµÙˆØ±Ø© Ø§Ù„Ø´Ø®ØµÙŠØ©:',
            style: TextStyle(color: textColor, fontSize: 14),
          ),
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerRight,
            child: InkWell(
              onTap: _isUploading ? null : _onUploadImage,
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
          const SizedBox(height: 40),
          
          // Save Button
          ElevatedButton(
            onPressed: _isSaving ? null : _saveProfile,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF724F96),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: _isSaving
                ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                  )
                : const Text(
                    'Ø­ÙØ¸ Ø§Ù„ØªØ¹Ø¯ÙŠÙ„Ø§Øª',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}

