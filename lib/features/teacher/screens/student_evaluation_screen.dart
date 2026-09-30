import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class StudentEvaluationScreen extends StatefulWidget {
  final String studentId;
  final String teacherId;
  final String studentName;
  final String category;
  final String initial;
  final String? photoUrl;
  final String teacherName;
  final String? teacherAvatarUrl;
  final String teacherSubject;

  const StudentEvaluationScreen({
    super.key,
    required this.studentId,
    required this.teacherId,
    required this.studentName,
    required this.category,
    required this.initial,
    this.photoUrl,
    required this.teacherName,
    this.teacherAvatarUrl,
    this.teacherSubject = 'ØºÙŠØ± Ù…Ø­Ø¯Ø¯',
  });

  @override
  State<StudentEvaluationScreen> createState() => _StudentEvaluationScreenState();
}

class _StudentEvaluationScreenState extends State<StudentEvaluationScreen> {
  final SupabaseClient _supabase = Supabase.instance.client;
  
  // Daily Evaluation State
  bool isPresent = true;
  bool ateMeal = false;
  bool tookBreak = false;
  int dailyStars = 0;
  final TextEditingController _dailyNoteController = TextEditingController();

  // Weekly Evaluation State
  final TextEditingController _weeklyNoteController = TextEditingController();
  final TextEditingController _completedLessonsController = TextEditingController();
  bool completedWeeklyDuties = true;
  String _weeklyAttendanceRate = 'Ø¬Ø§Ø±ÙŠ Ø§Ù„Ø­Ø³Ø§Ø¨...';

  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _calculateWeeklyAttendance();
  }

  Future<void> _calculateWeeklyAttendance() async {
    try {
      // Calculate start of the week (assuming Sunday as start)
      final now = DateTime.now();
      final startOfWeek = now.subtract(Duration(days: now.weekday % 7));
      final startStr = startOfWeek.toIso8601String().split('T')[0];
      
      final reportsRes = await _supabase
          .from('daily_reports')
          .select('status, attendance')
          .eq('student_id', widget.studentId)
          .gte('created_at', '${startStr}T00:00:00Z');

      final List reports = reportsRes as List;
      
      if (reports.isEmpty) {
        if (mounted) setState(() => _weeklyAttendanceRate = 'Ù Ùª');
        return;
      }

      int presentCount = 0;
      for (var r in reports) {
        if (r['status'] == 'present' || r['attendance'] == true) {
          presentCount++;
        }
      }

      final rate = (presentCount / reports.length) * 100;
      
      // Convert to Arabic numerals
      final arabicRate = rate.toStringAsFixed(0)
          .replaceAll('0', 'Ù ')
          .replaceAll('1', 'Ù¡')
          .replaceAll('2', 'Ù¢')
          .replaceAll('3', 'Ù£')
          .replaceAll('4', 'Ù¤')
          .replaceAll('5', 'Ù¥')
          .replaceAll('6', 'Ù¦')
          .replaceAll('7', 'Ù§')
          .replaceAll('8', 'Ù¨')
          .replaceAll('9', 'Ù©');

      if (mounted) {
        setState(() {
          _weeklyAttendanceRate = '$arabicRateÙª';
        });
      }
    } catch (e) {
      if (mounted) setState(() => _weeklyAttendanceRate = 'ØºÙŠØ± Ù…ØªÙˆÙØ±');
    }
  }

  @override
  void dispose() {
    _dailyNoteController.dispose();
    _weeklyNoteController.dispose();
    _completedLessonsController.dispose();
    super.dispose();
  }

  Future<void> _saveEvaluation() async {
    setState(() => _isSaving = true);
    try {
      final todayStr = DateTime.now().toIso8601String().split('T')[0];

      // â”€â”€ 1. Fetch teacher name and photo for supervisor_reviews â”€â”€
      String teacherName = widget.studentName.isNotEmpty ? 'Ø§Ù„Ù…Ø¯Ø±Ø³' : 'Ø§Ù„Ù…Ø¯Ø±Ø³';
      String? teacherPhotoUrl;
      try {
        final profileRes = await _supabase
            .from('profiles')
            .select('full_name, avatar_url')
            .eq('id', widget.teacherId)
            .maybeSingle();
        if (profileRes != null) {
          teacherName = profileRes['full_name']?.toString() ?? teacherName;
          teacherPhotoUrl = profileRes['avatar_url']?.toString();
        }
      } catch (_) {}

      try {
        final teacherRes = await _supabase
            .from('teachers')
            .select('full_name, name')
            .eq('id', widget.teacherId)
            .maybeSingle();
        if (teacherRes != null) {
          teacherName = teacherRes['full_name']?.toString() ??
              teacherRes['name']?.toString() ??
              'Ø§Ù„Ù…Ø¯Ø±Ø³';
        }
      } catch (_) {}

      // â”€â”€ 2. Upsert daily_reports (avoid duplicates for same student+date) â”€â”€

      try {
        final existingReport = await _supabase
            .from('daily_reports')
            .select('id, status')
            .eq('student_id', widget.studentId)
            .eq('teacher_id', widget.teacherId)
            .eq('report_date', todayStr)
            .maybeSingle();

        if (existingReport != null) {
          // Update existing report
          await _supabase.from('daily_reports').update({
            'status': isPresent ? 'present' : 'absent',
            'attendance': isPresent,
            'note': _dailyNoteController.text.trim(),
            'ate_meal': ateMeal,
            'took_break': tookBreak,
            'stars': dailyStars,
          }).eq('id', existingReport['id']);

          // Send absence notification if marked absent
          if (!isPresent && existingReport['status'] != 'absent') {
            try {
              await _supabase.from('notifications').insert({
                'student_id': widget.studentId,
                'teacher_id': widget.teacherId,
                'title': 'ØºÙŠØ§Ø¨ Ø¹Ù† Ø§Ù„Ø­ØµØ©',
                'body': 'ØªÙ… ØªØ³Ø¬ÙŠÙ„ ØºÙŠØ§Ø¨Ùƒ ÙÙŠ Ø­ØµØ© Ø§Ù„Ø£Ø³ØªØ§Ø°/Ø© $teacherName.',
              });
            } catch (e) {
              debugPrint('Notification error: $e');
            }
          }
        } else {
          // Insert new report
          await _supabase.from('daily_reports').insert({
            'student_id': widget.studentId,
            'teacher_id': widget.teacherId,
            'report_date': todayStr,
            'status': isPresent ? 'present' : 'absent',
            'attendance': isPresent,
            'note': _dailyNoteController.text.trim(),
            'ate_meal': ateMeal,
            'took_break': tookBreak,
            'stars': dailyStars,
          });

          // Send attendance notification (present or absent)
          try {
            if (!isPresent) {
              await _supabase.from('notifications').insert({
                'student_id': widget.studentId,
                'teacher_id': widget.teacherId,
                'title': 'ØºÙŠØ§Ø¨ Ø¹Ù† Ø§Ù„Ø­ØµØ©',
                'body': 'ØªÙ… ØªØ³Ø¬ÙŠÙ„ ØºÙŠØ§Ø¨Ùƒ ÙÙŠ Ø­ØµØ© Ø§Ù„Ø£Ø³ØªØ§Ø°/Ø© $teacherName.',
              });
            } else {
              // Send present notification with details
              String notifBody = 'ØªÙ… ØªØ³Ø¬ÙŠÙ„ Ø­Ø¶ÙˆØ±Ùƒ ÙÙŠ Ø­ØµØ© Ø§Ù„Ø£Ø³ØªØ§Ø°/Ø© $teacherName âœ…';
              if (dailyStars > 0) {
                notifBody += '\nâ­ Ø­ØµÙ„Øª Ø¹Ù„Ù‰ $dailyStars Ù†Ø¬ÙˆÙ…';
              }
              if (_dailyNoteController.text.trim().isNotEmpty) {
                notifBody += '\nðŸ“ Ù…Ù„Ø§Ø­Ø¸Ø©: ${_dailyNoteController.text.trim()}';
              }
              
              await _supabase.from('notifications').insert({
                'student_id': widget.studentId,
                'teacher_id': widget.teacherId,
                'title': 'ØªØ³Ø¬ÙŠÙ„ Ø­Ø¶ÙˆØ±',
                'body': notifBody,
              });
            }
          } catch (e) {
            debugPrint('Notification error: $e');
          }
        }
      } catch (e) {
        debugPrint('Error saving daily report: $e');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('âš ï¸ Ø­Ø¯Ø« Ø®Ø·Ø£ ÙÙŠ Ø­ÙØ¸ Ø§Ù„ØªÙ‚Ø±ÙŠØ± Ø§Ù„ÙŠÙˆÙ…ÙŠ: $e'),
              backgroundColor: Colors.orange,
              duration: const Duration(seconds: 3),
            ),
          );
        }
      }

      // â”€â”€ 3. Save teacher attendance (if not already logged today) â”€â”€
      try {
        final teacherAttRes = await _supabase
            .from('teacher_attendance')
            .select('id')
            .eq('teacher_id', widget.teacherId)
            .gte('created_at', '${todayStr}T00:00:00Z')
            .lte('created_at', '${todayStr}T23:59:59Z');

        if ((teacherAttRes as List).isEmpty) {
          await _supabase.from('teacher_attendance').insert({
            'teacher_id': widget.teacherId,
            'status': 'present',
          });
        }
      } catch (_) {}

      // â”€â”€ 4. Save student_reviews (teacher note â†’ appears in student notes tab) â”€â”€
      final String noteText = _dailyNoteController.text.trim();
      if (noteText.isNotEmpty) {
        try {
          final existingReview = await _supabase
              .from('student_reviews')
              .select('id')
              .eq('student_id', widget.studentId)
              .eq('review_date', todayStr)
              .maybeSingle();

          if (existingReview != null) {
            await _supabase.from('student_reviews').update({
              'teacher_name': teacherName,
              'notes': noteText,
              'behavior_rating': dailyStars >= 4
                  ? 'Ù…Ù…ÙŠØ²'
                  : dailyStars >= 3
                      ? 'Ø¬ÙŠØ¯ Ø¬Ø¯Ø§Ù‹'
                      : dailyStars >= 2
                          ? 'Ø¬ÙŠØ¯'
                          : 'ÙŠØ­ØªØ§Ø¬ Ù…ØªØ§Ø¨Ø¹Ø©',
              if (teacherPhotoUrl != null && teacherPhotoUrl.isNotEmpty)
                'teacher_photo_url': teacherPhotoUrl,
            }).eq('id', existingReview['id']);
          } else {
            await _supabase.from('student_reviews').insert({
              'student_id': widget.studentId,
              'review_date': todayStr,
              'teacher_name': teacherName,
              'notes': noteText,
              'behavior_rating': dailyStars >= 4
                  ? 'Ù…Ù…ÙŠØ²'
                  : dailyStars >= 3
                      ? 'Ø¬ÙŠØ¯ Ø¬Ø¯Ø§Ù‹'
                      : dailyStars >= 2
                          ? 'Ø¬ÙŠØ¯'
                          : 'ÙŠØ­ØªØ§Ø¬ Ù…ØªØ§Ø¨Ø¹Ø©',
              if (teacherPhotoUrl != null && teacherPhotoUrl.isNotEmpty)
                'teacher_photo_url': teacherPhotoUrl,
            });
          }
        } catch (e) {
          // Ignore if student_reviews table doesn't have teacher_name column
          debugPrint('Note: student_reviews save skipped: $e');
        }
      }

      // â”€â”€ 5. Save weekly evaluation â”€â”€
      final weeklyNote = _weeklyNoteController.text.trim();
      final completedLessons = _completedLessonsController.text.trim();
      
      if (weeklyNote.isNotEmpty || completedLessons.isNotEmpty || completedWeeklyDuties) {
        try {
          await _supabase.from('weekly_evaluations').insert({
            'student_id': widget.studentId,
            'teacher_id': widget.teacherId,
            'completed_duties': completedWeeklyDuties,
            'completed_lessons': completedLessons,
            'note': weeklyNote,
          });
          
          try {
            await _supabase.from('notifications').insert({
              'student_id': widget.studentId,
              'teacher_id': widget.teacherId,
              'title': 'ØªÙ‚ÙŠÙŠÙ… Ø£Ø³Ø¨ÙˆØ¹ÙŠ Ø¬Ø¯ÙŠØ¯',
              'body': 'ØªÙ… Ø¥Ø¶Ø§ÙØ© ØªÙ‚ÙŠÙŠÙ… Ø£Ø³Ø¨ÙˆØ¹ÙŠ Ù„Ùƒ Ù…Ù† Ø§Ù„Ø£Ø³ØªØ§Ø°/Ø© $teacherName',
            });
          } catch (e) {
            debugPrint('Weekly notification error: $e');
          }
        } catch (_) {
          // Table might not exist, ignore
        }
      }

      // â”€â”€ 6. Send Notification to Student â”€â”€
      // The notification is already sent above based on attendance status

      if (!mounted) return;
      
      // Ø±Ø³Ø§Ù„Ø© Ù†Ø¬Ø§Ø­ ÙˆØ§Ø¶Ø­Ø© Ø¨Ù†Ø§Ø¡Ù‹ Ø¹Ù„Ù‰ Ø­Ø§Ù„Ø© Ø§Ù„Ø­Ø¶ÙˆØ±
      final String successMessage = isPresent 
          ? 'âœ… ØªÙ… ØªØ³Ø¬ÙŠÙ„ Ø­Ø¶ÙˆØ± ${widget.studentName} Ø¨Ù†Ø¬Ø§Ø­'
          : 'âœ… ØªÙ… ØªØ³Ø¬ÙŠÙ„ ØºÙŠØ§Ø¨ ${widget.studentName}';
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(successMessage),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 2),
        ),
      );
      Navigator.of(context).pop();
    } catch (e) {
      debugPrint('Error saving evaluation: $e');
      if (!mounted) return;
      
      // Ø±Ø³Ø§Ù„Ø© Ø®Ø·Ø£ Ù…Ø¨Ø³Ø·Ø© Ù„Ù„Ù…Ø³ØªØ®Ø¯Ù…
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('âš ï¸ Ø­Ø¯Ø« Ø®Ø·Ø£ØŒ Ø­Ø§ÙˆÙ„ Ù…Ø±Ø© Ø£Ø®Ø±Ù‰'),
          backgroundColor: Colors.orange,
          duration: Duration(seconds: 2),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? Colors.black : const Color(0xFFE6E6FA);
    final textColor = isDark ? Colors.white : const Color(0xFF2A1B38);
    final cardColor = isDark ? Colors.grey[900] : Colors.white;

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: bgColor,
        elevation: 0,
        scrolledUnderElevation: 0,
        leadingWidth: 160,
        leading: TextButton.icon(
          onPressed: () => Navigator.of(context).pop(),
          icon: Icon(Icons.arrow_back, color: textColor),
          label: Text(
            'Ø¹ÙˆØ¯Ø© Ù„Ù„Ù‚Ø§Ø¦Ù…Ø©',
            style: TextStyle(
              color: textColor,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        actions: const [],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
        child: Column(
          children: [
            // Student Info Header
            CircleAvatar(
              radius: 40,
              backgroundColor: isDark ? Colors.grey[800] : const Color(0xFFEEEEEE),
              backgroundImage: widget.photoUrl != null && widget.photoUrl!.isNotEmpty
                  ? CachedNetworkImageProvider(widget.photoUrl!)
                  : null,
              child: widget.photoUrl == null || widget.photoUrl!.isEmpty
                  ? Text(
                      widget.initial,
                      style: TextStyle(
                        color: textColor,
                        fontSize: 36,
                        fontWeight: FontWeight.bold,
                      ),
                    )
                  : null,
            ),
            const SizedBox(height: 12),
            Text(
              widget.studentName,
              style: TextStyle(
                color: textColor,
                fontSize: 28,
                fontWeight: FontWeight.w900,
              ),
            ),
            Text(
              'Ø§Ù„ÙØ¦Ø© Ø§Ù„Ø¹Ù…Ø±ÙŠØ©: ${widget.category}',
              style: const TextStyle(
                color: Colors.grey,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 16),

            // Teacher Info Card
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E1E1E) : const Color(0xFFF3EEFF),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircleAvatar(
                    radius: 20,
                    backgroundColor: isDark
                        ? const Color(0xFF2A2A2A)
                        : const Color(0xFFDDD0F7),
                    backgroundImage: widget.teacherAvatarUrl != null &&
                            widget.teacherAvatarUrl!.isNotEmpty
                        ? CachedNetworkImageProvider(widget.teacherAvatarUrl!)
                        : null,
                    child: widget.teacherAvatarUrl == null ||
                            widget.teacherAvatarUrl!.isEmpty
                        ? Text(
                            widget.teacherName.isNotEmpty
                                ? widget.teacherName[0]
                                : 'Ù…',
                            style: TextStyle(
                              color: textColor,
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                          )
                        : null,
                  ),
                  const SizedBox(width: 10),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.teacherName,
                        style: TextStyle(
                          color: textColor,
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        widget.teacherSubject,
                        style: const TextStyle(
                          color: Color(0xFF724F96),
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(width: 8),
                  const Icon(
                    Icons.school_rounded,
                    color: Color(0xFF724F96),
                    size: 18,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Daily Evaluation Card
            _buildDailyEvaluationCard(textColor: textColor, cardColor: cardColor!),
            
            const SizedBox(height: 24),

            // Weekly Evaluation Card
            _buildWeeklyEvaluationCard(textColor: textColor, cardColor: cardColor),
            
            const SizedBox(height: 32),


            // Save Button
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: _isSaving ? null : _saveEvaluation,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF724F96),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _isSaving
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text(
                        'Ø­ÙØ¸ Ø§Ù„ØªØ¹Ø¯ÙŠÙ„Ø§Øª',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildDailyEvaluationCard({required Color textColor, required Color cardColor}) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Ø§Ù„ØªÙ‚ÙŠÙŠÙ… Ø§Ù„ÙŠÙˆÙ…ÙŠ',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Color(0xFF724F96),
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const Divider(),
          const SizedBox(height: 12),
          Text(
            'ØªØ³Ø¬ÙŠÙ„ Ø§Ù„Ø­Ø¶ÙˆØ±:',
            textAlign: TextAlign.right,
            style: TextStyle(
              color: textColor,
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              // Absent Button
              Expanded(
                child: GestureDetector(
                  onTap: () => setState(() => isPresent = false),
                  child: Container(
                    height: 48,
                    decoration: BoxDecoration(
                      color: !isPresent ? Colors.red : Colors.transparent,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                          color: !isPresent ? Colors.red : const Color(0xFFE5E5EA)),
                    ),
                    alignment: Alignment.center,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        if (!isPresent)
                          const Icon(Icons.close, color: Colors.white, size: 20),
                        if (!isPresent) const SizedBox(width: 8),
                        Text(
                          'ØºØ§Ø¦Ø¨',
                          style: TextStyle(
                            color: !isPresent ? Colors.white : textColor,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              // Present Button
              Expanded(
                child: GestureDetector(
                  onTap: () => setState(() => isPresent = true),
                  child: Container(
                    height: 48,
                    decoration: BoxDecoration(
                      color: isPresent ? Colors.green : Colors.transparent,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                          color: isPresent ? Colors.green : const Color(0xFFE5E5EA)),
                    ),
                    alignment: Alignment.center,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        if (isPresent)
                          const Icon(Icons.check, color: Colors.white, size: 20),
                        if (isPresent) const SizedBox(width: 8),
                        Text(
                          'Ø­Ø§Ø¶Ø±',
                          style: TextStyle(
                            color: isPresent ? Colors.white : textColor,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: TextField(
                  controller: _dailyNoteController,
                  textAlign: TextAlign.right,
                  textDirection: TextDirection.rtl,
                  maxLines: 2,
                  decoration: InputDecoration(
                    hintText: 'Ù…Ù„Ø§Ø­Ø¸Ø©',
                    hintStyle: const TextStyle(fontSize: 12),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(color: Color(0xFFE5E5EA)),
                    ),
                    contentPadding: const EdgeInsets.all(8),
                  ),
                  style: TextStyle(color: textColor),
                ),
              ),
              const SizedBox(width: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Row(
                    children: [
                      const Text('ØªÙ†Ø§ÙˆÙ„ Ø§Ù„ÙˆØ¬Ø¨Ø©', style: TextStyle(fontSize: 12)),
                      Checkbox(
                        value: ateMeal,
                        onChanged: (val) => setState(() => ateMeal = val ?? false),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      const Text('Ø£Ø®Ø° Ø§Ù„Ø§Ø³ØªØ±Ø§Ø­Ø©', style: TextStyle(fontSize: 12)),
                      Checkbox(
                        value: tookBreak,
                        onChanged: (val) => setState(() => tookBreak = val ?? false),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 20),
          Text(
            'Ø§Ù„ØªÙ‚ÙŠÙŠÙ… Ø§Ù„ÙŠÙˆÙ…ÙŠ:',
            textAlign: TextAlign.right,
            style: TextStyle(
              color: textColor,
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(5, (index) {
              return IconButton(
                icon: Icon(
                  index < dailyStars ? Icons.star : Icons.star_border,
                  color: const Color(0xFFFFCC00),
                  size: 32,
                ),
                onPressed: () {
                  setState(() {
                    dailyStars = index + 1;
                  });
                },
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildWeeklyEvaluationCard({required Color textColor, required Color cardColor}) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Ø§Ù„ØªÙ‚ÙŠÙŠÙ… Ø§Ù„Ø£Ø³Ø¨ÙˆØ¹ÙŠ',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Color(0xFF724F96),
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const Divider(),
          const SizedBox(height: 12),
          Text(
            'Ù†Ø³Ø¨Ø© Ø§Ù„Ø­Ø¶ÙˆØ± Ø§Ù„Ø£Ø³Ø¨ÙˆØ¹ÙŠØ©: $_weeklyAttendanceRate',
            textAlign: TextAlign.right,
            textDirection: TextDirection.rtl,
            style: TextStyle(
              color: textColor,
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Ø§Ù„Ø¯Ø±ÙˆØ³ Ø§Ù„Ù…Ù†Ø¬Ø²Ø©',
            textAlign: TextAlign.right,
            style: TextStyle(
              color: textColor,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _completedLessonsController,
            textAlign: TextAlign.right,
            textDirection: TextDirection.rtl,
            maxLines: 2,
            decoration: InputDecoration(
              hintText: 'Ù…Ø«Ø§Ù„: Ø§Ù„Ø­Ø±ÙˆÙØŒ Ø§Ù„Ø£Ø±Ù‚Ø§Ù…ØŒ Ø£Ù„Ø¹Ø§Ø¨ Ø§Ù„Ø°Ø§ÙƒØ±Ø©',
              hintStyle: const TextStyle(fontSize: 12),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: Color(0xFFE5E5EA)),
              ),
              contentPadding: const EdgeInsets.all(8),
            ),
            style: TextStyle(color: textColor),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Text('Ø£ÙƒÙ…Ù„ Ø§Ù„ÙˆØ§Ø¬Ø¨Ø§Øª Ø§Ù„Ø£Ø³Ø¨ÙˆØ¹ÙŠØ©', style: TextStyle(fontSize: 12, color: textColor)),
              Checkbox(
                value: completedWeeklyDuties,
                onChanged: (val) => setState(() => completedWeeklyDuties = val ?? false),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'Ù…Ù„Ø§Ø­Ø¸Ø§Øª Ø§Ù„Ø£Ø³Ø¨ÙˆØ¹',
            textAlign: TextAlign.right,
            style: TextStyle(
              color: textColor,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _weeklyNoteController,
            textAlign: TextAlign.right,
            textDirection: TextDirection.rtl,
            maxLines: 3,
            decoration: InputDecoration(
              hintText: 'Ù…ØªÙÙˆÙ‚ Ø¬Ø¯Ø§ Ù‡Ø°Ø§ Ø§Ù„Ø£Ø³Ø¨ÙˆØ¹...',
              hintStyle: const TextStyle(fontSize: 12),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: Color(0xFFE5E5EA)),
              ),
              contentPadding: const EdgeInsets.all(8),
            ),
            style: TextStyle(color: textColor),
          ),
        ],
      ),
    );
  }


}


